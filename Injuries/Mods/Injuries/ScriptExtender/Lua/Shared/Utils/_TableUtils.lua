--- @module "Utils._TableUtils"

TableUtils = {}

function TableUtils:AddItemToTable_AddingToExistingAmount(tarTable, key, amount)
	if not tarTable then
		tarTable = {}
	end
	if not tarTable[key] then
		tarTable[key] = amount
	else
		tarTable[key] = tarTable[key] + amount
	end
end

-- stolen from https://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value
local function copy(obj, seen, makeImmutable)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[copy(k, s, makeImmutable)] = copy(v, s, makeImmutable) end

	if makeImmutable then
		res = setmetatable(res, {
			getmetatable(res) and table.unpack(getmetatable(res)),
			__newindex = function(...) error("Attempted to modify immutable table") end
		})
	end

	return res
end

--- If obj is a table, returns a deep clone of that table, otherwise return obj
---@param obj table?
---@return table?
function TableUtils:DeeplyCopyTable(obj)
	if not obj then return end
	return copy(obj, nil, false)
end

--- Creates an immutable table
---@param tableName string
---@return table
function TableUtils:MakeImmutableTableCopy(myTable)
	return copy(myTable, nil, true)
end

---Compare two lists
---@param first
---@param second
---@treturn boolean true if the lists are equal
function TableUtils:CompareLists(first, second)
	for property, value in pairs(first) do
		if value ~= second[property] then
			return false
		end
	end

	for property, value in pairs(second) do
		if value ~= first[property] then
			return false
		end
	end

	return true
end

--- Custom pairs function that iterates over a table with alphanumeric indexes in alphabetical order
--- Optionally accepts a function to transform the key for sorting and returning
---@param t table
---@param keyTransformFunc function?
---@return function
function TableUtils:OrderedPairs(t, keyTransformFunc)
	local keys = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		local keyA = keyTransformFunc and keyTransformFunc(a) or tostring(a)
		local keyB = keyTransformFunc and keyTransformFunc(b) or tostring(b)
		return keyA < keyB
	end)

	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			local key = keys[i]
			return key, t[key]
		end
	end
end

---@param list table
---@param str string
---@return boolean, any?
function TableUtils:ListContains(list, str)
	if not list then
		return false
	end

	for i, value in pairs(list) do
		if value == str then
			return true, i
		end
	end
	return false
end

--- Get a count of all elements in a table with a non-numeric index
---@param t table
---@return number
function TableUtils:CountEntries(t)
	local count = 0
	for _, _ in pairs(t) do
		count = count + 1
	end
	return count
end
