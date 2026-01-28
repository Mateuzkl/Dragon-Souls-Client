-- Event Controller for HTML system
-- Manages event handling and binding for HTML widgets

EventController = {}
EventController.__index = EventController

function EventController:new()
    local instance = {
        events = {},
        cycleEvents = {},
        widgets = {}
    }
    return setmetatable(instance, EventController)
end

function EventController:registerEvents(widget, events)
    if not self.widgets[widget] then
        self.widgets[widget] = {}
    end
    
    for eventName, handler in pairs(events) do
        self.widgets[widget][eventName] = handler
        widget[eventName] = handler
    end
end

function EventController:cycleEvent(callback, interval)
    table.insert(self.cycleEvents, {
        callback = callback,
        interval = interval or 100,
        lastCall = g_clock.millis()
    })
end

function EventController:update()
    local currentTime = g_clock.millis()
    
    for _, cycleEvent in pairs(self.cycleEvents) do
        if currentTime - cycleEvent.lastCall >= cycleEvent.interval then
            cycleEvent.callback()
            cycleEvent.lastCall = currentTime
        end
    end
end

function EventController:destroy()
    for widget, events in pairs(self.widgets) do
        for eventName, _ in pairs(events) do
            widget[eventName] = nil
        end
    end
    
    self.widgets = {}
    self.events = {}
    self.cycleEvents = {}
end

-- Global instance
g_eventController = EventController:new()

-- Update cycle
if not g_eventControllerEvent then
    g_eventControllerEvent = cycleEvent(function()
        g_eventController:update()
    end, 50)
end