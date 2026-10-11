-- Ima proximo experimental, somente no cliente.
-- Nao aplica dano, nao modifica hitboxes nem chama eventos de combate.
-- A posicao vista no cliente pode ser diferente da reconhecida pelo servidor.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Execute no cliente.")
local player = Players.LocalPlayer
assert(player, "Jogador local indisponivel.")

local RAIO = 1000
local DISTANCIA = 3
local ESPACAMENTO = 3
local INTERVALO = 0.15
local TOLERANCIA = 1.25

for _, name in ipairs({"MagnetDamageTestCleanup", "InstaKillCleanup",
    "NPCMagnetCleanup", "CloseNPCMagnetCleanup"}) do
    if type(_G[name]) == "function" then _G[name]() end
end

local active = true
local entries = {}
local nextId = 0
local connections = {}
local worker
_G.NPCMagnetEnabled = true

local function register(object)
    if object:IsA("Humanoid") and not entries[object] then
        nextId = nextId + 1
        entries[object] = nextId
    end
end

local function isPlayer(model)
    local ancestor = model
    while ancestor and ancestor ~= workspace do
        if ancestor:IsA("Model") and Players:GetPlayerFromCharacter(ancestor) then
            return true
        end
        ancestor = ancestor.Parent
    end
    return false
end

local function getNPC(humanoid, root)
    local model = humanoid.Parent
    if not model or not model:IsA("Model") or isPlayer(model)
        or humanoid.Health <= 0 then return end
    local part = humanoid.RootPart or model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
    if not part or not part:IsA("BasePart") or part.Anchored then return end
    if (part.Position - root.Position).Magnitude > RAIO then return end
    return model, part
end

local gui = Instance.new("ScreenGui")
gui.Name = "CloseNPCMagnetTest"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(180, 44)
button.Position = UDim2.new(0, 10, 0, 65)
button.Text = "Ima proximo: LIGADO"
button.TextSize = 16
button.BackgroundColor3 = Color3.fromRGB(35, 60, 45)
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = gui
table.insert(connections, button.Activated:Connect(function()
    _G.NPCMagnetEnabled = not _G.NPCMagnetEnabled
    button.Text = _G.NPCMagnetEnabled and "Ima proximo: LIGADO" or "Ima proximo: PAUSADO"
end))

local function cleanup()
    if not active then return end
    active = false
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(entries)
    gui:Destroy()
    if worker and coroutine.running() ~= worker then task.cancel(worker) end
    if _G.CloseNPCMagnetCleanup == cleanup then _G.CloseNPCMagnetCleanup = nil end
    if _G.NPCMagnetCleanup == cleanup then
        _G.NPCMagnetCleanup = nil
        _G.NPCMagnetEnabled = false
    end
end
_G.CloseNPCMagnetCleanup = cleanup
_G.NPCMagnetCleanup = cleanup

table.insert(connections, workspace.DescendantAdded:Connect(register))
table.insert(connections, workspace.DescendantRemoving:Connect(function(object)
    entries[object] = nil
end))
for _, object in ipairs(workspace:GetDescendants()) do register(object) end

local function update(character, root)
    local list = {}
    local excluded = {character}
    for humanoid, id in pairs(entries) do
        local model, part = getNPC(humanoid, root)
        if model then
            table.insert(list, {model = model, part = part, id = id})
            table.insert(excluded, model)
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    if forward.Magnitude < 0.01 then return end
    forward = forward.Unit
    local right = Vector3.new(-forward.Z, 0, forward.X)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = excluded
    params.RespectCanCollide = true
    -- Primeira fila: centro, esquerda, direita. Outras filas ficam atras dela.
    local columns = {0, -1, 1}
    for index, npc in ipairs(list) do
        local row = math.floor((index - 1) / 3)
        local column = columns[((index - 1) % 3) + 1]
        local destination = root.Position + forward * (DISTANCIA + row * ESPACAMENTO)
            + right * (column * ESPACAMENTO)
        local direction = destination - root.Position
        local wall = workspace:Raycast(root.Position, direction, params)
        if not wall and (npc.part.Position - destination).Magnitude > TOLERANCIA then
            local ok, err = pcall(function()
                -- Apenas translacao: preserva orientacao e animacoes.
                npc.model:PivotTo(npc.model:GetPivot() + (destination - npc.part.Position))
            end)
            if not ok then warn("Ima proximo: " .. tostring(err)) end
        end
    end
end

worker = task.spawn(function()
    while active do
        task.wait(INTERVALO)
        if not active then break end
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if _G.NPCMagnetEnabled and root and humanoid and humanoid.Health > 0 then
            local ok, err = pcall(update, character, root)
            if not ok then warn("Ima proximo: " .. tostring(err)) end
        end
    end
    cleanup()
end)
print("Ima proximo LOCAL: primeira fila a 3 studs. Acertos nao garantidos.")
-- Encerrar nao restaura as posicoes originais dos NPCs.
