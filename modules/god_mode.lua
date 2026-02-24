-- ============================================
-- [MODULE 10] GOD MODE
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
        for _, data in pairs(MzD._godKillParts) do
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

    local function godBuildEgaleVloer(map)
        for _, p in pairs(MzD._godCreatedParts) do
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
            floor.Name         = "MzDGodFloor"
            floor.Size         = Vector3.new(segLen, floorThick, floorWidth)
            floor.Position     = Vector3.new(centerX, floorY, 0)
            floor.Anchored     = true floor.CanCollide = true
            floor.Color        = theme.floor floor.Material = Enum.Material.SmoothPlastic
            floor.Transparency = 0
            floor.TopSurface   = Enum.SurfaceType.Smooth floor.BottomSurface = Enum.SurfaceType.Smooth
            floor.Parent       = workspace
            tinsert(MzD._godCreatedParts, floor)

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
        for _, data in pairs(MzD._godOriginalFloors) do
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
        for _, f in pairs(MzD._godCreatedParts) do
            pcall(function() if f and f.Parent then f:Destroy() end end)
        end
        MzD._godCreatedParts = {}
    end

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
    -- Expose for external use (GUI buttons, respawn handler)
    M.godTeleportUnder = godTeleportUnder
    M.godBuildEgaleVloer = godBuildEgaleVloer
    M.godDisableKillParts = godDisableKillParts

    local function godStartLoop()
        if MzD._godLoopThread then pcall(tcancel, MzD._godLoopThread) end
        MzD._godLoopThread = tspawn(function()
            while MzD._isGod do
                pcall(function()
                    local ch  = Player.Character if not ch then return end
                    local hrp = ch:FindFirstChild("HumanoidRootPart")
                    local hum = ch:FindFirstChild("Humanoid")
                    if tick() - MzD._godFloorCacheTime > 5 then
                        for _, data in pairs(MzD._godOriginalFloors) do
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
    M.godSetupHealth = godSetupHealth

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
        MzD.Status.god = "Aan (Y="..MzD.S.GodWalkY.." K:"..killCount.." V:"..#MzD._godCreatedParts..")"
    end

    function MzD.disableGod()
        MzD._isGod = false MzD.S.GodEnabled = false
        if MzD._godLoopThread      then pcall(tcancel, MzD._godLoopThread)       MzD._godLoopThread = nil end
        if MzD._godKillWatchThread then pcall(tcancel, MzD._godKillWatchThread)  MzD._godKillWatchThread = nil end
        if MzD._godHealthConn      then pcall(function() MzD._godHealthConn:Disconnect() end) MzD._godHealthConn = nil end
        if MzD._godDiedConn        then pcall(function() MzD._godDiedConn:Disconnect()   end) MzD._godDiedConn = nil end
        godRestoreFloors()
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
