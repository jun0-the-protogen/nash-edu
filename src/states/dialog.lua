local lines = {}
local drawBuf = {} -- table of drawable functions, perhaps?

local function initDialog(prevState, params)
	lines = params.lines -- Retrieved from a table. Refers to dialog sprites.
	
	gui.canvases(0, 0, WinWidth(), WinHeight(), 60, "dialog")
	gui.canvases["dialog"].enabled = true
	gui.canvases["dialog"].color = {0, 0, 0, 0.25} -- To differentiate between playfield and characters.
	gui.canvases["dialog"].enabled = true
	gui.canvases["dialog"].drawFunc = function()
		love.graphics.clear()
		love.graphics.setBlendMode("alpha", "premultiplied")
		-- TODO: what goes here
		love.graphics.setBlendMode("alpha")
		drawbuf = {}
	end
end

return initDialog
