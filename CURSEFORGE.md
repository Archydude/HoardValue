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

**Logo / avatar:** `HoardValue\images\logo-under-100kb.png` (the treasure chest; `HoardValue\images\logo-bag-under-100kb.png` is the coin bag alternative)

**Description** (paste everything between the lines)

---
```markdown
## What is your hoard really worth?

Hoard Value adds up everything you own and tells you, in gold, what your character and your whole account are worth: your gold plus every item in your bags, bank and warband bank, priced with **TradeSkillMaster** or **Auctionator**.

### Your net worth at a glance
- One big total, split into **gold, bags, bank and warband bank**.
- **This character**, **Account** and **By character** tabs.
- Hover the minimap button for your totals without opening anything.

### Every item, most valuable first
Everything you own in one list, sorted by value. Sort by any column, search by name or place, and hover an item to see who has it and what it's worth.

### Who has it? Right on the tooltip
Hover any item, anywhere in the game, and **Hoard Info** shows which of your characters have it and how many, in their bags, their bank or the warband bank.

### Realistic value
Market prices are optimistic. Turn on **Realistic value** to see what you'd actually get: each item at the lower of its market value and the cheapest auction, minus the 5% auction house cut.

### Honest about soulbound items
Soulbound and warbound items can't be sold on the auction house, so they're left out by default. Turn them on to count them at vendor price.

### Retail and Classic
Works on **Retail**, **Mists of Pandaria Classic**, **TBC Anniversary**, **WoW Forever** and **Classic Era** (including Season of Discovery and Hardcore).

### How to use
1. Click the coin button on the minimap, or type **/hoard**.
2. Visit a banker once on each character, so Hoard Value can see what's there.
3. Log in on your other characters once so they count toward the account total.

### Good to know
- Uses TSM first, then Auctionator. Items without an auction price count at vendor price, and without either addon only vendor prices are used.
- Other characters' items are from the last time you logged in on them, and banks from the last time you opened them.
- Not counted yet: mail, your auctions and equipped gear.
- Options: the gear in the window, or **/hoard options**.

**Feedback and bug reports are welcome** in the comments.
```
---

**Source / Issues links:** leave empty unless you put the code on GitHub.

## B. Upload File form

**File:** `dist\HoardValue-1.1.4.zip`

**Display name**
```
Hoard Value 1.1.4
```

**Release type:** `Release`

**Game versions:** Retail `12.1.0` and `12.1.5`, Mists of Pandaria Classic `5.5.4`, TBC Anniversary `2.5.6`, WoW Forever `1.60.1` (if CurseForge lists it yet; it launches November 4), Classic Era `1.15.9` (covers Season of Discovery).

**Changelog** (paste only the newest part; 1.0.0 is already on CurseForge)
```markdown
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
