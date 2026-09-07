local _, addon = ...

-- ============================================================================
-- FacingCompass: a screen-centred, 8-direction marker compass that rotates
-- with the player's facing (reads MinimapCompassTexture:GetRotation, the
-- same source Vashnik's crosshair uses). Directions are labelled with the
-- stock raid-target icons.
--
-- Sszorak wind-call integration: markers 1..6 can be clicked (when clicks are
-- enabled) and the caller (boss module) decides what to broadcast. Received
-- calls ("raid_target_N") highlight the OPPOSITE marker with a pulsing ring;
-- an order label (1/2/3) is drawn fixed at the disc centre under the arrow
-- (FontStrings cannot rotate, so the order text stays upright at the centre).
--
-- Public API (used by Raids/.../Sszorak.lua):
--   Enable(strata?) / Disable() / IsActive()
--   SetClicksEnabled(bool) / SetOnMarkerClicked(fn(marker))
--   ShowOppositeCall(marker, order)   -- pulse the marker opposite `marker`
--   SetOrderText(text)                -- fixed centre text under the arrow
--   ClearCalls()                      -- hide all pulses + order text
-- ============================================================================

local FacingCompass = {
    name = "FacingCompass",
    isEnabled = false,
    clickEnabled = false,
    onMarkerClicked = nil, -- function(markerNumber)
}

local MARKER_TEX = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"
local PLAYER_ARROW_TEX = "Interface\\Minimap\\MinimapArrow"
local CIRCLE_TEX = "Interface\\AddOns\\" .. (addon.name or "AwakeningRaidTools") .. "\\media\\Textures\\circle_outline.png"
local RING_RED_TEX = "Interface\\AddOns\\" .. (addon.name or "AwakeningRaidTools") .. "\\media\\Textures\\ring_red.png"

local compassFrame
local markers = {}
local pulseLayers = {} -- [slot] pulse ring layer (rotates with the disc)
local clickButtons = {} -- [marker] click buttons 1..6 (wind-call sender)
local btnRow -- draggable container for the click buttons
local windTable -- draggable order table (序号 1 2 3 / 对侧 rt 图标)
local windTableRow1 = {} -- [slot] order label texture/number
local windTableRow2 = {} -- [slot] opposite-marker icon texture
local background
local playerArrow
local orderText -- fixed centre label under the arrow (1/2/3 order)
local rotationElapsed = 0
local rotationInterval = 0.03

local function MarkerTexture(marker)
    return MARKER_TEX .. marker
end

-- ============================================================================
-- Rotation source (minimap compass). Same guards as Vashnik's crosshair.
-- ============================================================================

local SAVED_ROTATE_MINIMAP
local ellesmereSettings
local ellesmereRotateCaptured = false
local ellesmereRotateWasNil = false
local ellesmereRotateValue
local ellesmereRegionState = {}
local ELLESMERE_COMPASS_ALPHA = 0.001

local function GetEllesmereMinimapSettings()
    local db = rawget(_G, "_EMM_DB")
    local profile = type(db) == "table" and db.profile
    local settings = type(profile) == "table" and profile.minimap
    if type(settings) == "table" then return settings end
end

local function RestoreEllesmereSetting()
    if not (ellesmereSettings and ellesmereRotateCaptured) then return end
    if ellesmereRotateWasNil then
        ellesmereSettings.rotateMinimap = nil
    else
        ellesmereSettings.rotateMinimap = ellesmereRotateValue
    end
    ellesmereSettings = nil
    ellesmereRotateCaptured = false
    ellesmereRotateWasNil = false
    ellesmereRotateValue = nil
end

local function KeepEllesmereRegionLive(region, alpha)
    if not region then return end
    if not ellesmereRegionState[region] then
        ellesmereRegionState[region] = {
            shown = region:IsShown(),
            alpha = region:GetAlpha(),
        }
    end
    if region:GetAlpha() ~= alpha then region:SetAlpha(alpha) end
    if not region:IsShown() then region:Show() end
end

local function RestoreEllesmereRegions()
    for region, state in pairs(ellesmereRegionState) do
        region:SetAlpha(state.alpha)
        if state.shown then region:Show() else region:Hide() end
    end
    wipe(ellesmereRegionState)
