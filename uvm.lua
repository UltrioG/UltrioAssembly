local LATEST_UVM_VERSION = 2

local params = {...}
local filePath = params[1]
local uvmPath = params[2]
local vmVersion = 2
for i, v in ipairs(params) do
	if v == "-v" or v == "--version" then
		---@diagnostic disable-next-line
		vmVersion = tonumber(params[i+1])
		if not vmVersion then
			vmVersion = LATEST_UVM_VERSION
			print(("Warning: No compiler for UAL version %s found."):format(v))
		end
	end
end
local compiler = require(("uvmVersions.uvm%i"):format(vmVersion))
compiler.compileProgram(filePath, uvmPath)