
--[[

Written by Mystifine#4924

This is a MMO type AI Controller; was made for Square Piece.
This is for Humanoid NPC's.

I'd appreciate credit <3

]]

--|| Services ||--
local ReplicatedStorage = game.ReplicatedStorage
local RunService = game:GetService("RunService")
local ServerStorage = game.ServerStorage
local Players = game:GetService("Players")

--|| Modules ||--
local AI_Handler = require(script["AI Handler"])
local Database = require(script.Database)
local Properties = require(script.Properties)

--|| Localise ||--
local Ipairs = ipairs
local Max = math.max
local Clock = os.clock
local Rng = math.random
local Next = next

--|| Variables ||--
local Cache = {
	SpawnerData = {},
}

local function Halt(n)
	n = n or 1/60
	local Begin = Clock()
	while Clock() - Begin < n do
		RunService.Stepped:Wait()
	end
end

local function Debug(Msg, Warn)
	if Properties.DEBUG then
		if Warn then
			warn("[AI HANDLER]: "..Msg)
		else
			print("[AI HANDLER]: "..Msg)
		end
	end
end

local function isAlive(Model)
	if Model and Model ~= nil  
	and Model:FindFirstChild"Humanoid"
	and Model:FindFirstChild"HumanoidRootPart"
	and Model.Humanoid.Health > 0 then
		return true
	end
end

local function isWithinRange(Pos1, Pos2, Range)
	return (Pos1 - Pos2).Magnitude <= Range
end

function copyTable(Table)
	local newTable = {}
	for Index, Value in Next, Table do
		if typeof(Value) == "table" then
			newTable[Index] = copyTable(Value)
		else
			newTable[Index] = Value
		end
	end
	return newTable
end

local function getNearestSpawner(Id, Position)
	local NearestSpawner = nil
	for Spawner, SpawnerData in Next, Cache.SpawnerData[Id] do
		local Distance = (Position - Spawner.Position).Magnitude
		if not NearestSpawner then
			NearestSpawner = {Spawner, Distance}
		elseif Distance < NearestSpawner[2] then
			NearestSpawner = {Spawner, Distance}
		end	
	end
	return NearestSpawner[1]
end

