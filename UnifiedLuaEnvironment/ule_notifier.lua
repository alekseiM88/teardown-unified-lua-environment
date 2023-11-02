-- messenger/notification system to show message to the user. Can be used by all ULE-based mods.
ULE_notifier = {}

ULE_notifier.messages = {}

-- str notification, number duration (in seconds), table color
function ULE_notifier.AddNotification(notification, length, col)
    length = length or 1.25
    col = col or {1,1,1,1}
    col[4] = col[4] or 1
    
    ULE_notifier.messages[#ULE_notifier.messages+1] = {text=notification, duration=length, timer=0, color=col}
end
-- draw and update the notifier
function ULE_notifier.Update(dt)

    if #ULE_notifier.messages < 1 then return end

    UiPush()
        UiFont("bold.ttf",48)
        UiAlign("top left")
        UiTranslate(24, 100)
        
        for _, message in ipairs(ULE_notifier.messages) do
            message.timer = message.timer + dt
        
            local opacity = (message.duration-message.timer)/(message.duration*0.125)
    
            UiColor(message.color[1], message.color[2], message.color[3], message.color[4] * opacity)
            
            UiTextOutline(0,0,0,opacity,0.4)
            
            UiText(message.text, true)
        end
    UiPop()

    -- clean messages
    local tempMessages = {}
    for _, message in ipairs(ULE_notifier.messages) do
        if message.timer <= message.duration then
            tempMessages[#tempMessages+1] = message
        end
    end
    
    ULE_notifier.messages = tempMessages
end
