-- ============================================
-- [MODULE 22] INSTANT PICKUP
-- ============================================

local M = {}

function M.init(Modules)
    local G   = Modules.globals
    local MzD = G.MzD

    function MzD.setupInstant()
        for _, o in pairs(workspace:GetDescendants()) do
            if o:IsA("ProximityPrompt") then pcall(function() o.HoldDuration = 0 end) end
        end
        if not MzD._instantConn then
            MzD._instantConn = workspace.DescendantAdded:Connect(function(o)
                if o:IsA("ProximityPrompt") then pcall(function() o.HoldDuration = 0 end) end
            end)
        end
    end
    MzD.setupInstant()
end

return M
