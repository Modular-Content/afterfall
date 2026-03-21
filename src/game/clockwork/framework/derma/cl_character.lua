local Clockwork = Clockwork

local pairs = pairs
local ScrH = ScrH
local ScrW = ScrW
local table = table
local string = string
local vgui = vgui
local math = math

local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	if not Clockwork.theme:Call("PreCharacterMenuInit", self) then
		local smallTextFont = Clockwork.option:GetFont("menu_text_small")
		local tinyTextFont = Clockwork.option:GetFont("menu_text_tiny")
		local hugeTextFont = Clockwork.option:GetFont("menu_text_huge")

		local scrH = ScrH()
		local scrW = ScrW()

		self:SetPos(0, 0)
		self:SetSize(scrW, scrH)
		self:SetDrawOnTop(false)
		self:SetFocusTopLevel(true)
		self:SetPaintBackground(false)
		self:SetMouseInputEnabled(true)

		self.titleLabel = vgui.Create("cwLabelButton", self)
		self.titleLabel:SetDisabled(true)
		self.titleLabel:SetFont(hugeTextFont)

		self.subLabel = vgui.Create("cwLabelButton", self)
		self.subLabel:SetDisabled(true)
		self.subLabel:SetFont(smallTextFont)

		self.authorLabel = vgui.Create("cwLabelButton", self)
		self.authorLabel:SetDisabled(true)
		self.authorLabel:SetFont(tinyTextFont)

		self.createButton = vgui.Create("cwLabelButton", self)
		self.createButton:SetFont(smallTextFont)
		self.createButton:FadeIn(0.5)

		self.createButton:SetCallback(function(panel)
			if table.Count(Clockwork.character:GetAll()) >= Clockwork.player:GetMaximumCharacters() then
				return Clockwork.character:SetFault({"FaultTooManyCharacters"})
			end

			Clockwork.character:ResetCreationInfo()
			Clockwork.character:OpenNextCreationPanel()
		end)

		self.createButton:SetMouseInputEnabled(true)
		self.loadButton = vgui.Create("cwLabelButton", self)
		self.loadButton:SetFont(smallTextFont)
		self.loadButton:FadeIn(0.5)

		self.loadButton:SetCallback(function(panel)
			self:OpenPanel("cwCharacterList", nil, function(panel)
				Clockwork.character:RefreshPanelList()
			end)
		end)

		self.loadButton:SetMouseInputEnabled(true)

		self.aboutButton = vgui.Create("cwLabelButton", self)
		self.aboutButton:SetFont(smallTextFont)
		self.aboutButton:SetAlpha(0)
		self.aboutButton:FadeIn(1)
		
		self.aboutButton:SetCallback(function(panel)
			gui.OpenURL('https://modularcontent.dev/modularwork/')
		end)

		self.aboutButton:SetMouseInputEnabled(true)

		self.disconnectButton = vgui.Create("cwLabelButton", self)
		self.disconnectButton:SetFont(smallTextFont)
		self.disconnectButton:FadeIn(0.5)

		self.disconnectButton:SetCallback(function(panel)
			if Clockwork.Client:HasInitialized() and not Clockwork.character:IsMenuReset() then
				Clockwork.character:SetPanelMainMenu()
				Clockwork.character:SetPanelOpen(false)
			else
				RunConsoleCommand("disconnect")
			end
		end)

		self.disconnectButton:SetMouseInputEnabled(true)
		self.previousButton = vgui.Create("cwLabelButton", self)
		self.previousButton:SetFont(tinyTextFont)

		self.previousButton:SetCallback(function(panel)
			if not Clockwork.character:IsCreationProcessActive() then
				local activePanel = Clockwork.character:GetActivePanel()

				if activePanel and activePanel.OnPrevious then
					activePanel:OnPrevious()
				end
			else
				Clockwork.character:OpenPreviousCreationPanel()
			end
		end)

		self.previousButton:SetMouseInputEnabled(true)
		self.nextButton = vgui.Create("cwLabelButton", self)
		self.nextButton:SetFont(tinyTextFont)

		self.nextButton:SetCallback(function(panel)
			if not Clockwork.character:IsCreationProcessActive() then
				local activePanel = Clockwork.character:GetActivePanel()

				if activePanel and activePanel.OnNext then
					activePanel:OnNext()
				end
			else
				Clockwork.character:OpenNextCreationPanel()
			end
		end)

		self.nextButton:SetMouseInputEnabled(true)
		self.cancelButton = vgui.Create("cwLabelButton", self)
		self.cancelButton:SetFont(tinyTextFont)

		self.cancelButton:SetCallback(function(panel)
			self:ReturnToMainMenu()
		end)

		self.cancelButton:SetMouseInputEnabled(true)

		local modelSize = ScrH() * 0.7

		self.characterModel = vgui.Create("cwCharacterModel", self)
		-- self.characterModel:SetAlpha(0)
		self.characterModel:SetSize(modelSize, modelSize) -- TBD: Remove this for new cam pos
		-- self.characterModel:SetModel("models/error.mdl")
		self.createTime = SysTime()
		Clockwork.theme:Call("PostCharacterMenuInit", self)
		self:ResetTextAndPositions()

		cvars.AddChangeCallback("cwLang", function()
			self:ResetTextAndPositions()
		end)
	end
end

-- A function to reset text and positions.
function PANEL:ResetTextAndPositions()
	local scrH = ScrH()
	local scrW = ScrW()

	self.titleLabel:SetText('')
	self.subLabel:SetText(string.upper(L("CharacterMenuSubTitle")))
	self.subLabel:SizeToContents()

	local schemaLogo = Clockwork.option:GetKey("schema_logo")

	if schemaLogo == "" then
		self.titleLabel:SetVisible(true)
		self.titleLabel:SizeToContents()
		self.titleLabel:SetPos(scrW / 2 - self.titleLabel:GetWide() / 2, scrH * 0.3)
		self.subLabel:SetPos(scrW / 2 - self.subLabel:GetWide() / 2, self.titleLabel.y + self.titleLabel:GetTall() + 8)
	else
		self.titleLabel:SetVisible(false)
		self.titleLabel:SetSize(512, 256)
		self.titleLabel:SetPos(scrW / 2 - self.titleLabel:GetWide() / 2, scrH * 0.3 - 128)
		self.subLabel:SetPos(self.titleLabel.x + self.titleLabel:GetWide() / 2 - self.subLabel:GetWide() / 2, self.titleLabel.y + self.titleLabel:GetTall() + 8)
	end

	self.authorLabel:SetText(L("CharacterMenuAuthorLabel"))
	self.authorLabel:SizeToContents()
	self.authorLabel:SetPos(self.subLabel.x + (self.subLabel:GetWide() - self.authorLabel:GetWide()), self.subLabel.y + self.subLabel:GetTall() + 4)

	self.createButton:SetText(L("CharacterMenuNew"))
	self.createButton:SizeToContents()
	self.createButton:SetPos((ScrW() / 2) - (self.createButton:GetWide() / 2) , ScrH() * 0.6)

	self.loadButton:SetText(L("CharacterMenuLoad"))
	self.loadButton:SizeToContents()
	self.loadButton:SetPos((ScrW() / 2) - (self.loadButton:GetWide() / 2), ScrH() * 0.65)

	self.aboutButton:SetText(L("CharacterMenuAbout"))
	self.aboutButton:SizeToContents()
	self.aboutButton:SetPos((ScrW() / 2) - (self.aboutButton:GetWide()) / 2, ScrH() * 0.7)

	self.disconnectButton:SetText(L("CharacterMenuLeave"))
	self.disconnectButton:SizeToContents()
	self.disconnectButton:SetPos((ScrW() / 2) - (self.disconnectButton:GetWide() / 2), ScrH() * 0.75)

	self.previousButton:SetText(L("CharacterMenuPrevious"))
	self.previousButton:SizeToContents()
	self.previousButton:SetPos((scrW * 0.2) - (self.previousButton:GetWide() / 2), scrH * 0.9)

	self.nextButton:SetText(L("CharacterMenuNext"))
	self.nextButton:SizeToContents()
	self.nextButton:SetPos((scrW * 0.8) - (self.nextButton:GetWide() / 2), scrH * 0.9)

	self.cancelButton:SetText(L("CharacterMenuCancel"))
	self.cancelButton:SizeToContents()
	self.cancelButton:SetPos((scrW * 0.5) - (self.cancelButton:GetWide() / 2), scrH * 0.9)
end

-- A function to fade in the model panel.
function PANEL:FadeInModelPanel(model)
	if ScrH() < 768 then return true end
	local width, height = self.characterModel:GetSize()
	local x, y = ScrW() - width - ScrW() * 0.1, (ScrH() - height) * 0.4
	self.characterModel:SetPos(x, y)
	if self.characterModel:FadeIn(0.5) then
		self:SetModelPanelModel(model)
		return true
	else
		return false
	end
