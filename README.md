# Hoard Value

How much your character, and your whole account, is worth in gold: the gold you carry plus everything in your bags, bank and warband bank, priced with TradeSkillMaster or Auctionator.

- **Total at a glance**, split into gold, bags, bank and warband bank.
- **Every item, most valuable first.** Click a column to sort by name, quantity, price, value or where it is. Search by item name or place.
- **Three tabs:** this character, the whole account (all characters plus the warband bank), and a per-character list.
- **Hoard Info on every item tooltip:** which of your characters have the item and how many, with a bag icon for their bags and a bank icon for their bank. The warband bank gets its own line, and a total shows when it's in more than one place. For items that come in ranks, an item shows only its own rank, and a material slot on a recipe or crafting order shows every rank you own, rank 1 first.
- **Realistic value:** what you'd actually get selling everything. Each item counts at the lower of its market value and the cheapest auction right now, minus the 5% auction house cut.
- Items with no auction price, like gray junk, count at vendor price. Anything a vendor pays more for than the auction house counts at the vendor price.

Requires **TradeSkillMaster** or **Auctionator** for auction prices. Without either, only vendor prices are used.

Works on **Retail** (Midnight 12.1), **Mists of Pandaria Classic**, **TBC Anniversary**, **WoW Forever** and **Classic Era** (including Season of Discovery and Hardcore). Classic has no warband bank, so everything about it is simply left out there.

## Install
Copy the `HoardValue` folder to `World of Warcraft\_retail_\Interface\AddOns\` (or `_classic_` / `_classic_era_` for Classic) and restart the game.

## Use
Click the coin button on the minimap, or pick **Hoard Value** in the minimap's addon menu, or type `/hoard`. Hover the button to see your character and account totals without opening anything.

- **Bags** are always up to date.
- **Your bank and the warband bank** can only be read while a bank is open. Visit a banker once on each character; Hoard Value remembers what was there and updates it every time you open the bank. The footer and the **By character** tab show when each bank was last read.
- **Other characters** show up after you log in on them once.
- Hover an item to see where it is and its price. Shift-click links it in chat.
- Hover any item in the game (bags, chat links, the auction house...) to see which of your characters have it. Counts for other characters are from the last time you logged in on them, and banks from the last time you opened them.
- In **By character**, right-click a character you deleted or transferred to forget it.

## Options
Click the gear in the window, right-click the minimap button, type `/hoard options`, or go to **Esc → Options → AddOns → Hoard Value**.

| Option | What it does |
|---|---|
| Count soulbound items | Off by default. Soulbound and warbound items can't go on the auction house, so when on they count at what a vendor pays. |
| Include the warband bank | Retail only. On by default. Adds the warband bank's gold and items to the account total, once. |
| Price addon | Automatic (TSM, then Auctionator for anything TSM has no price for), TSM only, or Auctionator only. |
| TSM price | Market value (default), lowest auction right now, historical price or region market average. |
| Realistic value | Off by default. Also a checkbox in the window. |
| Show minimap button | On by default. Drag the button to move it. `/hoard minimap` also hides or shows it. |
| Show amounts down to | Gold (default), silver or copper. |
| List items with no value | Off by default. Shows quest items, keys and other things nobody pays for. |
| Show who has it on item tooltips | On by default. Lists your characters that have the item, and the warband bank, on item tooltips. |
| Blank line on item tooltips | Above the Hoard Info lines (default), below them, both or none. |
| Window position: Reset | Puts the window back in the middle of the screen. |

## Notes
- Prices are looked up every time you open the window, so totals for other characters follow the market even if you haven't logged in on them.
- With Auctionator, prices come from your own auction house scans. With TSM, the TSM desktop app keeps them up to date.
- Not counted yet: mail, items you have listed on the auction house, and equipped gear.
