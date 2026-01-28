-- Simple HTML test
print("Testing simple HTML loading...")

local widget = g_ui.loadHtml('test_simple.html', g_ui.getRootWidget())

if widget then
    print("SUCCESS: HTML widget created!")
    print("Widget ID:", widget:getId())
    
    -- Try to find the container
    local container = widget:getChildById('container')
    if container then
        print("SUCCESS: Container found!")
        print("Container size:", container:getWidth(), "x", container:getHeight())
    else
        print("ERROR: Container not found")
    end
    
    -- Clean up
    widget:destroy()
else
    print("ERROR: Failed to create HTML widget")
end

print("Test completed.")