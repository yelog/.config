return {
  "igorlfs/nvim-dap-view",
  dependencies = { "mfussenegger/nvim-dap" },
  cmd = { "DapViewOpen", "DapViewClose", "DapViewToggle" },
  opts = {},
  keys = {
    { "<leader>du", "<cmd>DapViewToggle<cr>", desc = "Toggle DAP view" },
  },
}
