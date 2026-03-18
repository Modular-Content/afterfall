-- шапокляк
-- и никаких клауднетов не надо, я сам все сделаю, я же крутой и молодец, а ты там просто сиди и не мешай

--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
	это старый нетварс кстати
--]]

if SERVER then
	---@class netvars
	netvars = netvars or {}

	---@class Entity
	local entityMeta = FindMetaTable 'Entity'
	---@class Player : Entity
	local playerMeta = FindMetaTable 'Player'

	local stored = netvars.stored or {}
	local locals = netvars.locals or {}
	local globals = netvars.globals or {}
	local registered = netvars.registered or {}

	netvars.stored = stored
	netvars.locals = locals
	netvars.globals = globals
	netvars.registered = registered

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Registers a networked variable.
	---@param key string @ The variable name.
	---@param data? table @ Optional data table with `checkAccess` function.
	function netvars.Register(key, data)
	    if data == nil or type(data) == 'table' then registered[key] = data end
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Gets the list of players who can receive updates for a specific variable.
	---@param key string @ The variable name.
	---@param receivers? Player|Player[] @ Optional list of players to filter.
	---@return Player[] @ The list of players who can receive updates.
	function netvars.GetReceivers(key, receivers)
	    local reg = registered[key]
	    if not (reg and reg.checkAccess) then
	        return receivers or player.GetAll()
	    end
	    receivers = receivers or player.GetAll()
	    if type(receivers) ~= 'table' then receivers = { receivers } end
	    local result = {}
	    for i = 1, #receivers do
	        local ply = receivers[i]
	        if reg.checkAccess(ply) then
	            result[#result + 1] = ply
	        end
	    end
	    return result
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Checks if a player has access to a specific variable.
	---@param ply Player @ The player to check.
	---@param key string @ The variable name.
	---@return boolean @ Whether the player has access.
	function netvars.HasAccess(ply, key)
	    return not (registered[key] and isfunction(registered[key].checkAccess)) or registered[key].checkAccess(ply)
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Sets a global variable.
	---@param key string @ The variable name.
	---@param value any @ The variable value.
	---@param receiver? Player|Player[] @ Optional list of players to send the update to.
	function netvars.SetNetVar(key, value, receiver)
	    if type(value) == 'function' or (globals[key] == value) then return end
	    globals[key] = value
	    netstream.Start(netvars.GetReceivers(key, receiver), 'gVar', key, value)
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Updates networked variables for a player.
	function playerMeta:UpdateNetVars()
	    local storedToSend, globalsToSend = {}, {}
	    for k, v in next, registered do
	        local hasAccess = v.checkAccess and v.checkAccess(self)
	        if globals[k] ~= nil and hasAccess then
	            globalsToSend[k] = globals[k]
	        end
	        for idx, vars in next, stored do
	            if vars[k] ~= nil then
	                storedToSend[idx] = storedToSend[idx] or {}
	                if hasAccess then
	                    storedToSend[idx][k] = vars[k]
	                end
	            end
	        end
	    end
	    netstream.Heavy(self, 'nUpd', table.GetKeys(registered), storedToSend, globalsToSend)
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Sends a networked variable update for an entity.
	---@param key string @ The variable name.
	---@param receiver? Player|Player[] @ Optional list of players to send the update to.
	function entityMeta:SendNetVar(key, receiver)
	    local idx = self:EntIndex()
	    local data = stored[idx] and stored[idx][key]
	    netstream.Start(netvars.GetReceivers(key, receiver), 'nVar', idx, key, data)
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Clears all networked variables for an entity.
	---@param receiver? Player|Player[] @ Optional list of players to send the update to.
	function entityMeta:ClearNetVars(receiver)
	    local idx = self:EntIndex()
	    stored[idx] = nil
	    locals[idx] = nil
	    netstream.Start(receiver, 'nDel', idx)
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Sets a networked variable for an entity.
	---@param key string @ The variable name.
	---@param value any @ The variable value.
	---@param receiver? Player|Player[] @ Optional list of players to send the update to.
	function entityMeta:SetNetVar(key, value, receiver)
	    if type(value) == 'function' or (value == self:GetNetVar(key)) then return end
	    local idx = self:EntIndex()
	    stored[idx] = stored[idx] or {}
	    stored[idx][key] = value
	    self:SendNetVar(key, receiver)
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Gets a networked variable for an entity.
	---@param key string @ The variable name.
	---@param default any @ The default value if the variable is not set.
	---@return any @ The variable value.
	function entityMeta:GetNetVar(key, default)
	    local idx = self:EntIndex()
	    local val = (locals[idx] and locals[idx][key]) or (stored[idx] and stored[idx][key])
	    return val ~= nil and val or default
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Sets a local variable for a player.
	---@param key string @ The variable name.
	---@param value any @ The variable value.
	function playerMeta:SetLocalVar(key, value)
	    if type(value) == 'function' or (value == self:GetNetVar(key)) then return end
	    local idx = self:EntIndex()
	    locals[idx] = locals[idx] or {}
	    locals[idx][key] = value
	    netstream.Start(self, 'nLcl', key, value)
	end

	playerMeta.GetLocalVar = entityMeta.GetNetVar

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Gets a global variable.
	---@param key string @ The variable name.
	---@param default any @ The default value if the variable is not set.
	---@return any @ The variable value.
	function netvars.GetNetVar(key, default)
	    return globals[key] ~= nil and globals[key] or default
	end

	hook.Add('EntityRemoved', 'nCleanUp', function(ent)
	    ent:ClearNetVars()
	end)

	hook.Add('PlayerFinishedLoading', 'nSync', function(ply)
	    timer.Simple(10, function()
	        if not IsValid(ply) then return end
	        local storedToSend = {}
	        for idx, vars in next, stored do
	            storedToSend[idx] = {}
	            local empty = true
	            for key, value in next, vars do
	                if netvars.HasAccess(ply, key) then
	                    storedToSend[idx][key], empty = value, false
	                end
	            end
	            if empty then storedToSend[idx] = nil end
	        end
	        local globalsToSend = {}
	        for key, value in next, globals do
	            if netvars.HasAccess(ply, key) then
	                globalsToSend[key] = value
	            end
	        end
	        netstream.Heavy(ply, 'netvars_full', storedToSend, globalsToSend)
	    end)
	end)

	hook.Add('mw.updateNetVars', 'nUpd', playerMeta.UpdateNetVars)
else
	---@class netvars
	netvars = netvars or {}

	---@class Entity
	local entityMeta = FindMetaTable 'Entity'
	---@class Player
	local playerMeta = FindMetaTable 'Player'

	local stored = {}
	local globals = {}

	netstream.Hook('nVar', function(index, key, value)
	    local data = stored[index] or {}
	    data[key] = value
	    stored[index] = data
	    hook.Run('mw.netVarUpdate', index, key, value)
	end)

	netstream.Hook('nDel', function(index)
	    local data = stored[index]
	    if data then
	        for k in next, data do
	            hook.Run('mw.netVarUpdate', index, k)
	        end
	        stored[index] = nil
	    end
	end)

	netstream.Hook('nLcl', function(key, value)
	    if not IsValid(LocalPlayer()) then return end
	    local idx = LocalPlayer():EntIndex()
	    local data = stored[idx] or {}
	    data[key] = value
	    stored[idx] = data
	    hook.Run('mw.netVarUpdate', idx, key, value)
	end)

	netstream.Hook('gVar', function(key, value)
	    globals[key] = value
	    hook.Run('mw.netVarUpdate', nil, key, value)
	end)

	netstream.Hook('netvars_full', function(theirStored, theirGlobals)
	    for index, data in next, theirStored do
	        local current = stored[index] or {}
	        for key, value in next, data do
	            current[key] = value
	            hook.Run('mw.netVarUpdate', index, key, value)
	        end
	        stored[index] = current
	    end

	    theirGlobals = istable(theirGlobals) and theirGlobals or {}
	    for key, value in next, theirGlobals do
	        globals[key] = value
	        hook.Run('mw.netVarUpdate', nil, key, value)
	    end
	end)

	netstream.Hook('nUpd', function(keys, updStored, updGlobals)
	    for _, key in ipairs(keys) do
	        for index, data in next, updStored do
	            local current = stored[index] or {}
	            current[key] = data[key]
	            stored[index] = current
	        end
	        globals[key] = updGlobals[key]
	    end
	end)

	---![(Client)](https://github.com/user-attachments/assets/a5f6ba64-374d-42f0-b2f4-50e5c964e808) Gets a global variable.
	---@param key string @ The variable name.
	---@param default any @ The default value if the variable is not set.
	---@return any @ The variable value.
	function netvars.GetNetVar(key, default)
	    return globals[key] ~= nil and globals[key] or default
	end

	---![(Client)](https://github.com/user-attachments/assets/a5f6ba64-374d-42f0-b2f4-50e5c964e808) Gets a networked variable for an entity.
	---@param key string @ The variable name.
	---@param default any @ The default value if the variable is not set.
	---@return any @ The variable value.
	function entityMeta:GetNetVar(key, default)
	    local data = stored[self:EntIndex()]
	    return data and data[key] ~= nil and data[key] or default
	end

	---![(Client)](https://github.com/user-attachments/assets/a5f6ba64-374d-42f0-b2f4-50e5c964e808) Sets a networked variable for an entity (stub function).
	---@param key string @ The variable name.
	---@param default any @ The default value if the variable is not set.
	function entityMeta:SetNetVar(key, default)
		-- ого тут до сих пор это пометка, пиздец
		-- нахуя клиенту сеттер, че за бред хаахаха, я пойду выпью какого нить коньяка, а ты тут подумай над смыслом жизни
	end

	playerMeta.GetNetVar = entityMeta.GetNetVar
	playerMeta.GetLocalVar = entityMeta.GetNetVar
end

Clockwork.kernel = Clockwork.kernel or {}
if SERVER then
	function Clockwork.kernel:SetSharedVar(key, value, receiver)
		netvars.SetNetVar(key, value, receiver)
	end
	function Clockwork.kernel:SetNetVar(key, value, receiver)
		netvars.SetNetVar(key, value, receiver)
	end
end
function Clockwork.kernel:GetSharedVar(key, default)
	return netvars.GetNetVar(key, default)
end
function Clockwork.kernel:GetNetVar(key, default)
	return netvars.GetNetVar(key, default)
end
---@class Entity
local entityMeta = FindMetaTable 'Entity'
function entityMeta:GetSharedVar(key, default)
	return self:GetNetVar(key, default)
end
function entityMeta:SetSharedVar(key, value, receiver) -- ебанный клокворк ставит шаред варс на клиенте, поэтому ну пусть это будет здесь, фак ю
	self:SetNetVar(key, value, receiver)
end