-- ============================================
-- [MODULE 10] GOD MODE - NANO EDITION (v29 FIXED)
-- Fixes: Vloer werkt weer + Score-systeem voor bodems +
-- Actieve magneet voor nieuwe brainrots op eigen base.
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

    -- ==========================================
    -- VLOER DETECTIE (uit v28, was werkend)
    -- ==========================================
    local function godFindFloorParts()
        local floors, map = {}, nil
        for _, c in pairs(workspace:GetChildren()) do
            if c:IsA("Model") and sfind(c.Name,"Map")
               and not sfind(c.Name,"SharedInstances") and not sfind(c.Name,"VFX") then
                if c:FindFirstChild("Spawners") or c:FindFirstChild("Gaps") or
                   c:FindFirstChild("FirstFloor") or c:FindFirstChild("Ground") then
                    map = c break
                end
                local hasFloor = false
                for _, d in pairs(c:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local n = slower(d.Name)
                        if n == "firstfloor" or n == "ground" or n == "floor" then hasFloor = true break end
                    end
                end
                if hasFloor then map = c break end
            end
        end
        if not map then
            for _, c in pairs(workspace:GetChildren()) do
                if c:IsA("Model") and sfind(c.Name,"Map")
                   and not sfind(c.Name,"SharedInstances") and not sfind(c.Name,"VFX") then
                    local cnt = 0
                    for _, d in pairs(c:GetDescendants()) do
                        if d:IsA("BasePart") then cnt += 1 end
                        if cnt > 10 then map = c break end
                    end
                    if map then break end
                end
            end
        end
        if map then
            local seen = {}
            for _, d in pairs(map:GetDescendants()) do
                if d:IsA("BasePart") and not isMzDPart(d) and not seen[d] then
                    local n = slower(d.Name)
                    if n == "firstfloor" or n == "ground" or n == "floor"
                       or n == "grass" or n == "path" or n == "road"
                       or n == "platform" or n == "bridgefloor" then
                        seen[d] = true tinsert(floors, d)
                    elseif d.Size.X > 15 and d.Size.Z > 5 and d.Size.Y < 20
                           and d.Position.Y > -10 and d.Position.Y < 30 then
                        seen[d] = true tinsert(floors, d)
                    end
                end
            end
            local sp = map:FindFirstChild("Spawners")
            if sp then
                for _, s in pairs(sp:GetChildren()) do
                    if s:IsA("BasePart") and not seen[s] and not isMzDPart(s)
                       and s.Size.X > 15 and s.Size.Z > 5 and s.Size.Y < 20
                       and s.Position.Y > -10 and s.Position.Y < 30 then
                        seen[s] = true tinsert(floors, s)
                    end
                end
            end
        end
        for _, c in pairs(workspace:GetChildren()) do
            if sfind(c.Name,"SharedInstances") then
                local fl = c:FindFirstChild("Floors")
                if fl then
                    for _, f in pairs(fl:GetChildren()) do
                        if f:IsA("BasePart") and not isMzDPart(f)
                           and f.Size.X > 15 and f.Size.Z > 5 and f.Size.Y < 20
                           and f.Position.Y > -10 and f.Position.Y < 30 then
                             tinsert(floors, f)
                        end
                    end
                end
                for _, f in pairs(c:GetChildren()) do
                    if f:IsA("BasePart") and not isMzDPart(f)
                       and f.Size.X > 15 and f.Size.Z > 5 and f.Size.Y < 20
                       and f.Position.Y > -10 and f.Position.Y < 30 then
                        tinsert(floors, f)
                    end
                end
            end
        end

        local go = workspace:FindFirstChild("GameObjects")
        if go then
            local ps = go:FindFirstChild("PlaceSpecific", true)
            if ps then
                local root = ps:FindFirstChild("root")
                if root then
                    local misc = root:FindFirstChild("Misc")
                    if misc then
                        for _, d in pairs(misc:GetDescendants()) do
                            if d:IsA("BasePart") then tinsert(floors, d) end
                        end
                    end
                    local tower = root:FindFirstChild("Tower")
                    if tower then
                        for _, child in pairs(tower:GetChildren()) do
                            if child.Name ~= "Main" then
                                if child:IsA("BasePart") then tinsert(floors, child) end
                                for _, d in pairs(child:GetDescendants()) do
                                    if d:IsA("BasePart") then tinsert(floors, d) end
                                end
                            end
                        end
                    end
                end
            end
        end

        return floors, map
    end

    local function godDetectMapXRange(map)
        local minX, maxX, found = mhuge, -mhuge, false
        local function chk(p)
            if not p:IsA("BasePart") or isMzDPart(p) then return end
            if p.Size.Y > p.Size.X and p.Size.Y > p.Size.Z then return end
            if p.Position.Y > 50 or p.Position.Y < -30 or p.Size.X < 5 then return end
            local l = p.Position.X - p.Size.X/2
            local r = p.Position.X + p.Size.X/2
            if l < minX then minX = l end
            if r > maxX then maxX = r end
            found = true
        end
        if map then for _, d in pairs(map:GetDescendants()) do if d:IsA("BasePart") then chk(d) end end end
        for _, c in pairs(workspace:GetChildren()) do
            if sfind(c.Name,"SharedInstances") then
                for _, f in pairs(c:GetChildren()) do if f:IsA("BasePart") then chk(f) end end
                local fl = c:FindFirstChild("Floors")
                if fl then for _, f in pairs(fl:GetChildren()) do chk(f) end end
            end
        end
        if found and maxX > minX then return minX-20, maxX+20 end
        return -50, 4500
    end

    -- ==========================================
    -- KILL PARTS (uit v28, volledig)
    -- ==========================================
    local function godFindAllKillParts()
        local kills, seen = {}, {}
        for _, c in pairs(workspace:GetDescendants()) do
            if c:IsA("BasePart") and not seen[c] and not isMzDPart(c) then
                local ok2, isKillStrip = pcall(function()
                    return c.Size.Y < 1 and c.Size.Z > 50
                       and c.Position.Y < 5 and c.Position.Y > -5 and c.Size.X < 5
                end)
                if ok2 and isKillStrip then seen[c] = true tinsert(kills, c) end
                if not seen[c] then
                    local n = slower(c.Name)
                    if sfind(n,"kill") or sfind(n,"tsunamikill") or sfind(n,"deathzone")
                       or sfind(n,"damagezone") or sfind(n,"killbrick") or sfind(n,"killpart") then
                        seen[c] = true tinsert(kills, c)
                    end
                end
            end
        end
        return kills
    end

    local function godDisableKillParts()
        MzD._godKillParts = {}
        local kills = godFindAllKillParts()
        for _, p in pairs(kills) do
            tinsert(MzD._godKillParts, {
                part = p, canCollide = p.CanCollide, canTouch = p.CanTouch,
                size = p.Size, position = p.Position, transparency = p.Transparency,
            })
            pcall(function()
                p.CanCollide = false p.CanTouch = false p.Transparency = 1
                p.Size = Vector3.new(0,0,0) p.Position = Vector3.new(0,-9999,0)
            end)
        end
        return #kills
    end

    local function godRestoreKillParts()
        for _, data in pairs(MzD._godKillParts or {}) do
            pcall(function()
                if data.part and data.part.Parent then
                    data.part.Size        = data.size
                    data.part.Position    = data.position
                    data.part.CanCollide  = data.canCollide
                    data.part.CanTouch    = data.canTouch
                    data.part.Transparency = data.transparency
                end
            end)
        end
        MzD._godKillParts = {}
    end

    local function godStartKillWatcher()
        if MzD._godKillWatchThread then pcall(tcancel, MzD._godKillWatchThread) end
        MzD._godKillWatchThread = tspawn(function()
            while MzD._isGod do
                pcall(function()
                    for _, data in pairs(MzD._godKillParts) do
                        if data.part and data.part.Parent then
                            data.part.CanCollide = false data.part.CanTouch = false
                            data.part.Size = Vector3.new(0,0,0)
                            data.part.Position = Vector3.new(0,-9999,0)
                        end
                    end
                end)
                pcall(function()
                    for _, c in pairs(workspace:GetDescendants()) do
                        if c:IsA("BasePart") and not isMzDPart(c) then
                            local isKill = false
                            pcall(function()
                                if c.Size.Y < 1 and c.Size.Z > 50
                                   and c.Position.Y < 5 and c.Position.Y > -5 and c.Size.X < 5 then
                                    isKill = true
                                end
                            end)
                            if not isKill then
                                local n = slower(c.Name)
                                if sfind(n,"kill") or sfind(n,"deathzone") or sfind(n,"damagezone") then
                                    isKill = true
                                end
                            end
                            if isKill then
                                local already = false
                                for _, data in pairs(MzD._godKillParts) do if data.part == c then already = true break end end
                                if not already then
                                    tinsert(MzD._godKillParts, {
                                        part = c, canCollide = c.CanCollide, canTouch = c.CanTouch,
                                        size = c.Size, position = c.Position, transparency = c.Transparency,
                                    })
                                    pcall(function()
                                        c.CanCollide = false c.CanTouch = false c.Transparency = 1
                                        c.Size = Vector3.new(0,0,0) c.Position = Vector3.new(0,-9999,0)
                                    end)
                                end
                            end
                        end
                    end
                end)
                twait(3)
            end
        end)
    end

    -- ==========================================
    -- VLOER BOUWEN (uit v28, was werkend)
    -- ==========================================
    local function godBuildEgaleVloer(map)
        for _, p in pairs(MzD._godCreatedParts or {}) do
            pcall(function() if p and p.Parent then p:Destroy() end end)
        end
        MzD._godCreatedParts = {}
        local startX, endX = godDetectMapXRange(map)
        local floorY     = MzD.S.GodFloorY
        local floorWidth = 420
        local floorThick = 4
        local theme      = getThemeColors(MzD)
        local maxSeg     = 2000
        local curX       = startX
        local firstSeg   = true

        while curX < endX do
            local segLen  = mmin(maxSeg, endX - curX)
            local centerX = curX + segLen/2
            local floor   = Instance.new("Part")
            floor.Name         = "MzDNanoFloor"
            floor.Size         = Vector3.new(segLen, floorThick, floorWidth)
            floor.Position     = Vector3.new(centerX, floorY, 0)
            floor.Anchored     = true floor.CanCollide = true
            floor.Color        = Color3.fromRGB(15, 15, 15)
            floor.Material     = Enum.Material.Glass
            floor.Transparency = 0.1
            floor.Reflectance  = 0.3
            floor.TopSurface   = Enum.SurfaceType.Smooth floor.BottomSurface = Enum.SurfaceType.Smooth
            floor.Parent       = workspace
            tinsert(MzD._godCreatedParts, floor)

            local light = Instance.new("SurfaceLight")
            light.Color = theme.stripe
            light.Brightness = 2
            light.Range = 20
            light.Face = Enum.NormalId.Top
            light.Angle = 180
            light.Parent = floor

            if firstSeg then
                firstSeg = false
                buildSurfaceGui(floor, Enum.NormalId.Top, theme)
            end

            local topY = floorY + floorThick/2 + 0.1
            for _, zPos in pairs({floorWidth/2-5, -floorWidth/2+5}) do
                local s = Instance.new("Part")
                s.Name = "MzDGodFloorStripe" s.Size = Vector3.new(segLen, 0.2, 2)
                s.Position = Vector3.new(centerX, topY, zPos)
                s.Anchored = true s.CanCollide = false
                s.Color = theme.stripe s.Material = Enum.Material.Neon
                s.Parent = workspace
                tinsert(MzD._godCreatedParts, s)
            end
            local sm = Instance.new("Part")
            sm.Name = "MzDGodFloorStripe" sm.Size = Vector3.new(segLen, 0.2, 1)
            sm.Position = Vector3.new(centerX, topY, 0)
            sm.Anchored = true sm.CanCollide = false
            sm.Color = theme.stripe sm.Material = Enum.Material.Neon
            sm.Parent = workspace
            tinsert(MzD._godCreatedParts, sm)

            local wallHeight = 50
            local wallThickness = 2
            local wallY = floorY + (floorThick / 2) + (wallHeight / 2)
            for _, zOffset in pairs({floorWidth/2 + wallThickness/2, -floorWidth/2 - wallThickness/2}) do
                local wall = Instance.new("Part")
                wall.Name = "MzDGodNanoWall"
                wall.Size = Vector3.new(segLen, wallHeight, wallThickness)
                wall.Position = Vector3.new(centerX, wallY, zOffset)
                wall.Anchored = true wall.CanCollide = true
                wall.Material = Enum.Material.ForceField
                wall.Transparency = 0.7
                wall.Color = theme.stripe
                wall.Parent = workspace
                tinsert(MzD._godCreatedParts, wall)
            end

            curX = curX + segLen
        end

        local catch = Instance.new("Part")
        catch.Name = "MzDGodCatchFloor"
        catch.Size = Vector3.new(mabs(endX - startX) + 200, 2, floorWidth + 100)
        catch.Position = Vector3.new((startX+endX)/2, floorY-15, 0)
        catch.Anchored = true catch.CanCollide = true catch.Transparency = 1
        catch.Parent = workspace
        tinsert(MzD._godCreatedParts, catch)
        return true
    end

    -- ==========================================
    -- FLOOR HIDE/RESTORE (uit v28)
    -- ==========================================
    local function godHideOriginalFloors()
        local floors, map = godFindFloorParts()
        MzD._godOriginalFloors = {}
        for _, p in pairs(floors) do
            tinsert(MzD._godOriginalFloors, {
                part = p, size = p.Size, position = p.Position,
                canCollide = p.CanCollide, transparency = p.Transparency,
                color = p.Color, material = p.Material, anchored = p.Anchored,
            })
            pcall(function() p.CanCollide = false p.Transparency = 1 end)
        end
        if map then
            for _, c in pairs(map:GetChildren()) do
                if c:IsA("BasePart") and c.Name == "BridgeFloor" and not isMzDPart(c) then
                    tinsert(MzD._godOriginalFloors, {
                        part = c, size = c.Size, position = c.Position,
                        canCollide = c.CanCollide, transparency = c.Transparency,
                        color = c.Color, material = c.Material, anchored = c.Anchored,
                    })
                    pcall(function() c.CanCollide = false c.Transparency = 1 end)
                end
            end
        end
        return map
    end

    local function godRestoreFloors()
        for _, data in pairs(MzD._godOriginalFloors or {}) do
            pcall(function()
                if data.part and data.part.Parent then
                    data.part.Size        = data.size
                    data.part.Position    = data.position
                    data.part.CanCollide  = data.canCollide
                    data.part.Transparency = data.transparency
                    data.part.Color       = data.color
                    data.part.Material    = data.material
                    data.part.Anchored    = data.anchored
                end
            end)
        end
        MzD._godOriginalFloors = {}
        for _, f in pairs(MzD._godCreatedParts or {}) do
            pcall(function() if f and f.Parent then f:Destroy() end end)
        end
        MzD._godCreatedParts = {}
    end

    -- ==========================================
    -- STRUCTUREN VERLAGEN (v30: fixes voor eigen base, zwevers, doorzakkers)
    -- ==========================================

    -- Vind de absolute onderkant van een model (laagste punt van alle parts)
    local function getModelTrueBottom(model)
        local lowestBottom = mhuge
        for _, d in pairs(model:GetDescendants()) do
            if d:IsA("BasePart") and not isMzDPart(d) then
                -- Skip onderdelen die extreem hoog staan (bv. vlaggen, antennes)
                if d.Position.Y < 200 then
                    local bottom = d.Position.Y - (d.Size.Y / 2)
                    if bottom < lowestBottom then
                        lowestBottom = bottom
                    end
                end
            end
        end
        return lowestBottom
    end

    local function godMoveModel(obj, deltaY, isBase)
        if isBase and MzD._baseDeltas then
            MzD._baseDeltas[obj] = deltaY
        end
        for _, d in pairs(obj:GetDescendants()) do
            if d:IsA("BasePart") and not isMzDPart(d) then
                tinsert(MzD._godMovedParts, {part = d, origCF = d.CFrame})
                MzD._godMovedSet[d] = true
                pcall(function() d.CFrame = d.CFrame + Vector3.new(0, deltaY, 0) end)
            end
        end
    end

    local function godLowerStructures()
        MzD._godMovedParts = {}
        MzD._godMovedSet = {}
        MzD._baseDeltas = {}

        local floorTop = MzD.S.GodFloorY + 2  -- bovenkant van onze vloer (4 dik, center = GodFloorY)

        -- ===== 1. ALLE BASES (absolute laagste punt) =====
        if workspace:FindFirstChild("Bases") then
            for _, base in pairs(workspace.Bases:GetChildren()) do
                local trueBottom = getModelTrueBottom(base)
                if trueBottom ~= mhuge then
                    local deltaY = floorTop - trueBottom
                    -- Clamp: niet meer dan 500 stuks verplaatsen (voorkomt gekke waarden)
                    if mabs(deltaY) < 500 then
                        godMoveModel(base, deltaY, true)
                    end
                end
            end
        end

        -- ===== 2. WORKSPACE DIRECTE OBJECTEN =====
        local function tryMoveWorkspaceObj(name)
            local obj = workspace:FindFirstChild(name)
            if not obj then return end
            local trueBottom = getModelTrueBottom(obj)
            if trueBottom == mhuge then return end
            local deltaY = floorTop - trueBottom
            if mabs(deltaY) < 500 then
                godMoveModel(obj, deltaY, false)
            end
        end

        tryMoveWorkspaceObj("DoomWheel")
        tryMoveWorkspaceObj("LimitedShop")

        -- ===== 3. GAME OBJECTS (Shops, Portals, Machines) =====
        local go = workspace:FindFirstChild("GameObjects")
        if go then
            local ps = go:FindFirstChild("PlaceSpecific", true)
            if ps then
                local root = ps:FindFirstChild("root")
                if root then
                    -- Objecten die op de absolute bodem moeten landen
                    local trueBottomTargets = {
                        "MysteryMerchant", "SiteEventDetails", "PlazaPortal",
                    }
                    for _, name in pairs(trueBottomTargets) do
                        local obj = root:FindFirstChild(name)
                        if obj then
                            local trueBottom = getModelTrueBottom(obj)
                            if trueBottom ~= mhuge then
                                local deltaY = floorTop - trueBottom
                                if mabs(deltaY) < 500 then
                                    godMoveModel(obj, deltaY, false)
                                end
                            end
                        end
                    end
                    
                    -- UpgradeShop: zit iets te hoog, kleine extra neerwaartse offset
                    local upgradeShop = root:FindFirstChild("UpgradeShop")
                    if upgradeShop then
                        local trueBottom = getModelTrueBottom(upgradeShop)
                        if trueBottom ~= mhuge then
                            local deltaY = (floorTop - trueBottom) - 2  -- 2 studs extra omlaag
                            if mabs(deltaY) < 500 then
                                godMoveModel(upgradeShop, deltaY, false)
                            end
                        end
                    end

                    -- SpawnMachines (Sell machine, Wave machine, Spin wheel etc.)
                    local sm = root:FindFirstChild("SpawnMachines")
                    if sm then
                        for _, machine in pairs(sm:GetChildren()) do
                            local trueBottom = getModelTrueBottom(machine)
                            if trueBottom ~= mhuge then
                                local deltaY = floorTop - trueBottom
                                if mabs(deltaY) < 500 then
                                    godMoveModel(machine, deltaY, false)
                                end
                            end
                        end
                    end

                    -- Tower main
                    local tower = root:FindFirstChild("Tower")
                    if tower then
                        local main = tower:FindFirstChild("Main")
                        if main then
                            local trueBottom = getModelTrueBottom(main)
                            if trueBottom ~= mhuge then
                                local deltaY = floorTop - trueBottom
                                if mabs(deltaY) < 500 then
                                    godMoveModel(main, deltaY, false)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local function godRestoreStructures()
        if MzD._godMovedParts then
            for _, data in pairs(MzD._godMovedParts) do
                pcall(function()
                    if data.part and data.part.Parent then
                        data.part.CFrame = data.origCF
                    end
                end)
            end
        end
        MzD._godMovedParts = {}
        MzD._godMovedSet = {}
        MzD._baseDeltas = {}
    end

    -- ==========================================
    -- TELEPORT
    -- ==========================================
    local function godTeleportUnder()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = Player.Character:FindFirstChild("Humanoid")
        hrp.Velocity = Vector3.new(0,0,0)
        hrp.CFrame   = CFrame.new(hrp.Position.X, MzD.S.GodWalkY, hrp.Position.Z)
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Tripping, false)
                hum:ChangeState(Enum.HumanoidStateType.Running)
                hum.HipHeight = 0
            end)
        end
    end

    M.godTeleportUnder = godTeleportUnder
    M.godBuildEgaleVloer = godBuildEgaleVloer
    M.godDisableKillParts = godDisableKillParts

    -- ==========================================
    -- GOD LOOP (uit v28 + magneet van v29)
    -- ==========================================
    local function godStartLoop()
        if MzD._godLoopThread then pcall(tcancel, MzD._godLoopThread) end
        MzD._godLoopThread = tspawn(function()
            while MzD._isGod do
                pcall(function()
                    local ch  = Player.Character if not ch then return end
                    local hrp = ch:FindFirstChild("HumanoidRootPart")
                    local hum = ch:FindFirstChild("Humanoid")

                    -- Vloer blijven verbergen (resync elke 5 sec)
                    if tick() - MzD._godFloorCacheTime > 5 then
                        for _, data in pairs(MzD._godOriginalFloors or {}) do
                            if data.part and data.part.Parent then
                                data.part.CanCollide  = false
                                data.part.Transparency = 1
                            end
                        end
                        MzD._godFloorCacheTime = tick()
                    end

                    -- Actieve magneet: nieuwe brainrots op eigen base naar beneden
                    -- Zoek base via GUID of via naam
                    if workspace:FindFirstChild("Bases") then
                        local myBase = nil
                        if MzD.baseGUID then
                            myBase = workspace.Bases:FindFirstChild(MzD.baseGUID)
                        end
                        -- Fallback: zoek base op naam van de speler
                        if not myBase then
                            local pname = slower(Player.Name)
                            for _, b in pairs(workspace.Bases:GetChildren()) do
                                if sfind(slower(b.Name), pname) then
                                    myBase = b break
                                end
                            end
                        end

                        if myBase then
                            -- Als deze base nog geen delta heeft, bereken die nu
                            if not (MzD._baseDeltas and MzD._baseDeltas[myBase]) then
                                if MzD._baseDeltas then
                                    local floorTop = MzD.S.GodFloorY + 2
                                    -- Gebruik absolute laagste punt (zelfde als godLowerStructures)
                                    local trueBottom = getModelTrueBottom(myBase)
                                    if trueBottom ~= mhuge then
                                        local delta = floorTop - trueBottom
                                        if mabs(delta) < 500 then
                                            MzD._baseDeltas[myBase] = delta
                                            for _, d in pairs(myBase:GetDescendants()) do
                                                if d:IsA("BasePart") and not isMzDPart(d) and not MzD._godMovedSet[d] then
                                                    tinsert(MzD._godMovedParts, {part = d, origCF = d.CFrame})
                                                    MzD._godMovedSet[d] = true
                                                    pcall(function() d.CFrame = d.CFrame + Vector3.new(0, delta, 0) end)
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                -- Delta is al bekend, alleen nieuwe parts verplaatsen
                                local delta = MzD._baseDeltas[myBase]
                                for _, d in pairs(myBase:GetDescendants()) do
                                    if d:IsA("BasePart") and not isMzDPart(d) and not MzD._godMovedSet[d] then
                                        tinsert(MzD._godMovedParts, {part = d, origCF = d.CFrame})
                                        MzD._godMovedSet[d] = true
                                        pcall(function() d.CFrame = d.CFrame + Vector3.new(0, delta, 0) end)
                                    end
                                end
                            end
                        end
                    end

                    -- Humanoid states fix
                    if hum then
                        pcall(function()
                            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                            hum:SetStateEnabled(Enum.HumanoidStateType.Tripping, false)
                        end)
                        pcall(function()
                            local state = hum:GetState()
                            if state == Enum.HumanoidStateType.FallingDown
                            or state == Enum.HumanoidStateType.Ragdoll
                            or state == Enum.HumanoidStateType.Tripping then
                                hum:ChangeState(Enum.HumanoidStateType.Running)
                            end
                        end)
                    end

                    -- Val-catch
                    if hrp and hrp.Position.Y < MzD.S.GodWalkY - 30 then
                        hrp.Velocity = Vector3.new(0,0,0)
                        hrp.CFrame   = CFrame.new(hrp.Position.X, MzD.S.GodWalkY, hrp.Position.Z)
                    end
                end)
                twait(0.5)
            end
        end)
    end

    -- ==========================================
    -- HEALTH SETUP (uit v28)
    -- ==========================================
    local function godSetupHealth(char)
        if MzD._godHealthConn then pcall(function() MzD._godHealthConn:Disconnect() end) end
        if MzD._godDiedConn   then pcall(function() MzD._godDiedConn:Disconnect() end) end
        local hum = char:WaitForChild("Humanoid", 5) if not hum then return end
        pcall(function()
            hum.MaxHealth = mhuge hum.Health = mhuge
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Tripping, false)
            hum.HipHeight = 0
        end)
        for _, ff in pairs(char:GetChildren()) do if ff:IsA("ForceField") then ff:Destroy() end end
        local ff = Instance.new("ForceField") ff.Visible = false ff.Parent = char
        MzD._godHealthConn = hum:GetPropertyChangedSignal("Health"):Connect(function()
            if not MzD._isGod then return end
            pcall(function() if hum.Health ~= mhuge then hum.Health = mhuge end end)
        end)
        MzD._godDiedConn = hum.Died:Connect(function()
            if not MzD._isGod then return end
            tdefer(function()
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    hum.MaxHealth = mhuge hum.Health = mhuge
                end)
            end)
        end)
    end
    M.godSetupHealth = godSetupHealth

    -- ==========================================
    -- ENABLE / DISABLE
    -- ==========================================
    function MzD.enableGod()
        if MzD._isGod then return end
        MzD._isGod = true MzD.S.GodEnabled = true MzD._godFloorCacheTime = 0
        local killCount = godDisableKillParts()
        godStartKillWatcher()
        twait(0.1)
        local map = godHideOriginalFloors()
        twait(0.1)
        godLowerStructures()
        twait(0.1)
        godBuildEgaleVloer(map)
        twait(0.2)
        godStartLoop()
        twait(0.1)
        godTeleportUnder()
        twait(0.1)
        if Player.Character then godSetupHealth(Player.Character) end
        MzD.Status.god = "Aan (Y="..MzD.S.GodWalkY.." K:"..killCount.." NanoVloer)"
    end

    function MzD.disableGod()
        MzD._isGod = false MzD.S.GodEnabled = false
        if MzD._godLoopThread      then pcall(tcancel, MzD._godLoopThread)       MzD._godLoopThread = nil end
        if MzD._godKillWatchThread then pcall(tcancel, MzD._godKillWatchThread)  MzD._godKillWatchThread = nil end
        if MzD._godHealthConn      then pcall(function() MzD._godHealthConn:Disconnect() end) MzD._godHealthConn = nil end
        if MzD._godDiedConn        then pcall(function() MzD._godDiedConn:Disconnect()   end) MzD._godDiedConn = nil end
        godRestoreFloors()
        godRestoreStructures()
        godRestoreKillParts()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Velocity = Vector3.new(0,0,0) hrp.CFrame = CFrame.new(hrp.Position.X, 10, hrp.Position.Z) end
        local ch = Player.Character
        if ch then
            for _, ff2 in pairs(ch:GetChildren()) do if ff2:IsA("ForceField") then ff2:Destroy() end end
            local hum = ch:FindFirstChild("Humanoid")
            if hum then
                pcall(function()
                    hum.MaxHealth = 100 hum.Health = 100
                    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                end)
            end
        end
        MzD.Status.god = "Uit"
    end
end

return M
