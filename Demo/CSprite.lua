--[[
This code is MIT licensed, see http://www.opensource.org/licenses/mit-license.php
(C) 2013 Guava7
]]
if CSprite ~= nil then return end
CSprite = Core.class(Sprite)

function CSprite.CreateRect(alpha, rgb, x, y, w, h)
	local re = CSprite.new()
	re:SetWatermark(math.floor(alpha * 255) * 16777216 + rgb, x, y, w, h)
	return re
end

CSprite.GetChildAt = CSprite.getChildAt
CSprite.GetWidth = CSprite.getWidth
CSprite.GetHeight = CSprite.getHeight
CSprite.GetAlpha = CSprite.getAlpha
CSprite.SetAlpha = CSprite.setAlpha
CSprite.SetVisible = CSprite.setVisible
CSprite.GetRenderX = CSprite.getX
CSprite.GetRenderY = CSprite.getY
CSprite.IsVisible = CSprite.isVisible
CSprite.GetParent = CSprite.getParent
CSprite.AddChild = CSprite.addChild

function CSprite:init(opt)
	self.mWatermark = nil
	
	-- if degree == nil then degree = self.mDegree end
	self.mDegree = 0
	self.mX = 0
	self.mY = 0
	self.mHAnchor = ANCHOR_BASE
	self.mVAnchor = ANCHOR_BASE
	self.mFlipX = false
	self.mFlipY = false
	self.mScaleX = 1
	self.mScaleY = 1
	self.mName = ""
	if opt then 
		if type(opt) == "table" then
			self.mName = opt.name
			if opt.width and opt.height then
				self:SetWatermark(0, 0, 0, opt.width, opt.height)
			end
		end
	end
	self.mWasDestroy = false
end

function CSprite:GetName()
	return self.mName
end

function CSprite:SetName(name)
	self.mName = name
end

function CSprite:GetChildByName(name)
	local num = self:getNumChildren()
	local child
	for i = 1, num do
		child = self:getChildAt(i)
		if child.IsCSprite ~= nil then
			if child:GetName() == name then
				return child
			end
		end
	end
	return nil
end

function CSprite:GetFirstChild()
	return self:getChildAt(1)
end

function CSprite:SetScale(scalex, scaley)
	if scaley == nil then scaley = scalex end
	self.mScaleX = scalex
	self.mScaleY = scaley
	if self.mScaleX == nil then self.mScaleX = 1 end
	if self.mScaleY == nil then self.mScaleY = 1 end
end

function CSprite:GetScale()
	return self.mScaleX, self.mScaleY
end

function CSprite:GetScaleX()
	return self.mScaleX
end

function CSprite:GetScaleY()
	return self.mScaleY
end

function CSprite:SetFlip(flipx, flipy)
	self.mFlipX = flipx
	self.mFlipY = flipy
end

function CSprite:SetFlipX(flipx)
	self.mFlipX = flipx
end

function CSprite:SetFlipY(flipy)
	self.mFlipY = flipy
end

function CSprite:GetFlip()
	return self.mFlipX, self.mFlipY
end

function CSprite:GetFlipX()
	return self.mFlipX
end

function CSprite:GetFlipY()
	return self.mFlipY
end

