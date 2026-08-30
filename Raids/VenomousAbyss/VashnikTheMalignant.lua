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
    },
}

local function IsDirectionCrossEnabled()
    local db = AwakeningRaidToolsDB
    if db and db.encounters and db.encounters[Boss.encounterId] then
        return db.encounters[Boss.encounterId].directionCross ~= false
    end
    return true
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
    -- can flip rotateMinimap back, which would freeze the compass rotation and
    -- leave the crosshair static. Keep forcing it while the overlay is live.
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
    -- The compass only tracks facing while the minimap rotates.
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
    if SAVED_ROTATE_MINIMAP then
        SetCVar("rotateMinimap", SAVED_ROTATE_MINIMAP)
        SAVED_ROTATE_MINIMAP = nil
    end
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
    if IsDirectionCrossEnabled() then
        ShowOverlay("HIGH")
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
end

function Boss:OnPhaseChange(newPhase, prevPhase)
    -- TODO
end

addon:RegisterModule("Raids.VenomousAbyss.VashnikTheMalignant", Boss)
