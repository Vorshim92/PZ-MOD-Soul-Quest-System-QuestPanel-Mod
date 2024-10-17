require "XpSystem/ISUI/SF_MissionLists"
require "ISUI/ISButton"
SFQuest_QuestWindow = ISCollapsableWindow:derive("SFQuest_QuestWindow")
SFQuest_QuestWindow.tooltip = nil;

function SFQuest_QuestWindow:initialise()
	ISCollapsableWindow.initialise(self);
end

local function loadTexture(id, icons)
    if id > -1 and id < icons:size() then
        return getTexture("Item_"..tostring(icons:get(id)));
    end
end

local function getRealTexture(scriptItem)
	local texture = scriptItem:getNormalTexture()
	if not texture then
		local obj = scriptItem:InstanceItem(nil)
		if obj then
			local icons = scriptItem:getIconsForTexture()
			if icons and icons:size() > 0 then
				texture = loadTexture(obj:getVisual():getBaseTexture(), icons) or loadTexture(obj:getVisual():getTextureChoice(), icons)
			else
				texture = obj:getTexture()
			end
		end
	end
	return texture
end

function SFQuest_QuestWindow:createChildren()
	ISCollapsableWindow.createChildren(self)
	-- local titleBarHeight = self:titleBarHeight()
    self.rewX = 0
    self.objX = 0
	-- print("controllo loop in createchildren: " .. self.title)
	self.richText = ISRichTextPanel:new(25, 40, self.width-110, 100);
	self.richText.autosetheight = false;
	self.richText.clip = true
	self.richText:initialise();
	self.richText.background = false;
	self.richText:setAnchorTop(true);
	self.richText:setAnchorLeft(true);
	self.richText:setAnchorRight(true);
	-- self.richText:setAnchorBottom(true);
	self.richText:setVisible(false);
	self.richText.backgroundColor  = {r=0.5, g=0.5, b=0.5, a=0.1};
	self.richText.text = getText(self.dialogueinfo[1]) or "...";
    self.richText:setMargins(10,10,20,10)
    self.richText:paginate()
    -- local lineHeight = getTextManager():getFontFromEnum(self.font):getLineHeight();
	self.richText:addScrollBars()
    -- self.richText.vscroll.x + 5
	self:addChild(self.richText);
    --test
	self.originalTitle = self.title

	if self.picture then
	-- self.Image = ISButton:new(12, 40, 95, 82, " ", nil, nil);
	self.picTexture = getTexture(self.picture)
	-- self.Image:setImage(self.picTexture)
    -- self.Image:setVisible(true);
	-- self.Image:setEnable(true);
	-- self:addChild(self.Image) 
    end
    self.richText:setX(10 + self.picTexture:getWidth())
    -- self.richText:setY(40)
	
	

    -- check if quest has killzombies in actionevent
    if self.unlocks and luautils.stringStarts(self.unlocks, "actionevent") then -- maybe adding a for loop for self.unlocks to check if actionevent exists?
        local unlocksTable = luautils.split(self.unlocks:gsub(":", ";"), ";")
        if unlocksTable[2] == "killzombies" then
            self.hasZombieCounter = true
            self.goal = tonumber(unlocksTable[3])
        end
        local player = getPlayer()
        for i,v in ipairs(player:getModData().missionProgress.ActionEvent) do
            local commands = luautils.split(v.commands, ";");
            if self.guid == commands[2] then
                self.tempGoal = tonumber(luautils.split(v.condition, ";")[2])
                self.currentKills = player:getZombieKills()
                print("tempGoal: " .. self.tempGoal)
                print("currentKills: " .. self.currentKills)
                print("goal: " .. self.goal)
                break
            else
                self.hasZombieCounter = false
            end
        end
        if not self.hasZombieCounter then
            -- se non esiste l'action event si presuppone sia stato già completato? quindi:
            self.currentKills = self.goal
            self.hasZombieCounter = true
        end
    end
    

	local objectiveHeight  = 15
	if self.objectives and #self.objectives > 3 then
		self:setHeight(self.height + (objectiveHeight * (#self.objectives - 3)))
	end
	if self.awardsitem and self.awardsrep then
		self:setHeight(self.height + (objectiveHeight * 2))
	end

    -- gathering needsitem from objectives
    self.preprocessedObjectives = {}
    if self.objectives and #self.objectives > 0 then
        for i = 1, #self.objectives do
            -- print("Objective: " .. self.objectives[i].text)
            local objectiveData = {
                text = self.objectives[i].text,
                hidden = self.objectives[i].hidden
            }
            if not self.objectives[i].needsitem then 
                self.objX = math.max(self.objX, getTextManager():MeasureStringX(UIFont.Normal, objectiveData.text))
            end
            if self.objectives[i].needsitem then
                local needItem
                local newString = self.objectives[i].needsitem
                newString = newString:gsub("Tag.-#", ""):gsub("Predicate.-#", "")

                local needsTable = luautils.split(newString, ";")
                -- print("needsTable item: " .. needsTable[1])
                -- print("needsTable count: " .. needsTable[2])
                if luautils.stringStarts(self.objectives[i].needsitem, "Tag#") then
                    local itemsArray = getScriptManager():getItemsTag(needsTable[1])
                    objectiveData.tag = true
                    objectiveData.tagItems = {}
                    local itemNamesSet = {}  -- To track existing item names
                    if itemsArray and itemsArray:size() > 0 then
                        local maxTextWidth = 0
                        for k = 0, itemsArray:size() - 1 do
                            local itemName = itemsArray:get(k):getDisplayName()
                            maxTextWidth = math.max(maxTextWidth, getTextManager():MeasureStringX(UIFont.Normal, itemName))
                            -- print("itemName: " .. itemName .. " maxTextWidth: " .. maxTextWidth)
                            local itemTexture = getRealTexture(itemsArray:get(k))
                            if not itemNamesSet[itemName] then
                                table.insert(objectiveData.tagItems, {itemName = itemName, itemTexture = itemTexture})
                                itemNamesSet[itemName] = true  -- Mark the itemName as added
                            end
                        end
                        objectiveData.maxTextWidth = maxTextWidth
                        needItem = itemsArray:get(0)
                    end
                else
                    needItem = getScriptManager():FindItem(needsTable[1])
                    if not needItem then
                        local javaItem = getScriptManager():getItemsByType(needsTable[1])
                        if javaItem and javaItem:size() > 0 then
                            needItem = javaItem:get(0)
                        end
                    end
                end
                if needItem then
                    -- print("needItem trovato in obj: " .. needItem:getDisplayName())
                    objectiveData.itemName = needItem:getDisplayName()
                    self.objX = math.max(self.objX, getTextManager():MeasureStringX(UIFont.Normal, objectiveData.itemName))
                    objectiveData.itemCount = needsTable[2] or "1"
                    local texture = getRealTexture(needItem)
                    if texture then
                        objectiveData.iconTexture = texture
                    end
                end
                if objectiveData.tag then
                    self.tagsButton = ISButton:new(self.width - 20, self.height - 20, 20, 20, "", nil, nil, nil, nil);
                    self.tagsButton:setEnable(true)
                    -- self.tagsButton:setTextureRGBA(1, 1, 1, 1)
                    -- self.tagsButton:setBackgroundRGBA(0, 0, 0, 0.5)
                    self.tagsButton:noBackground()
                    -- self.tagsButton:setBorderRGBA(1, 1, 1, 0)
                    -- self.tagsButton:setBackgroundColorMouseOverRGBA(0,0,0,0.5)
                    self.tagsButton:initialise();
                    -- self.tagsButton.ztooltip = ObjectTooltip.new()
                    -- self.tagsButton.ztooltip:setX(0)
                    -- self.tagsButton.ztooltip:setY(0)
                    -- self.tagsButton.ztooltip:setVisible(false)
                    -- self.tagsButton.ztooltip:setOwner(self)
                    -- self.tagsButton.ztooltip:setVisible(false)
                    -- self.tagsButton.ztooltip:setAlwaysOnTop(true)
                    self:addChild(self.tagsButton);
                end

            end
            table.insert(self.preprocessedObjectives, objectiveData)
        end
    end

    self.preprocessedNeedsItems = {}
    if self.needsitem then
        local scriptItem
        local newString = self.needsitem
        newString = newString:gsub("Tag.-#", ""):gsub("Predicate.-#", "")
        local needsTable = luautils.split(newString, ";")
        local itemId = needsTable[1]
        local itemCount = needsTable[2]
        local needsItemData = {itemId = itemId, itemCount = itemCount or "1"}
        if luautils.stringStarts(self.needsitem, "Tag#") then
            local itemsArray = getScriptManager():getItemsTag(needsTable[1])
            needsItemData.tag = true
            needsItemData.tagItems = {}
            local itemNamesSet = {}  -- To track existing item names
            if itemsArray and itemsArray:size() > 0 then
                local maxTextWidth = 0
                for i = 0, itemsArray:size() - 1 do
                    local itemName = itemsArray:get(i):getDisplayName()
                    maxTextWidth = math.max(maxTextWidth, getTextManager():MeasureStringX(UIFont.Normal, itemName))
                    -- print("itemName: " .. itemName .. " maxTextWidth: " .. maxTextWidth)
                    local itemTexture = getRealTexture(itemsArray:get(i))
                    if not itemNamesSet[itemName] then
                        table.insert(needsItemData.tagItems, {itemName = itemName, itemTexture = itemTexture})
                        itemNamesSet[itemName] = true  -- Mark the itemName as added
                    end
                end
                needsItemData.maxTextWidth = maxTextWidth
                scriptItem = itemsArray:get(0)

            end
        else
            scriptItem = getScriptManager():FindItem(needsTable[1])
            if not scriptItem then
                local javaItem = getScriptManager():getItemsByType(needsTable[1])
                if javaItem and javaItem:size() > 0 then
                    scriptItem = javaItem:get(0)
                end
            end
        end
        
        if scriptItem then
            needsItemData.itemName = scriptItem:getDisplayName()
            self.objX = getTextManager():MeasureStringX(UIFont.Normal, needsItemData.itemName)
                -- print(textWidth)
                -- if self.objX > 123 then
                --     self:setWidth(self.width + self.objX-123)
                -- end
            local texture = getRealTexture(scriptItem)
            if texture then
                needsItemData.iconTexture = texture
            end
        end
        table.insert(self.preprocessedNeedsItems, needsItemData)
        if needsItemData.tag then
            self.tagsButton = ISButton:new(self.width - 20, self.height - 20, 20, 20, "", nil, nil, nil, nil);
            self.tagsButton:setEnable(true)
            -- self.tagsButton:setTextureRGBA(1, 1, 1, 1)
            -- self.tagsButton:setBackgroundRGBA(0, 0, 0, 0.5)
            self.tagsButton:noBackground()
            -- self.tagsButton:setBorderRGBA(1, 1, 1, 0)
            -- self.tagsButton:setBackgroundColorMouseOverRGBA(0,0,0,0.5)
            self.tagsButton:initialise();
            -- self.tagsButton.ztooltip = ObjectTooltip.new()
            -- self.tagsButton.ztooltip:setX(0)
            -- self.tagsButton.ztooltip:setY(0)
            -- self.tagsButton.ztooltip:setVisible(false)
            -- self.tagsButton.ztooltip:setOwner(self)
			-- self.tagsButton.ztooltip:setVisible(false)
			-- self.tagsButton.ztooltip:setAlwaysOnTop(true)
            self:addChild(self.tagsButton);
        end
    end

    self.preprocessedRewards = {}
    if self.awardsrep then
        local repTable = luautils.split(self.awardsrep, ";")
        for i = 1, #repTable, 2 do
            local repBonus = repTable[i + 1]
            local repStr = "+" .. repBonus .. " reputation"
            table.insert(self.preprocessedRewards, {type = "reputation", text = repStr})
            break
        end
    end

    if self.awardsitem then
        local count = 1
        local rewardTable = luautils.split(self.awardsitem, ";")

        while rewardTable[count] do
            local itemId = rewardTable[count]
            local itemCount = rewardTable[count+1] or "1"
            local rewardData = {itemId = itemId, itemCount = itemCount}


            local scriptItem = getScriptManager():FindItem(rewardTable[count])
			if not scriptItem then
				local javaItem = getScriptManager():getItemsByType(rewardTable[count])
				if javaItem and javaItem:size() > 0 then
					scriptItem = javaItem:get(0)
				end
			end
            if scriptItem then
                rewardData.itemName = scriptItem:getDisplayName()
                -- fix for panel width dimension issue
                self.rewX = math.max(self.rewX, getTextManager():MeasureStringX(UIFont.Normal, rewardData.itemName))+30 --+30 offset icona
                -- print("itemName: " .. rewardData.itemName .. " maxTextWidth: " .. self.rewX)
                -- print(textWidth)
                -- if self.rewX > 60 then
                --     self:setWidth(self.width+self.rewX-30)
                -- end
                -- fix for panel width dimension issue
                local texture = getRealTexture(scriptItem)
                if texture then
                    rewardData.iconTexture = texture
                end
            end
            table.insert(self.preprocessedRewards, rewardData)

            count = count + 2
        end
    end
    if self.objX < 120 then
        self.objX = 120
    end
    if self.rewX < 100 then
        self.rewX = 100
    end

    local rewX = self.objX +60 +50 +20  --+50 offset icona --60 offset for status

  
    if rewX+self.rewX > self.width then
        self:setWidth(rewX+self.rewX)
    end
    if rewX+self.rewX < self.width then
        self:setWidth(rewX+self.rewX)
    end
    self.rewX = rewX

end




function SFQuest_QuestWindow:collapse()
    ISCollapsableWindow.collapse(self)
end

function SFQuest_QuestWindow:uncollapse()
    ISCollapsableWindow.uncollapse(self)
end




-- Funzioni helper
local function drawReputationReward(self, reward, rewX, rewardHeight)
    self:drawTextureScaledAspect(getTexture("media/textures/Item_PlusRep.png"), rewX-16, rewardHeight, 20, 20, 1, 1, 1, 1)
    self:drawText(reward.text, rewX+5, rewardHeight + 2, 1, 1, 1, 1, self.font)
    return rewardHeight - 20
end

local function drawItemRewards(self, reward, rewX, rewardHeight)
    if reward.iconTexture then
        self:drawTextureScaledAspect(reward.iconTexture, rewX-16, rewardHeight, 20, 20, 1, 1, 1, 1)
    end
    local itemName = reward.itemName or reward.itemId
    
    self:drawText(itemName .. "  x " .. reward.itemCount, rewX+5, rewardHeight + 2, 1, 1, 1, 1, UIFont.Normal)
    return rewardHeight - 20
end


local function drawRewards(self, rewards, rewX, rewardHeight)
    local hasRewards = false
    for _, reward in ipairs(rewards) do
        if reward.type == "reputation" then
            rewardHeight = drawReputationReward(self, reward, rewX, rewardHeight)
        else
            rewardHeight = drawItemRewards(self, reward, rewX, rewardHeight)
        end
        hasRewards = true
    end
    return hasRewards, rewardHeight
end


local function drawNeededItems(self, needsItems, status, objX, needsHeight)
    for i = 1, #needsItems do
        local itemData = needsItems[i]
        local itemName = itemData.itemName or itemData.itemId
        local itemCount = itemData.itemCount
        local iconTexture = itemData.iconTexture
        local isTag = itemData.tag
        local r, g, b = 1, 1, 1

        if status then
            local objstatus = getText("IGUI_XP_TaskStatus_" .. status)
            itemName = objstatus .. " " .. itemName
            if status == "Completed" then
                r, g, b = 0, 1, 0.5
                
            elseif status == "Obtained" then
                r, g, b = 1, 1, 0
            end
        end

        if isTag then
            -- Display with expand/collapse functionality
            local displayText = string.format("%s x %s", self.title, itemCount)
            self:drawText(displayText, objX+5, needsHeight + 2, r, g, b, 1, UIFont.Normal)
            local titleWidth = getTextManager():MeasureStringX(UIFont.Normal, displayText)

            local btnWidth = getTextManager():MeasureStringX(UIFont.Normal, "LISTA")
            self.tagsButton:setTitle("LISTA")
            self.tagsButton.textColor = {r=r, g=g, b=b, a=1.0};
            self:drawTextureScaledAspect2(iconTexture, objX-16, needsHeight+2, 16, 16, 1, 1, 1, 1) -- mettere icona nuova multi items request
            self.tagsButton:setX(titleWidth+16+objX)
            self.tagsButton:setY(needsHeight)
            self.tagsButton:setWidth(btnWidth + 10)
            

            -- tooltip
            -- self.tagsButton.ztooltip:setDesiredPosition(getMouseX(), self:getAbsoluteY() + self:getHeight() + 8)
            if self.tagsButton:isMouseOver() then
                -- self.tagsButton.ztooltip:setVisible(true)
                -- local mx = getMouseX() + 24;
                -- local my = getMouseY() + 24;
                -- self.tagsButton.ztooltip:setX(mx+11);
                -- self.tagsButton.ztooltip:setY(my);
                -- self.tagsButton.ztooltip:setWidth(50)
                self.tagsButton.textColor = {r=0, g=1.0, b=0, a=1.0};
                local tooltipHeight = self.tagsButton.height+5
                local tooltipTitle = "Lista Items Accettati:" -- TODO: create translation
                local rectWidthMax = math.max(itemData.maxTextWidth, getTextManager():MeasureStringX(UIFont.Large, tooltipTitle))
                self.tagsButton:drawRect(0, self.tagsButton.height+5, rectWidthMax+30, 20 * #itemData.tagItems+tooltipHeight, 0.5, 0, 0, 0);
                self.tagsButton:drawRectBorder(0, tooltipHeight, rectWidthMax+30, 20 * #itemData.tagItems+tooltipHeight, 0.5, 1, 1, 1);
                self.tagsButton:drawText(tooltipTitle, 25, tooltipHeight+2, 1,1,1,1,UIFont.Large)
                tooltipHeight = tooltipHeight + 20
                for _, validItem in ipairs(itemData.tagItems) do
                    -- self.tagsButton.ztooltip:DrawTextureScaledAspect(validItem.itemTexture, 5, tooltipHeight, 16, 16, 1, 1, 1, 1)
                    -- self.tagsButton.ztooltip:DrawText(UIFont.Normal,validItem.itemName, 25, tooltipHeight, 1,1,1,1);
                    self.tagsButton:drawTextureScaledAspect(validItem.itemTexture, 5, tooltipHeight+4, 16, 16, 1, 1, 1, 1)
                    self.tagsButton:drawText(validItem.itemName, 25, tooltipHeight+4, 1,1,1,1,UIFont.Normal)
                    tooltipHeight = tooltipHeight + 20
                end 
            else
                self.tagsButton.textColor = {r=r, g=g, b=b, a=1.0};
                -- self.tagsButton.ztooltip:setVisible(false)
            end
        else
            -- if iconTexture
            if iconTexture then
                self:drawTextureScaledAspect2(iconTexture, objX-16, needsHeight+2, 16, 16, 1, 1, 1, 1)
            end
            -- Display single items normally
            self:drawText(itemName .. " x" .. itemCount, objX+5, needsHeight + 2, r, g, b, 1, UIFont.Normal)
        end

        needsHeight = needsHeight - 20
    end

    return needsHeight
end

local function drawObjectives(self, preprocessedObjectives, objectives, objX, needsHeight)
    for i = 1, #preprocessedObjectives do
        local objective = preprocessedObjectives[i]
        local isTag = objective.tag
        local objName = getText(objective.text)
        local objstatus

        if not objective.hidden then
            if not objective.iconTexture then
                objective.iconTexture = getTexture("media/textures/clickevent.png")
            end

            

            local r, g, b = 1, 1, 1

            -- Handle status coloring and text
            if objectives[i].status then
                objstatus = getText("IGUI_XP_TaskStatus_" .. objectives[i].status)
                objName = objstatus .. " " .. (objName or "...")
                if objectives[i].status == "Completed" then
                    r, g, b = 0, 1, 0.5
                    
                elseif objectives[i].status == "Obtained" then
                    r, g, b = 1, 1, 0
                end
            end

            if objectives[i] and objectives[i].needsitem then
                local itemCount = objective.itemCount
                if not objective.itemName or not objective.itemCount then
                    local needsitemTable = luautils.split(objectives[i].needsitem, ";")
                    objName = (needsitemTable[1] .. " X " .. needsitemTable[2] )
                else
                    objName = (objective.itemName .. " X " .. objective.itemCount )
                end
                if objectives[i].status then
                    local objstatus = getText("IGUI_XP_TaskStatus_" .. objectives[i].status)
                    objName = objstatus .. " " .. (objName or "...")
                end

                if isTag then
                    local displayText = string.format("%s x %s", getText(objective.text), itemCount)
                    local titleWidth = getTextManager():MeasureStringX(UIFont.Normal, displayText)

                    local btnWidth = getTextManager():MeasureStringX(UIFont.Normal, "LISTA")
                    -- Ensure self.tagsButton is initialized elsewhere in your code
                    self.tagsButton:setTitle("LISTA")
                    self.tagsButton.textColor = { r = r, g = g, b = b, a = 1.0 }
                    self:drawTextureScaledAspect2(objective.iconTexture, objX - 16, needsHeight + 2, 16, 16, 1, 1, 1, 1)
                    self.tagsButton:setX(titleWidth + 16 + 20 + objX)
                    self.tagsButton:setY(needsHeight)
                    self.tagsButton:setWidth(btnWidth + 10)

                    -- Tooltip display when hovering over the button
                    if self.tagsButton:isMouseOver() then
                        self.tagsButton.textColor = { r = 0, g = 1.0, b = 0, a = 1.0 }
                        local tooltipHeight = self.tagsButton.height + 5
                        local tooltipTitle = "Lista Items Accettati"
                        local rectWidthMax = math.max(objective.maxTextWidth, getTextManager():MeasureStringX(UIFont.Large, tooltipTitle))
                        self.tagsButton:drawRect(0, tooltipHeight, rectWidthMax + 40, 20 * #objective.tagItems + tooltipHeight, 0.5, 0, 0, 0)
                        self.tagsButton:drawRectBorder(0, tooltipHeight, rectWidthMax + 40, 20 * #objective.tagItems + tooltipHeight, 0.5, 1, 1, 1)
                        self.tagsButton:drawText(tooltipTitle, 25, tooltipHeight + 2, 1, 1, 1, 1, UIFont.Large)
                        tooltipHeight = tooltipHeight + 20

                        for _, validItem in ipairs(objective.tagItems) do
                            self.tagsButton:drawTextureScaledAspect(validItem.itemTexture, 5, tooltipHeight + 4, 16, 16, 1, 1, 1, 1)
                            self.tagsButton:drawText(validItem.itemName, 25, tooltipHeight + 4, 1, 1, 1, 1, UIFont.Normal)
                            tooltipHeight = tooltipHeight + 20
                        end
                    else
                        self.tagsButton.textColor = { r = r, g = g, b = b, a = 1.0 }
                    end
                end
            end
            if objective.iconTexture then
                self:drawTextureScaledAspect2(objective.iconTexture, objX-16, needsHeight+2, 16, 16, 1, 1, 1, 1)
            end
            -- local objText = objName .. " x" .. itemCount
            self:drawText(objName, objX + 5, needsHeight + 2, r, g, b, 1, UIFont.Normal)

            needsHeight = needsHeight - 20
        end
    end
    return needsHeight
end

-- Funzione render
function SFQuest_QuestWindow:render()
    ISCollapsableWindow.render(self)
    -- local height = self:getHeight();
	-- local th = self:titleBarHeight()
	-- if self.isCollapsed then
	-- 	height = th;
    -- end
    local needsHeight = self.height - self.fontHeight - 10
    local rewardHeight = self.height - self.fontHeight - 10
    local hasRewards = false
    local hasNeeds = false
    local hasObjs = false
    local objX = 20
    

    if self.task.status then
        self:setTitle(getText("IGUI_XP_TaskStatus_" .. self.task.status) .. " " .. self.originalTitle)
    else 
        self:setTitle(self.originalTitle)
    end
    if self.isCollapsed then
        if self.hasZombieCounter then
            if #self.title > 30 then
                self:setTitle(string.sub(self.title, 1, 20) .. "...")
                -- self:setTitle(string.sub(self.title, 1, 20) .. "...")
            end
            local player = getPlayer()
            if self.hasZombieCounter then
                local player = getPlayer()
                if player then
                    local newCurrentKills = player:getZombieKills()
                    if newCurrentKills > self.tempGoal then
                        self.currentKills = self.goal
                    else
                        self.currentKills = newCurrentKills
                        if self.currentKills - (self.tempGoal - self.goal) >= self.goal then
                            self.currentKills = self.goal
                        end
                    end
                end
            end
            self:drawTextureScaledAspect2(self.zombieTexture, 280, 2, 16, 16, 1, 1, 1, 1)
            self:drawText("Zombie: " .. tostring(self.currentKills) .. "/" .. tostring(self.goal), 300, 3, 1, 1, 1, 1, self.font)
            -- self:drawText(getText("IGUI_Objectives"), 30, 25, 1, 1, 1, 1, UIFont.Medium)
        end
        return
    end


    self.richText:setVisible(true)

    self:drawText(self.npcname, 12, 25, 1, 1, 1, 1, UIFont.Medium)

    if self.picTexture then
    self:drawTexture(self.picTexture, 12, 50, 1, 1, 1, 1);
    self:drawRectBorder(12, 50, self.picTexture:getWidth(), self.picTexture:getHeight(), 0.5, 1, 1, 1);
    end


    if self.preprocessedRewards and #self.preprocessedRewards > 0 then
        hasRewards, rewardHeight = drawRewards(self, self.preprocessedRewards, self.rewX, rewardHeight)
        if hasRewards then
            self:drawText(getText("IGUI_Rewards"), self.rewX , rewardHeight -5, 1, 1, 1, 1, UIFont.Medium)
        end
    end

    -- Disegna gli oggetti necessari
    if self.preprocessedNeedsItems and #self.preprocessedNeedsItems > 0 then
        if self.awardsitem or self.awardsrep then
            needsHeight = rewardHeight + 20
        end
        needsHeight = drawNeededItems(self, self.preprocessedNeedsItems, self.task.status, objX, needsHeight)
        hasNeeds = true
    end
    if hasNeeds then
        self:drawText(getText("IGUI_Objectives"), objX, needsHeight -5, 1, 1, 1, 1, UIFont.Medium)
    end

    local r, g, b = 1,1,1
    local zombieStatus = ""
    if self.hasZombieCounter then
        local player = getPlayer()
        if player then
            local newCurrentKills = player:getZombieKills()
            if newCurrentKills > self.tempGoal then
                self.currentKills = self.goal
                r,g,b = 0,1,0.5
                zombieStatus = getText("IGUI_XP_TaskStatus_Completed")
            else
                self.currentKills = newCurrentKills
                if self.currentKills - (self.tempGoal - self.goal) >= self.goal then
                    self.currentKills = self.goal
                    r,g,b = 0,1,0.5
                end
            end
        end

        if not self.objectives then
            self:drawText(getText("IGUI_Objectives"),  objX, needsHeight -20, 1, 1, 1, 1, UIFont.Medium)
            self:drawTextureScaledAspect2(self.zombieTexture, objX-16, needsHeight+2, 16, 16, 1, 1, 1, 1)
        
            self:drawText(zombieStatus.."Zombie: " .. tostring(self.currentKills) .. "/" .. tostring(self.goal),  objX+5, needsHeight + 4, r, g, b, 1, self.font)
        end
    end

    -- Disegna gli obiettivi
    if self.preprocessedObjectives and #self.preprocessedObjectives > 0 then
        hasObjs = true
        if self.awardsitem or self.awardsrep then
            needsHeight = rewardHeight + 20
        end
        
        needsHeight = drawObjectives(self, self.preprocessedObjectives, self.objectives, objX, needsHeight)
        if self.hasZombieCounter then
            self:drawTextureScaledAspect2(self.zombieTexture, objX-16, needsHeight+2, 16, 16, 1, 1, 1, 1)
            self:drawText(zombieStatus.."Zombie: " .. tostring(self.currentKills) .. "/" .. tostring(self.goal), objX+5, needsHeight + 4, r, g, b, 1, self.font)
            needsHeight = needsHeight - 20
        end
        if hasObjs then
            self:drawText(getText("IGUI_Objectives"), objX , needsHeight -5, 1, 1, 1, 1, UIFont.Medium)
        end
    end

    
end


function SFQuest_QuestWindow:update()
	ISCollapsableWindow.update(self)
end

function SFQuest_QuestWindow:close()
	self:removeFromUIManager()
end

function SFQuest_QuestWindow:new(x, y, item)

	-- print("controllo loop in new: " .. item.text)
    -- this will be much more easy if we can get from the task the npc's identity, so we can use SF_MissionPanel.instance:getWorldInfo(identity);
	local width = 420
	local height = 250
	local o = ISCollapsableWindow:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o:setResizable(false);
	o.fontHeight = getTextManager():getFontHeight(self.font)
	o.isCollapsed = false
	-- o.clearStentil = false;

	-- valori quest
	o.dialogueinfo = item.lore;
	local pictureConversion = string.gsub(item.texture, 'Item', 'Picture')
    if not pictureConversion then
        pictureConversion = "media/textures/Picture_Default.png"
    end
	o.picture = pictureConversion
	o.awardsrep = item.awardsrep
	o.awardsitem = item.awardsitem
	o.awardstask = item.awardstask
	o.objectives = item.objectives
	o.needsitem = item.needsitem
	o.unlocks = item.unlocks
	-- sezione variabili zombiekills counters
	o.tempGoal = 0;
	o.goal = 0;
	o.currentKills = 0;
	o.hasZombieCounter = false;
    o.zombieTexture = getTexture("media/ui/Moodle_Icon_Zombie.png")
	-- fine sezione
	o.guid = item.guid
	o.title = getText(item.text) or "????";
    o.status = item.status or nil
	-- if item.status then
	-- 	o.title = getText("IGUI_XP_TaskStatus_" .. item.status) .. getText(item.text);
	-- end
	o.titleFont = UIFont.Medium
	o.titleFontHgt = getTextManager():getFontHeight(o.titleFont)
	o.npcname = getText(item.title)
    o.task = item
	SFQuest_QuestWindow.instance = o;
	return o
end



function SFQuest_MissionLists:onMouseDown(x, y)
	local parent = SF_MissionPanel.instance;
	if #self.items == 0 then return end
	local row = self:rowAt(x, y)

	if row > #self.items then
		row = #self.items;
	end
	if row < 1 then
		row = 1;
	end

	self.selected = row;

            if self.items[row].guid == parent.expanded then
            	parent.expanded = nil;
				parent.loretitle = nil;
				parent.lore = {};
				parent.currentPage = 1;
				self:setHeight(self.originalheight);
				parent.titleLabel:setVisible(false);
				parent.pageLabel:setVisible(false);
				parent.nextPage:setVisible(false);
				parent.previousPage:setVisible(false);
				parent.richText:setVisible(false);
				getSoundManager():playUISound("UISelectListItem");
			elseif self.items[row].lore and #self.items[row].lore > 0 then
            	parent.window = SFQuest_QuestWindow:new( 70,  50 , self.items[row]);
				parent.window:initialise()
				parent.window:addToUIManager()
				parent.window:setVisible(true)
				parent.window.pin = true;
				parent.window.resizable = true
				getSoundManager():playUISound("UISelectListItem");
            end
			SF_MissionPanel.instance:triggerUpdate()
end