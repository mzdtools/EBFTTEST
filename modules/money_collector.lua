-- ============================================
-- [MODULE 19] MONEY COLLECTOR
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player = G.Player
    local tspawn = G.tspawn
    local twait  = G.twait
    local tcancel = G.tcancel
    local throttledPlotAction = Modules.utility.throttledPlotAction

    function MzD.startMoney()
        if MzD.moneyThread then return end
        MzD.S.AutoCollectMoney = true MzD.Status.money = "Actief"
        if not MzD.baseGUID then MzD.findBase() end

        MzD.moneyThread = tspawn(function()
            while MzD.S.AutoCollectMoney do
                pcall(function()
                    if not MzD.baseGUID then MzD.findBase() end
                    if not MzD.baseGUID then return end
                    local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID)
                    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    if not mb or not hrp then return end
                    for i = 1, MzD.getSlotCount() do
                        local sm2 = mb:FindFirstChild("slot "..i.." brainrot")
                        if sm2 and sm2:GetAttribute("BrainrotName") ~= "" then
                            for _, d in pairs(sm2:GetDescendants()) do
                                if d:IsA("BasePart") then
                                    pcall(function() firetouchinterest(hrp,d,0) firetouchinterest(hrp,d,1) end)
                                end
                            end
                        end
                    end
                end)
                twait(0.5)
            end
            MzD.Status.money = "Idle"
        end)

        MzD.moneyRemoteThread = tspawn(function()
            while MzD.S.AutoCollectMoney do
                pcall(function()
                    if not MzD.baseGUID then MzD.findBase() end
                    if not MzD.baseGUID or not MzD.PlotAction then return end
                    for i = 1, MzD.getSlotCount() do
                        if not MzD.S.AutoCollectMoney then break end
                        throttledPlotAction(MzD, "Collect Money", MzD.baseGUID, tostring(i))
                    end
                end)
                twait(5)
            end
        end)
    end

    function MzD.stopMoney()
        MzD.S.AutoCollectMoney = false
        if MzD.moneyThread       then pcall(tcancel, MzD.moneyThread)       MzD.moneyThread = nil end
        if MzD.moneyRemoteThread then pcall(tcancel, MzD.moneyRemoteThread) MzD.moneyRemoteThread = nil end
        MzD.Status.money = "Idle"
    end
end

return M
