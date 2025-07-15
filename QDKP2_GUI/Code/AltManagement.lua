-- Copyright 2025 Your Name
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--              Alt Management Window
--

local AltManagement = {}
AltManagement.ENTRIES_PER_PAGE = 15

function AltManagement:Show(mainCharacter)
    self.mainCharacter = mainCharacter
    if not self.mainCharacter then return end

    self.Frame:Show()
    QDKP2_AltManagementFrame_SubHeader:SetText("Assigning alts for: " .. self.mainCharacter)
    self:UpdateCharacterList()
end

function AltManagement:Hide()
    self.Frame:Hide()
    QDKP2_Roster_SearchBox:SetText("")
end

function AltManagement:OnSearchTextChanged()
    self:UpdateCharacterList()
end

function AltManagement:UpdateCharacterList()
    local scrollFrame = QDKP2_AltManagementFrame_ScrollFrame
    local filter = QDKP2_AltManagementFrame_SearchBox:GetText()
    
    if not self.fullCharacterList then
        self.fullCharacterList = {}
        for i = 1, QDKP2_GetNumGuildMembers(true) do
            local name = QDKP2_GetGuildRosterInfo(i)
            table.insert(self.fullCharacterList, name)
        end
    end

    self.displayList = {}
    for _, name in ipairs(self.fullCharacterList) do
        -- A character is eligible to be an alt if:
        -- 1. It's not the main character itself.
        -- 2. It's not already an alt of SOMEONE ELSE.
        -- 3. It passes the search filter (if any).
        if name and name ~= self.mainCharacter and not QDKP2alts[name] then
            if not filter or filter == "" or string.find(string.lower(name), string.lower(filter)) then
                table.insert(self.displayList, name)
            end
        end
    end
    
    table.sort(self.displayList)
    
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    
    for i = 1, self.ENTRIES_PER_PAGE do
        local entry = _G["QDKP2_AltManagementFrame_ListContainer_Entry"..i]
        local charIndex = i + offset
        
        if self.displayList[charIndex] then
            local charName = self.displayList[charIndex]
            local online = QDKP2online[charName]
            entry.characterName = charName
            _G[entry:GetName().."_Name"]:SetText(charName)
            
            local statusText = _G[entry:GetName().."_Status"]
            if online then
                statusText:SetText("|cff00ff00Online|r")
            else
                statusText:SetText("|cff808080Offline|r")
            end
            
            entry:Show()
        else
            entry:Hide()
        end
    end
    
    FauxScrollFrame_Update(scrollFrame, #self.displayList, self.ENTRIES_PER_PAGE, 16)
end

function AltManagement:AssignAlt(altName)
    if self.mainCharacter and altName then
        QDKP2_MakeAlt(altName, self.mainCharacter, true)
        QDKP2_Msg(altName .. " has been assigned as an alt of " .. self.mainCharacter .. ". Remember to |cffff0000Send Changes|r to save.", "INFO")
        self:UpdateCharacterList() -- Refresh the list to remove the newly assigned alt
    end
end

-- Initialize the class object
QDKP2GUI_AltManagement = AltManagement
