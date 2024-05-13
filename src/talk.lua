local W = {1, 1, 1}
local R = {1, 0.2, 0.2}
local G = {0.2, 1, 0.2}
local B = {0.2, 0.2, 1}
local allDialog = {
	{
		sprites = {
			bg = "classroom.png"

			teacher1 = "teacher1.png",
			teacher2 = "teacher2.png",
			teacher3 = "teacher3.png",
			teacher4 = "teacher4.png",
			teacher5 = "teacher5.png",

			mcClassroom1 = "mcClassroom1.png",
			mcClassroom2 = "mcClassroom2.png",
		},
		{
			text = "Good morning, class.",
			"teacher1",
		},
		{
			text = "[Everyone says good morning.]",
			"mcClassroom1",
		},
		{
			text = {W, "Today, we will be talking about the ", G, "Nash Equilibrium."},
			"teacher2",
		},
		{
			text = {W, "As a recap for the previous lesson for those who don't remember, We learned the basics of ", B, "Game Theory", W, ", which is the field of analysing independent parties making decisions, from... well... games, to business and even to the military!",
			"teacher3",
		},
		{
			text = {W, "The ", G, "Nash Equilibrium ", W "is a concept in", B, "Game Theory ", W, "that describes how two parties, when given an ", R, "infinite ", W, "amount of timem will land on an outcone, where changing either decision will not benefit either party. This may be dem-"} ,
			"teacher4",
		},
		{
			text = "Agh!- What is that thing?",
			"teacher5",
		},
	}
}

for _, dialog in pairs(allDialog) do
	for i, s in pairs(dialog.sprites) do
		dialog.sprites[k] = love.graphics.newImage("assets/"..s)
	end
	for _, t in ipairs(dialog) do
		for k, s in ipairs(t) do
			t[k] = t.sprites[s]
		end
	end
end

return allDialog
