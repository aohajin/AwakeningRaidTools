local _, addon = ...

local Raid = {}
Raid.name = "VenomousAbyss"
-- JournalInstance.ID 1320 (wago.tools/db2/JournalInstance)
Raid.instanceId = 1320
-- Boss order within the raid (DungeonEncounterID, i.e. ENCOUNTER_START id,
-- in encounter order). Used by the options panel to sort boss features;
-- encounterId values are NOT ascending in fight order, so this explicit
-- order is required.
Raid.bossOrder = {
    3470, -- Boss 1: Nek'zali the Soulcoiler
    3445, -- Boss 2: Entombed Sentinels
    3497, -- Boss 3: The Lost Explorers
    3455, -- Boss 4: Vashnik the Malignant
    3420, -- Boss 5: Sszorak
    3421, -- Boss 6: The Twin Fangs
    3429, -- Boss 7: The Coiled Altar
    3492, -- Boss 8: Ula'tek
}

addon:RegisterModule("Raids.VenomousAbyss", Raid)
