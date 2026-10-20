local _G = _G or getfenv(0)

local resizes = {
  MainMenuBar, MainMenuExpBar, MainMenuBarMaxLevelBar,
  ReputationWatchBar, ReputationWatchStatusBar,
}

local frames = {
  BonusActionBarTexture0, BonusActionBarTexture1,
  ShapeshiftBarLeft, ShapeshiftBarMiddle, ShapeshiftBarRight,
  MainMenuMaxLevelBar2, MainMenuMaxLevelBar3,
}

local textures = {
  MainMenuBarTexture0, MainMenuBarTexture1,
  MainMenuXPBarTexture2, MainMenuXPBarTexture3,
  ReputationWatchBarTexture2, ReputationWatchBarTexture3,
  ReputationXPBarTexture2, ReputationXPBarTexture3,
  SlidingActionBarTexture0, SlidingActionBarTexture1,
}

local normtextures = {
  ShapeshiftButton1, ShapeshiftButton2,
  ShapeshiftButton3, ShapeshiftButton4,
  ShapeshiftButton5, ShapeshiftButton6,
}

-- general function to hide textures and frames
local function hide(frame, texture)
  if not frame then return end

  if texture and texture == 1 and frame.SetTexture then
    frame:SetTexture("")
  elseif texture and texture == 2 and frame.SetNormalTexture then
    frame:SetNormalTexture("")
  else
    frame:ClearAllPoints()
    frame.Show = function() return end
    frame:Hide()
  end
end

-- reduce actionbar size
for id, frame in pairs(resizes) do frame:SetWidth(488) end

  -- hide reduced frames
for id, frame in pairs(frames) do hide(frame) end

-- clear reduced textures
for id, frame in pairs(textures) do hide(frame, 1) end

-- clear some button textures
for id, frame in pairs(normtextures) do hide(frame, 2) end

-- create a jump button
ActionButtonJmp = CreateFrame("CheckButton", "ActionButtonJmp", MainMenuBarArtFrame, "ActionButtonTemplate")

local ui = CreateFrame("Frame", "ShaguControllerUI", UIParent)
ui:RegisterEvent("PLAYER_ENTERING_WORLD")
ui:SetScript("OnEvent", function()
  -- the modifier layers (LT, RT, LT+RT) are served by the
  -- bottom left, bottom right and right multi action bars
  SHOW_MULTI_ACTIONBAR_1 = 1
  SHOW_MULTI_ACTIONBAR_2 = 1
  SHOW_MULTI_ACTIONBAR_3 = 1
  MultiActionBar_Update()

  -- update ui when frame positions get managed
  ui.manage_positions_hook = UIParent_ManageFramePositions
  UIParent_ManageFramePositions = ui.manage_positions
  ui:UnregisterAllEvents()
end)

ui:SetScript("OnUpdate", function()
  -- update ui once the first frame is shown
  UIParent_ManageFramePositions()
  this:Hide()
end)

local img = "Interface\\AddOns\\ShaguController\\img\\"

-- Each layer represents one modifier state of the gamepad and holds 8 buttons,
-- 4 on the D-pad (left screen side) and 4 face buttons (right screen side).
-- Both lists are ordered by position: up, right, down, left.
--
-- Like the WoW Forever gamepad UI, the layers are arranged around each other:
-- no modifier on top, LT to the left, RT to the right and LT+RT at the bottom.
local layers = {
  { -- no modifier
    label = nil, x = 0, y = 2,

    -- This is my personal preference where the last 3 buttons of an actionbar
    -- are usually mapped and mandatory skills for me. If you want to continue
    -- the line, change this to 7,8,9 and change the disabled ones to 10,11,12.
    -- also make sure to update the keybinds.lua accordingly.
    dpad = { 5, 10, 11, 12 },
    face = { 1, 3, ActionButtonJmp, 2 },
  },

  { -- left trigger
    label = "LT", x = -3, y = 0,
    dpad = { MultiBarBottomLeftButton1, MultiBarBottomLeftButton2, MultiBarBottomLeftButton3, MultiBarBottomLeftButton4 },
    face = { MultiBarBottomLeftButton5, MultiBarBottomLeftButton6, MultiBarBottomLeftButton7, MultiBarBottomLeftButton8 },
  },

  { -- right trigger
    label = "RT", x = 3, y = 0,
    dpad = { MultiBarBottomRightButton1, MultiBarBottomRightButton2, MultiBarBottomRightButton3, MultiBarBottomRightButton4 },
    face = { MultiBarBottomRightButton5, MultiBarBottomRightButton6, MultiBarBottomRightButton7, MultiBarBottomRightButton8 },
  },

  { -- left and right trigger
    label = "LT+RT", x = 0, y = -2,
    dpad = { MultiBarRightButton1, MultiBarRightButton2, MultiBarRightButton3, MultiBarRightButton4 },
    face = { MultiBarRightButton5, MultiBarRightButton6, MultiBarRightButton7, MultiBarRightButton8 },
  },
}

