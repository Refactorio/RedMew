## How to start Diggy

##### Step 1
Download the zip file from https://github.com/Valansch/RedMew/archive/develop.zip

##### Step 2
On Windows: extract the the zip file into `%appdata%\Factorio\Scenarios\Diggy`, 
make sure it's called Diggy and there's a `control.lua` in the root of that directory.

##### Step 3
Open `map_layout.lua` in that directory and look for `--require "map_gen.combined.diggy"`.
Change this to `require "map_gen.combined.diggy"`, by removing the double dashes.

##### Step 4
In factorio start either a local or online game via Scenarios. Select `Diggy` under
`User scenarios` and start it up.
