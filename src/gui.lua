gui = {}

function X(x)
	return love.graphics.getWidth() / 2 + x * 2
end
function Y(y)
	return love.graphics.getHeight() / 2 - y * 2
end
function S(s)
	return s * 2
end
function WinWidth()
	return S(640)
end
function WinHeight()
	return S(360)
end

--A list of canvases to draw to the screen, ordered as layers, where the draw order is bottom to top.
gui.canvases = {}

--Canvas list methods (see metatables in lua docs)
local canvases_mt = {
	
	--Custom metamethods
	__index = function(self, k)
		local function clear() self = {} end
		local function draw()
			local i
			for i=0, 1000 do
				local canvas = rawget(self, i)
				if canvas and canvas.enabled then
					if canvas.drawfunc then
						love.graphics.setCanvas(canvas.c)
						canvas.drawfunc()
						love.graphics.setCanvas()
					end
					love.graphics.setColor(canvas.color)
					love.graphics.draw(canvas.c, canvas.x, canvas.y)
				end
			end
		end
		--Clears the canvas_list. Uses the gc to remove the previus table.
		if k == "clear" then
			return clear
		--Draws the canvas list to the current screen.
		elseif k == "draw" then
			return draw
		end

		return self[k]
	end,

	__newindex = function(self, k, v)
		if k == "clear" or k == "draw" then
			assert("The name "..k.." is already in use. Please use a different name for the layer.")
		else
			rawset(self, k, v)
		end
	end,

	-- Counts the integer pairs of the 
	__len = function(self)
		if self[1] == nil then return 0 end
		r = 0
		for k, v in ipairs(self) do r = r + 1 end
		return r
	end,

	-- Instantiates a new Canvas at the top layer (if order is not specified). Names are used to access the canvas after its creation and after the destruction of local references in functions.
	__call = function(self, x, y, w, h, order, name)
		if order == nil or (type(order) ~= "number") then
			order = #self + 1
		end
		if order < 0 or order > 1000 then
			assert("Error: Invalid canvas order. Order must be between 0 and 1000 after collision checks")
		end
		order = math.floor(order)
		local element = {
			c = love.graphics.newCanvas(w, h),
			x = x,
			y = y,
			drawfunc = nil,
			enabled = true,
			color = {1, 1, 1, 1},
		}
		table.insert(self, order, element)
		if name then self[name] = self[order] end
		return element
	end,
	__metatable = true
}

setmetatable(gui.canvases, canvases_mt)
-- Stores all current hoverable/clickable objects. TODO: Currently, all buttons are being checked by priority, however, there needs to be more extendability, and a faster search is ideal.
gui.mouse_events = {}

local mouse_events_mt = {

	--Custom metamethods
	__index = function(self, k)
		local function clear(index)
				if index then self[index] = {}
				else self = {} end
		end
		local function iter(state, cx, cy, click, presses)
			if click == nil then click = false end
			local i
			if self[state] then
				for i=0, 1000 do
					local button = rawget(self, state)[i]
					if button then
						if button.collider(button.x, button.y, cx, cy) then
							if click then
								button.click(presses)
							else
								button.hover()
							end
							return true --shortcirciut, and for debug purposes TODO: passthrough
						end
					end
				end
			end
		end
		--Clears the mouse_events list. Uses the gc to remove the previous table.
		if k == "clear" then
			return clear
		--Iterates over all buttons and checks for mouse hovering and clicking.
		elseif k == "iter" then
			return iter
		end

		return rawget(self, k)
	end,

	__newindex = function(self, k, v)
		if k == "clear" or k == "iter" then
			assert("The name "..k.." is already in use. Please use a different name for the button.")
		else
			rawset(self, k, v)
		end
	end,

	--Entry format: {x, y, collider = collision hitbox(x, y, cx, cy), on_hover, on_click}
	__call = function(self, x, y, collider, on_hover, on_click, state, order, name)
		if order == nil or (type(order) ~= "number") then
			order = #self + 1
		end
		if order < 0 or order > 1000 then
			assert("Error: Invalid canvas order. Order must be between 0 and 1000 after collision checks")
		end
		order = math.floor(order)
		local element = {
			x = x,
			y = y,
			collider = collider,
			hover = on_hover,
			click = on_click,
		}
		if not rawget(self, state) then rawset(self, state, {}) end
		table.insert(rawget(self, state), order, element)
		if name then self[name] = self[state][order] end
		return element
	end,
	__metatable = true
} 

setmetatable(gui.mouse_events, mouse_events_mt)

--[[
function gui.choice_diamond_base(player_state, enemy, x, y, w, h, s, base_c, detail_c) --Generates the UI diamond and draws it to the current canvas; (x, y) is the top-left corner and (w, h) is the bottom right corner of the bounding square of the diamond.
	
	--Pops current color to push back after operation.
	r, g, b, a = love.graphics.getColor()

	mid_x, mid_y = (x * 2 + w) / 2, (y * 2 + h) / 2
	
	--Drawing base diamond
	love.graphics.setColor(base_c)
	love.graphics.polygon("fill", x, mid_y, mid_x, y, x+w, mid_y, mid_x, y+h)

	--TODO: Drawing rectangles to represent move pairs in the diamond
	
	
	love.graphics.setColor(r, g, b, a)
end

function gui.init_battle_ui(player_state, enemy, w, h, s) --Initializes the battle ui.
	canvas_list.clear()
	local ui_bottom_bg = canvas_list(0, h - math.floor(h/3) * s, w, h)
	love.graphics.setCanvas(ui_bottom_bg)
	gui.choice_diamond_base(player_state, enemy, math.floor((w - h)/2), 0, h, h, s, {0.4, 0.4, 0.4, 1}, {0.5, 0.5, 0.5, 1})
	love.graphics.setCanvas()
end]]--

gui.canvases(0, 0, WinWidth(), WinHeight(), 50, "primary")

return gui
