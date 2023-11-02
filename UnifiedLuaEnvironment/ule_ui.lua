-- UI helpers for the ULE, feel free to access these for your options menus and what not
ULE_ui = {}

ULE_ui.LINEMARGIN = 56
ULE_ui.TEXTSIZE = 48
ULE_ui.BUTTONWIDTH = 180

function ULE_ui.DrawToggleButton(context, label, registryKey)
    UiPush()
        UiFont("bold.ttf", ULE_ui.TEXTSIZE)
        UiButtonImageBox("ui/common/box-outline-fill-6.png", 6, 6)
        
        UiAlign("right")
        UiText(label)
        
        UiAlign("middle left")
        UiTranslate(10, -ULE_ui.TEXTSIZE/4)
        
        local value = GetBool(context, registryKey)
        if UiTextButton(value and "Enabled" or "Disabled", ULE_ui.BUTTONWIDTH, ULE_ui.TEXTSIZE) then
            SetBool(context, registryKey, not value)
        end
    UiPop()
    ULE_ui.MoveDown()
end

function ULE_ui.DrawCharInputButton(context, label, registryKey)
    UiPush()
        UiFont("bold.ttf", ULE_ui.TEXTSIZE)
        UiButtonImageBox("ui/common/box-outline-fill-6.png", 6, 6)
        
        UiAlign("right")
        UiText(label)
        
        UiAlign("middle left")
        UiTranslate(10, -ULE_ui.TEXTSIZE/4)
        
        if UiTextButton(GetString(context, registryKey), ULE_ui.BUTTONWIDTH, ULE_ui.TEXTSIZE) then
            SetString(context, registryKey, "?")
        end
    UiPop()
    ULE_ui.MoveDown()
end

function ULE_ui.DrawTextButton(callback, label, width, height)
    UiPush()
        width = width or 256
        height = height or 64
        
        UiFont("bold.ttf", ULE_ui.TEXTSIZE)
        UiButtonImageBox("ui/common/box-outline-fill-6.png", 6, 6)

        UiAlign("middle center")
        
        if UiTextButton(label, width, height) then
            callback()
        end
    UiPop()
    ULE_ui.MoveDown()
end

function ULE_ui.UpdateCharInputForKey(context, registryKey)
    if GetString(context, registryKey) == "?" then
        local lastPressedKey = InputLastPressedKey()
        if lastPressedKey ~= "" and lastPressedKey ~= "esc" then
            SetString(context, registryKey, lastPressedKey)
        end
    end
end

function ULE_ui.DrawBackButton(context)
    -- back button
    UiPush()
        UiFont("bold.ttf", ULE_ui.TEXTSIZE)
        UiButtonImageBox("ui/common/box-outline-fill-6.png", 6, 6)
    
        UiAlign("top center")
        UiTranslate(UiCenter(), UiMiddle()+200)
        
        if UiTextButton("Back",128, 64) then
            context.Menu()
        end
    UiPop()
end

function ULE_ui.PushOptionsDraw()
    UiPush()
    UiTranslate(UiCenter(), UiMiddle()-200)
end

function ULE_ui.PopOptionsDraw()
    UiPop()
end

-- translate down by LINEMARGIN
function ULE_ui.MoveDown()
    UiTranslate(0, ULE_ui.LINEMARGIN)
end