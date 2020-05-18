local public = {}
local _global = require('utils.global')

public.init = function()
   if global.this == nil then
      global.this = {}
   end

   global.this.timers = {}
end

--[[
set_timer - Sets a timer.
@param left - Time left on the timer in ticks.
@param hook - Action executed after timer is elapsed.
--]]
public.set_timer = function(left, hook)
   local id = game.tick
   local entry = {
      left = left,
      hook_finish = hook,
      hook_update = nil,
      deps = nil,
      running = false,
      last_update = 0,
   }

   global.this.timers[id] = entry
   return id
end

--[[
set_timer_on_update - Adds a hook that is executed everytime a
timers is updated.
@param id - Id of the timer.
@param hook - Hook that will be executed per update.
--]]
public.set_timer_on_update = function(id, hook)
   global.this.timers[id].hook_update = hook
end

--[[
set_timer_dependency - Adds dependency into user callback.
@param id - Id of the timer,
@param deps - Dependency of timer to add.
--]]
public.set_timer_dependency = function(id, deps)
   global.this.timers[id].deps = deps
end

--[[
set_timer_start - Sets the timer to run.
@param id - Id of a timer.
--]]
public.set_timer_start = function(id)
   global.this.timers[id].running = true
   global.this.timers[id].last_update = game.tick
end

--[[
kill_timer - Effectivly kills the timer.
@param id - Timer id.
--]]
public.kill_timer = function(id)
   global.this.timers[id] = nil
end

--[[
do_job - Execute timer logic within a tick.
--]]
public.do_job = function()
   for id, entry in pairs(global.this.timers) do
      if entry.running == false then
         goto continue
      end

      entry.left = entry.left - (game.tick - entry.last_update)
      if entry.left > 0 then
         entry.last_update = game.tick

         if entry.hook_update ~= nil then
            if not entry.hook_update(entry.left, entry.deps) then
               goto premature_finish
            end
         end

         goto continue
      end

      ::premature_finish::
      entry.hook_finish(entry.deps)
      global.this.timers[id] = nil

      ::continue::
   end
end

return public
