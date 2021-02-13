local Public = {}

local table_size = table.size
local string_match = string.match
local string_lower = string.lower

local Table = require 'modules.scrap_towny_ffa.table'

local outlander_color = { 150, 150, 150 }
local outlander_chat_color = { 170, 170, 170 }
local rogue_color = { 150, 150, 150 }
local rogue_chat_color = { 170, 170, 170 }
local item_drop_radius = 1.65

local function can_force_accept_member(force)
	local ffatable = Table.get_table()
	local town_centers = ffatable.town_centers
	local size_of_town_centers = ffatable.size_of_town_centers
	local member_limit = 0

	if size_of_town_centers <= 1 then return true end

	for _, town in pairs(town_centers) do
		member_limit = member_limit + table_size(town.market.force.connected_players)
	end
	member_limit = math.floor(member_limit / size_of_town_centers) + 4

	if #force.connected_players >= member_limit then
		game.print(">> Town " .. force.name .. " has too many settlers! Current limit (" .. member_limit .. ")", { 255, 255, 0 })
		return
	end
	return true
end

local function is_towny(force)
	if force == game.forces["player"] or force == game.forces["rogue"] then return false end
	return true
end

function Public.has_key(player)
	local ffatable = Table.get_table()
	if player == nil then return false end
	return ffatable.key[player]
end

function Public.give_key(player)
	local ffatable = Table.get_table()
	if player == nil then return end
	ffatable.key[player] = true
end

function Public.remove_key(player)
	local ffatable = Table.get_table()
	if player == nil then return end
	ffatable.key[player] = false
end

function Public.set_player_color(player)
	local ffatable = Table.get_table()
	if player.force == game.forces["player"] then
		player.color = outlander_color
		player.chat_color = outlander_chat_color
		return
	end
	if player.force == game.forces["rogue"] then
		player.color = rogue_color
		player.chat_color = rogue_chat_color
		return
	end
	local town_center = ffatable.town_centers[player.force.name]
	if not town_center then return end
	player.color = town_center.color
	player.chat_color = town_center.color
end

local function set_town_color(event)
	local ffatable = Table.get_table()
	if event.command ~= "color" then return end
	local player = game.players[event.player_index]
	local force = player.force
	local town_center = ffatable.town_centers[force.name]
	if not town_center then
		Public.set_player_color(player)
		return
	end
	town_center.color = { player.color.r, player.color.g, player.color.b }
	rendering.set_color(town_center.town_caption, town_center.color)
	for _, p in pairs(force.players) do
		Public.set_player_color(p)
	end
end

function Public.set_all_player_colors()
	for _, p in pairs(game.connected_players) do
		Public.set_player_color(p)
	end
end

function Public.add_player_to_town(player, town_center)
	local ffatable = Table.get_table()
	local market = town_center.market
	local force = market.force
	local surface = market.surface
	player.force = market.force
	Public.remove_key(player)
	ffatable.spawn_point[player.name] = force.get_spawn_position(surface)
	game.permissions.get_group(force.name).add_player(player)
	player.tag = ""
	Public.set_player_color(player)
end

function Public.give_outlander_items(player)
	player.insert({ name = "stone-furnace", count = 1 })
	player.insert({ name = "raw-fish", count = 3 })
	player.insert({ name = "coal", count = 3 })
end

function Public.set_player_to_outlander(player)
	local ffatable = Table.get_table()
	player.force = game.forces.player
	if ffatable.spawn_point[player.name] then
		ffatable.spawn_point[player.name] = nil
	end
	if game.permissions.get_group("outlander") == nil then game.permissions.create_group("outlander") end
	game.permissions.get_group("outlander").add_player(player)
	player.tag = "[Outlander]"
	Public.set_player_color(player)
	Public.give_key(player)
end

