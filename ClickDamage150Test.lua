-- CLIENT-ONLY click damage experiment. Not a modification of server combat damage.
-- Each click attempts 150 local damage on the nearest loaded non-player Humanoid within 20 studs.
-- Server deaths/rewards are NOT guaranteed. Existing auto-damage tests are stopped for comparison.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
assert(RunService:IsClient(), "Run this experiment on the client.")
local player = Players.LocalPlayer
assert(player, "LocalPlayer unavailable.")
local DAMAGE = 150
local RADIUS = 20
local active = true
local lastClick = -math.huge
local targets = {}
local connections = {}

if type(_G.ClickDamageTestCleanup) == "function" then _G.ClickDamageTestCleanup() end
if type(_G.DamageAuraTestCleanup) == "function" then _G.DamageAuraTestCleanup() end
if type(_G.InstaKillCleanup) == "function" then _G.InstaKillCleanup() end

local function track(instance)
    if instance:IsA("Humanoid") then targets[instance] = true end
end
connections[#connections + 1] = workspace.DescendantAdded:Connect(track)
connections[#connections + 1] = workspace.DescendantRemoving:Connect(function(instance)
    targets[instance] = nil
end)
for _, instance in ipairs(workspace:GetDescendants()) do track(instance) end

local function isPlayer(model)
    local ancestor = model
    while ancestor and ancestor ~= workspace do
        if ancestor == player.Character then return true end
        if ancestor:IsA("Model") and Players:GetPlayerFromCharacter(ancestor) then return true end
        ancestor = ancestor.Parent
    end
    return false
end

local function hitNearest()
    if not active or os.clock() - lastClick < 0.15 then return end
    lastClick = os.clock()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local ownHumanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not ownHumanoid or ownHumanoid.Health <= 0 then return end
    local nearest, nearestDistance
    for humanoid in pairs(targets) do
        local model = humanoid.Parent
        if model and model:IsA("Model") and humanoid.Health > 0 and not isPlayer(model) then
            local targetRoot = humanoid.RootPart or model:FindFirstChild("HumanoidRootPart")
                or model.PrimaryPart
            if targetRoot and targetRoot:IsA("BasePart") then
                local distance = (targetRoot.Position - root.Position).Magnitude
                if distance <= RADIUS and (not nearestDistance or distance < nearestDistance) then
                    nearest, nearestDistance = humanoid, distance
                end
            end
        end
    end
    if nearest then nearest:TakeDamage(DAMAGE) end
end

local gui = Instance.new("ScreenGui")
gui.Name = "ClickDamage150Test"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(200, 50)
button.Position = UDim2.new(1, -215, 0, 145)
button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 17
button.Text = "Teste: dano 150"
button.Parent = gui
connections[#connections + 1] = button.Activated:Connect(hitNearest)
connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and not UserInputService:GetFocusedTextBox()
        and input.UserInputType == Enum.UserInputType.MouseButton1 then
        hitNearest()
    end
end)

local function cleanup()
    if not active then return end
    active = false
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(targets)
    gui:Destroy()
    if _G.ClickDamageTestCleanup == cleanup then _G.ClickDamageTestCleanup = nil end
end
_G.ClickDamageTestCleanup = cleanup
warn("LOCAL click test enabled: 150 damage, nearest NPC within 20 studs. Left click or use the button. Server may ignore damage.")
