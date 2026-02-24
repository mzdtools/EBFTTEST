-- ============================================
-- [MODULE 18] LUCKY BLOCKS
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player  = G.Player
    local tinsert = G.tinsert
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel
    local sfind   = G.sfind
    local slower  = G.slower

    function MzD.getLuckyBlockRarities()
        return type(MzD.S.LuckyBlockRarity) == "table" and MzD.S.LuckyBlockRarity or {MzD.S.LuckyBlockRarity}
    end
    function MzD.luckyBlockRarityMatches(bn)
        for _, r in pairs(MzD.getLuckyBlockRarities()) do if r == "Any" or sfind(bn,r) or bn == r then return true end end
        return false
    end
    function MzD.luckyBlockMutationMatches(block)
        local mut    = block:GetAttribute("Mutation") or "None"
        local isNone = (slower(mut) == "none" or mut == "")
        if MzD.S.LuckyBlockMutation == "Any" then return true end
        if MzD.S.LuckyBlockMutation == "None" then return isNone end
        return mut == MzD.S.LuckyBlockMutation
    end
    function MzD.findLuckyBlockRoot(block)
        local r = block:FindFirstChild("Root") if r and r:IsA("BasePart") then return r end
        if block:IsA("BasePart") then return block end
        local p2 = nil pcall(function() p2 = block.PrimaryPart end)
        if p2 then return p2 end
        for _, d in pairs(block:GetDescendants()) do if d:IsA("BasePart") then return d end end
        return nil
    end
    function MzD.grabLuckyBlock(block, rootPart)
        if not block or not rootPart then return end
        for _, d in pairs(block:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function() d.MaxActivationDistance=99999 d.HoldDuration=0 d.RequiresLineOfSight=false end)
                pcall(function() fireproximityprompt(d) end)
            end
        end
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if rootPart:IsA("BasePart") then
                pcall(function() firetouchinterest(hrp, rootPart, 0) firetouchinterest(hrp, rootPart, 1) end)
            end
            for _, d in pairs(block:GetDescendants()) do
                if d:IsA("BasePart") then
                    pcall(function() firetouchinterest(hrp, d, 0) firetouchinterest(hrp, d, 1) end)
                end
            end
        end
    end

    function MzD.startLuckyBlockFarm()
        if MzD.luckyBlockThread then return end
        MzD.S.LuckyBlockEnabled = true MzD.Status.luckyBlockCount = 0 MzD.setHomePosition()
        MzD.luckyBlockThread = tspawn(function()
            while MzD.S.LuckyBlockEnabled do
                pcall(function()
                    if MzD.isDead() then MzD.waitForRespawn() twait(1) MzD.setHomePosition() return end
                    if not MzD.ActiveLuckyBlocks then MzD.ActiveLuckyBlocks = workspace:FindFirstChild("ActiveLuckyBlocks") end
                    if not MzD.ActiveLuckyBlocks then twait(3) return end
                    local foundBlock = false
                    for _, block in pairs(MzD.ActiveLuckyBlocks:GetChildren()) do
                        if not MzD.S.LuckyBlockEnabled or MzD.isDead() then break end
                        if MzD.luckyBlockRarityMatches(block.Name) and MzD.luckyBlockMutationMatches(block) then
                            local rootPart = MzD.findLuckyBlockRoot(block) if not rootPart then continue end
                            foundBlock = true
                            if MzD._isGod then MzD.safePathTo(rootPart.CFrame * CFrame.new(0,3,0))
                            else MzD.tweenTo(rootPart.CFrame * CFrame.new(0,3,0)) end
                            MzD.grabLuckyBlock(block, rootPart)
                            local t2 = tick()
                            while tick() - t2 < 0.2 do
                                if not block.Parent or not rootPart.Parent then break end twait(0.02)
                            end
                            if not block.Parent or not rootPart.Parent then MzD.Status.luckyBlockCount += 1 end
                            MzD.safeUnequip()
                            if MzD._isGod then MzD.safeReturnToBase() else MzD.returnToBase() end
                            break
                        end
                    end
                    if not foundBlock then twait(2) end
                end)
                twait(0.1)
            end
            MzD.Status.luckyBlock = "Idle" MzD.luckyBlockThread = nil
        end)
    end

    function MzD.stopLuckyBlockFarm()
        MzD.S.LuckyBlockEnabled = false
        if MzD.luckyBlockThread then pcall(tcancel, MzD.luckyBlockThread) MzD.luckyBlockThread = nil end
        MzD.Status.luckyBlock = "Idle"
    end
end

return M
