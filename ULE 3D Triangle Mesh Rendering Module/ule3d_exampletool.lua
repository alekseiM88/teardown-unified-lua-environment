-- include the test model
ULE_IncludeLua(_G, "testmodel.lua")

function init()
	RegisterTool("ule3dexampletool", "ULE3D Example", nil)
    
	SetBool("game.tool.ule3dexampletool.enabled", true)
end

function ULE_LateInit()
    -- keep a reference to ule3d
    ule3d = ULE_FindModByULEName("ULE3D")
    
    if ule3d == nil then
        DebugPrint("Error: could not find ULE3D, please install and enable ULE3D.")
        return
    end
    
    testModel = ule3d.CreateModelFromObjLines(testmodel)
    
    -- nil model lua so it can be garbage collected
    testmodel = nil
end

function tick()
    if ule3d ~= nil and GetString("game.player.tool") == "ule3dexampletool" then
        local cameraTf = GetCameraTransform()
        local cameraForward = TransformToParentVec(cameraTf, Vec(0,0,-1))
        local hit, dist, normal = QueryRaycast(cameraTf.pos, cameraForward, 50)
        
        if not hit then return end
        
        local hitPoint = VecAdd(VecScale(cameraForward, dist), cameraTf.pos)
        
        local curTime = GetTime()
        
        ule3d.QueueModelDraw(testModel, Transform(hitPoint, QuatEuler(math.sin(curTime*1.5)*12, curTime*90, math.cos(curTime*2)*12)))
    end
end