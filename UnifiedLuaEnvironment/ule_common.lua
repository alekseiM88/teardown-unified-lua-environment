function ULE_Lerp(a, b, t)
    return (b*t) + (a*(1-t))
end

function ULE_ProtectedRawCall(context, functionName, ...)
    local func = rawget(context, functionName)
    if not func then return end
    local succeeded, message = pcall(func, unpack(arg))
    if not succeeded then DebugPrint(message) end
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