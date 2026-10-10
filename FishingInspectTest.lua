-- Read-only fishing UI diagnostic. Launch the fishing rod manually.
-- Does not change UI positions, send remote events, fish automatically or grant rewards.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
assert(player, "Run on the client.")
local playerGui = player:WaitForChild("PlayerGui")
if type(_G.FishingInspectCleanup) == "function" then _G.FishingInspectCleanup() end
local gui = Instance.new("ScreenGui")
gui.Name = "FishingInspectTest"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(240, 45)
button.Position = UDim2.new(0, 10, 0, 65)
button.Text = "Lance a vara; toque para analisar"
button.TextSize = 14
button.TextWrapped = true
button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = gui

local report = Instance.new("TextLabel")
report.Size = UDim2.new(0.85, 0, 0, 165)
report.Position = UDim2.new(0, 10, 0, 115)
report.Text = "Diagnostico somente: nao altera a pesca.\nAnalise com o minijogo aberto."
report.TextSize = 12
report.TextWrapped = true
report.TextXAlignment = Enum.TextXAlignment.Left
report.TextYAlignment = Enum.TextYAlignment.Top
report.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
report.BackgroundTransparency = 0.15
report.TextColor3 = Color3.new(1, 1, 1)
report.Parent = gui

local function visible(object)
    local ancestor = object
    while ancestor and ancestor ~= playerGui do
        if ancestor:IsA("GuiObject") and not ancestor.Visible then return false end
        if ancestor:IsA("ScreenGui") and not ancestor.Enabled then return false end
        ancestor = ancestor.Parent
    end
    return object.AbsoluteSize.X > 0 and object.AbsoluteSize.Y > 0
end

local function green(color)
    return color.G > 0.35 and color.G > color.R * 1.3 and color.G > color.B * 1.2
end

local connection = button.Activated:Connect(function()
    local greens, relevant = {}, {}
    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("GuiObject") and not object:IsDescendantOf(gui) and visible(object) then
            local name = object:GetFullName()
            local lower = string.lower(name)
            local isGreen = object.BackgroundTransparency < 1 and green(object.BackgroundColor3)
            if object:IsA("ImageLabel") or object:IsA("ImageButton") then
                isGreen = isGreen or (object.ImageTransparency < 1 and green(object.ImageColor3))
            end
            local line = name .. " | " .. object.ClassName
                .. " | pos=" .. tostring(object.AbsolutePosition)
                .. " | size=" .. tostring(object.AbsoluteSize)
            if isGreen then table.insert(greens, line) end
            if string.find(lower, "fish", 1, true) or string.find(lower, "pesca", 1, true)
                or string.find(lower, "reel", 1, true) then
                table.insert(relevant, line)
            end
        end
    end
    local lines = {"Interface de pesca (candidatos; nao confirmados):"}
    for i = 1, math.min(#relevant, 20) do table.insert(lines, relevant[i]) end
    table.insert(lines, "Elementos verdes visiveis: " .. #greens)
    for i = 1, math.min(#greens, 12) do table.insert(lines, greens[i]) end
    if #relevant == 0 and #greens == 0 then
        table.insert(lines, "Nenhum candidato. Abra o minijogo e analise novamente.")
    end
    _G.FishingInspectReport = table.concat(lines, "\n")
    print(_G.FishingInspectReport)
    local short = {}
    for i = 1, math.min(#lines, 7) do table.insert(short, lines[i]) end
    report.Text = table.concat(short, "\n")
end)

local function cleanup()
    connection:Disconnect()
    gui:Destroy()
    if _G.FishingInspectCleanup == cleanup then _G.FishingInspectCleanup = nil end
end
_G.FishingInspectCleanup = cleanup
