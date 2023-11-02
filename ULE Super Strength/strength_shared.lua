-- make sure all our required registry keys are defined.
function InitializePersistentData(reset)
    _defaultStaticGrabStateKey = "savegame.mod.defaultstaticgrabstate"
    _enableStaticGrabTogglingKey = "savegame.mod.enablestaticgrabtoggling"
    
    -- keybinds
    _staticGrabToggleButtonKey = "savegame.mod.staticgrabtogglebutton"
    _toggleSuperStrengthButtonKey = "savegame.mod.togglesuperstrengthbutton"
    
    ULE_InitializePersistentRegistryKey(_G, _defaultStaticGrabStateKey, true, reset)
    ULE_InitializePersistentRegistryKey(_G, _enableStaticGrabTogglingKey, true, reset)
    ULE_InitializePersistentRegistryKey(_G, _staticGrabToggleButtonKey, "C", reset)
    ULE_InitializePersistentRegistryKey(_G, _toggleSuperStrengthButtonKey, "X", reset)
end