end

local function EnsureEllesmereCompatibility()
    local settings = GetEllesmereMinimapSettings()
    if not settings then return end
    if settings ~= ellesmereSettings then
        RestoreEllesmereSetting()
        ellesmereSettings = settings
        ellesmereRotateCaptured = true
        ellesmereRotateWasNil = settings.rotateMinimap == nil
        ellesmereRotateValue = settings.rotateMinimap
    end
    settings.rotateMinimap = true
    KeepEllesmereRegionLive(rawget(_G, "MinimapBackdrop"), 1)
    KeepEllesmereRegionLive(rawget(_G, "MinimapCompassTexture"), ELLESMERE_COMPASS_ALPHA)
end

local function RestoreRotateSource()
    RestoreEllesmereSetting()
    RestoreEllesmereRegions()
    if SAVED_ROTATE_MINIMAP then
        SetCVar("rotateMinimap", SAVED_ROTATE_MINIMAP)
        SAVED_ROTATE_MINIMAP = nil
    end
end

-- ============================================================================
-- Options + layout
-- ============================================================================

local function cfg(key)
    local db = AwakeningRaidToolsDB
    local v = db and db.FacingCompass and db.FacingCompass[key]
    if v == nil then
        local defaults = { size = 220, alpha = 0.9, markerSize = 28 }
        return defaults[key]
    end
    return v
end

-- Direction layout: 8 compass points at 45°, due EAST = 0° CCW, offset 30°.
--   dir 0 (slot 1) = 30°  (EMPTY)   dir 4 (slot 5) = 210° (EMPTY)
--   dir 1 (slot 2) = 75°  -> mark 1
--   dir 2 (slot 3) = 120° -> mark 2
--   dir 3 (slot 4) = 165° -> mark 3
--   dir 5 (slot 6) = 255° -> mark 4
--   dir 6 (slot 7) = 300° -> mark 5
--   dir 7 (slot 8) = 345° -> mark 6
local HIDDEN_SLOTS = { [1] = true, [5] = true }
local VISIBLE_ORDER = { 2, 3, 4, 6, 7, 8 } -- slots in angular order (marks 1..6)

local function DirectionAngle(slot)
    return 30 + (slot - 1) * 45
end

-- Marker number (1..6 as called) -> compass slot.
local function SlotForMarker(marker)
    return VISIBLE_ORDER[marker]
end

-- The slot exactly opposite (180° = +4 slots).
local function OppositeSlot(slot)
    return ((slot + 3) % 8) + 1
end

-- Marker number of the slot opposite the given marker's slot.
local function OppositeMarker(marker)
    return ((marker + 2) % 6) + 1
end

-- Geometry for a slot (shared by icon + pulse layers).
local function SlotGeometry(slot)
    local size = cfg("size")
    local markerSize = cfg("markerSize")
    local outlineRadius = size * 0.43
    local markerRadius = outlineRadius * math.cos(math.pi / 8)
    local rotationScale = math.sqrt(2)
    local layerSize = size * rotationScale
    local layerHalf = layerSize * 0.5
    local markerHalf = markerSize * rotationScale * 0.5
    local angle = math.rad(DirectionAngle(slot))
    local markerX = math.cos(angle) * markerRadius
    local markerY = math.sin(angle) * markerRadius
    return {
        layerSize = layerSize,
        layerHalf = layerHalf,
        markerHalf = markerHalf,
        targetX = markerX * rotationScale,
        targetY = markerY * rotationScale,
    }
end

-- Window a full-disc layer onto one slot's direction point.
local function PositionLayerAtSlot(layer, geo)
    layer:SetSize(geo.layerSize, geo.layerSize)
    layer:SetScale(1)
    layer:ClearAllPoints()
    layer:SetPoint("CENTER", compassFrame, "CENTER", 0, 0)
    layer:ClearVertexOffsets()
    local g = geo
    layer:SetVertexOffset(UPPER_LEFT_VERTEX,
        g.targetX - g.markerHalf + g.layerHalf, g.targetY + g.markerHalf - g.layerHalf)
    layer:SetVertexOffset(LOWER_LEFT_VERTEX,
        g.targetX - g.markerHalf + g.layerHalf, g.targetY - g.markerHalf + g.layerHalf)
    layer:SetVertexOffset(UPPER_RIGHT_VERTEX,
        g.targetX + g.markerHalf - g.layerHalf, g.targetY + g.markerHalf - g.layerHalf)
    layer:SetVertexOffset(LOWER_RIGHT_VERTEX,
        g.targetX + g.markerHalf - g.layerHalf, g.targetY - g.markerHalf + g.layerHalf)
