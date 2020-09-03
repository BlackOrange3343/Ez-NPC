--|| Services ||--
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

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
			NewObject.Parent = Folder
		else
			local NewFolder = Instance.new("Folder")
			NewFolder.Name = Index
			NewFolder.Parent = Folder
			CreateMiscData(NewFolder, Value)
		end
	end
end

function LoadAnimationFromTable(Humanoid, Animation, Table1, AnimTable)
	for Index, Value in next, AnimTable do
		if typeof(Value) == "table" then
			Table1[Index] = {}
			LoadAnimationFromTable(Humanoid, Animation, Table1[Index], Value)
		else
			Animation.AnimationId = Value
			Table1[Index] = Humanoid:LoadAnimation(Animation)			
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
		
		for Property, Value in ipairs(Database[Id].HumanoidProperties) do
			Humanoid[Property] = Value
		end
	end
	
	if not RandomNPC.PrimaryPart then
		Debug(RandomNPC:GetFullName().."["..Id.."] does not have a existing PrimaryPart!", true)
	else
		RandomNPC:SetPrimaryPartCFrame(SpawnCFrame)
	end
	
	--| Death Event
	local Death, AncestryChanged
	Death = RandomNPC.Humanoid.Died:Connect(function()
		Death:Disconnect()
		Death = nil
		NPC:Die()
	end)
	
	AncestryChanged = RandomNPC.AncestryChanged:Connect(function(_, Parent)
		if Parent == nil then
			AncestryChanged:Disconnect()
			AncestryChanged = nil
			NPC:Die()
		end
	end)
	RandomNPC.Parent = Properties.NPC_DIRECTORY
	
	--| Load Animations
	local Animation = Instance.new("Animation")
	Animation.AnimationId = ""
	LoadAnimationFromTable(Humanoid, Animation, Data.Animations, Database[Id].Animations)
	Animation:Destroy()
	
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
	self:Respawn()	
end

function NPC:Respawn()
	Halt(Database[self.Id].RespawnTime)
	local NewModel = CreateNPCModel(self)
	self.Model = NewModel	
end

function NPC:Attack(Target)
	if Database[self.Id].Attack then
		Database[self.Id].Attack(self.Model, Target)
	else
		if Target:FindFirstChild"Humanoid" then
			Target.Humanoid:TakeDamage(Database[self.Id].AttackDamage)
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
