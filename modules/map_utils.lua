-- ============================================
-- [MAP UTILS] Gedeelde kaart-hulpfuncties
-- Gebruikt door: Module 25 (Map Fixer), Module 10 (God Mode), Module 17 (Tower Trial)
-- ============================================
local M = {}

function M.init(Modules)
    local G         = Modules.globals
    local MzD       = G.MzD
    local sfind     = G.sfind
    local slower    = G.slower
    local mhuge     = G.mhuge
    local tinsert   = G.tinsert
    local mabs      = G.mabs
    local isMzDPart = Modules.utility.isMzDPart

    -- ============================================
    -- CONSTANTEN
    -- ============================================

    local FLOOR_PART_NAMES = {
        firstfloor = true, ground = true, floor = true,
        grass = true, path = true, road = true,
        platform = true, bridgefloor = true,
    }
    local WALL_KEYWORDS = { "vipwall", "sidewall", "barrier", "fence", "blocker", "border" }
    local KILL_KEYWORDS = { "kill", "tsunamikill", "deathzone", "damagezone", "killbrick", "killpart" }
    local MAP_SKIP_WORDS = { "SharedInstances", "VFX" }

    local FLOOR_MIN_SIZE_X   = 15
    local FLOOR_MIN_SIZE_Z   = 5
    local FLOOR_MAX_SIZE_Y   = 20
    local FLOOR_MAX_Y        = 30
    local FLOOR_MIN_Y        = -20
    local XRANGE_MAX_Y       = 50
    local XRANGE_MIN_Y       = -30
    local XRANGE_MIN_SIZE_X  = 5
    local XRANGE_PADDING     = 10
    local XRANGE_DEFAULT_MIN = -15
    local XRANGE_DEFAULT_MAX = 4385

    -- ============================================
    -- HELPER
    -- ============================================

    local function shouldSkipModel(model)
        if not model:IsA("Model") then return true end
        if not sfind(model.Name, "Map") then return true end
        for _, skipWord in ipairs(MAP_SKIP_WORDS) do
            if sfind(model.Name, skipWord) then return true end
        end
        return false
    end

    -- ============================================
    -- GAMEOBJECTS ROOT
    -- Gedeeld door god_mode EN tower_trial
    -- ============================================

    -- Geeft workspace.GameObjects.PlaceSpecific.root terug
    -- Gebruikt door: god_mode (structuren verplaatsen, Misc.Ground)
    --                tower_trial (Tower model vinden)
    function MzD.mapGetGameObjectsRoot()
        local gameObjects = workspace:FindFirstChild("GameObjects")
        if not gameObjects then return nil end
        local placeSpecific = gameObjects:FindFirstChild("PlaceSpecific", true)
        if not placeSpecific then return nil end
        return placeSpecific:FindFirstChild("root")
    end

    -- ============================================
    -- DEEL-TYPE DETECTIE
    -- ============================================

    function MzD.mapIsFloorPart(part)
        if not part:IsA("BasePart") or isMzDPart(part) then return false end
        if part.Size.Y > part.Size.X and part.Size.Y > part.Size.Z then return false end
        if part.Position.Y > FLOOR_MAX_Y or part.Position.Y < FLOOR_MIN_Y then return false end
        if FLOOR_PART_NAMES[slower(part.Name)] then return true end
        if part.Size.X > FLOOR_MIN_SIZE_X
           and part.Size.Z > FLOOR_MIN_SIZE_Z
           and part.Size.Y < FLOOR_MAX_SIZE_Y then
            return true
        end
        return false
    end

    function MzD.mapIsWallPart(part)
        if not part:IsA("BasePart") or isMzDPart(part) then return false end
        local name = slower(part.Name)
        for _, keyword in ipairs(WALL_KEYWORDS) do
            if name == keyword or sfind(name, "^" .. keyword) then return true end
        end
        if part.Size.Y > 15
           and part.Size.Y > part.Size.X * 3
           and part.Size.Y > part.Size.Z * 3
           and mabs(part.Position.Z) > 60 then
            return true
        end
        return false
    end

    function MzD.mapIsKillPart(part)
        if not part:IsA("BasePart") or isMzDPart(part) then return false end
        local ok, isStrip = pcall(function()
            return part.Size.Y < 1 and part.Size.Z > 50
               and part.Position.Y < 5 and part.Position.Y > -5
               and part.Size.X < 5
        end)
        if ok and isStrip then return true end
        local name = slower(part.Name)
        for _, keyword in ipairs(KILL_KEYWORDS) do
            if sfind(name, keyword) then return true end
        end
        return false
    end

    -- ============================================
    -- KAART-DETECTIE
    -- ============================================

    function MzD.mapFindCurrentMap()
        -- Stap 1: bekende landmark-children
        for _, child in ipairs(workspace:GetChildren()) do
            if not shouldSkipModel(child) then
                if child:FindFirstChild("Spawners") or child:FindFirstChild("Gaps")
                or child:FindFirstChild("FirstFloor") or child:FindFirstChild("Ground") then
                    return child
                end
            end
        end
        -- Stap 2: benoemde vloer-afstammeling
        for _, child in ipairs(workspace:GetChildren()) do
            if not shouldSkipModel(child) then
                for _, desc in ipairs(child:GetDescendants()) do
                    if desc:IsA("BasePart") and FLOOR_PART_NAMES[slower(desc.Name)] then
                        return child
                    end
                end
            end
        end
        -- Stap 3: fallback — meeste BaseParts
        local bestMap, bestCount = nil, 10
        for _, child in ipairs(workspace:GetChildren()) do
            if not shouldSkipModel(child) then
                local count = 0
                for _, desc in ipairs(child:GetDescendants()) do
                    if desc:IsA("BasePart") then count += 1 end
                end
                if count > bestCount then bestMap = child bestCount = count end
            end
        end
        return bestMap
    end

    function MzD.mapFindSharedInstances(mapName)
        return workspace:FindFirstChild(mapName .. "_SharedInstances")
    end

    -- ============================================
    -- VLOER-VERZAMELING
    -- ============================================

    function MzD.mapFindFloorParts(map, sharedInstances)
        local floors, seen = {}, {}
        local function addIfFloor(part)
            if seen[part] then return end
            if not MzD.mapIsFloorPart(part) then return end
            seen[part] = true
            tinsert(floors, part)
        end
        if map then
            local spawners = map:FindFirstChild("Spawners")
            if spawners then
                for _, part in ipairs(spawners:GetChildren()) do addIfFloor(part) end
            end
            for _, desc in ipairs(map:GetDescendants()) do addIfFloor(desc) end
        end
        if sharedInstances then
            local sharedFloors = sharedInstances:FindFirstChild("Floors")
            if sharedFloors then
                for _, part in ipairs(sharedFloors:GetChildren()) do addIfFloor(part) end
            end
            for _, child in ipairs(sharedInstances:GetChildren()) do addIfFloor(child) end
        end
        return floors
    end

    -- ============================================
    -- X-BEREIK DETECTIE
    -- ============================================

    function MzD.mapDetectXRange(map, sharedInstances)
        local minX, maxX, found = mhuge, -mhuge, false
        local function checkPart(part)
            if not part:IsA("BasePart") or isMzDPart(part) then return end
            if part.Size.Y > part.Size.X and part.Size.Y > part.Size.Z then return end
            if part.Position.Y > XRANGE_MAX_Y or part.Position.Y < XRANGE_MIN_Y then return end
            if part.Size.X < XRANGE_MIN_SIZE_X then return end
            local left  = part.Position.X - part.Size.X / 2
            local right = part.Position.X + part.Size.X / 2
            if left  < minX then minX = left  end
            if right > maxX then maxX = right end
            found = true
        end
        if map then
            for _, desc in ipairs(map:GetDescendants()) do checkPart(desc) end
        end
        if sharedInstances then
            for _, child in ipairs(sharedInstances:GetChildren()) do checkPart(child) end
            local sharedFloors = sharedInstances:FindFirstChild("Floors")
            if sharedFloors then
                for _, floor in ipairs(sharedFloors:GetChildren()) do checkPart(floor) end
            end
        end
        if found and maxX > minX then
            return minX - XRANGE_PADDING, maxX + XRANGE_PADDING
        end
        return XRANGE_DEFAULT_MIN, XRANGE_DEFAULT_MAX
    end

end

return M
