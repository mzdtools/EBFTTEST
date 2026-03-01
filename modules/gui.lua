-- ============================================
-- [MODULE 27] GUI (FLUENT UI)
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player  = G.Player
    local tinsert = G.tinsert
    local twait   = G.twait
    local sfind   = G.sfind
    local sformat = G.sformat
    local mfloor  = G.mfloor
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

    -- GUI CONSTANTEN
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
        Size        = UDim2.fromOffset(640, 540),
        Acrylic     = true,
        Theme       = "Dark",
        MinimizeKey = Enum.KeyCode.RightControl
    })

    -- ========== FARM TAB ==========
    local FT  = W:AddTab({Title = "Farm", Icon = "leaf"})
    local BDD = nil

    FT:AddParagraph({Title = "🎯 Brainrot Filters", Content = "Kies rarity, naam en mutatie"})

    local RDD = FT:AddDropdown("FarmRarity", {Title = "⭐ Rarity", Values = RAR, Default = {"Common"}, Multi = true})
    RDD:OnChanged(function(v)
        local s = {} for n, on in pairs(v) do if on then tinsert(s, n) end end
        if #s == 0 then s = {"Common"} end
        local any = false for _, r in pairs(s) do if r == "Any" then any = true break end end
        MzD.S.TargetRarity = any and "Any" or s
        MzD.S.SelectedBrainrots = {}
        pcall(function() BDD:SetValues(MzD.getBrainrotNamesMulti(MzD.S.TargetRarity)) BDD:SetValue({}) end)
    end)

    BDD = FT:AddDropdown("FarmBrainrots", {Title = "🧠 Brainrots", Description = "Leeg = alle", Values = MzD.getBrainrotNamesMulti(MzD.S.TargetRarity), Default = {}, Multi = true})
    BDD:OnChanged(function(v)
        local s = {} for n, on in pairs(v) do if on then tinsert(s, n) end end
        MzD.S.SelectedBrainrots = s
    end)

    FT:AddDropdown("FarmMutation", {Title = "💎 Mutatie",   Values = MUT, Default = "None",          Multi = false}):OnChanged(function(v) MzD.S.TargetMutation = v end)
    FT:AddDropdown("FarmMode",     {Title = "⚙️ Mode",      Values = FM,  Default = MzD.S.FarmMode,  Multi = false}):OnChanged(function(v) MzD.S.FarmMode = v end)
    FT:AddDropdown("FarmSlot",     {Title = "📦 Slot",      Values = SL,  Default = MzD.S.FarmSlot,  Multi = false}):OnChanged(function(v) MzD.S.FarmSlot = v end)
    FT:AddSlider("FarmMaxLevel",   {Title = "📈 Max Level", Default = MzD.S.MaxLevel, Min = 1, Max = 500, Rounding = 0}):OnChanged(function(v) MzD.S.MaxLevel = mfloor(v) end)

    local FSP = FT:AddParagraph({Title = "📊 Farm Status", Content = "Idle"})
    local FPP = FT:AddParagraph({Title = "📈 Stats",       Content = "Geplaatst:0 | Geupgrade:0"})
    local FTG = FT:AddToggle("FarmToggle", {Title = "🌾 Auto Farm", Default = false})
    FTG:OnChanged(function(v) if v then MzD.findBase() MzD.startFarming() else MzD.stopFarming() end end)

    -- Lucky Blocks
    FT:AddParagraph({Title = "🎲 Lucky Blocks", Content = ""})
    FT:AddDropdown("LBRarity",   {Title = "⭐ LB Rarity",  Values = LBR, Default = {"Common"}, Multi = true}):OnChanged(function(v)
        local s = {} for n, on in pairs(v) do if on then tinsert(s, n) end end
        if #s == 0 then s = {"Common"} end MzD.S.LuckyBlockRarity = s
    end)
    FT:AddDropdown("LBMutation", {Title = "💎 LB Mutatie", Values = MUT, Default = "Any", Multi = false}):OnChanged(function(v) MzD.S.LuckyBlockMutation = v end)
    local LBSP = FT:AddParagraph({Title = "🎲 LB Status", Content = "Idle"})
    local LBTG = FT:AddToggle("LBToggle", {Title = "🎲 Auto Lucky Blocks", Default = false})
    LBTG:OnChanged(function(v) if v then MzD.findBase() MzD.startLuckyBlockFarm() else MzD.stopLuckyBlockFarm() end end)

    -- Tower Trial Farm
    FT:AddParagraph({Title = "🏆 Tower Trial Farm", Content = "Auto trial activeren, brainrots ophalen\nen depositen tot het klaar is. Wacht cooldown af.\nGebruikt God Mode beweging als dat aan staat."})
    FT:AddDropdown("TowerTrialSlot", {Title = "📦 Werkslot (referentie)", Values = SL, Default = "5", Multi = false}):OnChanged(function(v)
        MzD.S.TowerTrialSlot = v
    end)
    FT:AddSlider("TowerTrialFallbackCd", {Title = "⏱️ Fallback Cooldown (sec)", Default = 305, Min = 60, Max = 600, Rounding = 0}):OnChanged(function(v)
        MzD.S.TowerTrialFallbackCd = mfloor(v)
    end)

    -- Walk Y fine-tune
    FT:AddParagraph({Title = "🚶 Walk Y Fine-tune", Content = "Pas Walk Y aan zonder God Mode uit te zetten"})
    FT:AddButton({Title = "Walk Y  −3", Callback = function()
        MzD.S.GodWalkY = (MzD.S.GodWalkY or 0) - 3
        Fluent:Notify({Title="🚶 Walk Y", Content="Walk Y: "..MzD.S.GodWalkY, Duration=2})
        if MzD._isGod then pcall(function() god_mod.godTeleportUnder() end) end
    end})
    FT:AddButton({Title = "Walk Y  −1", Callback = function()
        MzD.S.GodWalkY = (MzD.S.GodWalkY or 0) - 1
        Fluent:Notify({Title="🚶 Walk Y", Content="Walk Y: "..MzD.S.GodWalkY, Duration=2})
        if MzD._isGod then pcall(function() god_mod.godTeleportUnder() end) end
    end})
    FT:AddButton({Title = "Walk Y  +1", Callback = function()
        MzD.S.GodWalkY = (MzD.S.GodWalkY or 0) + 1
        Fluent:Notify({Title="🚶 Walk Y", Content="Walk Y: "..MzD.S.GodWalkY, Duration=2})
        if MzD._isGod then pcall(function() god_mod.godTeleportUnder() end) end
    end})
    FT:AddButton({Title = "Walk Y  +3", Callback = function()
        MzD.S.GodWalkY = (MzD.S.GodWalkY or 0) + 3
        Fluent:Notify({Title="🚶 Walk Y", Content="Walk Y: "..MzD.S.GodWalkY, Duration=2})
        if MzD._isGod then pcall(function() god_mod.godTeleportUnder() end) end
    end})

    local TTSP = FT:AddParagraph({Title = "🏆 Trial Status", Content = "Idle"})
    local TTTG = FT:AddToggle("TowerTrialToggle", {Title = "🏆 Auto Tower Trial Farm", Default = false})
    TTTG:OnChanged(function(v)
        if v then
            MzD.startTowerTrial()
            MzD.startTrialHUD()
        else
            MzD.stopTowerTrial()
            MzD.stopTrialHUD()
        end
    end)

    -- ========== FACTORY TAB ==========
    local FCT = W:AddTab({Title = "Factory", Icon = "factory"})
    FCT:AddParagraph({Title = "🏭 Factory Info", Content = "Pakt ALLE brainrots van de geselecteerde rarity\nuit je backpack en maakt ze zo snel mogelijk max.\nStel 'Any' in om alle rarities te verwerken."})
    FCT:AddDropdown("FactoryRarity",   {Title = "⭐ Rarity",   Values = RAR, Default = MzD.S.FactoryRarity,   Multi = false}):OnChanged(function(v) MzD.S.FactoryRarity = v end)
    FCT:AddDropdown("FactoryMutation", {Title = "💎 Mutatie",  Values = MUT, Default = MzD.S.FactoryMutation, Multi = false}):OnChanged(function(v) MzD.S.FactoryMutation = v end)
    FCT:AddDropdown("FactorySlot",     {Title = "📦 Werkslot", Values = SL,  Default = MzD.S.FactorySlot,     Multi = false}):OnChanged(function(v) MzD.S.FactorySlot = v end)
    FCT:AddSlider("FactoryMaxLevel",   {Title = "📈 Max Level", Default = MzD.S.FactoryMaxLevel, Min = 1, Max = 500, Rounding = 0}):OnChanged(function(v) MzD.S.FactoryMaxLevel = mfloor(v) end)
    local FCSP = FCT:AddParagraph({Title = "📊 Factory Status", Content = "Idle"})
    local FCTG = FCT:AddToggle("FactoryToggle", {Title = "🏭 Start Factory", Default = false})
    FCTG:OnChanged(function(v)
        if v then MzD.findBase() MzD.startFactoryLoop() else MzD.stopFactoryLoop() end
    end)

    -- ========== EVENTS TAB ==========
    local ET = W:AddTab({Title = "Events", Icon = "party-popper"})

    ET:AddParagraph({Title = "🌋 Doom Event", Content = "Auto doom coins verzamelen"})
    local DMSP = ET:AddParagraph({Title = "🪙 Doom Status", Content = "Uit"})
    local DMTG = ET:AddToggle("DoomToggle", {Title = "🪙 Auto Doom Coins", Default = false})
    DMTG:OnChanged(function(v) if v then MzD.startDoomCollector() else MzD.stopDoomCollector() end end)

    ET:AddParagraph({Title = "💝 Valentine / Candy", Content = "ValentinesCoinParts + CandyEventParts\n100 hearts → submit bij station"})
    local VSP = ET:AddParagraph({Title = "💝 Status", Content = "Idle"})
    local VTG = ET:AddToggle("ValentineToggle", {Title = "💝 Auto Valentine", Default = false})
    VTG:OnChanged(function(v) if v then MzD.startValentine() else MzD.stopValentine() end end)

    ET:AddButton({Title = "💝 Info", Callback = function()
        local coinFolder  = workspace:FindFirstChild("ValentinesCoinParts")
        local candyFolder = workspace:FindFirstChild("CandyEventParts")
        local info = "Hearts: "..MzD.getHeartCount().."/100"
        info = info.."\nCoinParts: "..(coinFolder and #coinFolder:GetChildren() or 0).." (cached: "..#MzD._valentineCachedParts..")"
        info = info.."\nCandyParts: "..(candyFolder and #candyFolder:GetChildren() or 0).." (cached: "..#MzD._candyCachedParts..")"
        local station = MzD.findCandyGramStation()
        info = info.."\nStation: "..(station and station.Name or "NIET GEVONDEN")
        Fluent:Notify({Title="💝 Valentine Info", Content=info, Duration=8})
    end})
    ET:AddButton({Title = "💝 Submit Nu (1x)", Callback = function()
        local ok = MzD.submitCandyGrams()
        Fluent:Notify({Title="💝 Submit", Content=(ok and "Gefired!" or "Mislukt").."\nHearts nu: "..MzD.getHeartCount(), Duration=4})
    end})

    ET:AddParagraph({Title = "🕹️ Arcade Event", Content = ""})
    local ASP = ET:AddParagraph({Title = "🕹️ Status", Content = "Idle"})
    local ATG = ET:AddToggle("ArcadeToggle", {Title = "🕹️ Auto Arcade", Default = false})
    ATG:OnChanged(function(v) if v then MzD.startArcade() else MzD.stopArcade() end end)

    -- NIEUW: Firefice Event
    ET:AddParagraph({Title = "🔥 Firefice Event", Content = "Auto Firefice coins verzamelen"})
    local FFSP = ET:AddParagraph({Title = "🪙 Firefice Status", Content = "Idle"})
    local FFTG = ET:AddToggle("FireficeToggle", {Title = "🔥 Auto Firefice Coins", Default = false})
    FFTG:OnChanged(function(v) if v then MzD.startFireficeCoinFarm() else MzD.stopFireficeCoinFarm() end end)

    -- ========== TOOLS TAB ==========
    local AT2 = W:AddTab({Title = "Tools", Icon = "wrench"})

    AT2:AddParagraph({Title = "💰 Geld", Content = ""})
    local MSP = AT2:AddParagraph({Title = "💰 Money Status", Content = "Idle"})
    local MTG = AT2:AddToggle("MoneyToggle", {Title = "💰 Auto Money", Default = false})
    MTG:OnChanged(function(v) if v then MzD.findBase() MzD.startMoney() else MzD.stopMoney() end end)

    AT2:AddParagraph({Title = "⬆️ Upgraden", Content = ""})
    local USP = AT2:AddParagraph({Title = "⬆️ Upgrade Status", Content = "Idle"})
    local UTG = AT2:AddToggle("UpgradeToggle", {Title = "⬆️ Upgrade All Slots", Default = false})
    UTG:OnChanged(function(v) if v then MzD.findBase() MzD.startAutoUpgrade() else MzD.stopAutoUpgrade() end end)

    AT2:AddParagraph({Title = "🗺️ Map Fixer", Content = ""})
    local MFSP = AT2:AddParagraph({Title = "🗺️ Status", Content = "Uit"})
    local MFTG = AT2:AddToggle("MapToggle", {Title = "🗺️ Map Fixer", Default = false})
    MFTG:OnChanged(function(v) if v then MzD.startMapFixer() else MzD.stopMapFixer() end end)
    AT2:AddButton({Title = "🗺️ Fix Nu", Callback = function()
        MzD._lastFixedMapName = "" pcall(function() MzD.mapRunFix() end)
        Fluent:Notify({Title="🗺️ Map", Content="Fix uitgevoerd!", Duration=3})
    end})
    AT2:AddButton({Title = "🗑️ Verwijder Deco", Callback = function()
        local map = MzD.mapFindCurrentMap()
        if map then
            local n = MzD.removeMapDeco(map)
            Fluent:Notify({Title="🗑️ Deco", Content="Verwijderd: "..map.Name.." ("..n.."x)", Duration=4})
        else Fluent:Notify({Title="🗑️ Deco", Content="Geen map", Duration=3}) end
    end})

    AT2:AddParagraph({Title = "😇 God Mode", Content = ""})
    AT2:AddDropdown("GodWalkY",  {Title = "🚶 Loop Y",  Values = GODWALKY,  Default = "0",   Multi = false}):OnChanged(function(v)
        MzD.S.GodWalkY = tonumber(v) or 0
        if MzD._isGod then god_mod.godTeleportUnder() end
    end)
    AT2:AddDropdown("GodFloorY", {Title = "🟫 Vloer Y", Values = GODFLOORY, Default = "-10", Multi = false}):OnChanged(function(v)
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

    local GDSP = AT2:AddParagraph({Title = "😇 God Status", Content = "Uit"})
    local GDTG = AT2:AddToggle("GodToggle", {Title = "😇 God Mode", Default = false})
    GDTG:OnChanged(function(v) if v then MzD.enableGod() else MzD.disableGod() end end)
    AT2:AddButton({Title = "📍 Teleport Onder", Callback = function() if MzD._isGod then god_mod.godTeleportUnder() end end})

    AT2:AddParagraph({Title = "🔧 Overig", Content = ""})
    AT2:AddToggle("InstantToggle", {Title = "⚡ Instant Pickup", Default = true}):OnChanged(function(v)
        MzD.S.InstantPickup = v if v then MzD.setupInstant() end
    end)
    local AFKSP = AT2:AddParagraph({Title = "🕐 AFK Status", Content = "Uit"})
    local AFKTG = AT2:AddToggle("AFKToggle", {Title = "🕐 Anti-AFK", Default = false})
    AFKTG:OnChanged(function(v) if v then MzD.startAFK() else MzD.stopAFK() end end)

    -- ========== CONFIG TAB ==========
    local CT = W:AddTab({Title = "Config", Icon = "settings"})

    CT:AddDropdown("TweenSpeed",    {Title = "🏃 Farm Speed",     Values = SPD,    Default = "INSTANT", Multi = false}):OnChanged(function(v) MzD.S.TweenSpeed    = SPM[v] or 9999 end)
    CT:AddDropdown("CorridorSpeed", {Title = "🛤️ Corridor Speed", Values = CSPD,   Default = "1500",    Multi = false}):OnChanged(function(v) MzD.S.CorridorSpeed = tonumber(v) or 1500 end)
    CT:AddDropdown("WallTheme",     {Title = "🎨 Thema",          Values = THEMES, Default = "Auto",    Multi = false}):OnChanged(function(v)
        MzD.S.WallTheme = v MzD._lastFixedMapName = ""
        pcall(function() MzD.mapRunFix() end)
        if MzD._isGod then MzD.disableGod() twait(0.3) MzD.enableGod() end
    end)

    -- GUI Scale via W.Main (Fluent's eigen window frame, altijd beschikbaar)
    CT:AddParagraph({Title = "🔎 GUI Schaal", Content = "50%–150% in stappen van 10%"})
    CT:AddSlider("GuiScale", {Title = "🔎 Schaal %", Default = 100, Min = 50, Max = 150, Rounding = 0}):OnChanged(function(v)
        local scale = mfloor(v / 10 + 0.5) * 10 / 100
        MzD.S.GuiScale = scale
        pcall(function()
            local root = W.Main
            if not root then return end
            local uiScale = root:FindFirstChildOfClass("UIScale")
            if not uiScale then
                uiScale = Instance.new("UIScale")
                uiScale.Parent = root
            end
            uiScale.Scale = scale
        end)
    end)

    CT:AddButton({Title = "🔄 Herlaad Brainrots", Callback = function()
        MzD.S.SelectedBrainrots = {}
        pcall(function() BDD:SetValues(MzD.getBrainrotNamesMulti(MzD.S.TargetRarity)) BDD:SetValue({}) end)
        Fluent:Notify({Title="✅ Herlaad", Content="Brainrot lijst vernieuwd", Duration=3})
    end})
    CT:AddButton({Title = "🔍 Zoek Base", Callback = function()
        MzD.findBase()
        Fluent:Notify({Title="🏠 Base", Content="GUID: "..(MzD.baseGUID or "?").."\nSlots: "..MzD.getSlotCount(), Duration=5})
    end})
    CT:AddButton({Title = "📍 Sla Home Op", Callback = function()
        MzD.setHomePosition()
        Fluent:Notify({Title="📍 Home", Content="Opgeslagen!", Duration=3})
    end})
    CT:AddButton({Title = "📋 Bezette Slots", Callback = function()
        MzD.findBase()
        local o = MzD.findOccupiedSlots()
        local info = ""
        for _, s in pairs(o) do info = info.."S"..s.slot..":"..s.name.." L"..s.level.."\n" end
        Fluent:Notify({Title="📦 Slots ("..#o.."/"..MzD.getSlotCount()..")", Content=#o>0 and info or "Leeg!", Duration=8})
    end})
    CT:AddButton({Title = "🗑️ Leeg Farm Slot", Callback = function()
        MzD.findBase() MzD.clearSlot(tonumber(MzD.S.FarmSlot) or 5)
        Fluent:Notify({Title="🗑️ Slot", Content="Slot "..MzD.S.FarmSlot.." geleegd", Duration=3})
    end})
    CT:AddButton({Title = "🏠 Ga Naar Base", Callback = function() MzD.findBase() MzD.returnToBase() end})
    CT:AddButton({Title = "📡 Debug Info",   Callback = function()
        local info = "God:"..(MzD._isGod and "AAN" or "UIT")
        info = info.."\nWalk:"..MzD.S.GodWalkY.." Floor:"..MzD.S.GodFloorY
        info = info.."\nDoom:"..(MzD.S.DoomEnabled and "AAN" or "UIT").." Parts:"..#MzD._doomCachedParts
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then info = info.."\nPlayer Y:"..sformat("%.1f",hrp.Position.Y) end
        info = info.."\nGUID:"..(MzD.baseGUID or "?").."\nSlots:"..MzD.getSlotCount()
        info = info.."\nRemote:"..(MzD.PlotAction and "OK" or "NIET GEVONDEN!")
        info = info.."\nCandy:"..#MzD._candyCachedParts
        info = info.."\nTrial:"..(MzD._towerTrialEnabled and "AAN" or "UIT").." #"..MzD.Status.towerTrialCount
        info = info.."\nScale:"..mfloor(MzD.S.GuiScale*100).."%"
        Fluent:Notify({Title="📡 Debug v13.0", Content=info, Duration=12})
    end})

    local IP = CT:AddParagraph({Title = "ℹ️ Info", Content = "..."})

    -- ========== SETTINGS TAB ==========
    local ST2 = W:AddTab({Title = "Settings", Icon = "shield"})
    if SaveManager and InterfaceManager then
        SaveManager:SetLibrary(Fluent)        InterfaceManager:SetLibrary(Fluent)
        SaveManager:SetFolder("MzDHub")       InterfaceManager:SetFolder("MzDHub")
        InterfaceManager:BuildInterfaceSection(ST2)
        SaveManager:BuildConfigSection(ST2)
    end

    -- Store references for status update loop
    M.guiRefs = {
        Fluent = Fluent, W = W,
        FSP = FSP, FPP = FPP, FTG = FTG,
        LBSP = LBSP, LBTG = LBTG,
        TTSP = TTSP, TTTG = TTTG,
        FCSP = FCSP, FCTG = FCTG,
        DMSP = DMSP, DMTG = DMTG,
        VSP = VSP, VTG = VTG,
        ASP = ASP, ATG = ATG,
        FFSP = FFSP, FFTG = FFTG, -- <-- Hier toegevoegd!
        MSP = MSP, MTG = MTG,
        USP = USP, UTG = UTG,
        MFSP = MFSP, MFTG = MFTG,
        AFKSP = AFKSP, AFKTG = AFKTG,
        GDSP = GDSP, GDTG = GDTG,
        IP = IP,
    }
end

return M
