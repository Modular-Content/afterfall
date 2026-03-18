--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local cwTheme = Clockwork.theme
local surface = surface
local Clockwork = Clockwork
local cwKernel = Clockwork.kernel
local Color = Color
local cwOption = Clockwork.option

local THEME = cwTheme:New('AfterFall')

function THEME:CreateFonts()
	surface.CreateFont('hl2_ThickArial',
	{
		font		= 'Arial',
		size		= cwKernel:FontScreenScale(8),
		weight		= 700,
		antialiase	= true,
		additive 	= false,
	})
	surface.CreateFont('hl2_PlayerInfoText',
	{
		font		= 'Verdana',
		size		= cwKernel:FontScreenScale(7),
		weight		= 600,
		antialiase	= true,
		additive 	= false,
	})
	surface.CreateFont('hl2_Large3D2D',
	{
		font		= 'Mailart Rubberstamp',
		size		= cwKernel:GetFontSize3D(),
		weight		= 600,
		antialiase	= true,
		additive 	= false,
	})
	surface.CreateFont('hl2_IntroTextSmall',
	{
		font		= 'Mailart Rubberstamp',
		size		= cwKernel:FontScreenScale(10),
		weight		= 600,
		antialiase	= true,
		additive 	= false,
	})
	surface.CreateFont('hl2_IntroTextTiny',
	{
		font		= 'Mailart Rubberstamp',
		size		= cwKernel:FontScreenScale(9),
		weight		= 600,
		antialiase	= true,
		additive 	= false,
	})
	surface.CreateFont('hl2_CinematicText',
	{
		font		= 'Mailart Rubberstamp',
		size		= cwKernel:FontScreenScale(8),
		weight		= 600,
		antialiase	= true,
		additive 	= false,
	})
	surface.CreateFont('hl2_IntroTextBig',
	{
		font		= 'Mailart Rubberstamp',
		size		= cwKernel:FontScreenScale(18),
		weight		= 600,
		antialiase	= true,
		additive 	= false,
	})
	surface.CreateFont('hl2_MainText',
	{
		font		= 'Mailart Rubberstamp',
		size		= cwKernel:FontScreenScale(7),
		weight		= 600,
		antialiase	= true,
		additive 	= false,
	})
	surface.CreateFont('hl2_TargetIDText',
	{
		font		= 'Mailart Rubberstamp',
		size		= cwKernel:FontScreenScale(7),
		weight		= 600,
		antialiase	= true,
		additive 	= false,
	})
	surface.CreateFont('hl2_MenuTextHuge',
	{
		font		= 'Mailart Rubberstamp',
		size		= cwKernel:FontScreenScale(30),
		weight		= 600,
		antialiase	= true,
		additive 	= false,
	})
	surface.CreateFont('hl2_MenuTextBig',
	{
		font		= 'Mailart Rubberstamp',
		size		= cwKernel:FontScreenScale(18),
		weight		= 600,
		antialiase	= true,
		additive 	= false,
	})
end

local colors = {
	['information'] = Color(241, 208, 94),
	['background'] = Color(0, 0, 0),
	['target_id'] = Color(241, 208, 94),
}

local fonts = {
	['bar_text'] = 'hl2_TargetIDText',
	['main_text'] = 'hl2_MainText',
	['hints_text'] = 'hl2_IntroTextTiny',
	['large_3d_2d'] = 'hl2_Large3D2D',
	['menu_text_big'] = 'hl2_MenuTextBig',
	['menu_text_huge'] = 'hl2_MenuTextHuge',
	['target_id_text'] = 'hl2_TargetIDText',
	['cinematic_text'] = 'hl2_CinematicText',
	['date_time_text'] = 'hl2_IntroTextSmall',
	['intro_text_big'] = 'hl2_IntroTextBig',
	['menu_text_tiny'] = 'hl2_IntroTextTiny',
	['menu_text_small'] = 'hl2_IntroTextSmall',
	['intro_text_tiny'] = 'hl2_IntroTextTiny',
	['intro_text_small'] = 'hl2_IntroTextSmall',
	['player_info_text'] = 'hl2_PlayerInfoText',
}

function THEME:Initialize()
	for k, v in next, colors do cwOption:SetColor(k, v) end
	for k, v in next, fonts do cwOption:SetFont(k, v) end
end

cwTheme:Register(true)