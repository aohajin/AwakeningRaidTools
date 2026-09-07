local _, addon = ...

local CastBar = {}
CastBar.name = "CastBar"

local LEM = LibStub("LibEQOLEditMode-1.0")
local LSM = LibStub("LibSharedMedia-3.0")

local bar = nil
local isEditMode = false

local VALID_STRATA = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG"}

local DEFAULT_CONFIG = {
	point = "CENTER",
	x = 0,
	y = 200,
	scale = 1,
	texture = "Blizzard",
	font = "Friz Quadrata TT",
	fontsize = 18,
	strata = "MEDIUM",
	counterScale = 1,
}

local function GetConfig()
	local db = AwakeningRaidToolsDB
	if db and db.encounters and db.encounters[3183] and db.encounters[3183].castBar then
		return db.encounters[3183].castBar
	end
	return DEFAULT_CONFIG
end

local function SaveConfig(key, value)
	local db = AwakeningRaidToolsDB
	if not db.encounters then db.encounters = {} end
	if not db.encounters[3183] then db.encounters[3183] = {} end
	if not db.encounters[3183].castBar then db.encounters[3183].castBar = {} end
	db.encounters[3183].castBar[key] = value
end

local function ApplyConfig()
	local cfg = GetConfig()
	if bar then
		local s = cfg.strata or "MEDIUM"
		bar:SetFrameStrata(s)
		bar:ClearAllPoints()
		bar:SetPoint(cfg.point or "CENTER", UIParent, cfg.point or "CENTER", cfg.x or 0, cfg.y or 200)
		bar:SetScale(cfg.scale or 1)

		local tex = LSM:Fetch("statusbar", cfg.texture or "Blizzard")
		if tex then bar.statusBar:SetStatusBarTexture(tex) end

		local font = LSM:Fetch("font", cfg.font or "Friz Quadrata TT")
		if font then
			local fs = cfg.fontsize or 18
			bar.spellName:SetFont(font, fs, "OUTLINE")
			bar.targetName:SetFont(font, math.max(10, fs - 2), "OUTLINE")
		end
		local counter = addon.modules["Common.Counter"]
		if counter then
			local cm = counter:GetMarker("center")
			if cm then cm:SetFrameStrata(s); cm:SetScale(cfg.counterScale or cfg.scale or 1) end
		end
	end
end

local function OnPositionChanged(frame, layoutName, point, x, y)
	SaveConfig("point", point)
	SaveConfig("x", x)
	SaveConfig("y", y)
end

local function ShowEditPreview()
	if not isEditMode then return end
	bar.Icon:SetTexture(136197)
	bar.Icon:Show()
	bar.spellName:SetText("Sample Spell")
	bar.targetName:SetText("Target")
	bar.targetName:Show()
	bar.statusBar:SetValue(0.55)
	bar:Show()

	local counter = addon.modules["Common.Counter"]
	if counter then
		local cfg = GetConfig()
		counter:GetMarker("center"):SetFrameStrata(cfg.strata or "MEDIUM")
		counter:SetAnchor("center", bar.Icon, "RIGHT", "LEFT", -8, 0)
		counter:Show("center", "1", GetConfig().scale or 1)
	end
end

