-- ============================================
-- [MODULE 10] GOD MODE - NANO EDITION (v35)
-- Fixes: Jouw GodFloorY instelling is weer de baas!
-- Gebruikt PivotTo() om modellen als één onbreekbaar
-- geheel te verplaatsen. Inclusief Oneindige Grid Vloer.
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
    -- MAP X EN Z RANGE BEPALEN (De Oneindige Wereld)
    -- ==========================================
    local function godDetectMapRange()
        local minX, maxX = mhuge, -mhuge
        local minZ, maxZ = mhuge, -mhuge
        local function chk(d)
            if d:IsA("BasePart") and not isMzDPart(d) and d.Position.Y < 200 and d.Position.Y > -100 then
                local lx = d.Position.X - d.Size.X/2
                local rx = d.Position.X + d.Size.X/2
                local lz = d.Position.Z - d.Size.Z/2
                local rz = d.Position.Z + d.Size.Z/2
                if lx < minX then minX = lx end
                if rx > maxX then maxX = rx end
                if lz < minZ then minZ = lz end
                if rz > maxZ then maxZ = rz end
            end
        end
        pcall(function()
            local folders = {workspace:FindFirstChild("Map"), workspace:FindFirstChild("Bases"), workspace:FindFirstChild("GameObjects")}
            for _, f in pairs(folders) do
                if f then for _, d in pairs(f:GetDescendants()) do chk(d) end end
            end
        end)
        
        if maxX <= minX then minX, maxX = -2000, 2000 end
        if maxZ <= minZ then minZ, maxZ = -2000, 2000 end
        
        return minX - 1000, maxX + 1000, minZ - 1000, maxZ + 1000
    end

    -- ==========================================
    -- VLOEREN VERBERGEN
    -- ==========================================
    local function godFindFloorParts()
        local floors, map = {}, nil
        for _, c in pairs(workspace:GetChildren()) do
            if c:IsA("Model") and sfind(c.Name,"Map")
               and not sfind(c.Name,"SharedInstances") and not sfind(c.Name,"VFX") then
                map = c break
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
        end
        for _, c in pairs(workspace:GetChildren()) do
            if sfind(c.Name,"SharedInstances") then
                for _, f in pairs(c:GetDescendants()) do
                    if f:IsA("BasePart") and not isMzDPart(f)
                       and f.Size.X > 15 and f.Size.Z > 5 and f.Size.Y < 20
                       and f.Position.Y > -10 and f.Position.Y < 30 then
                        tinsert(floors, f)
                    end
                end
            end
        end
        return floors, map
    end

    local function godHideOriginalFloors()
        local floors, map = godFindFloorParts()
        MzD._godOriginalFloors = {}
        for _, p in pairs(floors) do
            tinsert(MzD._godOriginalFloors, {
                part = p, canCollide = p.CanCollide, transparency = p.Transparency,
            })
            pcall(function() p.CanCollide = false p.Transparency = 1 end)
        end
        return map
    end

    local function godRestoreFloors()
        for _, data in pairs(MzD._godOriginalFloors or {}) do
            pcall(function()
                if data.part and data.part.Parent then
                    data.part.CanCollide = data.canCollide
                    data.part.Transparency = data.transparency
                end
            end)
        end
        MzD._godOriginalFloors = {}
    end

    -- ==========================================
    -- KILL PARTS
    -- ==========================================
    local function godDisableKillParts()
        MzD._godKillParts = {}
        for _, c in pairs(workspace:GetDescendants()) do
            if c:IsA("BasePart") and not isMzDPart(c) then
                local isKill = false
                pcall(function()
                    if c.Size.Y < 1 and c.Size.Z > 50 and c.Position.Y < 5 and c.Position.Y > -5 then isKill = true end
                end)
                local n = slower(c.Name)
                if sfind(n,"kill") or sfind(n,"death") or sfind(n,"damage") then isKill = true end
                
                if isKill then
                    tinsert(MzD._godKillParts, {
                        part = c, canCollide = c.CanCollide, canTouch = c.CanTouch,
                        size = c.Size, position = c.Position, transparency = c.Transparency,
                    })
                    pcall(function()
                        c.CanCollide = false c.CanTouch = false c.Transparency = 1
                        c.Position = Vector3.new(0,-9999,0)
                    end)
                end
            end
        end
        return #MzD._godKillParts
    end

    local function godRestoreKillParts()
        for _, data in pairs(MzD._godKillParts or {}) do
            pcall(function()
                if data.part and data.part.Parent then
                    data.part.Size = data.size data.part.Position = data.position
                    data.part.CanCollide = data.canCollide data.part.CanTouch = data.canTouch
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
                            data.part.Position = Vector3.new(0,-9999,0)
                        end
                    end
                end)
                twait(3)
            end
        end)
    end

    -- ==========================================
    -- GIGANTISCHE NANO VLOER OP JOUW GodFloorY
    -- ==========================================
    local function godBuildEgaleVloer()
        for _, p in pairs(MzD._godCreatedParts or {}) do pcall(function() if p then p:Destroy() end end) end
        MzD._godCreatedParts = {}
        
        local minX, maxX, minZ, maxZ = godDetectMapRange()
        local floorY = MzD.S.GodFloorY
        local floorThick = 4
        
        -- Zorgt ervoor dat de BOVENKANT van de vloer precies op GodFloorY ligt +2 (4 dik)
        local floorCenterY = floorY
        local theme = getThemeColors(MzD)

        local maxSeg = 2000
        for cx = minX, maxX, maxSeg do
            for cz = minZ, maxZ, maxSeg do
                local sx = mmin(maxSeg, maxX - cx)
                local sz = mmin(maxSeg, maxZ - cz)
                
                if sx > 0 and sz > 0 then
                    local px = cx + (sx / 2)
                    local pz = cz + (sz / 2)
                    
                    local floor = Instance.new("Part")
                    floor.Name = "MzDNanoFloor"
                    floor.Size = Vector3.new(sx, floorThick, sz)
                    floor.Position = Vector3.new(px, floorCenterY, pz)
                    floor.Anchored = true floor.CanCollide = true
                    floor.Color = Color3.fromRGB(15, 15, 15)
                    floor.Material = Enum.Material.Glass
                    floor.Transparency = 0.1
                    floor.Reflectance = 0.3
                    floor.Parent = workspace
                    tinsert(MzD._godCreatedParts, floor)

                    local light = Instance.new("SurfaceLight")
                    light.Color = theme.stripe
                    light.Brightness = 2
                    light.Range = 20
                    light.Face = Enum.NormalId.Top
                    light.Angle = 180
                    light.Parent = floor

                    buildSurfaceGui(floor, Enum.NormalId.Top, theme)
                end
            end
        end
        return true
    end

    -- ==========================================
    -- STRUCTUREN VERLAGEN (PivotTo Methode)
    -- ==========================================
    local function getModelTrueBottom(model)
        local fallbackLowest = mhuge
        local bestPart = nil
        local highestScore = -mhuge

        for _, d in pairs(model:GetDescendants()) do
            if d:IsA("BasePart") and not isMzDPart(d) then
                local n = slower(d.Name)
                local bottom = d.Position.Y - (d.Size.Y / 2)
                
                if sfind(n, "radius") or sfind(n, "roof") or sfind(n, "ceiling") or sfind(n, "sky") then continue end
                if d.Position.Y > 200 then continue end
                
                if bottom < fallbackLowest then fallbackLowest = bottom end
                
                local area = d.Size.X * d.Size.Z
                if d.Size.Y < 10 and area > 10 then
                    local score = area
                    if sfind(n, "floor") or sfind(n, "ground") or sfind(n, "base") or sfind(n, "pad") then
                        score = score + 10000
                    end
                    score = score - (d.Position.Y * 10)
                    
                    if score > highestScore then
                        highestScore = score
                        bestPart = d
                    end
                end
            end
        end
        
        if bestPart then
            return bestPart.Position.Y - (bestPart.Size.Y / 2)
        end
        return fallbackLowest
    end

    local function getBaseFloorBottom(base)
        local floor1 = base:FindFirstChild("Floor1")
        if floor1 then
            local lowestBottom = mhuge
            for _, d in pairs(floor1:GetDescendants()) do
                if d:IsA("BasePart") and not isMzDPart(d) then
                    local bottom = d.Position.Y - d.Size.Y / 2
                    if bottom < lowestBottom then lowestBottom = bottom end
                end
            end
            if lowestBottom ~= mhuge then return lowestBottom end
        end

        local slots = base:FindFirstChild("Slots")
        if slots then
            local lowestY = mhuge
            for _, s in pairs(slots:GetChildren()) do
                local pp = s.PrimaryPart or s:FindFirstChildWhichIsA("BasePart")
                if pp and pp.Position.Y < lowestY then lowestY = pp.Position.Y end
            end
            if lowestY ~= mhuge then return lowestY - 2 end
        end
        return getModelTrueBottom(base)
    end

    -- PivotTo is de magie: verplaatst een heel gebouw of poppetje als één object
    local function godMoveSafely(obj, deltaY)
        if not obj or MzD._godMovedSet[obj] then return end

        if obj:IsA("Model") then
            local cp = obj:GetPivot()
            tinsert(MzD._godMovedParts, {model = obj, origPivot = cp})
            MzD._godMovedSet[obj] = true
            pcall(function() obj:PivotTo(cp + Vector3.new(0, deltaY, 0)) end)
            
            -- Markeer alle descendants zodat we ze niet per ongeluk in stukken scheuren
            for _, d in pairs(obj:GetDescendants()) do
                MzD._godMovedSet[d] = true
            end
            return
        end

        if obj:IsA("BasePart") and not isMzDPart(obj) then
            tinsert(MzD._godMovedParts, {part = obj, origCF = obj.CFrame})
            MzD._godMovedSet[obj] = true
            pcall(function() obj.CFrame = obj.CFrame + Vector3.new(0, deltaY, 0) end)
            return
        end

        -- Als het een map/folder is, ga naar binnen
        for _, child in pairs(obj:GetChildren()) do
            godMoveSafely(child, deltaY)
        end
    end

    local function godLowerStructures()
        MzD._godMovedParts = {}
        MzD._godMovedSet = {}
        MzD._baseDeltas = {}

        local floorTop = MzD.S.GodFloorY + 2 

        -- 1. ALLE BASES
        if workspace:FindFirstChild("Bases") then
            for _, base in pairs(workspace.Bases:GetChildren()) do
                local trueBottom = getBaseFloorBottom(base)
                if trueBottom ~= mhuge then
                    local deltaY = floorTop - trueBottom
                    if mabs(deltaY) < 500 then
                        MzD._baseDeltas[base] = deltaY
                        godMoveSafely(base, deltaY)
                    end
                end
            end
        end

        -- 2. WORKSPACE OBJECTEN (Shops, Wheels, etc)
        local function tryMoveWorkspaceObj(name)
            local obj = workspace:FindFirstChild(name)
            if not obj then return end
            local trueBottom = getModelTrueBottom(obj)
            if trueBottom == mhuge then return end
            local deltaY = floorTop - trueBottom
            if mabs(deltaY) < 500 then godMoveSafely(obj, deltaY) end
        end

        tryMoveWorkspaceObj("DoomWheel")
        tryMoveWorkspaceObj("LimitedShop")
        tryMoveWorkspaceObj("FireAndIceWheel")
        tryMoveWorkspaceObj("DivineLuckyBlockPad")
        tryMoveWorkspaceObj("MysteryMerchant")

        for _, c in pairs(workspace:GetChildren()) do
            if c:IsA("Model") and c.Name == "Model" then
                local isMerchant = false
                for _, d in pairs(c:GetDescendants()) do
                    if sfind(slower(d.Name), "merchant") or sfind(slower(d.Name), "mystery") then
                        isMerchant = true break
                    end
                end
                if isMerchant then
                    local trueBottom = getModelTrueBottom(c)
                    if trueBottom ~= mhuge then
                        local deltaY = floorTop - trueBottom
                        if mabs(deltaY) < 500 then godMoveSafely(c, deltaY) end
                    end
                end
            end
        end

        -- 3. GAME OBJECTS
        local go = workspace:FindFirstChild("GameObjects")
        if go then
            local ps = go:FindFirstChild("PlaceSpecific", true)
            if ps then
                local root = ps:FindFirstChild("root")
                if root then
                    local trueBottomTargets = {"MysteryMerchant", "SiteEventDetails", "PlazaPortal", "SellStand", "UpgradeShop"}
                    for _, name in pairs(trueBottomTargets) do
                        local obj = root:FindFirstChild(name)
                        if obj then
                            local trueBottom = getModelTrueBottom(obj)
                            if trueBottom ~= mhuge then
                                local deltaY = floorTop - trueBottom
                                if mabs(deltaY) < 500 then godMoveSafely(obj, deltaY) end
                            end
                        end
                    end
                    
                    local sm = root:FindFirstChild("SpawnMachines")
                    if sm then
                        for _, machine in pairs(sm:GetChildren()) do
                            local trueBottom = getModelTrueBottom(machine)
                            if trueBottom ~= mhuge then
                                local deltaY = floorTop - trueBottom
                                if mabs(deltaY) < 500 then godMoveSafely(machine, deltaY) end
                            end
                        end
                    end

                    local tower = root:FindFirstChild("Tower")
                    if tower then
                        local main = tower:FindFirstChild("Main")
                        if main then
                            local trueBottom = getModelTrueBottom(main)
                            if trueBottom ~= mhuge then
                                local deltaY = floorTop - trueBottom
                                if mabs(deltaY) < 500 then godMoveSafely(main, deltaY) end
                            end
                        end
                    end
                end
            end
        end
    end

    local function godRestoreStructures()
        for _, data in pairs(MzD._godMovedParts or {}) do
            pcall(function()
                if data.model and data.model.Parent then
                    data.model:PivotTo(data.origPivot)
                elseif data.part and data.part.Parent then
                    data.part.CFrame = data.origCF
                end
            end)
        end
        MzD._godMovedParts = {}
        MzD._godMovedSet = {}
        MzD._baseDeltas = {}
    end

    -- ==========================================
    -- TELEPORT EN LOOPS
    -- ==========================================
    local function godTeleportUnder()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = Player.Character:FindFirstChild("Humanoid")
        hrp.Velocity = Vector3.new(0,0,0)
        hrp.CFrame = CFrame.new(hrp.Position.X, MzD.S.GodWalkY, hrp.Position.Z)
        
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

    local function godStartLoop()
        if MzD._godLoopThread then pcall(tcancel, MzD._godLoopThread) end
        MzD._godLoopThread = tspawn(function()
            while MzD._isGod do
                pcall(function()
                    local ch  = Player.Character if not ch then return end
                    local hrp = ch:FindFirstChild("HumanoidRootPart")
                    local hum = ch:FindFirstChild("Humanoid")

                    if tick() - MzD._godFloorCacheTime > 5 then
                        for _, data in pairs(MzD._godOriginalFloors or {}) do
                            if data.part and data.part.Parent then
                                data.part.CanCollide  = false
                                data.part.Transparency = 1
                            end
                        end
                        MzD._godFloorCacheTime = tick()
                    end

                    -- MAGNEET: Nieuwe brainrots scannen en veilig piverten
                    if workspace:FindFirstChild("Bases") then
                        local myBase = nil
                        if MzD.baseGUID then
                            myBase = workspace.Bases:FindFirstChild(MzD.baseGUID)
                        end
                        
                        if not myBase and MzD._baseDeltas then
                            local bestBase, bestCount = nil, 0
                            for b, _ in pairs(MzD._baseDeltas) do
                                if b and b.Parent then
                                    local newCount = 0
                                    for _, d in pairs(b:GetDescendants()) do
                                        if d:IsA("BasePart") and not MzD._godMovedSet[d] then
                                            newCount += 1
                                        end
                                    end
                                    if newCount > bestCount then bestCount = newCount bestBase = b end
                                end
                            end
                            if bestBase and bestCount > 0 then myBase = bestBase end
                        end

                        if myBase then
                            local delta = MzD._baseDeltas and MzD._baseDeltas[myBase]
                            if delta then
                                for _, child in pairs(myBase:GetChildren()) do
                                    if not MzD._godMovedSet[child] then
                                        godMoveSafely(child, delta)
                                    end
                                end
                                -- Kijk ook specifiek in de Slots map voor nieuwe pets/brainrots
                                local slotsDir = myBase:FindFirstChild("Slots")
                                if slotsDir then
                                    for _, child in pairs(slotsDir:GetChildren()) do
                                        if not MzD._godMovedSet[child] then
                                            godMoveSafely(child, delta)
                                        end
                                    end
                                end
                            end
                        end
                    end

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

                    if hrp and hrp.Position.Y < MzD.S.GodWalkY - 30 then
                        hrp.Velocity = Vector3.new(0,0,0)
                        hrp.CFrame   = CFrame.new(hrp.Position.X, MzD.S.GodWalkY, hrp.Position.Z)
                    end
                end)
                twait(0.5)
            end
        end)
    end

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
    
    M.godTeleportUnder = godTeleportUnder
    M.godBuildEgaleVloer = godBuildEgaleVloer
    M.godDisableKillParts = godDisableKillParts
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
        godHideOriginalFloors()
        twait(0.1)
        godLowerStructures()
        twait(0.1)
        godBuildEgaleVloer()
        twait(0.2)
        godStartLoop()
        twait(0.1)
        godTeleportUnder()
        twait(0.1)
        if Player.Character then godSetupHealth(Player.Character) end
        MzD.Status.god = "Aan (Y="..MzD.S.GodWalkY.." PivotMode)"
    end

    function MzD.reapplyGodFloor()
        if not MzD._isGod then return end
        godRestoreStructures()
        godRestoreFloors()
        for _, p in pairs(MzD._godCreatedParts or {}) do pcall(function() if p then p:Destroy() end end) end
        MzD._godCreatedParts = {}
        
        twait(0.05)
        godHideOriginalFloors()
        twait(0.05)
        godLowerStructures()
        twait(0.05)
        godBuildEgaleVloer()
        twait(0.05)
        godTeleportUnder()
        MzD.Status.god = "Aan (Y="..MzD.S.GodWalkY.." PivotMode)"
    end

    function MzD.disableGod()
        MzD._isGod = false MzD.S.GodEnabled = false
        if MzD._godLoopThread      then pcall(tcancel, MzD._godLoopThread)       MzD._godLoopThread = nil end
        if MzD._godKillWatchThread then pcall(tcancel, MzD._godKillWatchThread)  MzD._godKillWatchThread = nil end
        if MzD._godHealthConn      then pcall(function() MzD._godHealthConn:Disconnect() end) MzD._godHealthConn = nil end
        if MzD._godDiedConn        then pcall(function() MzD._godDiedConn:Disconnect()   end) MzD._godDiedConn = nil end
        godRestoreStructures()
        godRestoreFloors()
        godRestoreKillParts()
        for _, p in pairs(MzD._godCreatedParts or {}) do pcall(function() if p then p:Destroy() end end) end
        MzD._godCreatedParts = {}
        
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
