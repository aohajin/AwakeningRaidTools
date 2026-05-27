local _, addon = ...

local Counter = {}
Counter.name = "Counter"

local markers = {}

local function Ensure(key)
	if markers[key] then return markers[key] end
	local holder = CreateFrame("Frame", nil, UIParent)
	holder:SetSize(52, 52)
	holder:SetFrameStrata("MEDIUM")
	local bg = holder:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.1, 0.75, 0.2, 0.95)
	holder.label = holder:CreateFontString(nil, "OVERLAY")
	holder.label:SetFont(STANDARD_TEXT_FONT, 28, "OUTLINE")
	holder.label:SetPoint("CENTER")
	holder.label:SetTextColor(1, 1, 1, 1)
	holder:Hide()
	markers[key] = holder
	return holder
end

function Counter:SetAnchor(key, frame, point, relPoint, x, y)
	local m = Ensure(key)
	m:ClearAllPoints()
	m:SetPoint(point, frame, relPoint, x, y)
end

function Counter:Show(key, num, scale)
	local m = Ensure(key)
	m.label:SetText(tostring(num))
	if scale then m:SetScale(scale) end
	m:Show()
end

function Counter:Hide(key)
	if key then
		local m = markers[key]
		if m then m:Hide() end
	else
		for _, m in pairs(markers) do m:Hide() end
	end
end

function Counter:GetMarker(key)
	return markers[key] or Ensure(key)
end

function Counter:OnInitialize() end

addon:RegisterModule("Common.Counter", Counter)
