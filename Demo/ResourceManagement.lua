ResourceManagement = Core.class()
gResourceManagement = nil

local function Split(str, delim, maxNb)
	-- Eliminate bad cases...
	if str == nil or delim == nil then return {str} end
	assert(type(str) ==  "string", "str is not a string. Type: " .. type(str))
	if string.find(str, delim) == nil then
		return { str }
	end
	if maxNb == nil or maxNb < 1 then
		maxNb = 0    -- No limit
	end
	local result = {}
	local pat = "(.-)" .. delim .. "()"
	local nb = 0
	local lastPos
	for part, pos in string.gfind(str, pat) do
		nb = nb + 1
		result[nb] = part
		lastPos = pos
		if nb == maxNb then break end
	end
	-- Handle the last field
	if nb ~= maxNb then
		result[nb + 1] = string.sub(str, lastPos)
	end
	return result
end


function ResourceManagement.GetInstance()
	if gResourceManagement == nil then
		gResourceManagement = ResourceManagement.new()
	end
	return gResourceManagement
end

function ResourceManagement:init()
	self.mResTex = {}
	self.mResTextureRegion = {}
	self.mResRegion = {}
end

--[[
Texture
--]]
function ResourceManagement:GetTexture(texture_name)
	assert(texture_name ~= nil, "texture name is nil")
	if self.mResTex[texture_name] == nil then
		print("[RES] Load new texture " .. texture_name)
		self.mResTex[texture_name] = Texture.new(texture_name, true)
	end
	return self.mResTex[texture_name]
end

function ResourceManagement:FreeTexture(texture)
	if type(texture) == "string" then
		self.mResTex[texture] = nil
	elseif type(texture) == "table" then
		for k, v in pairs(self.mResTex) do
			if v == texture then
				self.mResTex[k] = nil
				break
			end
		end
	end
end


--[[
Texture Region
--]]
function ResourceManagement:GetTextureRegion(reg_name)
	if self.mResTextureRegion[reg_name] == nil then
		local data = Split(reg_name, ":")  
		assert(#data == 5, "Invalid region format " .. reg_name)
		local image = data[1]
		local x = data[2]
		local y = data[3]
		local w = data[4]
		local h = data[5]
		local texture = self:GetTexture(image)
		self.mResTextureRegion[reg_name] = TextureRegion.new(texture, x,  y,  w, h)
	end
	return self.mResTextureRegion[reg_name]
end

function ResourceManagement:FreeTextureRegion(texture_region)
	if type(texture_region) == "string" then
		self.mResTextureRegion[texture_region] = nil
	elseif type(texture_region) == "table" then
		for k, v in pairs(self.mResTextureRegion) do
			if v == texture_region then
				self.mResTextureRegion[k] = nil
			end
		end
	end
end

function ResourceManagement:CreateRegion(reg_name)
	local textureRegion = self:GetTextureRegion(reg_name)
	return Bitmap.new(textureRegion)
end

function ResourceManagement:FreeCache()
	self.mResTex = {}
	self.mResRegion = {}
	self.mResTextureRegion = {}
end