-- button offsets within a cluster and their gamepad icons
local positions = {
  { x =  0, y =  1, dpad = img .. "up",    face = img .. "y" },
  { x =  1, y =  0, dpad = img .. "right", face = img .. "b" },
  { x =  0, y = -1, dpad = img .. "down",  face = img .. "a" },
  { x = -1, y =  0, dpad = img .. "left",  face = img .. "x" },
}

-- buttons without a gamepad binding
local disabled = {
  4, 6, 7, 8, 9,
  MultiBarBottomLeftButton9, MultiBarBottomLeftButton10, MultiBarBottomLeftButton11, MultiBarBottomLeftButton12,
  MultiBarBottomRightButton9, MultiBarBottomRightButton10, MultiBarBottomRightButton11, MultiBarBottomRightButton12,
  MultiBarRightButton9, MultiBarRightButton10, MultiBarRightButton11, MultiBarRightButton12,
}

-- the alpha of each layer, inactive layers fade out while a modifier is held
ui.layer_alpha = { 1, 1, 1, 1 }

ui.update_alpha = function(self, button)
  local visible = button.shagu_visible or 1
  local layer = self.layer_alpha[button.shagu_layer or 1]
  button:SetAlpha(visible * layer)
end

local actionhide = CreateFrame("Frame", "ShaguControllerActionHide", BonusActionBarFrame)
actionhide.buttons = {}

actionhide:SetScript("OnShow", function()
  for button, bonus in pairs(this.buttons) do
    if button:GetID() ~= 0 then
      button:EnableMouse(bonus)
      button.shagu_visible = bonus
      ui:update_alpha(button)
    end
  end
end)

actionhide:SetScript("OnHide", function()
  for button, bonus in pairs(this.buttons) do
    if button:GetID() ~= 0 then
      button:EnableMouse(bonus == 0 and 1 or 0)
      button.shagu_visible = bonus == 0 and 1 or 0
      ui:update_alpha(button)
    end
  end
end)

-- show the gamepad icon in the middle of empty action slots
ui.update_empty = function(self, frame)
  if not frame.keybind_icon then return end

  if frame:GetID() == 0 or HasAction(ActionButton_GetPagedID(frame)) then
    frame.keybind_icon.empty:Hide()
  else
    frame.keybind_icon.empty:Show()
  end
end

local update_hook = ActionButton_Update
ActionButton_Update = function(a1, a2, a3)
  update_hook(a1, a2, a3)
  if this and this.keybind_icon then ui:update_empty(this) end
end

ui.disable_button = function(self, frame)
  if frame and tonumber(frame) then
    self:disable_button(_G["ActionButton" .. frame])
    self:disable_button(_G["BonusActionButton" .. frame])
    return
  end

  frame.Show = function() return end
  frame:ClearAllPoints()
  frame:Hide()
end

