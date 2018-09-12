# RedMew Scenario

## Getting Started

To use our scenario download it [here](https://github.com/Valansch/RedMew/archive/develop.zip) and unzip it into %AppData%/factorio/scenarios/ (~/.factorio/scenarios for linux). If you are using our scenario for a public-facing multiplayer server, please be sure to provide attribution back here to the github and keep links to our discord/patreon/website intact. 

## Generating maps

  There are 3 ways to generate maps using our scenario: Vanilla, FactorioMapConverter and Custom Maps.
  
### Vanilla
  Just start the scenario from the scenario menu and you are ready to go.

### Custom Maps

  We have many premade map modules that you can combine to create a unique map.
  
  Checkout [map_gen/data/map_previews](https://github.com/Valansch/RedMew/tree/develop/map_gen/data/.map_previews) to view all our modules.
  You can select and activate a module by removing the "--" infront of the module in the map_layout.lua file.

  You can mix as many modules as you want, as long as they logically fit together. 

  Futher instructions on this read the comments in the map_layout.lua file.
### FactorioMapConverter

You can generate your own maps from images. This works in 2 steps:

First convert the image file into a lua file (For example image_data.lua). Then use our scenario to loa the image_data.lua file and generate the map from it.

To achieve this please follow these steps:
1. Download the Map Converter [here](https://github.com/grilledham/FactorioMapConverter/releases) (Windows only) to generate the image_data.lua.
2. Place your image_data.lua file in the folder /map_gen/data/presets/
3. Create new lua file (for example my_image.lua) inside the folder map_gen/presets/. This file is used to configure your map (scale, translaten etc.)      
To do this you can copy map_gen/presets/template.lua and replace line 8 to point to your image_data.lua
4. Load your new preset by adding a new line to map_layout.lua. This should look similar to this:  
```MAP_GEN = require "map_gen.presets.my_image.lua"```
5. Load the scenario from the scenario menu.
  
  
  
  
  
