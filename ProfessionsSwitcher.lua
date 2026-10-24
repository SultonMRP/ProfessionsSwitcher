-- Crafting-window profession dropdown for WotLK 3.3.5a.
-- Enchanting uses CraftFrame; every other craft window uses TradeSkillFrame.

local CRAFTS = {
    { key = "alchemy",        ranks = { 2259, 3101, 3464, 11611, 28596, 51304 }, aliases = { "Alchemy" } },
    { key = "blacksmithing",  ranks = { 2018, 3100, 3538, 9785, 29844, 51300 }, aliases = { "Blacksmithing" } },
    { key = "enchanting",     ranks = { 7411, 7412, 7413, 13920, 28029, 51313 }, aliases = { "Enchanting" }, craftUI = true },
    { key = "engineering",    ranks = { 4036, 4037, 4038, 12656, 30350, 51306 }, aliases = { "Engineering" } },
    { key = "inscription",    ranks = { 45357, 45358, 45359, 45360, 45361, 45363 }, aliases = { "Inscription" } },
    { key = "jewelcrafting",  ranks = { 25229, 25230, 28894, 28895, 28897, 51311 }, aliases = { "Jewelcrafting" } },
    { key = "leatherworking", ranks = { 2108, 3104, 3811, 10662, 32549, 51302 }, aliases = { "Leatherworking" } },
    { key = "tailoring",      ranks = { 3908, 3909, 3910, 12180, 26790, 51309 }, aliases = { "Tailoring" } },
    { key = "cooking",        ranks = { 2550, 3102, 3413, 18260, 33359, 51296 }, aliases = { "Cooking" } },
    { key = "firstaid",       ranks = { 3273, 3274, 7924, 10846, 27028, 45542 }, aliases = { "First Aid" } },
    { key = "smelting",       ranks = { 2575, 2576, 3564, 10248, 29354, 50310 }, aliases = { "Mining", "Smelting" }, openSpell = 2656 },
}

BINDING_HEADER_PROFESSIONSSWITCHER = "Prof. Switcher"
BINDING_NAME_PROFESSIONSSWITCHER_OPEN = "Prof. Switcher"

local db
local tradeDrop, craftDrop
local hooked = {}
local CRAFT_BY_KEY = {}
for i = 1, #CRAFTS do
    CRAFT_BY_KEY[CRAFTS[i].key] = CRAFTS[i]
end

local function SpellName(id)
    return GetSpellInfo(id)
end

local function CraftName(craft)
    if craft.openSpell then
        return SpellName(craft.openSpell) or SpellName(craft.ranks[1]) or craft.key
    end
    return SpellName(craft.ranks[1]) or craft.key
end

local function CraftIcon(craft)
    local id = craft.openSpell or craft.ranks[1]
    local _, _, icon = GetSpellInfo(id)
    return icon
end

local function Lower(text)
    return text and string.lower(text) or nil
end

local function SkillLineName(craft)
    return SpellName(craft.ranks[1])
end

local function CraftNames(craft)
    local names = {}
    local function add(name)
        local key = Lower(name)
        if key and not names[key] then
            names[key] = name
        end
    end
    add(SpellName(craft.ranks[1]))
    add(craft.openSpell and SpellName(craft.openSpell))
    if craft.aliases then
        for i = 1, #craft.aliases do
            add(craft.aliases[i])
        end
    end
    return names
end

local function NameMatchesCraft(name, craft)
    local key = Lower(name)
    if not key then
        return false
    end
    return CraftNames(craft)[key] ~= nil
end

local function OpenLineName()
    if TradeSkillFrame and TradeSkillFrame:IsShown() and GetTradeSkillLine then
        local name = GetTradeSkillLine()
        if name and name ~= "UNKNOWN" then
            return name
        end
    end
    if CraftFrame and CraftFrame:IsShown() and GetCraftDisplaySkillLine then
        local name = GetCraftDisplaySkillLine()
        if name and name ~= "UNKNOWN" then
            return name
        end
    end
end

local function SpellbookHasCraft(craft)
    local wanted = CraftNames(craft)
    local tabCount = GetNumSpellTabs and GetNumSpellTabs() or 8
    for tab = 1, tabCount do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        offset = offset or 0
        numSpells = numSpells or 0
        for i = offset + 1, offset + numSpells do
            local spellName = GetSpellName(i, BOOKTYPE_SPELL)
            if spellName and wanted[Lower(spellName)] then
                return true
            end
        end
    end
    return false
end

local function SkillListHasCraft(craft)
    for i = 1, GetNumSkillLines() do
        local name, isHeader = GetSkillLineInfo(i)
        if not isHeader and NameMatchesCraft(name, craft) then
            return true
        end
    end
    return false
end