ui.manage_button = function(self, frame, layer, side, x, y, scale, image, bonus)
  if frame and tonumber(frame) then
    self:manage_button(_G["ActionButton" .. frame], layer, side, x, y, scale, image, false)
    self:manage_button(_G["BonusActionButton" .. frame], layer, side, x, y, scale, image, true)
    return
  end

  -- add main and bonus bar buttons to actionhide registry
  if bonus ~= nil then
    actionhide.buttons[frame] = bonus and 1 or 0
  end

  -- keep empty multi bar slots visible
  if not frame.shagu_grid and string.find(frame:GetName(), "^MultiBar") then
    ActionButton_ShowGrid(frame)
    frame.shagu_grid = true
  end

  -- set button scale and set position
  frame.shagu_layer = layer
  frame:SetScale(scale)
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, side, x/scale, y/scale)
  self:update_alpha(frame)

  -- hide keybind text
  _G[frame:GetName().."HotKey"]:Hide()

  -- add keybind icon
  if not frame.keybind_icon then
    frame.keybind_icon = CreateFrame("Frame", nil, frame)
    frame.keybind_icon:SetFrameLevel(255)
    frame.keybind_icon:SetAllPoints(frame)

    frame.keybind_icon.tex = frame.keybind_icon:CreateTexture(nil, "OVERLAY")
    frame.keybind_icon.tex:SetTexture(image)
    frame.keybind_icon.tex:SetPoint("TOPRIGHT", frame.keybind_icon, "TOPRIGHT", 0, 0)
    frame.keybind_icon.tex:SetWidth(16)
    frame.keybind_icon.tex:SetHeight(16)

    -- large gamepad icon for empty slots
    frame.keybind_icon.empty = frame.keybind_icon:CreateTexture(nil, "OVERLAY")
    frame.keybind_icon.empty:SetTexture(image)
    frame.keybind_icon.empty:SetPoint("CENTER", frame.keybind_icon, "CENTER", 0, 0)
    frame.keybind_icon.empty:SetWidth(24)
    frame.keybind_icon.empty:SetHeight(24)
    frame.keybind_icon.empty:SetAlpha(.6)

    -- handle out of range as desaturation of keybind and icon
    _G[frame:GetName().."HotKey"].SetVertexColor = function(self, r, g, b, a)
      if r == 1.0 and g == 0.1 and b == 0.1 then
        _G[frame:GetName().."Icon"]:SetDesaturated(true)
        frame.keybind_icon.tex:SetDesaturated(true)
        frame.keybind_icon.empty:SetDesaturated(true)
      else
        _G[frame:GetName().."Icon"]:SetDesaturated(false)
        frame.keybind_icon.tex:SetDesaturated(false)
        frame.keybind_icon.empty:SetDesaturated(false)
      end
    end
  end

  self:update_empty(frame)
end

ui.manage_jump_button = function(self, frame)
  local icon = _G[frame:GetName().."Icon"]
  local name = _G[frame:GetName().."Name"]

  icon:Show()
  icon:SetTexture("Interface\\Icons\\inv_gizmo_rocketboot_01")
  icon.SetTexture = function() return end
  icon.Hide = function() return end

  name:SetPoint("BOTTOM", 0, 5)
  name:SetText("Jump")
  name.SetText = function() return end

  frame:Show()
  frame.Hide = function() return end
  frame.GetID = function() return 0 end
end

-- modifier labels in the center of each cluster
ui.labels = {}
ui.manage_label = function(self, id, side, text, x, y, scale)
  local key = id .. side
  if not self.labels[key] then
    self.labels[key] = CreateFrame("Frame", nil, UIParent)
    self.labels[key]:SetWidth(36)
    self.labels[key]:SetHeight(36)
    self.labels[key].text = self.labels[key]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.labels[key].text:SetAllPoints(self.labels[key])
    self.labels[key].text:SetText(text)
    self.labels[key].layer = id
  end

  local label = self.labels[key]
  label:SetScale(scale)
  label:ClearAllPoints()
  label:SetPoint("CENTER", UIParent, side, x/scale, y/scale)
end

