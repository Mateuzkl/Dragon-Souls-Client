m_HelperList = {}
m_HelperFunction = {}

m_HelperFunction.delay = 500
m_HelperFunction.GameServerSendTools = 134
m_HelperFunction.TYPE = {
	BLANK = 0,
	SPELL = 1,
	ITEM = 2
}

m_HelperFunction.spellList = {
	["autoHasteSlot"] = {"Haste", "Strong Haste"},
	["manaTrainingSlot"] = {},
	["spellHealingSlot1"] = {"Light Healing", "Wound Cleansing", "Intense Wound Cleansing", "Salvation", "Intense Healing", "Heal Friend", "Ultimate Healing", "Mass Healing", "Divine Healing", "Fair Wound Cleansing", "Restoration", "Nature's Embrace"},
	["spellHealingSlot2"] = {"Light Healing", "Wound Cleansing", "Intense Wound Cleansing", "Salvation", "Intense Healing", "Heal Friend", "Ultimate Healing", "Mass Healing", "Divine Healing", "Fair Wound Cleansing", "Restoration", "Nature's Embrace"}
}

m_HelperFunction.exerciseWeapons = {28552, 28553, 28554, 28555, 28556, 28557, 45568, 44756, 45572, 45570, 47039, 35279, 35280, 35281, 35282, 35283, 35284, 45569, 44757, 45573, 45571, 47040, 35285, 35286, 35287, 35288, 35289, 35290, 45605, 45602, 45604, 45603, 47041}
m_HelperFunction.healthPotions = {266, 236, 239, 7643}
m_HelperFunction.spellsExhaust = {}
m_HelperFunction.defaultHeight = 280
m_HelperFunction.UHClientId = 3160
m_HelperFunction.heightByVocation = {
	[0] = 380, -- None
	[1] = 244, -- Knight
	[2] = 284, -- Paladin
	[3] = 244, -- Sorcerer
	[4] = 244 -- Druid
}

function onLoad()
	connect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd,
		onAddVip = m_HelperFunction.onAddVip,
		onVipStateChange = m_HelperFunction.onVipStateChange
	})

	connect(LocalPlayer, {
		onHealthChange = m_HelperFunction.onHealthChange
	})

	m_HelperFunction.button = modules.client_topmenu.addRightGameButton("helperButton", tr("Helper"), "/images/topbuttons/energy", m_HelperFunction.toggle, false, 7)

	m_HelperList.radio = UIRadioGroup.create()
	m_HelperList.window = g_ui.displayUI("game_helper")
	m_HelperList.toolsButton = m_HelperList.window:getChildById("toolsButton")
	m_HelperList.healingButton = m_HelperList.window:getChildById("healingButton")

	-- Tools panel
	m_HelperList.toolsPanel = m_HelperList.window:getChildById("toolsPanel")
	m_HelperList.autoEatFoodCheckBox = m_HelperList.toolsPanel:getChildById("autoEatFoodCheckBox") -- todo
	m_HelperList.autoReconnectCheckBox = m_HelperList.toolsPanel:getChildById("autoReconnectCheckBox") -- todo

	-- Auto haste
	m_HelperList.enableAutoHasteCheckBox = m_HelperList.toolsPanel:getChildById("enableAutoHasteCheckBox")
	m_HelperList.pzCastCheckBox = m_HelperList.toolsPanel:getChildById("pzCastCheckBox")
	m_HelperList.autoHasteSlot = m_HelperList.toolsPanel:getChildById("autoHasteSlot")
	m_HelperList.autoHasteSlot.type = m_HelperFunction.TYPE.BLANK

	-- Mana training
	m_HelperList.enableManaTrainingCheckBox = m_HelperList.toolsPanel:getChildById("enableManaTrainingCheckBox")
	m_HelperList.manaTrainingComboBox = m_HelperList.toolsPanel:getChildById("manaTrainingComboBox")
	m_HelperList.manaTrainingSlot = m_HelperList.toolsPanel:getChildById("manaTrainingSlot")
	m_HelperList.manaTrainingSlot.type = m_HelperFunction.TYPE.BLANK
	
	-- Exercise weapon training
	m_HelperList.enableExerciseTrainingCheckBox = m_HelperList.toolsPanel:getChildById("enableExerciseTrainingCheckBox")
	m_HelperList.exerciseTrainingComboBox = m_HelperList.toolsPanel:getChildById("exerciseTrainingComboBox")
	m_HelperList.exerciseTrainingSlot = m_HelperList.toolsPanel:getChildById("exerciseTrainingSlot")
	m_HelperList.exerciseTrainingSlot.type = m_HelperFunction.TYPE.BLANK

	-- Friend panel
	m_HelperList.friendHealingPanel = m_HelperList.window:getChildById("friendHealingPanel")
	m_HelperList.friendHealingFriends = m_HelperList.friendHealingPanel:getChildById("friends")
	m_HelperList.friendHealingSlots = {
		m_HelperList.friendHealingPanel:getChildById("friendHealing1"),
		m_HelperList.friendHealingPanel:getChildById("friendHealing2")
	}

	m_HelperFunction.updateHealingSlot(m_HelperList.friendHealingSlots)
	m_HelperList.friendHealingSlots[1].slot.item:setOn(true)
	m_HelperList.friendHealingSlots[1].slot.itemId = m_HelperFunction.UHClientId
	m_HelperList.friendHealingSlots[1].slot.type = m_HelperFunction.TYPE.ITEM

	local spellData = modules.gamelib.SpellInfo["Default"]["Heal Friend"]
	m_HelperList.friendHealingSlots[2].slot.text:setImageSource(SpelllistSettings['Default'].iconFile)
	m_HelperList.friendHealingSlots[2].slot.text:setImageClip(Spells.getImageClip(SpellIcons[spellData.icon][1], 'Default'))
	m_HelperList.friendHealingSlots[2].slot.words = spellData.words
	m_HelperList.friendHealingSlots[2].slot.spellName = spellData.spellName
	m_HelperList.friendHealingSlots[2].slot.type = m_HelperFunction.TYPE.SPELL

	for i = 0, 10 do
		m_HelperList.manaTrainingComboBox:addOption(math.max(1, (i * 10)) .. "%")
		m_HelperList.exerciseTrainingComboBox:addOption(i)
	end

	-- Healing panel
	m_HelperList.healingPanel = m_HelperList.window:getChildById("healingPanel")
	m_HelperList.spellHealingSlot = {
		m_HelperList.healingPanel:getChildById("spellHealingSlot1"),
		m_HelperList.healingPanel:getChildById("spellHealingSlot2")
	}

	m_HelperFunction.updateHealingSlot(m_HelperList.spellHealingSlot)
	m_HelperList.potionHealingSlot = {
		m_HelperList.healingPanel:getChildById("potionHealingSlot1"),
		m_HelperList.healingPanel:getChildById("potionHealingSlot2"),
		m_HelperList.healingPanel:getChildById("potionHealingSlot3")
	}

	m_HelperFunction.updateHealingSlot(m_HelperList.potionHealingSlot)
	m_HelperFunction.button:setOn(false)
	m_HelperList.window:hide()
	onGameStart()
