local Public = {}

local info = [[To ally or settle with another town, drop a fish on their market or character. (Default Hotkey Z)
They will have to do the same to you to complete the request.
Coal yields the opposite result, as it will make foes or banish settlers.
	
To found a town, place down a stone furnace at a valid location.
This will only trigger, if your character is in possession a "small-plane" token item!
Town buildings can only be placed close to it's other buildings.
Beware, biters are more aggressive towards towns that are advanced in research.
Their evolution will scale around the average technology progress all towns.

Only one town center can be owned at a time.
Only the owner can banish members.
Members can invite other players and teams.
Members can leave their town with a piece of coal.
The Market can only repaired manually.
Outlanders can not build close to it.

All towns are opponents to each other, if no alliance is formed with a raw fish.
If a center falls, the whole team will fall with it and all buildings will turn neutral and lootable.
The town center also acts as the team's respawn point. 

There are very little rules. Have fun and be comfy ^.^]]

function Public.toggle_button(player)
	if player.gui.top["towny_map_intro_button"] then return end
	local b = player.gui.top.add({type = "sprite-button", caption = "Towny", name = "towny_map_intro_button", tooltip = "Show Info"})
	b.style.font_color = {r=0.5, g=0.3, b=0.99}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.minimal_width = 60
	b.style.top_padding = 1
	b.style.left_padding = 1
	b.style.right_padding = 1
	b.style.bottom_padding = 1
end

function Public.show(player)
	if player.gui.center["towny_map_intro_frame"] then player.gui.center["towny_map_intro_frame"].destroy() end
	local frame = player.gui.center.add {type = "frame", name = "towny_map_intro_frame"}
	local frame = frame.add {type = "frame", direction = "vertical"}
	
	local t = frame.add {type = "table", column_count = 2}
	
	local label = t.add {type = "label", caption = "Active Factions:"}
	label.style.font = "heading-1"
	label.style.font_color = {r=0.85, g=0.85, b=0.85}
	label.style.right_padding = 8
	
	local t = t.add {type = "table", column_count = 4}
		
	local label = t.add {type = "label", caption = "Outlander" .. "(" .. #game.forces.player.connected_players .. ")"}
	label.style.font_color = {170, 170, 170}
	label.style.font = "heading-3"
	label.style.minimal_width = 80
	
	for _, town_center in pairs(global.towny.town_centers) do
		local force = town_center.market.force
		local label = t.add {type = "label", caption = force.name .. "(" .. #force.connected_players .. ")"}
		label.style.font = "heading-3"
		label.style.minimal_width = 80
		label.style.font_color = town_center.color
	end	
	
	frame.add {type = "line"}
	
	local l = frame.add {type = "label", caption = "Instructions:"}
	l.style.font = "heading-1"
	l.style.font_color = {r=0.85, g=0.85, b=0.85}
	
	local l = frame.add {type = "label", caption = info}
	l.style.single_line = false
	l.style.font = "heading-2"
	l.style.font_color = {r=0.8, g=0.7, b=0.99}	
end

function Public.close(event)
	if not event.element then return end
	if not event.element.valid then return end
	local parent = event.element.parent
	for _ = 1, 4, 1 do
		if not parent then return end
		if parent.name == "towny_map_intro_frame" then parent.destroy() return end	
		parent = parent.parent		
	end
end

function Public.toggle(event)
	if not event.element then return end
	if not event.element.valid then return end		
	if event.element.name == "towny_map_intro_button" then
		local player = game.players[event.player_index]
		if player.gui.center["towny_map_intro_frame"] then
			player.gui.center["towny_map_intro_frame"].destroy()
		else
			Public.show(player)
		end		
	end	
end


return Public