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

    -- ============================================
    -- STAP 1: ICOON DIRECT AANMAKEN
    -- ============================================
    pcall(function()
        local old = Player.PlayerGui:FindFirstChild("MzDIconToggle")
        if old then old:Destroy() end
    end)

    local _iconGui = Instance.new("ScreenGui")
    _iconGui.Name           = "MzDIconToggle"
    _iconGui.ResetOnSpawn   = false
    _iconGui.DisplayOrder   = 999
    _iconGui.IgnoreGuiInset = true
    _iconGui.Parent         = Player.PlayerGui

    local ICON_X = 0.62
    local ICON_Y = 0.02

    local _shadow = Instance.new("Frame")
    _shadow.Size                   = UDim2.new(0, 68, 0, 68)
    _shadow.Position               = UDim2.new(ICON_X, -3, ICON_Y, -3)
    _shadow.BackgroundColor3       = Color3.fromRGB(99, 102, 241)
    _shadow.BackgroundTransparency = 0.6
    _shadow.BorderSizePixel        = 0
    _shadow.ZIndex                 = 9
    _shadow.Parent                 = _iconGui
    Instance.new("UICorner", _shadow).CornerRadius = UDim.new(0.3, 0)

    local _iconFrame = Instance.new("Frame")
    _iconFrame.Size             = UDim2.new(0, 62, 0, 62)
    _iconFrame.Position         = UDim2.new(ICON_X, 0, ICON_Y, 0)
    _iconFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    _iconFrame.BorderSizePixel  = 0
    _iconFrame.ZIndex           = 10
    _iconFrame.Parent           = _iconGui
    Instance.new("UICorner", _iconFrame).CornerRadius = UDim.new(0.25, 0)

    local _grad = Instance.new("UIGradient")
    _grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 27, 75)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 18)),
    })
    _grad.Rotation = 135
    _grad.Parent   = _iconFrame

    local _stroke = Instance.new("UIStroke")
    _stroke.Color        = Color3.fromRGB(99, 102, 241)
    _stroke.Thickness    = 1.5
    _stroke.Transparency = 0.3
    _stroke.Parent       = _iconFrame

    local _lMzD = Instance.new("TextLabel")
    _lMzD.Size                   = UDim2.new(1, 0, 0.55, 0)
    _lMzD.Position               = UDim2.fromOffset(0, 6)
    _lMzD.BackgroundTransparency = 1
    _lMzD.Text                   = "MzD"
    _lMzD.TextColor3             = Color3.fromRGB(255, 255, 255)
    _lMzD.Font                   = Enum.Font.GothamBold
    _lMzD.TextSize               = 17
    _lMzD.ZIndex                 = 11
    _lMzD.Parent                 = _iconFrame
    local _tg = Instance.new("UIGradient")
    _tg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 180, 252)),
    })
    _tg.Rotation = 90
    _tg.Parent   = _lMzD

    local _lHub = Instance.new("TextLabel")
    _lHub.Size                   = UDim2.new(1, 0, 0.35, 0)
    _lHub.Position               = UDim2.new(0, 0, 0.6, 0)
    _lHub.BackgroundTransparency = 1
    _lHub.Text                   = "Hub"
    _lHub.TextColor3             = Color3.fromRGB(129, 140, 248)
    _lHub.Font                   = Enum.Font.Gotham
    _lHub.TextSize               = 11
    _lHub.ZIndex                 = 11
    _lHub.Parent                 = _iconFrame

    local _iconBtn = Instance.new("TextButton")
    _iconBtn.Size                   = UDim2.new(0, 62, 0, 62)
    _iconBtn.Position               = UDim2.new(ICON_X, 0, ICON_Y, 0)
    _iconBtn.BackgroundTransparency = 1
    _iconBtn.Text                   = ""
    _iconBtn.ZIndex                 = 12
    _iconBtn.Parent                 = _iconGui
    Instance.new("UICorner", _iconBtn).CornerRadius = UDim.new(0.25, 0)

    _iconBtn.MouseEnter:Connect(function()
        _stroke.Transparency = 0
        _stroke.Thickness    = 2
        _shadow.BackgroundTransparency = 0.4
    end)
    _iconBtn.MouseLeave:Connect(function()
        _stroke.Transparency = 0.3
        _stroke.Thickness    = 1.5
        _shadow.BackgroundTransparency = 0.6
    end)

    local function moveAll(pos)
        _iconFrame.Position = pos
        _iconBtn.Position   = pos
        _shadow.Position    = UDim2.new(pos.X.Scale, pos.X.Offset - 3, pos.Y.Scale, pos.Y.Offset - 3)
    end

    local _dragging  = false
    local _dragStart = nil
    local _startPos  = nil
    local _dragMoved = false

    _iconBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            _dragging  = true
            _dragMoved = false
            _dragStart = input.Position
            _startPos  = _iconFrame.Position
        end
    end)
    _iconBtn.InputChanged:Connect(function(input)
        if _dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - _dragStart
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
                _dragMoved = true
            end
            moveAll(UDim2.new(
                _startPos.X.Scale, _startPos.X.Offset + delta.X,
                _startPos.Y.Scale, _startPos.Y.Offset + delta.Y
            ))
        end
    end)
    _iconBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            _dragging = false
        end
    end)

    -- ============================================
    -- STAP 2: FLUENT LADEN
    -- Snapshot VOOR CreateWindow → daarna weten
    -- we exact welke ScreenGui Fluent aanmaakte
    -- ============================================
    twait(0.5)
    pcall(function()
        for _, gui in pairs(Player.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "MzDIconToggle" then
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
    local GODWALKY  = {"5","3","1","0","-1","-2","-3","-5","-8","-10","-15"}
    local GODFLOORY = {"15","12","10","8","5","3","0","-3","-5","-8","-10","-15","-20"}

    -- Snapshot vóór CreateWindow
    local _before = {}
    for _, gui in pairs(Player.PlayerGui:GetChildren()) do
        _before[gui] = true
    end

    local W = Fluent:CreateWindow({
        Title    = "MzD Hub",
        SubTitle = "v13.0 Clean",
        TabWidth = 160,
        Size     = UDim2.fromOffset(640, 540),
        Acrylic  = true,
        Theme    = "Dark",
    })

    -- Vind de NIEUWE ScreenGui die Fluent net aanmaakte
    local _fluentGui = nil
    for _, gui in pairs(Player.PlayerGui:GetChildren()) do
        if not _before[gui] and gui:IsA("ScreenGui") then
            _fluentGui = gui
            warn("[MzD] Fluent ScreenGui gevonden: " .. gui.Name)
            break
        end
    end

    -- Toggle functie — nu simpel en betrouwbaar
    local _wVisible = true
    local function toggleWindow()
        if not _fluentGui then
            warn("[MzD] _fluentGui is nil, kan niet togglen!")
            return
        end
        _wVisible = not _wVisible
        _fluentGui.Enabled = _wVisible
        warn("[MzD] Window visible: " .. tostring(_wVisible))
    end

    -- Icoon klik = TOGGLE (niet alleen show)
    _iconBtn.MouseButton1Click:Connect(function()
        if _dragMoved then return end
        toggleWindow()
    end)

    -- ============================================
    -- STAP 3: NA LADEN — hint verbergen + X knop
    -- ============================================
    task.spawn(function()
        twait(1)
        pcall(function()
            if not _fluentGui then return end

            -- Verberg Ctrl/keybind hints
            for _, lbl in pairs(_fluentGui:GetDescendants()) do
                if lbl:IsA("TextLabel") then
                    local t = lbl.Text:lower()
                    if t:find("ctrl") or t:find("control") or t:find("rightcontrol") or t:find("minimize") then
                        lbl.Text    = ""
                        lbl.Visible = false
                    end
                end
            end

            -- Debug: alle knoppen printen
            for _, btn in pairs(_fluentGui:GetDescendants()) do
                if btn:IsA("ImageButton") or btn:IsA("TextButton") then
                    warn("[MzD] Knop: '" .. btn.Name .. "' | Parent: '" .. btn.Parent.Name .. "'")
                end
            end

            -- X knop vervangen
            local TARGET_NAMES = {
                "close","closebutton","exit","x",
                "closewindow","close_button","btnclose",
            }
            for _, btn in pairs(_fluentGui:GetDescendants()) do
                if (btn:IsA("ImageButton") or btn:IsA("TextButton"))
                and not btn:FindFirstChild("_mzdReplaced") then
                    local n = string.lower(btn.Name)
                    local matched = false
                    for _, t in pairs(TARGET_NAMES) do
                        if n == t then matched = true break end
                    end
                    if matched then
                        warn("[MzD] Sluitknop vervangen: " .. btn.Name)
                        local parent   = btn.Parent
                        local pos      = btn.Position
                        local size     = btn.Size
                        local zindex   = btn.ZIndex
                        local imgId    = btn:IsA("ImageButton") and btn.Image or nil
                        local imgColor = btn:IsA("ImageButton") and btn.ImageColor3 or Color3.new(1,1,1)
                        local bgTrans  = btn.BackgroundTransparency
                        local bgColor  = btn.BackgroundColor3
                        btn:Destroy()

                        local newBtn
                        if imgId and imgId ~= "" then
                            newBtn = Instance.new("ImageButton")
                            newBtn.Image       = imgId
                            newBtn.ImageColor3 = imgColor
                        else
                            newBtn = Instance.new("TextButton")
                            newBtn.Text       = "✕"
                            newBtn.TextColor3 = Color3.new(1,1,1)
                            newBtn.Font       = Enum.Font.GothamBold
                            newBtn.TextSize   = 14
                        end
                        newBtn.Name                   = "_mzdCloseBtn"
                        newBtn.Position               = pos
                        newBtn.Size                   = size
                        newBtn.ZIndex                 = zindex
                        newBtn.BackgroundTransparency = bgTrans
                        newBtn.BackgroundColor3       = bgColor
                        Instance.new("BoolValue", newBtn).Name = "_mzdReplaced"
                        newBtn.Parent = parent
                        newBtn.MouseButton1Click:Connect(function()
                            toggleWindow()
                        end)
                    end
                end
            end
        end)
    end)

    -- Dummy objecten voor status_loop.lua
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

    FT:AddDropdown("FarmMutation", {Title = "💎 Mutatie",   Values = MUT, Default = "None",         Multi = false}):OnChanged(function(v) MzD.S.TargetMutation = v end)
    FT:AddDropdown("FarmMode",     {Title = "⚙️ Mode",      Values = FM,  Default = MzD.S.FarmMode, Multi = false}):OnChanged(function(v) MzD.S.FarmMode = v end)
    FT:AddDropdown("FarmSlot",     {Title = "📦 Slot",      Values = SL,  Default = MzD.S.FarmSlot, Multi = false}):OnChanged(function(v) MzD.S.FarmSlot = v end)
    FT:AddSlider("FarmMaxLevel",   {Title = "📈 Max Level", Default = MzD.S.MaxLevel, Min = 1, Max = 500, Rounding = 0}):OnChanged(function(v) MzD.S.MaxLevel = mfloor(v) end)

    local LBTG = FT:AddToggle("LBToggle", {Title = "🎲 Auto Lucky Blocks", Default = true})
    LBTG:OnChanged(function(v) if v then MzD.findBase() MzD.startLuckyBlockFarm() else MzD.stopLuckyBlockFarm() end end)
    FT:AddDropdown("LBRarity", {Title = "⭐ LB Rarity", Values = LBR, Default = {"Divine", "Infinity", "Admin"}, Multi = true}):OnChanged(function(v)
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
