local Public = {}

local Table = require 'modules.scrap_towny_ffa.table'

local info = [[You are an "outlander" stuck on this god-forsaken planet with a bunch of other desolate fools. You can choose to join
an existing town if accepted, or go at it alone, building your own outpost or living as an "outlander".

The local inhabitants are indifferent to you at first, so long as you don't build or pollute, but become increasingly aggressive
by foreign technology.  In fact, they get quite aggressive at the scent of it. If you were to hurt any of the natives you will be
brandished a rogue until your untimely death or until you find better digs.

To create a new town or outpost simply place a furnace down in a suitable spot that is not near any other towns or obstructed.
The world seems to be limited in size with uninhabitable zones on four sides.  News towns can only be built within these
borders and you must leave room for the town's size (radius of 27) when placing a new town.
TIP: It's best to find a spot far from existing towns and pollution, as enemies will become aggressive once you form a town.

Once a town is formed, members may invite other players and teams using a raw fish. To invite another player, drop a fish
on that player (with the Z key). To accept an invite, offer a fish in return to the member. To leave a town, simply drop coal
on the market. As a member of a town, your respawn point will change to that of the town.

To form any alliance with another town, drop a fish on a member or their market. If they agree they can reciprocate with a
fish offering.

The town market is the heart of your town.  If it is destroyed, your town is destroyed and you will lose all research. So
protect it well, repair it whenever possible, and if you can afford, increase its health by purchasing upgrades. If your
town falls, members will be disbanded, and all buildings will become neutral and lootable.

When building your town, note that you may only build nearby existing structures such as your town market and walls and
any other structure you have placed. Beware that biters and spitters become more aggressive towards towns that are
advanced in research. Their evolution will scale around technology progress in any nearby towns and pollution levels.

This is a FFA ("Free-For-All") world.  Short of bullying and derogatory remarks, anything goes. Griefing is encouraged,
so best to setup proper defenses for your town or outpost to fend off enemies when you are there and away.

Have fun and be comfy ^.^]]

function Public.toggle_button(player)
	if player.gui.top["towny_map_intro_button"] then return end
	local b = player.gui.top.add({ type = "sprite-button", caption = "Towny", name = "towny_map_intro_button", tooltip = "Show Info" })
	b.style.font_color = { r = 0.5, g = 0.3, b = 0.99 }
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.minimal_width = 80
	b.style.top_padding = 1
	b.style.left_padding = 1
	b.style.right_padding = 1
	b.style.bottom_padding = 1
end

function Public.show(player)
  local ffatable = Table.get_table()
	if player.gui.center["towny_map_intro_frame"] then player.gui.center["towny_map_intro_frame"].destroy() end
	local frame = player.gui.center.add { type = "frame", name = "towny_map_intro_frame" }
	frame = frame.add { type = "frame", direction = "vertical" }

	local t = frame.add { type = "table", column_count = 2 }

	local label = t.add { type = "label", caption = "Active Factions:" }
	label.style.font = "heading-1"
	label.style.font_color = { r = 0.85, g = 0.85, b = 0.85 }
	label.style.right_padding = 8

	t = t.add { type = "table", column_count = 4 }

	local label2 = t.add { type = "label", caption = "Outlander" .. "(" .. #game.forces.player.connected_players .. ")" }
	label2.style.font_color = { 170, 170, 170 }
	label2.style.font = "heading-3"
	label2.style.minimal_width = 80

	for _, town_center in pairs(ffatable.town_centers) do
		local force = town_center.market.force
		local label3 = t.add { type = "label", caption = force.name .. "(" .. #force.connected_players .. ")" }
		label3.style.font = "heading-3"
		label3.style.minimal_width = 80
		label3.style.font_color = town_center.color
	end

	frame.add { type = "line" }

	local l = frame.add { type = "label", caption = "Instructions:" }
	l.style.font = "heading-1"
	l.style.font_color = { r = 0.85, g = 0.85, b = 0.85 }

	local l2 = frame.add { type = "label", caption = info }
	l2.style.single_line = false
	l2.style.font = "heading-2"
	l2.style.font_color = { r = 0.8, g = 0.7, b = 0.99 }
end

function Public.close(event)
	if not event.element then return end
	if not event.element.valid then return end
	local parent = event.element.parent
	for _ = 1, 4, 1 do
		if not parent then return end
		if parent.name == "towny_map_intro_frame" then
			parent.destroy()
			return
		end
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

local function on_gui_click(event)
	Public.close(event)
	Public.toggle(event)
end

local Event = require 'utils.event'
Event.add(defines.events.on_gui_click, on_gui_click)

return Public