end

function onUnLoad()
	disconnect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd,
		onAddVip = m_HelperFunction.onAddVip,
		onVipStateChange = m_HelperFunction.onVipStateChange
	})

	disconnect(LocalPlayer, {
		onHealthChange = m_HelperFunction.onHealthChange
	})

	onGameEnd()
	if m_HelperFunction.button then
		m_HelperFunction.button:destroy()
		m_HelperFunction.button = nil
	end
end

function onGameStart()
	m_HelperFunction.destroy()
	m_HelperList.friendHealingFriends:destroyChildren()
	if not m_HelperList.event then
		m_HelperList.event = cycleEvent(m_HelperFunction.timerEvent, m_HelperFunction.delay)
	end
end

function onGameEnd()
	m_HelperFunction.destroy()
	m_HelperFunction.stopEvent()
end

m_HelperFunction.updateHealingSlot = function(list)
	for _, panel in pairs(list) do
		panel.slot.type = m_HelperFunction.TYPE.BLANK
		for i = 0, 10 do
			panel.comboBox:addOption(math.max(1, (i * 10)) .. "%")
		end
	end
end

m_HelperFunction.stopEvent = function()
	if m_HelperList.event then
		m_HelperList.event:cancel()
		m_HelperList.event = nil
	end
end

m_HelperFunction.destroy = function()
	m_HelperFunction.destroySpellWindow()
	if m_HelperList.window then
		m_HelperList.window:hide()
		m_HelperFunction.button:setOn(false)
	end
end

m_HelperFunction.toggle = function()
	if m_HelperList.window:isVisible() then
		m_HelperFunction.destroy()
	else
		m_HelperList.window:show()
		m_HelperFunction.button:setOn(true)
		m_HelperList.friendHealingSlots[1].slot.item:setItemId(m_HelperFunction.UHClientId)
	end
end

m_HelperFunction.canUseSpell = function(name)
	if not name then
		return (m_HelperFunction.spellsExhaust["potion"] or 0) < os.time()
	end

	return (m_HelperFunction.spellsExhaust[name] or 0) < os.time()
