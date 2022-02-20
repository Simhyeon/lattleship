local function log_err(text)
	io.stderr:write(string.format("ERR : %s\n",text))
end

local function log(text)
	io.stdout:write(string.format("%s\n",text))
end

-- Shuffle
local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

-- Shallow copy table
-- doesn't copy nested tables properly
local function shallow_copy(original)
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = value
	end
	return copy
end

-- Two dimensional array
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

local function to_simple_block_array(source,row,col)
	local grid = {}
	for i = 1,col do
		grid[i] = {}
		for j = 1,row do
			-- Copy a given value if the value is a table
			grid[i][j] = source[i][j].state
		end
	end
	return grid
end

-- Split command with given separator
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

-- Parse body and return
-- Though this is for very limited usage
local function parse_url_body(inputstr)
	local parsed_table = split_string(inputstr,"&")
	local body_table = {}
	for _,v in pairs(parsed_table) do
		local split = split_string(v,"=")
		body_table[split[1]] = split[2]
	end
	return body_table
end

local function uuid()
	local random = math.random
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function get_raded_index()
	local file = io.popen("./rad index.html -a fin", "r")
	local data = file:read("*all")
	file:close()
	return data
end

local utils = {
	log_err = log_err,
	log = log,
	shuffle = shuffle,
	shallow_copy = shallow_copy,
	to_simple_block_array = to_simple_block_array,
	empty_2d_array = empty_2d_array,
	split_string = split_string,
	parse_url_body = parse_url_body,
	get_raded_index = get_raded_index,
	uuid = uuid,
}

return utils
