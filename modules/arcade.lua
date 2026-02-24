-- ============================================
-- [MODULE 24] ARCADE EVENT
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player  = G.Player
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel

    function MzD.startArcade()
        if MzD.arcadeThread then return end
        MzD.S.ArcadeEnabled = true MzD.Status.arcadeCount = 0
        MzD.arcadeThread = tspawn(function()
            while MzD.S.ArcadeEnabled do
                pcall(function()
                    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, fn in pairs({"ArcadeEventConsoles","ArcadeEventTickets"}) do
                        local f = workspace:FindFirstChild(fn)
                        if f then
                            for _, item in pairs(f:GetChildren()) do
                                for _, d in pairs(item:GetDescendants()) do
                                    if d:IsA("BasePart") and d:FindFirstChild("TouchInterest") then
                                        pcall(function()
                                            firetouchinterest(hrp, d, 0) twait(0.01) firetouchinterest(hrp, d, 1)
                                        end)
                                        MzD.Status.arcadeCount += 1
                                    end
                                end
                            end
                        end
                    end
                end)
                twait(0.05)
            end
            MzD.Status.arcade = "Idle" MzD.arcadeThread = nil
        end)
    end

    function MzD.stopArcade()
        MzD.S.ArcadeEnabled = false
        if MzD.arcadeThread then pcall(tcancel, MzD.arcadeThread) MzD.arcadeThread = nil end
        MzD.Status.arcade = "Idle"
    end
end

return M
