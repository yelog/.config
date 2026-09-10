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
      local _, launcher_home = require("custom.java_runtime").discover()
      return {
        -- Spring Boot Tools follows JAVA_HOME by default. Keep it on the
        -- JDTLS-compatible JVM without changing the project's Java runtime.
        java_cmd = launcher_home and (launcher_home .. "/bin/java") or nil,
      }
    end,
  },
}