local function set_player_to_rogue(player)
	local ffatable = Table.get_table()
	player.force = game.forces["rogue"]
	if ffatable.spawn_point[player.name] then
		ffatable.spawn_point[player.name] = nil
	end
	if game.permissions.get_group("rogue") == nil then game.permissions.create_group("rogue") end
	game.permissions.get_group("rogue").add_player(player)
	player.tag = "[Rogue]"
	Public.set_player_color(player)
end

local function ally_outlander(player, target)
	local ffatable = Table.get_table()
	local requesting_force = player.force
	local target_force = target.force

	-- don't handle request if target is not a town
	if not is_towny(requesting_force) and not is_towny(target_force) then return false end

	-- don't handle request to  another town if already in a town
	if is_towny(requesting_force) and is_towny(target_force) then return false end

	-- handle the request
	if not is_towny(requesting_force) and is_towny(target_force) then
		ffatable.requests[player.index] = target_force.name

		local target_player = false
		if target.type == "character" then
			target_player = target.player
		else
			target_player = game.players[target_force.name]
		end

		if target_player then
			if ffatable.requests[target_player.index] then
				if ffatable.requests[target_player.index] == player.name then
					if ffatable.town_centers[target_force.name] then
						if not can_force_accept_member(target_force) then return true end
						game.print(">> " .. player.name .. " has settled in " .. target_force.name .. "'s Town!", { 255, 255, 0 })
						Public.add_player_to_town(player, ffatable.town_centers[target_force.name])
						return true
					end
				end
			end
		end

		game.print(">> " .. player.name .. " wants to settle in " .. target_force.name .. " Town!", { 255, 255, 0 })
		return true
	end

	-- handle the approval
	if is_towny(requesting_force) and not is_towny(target_force) then
		if target.type ~= "character" then return true end
		local target_player = target.player
		if not target_player then return true end
		ffatable.requests[player.index] = target_player.name

		if ffatable.requests[target_player.index] then
			if ffatable.requests[target_player.index] == player.force.name then
				if not can_force_accept_member(player.force) then return true end
				if player.force.name == player.name then
					game.print(">> " .. player.name .. " has accepted " .. target_player.name .. " into their Town!", { 255, 255, 0 })
				else
					game.print(">> " .. player.name .. " has accepted " .. target_player.name .. " into" .. player.force.name .. "'s Town!", { 255, 255, 0 })
				end
				Public.add_player_to_town(target_player, ffatable.town_centers[player.force.name])
				return true
			end
		end

		if player.force.name == player.name then
			game.print(">> " .. player.name .. " is inviting " .. target_player.name .. " into their Town!", { 255, 255, 0 })
		else
			game.print(">> " .. player.name .. " is inviting " .. target_player.name .. " into " .. player.force.name .. "'s Town!", { 255, 255, 0 })
		end
		return true
	end
end

local function ally_neighbour_towns(player, target)
	local requesting_force = player.force
	local target_force = target.force

	if target_force.get_friend(requesting_force) and requesting_force.get_friend(target_force) then return end

	requesting_force.set_friend(target_force, true)
	game.print(">> Town " .. requesting_force.name .. " has set " .. target_force.name .. " as their friend!", { 255, 255, 0 })

	if target_force.get_friend(requesting_force) then
		game.print(">> The towns " .. requesting_force.name .. " and " .. target_force.name .. " have formed an alliance!", { 255, 255, 0 })
	end
end

local function ally_town(player, item)
	local position = item.position
	local surface = player.surface
	local area = { { position.x - item_drop_radius, position.y - item_drop_radius }, { position.x + item_drop_radius, position.y + item_drop_radius } }
	local requesting_force = player.force
	local target = false

	for _, e in pairs(surface.find_entities_filtered({ type = { "character", "market" }, area = area })) do
		if e.force.name ~= requesting_force.name then
			target = e
			break
		end
	end

	if not target then return end
	if target.force == game.forces["enemy"] or target.force == game.forces["neutral"] then return end

	if ally_outlander(player, target) then return end
	ally_neighbour_towns(player, target)
