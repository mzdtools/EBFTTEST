-- ============================================
-- [MODULE 10] GOD MODE - NANO EDITION (v29)
-- Fixes: Geavanceerde Grond-Scanner voor Merchants & Shops.
-- Geforceerde detectie voor eigen Base via GUID.
-- Synchroniseert zwevende en zakkende objecten naar GodFloorY.
-- ============================================

local M = {}

function M.init(Modules)
    local G      = Modules.globals
    local MzD    = G.MzD
    local Player = G.Player
    local tinsert = G.tinsert
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel
    local tdefer  = G.tdefer
    local sfind   = G.sfind
    local slower  = G.slower
    local mabs    = G.mabs
    local mhuge   = G.mhuge
    local mmin    = G.mmin
    local isMzDPart       = Modules.utility.isMzDPart
    local getThemeColors  = Modules.wall_themes.getThemeColors
    local buildSurfaceGui = Modules.utility.buildSurfaceGui

    -- Helper om de werkelijke bodem van een model te vinden
    local function getModelBottom(model)
        local lowestY = mhuge
        local bestPart = nil
        local highestScore = -mhuge

        for _, d in pairs(model:GetDescendants()) do
            if d:IsA("BasePart") and not isMzDPart(d) then
                local area = d.Size.X * d.Size.Z
                local n = slower(d.Name)
                
                -- We zoeken een plat onderdeel (vloer/pad/grond)
                if d.Size.Y < 12 and area > 20 then
                    local score = area
                    if sfind(n, "floor") or sfind(n, "ground") or sfind(n, "base") or sfind(n, "pad") then
                        score = score + 50000
                    end
                    -- Strafpunten voor onderdelen die absurd hoog staan
                    score = score - (d.Position.Y * 5)
                    
                    if score > highestScore then
                        highestScore = score
                        bestPart = d
                    end
                end
                
                if d.Position.Y < lowestY then lowestY = d.Position.Y end
            end
        end

        if bestPart then
            return bestPart.Position.Y - (bestPart.Size.Y / 2)
        end
        return lowestY
    end

    local function godFindFloorParts()
        local floors, map = {}, nil
        for _, c in pairs(workspace:GetChildren()) do
            if c:IsA("Model") and sfind(c.Name,"Map")
               and not sfind(c.Name,"SharedInstances") and not sfind(c.Name,"VFX") then
                map = c break
            end
        end
        if map then
            for _, d in pairs(map:GetDescendants()) do
                if d:IsA("BasePart") and not isMzDPart(d) then
                    local n = slower(d.Name)
                    if sfind(n, "floor") or sfind(n, "ground") or sfind(n, "road") or sfind(n, "grass") then
                        tinsert(floors, d)
                    end
                end
            end
        end
        return floors, map
    end

    local function godDetectMapXRange(map)
        if not map then return -50, 4500 end
        local minX, maxX = mhuge, -mhuge
        for _, d in pairs(map:GetDescendants()) do
            if d:IsA("BasePart") and not isMzDPart(d) then
                if d.Position.X < minX then minX = d.Position.X end
                if d.Position.X > maxX then maxX = d.Position.X end
            end
        end
        return minX - 100, maxX + 100
    end

    local function godFindAllKillParts()
        local kills = {}
        for _, c in pairs(workspace:GetDescendants()) do
            if c:IsA("BasePart") and not isMzDPart(c) then
                local n = slower(c.Name)
                if sfind(n, "kill") or sfind(n, "death") or sfind(n, "damage") then
                    tinsert(kills, c)
                end
            end
        end
        return kills
    end

    local function godDisableKillParts()
        MzD._godKillParts = {}
        local kills = godFindAllKillParts()
        for _, p in pairs(kills) do
            tinsert(MzD._godKillParts, {part = p, pos = p.Position, size = p.Size})
            pcall(function() p.Position = Vector3.new(0, -9999, 0) p.CanTouch = false end)
        end
        return #kills
    end

    local function godRestoreKillParts()
        for _, d in pairs(MzD._godKillParts or {}) do
            pcall(function() d.part.Position = d.pos d.part.CanTouch = true end)
        end
        MzD._godKillParts = {}
    end

    local function godBuildEgaleVloer(map)
        for _, p in pairs(MzD._godCreatedParts or {}) do pcall(function() p:Destroy() end) end
        MzD._godCreatedParts = {}
        
        local startX, endX = godDetectMapXRange(map)
        local floorY = MzD.S.GodFloorY
        local theme = Modules.wall_themes.getThemeColors(MzD)

        local floor = Instance.new("Part")
        floor.Name = "MzDNanoFloor"
        floor.Size = Vector3.new(mabs(endX - startX), 4, 1000)
        floor.Position = Vector3.new((startX + endX)/2, floorY, 0)
        floor.Anchored = true
        floor.Material = Enum.Material.Glass
        floor.Transparency = 0.2
        floor.Color = Color3.fromRGB(20, 20, 20)
        floor.Parent = workspace
        tinsert(MzD._godCreatedParts, floor)
        
        buildSurfaceGui(floor, Enum.NormalId.Top, theme)
    end

    local function godLowerStructures()
        MzD._godMovedParts = {}
        MzD._godMovedSet = {}
        MzD._baseDeltas = {}
        
        local targets = {}
        
        -- 1. Bases
        if workspace:FindFirstChild("Bases") then
            for _, b in pairs(workspace.Bases:GetChildren()) do
                tinsert(targets, {model = b, isBase = true})
            end
        end
        
        -- 2. GameObjects (Shops, Portals, etc)
        local go = workspace:FindFirstChild("GameObjects")
        if go then
            for _, d in pairs(go:GetDescendants()) do
                if d:IsA("Model") and (sfind(slower(d.Name), "shop") or sfind(slower(d.Name), "merchant") or sfind(slower(d.Name), "machine") or sfind(slower(d.Name), "wheel") or sfind(slower(d.Name), "portal")) then
                    -- Alleen top-level models in de mappen toevoegen om dubbel werk te voorkomen
                    if d.Parent.Name == "root" or d.Parent.Name == "PlaceSpecific" or d.Parent == go then
                        tinsert(targets, {model = d, isBase = false})
                    end
                end
            end
        end

        local targetFloorTop = MzD.S.GodFloorY + 2 -- Onze vloer is 4 dik

        for _, item in pairs(targets) do
            local currentBottom = getModelBottom(item.model)
            if currentBottom ~= mhuge then
                local deltaY = targetFloorTop - currentBottom
                
                if item.isBase then MzD._baseDeltas[item.model] = deltaY end

                for _, p in pairs(item.model:GetDescendants()) do
                    if p:IsA("BasePart") and not isMzDPart(p) then
                        tinsert(MzD._godMovedParts, {part = p, orig = p.CFrame})
                        MzD._godMovedSet[p] = true
                        p.CFrame = p.CFrame + Vector3.new(0, deltaY, 0)
                    end
                end
            end
        end
    end

    local function godRestoreStructures()
        for _, d in pairs(MzD._godMovedParts or {}) do
            pcall(function() d.part.CFrame = d.orig end)
        end
        MzD._godMovedParts = {}
        MzD._godMovedSet = {}
        MzD._baseDeltas = {}
    end

    function MzD.enableGod()
        if MzD._isGod then return end
        MzD._isGod = true
        MzD.S.GodEnabled = true
        
        godDisableKillParts()
        local floors, map = godFindFloorParts()
        
        -- Verberg oude vloeren
        MzD._godOriginalFloors = {}
        for _, f in pairs(floors) do
            tinsert(MzD._godOriginalFloors, {part = f, can = f.CanCollide, trans = f.Transparency})
            f.CanCollide = false
            f.Transparency = 1
        end

        godLowerStructures()
        godBuildEgaleVloer(map)
        
        -- Teleport
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(hrp.Position.X, MzD.S.GodWalkY, hrp.Position.Z)
        end

        -- Loop voor nieuwe brainrots
        MzD._godLoopThread = tspawn(function()
            while MzD._isGod do
                if MzD.baseGUID and workspace:FindFirstChild("Bases") then
                    local myBase = workspace.Bases:FindFirstChild(MzD.baseGUID)
                    local delta = MzD._baseDeltas[myBase]
                    if myBase and delta then
                        for _, d in pairs(myBase:GetDescendants()) do
                            if d:IsA("BasePart") and not isMzDPart(d) and not MzD._godMovedSet[d] then
                                MzD._godMovedSet[d] = true
                                d.CFrame = d.CFrame + Vector3.new(0, delta, 0)
                            end
                        end
                    end
                end
                twait(1)
            end
        end)
        
        MzD.Status.god = "Aan"
    end

    function MzD.disableGod()
        MzD._isGod = false
        MzD.S.GodEnabled = false
        if MzD._godLoopThread then tcancel(MzD._godLoopThread) end
        
        godRestoreKillParts()
        godRestoreStructures()
        
        for _, d in pairs(MzD._godOriginalFloors or {}) do
            pcall(function() d.part.CanCollide = d.can d.part.Transparency = d.trans end)
        end
        
        for _, p in pairs(MzD._godCreatedParts or {}) do pcall(function() p:Destroy() end) end
        
        MzD.Status.god = "Uit"
    end
end

return M
