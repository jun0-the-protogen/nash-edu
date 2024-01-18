-- A wrapper state, indicating that the tutorial is running.
local drawBuf = {}
local tracker = 0

function tutorial(prevState, params)
	local creatures = params.creatures
	local states = params.states

	state = "tutorial"

	player = creatures.getCreature("demoPlayer")
	enemy = creatures.getCreature("demoPentagon")

	if tracker == 0 then

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

		gui.mouse_events(X(80), Y(-40),
			-- Collider
			function(x, y, cx, cy)
					return cx > x and cx < x + S(100) and cy > y and cy < y + S(100)
			end,

			-- On hover
			function()
					drawBuf[#drawBuf + 1] = function()
							love.graphics.setColor(1, 1, 1, 0.3)
							love.graphics.rectangle("fill", X(80), Y(-40), S(100), S(100))
					end
			end,

			-- On click
			function()
					page = page - (page > 1 and 1 or 0)
			end,
			"tutorial"
		)

		gui.mouse_events(X(180), Y(-40),
			-- Collider
			function(x, y, cx, cy)
					return cx > x and cx < x + S(100) and cy > y and cy < y + S(100)
			end,

			-- On hover
			function()
					drawBuf[#drawBuf + 1] = function()
							love.graphics.setColor(1, 1, 1, 0.3)
							love.graphics.rectangle("fill", X(180), Y(-40), S(100), S(100))
					end
			end,

			-- On click
			function()
					page = page + (page <= #pages and 1 or 0)
			end,
			"tutorial"
		)

		-- raw drawing because of time crunch, TODO: improve
		local function drawFunc()
			if page <= #pages then
					for _, v in ipairs(drawBuf) do
						v()
					end
					drawBuf = {function()
							love.graphics.draw(pages[page])

							love.graphics.setColor(0.4, 0.4, 0.4, 0.4)
							love.graphics.rectangle("fill", X(80), Y(-40), S(100), S(100))
							love.graphics.rectangle("fill", X(180), Y(-40), S(100), S(100))

							love.graphics.setColor(0.6, 0.6, 0.6, 0.6)
							love.graphics.rectangle("fill", X(80 + 2), Y(-40 - 2), S(100 - 4), S(100 - 4))
							love.graphics.rectangle("fill", X(180 + 2), Y(-40 - 2), S(100 - 4), S(100 - 4))

							love.graphics.setColor(0.75, 0.75, 0.75, 1)
							love.graphics.polygon("fill", X(100), Y(-90), X(160), Y(-60), X(160), Y(-120))
							love.graphics.polygon("fill", X(260), Y(-90), X(200), Y(-60), X(200), Y(-120))
					end}
			else
					-- self-deconstructing!
					gui.canvases["primary"].drawFunc = nil
					gui.canvases["primary"].enabled = false

					gui.mouse_events.clear("tutorial")

					tracker = tracker + 1
					states.tutorial(prevState, params)
			end

		end

		gui.canvases["primary"].drawfunc = drawFunc
		gui.canvases["primary"].enabled = true

	elseif tracker == 1 then
		state = "battle"

		player = states.battle(state, {
			party1 = player,
			party2 = enemy,
			deinitCallback = function()
				state = "tutorial"
				drawBuf = {}

				local page = 1
				local pages = {
					love.graphics.newImage"assets/n1.png",
					love.graphics.newImage"assets/n2.png",
					love.graphics.newImage"assets/n3.png",
				}

				gui.mouse_events(0, 0,
					-- Collider
					function(x, y, cx, cy)
							return cx > x and cx < x + S(100)
					end,

					-- On hover
					function()
							drawBuf[#drawBuf + 1] = function()
									love.graphics.setColor(1, 1, 1, 0.3)
									love.graphics.rectangle("fill", 0, 0, S(20), 720)
							end
					end,

					-- On click
					function()
							page = page - (page > 1 and 1 or 0)
					end,
					"tutorial"
				)

				gui.mouse_events(X(270), 0,
					-- Collider
					function(x, y, cx, cy)
							return cx > x and cx < x + S(100)
					end,

					-- On hover
					function()
							drawBuf[#drawBuf + 1] = function()
									love.graphics.setColor(1, 1, 1, 0.3)
									love.graphics.rectangle("fill", 1280 - S(20), 0, S(50), 720)
							end
					end,

					-- On click
					function()
							page = page + (page <= #pages and 1 or 0)
					end,
					"tutorial"
				)

				-- raw drawing because of time crunch, TODO: improve
				local function drawFunc()
					if page <= #pages then
							for _, v in ipairs(drawBuf) do
								v()
							end
							drawBuf = {function()
									love.graphics.draw(pages[page])

									love.graphics.setColor(0.4, 0.4, 0.4, 0.4)
									love.graphics.rectangle("fill", 0, 0, S(20), 720)
									love.graphics.rectangle("fill", X(300), 0, S(2), 720)

									love.graphics.setColor(0.6, 0.6, 0.6, 0.6)
									love.graphics.rectangle("fill", S(2), S(2), S(20 - 4), 720 - S(4))
									love.graphics.rectangle("fill", X(300 + 2), S(2), S(20 - 4), 720 - S(4))

									love.graphics.setColor(0.75, 0.75, 0.75, 1)
									love.graphics.polygon("fill", S(6), Y(0), S(14), Y(-3), S(14), Y(3))
									love.graphics.polygon("fill", 1280 - S(14), Y(-3), 1280 - S(14), Y(3), 1280 - S(6), Y(0))
							end}
					else
							gui.canvases["primary"].drawFunc = nil
							gui.canvases["primary"].enabled = false
							love.event.quit()
					end

				end

				gui.canvases["primary"].drawfunc = drawFunc
				gui.canvases["primary"].enabled = true
			end
		})
	end
end

return tutorial
