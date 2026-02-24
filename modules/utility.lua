-- ============================================
-- [MODULE 7] UTILITY HELPERS
-- ============================================

local M = {}

-- BUG FIX: was `p == "MzDGodPreview"` (altijd false), nu `p.Name == "MzDGodPreview"`
function M.isMzDPart(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local n = obj.Name
    if n == "MzDGodFloor" or n == "MzDGodCatchFloor" or n == "MzDGodFloorStripe" then return true end
    local p = obj.Parent
    while p do
        if p.Name == "MzDHubWalls" or p.Name == "MzDGodPreview" then return true end
        p = p.Parent
    end
    return false
end

local _lastPlotCall = 0
local PLOT_COOLDOWN = 0.15

function M.throttledPlotAction(MzD, action, guid, slot)
    local twait = task.wait
    local now  = tick()
    local wait = PLOT_COOLDOWN - (now - _lastPlotCall)
    if wait > 0 then twait(wait) end
    _lastPlotCall = tick()
    if not MzD.PlotAction then return false end
    if slot then
        return pcall(function() MzD.PlotAction:InvokeServer(action, guid, slot) end)
    elseif guid then
        return pcall(function() MzD.PlotAction:InvokeServer(action, guid) end)
    else
        return pcall(function() MzD.PlotAction:InvokeServer(action) end)
    end
end

function M.buildSurfaceGui(parent, face, theme)
    pcall(function()
        local sg = Instance.new("SurfaceGui")
        sg.Face        = face
        sg.CanvasSize  = Vector2.new(1600, 500)
        sg.AlwaysOnTop = false
        sg.Parent      = parent

        local title = Instance.new("TextLabel")
        title.Size               = UDim2.new(1, 0, 0.6, 0)
        title.Position           = UDim2.new(0, 0, 0.05, 0)
        title.BackgroundTransparency = 1
        title.Text               = "MzD Hub"
        title.TextColor3         = theme.glow
        title.TextScaled         = true
        title.Font               = Enum.Font.GothamBold
        title.Parent             = sg

        local sub = Instance.new("TextLabel")
        sub.Size               = UDim2.new(0.5, 0, 0.2, 0)
        sub.Position           = UDim2.new(0.25, 0, 0.68, 0)
        sub.BackgroundTransparency = 1
        sub.Text               = "v13.0"
        sub.TextColor3         = theme.stripe
        sub.TextScaled         = true
        sub.Font               = Enum.Font.Gotham
        sub.Parent             = sg

        local line = Instance.new("Frame")
        line.Size              = UDim2.new(0.7, 0, 0.025, 0)
        line.Position          = UDim2.new(0.15, 0, 0.65, 0)
        line.BackgroundColor3  = theme.stripe
        line.BorderSizePixel   = 0
        line.Parent            = sg
    end)
end

return M
