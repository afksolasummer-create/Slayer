-- Barreira de paredes LOCAL. Nao altera vida nem aplica dano.
-- Bloqueio de NPCs e ataques reconhecido pelo servidor nao e garantido.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Execute no cliente.")
local player = Players.LocalPlayer
assert(player, "Jogador local indisponivel.")
if type(_G.WallBarrierCleanup) == "function" then _G.WallBarrierCleanup() end

local RAIO = 6
local ALTURA = 8
local SEGMENTOS = 8
local enabled = true
local active = true
local folder = Instance.new("Folder")
folder.Name = "LocalWallBarrier"
folder.Parent = workspace
local walls = {}
local largura = 2 * RAIO * math.tan(math.pi / SEGMENTOS) + 0.2
for i = 1, SEGMENTOS do
    local wall = Instance.new("Part")
    wall.Name = "BarrierWall"
    wall.Anchored = true
    wall.CanCollide = false
    wall.CanTouch = false
    wall.CanQuery = false
    wall.CastShadow = false
    wall.Material = Enum.Material.Glass
    wall.Color = Color3.fromRGB(90, 190, 255)
    wall.Size = Vector3.new(largura, ALTURA, 0.6)
    wall.Transparency = 1
    wall.Parent = folder
    table.insert(walls, wall)
end

local gui = Instance.new("ScreenGui")
gui.Name = "WallBarrierUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local button = Instance.new("TextButton")
button.Size = UDim2.new(0.32, 0, 0.1, 0)
button.Position = UDim2.new(0.34, 0, 0.04, 0)
button.Text = "Parede local: LIGADA"
button.TextSize = 15
button.BackgroundColor3 = Color3.fromRGB(20, 55, 80)
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = gui
local connections = {}
table.insert(connections, button.Activated:Connect(function()
    enabled = not enabled
    button.Text = enabled and "Parede local: LIGADA" or "Parede local: PAUSADA"
end))

local function cleanup()
    if not active then return end
    active = false
    for _, connection in ipairs(connections) do connection:Disconnect() end
    folder:Destroy()
    gui:Destroy()
    if _G.WallBarrierCleanup == cleanup then _G.WallBarrierCleanup = nil end
end
_G.WallBarrierCleanup = cleanup
table.insert(connections, RunService.Heartbeat:Connect(function()
    if not active then return end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local show = enabled and root and humanoid and humanoid.Health > 0
    if not show then
        for _, wall in ipairs(walls) do
            wall.CanCollide = false
            wall.Transparency = 1
        end
        return
    end
    -- Base aproximada: 3 studs abaixo do centro do personagem.
    local center = root.Position + Vector3.new(0, ALTURA / 2 - 3, 0)
    for i, wall in ipairs(walls) do
        local angle = (i - 1) * 2 * math.pi / SEGMENTOS
        local position = center + Vector3.new(math.cos(angle) * RAIO, 0, math.sin(angle) * RAIO)
        wall.CFrame = CFrame.lookAt(position, center)
        wall.Transparency = 0.45
        wall.CanCollide = true
    end
end))
print("Barreira LOCAL de paredes ativa; nao concede imunidade.")
-- Remover: if _G.WallBarrierCleanup then _G.WallBarrierCleanup() end
