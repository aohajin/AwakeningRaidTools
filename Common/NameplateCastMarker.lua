local _, addon = ...

local NameplateCastMarker = {}
NameplateCastMarker.name = "NameplateCastMarker"

local eventFrame = CreateFrame("Frame")

local function IsNameplateUnit(unit)
    return type(unit) == "string" and unit:sub(1, 9) == "nameplate"
end

local function GetMarker(unit)
    local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
    if not namePlate or not namePlate.UnitFrame then
        return nil
    end

    local unitFrame = namePlate.UnitFrame
    if unitFrame.ARTCastMarker then
        return unitFrame.ARTCastMarker
    end

    local marker = unitFrame:CreateFontString(nil, "OVERLAY")
    marker:SetFont(STANDARD_TEXT_FONT, 28, "OUTLINE")
    marker:SetPoint("BOTTOM", unitFrame, "TOP", 0, 10)
    marker:Hide()

    unitFrame.ARTCastMarker = marker
    return marker
end

local function HideMarker(unit)
    local marker = GetMarker(unit)
    if marker then
        marker:Hide()
    end
end

local function UpdateUnit(unit)
    if not IsNameplateUnit(unit) then
        return
    end

    local marker = GetMarker(unit)
    if not marker then
        return
    end

    local spellName, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
    if not spellName then
        spellName, _, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
    end

    if not spellName then
        marker:Hide()
        return
    end

    if notInterruptible then
        marker:SetText("1")
        marker:SetTextColor(1, 0.1, 0.1)
    else
        marker:SetText("cc")
        marker:SetTextColor(0.1, 1, 0.1)
    end

    marker:Show()
end

local function RefreshAllVisibleNameplates()
    local namePlates = C_NamePlate.GetNamePlates() or {}
    for _, plate in ipairs(namePlates) do
        local unit = plate.namePlateUnitToken
        if unit then
            UpdateUnit(unit)
        end
    end
end

function NameplateCastMarker:OnInitialize()
    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "NAME_PLATE_UNIT_ADDED" then
            UpdateUnit(unit)
            return
        end

        if event == "NAME_PLATE_UNIT_REMOVED" then
            HideMarker(unit)
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            RefreshAllVisibleNameplates()
            return
        end

        UpdateUnit(unit)
    end)

    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
end

addon:RegisterModule("Common.NameplateCastMarker", NameplateCastMarker)
