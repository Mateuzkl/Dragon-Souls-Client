-- Advanced HTML Test Controller
-- Demonstrates the full power of the HTML/CSS system

AdvancedController = {}
AdvancedController.__index = AdvancedController
setmetatable(AdvancedController, { __index = Controller })

function AdvancedController:new()
    local instance = Controller:new()
    setmetatable(instance, AdvancedController)
    
    -- Controller state
    instance.username = ""
    instance.password = ""
    instance.selectedServer = "server1"
    instance.rememberMe = false
    instance.status = "Ready"
    
    return instance
end

function AdvancedController:init()
    print("[AdvancedController] Initializing advanced HTML test...")
    
    -- Load the advanced HTML interface
    self:loadHtml('modules/game_htmltest/advanced_test.html', modules.game_interface.getMapPanel())
    
    if self.ui then
        print("[AdvancedController] ✅ Advanced HTML interface loaded!")
        
        -- Position the interface
        self.ui.widget:setMarginTop(50)
        self.ui.widget:setMarginLeft(100)
        self.ui.widget:show()
        self.ui.widget:raise()
        
        -- Bind keyboard shortcut
        g_keyboard.bindKeyDown('Ctrl+H', function()
            self:toggle()
        end)
        
        print("[AdvancedController] Press Ctrl+H to toggle the advanced interface")
    else
        print("[AdvancedController] ❌ Failed to load advanced HTML interface!")
    end
end

-- Event handlers for HTML elements
function AdvancedController:onUsernameChange(event)
    self.username = event.value or event.text or ""
    print("[AdvancedController] Username changed to:", self.username)
    self:updateStatus("Username: " .. self.username)
end

function AdvancedController:onPasswordChange(event)
    self.password = event.value or event.text or ""
    print("[AdvancedController] Password changed (length: " .. #self.password .. ")")
    self:updateStatus("Password entered")
end

function AdvancedController:onServerChange(event)
    self.selectedServer = event.value or event.text or "server1"
    print("[AdvancedController] Server changed to:", self.selectedServer)
    
    local serverNames = {
        server1 = "Main Server",
        server2 = "Test Server", 
        server3 = "Development Server"
    }
    
    self:updateStatus("Server: " .. (serverNames[self.selectedServer] or self.selectedServer))
end

function AdvancedController:onRememberChange(event)
    self.rememberMe = event.checked or false
    print("[AdvancedController] Remember me:", self.rememberMe)
    self:updateStatus("Remember: " .. (self.rememberMe and "Yes" or "No"))
end

function AdvancedController:onLoginClick(event)
    print("[AdvancedController] Login clicked!")
    print("  Username:", self.username)
    print("  Password: [" .. string.rep("*", #self.password) .. "]")
    print("  Server:", self.selectedServer)
    print("  Remember:", self.rememberMe)
    
    if self.username == "" then
        self:updateStatus("❌ Please enter username")
        return
    end
    
    if self.password == "" then
        self:updateStatus("❌ Please enter password")
        return
    end
    
    self:updateStatus("🔄 Connecting to " .. self.selectedServer .. "...")
    
    -- Simulate login process
    scheduleEvent(function()
        self:updateStatus("✅ Connected successfully!")
    end, 2000)
end

function AdvancedController:onCancelClick(event)
    print("[AdvancedController] Cancel clicked!")
    self:updateStatus("❌ Login cancelled")
    self:hide()
end

function AdvancedController:updateStatus(message)
    self.status = message
    
    -- Find and update status element
    local statusElement = self:getElementById('status')
    if statusElement then
        statusElement:setVisible(true)
        local statusLabel = statusElement:getChildByIndex(1)
        if statusLabel then
            statusLabel:setText("Status: " .. message)
        end
    end
    
    print("[AdvancedController] Status:", message)
end

function AdvancedController:terminate()
    print("[AdvancedController] Terminating...")
    
    -- Unbind keyboard shortcut
    g_keyboard.unbindKeyDown('Ctrl+H')
    
    -- Destroy controller
    self:destroy()
end

-- Global instance
advancedController = AdvancedController:new()