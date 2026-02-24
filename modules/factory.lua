-- ============================================
-- [MODULE 15] FACTORY LOOP
-- Pakt alle brainrots uit backpack van de
-- geselecteerde rarity. Per brainrot:
--   1. tweenToSlot → Equip → Place op werkslot
--   2. Max upgraden zo snel mogelijk
--   3. PickUp → Unequip
-- Herhaal voor elke brainrot in backpack.
-- Werkt voor ALLE rarities.
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

    local function factoryToolMatchesRarity(tool)
        local tMut  = tool:GetAttribute("Mutation") or "None"
        local lvl   = tonumber(tool:GetAttribute("Level")) or 0
        local bName = tool:GetAttribute("BrainrotName")
        local tRar  = tool:GetAttribute("Rarity")
        if not bName or bName == "" then return false end
        if tRar and MzD.isHighRarity(tRar) then
            return MzD.S.FactoryRarity == "Any" or MzD.S.FactoryRarity == tRar
        end
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

    -- FIX: Haal LIVE de volgende matching tool op uit backpack (geen stale lijst)
    local function getNextFactoryTool()
        local bp = Player:FindFirstChild("Backpack")
        if bp then
            for _, t in pairs(bp:GetChildren()) do
                if t:IsA("Tool") and factoryToolMatchesRarity(t) then return t end
            end
        end
        -- Ook kijken of er iets equipped is
        if Player.Character then
            local eq = Player.Character:FindFirstChildWhichIsA("Tool")
            if eq and factoryToolMatchesRarity(eq) then return eq end
        end
        return nil
    end

    function MzD.startFactoryLoop()
        if MzD.factoryThread then return end
        MzD.S.FactoryEnabled   = true
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
                        MzD.tweenToSlot(ws) twait(0.3)   -- FIX: eerst naar slot
                        MzD.pickUpBrainrot(ws) twait(1.0)
                        MzD.safeUnequip() twait(0.4)
                    end

                    -- FIX: Haal live de volgende tool op, geen stale lijst
                    local tool = getNextFactoryTool()

                    if not tool then
                        stopReason = "Klaar! (geen tools meer)"
                        MzD.S.FactoryEnabled = false
                        return
                    end

                    local bName   = tool:GetAttribute("BrainrotName") or "Item"
                    local tRar    = tool:GetAttribute("Rarity") or ""
                    local isHighT = MzD.isHighRarity(tRar)

                    MzD.Status.factory = "🔧 " .. bName .. (isHighT and " ★" or "")

                    -- FIX: Naar slot tweenen VOOR equip + place
                    MzD.tweenToSlot(ws) twait(0.3)

                    -- Equip de tool
                    local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
                    if hum then
                        pcall(function() hum:EquipTool(tool) end)
                        twait(0.5)
                    end

                    -- Fallback equip als eerste poging mislukte
                    local equippedOk = Player.Character and Player.Character:FindFirstChildWhichIsA("Tool") ~= nil
                    if not equippedOk then
                        local bp = Player:FindFirstChild("Backpack")
                        if bp and hum then
                            for _, t in pairs(bp:GetChildren()) do
                                if t == tool then
                                    pcall(function() hum:EquipTool(t) end)
                                    twait(0.5) break
                                end
                            end
                        end
                    end

                    -- Plaats op werkslot
                    MzD.placeBrainrot(ws) twait(0.8)

                    if MzD.isSlotEmpty(ws) then
                        -- Plaatsen mislukt, unequip en volgende cyclus proberen
                        MzD.safeUnequip() twait(0.3)
                        return
                    end

                    -- Max upgraden (skip voor high rarities)
                    if not isHighT then
                        local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID)
                        local sm2 = mb and mb:FindFirstChild("slot " .. ws .. " brainrot")
                        if sm2 then
                            local cur, fails = tonumber(sm2:GetAttribute("Level")) or 0, 0
                            while cur < MzD.S.FactoryMaxLevel and MzD.S.FactoryEnabled do
                                MzD.upgradeBrainrot(ws)
                                twait(0.05)
                                local nw = tonumber(sm2:GetAttribute("Level")) or cur
                                if nw > cur then
                                    fails = 0
                                    cur   = nw
                                    MzD.Status.factory = bName .. " Lv." .. cur .. "/" .. MzD.S.FactoryMaxLevel
                                else
                                    fails += 1
                                    if fails > 80 then
                                        stopReason = "Geld op!"
                                        MzD.S.FactoryEnabled = false
                                        break
                                    end
                                end
                            end
                        end
                    else
                        MzD.Status.factory = "★ " .. tRar .. ": " .. bName .. " (gezet)"
                        twait(0.5)
                    end

                    -- Oppakken van slot → backpack
                    if MzD.S.FactoryEnabled then
                        MzD.pickUpBrainrot(ws) twait(1.0)
                        MzD.Status.factoryCount += 1
                        MzD.safeUnequip() twait(0.3)
                        MzD.Status.factory = (isHighT and "★ Done " or "Done ") .. bName .. " (#" .. MzD.Status.factoryCount .. ")"
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
        if not (sfind(f, "Done") or sfind(f, "Klaar") or sfind(f, "Geld op")) then
            MzD.Status.factory = "Idle"
        end
    end
end

return M
