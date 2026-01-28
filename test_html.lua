-- Test HTML system
local function testHtmlSystem()
    print("Testing HTML system...")
    
    -- Try to load the HTML file
    local htmlWidget = g_ui.loadHtml('modules/game_shaders/shaders.html', g_ui.getRootWidget())
    
    if htmlWidget then
        print("HTML widget created successfully!")
        print("Widget ID:", htmlWidget:getId())
        print("Is HTML widget:", htmlWidget:getLuaField("isHtmlWidget"))
        print("HTML file:", htmlWidget:getLuaField("htmlFile"))
        
        -- Try to find the comboboxes
        local mapComboBox = htmlWidget:getChildById('mapComboBox')
        local outfitComboBox = htmlWidget:getChildById('outfitComboBox')
        local mountComboBox = htmlWidget:getChildById('mountComboBox')
        
        if mapComboBox then
            print("Map ComboBox found!")
        else
            print("Map ComboBox NOT found")
        end
        
        if outfitComboBox then
            print("Outfit ComboBox found!")
        else
            print("Outfit ComboBox NOT found")
        end
        
        if mountComboBox then
            print("Mount ComboBox found!")
        else
            print("Mount ComboBox NOT found")
        end
        
        -- Clean up
        htmlWidget:destroy()
    else
        print("Failed to create HTML widget")
    end
end

-- Run test
testHtmlSystem()