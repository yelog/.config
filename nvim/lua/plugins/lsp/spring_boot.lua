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
    opts = {},
  },
}
