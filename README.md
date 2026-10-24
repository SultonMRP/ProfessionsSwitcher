# ProfessionsSwitcher

Adds a dropdown of your crafting professions to the top of every crafting window.

**For WotLK 3.3.5a.** Enchanting uses `CraftFrame`; every other craft window uses `TradeSkillFrame`.

Crafting windows are movable. The last profession you opened is remembered per character.

## Install

Copy the `ProfessionsSwitcher` folder to `Interface\AddOns` and `/reload`.

Or download the release zip and extract it into `Interface\AddOns`.

## Commands

| Command | Effect |
| --- | --- |
| `/openprof` | Open the last crafting profession (or close it if that window is already open) |
| `/profreset` | Center the TradeSkill and Enchanting windows |

A keybind for `/openprof` is under **Key Bindings → Prof. Switcher**.

## Notes

- Lists Alchemy, Blacksmithing, Enchanting, Engineering, Inscription, Jewelcrafting, Leatherworking, Tailoring, Cooking, First Aid, and Smelting
- Switching professions is blocked in combat
