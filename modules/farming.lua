-- ============================================
-- [MODULE 16] FARMING LOOP - ULTRASPEED v2.0
-- Fix: Directe CFrame sprongen, alle modes compleet,
--      filter checks intact, pcall beveiliging
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player = G.Player
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel

    -- ─── HELPER: Directe CFrame sprong (vervangt trage tweens) ───────────────
    local function snapTo(targetPos)
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        pcall(function()
            if MzD._isGod then
                hrp.CFrame = CFrame.new(targetPos.X, MzD.S.GodWalkY or hrp.Position.Y, targetPos.Z)
            else
                hrp.CFrame = CFrame.new(targetPos.X, hrp.Position.Y, targetPos.Z)
            end
        end)
        twait(0.05)
    end

    -- ─── HELPER: Pak brainrot op met retry ───────────────────────────────────
    local function grabBrainrot(b, root)
        for attempt = 1, 5 do
            if not MzD.S.Farming then return false end
            if MzD.isDead() then
                MzD.waitForRespawn()
                twait(1)
                MzD.setHomePosition()
                if not (root and root.Parent) then return false end
                snapTo(root.Position)
            end
            if root and root.Parent then
                MzD.forceGrabPrompt(root)
                MzD.forceGrabPrompt(b)
                twait(0.2)
                MzD.Status.farmCount += 1
                return true
            else
                return false
            end
        end
        return false
    end

    -- ─── HELPER: Terugkeren naar base ─────────────────────────────────────────
    local function goBase()
        if MzD._isGod then MzD.safeReturnToBase() else MzD.returnToBase() end
    end

    -- ─── HELPER: Loop door alle actieve brainrots ─────────────────────────────
    -- Retourneert true als er minstens 1 gevonden+opgepakt is
    local function collectLoop(stopAfterOne)
        local found = false
        if not MzD.ActiveBrainrots then
            MzD.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots")
        end
        if not MzD.ActiveBrainrots then return false end

        for _, folder in pairs(MzD.ActiveBrainrots:GetChildren()) do
            if not MzD.S.Farming then break end
            if not (folder:IsA("Folder") and MzD.rarityMatches(folder.Name)) then continue end

            for _, b in pairs(folder:GetChildren()) do
                if not MzD.S.Farming or MzD.isDead() then break end
                if not MzD.matchesFilter(b, folder.Name) then continue end

                local root = MzD.findBrainrotRoot(b)
                if not root then continue end

                MzD.Status.farm = "Ophalen " .. folder.Name
                snapTo(root.Position + Vector3.new(0, 3, 0))

                local ok = grabBrainrot(b, root)
                if ok then
                    found = true
                    MzD.safeUnequip()
                    twait(0.05)
                    if stopAfterOne then
                        goBase()
                        twait(0.1)
                        return true
                    end
                end
            end
        end
        return found
    end

    -- ════════════════════════════════════════════════════════════════════════
    function MzD.startFarming()
        if MzD.farmThread then return end
        MzD.S.Farming = true
        MzD.Status.farmCount = 0
        MzD.setHomePosition()
        MzD.detectWallZ()
        goBase()

        MzD.farmThread = tspawn(function()
            while MzD.S.Farming do
                local ok, err = pcall(function()
                    if MzD.isDead() then
                        MzD.waitForRespawn()
                        twait(1)
                        MzD.setHomePosition()
                        twait(0.5)
                        return
                    end

                    local ch  = Player.Character
                    local hum = ch and ch:FindFirstChild("Humanoid")
                    if not ch or not hum then twait(1) return end
                    if not MzD.baseGUID then MzD.findBase() end
                    if not MzD.baseGUID then twait(2) return end

                    local ws = tonumber(MzD.S.FarmSlot) or 5

                    -- ═══════════════════════════════════════════
                    -- MODE: Collect Only
                    -- Ophalen → direct terug naar base → backpack
                    -- ═══════════════════════════════════════════
                    if MzD.S.FarmMode == "Collect" then
                        local found = collectLoop(false)
                        if not found then
                            MzD.Status.farm = "Wachten..."
                            twait(1)
                        else
                            goBase()
                            twait(0.2)
                        end
                        return
                    end

                    -- ═══════════════════════════════════════════
                    -- MODE: Collect, Place & Max
                    -- Ophalen → base → plaatsen → max upgraden → oppakken
                    -- ═══════════════════════════════════════════
                    if MzD.S.FarmMode == "Collect,Place&Max" then
                        -- Stap 1: zorg dat slot leeg is
                        MzD.Status.farm = "Naar base..."
                        goBase()
                        twait(0.1)

                        if not MzD.isSlotEmpty(ws) then
                            MzD.pickUpBrainrot(ws)
                            twait(0.3)
                            MzD.safeUnequip()
                            twait(0.2)
                        end

                        -- Stap 2: check backpack voor bestaande tool
                        local tool = MzD.findTargetToolInBackpack()
                        if tool and MzD.isHighRarityTool(tool) then
                            MzD.Status.farm = "High " .. (tool:GetAttribute("Rarity") or "High")
                            MzD.Status.farmCount += 1
                            twait(0.3)
                            tool = nil
                        end

                        -- Stap 3: ophalen van de map als geen tool
                        if not tool then
                            local found = collectLoop(true) -- stop na 1
                            if not found then
                                MzD.Status.farm = "Wachten..."
                                twait(2)
                                return
                            end
                            twait(0.2)
                            tool = MzD.findTargetToolInBackpack()
                            if not tool then twait(1) return end
                        end

                        -- Stap 4: skip als high rarity
                        if MzD.isHighRarityTool(tool) then
                            MzD.Status.farm = "High"
                            MzD.Status.farmCount += 1
                            twait(0.3)
                            return
                        end

                        -- Stap 5: plaatsen
                        local bName = tool:GetAttribute("BrainrotName") or "Brainrot"
                        MzD.Status.farm = "Plaatsen " .. bName
                        MzD.tweenToSlot(ws)
                        twait(0.2)
                        MzD.safeEquip(tool)
                        twait(0.3)
                        MzD.placeBrainrot(ws)
                        twait(0.6)

                        if MzD.isSlotEmpty(ws) then
                            MzD.safeUnequip()
                            twait(0.5)
                            return
                        end

                        -- Stap 6: upgraden tot max
                        local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID)
                        local sm2 = mb and mb:FindFirstChild("slot " .. ws .. " brainrot")
                        if sm2 then
                            local cur, fails = tonumber(sm2:GetAttribute("Level")) or 0, 0
                            while cur < MzD.S.MaxLevel and MzD.S.Farming do
                                MzD.upgradeBrainrot(ws)
                                twait(0.1)
                                local nw = tonumber(sm2:GetAttribute("Level")) or cur
                                if nw > cur then
                                    fails = 0
                                    cur   = nw
                                    MzD.Status.upgradeCount += 1
                                    MzD.Status.farm = bName .. " Lv." .. cur .. "/" .. MzD.S.MaxLevel
                                else
                                    fails += 1
                                    if fails > 60 then break end
                                end
                            end
                        end

                        -- Stap 7: oppakken en klaar
                        twait(0.2)
                        MzD.pickUpBrainrot(ws)
                        twait(0.5)
                        MzD.safeUnequip()
                        twait(0.2)
                        if not MzD.isSlotEmpty(ws) then
                            MzD.pickUpBrainrot(ws)
                            twait(0.3)
                            MzD.safeUnequip()
                        end

                        MzD.Status.farm = "Cyclus klaar"
                        goBase()
                        twait(0.1)
                        return
                    end

                    -- ═══════════════════════════════════════════
                    -- MODE: Normaal (default)
                    -- Spawn → place → upgrade → pickup
                    -- ═══════════════════════════════════════════

                    -- Slot leegmaken
                    if not MzD.isSlotEmpty(ws) then
                        MzD.pickUpBrainrot(ws)
                        twait(0.3)
                        MzD.safeUnequip()
                        twait(0.2)
                    end

                    -- Check backpack
                    local tool = MzD.findTargetToolInBackpack()
                    if tool and MzD.isHighRarityTool(tool) then
                        MzD.Status.farm = "High " .. (tool:GetAttribute("Rarity") or "High")
                        MzD.Status.farmCount += 1
                        twait(0.3)
                        tool = nil
                    end

                    -- Ophalen van de map
                    if not tool then
                        local found = collectLoop(true) -- stop na 1
                        if not found then
                            MzD.Status.farm = "Wachten..."
                            twait(2)
                            return
                        end
                        twait(0.2)
                        tool = MzD.findTargetToolInBackpack()
                        if not tool then twait(1) return end
                    end

                    if MzD.isHighRarityTool(tool) then
                        MzD.Status.farm = "High"
                        MzD.Status.farmCount += 1
                        twait(0.3)
                        return
                    end

                    -- Plaatsen
                    local bName = tool:GetAttribute("BrainrotName") or "Brainrot"
                    MzD.Status.farm = "Plaatsen " .. bName
                    MzD.tweenToSlot(ws)
                    twait(0.2)
                    MzD.safeEquip(tool)
                    twait(0.3)
                    MzD.placeBrainrot(ws)
                    twait(0.6)

                    if MzD.isSlotEmpty(ws) then
                        MzD.safeUnequip()
                        twait(0.5)
                        return
                    end

                    -- Upgraden
                    local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID)
                    local sm2 = mb and mb:FindFirstChild("slot " .. ws .. " brainrot")
                    if sm2 then
                        local cur, fails = tonumber(sm2:GetAttribute("Level")) or 0, 0
                        while cur < MzD.S.MaxLevel and MzD.S.Farming do
                            MzD.upgradeBrainrot(ws)
                            twait(0.1)
                            local nw = tonumber(sm2:GetAttribute("Level")) or cur
                            if nw > cur then
                                fails = 0
                                cur   = nw
                                MzD.Status.upgradeCount += 1
                                MzD.Status.farm = bName .. " Lv." .. cur .. "/" .. MzD.S.MaxLevel
                            else
                                fails += 1
                                if fails > 60 then break end
                            end
                        end
                    end

                    -- Oppakken
                    twait(0.2)
                    MzD.pickUpBrainrot(ws)
                    twait(0.5)
                    MzD.safeUnequip()
                    twait(0.2)
                    if not MzD.isSlotEmpty(ws) then
                        MzD.pickUpBrainrot(ws)
                        twait(0.3)
                        MzD.safeUnequip()
                    end

                end) -- einde pcall

                if not ok then
                    warn("[Farm] Error: " .. tostring(err))
                    twait(1)
                end
                twait(0.1)
            end -- einde while

            MzD.Status.farm = "Idle"
            MzD.farmThread  = nil
        end)
    end

    -- ════════════════════════════════════════════════════════════════════════
    function MzD.stopFarming()
        MzD.S.Farming = false
        if MzD.farmThread then
            pcall(tcancel, MzD.farmThread)
            MzD.farmThread = nil
        end
        MzD.Status.farm = "Idle"
    end

end

return M
