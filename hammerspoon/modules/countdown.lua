local M = {}

local remindTimer = nil
local sound = hs.sound.getByName("Glass")

local function remindUser()
  hs.alert.show("Time is up!", 5)
  sound:play()
  remindTimer = nil
end

local function parseTime(input)
  local totalSeconds = 0
  for value, unit in input:gmatch("(%d+)([smh]?)") do
    value = tonumber(value)
    if unit == "s" or unit == "" then
      totalSeconds = totalSeconds + value
    elseif unit == "m" then
      totalSeconds = totalSeconds + value * 60
    elseif unit == "h" then
      totalSeconds = totalSeconds + value * 60 * 60
    end
  end
  return totalSeconds
end

local function formatTime(seconds)
  local hours = math.floor(seconds / 3600)
  local minutes = math.floor(seconds / 60 % 60)
  local remainingSeconds = math.floor(seconds % 60)

  if hours > 0 then
    return tostring(hours) .. " hour" .. (hours > 1 and "s" or "") .. " " .. tostring(minutes) .. " minute" ..
        (minutes > 1 and "s" or "") .. " " .. tostring(remainingSeconds) .. " second" ..
        (remainingSeconds ~= 1 and "s" or "")
  end

  if minutes > 0 then
    return tostring(minutes) .. " minute" .. (minutes > 1 and "s" or "") .. " " .. tostring(remainingSeconds) ..
        " second" .. (remainingSeconds ~= 1 and "s" or "")
  end

  return tostring(remainingSeconds) .. " second" .. (remainingSeconds ~= 1 and "s" or "")
end

function M.startRemindTimer()
  local ok, result = hs.dialog.textPrompt("Remind Timer", "Enter the time (e.g. 5s, 10m, 1h, 1h3m4s):", "20m")

  if ok then
    local time = parseTime(result)

    if time ~= nil and time > 0 then
      remindTimer = hs.timer.doAfter(time, remindUser)
      hs.timer.doAfter(0.3, function()
        local dialogWindow = hs.window.find("Remind Timer")
        if dialogWindow then
          dialogWindow:focus()
        end
      end)
    else
      hs.alert.show("Invalid input, please enter a time in the format of 5s, 10m, or 1h3m4s.")
    end
  end
end

function M.stopRemindTimer()
  if remindTimer ~= nil then
    remindTimer:stop()
    hs.notify.new({
      title = "Reminder",
      informativeText = "Timer Cancelled",
      soundName = "Glass"
    }):send()
    remindTimer = nil
  else
    hs.notify.new({
      title = "Reminder",
      informativeText = "No Timer to cancel",
      soundName = "Glass"
    }):send()
  end
end

function M.getRemainTime()
  if remindTimer ~= nil then
    local remainTime = remindTimer:nextTrigger()
    local timeString = formatTime(remainTime)
    hs.alert.show("Remaining time: " .. timeString)
    sound:play()
  else
    hs.alert.show("No timer is running")
  end
end

return M