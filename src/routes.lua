local utils = require("./utils")
local models= require("./models")

local index_file = "index.html"
local fs = require('fs')
local json = require('json').use_lpeg()
local timer = require('timer')

local check_interval   = 1000 * 30
local timeout_interval = 1000 * 60

-- Sadly it has to be a global variable
local connection = {}
local boat_sizes = { 3,3,4,4,5,6 }

-- Send static file
local function game(_, res)
	print("ROUTE--game")
	-- Set options
	res.headers["Content-Type"] = "text/html"
	res.code = 200
	-- Read file and send to response
	local file = utils.get_raded_index()
	res.body = file
end

-- Create id and send back to user
local function start(_, res)
	print("ROUTE--start")
	-- Set options
	res.headers["Content-Type"] = "text/json"
	res.code = 200
	-- Read file and send to response
	local id = utils.uuid()
	-- Create unique uuid
	-- If id already exists, re-generate
	while connection[id] do
		id = utils.uuid()
	end

	-- Add gamestate inside connection
	local state = models.GameState:new(10,10,boat_sizes)
	connection[id] = {
		state     = state,
		last_time = os.time()
	}

	state.player:debug()
	state.computer:debug()

	local player_blocks = utils.to_simple_block_array(state.player.blocks,state.row_count,state.col_count)
	local computer_blocks = utils.empty_2d_array(state.row_count,state.col_count,"blank")

	-- Send json body to client
	local body = {
		id       = id,
		player   = player_blocks,
		computer = computer_blocks,
	}

	-- This fails because of Block instance wich has "new" method
	res.body = json.stringify(body)
end

-- TODO
-- Pick request
local function pick(req,res)
	print("ROUTE--pick")
	res.headers["Content-Type"] = "text/json"
	res.code = 200

	local body_table = utils.parse_url_body(req.body)
	local state      = connection[body_table["id"]].state
	local result     = state:player_action(
		tonumber(body_table["row"]),
		tonumber(body_table["col"])
	)

	-- Remove connection from it
	if result.winner then
		connection[body_table["id"]] = nil
		utils.log("Game removed")
	end

	-- Update time
	connection[body_table["id"]].last_time = os.time()

	res.body = json.stringify(result)
end

local route = {
	game = game,
	start = start,
	pick = pick,
}

-- Set interval, though this is not the ideal place to call interval
-- Clear timeout connection per minute
timer.setInterval(check_interval, function()
	for i,v in pairs(connection) do
		-- 60 seconds has passed
		if os.time() - v.last_time >= timeout_interval then
			print(i .. " : timeout")
			connection[i] = nil
		end
	end
end)

return {
	route = route,
}
