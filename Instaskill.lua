local Players = game:GetService("Players")

local SEU_USER_ID = 5467515147
local RAIO = 50
local INTERVALO = 0.15

_G.InstaKillRunning = true

task.spawn(function()
	while _G.InstaKillRunning do
		task.wait(INTERVALO)

		local player = Players:GetPlayerByUserId(SEU_USER_ID)
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")

		if root then
			for _, npc in ipairs(workspace:GetDescendants()) do
				if npc:IsA("Model") and npc ~= character then
					local humanoid = npc:FindFirstChildOfClass("Humanoid")
					local npcRoot = npc:FindFirstChild("HumanoidRootPart")

					if humanoid
						and npcRoot
						and humanoid.Health > 0
						and not Players:GetPlayerFromCharacter(npc)
						and (npcRoot.Position - root.Position).Magnitude <= RAIO then

						humanoid.Health = 0
					end
				end
			end
		end
	end
end)

print("InstaKill ativado")
