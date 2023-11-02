ULE_IncludeLua(_G, "strength_shared.lua")

function init()
    InitializePersistentData()
    resetCallback = function() InitializePersistentData(true) end
end

function tick()
    -- input
    ULE_ui.UpdateCharInputForKey(_G, _staticGrabToggleButtonKey)
    ULE_ui.UpdateCharInputForKey(_G, _toggleSuperStrengthButtonKey)
end

function draw()
    ULE_ui.PushOptionsDraw()
        ULE_ui.DrawCharInputButton(_G, "The super strength toggle key is:", _toggleSuperStrengthButtonKey)
        
        ULE_ui.DrawToggleButton(_G, "Static body grabbing defaults to being:", _defaultStaticGrabStateKey)
        
        ULE_ui.DrawToggleButton(_G, "Toggling static body grabbing is:", _enableStaticGrabTogglingKey)
        
        if GetBool(_G, _enableStaticGrabTogglingKey) then
            ULE_ui.DrawCharInputButton(_G, "The static body grabbing toggle key is:", _staticGrabToggleButtonKey)
        end
        
        ULE_ui.MoveDown()
        
        ULE_ui.DrawTextButton(resetCallback, "Reset to Defaults", 350)
    ULE_ui.PopOptionsDraw()
    
    
    ULE_ui.DrawBackButton(_G)
end