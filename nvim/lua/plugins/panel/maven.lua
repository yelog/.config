return {
  dir = "~/workspace/vi/maven.nvim",
  name = "maven.nvim",
  lazy = false,
  cmd = {
    "Maven", "MavenExec", "MavenInit", "MavenFavorites",
    "MavenProfiles", "MavenProfilesClear", "MavenPresetAdd", "MavenPresetRemove", "MavenDependencies",
  },
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    mvn_executable = "mvn",
    project_scanner_depth = 5,
    projects_view = {
      position = "right",
      size = 55,
    },
    console = {
      show_dependencies_load_execution = true,
    },
  },
  config = function(_, opts)
    require("maven").setup(opts)
  end,
}
