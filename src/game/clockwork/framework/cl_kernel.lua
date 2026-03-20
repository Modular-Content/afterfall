--[[ Initiate the shared booting process. --]]
include("sh_boot.lua")
--[[ Micro-optimizations --]]
local Clockwork = Clockwork
local Derma_StringRequest = Derma_StringRequest
local UnPredictedCurTime = UnPredictedCurTime
local RunConsoleCommand = RunConsoleCommand
local DrawColorModify = DrawColorModify
local DeriveGamemode = DeriveGamemode
local DrawMotionBlur = DrawMotionBlur
local CreateSound = CreateSound
local FrameTime = FrameTime
local tonumber = tonumber
local tostring = tostring
local language = language
local CurTime = CurTime
local IsValid = IsValid
local SysTime = SysTime
local string = string
local Entity = Entity
local unpack = unpack
local table = table
local Vector = Vector
local Angle = Angle
local pairs = pairs
local Color = Color
local print = print
local MsgC = MsgC
local ScrW = ScrW
local ScrH = ScrH
local concommand = concommand
local surface = surface
local render = render
local timer = timer
local ents = ents
local hook = hook
local math = math
local draw = draw
local vgui = vgui
local gui = gui
local _team = _team
local _file = _file
--[[
	We localize the Clockwork libraries further to make lookups
	just that little bit faster, it will use a small amount more ram,
	but the performance increase will add up.
--]]
local netstream = netstream
local cwCharacter = Clockwork.character
local cwCommand = Clockwork.command
local cwSetting = Clockwork.setting
local cwFaction = Clockwork.faction
local cwChatBox = Clockwork.chatBox
local cwEntity = Clockwork.entity
local cwOption = Clockwork.option
local cwConfig = Clockwork.config
local cwKernel = Clockwork.kernel
local cwPlugin = Clockwork.plugin
local cwTheme = Clockwork.theme
local cwEvent = Clockwork.event
local cwPly = Clockwork.player
local cwMenu = Clockwork.menu
local cwQuiz = Clockwork.quiz
local cwItem = Clockwork.item
local cwLimb = Clockwork.limb
local cwClient
--[[
	Derive from Sandbox, because we want the spawn menu and such!
	We also want the base Sandbox entities and weapons.
--]]
DeriveGamemode("sandbox")

--[[
	This is a hack to allow us to call plugin hooks based
	on default GMod hooks that are called.
--]]
hook.ClockworkCall = hook.ClockworkCall or hook.Call
hook.Timings = hook.Timings or {}

function hook.Call(name, gamemode, ...)
	if not IsValid(Clockwork.Client) or (not IsValid(cwClient)) then
		Clockwork.Client = LocalPlayer()
		cwClient = Clockwork.Client
	end

	local status, a, b, c = xpcall(cwPlugin.RunHooks, debug.traceback, cwPlugin, name, nil, ...)

	if not status then
		MsgC(Color(255, 100, 0, 255), "[Clockwork] The '" .. name .. "' hook failed to run.\n" .. a .. "\n")
	end

	if a == nil then
		status, a, b, c = xpcall(hook.ClockworkCall, debug.traceback, name, gamemode or Clockwork, ...)

		if not status then
			MsgC(Color(255, 100, 0, 255), "[Clockwork] The '" .. name .. "' hook failed to run.\n" .. a .. "\n")
		else
			return a, b, c
		end
	else
		return a, b, c
	end
end

--[[
	This is a hack to display world tips correctly based on their owner.
--]]
local ClockworkAddWorldTip = AddWorldTip

function AddWorldTip(entIndex, text, dieTime, position, entity)
	local weapon = cwClient:GetActiveWeapon()

	if IsValid(weapon) and string.lower(weapon:GetClass()) == "gmod_tool" then
		if IsValid(entity) and entity.GetPlayerName then
			if cwClient:Name() == entity:GetPlayerName() then
				ClockworkAddWorldTip(entIndex, text, dieTime, position, entity)
			end
		end
	end
end

timer.Remove("HintSystem_OpeningMenu")
timer.Remove("HintSystem_Annoy1")
timer.Remove("HintSystem_Annoy2")

netstream.Hook("RunCommand", function(data)
	RunConsoleCommand(unpack(data))
end)

netstream.Hook("HiddenCommands", function(data)
	for k, v in pairs(data) do
		for k2, v2 in pairs(cwCommand:GetAll()) do
			if cwKernel:GetShortCRC(k2) == v then
				cwCommand:SetHidden(k2, true)
				break
			end
		end
	end
end)

netstream.Hook("OrderTime", function(data)
	Clockwork.OrderCooldown = data
	local activePanel = cwMenu:GetActivePanel()

	if activePanel and activePanel:GetPanelName() == cwOption:Translate("name_business") then
		activePanel:Rebuild()
	end
end)

netstream.Hook("CharacterInit", function(data)
	cwPlugin:Call("PlayerCharacterInitialized", data)
end)

netstream.Hook("Log", function(data)
	cwKernel:PrintColoredText(cwKernel:GetLogTypeColor(data.logType), T(data.text))
end)

netstream.Hook("StartSound", function(data)
	if IsValid(cwClient) then
		local uniqueID = data.uniqueID
		local sound = data.sound
		local volume = data.volume

		if not cwClientSounds then
			cwClientSounds = {}
		end

		if cwClientSounds[uniqueID] then
			cwClientSounds[uniqueID]:Stop()
		end

		cwClientSounds[uniqueID] = CreateSound(cwClient, sound)
		cwClientSounds[uniqueID]:PlayEx(volume, 100)
	end
end)

netstream.Hook("StopSound", function(data)
	local uniqueID = data.uniqueID
	local fadeOut = data.fadeOut

	if not cwClientSounds then
		cwClientSounds = {}
	end

	if cwClientSounds[uniqueID] then
		if fadeOut ~= 0 then
			cwClientSounds[uniqueID]:FadeOut(fadeOut)
		else
			cwClientSounds[uniqueID]:Stop()
		end

		cwClientSounds[uniqueID] = nil
	end
end)

netstream.Hook("InfoToggle", function(data)
	if IsValid(cwClient) and cwClient:HasInitialized() then
		if not Clockwork.InfoMenuOpen then
			Clockwork.InfoMenuOpen = true
			cwKernel:RegisterBackgroundBlur("InfoMenu", SysTime())
		else
			cwKernel:RemoveBackgroundBlur("InfoMenu")
			cwKernel:CloseActiveDermaMenus()
			Clockwork.InfoMenuOpen = false
		end
	end
end)

netstream.Hook("PlaySound", function(data)
	surface.PlaySound(data)
end)

netstream.Hook("InfoStreaming", function(data)
	netstream.Start("InfoSent", true)
end)

netstream.Hook("InfoStreamed", function(data)
	Clockwork.InfoHasStreamed = true
end)

netstream.Hook("QuizCompleted", function(data)
	if not data then
		if not cwQuiz:GetCompleted() then
			gui.EnableScreenClicker(true)
			cwQuiz.panel = vgui.Create("cwQuiz")
			cwQuiz.panel:Populate()
			cwQuiz.panel:MakePopup()
		end
	else
		local quizPanel = cwQuiz:GetPanel()
		cwQuiz:SetCompleted(true)

		if quizPanel then
			quizPanel:Remove()
		end
	end
end)

netstream.Hook("RecogniseMenu", function(data)
	local whisperRange = L("AllInWhisperRange")
	local yellRange = L("AllInYellRange")
	local talkRange = L("AllInTalkRange")
	local lookingAt = L("CharacterYouAreLookingAt")

	local menuPanel = cwKernel:AddMenuFromData(nil, {
		[whisperRange] = function()
			netstream.Start("RecogniseOption", "whisper")
		end,
		[yellRange] = function()
			netstream.Start("RecogniseOption", "yell")
		end,
		[talkRange] = function()
			netstream.Start("RecogniseOption", "talk")
		end,
		[lookingAt] = function()
			netstream.Start("RecogniseOption", "look")
		end
	})

	if IsValid(menuPanel) then
		menuPanel:SetPos(ScrW() / 2 - menuPanel:GetWide() / 2, ScrH() / 2 - menuPanel:GetTall() / 2)
	end

	cwKernel:SetRecogniseMenu(menuPanel)
end)

netstream.Hook("ClockworkIntro", function(data)
	if not Clockwork.ClockworkIntroFadeOut then
		local introImage = cwOption:GetKey("intro_image")
		local introSound = cwOption:GetKey("intro_sound")
		local duration = 8
		local curTime = UnPredictedCurTime()

		if introImage ~= "" then
			duration = 16
		end

		Clockwork.ClockworkIntroWhiteScreen = curTime + FrameTime() * 8
		Clockwork.ClockworkIntroFadeOut = curTime + duration
		Clockwork.ClockworkIntroSound = CreateSound(cwClient, introSound)
		Clockwork.ClockworkIntroSound:PlayEx(0.75, 100)

		timer.Simple(duration - 4, function()
			Clockwork.ClockworkIntroSound:FadeOut(4)
			Clockwork.ClockworkIntroSound = nil
		end)

		surface.PlaySound("buttons/button1.wav")
	end
end)

netstream.Hook("HideCommand", function(data)
	local index = data.index

	for k, v in pairs(cwCommand:GetAll()) do
		if cwKernel:GetShortCRC(k) == index then
			cwCommand:SetHidden(k, data.hidden)
			break
		end
	end
end)

