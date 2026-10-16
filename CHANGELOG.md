# Changelog

## 1.1.7
- Gray junk now always counts at what a vendor pays for it, never at its auction house price, so a few overpriced junk listings can't inflate your total.

## 1.1.6
- Fixed: a material slot on a recipe or crafting order could leave out a rank you own, showing only rank 1 while rank 2 sat in your bags. This happened when the game hadn't loaded that item's name yet when your bags were scanned. Every rank you own now shows.

## 1.1.5
- Fixed: on WoW Forever, characters were saved under their first name only, so the window, tooltips and minimap button showed just the first name, and two characters with the same first name shared one entry. They now show by their full name. Characters you already have move over to it the next time you log in on them.

## 1.1.4
- Items in the Hoard Value window now show the same Hoard Info lines as every other item tooltip (which characters have it, in their bags or bank, plus the warband bank), followed by the item's price. They show there even with the tooltip option off.

## 1.1.3
- Hoard Info and ranks: an item's tooltip now shows only the rank you're hovering. A material slot on a recipe or crafting order still shows every rank you own, rank 1 first.

## 1.1.2
- Fixed: Hoard Info showed nothing on a material or crafted item when you only owned a different quality of it. Hovering any quality now lists every quality you own, one line per character and quality, with its quality icon.

## 1.1.1
- The minimap button now works with minimap button collectors, and drags around the minimap like other addons' buttons. It stays where you put it.
- /hoard minimap hides or shows the minimap button.

## 1.1.0
- Hoard Info on item tooltips: hover any item to see which of your characters have it and how many, with a bag icon for what's in their bags and a bank icon for what's in their bank. The warband bank gets its own line, and a total shows when the item is in more than one place.
- New options: turn the tooltip lines off, and choose where a blank line goes to set them apart from the rest of the tooltip (above, below, both or none).

## 1.0.2
- Fixed: warbound and Battle.net account-bound items (including "Warbound until equipped") were valued at their auction price even though they can't be sold. They now count as bound, like soulbound items. Items that drop as BoE in one place and warbound in another are checked copy by copy.

## 1.0.1
- Fixed: items the game hadn't loaded yet when your bags were scanned showed as raw link text, or as just a quality icon, instead of their name. Their names now load in after a moment.

## 1.0.0
- First release.
- Net worth of your character and your account: gold, bags, bank and warband bank (items and gold).
- Report window with three tabs (this character, account, by character), an item list sorted by value, sortable columns and search.
- Prices from TradeSkillMaster, falling back to Auctionator, then vendor price.
- Realistic value mode: lower of market and lowest auction, minus the 5% auction house cut.
- Soulbound items left out by default, with an option to count them at vendor price.
- Minimap button with a quick total on hover, addon compartment entry, and `/hoard`.
- Works on Retail, Mists of Pandaria Classic, TBC Anniversary, WoW Forever and Classic Era, including Season of Discovery (no warband bank on Classic).
