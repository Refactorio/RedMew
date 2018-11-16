## Diggy Installation and Configuration
Diggy is a custom [RedMew](../../README.md) scenario. You start out with nothing but a market, your pick-axe and some
walls [deep, deep in the mine](https://www.youtube.com/watch?v=ov5pxaIbJlM). The goal is to launch a rocket, but be
careful, there's not a lot of space and the mine is unstable!

- Gameplay: https://www.youtube.com/watch?v=J3lheDK-6Cw
- Time lapse video: https://www.youtube.com/watch?v=4cRsx-wl_fk (By Namelesshunter Gaming)

> _Note_: Scenarios- also known as soft-mods- are scripted maps. They can be played online without having to download
any mods as the script is included in the map.

### Scenario Information
The idea of Diggy is similar to vanilla, except that it greatly changes how to build your factory. As you're in a cave,
each rock you dig, each support entity you remove and every tile you mine, can cause a collapse. You can use walls,
stone paths and (refined) concrete floor to increase the strength of your mine and reduce the chance of a collapse.

Whenever you place or remove a wall for example, the stress level of the area around it (9x9 tiles) will rise or lower.
When a certain threshold is reached, the cave will collapse. You can stop this by quickly placing walls or run away as
fast as you can. Letting the cave collapse _will_ destroy structures below it! The recommended pattern on dirt is to
place a wall every 4th tile. Using stone paths and concrete will increase this to 5 tiles while refined concrete will
make it 6.

## How to start Diggy for Single-player mode

#### Step 1
Download the zip file from
[https://github.com/Valansch/RedMew/archive/develop.zip](https://github.com/Valansch/RedMew/archive/develop.zip)

#### Step 2
- **Windows**: extract the the zip file into `%appdata%\Factorio\Scenarios\Diggy`
- **MacOS**: extract the the zip file into `~/Library/Application Support/factorio/Scenarios/Diggy`
- **Linux**: extract the the zip file into `~/.factorio/scenarios/Diggy`

Make sure it's called Diggy and there's a `control.lua` in the root of that directory.

> _Note_: these locations are based on the default configuration [defined by
factorio](https://wiki.factorio.com/Application_directory). If your installation is not default, you have to find your
scenarios directory in another way.

#### Step 3
Open `map_layout.lua` in that directory and look for `--require "map_gen.combined.diggy"`.
Change this to `require "map_gen.combined.diggy"`, by removing the double dashes.

#### Step 4
In factorio start either a local or online game via Scenarios. Select `Diggy` under
`User scenarios` and start it up.

> _Note:_ Downloading the latest version might not always be a functional version, please consult on discord for a
working version if this is the case.

#### Step 5 (optional)
Diggy is designed to work for at least 15 players online, working together. It's advised to change the configuration
to adjust the difficulty for your needs. You can find the config in `map_gen/Diggy/Config.lua`. Most options should be
well-explained. For Single-player it's recommend to enable cheats with modified values. You can change the starting
items and some pre-defined cheat values (if cheats are enabled) under the `SetupPlayer` config item.

You can turn off certain features if you wish.
 - DiggyCaveCollapse, disable this feature if you wish to play without collapses.
 - SimpleRoomGenerator, disable this if you want to play without room generation. _**WARNING:** this is the mechanic
 that spawns water._
 - AlienSpawner, disable this if you wish to disable spawning biters and spitters when mining.
 - ScatteredResources, used to tweak random resource spawning.
 - MarketExchange, regulates all the market related features.
