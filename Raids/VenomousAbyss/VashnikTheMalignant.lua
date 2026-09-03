local _, addon = ...

-- Boss 4: Vashnik the Malignant
-- Within The Chamber of Virulence, Vashnik the Malignant distills Ula'tek's
-- venoms into ever more lethal forms. The creature lurks in its noxious chamber,
-- brewing foul toxins to empower its brood.

local Boss = {
    name = "VashnikTheMalignant",
    -- DungeonEncounterID (ENCOUNTER_START)
    encounterId = 3455,
    journalEncounterId = 2882, -- Encounter Journal ID (EJ_GetEncounterInfo)
    mythicOnly = true,
    features = {
        directionCross = {
            type = "toggle",
            default = true,
            labelKey = "OPTIONS_VASHNIK_DIRECTION_CROSS",
            descKey  = "OPTIONS_VASHNIK_DIRECTION_CROSS_DESC",
            subFeatures = {
                {
                    type = "button",
                    key = "preview",
                    labelKey = "OPTIONS_VASHNIK_PREVIEW",
                    onClick = function()
                        -- The crosshair preview renders at FULLSCREEN_DIALOG
                        -- strata (above the DIALOG settings panel), so the
                        -- panel can stay open. Never call SettingsPanel:Close()
                        -- from addon code: it walks the ESC path and trips the
                        -- protected SpellStopCasting() (ADDON_ACTION_FORBIDDEN).
                        local addon = _G.AwakeningRaidTools
                        local boss = addon and addon.modules["Raids.VenomousAbyss.VashnikTheMalignant"]
                        if boss then
                            boss:TogglePreview()
                        end
                    end,
                },
            },
        },
        particleDensity = {
            type = "toggle",
            default = false,
            labelKey = "OPTIONS_VASHNIK_PARTICLE_DENSITY",
            descKey  = "OPTIONS_VASHNIK_PARTICLE_DENSITY_DESC",
        },
    },
}

local function IsBossFeatureEnabled(key)
    local db = AwakeningRaidToolsDB
    if db and db.encounters and db.encounters[Boss.encounterId] then
        return db.encounters[Boss.encounterId][key] ~= false
    end
    return true
end

-- ============================================================================
-- Particle density: disable combat particle effects for the whole fight (no
-- phase distinction), restored at encounter end. Same as MarchOfQuelDanas /
-- MidnightFalls but without the phase-based restore.
-- ============================================================================

local savedCVars = {}

local function SaveParticleCVars()
    wipe(savedCVars)
    local particle = C_CVar.GetCVar("graphicsParticleDensity")
    if particle ~= nil then savedCVars.particle = particle end
    local raidParticle = C_CVar.GetCVar("RaidGraphicsParticleDensity")
    if raidParticle ~= nil then savedCVars.raidParticle = raidParticle end
    addon:Dbg("Vashnik", ("CVar save: particle=%s raid=%s"):format(
        tostring(savedCVars.particle), tostring(savedCVars.raidParticle)))
end

local function DisableParticleCVars()
    addon:Dbg("Vashnik", "CVar disable: particle=0 raid=0")
    C_CVar.SetCVar("graphicsParticleDensity", "0")
    C_CVar.SetCVar("RaidGraphicsParticleDensity", "0")
end

local function RestoreParticleCVars()
    addon:Dbg("Vashnik", ("CVar restore: saved=(%s,%s)"):format(
        tostring(savedCVars.particle), tostring(savedCVars.raidParticle)))
    if savedCVars.particle then
        C_CVar.SetCVar("graphicsParticleDensity", savedCVars.particle)
    end
    if savedCVars.raidParticle then
        C_CVar.SetCVar("RaidGraphicsParticleDensity", savedCVars.raidParticle)
    end
end

-- ============================================================================
-- Direction crosshair: a screen-centered X that rotates with the player's
-- facing, to help line up during Plague Wave / fountain mechanics.
-- Ported from DreamForgeTools' DirectionCross module (encounter 3455).
-- ============================================================================

local BAR_THICKNESS = 2
local BAR_OPACITY = 0.7
local BAR_R, BAR_G, BAR_B = 1, 0.86, 0.08
local SAVED_ROTATE_MINIMAP

-- EllesmereUI (and similar minimap-overriding UIs) drive minimap rotation
-- from their own profile ( _EMM_DB.profile.minimap.rotateMinimap ) and may
-- hide/fade the stock MinimapCompassTexture. When Ellesmere is present we
-- must force its rotate flag AND keep the compass visible, or
-- MinimapCompassTexture:GetRotation() never changes and the crosshair stays
-- fixed on screen. Ported from DreamForgeTools' DirectionCross.
local ELLESMERE_COMPASS_ALPHA = 0.001
local ellesmereSettings
local ellesmereRotateCaptured = false
local ellesmereRotateWasNil = false
local ellesmereRotateValue
local ellesmereRegionState = {}

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
        if state.shown then
            region:Show()
        else
            region:Hide()
        end
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

-- Warn once when the compass can't rotate in the current UI setup. ElvUI's
-- square minimap hides MinimapCompassTexture entirely (its rotation is not
-- driven even with rotateMinimap=1), so the crosshair would stay frozen.
-- Detect that and tell the player to switch to round + enable rotation.
local warnedNoCompass = false

