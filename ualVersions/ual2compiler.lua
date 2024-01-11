local module = {
	VERSION = 2
}

function module.compileProgram(...)
	local compilerVer = module.VERSION

	local params = {...}
	local filePath = params[1]
	local umcPath = params[2]
	local file = io.open(filePath, "r")
	local writeFile = io.open(umcPath,"w+b")
	if not file then print("FileOpeningError while opening source: No file found") end
	if not writeFile then print("FileOpeningError while opening destination: No file found") end
	if not filePath:match(("%%.ual%i"):format(compilerVer)) then
		print(("FileOpeningError while opening source: File being opened is not a .ual%i file."):format(compilerVer))
	end
	if not umcPath:match(("%%.umc%i"):format(compilerVer)) then
		print(("FileOpeningError while opening destination: File being opened is not a .umc%i file."):format(compilerVer))
	end

	---@diagnostic disable
	---@type file*
	file = file
	---@type file*
	writeFile = writeFile
	---@diagnostic enable

	---@type string
	local fileStr = file:read("a")
	fileStr = fileStr:gsub(";.+\n", ""):gsub("%s+", " "):gsub("%s$", "")

	local instrAddr = {
		LDN = 0x00,
		DEF = 0x10,
		LDR = 0x20,
		CMP = 0x40,
		JMP = 0x60,
		LBL = 0x64,
		JLZ = 0x68,
		JGZ = 0x6A,
		JEZ = 0x6C,
		JSR = 0x70,
		BOR = 0x80,
		XOR = 0x90,
		ADD = 0xA0,
		NEG = 0xB0,
		AND = 0xC0
	}

	local regAddr = {
		A = 0, C = 1, X = 2
	}

	local variables = {}

	---Swaps the keys and items of a dictionary
	---@generic T
	---@generic U
	---@param T table<T, U>
	local function swapKeyAndItem(T)
		local new = {}
		for k, v in pairs(T) do
			new[v] = k
		end
		return new
	end

	local PC = 1
	local newVar = false
	local awaitValue = false
	local awaitFunc = nil
	local prog = ""
	for word in fileStr:gmatch("%w+") do
		local val = nil
		if instrAddr[word] then val = instrAddr[word] end
		if regAddr[word] then val = regAddr[word] end
		if word == "LBL" then newVar = true end
		if word == "DEF" then awaitValue = true newVar = true end
		if not val then
			if word:lower():sub(1,2) == "0x" then
				val = tonumber(word:sub(3,-1), 16)
			elseif word:lower():sub(1,2) == "0b" then
				val = tonumber(word:sub(3,-1), 2)
			elseif word:match("%D") == "fail" then
				val = tonumber(word)
			elseif variables[word] then
				val = variables[word]
			elseif newVar then
				if awaitValue then
					if awaitFunc then
						awaitFunc(val)
					else
						awaitFunc = function (newval)
							local varswap = swapKeyAndItem(variables)
							local newval = newval
							if varswap[newval] then
								repeat
									newval = newval + 1
								until not varswap[newval]
							end
							variables[word] = newval
							awaitFunc = nil
							newVar = false
							awaitValue = false
						end
					end
				else
					val = PC
					variables[word] = PC
				end
			else
				val = 0x00
			end
			if not val then val = 0x00 end
		end

		prog = prog..string.char(val)

		PC = PC + 1
	end

	writeFile:write(prog)
	file:close()
	writeFile:close()
	print("Compilation complete. Note that the compiler does not check for any errors.")
end

return module