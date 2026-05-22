local _, addon = ...

local panel = CreateFrame("Frame")
panel.name = "覺 醒 Raid Tools"
panel:Hide()

local PADDING_H = 16
local SECTION_SPACING = 32
local CHECKBOX_SPACING = 28
local INDENT_1 = 32
local INDENT_2 = 48
local LABEL_WIDTH = 360

local RAID_ORDER = {"Voidspire", "Dreamrift", "MarchOfQuelDanas", "Aberrus"}

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
	db.encounters[encounterId][featureName] = value or nil
end

local function GetGeneralFeatureEnabled(key, default)
	local db = AwakeningRaidToolsDB
	if db and db[key] ~= nil then return db[key] end
	return default ~= false
end

local function SetGeneralFeatureEnabled(key, value)
	AwakeningRaidToolsDB[key] = value or nil
end

local function GetRaidName(raidKey)
	local raidModule = addon.modules["Raids." .. raidKey]
	if raidModule and raidModule.instanceId then
		local info = EJ_GetInstanceInfo(raidModule.instanceId)
		if info then return info end
	end
	local L = addon.L or {}
	local keys = {
		Voidspire = "RAID_VOIDSPIRE",
		Dreamrift = "RAID_DREAMRIFT",
		MarchOfQuelDanas = "RAID_MARCH_OF_QUELDANAS",
		Aberrus = "RAID_ABERRUS",
	}
	local key = keys[raidKey]
	return (key and L[key]) or raidKey
end

local function GetBossName(module)
	if module.encounterId then
		local name = EJ_GetEncounterInfo(module.encounterId)
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
		if module.features then
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

panel:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	local L = addon.L or {}
	local raidMap, generalFeatures = BuildFeatureRegistry()

	local scrollFrame = CreateFrame("ScrollFrame", nil, self, "UIPanelScrollFrameTemplate")
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

		return 20
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

	for _, raidKey in ipairs(RAID_ORDER) do
		local raid = raidMap[raidKey]
		if raid and #raid.bosses > 0 then
			currentY = currentY - 8
			currentY = currentY + CreateDivider(currentY)
			currentY = currentY - 8
			CreateSectionHeader(raid.name, PADDING_H, currentY)
			currentY = currentY - 22

			for _, boss in ipairs(raid.bosses) do
				CreateBossLabel(boss.name, INDENT_1, currentY)
				currentY = currentY - 20

				for featureName, featureDef in pairs(boss.features) do
					local label = L[featureDef.labelKey] or featureDef.labelKey or featureName
					local tooltip = featureDef.descKey and L[featureDef.descKey] or nil
					CreateCheckbox(label, currentY, INDENT_2,
						GetFeatureEnabled(boss.encounterId, featureName, featureDef.default),
						function(checked)
							SetFeatureEnabled(boss.encounterId, featureName, checked)
						end, tooltip)
					currentY = currentY - CHECKBOX_SPACING
				end

				currentY = currentY - 4
			end
		end
	end

	content:SetHeight(math.abs(currentY) + 20)
	content:SetWidth(scrollFrame:GetWidth() - 8)
end)

local canvasCategory, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(canvasCategory)

addon.optionsCategory = canvasCategory
