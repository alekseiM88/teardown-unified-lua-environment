-- make sure all our required registry keys are defined.
function InitializePersistentData()
    _enableULE3DExampleToolKey = "savegame.mod.enableule3dexampletool"
    
    -- _G should be passed in order for the paths to be properly detoured.
    ULE_InitializePersistentRegistryKey(_G, _enableULE3DExampleToolKey, true)
end

