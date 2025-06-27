SLASH_TTRAIN1 = "/ttrain"
SLASH_DEBUGSPELLS1 = "/debugspells"


-- lists all spells in the spellbook currently with /debugspells

SlashCmdList["DEBUGSPELLS"] = function()
    for i = 1, 100 do
        local name, rank = GetSpellName(i, "spell")
        if name ~= nil or rank ~= nil then
            DEFAULT_CHAT_FRAME:AddMessage("Slot " .. i .. ": name = " .. tostring(name) .. ", rank " .. tostring(rank))
        end
    end
end








-- Create the main frame
local skillbrowser = CreateFrame("Frame", "SkillBrowser", UIParent, BackdropTemplateMixin and "BackdropTemplate")
skillbrowser:SetWidth(384)
skillbrowser:SetHeight(512)
skillbrowser:SetPoint("CENTER", 0, 0)
skillbrowser:SetFrameStrata("FULLSCREEN_DIALOG")
skillbrowser:SetMovable(true)
skillbrowser:EnableMouse(true)
skillbrowser:SetMovable(true)
skillbrowser:Hide()

-- Dragging scripts
skillbrowser:RegisterForDrag("LeftButton")
skillbrowser:SetScript("OnDragStart", function(this)
    this:StartMoving()
end)
skillbrowser:SetScript("OnDragStop", function(this)
    this:StopMovingOrSizing()
end)

-- Background icon
local icon = skillbrowser:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Spellbook\\Spellbook-Icon")
icon:SetWidth(58)
icon:SetHeight(58)
icon:SetPoint("TOPLEFT", 10, -8)

-- Panel textures
local topLeft = skillbrowser:CreateTexture(nil, "ARTWORK")
topLeft:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-TopLeft")
topLeft:SetWidth(256)
topLeft:SetHeight(256)
topLeft:SetPoint("TOPLEFT", 0, 0)

local topRight = skillbrowser:CreateTexture(nil, "ARTWORK")
topRight:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-TopRight")
topRight:SetWidth(128)
topRight:SetHeight(256)
topRight:SetPoint("TOPRIGHT", 0, 0)

local botLeft = skillbrowser:CreateTexture(nil, "ARTWORK")
botLeft:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-BotLeft")
botLeft:SetWidth(256)
botLeft:SetHeight(256)
botLeft:SetPoint("BOTTOMLEFT", 0, 0)

local botRight = skillbrowser:CreateTexture(nil, "ARTWORK")
botRight:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-BotRight")
botRight:SetWidth(128)
botRight:SetHeight(256)
botRight:SetPoint("BOTTOMRIGHT", 0, 0)

-- Title text
local title = skillbrowser:CreateFontString("SpellBookTitleText", "ARTWORK", "GameFontNormal")
title:SetText("Turtle Trainer")
title:SetPoint("CENTER", 6, 230)

-- Page text
local pageText = skillbrowser:CreateFontString("SpellBookPageText", "ARTWORK", "GameFontNormal")
pageText:SetWidth(102)
pageText:SetHeight(0)
pageText:SetPoint("BOTTOM", -14, 96)

-- Close button
local closeButton = CreateFrame("Button", "SpellBookCloseButton", skillbrowser, "UIPanelCloseButton")
closeButton:SetPoint("CENTER", skillbrowser, "TOPRIGHT", -44, -25)

-- Scroll frame
local scrollFrame = CreateFrame("ScrollFrame", "SkillBrowserScrollFrame", skillbrowser, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 20, -75)
scrollFrame:SetPoint("BOTTOMRIGHT", -65, 80)

-- Scroll content frame
local scrollContent = CreateFrame("Frame", "SkillBrowserScrollContent", scrollFrame)
scrollContent:SetWidth(300)
scrollContent:SetHeight(1)
scrollFrame:SetScrollChild(scrollContent)

