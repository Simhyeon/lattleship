local utils = require("./utils")
local random = math.random

--- Enum BlockState
local BlockState = {
	blank    = "blank",
	occupied = "occupied",
	attacked = "attacked",
	cleared  = "cleared"
}

--- Class coordinate
local Coord = {
	row = 1,
	col = 1,
}

--- Coordinate constructor
-- @param row Row value
-- @param col Column value
-- @return New coord instance
function Coord:new(row,col)
	local o = utils.shallow_copy(self)
	o.row = row
	o.col = col
	return o
end

--- Debug coordinate
function Coord:debug()
	utils.log(string.format("Coord : (%s %s)",self.row , self.col))
end

--- Boat instance
local Boat = {
	start_coord = Coord:new(1,1),
	end_coord = Coord:new(1,1),
	hp = 0,
}

--- Boat constructor
-- @param start_coord Starting coordinate
-- @param end_coord Ending cooridinate
-- @param hp Boat's health point
-- @return New boat instance
function Boat:new(start_coord,end_coord,hp)
	local obj = {}
	setmetatable(obj,self)
	self.__index = self
	obj.start_coord = utils.shallow_copy(start_coord)
	obj.end_coord = utils.shallow_copy(end_coord)
	obj.hp = hp
	return obj
end

--- Block class
local Block = {
	state = BlockState.blank,
	owner = Boat,
	display = "",
}

--- Block constructor
-- @return New block instance
function Block:new()
	local obj = {}
	setmetatable(obj,self)
	self.__index = self
	obj.state = BlockState.blank
	obj.owner = nil
	obj.display = " "
	return obj
end

--- Direction enum
local Direction = {
	horizontal = 1,
	vertical = 2,
}

--- Linestate instance
local LineState = {
	available_space = 0,
}

--- Linestate constructor
-- @return Newly created linestate instance
function LineState:new(space)
	local o = {}
	setmetatable(o,self)
	self.__index  = self
	o.available_space = space
	return o
end

--- FieldState class
local FieldState = {
	row_count = 10,
	col_count = 10,
	blocks = {},
	rows = {},  -- array
	cols = {},  -- array
	boats = {}, -- array
}

---- <FieldStateMethod>

--- FieldState constructor
-- This creates empty blocks with blank blockstate
-- @param row_count Row count of field
-- @param col_count Column count of field
-- @return FiedState instance
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

--- Fieldstate debug function
-- This prints blocks into a human readable form
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

--- Index a block wtih given coordinate
-- @param coord Coorindate instance to index
-- @return indexed block instance
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

--- Index a block wtih given row, column 
-- @param row Block row to index
-- @param row Block column to index
-- @return indexed block instance
function FieldState:index(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		utils.log_err("Row or column is out of range")
		return nil
	end
	-- row col is inversed in 2d array implementation
	return self.blocks[col][row]
end

--- Attack field with given row, column
-- This method tries to attak given block and return affected block
-- nil will be returned if index fails or no block was affected.
-- @param row Block row to attack
-- @param row Block column to attack
-- @retrun Affected block instance
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
			utils.remove_from_array(self.boats,boat)
			utils.log("Boat destroyed. Remaining count of boats are = " .. utils.get_length(self.boats))
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

--- Set block as occupied
-- @param row Block row to occupy
-- @param row Block column to occupy
-- @return if occupy succeeded ( boolean )
function FieldState:occupy(row,col)
	if row < 1 or row > self.row_count or col < 1 or col > self.col_count then
		utils.log_err("Row or column is out of range")
		return nil
	end

	-- row col is inversed in 2d array implementation
	self.blocks[col][row].state = BlockState.occupied
	return true
end

--- Get lines by direction
-- @param dir Direction to decide which line to get
-- @return Lines
function FieldState:get_lines(dir)
	if dir == Direction.vertical then
		return self.cols
	else
		return self.rows
	end
end

--- Get line length by direction
-- @param dir Direction to decide which line length to get
-- @return Lines count
function FieldState:get_line_length(dir)
	if dir == Direction.vertical then
		return self.row_count
	else
		return self.col_count
	end
end

--- Get available boat position's start and end index
-- This will get randomized boat position within given line
-- @param dir Direction
-- @param boat_size Boat size
-- @param line_index Index of line to calculate
-- @return Boat's start index
-- @return Boat's end index
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

--- Get coordinate from line content's start and end index
-- Because content's index is line specific index it needs to be converted to
-- global coordintate instance
-- @param current_dir Direction
-- @param line_index Line index
-- @param content_index_start Start index
-- @param content_index_end End index
-- @return Start coordinate
-- @return End coordinate
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

--- Construct boat and set into data list
-- @param current_dir Direction
-- @param boat_size Size of boat
-- @param line_index Index of a line for boat to be set
-- @param If the boat has ben constructed or not (boolean)
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

--- Place a boat for given boat size
-- @param boat_size Size of boat
-- @return If place succeeded or not (boolean)
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

--- Generate field map
-- @param boat_sizes Array of boat sizes
function FieldState:generate_map(boat_sizes)
	for _,size in ipairs(boat_sizes) do
		self:place_boat(size)
	end
end

---- </FieldStateMethod>

--- Total states of game
local GameState = {
	row_count = 10,
	col_count = 10,
	boat_sizes = {},
	id= "",
	player = FieldState,
	computer = FieldState,
	pick_cache = {},
}

--- GameFlow enum
local GameFlow = {
	On = "on",
	End = "end",
}

--- GameState constructor
-- @param row_count Count of field rows
-- @param col_count Count of field columns
-- @param boat_size Base array for boat sizes
-- @return Newly creaed gamestate instance
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
	o.pick_cache = utils.to_computer_cache(row_count,col_count)
	return o
end

--- Check if target has won or not
-- @param target The actor
-- @return If actor won or not (boolean)
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

--- Try attack computer by player
-- @param row Block's row to attack
-- @param col Block's col to attack
-- @return GameFlow
-- @return Changed block instance
function GameState:try_attack_computer(row,col)
	local changed = self.computer:attack(row,col)

	if self:check_victory("player") then
		return GameFlow.End, changed
	else
		return GameFlow.On, changed
	end
end

--- Try attack player by computer
-- @param row Block's row to attack
-- @param col Block's col to attack
-- @return GameFlow
-- @return Changed block instance
function GameState:try_attack_player()
	-- NOTE
	-- This can possibly improved though...
	local index = math.random(1,utils.get_length(self.pick_cache))
	local pick = self.pick_cache[index]
	local changed = self.player:attack(
		tonumber(pick.row),
		tonumber(pick.col)
	)

	-- Empty picked value from cache
	utils.remove_from_array(self.pick_cache, pick)

	if self:check_victory("computer") then
		return GameFlow.End, changed
	else
		return GameFlow.On, changed
	end
end

--- Player action called by server route
-- @param row Target block's row
-- @param col Target block's column
-- @return Result of player action
function GameState:player_action(row,col)
	-- Try attacking for both "players"
	local player_flow,computer_changed = self:try_attack_computer(row,col)
	local computer_flow,player_changed = self:try_attack_player()
	local winner = nil

	-- Check if flow should change
	if player_flow == GameFlow.End then
		winner = "player"
	elseif computer_flow == GameFlow.End then
		winner = "computer"
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
		winner = winner,
		player = p_block,
		computer = c_block
	}

	return result
end

return {
	GameFlow = GameFlow,
	GameState = GameState,
}