local function KnowsCraft(craft)
    if SkillListHasCraft(craft) then
        return true
    end
    if SpellbookHasCraft(craft) then
        return true
    end
    if NameMatchesCraft(OpenLineName(), craft) then
        return true
    end
    return false
end

local function KnownCrafts()
    local list = {}
    for i = 1, #CRAFTS do
        local craft = CRAFTS[i]
        if KnowsCraft(craft) then
            list[#list + 1] = craft
        end
    end
    return list
end

local function IsCurrentCraft(craft)
    return NameMatchesCraft(OpenLineName(), craft)
end

local function CraftFromOpenName(name)
    if not name then
        return nil
    end
    for i = 1, #CRAFTS do
        if NameMatchesCraft(name, CRAFTS[i]) then
            return CRAFTS[i]
        end
    end
end

local function RememberCraft(craft)
    if db and craft then
        db.lastKey = craft.key
    end
end

local function RememberOpenCraft()
    RememberCraft(CraftFromOpenName(OpenLineName()))
end

local function LastCraft()
    if db and db.lastKey and CRAFT_BY_KEY[db.lastKey] and KnowsCraft(CRAFT_BY_KEY[db.lastKey]) then
        return CRAFT_BY_KEY[db.lastKey]
    end
    local crafts = KnownCrafts()
    return crafts[1]
end

local function OpenCraft(craft)
    if not craft then
        return
    end
    RememberCraft(craft)
    if IsCurrentCraft(craft) then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffProfessionsSwitcher:|r Cannot switch professions during combat.")
        return
    end
    local spell = SpellName(craft.openSpell or craft.ranks[1])
    if spell then
        CastSpellByName(spell)
    end
end

function ProfessionsSwitcher_OpenLast()
    local craft = LastCraft()
    if not craft then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffProfessionsSwitcher:|r No crafting profession to open.")
        return
    end
    if IsCurrentCraft(craft) then
        if CloseTradeSkill then
            CloseTradeSkill()
        end
        if CloseCraft then
            CloseCraft()
        end
        return
    end
    OpenCraft(craft)
end

local function HideTitle(fontString)
    if fontString then
        fontString:Hide()
    end
end

local function InitDrop(drop)
    local openName = OpenLineName()
    UIDropDownMenu_Initialize(drop, function()
        local crafts = KnownCrafts()
        for i = 1, #crafts do
            local craft = crafts[i]
            local info = UIDropDownMenu_CreateInfo and UIDropDownMenu_CreateInfo() or {}
            info.text = CraftName(craft)
            info.icon = CraftIcon(craft)
            info.checked = IsCurrentCraft(craft)
            info.func = function()
                OpenCraft(craft)
            end
            UIDropDownMenu_AddButton(info)
        end
        if #crafts == 0 then
            local info = UIDropDownMenu_CreateInfo and UIDropDownMenu_CreateInfo() or {}
            info.text = "No crafting professions"
            info.disabled = 1
            info.notCheckable = 1
            UIDropDownMenu_AddButton(info)
        end
    end)

    local label = openName
    if not label then
        local crafts = KnownCrafts()
        label = crafts[1] and CraftName(crafts[1]) or "Professions"
    end
    UIDropDownMenu_SetText(drop, label)
end

local function PlaceDrop(drop, parent, rankFrame)
    drop:ClearAllPoints()
    if rankFrame then
        drop:SetPoint("BOTTOMLEFT", rankFrame, "TOPLEFT", -16, 17)
    else
        drop:SetPoint("TOPLEFT", parent, "TOPLEFT", 50, -10)
    end
    drop:SetFrameLevel((parent:GetFrameLevel() or 1) + 40)
    drop:Show()
end

local function EnsureDrop(parent, globalName)
    local drop = _G[globalName]
    if drop then
        return drop
    end
    drop = CreateFrame("Frame", globalName, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(drop, 170)
    UIDropDownMenu_JustifyText(drop, "LEFT")
    drop:SetScript("OnShow", function(self)
        InitDrop(self)
    end)
    return drop
end

local applyingPos = false

local function SaveFramePos(frame, key)
    if not db or not frame then
        return
    end
    local point, _, rel, x, y = frame:GetPoint()
    db[key] = {
        point = point or "CENTER",
        rel = rel or "CENTER",
        x = x or 0,
        y = y or 0,
    }
end

local function ApplyFramePos(frame, key)
    if not db or not frame or not db[key] or applyingPos then
        return
    end
    local pos = db[key]
    applyingPos = true
    frame:ClearAllPoints()
    frame:SetPoint(pos.point or "CENTER", UIParent, pos.rel or "CENTER", pos.x or 0, pos.y or 0)
    applyingPos = false
end

local function CenterFrame(frame, key)
    if not frame then
        return
    end
    applyingPos = true
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    applyingPos = false
    SaveFramePos(frame, key)
end

local function MakeCraftFrameMovable(frame, key)
    if not frame or frame.psMovable then
        return
    end
    frame.psMovable = true
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveFramePos(self, key)
    end)
    if not hooked.panelPos and hooksecurefunc then
        hooksecurefunc("UpdateUIPanelPositions", function()
            if TradeSkillFrame and TradeSkillFrame:IsShown() then
                ApplyFramePos(TradeSkillFrame, "tradePos")
            end
            if CraftFrame and CraftFrame:IsShown() then
                ApplyFramePos(CraftFrame, "craftPos")
            end
        end)
        hooked.panelPos = true
    end
end

local function AttachTradeSkill()
    local parent = _G.TradeSkillFrame
    if not parent then
        return
    end
    MakeCraftFrameMovable(parent, "tradePos")
    parent:SetFrameStrata("HIGH")
    ApplyFramePos(parent, "tradePos")
    tradeDrop = EnsureDrop(parent, "ProfessionsSwitcherTradeDrop")
    PlaceDrop(tradeDrop, parent, _G.TradeSkillRankFrame)
    HideTitle(_G.TradeSkillFrameTitleText)
    InitDrop(tradeDrop)

    if not hooked.tradeUpdate and hooksecurefunc and TradeSkillFrame_Update then
        hooksecurefunc("TradeSkillFrame_Update", function()
            HideTitle(_G.TradeSkillFrameTitleText)
            if tradeDrop then
                InitDrop(tradeDrop)
            end
        end)
        hooked.tradeUpdate = true
    end
end

local function AttachCraft()
    local parent = _G.CraftFrame
    if not parent then
        return
    end
    MakeCraftFrameMovable(parent, "craftPos")
    parent:SetFrameStrata("HIGH")
    ApplyFramePos(parent, "craftPos")
    craftDrop = EnsureDrop(parent, "ProfessionsSwitcherCraftDrop")
    PlaceDrop(craftDrop, parent, _G.CraftRankFrame)
    HideTitle(_G.CraftFrameTitleText)
    InitDrop(craftDrop)

    if not hooked.craftUpdate and hooksecurefunc and CraftFrame_Update then
        hooksecurefunc("CraftFrame_Update", function()
            HideTitle(_G.CraftFrameTitleText)
            if craftDrop then
                InitDrop(craftDrop)
            end
        end)
        hooked.craftUpdate = true
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("TRADE_SKILL_SHOW")
events:RegisterEvent("TRADE_SKILL_UPDATE")
events:RegisterEvent("CRAFT_SHOW")
events:RegisterEvent("CRAFT_UPDATE")
events:RegisterEvent("SKILL_LINES_CHANGED")
events:RegisterEvent("SPELLS_CHANGED")

events:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName == "ProfessionsSwitcher" then
            ProfessionsSwitcherDB = ProfessionsSwitcherDB or {}
            db = ProfessionsSwitcherDB
        elseif addonName == "Blizzard_TradeSkillUI" then
            AttachTradeSkill()
        elseif addonName == "Blizzard_CraftUI" then
            AttachCraft()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        if IsAddOnLoaded("Blizzard_TradeSkillUI") then
            AttachTradeSkill()
        end
        if IsAddOnLoaded("Blizzard_CraftUI") then
            AttachCraft()
        end
        return
    end

    if event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" then
        AttachTradeSkill()
        RememberOpenCraft()
        return
    end

    if event == "CRAFT_SHOW" or event == "CRAFT_UPDATE" then
        AttachCraft()
        RememberOpenCraft()
        return
    end

    if tradeDrop and TradeSkillFrame and TradeSkillFrame:IsShown() then
        InitDrop(tradeDrop)
    end
    if craftDrop and CraftFrame and CraftFrame:IsShown() then
        InitDrop(craftDrop)
    end
end)

SLASH_PROFRESET1 = "/profreset"
SLASH_PROFOPEN1 = "/openprof"
SlashCmdList["PROFRESET"] = function()
    if not db then
        ProfessionsSwitcherDB = ProfessionsSwitcherDB or {}
        db = ProfessionsSwitcherDB
    end
    CenterFrame(_G.TradeSkillFrame, "tradePos")
    CenterFrame(_G.CraftFrame, "craftPos")
    if not _G.TradeSkillFrame and not _G.CraftFrame then
        db.tradePos = { point = "CENTER", rel = "CENTER", x = 0, y = 0 }
        db.craftPos = { point = "CENTER", rel = "CENTER", x = 0, y = 0 }
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffProfessionsSwitcher:|r Crafting window centered. Drag the window to move it again.")
end

SlashCmdList["PROFOPEN"] = function()
    ProfessionsSwitcher_OpenLast()
end