end

local function declare_war(player, item)
	local ffatable = Table.get_table()
	local position = item.position
	local surface = player.surface
	local area = { { position.x - item_drop_radius, position.y - item_drop_radius }, { position.x + item_drop_radius, position.y + item_drop_radius } }

	local requesting_force = player.force
	local target = surface.find_entities_filtered({ type = { "character", "market" }, area = area })[1]

	if not target then return end
	local target_force = target.force
	if not is_towny(target_force) then return end

	if requesting_force.name == target_force.name then
		if player.name ~= target.force.name then
			Public.set_player_to_outlander(player)
			game.print(">> " .. player.name .. " has abandoned " .. target_force.name .. "'s Town!", { 255, 255, 0 })
			ffatable.requests[player.index] = nil
		end
		if player.name == target.force.name then
			if target.type ~= "character" then return end
			local target_player = target.player
			if not target_player then return end
			if target_player.index == player.index then return end
			Public.set_player_to_outlander(target_player)
			game.print(">> " .. player.name .. " has banished " .. target_player.name .. " from their Town!", { 255, 255, 0 })
			ffatable.requests[player.index] = nil
		end
		return
	end

	if not is_towny(requesting_force) then return end

	requesting_force.set_friend(target_force, false)
	target_force.set_friend(requesting_force, false)

	game.print(">> " .. player.name .. " has dropped the coal! Town " .. target_force.name .. " and " .. requesting_force.name .. " are now at war!", { 255, 255, 0 })
end

local function delete_chart_tag_for_all_forces(market)
	local forces = game.forces
	local position = market.position
	local surface = market.surface
	for _, force in pairs(forces) do
		local tags = force.find_chart_tags(surface, { { position.x - 0.1, position.y - 0.1 }, { position.x + 0.1, position.y + 0.1 } })
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
	local tags = force.find_chart_tags(market.surface, { { position.x - 0.1, position.y - 0.1 }, { position.x + 0.1, position.y + 0.1 } })
	if tags[1] then return end
	force.add_chart_tag(market.surface, { icon = { type = 'item', name = 'stone-furnace' }, position = position, text = market.force.name .. "'s Town" })
end

function Public.update_town_chart_tags()
	local ffatable = Table.get_table()
	local town_centers = ffatable.town_centers
	local forces = game.forces
	for _, town_center in pairs(town_centers) do
		local market = town_center.market
		for _, force in pairs(forces) do
			if force.is_chunk_visible(market.surface, town_center.chunk_position) then
				Public.add_chart_tag(force, market)
			end
		end
	end
	if game.forces["player"] ~= nil then game.forces["player"].clear_chart(game.surfaces["nauvis"]) end
	if game.forces["rogue"] ~= nil then game.forces["rogue"].clear_chart(game.surfaces["nauvis"]) end
end

local function reset_permissions(permission_group)
	for action_name, _ in pairs(defines.input_action) do
		permission_group.set_allows_action(defines.input_action[action_name], true)
	end
end

local function disable_blueprints(permission_group)
	local defs = {
		defines.input_action.alt_select_blueprint_entities,
		defines.input_action.cancel_new_blueprint,
		defines.input_action.change_blueprint_record_label,
		defines.input_action.clear_selected_blueprint,
		defines.input_action.create_blueprint_like,
		defines.input_action.cycle_blueprint_backwards,
		defines.input_action.cycle_blueprint_forwards,
		defines.input_action.delete_blueprint_library,
		defines.input_action.delete_blueprint_record,
		defines.input_action.drop_blueprint_record,
		defines.input_action.drop_to_blueprint_book,
		defines.input_action.export_blueprint,
		defines.input_action.grab_blueprint_record,
		defines.input_action.import_blueprint,
		defines.input_action.import_blueprint_string,
		defines.input_action.open_blueprint_library_gui,
		defines.input_action.open_blueprint_record,
		defines.input_action.select_blueprint_entities,
		defines.input_action.setup_blueprint,
		defines.input_action.setup_single_blueprint_record,
		defines.input_action.upgrade_open_blueprint,
		defines.input_action.deconstruct,
		defines.input_action.clear_selected_deconstruction_item,
		defines.input_action.cancel_deconstruct,
		defines.input_action.toggle_deconstruction_item_entity_filter_mode,
		defines.input_action.toggle_deconstruction_item_tile_filter_mode,
		defines.input_action.set_deconstruction_item_tile_selection_mode,
		defines.input_action.set_deconstruction_item_trees_and_rocks_only,
	}
	for _, d in pairs(defs) do permission_group.set_allows_action(d, false) end
