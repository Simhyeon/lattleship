local utils = require("./utils")
local random = math.random

-- Enum BlockState
local BlockState = {
	blank = 1,
	occupied = 2,
	attacked = 3,
}

local Coord = {
	row = 1,
	col = 1,
}

function Coord:new(row,col)
	local o = utils.shallow_copy(self)
	o.row = row
	o.col = col
	return o
end

function Coord:debug()
	utils.log(string.format("From : (%s %s)",self.row , self.col))
end

local Boat = {
	start_coord = Coord:new(1,1),
	end_coord = Coord:new(1,1),
	hp = 0,
}

function Boat:new(start_coord,end_coord,hp)
	local obj = {}
	setmetatable(obj,self)
	self.__index = self
	obj.start_coord = utils.shallow_copy(start_coord)
	obj.end_coord = utils.shallow_copy(end_coord)
	obj.hp = hp
	return obj
end

local Block =  {
	state = BlockState.blank,
	owner = nil,
}

function Block:new()
	local obj = {}
	setmetatable(obj,self)
	self.__index = self
	obj.state = BlockState.blank
	obj.owner = " "
	return obj
end

-- Direction enum
local Direction = {
	horizontal = 1,
	vertical = 2,
}

local LineState = {
	available_space = 0,
}

function LineState:new(space)
	local o = {}
	setmetatable(o,self)
	self.__index  = self
	o.available_space = space
	return o
end

local FieldState = {
	row_count = 10,
	col_count = 10,
	field = {},
	rows = {},  -- array
	cols = {},  -- array
	boats = {}, -- array
}

---- <FieldStateMethod>

function FieldState:new()
	local o = {}
	setmetatable(o,self)
	self.__index = self
	-- Assign new empty field
	o.field = utils.empty_2d_array(
		self.row_count,
		self.col_count,
		Block:new()
	)
	-- Declare values
	for i = 1,self.row_count do
		o.cols[i] = LineState:new(self.row_count)
	end
	for i = 1,self.col_count do
		o.rows[i] = LineState:new(self.col_count)
	end
	o.boats = {}
	return o
end

function FieldState:debug()
	local string = ""
	for row = 1,self.col_count do
		for col = 1,self.row_count do
			string = string .. tostring(self.field[col][row].owner) .. ","
		end
			string = string .. "\n"
	end

	utils.log(string)

	for i,v in pairs(self.boats) do
		utils.log("I : " .. i)
		v.start_coord:debug()
		v.end_coord:debug()
	end
end

function FieldState:index_coord(coord)
	local row = coord.row
	local col = coord.col

	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		utils.log_err("Row or column is out of range")
		return nil
	end
	-- row col is inversed in 2d array implementation
	return self.field[col][row]
end

