-- разумным решением было бы использовать helix, а не Clockwork
-- но мне похуй owo

-- include("external/utf8.lua");
-- include("external/pon.lua");
-- include("external/promise.lua");
-- include("external/csoundpatch_ext.lua");

-- include("clockwork_shared.lua")
-- include("clockwork/framework/cl_kernel.lua")

-- КЛОКВОРКЛАЙТ СТАРЫЕ ЗАПИСИ
-- аудирование в хуй
local sT,mC,r=os.clock(),Color(0,255,100),ClockworkLite and true
MsgC(mC, r and '[ClockworkLite] Change detected! Refreshing...\n' or '[ClockworkLite] Framework is initializing...\n')
---@class ClockworkLite : Clockwork
ClockworkLite = r and table.Merge(ClockworkLite, GM) or GM
---@class Clockwork : GM
Clockwork = r and table.Merge(Clockwork or {}, ClockworkLite) or ClockworkLite
include 'sh_preload.lua'
local loadExternals = function()
	local files = file.Find('clockwork/gamemode/external/*.lua', 'LUA')
	local order = {'utf8', 'pon', 'promise', 'csoundpatch_ext'}
	for i = 1, #order do
		for j = 1, #files do
			local v = files[j]
			if string.find(v, order[i], 1, true) then
				include('clockwork/gamemode/external/' .. v)
				AddCSLuaFile('clockwork/gamemode/external/' .. v)
			end
		end
	end
end
loadExternals()
include 'clockwork_shared.lua'
include 'clockwork/framework/cl_kernel.lua'
local t = math.Round(os.clock()-sT,3)
if r then ClockworkLite:Initialize() end
MsgC(mC, r and 'AutoRefresh handled in ' .. t .. ' second(s)\n' or 'Framework loading took ' .. t .. ' second(s)\n')
table.Merge(GM,ClockworkLite)