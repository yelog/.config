return {
  "yelog/i18n.nvim",
  dependencies = { "ibhagwan/fzf-lua" },
  dev = true,
  config = function()
    require("i18n").setup({
      mode = 'static',
      static = {
        -- langs = { "zh_CN", "en_US" },
        langs = { "zh", "en" },
        files = {
          "src/locales/{langs}.json",
          -- { files = "src/locales/lang/{langs}/{module}.ts",          prefix = "{module}." },
          -- { files = "src/views/{bu}/locales/lang/{langs}/{module}.ts", prefix = "{bu}.{module}." },
          -- { files = "packages/locales/src/langs/{langs}/{module}.json", prefix = "{module}." },
          -- { files = "src/views/{module}/lang/{langs}.json", prefix = "{module}." }
        }
      }
    })

    -- 集成 fzf-lua 查询 i18n key (改进版本)
    local parser = require("i18n.parser")
    local fzf = require("fzf-lua")

    -- 计算字符串显示宽度（处理中文字符）
    local function display_width(str)
      -- 添加 nil 检查，防止 gmatch 在 nil 值上调用
      if not str or str == "" then
        return 0
      end

      local width = 0
      for char in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if char:byte() > 127 then
          width = width + 2 -- 中文字符宽度为2
        else
          width = width + 1 -- 英文字符宽度为1
        end
      end
      return width
    end

    -- 右填充字符串到指定宽度
    local function pad_right(str, width)
      -- 添加 nil 检查
      str = str or ""

      local current_width = display_width(str)
      if current_width >= width then
        return str
      end
      return str .. string.rep(" ", width - current_width)
    end

    -- 截断过长文本并添加省略号
    local function truncate_text(text, max_width)
      -- 添加 nil 检查
      if not text or text == "" then
        return ""
      end

      if display_width(text) <= max_width then
        return text
      end

      local truncated = ""
      local width = 0
      for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local char_width = char:byte() > 127 and 2 or 1
        if width + char_width > max_width - 3 then -- 留3个字符给省略号
          truncated = truncated .. "..."
          break
        end
        truncated = truncated .. char
        width = width + char_width
      end
      return truncated
    end

    local function show_i18n_keys_with_fzf()
      -- 增加对 parser.translations 的 nil 检查
      local translations = parser.translations or {}
      local keys_map = {}
      for _, lang_tbl in pairs(translations) do
        for k, _ in pairs(lang_tbl) do
          keys_map[k] = true
        end
      end

      local key_list = {}
      for k, _ in pairs(keys_map) do
        table.insert(key_list, k)
      end

      -- 排序 key 列表
      table.sort(key_list)

      -- 获取所有语言
      local langs = require("i18n.config").options.static.langs or {}

      -- 计算每列的最大宽度
      local col_widths = {}
      col_widths[1] = 3 -- "Key" 的宽度
      for i, lang in ipairs(langs) do
        col_widths[i + 1] = display_width(lang)
      end

      -- 计算每个 key 和翻译的最大宽度
      for _, key in ipairs(key_list) do
        local key_str = type(key) == "string" and key or tostring(key or "")
        col_widths[1] = math.max(col_widths[1], display_width(key_str))
        for i, lang in ipairs(langs) do
          local value = ""
          -- 在访问 translations 表格时添加额外的检查
          local lang_data = translations[lang]
          if lang_data and type(lang_data) == 'table' and lang_data[key] ~= nil then
            value = lang_data[key]
          end
          value = type(value) == "string" and value or tostring(value or "")
          col_widths[i + 1] = math.max(col_widths[i + 1], display_width(value))
        end
      end

      -- 限制列宽度，避免过宽
      for i = 2, #col_widths do
        col_widths[i] = math.min(col_widths[i], 50) -- 最大50字符宽度
      end

      -- 构造多列
      local display_list = {}

      -- 构造数据行（不包含表头）
      for _, key in ipairs(key_list) do
        -- 确保 key 是字符串类型
        local key_str = type(key) == "string" and key or tostring(key or "")
        local row = { pad_right(key_str, col_widths[1]) } -- key 列不截断

        for i, lang in ipairs(langs) do
          local value = ""
          local lang_data = translations[lang]
          if lang_data and type(lang_data) == 'table' and lang_data[key] ~= nil then
            value = lang_data[key]
          end
          -- 确保 value 是字符串类型
          value = type(value) == "string" and value or tostring(value or "")
          local truncated_value = truncate_text(value, col_widths[i + 1])
          table.insert(row, pad_right(truncated_value, col_widths[i + 1]))
        end
        table.insert(display_list, table.concat(row, " │ "))
      end

      -- 构造固定的表头
      local header_row = { pad_right("Key", col_widths[1]) }
      for i, lang in ipairs(langs) do
        table.insert(header_row, pad_right(lang, col_widths[i + 1]))
      end
      local header = table.concat(header_row, " │ ")

      -- 构造分隔线
      local separator_parts = {}
      for i = 1, #col_widths do
        table.insert(separator_parts, string.rep("─", col_widths[i]))
      end
      local separator = table.concat(separator_parts, "─┼─")

      fzf.fzf_exec(display_list, {
        prompt = "I18n Key > ",
        header = header .. "\n" .. separator, -- 固定表头
        header_lines = 2,                     -- 固定表头行数
        actions = {
          ["default"] = function(selected)
            if selected and selected[1] then
              local key = selected[1]:match("^([^│]+)"):gsub("%s+$", "")
              vim.notify("选中 key: " .. key)
              -- 可以在这里添加其他操作，比如复制到剪贴板
              vim.fn.setreg('+', key)
            end
          end,
          ["ctrl-c"] = function(selected)
            if selected and selected[1] then
              local key = selected[1]:match("^([^│]+)"):gsub("%s+$", "")
              vim.fn.setreg('+', key)
              vim.notify("已复制 key 到剪贴板: " .. key)
            end
          end,
        },
        fzf_opts = {
          ["--no-multi"] = "",
          ["--layout"] = "reverse",
          ["--info"] = "inline",
          ["--border"] = "rounded",
        }
      })
    end

    vim.keymap.set("n", "<leader>fi", show_i18n_keys_with_fzf, { desc = "模糊查找 i18n key" })
    vim.keymap.set("n", "<D-S-n>", show_i18n_keys_with_fzf, { desc = "模糊查找 i18n key" })
  end
}
