-- ============================================
-- [MODULE 17B] TOWER TRIAL HUD OVERLAY
-- Floating on-screen display voor Tower Trial Farm
-- Toont: status, cooldown timer, trips, trials done
-- Gaming stijl met pulse animaties via TweenService
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player       = G.Player
    local TweenService = G.TweenService
    local tspawn       = G.tspawn
    local twait        = G.twait
    local tcancel      = G.tcancel
    local sformat      = G.sformat
    local mfloor       = G.mfloor

    -- ── GUI OPBOUW ───────────────────────────────────────────

    local function buildHUD()
        -- Verwijder oude HUD als die er al is
        local old = Player.PlayerGui:FindFirstChild("MzD_TrialHUD")
        if old then old:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name           = "MzD_TrialHUD"
        sg.ResetOnSpawn   = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder   = 10
        sg.Parent         = Player.PlayerGui

        -- Hoofd frame — rechtsonder op het scherm
        local frame = Instance.new("Frame")
        frame.Name             = "HUDFrame"
        frame.Size             = UDim2.fromOffset(260, 130)
        frame.Position         = UDim2.new(1, -276, 1, -146)
        frame.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
        frame.BackgroundTransparency = 0.08
        frame.BorderSizePixel  = 0
        frame.Parent           = sg
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

        -- Glow rand
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color     = Color3.fromRGB(180, 80, 255)
        stroke.Thickness = 1.5
        stroke.Transparency = 0.3

        -- Titel balk
        local titleBar = Instance.new("Frame", frame)
        titleBar.Size             = UDim2.new(1, 0, 0, 28)
        titleBar.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
        titleBar.BackgroundTransparency = 0.2
        titleBar.BorderSizePixel  = 0
        Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

        -- Titel fix: onderste rounding wegwerken met een extra frame
        local titleFix = Instance.new("Frame", titleBar)
        titleFix.Size             = UDim2.new(1, 0, 0.5, 0)
        titleFix.Position         = UDim2.new(0, 0, 0.5, 0)
        titleFix.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
        titleFix.BackgroundTransparency = 0.2
        titleFix.BorderSizePixel  = 0

        -- 🏆 Titel tekst
        local titleLbl = Instance.new("TextLabel", titleBar)
        titleLbl.Size                   = UDim2.new(1, -10, 1, 0)
        titleLbl.Position               = UDim2.fromOffset(10, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text                   = "🏆  TOWER TRIAL FARM"
        titleLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
        titleLbl.TextSize               = 11
        titleLbl.Font                   = Enum.Font.GothamBold
        titleLbl.TextXAlignment         = Enum.TextXAlignment.Left

        -- Status label (grote tekst)
        local statusLbl = Instance.new("TextLabel", frame)
        statusLbl.Name                  = "StatusLbl"
        statusLbl.Size                  = UDim2.new(1, -16, 0, 28)
        statusLbl.Position              = UDim2.fromOffset(8, 34)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text                  = "⏳ Idle"
        statusLbl.TextColor3            = Color3.fromRGB(220, 180, 255)
        statusLbl.TextSize              = 13
        statusLbl.Font                  = Enum.Font.GothamBold
        statusLbl.TextXAlignment        = Enum.TextXAlignment.Left
        statusLbl.TextWrapped           = true

        -- Cooldown grote timer display
        local timerLbl = Instance.new("TextLabel", frame)
        timerLbl.Name                   = "TimerLbl"
        timerLbl.Size                   = UDim2.new(1, -16, 0, 36)
        timerLbl.Position               = UDim2.fromOffset(8, 62)
        timerLbl.BackgroundTransparency = 1
        timerLbl.Text                   = ""
        timerLbl.TextColor3             = Color3.fromRGB(255, 220, 80)
        timerLbl.TextSize               = 28
        timerLbl.Font                   = Enum.Font.GothamBold
        timerLbl.TextXAlignment         = Enum.TextXAlignment.Center

        -- Stats label onderaan
        local statsLbl = Instance.new("TextLabel", frame)
        statsLbl.Name                   = "StatsLbl"
        statsLbl.Size                   = UDim2.new(1, -16, 0, 18)
        statsLbl.Position               = UDim2.fromOffset(8, 106)
        statsLbl.BackgroundTransparency = 1
        statsLbl.Text                   = "Trials: 0  |  Trips: 0"
        statsLbl.TextColor3             = Color3.fromRGB(140, 140, 160)
        statsLbl.TextSize               = 10
        statsLbl.Font                   = Enum.Font.Gotham
        statsLbl.TextXAlignment         = Enum.TextXAlignment.Center

        return sg, frame, statusLbl, timerLbl, statsLbl, stroke
    end

    -- ── PULSE ANIMATIE ───────────────────────────────────────

    local function pulseStroke(stroke, col)
        -- Kort oplichten van de rand bij state change
        pcall(function()
            local tw1 = TweenService:Create(stroke, TweenInfo.new(0.15), {
                Color = col or Color3.fromRGB(255, 255, 100),
                Thickness = 3
            })
            tw1:Play() tw1.Completed:Wait()
            local tw2 = TweenService:Create(stroke, TweenInfo.new(0.4), {
                Color = Color3.fromRGB(180, 80, 255),
                Thickness = 1.5
            })
            tw2:Play()
        end)
    end

    local function pulseTimer(timerLbl, col)
        pcall(function()
            local tw1 = TweenService:Create(timerLbl, TweenInfo.new(0.1), {
                TextColor3 = col or Color3.fromRGB(255, 255, 255)
            })
            tw1:Play() tw1.Completed:Wait()
            local tw2 = TweenService:Create(timerLbl, TweenInfo.new(0.3), {
                TextColor3 = Color3.fromRGB(255, 220, 80)
            })
            tw2:Play()
        end)
    end

    -- ── HUD STARTEN ──────────────────────────────────────────

    function MzD.startTrialHUD()
        if MzD._trialHUDThread then return end

        local sg, frame, statusLbl, timerLbl, statsLbl, stroke = buildHUD()
        MzD._trialHUDGui = sg

        local lastStatus  = ""
        local lastTrials  = -1
        local wasCooldown = false

        MzD._trialHUDThread = tspawn(function()
            while true do
                pcall(function()
                    local status  = MzD.Status.towerTrial or "Idle"
                    local trials  = MzD.Status.towerTrialCount or 0
                    local enabled = MzD._towerTrialEnabled or false

                    -- Verberg HUD als trial farm uit staat
                    if not enabled then
                        frame.BackgroundTransparency = 0.5
                        stroke.Transparency          = 0.7
                        statusLbl.Text               = "💤 Gestopt"
                        timerLbl.Text                = ""
                        statsLbl.Text                = "Trials: " .. trials
                        lastStatus = status
                        return
                    end

                    frame.BackgroundTransparency = 0.08
                    stroke.Transparency          = 0.3

                    -- Status updaten
                    if status ~= lastStatus then
                        statusLbl.Text = status

                        -- Pulse bij state changes
                        if status:find("KLAAR") then
                            tspawn(function() pulseStroke(stroke, Color3.fromRGB(80, 255, 120)) end)
                            tspawn(function() pulseTimer(timerLbl, Color3.fromRGB(80, 255, 120)) end)
                        elseif status:find("Cooldown") then
                            tspawn(function() pulseStroke(stroke, Color3.fromRGB(255, 180, 40)) end)
                        elseif status:find("Ophalen") or status:find("Submit") then
                            tspawn(function() pulseStroke(stroke, Color3.fromRGB(100, 180, 255)) end)
                        end

                        lastStatus = status
                    end

                    -- Timer extracten uit status als het een cooldown is
                    local m, s = status:match("(%d+):(%d%d)")
                    if m and s then
                        timerLbl.Text      = m .. ":" .. s
                        timerLbl.TextColor3 = Color3.fromRGB(255, 220, 80)
                        wasCooldown        = true

                        -- Rood knipperen als minder dan 10 sec
                        local totalSec = (tonumber(m) or 0) * 60 + (tonumber(s) or 0)
                        if totalSec <= 10 then
                            timerLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                        end
                    else
                        -- Geen cooldown meer: reset timer display
                        if wasCooldown then
                            timerLbl.Text       = ""
                            wasCooldown         = false
                        end
                        -- Toon actie icoon als timer
                        if status:find("Ophalen") then
                            timerLbl.Text       = "🧠"
                            timerLbl.TextColor3 = Color3.fromRGB(160, 220, 255)
                        elseif status:find("Submit") then
                            timerLbl.Text       = "📦"
                            timerLbl.TextColor3 = Color3.fromRGB(255, 200, 80)
                        elseif status:find("tower") or status:find("Tower") then
                            timerLbl.Text       = "🏃"
                            timerLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
                        elseif status:find("Trial actief") then
                            timerLbl.Text       = "⚔️"
                            timerLbl.TextColor3 = Color3.fromRGB(255, 120, 80)
                        elseif status:find("KLAAR") then
                            timerLbl.Text       = "🎉"
                            timerLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
                        elseif status:find("Idle") then
                            timerLbl.Text       = ""
                        end
                    end

                    -- Stats
                    if trials ~= lastTrials then
                        statsLbl.Text = "Trials gedaan: " .. trials
                        lastTrials    = trials
                    end
                end)
                twait(0.25)
            end
        end)
    end

    function MzD.stopTrialHUD()
        if MzD._trialHUDThread then
            pcall(tcancel, MzD._trialHUDThread)
            MzD._trialHUDThread = nil
        end
        if MzD._trialHUDGui then
            pcall(function() MzD._trialHUDGui:Destroy() end)
            MzD._trialHUDGui = nil
        end
    end
end

return M
