local M = {}

local api = vim.api
local namespace = api.nvim_create_namespace("nvim.codelens_eol")
local buffers = {}

local function valid_buffer(bufnr)
  return api.nvim_buf_is_valid(bufnr) and api.nvim_buf_is_loaded(bufnr)
end

local function lens_title(lens)
  local command = lens and lens.command
  local title = command and command.title
  if type(title) ~= "string" then
    return nil
  end

  title = vim.trim(title:gsub("[\r\n]+", " "))
  if title == "" then
    return nil
  end

  return title
end

local function render(bufnr)
  if not valid_buffer(bufnr) then
    return
  end

  api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

  local state = buffers[bufnr]
  if not state then
    return
  end

  local rows = {}
  for _, client_state in pairs(state.clients) do
    for row, lenses in pairs(client_state.lenses) do
      rows[row] = rows[row] or {}
      vim.list_extend(rows[row], lenses)
    end
  end

  local line_count = api.nvim_buf_line_count(bufnr)
  for row, lenses in pairs(rows) do
    if row >= 0 and row < line_count then
      table.sort(lenses, function(a, b)
        return a.column < b.column
      end)

      local titles = {}
      for _, lens in ipairs(lenses) do
        titles[#titles + 1] = lens.title
      end

      if #titles > 0 then
        api.nvim_buf_set_extmark(bufnr, namespace, row, 0, {
          virt_text = { { "  " .. table.concat(titles, " | "), "LspCodeLens" } },
          virt_text_pos = "eol",
          hl_mode = "combine",
        })
      end
    end
  end
end

local function request_lenses(bufnr, client_state)
  if
    not valid_buffer(bufnr)
    or not buffers[bufnr]
    or buffers[bufnr].clients[client_state.client.id] ~= client_state
  then
    return
  end

  client_state.generation = client_state.generation + 1
  local generation = client_state.generation
  local changedtick = vim.b[bufnr].changedtick

  local function current()
    local state = buffers[bufnr]
    return state
      and state.clients[client_state.client.id] == client_state
      and client_state.generation == generation
      and valid_buffer(bufnr)
      and vim.b[bufnr].changedtick == changedtick
  end

  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  client_state.client:request("textDocument/codeLens", params, function(err, lenses)
    if not current() then
      return
    end

    if err then
      client_state.lenses = {}
      render(bufnr)
      return
    end

    if type(lenses) ~= "table" then
      lenses = {}
    end

    local rows = {}
    local unresolved = {}
    local pending = 0

    local function add(lens, fallback_range)
      local range = lens and lens.range or fallback_range
      local start = range and range.start
      local title = lens_title(lens)
      if not title or not start or type(start.line) ~= "number" then
        return
      end

      rows[start.line] = rows[start.line] or {}
      table.insert(rows[start.line], {
        title = title,
        column = type(start.character) == "number" and start.character or 0,
      })
    end

    local function finish()
      if not current() then
        return
      end

      client_state.lenses = rows
      render(bufnr)
    end

    for _, lens in ipairs(lenses) do
      if type(lens) == "table" then
        if lens_title(lens) then
          add(lens)
        elseif lens.command == nil and lens.range then
          pending = pending + 1
          unresolved[#unresolved + 1] = lens
        end
      end
    end

    if pending == 0 then
      finish()
      return
    end

    for _, lens in ipairs(unresolved) do
      client_state.client:request("codeLens/resolve", lens, function(resolve_err, resolved)
        if current() then
          if not resolve_err and type(resolved) == "table" then
            add(resolved, lens.range)
          end
          pending = pending - 1
          if pending == 0 then
            finish()
          end
        end
      end, bufnr)
    end
  end, bufnr)
end

local function schedule_refresh(bufnr, delay)
  local state = buffers[bufnr]
  if not state then
    return
  end

  state.timer:stop()
  state.timer:start(
    delay,
    0,
    vim.schedule_wrap(function()
      if buffers[bufnr] ~= state then
        return
      end

      for _, client_state in pairs(state.clients) do
        request_lenses(bufnr, client_state)
      end
    end)
  )
end

local function destroy_buffer(bufnr)
  local state = buffers[bufnr]
  if not state then
    return
  end

  buffers[bufnr] = nil
  state.timer:stop()
  if not state.timer:is_closing() then
    state.timer:close()
  end

  if api.nvim_buf_is_valid(bufnr) then
    api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  end

  pcall(api.nvim_del_augroup_by_id, state.group)
end

function M.attach(bufnr, client)
  if not valid_buffer(bufnr) or type(client) ~= "table" or type(client.id) ~= "number" then
    return
  end

  local state = buffers[bufnr]
  if not state then
    state = {
      clients = {},
      group = api.nvim_create_augroup("nvim_codelens_eol_" .. bufnr, { clear = true }),
      timer = assert(vim.uv.new_timer()),
    }
    buffers[bufnr] = state

    api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePost" }, {
      group = state.group,
      buffer = bufnr,
      callback = function()
        schedule_refresh(bufnr, 0)
      end,
    })

    api.nvim_create_autocmd("TextChanged", {
      group = state.group,
      buffer = bufnr,
      callback = function()
        schedule_refresh(bufnr, 300)
      end,
    })

    api.nvim_create_autocmd("LspDetach", {
      group = state.group,
      buffer = bufnr,
      callback = function(args)
        M.detach(args.buf, args.data and args.data.client_id)
      end,
    })

    api.nvim_create_autocmd("BufWipeout", {
      group = state.group,
      buffer = bufnr,
      once = true,
      callback = function()
        destroy_buffer(bufnr)
      end,
    })
  end

  local client_state = state.clients[client.id]
  if not client_state then
    client_state = {
      client = client,
      generation = 0,
      lenses = {},
    }
    state.clients[client.id] = client_state
  else
    client_state.client = client
  end

  schedule_refresh(bufnr, 0)
end

function M.detach(bufnr, client_id)
  local state = buffers[bufnr]
  if not state or not client_id then
    return
  end

  state.clients[client_id] = nil
  if next(state.clients) == nil then
    destroy_buffer(bufnr)
  else
    render(bufnr)
  end
end

function M.refresh_client(client_id)
  for bufnr, state in pairs(buffers) do
    local client_state = state.clients[client_id]
    if client_state then
      request_lenses(bufnr, client_state)
    end
  end
end

function M.on_refresh(_, _, ctx)
  if not ctx or not ctx.client_id then
    return vim.NIL
  end

  M.refresh_client(ctx.client_id)
  return vim.NIL
end

return M
