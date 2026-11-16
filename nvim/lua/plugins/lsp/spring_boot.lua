return {
  {
    "JavaHello/spring-boot.nvim",
    event = {
      "BufReadPre *.java",
      "BufNewFile *.java",
      "BufReadPre application*.yml",
      "BufNewFile application*.yml",
      "BufReadPre application*.yaml",
      "BufNewFile application*.yaml",
      "BufReadPre bootstrap*.yml",
      "BufNewFile bootstrap*.yml",
      "BufReadPre bootstrap*.yaml",
      "BufNewFile bootstrap*.yaml",
      "BufReadPre application*.properties",
      "BufNewFile application*.properties",
      "BufReadPre bootstrap*.properties",
      "BufNewFile bootstrap*.properties",
    },
    dependencies = { "neovim/nvim-lspconfig" },
    opts = function()
      local _, launcher_home, launcher_error = require("custom.java_runtime").discover()
      if not launcher_home then
        vim.notify_once(launcher_error or "Spring Boot LS requires JDK 25 or newer", vim.log.levels.ERROR)
      end
      return {
        -- Spring Boot Tools follows JAVA_HOME by default. Keep it on the
        -- JDTLS-compatible JVM without changing the project's Java runtime.
        java_cmd = launcher_home and (launcher_home .. "/bin/java") or nil,
        autocmd = launcher_home ~= nil,
        server = { exit_timeout = 10000 },
      }
    end,
  },
}
