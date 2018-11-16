## Creating a New Scenario Using the RedMew Framework
To add a new scenario and make it available to everyone that wants to use RedMew, make a Pull Request on github to
request adding your scenario to the repository.

### Starting From Scratch
Depending on the size of the scenario, it could be desired to have its own dedicated directory. By default a scenario
is added in `map_gen/combined/your_scenario.lua`.

#### Step 1
If you're not experienced with git, it's advised to read up on how git works first or ask someone else to help out. To
get your change into the repository, you need to [fork the repository](https://help.github.com/articles/fork-a-repo/)
and eventually make your Pull Request from there. [Clone](https://help.github.com/articles/cloning-a-repository/) the
fork to your local environment and get your favorite IDE or Editor ready.

#### Step 2
Small scenarios can go into a single lua file, bigger scenarios might need their own dedicated directory. To follow the
RedMew structure for scenarios, create your scenario file: `map_gen/combined/your_scenario_file.lua`.

#### Step 3 (Optional)
If you plan on making a bigger scenario, create a directory: `map_gen/combined/your_scenario_file/` where you can place
your scenario specific lua files.

#### Step 4
Regardless, the `map_gen/combined/your_scenario_file.lua` file will be the entry point for your scenario and will be
loaded via `map_layout.lua`. Underneath `--combined--`, add your require: `require map_gen.combined.your_scenario_file`.

When making the Pull Request, make sure to comment the require in `map_layout.lua` as by default it should be off. To
enable debugging and get some extra feedback during development, enable `_DEBUG` in `config.lua`.
