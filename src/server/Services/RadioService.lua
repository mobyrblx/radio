local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local RadioService = Knit.CreateService {
	Name = "RadioService",
	Client = {}
}

function RadioService.Client:Play(player: Player, soundId: string)
	if typeof(soundId) ~= "string" then
		return
	end

	local character: Model = player.Character or player.CharacterAdded:Wait()

	if not character.Parent then
		character.AncestryChanged:Wait()
	end

	local sound: Sound = self.Server:GetSound(character, soundId)	
	if sound then
		sound:Play()
	end
end	

function RadioService.Client:Stop(player: Player)
	local character: Model = player.Character or player.CharacterAdded:Wait()

	if not character.Parent then
		character.AncestryChanged:Wait()
	end

	local sound: Sound = self.Server:GetSound(character)	
	if sound then
		sound:Stop()
	end
end

function RadioService.Client:Skip(player: Player, timePosition: number)
	if typeof(timePosition) ~= "number" then
		return
	end

	local character: Model = player.Character or player.CharacterAdded:Wait()

	if not character.Parent then
		character.AncestryChanged:Wait()
	end

	local sound: Sound = self.Server:GetSound(character)	
	if sound then
		sound.TimePosition = timePosition
	end
end

function RadioService:GetSound(character: Model, soundId: string)
	local radio = character:WaitForChild("Radio", 10)

	if radio then
		local sound = radio:FindFirstChildWhichIsA("Sound")

		if sound then
			sound.SoundId = soundId or sound.SoundId
			return sound
		else
			return RadioService:MakeSound(radio, soundId)
		end
	end
end

function RadioService:MakeSound(radio: BasePart, soundId: Sound)
	local sound = Instance.new("Sound")
	sound.Name = "RadioSound"
	sound.SoundId = soundId or sound.SoundId
	sound.Volume = 0.5
	sound.Looped = true
	sound.Parent = radio

	return sound
end

local function weld(part0: BasePart, part1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Name = part0.Name .. " -> " .. part1.Name
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0

	return weld
end

local RADIO_MODEL = ServerStorage:WaitForChild("Radio")

function RadioService:GiveRadio(character: Model)
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")

	local radio = RADIO_MODEL:Clone()
	CollectionService:AddTag(radio, "RadioComponent")
	radio.CFrame = humanoid.RootPart.CFrame * CFrame.Angles(0, math.pi, math.pi/4) - torso.CFrame.LookVector
	weld(torso, radio)
	radio.Parent = character

	return radio
end

function RadioService:KnitInit()
	local function playerAdded(player: Player)
		local function characterAdded(character: Model)
			if not character.Parent then
				character.AncestryChanged:Wait()
			end

			self:GiveRadio(character)
		end

		local character = player.Character
		
		if character then
			task.spawn(characterAdded, character)
		end

		player.CharacterAdded:Connect(characterAdded)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(playerAdded, player)
	end

	Players.PlayerAdded:Connect(playerAdded)
end

return RadioService
