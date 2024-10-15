require "XpSystem/ISUI/SF_MissionLists"
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

	-- print("controllo loop in createchildren: " .. self.title)
	self.richText = ISRichTextPanel:new(25, 40, 305, 120);
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
	

    -- check if quest has killzombies in actionevent
    if self.unlocks and luautils.stringStarts(self.unlocks, "actionevent") then
        local unlocksTable = luautils.split(self.unlocks:gsub(":", ";"), ";")
        if unlocksTable[2] == "killzombies" then
            self.goal = tonumber(unlocksTable[3])
        end
        local player = getPlayer()
        for i,v in ipairs(player:getModData().missionProgress.ActionEvent) do
            local commands = luautils.split(v.commands, ";");
            if luautils.stringStarts(self.guid, commands[2]) then
                self.tempGoal = tonumber(luautils.split(v.condition, ";")[2])
                self.currentKills = player:getZombieKills()
                self.hasZombieCounter = true
                print("tempGoal: " .. self.tempGoal)
                print("currentKills: " .. self.currentKills)
                print("goal: " .. self.goal)
                break
            end
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

            if self.objectives[i].needsitem then
                local needItem
                local newString = self.objectives[i].needsitem
                newString = newString:gsub("Tag.-#", ""):gsub("Predicate.-#", "")

                local needsTable = luautils.split(newString, ";")
                -- print("needsTable item: " .. needsTable[1])
                -- print("needsTable count: " .. needsTable[2])
                if luautils.stringStarts(self.objectives[i].needsitem, "Tag") then
                    local itemsArray = getScriptManager():getItemsTag(needsTable[1])
                    if itemsArray and itemsArray:size() > 0 then
                        -- local random = ZombRand(0, itemsArray:size())
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
                    objectiveData.itemCount = needsTable[2] or "1"
                    local texture = getRealTexture(needItem)
                    if texture then
                        objectiveData.iconTexture = texture
                    end
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
        if luautils.stringStarts(self.needsitem, "Tag") then
            local itemsArray = getScriptManager():getItemsTag(needsTable[1])
            if itemsArray and itemsArray:size() > 0 then
                -- local random = ZombRand(0, itemsArray:size())
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
            local texture = getRealTexture(scriptItem)
            if texture then
                needsItemData.iconTexture = texture
            end
        end
        table.insert(self.preprocessedNeedsItems, needsItemData)
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
                local textWidth = getTextManager():MeasureStringX(UIFont.Normal, rewardData.itemName)
                -- print(textWidth)
                if textWidth > 123 then
                    self:setWidth(self.width+ textWidth-123)
                end
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
end




function SFQuest_QuestWindow:collapse()
    ISCollapsableWindow.collapse(self)
end

function SFQuest_QuestWindow:uncollapse()
    ISCollapsableWindow.uncollapse(self)
end




-- Funzioni helper
local function drawReputationReward(self, reward, textX, rewardHeight)
    self:drawTextureScaledAspect(getTexture("media/textures/Item_PlusRep.png"), textX - 20, rewardHeight, 20, 20, 1, 1, 1, 1)
    self:drawText(reward.text, textX, rewardHeight + 2, 1, 1, 1, 1, self.font)
    return rewardHeight - 20
end

local function drawItemRewards(self, reward, textX, rewardHeight)
    if reward.iconTexture then
        self:drawTextureScaledAspect(reward.iconTexture, textX - 20, rewardHeight, 20, 20, 1, 1, 1, 1)
    end
    local itemName = reward.itemName or reward.itemId
    
    self:drawText(itemName .. "  X " .. reward.itemCount, textX, rewardHeight + 2, 1, 1, 1, 1, UIFont.Normal)
    return rewardHeight - 20
end


local function drawRewards(self, rewards, textX, rewardHeight)
    local hasRewards = false
    for _, reward in ipairs(rewards) do
        if reward.type == "reputation" then
            rewardHeight = drawReputationReward(self, reward, textX, rewardHeight)
        else
            rewardHeight = drawItemRewards(self, reward, textX, rewardHeight)
        end
        hasRewards = true
    end
    return hasRewards, rewardHeight
end


