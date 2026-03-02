-- ============================================
-- [MODULE 10] GOD MODE - REVERSE EDITION (v34)
-- Fixes: Oneindige Nano-Vloer. Berekent nu de X én Z 
-- as van de hele map + bases, zodat je base nooit 
-- meer buiten de glazen vloer kan vallen.
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
    local mhuge   = G.mhuge
    local mmin    = G.mmin
    local isMzDPart       = Modules.utility.isMzDPart
    local getThemeColors  = Modules.wall_themes.getThemeColors
    local buildSurfaceGui = Modules.utility.buildSurfaceGui

    -- ==========================================
    -- NATUURLIJKE HOOGTE BEPALEN (Top van de vloer)
    -- ==========================================
    local function getMapNaturalTopY()
        -- We pakken exact de Y positie van Slot 1 zodat de glazen vloer daar superstrak onder ligt
        if workspace:FindFirstChild("Bases") then
            for _, b in pairs(workspace.Bases:GetChildren()) do
                local slots = b:FindFirstChild("Slots")
                if slots then
                    for _, s in pairs(slots:GetChildren()) do
                        local pp = s.PrimaryPart or s:FindFirstChildWhichIsA("BasePart")
                        if pp then
                            return pp.Position.Y - 0.2 -- Net onder het voetstuk
                        end
                    end
                end
            end
        end
        return 0 -- Fallback
    end

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
        
        -- Fallbacks voor als de scan faalt
        if maxX <= minX then minX, maxX = -2000, 2000 end
        if maxZ <= minZ then minZ, maxZ = -2000, 2000 end
        
        -- Ruime extra padding zodat de vloer onzichtbaar ver doorloopt (Nooit meer afgronden)
        return minX - 1000, maxX + 1000, minZ - 1000, maxZ + 1000
    end

    -- ==========================================
    -- VLOEREN VERBERGEN (Originele map weghalen)
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
    -- GIGANTISCHE NANO VLOER BOUWEN
    -- ==========================================
    local function godBuildEgaleVloer()
        for _, p in pairs(MzD._godCreatedParts or {}) do pcall(function() if p then p:Destroy() end end) end
        MzD._godCreatedParts = {}
        
        local minX, maxX, minZ, maxZ = godDetectMapRange()
        local naturalTopY = getMapNaturalTopY()
        
        local floorThick = 4
        local floorCenterY = naturalTopY - (floorThick / 2)
        local theme = getThemeColors(MzD)

        -- Roblox laat geen Parts toe groter dan 2048, dus we bouwen een grid van gigantische platen
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

                    -- Geeft elke tegel dat gave neon grid uiterlijk
                    buildSurfaceGui(floor, Enum.NormalId.Top, theme)
                end
            end
        end

        MzD._actualGodWalkY = naturalTopY + 3
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

                    local catchY = (MzD._actualGodWalkY or MzD.S.GodWalkY) - 30
                    if hrp and hrp.Position.Y < catchY then
                        hrp.Velocity = Vector3.new(0,0,0)
                        hrp.CFrame   = CFrame.new(hrp.Position.X, MzD._actualGodWalkY or MzD.S.GodWalkY, hrp.Position.Z)
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
        godBuildEgaleVloer()
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
        
        twait(0.05)
        godHideOriginalFloors()
        twait(0.05)
        godBuildEgaleVloer()
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