end

local function ApplyMarkerLayout()
    if not compassFrame then return end
    for slot = 1, 8 do
        local marker = markers[slot]
        if marker then
            if HIDDEN_SLOTS[slot] then
                marker:Hide()
            else
                local iconIdx = 0
                for i = 1, #VISIBLE_ORDER do
                    if VISIBLE_ORDER[i] == slot then
                        iconIdx = i
                        break
                    end
                end
                marker:SetRotation(0)
                marker:SetTexture(MarkerTexture(iconIdx), "CLAMP", "CLAMP")
                marker:SetHorizTile(false)
                marker:SetVertTile(false)
                marker:SetTexCoord(0, 1, 0, 1)
                PositionLayerAtSlot(marker, SlotGeometry(slot))
                marker:Show()
            end
        end
        local pulse = pulseLayers[slot]
        if pulse then
            if HIDDEN_SLOTS[slot] then
                pulse:Hide()
            else
                -- Ring larger than the marker icon (1.4x window) so the red
                -- outline clearly surrounds the icon.
                local geo = SlotGeometry(slot)
                geo.markerHalf = geo.markerHalf * 1.4
                PositionLayerAtSlot(pulse, geo)
                pulse:Show()
            end
        end
    end
    local markerSize = cfg("markerSize")
    if playerArrow then
        local arrowSize = math.max(18, markerSize * 0.85)
        playerArrow:SetSize(arrowSize, arrowSize)
    end
end

local function ApplyOptions()
    if not compassFrame then return end
    local size = cfg("size")
    local markerSize = cfg("markerSize")
    compassFrame:SetSize(size, size)
    compassFrame:SetAlpha(cfg("alpha"))
    if background then
        local outlineRadius = size * 0.43
        local markerRadius = outlineRadius * math.cos(math.pi / 8)
        local discRadius = (markerRadius * math.sqrt(2)) + markerSize
        background:SetSize(discRadius * 2, discRadius * 2)
    end
    ApplyMarkerLayout()
end

-- Rotation updater: rotate icon and pulse layers together.
local function OnCompassUpdate(self, elapsed)
    rotationElapsed = rotationElapsed + elapsed
    if rotationElapsed < rotationInterval then return end
    rotationElapsed = 0
    EnsureEllesmereCompatibility()
    local texture = rawget(_G, "MinimapCompassTexture")
    if not texture then return end
    local ok, rotation = pcall(texture.GetRotation, texture)
    if not ok or not rotation then return end
    for slot = 1, 8 do
        local layer = markers[slot]
        if layer and layer:IsShown() then
            pcall(layer.SetRotation, layer, rotation)
        end
        local pulse = pulseLayers[slot]
        if pulse and pulse:IsShown() then
            pcall(pulse.SetRotation, pulse, rotation)
        end
    end
end

-- ============================================================================

