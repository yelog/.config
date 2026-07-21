local M = {}

local states = {}
local nbsp = "\194\160"

local function project_key(cwd)
  return vim.fs.normalize(cwd or vim.uv.cwd() or ".")
end

function M.reset()
  states = {}
end

function M.state(cwd)
  local key = project_key(cwd)
  if not states[key] then
    states[key] = {
      regex = false,
      case_sensitive = false,
      whole_word = false,
      masks = {},
    }
  end
  return states[key]
end

function M.parse_masks(value)
  local masks = {}
  for mask in tostring(value or ""):gmatch("[^,]+") do
    mask = vim.trim(mask)
    if mask ~= "" then
      masks[#masks + 1] = mask
    end
  end
  return masks
end

function M.build_args(state, base)
  local args = vim.deepcopy(base or {})
  args[#args + 1] = state.case_sensitive and "--case-sensitive" or "--ignore-case"
  if state.whole_word then
    args[#args + 1] = "--word-regexp"
  end
  return args
end

function M.result_summary(items)
  local files = {}
  for _, item in ipairs(items or {}) do
    if item.file then
      files[item.file] = true
    end
  end
  local matches = #(items or {})
  local file_count = vim.tbl_count(files)
  return string.format(
    "%d %s in %d %s",
    matches,
    matches == 1 and "match" or "matches",
    file_count,
    file_count == 1 and "file" or "files"
  )
end

local function set_title(picker, window, title)
  local win = picker.layout.wins[window]
  if win then
    win.meta.title_tpl = title
  end
end

local function option_chip(label, enabled)
  return {
    nbsp .. "[" .. label .. "]",
    enabled and "SnacksPickerSpecial" or "SnacksPickerComment",
  }
end

function M.update_toolbar(picker)
  local state = picker.opts._project_search_state
  if not state then
    return
  end
  local mask = #state.masks == 0 and "All files" or table.concat(state.masks, ", ")
  mask = Snacks.picker.util.truncate(mask, 36)
  set_title(picker, "input", {
    { "Find in Files", "FloatTitle" },
    option_chip(".* Regex", state.regex),
    option_chip("Aa Case", state.case_sensitive),
    option_chip("W Word", state.whole_word),
    option_chip("Mask: " .. mask, #state.masks > 0),
  })
  picker:update_titles()
end

function M.update_results(picker, loading)
  local summary = loading and "Searching..." or M.result_summary(picker.list.items)
  set_title(picker, "list", {
    { "Results", "FloatTitle" },
    { nbsp .. summary, "SnacksPickerTotals" },
  })
  picker:update_titles()
end

local function rerun(picker)
  M.update_toolbar(picker)
  M.update_results(picker, true)
  picker.list:set_target()
  picker:find()
end

local function toggle(name)
  return function(picker)
    local state = picker.opts._project_search_state
    state[name] = not state[name]
    picker.opts[name] = state[name]
    rerun(picker)
  end
end

local function edit_mask(picker)
  local state = picker.opts._project_search_state
  vim.ui.input({
    prompt = "File mask (comma-separated): ",
    default = table.concat(state.masks, ", "),
  }, function(value)
    if value ~= nil and not picker.closed then
      state.masks = M.parse_masks(value)
      picker.opts.glob = vim.deepcopy(state.masks)
      rerun(picker)
    end
    if not picker.closed then
      picker:focus("input")
    end
  end)
end

local function configure(opts)
  local state = M.state(opts.cwd)
  opts._project_search_state = state
  opts._project_search_base_args = vim.deepcopy(opts.args or {})
  opts.regex = state.regex
  opts.case_sensitive = state.case_sensitive
  opts.whole_word = state.whole_word
  opts.glob = vim.deepcopy(state.masks)
  opts.matcher = vim.tbl_deep_extend("force", opts.matcher or {}, { ignorecase = true, smartcase = false })
  return opts
end

local function finder(opts, ctx)
  local effective = vim.deepcopy(opts)
  effective.args = M.build_args(opts, opts._project_search_base_args)
  return require("snacks.picker.source.grep").grep(effective, ctx)
end

local function on_show(picker)
  M.update_toolbar(picker)
  M.update_results(picker, picker:is_active())
  if picker._project_search_attached then
    return
  end
  picker._project_search_attached = true
  local previous = picker.matcher.opts.on_done
  picker.matcher.opts.on_done = function(...)
    if previous then
      previous(...)
    end
    vim.schedule(function()
      if not picker.closed then
        M.update_results(picker, false)
      end
    end)
  end
end

local function preview(ctx)
  local file = ctx.item.file
  local cwd = ctx.item.cwd or vim.uv.cwd()
  local relative = file and (vim.fs.relpath(cwd, file) or file) or nil
  ctx.item.title = relative

  if relative then
    local filename = vim.fn.fnamemodify(relative, ":t")
    local directory = vim.fn.fnamemodify(relative, ":h")
    local icon, icon_hl = Snacks.util.icon(filename, "file", {
      fallback = ctx.picker.opts.icons.files,
    })
    local title = {
      { icon .. " ", icon_hl },
      { filename, "SnacksPickerFile" },
    }
    if directory ~= "." then
      title[#title + 1] = { string.rep(nbsp, 3) .. directory, "SnacksPickerComment" }
    end
    ctx.picker.layout.wins.preview.meta.title_tpl = title
  end

  Snacks.picker.preview.file(ctx)
end

local function format(item)
  local ret = {}
  if item.line then
    Snacks.picker.highlight.format(item, item.line, ret)
    for _, pos in ipairs(item.positions or {}) do
      ret[#ret + 1] = {
        col = pos - 1,
        end_col = pos,
        hl_group = "SnacksPickerSearch",
        priority = 200,
      }
    end
  end
  if item.file then
    ret[#ret + 1] = {
      col = 0,
      virt_text = {
        {
          string.format("%s %d", vim.fn.fnamemodify(item.file, ":t"), item.pos and item.pos[1] or 0),
          "SnacksPickerComment",
        },
      },
      virt_text_pos = "right_align",
      hl_mode = "combine",
    }
  end
  return ret
end

function M.source()
  local keys = {
    ["<A-x>"] = { "project_search_regex", mode = { "i", "n" } },
    ["<A-c>"] = { "project_search_case", mode = { "i", "n" } },
    ["<A-w>"] = { "project_search_word", mode = { "i", "n" } },
    ["<A-g>"] = { "project_search_mask", mode = { "i", "n" } },
  }
  return {
    auto_close = false,
    config = configure,
    finder = finder,
    preview = preview,
    format = format,
    on_show = on_show,
    actions = {
      project_search_regex = toggle("regex"),
      project_search_case = toggle("case_sensitive"),
      project_search_word = toggle("whole_word"),
      project_search_mask = edit_mask,
    },
    win = {
      input = { keys = keys },
      list = { keys = keys },
    },
    layout = {
      layout = {
        box = "vertical",
        width = 0.8,
        height = 0.85,
        {
          box = "vertical",
          height = 0.4,
          { win = "input", height = 1, border = true, title = "{title}", title_pos = "center" },
          { win = "list", border = true, title = "Results", title_pos = "left" },
        },
        { win = "preview", height = 0.6, border = true, title = "{preview}", title_pos = "left" },
      },
    },
  }
end

function M.open(opts)
  return Snacks.picker.grep(opts or {})
end

return M
