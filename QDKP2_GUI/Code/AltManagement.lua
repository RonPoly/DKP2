local AltManagement = {}
AltManagement.ENTRIES_PER_PAGE = 22
AltManagement.listData = {}
AltManagement.isInitialized = false
-- Table used to store the current alt->main links. We reference the
-- core table if available so that changes persist through QDKP's
-- normal saved variables.
AltManagement.altLinks = QDKP2altsRestore or {}

-- This function runs once to create all the UI elements we need
function AltManagement:Initialize()
    if self.isInitialized then return end

    local parentFrame = QDKP2_AltManagementFrame
    
    -- Create the Left Panel (Current Alts) UI elements
    self.currentAltEntries = {}
    local leftParent = _G[parentFrame:GetName().."_LeftPanel"]
    local previousLeftEntry
    for i = 1, self.ENTRIES_PER_PAGE do
        local entry = CreateFrame("Frame", nil, leftParent, "QDKP2_AltManagement_CurrentAltTemplate")
        if i == 1 then
            entry:SetPoint("TOPLEFT", 10, -30)
        else
            entry:SetPoint("TOPLEFT", previousLeftEntry, "BOTTOMLEFT", 0, -2)
        end
        previousLeftEntry = entry
        self.currentAltEntries[i] = entry
    end

    -- Create the Right Panel (Available Characters) UI elements
    self.availableCharEntries = {}
    local scrollFrame = _G[parentFrame:GetName().."_RightPanel_ScrollFrame"]
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(220, 380)
    scrollFrame:SetScrollChild(scrollChild)
    self.ScrollFrame = scrollFrame -- Store reference for later
    
    local previousRightEntry
    for i = 1, self.ENTRIES_PER_PAGE do
        local entry = CreateFrame("Frame", nil, scrollChild, "QDKP2_AltManagement_AvailableAltTemplate")
        if i == 1 then
            entry:SetPoint("TOPLEFT", 5, -5)
        else
            entry:SetPoint("TOPLEFT", previousRightEntry, "BOTTOMLEFT", 0, -2)
        end
        previousRightEntry = entry
        self.availableCharEntries[i] = entry
    end
    
    self.isInitialized = true
end

function AltManagement:Show(mainCharacter)
    self:Initialize() -- Create frames if they don't exist yet

    self.mainCharacter = mainCharacter
    if not self.mainCharacter then return end

    -- Make sure our alt link table references the latest data
    if QDKP2altsRestore then
        self.altLinks = QDKP2altsRestore
    end

    QDKP2_AltManagementFrame:Show()
    _G["QDKP2_AltManagementFrame_Header"]:SetText("ALT MANAGEMENT") -- Set title
    _G["QDKP2_AltManagementFrame_SubHeader"]:SetText("Managing alts for: |cffffd100" .. self.mainCharacter .. "|r")
    _G["QDKP2_AltManagementFrame_RightPanel_SearchBox"]:SetText("")
    _G["QDKP2_AltManagementFrame_RightPanel_SearchBox"]:ClearFocus()
    
    self:UpdateAllLists()
end

function AltManagement:Hide()
    QDKP2_AltManagementFrame:Hide()
end

-- Searches the guild roster for characters matching the given name
-- Returns a sorted table of character names
function AltManagement:SearchGuildForCharacter(name)
    local results = {}
    local query = name and name ~= "" and string.lower(name) or nil
    for i = 1, QDKP2_GetNumGuildMembers(true) do
        local fullName = QDKP2_GetGuildRosterInfo(i)
        if fullName and not QDKP2_IsAlt(fullName) and fullName ~= self.mainCharacter then
            if not query or string.find(string.lower(fullName), query, 1, true) then
                table.insert(results, fullName)
            end
        end
    end
    table.sort(results)
    return results
end

function AltManagement:UpdateAllLists()
    self:UpdateCurrentAltsList()
    self:UpdateAvailableCharsList()
end

-- Logic for the LEFT panel
function AltManagement:UpdateCurrentAltsList()
    local displayList = { {name = self.mainCharacter, isMain = true} }
    
    for i = 1, QDKP2_GetNumGuildMembers(true) do
        local name = QDKP2_GetGuildRosterInfo(i)
        if name and QDKP2_GetMain(name) == self.mainCharacter and name ~= self.mainCharacter then
            -- FIX: We were missing `main = self.mainCharacter` here
            table.insert(displayList, {name = name, isAlt = true, main = self.mainCharacter})
        end
    end
    
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
    local filter = _G["QDKP2_AltManagementFrame_RightPanel_SearchBox"]:GetText()
    self.availableChars = self:SearchGuildForCharacter(filter)
    self:PopulateAvailableCharsList()
end

function AltManagement:PopulateAvailableCharsList()
    if not self.isInitialized then return end
    
    local offset = FauxScrollFrame_GetOffset(self.ScrollFrame)

    for i, entryFrame in ipairs(self.availableCharEntries) do
        local name = self.availableChars[i + offset]
        if name then
            local nameLabel = _G[entryFrame:GetName().."_Name"]
            local actionButton = _G[entryFrame:GetName().."_ActionButton"]
            
            nameLabel:SetText(name)
            actionButton:SetText("Assign")
            entryFrame.characterName = name
            entryFrame:Show()
        else
            entryFrame:Hide()
        end
    end
    
    FauxScrollFrame_Update(self.ScrollFrame, #self.availableChars, #self.entries, 18)
end

-- Links an alt to a main character and stores the relation
function AltManagement:LinkAltToMain(altName, mainName)
    if not altName or not mainName then
        QDKP2_Msg("You must select both an alt and a main character.")
        return
    end

    if self.altLinks[altName] then
        QDKP2_Msg(altName .. " is already linked to a main.")
        return
    end

    self.altLinks[altName] = mainName
    -- Use the core function so the change is correctly persisted
    if QDKP2_MakeAlt then
        QDKP2_MakeAlt(altName, mainName, true)
    end
    QDKP2_Msg(altName .. " has been successfully linked to " .. mainName .. "!")
end

function AltManagement:HandleAssignClick(altName)
    if self.mainCharacter and altName then
        self:LinkAltToMain(altName, self.mainCharacter)
        self:UpdateAllLists()
    end
end

function AltManagement:HandleRemoveClick(altName)
    if altName then
        self.altLinks[altName] = nil
        if QDKP2_ClearAlt then
            QDKP2_ClearAlt(altName)
        end
        self:UpdateAllLists()
    end
end

-- Initialize the class object
QDKP2GUI_AltManagement = AltManagement
