
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

return {
    { -- tendril default large
        yield=1.5,
        min_distance=40,
        distance_richness=7,
        color={r=255/255, g=0/255, b=255/255},
        noise_settings = {
            type = "connected_tendril",
            threshold = 0.05,
            sources = {
                {variance=350*2, weight = 1.000, offset = 000, type="simplex"},
                {variance=200*2, weight = 0.350, offset = 150, type="simplex"},
                {variance=050*2, weight = 0.050, offset = 300, type="simplex"},
                {variance=020*2, weight = 0.015, offset = 450, type="simplex"},
            }
        },
        weights = {
            ['coal']        = 160,
            ['copper-ore']  = 280,
            ['iron-ore']    = 395,
            ['stone']       = 135,
            ['uranium-ore'] =  6,
        },
        distances = {
            ['coal']        = 16,
            ['copper-ore']  = 18,
            ['iron-ore']    = 18,
            ['stone']       = 15,
            ['uranium-ore'] = 120,
        }, },
    { -- tendril default small
        yield=1.0,
        min_distance=25,
        distance_richness=7,
        color={r=255/255, g=255/255, b=0/255},
        noise_settings = {
            type = "connected_tendril",
            threshold = 0.05,
            sources = {
                {variance=120, weight = 1.000, offset = 000, type="simplex"},
                {variance=060, weight = 0.300, offset = 150, type="simplex"},
                {variance=040, weight = 0.200, offset = 300, type="simplex"},
                {variance=020, weight = 0.090, offset = 450, type="simplex"},
            }
        },
        weights = {
            ['coal']        = 160,
            ['copper-ore']  = 215,
            ['iron-ore']    = 389,
            ['stone']       = 100,
            ['uranium-ore'] =  30,
        },
        distances = {
            ['coal']        = 16,
            ['copper-ore']  = 18,
            ['iron-ore']    = 18,
            ['stone']       = 15,
            ['uranium-ore'] = 120,
        },
    },
    { -- tendril default fragments coal
        yield=0.25,
        min_distance=10,
        distance_richness=7,
        color={r=0/255, g=0/255, b=0/255},
        noise_settings = {
            type = "fragmented_tendril",
            threshold = 0.05,
            discriminator_threshold = 0.4,
            sources = {
                {variance=050, weight = 1.000, offset = 600, type="simplex"},
                {variance=030, weight = 0.500, offset = 750, type="simplex"},
                {variance=020, weight = 0.250, offset = 900, type="simplex"},
                {variance=010, weight = 0.100, offset =1050, type="simplex"},
            },
            discriminator = {
                {variance=120, weight = 1.000, offset = 000, type="simplex"},
                {variance=060, weight = 0.300, offset = 150, type="simplex"},
                {variance=040, weight = 0.200, offset = 300, type="simplex"},
                {variance=020, weight = 0.090, offset = 450, type="simplex"},
            },
        },
        weights = {
            ['coal']        = 1,
        },
        distances = {
            ['coal']        = 16,
        },
    },
    { -- tendril default fragments iron
        yield=0.25,
        min_distance=10,
        distance_richness=7,
        color={r=0/255, g=140/255, b=255/255},
        noise_settings = {
            type = "fragmented_tendril",
            threshold = 0.05,
            discriminator_threshold = 0.4,
            sources = {
                {variance=050, weight = 1.000, offset = 600, type="simplex"},
                {variance=030, weight = 0.500, offset = 750, type="simplex"},
                {variance=020, weight = 0.250, offset = 900, type="simplex"},
                {variance=010, weight = 0.100, offset =1050, type="simplex"},
            },
            discriminator = {
                {variance=120, weight = 1.000, offset = 000, type="simplex"},
                {variance=060, weight = 0.300, offset = 150, type="simplex"},
                {variance=040, weight = 0.200, offset = 300, type="simplex"},
                {variance=020, weight = 0.090, offset = 450, type="simplex"},
            },
        },
        weights = {
            ['iron-ore']    = 389,
        },
        distances = {
            ['iron-ore']    = 18,
        },
    },
    { -- tendril default fragments copper
        yield=0.25,
        min_distance=10,
        distance_richness=7,
        color={r=255/255, g=55/255, b=0/255},
        noise_settings = {
            type = "fragmented_tendril",
            threshold = 0.05,
            discriminator_threshold = 0.4,
            sources = {
                {variance=050, weight = 1.000, offset = 600, type="simplex"},
                {variance=030, weight = 0.500, offset = 750, type="simplex"},
                {variance=020, weight = 0.250, offset = 900, type="simplex"},
                {variance=010, weight = 0.100, offset =1050, type="simplex"},
            },
            discriminator = {
                {variance=120, weight = 1.000, offset = 000, type="simplex"},
                {variance=060, weight = 0.300, offset = 150, type="simplex"},
                {variance=040, weight = 0.200, offset = 300, type="simplex"},
                {variance=020, weight = 0.090, offset = 450, type="simplex"},
            },
        },
        weights = {
            ['copper-ore']  = 215,
        },
        distances = {
            ['copper-ore']  = 18,
        },
    },
    { -- tendril default fragments stone
        yield=0.25,
        min_distance=10,
        distance_richness=7,
        color={r=100/255, g=100/255, b=100/255},
        noise_settings = {
            type = "fragmented_tendril",
            threshold = 0.05,
            discriminator_threshold = 0.4,
            sources = {
                {variance=050, weight = 1.000, offset = 600, type="simplex"},
                {variance=030, weight = 0.500, offset = 750, type="simplex"},
                {variance=020, weight = 0.250, offset = 900, type="simplex"},
                {variance=010, weight = 0.100, offset =1050, type="simplex"},
            },
            discriminator = {
                {variance=120, weight = 1.000, offset = 000, type="simplex"},
                {variance=060, weight = 0.300, offset = 150, type="simplex"},
                {variance=040, weight = 0.200, offset = 300, type="simplex"},
                {variance=020, weight = 0.090, offset = 450, type="simplex"},
            },
        },
        weights = {
            ['stone']       = 1,
        },
        distances = {
            ['stone']       = 15,
        },
    },
    { -- crude oil
        yield=1.7,
        min_distance=57,
        distance_richness=7,
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
