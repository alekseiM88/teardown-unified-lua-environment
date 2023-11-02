-- ULE Model Library

-- assumes faces have only 3 edges

parseObjSwitch = {
    ["v"] = function(lineData, modelData)
        modelData.verts[#modelData.verts+1] = Vec(lineData[2], lineData[3], lineData[4])
        
        -- vertex colors
        if lineData[5] and modelData.colors then
            modelData.colors[#modelData.verts] = {lineData[5], lineData[6], lineData[7]}
        end
    end,
    ["f"] = function(lineData, modelData)
        -- faces are tables of indices, these indices can be used
        -- to index into the vertex table
        
        -- add one to the indices since lua is one indexed
        modelData.faces[#modelData.faces+1] = {SplitStringWithTypeCoercion(lineData[2], "\/")[1], SplitStringWithTypeCoercion(lineData[3], "\/")[1], SplitStringWithTypeCoercion(lineData[4], "\/")[1]}
    end
}

-- if addColors is true then the parser will atempt to add vertex colors if any are present.
function CreateModelFromObjLines(fileLines, addColors)
    local modelData = {}

    modelData.verts = {}
    modelData.faces = {}
    if addColors then
        modelData.colors = {}
    end

    for _, line in ipairs(fileLines) do
        -- parse line into data
        local lineData = SplitStringWithTypeCoercion(line, " ")
        
        if parseObjSwitch[lineData[1]] then
            parseObjSwitch[lineData[1]](lineData, modelData)
        end
    end
    
    CalculateNormals(modelData)
    
    return modelData
end

function CalculateNormals(modelData)
    -- calculate face normals
    modelData.normals = {}
    
    for i, f in ipairs(modelData.faces) do
        modelData.normals[i] = VecNormalize(VecCross(VecNormalize(VecSub(modelData.verts[f[2]], modelData.verts[f[1]])), VecNormalize(VecSub(modelData.verts[f[3]], modelData.verts[f[1]]))))
    end
end

function SplitStringWithTypeCoercion(str, separators)
    if separators == nil then
        separators = " "
    end
    
    local t = {}
    
    for subString in string.gmatch(str, "([^"..separators.."]+)") do
        table.insert(t, tonumber(subString) or subString)
    end
    
    return t
end

-- returns a NEW table with points table transformed to world space using the supplied transform
function TransformPointTable(points, transform)
    local transformedPoints = {}
    
    for i, v in ipairs(points) do
        transformedPoints[i] = TransformToParentPoint(transform, v)
    end
    return transformedPoints
end

function TransformDirTable(directions, transform)
    local transformedDirections = {}
    
    for i, v in ipairs(directions) do
        transformedDirections[i] = TransformToParentVec(transform, v)
    end
    return transformedDirections
end

