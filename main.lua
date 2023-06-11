--[[
This code is structured like a finite state machine. https://en.wikipedia.org/wiki/Finite-state_machine
Function structure *strictly* must have all variables that it uses, as well as a summary of the function's purpose and output (if any).
Ex:
function player_hp_display(cur, max) --Displays player hp to the screen.
	--code here--
end

--]]

function init_battle(player_state, enemy) --Initializes battle between player and enemy
	state = "battle-start"
	-- operational code TODO: graphics and stuff go here
	state = "battle"
end

function battle_state(player_state, enemy) --Gameplay loop during the battle state.
	--TODO: UI movement
	--TODO: check for battle-ending conditions
end

function end_battle(player_state, enemy) --Deinitializes the battle state
	state = "battle-end"
	--operational code TODO: graphics and stuff go here
	state = "overworld"
end

function love.load() 
	init_battle() --Prototype 1 is testing just the battle system's effectiveness for learning.
end
