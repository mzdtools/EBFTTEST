-- ============================================
-- [MODULE 28] STATUS UPDATE LOOP
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD
    local Player  = G.Player
    local tspawn  = G.tspawn
    local twait   = G.twait
    local sfind   = G.sfind
    local sformat = G.sformat
    local mfloor  = G.mfloor

    local gui = Modules.gui.guiRefs
    if not gui then return end

    local FSP   = gui.FSP
    local FPP   = gui.FPP
    local FTG   = gui.FTG
    local LBSP  = gui.LBSP
    local LBTG  = gui.LBTG
    local TTSP  = gui.TTSP
    local TTTG  = gui.TTTG
    local FCSP  = gui.FCSP
    local FCTG  = gui.FCTG
    local DMSP  = gui.DMSP
    local DMTG  = gui.DMTG
    local VSP   = gui.VSP
    local VTG   = gui.VTG
    local ASP   = gui.ASP
    local ATG   = gui.ATG
    local MSP   = gui.MSP
    local MTG   = gui.MTG
    local USP   = gui.USP
    local UTG   = gui.UTG
    local MFSP  = gui.MFSP
    local MFTG  = gui.MFTG
    local AFKSP = gui.AFKSP
    local AFKTG = gui.AFKTG
    local GDSP  = gui.GDSP
    local GDTG  = gui.GDTG
    local IP    = gui.IP

    tspawn(function()
        while twait(1) do
            pcall(function()
                FSP:SetDesc((MzD.S.Farming and MzD.Status.farm or "Idle").." | #"..MzD.Status.farmCount)
                FPP:SetDesc("Geplaatst:"..MzD.Status.placeCount.." | Geupgrade:"..MzD.Status.upgradeCount)
                if not MzD.S.Farming         then pcall(function() if FTG.Value  then FTG:SetValue(false)  end end) end

                LBSP:SetDesc((MzD.S.LuckyBlockEnabled and MzD.Status.luckyBlock or "Idle").." #"..MzD.Status.luckyBlockCount)
                if not MzD.S.LuckyBlockEnabled then pcall(function() if LBTG.Value then LBTG:SetValue(false) end end) end

                -- Tower Trial status
                TTSP:SetDesc(MzD.Status.towerTrial or "Idle")
                if not MzD._towerTrialEnabled then pcall(function() if TTTG.Value then TTTG:SetValue(false) end end) end

                FCSP:SetDesc((MzD.Status.factory or "Idle").." #"..MzD.Status.factoryCount)
                if not MzD.S.FactoryEnabled  then pcall(function() if FCTG.Value then FCTG:SetValue(false) end end) end

                if MzD.S.DoomEnabled then
                    local fc = workspace:FindFirstChild("DoomEventParts")
                    DMSP:SetDesc("AAN | Parts:"..#MzD._doomCachedParts.." | Folder:"..(fc and #fc:GetChildren() or 0))
                else DMSP:SetDesc("Uit") end
                if not MzD.S.DoomEnabled then pcall(function() if DMTG.Value then DMTG:SetValue(false) end end) end

                VSP:SetDesc(MzD.S.ValentineEnabled and (MzD.Status.valentine.." | 🍬 "..#MzD._candyCachedParts) or "Idle")
                if not MzD.S.ValentineEnabled then pcall(function() if VTG.Value then VTG:SetValue(false) end end) end

                ASP:SetDesc(MzD.S.ArcadeEnabled and ("Actief #"..MzD.Status.arcadeCount) or "Idle")
                if not MzD.S.ArcadeEnabled then pcall(function() if ATG.Value then ATG:SetValue(false) end end) end

                MSP:SetDesc(MzD.S.AutoCollectMoney and ("Actief | Slots:"..MzD.getSlotCount()) or "Idle")
                if not MzD.S.AutoCollectMoney then pcall(function() if MTG.Value then MTG:SetValue(false) end end) end

                USP:SetDesc((MzD.S.AutoUpgrade and MzD.upgradeThread and MzD.Status.upgrade or "Idle").." #"..MzD.Status.upgradeCount)
                if not (MzD.S.AutoUpgrade and MzD.upgradeThread) then pcall(function() if UTG.Value then UTG:SetValue(false) end end) end

                MFSP:SetDesc(MzD.S.MapFixerEnabled and MzD.Status.mapFixer or "Uit")
                if not MzD.S.MapFixerEnabled then pcall(function() if MFTG.Value then MFTG:SetValue(false) end end) end

                AFKSP:SetDesc("AFK: "..MzD.Status.afk)
                if not MzD.S.AntiAFK then pcall(function() if AFKTG.Value then AFKTG:SetValue(false) end end) end

                GDSP:SetDesc(MzD.Status.god)
                if not MzD._isGod then pcall(function() if GDTG.Value then GDTG:SetValue(false) end end) end

                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                local curY = hrp and sformat("%.1f", hrp.Position.Y) or "?"
                IP:SetDesc("👤 "..Player.Name
                    .."\n🏠 "..(MzD.baseGUID or "?")
                    .."\n📦 "..MzD.getSlotCount()
                    .."\n😇 "..(MzD._isGod and "AAN" or "UIT")
                    .."\n🎨 "..(MzD.S.WallTheme or "Dark")
                    .."\n📍 Y:"..curY
                    .."\n🔎 "..mfloor(MzD.S.GuiScale*100).."%")
            end)
        end
    end)
end

return M
