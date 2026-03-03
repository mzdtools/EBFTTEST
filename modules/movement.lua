-- ============================================
-- [MODULE 11] MOVEMENT & NAVIGATION
-- ============================================
local M = {}

function M.init(Modules)
    local G            = Modules.globals
    local MzD          = G.MzD
    local Player       = G.Player
    local TweenService = G.TweenService
    local twait        = G.twait

    -- ============================================
    -- EQUIP / UNEQUIP
    -- ============================================

    function MzD.safeEquip(tool)
        if not tool then return end
        local character = Player.Character if not character then return end
        local humanoid  = character:FindFirstChild("Humanoid") if not humanoid then return end
        pcall(function() humanoid:EquipTool(tool) end)
        twait(0.4)
    end

    function MzD.safeUnequip()
        local character = Player.Character if not character then return end
        local humanoid  = character:FindFirstChild("Humanoid") if not humanoid then return end
        pcall(function() humanoid:UnequipTools() end)
        twait(0.2)
    end

    -- ============================================
    -- TWEEN HELPERS
    -- Intern: één functie met snelheidsparameter
    -- ============================================

    local function tweenAtSpeed(cf, speed)
        local character = Player.Character if not character then return false end
        local rootPart  = character:FindFirstChild("HumanoidRootPart") if not rootPart then return false end
        local targetCF  = MzD._isGod
            and CFrame.new(cf.Position.X, MzD.S.GodWalkY, cf.Position.Z)
            or  cf
        local duration  = math.max((rootPart.Position - targetCF.Position).Magnitude / speed, 0.005)
        local tween     = TweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCF })
        tween:Play()
        tween.Completed:Wait()
        return true
    end

    -- Normaal: gebruikt MzD.S.TweenSpeed (instelbaar)
    function MzD.tweenTo(cf)
        return tweenAtSpeed(cf, math.max(MzD.S.TweenSpeed or 9999, 50))
    end

    -- Instant: vaste maximale snelheid
    function MzD.fastTween(cf)
        return tweenAtSpeed(cf, 99999)
    end

    -- Corridor: gebruikt MzD.S.CorridorSpeed (aparte instelling)
    function MzD.corridorTween(cf)
        return tweenAtSpeed(cf, math.max(MzD.S.CorridorSpeed or 1500, 50))
    end

    -- ============================================
    -- MUUR / CORRIDOR DETECTIE
    -- MzD.mapFindCurrentMap() komt uit map_utils — niet hier herdefinieren
    -- ============================================

    function MzD.detectWallZ()
        local map = MzD.mapFindCurrentMap() if not map then return end
        local wallFolder = map:FindFirstChild("MzDHubWalls") if not wallFolder then return end
        local frontWall  = wallFolder:FindFirstChild("FrontWall_1")
        local backWall   = wallFolder:FindFirstChild("BackWall_1")
        if frontWall then MzD._wallZ_front = frontWall.Position.Z - frontWall.Size.Z / 2 - 3 end
        if backWall  then MzD._wallZ_back  = backWall.Position.Z  + backWall.Size.Z  / 2 + 3 end
    end

    function MzD.getCorridorZ()
        MzD.detectWallZ()
        local homePos = MzD.getHomePosition().Position
        return homePos.Z >= 0 and MzD._wallZ_front or MzD._wallZ_back
    end

    -- ============================================
    -- NAVIGATIE
    -- ============================================

    -- Veilig pad via corridor: omhoog → corridor → langs X-as → naar doel
    function MzD.safePathTo(targetCFrame)
        local character = Player.Character if not character then return false end
        local rootPart  = character:FindFirstChild("HumanoidRootPart") if not rootPart then return false end
        local startPos  = rootPart.Position
        local endPos    = targetCFrame.Position
        local safeZ     = MzD.getCorridorZ()
        local safeY     = MzD._isGod
            and MzD.S.GodWalkY
            or  (MzD.getHomePosition().Position.Y + 8)

        MzD.fastTween(CFrame.new(startPos.X, safeY, startPos.Z))  twait(0.05)
        MzD.corridorTween(CFrame.new(startPos.X, safeY, safeZ))   twait(0.05)
        MzD.corridorTween(CFrame.new(endPos.X,   safeY, safeZ))   twait(0.05)
        MzD.corridorTween(CFrame.new(endPos.X,   safeY, endPos.Z)) twait(0.05)

        local finalCF = MzD._isGod
            and CFrame.new(endPos.X, MzD.S.GodWalkY, endPos.Z)
            or  targetCFrame
        MzD.tweenTo(finalCF)
        twait(0.05)
        return true
    end

    -- Veilig terug naar base via corridor
    function MzD.safeReturnToBase()
        local character = Player.Character if not character then return end
        local rootPart  = character:FindFirstChild("HumanoidRootPart") if not rootPart then return end
        local currentPos = rootPart.Position
        local homePos    = MzD.getHomePosition().Position
        MzD.detectWallZ()
        local safeZ = MzD.getCorridorZ()
        local safeY = MzD._isGod
            and MzD.S.GodWalkY
            or  (homePos.Y + 8)

        MzD.fastTween(CFrame.new(currentPos.X, safeY, currentPos.Z))  twait(0.05)
        MzD.corridorTween(CFrame.new(currentPos.X, safeY, safeZ))     twait(0.05)
        MzD.corridorTween(CFrame.new(homePos.X,    safeY, safeZ))     twait(0.05)
        MzD.corridorTween(CFrame.new(homePos.X,    safeY, homePos.Z)) twait(0.05)
        MzD.tweenTo(CFrame.new(
            homePos.X,
            MzD._isGod and MzD.S.GodWalkY or homePos.Y,
            homePos.Z
        ))
        twait(0.05)
    end

    -- Directe terugkeer naar base (zonder corridor, voor normaal modus)
    function MzD.returnToBase()
        if MzD._isGod then
            local homePos = MzD.getHomePosition().Position
            MzD.tweenTo(CFrame.new(homePos.X, MzD.S.GodWalkY, homePos.Z))
        else
            MzD.tweenTo(MzD.getHomePosition())
        end
        twait(0.1)
    end

end

return M
