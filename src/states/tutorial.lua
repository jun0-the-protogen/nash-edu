-- A wrapper state, indicating that the tutorial is running.

function tutorial(prevState, params)
	local creatures = params.creatures
	local states = params.states

	local tracker = 0

	player = creatures.getCreature("player")
	enemy = creatures.getCreature("demoPentagon")
	enemy2 = creatures.getCreature("pentagon")

	if tracker == 0 then
		-- TODO: pre-game instructions
	elseif tracker === 1 then
		state = "battle"

		states.battle("tutorial", {
			party1 = player,
			party2 = enemy,
			initTutorial = true
		})

	elseif tracker == 2 then
		-- "Let's try a harder one"
		 states.battle("tutorial", {
			party1 = player,
			party2 = enemy2,
		})
	else
		-- TODO: post-game information
	end

end

return tutorial
