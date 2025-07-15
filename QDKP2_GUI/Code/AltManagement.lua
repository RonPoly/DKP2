-- Copyright 2025 Your Name
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--              Alt Management Window
--

local AltManagement = {}
AltManagement.ENTRIES_PER_PAGE = 20 -- Increased to match XML
AltManagement.listData = {} -- This will hold the structured list of mains and alts

function AltManagement:Show(mainCharacter)
    self.mainCharacter = mainCharacter
    if not self.mainCharacter then return end

    self.Frame:Show()
    QDKP2_AltManagementFrame_SubHeader:SetText("Managing alts for: |cffffd100" .. self.mainCharacter .. "|r")
    QDKP2_AltManagementFrame_SearchBox:SetText("")
    self:BuildAndDisplayList()
end

function AltManagement:Hide()
    if self.Frame then
        self.Frame:Hide()
    end
end

function AltManagement:OnSearchTextChanged()
    self:BuildAndDisplayList()
end

function AltManagement:BuildAndDisplayList()
    local filter = QDKP2_AltManagementFrame_SearchBox:GetText()
    filter = (filter and filter ~= "") and string.lower(filter) or nil
    
    wipe(self.listData)

    -- Create a temporary structure to hold mains and their alts
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
    
    -- Now build the flat display list from the structured data
    local sortedMains = {}
    for name, data in pairs(mains) do
        table.insert(sortedMains, name)
    end
    table.sort(sortedMains)

    for _, name in ipairs(sortedMains) do
        local data = mains[name]
        local isMainCharacter = (name == self.mainCharacter)
        
        -- Filter logic
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
            -- Add the main character to the list
            table.insert(self.listData, { name = name, indent = 5, isMain = true, isCurrentMain = isMainCharacter })
            
            -- Add their existing alts
            table.sort(data.alts)
            for _, altName in ipairs(data.alts) do
                table.insert(self.listData, { name = altName, indent = 25, isAlt = true, main = name })
            end
        end
    end
    
    self:PopulateVisibleList()
end

function AltManagement:PopulateVisibleList()
    local scrollFrame = QDKP2_AltManagementFrame_ScrollFrame
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    
    for i = 1, self.ENTRIES_PER_PAGE do
        local entryFrame = _G["QDKP2_AltManagementFrame_ListContainer_Entry"..i]
        
        if not entryFrame then 
            -- This check prevents errors if the XML hasn't loaded yet.
            return 
        end

        local dataIndex = i + offset
        local data = self.listData[dataIndex]
        
        if data then
            entryFrame.characterName = data.name
            entryFrame.characterStatus = data
            
            local nameLabel = _G[entryFrame:GetName().."_Name"]
            local statusLabel = _G[entryFrame:GetName().."_Status"]
            local actionButton = _G[entryFrame:GetName().."_ActionButton"]
            
            nameLabel:SetPoint("LEFT", data.indent, 0)
            nameLabel:SetText(data.name)
            
            -- Set colors and status text
            if data.isCurrentMain then
                nameLabel:SetTextColor(1, 0.82, 0)
                statusLabel:SetText("|cffffd100(Current Main)|r")
                actionButton:Hide()
            elseif data.isMain then
                nameLabel:SetTextColor(1, 1, 1)
                statusLabel:SetText("")
                actionButton:SetText("Assign")
                actionButton:Show()
            elseif data.isAlt then
                nameLabel:SetTextColor(0.8, 0.8, 0.8)
                statusLabel:SetText("|cffaaaaaa(Alt of " .. data.main .. ")|r")
                if data.main == self.mainCharacter then
                    actionButton:SetText("Remove")
                    actionButton:Show()
                else
                    actionButton:Hide()
                end
            end
            
            entryFrame:Show()
        else
            entryFrame:Hide()
        end
    end
    
    FauxScrollFrame_Update(scrollFrame, #self.listData, self.ENTRIES_PER_PAGE, 18)
end

function AltManagement:HandleActionClick(entryFrame)
    local status = entryFrame.characterStatus
    if not status then return end

    if status.isMain then
        -- This is another main character, assign them as an alt to our current main
        QDKP2_MakeAlt(status.name, self.mainCharacter, true)
        QDKP2_Msg(status.name .. " has been assigned as an alt of " .. self.mainCharacter .. ". Remember to |cffff0000Send Changes|r to save.", "INFO")
    elseif status.isAlt and status.main == self.mainCharacter then
        -- This is already an alt of our main, remove them
        QDKP2_ClearAlt(status.name)
        QDKP2_Msg(status.name .. " is no longer an alt of " .. self.mainCharacter .. ". Remember to |cffff0000Send Changes|r to save.", "INFO")
    end
    
    -- Rebuild and refresh the entire list to reflect the change
    self:BuildAndDisplayList()
end

-- Initialize the class object
QDKP2GUI_AltManagement = AltManagement
