ULE_IncludeLua(_G, "libmdl.lua")

function init()
    OVERSCANMARGIN = 0
    renderScale = 4
    renderScaleRecip = 1/renderScale
    
    width = 12
    height = 12

    _drawBuffer = {}

    ULE_name = "ULE3D"
end

function ULE_PostDraw(dt)
    _DrawModelQueue()
end

-- TODO: fix points behind the camera's plane behaving strangely.
function ScreenSpaceVec(worldSpaceVec)
    local x, y, dist = UiWorldToPixel(worldSpaceVec)
    local distSign = (dist > 0) and 1 or -1
    return Vec(math.floor(x * renderScaleRecip) * distSign ,math.floor(y * renderScaleRecip) * distSign ,dist)
end

-- add a model to the draw queue, order will be based on distance to the camera
function QueueModelDraw(modelData, transform, noSort, newRenderScale)
    newRenderScale = newRenderScale or 5

    if modelData == nil or transform == nil then
        DebugPrint("ULE 3D Error: Tried to queue model with nil modelData/transform")
        return
    end
    _drawBuffer[#_drawBuffer+1] = {modelData, transform, #_drawBuffer+1, noSort, newRenderScale}
end

-- make a sortedFaces table with faces sorted as if they were at transform
-- note that this function is much more expensive than the sorting that is done in _DrawModel
function SortModelFaces(modelData, transform)
    local cameraTf = GetCameraTransform()
    local cameraForward = TransformToParentVec(cameraTf, Vec(0,0,-1))

    local verts = TransformPointTable(modelData.verts, transform)
    

    -- transform verts into screenspace
    for i, vert in ipairs(verts) do
        verts[i] = ScreenSpaceVec(vert)
    end
    
    local sortedFaces = {}
    for i, f in ipairs(modelData.faces) do
        f[4] = i -- keep original index of face at 4
        sortedFaces[i] = f
    end
    
    -- then sort based on z
    table.sort(sortedFaces, function(a, b)
         return (verts[a[1]][3] + verts[a[2]][3] + verts[a[3]][3]) > (verts[b[1]][3] + verts[b[2]][3] + verts[b[3]][3])
     end)
    modelData.sortedFaces = sortedFaces
end

function _SetRenderScale(scale)
    renderScale = scale
    renderScaleRecip = 1/renderScale
    height = math.floor(UiHeight() * renderScaleRecip)
    width = math.floor(UiWidth() * renderScaleRecip)
end

function _DrawModelQueue()
    -- sort queued models by distance from camera
    local cameraTf = GetCameraTransform()
    
    local distances = {}
    for i, model in ipairs(_drawBuffer) do
        distances[i] = math.pow(model[2].pos[1] - cameraTf.pos[1], 2) + math.pow(model[2].pos[2] - cameraTf.pos[2], 2) + math.pow(model[2].pos[3] - cameraTf.pos[3], 2)
    end

    table.sort(_drawBuffer, function(a, b)
        return distances[a[3]] > distances[b[3]]
    end)

    -- draw models
    for _, model in ipairs(_drawBuffer) do
        _SetRenderScale(model[5])
        _DrawModel(model[1], model[2], model[4])
    end

    -- clear draw buffer
    _drawBuffer = {}
end

-- avoid calling this function directly
function _DrawModel(modelData, transform, noSort)
    local verts = TransformPointTable(modelData.verts, transform)
    local normals = TransformDirTable(modelData.normals, transform)
    
    local hasColors = modelData.colors and #modelData.colors > 0 
    local colors = modelData.colors

    -- transform verts into screenspace
    for i, vert in ipairs(verts) do
        verts[i] = ScreenSpaceVec(vert)
    end
    
    -- sort triangles based on combined z of the verts of face, which for this is the same as the average of all the verts's z
    
    -- first copy faces table
    if not noSort then
        local sortedFaces = {}
        for i, f in ipairs(modelData.faces) do
            f[4] = i -- keep original index of face at 4
            sortedFaces[i] = f
        end
        
        -- then sort based on z
        table.sort(sortedFaces, function(a, b)
            return (verts[a[1]][3] + verts[a[2]][3] + verts[a[3]][3]) > (verts[b[1]][3] + verts[b[2]][3] + verts[b[3]][3])
        end)
        modelData.sortedFaces = sortedFaces
    end
    
    local sortedFaces = modelData.sortedFaces
    
    if hasColors then
        for _, face in ipairs(sortedFaces) do
            
            if VecCross(VecSub(verts[face[2]], verts[face[1]]), VecSub(verts[face[3]], verts[face[1]]))[3] < 0 then
                -- basic half lambert shading
                local light = ((normals[face[4]][2] + 1) * 0.4) + 0.2
                
                local srcColor = colors[face[1]]
                local color = {srcColor[1]*light, srcColor[2]*light, srcColor[3]*light}
            
                _DrawTriangle({verts[face[1]],  verts[face[2]],  verts[face[3]]}, color)
            end
        end
    else
        for _, face in ipairs(sortedFaces) do
            
            if VecCross(VecSub(verts[face[2]], verts[face[1]]), VecSub(verts[face[3]], verts[face[1]]))[3] < 0 then
                -- basic half lambert shading
                local light = ((normals[face[4]][2] + 1) * 0.4) + 0.2
                
                _DrawTriangle({verts[face[1]],  verts[face[2]],  verts[face[3]]}, {light,light,light,1})
            end
        end
    end
end

-- Triangle scanline rasterizer, points table should be in screenspace.
function _DrawTriangle(points, color)

    local rect = UiRect
    local translate = UiTranslate
    local push = UiPush
    local pop = UiPop
    local min = math.min
    local max = math.max

    local topMost = 0
    local bottomMost = 0
    local sideMost = 0
    
    if points[1][2] >= points[2][2] and points[1][2] >= points[3][2] then
        topMost = 1
    elseif points[2][2] >= points[1][2] and points[2][2] >= points[3][2] then
        topMost = 2
    elseif points[3][2] >= points[1][2] and points[3][2] >= points[1][2] then
        topMost = 3
    end
    
    if points[1][2] <= points[2][2] and points[1][2] <= points[3][2] then
        bottomMost = 1
    elseif points[2][2] <= points[1][2] and points[2][2] <= points[3][2] then
        bottomMost = 2
    elseif points[3][2] <= points[1][2] and points[3][2] <= points[1][2] then
        bottomMost = 3
    end
    
    if 1 ~= topMost and 1 ~= bottomMost then
        sideMost = 1
    elseif 2 ~= topMost and 2 ~= bottomMost then
        sideMost = 2
    else
        sideMost = 3
    end
    
    

    sideMost = points[sideMost]
    topMost = points[topMost]
    bottomMost = points[bottomMost]
    
    if sideMost[3] < 0 and topMost[3] < 0 and bottomMost[3] < 0 then return end
    -- This shouldn't be culled this way.
    --if sideMost[3] < 0 or topMost[3] < 0 or bottomMost[3] < 0 then return end
    --if sideMost[1] < 0 or topMost[1] < 0 or bottomMost[1] < 0 or sideMost[1] > width or topMost[1] > width or bottomMost[1] > width then return end
    --if sideMost[2] < 0 or topMost[2] < 0 or bottomMost[2] < 0 or sideMost[2] > height or topMost[2] > height or bottomMost[2] > height then return end
    
    local longestLength = topMost[2] - bottomMost[2]
    local sideLength = sideMost[2] - bottomMost[2]
    
    
    if bottomMost[2] > height or topMost[2] < 0 then return end

    UiColor(unpack(color))
    
    local lerpA = 1
    local lerpb = 1
    local longestLengthRecip = 1/longestLength
    local sideLengthRecip = 1/sideLength
    local otherSideLengthRecip = 1/(longestLength-sideLength)
    
    local bottomDrawOffset = -min(bottomMost[2] - OVERSCANMARGIN,0)
    
    local midDrawOffset = -min(sideMost[2] -OVERSCANMARGIN, 0)
    local topMidDrawOffset = -max(sideMost[2]-height+OVERSCANMARGIN,0)
    
    local topDrawOffset = -max(topMost[2]-height+OVERSCANMARGIN,0)


    local leftDrawOffset = 0
    local rightDrawOffset = 0
    
    local lineWidth = 0
    local lineSign = 0
    
    
    if bottomMost[2] ~= sideMost[2] then
        for y = bottomDrawOffset, (sideLength+topMidDrawOffset)-1 do
            
            local lerpedSide = VecLerp(bottomMost, topMost, y*longestLengthRecip)
            local lerpedOtherSide = VecLerp(bottomMost, sideMost, y*sideLengthRecip)
            
            lerpedSide[1] = math.floor(lerpedSide[1] + 0.5)
            lerpedSide[2] = math.floor(lerpedSide[2] + 0.5)
            lerpedOtherSide[1] = math.floor(lerpedOtherSide[1] + 0.5)
            lerpedOtherSide[2] = math.floor(lerpedOtherSide[2] + 0.5)
            
            lineWidth = (lerpedOtherSide[1] - lerpedSide[1])
            
            
            if lineWidth > 0 then
                leftDrawOffset = -math.min(lerpedSide[1] - OVERSCANMARGIN,0) 
                rightDrawOffset = math.max(0, (lerpedOtherSide[1] - width) + OVERSCANMARGIN)
            else
                leftDrawOffset = math.min((width-lerpedSide[1]) - OVERSCANMARGIN,0) 
                rightDrawOffset = math.min(0, lerpedOtherSide[1] - OVERSCANMARGIN)
            end
            


            if ((lineWidth - leftDrawOffset) - rightDrawOffset > 0 and lineWidth > 0) or ((lineWidth - leftDrawOffset) - rightDrawOffset <= 0 and lineWidth <= 0) then
                push()
                    translate((lerpedSide[1] + leftDrawOffset)*renderScale,lerpedSide[2]*renderScale)
                    rect(((lineWidth - leftDrawOffset) - rightDrawOffset)*renderScale,renderScale)
                pop()
            end
        end
    end
    
    if topMost[2] ~= sideMost[2] then
        for y = sideLength + midDrawOffset, (longestLength + topDrawOffset)-1 do
            local lerpedSide = VecLerp(bottomMost, topMost, y*longestLengthRecip)
            local lerpedOtherSide = VecLerp(sideMost, topMost, (y-sideLength)*otherSideLengthRecip)
            
            lerpedSide[1] = math.floor(lerpedSide[1] + 0.5)
            lerpedSide[2] = math.floor(lerpedSide[2] + 0.5)
            lerpedOtherSide[1] = math.floor(lerpedOtherSide[1] + 0.5)
            lerpedOtherSide[2] = math.floor(lerpedOtherSide[2] + 0.5)
            
            lineWidth = (lerpedOtherSide[1] - lerpedSide[1])
            
            
            if lineWidth > 0 then
                leftDrawOffset = -math.min(lerpedSide[1] - OVERSCANMARGIN,0) 
                rightDrawOffset = math.max(0, (lerpedOtherSide[1] - width) + OVERSCANMARGIN)
            else
                leftDrawOffset = math.min((width-lerpedSide[1]) - OVERSCANMARGIN,0) 
                rightDrawOffset = math.min(0, lerpedOtherSide[1] - OVERSCANMARGIN)
            end
            

            if ((lineWidth - leftDrawOffset) - rightDrawOffset > 0 and lineWidth > 0) or ((lineWidth - leftDrawOffset) - rightDrawOffset <= 0 and lineWidth <= 0) then
                push()
                    translate((lerpedSide[1] + leftDrawOffset)*renderScale,lerpedSide[2]*renderScale)
                    rect(((lineWidth - leftDrawOffset) - rightDrawOffset)*renderScale,renderScale)
                pop()
            end
        end
    end
    
end

