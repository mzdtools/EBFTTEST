-- ============================================
-- [MODULE 4] SETTINGS & STATUS
-- ============================================

local M = {}

function M.init(Modules)
    local MzD = Modules.globals.MzD

    MzD.S = {
        Farming            = true,  -- Standaard aan
        SelectedBrainrots  = {},
        TargetMutation     = "None",
        TargetRarity       = {"Divine", "Infinity"}, -- Standaard Divine & Infinity
        TweenSpeed         = 9999,
        CorridorSpeed      = 1500,
        AutoCollectMoney   = false,
        InstantPickup      = true,
        AntiAFK            = false,
        AutoUpgrade        = false,
        MaxLevel           = 250,
        FactoryEnabled     = false,
        FactorySlot        = "5",
        FactoryRarity      = "Common",
        FactoryMutation    = "None",
        FactoryMaxLevel    = 250,
        FarmMode           = "Collect", -- Standaard op Collect
        FarmSlot           = "5",
        ValentineEnabled   = true,  -- Alle events standaard aan
        ArcadeEnabled      = true,
        FireiceEnabled     = true,
        MapFixerEnabled    = false,
        LuckyBlockEnabled  = true,  -- LB standaard aan
        LuckyBlockRarity   = {"Divine", "Infinity"}, -- LB standaard Divine & Infinity
        LuckyBlockMutation = "Any",
        GodEnabled         = false,
        GodWalkY           = 0,
        GodFloorY          = -10,
        DoomEnabled        = true,  -- Event aan
        WallTheme          = "Auto",
        GuiScale           = 1.0,
        -- Tower Trial
        TowerTrialEnabled  = false,
        TowerTrialSlot     = "5",
        TowerTrialFallbackCd = 305,
    }

    MzD.Status = {
        farm           = "Idle", farmCount      = 0,
        money          = "Idle",
        afk            = "Uit",
        placeCount     = 0,      upgradeCount   = 0,
        upgrade        = "Idle",
        factory        = "Idle", factoryCount  = 0,
        valentine      = "Idle", valentineCount = 0,
        arcade         = "Idle", arcadeCount   = 0,
        fireice        = "Idle", fireiceCount  = 0,
        mapFixer       = "Uit",
        luckyBlock     = "Idle", luckyBlockCount = 0,
        god            = "Uit",
        doom           = "Uit",  doomCount      = 0,
        towerTrial     = "Idle", towerTrialCount = 0,
    }
end

return M
