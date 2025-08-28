_G.my = {}

function my.is_include(item, table)
    for _,v in ipairs(table) do
      if v == item then
          return true
      end
    end
    return false
end

function my.is_wezterm()
  return os.getenv("WEZTERM_EXECUTABLE") ~= nil
end

