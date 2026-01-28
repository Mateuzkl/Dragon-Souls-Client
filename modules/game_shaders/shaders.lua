local shaderUI

MAP_SHADERS = {
  {name = 'Default', frag = 'shaders/fragment/default.frag'},
  {name = 'Rainbow', frag = 'shaders/fragment/rainbow.frag'}
}

OUTFIT_SHADERS = {
  {name = 'Default', frag = 'shaders/fragment/default.frag'},
  {name = 'Rainbow', frag = 'shaders/fragment/rainbow.frag'}
}

MOUNT_SHADERS = {
  {name = 'Default', frag = 'shaders/fragment/default.frag'},
  {name = 'Rainbow', frag = 'shaders/fragment/rainbow.frag'}
}

local function attachShaders()
  local map = modules.game_interface.getMapPanel()
  map:setShader('Default')
end

function onMapComboBoxChange(widget, text, data)
  local map = modules.game_interface.getMapPanel()
  map:setShader(text)

  local option = widget:getCurrentOption()
  if option and option.data then
     map:setDrawViewportEdge(option.data.drawViewportEdge == true)
  end
end

function onOutfitComboBoxChange(widget, text, data)
  local player = g_game.getLocalPlayer()
  if player then
    player:setShader(text)
    local option = widget:getCurrentOption()
    if option and option.data then
        player:setDrawOutfitColor(option.data.drawColor ~= false)
    end
  end
end

function onMountComboBoxChange(widget, text, data)
  local player = g_game.getLocalPlayer()
  if player then
    player:setMountShader(text)
  end
end

function init()
  -- add manually your shaders from /data/shaders

  -- map shaders
  g_shaders.createShader("map_default", "/shaders/map_default_vertex", "/shaders/map_default_fragment")  

  g_shaders.createShader("map_rainbow", "/shaders/map_rainbow_vertex", "/shaders/map_rainbow_fragment")
  g_shaders.addTexture("map_rainbow", "/images/shaders/rainbow.png")
  
  g_shaders.createShader("map_snow", "/shaders/map_snow_vertex", "/shaders/map_snow_fragment")
  g_shaders.addTexture("map_snow", "/images/shaders/snow.png")

  -- use modules.game_interface.gameMapPanel:setShader("map_rainbow") to set shader

  -- outfit shaders
  g_shaders.createOutfitShader("outfit_default", "/shaders/outfit_default_vertex", "/shaders/outfit_default_fragment")

  g_shaders.createOutfitShader("outfit_rainbow", "/shaders/outfit_rainbow_vertex", "/shaders/outfit_rainbow_fragment")
  g_shaders.addTexture("outfit_rainbow", "/images/shaders/rainbow.png")

  -- you can use creature:setOutfitShader("outfit_rainbow") to set shader

  connect(g_game, { onGameStart = attachShaders })

  g_keyboard.bindKeyDown('Ctrl+Shift+S', function()
    if shaderUI then
      shaderUI:setVisible(not shaderUI:isVisible())
    end
  end)

  -- Load OTUI
  shaderUI = g_ui.loadUI('shaders.otui', modules.game_interface.getMapPanel())
  
  if shaderUI then
    print("[Shader] UI loaded successfully!")
    shaderUI:setVisible(true)  -- Make visible by default for testing
    shaderUI:show()
    shaderUI:raise()

    -- Add options to comboboxes
    local mapComboBox = shaderUI:recursiveGetChildById('mapComboBox')
    local outfitComboBox = shaderUI:recursiveGetChildById('outfitComboBox')
    local mountComboBox = shaderUI:recursiveGetChildById('mountComboBox')

    if mapComboBox then
      print("[Shader] Found mapComboBox, adding options...")
      for _, opts in pairs(MAP_SHADERS) do
        mapComboBox:addOption(opts.name, opts)
        print("[Shader] Added option:", opts.name)
      end
      mapComboBox.onOptionChange = onMapComboBoxChange
    else
      print("[Shader] ERROR: mapComboBox not found!")
    end

    if outfitComboBox then
      print("[Shader] Found outfitComboBox, adding options...")
      for _, opts in pairs(OUTFIT_SHADERS) do
        outfitComboBox:addOption(opts.name, opts)
        print("[Shader] Added option:", opts.name)
      end
      outfitComboBox.onOptionChange = onOutfitComboBoxChange
    else
      print("[Shader] ERROR: outfitComboBox not found!")
    end

    if mountComboBox then
      print("[Shader] Found mountComboBox, adding options...")
      for _, opts in pairs(MOUNT_SHADERS) do
        mountComboBox:addOption(opts.name, opts)
        print("[Shader] Added option:", opts.name)
      end
      mountComboBox.onOptionChange = onMountComboBoxChange
    else
      print("[Shader] ERROR: mountComboBox not found!")
    end
    
    print("[Shader] All setup complete! Press Ctrl+Shift+S to toggle visibility")
  else
    print("[Shader] ERROR: Failed to load UI!")
  end
end

function terminate()
  if shaderUI then
    shaderUI:destroy()
    shaderUI = nil
  end
end