function CSprite:SetWatermark(argb, x, y, w, h, bordersize, bordercolor)
	self:RemoveChild(self.mWatermark)
	self.mWatermark = CSprite.new()
	local obj = self.mWatermark

	if bordersize == nil then bordersize = 0 end
	if bordercolor == nil then bordercolor = 0 end
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	if w == nil then w = self:GetWidth() end
	if h == nil then h = self:GetHeight() end
	
	local p1, p2, p3, p4
	local alpha = 0
	if type(argb) == "table" then
		p1 = tonumber(argb[1])
		p2 = tonumber(argb[2] or p1)
		p3 = tonumber(argb[3] or p2)
		p4 = tonumber(argb[4] or p3)
	else
		p1 = tonumber(argb)
		p2, p3, p4 = p1, p1, p1
	end
	local a1 = math.floor(p1/16777216)/255
	local c1 = math.mod(p1,16777216)
	local a2 = math.floor(p2/16777216)/255
	local c2 = math.mod(p2,16777216)
	local a3 = math.floor(p3/16777216)/255
	local c3 = math.mod(p3,16777216)
	local a4 = math.floor(p4/16777216)/255
	local c4 = math.mod(p4,16777216)
	
	local mesh = Mesh.new()
	mesh:setVertexArray(0, 0, w, 0, w, h, 0, h)
	mesh:setColorArray(c1, a1, c2, a2, c3, a3, c4, a4)
	mesh:setIndexArray(1, 2, 3, 1, 3, 4)
	obj:AddChild(mesh)
	
	local borderlapha = math.floor(bordercolor/16777216)/255
	local bordercolor =  math.mod(bordercolor,16777216)
	if bordersize > 0 and bordercolor > 0 then
		local shape = Shape.new()
		shape:setFillStyle(Shape.NONE)
		shape:setLineStyle(bordersize, bordercolor, borderlapha)
		shape:beginPath()
		shape:moveTo(0, 0)
		shape:lineTo(w, 0)
		shape:lineTo(w, h)
		shape:lineTo(0, h)
		shape:lineTo(0, 0)
		shape:endPath()
		obj:AddChild(shape)
	end
	alpha = math.max(a1, a2, a3, a4, borderlapha)
	
	obj:setVisible(alpha > 0)
	self:AddChildAlign(obj, x, y)
	return obj
end

function CSprite:GetCenter()
	local x, y, w, h = self:GetRect()
	return 0.5*(x + w), 0.5*(y + h)
end

function CSprite:GetCenterX()
	local x, y, w, h = self:GetRect()
	return 0.5*(x + w)
end

function CSprite:GetCenterY()
	local x, y, w, h = self:GetRect()
	return 0.5*(y + h)
end

function CSprite:Empty()
	local _fGetNumChild = self.getNumChildren
	local _fGetChildAt = self.getChildAt
	local _fRemoveChild = self.RemoveChild
	while _fGetNumChild(self) > 0 do
		_fRemoveChild(self, _fGetChildAt(self, 1))
	end
end

function CSprite:EmptyNoDestroy()
	local _fGetNumChild = self.getNumChildren
	local _fGetChildAt = self.getChildAt
	local _fRemoveChild = self.RemoveChildNoDestroy
	while _fGetNumChild(self) > 0 do
		_fRemoveChild(self, _fGetChildAt(self, 1))
	end
end

function CSprite:RemoveFirstChild()
	if (self:getNumChildren() > 0) then
		self:RemoveChild(self:getChildAt(1))
	end
end

function CSprite:RemoveFirstChildNoDestroy()
	if (self:getNumChildren() > 0) then
		self:RemoveChildNoDestroy(self:getChildAt(1))
	end
end

function CSprite:AddChildAlign(obj, x, y, valign, halign, rotation)
	self:AddChildAlignAt(obj, nil, x, y, valign, halign, rotation)
end

function CSprite:AddChildAlignAt(obj, index, x, y, valign, halign, rotation)
	if obj~=nil then
		self:SetChildPosition(obj, x, y, valign, halign, rotation)
		if index == nil then
			self:addChild(obj)
		else
			self:addChildAt(obj, index)
		end
	end
end

function CSprite:AddChildQuick(obj, x, y)
	if obj ~= nil then
		self:addChild(obj)
		if obj.IsCSprite ~= nil then
			obj:SetPositionQuick(x, y)
		else
			obj:setPosition(x, y)
		end
	end
end

function CSprite:SetPositionQuick(x, y)
	if x == nil then x = self.mX end
	if y == nil then y = self.mY end
	self.mX = x
	self.mY = y
	self:setPosition(math.floor(x), math.floor(y))
end

function CSprite:GetRelativePositionInfo()
	return self.mX, self.mY, self.mVAnchor, self.mHAnchor, self.mDegree
end

function CSprite:GetPosition()
	return self.mX, self.mY
end

function CSprite:UpdatePosition()
	self:SetPosition()
end

