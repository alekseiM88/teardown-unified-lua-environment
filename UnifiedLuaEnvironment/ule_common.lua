function ULE_Lerp(a, b, t)
    return (b*t) + (a*(1-t))
end

function ULE_ProtectedRawCall(context, functionName, ...)
    local func = rawget(context, functionName)
    if not func then return end
    local succeeded, message = pcall(func, unpack(arg))
    if not succeeded then DebugPrint(message) end
end