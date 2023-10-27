local default = function()
    return {
        ammo = {
            ['firearm-magazine'] = true,
            ['piercing-rounds-magazine'] = true,
            ['uranium-rounds-magazine'] = true,
        },
        locale = {
            ['firearm-magazine'] = {'item-name.firearm-magazine'},
            ['piercing-rounds-magazine'] = {'item-name.piercing-rounds-magazine'},
            ['uranium-rounds-magazine'] = {'item-name.uranium-rounds-magazine'},
        }
    }
end

if script.active_mods['Krastorio2'] then
    return {
        ammo = {
            ['rifle-magazine'] = true,
            ['armor-piercing-rifle-magazine'] = true,
            ['uranium-rifle-magazine'] = true,
            ['imersite-rifle-magazine'] = true,
        },
        locale = {
            ['rifle-magazine'] = {'item-name.rifle-magazine'},
            ['armor-piercing-rifle-magazine'] = {'item-name.armor-piercing-rifle-magazine'},
            ['uranium-rifle-magazine'] = {'item-name.uranium-rifle-magazine'},
            ['imersite-rifle-magazine'] = {'item-name.imersite-rifle-magazine'},
        }
    }
end

if script.active_mods['exotic-industries'] then
    return {
        ammo = {
            ['firearm-magazine'] = true,
            ['piercing-rounds-magazine'] = true,
            ['uranium-rounds-magazine'] = true,
            ['ei_compound-ammo'] = true,
        },
        locale = {
            ['firearm-magazine'] = {'item-name.firearm-magazine'},
            ['piercing-rounds-magazine'] = {'item-name.piercing-rounds-magazine'},
            ['uranium-rounds-magazine'] = {'item-name.uranium-rounds-magazine'},
            ['ei_compound-ammo'] = {'item-name.ei_compound-ammo'},
        }
    }
end

if script.active_mods['IndustrialRevolution3'] then
    return {
        ammo = {
            ['firearm-magazine'] = true,
            ['piercing-rounds-magazine'] = true,
            ['chromium-magazine'] = true,
            ['uranium-rounds-magazine'] = true,
        },
        locale = {
            ['firearm-magazine'] = {'item-name.firearm-magazine'},
            ['piercing-rounds-magazine'] = {'item-name.piercing-rounds-magazine'},
            ['chromium-magazine'] = {'item-name.chromium-magazine'},
            ['uranium-rounds-magazine'] = {'item-name.uranium-rounds-magazine'},
        }
    }
end

if script.active_mods['bobwarfare'] then
    return {
        ammo = {
            ['firearm-magazine'] = true,
            ['piercing-rounds-magazine'] = true,
            ['uranium-rounds-magazine'] = true,
            ['bullet-magazine'] = true,
            ['acid-bullet-magazine'] = true,
            ['ap-bullet-magazine'] = true,
            ['electric-bullet-magazine'] = true,
            ['flame-bullet-magazine'] = true,
            ['he-bullet-magazine'] = true,
            ['plasma-bullet-magazine'] = true,
            ['poison-bullet-magazine'] = true,
        },
        locale = {
            ['firearm-magazine'] = {'item-name.firearm-magazine'},
            ['piercing-rounds-magazine'] = {'item-name.piercing-rounds-magazine'},
            ['uranium-rounds-magazine'] = {'item-name.uranium-rounds-magazine'},
            ['acid-bullet-magazine'] = {'item-name.acid-bullet-magazine'},
            ['ap-bullet-magazine'] = {'item-name.ap-bullet-magazine'},
            ['electric-bullet-magazine'] = {'item-name.electric-bullet-magazine'},
            ['flame-bullet-magazine'] = {'item-name.flame-bullet-magazine'},
            ['he-bullet-magazine'] = {'item-name.he-bullet-magazine'},
            ['plasma-bullet-magazine'] = {'item-name.plasma-bullet-magazine'},
            ['poison-bullet-magazine'] = {'item-name.poison-bullet-magazine'},
        }
    }
end

if script.active_mods['bzzirconium'] then
    return {
        ammo = {
            ['firearm-magazine'] = true,
            ['piercing-rounds-magazine'] = true,
            ['explosive-rounds-magazine'] = true,
            ['uranium-rounds-magazine'] = true,
        },
        locale = {
            ['firearm-magazine'] = {'item-name.firearm-magazine'},
            ['piercing-rounds-magazine'] = {'item-name.piercing-rounds-magazine'},
            ['explosive-rounds-magazine'] = {'item-name.explosive-rounds-magazine'},
            ['uranium-rounds-magazine'] = {'item-name.uranium-rounds-magazine'},
        }
    }
end

return default()