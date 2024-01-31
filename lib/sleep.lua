local module = {}
local socket = require("socketlink.lnk")

function module.sleep(n)
    socket.sleep(n)
end

return module