-- highlight the layer of the currently held modifiers
local layerhighlight = CreateFrame("Frame", "ShaguControllerLayerHighlight", UIParent)
layerhighlight:SetScript("OnUpdate", function()
  local shift, ctrl = IsShiftKeyDown(), IsControlKeyDown()
  local active = shift and ctrl and 4 or ctrl and 3 or shift and 2 or 1
  if this.active == active then return end
  this.active = active

  for id in pairs(layers) do
    ui.layer_alpha[id] = (active == 1 or active == id) and 1 or .35
  end

  for id, data in pairs(layers) do
    for _, list in pairs({ data.dpad, data.face }) do
      for _, button in pairs(list) do
        if tonumber(button) then
          ui:update_alpha(_G["ActionButton" .. button])
          ui:update_alpha(_G["BonusActionButton" .. button])
        else
          ui:update_alpha(button)
        end
      end
    end
  end

  for _, label in pairs(ui.labels) do
    if label.layer == active then
      label.text:SetTextColor(1, .82, 0)
    else
      label.text:SetTextColor(.6, .6, .6)
    end
  end
end)

ui.manage_layout = function(self)
  -- scale clusters down to fit between the screen edge and the chat
  local cell, margin = 40, 10
  local space = (UIParent:GetWidth() - MainMenuBar:GetWidth()) / 2 - margin * 2
  local scale = math.min(1, space / (cell * 9))
  local size = cell * scale

  -- center of the cluster groups on each screen side
  local cx, cy = margin + size * 4.5, margin + size * 3.5

  for id, data in pairs(layers) do
    local lx, ly = data.x * size, data.y * size

    for pos, offset in pairs(positions) do
      local x, y = lx + offset.x * size, cy + ly + offset.y * size
      self:manage_button(data.dpad[pos], id, "BOTTOMLEFT", cx + x, y, scale, offset.dpad)
      self:manage_button(data.face[pos], id, "BOTTOMRIGHT", x - cx, y, scale, offset.face)
    end

    if data.label then
      self:manage_label(id, "BOTTOMLEFT", data.label, cx + lx, cy + ly, scale)
      self:manage_label(id, "BOTTOMRIGHT", data.label, lx - cx, cy + ly, scale)
    end
  end

  for _, button in pairs(disabled) do
    self:disable_button(button)
  end

  -- refresh label colors
  layerhighlight.active = nil
end

