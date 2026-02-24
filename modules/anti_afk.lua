-- ============================================
-- [MODULE 21] ANTI-AFK
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player  = G.Player
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel

    function MzD.startAFK()
        if MzD.afkThread then return end
        MzD.S.AntiAFK = true MzD.Status.afk = "Actief"
        pcall(function()
            for _, c in pairs(getconnections(Player.Idled)) do c:Disable() end
        end)
        MzD.afkThread = tspawn(function()
            while MzD.S.AntiAFK do
                pcall(function()
                    for _, c in pairs(getconnections(Player.Idled)) do c:Disable() end
                end)
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    twait(0.1)
                    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end)
                twait(60)
            end
            MzD.Status.afk = "Uit"
        end)
    end

    function MzD.stopAFK()
        MzD.S.AntiAFK = false
        if MzD.afkThread then pcall(tcancel, MzD.afkThread) MzD.afkThread = nil end
        if MzD._afkSteppedConn then
            pcall(function() MzD._afkSteppedConn:Disconnect() end)
            MzD._afkSteppedConn = nil
        end
        MzD.Status.afk = "Uit"
    end
end

return M
