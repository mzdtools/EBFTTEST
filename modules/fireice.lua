-- ============================================
-- [MODULE] FIRE & ICE EVENT FARM
-- ============================================

local M = {}

function M.init(Modules)
    local G       = Modules.globals
    local MzD     = G.MzD
    local Player  = G.Player
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel
    local tinsert = G.tinsert
    local tsort   = G.tsort
    local mfloor  = G.mfloor
    local sfind   = G.sfind
    local slower  = G.slower

    MzD.Status.fireice = "Idle"
    MzD._fireiceEnabled = false

    local function getFireiceFolder()
        local mogelijkeNamen = {"FireiceCoins", "FireiceEvent", "FireiceEventParts", "Fireice", "FireAndIce"}
        for _, naam in ipairs(mogelijkeNamen) do
            local folder = workspace:FindFirstChild(naam)
            if folder then return folder end
        end
        
        local eventsFolder = workspace:FindFirstChild("GameObjects") and workspace.GameObjects:FindFirstChild("Events")
        if eventsFolder then
            for _, child in pairs(eventsFolder:GetChildren()) do
                if sfind(slower(child.Name), "fireice") or sfind(slower(child.Name), "fireandice") then
                    return child
                end
            end
        end
        return nil
    end

    function MzD.startFireice()
        if MzD._fireiceThread then return end
        MzD._fireiceEnabled = true
        MzD.Status.fireice = "Opstarten..."

        MzD._fireiceThread = tspawn(function()
            while MzD._fireiceEnabled do
                local ok, err = pcall(function()
                    if MzD.isDead() then MzD.waitForRespawn() twait(2) return end

                    local coinsFolder = getFireiceFolder()
                    if not coinsFolder then 
                        MzD.Status.fireice = "⏳ Wachten op Fire & Ice map..."
                        twait(2) return 
                    end

                    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    local list = {}

                    for _, coin in pairs(coinsFolder:GetChildren()) do
                        local root = coin:FindFirstChild("Root") or coin:FindFirstChildWhichIsA("BasePart") or coin.PrimaryPart
                        if root then
                            local dist = hrp and (hrp.Position - root.Position).Magnitude or 0
                            tinsert(list, {model = coin, root = root, dist = dist})
                        end
                    end

                    if #list == 0 then
                        MzD.Status.fireice = "⏳ Geen coins op de map..."
                        twait(1.5) return
                    end

                    tsort(list, function(a, b) return a.dist < b.dist end)
                    local target = list[1]
                    MzD.Status.fireice = "🪙 Ophalen (" .. mfloor(target.dist) .. "m)"

                    MzD.safePathTo(target.root.CFrame * CFrame.new(0, 2, 0))

                    for attempt = 1, 15 do
                        if not MzD._fireiceEnabled then break end
                        if not target.model or target.model.Parent ~= coinsFolder then break end 
                        
                        if target.root then
                            pcall(function()
                                local char = Player.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.HumanoidRootPart.CFrame = target.root.CFrame
                                end
                            end)
                        end
                        
                        MzD.forceGrabPrompt(target.root)
                        MzD.forceGrabPrompt(target.model)
                        
                        for _, d in pairs(target.model:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then
                                pcall(function() fireproximityprompt(d) end)
                            end
                        end
                        twait(0.2)
                    end
                end)

                if not ok then
                    MzD.Status.fireice = "❌ Fout: " .. tostring(err):sub(1,40)
                    twait(2)
                end
                twait(0.1)
            end

            MzD.Status.fireice = "Gestopt"
            MzD._fireiceThread = nil
        end)
    end

    function MzD.stopFireice()
        MzD._fireiceEnabled = false
        if MzD._fireiceThread then 
            pcall(tcancel, MzD._fireiceThread) 
            MzD._fireiceThread = nil 
        end
        MzD.Status.fireice = "Idle"
    end
end

return M