end

-- A function to fade out the model panel.
function PANEL:FadeOutModelPanel()
	self.characterModel:FadeOut(0.5)
end

-- A function to set the model panel's model.
function PANEL:SetModelPanelModel(model)
	if self.characterModel.currentModel ~= model then
		self.characterModel.currentModel = model
		self.characterModel:SetModel(model)
	end

	local modelPanel = self.characterModel
	local sequence = Clockwork.plugin:Call("GetModelSelectSequence", modelPanel.Entity, model)

	if sequence then
		modelPanel.Entity:ResetSequence(sequence)
	end

	if IsValid(self.characterModel.skinComboBox) then self.characterModel.skinComboBox:Remove() end
end

-- A function to return to the main menu.
function PANEL:ReturnToMainMenu()
	local panel = Clockwork.character:GetActivePanel()

	if panel then
		panel:FadeOut(0.5, function()
			Clockwork.character.activePanel = nil
			panel:Remove()
			self:FadeInTitle()
		end)
	else
		self:FadeInTitle()
	end

	self:FadeOutModelPanel()
	self:FadeOutNavigation()
end

-- A function to fade out the navigation.
function PANEL:FadeOutNavigation()
	if not Clockwork.theme:Call("PreCharacterFadeOutNavigation", self) then
		self.previousButton:FadeOut(0.5)
		self.cancelButton:FadeOut(0.5)
		self.nextButton:FadeOut(0.5)
	end
end

-- A function to fade in the navigation.
function PANEL:FadeInNavigation()
	if not Clockwork.theme:Call("PreCharacterFadeInNavigation", self) then
		self.previousButton:FadeIn(0.5)
		self.cancelButton:FadeIn(0.5)
		self.nextButton:FadeIn(0.5)
	end
end

-- A function to fade out the title.
function PANEL:FadeOutTitle()
	if not Clockwork.theme:Call("PreCharacterFadeOutTitle", self) then
		self.subLabel:FadeOut(0.5)
		self.titleLabel:FadeOut(0.5)
		self.createButton:FadeOut(0.5)
		self.loadButton:FadeOut(0.5)
		self.aboutButton:FadeOut(0.5)
		self.disconnectButton:FadeOut(0.5)
		self.authorLabel:FadeOut(0.5)
	end
end

-- A function to fade in the title.
function PANEL:FadeInTitle()
	if not Clockwork.theme:Call("PreCharacterFadeInTitle", self) then
		self.subLabel:FadeIn(0.5)
		self.createButton:FadeIn(0.5)
		self.loadButton:FadeIn(0.5)
		self.aboutButton:FadeIn(0.5)
		self.disconnectButton:FadeIn(0.5)
		self.titleLabel:FadeIn(0.5)
		self.authorLabel:FadeIn(0.5)
	end
end

