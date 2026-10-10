-- Versao CLIENTE: altera somente a vida observada localmente.
-- Nao garante morte, recompensas ou dano reconhecido pelo servidor.
-- Raio em studs ao redor do personagem, nao angulo da camera.
-- Somente NPCs carregados no cliente podem ser encontrados.
-- Ataque de longa distancia precisa de integracao ao combate do jogo.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

assert(RunService:IsClient(), "Esta versao precisa executar no cliente.")

local RAIO = 1000
local INTERVALO = 0.15

-- Encerra a instancia anterior antes de iniciar outra.
if type(_G.InstaKillCleanup) == "function" then
	_G.InstaKillCleanup()
end

local ativo = true
local humanoids = {}
local connections = {}
local worker
_G.InstaKillRunning = true

local function registrar(instance)
	if instance:IsA("Humanoid") then
		humanoids[instance] = true
	end
end

local function cleanup()
	if not ativo then
		return
	end
	ativo = false
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
	table.clear(humanoids)
	if worker and coroutine.running() ~= worker then
		task.cancel(worker)
	end
	if _G.InstaKillCleanup == cleanup then
		_G.InstaKillCleanup = nil
		_G.InstaKillRunning = false
	end
end
_G.InstaKillCleanup = cleanup

table.insert(connections, workspace.DescendantAdded:Connect(registrar))
table.insert(connections, workspace.DescendantRemoving:Connect(function(instance)
	humanoids[instance] = nil
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

local function eliminarSeProximo(humanoid, playerRoot)
	local npc = humanoid.Parent
	if not npc or not npc:IsA("Model") or pertenceAJogador(npc) then
		return
	end
	if humanoid.Health <= 0 then
		return
	end

	local npcRoot = humanoid.RootPart
		or npc:FindFirstChild("HumanoidRootPart")
		or npc.PrimaryPart
		or npc:FindFirstChild("Torso")
		or npc:FindFirstChild("UpperTorso")
	if not npcRoot or not npcRoot:IsA("BasePart") then
		return
	end
	if (npcRoot.Position - playerRoot.Position).Magnitude > RAIO then
		return
	end

	-- Mesmo comportamento local da primeira versao; nao confirma morte no servidor.
	humanoid.Health = 0
end

worker = task.spawn(function()
	while ativo and _G.InstaKillRunning do
		task.wait(INTERVALO)
		if not ativo or not _G.InstaKillRunning then
			break
		end
		local player = Players.LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local playerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and root:IsA("BasePart") and playerHumanoid and playerHumanoid.Health > 0 then
			for humanoid in pairs(humanoids) do
				local ok, err = pcall(eliminarSeProximo, humanoid, root)
				if not ok then
					warn("Instaskill: falha ao processar NPC: " .. tostring(err))
				end
			end
		end
	end
	cleanup()
end)

-- Para parar neste cliente: _G.InstaKillCleanup()
warn("Instaskill LOCAL ativo; raio: " .. RAIO .. ". Morte e recompensas no servidor nao sao garantidas.")
