--[[
Functions must have a summary of the function's purpose and output (if any).
Ex:
function player_hp_display(cur, max) --Displays player hp to the screen.
	--code here--
end

--]]

local gui = require("src/gui")
local creatures = require("src/creatures")

local states = {
	tutorial = require("src/states/tutorial"),
	battle = require("src/states/battle"),
}
state = "main"

function love.load() --Place initializations here
	math.randomseed(os.time()) -- just to set it up
	w, h, s = 640, 360, 2
	success = love.window.setMode(w*s, h*s, {} )

	tutorial = true --TODO
	
	states.tutorial("main", {
		creatures = creatures,
		states = states,
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
	-- love.graphics.print(tts(party2.moves), X(0), 0)
	-- love.graphics.print(tts(party1.moves), 0, 0)
end

function love.update(dt) --currently handles all GUI interfacing (other than the function below)
	gui.mouse_events.iter(state, love.mouse.getX(), love.mouse.getY())
end

function love.mousepressed(x, y, button, istouch, presses)
	if button == 1 then
		gui.mouse_events.iter(state, x, y, true, presses)
	end
end
