-- сука

--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
	это старый нетстрим к слову
--]]

---![(Shared)](https://github.com/user-attachments/assets/a356f942-57d7-4915-a8cc-559870a980fc) Netstream module.
---@class netstream
---@field stored table<string, function> @ ![(Shared)](https://github.com/user-attachments/assets/a356f942-57d7-4915-a8cc-559870a980fc) Stores the netstream hooks.
---@field cache table<string, any> @ ![(Shared)](https://github.com/user-attachments/assets/a356f942-57d7-4915-a8cc-559870a980fc) Stores the netstream cache.
---@field requestCallbacks table<string, function> @ ![(Shared)](https://github.com/user-attachments/assets/a356f942-57d7-4915-a8cc-559870a980fc) Stores the netstream request callbacks.
---@field requestTimeout number @ ![(Shared)](https://github.com/user-attachments/assets/a356f942-57d7-4915-a8cc-559870a980fc) The timeout for netstream requests.
---@field nextReqID number @ ![(Shared)](https://github.com/user-attachments/assets/a356f942-57d7-4915-a8cc-559870a980fc) The next request ID for netstream requests.
netstream = netstream or {}
netstream.stored, netstream.cache, netstream.requestCallbacks = netstream.stored or {}, netstream.cache or {}, netstream.requestCallbacks or {}
netstream.requestTimeout, netstream.nextReqID = netstream.requestTimeout or 15, netstream.nextReqID or 0

---![(Shared)](https://github.com/user-attachments/assets/a356f942-57d7-4915-a8cc-559870a980fc) Splits the data into chunks of a specified size.
---@param data string @ The data to split.
---@return table<string> @ A table containing the split chunks.
function netstream.Split(data)
    local chunks, size, i = {}, 32768, 1
    for j = 1, math.ceil(#data / size) do
        chunks[j] = data:sub(i, i + size - 1)
        i = i + size
    end
    return chunks
end

---![(Shared)](https://github.com/user-attachments/assets/a356f942-57d7-4915-a8cc-559870a980fc) Hooks a netstream event.
---@param name string @ The name of the netstream event to hook.
---@param callback fun(...)? @ The callback function to execute when the event is triggered.
function netstream.Hook(name, callback)
    netstream.stored[name] = callback
end

---![(Shared)](https://github.com/user-attachments/assets/a356f942-57d7-4915-a8cc-559870a980fc) Listens for a netstream request.
---@param name string @ The name of the request to listen for.
---@param callback fun(...)? @ The callback function to execute when the request is received.
function netstream.Listen(name, callback)
    netstream.requestCallbacks[name] = callback
end

function createQueue(worker)
	local q = {worker = worker, tasks = {}, running = false}
	function q:Add(task)
		table.insert(self.tasks, task)
		self:Run()
	end
	function q:Run()
		if self.running or #self.tasks == 0 then return end
		self.running = true
		local task = table.remove(self.tasks, 1)
		self.worker(task, function()
			self.running = false
			self:Run()
		end)
	end
	return q
end

if SERVER then
	util.AddNetworkString('NetStreamDS')
	util.AddNetworkString('NetStreamHeavy')

	local function encodeData(...)
	    local ok, data = pcall(pon.encode, {...})
	    if not ok then
	        ErrorNoHalt('NetStream Encode Failed: '..tostring(data)..'\n')
	        return nil
	    end
	    return data
	end

	local function getRecipients(ply)
	    return not ply and player.GetAll() or (istable(ply) and ply or {ply})
	end

	netstream.HeavyQueue = createQueue(function(data, done)
	    local len = #data[2]
	    net.Start('NetStreamHeavy')
	        net.WriteString(data[1])
	        net.WriteUInt(len, 32)
	        net.WriteData(data[2], len)
	        net.WriteUInt(data[3], 8)
	        net.WriteUInt(data[4], 8)
	    net.Send(getRecipients(data[5]))
	    timer.Simple(0.25 * len / 32768, done)
	end)

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Start a network stream to the specified player(s).
	---@param ply Player|table<Player>? @ The player or players to send the data to.
	---@param name string @ The name of the network message.
	---@param ... any @ The data to send.
	function netstream.Start(ply, name, ...)
	    local recipients = getRecipients(ply)
	    local data = encodeData(...)
	    if not data then return end
	    net.Start('NetStreamDS')
	        net.WriteString(name)
	        net.WriteUInt(#data, 32)
	        net.WriteData(data, #data)
	    net.Send(recipients)
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Start a network stream to all players in the PVS of a specified position.
	---@param pos Vector @ The position to determine the PVS.
	---@param name string @ The name of the network message.
	---@param ... any @ The data to send.
	function netstream.StartPVS(pos, name, ...)
	    local rf = RecipientFilter()
	    rf:AddPVS(pos)
	    netstream.Start(rf:GetPlayers(), name, ...)
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Send a heavy network stream to the specified player(s).
	---@param ply Player|table<Player>? @ The player or players to send the data to.
	---@param name string @ The name of the network message.
	---@param ... any @ The data to send.
	function netstream.Heavy(ply, name, ...)
	    local recipients = getRecipients(ply)
	    local data = encodeData(...)
	    if not data then return end
	    local parts = netstream.Split(data)
	    if data and #data > 0 then
	        if #parts == 1 then
	            netstream.Start(recipients, name, ...)
	            return
	        end
	        for i = 1, #parts do netstream.HeavyQueue:Add({name, parts[i], i, #parts, recipients}) end
	    end
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Request data from the server.
	---@param ply Player @ The player making the request.
	---@param name string @ The name of the request.
	---@param ... any @ The arguments to send with the request.
	---@return Promise @ A promise that resolves with the response data.
	function netstream.Request(ply, name, ...)
	    local args = {...}
	    return util.Promise(function(res, rej)
	        local reqID = netstream.nextReqID
	        netstream.nextReqID = reqID + 1
	        local msgName = 'nsr-'..reqID
	        netstream.Hook(msgName, function(_, data)
	            netstream.Hook(msgName, nil)
	            res(data)
	        end)
	        netstream.Start(ply, 'nsr', name, reqID, unpack(args))
	        timer.Create(msgName, netstream.requestTimeout, 1, function()
	            rej('timeout')
	            timer.Remove(msgName)
	        end)
	    end)
	end

	---![(Server)](https://github.com/user-attachments/assets/d8fbe13a-6305-4e16-8698-5be874721ca1) Handle incoming network messages.
	---@param ply Player @ The player who sent the message.
	---@param name string @ The name of the network message.
	---@param data string @ The data received in the message.
	local function handleIncoming(ply, name, data)
	    local cb = netstream.stored[name]
	    if not cb then return end
	    local ok, decoded = pcall(pon.decode, data)
	    if not ok then
	        ErrorNoHalt('NetStream Failed Decode: '..name..'\n'..tostring(decoded)..'\n')
	        return
	    end
	    ---@cast decoded table
	    cb(ply, unpack(decoded))
	end

	net.Receive('NetStreamDS', function(_, ply)
	    local name = net.ReadString()
	    local len = net.ReadUInt(32)
	    local data = net.ReadData(len)
	    handleIncoming(ply, name, data)
	end)

	net.Receive('NetStreamHeavy', function(_, ply)
	    local name = net.ReadString()
	    local len = net.ReadUInt(32)
	    local data = net.ReadData(len)
	    local part, total = net.ReadUInt(8), net.ReadUInt(8)

	    if not netstream.cache[ply] then netstream.cache[ply] = {} end
	    if part == 1 then netstream.cache[ply][name] = '' end

	    netstream.cache[ply][name] = netstream.cache[ply][name] .. data

	    if part == total then
	        handleIncoming(ply, name, netstream.cache[ply][name])
	        netstream.cache[ply][name] = nil
	    end
	end)

	netstream.Hook('nsr', function(ply, name, reqID, ...)
	    local cb = netstream.requestCallbacks[name]
	    if not cb then return end
	    local r = function(...) netstream.Start(ply, 'nsr-'..reqID, ...) end
	    cb(r, ply, ...)
	end)
else
	local function encodeData(...)
	    local ok, data = pcall(pon.encode, {...})
	    if not ok then
	        ErrorNoHalt('NetStream Encode Failed: '..tostring(data)..'\n')
	        return nil
	    end
	    return data
	end

	netstream.HeavyQueue = createQueue(function(data, done)
	    local len = #data[2]
	    net.Start('NetStreamHeavy')
	        net.WriteString(data[1])
	        net.WriteUInt(len, 32)
	        net.WriteData(data[2], len)
	        net.WriteUInt(data[3], 8)
	        net.WriteUInt(data[4], 8)
	    net.SendToServer()
	    timer.Simple(0.25 * len / 32768, done)
	end)

	---![(Client)](https://github.com/user-attachments/assets/a5f6ba64-374d-42f0-b2f4-50e5c964e808) Start a network stream to server.
	---@param name string @ The name of the network message.
	---@param ... any @ The data to send.
	function netstream.Start(name, ...)
	    local data = encodeData(...)
	    if not data then return end
	    net.Start('NetStreamDS')
	        net.WriteString(name)
	        net.WriteUInt(#data, 32)
	        net.WriteData(data, #data)
	    net.SendToServer()
	end

	---![(Client)](https://github.com/user-attachments/assets/a5f6ba64-374d-42f0-b2f4-50e5c964e808) Start a heavy network stream to server.
	---@param name string @ The name of the network message.
	---@param ... any @ The data to send.
	function netstream.Heavy(name, ...)
	    local data = encodeData(...)
	    if not data then return end
	    local parts = netstream.Split(data)
	    if data and #data > 0 then
	        if #parts == 1 then
	            netstream.Start(name, ...)
	            return
	        end
	        for i = 1, #parts do netstream.HeavyQueue:Add({name, parts[i], i, #parts}) end
	    end
	end

	---![(Client)](https://github.com/user-attachments/assets/a5f6ba64-374d-42f0-b2f4-50e5c964e808) Request data from the server.
	---@param name string @ The name of the request.
	---@param ... any @ The arguments to send with the request.
	---@return Promise @ A promise that resolves with the response data.
	function netstream.Request(name, ...)
	    local args = {...}
	    return util.Promise(function(res, rej)
	        local reqID = netstream.nextReqID
	        netstream.nextReqID = reqID + 1
	        local msgName = 'nsr-'..reqID
	        netstream.Hook(msgName, function(...)
	            netstream.Hook(msgName, nil)
	            res(...)
	        end)
	        netstream.Start('nsr', name, reqID, unpack(args))
	        timer.Create(msgName, netstream.requestTimeout, 1, function()
	            rej('timeout')
	            netstream.Hook(msgName, nil)
	            timer.Remove(msgName)
	        end)
	    end)
	end

	---![(Client)](https://github.com/user-attachments/assets/a5f6ba64-374d-42f0-b2f4-50e5c964e808) Handle incoming network messages from the server.
	---@param name string @ The name of the network message.
	---@param data string @ The data received in the message.
	local function handleClientReceive(name, data)
	    local cb = netstream.stored[name]
	    if not cb then return end
	    local ok, decoded = pcall(pon.decode, data)
	    if not ok then
	        ErrorNoHalt('NetStream Client Decode Error: '..name..'\n'..tostring(decoded)..'\n')
	        return
	    end
	    ---@cast decoded table
	    cb(unpack(decoded))
	end

	net.Receive('NetStreamDS', function()
	    handleClientReceive(net.ReadString(), net.ReadData(net.ReadUInt(32)))
	end)

	net.Receive('NetStreamHeavy', function()
	    local name = net.ReadString()
	    local len = net.ReadUInt(32)
	    local data = net.ReadData(len)
	    local part, total = net.ReadUInt(8), net.ReadUInt(8)

	    if not netstream.cache[name] then netstream.cache[name] = '' end
	    netstream.cache[name] = netstream.cache[name] .. data

	    if part == total then
	        handleClientReceive(name, netstream.cache[name])
	        netstream.cache[name] = nil
	    end
	end)

	netstream.Hook('nsr', function(name, reqID, ...)
	    local cb = netstream.requestCallbacks[name]
	    if not cb then return end
	    local r = function(...) netstream.Start('nsr-'..reqID, ...) end
	    cb(r, ...)
	end)
end

Clockwork.datastream = Clockwork.datastream or {} -- BACK COMPATIBILITY, old code is bad...

function Clockwork.datastream:Hook(name, callback)
	netstream.Hook(name, callback)
end

function Clockwork.datastream:Listen(name, callback)
	netstream.Listen(name, callback)
end

if SERVER then
	function Clockwork.datastream:Start(ply, name, ...)
		netstream.Start(ply, name, ...)
	end

	function Clockwork.datastream:StartPVS(pos, name, ...)
		netstream.StartPVS(pos, name, ...)
	end

	function Clockwork.datastream:Heavy(ply, name, ...)
		netstream.Heavy(ply, name, ...)
	end

	function Clockwork.datastream:Request(ply, name, ...)
		return netstream.Request(ply, name, ...)
	end
else
	function Clockwork.datastream:Start(name, ...)
		netstream.Start(name, ...)
	end

	function Clockwork.datastream:Heavy(name, ...)
		netstream.Heavy(name, ...)
	end

	function Clockwork.datastream:Request(name, ...)
		return netstream.Request(name, ...)
	end
end