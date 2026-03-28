local _, addon = ...

local NameplateCastMarker = {}
NameplateCastMarker.name = "NameplateCastMarker"

local managerFrame = CreateFrame("Frame")
local watchersByUnit = {}

local function CreateMarker(parent, text, r, g, b)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(64, 64)
    holder:SetFrameStrata("TOOLTIP")
    holder:SetFrameLevel(parent:GetFrameLevel() + 100)

    local bg = holder:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(r, g, b, 0.95)
    holder.bg = bg

    local label = holder:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, 32, "OUTLINE")
    label:SetPoint("CENTER", holder, "CENTER", 0, 0)
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(text)
    holder.label = label

    holder:Hide()
    return holder
end

local function GetMarkers(namePlate)
    if not namePlate then
        return nil, nil
    end

    if not namePlate.ARTCastMarkerRed then
        local red = CreateMarker(namePlate, "1", 0.9, 0.1, 0.1)
        red:SetPoint("CENTER", namePlate, "CENTER", 0, 42)
        namePlate.ARTCastMarkerRed = red
    end

    if not namePlate.ARTCastMarkerGreen then
        local green = CreateMarker(namePlate, "cc", 0.1, 0.75, 0.2)
        green:SetPoint("CENTER", namePlate, "CENTER", 0, 42)
        namePlate.ARTCastMarkerGreen = green
    end

    return namePlate.ARTCastMarkerRed, namePlate.ARTCastMarkerGreen
end

local function HideMarkers(unit)
    local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
    local red, green = GetMarkers(namePlate)
    if red then red:Hide() end
    if green then green:Hide() end
end

local function ApplyCasting(unit)
    local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
    local red, green = GetMarkers(namePlate)
    if not red or not green then
        return
    end
    red:SetFrameStrata("TOOLTIP")
    green:SetFrameStrata("TOOLTIP")
    red:SetFrameLevel(namePlate:GetFrameLevel() + 100)
    green:SetFrameLevel(namePlate:GetFrameLevel() + 100)

    local castName, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
    if notInterruptible == nil then
        local channelName
        channelName, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
        castName = castName or channelName
    end

    if castName == nil then
        red:Hide()
        green:Hide()
        return
    end

    local redAlpha = 1
    local greenAlpha = 1
    if C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean then
        redAlpha = C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptible, 1, 0)
        greenAlpha = C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptible, 0, 1)
    end

    red:SetAlpha(redAlpha or 1)
    green:SetAlpha(greenAlpha or 1)
    red:Show()
    green:Show()
end

local function RegisterWatcher(unit)
    if watchersByUnit[unit] then
        return
    end

    local watcher = CreateFrame("Frame")
    watcher.unit = unit
    watcher:SetScript("OnEvent", function(self, event)
        if event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
            HideMarkers(self.unit)
        else
            ApplyCasting(self.unit)
        end
    end)

    watcher:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", unit)

    watchersByUnit[unit] = watcher
    ApplyCasting(unit)
end

local function UnregisterWatcher(unit)
    local watcher = watchersByUnit[unit]
    if not watcher then
        return
    end

    watcher:UnregisterAllEvents()
    watcher:SetScript("OnEvent", nil)
    watchersByUnit[unit] = nil
    HideMarkers(unit)
end

function NameplateCastMarker:OnInitialize()
    managerFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "NAME_PLATE_UNIT_ADDED" then
            RegisterWatcher(unit)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            UnregisterWatcher(unit)
        end
    end)

    managerFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    managerFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            RegisterWatcher(unit)
        end
    end
end

addon:RegisterModule("Common.NameplateCastMarker", NameplateCastMarker)
