--!nocheck
--[[
	==========================================================================
	  BEACH CHILL MAP GENERATOR  (Roblox / Luau)
	  แม็พเกาะนั่งชิลล์ริมทะเล แบบเน้นรายละเอียดสมจริง
	==========================================================================

	วิธีใช้ (เลือกอย่างใดอย่างหนึ่ง)

	  A) ง่ายที่สุด — สร้าง Script ใน ServerScriptService แล้ววางโค้ดทั้งไฟล์นี้
	     กด Play แม็พจะถูกสร้างตอนเริ่มเกม (ผู้เล่นจะเกิดหลังสร้างเสร็จ)

	  B) "อบ" แม็พลงไฟล์ถาวร (แก้ไขต่อใน Studio ได้) —
	     คัดลอกโค้ดทั้งหมดไปวางใน Command Bar (View > Command Bar) แล้วกด Enter
	     จากนั้นใส่สคริปต์เดียวกันไว้ใน ServerScriptService ด้วย ตอนกด Play
	     สคริปต์จะเห็นว่ามีแม็พอยู่แล้ว และจะรันแค่แอนิเมชัน (เรือโยก นกบิน ไฟกระพริบ)

	  ⚠ CLEAR_TERRAIN = true จะล้าง Terrain เดิมทั้งหมด (เกาะเก่า) ก่อนสร้างใหม่
	  ⚠ โมเดล Part เดิมใน Workspace จะไม่ถูกลบ — ย้าย/ลบเองถ้าซ้อนกัน
	==========================================================================
]]

local CONFIG = {
	SEED = 2026,                 -- เปลี่ยนเลขเพื่อสุ่มรูปเกาะ/ตำแหน่งต้นไม้ใหม่
	QUALITY = "Balanced",        -- "Mobile" | "Balanced" | "High"
	CLEAR_TERRAIN = true,        -- ล้าง Terrain เดิมก่อนสร้าง
	REBUILD_ON_PLAY = false,     -- ถ้ามีแม็พอยู่แล้ว ตอน Play จะไม่สร้างซ้ำ
	DISABLE_OTHER_SPAWNS = true, -- ปิด SpawnLocation อื่นเพื่อให้เกิดบนเกาะนี้

	ISLAND_RADIUS = 160,         -- รัศมีเกาะ (studs)
	OCEAN_SIZE = 3072,           -- ขนาดทะเลรอบเกาะ (ทวีคูณของ 512)

	TIME_OF_DAY = 16.9,          -- 16.9 = แดดเย็นสีทอง
	DAY_CYCLE = false,           -- true = เวลาเดินเอง
	DAY_LENGTH_MINUTES = 24,

	-- ใส่ Sound ID เองจาก Creator Store (เว้นว่าง = ไม่เล่น)
	SOUNDS = {
		Waves = "",  -- เช่น "rbxassetid://1234567890"
		Birds = "",
		Music = "",
	},
}

local QUALITY_PRESETS = {
	Mobile   = { palms = 16, fronds = 9,  frondSteps = 6, bushes = 22, ferns = 12, shells = 25, fringe = 1.1, bamboo = 0.9 },
	Balanced = { palms = 22, fronds = 10, frondSteps = 7, bushes = 32, ferns = 18, shells = 40, fringe = 0.75, bamboo = 0.7 },
	High     = { palms = 30, fronds = 12, frondSteps = 9, bushes = 45, ferns = 26, shells = 60, fringe = 0.5, bamboo = 0.62 },
}
local Q = QUALITY_PRESETS[CONFIG.QUALITY] or QUALITY_PRESETS.Balanced

-------------------------------------------------------------------------------
-- Services / globals
-------------------------------------------------------------------------------
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Terrain = Workspace.Terrain

local IS_RUNNING = RunService:IsRunning()
local MAP_NAME = "BeachChillMap"
local SEA = 0
local M = Enum.Material
local UP = Vector3.yAxis
local rng = Random.new(CONFIG.SEED)
local NOISE_Z = (CONFIG.SEED % 997) + 0.37

-------------------------------------------------------------------------------
-- Small helpers
-------------------------------------------------------------------------------
local yieldCounter = 0
local function breathe(n)
	yieldCounter += (n or 1)
	if yieldCounter >= 250 then
		yieldCounter = 0
		task.wait()
	end
end

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
local function lerp(a, b, t) return a + (b - a) * t end
local function smoothstep(e0, e1, x)
	local t = clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function outward(p)
	local f = flat(p)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.xAxis
end
local function jitterColor(c, amount)
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, clamp(s + rng:NextNumber(-amount, amount) * 0.6, 0, 1), clamp(v + rng:NextNumber(-amount, amount), 0, 1))
end
local function merge(a, b)
	if b then
		for k, v in pairs(b) do a[k] = v end
	end
	return a
end
local function noise2(x, z, scale, off)
	return math.noise(x / scale + off * 13.13, z / scale - off * 7.71, NOISE_Z)
end

-- decorative parts: no collision / touch / raycast (faster, players don't snag)
local DECO = { CanCollide = false, CanTouch = false, CanQuery = false }

local function make(className, parent, props)
	local p = Instance.new(className)
	if p:IsA("BasePart") then
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if props.Shape then p.Shape = props.Shape end
		if props.Size then p.Size = props.Size end
	end
	for k, v in pairs(props) do
		if k ~= "Shape" and k ~= "Size" and k ~= "CFrame" then
			p[k] = v
		end
	end
	if props.CFrame then p.CFrame = props.CFrame end
	p.Parent = parent
	breathe()
	return p
end

local function block(parent, size, cf, color, material, extra)
	return make("Part", parent, merge({
		Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic,
	}, extra))
end

local function ball(parent, d, pos, color, material, extra)
	return make("Part", parent, merge({
		Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), CFrame = CFrame.new(pos),
		Color = color, Material = material or M.SmoothPlastic,
	}, extra))
end

local function ellipsoid(parent, size, cf, color, material, extra)
	local p = block(parent, size, cf, color, material, extra)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function safeLookAt(pos, target, up)
	local look = target - pos
	if look.Magnitude < 1e-6 then return CFrame.new(pos) end
	look = look.Unit
	up = up or UP
	if math.abs(look:Dot(up.Unit)) > 0.999 then up = Vector3.xAxis end
	return CFrame.lookAt(pos, pos + look, up)
end

-- cylinder whose axis runs from a to b
local function cylinderBetween(parent, a, b, d, color, material, extra)
	local len = (b - a).Magnitude
	if len < 0.01 then return end
	local cf = safeLookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	return make("Part", parent, merge({
		Shape = Enum.PartType.Cylinder, Size = Vector3.new(len, d, d), CFrame = cf,
		Color = color, Material = material or M.SmoothPlastic,
	}, extra))
end

-- box from a to b (Z axis along a->b)
local function blockBetween(parent, a, b, w, h, color, material, extra, up)
	local len = (b - a).Magnitude
	if len < 0.01 then return end
	return block(parent, Vector3.new(w, h, len), safeLookAt((a + b) / 2, b, up), color, material, extra)
end

-- filled triangle made of two WedgeParts
local function triangle(parent, a, b, c, thickness, color, material, extra)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab)
	if right.Magnitude < 1e-6 then return end
	right = right.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	make("WedgePart", parent, merge({
		Size = Vector3.new(thickness, height, math.abs(ab:Dot(back))),
		CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back),
		Color = color, Material = material,
	}, extra))
	make("WedgePart", parent, merge({
		Size = Vector3.new(thickness, height, math.abs(ac:Dot(back))),
		CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back),
		Color = color, Material = material,
	}, extra))
end

local function quad(parent, a, b, c, d, thickness, color, material, extra)
	triangle(parent, a, b, c, thickness, color, material, extra)
	triangle(parent, a, c, d, thickness, color, material, extra)
end

-- sagging rope (catenary approximation); returns sampled points
local function rope(parent, a, b, sag, segments, d, color)
	local pts = { a }
	local prev = a
	for i = 1, segments do
		local u = i / segments
		local p = a:Lerp(b, u) - UP * sag * 4 * u * (1 - u)
		cylinderBetween(parent, prev, p, d, color, M.Fabric, DECO)
		table.insert(pts, p)
		prev = p
	end
	return pts
end

local function addLight(parent, color, range, brightness, shadows, flicker)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = shadows or false
	l.Parent = parent
	if flicker then
		l:SetAttribute("BaseBrightness", brightness)
		CollectionService:AddTag(l, "BC_Flicker")
	end
	return l
end

