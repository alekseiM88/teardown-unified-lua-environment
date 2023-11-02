function ULE_Lerp(a, b, t)
    return (b*t) + (a*(1-t))
end

function ULE_ProtectedRawCall(context, functionName, ...)
    local func = rawget(context, functionName)
    if not func then return end
    local succeeded, message = pcall(func, unpack(arg))
    if not succeeded then DebugPrint(message) end
end

function ULE_ProtectedRawCallOnContexts(contexts, functionName, ...)
    for name, context in pairs(contexts) do

        local func = rawget(context, functionName)
        
        if func then
            local succeeded, message = pcall(func, unpack(arg))
            
            if not succeeded then DebugPrint(message) end
        end
    end
end

--#include replacement that work in ULE, paths should still work as relative, you will probably always pass in _G as the context
function ULE_IncludeLua(context, path)

    if context.ULE_rawPath == nil then
        DebugPrint("ULE: Could not include file '"..path.."', context is invalid.")
        return
    end

    local luaFile = loadfile(context.ULE_rawPath.."/"..path)
    
    if type(luaFile) ~= "function" then
        DebugPrint("ULE: Could not include file '"..path.."', file might not exist.")
        return
    end
    
    -- set environment
    setfenv(luaFile, context)

    -- execute
    luaFile()
end

-- helper function. context is Lua environment, key is the undetoured registry key, data is the data to be held at that key,
-- and if reset is true then the data will be overridden regardless of if that key already exists
-- will forcefully reset string if it is '?'
function ULE_InitializePersistentRegistryKey(context, key, data, reset)
    local dataType = type(data)

    -- '?' case
    if dataType == "string" and GetString(context, key) == "?" then
        reset = true
    end
    
    if (HasKey(context, key) and not reset) then return end
    
    if dataType == "number" then
        if math.floor(data) == data then -- integer
            SetInt(context, key, data)
        else -- float
            SetFloat(context, key, data)
        end
    elseif dataType == "string" then
        SetString(context, key, data)
    elseif dataType == "boolean" then
        SetBool(context, key, data)
    else
        DebugPrint("ULE: Cannot initialize persistent registry key at path: "..key..". The type of 'data' is not valid.")
    end
end