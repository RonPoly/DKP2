-- Copyright 2025 Your Name
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--              Alt Management Window
--

local AltManagement = {}

function AltManagement:Show(mainCharacter)
  self.mainCharacter = mainCharacter
  QDKP2_AltManagementFrame:Show()
  self:UpdateCharacterList()
end

function AltManagement:Hide()
  QDKP2_AltManagementFrame:Hide()
end

function AltManagement:UpdateCharacterList(filter)
  local scrollFrame = QDKP2_AltManagementFrame_ScrollFrame
  local characterList = {}

  -- Populate characterList with all characters in the guild
  for i = 1, GetNumGuildMembers(true) do
    local name, _, _, _, _, _, _, _, _, online = QDKP2_GetGuildRosterInfo(i)
    if name and name ~= self.mainCharacter then
      if not filter or string.find(string.lower(name), string.lower(filter)) then
        table.insert(characterList, {name = name, online = online})
      end
    end
  end

  -- Sort the list alphabetically
  table.sort(characterList, function(a, b) return a.name < b.name end)

  -- Clear existing entries
  for i = 1, 20 do
    local entry = _G["QDKP2_AltManagementFrame_Entry"..i]
    entry:Hide()
  end

  -- Populate the list
  for i, char in ipairs(characterList) do
    if i > 20 then break end
    local entry = _G["QDKP2_AltManagementFrame_Entry"..i]
    entry.characterName = char.name
    _G[entry:GetName().."_Name"]:SetText(char.name)
    if char.online then
      _G[entry:GetName().."_Name"]:SetTextColor(1, 1, 1)
    else
      _G[entry:GetName().."_Name"]:SetTextColor(0.5, 0.5, 0.5)
    end
    entry:Show()
  end
end

function AltManagement:OnSearchTextChanged()
  self:UpdateCharacterList(QDKP2_AltManagementFrame_SearchBox:GetText())
end

function AltManagement:AssignAlt(altName)
  if self.mainCharacter and altName then
    QDKP2_MakeAlt(altName, self.mainCharacter, true)
  end
end

QDKP2GUI_AltManagement = AltManagement