local function getNearestEnemy(NPC)
	local ClosestEnemy = nil	
	if isAlive(NPC.Model) then
		for _, Player in Ipairs(Players:GetPlayers()) do
			if isAlive(Player.Character) then
				local Distance = (NPC.Model.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude
				if not ClosestEnemy then
					ClosestEnemy = {Player.Character, Distance}
				elseif Distance < ClosestEnemy[2] then
					ClosestEnemy = {Player.Character, Distance}
				end
			end
		end
	end
	return ClosestEnemy and ClosestEnemy[1] or nil
end

local function GatherSpawnerData()
	local Directory = Properties.NPC_SPAWNER_DIRECTORY
	for _, Container in Ipairs(Directory:GetChildren()) do
		Cache.SpawnerData[Container.Name] = {}
		for _, Spawner in Ipairs(Container:GetChildren()) do
			Spawner.CanCollide = false -- Collision should be set to false
			Cache.SpawnerData[Container.Name][Spawner] = {
				LargestScale = Max(Spawner.Size.X,Spawner.Size.Y,Spawner.Size.Z), -- We'll use this to measure distance
				NPCS = {},	
				LastUpdate = Clock(),
			}
		end
	end
end
GatherSpawnerData()

local function GetNewNPCData(Id, CFrame)
	return {
		Id = Id,
		CFrame = CFrame,
		LastUpdate = Clock() + 5 * Rng(), -- To Spread It Out
		LastAttack = Clock(),
		Data = copyTable(Database[Id].MiscData),
		LastAttackIndex = 0,
		Animations = {},
	}
end

local function GatherExistingNPCS()
	local Directory = Properties.NPC_DIRECTORY
	for _, Entity in Ipairs(Directory:GetChildren()) do
		if Database[Entity.Name] then
			
			if Entity:FindFirstChild"HumanoidRootPart" then
				local NewData = GetNewNPCData(Entity.Name, Entity.HumanoidRootPart.CFrame)
				local NPC = AI_Handler.new(NewData)
				local NearestSpawner = getNearestSpawner(NPC.Id, NPC.CFrame.Position)
				Cache.SpawnerData[NPC.Id][NearestSpawner].NPCS[#Cache.SpawnerData[NPC.Id][NearestSpawner].NPCS + 1] = NPC
				Entity:Destroy()
			else
				warn("[AI CONTROL SERVER]: When gathering existing npc's; "..Entity.Name.." did not have a humanoid root part!")
			end
		end
	end
end
GatherExistingNPCS()

local function SpawnNPC(Spawner, Id, Amount)
	for _ = 1, Amount do
		local StartPosition = Spawner.Position
		local RandomX, RandomZ = math.random(-Spawner.Size.X/2, Spawner.Size.X/2),math.random(-Spawner.Size.Z/2, Spawner.Size.Z/2) 
		local RandomPoint = StartPosition + Vector3.new(RandomX,0,RandomZ)
		
		local EndPoint = RandomPoint - Vector3.new(0,1000,0)
		local RaycastData = RaycastParams.new()
		RaycastData.FilterDescendantsInstances = {Properties.NPC_SPAWNER_DIRECTORY}
		RaycastData.FilterType = Enum.RaycastFilterType.Blacklist
		local RaycastResult = game.Workspace:Raycast(RandomPoint, (EndPoint - RandomPoint).Unit * 1000)
		
		local Size, _ = Properties.NPC_STORAGE_DIRECTORY[Id]:GetBoundingBox()
		
		if RaycastResult then
			--| Here we want to generate random points
			local NewData = GetNewNPCData(Id, CFrame.new(RaycastResult.Position + Vector3.new(0,Size.Y/2,0)) * CFrame.fromEulerAnglesXYZ(0,math.random(-360,360),0))
			local NPC = AI_Handler.new(NewData)
			local NearestSpawner = getNearestSpawner(NPC.Id, NPC.CFrame.Position)
			Cache.SpawnerData[NPC.Id][NearestSpawner].NPCS[#Cache.SpawnerData[NPC.Id][NearestSpawner].NPCS + 1] = NPC
		end
	end
end

local function SpawnNPCS()
	for Id, Spawners in Next, Cache.SpawnerData do
		for Spawner, Data in Next, Spawners do
			local ExistingNPCS = #Data.NPCS
			if ExistingNPCS < Database[Id].Quantity then
				local Amount = Database[Id].Quantity - ExistingNPCS
				SpawnNPC(Spawner, Id, Amount)
			end
		end
	end
end
SpawnNPCS()

while true do
	for Id, Spawners in Next, Cache.SpawnerData do
		for Spawner, Data in Next, Spawners do
			
			if Clock() - Data.LastUpdate >= Properties.SPAWNER_UPDATE_INTERVAL then
				--| For Displaying NPCS
				for _, Player in Ipairs(Players:GetPlayers()) do
					if isAlive(Player.Character) then
						local InRange = false
						if isWithinRange(Player.Character.HumanoidRootPart.Position, Spawner.Position, Data.LargestScale) then
							
							--| Display NPC's
							for _, NPC in Ipairs(Data.NPCS) do
								if isAlive(NPC.Model) then
									NPC.Model.Parent = Properties.NPC_DIRECTORY
								end
							end
							InRange = true 
							break
						end
						
						if not InRange then
							for _, NPC in Ipairs(Data.NPCS) do
								NPC.Model.Parent = ServerStorage
							end
						end
					end
				end
			end
				
			--| NPC Behavior
			for _, NPC in Ipairs(Data.NPCS) do
				if isAlive(NPC.Model) and NPC.Model:IsDescendantOf(Properties.NPC_DIRECTORY) then
					local Agressive = ((Database[NPC.Id].PassiveAgressive == true) and true or (NPC.Model.Humanoid.Health < NPC.Model.Humanoid.MaxHealth))
					
					if Agressive then
						if Clock() - NPC.LastUpdate >= Properties.NPC_UPDATE_INTERVAL then
							NPC.LastUpdate = Clock()	
							local NearestEnemy = getNearestEnemy(NPC)
							if NearestEnemy then
								if isWithinRange(NearestEnemy.HumanoidRootPart.Position, NPC.Model.HumanoidRootPart.Position, Database[Id].AttackDistance) then
									if Clock() - NPC.LastAttack >= Database[Id].AttackCooldown then
										NPC.LastAttack = Clock()
										NPC:Attack(NearestEnemy)													
									end
								elseif isWithinRange(NearestEnemy.HumanoidRootPart.Position, NPC.Model.HumanoidRootPart.Position, Database[Id].ChaseRange) then
									NPC:Chase(NearestEnemy)
								end
							end						
						end
					end
				end
			end
		end
	end
	Halt(0.25)
end
