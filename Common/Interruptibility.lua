local _, addon = ...

local Interruptibility = {}
Interruptibility.name = "Interruptibility"

function Interruptibility:IsNotInterruptible(unit)
    local castName, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
    if castName then
        return notInterruptible == true
    end

    local channelName
    channelName, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
    if channelName then
        return notInterruptible == true
    end

    return nil
end

addon:RegisterModule("Common.Interruptibility", Interruptibility)
