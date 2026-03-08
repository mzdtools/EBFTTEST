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
        for i = 1,         #fresh        do cacheTable[i] = fresh[i] end
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
        -- Clean up any existing connections
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

        -- Cache + watch all folders (wait for them if not loaded yet)
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

        -- Heartbeat: fire touch on every cached part every frame
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
    -- Auto-detect: start wanneer event folders in workspace
    -- verschijnen, stop wanneer ze verdwijnen
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
        MzD.Status.phantom = "Idle"
    end

    -- --------------------------------------------------------
    -- Auto-activate: scan workspace voor event folders
    -- Start zodra 1 van de 3 folders gevonden wordt
    -- --------------------------------------------------------
    tspawn(function()
        -- Wacht max 120s op de event folders
        local detected = false
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

        -- Blijf monitoren: herstart als folders opnieuw verschijnen
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
