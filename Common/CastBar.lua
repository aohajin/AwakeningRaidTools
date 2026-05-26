local _, addon = ...

local CastBar = {}
CastBar.name = "CastBar"

local bar = nil

local function Create()
	if bar then return bar end
	bar = CreateFrame("StatusBar", nil, UIParent)
	bar:SetSize(350, 32)
	bar:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
	bar:SetFrameStrata("TOOLTIP")
	bar:SetClampedToScreen(true)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(1)

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.5)

	bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	bar:SetStatusBarColor(0.29, 0.91, 1.0, 1)

	bar.spark = bar:CreateTexture(nil, "OVERLAY")
	bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	bar.spark:SetSize(20, 48)
	bar.spark:SetBlendMode("ADD")

	bar.Icon = bar:CreateTexture(nil, "OVERLAY")
	bar.Icon:SetSize(44, 44)
	bar.Icon:SetPoint("RIGHT", bar, "LEFT", -8, 0)
	bar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	bar.Text = bar:CreateFontString(nil, "OVERLAY")
	bar.Text:SetPoint("LEFT", bar, "LEFT", 10, 0)
	bar.Text:SetDrawLayer("OVERLAY", 7)
	bar.Text:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
	bar.Text:SetTextColor(1, 1, 1, 1)
	bar.Text:SetJustifyH("LEFT")
	bar.Text:SetWidth(200)

	bar.TargetNameText = bar:CreateFontString(nil, "OVERLAY")
	bar.TargetNameText:SetPoint("RIGHT", bar, "RIGHT", -10, 0)
	bar.TargetNameText:SetDrawLayer("OVERLAY", 7)
	bar.TargetNameText:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
	bar.TargetNameText:SetTextColor(1, 1, 1, 1)
	bar.TargetNameText:SetJustifyH("RIGHT")
	bar.TargetNameText:SetWidth(150)

	bar.Cooldown = CreateFrame("Cooldown", nil, bar, "CooldownFrameTemplate")
	bar.Cooldown:SetAllPoints()
	bar.Cooldown:SetReverse(true)
	bar.Cooldown:SetDrawSwipe(false)
	bar.Cooldown:SetDrawEdge(false)
	bar.Cooldown:SetDrawBling(false)
	bar.Cooldown:SetHideCountdownNumbers(true)

	bar:Hide()
	return bar
end

function CastBar:SetAnchor(frame, point, relPoint, x, y)
	Create()
	bar:ClearAllPoints()
	bar:SetPoint(point or "CENTER", frame or UIParent, relPoint or "CENTER", x or 0, y or 0)
end

function CastBar:Show(unit)
	if not unit or not UnitExists(unit) then self:Hide(); return end
	Create()

	-- Same pattern as ExwindTools GetFocusCastInfo
	local objCast = UnitCastingDuration(unit)
	local objChannel = UnitChannelDuration(unit)
	local activeObj = objCast or objChannel
	local isChannel = (objChannel ~= nil)
	if not activeObj then self:Hide(); return end

	local name, texture
	if isChannel then
		name, _, texture = UnitChannelInfo(unit)
	else
		name, _, texture = UnitCastingInfo(unit)
	end
	if not name then self:Hide(); return end

	-- Same pattern as ExwindTools ApplyFocusCastToBar: direct set, no secret checks
	bar.Icon:SetTexture(texture)
	bar.Text:SetText(name)

	local target = UnitSpellTargetName(unit)
	if target then
		bar.TargetNameText:SetText(target)
		local tc = UnitSpellTargetClass(unit)
		local color = C_ClassColor.GetClassColor(tc)
		if color then bar.TargetNameText:SetTextColor(color.r, color.g, color.b, 1)
		else bar.TargetNameText:SetTextColor(1, 1, 1, 1) end
		bar.TargetNameText:Show()
	else
		bar.TargetNameText:Hide()
	end

	bar:SetTimerDuration(activeObj, Enum.StatusBarInterpolation.None, isChannel and 1 or 0)
	bar.Cooldown:SetCooldownFromDurationObject(activeObj, true)
	bar:Show()
end

function CastBar:GetIconFrame()
	Create()
	return bar.Icon
end

function CastBar:Hide()
	if bar then bar:Hide() end
end

function CastBar:OnInitialize() end

addon:RegisterModule("Common.CastBar", CastBar)
