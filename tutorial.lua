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

		local page = 1
		local pages = {
			love.graphics.newImage"assets/1.png",
			love.graphics.newImage"assets/2.png",
			love.graphics.newImage"assets/3.png",
			love.graphics.newImage"assets/4.png",
			love.graphics.newImage"assets/5.png",
			love.graphics.newImage"assets/6.png",
			love.graphics.newImage"assets/7.png",
		}

		local function drawFunc()
			love.graphics.draw(pages[page])
		end
		gui.canvases["primary"].drawfunc = drawFunc
		gui.canvases["primary"].enabled = true

	elseif tracker == 1 then
		state = "battle"

		states.battle("tutorial", {
			party1 = player,
			party2 = enemy,
			initTutorial = true
		})

	elseif tracker == 2 then
		-- "Let's try a harder one"
		state = "battle"

		 states.battle("tutorial", {
			party1 = player,
			party2 = enemy2,
		})
	else
		-- TODO: post-game information
	end

end

return tutorial
