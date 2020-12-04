--|| Services ||--
local ReplicatedStorage = game.ReplicatedStorage
local Players = game.Players
local PhysicsService = game:GetService("PhysicsService")
PhysicsService:CreateCollisionGroup("Mystifine")
PhysicsService:CollisionGroupSetCollidable("Mystifine", "Mystifine", false)

--|| Modules ||--
local Config = require(script.Config);
local Mob = require(script.Mob);
local MobData = require(script.MobData);
local SpawnerCache = {};
local MobCache = {};

--| Private Functions
local function GetClosestTarget(Position, Range)
	local Closest
	local PlayerList = Players:GetPlayers();
	for i = 1, #PlayerList do
		local Player = PlayerList[i];
		local Character = Player.Character
		if Character and Character.PrimaryPart and Character:FindFirstChild"Humanoid" and Character.Humanoid.Health > 0 then
			local Distance = (Character.PrimaryPart.Position - Position).Magnitude
			Closest = not Closest and {Character, Distance} or Distance < Closest[2] and {Character, Distance};
		end
	end
	
	if Closest and Closest[2] < Range then
		return Closest[1], Closest[2];
	end
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

local function PlayerInRange(Point, Range)
	local PlayerList = Players:GetPlayers();
	for i = 1, #PlayerList do
		local Player = PlayerList[i];
		local Character = Player.Character
		if Character and Character.PrimaryPart then
			local Distance = (Point - Character.PrimaryPart.Position).Magnitude
			if Distance <= Range then
				return true
			end
		end
	end
	return false;
end

function Cast(Orgin, Goal, Data, FilterType, IgnoreWater)
	local StartPosition = Orgin
	local EndPosition = Goal
	local Difference = EndPosition - StartPosition
	local Direction = Difference.Unit
	local Distance = Difference.Magnitude
	
	local RayData = RaycastParams.new()
	RayData.FilterDescendantsInstances = Data or {}
	RayData.FilterType = FilterType or Enum.RaycastFilterType.Blacklist
	RayData.IgnoreWater = IgnoreWater or true
	
	return workspace:Raycast(StartPosition, Direction * Distance, RayData)
end

--| Load In NPC's
if not Config.Hiearchy then warn(script.Name, "Hiearchy/Folder for spawners has not been set.") return end;
local Spawners = Config.Hiearchy:GetChildren();
for i = 1, #Spawners do
	local Folder = Spawners[i];
	local Identification = Folder.Name;
	SpawnerCache[Folder] = {};
	MobCache[Folder] = {};
	local Children = Folder:GetChildren();
	for i = 1, #Children do
		local Spawner = Children[i];
		SpawnerCache[Folder][Spawner] = 0;
		MobCache[Folder][Spawner] = {};
		for i = 1, MobData[Identification].SpecifiedQuantity[Spawner] or MobData[Identification].Quantity do
			local RandomVector = Spawner.Position + Vector3.new( math.random(-Spawner.Size.X/2, Spawner.Size.X/2), 0,  math.random(-Spawner.Size.Z/2, Spawner.Size.Z/2));
			local Result = Cast(RandomVector, RandomVector - Vector3.new(0,1000,0), {Config.Hiearchy, Config.SpawnHiearchy}, Enum.RaycastFilterType.Blacklist);
			
			if Result then
				local NPC = Mob.new(Identification, CFrame.new(Result.Position) * CFrame.fromEulerAnglesXYZ(0,math.random(-360,360),0));
				MobCache[Folder][Spawner][NPC.Id] = NPC;
			end
		end
	end
end

--| Disables collision between players
if Config.PlayerCollide == false then
	Players.PlayerAdded:Connect(function(Player)
		local Character = Player.Character or Player.CharacterAdded:Wait()
		SetCollisionGroup(Character, "Mystifine");
		Player.CharacterAdded:Connect(function(Character)
			SetCollisionGroup(Character, "Mystifine");
		end)
	end)
end

while true do
	for Category, Spawners in next, MobCache do
		for Spawner, NPCS in next, Spawners do
			for _, Mob in next, NPCS do
				local InRange = PlayerInRange(Spawner.Position, MobData[Category.Name].SpecifiedHideRange[Spawner] or MobData[Category.Name].NPCHideRange)
				if not InRange then
					--| Reparent to ReplicatedStorage;
					Mob.Model.Parent = game.ReplicatedStorage;
				elseif InRange then
					Mob.Model.Parent = Config.SpawnHiearchy or game.Workspace;
				end
				
				if os.clock() - Mob.LastUpdate >= 0.25 and (MobData[Mob.Name].Agressive or Mob.Model.Humanoid.Health < Mob.Model.Humanoid.MaxHealth) then
					--| Calculate against players
					Mob.LastUpdate = os.clock();
					
					local Target, Distance = GetClosestTarget(Mob.Model.PrimaryPart.Position, MobData[Mob.Name].SeekRange);
					if Target then
						--| Chase Target
						if Distance <= MobData[Mob.Name].AttackRange and os.clock() - Mob.LastAttack >= MobData[Mob.Name].AttackSpeed then
							Mob.Model.PrimaryPart.Rotater.CFrame = CFrame.new(Mob.Model.PrimaryPart.Position, Target.PrimaryPart.Position);
							Mob.Model.PrimaryPart.Rotater.MaxTorque = Vector3.new(0,1,1) * 50000;
							
							Mob.Animations.Walk:Stop(); 
							
							--> Attack;
							if MobData[Mob.Name].Attack then
								MobData[Mob.Name].Attack(Mob, Target);
							else
								--| Default Attack
								Target.Humanoid:TakeDamage(MobData[Mob.Name].Damage);
								if MobData[Mob.Name].AttackSequence == "RNG" then
									local RandomAnimation = Mob.Animations.Attack[math.random(1, #Mob.Animations.Attack)];
									RandomAnimation:Play();
								elseif MobData[Mob.Name].AttackSequence == "LIST" then
									Mob.LastAttackIndex += 1;
									if Mob.LastAttackIndex >= #Mob.Animations.Attack then
										Mob.LastAttackIndex = 1;
									end
									local Animation = Mob.Animations.Attack[Mob.LastAttackIndex]
									Animation:Play();
								end
							end
							Mob.LastAttack = os.clock();
						else
							--> Chase;
							if not Mob.Animations.Walk.IsPlaying then Mob.Animations.Walk:Play() end;
							Mob.Model.Humanoid:MoveTo(Target.PrimaryPart.Position, Target.PrimaryPart);
							
							--> Update BodyGyro;
							Mob.Model.PrimaryPart.Rotater.CFrame = CFrame.new(Mob.Model.PrimaryPart.Position, Target.PrimaryPart.Position);
							Mob.Model.PrimaryPart.Rotater.MaxTorque = Vector3.new(0,1,1) * 50000;
						end
					else
						Mob.Model.PrimaryPart.Rotater.MaxTorque = Vector3.new(0,0,0);
					end
				end	
			end
		end
	end
	wait()
end
