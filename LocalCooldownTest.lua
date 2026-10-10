-- Local cooldown-gate experiment for your own Roblox game.
-- Tries ONLY to keep equipped Tool.Enabled=true.
-- Does NOT remove debounce variables, skill timers, server cooldowns or stamina checks.
-- Does NOT autoattack. Custom combat may be completely unaffected.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Run this test on the client.")
local player = Players.LocalPlayer
assert(player, "LocalPlayer unavailable.")

if type(_G.LocalCooldownTestCleanup) == "function" then
    _G.LocalCooldownTestCleanup()
end

local active = true
local toolConnections = {}
local characterConnections = {}
local respawnConnection

local function unwatch(tool)
    local connection = toolConnections[tool]
    if connection then connection:Disconnect() end
    toolConnections[tool] = nil
end

local function watch(tool)
    if not active or not tool:IsA("Tool") or toolConnections[tool] then return end
    local function enable()
        if active and tool.Parent == player.Character and not tool.Enabled then
            tool.Enabled = true
        end
    end
    toolConnections[tool] = tool:GetPropertyChangedSignal("Enabled"):Connect(enable)
    enable()
end

local function clearCharacter()
    for _, connection in ipairs(characterConnections) do
        connection:Disconnect()
    end
    table.clear(characterConnections)
    for tool, connection in pairs(toolConnections) do
        connection:Disconnect()
    end
    table.clear(toolConnections)
end

local function attach(character)
    if not active then return end
    clearCharacter()
    characterConnections[1] = character.ChildAdded:Connect(watch)
    characterConnections[2] = character.ChildRemoved:Connect(unwatch)
    for _, child in ipairs(character:GetChildren()) do
        watch(child)
    end
end

local function cleanup()
    if not active then return end
    active = false
    if respawnConnection then respawnConnection:Disconnect() end
    clearCharacter()
    -- Original cooldown timing cannot be reconstructed; no stale Enabled value is restored.
    if _G.LocalCooldownTestCleanup == cleanup then
        _G.LocalCooldownTestCleanup = nil
    end
    warn("Local gate test stopped. Rejoin for a clean comparison.")
end

_G.LocalCooldownTestCleanup = cleanup
respawnConnection = player.CharacterAdded:Connect(attach)
if player.Character then attach(player.Character) end
warn("LOCAL TEST: keeping equipped Tool.Enabled=true. Skill/script/server cooldowns may remain unchanged.")
