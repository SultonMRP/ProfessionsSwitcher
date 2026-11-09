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

BINDING_HEADER_PROFESSIONSSWITCHER = "Profession Switcher"
BINDING_NAME_PROFESSIONSSWITCHER_OPEN = "PS-Open Prof. Window"

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

local function MenuIsOpen()
    local list1 = _G.DropDownList1
    local list2 = _G.DropDownList2
    return (list1 and list1:IsShown()) or (list2 and list2:IsShown())
end

local function DropLabel()
    local openName = OpenLineName()
    if openName then
        return openName
    end
    local crafts = KnownCrafts()
    return crafts[1] and CraftName(crafts[1]) or "Professions"
end

local function SetDropLabel(drop)
    if drop and UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(drop, DropLabel())
    end
end

local function InitDrop(drop)
    if not drop or MenuIsOpen() then
        return
    end
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
    SetDropLabel(drop)
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

local function DetachFromPanelLayout(frame)
    if not frame then
        return
    end
    local name = frame.GetName and frame:GetName()
    if name and UIPanelWindows then
        UIPanelWindows[name] = nil
    end
    if frame.SetAttribute then
        frame:SetAttribute("UIPanelLayout-defined", true)
        frame:SetAttribute("UIPanelLayout-enabled", false)
    end
    if name and UISpecialFrames then
        local found
        for i = 1, #UISpecialFrames do
            if UISpecialFrames[i] == name then
                found = true
                break
            end
        end
        if not found then
            tinsert(UISpecialFrames, name)
        end
    end
end

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
            if TradeSkillFrame then
                DetachFromPanelLayout(TradeSkillFrame)
                if TradeSkillFrame:IsShown() then
                    ApplyFramePos(TradeSkillFrame, "tradePos")
                end
            end
            if CraftFrame then
                DetachFromPanelLayout(CraftFrame)
                if CraftFrame:IsShown() then
                    ApplyFramePos(CraftFrame, "craftPos")
                end
            end
        end)
        hooked.panelPos = true
    end
end

local function FillTradeReagentIcons()
    if not GetTradeSkillSelectionIndex or not GetTradeSkillNumReagents then
        return
    end
    local index = GetTradeSkillSelectionIndex()
    if not index or index < 1 then
        return
    end
    local num = GetTradeSkillNumReagents(index)
    for i = 1, num do
        local name, tex = GetTradeSkillReagentInfo(index, i)
        if name and (not tex or tex == "") then
            local link = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(index, i)
            if link then
                local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(link)
                tex = icon
            end
        end
        local btn = _G["TradeSkillReagent" .. i]
        if btn and tex and SetItemButtonTexture then
            SetItemButtonTexture(btn, tex)
        end
    end
end

local function FillCraftReagentIcons()
    if not GetCraftSelectionIndex or not GetCraftNumReagents then
        return
    end
    local index = GetCraftSelectionIndex()
    if not index or index < 1 then
        return
    end
    local num = GetCraftNumReagents(index)
    for i = 1, num do
        local name, tex = GetCraftReagentInfo(index, i)
        if name and (not tex or tex == "") then
            local link = GetCraftReagentItemLink and GetCraftReagentItemLink(index, i)
            if link then
                local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(link)
                tex = icon
            end
        end
        local btn = _G["CraftReagent" .. i]
        if btn and tex and SetItemButtonTexture then
            SetItemButtonTexture(btn, tex)
        end
    end
end

local function AttachTradeSkill()
    local parent = _G.TradeSkillFrame
    if not parent then
        return
    end
    MakeCraftFrameMovable(parent, "tradePos")
    DetachFromPanelLayout(parent)
    parent:SetFrameStrata("HIGH")
    ApplyFramePos(parent, "tradePos")
    tradeDrop = EnsureDrop(parent, "ProfessionsSwitcherTradeDrop")
    PlaceDrop(tradeDrop, parent, _G.TradeSkillRankFrame)
    HideTitle(_G.TradeSkillFrameTitleText)
    if not hooked.tradeDropInit then
        InitDrop(tradeDrop)
        hooked.tradeDropInit = true
    else
        SetDropLabel(tradeDrop)
    end

    if not hooked.tradeUpdate and hooksecurefunc and TradeSkillFrame_Update then
        hooksecurefunc("TradeSkillFrame_Update", function()
            HideTitle(_G.TradeSkillFrameTitleText)
            SetDropLabel(tradeDrop)
        end)
        hooked.tradeUpdate = true
    end
    if not hooked.tradeSelect and hooksecurefunc and TradeSkillFrame_SetSelection then
        hooksecurefunc("TradeSkillFrame_SetSelection", function()
            FillTradeReagentIcons()
        end)
        hooked.tradeSelect = true
    end
