-- Common/WindCall.lua
-- Wind-outlet call system (DFT WindOctagon style):
--   * RECEIVE strip: incoming wind-outlet calls (/raid wN) are shown as icons;
--     each entry is the OPPOSITE marker (the soak position);
--   * SEND panel: secure buttons that fire /raid wN for the raid leader.
-- Both keep working while chat text is secret in Mythic: the message is only
-- ever handed to a C API (FontString:SetFormattedText), never read in Lua.
--
-- The old screen-centre compass DISC was removed: it depended on the
-- minimap-rotation API (MinimapCompassTexture:GetRotation / rotateMinimap),
-- which Blizzard no longer permits. The saved-variable key "FacingCompass" is
-- kept so existing strip/panel positions survive this rename.
--
-- Public API (used by Raids/.../Sszorak.lua):
--   SetReceiveEnabled(bool) / IsReceiveEnabled()  -- the strip
--   SetSendEnabled(bool) / IsSendEnabled()        -- the button panel
--   Enable(strata?) / Disable() / IsActive()      -- both at once
--   AddWindCall(text) / ClearWindCalls() / ResetPositions()

local _, addon = ...

local LEM = LibStub and LibStub("LibEQOLEditMode-1.0")

local WindCall = {
    name = "WindCall",
    -- isEnabled mirrors (receiveEnabled or sendEnabled) for generic checks.
    isEnabled = false,
    receiveEnabled = false, -- show the incoming wind-call strip
    sendEnabled = false, -- show the leader send-button panel
}

-- Saved-variable key kept from the old FacingCompass module.
local DB_KEY = "FacingCompass"

-- Wind-call icons: w<N>.tga = outlet marker, w<N>_o.tga = the OPPOSITE marker
-- (soak position). The chat message ("wN") is fed straight into a texture path
-- via SetFormattedText — no parsing, so it works while the message is secret.
-- Art is the DFT WindOctagon raid-icon set, copied (not renamed in place) into
-- a fresh folder with the mapping baked in: w1 star->triangle, w2 circle->moon,
-- w3 diamond->square and vice versa.
local WIND_TEX = "Interface\\AddOns\\" .. (addon.name or "AwakeningRaidTools")
    .. "\\media\\WindCallTga\\"

-- Call strip: slot count/width. recentCalls holds the raw message values of
-- the latest calls (newest last, at most WIND_SLOTS). Storing secret values in
-- a table is allowed — we never compare or read them, only hand each to the C
-- formatter again — which is what makes the strip scroll instead of resetting.
local WIND_SLOTS = 3
local WIND_SLOT_W = 60
local recentCalls = {}

local windTable
local windTableRow1 = {} -- [slot] order number FontString
local windTableRow2 = {} -- [slot] call-icon FontString (renders the message)

-- Send panel (leader buttons).
local senderPanel
local senderSecure -- secure button host (parented to UIParent)
local senderButtons = {} -- [idx] SecureActionButtonTemplate
local senderDeferFrame -- defers panel creation when /reload lands in combat
local SENDER_COUNT = 6
local SENDER_BTN_W = 40

-- Raid-target icons for the send buttons (rt1..rt6).
local MARKER_TEX = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"

-- Forward declaration: the Edit Mode registrar is defined later (OnInitialize)
-- but the deferred-creation callback below must be able to call it.
local RegisterEditModeMovable

local function cfg(key)
    local db = AwakeningRaidToolsDB
    return db and db[DB_KEY] and db[DB_KEY][key]
end

local function SavePos(key)
    return function(frame)
        local point, _, relativePoint, x, y = frame:GetPoint(1)
        AwakeningRaidToolsDB[DB_KEY] = AwakeningRaidToolsDB[DB_KEY] or {}
        AwakeningRaidToolsDB[DB_KEY][key] = {
            point = point or "CENTER",
            relativePoint = relativePoint or "CENTER",
            x = x or 0,
            y = y or 0,
        }
    end
