--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local startTime = os.clock()

Clockwork.kernel:IncludePrefixed 'cl_schema.lua'
Clockwork.kernel:IncludePrefixed 'sh_hooks.lua'
Clockwork.kernel:IncludePrefixed 'cl_hooks.lua'
Clockwork.kernel:IncludePrefixed 'cl_theme.lua'
if SERVER then
	Clockwork.kernel:IncludePrefixed 'sv_schema.lua'
	Clockwork.kernel:IncludePrefixed 'sv_hooks.lua'
end

FACTION_CITIZEN = 'Гражданин'

team.SetUp(2, 'Oppositions', Color(255, 0, 0))
team.SetUp(3, 'Workers', Color(255, 255, 0))
team.SetUp(4, 'Biotics', Color(0, 255, 0))

local endTime = os.clock()
local loadTime = endTime - startTime
MsgC(Color(0, 255, 100, 255), string.format('[Afterfall] Schema loaded in %.3f seconds!\n', loadTime))