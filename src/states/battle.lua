local party1 = {}
local party2 = {}
local deinitCallback = function() end

local lastCombo = {} -- Remember to reassign the table every time!
local moveRepeatCount = 1

local function deinitBattleState(prevState, party1, deinitCallback)
	gui.canvases.bottomGUI = nil
	gui.canvases.topGUI = nil

	gui.canvases["primary"].drawfunc = nil

	gui.mouse_events.clear()

	state = prevState

	deinitCallback()

	return player1
end

-- Factory to build a move iterator.
	-- Mode 1 iterates over party1's moves,
	-- Mode 2 iterates over party2's moves,
	-- Mode 3 iterates over both party's moves, the lower loop being party2, and
	-- Mode 4 iterates over both party's moves, the lower loop being party1.
-- party1.moves, party2.moves >> ([1-4]int) -> () -> int, ?int, move{}, ?move{}
local function moveIter(mode, p1, p2)
	local party1 = p1 or party1
	local party2 = p2 or party2
	local i = mode <= 2 and 0 or 1
	local j = 0
	if mode == 1 then
		return function()
			i = i + 1
			if i <= #party1.moves then
				return i, party1.moves[i]
			end
		end
	elseif mode == 2 then
		return function()
			i = i + 1
			if i <= #party2.moves then
				return i, party2.moves[i]
			end
		end
	elseif mode == 3 then
		return function()
			i = j < #party2.moves and i or i + 1
			if i <= #party1.moves then
				j = j < #party2.moves and j + 1 or 1
				return i, j, party1.moves[i], party2.moves[j]
			end
		end
	elseif mode == 4 then
		return function()
			i = j < #party1.moves and i or i + 1
			if i <= #party2.moves then
				j = j < #party1.moves and j + 1 or 1
				return i, j, party2.moves[i], party1.moves[j]
			end
		end
	else
		error("Unrecognized mode.")
	end
end

-- Internal function to handle the effects of a single move
-- (move{}, creature{}, creature{},bool) -> int, int, bool, ?{}, ?{}
local function resolveMove(move, user, enemy, prio)
	local dmg, heal, inv, userStatus, enemyStatus = 0, 0, false, nil, nil

	dmg = dmg + (move.damage or 0)
	heal = heal + (move.heal or 0)
	inv = move.inv

	--[[
	if tp == "instant" or tp == "channeled" then
		dmg = dmg + (move.damage or 0)
		heal = heal + (move.heal or 0)
		enemyStatus = enemy.status[1] == "charge" and {} or nil
	end
	if tp == "channeled" then
		if user.status[1] == "channel" and user.status[2] == move.id then
			if user.status[3] == 1 then
				userStatus = {}
			else
				userStatus = {"channel", move.id, user.status[3] - 1}
			end
		else
			userStatus = {"channel", move.id, move.channeltime - 1}
		end
	end
	if tp == "charge" then
		if user.status[1] == "charge" and user.status[2] == move.id then
			userStatus = {}
			dmg = dmg + (move.damage or 0)
			heal = heal + (move.heal or 0)
			enemyStatus = enemy.status[1] == "charge" and {} or nil
		else
			userStatus = {"charge", move.id}
			inv = move.inv or inv
		end
	end]]--
	return dmg, heal, inv, userStatus, enemyStatus
end

-- Internal function to handle move canceling
-- (int, int, type"") -> int
local function cancel(value1, value2, ctype)
	if ctype == "negate" then
		value1 = value1 - value2
	elseif ctype == "nullify" then
		if value2 > 0 then
			value1 = 0
		end
	end
	return math.max(value1, 0)
end

-- Resolve the effects of 2 moves and outputs the resulting changes to health and the new status effects
-- cancel() >> (move{}, move{}, creature{}, creature{}) -> {heal1, dmg1, heal2, dmg2, status1{}, status2{}, prio} >> lastCombo

local m1, m2

