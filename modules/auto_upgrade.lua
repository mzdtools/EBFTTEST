-- ============================================
-- [MODULE 20] AUTO UPGRADE
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel

    function MzD.startAutoUpgrade()
        if MzD.upgradeThread then return end
        MzD.S.AutoUpgrade = true MzD.Status.upgradeCount = 0
        MzD.upgradeThread = tspawn(function()
            while MzD.S.AutoUpgrade do
                pcall(function()
                    for _, info in pairs(MzD.findOccupiedSlots()) do
                        if not MzD.S.AutoUpgrade then break end
                        if info.level < MzD.S.MaxLevel then MzD.upgradeSlotToMax(info.slot) end
                    end
                    MzD.Status.upgrade = "Klaar (#"..MzD.Status.upgradeCount..")"
                end)
                twait(5)
            end
            MzD.Status.upgrade = "Idle"
        end)
    end

    function MzD.stopAutoUpgrade()
        MzD.S.AutoUpgrade = false
        if MzD.upgradeThread then pcall(tcancel, MzD.upgradeThread) MzD.upgradeThread = nil end
        MzD.Status.upgrade = "Idle"
    end
end

return M
