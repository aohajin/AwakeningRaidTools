local _, addon = ...

local SpecGearMismatchWarning = {}
SpecGearMismatchWarning.name = "SpecGearMismatchWarning"

local frame = CreateFrame("Frame")
local pendingCheck = false
local lastMismatchKey = nil

local L = addon.L or {
    STAT_STRENGTH = "Strength",
    STAT_AGILITY = "Agility",
    STAT_INTELLECT = "Intellect",
    SLOT_HEAD = "Head",
    SLOT_NECK = "Neck",
    SLOT_SHOULDER = "Shoulder",
    SLOT_CHEST = "Chest",
    SLOT_WAIST = "Waist",
    SLOT_LEGS = "Legs",
    SLOT_FEET = "Feet",
    SLOT_WRIST = "Wrist",
    SLOT_HAND = "Hands",
    SLOT_FINGER1 = "Ring 1",
    SLOT_FINGER2 = "Ring 2",
    SLOT_TRINKET1 = "Trinket 1",
    SLOT_TRINKET2 = "Trinket 2",
    SLOT_BACK = "Back",
    SLOT_MAINHAND = "Main Hand",
    SLOT_OFFHAND = "Off Hand",
    UNKNOWN_STAT = "Unknown",
    UNKNOWN_SLOT = "Slot %s",
    CENTER_ENTRY = "[%s:%s]",
    CENTER_MSG = "Primary stat mismatch (spec: %s) %s",
    CHAT_ENTRY = "[%s] %s %s",
    CHAT_MSG = "ART: Primary stat mismatch (spec: %s) %s",
    LIST_SEPARATOR = "; ",
}

local centerNoticeFrame = CreateFrame("Frame", nil, UIParent)
centerNoticeFrame:SetSize(1200, 80)
centerNoticeFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 140)
centerNoticeFrame:Hide()

local centerNoticeText = centerNoticeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
centerNoticeText:SetPoint("CENTER", centerNoticeFrame, "CENTER", 0, 0)
centerNoticeText:SetTextColor(1, 0.2, 0.2, 1)
centerNoticeText:SetJustifyH("CENTER")
centerNoticeText:SetJustifyV("MIDDLE")

local PRIMARY_STAT_NAME = {
    [1] = L.STAT_STRENGTH,
    [2] = L.STAT_AGILITY,
    [4] = L.STAT_INTELLECT,
}

local PRIMARY_STAT_ITEM_KEY = {
    [1] = "ITEM_MOD_STRENGTH_SHORT",
    [2] = "ITEM_MOD_AGILITY_SHORT",
    [4] = "ITEM_MOD_INTELLECT_SHORT",
}

local OTHER_PRIMARY_STATS = {
    [1] = {2, 4},
    [2] = {1, 4},
    [4] = {1, 2},
}

local SLOT_NAME = {
    [INVSLOT_HEAD] = L.SLOT_HEAD,
    [INVSLOT_NECK] = L.SLOT_NECK,
    [INVSLOT_SHOULDER] = L.SLOT_SHOULDER,
    [INVSLOT_CHEST] = L.SLOT_CHEST,
    [INVSLOT_WAIST] = L.SLOT_WAIST,
    [INVSLOT_LEGS] = L.SLOT_LEGS,
    [INVSLOT_FEET] = L.SLOT_FEET,
    [INVSLOT_WRIST] = L.SLOT_WRIST,
    [INVSLOT_HAND] = L.SLOT_HAND,
    [INVSLOT_FINGER1] = L.SLOT_FINGER1,
    [INVSLOT_FINGER2] = L.SLOT_FINGER2,
    [INVSLOT_TRINKET1] = L.SLOT_TRINKET1,
    [INVSLOT_TRINKET2] = L.SLOT_TRINKET2,
    [INVSLOT_BACK] = L.SLOT_BACK,
    [INVSLOT_MAINHAND] = L.SLOT_MAINHAND,
    [INVSLOT_OFFHAND] = L.SLOT_OFFHAND,
}

local EQUIPPED_SLOT_IDS = {
    INVSLOT_HEAD,
    INVSLOT_NECK,
    INVSLOT_SHOULDER,
    INVSLOT_CHEST,
    INVSLOT_WAIST,
    INVSLOT_LEGS,
    INVSLOT_FEET,
    INVSLOT_WRIST,
    INVSLOT_HAND,
    INVSLOT_FINGER1,
    INVSLOT_FINGER2,
    INVSLOT_TRINKET1,
    INVSLOT_TRINKET2,
    INVSLOT_BACK,
    INVSLOT_MAINHAND,
    INVSLOT_OFFHAND,
}

local function GetCurrentSpecializationIndex()
    if C_SpecializationInfo and type(C_SpecializationInfo.GetSpecialization) == "function" then
        return C_SpecializationInfo.GetSpecialization()
    end
    if type(GetSpecialization) == "function" then
        return GetSpecialization()
    end
    return nil
end

local function GetSpecializationDetails(specIndex)
    if C_SpecializationInfo and type(C_SpecializationInfo.GetSpecializationInfo) == "function" then
        return C_SpecializationInfo.GetSpecializationInfo(specIndex)
    end
    if type(GetSpecializationInfo) == "function" then
        return GetSpecializationInfo(specIndex)
    end
    return nil
end

local function GetItemStatsTable(itemLink)
    if C_Item and type(C_Item.GetItemStats) == "function" then
        return C_Item.GetItemStats(itemLink)
    end
    if type(GetItemStats) == "function" then
        return GetItemStats(itemLink)
    end
    return nil
end

