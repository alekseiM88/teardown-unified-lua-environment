#include "ule_optionsmenu.lua"

function init()
    ULE_SetupUi()
    ULE_SetupOptionsMenu()
    
    ULE_optionsMenu.Init()
end

function tick(dt)
    ULE_UpdateLerpValues(dt)
    
    ULE_optionsMenu.Tick(dt)
end

function update(dt)
    ULE_optionsMenu.Update(dt)
end

function draw(dt)
    ULE_optionsMenu.Draw(dt)
end