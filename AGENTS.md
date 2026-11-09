# ProfessionsSwitcher

WotLK 3.3.5a dropdown on every crafting window so you can switch professions without closing the UI. Enchanting uses `CraftFrame`; every other craft uses `TradeSkillFrame`.

## Client

- Target: WoW 3.3.5a only (`## Interface: 30300`)
- Lua 5.1. No `C_Timer`, no retail profession APIs
- Do not call `TradeSkillFrame_Update` / `CraftFrame_Update` on a timer or on every `TRADE_SKILL_UPDATE`. Blizzard already redraws the list. Extra rebuilds make the recipe count look short, close the dropdown, and hitch after store-taught "all recipes"
- `TRADE_SKILL_UPDATE` / `CRAFT_UPDATE` must stay cheap: remember the last profession and set the dropdown label. Attach frames on `SHOW`, not on every update packet
- Do not wipe `Cache` / `WDB` to "fix" a slow recipe list. That list is sent by the server when the window opens; item cache only affects reagent icons
- Recipe lists cannot be precached. `/profcache` only warms `GetItemInfo` for recipe and reagent icons. It must not run by itself
- Keep the profession window out of `UIPanelWindows` (`UIPanelLayout-enabled` false). Otherwise CharacterFrame (and other panels) shift as if TradeSkill is still parked in the left slot after the user dragged it
- While `DropDownList1` / `DropDownList2` is shown, do not `UIDropDownMenu_Initialize` or rebuild the trade skill frame
- Switching professions is blocked in combat (`InCombatLockdown`)
- Saved position is per character (`ProfessionsSwitcherDB`)

## Commands

- `/openprof` — open last crafting profession (or close it)
- `/profreset` — center TradeSkill and Enchanting windows
- `/profcache` — walk known professions once and query item links; `/profcache stop` cancels
