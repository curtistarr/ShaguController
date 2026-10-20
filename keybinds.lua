local keybinds = CreateFrame("Frame", "ShaguControllerKeybinds")

-- gamepad buttons in the order of the layer slots:
-- D-pad up, right, down, left and Y, B, A, X
keybinds.keys = { "UP", "RIGHT", "DOWN", "LEFT", "F", "E", "SPACE", "R" }

-- the modifier keys that are sent by the triggers and their action bars
keybinds.layers = {
  ["SHIFT-"] = "MULTIACTIONBAR1BUTTON",      -- LT: bottom left bar
  ["CTRL-"] = "MULTIACTIONBAR2BUTTON",       -- RT: bottom right bar
  ["CTRL-SHIFT-"] = "MULTIACTIONBAR3BUTTON", -- LT+RT: right bar
}

keybinds:RegisterEvent("PLAYER_LOGIN")
keybinds:RegisterEvent("PLAYER_LOGOUT")
keybinds:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then
    -- save previous keybinds
    keybinds.previous_bindings = GetCurrentBindingSet()

    -- overwrite keybindings on login
    SetBinding("TAB", "TOGGLEWORLDMAP")                 -- Window (TabKey)
    SetBinding("1", "SHAGUCONTROL1")                    -- Trackpad-Up: Inventory + Character
    SetBinding("2", "SHAGUCONTROL2")                    -- Trackpad-Right: QuestLog
    SetBinding("3", "SHAGUCONTROL3")                    -- Trackpad-Down: Talents & Social
    SetBinding("4", "SHAGUCONTROL4")                    -- Trackpad-Left: Spellbook
    SetBinding("MOUSEWHEELDOWN", "TARGETPREVIOUSENEMY") -- L1
    SetBinding("MOUSEWHEELUP", "TARGETNEARESTENEMY")    -- R1
    SetBinding("F", "ACTIONBUTTON1")                    -- Y
    SetBinding("R", "ACTIONBUTTON2")                    -- X
    SetBinding("E", "ACTIONBUTTON3")                    -- B
    -- Jump                                             -- A
    SetBinding("UP", "ACTIONBUTTON5")                   -- Arrow-Up
    SetBinding("RIGHT", "ACTIONBUTTON10")               -- Arrow-Right
    SetBinding("DOWN", "ACTIONBUTTON11")                -- Arrow-Down
    SetBinding("LEFT", "ACTIONBUTTON12")                -- Arrow-Left

    -- modifier layers: LT (Shift), RT (Ctrl) and LT+RT (Ctrl+Shift)
    for prefix, bar in pairs(keybinds.layers) do
      for id, key in pairs(keybinds.keys) do
        SetBinding(prefix .. key, bar .. id)
      end
    end

    SaveBindings(GetCurrentBindingSet())

    -- notify the player for keybind changes
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffController: Initialized Keybinds")
  elseif event == "PLAYER_LOGOUT" and keybinds.previous_bindings then
    SaveBindings(keybinds.previous_bindings)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffController: Old Keybinds Restored")
  end
end)

-- save to main frame
ShaguController.keybinds = keybinds
