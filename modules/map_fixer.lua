-- ============================================
-- [MODULE 25] MAP FIXER
-- ============================================
local M = {}

function M.init(Modules)
    local G               = Modules.globals
    local MzD             = G.MzD
    local tinsert         = G.tinsert
    local tspawn          = G.tspawn
    local twait           = G.twait
    local tcancel         = G.tcancel
    local sfind           = G.sfind
    local slower          = G.slower
    local mabs            = G.mabs
    local mmin            = G.mmin
    local isMzDPart       = Modules.utility.isMzDPart
    local getThemeColors  = Modules.wall_themes.getThemeColors
    local buildSurfaceGui = Modules.utility.buildSurfaceGui

    -- ============================================
    -- CONFIGURATIE
    -- ============================================
    local CONFIG = {
        FLOOR_WIDTH        = 420,
        FLOOR_HALF_WIDTH   = 210,
        WALL_THICKNESS     = 6,
        WALL_HEIGHT        = 300,
        WALL_BOTTOM_Y      = -25,
        POLL_INTERVAL      = 8,
        MAX_SEGMENT_LENGTH = 2000,
    }
    local WALL_MID_Y = CONFIG.WALL_BOTTOM_Y + CONFIG.WALL_HEIGHT / 2

    local EVENT_MAP_NAMES = {
        "ValentinesMap", "ArcadeMap",  "CandyMap",   "HalloweenMap",
        "ChristmasMap",  "EasterMap",  "SummerMap",  "SpringMap",
        "WinterMap",     "DoomMap",
    }
    local MAP_FOLDERS_TO_REMOVE = {
        "RightWalls", "LeftWalls", "Gaps",    "VIPWalls",
        "SideWalls",  "Barriers",  "Fences",  "Walls", "Decorations",
    }
    local DECORATION_FOLDER_NAMES = {
        "Deco", "Decoration", "Decorations", "Decor",
        "Props", "Prop", "Effects", "VFX", "Extras", "Extra",
    }

    -- ============================================
    -- HELPERS
    -- ============================================

    local function safeDestroyFolder(parent, folderName)
        if not parent then return end
        local folder = parent:FindFirstChild(folderName)
        if not folder or folder.Name == "MzDHubWalls" then return end
        pcall(function()
            for _, desc in ipairs(folder:GetDescendants()) do
                if desc:IsA("BasePart") then desc:Destroy() end
            end
            folder:Destroy()
        end)
    end

    -- ============================================
    -- CLEANUP
    -- ============================================

    function MzD.removeMapDecorations(map)
        if not map then return 0 end
        local removedCount = 0
        local lowerNames   = {}
        for _, name in ipairs(DECORATION_FOLDER_NAMES) do
            lowerNames[slower(name)] = true
        end
        for _, decoName in ipairs(DECORATION_FOLDER_NAMES) do
            local child = map:FindFirstChild(decoName)
            if child then
                pcall(function() child:Destroy() removedCount += 1 end)
            end
        end
        for _, child in ipairs(map:GetChildren()) do
            if (child:IsA("Folder") or child:IsA("Model")) and lowerNames[slower(child.Name)] then
                pcall(function() child:Destroy() removedCount += 1 end)
            end
        end
        return removedCount
    end

    function MzD.mapCleanup(map)
        if not map then return end
        for _, folderName in ipairs(MAP_FOLDERS_TO_REMOVE) do
            safeDestroyFolder(map, folderName)
        end
        MzD.removeMapDecorations(map)
        for _, desc in ipairs(map:GetDescendants()) do
            if desc.Parent and not isMzDPart(desc) and MzD.mapIsWallPart(desc) then
                pcall(function() desc:Destroy() end)
            end
        end
    end

    function MzD.mapCleanupSharedInstances(sharedInstances)
        if not sharedInstances then return end
        for _, folderName in ipairs(MAP_FOLDERS_TO_REMOVE) do
            safeDestroyFolder(sharedInstances, folderName)
        end
        MzD.removeMapDecorations(sharedInstances)
        for _, desc in ipairs(sharedInstances:GetDescendants()) do
            if desc:IsA("BasePart") and not isMzDPart(desc) and MzD.mapIsWallPart(desc) then
                pcall(function() desc:Destroy() end)
            end
        end
    end

    function MzD.mapCleanupMisc()
        local misc = workspace:FindFirstChild("Misc")
        if not misc then return end
        for _, child in ipairs(misc:GetChildren()) do
            if child.Name == "BrickAddition" or child.Name == "Roof" then
                pcall(function() child:Destroy() end)
            end
        end
    end

    function MzD.cleanupEventMaps()
        for _, mapName in ipairs(EVENT_MAP_NAMES) do
            local eventMap = workspace:FindFirstChild(mapName)
            if eventMap then
                for _, folderName in ipairs(MAP_FOLDERS_TO_REMOVE) do
                    safeDestroyFolder(eventMap, folderName)
                end
                MzD.removeMapDecorations(eventMap)
                for _, desc in ipairs(eventMap:GetDescendants()) do
                    if desc:IsA("BasePart") and not isMzDPart(desc) and MzD.mapIsWallPart(desc) then
                        pcall(function() desc:Destroy() end)
                    end
                end
            end
        end
    end

    -- ============================================
    -- VLOER AANPASSEN
    -- ============================================

    function MzD.mapWidenFloors(map, sharedInstances)
        local floors = MzD.mapFindFloorParts(map, sharedInstances)
        for _, part in ipairs(floors) do
            pcall(function()
                if mabs(part.Size.Z - CONFIG.FLOOR_WIDTH) > 1 then
                    part.Size     = Vector3.new(part.Size.X, part.Size.Y, CONFIG.FLOOR_WIDTH)
                    part.Position = Vector3.new(part.Position.X, part.Position.Y, 0)
                end
            end)
        end
    end

    function MzD.mapFillGaps(map, startX, endX)
        if not map then return end

        local referenceFloor = nil
        for _, desc in ipairs(map:GetDescendants()) do
            if desc:IsA("BasePart") and not isMzDPart(desc) then
                local name = slower(desc.Name)
                if name == "firstfloor" or name == "ground" then
                    referenceFloor = desc break
                end
            end
        end
        if not referenceFloor then
            local spawners = map:FindFirstChild("Spawners")
            if spawners then
                for _, part in ipairs(spawners:GetChildren()) do
                    if part:IsA("BasePart") then referenceFloor = part break end
                end
            end
        end
        if not referenceFloor then
            for _, desc in ipairs(map:GetDescendants()) do
                if desc:IsA("BasePart") and not isMzDPart(desc)
                   and desc.Size.X > 50 and desc.Size.Y < 10 and desc.Position.Y < 20 then
                    referenceFloor = desc break
                end
            end
        end
        if not referenceFloor then return end

        local floorY        = referenceFloor.Position.Y
        local floorHeight   = referenceFloor.Size.Y
        local floorColor    = referenceFloor.Color
        local floorMaterial = referenceFloor.Material

        for _, child in ipairs(map:GetChildren()) do
            if child:IsA("BasePart") and child.Name == "BridgeFloor" then
                pcall(function() child:Destroy() end)
            end
        end

        local currentX = startX
        while currentX < endX do
            local segmentLength   = mmin(CONFIG.MAX_SEGMENT_LENGTH, endX - currentX)
            local segment         = Instance.new("Part")
            segment.Name          = "BridgeFloor"
            segment.Size          = Vector3.new(segmentLength, floorHeight, CONFIG.FLOOR_WIDTH)
            segment.Position      = Vector3.new(currentX + segmentLength / 2, floorY, 0)
            segment.Anchored      = true
            segment.CanCollide    = true
            segment.Color         = floorColor
            segment.Material      = floorMaterial
            segment.TopSurface    = Enum.SurfaceType.Smooth
            segment.BottomSurface = Enum.SurfaceType.Smooth
            segment.Parent        = map
            currentX = currentX + segmentLength
        end
    end

    -- ============================================
    -- MUREN BOUWEN
    -- ============================================

    function MzD.mapBuildWalls(map, startX, endX)
        if not map then return end

        local floorTop  = MzD.S.GodFloorY + 2
        local stripeBot = floorTop + 1
        local stripeMid = floorTop + CONFIG.WALL_HEIGHT * 0.2
        local stripeTop = floorTop + CONFIG.WALL_HEIGHT * 0.85

        local existingFolder = map:FindFirstChild("MzDHubWalls")
        if existingFolder then
            local firstWall = existingFolder:FindFirstChild("FrontWall_1")
            if firstWall
               and mabs(firstWall.Size.Y - CONFIG.WALL_HEIGHT) < 1
               and mabs(firstWall.Position.Y - WALL_MID_Y) < 1 then
                MzD._wallZ_front = CONFIG.FLOOR_HALF_WIDTH - 3
                MzD._wallZ_back  = -CONFIG.FLOOR_HALF_WIDTH + 3
                return
            end
            pcall(function() existingFolder:Destroy() end)
        end

        local wallFolder  = Instance.new("Folder")
        wallFolder.Name   = "MzDHubWalls"
        wallFolder.Parent = map
        local theme       = getThemeColors(MzD)

        local function makeWall(name, size, position)
            local wall            = Instance.new("Part")
            wall.Name             = name
            wall.Size             = size
            wall.Position         = position
            wall.Anchored         = true
            wall.CanCollide       = true
            wall.Color            = theme.wall
            wall.Material         = Enum.Material.SmoothPlastic
            wall.TopSurface       = Enum.SurfaceType.Smooth
            wall.BottomSurface    = Enum.SurfaceType.Smooth
            wall.Parent           = wallFolder
            return wall
        end

        local function makeStripe(name, size, position)
            local stripe          = Instance.new("Part")
            stripe.Name           = name
            stripe.Size           = size
            stripe.Position       = position
            stripe.Anchored       = true
            stripe.CanCollide     = false
            stripe.Color          = theme.stripe
            stripe.Material       = Enum.Material.Neon
            stripe.Parent         = wallFolder
        end

        local currentX = startX
        local index    = 1
        while currentX < endX do
            local segmentLength = mmin(CONFIG.MAX_SEGMENT_LENGTH, endX - currentX)
            local centerX       = currentX + segmentLength / 2
            local halfW         = CONFIG.FLOOR_HALF_WIDTH
            local thick         = CONFIG.WALL_THICKNESS

            local frontWall = makeWall(
                "FrontWall_" .. index,
                Vector3.new(segmentLength, CONFIG.WALL_HEIGHT, thick),
                Vector3.new(centerX, WALL_MID_Y, halfW + thick / 2)
            )
            buildSurfaceGui(frontWall, Enum.NormalId.Front, theme)
            buildSurfaceGui(frontWall, Enum.NormalId.Back,  theme)
            makeStripe("FrontStripe_bot_" .. index, Vector3.new(segmentLength, 2, 0.4), Vector3.new(centerX, stripeBot, halfW + thick + 0.3))
            makeStripe("FrontStripe_mid_" .. index, Vector3.new(segmentLength, 1, 0.4), Vector3.new(centerX, stripeMid, halfW + thick + 0.3))
            makeStripe("FrontStripe_top_" .. index, Vector3.new(segmentLength, 2, 0.4), Vector3.new(centerX, stripeTop, halfW + thick + 0.3))

            local backWall = makeWall(
                "BackWall_" .. index,
                Vector3.new(segmentLength, CONFIG.WALL_HEIGHT, thick),
                Vector3.new(centerX, WALL_MID_Y, -halfW - thick / 2)
            )
            buildSurfaceGui(backWall, Enum.NormalId.Front, theme)
            buildSurfaceGui(backWall, Enum.NormalId.Back,  theme)
            makeStripe("BackStripe_bot_" .. index, Vector3.new(segmentLength, 2, 0.4), Vector3.new(centerX, stripeBot, -halfW - thick - 0.3))
            makeStripe("BackStripe_mid_" .. index, Vector3.new(segmentLength, 1, 0.4), Vector3.new(centerX, stripeMid, -halfW - thick - 0.3))
            makeStripe("BackStripe_top_" .. index, Vector3.new(segmentLength, 2, 0.4), Vector3.new(centerX, stripeTop, -halfW - thick - 0.3))

            currentX = currentX + segmentLength
            index    = index + 1
        end

        local totalZ = CONFIG.FLOOR_HALF_WIDTH * 2 + CONFIG.WALL_THICKNESS * 2 + 2
        makeWall("LeftWall",
            Vector3.new(CONFIG.WALL_THICKNESS, CONFIG.WALL_HEIGHT, totalZ),
            Vector3.new(startX - CONFIG.WALL_THICKNESS / 2, WALL_MID_Y, 0))
        makeWall("RightWall",
            Vector3.new(CONFIG.WALL_THICKNESS, CONFIG.WALL_HEIGHT, totalZ),
            Vector3.new(endX   + CONFIG.WALL_THICKNESS / 2, WALL_MID_Y, 0))

        MzD._wallZ_front = CONFIG.FLOOR_HALF_WIDTH - 3
        MzD._wallZ_back  = -CONFIG.FLOOR_HALF_WIDTH + 3
    end

    -- ============================================
    -- COLLISION
    -- ============================================

    function MzD.mapFixCollision(map, sharedInstances)
        if not map then return end
        local floors = MzD.mapFindFloorParts(map, sharedInstances)
        for _, part in ipairs(floors) do
            if MzD._isGod then
                pcall(function() part.CanCollide = false part.Transparency = 1 end)
            else
                pcall(function() part.CanCollide = true  part.Transparency = 0 end)
            end
        end
        for _, child in ipairs(map:GetChildren()) do
            if child:IsA("BasePart") and child.Name == "BridgeFloor" then
                if MzD._isGod then
                    pcall(function() child.CanCollide = false child.Transparency = 1 end)
                else
                    pcall(function() child.CanCollide = true end)
                end
            end
        end
        local wallFolder = map:FindFirstChild("MzDHubWalls")
        if wallFolder then
            for _, part in ipairs(wallFolder:GetChildren()) do
                if part:IsA("BasePart") then
                    if sfind(part.Name, "Stripe") then
                        part.CanCollide = false
                    else
                        part.CanCollide = true
                        part.Anchored   = true
                    end
                end
            end
        end
    end

    -- ============================================
    -- HOOFD-FIX + EVENT-GEDREVEN MAPWATCHER
    -- ============================================

    MzD._lastFixedMapName = ""

    function MzD.mapRunFix()
        local map = MzD.mapFindCurrentMap()
        if not map then return end
        local sharedInstances = MzD.mapFindSharedInstances(map.Name)
        local mapChanged      = map.Name ~= MzD._lastFixedMapName

        if mapChanged then
            MzD._lastFixedMapName = map.Name
            MzD.lastMapName       = map.Name
        end

        local startX, endX = MzD.mapDetectXRange(map, sharedInstances)

        if mapChanged then
            pcall(function() MzD.mapCleanup(map) end)
            pcall(function() MzD.mapCleanupSharedInstances(sharedInstances) end)
            pcall(function() MzD.mapCleanupMisc() end)
            pcall(function() MzD.cleanupEventMaps() end)
            twait(0.1)
            pcall(function() MzD.mapWidenFloors(map, sharedInstances) end)
            pcall(function() MzD.mapFillGaps(map, startX, endX) end)
            pcall(function() MzD.mapBuildWalls(map, startX, endX) end)
            MzD.Status.mapFixer = "Gefixed: " .. map.Name
        end

        pcall(function() MzD.mapFixCollision(map, sharedInstances) end)
    end

    function MzD.startMapFixer()
        if MzD._mapFixerActive then return end
        MzD._mapFixerActive   = true
        MzD.S.MapFixerEnabled = true
        MzD._lastFixedMapName = ""

        pcall(function() MzD.mapRunFix() end)

        -- Event: directe reactie bij nieuwe map
        if MzD._mapAddedConn then
            pcall(function() MzD._mapAddedConn:Disconnect() end)
        end
        MzD._mapAddedConn = workspace.ChildAdded:Connect(function(child)
            if not MzD._mapFixerActive then return end
            if child:IsA("Model")
               and sfind(child.Name, "Map")
               and not sfind(child.Name, "SharedInstances")
               and not sfind(child.Name, "VFX") then
                twait(0.3)
                pcall(function() MzD.mapRunFix() end)
            end
        end)

        -- Event: reset bij verwijderen huidige map
        if MzD._mapRemovedConn then
            pcall(function() MzD._mapRemovedConn:Disconnect() end)
        end
        MzD._mapRemovedConn = workspace.ChildRemoved:Connect(function(child)
            if not MzD._mapFixerActive then return end
            if child.Name == MzD._lastFixedMapName then
                MzD._lastFixedMapName = ""
            end
        end)

        -- Polling als fallback
        if MzD.mapFixerThread then return end
        MzD.mapFixerThread = tspawn(function()
            while MzD._mapFixerActive do
                twait(CONFIG.POLL_INTERVAL)
                if MzD._mapFixerActive then
                    pcall(function() MzD.mapRunFix() end)
                    MzD.Status.mapFixer = "Actief"
                end
            end
            MzD.Status.mapFixer = "Uit"
            MzD.mapFixerThread  = nil
        end)
    end

    function MzD.stopMapFixer()
        MzD._mapFixerActive   = false
        MzD.S.MapFixerEnabled = false
        if MzD._mapAddedConn then
            pcall(function() MzD._mapAddedConn:Disconnect() end)
            MzD._mapAddedConn = nil
        end
        if MzD._mapRemovedConn then
            pcall(function() MzD._mapRemovedConn:Disconnect() end)
            MzD._mapRemovedConn = nil
        end
        if MzD.mapFixerThread then
            pcall(tcancel, MzD.mapFixerThread)
            MzD.mapFixerThread = nil
        end
        MzD.Status.mapFixer = "Uit"
    end

end

return M