netstream.Hook("CfgListVars", function(data)
	cwClient:PrintMessage(2, "######## [Clockwork] Config ########\n")
	local sSearchData = data
	local tConfigRes = {}

	if sSearchData then
		sSearchData = string.lower(sSearchData)
	end

	for k, v in pairs(cwConfig:GetStored()) do
		if type(v.value) ~= "table" and (not sSearchData or string.find(string.lower(k), sSearchData)) and not v.isStatic then
			if v.isPrivate then
				tConfigRes[#tConfigRes + 1] = {k, string.rep("*", string.utf8len(tostring(v.value)))}
			else
				tConfigRes[#tConfigRes + 1] = {k, tostring(v.value)}
			end
		end
	end

	table.sort(tConfigRes, function(a, b) return a[1] < b[1] end)

	for k, v in pairs(tConfigRes) do
		local systemValues = cwConfig:GetFromSystem(v[1])

		if systemValues then
			cwClient:PrintMessage(2, "// " .. systemValues.help .. "\n")
		end

		cwClient:PrintMessage(2, v[1] .. " = \"" .. v[2] .. "\"\n")
	end

	cwClient:PrintMessage(2, "######## [Clockwork] Config ########\n")
end)

netstream.Hook("ClearRecognisedNames", function(data)
	Clockwork.RecognisedNames = {}
end)

netstream.Hook("RecognisedName", function(data)
	local key = data.key
	local status = data.status

	if status > 0 then
		Clockwork.RecognisedNames[key] = status
	else
		Clockwork.RecognisedNames[key] = nil
	end
end)

netstream.Hook("Hint", function(data)
	if data and type(data) == "table" then
		if data.center then
			cwKernel:AddCenterHint(cwKernel:ParseData(T(data.text)), data.delay, data.color, data.noSound, data.showDuplicates)
		else
			cwKernel:AddTopHint(cwKernel:ParseData(T(data.text)), data.delay, data.color, data.noSound, data.showDuplicates)
		end
	end
end)

netstream.Hook("WeaponItemData", function(data)
	local weapon = Entity(data.weapon)

	if IsValid(weapon) then
		weapon.cwItemTable = cwItem:CreateInstance(data.definition.uniqueID or data.definition.index, data.definition.itemID, data.definition.data)
	end
end)

netstream.Hook("CinematicText", function(data)
	if data and type(data) == "table" then
		cwKernel:AddCinematicText(data.text, data.color, data.barLength, data.hangTime)
	end
end)

netstream.Hook("AddAccessory", function(data)
	Clockwork.AccessoryData[data.itemID] = data.uniqueID
end)

netstream.Hook("RemoveAccessory", function(data)
	Clockwork.AccessoryData[data.itemID] = nil
end)

netstream.Hook("AllAccessories", function(data)
	Clockwork.AccessoryData = {}

	for k, v in pairs(data) do
		Clockwork.AccessoryData[k] = v
	end
end)

netstream.Hook("Notification", function(data)
	local text = T(data.text)
	local class = data.class
	local sound = "ambient/water/drip2.wav"

	if class == 1 then
		sound = "buttons/button10.wav"
	elseif class == 2 then
		sound = "buttons/button17.wav"
	elseif class == 3 then
		sound = "buttons/bell1.wav"
	elseif class == 4 then
		sound = "buttons/button15.wav"
	end

	local info = {
		class = class,
		sound = sound,
		text = text
	}

	if cwPlugin:Call("NotificationAdjustInfo", info) then
		cwKernel:AddNotify(info.text, info.class, 10)
		surface.PlaySound(info.sound)
		print(info.text)
	end
end)

netstream.Hook('RefreshMenu', function()
	if not Clockwork.menu:GetOpen() then return end
	local panel = Clockwork.menu:GetPanel()
	if not (panel and IsValid(panel)) then return end
	panel:Rebuild()
end)

--[[
	@codebase Client
	@details Called to display a HUD notification when a weapon has been picked up. (Used to override GMOD function)
--]]
function Clockwork:HUDWeaponPickedUp(...)
end

--[[
	@codebase Client
	@details Called to display a HUD notification when an item has been picked up. (Used to override GMOD function)
--]]
function Clockwork:HUDItemPickedUp(...)
end

--[[
	@codebase Client
	@details Called to display a HUD notification when ammo has been picked up. (Used to override GMOD function)
--]]
function Clockwork:HUDAmmoPickedUp(...)
end

--[[
	@codebase Client
	@details Called when the context menu is opened.
--]]
function Clockwork:OnContextMenuOpen()
	if cwKernel:IsUsingTool() then
		return self.BaseClass:OnContextMenuOpen(self)
	else
		gui.EnableScreenClicker(true)
	end
end

--[[
	@codebase Client
	@details Called when the context menu is close.
--]]
function Clockwork:OnContextMenuClose()
	if cwKernel:IsUsingTool() then
		return self.BaseClass:OnContextMenuClose(self)
	else
		gui.EnableScreenClicker(false)
	end
end

--[[
	@codebase Client
	@details Called to determine if a player can use property.
	@param {Player} The player that is trying to use property.
	@param
	@param {Entity} The entity that is being used.
	@returns {Bool} Whether or not the player can use property.
--]]
function Clockwork:CanProperty(player, property, entity)
	if not IsValid(entity) then return false end
	local isAdmin = cwPly:IsAdmin(player)
	if not player:Alive() or player:IsRagdolled() or not isAdmin then return false end

	return self.BaseClass:CanProperty(player, property, entity)
end

--[[
	@codebase Client
	@details Called to determine if a player can drive.
	@param {Player} The player trying to drive.
	@param {Entity} The entity that the player is trying to drive.
	@returns {Bool} Whether or not the player can drive the entity.
--]]
function Clockwork:CanDrive(player, entity)
	if not IsValid(entity) then return false end
	local isAdmin = cwPly:IsAdmin(player)
	if not player:Alive() or player:IsRagdolled() or not isAdmin then return false end

	return self.BaseClass:CanDrive(player, entity)
end

--[[
	@codebase Client
	@details Called when the directory is rebuilt.
	@param {DPanel} The directory panel.
--]]
function Clockwork:ClockworkDirectoryRebuilt(panel)
	for k, v in pairs(cwCommand:GetAll()) do
		if not cwPly:HasFlags(cwClient, v.access) then
			cwCommand:RemoveHelp(v)
		else
			cwCommand:AddHelp(v)
		end
	end
end

--[[
	@codebase Client
	@details Called when the derma skin needs to be forced.
	@returns {String} The name of the skin to be forced (nil if not forcing skin).
--]]
function Clockwork:ForceDermaSkin()
	return "Clockwork"
end

--[[
	@codebase Client
	@details Called when the local player is given an item.
	@param {Table} The table of the item that was given.
--]]
function Clockwork:PlayerItemGiven(itemTable)
	if self.storage:IsStorageOpen() then
		self.storage:GetPanel():Rebuild()
	end
end

--[[
	@codebase Client
	@details Called when the local player has an item taken from them.
	@param {Table} The table of the item that was taken.
--]]
function Clockwork:PlayerItemTaken(itemTable)
	if self.storage:IsStorageOpen() then
		self.storage:GetPanel():Rebuild()
	end
end

--[[
	@codebase Client
	@details Called when the local player's character has initialized.
	@returns {Unknown}
--]]
function Clockwork:PlayerCharacterInitialized(iCharacterKey)
end

--[[
	@codebase Client
	@details Called before the local player's storage is rebuilt.
	@param {DPanel} The player's storage panel.
--]]
function Clockwork:PlayerPreRebuildStorage(panel)
end

--[[
	@codebase Client
	@details Called when the local player's storage is rebuilt.
	@param {DPanel} The player's storage panel.
	@param {Table} The categories for the player's storage.
--]]
function Clockwork:PlayerStorageRebuilt(panel, categories)
end

--[[
	@codebase Client
	@details Called when the local player's business is rebuilt.
	@param {DPanel} The player's business panel.
	@param {Table} The categories for the player's business.
--]]
function Clockwork:PlayerBusinessRebuilt(panel, categories)
end

--[[
	@codebase Client
	@details Called when the local player's storage is rebuilt.
	@param {DPanel} The player's storage panel.
	@param {Table} The categories for the player's inventory.
--]]
function Clockwork:PlayerInventoryRebuilt(panel, categories)
end

--[[
	@codebase Client
	@details Called when an entity attempts to fire bullets.
	@param {Entity} The entity trying to fire bullets.
	@param {Table} The info of the bullets being fired.
--]]
function Clockwork:EntityFireBullets(entity, bulletInfo)
end

--[[
	@codebase Client
	@details Called when a player's bulletInfo needs to be adjusted.
	@param {Player} The player that is firing bullets.
	@param {Table} The info of the bullets that need to be adjusted.
--]]
function Clockwork:PlayerAdjustBulletInfo(player, bulletInfo)
end

--[[
	@codebase Client
	@details Called when clockwork's config is initialized.
	@param {String} The name of the config key.
	@param {String} The value relating to the key in the table.
--]]
function Clockwork:ClockworkConfigInitialized(key, value)
	if key == "cash_enabled" and not value then
		for k, v in pairs(cwItem:GetAll()) do
			v.cost = 0
		end
	end
end

local checkTable = {
	["cwTextColorR"] = true,
	["cwTextColorG"] = true,
	["cwTextColorB"] = true,
	["cwTextColorA"] = true
}

--[[
	@codebase Client
	@details Called when one of the client's console variables have been changed.
	@param {String} The name of the convar that was changed.
	@param {String} The previous value of the convar.
	@param {String} The new value of the convar.
--]]
function Clockwork:ClockworkConVarChanged(name, previousValue, newValue) end

--[[
	@codebase Client
	@details Called when one of the configs have been changed.
	@param {String} The config key that was changed.
	@param {String} The data provided.
	@param {String} The previous value of the key.
	@param {String} The new value of the key.
--]]
function Clockwork:ClockworkConfigChanged(key, data, previousValue, newValue)
end

--[[
	@codebase Client
	@details Called when an entity's menu options are needed.
	@param {Entity} The entity that is being checked for menu options.
	@param {Table} The table of options for the entity.
--]]
function Clockwork:GetEntityMenuOptions(entity, options)
	local class = entity:GetClass()
	local generator = self.generator:FindByID(class)

	if class == "cw_item" then
		local itemTable = nil

		if entity.GetItemTable then
			itemTable = entity:GetItemTable()
		else
			debug.Trace()
		end

		if itemTable then
			local useText = itemTable("useText", "Use")

			if itemTable.OnUse and not itemTable.noPlacementUse then
				options[useText] = "cwItemUse"
			end

			if itemTable.GetEntityMenuOptions then
				itemTable:GetEntityMenuOptions(entity, options)
			end

			options["Take"] = "cwItemTake"
			options["Examine"] = "cwItemExamine"
		end
	elseif class == "cw_belongings" then
		options["Open"] = "cwBelongingsOpen"
	elseif class == "cw_shipment" then
		options["Open"] = "cwShipmentOpen"
	elseif class == "cw_cash" then
		options["Take"] = "cwCashTake"
	elseif generator then
		if not entity.CanSupply or entity:CanSupply() then
			options["Supply"] = "cwGeneratorSupply"
		end
	end
end

--[[
	@codebase Client
	@details Called when the GUI mouse has been released.
--]]
function Clockwork:GUIMouseReleased(code)
	if not cwConfig:Get("use_opens_entity_menus"):Get() and vgui.CursorVisible() then
		local trace = cwClient:GetEyeTrace()

		if IsValid(trace.Entity) and trace.HitPos:Distance(cwClient:GetShootPos()) <= 80 then
			self.EntityMenu = cwKernel:HandleEntityMenu(trace.Entity)

			if IsValid(self.EntityMenu) then
				self.EntityMenu:SetPos(gui.MouseX() - self.EntityMenu:GetWide() / 2, gui.MouseY() - self.EntityMenu:GetTall() / 2)
			end
		end
	end
end

--[[
	@codebase Client
	@details Called when a key has been released.
	@param {Player} The player releasing a key.
	@param {String} The key that is being released.
--]]
function Clockwork:KeyRelease(player, key)
	if cwConfig:Get("use_opens_entity_menus"):Get() then
		if key == IN_USE then
			local activeWeapon = player:GetActiveWeapon()
			local trace = cwClient:GetEyeTraceNoCursor()

			if IsValid(activeWeapon) and activeWeapon:GetClass() == "weapon_physgun" then
				if player:KeyDown(IN_ATTACK) then return end
			end

			if IsValid(trace.Entity) and trace.HitPos:Distance(cwClient:GetShootPos()) <= 80 then
				self.EntityMenu = cwKernel:HandleEntityMenu(trace.Entity)

				if IsValid(self.EntityMenu) then
					self.EntityMenu:SetPos(ScrW() / 2 - self.EntityMenu:GetWide() / 2, ScrH() / 2 - self.EntityMenu:GetTall() / 2)
				end
			end
		end
	end
end

--[[
	@codebase Client
	@details Called when the local player has been created.
--]]
function Clockwork:LocalPlayerCreated()
	cwKernel:RegisterNetworkProxy(cwClient, "Clothes", function(entity, name, oldValue, newValue)
		if oldValue ~= newValue then
			if newValue ~= "" then
				local clothesData = string.Explode(" ", newValue)
				Clockwork.ClothesData.uniqueID = clothesData[1]
				Clockwork.ClothesData.itemID = tonumber(clothesData[2])
			else
				Clockwork.ClothesData.uniqueID = nil
				Clockwork.ClothesData.itemID = nil
			end

			Clockwork.inventory:Rebuild()
		end
	end)

	timer.Simple(1, function()
		netstream.Start("LocalPlayerCreated", true)
	end)
end

--[[
	@codebase Client
	@details Called when the client initializes.
--]]
function Clockwork:Initialize()
	CW_CONVAR_TEST = cwKernel:CreateClientConVar("cwTest", 0, true, true)
	CW_CONVAR_TWELVEHOURCLOCK = cwKernel:CreateClientConVar("cwTwelveHourClock", 0, true, true)
	CW_CONVAR_SHOWTIMESTAMPS = cwKernel:CreateClientConVar("cwShowTimeStamps", 0, true, true)
	CW_CONVAR_MAXCHATLINES = cwKernel:CreateClientConVar("cwMaxChatLines", 10, true, true)
	CW_CONVAR_HEADBOBSCALE = cwKernel:CreateClientConVar("cwHeadbobScale", 1, true, true)
	CW_CONVAR_SHOWSERVER = cwKernel:CreateClientConVar("cwShowServer", 1, true, true)
	CW_CONVAR_SHOWAURA = cwKernel:CreateClientConVar("cwShowClockwork", 1, true, true)
	CW_CONVAR_SHOWHINTS = cwKernel:CreateClientConVar("cwShowHints", 1, true, true)
	CW_CONVAR_SHOWLOG = cwKernel:CreateClientConVar("cwShowLog", 1, true, true)
	CW_CONVAR_SHOWOOC = cwKernel:CreateClientConVar("cwShowOOC", 1, true, true)
	CW_CONVAR_SHOWIC = cwKernel:CreateClientConVar("cwShowIC", 1, true, true)
	CW_CONVAR_LANG = cwKernel:CreateClientConVar("cwLang", "English", true, true)
	CW_CONVAR_VIGNETTE = cwKernel:CreateClientConVar("cwShowVignette", 0, true, true)
	CW_CONVAR_CROSSHAIR = cwKernel:CreateClientConVar("cwShowCrosshair", 1, true, true)
	CW_CONVAR_CROSSHAIRDYNAMIC = cwKernel:CreateClientConVar("cwShowCrosshairDynamic", 0, true, true)
	CW_CONVAR_ADMINESP = cwKernel:CreateClientConVar("cwAdminESP", 0, true, true)
	CW_CONVAR_ESPBARS = cwKernel:CreateClientConVar("cwESPBars", 1, true, true)
	CW_CONVAR_ITEMESP = cwKernel:CreateClientConVar("cwItemESP", 0, false, true)
	CW_CONVAR_PROPESP = cwKernel:CreateClientConVar("cwPropESP", 0, false, true)
	CW_CONVAR_SPAWNESP = cwKernel:CreateClientConVar("cwSpawnESP", 0, false, true)
	CW_CONVAR_NPCESP = cwKernel:CreateClientConVar("cwNPCESP", 0, false, true)
	CW_CONVAR_TEXTCOLORR = cwKernel:CreateClientConVar("cwTextColorR", 255, true, true)
	CW_CONVAR_TEXTCOLORG = cwKernel:CreateClientConVar("cwTextColorG", 200, true, true)
	CW_CONVAR_TEXTCOLORB = cwKernel:CreateClientConVar("cwTextColorB", 0, true, true)
	CW_CONVAR_TEXTCOLORA = cwKernel:CreateClientConVar("cwTextColorA", 255, true, true)
	CW_CONVAR_TABX = cwKernel:CreateClientConVar("cwTabPosX", 56, true, true)
	CW_CONVAR_TABY = cwKernel:CreateClientConVar("cwTabPosY", 112, true, true)
	CW_CONVAR_FADEPANEL = cwKernel:CreateClientConVar("cwFadePanels", 0, true, true)
	CW_CONVAR_SHOWGRADIENT = cwKernel:CreateClientConVar("cwShowGradient", 0, true, true)

	if not cwChatBox.panel then
		cwChatBox:CreateDermaAll()
	end

	cwItem:Initialize()

	if not cwOption:GetKey("top_bars") then
		CW_CONVAR_TOPBARS = cwKernel:CreateClientConVar("cwTopBars", 0, true, true)
	else
		cwSetting:RemoveByConVar("cwTopBars")
	end

	cwPlugin:Call("ClockworkKernelLoaded")
	cwPlugin:Call("ClockworkInitialized")
	cwTheme:Initialize()
	cwPlugin:CheckMismatches()
	cwPlugin:ClearHookCache()
	cwSetting:AddSettings()

	if not cwTheme:IsFixed() then
		cwOption:SetColor("information", Color(cvars.Number("cwTextColorR"), cvars.Number("cwTextColorG"), cvars.Number("cwTextColorB"), cvars.Number("cwTextColorA")))
	end

	hook.Remove("PostDrawEffects", "RenderWidgets")
end

--[[
	@codebase Client
	@details Called when Clockwork has initialized.
--]]
function Clockwork:ClockworkInitialized()
	SCREEN_DAMAGE_OVERLAY = Material("clockwork/screendamage.png")
	if SCREEN_DAMAGE_OVERLAY:IsError() then
		ErrorNoHalt("Can't create Material 'clockwork/screendamage.png', disable drawing...")
		SCREEN_DAMAGE_OVERLAY = nil
	end

	VIGNETTE_OVERLAY = Material("clockwork/vignette.png")
	if VIGNETTE_OVERLAY:IsError() then
		ErrorNoHalt("Can't create Material 'clockwork/vignette.png', disable drawing...")
		VIGNETTE_OVERLAY = nil
	end
	
	local weapon = weapons.GetStored("gmod_tool")
	local logoFile = "clockwork/logo/002.png"

	-- Capitalize tool gun text on weapon scroll.
	if (weapon) then
		weapon.PrintName = "Tool Gun"
	end

	self.SpawnIconMaterial = cwKernel:GetMaterial("vgui/spawnmenu/hover")
	self.DefaultGradient = surface.GetTextureID("gui/gradient_down")
	self.GradientTexture = cwKernel:GetMaterial(cwOption:GetKey("gradient") .. ".png")
	self.ClockworkSplash = cwKernel:GetMaterial(logoFile)
	self.FishEyeTexture = cwKernel:GetMaterial("models/props_c17/fisheyelens")
	self.GradientCenter = surface.GetTextureID("gui/center_gradient")
	self.GradientRight = surface.GetTextureID("gui/gradient")
	self.GradientUp = surface.GetTextureID("gui/gradient_up")
	self.ScreenBlur = cwKernel:GetMaterial("pp/blurscreen")

	self.Gradients = {
		[GRADIENT_CENTER] = self.GradientCenter,
		[GRADIENT_RIGHT] = self.GradientRight,
		[GRADIENT_DOWN] = self.DefaultGradient,
		[GRADIENT_UP] = self.GradientUp,
	}

	cwSetting:AddSettings()
end

--[[
	@codebase Client
	@details Called when the tool menu needs to be populated.
--]]
function Clockwork:PopulateToolMenu()
	local toolGun = weapons.GetStored("gmod_tool")

	for k, v in pairs(self.tool:GetAll()) do
		toolGun.Tool[v.Mode] = v

		if v.AddToMenu ~= false then
			spawnmenu.AddToolMenuOption(v.Tab or "Main", v.Category or "New Category", k, v.Name or "#" .. k, v.Command or "gmod_tool " .. k, v.ConfigName or k, v.BuildCPanel)
		end

		language.Add("tool." .. v.UniqueID .. ".name", v.Name)
		language.Add("tool." .. v.UniqueID .. ".desc", v.Desc)
		language.Add("tool." .. v.UniqueID .. ".0", v.HelpText)
	end
end

--[[
	@codebase Client
	@details Called when an Clockwork item has initialized.
	@param {Table} The table of the item being initialized.
--]]
function Clockwork:ClockworkItemInitialized(itemTable)
end

--[[
	@codebase Client
	@details Called after Clockwork items have been initialized.
	@param {Table} The table of items that have been initialized.
--]]
function Clockwork:ClockworkPostItemsInitialized(itemsTable)
end

--[[
	@codebase Client
	@details Called when a player's phys desc override is needed.
	@param {Player} The player whose phys desc override is needed.
	@param {String} The player's physDesc.
--]]
function Clockwork:GetPlayerPhysDescOverride(player, physDesc)
end

--[[
	@codebase Client
	@details Called when a player's door access name is needed.
--]]
function Clockwork:GetPlayerDoorAccessName(player, door, owner)
	return player:Name()
end

--[[
	@codebase Client
	@details Called when a player should show on the door access list.
--]]
function Clockwork:PlayerShouldShowOnDoorAccessList(player, door, owner)
	return true
end

--[[
	@codebase Client
	@details Called when a player should show on the scoreboard.
--]]
function Clockwork:PlayerShouldShowOnScoreboard(player)
	return true
end

--[[
	@codebase Client
	@details Called when the local player attempts to zoom.
--]]
function Clockwork:PlayerCanZoom()
	return true
end

--[[
	@codebase Client
	@details Called when the local player attempts to see a business item.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanSeeBusinessItem(itemTable)
	return true
end

--[[
	@codebase Client
	@details Called when a player presses a bind.
	@param {Unknown} Missing description for player.
	@param {Unknown} Missing description for bind.
	@param {Unknown} Missing description for bPress.
	@returns {Unknown}
--]]
function Clockwork:PlayerBindPress(player, bind, bPress)
	if player:GetRagdollState() == RAGDOLL_FALLENOVER and string.find(bind, "+jump") then
		cwKernel:RunCommand("CharGetUp")
	elseif string.find(bind, "toggle_zoom") then
		return true
	elseif string.find(bind, "+zoom") then
		if not cwPlugin:Call("PlayerCanZoom") then return true end
	end

	if string.find(bind, "+attack") or string.find(bind, "+attack2") then
		if self.storage:IsStorageOpen() then return true end
	end

	if cwConfig:Get("block_inv_binds"):Get() then
		local lowerString = string.lower(bind)
		if string.find(lowerString, cwConfig:Get("command_prefix"):Get() .. "invaction") or string.find(lowerString, "cw invaction") or string.find(lowerString, "cwcmd invaction") then return true end
	end

	return cwPlugin:Call("TopLevelPlayerBindPress", player, bind, bPress)
end

--[[
	@codebase Client
	@details Called when the pause menu is shown.
	@returns {Unknown}
--]]
function ClockworkLite:OnPauseMenuShow()
	if cwCharacter:IsPanelOpen() then
		if cwClient:HasInitialized() and not cwCharacter:IsMenuReset() then
			cwCharacter:SetPanelMainMenu()
			cwCharacter:SetPanelOpen(false)
		end
		return false
	end
	if cwMenu:GetOpen() then
		local panel = cwMenu:GetPanel()
		if panel then panel:SetOpen(false) end
	end
end

-- пожалуйста рубат сделай вызов хука для консоли тоже а то это полный qwq
local wV = false
hook.Add('Think', 'ClockworkLite.console', function()
	local iV = gui.IsConsoleVisible()
	if iV and not wV then
		hook.Run('OnPauseMenuShow')
	end
	wV = iV
end)

--[[
	@codebase Client
	@details Called when a player presses a bind at the top level.
	@param {Unknown} Missing description for player.
	@param {Unknown} Missing description for bind.
	@param {Unknown} Missing description for bPress.
	@returns {Unknown}
--]]
function Clockwork:TopLevelPlayerBindPress(player, bind, bPress)
	return self.BaseClass:PlayerBindPress(player, bind, bPress)
end

--[[
	@codebase Client
	@details Called when the local player attempts to see while unconscious.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanSeeUnconscious()
	return false
end

--[[
	@codebase Client
	@details Called when the local player's move data is created.
	@param {Unknown} Missing description for userCmd.
	@returns {Unknown}
--]]
function Clockwork:CreateMove(userCmd)
	local ragdollEyeAngles = cwKernel:GetRagdollEyeAngles()

	if ragdollEyeAngles and IsValid(cwClient) then
		local defaultSensitivity = 0.05
		local sensitivity = defaultSensitivity * (cwPlugin:Call("AdjustMouseSensitivity", defaultSensitivity) or defaultSensitivity)

		if sensitivity <= 0 then
			sensitivity = defaultSensitivity
		end

		if cwClient:IsRagdolled() then
			ragdollEyeAngles.p = math.Clamp(ragdollEyeAngles.p + userCmd:GetMouseY() * sensitivity, -48, 48)
			ragdollEyeAngles.y = math.Clamp(ragdollEyeAngles.y - userCmd:GetMouseX() * sensitivity, -48, 48)
		else
			ragdollEyeAngles.p = math.Clamp(ragdollEyeAngles.p + userCmd:GetMouseY() * sensitivity, -90, 90)
			ragdollEyeAngles.y = math.Clamp(ragdollEyeAngles.y - userCmd:GetMouseX() * sensitivity, -90, 90)
		end
	end
end

--local LAST_RAISED_TARGET = 0

--[[
	@codebase Client
	@details Called when the view should be calculated.
	@param {Unknown} Missing description for player.
	@param {Unknown} Missing description for origin.
	@param {Unknown} Missing description for angles.
	@param {Unknown} Missing description for fov.
	@returns {Unknown}
--]]
function Clockwork:CalcView(player, origin, angles, fov)
	local scale = math.Clamp(CW_CONVAR_HEADBOBSCALE:GetFloat(),0,1) or 1
	local ent = GetViewEntity()

	if ent != LocalPlayer() then return self.BaseClass:CalcView(player, origin, angles, fov) end

	-- not work if CalcView is overridden, this means that scanners and pills are not affected
	if (self.Client:IsRagdolled()) then
		if (self.BlackFadeIn == 255) then
			return {origin = Vector(20000, 0, 0), angles = Angle(0, 0, 0), fov = fov}
		else
			return self.BaseClass:CalcView(player, origin, angles, fov)
		end
	elseif (!self.Client:Alive()) then
		return {origin = Vector(20000, 0, 0), angles = Angle(0, 0, 0), fov = fov}
	elseif (self.config:Get("enable_headbob"):Get() and scale > 0) then
		if (player:IsOnGround()) then
			local frameTime = FrameTime()

			if (!self.player:IsNoClipping(player)) then
				local approachTime = frameTime * 2
				local info = {speed = 1, yaw = 0.5, roll = 0.1}

				if (!self.HeadbobAngle) then
					self.HeadbobAngle = 0
				end

				if (!self.HeadbobInfo) then
					self.HeadbobInfo = info
				end

				self.plugin:Call("PlayerAdjustHeadbobInfo", info)

				self.HeadbobInfo.yaw = math.Approach(self.HeadbobInfo.yaw, info.yaw, approachTime)
				self.HeadbobInfo.roll = math.Approach(self.HeadbobInfo.roll, info.roll, approachTime)
				self.HeadbobInfo.speed = math.Approach(self.HeadbobInfo.speed, info.speed, approachTime)
				self.HeadbobAngle = self.HeadbobAngle + (self.HeadbobInfo.speed * frameTime)

				local yawAngle = math.sin(self.HeadbobAngle)
				local rollAngle = math.cos(self.HeadbobAngle)

				angles.y = angles.y + (yawAngle * self.HeadbobInfo.yaw)
				angles.r = angles.r + (rollAngle * self.HeadbobInfo.roll)

				local velocity = player:GetVelocity()
				local eyeAngles = player:EyeAngles()

				if (!self.VelSmooth) then self.VelSmooth = 0 end
				if (!self.WalkTimer) then self.WalkTimer = 0 end
				if (!self.LastStrafeRoll) then self.LastStrafeRoll = 0 end

				self.VelSmooth = math.Clamp(self.VelSmooth * 0.9 + velocity:Length() * 0.1, 0, 700)
				self.WalkTimer = self.WalkTimer + self.VelSmooth * FrameTime() * 0.05

				self.LastStrafeRoll = (self.LastStrafeRoll * 3) + (eyeAngles:Right():DotProduct(velocity) * 0.0001 * self.VelSmooth * 0.3)
				self.LastStrafeRoll = self.LastStrafeRoll * 0.25
				angles.r = angles.r + self.LastStrafeRoll

				if (player:GetGroundEntity() != NULL) then
					angles.p = angles.p + math.cos(self.WalkTimer * 0.5) * self.VelSmooth * 0.000002 * self.VelSmooth
					angles.r = angles.r + math.sin(self.WalkTimer) * self.VelSmooth * 0.000002 * self.VelSmooth
					angles.y = angles.y + math.cos(self.WalkTimer) * self.VelSmooth * 0.000002 * self.VelSmooth
				end

				velocity = self.Client:GetVelocity().z

				if (velocity <= -1000 and self.Client:GetMoveType() == MOVETYPE_WALK) then
					angles.p = angles.p + math.sin(UnPredictedCurTime()) * math.abs((velocity + 1000) - 16)
				end
			end
		end
	end

	local view = self.BaseClass:CalcView(player, origin, angles, fov)

	self.plugin:Call("CalcViewAdjustTable", view)

	return view
end

function Clockwork:CalcViewModelView(weapon, viewModel, oldEyePos, oldEyeAngles, eyePos, eyeAngles)
	if !IsValid(weapon) then return end

	local client = self.Client
	local weaponRaised = self.player:GetWeaponRaised(client)

	if (!client:HasInitialized() or !self.config:HasInitialized()) then
		weaponRaised = nil
	end

	if weapon.Sprint and weapon.Sprint != 0 and weapon.Sprint != 3 then
		weaponRaised = true
	end

	local targetValue = 100

	if (weaponRaised) then
		targetValue = 0
	end

	local fraction = (client.cwRaisedFraction or 100) / 100
	local anglesMod = Angle(0, 0, -15)

	eyeAngles:RotateAroundAxis(eyeAngles:Up(), anglesMod.p * fraction)
	eyeAngles:RotateAroundAxis(eyeAngles:Forward(), anglesMod.y * fraction)
	eyeAngles:RotateAroundAxis(eyeAngles:Right(), anglesMod.r * fraction)

	client.cwRaisedFraction = Lerp(FrameTime() * 2, client.cwRaisedFraction or 100, targetValue)

	viewModel:SetAngles(eyeAngles)

	-- Controls the position of all viewmodels
	local func = weapon.GetViewModelPosition
	if ( func ) then
		local pos, ang = func(weapon, eyePos, eyeAngles)
		eyePos = pos or eyePos
		eyeAngles = ang or eyeAngles
	end

	return eyePos, eyeAngles
end

--[[
	@codebase Client
	@details Called when the local player's limb damage is received.
	@returns {Unknown}
--]]
function Clockwork:PlayerLimbDamageReceived()
end

--[[
	@codebase Client
	@details Called when the local player's limb damage is reset.
	@returns {Unknown}
--]]
function Clockwork:PlayerLimbDamageReset()
end

--[[
	@codebase Client
	@details Called when the local player's limb damage is bIsHealed.
	@returns {Unknown}
--]]
function Clockwork:PlayerLimbDamageHealed(hitGroup, amount)
end

--[[
	@codebase Client
	@details Called when the local player's limb takes damage.
	@returns {Unknown}
--]]
function Clockwork:PlayerLimbTakeDamage(hitGroup, damage)
end

--[[
	@codebase Client
	@details Called when a weapon's lowered view info is needed.
	@returns {Unknown}
--]]
function Clockwork:GetWeaponLoweredViewInfo(itemTable, weapon, viewInfo)
end

local _hudBlockedElements = {
	CHudWeaponSelection = true,
	CHudSecondaryAmmo = true,
	CHudVoiceStatus = true,
	CHudCrosshair = true,
	CHudSuitPower = true,
	CHudBattery = true,
	CHudHealth = true,
	CHudAmmo = true,
	CHudChat = true,
	CHUDQuickInfo = true,
	CHUDAutoAim = true,
	CMapOverview = true,
	CustomCrosshair = true,
	CCustomCrosshair = true,
}

--[[
	@codebase Client
	@details Called when a HUD element should be drawn.
	@param {Unknown} Missing description for name.
	@returns {Unknown}
--]]
function Clockwork:HUDShouldDraw(name)
	if _hudBlockedElements[name] then
		return false
	end
	return self.BaseClass:HUDShouldDraw(name)
end

--[[
	@codebase Client
	@details Called when the menu is opened.
	@returns {Unknown}
--]]
function Clockwork:MenuOpened()
	for k, v in pairs(cwMenu:GetItems()) do
		if v.panel.OnMenuOpened then
			v.panel:OnMenuOpened()
		end
	end
end

--[[
	@codebase Client
	@details Called when the menu is closed.
	@returns {Unknown}
--]]
function Clockwork:MenuClosed()
	for k, v in pairs(cwMenu:GetItems()) do
		if v.panel.OnMenuClosed then
			v.panel:OnMenuClosed()
		end
	end

	cwKernel:RemoveActiveToolTip()
	cwKernel:CloseActiveDermaMenus()
end

--[[
	@codebase Client
	@details Called when the character screen's faction characters should be sorted.
	@param {Unknown} Missing description for faction.
	@param {Unknown} Missing description for a.
	@param {Unknown} Missing description for b.
	@returns {Unknown}
--]]
function Clockwork:CharacterScreenSortFactionCharacters(faction, a, b)
	return a.name < b.name
end

--[[
	@codebase Client
	@details Called when the scoreboard's class players should be sorted.
	@param {Unknown} Missing description for class.
	@param {Unknown} Missing description for a.
	@param {Unknown} Missing description for b.
	@returns {Unknown}
--]]
function Clockwork:ScoreboardSortClassPlayers(class, a, b)
	local recogniseA = cwPly:DoesRecognise(a)
	local recogniseB = cwPly:DoesRecognise(b)

	if recogniseA and recogniseB then
		return a:Team() < b:Team()
	elseif recogniseA then
		return true
	else
		return false
	end
end

--[[
	@codebase Client
	@details Called when the scoreboard's player info should be adjusted.
	@returns {Unknown}
--]]
function Clockwork:ScoreboardAdjustPlayerInfo(info)
end

--[[
	@codebase Client
	@details Called when the menu's items should be adjusted.
	@param {Unknown} Missing description for menuItems.
	@returns {Unknown}
--]]
function Clockwork:MenuItemsAdd(menuItems)

	menuItems:Add(cwOption:Translate("name_attributes"), "cwAttributes", cwOption:Translate("description_attributes"), cwOption:GetKey("icon_data_attributes"))
	menuItems:Add(cwOption:Translate("name_scoreboard"), "cwScoreboard", cwOption:Translate("description_scoreboard"), cwOption:GetKey("icon_data_scoreboard"))
	menuItems:Add(cwOption:Translate("name_inventory"), "cwInventory", cwOption:Translate("description_inventory"), cwOption:GetKey("icon_data_inventory"))
	menuItems:Add(cwOption:Translate("name_directory"), "cwDirectory", cwOption:Translate("description_directory"), cwOption:GetKey("icon_data_directory"))
	menuItems:Add(cwOption:Translate("name_settings"), "cwSettings", cwOption:Translate("description_settings"), cwOption:GetKey("icon_data_settings"))
	menuItems:Add(cwOption:Translate("name_system"), "cwSystem", cwOption:Translate("description_system"), cwOption:GetKey("icon_data_system"))

	menuItems:Add(cwOption:Translate("name_donations"), "cwDonations", cwOption:Translate("description_donations"), cwOption:GetKey("icon_data_donations"))

	if cwConfig:Get("show_business"):GetBoolean() then
		menuItems:Add(cwOption:Translate("name_business"), "cwBusiness", cwOption:Translate("description_business"), cwOption:GetKey("icon_data_business"))
	end

	if cwConfig:Get("crafting_menu_enabled"):GetBoolean() then
		menuItems:Add(cwOption:Translate("name_crafting"), "cwCrafting", cwOption:Translate("description_crafting"), cwOption:GetKey("icon_data_crafting"))
	end
end

--[[
	@codebase Client
	@details Called when the menu's items should be destroyed.
	@returns {Unknown}
--]]
function Clockwork:MenuItemsDestroy(menuItems)
end

--[[
	@codebase Client
	@details Called when a generator's target ID is drawn.
	@returns {Unknown}
--]]
function Clockwork:DrawGeneratorTargetID(entity, info)
end

-- МОДУЛЯРВОРК УРА
-- ОПТИМИЗИРУЕМ ЭТОТ Tick!

---@class ModularWork
ModularWork = ModularWork or {}
ModularWork.Systems = ModularWork.Systems or {}

function ModularWork.Systems.CharacterMenu()
	local panel = Clockwork.character:GetPanel()

	if not panel then
		Clockwork.character:SetPanelPolling(false)
		Clockwork.character.isOpen = true
		Clockwork.character.panel = vgui.Create("cwCharacterMenu")
		Clockwork.character.panel:MakePopup()
		Clockwork.character.panel:ReturnToMainMenu()
		Clockwork.plugin:Call("PlayerCharacterScreenCreated", Clockwork.character.panel)
	end
end

local menuMusic = {
	'music/hl1_song17.mp3',
	'music/hl1_song19.mp3',
	'music/hl1_song20.mp3',
	'music/hl1_song21.mp3',
	'music/hl1_song3.mp3',
	'music/hl1_song5.mp3',
	'music/hl2_song0.mp3',
	'music/hl2_song10.mp3',
	'music/hl2_song2.mp3',
	'music/hl2_song26_trainstation1.mp3',
	'music/hl2_song27_trainstation2.mp3',
	'music/hl2_song8.mp3'
}

local musicPool = {}
local menuMusicSound
local deathMusicSound
local heartbeatSound

local function RefillMusicPool()
	musicPool = table.Copy(menuMusic)
end

local function GetNextMusic()
	if #musicPool == 0 then
		RefillMusicPool()
	end
	local id = math.random(#musicPool)
	local track = musicPool[id]
	table.remove(musicPool,id)
	return track
end

function ModularWork.Systems.MenuMusic()
	local client = cwClient
	if not IsValid(client) then return end
	if not cwCharacter:IsPanelOpen() then
		if menuMusicSound then
			if menuMusicSound:IsPlaying() then
				menuMusicSound:FadeOut(4)
			else
				menuMusicSound = nil
			end
		end
		return
	end
	if deathMusicSound and deathMusicSound:IsPlaying() then return end
	if not menuMusicSound then
		local track = GetNextMusic()
		menuMusicSound = CreateSoundExt(client, track)
		menuMusicSound:SetSoundLevel(0)
		menuMusicSound:PlayEx(0.7,100)
		return
	end
	if menuMusicSound:IsFading() then
		menuMusicSound:PlayEx(0.7,100)
		return
	end
	if not menuMusicSound:IsPlaying() then
		menuMusicSound = nil
	end
end

local nextHeartbeatUpdate = 0
local breathSound
function ModularWork.Systems.Heartbeat()
	local ply = cwClient
	if not IsValid(ply) then return end
	if CurTime() < nextHeartbeatUpdate then return end
	nextHeartbeatUpdate = CurTime() + 0.1
	if not ply:Alive() then return end
	local hp = ply:Health()
	local max = ply:GetMaxHealth()
	if max <= 0 then return end
	local percent = hp / max
	if percent < 0.6 then
		if not heartbeatSound then
			heartbeatSound = CreateSoundExt(ply, 'player/heartbeat1.wav')
			heartbeatSound:SetSoundLevel(0)
			heartbeatSound:PlayEx(0.2,100)
		end
		local pitch = 80 + (1 - percent) * 60
		local volume = math.Clamp(0.2 + (1 - percent) * 0.8,0,1)
		heartbeatSound:ChangePitch(pitch,0.2)
		heartbeatSound:ChangeVolume(volume,0.2)
	else
		if heartbeatSound then
			if heartbeatSound:IsPlaying() then
				heartbeatSound:FadeOut(2)
			else
				heartbeatSound = nil
			end
		end
	end
	if percent < 0.4 then
		if not breathSound then
			breathSound = CreateSoundExt(ply, 'player/breathe1.wav')
			breathSound:SetSoundLevel(0)
			breathSound:PlayEx(0.2,100)
		end
		local pitch = 100 + math.Clamp(ply:GetNetVar('Pitch', 0), -20, 20)
		local volume = math.Clamp(0.4 + (1-percent)*0.6,0,1)
		breathSound:ChangePitch(pitch,0.5)
		breathSound:ChangeVolume(volume,0.5)
	else
		if breathSound then
			if breathSound:IsPlaying() then
				breathSound:FadeOut(3)
			else
				breathSound = nil
			end
		end
	end
end

function ModularWork.Systems.NetworkProxy()
	local proxies = Clockwork.NetworkProxies
	local world = game.GetWorld()
	for ent, vars in pairs(proxies) do
		if not IsValid(ent) and ent ~= world then
			proxies[ent] = nil
			continue
		end
		for key, proxy in pairs(vars) do
			local value
			if ent == world then
				value = cwKernel:GetNetVar(key)
			else
				value = ent:GetNetVar(key)
			end
			if value ~= proxy.oldValue then
				proxy.Callback(ent,key,proxy.oldValue,value)
				proxy.oldValue = value
			end
		end
	end
end


timer.Create("mw_fast_networkproxy", 0.1, 0, function()
	if not cwClient then return end
	if cwKernel:IsChoosingCharacter() then return end
	ModularWork.Systems.NetworkProxy()
end)

--[[
	@codebase Client
	@details Called each tick.
	@returns {Unknown}
--]]
function Clockwork:Tick()
    local client = cwClient
    if not IsValid(client) then return end
    if cwCharacter:IsPanelPolling() then ModularWork.Systems.CharacterMenu() end
   	ModularWork.Systems.MenuMusic()
    ModularWork.Systems.Heartbeat()
end

timer.Create("cw_ui_update", 0.1, 0, function()
    if not IsValid(cwClient) then return end
    if cwKernel:IsChoosingCharacter() then return end
    local font = cwOption:GetFont("player_info_text")
	local bars = Clockwork.bars
    local info = Clockwork.PlayerInfoText
    table.Empty(bars.stored)
    table.Empty(info.text)
	info.width = ScrW() * .15
    table.Empty(info.subText)
    cwKernel:DrawHealthArmorBar()
    cwPlugin:Call("GetBars", bars)
    cwPlugin:Call("DestroyBars", bars)
    cwPlugin:Call("GetPlayerInfoText", info)
    cwPlugin:Call("DestroyPlayerInfoText", info)
    if #bars.stored > 1 then
        table.sort(bars.stored, function(a,b)
            return a.priority > b.priority
        end)
    end
	if #info.subText > 1 then
		table.sort(info.subText, function(a,b)
			return a.priority > b.priority
		end)
	end
	for i = 1, #info.text do
		local v = info.text[i]
		if not v then continue end
		info.width = cwKernel:AdjustMaximumWidth(font, v.text, info.width)
	end
	for i = 1, #info.subText do
		local v = info.subText[i]
		if not v then continue end
		info.width = cwKernel:AdjustMaximumWidth(font, v.text, info.width)
	end
	info.width = info.width + 16
end)

timer.Create("cw_attribute_decay", 3, 0, function()
    local boosts = Clockwork.attributes.boosts
    local curTime = CurTime()
    for attr, data in pairs(boosts) do
        for id, boost in pairs(data) do
            if boost.duration and boost.endTime then
                if curTime > boost.endTime then
                    data[id] = nil
                else
                    local timeLeft = boost.endTime - curTime
                    local val = (boost.default / boost.duration) * timeLeft
                    if boost.default < 0 then
                        boost.amount = math.min(val,0)
                    else
                        boost.amount = math.max(val,0)
                    end
                end
            end
        end
    end
end)

timer.Create("cw_ragdoll_decay", 15, 0, function()
    if not cwConfig:Get("fade_dead_npcs"):Get() then return end
    for _, rag in ipairs(ents.FindByClass("C_ClientRagdoll")) do
        if not cwEntity:IsDecaying(rag) then
            cwEntity:Decay(rag,300)
        end
    end
end)

function Clockwork:InitPostEntity()
	self.Client = LocalPlayer()
	cwClient = self.Client

	if IsValid(self.Client) then
		cwPlugin:Call("LocalPlayerCreated")
	end
end

--[[
	@codebase Client
	@details Called each frame.
	@returns {Unknown}
--]]
function Clockwork:Think()
	cwKernel:CallTimerThink(CurTime())
	cwKernel:CalculateHints()

	if cwKernel:IsCharacterScreenOpen() then
		local panel = cwCharacter:GetPanel()

		if panel then
			panel:SetVisible(cwPlugin:Call("GetPlayerCharacterScreenVisible", panel))

			if panel:IsVisible() then
				self.HasCharacterMenuBeenVisible = true
			end
		end
	end
end

--[[
	@codebase Client
	@details Called when the character loading HUD should be painted.
	@returns {Unknown}
--]]
function Clockwork:HUDPaintCharacterLoading(alpha)
end

--[[
	@codebase Client
	@details Called when the character selection HUD should be painted.
	@returns {Unknown}
--]]
function Clockwork:HUDPaintCharacterSelection()
end

--[[
	@codebase Client
	@details Called when the important HUD should be painted.
	@returns {Unknown}
--]]
function Clockwork:HUDPaintImportant()
end

--[[
	@codebase Client
	@details Called when the top screen HUD should be painted.
	@returns {Unknown}
--]]
function Clockwork:HUDPaintTopScreen(info)
end

--[[
	@codebase Client
	@details Called when the local player's screen damage should be drawn.
	@param {Unknown} Missing description for damageFraction.
	@returns {Unknown}
--]]
function Clockwork:DrawPlayerScreenDamage(damageFraction)
	if not SCREEN_DAMAGE_OVERLAY then
		return
	end

	local scrW, scrH = ScrW(), ScrH()
	surface.SetDrawColor(255, 255, 255, math.Clamp(100 * damageFraction, 0, 255))
	surface.SetMaterial(SCREEN_DAMAGE_OVERLAY)
	surface.DrawTexturedRect(0, 0, scrW, scrH)
end

--[[
	Called when the entity outlines should be added.
	The "outlines" parameter is a reference to Clockwork.outline.
--]]
function Clockwork:AddEntityOutlines(outlines)
	if IsValid(self.EntityMenu) and IsValid(self.EntityMenu.entity) then
		--[[ Maybe this isn't needed. --]]
		self.EntityMenu.entity:DrawModel()
		outlines:Add(self.EntityMenu.entity, Color(255, 255, 255, 255))
	end
end

--[[
	@codebase Client
	@details Called when the local player's vignette should be drawn.
	@returns {Unknown}
--]]
function Clockwork:DrawPlayerVignette()
	if not VIGNETTE_OVERLAY then
		return
	end
	
	local curTime = CurTime()

	if not self.cwVignetteAlpha then
		self.cwVignetteAlpha = 100
		self.cwVignetteDelta = self.cwVignetteAlpha
		self.cwVignetteRayTime = 0
	end

	if curTime >= self.cwVignetteRayTime then
		local data = {}
		data.start = cwClient:GetShootPos()
		data.endpos = data.start + cwClient:GetUp() * 512
		data.filter = cwClient
		local trace = util.TraceLine(data)

		if not trace.HitWorld and not trace.HitNonWorld then
			self.cwVignetteAlpha = 100
		else
			self.cwVignetteAlpha = 255
		end

		self.cwVignetteRayTime = curTime + 1
	end

	self.cwVignetteDelta = math.Approach(self.cwVignetteDelta, self.cwVignetteAlpha, FrameTime() * 70)
	local scrW, scrH = ScrW(), ScrH()
	surface.SetDrawColor(0, 0, 0, self.cwVignetteDelta)
	surface.SetMaterial(VIGNETTE_OVERLAY)
	surface.DrawTexturedRect(0, 0, scrW, scrH)
end

local deathMusics = {
	'music/hl2_song1.mp3',
	'music/hl2_song19.mp3',
	'music/hl2_song2.mp3',
	'music/hl2_song23_suitsong3.mp3',
	'music/hl2_song23_suitsong3.mp3',
	'music/hl2_song32.mp3',
	'music/hl2_song33.mp3',
	'music/hl2_song6.mp3',
	'music/hl2_song7.mp3',
	'music/ravenholm_1.mp3',
}

function Clockwork:ChooseDeathMusic()
	return deathMusics[math.random(#deathMusics)]
end

--[[
	@codebase Client
	@details Called when the foreground HUD should be painted.
	@returns {Unknown}
--]]
function Clockwork:HUDPaintForeground()
	local colorWhite = cwOption:GetColor("white")
	local info = cwPlugin:Call("GetProgressBarInfo")

	if info then
		local height = 32
		local width = ScrW() * 0.5
		local x = ScrW() * 0.25
		local y = ScrH() * 0.3

		cwKernel:DrawGradient(
			GRADIENT_RIGHT, x - 16, y - 16, width + 32, height + 32, Color(100, 100, 100, 200)
		)

		cwKernel:DrawBar(
			x, y, width, height, info.color or cwOption:GetColor("information"),
			info.text or "Progress Bar", info.percentage or 100, 100, info.flash
		)
	else
		info = cwPlugin:Call("GetPostProgressBarInfo")

		if info then
			local height = 32
			local width = ScrW() / 2 - 64
			local x = ScrW() * 0.25
			local y = ScrH() * 0.3
			
			cwKernel:DrawGradient(
				GRADIENT_RIGHT, x - 16, y - 16, width + 32, height + 32, Color(100, 100, 100, 200)
			)

			cwKernel:DrawBar(
				x, y, width, height, info.color or cwOption:GetColor("information"),
				info.text or "Progress Bar", info.percentage or 100, 100, info.flash
			)
		end
	end
	
	local ply = cwClient
	local canESP = (cwPly:IsAdmin(ply)) or (ULib and ULib.ucl and ULib.ucl.query and ULib.ucl.query(ply, "cw - admin esp"))
	if canESP then
		if cwPlugin:Call("PlayerCanSeeAdminESP") then
			cwKernel:DrawAdminESP()
		end
	end

	local screenTextInfo = cwPlugin:Call("GetScreenTextInfo")

	if screenTextInfo then
		local alpha = screenTextInfo.alpha or 255
		local y = ScrH() / 2 - 128
		local x = ScrW() / 2

		if screenTextInfo.title then
			cwKernel:OverrideMainFont(cwOption:GetFont("menu_text_small"))
			y = cwKernel:DrawInfo(screenTextInfo.title, x, y, colorWhite, alpha)
			cwKernel:OverrideMainFont(false)
		end

		if screenTextInfo.text then
			cwKernel:OverrideMainFont(cwOption:GetFont("menu_text_tiny"))
			y = cwKernel:DrawInfo(screenTextInfo.text, x, y, colorWhite, alpha)
			cwKernel:OverrideMainFont(false)
		end
	end

	if screenTextInfo and screenTextInfo.deathMusic then
		if not deathMusicSound or not deathMusicSound:IsPlaying() then
			local deathMusic = self:ChooseDeathMusic()
			if deathMusic then
				deathMusicSound = CreateSoundExt(ply, deathMusic)
				deathMusicSound:SetSoundLevel(0)
				deathMusicSound:PlayEx(.8, math.random(95, 105))
			end
		end
	elseif deathMusicSound then
		if deathMusicSound:IsPlaying() then
			deathMusicSound:FadeOut(8)
		else
			deathMusicSound = nil
		end
	end

	cwChatBox:Paint()

	local info = {width = ScrW() * 0.3, x = 8, y = 8};
	cwKernel:DrawBars(info, "top")
	cwPlugin:Call("HUDPaintTopScreen", info)
end

--[[
	@codebase Client
	@details Called each frame that an item entity exists.
	@returns {Unknown}
--]]
function Clockwork:ItemEntityThink(itemTable, entity)
end

--[[
	@codebase Client
	@details Called when an item entity is drawn.
	@returns {Unknown}
--]]
function Clockwork:ItemEntityDraw(itemTable, entity)
end

--[[
	@codebase Client
	@details Called when a cash entity is drawn.
	@returns {Unknown}
--]]
function Clockwork:CashEntityDraw(entity)
end

--[[
	@codebase Client
	@details Called when a gear entity is drawn.
	@returns {Unknown}
--]]
function Clockwork:GearEntityDraw(entity)
end

--[[
	@codebase Client
	@details Called when a generator entity is drawn.
	@returns {Unknown}
--]]
function Clockwork:GeneratorEntityDraw(entity)
end

--[[
	@codebase Client
	@details Called when a shipment entity is drawn.
	@returns {Unknown}
--]]
function Clockwork:ShipmentEntityDraw(entity)
end

--[[
	@codebase Client
	@details Called when an item's network data has been updated.
	@param {Unknown} Missing description for itemTable.
	@param {Unknown} Missing description for newData.
	@returns {Unknown}
--]]
function Clockwork:ItemNetworkDataUpdated(itemTable, newData)
	if itemTable.OnNetworkDataUpdated then
		itemTable:OnNetworkDataUpdated(newData)
	end
end

--[[
	@codebase Client
	@details Called when the Clockwork kernel has loaded.
--]]
function Clockwork:ClockworkKernelLoaded()
end

--[[
	@codebase Client
	@details Called when the Clockwork schema has loaded.
--]]
function Clockwork:ClockworkSchemaLoaded()
	FACTION_CITIZENS_FEMALE = Schema:GetFemaleCitizenModels() or FACTION_CITIZENS_FEMALE
	FACTION_CITIZENS_MALE = Schema:GetMaleCitizenModels() or FACTION_CITIZENS_MALE
end

--[[
	@codebase Client
	@details Called to get the screen text info.
	@returns {Unknown}
--]]
function Clockwork:GetScreenTextInfo()
	local blackFadeAlpha = cwKernel:GetBlackFadeAlpha()

	if cwClient:GetNetVar('CharBanned', false) then
		return {
			alpha = blackFadeAlpha,
			title = 'ВАШ ПЕРСОНАЖ ЗАБАНЕН',
			text = 'Перейдите в меню персонажей, чтобы выбрать другого.',
			deathMusic = true,
		}
	end

	if CW_CONVAR_TEST:GetInt() == 1 then
		return {
			alpha = 255 - blackFadeAlpha,
			title = 'ТЕСТОВЫЙ ТЕКСТ',
			text = 'Это тестовый текст для проверки отображения текста на экране и работы музыки при смерти.',
			deathMusic = true,
		}
	end
end

--[[
	@codebase Client
	@details Called after the VGUI has been rendered.
	@returns {Unknown}
--]]
function Clockwork:PostRenderVGUI()
	local cinematic = self.Cinematics[1]

	if cinematic then
		cwKernel:DrawCinematic(cinematic, CurTime())
	end

	local activeMarkupToolTip = cwKernel:GetActiveMarkupToolTip()

	if activeMarkupToolTip and IsValid(activeMarkupToolTip) and activeMarkupToolTip:IsVisible() then
		local markupToolTip = activeMarkupToolTip:GetMarkupToolTip()
		local alpha = activeMarkupToolTip:GetAlpha()
		local x, y = gui.MouseX(), gui.MouseY() + 24

		if markupToolTip then
			cwKernel:DrawMarkupToolTip(markupToolTip.object, x, y, alpha)
		end
	end
end

--[[
	@codebase Client
	@details Called to get whether the local player can see the admin ESP.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanSeeAdminESP()
	return CW_CONVAR_ADMINESP:GetInt() == 1
end

--[[
	@codebase Client
	@details Called when the local player attempts to get up.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanGetUp()
	return true
end

--[[
	@codebase Client
	@details Called when the local player attempts to see the top bars.
	@param {Unknown} Missing description for class.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanSeeBars(class)
	if class == "tab" then
		if CW_CONVAR_TOPBARS then
			return CW_CONVAR_TOPBARS:GetInt() == 0 and cwKernel:IsInfoMenuOpen()
		else
			return cwKernel:IsInfoMenuOpen()
		end
	elseif class == "top" then
		if CW_CONVAR_TOPBARS then
			return CW_CONVAR_TOPBARS:GetInt() == 1
		else
			return true
		end
	else
		return true
	end
end

--[[
	@codebase Client
	@details Called when the local player's limb info is needed.
	@returns {Unknown}
--]]
function Clockwork:GetPlayerLimbInfo(info)
end

--[[
	@codebase Client
	@details Called when the local player attempts to see the top hints.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanSeeHints()
	return true
end

--[[
	@codebase Client
	@details Called when the local player attempts to see the center hints.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanSeeCenterHints()
	return true
end

--[[
	@codebase Client
	@details Called when the local player attempts to see their limb damage.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanSeeLimbDamage()
	return cwKernel:IsInfoMenuOpen() and cwConfig:Get("limb_damage_system"):Get()
end

--[[
	@codebase Client
	@details Called when the local player attempts to see the date and time.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanSeeDateTime()
	return cwKernel:IsInfoMenuOpen()
end

--[[
	@codebase Client
	@details Called when the local player attempts to see a class.
	@param {Unknown} Missing description for class.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanSeeClass(class)
	return true
end

--[[
	@codebase Client
	@details Called when the local player attempts to see the player info.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanSeePlayerInfo()
	return cwKernel:IsInfoMenuOpen()
end

function Clockwork:AddHint(name, delay)
end

function Clockwork:AddNotify(text, class, length)
	return cwKernel:AddNotify(text, class, length)
end

--[[
	@codebase Client
	@details Called when the target ID HUD should be drawn.
	@returns {Unknown}
--]]
function Clockwork:HUDDrawTargetID()
	local targetIDTextFont = cwOption:GetFont("target_id_text")
	local traceEntity = NULL
	local colorWhite = cwOption:GetColor("white")
	cwKernel:OverrideMainFont(targetIDTextFont)

	if IsValid(cwClient) and cwClient:Alive() and not IsValid(self.EntityMenu) then
		if not cwClient:IsRagdolled(RAGDOLL_FALLENOVER) then
			local fadeDistance = 196
			local curTime = UnPredictedCurTime()
			local trace = cwPly:GetRealTrace(cwClient)

			if IsValid(trace.Entity) and not trace.Entity:IsEffectActive(EF_NODRAW) then
				if not self.TargetIDData or self.TargetIDData.entity ~= trace.Entity then
					self.TargetIDData = {
						showTime = curTime + cwConfig:Get("target_id_delay"):Get(),
						entity = trace.Entity
					}
				end

				if self.TargetIDData then
					self.TargetIDData.trace = trace
				end

				if not IsValid(traceEntity) then
					traceEntity = trace.Entity
				end

				if curTime >= self.TargetIDData.showTime then
					if not self.TargetIDData.fadeTime then
						self.TargetIDData.fadeTime = curTime + 1
					end

					local class = trace.Entity:GetClass()
					local entity = cwEntity:GetPlayer(trace.Entity)

					if entity then
						fadeDistance = cwPlugin:Call("GetTargetPlayerFadeDistance", entity)
					end

					local alpha = math.Clamp(cwKernel:CalculateAlphaFromDistance(fadeDistance, cwClient, trace.HitPos) * 1.5, 0, 255)

					if alpha > 0 then
						alpha = math.min(alpha, math.Clamp(1 - (self.TargetIDData.fadeTime - curTime) / 3, 0, 1) * 255)
					end

					self.TargetIDData.fadeDistance = fadeDistance
					self.TargetIDData.player = entity
					self.TargetIDData.alpha = alpha
					self.TargetIDData.class = class

					if entity and cwClient ~= entity then
						if cwPlugin:Call("ShouldDrawPlayerTargetID", entity, traceEntity) then
							if not cwPly:IsNoClipping(entity) then
								if cwClient:GetShootPos():Distance(trace.HitPos) <= fadeDistance then
									if self.nextCheckRecognises and self.nextCheckRecognises[2] ~= entity then
										cwClient:SetNetVar("TargetKnows", true)
									end

									local flashAlpha = nil
									local toScreen = (trace.HitPos + Vector(0, 0, 16)):ToScreen()
									local x, y = toScreen.x, toScreen.y

									if not cwPly:DoesTargetRecognise() then
										flashAlpha = math.Clamp(math.sin(curTime * 2) * alpha, 0, 255)
									end

									if cwPly:DoesRecognise(entity, RECOGNISE_PARTIAL) then
										local text = string.Explode("\n", cwPlugin:Call("GetTargetPlayerName", entity))
										local newY

										for k, v in pairs(text) do
											newY = cwKernel:DrawInfo(v, x, y, entity:GetTeamClass().color, alpha)

											if flashAlpha then
												cwKernel:DrawInfo(v, x, y, colorWhite, flashAlpha)
											end

											if newY then
												y = newY
											end
										end
									else
										local unrecognisedName, usedPhysDesc = cwPly:GetUnrecognisedName(entity)

										local wrappedTable = {unrecognisedName}

										local teamColor = entity:GetTeamClass().color
										local result = cwPlugin:Call("PlayerCanShowUnrecognised", entity, x, y, unrecognisedName, teamColor, alpha, flashAlpha)
										local newY

										if type(result) == "string" then
											wrappedTable = {}
											cwKernel:WrapText(result, targetIDTextFont, math.max(ScrW() / 9, 384), wrappedTable)
										elseif usedPhysDesc then
											wrappedTable = {}
											cwKernel:WrapText(unrecognisedName, targetIDTextFont, math.max(ScrW() / 9, 384), wrappedTable)
										end

										if result == true or type(result) == "string" then
											for k, v in pairs(wrappedTable) do
												newY = cwKernel:DrawInfo(v, x, y, teamColor, alpha)

												if flashAlpha then
													cwKernel:DrawInfo(v, x, y, colorWhite, flashAlpha)
												end

												if newY then
													y = newY
												end
											end
										elseif tonumber(result) then
											y = result
										end
									end

									self.TargetPlayerText.stored = {}
									cwPlugin:Call("GetTargetPlayerText", entity, self.TargetPlayerText)
									cwPlugin:Call("DestroyTargetPlayerText", entity, self.TargetPlayerText)
									y = cwPlugin:Call("DrawTargetPlayerStatus", entity, alpha, x, y) or y

									for k, v in pairs(self.TargetPlayerText.stored) do
										if v.scale then
											y = cwKernel:DrawInfoScaled(v.scale, v.text, x, y, v.color or colorWhite, alpha)
										else
											y = cwKernel:DrawInfo(v.text, x, y, v.color or colorWhite, alpha)
										end
									end

									if not self.nextCheckRecognises or curTime >= self.nextCheckRecognises[1] or self.nextCheckRecognises[2] ~= entity then
										netstream.Start("GetTargetRecognises", entity)

										self.nextCheckRecognises = {curTime + 2, entity}
									end
								end
							end
						end
					elseif self.generator:FindByID(class) then
						if cwClient:GetShootPos():Distance(trace.HitPos) <= fadeDistance then
							local generator = self.generator:FindByID(class)
							local toScreen = (trace.HitPos + Vector(0, 0, 16)):ToScreen()
							local power = trace.Entity:GetPower()
							local name = generator.name
							local x, y = toScreen.x, toScreen.y
							y = cwKernel:DrawInfo(name, x, y, Color(150, 150, 100, 255), alpha)

							local info = {
								showPower = true,
								generator = generator,
								x = x,
								y = y
							}

							cwPlugin:Call("DrawGeneratorTargetID", trace.Entity, info)

							if info.showPower then
								if power == 0 then
									info.y = cwKernel:DrawInfo("Press Use to re-supply", info.x, info.y, Color(255, 255, 255, 255), alpha)
								else
									info.y = cwKernel:DrawBar(info.x - 80, info.y, 160, 16, cwOption:GetColor("information"), generator.powerPlural, power, generator.power, power < generator.power / 5, {
										uniqueID = class
									})
								end
							end
						end
					elseif trace.Entity:IsWeapon() then
						if cwClient:GetShootPos():Distance(trace.HitPos) <= fadeDistance then
							local active = nil

							for k, v in ipairs(_player.GetAll()) do
								if v:GetActiveWeapon() == trace.Entity then
									active = true
								end
							end

							if not active then
								local toScreen = (trace.HitPos + Vector(0, 0, 16)):ToScreen()
								local x, y = toScreen.x, toScreen.y
								y = cwKernel:DrawInfo("An unknown weapon", x, y, Color(200, 100, 50, 255), alpha)
								y = cwKernel:DrawInfo("Press use to equip.", x, y, colorWhite, alpha)
							end
						end
					elseif trace.Entity.HUDPaintTargetID then
						local toScreen = (trace.HitPos + Vector(0, 0, 16)):ToScreen()
						local x, y = toScreen.x, toScreen.y
						trace.Entity:HUDPaintTargetID(x, y, alpha)
					else
						local toScreen = (trace.HitPos + Vector(0, 0, 16)):ToScreen()
						local x, y = toScreen.x, toScreen.y

						hook.Call("HUDPaintEntityTargetID", Clockwork, trace.Entity, {
							alpha = alpha,
							x = x,
							y = y
						})
					end
				end
			end
		end
	end

	cwKernel:OverrideMainFont(false)

	if not IsValid(traceEntity) then
		if self.TargetIDData then
			self.TargetIDData = nil
		end
	end
end

--[[
	@codebase Client
	@details Called when the target's status should be drawn.
	@param {Unknown} Missing description for target.
	@param {Unknown} Missing description for alpha.
	@param {Unknown} Missing description for x.
	@param {Unknown} Missing description for y.
	@returns {Unknown}
--]]
function Clockwork:DrawTargetPlayerStatus(target, alpha, x, y)
	local informationColor = cwOption:GetColor("information")
	local gender = target:GetPronouns()

	if not target:Alive() then
		return cwKernel:DrawInfo(gender .. " is clearly deceased.", x, y, informationColor, alpha)
	else
		return y
	end
end

--[[
	@codebase Client
	@details Called when the local player's character creation info should be adjusted.
	@returns {Unknown}
--]]
function Clockwork:PlayerAdjustCharacterCreationInfo(panel, info)
end

--[[
	@codebase Client
	@details Called when the character panel tool tip is needed.
	@param {Unknown} Missing description for panel.
	@param {Unknown} Missing description for character.
	@returns {Unknown}
--]]
function Clockwork:GetCharacterPanelToolTip(panel, character)
	if table.Count(cwFaction:GetAll()) > 1 then
		local numPlayers = #cwFaction:GetPlayers(character.faction)
		local numLimit = cwFaction:GetLimit(character.faction)

		return "There are " .. numPlayers .. "/" .. numLimit .. " characters with this faction."
	end
end

--[[
	@codebase Client
	@details Called when the character panel weapon model is needed.
	@returns {Unknown}
--]]
function Clockwork:GetCharacterPanelSequence(entity, character)
end

--[[
	@codebase Client
	@details Called when the character panel weapon model is needed.
	@returns {Unknown}
--]]
function Clockwork:GetCharacterPanelWeaponModel(panel, character)
end

--[[
	@codebase Client
	@details Called when a model selection's weapon model is needed.
	@returns {Unknown}
--]]
function Clockwork:GetModelSelectWeaponModel(model)
end

--[[
	@codebase Client
	@details Called when a model selection's sequence is needed.
	@returns {Unknown}
--]]
function Clockwork:GetModelSelectSequence(entity, model)
end

--[[
    @codebase Client
    @details Finds the location of the player and packs together the info for observer ESP.
    @param {Table} The current table of ESP positions/colors/names to add on to.
--]]
function Clockwork:GetAdminESPInfo(info)
	for k, v in ipairs(_player.GetAll()) do
		if v:HasInitialized() then
			local physBone = v:LookupBone("ValveBiped.Bip01_Head1")
			local position = nil

			if physBone then
				local bonePosition = v:GetBonePosition(physBone)

				if bonePosition then
					position = bonePosition + Vector(0, 0, 16)
				end
			else
				position = v:GetPos() + Vector(0, 0, 80)
			end

			local topText = {v:Name()}

			cwPlugin:Call("GetStatusInfo", v, topText)

			local text = {
				{
					text = table.concat(topText, " "),
					color = v:GetTeamClass().color
				}
			}

			cwPlugin:Call("GetPlayerESPInfo", v, text)

			table.insert(info, {
				position = position,
				text = text
			})
		end
	end

	if CW_CONVAR_ITEMESP:GetInt() == 1 then
		for k, v in ipairs(ents.GetAll()) do
			if v:GetClass() == "cw_item" then
				if v:IsValid() then
					local position = v:GetPos()
					local itemTable = cwEntity:FetchItemTable(v)

					if itemTable then
						local itemName = L(itemTable("name"))
						local color = Color(0, 255, 255, 255)

						table.insert(info, {
							position = position,
							text = {
								{
									text = "[Item]",
									color = color
								},
								{
									text = itemName,
									color = color
								}
							}
						})
					end
				end
			end
		end
	end
end

--[[
	@codebase Client
	@details Called when a player's status info is needed.
	@param {Unknown} Missing description for player.
	@param {Unknown} Missing description for text.
	@returns {Unknown}
--]]
function Clockwork:GetStatusInfo(player, text)
	local action = cwPly:GetAction(player, true)

	if action then
		if not player:IsRagdolled() then
			if action == "lock" then
				table.insert(text, "[Locking]")
			elseif action == "unlock" then
				table.insert(text, "[Unlocking]")
			end
		elseif action == "unragdoll" then
			if player:GetRagdollState() == RAGDOLL_FALLENOVER then
				table.insert(text, "[Getting Up]")
			else
				table.insert(text, "[Unconscious]")
			end
		elseif not player:Alive() then
			table.insert(text, "[Dead]")
		else
			table.insert(text, "[Performing '" .. action .. "']")
		end
	end

	if player:GetRagdollState() == RAGDOLL_FALLENOVER then
		local fallenOver = player:GetNetVar("FallenOver")

		if fallenOver then
			table.insert(text, "[Fallen Over]")
		end
	end
end

--[[
	@codebase Client
	@details Called when extra player info is needed.
	@param {Unknown} Missing description for player.
	@param {Unknown} Missing description for text.
	@returns {Unknown}
--]]
function Clockwork:GetPlayerESPInfo(player, text)
	if player:IsValid() then
		local weapon = player:GetActiveWeapon()
		local health = player:Health()
		local armor = player:Armor()
		local colorWhite = Color(255, 255, 255, 255)
		local colorRed = Color(255, 0, 0, 255)
		local colorHealth = colorWhite
		local colorArmor = colorWhite

		table.insert(text, {
			text = player:SteamName(),
			color = Color(170, 170, 170, 255),
			icon = cwPly:GetChatIcon(player)
		})

		if player:Alive() and health > 0 then
			if CW_CONVAR_ESPBARS:GetInt() == 0 then
				colorHealth = self:GetValueColor(health)
				colorArmor = self:GetValueColor(armor)
			end

			table.insert(text, {
				text = "Health: [" .. health .. "]",
				color = colorHealth,
				bar = {
					value = health,
					max = player:GetMaxHealth()
				}
			})

			if player:Armor() > 0 then
				table.insert(text, {
					text = "Armor: [" .. armor .. "]",
					color = colorArmor,
					bar = {
						value = armor,
						max = player:GetMaxArmor()
					},
					barColor = Color(30, 65, 175, 255)
				})
			end

			if weapon and IsValid(weapon) then
				local raised = cwPly:GetWeaponRaised(player)
				local color = colorWhite

				if raised == true then
					color = colorRed
				end

				if weapon.GetPrintName then
					local printName = weapon:GetPrintName()

					if printName then
						table.insert(text, {
							text = printName,
							color = color
						})
					end
				end
			end
		end
	end
end

--[[
	@codebase Client
	@details A function to get the color of a value from green to red.
	@param {Unknown} Missing description for value.
	@returns {Unknown}
--]]
function Clockwork:GetValueColor(value)
	local red = math.floor(255 - value * 2.55)
	local green = math.floor(value * 2.55)

	return Color(red, green, 0, 255)
end

--[[
    @codebase Client
    @details This function is called after the progress bar info updates.
--]]
function Clockwork:GetPostProgressBarInfo()
end

--[[
    @codebase Client
    @details This function is called when custom character options are needed.
    @param {Table} The character whose options are needed.
    @param {Table} The currently available options.
    @param {Table} The menu itself.
--]]
function Clockwork:GetCustomCharacterOptions(character, options, menu)
end

--[[
    @codebase Client
    @details This function is called when custom character buttons are needed.
    @param {Table} The character whose buttons are needed.
    @param {Table} The currently available buttons.
--]]
function Clockwork:GetCustomCharacterButtons(character, buttons)
end

--[[
    @codebase Client
    @details This function is called to figure out the text, percentage and flash of the current progress bar.
    @returns {Table} The text, flash, and percentage of the progress bar.
--]]
function Clockwork:GetProgressBarInfo()
    local action, percentage = cwPly:GetAction(cwClient, true)
    if not cwClient:Alive() and action == "spawn" then
        return {text = "Вы умерли...", percentage = percentage, flash = percentage < 10}
    end
    if cwClient:GetRagdollState() == RAGDOLL_FALLENOVER then
        local fallenOver = cwClient:GetNetVar("FallenOver")

        if fallenOver and Clockwork.plugin:Call("PlayerCanGetUp", cwClient) then
            return {text = 'Нажмите "Прыжок", чтобы подняться.', percentage = 100}
        end
    end
	if action then
    	if action == "lock" then
    	    return {text = "Закрываем замок...", percentage = percentage, flash = percentage < 10}
    	elseif action == "unlock" then
    	    return {text = "Открываем замок...", percentage = percentage, flash = percentage < 10}
    	elseif action == "unragdoll" then
    	    if cwClient:GetRagdollState() == RAGDOLL_FALLENOVER then
    	        return {text = "Вы встаете...", percentage = percentage, flash = percentage < 10}
    	    else
    	        return {text = "Вы приходите в сознание...", percentage = percentage, flash = percentage < 10}
    	    end
    	end
	end
end

--[[
	@codebase Client
	@details Called just before the local player's information is drawn.
	@returns {Unknown}
--]]
function Clockwork:PreDrawPlayerInfo(boxInfo, information, subInformation)
end

--[[
	@codebase Client
	@details Called just after the local player's information is drawn.
	@returns {Unknown}
--]]
function Clockwork:PostDrawPlayerInfo(boxInfo, information, subInformation)
end

--[[
	@codebase Client
	@details Called just after the date time box is drawn.
	@returns {Unknown}
--]]
function Clockwork:PostDrawDateTimeBox(info)
end

--[[
	@codebase Client
	@details Called after the view model is drawn.
	@param {Entity} The viewmodel being drawn.
	@param {Player} The player drawing the viewmodel.
	@param {Weapon} The weapon table for the viewmodel.
--]]
function Clockwork:PostDrawViewModel(viewModel, player, weapon)
	if weapon.UseHands or not weapon:IsScripted() then
		local hands = cwClient:GetHands()

		if IsValid(hands) then
			hands:DrawModel()
		end
	end
end

--[[
    @codebase Client
    @details This function is called when local player info text is needed and adds onto it (F1 menu).
    @param {Table} The current table of player info text to add onto.
--]]
function Clockwork:GetPlayerInfoText(playerInfoText)
	local cash = cwPly:GetCash()
	local wages = cwPly:GetWages()

	if cwConfig:Get("cash_enabled"):Get() then
		if cash > 0 then
			playerInfoText:Add("CASH", L("PlayerInfoCash", cwOption:GetKey("name_cash"), cwKernel:FormatCash(cash, true)))
		end

		if wages > 0 then
			playerInfoText:Add("WAGES", L("PlayerInfoWages", cwConfig:Get("wages_name"):Get(), cwKernel:FormatCash(wages)))
		end
	end

	playerInfoText:AddSub("NAME", L("PlayerInfoName", cwClient:Name()), 2)
	playerInfoText:AddSub("CLASS", L("PlayerInfoClass", L(cwClient:GetTeamClass().name)), 1)
end

--[[
    @codebase Client
    @details This function is called when the player's fade distance is needed for their target text (when you look at them).
    @param {Table} The player we are finding the distance for.
    @returns {Number} The fade distance, defaulted at 4096.
--]]
function Clockwork:GetTargetPlayerFadeDistance(player)
	return 4096
end

--[[
	@codebase Client
	@details Called when the player info text should be destroyed.
	@returns {Unknown}
--]]
function Clockwork:DestroyPlayerInfoText(playerInfoText)
end

--[[
    @codebase Client
    @details This function is called when the targeted player's target text is needed.
    @param {Table} The player we are finding the distance for.
    @param {Table} The player's current target text.
--]]
function Clockwork:GetTargetPlayerText(player, targetPlayerText)
	local rankName, rankTable = player:GetFactionRank()

	if rankName and rankName ~= "" and rankTable.displayRank then
		local rankDisplayText = L("Ranked", rankName)
		targetPlayerText:Add("RANK", rankDisplayText)
	end

	local targetIDTextFont = cwOption:GetFont("target_id_text")
	local physDescTable = {}
	local thirdPerson = "him"

	if player:GetGender() == GENDER_FEMALE then
		thirdPerson = "her"
	end

	if cwPly:DoesRecognise(player, RECOGNISE_PARTIAL) then
		cwKernel:WrapText(cwPly:GetPhysDesc(player), targetIDTextFont, math.max(ScrW() / 9, 384), physDescTable)

		for k, v in pairs(physDescTable) do
			targetPlayerText:Add("PHYSDESC_" .. k, v)
		end
	elseif player:Alive() then
		targetPlayerText:Add("PHYSDESC", "You do not recognise " .. thirdPerson .. ".")
	end
end

--[[
	@codebase Client
	@details Called when the target player's text should be destroyed.
	@returns {Unknown}
--]]
function Clockwork:DestroyTargetPlayerText(player, targetPlayerText)
end

--[[
	@codebase Client
	@details Called when a player's scoreboard text is needed.
	@param {Unknown} Missing description for player.
	@returns {Unknown}
--]]
function Clockwork:GetPlayerScoreboardText(player)
	local _, thirdPerson = player:GetPronouns()

	if cwPly:DoesRecognise(player, RECOGNISE_PARTIAL) then
		local physDesc = cwPly:GetPhysDesc(player)

		if string.utf8len(physDesc) > 64 then
			return string.utf8sub(physDesc, 1, 61) .. "..."
		else
			return physDesc
		end
	else
		return "You do not recognise " .. thirdPerson .. "."
	end
end

--[[
	@codebase Client
	@details Called when the local player's character screen faction is needed.
	@param {Unknown} Missing description for character.
	@returns {Unknown}
--]]
function Clockwork:GetPlayerCharacterScreenFaction(character)
	return character.faction
end

--[[
	@codebase Client
	@details Called to get whether the local player's character screen is visible.
	@param {Unknown} Missing description for panel.
	@returns {Unknown}
--]]
function Clockwork:GetPlayerCharacterScreenVisible(panel)
	if not cwQuiz:GetEnabled() or cwQuiz:GetCompleted() then
		return true
	else
		return false
	end
end

--[[
	@codebase Client
	@details Called to get whether the character menu should be created.
	@returns {Unknown}
--]]
function Clockwork:ShouldCharacterMenuBeCreated()
	if self.ClockworkIntroFadeOut then return false end

	return true
end

--[[
	@codebase Client
	@details Called when the local player's character screen is created.
	@param {Unknown} Missing description for panel.
	@returns {Unknown}
--]]
function Clockwork:PlayerCharacterScreenCreated(panel)
	if cwQuiz:GetEnabled() then
		netstream.Start("GetQuizStatus", true)
	end
end

--[[
	@codebase Client
	@details Called when a player's scoreboard class is needed.
	@param {Unknown} Missing description for player.
	@returns {Unknown}
--]]
function Clockwork:GetPlayerScoreboardClass(player)
	return player:GetTeamClass().name
end

--[[
	@codebase Client
	@details Called when a player's scoreboard options are needed.
	@param {Unknown} Missing description for player.
	@param {Unknown} Missing description for options.
	@param {Unknown} Missing description for menu.
	@returns {Unknown}
--]]
function Clockwork:GetPlayerScoreboardOptions(player, options, menu)
	local charTakeFlags = cwCommand:FindByID("CharTakeFlags")
	local charGiveFlags = cwCommand:FindByID("CharGiveFlags")
	local charGiveItem = cwCommand:FindByID("CharGiveItem")
	local charSetName = cwCommand:FindByID("CharSetName")
	local plySetGroup = cwCommand:FindByID("PlySetGroup")
	local plyDemote = cwCommand:FindByID("PlyDemote")
	local charBan = cwCommand:FindByID("CharBan")
	local plyKick = cwCommand:FindByID("PlyKick")
	local plyBan = cwCommand:FindByID("PlyBan")

	if charBan and cwPly:HasFlags(cwClient, charBan.access) then
		options["BanCharacter"] = function()
			RunConsoleCommand("cw", "CharBan", player:Name())
		end
	end

	if plyKick and cwPly:HasFlags(cwClient, plyKick.access) then
		options["KickPlayer"] = function()
			Derma_StringRequest(player:Name(), L("KickPlayerReason"), nil, function(text)
				cwKernel:RunCommand("PlyKick", player:Name(), text)
			end)
		end
	end

	if plyBan and cwPly:HasFlags(cwClient, cwCommand:FindByID("PlyBan").access) then
		options["BanPlayer"] = function()
			Derma_StringRequest(player:Name(), L("BanPlayerTime"), nil, function(minutes)
				Derma_StringRequest(player:Name(), L("BanPlayerReason"), nil, function(reason)
					cwKernel:RunCommand("PlyBan", player:Name(), minutes, reason)
				end)
			end)
		end
	end

	if charGiveFlags and cwPly:HasFlags(cwClient, charGiveFlags.access) then
		options["GiveFlags"] = function()
			Derma_StringRequest(player:Name(), L("GiveFlagsHelp"), nil, function(text)
				cwKernel:RunCommand("CharGiveFlags", player:Name(), text)
			end)
		end
	end

	if charTakeFlags and cwPly:HasFlags(cwClient, charTakeFlags.access) then
		options["TakeFlags"] = function()
			Derma_StringRequest(player:Name(), L("TakeFlagsHelp"), player:GetNetVar("Flags"), function(text)
				cwKernel:RunCommand("CharTakeFlags", player:Name(), text)
			end)
		end
	end

	if charSetName and cwPly:HasFlags(cwClient, charSetName.access) then
		options["SetName"] = function()
			Derma_StringRequest(player:Name(), L("SetNameHelp"), player:Name(), function(text)
				cwKernel:RunCommand("CharSetName", player:Name(), text)
			end)
		end
	end

	if charGiveItem and cwPly:HasFlags(cwClient, charGiveItem.access) then
		options["GiveItem"] = function()
			Derma_StringRequest(player:Name(), L("GiveItemHelp"), nil, function(text)
				cwKernel:RunCommand("CharGiveItem", player:Name(), text)
			end)
		end
	end

	if plySetGroup and cwPly:HasFlags(cwClient, plySetGroup.access) then
		options["SetGroup"] = {}

		options["SetGroup"]["SuperAdmin"] = function()
			cwKernel:RunCommand("PlySetGroup", player:Name(), "superadmin")
		end

		options["SetGroup"]["Admin"] = function()
			cwKernel:RunCommand("PlySetGroup", player:Name(), "admin")
		end

		options["SetGroup"]["Operator"] = function()
			cwKernel:RunCommand("PlySetGroup", player:Name(), "operator")
		end
	end

	if plyDemote and cwPly:HasFlags(cwClient, plyDemote.access) then
		options["Demote"] = function()
			cwKernel:RunCommand("PlyDemote", player:Name())
		end
	end

	local canUwhitelist = false
	local canWhitelist = false
	local unwhitelist = cwCommand:FindByID("PlyUnwhitelist")
	local whitelist = cwCommand:FindByID("PlyWhitelist")

	if whitelist and cwPly:HasFlags(cwClient, whitelist.access) then
		canWhitelist = true
	end

	if unwhitelist and cwPly:HasFlags(cwClient, unwhitelist.access) then
		canUnwhitelist = true
	end

	if canWhitelist or canUwhitelist then
		local areWhitelistFactions = false

		for k, v in pairs(cwFaction:GetAll()) do
			if v.whitelist then
				areWhitelistFactions = true
			end
		end

		if areWhitelistFactions then
			if canWhitelist then
				options["Whitelist"] = {}
			end

			if canUwhitelist then
				options["Unwhitelist"] = {}
			end

			for k, v in pairs(cwFaction:GetAll()) do
				if v.whitelist then
					if options["Whitelist"] then
						options["Whitelist"][k] = function()
							cwKernel:RunCommand("PlyWhitelist", player:Name(), k)
						end
					end

					if options["Unwhitelist"] then
						options["Unwhitelist"][k] = function()
							cwKernel:RunCommand("PlyUnwhitelist", player:Name(), k)
						end
					end
				end
			end
		end
	end
end

--[[
	@codebase Client
	@details Called when information about a door is needed.
	@param {Unknown} Missing description for door.
	@param {Unknown} Missing description for information.
	@returns {Unknown}
--]]
function Clockwork:GetDoorInfo(door, information)
	local doorCost = cwConfig:Get("door_cost"):Get()
	local owner = cwEntity:GetOwner(door)
	local text = cwEntity:GetDoorText(door)
	local name = cwEntity:GetDoorName(door)

	if information == DOOR_INFO_NAME then
		if cwEntity:IsDoorHidden(door) or cwEntity:IsDoorFalse(door) then
			return false
		elseif name == "" then
			return "Door"
		else
			return name
		end
	elseif information == DOOR_INFO_TEXT then
		if cwEntity:IsDoorUnownable(door) then
			if not cwEntity:IsDoorHidden(door) and not cwEntity:IsDoorFalse(door) then
				if text == "" then
					return "UnownableDoorText"
				else
					return text
				end
			else
				return false
			end
		elseif text ~= "" then
			if not IsValid(owner) then
				if doorCost > 0 then
					return "PurchasableDoorText"
				else
					return "OwnableDoorText"
				end
			else
				return text
			end
		elseif IsValid(owner) then
			if doorCost > 0 then
				return "PurchasedDoorText"
			else
				return "OwnedDoorText"
			end
		elseif doorCost > 0 then
			return "PurchasableDoorText"
		else
			return "OwnableDoorText"
		end
	end
end

--[[
	@codebase Client
	@details Called to get whether or not a post process is permitted.
	@param {Unknown} Missing description for class.
	@returns {Unknown}
--]]
function Clockwork:PostProcessPermitted(class)
	return false
end

--[[
	@codebase Client
	@details Called just after the translucent renderables have been drawn.
	@param {Unknown} Missing description for bDrawingDepth.
	@param {Unknown} Missing description for bDrawingSkybox.
	@returns {Unknown}
--]]
function Clockwork:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
	if bDrawingSkybox or bDrawingDepth then return end
	local colorWhite = cwOption:GetColor("white")
	local colorInfo = cwOption:GetColor("information")
	local doorFont = cwOption:GetFont("large_3d_2d")
	local eyeAngles = EyeAngles()
	local eyePos = EyePos()

	if not cwKernel:IsChoosingCharacter() then
		cam.Start3D(eyePos, eyeAngles)
		local entities = ents.FindInSphere(eyePos, 256)

		for k, v in pairs(entities) do
			if IsValid(v) and cwEntity:IsDoor(v) then
				cwKernel:DrawDoorText(v, eyePos, eyeAngles, doorFont, colorInfo, colorWhite)
			end
		end

		cam.End3D()
	end
end

--[[
	@codebase Client
	@details Called when screen space effects should be rendered.
	@returns {Unknown}
--]]
function Clockwork:RenderScreenspaceEffects()
	if IsValid(cwClient) then
		local frameTime = FrameTime()

		local motionBlurs = {
			enabled = true,
			blurTable = {}
		}

		local color = 1
		local isDrunk = cwPly:GetDrunk()

		if not cwKernel:IsChoosingCharacter() then
			if cwLimb:IsActive() then
				local headDamage = cwLimb:GetDamage(HITGROUP_HEAD)
				motionBlurs.blurTable["health"] = math.Clamp(1 - headDamage * 0.01, 0, 1)
			elseif cwClient:Health() <= 25 then
				motionBlurs.blurTable["health"] = math.Clamp(1 - (cwClient:GetMaxHealth() - cwClient:Health()) * 0.01, 0, 1)
			end

			if cwClient:Alive() then
				color = math.Clamp(color - (cwClient:GetMaxHealth() - cwClient:Health()) * 0.01, 0, color)
			else
				color = 0
			end

			if isDrunk and self.DrunkBlur then
				self.DrunkBlur = math.Clamp(self.DrunkBlur - frameTime / 10, math.max(1 - isDrunk / 8, 0.1), 1)
				DrawMotionBlur(self.DrunkBlur, 1, 0)
			elseif self.DrunkBlur and self.DrunkBlur < 1 then
				self.DrunkBlur = math.Clamp(self.DrunkBlur + frameTime / 10, 0.1, 1)
				motionBlurs.blurTable["isDrunk"] = self.DrunkBlur
			else
				self.DrunkBlur = 1
			end
		end

		if self.FishEyeTexture and cwClient:WaterLevel() > 2 then
			render.UpdateScreenEffectTexture()
			self.FishEyeTexture:SetFloat("$envmap", 0)
			self.FishEyeTexture:SetFloat("$envmaptint", 0)
			self.FishEyeTexture:SetFloat("$refractamount", 0.1)
			self.FishEyeTexture:SetInt("$ignorez", 1)
			render.SetMaterial(self.FishEyeTexture)
			render.DrawScreenQuad()
		end

		self.ColorModify["$pp_colour_brightness"] = 0
		self.ColorModify["$pp_colour_contrast"] = 1
		self.ColorModify["$pp_colour_colour"] = color
		self.ColorModify["$pp_colour_addr"] = 0
		self.ColorModify["$pp_colour_addg"] = 0
		self.ColorModify["$pp_colour_addb"] = 0
		self.ColorModify["$pp_colour_mulr"] = 0
		self.ColorModify["$pp_colour_mulg"] = 0
		self.ColorModify["$pp_colour_mulb"] = 0

		local systemTable = self.system:FindByID("ColorModify")
		local overrideColorMod

		if systemTable then
			overrideColorMod = systemTable:GetModifyTable()
		end

		if overrideColorMod and overrideColorMod.enabled then
			self.ColorModify["$pp_colour_brightness"] = overrideColorMod.brightness
			self.ColorModify["$pp_colour_contrast"] = overrideColorMod.contrast
			self.ColorModify["$pp_colour_colour"] = overrideColorMod.color
			self.ColorModify["$pp_colour_addr"] = overrideColorMod.addr * 0.025
			self.ColorModify["$pp_colour_addg"] = overrideColorMod.addg * 0.025
			self.ColorModify["$pp_colour_addb"] = overrideColorMod.addg * 0.025
			self.ColorModify["$pp_colour_mulr"] = overrideColorMod.mulr * 0.1
			self.ColorModify["$pp_colour_mulg"] = overrideColorMod.mulg * 0.1
			self.ColorModify["$pp_colour_mulb"] = overrideColorMod.mulb * 0.1
		else
			cwPlugin:Call("PlayerSetDefaultColorModify", self.ColorModify)
		end

		cwPlugin:Call("PlayerAdjustColorModify", self.ColorModify)
		cwPlugin:Call("PlayerAdjustMotionBlurs", motionBlurs)

		if motionBlurs.enabled then
			local addAlpha = nil

			for k, v in pairs(motionBlurs.blurTable) do
				if not addAlpha or v < addAlpha then
					addAlpha = v
				end
			end

			if addAlpha then
				DrawMotionBlur(math.Clamp(addAlpha, 0.1, 1), 1, 0)
			end
		end

		--[[
			Hotfix for ColorModify issues on OS X.
		--]]
		if system.IsOSX() then
			self.ColorModify["$pp_colour_brightness"] = 0
			self.ColorModify["$pp_colour_contrast"] = 1
		end

		DrawColorModify(self.ColorModify)
	end
end

--[[
	@codebase Client
	@details Called when the chat box is opened.
	@returns {Unknown}
--]]
function Clockwork:ChatBoxOpened()
end

--[[
	@codebase Client
	@details Called when the chat box is closed.
	@returns {Unknown}
--]]
function Clockwork:ChatBoxClosed(textTyped)
end

--[[
	@codebase Client
	@details Called when the chat box text has been typed.
	@param {Unknown} Missing description for text.
	@returns {Unknown}
--]]
function Clockwork:ChatBoxTextTyped(text)
	if self.LastChatBoxText then
		if self.LastChatBoxText[1] == text then return end

		if #self.LastChatBoxText >= 25 then
			table.remove(self.LastChatBoxText, 25)
		end
	else
		self.LastChatBoxText = {}
	end

	table.insert(self.LastChatBoxText, 1, text)
end

--[[
	@codebase Client
	@details Called when the calc view table should be adjusted.
	@returns {Unknown}
--]]
function Clockwork:CalcViewAdjustTable(view)
end

--[[
	@codebase Client
	@details Called when the chat box info should be adjusted.
	@returns {Unknown}
--]]
function Clockwork:ChatBoxAdjustInfo(info)
end

--[[
	@codebase Client
	@details Called when the chat box text has changed.
	@returns {Unknown}
--]]
function Clockwork:ChatBoxTextChanged(previousText, newText)
end

--[[
	@codebase Client
	@details Called when the chat box has had a key code typed in.
	@param {Unknown} Missing description for code.
	@param {Unknown} Missing description for text.
	@returns {Unknown}
--]]
function Clockwork:ChatBoxKeyCodeTyped(code, text)
	if code == KEY_UP then
		if self.LastChatBoxText then
			for k, v in pairs(self.LastChatBoxText) do
				if v == text and self.LastChatBoxText[k + 1] then return self.LastChatBoxText[k + 1] end
			end

			if self.LastChatBoxText[1] then return self.LastChatBoxText[1] end
		end
	elseif code == KEY_DOWN then
		if self.LastChatBoxText then
			for k, v in pairs(self.LastChatBoxText) do
				if v == text and self.LastChatBoxText[k - 1] then return self.LastChatBoxText[k - 1] end
			end

			if #self.LastChatBoxText > 0 then return self.LastChatBoxText[#self.LastChatBoxText] end
		end
	end
end

--[[
	@codebase Client
	@details Called when a notification should be adjusted.
	@param {Unknown} Missing description for info.
	@returns {Unknown}
--]]
function Clockwork:NotificationAdjustInfo(info)
	return true
end

--[[
	@codebase Client
	@details Called when the local player's business item should be adjusted.
	@returns {Unknown}
--]]
function Clockwork:PlayerAdjustBusinessItemTable(itemTable)
end

--[[
	@codebase Client
	@details Called when the local player's class model info should be adjusted.
	@returns {Unknown}
--]]
function Clockwork:PlayerAdjustClassModelInfo(class, info)
end

--[[
	@codebase Client
	@details Called when the local player's headbob info should be adjusted.
	@param {Unknown} Missing description for info.
	@returns {Unknown}
--]]
function Clockwork:PlayerAdjustHeadbobInfo(info)
	local bIsDrunk = cwPly:GetDrunk()
	local scale = math.Clamp(CW_CONVAR_HEADBOBSCALE:GetFloat(), 0, 1) or 1

	if cwClient:IsRunning() then
		info.speed = (info.speed * 4) * scale
		info.roll = (info.roll * 2) * scale
	elseif cwClient:GetVelocity():Length() > 0 then
		info.speed = (info.speed * 3) * scale
		info.roll = (info.roll * 1) * scale
	else
		info.roll = info.roll * scale
	end

	if bIsDrunk then
		info.speed = info.speed * math.min(bIsDrunk * 0.25, 2)
		info.yaw = info.yaw * math.min(bIsDrunk, 4)
		info.roll = info.roll * (10 + bIsDrunk)
	end
end

--[[
	@codebase Client
	@details Called when the local player's motion blurs should be adjusted.
	@returns {Unknown}
--]]
function Clockwork:PlayerAdjustMotionBlurs(motionBlurs)
end

--[[
	@codebase Client
	@details Called when the local player's item menu should be adjusted.
	@returns {Unknown}
--]]
function Clockwork:PlayerAdjustMenuFunctions(itemTable, menuPanel, itemFunctions)
end

--[[
	@codebase Client
	@details Called when the local player's item functions should be adjusted.
	@returns {Unknown}
--]]
function Clockwork:PlayerAdjustItemFunctions(itemTable, itemFunctions)
end

--[[
	@codebase Client
	@details Called when the local player's default colorify should be set.
	@returns {Unknown}
--]]
function Clockwork:PlayerSetDefaultColorModify(colorModify)
end

--[[
	@codebase Client
	@details Called when the local player's colorify should be adjusted.
	@returns {Unknown}
--]]
function Clockwork:PlayerAdjustColorModify(colorModify)
end

--[[
	@codebase Client
	@details Called to get whether a player's target ID should be drawn.
	@param {Unknown} Missing description for player.
	@returns {Unknown}
--]]
function Clockwork:ShouldDrawPlayerTargetID(player)
	return true
end

--[[
	@codebase Client
	@details Called to get whether the local player's screen should fade black.
	@returns {Unknown}
--]]
function Clockwork:ShouldPlayerScreenFadeBlack()
	if not cwClient:Alive() or cwClient:IsRagdolled(RAGDOLL_FALLENOVER) then
		if not cwPlugin:Call("PlayerCanSeeUnconscious") then return true end
	end

	return false
end

--[[
	@codebase Client
	@details Called when the menu background blur should be drawn.
	@returns {Unknown}
--]]
function Clockwork:ShouldDrawMenuBackgroundBlur()
	return true
end

--[[
	@codebase Client
	@details Called when the character background blur should be drawn.
	@returns {Unknown}
--]]
function Clockwork:ShouldDrawCharacterBackgroundBlur()
	return true
end

--[[
	@codebase Client
	@details Called when the character background should be drawn.
	@returns {Unknown}
--]]
function Clockwork:ShouldDrawCharacterBackground()
	return true
end

--[[
	@codebase Client
	@details Called when the character fault should be drawn.
	@param {Unknown} Missing description for fault.
	@returns {Unknown}
--]]
function Clockwork:ShouldDrawCharacterFault(fault)
	return true
end

--[[
	@codebase Client
	@details Called when the score board should be drawn.
	@returns {Unknown}
--]]
function Clockwork:HUDDrawScoreBoard()
	self.BaseClass:HUDDrawScoreBoard(player)
	local drawPendingScreenBlack = nil
	local drawCharacterLoading = nil
	local hasClientInitialized = cwClient:HasInitialized()
	local introTextSmallFont = cwOption:GetFont("intro_text_small")
	local colorWhite = cwOption:GetColor("white")
	local curTime = UnPredictedCurTime()
	local scrH = ScrH()
	local scrW = ScrW()

	if cwKernel:IsChoosingCharacter() then
		if cwPlugin:Call("ShouldDrawCharacterBackground") then
			cwKernel:DrawSimpleGradientBox(0, 0, 0, ScrW(), ScrH(), Color(0, 0, 0, 255))
		end

		cwPlugin:Call("HUDPaintCharacterSelection")
	elseif not hasClientInitialized then
		if not self.HasCharacterMenuBeenVisible and cwPlugin:Call("ShouldDrawCharacterBackground") then
			drawPendingScreenBlack = true
		end
	end

	if hasClientInitialized then
		if not self.CharacterLoadingFinishTime then
			local loadingTime = cwPlugin:Call("GetCharacterLoadingTime")
			self.CharacterLoadingDelay = loadingTime
			self.CharacterLoadingFinishTime = curTime + loadingTime
		end

		if not cwKernel:IsChoosingCharacter() then
			cwKernel:CalculateScreenFading()

			if not cwKernel:IsUsingCamera() then
				cwPlugin:Call("HUDPaintForeground")
			end

			cwPlugin:Call("HUDPaintImportant")
		end

		if self.CharacterLoadingFinishTime > curTime then
			drawCharacterLoading = true
		elseif not self.CinematicScreenDone then
			cwKernel:DrawCinematicIntro(curTime)
		end
	end

	if cwPlugin:Call("ShouldDrawBackgroundBlurs") then
		cwKernel:DrawBackgroundBlurs()
	end

	if not cwPly:HasInfoStreamed() then
		if not self.InfoStreamedAlpha then
			self.InfoStreamedAlpha = 255
		end
	elseif self.InfoStreamedAlpha then
		self.InfoStreamedAlpha = math.Approach(self.InfoStreamedAlpha, 0, FrameTime() * 100)

		if self.InfoStreamedAlpha <= 0 then
			self.InfoStreamedAlpha = nil
		end
	end

	if self.ClockworkIntroFadeOut then
		local duration = 8
		local introImage = cwOption:GetKey("intro_image")

		if introImage ~= "" then
			duration = 16
		end

		local timeLeft = math.Clamp(self.ClockworkIntroFadeOut - curTime, 0, duration)
		local material = self.ClockworkIntroOverrideImage or self.ClockworkSplash
		local sineWave = math.sin(curTime)
		local height = 256
		local width = 512 --Patched
		local alpha = 384

		if not self.ClockworkIntroOverrideImage then
			if introImage ~= "" and timeLeft <= 8 then
				self.ClockworkIntroWhiteScreen = curTime + FrameTime() * 8
				self.ClockworkIntroOverrideImage = cwKernel:GetMaterial(introImage .. ".png")
				surface.PlaySound("buttons/combine_button5.wav")
			end
		end

		if timeLeft <= 3 then
			alpha = (255 / 3) * timeLeft
		end

		if timeLeft == 0 then
			self.ClockworkIntroFadeOut = nil
			self.ClockworkIntroOverrideImage = nil
		end

		if sineWave > 0 then
			width = width - sineWave * 16
			height = height - sineWave * 4
		end

		if curTime <= self.ClockworkIntroWhiteScreen then
			cwKernel:DrawSimpleGradientBox(0, 0, 0, scrW, scrH, Color(255, 255, 255, alpha))
		else
			local x, y = scrW / 2 - width / 2, scrH * 0.3 - height / 2
			cwKernel:DrawSimpleGradientBox(0, 0, 0, scrW, scrH, Color(0, 0, 0, alpha))
			cwKernel:DrawGradient(GRADIENT_CENTER, 0, y - 8, scrW, height + 16, Color(100, 100, 100, math.min(alpha, 150)))
			material:SetFloat("$alpha", alpha / 255)
			surface.SetDrawColor(255, 255, 255, alpha)
			surface.SetMaterial(material)
			surface.DrawTexturedRect(x, y, width, height)
		end

		drawPendingScreenBlack = nil
	end

	if cwKernel:GetNetVar("NoMySQL") and cwKernel:GetNetVar("NoMySQL") ~= "" then
		cwKernel:DrawSimpleGradientBox(0, 0, 0, scrW, scrH, Color(0, 0, 0, 255))
		draw.SimpleText(cwKernel:GetNetVar("NoMySQL"), introTextSmallFont, scrW / 2, scrH / 2, Color(179, 46, 49, 255), 1, 1)
	elseif self.InfoStreamedAlpha and self.InfoStreamedAlpha > 0 then
		cwKernel:DrawSimpleGradientBox(0, 0, 0, scrW, scrH, Color(0, 0, 0, self.InfoStreamedAlpha))
		drawPendingScreenBlack = nil
	end

	if drawCharacterLoading then
		cwPlugin:Call("HUDPaintCharacterLoading", math.Clamp((255 / self.CharacterLoadingDelay) * (self.CharacterLoadingFinishTime - curTime), 0, 255))
	elseif drawPendingScreenBlack then
		cwKernel:DrawSimpleGradientBox(0, 0, 0, ScrW(), ScrH(), Color(0, 0, 0, 255))
	end

	if self.CharacterLoadingFinishTime then
		if not self.CinematicInfoDrawn then
			cwKernel:DrawCinematicInfo()
		end
	end

	cwPlugin:Call("PostDrawBackgroundBlurs")
end

--[[
	@codebase Client
	@details Called when the background blurs should be drawn.
	@returns {Unknown}
--]]
function Clockwork:ShouldDrawBackgroundBlurs()
	return true
end

--[[
	@codebase Client
	@details Called just after the background blurs have been drawn.
	@returns {Unknown}
--]]
function Clockwork:PostDrawBackgroundBlurs()
--	local introTextSmallFont = cwOption:GetFont("intro_text_small")
	local position = self.plugin:Call("GetChatBoxPosition")
	if position then
		cwChatBox:SetCustomPosition(position.x, position.y)
	end
	local backgroundColor = cwOption:GetColor("background")
	local colorWhite = cwOption:GetColor("white")
	local panelInfo = self.CurrentFactionSelected
--	local menuPanel = cwKernel:GetRecogniseMenu()

	if panelInfo and IsValid(panelInfo[1]) and panelInfo[1]:IsVisible() then
		local factionTable = cwFaction:FindByID(panelInfo[2])

		if factionTable and factionTable.material then
			if _file.Exists("materials/" .. factionTable.material .. ".png", "GAME") then
				if not panelInfo[3] then
					panelInfo[3] = cwKernel:GetMaterial(factionTable.material .. ".png")
				end

				if cwKernel:IsCharacterScreenOpen(true) then
					surface.SetDrawColor(255, 255, 255, panelInfo[1]:GetAlpha())
					surface.SetMaterial(panelInfo[3])
					surface.DrawTexturedRect(panelInfo[1].x, panelInfo[1].y + panelInfo[1]:GetTall() + 16, 512, 256)
				end
			end
		end
	end

	if self.TitledMenu and IsValid(self.TitledMenu.menuPanel) then
		local menuTextTiny = cwOption:GetFont("menu_text_tiny")
		local menuPanel = self.TitledMenu.menuPanel
		local menuTitle = self.TitledMenu.title
		cwKernel:DrawSimpleGradientBox(2, menuPanel.x - 4, menuPanel.y - 4, menuPanel:GetWide() + 8, menuPanel:GetTall() + 8, backgroundColor)
		cwKernel:OverrideMainFont(menuTextTiny)
		cwKernel:DrawInfo(menuTitle, menuPanel.x, menuPanel.y, colorWhite, 255, true, function(x, y, width, height) return x, y - height - 4 end)
		cwKernel:OverrideMainFont(false)
	end

	cwKernel:DrawDateTime()
end

--[[
	@codebase Client
	@details Called just before a bar is drawn.
	@returns {Unknown}
--]]
function Clockwork:PreDrawBar(barInfo)
end

--[[
	@codebase Client
	@details Called just after a bar is drawn.
	@returns {Unknown}
--]]
function Clockwork:PostDrawBar(barInfo)
end

--[[
	@codebase Client
	@details Called when the top bars are needed.
	@returns {Unknown}
--]]
function Clockwork:GetBars(bars)
end

function Clockwork:GetChatBoxPosition()
	return {x = 8, y = ScrH() - 40}
end

--[[
	@codebase Client
	@details Called when the top bars should be destroyed.
	@returns {Unknown}
--]]
function Clockwork:DestroyBars(bars)
end

--[[
	@codebase Client
	@details Called when the cinematic intro info is needed.
	@returns {Unknown}
--]]
function Clockwork:GetCinematicIntroInfo()
	return {
		credits = "A roleplaying game designed by " .. Schema:GetAuthor() .. ".",
		title = L(Schema:GetName()),
		text = L(Schema:GetDescription())
	}
end

--[[
	@codebase Client
	@details Called when the character loading time is needed.
	@returns {Unknown}
--]]
function Clockwork:GetCharacterLoadingTime()
	return 8
end

--[[
	@codebase Client
	@details Called when a player's HUD should be painted.
	@returns {Unknown}
--]]
function Clockwork:HUDPaintPlayer(player)
end

--[[
	@codebase Client
	@details Called when the HUD should be painted.
	@returns {Unknown}
--]]
function Clockwork:HUDPaint()
	if not cwKernel:IsChoosingCharacter() and not cwKernel:IsUsingCamera() then
		if cwClient:Alive() then
			local health = cwClient:Health()
			local maxHealth = cwClient:GetMaxHealth() * 0.5

			if health < maxHealth then
				cwPlugin:Call("DrawPlayerScreenDamage", 1 - (health / maxHealth))
			end
		end

		if cwConfig:Get("enable_vignette"):Get() then
			cwPlugin:Call("DrawPlayerVignette")
		end

		local weapon = cwClient:GetActiveWeapon()
		self.BaseClass:HUDPaint()

		if not cwKernel:IsScreenFadedBlack() then
			for k, v in ipairs(_player.GetAll()) do
				if v:HasInitialized() and v ~= cwClient then
					cwPlugin:Call("HUDPaintPlayer", v)
				end
			end
		end

		if not cwKernel:IsUsingTool() then
			cwKernel:DrawHints()
		end

		if IsValid(weapon) and (cwConfig:Get("enable_crosshair"):Get() or cwKernel:IsDefaultWeapon(weapon) or weapon.cwDrawCrosshair) then
			local info = {
				color = Color(255, 255, 255, 255),
				x = ScrW() / 2,
				y = ScrH() / 2,
			}

			cwPlugin:Call("GetPlayerCrosshairInfo", info)
			self.CustomCrosshair = cwPlugin:Call("DrawPlayerCrosshair", info.x, info.y, info.color)
		else
			self.CustomCrosshair = false
		end
	end
end

function Clockwork:CanDrawCrosshair(weapon)
	return (CW_CONVAR_CROSSHAIR:GetInt() == 1 or cwKernel:IsDefaultWeapon(weapon)) and (IsValid(weapon) and weapon.DrawCrosshair ~= false)
end

--[[
	@codebase Client
	@details Called when the local player's crosshair info is needed.
	@param {Unknown} Missing description for info.
	@returns {Unknown}
--]]
function Clockwork:GetPlayerCrosshairInfo(info)
	if CW_CONVAR_CROSSHAIRDYNAMIC:GetInt() == 1 then
		-- Thanks to BlackOps7799 for this open source example.
		local traceLine = util.TraceLine({
			start = cwClient:EyePos(),
			endpos = cwClient:EyePos() + cwClient:GetAimVector() * 1024 * 1024,
			filter = cwClient
		})

		local screenPos = traceLine.HitPos:ToScreen()
		info.x = screenPos.x
		info.y = screenPos.y
	end
end

--[[
	@codebase Client
	@details Called when the local player's crosshair should be drawn.
	@param {Unknown} Missing description for x.
	@param {Unknown} Missing description for y.
	@param {Unknown} Missing description for color.
	@returns {Unknown}
--]]
function Clockwork:DrawPlayerCrosshair(x, y, color)
	surface.SetDrawColor(color.r, color.g, color.b, color.a)
	surface.DrawRect(x, y, 2, 2)
	surface.DrawRect(x, y + 9, 2, 2)
	surface.DrawRect(x, y - 9, 2, 2)
	surface.DrawRect(x + 9, y, 2, 2)
	surface.DrawRect(x - 9, y, 2, 2)

	return true
end

--[[
	@codebase Client
	@details Called when a player starts using voice.
	@param {Unknown} Missing description for player.
	@returns {Unknown}
--]]
function Clockwork:PlayerStartVoice(player)
	if cwConfig:Get("local_voice"):Get() then
		if player:IsRagdolled(RAGDOLL_FALLENOVER) or not player:Alive() then return end
	end

	if self.BaseClass and self.BaseClass.PlayerStartVoice then
		self.BaseClass:PlayerStartVoice(player)
	end
end

--[[
	@codebase Client
	@details Called to check if a player does have an flag.
	@param {Unknown} Missing description for player.
	@param {Unknown} Missing description for flag.
	@returns {Unknown}
--]]
function Clockwork:PlayerDoesHaveFlag(player, flag)
	if string.find(cwConfig:Get("default_flags"):Get(), flag) then return true end
end

--[[
	@codebase Client
	@details Called to check if a player does recognise another player.
	@param {Unknown} Missing description for player.
	@param {Unknown} Missing description for status.
	@param {Unknown} Missing description for isAccurate.
	@param {Unknown} Missing description for realValue.
	@returns {Unknown}
--]]
function Clockwork:PlayerDoesRecognisePlayer(player, status, isAccurate, realValue)
	return realValue
end

--[[
	@codebase Client
	@details Called when a player's name should be shown as unrecognised.
	@param {Unknown} Missing description for player.
	@param {Unknown} Missing description for x.
	@param {Unknown} Missing description for y.
	@param {Unknown} Missing description for color.
	@param {Unknown} Missing description for alpha.
	@param {Unknown} Missing description for flashAlpha.
	@returns {Unknown}
--]]
function Clockwork:PlayerCanShowUnrecognised(player, x, y, color, alpha, flashAlpha)
	return true
end

--[[
	@codebase Client
	@details Called when the target player's name is needed.
	@param {Unknown} Missing description for player.
	@returns {Unknown}
--]]
function Clockwork:GetTargetPlayerName(player)
	return player:Name()
end

--[[
	@codebase Client
	@details Called when a player begins typing.
	@param {Unknown} Missing description for team.
	@returns {Unknown}
--]]
function Clockwork:StartChat(team)
	return true
end

--[[
	@codebase Client
	@details Called when a player says something.
	@param {Unknown} Missing description for player.
	@param {Unknown} Missing description for text.
	@param {Unknown} Missing description for teamOnly.
	@param {Unknown} Missing description for playerIsDead.
	@returns {Unknown}
--]]
function Clockwork:OnPlayerChat(player, text, teamOnly, playerIsDead)
	if IsValid(player) then
		cwChatBox:Decode(player, player:Name(), text, {}, "none")
	else
		cwChatBox:Decode(nil, "Console", text, {}, "chat")
	end

	return true
end

--[[
	@codebase Client
	@details Called when chat text is received from the server
	@param {Unknown} Missing description for index.
	@param {Unknown} Missing description for name.
	@param {Unknown} Missing description for text.
	@param {Unknown} Missing description for class.
	@returns {Unknown}
--]]
function Clockwork:ChatText(index, name, text, class)
	if class == "none" then
		cwChatBox:Decode(_player.GetByID(index), name, text, {}, "none")
	end

	return true
end

--[[
	@codebase Client
	@details Called when the scoreboard should be created.
	@returns {Unknown}
--]]
function Clockwork:CreateScoreboard()
end

--[[
	@codebase Client
	@details Called when the scoreboard should be shown.
	@returns {Unknown}
--]]
function Clockwork:ScoreboardShow()
	if cwClient:HasInitialized() then
		if cwPlugin:Call("CanShowTabMenu") then
			cwMenu:Create(true)
			cwMenu.holdTime = UnPredictedCurTime() + 0.5
		end
	end
end

--[[
	@codebase Client
	@details Called when the scoreboard should be hidden.
	@returns {Unknown}
--]]
function Clockwork:ScoreboardHide()
	if cwClient:HasInitialized() and cwMenu.holdTime then
		if UnPredictedCurTime() >= cwMenu.holdTime then
			cwMenu:SetOpen(false)
		end
	end
end

--[[
	@codebase Client
	@details Called before the tab menu is shown.
	@returns {Unknown}
--]]
function Clockwork:CanShowTabMenu()
	return true
end

--[[
	@codebase Client
	@details Overriding Garry's "grab ear" animation.
	@returns {Unknown}
--]]
function Clockwork:GrabEarAnimation(player)
end

--[[
	@codebase Client
	@details Called before the item entity's target ID is drawn. Return false to stop default draw.
	@returns {Unknown}
--]]
function Clockwork:PaintItemTargetID(x, y, alpha, itemTable)
	return true
end

concommand.Add("cwSay", function(player, command, arguments) return netstream.Start("PlayerSay", table.concat(arguments, " ")) end)

concommand.Add("cwLua", function(player, command, arguments)
	if player:IsSuperAdmin() then
		RunString(table.concat(arguments, " "))

		return
	end

	print("You do not have access to this command, " .. player:Name() .. ".")
end)

Clockwork.kernel:IncludePrefixed("meta/cl_entity.lua")
Clockwork.kernel:IncludePrefixed("meta/cl_weapon.lua")
Clockwork.kernel:IncludePrefixed("meta/cl_player.lua")