-- Diagnostico somente: NAO pula waves e NAO chama eventos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
assert(player, "Execute no cliente.")
if type(_G.WaveInspectCleanup) == "function" then _G.WaveInspectCleanup() end

local gui = Instance.new("ScreenGui")
gui.Name = "WaveInspectTest"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(220, 44)
button.Position = UDim2.new(0, 10, 0, 220)
button.Text = "Analisar waves (nao avanca)"
button.TextSize = 14
button.Parent = gui
local report = Instance.new("TextBox")
report.Size = UDim2.new(0.8, 0, 0, 170)
report.Position = UDim2.new(0, 10, 0, 270)
report.MultiLine = true
report.TextEditable = false
report.ClearTextOnFocus = false
report.TextWrapped = true
report.TextXAlignment = Enum.TextXAlignment.Left
report.TextYAlignment = Enum.TextYAlignment.Top
report.TextSize = 12
report.Text = "Abra Roguelike ou Tower e toque em analisar. Diagnostico somente."
report.Parent = gui

local function matches(name)
    name = string.lower(name)
    for _, keyword in ipairs({"wave", "floor", "round"}) do
        if string.find(name, keyword, 1, true) then return true end
    end
    return false
end
local connection = button.Activated:Connect(function()
    local lines = {"DIAGNOSTICO: nao avancou nenhuma wave.", "PlaceId: " .. game.PlaceId}
    for _, container in ipairs({ReplicatedStorage, workspace, player:WaitForChild("PlayerGui")}) do
        for _, object in ipairs(container:GetDescendants()) do
            if not object:IsDescendantOf(gui) and matches(object.Name) then
                local line
                if object:IsA("IntValue") or object:IsA("NumberValue") then
                    line = object:GetFullName() .. " | " .. object.ClassName .. " = " .. tostring(object.Value)
                elseif object:IsA("RemoteEvent") or object:IsA("RemoteFunction") then
                    line = object:GetFullName() .. " | " .. object.ClassName .. " (nao chamado)"
                elseif object:IsA("TextLabel") or object:IsA("TextButton") then
                    line = object:GetFullName() .. " | texto: " .. string.sub(object.Text, 1, 80)
                end
                if line and #lines < 42 then table.insert(lines, line) end
            end
        end
    end
    if #lines == 2 then table.insert(lines, "Nenhum candidato encontrado por nome.") end
    _G.WaveInspectReport = table.concat(lines, "\n")
    print(_G.WaveInspectReport)
    local short = {}
    for i = 1, math.min(#lines, 8) do table.insert(short, lines[i]) end
    report.Text = table.concat(short, "\n")
end)
local function cleanup()
    connection:Disconnect()
    gui:Destroy()
    if _G.WaveInspectCleanup == cleanup then _G.WaveInspectCleanup = nil end
end
_G.WaveInspectCleanup = cleanup
