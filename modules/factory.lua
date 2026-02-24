-- ============================================
-- [MODULE 15] FACTORY LOOP
-- Pakt alle brainrots uit backpack van de
-- geselecteerde rarity. Per brainrot:
--   1. tweenToSlot → Equip → Place op werkslot
--   2. Max upgraden ZSM (dynamisch adaptief)
--   3. PickUp → Unequip
-- Herhaal voor elke brainrot in backpack.
-- Werkt voor ALLE rarities inclusief high rarities.
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player  = G.Player
    local tinsert = G.tinsert
    local tspawn  = G.tspawn
    local twait   = G.twait
    local tcancel = G.tcancel
    local sfind   = G.sfind
    local slower  = G.slower

    local function factoryBrainrotMatchesRarity(brainrot)
        local tMut  = brainrot:GetAttribute("Mutation") or "None"
        local lvl   = tonumber(brainrot:GetAttribute("Level")) or 0
        local bName = brainrot:GetAttribute("BrainrotName")
        local tRar  = brainrot:GetAttribute("Rarity")
        if not bName or bName == "" then return false end
        if lvl >= MzD.S.FactoryMaxLevel then return false end
        if MzD.S.FactoryMutation == "None" then
            if not (slower(tMut) == "none" or tMut == "") then return false end
        elseif MzD.S.FactoryMutation ~= "Any" then
            if tMut ~= MzD.S.FactoryMutation then return false end
        end
        if MzD.S.FactoryRarity ~= "Any" then
            if tRar and tRar ~= "" then
                if tRar ~= MzD.S.FactoryRarity then return false end
            else
                local wl = {}
                for _, n in pairs(MzD.getBrainrotNames(MzD.S.FactoryRarity)) do wl[n] = true end
                if not wl[bName] then return false end
            end
        end
        return true
    end

    -- Haal live de volgende matching brainrot op uit backpack
    local function getNextFactoryBrainrot()
        local bp = Player:FindFirstChild("Backpack")
        if bp then
            for _, b in pairs(bp:GetChildren()) do
                if b:IsA("Tool") and factoryBrainrotMatchesRarity(b) then return b end
            end
        end
        if Player.Character then
            local eq = Player.Character:FindFirstChildWhichIsA("Tool")
            if eq and factoryBrainrotMatchesRarity(eq) then return eq end
        end
        return nil
    end

    function MzD.startFactoryLoop()
        if MzD.factoryThread then return end
        MzD.S.FactoryEnabled    = true
        MzD.Status.factoryCount = 0

        MzD.factoryThread = tspawn(function()
            local stopReason = "Idle"

            while MzD.S.FactoryEnabled do
                local ok, err = pcall(function()
                    if not MzD.baseGUID then MzD.findBase() end
                    if not MzD.baseGUID then twait(2) return end

                    local ws = tonumber(MzD.S.FactorySlot) or 5

                    -- Leeg werkslot als bezet
                    if not MzD.isSlotEmpty(ws) then
                        MzD.tweenToSlot(ws) twait(0.3)
                        MzD.pickUpBrainrot(ws) twait(1.0)
                        MzD.safeUnequip() twait(0.4)
                    end

                    -- Volgende brainrot live ophalen
                    local brainrot = getNextFactoryBrainrot()
                    if not brainrot then
                        stopReason = "Klaar! (geen brainrots meer)"
                        MzD.S.FactoryEnabled = false
                        return
                    end

                    local bName = brainrot:GetAttribute("BrainrotName") or "Brainrot"
                    local tRar  = brainrot:GetAttribute("Rarity") or ""

                    MzD.Status.factory = "🔧 " .. bName .. (tRar ~= "" and " [" .. tRar .. "]" or "")

                    -- Naar slot, dan equip
                    MzD.tweenToSlot(ws) twait(0.3)

                    local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
                    if hum then
                        pcall(function() hum:EquipTool(brainrot) end)
                        twait(0.5)
                    end

                    -- Fallback equip
                    local equippedOk = Player.Character and Player.Character:FindFirstChildWhichIsA("Tool") ~= nil
                    if not equippedOk then
                        local bp = Player:FindFirstChild("Backpack")
                        if bp and hum then
                            for _, b in pairs(bp:GetChildren()) do
                                if b == brainrot then
                                    pcall(function() hum:EquipTool(b) end)
                                    twait(0.5) break
                                end
                            end
                        end
                    end

                    -- Plaatsen op werkslot
                    MzD.placeBrainrot(ws) twait(0.8)

                    if MzD.isSlotEmpty(ws) then
                        -- Plaatsen mislukt
                        MzD.safeUnequip() twait(0.3)
                        return
                    end

                    -- ── DYNAMISCH UPGRADEN ZSM (altijd, alle rarities) ──
                    local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID)
                    local sm2 = mb and mb:FindFirstChild("slot " .. ws .. " brainrot")
                    if sm2 then
                        local cur   = tonumber(sm2:GetAttribute("Level")) or 0
                        local fails = 0
                        local delay = 0.05

                        while cur < MzD.S.FactoryMaxLevel and MzD.S.FactoryEnabled do
                            MzD.upgradeBrainrot(ws)
                            twait(delay)
                            local nw = tonumber(sm2:GetAttribute("Level")) or cur
                            if nw > cur then
                                cur   = nw
                                fails = 0
                                delay = 0.05
                                MzD.Status.factory = bName .. " Lv." .. cur .. "/" .. MzD.S.FactoryMaxLevel
                            else
                                fails += 1
                                delay = math.min(0.05 + (fails * 0.01), 0.3)
                                if fails > 80 then
                                    stopReason = "Geld op!"
                                    MzD.S.FactoryEnabled = false
                                    break
                                end
                            end
                        end
                    end

                    -- Oppakken → backpack
                    if MzD.S.FactoryEnabled then
                        MzD.pickUpBrainrot(ws) twait(1.0)
                        MzD.Status.factoryCount += 1
                        MzD.safeUnequip() twait(0.3)
                        MzD.Status.factory = "Klaar " .. bName .. " (#" .. MzD.Status.factoryCount .. ")"
                    end
                end)

                if not ok then
                    MzD.Status.factory = "❌ " .. tostring(err):sub(1, 50)
                    twait(1)
                end
                if MzD.S.FactoryEnabled then twait(0.1) end
            end

            MzD.Status.factory = stopReason
            MzD.factoryThread  = nil
        end)
    end

    function MzD.stopFactoryLoop()
        MzD.S.FactoryEnabled = false
        if MzD.factoryThread then pcall(tcancel, MzD.factoryThread) MzD.factoryThread = nil end
        local f = MzD.Status.factory or ""
        if not (sfind(f, "Klaar") or sfind(f, "Geld op")) then
            MzD.Status.factory = "Idle"
        end
    end
end

return M
