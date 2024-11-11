This is an edit and reupload of Cosminpop's LootRes addon with focus on compatability with Raidres on TurtleWOW. Credit to Cosminpop for the original addon.

Changes:
- LootLC component fully removed.
- Rolling functionallity of addon removed.
- ~~Made a small improvement to the creation of table for reserves. 2SR+ now properly works, player's second SR has an "S" appended to the end.~~

Forked Changes:
- Added SR+ system for LootRes.
- Added SR looted history.
- Added SR announcement when any player type in the chat: "[Item] SR".
- Fixed Duplicate SR, Double SR, and so on.

Commands for the addon:
```lua
/lootres load -- Load parsed data from raidres.fly.dev
/lootres delete -- Delete loaded SR data from LootRes
/lootres announce 0 -- Disable feature for announce SR in raid chat
/lootres announce 1 -- Enable feature for announce SR in raid chat
/lootres print -- Print loaded SR data
/lootres raidprint -- Print loaded SR data in the raid chat
/lootres log -- Print SR looted history
/lootres raidlog -- Print looted history in the raid
/lootres reset -- Reset SR looted history
/lootres excel -- Show textbox with SR looted history
/lootres view PlayerName -- View SR for Player
/lootres clear PlayerName -- Remove SR for Player
```

Usage for SR (get your parsed data from raidres.fly.dev):
```lua
/lootres load
/lootres reset
```


Usage for SR+, needed my chrome extension [https://github.com/asyncwithsky/RaidRes-extractor]:
```lua
/lootres load
/lootres reset
```