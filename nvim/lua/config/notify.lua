local is_available = my.is_available
if is_available("notify") then
  vim.notify = require("notify")
end
