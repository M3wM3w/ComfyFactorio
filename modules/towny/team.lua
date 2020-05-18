local Public = {}

local outlander_color = {150, 150, 150}
local outlander_chat_color = {170, 170, 170}
local item_drop_radius = 1.65

local function can_force_accept_member(force)
	local town_centers = global.towny.town_centers
	local size_of_town_centers = global.towny.size_of_town_centers
	local member_limit = 0
	
	if size_of_town_centers <= 1 then return true end	
		
	for _, town in pairs(town_centers) do
		member_limit = member_limit + #town.market.force.connected_players
	end
	member_limit = math.floor(member_limit / size_of_town_centers) + 4
	
	if #force.connected_players >= member_limit then 
		game.print(">> Town " .. force.name .. " has too many settlers! Current limit (" .. member_limit .. ")" , {255, 255, 0})
		return 
	end
	return true
end

function Public.set_player_color(player)
	if player.force.index == 1 then
		player.color = outlander_color
		player.chat_color = outlander_chat_color
		return
	end
	local town_center = global.towny.town_centers[player.force.name]
	if not town_center then return end
	player.color = town_center.color
	player.chat_color= town_center.color
end

function Public.set_town_color(event)
	if event.command ~= "color" then return end
	local player = game.players[event.player_index]	
	if player.force.index == 1 then
		player.color = outlander_color
		player.chat_color = outlander_chat_color
		return
	end
	local town_center = global.towny.town_centers[player.name]
	if not town_center then
		Public.set_player_color(player)
		return
	end	
	
	town_center.color = {player.color.r, player.color.g, player.color.b}
	rendering.set_color(town_center.town_caption, town_center.color)
	for _, p in pairs(player.force.players) do
		Public.set_player_color(p)
	end
end

function Public.set_all_player_colors()
	for _, p in pairs(game.connected_players) do
		Public.set_player_color(p)
	end
end

function Public.add_player_to_town(player, town_center)
	player.force = town_center.market.force
	game.permissions.get_group("Default").add_player(player)
	player.tag = ""
	Public.set_player_color(player)	
end

function Public.give_outlander_items(player)
	player.insert({name = "stone-furnace", count = 1})
	player.insert({name = "small-plane", count = 1})
	player.insert({name = "raw-fish", count = 3})
	player.insert({name = "coal", count = 3})
end

function Public.set_player_to_outlander(player)
	player.force = game.forces.player
	game.permissions.get_group("outlander").add_player(player)
	player.tag = "[Outlander]"
	Public.set_player_color(player)
end

local function ally_outlander(player, target)
	local requesting_force = player.force
	local target_force = target.force

	if requesting_force.index ~= 1 and target_force.index ~= 1 then return end
	if requesting_force.index == 1 and target_force.index == 1 then return true end
	
	if requesting_force.index == 1 then
		global.towny.requests[player.index] = target_force.name
		
		local target_player = false
		if target.type == "character" then 
			target_player = target.player
		else
			target_player = game.players[target_force.name]
		end
	
		if target_player then
			if global.towny.requests[target_player.index] then 
				if global.towny.requests[target_player.index] == player.name then			
					if global.towny.town_centers[target_force.name] then
						if not can_force_accept_member(target_force) then return true end
						game.print(">> " .. player.name .. " has settled in " .. target_force.name .. "'s Town!", {255, 255, 0})
						Public.add_player_to_town(player, global.towny.town_centers[target_force.name])
						return true
					end
				end
			end
		end

		game.print(">> " .. player.name .. " wants to settle in " .. target_force.name .. " Town!", {255, 255, 0})
		return true
	end
	
	if target_force.index == 1 then		
		if target.type ~= "character" then return true end
		local target_player = target.player
		if not target_player then return true end
		global.towny.requests[player.index] = target_player.name				
		
		if global.towny.requests[target_player.index] then 
			if global.towny.requests[target_player.index] == player.force.name then
				if not can_force_accept_member(player.force) then return true end		
				if player.force.name == player.name then
					game.print(">> " .. player.name .. " has accepted " .. target_player.name .. " into their Town!", {255, 255, 0})
				else
					game.print(">> " .. player.name .. " has accepted " .. target_player.name .. " into" .. player.force.name .. "'s Town!", {255, 255, 0})
				end
				Public.add_player_to_town(target_player, global.towny.town_centers[player.force.name])
				return true
			end
		end	
		
		if player.force.name == player.name then
			game.print(">> " .. player.name .. " is inviting " .. target_player.name .. " into their Town!", {255, 255, 0})
		else
			game.print(">> " .. player.name .. " is inviting " .. target_player.name .. " into " .. player.force.name .. "'s Town!", {255, 255, 0})
		end
		return true
	end
