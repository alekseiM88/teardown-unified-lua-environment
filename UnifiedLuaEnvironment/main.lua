
-- Unified Lua Environment. Created by TextureLikeSun/MSN/erratis

-- methods are ULE_PascalCase, variables are ULE_camelCase

#include "ule_function_overrides.lua"
#include "ule_common.lua"
#include "ule_ui.lua"
#include "ule_notifier.lua"
#include "ule_optionsmenu.lua"


lateInitCalled = lateInitCalled or false
isLoading = false


function init()
    ULE_Init()

    -- Add and execute all enabled ULE-based mods.
    local allMods = ListKeys("savegame.mod.mods")
    for i, key in ipairs(allMods) do
    
        local fullKey = "mods.available."..key
        
        local modName = GetString(fullKey..".listname")

        if not ULE_AddMod(modName, GetString(fullKey..".path"), key) then
            ClearKey("savegame.mod.mods."..key)
        end
    end

end

-- This function mainly exists for deserialization.
function ULE_Init()
    -- 'g' tables of all loaded mods
    ULE_mods = ULE_mods or {}
    ULE_modManagerActive = false
    
    -- g metatable for all g tables
    ULE_gMetatable = ULE_gMetatable or {}
    ULE_gMetatable.__index = _G
    
    ULE_SetupNotifier()
    ULE_SetupUi()
    ULE_SetupOptionsMenu()
    
    -- override mod manager exit function
    ULE_optionsMenu.Exit = function()
        UiDisableInput()
        SetValue(ULE_optionsMenu, "ULE_optionsFadeOpacity", 1, "linear", 0.2, function()
            ULE_modManagerActive = false
            SetValue(ULE_optionsMenu, "ULE_optionsFadeOpacity", 0, "linear", 0.2, function()
                UiEnableInput()
            end)
        end)
        
    end
    
    -- override mod state change callback
    ULE_optionsMenu.OnModActiveStateChanged = function(mod) 
        if mod.enabled then
            local addedMod = ULE_AddMod(mod.name, mod.path, mod.keyName)
            
            -- force call late init, since we're past real initialization
            ULE_ProtectedRawCall(addedMod, "ULE_LateInit")
        else
            ULE_DestroyMod(mod.name)
        end
    end

end

-- run ULE_AddMod on a table of lua files with keys as names and values as local paths.
-- The filenames in paths should not have any non-alphanumeric characters, as the filenames will be used to create their savegame registry keys
-- returns table of mods added, where keys are the mod names and values are their environment tables
function ULE_InitModList(context, paths)

    local addedMods = {}

    -- add mods
    for name, path in pairs(paths) do
        local gTable = ULE_AddMod(name, context.ULE_rawPath, context.ULE_modRegistryKey.."-"..string.gsub(path, ".lua", ""), path, isLoading)

        if gTable then
            addedMods[name] = gTable
        end
    end
    
    -- force call late init, if we're past real initialization
    if lateInitCalled then
        ULE_ProtectedRawCallOnContexts(addedMods, "ULE_LateInit")
    end
   
    return addedMods
end

-- same as above except the source is then destroyed with ULE_DestroyMod. It is recommended that you don't use this function, as it can break hotloading.
function ULE_InitModListAndDestroySource(context, paths)

    local addedMods = ULE_InitModList(context, paths)
    
    -- destroy source
    ULE_DestroyMod(context.ULE_modKey)

    return addedMods
end


-- path is aboslute, name is string
function ULE_AddMod(name, directory, regKey, filePath, reload)

    local filePath = filePath or "ule_main.lua"
    local absoluteDirectory = directory.."/"..filePath

    if not HasFile("RAW:"..absoluteDirectory) then
        DebugPrint("ULE: Could not load mod of name '"..name.."', file '"..filePath.."' not found.")
        return false
    end

    -- load mod data from file
    local newMod = loadfile(absoluteDirectory)

    if type(newMod) ~= "function" then
        DebugPrint("ULE: Could not load mod of name '"..name.."', loadfile could not parse. Probably a syntax error.")
        return false
    end
   
   
    if ULE_mods[name] ~= nil then
        if not reload and not ULE_mods[name].ULE_isDestroyed then 
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
    modGTable.ULE_fileName = filePath
    modGTable.ULE_isDestroyed = false

    modGTable._G = modGTable

    -- set gTable's environment
    setfenv(newMod, modGTable)
    
    -- execute
    newMod()

    -- run init
    if not reload then
        ULE_ProtectedRawCall(modGTable, "init")
    end
    
    return modGTable
