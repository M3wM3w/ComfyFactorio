local Public_gui = {}

local math_floor = math.floor
local math_ceil = math.ceil
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local Upgrades = require "maps.chronosphere.upgrade_list"

local function create_gui(player)
	local frame = player.gui.top.add({ type = "frame", name = "chronosphere"})
	frame.style.maximal_height = 38

	local label = frame.add({ type = "label", caption = " ", name = "label"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-bold"
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

	local label = frame.add({ type = "label", caption = " ", name = "jump_number"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-bold"
	label.style.right_padding = 4
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

  local label = frame.add({ type = "label", caption = " ", name = "charger"})
	label.style.font = "default-bold"
	label.style.left_padding = 4
	label.style.font_color = {r = 255, g = 200, b = 200} --255 200 200 --150 0 255

  local label = frame.add({ type = "label", caption = " ", name = "charger_value"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 255, g = 200, b = 200}

	local progressbar = frame.add({ type = "progressbar", name = "progressbar", value = 0})
	progressbar.style.minimal_width = 96
	progressbar.style.maximal_width = 96
	progressbar.style.top_padding = 10

  local label = frame.add({ type = "label", caption = " ", name = "timer"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 255, g = 200, b = 200}

  local label = frame.add({ type = "label", caption = " ", name = "timer_value", tooltip = " "})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 255, g = 200, b = 200}

  local label = frame.add({ type = "label", caption = " ", name = "timer2"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 0, g = 200, b = 0}

  local label = frame.add({ type = "label", caption = " ", name = "timer_value2"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 0, g = 200, b = 0}

  -- local line = frame.add({type = "line", direction = "vertical"})
	-- line.style.left_padding = 4
	-- line.style.right_padding = 8

	local button = frame.add({type = "button", caption = " ", name = "planet_button"})
	button.style.font = "default-bold"
	button.style.font_color = { r=0.99, g=0.99, b=0.99}
	button.style.minimal_width = 75

	local button = frame.add({type = "button", caption = " ", name = "upgrades_button"})
	button.style.font = "default-bold"
	button.style.font_color = { r=0.99, g=0.99, b=0.99}
	button.style.minimal_width = 75
end

local function update_upgrades_gui(player)
	if not player.gui.screen["gui_upgrades"] then return end
	local upgrades = Upgrades.upgrades()
	local frame = player.gui.screen["gui_upgrades"]

	for i = 1, #upgrades, 1 do
		local t = frame["upgrades_table" .. i]
		t["upgrade" .. i].number = global.objective.upgrades[i]
		t["upgrade" .. i].tooltip = upgrades[i].tooltip
		t["upgrade_label" .. i].tooltip = upgrades[i].tooltip

		if global.objective.upgrades[i] == upgrades[i].max_level then
			t["maxed" .. i].visible = true
			t["jump_req" .. i].visible = false
			for index,_ in pairs(upgrades[i].cost) do
				t[index .. "-" .. i].visible = false
			end
		else
			t["maxed" .. i].visible = false
			t["jump_req" .. i].visible = true
			t["jump_req" .. i].number = upgrades[i].jump_limit
			for index,item in pairs(upgrades[i].cost) do
				t[index .. "-" .. i].visible = true
				t[index .. "-" .. i].number = item.count
			end
		end
	end
end

local function update_planet_gui(player)
	if not player.gui.screen["gui_planet"] then return end
	local planet = global.objective.planet[1]
	local evolution = game.forces["enemy"].evolution_factor
	local evo_color = {
    r = math_floor(255 * 1 * math_max(0, math_min(1, 1.2 - evolution * 2))),
    g = math_floor(255 * 1 * math_max(math_abs(0.5 - evolution * 1.5), 1 - evolution * 4)),
    b = math_floor(255 * 4 * math_max(0, 0.25 - math_abs(0.5 - evolution)))
  }
	local frame = player.gui.screen["gui_planet"]

	frame["planet_name"].caption = {"chronosphere.gui_planet_0", planet.name.name}
	frame["planet_ores"]["iron-ore"].number = planet.name.iron
	frame["planet_ores"]["copper-ore"].number = planet.name.copper
	frame["planet_ores"]["coal"].number = planet.name.coal
	frame["planet_ores"]["stone"].number = planet.name.stone
	frame["planet_ores"]["uranium-ore"].number = planet.name.uranium
	frame["planet_ores"]["oil"].number = planet.name.oil
	frame["richness"].caption = {"chronosphere.gui_planet_2", planet.ore_richness.name}
	frame["planet_biters"].caption = {"chronosphere.gui_planet_3", math_floor(evolution * 1000) / 10}
	frame["planet_biters"].style.font_color = evo_color

	frame["planet_biters3"].caption = {"chronosphere.gui_planet_4_1", global.objective.passivejumps * 2.5, global.objective.passivejumps * 10}
	frame["planet_time"].caption = {"chronosphere.gui_planet_5", planet.day_speed.name}

end

function Public_gui.update_gui(player)
  local objective = global.objective
	update_planet_gui(player)
	update_upgrades_gui(player)
	if not player.gui.top.chronosphere then create_gui(player) end
	local gui = player.gui.top.chronosphere

	gui.label.caption = {"chronosphere.gui_1"}
	gui.jump_number.caption = objective.chronojumps

	local interval = objective.chrononeeds
	gui.progressbar.value = 1 - (objective.chrononeeds - objective.chronotimer) / interval

	gui.charger.caption = {"chronosphere.gui_2"}
	gui.charger_value.caption = objective.chronotimer .. " / " .. objective.chrononeeds

  gui.timer.caption = {"chronosphere.gui_3"}
	gui.timer_value.caption = math_floor((objective.chrononeeds - objective.chronotimer) / 60) .. " min, " .. (objective.chrononeeds - objective.chronotimer) % 60 .. " s"
	if objective.chronojumps > 5 then
		local overstay_timer_min = math_floor((objective.chrononeeds * 0.75 - objective.passivetimer) / 60)
		local evo_timer_min = math_floor((objective.chrononeeds * 0.5 - objective.passivetimer) / 60)
		local first_part = "If overstaying this, other planets can evolve: " .. overstay_timer_min .. " min, " .. (objective.chrononeeds * 0.75 - objective.passivetimer) % 60 .. " s"
		if overstay_timer_min < 0 then
			first_part = "If overstaying this, other planets can evolve: " .. overstay_timer_min .. " min, " .. 59 - ((objective.chrononeeds * 0.75 - objective.passivetimer) % 60) .. " s"
		end
		local second_part = "This planet gets additional evolution growth in: " ..evo_timer_min .. " min, " .. (objective.chrononeeds * 0.5 - objective.passivetimer) % 60 .. " s"
		if evo_timer_min < 0 then
			second_part = "This planet gets additional evolution growth in: " ..evo_timer_min .. " min, " .. 59 -((objective.chrononeeds * 0.5 - objective.passivetimer) % 60) .. " s"
		end
		gui.timer_value.tooltip = first_part .. "\n" .. second_part
	else
		gui.timer_value.tooltip = "After planet 5, biters will get additional permanent evolution for staying too long on each planet."
	end

	gui.planet_button.caption = {"chronosphere.gui_planet_button"}
	gui.upgrades_button.caption = {"chronosphere.gui_upgrades_button"}

  local acus = 0
  if global.acumulators then acus = #global.acumulators end
  local bestcase = math_floor((objective.chrononeeds - objective.chronotimer) / (1 + math_floor(acus/10)))
	local nukecase = objective.dangertimer
	if objective.planet[1].name.id == 19 and objective.passivetimer > 31 then
		gui.timer2.caption = {"chronosphere.gui_3_2"}
		gui.timer_value2.caption = math_floor(nukecase / 60) .. " min, " .. nukecase % 60 .. " s"
		gui.timer2.style.font_color = {r=0.98, g=0, b=0}
		gui.timer_value2.style.font_color = {r=0.98, g=0, b=0}
	else
		gui.timer2.caption = {"chronosphere.gui_3_1"}
		gui.timer_value2.caption = math_floor(bestcase / 60) .. " min, " .. bestcase % 60 .. " s (when using " .. acus * 0.3 .. "MW)"
		gui.timer2.style.font_color = {r = 0, g = 200, b = 0}
		gui.timer_value2.style.font_color = {r = 0, g = 200, b = 0}
	end
end

local function upgrades_gui(player)
	if player.gui.screen["gui_upgrades"] then player.gui.screen["gui_upgrades"].destroy() return end
	local objective = global.objective
	local upgrades = Upgrades.upgrades()
	local frame = player.gui.screen.add{type = "frame", name = "gui_upgrades", caption = "ChronoTrain Upgrades", direction = "vertical"}
  frame.location = {x = 350, y = 45}
  frame.style.minimal_height = 300
  frame.style.maximal_height = 900
  frame.style.minimal_width = 330
  frame.style.maximal_width = 630
  frame.add({type = "label", caption = {"chronosphere.gui_upgrades_1"}})
	frame.add({type = "label", caption = {"chronosphere.gui_upgrades_2"}})

	for i = 1, #upgrades, 1 do
		local upg_table = frame.add({type = "table", name = "upgrades_table" .. i, column_count = 10})
		upg_table.add({type = "sprite-button", name = "upgrade" .. i, enabled = false, sprite = upgrades[i].sprite, number = global.objective.upgrades[i], tooltip = upgrades[i].tooltip})
		local name = upg_table.add({type = "label", name ="upgrade_label" .. i, caption = upgrades[i].name, tooltip = upgrades[i].tooltip})
		name.style.width = 200

		local maxed = upg_table.add({type = "sprite-button", name = "maxed" .. i, enabled = false, sprite = "virtual-signal/signal-check", tooltip = "Upgrade maxed!", visible = false})
		local jumps = upg_table.add({type = "sprite-button", name = "jump_req" .. i, enabled = false, sprite = "virtual-signal/signal-J", number = upgrades[i].jump_limit, tooltip = "Required jump number", visible = true})
		local costs = {}
		for index,item in pairs(upgrades[i].cost) do
			costs[index] = upg_table.add({type = "sprite-button", name = index .. "-" .. i, number = item.count, sprite = item.sprite, enabled = false, tooltip = {item.tt .. "." .. item.name}, visible = true})
		end
		if global.objective.upgrades[i] == upgrades[i].max_level then
			maxed.visible = true
			jumps.visible = false
			for index,_ in pairs(upgrades[i].cost) do
				costs[index].visible = false
			end
		else
			maxed.visible = false
			jumps.visible = true
			for index,_ in pairs(upgrades[i].cost) do
				costs[index].visible = true
			end
		end
	end
  frame.add({type = "button", name = "close_upgrades", caption = "Close"})
end

local function planet_gui(player)
	if player.gui.screen["gui_planet"] then player.gui.screen["gui_planet"].destroy() return end
	local planet = global.objective.planet[1]
	local evolution = game.forces["enemy"].evolution_factor
	local frame = player.gui.screen.add{type = "frame", name = "gui_planet", caption = "Planet Info", direction = "vertical"}
  frame.location = {x = 650, y = 45}
  frame.style.minimal_height = 300
  frame.style.maximal_height = 500
  frame.style.minimal_width = 200
  frame.style.maximal_width = 400
	local l = {}
	l[1] = frame.add({type = "label", name = "planet_name", caption = {"chronosphere.gui_planet_0", planet.name.name}})
  l[2] = frame.add({type = "label", caption = {"chronosphere.gui_planet_1"}})
	local table0 = frame.add({type = "table", name = "planet_ores", column_count = 3})
	table0.add({type = "sprite-button", name = "iron-ore", sprite = "item/iron-ore", enabled = false, number = planet.name.iron})
	table0.add({type = "sprite-button", name = "copper-ore", sprite = "item/copper-ore", enabled = false, number = planet.name.copper})
	table0.add({type = "sprite-button", name = "coal", sprite = "item/coal", enabled = false, number = planet.name.coal})
	table0.add({type = "sprite-button", name = "stone", sprite = "item/stone", enabled = false, number = planet.name.stone})
	table0.add({type = "sprite-button", name = "uranium-ore", sprite = "item/uranium-ore", enabled = false, number = planet.name.uranium})
	table0.add({type = "sprite-button", name = "oil", sprite = "fluid/crude-oil", enabled = false, number = planet.name.oil})
	l[3] = frame.add({type = "label", name = "richness", caption = {"chronosphere.gui_planet_2", planet.ore_richness.name}})
	frame.add({type = "line"})
	frame.add({type = "label", name = "planet_biters", caption = {"chronosphere.gui_planet_3", math_floor(evolution * 1000) / 10}})
	frame.add({type = "label", name = "planet_biters2", caption = {"chronosphere.gui_planet_4"}})
	frame.add({type = "label", name = "planet_biters3", caption = {"chronosphere.gui_planet_4_1", global.objective.passivejumps * 2.5, global.objective.passivejumps * 10}})
	frame.add({type = "line"})
	frame.add({type = "label", name = "planet_time", caption = {"chronosphere.gui_planet_5", planet.day_speed.name}})
	frame.add({type = "line"})
  local close = frame.add({type = "button", name = "close_planet", caption = "Close"})
	close.style.horizontal_align = "center"
	-- for i = 1, 3, 1 do
	-- 	l[i].style.font = "default-game"
	-- end
end

function Public_gui.on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	if event.element.name == "upgrades_button" then
		upgrades_gui(player)
		return
	elseif event.element.name == "planet_button" then
		planet_gui(player)
		return
	end

	if event.element.type ~= "button" and event.element.type ~= "sprite-button" then return end
	local name = event.element.name
	if name == "close_upgrades" then upgrades_gui(player) return end
  if name == "close_planet" then planet_gui(player) return end
end

return Public_gui