local function drawNeededItems(self, needsItems, status, textX, needsHeight)
    for i = 1, #needsItems do
        local itemId = needsItems[i].itemId
        local itemCount = needsItems[i].itemCount
        local itemName = needsItems[i].itemName or itemId
        local iconTexture = needsItems[i].iconTexture
        if status then
           local objstatus = getText("IGUI_XP_TaskStatus_" .. status)
           itemName = objstatus .. " " .. itemName
        end

        if iconTexture then
            self:drawTextureScaledAspect2(iconTexture, textX - 20, needsHeight, 16, 16, 1, 1, 1, 1)
        end
        self:drawText(itemName .. "  X " .. itemCount, textX + 5, needsHeight + 2, 1, 1, 1, 1, UIFont.Normal) -- TO DO inserire anche qui status quest?
        needsHeight = needsHeight - 20
    end

    return needsHeight
end




local function drawObjectives(self, preprocessedObjectives, objectives, textX, needsHeight)
    for i = 1, #preprocessedObjectives do
        -- print(tostring(preprocessedObjectives[i]))
        if not preprocessedObjectives[i].hidden then
            if not preprocessedObjectives[i].iconTexture then
                preprocessedObjectives[i].iconTexture = getTexture("media/textures/clickevent.png")
            end
            if preprocessedObjectives[i].iconTexture then
                self:drawTextureScaledAspect2(preprocessedObjectives[i].iconTexture, textX-16, needsHeight+ 2, 16, 16, 1, 1, 1, 1)
            end
            local objtext = getText(preprocessedObjectives[i].text)
            local objstatus
            if objectives[i] and objectives[i].needsitem then
                -- luautils.split(objectives[i].needsitem, ";")[2]
                if not preprocessedObjectives[i].itemName or not preprocessedObjectives[i].itemCount then
                    local needsitemTable = luautils.split(objectives[i].needsitem, ";")
                    objtext = (needsitemTable[1] .. " X " .. needsitemTable[2] )
                else
                objtext = (preprocessedObjectives[i].itemName .. " X " .. preprocessedObjectives[i].itemCount )
                end
            end
            local r, g, b = 0.5, 0.5, 0.5
            if not self.greyed then
                r, g, b = 1.0, 1.0, 1.0
            end
            if objectives[i].status then
                objstatus = getText("IGUI_XP_TaskStatus_" .. objectives[i].status)
                objtext = objstatus .. " " .. objtext
                if objectives[i].status == "Failed" then
                    r, g, b = 1.0, 0.25, 0.25
                elseif objectives[i].status == "Delivered" then
                    r, g, b = 0.5, 0.5, 0.5
                end
            end
            self:drawText(objtext, textX + 5, needsHeight+ 2, 1, r, g, b, UIFont.Normal)
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
    local textX = 280
    local rewardHeight = self.height - self.fontHeight - 10
    local needsHeight = self.height - self.fontHeight - 10
    local fixPosX = 20
    local fixPosXImg = 20
    local hasRewards = false
    local hasNeeds = false
    local hasObjs = false
    -- if self.status then
    --     self.title = getText("IGUI_XP_TaskStatus_" .. self.status) .. " " .. self.title
    -- end
    if self.isCollapsed then
        if self.hasZombieCounter then
            if #self.title > 30 then
                self:setTitle(string.sub(self.title, 1, 20) .. "...")
                -- self:setTitle(string.sub(self.title, 1, 20) .. "...")
            end
            local player = getPlayer()
            if player then
                local newCurrentKills = player:getZombieKills()
                if newCurrentKills > self.currentKills then
                    self.currentKills = self.currentKills + (newCurrentKills - self.currentKills)
                    if self.currentKills - (self.tempGoal - self.goal) >= self.goal then
                        self.hasZombieCounter = false
                    else
                        self.hasZombieCounter = true
                    end
                end
            end
            self:drawTextureScaledAspect2(self.zombieTexture, 280, 2, 16, 16, 1, 1, 1, 1)
            self:drawText("Zombie: " .. tostring(self.currentKills - (self.tempGoal - self.goal)) .. "/" .. tostring(self.goal), 300, 3, 1, 1, 1, 1, self.font)
            -- self:drawText(getText("IGUI_Objectives"), 30, 25, 1, 1, 1, 1, UIFont.Medium)
        end
        return
    else 
        self:setTitle(self.originalTitle)
    end
    

    self.richText:setX(10 + self.picTexture:getWidth())
    self.richText:setY(40)
    self.richText:setVisible(true)
    self.richText:paginate()
    self:drawText(self.npcname, 12, 25, 1, 1, 1, 1, UIFont.Medium)

    if self.picTexture then
    self:drawTexture(self.picTexture, 12, 50, 1, 1, 1, 1);
    self:drawRectBorder(12, 50, self.picTexture:getWidth(), self.picTexture:getHeight(), 0.5, 1, 1, 1);
    end


    if self.preprocessedRewards and #self.preprocessedRewards > 0 then
        hasRewards, rewardHeight = drawRewards(self, self.preprocessedRewards, textX-10, rewardHeight)
        if hasRewards then
            self:drawText(getText("IGUI_Rewards"), textX-10 , rewardHeight -5, 1, 1, 1, 1, UIFont.Medium)
        end
    end
    -- Disegna le ricompense di `rewardTask`
    -- if self.awardstask and not (self.awardsrep or self.awardsitem) then
    --     local rewardTask = SF_MissionPanel:getQuest(self.awardstask)
    --     if rewardTask.awardsrep or rewardTask.awardsitem then
    --         hasRewards, rewardHeight = drawRewards(self, rewardTask.awardsrep, rewardTask.awardsitem, textX-10, rewardHeight)
    --     end
    -- end


    -- Disegna gli oggetti necessari
    if self.preprocessedNeedsItems and #self.preprocessedNeedsItems > 0 then
        if self.awardsitem or self.awardsrep then
            needsHeight = rewardHeight + 20
        end
        needsHeight = drawNeededItems(self, self.preprocessedNeedsItems, self.status, fixPosX+5, needsHeight)
        hasNeeds = true
    end
    if hasNeeds then
        self:drawText(getText("IGUI_Objectives"), fixPosX + 10, needsHeight -5, 1, 1, 1, 1, UIFont.Medium)
    end


    if self.hasZombieCounter then
        local player = getPlayer()
        if player then
            local newCurrentKills = player:getZombieKills()
            if newCurrentKills > self.currentKills then
                self.currentKills = self.currentKills + (newCurrentKills - self.currentKills)
                if self.currentKills - (self.tempGoal - self.goal) >= self.goal then
                    self.hasZombieCounter = false
                else
                    self.hasZombieCounter = true
                end
            end
        end

        if not self.objectives then
            self:drawText(getText("IGUI_Objectives"),  fixPosX+10, needsHeight -20, 1, 1, 1, 1, UIFont.Medium)
            self:drawTextureScaledAspect2(self.zombieTexture, fixPosX - 10, needsHeight+2, 16, 16, 1, 1, 1, 1)
            self:drawText("Zombie: " .. tostring(self.currentKills - (self.tempGoal - self.goal)) .. "/" .. tostring(self.goal),  fixPosX+10, needsHeight + 4, 1, 1, 1, 1, self.font)
        end
    end

    -- Disegna gli obiettivi
    if self.preprocessedObjectives and #self.preprocessedObjectives > 0 then
        hasObjs = true
        if self.awardsitem or self.awardsrep then
            needsHeight = rewardHeight + 20
        end
        
        needsHeight = drawObjectives(self, self.preprocessedObjectives, self.objectives, fixPosX+5, needsHeight)
        if self.hasZombieCounter then
            self:drawTextureScaledAspect2(self.zombieTexture, fixPosX - 10, needsHeight+2, 16, 16, 1, 1, 1, 1)
            self:drawText("Zombie: " .. tostring(self.currentKills - (self.tempGoal - self.goal)) .. "/" .. tostring(self.goal), fixPosX+10, needsHeight + 4, 1, 1, 1, 1, self.font)
            needsHeight = needsHeight - 20
        end
        if hasObjs then
            self:drawText(getText("IGUI_Objectives"), fixPosX + 10, needsHeight -5, 1, 1, 1, 1, UIFont.Medium)
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
	if item.status then
		o.title = getText("IGUI_XP_TaskStatus_" .. item.status) .. getText(item.text);
	end
	o.titleFont = UIFont.Medium
	o.titleFontHgt = getTextManager():getFontHeight(o.titleFont)
	o.npcname = getText(item.title)
	
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
			SF_MissionPanel.instance:triggerUpdate();	

end