# Hoard Value: CurseForge upload sheet

What to type into each CurseForge field, ready to copy and paste. The steps for a first upload and for releasing an update are in [UPLOADING.md](../UPLOADING.md).

Update this sheet with every release: the zip, the display name and the changelog, and rewrite the description so it covers everything in the new version. The release script won't publish until the zip, display name and changelog name the new version.

## A. Project form

**Project name**
```
Hoard Value
```

**Summary**
```
What your character and account are really worth in gold: bags, bank and warband bank, priced with TSM or Auctionator.
```

**Main category:** `Auction & Economy`
**Additional categories:** `Bags & Inventory`

**License:** `MIT License`

**Logo / avatar:** `HoardValue\images\logo-v2.png` (a coin bag spilling gold coins, with a price tag showing a rising chart)

**Description** (paste everything between the lines)

---
```markdown
## What is your hoard really worth?

Hoard Value adds up everything you own and tells you, in gold, what your character and your whole account are worth: your gold plus every item in your bags, bank and warband bank, priced with **TradeSkillMaster** or **Auctionator**.

### Your net worth at a glance
- One big total, split into **gold, bags, bank and warband bank**.
- **This character**, **Account** and **By character** tabs.
- Hover the minimap button for your totals.

### Every item, most valuable first
Sort by any column, search by item name, and right-click an item to destroy it, after a confirmation. **List every item** adds soulbound and warbound items too.

### Who has it? Right on the tooltip
Hover any item and **Hoard Info** shows which of your characters have it and how many, in bags, bank or warband bank.

### Your bags' value in your bag window
What your bags are worth shows at the bottom of the game's own bag window, next to your gold. Bag addons that replace the game's bags don't show it.

### What you pick up is worth
Loot an item, or get handed one, and a chat line only you see says what it's worth. Set a minimum value to hear only about the good finds. Soulbound items are only mentioned when you count them.

### Realistic value
What you'd actually get: each item at the lower of its market value and the cheapest auction, minus the 5% cut.

### Soulbound items
Soulbound and warbound items can't be auctioned, so they're left out by default. Turn them on to count them at vendor price.

### Retail and Classic
Works on **Retail**, **Mists of Pandaria Classic**, **TBC Anniversary**, **WoW Forever** and **Classic Era** (including Season of Discovery and Hardcore).

### How to use
1. Click the coin button on the minimap, or type **/hoard**.
2. Log in and visit a banker once on each character.

### Good to know
- Uses TSM first, then Auctionator. Gray junk and items with no auction price count at vendor price.
- With TSM, choose the price: market value, lowest auction, or the lower of the two.
- Not counted yet: mail, your auctions and equipped gear.
- After an update, a What's New window shows what changed.

This addon was made with AI.

**Feedback and bug reports are welcome** in the comments.
```
---

**Source / Issues links:** leave empty unless you put the code on GitHub.

## B. Upload File form

**File:** `dist\HoardValue-1.5.1.zip`

**Display name**
```
Hoard Value 1.5.1
```

**Release type:** `Release`

**Game versions:** Retail `12.1.0` and `12.1.5`, Mists of Pandaria Classic `5.5.4`, TBC Anniversary `2.5.6`, WoW Forever `1.60.1` (if CurseForge lists it yet), Classic Era `1.15.9` (covers Season of Discovery).

