global.this = {}
local _global = require("utils.global")
local _evt = require("utils.event")
local _server = require("utils.server")
local _map = require("tools.map_functions")
local _timers = require("planet_prison.mod.timers")
local _common = require("planet_prison.mod.common")
local _layers = require("planet_prison.mod.layers")
local _ai = require("planet_prison.mod.ai")
local _bp = require("planet_prison.mod.bp")
local _afk = require("planet_prison.mod.afk")
local _claims = require("planet_prison.mod.claims")
global.this._config = require("planet_prison.config")

global.this.maps = {
   {
      name = "flooded-metropolia",
      height = 2000,
      width = 2000,
      water = 1,
      terrain_segmentation = 8,
      property_expression_names = {
         moisture = 0,
         temperature = 30.
      },
      cliff_settings = {
         richness = 0,
      },
      starting_area = "none",
      autoplace_controls = {
         ["iron-ore"] = {
            frequency = 0,
         },
         ["copper-ore"] = {
            frequency = 0,
         },
         ["uranium-ore"] = {
            frequency = 0,
         },
         ["stone"] = {
            frequency = 0,
         },
         ["coal"] = {
            frequency = 0,
         },
         ["crude-oil"] = {
            frequency = 1000,
            size = 1,
         },
         ["trees"] = {
            frequency = 4,
         },
         ["enemy-base"] = {
            frequency = 0,
         }
      },
   }
}

global.this.assign_camouflage = function(ent, common)
   local shade = common.rand_range(20, 200)
   ent.color = {
      r = shade,
      g = shade,
      b = shade
   }
   ent.disable_flashlight()
end

local function noise_hostile_hook(ent, common)
   ent.force = "enemy"
   if ent.name == "character" then
      global.this.assign_camouflage(ent, common)

      if common.rand_range(1, 5) == 1 then
         ent.insert({name="shotgun", count=1})
         ent.insert({name="shotgun-shell", count=20})
      else
         ent.insert({name="pistol", count=1})
         ent.insert({name="firearm-magazine", count=20})
      end
   else
      ent.insert({name="firearm-magazine", count=200})
   end
end

local function noise_set_neutral_hook(ent)
   ent.force = "neutral"
end

local industrial_zone_layers = {
   {
      type = "LuaTile",
      name = "concrete",
      objects = {
         "concrete",
      },
      elevation = 0.3,
      resolution = 0.2,
      hook = nil,
      deps = nil,
   },
   {
      type = "LuaTile",
      name = "stones",
      objects = {
         "stone-path",
      },
      elevation = 0.2,
      resolution = 0.4,
      hook = nil,
      deps = nil,
   },
   {
      type = "LuaTile",
      name = "shallows",
      objects = {
         "water-shallow",
      },
      elevation = 0.7,
      resolution = 0.01,
      hook = nil,
      deps = nil,
   },
   {
      type = "LuaEntity",
      name = "scrap",
      objects = {
         "mineable-wreckage",
      },
      elevation = 0.5,
      resolution = 0.1,
      hook = nil,
      deps = nil,
   },
   {
      type = "LuaEntity",
      name = "walls",
      objects = {
         "stone-wall"
      },
      elevation = 0.5,
      resolution = 0.09,
      hook = noise_set_neutral_hook,
      deps = nil,
   },
   {
      type = "LuaEntity",
      name = "hostile",
      objects = {
         "character",
         "gun-turret",
      },
      elevation = 0.92,
      resolution = 0.99,
      hook = noise_hostile_hook,
      deps = _common,
   },
   {
      type = "LuaEntity",
      name = "structures",
      objects = {
         "big-electric-pole",
         "medium-electric-pole",
      },
      elevation = 0.9,
      resolution = 0.9,
      hook = noise_set_neutral_hook,
      deps = nil,
   },
}

global.this.presets = {
   ["flooded-metropolia"] = industrial_zone_layers,
}

