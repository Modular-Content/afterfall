--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlKernel = ClockworkLite.kernel
local cwlConfig = ClockworkLite.config
local cwlQuiz = ClockworkLite.quiz

cwlKernel:IncludePrefixed 'cl_schema.lua'
cwlKernel:IncludePrefixed 'sh_hooks.lua'
cwlKernel:IncludePrefixed 'cl_hooks.lua'
cwlKernel:IncludePrefixed 'cl_theme.lua'
if SERVER then
	cwlKernel:IncludePrefixed 'sv_schema.lua'
	cwlKernel:IncludePrefixed 'sv_hooks.lua'
end

cwlConfig:ShareKey 'intro_text_small'
cwlConfig:ShareKey 'intro_text_big'

cwlQuiz:SetEnabled(true)
cwlQuiz:AddQuestion('выметайтесь вон', 1, 'uwu')

FACTION_CITIZEN = 'Гражданин'

team.SetUp(2, 'Oppositions', Color(255, 0, 0))
team.SetUp(3, 'Workers', Color(255, 255, 0))
team.SetUp(4, 'Biotics', Color(0, 255, 0))