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
	-- Create new random seed
	math.randomseed(os.time())
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

local utils = {
	split_string = split_string,
	parse_url_body = parse_url_body,
	uuid = uuid,
}

return utils
