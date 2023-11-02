-- most of this is copied from ule super strength's options menu, just for the record.
ULE_IncludeLua(_G, "ule3d_shared.lua")

function init()
    InitializePersistentData()
end

function draw()
    ULE_ui.PushOptionsDraw()
        ULE_ui.DrawToggleButton(_G, "The ULE3D example tool is:", _enableULE3DExampleToolKey)
    ULE_ui.PopOptionsDraw()
    
    
    ULE_ui.DrawBackButton(_G)
end
