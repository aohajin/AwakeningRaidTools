-- Checkbox-left settings row mixin (Delves-Helper / HousingDecorGuide style).
-- Subclasses SettingsCheckboxControlMixin; re-anchors the checkbox to the left
-- so the label fills the rest of the row instead of Blizzard's default
-- centre-anchored checkbox + left-column label (which truncates long names).
ART_SettingsCheckRowMixin = CreateFromMixins(SettingsCheckboxControlMixin)

function ART_SettingsCheckRowMixin:Init(initializer)
    SettingsCheckboxControlMixin.Init(self, initializer)
    local indent = self:GetIndent()
    self.Checkbox:ClearAllPoints()
    self.Checkbox:SetPoint("LEFT", self, "LEFT", indent + 8, 0)
    self.Text:ClearAllPoints()
    self.Text:SetPoint("LEFT", self.Checkbox, "RIGHT", 6, 0)
    self.Text:SetPoint("RIGHT", self, "RIGHT", -8, 0)
    self.Text:SetJustifyH("LEFT")
end

-- ============================================================================
-- ART_ReloadButtonMixin — a settings button row hidden until a "dirty"
-- variable turns true (e.g. legacy raid toggles changed, needing a /reload).
-- Expects initializer.data.dirtySetting (a Setting object). On init the row
-- is shown only when dirty is already true; a callback handle flips it as
-- the variable changes.
-- ============================================================================
ART_ReloadButtonMixin = CreateFromMixins(SettingsButtonControlMixin)

function ART_ReloadButtonMixin:OnLoad()
    SettingsButtonControlMixin.OnLoad(self)
end

function ART_ReloadButtonMixin:Init(initializer)
    SettingsButtonControlMixin.Init(self, initializer)

    local dirtySetting = initializer.data and initializer.data.dirtySetting
    if dirtySetting then
        local function OnDirtyChanged()
            local ok, dirty = pcall(dirtySetting.GetValue, dirtySetting)
            self:SetShown(ok and dirty == true)
        end
        -- Immediate state, then subscribe.
        OnDirtyChanged()
        self.cbrHandles:SetOnValueChangedCallback(
            dirtySetting:GetVariable(), OnDirtyChanged, self)
    else
        self:Show()
    end
end

-- ============================================================================
-- ART_BossLabelMixin — a static boss-name row. Subclasses the stock element
-- base (which supplies Text + GetIndent) but renders no checkbox/button:
-- just the name at the row's indent, used as a visual group header that boss
-- feature toggles attach to as children.
-- ============================================================================
ART_BossLabelMixin = CreateFromMixins(SettingsListElementMixin)

function ART_BossLabelMixin:OnLoad()
    SettingsListElementMixin.OnLoad(self)
end

function ART_BossLabelMixin:Init(initializer)
    SettingsListElementMixin.Init(self, initializer)
    local indent = self:GetIndent()
    self.Text:ClearAllPoints()
    self.Text:SetPoint("LEFT", self, "LEFT", indent + 6, 0)
    self.Text:SetPoint("RIGHT", self, "RIGHT", -8, 0)
    self.Text:SetJustifyH("LEFT")
    self.Text:SetFontObject(GameFontHighlightSmall)
end
