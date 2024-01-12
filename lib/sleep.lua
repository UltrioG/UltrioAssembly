local module = {}
local socket = require("socket")

function module.sleep(n)
    socket.sleep(n)
end

return module