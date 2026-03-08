-- ============================================
-- TOWER TRIAL FARM STANDALONE — PLATFORM EDIT
-- ============================================

local Player = game.Players.LocalPlayer
do
    local old = Player.PlayerGui:FindFirstChild("TowerTrialFarm")
    if old then old:Destroy() end
end

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local tspawn       = task.spawn
local tcancel      = task.cancel
local twait        = task.wait
local tinsert      = table.insert
local tsort        = table.sort
local mfloor       = math.floor
local sformat      = string.format

-- ============================================
-- FARM PLATFORM AANMAKEN
-- ============================================
local farmPlatform = workspace:FindFirstChild("TowerFarmPlatform")
if not farmPlatform then
    farmPlatform = Instance.new("Part")
    farmPlatform.Name = "TowerFarmPlatform"
    farmPlatform.Size = Vector3.new(5, 1, 5)
    farmPlatform.Anchored = true
    farmPlatform.CanCollide = true
    farmPlatform.Transparency = 0.5
    farmPlatform.Color = Color3.fromRGB(180, 80, 255)
    farmPlatform.Parent = workspace
end

-- ============================================
-- SAFE Y DETECTIE
-- ============================================
local function detectSafeY()
    for _, part in ipairs(workspace:GetChildren()) do
        if part.Name == "MzDGodFloor" and part:IsA("BasePart") then
            return part.Position.Y + part.Size.Y / 2 - 1
        end
    end
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { char }
        local hit = workspace:Raycast(root.Position, Vector3.new(0, -200, 0), params)
        if hit then return hit.Position.Y + 3 end
    end
    if root and root.Position.Y > -50 then return root.Position.Y end
    return 10
end

-- ============================================
-- PLATFORM TWEENING
-- ============================================
local function tweenToSafe(targetCFrame, speed)
    speed = speed or 1200
    local safeY   = detectSafeY()
    local finalCF = CFrame.new(targetCFrame.Position.X, safeY, targetCFrame.Position.Z)
    
    local character = Player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local dist     = (rootPart.Position - finalCF.Position).Magnitude
    local duration = math.max(0.05, dist / speed)
    
    -- Zet het platform direct onder de speler voordat we bewegen
    farmPlatform.CFrame = rootPart.CFrame * CFrame.new(0, -3.5, 0)
    
    -- Tween het platform naar de bestemming (ietsje lager zodat speler goed uitkomt)
    local tween = TweenService:Create(
        farmPlatform,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = finalCF * CFrame.new(0, -3.5, 0) }
    )
    
    -- Zet de speler continu vast op het platform tijdens de rit
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if rootPart and farmPlatform then
            rootPart.CFrame = farmPlatform.CFrame * CFrame.new(0, 3.5, 0)
            rootPart.Velocity = Vector3.zero
        else
            if connection then connection:Disconnect() end
        end
    end)
    
    tween:Play()
    tween.Completed:Wait()
    
    if connection then connection:Disconnect() end
    
    if rootPart then
        rootPart.Velocity    = Vector3.zero
        rootPart.RotVelocity = Vector3.zero
    end
end

-- ============================================
-- HELPERS
-- ============================================
local function safeUnequip()
    local character = Player.Character if not character then return end
    local humanoid  = character:FindFirstChildOfClass("Humanoid")
    if humanoid then pcall(function() humanoid:UnequipTools() end) end
end

