-- ============================================
-- [MODULE 16] FARMING LOOP - COMPLETE REWRITE v3.0
-- Modes:
--   "Collect"       → brainrot ophalen → terug naar base → unequip → herhaal
--   "Collect&Max"   → brainrot ophalen → terug naar base → plaatsen →
--                     max upgraden → oppakken → unequip → herhaal
--
-- Beweging: Tween (vloeiend, veilig)
-- God Mode: Y = -10 (vloer verlaagd), tween beweegt op die hoogte
-- Config:   COLLECT_AMOUNT = hoeveel ophalen voor terug naar base
-- ============================================

local M = {}

function M.init(Modules)
    local G       = Modules.globals
    local MzD     = G.MzD
    local Player  = G.Player
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel

    local TweenService = game:GetService("TweenService")

    -- ─────────────────────────────────────────────────────────────────────────
    -- CONFIG (aanpasbaar)
    -- ─────────────────────────────────────────────────────────────────────────
    local TWEEN_SPEED     = 300   -- studs per seconde
    local GOD_Y           = -10   -- Y hoogte bij God Mode
    local COLLECT_AMOUNT  = 1     -- hoeveel brainrots ophalen voor terug naar base
                                  -- (MzD.S.CollectAmount overschrijft dit als het bestaat)

    -- ─────────────────────────────────────────────────────────────────────────
    -- HELPER: Haal collectAmount op uit settings of gebruik default
    -- ─────────────────────────────────────────────────────────────────────────
    local function getCollectAmount()
        return tonumber(MzD.S.CollectAmount) or COLLECT_AMOUNT
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- HELPER: Tween naar positie op God Mode hoogte
    -- ─────────────────────────────────────────────────────────────────────────
    local function tweenTo(targetPos)
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local y = MzD._isGod and GOD_Y or hrp.Position.Y
        local dest = CFrame.new(targetPos.X, y, targetPos.Z)
        local dist = (Vector3.new(targetPos.X, y, targetPos.Z) - hrp.Position).Magnitude

        if dist < 3 then return end

        local info  = TweenInfo.new(dist / TWEEN_SPEED, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, info, {CFrame = dest})
        tween:Play()
        tween.Completed:Wait()
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- HELPER: Terug naar base (gebruikt bestaande MzD functies)
    -- ─────────────────────────────────────────────────────────────────────────
    local function goBase()
        if MzD._isGod then
            MzD.safeReturnToBase()
        else
            MzD.returnToBase()
        end
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- HELPER: Pak 1 brainrot op en keer terug
    -- Retourneert true als gelukt
    -- ─────────────────────────────────────────────────────────────────────────
    local function pickupOne()
        if not MzD.ActiveBrainrots then
            MzD.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots")
        end
        if not MzD.ActiveBrainrots then return false end

        for _, folder in pairs(MzD.ActiveBrainrots:GetChildren()) do
            if not MzD.S.Farming then return false end
            if not (folder:IsA("Folder") and MzD.rarityMatches(folder.Name)) then continue end

            for _, b in pairs(folder:GetChildren()) do
                if not MzD.S.Farming then return false end
                if MzD.isDead() then return false end
                if not MzD.matchesFilter(b, folder.Name) then continue end

                local root = MzD.findBrainrotRoot(b)
                if not root or not root.Parent then continue end

                -- Tween ernaartoe
                MzD.Status.farm = "Naar " .. folder.Name .. "..."
                tweenTo(root.Position)
                twait(0.15)

                -- Controleer nog of hij er nog is na tween
                if not (root and root.Parent) then continue end

                -- Oppakken
                MzD.forceGrabPrompt(root)
                MzD.forceGrabPrompt(b)
                twait(0.2)
                MzD.Status.farmCount += 1

                return true
            end
        end

        return false
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- HELPER: Upgraden tot max level op slot ws
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
                if fails > 60 then
                    warn("[Farm] Upgrade vastgelopen bij Lv." .. cur .. ", stoppen.")
                    break
                end
            end
        end
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- MAIN: startFarming
    -- ─────────────────────────────────────────────────────────────────────────
    function MzD.startFarming()
        if MzD.farmThread then return end

        MzD.S.Farming       = true
        MzD.Status.farmCount = 0
        MzD.setHomePosition()
        MzD.detectWallZ()
        goBase()

        MzD.farmThread = tspawn(function()
            while MzD.S.Farming do
                local ok, err = pcall(function()

                    -- Dood afhandelen
                    if MzD.isDead() then
                        MzD.Status.farm = "Dood, wachten op respawn..."
                        MzD.waitForRespawn()
                        twait(1.5)
                        MzD.setHomePosition()
                        goBase()
                        twait(0.5)
                        return
                    end

                    -- Character check
                    local ch  = Player.Character
                    local hum = ch and ch:FindFirstChild("Humanoid")
                    if not ch or not hum then twait(1) return end

                    -- Base check
                    if not MzD.baseGUID then MzD.findBase() end
                    if not MzD.baseGUID then twait(2) return end

                    local ws     = tonumber(MzD.S.FarmSlot) or 5
                    local amount = getCollectAmount()

                    -- ════════════════════════════════════════════
                    -- MODE: Collect
                    -- Ophalen (X keer) → base → unequip → herhaal
                    -- ════════════════════════════════════════════
                    if MzD.S.FarmMode == "Collect" then
                        local collected = 0

                        while collected < amount and MzD.S.Farming do
                            if MzD.isDead() then break end

                            local ok = pickupOne()
                            if ok then
                                collected += 1
                                MzD.Status.farm = "Opgehaald " .. collected .. "/" .. amount
                                twait(0.1)
                            else
                                -- Geen brainrot gevonden, even wachten
                                MzD.Status.farm = "Zoeken..."
                                twait(1)
                                break
                            end
                        end

                        -- Terug naar base, unequip
                        if collected > 0 then
                            MzD.Status.farm = "Terugkeren naar base..."
                            goBase()
                            twait(0.2)
                            MzD.safeUnequip()
                            twait(0.1)
                        end

                        return
                    end

                    -- ════════════════════════════════════════════
                    -- MODE: Collect&Max
                    -- Ophalen → base → plaatsen → max upgrade →
                    -- oppakken → unequip → herhaal
                    -- ════════════════════════════════════════════
                    if MzD.S.FarmMode == "Collect&Max" then
                        local collected = 0

                        -- Stap 1: ophalen (amount keer)
                        while collected < amount and MzD.S.Farming do
                            if MzD.isDead() then break end

                            local ok = pickupOne()
                            if ok then
                                collected += 1
                                MzD.Status.farm = "Opgehaald " .. collected .. "/" .. amount
                                twait(0.1)
                            else
                                MzD.Status.farm = "Zoeken..."
                                twait(1)
                                break
                            end
                        end

                        if collected == 0 then return end

                        -- Stap 2: terug naar base
                        MzD.Status.farm = "Terugkeren naar base..."
                        goBase()
                        twait(0.2)
                        MzD.safeUnequip()
                        twait(0.1)

                        -- Stap 3: haal tool op uit backpack
                        local tool = MzD.findTargetToolInBackpack()
                        if not tool then twait(1) return end

                        -- High rarity? Bewaar in backpack, niet plaatsen
                        if MzD.isHighRarityTool(tool) then
                            MzD.Status.farm = "High rarity bewaard: " .. (tool:GetAttribute("Rarity") or "?")
                            MzD.Status.farmCount += 1
                            twait(0.3)
                            return
                        end

                        -- Stap 4: slot leegmaken als bezet
                        if not MzD.isSlotEmpty(ws) then
                            MzD.Status.farm = "Slot leegmaken..."
                            MzD.pickUpBrainrot(ws)
                            twait(0.3)
                            MzD.safeUnequip()
                            twait(0.2)
                        end

                        -- Stap 5: naar slot lopen en plaatsen
                        local bName = tool:GetAttribute("BrainrotName") or "Brainrot"
                        MzD.Status.farm = "Plaatsen " .. bName .. "..."
                        MzD.tweenToSlot(ws)
                        twait(0.2)
                        MzD.safeEquip(tool)
                        twait(0.3)
                        MzD.placeBrainrot(ws)
                        twait(0.6)

                        -- Check of plaatsen gelukt is
                        if MzD.isSlotEmpty(ws) then
                            MzD.Status.farm = "Plaatsen mislukt, opnieuw..."
                            MzD.safeUnequip()
                            twait(0.5)
                            return
                        end

                        -- Stap 6: upgraden tot max
                        MzD.Status.farm = "Upgraden " .. bName .. "..."
                        upgradeToMax(ws, bName)

                        -- Stap 7: oppakken
                        twait(0.2)
                        MzD.Status.farm = "Oppakken..."
                        MzD.pickUpBrainrot(ws)
                        twait(0.5)
                        MzD.safeUnequip()
                        twait(0.2)

                        -- Dubbele check: slot echt leeg?
                        if not MzD.isSlotEmpty(ws) then
                            MzD.pickUpBrainrot(ws)
                            twait(0.3)
                            MzD.safeUnequip()
                        end

                        MzD.Status.farm = "Cyclus klaar ✓"
                        goBase()
                        twait(0.1)
                        return
                    end

                    -- ════════════════════════════════════════════
                    -- MODE: Onbekend
                    -- ════════════════════════════════════════════
                    warn("[Farm] Onbekende FarmMode: " .. tostring(MzD.S.FarmMode))
                    twait(2)

                end) -- einde pcall

                if not ok then
                    warn("[Farm] Fout: " .. tostring(err))
                    twait(1)
                end

                twait(0.1)
            end -- einde while

            MzD.Status.farm = "Idle"
            MzD.farmThread  = nil
        end)
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- MAIN: stopFarming
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
