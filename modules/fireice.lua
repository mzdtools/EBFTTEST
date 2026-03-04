-- ============================================
-- [MODULE] FIRE & ICE EVENT FARM
-- Gebruikt firetouchinterest via Heartbeat
-- zodat coins gecollect worden zonder te lopen
-- ============================================

local M = {}

function M.init(Modules)
    local G          = Modules.globals
    local MzD        = G.MzD
    local Player     = G.Player
    local RunService = G.RunService
    local tspawn     = G.tspawn
    local twait      = G.twait
    local tcancel    = G.tcancel
    local tinsert    = G.tinsert
    local sfind      = G.sfind
    local slower     = G.slower

    -- ── State ──────────────────────────────────────────────
    MzD.Status.fireice    = "Idle"
    MzD._fireiceEnabled   = false
    MzD._fireiceThread    = nil
    MzD._fireiceCollected = 0
    MzD._fireiceCachedParts     = {}
    MzD._fireiceLastCacheScan   = 0
    MzD._fireiceCollectorConn   = nil
    MzD._fireiceDescAddedConn   = nil

    -- ── Folder namen ───────────────────────────────────────
    local FOLDER_NAMES = {
        "FireAndIceEventParts",
        "FireAndIce",
        "FireiceCoins",
        "FireiceEvent",
        "FireiceEventParts",
        "Fireice",
        "FireIceEventParts",
        "FireIce",
    }

    local function getFireiceFolder()
        for _, naam in ipairs(FOLDER_NAMES) do
            local f = workspace:FindFirstChild(naam)
            if f then return f, naam end
        end
        local events = workspace:FindFirstChild("GameObjects")
        events = events and events:FindFirstChild("Events")
        if events then
            for _, child in pairs(events:GetChildren()) do
                local n = slower(child.Name)
                if sfind(n, "fireandice") or sfind(n, "fireice") then
                    return child, child.Name
                end
            end
        end
        return nil, nil
    end

    -- ── Part cache bouwen ──────────────────────────────────
    local function buildCache(folder, cacheTable)
        local fresh, seen = {}, {}
        for _, p in pairs(folder:GetDescendants()) do
            if p:IsA("BasePart") and not seen[p] then
                seen[p] = true
                tinsert(fresh, p)
            end
        end
        for i = 1, #fresh do cacheTable[i] = fresh[i] end
        for i = #fresh + 1, #cacheTable do cacheTable[i] = nil end
    end

    -- ── Start collector ────────────────────────────────────
    local function startCollector()
        -- Cleanup vorige connecties
        if MzD._fireiceCollectorConn then
            pcall(function() MzD._fireiceCollectorConn:Disconnect() end)
            MzD._fireiceCollectorConn = nil
        end
        if MzD._fireiceDescAddedConn then
            pcall(function() MzD._fireiceDescAddedConn:Disconnect() end)
            MzD._fireiceDescAddedConn = nil
        end
        MzD._fireiceCachedParts   = {}
        MzD._fireiceLastCacheScan = tick()

        local folder, folderName = getFireiceFolder()

        if folder then
            buildCache(folder, MzD._fireiceCachedParts)

            -- Nieuwe parts direct toevoegen aan cache
            MzD._fireiceDescAddedConn = folder.DescendantAdded:Connect(function(d)
                if not MzD._fireiceEnabled then return end
                if d:IsA("BasePart") then
                    tinsert(MzD._fireiceCachedParts, d)
                    -- Direct proberen te collecten
                    pcall(function()
                        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            firetouchinterest(hrp, d, 0)
                            firetouchinterest(hrp, d, 1)
                        end
                    end)
                end
            end)
        else
            -- Wacht op folder en probeer opnieuw
            tspawn(function()
                local found = nil
                local deadline = tick() + 60
                while tick() < deadline and MzD._fireiceEnabled do
                    local f = getFireiceFolder()
                    if f then found = f break end
                    twait(2)
                end
                if found and MzD._fireiceEnabled then
                    buildCache(found, MzD._fireiceCachedParts)
                    MzD._fireiceDescAddedConn = found.DescendantAdded:Connect(function(d)
                        if not MzD._fireiceEnabled then return end
                        if d:IsA("BasePart") then
                            tinsert(MzD._fireiceCachedParts, d)
                            pcall(function()
                                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    firetouchinterest(hrp, d, 0)
                                    firetouchinterest(hrp, d, 1)
                                end
                            end)
                        end
                    end)
                end
            end)
        end

        -- Heartbeat loop — fire touch op alle gecachede parts elke frame
        MzD._fireiceCollectorConn = RunService.Heartbeat:Connect(function()
            if not MzD._fireiceEnabled then return end
            pcall(function()
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                -- Cache refresh elke 5 seconden
                if tick() - MzD._fireiceLastCacheScan > 5 then
                    local f = getFireiceFolder()
                    if f then buildCache(f, MzD._fireiceCachedParts) end
                    MzD._fireiceLastCacheScan = tick()
                end

                for _, p in pairs(MzD._fireiceCachedParts) do
                    if p and p.Parent then
                        firetouchinterest(hrp, p, 0)
                        firetouchinterest(hrp, p, 1)
                    end
                end
            end)
        end)
    end

    local function stopCollector()
        if MzD._fireiceCollectorConn then
            pcall(function() MzD._fireiceCollectorConn:Disconnect() end)
            MzD._fireiceCollectorConn = nil
        end
        if MzD._fireiceDescAddedConn then
            pcall(function() MzD._fireiceDescAddedConn:Disconnect() end)
            MzD._fireiceDescAddedConn = nil
        end
        MzD._fireiceCachedParts = {}
    end

    -- ── Hoofd loop (alleen status bijhouden) ───────────────
    function MzD.startFireice()
        if MzD._fireiceThread then return end
        MzD._fireiceEnabled   = true
        MzD._fireiceCollected = 0
        MzD.Status.fireice    = "Opstarten..."

        startCollector()

        MzD._fireiceThread = tspawn(function()
            while MzD._fireiceEnabled do
                pcall(function()
                    local partCount = #MzD._fireiceCachedParts
                    local folder    = getFireiceFolder()
                    if not folder then
                        MzD.Status.fireice = "⏳ Wachten op Fire & Ice map..."
                    else
                        MzD.Status.fireice = string.format(
                            "🔥❄️ Collecten | %d parts | %d verzameld",
                            partCount, MzD._fireiceCollected
                        )
                    end
                end)
                twait(1)
            end
            MzD.Status.fireice = string.format("Gestopt (verzameld: %d)", MzD._fireiceCollected)
            MzD._fireiceThread = nil
        end)
    end

    function MzD.stopFireice()
        MzD._fireiceEnabled = false
        stopCollector()
        if MzD._fireiceThread then
            pcall(tcancel, MzD._fireiceThread)
            MzD._fireiceThread = nil
        end
        MzD.Status.fireice = string.format("Gestopt (verzameld: %d)", MzD._fireiceCollected)
    end

end

return M
