-- ============================================
-- [MODULE] FIREFICE EVENT FARM
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

    -- Initialiseer status
    MzD.Status.firefice = "Idle"
    MzD._fireficeEnabled = false

    -- Slimme functie om de map met coins te vinden
    local function getFireficeFolder()
        -- Probeer eerst directe namen in workspace
        local mogelijkeNamen = {"FireficeCoins", "FireficeEvent", "FireficeEventParts", "Firefice"}
        for _, naam in ipairs(mogelijkeNamen) do
            local folder = workspace:FindFirstChild(naam)
            if folder then return folder end
        end
        
        -- Fallback: Zoek in GameObjects of Events als ze daar zitten
        local eventsFolder = workspace:FindFirstChild("GameObjects") and workspace.GameObjects:FindFirstChild("Events")
        if eventsFolder then
            for _, child in pairs(eventsFolder:GetChildren()) do
                if sfind(slower(child.Name), "firefice") then
                    return child
                end
            end
        end

        return nil
    end

    function MzD.startFireficeCoinFarm()
        if MzD._fireficeThread then return end
        MzD._fireficeEnabled = true
        MzD.Status.firefice = "Opstarten..."

        MzD._fireficeThread = tspawn(function()
            while MzD._fireficeEnabled do
                local ok, err = pcall(function()
                    if MzD.isDead() then MzD.waitForRespawn() twait(2) return end

                    local coinsFolder = getFireficeFolder()
                    if not coinsFolder then 
                        MzD.Status.firefice = "⏳ Wachten op Firefice map..."
                        twait(2) return 
                    end

                    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    local list = {}

                    -- Verzamel alle coins
                    for _, coin in pairs(coinsFolder:GetChildren()) do
                        local root = coin:FindFirstChild("Root") or coin:FindFirstChildWhichIsA("BasePart") or coin.PrimaryPart
                        if root then
                            local dist = hrp and (hrp.Position - root.Position).Magnitude or 0
                            tinsert(list, {model = coin, root = root, dist = dist})
                        end
                    end

                    if #list == 0 then
                        MzD.Status.firefice = "⏳ Geen coins op de map..."
                        twait(1.5) return
                    end

                    -- Sorteer op dichtstbijzijnde
                    tsort(list, function(a, b) return a.dist < b.dist end)
                    
                    local target = list[1]
                    MzD.Status.firefice = "🪙 Ophalen (" .. mfloor(target.dist) .. "m)"

                    -- Beweeg naar de coin
                    MzD.safePathTo(target.root.CFrame * CFrame.new(0, 2, 0))

                    -- Oppakken (Touch + Prompts)
                    for attempt = 1, 15 do
                        if not MzD._fireficeEnabled then break end
                        if not target.model or target.model.Parent ~= coinsFolder then break end -- Coin is al verdwenen
                        
                        -- CFrame Lock voor Touch-events (vergelijkbaar met de verbeterde brainrot pickup)
                        if target.root then
                            pcall(function()
                                local char = Player.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.HumanoidRootPart.CFrame = target.root.CFrame
                                end
                            end)
                        end
                        
                        -- Vuur eventuele prompts af (voor de zekerheid)
                        MzD.forceGrabPrompt(target.root)
                        MzD.forceGrabPrompt(target.model)
                        
                        -- Vuur ook geneste prompts af
                        for _, d in pairs(target.model:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then
                                pcall(function() fireproximityprompt(d) end)
                            end
                        end
                        
                        twait(0.2)
                    end
                end)

                if not ok then
                    MzD.Status.firefice = "❌ Fout: " .. tostring(err):sub(1,40)
                    twait(2)
                end
                twait(0.1)
            end

            MzD.Status.firefice = "Gestopt"
            MzD._fireficeThread = nil
        end)
    end

    function MzD.stopFireficeCoinFarm()
        MzD._fireficeEnabled = false
        if MzD._fireficeThread then 
            pcall(tcancel, MzD._fireficeThread) 
            MzD._fireficeThread = nil 
        end
        MzD.Status.firefice = "Idle"
    end
end

return M
