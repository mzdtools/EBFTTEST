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
    local TS      = game:GetService("TweenService")

    twait(0.5)

    -- ═══════ CLEANUP OLD INSTANCES ═══════
    local function destroyOldGui(parent)
        pcall(function()
            for _, gui in pairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    if gui.Name == "MzDHubToggle" then
                        gui:Destroy()
                    else
                        for _, d in pairs(gui:GetDescendants()) do
                            if d:IsA("TextLabel") and d.Text == "MzD Hub" then
                                gui:Destroy()
                                break
                            end
                        end
                    end
                end
            end
        end)
    end
    destroyOldGui(Player.PlayerGui)
    pcall(function() destroyOldGui(game:GetService("CoreGui")) end)
    pcall(function() if typeof(gethui) == "function" then destroyOldGui(gethui()) end end)
    twait(0.3)

    -- ═══════ SNAPSHOT BESTAANDE GUIS ═══════
    local preExisting = {}
    local function snapshot(parent)
        pcall(function()
            for _, g in pairs(parent:GetChildren()) do preExisting[g] = true end
        end)
    end
    snapshot(Player.PlayerGui)
    pcall(function() snapshot(game:GetService("CoreGui")) end)
    pcall(function() if typeof(gethui) == "function" then snapshot(gethui()) end end)

    -- ═══════ LOAD FLUENT ═══════
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

    -- ═══════ CONSTANTS ═══════
    local RAR  = MzD.getAvailableRarities()
    local MUT  = MzD.getAvailableMutations()
    local FM   = {"Collect", "Collect, Place & Max"}
    local LBR  = {"Any","Common","Uncommon","Rare","Epic","Legendary","Mythical","Cosmic","Secret","Celestial","Divine","Infinity","Admin","UFO","Candy","Money"}
    local SL   = {} for i = 1, 40 do tinsert(SL, tostring(i)) end
    local GODWALKY  = {"5","3","1","0","-1","-2","-3","-5","-8","-10","-15"}
    local GODFLOORY = {"15","12","10","8","5","3","0","-3","-5","-8","-10","-15","-20"}

    -- ═══════ FLUENT WINDOW ═══════
    local W = Fluent:CreateWindow({
        Title       = "MzD Hub",
        SubTitle    = "v13.0 Clean",
        TabWidth    = 160,
        Size        = UDim2.fromOffset(640, 540),
        Acrylic     = true,
        Theme       = "Dark",
        MinimizeKey = Enum.KeyCode.Unknown
    })

    twait(1.5)

    -- ═══════ VIND FLUENT SCREENGUI (ROBUUST) ═══════
    local fluentGui = nil
    local fluentChildren = {}

    local function searchNew(parent)
        if fluentGui then return end
        pcall(function()
            for _, gui in pairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name ~= "MzDHubToggle" and not preExisting[gui] then
                    fluentGui = gui
                    return
                end
            end
        end)
    end

    local function searchContent(parent)
        if fluentGui then return end
        pcall(function()
            for _, gui in pairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name ~= "MzDHubToggle" then
                    for _, d in pairs(gui:GetDescendants()) do
                        if d:IsA("TextLabel") and (d.Text == "MzD Hub" or d.Text == "v13.0 Clean") then
                            fluentGui = gui
                            return
                        end
                    end
                end
                if fluentGui then return end
            end
        end)
    end

    searchNew(Player.PlayerGui)
    pcall(function() searchNew(game:GetService("CoreGui")) end)
    pcall(function() if typeof(gethui) == "function" then searchNew(gethui()) end end)
    if not fluentGui then
        searchContent(Player.PlayerGui)
        pcall(function() searchContent(game:GetService("CoreGui")) end)
        pcall(function() if typeof(gethui) == "function" then searchContent(gethui()) end end)
    end

    if fluentGui then
        pcall(function()
            for _, child in pairs(fluentGui:GetChildren()) do
                tinsert(fluentChildren, child)
            end
        end)
    end

    -- ═══════ TOGGLE LOGICA ═══════
    local guiVisible = true

    local function setFluentVisible(vis)
        guiVisible = vis
        if fluentGui then
            pcall(function() fluentGui.Enabled = vis end)
        end
        for _, child in pairs(fluentChildren) do
            pcall(function()
                if child:IsA("GuiObject") or child:IsA("CanvasGroup") then
                    child.Visible = vis
                end
            end)
        end
    end

    -- ═══════ TOGGLE BUTTON — FUTURISTISCH VIERKANT ═══════
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name           = "MzDHubToggle"
    toggleGui.ResetOnSpawn   = false
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    toggleGui.DisplayOrder   = 999999
    if not pcall(function() toggleGui.Parent = Player.PlayerGui end) or not toggleGui.Parent then
        pcall(function() toggleGui.Parent = game:GetService("CoreGui") end)
    end

    -- Container (wordt gesleept)
    local container = Instance.new("Frame")
    container.Name               = "MzDContainer"
    container.Size               = UDim2.fromOffset(64, 64)
    container.Position           = UDim2.new(0.6, 0, 0.025, 0)
    container.AnchorPoint        = Vector2.new(0.5, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel    = 0
    container.ZIndex             = 995
    container.Parent             = toggleGui

    -- Hoofd knop — donker met blauwe gradient
    local btn = Instance.new("TextButton")
    btn.Name             = "MzDBtn"
    btn.Size             = UDim2.fromScale(1, 1)
    btn.Position         = UDim2.fromScale(0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
    btn.Text             = ""
    btn.AutoButtonColor  = false
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 998
    btn.Parent           = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0.18, 0)

    -- Gradient achtergrond
    local btnGrad = Instance.new("UIGradient")
    btnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(14, 20, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8,  12, 24)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(5,   5, 10)),
    })
    btnGrad.Rotation = 145
    btnGrad.Parent   = btn

    -- Neon cyan border
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color        = Color3.fromRGB(0, 220, 255)
    btnStroke.Thickness    = 1.5
    btnStroke.Transparency = 0.15
    btnStroke.Parent       = btn

    -- Accent streepje bovenaan
    local accentLine = Instance.new("Frame")
    accentLine.Size                   = UDim2.new(0.6, 0, 0, 2)
    accentLine.Position               = UDim2.new(0.2, 0, 0, 0)
    accentLine.BackgroundColor3       = Color3.fromRGB(0, 220, 255)
    accentLine.BackgroundTransparency = 0
    accentLine.BorderSizePixel        = 0
    accentLine.ZIndex                 = 999
    accentLine.Parent                 = btn
    local accentGrad = Instance.new("UIGradient")
    accentGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 180, 220)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 240, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 180, 220)),
    })
    accentGrad.Rotation = 0
    accentGrad.Parent   = accentLine

    -- "MzD" tekst
    local label = Instance.new("TextLabel")
    label.Size                   = UDim2.new(1, 0, 0.52, 0)
    label.Position               = UDim2.new(0, 0, 0.08, 0)
    label.BackgroundTransparency = 1
    label.Text                   = "MzD"
    label.TextColor3             = Color3.fromRGB(210, 240, 255)
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = 18
    label.ZIndex                 = 1000
    label.Parent                 = btn

    -- "HUB" tekst
    local labelHub = Instance.new("TextLabel")
    labelHub.Size                   = UDim2.new(1, 0, 0.28, 0)
    labelHub.Position               = UDim2.new(0, 0, 0.62, 0)
    labelHub.BackgroundTransparency = 1
    labelHub.Text                   = "HUB"
    labelHub.TextColor3             = Color3.fromRGB(0, 200, 240)
    labelHub.Font                   = Enum.Font.Code
    labelHub.TextSize               = 11
    labelHub.ZIndex                 = 1000
    labelHub.Parent                 = btn

    -- Status dot (groen = open, rood = dicht)
    local dot = Instance.new("Frame")
    dot.Size             = UDim2.fromOffset(7, 7)
    dot.Position         = UDim2.new(1, -10, 0, 5)
    dot.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
    dot.BorderSizePixel  = 0
    dot.ZIndex           = 1001
    dot.Parent           = btn
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    -- ═══════ VISUELE FEEDBACK ═══════
    local function updateIconLook()
        if guiVisible then
            btnStroke.Color      = Color3.fromRGB(0, 220, 255)
            btnStroke.Transparency = 0.15
            label.TextColor3     = Color3.fromRGB(210, 240, 255)
            labelHub.TextColor3  = Color3.fromRGB(0, 200, 240)
            dot.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
            accentLine.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
        else
            btnStroke.Color      = Color3.fromRGB(255, 60, 60)
            btnStroke.Transparency = 0
            label.TextColor3     = Color3.fromRGB(255, 140, 140)
            labelHub.TextColor3  = Color3.fromRGB(255, 80, 80)
            dot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
            accentLine.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        end
    end

    -- ═══════ HOVER EFFECT ═══════
    btn.MouseEnter:Connect(function()
        btnStroke.Thickness    = 2
        btnStroke.Transparency = 0
    end)
    btn.MouseLeave:Connect(function()
        btnStroke.Thickness    = 1.5
        btnStroke.Transparency = guiVisible and 0.15 or 0
    end)

    -- ═══════ DRAG + KLIK LOGICA (van Opus) ═══════
    local dragging  = false
    local dragStart = Vector3.zero
    local startPos  = UDim2.new()
    local totalDrag = 0

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = container.Position
            totalDrag = 0
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            totalDrag = delta.Magnitude
            container.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if totalDrag < 8 then
                setFluentVisible(not guiVisible)
                updateIconLook()
                -- Subtiele klik animatie (geen pulse, gewoon even indrukken)
                task.spawn(function()
                    pcall(function()
                        TS:Create(btn, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Size = UDim2.fromScale(0.92, 0.92),
                            Position = UDim2.fromScale(0.04, 0.04)
                        }):Play()
                        twait(0.07)
                        TS:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            Size = UDim2.fromScale(1, 1),
                            Position = UDim2.fromScale(0, 0)
                        }):Play()
                    end)
                end)
            end
        end
    end)

    -- ═══════ DUMMY PARAGRAPHS ═══════
    local dP = { SetTitle = function() end, SetDesc = function() end }
    local FSP, FPP, LBSP, TTSP, FCSP, DMSP, VSP, ASP, FISP, MSP, USP, MFSP, GDSP, AFKSP, IP = dP, dP, dP, dP, dP, dP, dP, dP, dP, dP, dP, dP, dP, dP, dP

    -- ========== FARM TAB ==========
    local FT = W:AddTab({Title = "Farm", Icon = "leaf"})

    local TTTG = FT:AddToggle("TowerTrialToggle", {Title = "🏆 Auto Tower Trial Farm", Default = false})
    TTTG:OnChanged(function(v)
        if v then MzD.startTowerTrial() MzD.startTrialHUD()
        else MzD.stopTowerTrial() MzD.stopTrialHUD() end
    end)

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

    FT:AddDropdown("FarmMutation", {Title = "💎 Mutatie",  Values = MUT, Default = "None",         Multi = false}):OnChanged(function(v) MzD.S.TargetMutation = v end)
    FT:AddDropdown("FarmMode",     {Title = "⚙️ Mode",     Values = FM,  Default = MzD.S.FarmMode, Multi = false}):OnChanged(function(v) MzD.S.FarmMode = v end)
    FT:AddDropdown("FarmSlot",     {Title = "📦 Slot",     Values = SL,  Default = MzD.S.FarmSlot, Multi = false}):OnChanged(function(v) MzD.S.FarmSlot = v end)
    FT:AddSlider("FarmMaxLevel",   {Title = "📈 Max Level", Default = MzD.S.MaxLevel, Min = 1, Max = 500, Rounding = 0}):OnChanged(function(v) MzD.S.MaxLevel = mfloor(v) end)

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
    FCTG:OnChanged(function(v) if v then MzD.findBase() MzD.startFactoryLoop() else MzD.stopFactoryLoop() end end)
    FCT:AddDropdown("FactoryRarity",   {Title = "⭐ Rarity",   Values = RAR, Default = MzD.S.FactoryRarity,   Multi = false}):OnChanged(function(v) MzD.S.FactoryRarity = v end)
    FCT:AddDropdown("FactoryMutation", {Title = "💎 Mutatie",  Values = MUT, Default = MzD.S.FactoryMutation, Multi = false}):OnChanged(function(v) MzD.S.FactoryMutation = v end)
    FCT:AddDropdown("FactorySlot",     {Title = "📦 Werkslot", Values = SL,  Default = MzD.S.FactorySlot,     Multi = false}):OnChanged(function(v) MzD.S.FactorySlot = v end)
    FCT:AddSlider("FactoryMaxLevel",   {Title = "📈 Max Level", Default = MzD.S.FactoryMaxLevel, Min = 1, Max = 500, Rounding = 0}):OnChanged(function(v) MzD.S.FactoryMaxLevel = mfloor(v) end)

    -- ========== EVENTS TAB ==========
    local ET = W:AddTab({Title = "Events", Icon = "party-popper"})
    local DMTG = ET:AddToggle("DoomToggle",     {Title = "🌋 Collect Auto Doom Coins",          Default = true})
    DMTG:OnChanged(function(v) if v then MzD.startDoomCollector() else MzD.stopDoomCollector() end end)
    local VTG  = ET:AddToggle("ValentineToggle", {Title = "💝 Auto Collect Hearts and Candy",    Default = true})
    VTG:OnChanged(function(v)  if v then MzD.startValentine()     else MzD.stopValentine()     end end)
    local ATG  = ET:AddToggle("ArcadeToggle",    {Title = "🕹️ Auto collect controllers & coins", Default = true})
    ATG:OnChanged(function(v)  if v then MzD.startArcade()        else MzD.stopArcade()        end end)
    local FITG = ET:AddToggle("FireiceToggle",   {Title = "🔥 Auto Fire & Ice Coins",            Default = true})
    FITG:OnChanged(function(v) if v then MzD.startFireice()       else MzD.stopFireice()       end end)

    -- ========== TOOLS TAB ==========
    local AT2 = W:AddTab({Title = "Tools", Icon = "wrench"})
    local MTG  = AT2:AddToggle("MoneyToggle",   {Title = "💰 Auto Money",             Default = false})
    MTG:OnChanged(function(v)  if v then MzD.findBase() MzD.startMoney()       else MzD.stopMoney()       end end)
    local UTG  = AT2:AddToggle("UpgradeToggle", {Title = "⬆️ Auto Upgrade All Slots", Default = false})
    UTG:OnChanged(function(v)  if v then MzD.findBase() MzD.startAutoUpgrade() else MzD.stopAutoUpgrade() end end)
    local MFTG = AT2:AddToggle("MapToggle",     {Title = "🗺️ Auto Map Fixer",         Default = false})
    MFTG:OnChanged(function(v) if v then MzD.startMapFixer()                   else MzD.stopMapFixer()    end end)
    local GDTG = AT2:AddToggle("GodToggle",     {Title = "😇 God Mode",               Default = false})
    GDTG:OnChanged(function(v) if v then MzD.enableGod()                       else MzD.disableGod()      end end)

    AT2:AddDropdown("GodWalkY",  {Title = "🚶 Loop Y Offset", Values = GODWALKY,  Default = "0",   Multi = false}):OnChanged(function(v)
        MzD.S.GodWalkY = tonumber(v) or 0
        if MzD._isGod then god_mod.godTeleportUnder() end
    end)
    AT2:AddDropdown("GodFloorY", {Title = "🟫 Vloer Y",       Values = GODFLOORY, Default = "-10", Multi = false}):OnChanged(function(v)
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

    -- ═══════ STORE REFS ═══════
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
