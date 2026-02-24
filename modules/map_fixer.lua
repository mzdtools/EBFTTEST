-- ============================================
-- [MODULE 25] MAP FIXER
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
    local mabs    = G.mabs
    local mhuge   = G.mhuge
    local mmin    = G.mmin
    local isMzDPart       = Modules.utility.isMzDPart
    local getThemeColors  = Modules.wall_themes.getThemeColors
    local buildSurfaceGui = Modules.utility.buildSurfaceGui

    local MF = {W=420, WH=220, WT=6, INT=8}
    MF.SZ = MF.W/2
    MF.WY = 100

    local function safeDestroyFolder(parent, fn)
        if not parent then return end
        local f = parent:FindFirstChild(fn)
        if not f or f.Name == "MzDHubWalls" then return end
        pcall(function()
            for _, d in pairs(f:GetDescendants()) do if d:IsA("BasePart") then d:Destroy() end end
            f:Destroy()
        end)
    end

    local MAP_FOLDERS_REMOVE = {"RightWalls","LeftWalls","Gaps","VIPWalls","SideWalls","Barriers","Fences","Walls","Decorations"}
    local EVENT_MAPS         = {"ValentinesMap","ArcadeMap","CandyMap","HalloweenMap","ChristmasMap","EasterMap","SummerMap","SpringMap","WinterMap","DoomMap"}
    local DECO_NAMES         = {"Deco","Decoration","Decorations","Decor","Props","Prop","Effects","VFX","Extras","Extra"}

    local function isWallPart(p)
        if not p:IsA("BasePart") or isMzDPart(p) then return false end
        local n = slower(p.Name)
        for _, k in pairs({"vipwall","sidewall","barrier","fence","blocker","border"}) do
            if n == k or sfind(n,"^"..k) then return true end
        end
        if p.Size.Y > 15 and p.Size.Y > p.Size.X*3 and p.Size.Y > p.Size.Z*3
           and mabs(p.Position.Z) > 60 then return true end
        return false
    end

    function MzD.mapFindShared(mn) return workspace:FindFirstChild(mn.."_SharedInstances") end

    function MzD.mapDetectXRange(map, si)
        local minX, maxX, found = mhuge, -mhuge, false
        local function chk(p)
            if not p:IsA("BasePart") or isMzDPart(p) then return end
            if p.Size.Y > p.Size.X and p.Size.Y > p.Size.Z then return end
            if p.Position.Y > 50 or p.Position.Y < -30 or p.Size.X < 5 then return end
            local l = p.Position.X - p.Size.X/2
            local r = p.Position.X + p.Size.X/2
            if l < minX then minX = l end
            if r > maxX then maxX = r end
            found = true
        end
        if map then for _, d in pairs(map:GetDescendants()) do if d:IsA("BasePart") then chk(d) end end end
        if si  then
            for _, c in pairs(si:GetChildren()) do if c:IsA("BasePart") then chk(c) end end
            local sf = si:FindFirstChild("Floors")
            if sf then for _, f in pairs(sf:GetChildren()) do chk(f) end end
        end
        if found and maxX > minX then return minX-5, maxX+5 end
        return -15, 4385
    end

    local function getFloorParts(map, si)
        local fl, seen = {}, {}
        local function af(p)
            if not p:IsA("BasePart") or isMzDPart(p) or seen[p] then return end
            if p.Size.Y > p.Size.X and p.Size.Y > p.Size.Z then return end
            if p.Position.Y > 30 or p.Position.Y < -20 or p.Size.X < 5 then return end
            seen[p] = true tinsert(fl, p)
        end
        if map then
            for _, d in pairs(map:GetDescendants()) do
                if d:IsA("BasePart") and not isMzDPart(d) then
                    local n = slower(d.Name)
                    if n == "firstfloor" or n == "ground" or n == "bridgefloor" or n == "floor"
                       or n == "grass" or n == "path" or n == "road" or n == "platform" then
                        af(d)
                    elseif d.Size.X > 50 and d.Size.Z > 10 and d.Size.Y < 10 then af(d) end
                end
            end
        end
        if si then
            local sf = si:FindFirstChild("Floors")
            if sf then for _, f in pairs(sf:GetChildren()) do if f:IsA("BasePart") then af(f) end end end
            for _, c in pairs(si:GetChildren()) do
                if c:IsA("BasePart") and c.Size.X > 50 and c.Size.Z > 10 and c.Size.Y < 10 then af(c) end
            end
        end
        return fl
    end

    function MzD.removeMapDeco(map)
        if not map then return 0 end
        local removed = 0
        for _, decoName in pairs(DECO_NAMES) do
            local deco = map:FindFirstChild(decoName)
            if deco then pcall(function() deco:Destroy() removed += 1 end) end
        end
        for _, child in pairs(map:GetChildren()) do
            if child:IsA("Folder") or child:IsA("Model") then
                local n = slower(child.Name)
                for _, decoName in pairs(DECO_NAMES) do
                    if n == slower(decoName) then
                        pcall(function() child:Destroy() removed += 1 end) break
                    end
                end
            end
        end
        return removed
    end

    function MzD.mapCleanup(map)
        for _, n in pairs(MAP_FOLDERS_REMOVE) do safeDestroyFolder(map, n) end
        MzD.removeMapDeco(map)
        for _, d in pairs(map:GetDescendants()) do
            if d.Parent and not isMzDPart(d) and d:IsA("BasePart") and isWallPart(d) then
                pcall(function() d:Destroy() end)
            end
        end
    end

    function MzD.mapCleanupShared(si)
        if not si then return end
        for _, n in pairs(MAP_FOLDERS_REMOVE) do safeDestroyFolder(si, n) end
        MzD.removeMapDeco(si)
        for _, d in pairs(si:GetDescendants()) do
            if d:IsA("BasePart") and not isMzDPart(d) and isWallPart(d) then
                pcall(function() d:Destroy() end)
            end
        end
    end

    function MzD.mapCleanupMisc()
        local misc = workspace:FindFirstChild("Misc")
        if misc then
            for _, c in pairs(misc:GetChildren()) do
                if c.Name == "BrickAddition" or c.Name == "Roof" then
                    pcall(function() c:Destroy() end)
                end
            end
        end
    end

    function MzD.cleanupEventMaps()
        for _, mn in pairs(EVENT_MAPS) do
            local em = workspace:FindFirstChild(mn)
            if em then
                for _, fn in pairs(MAP_FOLDERS_REMOVE) do safeDestroyFolder(em, fn) end
                MzD.removeMapDeco(em)
                for _, d in pairs(em:GetDescendants()) do
                    if d:IsA("BasePart") and not isMzDPart(d) and isWallPart(d) then
                        pcall(function() d:Destroy() end)
                    end
                end
            end
        end
    end

    function MzD.mapWidenFloors(map, si)
        for _, p in pairs(getFloorParts(map, si)) do
            pcall(function()
                if mabs(p.Size.Z - MF.W) > 1 then
                    p.Size     = Vector3.new(p.Size.X, p.Size.Y, MF.W)
                    p.Position = Vector3.new(p.Position.X, p.Position.Y, 0)
                end
            end)
        end
    end

    function MzD.mapFillGaps(map, sx, ex)
        local ref = nil
        for _, d in pairs(map:GetDescendants()) do
            if d:IsA("BasePart") and not isMzDPart(d) then
                local n = slower(d.Name)
                if n == "firstfloor" or n == "ground" then ref = d break end
            end
        end
        if not ref then
            local sp = map:FindFirstChild("Spawners")
            if sp then for _, s in pairs(sp:GetChildren()) do if s:IsA("BasePart") then ref = s break end end end
        end
        if not ref then
            for _, d in pairs(map:GetDescendants()) do
                if d:IsA("BasePart") and not isMzDPart(d)
                   and d.Size.X > 50 and d.Size.Y < 10 and d.Position.Y < 20 then
                    ref = d break
                end
            end
        end
        if not ref then return end
        local fY, fH, fC, fM2 = ref.Position.Y, ref.Size.Y, ref.Color, ref.Material
        for _, c in pairs(map:GetChildren()) do
            if c:IsA("BasePart") and c.Name == "BridgeFloor" then pcall(function() c:Destroy() end) end
        end
        local maxSeg, curX = 2000, sx
        while curX < ex do
            local segLen = mmin(maxSeg, ex - curX)
            local b = Instance.new("Part") b.Name = "BridgeFloor"
            b.Size     = Vector3.new(segLen, fH, MF.W)
            b.Position = Vector3.new(curX + segLen/2, fY, 0)
            b.Anchored = true b.CanCollide = true b.Color = fC b.Material = fM2
            b.TopSurface = Enum.SurfaceType.Smooth b.BottomSurface = Enum.SurfaceType.Smooth
            b.Parent = map
            curX = curX + segLen
        end
    end

    function MzD.mapBuildWalls(map, sx, ex)
        local WALL_BOTTOM = -25
        local WALL_H      = 300
        local WALL_MID_Y  = WALL_BOTTOM + WALL_H/2
        local floorTop    = MzD.S.GodFloorY + 2
        local sBot, sMid, sTop = floorTop+1, floorTop+WALL_H*0.2, floorTop+WALL_H*0.85

        local mf = map:FindFirstChild("MzDHubWalls")
        if mf then
            local fw = mf:FindFirstChild("FrontWall_1")
            if fw and mabs(fw.Size.Y - WALL_H) < 1 and mabs(fw.Position.Y - WALL_MID_Y) < 1 then
                MzD._wallZ_front = MF.SZ - 3 MzD._wallZ_back = -MF.SZ + 3 return
            end
            pcall(function() mf:Destroy() end)
        end

        mf = Instance.new("Folder") mf.Name = "MzDHubWalls" mf.Parent = map
        local theme = getThemeColors(MzD)

        local function mw(nm, sz, ps)
            local w = Instance.new("Part") w.Name = nm w.Size = sz w.Position = ps
            w.Anchored = true w.CanCollide = true
            w.Color = theme.wall w.Material = Enum.Material.SmoothPlastic
            w.TopSurface = Enum.SurfaceType.Smooth w.BottomSurface = Enum.SurfaceType.Smooth
            w.Parent = mf return w
        end

        local function ms(nm, sz, ps)
            local s = Instance.new("Part") s.Name = nm s.Size = sz s.Position = ps
            s.Anchored = true s.CanCollide = false
            s.Color = theme.stripe s.Material = Enum.Material.Neon
            s.Parent = mf
        end

        local segs = {} local p2 = sx
        while p2 < ex do
            local l = mmin(2000, ex - p2)
            tinsert(segs, {s = p2, l = l}) p2 = p2 + l
        end

        for i, s in pairs(segs) do
            local cx = s.s + s.l/2
            local fw = mw("FrontWall_"..i, Vector3.new(s.l, WALL_H, MF.WT), Vector3.new(cx, WALL_MID_Y, MF.SZ + MF.WT/2))
            buildSurfaceGui(fw, Enum.NormalId.Front, theme)
            buildSurfaceGui(fw, Enum.NormalId.Back,  theme)
            ms("FS_bot"..i, Vector3.new(s.l,2,0.4), Vector3.new(cx, sBot, MF.SZ+MF.WT+0.3))
            ms("FS_mid"..i, Vector3.new(s.l,1,0.4), Vector3.new(cx, sMid, MF.SZ+MF.WT+0.3))
            ms("FS_top"..i, Vector3.new(s.l,2,0.4), Vector3.new(cx, sTop, MF.SZ+MF.WT+0.3))

            local bw = mw("BackWall_"..i, Vector3.new(s.l, WALL_H, MF.WT), Vector3.new(cx, WALL_MID_Y, -MF.SZ - MF.WT/2))
            buildSurfaceGui(bw, Enum.NormalId.Front, theme)
            buildSurfaceGui(bw, Enum.NormalId.Back,  theme)
            ms("BS_bot"..i, Vector3.new(s.l,2,0.4), Vector3.new(cx, sBot, -MF.SZ-MF.WT-0.3))
            ms("BS_mid"..i, Vector3.new(s.l,1,0.4), Vector3.new(cx, sMid, -MF.SZ-MF.WT-0.3))
            ms("BS_top"..i, Vector3.new(s.l,2,0.4), Vector3.new(cx, sTop, -MF.SZ-MF.WT-0.3))
        end

        local totalZ = MF.SZ*2 + MF.WT*2 + 2
        mw("LeftWall",  Vector3.new(MF.WT, WALL_H, totalZ), Vector3.new(sx - MF.WT/2, WALL_MID_Y, 0))
        mw("RightWall", Vector3.new(MF.WT, WALL_H, totalZ), Vector3.new(ex + MF.WT/2, WALL_MID_Y, 0))
        MzD._wallZ_front = MF.SZ - 3 MzD._wallZ_back = -MF.SZ + 3
    end

    function MzD.mapFixCollision(map, si)
        for _, p in pairs(getFloorParts(map, si)) do
            if MzD._isGod then pcall(function() p.CanCollide=false p.Transparency=1 end)
            else pcall(function() p.CanCollide=true p.Transparency=0 end) end
        end
        for _, c in pairs(map:GetChildren()) do
            if c:IsA("BasePart") and c.Name == "BridgeFloor" then
                if MzD._isGod then pcall(function() c.CanCollide=false c.Transparency=1 end)
                else pcall(function() c.CanCollide=true end) end
            end
        end
        local mf2 = map:FindFirstChild("MzDHubWalls")
        if mf2 then
            for _, w in pairs(mf2:GetChildren()) do
                if w:IsA("BasePart") then
                    local n = w.Name
                    if sfind(n,"FS_") or sfind(n,"BS_") then w.CanCollide = false
                    else w.CanCollide = true w.Anchored = true end
                end
            end
        end
    end

    MzD._lastFixedMapName = ""

    function MzD.mapRunFix()
        local map = MzD.mapFindCurrentMap() if not map then return end
        local si  = MzD.mapFindShared(map.Name)
        local mapChanged = map.Name ~= MzD._lastFixedMapName
        if mapChanged then
            MzD._lastFixedMapName = map.Name
            MzD.lastMapName       = map.Name
        end
        local sx, ex = MzD.mapDetectXRange(map, si)
        if mapChanged then
            pcall(function() MzD.mapCleanup(map) end)
            pcall(function() MzD.mapCleanupShared(si) end)
            pcall(function() MzD.mapCleanupMisc() end)
            pcall(function() MzD.cleanupEventMaps() end)
            twait(0.1)
            pcall(function() MzD.mapWidenFloors(map, si) end)
            pcall(function() MzD.mapFillGaps(map, sx, ex) end)
            pcall(function() MzD.mapBuildWalls(map, sx, ex) end)
            MzD.Status.mapFixer = "Gefixed: "..map.Name
        end
        pcall(function() MzD.mapFixCollision(map, si) end)
    end

    function MzD.startMapFixer()
        if MzD.mapFixerThread then return end
        MzD.S.MapFixerEnabled = true MzD._lastFixedMapName = ""
        pcall(function() MzD.mapRunFix() end)
        MzD.mapFixerThread = tspawn(function()
            while MzD.S.MapFixerEnabled do
                pcall(function() MzD.mapRunFix() end)
                MzD.Status.mapFixer = "Actief"
                twait(MF.INT)
            end
            MzD.Status.mapFixer = "Uit" MzD.mapFixerThread = nil
        end)
    end

    function MzD.stopMapFixer()
        MzD.S.MapFixerEnabled = false
        if MzD.mapFixerThread then pcall(tcancel, MzD.mapFixerThread) MzD.mapFixerThread = nil end
        MzD.Status.mapFixer = "Uit"
    end
end

return M
