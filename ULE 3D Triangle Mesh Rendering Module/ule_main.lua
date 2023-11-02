-- ule3d bootstrapper
ULE_IncludeLua(_G, "ule3d_shared.lua")

function init()
    InitializePersistentData()

    local paths = { ["ule3d"] = "ule3d_main.lua" }

    if GetBool(_G, _enableULE3DExampleToolKey) then
        paths["ule3d_exampletool"] = "ule3d_exampletool.lua"
    end
    
    ULE_InitModListAndDestroySource(_G, paths)
end