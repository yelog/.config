local M = {}

local function normalize(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function workspace_root()
  return vim.fn.stdpath("cache") .. "/jdtls/workspace"
end

---@param root string
---@return string[]
function M.list_workspaces(root)
  root = normalize(root)
  local workspaces = {}
  if vim.fn.isdirectory(root) ~= 1 then
    return workspaces
  end

  for name, type in vim.fs.dir(root) do
    if type == "directory" then
      workspaces[#workspaces + 1] = normalize(root .. "/" .. name)
    end
  end
  table.sort(workspaces)
  return workspaces
end

---@param root string
---@param path string
---@return boolean
function M.is_workspace_path(root, path)
  root = normalize(root)
  path = normalize(path)
  return path:sub(1, #root + 1) == root .. "/" and not path:sub(#root + 2):find("/", 1, true)
end

---@param client vim.lsp.Client
---@return string|nil
function M.client_workspace(client)
  if client.name ~= "jdtls" then
    return nil
  end

  local cmd = client.config and client.config.cmd
  if type(cmd) ~= "table" then
    return nil
  end

  for index, argument in ipairs(cmd) do
    if argument == "-data" or argument == "--data" then
      return cmd[index + 1] and normalize(cmd[index + 1]) or nil
    end
    local data_dir = type(argument) == "string" and argument:match("^%-%-data=(.+)$")
    if data_dir then
      return normalize(data_dir)
    end
  end
end

local function active_client(workspace)
  for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    if M.client_workspace(client) == workspace then
      return client
    end
  end
end

local function delete_workspace(root, workspace)
  if not M.is_workspace_path(root, workspace) then
    vim.notify("Refusing to delete a path outside the JDTLS workspace cache", vim.log.levels.ERROR)
    return false
  end
  if vim.fn.delete(workspace, "rf") ~= 0 then
    vim.notify("Failed to delete JDTLS workspace: " .. workspace, vim.log.levels.ERROR)
    return false
  end
  return true
end

local function restart_client(client)
  local buffers = vim.tbl_keys(client.attached_buffers or {})
  client:stop()
  if not vim.wait(30000, function()
    return vim.lsp.get_client_by_id(client.id) == nil
  end, 100) then
    vim.notify("Timed out waiting for JDTLS to stop; workspace was not deleted", vim.log.levels.ERROR)
    return false
  end

  return buffers
end

---@param workspace string
function M.clean(workspace)
  local root = workspace_root()
  workspace = normalize(workspace)
  local client = active_client(workspace)
  local buffers = client and restart_client(client)
  if client and not buffers then
    return
  end
  if not delete_workspace(root, workspace) then
    return
  end

  if client then
    local client_id = vim.lsp.start(client.config)
    if not client_id then
      vim.notify("Deleted JDTLS workspace, but failed to restart JDTLS", vim.log.levels.ERROR)
      return
    end
    for _, buffer in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buffer) then
        vim.lsp.buf_attach_client(buffer, client_id)
      end
    end
  end

  vim.notify("Deleted JDTLS workspace: " .. vim.fs.basename(workspace), vim.log.levels.INFO)
end

function M.pick()
  local root = workspace_root()
  local workspaces = M.list_workspaces(root)
  if #workspaces == 0 then
    vim.notify("No JDTLS workspaces found", vim.log.levels.INFO)
    return
  end

  Snacks.picker.pick({
    title = "Clean JDTLS Workspace",
    items = vim.tbl_map(function(workspace)
      return {
        text = vim.fs.basename(workspace) .. "  " .. workspace,
        workspace = workspace,
      }
    end, workspaces),
    format = "text",
    preview = "none",
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      Snacks.picker.util.confirm("Delete JDTLS workspace '" .. item.workspace .. "'?", function()
        M.clean(item.workspace)
      end)
    end,
  })
end

return M