-- Add scroll background like quest log
local scrollBG = scrollFrame:CreateTexture(nil, "BACKGROUND")
scrollBG:SetAllPoints()
scrollBG:SetTexture("Interface\\QuestFrame\\UI-QuestLog-ScrollPanel")
scrollBG:SetTexCoord(0, 1, 0, 0.75)


-- Function to create a spell row
local function CreateSpellRow(parent, text, index, color)
  local row = CreateFrame("Button", nil, parent)
  row:SetHeight(20)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 22))
  row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -((index - 1) * 22))

  local bg = row:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetTexture(1, 1, 1, math.mod(index, 2) == 0 and 0.03 or 0.06)

  local label = row:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  label:SetPoint("LEFT", row, "LEFT", 5, 0)
  label:SetText(text)

    -- Set color; default white if no color provided
  if color then
    label:SetTextColor(unpack(color))
  else
    label:SetTextColor(1, 1, 1)
  end

  row:SetScript("OnEnter", function()
    bg:SetTexture(0.3, 1, 0.8, 0.3)
  end)
  row:SetScript("OnLeave", function()
    bg:SetTexture(1, 1, 1, math.mod(index, 2) == 0 and 0.03 or 0.06)
    GameTooltip:Hide()
  end)
  row:SetScript("OnClick", function()
    DEFAULT_CHAT_FRAME:AddMessage("Clicked: " .. text)
  end)
end





local function GetLearnedSpells()
  local learned = {}

  for i = 1, 100 do
    local name, rank = GetSpellName(i, "spell")
    if name then
      local baseName = name
      local rankNumber = 0

      if type(rank) == "string" and rank ~= "" then
        -- Look for "Rank X" inside the rank string manually
        local startPos, endPos = string.find(rank, "%d+")
        if startPos and endPos then
          -- Extract substring containing the digits
          local rankStr = string.sub(rank, startPos, endPos)
          rankNumber = tonumber(rankStr) or 0
        end
      end

      for r = 1, rankNumber do
        learned[baseName .. " (Rank " .. r .. ")"] = true
      end

      if rank == "" or rank == nil then
        learned[baseName] = true
      end
    end
  end

  return learned
end


SLASH_DEBUGLEARNED1 = "/debuglearned"
SlashCmdList["DEBUGLEARNED"] = function()
    local learned = GetLearnedSpells()
    for spell in pairs(learned) do
        print("Learned: " .. spell)
    end
end



-- Fill the skill browser
local function PopulateSkillBrowser()
  local _, class = UnitClass("player")
  local playerLevel = UnitLevel("player")
  local index = 1
  local classSpells = spellsByLevel[class]
  local learnedSpells = GetLearnedSpells()

  if classSpells then
    local levels = {}
    for level in pairs(classSpells) do
      table.insert(levels, level)
    end
    table.sort(levels)

    for _, level in ipairs(levels) do
      local spells = classSpells[level]
      table.sort(spells)
      CreateSpellRow(scrollContent, "Level " .. level, index)
      index = index + 1

      for _, spellName in ipairs(spells) do
        local isLearned = learnedSpells[spellName] or false
        local color

        if isLearned then
          color = {1, 1, 1}       -- white
        elseif playerLevel >= level then
          color = {0, 1, 0}       -- green
        else
          color = {1, 0, 0}       -- red
        end

        local mark = isLearned and "X" or "O"
        CreateSpellRow(scrollContent, "  " .. mark .. " " .. spellName, index, color)
        index = index + 1
      end
    end
  else
    CreateSpellRow(scrollContent, "No spell data available for your class.", index)
  end
  scrollContent:SetHeight(index * 22)
  scrollFrame:SetVerticalScroll(0)
end






SLASH_SKILLBROWSER1 = "/skillbrowser"
SlashCmdList["SKILLBROWSER"] = function()
  if skillbrowser:IsShown() then
    skillbrowser:Hide()
  else
    skillbrowser:Show()
    if not skillbrowser.__initialized then
      PopulateSkillBrowser()
      skillbrowser.__initialized = true
    end
  end
end