end

-- ============================================================================
-- Receive strip
-- ============================================================================

local function CreateWindTable()
    if windTable then return windTable end
    windTable = _G.CreateFrame("Frame", "ART_WindCallStrip", UIParent, "BackdropTemplate")
    windTable:SetFrameStrata("DIALOG")
    windTable:SetFrameLevel(190)
    windTable:SetSize(WIND_SLOTS * WIND_SLOT_W, 80)
    local wtPos = cfg("windTablePos")
    if type(wtPos) == "table" and wtPos.x then
        windTable:SetPoint(wtPos.point or "CENTER", UIParent,
            wtPos.relativePoint or "CENTER", wtPos.x, wtPos.y)
    else
        windTable:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    windTable:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    windTable:SetBackdropColor(0.02, 0.04, 0.08, 0.65)
    windTable:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.6)

    -- One slot per call: order number on top, the call icon below. The icon is
    -- a FontString rendered via SetFormattedText so the (possibly SECRET) chat
    -- message text is handled by the C API, never read in Lua.
    for slot = 1, WIND_SLOTS do
        local num = windTable:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        num:SetPoint("TOP", windTable, "TOPLEFT", (slot - 0.5) * WIND_SLOT_W, -6)
        num:SetText(tostring(slot))
        num:SetTextColor(0.85, 0.9, 1, 1)
        windTableRow1[slot] = num

        local icon = windTable:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        icon:SetPoint("BOTTOM", windTable, "BOTTOMLEFT", (slot - 0.5) * WIND_SLOT_W, 6)
        icon:Hide()
        windTableRow2[slot] = icon
    end
    windTable:Hide()
    return windTable
end

-- ============================================================================
-- Send panel (secure macro buttons)
-- A plain Button + SendChatMessage is BLOCKED (SendChatMessage is protected);
-- a SecureActionButtonTemplate "macro" is the only allowed path. RAID/PARTY
-- need no hardware event; SAY outdoors does, so solo testing may silently fail.
-- ============================================================================

-- Always /raid: the send panel is for the raid leader.
local function MacroBody(i)
    return "/raid w" .. i
end

local function CreateSenderPanel()
    if senderPanel then return senderPanel end
    if InCombatLockdown() then
        -- Secure attributes cannot be set in combat; defer creation.
        if not senderDeferFrame then
            senderDeferFrame = CreateFrame("Frame")
            senderDeferFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            senderDeferFrame:SetScript("OnEvent", function(self)
                self:UnregisterAllEvents()
                senderDeferFrame = nil
                CreateSenderPanel()
                if senderPanel then
                    -- Register for Edit Mode now that creation succeeded.
                    if RegisterEditModeMovable then
                        senderPanel.editModeName = "Awakening Raid Tools: Wind call buttons"
                        RegisterEditModeMovable(senderPanel, "senderPos", 0, -120)
                    end
                    if WindCall.isEnabled then senderPanel:Show() end
                end
            end)
        end
        return nil
    end
    senderPanel = CreateFrame("Frame", "ART_WindCallPanel", UIParent)
    senderPanel:SetFrameStrata("MEDIUM")
    senderPanel:SetSize(SENDER_COUNT * SENDER_BTN_W, 44)
    local pos = cfg("senderPos")
    if type(pos) == "table" and pos.x then
        senderPanel:SetPoint(pos.point or "CENTER", UIParent,
            pos.relativePoint or "CENTER", pos.x, pos.y)
    else
        senderPanel:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    end
    -- Secure host: parented to UIParent (not the panel) so the buttons live in
    -- a clean secure environment; anchored to the panel so it follows Edit Mode.
    senderSecure = CreateFrame("Frame", "ART_WindCallSecure", UIParent)
    senderSecure:SetSize(SENDER_COUNT * SENDER_BTN_W, 44)
    senderSecure:SetPoint("CENTER", senderPanel, "CENTER", 0, 0)
    senderSecure:SetFrameLevel(senderPanel:GetFrameLevel() + 5)

    for i = 1, SENDER_COUNT do
        local btn = CreateFrame("Button", "ART_WindCallBtn" .. i, senderSecure,
            "SecureActionButtonTemplate")
        btn:SetSize(SENDER_BTN_W - 4, SENDER_BTN_W - 4)
        btn:SetPoint("LEFT", senderSecure, "LEFT", (i - 1) * SENDER_BTN_W + 2, 0)
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", MacroBody(i))
        btn:RegisterForClicks("AnyUp", "AnyDown")
        -- NOTE: do NOT SetScript("OnClick", ...) here — SecureActionButtonTemplate
        -- runs its action through the template's OnClick handler, so overriding
        -- it silently disables the macro. Use OnMouseDown for diagnostics.
        btn:SetScript("OnMouseDown", function()
            addon:Dbg("WindCall", ("clicked w%d -> macro '%s'"):format(i, MacroBody(i)))
        end)
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(btn)
        icon:SetTexture(MARKER_TEX .. i)
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(btn)
        hl:SetColorTexture(0.4, 1, 0.7, 0.30)
        senderButtons[i] = btn
    end
    senderPanel:Hide()

    return senderPanel
