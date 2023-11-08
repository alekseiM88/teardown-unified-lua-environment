-- detour built-in functions to make them work properly with different lua contexts and ULE complications

realSetValue = SetValue

-- reimplemented SetValue
ULE_lerpValues = {}

-- context is _G, more or less
function SetValue(lerpContext, variable, value, transition, duration, callback)
    local transition = transition or "linear"
    local duration = duration or 1

    ULE_lerpValues[#ULE_lerpValues+1] = {
        variableName = variable,
        context = lerpContext,
        from = lerpContext[variable],
        to = value,
        amount = 0,
        scale = 1/math.max(duration, 0.001),
        kind = transition,
        onCompleted = callback
    }
end

function ULE_UpdateLerpValues(dt)

    if #ULE_lerpValues < 1 then
        return
    end
    
    -- update lerps
    local cleanedLerps = {}
    for i, lerp in ipairs(ULE_lerpValues) do
    
        lerp.amount = math.min(lerp.amount + (dt * lerp.scale), 1)
        
        if lerp.kind == "linear" then   
            lerp.context[lerp.variableName] = ULE_Lerp(lerp.from, lerp.to, lerp.amount)
        elseif lerp.kind == "cosine" then
            lerp.context[lerp.variableName] = ULE_Lerp(lerp.from, lerp.to, 1-((math.cos(lerp.amount * 3.14159265)+1)*0.5))
        elseif lerp.kind == "easein" then
            lerp.context[lerp.variableName] = ULE_Lerp(lerp.from, lerp.to, math.pow(lerp.amount, 3))
        elseif lerp.kind == "easeout" then
            lerp.context[lerp.variableName] = ULE_Lerp(lerp.from, lerp.to, 1-math.pow(1-lerp.amount, 3))
        elseif lerp.kind == "bounce" then
            lerp.context[lerp.variableName] = ULE_Lerp(lerp.from, lerp.to, ((1-math.pow(1-lerp.amount,3))*1.5) - (math.pow(math.max((lerp.amount*2)-1, 0), 3) * 0.5))
        end
        
        
        if lerp.amount < 1 then
            cleanedLerps[#cleanedLerps+1] = lerp
        else
            lerp.context[lerp.variableName] = lerp.to
            if lerp.onCompleted then
                lerp.onCompleted()
            end
        end
    end
    
    ULE_lerpValues = cleanedLerps
end 

function ULE_FixUpRegistryKey(context, key)
    if key then
        return string.gsub(key, "savegame.mod", "savegame.mod."..context.ULE_modRegistryKey)
    else
        return context
    end
    
end

-- override registry getters and setters
-- If context is provided then anything using "savegame.mod" will be modified.
-- If the context argument is omitted entirely (not just nil) then the functions will behave exactly as they do by default.
_realGetInt = GetInt
_realSetInt = SetInt

function GetInt(context, key)
    return _realGetInt(ULE_FixUpRegistryKey(context, key))
end

function SetInt(context, key, value)
    if value ~= nil then
        _realSetInt(ULE_FixUpRegistryKey(context, key), value)
    else
        _realSetInt(context, key)
    end
end

_realGetFloat = GetFloat
_realSetFloat = SetFloat

function GetFloat(context, key)
    return _realGetFloat(ULE_FixUpRegistryKey(context, key))
end

function SetFloat(context, key, value)
    if value ~= nil then
        _realSetFloat(ULE_FixUpRegistryKey(context, key), value)
    else
        _realSetFloat(context, key)
    end
end

_realGetString = GetString
_realSetString = SetString

function GetString(context, key)
    return _realGetString(ULE_FixUpRegistryKey(context, key))
end

function SetString(context, key, value)
    if value ~= nil then
        _realSetString(ULE_FixUpRegistryKey(context, key), value)
    else
        _realSetString(context, key)
    end
end

_realGetBool = GetBool
_realSetBool = SetBool

function GetBool(context, key)
    return _realGetBool(ULE_FixUpRegistryKey(context, key))
end

function SetBool(context, key, value)

    if value ~= nil then
        _realSetBool(ULE_FixUpRegistryKey(context, key), value)
    else
        _realSetBool(context, key)
    end
end

-- override misc registry
_realClearKey = ClearKey

function ClearKey(context, key)
    _realClearKey(ULE_FixUpRegistryKey(context, key))
end


_realListKeys = ListKeys

function ListKeys(context, parent)
    return _realListKeys(ULE_FixUpRegistryKey(context, parent))
end


_realHasKey = HasKey

function HasKey(context, key)
    return _realHasKey(ULE_FixUpRegistryKey(context, key))
end