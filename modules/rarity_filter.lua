-- ============================================
-- [MODULE 12] RARITY / FILTER HELPERS
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player           = G.Player
    local ReplicatedStorage = G.ReplicatedStorage
    local tinsert = G.tinsert
    local tsort   = G.tsort
    local sfind   = G.sfind
    local slower  = G.slower
    local twait   = G.twait
    local HIGH_RARITIES = Modules.state.HIGH_RARITIES

    function MzD.isHighRarity(r)    return HIGH_RARITIES[r] == true end
    function MzD.isHighRarityTool(t) return t and HIGH_RARITIES[t:GetAttribute("Rarity") or ""] == true end
    function MzD.isDead()
        local ch  = Player.Character if not ch then return true end
        local hum = ch:FindFirstChild("Humanoid") if not hum then return true end
        return hum.Health <= 0
    end
    function MzD.waitForRespawn()
        if not MzD.isDead() then return true end
        local timeout = tick() + 15
        while MzD.isDead() and tick() < timeout do twait(0.2) end
        twait(1)
        return not MzD.isDead()
    end

    function MzD.forceGrabPrompt(target)
        if not target then return end
        local prompts = {}
        if target:IsA("ProximityPrompt") then tinsert(prompts, target)
        else for _, d in pairs(target:GetDescendants()) do if d:IsA("ProximityPrompt") then tinsert(prompts, d) end end end
        for _, p in pairs(prompts) do
            pcall(function() p.MaxActivationDistance = 99999 p.HoldDuration = 0 p.RequiresLineOfSight = false end)
            pcall(function() fireproximityprompt(p) end) twait(0.02)
            pcall(function() fireproximityprompt(p) end)
        end
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local parent = target
            if parent:IsA("ProximityPrompt") then parent = parent.Parent end
            if parent and parent:IsA("BasePart") then
                pcall(function() firetouchinterest(hrp, parent, 0) end)
                pcall(function() firetouchinterest(hrp, parent, 1) end)
            end
        end
        twait(0.02)
    end

    function MzD.getTargetRarities()
        return type(MzD.S.TargetRarity) == "table" and MzD.S.TargetRarity or {MzD.S.TargetRarity}
    end
    function MzD.rarityMatches(fn)
        for _, r in pairs(MzD.getTargetRarities()) do if r == "Any" or r == fn then return true end end
        return false
    end

    function MzD.getBrainrotNames(rarity)
        local names, seen = {}, {}
        if not MzD.ActiveBrainrots then MzD.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots") end
        if not MzD.ActiveBrainrots then return names end
        for _, f in pairs(MzD.ActiveBrainrots:GetChildren()) do
            if f:IsA("Folder") and (rarity == "Any" or f.Name == rarity) then
                for _, b in pairs(f:GetChildren()) do
                    local n = nil
                    if b:FindFirstChild("RenderedBrainrot") then n = b.RenderedBrainrot:GetAttribute("BrainrotName")
                    elseif b.Name == "RenderedBrainrot"     then n = b:GetAttribute("BrainrotName")
                    else n = b:GetAttribute("BrainrotName") or b.Name end
                    if n and n ~= "" and not seen[n] then seen[n] = true tinsert(names, n) end
                end
            end
        end
        tsort(names) return names
    end

    function MzD.getBrainrotNamesMulti(rarities)
        if type(rarities) ~= "table" then return MzD.getBrainrotNames(rarities) end
        local names, seen = {}, {}
        for _, r in pairs(rarities) do if r == "Any" then return MzD.getBrainrotNames("Any") end end
        for _, r in pairs(rarities) do
            for _, n in pairs(MzD.getBrainrotNames(r)) do
                if not seen[n] then seen[n] = true tinsert(names, n) end
            end
        end
        tsort(names) return names
    end

    function MzD.matchesFilter(b, folderRarity)
        if not MzD.rarityMatches(folderRarity) then return false end
        if MzD.isHighRarity(folderRarity)      then return true end
        local mut    = b:GetAttribute("Mutation") or "None"
        local isNone = (slower(mut) == "none" or mut == "")
        if MzD.S.TargetMutation == "None" then
            if not isNone then return false end
        elseif MzD.S.TargetMutation ~= "Any" then
            if mut ~= MzD.S.TargetMutation then return false end
        end
        if #MzD.S.SelectedBrainrots > 0 then
            local bName = b:GetAttribute("BrainrotName") or ""
            local found = false
            for _, sel in pairs(MzD.S.SelectedBrainrots) do if sel == bName then found = true break end end
            if not found then return false end
        end
        return true
    end

    function MzD.toolMatchesRarity(tool, targetRarity, targetMutation)
        local tMut     = tool:GetAttribute("Mutation") or "None"
        local lvl      = tonumber(tool:GetAttribute("Level")) or 0
        local bName    = tool:GetAttribute("BrainrotName")
        local toolRarity = tool:GetAttribute("Rarity")
        if not bName or bName == "" then return false end
        if lvl >= MzD.S.MaxLevel then return false end
        if toolRarity and MzD.isHighRarity(toolRarity) then
            local tR = type(targetRarity) == "table" and targetRarity or {targetRarity}
            for _, r in pairs(tR) do if r == "Any" or r == toolRarity then return true end end
            return false
        end
        if targetMutation == "None" then
            if not (slower(tMut) == "none" or tMut == "") then return false end
        elseif targetMutation ~= "Any" then
            if tMut ~= targetMutation then return false end
        end
        local tR   = type(targetRarity) == "table" and targetRarity or {targetRarity}
        local isAny = false
        for _, r in pairs(tR) do if r == "Any" then isAny = true break end end
        if not isAny then
            if toolRarity and toolRarity ~= "" then
                local m2 = false
                for _, r in pairs(tR) do if toolRarity == r then m2 = true break end end
                if not m2 then return false end
            else
                local wl = {}
                for _, n2 in pairs(MzD.getBrainrotNamesMulti(tR)) do wl[n2] = true end
                if not wl[bName] then return false end
            end
        end
        return true
    end

    function MzD.getAvailableMutations()
        local muts, seen = {"Any","None"}, {["Any"]=true,["None"]=true}
        pcall(function()
            local mutFolder = ReplicatedStorage:FindFirstChild("Assets")
            if mutFolder then
                mutFolder = mutFolder:FindFirstChild("Mutations")
                if mutFolder then
                    for _, m in pairs(mutFolder:GetChildren()) do
                        if not seen[m.Name] then seen[m.Name] = true tinsert(muts, m.Name) end
                    end
                end
            end
        end)
        for _, m in pairs({"Emerald","Gold","Blood","Diamond","Rainbow","Shadow","Crystal","Void","Doom"}) do
            if not seen[m] then seen[m] = true tinsert(muts, m) end
        end
        return muts
    end

    function MzD.getAvailableRarities()
        local rars, seen = {}, {}
        for _, r in pairs({"Any","Common","Uncommon","Rare","Epic","Legendary","Mythical","Cosmic","Secret","Celestial","Divine","Infinity"}) do
            if not seen[r] then seen[r] = true tinsert(rars, r) end
        end
        pcall(function()
            if MzD.ActiveBrainrots then
                for _, f in pairs(MzD.ActiveBrainrots:GetChildren()) do
                    if f:IsA("Folder") and not seen[f.Name] then seen[f.Name] = true tinsert(rars, f.Name) end
                end
            end
        end)
        return rars
    end
end

return M