local _ffloor = math.floor
function CSprite:SetPosition(x, y, vanchor, hanchor, degree)
	-- print("SetPosition", self)
	if degree == nil then 
		degree = self.mDegree 
	else
		self.mDegree  = degree
	end
	if x == nil then 
		x = self.mX 
	else
		self.mX = x
	end
	if y == nil then 
		y = self.mY 
	else
		self.mY = y
	end
	if vanchor == nil then 
		vanchor = self.mVAnchor 
	else
		self.mVAnchor = vanchor
	end
	if hanchor == nil then 
		hanchor = self.mHAnchor 
	else
		self.mHAnchor = hanchor
	end
	
	self:setRotation(0)
	local width = self:GetWidth()
	local height = self:GetHeight()
	local _ffloor = math.floor
	
	local mdX = 0
	local mdY = 0
	
	local scalex = self.mScaleX
	local scaley = self.mScaleY
	if self.mFlipX == true then scalex = - scalex end
	if self.mFlipY == true then scaley = - scaley end
	
	local boundx, boundy = 0, 0
	if hanchor ~= ANCHOR_BASE or vanchor ~= ANCHOR_BASE then
		boundx, boundy, _, _ = self:getBounds(self)
		boundx, boundy = boundx*scalex, boundy*scalex
	end
	
	
	if hanchor == ANCHOR_LEFT then
		mdX = -boundx
	elseif hanchor == ANCHOR_RIGHT then
		mdX = - (width + boundx)
	elseif hanchor == ANCHOR_HCENTER then
		mdX = - 0.5*(boundx + (width + boundx))
	end
	
	if vanchor == ANCHOR_TOP then
		mdY = - boundy
	elseif vanchor == ANCHOR_BOTTOM then
		mdY = - (height + boundy)
	elseif vanchor == ANCHOR_VCENTER then
		mdY = - 0.5*(boundy + (height + boundy))
	end
	
	
	
	if scalex == 1 and scaley == 1 then
		self:setScale(1, 1)
	else
		self:setScale(scalex, scaley)
		
		if scalex < 0 then
			if self.IsCUIObject == nil then
				mdX = mdX - scalex*width
			end
		end
		
		if scaley < 0 then
			if self.IsCUIObject == nil then
				mdY = mdY - scaley*height
			end
		end	
	end
	
	if degree == 0 then
		self:setPosition(_ffloor(x + mdX), _ffloor(y + mdY))
	else
		local c = QuickCos(degree)
		local s = QuickSin(degree)
		self:setPosition(_ffloor(x + mdX * c - mdY * s), _ffloor(y + mdY * c + mdX * s))
		self:setRotation(degree)
	end
end
	
function CSprite:SetChildPosition(obj, x, y, valign, halign, rotation)
	if obj~=nil then
		local _ffloor = math.floor
		if x == nil then x = 0 end
		if y == nil then y = 0 end
		obj:SetPosition(x, y, valign, halign, rotation)
	end
end

function CSprite:RemoveChild(child)
	if child ~= nil then
		if self:contains(child) then
			if child.IsCSprite ~= nil then
				child:Destroy()
			end
			self:removeChild(child)
		end
	end
end

function CSprite:RemoveChildNoDestroy(child)
	if child ~= nil then
		if self:contains(child) then
			self:removeChild(child)
		end
	end
end

function CSprite:SetVisibleTree(val)
	local stack = CStack.new()
	stack:Push(self)
	local obj, numOfChild = nil, 0
	local getNumChildren = Sprite.getNumChildren
	local getChildAt = Sprite.getChildAt
	while (stack:GetSize() > 0) do
		obj = stack:Pop()
		if obj.SetVisible then
			obj:SetVisible(val)
		else
			obj:setVisible(val)
		end
		numOfChild = getNumChildren(obj)
		for i = 1, numOfChild do
			stack:Push(getChildAt(obj, i))
		end
	end
end

function CSprite:Destroy()
	if self:IsAlive() then
		self:Empty()
		if self.onEnterFrame ~= nil then
			self:removeEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
		end
		self.mWasDestroy = true
	end
end

function CSprite:IsAlive()
	return self.mWasDestroy == false
end

function CSprite:IsCSprite()
	return true
end

function CSprite:GetX()
	return self.mX
end

function CSprite:GetY()
	return self.mY
end

function CSprite:GetRenderPosition()
	return self:getX(), self:getY()
end

function CSprite:SetRotation(val)
	self.mDegree = val
end

function CSprite:GetRotation()
	return self.mDegree
end

function CSprite:GetRect()
	return self:getBounds(self)
end
