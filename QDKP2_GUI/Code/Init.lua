------------------------------------- INIT ----------------------------------
function QDKP2GUI_Init()
  QDKP2_Events:RegisterCallback("TIMERBASE_UPDATED",function(...) QDKP2GUI_Main:TimerCountdownRefresh(...); end)
  QDKP2_Events:RegisterCallback("DATA_UPDATED",QDKP2GUI_UpdateManager)
  QDKP2_Events:RegisterCallback("TIMER_START",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("TIMER_STOP",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("TIMER_PAUSED",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("IRONMAN_START",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("IRONMAN_STOP",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("BOSSBONUS_ON",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("BOSSBONUS_OFF",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("DETECTBID_ON",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("DETECTBID_OFF",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("FIXEDPRICES_ON",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("FIXEDPRICES_OFF",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("BACKUP_SAVED",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("BACKUP_RESTORED",function(...) QDKP2GUI_Main:Refresh(); end)
  QDKP2_Events:RegisterCallback("BID_START",function(...) QDKP2GUI_Roster:Refresh(); end)
  QDKP2_Events:RegisterCallback("BID_CLOSE",function(...) QDKP2GUI_Roster:Refresh(); end)
  QDKP2_Events:RegisterCallback("BID_CANCEL",function(...) QDKP2GUI_Roster:Refresh(); end)
  QDKP2_Events:RegisterCallback("LOAD",QDKP2GUI_OnLoad)
end

------------------------------------- ON LOAD ----------------------------------------
function QDKP2GUI_OnLoad()
  QDKP2_Debug(2,"GUI","Doing OnLoad...")
  --QDKP2_RefreshAll()
  QDKP2_Frame2_Header:SetText("Roster")
  QDKP2_Frame4_Header:SetText("Set Player Amounts")
  --hook to detect shift-click on item link
  QDKP2_Old_ChatEdit_InsertLink = ChatEdit_InsertLink
  ChatEdit_InsertLink = QDKP2_ChatEdit_InsertLink
  QDKP2GUI_AltManagement:OnLoad()
end

-------------------------------- QDKP2 EVENTS MANAGER --------------------------------
function QDKP2GUI_UpdateManager(event,what)
	if what=="all" then QDKP2_RefreshAll()
  elseif what=="log" then QDKP2GUI_Log:Refresh()
  elseif what=="roster" then QDKP2GUI_Roster:Refresh(true) --forces a restory
  end
end


function QDKP2_ChatEdit_InsertLink(...)
  if QDKP2_Frame3:IsVisible() then
    QDKP2frame3_reasonBox:SetText(...)
  elseif QDKP2_Frame2:IsVisible() and QDKP2GUI_Roster.Sel=="bid" then
    QDKP2_Frame2_Bid_Item:SetText(...)
  else
    QDKP2_Old_ChatEdit_InsertLink(...)
  end
end

--RAZ101019_START 
-- Basic LDB support 
local ldb = LibStub("LibDataBroker-1.1") 
local launcher = ldb:NewDataObject( "QDKP", { 
type = "data source", 
text = "QuickDKP Launcher V2", 
icon = "Interface\\Addons\\QDKP2_GUI\\Arts\\LogoSmall.tga", 
OnLeave = Block_OnLeave, 
OnClick = function(self, button) 
if button == "LeftButton" then 
QDKP2_Toggle_Main() 
elseif button == "RightButton" then 
QDKP2GUI_Roster:Toggle() 
end 
end, 
} ) 
--RAZ101019_END 