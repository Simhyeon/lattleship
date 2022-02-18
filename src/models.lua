local utils = require("./utils")

-- Enum BlockState
local block_state = {
	blank = 1,
	occupied = 2,
	attacked = 3,
}

local FieldState = {
	row = 10,
	col = 10,
	field = {},
}

---- <FieldStateMethod>

-- TODO
-- Implement method of
--
-- generate_ships

-- TODO
-- Rather than empy table, make a whole playable table
function FieldState:new()
	local o = {}
	setmetatable(o,self)
	self.__index = self
	-- Assign new empty field
	o.field = utils.empty_2d_array(
		self.row,
		self.col,
		block_state.blank
	)
	return o
end

-- Return true if succeed
-- Return false if failed
-- Retrun nil if indexing is out of range
function FieldState:attack(row,col)
	if row < 1 or row > self.row or col < 1 or col > self.col then
		print("Row or column is out of range")
		return nil
	end

	-- Attack only if occupied
	-- row col is inversed in 2d array implementation
	if self.field[col][row] == block_state.occupied then
		self.field[col][row] = block_state.attacked
		return true
	end

	return false
end

function FieldState:index(row,col)
	if row < 1 or row > self.row or col < 1 or col > self.col then
		print("Row or column is out of range")
		return nil
	end
	-- row col is inversed in 2d array implementation
	return self.field[col][row]
end

function FieldState:occupy(row,col)
	if row < 1 or row > self.row or col < 1 or col > self.col then
		print("Row or column is out of range")
		return nil
	end
	-- row col is inversed in 2d array implementation
	self.field[col][row] = block_state.occupied
	return true
end

---- </FieldStateMethod>

local game_state = {
	["id"]= "",
	["player"] = FieldState:new(),
	["computer"] = FieldState:new(),
}

return {
	FieldState = FieldState,
	user_state = FieldState,
	game_state = game_state,
}