local function CheckCompassUsability()
    if warnedNoCompass then return end
    -- Already handled: Ellesmere compatibility forces its own profile.
    local compass = rawget(_G, "MinimapCompassTexture")
    if not compass then
        warnedNoCompass = true
        return
    end
    -- Native / Ellesmere: compass exists and (after EnsureEllesmereCompat)
    -- is live. ElvUI square minimap hides the compass: detect via ElvDB.
    local elvDB = rawget(_G, "ElvDB")
    local minimapDB = type(elvDB) == "table" and elvDB.profile and elvDB.profile.minimap
    if type(minimapDB) == "table" and minimapDB.circle == false then
        warnedNoCompass = true
        print("ART: 方向瞄准线需要圆形小地图 + 开启旋转（ElvUI 小地图设置 → 圆形 → 旋转）。方形小地图无法提供朝向。")
        return
    end
end


local overlay, barA, barB

local function CreateBar(parent, horizontal)
    local bar = parent:CreateTexture(nil, "OVERLAY")
    bar:SetTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetBlendMode("ADD")
    bar:SetVertexColor(BAR_R, BAR_G, BAR_B, BAR_OPACITY)
    local width = UIParent:GetWidth() or 1024
    local height = UIParent:GetHeight() or 768
    local length = math.sqrt(width * width + height * height) * 1.5
    if horizontal then
        bar:SetWidth(length)
        bar:SetHeight(BAR_THICKNESS)
    else
        bar:SetWidth(BAR_THICKNESS)
        bar:SetHeight(length)
    end
    bar:SetPoint("CENTER", parent, "CENTER")
    return bar
end

local function UpdateFacing()
    if not overlay or not overlay:IsShown() then return end
    -- DFT calls ensureRotateSource() on every frame: other addons or settings
    -- can flip rotateMinimap back (or Ellesmere can reset its own profile),
    -- which would freeze the compass rotation and leave the crosshair static.
    -- Keep forcing the rotation source while the overlay is live.
    EnsureEllesmereCompatibility()
    if GetCVar("rotateMinimap") ~= "1" then
        SetCVar("rotateMinimap", "1")
    end
    local compass = _G.MinimapCompassTexture
    local rotation = compass and compass:GetRotation()
    if rotation then
        -- rotation can be a secret number during RWF: pass it straight to the
        -- C API (SetRotation accepts secrets) and NEVER do Lua arithmetic on
        -- it. The two bars start perpendicular (one horizontal, one vertical),
        -- so applying the same rotation to both forms an X with no offset math.
        barA:SetRotation(rotation)
        barB:SetRotation(rotation)
    end
end

local function CreateOverlay()
    if overlay then return end
    overlay = CreateFrame("Frame", nil, UIParent)
    -- Strata is set per-show: HIGH in combat, FULLSCREEN_DIALOG while
    -- previewing so the crosshair renders above the settings panel.
    overlay:SetFrameLevel(900)
    overlay:SetAllPoints(UIParent)
    barA = CreateBar(overlay, true)   -- horizontal bar
    barB = CreateBar(overlay, false)  -- vertical bar
    overlay:SetScript("OnUpdate", UpdateFacing)
    overlay:Hide()
end

local function ShowOverlay(strata)
    CreateOverlay()
    if SAVED_ROTATE_MINIMAP == nil then
        SAVED_ROTATE_MINIMAP = GetCVar("rotateMinimap") or "0"
    end
    -- The compass only tracks facing while the minimap rotates. With
    -- EllesmereUI the rotation flag lives in its own profile and the stock
    -- compass may be hidden, so also force those here (kept live every frame
    -- in UpdateFacing too).
    EnsureEllesmereCompatibility()
    CheckCompassUsability()
    SetCVar("rotateMinimap", "1")
    if strata then
        overlay:SetFrameStrata(strata)
    end
    overlay:Show()
    UpdateFacing()
end

local function HideOverlay()
    if overlay then
        overlay:Hide()
    end
    RestoreRotateSource()
end

-- ============================================================================

-- Options "preview" button: show the crosshair outside any encounter (same
-- effect as the removed always-show debug mode). Toggling again hides it.
function Boss:TogglePreview()
    self._previewing = not self._previewing
    addon:Dbg(self.name, ("preview -> %s"):format(tostring(self._previewing)))
    if self._previewing then
        ShowOverlay("FULLSCREEN_DIALOG")
    else
        HideOverlay()
    end
    return self._previewing
end

function Boss:OnMythicEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    self.isActive = true
    addon:Dbg(self.name, "start")
    if IsBossFeatureEnabled("directionCross") then
        ShowOverlay("HIGH")
    end
    if IsBossFeatureEnabled("particleDensity") then
        SaveParticleCVars()
        DisableParticleCVars()
    end
    -- Phase tracking: uncomment and fill in transitions once timings are known.
    -- local pt = addon.modules["Common.PhaseTracker"]
    -- if pt then
    --     pt:RegisterPhaseConfig(self.encounterId, { transitions = {
    --         { atDuration = 45.0, phase = 2 },
    --     }})
    --     pt:RegisterPhaseCallback(self.encounterId, function(_, newPhase, prevPhase)
    --         self:OnPhaseChange(newPhase, prevPhase)
    --     end)
    -- end
end

function Boss:OnMythicEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    self.isActive = false
    addon:Dbg(self.name, "end")
    self._previewing = false
    HideOverlay()
    RestoreParticleCVars()
end

function Boss:OnPhaseChange(newPhase, prevPhase)
    -- TODO
end

addon:RegisterModule("Raids.VenomousAbyss.VashnikTheMalignant", Boss)
