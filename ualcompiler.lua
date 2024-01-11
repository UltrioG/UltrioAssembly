local LATEST_UAL_VERSION = 2

local params = {...}
local filePath = params[1]
local umcPath = params[2]
local compilerVersion = 2
for i, v in ipairs(params) do
	if v == "-v" or v == "--version" then
		---@diagnostic disable-next-line
		compilerVersion = tonumber(params[i+1])
		if not compilerVersion then
			compilerVersion = LATEST_UAL_VERSION
			print(("Warning: No compiler for UAL version %s found."):format(v))
		end
	end
end
local compiler = require(("ualVersions.ual%icompiler"):format(compilerVersion))
compiler.compileProgram(filePath, umcPath)