local function GetExpectedPrimaryStat()
    local specIndex = GetCurrentSpecializationIndex()
    if not specIndex then
        return nil
    end

    local result1, _, _, _, _, result6 = GetSpecializationDetails(specIndex)
    local primaryStat
    if type(result1) == "table" then
        primaryStat = result1.primaryStat
    else
        primaryStat = result6
    end

    if not PRIMARY_STAT_NAME[primaryStat] then
        return nil
    end

    return primaryStat
end

local function GetMismatchedItems(primaryStat)
    local mismatches = {}
    local disallowedStats = OTHER_PRIMARY_STATS[primaryStat]
    if not disallowedStats then
        return mismatches
    end

    local expectedKey = PRIMARY_STAT_ITEM_KEY[primaryStat]
    for i = 1, #EQUIPPED_SLOT_IDS do
        local slotID = EQUIPPED_SLOT_IDS[i]
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            local itemStats = GetItemStatsTable(itemLink)
            if type(itemStats) == "table" then
                local expectedValue = itemStats[expectedKey] or 0
                if expectedValue <= 0 then
                    for j = 1, #disallowedStats do
                        local otherStat = disallowedStats[j]
                        local otherKey = PRIMARY_STAT_ITEM_KEY[otherStat]
                        local otherValue = itemStats[otherKey] or 0
                        if otherValue > 0 then
                            mismatches[#mismatches + 1] = {
                                itemLink = itemLink,
                                mismatchStat = otherStat,
                                slotID = slotID,
                            }
                            break
                        end
                    end
                end
            end
        end
    end

    return mismatches
end

local function BuildMismatchKey(expectedPrimaryStat, mismatches)
    local parts = { tostring(expectedPrimaryStat or 0) }
    for i = 1, #mismatches do
        local mismatch = mismatches[i]
        parts[#parts + 1] = ("%d:%d:%s"):format(mismatch.slotID or 0, mismatch.mismatchStat or 0, mismatch.itemLink or "")
    end
    return table.concat(parts, "|")
end

local function BuildMismatchSummary(expectedPrimaryStat, mismatches)
    local expectedStatName = PRIMARY_STAT_NAME[expectedPrimaryStat] or L.UNKNOWN_STAT
    local centerParts = {}
    local chatParts = {}
    for i = 1, #mismatches do
        local mismatch = mismatches[i]
        local slotName = SLOT_NAME[mismatch.slotID] or L.UNKNOWN_SLOT:format(tostring(mismatch.slotID or "?"))
        local mismatchStatName = PRIMARY_STAT_NAME[mismatch.mismatchStat] or L.UNKNOWN_STAT
        centerParts[#centerParts + 1] = L.CENTER_ENTRY:format(slotName, mismatchStatName)
        chatParts[#chatParts + 1] = L.CHAT_ENTRY:format(slotName, mismatchStatName, mismatch.itemLink or "")
    end

    local centerMsg = L.CENTER_MSG:format(expectedStatName, table.concat(centerParts, " "))
    local chatMsg = L.CHAT_MSG:format(expectedStatName, table.concat(chatParts, L.LIST_SEPARATOR))
    return centerMsg, chatMsg
end

local function ShowMismatchWarning(expectedPrimaryStat, mismatches)
    local centerMsg, chatMsg = BuildMismatchSummary(expectedPrimaryStat, mismatches)

    if UIErrorsFrame and type(UIErrorsFrame.AddMessage) == "function" then
        UIErrorsFrame:AddMessage(chatMsg, 1, 0.2, 0.2, 1)
    end
    centerNoticeText:SetText(centerMsg)
    centerNoticeFrame:Show()
    print(chatMsg)
end

local function CheckMismatch()
    if not SpecGearMismatchWarning.isEnabled then
        return
    end

    local expectedPrimaryStat = GetExpectedPrimaryStat()
    if not expectedPrimaryStat then
        lastMismatchKey = nil
        centerNoticeFrame:Hide()
        return
    end

    local mismatches = GetMismatchedItems(expectedPrimaryStat)
    if #mismatches == 0 then
        lastMismatchKey = nil
        centerNoticeFrame:Hide()
        return
    end

    local mismatchKey = BuildMismatchKey(expectedPrimaryStat, mismatches)
    if mismatchKey == lastMismatchKey then
        local centerMsg = BuildMismatchSummary(expectedPrimaryStat, mismatches)
        centerNoticeText:SetText(centerMsg)
        centerNoticeFrame:Show()
        return
    end

    lastMismatchKey = mismatchKey
    ShowMismatchWarning(expectedPrimaryStat, mismatches)
end

local function ScheduleCheck()
    if pendingCheck then
        return
    end
    pendingCheck = true

    C_Timer.After(0.1, function()
        pendingCheck = false
        CheckMismatch()
    end)
end

function SpecGearMismatchWarning:OnInitialize()
    frame:SetScript("OnEvent", function(_, event, arg1)
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            ScheduleCheck()
            return
        end

        if event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 ~= "player" then
            return
        end

        ScheduleCheck()
    end)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    frame:RegisterEvent("TRAIT_CONFIG_UPDATED")

    if AwakeningRaidToolsDB and AwakeningRaidToolsDB.SpecGearMismatchEnabled then
        self:Enable()
    end
end

function SpecGearMismatchWarning:Enable()
    self.isEnabled = true
    ScheduleCheck()
end

function SpecGearMismatchWarning:Disable()
    self.isEnabled = false
    lastMismatchKey = nil
    centerNoticeFrame:Hide()
end

addon:RegisterModule("Common.SpecGearMismatchWarning", SpecGearMismatchWarning)
