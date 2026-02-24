-- ============================================
-- [MODULE 11] MOVEMENT & NAVIGATION
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player       = G.Player
    local TweenService = G.TweenService
    local sfind        = G.sfind
    local twait        = G.twait

    function MzD.safeEquip(tool)
        if not tool then return end
        local ch  = Player.Character if not ch then return end
        local hum = ch:FindFirstChild("Humanoid") if not hum then return end
        pcall(function() hum:EquipTool(tool) end) twait(0.4)
    end

    function MzD.safeUnequip()
        local ch  = Player.Character if not ch then return end
        local hum = ch:FindFirstChild("Humanoid") if not hum then return end
        pcall(function() hum:UnequipTools() end) twait(0.2)
    end

    function MzD.tweenTo(cf)
        local ch  = Player.Character if not ch then return false end
        local hrp = ch:FindFirstChild("HumanoidRootPart") if not hrp then return false end
        local targetCF = MzD._isGod and CFrame.new(cf.Position.X, MzD.S.GodWalkY, cf.Position.Z) or cf
        local t = math.max((hrp.Position - targetCF.Position).Magnitude / MzD.S.TweenSpeed, 0.01)
        local tw = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = targetCF})
        tw:Play() tw.Completed:Wait() return true
    end

    function MzD.fastTween(cf)
        local ch  = Player.Character if not ch then return false end
        local hrp = ch:FindFirstChild("HumanoidRootPart") if not hrp then return false end
        local targetCF = MzD._isGod and CFrame.new(cf.Position.X, MzD.S.GodWalkY, cf.Position.Z) or cf
        local t = math.max((hrp.Position - targetCF.Position).Magnitude / 99999, 0.005)
        local tw = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = targetCF})
        tw:Play() tw.Completed:Wait() return true
    end

    function MzD.corridorTween(cf)
        local ch  = Player.Character if not ch then return false end
        local hrp = ch:FindFirstChild("HumanoidRootPart") if not hrp then return false end
        local targetCF = MzD._isGod and CFrame.new(cf.Position.X, MzD.S.GodWalkY, cf.Position.Z) or cf
        local speed = math.max(MzD.S.CorridorSpeed or 1500, 50)
        local t = math.max((hrp.Position - targetCF.Position).Magnitude / speed, 0.01)
        local tw = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = targetCF})
        tw:Play() tw.Completed:Wait() return true
    end

    function MzD.mapFindCurrentMap()
        local best, bc = nil, 0
        for _, c in pairs(workspace:GetChildren()) do
            if c:IsA("Model") and sfind(c.Name,"Map") and not sfind(c.Name,"SharedInstances") then
                if c:FindFirstChild("Spawners") or c:FindFirstChild("Gaps") or c:FindFirstChild("RightWalls")
                   or c:FindFirstChild("FirstFloor") or c:FindFirstChild("Ground") then return c end
                local cnt = 0
                for _, d in pairs(c:GetDescendants()) do if d:IsA("BasePart") then cnt += 1 end if cnt > 10 then return c end end
                if cnt > bc then bc = cnt best = c end
            end
        end
        return best
    end

    function MzD.detectWallZ()
        local map = MzD.mapFindCurrentMap() if not map then return end
        local mzwalls = map:FindFirstChild("MzDHubWalls") if not mzwalls then return end
        local fw = mzwalls:FindFirstChild("FrontWall_1")
        local bw = mzwalls:FindFirstChild("BackWall_1")
        if fw then MzD._wallZ_front = fw.Position.Z - fw.Size.Z/2 - 3 end
        if bw then MzD._wallZ_back  = bw.Position.Z + bw.Size.Z/2 + 3 end
    end

    function MzD.getCorridorZ()
        MzD.detectWallZ()
        local homePos = MzD.getHomePosition().Position
        return homePos.Z >= 0 and MzD._wallZ_front or MzD._wallZ_back
    end

    function MzD.safePathTo(targetCFrame)
        local ch  = Player.Character if not ch then return false end
        local hrp = ch:FindFirstChild("HumanoidRootPart") if not hrp then return false end
        local startPos = hrp.Position
        local endPos   = targetCFrame.Position
        local SAFE_Z   = MzD.getCorridorZ()
        local SAFE_Y   = MzD._isGod and MzD.S.GodWalkY or (MzD.getHomePosition().Position.Y + 8)
        MzD.fastTween(CFrame.new(startPos.X, SAFE_Y, startPos.Z))    twait(0.05)
        MzD.corridorTween(CFrame.new(startPos.X, SAFE_Y, SAFE_Z))    twait(0.05)
        MzD.corridorTween(CFrame.new(endPos.X, SAFE_Y, SAFE_Z))      twait(0.05)
        MzD.corridorTween(CFrame.new(endPos.X, SAFE_Y, endPos.Z))    twait(0.05)
        local finalCF = MzD._isGod and CFrame.new(endPos.X, MzD.S.GodWalkY, endPos.Z) or targetCFrame
        MzD.tweenTo(finalCF) twait(0.05) return true
    end

    function MzD.safeReturnToBase()
        local ch  = Player.Character if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart") if not hrp then return end
        local curPos  = hrp.Position
        local homePos = MzD.getHomePosition().Position
        MzD.detectWallZ()
        local SAFE_Z = MzD.getCorridorZ()
        local SAFE_Y = MzD._isGod and MzD.S.GodWalkY or (homePos.Y + 8)
        MzD.fastTween(CFrame.new(curPos.X, SAFE_Y, curPos.Z))    twait(0.05)
        MzD.corridorTween(CFrame.new(curPos.X, SAFE_Y, SAFE_Z))  twait(0.05)
        MzD.corridorTween(CFrame.new(homePos.X, SAFE_Y, SAFE_Z)) twait(0.05)
        MzD.corridorTween(CFrame.new(homePos.X, SAFE_Y, homePos.Z)) twait(0.05)
        MzD.tweenTo(CFrame.new(homePos.X, MzD._isGod and MzD.S.GodWalkY or homePos.Y, homePos.Z)) twait(0.05)
    end

    function MzD.returnToBase()
        if MzD._isGod then
            local hp = MzD.getHomePosition().Position
            MzD.tweenTo(CFrame.new(hp.X, MzD.S.GodWalkY, hp.Z))
        else
            MzD.tweenTo(MzD.getHomePosition())
        end
        twait(0.1)
    end
end

return M
