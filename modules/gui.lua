-- ============================================
-- [MODULE 27] GUI (FLUENT UI) - SUPER CLEAN
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
    local UIS     = game:GetService("UserInputService")

    twait(0.5)
    pcall(function()
        for _, gui in pairs(Player.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                if gui.Name == "MzDHubToggle" then gui:Destroy() end
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
    local GODWALKY  = {"5","3","1","0","-1","-2","-3","-5","-8","-10","-15"}
    local GODFLOORY = {"15","12","10","8","5","3","0","-3","-5","-8","-10","-15","-20"}

    local W = Fluent:CreateWindow({
        Title       = "MzD Hub",
        SubTitle    = "v13.0 Clean",
        TabWidth    = 160,
        Size        = UDim2.fromOffset(640, 540),
        Acrylic     = true,
        Theme       = "Dark",
        MinimizeKey = Enum.KeyCode.RightControl
    })

    -- ==========================================
    -- DRAGGABLE TOGGLE ICON (MuMu / Mobile safe)
    -- ==========================================
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "MzDHubToggle"
    toggleGui.ResetOnSpawn = false
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    toggleGui.DisplayOrder = 999999
    toggleGui.Parent = Player.PlayerGui

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "MzDIcon"
    toggleBtn.Size = UDim2.fromOffset(48, 48)
    toggleBtn.Position = UDim2.new(0, 12, 0.5, -24)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    toggleBtn.BackgroundTransparency = 0.1
    toggleBtn.Text = "MzD"
    toggleBtn.TextColor3 = Color3.fromRGB(180, 140, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13
    toggleBtn.AutoButtonColor = false
    toggleBtn.BorderSizePixel = 0
    toggleBtn.ZIndex = 999
    toggleBtn.Parent = toggleGui

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = toggleBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(120, 80, 220)
    btnStroke.Thickness = 2
    btnStroke.Transparency = 0.2
    btnStroke.Parent = toggleBtn

    -- Shadow ring
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.fromOffset(56, 56)
    shadow.Position = UDim2.fromScale(0.5, 0.5)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 998
    shadow.Parent = toggleBtn
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(1, 0)
    shadowCorner.Parent = shadow

    -- Find Fluent ScreenGui reference
    twait(0.3)
    local fluentGui = nil
    pcall(function()
        for _, gui in pairs(Player.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui ~= toggleGui then
                for _, d in pairs(gui:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text == "MzD Hub" then
                        fluentGui = gui
                        break
                    end
                end
            end
            if fluentGui then break end
        end
    end)

    -- Drag logic
    local dragging  = false
    local dragStart = Vector3.new()
    local startPos  = UDim2.new()
    local dragDelta = 0

    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = toggleBtn.Position
            dragDelta = 0
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            dragDelta = delta.Magnitude
            toggleBtn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            dragging = false
            if dragDelta < 6 then
                -- TAP / CLICK → toggle the Fluent window
                if not fluentGui then
                    pcall(function()
                        for _, gui in pairs(Player.PlayerGui:GetChildren()) do
                            if gui:IsA("ScreenGui") and gui ~= toggleGui then
                                for _, d in pairs(gui:GetDescendants()) do
                                    if d:IsA("TextLabel") and d.Text == "MzD Hub" then
                                        fluentGui = gui break
                                    end
                                end
                            end
                            if fluentGui then break end
                        end
                    end)
                end
                if fluentGui then
                    fluentGui.Enabled = not fluentGui.Enabled
                    if fluentGui.Enabled then
                        toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
                        btnStroke.Color = Color3.fromRGB(120, 80, 220)
                        toggleBtn.TextColor3 = Color3.fromRGB(180, 140, 255)
                    else
                        toggleBtn.BackgroundColor3 = Color3.fromRGB(55, 20, 20)
                        btnStroke.Color = Color3.fromRGB(200, 60, 60)
                        toggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
                    end
                end
            end
        end
    end)

    -- Onzichtbare dummy objecten om te voorkomen dat status_loop.lua crasht
    local dP = { SetTitle = function() end, SetDesc = function() end }
    local FSP, FPP, LBSP, TTSP, FCSP, DMSP, VSP, ASP, FISP, MSP, USP, MFSP, GDSP, AFKSP, IP = dP, dP, dP, dP, dP, dP, dP, dP, dP, dP, dP, dP, dP, dP, dP

    -- ========== FARM TAB ==========
    local FT  = W:AddTab({Title = "Farm", Icon = "leaf"})

    -- Tower Trial Farm (Bovenaan)
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

    -- Auto Farm
    local BDD = nil
    local FTG = FT:AddToggle("FarmToggle", {Title = "🌾 Auto Farm", Default = true})
    FTG:OnChanged(function(v) if v then MzD.findBase() MzD.startFarming() else MzD.stopFarming() end end)

    local RDD = FT:AddDropdown("FarmRarity", {Title = "⭐ Rarity", Values = RAR, Default = {"Divine", "Infinity"}, Multi = true})
    RDD:OnChanged(function(v)
        local s = {} for n, on in pairs(v) do if on then tinsert(s, n) end end
        if #s == 0 then s = {"Common"} end
        local any = false for _, r in pairs(s) do if r == "Any" then any = true break end end
        MzD.S.TargetRarity = any and "Any" or s
        MzD.S.SelectedBrainrots = {}
        pcall(function() BDD:SetValues(MzD.getBrainrotNamesMulti(MzD.S.TargetRarity)) BDD:SetValue({}) end)
    end)

    BDD = FT:AddDropdown("FarmBrainrots", {Title = "🧠 Brainrots (Leeg = alle)", Values = MzD.getBrainrotNamesMulti(MzD.S.TargetRarity), Default = {}, Multi = true})
    BDD:OnChanged(function(v)
        local s = {} for n, on in pairs(v) do if on then tinsert(s, n) end end
        MzD.S.SelectedBrainrots = s
    end)

    FT:AddDropdown("FarmMutation", {Title = "💎 Mutatie",   Values = MUT, Default = "None",          Multi = false}):OnChanged(function(v) MzD.S.TargetMutation = v end)
    FT:AddDropdown("FarmMode",     {Title = "⚙️ Mode",      Values = FM,  Default = MzD.S.FarmMode,  Multi = false}):OnChanged(function(v) MzD.S.FarmMode = v end)
    FT:AddDropdown("FarmSlot",     {Title = "📦 Slot",      Values = SL,  Default = MzD.S.FarmSlot,  Multi = false}):OnChanged(function(v) MzD.S.FarmSlot = v end)
    FT:AddSlider("FarmMaxLevel",   {Title = "📈 Max Level", Default = MzD.S.MaxLevel, Min = 1, Max = 500, Rounding = 0}):OnChanged(function(v) MzD.S.MaxLevel = mfloor(v) end)

    -- Lucky Blocks
    local LBTG = FT:AddToggle("LBToggle", {Title = "🎲 Auto Lucky Blocks", Default = true})
    LBTG:OnChanged(function(v) if v then MzD.findBase() MzD.startLuckyBlockFarm() else MzD.stopLuckyBlockFarm() end end)
    FT:AddDropdown("LBRarity",   {Title = "⭐ LB Rarity",  Values = LBR, Default = {"Divine", "Infinity", "Admin"}, Multi = true}):OnChanged(function(v)
        local s = {} for n, on in pairs(v) do if on then tinsert(s, n) end end
        if #s == 0 then s = {"Common"} end MzD.S.LuckyBlockRarity = s
    end)
    FT:AddDropdown("LBMutation", {Title = "💎 LB Mutatie", Values = MUT, Default = "Any", Multi = false}):OnChanged(function(v) MzD.S.LuckyBlockMutation = v end)

    -- ========== FACTORY TAB ==========
    local FCT = W:AddTab({Title = "Factory", Icon = "factory"})

    local FCTG = FCT:AddToggle("FactoryToggle", {Title = "🏭 Start Factory", Default = false})
    FCTG:OnChanged(function(v)
        if v then MzD.findBase() MzD.startFactoryLoop() else MzD.stopFactoryLoop() end
    end)
    FCT:AddDropdown("FactoryRarity",   {Title = "⭐ Rarity",   Values = RAR, Default = MzD.S.FactoryRarity,   Multi = false}):OnChanged(function(v) MzD.S.FactoryRarity = v end)
    FCT:AddDropdown("FactoryMutation", {Title = "💎 Mutatie",  Values = MUT, Default = MzD.S.FactoryMutation, Multi = false}):OnChanged(function(v) MzD.S.FactoryMutation = v end)
    FCT:AddDropdown("FactorySlot",     {Title = "📦 Werkslot", Values = SL,  Default = MzD.S.FactorySlot,     Multi = false}):OnChanged(function(v) MzD.S.FactorySlot = v end)
    FCT:AddSlider("FactoryMaxLevel",   {Title = "📈 Max Level", Default = MzD.S.FactoryMaxLevel, Min = 1, Max = 500, Rounding = 0}):OnChanged(function(v) MzD.S.FactoryMaxLevel = mfloor(v) end)

    -- ========== EVENTS TAB ==========
    local ET = W:AddTab({Title = "Events", Icon = "party-popper"})

    local DMTG = ET:AddToggle("DoomToggle", {Title = "🌋 Collect Auto Doom Coins", Default = true})
    DMTG:OnChanged(function(v) if v then MzD.startDoomCollector() else MzD.stopDoomCollector() end end)

    local VTG = ET:AddToggle("ValentineToggle", {Title = "💝 Auto Collect Hearts and Candy", Default = true})
    VTG:OnChanged(function(v) if v then MzD.startValentine() else MzD.stopValentine() end end)

    local ATG = ET:AddToggle("ArcadeToggle", {Title = "🕹️ Auto collect controllers & coins", Default = true})
    ATG:OnChanged(function(v) if v then MzD.startArcade() else MzD.stopArcade() end end)

    local FITG = ET:AddToggle("FireiceToggle", {Title = "🔥 Auto Fire & Ice Coins", Default = true})
    FITG:OnChanged(function(v) if v then MzD.startFireice() else MzD.stopFireice() end end)

    -- ========== TOOLS TAB ==========
    local AT2 = W:AddTab({Title = "Tools", Icon = "wrench"})

    local MTG = AT2:AddToggle("MoneyToggle", {Title = "💰 Auto Money", Default = false})
    MTG:OnChanged(function(v) if v then MzD.findBase() MzD.startMoney() else MzD.stopMoney() end end)

    local UTG = AT2:AddToggle("UpgradeToggle", {Title = "⬆️ Auto Upgrade All Slots", Default = false})
    UTG:OnChanged(function(v) if v then MzD.findBase() MzD.startAutoUpgrade() else MzD.stopAutoUpgrade() end end)

    local MFTG = AT2:AddToggle("MapToggle", {Title = "🗺️ Auto Map Fixer", Default = false})
    MFTG:OnChanged(function(v) if v then MzD.startMapFixer() else MzD.stopMapFixer() end end)

    local GDTG = AT2:AddToggle("GodToggle", {Title = "😇 God Mode", Default = false})
    GDTG:OnChanged(function(v) if v then MzD.enableGod() else MzD.disableGod() end end)

    AT2:AddDropdown("GodWalkY",  {Title = "🚶 Loop Y Offset",  Values = GODWALKY,  Default = "0",   Multi = false}):OnChanged(function(v)
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

    AT2:AddToggle("InstantToggle", {Title = "⚡ Instant Pickup", Default = true}):OnChanged(function(v)
        MzD.S.InstantPickup = v if v then MzD.setupInstant() end
    end)

    local AFKTG = AT2:AddToggle("AFKToggle", {Title = "🕐 Anti-AFK", Default = true})
    AFKTG:OnChanged(function(v) if v then MzD.startAFK() else MzD.stopAFK() end end)

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
        FISP = FISP, FITG = FITG,
        MSP = MSP, MTG = MTG,
        USP = USP, UTG = UTG,
        MFSP = MFSP, MFTG = MFTG,
        AFKSP = AFKSP, AFKTG = AFKTG,
        GDSP = GDSP, GDTG = GDTG,
        IP = IP,
    }
end

return M
