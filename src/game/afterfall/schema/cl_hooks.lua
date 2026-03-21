--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlKernel = ClockworkLite.kernel
local cwlConfig = ClockworkLite.config

function Schema:GetCinematicIntroInfo()
	local smallText = cwlConfig:Get('intro_text_small'):Get()
	if smallText:find '%%d' then smallText = smallText:format(os.date('%Y')) end
	return {credits = 'Разработчики сервера: Modular Content', title = cwlConfig:Get('intro_text_big'):Get(), text = smallText}
end

local scoreboardClasses = {
	[FACTION_CITIZEN] = 'Граждане',
}

function Schema:GetPlayerScoreboardClass(ply)
	local faction = ply:GetFaction()
	if not ply:IsAdmin() then return ply:HasInitialized() and scoreboardClasses[faction] end
	if not ply:HasInitialized() then return 'Connecting' end
	return scoreboardClasses[faction] or faction or 'Unknown'
end

function Schema:PlayerSetDefaultColorModify(cM)
	cM['$pp_colour_brightness'] = -.02
	cM['$pp_colour_contrast'] = 1.2
	cM['$pp_colour_colour'] = .5
end

function Schema:PlayerFootstep() return true end

function Schema:HUDPaintForeground()
	local scrW, scrH = ScrW(), ScrH()
	local ct = CurTime()
	local ply = ClockworkLite.Client
	if not IsValid(ply) then return end
	local isStunned = ply.stunned
	if ply:Alive() and isStunned then
		local timeLeft = ply.stunNow - ct
		if timeLeft <= 0 then ply.stunned, ply.stun, ply.stunNow = nil, nil, nil return end
		local progress = timeLeft / ply.stun
		local alpha = 100 * progress
    	surface.SetDrawColor(255, 255, 255, alpha) surface.DrawRect(0, 0, scrW, scrH)
	end
end