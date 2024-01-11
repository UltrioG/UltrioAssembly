local sleep = require("lib.sleep")
local pprint = require("lib.inspect")
local BITCOUNT = 8

---@class VirtualMachine
local VM = {
	VERSION = 2,
	PC = 0,
	A = 0,
	C = 0,
	RAM = {},
	Flags = {
		ZERO = false,
		POSITIVE = false,
		OVERFLOW = false
	},
	variables = {},
	currentInstruction = nil
}

---@alias register
---|0 A register
---|1 C register
---|2 X register

---Gets the register value based on index of the register
---@param n register
function VM:getRegisterValue(n)
	if n == 0 then
		return self.A
	elseif n == 1 then
		return self.C
	elseif n == 2 then
		self.RAM[self.A] = self.RAM[self.A] or 0
		return self.RAM[self.A]
	end
end

---Sets the X register, hence the memory address pointed to by A
---@param v integer
function VM:setX(v)
	self.RAM[self.A] = v
end

---Gets the register value based on index of the register
---@param r register
---@param v integer
function VM:setRegisterValue(r, v)
	self.Flags.OVERFLOW = v > 2^BITCOUNT-1
	local v = v%2^BITCOUNT
	if r == 0 then
		self.A = v
	elseif r == 1 then
		self.C = v
	elseif r == 2 then
		self:setX(v)
	end
end

local instructions
---@type table<integer, fun(vm: VirtualMachine): (0 | fun(r:register): (fun(r2:register):0)|(fun(v:integer):0)) >
instructions = {
	[0x00] = function(M)
		return function (R)
			return function (v)
				M:setRegisterValue(R, v)
				return 0
			end
		end
	end,
	[0x10] = function()
		return function ()
			return function ()
				return 0
			end
		end
	end,
	[0x20] = function(M)
		return function (r)
			return function (r2)
				M:setRegisterValue(r, M:getRegisterValue(r2))
				return 0
			end
		end
	end,
	[0x40] = function(M)
		local C = M:getRegisterValue(1)
		M.Flags.POSITIVE = C > 0
		M.Flags.ZERO = C == 0
		return 0
	end,
	[0x60] = function(M)
		local C = M:getRegisterValue(2)
		---@diagnostic disable-next-line
		M.PC = C
		return 0
	end,
	[0x64] = function()
		return function ()
			return 0
		end
	end,
	[0x68] = function(M)
		if M.Flags.POSITIVE or M.Flags.ZERO then return 0 end
		return instructions[0x60](M)
	end,
	[0x6A] = function(M)
		if M.Flags.POSITIVE then return 0 end
		return instructions[0x60](M)
	end,
	[0x6C] = function(M)
		if M.Flags.ZERO then return 0 end
		return instructions[0x60](M)
	end,
	[0x80] = function(M)
		return function (r)
			return function (r2)
				local R1 = M:getRegisterValue(r)
				local R2 = M:getRegisterValue(r)
				M:setRegisterValue(1, R1 | R2)
				return 0
			end
		end
	end,
	[0x90] = function(M)
		return function (r)
			return function (r2)
				local R1 = M:getRegisterValue(r)
				local R2 = M:getRegisterValue(r)
				M:setRegisterValue(1, R1 ~ R2)
				return 0
			end
		end
	end,
	[0xA0] = function(M)
		return function (r)
			return function (r2)
				local R1 = M:getRegisterValue(r)
				local R2 = M:getRegisterValue(r)
				M:setRegisterValue(1, R1 + R2)
				return 0
			end
		end
	end,
	[0xB0] = function(M)
		local C = M:getRegisterValue(1)
		M:setRegisterValue(1, 2^BITCOUNT - C)
		return 0
	end,
	[0xC0] = function(M)
		return function (r)
			return function (r2)
				local R1 = M:getRegisterValue(r)
				local R2 = M:getRegisterValue(r)
				M:setRegisterValue(1, R1 & R2)
				return 0
			end
		end
	end,
}

---Executes the given byte based on current state
---@param instr integer
function VM:decode(instr)
	if (not self.currentInstruction) or self.currentInstruction == 0 then
		self.currentInstruction = instructions[instr](self)
	else
		self.currentInstruction = self.currentInstruction(instr)
	end
end


function VM:execute(filePath)
	local file = io.open(filePath, "rb")
	if not file then print("FileOpeningError while opening source: No file found") end
	if not filePath:match(("%%.umc%i"):format(self.VERSION)) then
		print(("FileOpeningError while opening source: File being opened is not a .umc%i file."):format(self.VERSION))
	end

	---@type file*
	---@diagnostic disable-next-line
	file = file

	---@type string
	local fileStr = file:read("a")
	local run = true
	while run do
		for _ = 1, 60 do
			self.PC = self.PC + 1
			local byteChar = fileStr:sub(self.PC, self.PC)
			if byteChar == "" then run = false break end
			self:decode(byteChar:byte())
		end
		sleep.sleep(1/60)
	end
	print("Exection complete, RAM state:")
	pprint.inspect(VM.RAM)
end

return VM