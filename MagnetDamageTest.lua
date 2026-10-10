-- Generic CLIENT experiment: NPC magnet + local damage aura.
-- Intended for testing; NOT a verified Project Slayers 2 Roguelike integration.
-- Magnet radius: 1000. Damage radius: 20; damage: 10 every 0.5 seconds.
-- Does not guarantee server deaths, wave completion or rewards.
if type(_G.MagnetDamageTestCleanup) == "function" then
    _G.MagnetDamageTestCleanup()
end

do
-- Ima de NPCs somente, executado no cliente.
-- Nao aplica dano nem ativa ferramentas.
-- Apenas NPCs carregados; o servidor pode corrigir as posicoes.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "Execute o ima no cliente.")

local RAIO = 1000
local DISTANCIA = 6
local INTERVALO = 0.15

-- Para os scripts anteriores desta conversa, evitando dano em paralelo.
if type(_G.InstaKillCleanup) == "function" then
	_G.InstaKillCleanup()
end
if type(_G.NPCMagnetCleanup) == "function" then
	_G.NPCMagnetCleanup()
end

local ativo = true
local humanoids = {}
local posicoes = setmetatable({}, {__mode = "k"})
local proximaPosicao = 0
local connections = {}
local worker
_G.NPCMagnetEnabled = true

local function registrar(instance)
	if instance:IsA("Humanoid") then
		humanoids[instance] = true
	end
end

local function cleanup()
	if not ativo then return end
	ativo = false
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
	table.clear(humanoids)
	if worker and coroutine.running() ~= worker then
		task.cancel(worker)
	end
	if _G.NPCMagnetCleanup == cleanup then
		_G.NPCMagnetCleanup = nil
		_G.NPCMagnetEnabled = false
	end
end
_G.NPCMagnetCleanup = cleanup

table.insert(connections, workspace.DescendantAdded:Connect(registrar))
table.insert(connections, workspace.DescendantRemoving:Connect(function(instance)
	humanoids[instance] = nil
	posicoes[instance] = nil
end))
for _, instance in ipairs(workspace:GetDescendants()) do
	registrar(instance)
end

local function pertenceAJogador(model)
	local ancestor = model
	while ancestor and ancestor ~= workspace do
		if ancestor:IsA("Model") and Players:GetPlayerFromCharacter(ancestor) then
			return true
		end
		ancestor = ancestor.Parent
	end
	return false
end

local function aproximar(humanoid, root)
	local npc = humanoid.Parent
	if not npc or not npc:IsA("Model") or pertenceAJogador(npc) then return end
	if humanoid.Health <= 0 then return end
	local npcRoot = humanoid.RootPart
		or npc:FindFirstChild("HumanoidRootPart")
		or npc.PrimaryPart
		or npc:FindFirstChild("Torso")
		or npc:FindFirstChild("UpperTorso")
	if not npcRoot or not npcRoot:IsA("BasePart") then return end
	if (npcRoot.Position - root.Position).Magnitude > RAIO then return end
	if not posicoes[humanoid] then
		proximaPosicao = proximaPosicao + 1
		posicoes[humanoid] = proximaPosicao
	end
	local angulo = posicoes[humanoid] * 2.3999632297
	local centro = root.Position + root.CFrame.LookVector * DISTANCIA
	local destino = centro + Vector3.new(math.cos(angulo) * 2, 0, math.sin(angulo) * 2)
	npc:PivotTo(npc:GetPivot() + (destino - npcRoot.Position))
end

worker = task.spawn(function()
	while ativo do
		task.wait(INTERVALO)
		if not ativo then break end
		local player = Players.LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if _G.NPCMagnetEnabled and root and root:IsA("BasePart")
			and humanoid and humanoid.Health > 0 then
			for npcHumanoid in pairs(humanoids) do
				local ok, err = pcall(aproximar, npcHumanoid, root)
				if not ok then warn("Ima de NPCs: " .. tostring(err)) end
			end
		end
	end
	cleanup()
end)

-- Pausar: _G.NPCMagnetEnabled = false
-- Retomar: _G.NPCMagnetEnabled = true
-- Encerrar: if _G.NPCMagnetCleanup then _G.NPCMagnetCleanup() end
-- Pausar/encerrar nao restaura posicoes nem vida alterada pelo script anterior.
print("Ima LOCAL de NPCs ativo; raio: " .. RAIO)

end

do
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

end

local stopMagnet = _G.NPCMagnetCleanup
local stopDamage = _G.DamageAuraTestCleanup
local stopped = false
local function cleanup()
    if stopped then return end
    stopped = true
    if type(stopMagnet) == "function" then stopMagnet() end
    if type(stopDamage) == "function" then stopDamage() end
    if _G.MagnetDamageTestCleanup == cleanup then
        _G.MagnetDamageTestCleanup = nil
    end
end
_G.MagnetDamageTestCleanup = cleanup
warn("Combined LOCAL test enabled. Not verified in Roguelike; server may ignore damage and movement.")
