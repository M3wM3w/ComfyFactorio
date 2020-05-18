--vanilla with wave_defense

local WD = require "modules.wave_defense.main"
local Map = require "modules.map_info"

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['iron-plate'] = 16, ['iron-gear-wheel'] = 8, ['raw-fish'] = 3,}

local function set_difficulty()
	local wave_defense_table = WD.get_table()
	--20 Players for maximum difficulty
	wave_defense_table.wave_interval = 7200 - #game.connected_players * 270
	if wave_defense_table.wave_interval < 1800 then wave_defense_table.wave_interval = 1800 end	
end

local function on_player_joined_game(event)	
	set_difficulty()
	
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end	
end

local function on_player_left_game(event)
	set_difficulty()
end

local function on_init()
	local T = Map.Pop_info()
	T.main_caption = "Wave Defense"
	T.sub_caption =  "~~~~~~"
	T.text = table.concat({
		"Survive\n",
		"as\n",
		"long\n",
		"as\n",
		"possible.\n",
	})
	T.main_caption_color = {r = 150, g = 0, b = 150}
	T.sub_caption_color = {r = 100, g = 150, b = 0}
	game.surfaces[1].request_to_generate_chunks({0,0}, 16)
	game.surfaces[1].force_generate_chunk_requests()
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_player_joined_game, on_player_joined_game)