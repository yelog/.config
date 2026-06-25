-- 剪贴板候选翻译器
-- 输入触发前缀（默认 vv），将系统剪贴板内容作为候选词输出
-- 支持：单行文本、多行文本截取、URL 直出
-- macOS 依赖 pbpaste，Linux 依赖 xclip/wl-paste

local MAX_LENGTH = 500   -- 剪贴板内容最大读取长度
local MAX_LINES = 5      -- 多行文本最多展示行数

-- 读取系统剪贴板
local function read_clipboard()
  -- macOS
  local handle = io.popen("pbpaste 2>/dev/null")
  if handle then
    local content = handle:read("*a")
    handle:close()
    if content and content ~= "" then
      return content
    end
  end
  -- Linux X11
  handle = io.popen("xclip -selection clipboard -o 2>/dev/null")
  if handle then
    local content = handle:read("*a")
    handle:close()
    if content and content ~= "" then
      return content
    end
  end
  -- Linux Wayland
  handle = io.popen("wl-paste 2>/dev/null")
  if handle then
    local content = handle:read("*a")
    handle:close()
    if content and content ~= "" then
      return content
    end
  end
  return nil
end

-- 截断并清理文本
local function clean_text(text, max_len)
  -- 去除首尾空白
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  -- 截断
  if #text > max_len then
    text = text:sub(1, max_len) .. "…"
  end
  return text
end

-- 多行文本压缩为摘要
local function summarize_multiline(text)
  local lines = {}
  for line in text:gmatch("([^\n]+)") do
    if line:gsub("%s+", "") ~= "" then
      table.insert(lines, line)
    end
  end
  if #lines <= 1 then
    return clean_text(text, MAX_LENGTH)
  end
  -- 多行：取前 N 行，拼接显示
  local summary_lines = {}
  for i = 1, math.min(MAX_LINES, #lines) do
    table.insert(summary_lines, lines[i])
  end
  local summary = table.concat(summary_lines, " ")
  if #lines > MAX_LINES then
    summary = summary .. " …(" .. #lines .. "行)"
  end
  return clean_text(summary, MAX_LENGTH)
end

-- 获取内容类型注释
local function get_comment(text)
  -- URL
  if text:match("^https?://") then
    return "🔗 链接"
  end
  -- 邮箱
  if text:match("^[%w._-]+@[%w._-]+%.%w+$") then
    return "📧 邮箱"
  end
  -- 纯数字
  if text:match("^%d+$") then
    return "🔢 数字"
  end
  -- 文件路径
  if text:match("^/") or text:match("^~") then
    return "📁 路径"
  end
  -- 多行
  if text:find("\n") then
    return "📋 多行文本"
  end
  return "📋 剪贴板"
end

-- 去重：对剪贴板内容按行去重
local function deduplicate_lines(text)
  local seen = {}
  local result = {}
  for line in text:gmatch("([^\n]+)") do
    local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed ~= "" and not seen[trimmed] then
      seen[trimmed] = true
      table.insert(result, line)
    end
  end
  if #result == 0 then return text end
  return table.concat(result, "\n")
end

local function clipboard_translator(input, seg, env)
  -- 获取触发前缀，从 recognizer/patterns/clipboard 读取
  env.clipboard_keyword = env.clipboard_keyword or
      (env.engine.schema.config:get_string('recognizer/patterns/clipboard') or "vv"):sub(2):match("^([^%%]+)")

  -- 兼容：直接用 vv 作为触发
  local prefix = "vv"
  if input ~= prefix then return end

  local raw = read_clipboard()
  if not raw or raw == "" then
    yield(Candidate("clipboard", seg.start, seg._end, "（剪贴板为空）", ""))
    return
  end

  -- 去除末尾换行
  raw = raw:gsub("\n$", "")

  local comment = get_comment(raw)

  -- 候选1：原始内容（单行直接出，多行压缩）
  local display = raw:find("\n") and summarize_multiline(raw) or clean_text(raw, MAX_LENGTH)
  local cand = Candidate("clipboard", seg.start, seg._end, display, comment)
  cand.quality = 100
  yield(cand)

  -- 候选2：去重版本（仅多行时有意义）
  if raw:find("\n") then
    local deduped = deduplicate_lines(raw)
    if deduped ~= raw then
      local dedup_display = summarize_multiline(deduped)
      yield(Candidate("clipboard_dedup", seg.start, seg._end, dedup_display, "📋 去重"))
    end
  end

  -- 候选3：纯文本清理版（去除多余空白）
  local cleaned = clean_text(raw:gsub("%s+", " "), MAX_LENGTH)
  if cleaned ~= display then
    yield(Candidate("clipboard_clean", seg.start, seg._end, cleaned, "📋 单行"))
  end
end

return clipboard_translator