end

local function enable_artillery(force, permission_group)
	permission_group.set_allows_action(defines.input_action.use_artillery_remote, true)
	force.technologies["artillery"].enabled = true
	force.technologies["artillery-shell-range-1"].enabled = false
	force.technologies["artillery-shell-speed-1"].enabled = false
	force.recipes["artillery-turret"].enabled = true
	force.recipes["artillery-wagon"].enabled = true
	force.recipes["artillery-targeting-remote"].enabled = true
	force.recipes["artillery-shell"].enabled = true
end

local function disable_artillery(force, permission_group)
	permission_group.set_allows_action(defines.input_action.use_artillery_remote, false)
	force.technologies["artillery"].enabled = false
	force.technologies["artillery-shell-range-1"].enabled = false
	force.technologies["artillery-shell-speed-1"].enabled = false
	force.recipes["artillery-turret"].enabled = false
	force.recipes["artillery-wagon"].enabled = false
	force.recipes["artillery-targeting-remote"].enabled = false
	force.recipes["artillery-shell"].enabled = false
end

local function disable_spidertron(force, permission_group)
	permission_group.set_allows_action(defines.input_action.send_spidertron, false)
	force.technologies["spidertron"].enabled = false
	force.recipes["spidertron"].enabled = false
	force.recipes["spidertron-remote"].enabled = false
end

local function disable_rockets(force)
	force.technologies["rocketry"].enabled = false
	force.technologies["explosive-rocketry"].enabled = false
	force.recipes["rocket-launcher"].enabled = false
	force.recipes["rocket"].enabled = false
	force.recipes["explosive-rocket"].enabled = false
end

local function disable_nukes(force)
	force.technologies["atomic-bomb"].enabled = false
	force.recipes["atomic-bomb"].enabled = false
end

local function disable_cluster_grenades(force)
	force.recipes["cluster-grenade"].enabled = false
end

local function enable_radar(force)
	force.recipes["radar"].enabled = true
	force.share_chart = true
	force.clear_chart("nauvis")
end

local function disable_radar(force)
	force.recipes["radar"].enabled = false
	force.share_chart = false
	force.clear_chart("nauvis")
end

local function disable_achievements(permission_group)
	permission_group.set_allows_action(defines.input_action.open_achievements_gui, false)
end

local function disable_tips_and_tricks(permission_group)
	permission_group.set_allows_action(defines.input_action.open_tips_and_tricks_gui, false)
end

-- setup a team force
function Public.add_new_force(force_name)
	-- disable permissions
	local force = game.create_force(force_name)
	local permission_group = game.permissions.create_group(force_name)
	reset_permissions(permission_group)
	disable_blueprints(permission_group)
	enable_artillery(force, permission_group)
	disable_spidertron(force, permission_group)
	disable_rockets(force)
	disable_nukes(force)
	disable_cluster_grenades(force)
	enable_radar(force)
	disable_achievements(permission_group)
	disable_tips_and_tricks(permission_group)
	-- friendly fire
	force.friendly_fire = true
	-- disable technologies
	force.research_queue_enabled = true
	-- balance initial combat
	force.set_ammo_damage_modifier("landmine", -0.75)
	force.set_ammo_damage_modifier("grenade", -0.5)