end

local function AttachCraft()
    local parent = _G.CraftFrame
    if not parent then
        return
    end
    MakeCraftFrameMovable(parent, "craftPos")
    DetachFromPanelLayout(parent)
    parent:SetFrameStrata("HIGH")
    ApplyFramePos(parent, "craftPos")
    craftDrop = EnsureDrop(parent, "ProfessionsSwitcherCraftDrop")
    PlaceDrop(craftDrop, parent, _G.CraftRankFrame)
    HideTitle(_G.CraftFrameTitleText)
    if not hooked.craftDropInit then
        InitDrop(craftDrop)
        hooked.craftDropInit = true
    else
        SetDropLabel(craftDrop)
    end

    if not hooked.craftUpdate and hooksecurefunc and CraftFrame_Update then
        hooksecurefunc("CraftFrame_Update", function()
            HideTitle(_G.CraftFrameTitleText)
            SetDropLabel(craftDrop)
        end)
        hooked.craftUpdate = true
    end
    if not hooked.craftSelect and hooksecurefunc and CraftFrame_SetSelection then
        hooksecurefunc("CraftFrame_SetSelection", function()
            FillCraftReagentIcons()
        end)
        hooked.craftSelect = true
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

    if event == "TRADE_SKILL_SHOW" then
        AttachTradeSkill()
        RememberOpenCraft()
        return
    end
    if event == "TRADE_SKILL_UPDATE" then
        RememberOpenCraft()
        SetDropLabel(tradeDrop)
        return
    end

    if event == "CRAFT_SHOW" then
        AttachCraft()
        RememberOpenCraft()
        return
    end
    if event == "CRAFT_UPDATE" then
        RememberOpenCraft()
        SetDropLabel(craftDrop)
        return
    end

    if tradeDrop and TradeSkillFrame and TradeSkillFrame:IsShown() then
        SetDropLabel(tradeDrop)
    end
    if craftDrop and CraftFrame and CraftFrame:IsShown() then
        SetDropLabel(craftDrop)
    end
end)

-- Warms item cache for recipe/reagent icons. Recipe *lists* still come from
-- the server each time the window opens; this only fills GetItemInfo.
local cacheJob
local cacheFrame = CreateFrame("Frame")
cacheFrame:Hide()

