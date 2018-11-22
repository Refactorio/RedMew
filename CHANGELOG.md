# Change Log

All notable changes to this project will be documented in this file.

## Next version

### Features

### Bugfixes
- [Diggy] Stones killed by damage no longer spill. #395
- [Core] Fix /kill non-functional if walkabout is disabled. Fix walkabout giving from variable definition. #425
- [Core] Fix null reference in chat_triggers #431

### Internal
- [Core] Cleanup of code formatting. #413 #415 #414 #412 #411
- [Core] Establishment of a style guide. #396 

## v1.0.0

### Features
- [GUI] When admins click the "Report" button in the player list it now jails the player.  #399
- [Core] Better buff descriptions in market. #389
- [Core] Using the `@` or `#` symbol before or after someone's name now notifies that person. #387
- [Diggy] Iron axe added to market. #385

### Bugfixes
- [Core] Players who die or disconnect with market buffs no longer keep the buffs on their return. #404
- [Core] Players on walkabout are no longer trapped when they die or log out. #398
- [Diggy] Fixed room loot spill. #388
- [Diggy] Big rocks spawning multiple ores. #384

### Internal
- [Core] Windows line endings converted to unix. #393
- [Core] Changed how commands are logged. #386
