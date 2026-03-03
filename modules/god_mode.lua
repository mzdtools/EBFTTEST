-- ============================================
-- [MODULE 10] GOD MODE
-- ============================================
local M = {}

function M.init(Modules)
    local G               = Modules.globals
    local MzD             = G.MzD
    local Player          = G.Player
    local tinsert         = G.tinsert
    local tspawn          = G.tspawn
    local twait           = G.twait
    local tcancel         = G.tcancel
    local tdefer          = G.tdefer
    local mabs            = G.mabs
    local mhuge           = G.mhuge
    local mmin            = G.mmin
    local isMzDPart       = Modules.utility.isMzDPart
    local getThemeColors  = Modules.wall_themes.getThemeColors
    local buildSurfaceGui = Modules.utility.buildSurfaceGui

    -- ============================================
    -- CONFIGURATIE
    -- ============================================
    local CONFIG = {
        FLOOR_WIDTH          = 420,
        FLOOR_THICKNESS      = 4,
        CATCH_FLOOR_PADDING  = 200,
        CATCH_FLOOR_OFFSET_Y = -15,
        MAX_SEGMENT_LENGTH   = 2000,
        STRUCTURE_OFFSET_Y   = 3.5,
        STRUCTURE_MAX_DELTA  = 300,   -- max toegestane deltaY bij structuren
        FALL_MARGIN          = 30,
        FLOOR_RECHECK_SECS   = 5,
        LOOP_INTERVAL        = 0.5,
    }

    -- ============================================
    -- HELPER: GameObjects.PlaceSpecific.root
    -- Gedeeld via map_utils als MzD.mapGetGameObjectsRoot()
    -- ============================================

    local function findGameObjectsRoot()
        return MzD.mapGetGameObjectsRoot and MzD.mapGetGameObjectsRoot()
    end

    -- ============================================
    -- KILL PARTS
    -- ============================================

    local function disableKillPart(part)
        tinsert(MzD._godKillParts, {
            part         = part,
            canCollide   = part.CanCollide,
            canTouch     = part.CanTouch,
            size         = part.Size,
            position     = part.Position,
            transparency = part.Transparency,
        })
        pcall(function()
            part.CanCollide   = false
            part.CanTouch     = false
            part.Transparency = 1
            part.Size         = Vector3.new(0, 0, 0)
            part.Position     = Vector3.new(0, -9999, 0)
        end)
    end

    local function disableAllKillParts()
        MzD._godKillParts = {}
        local seen        = {}
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not seen[part] and MzD.mapIsKillPart(part) then
                seen[part] = true
                disableKillPart(part)
            end
        end
        return #MzD._godKillParts
    end

    local function restoreKillParts()
        for _, data in ipairs(MzD._godKillParts) do
            pcall(function()
                if data.part and data.part.Parent then
                    data.part.Size         = data.size
                    data.part.Position     = data.position
                    data.part.CanCollide   = data.canCollide
                    data.part.CanTouch     = data.canTouch
                    data.part.Transparency = data.transparency
                end
            end)
        end
        MzD._godKillParts = {}
    end

    local function reapplyKillPartDisable()
        for _, data in ipairs(MzD._godKillParts) do
            if data.part and data.part.Parent then
                pcall(function()
                    data.part.CanCollide = false
                    data.part.CanTouch   = false
                    data.part.Size       = Vector3.new(0, 0, 0)
                    data.part.Position   = Vector3.new(0, -9999, 0)
                end)
            end
        end
    end

    local function startKillPartWatcher()
        if MzD._godKillWatchConn then
            pcall(function() MzD._godKillWatchConn:Disconnect() end)
        end
        local knownParts = {}
        for _, data in ipairs(MzD._godKillParts) do
            knownParts[data.part] = true
        end
        MzD._godKillWatchConn = workspace.DescendantAdded:Connect(function(descendant)
            if not MzD._isGod then return end
            if not descendant:IsA("BasePart") then return end
            if isMzDPart(descendant) or knownParts[descendant] then return end
            if MzD.mapIsKillPart(descendant) then
                knownParts[descendant] = true
                disableKillPart(descendant)
            end
        end)
    end

    local function stopKillPartWatcher()
        if MzD._godKillWatchConn then
            pcall(function() MzD._godKillWatchConn:Disconnect() end)
            MzD._godKillWatchConn = nil
        end
    end

    -- ============================================
    -- ORIGINELE VLOEREN
    -- ============================================

    local function hideOriginalFloors()
        local map             = MzD.mapFindCurrentMap()
        local sharedInstances = map and MzD.mapFindSharedInstances(map.Name) or nil
        local floors          = MzD.mapFindFloorParts(map, sharedInstances)
        MzD._godOriginalFloors = {}

        local function saveAndHide(part)
            tinsert(MzD._godOriginalFloors, {
                part         = part,
                size         = part.Size,
                position     = part.Position,
                canCollide   = part.CanCollide,
                transparency = part.Transparency,
                color        = part.Color,
                material     = part.Material,
                anchored     = part.Anchored,
            })
            pcall(function() part.CanCollide = false part.Transparency = 1 end)
        end

        for _, part in ipairs(floors) do saveAndHide(part) end

        if map then
            for _, child in ipairs(map:GetChildren()) do
                if child:IsA("BasePart") and child.Name == "BridgeFloor" and not isMzDPart(child) then
                    saveAndHide(child)
                end
            end
        end

        -- Misc.Ground verbergen zodat je erdoorheen valt
        local root = findGameObjectsRoot()
        if root then
            local misc = root:FindFirstChild("Misc")
            if misc then
                for _, desc in ipairs(misc:GetDescendants()) do
                    if desc:IsA("BasePart") then saveAndHide(desc) end
                end
            end
        end

        return map
    end

    local function restoreOriginalFloors()
        for _, data in ipairs(MzD._godOriginalFloors) do
            pcall(function()
                if data.part and data.part.Parent then
                    data.part.Size         = data.size
                    data.part.Position     = data.position
                    data.part.CanCollide   = data.canCollide
                    data.part.Transparency = data.transparency
                    data.part.Color        = data.color
                    data.part.Material     = data.material
                    data.part.Anchored     = data.anchored
                end
            end)
        end
        MzD._godOriginalFloors = {}
    end

    -- ============================================
    -- GOD VLOER
    -- ============================================

    local function buildGodFloor(map)
        for _, part in ipairs(MzD._godCreatedParts) do
            pcall(function() if part and part.Parent then part:Destroy() end end)
        end
        MzD._godCreatedParts = {}

        local sharedInstances = map and MzD.mapFindSharedInstances(map.Name) or nil
        local startX, endX    = MzD.mapDetectXRange(map, sharedInstances)
        local floorY          = MzD.S.GodFloorY
        local theme           = getThemeColors(MzD)
        local isFirstSegment  = true
        local currentX        = startX

        while currentX < endX do
            local segmentLength = mmin(CONFIG.MAX_SEGMENT_LENGTH, endX - currentX)
            local centerX       = currentX + segmentLength / 2

            local floor             = Instance.new("Part")
            floor.Name              = "MzDGodFloor"
            floor.Size              = Vector3.new(segmentLength, CONFIG.FLOOR_THICKNESS, CONFIG.FLOOR_WIDTH)
            floor.Position          = Vector3.new(centerX, floorY, 0)
            floor.Anchored          = true
            floor.CanCollide        = true
            floor.Color             = theme.floor
            floor.Material          = Enum.Material.SmoothPlastic
            floor.Transparency      = 0
            floor.TopSurface        = Enum.SurfaceType.Smooth
            floor.BottomSurface     = Enum.SurfaceType.Smooth
            floor.Parent            = workspace
            tinsert(MzD._godCreatedParts, floor)

            if isFirstSegment then
                isFirstSegment = false
                buildSurfaceGui(floor, Enum.NormalId.Top, theme)
            end

            local topY = floorY + CONFIG.FLOOR_THICKNESS / 2 + 0.1
            for _, zOffset in ipairs({ CONFIG.FLOOR_WIDTH / 2 - 5, -CONFIG.FLOOR_WIDTH / 2 + 5 }) do
                local stripe         = Instance.new("Part")
                stripe.Name          = "MzDGodFloorStripe"
                stripe.Size          = Vector3.new(segmentLength, 0.2, 2)
                stripe.Position      = Vector3.new(centerX, topY, zOffset)
                stripe.Anchored      = true
                stripe.CanCollide    = false
                stripe.Color         = theme.stripe
                stripe.Material      = Enum.Material.Neon
                stripe.Parent        = workspace
                tinsert(MzD._godCreatedParts, stripe)
            end

            local midStripe         = Instance.new("Part")
            midStripe.Name          = "MzDGodFloorStripe"
            midStripe.Size          = Vector3.new(segmentLength, 0.2, 1)
            midStripe.Position      = Vector3.new(centerX, topY, 0)
            midStripe.Anchored      = true
            midStripe.CanCollide    = false
            midStripe.Color         = theme.stripe
            midStripe.Material      = Enum.Material.Neon
            midStripe.Parent        = workspace
            tinsert(MzD._godCreatedParts, midStripe)

            currentX = currentX + segmentLength
        end

        -- Onzichtbaar vangnet eronder
        local catchFloor        = Instance.new("Part")
        catchFloor.Name         = "MzDGodCatchFloor"
        catchFloor.Size         = Vector3.new(
            mabs(endX - startX) + CONFIG.CATCH_FLOOR_PADDING,
            2,
            CONFIG.FLOOR_WIDTH + CONFIG.CATCH_FLOOR_PADDING
        )
        catchFloor.Position     = Vector3.new(
            (startX + endX) / 2,
            floorY + CONFIG.CATCH_FLOOR_OFFSET_Y,
            0
        )
        catchFloor.Anchored     = true
        catchFloor.CanCollide   = true
        catchFloor.Transparency = 1
        catchFloor.Parent       = workspace
        tinsert(MzD._godCreatedParts, catchFloor)
    end

    local function destroyGodFloor()
        for _, part in ipairs(MzD._godCreatedParts) do
            pcall(function() if part and part.Parent then part:Destroy() end end)
        end
        MzD._godCreatedParts = {}
    end

    -- ============================================
    -- STRUCTUREN VERPLAATSEN
    -- ============================================

    local function lowerStructuresToGodFloor()
        MzD._godMovedParts  = {}
        local targetY       = MzD.S.GodFloorY + CONFIG.STRUCTURE_OFFSET_Y
        local root          = findGameObjectsRoot()
        local objectsToMove = {}

        -- Alle bases (inclusief eigen base)
        if workspace:FindFirstChild("Bases") then
            for _, base in ipairs(workspace.Bases:GetChildren()) do
                tinsert(objectsToMove, { obj = base, isBase = true })
            end
        end

        -- Directe workspace objecten
        for _, name in ipairs({ "DoomWheel", "LimitedShop", "FireAndIceWheel" }) do
            local obj = workspace:FindFirstChild(name)
            if obj then tinsert(objectsToMove, { obj = obj, isBase = false }) end
        end

        -- GameObjects root
        if root then
            for _, name in ipairs({ "UpgradeShop", "PlazaPortal", "SiteEventDetails", "SellStand", "WaveMachine" }) do
                local obj = root:FindFirstChild(name)
                if obj then tinsert(objectsToMove, { obj = obj, isBase = false }) end
            end
            local spawnMachines = root:FindFirstChild("SpawnMachines")
            if spawnMachines then
                local default = spawnMachines:FindFirstChild("Default")
                if default then tinsert(objectsToMove, { obj = default, isBase = false }) end
            end
        end

        for _, entry in ipairs(objectsToMove) do
            local obj = entry.obj

            -- Zoek groundY via naam
            local groundY = nil
            for _, desc in ipairs(obj:GetDescendants()) do
                if desc:IsA("BasePart") then
                    local n = string.lower(desc.Name)
                    if n == "ground" or n == "floor" or n == "primary"
                       or string.find(n, "baseplate") then
                        groundY = desc.Position.Y break
                    end
                end
            end

            -- Fallback: laagste part (skip slot brainrots bij bases)
            if not groundY then
                local lowestY = mhuge
                for _, desc in ipairs(obj:GetDescendants()) do
                    if desc:IsA("BasePart") then
                        -- Skip brainrot slot contents bij bases
                        if entry.isBase then
                            local parent = desc.Parent
                            local isBrainrot = false
                            while parent and parent ~= obj do
                                if parent.Name:find("brainrot") then
                                    isBrainrot = true break
                                end
                                parent = parent.Parent
                            end
                            if isBrainrot then continue end
                        end
                        if desc.Position.Y < lowestY then lowestY = desc.Position.Y end
                    end
                end
                if lowestY ~= mhuge then groundY = lowestY end
            end

            if not groundY then continue end

            local deltaY = targetY - groundY

            -- Skip als deltaY absurd groot is
            if mabs(deltaY) > CONFIG.STRUCTURE_MAX_DELTA then
                warn(string.format("[GodMode] Skip %s — deltaY=%.1f (te groot)", obj.Name, deltaY))
                continue
            end

            -- Skip als al op juiste hoogte
            if mabs(deltaY) < 0.1 then continue end

            -- Verplaats alle parts (skip brainrot slots bij bases)
            for _, desc in ipairs(obj:GetDescendants()) do
                if desc:IsA("BasePart") and not isMzDPart(desc) then
                    if entry.isBase then
                        local parent = desc.Parent
                        local isBrainrot = false
                        while parent and parent ~= obj do
                            if parent.Name:find("brainrot") then
                                isBrainrot = true break
                            end
                            parent = parent.Parent
                        end
                        if isBrainrot then continue end
                    end
                    tinsert(MzD._godMovedParts, { part = desc, originalCFrame = desc.CFrame })
                    desc.CFrame = desc.CFrame + Vector3.new(0, deltaY, 0)
                end
            end
        end
    end

    local function restoreStructures()
        for _, data in ipairs(MzD._godMovedParts or {}) do
            pcall(function()
                if data.part and data.part.Parent then
                    data.part.CFrame = data.originalCFrame
                end
            end)
        end
        MzD._godMovedParts = {}
    end

    -- ============================================
    -- BRAINROT SLOT REPAIR
    -- Snapt verschoven brainrots terug naar hun slot
    -- Alleen Root (anchored) wordt verplaatst —
    -- gewelde parts volgen automatisch
    -- ============================================

    local function repairBrainrotSlots()
        local bases = workspace:FindFirstChild("Bases")
        if not bases then return end

        for _, base in ipairs(bases:GetChildren()) do
            local slotsFolder = base:FindFirstChild("Slots")
            if not slotsFolder then continue end

            for _, slot in ipairs(slotsFolder:GetChildren()) do
                local slotNum = slot.Name:match("Slot(%d+)")
                if not slotNum then continue end

                local brainrotModel = base:FindFirstChild("slot " .. slotNum .. " brainrot")
                if not brainrotModel then continue end

                -- Referentiepositie: de Base part van de Slot
                local slotBase = slot:FindFirstChild("Base")
                if not slotBase or not slotBase:IsA("BasePart") then continue end
                local targetY = slotBase.Position.Y

                -- Vind de Root (anchored) part van de brainrot
                local rootPart = nil
                for _, desc in ipairs(brainrotModel:GetDescendants()) do
                    if desc:IsA("BasePart") and desc.Anchored and desc.Name == "Root" then
                        rootPart = desc break
                    end
                end
                -- Fallback: eerste anchored part
                if not rootPart then
                    for _, desc in ipairs(brainrotModel:GetDescendants()) do
                        if desc:IsA("BasePart") and desc.Anchored then
                            rootPart = desc break
                        end
                    end
                end
                if not rootPart then continue end

                -- Alleen fixen als nodig
                if mabs(rootPart.Position.Y - targetY) <= 2 then continue end

                pcall(function()
                    rootPart.CFrame = CFrame.new(
                        rootPart.Position.X,
                        targetY,
                        rootPart.Position.Z
                    )
                end)
            end
        end
    end

    -- ============================================
    -- TELEPORT
    -- ============================================

    local function teleportPlayerUnder()
        local character = Player.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not rootPart then return end
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.CFrame   = CFrame.new(rootPart.Position.X, MzD.S.GodWalkY, rootPart.Position.Z)
        if humanoid then
            pcall(function()
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Tripping,    false)
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                humanoid.HipHeight = 0
            end)
        end
    end

    M.godTeleportUnder = teleportPlayerUnder

    -- ============================================
    -- HEALTH
    -- ============================================

    local function setupGodHealth(character)
        if MzD._godHealthConn then pcall(function() MzD._godHealthConn:Disconnect() end) end
        if MzD._godDiedConn   then pcall(function() MzD._godDiedConn:Disconnect() end)   end

        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end

        MzD._godOriginalMaxHealth = humanoid.MaxHealth

        pcall(function()
            humanoid.MaxHealth = mhuge
            humanoid.Health    = mhuge
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,        false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Tripping,    false)
            humanoid.HipHeight = 0
        end)

        for _, ff in ipairs(character:GetChildren()) do
            if ff:IsA("ForceField") then ff:Destroy() end
        end
        local forceField   = Instance.new("ForceField")
        forceField.Visible = false
        forceField.Parent  = character

        MzD._godHealthConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if not MzD._isGod then return end
            pcall(function()
                if humanoid.Health ~= mhuge then humanoid.Health = mhuge end
            end)
        end)

        MzD._godDiedConn = humanoid.Died:Connect(function()
            if not MzD._isGod then return end
            tdefer(function()
                pcall(function()
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    humanoid.MaxHealth = mhuge
                    humanoid.Health    = mhuge
                end)
            end)
        end)
    end

    M.godSetupHealth = setupGodHealth

    -- ============================================
    -- GOD LOOP
    -- ============================================

    local function startGodLoop()
        if MzD._godLoopThread then pcall(tcancel, MzD._godLoopThread) end
        local floorRecheckTimer = 0

        MzD._godLoopThread = tspawn(function()
            while MzD._isGod do
                pcall(function()
                    local character = Player.Character
                    if not character then return end
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character:FindFirstChild("Humanoid")

                    -- Periodieke vloer/killpart hercheck
                    floorRecheckTimer += CONFIG.LOOP_INTERVAL
                    if floorRecheckTimer >= CONFIG.FLOOR_RECHECK_SECS then
                        floorRecheckTimer = 0
                        for _, data in ipairs(MzD._godOriginalFloors) do
                            if data.part and data.part.Parent then
                                pcall(function()
                                    data.part.CanCollide   = false
                                    data.part.Transparency = 1
                                end)
                            end
                        end
                        reapplyKillPartDisable()
                    end

                    -- Anti-ragdoll
                    if humanoid then
                        pcall(function()
                            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
                            humanoid:SetStateEnabled(Enum.HumanoidStateType.Tripping,    false)
                            local state = humanoid:GetState()
                            if state == Enum.HumanoidStateType.FallingDown
                            or state == Enum.HumanoidStateType.Ragdoll
                            or state == Enum.HumanoidStateType.Tripping then
                                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                            end
                        end)
                    end

                    -- Val-detectie
                    if rootPart and rootPart.Position.Y < MzD.S.GodWalkY - CONFIG.FALL_MARGIN then
                        rootPart.Velocity = Vector3.new(0, 0, 0)
                        rootPart.CFrame   = CFrame.new(
                            rootPart.Position.X, MzD.S.GodWalkY, rootPart.Position.Z
                        )
                    end
                end)
                twait(CONFIG.LOOP_INTERVAL)
            end
        end)
    end

    -- ============================================
    -- ENABLE / DISABLE
    -- ============================================

    function MzD.enableGod()
        if MzD._isGod then return end
        MzD._isGod       = true
        MzD.S.GodEnabled = true

        local killCount = disableAllKillParts()
        startKillPartWatcher()
        twait(0.1)

        local map = hideOriginalFloors()
        twait(0.1)

        lowerStructuresToGodFloor()
        twait(0.1)

        repairBrainrotSlots()   -- ← fix verschoven brainrots
        twait(0.1)

        buildGodFloor(map)
        twait(0.2)

        startGodLoop()
        twait(0.1)

        teleportPlayerUnder()
        twait(0.1)

        if Player.Character then setupGodHealth(Player.Character) end

        MzD.Status.god = string.format(
            "Aan (Y=%d K:%d V:%d)",
            MzD.S.GodWalkY, killCount, #MzD._godCreatedParts
        )
    end

    function MzD.disableGod()
        MzD._isGod       = false
        MzD.S.GodEnabled = false

        if MzD._godLoopThread then
            pcall(tcancel, MzD._godLoopThread)
            MzD._godLoopThread = nil
        end
        stopKillPartWatcher()
        if MzD._godHealthConn then
            pcall(function() MzD._godHealthConn:Disconnect() end)
            MzD._godHealthConn = nil
        end
        if MzD._godDiedConn then
            pcall(function() MzD._godDiedConn:Disconnect() end)
            MzD._godDiedConn = nil
        end

        restoreOriginalFloors()
        restoreStructures()     -- ← zet structuren terug, brainrots volgen automatisch
        restoreKillParts()
        destroyGodFloor()

        -- Teleporteer speler terug omhoog
        local character = Player.Character
        local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.CFrame   = CFrame.new(rootPart.Position.X, 10, rootPart.Position.Z)
        end

        -- Herstel originele health
        if character then
            for _, ff in ipairs(character:GetChildren()) do
                if ff:IsA("ForceField") then ff:Destroy() end
            end
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                pcall(function()
                    local originalMaxHealth = MzD._godOriginalMaxHealth or 100
                    humanoid.MaxHealth = originalMaxHealth
                    humanoid.Health    = originalMaxHealth
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                end)
            end
        end

        MzD.Status.god = "Uit"
    end

    M.godBuildEgaleVloer  = buildGodFloor
    M.godDisableKillParts = disableAllKillParts

end

return M
