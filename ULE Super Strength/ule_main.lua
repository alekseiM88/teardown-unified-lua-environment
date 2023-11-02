-- Super Strength for ULE
ULE_IncludeLua(_G, "strength_shared.lua")

MINHELDDIST = 0.7
MAXHELDDIST = 5

HOLERADIUS = 0.8 -- default is 0.8


function init()
    -- Call InitializePersistentData, a function included from strength_shared.lua
    InitializePersistentData()

    heldBody = nil
    
    holdDistance = 1
    -- held position in body's space
    heldPosition = nil
    -- held rotation in camera's space, stored as transform so I can use the less confusing functions for moving
    -- it in and out of local space
    rotationTf = nil
    
    hasThrown = false
    
    -- the tool the player was holding before picking up a body
    lastHeldTool = ""

    cameraTf = nil
    cameraForward = nil
    
    allowGrabbingStaticBodies = GetBool(_G, _defaultStaticGrabStateKey)
    superStrengthEnabled = true

    ULE_name = "TLS Super Strength"
end


-- Called a frame after global init. All mods are initialized at this point.
function ULE_LateInit()
    --DebugPrint("Late init.")
    -- Since ULE_FindModByULEName is a rather expensive function, it is best to only call it once.
    -- The body of ULE_LateInit() is the best place to do so.
    --minigunGTable = ULE_FindModByULEName("Minigun")
    --PrintMe()
end

-- number, table with values that are the same type as number
function IsNumberInTable(number, list)
    for _, v in ipairs(list) do
        if v == number then
            return true
        end
    end
    return false
end

function SetPlayerTool(toolName)
    SetString("game.player.tool", toolName)
    SetInt("game.player.toolselect", 0)
end

function DropBody()
    if heldBody == nil then return end
    
    heldBody = nil
    SetPlayerTool(lastHeldTool)
end

function ThrowBody()
    if heldBody == nil then return end

    local bodyTf = GetBodyTransform(heldBody)
    local globalHeldPosition = TransformToParentPoint(bodyTf, heldPosition)
    ApplyBodyImpulse(heldBody, globalHeldPosition, VecScale(cameraForward, 40 * GetBodyMass(heldBody)))
    
    heldBody = nil
    
    hasThrown = true
end

function AttemptGrab()
    -- don't attempt to grab if we're still post throw
    if hasThrown then return end

    local hit, dist, normal, shape = QueryRaycast(cameraTf.pos, cameraForward, 5)
    
    if not hit then
        heldBody = nil
        return
    end
    
    
    heldBody = GetShapeBody(shape)
    
    -- grabbing a chunk of a static body, try to break it off
    if allowGrabbingStaticBodies and not IsBodyDynamic(heldBody) then 
        local hitPosition = VecAdd(VecScale(cameraForward, dist), cameraTf.pos)
        local queryBounds = Vec(HOLERADIUS,HOLERADIUS,HOLERADIUS)
        
        -- get all bodies in ~radius of hitposition, then make hole and lump all new bodies into a single body, then grab that body
        local oldBodies = QueryAabbBodies(VecSub(hitPosition, queryBounds), VecAdd(hitPosition, queryBounds))
        
        MakeHole(hitPosition, HOLERADIUS, HOLERADIUS, HOLERADIUS, false)
        
        local newBodies = QueryAabbBodies(VecSub(hitPosition, queryBounds), VecAdd(hitPosition, queryBounds))

        heldBody = nil
        
        for _, start in ipairs(newBodies) do
            if not IsNumberInTable(start, oldBodies) then
                heldBody = start

                
                local heldBodyTf = GetBodyTransform(heldBody)
                for _, body in ipairs(newBodies) do
                    if body ~= heldBody and not IsNumberInTable(body, oldBodies) then
                    
                        local otherBodyTf = GetBodyTransform(body)
                        local bodyShapes = GetBodyShapes(body)
                        
                        for _, shape in ipairs(bodyShapes) do
                            local shapeJoints = GetShapeJoints(shape)
                            for k, j in ipairs(shapeJoints) do
                                Delete(j)
                            end
                        
                            SetShapeBody(shape, heldBody, TransformToLocalTransform(heldBodyTf, TransformToParentTransform(otherBodyTf, GetShapeLocalTransform(shape))))
                        end
                    end
                end
                
                break
            end
        end
        
    end
        
    -- regular body grabbing
    if IsBodyDynamic(heldBody) then 
    
        local bodyTf = GetBodyTransform(heldBody)
        local globalHeldPosition = VecAdd(VecScale(cameraForward, dist), cameraTf.pos)
        
        heldPosition = TransformToLocalPoint(bodyTf, globalHeldPosition)
        holdDistance = dist
        
        rotationTf = Transform(Vec(), bodyTf.rot)
        
        rotationTf = TransformToLocalTransform(cameraTf, rotationTf)
        
        local playerTool = GetString("game.player.tool")
        if playerTool ~= "none" then
            lastHeldTool = playerTool
        end
    else
        heldBody = nil
    end
    
    
    
    ReleasePlayerGrab()
