-- Experimental auto-activation for an equipped Roblox Tool in your own game.
-- Does NOT remove local or server cooldowns, extend reach, or bypass combat checks.
-- Custom attacks not implemented through Tool.Activated require their own integration.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Run this test on the client.")
local player = Players.LocalPlayer
assert(player, "LocalPlayer unavailable.")
local playerGui = player:WaitForChild("PlayerGui")

if type(_G.AutoAttackTestCleanup) == "function" then
    _G.AutoAttackTestCleanup()
end

local alive = true
local enabled = false
local pressedTool
local warned = false
local INTERVAL = 0.2
local PRESS_DURATION = 0.03

local gui = Instance.new("ScreenGui")
gui.Name = "AutoAttackTestGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "Toggle"
button.Size = UDim2.fromOffset(210, 52)
button.Position = UDim2.new(1, -225, 0, 80)
button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 17
button.Text = "Autoataque: DESLIGADO"
button.Parent = gui

local function release()
    local tool = pressedTool
    pressedTool = nil
    if tool and tool.Parent then
        pcall(function() tool:Deactivate() end)
    end
end

local connection = button.Activated:Connect(function()
    enabled = not enabled
    button.Text = enabled and "Autoataque: LIGADO" or "Autoataque: DESLIGADO"
    if not enabled then release() end
end)

local function cleanup()
    if not alive then return end
    alive = false
    enabled = false
    connection:Disconnect()
    release()
    gui:Destroy()
    if _G.AutoAttackTestCleanup == cleanup then
        _G.AutoAttackTestCleanup = nil
    end
end
_G.AutoAttackTestCleanup = cleanup

task.spawn(function()
    while alive do
        if enabled then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local tool = character and character:FindFirstChildOfClass("Tool")
            if humanoid and humanoid.Health > 0 and tool and tool.Enabled then
                pressedTool = tool
                local ok, err = pcall(function() tool:Activate() end)
                if not ok and not warned then
                    warned = true
                    warn("Autoattack activation failed: " .. tostring(err))
                end
                task.wait(PRESS_DURATION)
                release()
            end
        end
        task.wait(INTERVAL)
    end
end)

warn("Autoattack test ready: equip an attack Tool and toggle the button. Cooldowns remain unchanged.")
