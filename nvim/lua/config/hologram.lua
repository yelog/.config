local is_available = my.is_available
if is_available("hologram") then
  require("hologram").setup({
    auto_display = true, -- WIP automatic markdown image display, may be prone to breaking
  })
end
if is_available("image") then
  -- Require and call setup function somewhere in your init.lua
  require("image").setup({
    render = {
      min_padding = 1,
      show_label = true,
      use_dither = true,
      foreground_color = true,
      background_color = true,
    },
    events = {
      update_on_nvim_resize = true,
    },
  })
end