end

-- remove a mod from ULE_mods, calling ULE_OnDestroy() and then set all present indices to nil
-- name is key in ULE_mods table
function ULE_DestroyMod(name)
    if name == nil then return end
   
    local gTable = ULE_mods[name]
    
    if gTable == nil then
        DebugPrint("ULE: Could not destroy mod of name '"..name.."'. Mod could not be found in ULE_mods.")
        return
    end
    
    ULE_ProtectedRawCall(gTable, "ULE_OnDestroy")
    
    -- remove metatable and nil out all indices of mod's gTable
    setmetatable(gTable, nil)
    for k, _ in pairs(gTable) do
        gTable[k] = nil
    end
   
    -- flag that this mod is destroyed
    gTable.ULE_isDestroyed = true
    
    --ULE_mods[name] = nil
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
    -- mod manager toggling
    if PauseMenuButton("ULE Mod Manager", true) then
        UiDisableInput()
        SetValue(ULE_optionsMenu, "ULE_optionsFadeOpacity", 1, "linear", 0.2, function()
            ULE_modManagerActive = true
            UiEnableInput()
            ULE_optionsMenu.modOptionsGTable = nil
            ULE_optionsMenu.Init()
        end)
    end

    if ULE_modManagerActive then
        SetBool("game.disablepause", true)
        SetBool("game.disablemap", true)
        SetBool("game.player.disableinput", true)
    
        ULE_optionsMenu.Tick(dt)
        
        -- hacky back buttons
        if InputPressed("pause") then
            if ULE_optionsMenu.modOptionsGTable then
                ULE_optionsMenu.FakeMenu()
            else
                ULE_optionsMenu.Exit()
            end
        end
    end
    
    -- Call ULE_LateInit on first frame after int. All mods are initialized at this point and they can interact safely at this time.
    if not lateInitCalled then
        ULE_ProtectedRawCallOnContexts(ULE_mods, "ULE_LateInit")
        lateInitCalled = true
    end

    -- Update lerp values, so the overridden SetValue functions correctly.
    ULE_UpdateLerpValues(dt)

    ULE_ProtectedRawCallOnContexts(ULE_mods, "tick", dt)

    ULE_ProtectedRawCallOnContexts(ULE_mods, "ULE_PostTick", dt)
end


function update(dt)
    if ULE_modManagerActive then
        ULE_optionsMenu.Update(dt)
    end

    ULE_ProtectedRawCallOnContexts(ULE_mods, "update", dt)
    
    ULE_ProtectedRawCallOnContexts(ULE_mods, "ULE_PostUpdate", dt)
end


function draw(dt)
    if ULE_modManagerActive then
        UiPush()
            UiColor(0,0,0,1)
            UiRect(UiWidth(), UiHeight())
            UiColor(1,1,1,1)
            UiMakeInteractive()
            ULE_optionsMenu.Draw(dt)
        UiPop()
        return -- return, stop other mods from drawing
    end

    UiPush()
        ULE_ProtectedRawCallOnContexts(ULE_mods, "draw", dt)

        ULE_ProtectedRawCallOnContexts(ULE_mods, "ULE_PostDraw", dt)
    UiPop()

    -- draw and update the notification system
    ULE_notifier.Update(dt)
    
    -- mild hack for mod manager fade
    if not ULE_modManagerActive then
        UiColor(0, 0, 0, ULE_optionsMenu.ULE_optionsFadeOpacity)
        UiRect(UiWidth(), UiHeight())
    end
end


function handleCommand(command)
    -- partial reinit of all loaded mods
    if command == "quickload" then
        ULE_Init()
        
        isLoading = true
        for modName, gTable in pairs(ULE_mods) do
            if not gTable.ULE_isDestroyed then
                ULE_AddMod(modName, gTable.ULE_rawPath, gTable.ULE_modRegistryKey, gTable.ULE_fileName, true)
            end
        end
        isLoading = false
    end

    ULE_ProtectedRawCallOnContexts(ULE_mods, "handleCommand", command)
end