-- ule3d bootstrapper
ULE_IncludeLua(_G, "ule3d_shared.lua")

paths = { ["ule3d"] = "ule3d_main.lua" }

function init()
    InitializePersistentData()

    if GetBool(_G, _enableULE3DExampleToolKey) then
        paths["ule3d_exampletool"] = "ule3d_exampletool.lua"
    end
    
    ULE_InitModList(_G, paths)
end

function ULE_OnDestroy()
    -- Destroy our bootsrapped mods when we're destroyed.
    for name, path in pairs(paths) do
        ULE_DestroyMod(name)
    end
end