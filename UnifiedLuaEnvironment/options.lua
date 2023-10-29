#include "ule_common.lua"
#include "ule_function_overrides.lua"

SIDEMARGIN = 6
SIDEMARGINDOUBLE = SIDEMARGIN*2

BUTTONHEIGHT = 45
BUTTONVERTICALMARGIN = 5

TEXTMARGIN = 12
FONTSIZE = 26

local realMenu = realMenu or Menu



function init()

    ULE_optionsFadeOpacity = ULE_optionsFadeOpacity or 0

    availableMods = {}
    selectedModIndex = selectedModIndex or -1
    selectedMod = selectedMod or nil
    scrollDistance = 0
    scrollDistanceNormalized = 0

    local allMods = ListKeys("mods.available")
    for i, regKey in ipairs(allMods) do
        local baseKey = "mods.available."..regKey.."."
    

        local modPath = "RAW:"..GetString(baseKey.."path")
        
        -- if mod has ule_main.lua then add it to availableMods      
        if HasFile(modPath.."/ule_main.lua") then
        
            local icon = modPath.."/preview.jpg"
            if not HasFile(icon) then icon = nil end
            table.insert(availableMods, {name = GetString(baseKey.."listname"), path = GetString(baseKey.."path"), keyName = regKey, iconPath = icon, description = GetString(baseKey.."description"), hasOptions = HasFile(modPath.."/ule_options.lua"), enabled = GetBool("savegame.mod.mods."..regKey)})

        end
    end

end

function drawToggle(currentState)
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

function drawEnableToggle(mod)
    -- enable button
    local newState = drawToggle(mod.enabled)
    if newState ~= mod.enabled then
        mod.enabled = newState
        if mod.enabled then
            -- add key to mods if enabled
            SetBool("savegame.mod.mods."..mod.keyName, true)
        else
            -- otherwise clear
            ClearKey("savegame.mod.mods."..mod.keyName)
        end
    end
    --[[
    if UiImageButton("ui/common/box-outline-6.png") then
        mod.enabled = not mod.enabled
        if mod.enabled then
            -- add key to mods if enabled
            SetBool("savegame.mod.mods."..mod.keyName, true)
        else
            -- other wise clear
            ClearKey("savegame.mod.mods."..mod.keyName)
        end
    end
    ]]--
    if mod.enabled then
        UiImage("ui/common/box-solid-6.png")
    end
end

function fakeMenu()
    UiDisableInput()
    SetValue(_G, "ULE_optionsFadeOpacity", 1, "linear", 0.125, function()
        drawMain = r_Draw
        init = r_Init
        tickMain = r_Tick
        update = r_Update
        
        init()
        SetValue(_G, "ULE_optionsFadeOpacity", 0, "linear", 0.125, function()
            UiEnableInput()
        end)
    end)
end

function openOptionsFile(mod)
    local optionsFile = loadfile(mod.path.."/".."ule_options.lua")
    
    if type(optionsFile) ~= "function" then
        DebugPrint("ULE: Could not open 'ule_options.lua'")
        return
    end
    
    -- bon voyage
    
    r_Draw = drawMain
    r_Init = init
    r_Tick = tickMain
    r_Update = update
    
    drawMain = nil
    init = nil
    tickMain = nil
    update = nil
    
    ULE_rawPath = mod.path
    ULE_modPath = "RAW:"..mod.path.."/"
    ULE_modRegistryKey = mod.keyName
    
    local tempDraw = draw
    local tempTick = tick
    
    draw = nil
    tick = nil
    
    optionsFile()
    
    drawMain = draw
    tickMain = tick
    
    draw = tempDraw
    tick = tempTick
    
    Menu = fakeMenu
    
    
    if init then
        init()
    end
end

function draw(dt)
    if drawMain then
        drawMain(dt)
    end
    -- fade rect
    UiColor(0, 0, 0, ULE_optionsFadeOpacity)
    UiRect(UiWidth(), UiHeight())
end

function tick(dt)
    ULE_UpateLerpValues(dt)
    if tickMain then
        tickMain(dt)
    end
end

function drawMain(dt)

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
            scrollDistance = math.max(math.min((UiHeight()-24), scrollDistance + (((InputValue("mousewheel")*-12000) / (UiHeight()-24)))), 0)
            scrollDistance = UiSlider("ui/terminal/button-bright-round-6.png", "y", scrollDistance, 0, UiHeight()-24)
            scrollDistanceNormalized = scrollDistance / (UiHeight()-24)
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
                UiTranslate(0, -(scrollDistanceNormalized * (#availableMods-1) * (BUTTONHEIGHT + BUTTONVERTICALMARGIN)))

                for i, mod in ipairs(availableMods) do
                    if selectedModIndex == i then
                        UiPush()
                            UiColor(0.15, 0.6, 0.9, 0.8)
                            UiImageBox("ui/common/box-solid-6.png", UiWidth()-SIDEMARGINDOUBLE, BUTTONHEIGHT, 6, 6)
                        UiPop()
                    end
                    
                    UiPush()
                        UiButtonPressColor(0.15, 0.6, 0.9, 1)
                        if UiTextButton(mod.name, UiWidth()-SIDEMARGINDOUBLE, BUTTONHEIGHT) then
                            selectedModIndex = i
                            selectedMod = availableMods[selectedModIndex]
                        end
                    UiPop()
                    
                    UiPush()
                        UiAlign("center middle")
                        UiTranslate(BUTTONHEIGHT/2,BUTTONHEIGHT/2)
                        -- enable button
                        drawEnableToggle(mod)
                        
                    UiPop()
                    UiTranslate(0,BUTTONHEIGHT + BUTTONVERTICALMARGIN)
                    

                end

            UiPop()
        UiPop()
  
    UiPop()
    
    
    
    -- right two thirds, information and the like
    UiPush()
        UiButtonPressDist(0)
        UiAlign("left top")
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
                realMenu()
            end
        UiPop()
        
        if selectedMod then
        UiPush()
            UiWordWrap(UiWidth()-45)
        
            UiFont("RobotoMono-Regular.ttf", FONTSIZE)
            UiAlign("left top")
            
            UiTranslate(TEXTMARGIN, TEXTMARGIN)
            UiText("NAME: "..selectedMod.name, true)
            
            UiTranslate(0, TEXTMARGIN)
            UiText("DESC: "..selectedMod.description, true)
            
            UiTranslate(0, TEXTMARGIN*2)
            UiPush()
                -- enable toggle
                UiAlign("center middle")
                UiTranslate((FONTSIZE/2) + 6,FONTSIZE/2)
                drawEnableToggle(selectedMod)
            UiPop()
            UiPush()
                UiTranslate(40, 0)
                if selectedMod.enabled then
                    UiText("ENABLED")
                else
                    UiText("DISABLED")
                end
                
                -- options button
                if selectedMod.hasOptions then
                    UiTranslate(180, -3)
                    if UiTextButton("OPTIONS", 128, 32) then
                        UiDisableInput()
                        SetValue(_G, "ULE_optionsFadeOpacity", 1, "linear", 0.125, function()
                            openOptionsFile(selectedMod)
                            SetValue(_G, "ULE_optionsFadeOpacity", 0, "linear", 0.125, function()
                                UiEnableInput()
                            end)
                        end)
                    end
                end
            UiPop()
           
           -- draw icon
            if selectedMod.iconPath then
                UiPush()
                    UiAlign("top left")
                    UiTranslate(0,TEXTMARGIN+42)
                    UiScale(0.5)
                    UiImage(selectedMod.iconPath)
                UiPop()
            end
           
        UiPop()

        end
    UiPop()
    

end

function tickMain()

end