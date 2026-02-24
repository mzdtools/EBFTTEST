-- ============================================
-- [MODULE 15] FACTORY LOOP — VOLLEDIG HERSCHREVEN
-- FIXED: Pakt alle brainrots uit backpack van de
--        geselecteerde rarity. Per brainrot:
--        1. Equip → Place op werkslot
--        2. Max upgraden zo snel mogelijk
--        3. PickUp → Unequip
--        Herhaal voor elke brainrot. Werkt voor
--        ALLE rarities inclusief high rarities.
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

    -- Verzamel ALLE matching tools uit backpack + equipped
    local function getAllFactoryTools()
        local tools = {}
        local bp = Player:FindFirstChild("Backpack")
        if bp then
            for _, t in pairs(bp:GetChildren()) do
                if t:IsA("Tool") and factoryToolMatchesRarity(t) then tinsert(tools, t) end
            end
        end
        if Player.Character then
            local eq = Player.Character:FindFirstChildWhichIsA("Tool")
            if eq and factoryToolMatchesRarity(eq) then tinsert(tools, eq) end
        end
        return tools
    end

    function MzD.startFactoryLoop()
        if MzD.factoryThread then return end
        MzD.S.FactoryEnabled  = true
        MzD.Status.factoryCount = 0

        MzD.factoryThread = tspawn(function()
            local stopReason = "Idle"
            while MzD.S.FactoryEnabled do
                local ok, err = pcall(function()
                    if not MzD.baseGUID then MzD.findBase() end
                    if not MzD.baseGUID then twait(2) return end

                    local ws = tonumber(MzD.S.FactorySlot) or 5

                    -- Leeg de werkslot eerst als die bezet is
                    if not MzD.isSlotEmpty(ws) then
                        MzD.pickUpBrainrot(ws) twait(1.0)
                        MzD.safeUnequip() twait(0.4)
                    end

                    -- Haal alle matching tools op uit backpack
                    local tools = getAllFactoryTools()

                    if #tools == 0 then
                        stopReason = "Klaar! (geen tools meer)"
                        MzD.S.FactoryEnabled = false
                        return
                    end

                    -- Verwerk elke tool één voor één
                    for i = 1, #tools do
                        if not MzD.S.FactoryEnabled then break end

                        local tool = tools[i]
                        -- Verifieer dat de tool nog bestaat en in backpack/char zit
                        if not tool or not tool.Parent then
                            -- Tool verdwenen, skip
                        else
                            local bName   = tool:GetAttribute("BrainrotName") or "Item"
                            local tRar    = tool:GetAttribute("Rarity") or ""
                            local isHighT = MzD.isHighRarity(tRar)

                            MzD.Status.factory = "🔧 " .. bName .. (isHighT and " ★" or "")

                            -- Zorg dat slot leeg is voor we plaatsen
                            if not MzD.isSlotEmpty(ws) then
                                MzD.pickUpBrainrot(ws) twait(1.0) MzD.safeUnequip() twait(0.4)
                            end

                            -- Equip de tool
                            local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
                            if hum then
                                pcall(function() hum:EquipTool(tool) end)
                                twait(0.5)
                            end

                            -- Controleer of tool nu equipped is
                            local equippedOk = false
                            if Player.Character then
                                local eq = Player.Character:FindFirstChildWhichIsA("Tool")
                                equippedOk = eq ~= nil
                            end

                            if not equippedOk then
                                -- Equip mislukt, probeer via backpack lookup
                                local bp = Player:FindFirstChild("Backpack")
                                if bp then
                                    for _, t in pairs(bp:GetChildren()) do
                                        if t == tool and hum then
                                            pcall(function() hum:EquipTool(t) end)
                                            twait(0.5) break
                                        end
                                    end
                                end
                            end

                            -- Plaats op werkslot
                            MzD.placeBrainrot(ws) twait(0.8)

                            if MzD.isSlotEmpty(ws) then
                                -- Plaatsen mislukt, unequip en naar volgende
                                pcall(function() if hum then hum:UnequipTools() end end)
                                twait(0.3)
                            else
                                -- Max upgraden (skip voor high rarities)
                                if not isHighT then
                                    local mb  = workspace:FindFirstChild("Bases") and workspace.Bases:FindFirstChild(MzD.baseGUID)
                                    local sm2 = mb and mb:FindFirstChild("slot "..ws.." brainrot")
                                    if sm2 then
                                        local cur, fails = tonumber(sm2:GetAttribute("Level")) or 0, 0
                                        while cur < MzD.S.FactoryMaxLevel and MzD.S.FactoryEnabled do
                                            MzD.upgradeBrainrot(ws)
                                            twait(0.05) -- zo snel mogelijk
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

                                if MzD.S.FactoryEnabled then
                                    -- Oppakken van slot
                                    MzD.pickUpBrainrot(ws) twait(1.0)
                                    MzD.Status.factoryCount += 1
                                    pcall(function() if hum then hum:UnequipTools() end end)
                                    twait(0.3)
                                    MzD.Status.factory = (isHighT and "★ Done " or "Done ") .. bName .. " (#" .. MzD.Status.factoryCount .. ")"
                                end
                            end
                        end -- tool.Parent check
                    end -- for tools
                end)
                if not ok then twait(1) end
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
        if not (sfind(f,"Done") or sfind(f,"Klaar") or sfind(f,"Geld op")) then
            MzD.Status.factory = "Idle"
        end
    end
end

return M
