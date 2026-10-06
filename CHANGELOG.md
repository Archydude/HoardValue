# Changelog

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
