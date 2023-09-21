creatures = {}

local moves = require("src/moves")

--initalises some cached data for moves
local function initMoves(moves)
	local i
	for i=1, #moves do
		moves[i].id = i
		moves[moves[i].name] = moves[i]
	end
	return moves
end


local allCreatures = {
	player = {
		humanname = "Player",
		maxHp = 10,
		sprite = "a.png",
		moves = initMoves{
			moves.Slash,
			moves.Charge,
			moves.Heavy_Slash,
		},
	},
	pentagon = {
		humanname = "Pentagon",
		maxHp = 10,
		sprite = "b.png",
		moves = initMoves{
			moves.Slash,
			moves.Charge,
			moves.Heavy_Slash,
		},
	},
	pentavian = {
		humanname = "Pentavian",
		maxHp = 336,
		sprite = "b.png",
		moves = initMoves{
			moves.Crasher_Storm,
			moves.En_Guarde,
			moves.Imminent_Asterism,
			moves.Poly_Lightning,
			moves.Waterflame,
		},
	},
}

creatures.player = allCreatures.player

for name, creature in pairs(allCreatures) do
	creature.name = name
	creature.sprite = love.graphics.newImage("assets/"..creature.sprite)
end


-- Get an instance of a creature, note that the moves element is just a ref to the definition's moves and should not be edited.
function creatures.getCreature(name)
	local creatureDef = allCreatures[name]
	local creature = {
		name = creatureDef.name,
		humanname = creatureDef.humanname,
		maxHp = creatureDef.maxHp,
		hp = creatureDef.maxHp,
		status = {},
		sprite = creatureDef.sprite,
		moves = creatureDef.moves,
		-- For player: Used to store the known move combination damage numbers to the GUI. TODO: Store in a savefile.
		-- For NPCs: Used to determine which move to select based on the players actions. This is initialized at the start of the battle. 
		knownMoveCombos = {},
	}

	return creature
end

return creatures
