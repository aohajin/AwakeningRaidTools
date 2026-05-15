local _, addon = ...

local panel = CreateFrame("Frame")
panel.name = "Awakening Raid Tools"
panel:Hide()

local PADDING_H = 16
local SECTION_SPACING = 28
local CHECKBOX_SPACING = 26
local BOSS_INDENT = 32
local FEATURE_INDENT = 48

local RAID_ORDER = {
	{ key = "Voidspire",          name = "Voidspire" },
	{ key = "Dreamrift",          name = "Dreamrift" },
	{ key = "MarchOfQuelDanas",   name = "March of Quel'Danas" },
	{ key = "Aberrus",            name = "Aberrus, the Shadowed Crucible" },
}

local function GetFeatureEnabled(encounterId, featureName, default)
	local db = AwakeningRaidToolsDB
	if db and db.encounters and db.encounters[encounterId] then
		local val = db.encounters[encounterId][featureName]
		if val ~= nil then
			return val
		end
	end
	return default ~= false
end

local function SetFeatureEnabled(encounterId, featureName, value)
	local db = AwakeningRaidToolsDB
	if not db.encounters then
		db.encounters = {}
	end
	if not db.encounters[encounterId] then
		db.encounters[encounterId] = {}
	end
	db.encounters[encounterId][featureName] = value or nil
end

local function BuildFeatureRegistry()
	local raidMap = {}
	for _, raidDef in ipairs(RAID_ORDER) do
		raidMap[raidDef.key] = { name = raidDef.name, bosses = {} }
	end

	for moduleName, module in pairs(addon.modules) do
		if module.features and module.encounterId then
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
					name = module.name,
					encounterId = module.encounterId,
					features = module.features,
				})
			end
		end
	end

	for _, raid in pairs(raidMap) do
		table.sort(raid.bosses, function(a, b) return a.encounterId < b.encounterId end)
	end

	return raidMap
end

panel:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	local L = addon.L or {}

	local scrollFrame = CreateFrame("ScrollFrame", nil, self, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -8)
	scrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4)

	local content = CreateFrame("Frame", nil, scrollFrame)
	scrollFrame:SetScrollChild(content)

	local currentY = 0

	local function CreateHeader(text, xOffset, yOffset)
		local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		header:SetPoint("TOPLEFT", xOffset or 0, yOffset or 0)
		header:SetText(text)
		return header
	end

	local function CreateCheckbox(label, yAnchor, xOffset, checked, onClick)
		local cb = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
		cb:SetPoint("TOPLEFT", xOffset or FEATURE_INDENT, yAnchor or 0)
		cb.Text:SetText(label)
		cb:SetChecked(checked)
		cb:HookScript("OnClick", function(self)
			onClick(self:GetChecked())
		end)
		return cb
	end

	-- Title
	CreateHeader("Awakening Raid Tools", PADDING_H, -PADDING_H)
	currentY = -PADDING_H - 28

	-- ========== GENERAL ==========
	currentY = currentY - 10
	CreateHeader(L.OPTIONS_GENERAL_HEADER or "General", PADDING_H, currentY)
	currentY = currentY - 28

	local specGearLabel = L.OPTIONS_SPEC_GEAR_MISMATCH or "Enable gear mismatch check"
	CreateCheckbox(specGearLabel, currentY, BOSS_INDENT,
		AwakeningRaidToolsDB and AwakeningRaidToolsDB.SpecGearMismatchEnabled == true,
		function(checked)
			PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
			AwakeningRaidToolsDB.SpecGearMismatchEnabled = checked or nil
			local module = addon.modules["Common.SpecGearMismatchWarning"]
			if module then
				if checked then module:Enable() else module:Disable() end
			end
		end)
	currentY = currentY - CHECKBOX_SPACING

	-- ========== BOSS SECTIONS ==========
	local registry = BuildFeatureRegistry()

	for _, raidDef in ipairs(RAID_ORDER) do
		local raid = registry[raidDef.key]
		if raid and #raid.bosses > 0 then
			currentY = currentY - SECTION_SPACING
			CreateHeader(raid.name, PADDING_H, currentY)
			currentY = currentY - 26

			for _, boss in ipairs(raid.bosses) do
				local bossLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				bossLabel:SetPoint("TOPLEFT", BOSS_INDENT, currentY)
				bossLabel:SetText(boss.name)
				currentY = currentY - 22

				for featureName, featureDef in pairs(boss.features) do
					local label = L[featureDef.labelKey] or featureDef.labelKey or featureName
					local default = (featureDef.default ~= false)
					local cb = CreateCheckbox(label, currentY, FEATURE_INDENT,
						GetFeatureEnabled(boss.encounterId, featureName, default),
						function(checked)
							PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
							SetFeatureEnabled(boss.encounterId, featureName, checked)
						end)
					if featureDef.descKey then
						cb.tooltip = L[featureDef.descKey]
					end
					currentY = currentY - CHECKBOX_SPACING
				end

				currentY = currentY - 6
			end
		end
	end

	content:SetHeight(math.abs(currentY) + 20)
	content:SetWidth(scrollFrame:GetWidth() - 8)
end)

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)
