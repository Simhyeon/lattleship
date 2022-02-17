local utils = require("./utils")

local index_file = "index.html"
local fs = require('fs')

-- Sadly it has to be a global variable
connection = {}

-- Send static file
local function game(_, res)
	print("ROUTE--game")
	-- Set options
	res.headers["Content-Type"] = "text/html"
	-- Read file and send to response
	local file = fs.readFileSync(index_file)
	res.body = file
end

-- Create id and send back to user
local function start(_, res)
	print("ROUTE--start")
	-- Set options
	res.headers["Content-Type"] = "text/json"
	-- Read file and send to response
	local id = utils.uuid()
	-- Create unique uuid
	while connection[id] do
		id = utils.uuid()
	end

	-- Add gamestate inside connection
	-- CONNECTION[id] = GameState.new()
	res.body = string.format("{\"conn_id\" : \"%s\"}",id)
end

-- TODO
-- Pick request
local function pick(req,res)
	print("ROUTE--pick")
	res.headers["Content-Type"] = "text/json"
	local body_table = utils.parse_url_body(req.body)
	local state = connection[body_table["id"]]

	-- TODO
	-- Check body and apply information to state

	-- TODO
	-- Send back result
	res.body = "{}"
end

local route = {
	game = game,
	start = start,
	pick = pick,
}

return {
	route = route,
}
