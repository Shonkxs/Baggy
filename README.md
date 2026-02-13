# Baggy

Modern category-based bag replacement for World of Warcraft Retail.

## Features

- Replaces the default bag window behavior with a single modern Baggy frame
- Main tabs:
  - Consumables
  - Armor
  - Materials
  - Gems
  - Enchantments
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
- Header shows current character gold (gold/silver/copper)
- Crafting reagent quality badges are shown on item icons (when available via API)
- Tracked currency badges can be added via a `+` picker in the header

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

## Gems and Enchantments

- `Enum.ItemClass.Gem` items are routed to `Gems`.
- `Enum.ItemClass.ItemEnhancement` items are routed to `Enchantments`.
- This is a strict split: Gems/ItemEnhancement are not duplicated into `Materials`.
- Enchanting reagents (for example dust/shards/essences) usually remain in `Materials` because they are typically `Tradegoods`/`Reagent`.

## Gold Display

- Gold uses the character money API (`GetMoney()`), not warband/account aggregated totals.
- The header display is formatted as gold/silver/copper with WoW coin icons.

## Tracked Currencies

- Click the header `+` button to open a currency picker with search.
- Click a currency row to add it as a header badge.
- Badges display currency icon + owned amount.
- Right-click a badge to remove it.
- Up to 8 currencies can be tracked at once.
- Currency data is sourced from `C_CurrencyInfo`.

## Crafting Quality Badges

- Badge source: `C_TradeSkillUI.GetItemReagentQualityByItemInfo`.
- Reagent quality badges are shown at the top-left of item icons.
- Stack counts are shown at the bottom-right to avoid overlap with quality badges.

## Scope

- Target: WoW Retail
- Not included: Classic/Cata/Wrath support, auto-sorting/auto-stacking, full options panel
