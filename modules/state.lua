-- ============================================
-- [MODULE 5] STATE / THREAD HANDLES
-- ============================================

local M = {}

function M.init(Modules)
    local MzD = Modules.globals.MzD

    MzD.baseGUID              = nil
    MzD.baseCFrame            = nil
    MzD.homePosition          = nil
    MzD.farmThread            = nil
    MzD.factoryThread         = nil
    MzD.moneyThread           = nil
    MzD.moneyRemoteThread     = nil
    MzD.afkThread             = nil
    MzD._afkSteppedConn       = nil
    MzD._instantConn          = nil
    MzD.upgradeThread         = nil
    MzD.valentineThread       = nil
    MzD.valentineCollectorConn  = nil
    MzD._valentineDescAddedConn = nil
    MzD._candyCollectorConn     = nil
    MzD._candyDescAddedConn     = nil
    MzD._candyCachedParts       = {}
    MzD._candyLastCacheScan     = 0
    MzD.arcadeThread          = nil
    MzD.mapFixerThread        = nil
    MzD.lastMapName           = ""
    MzD._valentineCachedParts   = {}
    MzD._valentineLastCacheScan = 0
    MzD._valentineStationCF     = nil
    MzD.luckyBlockThread      = nil
    MzD._isGod                = false
    MzD._godLoopThread        = nil
    MzD._godHealthConn        = nil
    MzD._godDiedConn          = nil
    MzD._godOriginalFloors    = {}
    MzD._godCreatedParts      = {}
    MzD._godKillParts         = {}
    MzD._godKillWatchThread   = nil
    MzD._godFloorCacheTime    = 0
    MzD._doomConn             = nil
    MzD._doomDescConn         = nil
    MzD._doomCachedParts      = {}
    MzD._doomLastScan         = 0
    MzD._doomCollected        = 0
    MzD._wallZ_front          = 207
    MzD._wallZ_back           = -207
    -- Tower Trial state
    MzD._towerTrialThread     = nil
    MzD._towerTrialEnabled    = false
end

M.HIGH_RARITIES = {["Celestial"]=true, ["Divine"]=true, ["Infinity"]=true}

return M
