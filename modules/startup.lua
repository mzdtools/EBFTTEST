-- ============================================
-- [MODULE 29] STARTUP
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local tspawn = G.tspawn
    local twait  = G.twait
    local mfloor = G.mfloor

    local gui = Modules.gui.guiRefs
    local Fluent = gui and gui.Fluent
    local W      = gui and gui.W

    tspawn(function()
        twait(1) MzD.findBase() twait(0.5) MzD.detectWallZ()
        if Fluent then
            Fluent:Notify({
                Title   = "MzD Hub v13.0",
                Content = "✅ Factory fix: alle brainrots + zo snel mogelijk max\n✅ Tower Trial Farm in Farm Tab\n✅ Doom Coins conflict-fix\n✅ isMzDPart bug gefixed\n✅ GUI Scale werkend",
                Duration = 8
            })
        end
    end)

    if W then W:SelectTab(1) end
    print("[MzD Hub] v13.0 GELADEN")
end

return M
