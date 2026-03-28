local _, addon = ...

local NameplateCastMarker = {}
NameplateCastMarker.name = "NameplateCastMarker"

local refreshTicker

local function GetMarkers(namePlate)
    if not namePlate then
        return nil, nil
    end

    if not namePlate.ARTCastMarkerRed then
        local red = namePlate:CreateFontString(nil, "OVERLAY")
        red:SetFont(STANDARD_TEXT_FONT, 36, "OUTLINE")
        red:SetPoint("CENTER", namePlate, "CENTER", -14, 30)
        red:SetTextColor(1, 0.1, 0.1)
        red:SetText("1")
        red:Hide()
        namePlate.ARTCastMarkerRed = red
    end

    if not namePlate.ARTCastMarkerGreen then
        local green = namePlate:CreateFontString(nil, "OVERLAY")
        green:SetFont(STANDARD_TEXT_FONT, 36, "OUTLINE")
        green:SetPoint("CENTER", namePlate, "CENTER", 14, 30)
        green:SetTextColor(0.1, 1, 0.1)
        green:SetText("cc")
        green:Hide()
        namePlate.ARTCastMarkerGreen = green
    end

    return namePlate.ARTCastMarkerRed, namePlate.ARTCastMarkerGreen
end

local function UpdateUnit(unit)
    local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
    local red, green = GetMarkers(namePlate)
    if not red or not green then
        return
    end

    local castName = UnitCastingInfo(unit)
    if not castName then
        castName = UnitChannelInfo(unit)
    end

    if castName then
        local _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
        if notInterruptible == nil then
            _, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
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
    else
        red:Hide()
        green:Hide()
    end
end

local function RefreshAllVisibleNameplates()
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            UpdateUnit(unit)
        end
    end
end

function NameplateCastMarker:OnInitialize()
    refreshTicker = C_Timer.NewTicker(0.05, RefreshAllVisibleNameplates)
end

addon:RegisterModule("Common.NameplateCastMarker", NameplateCastMarker)