end

m_HelperFunction.addExhaust = function(name)
	if not name then
		m_HelperFunction.spellsExhaust["potion"] = os.time() + 1
		return true
	end

	m_HelperFunction.spellsExhaust[name] = os.time() + (modules.gamelib.SpellInfo["Default"][name].exhaustion / 1000)
end

m_HelperFunction.onRemoveVip = function(id)
	local label = m_HelperList.friendHealingFriends:getChildById(id)
	if not label then
		return true
	end

	label:destroy()
end

m_HelperFunction.onAddVip = function(id, name, state, description, iconId, notify)  
  	if not name or name:len() == 0 then
    	return
  	end

	local label = g_ui.createWidget("HelperFriendListLabel", m_HelperList.friendHealingFriends)
	label.state = state
	label:setText(name)
	label:setId(id)
	if state == VipState.Online then
		label:setColor('#00FF00')
	elseif state == VipState.Pending then
		label:setColor('#FFCA38')
	else
		label:setColor('#FF0000')
	end
end

m_HelperFunction.onVipStateChange = function(id, state)
	local label = m_HelperList.friendHealingFriends:getChildById(id)
	if not label then
		return true
	end

	label.state = state
	if state == VipState.Online then
		label:setColor('#00FF00')
	elseif state == VipState.Pending then
		label:setColor('#FFCA38')
	else
		label:setColor('#FF0000')
	end
end