local function Create()
	if bar then return bar end

	bar = CreateFrame("Frame", nil, UIParent)
	bar:SetSize(350, 32)
	bar:SetFrameStrata("MEDIUM")
	bar:SetClampedToScreen(true)
	bar.editModeName = "Art Lura cast bar"

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.5)

	bar.statusBar = CreateFrame("StatusBar", nil, bar)
	bar.statusBar:SetAllPoints()
	bar.statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	bar.statusBar:SetStatusBarColor(0.29, 0.91, 1.0, 1)
	bar.statusBar:SetMinMaxValues(0, 1)
	bar.statusBar:SetValue(1)

	bar.spark = bar:CreateTexture(nil, "OVERLAY")
	bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	bar.spark:SetSize(20, 48)
	bar.spark:SetBlendMode("ADD")

	bar.Icon = bar:CreateTexture(nil, "OVERLAY")
	bar.Icon:SetSize(44, 44)
	bar.Icon:SetPoint("RIGHT", bar, "LEFT", -8, 0)
	bar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local textOverlay = CreateFrame("Frame", nil, bar)
	textOverlay:SetAllPoints()
	textOverlay:SetFrameLevel(bar.statusBar:GetFrameLevel() + 10)

	bar.spellName = textOverlay:CreateFontString(nil, "OVERLAY")
	bar.spellName:SetPoint("LEFT", textOverlay, "LEFT", 10, 0)
	bar.spellName:SetJustifyH("LEFT")
	bar.spellName:SetWidth(200)

	bar.targetName = textOverlay:CreateFontString(nil, "OVERLAY")
	bar.targetName:SetPoint("RIGHT", textOverlay, "RIGHT", -10, 0)
	bar.targetName:SetJustifyH("RIGHT")
	bar.targetName:SetWidth(150)

	bar.Cooldown = CreateFrame("Cooldown", nil, bar, "CooldownFrameTemplate")
	bar.Cooldown:SetAllPoints()
	bar.Cooldown:SetReverse(true)
	bar.Cooldown:SetDrawSwipe(false)
	bar.Cooldown:SetDrawEdge(false)
	bar.Cooldown:SetDrawBling(false)
	bar.Cooldown:SetHideCountdownNumbers(true)

		bar:SetPoint("CENTER", UIParent, "CENTER", 0, 200)

	LEM:AddFrame(bar, OnPositionChanged, {
		baseFrameName = "Art Lura cast bar",
		name = "Art Lura cast bar", point = "CENTER", x = 0, y = 200,
		enableOverlayToggle = true,
		showReset = true,
	})
	-- LEM doesn't set system.name; Blizzard EditMode needs it for tooltip
	for _, child in ipairs({bar:GetChildren()}) do
		if child.system then
			child.system.name = child.systemBaseName or "Art Lura cast bar"
			break
		end
	end

	local buildStrataValues = function()
		local t = {}
		for _, s in ipairs(VALID_STRATA) do table.insert(t, { text = s, value = s }) end
		return t
	end
	local buildTexValues = function()
		local t = {}
		for _, n in ipairs(LSM:List("statusbar")) do table.insert(t, { text = n, value = n }) end
		return t
	end
	local buildFontValues = function()
		local t = {}
		for _, n in ipairs(LSM:List("font")) do table.insert(t, { text = n, value = n }) end
		return t
	end

	LEM:AddFrameSettings(bar, {
		{ name = "Scale", kind = LEM.SettingType.Slider, default = 1,
			minValue = 0.3, maxValue = 3, valueStep = 0.1,
			get = function() return GetConfig().scale or 1 end,
			set = function(_, v) SaveConfig("scale", v); ApplyConfig() end },
		{ name = "Texture", kind = LEM.SettingType.Dropdown, default = "Blizzard",
			get = function() return GetConfig().texture or "Blizzard" end,
			set = function(_, v) SaveConfig("texture", v); ApplyConfig() end,
			values = buildTexValues() },
		{ name = "Font", kind = LEM.SettingType.Dropdown, default = "Friz Quadrata TT",
			get = function() return GetConfig().font or "Friz Quadrata TT" end,
			set = function(_, v) SaveConfig("font", v); ApplyConfig() end,
			values = buildFontValues() },
		{ name = "Font Size", kind = LEM.SettingType.Slider, default = 18,
			minValue = 10, maxValue = 36, valueStep = 1,
			get = function() return GetConfig().fontsize or 18 end,
			set = function(_, v) SaveConfig("fontsize", v); ApplyConfig() end },
		{ name = "Strata", kind = LEM.SettingType.Dropdown, default = "MEDIUM",
			get = function() return GetConfig().strata or "MEDIUM" end,
			set = function(_, v) SaveConfig("strata", v); ApplyConfig() end,
			values = buildStrataValues() },
		{ name = "Counter Scale", kind = LEM.SettingType.Slider, default = 1,
			minValue = 0.3, maxValue = 5, valueStep = 0.1,
			get = function() return GetConfig().counterScale or 1 end,
			set = function(_, v) SaveConfig("counterScale", v); ApplyConfig() end },
	})

	LEM:RegisterCallback("enter", function()
		isEditMode = true
		ShowEditPreview()
	end)
	LEM:RegisterCallback("exit", function()
		isEditMode = false
		bar.Icon:Hide()
		bar.spellName:SetText("")
		bar.targetName:Hide()
		bar.statusBar:SetValue(1)
		bar:Hide()
		local counter = addon.modules["Common.Counter"]
		if counter then counter:Hide("center") end
	end)

	ApplyConfig()
	bar:Hide()
	return bar
end

function CastBar:SetAnchor(frame, point, relPoint, x, y)
	Create()
end

function CastBar:Show(unit)
	if not unit or not UnitExists(unit) then self:Hide(); return end
	Create()
	if isEditMode then return end

	local objCast = UnitCastingDuration(unit)
	local objChannel = UnitChannelDuration(unit)
	local activeObj = objCast or objChannel
	local isChannel = (objChannel ~= nil)
	if not activeObj then self:Hide(); return end

	local name, texture
	if isChannel then name, _, texture = UnitChannelInfo(unit)
	else name, _, texture = UnitCastingInfo(unit) end

	bar.Icon:SetTexture(texture)
	bar.Icon:Show()
	bar.spellName:SetText(name or "")

	local target = UnitSpellTargetName(unit)
	if target then
		bar.targetName:SetText(target)
		local tc = UnitSpellTargetClass(unit)
		local color = C_ClassColor.GetClassColor(tc)
		if color then bar.targetName:SetTextColor(color.r, color.g, color.b, 1)
		else bar.targetName:SetTextColor(1, 1, 1, 1) end
		bar.targetName:Show()
	else
		bar.targetName:Hide()
	end

	bar.statusBar:SetTimerDuration(activeObj, Enum.StatusBarInterpolation.None, isChannel and 1 or 0)
	bar.Cooldown:SetCooldownFromDurationObject(activeObj, true)
	bar:Show()
end

function CastBar:Hide()
	if bar and not isEditMode then bar:Hide() end
end

function CastBar:GetIconFrame()
	Create()
	return bar.Icon
end

-- Legacy raid feature: the bar (and its Edit Mode entry) must only exist when
-- the LoadOnDemand legacy addon is loaded. The DB per-raid flags decide that,
-- so mirror the LegacyLoader's check instead of unconditionally registering.
local function AnyLegacyRaidEnabled()
    local db = AwakeningRaidToolsDB
    if not (db and db.LegacyRaidEnabled) then return false end
    for _, key in ipairs({ "Voidspire", "Dreamrift", "MarchOfQuelDanas" }) do
        if db.LegacyRaidEnabled[key] then return true end
    end
    return false
end

function CastBar:OnInitialize()
    if AnyLegacyRaidEnabled() then
        Create()
    end
end

addon:RegisterModule("Common.CastBar", CastBar)
