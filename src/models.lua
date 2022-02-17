local ships_state = {
	-- 2 by 2 matrix with ENUM as value
}

-- TODO
-- Implement method of
--
-- generate_ships
-- attack

local game_state = {
	["id"]= "",
	["player"] = ships_state,
	["computer"] = ships_state,
}

return {
	user_state = ships_state,
	game_state = game_state,
}
