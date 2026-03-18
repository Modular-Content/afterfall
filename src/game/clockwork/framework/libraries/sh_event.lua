-- сделаем из бесполезного модуля что-то полезное, а то он там просто так лежит
local Clockwork = Clockwork
local type = type

Clockwork.event = Clockwork.kernel:NewLibrary("Event")
Clockwork.event.stored = Clockwork.event.stored or {}

--[[
	@codebase Shared
	@details A function to hook into an event.
	@param {Unknown} Missing description for eventClass.
	@param {Unknown} Missing description for eventName.
	@param {Unknown} Missing description for callback.
	@returns {Unknown}
--]]
function Clockwork.event:Hook(eventClass, callback)
	self.stored[eventClass] = callback
end

--[[
	@codebase Shared
	@details A function to get whether an event can run.
	@param {Unknown} Missing description for eventClass.
	@param {Unknown} Missing description for eventName.
	@returns {Unknown}
--]]
function Clockwork.event:CanRun(eventClass, ...)
	local event = self.stored[eventClass]
	return type(event) == 'function' and event(...) ~= false
end