ULE_IncludeLua(_G, "strength_shared.lua")

function init()
    InitializePersistentData()
    LINEMARGIN = 56
    TEXTSIZE = 48
    BUTTONWIDTH = 180
end

function tick()
    -- input
    UpdateInputForKey(_staticGrabToggleButtonKey)
    UpdateInputForKey(_toggleSuperStrengthButtonKey)
end

function draw()
    UiPush()
        UiFont("bold.ttf", TEXTSIZE)
        UiButtonImageBox("ui/common/box-outline-fill-6.png", 6, 6)
    
        -- main
        UiPush()
            local canGrabStaticBodies = GetBool(_G, _enableStaticGrabTogglingKey)
            local defaultStaticGrabState = GetBool(_G, _defaultStaticGrabStateKey)
            
            UiTranslate(UiCenter(), UiMiddle()-200)
            
            -- left side
            UiAlign("right")
            UiPush()
                UiText("The super strength toggle key is:")
                
                UiTranslate(0, LINEMARGIN)
            
                UiText("Static body grabbing defaults to being:")
                
                UiTranslate(0, LINEMARGIN)
            
                UiText("Toggling static body grabbing is:")
                
                UiTranslate(0, LINEMARGIN)
                
                if canGrabStaticBodies then
                    UiText("The static body grabbing toggle key is:")
                end
            UiPop()
            
            -- right side
            UiAlign("left")
            UiPush()
                UiTranslate(10, -TEXTSIZE/4)
                
                UiAlign("middle left")
                
                if UiTextButton(GetString(_G, _toggleSuperStrengthButtonKey), BUTTONWIDTH, TEXTSIZE) then
                    SetString(_G, _toggleSuperStrengthButtonKey, "?")
                end
                UiTranslate(0, LINEMARGIN)
                
                DrawToggleButton(_defaultStaticGrabStateKey)
                UiTranslate(0, LINEMARGIN)
                
                DrawToggleButton(_enableStaticGrabTogglingKey)
                UiTranslate(0, LINEMARGIN)
                
                if canGrabStaticBodies then
                    if UiTextButton(GetString(_G, _staticGrabToggleButtonKey), BUTTONWIDTH, TEXTSIZE) then
                        SetString(_G, _staticGrabToggleButtonKey, "?")
                    end
                end
                
            UiPop()
            
        UiPop()
        
        -- back button
        UiPush()
            UiAlign("top center")
            UiTranslate(UiCenter(), UiMiddle()+200)
            
            if UiTextButton("Back",128, 64) then
                Menu()
            end
        UiPop()
    UiPop()
end

function DrawToggleButton(registryKey)
    local value = GetBool(_G, registryKey)
    if UiTextButton(value and "Enabled" or "Disabled", BUTTONWIDTH, TEXTSIZE) then
        SetBool(_G, registryKey, not value)
    end
end

function UpdateInputForKey(registryKey)
    if GetString(_G, registryKey) == "?" then
        local lastPressedKey = InputLastPressedKey()
        if lastPressedKey ~= "" then
            SetString(_G, registryKey, lastPressedKey)
        end
    end
end