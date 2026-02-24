-- ============================================
-- [MODULE 17] TOWER TRIAL FARM — v18 logica
-- Fixes: startParent check, pickup succes OR-conditie,
--        safeUnequip altijd na submit, HUD waitStart loop,
--        safePathTo voor submit (langs muur, niet rechtdoor)
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
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

    -- Bewegingsstop helper
    local function haltMovement()
        local char = Player.Character if not char then return end
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if hum and hrp then hum:MoveTo(hrp.Position) end
        if hrp then
            local cf = hrp.CFrame
            hrp.Anchored    = true
            hrp.Velocity    = Vector3.zero
            hrp.RotVelocity = Vector3.zero
            twait(0.05)
            hrp.Anchored = false
            hrp.CFrame   = cf
        end
    end
    M.haltMovement = haltMovement

    local function getTowerForTrial()
        local ok, t = pcall(function() return workspace.GameObjects.PlaceSpecific.root.Tower end)
        if ok and t then return t end
        for _, c in pairs(workspace:GetDescendants()) do
            if c.Name == "Tower" and c:IsA("Model") then
                local cnt = 0
                for _, d in pairs(c:GetDescendants()) do
                    if d:IsA("BasePart") then cnt += 1 end
                    if cnt > 5 then return c end
                end
            end
        end
        return nil
    end

    -- nil-check op fireproximityprompt
    local function trialFirePrompts(targetModel)
        if not targetModel then return end
        for _, d in pairs(targetModel:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function()
                    d.RequiresLineOfSight    = false
                    d.HoldDuration          = 0
                    d.MaxActivationDistance = 99999
                    d.Enabled               = true
                end)
                if fireproximityprompt then
                    pcall(function() fireproximityprompt(d) end)
                end
            end
        end
    end

    local function trialGetBar()
        local hud = Player.PlayerGui:FindFirstChild("TowerTrialHUD")
        return hud and hud:FindFirstChild("TrialBar")
    end

    local function trialGetTimer()
        local bar = trialGetBar() if not bar then return "" end
        local lbl = bar:FindFirstChild("Timer")
        return lbl and lbl.Text or ""
    end

    local function trialGetDeposits()
        local bar = trialGetBar() if not bar then return 0, 10 end
        local lbl = bar:FindFirstChild("Deposits") if not lbl then return 0, 10 end
        local cur, goal = lbl.Text:match("(%d+)%s*/%s*(%d+)")
        return tonumber(cur) or 0, tonumber(goal) or 10
    end

    local function trialGetRarity()
        local bar = trialGetBar() if not bar then return "?" end
        local lbl = bar:FindFirstChild("Requirement")
        if lbl and lbl.Text ~= "" then
            local txt = lbl.Text:gsub("<[^>]+>",""):match("^%s*(.-)%s*$")
            if txt ~= "" then return txt:match("Tower Trial:%s*(.+)") or txt end
        end
        for _, child in pairs(bar:GetDescendants()) do
            if child:IsA("TextLabel") and child.Text ~= "" then
                local txt    = child.Text:gsub("<[^>]+>","")
                local rarity = txt:match("Tower Trial:%s*(.+)")
                if rarity then return rarity:match("^%s*(.-)%s*$") end
            end
        end
        return "?"
    end

    local function trialIsActive()
        local bar = trialGetBar()
        if not bar or not bar.Visible then return false end
        local t = trialGetTimer()
        return t ~= "" and t ~= "00:00" and t ~= "0:00"
    end

    local function trialGetLiveCooldown()
        local tower = getTowerForTrial() if not tower then return nil end
        for _, d in pairs(tower:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" then
                local m, s = d.Text:match("(%d%d?):(%d%d)")
                if m and s then return (tonumber(m)*60) + tonumber(s) end
            end
        end
        return nil
    end

    local function trialKillPopups()
        pcall(function()
            for _, gui in pairs(Player.PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                    local txt = slower(gui.Text)
                    if sfind(txt,"claim") or sfind(txt,"reward") or sfind(txt,"worthy") then
                        local f = gui:FindFirstAncestorWhichIsA("Frame")
                        if f and f.Visible and f.Name ~= "TrialBar" and f.Name ~= "TowerTrialHUD" then
                            f.Visible = false
                        end
                    end
                end
            end
        end)
    end

    local function trialGetToolCount()
        local count = 0
        local bp = Player:FindFirstChild("Backpack")
        if bp then for _, t in pairs(bp:GetChildren()) do if t:IsA("Tool") then count += 1 end end end
        if Player.Character then
            for _, t in pairs(Player.Character:GetChildren()) do if t:IsA("Tool") then count += 1 end end
        end
        return count
    end

    -- findRoot met fallback
    local function trialFindRoot(b)
        if not b then return nil end
        if MzD.findBrainrotRoot then
            local root = MzD.findBrainrotRoot(b)
            if root then return root end
        end
        local r = b:FindFirstChild("Root")
        if r and r:IsA("BasePart") then return r end
        local rendered = b:FindFirstChild("RenderedBrainrot")
        if rendered then local rr = rendered:FindFirstChild("Root") if rr and rr:IsA("BasePart") then return rr end end
        if b:IsA("Model") and b.PrimaryPart then return b.PrimaryPart end
        for _, d in pairs(b:GetDescendants()) do if d:IsA("BasePart") then return d end end
        return nil
    end

    function MzD.startTowerTrial()
        if MzD._towerTrialThread then return end
        MzD._towerTrialEnabled  = true
        MzD.S.TowerTrialEnabled = true
        MzD.Status.towerTrialCount = 0
        MzD.Status.towerTrial   = "Opstarten..."

        MzD._towerTrialThread = tspawn(function()
            local state         = "ACTIVATE"
            local depBeforeTrip = 0
            local trialsDone    = 0
            local trips         = 0

            MzD.safeUnequip() twait(0.3)

            while MzD._towerTrialEnabled do
                local ok, err = pcall(function()
                    trialKillPopups()

                    -- ── STATE: ACTIVATE ──────────────────────────────
                    if state == "ACTIVATE" then
                        if trialIsActive() then state = "COLLECT" return end
                        local liveCd = trialGetLiveCooldown()
                        if liveCd and liveCd > 0 then
                            MzD.Status.towerTrial = "⚠️ Tower op cooldown..."
                            state = "COOLDOWN" return
                        end

                        local tower = getTowerForTrial()
                        if not tower then
                            MzD.Status.towerTrial = "⚠️ Tower niet gevonden"
                            twait(3) return
                        end
                        MzD.Status.towerTrial = "🏃 Naar tower..."
                        -- Altijd via corridor naar tower
                        MzD.safePathTo(tower:GetPivot() * CFrame.new(0,3,0))

                        for i = 1, 15 do
                            if not MzD._towerTrialEnabled then break end
                            MzD.Status.towerTrial = "🏁 Activeer trial... " .. i
                            trialFirePrompts(tower)
                            twait(0.6)
                            if trialIsActive() then
                                MzD.Status.towerTrial = "✅ Trial actief! " .. trialGetRarity()
                                state = "COLLECT" return
                            end
                        end

                        local cd = trialGetLiveCooldown()
                        if cd and cd > 0 then state = "COOLDOWN"
                        else MzD.Status.towerTrial = "⚠️ Activeren mislukt" twait(5) end
                        return
                    end

                    -- ── STATE: COLLECT ───────────────────────────────
                    if state == "COLLECT" then
                        if MzD.isDead() then MzD.waitForRespawn() twait(2) return end
                        local cur, goal = trialGetDeposits()
                        MzD.Status.towerTrial = "💝 " .. cur .. "/" .. goal .. " | Trips: " .. trips .. " | #" .. trialsDone

                        if cur >= goal then
                            -- Claim
                            pcall(function()
                                local rs     = game:GetService("ReplicatedStorage")
                                local shared = rs:FindFirstChild("Shared")
                                local remote = shared
                                    and shared:FindFirstChild("Remotes")
                                    and shared.Remotes:FindFirstChild("Networking")
                                    and shared.Remotes.Networking:FindFirstChild("RE/Tower/TowerClaimConfirmed")
                                if remote then remote:FireServer() end
                            end)
                            twait(1.5)
                            trialsDone += 1
                            MzD.Status.towerTrialCount = trialsDone
                            MzD.Status.towerTrial = "🎉 Trial #" .. trialsDone .. " KLAAR!"
                            MzD.safeUnequip()
                            state = "COOLDOWN" return
                        end

                        -- Pak brainrot op
                        local activeBrainrots = workspace:FindFirstChild("ActiveBrainrots")
                        if not activeBrainrots then twait(2) return end
                        local required = trialGetRarity()
                        if required == "?" then twait(1) return end

                        local list = {}
                        local hrp  = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                        for _, folder in pairs(activeBrainrots:GetChildren()) do
                            if folder.Name == required then
                                for _, b in pairs(folder:GetChildren()) do
                                    local root = trialFindRoot(b)
                                    if root then
                                        local dist = hrp and (hrp.Position - root.Position).Magnitude or 0
                                        tinsert(list, {b=b, root=root, dist=dist})
                                    end
                                end
                            end
                        end
                        tsort(list, function(a, bx) return a.dist < bx.dist end)

                        if #list == 0 then
                            MzD.Status.towerTrial = "⏳ Geen " .. required .. " op de map..."
                            twait(1.5) return
                        end

                        local entry       = list[1]
                        local startParent = entry.b.Parent
                        local startTools  = trialGetToolCount()
                        MzD.Status.towerTrial = "🧠 Ophalen " .. required .. " (" .. mfloor(entry.dist) .. "m)"
                        -- Naar brainrot via corridor
                        MzD.safePathTo(entry.root.CFrame * CFrame.new(0,3,0))

                        for attempt = 1, 6 do
                            if not MzD._towerTrialEnabled then break end
                            if not entry.b or entry.b.Parent ~= startParent then break end
                            if trialGetToolCount() > startTools then break end
                            MzD.forceGrabPrompt(entry.root)
                            MzD.forceGrabPrompt(entry.b)
                            twait(0.3)
                        end

                        if trialGetToolCount() > startTools or (entry.b and entry.b.Parent ~= startParent) then
                            depBeforeTrip = cur
                            state = "SUBMIT"
                        else
                            MzD.Status.towerTrial = "⏳ Ophalen mislukt" twait(1)
                        end
                        return
                    end

                    -- ── STATE: SUBMIT ────────────────────────────────
                    if state == "SUBMIT" then
                        trips += 1
                        local tower = getTowerForTrial()
                        if not tower then state = "COLLECT" return end
                        MzD.Status.towerTrial = "📦 Submit #" .. trips .. " → tower via corridor"

                        -- FIX: safePathTo ipv tweenTo zodat hij langs de muur gaat
                        MzD.safePathTo(tower:GetPivot() * CFrame.new(0,3,0))

                        local t0        = tick()
                        local deposited = false
                        while tick() - t0 < 8 do
                            if not MzD._towerTrialEnabled then break end
                            trialFirePrompts(tower)
                            twait(0.4)
                            local cur2, _ = trialGetDeposits()
                            if cur2 > depBeforeTrip then
                                deposited = true
                                break
                            end
                        end

                        if deposited then
                            -- Wacht op HUD bevestiging
                            local waitStart = tick()
                            local cur2, _  = trialGetDeposits()
                            while cur2 <= depBeforeTrip and (tick() - waitStart) < 6 do
                                twait(0.2)
                                cur2, _ = trialGetDeposits()
                            end
                            twait(3)
                        else
                            MzD.Status.towerTrial = "⚠️ Submit mislukt"
                        end

                        MzD.safeUnequip()
                        state = "COLLECT"
                        return
                    end

                    -- ── STATE: COOLDOWN ──────────────────────────────
                    if state == "COOLDOWN" then
                        -- Terugkeren naar base via corridor
                        MzD.Status.towerTrial = "🏠 Terugkeren naar base..."
                        MzD.safeReturnToBase()

                        local remaining = MzD.S.TowerTrialFallbackCd
                        while MzD._towerTrialEnabled do
                            trialKillPopups()
                            local live = trialGetLiveCooldown()
                            if live ~= nil then remaining = live end
                            if remaining <= 0 then
                                MzD.Status.towerTrial = "✅ Cooldown klaar!"
                                twait(2) state = "ACTIVATE" return
                            end
                            local mm = mfloor(remaining/60)
                            local ss = mfloor(remaining%60)
                            MzD.Status.towerTrial = sformat("⏳ Cooldown: %d:%02d", mm, ss)
                            if live == nil then remaining -= 1 end
                            twait(1)
                        end
                        return
                    end
                end)

                if not ok then
                    MzD.Status.towerTrial = "❌ " .. tostring(err):sub(1,50)
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
        if MzD._towerTrialThread then pcall(tcancel, MzD._towerTrialThread) MzD._towerTrialThread = nil end
        haltMovement()
        MzD.Status.towerTrial = "Idle"
    end
end

return M
