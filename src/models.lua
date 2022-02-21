local utils = require("./utils")
local random = math.random

-- Enum BlockState
local BlockState = {
	blank    = "blank",
	occupied = "occupied",
	attacked = "attacked",
	cleared  = "cleared"
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

local Block = {
	state = BlockState.blank,
	owner = Boat,
	display = "",
}

function Block:new()
	local obj = {}
	setmetatable(obj,self)
	self.__index = self
	obj.state = BlockState.blank
	obj.owner = nil
	obj.display = " "
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
	blocks = {},
	rows = {},  -- array
	cols = {},  -- array
	boats = {}, -- array
}

---- <FieldStateMethod>

function FieldState:new(row_count,col_count)
	local o = {}
	setmetatable(o,self)
	self.__index = self
	o.row_count = row_count
	o.col_count = col_count
	-- Assign new empty blocks
	o.blocks = utils.empty_2d_array(
		row_count,
		col_count,
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
			local block = self.blocks[col][row]
			-- Display as crossed if attacked
			if block.state == BlockState.attacked then
				string = string .. "x."
			else
				string = string .. tostring(block.display) .. "."
			end
		end
		string = string .. "\n"
	end

	utils.log(string)
end

function FieldState:index_coord(coord)
	local row = coord.row
	local col = coord.col

	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		utils.log_err("Row or column is out of range")
		return nil
	end
	-- row col is inversed in 2d array implementation
	return self.blocks[col][row]
end

function FieldState:index(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		utils.log_err("Row or column is out of range")
		return nil
	end
	-- row col is inversed in 2d array implementation
	return self.blocks[col][row]
end

-- Return coord if anything changed
-- Retrun nil if indexing is out of range or nothing has changed
function FieldState:attack(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		utils.log_err("Row or column is out of range")
		return nil
	end

	-- Attack only if occupied
	-- row col is inversed in 2d array implementation
	local block = self.blocks[col][row]
	if block.state == BlockState.occupied then
		block.state = BlockState.attacked

		local boat = block.owner
		boat.hp = boat.hp - 1

		-- Destroy ship which,
		-- removes boat from available stack
		if boat.hp <= 0 then
			utils.remove_from_table(self.boats,boat)
			print("Boat destroyed. Remaining : " .. utils.get_length(self.boats))
		end

		return Coord:new(row,col)
	elseif block.state == BlockState.blank then
		block.state = BlockState.cleared
		return Coord:new(row,col)
	end

	-- Nothing has changed...
	-- It's better not be executed at the first time, ( prevented by client )
	-- but it can happen
	return nil
end


function FieldState:occupy(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		utils.log_err("Row or column is out of range")
		return nil
	end

	-- row col is inversed in 2d array implementation
	self.blocks[col][row].state = BlockState.occupied
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
	local idx = Coord:new(line_index,line_index) -- Default is line_index
	local inc_target = "row" -- Either row or column

	-- Set to col if horizontal
	if dir == Direction.horizontal then 
		inc_target = "col"
	end

	-- Iterate
	for content_index = 1,self:get_line_length(dir) do
		idx[inc_target] = content_index -- Set corresponding index value
		if self:index_coord(idx).state == BlockState.blank then
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
	local min_coord = Coord
	local max_coord = Coord

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

	-- Add boat to boat map
	local boat = Boat:new(min_coord,max_coord,boat_size)
	self.boats[utils.get_length(self.boats) + 1] = boat

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
		local block   = self:index_coord(coord)
		block.state   = BlockState.occupied
		block.owner   = boat
		block.display = boat_name
	end

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

		local iterable = {} -- Array
		for i = 1,self:get_line_length(current_dir) do
			iterable[i] = i
		end

		-- Shuffle for randomess of indexing
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
	row_count = 10,
	col_count = 10,
	boat_sizes = { 3,3,4,5,6,7 },
	id= "",
	player = FieldState,
	computer = FieldState,
}

local GameFlow = {
	On = "on",
	End = "end",
}

function GameState:new(row_count,col_count,boat_sizes)
	if not row_count or not col_count or not boat_sizes then
		utils.log_err("Insufficient arguments for gamestate constructor")
		return nil
	end
	local o = {}
	setmetatable(o,self)
	self.__index  = self
	o.row_count = row_count
	o.col_count = col_count
	o.boat_sizes = boat_sizes
	o.id = utils.uuid()
	o.player = FieldState:new(row_count,col_count)
	o.player:generate_map(boat_sizes)
	o.computer = FieldState:new(row_count,col_count)
	o.computer:generate_map(boat_sizes)
	return o
end

function GameState:check_victory(target)
	if target == "player" then
		if utils.get_length(self.computer.boats) == 0 then
			return true
		end
	else
		if utils.get_length(self.player.boats) == 0 then
			return true
		end
	end

	return false
end

function GameState:try_attack_computer(row,col)
	local changed = self.computer:attack(row,col)

	if self:check_victory("player") then
		return GameFlow.End, changed
	else
		return GameFlow.On, changed
	end
end

function GameState:try_attack_player()
	-- TODO
	-- This is just too naive solution
	-- Make computer more smarter
	local row,col = math.random(1,self.row_count), math.random(1,self.col_count)
	local block = self.player:index(row,col)
	-- Get block again if attacked or cleared
	while block.state == BlockState.attacked or block.state == BlockState.cleared do
		row,col = math.random(1,self.row_count), math.random(1,self.col_count)
		block = self.player:index(row,col)
	end
	local changed = self.player:attack(row,col)

	if self:check_victory("computer") then
		return GameFlow.End, changed
	else
		return GameFlow.On, changed
	end
end

local ActionResult = {
	game_state = GameState,
	new_player_block = {},
	new_computer_block = {},
}

function GameState:player_action(row,col)
	-- Try attacking for both "players"
	local player_flow,computer_changed     = self:try_attack_computer(row,col)
	local computer_flow,player_changed = self:try_attack_player()
	local final_flow = GameFlow.On

	-- Check if flow should change
	if player_flow == GameFlow.End or computer_flow == GameFlow.End then
		final_flow = GameFlow.End
	end

	-- Only send new blocks if there was change
	local p_block,c_block = nil,nil
	if player_changed then
		p_block = {
			state = self.player:index_coord(player_changed).state,
			row = player_changed.row,
			col = player_changed.col,
		}
	end
	if computer_changed then
		c_block = {
			state = self.computer:index_coord(computer_changed).state,
			row = computer_changed.row,
			col = computer_changed.col,
		}
	end

	-- Create result
	local result = {
		state = final_flow,
		player = p_block,
		computer = c_block
	}

	return result
end

return {
	GameFlow = GameFlow,
	GameState = GameState,
}
