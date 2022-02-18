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
	print(string.format("From : (%s %s)",self.row , self.col))
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
	obj.owner = nil
	return obj
end

-- Direction enum
local Direction = {
	horizontal = 1,
	vertical = 2,
}

local LineState = {
	start_index = nil,
	end_index = nil,
	available_maxium_space = 0,
}

function LineState:new(start_index,end_index,space)
	local o = {}
	setmetatable(o,self)
	self.__index  = self
	o.start_index = start_index
	o.end_index   = end_index
	o.available_maxium_space = space
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
		self.row_count,
		self.col_count,
		Block:new()
	)
	-- Declare values
	for i = 1,self.row_count do
		o.cols[i] = LineState:new(1,self.row_count,self.row_count)
	end
	for i = 1,self.col_count do
		o.rows[i] = LineState:new(1,self.col_count,self.col_count)
	end
	o.boats = {}
	return o
end

function FieldState:debug()
	local string = ""
	for row = 1,self.col_count do
		for col = 1,self.row_count do
			string = string .. tostring(self.field[col][row].state) .. ","
		end
			string = string .. "\n"
	end

	print(string)

	for i,v in pairs(self.boats) do
		print("I : " .. i)
		v.start_coord:debug()
		v.end_coord:debug()
	end
end

-- Return true if succeed
-- Return false if failed
-- Retrun nil if indexing is out of range
function FieldState:attack(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		print("Row or column is out of range")
		return nil
	end

	-- Attack only if occupied
	-- row col is inversed in 2d array implementation
	if self.field[col][row].state == BlockState.occupied then
		self.field[col][row].state = BlockState.attacked
		return true
	end

	-- TODO
	-- Check destroyed ships

	return false
end

function FieldState:index_coord(coord)
	local row = coord.row
	local col = coord.col

	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		print("Row or column is out of range")
		return nil
	end
	-- row col is inversed in 2d array implementation
	return self.field[col][row]
end

function FieldState:index(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		print("Row or column is out of range")
		return nil
	end
	-- row col is inversed in 2d array implementation
	return self.field[col][row]
end

function FieldState:occupy(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		print("Row or column is out of range")
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

function FieldState:get_line_content_start_end(boat_size,line_length,line)
	local content_index_start,content_index_end = 0,0
	-- from end index to line_length
	if line_length - line.end_index > boat_size then
		content_index_start = line.end_index
		content_index_end   = line_length
	else -- From 1 to start index
		content_index_start = 1
		content_index_end   = line.end_index
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

	print("Line index : " .. line_index)
	print("Adding boat of ... dir = " .. current_dir)
	min_coord:debug()
	max_coord:debug()

	return min_coord,max_coord
end

function FieldState:get_offset_index_start_end(boat_size,content_index_start, content_index_end)
	-- set offset
	-- remainder can be 0
	local remainder = (content_index_end - content_index_start) - boat_size
	local start_offset = random(0,remainder)
	local end_offset = remainder - start_offset
	content_index_start = content_index_start + start_offset
	content_index_end = content_index_end - end_offset
	return content_index_start, content_index_end
end

function FieldState:construct_boat(current_dir,boat_size,line,line_index)
	-- Name is simply a boat size to string
	local boat_name   = tostring(boat_size)
	local lines_iter  = self:get_lines(current_dir)
	local line_length = self:get_line_length(current_dir)

	-- Get line's content indices
	local content_index_start,content_index_end
		= self:get_line_content_start_end(boat_size,line_length,line);

	-- Set offset for indices
	content_index_start, content_index_end =
		self:get_offset_index_start_end(boat_size,content_index_start,content_index_end);

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
	line_state.start_index            = content_index_start
	line_state.end_index              = content_index_end
	line_state.available_maxium_space = line_length - boat_size
end

-- TODO
-- Direction ought be placed outside? Not inside?
function FieldState:place_boat(boat_size)
	local placed = false
	while not placed do
		-- TODO DEBUG
		-- Remove this line
		-- TODO
		-- Swap direction when it didn't find anything
		-- Rather than random distribution, make it uniformly distributed
		-- Also line iteration can be also randomized
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
			if line.available_maxium_space >= boat_size then
				-- Construct boat
				self:construct_boat(current_dir,boat_size,line,index)

				-- BREAK from loop
				placed = true -- break while loop by setting conditional variable
				break         -- Break lines loop
			end
		end -- End lines iteration
	end     -- End while loop
end         -- End function

function FieldState:generate_map()
	local boat_sizes = { 5,6,7,8,9 }
	-- local boat_sizes = {5,6}

	for _,size in ipairs(boat_sizes) do
		print("Set boat of " .. size)
		self:place_boat(size)
	end
end

---- </FieldStateMethod>

local game_state = {
	["id"]= "",
	--["player"] = FieldState:new(),
	--["computer"] = FieldState:new(),
}

return {
	FieldState = FieldState,
	user_state = FieldState,
	game_state = game_state,
}
