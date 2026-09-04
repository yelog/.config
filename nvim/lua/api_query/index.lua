local scanner = require("api_query.scanner")
local model = require("api_query.model")
local diagnostics = require("api_query.diagnostics")
local M = { files = {}, endpoints = {}, diagnostics = diagnostics.new() }
M.root = nil

local source_globs = { "*.java", "*.py", "*.go", "*.js", "*.jsx", "*.ts", "*.tsx" }
local candidate_pattern = table.concat({
  "@(RestController|Controller|RequestMapping|GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping|Path|GET|POST|PUT|PATCH|DELETE)",
  "APIRouter|FastAPI|Blueprint|Flask|urlpatterns",
  "gin-gonic/gin|gin\\.Default|gin\\.New|go-chi/chi|chi\\.NewRouter|http\\.Handle",
  "express|fastify|@nestjs/",
}, "|")

local function fallback_files(root, opts, out, prefix)
  opts, out, prefix = opts or {}, out or {}, prefix or root
  local handle = vim.loop.fs_scandir(prefix); if not handle then return out end
  while true do
    local name, kind = vim.loop.fs_scandir_next(handle); if not name then break end
    local path = prefix .. "/" .. name
    local excluded = false; for _, part in ipairs(opts.exclude or { ".git", "node_modules", "vendor", "target", "build", "dist" }) do if name == part then excluded = true end end
    if not excluded then
      if kind == "directory" then
        fallback_files(root, opts, out, path)
      elseif vim.tbl_contains(source_globs, "*." .. (name:match("%.([^.]*)$") or "")) then
        out[#out + 1] = path
      end
    end
  end
  return out
end

local function candidate_files(root, opts)
  if vim.fn.executable("rg") ~= 1 then return fallback_files(root, opts) end
  local command = { "rg", "--files-with-matches", "--no-messages", "--hidden" }
  for _, glob in ipairs(source_globs) do vim.list_extend(command, { "--glob", glob }) end
  for _, part in ipairs(opts.exclude or { ".git", "node_modules", "vendor", "target", "build", "dist" }) do
    vim.list_extend(command, { "--glob", "!" .. part .. "/**", "--glob", "!**/" .. part .. "/**" })
  end
  vim.list_extend(command, { candidate_pattern, "." })
  local result = vim.system(command, { text = true, cwd = root }):wait()
  if result.code ~= 0 and result.code ~= 1 then return fallback_files(root, opts) end
  local paths = vim.split(result.stdout or "", "\n", { trimempty = true })
  for i, path in ipairs(paths) do paths[i] = vim.fs.joinpath(root, path) end
  return paths
end

function M.scan_root(root, opts)
  opts = opts or {}; M.root = root; M.files, M.endpoints, M.diagnostics = {}, {}, diagnostics.new()
  for _, path in ipairs(candidate_files(root, opts)) do
    local file = io.open(path, "r"); local text = file and file:read("*a") or nil; if file then file:close() end
    if text then local report = scanner.scan_file(text, path, opts); M.files[path] = report; diagnostics.merge(M.diagnostics, report.diagnostics); for _, endpoint in ipairs(report.endpoints) do M.endpoints[#M.endpoints + 1] = endpoint end else diagnostics.add(M.diagnostics, { file = path }, "unable to read file") end
  end
  table.sort(M.endpoints, model.compare); local unique, seen = {}, {}; for _, endpoint in ipairs(M.endpoints) do if not seen[endpoint.id] then seen[endpoint.id] = true; unique[#unique + 1] = endpoint end end; M.endpoints = unique
  return { endpoints = M.endpoints, files = M.files, diagnostics = M.diagnostics.items }
end
function M.open(opts)
  opts = opts or {}
  opts = vim.tbl_extend("force", opts.scan or {}, opts)
  local root = opts.root or vim.fn.getcwd()
  if M.root ~= root or opts.force then
    vim.notify("api_query: indexing endpoints...", vim.log.levels.INFO)
    vim.cmd("redraw")
    local started = (vim.uv or vim.loop).hrtime()
    M.scan_root(root, opts)
    local elapsed = ((vim.uv or vim.loop).hrtime() - started) / 1e9
    vim.notify(string.format("api_query: indexed %d endpoints in %.2fs", #M.endpoints, elapsed), vim.log.levels.INFO)
  end
  return M.endpoints
end
function M.refresh(opts)
  opts = opts or {}; M.root = nil; return M.open(opts)
end
function M.list() return M.endpoints end
M.candidate_files = candidate_files
return M
