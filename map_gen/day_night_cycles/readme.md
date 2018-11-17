In terms of daylight during the day/night cycle:

when dusk begins the light decreases until
evening (aka nighttime) which is full darkness until
morning which increases the light level until
dawn (aka daytime) which is full brightness until dusk

Defaults as follows:
ticks_per_day=25000 (approx 6 mins 56.4 secs)
dusk=0.25, evening=0.45, morning=0.55, dawn=0.75

If you keep your numbers < 1 , it's the percentage
of the total ticks at which the phase of day will change
Not sure what happens if you go > 1

When setting these variables, the command will fail if it changes
the *order* of the phases. Ex: morning must be > evening but < dawn

Lastly, the map starts at time tick 0 so if you want to start during full
daylight you want a dusk > 0
