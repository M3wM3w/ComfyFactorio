local Public = {}
local Team = require "maps.native_war.team"
local XP = require "maps.native_war.xp"
local Settings = require "maps.native_war.settings"

local button_science_name={}
for _ ,nbw in pairs(Settings.nb_of_waves) do
	for k,sp in pairs(Settings.science_pack) do
		table.insert(button_science_name , {sp = k, spc = sp.short, button_name = sp.short.."_"..nbw, nbw = nbw})
	end
end

local function create_new_gui_for_market(player,market)
	local player_inventory = player.get_main_inventory()
	local player_red_science_pack = player_inventory.get_item_count("automation-science-pack")
	local player_green_science_pack = player_inventory.get_item_count("logistic-science-pack")
	local player_grey_science_pack = player_inventory.get_item_count("military-science-pack")
	local player_blue_science_pack = player_inventory.get_item_count("chemical-science-pack")
	local player_purple_science_pack = player_inventory.get_item_count("production-science-pack")
	local player_yellow_science_pack = player_inventory.get_item_count("utility-science-pack")
	local player_white_science_pack = player_inventory.get_item_count("space-science-pack")


	local root = player.gui.screen
	local frame = root.add({type = "frame", name = "market_frame", caption = "Market",direction = "vertical"})
	frame.style.font = "default"
	frame.style.font_color = {r = 0.3, g = 0.65, b = 0.3}
	frame.style.horizontal_align = "center"
	frame.add({type = "label", caption="Buy waves of biter/spitter"})
	local line = frame.add({type = "line", direction = "horizontal"})
	local table = frame.add({type = "table", column_count = 5, draw_horizontal_lines = true, draw_vertical_lines = true})
	local case = table.add({type = "sprite", sprite="file/graphics/vide.png"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite = "entity/small-biter"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite = "entity/medium-biter"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite = "entity/big-biter"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite = "entity/behemoth-biter"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30

	for _, nb in pairs(Settings.nb_of_waves) do
		local wave_nb = nb
		local text_wave =""
		if wave_nd == 1 then
			text_wave = wave_nb.." wave"
		else
			text_wave = wave_nb.." waves"
		end
		local case = table.add({type = "label", caption= text_wave})
		case.style.right_padding = 30
		local case = table.add({type = "flow", direction = "horizontal"})
		case.add({type = "sprite-button", sprite = "item/automation-science-pack", name = "red_"..wave_nb, tooltip = "Buy "..wave_nb.." wave of small biter/spitter.\nPrice: "..wave_nb*Settings.wave_price["automation-science-pack"].price.." [item=automation-science-pack].", number = math.floor((player_red_science_pack/Settings.wave_price["automation-science-pack"].price)/wave_nb)})
		case.add({type = "sprite-button", sprite = "item/logistic-science-pack", name = "green_"..wave_nb, tooltip = "Buy 1 wave of small biter/spitter.\nPrice: "..wave_nb*Settings.wave_price["logistic-science-pack"].price.." [item=logistic-science-pack].", number = math.floor((player_green_science_pack/Settings.wave_price["logistic-science-pack"].price)/wave_nb)})
		case.style.right_padding = 12
		case.style.left_padding = 12
		local case = table.add({type = "flow", direction = "horizontal"})
		case.add({type = "sprite-button", sprite = "item/military-science-pack", name = "grey_"..wave_nb, tooltip = "Buy "..wave_nb.." wave of medium biter/spitter.\nPrice: "..wave_nb*Settings.wave_price["military-science-pack"].price.." [item=military-science-pack].", number = math.floor((player_grey_science_pack/Settings.wave_price["military-science-pack"].price)/wave_nb)})
		case.style.left_padding = 30
		case.style.right_padding = 30
		local case = table.add({type = "flow", direction = "horizontal"})
		case.add({type = "sprite-button", sprite = "item/chemical-science-pack", name = "blue_"..wave_nb, tooltip = "Buy "..wave_nb.." wave of big biter/spitter.\nPrice: "..wave_nb*Settings.wave_price["chemical-science-pack"].price.." [item=chemical-science-pack].", number = math.floor((player_blue_science_pack/Settings.wave_price["chemical-science-pack"].price)/wave_nb)})
		case.style.left_padding = 30
		case.style.right_padding = 30
		local case = table.add({type = "flow", direction = "horizontal"})
		case.add({type = "sprite-button", sprite = "item/production-science-pack", name = "purple_"..wave_nb, tooltip = "Buy "..wave_nb.." wave of behemoth biter/spitter.\nPrice: "..wave_nb*Settings.wave_price["production-science-pack"].price.." [item=production-science-pack].", number = math.floor((player_purple_science_pack/Settings.wave_price["production-science-pack"].price)/wave_nb)})
		case.add({type = "sprite-button", sprite = "item/utility-science-pack", name = "yellow_"..wave_nb, tooltip = "Buy "..wave_nb.." wave of behemoth biter/spitter.\nPrice: "..wave_nb*Settings.wave_price["utility-science-pack"].price.." [item=utility-science-pack].", number = math.floor((player_yellow_science_pack/Settings.wave_price["utility-science-pack"].price)/wave_nb)})
		case.style.right_padding = 12
		case.style.left_padding = 12
	end

	local line = frame.add({type = "line", direction = "horizontal"})
	frame.add({type = "label", caption="Buy/ugrade worm turret"})

	local table = frame.add({type = "table", column_count = 5, draw_horizontal_lines = true, draw_vertical_lines = true})
	local case = table.add({type = "sprite", sprite="file/graphics/vide.png"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite = "entity/small-worm-turret"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite = "entity/medium-worm-turret"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite = "entity/big-worm-turret"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite = "entity/behemoth-worm-turret"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30

	for _, dist in pairs(Settings.worm_dist) do
		local turret = ""
		if dist == "all" then
			turret = "turrets"
		else
			turret = "turret"
		end
		local case = table.add({type = "label", caption=dist})
		case.style.right_padding = 30
		local case = table.add({type = "flow", direction = "horizontal"})
		case.add({type = "sprite-button", sprite = "item/automation-science-pack", name = "red_"..dist, tooltip = "Buy "..dist.." worm "..turret..".\nPrice: "..Settings.upgrade_turret_price["automation-science-pack"].price.." [item=automation-science-pack].", number = math.floor(player_red_science_pack/Settings.upgrade_turret_price["automation-science-pack"].price)})
		case.add({type = "sprite-button", sprite = "item/logistic-science-pack", name = "green_"..dist, tooltip = "Buy "..dist.." worm "..turret..".\nPrice: "..Settings.upgrade_turret_price["logistic-science-pack"].price.." [item=logistic-science-pack].", number = math.floor(player_green_science_pack/Settings.upgrade_turret_price["logistic-science-pack"].price)})
		case.style.right_padding = 12
		case.style.left_padding = 12
		local case = table.add({type = "flow", direction = "horizontal"})
		case.add({type = "sprite-button", sprite = "item/military-science-pack", name = "grey_"..dist, tooltip =  "Upgrade "..dist.." worm "..turret..".\nPrice: "..Settings.upgrade_turret_price["military-science-pack"].price.." [item=military-science-pack].", number = math.floor(player_grey_science_pack/Settings.upgrade_turret_price["military-science-pack"].price)})
		case.style.left_padding = 30
		case.style.right_padding = 30
		local case = table.add({type = "flow", direction = "horizontal"})
		case.add({type = "sprite-button", sprite = "item/chemical-science-pack", name = "blue_"..dist, tooltip = "Upgrade "..dist.." worm "..turret..".\nPrice: "..Settings.upgrade_turret_price["chemical-science-pack"].price.." [item=chemical-science-pack].", number = math.floor(player_blue_science_pack/Settings.upgrade_turret_price["chemical-science-pack"].price)})
		case.style.left_padding = 30
		case.style.right_padding = 30
		local case = table.add({type = "flow", direction = "horizontal"})
		case.add({type = "sprite-button", sprite = "item/production-science-pack", name = "purple_"..dist, tooltip = "Upgrade "..dist.." worm "..turret..".\nPrice: "..Settings.upgrade_turret_price["production-science-pack"].price.." [item=production-science-pack].", number = math.floor(player_purple_science_pack/Settings.upgrade_turret_price["production-science-pack"].price)})
		case.add({type = "sprite-button", sprite = "item/utility-science-pack", name = "yellow_"..dist, tooltip = "Upgrade "..dist.." worm "..turret..".\nPrice: "..Settings.upgrade_turret_price["utility-science-pack"].price.." [item=utility-science-pack].", number = math.floor(player_yellow_science_pack/Settings.upgrade_turret_price["utility-science-pack"].price)})
		case.style.right_padding = 12
		case.style.left_padding = 12
	end

	local line = frame.add({type = "line", direction = "horizontal"})
	frame.add({type = "label", caption="Upgrade biter"})
	local table = frame.add({type = "table", column_count = 5, draw_horizontal_lines = true, draw_vertical_lines = true})
	local case = table.add({type = "sprite", sprite="file/graphics/vide.png"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite="file/graphics/Splash.png"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite="file/graphics/resist.png"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite="file/graphics/griffe.png"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30
	local case = table.add({type = "sprite", sprite="file/graphics/life.png"})
	case.style.horizontal_align = "center"
	case.style.right_padding = 30
	case.style.left_padding = 30

	local xp_t = XP.get_table()
	local xp_available = xp_t[player.index].xp

	local case = table.add({type = "flow", direction = "vertical"})
	case.add({type = "label", caption="Available XP :"})
	case.add({type = "label", caption=math.floor(xp_available)})
	local case = table.add({type = "flow", direction = "horizontal"})
	local b = case.add({type = "button", name = "xp_splash", caption = "10 XP",tooltip = "Increase spitters splash damage.\nPrice: 10 XP."})
	b.style.minimal_width = 50
	case.style.top_padding = 5
	case.style.left_padding = 20
	local case = table.add({type = "flow", direction = "horizontal"})
	local b = case.add({type = "button", name = "xp_resistance", caption = "10 XP",tooltip = "Increase resistance of all your biter/spitter.\nPrice: 10 XP."})
	b.style.minimal_width = 50
	case.style.top_padding = 5
	case.style.left_padding = 20
	local case = table.add({type = "flow", direction = "horizontal"})
	local b = case.add({type = "button", name = "xp_damage", caption = "10 XP",tooltip = "Increase biter melee damage.\nPrice: 10 XP."})
	b.style.minimal_width = 50
	case.style.top_padding = 5
	case.style.left_padding = 20
	local case = table.add({type = "flow", direction = "horizontal"})
	case.add({type = "sprite-button", name = "add_life", sprite = "item/space-science-pack",tooltip = "Buy extra life for all your biter/spitter.\nPrice: 1000 [item=space-science-pack].", number = math.floor(player_white_science_pack/1000)})
	case.style.left_padding = 30
	case.style.right_padding = 30

	local line = frame.add({type = "line", direction = "horizontal"})
	frame.add({type = "button", name = "cancel_market", caption = "Close"})
end

local function on_gui_opened(event)
	if not event then return end
	if not event.entity then return end
	if event.entity.name == "market" then
	local player = game.players[event.player_index]
		event.entity.operable =false
		create_new_gui_for_market(player,event.entity)
	end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	local player_inventory = player.get_main_inventory()

	--[[if event.element.name == "confirm_rejoin" then
		player.gui.center["rejoin_question_frame"].destroy()
		Team.assign_force_to_player(player)
		Team.teleport_player_to_active_surface(player)
		Team.put_player_into_random_team(player)
		game.print(player.name .. " has rejoined the game!")
		return
	end
	if event.element.name == "cancel_rejoin" then player.gui.center["rejoin_question_frame"].destroy() return end
	if player.force.name == "spectator" then return end
	if event.element.name == "cancel_spectate" then player.gui.center["spectate_confirmation_frame"].destroy() return end

	if event.element.name == "cancel_spectate" then player.gui.center["spectate_confirmation_frame"].destroy() return end]]

	if event.element.name == "cancel_market" then
		player.gui.screen["market_frame"].destroy()
		local surface = game.surfaces["native_war"]
		if player.force.name == "west" then
			local market = surface.find_entities_filtered{position = {-197,0}, radius = 5, type = "market"}
		 	market[1].operable = true
		elseif player.force.name == "east" then
		 local market = surface.find_entities_filtered{position = {197,0}, radius = 5, type = "market"}
		 market[1].operable = true
	 	end
		return
	end

	--[[if event.element.name == "confirm_spectate" then
		player.gui.screen["spectate_confirmation_frame"].destroy()
		Team.set_player_to_spectator(player)
		game.print(player.name .. " has turned into a spectator ghost.")
		return
	end

	if event.element.name == "spectate_button" then
		if player.gui.screen["spectate_confirmation_frame"] then
			player.gui.screen["spectate_confirmation_frame"].destroy()
		else
			create_spectate_confirmation(player)
		end
		return
	end]]
	local xp_t = XP.get_table()
	local xp_available = xp_t[player.index].xp
	local amount = 10
	if event.element.name == "xp_splash" and xp_available >= amount then
		XP.lost_xp(player, amount)
		global.map_forces[player.force.name].modifier.splash = global.map_forces[player.force.name].modifier.splash + 0.001
		player.gui.screen["market_frame"].destroy()
		create_new_gui_for_market(player,event.entity)
	end
	if event.element.name == "xp_damage" and xp_available >= amount then
		XP.lost_xp(player, amount)
		global.map_forces[player.force.name].modifier.damage = global.map_forces[player.force.name].modifier.damage + 0.001
		player.gui.screen["market_frame"].destroy()
		create_new_gui_for_market(player,event.entity)
	end
	if event.element.name == "xp_resistance" and xp_available >= amount then
		XP.lost_xp(player, amount)
		global.map_forces[player.force.name].modifier.resistance = global.map_forces[player.force.name].modifier.resistance - 0.001
		player.gui.screen["market_frame"].destroy()
		create_new_gui_for_market(player,event.entity)
	end
	if event.element.name == "add_life" and player_inventory.get_item_count("space-science-pack") >= 1000 then
		XP.buy_extra_life(player.force.name)
		player.remove_item({name="space-science-pack", count=1000})
		player.gui.screen["market_frame"].destroy()
		create_new_gui_for_market(player,event.entity)
	end


	for _, button in pairs(button_science_name) do
		if event.element.name == button.button_name then
			local count = 0
			for i = 1, button.nbw, 1 do
				if player_inventory.get_item_count(button.sp) < Settings.wave_price[button.sp].price then break end
				 player.remove_item({name=button.sp, count=Settings.wave_price[button.sp].price})
				 Team.on_buy_wave("native_war", player.force.name, button.spc)
				 count = count + 1
			end
			if count > 0 then
				if button.nbw > 1 then
					game.print(player.name.." buy "..count.." waves of biter/spitters using [item="..button.sp.."]", Settings.color[button.sp])
				else
					game.print(player.name.." buy "..count.." wave of biter/spitters using [item="..button.sp.."]", Settings.color[button.sp])
				end
			end
				player.gui.screen["market_frame"].destroy()
				create_new_gui_for_market(player,event.entity)
				break
		end
	end


	for k, button in pairs(Settings.button_upgrade_name) do  --sp = k, spc = sp.short, button_name = sp.short.."_"..dist, dist = dist, type_worm = sp.t
		if event.element.name == k then
			if player_inventory.get_item_count(button.sp) >= Settings.upgrade_turret_price[button.sp].price then
				if button.sp == "automation-science-pack" or button.sp == "logistic-science-pack" then
					if Team.buy_worm_turret(game.surfaces["native_war"], player.force.name, button.dist, player, player_inventory.get_item_count(button.sp),Settings.upgrade_turret_price[button.sp].price, button.sp) then
						player.gui.screen["market_frame"].destroy()
						create_new_gui_for_market(player,event.entity)
						break
					else
						player.print("All small worm turrets are already buy", Settings.color["message"])
						player.gui.screen["market_frame"].destroy()
						create_new_gui_for_market(player,event.entity)
						break
					end
				else
					if Team.upgrade_worm_turret(game.surfaces["native_war"], player.force.name, button.dist, player, player_inventory.get_item_count(button.sp),Settings.upgrade_turret_price[button.sp].price, button.sp, button.type_worm.."-worm-turret") then
						player.gui.screen["market_frame"].destroy()
						create_new_gui_for_market(player,event.entity)
						break
					else
						local table_upgrade = {
							["medium"] = "small",
							["big"] = "medium",
							["behemoth"] = "big"
						}
						player.print("There is no more "..table_upgrade[button.type_worm].." worm turrets to upgrade with  [item="..button.sp.."].", Settings.color["message"])
						player.gui.screen["market_frame"].destroy()
						create_new_gui_for_market(player,event.entity)
						break
					end
				end
			end
		end
	end
end

local event = require 'utils.event'
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_gui_opened, on_gui_opened)

return Public
