-- Base Controller class for HTML modules
-- Provides structure and common functionality for HTML-based modules

Controller = {}
Controller.__index = Controller

function Controller:new()
    local instance = {
        ui = nil,
        events = {},
        eventController = EventController:new()
    }
    return setmetatable(instance, Controller)
end

function Controller:loadHtml(htmlFile, parent)
    self.ui = HtmlLoader(htmlFile, parent, self)
    return self.ui
end

function Controller:registerEvents(widget, events)
    self.eventController:registerEvents(widget, events)
end

function Controller:cycleEvent(callback, interval)
    self.eventController:cycleEvent(callback, interval)
end

function Controller:destroy()
    if self.ui then
        self.ui:destroy()
        self.ui = nil
    end
    
    if self.eventController then
        self.eventController:destroy()
        self.eventController = nil
    end
end

-- Utility functions for controllers
function Controller:getElementById(id)
    if self.ui and self.ui.widget then
        return self.ui.widget:recursiveGetChildById(id)
    end
    return nil
end

function Controller:getElementsByClass(className)
    -- This would require more advanced DOM traversal
    -- For now, return empty table
    return {}
end

function Controller:show()
    if self.ui and self.ui.widget then
        self.ui.widget:show()
        self.ui.widget:raise()
    end
end

function Controller:hide()
    if self.ui and self.ui.widget then
        self.ui.widget:hide()
    end
end

function Controller:toggle()
    if self.ui and self.ui.widget then
        if self.ui.widget:isVisible() then
            self:hide()
        else
            self:show()
        end
    end
end