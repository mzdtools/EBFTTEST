-- ============================================
-- [MODULE 6] WALL THEMES
-- ============================================

local M = {}

M.WALL_THEMES = {
    Dark      = { wall=Color3.fromRGB(20,20,30),    floor=Color3.fromRGB(15,15,20),    stripe=Color3.fromRGB(255,200,50),   glow=Color3.fromRGB(255,215,0)   },
    Doom      = { wall=Color3.fromRGB(60,10,10),    floor=Color3.fromRGB(40,5,5),      stripe=Color3.fromRGB(255,60,0),    glow=Color3.fromRGB(255,80,20)   },
    Valentine = { wall=Color3.fromRGB(80,20,40),    floor=Color3.fromRGB(60,15,30),    stripe=Color3.fromRGB(255,100,150), glow=Color3.fromRGB(255,130,180) },
    UFO       = { wall=Color3.fromRGB(10,40,10),    floor=Color3.fromRGB(5,30,5),      stripe=Color3.fromRGB(0,255,80),    glow=Color3.fromRGB(50,255,100)  },
    Bright    = { wall=Color3.fromRGB(200,200,210), floor=Color3.fromRGB(180,180,190), stripe=Color3.fromRGB(50,50,200),   glow=Color3.fromRGB(80,80,255)   },
}

function M.getThemeColors(MzD)
    local sfind  = string.find
    local slower = string.lower
    local theme = MzD.S.WallTheme or "Dark"
    if theme == "Auto" then
        local mapName = slower(MzD.lastMapName or "")
        if sfind(mapName,"doom")                                      then return M.WALL_THEMES.Doom
        elseif sfind(mapName,"valentine") or sfind(mapName,"candy")   then return M.WALL_THEMES.Valentine
        elseif sfind(mapName,"ufo") or sfind(mapName,"radioactive")   then return M.WALL_THEMES.UFO
        elseif sfind(mapName,"bright") or sfind(mapName,"white")      then return M.WALL_THEMES.Bright
        else return M.WALL_THEMES.Dark end
    end
    return M.WALL_THEMES[theme] or M.WALL_THEMES.Dark
end

return M
