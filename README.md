# Baggy

Modern category-based bag replacement for World of Warcraft Retail.

## Features

- Replaces the default bag window behavior with a single modern Baggy frame
- Main tabs:
  - Consumables
  - Armor
  - Materials
  - Mounts
  - Misc
- Armor subtabs:
  - All
  - Weapons
  - Head
  - Neck
  - Shoulder
  - Back
  - Chest
  - Wrist
  - Hands
  - Waist
  - Legs
  - Feet
  - Finger
  - Trinket
- Global search for the active tab
- Inventory mode and bank mode (bank + inventory while bank is open)
- Persistent frame position, size, scale, active tab/subtab, and lock state
- UI labels are intentionally English and work across all game locales

## Commands

- `/baggy` - Toggle Baggy window
- `/baggy help` - Show command help
- `/baggy reset` - Reset layout and settings
- `/baggy lock` - Toggle frame lock
- `/baggy scale <0.75-1.50>` - Set frame scale
- `/baggy debug classify` - Toggle temporary item classification debug output (max 25 lines per rescan)

## Material Classification

- Crafting materials are classified by API-driven item class IDs.
- `Enum.ItemClass.Tradegoods` and `Enum.ItemClass.Reagent` are both routed to `Materials`.
- Classification logic is locale-independent and does not use tooltip/name text parsing.
- `Data/Overrides.lua` can pin specific itemIDs to explicit tabs for API edge cases.
- Legacy saved tabs (`CLOTH/LEATHER/HERBS/ORES`) are auto-migrated to `MATERIALS`.

## Scope

- Target: WoW Retail
- Not included: Classic/Cata/Wrath support, auto-sorting/auto-stacking, full options panel
