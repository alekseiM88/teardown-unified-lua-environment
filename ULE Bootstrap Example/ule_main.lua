
function init()
    -- The filenames supplied should not have any non-alphanumeric characters, as the they will be used to create their savegame registry keys
    ULE_InitModListAndDestroySource(_G, 
    {
        ["Bootstrap Example #1"] = "exampleone.lua",
        ["Bootstrap Example #2"] = "exampletwo.lua",
        ["Bootstrap Example #3"] = "examplethree.lua"
    })
end

function tick()
    DebugPrint("This string won't print since this mod will be destroyed before it has the chance to have its tick function run.")
end