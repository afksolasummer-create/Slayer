-- Teste LOCAL de contador. NAO confirma salto real de rodada ou recompensas.
-- Nao altera progresso de titulos e nao dispara eventos do servidor.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Execute no cliente.")
if type(_G.WaveCounter150Cleanup) == "function" then _G.WaveCounter150Cleanup() end
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
    warn("Teste interrompido: encontrados " .. #candidates .. " contadores candidatos; nenhuma wave alterada.")
    for _, object in ipairs(candidates) do print(object:GetFullName(), object.Value) end
    return
end
local counter = candidates[1]
local previous = counter.Value
local ok, err = pcall(function() counter.Value = 150 end)
if not ok then warn("Alteracao local falhou: " .. tostring(err)) return end
print("Contador LOCAL alterado: " .. counter:GetFullName() .. " de " .. previous .. " para 150.")
warn("Isso NAO comprova avanço real, inimigos da wave 150 ou recompensas.")
local function cleanup()
    if counter.Parent and counter.Value == 150 then counter.Value = previous end
    if _G.WaveCounter150Cleanup == cleanup then _G.WaveCounter150Cleanup = nil end
end
_G.WaveCounter150Cleanup = cleanup
-- Reverter contador: if _G.WaveCounter150Cleanup then _G.WaveCounter150Cleanup() end
