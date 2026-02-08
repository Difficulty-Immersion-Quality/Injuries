RandomHelpers = {}

---@param s string
---@return string
function RandomHelpers:SanitizeStringForFind(s)
	-- Magic chars in Lua patterns: ( ) . % + - * ? [ ^ $
	return (s:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1"))
end