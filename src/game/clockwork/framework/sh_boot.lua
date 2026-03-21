
-- if not Clockwork then
-- 	Clockwork = GM
-- else
-- 	CurrentGM = Clockwork

-- 	table.Merge(CurrentGM, GM)
-- 	Clockwork = nil
-- 	Clockwork = GM

-- 	table.Merge(Clockwork, CurrentGM)
-- 	CurrentGM = nil
-- end
mw = mw or {}

Clockwork.ClockworkFolder = Clockwork.ClockworkFolder or GM.Folder
Clockwork.SchemaFolder = Clockwork.SchemaFolder or engine.ActiveGamemode()

Clockwork.Name = "Clockwork"
Clockwork.Author = "kurozael"
Clockwork.Website = "http://kurozael.com"
Clockwork.Email = "kurozael@gmail.com"
Clockwork.KernelVersion = "0.101"
Clockwork.KernelBuild = ""
Clockwork.TeamBased = false

function Clockwork:GetGameDescription()
	return Clockwork.kernel:GetSchemaGamemodeName()
end

AddCSLuaFile("cl_kernel.lua")
AddCSLuaFile("cl_theme.lua")
AddCSLuaFile("sh_kernel.lua")
AddCSLuaFile("sh_enum.lua")
AddCSLuaFile("sh_boot.lua")

include("sh_enum.lua")
include("sh_kernel.lua")

--[[ These are aliases to avoid variable name conflicts. --]]
cwPlayer, cwTeam, cwFile = player, team, file
_player, _team, _file = player, team, file

team.SetUp(1, 'Default', Color(0, 255, 255))

--[[ These are libraries that we want to load before any others. --]]
-- Clockwork.kernel:IncludePrefixed("libraries/server/sv_file.lua")
-- Clockwork.kernel:IncludeDirectory("libraries/server", true)
-- Clockwork.kernel:IncludeDirectory("libraries/client", true)
-- Clockwork.kernel:IncludeDirectory("libraries/", true)
mw.include.files("libraries/", true, {
	'!sh_json', -- оставлю его на память как самый позорный файл в истории клокворка
	'sv_file',
	'sh_netstream',
	'cl_chatbox',
	'sh_plugin',
	'cl_outline',
	'sh_config',
	'sh_attribute',
	'sh_faction',
	'sh_class',
	'sh_trait',
	'sh_command',
	'sh_option',
	'sh_entity',
	'sh_item',
	'sh_generator',
	'sh_inventory',
	'cl_directory',
	'sv_database',
	'sv_chatbox',
	'sv_hint',
	'*',
})
Clockwork.kernel:IncludePrefixed("cl_theme.lua")
Clockwork.kernel:IncludeDirectory("language/", true)
Clockwork.kernel:IncludeDirectory("directory/", true)
Clockwork.kernel:IncludeDirectory("config/", true)
Clockwork.kernel:IncludePlugins("plugins/", true)
Clockwork.kernel:IncludeDirectory("system/", true)
Clockwork.kernel:IncludeDirectory("items/", true)
Clockwork.kernel:IncludeDirectory("derma/", true)

--[[ The following code is loaded over-the-Cloud. --]]
if SERVER and Clockwork.LoadPreSchemaExternals then
	Clockwork:LoadPreSchemaExternals()
end

--[[ Load the schema and let any plugins know about it. --]]
Clockwork.kernel:IncludeSchema()
Clockwork.plugin:Call("ClockworkSchemaLoaded")

if SERVER then
	MsgC(Color(0,255,100), '[ClockworkLite] Schema loaded!\n')
end

Clockwork.kernel:IncludeDirectory("commands/", true)
Clockwork.player:AddCharacterData("PhysDesc", NWTYPE_STRING, "")
Clockwork.player:AddCharacterData("Skin", NWTYPE_STRING, 0)
Clockwork.player:AddCharacterData("BodyGroups", NWTYPE_STRING, pon.encode({}))
Clockwork.player:AddCharacterData("Pitch", NWTYPE_NUMBER, 0)
Clockwork.player:AddCharacterData("Model", NWTYPE_STRING, "")
Clockwork.player:AddCharacterData("Flags", NWTYPE_STRING, "")
Clockwork.player:AddCharacterData("Name", NWTYPE_STRING, "")
Clockwork.player:AddCharacterData("Cash", NWTYPE_NUMBER, 0)
Clockwork.player:AddCharacterData("Key", NWTYPE_NUMBER, 0)

Clockwork.plugin:IncludeEffects("Clockwork/framework")
Clockwork.plugin:IncludeWeapons("Clockwork/framework")
Clockwork.plugin:IncludeEntities("Clockwork/framework")

if SERVER then
	Clockwork.file:Write("lua/clockwork_shared.lua", "CW_PLUGIN_SHARED_SERIAL = [[" .. Clockwork.kernel:Serialize(CW_PLUGIN_SHARED) .. "]]")

	AddCSLuaFile("clockwork_shared.lua")
end
