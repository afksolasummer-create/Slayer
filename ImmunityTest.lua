-- Experimental LOCAL ForceField for testing in your own Roblox game.
-- Does not change Health. Does not guarantee protection from server damage.
-- ForceField covers Humanoid:TakeDamage(), not direct Health assignments.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "This experimental version must run on the client.")

local player = Players.LocalPlayer
assert(player, "LocalPlayer is unavailable.")

if type(_G.ImmunityTestCleanup) == "function" then
    _G.ImmunityTestCleanup()
end

local active = true
local forceField
local characterConnection

local function attach(character)
    if not active then return end
    if forceField then
        forceField:Destroy()
        forceField = nil
    end
    forceField = Instance.new("ForceField")
    forceField.Name = "ImmunityTestForceField"
    forceField.Visible = true
    forceField.Parent = character
end

local function cleanup()
    if not active then return end
    active = false
    if characterConnection then
        characterConnection:Disconnect()
    end
    if forceField then
        forceField:Destroy()
        forceField = nil
    end
    if _G.ImmunityTestCleanup == cleanup then
        _G.ImmunityTestCleanup = nil
    end
end

_G.ImmunityTestCleanup = cleanup
characterConnection = player.CharacterAdded:Connect(attach)
if player.Character then
    attach(player.Character)
end

warn("Local ForceField test enabled. Server damage may still apply. Stop with _G.ImmunityTestCleanup().")
