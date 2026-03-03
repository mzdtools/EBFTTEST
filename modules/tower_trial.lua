-- ============================================
-- [MODULE 17] TOWER TRIAL FARM
-- ============================================
local M = {}

function M.init(Modules)
    local G       = Modules.globals
    local MzD     = G.MzD
    local Player  = G.Player
    local tinsert = G.tinsert
    local tsort   = G.tsort
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel
    local sfind   = G.sfind
    local slower  = G.slower
    local sformat = G.sformat
    local mfloor  = G.mfloor

    -- ============================================
    -- TOWER DETECTIE
    -- Gebruikt findGameObjectsRoot uit map_utils
    -- zodat er geen duplicatie is met god_mode
    -- ============================================

    local function getTower()
        local root = MzD.mapGetGameObjectsRoot and MzD.mapGetGameObjectsRoot()
        if root then
            local tower = root:FindFirstChild("Tower")
            if tower then return tower end
        end
        -- Fallback: zoek in workspace
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc.Name == "Tower" and desc:IsA("Model") then
                local count = 0
                for _, d in ipairs(desc:GetDescendants()) do
                    if d:IsA("BasePart") then count += 1 end
                    if count > 5 then return desc end
                end
            end
        end
        return nil
    end

    -- ============================================
    -- TOWER VISUAL CLEANER
    -- Verwijdert storende visuals zodat alleen
    -- het functionele gedeelte overblijft
    -- ============================================

    local function cleanTowerVisuals()
        local tower = getTower()
        if not tower then return end

        for _, child in ipairs(tower:GetChildren()) do
            if child.Name ~= "Main" then
                pcall(function()
                    if child:IsA("BasePart") then
                        child.Transparency = 1
                        child.CanCollide   = false
                    elseif child:IsA("Model") then
                        for _, desc in ipairs(child:GetDescendants()) do
                            if desc:IsA("BasePart") then
                                desc.Transparency = 1
                                desc.CanCollide   = false
                            elseif desc:IsA("Decal") or desc:IsA("Texture") then
                                desc.Transparency = 1
                            elseif desc:IsA("ParticleEmitter") or desc:IsA("Light") then
                                desc.Enabled = false
                            end
                        end
                    elseif child:IsA("ParticleEmitter") or child:IsA("Light") then
                        child.Enabled = false
                    end
                end)
            else
                -- Verwijder ook particles/beams binnen Main
                pcall(function()
                    for _, desc in ipairs(child:GetDescendants()) do
                        if desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Trail") then
                            desc.Enabled = false
                        end
                    end
                end)
            end
        end
    end

    -- ============================================
    -- PROXIMITY PROMPTS
    -- ============================================

    local function fireAllPrompts(targetModel)
        if not targetModel then return end
        for _, desc in ipairs(targetModel:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                pcall(function()
                    desc.RequiresLineOfSight    = false
                    desc.HoldDuration           = 0
                    desc.MaxActivationDistance  = 99999
                    desc.Enabled                = true
                end)
                if fireproximityprompt then
                    pcall(function() fireproximityprompt(desc) end)
                end
            end
        end
    end

    -- ============================================
    -- HUD UITLEZEN
    -- ============================================

    local function getTrialBar()
        local hud = Player.PlayerGui:FindFirstChild("TowerTrialHUD")
        return hud and hud:FindFirstChild("TrialBar")
    end

    local function getTimer()
        local bar = getTrialBar() if not bar then return "" end
        local label = bar:FindFirstChild("Timer")
        return label and label.Text or ""
    end

    local function getDeposits()
        local bar = getTrialBar() if not bar then return 0, 10 end
        local label = bar:FindFirstChild("Deposits") if not label then return 0, 10 end
        local current, goal = label.Text:match("(%d+)%s*/%s*(%d+)")
        return tonumber(current) or 0, tonumber(goal) or 10
    end

    local function getRequiredRarity()
        local bar = getTrialBar() if not bar then return "?" end
        local label = bar:FindFirstChild("Requirement")
        if label and label.Text ~= "" then
            local text = label.Text:gsub("<[^>]+>", ""):match("^%s*(.-)%s*$")
            if text ~= "" then return text:match("Tower Trial:%s*(.+)") or text end
        end
        for _, child in ipairs(bar:GetDescendants()) do
            if child:IsA("TextLabel") and child.Text ~= "" then
                local text   = child.Text:gsub("<[^>]+>", "")
                local rarity = text:match("Tower Trial:%s*(.+)")
                if rarity then return rarity:match("^%s*(.-)%s*$") end
            end
        end
        return "?"
    end

    local function isTrialActive()
        local bar = getTrialBar()
        if not bar or not bar.Visible then return false end
        local timer = getTimer()
        return timer ~= "" and timer ~= "00:00" and timer ~= "0:00"
    end

    local function getLiveCooldown()
        local tower = getTower() if not tower then return nil end
        for _, desc in ipairs(tower:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text ~= "" then
                local minutes, seconds = desc.Text:match("(%d%d?):(%d%d)")
                if minutes and seconds then
                    return (tonumber(minutes) * 60) + tonumber(seconds)
                end
            end
        end
        return nil
    end

    -- ============================================
    -- HELPERS
    -- ============================================

    local function killRewardPopups()
        pcall(function()
            for _, gui in ipairs(Player.PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                    local text = slower(gui.Text)
                    if sfind(text, "claim") or sfind(text, "reward") or sfind(text, "worthy") then
                        local frame = gui:FindFirstAncestorWhichIsA("Frame")
                        if frame and frame.Visible
                           and frame.Name ~= "TrialBar"
                           and frame.Name ~= "TowerTrialHUD" then
                            frame.Visible = false
                        end
                    end
                end
            end
        end)
    end

    local function getToolCount()
        local count = 0
        local backpack = Player:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then count += 1 end
            end
        end
        if Player.Character then
            for _, tool in ipairs(Player.Character:GetChildren()) do
                if tool:IsA("Tool") then count += 1 end
            end
        end
        return count
    end

    -- Vind de root BasePart van een brainrot model
    -- Gebruikt MzD.findBrainrotRoot als die beschikbaar is
    local function findBrainrotRoot(brainrot)
        if not brainrot then return nil end
        if MzD.findBrainrotRoot then
            local root = MzD.findBrainrotRoot(brainrot)
            if root then return root end
        end
        -- Fallback handmatig
        local root = brainrot:FindFirstChild("Root")
        if root and root:IsA("BasePart") then return root end
        local rendered = brainrot:FindFirstChild("RenderedBrainrot")
        if rendered then
            local renderedRoot = rendered:FindFirstChild("Root")
            if renderedRoot and renderedRoot:IsA("BasePart") then return renderedRoot end
        end
        if brainrot:IsA("Model") and brainrot.PrimaryPart then return brainrot.PrimaryPart end
        for _, desc in ipairs(brainrot:GetDescendants()) do
            if desc:IsA("BasePart") then return desc end
        end
        return nil
    end

    local function haltMovement()
        local character = Player.Character if not character then return end
        local rootPart  = character:FindFirstChild("HumanoidRootPart")
        local humanoid  = character:FindFirstChildOfClass("Humanoid")
        if humanoid and rootPart then humanoid:MoveTo(rootPart.Position) end
        if rootPart then
            local cf = rootPart.CFrame
            rootPart.Anchored    = true
            rootPart.Velocity    = Vector3.zero
            rootPart.RotVelocity = Vector3.zero
            twait(0.05)
            rootPart.Anchored = false
            rootPart.CFrame   = cf
        end
    end
    M.haltMovement = haltMovement

    -- Beweeg zijwaarts weg van de tower zodat safePathTo niet blokkeert
    local function escapeFromTower(tower)
        local character = Player.Character if not character then return end
        local rootPart  = character:FindFirstChild("HumanoidRootPart") if not rootPart then return end
        local towerPos  = tower:GetPivot().Position
        local myPos     = rootPart.Position
        local escapeX   = myPos.X + (myPos.X >= towerPos.X and 14 or -14)
        local safeY     = MzD._isGod and MzD.S.GodWalkY or (myPos.Y + 3)
        MzD.fastTween(CFrame.new(escapeX, safeY, myPos.Z))
        twait(0.15)
    end

    -- ============================================
    -- STATE MACHINE
    -- ACTIVATE → COLLECT → SUBMIT → COOLDOWN → ACTIVATE
    -- ============================================

    function MzD.startTowerTrial()
        if MzD._towerTrialThread then return end
        MzD._towerTrialEnabled     = true
        MzD.S.TowerTrialEnabled    = true
        MzD.Status.towerTrialCount = 0
        MzD.Status.towerTrial      = "Opstarten..."

        -- Direct visuele rommel opruimen bij start
        cleanTowerVisuals()

        MzD._towerTrialThread = tspawn(function()
            local state          = "ACTIVATE"
            local depositsBefore = 0
            local trialsDone     = 0
            local trips          = 0

            MzD.safeUnequip()
            twait(0.3)

            while MzD._towerTrialEnabled do
                local ok, err = pcall(function()
                    killRewardPopups()

                    -- ── STATE: ACTIVATE ──────────────────────────────────────
                    if state == "ACTIVATE" then
                        if isTrialActive() then state = "COLLECT" return end

                        local liveCooldown = getLiveCooldown()
                        if liveCooldown and liveCooldown > 0 then
                            MzD.Status.towerTrial = "⚠️ Tower op cooldown..."
                            state = "COOLDOWN" return
                        end

                        local tower = getTower()
                        if not tower then
                            MzD.Status.towerTrial = "⚠️ Tower niet gevonden"
                            twait(3) return
                        end

                        MzD.Status.towerTrial = "🏃 Naar tower..."
                        MzD.safePathTo(tower:GetPivot() * CFrame.new(0, 3, 0))

                        for attempt = 1, 15 do
                            if not MzD._towerTrialEnabled then break end
                            MzD.Status.towerTrial = "🏁 Activeer trial... " .. attempt
                            fireAllPrompts(tower)
                            twait(0.6)
                            if isTrialActive() then
                                MzD.Status.towerTrial = "✅ Trial actief! " .. getRequiredRarity()
                                state = "COLLECT" return
                            end
                        end

                        local cd = getLiveCooldown()
                        if cd and cd > 0 then
                            state = "COOLDOWN"
                        else
                            MzD.Status.towerTrial = "⚠️ Activeren mislukt"
                            twait(5)
                        end
                        return
                    end

                    -- ── STATE: COLLECT ───────────────────────────────────────
                    if state == "COLLECT" then
                        if MzD.isDead() then MzD.waitForRespawn() twait(2) return end

                        local current, goal = getDeposits()
                        MzD.Status.towerTrial = sformat(
                            "💝 %d/%d | Trips: %d | #%d",
                            current, goal, trips, trialsDone
                        )

                        -- Alle deposits gedaan → trial claimen
                        if current >= goal then
                            pcall(function()
                                local rs      = game:GetService("ReplicatedStorage")
                                local shared  = rs:FindFirstChild("Shared")
                                local remotes = shared and shared:FindFirstChild("Remotes")
                                local network = remotes and remotes:FindFirstChild("Networking")
                                local remote  = network and network:FindFirstChild("RE/Tower/TowerClaimConfirmed")
                                if remote then remote:FireServer() end
                            end)
                            twait(1.5)
                            trialsDone += 1
                            MzD.Status.towerTrialCount = trialsDone
                            MzD.Status.towerTrial      = "🎉 Trial #" .. trialsDone .. " KLAAR!"

                            -- Zijwaarts ontsnappen zodat safePathTo niet blokkeert
                            local tower = getTower()
                            if tower then escapeFromTower(tower) end

                            state = "COOLDOWN" return
                        end

                        -- Zoek brainrots van het vereiste rarity
                        local activeBrainrots = workspace:FindFirstChild("ActiveBrainrots")
                        if not activeBrainrots then twait(2) return end

                        local required = getRequiredRarity()
                        if required == "?" then twait(1) return end

                        local candidates = {}
                        local rootPart   = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

                        for _, folder in ipairs(activeBrainrots:GetChildren()) do
                            if folder.Name == required then
                                for _, brainrot in ipairs(folder:GetChildren()) do
                                    local root = findBrainrotRoot(brainrot)
                                    if root then
                                        local dist = rootPart
                                            and (rootPart.Position - root.Position).Magnitude
                                            or  0
                                        tinsert(candidates, { brainrot = brainrot, root = root, dist = dist })
                                    end
                                end
                            end
                        end
                        tsort(candidates, function(a, b) return a.dist < b.dist end)

                        if #candidates == 0 then
                            MzD.Status.towerTrial = "⏳ Geen " .. required .. " op de map..."
                            twait(1.5) return
                        end

                        local target      = candidates[1]
                        local startParent = target.brainrot.Parent
                        local startTools  = getToolCount()

                        MzD.Status.towerTrial = "🧠 Ophalen " .. required .. " (" .. mfloor(target.dist) .. "m)"
                        MzD.safePathTo(target.root.CFrame * CFrame.new(0, 3, 0))

                        -- Meerdere pogingen om de brainrot op te pakken
                        for attempt = 1, 15 do
                            if not MzD._towerTrialEnabled then break end
                            if not target.brainrot or target.brainrot.Parent ~= startParent then break end
                            if getToolCount() > startTools then break end

                            -- Blijf strak op de root staan (ook als het item beweegt/rolt)
                            if target.root then
                                pcall(function()
                                    local character = Player.Character
                                    if character and character:FindFirstChild("HumanoidRootPart") then
                                        character.HumanoidRootPart.CFrame = target.root.CFrame * CFrame.new(0, 3, 0)
                                    end
                                end)
                            end

                            MzD.forceGrabPrompt(target.root)
                            MzD.forceGrabPrompt(target.brainrot)
                            fireAllPrompts(target.brainrot)
                            twait(0.2)
                        end

                        local grabbed = getToolCount() > startTools
                            or (target.brainrot and target.brainrot.Parent ~= startParent)

                        if grabbed then
                            depositsBefore = current
                            state = "SUBMIT"
                        else
                            MzD.Status.towerTrial = "⏳ Ophalen mislukt"
                            twait(1)
                        end
                        return
                    end

                    -- ── STATE: SUBMIT ────────────────────────────────────────
                    if state == "SUBMIT" then
                        trips += 1
                        local tower = getTower()
                        if not tower then state = "COLLECT" return end

                        MzD.Status.towerTrial = "📦 Submit #" .. trips
                        MzD.safePathTo(tower:GetPivot() * CFrame.new(0, 3, 0))

                        local deadline   = tick() + 8
                        local deposited  = false
                        while tick() < deadline do
                            if not MzD._towerTrialEnabled then break end
                            fireAllPrompts(tower)
                            twait(0.4)
                            local current2, _ = getDeposits()
                            if current2 > depositsBefore then deposited = true break end
                        end

                        if deposited then
                            -- Wacht tot de teller daadwerkelijk omhoog is gegaan
                            local waitDeadline = tick() + 6
                            local current2, _  = getDeposits()
                            while current2 <= depositsBefore and tick() < waitDeadline do
                                twait(0.2)
                                current2, _ = getDeposits()
                            end
                            twait(3)
                        else
                            MzD.Status.towerTrial = "⚠️ Submit mislukt"
                        end

                        MzD.safeUnequip()
                        state = "COLLECT"
                        return
                    end

                    -- ── STATE: COOLDOWN ──────────────────────────────────────
                    if state == "COOLDOWN" then
                        MzD.Status.towerTrial = "🏠 Terugkeren naar base..."
                        MzD.safeReturnToBase()
                        MzD.safeUnequip()
                        twait(0.3)

                        local remaining = MzD.S.TowerTrialFallbackCd
                        while MzD._towerTrialEnabled do
                            killRewardPopups()
                            local live = getLiveCooldown()
                            if live ~= nil then remaining = live end
                            if remaining <= 0 then
                                MzD.Status.towerTrial = "✅ Cooldown klaar!"
                                twait(2)
                                state = "ACTIVATE" return
                            end
                            MzD.Status.towerTrial = sformat(
                                "⏳ Cooldown: %d:%02d",
                                mfloor(remaining / 60),
                                mfloor(remaining % 60)
                            )
                            if live == nil then remaining -= 1 end
                            twait(1)
                        end
                        return
                    end
                end)

                if not ok then
                    MzD.Status.towerTrial = "❌ " .. tostring(err):sub(1, 50)
                    twait(3)
                end
                twait(0.05)
            end

            haltMovement()
            MzD.Status.towerTrial = "Gestopt"
            MzD._towerTrialThread = nil
        end)
    end

    function MzD.stopTowerTrial()
        MzD._towerTrialEnabled  = false
        MzD.S.TowerTrialEnabled = false
        if MzD._towerTrialThread then
            pcall(tcancel, MzD._towerTrialThread)
            MzD._towerTrialThread = nil
        end
        haltMovement()
        MzD.Status.towerTrial = "Idle"
    end

end

return M
