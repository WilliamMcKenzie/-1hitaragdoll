--!nocheck
-- Appended after tools/preview/mock.luau + the bundled showcase script.
-- Serialises Workspace.AssetShowcase and ServerStorage.AssetKitModels to Rojo
-- .model.json files (printed as one JSON object keyed by file name).
-- The Base biome's ground is left out: Rojo recolours the place's real Baseplate.

local SKIP = { Parent = true, Name = true, ClassName = true, WorldPivot = true, Adornee = true }

local function q(s)
	return '"' .. tostring(s):gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
end
local function n(x)
	if x == math.floor(x) then return tostring(math.floor(x)) end
	return string.format("%.4f", x)
end

local function value(k, v)
	local t = type(v)
	if t == "boolean" then return tostring(v) end
	if t == "number" then return n(v) end
	if t == "string" then
		local enumName = v:match("^%u%w+%.(%u%w+)$")
		if enumName then
			return q(enumName)
		end
		return q(v)
	end
	if t == "table" then
		if v.__enum then
			return q(v.Name)
		end
		if v.__udim2 then
			local u = v.__udim2
			return string.format('{"UDim2":[[%s,%s],[%s,%s]]}', n(u[1]), n(u[2]), n(u[3]), n(u[4]))
		end
		if v.R then
			return string.format('{"Color3":[%s,%s,%s]}', n(v.R), n(v.G), n(v.B))
		end
		if v.p and v.r then
			local r = v.r
			return string.format('{"CFrame":{"position":[%s,%s,%s],"orientation":[[%s,%s,%s],[%s,%s,%s],[%s,%s,%s]]}}',
				n(v.p[1]), n(v.p[2]), n(v.p[3]), n(r[1]), n(r[4]), n(r[7]), n(r[2]), n(r[5]), n(r[8]), n(r[3]), n(r[6]), n(r[9]))
		end
		if v.X then
			return string.format('{"Vector3":[%s,%s,%s]}', n(v.X), n(v.Y), n(v.Z))
		end
	end
	error("cannot serialise " .. k .. " (" .. t .. ")")
end

local function encode(o, out)
	table.insert(out, '{"name":' .. q(o.Name) .. ',"className":' .. q(o.ClassName))
	local props = {}
	local keys = {}
	for k in rawget(o, "_props") do
		if not SKIP[k] then table.insert(keys, k) end
	end
	table.sort(keys)
	for _, k in keys do
		table.insert(props, q(k) .. ":" .. value(k, rawget(o, "_props")[k]))
	end
	if #props > 0 then
		table.insert(out, ',"properties":{' .. table.concat(props, ",") .. "}")
	end
	local kids = rawget(o, "_children")
	if #kids > 0 then
		table.insert(out, ',"children":[')
		for i, c in kids do
			if i > 1 then table.insert(out, ",") end
			encode(c, out)
		end
		table.insert(out, "]")
	end
	table.insert(out, "}")
end

local show = workspace:FindFirstChild("AssetShowcase")
local baseGround = show:FindFirstChild("Base"):FindFirstChild("BaseBaseplate")
baseGround.Parent = nil

local files = {}
for name, root in { AssetShowcase = show, AssetKitModels = SERVICES.ServerStorage:FindFirstChild("AssetKitModels") } do
	local out = {}
	encode(root, out)
	table.insert(files, q(name) .. ":" .. table.concat(out))
end
print("{" .. table.concat(files, ",") .. "}")
