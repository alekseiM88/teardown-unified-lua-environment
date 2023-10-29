-- make sure all our required registry keys are defined.
function InitializePersistentData()
    _defaultStaticGrabStateKey = "savegame.mod.defaultstaticgrabstate"
    _enableStaticGrabTogglingKey = "savegame.mod.enablestaticgrabtoggling"
    _staticGrabToggleButtonKey = "savegame.mod.staticgrabtogglebutton"
    
    -- _G should be passed in order for the paths to be properly detoured.
    if not HasKey(_G, _defaultStaticGrabStateKey) then
        SetBool(_G, _defaultStaticGrabStateKey, true)
    end
    
    if not HasKey(_G, _enableStaticGrabTogglingKey) then
        SetBool(_G, _enableStaticGrabTogglingKey, true)
    end

    if not HasKey(_G, _staticGrabToggleButtonKey) or GetString(_G, _staticGrabToggleButtonKey) == "?" then
        SetString(_G, _staticGrabToggleButtonKey, "C")
    end
end

