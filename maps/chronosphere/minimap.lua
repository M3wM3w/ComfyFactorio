local Public = {}

local Chrono_table = require 'maps.chronosphere.table'

local function create_button(player)
  local button = player.gui.top.add({ type = "sprite-button", name = "minimap_button", sprite = "utility/map", tooltip = {"chronosphere.minimap_button_tooltip"}})
  button.visible = false
end

function Public.toggle_button(player)
  if not player.gui.top["minimap_button"] then
    create_button(player)
  end
  local button = player.gui.top["minimap_button"]
  if player.surface.name == "cargo_wagon" then
    button.visible = true
  else
    button.visible = false
  end
end

local function get_player_data(player)
  local playertable = Chrono_table.get_player_table()
  local objective = Chrono_table.get_table()
	local player_data = playertable.icw.players[player.index]
	if playertable.icw.players[player.index] then return player_data end

	playertable.icw.players[player.index] = {
		surface = objective.active_surface_index,
		zoom = 0.30,
		map_size = 360,
    auto_map = true,
    coords = {x = 10, y = 45}
	}
	return playertable.icw.players[player.index]
end

function Public.toggle_auto(player)
  local player_data = get_player_data(player)
  local playertable = Chrono_table.get_player_table()
  local switch = player.gui.screen.icw_map_frame["switch_auto_map"]
  if switch.switch_state == "left" then
    playertable.icw.players[player.index].auto_map = true
  elseif switch.switch_state == "right" then
    playertable.icw.players[player.index].auto_map = false
  end
end

local function kill_minimap(player)
	local element = player.gui.screen.icw_map_frame
  local player_data = get_player_data(player)
  if element then
    player_data.coords = {x = element.location.x, y = element.location.y}
    if element["switch_auto_map"].switch_state == "left" then
      player_data.auto_map = true
    else
      player_data.auto_map = false
    end
    element.destroy()
  end
  --if element.visible then element.visible = false end
end

local function kill_frame(player)
  if player.gui.screen.icw_map_frame then
    local element = player.gui.screen.icw_map_frame.icw_map
    element.destroy()
  end
end

local function draw_minimap(player)
  local objective = Chrono_table.get_table()
  local surface = game.surfaces[objective.active_surface_index]
  local position = objective.locomotive.position
  local player_data = get_player_data(player)
  local frame = player.gui.screen.icw_map_frame
  if not frame then
    frame = player.gui.screen.add({ type = "frame", direction = "vertical", name = "icw_map_frame", caption = {"chronosphere.minimap"}})
    frame.location = player_data.coords or {x = 10, y = 45}
    switch_state = "right"
  	if player_data.auto_map then switch_state = "left" end
    frame.add({type = "switch", name = "switch_auto_map", allow_none_state = false, switch_state = switch_state, left_label_caption = {"chronosphere.map_on"}, right_label_caption = {"chronosphere.map_off"}})
  end
  frame.visible = true
	local element = frame["icw_map"]
	if not element then

		element = player.gui.screen.icw_map_frame.add({
			type = "camera",
			name = "icw_map",
			position = position,
			surface_index = surface.index,
			zoom = player_data.zoom,
			tooltip = {"chronosphere.minimap_tooltip"}
		})
		element.style.margin = 1
		element.style.minimal_height = player_data.map_size
		element.style.minimal_width = player_data.map_size
		return
	end
	element.position = position
end

function Public.minimap(player, autoaction)
  local player_data = get_player_data(player)
  local frame = player.gui.screen["icw_map_frame"]
  if frame then
    kill_minimap(player)
  else
    if player.surface.name == "cargo_wagon" then
      if autoaction then
        if player_data.auto_map then
          draw_minimap(player)
        end
      else
        draw_minimap(player)
      end
    end
  end
end

function Public.update_minimap(player)
  if player then
    kill_minimap(player)
    if player.surface.name == "cargo_wagon" then
      draw_minimap(player)
    end
  else
    for _, player in pairs(game.connected_players) do
      kill_minimap(player)
			if player.surface.name == "cargo_wagon" then
				draw_minimap(player)
			end
  	end
  end
end

function Public.update_surface(player)
  local objective = Chrono_table.get_table()
  local playertable = Chrono_table.get_player_table()
  if not player then
    for k, _ in pairs(playertable.icw.players) do
      playertable.icw.players[k].surface = objective.active_surface_index
      Public.update_minimap()
    end
  else
    local data = get_player_data(player)
    data.surface = objective.active_surface_index
    Public.update_minimap(player)
  end
end

function Public.toggle_minimap(event)
	local element = event.element
	if not element then return end
	if not element.valid then return end
	if element.name ~= "icw_map" then return end
	local player = game.players[event.player_index]
	local player_data = get_player_data(player)
	if event.button == defines.mouse_button_type.right then
		player_data.zoom = player_data.zoom - 0.07
		if player_data.zoom < 0.07 then player_data.zoom = 0.07 end
		element.zoom = player_data.zoom
		return
	end
	if event.button == defines.mouse_button_type.left then
		player_data.zoom = player_data.zoom + 0.07
		if player_data.zoom > 2 then player_data.zoom = 2 end
		element.zoom = player_data.zoom
		return
	end
	if event.button == defines.mouse_button_type.middle then
		player_data.map_size = player_data.map_size + 50
		if player_data.map_size > 650 then player_data.map_size = 250 end
		element.style.minimal_height = player_data.map_size
		element.style.minimal_width = player_data.map_size
		element.style.maximal_height = player_data.map_size
		element.style.maximal_width = player_data.map_size
		return
	end
end

return Public
