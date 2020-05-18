local event = require 'utils.event'

local function teleport_player(surface, source_player, position)		
	local materializing_characters = source_player.surface.find_entities_filtered({
		name = "character",
		area = {{position.x - 1, position.y - 1},{position.x + 1, position.y + 1}},
		force = "neutral"
	})	
	for _, e in pairs(materializing_characters) do
		if e.valid then e.destroy() end
	end
		
	if not source_player.character then return end
	surface.create_entity({name = "character-corpse", position = source_player.position, force = source_player.force.name})	
	source_player.teleport(position, surface)
	if source_player.character.health < 25 then source_player.character.health = 250 end
	global.team_teleport_delay[source_player.name] = game.tick + 18000
end

local function fix_player_position(source_player, original_position)
	if not source_player.character then return end
	if source_player.position.x == original_position.x and source_player.position.y == original_position.y then return end
	source_player.teleport(original_position, source_player.surface)
end

local function teleport_effects(surface, position)	
	local x = position.x + (4 - (math.random(1,80) * 0.1))
	surface.create_entity({
		name = "railgun-beam",
		position = {x = position.x, y = position.y},
		target = {x = x, y = position.y - math.random(6,13)}
	})
	for y = 0, 1, 1 do		
		surface.create_entity({
			name = "water-splash",
			position = {x = position.x, y = position.y + y},		
		})		
	end
	if math.random(1,40) == 1 then surface.create_entity({name = "explosion", position = {x = position.x + (3 - (math.random(1,60) * 0.1)), y = position.y + (3 - (math.random(1,60) * 0.1))}}) end
	if math.random(1,32) == 1 then surface.create_entity({name = "blood-explosion-huge", position = position}) end
	if math.random(1,16) == 1 then surface.create_entity({name = "blood-explosion-big", position = position}) end
	if math.random(1,8) == 1 then surface.create_entity({name = "blood-explosion-small", position = position}) end
end

local function sync_health_and_direction(player, materializing_character)
	if not player.character then return end
	if not player.character.valid then return end
	if not materializing_character then return end
	if not materializing_character.valid then return end
	materializing_character.health = materializing_character.health + 2
	materializing_character.direction = player.character.direction	
	if player.character.health < 3 then player.character.health = 1 return end
	if player.character.health == 250 then player.character.damage(2, "player") return end
	if math.random(1,64) == 1 then player.character.damage(2, "player") return end
	player.character.health = player.character.health - 2
end

local function teleport(source_player, target_player)
	source_player.teleport({x = math.floor(source_player.position.x), y = math.floor(source_player.position.y)})
	local target_position = target_player.surface.find_non_colliding_position("character", target_player.position, 128, 1)
	if not target_position then target_position = {x = target_player.position.x, y = target_player.position.y} end
	local materializing_character = target_player.surface.create_entity({name = "character", position = target_position, force = "neutral", direction = source_player.character.direction})
	materializing_character.destructible = false
	materializing_character.color = source_player.color
	materializing_character.damage(1, "player")
	materializing_character.health = 1		

	local a = 20
	for t = 0, 780, 1 do
		if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end	
		
		if t % a == 0 then
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = teleport_effects,
				args = {source_player.surface, {x = source_player.position.x, y = source_player.position.y}}
			}
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = teleport_effects,
				args = {source_player.surface, target_position}
			}
			
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = sync_health_and_direction,
				args = {source_player, materializing_character}
			}		
			
			a = a - 0.5
			if a < 5 then a = 5 end
		end
		
		if t % 2 == 0 then
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = fix_player_position,
				args = {source_player, {x = source_player.position.x, y = source_player.position.y}}
			}
		end
		
		if t == 780 then			
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = teleport_player,
				args = {target_player.surface, source_player, target_position}
			}
		end
		
	end
end

