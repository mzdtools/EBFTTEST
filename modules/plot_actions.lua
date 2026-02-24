-- ============================================
-- [MODULE 13] PLOT ACTION WRAPPERS
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local twait = G.twait
    local throttledPlotAction = Modules.utility.throttledPlotAction

    function MzD.placeBrainrot(s)
        if not MzD.baseGUID then return false end
        local ok = throttledPlotAction(MzD, "Place Brainrot", MzD.baseGUID, tostring(s))
        if ok then MzD.Status.placeCount += 1 end
        return ok
    end
    function MzD.pickUpBrainrot(s)    if not MzD.baseGUID then return false end return throttledPlotAction(MzD, "Pick Up Brainrot", MzD.baseGUID, tostring(s)) end
    function MzD.clearSlot(s)         if not MzD.baseGUID then return end throttledPlotAction(MzD, "Pick Up Brainrot", MzD.baseGUID, tostring(s)) twait(0.5) MzD.safeUnequip() twait(0.3) end
    function MzD.upgradeBrainrot(s)   if not MzD.baseGUID then return false end return throttledPlotAction(MzD, "Upgrade Brainrot", MzD.baseGUID, tostring(s)) end
end

return M