local function CreateCompassFrame()
    if compassFrame then return compassFrame end
    compassFrame = _G.CreateFrame("Frame", "ART_FacingCompass", UIParent)
    compassFrame:SetFrameStrata("DIALOG")
    compassFrame:SetFrameLevel(180)
    compassFrame:SetClampedToScreen(true)
    compassFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    background = compassFrame:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(CIRCLE_TEX)
    background:SetVertexColor(0, 0, 0, 1)
    background:SetPoint("CENTER")

    playerArrow = compassFrame:CreateTexture(nil, "OVERLAY", nil, 2)
    playerArrow:SetPoint("CENTER")
    playerArrow:SetTexture(PLAYER_ARROW_TEX)

    -- Order label fixed under the arrow (cannot rotate with the disc, so it
    -- stays upright at the centre; shows e.g. "2" for the 2nd call).
    orderText = compassFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    orderText:SetPoint("CENTER", compassFrame, "CENTER", 0, -18)
    orderText:SetTextColor(0.35, 1, 0.55, 1)
    orderText:Hide()

    for slot = 1, 8 do
        markers[slot] = compassFrame:CreateTexture(nil, "OVERLAY")
        markers[slot]:SetTexture(MarkerTexture(slot))
    end
    -- Pulse ring layers (bright red outline) above icons.
    for slot = 1, 8 do
        local pulse = compassFrame:CreateTexture(nil, "OVERLAY", nil, 3)
        pulse:SetTexture(RING_RED_TEX)
        pulseLayers[slot] = pulse
        pulse:Hide()
    end

    -- Click buttons (markers 1..6, raid icons) in a draggable row anchored
    -- under the compass; shown only when wind-call sending is enabled.
    -- The row is its own UIParent frame so StartMoving works; its position is
    -- stored to DB.FacingCompass.btnPos.
    btnRow = _G.CreateFrame("Frame", nil, UIParent)
    btnRow:SetFrameStrata("DIALOG")
    btnRow:SetFrameLevel(200)
    btnRow:SetSize(6 * 38, 40)
    -- Anchor to UIParent (absolute), positioned under the compass unless the
    -- user dragged it before (saved btnPos). Anchoring to UIParent keeps
    -- StartMoving/StopMovingOrSizing stable.
    local savedPos = cfg("btnPos")
    if type(savedPos) == "table" and savedPos.x then
        btnRow:SetPoint(savedPos.point or "CENTER", UIParent,
            savedPos.relativePoint or "CENTER", savedPos.x, savedPos.y)
    else
        -- Initial: directly under the (screen-centred) compass.
        btnRow:SetPoint("CENTER", UIParent, "CENTER", 0, -(cfg("size") * 0.5 + 34))
    end
    btnRow:EnableMouse(true)
    -- Manual right-button drag (frame drag APIs can conflict with the child
    -- buttons' click handling). We track cursor movement ourselves.
    local dragging = false
    local dragStartX, dragStartY = 0, 0
    local baseX, baseY = 0, 0
    btnRow:Hide()

    for i = 1, 6 do
        local btn = _G.CreateFrame("Button", nil, btnRow)
        btn:SetSize(34, 34)
        btn:SetPoint("CENTER", btnRow, "CENTER", (i - 3.5) * 38, 0)
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(btn)
        icon:SetTexture(MarkerTexture(i))
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- trim raid-icon ring padding
        local marker = i -- capture
        -- Left click sends the call; right button starts a drag of the row.
        btn:RegisterForClicks("LeftButtonUp")
        btn:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                if FacingCompass.onMarkerClicked then
                    FacingCompass.onMarkerClicked(marker)
                end
            end
        end)
        -- Manual drag: right button down -> begin, move -> follow, up -> end.
        btn:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" and not dragging then
                dragging = true
                dragStartX, dragStartY = GetCursorPosition()
                local _, _, _, x, y = btnRow:GetPoint(1)
                baseX, baseY = x or 0, y or 0
            end
        end)
        btn:SetScript("OnUpdate", function(self, elapsed)
            if not dragging then return end
            local curX, curY = GetCursorPosition()
            local scale = self:GetEffectiveScale()
            local dx = (curX - dragStartX) / scale
            local dy = (curY - dragStartY) / scale
            btnRow:ClearAllPoints()
            btnRow:SetPoint("CENTER", UIParent, "CENTER", baseX + dx, baseY + dy)
        end)
        btn:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" and dragging then
                dragging = false
                local point, _, relativePoint, x, y = btnRow:GetPoint(1)
                AwakeningRaidToolsDB.FacingCompass = AwakeningRaidToolsDB.FacingCompass or {}
                AwakeningRaidToolsDB.FacingCompass.btnPos = { point = point, relativePoint = relativePoint, x = x, y = y }
            end
        end)
        clickButtons[i] = btn
    end

    -- Wind order table: two rows (order 1..3 / opposite marker icons). Shown
    -- with the compass during combat/preview; draggable like btnRow.
    windTable = _G.CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    windTable:SetFrameStrata("DIALOG")
    windTable:SetFrameLevel(190)
    windTable:SetSize(3 * 40, 74)
    local wtPos = cfg("windTablePos")
    if type(wtPos) == "table" and wtPos.x then
        windTable:SetPoint(wtPos.point or "CENTER", UIParent,
            wtPos.relativePoint or "CENTER", wtPos.x, wtPos.y)
    else
        -- Default: directly above the (screen-centred) compass.
        windTable:SetPoint("CENTER", UIParent, "CENTER", 0, (cfg("size") * 0.5 + 46))
    end
    windTable:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    windTable:SetBackdropColor(0.02, 0.04, 0.08, 0.65)
    windTable:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.6)

    -- Row 1: order numbers 1 2 3 (always visible).
    for slot = 1, 3 do
        local num = windTable:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        num:SetPoint("CENTER", windTable, "TOP", 0, -18)
        num:ClearAllPoints()
        num:SetPoint("CENTER", windTable, "TOPLEFT", (slot - 0.5) * 40, -18)
        num:SetText(tostring(slot))
        num:SetTextColor(0.85, 0.9, 1, 1)
        windTableRow1[slot] = num
    end
    -- Separator line between the number row and the icon row.
    local sep = windTable:CreateTexture(nil, "OVERLAY")
    sep:SetTexture("Interface\\Buttons\\WHITE8x8")
    sep:SetVertexColor(0.5, 0.5, 0.6, 0.7)
    sep:SetPoint("TOPLEFT", windTable, "TOPLEFT", 4, -30)
    sep:SetPoint("TOPRIGHT", windTable, "TOPRIGHT", -4, -30)
    sep:SetHeight(1)

    -- Row 2: opposite marker icons (filled on calls, empty otherwise).
    for slot = 1, 3 do
        local icon = windTable:CreateTexture(nil, "OVERLAY")
        icon:SetSize(28, 28)
        icon:SetPoint("CENTER", windTable, "BOTTOMLEFT", (slot - 0.5) * 40, 18)
        windTableRow2[slot] = icon
    end
    -- Draggable table: a full-size transparent mouse layer on top so any
    -- point (numbers/icons/padding) can be grabbed with left OR right button.
    local dragLayer = _G.CreateFrame("Frame", nil, windTable)
    dragLayer:SetAllPoints(windTable)
    dragLayer:SetFrameLevel(50)
    dragLayer:EnableMouse(true)
    dragLayer:RegisterForDrag("LeftButton", "RightButton")
    local wtDragging = false
    local wtStartX, wtStartY = 0, 0
    local wtBaseX, wtBaseY = 0, 0
    local function EndTableDrag()
        if not wtDragging then return end
        wtDragging = false
        local point, _, relativePoint, x, y = windTable:GetPoint(1)
        AwakeningRaidToolsDB.FacingCompass = AwakeningRaidToolsDB.FacingCompass or {}
        AwakeningRaidToolsDB.FacingCompass.windTablePos = { point = point, relativePoint = relativePoint, x = x, y = y }
    end
    dragLayer:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" or button == "RightButton" then
            wtDragging = true
            wtStartX, wtStartY = GetCursorPosition()
            local _, _, _, x, y = windTable:GetPoint(1)
            wtBaseX, wtBaseY = x or 0, y or 0
        end
    end)
    dragLayer:SetScript("OnUpdate", function(self, elapsed)
        if not wtDragging then return end
        local curX, curY = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        local dx = (curX - wtStartX) / scale
        local dy = (curY - wtStartY) / scale
        windTable:ClearAllPoints()
        windTable:SetPoint("CENTER", UIParent, "CENTER", wtBaseX + dx, wtBaseY + dy)
    end)
    dragLayer:SetScript("OnMouseUp", function(self, button)
        EndTableDrag()
    end)
    dragLayer:SetScript("OnDragStop", EndTableDrag)
    windTable:Hide()

    ApplyOptions()
    compassFrame:Hide()
    return compassFrame
