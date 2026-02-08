local rewardWindow
local rewardButton
local shineEvent
local OPCODE_REWARD = 201
local selectedReward = nil
local REWARDS = {}

local VOCATION_REWARDS = {
    [1] = {2, 1, 3},
    [11] = {2, 1, 3},
    [2] = 2389,
    [12] = 2389,
    [3] = 2190,
    [13] = 2190,
    [4] = 2182,
    [14] = 2182
}

local config = {
    animationInterval = 100,
    blinkDuration = 1000,
    spriteFrames = 13,
    spriteWidth = 108,
    gridMarginLeft = 15,
    itemSize = 68,
    itemSpacing = 5,
    gridTop = 65
}

function init()
    connect(g_game, {onGameStart = onGameStart})
    
    local parent = modules.game_interface and modules.game_interface.getMapPanel() or nil
    rewardWindow = g_ui.displayUI('reward', parent)
    if rewardWindow then
        rewardWindow:hide()
    end
    
    createRewardButton()
    ProtocolGame.registerExtendedOpcode(OPCODE_REWARD, onExtendedOpcode)
    
    if g_game.isOnline() then
        onGameStart()
    end
    
    g_keyboard.bindKeyDown('Ctrl+U', toggle)
end

function terminate()
    disconnect(g_game, {onGameStart = onGameStart})
    ProtocolGame.unregisterExtendedOpcode(OPCODE_REWARD)
    g_keyboard.unbindKeyDown('Ctrl+U')
    
    destroyRewardButton()
    destroyRewardWindow()
    stopBlinkAnimation()
end

function createRewardButton()
    if not modules.game_interface then return end
    
    local mapPanel = modules.game_interface.getMapPanel()
    if not mapPanel then return end
    
    rewardButton = g_ui.createWidget('RewardButton', mapPanel)
    if not rewardButton then return end
    
    rewardButton:raise()
    rewardButton:hide()
    
    local function updateLayout()
        if not rewardButton or not mapPanel then return end
        
        local panelSize = mapPanel:getSize()
        local panelRatio = panelSize.width / panelSize.height
        local mapRatio = 15 / 11
        
        local marginX = 10
        local marginY = 10
        
        if panelRatio > mapRatio then
            local drawWidth = panelSize.height * mapRatio
            local gap = (panelSize.width - drawWidth) / 2
            marginX = marginX + gap
        elseif panelRatio < mapRatio then
            local drawHeight = panelSize.width / mapRatio
            local gap = (panelSize.height - drawHeight) / 2
            marginY = marginY + gap
        end
        
        rewardButton:setMarginRight(marginX)
        rewardButton:setMarginBottom(marginY)
    end
    
    connect(mapPanel, {onGeometryChange = updateLayout})
    addEvent(updateLayout)
end

function destroyRewardButton()
    if rewardButton then
        rewardButton:destroy()
        rewardButton = nil
    end
end

function destroyRewardWindow()
    if rewardWindow then
        rewardWindow:destroy()
        rewardWindow = nil
    end
end

function onGameStart()
end

function onExtendedOpcode(protocol, opcode, buffer)
    if opcode ~= OPCODE_REWARD then return end
    
    if buffer:sub(1, 4) == "Show" then
        parseRewards(buffer:sub(6))
        populate()
        showRewardButton()
    elseif buffer == "Hide" then
        hideRewardButton()
        hide()
    end
end

function parseRewards(data)
    if not data or #data == 0 then return end
    
    REWARDS = {}
    for entry in data:gmatch("([^;]+)") do
        local serverId, clientId, name = entry:match("(%d+),(%d+),(.+)")
        if serverId and clientId and name then
            table.insert(REWARDS, {
                id = tonumber(serverId),
                clientId = tonumber(clientId),
                name = name
            })
        end
    end
end

