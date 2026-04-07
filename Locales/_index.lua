local _, addon = ...

addon.locales = addon.locales or {}

local locale = GetLocale()
if locale == "enGB" then
    locale = "enUS"
end

local base = addon.locales.enUS or {}
local selected = addon.locales[locale] or {}

local merged = {}
for k, v in pairs(base) do
    merged[k] = v
end
for k, v in pairs(selected) do
    merged[k] = v
end

addon.L = merged
