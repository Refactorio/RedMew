-- A part of band.lua
-- Feel free to edit.

return {

["to_print"] = {
 -- "%name now in the [%band] group.",
  "%name has joined the [%band] party.",
  "%name is now supporting the [%band] party."  
},

["roles"] = {

  ["Trooper"] = {
    "item/tank",	
    tooltip = {
      "Incoming!!!",
      "If the facts don't fit the theory, change the facts.",
      "I suppose it is tempting, if the only tool you have is a hammer, to treat everything as if it were a nail.",
      "There's a fine line between genius and insanity. I have erased this line."
    },
    verbs = {
      "strengthened",
    }
  },
    
  ["Mining"] = {
    --"item/steel-axe",
    "item/iron-axe",
   -- "item/iron-ore",
   -- "item/copper-ore",
    tooltip = {
      "Mine or not to mine", 
      "The nation behaves well if it treats the natural resources as assets which\n it must turn over to the next generation increased, and not impaired, in value."
    },
    verbs = {
      "enriched"
     -- "smelted"
    }
  },
  
  ["Smelting"] = {
    --"item/assembling-machine-1",
    "item/steel-furnace",
    --"item/assembling-machine-3",
    --"item/inserter",
    --"item/stack-inserter",
    tooltip = {
      "Mirrors are ice which do not melt: what melts are those who admire themselves in them.",
	  "It's as certain that as long as fossil fuels are the cheapest energy, we will just keep burning them."	  
      },
	 verbs = {
      "fused"
    }
  },
  
  ["Production"] = {
    "item/assembling-machine-1",
    "item/assembling-machine-2",
    "item/assembling-machine-3",
    --"item/inserter",
    --"item/stack-inserter",
    tooltip = {
      "When every physical and mental resources is focused, one's power to solve a problem multiplies tremendously.",
      "The production of too many useful things results in too many useless people. ",
      "Everything must be made as simple as possible. But not simpler."
    },
    verbs = {
      "enhanced"
    } 
  },
  
  ["Science"] = {
    "item/science-pack-1",
    "item/science-pack-2",
    "item/science-pack-3",
    "item/military-science-pack",
    "item/production-science-pack",
    "item/high-tech-science-pack",
    "item/space-science-pack",
    tooltip = {
      "Science without religion is lame, religion without science is blind",
      "If we knew what it was we were doing, it would not be called research, would it?",
      "Somewhere, something incredible is waiting to be known.",
      "I'm sure the universe is full of intelligent life. It's just been too intelligent to come here."
    },
    verbs = {
      "advanced"
    } 
  },

["Wizard"] = {

    "item/green-wire",
	"item/red-wire",
	"item/arithmetic-combinator",
	"item/decider-combinator",

    tooltip = {
      "Without mathematics, there's nothing you can do. Everything around you is mathematics. Everything around you is numbers.",
	  "Pure mathematics is, in its way, the poetry of logical ideas.",
		"God used beautiful mathematics in creating the world.",
		"The numbers may be said to rule the whole world of quantity, and the four rules of arithmetic may be regarded as the complete equipment of the mathematician.",
		"But if the technological Singularity can happen, it will."
		--"One day it will have a mind of it´s own!."
      },
	  verbs = {
      "combinated",
	  "equaled"
    } 
  },	
  
  ["Trains"] = {
    --"entity/curved-rail",
    --"item/cargo-wagon",
    --"item/fluid-wagon",
    "item/locomotive",
    --"item/rail-signal",
    --"item/rail",
    tooltip = {
      "Ch, ch, choooo!",
      "The only way of catching a train I have ever discovered is to miss the train before. ",
      "If a trainstation is where the train stops, what's a workstation...?"
    },
    verbs = {
      "expanded",
      "derailed"
    } 
  },

  ["Oil"] = {
    --"item/storage-tank",
    --"item/pipe-to-ground",
    --"item/oil-refinery",
    --"item/chemical-plant",
    "item/pumpjack",
    "fluid/crude-oil",
    --"fluid/heavy-oil",
    --"fluid/light-oil",
    --"fluid/petroleum-gas",
    --"fluid/lubricant",
    --"fluid/sulfuric-acid",
    tooltip = {
      "We're running out of oil!",
      "Black gold",
      "Naturally occurring, yellow-to-black liquid found in geological formations beneath the Earth's surface, which is commonly refined into various types of fuels.",
      "Components of petroleum are separated using a technique called fractional distillation.",
      "The petroleum industry generally classifies crude oil by the geographic location it is produced in (e.g. West Texas Intermediate, Brent, or Oman), its API gravity (an oil industry measure of density), and its sulfur content."
    },
    verbs = {
      "lubricated",
      "sulfured"
    }
  },
  
  ["Powah!"] = {
    "item/steam-turbine",
    --"item/nuclear-reactor",
    --"item/heat-exchanger",
    "item/steam-engine",
    "item/solar-panel",
    "item/accumulator",
    --"item/boiler",
    --"fluid/steam",
    tooltip = {
      "I ve Got The power!",
      "Power Overwhelming!!!111",
      "Its Over 9000!!!",
      "If you want to find the secrets of the universe, think in terms of energy, frequency and vibration."
    },
    verbs = {
      "amplified",
      "teslaed",
	  "electrified"
    }
  },
  
  ["Spaceman"] = {
    "item/rocket-silo",   
    "item/rocket-control-unit",
    "item/satellite",
    "item/rocket-fuel",   
    tooltip = {
      "That's one small step for a man, one giant leap for mankind.",
      "The sky is the limit only for those who aren't afraid to fly!",
      "Apocalyptic explosions, dead reactors, terrorists, mass murder, death-slugs, and now a blindness plague. This is a terrible planet. We should not have come here.",
      "A still more glorious dawn awaits. Not a sunrise, but a galaxy rise. A morning filled with 400 billion suns. The rising of the milky way",
	  "The Universe is under no obligation to make sense to you."
    },
    verbs = {
      "warped"
    }
  },  

  ["Cat"] = {
    "item/raw-fish",
	
    tooltip = {
      "=^.^=",
      "Meow",
      "In a cat's eye, all things belong to cats.",
      "Cats don't like change without their consent.",
      "Heard melodies are sweet, but those unheard, are sweeter"
    },
    verbs = {
      "mewed",
      "purred",
      "miaowed"
    } 
  },
  
  ["Dog"] = {
    "entity/small-biter",
    "entity/medium-biter",
    "entity/big-biter",
    "entity/behemoth-biter",
    tooltip = {
      "Not a cat",
      "Friend",
      "It's not the size of the dog in the fight, it's the size of the fight in the dog.",
      "When what you want is a relationship, and not a person, get a dog",
      "A dog has one aim in life... to bestow his heart."
    },
    verbs = {
      "woofed",
	  "howled"
    }
  }
}
}