-- A function to open a panel.
function PANEL:OpenPanel(vguiName, childData, Callback)
	if not Clockwork.theme:Call("PreCharacterMenuOpenPanel", self, vguiName, childData, Callback) then
		local panel = Clockwork.character:GetActivePanel()
		local y = ScrH() * .275

		if ScrH() < 768 then
			y = ScrH() * .225
		end

		if panel then
			panel:FadeOut(0.5, function()
				panel:Remove()
				self.childData = childData
				Clockwork.character.activePanel = vgui.Create(vguiName, self)
				Clockwork.character.activePanel:SetAlpha(0)
				Clockwork.character.activePanel:FadeIn(0.5)
				Clockwork.character.activePanel:MakePopup()
				Clockwork.character.activePanel:SetPos(ScrW() * 0.2, y)

				if Callback then
					Callback(Clockwork.character.activePanel)
				end

				if childData then
					Clockwork.character.activePanel.isCreationProcess = true
					Clockwork.character:FadeInNavigation()
				end
			end)
		else
			self.childData = childData
			self:FadeOutTitle()
			Clockwork.character.activePanel = vgui.Create(vguiName, self)
			Clockwork.character.activePanel:SetAlpha(0)
			Clockwork.character.activePanel:FadeIn(0.5)
			Clockwork.character.activePanel:MakePopup()
			Clockwork.character.activePanel:SetPos(ScrW() * 0.2, y)

			if Callback then
				Callback(Clockwork.character.activePanel)
			end

			if childData then
				Clockwork.character.activePanel.isCreationProcess = true
				Clockwork.character:FadeInNavigation()
			end
		end

		--[[ Fade out the model panel, we probably don't need it now! --]]
		self:FadeOutModelPanel()
		Clockwork.theme:Call("PostCharacterMenuOpenPanel", self)
	end
end

-- Called when the panel is painted.
function PANEL:Paint(w, h)
	if not Clockwork.theme:Call("PreCharacterMenuPaint", self) then
		local schemaLogo = Clockwork.option:GetKey("schema_logo")
		local subLabelAlpha = self.subLabel:GetAlpha()

		if schemaLogo ~= "" and subLabelAlpha > 0 then
			if not self.logoTextureID then
				self.logoTextureID = Material(schemaLogo .. ".png")
			end

			self.logoTextureID:SetFloat("$alpha", subLabelAlpha)
			surface.SetDrawColor(255, 255, 255, subLabelAlpha)
			surface.SetMaterial(self.logoTextureID)
			surface.DrawTexturedRect(self.titleLabel.x, self.titleLabel.y - 64, 512, 256)
		end

		-- local backgroundColor = Clockwork.option:GetColor("background")
		-- local foregroundColor = Clockwork.option:GetColor("foreground")
		-- local colorTargetID = Clockwork.option:GetColor("target_id")
		-- local colorWhite = Clockwork.option:GetColor("white")
		-- local scrW = ScrW()
		-- local height = self.createButton.y * 2 + self.createButton:GetTall()
		-- local y = 0

		-- Clockwork.kernel:DrawSimpleGradientBox(0, 0, y, scrW, height, Color(backgroundColor.r, backgroundColor.g, backgroundColor.b, 100))

		-- surface.SetDrawColor(foregroundColor.r, foregroundColor.g, foregroundColor.b, 200)
		-- surface.DrawRect(0, y + height, scrW, 1)

		-- if Clockwork.character:IsCreationProcessActive() then
		-- 	local creationPanels = Clockwork.character:GetCreationPanels(true)
		-- 	local numCreationPanels = #creationPanels
		-- 	local creationProgress = Clockwork.character:GetCreationProgress()
		-- 	local mainTextFont = Clockwork.option:GetFont("main_text")
		-- 	local _, mainTextH = Clockwork.kernel:GetCachedTextSize(mainTextFont, "U")
		-- 	local progressHeight = mainTextH + 16
		-- 	local progressY = y + height + 1
		-- 	local boxColor = Color(math.min(backgroundColor.r + 50, 255), math.min(backgroundColor.g + 50, 255), math.min(backgroundColor.b + 50, 255), 100)

		-- 	Clockwork.kernel:DrawSimpleGradientBox(0, 0, progressY, scrW, progressHeight, boxColor)

		-- 	for i = 1, numCreationPanels do
		-- 		surface.SetDrawColor(foregroundColor.r, foregroundColor.g, foregroundColor.b, 150)
		-- 		surface.DrawRect((scrW / numCreationPanels) * i, progressY, 1, progressHeight)
		-- 	end

		-- 	Clockwork.kernel:DrawSimpleGradientBox(0, 0, progressY, (scrW / 100) * creationProgress, progressHeight, colorTargetID)

		-- 	if creationProgress > 0 and creationProgress < 100 then
		-- 		surface.SetDrawColor(foregroundColor.r, foregroundColor.g, foregroundColor.b, 200)
		-- 		surface.DrawRect((scrW / 100) * creationProgress, progressY, 1, progressHeight)
		-- 	end

		-- 	for i = 1, numCreationPanels do
		-- 		local textX = (scrW / numCreationPanels) * (i - 0.5)
		-- 		local textY = progressY + progressHeight / 2
		-- 		local color = Color(colorWhite.r, colorWhite.g, colorWhite.b, 200)
		-- 		Clockwork.kernel:DrawSimpleText(L(creationPanels[i].friendlyName), textX, textY - 1, color, 1, 1)
		-- 	end

		-- 	surface.SetDrawColor(foregroundColor.r, foregroundColor.g, foregroundColor.b, 200)
		-- 	surface.DrawRect(0, progressY + progressHeight, scrW, 1)
		-- end

		Clockwork.theme:Call("PostCharacterMenuPaint", self)
	end

	return true
end

-- Called each frame.
function PANEL:Think()
	if not Clockwork.theme:Call("PreCharacterMenuThink", self) then
		local characters = table.Count(Clockwork.character:GetAll())
		local bIsLoading = Clockwork.character:IsPanelLoading()
		local schemaLogo = Clockwork.option:GetKey("schema_logo")
		local activePanel = Clockwork.character:GetActivePanel()

		if Clockwork.plugin:Call("ShouldDrawCharacterBackgroundBlur") then
			Clockwork.kernel:RegisterBackgroundBlur(self, self.createTime)
		else
			Clockwork.kernel:RemoveBackgroundBlur(self)
		end

		-- if self.characterModel then
		-- 	if not self.characterModel.currentModel or self.characterModel.currentModel == "models/error.mdl" then
		-- 		self.characterModel:SetAlpha(0)
		-- 	end
		-- end

		if not Clockwork.character:IsCreationProcessActive() then
			if activePanel then
				if activePanel.GetNextDisabled and activePanel:GetNextDisabled() then
					self.nextButton:SetDisabled(true)
				else
					self.nextButton:SetDisabled(false)
				end

				if activePanel.GetPreviousDisabled and activePanel:GetPreviousDisabled() then
					self.previousButton:SetDisabled(true)
				else
					self.previousButton:SetDisabled(false)
				end
			end
		else
			local previousPanelInfo = Clockwork.character:GetPreviousCreationPanel()

			if previousPanelInfo then
				self.previousButton:SetDisabled(false)
			else
				self.previousButton:SetDisabled(true)
			end

			self.nextButton:SetDisabled(false)
		end

		if schemaLogo == "" then
			self.titleLabel:SetVisible(true)
		else
			self.titleLabel:SetVisible(false)
		end

		if characters == 0 or bIsLoading then
			self.loadButton:SetDisabled(true)
		else
			self.loadButton:SetDisabled(false)
		end

		if characters >= Clockwork.player:GetMaximumCharacters() or Clockwork.character:IsPanelLoading() then
			self.createButton:SetDisabled(true)
		else
			self.createButton:SetDisabled(false)
		end

		if Clockwork.Client:HasInitialized() and not Clockwork.character:IsMenuReset() then
			self.disconnectButton:SetText(L("CharacterMenuCancel"))
			self.disconnectButton:SizeToContents()
			self.disconnectButton:SetPos((ScrW() / 2) - (self.disconnectButton:GetWide() / 2), ScrH() * 0.75)
		else
			self.disconnectButton:SetText(L("CharacterMenuLeave"))
			self.disconnectButton:SizeToContents()
			self.disconnectButton:SetPos((ScrW() / 2) - (self.disconnectButton:GetWide() / 2), ScrH() * 0.75)
		end

		if self.animation then
			self.animation:Run()
		end

		self:SetSize(ScrW(), ScrH())
		Clockwork.theme:Call("PostCharacterMenuThink", self)
	end
end

vgui.Register("cwCharacterMenu", PANEL, "DPanel")

--[[
	Add a hook to control clicking outside of the active panel.
--]]
hook.Add("VGUIMousePressed", "Clockwork.character:VGUIMousePressed", function(panel, code)
	local characterPanel = Clockwork.character:GetPanel()
	local activePanel = Clockwork.character:GetActivePanel()

	if Clockwork.character:IsPanelOpen() and activePanel and characterPanel == panel then
		activePanel:MakePopup()
	end
end)

local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.selectedIdx = 1
	self.characterPanels = {}
	self.isCharacterList = true

	CHAR_LIST = self
	Clockwork.character:FadeInNavigation()
end

-- Called when the panel is painted.
function PANEL:Paint(w, h)
end

-- A function to make the panel fade out.
function PANEL:FadeOut(speed, Callback)
	if self:GetAlpha() > 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetAlpha(255 - delta * 255)

			if animation.Finished then
				panel:SetVisible(false)
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end

		Clockwork.option:PlaySound('rollover')
	else
		self:SetVisible(false)
		self:SetAlpha(0)

		if Callback then
			Callback()
		end
	end
end

-- A function to make the panel fade in.
function PANEL:FadeIn(speed, Callback)
	if self:GetAlpha() == 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetVisible(true)
			panel:SetAlpha(delta * 255)

			if animation.Finished then
				self.animation = nil
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end

		Clockwork.option:PlaySound("click_release")
	else
		self:SetVisible(true)
		self:SetAlpha(255)

		if Callback then
			Callback()
		end
	end
end

-- A function to clear the panel's panels.
function PANEL:Clear()
	for k, v in pairs(self.characterPanels) do
		v:Remove()
	end

	self.characterPanels = {}
end

-- A function to add a panel to the panel.
function PANEL:AddPanel(panel)
	self.characterPanels[#self.characterPanels + 1] = panel
end

-- Called to get whether the previous button is disabled.
function PANEL:GetPreviousDisabled()
	return self.characterPanels[self.selectedIdx - 1] == nil
end

-- Called to get whether the next button is disabled.
function PANEL:GetNextDisabled()
	return self.characterPanels[self.selectedIdx + 1] == nil
end

-- A function to get the panel's character panels.
function PANEL:GetCharacterPanels()
	return self.characterPanels
end

-- A function to get the panel's selected model.
function PANEL:GetSelectedModel()
	return self.characterPanels[self.selectedIdx]
end

-- A function to manage a panel's targets.
function PANEL:ManageTargets(panel, position, alpha)
	if not panel.TargetPosition then
		panel.TargetPosition = position
	end

	if not panel.TargetAlpha then
		panel.TargetAlpha = alpha
	end

	local moveSpeed = math.abs(panel.TargetPosition - position) * 2
	local interval = moveSpeed * FrameTime()
	panel.TargetPosition = math.Approach(panel.TargetPosition, position, interval)
	panel.TargetAlpha = math.Approach(panel.TargetAlpha, alpha, interval)

	panel:SetAlpha(panel.TargetAlpha)
	panel:SetPos(panel.TargetPosition, 0)
end

-- A function to set the panel's selected index.
function PANEL:SetSelectedIdx(index)
	self.selectedIdx = index
end

-- Called when the previous button is pressed.
function PANEL:OnPrevious()
	self.selectedIdx = math.max(self.selectedIdx - 1, 1)
	self:MakePopup()
end

-- Called when the next button is pressed.
function PANEL:OnNext()
	self.selectedIdx = math.min(self.selectedIdx + 1, #self.characterPanels)
	self:MakePopup()
end

-- Called each frame.
function PANEL:Think()
	self:InvalidateLayout(true)
	if self.animation then self.animation:Run() end
	while self.selectedIdx > #self.characterPanels do self.selectedIdx = self.selectedIdx - 1 end
	if self.selectedIdx == 0 then self.selectedIdx = 1 end
	if self.characterPanels[self.selectedIdx] then
		local centerPanel = self.characterPanels[self.selectedIdx]
		centerPanel:SetActive(true)
		self:ManageTargets(centerPanel, (self:GetWide() / 2) - (centerPanel:GetWide() / 2), 255)
		local rightX = centerPanel.x + centerPanel:GetWide() + 16
		local leftX = centerPanel.x - 16
		for i = self.selectedIdx - 1, 1, -1 do
			local previousPanel = self.characterPanels[i]
			if previousPanel then
				previousPanel:SetActive(false)
				self:ManageTargets(previousPanel, leftX - previousPanel:GetWide(), (255 / self.selectedIdx) * i)
				leftX = previousPanel.x - 16
			end
		end
		for k, v in next, self.characterPanels do
			if k > self.selectedIdx then
				v:SetActive(false)
				self:ManageTargets(v, rightX, (255 / ((#self.characterPanels + 1) - self.selectedIdx)) * ((#self.characterPanels + 1) - k))
				rightX = v.x + v:GetWide() + 16
			end
		end
	end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout(w, h)
	self:SetPos(0, (ScrH() / 2) - 256)
	self:SetSize(ScrW(), 512)
end

vgui.Register("cwCharacterList", PANEL, "EditablePanel")
local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	local smallTextFont = Clockwork.option:GetFont("menu_text_small")
	local tinyTextFont = Clockwork.option:GetFont("menu_text_tiny")
	local buttonsList = {}
	local buttonX = 20
	local buttonY = 0
	local labels = {}

	self.customData = self:GetParent().customData
	self.buttonPanels = {}

	self:SetPaintBackground(false)

	Clockwork.plugin:Call("GetCharacterPanelLabels", labels, self.customData)

	self.nameLabel = vgui.Create("cwLabelButton", self)
	self.nameLabel:SetDisabled(true)
	self.nameLabel:SetFont(smallTextFont)
	self.nameLabel:SetText(self.customData.name)
	self.nameLabel:SizeToContents()

	self.factionLabel = vgui.Create("cwLabelButton", self)
	self.factionLabel:SetDisabled(true)
	self.factionLabel:SetFont(tinyTextFont)
	self.factionLabel:SetText(self.customData.faction)
	self.factionLabel:SizeToContents()
	self.factionLabel:SetPos(0, self.nameLabel:GetTall() + 8)

	local color = Color(255, 255, 255, 255)
	local factionTable = Clockwork.faction:FindByID(self.customData.faction)

	if not factionTable or not factionTable.color then
		for k, v in pairs(Clockwork.class:GetAll()) do
			if v.factions and table.HasValue(v.factions, self.customData.faction) then
				color = v.color
			end
		end
	else
		color = factionTable.color
	end

	self.factionLabel:OverrideTextColor(color)

	local modelSize = 300
	self.characterModel = vgui.Create("cwCharacterModel", self)
	self.characterModel:SetModel(self.customData.model)
	self.characterModel:SetPos(0, self.factionLabel.y + self.factionLabel:GetTall() + 8)
	self.characterModel:SetSize(modelSize, modelSize)
	-- self.characterModel:SetMouseInputEnabled(true)

	buttonY = self.characterModel.y + self.characterModel:GetTall() + 8

	local modelPanel = self.characterModel:GetModelPanel()
	if IsValid(modelPanel) and IsValid(modelPanel.Entity) then
		local modelEnt = modelPanel.Entity
		if self.customData.skin then modelEnt:SetSkin(self.customData.skin) end
		if self.customData.bodyGroups then for k, v in next, self.customData.bodyGroups do modelEnt:SetBodygroup(tonumber(k), v) end end
	end

	self.useButton = Clockwork.kernel:CreateMarkupToolTip(vgui.Create("DImageButton", self))
	self.useButton:SetTooltip(L("UseThisCharacter"))
	self.useButton:SetImage("icon16/tick.png")
	self.useButton:SetSize(16, 16)
	self.useButton:SetPos(-10, buttonY)
	self.useButton:SetMouseInputEnabled(true)

	self.deleteButton = Clockwork.kernel:CreateMarkupToolTip(vgui.Create("DImageButton", self))
	self.deleteButton:SetTooltip(L("DeleteThisCharacter"))
	self.deleteButton:SetImage("icon16/cross.png")
	self.deleteButton:SetSize(16, 16)
	self.deleteButton:SetPos(30, buttonY)
	self.deleteButton:SetMouseInputEnabled(true)

	Clockwork.plugin:Call("GetCustomCharacterButtons", self.customData.charTable, buttonsList)

	for k, v in pairs(buttonsList) do
		local button = Clockwork.kernel:CreateMarkupToolTip(vgui.Create("DImageButton", self))
		buttonX = buttonX + 20
		button:SetTooltip(v.toolTip)
		button:SetImage(v.image)
		button:SetSize(16, 16)
		button:SetPos(buttonX, buttonY)
		button:SetMouseInputEnabled(true)

		self.buttonPanels[#self.buttonPanels + 1] = button

		-- Called when the button is clicked.
		function button.DoClick(button)
			local function Callback()
				netstream.Start("InteractCharacter", {
					characterID = self.customData.characterID,
					action = k
				})
			end

			if not v.OnClick or v.OnClick(Callback) ~= false then
				Callback()
			end
		end
	end

	-- Called when the button is clicked.
	function self.useButton.DoClick(spawnIcon)
		netstream.Start("InteractCharacter", {
			characterID = self.customData.characterID,
			action = "use"
		})
	end

	local function deleteConfirmation()
		-- local message = string.format("Вы собираетесь безвозвратно удалить персонажа \"%s\". Вы уверены?", self.customData.name)
		local message = L("DeleteCharacterConfirmation", self.customData.name)
		Derma_Query(message, self.customData.name,
			L("Delete"), function()
				netstream.Start("InteractCharacter", {
					characterID = self.customData.characterID,
					action = "delete"
				})
			end,
			L("Cancel")
		)
	end

	-- Called when the button is clicked.
	function self.deleteButton.DoClick(spawnIcon)
		Clockwork.kernel:AddMenuFromData(nil, {
			[L("Yes")] = function()
				-- netstream.Start("InteractCharacter", {
				-- 	characterID = self.customData.characterID,
				-- 	action = "delete"
				-- })
				deleteConfirmation()
			end,
			[L("No")] = function() end
		})
	end

	local modelPanel = self.characterModel:GetModelPanel()

	-- Called when the character model is clicked.
	function modelPanel.DoClick(modelPanel)
		local activePanel = Clockwork.character:GetActivePanel()

		if activePanel:GetSelectedModel() == self then
			local options = {}

			options[L("Select")] = function()
				netstream.Start("InteractCharacter", {
					characterID = self.customData.characterID,
					action = "use"
				})
			end

			options[L("Delete")] = {}
			options[L("Delete")][L("No")] = function() end

			options[L("Delete")][L("Yes")] = function()
				deleteConfirmation()
			end

			Clockwork.plugin:Call("GetCustomCharacterOptions", self.customData.charTable, options, menu)

			Clockwork.kernel:AddMenuFromData(nil, options, function(menu, key, value)
				menu:AddOption(T(key), function()
					netstream.Start("InteractCharacter", {
						characterID = self.customData.characterID,
						action = value
					})
				end)
			end)
		else
			for k, v in pairs(activePanel:GetCharacterPanels()) do
				if v == self then
					activePanel:SetSelectedIdx(k)
				end
			end
		end
	end

	local maxWidth = math.max(buttonX, 200)

	if self.nameLabel:GetWide() > maxWidth then
		maxWidth = self.nameLabel:GetWide()
	end

	if self.factionLabel:GetWide() > maxWidth then
		maxWidth = self.factionLabel:GetWide()
	end

	-- local widths = {
	-- 	["Vortigaunt"] = 90,
	-- 	["Enslaved Vortigaunt"] = 80,
	-- 	["Antlion"] = 180,
	-- 	["Zombie"] = 40
	-- }

	-- if (widths[self.customData.faction]) then
	-- 	maxWidth = maxWidth + widths[self.customData.faction]
	-- end

	-- local labelY = self.characterModel.y + self.characterModel:GetTall() + 4

	-- for k, v in pairs(labels) do
	-- 	local label = vgui.Create("cwLabelButton", self)
	-- 	label:SetDisabled(true)
	-- 	label:SetFont(tinyTextFont)
	-- 	label:SetText(string.upper(v.text))
	-- 	label:OverrideTextColor(v.color)
	-- 	label:SizeToContents()
	-- 	label:SetPos(maxWidth / 2 - label:GetWide() / 2, labelY)

	-- 	labelY = labelY + label:GetTall() + 4
	-- end

	self.characterModel:SetPos((maxWidth / 2) - (self.characterModel:GetWide() / 2), self.characterModel.y)
	self.factionLabel:SetPos((maxWidth / 2) - (self.factionLabel:GetWide() / 2), self.factionLabel.y)
	self.nameLabel:SetPos((maxWidth / 2) - (self.nameLabel:GetWide() / 2), self.nameLabel.y)

	self:SetSize(maxWidth, buttonY + 32)

	local buttonAddX = ((maxWidth / 2) - (buttonX / 2)) - 10
	self.useButton:SetPos(self.useButton.x + buttonAddX, self.useButton.y)
	self.deleteButton:SetPos(self.deleteButton.x + buttonAddX, self.deleteButton.y)
	for _, v in next, self.buttonPanels do
		v:SetPos(v.x + buttonAddX, v.y)
	end
end

-- A function to set whether the panel is active.
function PANEL:SetActive(isActive)
	if isActive then
		self.nameLabel:OverrideTextColor(Clockwork.option:GetColor("information"))
	else
		self.nameLabel:OverrideTextColor(false)
	end
end

-- Called each frame.
function PANEL:Think()
	local markupObject = Clockwork.theme:GetMarkupObject()
	local toolTip = Clockwork.plugin:Call("GetCharacterPanelToolTip", self, self.customData.charTable)

	if tooltip and toolTip ~= "" then
		details = markupObject:Title(self.customData.name)
		details = markupObject:Add(toolTip)
	end

	markupObject:Title(L("CharTooltipDetailsTitle"))
	markupObject:Add(self.customData.details or L("CharNoDetailsToDisplay"))

	self.characterModel:SetDetails(markupObject:GetText())
end

vgui.Register("cwCharacterPanel", PANEL, "DPanel")
local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
    self:SetPaintBackground(false)
    self.modelPanel = vgui.Create('DModelPanel', self)
    self.modelPanel:SetAmbientLight(Color(255, 255, 255, 255))
    function self.modelPanel.LayoutEntity(modelPanel) modelPanel:RunAnimation() end
    self:SetCursor('none')
    Clockwork.kernel:CreateMarkupToolTip(self)
end

-- A function to make the panel fade out.
function PANEL:FadeOut(speed, Callback)
	if self:GetAlpha() > 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetAlpha(255 - delta * 255)

			if animation.Finished then
				panel:SetVisible(false)
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end

		Clockwork.option:PlaySound('rollover')

		return true
	else
		self:SetAlpha(0)
		self:SetVisible(false)

		if Callback then
			Callback()
		end
	end
end

-- A function to make the panel fade in.
function PANEL:FadeIn(speed, Callback)
	if self:GetAlpha() == 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetAlpha(delta * 255)

			if animation.Finished then
				self.animation = nil
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end

		Clockwork.option:PlaySound('click_release')
		self:SetVisible(true)

		return true
	else
		self:SetVisible(true)
		self:SetAlpha(255)

		if Callback then
			Callback()
		end
	end
end

-- A function to set the alpha of the panel.
function PANEL:SetAlpha(alpha)
	local color = self.modelPanel:GetColor()
	self.modelPanel:SetColor(Color(color.r, color.g, color.b, alpha))
end

-- A function to get the alpha of the panel.
function PANEL:GetAlpha(alpha)
	local color = self.modelPanel:GetColor()

	return color.a
end

-- Called each frame.
function PANEL:Think()
	local entity = self.modelPanel.Entity
	if IsValid(entity) then entity:ClearPoseParameters() end
	if self.animation then
		self.animation:Run()
	end

	-- if self.forceX then
	-- 	self.x = self.forceX
	-- end

	self:InvalidateLayout(true)
end

function PANEL:GetModelPanel()
	return self.modelPanel
end

function PANEL:PerformLayout(w, h)
	self.modelPanel:SetSize(w, h)
end

-- A function to set the model details.
function PANEL:SetDetails(details)
	self:SetMarkupToolTip(details)
end

function PANEL:SetModel(model)
	self.modelPanel:SetModel(model)
	local entity = ents.CreateClientProp(model)
	entity:SetAngles(angle_zero)
	entity:SetPos(vector_origin)
	entity:Spawn()
	local obbCenter = entity:OBBCenter()
	obbCenter.z = obbCenter.z * 1.09
	local distance = math.max(70, entity:GetModelRadius())
	entity:Remove()
	self.modelPanel:SetLookAt(obbCenter)
	self.modelPanel:SetFOV(40)
	self.modelPanel:SetCamPos(obbCenter + Vector(distance * 1.56, distance * 0.31, distance * 0.4))
	entity = self.modelPanel.Entity
	if IsValid(entity) then
		local sequence = entity:LookupSequence('idle')
		local leanBackAnims = {'LineIdle01', 'LineIdle02', 'LineIdle03'}
		local leanBackAnim = entity:LookupSequence(leanBackAnims[math.random(1, #leanBackAnims)])
		if leanBackAnim > 0 then sequence = leanBackAnim end
		if sequence <= 0 then sequence = entity:LookupSequence('idle_unarmed') end
		if sequence <= 0 then sequence = entity:LookupSequence('idle1') end
		if sequence <= 0 then sequence = entity:LookupSequence('walk_all') end
		entity:ResetSequence(sequence)
	end
end

function PANEL:OnMousePressed()
	if self.DoClick then
		self:DoClick()
	end
end

vgui.Register("cwCharacterModel", PANEL, "DModelPanel")
local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	local colorWhite = Clockwork.option:GetColor("white")
	local colorTargetID = Clockwork.option:GetColor("target_id")

	self:SetSize(self:GetWide(), 16)

	self.totalPoints = 0
	self.maximumPoints = 0
	self.attributeTable = nil
	self.attributePanels = {}

	self:SetPaintBackground(false)

	Clockwork.kernel:CreateMarkupToolTip(self)

	self.addButton = vgui.Create("DImageButton", self)
	self.addButton:SetMaterial("icon16/add.png")
	self.addButton:SizeToContents()

	-- Called when the button is clicked.
	function self.addButton.DoClick(imageButton)
		self:AddPoint()
	end

	self.removeButton = vgui.Create("DImageButton", self)
	self.removeButton:SetMaterial("icon16/exclamation.png")
	self.removeButton:SizeToContents()

	-- Called when the button is clicked.
	function self.removeButton.DoClick(imageButton)
		self:RemovePoint()
	end

	self.pointsUsed = vgui.Create("DPanel", self)
	self.pointsUsed:SetPos(self.addButton:GetWide() + 8, 0)
	Clockwork.kernel:CreateMarkupToolTip(self.pointsUsed)

	self.pointsLabel = vgui.Create("DLabel", self)
	self.pointsLabel:SetText("N/A")
	self.pointsLabel:SetTextColor(colorWhite)
	self.pointsLabel:SizeToContents()
	self.pointsLabel:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	Clockwork.kernel:CreateMarkupToolTip(self.pointsLabel)

	-- Called when the panel should be painted.
	function self.pointsUsed.Paint(pointsUsed)
		local color = Color(100, 100, 100, 255)
		local width = math.Clamp((pointsUsed:GetWide() / self.attributeTable.maximum) * self.totalPoints, 0, pointsUsed:GetWide())

		if color then
			color.r = math.min(color.r - 25, 255)
			color.g = math.min(color.g - 25, 255)
			color.b = math.min(color.b - 25, 255)
		end

		Clockwork.kernel:DrawSimpleGradientBox(2, 0, 0, pointsUsed:GetWide(), pointsUsed:GetTall(), color)

		if self.totalPoints > 0 and self.totalPoints < self.attributeTable.maximum then
			Clockwork.kernel:DrawSimpleGradientBox(0, 2, 2, width - 4, pointsUsed:GetTall() - 4, colorTargetID)
			surface.SetDrawColor(255, 255, 255, 200)
			surface.DrawRect(width, 0, 1, pointsUsed:GetTall())
		end
	end
end

-- Called each frame.
function PANEL:Think()
	self.pointsUsed:SetSize(self:GetWide() - self.pointsUsed.x * 2, 16)
	self.pointsLabel:SetText(self.attributeTable.name)
	self.pointsLabel:SetPos(self:GetWide() / 2 - self.pointsLabel:GetWide() / 2, self:GetTall() / 2 - self.pointsLabel:GetTall() / 2)
	self.pointsLabel:SizeToContents()
	self.addButton:SetPos(self.pointsUsed.x + self.pointsUsed:GetWide() + 8, 0)

	local markupObject = Clockwork.theme:GetMarkupObject()
	local attributeName = self.attributeTable.name
	local attributeMax = self.totalPoints .. "/" .. self.attributeTable.maximum

	markupObject:Title(attributeName .. ", " .. attributeMax)
	markupObject:Add(self.attributeTable.description)

	self:SetMarkupToolTip(markupObject:GetText())
	self.pointsUsed:SetMarkupToolTip(markupObject:GetText())
	self.pointsLabel:SetMarkupToolTip(markupObject:GetText())
end

-- A function to add a point.
function PANEL:AddPoint()
	local pointsUsed = self:GetPointsUsed()

	if pointsUsed + 1 <= self.maximumPoints then
		self.totalPoints = self.totalPoints + 1
	end
end

-- A function to remove a point.
function PANEL:RemovePoint()
	self.totalPoints = math.max(self.totalPoints - 1, 0)
end

-- A function to get the total points.
function PANEL:GetTotalPoints()
	return self.totalPoints
end

-- A function to get the points used.
function PANEL:GetPointsUsed()
	local pointsUsed = 0

	for k, v in pairs(self.attributePanels) do
		pointsUsed = pointsUsed + v:GetTotalPoints()
	end

	return pointsUsed
end

-- A function to get the panel's attribute ID.
function PANEL:GetAttributeID()
	return self.attributeTable.uniqueID
end

-- A function to set the panel's attribute panels.
function PANEL:SetAttributePanels(attributePanels)
	self.attributePanels = attributePanels
end

-- A function to set the panel's attribute table.
function PANEL:SetAttributeTable(attributeTable)
	self.attributeTable = attributeTable
end

-- A function to set the panel's maximum points.
function PANEL:SetMaximumPoints(maximumPoints)
	self.maximumPoints = maximumPoints
end

vgui.Register("cwCharacterAttribute", PANEL, "DPanel")
local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.info = Clockwork.character:GetCreationInfo()
	local maximumPoints = Clockwork.config:Get("default_attribute_points"):Get()
	local factionTable = Clockwork.faction:FindByID(self.info.faction)
	local attributes = {}

	if factionTable.attributePointsScale then
		maximumPoints = math.Round(maximumPoints * factionTable.attributePointsScale)
	end

	if factionTable.maximumAttributePoints then
		maximumPoints = factionTable.maximumAttributePoints
	end

	self.attributesForm = vgui.Create("cwBasicForm")
	self.attributesForm:SetAutoSize(true)
	self.attributesForm:SetText(Clockwork.option:Translate("name_attributes"))
	self.attributesForm:SetPadding(8)
	self.attributesForm:SetSpacing(12)

	self.categoryList = vgui.Create("cwPanelList", self)
	self.categoryList:SetPadding(8)
	self.categoryList:SetSpacing(8)
	self.categoryList:SizeToContents()
	self.categoryList:EnableVerticalScrollbar(true)

	for k, v in pairs(Clockwork.attribute:GetAll()) do
		attributes[#attributes + 1] = v
	end

	table.sort(attributes, function(a, b) return a.name < b.name end)

	self.attributePanels = {}
	self.info.attributes = {}
	self.helpText = self.attributesForm:Help(L("YouCanSpendMorePoints", maximumPoints))

	for k, v in pairs(attributes) do
		if v.isOnCharScreen then
			local characterAttribute = vgui.Create("cwCharacterAttribute", self.attributesForm)
			characterAttribute:SetAttributeTable(v)
			characterAttribute:SetMaximumPoints(maximumPoints)
			characterAttribute:SetAttributePanels(self.attributePanels)

			self.attributesForm:AddItem(characterAttribute)

			self.attributePanels[#self.attributePanels + 1] = characterAttribute
		end
	end

	self.maximumPoints = maximumPoints
	self.categoryList:AddItem(self.attributesForm)
end

-- Called when the next button is pressed.
function PANEL:OnNext()
	for k, v in pairs(self.attributePanels) do
		self.info.attributes[v:GetAttributeID()] = v:GetTotalPoints()
	end
end

-- Called when the panel is painted.
function PANEL:Paint(w, h)
end

-- A function to make the panel fade out.
function PANEL:FadeOut(speed, Callback)
	if self:GetAlpha() > 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetAlpha(255 - delta * 255)

			if animation.Finished then
				panel:SetVisible(false)
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end
	else
		self:SetVisible(false)
		self:SetAlpha(0)

		if Callback then
			Callback()
		end
	end
end

-- A function to make the panel fade in.
function PANEL:FadeIn(speed, Callback)
	if self:GetAlpha() == 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetVisible(true)
			panel:SetAlpha(delta * 255)

			if animation.Finished then
				self.animation = nil
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end
	else
		self:SetVisible(true)
		self:SetAlpha(255)

		if Callback then
			Callback()
		end
	end
end

-- Called each frame.
function PANEL:Think()
	self:InvalidateLayout(true)

	if self.helpText then
		local pointsLeft = self.maximumPoints

		for k, v in pairs(self.attributePanels) do
			pointsLeft = pointsLeft - v:GetTotalPoints()
		end

		self.helpText:SetText(L("YouCanSpendMorePoints", pointsLeft))
	end

	if self.animation then
		self.animation:Run()
	end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout(w, h)
	self.categoryList:StretchToParent(0, 0, 0, 0)
	self:SetSize(512, math.min(self.categoryList.pnlCanvas:GetTall() + 8, ScrH() * 0.6))
end

vgui.Register("cwCharacterStageFour", PANEL, "EditablePanel")
local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.info = Clockwork.character:GetCreationInfo()

	self.classesForm = vgui.Create("DForm")
	self.classesForm:SetLabel(L("MenuNameClasses"))
	self.classesForm:SetPadding(4)

	self.categoryList = vgui.Create("cwPanelList", self)
	self.categoryList:SetPadding(8)
	self.categoryList:SetSpacing(8)
	self.categoryList:SizeToContents()

	for k, v in pairs(Clockwork.class:GetAll()) do
		if v.isOnCharScreen and (v.factions and table.HasValue(v.factions, self.info.faction)) then
			self.classTable = v

			self.overrideData = {
				information = L("SelectToMakeDefaultClass"),
				Callback = function()
					self.info.class = v.index
				end
			}

			self.classForm:AddItem(vgui.Create("cwClassesItem", self))
		end
	end

	self.categoryList:AddItem(self.classForm)
end

-- Called when the panel is painted.
function PANEL:Paint(w, h)
end

-- A function to make the panel fade out.
function PANEL:FadeOut(speed, Callback)
	if self:GetAlpha() > 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetAlpha(255 - delta * 255)

			if animation.Finished then
				panel:SetVisible(false)
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end
	else
		self:SetVisible(false)
		self:SetAlpha(0)

		if Callback then
			Callback()
		end
	end
end

-- A function to make the panel fade in.
function PANEL:FadeIn(speed, Callback)
	if self:GetAlpha() == 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetVisible(true)
			panel:SetAlpha(delta * 255)

			if animation.Finished then
				self.animation = nil
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end
	else
		self:SetVisible(true)
		self:SetAlpha(255)

		if Callback then
			Callback()
		end
	end
end

-- Called each frame.
function PANEL:Think()
	self:InvalidateLayout(true)

	if self.animation then
		self.animation:Run()
	end
end

-- Called when the next button is pressed.
function PANEL:OnNext()
	if not self.info.class or not Clockwork.class:FindByID(self.info.class) then
		Clockwork.character:SetFault(L("FaultNeedClass"))

		return false
	end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout(w, h)
	self.categoryList:StretchToParent(0, 0, 0, 0)
	self:SetSize(512, math.min(self.categoryList.pnlCanvas:GetTall() + 8, ScrH() * 0.6))
end

vgui.Register("cwCharacterStageThree", PANEL, "EditablePanel")
local PANEL = {}

local skinBlacklist = {}

-- Called when the panel is initialized.
function PANEL:Init()
	local panel = Clockwork.character:GetPanel()

	self.categoryList = vgui.Create("DCategoryList", self)
	self.categoryList:SetPadding(2)
	self.categoryList:SizeToContents()

	self.overrideModel = nil
	self.hasSelectedModel = nil
	self.hasPhysDesc = Clockwork.command:FindByID("CharPhysDesc") ~= nil
	self.info = Clockwork.character:GetCreationInfo()

	if not Clockwork.faction.stored[self.info.faction].GetModel then
		self.hasSelectedModel = true
	end

	local faction = Clockwork.faction.stored[self.info.faction]

	local genderModels = faction.models

	if not faction.singleGender then
		genderModels = faction.models[string.lower(self.info.gender)]
	end

	if genderModels and #genderModels == 1 then
		self.hasSelectedModel = false
		self.overrideModel = genderModels[1]

		if not panel:FadeInModelPanel(self.overrideModel) then
			panel:SetModelPanelModel(self.overrideModel)
		end
	end

	self.nameForm = vgui.Create("DForm", self)
	self.nameForm:SetPadding(4)
	if not Clockwork.faction.stored[self.info.faction].GetName then
		self.nameForm:SetLabel(L("Name"))

		if Clockwork.faction.stored[self.info.faction].useFullName then
			self.fullNameTextEntry = self.nameForm:TextEntry(L("CharacterMenuFullName"))
			self.fullNameTextEntry:SetAllowNonAsciiCharacters(true)
		else
			self.forenameTextEntry = self.nameForm:TextEntry(L("CharacterMenuForename"))
			self.forenameTextEntry:SetAllowNonAsciiCharacters(true)
			self.surnameTextEntry = self.nameForm:TextEntry(L("CharacterMenuSurname"))
			self.surnameTextEntry:SetAllowNonAsciiCharacters(true)
		end
	else
		self.nameForm:SetLabel(L("CharacterVoice"))
	end

	if self.hasSelectedModel or self.hasPhysDesc then
		self.appearanceForm = vgui.Create("DForm")
		self.appearanceForm:SetPadding(4)
		self.appearanceForm:SetLabel(L("CharacterMenuAppearance"))

		if self.hasPhysDesc then
			self.physDescTextEntry = self.appearanceForm:TextEntry('Описание')
			self.physDescTextEntry:SetAllowNonAsciiCharacters(true)
		end

		if self.hasSelectedModel then
			self.modelItemsList = vgui.Create("DPanelList", self)
			self.modelItemsList:SetPadding(4)
			self.modelItemsList:SetSpacing(16)
			self.modelItemsList:EnableHorizontal(true)
			self.modelItemsList:EnableVerticalScrollbar(true)

			self.appearanceForm:AddItem(self.modelItemsList)
		end
	end

	if self.nameForm then
		self.categoryList:AddItem(self.nameForm)
	end

	if self.physDescForm then
		self.categoryList:AddItem(self.physDescForm)
	end

	if self.appearanceForm then
		self.categoryList:AddItem(self.appearanceForm)
	end

	local informationColor = Clockwork.option:GetColor("information")
	local lowerGender = string.lower(self.info.gender)
	self.multitoneNumSlider = self.nameForm:NumSlider('Высота голоса', nil, -20, 20, 0)
	self.multitoneNumSlider:SetValue(0)
	local checkButton = vgui.Create('DButton', self.multitoneNumSlider)
	checkButton:SetText('Прослушать')
	checkButton:SetPos(100, 5)
	checkButton:SetSize(100, 20)
	function checkButton.DoClick()
		if Clockwork.faction.stored[self.info.faction].voPreview then
			local res = Clockwork.faction.stored[self.info.faction].voPreview(lowerGender)
			Clockwork.Client:EmitSound(res, 75, 100 + self.multitoneNumSlider:GetValue())
		else
			Clockwork.Client:EmitSound('vo/npc/' .. lowerGender .. '01/question' .. math.random(10, 31) .. '.wav', 75, 100 + self.multitoneNumSlider:GetValue())
		end
	end
	local spawnIcon = nil

	for k, v in pairs(Clockwork.faction.stored) do
		if v.name == self.info.faction then
			if self.modelItemsList and v.models[lowerGender] then
				for k2, v2 in pairs(v.models[lowerGender]) do
					spawnIcon = Clockwork.kernel:CreateMarkupToolTip(vgui.Create("cwSpawnIcon", self))
					spawnIcon:SetModel(v2)
					spawnIcon:SetTooltip(false)

					-- Called when the spawn icon is clicked.
					function spawnIcon.DoClick(spawnIcon)
						if self.selectedSpawnIcon then
							self.selectedSpawnIcon:SetColor(nil)
						end

						spawnIcon:SetColor(informationColor)

						if not panel:FadeInModelPanel(v2) then
							panel:SetModelPanelModel(v2)
						end

						self.selectedSpawnIcon = spawnIcon
						self.selectedModel = v2
						self.selectedSkin = 0
						local characterPanel = panel.characterModel
						if IsValid(characterPanel) then
							if IsValid(characterPanel.skinComboBox) then characterPanel.skinComboBox:Remove() end
							if v.allowSkins and skinBlacklist[v2] ~= true then
								local modelPanel = characterPanel:GetModelPanel()
								if IsValid(modelPanel) and IsValid(modelPanel.Entity) then
									local entityModel = modelPanel.Entity
									local skins = entityModel:SkinCount()
									entityModel:SetSkin(0)
									if skins > 1 then
										local width, height = characterPanel:GetSize()
										local comboBox = vgui.Create("DComboBox", characterPanel)
										comboBox:SetSize(100, 22)
										comboBox:SetPos(width - comboBox:GetWide() - 4, height - comboBox:GetTall() - 4)
										comboBox:SetSortItems(false)
										comboBox.OnSelect = function(_, _, _, data)
											if IsValid(self) and IsValid(entityModel) then
												entityModel:SetSkin(data)
												self.selectedSkin = data
											end
										end
										for i = 0, skins - 1 do
											if not skinBlacklist[v2] or not skinBlacklist[v2][i] then
												comboBox:AddChoice('Skin ' .. i, i, i == 0)
											end
										end
										characterPanel.skinComboBox = comboBox
									end
								end
							end
						end
					end

					self.modelItemsList:AddItem(spawnIcon)
				end
			end
		end
	end
end

-- Called when the next button is pressed.
function PANEL:OnNext()
	if self.overrideModel then
		self.info.model = self.overrideModel
	else
		self.info.model = self.selectedModel
	end

	self.info.tone = math.Clamp(math.floor(self.multitoneNumSlider:GetValue()), -20, 20)
	self.info.skin = self.selectedSkin or 0

	if not Clockwork.faction.stored[self.info.faction].GetName then
		if IsValid(self.fullNameTextEntry) then
			local limitCharName = Clockwork.config:Get("max_char_name"):Get()
			self.info.fullName = self.fullNameTextEntry:GetValue()

			if self.info.fullName == "" then
				Clockwork.character:SetFault({"FaultNameInvalid"})

				return false
			elseif string.utf8len(self.info.fullName) > limitCharName then
				Clockwork.character:SetFault({"FaultNameInvalid"})

				return false
			end
		else
			self.info.forename = self.forenameTextEntry:GetValue()
			self.info.surname = self.surnameTextEntry:GetValue()

			if self.info.forename == "" or self.info.surname == "" then
				Clockwork.character:SetFault({"FaultNameInvalid"})

				return false
			end

			if string.find(self.info.forename, "[%p%s%d]") or string.find(self.info.surname, "[%p%s%d]") then
				Clockwork.character:SetFault({"FaultNameNoSpecialChars"})

				return false
			end

			if not string.find(self.info.forename, "[aeiouAEIOUаеёиоуыэюяАЕЁИОУЫЭЮЯ]") or not string.find(self.info.surname, "[aeiouAEIOUаеёиоуыэюяАЕЁИОУЫЭЮЯ]") then
				Clockwork.character:SetFault({"FaultNameHaveVowel"})

				return false
			end

			if string.utf8len(self.info.forename) < 2 or string.utf8len(self.info.surname) < 2 then
				Clockwork.character:SetFault({"FaultNameMinLength"})

				return false
			end

			if string.utf8len(self.info.forename) > 16 or string.utf8len(self.info.surname) > 16 then
				Clockwork.character:SetFault({"FaultNameTooLong"})

				return false
			end
		end
	end

	if self.hasSelectedModel and not self.info.model then
		Clockwork.character:SetFault({"FaultNeedModel"})

		return false
	end

	if self.hasPhysDesc then
		local minimumPhysDesc = Clockwork.config:Get("minimum_physdesc"):Get()
		self.info.physDesc = self.physDescTextEntry:GetValue()

		if string.utf8len(self.info.physDesc) < minimumPhysDesc then
			Clockwork.character:SetFault({"PhysDescMinimumLength", minimumPhysDesc})

			return false
		end
	end
end

-- Called when the panel is painted.
function PANEL:Paint(w, h)
end

-- A function to make the panel fade out.
function PANEL:FadeOut(speed, Callback)
	if self:GetAlpha() > 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetAlpha(255 - delta * 255)

			if animation.Finished then
				panel:SetVisible(false)
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end

		Clockwork.option:PlaySound('rollover')
	else
		self:SetVisible(false)
		self:SetAlpha(0)

		if Callback then
			Callback()
		end
	end
end

-- A function to make the panel fade in.
function PANEL:FadeIn(speed, Callback)
	if self:GetAlpha() == 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetVisible(true)
			panel:SetAlpha(delta * 255)

			if animation.Finished then
				self.animation = nil
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end

		Clockwork.option:PlaySound('click_release')
	else
		self:SetVisible(true)
		self:SetAlpha(255)

		if Callback then
			Callback()
		end
	end
end

-- Called each frame.
function PANEL:Think()
	self:InvalidateLayout(true)

	if self.animation then
		self.animation:Run()
	end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout(w, h)
	self.categoryList:StretchToParent(0, 0, 0, 0)
	if IsValid(self.modelItemsList) then self.modelItemsList:SetTall(256) end
	self:SetSize(512, math.min(self.categoryList.pnlCanvas:GetTall() + 8, ScrH() * 0.6))
end

vgui.Register("cwCharacterStageTwo", PANEL, "EditablePanel")
local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	local factions = {}

	for k, v in pairs(Clockwork.faction.stored) do
		if not v.whitelist or Clockwork.character:IsWhitelisted(v.name) then
			if not Clockwork.faction:HasReachedMaximum(k) then
				factions[#factions + 1] = v.name
			end
		end
	end

	table.sort(factions, function(a, b) return a < b end)

	self.forcedFaction = nil
	self.info = Clockwork.character:GetCreationInfo()

	self.categoryList = vgui.Create("DCategoryList", self)
	self.categoryList:SetPadding(2)
	self.categoryList:SizeToContents()

	self.settingsForm = vgui.Create("DForm")
	self.settingsForm:SetLabel(L("CreateCharacterStage1"))
	self.settingsForm:SetPadding(4)

	if #factions > 1 then
		self.settingsForm:Help(L("CharacterMenuFactionHelp"))
		self.factionMultiChoice = self.settingsForm:ComboBox(L("CharacterMenuFaction"))

		-- Called when an option is selected.
		self.factionMultiChoice.OnSelect = function(multiChoice, index, value, data)
			for k, v in pairs(Clockwork.faction.stored) do
				if v.name == value then
					if IsValid(self.genderMultiChoice) then
						self.genderMultiChoice:Clear()
					else
						self.genderMultiChoice = self.settingsForm:ComboBox(L("Gender"))
						self.settingsForm:Rebuild()
					end

					if v.singleGender then
						local index = self.genderMultiChoice:AddChoice(L(GENDER_NONE))
						self.genderMultiChoice:ChooseOptionID(index)
					else
						self.genderMultiChoice:AddChoice(L(GENDER_FEMALE))
						self.genderMultiChoice:AddChoice(L(GENDER_MALE))
					end

					Clockwork.CurrentFactionSelected = {self, value}

					break
				end
			end
		end
	elseif #factions == 1 then
		for k, v in pairs(Clockwork.faction.stored) do
			if v.name == factions[1] then
				self.genderMultiChoice = self.settingsForm:ComboBox(L("Gender"))

				if v.singleGender then
					local index = self.genderMultiChoice:AddChoice(L(GENDER_NONE))
					self.genderMultiChoice:ChooseOptionID(index)
				else
					self.genderMultiChoice:AddChoice(L(GENDER_FEMALE))
					self.genderMultiChoice:AddChoice(L(GENDER_MALE))
				end

				Clockwork.CurrentFactionSelected = {self, v.name}

				self.forcedFaction = v.name
				break
			end
		end
	end

	if self.factionMultiChoice then
		for k, v in pairs(factions) do
			self.factionMultiChoice:AddChoice(v)
		end
	end

	self.customChoices = {}

	Clockwork.plugin:Call("GetPersuasionChoices", self.customChoices)

	if self.customChoices then
		self.customPanels = {}

		for k2, v2 in pairs(self.customChoices) do
			if not v2.type or string.lower(v2.type) == "combobox" then
				table.insert(self.customPanels, {v2, self.settingsForm:ComboBox(v2.name)})

				for k3, v3 in ipairs(v2.choices) do
					self.customPanels[#self.customPanels][2]:AddChoice(v3)
				end
			elseif string.lower(v2.type) == "textentry" then
				table.insert(self.customPanels, {v2, self.settingsForm:TextEntry(v2.name)})
			end
		end
	end

	self.categoryList:AddItem(self.settingsForm)
end

-- Called when the next button is pressed.
function PANEL:OnNext()
	self.info.plugin = {}

	if self.customPanels then
		for k, v in pairs(self.customPanels) do
			local value = v[2]:GetValue()

			if value == "" then
				Clockwork.character:SetFault({"FaultDidNotFillPanel", v[1].name})

				return false
			elseif v[1].isNumber then
				local max = v[1].max
				local min = v[1].min

				if not tonumber(value) then
					Clockwork.character:SetFault({"FaultDidNotFillPanelWithNumber", v[1].name})

					return false
				end

				if max and max < tonumber(value) then
					Clockwork.character:SetFault({"FaultTextEntryHigherThan", tostring(max), v[1].name})

					return false
				end

				if min and min > tonumber(value) then
					Clockwork.character:SetFault({"FaultTextEntryLowerThan", tostring(min), v[1].name})

					return false
				end
			end

			self.info.plugin[v[1].name] = value
		end
	end

	if IsValid(self.genderMultiChoice) then
		local faction = self.forcedFaction
		local gender = self.genderMultiChoice:GetValue()

		if gender == L(GENDER_MALE) then
			gender = GENDER_MALE
		elseif gender == L(GENDER_FEMALE) then
			gender = GENDER_FEMALE
		elseif gender == L(GENDER_NONE) then
			gender = GENDER_NONE
		else
			gender = GENDER_MALE
		end

		if not faction and self.factionMultiChoice then
			faction = self.factionMultiChoice:GetValue()
		end

		for k, v in pairs(Clockwork.faction.stored) do
			if v.name == faction then
				if Clockwork.faction:IsGenderValid(faction, gender) then
					self.info.faction = faction
					self.info.gender = gender

					return true
				end
			end
		end
	end

	Clockwork.character:SetFault({"FaultDidNotChooseFaction"})

	return false
end

-- Called when the panel is painted.
function PANEL:Paint(w, h)
end

-- A function to make the panel fade out.
function PANEL:FadeOut(speed, Callback)
	if self:GetAlpha() > 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetAlpha(255 - delta * 255)

			if animation.Finished then
				panel:SetVisible(false)
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end

		Clockwork.option:PlaySound('rollover')
	else
		self:SetVisible(false)
		self:SetAlpha(0)

		if Callback then
			Callback()
		end
	end
end

-- A function to make the panel fade in.
function PANEL:FadeIn(speed, Callback)
	if self:GetAlpha() == 0 and CW_CONVAR_FADEPANEL:GetInt() == 1 and (not self.animation or not self.animation:Active()) then
		self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
			panel:SetVisible(true)
			panel:SetAlpha(delta * 255)

			if animation.Finished then
				self.animation = nil
			end

			if animation.Finished and Callback then
				Callback()
			end
		end)

		if self.animation then
			self.animation:Start(speed)
		end

		Clockwork.option:PlaySound('click_release')
	else
		self:SetVisible(true)
		self:SetAlpha(255)

		if Callback then
			Callback()
		end
	end
end

-- Called each frame.
function PANEL:Think()
	self:InvalidateLayout(true)

	if self.animation then
		self.animation:Run()
	end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout(w, h)
	self.categoryList:StretchToParent(0, 0, 0, 0)
	self:SetSize(512, math.min(self.categoryList.pnlCanvas:GetTall() + 8, ScrH() * 0.6))
end

vgui.Register("cwCharacterStageOne", PANEL, "EditablePanel")

netstream.Hook("CharacterRemove", function(data)
	local characters = Clockwork.character:GetAll()
	local characterID = data

	if table.Count(characters) == 0 then return end

	if not characters[characterID] then return end
	characters[characterID] = nil

	if not Clockwork.character:IsPanelLoading() then
		Clockwork.character:RefreshPanelList()
	end

	if Clockwork.character:GetPanelList() then
		if table.Count(characters) == 0 then
			Clockwork.character:GetPanel():ReturnToMainMenu()
		end
	end
end)

netstream.Hook("SetWhitelisted", function(data)
	local whitelisted = Clockwork.character:GetWhitelisted()

	for k, v in pairs(whitelisted) do
		if v == data[1] then
			if not data[2] then
				whitelisted[k] = nil

				return
			end
		end
	end

	if data[2] then
		whitelisted[#whitelisted + 1] = data[1]
	end
end)

netstream.Hook("CharacterAdd", function(data)
	Clockwork.character:Add(data.characterID, data)

	if not Clockwork.character:IsPanelLoading() then
		Clockwork.character:RefreshPanelList()
	end
end)

netstream.Hook("CharacterMenu", function(data)
	local menuState = data

	if menuState == CHARACTER_MENU_LOADED then
		if Clockwork.character:GetPanel() then
			Clockwork.character:SetPanelLoading(false)
			Clockwork.character:RefreshPanelList()
		end
	elseif menuState == CHARACTER_MENU_CLOSE then
		Clockwork.character:SetPanelOpen(false)
	elseif menuState == CHARACTER_MENU_OPEN then
		Clockwork.character:SetPanelOpen(true)
	end
end)

netstream.Hook("CharacterOpen", function(data)
	Clockwork.character:SetPanelOpen(true)

	if data then
		Clockwork.character.isMenuReset = true
	end
end)

netstream.Hook("CharacterFinish", function(data)
	if data.wasSuccess then
		Clockwork.character:SetPanelMainMenu()
		Clockwork.character:SetPanelOpen(false, true)
		Clockwork.character:SetFault(nil)
	else
		Clockwork.character:SetFault(data.fault)
	end
end)

Clockwork.character:RegisterCreationPanel("CreateCharacterStage1", "cwCharacterStageOne")
Clockwork.character:RegisterCreationPanel("CreateCharacterStage2", "cwCharacterStageTwo")

Clockwork.character:RegisterCreationPanel("CreateCharacterStage3", "cwCharacterStageThree", nil, function(info)
	local classTable = Clockwork.class:GetAll()

	if table.Count(classTable) > 0 then
		for k, v in pairs(classTable) do
			if v.isOnCharScreen and (v.factions and table.HasValue(v.factions, info.faction)) then return true end
		end
	end

	return false
end)

Clockwork.character:RegisterCreationPanel("CreateCharacterStage4", "cwCharacterStageFour", nil, function(info)
	local attributeTable = Clockwork.attribute:GetAll()

	if table.Count(attributeTable) > 0 then
		for k, v in pairs(attributeTable) do
			if v.isOnCharScreen and (not v.factions or table.HasValue(v.factions, info.faction)) then return true end
		end
	end

	return false
end)