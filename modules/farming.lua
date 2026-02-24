-- ============================================
-- [MODULE 16] FARMING LOOP
-- Modes:
--   "Collect"           → ophalen → base → backpack
--   "Collect,Place&Max" → ophalen → base → plaatsen → max upgraden → oppakken → backpack
--   (default)           → normale farm loop (spawn → place → upgrade → pickup)
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player = G.Player
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel

    function MzD.startFarming()
        if MzD.farmThread then return end
        MzD.S.Farming = true MzD.Status.farmCount = 0
        MzD.setHomePosition() MzD.detectWallZ() MzD.returnToBase()

        MzD.farmThread = tspawn(function()
            while MzD.S.Farming do
                local ok, err = pcall(function()
                    if MzD.isDead() then MzD.waitForRespawn() twait(1) MzD.setHomePosition() twait(0.5) return end
                    local ch  = Player.Character
                    local hum = ch and ch:FindFirstChild("Humanoid")
                    if not ch or not hum then twait(1) return end
                    if not MzD.baseGUID then MzD.findBase() end
                    if not MzD.baseGUID then twait(2) return end
                    local ws = tonumber(MzD.S.FarmSlot) or 5

                    -- ═══════════════════════════════════════════
                    -- MODE: Collect Only
                    -- ═══════════════════════════════════════════
                    if MzD.S.FarmMode == "Collect" then
                        if not MzD.ActiveBrainrots then MzD.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots") end
                        if MzD.ActiveBrainrots then
                            for _, folder in pairs(MzD.ActiveBrainrots:GetChildren()) do
                                if not MzD.S.Farming then break end
                                if folder:IsA("Folder") and MzD.rarityMatches(folder.Name) then
                                    for _, b in pairs(folder:GetChildren()) do
                                        if not MzD.S.Farming or MzD.isDead() then break end
                                        if MzD.matchesFilter(b, folder.Name) then
                                            local root = MzD.findBrainrotRoot(b) if not root then continue end
                                            MzD.Status.farm = "Ophalen "..folder.Name
                                            if MzD._isGod then MzD.safePathTo(root.CFrame * CFrame.new(0,3,0))
                                            else MzD.tweenTo(root.CFrame * CFrame.new(0,3,0)) end
                                            for attempt = 1, 5 do
                                                if not MzD.S.Farming then break end
                                                if MzD.isDead() then
                                                    MzD.waitForRespawn() twait(1) MzD.setHomePosition()
                                                    if root and root.Parent then
                                                        if MzD._isGod then MzD.safePathTo(root.CFrame * CFrame.new(0,3,0))
                                                        else MzD.tweenTo(root.CFrame * CFrame.new(0,3,0)) end
                                                    else break end
                                                end
                                                if root and root.Parent then
                                                    MzD.forceGrabPrompt(root) MzD.forceGrabPrompt(b)
                                                    twait(0.3) MzD.Status.farmCount += 1 break
                                                else break end
                                            end
                                            MzD.safeUnequip() twait(0.1)
                                            MzD.Status.farm = "Terugkeren..."
                                            if MzD._isGod then MzD.safeReturnToBase() else MzD.returnToBase() end
                                        end
                                    end
                                end
                            end
                        end
                        twait(1) return
                    end

                    -- ═══════════════════════════════════════════
                    -- MODE: Collect, Place & Max
                    -- ═══════════════════════════════════════════
                    if MzD.S.FarmMode == "Collect,Place&Max" then
                        -- Start elke cyclus bij base
                        MzD.Status.farm = "Naar base..."
                        if MzD._isGod then MzD.safeReturnToBase() else MzD.returnToBase() end
                        twait(0.2)

                        -- Slot leegmaken als bezet
                        if not MzD.isSlotEmpty(ws) then MzD.pickUpBrainrot(ws) twait(0.5) MzD.safeUnequip() twait(0.3) end

                        -- Kijk of er al een tool in backpack zit
                        local tool = MzD.findTargetToolInBackpack()
                        if tool and MzD.isHighRarityTool(tool) then
                            MzD.Status.farm = "High "..(tool:GetAttribute("Rarity") or "High")
                            MzD.Status.farmCount += 1 twait(0.5) tool = nil
                        end

                        -- Geen tool → ophalen van de map
                        if not tool then
                            local found = false
                            if not MzD.ActiveBrainrots then MzD.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots") end
                            if MzD.ActiveBrainrots then
                                for _, folder in pairs(MzD.ActiveBrainrots:GetChildren()) do
                                    if not MzD.S.Farming then break end
                                    if folder:IsA("Folder") and MzD.rarityMatches(folder.Name) then
                                        for _, b in pairs(folder:GetChildren()) do
                                            if not MzD.S.Farming or MzD.isDead() then break end
                                            if MzD.matchesFilter(b, folder.Name) then
                                                local root = MzD.findBrainrotRoot(b) if not root then continue end
                                                found = true
                                                MzD.Status.farm = "Ophalen "..folder.Name
                                                if MzD._isGod then MzD.safePathTo(root.CFrame * CFrame.new(0,3,0))
                                                else MzD.tweenTo(root.CFrame * CFrame.new(0,3,0)) end
                                                for attempt = 1, 5 do
                                                    if not MzD.S.Farming then break end
                                                    if MzD.isDead() then
                                                        MzD.waitForRespawn() twait(1) MzD.setHomePosition()
                                                        if not MzD.S.Farming then break end
                                                        if root and root.Parent then
                                                            if MzD._isGod then MzD.safePathTo(root.CFrame * CFrame.new(0,3,0))
                                                            else MzD.tweenTo(root.CFrame * CFrame.new(0,3,0)) end
                                                        else found = false break end
                                                    end
                                                    if root and root.Parent then
                                                        MzD.forceGrabPrompt(root) MzD.forceGrabPrompt(b)
                                                        twait(0.3) MzD.Status.farmCount += 1 break
                                                    else found = false break end
                                                end
                                                MzD.safeUnequip() twait(0.1)
                                                -- Terugkeren naar base na ophalen
                                                MzD.Status.farm = "Terugkeren naar base..."
                                                if MzD._isGod then MzD.safeReturnToBase() else MzD.returnToBase() end
                                                twait(0.2)
                                                break
                                            end
                                        end
                                    end
                                    if found then break end
                                end
                            end
                            if not found then MzD.Status.farm = "Wachten..." twait(2) return end
                            twait(0.3)
                            tool = MzD.findTargetToolInBackpack()
                            if not tool then twait(1) return end
                        end

                        -- High rarity skip
                        if MzD.isHighRarityTool(tool) then MzD.Status.farm = "High" MzD.Status.farmCount += 1 twait(0.5) return end

                        -- Plaatsen, upgraden, oppakken
                        local bName = tool:GetAttribute("BrainrotName") or "Brainrot"
                        MzD.Status.farm = "Plaatsen "..bName.."..."
                        MzD.tweenToSlot(ws) twait(0.3)
                        MzD.safeEquip(tool) twait(0.5)
                        MzD.placeBrainrot(ws) twait(0.8)
                        if MzD.isSlotEmpty(ws) then MzD.safeUnequip() twait(1) return end

                        -- Upgraden tot max
                        local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID)
                        local sm2 = mb and mb:FindFirstChild("slot "..ws.." brainrot")
                        if sm2 then
                            local cur, fails = tonumber(sm2:GetAttribute("Level")) or 0, 0
                            while cur < MzD.S.MaxLevel and MzD.S.Farming do
                                MzD.upgradeBrainrot(ws) twait(0.15)
                                local nw = tonumber(sm2:GetAttribute("Level")) or cur
                                if nw > cur then fails = 0 cur = nw MzD.Status.upgradeCount += 1 MzD.Status.farm = bName.." Lv."..cur.."/"..MzD.S.MaxLevel
                                else fails += 1 if fails > 60 then break end end
                            end
                        end

                        -- Oppakken → backpack
                        twait(0.3)
                        MzD.pickUpBrainrot(ws) twait(0.8) MzD.safeUnequip() twait(0.3)
                        if not MzD.isSlotEmpty(ws) then MzD.pickUpBrainrot(ws) twait(0.5) MzD.safeUnequip() twait(0.3) end

                        -- Terugkeren na volledige cyclus
                        MzD.Status.farm = "Cyclus klaar, terugkeren..."
                        if MzD._isGod then MzD.safeReturnToBase() else MzD.returnToBase() end
                        twait(0.2)
                        return
                    end

                    -- ═══════════════════════════════════════════
                    -- MODE: Normaal (default)
                    -- ═══════════════════════════════════════════
                    if not MzD.isSlotEmpty(ws) then MzD.pickUpBrainrot(ws) twait(0.5) MzD.safeUnequip() twait(0.3) end
                    local tool = MzD.findTargetToolInBackpack()
                    if tool and MzD.isHighRarityTool(tool) then
                        MzD.Status.farm = "High "..(tool:GetAttribute("Rarity") or "High")
                        MzD.Status.farmCount += 1 twait(0.5) tool = nil
                    end
                    if not tool then
                        local found = false
                        if not MzD.ActiveBrainrots then MzD.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots") end
                        if MzD.ActiveBrainrots then
                            for _, folder in pairs(MzD.ActiveBrainrots:GetChildren()) do
                                if not MzD.S.Farming then break end
                                if folder:IsA("Folder") and MzD.rarityMatches(folder.Name) then
                                    for _, b in pairs(folder:GetChildren()) do
                                        if not MzD.S.Farming or MzD.isDead() then break end
                                        if MzD.matchesFilter(b, folder.Name) then
                                            local root = MzD.findBrainrotRoot(b) if not root then continue end
                                            found = true
                                            MzD.Status.farm = "Ophalen "..folder.Name
                                            if MzD._isGod then MzD.safePathTo(root.CFrame * CFrame.new(0,3,0))
                                            else MzD.tweenTo(root.CFrame * CFrame.new(0,3,0)) end
                                            for attempt = 1, 5 do
                                                if not MzD.S.Farming then break end
                                                if MzD.isDead() then
                                                    MzD.waitForRespawn() twait(1) MzD.setHomePosition()
                                                    if not MzD.S.Farming then break end
                                                    if root and root.Parent then
                                                        if MzD._isGod then MzD.safePathTo(root.CFrame * CFrame.new(0,3,0))
                                                        else MzD.tweenTo(root.CFrame * CFrame.new(0,3,0)) end
                                                    else found = false break end
                                                end
                                                if root and root.Parent then
                                                    MzD.forceGrabPrompt(root) MzD.forceGrabPrompt(b)
                                                    twait(0.3) MzD.Status.farmCount += 1 break
                                                else found = false break end
                                            end
                                            MzD.safeUnequip() twait(0.1)
                                            if MzD._isGod then MzD.safeReturnToBase() else MzD.returnToBase() end
                                            break
                                        end
                                    end
                                end
                                if found then break end
                            end
                        end
                        if not found then MzD.Status.farm = "Wachten..." twait(2) return end
                        twait(0.3)
                        tool = MzD.findTargetToolInBackpack()
                        if not tool then twait(1) return end
                    end
                    if MzD.isHighRarityTool(tool) then MzD.Status.farm = "High" MzD.Status.farmCount += 1 twait(0.5) return end
                    local bName = tool:GetAttribute("BrainrotName") or "Brainrot"
                    MzD.tweenToSlot(ws) twait(0.3)
                    MzD.safeEquip(tool) twait(0.5)
                    MzD.placeBrainrot(ws) twait(0.8)
                    if MzD.isSlotEmpty(ws) then MzD.safeUnequip() twait(1) return end
                    local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID)
                    local sm2 = mb and mb:FindFirstChild("slot "..ws.." brainrot")
                    if sm2 then
                        local cur, fails = tonumber(sm2:GetAttribute("Level")) or 0, 0
                        while cur < MzD.S.MaxLevel and MzD.S.Farming do
                            MzD.upgradeBrainrot(ws) twait(0.15)
                            local nw = tonumber(sm2:GetAttribute("Level")) or cur
                            if nw > cur then fails = 0 cur = nw MzD.Status.upgradeCount += 1 MzD.Status.farm = bName.." Lv."..cur.."/"..MzD.S.MaxLevel
                            else fails += 1 if fails > 60 then break end end
                        end
                    end
                    twait(0.3)
                    MzD.pickUpBrainrot(ws) twait(0.8) MzD.safeUnequip() twait(0.3)
                    if not MzD.isSlotEmpty(ws) then MzD.pickUpBrainrot(ws) twait(0.5) MzD.safeUnequip() twait(0.3) end
                end)
                if not ok then twait(1) end
                twait(0.3)
            end
            MzD.Status.farm = "Idle" MzD.farmThread = nil
        end)
    end

    function MzD.stopFarming()
        MzD.S.Farming = false
        if MzD.farmThread then pcall(tcancel, MzD.farmThread) MzD.farmThread = nil end
        MzD.Status.farm = "Idle"
    end
end

return M
