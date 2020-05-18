-- launch fish into space to win the game -- by mewmew

local event = require 'utils.event'

local function get_rank()
	for i = #global.catplanet_goals, 1, -1 do
		if global.fish_in_space >= global.catplanet_goals[i].goal then
			return i
		end
	end
end

local function fish_in_space_toggle_button(player)
	if player.gui.top["fish_in_space_toggle"] then return end
	local button = player.gui.top.add { name = "fish_in_space_toggle", type = "sprite-button", sprite = "item/raw-fish", tooltip = "Fish in Space"}
	button.style.font = "default-bold"
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.top_padding = 2
	button.style.left_padding = 4
	button.style.right_padding = 4
	button.style.bottom_padding = 2
end

function level_up_popup(player)
	local reward = global.catplanet_goals[get_rank()]
	if player.gui.center["level_up_popup"] then player.gui.center["level_up_popup"].destroy() end
	local frame = player.gui.center.add({type = "frame", name = "level_up_popup", direction = "vertical"})
	local label = frame.add({type = "label", caption = reward.msg})
	label.style.font = "default-listbox"
	label.style.font_color = reward.color
	local button = frame.add({type = "button", caption = reward.msg2, name = "level_up_popup_close"})
	button.style.minimal_width = string.len(reward.msg) * 7
	button.style.font = "default-listbox"
	button.style.font_color = {r=0.77, g=0.77, b=0.77}
end

function fish_in_space_gui(player)
	if global.fish_in_space == 0 then return end
	local i = get_rank()
	
	fish_in_space_toggle_button(player)
	
	if player.gui.left["fish_in_space"] then player.gui.left["fish_in_space"].destroy() end
		
	local frame = player.gui.left.add({type = "frame", name = "fish_in_space"})
	local label = frame.add({type = "label", caption = "Fish rescued: "})
	label.style.font_color = {r=0.11, g=0.8, b=0.44}	
			
	local progress = global.fish_in_space / global.catplanet_goals[i+1].goal
	if progress > 1 then progress = 1 end
	local progressbar = frame.add({ type = "progressbar", value = progress})
	progressbar.style.minimal_width = 100
	progressbar.style.maximal_width = 100
	progressbar.style.top_padding = 10
	
	local label = frame.add({type = "label", caption = global.fish_in_space .. "/" .. tostring(global.catplanet_goals[i+1].goal)})
	label.style.font_color = {r=0.33, g=0.66, b=0.9}	
	
	if global.catplanet_goals[i].rank then
		local label = frame.add({type = "label", caption = "  ~Rank~"})
		label.style.font_color = {r=0.75, g=0.75, b=0.75}	
		local label = frame.add({type = "label", caption = global.catplanet_goals[i].rank})
		label.style.font = "default-bold"
		label.style.font_color = global.catplanet_goals[i].color
	end
end

local function fireworks(entity)
	for x = entity.position.x - 32, entity.position.x + 32, 1 do
		for y = entity.position.y - 32, entity.position.y + 32, 1 do
			if math.random(1,150) == 1 then
				entity.surface.create_entity({name = "big-explosion", position = {x = x, y = y}})
			end
			if math.random(1,150) == 1 then
				entity.surface.create_entity({name = "uranium-cannon-shell-explosion", position = {x = x, y = y}})
			end
			if math.random(1,150) == 1 then
				entity.surface.create_entity({name = "blood-explosion-huge", position = {x = x, y = y}})
			end
			if math.random(1,150) == 1 then
				entity.surface.create_entity({name = "big-artillery-explosion", position = {x = x, y = y}})
			end
		end
	end
end

local function on_rocket_launched(event)	
	local rocket_inventory = event.rocket.get_inventory(defines.inventory.rocket)
	local launched_fish_count = rocket_inventory.get_item_count("raw-fish")
	if launched_fish_count == 0 then return end	
	global.fish_in_space = global.fish_in_space + launched_fish_count
	
	local i = get_rank()
	
	for _, player in pairs(game.connected_players) do
		fish_in_space_gui(player)
	end
	
	if not global.catplanet_goals[i].achieved then								
		for _, player in pairs(game.connected_players) do
			player.play_sound{path = "utility/game_won", volume_modifier = 0.9}
			level_up_popup(player)
		end						
		global.catplanet_goals[i].achieved = true
		fireworks(event.rocket_silo)
	end		
end

local function init()
	global.fish_in_space = 0
	global.catplanet_goals = {
		{goal = 0, rank = false, achieved = true},
		{goal = 100, rank = "Copper", color = {r = 201, g = 133, b = 6}, msg = "You have saved the first container of fish!", msg2 = "However, this is only the beginning.", achieved = false},
		{goal = 1000, rank = "Bronze", color = {r = 186, g = 115, b = 39}, msg = "Thankful for the fish, they sent back a toy mouse made of solid bronze!", msg2 = "They are demanding more.", achieved = false},
		{goal = 10000, rank = "Silver", color = {r = 186, g = 178, b = 171}, msg = "In gratitude for the fish, they left you a silver furball!", msg2 = "They are still longing for more.", achieved = false},
		{goal = 25000, rank = "Gold", color = {r = 255, g = 214, b = 33}, msg = "Pleased about the delivery, they sent back a golden audiotape with cat purrs.", msg2 = "They still demand more.", achieved = false},
		{goal = 50000, rank = "Platinum", color = {r = 224, g = 223, b = 215}, msg = "To express their infinite love, they sent back a yarnball made of shiny material.", msg2 = "Defying all logic, they still demand more fish.", achieved = false},	
		{goal = 100000, rank = "Diamond", color = {r = 237, g = 236, b = 232}, msg = "A box arrives with a mewing kitten, it a has a diamond collar.", msg2 = "More fish? Why? What..", achieved = false},	
		{goal = 250000, rank = "Anti-matter", color = {r = 100, g = 100, b = 245}, msg = "The obese cat colapses and forms a black hole!", msg2 = ":obese:", achieved = false},
		{goal = 500000, rank = "Black Hole", color = {r = 100, g = 100, b = 245}, msg = "A letter arrives, it reads: Go to bed hooman!", msg2 = "Not yet...", achieved = false},
		{goal = 1000000, rank = "Blue Screen", color = {r = 100, g = 100, b = 245}, msg = "Cat error #4721", msg2 = "....", achieved = false},
		{goal = 10000000, rank = "Blue Screen", color = {r = 100, g = 100, b = 245}, msg = "....", msg2 = "....", achieved = false}
	}
end

local function on_player_joined_game(event)
	if not global.fish_in_space then
		init()
	end
	local player = game.players[event.player_index]	
	fish_in_space_gui(player)
end

local function on_gui_click(event)	
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end			
	local player = game.players[event.element.player_index]
	local name = event.element.name
	
	if name == "fish_in_space_toggle" then
		local frame = player.gui.left["fish_in_space"]
		if frame then
			frame.destroy()
		else
			fish_in_space_gui(player)
		end
	end
	
	if name == "level_up_popup_close" then
		player.gui.center["level_up_popup"].destroy()		
	end
end

event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)	
event.add(defines.events.on_rocket_launched, on_rocket_launched)
