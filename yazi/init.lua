-- https://github.com/yazi-rs/plugins/tree/main/git.yazi
th.git = th.git or {}
th.git.modified_sign = "M"
th.git.deleted_sign = "D"
th.git.added_sign = "A"
th.git.modified = ui.Style():fg("blue")
th.git.deleted = ui.Style():fg("red"):bold()

require("git"):setup {}

require("quicklook"):setup({
  showPreviewNotification = true,
})