local function resolveMoves(move1, move2, party1, party2)
	local p1HPChange, p2HPChange, p1Status, p2Status
	local p1dmg, p1heal, p1inv, p1UStatus, p1EStatus = resolveMove(move1, party1, party2, move1.speed > move2.speed)
	local p2dmg, p2heal, p2inv, p2UStatus, p2EStatus = resolveMove(move2, party2, party1, move2.speed > move1.speed)
	p1Status = p2EStatus or p1UStatus or party1.status
	p2Status = p1EStatus or p2UStatus or party2.status

	local d1, d2, h1, h2 = p1dmg, p2dmg, p1heal, p2heal
	if not (move1.cancelType == "bypass" or move2.cancelType == "bypass") then
		d1 = move2.speed >= move1.speed and cancel(p1dmg,  p2dmg,  move1.cancelType) or d1
		h1 = move2.speed >= move1.speed and cancel(p1heal, p2heal, move1.cancelType) or h1

		d2 = move2.speed <= move1.speed and cancel(p2dmg,  p1dmg,  move2.cancelType) or d2
		h2 = move2.speed <= move1.speed and cancel(p2heal, p1heal, move2.cancelType) or h2
	end
	if p1inv then d2 = 0 end
	if p2inv then d1 = 0 end

	-- KnownMoveCombos
	m1 = {
		name        = move1.name,
		selfDamage  = d2 - h1,
		enemyDamage = d1 - h2,
	}
	m2 = {
		name        = move2.name,
		selfDamage  = d1 - h2,
		enemyDamage = d2 - h1,
	}

	if not party1.knownMoveCombos[move2.name][move1.name] then
		local best = party1.knownMoveCombos[move2.name].best
		party1.knownMoveCombos[move2.name].best = best.name and (
			best.enemyDamage - best.selfDamage <
			m1.enemyDamage - m1.selfDamage and
				m1 or
				best) or
			m1
		party1.knownMoveCombos[move2.name][move1.name] = m1
	end
	if not party2.knownMoveCombos[move1.name][move2.name] then
		local best = party2.knownMoveCombos[move1.name].best
		party2.knownMoveCombos[move1.name].best = best.name and (
			best.enemyDamage - best.selfDamage <
			m2.enemyDamage - m2.selfDamage and
				m2 or
				best) or
			m2
		party2.knownMoveCombos[move1.name][move2.name] = m2
	end

	moveRepeatCount = lastCombo[1] and
			  m1.name == lastCombo[1].name and
			  m1.selfDamage == lastCombo[1].selfDamage and
			  m1.enemyDamage == lastCombo[1].enemyDamage and

			  m2.name == lastCombo[2].name and
			  m2.selfDamage == lastCombo[2].selfDamage and
			  m2.enemyDamage == lastCombo[2].enemyDamage and
			  moveRepeatCount + 1 or 1
	lastCombo = {m1, m2}

	return {
		heal1 = h1,
		dmg1 = d1,
		heal2 = h2,
		dmg2 = d2,
		status1 = p1Status,
		status2 = p2Status,
		prio = (move2.speed > move1.speed),
	}
end

-- Debug function which tests all the moves of 2 parties against each other for 5 turns per move pair and outputs the results to stdout
-- (creature{}, creature{}) >> stdout
local function testMoves(party1, party2)
	for _, _, m1, m2 in moveIter(3, party1, party2) do
		party1.hp = 100
		party2.hp = 100
		party1.status = {}
		party2.status = {}
		print("you: "..m1.name.." VS enemy: "..m2.name)
		for m=0, 5 do
			print("\tTurn "..n.." || you: hp: "..party1.hp.. " status: "..(party1.status[1] or "").." | enemy: hp: "..party2.hp.. " status: "..(party2.status[1] or ""))
			resolveMoves(m1, m2, party1, party2)
		end
	end
end

