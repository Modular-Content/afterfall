--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

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