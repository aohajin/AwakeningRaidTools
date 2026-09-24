local addonName, addon = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == addonName then
        AwakeningRaidToolsDB = AwakeningRaidToolsDB or {}
        if type(addon.InitializeModules) == "function" then
            addon:InitializeModules()
        end
    end
end)

SLASH_ART1 = "/art"
SlashCmdList["ART"] = function()
    if addon.optionsCategory then
        Settings.OpenToCategory(addon.optionsCategory:GetID())
    end
end

-- Virulence voice diagnostic: prints all conditions that could stop the
-- Sszorak direction voice from playing. Ask affected users to run this.
SLASH_ARTVOICE1 = "/artvoice"
SlashCmdList["ARTVOICE"] = function()
    local boss = addon.modules["Raids.VenomousAbyss.Sszorak"]
    if boss and boss.DiagnoseVoice then
        boss:DiagnoseVoice()
    else
        print("ART: Sszorak module not loaded")
    end
end

SLASH_PARTICLE1 = "/particle"
SlashCmdList["PARTICLE"] = function()
    print("ART: graphicsParticleDensity = " .. tostring(C_CVar.GetCVar("graphicsParticleDensity")))
    print("ART: RaidGraphicsParticleDensity = " .. tostring(C_CVar.GetCVar("RaidGraphicsParticleDensity")))
end

SLASH_FICLOG1 = "/ficlog"
SlashCmdList["FICLOG"] = function()
    local log = AwakeningRaidToolsDB and AwakeningRaidToolsDB.DebugLog
    if not log or #log == 0 then
        print("ART: Debug log is empty. Enable debug logging in options first.")
        return
    end

    -- Reuse or create once
    local f = _G.ARTDebugLogFrame
    if not f then
        f = CreateFrame("Frame", "ARTDebugLogFrame", UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(700, 500)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetScript("OnHide", function() end)

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        f.title:SetPoint("TOP", 0, -15)

        local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 12, -35)
        sf:SetPoint("BOTTOMRIGHT", -30, 40)
        f.scrollFrame = sf

        f.edit = CreateFrame("EditBox", nil, sf)
        f.edit:SetMultiLine(true)
        f.edit:SetMaxLetters(0)
        f.edit:SetFontObject("ChatFontNormal")
        f.edit:SetWidth(sf:GetWidth() - 20)
        f.edit:SetCursorPosition(0)
        f.edit:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(f.edit)

        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetPoint("BOTTOM", 0, 15)
        close:SetText("Close")
        close:SetSize(80, 24)
        close:SetScript("OnClick", function() f:Hide() end)
    end

    f.title:SetText("ART Debug Log (" .. #log .. " entries)")
    f.edit:SetText(table.concat(log, "\n", math.max(1, #log - 499), #log))
    f:Show()
end

-- PhaseTracker debug commands
SLASH_ARTPT1 = "/artpt"
SlashCmdList["ARTPT"] = function()
    local pt = addon.modules and addon.modules["Common.PhaseTracker"]
    if pt and pt.PrintState then
        pt:PrintState()
    else
        print("ART: PhaseTracker not loaded")
    end
end

SLASH_ARTPTDEBUG1 = "/artptdebug"
SlashCmdList["ARTPTDEBUG"] = function()
    local pt = addon.modules and addon.modules["Common.PhaseTracker"]
    if pt then
        pt.debugEnabled = not pt.debugEnabled
        print("ART: PhaseTracker debug = " .. tostring(pt.debugEnabled))
    else
        print("ART: PhaseTracker not loaded")
    end
end

SLASH_ARTPTTEST1 = "/artpttest"
SlashCmdList["ARTPTTEST"] = function(msg)
    local stage = tonumber(msg)
    if not stage then
        print("ART: Usage: /artpttest <stage>  (e.g. /artpttest 2)")
        return
    end
    local pt = addon.modules and addon.modules["Common.PhaseTracker"]
    if pt and pt.SimulateStage then
        pt:SimulateStage(stage)
    else
        print("ART: PhaseTracker not loaded")
    end
end

-- ============================================================================
-- /artsim — one-shot simulation of restricted-environment states.
-- Uses Blizzard's session-only "*Forced" cvars so secret/restriction branches
-- can be exercised in town without entering a dungeon. Restart clears them.
-- ============================================================================

local ARTSIM_CVARS = {
    "addonChatRestrictionsForced",
    "addonMapRestrictionsForced",
    "addonEncounterRestrictionsForced",
    "addonCombatRestrictionsForced",
    "addonChallengeModeRestrictionsForced",
    "addonPvPMatchRestrictionsForced",
}

-- Restriction enum order (Enum.AddOnRestrictionType): Combat, Encounter,
-- ChallengeMode, PvPMatch, Map, Chat.
local ARTSIM_PRESETS = {
    mythic = {
        "addonEncounterRestrictionsForced",
        "addonMapRestrictionsForced",
        "addonChatRestrictionsForced",
    },
    ["m+"] = {
        "addonChallengeModeRestrictionsForced",
        "addonMapRestrictionsForced",
        "addonChatRestrictionsForced",
    },
    ["pvp"] = {
        "addonPvPMatchRestrictionsForced",
        "addonMapRestrictionsForced",
        "addonChatRestrictionsForced",
    },
}

local function ArtSimApply(names)
    for _, c in ipairs(ARTSIM_CVARS) do
        SetCVar(c, "0")
    end
    if names then
        for _, c in ipairs(names) do
            SetCVar(c, "1")
        end
    end
end

local function ArtSimReport()
    if not (C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive) then
        print("ART sim: C_RestrictedActions unavailable on this client")
        return
    end
    local labels = { "Combat", "Encounter", "ChallengeMode", "PvPMatch", "Map", "Chat" }
    local parts = {}
    for i, label in ipairs(labels) do
        local ok, active = pcall(C_RestrictedActions.IsAddOnRestrictionActive, i - 1)
        parts[#parts + 1] = ("%s=%s"):format(label, ok and tostring(active == true) or "?")
    end
    print("ART sim: " .. table.concat(parts, "  "))
end

SLASH_ARTSIM1 = "/artsim"
SlashCmdList["ARTSIM"] = function(msg)
    local key = (msg or ""):lower():gsub("%s+", "")
    if key == "" or key == "status" then
        print("ART: /artsim mythic | m+ | pvp | off")
    elseif key == "off" or key == "0" then
        ArtSimApply(nil)
        print("ART sim: off (all forced cvars cleared)")
    elseif ARTSIM_PRESETS[key] then
        ArtSimApply(ARTSIM_PRESETS[key])
        print(("ART sim: %s restrictions forced ON"):format(key))
    else
        print(("ART: unknown preset '%s' — use mythic | m+ | pvp | off"):format(key))
    end
    ArtSimReport()
    print("ART sim: if nothing changed, /reload (cvars are session-only, cleared on restart)")
end
