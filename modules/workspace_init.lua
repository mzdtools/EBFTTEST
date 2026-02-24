-- ============================================
-- [MODULE 2] WORKSPACE INIT
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD

    MzD.ActiveBrainrots   = workspace:FindFirstChild("ActiveBrainrots")
    MzD.ActiveLuckyBlocks = workspace:FindFirstChild("ActiveLuckyBlocks")

    if not MzD.ActiveBrainrots then
        G.tspawn(function()
            MzD.ActiveBrainrots = workspace:WaitForChild("ActiveBrainrots", 15)
        end)
    end
    if not MzD.ActiveLuckyBlocks then
        G.tspawn(function()
            MzD.ActiveLuckyBlocks = workspace:WaitForChild("ActiveLuckyBlocks", 15)
        end)
    end
end

return M