local function get_sorted_player_table(requesting_player)
	local t = {}
	for _, player in pairs(game.connected_players) do
		if player.name ~= requesting_player.name and player.force == requesting_player.force then
			local distance = math.ceil(math.sqrt((player.position.x - requesting_player.position.x)^2 + (player.position.y - requesting_player.position.y)^2) * 10) * 0.1
			table.insert(t, {name = player.name, distance = distance})
		end
	end	
	for i = 1, #t, 1 do
		for i2 = 1, #t, 1 do
			if t[i].distance > t[i2].distance then
				local k = t[i]
				t[i] = t[i2]
				t[i2] = k
			end
		end
	end	
	return t
end

local function create_gui_toggle_button(player)
	if player.gui.top["team_teleport_button"] then return end
	local b = player.gui.top.add({type = "sprite-button", name = "team_teleport_button", caption = "TP", tooltip = "Teleport to a Team Member"})
	b.style.font_color = {r = 0.55, g = 0.22, b = 0.77}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
end

local function create_teleport_gui(player)
	if player.gui.center["team_teleport"] then player.gui.center["team_teleport"].destroy() end
	local frame = player.gui.center.add({type = "frame", name = "team_teleport", caption = "<< Teleport to player >>"})
	frame.style.font_color = {r = 0.55, g = 0.22, b = 0.77}
	frame.style.font = "heading-1"
	
	local scroll_pane = frame.add({ type = "scroll-pane", name = "scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"})
	scroll_pane.style.maximal_height = 320
	scroll_pane.style.minimal_height = 320
	
	local t = scroll_pane.add({type = "table", column_count = 3, name = "team_teleport_table"})
	local player_table = get_sorted_player_table(player)
	
	for _, k in pairs(player_table) do
		local l = t.add({type = "button", name = k.name, caption = k.name})
		l.style.font_color = {r = game.players[k.name].color.r * 0.5, g = game.players[k.name].color.g * 0.5, b = game.players[k.name].color.b * 0.5}
		l.style.font = "heading-2"
		l.style.minimal_width = 120
		
		local l = t.add({type = "label", caption = "       Distance: "})
		l.style.font = "heading-2"
		
		local l = t.add({type = "label", caption = tostring(k.distance)})
		l.style.font_color = {r = 0.66, g = 0.66, b = 0.99}
		l.style.font = "heading-2"
		l.style.minimal_width = 100
	end	
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	
	local player = game.players[event.player_index]
	local name = event.element.name
	if name == "team_teleport_button" then
		if player.gui.center["team_teleport"] then
			player.gui.center["team_teleport"].destroy()
			return
		else
			create_teleport_gui(player) 
			return
		end
	end
	
	if not game.players[name] then return end
	if event.element.parent.name ~= "team_teleport_table" then return end
	if not player.character then return end
	if not game.players[name].character then return end
	if player.character.driving then return end		
	if game.tick - global.team_teleport_delay[player.name] < 0 then
		local recovery_time = math.ceil(math.abs(game.tick - global.team_teleport_delay[player.name]) / 3600)
		if recovery_time == 1 then
			player.print("You need one more minute to recover from the last teleport.")
		else
			player.print("You are not capable of handling another teleport yet, you need " .. tostring(recovery_time) .. " more minutes to recover.")
		end
		return
	end	
	global.team_teleport_delay[player.name] = game.tick + 900
	teleport(player, game.players[name])
	player.gui.center["team_teleport"].destroy()
end

local function refresh_gui()
	for _, p in pairs(game.connected_players) do
		if p.gui.center["team_teleport"] then
			p.gui.center["team_teleport"].destroy()
			create_teleport_gui(p)
		end
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.team_teleport_delay then global.team_teleport_delay = {} end		
	if not global.team_teleport_delay[player.name] then global.team_teleport_delay[player.name] = 0 end
	create_gui_toggle_button(player)
	refresh_gui()
end

local function on_player_left_game(event)
	refresh_gui()
end

event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)