end

local function kill_force(force_name)
	local ffatable = Table.get_table()
	local force = game.forces[force_name]
	local market = ffatable.town_centers[force_name].market
	local surface = market.surface
	surface.create_entity({ name = "big-artillery-explosion", position = market.position })
	for _, player in pairs(force.players) do
		if player.character then
			player.character.die()
		else
			ffatable.requests[player.index] = "kill-character"
		end
		player.force = game.forces.player
		Public.set_player_color(player)
	end
	for _, e in pairs(surface.find_entities_filtered({ force = force_name })) do
		if e.valid then
			if e.type == "wall" or e.type == "gate" then
				e.die()
			end
		end
	end
	game.merge_forces(force_name, "neutral")
	ffatable.town_centers[force_name] = nil
	ffatable.size_of_town_centers = ffatable.size_of_town_centers - 1
	delete_chart_tag_for_all_forces(market)
	game.print(">> " .. force_name .. "'s town has fallen! [gps=" .. math.floor(market.position.x) .. "," .. math.floor(market.position.y) .. "]", { 255, 255, 0 })
end

local player_force_disabled_recipes = { "lab", "automation-science-pack", "stone-brick", "radar" }
local player_force_enabled_recipes = { "submachine-gun", "assembling-machine-1", "small-lamp", "shotgun", "shotgun-shell", "underground-belt", "splitter", "steel-plate", "car", "cargo-wagon", "constant-combinator", "engine-unit", "green-wire", "locomotive", "rail", "train-stop", "arithmetic-combinator", "decider-combinator" }

-- setup the player force (this is the default for Outlanders)
local function setup_player_force()
	local force = game.forces.player
	local permission_group = game.permissions.create_group("outlander")
	-- disable permissions
	reset_permissions(permission_group)
	disable_blueprints(permission_group)
	disable_artillery(force, permission_group)
	disable_spidertron(force, permission_group)
	disable_rockets(force)
	disable_nukes(force)
	disable_cluster_grenades(force)
	disable_radar(force)
	disable_achievements(permission_group)
	disable_tips_and_tricks(permission_group)
	-- disable research
	force.disable_research()
	force.research_queue_enabled = false
	-- friendly fire
	force.friendly_fire = true
	-- disable recipes
	local recipes = force.recipes
	for _, recipe_name in pairs(player_force_disabled_recipes) do
		recipes[recipe_name].enabled = false
	end
	for _, recipe_name in pairs(player_force_enabled_recipes) do
		recipes[recipe_name].enabled = true
	end
	force.set_ammo_damage_modifier("landmine", -0.75)
	force.set_ammo_damage_modifier("grenade", -0.5)
end

local function setup_rogue_force()
	local force_name = "rogue"
	local force = game.create_force(force_name)
	local permission_group = game.permissions.create_group(force_name)
	-- disable permissions
	reset_permissions(permission_group)
	disable_blueprints(permission_group)
	disable_artillery(force, permission_group)
	disable_spidertron(force, permission_group)
	disable_rockets(force)
	disable_nukes(force)
	disable_cluster_grenades(force)
	disable_radar(force)
	disable_achievements(permission_group)
	disable_tips_and_tricks(permission_group)
	-- disable research
	force.disable_research()
	force.research_queue_enabled = false
	-- friendly fire
	force.friendly_fire = true
	-- disable recipes
	local recipes = force.recipes
	for _, recipe_name in pairs(player_force_disabled_recipes) do
		recipes[recipe_name].enabled = false
	end
	for _, recipe_name in pairs(player_force_enabled_recipes) do
		recipes[recipe_name].enabled = true
	end
	force.set_ammo_damage_modifier("landmine", -0.75)
	force.set_ammo_damage_modifier("grenade", -0.5)
end

