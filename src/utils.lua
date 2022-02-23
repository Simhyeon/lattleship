--- Print text to stderr
-- @param text Content to print out
local function log_err(text)
	io.stderr:write(string.format("ERR : %s\n",text))
end

--- Print text to stdout
-- @param text Content to print out
local function log(text)
	io.stdout:write(string.format("%s\n",text))
end

--- Remove value from array-type table
-- @param source Table to remove from
-- @param val Value to remove
local function remove_from_array(source,val)
	local index = nil
	for i, v in ipairs(source) do
		if (v == val) then
			index = i
		end
	end
	if index == nil then
		log_err("Failed to remove key from table.=\nERR : Key does not exist")
	else
		table.remove(source, index)
	end
end

--- Get table length from table
-- @param tbl Table to get length
-- @return Length of the table
local function get_length(tbl)
	local getN = 0
	for _ in pairs(tbl) do
		getN = getN + 1
	end
	return getN
end

--- Shuffle given array-typed table
-- Keep in mind that lua doesn't send copy of table thus
-- shuffle changes source table
-- @param tbl Table to shuffle
-- @return Shuffled table reference
local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

--- Shallow copy table
-- This doesn't copy nested tables properly
-- @param original Original table to copy from
local function shallow_copy(original)
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = value
	end
	return copy
end

--- Create two dimensional array(table) with given value
-- @param row Count of rows
-- @param col Count of columns
-- @param value Value to assign to each coordinate
-- @return Created table
local function empty_2d_array(row,col,value)
	local grid = {}
	for i = 1,col do
		grid[i] = {}
		for j = 1,row do
			-- Copy a given value if the value is a table
			if type(value) == "table" then
				grid[i][j] = shallow_copy(value)
			else
				grid[i][j] = value
			end
		end
	end
	return grid
end

--- Convert blocks table into json.stringify-able table
-- @param source Blocks table to convert
-- @param row Count of rows
-- @param col Count of columns
-- @return Newly created simple block table
local function to_simple_block_array(source,row,col)
	local grid = {}
	for i = 1,col do
		grid[i] = {}
		for j = 1,row do
			grid[i][j] = source[i][j].state
		end
	end
	return grid
end

--- Create 2d array(table) for computer's decision making
-- This is utilized for randomly picking available block space
-- @param row Count of rows
-- @param col Count of columns
-- @return Created 2d array
local function to_computer_cache(row,col)
	local grid = {}
	for i = 1,col do
		for j = 1,row do
			local index = ((i - 1) * col) + j
			grid[index] = {
				row = i,
				col = j,
			}
		end
	end
	return grid
end

--- Split text with given separator
-- @param inputstr Text to split
-- @param sep Separator string
-- @return Splited array table
local function split_string(inputstr, sep)
	if sep == nil or sep == "" then
		sep = "%s"
	end

	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

--- Parse request body and get parsed table
-- @param inputstr Source to parse
-- @return Parsed table(hashmap)
local function parse_url_body(inputstr)
	local parsed_table = split_string(inputstr,"&")
	local body_table = {}
	for _,v in pairs(parsed_table) do
		local split = split_string(v,"=")
		body_table[split[1]] = split[2]
	end
	return body_table
end

--- Create mostly distinctive uuid string
-- @return Generated uuid string
local function uuid()
	local random = math.random
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

--- Get index.file from local directory
-- @return Read file's content as string
local function get_index_file()
	local file = io.open("./bundle.html", "r")
	local data = file:read("*all")
	file:close()
	return data
end

local utils = {
	remove_from_array = remove_from_array,
	get_length = get_length,
	log_err = log_err,
	log = log,
	shuffle = shuffle,
	shallow_copy = shallow_copy,
	to_computer_cache = to_computer_cache,
	to_simple_block_array = to_simple_block_array,
	empty_2d_array = empty_2d_array,
	split_string = split_string,
	parse_url_body = parse_url_body,
	get_index_file = get_index_file,
	uuid = uuid,
}

return utils
