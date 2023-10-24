
-- Unified Lua Environment. Created by TextureLikeSun/MSN/erratis

-- methods are ULE_PascalCase, variables are ULE_camelCase

#include "ule_common.lua"
#include "ule_function_overrides.lua"

lateInitCalled = lateInitCalled or false


function init()
    ULE_Init()

    -- find all mods with names that start with the uppercase ULE and try to add them.

    --[[
    local allMods = ListKeys("mods.available")
    for i, key in ipairs(allMods) do
        local modKey = "mods.available."..key
        local modName = GetString(modKey..".name")
        if string.sub(modName, 1, 3) == "ULE" then
            --DebugPrint(GetString(modKey..".path"))
            ULE_AddMod(modName, GetString(modKey..".path"))
            --return "RAW:"..GetString(modKey..".path").."/"
        end
    end
    ]]--
    
    local allMods = ListKeys("savegame.mod.mods")
    for i, key in ipairs(allMods) do
    
        local fullKey = "mods.available."..key

        local modName = GetString(fullKey..".name")
        --if string.sub(modName, 1, 3) == "ULE" then
        if not ULE_AddMod(modName, GetString(fullKey..".path"), key) then
            ClearKey("savegame.mod.mods."..key)
        end

        --end
    end

    -- proof of concept
    --[[
    gTables[1] = {}
    DebugPrint(tostring(gTables[1].GetPlayerTransform))
    --gTables[1].__index = _G
    setmetatable(gTables[1], gMetatable)
    DebugPrint(tostring(gTables[1].GetPlayerTransform))
    
    gTables[1].GetPlayerTransform = function() DebugPrint("test") end
    DebugPrint(tostring(gTables[1].GetPlayerTransform))
    DebugPrint(tostring(rawget(gTables[1], "GetPlayerTransform")))
    
    DebugPrint(tostring(GetPlayerTransform))
    
    gTables[1].GetPlayerTransform = nil
    DebugPrint(tostring(gTables[1].GetPlayerTransform))
    DebugPrint(tostring(rawget(gTables[1], "GetPlayerTransform")))
    ]]--
end

function ULE_Init()
    -- 'g' tables of all loaded mods
    ULE_mods = ULE_mods or {}
    
    -- g metatable for all g tables
    ULE_gMetatable = ULE_gMetatable or {}
    ULE_gMetatable.__index = _G
end

-- run ULE_AddMod on a table of lua files with keys as names and values as local paths, then ULE_DestroyMod on the source.
-- The filenames in paths should not have any non-alphanumeric characters, as the filenames will be used to create their savegame registry keys
function ULE_InitModListAndDestroySource(context, paths)
    DebugPrint("attempting bootstrap")
    -- add mods
    for name, path in pairs(paths) do
        ULE_AddMod(name, context.ULE_rawPath, context.ULE_modRegistryKey.."-"..string.gsub(path, ".lua", ""), path)
    end
    
    -- destroy source
    ULE_DestroyMod(context.ULE_modKey)
end

-- path is aboslute, name is string
function ULE_AddMod(name, directory, regKey, filePath, reload)

    local filePath = filePath or "ule_main.lua"

    local newMod = loadfile(directory.."/"..filePath)

    if type(newMod) ~= "function" then
        DebugPrint("ULE: Could not load mod of name '"..name.."'")
        return false
    end
   
   
    if ULE_mods[name] ~= nil then
        if not reload then 
            DebugPrint("ULE: Mod of name '"..name.."' already exists.")
            return true
        end
    else
        ULE_mods[name] = {}
    end
    local modGTable = ULE_mods[name]

    setmetatable(modGTable, ULE_gMetatable)
    
    -- let mod know its own path and its own key in ULE_mods
    modGTable.ULE_modPath = "RAW:"..directory.."/"
    modGTable.ULE_modKey = name -- key in ULE_mods
    modGTable.ULE_modRegistryKey = regKey -- key in the registry under availablemods
    modGTable.ULE_rawPath = directory

    modGTable._G = modGTable

    -- set gTable's environment
    setfenv(newMod, modGTable)
    
    -- execute
    newMod()
    
    -- run init
    if not reload then
        local modInit = rawget(modGTable, "init")
        if modInit then modInit() end
    end
    
    return true
end

--#include replacement that work in ULE, paths should still work as relative, you will probably always pass in _G as the context
function ULE_IncludeLua(context, path)

    if context.rawPath == nil then
        DebugPrint("ULE: Could not include file '"..path.."', context is invalid.")
        return
    end

    local luaFile = loadfile(context.rawPath.."/"..path)
    
    if type(luaFile) ~= "function" then
        DebugPrint("ULE: Could not include file '"..path.."', file might not exist.")
        return
    end
    
    -- set environment
    setfenv(luaFile, context)

    -- execute
    luaFile()
end

-- remove a mod from ULE_mods, fully clearing it from memory and all that
-- name is key in ULE_mods table
function ULE_DestroyMod(name)
    if name == nil then return end
   
    local modOnDestroy = rawget(ULE_mods[name], "ULE_OnDestroy")
    if modOnDestroy then modOnDestroy() end
   
    ULE_mods[name] = nil
end

-- returns gTable of mod, linear search, name is name of mod, returns nil if mod wasn't found
function ULE_FindMod(name)
    local gTable = ULE_mods[name]
    if gTable ~= nil then return gTable end
    return nil
end

-- find mod by 'ULE_name' variable of the mod's gTable, may not work for all ULE mods
function ULE_FindModByULEName(ulename)
    for _, gTable in pairs(ULE_mods) do
        if gTable.ULE_name == ulename then
            return gTable
        end
    end
    return nil
end

-- like above but returns name instead of gTable
function ULE_FindModNameByULEName(ulename)
    for name, gTable in pairs(ULE_mods) do
        if gTable.ULE_name == ulename then
            return name
        end
    end
    return nil
end

function tick(dt)
    
    -- Call ULE_LateInit on first frame after int. All mods are initialized at this point and they can interact safely at this time.
    if not lateInitCalled then
        local modLateInit = nil
        for modName, gTable in pairs(ULE_mods) do
            local modLateInit = rawget(gTable, "ULE_LateInit")
            if modLateInit then modLateInit() end
        end
        lateInitCalled = true
    end

    -- Update lerp values, so the overridden SetValue functions correctly.
    ULE_UpateLerpValues(dt)

    local modTick = nil
    for modName, gTable in pairs(ULE_mods) do
        local modTick = rawget(gTable, "tick")
        if modTick then modTick(dt) end
    end
end


function update(dt)
    local modUpdate = nil
    for modName, gTable in pairs(ULE_mods) do
        local modUpdate = rawget(gTable, "update")
        if modUpdate then modUpdate(dt) end
    end
end


function draw(dt)
    local modDraw = nil
    for modName, gTable in pairs(ULE_mods) do
        local modDraw = rawget(gTable, "draw")
        if modDraw then modDraw(dt) end
    end
end


function handleCommand(command)
    -- strange saving
    if command == "quickload" then
        ULE_Init()
    
        for modName, gTable in pairs(ULE_mods) do
            ULE_AddMod(modName, gTable.ULE_rawPath, gTable.ULE_modRegistryKey, nil, true)
        end
    end

    local modHandle = nil
    for modName, gTable in pairs(ULE_mods) do
        local modHandle = rawget(gTable, "handleCommand")
        if modHandle then modHandle(command) end
    end
end