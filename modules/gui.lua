-- ============================================
-- [MODULE 27] GUI (FLUENT UI) — CLEAN
-- ============================================

local M = {}

function M.init(Modules)
    local G = Modules.globals
    local MzD = G.MzD
    local Player = G.Player
    local tinsert = G.tinsert
    local twait = G.twait
    local sfind = G.sfind
    local sformat = G.sformat
    local mfloor = G.mfloor
    local god_mod = Modules.god_mode

    twait(0.5)
    pcall(function()
        for _, gui in pairs(Player.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, d in pairs(gui:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text == "MzD Hub" then gui:Destroy() break end
                end
            end
        end
    end)
    twait(0.3)

    local Fluent, SaveManager, InterfaceManager
    local ok1, r1 = pcall(function()
        return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end)
    if ok1 then Fluent = r1 else warn("[MzD Hub] Fluent laden mislukt: "..tostring(r1)) return end

    local ok2, r2 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    end)
    SaveManager = ok2 and r2 or nil

    local ok3, r3 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    end)
    InterfaceManager = ok3 and r3 or nil

    local RAR  = MzD.getAvailableRarities()
    local MUT  = MzD.getAvailableMutations()
    local FM   = {"Collect", "Collect, Place & Max"}
    local LBR  = {"Any","Common","Uncommon","Rare","Epic","Legendary","Mythical","Cosmic","Secret","Celestial","Divine","Infinity","Admin","UFO","Candy","Money"}
    local SL   = {} for i = 1, 40 do tinsert(SL, tostring(i)) end
    local SPD  = {"200","400","600","800","1000","1500","2000","3000","4000","INSTANT"}
    local SPM  = {["200"]=200,["400"]=400,["600"]=600,["800"]=800,["1000"]=1000,["1500"]=1500,["2000"]=2000,["3000"]=3000,["4000"]=4000,["INSTANT"]=9999}
    local CSPD = {"100","200","300","400","500","600","800","1000","1500","2000"}
    local GODWALKY  = {"5","3","1","0","-1","-2","-3","-5","-8","-10","-15"}
    local GODFLOORY = {"15","12","10","8","5","3","0","-3","-5","-8","-10","-15","-20"}
    local THEMES    = {"Auto","Dark","Doom","Valentine","UFO","Bright"}

    local W = Fluent:CreateWindow({
        Title       = "MzD Hub",
        SubTitle    = "v13.0",
        TabWidth    = 160,
        Size        = UDim2.fromOffset(580, 480),
        Acrylic     = true,
        Theme       = "Dark",
        MinimizeKey = Enum.KeyCode.RightControl
    })

    -- ========== FARM TAB ==========
    local FT  = W:AddTab({Title = "Farm", Icon = "leaf"})
    local BDD = nil

    local RDD = FT:AddDropdown("FarmRarity", {Title = "Rarity", Values = RAR, Default = {"Common"}, Multi = true})
    RDD:OnChanged(function(v)
        local s = {} for n, on in pairs(v) do if on then tinsert(s, n) end end
        if #s == 0 then s = {"Common"} end
        local any = false for _, r in pairs(s) do if r == "Any" then any = true break end end
        MzD.S.TargetRarity = any and "Any" or s
        MzD.S.SelectedBrainrots = {}
        pcall(function() BDD:SetValues(MzD.getBrainrotNamesMulti(MzD.S.TargetRarity)) BDD:SetValue({}) end)
    end)

    BDD = FT:AddDropdown("FarmBrainrots", {Title = "Brainrots", Values = MzD.getBrainrotNamesMulti(MzD.S.TargetRarity), Default = {}, Multi = true})
    BDD:OnChanged(function(v)
        local s = {} for n, on in pairs(v) do if on then tinsert(s, n) end end
        MzD.S.SelectedBrainrots = s
    end)

    FT:AddDropdown("FarmMutation", {Title = "Mutatie", Values = MUT, Default = "None", Multi = false}):OnChanged(function(v) MzD.S.TargetMutation = v end)
    FT:AddDropdown("FarmMode",     {Title = "Mode",    Values = FM,  Default = MzD.S.FarmMode, Multi = false}):OnChanged(function(v) MzD.S.FarmMode = v end)
    FT:AddDropdown("FarmSlot",     {Title = "Slot",    Values = SL,  Default = MzD.S.FarmSlot, Multi = false}):OnChanged(function(v) MzD.S.FarmSlot = v end)
    FT:AddSlider("FarmMaxLevel",   {Title = "Max Level", Default = MzD.S.MaxLevel, Min = 1, Max = 500, Rounding = 0}):OnChanged(function(v) MzD.S.MaxLevel = mfloor(v) end)

    local FTG = FT:AddToggle("FarmToggle", {Title = "Auto Farm", Default = false})
    FTG:OnChanged(function(v) if v then MzD.findBase() MzD.startFarming() else MzD.stopFarming() end end)

    FT:AddDropdown("LBRarity",   {Title = "LB Rarity",  Values = LBR, Default = {"Common"}, Multi = true}):OnChanged(function(v)
        local s = {} for n, on in pairs(v) do if on then tinsert(s, n) end end
        if #s == 0 then s = {"Common"} end MzD.S.LuckyBlockRarity = s
    end)
    FT:AddDropdown("LBMutation", {Title = "LB Mutatie", Values = MUT, Default = "Any", Multi = false}):OnChanged(function(v) MzD.S.LuckyBlockMutation = v end)

    local LBTG = FT:AddToggle("LBToggle", {Title = "Auto Lucky Blocks", Default = false})
    LBTG:OnChanged(function(v) if v then MzD.findBase() MzD.startLuckyBlockFarm() else MzD.stopLuckyBlockFarm() end end)

    FT:AddDropdown("TowerTrialSlot", {Title = "Trial Slot", Values = SL, Default = "5", Multi = false}):OnChanged(function(v) MzD.S.TowerTrialSlot = v end)
    FT:AddSlider("TowerTrialFallbackCd", {Title = "Trial Cooldown (sec)", Default = 305, Min = 60, Max = 600, Rounding = 0}):OnChanged(function(v) MzD.S.TowerTrialFallbackCd = mfloor(v) end)

    local TTTG = FT:AddToggle("TowerTrialToggle", {Title = "Auto Tower Trial", Default = false})
    TTTG:OnChanged(function(v)
        if v then MzD.startTowerTrial() MzD.startTrialHUD() else MzD.stopTowerTrial() MzD.stopTrialHUD() end
    end)

    -- Walk Y buttons
    for _, delta in ipairs({-3, -1, 1, 3}) do
        FT:AddButton({Title = "Walk Y  "..(delta > 0 and "+" or "")..delta, Callback = function()
            MzD.S.GodWalkY = (MzD.S.GodWalkY or 0) + delta
            if MzD._isGod then pcall(function() god_mod.godTeleportUnder() end) end
        end})
    end

    -- ========== FACTORY TAB ==========
    local FCT = W:AddTab({Title = "Factory", Icon = "factory"})
    FCT:AddDropdown("FactoryRarity",   {Title = "Rarity",   Values = RAR, Default = MzD.S.FactoryRarity,   Multi = false}):OnChanged(function(v) MzD.S.FactoryRarity = v end)
    FCT:AddDropdown("FactoryMutation", {Title = "Mutatie",  Values = MUT, Default = MzD.S.FactoryMutation, Multi = false}):OnChanged(function(v) MzD.S.FactoryMutation = v end)
    FCT:AddDropdown("FactorySlot",     {Title = "Werkslot", Values = SL,  Default = MzD.S.FactorySlot,     Multi = false}):OnChanged(function(v) MzD.S.FactorySlot = v end)
    FCT:AddSlider("FactoryMaxLevel",   {Title = "Max Level", Default = MzD.S.FactoryMaxLevel, Min = 1, Max = 500, Rounding = 0}):OnChanged(function(v) MzD.S.FactoryMaxLevel = mfloor(v) end)

    local FCTG = FCT:AddToggle("FactoryToggle", {Title = "Start Factory", Default = false})
    FCTG:OnChanged(function(v) if v then MzD.findBase() MzD.startFactoryLoop() else MzD.stopFactoryLoop() end end)

    -- ========== EVENTS TAB ==========
    local ET = W:AddTab({Title = "Events", Icon = "party-popper"})

    local DMTG = ET:AddToggle("DoomToggle", {Title = "Auto Doom Coins", Default = false})
    DMTG:OnChanged(function(v) if v then MzD.startDoomCollector() else MzD.stopDoomCollector() end end)

    local VTG = ET:AddToggle("ValentineToggle", {Title = "Auto Valentine", Default = false})
    VTG:OnChanged(function(v) if v then MzD.startValentine() else MzD.stopValentine() end end)

    ET:AddButton({Title = "Submit Candy (1x)", Callback = function()
        MzD.submitCandyGrams()
    end})

    local ATG = ET:AddToggle("ArcadeToggle", {Title = "Auto Arcade", Default = false})
    ATG:OnChanged(function(v) if v then MzD.startArcade() else MzD.stopArcade() end end)

    local FFTG = ET:AddToggle("FireficeToggle", {Title = "Auto Firefice Coins", Default = false})
    FFTG:OnChanged(function(v) if v then MzD.startFireficeCoinFarm() else MzD.stopFireficeCoinFarm() end end)

    -- ========== TOOLS TAB ==========
    local AT2 = W:AddTab({Title = "Tools", Icon = "wrench"})

    local MTG = AT2:AddToggle("MoneyToggle", {Title = "Auto Money", Default = false})
    MTG:OnChanged(function(v) if v then MzD.findBase() MzD.startMoney() else MzD.stopMoney() end end)

    local UTG = AT2:AddToggle("UpgradeToggle", {Title = "Upgrade All Slots", Default = false})
    UTG:OnChanged(function(v) if v then MzD.findBase() MzD.startAutoUpgrade() else MzD.stopAutoUpgrade() end end)

    local MFTG = AT2:AddToggle("MapToggle", {Title = "Map Fixer", Default = false})
    MFTG:OnChanged(function(v) if v then MzD.startMapFixer() else MzD.stopMapFixer() end end)

    AT2:AddButton({Title = "Fix Map Nu", Callback = function()
        MzD._lastFixedMapName = "" pcall(function() MzD.mapRunFix() end)
    end})
    AT2:AddButton({Title = "Verwijder Deco", Callback = function()
        local map = MzD.mapFindCurrentMap()
        if map then MzD.removeMapDeco(map) end
    end})

    AT2:AddDropdown("GodWalkY",  {Title = "God Walk Y",  Values = GODWALKY,  Default = "0",   Multi = false}):OnChanged(function(v)
        MzD.S.GodWalkY = tonumber(v) or 0
        if MzD._isGod then god_mod.godTeleportUnder() end
    end)
    AT2:AddDropdown("GodFloorY", {Title = "God Floor Y", Values = GODFLOORY, Default = "-10", Multi = false}):OnChanged(function(v)
        MzD.S.GodFloorY = tonumber(v) or -10
        if MzD._isGod then
            local map = MzD.mapFindCurrentMap()
            if map then
                pcall(function() god_mod.godBuildEgaleVloer(map) end)
                local mf = map:FindFirstChild("MzDHubWalls") if mf then pcall(function() mf:Destroy() end) end
                local sx, ex = MzD.mapDetectXRange(map, MzD.mapFindShared(map.Name))
                pcall(function() MzD.mapBuildWalls(map, sx, ex) end)
            end
            pcall(function() god_mod.godTeleportUnder() end)
        end
    end)

    local GDTG = AT2:AddToggle("GodToggle", {Title = "God Mode", Default = false})
    GDTG:OnChanged(function(v) if v then MzD.enableGod() else MzD.disableGod() end end)

    AT2:AddButton({Title = "Teleport Onder", Callback = function() if MzD._isGod then god_mod.godTeleportUnder() end end})

    AT2:AddToggle("InstantToggle", {Title = "Instant Pickup", Default = true}):OnChanged(function(v)
        MzD.S.InstantPickup = v if v then MzD.setupInstant() end
    end)

    local AFKTG = AT2:AddToggle("AFKToggle", {Title = "Anti-AFK", Default = false})
    AFKTG:OnChanged(function(v) if v then MzD.startAFK() else MzD.stopAFK() end end)

    -- ========== CONFIG TAB ==========
    local CT = W:AddTab({Title = "Config", Icon = "settings"})

    CT:AddDropdown("TweenSpeed",    {Title = "Farm Speed",     Values = SPD,    Default = "INSTANT", Multi = false}):OnChanged(function(v) MzD.S.TweenSpeed = SPM[v] or 9999 end)
    CT:AddDropdown("CorridorSpeed", {Title = "Corridor Speed", Values = CSPD,   Default = "1500",    Multi = false}):OnChanged(function(v) MzD.S.CorridorSpeed = tonumber(v) or 1500 end)
    CT:AddDropdown("WallTheme",     {Title = "Thema",          Values = THEMES, Default = "Auto",    Multi = false}):OnChanged(function(v)
        MzD.S.WallTheme = v MzD._lastFixedMapName = ""
        pcall(function() MzD.mapRunFix() end)
        if MzD._isGod then MzD.disableGod() twait(0.3) MzD.enableGod() end
    end)

    CT:AddSlider("GuiScale", {Title = "GUI Schaal %", Default = 100, Min = 50, Max = 150, Rounding = 0}):OnChanged(function(v)
        local scale = mfloor(v / 10 + 0.5) * 10 / 100
        MzD.S.GuiScale = scale
        pcall(function()
            local root = W.Main
            if not root then return end
            local uiScale = root:FindFirstChildOfClass("UIScale")
            if not uiScale then uiScale = Instance.new("UIScale") uiScale.Parent = root end
            uiScale.Scale = scale
        end)
    end)

    CT:AddButton({Title = "Herlaad Brainrots", Callback = function()
        MzD.S.SelectedBrainrots = {}
        pcall(function() BDD:SetValues(MzD.getBrainrotNamesMulti(MzD.S.TargetRarity)) BDD:SetValue({}) end)
    end})
    CT:AddButton({Title = "Zoek Base",       Callback = function() MzD.findBase() end})
    CT:AddButton({Title = "Sla Home Op",     Callback = function() MzD.setHomePosition() end})
    CT:AddButton({Title = "Bezette Slots",   Callback = function()
        MzD.findBase()
        local o = MzD.findOccupiedSlots()
        local info = ""
        for _, s in pairs(o) do info = info.."S"..s.slot..":"..s.name.." L"..s.level.."\n" end
        Fluent:Notify({Title="Slots ("..#o.."/"..MzD.getSlotCount()..")", Content=#o>0 and info or "Leeg", Duration=6})
    end})
    CT:AddButton({Title = "Leeg Farm Slot",  Callback = function() MzD.findBase() MzD.clearSlot(tonumber(MzD.S.FarmSlot) or 5) end})
    CT:AddButton({Title = "Ga Naar Base",    Callback = function() MzD.findBase() MzD.returnToBase() end})
    CT:AddButton({Title = "Debug Info",      Callback = function()
        local info = "God:"..(MzD._isGod and "AAN" or "UIT")
        info = info.." | Walk:"..MzD.S.GodWalkY.." Floor:"..MzD.S.GodFloorY
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then info = info.."\nY:"..sformat("%.1f",hrp.Position.Y) end
        info = info.."\nGUID:"..(MzD.baseGUID or "?").." Slots:"..MzD.getSlotCount()
        info = info.."\nRemote:"..(MzD.PlotAction and "OK" or "MISS")
        info = info.."\nTrial:"..(MzD._towerTrialEnabled and "AAN" or "UIT").." #"..MzD.Status.towerTrialCount
        Fluent:Notify({Title="Debug", Content=info, Duration=8})
    end})

    -- ========== SETTINGS TAB ==========
    local ST2 = W:AddTab({Title = "Settings", Icon = "shield"})
    if SaveManager and InterfaceManager then
        SaveManager:SetLibrary(Fluent)        InterfaceManager:SetLibrary(Fluent)
        SaveManager:SetFolder("MzDHub")       InterfaceManager:SetFolder("MzDHub")
        InterfaceManager:BuildInterfaceSection(ST2)
        SaveManager:BuildConfigSection(ST2)
    end

    M.guiRefs = {
        Fluent = Fluent, W = W,
        FTG = FTG, LBTG = LBTG, TTTG = TTTG,
        FCTG = FCTG, DMTG = DMTG, VTG = VTG,
        ATG = ATG, FFTG = FFTG, MTG = MTG,
        UTG = UTG, MFTG = MFTG, AFKTG = AFKTG,
        GDTG = GDTG,
    }
end

return M
