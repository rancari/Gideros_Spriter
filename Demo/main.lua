
function GetUsedMemory(cleanup)
	if cleanup == true then
		collectgarbage()
	end
	return math.floor(collectgarbage("count"))
end

ResourceManagement.GetInstance():FreeCache()
testAnim = {}


--[[ TEST MEMORY LEAK ]]--
print("Test memory leak")
print(GetUsedMemory(true))
for i=1, 100 do
	testAnim[i] = CAnimation.CreateWithSpriteSheetName("anim_spriter_demo", "1")
end
for i=1, 100 do
	testAnim[i] = nil
end
testAnim = nil
ResourceManagement.GetInstance():FreeCache()
print(GetUsedMemory(true))
print(GetUsedMemory(true))
print(GetUsedMemory(true))


--[[ TEST ANIMATION ]]--
print("Test animation")

-- MC
local mc = CSprite.new()
mc.spr = {
	['Idle'] = CAnimation.CreateWithSpriteSheetName("anim_Example", "Idle"),
	['Posture'] = CAnimation.CreateWithSpriteSheetName("anim_Example", "Posture"),
}
mc.sprStream = {
	'Idle', 'Posture'
} 
mc.currentAnim = 1

for _,v in pairs(mc.spr) do
	v:SetVisible(false)
	mc:addChild(v)
end

local screenW, screenH = application:getDeviceWidth(), application:getDeviceHeight()
if application:getOrientation() == Stage.LANDSCAPE_LEFT or application:getOrientation() == Stage.LANDSCAPE_RIGHT then
	if screenH > screenW then
		screenW, screenH = screenH, screenW
	end
end

mc:setScale(math.min(screenW/1024, screenH/768))
mc:setPosition(screenW/2, 3*screenH/4)
mc.spr[mc.sprStream[mc.currentAnim]]:setVisible(true)
stage:addChild(mc)

-- logo
local logo = CAnimation.CreateWithSpriteSheetName("anim_guava7", "First Animation")
logo:setPosition(screenW - logo:getWidth(), screenH)
logo:EnableLoop(true)
stage:addChild(logo)

--label
local label = TextField.new(nil, "Current Animation: " .. mc.sprStream[mc.currentAnim])
label:setPosition(0, screenH - 2)
label:setScale(3)
stage:addChild(label)

-- buttons
local up = Bitmap.new(Texture.new("button/button_up.png"))
local down = Bitmap.new(Texture.new("button/button_down.png"))
local button = Button.new(up, down)
button:addEventListener("click", 
	function() 
		mc.spr[mc.sprStream[mc.currentAnim]]:setVisible(false)
		mc.currentAnim = mc.currentAnim + 1
		if mc.currentAnim > #mc.sprStream then
			mc.currentAnim = 1
		end
		mc.spr[mc.sprStream[mc.currentAnim]]:setVisible(true)
		label:setText("Current Animation: " .. mc.sprStream[mc.currentAnim])
	end)
button:setPosition(0, 0)
stage:addChild(button)



function _onEnterFrame()
	mc.spr[mc.sprStream[mc.currentAnim]]:Update(30)
	logo:Update(30)
end

stage:addEventListener(Event.ENTER_FRAME, _onEnterFrame)

