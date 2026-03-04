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

    -- ── State ──────────────────────────────────────────────
    MzD.Status.fireice     = "Idle"
    MzD._fireiceEnabled    = false
    MzD._fireiceThread     = nil
    MzD._fireiceCollected  = 0

    -- ── Folder finder ──────────────────────────────────────
    local FOLDER_NAMES = {
        "FireAndIceEventParts",
        "FireAndIce",
        "FireiceCoins",
        "FireiceEvent",
        "FireiceEventParts",
        "Fireice",
    }

    local function getFireiceFolder()
        -- Directe workspace check
        for _, naam in ipairs(FOLDER_NAMES) do
            local f = workspace:FindFirstChild(naam)
            if f then return f end
        end

        -- Fallback: zoek recursief in GameObjects/Events
        local events = workspace:FindFirstChild("GameObjects")
        events = events and events:FindFirstChild("Events")
        if events then
            for _, child in pairs(events:GetChildren()) do
                local n = slower(child.Name)
                if sfind(n, "fireandice") or sfind(n, "fireice") then
                    return child
                end
            end
        end

        return nil
    end

    -- ── Coin scanner (recursief) ────────────────────────────
    local function scanCoins(folder, hrp, results)
        results = results or {}
        for _, child in pairs(folder:GetChildren()) do
            local root = child:FindFirstChild("Root")
                      or child:FindFirstChildWhichIsA("BasePart")
                      or child.PrimaryPart

            if root then
                local dist = hrp and (hrp.Position - root.Position).Magnitude or 0
                tinsert(results, { model = child, root = root, dist = dist })
            else
                -- Subfolder → recursief doorzoeken
                scanCoins(child, hrp, results)
            end
        end
        return results
    end

    -- ── Proximity prompt firer ──────────────────────────────
    local function fireAllPrompts(model)
        -- Probeer direct op root
        local root = model:FindFirstChild("Root")
                  or model:FindFirstChildWhichIsA("BasePart")
                  or model.PrimaryPart

        if root then
            local pp = root:FindFirstChildWhichIsA("ProximityPrompt")
            if pp then pcall(fireproximityprompt, pp) end
        end

        -- Scan alle descendants
        for _, d in pairs(model:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(fireproximityprompt, d)
            end
        end

        -- Fallback naar MzD helpers
        if root then MzD.forceGrabPrompt(root) end
        MzD.forceGrabPrompt(model)
    end

    -- ── Teleport naar coin ──────────────────────────────────
    local function teleportTo(root)
        local char = Player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp.CFrame = root.CFrame * CFrame.new(0, 2, 0)
            end)
        end
    end

    -- ── Coin is verdwenen check ─────────────────────────────
    local function coinGone(target, parentFolder)
        return not target.model
            or not target.model.Parent
            or target.model.Parent ~= parentFolder
    end

    -- ── Collect één coin ───────────────────────────────────
    local function collectCoin(target, parentFolder)
        teleportTo(target.root)
        twait(0.05)

        for attempt = 1, 20 do
            if not MzD._fireiceEnabled then return end
            if coinGone(target, parentFolder) then return end

            fireAllPrompts(target.model)
            twait(0.15)
        end
    end

    -- ── Hoofd loop ─────────────────────────────────────────
    function MzD.startFireice()
        if MzD._fireiceThread then return end
        MzD._fireiceEnabled   = true
        MzD._fireiceCollected = 0
        MzD.Status.fireice    = "Opstarten..."

        MzD._fireiceThread = tspawn(function()
            while MzD._fireiceEnabled do
                local ok, err = pcall(function()

                    -- Dood? Wacht op respawn
                    if MzD.isDead() then
                        MzD.Status.fireice = "💀 Respawnen..."
                        MzD.waitForRespawn()
                        twait(2)
                        return
                    end

                    -- Zoek de folder
                    local folder = getFireiceFolder()
                    if not folder then
                        MzD.Status.fireice = "⏳ Wachten op Fire & Ice map..."
                        twait(3)
                        return
                    end

                    -- Verzamel coins
                    local hrp  = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    local list = scanCoins(folder, hrp)

                    if #list == 0 then
                        MzD.Status.fireice = "⏳ Geen coins gevonden..."
                        twait(2)
                        return
                    end

                    -- Sorteer op afstand (dichtstbijzijnde eerst)
                    tsort(list, function(a, b) return a.dist < b.dist end)

                    local target = list[1]
                    MzD.Status.fireice = string.format(
                        "🪙 Coin #%d ophalen (%dm)",
                        MzD._fireiceCollected + 1,
                        mfloor(target.dist)
                    )

                    collectCoin(target, folder)

                    -- Teller ophogen als coin verdwenen is (= gecollect)
                    if coinGone(target, folder) then
                        MzD._fireiceCollected = MzD._fireiceCollected + 1
                    end
                end)

                if not ok then
                    MzD.Status.fireice = "❌ " .. tostring(err):sub(1, 50)
                    twait(2)
                end

                twait(0.05)
            end

            MzD.Status.fireice    = "Idle"
            MzD._fireiceThread    = nil
        end)
    end

    -- ── Stop ───────────────────────────────────────────────
    function MzD.stopFireice()
        MzD._fireiceEnabled = false
        if MzD._fireiceThread then
            pcall(tcancel, MzD._fireiceThread)
            MzD._fireiceThread = nil
        end
        MzD.Status.fireice = string.format("Gestopt (verzameld: %d)", MzD._fireiceCollected)
    end
end

return M
