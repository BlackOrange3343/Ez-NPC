local ServerStorage = game.ServerStorage
local Workspace = game.Workspace

--[[

Make sure to have a Part as a "Spawner" for the npcs, they will spawn under neath the part.
You want to add a model or folder in workspace then give it a unique name. After that
you want to add model or folder again in that model or folder and give that the name of
the npc it's responsible for spawning. Once you've done that you can just put parts
in the folder / model and npcs will spawn where the part is at. Put above ground level.

NPC DIRECTORY is for where all the npcs are stored.

]]

local Properties = {
	
	DEBUG = false,
	
	NPC_UPDATE_INTERVAL = 0.5,
	SPAWNER_UPDATE_INTERVAL = 3,
	
	NPC_SPAWNER_DIRECTORY = Workspace.Visuals.Spawners,  -- Where spawners are at
	NPC_STORAGE_DIRECTORY = ServerStorage.NPCS, -- Where Models are stored
	NPC_DIRECTORY = Workspace.Entities, -- Where Active NPC's Are at
	
	CREATE_MISC_DATA = true, -- This is preferred on false bubt can be set to true for thos who wish to have it on true
	NPC_COLLISION = false, -- This is preferred on false
	PLAYER_COLLISION = false, -- This is preferred on false
	
	HUMANOID_STATES = { -- Put humanoid states you don't want in here
		--[Enum.HumanoidStateType.Climbing] = true,
		--[Enum.HumanoidStateType.Dead] = true,
		--[Enum.HumanoidStateType.FallingDown] = true,
		--[Enum.HumanoidStateType.Freefall] = true,
		--[Enum.HumanoidStateType.Flying] = true,
		--[Enum.HumanoidStateType.GettingUp] = true,
		--[Enum.HumanoidStateType.Jumping] = true,
		--[Enum.HumanoidStateType.Landed] = true,
		--[Enum.HumanoidStateType.Physics] = true,
		--[Enum.HumanoidStateType.PlatformStanding] = true,
		--[Enum.HumanoidStateType.Ragdoll] = true,
		--[Enum.HumanoidStateType.Running] = true,
		--[Enum.HumanoidStateType.RunningNoPhysics] = true,
		--[Enum.HumanoidStateType.Seated] = true,
		--[Enum.HumanoidStateType.StrafingNoPhysics] = true,
		--[Enum.HumanoidStateType.Swimming] = true,
	}
	
}

return Properties