local function forceGrabPrompt(target)
    if not target then return end
    for _, desc in ipairs(target:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            pcall(function()
                desc.RequiresLineOfSight   = false
                desc.HoldDuration          = 0
                desc.MaxActivationDistance = 99999
                desc.Enabled               = true
            end)
            if fireproximityprompt then pcall(function() fireproximityprompt(desc) end) end
        end
    end
    if target:IsA("ProximityPrompt") then
        pcall(function()
            target.RequiresLineOfSight   = false
            target.HoldDuration          = 0
            target.MaxActivationDistance = 99999
        end)
        if fireproximityprompt then pcall(function() fireproximityprompt(target) end) end
    end
end

local function haltMovement()
    local char = Player.Character if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if hum and hrp then hum:MoveTo(hrp.Position) end
    if hrp then
        hrp.Velocity    = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    end
end

local function getTower()
    local ok, t = pcall(function() return workspace.GameObjects.PlaceSpecific.root.Tower end)
    if ok and t then return t end
    for _, c in ipairs(workspace:GetDescendants()) do
        if c.Name == "Tower" and c:IsA("Model") then
            local cnt = 0
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") then cnt += 1 end
                if cnt > 5 then return c end
            end
        end
    end
    return nil
end

local function cleanTowerVisuals()
    local tower = getTower()
    if not tower then return end
    for _, child in ipairs(tower:GetChildren()) do
        if child.Name ~= "Main" then
            pcall(function() child:Destroy() end)
        end
    end
end

local function fireAllPrompts(targetModel)
    if not targetModel then return end
    for _, d in ipairs(targetModel:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function()
                d.RequiresLineOfSight   = false
                d.HoldDuration          = 0
                d.MaxActivationDistance = 99999
                d.Enabled               = true
            end)
            if fireproximityprompt then pcall(function() fireproximityprompt(d) end) end
        end
    end
end

local function getToolCount()
    local count = 0
    local bp = Player:FindFirstChild("Backpack")
    if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then count += 1 end end end
    if Player.Character then
        for _, t in ipairs(Player.Character:GetChildren()) do if t:IsA("Tool") then count += 1 end end
    end
    return count
end

local function findBrainrotRoot(b)
    if not b then return nil end
    local r = b:FindFirstChild("Root")
    if r and r:IsA("BasePart") then return r end
    local rendered = b:FindFirstChild("RenderedBrainrot")
    if rendered then local rr = rendered:FindFirstChild("Root") if rr and rr:IsA("BasePart") then return rr end end
    if b:IsA("Model") and b.PrimaryPart then return b.PrimaryPart end
    for _, d in ipairs(b:GetDescendants()) do if d:IsA("BasePart") then return d end end
    return nil
end

-- ============================================
-- HUD READERS
-- ============================================
local function getTrialBar()
    local hud = Player.PlayerGui:FindFirstChild("TowerTrialHUD")
    return hud and hud:FindFirstChild("TrialBar")
end

local function getTimer()
    local bar = getTrialBar() if not bar then return "" end
    local lbl = bar:FindFirstChild("Timer")
    return lbl and lbl.Text or ""
end

local function getDeposits()
    local bar = getTrialBar() if not bar then return 0, 10 end
    local lbl = bar:FindFirstChild("Deposits") if not lbl then return 0, 10 end
    local cur, goal = lbl.Text:match("(%d+)%s*/%s*(%d+)")
    return tonumber(cur) or 0, tonumber(goal) or 10
end

local function getRequiredRarity()
    return "Common"
end

local function isTrialActive()
    local bar = getTrialBar()
    if not bar or not bar.Visible then return false end
    local t = getTimer()
    return t ~= "" and t ~= "00:00" and t ~= "0:00"
end

local function getLiveCooldown()
    local tower = getTower() if not tower then return nil end
    for _, d in ipairs(tower:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" then
            local m, s = d.Text:match("(%d%d?):(%d%d)")
            if m and s then return (tonumber(m)*60) + tonumber(s) end
        end
    end
    return nil
end

local function killRewardPopups()
    pcall(function()
        for _, gui in ipairs(Player.PlayerGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                local txt = gui.Text:lower()
                if txt:find("claim") or txt:find("reward") or txt:find("worthy") then
                    local isTrialGui = false
                    local ancestor = gui.Parent
                    while ancestor do
                        if ancestor.Name == "TowerTrialHUD" or ancestor.Name == "TrialBar" then
                            isTrialGui = true break
                        end
                        ancestor = ancestor.Parent
                    end
                    if not isTrialGui then
                        local frame = gui:FindFirstAncestorWhichIsA("ScreenGui")
                        if frame and frame.Name ~= "TowerTrialHUD" and frame.Name ~= "TowerTrialFarm" then
                            frame.Enabled = false
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================
-- STATE MACHINE
-- ============================================
local statusText = "Idle"
local _running   = false
local _thread    = nil

local function startFarm()
    if _running then return end
    _running = true

    _thread = tspawn(function()
        local state         = "ACTIVATE"
        local depBeforeTrip = 0
        local trialsDone    = 0
        local trips         = 0

        cleanTowerVisuals()
        safeUnequip()
        twait(0.3)
        local baselineTools = getToolCount()

        while _running do
            local ok, err = pcall(function()
                killRewardPopups()

                if state == "ACTIVATE" then
                    if isTrialActive() then state = "COLLECT" return end
                    local liveCd = getLiveCooldown()
                    if liveCd and liveCd > 0 then
                        statusText = "⚠️ Tower op cooldown..."
                        state = "COOLDOWN" return
                    end

                    local tower = getTower()
                    if not tower then
                        statusText = "⚠️ Tower niet gevonden"
                        twait(3) return
                    end

                    cleanTowerVisuals()
                    statusText = "🏃 Naar tower..."
                    local tPos = tower:GetPivot().Position
                    tweenToSafe(CFrame.new(tPos.X - 43, 0, tPos.Z))
                    cleanTowerVisuals()

                    for i = 1, 15 do
                        if not _running then break end
                        statusText = "🏁 Activeer trial... " .. i
                        fireAllPrompts(tower)
                        twait(0.4)
                        if isTrialActive() then
                            statusText = "✅ Trial actief! " .. getRequiredRarity()
                            state = "COLLECT" return
                        end
                    end

                    local cd = getLiveCooldown()
                    if cd and cd > 0 then state = "COOLDOWN"
                    else statusText = "⚠️ Activeren mislukt" twait(5) end
                    return
                end

                if state == "COLLECT" then
                    if getToolCount() > baselineTools then
                        statusText = "📦 Iets vast → direct submit"
                        depBeforeTrip, _ = getDeposits()
                        state = "SUBMIT" return
                    end

                    local cur, goal = getDeposits()
                    statusText = sformat("💝 %d/%d | Trips:%d | #%d", cur, goal, trips, trialsDone)

                    if cur >= goal then
                        pcall(function()
                            local rs     = game:GetService("ReplicatedStorage")
                            local shared = rs:FindFirstChild("Shared")
                            local remote = shared and shared:FindFirstChild("Remotes") and shared.Remotes:FindFirstChild("Networking") and shared.Remotes.Networking:FindFirstChild("RE/Tower/TowerClaimConfirmed")
                            if remote then remote:FireServer() end
                        end)
                        twait(1.5)
                        trialsDone += 1
                        statusText = "🎉 Trial #" .. trialsDone .. " KLAAR!"
                        state = "COOLDOWN" return
                    end

                    local activeBrainrots = workspace:FindFirstChild("ActiveBrainrots")
                    if not activeBrainrots then twait(2) return end
                    local required = getRequiredRarity()
                    if required == "?" then twait(1) return end

                    local list = {}
                    local hrp  = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    for _, folder in ipairs(activeBrainrots:GetChildren()) do
                        if folder.Name == required then
                            for _, b in ipairs(folder:GetChildren()) do
                                local root = findBrainrotRoot(b)
                                if root then
                                    local dist = hrp and (hrp.Position - root.Position).Magnitude or 0
                                    tinsert(list, { b = b, root = root, dist = dist })
                                end
                            end
                        end
                    end
                    tsort(list, function(a, bx) return a.dist < bx.dist end)

                    if #list == 0 then
                        statusText = "⏳ Geen " .. required .. " op de map..."
                        twait(1.5) return
                    end

                    local entry       = list[1]
                    local startParent = entry.b.Parent
                    local startTools  = getToolCount()

                    statusText = sformat("🧠 %s (%.0fm)", required, entry.dist)

                    -- Tween het platform naar de brainrot
                    tweenToSafe(entry.root.CFrame * CFrame.new(0, 3, 0))

                    for attempt = 1, 15 do
                        if not _running then break end
                        if not entry.b or entry.b.Parent ~= startParent then break end
                        if getToolCount() > startTools then break end

                        forceGrabPrompt(entry.root)
                        forceGrabPrompt(entry.b)
                        fireAllPrompts(entry.b)
                        twait(0.1)
                    end

                    local pickedUp = getToolCount() > startTools or (entry.b and entry.b.Parent ~= startParent)
                    if pickedUp then
                        for w = 1, 15 do
                            if getToolCount() > baselineTools then break end
                            twait(0.1)
                        end
                        
                        if getToolCount() > baselineTools then
                            depBeforeTrip = cur
                            state = "SUBMIT"
                        else
                            statusText = "⏳ Brainrot weg maar niks vast, opnieuw..."
                            twait(0.5)
                        end
                    else
                        statusText = "⏳ Ophalen mislukt"
                        twait(1)
                    end
                    return
                end

                if state == "SUBMIT" then
                    trips += 1
                    local tower = getTower()
                    if not tower then state = "COLLECT" return end

                    statusText = "📦 Submit #" .. trips .. " | Trips:" .. trips
                    cleanTowerVisuals()
                    
                    -- Tween het platform terug naar de tower
                    local tPos = tower:GetPivot().Position
                    tweenToSafe(CFrame.new(tPos.X - 43, 0, tPos.Z))
                    cleanTowerVisuals()

                    local t0        = tick()
                    local deposited = false
                    while tick() - t0 < 5 do
                        if not _running then break end
                        fireAllPrompts(tower)
                        twait(0.2)
                        local cur2, _ = getDeposits()
                        if cur2 > depBeforeTrip then deposited = true break end
                    end

                    if deposited then
                        local waitStart = tick()
                        local cur2, _  = getDeposits()
                        while cur2 <= depBeforeTrip and (tick() - waitStart) < 3 do
                            twait(0.2)
                            cur2, _ = getDeposits()
                        end
                    else
                        statusText = "⚠️ Submit mislukt, verder..."
                    end

                    safeUnequip()
                    state = "COLLECT"
                    return
                end

                if state == "COOLDOWN" then
                    safeUnequip()
                    local remaining = 300
                    while _running do
                        killRewardPopups()
                        local live = getLiveCooldown()
                        if live ~= nil then remaining = live end
                        if remaining <= 0 then
                            statusText = "✅ Cooldown klaar!"
                            twait(2) state = "ACTIVATE" return
                        end
                        statusText = sformat("⏳ Cooldown: %d:%02d", mfloor(remaining/60), mfloor(remaining%60))
                        if live == nil then remaining -= 1 end
                        twait(1)
                    end
                    return
                end
            end)

            if not ok then
                statusText = "❌ " .. tostring(err):sub(1, 60)
                twait(3)
            end
            twait(0.05)
        end

        haltMovement()
        statusText = "Gestopt"
        _thread    = nil
    end)
end

local function stopFarm()
    _running = false
    if _thread then
        pcall(tcancel, _thread)
        _thread = nil
    end
    haltMovement()
    safeUnequip()
    statusText = "Idle"
end

-- ============================================
-- UI
-- ============================================
local trialsDone = 0

local sg = Instance.new("ScreenGui")
sg.Name            = "TowerTrialFarm"
sg.ResetOnSpawn    = false
sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder    = 10
sg.Parent          = Player.PlayerGui

local ctrl = Instance.new("Frame", sg)
ctrl.Size             = UDim2.fromOffset(180, 60)
ctrl.Position         = UDim2.new(0, 16, 1, -76)
ctrl.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ctrl.BorderSizePixel  = 0
ctrl.Active           = true
ctrl.Draggable        = true
Instance.new("UICorner", ctrl).CornerRadius = UDim.new(0, 8)

local btn = Instance.new("TextButton", ctrl)
btn.Size             = UDim2.new(1, -12, 0, 34)
btn.Position         = UDim2.fromOffset(6, 13)
btn.BackgroundColor3 = Color3.fromRGB(0, 170, 70)
btn.BorderSizePixel  = 0
btn.Text             = "▶  START FARM"
btn.TextColor3       = Color3.fromRGB(255, 255, 255)
btn.TextSize         = 13
btn.Font             = Enum.Font.GothamBold
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

local hudFrame = Instance.new("Frame", sg)
hudFrame.Size                 = UDim2.fromOffset(260, 130)
hudFrame.Position             = UDim2.new(1, -276, 1, -146)
hudFrame.BackgroundColor3     = Color3.fromRGB(8, 8, 14)
hudFrame.BackgroundTransparency = 0.08
hudFrame.BorderSizePixel      = 0
Instance.new("UICorner", hudFrame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", hudFrame)
stroke.Color       = Color3.fromRGB(180, 80, 255)
stroke.Thickness   = 1.5
stroke.Transparency = 0.3

local titleBar = Instance.new("Frame", hudFrame)
titleBar.Size             = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel  = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleFix = Instance.new("Frame", titleBar)
titleFix.Size             = UDim2.new(1, 0, 0.5, 0)
titleFix.Position         = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
titleFix.BackgroundTransparency = 0.2
titleFix.BorderSizePixel  = 0

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size               = UDim2.new(1, -10, 1, 0)
titleLbl.Position           = UDim2.fromOffset(10, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text               = "🏆  TOWER TRIAL FARM (PLATFORM)"
titleLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
titleLbl.TextSize           = 11
titleLbl.Font               = Enum.Font.GothamBold
titleLbl.TextXAlignment     = Enum.TextXAlignment.Left

local statusLbl = Instance.new("TextLabel", hudFrame)
statusLbl.Size              = UDim2.new(1, -16, 0, 28)
statusLbl.Position          = UDim2.fromOffset(8, 34)
statusLbl.BackgroundTransparency = 1
statusLbl.Text              = "⏳ Idle"
statusLbl.TextColor3        = Color3.fromRGB(220, 180, 255)
statusLbl.TextSize          = 13
statusLbl.Font              = Enum.Font.GothamBold
statusLbl.TextXAlignment    = Enum.TextXAlignment.Left
statusLbl.TextWrapped       = true

local timerLbl = Instance.new("TextLabel", hudFrame)
timerLbl.Size               = UDim2.new(1, -16, 0, 36)
timerLbl.Position           = UDim2.fromOffset(8, 62)
timerLbl.BackgroundTransparency = 1
timerLbl.Text               = ""
timerLbl.TextColor3         = Color3.fromRGB(255, 220, 80)
timerLbl.TextSize           = 28
timerLbl.Font               = Enum.Font.GothamBold
timerLbl.TextXAlignment     = Enum.TextXAlignment.Center

local statsLbl = Instance.new("TextLabel", hudFrame)
statsLbl.Size               = UDim2.new(1, -16, 0, 18)
statsLbl.Position           = UDim2.fromOffset(8, 106)
statsLbl.BackgroundTransparency = 1
statsLbl.Text               = "Trials: 0  |  Trips: 0"
statsLbl.TextColor3         = Color3.fromRGB(140, 140, 160)
statsLbl.TextSize           = 10
statsLbl.Font               = Enum.Font.Gotham
statsLbl.TextXAlignment     = Enum.TextXAlignment.Center

local function pulseStroke(col)
    pcall(function()
        local tw1 = TweenService:Create(stroke, TweenInfo.new(0.15), {
            Color = col or Color3.fromRGB(255, 255, 100), Thickness = 3
        })
        tw1:Play() tw1.Completed:Wait()
        TweenService:Create(stroke, TweenInfo.new(0.4), {
            Color = Color3.fromRGB(180, 80, 255), Thickness = 1.5
        }):Play()
    end)
end

btn.MouseButton1Click:Connect(function()
    if _running then
        stopFarm()
        btn.Text             = "▶  START FARM"
        btn.BackgroundColor3 = Color3.fromRGB(0, 170, 70)
    else
        startFarm()
        btn.Text             = "⏹  STOP FARM"
        btn.BackgroundColor3 = Color3.fromRGB(190, 30, 30)
    end
end)

tspawn(function()
    local lastStatus  = ""
    local wasCooldown = false
    while true do
        pcall(function()
            local status = statusText
            if not _running then
                hudFrame.BackgroundTransparency = 0.5
                stroke.Transparency             = 0.7
                statusLbl.Text                  = "💤 Gestopt"
                timerLbl.Text                   = ""
                return
            end
            hudFrame.BackgroundTransparency = 0.08
            stroke.Transparency             = 0.3
            statusLbl.Text                  = status
            if status ~= lastStatus then
                if status:find("KLAAR") then
                    tspawn(function() pulseStroke(Color3.fromRGB(80, 255, 120)) end)
                elseif status:find("Cooldown") then
                    tspawn(function() pulseStroke(Color3.fromRGB(255, 180, 40)) end)
                elseif status:find("Ophalen") or status:find("Submit") then
                    tspawn(function() pulseStroke(Color3.fromRGB(100, 180, 255)) end)
                end
                lastStatus = status
            end
            local m, s = status:match("(%d+):(%d%d)")
            if m and s then
                local totalSec = (tonumber(m) or 0) * 60 + (tonumber(s) or 0)
                timerLbl.Text       = m .. ":" .. s
                timerLbl.TextColor3 = totalSec <= 10 and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 220, 80)
                wasCooldown = true
            else
                if wasCooldown then timerLbl.Text = "" wasCooldown = false end
                if     status:find("Ophalen")     then timerLbl.Text = "🧠"
                elseif status:find("Submit")       then timerLbl.Text = "📦"
                elseif status:find("tower") or status:find("Tower") then timerLbl.Text = "🏃"
                elseif status:find("Trial actief") then timerLbl.Text = "⚔️"
                elseif status:find("KLAAR")        then timerLbl.Text = "🎉"
                elseif status:find("Idle") or status:find("Gestopt") then timerLbl.Text = ""
                end
            end
            local t = status:match("Trial #(%d+)")
            if t then trialsDone = tonumber(t) end
            local tripsStr = status:match("Trips:(%d+)") or "0"
            statsLbl.Text = "Trials: " .. trialsDone .. "  |  Trips: " .. tripsStr
        end)
        twait(0.15)
    end
end)
