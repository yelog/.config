return {
  "oclay1st/maven.nvim",
  cmd = { "Maven", "MavenExec", "MavenInit", "MavenFavorites" },
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    mvn_executable = "mvn",
    project_scanner_depth = 5,
    projects_view = {
      position = "right",
      size = 55,
    },
  },
  config = function(_, opts)
    require("maven").setup(opts)
    require("custom.maven_project_tree").install()
    require("custom.maven_profiles").apply_current()
  end,
}
