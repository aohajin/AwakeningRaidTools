local _, addon = ...

-- ============================================================================
-- Options panel built on the native 12.x Settings framework
-- (RegisterVerticalLayoutCategory + RegisterProxySetting +
-- CreateControlInitializer), matching the look of WilduTools / Blizzard
-- settings pages.
--
-- Registered as a module whose OnInitialize runs after ADDON_LOADED.
--
-- Structure:
--   Root category "覺 醒 Raid Tools"  (block headers: GENERAL / Voice pack /
--     each current+test raid)
--   `-- Subcategory "Legacy Raids"    (separate tree entry, like WilduTools'
--       Map / Cast Bar). Three per-raid toggles (single source of truth) plus
--       a Reload UI button that appears only after a toggle change. The
--       legacy addon is NOT loaded by default; enabling any raid loads it
--       (boss features render after the next /reload).
-- ============================================================================

local RAID_ORDER_CURRENT = { "VenomousAbyss" }
local RAID_ORDER_TEST = { "Aberrus" }
local RAID_ORDER_LEGACY = { "Voidspire", "Dreamrift", "MarchOfQuelDanas" }

-- ============================================================================
-- DB helpers (unchanged semantics from the old panel)
-- ============================================================================

local function GetFeatureEnabled(encounterId, featureName, default)
    local db = AwakeningRaidToolsDB
    if db and db.encounters and db.encounters[encounterId] then
        local val = db.encounters[encounterId][featureName]
        if val ~= nil then return val end
    end
    return default ~= false
end

local function SetFeatureEnabled(encounterId, featureName, value)
    local db = AwakeningRaidToolsDB
    if not db.encounters then db.encounters = {} end
    if not db.encounters[encounterId] then db.encounters[encounterId] = {} end
    db.encounters[encounterId][featureName] = value and true or false
end

local function GetSubFeatureEnabled(encounterId, parentKey, subKey, default)
    local db = AwakeningRaidToolsDB
    if db and db.encounters and db.encounters[encounterId] then
        local val = db.encounters[encounterId][parentKey .. "_" .. subKey]
        if val ~= nil then return val end
    end
    return default ~= false
end

local function SetSubFeatureEnabled(encounterId, parentKey, subKey, value)
    local db = AwakeningRaidToolsDB
    if not db.encounters then db.encounters = {} end
    if not db.encounters[encounterId] then db.encounters[encounterId] = {} end
    db.encounters[encounterId][parentKey .. "_" .. subKey] = value and true or false
end

local function GetLegacyRaidEnabled(raidKey)
    local db = AwakeningRaidToolsDB
    return db and db.LegacyRaidEnabled and db.LegacyRaidEnabled[raidKey] == true
end

local function SetLegacyRaidEnabled(raidKey, value)
    AwakeningRaidToolsDB.LegacyRaidEnabled = AwakeningRaidToolsDB.LegacyRaidEnabled or {}
    AwakeningRaidToolsDB.LegacyRaidEnabled[raidKey] = value and true or nil
end

local function GetRaidName(raidKey)
    local raidModule = addon.modules["Raids." .. raidKey]
    if raidModule and raidModule.instanceId then
        local info = EJ_GetInstanceInfo(raidModule.instanceId)
        if info then return info end
    end
    local L = addon.L or {}
    local keys = {
        VenomousAbyss = "RAID_VENOMOUS_ABYSS",
        Voidspire = "RAID_VOIDSPIRE",
        Dreamrift = "RAID_DREAMRIFT",
        MarchOfQuelDanas = "RAID_MARCH_OF_QUELDANAS",
        Aberrus = "RAID_ABERRUS",
    }
    local key = keys[raidKey]
    return (key and L[key]) or raidKey
end

local function GetBossName(module)
    local journalId = module.journalEncounterId or module.encounterId
    if journalId then
        local name = EJ_GetEncounterInfo(journalId)
        if name then return name end
    end
    return module.name or "Unknown"
end

-- ============================================================================
-- Feature registry: raidKey -> { bosses sorted by raid.bossOrder }
-- Reads only modules already registered (current raids at load time; legacy
-- raids appear once the legacy addon loads).
-- ============================================================================

local function CollectRaidModules()
    local raids = {}
    for moduleName, module in pairs(addon.modules) do
        if module.features and next(module.features) and module.encounterId then
            local parts = {}
            for segment in moduleName:gmatch("[^.]+") do
                parts[#parts + 1] = segment
            end
            if #parts >= 2 and parts[1] == "Raids" then
                local raidKey = parts[2]
                local entry = raids[raidKey]
                if not entry then
                    entry = { bosses = {} }
                    raids[raidKey] = entry
                end
                table.insert(entry.bosses, {
                    module = module,
                    name = GetBossName(module),
                    encounterId = module.encounterId,
                    features = module.features,
                })
            end
        end
    end
    for raidKey, entry in pairs(raids) do
        local raidModule = addon.modules and addon.modules["Raids." .. raidKey]
        local bossOrder = raidModule and raidModule.bossOrder
        if type(bossOrder) == "table" then
            local rank = {}
            for index, encounterId in ipairs(bossOrder) do
                rank[encounterId] = index
            end
            table.sort(entry.bosses, function(a, b)
                local ra, rb = rank[a.encounterId], rank[b.encounterId]
                if ra and rb then return ra < rb end
                if ra then return true end
                if rb then return false end
                return a.encounterId < b.encounterId
            end)
        else
            table.sort(entry.bosses, function(a, b)
                return a.encounterId < b.encounterId
            end)
        end
    end
    return raids
end

-- ============================================================================
-- Settings helpers
-- ============================================================================

local function AddHeader(layout, text)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
end

-- Register a boolean checkbox for a boss feature on the given layout/category,
-- plus any sub-features (indented toggles bound to the parent, or action
-- buttons shown while the parent is enabled).
local function AddFeatureCheckbox(category, layout, encounterId, featureName, featureDef)
    local L = addon.L or {}
    local label = L[featureDef.labelKey] or featureDef.labelKey or featureName
    local tooltip = featureDef.descKey and L[featureDef.descKey] or nil
    local default = featureDef.default ~= false

    local setting = Settings.RegisterProxySetting(
        category,
        ("ART_enc_%d_%s"):format(encounterId, featureName),
        Settings.VarType.Boolean,
        label,
        default,
        function() return GetFeatureEnabled(encounterId, featureName, default) end,
        function(value) SetFeatureEnabled(encounterId, featureName, value) end
    )
    local parentInit = Settings.CreateControlInitializer("ART_SettingsCheckRowTemplate", setting, nil, tooltip)
    layout:AddInitializer(parentInit)

    -- Sub-features (Vashnik preview button; MidnightFalls toggles + button).
    local subFeatures = featureDef.subFeatures
    if subFeatures then
        for _, subDef in ipairs(subFeatures) do
            local subKey = subDef.key
            local subLabel = L[subDef.labelKey] or subDef.labelKey or subKey
            local subTooltip = subDef.descKey and L[subDef.descKey] or nil

            if subDef.type == "button" then
                local btnInit = CreateSettingsButtonInitializer(
                    "", subLabel,
                    subDef.onClick or function() end,
                    subTooltip or "",
                    true -- addSearchTags (asserted non-nil by Blizzard)
                )
                -- Show the button only while the parent feature is enabled
                -- and any declared dependsOn sibling toggle is on.
                if btnInit and btnInit.SetParentInitializer then
                    local depKey = subDef.dependsOn
                    btnInit:SetParentInitializer(parentInit, function()
                        if not GetFeatureEnabled(encounterId, featureName, default) then
                            return false
                        end
                        if depKey then
                            return GetSubFeatureEnabled(encounterId, featureName, depKey, false)
                        end
                        return true
                    end)
                end
                layout:AddInitializer(btnInit)
            else -- toggle sub-feature
                local subSetting = Settings.RegisterProxySetting(
                    category,
                    ("ART_enc_%d_%s_%s"):format(encounterId, featureName, subKey),
                    Settings.VarType.Boolean,
                    subLabel,
                    subDef.default ~= false,
                    function() return GetSubFeatureEnabled(encounterId, featureName, subKey, subDef.default) end,
                    function(value) SetSubFeatureEnabled(encounterId, featureName, subKey, value) end
                )
                local subInit = Settings.CreateControlInitializer("ART_SettingsCheckRowTemplate", subSetting, nil, subTooltip)
                if subInit and subInit.SetParentInitializer then
                    -- Enabled while the parent feature is on; also honour a
                    -- declared dependsOn sibling (e.g. editMode needs
                    -- centerScreen) when present.
                    local depKey = subDef.dependsOn
                    subInit:SetParentInitializer(parentInit, function()
                        if not GetFeatureEnabled(encounterId, featureName, default) then
                            return false
                        end
                        if depKey then
                            return GetSubFeatureEnabled(encounterId, featureName, depKey, false)
                        end
                        return true
                    end)
                end
                layout:AddInitializer(subInit)
            end
        end
    end
    return parentInit
end

-- Render every boss feature of one raid into the given layout under one header.
-- Each boss gets a static label (ART_BossLabelTemplate) as a group header;
-- its feature toggles are children of that label, so they indent one more
-- level. The label has no setting, so children never hide (pure visual
-- hierarchy for current/test raids).
local function RenderRaid(category, layout, raidKey, raids)
    local raid = raids[raidKey]
    if not raid or #raid.bosses == 0 then return end
    AddHeader(layout, GetRaidName(raidKey))
    for _, boss in ipairs(raid.bosses) do
        local bossInit = Settings.CreateElementInitializer("ART_BossLabelTemplate", { name = boss.name })
        bossInit:Indent()
        layout:AddInitializer(bossInit)
        for featureName, featureDef in pairs(boss.features) do
            local featureInit = AddFeatureCheckbox(category, layout, boss.encounterId, featureName, featureDef)
            if featureInit and featureInit.SetParentInitializer then
                featureInit:SetParentInitializer(bossInit, function() return true end)
            end
        end
    end
end

-- ============================================================================
-- Module + build (OnInitialize runs after ADDON_LOADED).
-- ============================================================================

local OptionsPanel = {
    name = "OptionsPanel",
}

-- Ensure the LoadOnDemand legacy addon is loaded when any legacy raid is
-- enabled. Called at panel build (from OnInitialize) and when a legacy raid
-- toggle is checked at runtime. LoadAddOn is synchronous; afterwards the
-- legacy boss modules are in addon.modules and CollectRaidModules() can see
-- them.
local function EnsureLegacyLoaded()
    local loader = addon.modules["Core.LegacyLoader"]
    if loader and not addon.legacyLoaded and loader.LoadIfNeeded then
        loader:LoadIfNeeded()
    end
end

-- Legacy subcategory (separate tree entry like WilduTools' Map / Cast Bar).
-- Defined before OptionsPanel:OnInitialize so the closure can call it.
local function BuildLegacySubcategory(category, L)
    local legacyCategory, legacyLayout = Settings.RegisterVerticalLayoutSubcategory(category, L.OPTIONS_LEGACY_HEADER or "Legacy Raids")

    -- Dirty flag for the "Reload UI" button: any change to a legacy raid
    -- toggle sets it, revealing the reload button until the next /reload.
    -- Pure in-memory state (not persisted); the proxy getter reads the local.
    local legacyDirty = false
    local legacyDirtySetting = Settings.RegisterProxySetting(
        category,
        "ART_legacyNeedsReload",
        Settings.VarType.Boolean,
        "Needs reload",
        false,
        function() return legacyDirty end,
        function(value) legacyDirty = (value == true) end
    )

    -- Per-raid toggles (single source of truth). Checking one loads the
    -- legacy addon; any change sets the dirty flag so the Reload UI button
    -- below appears. Each raid's boss features are grouped under a boss
    -- label and all of them show/hide with the raid toggle (unlike
    -- current raids, here the raid checkbox is a real switch).
    local legacyRaids = CollectRaidModules()
    for _, raidKey in ipairs(RAID_ORDER_LEGACY) do
        local label = GetRaidName(raidKey)
        local setting = Settings.RegisterProxySetting(
            legacyCategory, "ART_legacy_" .. raidKey, Settings.VarType.Boolean, label, false,
            function() return GetLegacyRaidEnabled(raidKey) end,
            function(value)
                local changed = GetLegacyRaidEnabled(raidKey) ~= (value == true)
                SetLegacyRaidEnabled(raidKey, value)
                if changed then
                    legacyDirtySetting:SetValue(true)
                end
                if value then
                    EnsureLegacyLoaded()
                end
            end
        )
        local raidCheckboxInit = Settings.CreateControlInitializer("ART_SettingsCheckRowTemplate", setting)
        legacyLayout:AddInitializer(raidCheckboxInit)

        local raid = legacyRaids[raidKey]
        if raid and #raid.bosses > 0 and GetLegacyRaidEnabled(raidKey) then
            for _, boss in ipairs(raid.bosses) do
                local bossInit = Settings.CreateElementInitializer("ART_BossLabelTemplate", { name = boss.name })
                bossInit:Indent()
                if bossInit and bossInit.SetParentInitializer then
                    bossInit:SetParentInitializer(raidCheckboxInit, function()
                        return GetLegacyRaidEnabled(raidKey)
                    end)
                end
                legacyLayout:AddInitializer(bossInit)
                for featureName, featureDef in pairs(boss.features) do
                    local featureInit = AddFeatureCheckbox(legacyCategory, legacyLayout, boss.encounterId, featureName, featureDef)
                    if featureInit and featureInit.SetParentInitializer then
                        featureInit:SetParentInitializer(bossInit, function()
                            return GetLegacyRaidEnabled(raidKey)
                        end)
                    end
                end
            end
        end
    end

    -- Reload UI button (hidden unless a legacy toggle changed).
    local reloadData = {
        name = "",
        buttonText = L.OPTIONS_LEGACY_RELOAD_BUTTON or "Reload UI",
        buttonClick = function() ReloadUI() end,
        dirtySetting = legacyDirtySetting,
    }
    local reloadInit = Settings.CreateElementInitializer("ART_ReloadButtonTemplate", reloadData)
    legacyLayout:AddInitializer(reloadInit)
end

function OptionsPanel:OnInitialize()
    -- Load the legacy addon up-front when the saved DB enables any legacy
    -- raid (default: not loaded). Module OnInitialize order is not
    -- guaranteed, so do this here rather than relying on LegacyLoader.
    local db = AwakeningRaidToolsDB
    local anyLegacy = false
    if db and db.LegacyRaidEnabled then
        for _, raidKey in ipairs(RAID_ORDER_LEGACY) do
            if db.LegacyRaidEnabled[raidKey] then
                anyLegacy = true
                break
            end
        end
    end
    if anyLegacy then
        EnsureLegacyLoaded()
    end

    local category, layout = Settings.RegisterVerticalLayoutCategory("覺 醒 Raid Tools")
    Settings.RegisterAddOnCategory(category)
    addon.optionsCategory = category

    local L = addon.L or {}

    -- GENERAL
    AddHeader(layout, L.OPTIONS_GENERAL_HEADER or "GENERAL")

    do -- Spec gear mismatch
        local label = L.OPTIONS_SPEC_GEAR_MISMATCH or "Enable gear mismatch check"
        local setting = Settings.RegisterProxySetting(
            category, "ART_specGearMismatch", Settings.VarType.Boolean, label, false,
            function()
                return AwakeningRaidToolsDB and AwakeningRaidToolsDB.SpecGearMismatchEnabled == true
            end,
            function(value)
                AwakeningRaidToolsDB.SpecGearMismatchEnabled = value or nil
                local module = addon.modules["Common.SpecGearMismatchWarning"]
                if module then
                    if value then module:Enable() else module:Disable() end
                end
            end
        )
        layout:AddInitializer(Settings.CreateControlInitializer("ART_SettingsCheckRowTemplate", setting))
    end

    do -- Debug toggle
        local label = L.OPTIONS_DEBUG_ENABLE or "Enable debug logging"
        local tooltip = L.OPTIONS_DEBUG_ENABLE_DESC
        local setting = Settings.RegisterProxySetting(
            category, "ART_debug", Settings.VarType.Boolean, label, false,
            function()
                return AwakeningRaidToolsDB and AwakeningRaidToolsDB.DebugEnabled == true
            end,
            function(value)
                AwakeningRaidToolsDB.DebugEnabled = value or nil
            end
        )
        layout:AddInitializer(Settings.CreateControlInitializer("ART_SettingsCheckRowTemplate", setting, nil, tooltip))
    end

    -- Voice pack
    do
        AddHeader(layout, L.OPTIONS_VOICEPACK_GROUP or "Voice pack")

        local packs = addon.voicePacks or {}
        local defaultPack = addon.voicePackDefault or packs[1] or "Aloy"
        local voiceSetting = Settings.RegisterProxySetting(
            category, "ART_voicePack", Settings.VarType.String,
            L.OPTIONS_VOICEPACK or "Voice pack", defaultPack,
            function()
                local saved = AwakeningRaidToolsDB and AwakeningRaidToolsDB.VoicePack
                for _, name in ipairs(packs) do
                    if name == saved then return saved end
                end
                return defaultPack
            end,
            function(value)
                AwakeningRaidToolsDB.VoicePack = (value ~= "" and value) or nil
            end
        )
        local function buildVoiceOptions()
            local container = Settings.CreateControlTextContainer()
            for _, name in ipairs(packs) do
                container:Add(name, name)
            end
            return container:GetData()
        end
        -- Settings.CreateDropdown already adds the initializer to the layout.
        Settings.CreateDropdown(category, voiceSetting, buildVoiceOptions,
            L.OPTIONS_VOICEPACK_DESC)

        -- Sound preview dropdown (plays the picked sound on selection).
        local sounds = addon.voiceSounds or {}
        local function ResolvePack()
            local saved = AwakeningRaidToolsDB and AwakeningRaidToolsDB.VoicePack
            for _, name in ipairs(packs) do
                if name == saved then return saved end
            end
            return defaultPack
        end
        local previewSetting = Settings.RegisterProxySetting(
            category, "ART_voicePreview", Settings.VarType.String,
            L.OPTIONS_VOICEPACK_PREVIEW_SOUND or "Preview sound", "",
            function() return "" end,
            function(value)
                if value and value ~= "" then
                    local baseDir = "Interface\\AddOns\\" .. (addon.name or "AwakeningRaidTools") .. "\\media\\"
                    local path = baseDir .. "VoicePacks\\" .. ResolvePack() .. "\\" .. value .. ".ogg"
                    if PlaySoundFile then
                        PlaySoundFile(path, "Master")
                    end
                end
            end
        )
        local function buildPreviewOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add("", L.OPTIONS_VOICEPACK_PICK_SOUND or "Select a sound")
            for _, key in ipairs(sounds) do
                container:Add(key, key)
            end
            return container:GetData()
        end
        -- Settings.CreateDropdown already adds the initializer to the layout.
        Settings.CreateDropdown(category, previewSetting, buildPreviewOptions,
            L.OPTIONS_VOICEPACK_PREVIEW_HINT)
    end

    -- Current + test raids (block headers inside the root content).
    local raids = CollectRaidModules()
    for _, raidKey in ipairs(RAID_ORDER_CURRENT) do
        RenderRaid(category, layout, raidKey, raids)
    end
    for _, raidKey in ipairs(RAID_ORDER_TEST) do
        RenderRaid(category, layout, raidKey, raids)
    end

    -- Legacy subcategory (separate tree entry, like WilduTools' Map/Cast Bar).
    BuildLegacySubcategory(category, L)
end

-- Kept for compatibility; the Settings layout cannot be rebuilt at runtime.
addon.RebuildOptionsPanel = function() end

addon:RegisterModule("Options.Panel", OptionsPanel)

