-- Standalone client damage-aura experiment for your own game.
-- LOCAL TEST ONLY: server health, deaths, rewards and custom combat may be unaffected.
-- Targets loaded non-player Humanoids. No weapon or remote-event guessing.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Run this experimental version on the client.")
local player = Players.LocalPlayer
assert(player, "LocalPlayer unavailable.")

local RADIUS = 20
local DAMAGE = 10
local INTERVAL = 0.5

if type(_G.DamageAuraTestCleanup) == "function" then
    _G.DamageAuraTestCleanup()
end

local active = true
local humanoids = {}
local connections = {}

local function track(instance)
    if instance:IsA("Humanoid") then
        humanoids[instance] = true
    end
end

connections[1] = workspace.DescendantAdded:Connect(track)
connections[2] = workspace.DescendantRemoving:Connect(function(instance)
    humanoids[instance] = nil
end)
for _, instance in ipairs(workspace:GetDescendants()) do
    track(instance)
end

local function belongsToPlayer(model)
    local ancestor = model
    while ancestor and ancestor ~= workspace do
        if ancestor:IsA("Model") and Players:GetPlayerFromCharacter(ancestor) then
            return true
        end
        if ancestor == player.Character then
            return true
        end
        ancestor = ancestor.Parent
    end
    return false
end

local function cleanup()
    if not active then return end
    active = false
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(humanoids)
    if _G.DamageAuraTestCleanup == cleanup then
        _G.DamageAuraTestCleanup = nil
    end
end
_G.DamageAuraTestCleanup = cleanup

task.spawn(function()
    while active do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local ownHumanoid = character and character:FindFirstChildOfClass("Humanoid")
        if root and ownHumanoid and ownHumanoid.Health > 0 then
            for humanoid in pairs(humanoids) do
                local model = humanoid.Parent
                if model and model:IsA("Model") and humanoid.Health > 0
                    and not belongsToPlayer(model) then
                    local targetRoot = model:FindFirstChild("HumanoidRootPart")
                        or model.PrimaryPart
                    if targetRoot and targetRoot:IsA("BasePart")
                        and (targetRoot.Position - root.Position).Magnitude <= RADIUS then
                        humanoid:TakeDamage(DAMAGE)
                    end
                end
            end
        end
        task.wait(INTERVAL)
    end
end)
warn("LOCAL damage-aura test: radius 20, damage 10 every 0.5s. Server may ignore changes. Stop: _G.DamageAuraTestCleanup()")