local function setup_enemy_force()
	local e_force = game.forces["enemy"]
	e_force.evolution_factor = 1    -- this should never change since we are changing biter types on spawn
	e_force.set_friend(game.forces.player, true)        -- outlander force (player) should not be attacked by turrets
	e_force.set_cease_fire(game.forces.player, true)    -- outlander force (player) should not be attacked by units
	e_force.set_friend(game.forces["rogue"], false)        -- rogue force (rogue) should be attacked by turrets
	e_force.set_cease_fire(game.forces["rogue"], false)    -- rogue force (rogue) should  be attacked by units
	-- note, these don't prevent an outlander or rogue from attacking a unit or spawner, we need to handle separately
end

local function on_player_dropped_item(event)
	local player = game.players[event.player_index]
	local entity = event.entity
	if entity.stack.name == "raw-fish" then
		ally_town(player, entity)
		return
	end
	if entity.stack.name == "coal" then
		declare_war(player, entity)
		return
	end
end

---- when a player dies, reveal their base to everyone
--local function on_player_died(event)
--	local player = game.players[event.player_index]
--	if not player.character then return end
--	if not player.character.valid then return end
--	reveal_entity_to_all(player.character)
--end

local function on_entity_damaged(event)
	local entity = event.entity
	if not entity.valid then return end
	local cause = event.cause
	local force = event.force

	-- special case to handle enemies attacked by outlanders
	if entity.force == game.forces["enemy"] then
		if cause ~= nil then
			if cause.type == "character" and force == game.forces["player"] then
				local player = cause.player
				if force == game.forces["player"] then
					-- set the force of the player to rogue until they die or create a town
					set_player_to_rogue(player)
				end
			end
			-- cars and tanks
			if cause.type == "car" or cause.type == "tank" then
				local driver = cause.get_driver()
				if driver ~= nil and driver.force == game.forces["player"] then
					-- set the force of the player to rogue until they die or create a town
					set_player_to_rogue(driver)
				end
				local passenger = cause.get_passenger()
				if passenger ~= nil and passenger.force == game.forces["player"] then
					-- set the force of the player to rogue until they die or create a town
					set_player_to_rogue(passenger)
				end
			end
			-- trains
			if cause.type == "locomotive" or cause.type == "cargo-wagon" or cause.type == "fluid-wagon" or cause.type == "artillery-wagon" then
				local train = cause.train
				for _, passenger in pairs(train.passengers) do
					if passenger ~= nil and passenger.force == game.forces["player"] then
						set_player_to_rogue(passenger)
					end
				end
			end
			-- combat robots
			if cause.type == "combat-robot" and force == game.forces["player"] then
				local owner = cause.last_user
				-- set the force of the player to rogue until they die or create a town
				set_player_to_rogue(owner)
			end
		end
	end
end

local function on_entity_died(event)
	local entity = event.entity
	if entity.name == "market" then
		kill_force(entity.force.name)
	end
end

local function on_post_entity_died(event)
	local prototype = event.prototype.type
	if prototype ~= "character" then return end
	local entities = game.surfaces[event.surface_index].find_entities_filtered({ position = event.position, radius = 1 })
	for _, e in pairs(entities) do
		if e.type == "character-corpse" then
			Public.remove_key(e)
		end
	end
end

local function on_console_command(event)
	set_town_color(event)
end

local function on_console_chat(event)
	local player = game.players[event.player_index]
	if string_match(string_lower(event.message), "%[armor%=") then
		player.clear_console()
		game.print(">> " .. player.name .. " is trying to gain an unfair advantage!")
	end
end

function Public.initialize()
	setup_player_force()
	setup_rogue_force()
	setup_enemy_force()
end

local on_init = function ()
	local ffatable = Table.get_table()
	ffatable.key = {}
	ffatable.spawn_point = {}
	ffatable.requests = {}

end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_post_entity_died, on_post_entity_died)
Event.add(defines.events.on_console_command, on_console_command)
Event.add(defines.events.on_console_chat, on_console_chat)

return Public