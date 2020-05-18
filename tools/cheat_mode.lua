function cheat_mode()
	local surface = game.players[1].surface
	game.player.cheat_mode=true
	game.players[1].insert({name="power-armor-mk2"})
	game.players[1].insert({name="fusion-reactor-equipment", count=4})
	game.players[1].insert({name="personal-laser-defense-equipment", count=8})
	game.players[1].insert({name="rocket-launcher"})		
	game.players[1].insert({name="railgun", count=1})
	game.players[1].insert({name="railgun-dart", count=10})
	game.players[1].insert({name="coin", count = 100000})
	game.players[1].insert({name="loader"})
	game.players[1].insert({name="fast-loader"})
	game.players[1].insert({name="express-loader"})
	game.players[1].insert({name="infinity-chest", count = 15})
	game.players[1].insert({name="computer", count=2})
	game.players[1].insert({name="raw-fish", count=2000})
	game.players[1].insert({name="submachine-gun", count=1})
	game.players[1].insert({name="uranium-rounds-magazine", count=200})
	game.players[1].insert({name="steel-chest", count=200})
	game.players[1].insert({name="electric-energy-interface", count=2})
	game.forces.player.manual_mining_speed_modifier = 3
	game.forces.player.character_reach_distance_bonus = 1000
	game.forces.player.character_health_bonus = 1000
	game.speed = 1
	surface.daytime = 1
	--surface.freeze_daytime = 1
	game.player.force.research_all_technologies()
	game.forces["enemy"].evolution_factor = 0.1
	local chart = 128	
	game.forces["player"].chart(surface, {lefttop = {x = chart*-1, y = chart*-1}, rightbottom = {x = chart, y = chart}})			
end