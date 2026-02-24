-- ============================================
-- [MODULE 3] REMOTE DISCOVERY
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local ReplicatedStorage = G.ReplicatedStorage

    MzD.PlotAction = nil

    local function findPlotAction()
        local ok1, result1 = pcall(function()
            return ReplicatedStorage
                :WaitForChild("Shared", 10)
                :WaitForChild("Remotes", 10)
                :WaitForChild("Networking", 10)
                :WaitForChild("RF/PlotAction", 10)
        end)
        if ok1 and result1 then return result1 end

        local ok2, result2 = pcall(function()
            return ReplicatedStorage
                :WaitForChild("Packages", 10)
                :WaitForChild("Net", 10)
                :WaitForChild("RF/Plot.PlotAction", 10)
        end)
        if ok2 and result2 then return result2 end

        return nil
    end

    MzD.PlotAction = findPlotAction()
end

return M