local function newModel(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-------------------------------------------------------------------------------
-- Island shape
-------------------------------------------------------------------------------
local R0 = CONFIG.ISLAND_RADIUS

local function radiusAt(theta)
	local c, s = math.cos(theta), math.sin(theta)
	return R0 * (1
		+ 0.13 * math.noise(c * 1.3 + 5.31, s * 1.3 + 2.17, NOISE_Z)
		+ 0.05 * math.noise(c * 4.1 + 1.73, s * 4.1 + 3.37, NOISE_Z))
end

-- point on the island: angle in degrees (0 = +X, -90 = north/-Z), t = 0 centre .. 1 shoreline
local function polar(deg, t)
	local th = math.rad(deg)
	local r = t * radiusAt(th)
	return Vector3.new(math.cos(th) * r, 0, math.sin(th) * r)
end

local function tAt(x, z)
	local r = math.sqrt(x * x + z * z)
	return r / radiusAt(math.atan2(z, x)) + 0.025 * noise2(x, z, 28, 1)
end

-- key locations
local LAYOUT = {
	spawn     = polar(-6, 0.80),
	dockStart = polar(0, 0.80),
	bar       = polar(-34, 0.85),
	lounge    = polar(52, 0.87),
	campfire  = polar(188, 0.87),
	hammockA  = polar(117, 0.78),
	hammockB  = polar(124.5, 0.78),
	towels    = polar(86, 0.9),
}

-- rocky headland + sea stacks (gaussian bumps)
local ROCKS = {
	{ pos = polar(-95, 0.95), h = 34, s = 19 },
	{ pos = polar(-80, 1.08), h = 13, s = 7 },
	{ pos = polar(-112, 1.07), h = 10, s = 6 },
	{ pos = polar(214, 1.08), h = 9, s = 6 },
	{ pos = polar(140, 1.1), h = 7, s = 5 },
}

local function rockBump(x, z)
	local total = 0
	for _, r in ipairs(ROCKS) do
		local dx, dz = x - r.pos.X, z - r.pos.Z
		local g = math.exp(-(dx * dx + dz * dz) / (2 * r.s * r.s))
		if g > 0.002 then
			local crag = 0.7 + 0.7 * math.abs(noise2(x, z, 9, 3)) + 0.3 * noise2(x, z, 3.5, 4)
			total += r.h * (g ^ 0.85) * crag
		end
	end
	return total
end

-- smooth footpaths (Catmull-Rom through control points)
local function catmull(points, sub)
	local out = {}
	for i = 1, #points - 1 do
		local p0 = points[math.max(i - 1, 1)]
		local p1, p2 = points[i], points[i + 1]
		local p3 = points[math.min(i + 2, #points)]
		for s = 0, sub - 1 do
			local t = s / sub
			local t2, t3 = t * t, t * t * t
			table.insert(out, 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
		end
	end
	table.insert(out, points[#points])
	return out
end

local PATHS = {
	catmull({ polar(-6, 0.76), polar(-12, 0.6), polar(20, 0.33), polar(100, 0.3), polar(150, 0.5), polar(184, 0.72) }, 8),
	catmull({ polar(-12, 0.6), polar(-24, 0.66), polar(-32, 0.73) }, 6),
	catmull({ polar(20, 0.33), polar(44, 0.56), polar(52, 0.72) }, 6),
}

local function distToSegment(px, pz, a, b)
	local abx, abz = b.X - a.X, b.Z - a.Z
	local apx, apz = px - a.X, pz - a.Z
	local len2 = abx * abx + abz * abz
	local t = len2 > 0 and clamp((apx * abx + apz * abz) / len2, 0, 1) or 0
	local dx, dz = apx - abx * t, apz - abz * t
	return math.sqrt(dx * dx + dz * dz)
end

local function pathDistance(x, z)
	local best = math.huge
	for _, path in ipairs(PATHS) do
		for i = 1, #path - 1 do
			local d = distToSegment(x, z, path[i], path[i + 1])
			if d < best then best = d end
		end
	end
	return best + noise2(x, z, 9, 15) * 1.4
end

local function baseHeight(t, x, z)
	local h
	if t <= 0.62 then
		local hills = (noise2(x, z, 70, 5) * 0.5 + 0.5) * 7 + noise2(x, z, 23, 6) * 1.6
		h = 6.5 + (0.62 - t) * 6 + hills * smoothstep(0.62, 0.45, t)
	elseif t <= 0.74 then
		h = lerp(6.5, 2.4, smoothstep(0.62, 0.74, t))           -- grassy bank
	elseif t <= 1.0 then
		h = lerp(2.4, -0.2, ((t - 0.74) / 0.26) ^ 1.15)          -- beach
	elseif t <= 1.18 then
		h = lerp(-0.2, -3.5, smoothstep(1.0, 1.18, t))           -- turquoise shallows
	else
		h = lerp(-3.5, -44, smoothstep(1.18, 1.7, t))            -- drop-off
		h += noise2(x, z, 40, 8) * 3 * smoothstep(1.2, 1.4, t)
	end
	if t > 0.72 and t < 1.2 then
		h += noise2(x, z, 13, 7) * 0.28                            -- sand ripples
	end
	return h
end

-- returns height, surface material, subsurface material
local function sampleColumn(x, z)
	local t = tAt(x, z)
	local bump = rockBump(x, z)
	local h = baseHeight(t, x, z) + bump
	h = math.max(h, -44)

	local surf, sub
	if bump > 1.4 and h > -8 then
		surf = (noise2(x, z, 11, 9) > 0.12) and M.Slate or M.Rock
		sub = M.Rock
	elseif h < -6 then
		surf = (noise2(x, z, 30, 10) > 0.28) and M.Rock or M.Sand
		sub = M.Sand
	else
		local edge = 0.715 + noise2(x, z, 16, 11) * 0.045
		if t > edge then
			surf, sub = M.Sand, M.Sand
		elseif t > edge - 0.035 then
			surf = (noise2(x, z, 5, 12) > 0) and M.Sand or M.Ground
			sub = M.Ground
		else
			sub = M.Ground
			local pd = pathDistance(x, z)
			if pd < 2.2 then
				surf = M.Ground
			elseif pd < 3.6 then
				surf = (noise2(x, z, 3, 13) > -0.05) and M.Ground or M.Grass
			else
				local n = noise2(x, z, 22, 14)
				if n > 0.22 then
					surf = M.LeafyGrass
				elseif n < -0.36 then
					surf = M.Ground
				else
					surf = M.Grass
				end
			end
		end
	end
	return h, surf, sub
end

-------------------------------------------------------------------------------
-- Terrain generation
-------------------------------------------------------------------------------
local function fillOcean()
	local size, chunk = CONFIG.OCEAN_SIZE, 512
	for cx = -size / 2, size / 2 - chunk, chunk do
		for cz = -size / 2, size / 2 - chunk, chunk do
			local x, z = cx + chunk / 2, cz + chunk / 2
			Terrain:FillBlock(CFrame.new(x, -22, z), Vector3.new(chunk, 44, chunk), M.Water)
			Terrain:FillBlock(CFrame.new(x, -48, z), Vector3.new(chunk, 8, chunk), M.Sand)
			task.wait()
		end
	end
end

local function generateIsland()
	local half = math.ceil(R0 * 2.2 / 4) * 4
	local Y0, Y1 = -52, 76
	local SLAB = 64
	local warned = false
	for sx = -half, half - 1, SLAB do
		local x0, x1 = sx, math.min(sx + SLAB, half)
		local region = Region3.new(Vector3.new(x0, Y0, -half), Vector3.new(x1, Y1, half))
		local nx, ny, nz = (x1 - x0) / 4, (Y1 - Y0) / 4, (2 * half) / 4
		local mats, occs, liqs = {}, {}, {}
		for ix = 1, nx do
			local mx, ox, lx = {}, {}, {}
			mats[ix], occs[ix], liqs[ix] = mx, ox, lx
			for iy = 1, ny do
				mx[iy], ox[iy], lx[iy] = {}, {}, {}
			end
			local x = x0 + (ix - 0.5) * 4
			for iz = 1, nz do
				local z = -half + (iz - 0.5) * 4
				local h, surf, sub = sampleColumn(x, z)
				for iy = 1, ny do
					local vy0 = Y0 + (iy - 1) * 4
					local occ = clamp((h - vy0) / 4, 0, 1)
					local m = M.Air
					if occ > 0 then
						m = (h - vy0) > 8 and sub or surf
					end
					mx[iy][iz] = m
					ox[iy][iz] = occ
					lx[iy][iz] = (vy0 < SEA and occ < 1) and 1 or 0
				end
			end
		end

		local ok = pcall(function()
			Terrain:WriteVoxelChannels(region, 4, {
				SolidMaterial = mats, SolidOccupancy = occs, LiquidOccupancy = liqs,
			})
		end)
		if not ok then
			if not warned then
				warned = true
				warn("[BeachChill] WriteVoxelChannels unavailable, falling back to WriteVoxels")
			end
			for ix = 1, nx do
				for iy = 1, ny do
					for iz = 1, nz do
						if liqs[ix][iy][iz] == 1 and occs[ix][iy][iz] < 0.5 then
							mats[ix][iy][iz] = M.Water
							occs[ix][iy][iz] = 1
						end
					end
				end
			end
			Terrain:WriteVoxels(region, 4, mats, occs)
		end
		task.wait()
	end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { Terrain }
rayParams.IgnoreWater = true

local function groundY(x, z)
	local res = Workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), rayParams)
	if res then return res.Position.Y end
	return (sampleColumn(x, z))
end
local function groundAt(v) return Vector3.new(v.X, groundY(v.X, v.Z), v.Z) end

local function terrainRocks()
	local clusters = { -140, -60, 30, 95, 160, 235, 280 }
	for _, deg in ipairs(clusters) do
		local c = polar(deg + rng:NextNumber(-4, 4), rng:NextNumber(0.99, 1.06))
		for _ = 1, rng:NextInteger(3, 5) do
			local p = c + Vector3.new(rng:NextNumber(-5, 5), 0, rng:NextNumber(-5, 5))
			local r = rng:NextNumber(1.6, 4.2)
			local y = math.max(groundY(p.X, p.Z), -3.5) + r * 0.25
			Terrain:FillBall(Vector3.new(p.X, y, p.Z), r, (rng:NextNumber() > 0.5) and M.Basalt or M.Rock)
		end
	end
	-- a few mossy boulders inland
	for _ = 1, 7 do
		local p = polar(rng:NextNumber(0, 360), rng:NextNumber(0.15, 0.6))
		if pathDistance(p.X, p.Z) > 6 then
			Terrain:FillBall(Vector3.new(p.X, groundY(p.X, p.Z) - 0.5, p.Z), rng:NextNumber(1.5, 3), M.Rock)
		end
	end
end

-------------------------------------------------------------------------------
-- Lighting / atmosphere / water
-------------------------------------------------------------------------------
local function setupEnvironment()
	pcall(function() Lighting.Technology = Enum.Technology.Future end)
	Lighting.ClockTime = CONFIG.TIME_OF_DAY
	Lighting.GeographicLatitude = 14
	Lighting.Brightness = 3
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.25
	Lighting.Ambient = rgb(72, 70, 78)
	Lighting.OutdoorAmbient = rgb(138, 132, 140)
	Lighting.ExposureCompensation = 0.1

	for _, c in ipairs(Lighting:GetChildren()) do
		if c.Name:sub(1, 3) == "BC_" or c:IsA("Atmosphere") then c:Destroy() end
	end

	local atmo = Instance.new("Atmosphere")
	atmo.Name = "BC_Atmosphere"
	atmo.Density = 0.28
	atmo.Offset = 0.22
	atmo.Color = rgb(206, 186, 170)
	atmo.Decay = rgb(110, 118, 132)
	atmo.Glare = 0.45
	atmo.Haze = 1.4
	atmo.Parent = Lighting

	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	sky.SunAngularSize = 13
	sky.MoonAngularSize = 9
	sky.StarCount = 3000
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "BC_Bloom"; bloom.Intensity = 0.55; bloom.Size = 26; bloom.Threshold = 1.25
	bloom.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Name = "BC_SunRays"; rays.Intensity = 0.07; rays.Spread = 0.75
	rays.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "BC_Color"; cc.Saturation = 0.12; cc.Contrast = 0.08; cc.Brightness = 0.02
	cc.TintColor = rgb(255, 247, 236)
	cc.Parent = Lighting

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "BC_DOF"; dof.FarIntensity = 0.12; dof.FocusDistance = 70; dof.InFocusRadius = 90; dof.NearIntensity = 0
	dof.Parent = Lighting

	local clouds = Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.52
	clouds.Density = 0.55
	clouds.Color = rgb(255, 250, 245)
	clouds.Parent = Terrain

	Terrain.WaterColor = rgb(18, 140, 150)
	Terrain.WaterTransparency = 0.9
	Terrain.WaterReflectance = 0.55
	Terrain.WaterWaveSize = 0.22
	Terrain.WaterWaveSpeed = 11
	pcall(function() Terrain.Decoration = true end) -- 3D animated grass

	local colors = {
		[M.Sand] = rgb(226, 208, 170),
		[M.Grass] = rgb(98, 142, 60),
		[M.LeafyGrass] = rgb(84, 126, 50),
		[M.Ground] = rgb(128, 104, 76),
		[M.Rock] = rgb(118, 114, 108),
		[M.Slate] = rgb(98, 96, 92),
		[M.Basalt] = rgb(70, 68, 66),
	}
	for mat, col in pairs(colors) do
		pcall(function() Terrain:SetMaterialColor(mat, col) end)
	end
end

-------------------------------------------------------------------------------
-- Vegetation
-------------------------------------------------------------------------------
local LEAF_GREENS = { rgb(64, 118, 44), rgb(78, 132, 50), rgb(58, 104, 40), rgb(92, 140, 56) }

local function buildFrond(parent, origin, phi, elev, len, opts)
	local steps = opts.steps or Q.frondSteps
	local segLen = len / steps
	local horiz = Vector3.new(math.cos(phi), 0, math.sin(phi))
	local dir = (horiz * math.cos(elev) + UP * math.sin(elev)).Unit
	local side = horiz:Cross(UP).Unit
	local droop = math.tan(math.rad(opts.droop or 12))
	local leafletMax = opts.leaflet or 4.2
	local dry = opts.dry
	local rachisColor = dry and rgb(150, 122, 72) or rgb(120, 128, 62)
	local pos = origin
	for k = 1, steps do
		local nextPos = pos + dir * segLen
		local thick = lerp(opts.rachis or 0.3, 0.1, k / steps)
		blockBetween(parent, pos, nextPos, thick, thick, rachisColor, M.Wood, DECO)
		if k >= 2 then
			local s = (k - 1) / (steps - 1)
			local leafLen = leafletMax * (math.sin(math.pi * clamp(s * 0.9 + 0.1, 0, 1)) ^ 0.7) + leafletMax * 0.12
			local start = pos:Lerp(nextPos, 0.5)
			for _, sgn in ipairs({ -1, 1 }) do
				local ldir = (side * sgn * 0.78 + dir * 0.5 - UP * 0.38).Unit
				local finish = start + ldir * leafLen
				local normal = ldir:Cross(dir)
				if normal.Magnitude < 1e-3 then normal = UP end
				local col
				if dry then
					col = jitterColor(rgb(166, 138, 82), 0.06)
				else
					col = jitterColor(LEAF_GREENS[rng:NextInteger(1, #LEAF_GREENS)], 0.05)
					if s > 0.85 and rng:NextNumber() < 0.35 then col = rgb(150, 150, 70) end -- sun-bleached tips
				end
				block(parent, Vector3.new(opts.leafWidth or 0.75, 0.06, leafLen),
					CFrame.lookAt((start + finish) / 2, finish, normal.Unit), col, M.Grass, DECO)
			end
		end
		pos = nextPos
		dir = (dir - UP * droop).Unit
	end
end

-- returns model, bezier(s) function, height
local function buildPalm(parent, base, opts)
	opts = opts or {}
	local height = opts.height or rng:NextNumber(24, 36)
	local lean = opts.lean or rng:NextNumber(4, 12)
	local leanDir = opts.leanDir or Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)).Unit
	local model = Instance.new("Model")
	model.Name = "PalmTree"

	local p0 = base
	local p1 = base + leanDir * lean * 0.85 + UP * height * 0.45
	local p2 = base + leanDir * lean + UP * height
	local function bez(s)
		local a, b = p0:Lerp(p1, s), p1:Lerp(p2, s)
		return a:Lerp(b, s)
	end

	local barkA, barkB, scar = rgb(126, 104, 80), rgb(104, 86, 68), rgb(84, 70, 56)
	local SEG = 16
	for i = 0, SEG - 1 do
		local s0, s1 = i / SEG, (i + 1) / SEG
		local a, b = bez(s0), bez(s1)
		local axis = (b - a).Unit
		local d = lerp(2.3, 1.35, s0 ^ 0.8)
		cylinderBetween(model, a, b + axis * 0.15, d, jitterColor(i % 2 == 0 and barkA or barkB, 0.035), M.Wood)
		-- leaf-scar ring
		cylinderBetween(model, a - axis * 0.13, a + axis * 0.13, d + 0.24, jitterColor(scar, 0.03), M.Wood, DECO)
	end
	-- root flare
	cylinderBetween(model, base - UP * 1.6, base + UP * 0.9, 3.3, barkB, M.Wood)
	ellipsoid(model, Vector3.new(4.2, 1.2, 4.2), CFrame.new(base + UP * 0.1), barkB, M.Wood, DECO)

	-- crown shaft
	local top = bez(1)
	local tangent = (bez(1) - bez(0.96)).Unit
	cylinderBetween(model, top - tangent * 1.4, top + tangent * 0.9, 1.75, rgb(104, 112, 62), M.Grass, DECO)

	-- coconuts
	for _ = 1, rng:NextInteger(3, 6) do
		local ang = rng:NextNumber(0, math.pi * 2)
		local off = Vector3.new(math.cos(ang), 0, math.sin(ang)) * rng:NextNumber(0.75, 1.15) - UP * rng:NextNumber(0.5, 1.5)
		local col = (rng:NextNumber() > 0.4) and rgb(104, 76, 46) or rgb(110, 132, 54)
		ball(model, rng:NextNumber(1.1, 1.4), top + off, col, M.Wood, DECO)
	end

	-- fronds
	local count = Q.fronds + rng:NextInteger(-1, 1)
	local phase = rng:NextNumber(0, math.pi * 2)
	for f = 1, count do
		local phi = phase + (f / count) * math.pi * 2 + rng:NextNumber(-0.22, 0.22)
		local lower = rng:NextNumber() < 0.35
		local elev = math.rad(lower and rng:NextNumber(-12, 10) or rng:NextNumber(15, 50))
		buildFrond(model, top + UP * 0.3, phi, elev, rng:NextNumber(12, 17), {
			droop = rng:NextNumber(9, 15),
			dry = rng:NextNumber() < 0.08,
		})
	end
	-- a couple of dead hanging fronds against the trunk
	for _ = 1, rng:NextInteger(0, 2) do
		buildFrond(model, top - UP * 0.6, rng:NextNumber(0, math.pi * 2), math.rad(-60), 7, { dry = true, droop = 4, leaflet = 2.2, steps = 4 })
	end

	model.Parent = parent
	return model, bez, height
end

local function buildBush(parent, pos)
	local m = Instance.new("Model")
	m.Name = "Bush"
	local n = rng:NextInteger(4, 8)
	local flower = rng:NextNumber() < 0.45
	local flowerCol = ({ rgb(222, 52, 72), rgb(240, 120, 160), rgb(250, 196, 60), rgb(250, 120, 60) })[rng:NextInteger(1, 4)]
	for _ = 1, n do
		local d = rng:NextNumber(2.2, 4.6)
		local off = Vector3.new(rng:NextNumber(-2, 2), d * rng:NextNumber(0.15, 0.35), rng:NextNumber(-2, 2))
		ball(m, d, pos + off, jitterColor(LEAF_GREENS[rng:NextInteger(1, #LEAF_GREENS)], 0.06), M.Grass, DECO)
		if flower then
			for _ = 1, 3 do
				local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.2, 1), rng:NextNumber(-1, 1)).Unit
				ball(m, rng:NextNumber(0.35, 0.55), pos + off + dir * d * 0.5, flowerCol, M.SmoothPlastic, DECO)
			end
		end
	end
	m.Parent = parent
end

local function buildFern(parent, pos)
	local m = Instance.new("Model")
	m.Name = "Fern"
	local n = rng:NextInteger(6, 9)
	local phase = rng:NextNumber(0, math.pi * 2)
	for i = 1, n do
		buildFrond(m, pos + UP * 0.2, phase + i / n * math.pi * 2, math.rad(rng:NextNumber(35, 60)), rng:NextNumber(3.2, 5.2), {
			steps = 5, leaflet = 1.1, droop = 15, leafWidth = 0.4, rachis = 0.14,
		})
	end
	m.Parent = parent
end

-------------------------------------------------------------------------------
-- Beach furniture
-------------------------------------------------------------------------------
local WOOD_TEAK = rgb(146, 104, 70)
local WOOD_DARK = rgb(92, 70, 52)
local ROPE = rgb(196, 176, 136)
local BAMBOO = rgb(198, 172, 112)
local STRAW = rgb(186, 156, 98)

local function buildUmbrella(parent, ground, colA, colB)
	local m = newModel("BeachUmbrella", parent)
	local tilt = CFrame.Angles(math.rad(rng:NextNumber(-5, 5)), 0, math.rad(rng:NextNumber(-5, 5)))
	local baseCF = CFrame.new(ground - UP * 1.2) * tilt * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
	local function W(x, y, z) return (baseCF * CFrame.new(x, y, z)).Position end
	local poleH = 10.2
	cylinderBetween(m, W(0, 0, 0), W(0, poleH + 0.6, 0), 0.3, rgb(236, 230, 218), M.Wood)
	cylinderBetween(m, W(0, poleH - 3.2, 0), W(0, poleH - 2.9, 0), 0.42, rgb(160, 160, 160), M.Metal, DECO)

	local apex = W(0, poleH + 0.7, 0)
	local ribs, radius, rimY = 10, 6.2, poleH - 0.9
	local rim = {}
	for i = 1, ribs do
		local a = (i / ribs) * math.pi * 2
		rim[i] = W(math.cos(a) * radius, rimY, math.sin(a) * radius)
	end
	for i = 1, ribs do
		local a, b = rim[i], rim[i % ribs + 1]
		local col = (i % 2 == 0) and colA or colB
		triangle(m, apex, a, b, 0.08, col, M.Fabric, DECO)
		-- rib under the canopy
		blockBetween(m, apex - UP * 0.15, a - UP * 0.12, 0.1, 0.1, rgb(220, 214, 200), M.Wood, DECO)
		cylinderBetween(m, W(0, poleH - 3.0, 0), apex:Lerp(a, 0.55) - UP * 0.2, 0.06, rgb(200, 200, 200), M.Metal, DECO)
		-- scalloped valance
		local edge = b - a
		local mid = (a + b) / 2 - UP * 0.36
		block(m, Vector3.new(edge.Magnitude, 0.7, 0.05), CFrame.fromMatrix(mid, edge.Unit, UP), col, M.Fabric, DECO)
	end
	ball(m, 0.45, apex + UP * 0.2, rgb(236, 230, 218), M.Wood, DECO)
	-- small sand mound around the pole
	ellipsoid(m, Vector3.new(1.6, 0.5, 1.6), CFrame.new(ground), rgb(214, 194, 156), M.Sand, DECO)
	return m
end

local function buildLounger(parent, cf, cushionColor, towelColors)
	local m = newModel("SunLounger", parent)
	local function C(x, y, z) return cf * CFrame.new(x, y, z) end
	for _, x in ipairs({ -1.2, 1.2 }) do
		block(m, Vector3.new(0.25, 0.35, 4.6), C(x, 1.15, -1.2), jitterColor(WOOD_TEAK, 0.03), M.Wood)
		for _, z in ipairs({ -3.3, 0.85 }) do
			block(m, Vector3.new(0.28, 1.9, 0.28), C(x, 0.2, z), jitterColor(WOOD_TEAK, 0.03), M.Wood)
		end
	end
	for z = -3.4, 0.8, 0.46 do
		block(m, Vector3.new(2.65, 0.12, 0.34), C(0, 1.38, z), jitterColor(WOOD_TEAK, 0.05), M.Wood)
	end
	local back = cf * CFrame.new(0, 1.38, 1.0) * CFrame.Angles(math.rad(-38), 0, 0)
	for _, x in ipairs({ -1.2, 1.2 }) do
		block(m, Vector3.new(0.25, 0.3, 3.3), back * CFrame.new(x, -0.15, 1.6), WOOD_TEAK, M.Wood)
		blockBetween(m, (back * CFrame.new(x, -0.25, 2.5)).Position, C(x, -0.5, 2.6).Position, 0.25, 0.25, WOOD_TEAK, M.Wood)
	end
	for z = 0.2, 3.1, 0.46 do
		block(m, Vector3.new(2.65, 0.12, 0.34), back * CFrame.new(0, 0.02, z), jitterColor(WOOD_TEAK, 0.05), M.Wood)
	end
	block(m, Vector3.new(2.35, 0.32, 4.3), C(0, 1.6, -1.3), cushionColor, M.Fabric)
	block(m, Vector3.new(2.35, 0.32, 3.0), back * CFrame.new(0, 0.24, 1.65), cushionColor, M.Fabric)
	ellipsoid(m, Vector3.new(1.7, 0.55, 0.9), back * CFrame.new(0, 0.62, 2.75), rgb(245, 242, 235), M.Fabric, DECO)
	local tw = 1.8
	for i, col in ipairs(towelColors) do
		local x = (i - (#towelColors + 1) / 2) * tw / #towelColors
		block(m, Vector3.new(tw / #towelColors, 0.05, 2.6), C(x, 1.79, -2.2), col, M.Fabric, DECO)
		block(m, Vector3.new(tw / #towelColors, 1.0, 0.05), C(x, 1.3, -3.5), col, M.Fabric, DECO)
	end
	make("Seat", m, { Size = Vector3.new(2, 0.4, 2), CFrame = C(0, 1.75, -0.6), Transparency = 1, CanCollide = false })
	return m
end

local function buildSideTable(parent, ground, drinkColor)
	local m = newModel("SideTable", parent)
	cylinderBetween(m, ground - UP * 0.6, ground + UP * 1.5, 0.25, WOOD_TEAK, M.Wood)
	cylinderBetween(m, ground + UP * 1.5, ground + UP * 1.66, 1.9, WOOD_TEAK, M.Wood)
	local top = ground + UP * 1.66
	-- cocktail
	local g = top + Vector3.new(0.35, 0, 0.1)
	cylinderBetween(m, g, g + UP * 0.95, 0.56, rgb(232, 242, 246), M.Glass, merge({ Transparency = 0.55 }, DECO))
	cylinderBetween(m, g + UP * 0.05, g + UP * 0.72, 0.48, drinkColor, M.SmoothPlastic, merge({ Transparency = 0.12 }, DECO))
	cylinderBetween(m, g + UP * 0.2, g + Vector3.new(0.25, 1.45, 0.1), 0.07, rgb(230, 60, 60), M.SmoothPlastic, DECO)
	cylinderBetween(m, g + Vector3.new(-0.3, 0.75, 0), g + Vector3.new(-0.3, 1.05, 0.1), 0.5, rgb(140, 200, 70), M.SmoothPlastic, DECO)
	-- coconut drink
	local c = top + Vector3.new(-0.4, 0.45, -0.25)
	ball(m, 0.9, c, rgb(110, 80, 50), M.Wood, DECO)
	cylinderBetween(m, c + UP * 0.38, c + UP * 0.45, 0.6, rgb(245, 240, 230), M.SmoothPlastic, DECO)
	cylinderBetween(m, c + UP * 0.3, c + Vector3.new(0.2, 1.2, 0.1), 0.07, rgb(250, 200, 60), M.SmoothPlastic, DECO)
	-- sunglasses
	local s = top + Vector3.new(0.1, 0.05, 0.55)
	ellipsoid(m, Vector3.new(0.35, 0.08, 0.28), CFrame.new(s + Vector3.new(-0.2, 0, 0)), rgb(25, 25, 30), M.Glass, DECO)
	ellipsoid(m, Vector3.new(0.35, 0.08, 0.28), CFrame.new(s + Vector3.new(0.2, 0, 0)), rgb(25, 25, 30), M.Glass, DECO)
	return m
end

local function buildTorch(parent, ground)
	local m = newModel("TikiTorch", parent)
	local top = ground + UP * 5.6
	cylinderBetween(m, ground - UP * 1.2, top, 0.42, jitterColor(BAMBOO, 0.04), M.Wood)
	for _, h in ipairs({ 1.5, 3.2, 4.8 }) do
		cylinderBetween(m, ground + UP * (h - 0.08), ground + UP * (h + 0.08), 0.5, rgb(150, 120, 80), M.Wood, DECO)
	end
	cylinderBetween(m, top, top + UP * 0.9, 0.85, rgb(110, 80, 50), M.Wood, DECO)
	cylinderBetween(m, top + UP * 0.9, top + UP * 1.0, 0.5, rgb(40, 34, 30), M.Fabric, DECO)
	local flame = block(m, Vector3.new(0.4, 0.4, 0.4), CFrame.new(top + UP * 1.3), rgb(0, 0, 0), M.SmoothPlastic, merge({ Transparency = 1 }, DECO))
	local fire = Instance.new("Fire")
	fire.Size = 2.4; fire.Heat = 7; fire.Color = rgb(255, 150, 50); fire.SecondaryColor = rgb(255, 70, 20)
	fire.Parent = flame
	addLight(flame, rgb(255, 160, 85), 14, 1.3, false, true)
	return m
end

-------------------------------------------------------------------------------
-- Beach bar (stilts, bamboo walls, layered thatch roof)
-------------------------------------------------------------------------------
local function buildBeachBar(parent, cf)
	local m = newModel("BeachBar", parent)
	local W, D, FH = 22, 18, 3.2
	local over = 2.5
	local function C(x, y, z) return cf * CFrame.new(x, y, z) end
	local function L(x, y, z) return cf:PointToWorldSpace(Vector3.new(x, y, z)) end

	-- stilts & joists
	for _, x in ipairs({ -10.5, 0, 10.5 }) do
		for _, z in ipairs({ -8.5, 0, 8.5 }) do
			cylinderBetween(m, L(x, -3, z), L(x, FH - 0.3, z), 1.1, jitterColor(WOOD_DARK, 0.04), M.Wood)
		end
	end
	for _, z in ipairs({ -8.5, 0, 8.5 }) do
		block(m, Vector3.new(W, 0.6, 0.6), C(0, FH - 0.45, z), WOOD_DARK, M.Wood)
	end
	-- floor planks
	for x = -W / 2 + 0.55, W / 2 - 0.5, 1.1 do
		block(m, Vector3.new(1.0, 0.3, D), C(x, FH, 0) * CFrame.Angles(0, math.rad(rng:NextNumber(-0.4, 0.4)), 0),
			jitterColor(rgb(150, 112, 78), 0.06), M.WoodPlanks)
	end
	-- front-left stairs
	for i = 1, 3 do
		block(m, Vector3.new(4, 0.35, 1.2), C(-8, FH - i * 0.85, -D / 2 - 0.6 - (i - 1) * 1.2), jitterColor(WOOD_TEAK, 0.05), M.WoodPlanks)
	end
	for _, x in ipairs({ -10.1, -5.9 }) do
		blockBetween(m, L(x, FH - 0.4, -D / 2), L(x, -0.4, -D / 2 - 3.6), 0.3, 0.7, WOOD_DARK, M.Wood)
	end

	-- corner / ridge posts (thick logs)
	for _, x in ipairs({ -10.6, 10.6 }) do
		for _, z in ipairs({ -8.6, 8.6 }) do
			cylinderBetween(m, L(x, FH, z), L(x, FH + 9.6, z), 1.15, jitterColor(WOOD_DARK, 0.04), M.Wood)
		end
		cylinderBetween(m, L(x, FH, 0), L(x, FH + 14, 0), 1.0, WOOD_DARK, M.Wood)
	end

	-- bamboo walls
	local step = Q.bamboo
	for x = -W / 2 + 0.4, W / 2 - 0.4, step do
		cylinderBetween(m, L(x, FH, 8.7), L(x, FH + 8 + rng:NextNumber(-0.15, 0.15), 8.7), 0.56, jitterColor(BAMBOO, 0.05), M.Wood)
	end
	for _, x in ipairs({ -10.9, 10.9 }) do
		for z = -7.6, 7.6, step do
			cylinderBetween(m, L(x, FH, z), L(x, FH + 3.6, z), 0.56, jitterColor(BAMBOO, 0.05), M.Wood)
		end
		cylinderBetween(m, L(x, FH + 3.7, -8.6), L(x, FH + 3.7, 8.6), 0.4, rgb(150, 120, 80), M.Wood)
	end

	-- bar counter
	local counterZ = -5.2
	for x = -3, 10.2, step do
		cylinderBetween(m, L(x, FH, counterZ), L(x, FH + 3.7, counterZ), 0.56, jitterColor(BAMBOO, 0.05), M.Wood)
	end
	block(m, Vector3.new(14.2, 0.4, 2.4), C(3.6, FH + 3.95, counterZ), rgb(112, 70, 44), M.Wood)
	block(m, Vector3.new(13.6, 0.25, 1.4), C(3.6, FH + 2.2, counterZ + 1.1), WOOD_DARK, M.Wood)

	-- back shelves with bottles
	local bottleCols = { rgb(60, 120, 60), rgb(160, 100, 40), rgb(230, 230, 220), rgb(120, 40, 40), rgb(60, 90, 140) }
	for _, y in ipairs({ FH + 4.2, FH + 5.9 }) do
		block(m, Vector3.new(16, 0.25, 1.0), C(0, y, 8.1), WOOD_DARK, M.Wood)
		for x = -7, 7, 2.1 do
			local bx = x + rng:NextNumber(-0.3, 0.3)
			local h = rng:NextNumber(0.9, 1.3)
			local col = bottleCols[rng:NextInteger(1, #bottleCols)]
			local b0 = L(bx, y + 0.12, 8.1)
			cylinderBetween(m, b0, b0 + UP * h, 0.45, col, M.Glass, merge({ Transparency = 0.25 }, DECO))
			cylinderBetween(m, b0 + UP * h, b0 + UP * (h + 0.45), 0.17, col, M.Glass, merge({ Transparency = 0.2 }, DECO))
		end
	end

	-- stools
	for _, x in ipairs({ 0, 3, 6, 9 }) do
		local s0 = L(x, FH + 0.15, counterZ - 2.1)
		cylinderBetween(m, s0, s0 + UP * 2.4, 0.3, WOOD_DARK, M.Wood)
		cylinderBetween(m, s0 + UP * 0.9, s0 + UP * 1.0, 1.1, WOOD_DARK, M.Wood, DECO)
		cylinderBetween(m, s0 + UP * 2.4, s0 + UP * 2.75, 1.6, rgb(160, 110, 70), M.Wood)
		make("Seat", m, { Size = Vector3.new(1.4, 0.3, 1.4), CFrame = CFrame.lookAt(s0 + UP * 2.95, s0 + UP * 2.95 + cf.LookVector * -1), Transparency = 1, CanCollide = false })
	end

	-- thatched gable roof (layered courses + hanging fringe)
	local ridgeY, eaveY = FH + 14, FH + 8.5
	local RX = W / 2 + over
	for _, s in ipairs({ -1, 1 }) do
		local E = Vector3.new(0, eaveY, s * (D / 2 + over))
		local Rg = Vector3.new(0, ridgeY, 0)
		local v = Rg - E
		local slopeLen = v.Magnitude
		local vh = v.Unit
		local normal = Vector3.xAxis:Cross(vh)
		if normal.Y < 0 then normal = -normal end
		local rows = 6
		local rowL = slopeLen / rows * 1.45
		for r = 0, rows - 1 do
			local centerL = E + vh * (r * slopeLen / rows + rowL / 2) + normal * (0.35 + (rows - r) * 0.06)
			local lcf = CFrame.fromMatrix(centerL, Vector3.xAxis, normal)
			block(m, Vector3.new(RX * 2, 0.7, rowL), cf * lcf, jitterColor(r % 2 == 0 and STRAW or rgb(170, 140, 86), 0.04), M.Grass)
		end
		-- rafters visible from below
		for x = -RX + 1, RX - 1, 4 do
			blockBetween(m, L(x, eaveY - 0.1, s * (D / 2 + over)), L(x, ridgeY - 0.1, 0), 0.4, 0.5, WOOD_DARK, M.Wood, DECO)
		end
		-- fringe
		for x = -RX, RX, Q.fringe do
			local len = rng:NextNumber(0.7, 1.7)
			local top = cf:PointToWorldSpace(E + Vector3.new(x, 0.1, 0) + normal * 0.3)
			block(m, Vector3.new(0.4, len, 0.14),
				CFrame.new(top - UP * len / 2) * (cf - cf.Position) * CFrame.Angles(math.rad(rng:NextNumber(-10, 10)) * s, 0, math.rad(rng:NextNumber(-6, 6))),
				jitterColor(STRAW, 0.07), M.Grass, DECO)
		end
	end
	-- gable ends
	for _, x in ipairs({ -RX + 0.4, RX - 0.4 }) do
		triangle(m, L(x, eaveY + 0.2, -(D / 2 + over) + 0.5), L(x, eaveY + 0.2, (D / 2 + over) - 0.5), L(x, ridgeY + 0.2, 0), 0.35, jitterColor(STRAW, 0.03), M.Grass)
	end
	cylinderBetween(m, L(-RX - 0.3, ridgeY + 0.75, 0), L(RX + 0.3, ridgeY + 0.75, 0), 1.4, rgb(150, 120, 70), M.Grass)

	-- hanging sign
	local sign = block(m, Vector3.new(9, 1.8, 0.25), C(0, eaveY - 1.6, -(D / 2 + over) + 0.4), rgb(120, 80, 50), M.WoodPlanks)
	for _, x in ipairs({ -3.8, 3.8 }) do
		cylinderBetween(m, L(x, eaveY - 0.7, -(D / 2 + over) + 0.4), L(x, eaveY + 0.2, -(D / 2 + over) + 0.4), 0.08, ROPE, M.Fabric, DECO)
	end
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 1
	sg.Parent = sign
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = "CHILL BAR"
	tl.TextScaled = true
	tl.Font = Enum.Font.FredokaOne
	tl.TextColor3 = rgb(250, 238, 210)
	tl.TextStrokeTransparency = 0.5
	tl.Parent = sg

	-- string lights along the front eave
	local bulbCols = { rgb(255, 214, 140), rgb(255, 170, 110), rgb(255, 236, 190) }
	local a0, a1 = L(-RX, eaveY - 0.4, -(D / 2 + over) + 0.2), L(RX, eaveY - 0.4, -(D / 2 + over) + 0.2)
	local count = 0
	for seg = 0, 2 do
		local pa, pb = a0:Lerp(a1, seg / 3), a0:Lerp(a1, (seg + 1) / 3)
		local pts = rope(m, pa, pb, 0.9, 8, 0.06, rgb(30, 30, 30))
		for i = 2, #pts - 1, 2 do
			count += 1
			local bulb = ball(m, 0.38, pts[i] - UP * 0.2, bulbCols[count % 3 + 1], M.Neon, DECO)
			if count % 4 == 0 then addLight(bulb, rgb(255, 196, 130), 9, 0.8) end
		end
	end

	-- lantern inside
	local lp = L(0, FH + 9.5, 0)
	cylinderBetween(m, lp, lp + UP * 2.5, 0.08, rgb(40, 40, 40), M.Metal, DECO)
	block(m, Vector3.new(0.9, 1.2, 0.9), CFrame.new(lp - UP * 0.6), rgb(255, 236, 200), M.Glass, merge({ Transparency = 0.45 }, DECO))
	local core = ball(m, 0.45, lp - UP * 0.6, rgb(255, 196, 120), M.Neon, DECO)
	addLight(core, rgb(255, 190, 120), 20, 1.4, true, true)

	-- surfboards leaning on the right wall
	local boardCols = { { rgb(240, 236, 226), rgb(30, 140, 160) }, { rgb(250, 190, 70), rgb(230, 80, 60) }, { rgb(80, 170, 200), rgb(250, 250, 250) } }
	for i, cols in ipairs(boardCols) do
		local z = -5 + i * 3.2
		local bcf = cf * CFrame.new(12.4, 4.0, z) * CFrame.Angles(0, 0, math.rad(13)) * CFrame.Angles(math.rad(rng:NextNumber(-4, 4)), 0, 0)
		ellipsoid(m, Vector3.new(0.28, 8.6, 2.2), bcf, cols[1], M.SmoothPlastic)
		ellipsoid(m, Vector3.new(0.3, 8.0, 0.35), bcf, cols[2], M.SmoothPlastic, DECO)
	end
	return m
end

-------------------------------------------------------------------------------
-- Dock, rowboat, life ring
-------------------------------------------------------------------------------
local function buildRowboat(parent, cf)
	local m = newModel("Rowboat", parent)
	local hullCol, trim = rgb(54, 116, 128), rgb(236, 232, 222)
	local N = 8
	local function w(u) return 2.3 * (1 - u ^ 2.5) ^ 0.55 * (0.82 + 0.18 * math.sin(math.min(u, 0.5) * math.pi)) end
	local function topY(u) return 1.1 + 0.45 * u ^ 3 end
	local function botY(u) return -0.5 + 0.7 * u ^ 3 end
	local function z(u) return 6 - 12 * u end
	local function P(x, y, zz) return cf:PointToWorldSpace(Vector3.new(x, y, zz)) end
	for i = 0, N - 1 do
		local u0, u1 = i / N, (i + 1) / N
		for _, sx in ipairs({ -1, 1 }) do
			local tA, tB = P(sx * w(u0), topY(u0), z(u0)), P(sx * w(u1), topY(u1), z(u1))
			local bA, bB = P(sx * w(u0) * 0.55, botY(u0), z(u0)), P(sx * w(u1) * 0.55, botY(u1), z(u1))
			quad(m, tA, tB, bB, bA, 0.16, hullCol, M.Wood)
			blockBetween(m, tA + UP * 0.08, tB + UP * 0.08, 0.25, 0.22, trim, M.Wood, DECO)
		end
		quad(m, P(-w(u0) * 0.55, botY(u0), z(u0)), P(-w(u1) * 0.55, botY(u1), z(u1)), P(w(u1) * 0.55, botY(u1), z(u1)), P(w(u0) * 0.55, botY(u0), z(u0)), 0.16, hullCol, M.Wood)
	end
	quad(m, P(-w(0), topY(0), 6), P(w(0), topY(0), 6), P(w(0) * 0.55, botY(0), 6), P(-w(0) * 0.55, botY(0), 6), 0.2, trim, M.Wood)
	for _, x in ipairs({ -0.6, 0, 0.6 }) do
		block(m, Vector3.new(0.5, 0.1, 8), cf * CFrame.new(x, -0.3, 0.6), rgb(150, 112, 78), M.WoodPlanks, DECO)
	end
	for _, u in ipairs({ 0.28, 0.58 }) do
		block(m, Vector3.new(w(u) * 1.9, 0.22, 0.9), cf * CFrame.new(0, 0.55, z(u)), rgb(150, 112, 78), M.Wood)
	end
	for _, sx in ipairs({ -1, 1 }) do
		local a, b = P(sx * 0.9, 0.75, 4.2), P(sx * 0.4, 0.75, -3.4)
		cylinderBetween(m, a, b, 0.16, rgb(170, 130, 90), M.Wood, DECO)
		blockBetween(m, b, b + (b - a).Unit * 1.6, 0.6, 0.08, rgb(170, 130, 90), M.Wood, DECO)
	end
	-- welded assembly so the boat can bob efficiently
	local root = block(m, Vector3.new(1, 1, 1), cf, rgb(0, 0, 0), M.SmoothPlastic, merge({ Transparency = 1, Name = "BoatRoot" }, DECO))
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") and p ~= root then
			local wc = Instance.new("WeldConstraint")
			wc.Part0 = root
			wc.Part1 = p
			wc.Parent = p
			p.Anchored = false
			p.Massless = true
		end
	end
	m.PrimaryPart = root
	root:SetAttribute("BaseCFrame", cf)
	CollectionService:AddTag(root, "BC_Bob")
	return m
end

local function buildLifeRing(parent, center, axis)
	local a1 = axis:Cross(UP).Unit
	local a2 = UP
	local prev
	for i = 0, 12 do
		local ang = i / 12 * math.pi * 2
		local p = center + (a1 * math.cos(ang) + a2 * math.sin(ang)) * 1.05
		if prev then
			cylinderBetween(parent, prev, p, 0.48, (i % 3 == 0) and rgb(240, 240, 240) or rgb(220, 50, 40), M.SmoothPlastic, DECO)
		end
		prev = p
	end
end

local function buildDock(parent, start, dir, length)
	local m = newModel("Dock", parent)
	local DECK_Y = 2.4
	local s = Vector3.new(start.X, DECK_Y, start.Z)
	local dcf = CFrame.lookAt(s, s + dir)
	local function D(x, y, z) return dcf:PointToWorldSpace(Vector3.new(x, y, z)) end
	local platform = 14

	-- planks
	local dist = 0
	while dist < length do
		local wide = dist > length - platform
		local width = wide and 17 or 9.4
		block(m, Vector3.new(width, 0.32, 1.0), dcf * CFrame.new(0, 0, -(dist + 0.5)) * CFrame.Angles(0, math.rad(rng:NextNumber(-0.7, 0.7)), 0),
			jitterColor(rgb(140, 108, 78), 0.07), M.WoodPlanks)
		dist += 1.12
	end
	-- stringers
	for _, x in ipairs({ -3.8, 0, 3.8 }) do
		block(m, Vector3.new(0.6, 0.7, length), dcf * CFrame.new(x, -0.55, -length / 2), WOOD_DARK, M.Wood)
	end
	for _, x in ipairs({ -7.6, 7.6 }) do
		block(m, Vector3.new(0.6, 0.7, platform), dcf * CFrame.new(x, -0.55, -(length - platform / 2)), WOOD_DARK, M.Wood)
	end
	block(m, Vector3.new(17, 0.7, 0.6), dcf * CFrame.new(0, -0.55, -(length - platform)), WOOD_DARK, M.Wood)

	-- posts
	local function post(x, z, railTop)
		local top = D(x, railTop and 2.9 or 0.5, z)
		local g = groundY(top.X, top.Z)
		local bottom = Vector3.new(top.X, g - 2.5, top.Z)
		cylinderBetween(m, bottom, top, 1.0, jitterColor(rgb(92, 72, 55), 0.04), M.Wood)
		if g < SEA then
			cylinderBetween(m, Vector3.new(top.X, -1.3, top.Z), Vector3.new(top.X, 0.25, top.Z), 1.08, rgb(74, 86, 56), M.Slate, DECO) -- algae line
		end
		return top
	end
	local left, right = {}, {}
	for d = 0, length - platform, 9 do
		table.insert(left, post(-5.0, -d, true))
		table.insert(right, post(5.0, -d, true))
	end
	for d = length - platform, length, 7 do
		table.insert(left, post(-8.6, -d, true))
		table.insert(right, post(8.6, -d, true))
	end
	post(0, -length, false)
	for _, rail in ipairs({ left, right }) do
		for i = 1, #rail - 1 do
			rope(m, rail[i] - UP * 0.3, rail[i + 1] - UP * 0.3, 0.55, 4, 0.18, ROPE)
		end
	end

	-- lamp posts at the end
	for _, x in ipairs({ -7.8, 7.8 }) do
		local b = D(x, 0.2, -(length - 0.8))
		cylinderBetween(m, b, b + UP * 7.2, 0.45, rgb(58, 50, 44), M.Wood)
		local arm = b + UP * 7.0
		local lantern = arm + dcf.RightVector * (x > 0 and -0.9 or 0.9) - UP * 0.6
		blockBetween(m, arm, arm + dcf.RightVector * (x > 0 and -1.1 or 1.1), 0.2, 0.2, rgb(58, 50, 44), M.Wood, DECO)
		block(m, Vector3.new(0.95, 1.25, 0.95), CFrame.new(lantern), rgb(255, 240, 210), M.Glass, merge({ Transparency = 0.45 }, DECO))
		block(m, Vector3.new(1.15, 0.2, 1.15), CFrame.new(lantern + UP * 0.72), rgb(40, 40, 40), M.Metal, DECO)
		local core = ball(m, 0.5, lantern, rgb(255, 200, 130), M.Neon, DECO)
		addLight(core, rgb(255, 190, 120), 18, 1.5, true)
	end

	-- bench facing the sea
	local bz = -(length - 6)
	block(m, Vector3.new(6, 0.3, 1.6), dcf * CFrame.new(0, 1.6, bz), WOOD_TEAK, M.Wood)
	block(m, Vector3.new(6, 1.4, 0.25), dcf * CFrame.new(0, 2.7, bz + 0.85) * CFrame.Angles(math.rad(-10), 0, 0), WOOD_TEAK, M.Wood)
	for _, x in ipairs({ -2.6, 2.6 }) do
		block(m, Vector3.new(0.3, 1.5, 1.4), dcf * CFrame.new(x, 0.85, bz), WOOD_DARK, M.Wood)
	end
	make("Seat", m, { Size = Vector3.new(4, 0.3, 1.4), CFrame = dcf * CFrame.new(0, 1.8, bz), Transparency = 1, CanCollide = false })

	-- ladder into the water
	local lz = -(length - 3)
	for _, z in ipairs({ lz - 0.8, lz + 0.8 }) do
		cylinderBetween(m, D(9.0, 1.4, z), D(9.0, -5, z), 0.22, rgb(170, 170, 170), M.Metal, DECO)
	end
	for y = -4.5, 0, 0.9 do
		cylinderBetween(m, D(9.0, y, lz - 0.8), D(9.0, y, lz + 0.8), 0.14, rgb(170, 170, 170), M.Metal, DECO)
	end

	-- life ring on a post, bucket and fishing rod
	buildLifeRing(m, D(-8.6, 1.4, -(length - 7)) - dcf.RightVector * 0.6, dcf.RightVector)
	local bk = D(5.5, 0.16, -(length - 2.5))
	cylinderBetween(m, bk, bk + UP * 1.0, 1.0, rgb(70, 110, 160), M.SmoothPlastic, DECO)
	cylinderBetween(m, D(4.5, 0.3, -(length - 2.2)), D(5.8, 6.0, -(length + 2.5)), 0.09, rgb(40, 40, 40), M.Metal, DECO)

	-- moored rowboat
	local boatPos = D(-13, -DECK_Y + 0.15, -(length - 7))
	local boatCF = CFrame.lookAt(boatPos, boatPos + dir) * CFrame.Angles(0, math.rad(6), 0)
	local boat = buildRowboat(parent, boatCF)
	rope(m, (boatCF * CFrame.new(0, 1.3, -5.5)).Position, D(-8.6, 0.6, -(length - 12)), 0.8, 6, 0.12, ROPE)
	return m, boat
end

-------------------------------------------------------------------------------
-- Campfire, hammock, beach clutter
-------------------------------------------------------------------------------
local function buildCampfire(parent, center)
	local m = newModel("Campfire", parent)
	ellipsoid(m, Vector3.new(4.6, 0.3, 4.6), CFrame.new(center + UP * 0.05), rgb(54, 50, 48), M.Slate, DECO)
	for i = 1, 11 do
		local a = i / 11 * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * 2.6, 0.25, math.sin(a) * 2.6)
		ellipsoid(m, Vector3.new(rng:NextNumber(1.1, 1.6), rng:NextNumber(0.7, 1.0), rng:NextNumber(0.9, 1.3)),
			CFrame.new(p) * CFrame.Angles(0, a + rng:NextNumber(-0.3, 0.3), rng:NextNumber(-0.2, 0.2)), jitterColor(rgb(110, 106, 100), 0.07), M.Slate)
	end
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		cylinderBetween(m, center + Vector3.new(math.cos(a) * 1.7, 0.2, math.sin(a) * 1.7), center + UP * 2.1 + Vector3.new(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2)),
			0.42, rgb(60, 44, 34), M.Wood, DECO)
	end
	cylinderBetween(m, center + UP * 0.12, center + UP * 0.22, 2.0, rgb(255, 110, 30), M.Neon, DECO)
	local emitter = block(m, Vector3.new(0.5, 0.5, 0.5), CFrame.new(center + UP * 1.1), rgb(0, 0, 0), M.SmoothPlastic, merge({ Transparency = 1 }, DECO))
	local fire = Instance.new("Fire")
	fire.Size = 5.5; fire.Heat = 12; fire.Color = rgb(255, 140, 40); fire.SecondaryColor = rgb(255, 60, 10)
	fire.Parent = emitter
	local smoke = Instance.new("Smoke")
	smoke.Opacity = 0.07; smoke.RiseVelocity = 4; smoke.Size = 3; smoke.Color = rgb(120, 120, 120)
	smoke.Parent = emitter
	addLight(emitter, rgb(255, 150, 70), 26, 2.2, true, true)

	-- log benches
	for i = 0, 2 do
		local a = math.rad(-40 + i * 80) + math.atan2(-center.Z, -center.X) -- face inland side of the fire
		local c = center + Vector3.new(math.cos(a), 0, math.sin(a)) * 6.8
		local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
		local y = groundY(c.X, c.Z)
		local p = Vector3.new(c.X, y + 0.55, c.Z)
		cylinderBetween(m, p - tangent * 3.2, p + tangent * 3.2, 1.7, jitterColor(rgb(112, 84, 60), 0.05), M.Wood)
		cylinderBetween(m, p - tangent * 3.25, p - tangent * 3.15, 1.5, rgb(186, 150, 110), M.Wood, DECO) -- cut end
		cylinderBetween(m, p + tangent * 3.15, p + tangent * 3.25, 1.5, rgb(186, 150, 110), M.Wood, DECO)
		local seatPos = p + UP * 0.95
		make("Seat", m, { Size = Vector3.new(2, 0.3, 1.2), CFrame = CFrame.lookAt(seatPos, Vector3.new(center.X, seatPos.Y, center.Z)), Transparency = 1, CanCollide = false })
	end
	-- marshmallow sticks
	for i = 1, 2 do
		local a = rng:NextNumber(0, math.pi * 2)
		local b = center + Vector3.new(math.cos(a) * 4.2, 0, math.sin(a) * 4.2)
		local tip = center + Vector3.new(math.cos(a) * 1.4, 1.6, math.sin(a) * 1.4)
		cylinderBetween(m, b, tip, 0.1, rgb(130, 100, 70), M.Wood, DECO)
		cylinderBetween(m, tip, tip + (tip - b).Unit * 0.35, 0.3, rgb(250, 240, 225), M.SmoothPlastic, DECO)
	end
	return m
end

local function buildHammock(parent, A, B)
	local m = newModel("Hammock", parent)
	local span = B - A
	local fwd = flat(span).Unit
	local side = fwd:Cross(UP).Unit
	local sag = 3.6
	local function P(u) return A:Lerp(B, u) - UP * sag * 4 * u * (1 - u) end
	local u0, u1, W = 0.2, 0.8, 3.3
	for _, u in ipairs({ u0, u1 }) do
		local c = P(u)
		cylinderBetween(m, c - side * (W / 2 + 0.25), c + side * (W / 2 + 0.25), 0.22, WOOD_TEAK, M.Wood, DECO)
		local anchor = (u == u0) and A or B
		for _, sgn in ipairs({ -1, -0.5, 0, 0.5, 1 }) do
			cylinderBetween(m, anchor, c + side * sgn * (W / 2), 0.07, ROPE, M.Fabric, DECO)
		end
		cylinderBetween(m, anchor - UP * 0.25, anchor + UP * 0.25, 2.0, ROPE, M.Fabric, DECO) -- wrap around trunk
	end
	local stripes = { rgb(196, 72, 58), rgb(242, 230, 204), rgb(46, 120, 128), rgb(242, 230, 204), rgb(196, 72, 58) }
	local sw = W / #stripes
	local SEG = 12
	for i = 0, SEG - 1 do
		local ua, ub = lerp(u0, u1, i / SEG), lerp(u0, u1, (i + 1) / SEG)
		local a, b = P(ua), P(ub)
		local base = safeLookAt((a + b) / 2, b)
		local cup = math.sin(math.pi * ((ua + ub) / 2 - u0) / (u1 - u0))
		for k, col in ipairs(stripes) do
			local off = (k - (#stripes + 1) / 2) * sw
			local lift = (off / (W / 2)) ^ 2 * 0.5 * cup
			block(m, Vector3.new(sw + 0.03, 0.1, (b - a).Magnitude + 0.05), base * CFrame.new(off, lift, 0), col, M.Fabric, DECO)
		end
	end
	ellipsoid(m, Vector3.new(1.8, 0.5, 1.0), CFrame.lookAt(P(0.27) + UP * 0.35, P(0.27) + UP * 0.35 + side), rgb(245, 240, 230), M.Fabric, DECO)
	local mid = P(0.5) + UP * 0.4
	make("Seat", m, { Size = Vector3.new(2, 0.3, 2), CFrame = CFrame.lookAt(mid, mid + side), Transparency = 1, CanCollide = false })
	return m
end

local function buildStarfish(parent, ground)
	local m = newModel("Starfish", parent)
	local col = ({ rgb(232, 120, 60), rgb(214, 80, 70), rgb(240, 170, 90) })[rng:NextInteger(1, 3)]
	local rot = rng:NextNumber(0, math.pi * 2)
	for i = 1, 5 do
		local a = rot + i / 5 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		ellipsoid(m, Vector3.new(0.32, 0.14, 0.9), CFrame.lookAt(ground + dir * 0.4 + UP * 0.05, ground + dir + UP * 0.05), col, M.Sand, DECO)
	end
	ellipsoid(m, Vector3.new(0.45, 0.18, 0.45), CFrame.new(ground + UP * 0.07), col, M.Sand, DECO)
end

local function buildShell(parent, ground)
	local col = ({ rgb(245, 232, 215), rgb(236, 196, 186), rgb(220, 200, 170), rgb(250, 245, 240) })[rng:NextInteger(1, 4)]
	if rng:NextNumber() < 0.3 then
		cylinderBetween(parent, ground, ground + UP * 0.06, 0.8, rgb(232, 222, 200), M.Sand, DECO) -- sand dollar
	else
		local s = rng:NextNumber(0.35, 0.7)
		ellipsoid(parent, Vector3.new(s, s * 0.45, s * 1.25), CFrame.new(ground) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), col, M.Marble, DECO)
	end
end

local function buildDriftwood(parent, ground)
	local m = newModel("Driftwood", parent)
	local len = rng:NextNumber(5, 10)
	local a = rng:NextNumber(0, math.pi * 2)
	local dir = Vector3.new(math.cos(a), rng:NextNumber(-0.05, 0.08), math.sin(a)).Unit
	local col = jitterColor(rgb(176, 166, 150), 0.05)
	local p0 = ground + UP * 0.3
	cylinderBetween(m, p0 - dir * len / 2, p0 + dir * len / 2, rng:NextNumber(0.7, 1.2), col, M.Wood)
	for _ = 1, 2 do
		local b = p0 + dir * rng:NextNumber(-len / 3, len / 3)
		local bd = (Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.2, 0.8), rng:NextNumber(-1, 1))).Unit
		cylinderBetween(m, b, b + bd * rng:NextNumber(1, 2.4), 0.35, col, M.Wood, DECO)
	end
end

local function buildTowelSpot(parent, ground, out)
	local m = newModel("TowelSpot", parent)
	local side = out:Cross(UP).Unit
	local sets = { { rgb(240, 90, 80), rgb(250, 240, 220), rgb(240, 90, 80) }, { rgb(40, 120, 170), rgb(250, 210, 80), rgb(40, 120, 170), rgb(250, 210, 80) } }
	for t, cols in ipairs(sets) do
		local c = ground + side * ((t - 1.5) * 4)
		local cf = CFrame.lookAt(Vector3.new(c.X, groundY(c.X, c.Z) + 0.04, c.Z), Vector3.new(c.X, groundY(c.X, c.Z) + 0.04, c.Z) + out)
		local w = 3 / #cols
		for i, col in ipairs(cols) do
			block(m, Vector3.new(w, 0.06, 6), cf * CFrame.new((i - (#cols + 1) / 2) * w, 0, 0), col, M.Fabric, DECO)
		end
	end
	-- cooler
	local cpos = ground - out * 4 + side * 0.5
	local cg = groundY(cpos.X, cpos.Z)
	local ccf = CFrame.lookAt(Vector3.new(cpos.X, cg + 0.75, cpos.Z), Vector3.new(cpos.X, cg + 0.75, cpos.Z) + side)
	block(m, Vector3.new(2.4, 1.5, 1.5), ccf, rgb(40, 110, 170), M.SmoothPlastic)
	block(m, Vector3.new(2.5, 0.3, 1.6), ccf * CFrame.new(0, 0.85, 0), rgb(245, 245, 245), M.SmoothPlastic)
	-- beach ball, bucket & spade, little sandcastle
	local bb = ground + out * 4.5 + side * 3
	ball(m, 1.6, Vector3.new(bb.X, groundY(bb.X, bb.Z) + 0.75, bb.Z), rgb(230, 60, 60), M.SmoothPlastic)
	local sc = ground + out * 5 - side * 3
	local sy = groundY(sc.X, sc.Z)
	local sand = rgb(214, 192, 150)
	cylinderBetween(m, Vector3.new(sc.X, sy - 0.2, sc.Z), Vector3.new(sc.X, sy + 1.3, sc.Z), 2.2, sand, M.Sand)
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2
		local tp = Vector3.new(sc.X + math.cos(a) * 1.5, sy - 0.2, sc.Z + math.sin(a) * 1.5)
		cylinderBetween(m, tp, tp + UP * 1.0, 0.9, sand, M.Sand, DECO)
	end
	local bk = sc + side * 2
	local by = groundY(bk.X, bk.Z)
	cylinderBetween(m, Vector3.new(bk.X, by, bk.Z), Vector3.new(bk.X, by + 0.9, bk.Z), 0.9, rgb(250, 200, 50), M.SmoothPlastic, DECO)
	blockBetween(m, Vector3.new(bk.X + 0.8, by + 0.05, bk.Z), Vector3.new(bk.X + 0.8, by + 0.6, bk.Z + 1.6), 0.4, 0.06, rgb(60, 150, 220), M.SmoothPlastic, DECO)
	return m
end

-------------------------------------------------------------------------------
-- Placement bookkeeping
-------------------------------------------------------------------------------
local zones = {}
local function reserve(pos, r) table.insert(zones, { p = flat(pos), r = r }) end
local function isFree(pos, r)
	local f = flat(pos)
	for _, z in ipairs(zones) do
		if (f - z.p).Magnitude < z.r + r then return false end
	end
	return true
end

-------------------------------------------------------------------------------
-- Build everything
-------------------------------------------------------------------------------
local function build()
	local t0 = os.clock()
	local old = Workspace:FindFirstChild(MAP_NAME)
	if old then old:Destroy() end
	if CONFIG.CLEAR_TERRAIN then Terrain:Clear() end

	local map = Instance.new("Folder")
	map.Name = MAP_NAME
	map.Parent = Workspace
	local F = {}
	for _, n in ipairs({ "Palms", "Plants", "Lounge", "BeachBar", "Dock", "Campfire", "Hammock", "Details", "Paths" }) do
		F[n] = Instance.new("Folder")
		F[n].Name = n
		F[n].Parent = map
	end

	print("[BeachChill] environment...")
	setupEnvironment()
	print("[BeachChill] ocean...")
	fillOcean()
	print("[BeachChill] island terrain...")
	generateIsland()
	terrainRocks()

	-- reserve structure footprints
	reserve(LAYOUT.bar, 17)
	reserve(LAYOUT.lounge, 25)
	reserve(LAYOUT.campfire, 11)
	reserve(LAYOUT.spawn, 6)
	reserve(LAYOUT.towels, 8)
	reserve(LAYOUT.hammockA:Lerp(LAYOUT.hammockB, 0.5), 9)
	for d = 0, 30, 6 do reserve(LAYOUT.dockStart + outward(LAYOUT.dockStart) * d, 7) end
	reserve(ROCKS[1].pos, 20)

	-- spawn
	local sp = groundAt(LAYOUT.spawn)
	local spawn = make("SpawnLocation", map, {
		Size = Vector3.new(6, 1, 6), CFrame = CFrame.lookAt(sp + UP * 0.6, sp + UP * 0.6 + outward(sp)),
		Transparency = 1, CanCollide = false, Neutral = true, Duration = 0, Name = "BeachSpawn",
	})
	if CONFIG.DISABLE_OTHER_SPAWNS then
		for _, d in ipairs(Workspace:GetDescendants()) do
			if d:IsA("SpawnLocation") and d ~= spawn then d.Enabled = false end
		end
	end

	print("[BeachChill] beach bar...")
	local barPos = groundAt(LAYOUT.bar)
	buildBeachBar(F.BeachBar, CFrame.lookAt(barPos, barPos + outward(barPos)))

	print("[BeachChill] lounge...")
	do
		local C = groundAt(LAYOUT.lounge)
		local out = outward(C)
		local tangent = UP:Cross(out).Unit
		local umbrellaCols = { { rgb(245, 242, 232), rgb(30, 140, 150) }, { rgb(245, 242, 232), rgb(232, 96, 76) }, { rgb(240, 228, 196), rgb(36, 64, 110) } }
		local cushions = { rgb(32, 128, 140), rgb(224, 110, 88), rgb(40, 70, 118) }
		local towels = { { rgb(250, 210, 80), rgb(250, 250, 245), rgb(250, 210, 80) }, { rgb(80, 180, 200), rgb(250, 250, 245), rgb(80, 180, 200) } }
		local drinks = { rgb(255, 140, 60), rgb(240, 90, 120), rgb(120, 210, 230) }
		for i = -1, 1 do
			local uc = C + tangent * i * 15
			buildUmbrella(F.Lounge, groundAt(uc - out * 1.6), umbrellaCols[i + 2][1], umbrellaCols[i + 2][2])
			for k, sgn in ipairs({ -1, 1 }) do
				local p = groundAt(uc + tangent * sgn * 2.3)
				buildLounger(F.Lounge, CFrame.lookAt(p, p + out), cushions[i + 2], towels[k])
			end
			buildSideTable(F.Lounge, groundAt(uc + out * 1.2), drinks[i + 2])
		end
	end

	print("[BeachChill] dock...")
	local dockStart = groundAt(LAYOUT.dockStart)
	buildDock(F.Dock, dockStart, outward(dockStart), 92)

	print("[BeachChill] campfire...")
	local fireC = groundAt(LAYOUT.campfire)
	buildCampfire(F.Campfire, fireC)
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		buildTorch(F.Campfire, groundAt(fireC + Vector3.new(math.cos(a), 0, math.sin(a)) * 10))
	end
	for _, spot in ipairs({ polar(-20, 0.8), polar(14, 0.82), polar(32, 0.84), polar(72, 0.86) }) do
		buildTorch(F.Details, groundAt(spot))
		reserve(spot, 2)
	end

	print("[BeachChill] palms & hammock...")
	local palms = {}
	do
		local pA, pB = groundAt(LAYOUT.hammockA), groundAt(LAYOUT.hammockB)
		local towardB = flat(pB - pA).Unit
		local _, bezA, hA = buildPalm(F.Palms, pA - UP * 0.8, { height = 27, lean = 3.5, leanDir = (outward(pA) - towardB * 0.5).Unit })
		local _, bezB, hB = buildPalm(F.Palms, pB - UP * 0.8, { height = 29, lean = 3.5, leanDir = (outward(pB) + towardB * 0.5).Unit })
		table.insert(palms, flat(pA)); table.insert(palms, flat(pB))
		buildHammock(F.Hammock, bezA(6.5 / hA) + towardB * 0.9, bezB(6.5 / hB) - towardB * 0.9)
	end
	local tries = 0
	while #palms < Q.palms + 2 and tries < 3000 do
		tries += 1
		local t = rng:NextNumber(0.5, 0.86)
		local p = polar(rng:NextNumber(0, 360), t)
		local ok = isFree(p, 3) and pathDistance(p.X, p.Z) > 3.5
		if ok then
			for _, q in ipairs(palms) do
				if (q - flat(p)).Magnitude < 12 then ok = false break end
			end
		end
		if ok then
			local g = groundAt(p)
			if g.Y > 0.8 then
				local out = outward(p)
				local leanDir = (out + Vector3.new(rng:NextNumber(-0.7, 0.7), 0, rng:NextNumber(-0.7, 0.7))).Unit
				buildPalm(F.Palms, g - UP * 0.8, { lean = lerp(3, 14, smoothstep(0.5, 0.86, t)), leanDir = leanDir })
				table.insert(palms, flat(p))
			end
		end
	end

	print("[BeachChill] plants...")
	local function placeMany(count, tMin, tMax, minPath, fn)
		local n, tries2 = 0, 0
		while n < count and tries2 < count * 40 do
			tries2 += 1
			local p = polar(rng:NextNumber(0, 360), rng:NextNumber(tMin, tMax))
			if isFree(p, 2) and pathDistance(p.X, p.Z) > minPath then
				local nearPalm = false
				for _, q in ipairs(palms) do
					if (q - flat(p)).Magnitude < 3 then nearPalm = true break end
				end
				if not nearPalm then
					local g = groundAt(p)
					if g.Y > 0.3 then
						fn(g)
						n += 1
					end
				end
			end
		end
	end
	placeMany(Q.bushes, 0.12, 0.7, 4.5, function(g) buildBush(F.Plants, g) end)
	placeMany(Q.ferns, 0.1, 0.72, 3.5, function(g) buildFern(F.Plants, g) end)

	print("[BeachChill] beach details...")
	local tw = groundAt(LAYOUT.towels)
	buildTowelSpot(F.Details, tw, outward(tw))
	placeMany(Q.shells, 0.8, 0.99, 0, function(g)
		if rng:NextNumber() < 0.25 then buildStarfish(F.Details, g) else buildShell(F.Details, g) end
	end)
	placeMany(5, 0.93, 0.99, 0, function(g) buildDriftwood(F.Details, g) end)

	-- stepping stones on the main path (grassy part only)
	local main = PATHS[1]
	local acc = 0
	for i = 2, #main do
		local a, b = main[i - 1], main[i]
		local segLen = (b - a).Magnitude
		local d = 0
		while d < segLen do
			acc += 1
			local p = a:Lerp(b, d / segLen)
			if tAt(p.X, p.Z) < 0.7 then
				local dir = flat(b - a).Unit
				local side = dir:Cross(UP)
				local sp2 = p + side * ((acc % 2 == 0) and 0.7 or -0.7)
				local g = groundAt(sp2)
				ellipsoid(F.Paths, Vector3.new(rng:NextNumber(1.8, 2.4), 0.4, rng:NextNumber(1.5, 2.0)),
					CFrame.new(g + UP * 0.05) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), jitterColor(rgb(140, 136, 128), 0.06), M.Slate, DECO)
			end
			d += 3.2
		end
	end

	-- ambient sounds
	for name, id in pairs(CONFIG.SOUNDS) do
		if id ~= "" then
			local s = Instance.new("Sound")
			s.Name = "BC_" .. name
			s.SoundId = id
			s.Looped = true
			s.Volume = (name == "Music") and 0.25 or 0.5
			s.Playing = true
			s.Parent = map
		end
	end

	local parts = 0
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") then parts += 1 end
	end
	print(("[BeachChill] done in %.1fs — %d parts"):format(os.clock() - t0, parts))
	return map
end

-------------------------------------------------------------------------------
-- Runtime animation (only while the game is running)
-------------------------------------------------------------------------------
local function makeGull(parent)
	local m = newModel("Seagull", parent)
	local body = ellipsoid(m, Vector3.new(0.7, 0.65, 1.9), CFrame.new(), rgb(246, 246, 246), M.SmoothPlastic, DECO)
	local wl = block(m, Vector3.new(2.4, 0.07, 0.8), CFrame.new(), rgb(200, 204, 210), M.SmoothPlastic, DECO)
	local wr = block(m, Vector3.new(2.4, 0.07, 0.8), CFrame.new(), rgb(200, 204, 210), M.SmoothPlastic, DECO)
	return {
		body = body, wl = wl, wr = wr,
		phase = rng:NextNumber(0, math.pi * 2),
		radius = rng:NextNumber(60, 140),
		height = rng:NextNumber(40, 65),
		speed = rng:NextNumber(0.08, 0.14) * (rng:NextNumber() > 0.5 and 1 or -1),
	}
end

local function startAnimations(map)
	local gullFolder = Instance.new("Folder")
	gullFolder.Name = "Gulls"
	gullFolder.Parent = map
	local gulls = {}
	for _ = 1, 4 do table.insert(gulls, makeGull(gullFolder)) end

	local bobs = CollectionService:GetTagged("BC_Bob")
	local flickers = CollectionService:GetTagged("BC_Flicker")
	local start = os.clock()
	local flickerAcc = 0

	RunService.Heartbeat:Connect(function(dt)
		local t = os.clock() - start
		for _, root in ipairs(bobs) do
			local base = root:GetAttribute("BaseCFrame")
			if base and root.Parent then
				root.CFrame = base * CFrame.new(0, math.sin(t * 1.2) * 0.22, 0)
					* CFrame.Angles(math.sin(t * 0.8) * 0.025, 0, math.sin(t * 1.05) * 0.035)
			end
		end
		for _, g in ipairs(gulls) do
			local ang = g.phase + t * g.speed
			local pos = Vector3.new(math.cos(ang) * g.radius, g.height + math.sin(t * 0.4 + g.phase) * 3, math.sin(ang) * g.radius)
			local tangent = Vector3.new(-math.sin(ang), 0, math.cos(ang)) * math.sign(g.speed)
			local cf = CFrame.lookAt(pos, pos + tangent) * CFrame.Angles(0, 0, math.rad(15) * math.sign(g.speed))
			local flapping = math.sin(t * 0.35 + g.phase * 3) > 0.2
			local flap = flapping and math.sin(t * 7 + g.phase) * 0.55 or 0.08
			g.body.CFrame = cf
			g.wl.CFrame = cf * CFrame.new(-0.3, 0.1, 0) * CFrame.Angles(0, 0, flap) * CFrame.new(-1.2, 0, 0)
			g.wr.CFrame = cf * CFrame.new(0.3, 0.1, 0) * CFrame.Angles(0, 0, -flap) * CFrame.new(1.2, 0, 0)
		end
		flickerAcc += dt
		if flickerAcc > 0.08 then
			flickerAcc = 0
			for _, l in ipairs(flickers) do
				local b = l:GetAttribute("BaseBrightness") or 1
				l.Brightness = b * rng:NextNumber(0.75, 1.15)
			end
		end
	end)

	if CONFIG.DAY_CYCLE then
		task.spawn(function()
			local speed = 24 / (CONFIG.DAY_LENGTH_MINUTES * 60)
			while true do
				local dt = task.wait(0.1)
				Lighting.ClockTime = (Lighting.ClockTime + dt * speed) % 24
			end
		end)
	end
end

-------------------------------------------------------------------------------
-- Entry point
-------------------------------------------------------------------------------
if IS_RUNNING then
	local existing = Workspace:FindFirstChild(MAP_NAME)
	local map = existing
	if not existing or CONFIG.REBUILD_ON_PLAY then
		local auto = Players.CharacterAutoLoads
		Players.CharacterAutoLoads = false
		map = build()
		Players.CharacterAutoLoads = auto
		if auto then
			for _, plr in ipairs(Players:GetPlayers()) do
				if not plr.Character then
					task.spawn(function() plr:LoadCharacter() end)
				end
			end
		end
	end
	startAnimations(map)
else
	build() -- Command Bar / edit mode: bake the map into the place
end
