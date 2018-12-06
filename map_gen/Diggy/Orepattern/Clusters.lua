
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
    {
        yield=1.0,
        min_distance=30,
        distance_richness=7,
        noise_settings = {
            type = "cluster",
            threshold = 0.40,
            sources = {
                {variance=25, weight = 1, offset = 000, type="perlin"},
            }
        },
        weights = {
            ['coal']        = 160,
            ['copper-ore']  = 215,
            ['iron-ore']    = 389,
            ['stone']       = 212,
            ['uranium-ore'] =  21,
            ['crude-oil']   =   3,
        },
        distances = {
            ['coal']        = 16,
            ['copper-ore']  = 18,
            ['iron-ore']    = 18,
            ['stone']       = 15,
            ['uranium-ore'] = 86,
            ['crude-oil']   = 57,
        }, },
}
