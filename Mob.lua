math.randomseed(os.clock());
--|| Services ||--
local PhysicsService = game:GetService("PhysicsService")

--|| Modules ||--
local Config = require(script.Parent.Config);
local MobData = require(script.Parent.MobData);

local Mob = {};
local MobCount = 0;
Mob.__index = Mob;

--|| Private Functions
local function OnDeath(Mob, Connections)
	for i = 1, #Connections do
		Connections[i] = Connections[i] and Connections[i]:Disconnect();
	end
	Connections = nil
	wait(MobData[Mob.Name].RespawnTime)
	if MobData[Mob.Name].Death then
		MobData[Mob.Name].Death(Mob);
		if Mob.Model then
			Mob.Model:Destroy()
		end
	end
	Mob:Respawn()
end

local function ConnectDeathEvent(Mob)
	local Connections = {};
	
	Connections[#Connections + 1] = Mob.Model.AncestryChanged:Connect(function(_, Parent)
		if Parent == nil then
			OnDeath(Mob, Connections)
		end
	end)
	
	Connections[#Connections + 1] = Mob.Model.Humanoid.HealthChanged:Connect(function()
		if Mob.Model.Humanoid.Health == 0 then
			OnDeath(Mob, Connections)
		end
	end)
end

local Datatypes = {
	["string"] = "StringValue",
	["boolean"] = "BoolValue",
	["CFrame"] = "CFrameValue",
	["Color3"] = "Color3Value",
	["Vector3"] = "Vector3Value",
	["BrickColor"] = "BrickColorValue",
	["number"] = "NumberValue",
	["Instance"] = "ObjectValue",
	
}

local function ObjectifyTable(Parent, Table)
	for Index, Value in next, Table do
		if typeof(Value) == "table" then
			local Folder = Instance.new("Folder");
			Folder.Name = Index;
			Folder.Parent = Parent;
			ObjectifyTable(Folder, Value);
		else
			local NewValue = Instance.new(Datatypes[typeof(Value)]);
			NewValue.Value = Value;
			NewValue.Name = Index;
			NewValue.Parent = Parent;
		end
	end
end

local function Copy(Table)
	local NewTable = {}
	for Index, Value in next, Table do
		if typeof(Value) == "table" then
			NewTable[Index] = Copy(Value);	
		else			
			NewTable[Index] = Value;
		end
	end
	return NewTable;
end

local function SetCollisionGroup(Model, Group)
	if Model:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(Model, Group);
	else
		local ModelDescendants = Model:GetDescendants()
		for i = 1, #ModelDescendants do
			local Model = ModelDescendants[i];
			if Model:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(Model, Group);
			end
		end
	end
end

local function LoadAnimationsInto(Animator, Table, Data)
	for Key, Value in next, Data do
		if typeof(Value) == "table" then
			Table[Key] = {};
			LoadAnimationsInto(Animator, Table[Key], Value);
		else
			local Animation = Instance.new("Animation");
			Animation.AnimationId = Value;
			Table[Key] = Animator:LoadAnimation(Animation);
			Animation:Destroy();
		end
	end
end

function Mob.new(Id, CF)
	local Data = {};
	
	--| Error Fetching
	if type(Id) ~= "string" then warn(script.Name, "Mob Id was not passed as a string;", Id) return end;
	if not MobData[Id] then warn(script.Name, "Was unable to locate ", Id, " in MobData", MobData) end;
	if not Config.Hiearchy:FindFirstChild(Id) then warn(script.Name, "Unable to locate spawners folder for ", Id) end;
	
	--| Selecting the NPC
	local AvailableNPCS = Config.Storage:GetChildren()
	local FilteredNPCS = {};
	local TableIndex = 0;
	for i = 1, #AvailableNPCS do
		if AvailableNPCS[i].Name == Id then
			TableIndex += 1;
			FilteredNPCS[TableIndex] = AvailableNPCS[i];
		end
	end
	if TableIndex == 0 then warn(script.Name, "No models found for", Id, " in storage unit") return end;
	local RandomIndex = math.random(1, #FilteredNPCS);
	if not FilteredNPCS[RandomIndex].PrimaryPart or not FilteredNPCS[RandomIndex]:FindFirstChild"Humanoid" then warn(script.Name, "No Humanoid or PrimaryPart for ", FilteredNPCS[RandomIndex], Id) return end;
	if not FilteredNPCS[RandomIndex].Humanoid:FindFirstChild"Animator" then 
		local Animator = Instance.new("Animator")
		Animator.Parent = FilteredNPCS[RandomIndex].Humanoid;
	end
	local Model = FilteredNPCS[RandomIndex]:Clone();
	Model:SetPrimaryPartCFrame(CF);
	Model.Parent = Config.SpawnHiearchy or game.Workspace;
	
	--| Property Updates;
	local ModelDescendants = Model:GetDescendants()
	for i = 1, #ModelDescendants do
		local Object = ModelDescendants[i];
		if Object:IsA("BasePart") then
			Object.Anchored = false;
			Object.CastShadow = MobData[Id].CastShadow;
		end
	end
	
	Model.Humanoid.MaxHealth = MobData[Id].Health;
	Model.Humanoid.Health = Model.Humanoid.MaxHealth;
	Model.Humanoid.WalkSpeed = MobData[Id].WalkSpeed;
	Model.Humanoid.JumpPower = MobData[Id].JumpPower;
	
	--| Adding Assets
	local BodyGyro = Instance.new("BodyGyro");
	BodyGyro.MaxTorque = Vector3.new(0,0,0) * 50000;
	BodyGyro.D = 150;
	BodyGyro.P = 2500;
	BodyGyro.Name = "Rotater";
	BodyGyro.Parent = Model.PrimaryPart;
	
	--| No Collision
	if Config.MobCollide == false then
		SetCollisionGroup(Model, "Mystifine")
	end
	
	--| Disabling States For Optimization
	for State, Value in next, Config.HumanoidStates do
		Model.Humanoid:SetStateEnabled(State, Value)
	end
	
	--| Loading the Animations Into The Model;
	Data.Animations = {};
	local Animations = MobData[Id].Animations or {}
	LoadAnimationsInto(Model.Humanoid.Animator, Data.Animations, Animations);
	Data.Animations.Idle:Play(); --> Play Idle Animations
	
	--| Extra Data;
	if MobData[Id].ObjectifyData then
		local Folder = Instance.new("Folder");
		Folder.Name = "Data";
		Folder.Parent = Model;
		ObjectifyTable(Folder, MobData[Id].Data);
	end
	
	Data.Data = Copy(MobData[Id].Data);
	Data.LastUpdate = os.clock();
	Data.CFrame = CF;
	Data.Name = Id;
	Data.LastAttack = os.clock();
	Data.LastAttackIndex = 0;
	Data.Model = Model;
	MobCount += 1;
	Data.Id = tostring(MobCount); 
	
	--| Death Connections;
	local MobObject = setmetatable(Data, Mob);
	ConnectDeathEvent(MobObject);
	
	return MobObject;
end

function Mob:Respawn()
	self = Mob.new(self.Name, self.CFrame);
end


return Mob
