local public = {}
local _evt = require("utils.event")

--[[
on_inactive_players - Performs operation on inactive players from the game
if they exceed time.
@param time - Maximum time a player can be inactive.
@param func - Callback that will be called.
--]]
public.on_inactive_players = function(time, func)
   for _, p in pairs(game.connected_players) do
      local afk = p.afk_time / 60 / 60
      if afk >= time then
         func(p)
      end
   end
end

return public
