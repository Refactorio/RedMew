# Change Log

All notable changes to this project will be documented in this file.


## In development


### Features
- [Map/Core] Overhauled day_night_cycle, creep_spread, and nightfall. Add Venus map. #524
- [Core] Added builders.circular_pattern #514
- [Diggy] Ore tendril pattern with slight impurities #528
- [Core] Added a command-search command #530
- [Core] Added particle limits and scales #504
- [Core] Docs into wiki #510
- [Diggy] Improved Biter aggression and scales a bit higher #498
- [Map] Added spiral_crossings map preset. #508
- [Map] Added 'rotten_apples' map preset and supporting files. #494
- [Diggy] Added a crumbling effect from the ceiling when close to collapse #478
- [Core] Add core cheats #490
- [Diggy] Added big rocks to the table #489
### Bugfixes
- [Core] Fix car body directions #521
- [Diggy] Fixed some bugs and tweaked some balance #520
- [Diggy] Fixed duplicate big rock and missing huge rock #497
- [Core] Minor fixes in the config #499
- [Diggy] Balancing changes #481
- [Diggy] Fixed a bug related to player index missing #483
- [Diggy] Lowered uranium density in main vein #479
### Internal
- [Diggy] Cleaned up some diggy commands and the left-overs register in _DEBUG #522
- [Core] Added the crash-site GUI features to the retailer #523
- [Core] Gave the player_create feature the same as diggy SetupPlayer #529
- [Core] Added a basic RedMew configuration setup #502
- [Core] Server time #487
- [Core] Add inspect and size to table util #492
- [Map] Removed the old cave_miner #500
- [Core] Added a new command wrapper #443
- [Core] Overhaul utils and add minor functionality #464
- [Core] Add ability to push time from server to factorio #487
- [Core] Ban sync #476

## v1.1.0 - Persian Longhair

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
- [Diggy] Bot mining experience #447
- [Core] Added a Market Retailer to manage the market contents of market groups #461

### Bugfixes
- [Diggy] Stones killed by damage no longer spill. #395
- [Core] Fix /kill non-functional if walkabout is disabled. Fix walkabout giving from variable definition. #425
- [Diggy] Improved biter spawning algorithm #408
- [Core] Fix null reference in chat_triggers #431
- [Core] Fix nil ref in train_station_names #441
- [Diggy] Fixed a bunch of performance issues and bugs in Diggy #470
- [Diggy] Fixed antigrief desyncs #467
- [Core] Fix walkabout case of player with no character #474

### Internal
- [Core] Cleanup of code formatting. #413 #415 #414 #412 #411
- [Core] Establishment of a style guide. #396
- [GitHub] Add stickler_ci #435
- [Core] Add server print on admin_prints #430
- [Core] Overhaul config and global.scenario usage #466
- [Core] Add new server module #469
- [Core] Restructured chat_trigger functions #465

## v1.0.0 - Maine Coon

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
