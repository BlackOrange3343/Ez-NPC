local module = {}

module.Dummy = {
	--| Stats	
	Health = 100,
	WalkSpeed = 16,
	JumpPower = 50,
	
	--| Damage Data
	Damage = 10,
	AttackSpeed = 1,
	AttackRange = 3,
	
	--| Agression Chase Behavior;
	Agressive = false, 
	SeekRange = 30, -- In Studs,
	
	--| Animations
	Animations = {
		Idle = "rbxassetid://5051775001",
		Walk = "rbxassetid://5051979913",
		Attack = {"rbxassetid://5153989112", "rbxassetid://5153964818", "rbxassetid://5134956506", "rbxassetid://5153991114"},
	}, -- Feel free to add more, however, the default ones must stay
	AttackSequence = "RNG", -- RNG or LIST, RNG by Default.
	
	--| Other Data
	CastShadow = true, -- Want to create shadows or not, good for optimization
	NPCHideRange = 150, -- For Optimization, you can specifiy specific hie ranges for spawners below;
	SpecifiedHideRange = {}, -- same as specified quantity
	RespawnTime = 10,
	Quantity = 2, -- Quantity Per Spawner;
	SpecifiedQuantity = {}, --[[ Specify quantity for specific spawners.
		SpecifiedQuantity = {
			[game.Workspace.Spawners.Dummy.SpawnerNearForest] = 20, -- Exaample
		}
	]]
	Data = {
		Example = "Hi!",
		StackedExampled = {
			StatsBro = 5,
			ACFrame = CFrame.new(0,0,0),
		}
	}, -- Additional Information Can Be Provided;
	ObjectifyData = true, -- If True, will create a folder with data within the npc, else refer to tables.
	
	--| Additional Customization
	--Attack = function()
		
	--end,
	--Death = function()
		
	--end,
}

return module