ui.manage_positions = function(a1, a2, a3)
  -- run original function first
  ui.manage_positions_hook(a1, a2, a3)

  -- move and skin all buttons
  ui:manage_layout()

  -- skin jump button
  ui:manage_jump_button(ActionButtonJmp)

  -- move and resize chat
  ChatFrameEditBox:ClearAllPoints()
  ChatFrameEditBox:SetPoint("TOP", UIParent, "TOP", 0, -10)
  ChatFrameEditBox:SetWidth(300)
  ChatFrameEditBox:SetScale(2)

  -- on-screen keyboard helper
  ChatFrame1.oskHelper = ChatFrame1.oskHelper or CreateFrame("Button", nil, UIParent)
  ChatFrame1.oskHelper:SetFrameStrata("BACKGROUND")
  ChatFrame1.oskHelper:SetAllPoints(ChatFrame1)
  ChatFrame1.oskHelper:SetScript("OnClick", function()
    if not ChatFrameEditBox:IsVisible() then
      ChatFrameEditBox:Show()
      ChatFrameEditBox:Raise()
    else
      ChatFrameEditBox:Hide()
    end
  end)

  ChatFrame1.oskHelper:SetScript("OnUpdate", function()
    if ChatFrameEditBox:IsVisible() and this.state ~= 1 then
      ChatFrame1:SetScale(2)
      ChatFrame1:ClearAllPoints()
      ChatFrame1:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
      ChatFrame1:SetPoint("BOTTOMRIGHT", UIParent, "RIGHT", 0, -14)

      FCF_SetWindowColor(ChatFrame1, 0,0,0)
      FCF_SetWindowAlpha(ChatFrame1, .5)

      this.state = 1
    elseif not ChatFrameEditBox:IsVisible() and this.state ~= 0 then
      local anchor = MainMenuBarArtFrame
      anchor = ShapeshiftBarFrame:IsVisible() and ShapeshiftBarFrame or anchor
      anchor = PetActionBarFrame:IsVisible() and PetActionBarFrame or anchor

      ChatFrame1:SetScale(1)
      ChatFrame1:ClearAllPoints()
      ChatFrame1:SetPoint("LEFT", MainMenuBar, "LEFT", 5, 0)
      ChatFrame1:SetPoint("RIGHT", MainMenuBar, "RIGHT", -5, 0)
      ChatFrame1:SetPoint("BOTTOM", anchor, "TOP", 0, 13)
      ChatFrame1:SetPoint("TOP", UIParent, "CENTER", 0, -200)

      FCF_SetWindowColor(ChatFrame1, 0,0,0)
      FCF_SetWindowAlpha(ChatFrame1, 0)

      this.state = 0
    end
  end)

  -- move and hide some chat buttons
  ChatFrameMenuButton:Hide()
  ChatFrameMenuButton.Show = function() return end

  for i=1, NUM_CHAT_WINDOWS do
    _G["ChatFrame"..i.."DownButton"]:ClearAllPoints()
    _G["ChatFrame"..i.."DownButton"]:SetPoint("BOTTOMRIGHT", _G["ChatFrame"..i], "BOTTOMRIGHT", 0, -5)

    _G["ChatFrame"..i.."UpButton"]:ClearAllPoints()
    _G["ChatFrame"..i.."UpButton"]:SetPoint("RIGHT", _G["ChatFrame"..i.."DownButton"], "LEFT", 0, 0)

    _G["ChatFrame"..i.."BottomButton"]:Hide()
    _G["ChatFrame"..i.."BottomButton"].Show = function() return end
  end

  -- move pet action bar
  local anchor = MainMenuBarArtFrame
  anchor = ShapeshiftBarFrame:IsVisible() and ShapeshiftBarFrame or anchor
  PetActionBarFrame:ClearAllPoints()
  PetActionBarFrame:SetPoint("BOTTOM", anchor, "TOP", 0, 3)

  -- move shapeshift bar
  ShapeshiftBarFrame:ClearAllPoints()
  ShapeshiftBarFrame:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "TOPLEFT", 15, -5)

  -- the multi bar buttons are placed in the layer clusters,
  -- keep their empty bar frames out of the way
  MultiBarBottomLeft:ClearAllPoints()
  MultiBarBottomLeft:SetPoint("BOTTOM", MainMenuBar, "BOTTOM", 0, 0)

  MultiBarBottomRight:ClearAllPoints()
  MultiBarBottomRight:SetPoint("BOTTOM", MainMenuBar, "BOTTOM", 0, 0)

  -- experience bar
  MainMenuXPBarTexture0:SetPoint("LEFT", MainMenuExpBar, "LEFT")
  MainMenuXPBarTexture1:SetPoint("RIGHT", MainMenuExpBar, "RIGHT")

  -- reputation bar
  ReputationWatchBar:SetPoint("BOTTOM", MainMenuExpBar, "TOP", 0, 0)
  ReputationWatchBarTexture0:SetPoint("LEFT", ReputationWatchBar, "LEFT")
  ReputationWatchBarTexture1:SetPoint("RIGHT", ReputationWatchBar, "RIGHT")

  -- move elements for reduced actionbar size
  MainMenuMaxLevelBar0:SetPoint("LEFT", MainMenuBarArtFrame, "LEFT")
  MainMenuBarTexture2:SetPoint("LEFT", MainMenuBarArtFrame, "LEFT")
  MainMenuBarTexture3:SetPoint("RIGHT", MainMenuBarArtFrame, "RIGHT")

  ActionBarDownButton:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMLEFT", -5, -5)
  ActionBarUpButton:SetPoint("TOPLEFT", MainMenuBarArtFrame, "TOPLEFT", -5, -5)
  MainMenuBarPageNumber:SetPoint("LEFT", MainMenuBarArtFrame, "LEFT", 25, -5)
  CharacterMicroButton:SetPoint("LEFT", MainMenuBarArtFrame, "LEFT", 38, 0)

  MainMenuBarLeftEndCap:SetPoint("RIGHT", MainMenuBarArtFrame, "LEFT", 30, 0)
  MainMenuBarRightEndCap:SetPoint("LEFT", MainMenuBarArtFrame, "RIGHT", -30, 0)

  -- move pfQuest arrow if existing
  if pfQuest and pfQuest.route and pfQuest.route.arrow then
    pfQuest.route.arrow:SetPoint("CENTER", 0, -120)
  end
end

-- save to main frame
ShaguController.ui = ui
