-- ============================================
-- [MODULE 9] DOOM EVENT COLLECTOR
-- Geen Tower Mover meer — die was verwijderd.
-- Doom collector heeft eigen _doomConn zodat hij
-- NOOIT conflicteert met Valentine/Arcade/etc.
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

    local function fireAllDoomPrompts(parent)
        if not parent then return end
        for _, d in pairs(parent:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function()
                    d.HoldDuration = 0
                    d.MaxActivationDistance = 99999
                    d.RequiresLineOfSight   = false
                end)
                pcall(function() fireproximityprompt(d) end)
            end
        end
    end

    local function scanDoomParts()
        MzD._doomCachedParts = {}
        local folder = workspace:FindFirstChild("DoomEventParts")
        if folder then
            for _, obj in pairs(folder:GetDescendants()) do
                if obj:IsA("BasePart") then tinsert(MzD._doomCachedParts, obj) end
                if obj:IsA("ProximityPrompt") then
                    pcall(function()
                        obj.HoldDuration = 0
                        obj.MaxActivationDistance = 99999
                        obj.RequiresLineOfSight   = false
                    end)
                end
            end
        end
        MzD._doomLastScan = tick()
        return #MzD._doomCachedParts
    end

    local function handleDoomNewDesc(d)
        if not MzD.S.DoomEnabled then return end
        if d:IsA("BasePart") then
            tinsert(MzD._doomCachedParts, d)
            pcall(function()
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then firetouchinterest(hrp, d, 0) firetouchinterest(hrp, d, 1) end
            end)
        end
        if d:IsA("ProximityPrompt") then
            pcall(function()
                d.HoldDuration = 0 d.MaxActivationDistance = 99999 d.RequiresLineOfSight = false
            end)
            pcall(function() fireproximityprompt(d) end)
        end
    end

    function MzD.startDoomCollector()
        if MzD.S.DoomEnabled then return end
        MzD.S.DoomEnabled  = true
        MzD._doomCollected = 0
        MzD.Status.doomCount = 0
        local partCount = scanDoomParts()

        local folder = workspace:FindFirstChild("DoomEventParts")
        if not folder then
            tspawn(function()
                folder = workspace:WaitForChild("DoomEventParts", 30)
                if folder and MzD.S.DoomEnabled then
                    scanDoomParts()
                    MzD._doomDescConn = folder.DescendantAdded:Connect(handleDoomNewDesc)
                end
            end)
        else
            if MzD._doomDescConn then pcall(function() MzD._doomDescConn:Disconnect() end) end
            MzD._doomDescConn = folder.DescendantAdded:Connect(handleDoomNewDesc)
        end

        -- Eigen Heartbeat connectie — conflicteert nooit met andere collectors
        MzD._doomConn = RunService.Heartbeat:Connect(function()
            if not MzD.S.DoomEnabled then return end
            pcall(function()
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if tick() - MzD._doomLastScan > 10 then
                    local alive = {}
                    for _, p in pairs(MzD._doomCachedParts) do
                        if p and p.Parent then tinsert(alive, p) end
                    end
                    local folder2 = workspace:FindFirstChild("DoomEventParts")
                    if folder2 then
                        for _, obj in pairs(folder2:GetDescendants()) do
                            if obj:IsA("BasePart") then
                                local found = false
                                for _, cached in pairs(alive) do if cached == obj then found = true break end end
                                if not found then tinsert(alive, obj) end
                            end
                        end
                    end
                    MzD._doomCachedParts = alive
                    MzD._doomLastScan    = tick()
                end
                for _, p in pairs(MzD._doomCachedParts) do
                    if p and p.Parent then
                        pcall(function() firetouchinterest(hrp, p, 0) firetouchinterest(hrp, p, 1) end)
                    end
                end
                local folder3 = workspace:FindFirstChild("DoomEventParts")
                if folder3 then fireAllDoomPrompts(folder3) end
                MzD._doomCollected = #MzD._doomCachedParts
            end)
        end)
        MzD.Status.doom = "Aan (" .. partCount .. " parts)"
    end

    function MzD.stopDoomCollector()
        MzD.S.DoomEnabled = false
        if MzD._doomConn     then pcall(function() MzD._doomConn:Disconnect()     end) MzD._doomConn = nil end
        if MzD._doomDescConn then pcall(function() MzD._doomDescConn:Disconnect() end) MzD._doomDescConn = nil end
        MzD._doomCachedParts = {}
        MzD._doomCollected   = 0
        MzD.Status.doom = "Uit"
    end
end

return M
