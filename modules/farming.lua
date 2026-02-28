-- ============================================
-- [MODULE 16] FARMING LOOP - REWRITE v4.0
-- Gebaseerd op volledige codebase analyse
--
-- MODES:
--   "Collect"          → brainrot ophalen (X keer) → terug naar base → unequip → herhaal
--   "Collect, Place & Max" → ophalen → base → plaatsen op slot → max upgraden → oppakken → unequip → herhaal
--
-- BEWEGING:
--   God Mode AAN  → MzD.safePathTo() (via corridor, veilig pad)
--   God Mode UIT  → MzD.tweenTo()    (directe tween op vloer hoogte)
--
-- SETTINGS:
--   MzD.S.FarmMode    = "Collect" of "Collect, Place & Max"
--   MzD.S.FarmSlot    = "5"   (welk slot plaatsen)
--   MzD.S.MaxLevel    = 250
--   MzD.S.TweenSpeed  = 9999  (studs/s, al geconfigureerd in settings)
-- ============================================

local M = {}

function M.init(Modules)
    local G       = Modules.globals
    local MzD     = G.MzD
    local Player  = G.Player
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel

    -- ─────────────────────────────────────────────────────────────────────────
    -- INTERN: Beweeg naar een positie (gebruikt bestaande MzD movement)
    -- God Mode → safePathTo (corridor routing, veilig)
    -- Normaal  → tweenTo (direct)
    -- ─────────────────────────────────────────────────────────────────────────
    local function moveTo(targetCF)
        if MzD._isGod then
            MzD.safePathTo(targetCF)
        else
            MzD.tweenTo(targetCF)
        end
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- INTERN: Terug naar base
    -- ─────────────────────────────────────────────────────────────────────────
    local function goBase()
        if MzD._isGod then
            MzD.safeReturnToBase()
        else
            MzD.returnToBase()
        end
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- INTERN: Zoek en pak 1 brainrot op van de map
    -- Retourneert true als gelukt, false als niets gevonden
    -- ─────────────────────────────────────────────────────────────────────────
    local function pickupOne()
        -- Zorg dat ActiveBrainrots gecached is
        if not MzD.ActiveBrainrots or not MzD.ActiveBrainrots.Parent then
            MzD.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots")
        end
        if not MzD.ActiveBrainrots then return false end

        for _, folder in pairs(MzD.ActiveBrainrots:GetChildren()) do
            if not MzD.S.Farming then return false end
            if not folder:IsA("Folder") then continue end
            if not MzD.rarityMatches(folder.Name) then continue end

            for _, b in pairs(folder:GetChildren()) do
                if not MzD.S.Farming then return false end
                if MzD.isDead() then return false end
                if not MzD.matchesFilter(b, folder.Name) then continue end

                local root = MzD.findBrainrotRoot(b)
                if not root or not root.Parent then continue end

                -- Beweeg ernaartoe
                MzD.Status.farm = "Naar " .. folder.Name .. "..."
                moveTo(root.CFrame * CFrame.new(0, 3, 0))
                twait(0.1)

                -- Controleer of de brainrot er nog is
                if not root.Parent then continue end

                -- Oppakken
                MzD.forceGrabPrompt(root)
                MzD.forceGrabPrompt(b)
                twait(0.15)

                MzD.Status.farmCount += 1
                return true
            end
        end

        return false
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- INTERN: Upgrade brainrot op slot ws tot MaxLevel
    -- ─────────────────────────────────────────────────────────────────────────
    local function upgradeToMax(ws, bName)
        local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID)
        local sm  = mb and mb:FindFirstChild("slot " .. ws .. " brainrot")
        if not sm then return end

        local cur   = tonumber(sm:GetAttribute("Level")) or 0
        local fails = 0

        while cur < MzD.S.MaxLevel and MzD.S.Farming do
            MzD.upgradeBrainrot(ws)
            twait(0.1)

            local nw = tonumber(sm:GetAttribute("Level")) or cur
            if nw > cur then
                fails = 0
                cur   = nw
                MzD.Status.upgradeCount += 1
                MzD.Status.farm = (bName or "Brainrot") .. " Lv." .. cur .. "/" .. MzD.S.MaxLevel
            else
                fails += 1
                if fails >= 60 then
                    warn("[Farm] Upgrade vastgelopen bij Lv." .. cur .. ", verder gaan.")
                    break
                end
            end
        end
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- INTERN: Doe een complete "Collect" cyclus
    -- Pakt 'amount' brainrots op → terug naar base → unequip
    -- ─────────────────────────────────────────────────────────────────────────
    local function doCollectCycle(amount)
        local collected = 0

        while collected < amount and MzD.S.Farming do
            if MzD.isDead() then break end

            local ok = pickupOne()
            if ok then
                collected += 1
                MzD.Status.farm = "Opgehaald " .. collected .. "/" .. amount
                twait(0.05)
            else
                MzD.Status.farm = "Geen brainrot gevonden, wachten..."
                twait(1.5)
                break
            end
        end

        if collected > 0 then
            MzD.Status.farm = "Terugkeren naar base..."
            goBase()
            twait(0.1)
            MzD.safeUnequip()
            twait(0.1)
        end

        return collected
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- INTERN: Doe een complete "Collect, Place & Max" cyclus
    -- Pakt 1 brainrot op → base → slot leegmaken → plaatsen → upgraden → oppakken → unequip
    -- ─────────────────────────────────────────────────────────────────────────
    local function doCollectAndMaxCycle(ws)
        -- Stap 1: ophalen van de map
        local ok = pickupOne()
        if not ok then
            MzD.Status.farm = "Geen brainrot gevonden, wachten..."
            twait(1.5)
            return false
        end

        -- Stap 2: terug naar base, unequip
        MzD.Status.farm = "Terugkeren naar base..."
        goBase()
        twait(0.1)
        MzD.safeUnequip()
        twait(0.1)

        -- Stap 3: tool vinden in backpack
        local tool = MzD.findTargetToolInBackpack()
        if not tool then
            twait(0.5)
            return false
        end

        -- Stap 4: high rarity → bewaren, niet plaatsen
        if MzD.isHighRarityTool(tool) then
            MzD.Status.farm = "High rarity bewaard: " .. (tool:GetAttribute("Rarity") or "?")
            MzD.Status.farmCount += 1
            return true
        end

        -- Stap 5: slot leegmaken als bezet
        if not MzD.isSlotEmpty(ws) then
            MzD.Status.farm = "Slot " .. ws .. " leegmaken..."
            MzD.pickUpBrainrot(ws)
            twait(0.3)
            MzD.safeUnequip()
            twait(0.2)
        end

        -- Stap 6: naar slot gaan en plaatsen
        local bName = tool:GetAttribute("BrainrotName") or "Brainrot"
        MzD.Status.farm = "Plaatsen " .. bName .. " op slot " .. ws .. "..."
        MzD.tweenToSlot(ws)
        twait(0.2)
        MzD.safeEquip(tool)
        twait(0.3)
        MzD.placeBrainrot(ws)
        twait(0.6)

        -- Controleer of plaatsen gelukt is
        if MzD.isSlotEmpty(ws) then
            MzD.Status.farm = "Plaatsen mislukt, volgende cyclus..."
            MzD.safeUnequip()
            twait(0.5)
            return false
        end

        -- Stap 7: upgraden tot max
        MzD.Status.farm = "Upgraden " .. bName .. "..."
        upgradeToMax(ws, bName)

        -- Stap 8: oppakken
        MzD.Status.farm = "Oppakken..."
        twait(0.2)
        MzD.pickUpBrainrot(ws)
        twait(0.5)
        MzD.safeUnequip()
        twait(0.2)

        -- Dubbele check: slot echt leeg?
        if not MzD.isSlotEmpty(ws) then
            MzD.pickUpBrainrot(ws)
            twait(0.3)
            MzD.safeUnequip()
            twait(0.1)
        end

        MzD.Status.farm = "Cyclus klaar ✓"
        goBase()
        twait(0.1)
        return true
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- PUBLIC: startFarming
    -- ─────────────────────────────────────────────────────────────────────────
    function MzD.startFarming()
        if MzD.farmThread then return end

        MzD.S.Farming        = true
        MzD.Status.farmCount = 0
        MzD.setHomePosition()
        MzD.detectWallZ()
        goBase()

        MzD.farmThread = tspawn(function()
            while MzD.S.Farming do
                local ok, err = pcall(function()

                    -- ── Dood afhandelen ──────────────────────────────────────
                    if MzD.isDead() then
                        MzD.Status.farm = "Dood, respawn afwachten..."
                        MzD.waitForRespawn()
                        twait(1.5)
                        MzD.setHomePosition()
                        MzD.detectWallZ()
                        goBase()
                        twait(0.5)
                        return
                    end

                    -- ── Character check ──────────────────────────────────────
                    local ch  = Player.Character
                    local hum = ch and ch:FindFirstChild("Humanoid")
                    if not ch or not hum then twait(1) return end

                    -- ── Base check ───────────────────────────────────────────
                    if not MzD.baseGUID then MzD.findBase() end
                    if not MzD.baseGUID then
                        MzD.Status.farm = "Base niet gevonden..."
                        twait(2)
                        return
                    end

                    local ws     = tonumber(MzD.S.FarmSlot) or 5
                    local amount = tonumber(MzD.S.CollectAmount) or 1
                    local mode   = MzD.S.FarmMode

                    -- ════════════════════════════════════════════════════════
                    -- MODE: Collect
                    -- ════════════════════════════════════════════════════════
                    if mode == "Collect" then
                        doCollectCycle(amount)
                        return
                    end

                    -- ════════════════════════════════════════════════════════
                    -- MODE: Collect, Place & Max
                    -- ════════════════════════════════════════════════════════
                    if mode == "Collect, Place & Max" then
                        doCollectAndMaxCycle(ws)
                        return
                    end

                    -- ════════════════════════════════════════════════════════
                    -- MODE: Onbekend / fallback
                    -- ════════════════════════════════════════════════════════
                    warn("[Farm] Onbekende FarmMode: '" .. tostring(mode) .. "'")
                    warn("[Farm] Gebruik 'Collect' of 'Collect, Place & Max'")
                    twait(3)

                end) -- einde pcall

                if not ok then
                    warn("[Farm] Onverwachte fout: " .. tostring(err))
                    twait(1)
                end

                twait(0.05)
            end -- einde while

            MzD.Status.farm = "Idle"
            MzD.farmThread  = nil
        end)
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- PUBLIC: stopFarming
    -- ─────────────────────────────────────────────────────────────────────────
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
