local t = {
    ['biter-spawner'] = 128,
    ['spitter-spawner'] = 128,
    ['behemoth-biter'] = 64,
    ['behemoth-spitter'] = 64,
    ['big-biter'] = 16,
    ['big-spitter'] = 16,
    ['medium-biter'] = 4,
    ['medium-spitter'] = 4,
    ['small-biter'] = 1,
    ['small-spitter'] = 1,
    ['small-worm-turret'] = 16,
    ['medium-worm-turret'] = 32,
    ['big-worm-turret'] = 64,
    ['behemoth-worm-turret'] = 128
}
if is_mod_loaded('bobenemies') then
    t['bob-big-electric-spitter'] = 64
    t['bob-huge-acid-spitter'] = 128
    t['bob-huge-explosive-spitter'] = 128
    t['bob-giant-fire-spitter'] = 512
    t['bob-giant-poison-spitter'] = 512
    t['bob-leviathan-spitter'] = 1024
    t['bob-big-piercing-biter'] = 64
    t['bob-behemoth-biter'] = 128
    t['bob-titan-biter'] = 128
    t['bob-giant-poison-biter'] = 512
    t['bob-giant-fire-biter'] = 512
    t['bob-huge-explosive-biter'] = 1024
end

return t
