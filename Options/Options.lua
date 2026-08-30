local _, addon = ...

local panel = CreateFrame("Frame")
panel.name = "覺 醒 Raid Tools"
panel:Hide()

local PADDING_H = 16
local SECTION_SPACING = 32
local CHECKBOX_SPACING = 28
local INDENT_1 = 32
local INDENT_2 = 48
local INDENT_3 = 64
local LABEL_WIDTH = 360

-- Current-raid modules live in the main addon. Legacy raids are shipped in the
-- LoadOnDemand AwakeningRaidTools-Legacy addon and only show up in this panel
-- once their modules have been registered (i.e. after an old-raid encounter
-- pulled the legacy addon in). The test raid is always loaded with the main
-- addon and listed last.
local RAID_ORDER_CURRENT = {"VenomousAbyss"}
local RAID_ORDER_LEGACY = {"Voidspire", "Dreamrift", "MarchOfQuelDanas"}
local RAID_ORDER_TEST = {"Aberrus"}
local RAID_ORDER = {}
for _, raidKey in ipairs(RAID_ORDER_CURRENT) do
	RAID_ORDER[#RAID_ORDER + 1] = raidKey
end
for _, raidKey in ipairs(RAID_ORDER_LEGACY) do
	RAID_ORDER[#RAID_ORDER + 1] = raidKey
end
for _, raidKey in ipairs(RAID_ORDER_TEST) do
	RAID_ORDER[#RAID_ORDER + 1] = raidKey
end

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

local function GetGeneralFeatureEnabled(key, default)
	local db = AwakeningRaidToolsDB
	if db and db[key] ~= nil then return db[key] end
	return default ~= false
end

local function SetGeneralFeatureEnabled(key, value)
	AwakeningRaidToolsDB[key] = value and true or false
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
	-- EJ_GetEncounterInfo takes the journal encounter id, not the
	-- DungeonEncounterID used by ENCOUNTER_START.
	local journalId = module.journalEncounterId or module.encounterId
	if journalId then
		local name = EJ_GetEncounterInfo(journalId)
		if name then return name end
	end
	return module.name or "Unknown"
end

local function BuildFeatureRegistry()
	local raidMap = {}
	for _, raidKey in ipairs(RAID_ORDER) do
		raidMap[raidKey] = { name = GetRaidName(raidKey), bosses = {} }
	end

	local generalFeatures = {}

	for moduleName, module in pairs(addon.modules) do
		if module.features and next(module.features) then
			if module.encounterId then
				local raidKey = module.raidName
				if not raidKey and type(moduleName) == "string" then
					local parts = {}
					for segment in moduleName:gmatch("[^.]+") do
						parts[#parts + 1] = segment
					end
					if #parts >= 2 and parts[1] == "Raids" then
						raidKey = parts[2]
					end
				end

				if raidKey and raidMap[raidKey] then
					table.insert(raidMap[raidKey].bosses, {
						module = module,
						name = GetBossName(module),
						encounterId = module.encounterId,
						features = module.features,
					})
				end
			elseif module.generalFeatureKey then
				table.insert(generalFeatures, {
					features = module.features,
					generalFeatureKey = module.generalFeatureKey,
					module = module,
				})
			end
		end
	end

	for _, raid in pairs(raidMap) do
		table.sort(raid.bosses, function(a, b) return a.encounterId < b.encounterId end)
	end

	return raidMap, generalFeatures
end

local panelBuilt = false
local scrollFrame

local function BuildPanel(self)
	local L = addon.L or {}
	local raidMap, generalFeatures = BuildFeatureRegistry()

	-- Rebuild support: tear down the previous scroll frame (and its children)
	-- before rebuilding, so toggling the legacy loader refreshes the panel.
	if scrollFrame then
		scrollFrame:SetParent(nil)
		scrollFrame:Hide()
		scrollFrame = nil
	end

	scrollFrame = CreateFrame("ScrollFrame", nil, self, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -8)
	scrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4)

	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetWidth(scrollFrame:GetWidth() - 8)
	scrollFrame:SetScrollChild(content)

	local currentY = 0

	local function CreateDivider(yOffset)
		local tex = content:CreateTexture(nil, "ARTWORK")
		tex:SetPoint("TOPLEFT", INDENT_1, yOffset)
		tex:SetSize(LABEL_WIDTH, 1)
		tex:SetColorTexture(0.4, 0.4, 0.4, 0.3)
		return -6
	end

	local function CreateSectionHeader(text, xOffset, yOffset)
		local header = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		header:SetPoint("TOPLEFT", xOffset or 0, yOffset or 0)
		header:SetText(text:upper())
		header:SetTextColor(0.6, 0.6, 0.6, 1)
		return header
	end

	local function CreateBossLabel(text, xOffset, yOffset)
		local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		label:SetPoint("TOPLEFT", xOffset, yOffset)
		label:SetText(text)
		label:SetWidth(LABEL_WIDTH)
		return label
	end

	local function CreateCheckbox(label, yAnchor, xOffset, checked, onClick, tooltip)
		local cb = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
		cb:SetPoint("TOPLEFT", xOffset, yAnchor + 2)
		cb:SetChecked(checked)

		local labelText = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		labelText:SetPoint("LEFT", cb, "RIGHT", 2, 0)
		labelText:SetText(label)
		labelText:SetWidth(LABEL_WIDTH)
		labelText:SetJustifyH("LEFT")

		cb:HookScript("OnClick", function(cbSelf)
			onClick(cbSelf:GetChecked())
		end)

		if tooltip then
			cb:SetScript("OnEnter", function(cbSelf)
				GameTooltip:SetOwner(cbSelf, "ANCHOR_RIGHT")
				GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
			end)
			cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end

		return cb
	end

	local function CreateActionButton(label, yAnchor, xOffset, onClick, disabled)
		local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
		btn:SetPoint("TOPLEFT", xOffset, yAnchor + 2)
		btn:SetText(label)
		btn:SetSize(220, 22)
		btn:SetScript("OnClick", onClick)
		btn:SetEnabled(not disabled)
		return btn
	end

	-- Title
	local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", PADDING_H, -PADDING_H)
	title:SetText("覺 醒 Raid Tools")
	currentY = -PADDING_H - 36

	-- ========== GENERAL ==========
	CreateSectionHeader(L.OPTIONS_GENERAL_HEADER or "GENERAL", PADDING_H, currentY)
	currentY = currentY - 22

	CreateCheckbox(L.OPTIONS_SPEC_GEAR_MISMATCH or "Enable gear mismatch check",
		currentY, INDENT_1,
		AwakeningRaidToolsDB and AwakeningRaidToolsDB.SpecGearMismatchEnabled == true,
		function(checked)
			AwakeningRaidToolsDB.SpecGearMismatchEnabled = checked or nil
			local module = addon.modules["Common.SpecGearMismatchWarning"]
			if module then
				if checked then module:Enable() else module:Disable() end
			end
		end)
	currentY = currentY - CHECKBOX_SPACING

	-- Debug toggle
	local debugLabel = L.OPTIONS_DEBUG_ENABLE or "Enable debug logging"
	local debugDesc = L.OPTIONS_DEBUG_ENABLE_DESC
	CreateCheckbox(debugLabel, currentY, INDENT_1,
		AwakeningRaidToolsDB and AwakeningRaidToolsDB.DebugEnabled == true,
		function(checked)
			AwakeningRaidToolsDB.DebugEnabled = checked or nil
		end, debugDesc)
	currentY = currentY - CHECKBOX_SPACING

	-- Legacy load/unload button (stateful label). While an unload is pending
	-- (awaiting /reload) the unload button is grayed out and a reload button
	-- appears next to it.
	local legacyPendingUnload = addon.legacyLoaded and not (AwakeningRaidToolsDB and AwakeningRaidToolsDB.LegacyEnabled)
	if legacyPendingUnload then
		local unloadBtn = CreateActionButton(L.OPTIONS_LEGACY_UNLOAD_BUTTON or "Unload legacy raid modules", currentY, INDENT_1, nil, true)
		local reloadBtn = CreateActionButton(L.OPTIONS_LEGACY_RELOAD_BUTTON or "Reload UI", currentY, INDENT_1, function()
			ReloadUI()
		end)
		reloadBtn:ClearAllPoints() -- drop the anchor set inside CreateActionButton
		reloadBtn:SetPoint("LEFT", unloadBtn, "RIGHT", 4, 0)
	else
		CreateActionButton(addon.legacyLoaded and (L.OPTIONS_LEGACY_UNLOAD_BUTTON or "Unload legacy raid modules") or (L.OPTIONS_LEGACY_LOAD_BUTTON or "Load legacy raid modules"),
			currentY, INDENT_1, function()
				local loader = addon.modules["Core.LegacyLoader"]
				if loader then
					if addon.legacyLoaded then loader:Disable() else loader:Enable() end
				end
			end)
	end
	currentY = currentY - CHECKBOX_SPACING

	for _, gen in ipairs(generalFeatures) do
		for featureName, featureDef in pairs(gen.features) do
			local label = L[featureDef.labelKey] or featureDef.labelKey or featureName
			local tooltip = featureDef.descKey and L[featureDef.descKey] or nil
			local key = gen.generalFeatureKey
			CreateCheckbox(label, currentY, INDENT_1,
				GetGeneralFeatureEnabled(key, featureDef.default),
				function(checked)
					SetGeneralFeatureEnabled(key, checked)
					if gen.module then
						if checked then gen.module:Enable() else gen.module:Disable() end
					end
				end, tooltip)
			currentY = currentY - CHECKBOX_SPACING
		end
	end

	-- ========== BOSS SECTIONS ==========

	local function RenderRaidBosses(raid, indent)
		for _, boss in ipairs(raid.bosses) do
			CreateBossLabel(boss.name, indent, currentY)
			currentY = currentY - 20

			for featureName, featureDef in pairs(boss.features) do
					local label = L[featureDef.labelKey] or featureDef.labelKey or featureName
					local tooltip = featureDef.descKey and L[featureDef.descKey] or nil
					local subWidgets = {}

					local parentCB = CreateCheckbox(label, currentY, INDENT_2,
						GetFeatureEnabled(boss.encounterId, featureName, featureDef.default),
						function(checked)
							SetFeatureEnabled(boss.encounterId, featureName, checked)
							for _, sub in ipairs(subWidgets) do
								if sub._depKey then local dc = GetSubFeatureEnabled(boss.encounterId, featureName, sub._depKey, false); sub:SetShown(checked and dc) else sub:SetShown(checked) end
							end
						end, tooltip)
					currentY = currentY - CHECKBOX_SPACING

					-- Sub-features
					if featureDef.subFeatures then
						local parentChecked = GetFeatureEnabled(boss.encounterId, featureName, featureDef.default)
						for _, subDef in ipairs(featureDef.subFeatures) do
								local subKey = subDef.key
							if subDef.type == "button" then
								local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
								btn:SetPoint("TOPLEFT", INDENT_3, currentY + 2)
								btn:SetText(L[subDef.labelKey] or subKey)
								btn:SetWidth(220)
								btn:SetScript("OnClick", subDef.onClick)
								btn._depKey = subDef.dependsOn
local depKey = subDef.dependsOn; local depChecked = depKey and GetSubFeatureEnabled(boss.encounterId, featureName, depKey, false); btn:SetShown(depKey and parentChecked and depChecked or parentChecked)
								table.insert(subWidgets, btn)
								currentY = currentY - CHECKBOX_SPACING
							else
								local subLabel = L[subDef.labelKey] or subDef.labelKey or subKey
								local subTooltip = subDef.descKey and L[subDef.descKey] or nil
								local subCB = CreateCheckbox(subLabel, currentY, INDENT_3,
									GetSubFeatureEnabled(boss.encounterId, featureName, subKey, subDef.default),
									function(checked)
										SetSubFeatureEnabled(boss.encounterId, featureName, subKey, checked)
										for _, w in ipairs(subWidgets) do
											if w._depKey == subKey then
												w:SetShown(checked)
											end
										end
									end, subTooltip)
								subCB:SetShown(parentChecked)
								table.insert(subWidgets, subCB)
								currentY = currentY - CHECKBOX_SPACING
							end
						end
					end
				end

				currentY = currentY - 4
			end
	end

	for _, raidKey in ipairs(RAID_ORDER) do
		local raid = raidMap[raidKey]
		if raid and #raid.bosses > 0 and not (addon.IsLegacyRaid and addon:IsLegacyRaid(raidKey)) then
			currentY = currentY - 8
			currentY = currentY + CreateDivider(currentY)
			currentY = currentY - 8
			CreateSectionHeader(raid.name, PADDING_H, currentY)
			currentY = currentY - 22

			RenderRaidBosses(raid, INDENT_1)
		end
	end

	-- ========== LEGACY RAIDS ==========
	-- Only shown once the legacy addon is loaded via the general toggle above.

	if addon.legacyLoaded then
		currentY = currentY - 8
		currentY = currentY + CreateDivider(currentY)
		currentY = currentY - 8
		CreateSectionHeader(L.OPTIONS_LEGACY_HEADER or "LEGACY RAIDS", PADDING_H, currentY)
		currentY = currentY - 22

		for _, raidKey in ipairs(RAID_ORDER_LEGACY) do
			local raid = raidMap[raidKey]
			local checked = GetLegacyRaidEnabled(raidKey)
			CreateCheckbox(GetRaidName(raidKey), currentY, INDENT_1, checked, function(value)
				SetLegacyRaidEnabled(raidKey, value)
				if addon.RebuildOptionsPanel then
					addon.RebuildOptionsPanel()
				end
			end)
			currentY = currentY - CHECKBOX_SPACING

			if checked and raid then
				RenderRaidBosses(raid, INDENT_2)
			end
		end
	end

	content:SetHeight(math.abs(currentY) + 20)
	content:SetWidth(scrollFrame:GetWidth() - 8)
end

panel:SetScript("OnShow", function(self)
	if not panelBuilt then
		BuildPanel(self)
		panelBuilt = true
	end
end)

-- Called by Core.LegacyLoader after the legacy addon loads, so historical
-- raid options appear without requiring a /reload.
addon.RebuildOptionsPanel = function()
	if panelBuilt then
		BuildPanel(panel)
	end
end

local canvasCategory, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(canvasCategory)

addon.optionsCategory = canvasCategory
