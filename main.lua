--[[
Functions must have a summary of the function's purpose and output (if any).
Ex:
function player_hp_display(cur, max) --Displays player hp to the screen.
	--code here--
end

--]]

local utils = require("src/utils")
local gui = require("src/gui")
local creatures = require("src/creatures")

local states = {
	battle = require("src/states/battle"),
}
state = "battle"

function love.load() --Place initializations here
	math.randomseed(os.time()) -- just to set it up
	w, h, s = 640, 360, 2
	success = love.window.setMode(w*s, h*s, {} )

	tutorial = true

	player = creatures.getCreature("player")
	enemy = creatures.getCreature("pentagon")
	enemy2 = creatures.getCreature("pentavian")
	
	states.battle("", {
		party1 = player,
		party2 = enemy2,
	})
end

--[[ --TODO: rescale-friendly UI
function love.window.resize(w, h)
	gui.canvases.redraw()
end
]]
function love.draw()
	gui.canvases.draw()
	--XXX: Debug
	--({}) -> ""
	function tts(x, depth)
		depth = depth or ""
		ret = ""
		for k, v in next, x do
			ret = ret.."\n"..depth.."["..tostring(k).."]: "..(type(v) == "table" and tts(v, depth.."\t") or v == nil and "nil" or tostring(v))
		end
		ret = #ret == 0 and "{}" or ret
		return ret
	end
	-- note: best seems not to work
	-- love.graphics.print(tts(party2.knownMoveCombos), X(0), 0)
	-- love.graphics.print(tts(party1.knownMoveCombos), 0, 0)
end

function love.update(dt) --currently handles all GUI interfacing (other than the function below)
	gui.mouse_events.iter(state, love.mouse.getX(), love.mouse.getY())
end

function love.mousepressed(x, y, button, istouch)
	if button >= 1 then
		gui.mouse_events.iter(state, x, y, true)
	end
end
