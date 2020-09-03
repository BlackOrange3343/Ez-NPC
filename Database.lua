local Database = {
	Dummy = {
		HumanoidProperties = { -- Put any humanoid properties you want set in here
			WalkSpeed = 18,
			JumpPower = 50,
			MaxHealth = 500, -- Make sure to put MaxHealth before Health
			Health = 500,
		},
		
		MiscData = { -- This is data for your own game

		},
		
		--| Other Essential Data
		AttackDistance = 5,
		AttackCooldown = 1,
		ChaseRange = 50,
		AttackDamage = 10,
		RespawnTime = 10,
		PassiveAgressive = true,
		Quantity = 10, -- Per Spawner
		Animations = {
			Idle = "rbxassetid://05051775001",
			Chase = "rbxassetid://05051979913",
			Attack = {"rbxassetid://5153989112", "rbxassetid://5153964818", "rbxassetid://5134956506", "rbxassetid://5153991114"},
		},
		RandomAttack = false, -- If false it will iterate in order
		
		--[[
		
		If you want a custom attack function list make a index called Attack with a function
		
		]]
		--Attack = function(NPC, Target) -- This would have custom attack
			
		--end,
		--Die = function(NPC) -- This would have a custom death
			
		--end,
		
	}
}

return Database
