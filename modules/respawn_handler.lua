-- ============================================
-- [MODULE 26] RESPAWN HANDLER
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player  = G.Player
    local twait   = G.twait
    local god_mod = Modules.god_mode

    Player.CharacterAdded:Connect(function(character)
        twait(1.5)
        if MzD.S.InstantPickup then MzD.setupInstant() end
        twait(0.5) MzD.detectWallZ()
        if MzD._isGod then
            if MzD._godHealthConn then pcall(function() MzD._godHealthConn:Disconnect() end) MzD._godHealthConn = nil end
            if MzD._godDiedConn   then pcall(function() MzD._godDiedConn:Disconnect()   end) MzD._godDiedConn = nil end
            twait(0.5) god_mod.godSetupHealth(character)
            god_mod.godDisableKillParts()
            pcall(function()
                for _, data in pairs(MzD._godOriginalFloors) do
                    if data.part and data.part.Parent then
                        data.part.CanCollide = false data.part.Transparency = 1
                    end
                end
            end)
            twait(0.3) god_mod.godTeleportUnder()
        end
    end)

    print("[MzD Hub] Core v13.0 GELADEN")
end

return M
