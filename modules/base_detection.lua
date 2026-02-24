-- ============================================
-- [MODULE 8] BASE DETECTION
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player = G.Player
    local smatch = G.smatch
    local tspawn = G.tspawn
    local twait  = G.twait

    function MzD.getSlotCount()
        if not MzD.baseGUID then MzD.findBase() end
        if not MzD.baseGUID then return 40 end
        local bases = workspace:FindFirstChild("Bases")
        if not bases then return 40 end
        local myBase = bases:FindFirstChild(MzD.baseGUID)
        if not myBase then return 40 end
        local slotsFolder = myBase:FindFirstChild("Slots")
        if slotsFolder then
            local count = 0
            for _ in pairs(slotsFolder:GetChildren()) do count += 1 end
            if count > 0 then return count end
        end
        local maxSlot = 0
        for _, child in pairs(myBase:GetChildren()) do
            local s = smatch(child.Name, "^slot (%d+) brainrot$")
            if s then
                local n = tonumber(s)
                if n and n > maxSlot then maxSlot = n end
            end
        end
        return maxSlot > 0 and maxSlot or 40
    end

    function MzD.findBase()
        local bases = workspace:FindFirstChild("Bases")
        if not bases then return end
        for _, base in pairs(bases:GetChildren()) do
            pcall(function()
                local pn = base.Title.TitleGui.Frame.PlayerName
                if pn.Text == Player.Name or pn.Text == Player.DisplayName then
                    MzD.baseGUID = base.Name
                    local s1 = base:FindFirstChild("slot 1 brainrot")
                    if s1 and s1:FindFirstChild("Root") then
                        MzD.baseCFrame = s1.Root.CFrame
                    end
                end
            end)
        end
        if not MzD.homePosition then MzD.setHomePosition() end
    end

    function MzD.setHomePosition()
        local ch  = Player.Character if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart") if not hrp then return end
        MzD.homePosition = hrp.CFrame
    end

    function MzD.getHomePosition()
        return MzD.homePosition or MzD.baseCFrame or CFrame.new(124, 3.8, 22)
    end

    tspawn(function() twait(3) MzD.findBase() end)
end

return M