-- Function to assist with creating an instance of a limited-information beatLast implementation, which selects from making a random move, an unknown move, or the best known move.
-- party1.moves, party2{moves, knownMoveCombos} >> ([0-1]float, [0-1]float) -> party2{moves, knownMoveCombos}, lastCombo >> (int) -> int
local function aiGenerator(exploreUnknownChance, randomChance)
	exploreUnknownChance = exploreUnknownChance or 1
	randomChance = randomChance or 0

	-- Closures are a helpful concept here.
	local moves       = party2.moves
	local enemyMoves  = party1.moves
	local moveCombos  = party2.knownMoveCombos
	local moveCount   = #moves
	local exploredAll = {}
	for i=1, #party1.moves do
		exploredAll[i] = false
	end

	-- party2{moves, knownMoveCombos} >> (int) -> int
	return function(enemyMoveId)
		-- Random move
		if math.random() <= randomChance then
			return math.random(moveCount)
		end
		-- TODO: fairer random distribution
		if math.random() <= exploreUnknownChance and not exploredAll[enemyMoveId] then
			local a = math.random(moveCount)
			local b = a
			local em = moveCombos[enemyMoves[enemyMoveId].name]
			while em[moves[a].name] do
				a = a < moveCount and
					a + 1 or 1
				if a == b then
					exploredAll[enemyMoveId] = true
					break
				end
			end
			if not em[moves[a].name] then
				return a
			end
		end

		-- beatLast implementation
		if lastCombo[1] and lastCombo[2] then
			if moveCombos[lastCombo[1].name].best then
				a = moves[moveCombos[lastCombo[1].name].best.name].id
				return a
			end
		end
		error("Oops!")
	end
end

-- Functions that return polygons to draw to the UI.
-- gui{diamondSizeX, diamondSizeY} >> (int) -> poly{}
local function polyHighlightP1(y)
	return X(-140),
		gui.diamondSizeY * (y + 1) + Y(-180),
		X(-140),
		gui.diamondSizeY * y + Y(-180),
		X(160),
		gui.diamondSizeY * y + Y(-180),
		X(160),
		gui.diamondSizeY * (y + 1) + Y(-180)
end
local function polyHighlightP2(x)
	return  gui.diamondSizeX * (x + 1) + X(-140),
		Y(-180),
		gui.diamondSizeX * x + X(-140),
		Y(-180),
		gui.diamondSizeX * x + X(-140),
		Y(120),
		gui.diamondSizeX * (x + 1) + X(-140),
		Y(120)
end

--(int, int) -> poly{}
local function polyDiamondCellP1Half(x, y)
	return
		-- East corner
		x * gui.diamondSizeX + X(-140),
		y * gui.diamondSizeY + Y(120),

		-- North corner
		(x + 1) * gui.diamondSizeX + X(-140),
		y * gui.diamondSizeY + Y(120),

		--South Corner
		x * gui.diamondSizeX + X(-140),
		(y + 1) * gui.diamondSizeY + Y(120)
	
end
local function polyDiamondCellP2Half(x, y)
	return
		-- West corner
		(x + 1) * gui.diamondSizeX + X(-140),
		(y + 1) * gui.diamondSizeY + Y(120),

		-- North corner
		(x + 1) * gui.diamondSizeX + X(-140),
		y * gui.diamondSizeY + Y(120),

		--South Corner
		x * gui.diamondSizeX + X(-140),
		(y + 1) * gui.diamondSizeY + Y(120)
	
end

-- NOTE: considering moving this to gui.lua
local baseColors = {
	fill =     {0.75, 0.75, 0.75, 1},
	filldark = {0.6 , 0.6 , 0.6 , 1},
	edge =     {0.4 , 0.4 , 0.4 , 1},
}
local p1Color = {
	fill = {0.5 , 1   , 0.5 , 1},
	edge = {0   , 0.5 , 0   , 1},
	text = {0   , 0   , 0   , 1},
}
local p2Color = {
	fill = {1   , 0.5 , 0.5 , 1},
	edge = {0.5 , 0   , 0   , 1},
	text = {0   , 0   , 0   , 1},
}
-- diamond size
local d = {120, -150, -180, 0}
d[5] = (d[1]+d[3])/2

