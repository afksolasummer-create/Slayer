-- Tornado experimental LOCAL. Nao usa a skill do leque.
-- Dano local nao garante mortes ou recompensas reconhecidas pelo servidor.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Execute no cliente.")
local player = Players.LocalPlayer
assert(player, "Jogador local indisponivel.")
if type(_G.TornadoTestCleanup) == "function" then _G.TornadoTestCleanup() end

local DISTANCIA = 6
local RAIO = 8
local DANO = 10
local INTERVALO = 0.5
local active = true
local enabled = true
local elapsed = 0
local lastDamage = 0
local humanoids = {}
local connections = {}
local model = Instance.new("Model")
model.Name = "LocalTornadoTest"
model.Parent = workspace

local pieces = {}
for layer = 1, 3 do
    for index = 1, 8 do
        local part = Instance.new("Part")
        part.Name = "Wind"
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Material = Enum.Material.Neon
        part.Color = layer == 2 and Color3.fromRGB(125, 220, 255) or Color3.fromRGB(230, 250, 255)
        part.Size = Vector3.new(0.3, 0.35, 2.3)
        part.Transparency = 1
        part.Parent = model
        table.insert(pieces, {part = part, layer = layer, index = index})
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "TornadoTestUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(190, 44)
button.Position = UDim2.new(0, 10, 0, 170)
button.Text = "Tornado local: LIGADO"
button.TextSize = 15
button.BackgroundColor3 = Color3.fromRGB(25, 65, 85)
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = gui
table.insert(connections, button.Activated:Connect(function()
    enabled = not enabled
    button.Text = enabled and "Tornado local: LIGADO" or "Tornado local: PAUSADO"
end))

local function register(object)
    if object:IsA("Humanoid") then humanoids[object] = true end
end
table.insert(connections, workspace.DescendantAdded:Connect(register))
table.insert(connections, workspace.DescendantRemoving:Connect(function(object)
    humanoids[object] = nil
end))
for _, object in ipairs(workspace:GetDescendants()) do register(object) end

local function isPlayer(npc)
    local ancestor = npc
    while ancestor and ancestor ~= workspace do
        if ancestor:IsA("Model") and Players:GetPlayerFromCharacter(ancestor) then return true end
        ancestor = ancestor.Parent
    end
    return false
end

local function damage(center)
    for humanoid in pairs(humanoids) do
        local npc = humanoid.Parent
        if npc and npc:IsA("Model") and not isPlayer(npc) and humanoid.Health > 0 then
            local root = humanoid.RootPart or npc:FindFirstChild("HumanoidRootPart")
                or npc:FindFirstChild("Torso") or npc:FindFirstChild("UpperTorso")
            if root and root:IsA("BasePart") and (root.Position - center).Magnitude <= RAIO then
                local ok, err = pcall(function() humanoid:TakeDamage(DANO) end)
                if not ok then warn("Tornado local: " .. tostring(err)) end
            end
        end
    end
end

local function cleanup()
    if not active then return end
    active = false
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(humanoids)
    model:Destroy()
    gui:Destroy()
    if _G.TornadoTestCleanup == cleanup then _G.TornadoTestCleanup = nil end
end
_G.TornadoTestCleanup = cleanup

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if not active then return end
    elapsed = elapsed + dt
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local ownHumanoid = character and character:FindFirstChildOfClass("Humanoid")
    local show = enabled and root and ownHumanoid and ownHumanoid.Health > 0
    if not show then
        for _, piece in ipairs(pieces) do piece.part.Transparency = 1 end
        return
    end
    local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    if forward.Magnitude < 0.01 then return end
    local center = root.Position + forward.Unit * DISTANCIA
    for _, piece in ipairs(pieces) do
        local angle = elapsed * 5 + piece.index * math.pi / 4 + piece.layer * 0.4
        local radius = 1.3 + piece.layer * 0.9
        local height = (piece.layer - 1) * 2.1 - 1
        piece.part.CFrame = CFrame.new(center + Vector3.new(
            math.cos(angle) * radius, height, math.sin(angle) * radius))
            * CFrame.Angles(0, -angle, 0)
        piece.part.Transparency = 0.3
    end
    if elapsed - lastDamage >= INTERVALO then
        lastDamage = elapsed
        damage(center)
    end
end))
print("Tornado LOCAL ativo: 10 de dano / 0.5s, raio 8. Mortes reais nao garantidas.")
-- Encerrar: if _G.TornadoTestCleanup then _G.TornadoTestCleanup() end
