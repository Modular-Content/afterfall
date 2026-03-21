
-- local startTime = os.clock()


-- cwReloading = false
-- cwReloaded = false

-- if Clockwork and Clockwork.kernel then
-- 	MsgC(Color(0, 255, 100, 255), "[Clockwork] Change has been detected! Auto-refreshing...\n")
-- 	cwReloading =  true
-- else
-- 	MsgC(Color(0, 255, 100, 255), "[Clockwork] The framework is initializing...\n")
-- 	require("cwutil")
-- end

-- AddCSLuaFile("external/utf8.lua");
-- AddCSLuaFile("cl_init.lua");
-- AddCSLuaFile("external/pon.lua");
-- AddCSLuaFile("external/promise.lua");
-- AddCSLuaFile("external/csoundpatch_ext.lua");

-- include("external/utf8.lua");
-- include("external/pon.lua");
-- include("external/promise.lua");
-- include("external/csoundpatch_ext.lua");
-- include("clockwork/framework/sv_cax_patch.lua")
-- include("clockwork/framework/sv_kernel.lua");

-- if Clockwork and cwBootComplete then
-- 	Clockwork:Initialize()
-- 	MsgC(Color(0, 255, 100, 255), "[Clockwork] Auto-refresh handled server-side in " .. math.Round(os.clock() - startTime, 3) .. " second(s)!\n")
-- else
-- 	MsgC(Color(0, 255, 100, 255), "[Clockwork] Successfully loaded Clockwork version " .. Clockwork.kernel:GetVersionBuild() .. " in " .. math.Round(os.clock() - startTime, 3) .. " second(s).\n")
-- end

-- cwBootComplete = true
-- if cwReloading then cwReloaded = true end

-- КЛОКВОРКЛАЙТ СТАРЫЕ ЗАПИСИ
-- аудирование в хуй
local sT,mC,r=os.clock(),Color(0,255,100),ClockworkLite and true
MsgC(mC, r and '[ClockworkLite] Change detected! Refreshing...\n' or '[ClockworkLite] Framework is initializing...\n')
if not r then require 'cwutil' end
---@class ClockworkLite : Clockwork
ClockworkLite = r and table.Merge(ClockworkLite, GM) or GM
---@class Clockwork : GM
Clockwork = r and table.Merge(Clockwork or {}, ClockworkLite) or ClockworkLite
AddCSLuaFile 'cl_preload.lua'
AddCSLuaFile 'sh_preload.lua'
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
AddCSLuaFile 'cl_init.lua'
loadExternals()
include 'clockwork/framework/sv_cax_patch.lua'
include 'clockwork/framework/sv_kernel.lua'
local t = math.Round(os.clock()-sT,3)
if r then ClockworkLite:Initialize() end
MsgC(mC, r and '[ClockworkLite] AutoRefresh handled in ' .. t .. ' second(s)\n' or '[ClockworkLite] Framework loading took ' .. t .. ' second(s)\n')
table.Merge(GM,ClockworkLite)