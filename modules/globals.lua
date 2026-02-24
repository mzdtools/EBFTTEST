-- ============================================
-- [MODULE 1] GLOBALS & SERVICE CACHE
-- ============================================

local M = {}

getgenv().MzD = {}
M.MzD = getgenv().MzD

M.Players           = game:GetService("Players")
M.TweenService      = game:GetService("TweenService")
M.RunService        = game:GetService("RunService")
M.UserInputService  = game:GetService("UserInputService")
M.ReplicatedStorage = game:GetService("ReplicatedStorage")
M.Player            = M.Players.LocalPlayer

M.tinsert  = table.insert
M.tremove  = table.remove
M.tsort    = table.sort
M.sfind    = string.find
M.smatch   = string.match
M.sformat  = string.format
M.slower   = string.lower
M.mabs     = math.abs
M.mfloor   = math.floor
M.mhuge    = math.huge
M.mmin     = math.min
M.tspawn   = task.spawn
M.twait    = task.wait
M.tdefer   = task.defer
M.tcancel  = task.cancel

return M
