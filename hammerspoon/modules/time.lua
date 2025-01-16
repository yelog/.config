require("modules.key-map")

if time.currentTime ~= nil then
  hs.hotkey.bind(time.currentTime.prefix, time.currentTime.key, function()
    --show current time
    hs.alert.show(os.date("%A              📅%B %d %Y              🕐%I:%M:%S %p"))
  end)
end