function populate()
    if not rewardWindow then return end
    
    local contentPanel = rewardWindow:getChildById('rewardGrid')
    local recommendedLabel = rewardWindow:getChildById('recommendedLabel')
    
    if not contentPanel then return end
    
    if recommendedLabel then
        recommendedLabel:setVisible(false)
    end
    
    contentPanel:destroyChildren()
    
    local recommendedId = getRecommendedReward()
    
    for i, reward in ipairs(REWARDS) do
        local widget = g_ui.createWidget('RewardItemWidget', contentPanel)
        widget:setId('weaponSlot' .. i)
        
        local itemWidget = widget:getChildById('item')
        if itemWidget and reward.clientId then
            itemWidget:setItemId(reward.clientId)
        end
        
        if reward.name then
            widget:setTooltip(reward.name)
        end
        
        if reward.id == recommendedId and recommendedLabel then
            positionRecommendedLabel(recommendedLabel, i)
        end
        
        widget.onClick = function() selectItem(i) end
    end
end

function positionRecommendedLabel(label, index)
    local itemX = config.gridMarginLeft + ((index - 1) * (config.itemSize + config.itemSpacing))
    local itemCenterX = itemX + (config.itemSize / 2)
    local itemY = config.gridTop + config.itemSize + config.itemSpacing
    
    label:setText("Recommended")
    label:setVisible(true)
    
    local labelWidth = label:getTextSize().width
    label:setMarginLeft(itemCenterX - (labelWidth / 2))
    label:setMarginTop(itemY)
end

function getRecommendedReward()
    local player = g_game.getLocalPlayer()
    if not player then return 0 end
    
    local voc = player:getVocation()
    local vocReward = VOCATION_REWARDS[voc]
    
    if not vocReward then return 0 end
    
    if type(vocReward) == "number" then
        return vocReward
    end
    
    if type(vocReward) == "table" then
        local sword = player:getSkillLevel(vocReward[1])
        local club = player:getSkillLevel(vocReward[2])
        local axe = player:getSkillLevel(vocReward[3])
        
        local bestSkill = math.max(sword, club, axe)
        
        if bestSkill == club then return 2382 end
        if bestSkill == axe then return 2386 end
        return 2376
    end
    
    return 0
end

function selectItem(index)
    if not REWARDS[index] then return end
    
    selectedReward = REWARDS[index].id
    
    local contentPanel = rewardWindow:getChildById('rewardGrid')
    if not contentPanel then return end
    
    local children = contentPanel:getChildren()
    for i, child in ipairs(children) do
        local selectedOverlay = child:getChildById('selected')
        if selectedOverlay then
            selectedOverlay:setVisible(i == index)
        end
    end
end

function claim()
    if not selectedReward then return end
    
    local protocol = g_game.getProtocolGame()
    if protocol then
        protocol:sendExtendedOpcode(OPCODE_REWARD, tostring(selectedReward))
    end
end

function showRewardButton()
    if rewardButton then
        rewardButton:show()
        startBlinkAnimation()
    end
end

function hideRewardButton()
    if rewardButton then
        rewardButton:hide()
    end
    stopBlinkAnimation()
end

function startBlinkAnimation()
    if not rewardButton then return end
    
    stopBlinkAnimation()
    
    local highlight = rewardButton:getChildById('highlight')
    local animatedIcon = rewardButton:getChildById('animatedIcon')
    
    local startTime = g_clock.millis()
    local currentFrame = 0
    
    local function animate()
        if not rewardButton or not rewardButton:isVisible() then
            stopBlinkAnimation()
            return
        end
        
        local now = g_clock.millis()
        
        if highlight then
            local val = (math.sin((now - startTime) / config.blinkDuration * math.pi * 2) + 1.0) * 0.5
            highlight:setOpacity(val)
            highlight:setVisible(true)
        end
        
        if animatedIcon then
            currentFrame = (currentFrame + 1) % config.spriteFrames
            local clipX = currentFrame * config.spriteWidth
            animatedIcon:setImageClip(clipX .. " 0 " .. config.spriteWidth .. " " .. config.spriteWidth)
        end
        
        shineEvent = scheduleEvent(animate, config.animationInterval)
    end
    
    animate()
end

function stopBlinkAnimation()
    if shineEvent then
        removeEvent(shineEvent)
        shineEvent = nil
    end
end

function show()
    if not rewardWindow then return end
    
    rewardWindow:show()
    rewardWindow:raise()
    rewardWindow:focus()
end

function hide()
    if rewardWindow then
        rewardWindow:hide()
    end
end

function toggle()
    if not rewardWindow then return end
    
    if rewardWindow:isVisible() then
        hide()
    else
        show()
    end
end
