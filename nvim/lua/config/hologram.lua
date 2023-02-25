require('hologram').setup{
    auto_display = true -- WIP automatic markdown image display, may be prone to breaking
}
-- Require and call setup function somewhere in your init.lua
require('image').setup {
  render = {
    min_padding = 1,
    show_label = true,
    use_dither = true,
    foreground_color = true,
    background_color = true
  },
  events = {
    update_on_nvim_resize = true,
  },
}
