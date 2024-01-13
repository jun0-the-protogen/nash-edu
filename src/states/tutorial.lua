-- A wrapper state, indicating that the tutorial is running.

function tutorial(prevState, params)
	local creatures = params.creatures
	local states = params.states

	local battle = 1

	-- TODO: pre-game instructions

	state = "battle"

	player = creatures.getCreature("player")
	enemy = creatures.getCreature("demoPentagon")
	enemy2 = creatures.getCreature("pentagon")

	if battle == 1 then
		states.battle("tutorial", {
			party1 = player,
			party2 = enemy,
			initTutorial = true
		})

	else -- "Let's try a harder one"
		 states.battle("tutorial", {
			party1 = player,
			party2 = enemy2,
		})
	end

	-- TODO: post-game information
end

return tutorial
