--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlKernel = ClockworkLite.kernel
local cwlConfig = ClockworkLite.config
local cwlQuiz = ClockworkLite.quiz

FACTION_MPF = 'Гражданская Оборона'
FACTION_OTA = 'Сверхчеловеческий Отдел'
FACTION_CREMATOR = 'Крематор'
FACTION_CITIZEN = 'Гражданин'
FACTION_INCOG = 'Секретный агент'

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

team.SetUp(2, 'Oppositions', Color(255, 0, 0))
team.SetUp(3, 'Workers', Color(255, 255, 0))
team.SetUp(4, 'Biotics', Color(0, 255, 0))

function Schema:IsStringCombineRank(str, rank)
    if not istable(rank) then return string.find(str, '%p' .. rank .. '%p') ~= nil end
	for i = 1, #rank do local v = rank[i] if self:IsStringCombineRank(str, v) then return true end end
    return false
end

function Schema:IsPlayerCombineRank(ply, r)
    if not IsValid(ply) then return end
    local name, faction = ply:Name(), ply:GetFaction()
    if not self:IsCombineFaction(faction) then return end
	return self:IsStringCombineRank(name, r)
end

CFG.combineRanks = {
    default = 6,
    ota = {
		['OWS'] = 0,
		['EOW'] = 2,
		default = 1,
	},
    mpf = {
        ['RCT'] = 0,
        ['05'] = 1,
        ['04'] = 2,
        ['03'] = 3,
        ['02'] = 4,
        ['01'] = 5,
        ['OfC'] = 7,
        ['EpU'] = 8,
        ['CmR'] = 9,
        ['DvL'] = 10,
        ['SeC'] = 11,
    },
    scanners = {
		['SCN'] = 12,
		['SYNTH'] = 13,
	}
}

function Schema:GetPlayerCombineRank(ply)
    if not IsValid(ply) then return end
	if not ply:IsCombine() then return end
    local faction = ply:GetFaction()
    local ranks = CFG.combineRanks
    if faction == FACTION_OTA then
        for key, value in next, ranks.ota do if self:IsPlayerCombineRank(ply, key) then return value end end
        return ranks.ota.default or ranks.default
	end
    for k, v in next, ranks.scanners do if self:IsPlayerCombineRank(ply, k) then return v end end
    for k, v in next, ranks.mpf do if self:IsPlayerCombineRank(ply, k) then return v end end
    return ranks.default
end

local combineFactions = {
	[FACTION_MPF] = true,
	[FACTION_OTA] = true,
	[FACTION_CREMATOR] = true,
	[FACTION_INCOG] = true,
}

function Schema:IsCombineFaction(faction)
	return combineFactions[faction] or false
end

---@class Player
local playerMeta = FindMetaTable 'Player'

function playerMeta:IsCombine()
	return Schema:PlayerIsCombine(self)
end

-- УСТАНОВИТЕ СВОИ ЗНАЧЕНИЯ
CFG.mpfMask = 2
CFG.mpfWhitelistMdls = {['models/police.mdl'] = true}
CFG.citizenMask = 4
CFG.citizenMaskTarget = {[2] = true}
CFG.hazmatSuits = {}

function playerMeta:IsMasked()
	local mdl = self:GetModel()
	local mSt, cSt = self:GetBodygroup(CFG.mpfMask), self:GetBodygroup(CFG.citizenMask)
	if self:IsCombine() then
		if Schema:IsPlayerCombineRank(self, 'SCN') then return true end
		local faction = self:GetFaction()
		if faction == FACTION_MPF then return CFG.mpfWhitelistMdls[mdl] or mSt ~= 0 end
		return true
	end
	if CFG.hazmatSuits[mdl] then return true end
    if CFG.citizenMaskTarget[cSt] then return true end
	return false
end