end

function tick(dt)
    cameraTf = GetPlayerCameraTransform(true)
    cameraForward = TransformToParentVec(cameraTf, Vec(0,0,-1))
    
    local engineGrab = GetPlayerGrabBody() ~= 0

    -- only get input when player can use tool, hopefully this'll make creative work better
    if GetBool("game.player.canusetool") or engineGrab then
    
        -- toggle static body grabbing is the toggle button is pressed and the toggle feature is enabled
        if superStrengthEnabled and InputPressed(GetString(_G, _staticGrabToggleButtonKey)) and GetBool(_G, _enableStaticGrabTogglingKey) then
            allowGrabbingStaticBodies = not allowGrabbingStaticBodies
            
            if allowGrabbingStaticBodies then
                ULE_notifier.AddNotification("Static body grabbing is now enabled.", nil, {0, 0.9, 0.2})
            else
                ULE_notifier.AddNotification("Static body grabbing is now disabled.", nil, {0.9, 0.2, 0.2})
            end
        end
        
        -- super strength toggle
        if InputPressed(GetString(_G, _toggleSuperStrengthButtonKey)) then
            superStrengthEnabled = not superStrengthEnabled
            
            if superStrengthEnabled then
                ULE_notifier.AddNotification("Super strength is now enabled.", nil, {0, 0.9, 0.2})
            else
                ULE_notifier.AddNotification("Super strength is now disabled.", nil, {0.9, 0.2, 0.2})
            end
            
            -- try to transfer grab if the player was already grabbing something
            if superStrengthEnabled and engineGrab then
                ReleasePlayerGrab()
                AttemptGrab()
            end
        end

    end

    -- attempt to grab a body if grab is both held AND pressed
    if superStrengthEnabled and InputDown("grab") and (GetBool("game.player.canusetool") or engineGrab) then
        if heldBody == nil and InputPressed("grab") and not InputDown("usetool") then
            AttemptGrab()
        end
    elseif heldBody ~= nil then
        DropBody()
    end
    
    -- override held tool when grabbing or if post throw
    if heldBody ~= nil or hasThrown then
        SetPlayerTool("none")
    end
    
   
    if heldBody ~= nil then
        SetBool("game.player.grabbing", true) 
        
        SetToolTransform(Transform(Vec(0,-2,0)))

        
        -- throwing
        if InputPressed("usetool") then
            ThrowBody()
        end
    end
    
    -- end throw state if throw button is unpressed
    if hasThrown and not InputDown("usetool") then
        hasThrown = false
        SetPlayerTool(lastHeldTool)
    end
    
    
    holdDistance = math.min(math.max(holdDistance + (InputValue("mousewheel") * 0.65), MINHELDDIST), MAXHELDDIST)
    
end


function update(dt)
    if heldBody == nil then return end
    
    
    cameraTf = GetPlayerCameraTransform(true)
    cameraForward = TransformToParentVec(cameraTf, Vec(0,0,-1))

    local bodyTf = GetBodyTransform(heldBody)
    local globalHeldPosition = TransformToParentPoint(bodyTf, heldPosition)


    -- linear velocity
    local bodyVelocity = GetBodyVelocityAtPos(heldBody, globalHeldPosition)
    
    local idealVelocity = VecSub(VecAdd(cameraTf.pos, VecScale(cameraForward, holdDistance)), globalHeldPosition)
    
    local bodyMass = GetBodyMass(heldBody)
    
    idealVelocity = VecScale(idealVelocity, bodyMass * 6)
    
    local impulseVector = VecSub(idealVelocity, VecScale(bodyVelocity, bodyMass/3))
    
    ApplyBodyImpulse(heldBody, globalHeldPosition, impulseVector)
    

    -- angular velocity
    local heldVehicle = GetBodyVehicle(heldBody)
    if not (IsBodyJointedToStatic(heldBody) or #GetJointedBodies(heldBody) > 1) or (heldVehicle ~= 0 and GetVehicleBody(heldVehicle) == heldBody) then

        local worldRotationTf = TransformToParentTransform(cameraTf, rotationTf)
        ConstrainOrientation(heldBody, 0, bodyTf.rot, worldRotationTf.rot, 12.5)
        
        
        rotationTf = Transform(Vec(), QuatSlerp(bodyTf.rot, worldRotationTf.rot, 0.98))
    
        rotationTf = TransformToLocalTransform(cameraTf, rotationTf)
    end

end
