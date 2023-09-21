local utils = {}

function utils.shallowcopy(t)
	local ret = {}
	for k, v in next, t do
		ret[k] = v
	end
	return ret
end

return utils
