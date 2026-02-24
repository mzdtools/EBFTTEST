-- ============================================
-- [MODULE 23] CANDY / VALENTINE COLLECTORS
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player       = G.Player
    local RunService   = G.RunService
    local tinsert      = G.tinsert
    local tspawn       = G.tspawn
    local twait        = G.twait
    local tcancel      = G.tcancel
    local sfind        = G.sfind
    local slower       = G.slower

    local function buildPartCache(folderName, cacheTable)
        local folder = workspace:FindFirstChild(folderName)
        if not folder then return end
        local fresh, seen = {}, {}
        for _, p in pairs(folder:GetDescendants()) do
            if p:IsA("BasePart") and not seen[p] then seen[p] = true tinsert(fresh, p) end
        end
        for _, p in pairs(folder:GetChildren()) do
            if p:IsA("BasePart") and not seen[p] then seen[p] = true tinsert(fresh, p) end
            if p:IsA("Model") or p:IsA("Folder") then
                for _, d in pairs(p:GetDescendants()) do
                    if d:IsA("BasePart") and not seen[d] then seen[d] = true tinsert(fresh, d) end
                end
            end
        end
        for i = 1, #fresh do cacheTable[i] = fresh[i] end
        for i = #fresh + 1, #cacheTable do cacheTable[i] = nil end
    end

    function MzD._candyStartCollector()
        if MzD._candyCollectorConn  then pcall(function() MzD._candyCollectorConn:Disconnect()  end) MzD._candyCollectorConn = nil end
        if MzD._candyDescAddedConn  then pcall(function() MzD._candyDescAddedConn:Disconnect()  end) MzD._candyDescAddedConn = nil end
        MzD._candyCachedParts   = {}
        MzD._candyLastCacheScan = tick()
        buildPartCache("CandyEventParts", MzD._candyCachedParts)

        local function onNewDesc(d)
            if not MzD.S.ValentineEnabled then return end
            if d:IsA("BasePart") then
                tinsert(MzD._candyCachedParts, d)
                pcall(function()
                    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then firetouchinterest(hrp,d,0) firetouchinterest(hrp,d,1) end
                end)
            end
        end

        local candyFolder = workspace:FindFirstChild("CandyEventParts")
        if candyFolder then
            MzD._candyDescAddedConn = candyFolder.DescendantAdded:Connect(onNewDesc)
        else
            tspawn(function()
                local f2 = workspace:WaitForChild("CandyEventParts", 60)
                if f2 and MzD.S.ValentineEnabled then
                    buildPartCache("CandyEventParts", MzD._candyCachedParts)
                    MzD._candyDescAddedConn = f2.DescendantAdded:Connect(onNewDesc)
                end
            end)
        end

        MzD._candyCollectorConn = RunService.Heartbeat:Connect(function()
            if not MzD.S.ValentineEnabled then return end
            pcall(function()
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if tick() - MzD._candyLastCacheScan > 5 then
                    buildPartCache("CandyEventParts", MzD._candyCachedParts)
                    MzD._candyLastCacheScan = tick()
                end
                for _, p in pairs(MzD._candyCachedParts) do
                    if p and p.Parent then firetouchinterest(hrp,p,0) firetouchinterest(hrp,p,1) end
                end
            end)
        end)
    end

    function MzD._candyStopCollector()
        if MzD._candyCollectorConn then pcall(function() MzD._candyCollectorConn:Disconnect() end) MzD._candyCollectorConn = nil end
        if MzD._candyDescAddedConn then pcall(function() MzD._candyDescAddedConn:Disconnect() end) MzD._candyDescAddedConn = nil end
        MzD._candyCachedParts = {}
    end

    function MzD.getHeartCount()
        local count = 0
        pcall(function()
            local ls = Player:FindFirstChild("leaderstats")
            if ls then
                for _, v in pairs(ls:GetChildren()) do
                    local n = slower(v.Name)
                    if sfind(n,"heart") or sfind(n,"candy") or sfind(n,"gram") or sfind(n,"valentine") then
                        local val = tonumber(v.Value) or 0
                        if val > count then count = val end
                    end
                end
            end
        end)
        if count == 0 then
            pcall(function()
                for _, a in pairs({"Hearts","Candy","CandyGrams","Valentines","Love","CandyHearts","ValentineHearts"}) do
                    local v = Player:GetAttribute(a)
                    if v then local n2 = tonumber(v) or 0 if n2 > count then count = n2 end end
                end
            end)
        end
        return count
    end

    function MzD.findCandyGramStation()
        local station = nil
        pcall(function() station = workspace.ValentinesMap.CandyGramStation end)
        if station then return station end
        for _, obj in pairs(workspace:GetDescendants()) do
            local n = slower(obj.Name)
            if sfind(n,"candygram") or sfind(n,"station") then
                if obj:IsA("BasePart") or obj:IsA("Model") then return obj end
            end
        end
        return nil
    end

    function MzD.getStationPosition()
        local station = MzD.findCandyGramStation() if not station then return nil end
        if station:IsA("BasePart") then return station.Position end
        local pos = nil
        if station:IsA("Model") then
            pcall(function() pos = station:GetPivot().Position end)
            if not pos then
                for _, d in pairs(station:GetDescendants()) do
                    if d:IsA("BasePart") then pos = d.Position break end
                end
            end
        end
        return pos
    end

    function MzD._valentineStartCoinCollector()
        if MzD.valentineCollectorConn   then pcall(function() MzD.valentineCollectorConn:Disconnect()  end) MzD.valentineCollectorConn = nil end
        if MzD._valentineDescAddedConn  then pcall(function() MzD._valentineDescAddedConn:Disconnect() end) MzD._valentineDescAddedConn = nil end
        MzD._valentineCachedParts   = {}
        MzD._valentineLastCacheScan = tick()
        buildPartCache("ValentinesCoinParts", MzD._valentineCachedParts)

        local function onNewDesc(d)
            if not MzD.S.ValentineEnabled then return end
            if d:IsA("BasePart") then
                tinsert(MzD._valentineCachedParts, d)
                pcall(function()
                    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then firetouchinterest(hrp,d,0) firetouchinterest(hrp,d,1) end
                end)
            end
        end

        local coinFolder = workspace:FindFirstChild("ValentinesCoinParts")
        if coinFolder then
            MzD._valentineDescAddedConn = coinFolder.DescendantAdded:Connect(onNewDesc)
        else
            tspawn(function()
                local f2 = workspace:WaitForChild("ValentinesCoinParts", 60)
                if f2 and MzD.S.ValentineEnabled then
                    buildPartCache("ValentinesCoinParts", MzD._valentineCachedParts)
                    MzD._valentineDescAddedConn = f2.DescendantAdded:Connect(onNewDesc)
                end
            end)
        end

        MzD.valentineCollectorConn = RunService.Heartbeat:Connect(function()
            if not MzD.S.ValentineEnabled then return end
            pcall(function()
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if tick() - MzD._valentineLastCacheScan > 5 then
                    buildPartCache("ValentinesCoinParts", MzD._valentineCachedParts)
                    MzD._valentineLastCacheScan = tick()
                end
                for _, p in pairs(MzD._valentineCachedParts) do
                    if p and p.Parent then firetouchinterest(hrp,p,0) firetouchinterest(hrp,p,1) end
                end
            end)
        end)
    end

    function MzD.submitCandyGrams()
        local stationPos = MzD.getStationPosition()
        if not stationPos then MzD.Status.valentine = "⚠️ Station niet gevonden!" twait(2) return false end
        MzD.tweenTo(CFrame.new(stationPos.X, MzD.S.GodWalkY, stationPos.Z)) twait(0.3)
        local fired   = false
        local station = MzD.findCandyGramStation()
        if station then
            local function fireAll(obj)
                if not obj then return end
                if obj:IsA("ProximityPrompt") then
                    pcall(function() obj.HoldDuration=0 obj.MaxActivationDistance=99999 obj.RequiresLineOfSight=false end)
                    pcall(function() fireproximityprompt(obj) end) fired = true
                end
                for _, d in pairs(obj:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        pcall(function() d.HoldDuration=0 d.MaxActivationDistance=99999 d.RequiresLineOfSight=false end)
                        pcall(function() fireproximityprompt(d) end) fired = true
                    end
                end
            end
            fireAll(station)
            if station.Parent and not station.Parent:IsA("Workspace") then fireAll(station.Parent) end
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local function touchAll(obj)
                    if obj:IsA("BasePart") then
                        pcall(function() firetouchinterest(hrp,obj,0) firetouchinterest(hrp,obj,1) end)
                    end
                    for _, d in pairs(obj:GetDescendants()) do
                        if d:IsA("BasePart") then
                            pcall(function() firetouchinterest(hrp,d,0) firetouchinterest(hrp,d,1) end)
                        end
                    end
                end
                touchAll(station)
            end
        end
        if not fired then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.Parent and obj.Parent:IsA("BasePart") then
                        if (obj.Parent.Position - hrp.Position).Magnitude < 50 then
                            pcall(function() obj.HoldDuration=0 obj.MaxActivationDistance=99999 obj.RequiresLineOfSight=false end)
                            pcall(function() fireproximityprompt(obj) end) fired = true
                        end
                    end
                end
            end
        end
        twait(0.5) return fired
    end

    function MzD.startValentine()
        if MzD.valentineThread then return end
        MzD.S.ValentineEnabled   = true
        MzD.Status.valentineCount = 0
        MzD.Status.valentine     = "Opstarten..."
        if not MzD._isGod then MzD.enableGod() end
        MzD._valentineStartCoinCollector()
        MzD._candyStartCollector()

        MzD.valentineThread = tspawn(function()
            local submitCount = 0
            while MzD.S.ValentineEnabled do
                local ok, err = pcall(function()
                    if MzD.isDead() then
                        MzD.waitForRespawn() twait(1)
                        if not MzD._isGod then MzD.enableGod() end return
                    end
                    local h          = MzD.getHeartCount()
                    local coinCount  = #MzD._valentineCachedParts
                    local candyCount = #MzD._candyCachedParts
                    MzD.Status.valentine = "💝 "..h.."/100 | 🪙 "..coinCount.." | 🍬 "..candyCount.." | #"..submitCount
                    if h >= 100 then
                        MzD.Status.valentine = "🏃 Naar station... H:"..h
                        local ok2 = MzD.submitCandyGrams()
                        if ok2 then
                            local prevH, waitStart = h, tick()
                            repeat twait(0.3) h = MzD.getHeartCount() until h < prevH or tick()-waitStart > 5
                            if h < prevH then
                                submitCount += 1 MzD.Status.valentineCount = submitCount
                                MzD.Status.valentine = "✅ Submit #"..submitCount.." | Nu: "..h.." hearts"
                            else
                                MzD.Status.valentine = "⚠️ Submit mislukt? H:"..h
                            end
                        else
                            MzD.Status.valentine = "⚠️ Retry..." twait(2)
                        end
                        twait(0.5)
                    else
                        twait(1)
                    end
                end)
                if not ok then twait(1) end
            end
            if MzD.valentineCollectorConn  then pcall(function() MzD.valentineCollectorConn:Disconnect()  end) MzD.valentineCollectorConn = nil end
            if MzD._valentineDescAddedConn then pcall(function() MzD._valentineDescAddedConn:Disconnect() end) MzD._valentineDescAddedConn = nil end
            MzD._valentineCachedParts = {}
            MzD._candyStopCollector()
            MzD.Status.valentine = "Idle" MzD.valentineThread = nil
        end)
    end

    function MzD.stopValentine()
        MzD.S.ValentineEnabled = false
        if MzD.valentineThread then pcall(tcancel, MzD.valentineThread) MzD.valentineThread = nil end
        if MzD.valentineCollectorConn  then pcall(function() MzD.valentineCollectorConn:Disconnect()  end) MzD.valentineCollectorConn = nil end
        if MzD._valentineDescAddedConn then pcall(function() MzD._valentineDescAddedConn:Disconnect() end) MzD._valentineDescAddedConn = nil end
        MzD._valentineCachedParts = {}
        MzD._candyStopCollector()
        MzD.Status.valentine = "Idle"
    end
end

return M
