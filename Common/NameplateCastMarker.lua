local _, addon = ...

local NameplateCastMarker = {}
NameplateCastMarker.name = "NameplateCastMarker"
NameplateCastMarker.isEnabled = false
-- NameplateCastMarker.excludeUnits = {}

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

-- local function BuildExcludeUnits(options)
--     local out = {}
--     if type(options) ~= "table" then
--         return out
--     end

--     local exclude = options.exclude or options.excludeUnits
--     if type(exclude) == "string" and exclude ~= "" then
--         out[1] = exclude
--         return out
--     end

--     if type(exclude) == "table" then
--         for i = 1, #exclude do
--             local token = exclude[i]
--             if type(token) == "string" and token ~= "" then
--                 out[#out + 1] = token
--             end
--         end
--     end

--     return out
-- end

-- local function GetVisibilityAlphaForUnit(unit)
--     -- local excludeUnits = NameplateCastMarker.excludeUnits
--     -- if type(excludeUnits) ~= "table" or #excludeUnits == 0 then
--     --     return 1
--     -- end
--     if not (C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean) then
--         return 1
--     end

--     local visibilityAlpha = 1
--     -- for i = 1, #excludeUnits do
--     --     local unitToken = excludeUnits[i]
--     --     visibilityAlpha = C_CurveUtil.EvaluateColorValueFromBoolean(UnitIsUnit(unit, unitToken), 0, visibilityAlpha)
--     -- end

--     return visibilityAlpha or 1
-- end

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
    -- local visibilityAlpha = GetVisibilityAlphaForUnit(unit)
    -- red:SetAlpha(visibilityAlpha)
    -- green:SetAlpha(visibilityAlpha)
    red.bg:SetAlpha(redAlpha or 1)
    red.label:SetAlpha(redAlpha or 1)
    green.bg:SetAlpha(greenAlpha or 1)
    green.label:SetAlpha(greenAlpha or 1)
    red:Show()
    green:Show()
end

local function StopCastTicker(watcher)
    if watcher.castTicker then
        watcher.castTicker:Cancel()
        watcher.castTicker = nil
    end
end

local function StartCastTicker(watcher)
    if watcher.castTicker then
        return
    end
    watcher.castTicker = C_Timer.NewTicker(0.05, function()
        ApplyCasting(watcher.unit)
    end)
end

local function RegisterWatcher(unit)
    if watchersByUnit[unit] then
        return
    end

    local watcher = CreateFrame("Frame")
    watcher.unit = unit
    watcher:SetScript("OnEvent", function(self, event)
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            StartCastTicker(self)
            ApplyCasting(self.unit)
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
            StopCastTicker(self)
            HideMarkers(self.unit)
        else
            ApplyCasting(self.unit)
        end
    end)

    watcher:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", unit)
    watcher:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", unit)
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
    StopCastTicker(watcher)
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
end

function NameplateCastMarker:Enable(options)
    -- self.excludeUnits = BuildExcludeUnits(options)
    if self.isEnabled then
        for unit in pairs(watchersByUnit) do
            ApplyCasting(unit)
        end
        return
    end
    self.isEnabled = true

    managerFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    managerFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            RegisterWatcher(unit)
        end
    end
end

function NameplateCastMarker:Disable()
    if not self.isEnabled then
        return
    end
    self.isEnabled = false
    --self.excludeUnits = {}

    managerFrame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
    managerFrame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")

    for unit in pairs(watchersByUnit) do
        UnregisterWatcher(unit)
    end
end

addon:RegisterModule("Common.NameplateCastMarker", NameplateCastMarker)
