return [[
  2019-03-27:
      - [DO] Ore arranged into quadrants to allow for more controlled resource gathering.

  2019-03-30:
      - [DO] Uranium ore patch threshold increased slightly
      - [DO] Bug fix: Cars and tanks can now be placed onto ore!
      - [DO] Starting minimum pollution to expand map set to 650
          View current pollution via Debug Settings [F4] show-pollution-values,
          then open map and turn on pollution via the red box.
      - [DO] Starting water at spawn increased from radius 8 to radius 16 circle.

  2019-04-24:
      - [DO] Stone ore density reduced by 1/2
      - [DO] Ore quadrants randomized
      - [DO] Increased time factor of biter evolution from 5 to 7
      - [DO] Added win conditions (+5% evolution every 5 rockets until 100%, +100 rockets until biters are wiped)

  2020-09-02:
      - [DO] Destroyed chests dump their content as coal ore.

  2020-12-28:
      - [DO] Changed win condition. First satellite kills all biters, launch 500 to win the map.

  2021-04-06:
      - [DO] Rail signals and train stations now allowed on ore.

  2023-06-27:
      - [DO:LazyOne] Disabled Crafting
      - [DO:LazyOne] Added Starting Equipment

  2023-10-01:
      - [Do:K2] Added K2 preset

  2023-10-17:
      - [Do:Omni] Added Omnimatter presets

  2023-10-21:
      - [DO:BZ] Added BZ preset

  2023-10-23:
      - [DO:EI] Added EI presets

  2023-10-24:
      - [DO:IR3] Added IR3 presets
      - [DO:PYFE] Added PyFE preset

  2024-02-24:
      - [DO:Safety] Added Safety Ores preset
      - [Do:Scrap] Added Scrap preset

  2024-04-08:
      - [DO:Expanse] Forked from DO/terraforming
      - [DO:Expanse] Added DO/expanse
      - [DO:Expanse] Lowered tech multiplier 25 > 5

  2024-04-17:
      - [DO:Expanse] Fixed incorrect request computation
      - [DO:Expanse] Fixed persistent chests on new chunk unlocks
      - [DO:Expanse] Added chests for each new expansion border
      - [DO:Expanse] Reduced pre_multiplier from 0.33 >s 0.20

  2024-08-01:
      - [DO:Expanse] Fixed allowed entities list with Mk2-3 drills
      - [DO:Expanse] Fixed typos in description

  2024-11-22:
      - [DO] Updated scenarios to 2.0
      - [DO] Added compatibility with AAI Loaders mod
      - [DO] Added compatibility with Deadlock Stacked Beltboxes and Loaders mod
      - [DO] Added compatibility with Early Construction mod
      - [DO] Added compatibility with REdMew Data mod
      - [DO] Added module to prevent quality miners from being placed on ore
      - [DO] Added module to replace mining productivity effects with robot cargo size instead
      - [DO] Removed deadlock's custom scenario forks
      - [DO] Updated map poll list
      - [DO] Updated rocket launches requirement to win at 1000 for most presets
      - [DO] Updated technology multiplier to x25 for most presets
      - [DO] Updated terraforming for most presets

  2024-11-27:
      - [DO] Enabled presets: PyShort, Omnimatter (x2), and Scrap
      - [DO] Changed default permissions to allow blueprints

  2024-12-01:
      - [DO:XCross] Added X-Cross preset
      - [DO:Permanence] Added Permanence preset

  2025-01-13:
      - [DO] Added quality settings to rocket launched goals
      - [DO:Permanence] Increased manual mining speed to +900%

  2025-01-14:
      - [DO:CoalMaze] Added Coal Maze preset

  2025-02-19:
      - [DO:OneDirection] Fixed terraforming bounds
      - [DO:OneDirectionWide] Fixed terraforming bounds

  2025-05-09:
      - [DO:Krastorio2] Updated to 2.0

  2025-08-04:
      - [DO] Fixed error when displaying total ore mined to discord
      - [DO] Fixed an error with allowed_entities module
      - [DO] Updated "trees" and "enemy" modules
      - [DO] Removed ore breakdown, only total amount is displayed instead
      - [DO] Removed custom surface from base scenario
      - [DO:SpaceAge] Added DO/SpaceAge

  2025-09-02:
      - [DO:Collapse] Added Collapse preset

  2025-09-14:
      - [DO] Added dominant stone patches to heavy coal presets
      - [DO:SA] Fixed jellunut and yumako progression softlock
      - [DO:SA] Removed ore-voiding recipes from recyclers
      - [DO:K2] Fixed rare metals and yellowcake pictures scaling
      - [DO:K2] Removed ore-voiding recipes from crushers

  2026-01-05:
      - [DO] Reverted ore stack size to default (50)
      - [DO] Infinite tech cost does not scale with technology multiplier
      - [DO:AB] Added DO/AngelBob preset
      - [DO:AM] Added DO/Angels preset
      - [DO:BM] Added DO/Bobs preset

  2026-02-05:
      - [DO] Fixed grid factory presets starting area not rendering correctly
      - [DO] Fixed autodeconstruct not waiting for mining drills to output last ores
      - [DO:Gridlocked] Added DO/Gridlocked preset
      - [DO:Expanse] Updated DO/Expanse to 2.0
      - [DO:Safety] Updated DO/Safety to 2.0

  2026-02-18:
      - [DO] Added 1x1 loaders
      - [DO] Added ore radioactivity
      - [DO] Added reskins for advanced factory (thanks Kirazy)
      - [DO] Added vibrant colors to entities with player color masks
      - [DO] Added technology milestones
      - [DO] Added Deep-house chest
      - [DO] Turn OFF always day mode
      - [DO] Rebalanced solar energy production and rocket recipes
      - [DO] Rebalanced increased copper consumption early game
      - [DO] Removed 1x2 loaders
      - [DO] Removed Memory unit mod
      - [DO] Removed ore stack changes
      - [DO] Removed robots cost multipliers
      - [DO:JK] Added DO/Joker preset
      - [DO:JK] Added biters drop resources

  2026-06-14:
      - [DO] Disabled radioactivity by default, expect for Joker preset

  2026-07-06:
      - [DO:Tetrominoes] Added DO/Tetrominoes preset
      - [DO:Voronoi] Added DO/Voronoi preset

  2026-07-07:
      - [DO:ScrapMaze] Added DO/Scrapworld-Maze preset
      - [DO:OmniMaze] Added DO/Omnimatter-Maze preset
 
  2026-07-01:
      - [DO] Updated for Factorio 2.1 compatibility
      - [DO] Rewrote biters-drop-resources loot to new ItemProductPrototype format
      - [DO] Fixed MineEntityTechnologyTrigger entity field renamed to entities (array) in milestones triggers
      - [DO:SA] Replaced removed "chemistry-or-cryogenics" recipe category with categories = {"chemistry", "cryogenics"} in coal-gasification
      - [DO:SA] Replaced custom solar-system-edge-discovery technology with a modified vanilla stellar-discovery-solar-system-edge
      - [DO:SA] Updated coal-gasification recipe unlock to reference stellar-discovery-solar-system-edge
      - [DO:SA] Fixed MineEntityTechnologyTrigger entity field renamed to entities (array) in holmium-processing triggers
      - [DO:SA] Fixed startup crash from invalid decorative name 'fulgoran-gravewort'
      - [DO:SA] Fixed startup crash from dangling unlock-recipe effects left by removed ore-recycling recipes
      - [DO:Scrap] Fixed danger-ores package dependency: replaced obsolete 'quality' mod with 'recycler'
]]
