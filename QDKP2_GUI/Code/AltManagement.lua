--=============================================================================
-- Alt Management Frame - REVISED
--=============================================================================

local selectedMain = nil
local selectedAlt = nil
local fullGuildRoster = {} -- We will store the full roster here to search against it

-- Create a frame to handle game events
local eventHandler = CreateFrame("Frame")
eventHandler:SetScript("OnEvent", function(self, event, ...)
    if event == "GUILD_ROSTER_UPDATE" then
        -- This is the trigger. When the guild roster is ready, populate our local table.
        wipe(fullGuildRoster)
        local numGuildMembers = GetNumGuildMembers(true)
        for i = 1, numGuildMembers do
            local fullName = GetGuildRosterInfo(i)
            if fullName then
                table.insert(fullGuildRoster, fullName)
            end
        end
        -- Now that our local roster is full, update the display
        QDKP2_AltManagementFrame_UpdateDisplay()
    end
end)

-- When the frame is loaded for the first time
function QDKP2_AltManagementFrame_OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self.Title:SetText("Alt Management")
    self.SubHeader:SetText("Link alts to main characters")
end

-- When the frame is shown
function QDKP2_AltManagementFrame_OnShow(self)
    -- Reset selections
    selectedMain = nil
    selectedAlt = nil
    QDKP2_AltManagementFrame.SelectedMain:SetText("Main: (none)")
    QDKP2_AltManagementFrame.SelectedAlt:SetText("Alt: (none)")

    -- Clear the search box
    QDKP2_AltManagementFrame_SearchBox:SetText("")

    -- Register for the event and request the roster
    eventHandler:RegisterEvent("GUILD_ROSTER_UPDATE")
    GuildRoster()
end

-- When the frame is hidden
function QDKP2_AltManagementFrame_OnHide(self)
    -- Unregister the event to save resources when the window is closed
    eventHandler:UnregisterEvent("GUILD_ROSTER_UPDATE")
end

-- This is our main display update function now. It handles both searching and showing the full list.
function QDKP2_AltManagementFrame_UpdateDisplay()
    local searchText = QDKP2_AltManagementFrame_SearchBox:GetText():lower()
    local resultsToShow = {}

    if searchText and searchText ~= "" then
        -- Search our local, complete roster table
        for _, characterName in ipairs(fullGuildRoster) do
            if characterName:lower():find(searchText, 1, true) then
                table.insert(resultsToShow, characterName)
            end
        end
    else
        -- If search is empty, show the full roster
        resultsToShow = fullGuildRoster
    end

    QDKP2_AltManagementFrame_PopulateList(resultsToShow)
end

-- This function populates the scroll list with the provided results
function QDKP2_AltManagementFrame_PopulateList(characterList)
    local scrollFrame = QDKP2_AltManagementFrame_CharacterListScrollFrame
    FauxScrollFrame_Update(scrollFrame, #characterList, 10, 16)

    for i = 1, 10 do
        local index = i + FauxScrollFrame_GetOffset(scrollFrame)
        local button = _G["QDKP2_AltManagementFrame_CharacterButton" .. i]

        if index <= #characterList then
            local characterName = characterList[index]
            if characterName then
                button:SetText(characterName)
                button:Show()
            else
                button:Hide()
            end
        else
            button:Hide()
        end
    end
end

-- When a character in the list is clicked
function QDKP2_AltManagementFrame_CharacterButton_OnClick(self)
    local characterName = self:GetText()
    if IsShiftKeyDown() then
        selectedMain = characterName
        QDKP2_AltManagementFrame.SelectedMain:SetText("Main: " .. characterName)
    else
        selectedAlt = characterName
        QDKP2_AltManagementFrame.SelectedAlt:SetText("Alt: " .. characterName)
    end
end

-- Link the selected alt to the selected main (with improved logic)
function QDKP2_AltManagementFrame_LinkAlt()
    if not selectedAlt or not selectedMain then
        print("You must select both an alt and a main character. (Hold Shift to select a main)")
        return
    end

    if selectedAlt == selectedMain then
        print("A character cannot be their own alt.")
        return
    end

    if not QDKP2.db.profile.altLinks then
        QDKP2.db.profile.altLinks = {}
    end

    for alt, main in pairs(QDKP2.db.profile.altLinks) do
        if main == selectedAlt then
            print(selectedAlt .. " is already the main for " .. alt .. ". You cannot link them as an alt.")
            return
        end
    end

    if QDKP2.db.profile.altLinks[selectedMain] then
        print(selectedMain .. " is already an alt for " .. QDKP2.db.profile.altLinks[selectedMain] .. ". You cannot use them as a main.")
        return
    end

    if QDKP2.db.profile.altLinks[selectedAlt] then
        print(selectedAlt .. " is already linked to " .. QDKP2.db.profile.altLinks[selectedAlt] .. ". Unlink first.")
        return
    end

    QDKP2.db.profile.altLinks[selectedAlt] = selectedMain
    print("|cff00ff00" .. selectedAlt .. " has been successfully linked to " .. selectedMain .. "!|r")
end
