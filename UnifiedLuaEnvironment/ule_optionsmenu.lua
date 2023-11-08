#include "ule_function_overrides.lua"
#include "ule_common.lua"
#include "ule_ui.lua"


ULE_optionsMenu = {}

function ULE_SetupOptionsMenu()
    ULE_optionsMenu.SIDEMARGIN = 6
    ULE_optionsMenu.SIDEMARGINDOUBLE = ULE_optionsMenu.SIDEMARGIN*2

    ULE_optionsMenu.BUTTONHEIGHT = 45
    ULE_optionsMenu.BUTTONVERTICALMARGIN = 5

    ULE_optionsMenu.TEXTMARGIN = 12
    ULE_optionsMenu.FONTSIZE = 26

    ULE_optionsMenu.ULE_optionsFadeOpacity = 0

    -- environment of mods' options environment
    ULE_optionsMenu.modOptionsGTable = nil

    function ULE_optionsMenu.Init()

        ULE_optionsMenu.availableULEMods = {}
        
        ULE_optionsMenu.selectedModIndex = -1
        ULE_optionsMenu.selectedMod = nil
        ULE_optionsMenu.scrollDistance = 0
        ULE_optionsMenu.scrollDistanceNormalized = 0
        ULE_optionsMenu.Exit = ULE_optionsMenu.Exit or function() Menu() end

        local allMods = ListKeys("mods.available")
        for i, regKey in ipairs(allMods) do
            local baseKey = "mods.available."..regKey.."."

            local modPath = "RAW:"..GetString(baseKey.."path")
            
            -- if mod has ule_main.lua then add it to availableULEMods      
            if HasFile(modPath.."/ule_main.lua") then
            
                local icon = modPath.."/preview.jpg"
                if not HasFile(icon) then icon = nil end
                table.insert(ULE_optionsMenu.availableULEMods, {name = GetString(baseKey.."listname"), author = GetString(baseKey.."author"), path = GetString(baseKey.."path"), keyName = regKey, iconPath = icon, description = GetString(baseKey.."description"), hasOptions = HasFile(modPath.."/ule_options.lua"), enabled = GetBool("savegame.mod.mods."..regKey)})

            end
        end

        -- sort available mods by name
        table.sort(ULE_optionsMenu.availableULEMods, function(a, b)
            return table.concat({string.byte(a.name)}) > table.concat({string.byte(b.name)})
        end)


        -- start fade
        ULE_optionsMenu.ULE_optionsFadeOpacity = 1
        SetValue(ULE_optionsMenu, "ULE_optionsFadeOpacity", 0, "linear", 0.2)
    end


    function ULE_optionsMenu.DrawToggle(currentState)
        -- enable button
        UiPush()
        UiAlign("center middle")
            if currentState then
                UiImage("ui/common/box-solid-6.png")
            end
            
            if UiImageButton("ui/common/box-outline-6.png") then
                UiPop()
                return not currentState
            end
        UiPop()
        return currentState
    end

    function ULE_optionsMenu.DrawEnableToggle(mod)
        -- enable button
        local newState = ULE_optionsMenu.DrawToggle(mod.enabled)
        if newState ~= mod.enabled then
            mod.enabled = newState
            
            if mod.enabled then
                -- add key to mods if enabled
                SetBool("savegame.mod.mods."..mod.keyName, true)
            else
                -- otherwise clear
                ClearKey("savegame.mod.mods."..mod.keyName)
            end
            
            ULE_optionsMenu.OnModActiveStateChanged(mod)
        end

        if mod.enabled then
            UiImage("ui/common/box-solid-6.png")
        end
    end
    
    function ULE_optionsMenu.OnModActiveStateChanged(mod)
    
    end

    function ULE_optionsMenu.OpenOptionsFile(mod)
        local optionsFile = loadfile(mod.path.."/".."ule_options.lua")
        
        if type(optionsFile) ~= "function" then
            DebugPrint("ULE: Could not open 'ule_options.lua'")
            return
        end
        

        local optionsGTableMetatable = {}
        optionsGTableMetatable.__index = _G
        
        
        -- create options table and set metatable
        ULE_optionsMenu.modOptionsGTable = {}
        setmetatable(ULE_optionsMenu.modOptionsGTable, optionsGTableMetatable)
    
        -- override menu
        ULE_optionsMenu.modOptionsGTable.Menu = ULE_optionsMenu.FakeMenu

    
        -- set ULE variables, this is only a subset of what ule_main gets.
        ULE_optionsMenu.modOptionsGTable.ULE_rawPath = mod.path
        ULE_optionsMenu.modOptionsGTable.ULE_modPath = "RAW:"..mod.path.."/"
        ULE_optionsMenu.modOptionsGTable.ULE_modRegistryKey = mod.keyName

        ULE_optionsMenu.modOptionsGTable._G = ULE_optionsMenu.modOptionsGTable

        -- set load file function's environment
        setfenv(optionsFile, ULE_optionsMenu.modOptionsGTable)
        
        -- execute loaded file
        optionsFile()
        
        -- call options init
        ULE_ProtectedRawCall(ULE_optionsMenu.modOptionsGTable, "init")
    end


    function ULE_optionsMenu.FakeMenu()
        UiDisableInput()
        SetValue(ULE_optionsMenu, "ULE_optionsFadeOpacity", 1, "linear", 0.2, function()
            ULE_optionsMenu.modOptionsGTable = nil
            SetValue(ULE_optionsMenu, "ULE_optionsFadeOpacity", 0, "linear", 0.2, function()
                UiEnableInput()
            end)
        end)
    end
    
    
    function ULE_optionsMenu.Tick(dt)
        if ULE_optionsMenu.modOptionsGTable ~= nil then
            ULE_ProtectedRawCall(ULE_optionsMenu.modOptionsGTable, "tick", dt)
            return
        end
    end

    function ULE_optionsMenu.Update(dt)
        if ULE_optionsMenu.modOptionsGTable ~= nil then
            ULE_ProtectedRawCall(ULE_optionsMenu.modOptionsGTable, "update", dt)
            return
        end
    end
        
    function ULE_optionsMenu.Draw(dt)
        if ULE_optionsMenu.modOptionsGTable ~= nil then
            ULE_ProtectedRawCall(ULE_optionsMenu.modOptionsGTable, "draw", dt)
            return
        end
        
        ULE_optionsMenu.DrawModMenu(dt)
        
        -- fade rect
        UiColor(0, 0, 0, ULE_optionsMenu.ULE_optionsFadeOpacity)
        UiRect(UiWidth(), UiHeight())
    end


    function ULE_optionsMenu.DrawModMenu(dt)
        local SIDEMARGIN = ULE_optionsMenu.SIDEMARGIN
        local SIDEMARGINDOUBLE = ULE_optionsMenu.SIDEMARGINDOUBLE

        local BUTTONHEIGHT = ULE_optionsMenu.BUTTONHEIGHT
        local BUTTONVERTICALMARGIN = ULE_optionsMenu.BUTTONVERTICALMARGIN

        local TEXTMARGIN = ULE_optionsMenu.TEXTMARGIN
        local FONTSIZE = ULE_optionsMenu.FONTSIZE


        UiFont("regular.ttf", FONTSIZE)

        UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
        UiColor(1, 1, 1, 1)
        

        -- Left Third Panel, selection
        UiPush()
            UiAlign("left top")
            UiTranslate(SIDEMARGIN,SIDEMARGIN)
            UiWindow((UiWidth()/3)-SIDEMARGIN, UiHeight()-SIDEMARGINDOUBLE, false)
            UiImageBox("ui/common/box-outline-6.png", UiWidth(), UiHeight(), 6, 6)
            
            -- slider
            UiPush()
                UiAlign("right middle")
                UiTranslate(UiWidth()-1,12)
                ULE_optionsMenu.scrollDistance = math.max(math.min((UiHeight()-24), ULE_optionsMenu.scrollDistance + (((InputValue("mousewheel")*-12000) / (UiHeight()-24)))), 0)
                ULE_optionsMenu.scrollDistance = UiSlider("ui/terminal/button-bright-round-6.png", "y", ULE_optionsMenu.scrollDistance, 0, UiHeight()-24)
                ULE_optionsMenu.scrollDistanceNormalized = ULE_optionsMenu.scrollDistance / (UiHeight()-24)
                --DebugPrint(scrollDistanceNormalized)
            UiPop()
            
            UiPush()
                UiAlign("left top")
                UiWindow(UiWidth()-18, UiHeight(), true)

                UiImageBox("ui/common/box-outline-6.png", UiWidth(), UiHeight(), 6, 6)
                
                -- draw mod buttons
                UiPush()
                    UiAlign("left top")
                    
                    UiButtonPressDist(0)
                    UiTranslate(SIDEMARGIN,SIDEMARGIN)
                    
                    -- scroll offset
                    UiTranslate(0, -(ULE_optionsMenu.scrollDistanceNormalized * (#ULE_optionsMenu.availableULEMods-1) * (BUTTONHEIGHT + BUTTONVERTICALMARGIN)))

                    for i, mod in ipairs(ULE_optionsMenu.availableULEMods) do
                        if ULE_optionsMenu.selectedModIndex == i then
                            UiPush()
                                UiColor(0.15, 0.6, 0.9, 0.8)
                                UiImageBox("ui/common/box-solid-6.png", UiWidth()-SIDEMARGINDOUBLE, BUTTONHEIGHT, 6, 6)
                            UiPop()
                        end
                        
                        UiPush()
                            UiButtonPressColor(0.15, 0.6, 0.9, 1)
                            if UiTextButton(mod.name, UiWidth()-SIDEMARGINDOUBLE, BUTTONHEIGHT) then
                                ULE_optionsMenu.selectedModIndex = i
                                ULE_optionsMenu.selectedMod = ULE_optionsMenu.availableULEMods[ULE_optionsMenu.selectedModIndex]
                            end
                        UiPop()
                        
                        UiPush()
                            UiAlign("center middle")
                            UiTranslate(BUTTONHEIGHT/2,BUTTONHEIGHT/2)
                            -- enable button
                            ULE_optionsMenu.DrawEnableToggle(mod)
                            
                        UiPop()
                        UiTranslate(0,BUTTONHEIGHT + BUTTONVERTICALMARGIN)
                        

                    end

                UiPop()
            UiPop()
      
        UiPop()
        
        
        
        -- right two thirds, information and the like
        UiPush()
            UiButtonPressDist(0)
            --UiAlign("left top")
            UiTranslate((UiWidth()/3) + SIDEMARGIN, SIDEMARGIN)
            UiWindow(((UiWidth()/3)*2)-SIDEMARGINDOUBLE, UiHeight()-SIDEMARGINDOUBLE)
            UiImageBox("ui/common/box-outline-6.png", UiWidth(), UiHeight(), 6, 6)
            
            -- ULE Title
            UiPush()
                UiAlign("bottom left")
                UiTranslate(TEXTMARGIN, UiHeight()-56)
                UiFont("bold.ttf", FONTSIZE*3)
                UiText("Unified Lua Environment")
                
                UiTranslate(24, FONTSIZE*1.5)
                
                UiFont("RobotoMono-Regular.ttf", FONTSIZE)
                
                UiText("Created by TextureLikeSun/msn/erratis")

            UiPop()
            UiPush()
                -- back button
                UiTranslate(UiWidth()-TEXTMARGIN, UiHeight()-TEXTMARGIN)
                UiAlign("bottom right")
                if UiTextButton("Back", 64, 32) then
                    ULE_optionsMenu.Exit()
                end
            UiPop()
            
            if ULE_optionsMenu.selectedMod then
            UiPush()
                UiWordWrap(UiWidth()-45)
            
                UiFont("RobotoMono-Regular.ttf", FONTSIZE)

                UiTranslate(TEXTMARGIN, (TEXTMARGIN*2) + SIDEMARGIN)
                UiText("NAME: "..ULE_optionsMenu.selectedMod.name, true)
                
                UiTranslate(0, TEXTMARGIN)
                UiText("AUTHOR: "..ULE_optionsMenu.selectedMod.author, true)   
                
                UiTranslate(0, TEXTMARGIN)
                UiText("DESC: "..ULE_optionsMenu.selectedMod.description, true)
                
                UiAlign("left top")
                
                UiTranslate(0, TEXTMARGIN*2)
                UiPush()
                    -- enable toggle
                    UiAlign("center middle")
                    UiTranslate((FONTSIZE/2) + 6,FONTSIZE/2)
                    ULE_optionsMenu.DrawEnableToggle(ULE_optionsMenu.selectedMod)
                UiPop()
                UiPush()
                    UiTranslate(40, 0)
                    if ULE_optionsMenu.selectedMod.enabled then
                        UiText("ENABLED")
                    else
                        UiText("DISABLED")
                    end
                    
                    -- options button
                    if ULE_optionsMenu.selectedMod.hasOptions then
                        UiTranslate(180, -3)
                        if UiTextButton("OPTIONS", 128, 32) then
                            UiDisableInput()
                            SetValue(ULE_optionsMenu, "ULE_optionsFadeOpacity", 1, "linear", 0.2, function()
                                ULE_optionsMenu.OpenOptionsFile(ULE_optionsMenu.selectedMod)
                                SetValue(ULE_optionsMenu, "ULE_optionsFadeOpacity", 0, "linear", 0.2, function()
                                    UiEnableInput()
                                end)
                            end)
                        end
                    end
                UiPop()
               
               -- draw icon
                if ULE_optionsMenu.selectedMod.iconPath then
                    UiPush()
                        UiAlign("top left")
                        UiTranslate(0,TEXTMARGIN+42)
                        UiScale(0.5)
                        UiImage(ULE_optionsMenu.selectedMod.iconPath)
                    UiPop()
                end
               
            UiPop()

            end
        UiPop()
        

    end

end