end

local function ally_neighbour_towns(player, target)
	local requesting_force = player.force
	local target_force = target.force
	
	if target_force.get_friend(requesting_force) and requesting_force.get_friend(target_force) then return end
	
	requesting_force.set_friend(target_force, true)
	game.print(">> Town " .. requesting_force.name .. " has set " .. target_force.name .. " as their friend!", {255, 255, 0})
	
	if target_force.get_friend(requesting_force) then
		game.print(">> The towns " .. requesting_force.name .. " and " .. target_force.name .. " have formed an alliance!", {255, 255, 0})
	end
end

function Public.ally_town(player, item)
	local position = item.position
	local surface = player.surface
	local area = {{position.x - item_drop_radius, position.y - item_drop_radius}, {position.x + item_drop_radius, position.y + item_drop_radius}}
	local requesting_force = player.force
	local target = false
	
	for _, e in pairs(surface.find_entities_filtered({type = {"character", "market"}, area = area})) do
		if e.force.name ~= requesting_force.name then
			target = e
			break
		end
	end
	
	if not target then return end
	if target.force.index == 2 or target.force.index == 3 then return end

	if ally_outlander(player, target) then return end	
	ally_neighbour_towns(player, target)
end

function Public.declare_war(player, item)
	local position = item.position
	local surface = player.surface
	local area = {{position.x - item_drop_radius, position.y - item_drop_radius}, {position.x + item_drop_radius, position.y + item_drop_radius}}

	local requesting_force = player.force
	local target = surface.find_entities_filtered({type = {"character", "market"}, area = area})[1]

	if not target then return end
	local target_force = target.force
	if target_force.index <= 3 then return end
	
	if requesting_force.name == target_force.name then
		if player.name ~= target.force.name then
			Public.set_player_to_outlander(player)
			game.print(">> " .. player.name .. " has abandoned " .. target_force.name .. "'s Town!", {255, 255, 0})
			global.towny.requests[player.index] = nil
		end	
		if player.name == target.force.name then
			if target.type ~= "character" then return end
			local target_player = target.player
			if not target_player then return end
			if target_player.index == player.index then return end
			Public.set_player_to_outlander(target_player)
			game.print(">> " .. player.name .. " has banished " .. target_player.name .. " from their Town!", {255, 255, 0})
			global.towny.requests[player.index] = nil
		end
		return
	end
	
	if requesting_force.index == 1 then return end
	
	requesting_force.set_friend(target_force, false)
	target_force.set_friend(requesting_force, false)
	
	game.print(">> " .. player.name .. " has dropped the coal! Town " .. target_force.name .. " and " .. requesting_force.name .. " are now at war!", {255, 255, 0})
end

local radius = 96
function Public.reveal_entity_to_all(entity)
	local chart_area = {{entity.position.x - radius, entity.position.y - radius}, {entity.position.x + radius, entity.position.y + radius}}
	local surface = entity.surface
	for _, force in pairs(game.forces) do
		force.chart(surface, chart_area)
	end
end

