-- Teste LOCAL de contador. NAO confirma salto real de rodada ou recompensas.
-- Nao altera progresso de titulos e nao dispara eventos do servidor.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Execute no cliente.")
if type(_G.WaveCounter150Cleanup) == "function" then _G.WaveCounter150Cleanup() end
if type(_G.WaveCounter150StatusCleanup) == "function" then _G.WaveCounter150StatusCleanup() end
local gui = Instance.new("ScreenGui")
gui.Name = "WaveCounter150Status"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local panel = Instance.new("TextLabel")
panel.Size = UDim2.new(0.8, 0, 0.3, 0)
panel.Position = UDim2.new(0.1, 0, 0.2, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
panel.TextColor3 = Color3.new(1, 1, 1)
panel.TextSize = 16
panel.TextWrapped = true
panel.Text = "Teste LOCAL: procurando contador..."
panel.Parent = gui
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(44, 32)
close.Position = UDim2.new(0.9, -44, 0.2, -32)
close.Text = "X"
close.Parent = gui
local closeConnection
local function closeStatus()
    if closeConnection then closeConnection:Disconnect() end
    gui:Destroy()
    if _G.WaveCounter150StatusCleanup == closeStatus then
        _G.WaveCounter150StatusCleanup = nil
    end
end
closeConnection = close.Activated:Connect(closeStatus)
_G.WaveCounter150StatusCleanup = closeStatus

local names = {wave = true, currentwave = true, floor = true, currentfloor = true}
local candidates = {}
local function isPlayerData(object)
    local ancestor = object
    while ancestor do
        local name = string.lower(ancestor.Name)
        if ancestor == Players or name == "player_service" or name == "playertitles"
            or name == "leaderstats" then return true end
        if ancestor:IsA("Model") and (Players:GetPlayerFromCharacter(ancestor)
            or ancestor:FindFirstChildOfClass("Humanoid")) then return true end
        ancestor = ancestor.Parent
    end
    return false
end
for _, container in ipairs({workspace, game:GetService("ReplicatedStorage")}) do
    for _, object in ipairs(container:GetDescendants()) do
        if (object:IsA("IntValue") or object:IsA("NumberValue"))
            and names[string.lower(object.Name)] and not isPlayerData(object) then
            table.insert(candidates, object)
        end
    end
end
if #candidates ~= 1 then
    panel.Text = "Teste executado.\nContadores candidatos: " .. #candidates .. "\nNenhuma wave alterada.\nEste teste nao confirmou um salto para 150."
    warn("Teste interrompido: encontrados " .. #candidates .. " contadores candidatos; nenhuma wave alterada.")
    for _, object in ipairs(candidates) do print(object:GetFullName(), object.Value) end
    return
end
local counter = candidates[1]
local previous = counter.Value
local ok, err = pcall(function() counter.Value = 150 end)
if not ok then panel.Text = "Falha na alteracao local: " .. tostring(err); warn(tostring(err)); return end
panel.Text = "Contador LOCAL colocado em 150.\n" .. counter:GetFullName() .. "\nIsso nao confirma avanço da partida ou recompensas."
print("Contador LOCAL alterado: " .. counter:GetFullName() .. " de " .. previous .. " para 150.")
warn("Isso NAO comprova avanço real, inimigos da wave 150 ou recompensas.")
local function cleanup()
    if counter.Parent and counter.Value == 150 then counter.Value = previous end
    if _G.WaveCounter150Cleanup == cleanup then _G.WaveCounter150Cleanup = nil end
end
_G.WaveCounter150Cleanup = cleanup
-- Reverter contador: if _G.WaveCounter150Cleanup then _G.WaveCounter150Cleanup() end