local tabsize = 90
local attackAnimTimer = 0
local attackAnimPhase = "none"
local attackAnimData = {}
local p1selected = 0
local p2selected = 0
local aiturn
local drawBuf = {}
local party1offset = 0
local party2offset = 0


-- party1,moves >> (int) -> poly
local function moveButtonHighlight(y)
	-- FIXME: outer X coordinates not fully extending out.
	local step = 150 / #party1.moves
	local dstep = S(step)
	local x1 = X(-150 - tabsize + y * step)
	local x2 = X(-150 + (y + 1) * step)

	return x1,
		Y(-30) + y * dstep,
		x2 - dstep,
		Y(-30) + y * dstep,
		x2,
		Y(-30) + (y + 1) * dstep,
		x1,
		Y(-30) + (y + 1) * dstep
end

local diamondXDrawPrio = false

-- TODO: rescalable; main.lua love.window.resize()

-- () >> love.graphics
local function drawFunc()
	if (party1.hp < 1 or party2.hp < 1 or moveRepeatCount == 5 and lastCombo[1].selfDamage < 1 and lastCombo[2].selfDamage < 1) and attackAnimPhase ~= "done" then
		attackAnimTimer = 1
		attackAnimPhase = "done"
	end
	local i
	-- draw playfield and choice diamond
	love.graphics.clear(0,0,0,1)

	local baseColor = baseColors
	love.graphics.setColor(baseColor.fill)
	love.graphics.polygon("fill", X(0), Y(d[1]), X(d[2]), Y(d[5]), X(0), Y(d[3]), X(-d[2]), Y(d[5]))

	-- draw choices
	love.graphics.setLineStyle("smooth")

	-- TODO: consolidate

	local moves, partyColor

	-- (party, partyColor, xmult, indent) >> love.graphics
	local function drawHalfGrid(party, partyColor, xmult, indent)
		love.graphics.line(X(xmult*d[2]), Y(d[5]), X(xmult*d[4]), Y(d[1]))
		local step = -d[2]/#party.moves
		for i, move in moveIter(1, party) do
			love.graphics.setLineWidth(S(2))
			love.graphics.setColor(baseColor.edge)
			love.graphics.line(X(xmult*(d[2]+i*step)), Y(d[5]-i*step), X(xmult*(d[4]+i*step)), Y(d[1]-i*step))
			love.graphics.setLineWidth(S(4))
			love.graphics.setColor(partyColor.fill)
			love.graphics.polygon("fill", X(xmult*(d[2]+i*step)), Y(d[5]-i*step),
										  X(xmult*(d[2]-tabsize+(i-1)*step)), Y(d[5]-i*step),
										  X(xmult*(d[2]-tabsize+(i-1)*step)), Y(d[5]-(i-1)*step),
										  X(xmult*(d[2]+(i-1)*step)), Y(d[5]-(i-1)*step))
			love.graphics.setColor(partyColor.edge)
			love.graphics.polygon("line", X(xmult*(d[2]+i*step)), Y(d[5]-i*step),
										  X(xmult*(d[2]-tabsize+(i-1)*step)), Y(d[5]-i*step),
										  X(xmult*(d[2]-tabsize+(i-1)*step)), Y(d[5]-(i-1)*step),
										  X(xmult*(d[2]+(i-1)*step)), Y(d[5]-(i-1)*step))
			love.graphics.setColor(partyColor.text)
			love.graphics.printf(move.name, X(xmult*(d[2]+(i-1)*step+5-tabsize/2)-tabsize/2), Y(d[5]-(i-1)*step-5),
								 tabsize/0.75, indent, 0, S(0.75), S(0.75))
		end

	end

	drawHalfGrid(party1, p1Color, 1,  "left")
	drawHalfGrid(party2, p2Color, -1, "right")

	love.graphics.setLineWidth(S(4))
	love.graphics.setColor(baseColor.edge)
	love.graphics.polygon("line", X(0), Y(d[1]), X(d[2]), Y(d[5]), X(0), Y(d[3]), X(-d[2]), Y(d[5]))

	local barheight = 60
	local function drawHalfBar(entity, partyColor, xmult, indent)
		love.graphics.setColor(baseColor.filldark)
		love.graphics.polygon("fill", X(-320*xmult), Y(d[5]),
									  X(xmult*d[2]), Y(d[5]),
									  X(xmult*(d[2]+barheight/2)), Y(d[5]+barheight/2),
									  X(xmult*d[2]), Y(d[5]+barheight),
									  X(-320*xmult), Y(d[5]+barheight))
		love.graphics.setLineWidth(S(4))
		love.graphics.setColor(baseColor.edge)
		love.graphics.polygon("line", X(-320*xmult), Y(d[5]),
									  X(xmult*d[2]), Y(d[5]),
									  X(xmult*(d[2]+barheight/2)), Y(d[5]+barheight/2),
									  X(xmult*d[2]), Y(d[5]+barheight),
									  X(-320*xmult), Y(d[5]+barheight))
		love.graphics.setColor(partyColor.text)
		love.graphics.printf(entity.humanname, X(-315*xmult - ((xmult<0 and 100) or 0)), Y(d[5]+barheight-5),
							 100, indent, 0, S(1), S(1))
		local hpbarWidth = 290 + d[2]
		love.graphics.setColor(partyColor.edge)
		love.graphics.rectangle("fill", X(xmult*(-155+d[2]/2)-(316+d[2])/2), Y(d[5]+barheight/2+8), S(316+d[2]), S(16))
		local hpratio = entity.hp / entity.maxHp
		local hpsize = (310 + d[2]) * hpratio
		love.graphics.setColor(partyColor.fill)
		love.graphics.rectangle("fill", X(xmult*(hpsize/2-310)-hpsize/2), Y(d[5]+barheight/2+5), S(hpsize), S(10))
		love.graphics.setColor(partyColor.text)
		love.graphics.printf(math.ceil(entity.hp).." / "..math.ceil(entity.maxHp),
							 X(-307*xmult - ((xmult<0 and 60) or 0)), Y(d[5]+barheight/2 + 4.5),
							 100, indent, 0, S(0.6), S(0.6))
	end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(party1.sprite, X(-310 + party1offset), 0, 0, S(1), S(1))
	love.graphics.draw(party2.sprite, X(160 - party2offset), 0, 0, S(1), S(1))
	if attackAnimPhase == "scramble" then
		local stage = math.floor(attackAnimTimer^2*4)/4
		local lastStage = attackAnimData.lastStage or 100
		if stage < lastStage then
			attackAnimData.lastStage = stage
			p2selected = math.floor(math.random() * #party2.moves) + 1 -- NOTE: there's an alternative way to do this.
		end
		if stage == 0 and not aiturn then
			p2selected = party2.ai(p1selected)
			aiturn = true
		end
		if attackAnimTimer < 0 then
			aiturn = false
			attackAnimPhase = "attack"
			attackAnimTimer = 3
			attackAnimData = {
				effect = resolveMoves(party1.moves[p1selected], party2.moves[p2selected], party1, party2),
				applied1 = false,
				applied2 = false,
			}
		end
	elseif attackAnimPhase == "attack" then
		local localtimer = (3-attackAnimTimer) % 1.5
		local effect = attackAnimData.effect
		if effect.prio == (attackAnimTimer < 1.5) then
			if localtimer < 1 then
				love.graphics.setColor(p1Color.fill)
				love.graphics.printf(party1.moves[p1selected].name, X(-200), Y(160), 200, "center", 0, S(2), S(2))
			end
			if localtimer > 0.5 then
				if effect.heal1 > 0 then
					love.graphics.setColor(p1Color.fill)
					love.graphics.printf("healed "..tonumber(effect.heal1).." hp", X(-270), Y(160), 200, "center", 0, S(1), S(1))
				end
				if effect.dmg1 > 0 then
					love.graphics.setColor(p2Color.fill)
					love.graphics.printf("hit for "..tonumber(effect.dmg1).." hp", X(120), Y(160), 200, "center", 0, S(1), S(1))
				end
				if not attackAnimData.applied1 then
					party1.hp = math.min(party1.hp + effect.heal1, party1.maxHp)
					party2.hp = party2.hp - effect.dmg1
					party1.status = effect.p1Status
					attackAnimData.applied1 = true
				end
			end
		else
			if localtimer < 1 then
				love.graphics.setColor(p2Color.fill)
				love.graphics.printf(party2.moves[p2selected].name, X(-200), Y(160), 200, "center", 0, S(2), S(2))
			end
			if localtimer > 0.5 then
				if effect.heal2 > 0 then
					love.graphics.setColor(p1Color.fill)
					love.graphics.printf("healed "..tonumber(effect.heal2).." hp", X(120), Y(160), 200, "center", 0, S(1), S(1))
				end
				if effect.dmg2 > 0 then
					love.graphics.setColor(p2Color.fill)
					love.graphics.printf("hit for "..tonumber(effect.dmg2).." hp", X(-270), Y(160), 200, "center", 0, S(1), S(1))
				end
				if not attackAnimData.applied2 then
					party2.hp = math.min(party2.hp + effect.heal2, party2.maxHp)
					party1.hp = party1.hp - effect.dmg2
					party2.status = effect.p2Status
					attackAnimData.applied2 = true
				end
			end
		end
		if attackAnimTimer < 0 then
			attackAnimPhase = "none"
			attackAnimData = {}
			p2selected = 0
		end
	elseif attackAnimPhase == "done" and attackAnimTimer < 0 then
		deinitBattleState(prevState, party1, deinitCallback)
	end

	attackAnimTimer = attackAnimTimer-0.0166 -- what

	-- Display only when the player isn't selecting a move.
	if p1selected > 0 and p1selected <= #party1.moves then
		love.graphics.setColor(1, 1, 1, 0.3)
		love.graphics.polygon("fill", moveButtonHighlight(p1selected - 1))

		-- () >> love.graphics, diamondXDrawPrio
		drawBuf[#drawBuf+1] = function ()
			love.graphics.setColor(1, 1, 1, 0.3)
			if not diamondXDrawPrio then
				love.graphics.polygon("fill", polyHighlightP1(p1selected - #party1.moves - 1))
			end
			diamondXDrawPrio = false
		end
	end
	if attackAnimPhase ~= "none" then
		if p2selected then
			drawBuf[#drawBuf+1] = function ()
				love.graphics.setColor(1, 1, 1, 0.3)
				love.graphics.polygon("fill", polyHighlightP2(#party2.moves - p2selected))
			end
		end
	end

	drawHalfBar(party1, p1Color, 1, "left")
	drawHalfBar(party2, p2Color, -1, "right")
	
	local moveCombo
	for i, j, m1, m2 in moveIter(3) do
		moveCombo = party1.knownMoveCombos[m2.name][m1.name]
		if moveCombo then
			local enemyDamage = moveCombo.enemyDamage
			local selfDamage = moveCombo.selfDamage
			drawBuf[#drawBuf + 1] = function()
				if selfDamage < 0 then
					love.graphics.setColor(0, 1, 0, 0.5)
				else
					love.graphics.setColor(0, 0.8, 0, 0.5)
				end
				love.graphics.polygon("fill", polyDiamondCellP1Half(#party2.moves - j, i - 1))
				if enemyDamage >= 0 then
					love.graphics.setColor(1, 0, 0, 0.5)
				else
					love.graphics.setColor(0.8, 0, 0, 0.5)
				end
				love.graphics.polygon("fill", polyDiamondCellP2Half(#party2.moves - j, i - 1))
				love.graphics.setColor(baseColor.edge)
				love.graphics.setLineWidth(S(2))
				love.graphics.line((#party2.moves + 1 - j) * gui.diamondSizeX + X(-140), (i - 1) * gui.diamondSizeY + Y(120), (#party2.moves - j) * gui.diamondSizeX + X(-140), i * gui.diamondSizeY + Y(120))
			end

			drawBufTop[#drawBufTop + 1] = function()
				love.graphics.setColor(1, 1, 1, 1)
				-- TODO: center text
				love.graphics.print((selfDamage < 0 and "+" or selfDamage > 0 and "-" or "")..tostring(math.abs(selfDamage)), (1/3 + #party2.moves - j) * gui.diamondSizeX + X(-140), (i - 2/3) * gui.diamondSizeY + Y(120), math.rad(45), S(1), S(1))
				love.graphics.print((enemyDamage < 0 and "+" or enemyDamage > 0 and "-" or "")..tostring(math.abs(enemyDamage)), (2/3 + #party2.moves - j) * gui.diamondSizeX + X(-140), (i - 1/3) * gui.diamondSizeY + Y(120), math.rad(45), S(1), S(1))
			end
		end
	end

end

-- TODO: UI elements on canvases separate from bg for animation

-- Transform matrix
local diamondTransform = love.math.newTransform(X(-150), Y(-120), math.rad(-45), math.sqrt(2) / 2, math.sqrt(2) / 2, 0, 0)

-- Decision Diamond helper functions:
-- Input: functions to draw (input functions must have no arguments.)
-- ({() >> love.graphics, ...})
local function drawRelDiamond(arg)
	if arg then
		love.graphics.push()
		love.graphics.applyTransform(diamondTransform)
		for i=1, #arg do
			arg[i]()
		end
		love.graphics.pop()
	end
end

-- Initializes the buttons and hover elements for the choice diamond and the move choices.
-- (_, _, cx, cy) -> bool
local function diamondCollider(x, y, cx, cy) -- Ignores calling conventions, but that's how it works
	x, y = diamondTransform:inverseTransformPoint(cx, cy)
	return x < X(150) and x > X(-150) and y > Y(120) and y < Y(-180)
end

-- attackAnimPhase >> () >> love.graphics, drawBuf
local function diamondHover()
	local x, y = diamondTransform:inverseTransformPoint(love.mouse.getX(), love.mouse.getY()) -- transforms the cursor to match the axes of the diamond to the x and y coordinates of the game.

	-- Relative positioning
	x = math.floor((x - X(-150)) / gui.diamondSizeX)
	y = math.floor((y - Y(-180)) / gui.diamondSizeY)

	if attackAnimPhase == "none" then
		-- p1selected = y + #party1.moves + 1 -- NOTE: we have p1Click for this.
		drawBuf = {
			-- () >> love.graphics, diamondXDrawPrio
			function()
				diamondXDrawPrio = true
				love.graphics.setColor(1, 1, 1, 0.3)
				love.graphics.polygon("fill", polyHighlightP1(y))
			end,
			function()
				love.graphics.setColor(1, 1, 1, 0.3)
				love.graphics.polygon("fill", polyHighlightP2(x))
			end
		}

	end

	love.graphics.setLineWidth(S(4))
	love.graphics.setColor(baseColors.edge)
	love.graphics.polygon("line", X(0), Y(d[1]), X(d[2]), Y(d[5]), X(0), Y(d[3]), X(-d[2]), Y(d[5]))
end

-- p1selected, attackAnimPhase >> (int) >> attackAnimPhase, attackAnimTimer, attackAnimData
local function diamondClick(clicks)
	if clicks <= 1 then return end
	if p1selected > 0 and attackAnimPhase == "none" then
		attackAnimPhase = "scramble"
		attackAnimTimer = 2
		attackAnimData = {}
	end
end

-- P1 Move buttons
-- (_, _, cx, cy) -> bool
local function p1Collider(x, y, cx, cy) -- Ignores calling conventions, but that's how it works
	if cy >= Y(-30) and cy <= Y(-180) then
		local step = 150 / #party1.moves --TODO: Turn code into a function
		local y = math.floor((cy - Y(-30)) / S(step)) -- integer value
		-- horizontal bounds
		local x1 = X(-150 - tabsize + y * step)
		local x2 = X(-150 + (y + 1) * step)
	
		return cx >= x1 and cx <= x2
	end
end

-- This will select the move based on cursor Y position.
local p1Click = function(clicks)
	local step = S(150) / #party1.moves
	y = math.floor((love.mouse.getY() - Y(-30)) / step) -- integer value

	if attackAnimPhase == "none" then
		if clicks > 1 then
			if p1selected == y + 1 then
				diamondClick(clicks) -- function reuse
			end
		end
		p1selected = y + 1
	end

	-- resolveMoves(party1.moves[y + 1], party2.moves[p2AI()], party1, party2)
end


local function initBattleState(prevState, params)
	party1 = params.party1
	party2 = params.party2
	deinitCallback = params.deinitCallback

	local p1move, p2move
	for i, j, m1, m2 in moveIter(3) do
		local p1move = m1.name
		local p2move = m2.name
		party1.knownMoveCombos[p2move] =
			party1.knownMoveCombos[p2move] or {}
		party1.knownMoveCombos[p2move][p1move] = false

		party1.knownMoveCombos[p2move].best = {}

		party2.knownMoveCombos[p1move] =
			party2.knownMoveCombos[p1move] or {}
		party2.knownMoveCombos[p1move][p2move] = false

		party2.knownMoveCombos[p1move].best = {}
	end


	party2.ai = aiGenerator(1, 0)

	-- testMoves(party1, party2)

	gui.canvases["primary"].drawfunc = drawFunc
	gui.canvases["primary"].enabled = true

	gui.canvases(0, 0, WinWidth(), WinHeight(), 60, "bottomGUI") -- TODO: gui.canvases(0, Y(120), WinWidth(), S(300), 60, "bottomGUI")
	gui.canvases.bottomGUI.drawfunc = function()
		love.graphics.clear()
		love.graphics.setBlendMode("alpha", "premultiplied")
		drawRelDiamond(drawBuf)
		love.graphics.setBlendMode("alpha")
		drawBuf = {}
	end
	gui.canvases.bottomGUI.enabled = true
	gui.canvases(0, 0, WinWidth(), WinHeight(), 70, "topGUI") -- TODO: gui.canvases(0, Y(120), WinWidth(), S(300), 70, topGUI")
	gui.canvases.topGUI.drawfunc = function()
		love.graphics.clear()
		love.graphics.setBlendMode("alpha", "premultiplied")
		drawRelDiamond(drawBufTop)
		love.graphics.setBlendMode("alpha")
		drawBufTop = {}
	end
	gui.canvases.topGUI.enabled = true

	-- TODO: store diamond params somewhere
	-- Side lengths of a single rectangular grid unit in inversely trasnformed space.
	gui.diamondSizeX, gui.diamondSizeY = S(300) / #party2.moves, S(300) / #party1.moves

	gui.mouse_events(X(-150), Y(120), diamondCollider, diamondHover, diamondClick, "battle", 1)
	gui.mouse_events(0, 0, p1Collider, function() end, p1Click, "battle", 2)

end

return initBattleState
