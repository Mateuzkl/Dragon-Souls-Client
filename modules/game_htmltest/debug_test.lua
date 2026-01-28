function init()
    print("[HTML Test] Debug module loaded")
end

function terminate()
    print("[HTML Test] Debug module terminated")
end
-- Debug test for HTML system
print("=== HTML DEBUG TEST ===")

function testBasicHTML()
    print("1. Testing if g_ui.loadHtml exists...")
    if g_ui.loadHtml then
        print("✓ g_ui.loadHtml function exists")
    else
        print("✗ g_ui.loadHtml function NOT found!")
        return
    end
    
    print("4. Testing HTML loading with visibility...")
    local htmlWidget = g_ui.loadHtml('modules/game_htmltest/visible_test.html', g_ui.getRootWidget())
    
    if htmlWidget then
        print("✓ HTML widget created successfully!")
        print("  - Widget ID:", htmlWidget:getId())
        print("  - Widget class:", htmlWidget:getClassName())
        
        -- Force visibility and positioning
        htmlWidget:show()
        htmlWidget:raise()
        htmlWidget:focus()
        htmlWidget:setVisible(true)
        
        print("  - Widget visible after show():", htmlWidget:isVisible())
        print("  - Widget size:", htmlWidget:getWidth(), "x", htmlWidget:getHeight())
        print("  - Widget position:", htmlWidget:getX(), ",", htmlWidget:getY())
        
        -- Try to find child elements
        local testPanel = htmlWidget:getChildById('testPanel')
        if testPanel then
            print("  - Found testPanel child")
            testPanel:show()
            testPanel:setVisible(true)
            print("  - testPanel size:", testPanel:getWidth(), "x", testPanel:getHeight())
            
            -- Check for labels
            local children = testPanel:getChildren()
            print("  - testPanel has", #children, "children")
            
            for i, child in ipairs(children) do
                print("    - Child", i, ":", child:getClassName(), "visible:", child:isVisible())
                child:show()
                child:setVisible(true)
                if child:getClassName() == "UILabel" then
                    print("      - Label text:", child:getText())
                end
            end
        else
            print("  - testPanel child NOT found")
        end
        
        print("✓ HTML widget should now be visible!")
        print("✓ Look for a white bordered box with HTML text!")
        
    else
        print("✗ HTML widget creation FAILED!")
    end
    
    print("=== HTML DEBUG TEST COMPLETE ===")
end

-- Run the test
scheduleEvent(testBasicHTML, 1000)

-- Manual test command
function manualHTMLTest()
    print("=== MANUAL HTML TEST ===")
    
    local htmlWidget = g_ui.loadHtml('modules/game_htmltest/visible_test.html', g_ui.getRootWidget())
    
    if htmlWidget then
        print("HTML widget created! Making it super visible...")
        
        -- Force maximum visibility
        htmlWidget:show()
        htmlWidget:raise()
        htmlWidget:focus()
        htmlWidget:setVisible(true)
        htmlWidget:setOpacity(1.0)
        
        -- Set bright background to make it obvious
        htmlWidget:setBackgroundColor("#FF0000")  -- Red background
        htmlWidget:setBorderWidth(5)
        htmlWidget:setBorderColor("#FFFF00")      -- Yellow border
        
        print("Red box with yellow border should be visible!")
        print("Position:", htmlWidget:getX(), ",", htmlWidget:getY())
        print("Size:", htmlWidget:getWidth(), "x", htmlWidget:getHeight())
        
        -- Store globally so we can access it
        _G.testHTMLWidget = htmlWidget
        
        return htmlWidget
    else
        print("Failed to create HTML widget!")
        return nil
    end
end

-- Bind Ctrl+U to manual test
g_keyboard.bindKeyDown('Ctrl+U', function()
    print("Ctrl+U pressed - Running manual HTML test...")
    manualHTMLTest()
end)