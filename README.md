# ProfessionsSwitcher

Adds a dropdown of your crafting professions to the top of every crafting window.

**For WotLK 3.3.5a.** Enchanting uses `CraftFrame`; every other craft window uses `TradeSkillFrame`.

Crafting windows are movable and float outside Blizzard's panel stack, so opening the character sheet does not shove itself sideways as if the profession window still owned the left slot. The last profession you opened is remembered per character.

## Install

Copy the `ProfessionsSwitcher` folder to `Interface\AddOns` and `/reload`.

Or download the release zip and extract it into `Interface\AddOns`.

## Commands

| Command | Effect |
| --- | --- |
| `/openprof` | Open the last crafting profession (or close it if that window is already open) |
| `/profreset` | Center the TradeSkill and Enchanting windows |
| `/profcache` | Open each known profession once and warm reagent/item icons. Does not make the recipe list load faster. `/profcache stop` cancels |

A keybind for `/openprof` is under **Key Bindings → Profession Switcher**.

## Notes

- Lists Alchemy, Blacksmithing, Enchanting, Engineering, Inscription, Jewelcrafting, Leatherworking, Tailoring, Cooking, First Aid, and Smelting
- Switching professions is blocked in combat
- The addon does not rebuild the recipe list in the background; that made store-taught professions hitch