local function CachePrint(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffProfessionsSwitcher:|r " .. msg)
end

local function CacheQueryLink(link)
    if link and GetItemInfo then
        GetItemInfo(link)
        return 1
    end
    return 0
end

local function ExpandTradeHeaders()
    if not GetNumTradeSkills or not GetTradeSkillInfo then
        return
    end
    local i = 1
    local n = GetNumTradeSkills()
    while i <= n do
        local _, header, expanded = GetTradeSkillInfo(i)
        if header and not expanded then
            if ExpandTradeSkillSubClass then
                ExpandTradeSkillSubClass(i)
            elseif ExpandTradeSkillHeader then
                ExpandTradeSkillHeader(i)
            end
            n = GetNumTradeSkills()
        end
        i = i + 1
    end
end

local function ExpandCraftHeaders()
    if not GetNumCrafts or not GetCraftInfo then
        return
    end
    local i = 1
    local n = GetNumCrafts()
    while i <= n do
        local _, _, craftType, _, expanded = GetCraftInfo(i)
        if craftType == "header" and not expanded and ExpandCraftSkillLine then
            ExpandCraftSkillLine(i)
            n = GetNumCrafts()
        end
        i = i + 1
    end
end

local function CacheScanTrade(job, limit)
    if not GetNumTradeSkills then
        return true
    end
    local n = GetNumTradeSkills()
    local scanned = 0
    while job.scanIndex <= n and scanned < limit do
        local name, header = GetTradeSkillInfo(job.scanIndex)
        if name and not header then
            job.recipes = job.recipes + 1
            job.items = job.items + CacheQueryLink(GetTradeSkillItemLink and GetTradeSkillItemLink(job.scanIndex))
            local reagents = GetTradeSkillNumReagents and GetTradeSkillNumReagents(job.scanIndex) or 0
            for r = 1, reagents do
                job.items = job.items + CacheQueryLink(GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(job.scanIndex, r))
            end
        end
        job.scanIndex = job.scanIndex + 1
        scanned = scanned + 1
        n = GetNumTradeSkills()
    end
    return job.scanIndex > n
end

local function CacheScanCraft(job, limit)
    if not GetNumCrafts then
        return true
    end
    local n = GetNumCrafts()
    local scanned = 0
    while job.scanIndex <= n and scanned < limit do
        local name, _, craftType = GetCraftInfo(job.scanIndex)
        if name and craftType ~= "header" then
            job.recipes = job.recipes + 1
            job.items = job.items + CacheQueryLink(GetCraftItemLink and GetCraftItemLink(job.scanIndex))
            local reagents = GetCraftNumReagents and GetCraftNumReagents(job.scanIndex) or 0
            for r = 1, reagents do
                job.items = job.items + CacheQueryLink(GetCraftReagentItemLink and GetCraftReagentItemLink(job.scanIndex, r))
            end
        end
        job.scanIndex = job.scanIndex + 1
        scanned = scanned + 1
        n = GetNumCrafts()
    end
    return job.scanIndex > n
end

local function CacheCloseWindows()
    if CloseTradeSkill then
        CloseTradeSkill()
    end
    if CloseCraft then
        CloseCraft()
    end
end

local function CacheStop(quiet)
    cacheJob = nil
    cacheFrame:Hide()
    if not quiet then
        CachePrint("Precache stopped.")
    end
end

local function CacheStart()
    if cacheJob then
        CachePrint("Already running. Use /profcache stop")
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        CachePrint("Cannot precache during combat.")
        return
    end
    local crafts = KnownCrafts()
    if #crafts == 0 then
        CachePrint("No professions found.")
        return
    end
    cacheJob = {
        queue = crafts,
        q = 1,
        phase = "open",
        scanIndex = 1,
        lastCount = -1,
        stableAt = 0,
        waitUntil = 0,
        recipes = 0,
        items = 0,
        expanded = false,
    }
    cacheFrame:Show()
    CachePrint("Precaching " .. #crafts .. " profession(s). Windows will open and close. /profcache stop to cancel.")
end

cacheFrame:SetScript("OnUpdate", function()
    local job = cacheJob
    if not job then
        cacheFrame:Hide()
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        CacheStop(true)
        CachePrint("Precache stopped (combat).")
        return
    end
    if MenuIsOpen() then
        return
    end
    local now = GetTime()
    local craft = job.queue[job.q]
    if not craft then
        CacheCloseWindows()
        CachePrint(string.format("Precache done. %d recipes, %d item queries.", job.recipes, job.items))
        cacheJob = nil
        cacheFrame:Hide()
        return
    end
    if job.phase == "open" then
        CacheCloseWindows()
        job.waitUntil = now + 0.25
        job.phase = "cast"
        job.scanIndex = 1
        job.lastCount = -1
        job.stableAt = 0
        job.expanded = false
        return
    end
    if job.phase == "cast" then
        if now < job.waitUntil then
            return
        end
        CachePrint("Caching " .. CraftName(craft) .. "...")
        OpenCraft(craft)
        job.waitUntil = now + 8
        job.phase = "wait"
        return
    end
    if job.phase == "wait" then
        local ready, count
        if craft.craftUI then
            ready = CraftFrame and CraftFrame:IsShown()
            count = GetNumCrafts and GetNumCrafts() or 0
        else
            ready = TradeSkillFrame and TradeSkillFrame:IsShown()
            count = GetNumTradeSkills and GetNumTradeSkills() or 0
        end
        if ready then
            if count ~= job.lastCount then
                job.lastCount = count
                job.stableAt = now + 0.6
            elseif job.stableAt > 0 and now >= job.stableAt then
                job.phase = "scan"
            end
        elseif now >= job.waitUntil then
            CachePrint("Skipped " .. CraftName(craft) .. " (did not open).")
            job.q = job.q + 1
            job.phase = "open"
        end
        return
    end
    if job.phase == "scan" then
        if not job.expanded then
            if craft.craftUI then
                ExpandCraftHeaders()
            else
                if TradeSkillOnlyShowMakeable then
                    TradeSkillOnlyShowMakeable(false)
                end
                ExpandTradeHeaders()
            end
            job.expanded = true
            job.scanIndex = 1
            return
        end
        local done
        if craft.craftUI then
            done = CacheScanCraft(job, 25)
        else
            done = CacheScanTrade(job, 25)
        end
        if done then
            job.phase = "next"
            job.waitUntil = now + 0.15
        end
        return
    end
    if job.phase == "next" then
        if now < job.waitUntil then
            return
        end
        job.q = job.q + 1
        job.phase = "open"
    end
end)

SLASH_PROFRESET1 = "/profreset"
SLASH_PROFOPEN1 = "/openprof"
SLASH_PROFCACHE1 = "/profcache"
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

SlashCmdList["PROFCACHE"] = function(msg)
    msg = msg and string.lower(msg) or ""
    if msg == "stop" or msg == "cancel" then
        if cacheJob then
            CacheStop()
        else
            CachePrint("Precache is not running.")
        end
        return
    end
    CacheStart()
end
