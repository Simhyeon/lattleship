local utils = require("./utils")
local models= require("./models")

local json = require('json').use_lpeg()
local timer = require('timer')

local check_interval   = 1000 * 30
local timeout_interval = 1000 * 60

-- Sadly it has to be a global variable
local connection = {}
local boat_sizes = { 3,3,4,4,5,6 }

--- Default root route for game
-- Send static file
-- @pram _
-- @pram req Request
local function game(_, res)
	utils.log("ROUTE--game")
	-- Set options
	res.headers["Content-Type"] = "text/html"
	res.code = 200
	-- Read file and send to response
	local file = utils.get_index_file()
	res.body = file
end

--- "Start" route
-- Create id with game, add to connection and send back information to user
-- @pram _
-- @pram req Request
local function start(_, res)
	utils.log("ROUTE--start")
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

--- "Refresh" route
-- Refresh connections last update time
-- @pram _
-- @pram req Request
local function refresh(req,res)
	utils.log("ROUTE--refresh")
	res.headers["Content-Type"] = "text/json"
	res.code = 200 -- Default is ok

	local body_table = utils.parse_url_body(req.body)
	local id = body_table["id"]

	if id then
		local conn = connection[id]
		if conn then
			-- Update time
			conn.last_time = os.time()
		else
			res.code = 400
			res.body = string.format("{\"error\" : \"Given id is not registered\"}")
		end
	else -- No id in parameter
		-- Bad request
		res.code = 400
		res.body = string.format("{\"error\" : \"No id in post parameter\"}")
	end

	res.body = "{}"
end

--- "Pick" route
-- Get player's pick information, execute player_action method and send result
-- @pram res Response
-- @pram req Request
local function pick(req,res)
	utils.log("ROUTE--pick")
	res.headers["Content-Type"] = "text/json"
	res.code = 200 -- Default is ok

	local body_table = utils.parse_url_body(req.body)
	local id = body_table["id"]

	if id then
		local conn = connection[id]
		if conn then
			local state      = conn.state
			local result     = state:player_action(
				tonumber(body_table["row"]),
				tonumber(body_table["col"])
			)

			-- Update time
			conn.last_time = os.time()

			-- Remove connection from it
			if result.winner then
				connection[body_table["id"]] = nil
				utils.log("ID removed from connection")
			end

			res.body = json.stringify(result)
		else
			res.code = 400
			res.body = string.format("{\"error\" : \"Given id is not registered\"}")
		end
	else -- No id in parameter
		-- Bad request
		res.code = 400
		res.body = string.format("{\"error\" : \"No id in post parameter\"}")
	end
end

local route = {
	game = game,
	start = start,
	pick = pick,
	refresh = refresh,
}

-- Set interval, though this is not the ideal place to call interval
-- Clear timeout connection per minute
timer.setInterval(check_interval, function()
	for i,v in pairs(connection) do
		-- 60 seconds has passed
		if os.time() - v.last_time >= timeout_interval then
			utils.log(i .. " : timeout")
			connection[i] = nil
		end
	end
end)

return {
	route = route,
}