end

-- ============================================================================
-- Public API
-- ============================================================================

-- Redraw every slot from recentCalls (slot 1 = oldest of the retained calls,
-- last slot = newest). Empty slots are hidden.
local function RenderCalls()
    for slot = 1, WIND_SLOTS do
        local icon = windTableRow2[slot]
        if icon then
            local text = recentCalls[slot]
            if text ~= nil then
                -- Aligned with DFT WindOctagon: no file extension in the |T
                -- path (the client resolves .tga/.blp) and the whole call is
                -- pcall-wrapped like DFT does.
                local ok = pcall(function()
                    icon:SetFormattedText("|T" .. WIND_TEX .. "%s_o.tga:40:40|t", text)
                end)
                addon:Dbg("WindCall", ("slot %d render ok=%s"):format(slot, tostring(ok)))
                icon:Show()
            else
                icon:Hide()
            end
        end
    end
end

-- Append one call to the strip and scroll: keep only the latest WIND_SLOTS
-- calls, so w1 w2 w3 w4 shows w2 w3 w4. `text` is the raw chat message (e.g.
-- "w6"), which is a SECRET value in Mythic — we store it but never read it.
function WindCall:AddWindCall(text)
    if not windTable then return end
    addon:Dbg("WindCall", ("AddWindCall: type=%s secret=%s shown=%s"):format(
        type(text),
        tostring(issecretvalue and issecretvalue(text)),
        tostring(windTable:IsShown())))
    -- Strip texture/colour escapes so a raid member cannot inject |T/|c
    -- markup. Only possible when the message is NOT secret.
    if type(text) == "string" and not (issecretvalue and issecretvalue(text)) then
        text = text:gsub("%|", "")
    end
    recentCalls[#recentCalls + 1] = text
    while #recentCalls > WIND_SLOTS do
        table.remove(recentCalls, 1) -- drop the oldest
    end
    RenderCalls()
    if self.receiveEnabled then
        windTable:Show()
    end
end

-- Clear the strip (numbers stay; icons hidden). Does not change visibility.
function WindCall:ClearWindCalls()
    wipe(recentCalls)
    RenderCalls()
end

-- Visibility follows the two independent toggles.
local function ApplyVisibility()
    if windTable then windTable:SetShown(WindCall.receiveEnabled == true) end
    if senderPanel then senderPanel:SetShown(WindCall.sendEnabled == true) end
    if senderSecure then senderSecure:SetShown(WindCall.sendEnabled == true) end
end

function WindCall:SetReceiveEnabled(on)
    self.receiveEnabled = on and true or false
    self.isEnabled = (self.receiveEnabled or self.sendEnabled) and true or false
    CreateWindTable()
    if self.receiveEnabled then
        self:ClearWindCalls()
    end
    ApplyVisibility()
end

function WindCall:IsReceiveEnabled()
    return self.receiveEnabled == true
end

function WindCall:SetSendEnabled(on)
    self.sendEnabled = on and true or false
    self.isEnabled = (self.receiveEnabled or self.sendEnabled) and true or false
    CreateSenderPanel()
    ApplyVisibility()
end

function WindCall:IsSendEnabled()
    return self.sendEnabled == true
end

-- Convenience: enable/disable both at once.
function WindCall:Enable(strata)
    CreateWindTable()
    CreateSenderPanel()
    if strata then
        if windTable then windTable:SetFrameStrata(strata) end
        if senderPanel and not InCombatLockdown() then
            senderPanel:SetFrameStrata(strata)
        end
    end
    self:SetReceiveEnabled(true)
    self:SetSendEnabled(true)
end

function WindCall:Disable()
    self:SetReceiveEnabled(false)
    self:SetSendEnabled(false)
end

function WindCall:IsActive()
    return self.receiveEnabled == true or self.sendEnabled == true
end

-- Reset both frames to the screen centre, clearing saved offsets.
function WindCall:ResetPositions()
    local db = AwakeningRaidToolsDB
    if db and db[DB_KEY] then
        db[DB_KEY].windTablePos = nil
        db[DB_KEY].senderPos = nil
    end
    if windTable then
        windTable:ClearAllPoints()
        windTable:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    if senderPanel then
        senderPanel:ClearAllPoints()
        senderPanel:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    end
    print("ART: wind-call strip/panel reset to UIParent centre")
end

-- ============================================================================
-- Edit Mode (LibEQOLEditMode)
-- ============================================================================

local wasShownForEditMode = false

local function ShowForEditMode()
    CreateWindTable()
    CreateSenderPanel()
    wasShownForEditMode = true
    -- Force both movable frames visible so they can be repositioned.
    if windTable then windTable:Show() end
    if senderPanel then senderPanel:Show() end
    if senderSecure then senderSecure:Show() end
end

local function RestoreAfterEditMode()
    if not wasShownForEditMode then return end
    wasShownForEditMode = false
    ApplyVisibility()
end

local function RegisterMovable(frame, key, defaultX, defaultY)
    -- defaultX/defaultY are the FACTORY default (Edit Mode "Reset to default").
    LEM:AddFrame(frame, SavePos(key), {
        baseFrameName = frame.editModeName,
        name = frame.editModeName,
        point = "CENTER",
        relativePoint = "CENTER",
        x = defaultX or 0,
        y = defaultY or 0,
        enableOverlayToggle = false,
        showReset = true,
    })
    -- LEM doesn't set system.name; Blizzard EditMode needs it.
    for _, child in ipairs({ frame:GetChildren() }) do
        if child.system then
            child.system.name = frame.editModeName
            break
        end
    end
end

-- Expose the registrar to the deferred-creation callback (forward-declared).
RegisterEditModeMovable = RegisterMovable

function WindCall:OnInitialize()
    -- Pre-create + register both frames so they exist BEFORE Edit Mode opens.
    CreateWindTable()
    CreateSenderPanel()
    if not LEM then return end
    LEM:RegisterCallback("enter", ShowForEditMode)
    LEM:RegisterCallback("exit", RestoreAfterEditMode)
    if windTable then
        windTable.editModeName = "Awakening Raid Tools: Wind call strip"
        RegisterMovable(windTable, "windTablePos", 0, 0)
    end
    if senderPanel then
        senderPanel.editModeName = "Awakening Raid Tools: Wind call buttons"
        RegisterMovable(senderPanel, "senderPos", 0, -120)
    end
end

addon:RegisterModule("Common.WindCall", WindCall)