function FieldState:index(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		utils.log_err("Row or column is out of range")
		return nil
	end
	-- row col is inversed in 2d array implementation
	return self.field[col][row]
end

-- Return true if succeed
-- Return false if failed
-- Retrun nil if indexing is out of range
function FieldState:attack(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		utils.log_err("Row or column is out of range")
		return nil
	end

	-- Attack only if occupied
	-- row col is inversed in 2d array implementation
	local block = self.field[col][row]
	if block.state == BlockState.occupied then
		block.state = BlockState.attacked
		self.boats[block.owner].hp = self.boats[block.owner].hp - 1
		return true
	end

	--  Make attack methodTODO
	-- Check destroyed ships

	return false
end


function FieldState:occupy(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		utils.log_err("Row or column is out of range")
		return nil
	end

	-- row col is inversed in 2d array implementation
	self.field[col][row].state = BlockState.occupied
	return true
end

function FieldState:get_lines(dir)
	if dir == Direction.vertical then
		return self.cols
	else
		return self.rows
	end
end

function FieldState:get_line_length(dir)
	if dir == Direction.vertical then
		return self.row_count
	else
		return self.col_count
	end
end

-- Return value of nil,nil means space is not sufficient
function FieldState:get_line_content_start_end(dir,boat_size,line_index)
	-- Initial value
	local content_index_start,content_index_end = nil,nil
	local remainder = 0

	-- Index coordinate that is used for iteration
	local index_coord = Coord:new(line_index,line_index) -- Default is line_index
	local inc_target = "row" -- Either row or column

	-- Set to col if horizontal
	if dir == Direction.horizontal then 
		inc_target = "col"
	end

	-- Iterate
	for content_index = 1,self:get_line_length(dir) do
		index_coord[inc_target] = content_index -- Set corresponding index value
		if self:index_coord(index_coord).state == BlockState.blank then
			if not content_index_start then -- Start is nil
				content_index_start = content_index
				content_index_end = content_index
			else -- consequent blocks
				content_index_end = content_index

				-- surplus blocks
				if content_index_end - content_index_start >= boat_size then
					remainder = remainder + 1
				end
			end
		else -- Found non-blank value
			if content_index_start and content_index_end then
				-- Sufficient boat spce
				if content_index_end - content_index_start >= boat_size then
					break
				end
			end
			-- Insufficient boat space
			content_index_start, content_index_end = nil,nil
			remainder = 0
		end
	end

	if content_index_start and content_index_end then

		-- Check if boat space is sufficient
		if content_index_end - content_index_start < boat_size then
			return nil,nil
		end

		-- Calculate offset and randomize boat position
		if remainder ~= 0 then
			local start_offset = random(0,remainder)
			local end_offset = remainder - start_offset
			content_index_start = content_index_start + start_offset
			content_index_end = content_index_end - end_offset
		end
	end

	return content_index_start, content_index_end
end

function FieldState:get_coord_start_end(current_dir,line_index,content_index_start,content_index_end)
	local min_coord = {}
	local max_coord = {}

	if current_dir == Direction.vertical then
		min_coord = Coord:new(content_index_start,line_index)
		max_coord = Coord:new(content_index_end,line_index)
	else
		min_coord = Coord:new(line_index,content_index_start)
		max_coord = Coord:new(line_index,content_index_end)
	end

	return min_coord,max_coord
end

function FieldState:construct_boat(current_dir,boat_size,line_index)
	-- Name is simply a boat size to string
	local boat_name   = tostring(boat_size)
	local lines_iter  = self:get_lines(current_dir)

	-- Get line's content indices
	local content_index_start,content_index_end
		= self:get_line_content_start_end(current_dir,boat_size,line_index);

	if not content_index_start then
		return false
	end

	-- This should come after setting offset
	-- Get min,max coord of boat object
	local min_coord,max_coord = self:get_coord_start_end(
		current_dir,
		line_index,
		content_index_start,
		content_index_end
	);

	-- Set default value for iteration coord value
	local coord = Coord:new(line_index,line_index)

	-- Iterate line contents and update block information
	for content_index = content_index_start,content_index_end do
		-- Set row and col_index according a type of a line
		if current_dir == Direction.vertical then
			-- Vertical : Rows increment
			coord.row = content_index
		else
			-- Horizontal : Columns increment
			coord.col = content_index
		end

		-- Set block as occupied and set owner
		local block = self:index_coord(coord)
		block.state = BlockState.occupied
		block.owner = boat_name
	end

	-- Add boat to boat map
	local boat = Boat:new(min_coord,max_coord,boat_size)
	self.boats[boat_name] = boat

	-- Update information
	local line_state = lines_iter[line_index]
	line_state.available_space = line_state.available_space - boat_size

	return true
end

function FieldState:place_boat(boat_size)
	local placed = false
	while not placed do
		-- Get random direction
		local current_dir = random(Direction.horizontal, Direction.vertical)

		-- Set local loop variants
		local lines = self:get_lines(current_dir)

		local iterable = {}
		for i = 1,self:get_line_length(current_dir) do
			iterable[i] = i
		end

		local shuffled = utils.shuffle(iterable)

		-- Iterate through lines and find 'placeable' line
		for _,index in pairs(shuffled) do
			local line = lines[index]
			-- Line has enough space to place boat
			if line.available_space >= boat_size then
				-- Construct boat
				local success = self:construct_boat(current_dir,boat_size,index)

				-- BREAK from loop
				if success then
					placed = true -- break while loop by setting conditional variable
					break         -- Break lines loop
				end

			end
		end -- End lines iteration
	end     -- End while loop
end         -- End function

function FieldState:generate_map(boat_sizes)
	for _,size in ipairs(boat_sizes) do
		self:place_boat(size)
	end
end

---- </FieldStateMethod>

local GameState = {
	boat_sizes = { 3,3,4,5,6,7 },
	id= "",
	player = {},
	computer = {},
}

function GameState:new()
	local o = {}
	setmetatable(o,self)
	self.__index  = self
	o.id = utils.uuid()
	o.player = FieldState:new()
	o.player:generate_map(self.boat_sizes)
	o.computer = FieldState:new()
	o.computer:generate_map(self.boat_sizes)
	return o
end

return {
	GameState = GameState,
}
