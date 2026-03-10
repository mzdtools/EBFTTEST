-- ============================================
-- [MODULE] PHANTOM EVENT COLLECTOR
-- ============================================

local M = {}

function M.init(Modules)
    local G          = Modules.globals
    local MzD        = G.MzD
    local Player     = G.Player
    local RunService = G.RunService
    local tinsert    = G.tinsert
    local tspawn     = G.tspawn
    local twait      = G.twait
    local tcancel    = G.tcancel

    local FOLDERS        = { "PhantomShardParts", "PhantomOrbParts", "PhantomCoinParts" }
    local CACHE_INTERVAL = 5

    -- --------------------------------------------------------
    -- Wall patch: knipt gat in FrontWall voor de Staircase
    -- Staircase X range: ~399–527 (center 463, size 129)
    -- Gap met padding: 390–535
    -- --------------------------------------------------------
    local WALL_GAP_X_MIN = 390
    local WALL_GAP_X_MAX = 535

    local function patchWallPart(wall)
        local cx = wall.Position.X
        local cy = wall.Position.Y
        local cz = wall.Position.Z
        local sx = wall.Size.X
        local sy = wall.Size.Y
        local sz = wall.Size.Z

        local wallXMin = cx - sx / 2
        local wallXMax = cx + sx / 2

        -- Geen overlap met gat? Skip
        if wallXMax <= WALL_GAP_X_MIN or wallXMin >= WALL_GAP_X_MAX then return false end

        local leftW  = WALL_GAP_X_MIN - wallXMin
        local rightW = wallXMax - WALL_GAP_X_MAX

        if leftW > 1 then
            local lp          = wall:Clone()
            lp.Name           = wall.Name .. "_L"
            lp.Size           = Vector3.new(leftW, sy, sz)
            lp.Position       = Vector3.new(wallXMin + leftW / 2, cy, cz)
            lp.Anchored       = true
            lp.Parent         = wall.Parent
        end

        if rightW > 1 then
            local rp          = wall:Clone()
            rp.Name           = wall.Name .. "_R"
            rp.Size           = Vector3.new(rightW, sy, sz)
            rp.Position       = Vector3.new(WALL_GAP_X_MAX + rightW / 2, cy, cz)
            rp.Anchored       = true
            rp.Parent         = wall.Parent
        end

        wall:Destroy()
        return true
    end

    local function patchPhantomWalls()
        local phantomMap = workspace:FindFirstChild("PhantomMap")
        if not phantomMap then return end

        local wallFolder = phantomMap:FindFirstChild("MzDHubWalls")
        if not wallFolder then
            -- Wacht tot MapFixer de muren bouwt
            local conn
            conn = phantomMap.ChildAdded:Connect(function(child)
                if child.Name == "MzDHubWalls" then
                    conn:Disconnect()
                    twait(0.3) -- wacht tot alle segmenten gebouwd zijn
                    pcall(function()
                        local patched = 0
                        for _, part in ipairs(child:GetChildren()) do
                            if part:IsA("BasePart") and part.Name:find("FrontWall") then
                                if patchWallPart(part) then patched += 1 end
                            end
                        end
                        print(string.format("[PhantomEvent] Wall patch klaar — %d segment(en) gepatcht", patched))
                    end)
                end
            end)
            return
        end

        -- Muren al aanwezig
        local patched = 0
        for _, part in ipairs(wallFolder:GetChildren()) do
            if part:IsA("BasePart") and part.Name:find("FrontWall") then
                if patchWallPart(part) then patched += 1 end
            end
        end
        print(string.format("[PhantomEvent] Wall patch klaar — %d segment(en) gepatcht", patched))
    end

    -- --------------------------------------------------------
    -- Enemy killer: workspace.GameObjects.Enemies
    -- Bulletproof: probeert meerdere methodes per enemy
    -- --------------------------------------------------------
    local function killEnemy(enemy)
        -- Methode 1: Humanoid health nul zetten
        pcall(function()
            local humanoid = enemy:FindFirstChildWhichIsA("Humanoid", true)
            if humanoid then
                humanoid.MaxHealth = 0
                humanoid.Health    = 0
            end
        end)

        -- Methode 2: Alle BodyForce/BodyVelocity verwijderen (stop beweging)
        pcall(function()
            for _, d in ipairs(enemy:GetDescendants()) do
                if d:IsA("BodyMover") then d:Destroy() end
            end
        end)

        -- Methode 3: firetouchinterest van enemy parts met eigen HRP
        pcall(function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, d in ipairs(enemy:GetDescendants()) do
                if d:IsA("BasePart") then
                    firetouchinterest(d, hrp, 0)
                    firetouchinterest(d, hrp, 1)
                end
            end
        end)

        -- Methode 4: Parts onzichtbaar en non-collidable maken (visuele cleanup)
        pcall(function()
            for _, d in ipairs(enemy:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.CanCollide   = false
                    d.CanTouch     = false
                    d.Transparency = 1
                end
            end
        end)

        -- Methode 5: Proximityprompts firen (sommige enemies hebben een kill prompt)
        pcall(function()
            for _, d in ipairs(enemy:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    d.MaxActivationDistance = 99999
                    d.HoldDuration          = 0
                    fireproximityprompt(d)
                end
            end
        end)
    end

    local function startEnemyKiller()
        if MzD._phantomEnemyConn then
            pcall(function() MzD._phantomEnemyConn:Disconnect() end)
            MzD._phantomEnemyConn = nil
        end
        if MzD._phantomEnemyLoop then
            pcall(tcancel, MzD._phantomEnemyLoop)
            MzD._phantomEnemyLoop = nil
        end

        local function hookFolder(folder)
            -- Kill alles dat er al in zit
            for _, enemy in ipairs(folder:GetChildren()) do
                pcall(function() killEnemy(enemy) end)
            end

            -- Watch voor nieuwe enemies
            MzD._phantomEnemyConn = folder.ChildAdded:Connect(function(enemy)
                if not MzD.S.PhantomEnabled then return end
                twait(0.05) -- wacht tot enemy volledig geladen is
                pcall(function() killEnemy(enemy) end)
            end)

            -- Herhaalde kill loop: pakt enemies die eerste poging overleefden
            MzD._phantomEnemyLoop = tspawn(function()
                while MzD.S.PhantomEnabled do
                    pcall(function()
                        for _, enemy in ipairs(folder:GetChildren()) do
                            pcall(function() killEnemy(enemy) end)
                        end
                    end)
                    twait(1)
                end
            end)
        end

        local go = workspace:FindFirstChild("GameObjects")
        local ef = go and go:FindFirstChild("Enemies")
        if ef then
            hookFolder(ef)
        else
            tspawn(function()
                local go2 = workspace:WaitForChild("GameObjects", 120)
                if not go2 then return end
                local ef2 = go2:WaitForChild("Enemies", 120)
                if ef2 and MzD.S.PhantomEnabled then
                    hookFolder(ef2)
                end
            end)
        end
    end

    local function stopEnemyKiller()
        if MzD._phantomEnemyConn then
            pcall(function() MzD._phantomEnemyConn:Disconnect() end)
            MzD._phantomEnemyConn = nil
        end
        if MzD._phantomEnemyLoop then
            pcall(tcancel, MzD._phantomEnemyLoop)
            MzD._phantomEnemyLoop = nil
        end
    end

    -- --------------------------------------------------------
    -- Build part cache from all Phantom folders
    -- --------------------------------------------------------
    local function buildPartCache(cacheTable)
        local fresh, seen = {}, {}
        for _, name in ipairs(FOLDERS) do
            local folder = workspace:FindFirstChild(name)
            if folder then
                for _, d in pairs(folder:GetDescendants()) do
                    if d:IsA("BasePart") and not seen[d] then
                        seen[d] = true
                        tinsert(fresh, d)
                    end
                end
            end
        end
        for i = 1,          #fresh       do cacheTable[i] = fresh[i] end
        for i = #fresh + 1, #cacheTable  do cacheTable[i] = nil      end
    end

    -- --------------------------------------------------------
    -- Watch a folder for new parts spawning in
    -- --------------------------------------------------------
    local function watchFolder(folder)
        local conn = folder.DescendantAdded:Connect(function(d)
            if not MzD.S.PhantomEnabled then return end
            if d:IsA("BasePart") then
                tinsert(MzD._phantomCachedParts, d)
                pcall(function()
                    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        firetouchinterest(hrp, d, 0)
                        firetouchinterest(hrp, d, 1)
                    end
                end)
            end
        end)
        tinsert(MzD._phantomDescConns, conn)
    end

    -- --------------------------------------------------------
    -- Start collector
    -- --------------------------------------------------------
    function MzD._phantomStartCollector()
        if MzD._phantomCollectorConn then
            pcall(function() MzD._phantomCollectorConn:Disconnect() end)
            MzD._phantomCollectorConn = nil
        end
        for _, c in pairs(MzD._phantomDescConns or {}) do
            pcall(function() c:Disconnect() end)
        end
        MzD._phantomDescConns   = {}
        MzD._phantomCachedParts = {}
        MzD._phantomLastScan    = tick()

        buildPartCache(MzD._phantomCachedParts)
        for _, name in ipairs(FOLDERS) do
            local folder = workspace:FindFirstChild(name)
            if folder then
                watchFolder(folder)
            else
                tspawn(function()
                    local f = workspace:WaitForChild(name, 120)
                    if f and MzD.S.PhantomEnabled then
                        buildPartCache(MzD._phantomCachedParts)
                        watchFolder(f)
                    end
                end)
            end
        end

        MzD._phantomCollectorConn = RunService.Heartbeat:Connect(function()
            if not MzD.S.PhantomEnabled then return end
            pcall(function()
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                if tick() - MzD._phantomLastScan > CACHE_INTERVAL then
                    buildPartCache(MzD._phantomCachedParts)
                    MzD._phantomLastScan = tick()
                end

                for _, p in pairs(MzD._phantomCachedParts) do
                    if p and p.Parent then
                        firetouchinterest(hrp, p, 0)
                        firetouchinterest(hrp, p, 1)
                    end
                end
            end)
        end)
    end

    -- --------------------------------------------------------
    -- Stop collector
    -- --------------------------------------------------------
    function MzD._phantomStopCollector()
        if MzD._phantomCollectorConn then
            pcall(function() MzD._phantomCollectorConn:Disconnect() end)
            MzD._phantomCollectorConn = nil
        end
        for _, c in pairs(MzD._phantomDescConns or {}) do
            pcall(function() c:Disconnect() end)
        end
        MzD._phantomDescConns   = {}
        MzD._phantomCachedParts = {}
    end

    -- --------------------------------------------------------
    -- Internal start (gebruikt door auto-detect + public start)
    -- --------------------------------------------------------
    local function isEventActive()
        for _, name in ipairs(FOLDERS) do
            if workspace:FindFirstChild(name) then return true end
        end
        return false
    end

    local function startPhantomInternal()
        if MzD.phantomThread then return end
        MzD.Status.phantom = "Opstarten..."

        -- Wall patch + enemy killer starten
        pcall(patchPhantomWalls)
        pcall(startEnemyKiller)

        MzD._phantomStartCollector()

        MzD.phantomThread = tspawn(function()
            while MzD.S.PhantomEnabled do
                local ok, err = pcall(function()
                    local count = #(MzD._phantomCachedParts or {})
                    MzD.Status.phantom = "👻 Collecting | " .. count .. " parts"
                    twait(1)
                end)
                if not ok then twait(1) end
            end
            MzD._phantomStopCollector()
            stopEnemyKiller()
            MzD.Status.phantom = "Idle"
            MzD.phantomThread  = nil
        end)
    end

    -- --------------------------------------------------------
    -- Public: start / stop (GUI toggle)
    -- --------------------------------------------------------
    function MzD.startPhantom()
        MzD.S.PhantomEnabled = true
        startPhantomInternal()
    end

    function MzD.stopPhantom()
        MzD.S.PhantomEnabled = false
        if MzD.phantomThread then
            pcall(tcancel, MzD.phantomThread)
            MzD.phantomThread = nil
        end
        MzD._phantomStopCollector()
        stopEnemyKiller()
        MzD.Status.phantom = "Idle"
    end

    -- --------------------------------------------------------
    -- Auto-activate: detecteer event folders bij opstarten
    -- --------------------------------------------------------
    tspawn(function()
        local detected  = false
        local waitStart = tick()
        repeat
            if isEventActive() then detected = true break end
            twait(2)
        until tick() - waitStart > 120

        if detected and MzD.S.PhantomEnabled then
            print("[PhantomEvent] Event folders gedetecteerd — auto-start!")
            startPhantomInternal()
        else
            print("[PhantomEvent] Geen event folders gevonden — wacht op handmatige activatie.")
        end

        -- Blijf monitoren: herstart als event terugkomt
        while true do
            twait(5)
            if MzD.S.PhantomEnabled and not MzD.phantomThread and isEventActive() then
                print("[PhantomEvent] Event hervat — opnieuw starten.")
                startPhantomInternal()
            end
        end
    end)

end

return M
