-- A wrapper state, indicating that the tutorial is running.

function tutorial(prevState, params)
	local creatures = params.creatures
	local states = params.states

	-- TODO: pre-game instructions

	state = "battle"

	player = creatures.getCreature("player")
	enemy = creatures.getCreature("demoPentagon")
	enemy2 = creatures.getCreature("pentagon")

	states.battle("tutorial", {
		party1 = player,
		party2 = enemy,
		initTutorial = true
	})

	-- "Let's try a harder one"

	state = "battle"

	-- states.battle("tutorial", {
	--	party1 = player,
	--	party2 = enemy2,
	--})

	-- TODO: post-game information
end

return tutorial