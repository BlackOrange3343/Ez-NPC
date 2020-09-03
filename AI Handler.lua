--|| Services ||--
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

PhysicsService:CreateCollisionGroup("Uncollideable NPCS")
PhysicsService:CollisionGroupSetCollidable("Uncollideable NPCS", "Uncollideable NPCS", false)

--|| Modules ||--
local Properties = require(script.Parent.Properties)
local Database = require(script.Parent.Database)

--|| Localise ||--
local Clock = os.clock

local NPC = {}
local NPCS = {}
NPC.__index = NPC

local function SetCollisionGroup(Model, Group)
	for _, Desc in ipairs(Model:GetDescendants()) do
		if Desc:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(Desc, Group)
		end
	end
end

if not Properties.PLAYER_COLLISION then
	Players.PlayerAdded:Connect(function(Player)
		local Character = Player.Character or Player.CharacterAdded:Wait()
		SetCollisionGroup(Player.Character,"Uncollideable NPCS")
		Player.CharacterAdded:Connect(function(Character)
			SetCollisionGroup(Character, "Uncollideable NPCS")
		end)
	end)
end

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

local function GroupLikeNPCS()
	local Directory = Properties.NPC_STORAGE_DIRECTORY
	for NPC, NPCData in next, Database do
		NPCS[NPC] = {}
		for _, Child in ipairs(Directory:GetChildren()) do
			if NPC == Child.Name then
				NPCS[NPC][#NPCS[NPC] + 1] = Child
			end
		end
	end
end
GroupLikeNPCS()

local DataValuesToObject = {
	["number"] = "NumberValue",
	["boolean"] = "BoolValue",
	["string"] = "StringValue"
}

function CreateMiscData(Folder, Table)
	for Index, Value in next, Table do
		if typeof(Value) ~= "table" then
			local NewObject = Instance.new(DataValuesToObject[typeof(Value)])
			NewObject.Name = Index
			NewObject.Value = Value
			NewObject.Parent = Folder
		else
			local NewFolder = Instance.new("Folder")
			NewFolder.Name = Index
			NewFolder.Parent = Folder
			CreateMiscData(NewFolder, Value)
		end
	end
end

function LoadAnimationFromTable(Humanoid, Table1, AnimTable)
	for Index, Value in next, AnimTable do
		if typeof(Value) == "table" then
			Table1[Index] = {}
			LoadAnimationFromTable(Humanoid, Table1[Index], Value)
		else
			local Animation = Instance.new("Animation")
			Animation.AnimationId = Value
			Table1[Index] = Humanoid:LoadAnimation(Animation)	
			Animation:Destroy()
		end	
	end
end

local function CreateNPCModel(Data)
	--| Main Data
	local Id = Data.Id
	local SpawnCFrame = Data.CFrame
	
	local RandomNPC = NPCS[Id][math.random(1, #NPCS[Id])]:Clone()
	local Humanoid = RandomNPC:FindFirstChild"Humanoid"
	
	if not Properties.NPC_COLLISION then
		SetCollisionGroup(RandomNPC, "Uncollideable NPCS")
	end
	
	if Properties.CREATE_MISC_DATA then
		local Folder = Instance.new("Folder")
		Folder.Name = "Data"
		Folder.Parent = RandomNPC
		
		CreateMiscData(Folder, Database[Id].MiscData)
	end
	
	if not Humanoid then
		Debug(RandomNPC:GetFullName().."["..Id.."] does not have a existing Humanoid!", true)
		return
	else
		for State, Value in next, Properties.HUMANOID_STATES do
			Humanoid:SetStateEnabled(State, Value)
		end
		
		for Property, Value in next,Database[Id].HumanoidProperties do
			Humanoid[Property] = Value
		end
		Humanoid.Health = Humanoid.MaxHealth
	end
	
	if not RandomNPC.PrimaryPart then
		Debug(RandomNPC:GetFullName().."["..Id.."] does not have a existing PrimaryPart!", true)
	else
		RandomNPC:SetPrimaryPartCFrame(SpawnCFrame)
	end
	RandomNPC.Parent = ReplicatedStorage
	
	--| Load Animations
	LoadAnimationFromTable(Humanoid, Data.Animations, Database[Id].Animations)
	
	--| Play Idle
	Data.Animations.Idle:Play()
	
	return RandomNPC
end

function NPC.new(Data)
	local Model = CreateNPCModel(Data)
	Data.Model = Model
	return setmetatable(Data, NPC)
end

function NPC:Die()
	if Database[self.Id].Die then
		Database[self.Id].Die(self.Model)
	end
	
	Halt(1)
	self.Model:Destroy()
	NPC.Respawn(self)
end

function NPC:Respawn()
	Halt(Database[self.Id].RespawnTime)
	local NewModel = CreateNPCModel(self)
	self.Model = NewModel
	self.Animations.Idle:Play()
	
	--| Death Event
	local Death, AncestryChanged
	Death = self.Model.Humanoid.HealthChanged:Connect(function(Health)
		if Health <= 0 then
			
			Death:Disconnect()
			Death = nil
			
			AncestryChanged:Disconnect()
			AncestryChanged = nil
			
			self:Die()
		end
	end)
	
	AncestryChanged = self.Model.AncestryChanged:Connect(function(_, Parent)
		if Parent == nil then
			
			AncestryChanged:Disconnect()
			AncestryChanged = nil
			
			Death:Disconnect()
			Death = nil
			
			self:Die()
		end
	end)
end

function NPC:Attack(Target)
	if Database[self.Id].Attack then
		Database[self.Id].Attack(self.Model, Target)
	else
		
		for i = 0, 1, 0.1 do
			self.Model.HumanoidRootPart.CFrame = self.Model.HumanoidRootPart.CFrame:Lerp(CFrame.new(self.Model.HumanoidRootPart.Position, Vector3.new(Target.HumanoidRootPart.Position.X,self.Model.HumanoidRootPart.Position.Y,Target.HumanoidRootPart.Position.Z)), i)
			RunService.Stepped:Wait()
		end
		
		if Target:FindFirstChild"Humanoid" then
			Target.Humanoid:TakeDamage(Database[self.Id].AttackDamage)
			-- If you have a Damage API you can use that instead of line above			
		end
		
		if Database[self.Id].RandomAttack then
			local AttackIndex = math.random(1, #self.Animations.Attack)
			self.Animations.Attack[AttackIndex]:Play()
		else
			self.LastAttackIndex = (self.LastAttackIndex + 1 > #self.Animations.Attack and 1 or self.LastAttackIndex + 1)
			self.Animations.Attack[self.LastAttackIndex]:Play()	
		end
		
		if self.Animations.Chase.IsPlaying then
			self.Animations.Chase:Stop()
		end
	end
end

function NPC:Chase(Target)
	local EndGoal = Target.HumanoidRootPart.Position
	local StartPosition = self.Model.HumanoidRootPart.Position
	local Direction = (EndGoal - StartPosition).Unit
	local NewEndGoal = EndGoal + Direction * Database[self.Id].AttackDistance/2
	self.Model.Humanoid:MoveTo(NewEndGoal, Target.HumanoidRootPart)
	
	if not self.Animations.Chase.IsPlaying then
		self.Animations.Chase:Play()
	end
end

return NPC