end

-- ============================================================================
-- Public API
-- ============================================================================

function FacingCompass:Enable(strata)
    local f = CreateCompassFrame()
    if not self.isEnabled then
        self.isEnabled = true
        if SAVED_ROTATE_MINIMAP == nil then
            SAVED_ROTATE_MINIMAP = GetCVar("rotateMinimap") or "0"
        end
        EnsureEllesmereCompatibility()
        SetCVar("rotateMinimap", "1")
    end
    if strata then
        compassFrame:SetFrameStrata(strata)
    end
    -- Combat Enable must not leave preview click buttons visible; the caller
    -- (Sszorak preview or battle with sender on) enables clicks explicitly.
    self.clickEnabled = false
    if btnRow then btnRow:Hide() end
    -- Fresh start: no marker is called until a broadcast arrives.
    self:ClearCalls()
    if windTable then windTable:Show() end
    rotationElapsed = 0
    f:SetScript("OnUpdate", OnCompassUpdate)
    ApplyOptions()
    f:Show()
end

function FacingCompass:Disable()
    if not self.isEnabled then return end
    self.isEnabled = false
    self.clickEnabled = false
    if btnRow then btnRow:Hide() end
    if windTable then windTable:Hide() end
    if compassFrame then
        compassFrame:SetScript("OnUpdate", nil)
        compassFrame:Hide()
    end
    RestoreRotateSource()
