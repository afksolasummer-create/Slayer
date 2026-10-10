-- Versao CLIENTE: altera somente a vida observada localmente.
-- Nao garante morte, recompensas ou dano reconhecido pelo servidor.
-- Raio em studs ao redor do personagem, nao angulo da camera.
-- Somente NPCs carregados no cliente podem ser encontrados.
-- TESTE: tenta Tool:Activate() com a ferramenta equipada a cada 0.6s.
-- Nao aumenta o alcance da arma, nao mira e nao altera a validacao do servidor.
-- Ataque de longa distancia precisa de integracao ao combate do jogo.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

assert(RunService:IsClient(), "Esta versao precisa executar no cliente.")

local RAIO = 1000
local INTERVALO = 0.15
local INTERVALO_ATAQUE = 0.6
local ultimoAtaque = -math.huge
local ferramentaAtivada
local avisouSemFerramenta = false

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
	if ferramentaAtivada then
		pcall(function() ferramentaAtivada:Deactivate() end)
		ferramentaAtivada = nil
	end
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
	if humanoid.Health > 0 then
		humanoid.Health = 0
	end
	-- Mantem o alvo elegivel ao ataque mesmo com vida local zerada.
	return true
end

local function tentarAtaque(character)
	if os.clock() - ultimoAtaque < INTERVALO_ATAQUE then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		if not avisouSemFerramenta then
			warn("Equipe a espada/soco. Nenhuma Tool equipada; combate personalizado precisa de integracao.")
			avisouSemFerramenta = true
		end
		return
	end
	avisouSemFerramenta = false
	if not tool.Enabled or (tool.RequiresHandle and not tool:FindFirstChild("Handle")) then
		return
	end
	ultimoAtaque = os.clock()
	ferramentaAtivada = tool
	local ok, err = pcall(function() tool:Activate() end)
	if not ok then
		warn("Nao foi possivel ativar a ferramenta: " .. tostring(err))
	end
end

worker = task.spawn(function()
	while ativo and _G.InstaKillRunning do
		task.wait(INTERVALO)
		if ferramentaAtivada then
			pcall(function() ferramentaAtivada:Deactivate() end)
			ferramentaAtivada = nil
		end
		if not ativo or not _G.InstaKillRunning then
			break
		end
		local player = Players.LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local playerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and root:IsA("BasePart") and playerHumanoid and playerHumanoid.Health > 0 then
			local encontrouAlvo = false
			for humanoid in pairs(humanoids) do
				local ok, resultado = pcall(eliminarSeProximo, humanoid, root)
				if ok and resultado then encontrouAlvo = true end
				if not ok then
					warn("Instaskill: falha ao processar NPC: " .. tostring(resultado))
				end
			end
			if encontrouAlvo then tentarAtaque(character) end
		end
	end
	cleanup()
end)

-- Para parar neste cliente: _G.InstaKillCleanup()
warn("Instaskill LOCAL ativo; raio: " .. RAIO .. ". Morte e recompensas no servidor nao sao garantidas.")