local function delete_chart_tag_for_all_forces(market)
	local forces = game.forces
	local position = market.position	
	local surface = market.surface
	for _, force in pairs(forces) do		
		local tags = force.find_chart_tags(surface, {{position.x - 0.1, position.y - 0.1}, {position.x + 0.1, position.y + 0.1}})
		local tag = tags[1]
		if tag then
			if tag.icon.name == "stone-furnace" then
				tag.destroy()
			end
		end
	end
end

function Public.add_chart_tag(force, market)
	local position = market.position
	local tags = force.find_chart_tags(market.surface, {{position.x - 0.1, position.y - 0.1}, {position.x + 0.1, position.y + 0.1}})
	if tags[1] then return end
	force.add_chart_tag(market.surface, {icon = {type = 'item', name = 'stone-furnace'}, position = position, text = market.force.name .. "'s Town"})	
end

function Public.update_town_chart_tags()
	local town_centers = global.towny.town_centers
	local forces = game.forces
	for _, town_center in pairs(town_centers) do
		local market = town_center.market
		for _, force in pairs(forces) do
			if force.is_chunk_visible(market.surface, town_center.chunk_position) then
				Public.add_chart_tag(force, market)
			end
		end	
	end		
end

function Public.add_new_force(force_name)
	local force = game.create_force(force_name)
	force.research_queue_enabled = true	
	force.share_chart = true
	force.technologies["atomic-bomb"].enabled = false
	force.technologies["explosive-rocketry"].enabled = false
	force.technologies["rocketry"].enabled = false
	force.technologies["artillery-shell-range-1"].enabled = false					
	force.technologies["artillery-shell-speed-1"].enabled = false
	force.set_ammo_damage_modifier("landmine", -0.6)
	force.set_ammo_damage_modifier("artillery-shell", -0.75)
end

function Public.kill_force(force_name)
	local force = game.forces[force_name]
	local market = global.towny.town_centers[force_name].market	
	local surface = market.surface
	
	surface.create_entity({name = "big-artillery-explosion", position = market.position})
	
	for _, player in pairs(force.players) do
		if player.character then
			player.character.die()
		else
			global.towny.requests[player.index] = "kill-character"
		end
		player.force = game.forces.player
	end
	
	for _, e in pairs(surface.find_entities_filtered({force = force_name})) do
		if e.valid then
			if e.type == "wall" or e.type == "gate" then
				e.die()
			end
		end
	end

	game.merge_forces(force_name, "neutral")
	
	global.towny.town_centers[force_name] = nil
	global.towny.size_of_town_centers = global.towny.size_of_town_centers - 1
	
	delete_chart_tag_for_all_forces(market)
	Public.reveal_entity_to_all(market)
	
	game.print(">> " .. force_name .. "'s town has fallen! [gps=" .. math.floor(market.position.x) .. "," .. math.floor(market.position.y) .. "]", {255, 255, 0})	
end

local player_force_disabled_recipes = {"lab", "automation-science-pack", "stone-brick"}
local player_force_enabled_recipes = {"submachine-gun", "assembling-machine-1", "small-lamp", "shotgun", "shotgun-shell", "underground-belt", "splitter", "steel-plate", "car", "cargo-wagon", "constant-combinator", "engine-unit", "green-wire", "locomotive", "rail", "train-stop", "arithmetic-combinator", "decider-combinator"}

function Public.setup_player_force()
	local p = game.permissions.create_group("outlander")
	for action_name, _ in pairs(defines.input_action) do
		p.set_allows_action(defines.input_action[action_name], true)
	end
	local defs = {
		defines.input_action.start_research,
	}
	for _, d in pairs(defs) do p.set_allows_action(d, false) end
	
	local force = game.forces.player
	local recipes = force.recipes
	
	for k, recipe_name in pairs(player_force_disabled_recipes) do
		recipes[recipe_name].enabled = false
	end
	for k, recipe_name in pairs(player_force_enabled_recipes) do
		recipes[recipe_name].enabled = true
	end
	
	force.set_ammo_damage_modifier("landmine", -0.6)
	force.set_ammo_damage_modifier("artillery-shell", -0.75)
end

return Public