end

function FacingCompass:IsActive()
    return self.isEnabled
end

function FacingCompass:SetClicksEnabled(enabled)
    self.clickEnabled = enabled and true or false
    if btnRow then
        btnRow:SetShown(self.clickEnabled)
    end
end

function FacingCompass:SetOnMarkerClicked(fn)
    self.onMarkerClicked = fn
end

-- Pulse the marker OPPOSITE the given called marker. `order` is the 1..3
-- position of this call; shown in the fixed centre label.
function FacingCompass:ShowCalls(calls)
    if not compassFrame then return end
    -- Clear existing pulses only (do NOT touch the wind table).
    for slot = 1, 8 do
        local pulse = pulseLayers[slot]
        if pulse then pulse:Hide() end
    end
    if type(calls) ~= "table" or #calls == 0 then
        return
    end
    for _, entry in ipairs(calls) do
        local marker = entry and entry.marker
        if marker then
            local oppMarker = OppositeMarker(marker)
            local slot = SlotForMarker(oppMarker)
            local pulse = pulseLayers[slot]
            if pulse then
                pulse:SetAlpha(1)
                pulse:Show()
            end
        end
    end
    -- (Centre order label intentionally not shown: the wind table above the
    -- compass carries the 1-2-3 / target icons.)
end

function FacingCompass:SetOrderText(text)
    if not orderText then return end
    if text == nil or text == "" then
        orderText:Hide()
    else
        orderText:SetText(tostring(text))
        orderText:Show()
    end
end

function FacingCompass:ClearCalls()
    if not compassFrame then return end
    for slot = 1, 8 do
        local pulse = pulseLayers[slot]
        if pulse then pulse:Hide() end
    end
    if orderText then orderText:Hide() end
    self:ClearWindTable()
end

-- Show the wind order table for a list of opposite markers (already the
-- OPPOSITE targets): row 1 = "1 2 3", row 2 = rt icons.
function FacingCompass:ShowWindTable(oppositeMarkers)
    if not windTable then return end
    -- Reset icons (the 1 2 3 numbers stay permanently).
    for slot = 1, 3 do
        local icon = windTableRow2[slot]
        if icon then icon:Hide() end
    end
    if type(oppositeMarkers) == "table" and #oppositeMarkers > 0 then
        for slot = 1, math.min(3, #oppositeMarkers) do
            local marker = oppositeMarkers[slot]
            local icon = windTableRow2[slot]
            if icon and marker then
                icon:SetTexture(MarkerTexture(marker))
                icon:Show()
            end
        end
    end
    windTable:Show()
end

function FacingCompass:ClearWindTable()
    if not windTable then return end
    -- Clear icons only; the 1 2 3 numbers stay, empty table stays visible.
    for slot = 1, 3 do
        local icon = windTableRow2[slot]
        if icon then icon:Hide() end
    end
end

addon:RegisterModule("Common.FacingCompass", FacingCompass)
