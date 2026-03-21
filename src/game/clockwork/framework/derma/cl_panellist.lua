
local Color = Color
local vgui = vgui

local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.backgroundColor = Color(255, 255, 255, 255)
end

-- A function to set the background color.
function PANEL:SetBackgroundColor(color)
	self.backgroundColor = color
end

-- Called when the panel should be painted.
function PANEL:Paint(w, h)
	surface.SetDrawColor(self.backgroundColor)
	surface.DrawRect(0, 0, w, h)
	derma.SkinHook('Paint', 'cwPanelList', self, w, h)
end;

-- A function to clear the panel list.
function PANEL:Clear()
	for _, v in next, self.Items do if IsValid(v) then v:Remove() end end
	self.Items = {}
end

vgui.Register("cwPanelList", PANEL, "DPanelList")