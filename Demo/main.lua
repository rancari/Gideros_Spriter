
function GetUsedMemory(cleanup)
	if cleanup == true then
		collectgarbage()
	end
	return math.floor(collectgarbage("count"))
end

ResourceManagement.GetInstance():FreeCache()
testAnim = {}

print("Test memory leak")
print(GetUsedMemory(true))
for i=1, 100 do
	testAnim[i] = CAnimation.CreateWithSpriteSheetName("spriter_demo", "1")
end
for i=1, 100 do
	testAnim[i] = nil
end
testAnim = nil
ResourceManagement.GetInstance():FreeCache()
print(GetUsedMemory(true))
print(GetUsedMemory(true))
print(GetUsedMemory(true))


print("Test animation")
local testAnim = CAnimation.CreateWithSpriteSheetName("Example", "Idle")
local testAnim2 = CAnimation.CreateWithSpriteSheetName("Example", "Posture")
testAnim:setPosition(200, 400)
testAnim2:setPosition(500, 400)
stage:addChild(testAnim)
stage:addChild(testAnim2)


function _onEnterFrame()
	testAnim:Update(30)
	testAnim2:Update(30)
end

stage:addEventListener(Event.ENTER_FRAME, _onEnterFrame)