m_HelperFunction.onHealthChange = function(localPlayer, health, maxHealth)
	local healthPercent = health / maxHealth * 100
	for _, spellHealing in pairs(m_HelperList.spellHealingSlot) do
		if spellHealing.slot.type == m_HelperFunction.TYPE.SPELL then
			local value = spellHealing.comboBox:getCurrentOption().text
			local percent = tonumber(value:sub(1, #value - 1))
			if healthPercent <= percent and m_HelperFunction.canUseSpell(spellHealing.slot.spellName) then
				g_game.talk(spellHealing.slot.words)
				m_HelperFunction.addExhaust(spellHealing.slot.spellName)
			end
		end
	end

	for _, itemHealing in pairs(m_HelperList.potionHealingSlot) do
		if itemHealing.slot.type == m_HelperFunction.TYPE.ITEM then
			local value = itemHealing.comboBox:getCurrentOption().text
			local percent = tonumber(value:sub(1, #value - 1))
			if healthPercent <= percent and m_HelperFunction.canUseSpell() then
				g_game.useInventoryItemWith(itemHealing.slot.itemId, localPlayer, -1)
				m_HelperFunction.addExhaust()
			end
		end
	end
end

m_HelperFunction.timerEvent = function()
	local localPlayer = g_game.getLocalPlayer()
	if not localPlayer then
		return true
	end

	if m_HelperList.enableAutoHasteCheckBox:isChecked() then
		-- Auto haste
		if m_HelperList.pzCastCheckBox:isChecked() or not modules.game_inventory.hasStatus("condition_protection_zone") then
			if m_HelperList.autoHasteSlot.type == m_HelperFunction.TYPE.SPELL then
				if not modules.game_inventory.hasStatus("condition_haste") and m_HelperFunction.canUseSpell(m_HelperList.autoHasteSlot.spellName) then
					g_game.talk(m_HelperList.autoHasteSlot.words)
					m_HelperFunction.addExhaust(m_HelperList.autoHasteSlot.spellName)
				end
			end
		end
	end

	if m_HelperList.enableManaTrainingCheckBox:isChecked() then
		-- Auto mana training
		if m_HelperList.manaTrainingSlot.type == m_HelperFunction.TYPE.SPELL then
			local value = m_HelperList.manaTrainingComboBox:getCurrentOption().text
			local percent = tonumber(value:sub(1, #value - 1))
			local manaPercent = localPlayer:getMana() / localPlayer:getMaxMana() * 100
			if manaPercent >= percent and m_HelperFunction.canUseSpell(m_HelperList.manaTrainingSlot.spellName) then
				g_game.talk(m_HelperList.manaTrainingSlot.words)
				m_HelperFunction.addExhaust(m_HelperList.manaTrainingSlot.spellName)
			end
		end
	end

	local focusedChild = m_HelperList.friendHealingFriends:getFocusedChild()
	if focusedChild and focusedChild.state == VipState.Online then
		-- Friend healing
		local name = focusedChild:getText()
		local target = g_map.getCreatureByName(name)
		if target then
			for _, friendHealing in pairs(m_HelperList.friendHealingSlots) do
				if friendHealing.checkBox:isChecked() then
					local value = friendHealing.comboBox:getCurrentOption().text
					local percent = tonumber(value:sub(1, #value - 1))
					local healthPercent = target:getHealthPercent()
					if healthPercent <= percent then
						if friendHealing.slot.type == m_HelperFunction.TYPE.SPELL then
							if m_HelperFunction.canUseSpell(friendHealing.slot.spellName) then
								g_game.talk(friendHealing.slot.words .. ' "'.. name ..'"' )
								m_HelperFunction.addExhaust(friendHealing.slot.spellName)
							end
						elseif friendHealing.slot.type == m_HelperFunction.TYPE.ITEM then
							if m_HelperFunction.canUseSpell() then
								g_game.useInventoryItemWith(friendHealing.slot.itemId, target, -1)
								m_HelperFunction.addExhaust()
							end
						end
					end
				end
			end
		end
	end

	local flags = 0
	local itemId = 0
	if m_HelperList.autoEatFoodCheckBox:isChecked() then
		-- Auto eat food
		if localPlayer:getRegenerationTime() < 60 then
			flags = flags + 1
		end
	end

	if m_HelperList.enableExerciseTrainingCheckBox:isChecked() then
		-- Exercise weapon
		if m_HelperList.exerciseTrainingSlot.type == m_HelperFunction.TYPE.ITEM then
			itemId = m_HelperList.exerciseTrainingSlot.itemid
			flags = flags + 2
		end
	end
		
	if flags > 0 then
		m_HelperFunction.send(flags, itemId)
	end
end

m_HelperFunction.send = function(flags, itemId)
	local msg = OutputMessage.create()
	msg:addU8(m_HelperFunction.GameServerSendTools)
	msg:addU8(flags)
	msg:addU16(itemId)
	g_game.getProtocolGame():send(msg)
end

m_HelperFunction.openHealingPanel = function()
	m_HelperList.toolsPanel:hide()
	m_HelperList.healingPanel:show()
	m_HelperList.toolsButton:setOn(false)
	m_HelperList.healingButton:setOn(true)

	local vocationId = 3--g_game.getLocalPlayer():getVocation()
	local height = m_HelperFunction.heightByVocation[vocationId]
	m_HelperList.potionHealingSlot[3]:hide()
	m_HelperList.friendHealingPanel:setOn(false)
	if vocationId == 0 then -- None
		-- No changes to layout
	elseif vocationId == 1 then -- Knight
		-- No changes to layout
	elseif vocationId == 2 then -- Paladin
		m_HelperList.potionHealingSlot[3]:show()
	elseif vocationId == 3 then -- Sorcerer
		m_HelperList.friendHealingPanel:setOn(true)
		height = height + m_HelperList.friendHealingPanel:getHeight()
	elseif vocationId == 4 then -- Druid
		m_HelperList.friendHealingPanel:setOn(true)
		height = height + m_HelperList.friendHealingPanel:getHeight()
	end

	m_HelperList.window:setHeight(height)
end

m_HelperFunction.openToolsPanel = function()
	m_HelperList.toolsPanel:show()
	m_HelperList.healingPanel:hide()
	m_HelperList.toolsButton:setOn(true)
	m_HelperList.healingButton:setOn(false)
	m_HelperList.friendHealingPanel:setOn(false)
	m_HelperList.window:setHeight(m_HelperFunction.defaultHeight)
end

m_HelperFunction.openTab = function(id)
	if id == 1 then
		m_HelperFunction.openHealingPanel()
	else
		m_HelperFunction.openToolsPanel()
	end
end

m_HelperFunction.destroySpellWindow = function()
	if m_HelperList.spellWindow then
		m_HelperList.window:setEnabled(true)
		m_HelperList.spellWindow:destroy()
		m_HelperList.spellWindow = nil
	end
end

m_HelperFunction.applySpellWindow = function()
	if not m_HelperList.radio then
		return false
	end

    local selected = m_HelperList.radio:getSelectedWidget()
	if not selected then
		return false
	end

	m_HelperList.spellWindow.widget.type = selected.type
	if selected.type == m_HelperFunction.TYPE.SPELL then
	    m_HelperList.spellWindow.widget.text:setImageSource(selected.source)
		m_HelperList.spellWindow.widget.text:setImageClip(selected.clip)
		m_HelperList.spellWindow.widget.words = selected.words
		m_HelperList.spellWindow.widget.spellName = selected.spellName
	elseif selected.type == m_HelperFunction.TYPE.ITEM then
		m_HelperList.spellWindow.widget.item:setItemId(selected.itemId)
		m_HelperList.spellWindow.widget.item:setOn(true)
		m_HelperList.spellWindow.widget.itemId = selected.itemId
	end
end

m_HelperFunction.okSpellWindow = function()
	m_HelperFunction.applySpellWindow()
	m_HelperFunction.destroySpellWindow()
end

m_HelperFunction.translateVocation = function(id) 
	if id == 1 or id == 11 then
	  	return 8 -- ek
	elseif id == 2 or id == 12 then
	  	return 7 -- rp
	elseif id == 3 or id == 13 then
	 	 return 5 -- ms
	elseif id == 4 or id == 14 then
	  	return 6 -- ed
	end
end

m_HelperFunction.assignItem = function(self)
	m_HelperList.window:setEnabled(false)
	m_HelperList.spellWindow = g_ui.loadUI("assign_item", g_ui.getRootWidget())
	m_HelperList.spellWindow.widget = self
	
	local list = m_HelperList.spellWindow:getChildById("list")
	local itemsList = {}
	if self == m_HelperList.exerciseTrainingSlot then
		itemsList = m_HelperFunction.exerciseWeapons
	else
		itemsList = m_HelperFunction.healthPotions
	end

	for i = 1, #itemsList do
		local widget = g_ui.createWidget("ItemPreview", list)
		m_HelperList.radio:addWidget(widget)
		widget.type = m_HelperFunction.TYPE.ITEM
		widget.itemId = itemsList[i]
		widget.image:setItemId(widget.itemId)
	end
end

m_HelperFunction.assignSpell = function(self, parent)
	local id = parent and parent:getId() or self:getId()
	m_HelperList.window:setEnabled(false)
	m_HelperList.spellWindow = g_ui.loadUI("assign_spell", g_ui.getRootWidget())
	m_HelperList.spellWindow.widget = self
	
	local list = m_HelperList.spellWindow:getChildById("list")
	local spells = modules.gamelib.SpellInfo["Default"]
	local spellsList = m_HelperFunction.spellList[id]
	if #spellsList == 0 then
		for spellName, spellData in pairs(spells) do
			table.insert(spellsList, spellName)
		end
	end

	local vocationId = m_HelperFunction.translateVocation(g_game.getLocalPlayer():getVocation())
	for i = 1, #spellsList do
		local spellName = spellsList[i]
		local spellData = spells[spellName]
		if table.find(spellData.vocations, vocationId) then
			local widget = g_ui.createWidget("SpellPreview", list)
			m_HelperList.radio:addWidget(widget)
			widget:setId(spellData.id)
			widget:setText(spellName .. "\n" .. spellData.words)

			widget.source = SpelllistSettings['Default'].iconFile
			widget.clip = Spells.getImageClip(SpellIcons[spellData.icon][1], 'Default')
			widget.words = spellData.words
			widget.spellName = spellName
			widget.type = m_HelperFunction.TYPE.SPELL

			local spellImage = widget:getChildById("image")
			spellImage:setImageSource(widget.source)
			spellImage:setImageClip(widget.clip)
		end
	end
end

m_HelperFunction.clearSlot = function(self)
    self.text:setImageSource(nil)
	self.item:setItemId(nil)
	self.item:setOn(false)
    self.type = m_HelperFunction.TYPE.BLANK
end

m_HelperFunction.onSlotMouseRelease = function(self, mousePos, mouseButton)
	if mouseButton == MouseRightButton then
		local parent = self:getParent()
		if parent == m_HelperList.friendHealingSlots[1] or parent == m_HelperList.friendHealingSlots[2] then
			return true
		end

		local menu = g_ui.createWidget("PopupMenu")
		menu:setGameMenu(true)

		if self == m_HelperList.autoHasteSlot or self == m_HelperList.manaTrainingSlot then
			menu:addOption(self.spellId and tr("Edit Spell") or tr("Assign Spell"), function() m_HelperFunction.assignSpell(self) end)
		elseif parent == m_HelperList.spellHealingSlot[1] or parent == m_HelperList.spellHealingSlot[2] then
			menu:addOption(self.spellId and tr("Edit Spell") or tr("Assign Spell"), function() m_HelperFunction.assignSpell(self, parent) end)
		else
			menu:addOption(self.item:getItemId() > 100 and tr("Edit Object") or tr("Assign Object"), function() m_HelperFunction.assignItem(self) end)
		end

		if self.type ~= m_HelperFunction.TYPE.BLANK then
		  	menu:addSeparator()
		  	menu:addOption(tr("Clear Slot"), function() m_HelperFunction.clearSlot(self) end)
		end
		menu:display(mousePos)
	end
end