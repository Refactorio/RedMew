local Color = require 'resources.color_presets'
local math = require 'utils.math'
local RS = require 'map_gen.shared.redmew_surface'
local ScoreTracker = require 'utils.score_tracker'
local Sounds = require 'utils.sounds'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Public = require 'map_gen.maps.frontier.shared.core'
local Enemy = require 'map_gen.maps.frontier.modules.enemy'
local Terrain = require 'map_gen.maps.frontier.modules.terrain'
local this = Public.get()
local math_abs = math.abs
local math_ceil = math.ceil
local math_clamp = math.clamp
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_random = math.random
local SECOND = 60
local MINUTE = SECOND * 60

local RocketSilo = {}

local bard_messages_1 = {
  [1] = {
    [[The rocket has successfully launched! The Kraken has accepted your offering... for now.]],
    [[A distant rumble echoes through the air. The Kraken stirs in the depths.]],
    [[You can almost feel the waters shifting. What will the Kraken do with your gift?]],
    [[The sky darkens as the rocket ascends. Is the Kraken pleased or plotting revenge?]],
    [[You have awakened something ancient. Expect the unknown in the next moments.]],
    [[A whisper echoes in your mind: 'You dare disturb my slumber?']],
    [[The Kraken watches from below, its tendrils coiling in anticipation.]],
    [[A chilling wind sweeps across your factory—a sign the Kraken is not to be trifled with.]],
    [[The ground trembles as the rocket disappears into the sky... what price will you pay?]],
    [[An ominous shadow looms beneath the waves. The Kraken has taken notice.]],
  },
  [2] = {
    [[As the rocket pierces the sky, dark waters tremble in anticipation... something stirs.]],
    [[A whispering gale caresses the land; the Kraken's essence begins to awaken.]],
    [[Shadows flicker at the water's edge. The depths conceal secrets you cannot fathom.]],
    [[Eyes unblinking watch from the abyss; your offering has been noted with curiosity... or contempt.]],
    [[The air grows thick with foreboding. An ancient power rouses from its slumber.]],
    [[From the deep, a voice resonates: 'What price have you paid for your hubris?']],
    [[The ocean churns as if agitated. The Kraken's mood is as unpredictable as the tempest.]],
    [[Unseen tendrils drift closer to your shores. What has been awakened cannot be unmade.]],
    [[A shiver runs through the ground, as if the earth itself fears the Kraken's gaze.]],
    [[With each second that passes, the Kraken's presence suffocates the air around you.]],
  },
  [3] = {
    [[Hark! The rocket soars to the heavens, yet below, the Kraken stirs in its slumber deep, its ancient wrath looms ever near!]],
    [[Lo, the winds whisper secrets of the abyss; the Kraken watches, its tendrils twitching in delight or dread—can you tell which it shall be?]],
    [[By the light of the fading suns, shadows dance upon the waves. A gift offered, but at what terrible cost? Beware the storm that brews!]],
    [[Listen well, dear traveler! For the depths grow restless, and the Kraken, master of the abyss, awakens to claim its due!]],
    [[Oh, fear the echo of the deep! A creature of legend stirs, its gaze upon your fortress—wreathed in shadows, it feasts on your hubris!]],
    [[Beware the churning sea, where the ancient beast stirs; your paid price may be your eternal plight—what horrors shall it unleash?]],
    [[From depths unknown, an unsettling murmur rises, 'You dared disturb me, foolish one! Know now the depths of my disdain!']],
    [[As the rocket ascends, the sky darkens and trembles, for the Kraken's heart beats wildly—can you sense its lurking fury?]],
    [[Oremus, oh heed my words! For beneath the surface lies a horror awakened—a vengeful force hungering for the taste of calamity!]],
    [[An eternal shadow looms, beckoned by your ambition! What horrors have you invited to dance upon your very threshold?]],
  },
}
local bard_messages_2 = {
  [1] = {
    [[The surface of the water begins to churn ominously... something awakens.]],
    [[An unsettling roar reverberates through the land. The Kraken's wrath is near.]],
    [[A dark cloud forms above, casting a shadow over your factory. The Kraken is displeased.]],
    [[Tentacles rise from the deep, a harbinger of chaos approaching your base.]],
    [[The Kraken demands retribution! Prepare for the onslaught!]],
    [[A storm brews on the horizon; the Kraken lashes out in fury.]],
    [[The air grows thick with tension as a monstrous wave approaches your shores.]],
    [[All around you, the atmosphere shifts—something is very wrong.]],
    [[The Kraken's vengeance is upon you! Brace yourself for the inevitable.]],
    [[In its rage, the Kraken unleashes its fury! The biter swarm descends!]],
  },
  [2] = {
    [[The surface roils ominously, dark waters boiling as wrath takes form.]],
    [[A haunting cry echoes across the landscape—an ancient beast calls for retribution.]],
    [[Dark clouds gather like a shroud, heralding calamity born of the abyss.]],
    [[Tendrils of shadow writhe beneath the waves—a prelude to the storm of vengeance.]],
    [[The Kraken's disdain unfurls like a tempest, a dark promise of chaos and destruction.]],
    [[An unnatural stillness settles, broken only by the distant crash of furious waves.]],
    [[The deep stirs with malice. Can you hear the heartbeat of your impending doom?]],
    [[In the twilight, the Kraken's fury eclipses all hope, a symphony of despair draws near.]],
    [[As specters rise from the depths, their intent is clear: retribution is swift and merciless.]],
    [[Your fate is entwined with the Kraken's ire—prepare for the inexorable tide of darkness.]],
  },
  [3] = {
    [[Attend! A tempest brews upon darkened waters, rage unfurling like a ravenous beast—your time is nigh!]],
    [[The Kraken's call resounds, echoing through the night; from the abyss it comes, cloaked in shadows and dread!]],
    [[A shudder passes through the land, and ominous clouds converge—gaze now upon the darkening sky, for doom draws near!]],
    [[Dread whisperings of the deep herald the coming tempest; the Kraken rises, eager to reclaim what is owed with swift malice!]],
    [[Foul winds carry the scent of vengeance. The Kraken's ire is unbound, and soon your fortress shall feel its dark embrace!]],
    [[In the twilight haze, a cacophony of doom stirs—behold, the tide of destruction approaches with unholy intent!]],
    [[Tremble now, for the Kraken awakens! A chorus of despair sings forth, heralding the swarm that comes, hungry and relentless!]],
    [[The ancient beast unleashes fury upon your path—a storm of chaos born from the depths, bringing forth a wretched tide!]],
    [[Beware! The Kraken's wrath is a specter unshackled, and every heartbeat draws nearer to the end of your peace!]],
    [[Thus, from beneath the waves, chaos and slaughter arise—oh, brave souls, face the horrors your hubris has conjured!]],
  },
}

RocketSilo.play_sound_token = Token.register(Sounds.notify_all)

RocketSilo.restart_message_token = Token.register(function(seconds)
  game.print({'frontier.restart', seconds}, Color.success)
end)

function RocketSilo.bard_message(list)
  game.print('[color=orange][Bard][/color] ' .. list[math_random(#list)], { sound_path = 'utility/axe_fighting', color = Color.brown })
end
RocketSilo.bard_message_token = Token.register(RocketSilo.bard_message)

function RocketSilo.move_silo(position)
  local surface = RS.get_surface()
  local old_silo = this.rocket_silo
  local old_position = old_silo and old_silo.position or { x = 0, y = 0 }
  local new_silo
  local new_position = position or { x = this.x, y = this.y }

  if old_silo and math_abs(new_position.x - old_position.x) < this.min_step then
    this.move_buffer = this.move_buffer + new_position.x - old_position.x
    return
  end

  for _, e in pairs(surface.find_entities_filtered{ position = new_position, radius = 15 }) do
    if e.type == 'character' then
      local pos = surface.find_non_colliding_position('character', { new_position.x + 12, new_position.y }, 5, 0.5)
      if pos then
        e.teleport(pos)
      else
        e.character.die()
      end
    else
      e.destroy()
    end
  end

  if old_silo then
    local result_inventory = old_silo.get_output_inventory().get_contents()
    new_silo = old_silo.clone { position = new_position, force = old_silo.force, create_build_effect_smoke = true }
    old_silo.destroy()
    local chest = surface.create_entity { name = 'steel-chest', position = old_position, force = 'player', move_stuck_players = true }
    if table_size(result_inventory) > 0 then
      chest.destructible = false
      for name, count in pairs(result_inventory) do
        chest.insert({ name = name, count = count })
      end
    end
    local spill_item_stack = surface.spill_item_stack
    for x = -15, 15 do
      for y = -15, 15 do
        for _ = 1, 4 do
          spill_item_stack({ x = old_position.x + x + math_random(), y = old_position.y + y + math_random()}, { name = 'raw-fish', count = 1 }, false, nil, true)
        end
      end
    end
    game.print({'frontier.empty_rocket'})
    Enemy.nuclear_explosion(chest.position)

    for _ = 1, 3 do
      local spawn_target = Enemy.get_target()
      if spawn_target and spawn_target.valid then
        for _ = 1, 12 do
          Task.set_timeout_in_ticks(math_random(30, 4 * 60), Enemy.artillery_explosion_token, { surface_name = surface.name, position = spawn_target.position })
        end
        for t = 1, math_clamp(math_floor((#game.connected_players) / 2 + 0.5), 1, 5) do
          Task.set_timeout(15 * t, Enemy.spawn_enemy_wave_token, spawn_target.position)
        end
        break
      end
    end

    game.forces.enemy.reset_evolution()
    local enemy_evolution = game.map_settings.enemy_evolution
    enemy_evolution.time_factor = enemy_evolution.time_factor * 1.01
  else
    new_silo = surface.create_entity { name = 'rocket-silo', position = new_position, force = 'player', move_stuck_players = true }
  end

  if new_silo and new_silo.valid then
    new_silo.destructible = false
    new_silo.minable = false
    new_silo.active = true
    new_silo.get_output_inventory().clear()
    this.rocket_silo = new_silo
    this.x = new_silo.position.x
    this.y = new_silo.position.y
    this.move_buffer = 0
    Terrain.set_silo_tiles(new_silo)

    local x_diff = math.round(new_position.x - old_position.x)
    if x_diff > 0 then
      game.print({'frontier.silo_forward', x_diff})
    else
      game.print({'frontier.silo_backward', x_diff})
    end
  end
end
RocketSilo.move_silo_token = Token.register(RocketSilo.move_silo)

function RocketSilo.compute_silo_coordinates(step)
  this.move_buffer = this.move_buffer + (step or 0)

  if this.x + this.move_buffer > this.max_distance then
    -- Exceeding max right direction, move to max (if not already) and add rockets to win
    local remainder = this.x + this.move_buffer - this.max_distance
    local add_rockets = math_floor(remainder / this.rocket_step)
    if add_rockets > 0 then
      this.rockets_to_win = this.rockets_to_win + add_rockets
      game.print({'frontier.warning_max_distance', this.rocket_step})
    end
    this.x = math_min(this.max_distance, this.x + this.move_buffer)
    this.move_buffer = remainder % this.rocket_step
  elseif this.x + this.move_buffer < -(this.left_boundary * 32) + 12 then
    -- Exceeding min left direction, move to min (if not already) and remove rockets to win
    local min_distance = -(this.left_boundary * 32) + 12
    local remainder = this.x + this.move_buffer - min_distance -- this is negative
    local remove_rockets = math_floor(-remainder / this.rocket_step)
    if remove_rockets > 0 then
      this.rockets_to_win = this.rockets_to_win - remove_rockets
      if this.rockets_to_win < 1 then this.rockets_to_win = 1 end
      if this.rockets_launched >= this.rockets_to_win then
        RocketSilo.set_game_state(true)
        return
      else
        game.print({'frontier.warning_min_distance', this.rocket_step})
      end
    end
    this.x = math_max(min_distance, this.x + this.move_buffer)
    this.move_buffer = remainder % this.rocket_step
  else
    this.x = this.x + this.move_buffer
    this.move_buffer = 0
  end

  local max_height = (this.height * 16) - 16
  this.y = math_random(-max_height, max_height)
end

function RocketSilo.reveal_spawn_area()
  local surface = RS.get_surface()
  local far_left, far_right = this.kraken_distance + this.left_boundary * 32 + 1, this.right_boundary * 32 + this.wall_width
  surface.request_to_generate_chunks({ x = 0, y = 0 }, math.ceil(math_max(far_left, far_right, this.height * 32) / 32))
  surface.force_generate_chunk_requests()

  RocketSilo.compute_silo_coordinates(this.silo_starting_x + math_random(100))
  RocketSilo.move_silo()
  Terrain.create_wall(this.right_boundary * 32, this.wall_width)

  game.forces.player.chart(surface, { { -far_left - 32, -this.height * 16 }, { far_right + 32, this.height * 16 } })
end

function RocketSilo.set_game_state(player_won)
  this.scenario_finished = true
  game.set_game_state {
    game_finished = true,
    player_won = player_won or false,
    can_continue = true,
    victorious_force = player_won and 'player' or 'enemy'
  }

  Task.set_timeout( 1, RocketSilo.restart_message_token, 90)
  Task.set_timeout(31, RocketSilo.restart_message_token, 60)
  Task.set_timeout(61, RocketSilo.restart_message_token, 30)
  Task.set_timeout(81, RocketSilo.restart_message_token, 10)
  Task.set_timeout(86, RocketSilo.restart_message_token,  5)
  Task.set_timeout(90, RocketSilo.end_game_token)
  Task.set_timeout(100, RocketSilo.restart_game_token)
end
RocketSilo.set_game_state_token = Token.register(RocketSilo.set_game_state)

function RocketSilo.on_game_started()
  local ms = game.map_settings
  ms.enemy_expansion.friendly_base_influence_radius = 0
  ms.enemy_expansion.min_expansion_cooldown = SECOND * 30
  ms.enemy_expansion.max_expansion_cooldown = MINUTE * 4
  ms.enemy_expansion.max_expansion_distance = 5
  ms.enemy_evolution.destroy_factor = 0.0001
  ms.enemy_evolution.time_factor = 0.000015
  ms.pollution.ageing  = 0.5 --1
  ms.pollution.diffusion_ratio = 0.04 -- 0.02
  ms.pollution.enemy_attack_pollution_consumption_modifier = 0.5 --1

  this.rounds = this.rounds + 1
  this.kraken_contributors = {}
  this.death_contributions = {}
  this.rockets_to_win = 12 + math_random(12) + this.rounds
  this.rockets_launched = 0
  this.scenario_finished = false
  this.x = 0
  this.y = 0
  this.rocket_silo = nil
  this.move_buffer = 0
  this.invincible = {}
  this.target_entities = {}
  this.unit_groups = {}
  this.spawn_shop_funds = 1
  this.spawn_shop_upgrades = {}

  if _DEBUG then
    this.silo_starting_x = 30
    this.rockets_to_win = 2
    this.spawn_shop_funds = 3
  end

  for _, force in pairs(game.forces) do
    force.reset()
    force.reset_evolution()
  end

  game.speed = 1
  game.reset_game_state()
  game.reset_time_played()

  ScoreTracker.reset()
  ScoreTracker.set_for_global(Public.scores.rocket_launches.name, this.rockets_to_win)
  ScoreTracker.set_for_global(Public.scores.shop_funds.name, this.spawn_shop_funds)
end

RocketSilo.restart_game_token = Token.register(function()
  script.raise_event(Public.events.on_game_started, {})
end)

function RocketSilo.on_game_finished()
  this.lobby_enabled = true
  game.print({'frontier.map_setup'})

  local surface = RS.get_surface()
  surface.clear(true)
  local mgs = table.deepcopy(surface.map_gen_settings)
  mgs.seed = mgs.seed + 1e4
  surface.map_gen_settings = mgs
end

RocketSilo.end_game_token = Token.register(function()
  script.raise_event(Public.events.on_game_finished, {})
end)

function RocketSilo.on_rocket_launched(event)
  local rocket = event.rocket
  if not (rocket and rocket.valid) then
    return
  end

  if this.scenario_finished then
    return
  end

  this.rockets_launched = this.rockets_launched + 1
  ScoreTracker.set_for_global(Public.scores.rocket_launches.name, this.rockets_to_win - this.rockets_launched)
  if this.rockets_launched >= this.rockets_to_win then
    RocketSilo.set_game_state(true)
    return
  end

  game.print({'frontier.rocket_launched', this.rockets_launched, (this.rockets_to_win - this.rockets_launched) })
  RocketSilo.compute_silo_coordinates(this.rocket_step + math_random(200))

  local ticks = 60
  for _, delay in pairs{60, 40, 20} do
    for i = 1, 30 do
      ticks = ticks + math_random(math_ceil(delay/5), delay)
      Task.set_timeout_in_ticks(ticks, RocketSilo.play_sound_token, 'utility/alert_destroyed')
    end
  end
  Task.set_timeout( 5, RocketSilo.bard_message_token, bard_messages_1[3])
  Task.set_timeout(25, RocketSilo.bard_message_token, bard_messages_2[3])
  Task.set_timeout_in_ticks(ticks + 30, RocketSilo.move_silo_token)
  local silo = event.rocket_silo
  if silo then silo.active = false end
end

return RocketSilo
