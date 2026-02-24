-- ============================================
-- [MODULE 14] SLOT HELPERS
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player  = G.Player
    local smatch  = G.smatch
    local tinsert = G.tinsert
    local twait   = G.twait
    local HIGH_RARITIES = Modules.state.HIGH_RARITIES

    function MzD.isSlotEmpty(s)
        if not MzD.baseGUID then MzD.findBase() end if not MzD.baseGUID then return true end
        local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID) if not mb then return true end
        local sm2 = mb:FindFirstChild("slot "..s.." brainrot") if not sm2 then return true end
        local bn  = sm2:GetAttribute("BrainrotName") return not bn or bn == ""
    end

    function MzD.findOccupiedSlots()
        if not MzD.baseGUID then MzD.findBase() end if not MzD.baseGUID then return {} end
        local mb = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID) if not mb then return {} end
        local o, slotCount = {}, MzD.getSlotCount()
        for i = 1, slotCount do
            local sm2 = mb:FindFirstChild("slot "..i.." brainrot")
            if sm2 then
                local bn = sm2:GetAttribute("BrainrotName")
                local lv = sm2:GetAttribute("Level")
                if bn and bn ~= "" then tinsert(o, {slot = i, name = bn, level = lv or 1}) end
            end
        end
        return o
    end

    function MzD.tweenToSlot(sn)
        if not MzD.baseGUID then MzD.findBase() end if not MzD.baseGUID then return false end
        local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID) if not mb then return false end
        local sm2 = mb:FindFirstChild("slot "..sn.." brainrot") if not sm2 then return false end
        local root = sm2:FindFirstChild("Root")
        if root and root:IsA("BasePart") then return MzD.tweenTo(root.CFrame * CFrame.new(0,3,0)) end
        local ok2, pos = pcall(function() return sm2:GetPivot() end)
        if ok2 and pos then return MzD.tweenTo(pos * CFrame.new(0,3,0)) end
        return false
    end

    function MzD.upgradeSlotToMax(slot)
        if not MzD.baseGUID then MzD.findBase() end if not MzD.baseGUID then return end
        local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID) if not mb then return end
        local sm2 = mb:FindFirstChild("slot "..slot.." brainrot") if not sm2 then return end
        if MzD.isHighRarity(sm2:GetAttribute("Rarity") or "") then return end
        local cur, fails = tonumber(sm2:GetAttribute("Level")) or 1, 0
        while cur < MzD.S.MaxLevel and MzD.S.AutoUpgrade do
            MzD.upgradeBrainrot(slot) twait(0.15)
            local nw = tonumber(sm2:GetAttribute("Level")) or cur
            if nw > cur then fails = 0 cur = nw MzD.Status.upgradeCount += 1
            else fails += 1 if fails >= 60 then break end end
        end
    end

    function MzD.findBrainrotRoot(b)
        if not b then return nil end
        local root = b:FindFirstChild("Root") if root and root:IsA("BasePart") then return root end
        local rendered = b:FindFirstChild("RenderedBrainrot")
        if rendered then local rr = rendered:FindFirstChild("Root") if rr and rr:IsA("BasePart") then return rr end end
        for _, desc in pairs(b:GetDescendants()) do if desc:IsA("BasePart") then return desc end end
        if b:IsA("BasePart") then return b end
        return nil
    end

    function MzD.findTargetToolInBackpack()
        local bp = Player:FindFirstChild("Backpack")
        if bp then
            for _, t in pairs(bp:GetChildren()) do
                if t:IsA("Tool") and MzD.toolMatchesRarity(t, MzD.S.TargetRarity, MzD.S.TargetMutation) then return t end
            end
        end
        local ch = Player.Character
        if ch then
            local eq = ch:FindFirstChildWhichIsA("Tool")
            if eq and MzD.toolMatchesRarity(eq, MzD.S.TargetRarity, MzD.S.TargetMutation) then return eq end
        end
        return nil
    end
end

return M