**Changelog** (paste only the newest part; 1.0.0 is already on CurseForge)
```markdown
1.5.1
- Fixed on WoW Forever: a character could show twice, once with its realm and once without, so its items and gold were counted twice in Hoard Info and in your account total. This happened when the game didn't give the realm's name at login. The two become one again the next time you log in on that character.

1.5.0
- **Lower of market and lowest:** a new choice under TSM price in the options. Each item counts at TSM's market value or the lowest auction right now, whichever is lower, so nothing counts for more than it's listed for.

1.4.1
- Fixed: after you opened Hoard Value's options, the game's own options could show the error "AddOn 'HoardValue' tried to call the protected function 'IsUserOAuthed()'".

1.4.0
- **Bags value in your bag window:** what the items in your bags are worth now shows at the bottom of the game's own bag window, left of your gold. Hover it for this character's total, click it to open Hoard Value. Bag addons that replace the game's bags don't show it.
- **What you pick up is worth:** when you loot an item or are handed one, a chat line only you see says what it's worth, with the price of each for a stack. A new option sets a minimum value, so only the good finds are mentioned. Soulbound items are only mentioned with Count soulbound items on.
- Both are on by default and can be turned off in the options.

1.3.2
- Fixed on WoW Forever: items in your reagent bag were counted as bank instead of bags, your keyring was counted as bank, and bank tabs after the fifth weren't counted. Open your bank once on each Forever character to clear the old bank count.

1.3.1
- Fixed an error when opening the options during combat ("tried to call the protected function 'OpenSettingsPanel()'"). The options now open as soon as the fight ends.

1.3.0
- **Destroy items from the list:** right-click an item and choose Destroy. After you confirm, it destroys the copies in your bags, and in your bank or warband bank while one is open. Copies on other characters stay. An item in several stacks asks once per stack, since the game destroys one stack at a time.

1.2.2
- Search in the item list now matches item names only. Typing "bag" finds your bags, not every item kept in your bags.

1.2.1
- Fixed: typing in the search box of the game's options (Esc > Options) could show the error "AddOn 'HoardValue' tried to call the protected function 'IsUserOAuthed()'". The window position's Reset button no longer comes up in that search; it's still on Hoard Value's options page.

1.2.0
- **List every item:** a new option lists everything in your bags and banks, including soulbound and warbound items and items with no value, so you can search all of it. Bound items show their vendor price, and your totals don't change unless Count soulbound items is on.
- Search now finds an item by character name even when it's spread across many places. Before, an item on three or more characters could be missed.
- After an update, a What's New window shows what changed since the version you had.

1.1.7
- Gray junk now always counts at what a vendor pays for it, never at its auction house price, so a few overpriced junk listings can't inflate your total.

1.1.6
- Fixed: a material slot on a recipe or crafting order could leave out a rank you own, showing only rank 1 while rank 2 sat in your bags. This happened when the game hadn't loaded that item's name yet when your bags were scanned. Every rank you own now shows.

1.1.5
- Fixed: on WoW Forever, characters were saved under their first name only, so the window, tooltips and minimap button showed just the first name, and two characters with the same first name shared one entry. They now show by their full name. Characters you already have move over to it the next time you log in on them.

1.1.4
- Items in the Hoard Value window now show the same Hoard Info lines as every other item tooltip (which characters have it, in their bags or bank, plus the warband bank), followed by the item's price. They show there even with the tooltip option off.

1.1.3
- Hoard Info and ranks: an item's tooltip now shows only the rank you're hovering. A material slot on a recipe or crafting order still shows every rank you own, rank 1 first.

1.1.2
- Fixed: Hoard Info showed nothing on a material or crafted item when you only owned a different quality of it. Hovering any quality now lists every quality you own, one line per character and quality, with its quality icon.

1.1.1
- The minimap button now works with minimap button collectors, and drags around the minimap like other addons' buttons. It stays where you put it.
- /hoard minimap hides or shows the minimap button.

1.1.0
- Hoard Info on item tooltips: hover any item to see which of your characters have it and how many, with a bag icon for what's in their bags and a bank icon for what's in their bank. The warband bank gets its own line, and a total shows when the item is in more than one place.
- New options: turn the tooltip lines off, and choose where a blank line goes to set them apart from the rest of the tooltip (above, below, both or none).

1.0.2
- Fixed: warbound and Battle.net account-bound items (including "Warbound until equipped") were valued at their auction price even though they can't be sold. They now count as bound, like soulbound items. Items that drop as BoE in one place and warbound in another are checked copy by copy.

1.0.1
- Fixed: items the game hadn't loaded yet when your bags were scanned showed as raw link text, or as just a quality icon, instead of their name. Their names now load in after a moment.

1.0.0 - First release.
- Net worth of your character and your account: gold, bags, bank and warband bank (items and gold).
- Report window with three tabs (this character, account, by character), an item list sorted by value, sortable columns and search.
- Prices from TradeSkillMaster, falling back to Auctionator, then vendor price.
- Realistic value mode: lower of market and lowest auction, minus the 5% auction house cut.
- Soulbound items left out by default, with an option to count them at vendor price.
- Minimap button with a quick total on hover, addon compartment entry, and /hoard.
- Works on Retail, Mists of Pandaria Classic, TBC Anniversary, WoW Forever and Classic Era, including Season of Discovery (no warband bank on Classic).
```

**Related projects:** add both as **Optional Dependency**:
- `TradeSkillMaster`
- `Auctionator`
