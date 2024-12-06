return {
  -- AUX
  -- range: [0, 1]
  -- determines whether low-moisture tiles become sand or red desert
  aux = {
    very_low  = { aux = { frequency = 1, bias = -0.5 } },
    low       = { aux = { frequency = 1, bias = -0.3 } },
    med       = { aux = { frequency = 1, bias = -0.1 } },
    high      = { aux = { frequency = 1, bias = 0.2 } },
    very_high = { aux = { frequency = 1, bias = 0.5 } },
  },
  -- MOISTURE
  -- range: [0, 1]
  -- determines whether a tile becomes sandy (low moisture) or grassy (high moisture).
  moisture = {
    none      = { moisture = { frequency = 2, bias = -1 } },
    low       = { moisture = { frequency = 1, bias = -0.15 } },
    med       = { moisture = { frequency = 1, bias = 0 } },
    high      = { moisture = { frequency = 1, bias = 0.15 } },
    max       = { moisture = { frequency = 2, bias = 0.5 } },
  },
  temperature = {
    -- mixed
    bland     = { hot = { frequency = 0.5,   size = 0 },    cold = { frequency = 0.5,  size = 0 } },
    temperate = { hot = { frequency = 1,     size = 0.25 }, cold = { frequency = 1,    size = 0.25 } },
    midrange  = { hot = { frequency = 1,     size = 0.65 }, cold = { frequency = 1,    size = 0.65 } },
    balanced  = { hot = { frequency = 1,     size = 1 },    cold = { frequency = 1,    size = 1 } },
    wild      = { hot = { frequency = 1,     size = 3 },    cold = { frequency = 1,    size = 3 } },
    extreme   = { hot = { frequency = 1,     size = 6 },    cold = { frequency = 1,    size = 6 } },
    -- cold
    cool      = { hot = { frequency = 0.75,  size = 0 },    cold = { frequency = 0.75, size = 0.5 } },
    cold      = { hot = { frequency = 0.75,  size = 0 },    cold = { frequency = 0.75, size = 1 } },
    very_cold = { hot = { frequency = 0.75,  size = 0 },    cold = { frequency = 0.75, size = 2.2 } },
    frozen    = { hot = { frequency = 0.75,  size = 0 },    cold = { frequency = 0.75, size = 6 } },
    -- hot
    warm      = { hot = { frequency = 0.75,  size = 0.5 },  cold = { frequency = 0.75, size = 0 } },
    hot       = { hot = { frequency = 0.75,  size = 1 },    cold = { frequency = 0.75, size = 0 } },
    very_hot  = { hot = { frequency = 0.75,  size = 2.2 },  cold = { frequency = 0.75, size = 0 } },
    volcanic  = { hot = { frequency = 0.75,  size = 6 },    cold = { frequency = 0.75, size = 0 } },
  },
  trees = {
    none      = { trees = { frequency = 0.25, size = 0,    richness = 0 } },
    low       = { trees = { frequency = 0.6,  size = 0.35, richness = 0.8 } },
    med       = { trees = { frequency = 0.8,  size = 0.66, richness = 1 } },
    high      = { trees = { frequency = 1,    size = 1,    richness = 1 } },
    max       = { trees = { frequency = 3,    size = 1,    richness = 1 } },
  },
  cliff = {
    none      = { cliff = { frequency = 0.01, richness = 0 } },
    low       = { cliff = { frequency = 0.3,  richness = 0.3 } },
    med       = { cliff = { frequency = 1,    richness = 1 } },
    high      = { cliff = { frequency = 2,    richness = 2 } },
    max       = { cliff = { frequency = 6,    richness = 2 } },
  },
  water = {
    none      = { water = { frequency = 1,   richness = 1, size = 0 } },
    low       = { water = { frequency = 0.5, richness = 1, size = 0.3 } },
    med       = { water = { frequency = 1,   richness = 1, size = 1 } },
    high      = { water = { frequency = 1,   richness = 1, size = 4 } },
    max       = { water = { frequency = 0.5, richness = 1, size = 10 } },
  },
  enemy = {
    none      = { ['enemy-base'] = { frequency = 0,    size = 0,   richness = 0 } },
    very_low  = { ['enemy-base'] = { frequency = 0.1,  size = 0.1, richness = 0.1 } },
    low       = { ['enemy-base'] = { frequency = 0.2,  size = 0.2, richness = 0.2 } },
    med       = { ['enemy-base'] = { frequency = 0.5,  size = 0.5, richness = 0.5 } },
    high      = { ['enemy-base'] = { frequency = 1,    size = 1,   richness = 1 } },
    very_high = { ['enemy-base'] = { frequency = 1.5,  size = 2,   richness = 1.5 } },
    max       = { ['enemy-base'] = { frequency = 2,    size = 6,   richness = 2 } },
  },
}
