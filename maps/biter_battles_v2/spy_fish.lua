local function spy_fish(player)
	if not player.character then return end
	local duration_per_unit = 2700 
	local i2 = player.get_inventory(defines.inventory.character_main)
	if not i2 then return end
	local owned_fishes = i2.get_item_count("raw-fish")
	owned_fishes = owned_fishes + i2.get_item_count("raw-fish")
	if owned_fishes == 0 then 
		player.print("You have no fish in your inventory.",{ r=0.98, g=0.66, b=0.22})
	else
		local x = i2.remove({name="raw-fish", count=1})
		if x == 0 then i2.remove({name="raw-fish", count=1}) end
		local enemy_team = "south"
		if player.force.name == "south" then enemy_team = "north" end													 
		if global.spy_fish_timeout[player.force.name] - game.tick > 0 then 
			global.spy_fish_timeout[player.force.name] = global.spy_fish_timeout[player.force.name] + duration_per_unit
			player.print(math.ceil((global.spy_fish_timeout[player.force.name] - game.tick) / 60) .. " seconds of enemy vision left.", { r=0.98, g=0.66, b=0.22})
		else			
			game.print(player.name .. " sent a fish to spy on " .. enemy_team .. " team!", {r=0.98, g=0.66, b=0.22})			
			global.spy_fish_timeout[player.force.name] = game.tick + duration_per_unit							
		end		
	end
end

return spy_fish