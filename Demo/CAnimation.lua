--[[
This code is MIT licensed, see http://www.opensource.org/licenses/mit-license.php
(C) 2013 Guava7
]]

if CSprite == nil then
	require  "CSprite"
end

CAnimation = Core.class(CSprite)

function CAnimation:init()
	self.mSpriteSheet = nil
	self.mTime = 0
	self.mDuration = 0
	self.mIsEndOfAnim = false
	self.mIsLoop = false
end

local function GetKeyFrameIndex(self)
	local _min = 1
	local array = self.mSpriteSheet.keyframes
	local _max = #array
	local x = self.mTime
	
	if x < array[_min].timestamp  then
		return _min
	elseif x >= array[_max].timestamp then
		return _max + 1
	else
		local _floor = math.floor
		local mid
		while true do
			mid = _floor(0.5*(_min + _max))
			if (array[mid].timestamp == x)  then
				return mid
			else
				if x > array[mid].timestamp then
					_min = 1 + mid
				else
					_max = mid - 1
				end
			end
			if (_min >= _max) then
				if array[_min].timestamp > x then
					return _min  
				else
					return 1 + _min
				end
			end
		end
	end
end

function CAnimation.CreateWithSpriteSheetName(spritesheetFilename, animation_name)
	assert(spritesheetFilename ~= nil, "spritesheetFilename is nil")
	assert(animation_name ~= nil, "animation_name is nil")
	
	spritesheetFilename = spritesheetFilename
	local self = CAnimation.new()
	
	local tmp = require(spritesheetFilename)
	package.loaded[spritesheetFilename] = nil
	assert(tmp ~= nil, "spritesheet data return nil")
	assert(tmp[animation_name] ~= nil, "Animation name not found")
	
	local spritesheet = tmp[animation_name]
	
	self.mSpriteSheet = spritesheet
	self.mDuration = spritesheet.duration
	self.mIsLoop = spritesheet.loop
	
	--[[ build cache timeline. Each timeline is a sprite]]
	self.mTimelineSprites = {}
	local tlSpr = self.mTimelineSprites
	local timelines = spritesheet.timelines
	local slot_region_define, slot_bitmap_region, slot_region_sprite
	
	for k1, timeline in pairs(timelines) do
		local spr = CSprite.new()
		spr:SetVisible(false)
		tlSpr[#tlSpr + 1] = spr
		
		for k2, slot in pairs(timeline) do
			slot_region_define = slot.region
			slot_bitmap_region = ResourceManagement.GetInstance():CreateRegion(slot_region_define)
			slot_region_sprite = CSprite.new()
			slot_region_sprite:AddChild(slot_bitmap_region)
			spr:AddChild(slot_region_sprite)
			slot_region_sprite:SetVisible(false)
			slot.region = slot_region_sprite
			
			--[[ the following is used for pivot calculate]]
			slot.regionBitmap = slot_bitmap_region 
			slot.width = slot_bitmap_region:getWidth()
			slot.height = slot_bitmap_region:getHeight()
		end
		self:AddChild(spr)
		spr.currentSlotSpr = nil --[[current region which are shown]]
	end
	return self
end

function CAnimation:Destroy()
	self.mSpriteSheet = nil
	self.mTimelineSprites = nil
end

function CAnimation:Update(dt)
	if not self.mIsEndOfAnim then
		local keyframe = GetKeyFrameIndex(self) - 1
		if keyframe <= 0 then keyframe = 1 end
		local frames = self.mSpriteSheet.keyframes[keyframe].frames
		local spritesheetTimelines = self.mSpriteSheet.timelines
		local timelinesprs = self.mTimelineSprites
		
		local timelineIndex, slotIndex, timelineObj, slotObj, slotObjSpr, slotObjBitmap, nextSlotObj
		local t1, x1, y1, sx1, sy1, a1, alpha1, pvx1, pvy1
		local t2 ,x2, y2, sx2, sy2, a2, alpha2, pvx2, pvy2
		local x, y, sx, sy, a, delta, spin, alpha, pvx, pvy
		
		for _, v in pairs(timelinesprs) do
			v:SetVisible(false)
			if v.currentSlotSpr then v.currentSlotSpr:SetVisible(false) end
		end
		
		for _, v in pairs(frames) do
			timelineIndex, slotIndex = v.timeline, v.slot
			timelineObj = timelinesprs[timelineIndex]
			timelineObj:SetVisible(true)
			
			if (slotIndex < #spritesheetTimelines[timelineIndex]) then
				--[[interpolation]]
				slotObj = spritesheetTimelines[timelineIndex][slotIndex]
				nextSlotObj = spritesheetTimelines[timelineIndex][slotIndex + 1]
				t1, x1, y1, sx1, sy1, a1, spin, alpha1, pvx1, pvy1 = slotObj.timestamp, slotObj.x, slotObj.y, slotObj.sx, slotObj.sy, slotObj.angle , slotObj.spin, slotObj.alpha, slotObj.pivot_x, slotObj.pivot_y
				t2, x2, y2, sx2, sy2, a2, alpha2, pvx2, pvy2 = nextSlotObj.timestamp, nextSlotObj.x, nextSlotObj.y, nextSlotObj.sx, nextSlotObj.sy, nextSlotObj.angle, nextSlotObj.alpha, nextSlotObj.pivot_x, nextSlotObj.pivot_y
				delta = (self.mTime - t1)/(t2 - t1)
				
				if spin > 0 then
					if a1 > a2 then
						a = a1 - (a1-a2)*delta
					elseif a1 < a2 then
						a = a1 - (360 + a1 - a2)*delta
					else
						a = a1
					end
				else
					if a1 < a2 then
						a = a1 + (a2-a1)*delta
					elseif a1 > a2 then
						a = a1 + (360 + a2 - a1)*delta
					else
						a = a1
					end
				end
				x, y, sx, sy, alpha, pvx, pvy = x1 + (x2-x1)*delta, y1 + (y2-y1)*delta, sx1 + (sx2-sx1)*delta, sy1 + (sy2-sy1)*delta, alpha1 + (alpha2-alpha1)*delta, pvx1 + (pvx2-pvx1)*delta, pvy1 + (pvy2-pvy1)*delta
				
				
				slotObjSpr = slotObj.region
				timelineObj.currentSlotSpr = slotObjSpr
				slotObjSpr:SetVisible(true)
				slotObjSpr:setScale(sx, sy)
				slotObjSpr:setRotation(a)
				slotObjSpr:setPosition(x, y)
				slotObjSpr:SetAlpha(alpha)
				
				slotObjBitmap = slotObj.regionBitmap
				slotObjBitmap:setPosition(-slotObj.width * pvx, -slotObj.height * pvy)
			else
				--[[ no need interpolation]]
				slotObj = spritesheetTimelines[timelineIndex][slotIndex]
				slotObjSpr = slotObj.region
				timelineObj.currentSlotSpr = slotObjSpr
				slotObjSpr:SetVisible(true)
				slotObjSpr:setScale(slotObj.sx, slotObj.sy)
				slotObjSpr:setRotation(slotObj.angle)
				slotObjSpr:setPosition(slotObj.x, slotObj.y)
				
				slotObjBitmap = slotObj.regionBitmap
				slotObjBitmap:setPosition(-slotObj.width * slotObj.pivot_x, -slotObj.height * slotObj.pivot_y)
			end
			
		end
		-- LogI(frames)
		
		-- update time
		self.mTime = self.mTime + dt
		
		if self.mTime > self.mDuration then
			if self.mIsLoop then
				self.mTime = self.mTime % self.mDuration
			else
				self.mIsEndOfAnim = true
			end
		end
	end
end

function CAnimation:EnableLoop(loop)
	self.mIsLoop = loop
end





