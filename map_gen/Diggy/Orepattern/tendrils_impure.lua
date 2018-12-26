-- defines all ore patches to be generated. Add as many clusters as
-- needed. Clusters listed first have a higher placement priority over
-- the latter clusters
--
-- TODO update and document all configuration settings
--
-- noise types:
--   cluster: same as vanilla factorio generation
--   skip: skips this cluster
--   connected_tendril: long ribbons of ore
--   fragmented_tendril: long ribbons of ore that occur when inside another
--       region of ribbons
--
-- noise source types and configurations
--   perlin: same as vanilla factorio generation
--     variance: increase to make patches closer together and smaller
--         note that this is the inverse of the cluster_mode variance
--     threshold: increase to shrink size of patches
--   simplex: similar to perlin
--   zero: does nothing with this source
--   one: adds the weight directly to the noise calculation
--
-- weights:  recommend having resource weights for each cluster add up to 1000
--           so that it is apparent that every 10 weight = 1%.  eg. weight 860 (86%) + weight 80 (8%) + weight 60 (6%) = 100%

return {
    { -- tendril medium large impure iron
        yield=1.15,
        min_distance=25,
        distance_richness=9,
        color={r=0/255, g=140/255, b=255/255},
        noise_settings = {
            type = "connected_tendril",
            threshold = 0.05,
            sources = {
                {variance=350, weight = 1.000, offset = 000, type="simplex"},
                {variance=200, weight = 0.350, offset = 150, type="simplex"},
                {variance=050, weight = 0.050, offset = 300, type="simplex"},
                {variance=020, weight = 0.015, offset = 450, type="simplex"},
            }
        },
        weights = {
            ['iron-ore']    = 860,
            ['coal']        = 85,
            ['stone']       = 55,
        },
        distances = {
            ['coal']        = 16,
            ['iron-ore']    = 18,
            ['stone']       = 15,
        },
    },
    { -- tendril medium large impure copper
        yield=0.92,
        min_distance=25,
        distance_richness=9,
        color={r=255/255, g=55/255, b=0/255},
        noise_settings = {
            type = "connected_tendril",
            threshold = 0.05,
            sources = {
                {variance=350, weight = 1.000, offset = 000, type="simplex"},
                {variance=200, weight = 0.350, offset = 150, type="simplex"},
                {variance=050, weight = 0.050, offset = 300, type="simplex"},
                {variance=020, weight = 0.015, offset = 450, type="simplex"},
            }
        },
        weights = {
            ['copper-ore']  = 860,
            ['coal']        = 85,
            ['stone']       = 55,
        },
        distances = {
            ['coal']        = 16,
            ['copper-ore']  = 18,
            ['stone']       = 15,
        },
    },
    { -- tendril medium impure coal
        yield=0.5,
        min_distance=25,
        distance_richness=9,
        color={r=0/255, g=0/255, b=0/255},
        noise_settings = {
            type = "connected_tendril",
            threshold = 0.03,
            sources = {
                {variance=350, weight = 1.000, offset = 000, type="simplex"},
                {variance=200, weight = 0.350, offset = 150, type="simplex"},
                {variance=050, weight = 0.050, offset = 300, type="simplex"},
                {variance=020, weight = 0.015, offset = 450, type="simplex"},
            },
        },
        weights = {
            ['coal']        = 790,
            ['iron-ore']    = 160,
            ['stone']       = 50,
        },
        distances = {
            ['coal']        = 16,
            ['iron-ore']    = 18,
            ['stone']       = 15,
        },
    },
    { -- tendril medium impure stone
        yield=0.35,
        min_distance=25,
        distance_richness=9,
        color={r=100/255, g=100/255, b=100/255},
        noise_settings = {
            type = "connected_tendril",
            threshold = 0.028,
            sources = {
                {variance=350, weight = 1.000, offset = 000, type="simplex"},
                {variance=200, weight = 0.350, offset = 150, type="simplex"},
                {variance=050, weight = 0.050, offset = 300, type="simplex"},
                {variance=020, weight = 0.015, offset = 450, type="simplex"},
            }
        },
        weights = {
            ['stone']       = 790,
            ['copper-ore']  = 126,
            ['coal']        = 84,
        },
        distances = {
            ['coal']        = 16,
            ['copper-ore']  = 18,
            ['stone']       = 15,
        },
    },
    { -- tendril small uranium
        yield=0.2,
        min_distance=86,
        distance_richness=9,
        color={r=0/255, g=0/255, b=0/255},
        noise_settings = {
            type = "connected_tendril",
            threshold = 0.025,
            sources = {
                {variance=120, weight = 1.000, offset = 000, type="simplex"},
                {variance=060, weight = 0.300, offset = 150, type="simplex"},
                {variance=040, weight = 0.200, offset = 300, type="simplex"},
                {variance=020, weight = 0.090, offset = 450, type="simplex"},
            }
        },
        weights = {
            ['uranium-ore'] =  1,
        },
        distances = {
            ['uranium-ore'] = 86,
        },
    },
    { -- scattered tendril fragments
        yield=0.2,
        min_distance=10,
        distance_richness=7,
        color={r=0/255, g=0/255, b=0/255},
        noise_settings = {
            type = "fragmented_tendril",
            threshold = 0.06,
            discriminator_threshold = 1.2,
            sources = {
                {variance=025, weight = 1.000, offset = 600, type="simplex"},
                {variance=015, weight = 0.500, offset = 750, type="simplex"},
                {variance=010, weight = 0.250, offset = 900, type="simplex"},
                {variance=05, weight = 0.100, offset =1050, type="simplex"},
            },
            discriminator = {
                {variance=120, weight = 1.000, offset = 000, type="simplex"},
                {variance=060, weight = 0.300, offset = 150, type="simplex"},
                {variance=040, weight = 0.200, offset = 300, type="simplex"},
                {variance=020, weight = 0.090, offset = 450, type="simplex"},
            },
        },
        weights = {
            ['coal']        = 181,
            ['copper-ore']  = 272,
            ['iron-ore']    = 454,
            ['stone']       = 93,
        },
        distances = {
            ['coal']        = 16,
            ['iron-ore']    = 18,
            ['copper-ore']  = 18,
            ['stone']       = 15,
        },
    },
    { -- crude oil
        yield=1.7,
        min_distance=57,
        distance_richness=9,
        color={r=0/255, g=255/255, b=255/255},
        noise_settings = {
            type = "cluster",
            threshold = 0.40,
            sources = {
                {variance=25, weight = 1, offset = 000, type="perlin"},
            },
        },
        weights = {
            ['skip']        = 997,
            ['crude-oil']   =   3,
        },
        distances = {
            ['crude-oil']   = 57,
        },
    },
}