global.this.entities_cache = nil
global.this.surface = nil
global.this.last_friend = nil
local function pick_map()
   return global.this.maps[_common.rand_range(1, #global.this.maps)]
end

local function find_force(name)
   for _, f in pairs(game.forces) do
      if f.name == name then
         return f
      end
   end

   return nil
end

local function init_player_ship_bp(entity, player)
   entity.force = player.force
   if entity.name == "crash-site-chest-1" then
      for _, stack in pairs(global.this._config.player_ship_loot) do
         entity.insert(stack)
      end
   end

   if entity.name == "crash-site-generator" then
      entity.electric_buffer_size = 2000
      entity.power_production = 2000
   end
end

global.this.events = {
   merchant = {
      alive = false,
      moving = false,
      spawn_tick = 0,
      embark_tick = 0,
      position = { x = 0, y = 0 },
      offer = global.this._config.merchant_offer,
   }
}
local function init_merchant_bp(entity, _)
   entity.force = "merchant"
   entity.rotatable = false
   entity.minable = false
   if entity.name ~= "market" then
      entity.operable = false
   else
      for _, entry in pairs(global.this.events.merchant.offer) do
         entity.add_market_item(entry)
      end
   end
end

local function create_orbit_group()
   local orbit = game.permissions.create_group("orbit")
   for _, perm in pairs(global.this._config.permission_orbit) do
      orbit.set_allows_action(perm, false)
   end
end

global.this.bp = {
   player_ship = require("planet_prison.bp.player_ship"),
   merchant = require("planet_prison.bp.merchant")
}
local function init_game()
   _common.init()
   _layers.init()
   _bp.init()
   _ai.init()
   _timers.init()
   _claims.init(global.this._config.claim_markers,
                global.this._config.claim_max_distance)

   local map = pick_map()
   local preset = global.this.presets[map.name]
   global.this.surface = game.create_surface("arena", map)
   global.this.surface.brightness_visual_weights = {
      1 / 0.85,
      1 / 0.85,
      1 / 0.85
   }
   global.this.surface.ticks_per_day = 25000 * 4
   global.this.perks = {}
   global.this.events.merchant.spawn_tick = game.tick + 5000
   global.this.events.raid_groups = {}
   global.this.events.raid_init = false
   global.this.events.annihilation = false
   global.this.events.reset_time = nil

   create_orbit_group()
   game.map_settings.pollution.enabled = false
   game.map_settings.enemy_evolution.enabled = false
   game.difficulty_settings.technology_price_multiplier = 0.1
   game.difficulty_settings.research_queue_setting = "always"

   _layers.set_collision_mask({"water-tile"})

   for _, layer in pairs(preset) do
      _layers.add_noise_layer(layer.type, layer.name,
                              layer.objects, layer.elevation,
                              layer.resolution)
      if layer.hook ~= nil then
         _layers.add_noise_layer_hook(layer.name, layer.hook)
      end

      if layer.deps ~= nil then
         _layers.add_noise_layer_dependency(layer.name, layer.deps)
      end
   end

   _bp.push_blueprint("player_ship", global.this.bp.player_ship)
   _bp.set_blueprint_hook("player_ship", init_player_ship_bp)
   _bp.push_blueprint("merchant", global.this.bp.merchant)
   _bp.set_blueprint_hook("merchant", init_merchant_bp)
end

local function explode_ship(deps)
   local bp = deps.modules.bp
   local layers = deps.modules.layers
   for _, ent in pairs(bp.reference_get_entities(deps.ship)) do
      if not ent.valid then
         goto continue
      end

      local explosion = {
         name = "massive-explosion",
         position = ent.position
      }
      deps.surf.create_entity(explosion)

      ::continue::
   end

   local bb = bp.reference_get_bounding_box(deps.ship)
   layers.remove_excluding_bounding_box(bb)
   bp.destroy_reference(deps.surf, deps.ship)
   rendering.destroy(deps.id)
end

local function explode_ship_update(left, deps)
   local common = deps.modules.common
   for _, ent in pairs(deps.ship.entities) do
      if not ent.valid then
         return false
      end
   end

   rendering.set_text(deps.id, common.get_time(left))
   return true
end

local function do_spawn_point(player)
   local point = {
      x = _common.get_axis(player.position, "x"),
      y = _common.get_axis(player.position, "y") - 2
   }
   local instance = _bp.build(player.surface, "player_ship", point, player)
   _layers.push_excluding_bounding_box(instance.bb)

   local left = global.this._config.self_explode
   local object = {
      text = _common.get_time(left),
      surface = player.surface,
      color = {
         r = 255,
         g = 20,
         b = 20
      },
      target = {
         x = point.x - 2,
         y = point.y - 3,
      },
      scale = 2.0
   }

   local entry = {
      id = rendering.draw_text(object),
      ship = instance,
      modules = {
         bp = _bp,
         layers = _layers,
         common = _common,
         timers = _timers,
         func = _bp.destroy_reference,
      },
      surf = player.surface,
   }
   local timer = _timers.set_timer(left, explode_ship)
   _timers.set_timer_on_update(timer, explode_ship_update)
   _timers.set_timer_dependency(timer, entry)
   _timers.set_timer_start(timer)
end

local function get_non_obstructed_position(s, radius)
   local chunk

   for i = 1, 32 do
      chunk = s.get_random_chunk()
      chunk.x = chunk.x * 32
      chunk.y = chunk.y * 32

      local search_info = {
         position = chunk,
         radius = radius,
      }

      local tiles = s.find_tiles_filtered(search_info)
      for _, tile in pairs(tiles) do
         if string.find(tile.name, "water") ~= nil
         or string.find(tile.name, "out") ~= nil then
            goto continue
         end
      end

      search_info = {
         position = chunk,
         radius = radius,
         force = {"neutral", "enemy"},
         invert = true
      }
      local ents = s.find_entities_filtered(search_info)
      if not ents or #ents == 0 then
         break
      end

      ::continue::
   end

   return chunk
end

local function switchable_perk(caption, status)
   if status then
      return string.format("[color=0,80,0]%s[/color]", caption)
   end

   return string.format("[color=80,0,0]%s[/color]", caption)
end

local function draw_normal_gui(player)
   local button
   local merchant = global.this.events.merchant
   if merchant.alive then
      button = {
         type = "button",
         name = "merchant_find",
         caption = "Merchant",
      }
      player.gui.left.add(button)
   end

   button = {
      type = "button",
      name = "flashlight_toggle",
      caption = "Toggle flashlight"
   }
   player.gui.left.add(button)
end

local function draw_common_gui(player)
   local perks = global.this.perks[player.name]
   local chat_type = "Global chat"
   if not perks.chat_global then
      chat_type = "NAP chat"
   end

   local button = {
      type = "button",
      name = "manual_toggle",
      caption = "Manual"
   }
   player.gui.left.add(button)

   button = {
      type = "button",
      name = "chat_toggle",
      caption = chat_type,
   }
   player.gui.left.add(button)
end

local function draw_orbit_gui(player)
   local button = {
      type = "button",
      name = "annihilate",
      caption = "Annihilate"
   }
   player.gui.left.add(button)
end

local function redraw_gui(player)
   player.gui.left.clear()
   draw_common_gui(player)
   if player.spectator == true then
      draw_orbit_gui(player)
   else
      draw_normal_gui(player)
   end
end

local function print_merchant_position(player)
   local position = global.this.events.merchant.position
   local perks = global.this.perks[player.name]
   if not perks.minimap then
      player.print(string.format(">> You were able to spot him %s from your location",
                                 _common.get_readable_direction(player.position, position)))
   else
      player.print(string.format(">> You received a broadcast with [gps=%d,%d] coordinates", position.x, position.y))
   end
end

local function on_tick_reset()
   if global.this.events.reset_time == nil then
      return
   end

   if global.this.events.reset_time > game.tick then
      return
   end

   _server.start_scenario('planet_prison')
   global.this.events.reset_time = nil
end

local function annihilate(caller)
   global.this.events.annihilation = true
   for _, player in pairs(game.connected_players) do
      if player.name == caller.name then
         goto continue
      end

      local coeff
      for i = 1, 5 do
         if i % 2 == 0 then
            coeff = -1
         else
            coeff = 1
         end

         local query = {
            name = "atomic-rocket",
            position = {
               player.position.x - 100,
               player.position.y - 100,
            },
            target = {
               player.position.x + (8 * i * coeff),
               player.position.y + (8 * i * coeff),
            },
            speed = 0.1,
         }

         player.surface.create_entity(query)
         player.print(">> Annihilation in progress...")
      end
      ::continue::
   end

   global.this.events.reset_time = game.tick + (60 * 15)
end

local function on_gui_click(e)
   local elem = e.element
   local p = game.players[e.player_index]
   local perks = global.this.perks[p.name]

   if not elem.valid then
      return
   end

   if elem.name == "chat_toggle" then
      if perks.chat_global then
         elem.caption = "NAP chat"
         perks.chat_global = false
      else
         elem.caption = "Global chat"
         perks.chat_global = true
      end
   elseif elem.name == "flashlight_toggle" then
      if perks.flashlight_enable then
         perks.flashlight_enable = false
         p.character.disable_flashlight()
      else
         perks.flashlight_enable = true
         p.character.enable_flashlight()
      end
   elseif elem.name == "merchant_find" then
      print_merchant_position(p)
   elseif elem.name == "manual_toggle" then
      local children = p.gui.center.children
      if #children >= 1 then
         p.gui.center.clear()
         return
      end

      local text_box = {
         type = "text-box",
         text = global.this._config.manual
      }
      text_box = p.gui.center.add(text_box)
      text_box.style.minimal_width = 512
      text_box.read_only = true
      text_box.word_wrap = true
   elseif elem.name == "annihilate" then
      if global.this.events.annihilation == true then
         return
      end

      elem.destroy()
      annihilate(p)
   end
end

local function get_random_name()
   while true do
      local id = _common.rand_range(100, 999)
      local name = string.format("#%d", id)
      if global.this.perks[name] == nil then
         return name
      end
   end
end

local function init_player(p)
   p.teleport({0, 0}, "arena")
   local s = p.surface
   local position = get_non_obstructed_position(s, 10)

   global.this.perks[p.name] = nil
   p.teleport(position, "arena")
   p.name = get_random_name()
   p.force = game.create_force(p.name)
   p.force.set_friend("neutral", true)
   global.this.perks[p.name] = {
      flashlight_enable = true,
      minimap = false,
      chat_global = true,
   }

   local merch = find_force("merchant")
   if merch then
      p.force.set_friend(merch, true)
      merch.set_friend(p.force, true)
   end

   p.force.research_queue_enabled = true
   for _, tech in pairs(p.force.technologies) do
      for name, status in pairs(global.this._config.technologies) do
         if tech.name == name then
            tech.researched = status
            tech.enabled = status
         end
      end
   end

   p.minimap_enabled = false
   redraw_gui(p)
   do_spawn_point(p)
end

local function on_player_joined_game(e)
   local p = game.players[e.player_index]
   init_player(p)
end

local function _build_merchant_bp(surf, position)
   local instance = _bp.build(surf, "merchant", position, nil)
   _layers.push_excluding_bounding_box(instance.bb)
end

local function _remove_merchant_bp(surf)
   local refs = _bp.get_references("merchant")
   local bb = _bp.reference_get_bounding_box(refs[1])
   _layers.remove_excluding_bounding_box(bb)
   _bp.destroy_references(surf, "merchant")
   global.this.events.merchant.position = {
      x = 0,
      y = 0
   }
end

local function spawn_merchant(s)
   local merchant = global.this.events.merchant
   local position = get_non_obstructed_position(s, 10)
   local merch
   if not merchant.moving then
      merch = game.create_force("merchant")
   else
      merch = find_force("merchant")
   end

   merchant.position = position
   merchant.alive = true
   merchant.moving = false
   merchant.embark_tick = game.tick + 90000
   _build_merchant_bp(s, position)

   s.print(">> Merchant appeared in the area")
   for _, p in pairs(game.players) do
      p.force.set_friend(merch, true)
      merch.set_friend(p.force, true)
      print_merchant_position(p)
      redraw_gui(p)
   end
end

local function embark_merchant(s)
   global.this.events.merchant.alive = false
   global.this.events.merchant.moving = true
   global.this.events.merchant.spawn_tick = game.tick + 10000

   s.print(">> Merchant is moving to new location")
   _remove_merchant_bp(s)
   for _, player in pairs(game.players) do
      redraw_gui(player)
   end
end

local function merchant_event(s)
   local e = global.this.events
   local m = e.merchant
   if not m.alive and m.spawn_tick <= game.tick then
      spawn_merchant(s)
   end

   if m.alive and not m.moving and m.embark_tick <= game.tick then
      embark_merchant(s)
   end
end

local function _get_outer_points(surf, x, y, deps)
   local inner = deps.inner
   local points = deps.points

   local point = {
      x = x,
      y = y,
   }

   if _common.point_in_bounding_box(point, inner) then
      return
   end

   local tile = surf.get_tile(point)
   if string.find(tile.name, "water") ~= nil
   or string.find(tile.name, "out") ~= nil then
      return
   end

   table.insert(points, point)
end

local function _calculate_attack_costs(surf, bb)
   local query = {
      area = bb,
      force = {
         "enemy",
         "neutral",
         "player",
      },
      invert = true,
   }
   local objects = surf.find_entities_filtered(query)
   if next(objects) == nil then
      log("B")
      return 0
   end

   local cost = 0
   local costs = global.this._config.base_costs
   for _, obj in pairs(objects) do
      for name, coeff in pairs(costs) do
         if obj.name == name then
            cost = cost + coeff
         end
      end
   end

   return cost
end

local function _get_raid_info(surf, bb)
   local pick = nil
   local cost = _calculate_attack_costs(surf, bb)
   for _, entry in pairs(global.this._config.raid_costs) do
      if entry.cost <= cost then
         pick = entry
      else
         break
      end
   end

   return pick
end

local function _create_npc_group(claim, surf)
   local inner = _common.create_bounding_box_by_points(claim)
   local info = _get_raid_info(surf, inner)
   if info == nil then
      return {}
   end

   local outer = _common.deepcopy(inner)
   _common.enlarge_bounding_box(outer, 10)

   local points = {}
   local deps = {
      points = points,
      inner = inner,
   }
   _common.for_bounding_box_extra(surf, outer, _get_outer_points, deps)

   local agents = {}
   for i, point in ipairs(points) do
      if _common.rand_range(1, info.chance) ~= 1 then
         goto continue
      end

      local query = {
         name = "character",
         position = point
      }

      local agent = surf.create_entity(query)
      local stash = {}
      for attr, value in pairs(info.gear[(i % #info.gear) + 1]) do
         local prop = {
            name = value
         }

         if attr == "ammo" then
            prop.count = 20
         elseif attr == "weap" then
            prop.count = 1
         elseif attr == "armor" then
            prop.count = 1
         end

         table.insert(stash, prop)
      end

      for _, stack in pairs(stash) do
         agent.insert(stack)
      end

      global.this.assign_camouflage(agent, _common)

      table.insert(agents, agent)
      ::continue::
   end

   return agents
end

local function populate_raid_event(surf)
   local claims, group
   local status = false
   local groups = global.this.events.raid_groups

   for _, p in pairs(game.connected_players) do
      groups[p.name] = {}
      claims = _claims.get_claims(p.name)
      for _, claim in pairs(claims) do
         if #claim == 0 then
            goto continue
         end

         status = true
         group = {
            agents = _create_npc_group(claim, surf),
            objects = claim
         }
         table.insert(groups[p.name], group)

         ::continue::
      end
   end

   return status
end

local function raid_event(surf)
   local raid_groups = global.this.events.raid_groups
   if global.this.events.raid_init then
      if surf.daytime > 0.01 and surf.daytime <= 0.1 then
         for name, groups in pairs(raid_groups) do
            for i = #groups, 1, -1 do
               local group = groups[i]
               local agents = group.agents
               for j = #agents, 1, -1 do
                  local agent = agents[j]
                  if agent.valid then
                     agent.destroy()
                  end

                  table.remove(agents, j)
               end

               if #agents == 0 then
                  table.remove(group, i)
               end
            end

            if #groups == 0 then
               raid_groups[name] = nil
            end
         end

         global.this.events.raid_init = false
      end
   else
      if surf.daytime < 0.4 or surf.daytime > 0.6 then
         return
      end

      if populate_raid_event(surf) then
         global.this.events.raid_init = true
      end
   end

   if game.tick % 4 ~= 0 then
      return
   end

   for name, groups in pairs(raid_groups) do
      local exists = false
      for _, p in pairs(game.connected_players) do
         if p.name == name then
            exists = true
            break
         end
      end

      if not exists then
         raid_groups[name] = nil
         goto continue
      end

      for _, group in pairs(groups) do
         _ai.do_job(surf, _ai.command.attack_objects, group)
      end

      ::continue::
   end
end

local function cause_event(s)
   merchant_event(s)
   raid_event(s)
end

local function kill_player(p)
   p.character.die()
end

local function on_tick()
   local s = global.this.surface
   if not s then
      log("on_tick: surface empty!")
      return
   end

   local surf = global.this.surface
   if game.tick % 4 == 0 then
      _ai.do_job(surf, _ai.command.seek_and_destroy_player)
   end

   _layers.do_job(surf)
   cause_event(s)

   if (game.tick + 1) % 100 == 0 then
      _afk.on_inactive_players(90, kill_player)
   end

   if (game.tick + 1) % 60 == 0 then
      _timers.do_job()
   end
end

local function make_ore_patch(e)
   if _common.rand_range(1, 30) ~= 1 then
      return
   end

   local surf = e.surface
   local point = e.area.left_top
   _map.draw_entity_circle(point, "stone", surf, 6, true, 1000000)
   _map.draw_entity_circle(point, "coal", surf, 12, true, 1000000)
   _map.draw_entity_circle(point, "copper-ore", surf, 18, true, 1000000)
   _map.draw_entity_circle(point, "iron-ore", surf, 24, true, 1000000)
   _map.draw_noise_tile_circle(point, "water", surf, 4)
end

local function on_chunk_generated(e)
   if e.surface.name ~= "arena" then
      return
   end

   make_ore_patch(e)
   _layers.push_chunk(e.position)
end

local function mined_wreckage(e)
   if e.entity.name ~= "mineable-wreckage" then
      return
   end

   local candidates = {}
   local chance = _common.rand_range(0, 1000)
   for name, attrs in pairs(global.this._config.wreck_loot) do
      local prob = attrs.rare * 100
      if prob < chance then
         local cand = {
            name = name,
            count = _common.rand_range(attrs.count[1], attrs.count[2]),
         }
         table.insert(candidates, cand)
      end
   end

   local count = #candidates
   if count == 0 then
      return
   end

   local cand = candidates[_common.rand_range(1, count)]
   e.buffer.insert(cand)
end

local function on_player_mined_entity(e)
   local ent = e.entity
   if not ent.valid then
      return
   end

   mined_wreckage(e)
   _claims.on_player_mined_entity(ent)
end

local function on_player_died(e)
   local index = e.player_index
   if not index then
      return -- banned/kicked somewhere else
   end

   local p = game.players[index]
   _claims.on_player_died(p)
   game.merge_forces(p.name, "neutral")
end

local function on_player_respawned(e)
   local p = game.players[e.player_index]
   init_player(p)
end

local function on_player_dropped_item(e)
   if not global.this.last_friend then
      global.this.last_friend = {}
   end

   local p = game.players[e.player_index]
   local ent = e.entity
   if ent.stack.name == "raw-fish" then
      local ent_list = p.surface.find_entities_filtered({
         name = "character",
         position = ent.position,
         radius = 2,
      })
      if not ent_list then
         return
      end

      local peer = nil
      for _, char in pairs(ent_list) do
         if char.player and char.player.name ~= p.name then
            peer = char.player
            break
         end
      end

      if peer == nil then
         return
      end

      if p.force.get_cease_fire(peer.name) then
         p.print(string.format("You're in the NAP with %s already", peer.name))
         return
      end

      if global.this.last_friend[peer.name] == p.name then
         p.force.set_cease_fire(peer.name, true)
         peer.force.set_cease_fire(p.name, true)
         p.print(string.format("The NAP was formed with %s", peer.name))
         peer.print(string.format("The NAP was formed with %s", p.name))
         global.this.last_friend[p.name] = ""
         global.this.last_friend[peer.name] = ""
         return
      end

      global.this.last_friend[p.name] = peer.name
      p.print(string.format("You want to form the NAP with %s", peer.name))
      peer.print(string.format("The %s wants to form NAP with you", p.name))
   elseif ent.stack.name == "coal" then
      local ent_list = p.surface.find_entities_filtered({
         name = "character",
         position = ent.position,
         radius = 2,
      })
      if not ent_list then
         return
      end

      local peer = nil
      for _, char in pairs(ent_list) do
         if char.player and char.player.name ~= p.name then
            peer = char.player
            break
         end
      end

      if peer == nil then
         return
      end

      if not p.force.get_cease_fire(peer.name) then
         p.print(string.format("You don't have the NAP with %s", p.name))
         return
      end

      p.force.set_cease_fire(peer.name, false)
      peer.force.set_cease_fire(p.name, false)

      global.this.last_friend[p.name] = ""
      global.this.last_friend[peer.name] = ""
      p.print(string.format("You're no longer in the NAP with %s", peer.name))
      peer.print(string.format("You're no longer in the NAP with %s", p.name))
   end
end

local function on_chunk_charted(e)
   local f_perks = global.this.perks[e.force.name]

   if not f_perks then
      return
   end

   if not f_perks.minimap then
      e.force.clear_chart()
   end
end

local function on_entity_damaged(e)
   local ent = e.entity

   if ent.force.name == "merchant" then
      if not ent.force.get_friend(e.force) then
         return
      end

      ent.force.set_friend(e.force, false)
      e.force.set_friend(ent.force, false)
   end

   if ent.name == "character" then
      local hp = 1.0 - ent.get_health_ratio()
      local particles = 45 * hp
      local coeff = _common.rand_range(-20, 20) / 100.0
      for i = 1, particles do
         local blood = {
            name = "blood-particle",
            position = {
               x = ent.position.x,
               y = ent.position.y,
            },
            movement = {
               (_common.rand_range(-20, 20) / 100.0) + coeff,
               (_common.rand_range(-20, 20) / 100.0) + coeff,
            },
            frame_speed = 0.01,
            vertical_speed = 0.02,
            height = 0.01,
         }
         ent.surface.create_particle(blood)
      end
   end
end

local function merchant_death(e)
   local ent = e.entity
   if ent.force.name ~= "merchant" then
      return false
   end

   if ent.name ~= "character" and ent.name ~= "market" then
      return false
   end

   local s = ent.surface
   local explosion = {
      name = "massive-explosion",
      position = ent.position
   }
   s.create_entity(explosion)
   _remove_merchant_bp(s)

   global.this.events.merchant.alive = false
   global.this.events.merchant.moving = false
   global.this.events.merchant.spawn_tick = game.tick + 1000
   game.merge_forces("merchant", "neutral")

   s.print(">> Merchant died")
   for _, player in pairs(game.players) do
      redraw_gui(player)
   end

   return true
end

local function hostile_death(e)
   local ent = e.entity
   local loot = e.loot
   if ent.name ~= "character" then
      return false
   end

   if ent.player then
      loot.insert({name = "coin", count = 70})
   else
      loot.insert({name = "coin", count = 10})
   end

   return true
end

local function character_death(e)
   local ent = e.entity
   if ent.name ~= "character" then
      return false
   end

   local explosion = {
      name = "blood-explosion-big",
      position = ent.position,
   }
   ent.surface.create_entity(explosion)
end

local function on_entity_died(e)
   if not e.entity.valid then
      return
   end

   if merchant_death(e) then
      return
   end

   hostile_death(e)
   character_death(e)
   _claims.on_entity_died(e.entity)
end


local function merchant_exploit_check(ent)
   if ent.type ~= "electric-pole" then
      return
   end

   local refs = _bp.get_references("merchant")
   if not refs or #refs <= 0 then
      return
   end

   local bp_ent = _bp.reference_get_entities(refs[1])[1]
   local surf = bp_ent.surface

   local query = {
      type = "electric-pole",
      position = bp_ent.position,
      radius = 18
   }
   local ents = surf.find_entities_filtered(query)
   for _, s_ent in pairs(ents) do
      if s_ent.valid and s_ent.force.name ~= "merchant" then
         s_ent.die()
      end
   end
end

local function on_built_entity(e)
   local ent = e.created_entity
   if not ent or not ent.valid then
      return
   end

   _claims.on_built_entity(ent)
   merchant_exploit_check(ent)
end

local function on_market_item_purchased(e)
   local p = game.players[e.player_index]
   local m = e.market
   local o = m.get_market_items()[e.offer_index].offer
   local perks = global.this.perks[p.name]

   if o.effect_description == "Construct a GPS receiver" then
      perks.minimap = true
      p.minimap_enabled = true
   end
end

local function stringify_color(color)
   local r, g, b = color.r, color.g, color.b
   if r <= 1 then
      r = math.floor(r * 255)
   end

   if g <= 1 then
      g = math.floor(g * 255)
   end

   if b <= 1 then
      b = math.floor(b * 255)
   end

   return string.format("%d,%d,%d", r, g, b)
end

local function create_console_message(p, message)
   local prefix_fmt = "[color=%s]%s:[/color]"
   local msg_fmt = "[color=%s]%s[/color]"
   local color = stringify_color(p.chat_color)
   local prefix = string.format(prefix_fmt, color, p.name)
   local p_msg = string.format(msg_fmt, color, message)

   if global.this.perks[p.name].chat_global then
      msg_fmt = "[color=red]global:[/color] %s %s"
   else
      msg_fmt = "[color=green]nap:[/color] %s %s"
   end

   return string.format(msg_fmt, prefix, p_msg)
end

local function filter_out_gps(message)
   local msg = string.gsub(message, '%[gps=%-?%d+%,?%s*%-?%d+%]', '[gps]')
   return msg
end

local function on_console_chat(e)
   local pid = e.player_index

   if not pid then
      return
   end

   local p = game.players[pid]
   local msg = create_console_message(p, e.message)
   if global.this.perks[p.name].chat_global then
      for _, peer in pairs(game.players) do
         if peer.name ~= p.name  then
            local perks = global.this.perks[peer.name]
            if perks.minimap then
               peer.print(msg)
            else
               peer.print(filter_out_gps(msg))
            end
         end
      end
   else
      for _, f in pairs(game.forces) do
         if p.force.get_cease_fire(f) then
            local peer = f.players[1]
            if peer.name ~= p.name then
               local perks = global.this.perks[peer.name]
               if perks.minimap then
                  peer.print(msg)
               else
                  peer.print(filter_out_gps(msg))
               end
            end
         end
      end
   end
end

local function on_research_finished(e)
   local r = e.research
   if not r.valid then
      return
   end

   local reward = {
      name = "coin",
      count = math.ceil(r.research_unit_count * 3)
   }
   local f = r.force
   for _, player in pairs(f.players) do
      if player.can_insert(reward) then
         player.insert(reward)
      end
   end
end

local function move_to_orbit(player)
   local char = player.character
   player.character = nil
   char.destroy()

   game.merge_forces(player.name, "neutral")
   player.spectator = true
   redraw_gui(player)

   local orbit_perms = game.permissions.get_group("orbit")
   orbit_perms.add_player(player)
end

local function on_rocket_launched(e)
   local surf = global.this.surface
   local pid = e.player_index
   surf.print(">> The rocket was launched")
   if pid == nil then
      surf.print(">> Nobody escaped by it")
   else
      local player = game.players[pid]
      surf.print(string.format(">> The %s was able to escape", player.name))
      move_to_orbit(player)
   end
end

_evt.on_init(init_game)
_evt.add(defines.events.on_built_entity, on_built_entity)
_evt.add(defines.events.on_robot_built_entity, on_built_entity)
_evt.add(defines.events.on_research_finished, on_research_finished)
_evt.add(defines.events.on_player_joined_game, on_player_joined_game)
_evt.add(defines.events.on_chunk_generated, on_chunk_generated)
_evt.add(defines.events.on_player_mined_entity, on_player_mined_entity)
_evt.add(defines.events.on_player_died, on_player_died)
_evt.add(defines.events.on_player_kicked, on_player_died)
_evt.add(defines.events.on_player_banned, on_player_died)
_evt.add(defines.events.on_player_respawned, on_player_respawned)
_evt.add(defines.events.on_player_dropped_item, on_player_dropped_item)
_evt.add(defines.events.on_pre_player_left_game, on_player_died)
_evt.add(defines.events.on_entity_damaged, on_entity_damaged)
_evt.add(defines.events.on_entity_died, on_entity_died)
_evt.add(defines.events.on_market_item_purchased, on_market_item_purchased)
_evt.add(defines.events.on_chunk_charted, on_chunk_charted)
_evt.add(defines.events.on_console_chat, on_console_chat)
_evt.add(defines.events.on_gui_click, on_gui_click)
_evt.add(defines.events.on_tick, on_tick)
_evt.add(defines.events.on_tick, on_tick_reset)
_evt.add(defines.events.on_rocket_launched, on_rocket_launched)

_global.register_init({},
   function(tbl)
      tbl.this = global.this
   end,
   function(tbl)
      global.this = tbl.this
end)
