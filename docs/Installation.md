## Installing and Using the RedMew Scenario
Some scenarios have more detailed information, please check [the index](Index.md) before continuing with the generic
RedMew installation. To install the RedMew scenario directly into something playable, [download the
archive](https://github.com/Valansch/RedMew/archive/develop.zip) and take the next step based on your Operating System.

- **Windows**: extract the the zip file into `%appdata%\Factorio\Scenarios\RedMew`
- **MacOS**: extract the the zip file into `~/Library/Application Support/factorio/Scenarios/RedMew`
- **Linux**: extract the the zip file into `~/.factorio/scenarios/RedMew`

Make sure it's called RedMew and there's a `control.lua` in the root of that directory. If you are using the RedMew
scenario for a public-facing multi-player server, be sure to provide attribution back to github and keep links to the
Discord, Patreon and website intact.

> _Note_: these locations are based on the default configuration [defined by
factorio](https://wiki.factorio.com/Application_directory). If your installation is not default, you have to find your
scenarios directory in another way.

## Generating maps
There are 3 ways to generate maps using our scenario: Vanilla, FactorioMapConverter and Custom Maps.

### Vanilla
Start the scenario from the scenario menu and you are ready to go. Additionally you can turn features on or off via
[`control.lua`](../control.lua) if desired.

### Custom Maps
There are many pre-made map modules that can be combined to create a unique map.

Map module previews can be found in [map_gen/data/.map_previews](../map_gen/data/.map_previews). You can select and
activate a module by removing the `--` in front of the require in [`map_layout.lua`](../map_layout.lua).

You can mix as many modules as you want, as long as they logically fit together.

### FactorioMapConverter (Windows only)

You can generate your own maps from images. First convert the image file into a lua file (For example `image_data.lua`).
Then use our scenario to load the `image_data.lua` file and generate the map from it.

To create your own map preview:
1. Download the Map Converter [here](https://github.com/grilledham/FactorioMapConverter/releases) to generate the
   `image_data.lua`.
2. Place your `image_data.lua` file in the `map_gen/data/presets/` directory.
3. Create new lua file (for example `my_image.lua`) inside the folder `map_gen/presets/`. This file is used to configure
   your map (scale, translate etc.). To do this, you can copy `map_gen/presets/template.lua` and replace line 8 to point
   to your `image_data.lua`
4. Load your new preset by adding a new line to `map_layout.lua`. This should look similar to this:
    ```lua
    MAP_GEN = require "map_gen.presets.my_image.lua"
    ```
5. Load the scenario from the scenario menu.
