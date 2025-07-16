local AltManagement = {}
AltManagement.ENTRIES_PER_PAGE = 22
AltManagement.listData = {}
AltManagement.isInitialized = false -- We'll use this to build the UI only once

-- This function creates all the necessary frames programmatically
function AltManagement:CreateFrames()
    if self.isInitialized then return end

    local parentFrame = QDKP2_AltManagementFrame
    
    -- Create the ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "$parent_ScrollFrame", parentFrame, "FauxScrollFrameTemplate")
    scrollFrame:SetSize(420, 400)
    scrollFrame:SetPoint("TOP", QDKP2_AltManagementFrame_SearchBox, "BOTTOM", 0, -10)
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, 18, QDKP2GUI_AltManagement.PopulateVisibleList)
    end)
    self.ScrollFrame = scrollFrame

    -- Create the scrollable container
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(420, 400)
    scrollFrame:SetScrollChild(scrollChild)

    -- Create and parent the list entries
    self.entries = {}
    local previousEntry
    for i=1, self.ENTRIES_PER_PAGE do
        local entry = CreateFrame("Frame", nil, scrollChild)
        entry:SetSize(400, 18)
        entry:SetID(i)

        local name = entry:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        name:SetPoint("LEFT", 5, 0)
        entry.Name = name

        local status = entry:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        status:SetPoint("RIGHT", -80, 0)
        entry.Status = status

        local button = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
        button:SetSize(70, 16)
        button:SetPoint("RIGHT", -5, 0)
        button:SetScript("OnClick", function() self:HandleActionClick(entry) end)
        entry.ActionButton = button
        
        local hl = entry:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(true)
        hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        hl:SetBlendMode("ADD")
        
        if i == 1 then
            entry:SetPoint("TOPLEFT", 5, -5)
        else
            entry:SetPoint("TOPLEFT", previousEntry, "BOTTOMLEFT", 0, -2)
        end
        previousEntry = entry
        self.entries[i] = entry
    end
    
    self.isInitialized = true
end

function AltManagement:Show(mainCharacter)
    self:CreateFrames() -- Create frames if they don't exist
    
    self.mainCharacter = mainCharacter
    if not self.mainCharacter then return end

    QDKP2_AltManagementFrame:Show()
    QDKP2_AltManagementFrame_SubHeader:SetText("Managing alts for: |cffffd100" .. self.mainCharacter .. "|r")
    QDKP2_AltManagementFrame_SearchBox:SetText("")
    QDKP2_AltManagementFrame_SearchBox:ClearFocus()
    self:BuildAndDisplayList()
end

function AltManagement:Hide()
    QDKP2_AltManagementFrame:Hide()
end

function AltManagement:BuildAndDisplayList()
    local filter = QDKP2_AltManagementFrame_SearchBox:GetText()
    filter = (filter and filter ~= "") and string.lower(filter) or nil
    
    wipe(self.listData)

    local mains = {}
    for i = 1, QDKP2_GetNumGuildMembers(true) do
        local name = QDKP2_GetGuildRosterInfo(i)
        if name then
            local mainName = QDKP2_GetMain(name)
            if not mains[mainName] then
                mains[mainName] = { alts = {} }
            end
            if mainName ~= name then
                table.insert(mains[mainName].alts, name)
            end
        end
    end
    
    local sortedMains = {}
    for name in pairs(mains) do
        table.insert(sortedMains, name)
    end
    table.sort(sortedMains)

    for _, name in ipairs(sortedMains) do
        local data = mains[name]
        local isMainCharacter = (name == self.mainCharacter)
        
        local mainMatches = filter and string.find(string.lower(name), filter)
        local altMatches = false
        if filter then
            for _, altName in ipairs(data.alts) do
                if string.find(string.lower(altName), filter) then
                    altMatches = true
                    break
                end
            end
        end
        
        if not filter or mainMatches or altMatches then
            table.insert(self.listData, { name = name, indent = 5, isMain = true, isCurrentMain = isMainCharacter })
            table.sort(data.alts)
            for _, altName in ipairs(data.alts) do
                table.insert(self.listData, { name = altName, indent = 25, isAlt = true, main = name })
            end
        end
    end
    
    self:PopulateVisibleList()
end

function AltManagement:PopulateVisibleList()
    if not self.isInitialized then return end

    local offset = FauxScrollFrame_GetOffset(self.ScrollFrame)
    
    for i = 1, self.ENTRIES_PER_PAGE do
        local entryFrame = self.entries[i]
        local data = self.listData[i + offset]
        
        if data then
            entryFrame.characterStatus = data
            entryFrame.Name:SetPoint("LEFT", data.indent, 0)
            entryFrame.Name:SetText(data.name)
            
            if data.isCurrentMain then
                entryFrame.Name:SetTextColor(1, 0.82, 0)
                entryFrame.Status:SetText("|cffffd100(Current Main)|r")
                entryFrame.ActionButton:Hide()
            elseif data.isMain then
                entryFrame.Name:SetTextColor(1, 1, 1)
                entryFrame.Status:SetText("")
                entryFrame.ActionButton:SetText("Assign")
                entryFrame.ActionButton:Show()
            elseif data.isAlt then
                entryFrame.Name:SetTextColor(0.8, 0.8, 0.8)
                if data.main then
                    entryFrame.Status:SetText("|cffaaaaaa(Alt of " .. data.main .. ")|r")
                else
                    entryFrame.Status:SetText("|cffff0000(Error: No Main)|r")
                end
                
                if data.main == self.mainCharacter then
                    entryFrame.ActionButton:SetText("Remove")
                    entryFrame.ActionButton:Show()
                else
                    entryFrame.ActionButton:Hide()
                end
            end
            entryFrame:Show()
        else
            entryFrame:Hide()
        end
    end
    
    FauxScrollFrame_Update(self.ScrollFrame, #self.listData, self.ENTRIES_PER_PAGE, 18)
end

function AltManagement:HandleActionClick(entryFrame)
    local status = entryFrame.characterStatus
    if not status then return end

    if status.isMain then
        QDKP2_MakeAlt(status.name, self.mainCharacter, true)
    elseif status.isAlt and status.main == self.mainCharacter then
        QDKP2_ClearAlt(status.name)
    end
    
    self:BuildAndDisplayList()
end

-- Initialize the class object
QDKP2GUI_AltManagement = AltManagement
