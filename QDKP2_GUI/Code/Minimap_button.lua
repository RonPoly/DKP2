function QDKP2GUI_MiniBtn_Click(self, ...)
    QDKP2_Toggle_Main()
  end

  function QDKP2GUI_MiniBtn_LabelOn(self,...)
    if not QDKP2_ACTIVE then return; end
    if self.Dragging then return; end
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
    GameTooltip:AddLine("Quick DKP "..tostring(QDKP2_VERSION))
    if QDKP2_OfficerMode() then
      GameTooltip:AddLine("Officer mode",0.3,1,0.3)
    else
      GameTooltip:AddLine("Read-only mode",1,1,1)
    end
    local M1,M2,M3 = QDKP2_GetPermissions()
    GameTooltip:AddLine("DKP officer rights:")
    GameTooltip:AddLine(M1)     --officer notes
    GameTooltip:AddLine(M2)     --guild notes
    --GameTooltip:AddLine(M3)   --The RSA key is not used for now.
    GameTooltip:AddLine("LEFT CLICK: Show/Hide QDKP",.8,.8,.8,1)
    GameTooltip:AddLine("SHIFT+CLICK: Drag self button",.8,.8,.8,1)
	GameTooltip:AddLine("RIGHT CLICK: Open Quick DKP Options GUI",.8,.8,.8,1)
    GameTooltip:Show()
  end

  function QDKP2GUI_MiniBtn_LabelOff(self,...)
    GameTooltip:Hide()
  end

  function QDKP2GUI_MiniBtn_DragOn(self,...)
  if IsShiftKeyDown()then
    self.Dragging = true;
    QDKP2GUI_MiniBtn_LabelOff();
  end
  end

  function QDKP2GUI_MiniBtn_DragOff(self,...)
    self:StopMovingOrSizing();
    self.Dragging = nil;
    self.Moving = nil;
  end

  function QDKP2GUI_MiniBtn_Press(self, ...)
    QDKP2GUI_MiniBtnIcon:SetTexCoord(-0.05,0.95,-0.05,0.95)
  end

  function QDKP2GUI_MiniBtn_Release(self, ...)
    QDKP2GUI_MiniBtnIcon:SetTexCoord(0,1,0,1)
  end

 function QDKP2GUI_MiniBtn_Update(self,...)
  if not self.Dragging then return; end
  local MapScale = Minimap:GetEffectiveScale();
  local CX, CY = GetCursorPosition();
  local X, Y = (Minimap:GetRight() - 70) * MapScale, (Minimap:GetTop() - 70) * MapScale;
  local Dist = sqrt(math.pow(X - CX, 2) + math.pow(Y - CY, 2)) / MapScale;
  local Scale = self:GetEffectiveScale();
  if(Dist <= 90)then
    if self.Moving then
      self:StopMovingOrSizing();
      self.Moving = nil;
    end
    local Angle = atan2(CY - Y, X - CX) - 90;
    self:ClearAllPoints();
    self:SetPoint("CENTER", Minimap, "TOPRIGHT", (sin(Angle) * 80 - 70) * MapScale / Scale, (cos(Angle) * 77 - 73) * MapScale / Scale);

  elseif not self.Moving then
    self:ClearAllPoints();
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT",CX / Scale, CY / Scale);
    self:StartMoving();
    self.Moving = true;
  end
end
