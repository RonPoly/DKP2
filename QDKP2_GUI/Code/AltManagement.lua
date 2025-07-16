-- Copyright 2025 Your Name
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--              Alt Management Window
--

local AltManagement = {}
AltManagement.ENTRIES_PER_PAGE = 22
AltManagement.listData = {}
AltManagement.entries = {}

function AltManagement:OnLoad()
    self.Frame = QDKP2_AltManagementFrame;

    -- Create the scrollable container
    self.Frame.scrollChild = CreateFrame("Frame", nil, self.Frame.ScrollFrame);
    self.Frame.scrollChild:SetSize(420, 400);
    self.Frame.ScrollFrame:SetScrollChild(self.Frame.scrollChild);

    -- Create and parent the list entries
    local previousEntry;
    for i=1, self.ENTRIES_PER_PAGE do
        local entry = CreateFrame("Frame", nil, self.Frame.scrollChild, "QDKP2_AltManagement_EntryTemplate");
        entry:SetID(i);
        if i == 1 then
            entry:SetPoint("TOPLEFT", 5, -5);
        else
            entry:SetPoint("TOPLEFT", previousEntry, "BOTTOMLEFT", 0, -2);
        end
        previousEntry = entry;
        self.entries[i] = entry;
    end
end

function AltManagement:Show(mainCharacter)
    self.mainCharacter = mainCharacter
    if not self.mainCharacter then return end

    self.Frame:Show()
    QDKP2_AltManagementFrame_SubHeader:SetText("Managing alts for: |cffffd100" .. self.mainCharacter .. "|r")
    QDKP2_AltManagementFrame_SearchBox:SetText("")
    QDKP2_AltManagementFrame_SearchBox:ClearFocus()
    self:BuildAndDisplayList()
end

function AltManagement:Hide()
    if self.Frame then
        self.Frame:Hide()
    end
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
    local scrollFrame = QDKP2_AltManagementFrame_ScrollFrame
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    
    for i = 1, self.ENTRIES_PER_PAGE do
        local entryFrame = self.entries[i]
        if not entryFrame then return end

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
                if data.main then
                    statusLabel:SetText("|cffaaaaaa(Alt of " .. data.main .. ")|r")
                else
                    statusLabel:SetText("|cffff0000(Error: No Main)|r")
                end
                
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
        QDKP2_MakeAlt(status.name, self.mainCharacter, true)
    elseif status.isAlt and status.main == self.mainCharacter then
        QDKP2_ClearAlt(status.name)
    end
    
    self:BuildAndDisplayList()
end

-- Initialize the class object
QDKP2GUI_AltManagement = AltManagement
