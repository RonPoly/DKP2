local AltManagement = {}
AltManagement.isInitialized = false

-- This function runs once to create all the UI elements we need
function AltManagement:Initialize()
    if self.isInitialized then return end

    -- Left Panel (Current Alts)
    self.currentAltEntries = {}
    local leftParent = QDKP2_AltManagementFrame_LeftPanel
    for i = 1, 22 do
        local entry = CreateFrame("Frame", nil, leftParent, "QDKP2_AltManagement_CurrentAltTemplate")
        if i == 1 then
            entry:SetPoint("TOPLEFT", 10, -30)
        else
            entry:SetPoint("TOPLEFT", self.currentAltEntries[i-1], "BOTTOMLEFT", 0, -2)
        end
        self.currentAltEntries[i] = entry
    end

    -- Right Panel (Available Characters)
    self.availableCharEntries = {}
    local scrollFrame = QDKP2_AltManagementFrame_RightPanel_ScrollFrame
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(220, 380)
    scrollFrame:SetScrollChild(scrollChild)
    
    local previousEntry
    for i = 1, 20 do
        local entry = CreateFrame("Frame", nil, scrollChild, "QDKP2_AltManagement_AvailableAltTemplate")
        if i == 1 then
            entry:SetPoint("TOPLEFT", 5, -5)
        else
            entry:SetPoint("TOPLEFT", previousEntry, "BOTTOMLEFT", 0, -2)
        end
        previousEntry = entry
        self.availableCharEntries[i] = entry
    end
    
    self.isInitialized = true
end

function AltManagement:Show(mainCharacter)
    self:Initialize() -- Create frames if they don't exist yet
    
    self.mainCharacter = mainCharacter
    if not self.mainCharacter then return end

    QDKP2_AltManagementFrame:Show()
    QDKP2_AltManagementFrame_RightPanel_SearchBox:SetText("")
    QDKP2_AltManagementFrame_RightPanel_SearchBox:ClearFocus()
    
    self:UpdateAllLists()
end

function AltManagement:Hide()
    QDKP2_AltManagementFrame:Hide()
end

function AltManagement:UpdateAllLists()
    self:UpdateCurrentAltsList()
    self:UpdateAvailableCharsList()
end

-- Logic for the LEFT panel
function AltManagement:UpdateCurrentAltsList()
    -- Add the main character at the top
    local displayList = { {name = self.mainCharacter, isMain = true} }
    
    -- Find all alts for the current main
    for i = 1, QDKP2_GetNumGuildMembers(true) do
        local name = QDKP2_GetGuildRosterInfo(i)
        if name and QDKP2_GetMain(name) == self.mainCharacter and name ~= self.mainCharacter then
            table.insert(displayList, {name = name, isAlt = true})
        end
    end
    
    -- Populate the UI
    for i, entry in ipairs(self.currentAltEntries) do
        local data = displayList[i]
        if data then
            local nameLabel = _G[entry:GetName().."_Name"]
            local actionButton = _G[entry:GetName().."_ActionButton"]

            nameLabel:SetText(data.name)
            nameLabel:SetPoint("LEFT", data.isAlt and 20 or 5, 0)
            
            if data.isMain then
                nameLabel:SetTextColor(1, 0.82, 0)
                actionButton:Hide()
            else -- isAlt
                nameLabel:SetTextColor(0.8, 0.8, 0.8)
                actionButton:SetText("Remove")
                entry.characterName = data.name
                actionButton:Show()
            end
            entry:Show()
        else
            entry:Hide()
        end
    end
end

-- Logic for the RIGHT panel
function AltManagement:UpdateAvailableCharsList()
    local filter = QDKP2_AltManagementFrame_RightPanel_SearchBox:GetText()
    filter = (filter and filter ~= "") and string.lower(filter) or nil
    
    self.availableChars = {}
    for i = 1, QDKP2_GetNumGuildMembers(true) do
        local name = QDKP2_GetGuildRosterInfo(i)
        if name and not QDKP2_IsAlt(name) and name ~= self.mainCharacter then
            if not filter or string.find(string.lower(name), filter) then
                table.insert(self.availableChars, name)
            end
        end
    end
    table.sort(self.availableChars)
    self:PopulateAvailableCharsList()
end

function AltManagement:PopulateAvailableCharsList()
    local scrollFrame = QDKP2_AltManagementFrame_RightPanel_ScrollFrame
    local offset = FauxScrollFrame_GetOffset(scrollFrame)

    for i, entry in ipairs(self.availableCharEntries) do
        local name = self.availableChars[i + offset]
        if name then
            local nameLabel = _G[entry:GetName().."_Name"]
            local actionButton = _G[entry:GetName().."_ActionButton"]
            
            nameLabel:SetText(name)
            actionButton:SetText("Assign")
            entry.characterName = name
            entry:Show()
        else
            entry:Hide()
        end
    end
    
    FauxScrollFrame_Update(scrollFrame, #self.availableChars, self.ENTRIES_PER_PAGE, 18)
end

function AltManagement:HandleAssignClick(altName)
    if self.mainCharacter and altName then
        QDKP2_MakeAlt(altName, self.mainCharacter, true)
        self:UpdateAllLists()
    end
end

function AltManagement:HandleRemoveClick(altName)
    if altName then
        QDKP2_ClearAlt(altName)
        self:UpdateAllLists()
    end
end

-- Initialize the class object
QDKP2GUI_AltManagement = AltManagement
