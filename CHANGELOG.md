# Change Log

All notable changes to this project will be documented in this file.

## Next version

### Features
- [Core] Change /find-player to /find #417
- [Core] Using `/regular <name>` now defaults to promoting the player. #417
- [Diggy] Added new formula to calculate experience requirement for next level #402
- [Diggy] Added health bonus on level up #402
- [Diggy] Added new level system to replace stone sent to surface #402
- [Diggy] Mining rocks no longer gives stone or coal #402
- [Diggy] Added particles when a biter mines a rock upon spawning #424
- [Diggy] Added bot mining #434
- [Map] Add Tetris map #433
- [Map] Add World Thanksgiving map #433
- [Diggy] Added bot mining levels and rock mining/destruction particles #442

### Bugfixes
- [Diggy] Stones killed by damage no longer spill. #395
- [Core] Fix /kill non-functional if walkabout is disabled. Fix walkabout giving from variable definition. #425
- [Diggy] Improved biter spawning algorithm #408
- [Core] Fix null reference in chat_triggers #431
- [Core] Fix nil ref in train_station_names #441

### Internal
- [Core] Cleanup of code formatting. #413 #415 #414 #412 #411
- [Core] Establishment of a style guide. #396
- [GitHub] Add stickler_ci #435
- [Core] Add server print on admin_prints #430

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
