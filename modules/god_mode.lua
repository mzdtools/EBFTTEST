-- ============================================
-- [MODULE 10] GOD MODE - REVERSE EDITION (v33 fixed)
-- Nano-vloer op natuurlijke hoogte van de map.
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
    -- VLOER HOOGTE = dropdown waarde (GodFloorY)
    -- Bovenkant nanovloer = GodFloorY + 2
    -- ==========================================
    local function getMapNaturalY()
        return MzD.S.GodFloorY + 2
    end

    -- ==========================================
    -- MAP X-RANGE BEPALEN
    -- ==========================================
    local function godDetectMapXRange(map)
        local minX, maxX = -50, 4500
        if map then
            minX, maxX = mhuge, -mhuge
            for _, d in pairs(map:GetDescendants()) do
                if d:IsA("BasePart") and not isMzDPart(d) and d.Position.Y < 50 and d.Position.Y > -30 then
                    local l = d.Position.X - d.Size.X/2
                    local r = d.Position.X + d.Size.X/2
                    if l < minX then minX = l end
                    if r > maxX then maxX = r end
                end
            end
            if maxX <= minX then minX, maxX = -50, 4500 end
        end
        return minX-20, maxX+20
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

    -- Bereken de X/Z bounds van alle bases samen
    local function getBaseBounds()
        local minX, maxX, minZ, maxZ = mhuge, -mhuge, mhuge, -mhuge
        if workspace:FindFirstChild("Bases") then
            for _, b in pairs(workspace.Bases:GetChildren()) do
                for _, d in pairs(b:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local x1 = d.Position.X - d.Size.X/2
                        local x2 = d.Position.X + d.Size.X/2
                        local z1 = d.Position.Z - d.Size.Z/2
                        local z2 = d.Position.Z + d.Size.Z/2
                        if x1 < minX then minX = x1 end
                        if x2 > maxX then maxX = x2 end
                        if z1 < minZ then minZ = z1 end
                        if z2 > maxZ then maxZ = z2 end
                    end
                end
            end
        end
        if minX == mhuge then return nil end
        return {minX=minX-5, maxX=maxX+5, minZ=minZ-5, maxZ=maxZ+5}
    end

    local function godHideOriginalFloors()
        local floors, map = godFindFloorParts()
        local baseBounds = getBaseBounds()
        MzD._godOriginalFloors = {}
        for _, p in pairs(floors) do
            -- Skip vloer parts die ONDER een base liggen - die hebben we nodig voor brainrots
            if baseBounds then
                local px = p.Position.X
                local pz = p.Position.Z
                if px >= baseBounds.minX and px <= baseBounds.maxX
                and pz >= baseBounds.minZ and pz <= baseBounds.maxZ then
                    continue -- Laat deze vloer staan
                end
            end
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
    -- KILL PARTS UITSCHAKELEN
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
    -- NANO VLOER BOUWEN
    -- Bovenkant vloer = naturalY (bovenkant Floor1 = waar brainrots op staan)
    -- ==========================================
    local function godBuildEgaleVloer(map)
        for _, p in pairs(MzD._godCreatedParts or {}) do pcall(function() if p then p:Destroy() end end) end
        MzD._godCreatedParts = {}

        local startX, endX = godDetectMapXRange(map)
        local naturalY = getMapNaturalY()  -- bovenkant Floor1

        local floorWidth = 420
        local floorThick = 4
        local theme = getThemeColors(MzD)

        local segLen = mabs(endX - startX)
        local centerX = (startX + endX) / 2

        -- Bovenkant van nanovloer = naturalY, center = naturalY - floorThick/2
        local floorCenterY = naturalY - (floorThick / 2)

        local floor = Instance.new("Part")
        floor.Name = "MzDNanoFloor"
        floor.Size = Vector3.new(segLen, floorThick, floorWidth)
        floor.Position = Vector3.new(centerX, floorCenterY, 0)
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

        local topY = floorCenterY + floorThick/2 + 0.1
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
        local wallY = floorCenterY + (floorThick / 2) + (wallHeight / 2)
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

        local catch = Instance.new("Part")
        catch.Name = "MzDGodCatchFloor"
        catch.Size = Vector3.new(segLen + 200, 2, floorWidth + 100)
        catch.Position = Vector3.new(centerX, floorCenterY - 15, 0)
        catch.Anchored = true catch.CanCollide = true catch.Transparency = 1
        catch.Parent = workspace
        tinsert(MzD._godCreatedParts, catch)

        -- WalkY = bovenkant nanovloer + kleine offset zodat speler er netjes op staat
        MzD._actualGodWalkY = naturalY + 3
        return true
    end

    -- ==========================================
    -- TELEPORT EN LOOPS
    -- ==========================================
    local function godTeleportUnder()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = Player.Character:FindFirstChild("Humanoid")
        hrp.Velocity = Vector3.new(0,0,0)
        local targetY = MzD._actualGodWalkY or MzD.S.GodWalkY
        hrp.CFrame = CFrame.new(hrp.Position.X, targetY, hrp.Position.Z)
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

                    -- Verberg originele vloeren periodiek
                    if tick() - MzD._godFloorCacheTime > 5 then
                        for _, data in pairs(MzD._godOriginalFloors or {}) do
                            if data.part and data.part.Parent then
                                data.part.CanCollide  = false
                                data.part.Transparency = 1
                            end
                        end
                        MzD._godFloorCacheTime = tick()
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

                    local walkY = MzD._actualGodWalkY or MzD.S.GodWalkY
                    local catchY = walkY - 30
                    if hrp and hrp.Position.Y < catchY then
                        hrp.Velocity = Vector3.new(0,0,0)
                        hrp.CFrame = CFrame.new(hrp.Position.X, walkY, hrp.Position.Z)
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

    M.godTeleportUnder  = godTeleportUnder
    M.godBuildEgaleVloer = godBuildEgaleVloer
    M.godDisableKillParts = godDisableKillParts
    M.godSetupHealth    = godSetupHealth

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
        godBuildEgaleVloer(map)
        twait(0.2)
        godStartLoop()
        twait(0.1)
        godTeleportUnder()
        twait(0.1)
        if Player.Character then godSetupHealth(Player.Character) end
        MzD.Status.god = "Aan (Reverse Mode K:"..killCount..")"
    end

    function MzD.reapplyGodFloor()
        if not MzD._isGod then return end
        godRestoreFloors()
        for _, p in pairs(MzD._godCreatedParts or {}) do pcall(function() if p then p:Destroy() end end) end
        MzD._godCreatedParts = {}
        local map = godHideOriginalFloors()
        twait(0.05)
        godBuildEgaleVloer(map)
        twait(0.05)
        godTeleportUnder()
    end

    function MzD.disableGod()
        MzD._isGod = false MzD.S.GodEnabled = false
        if MzD._godLoopThread      then pcall(tcancel, MzD._godLoopThread)       MzD._godLoopThread = nil end
        if MzD._godKillWatchThread then pcall(tcancel, MzD._godKillWatchThread)  MzD._godKillWatchThread = nil end
        if MzD._godHealthConn      then pcall(function() MzD._godHealthConn:Disconnect() end) MzD._godHealthConn = nil end
        if MzD._godDiedConn        then pcall(function() MzD._godDiedConn:Disconnect()   end) MzD._godDiedConn = nil end
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
