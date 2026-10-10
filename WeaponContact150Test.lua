-- Experimental CLIENT weapon-contact damage test.
-- Adds a LOCAL TakeDamage(150) attempt when an equipped Tool's Handle touches
-- a non-player Humanoid within 0.4 seconds of Tool.Activated.
-- Does NOT replace the original attack damage or guarantee server damage/deaths.
-- Fists, raycast attacks and skills without Handle contact are unsupported.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Run this test on the client.")
local player = Players.LocalPlayer
assert(player, "LocalPlayer unavailable.")
if type(_G.WeaponContact150Cleanup) == "function" then _G.WeaponContact150Cleanup() end
local active = true
local DAMAGE = 150
local WINDOW = 0.4
local records = {}
local characterConnections = {}
local respawnConnection

local function unwatch(tool)
    local record = records[tool]
    if not record then return end
    for _, connection in ipairs(record.connections) do connection:Disconnect() end
    records[tool] = nil
end

local function findNPC(part)
    local ancestor = part.Parent
    local candidate
    while ancestor and ancestor ~= workspace do
        if ancestor:IsA("Model") then
            if ancestor == player.Character or Players:GetPlayerFromCharacter(ancestor) then
                return nil
            end
            if not candidate then
                candidate = ancestor:FindFirstChildOfClass("Humanoid")
            end
        end
        ancestor = ancestor.Parent
    end
    return candidate
end

local function watch(tool)
    if not active or not tool:IsA("Tool") or records[tool] then return end
    local record = {connections = {}, deadline = -math.huge, hit = {}}
    records[tool] = record
    local boundHandle
    local function bindHandle(handle)
        if boundHandle or handle.Name ~= "Handle" or not handle:IsA("BasePart") then return end
        boundHandle = handle
        table.insert(record.connections, handle.Touched:Connect(function(part)
            if not active or tool.Parent ~= player.Character or os.clock() > record.deadline then return end
            local ownHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if not ownHumanoid or ownHumanoid.Health <= 0 then return end
            local humanoid = findNPC(part)
            if humanoid and humanoid.Health > 0 and not record.hit[humanoid] then
                record.hit[humanoid] = true
                humanoid:TakeDamage(DAMAGE)
            end
        end))
    end
    table.insert(record.connections, tool.Activated:Connect(function()
        if active and tool.Parent == player.Character then
            record.hit = {}
            record.deadline = os.clock() + WINDOW
        end
    end))
    table.insert(record.connections, tool.Deactivated:Connect(function()
        record.deadline = -math.huge
    end))
    table.insert(record.connections, tool.ChildAdded:Connect(bindHandle))
    local handle = tool:FindFirstChild("Handle")
    if handle then bindHandle(handle) end
    if not boundHandle then
        warn("Contact test: " .. tool.Name .. " has no Handle; fists/skills may not trigger this test.")
    end
end

local function clearCharacter()
    for _, connection in ipairs(characterConnections) do connection:Disconnect() end
    table.clear(characterConnections)
    for tool in pairs(records) do unwatch(tool) end
end
local function attach(character)
    if not active then return end
    clearCharacter()
    characterConnections[1] = character.ChildAdded:Connect(watch)
    characterConnections[2] = character.ChildRemoved:Connect(unwatch)
    for _, child in ipairs(character:GetChildren()) do watch(child) end
end
local function cleanup()
    if not active then return end
    active = false
    if respawnConnection then respawnConnection:Disconnect() end
    clearCharacter()
    if _G.WeaponContact150Cleanup == cleanup then _G.WeaponContact150Cleanup = nil end
end
_G.WeaponContact150Cleanup = cleanup
respawnConnection = player.CharacterAdded:Connect(attach)
if player.Character then attach(player.Character) end
warn("LOCAL weapon-contact test enabled. Adds 150 locally on Handle contact during activation. Original attack damage is unchanged.")
