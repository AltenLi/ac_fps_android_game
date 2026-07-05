# CS 5v5 Feature And Test Matrix

Last updated: 2026-07-05

This is the current feature inventory and verification map. Use it together with `design/CURRENT_DESIGN.md` before making gameplay changes.

## How To Verify

Primary automated gate:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
```

Current test suites:

| Test file | Main coverage |
|---|---|
| `tests/test_map_registry.gd` | Map registry, map scenes, map costs, loading screen, map materials, model materials, themed map props, snow achievement source hooks |
| `tests/test_player_data.gd` | Stars, map unlocks, daily rewards, daily tasks, tutorial completion, achievement persistence |
| `tests/test_weapon_configs.gd` | Weapon resources, damage/cooldowns/ammo, knife melee rules, enemy damage reduction |
| `tests/test_ai_balance.gd` | AI attack ranges, navigation, wall avoidance, frontline behavior, ammo seeking, prone detection, spectate visibility, AI weapon animations |
| `tests/test_tutorial_flow.gd` | Home/tutorial flow, mobile detection, menu entry points |
| `tests/test_settings.gd` | Settings validation, selected map/role/difficulty, ultra quality mode |
| `tests/test_mobile_controls.gd` | Touch controls, button layout, double jump, aiming, grenade/prone/tower controls, first-person weapon animations |
| `tests/test_laser_tower.gd` | Laser tower build rules, once-per-round rule, arm delay, target count, ground-only placement |
| `tests/test_sound_manager.gd` | Original generated audio, music, shot distance volume, reload/explosion/feedback sounds |
| `tests/test_release_config.gd` | Android release/export configuration and package metadata |
| `tests/test_feature_matrix.gd` | This feature matrix remains present and aligned with the major implemented systems |

## Core Match

| Feature | Implementation | Verification |
|---|---|---|
| 5v5 match: player + 4 blue AI vs 5 orange AI | `scripts/match_manager.gd` | `tests/test_ai_balance.gd`, `tests/test_map_registry.gd` |
| 300 second round timer | `MatchManager.ROUND_TIME` | Source assertion coverage through match tests |
| Elimination or timer result | `MatchManager._check_elimination()`, `finish_match()` | `tests/test_ai_balance.gd`, HUD/result source checks |
| Player death spectator mode | `scripts/player_controller.gd`, `scripts/hud.gd`, `scripts/ai_controller.gd` | `tests/test_mobile_controls.gd`, `tests/test_ai_balance.gd` |
| Match rewards and MVP/star result | `scripts/match_manager.gd`, `scripts/player_data.gd`, `scripts/hud.gd` | `tests/test_player_data.gd`, `tests/test_map_registry.gd` |

## Weapons And Combat

| Feature | Implementation | Verification |
|---|---|---|
| M416 automatic rifle | `resources/weapons/m416.tres`, `scripts/weapon_system.gd`, `scripts/model_factory.gd` | `tests/test_weapon_configs.gd`, `tests/test_map_registry.gd` |
| Barrett sniper rifle | `resources/weapons/barrett.tres`, `scripts/model_factory.gd` | `tests/test_weapon_configs.gd`, `tests/test_mobile_controls.gd` |
| Tactical knife melee | `resources/weapons/knife.tres`, `WeaponSystem._fire_melee()` | `tests/test_weapon_configs.gd`, `tests/test_mobile_controls.gd` |
| Knife has no ammo, no projectile, unlimited swing use | `WeaponSystem.get_current_ammo()`, `start_reload()`, `try_fire()` | `tests/test_weapon_configs.gd` |
| Knife attack interval and damage: 0.5 seconds, 50 damage | `resources/weapons/knife.tres` | `tests/test_weapon_configs.gd` |
| Manual reload and auto reload when empty | `WeaponSystem.start_reload()`, `_finish_reload()` | `tests/test_weapon_configs.gd`, `tests/test_mobile_controls.gd` |
| First-person gun fire animation | `PlayerController._play_gun_fire_animation()` | `tests/test_mobile_controls.gd` |
| First-person reload animation with magazine motion | `PlayerController._play_reload_animation()` | `tests/test_mobile_controls.gd` |
| Third-person AI fire/reload weapon animations | `AIController._on_weapon_fired()`, `_on_reload_started()` | `tests/test_ai_balance.gd` |
| Shot tracers and hit damage | `WeaponSystem._fire_hitscan()`, `_spawn_tracer()` | `tests/test_weapon_configs.gd` |
| Distance-aware gunshot audio | `scripts/sound_manager.gd` | `tests/test_sound_manager.gd` |

## Aiming And Movement

| Feature | Implementation | Verification |
|---|---|---|
| All guns can aim | `PlayerController._cycle_scope_zoom()` | `tests/test_mobile_controls.gd` |
| Scope tap order: 2.5x, 5.0x, close | `SCOPE_ZOOM_LEVELS := [1.0, 2.5, 5.0]` | `tests/test_mobile_controls.gd` |
| Barrett scope overlay | `scripts/hud.gd` | `tests/test_mobile_controls.gd` |
| Air movement | `PlayerController._apply_movement()` | `tests/test_mobile_controls.gd` |
| First jump height target | `PlayerController.JUMP_HEIGHT` | `tests/test_mobile_controls.gd` |
| Double jump by tapping jump again while airborne | `PlayerController._try_jump()` | `tests/test_mobile_controls.gd` |
| Double jump height: about 1.5 humans | `PlayerController.SECOND_JUMP_HEIGHT` | `tests/test_mobile_controls.gd` |
| Prone height: one fifth standing height | `PRONE_BODY_HEIGHT := STANDING_BODY_HEIGHT / 5.0` | `tests/test_mobile_controls.gd`, `tests/test_ai_balance.gd` |
| Prone detection chance for enemies: 30 percent | `AIController.PRONE_PLAYER_DETECTION_CHANCE` | `tests/test_ai_balance.gd` |
| Grenade self-launch without self-damage | `scripts/projectile.gd`, `PlayerController.apply_grenade_knockback()` | `tests/test_mobile_controls.gd`, `tests/test_weapon_configs.gd` |

## Grenades

| Feature | Implementation | Verification |
|---|---|---|
| Grenade action is manual, not automatic RPG fire | `PlayerController.mobile_throw_grenade()`, `_throw_grenade()` | `tests/test_mobile_controls.gd` |
| 10 grenades per round | `GRENADE_MAX_PER_ROUND := 10` | `tests/test_mobile_controls.gd` |
| 2 second grenade cooldown | `GRENADE_COOLDOWN := 2.0` | `tests/test_mobile_controls.gd` |
| Arc/parabolic throw | `Projectile.setup_arc()` | `tests/test_mobile_controls.gd` |
| Top HUD shows cooldown and remaining count | `scripts/hud.gd` | `tests/test_mobile_controls.gd` |

## Laser Tower

| Feature | Implementation | Verification |
|---|---|---|
| Player can build a laser tower | `PlayerController.mobile_build_laser_tower()`, `MatchManager.build_laser_tower()` | `tests/test_laser_tower.gd`, `tests/test_mobile_controls.gd` |
| Build takes 4 seconds and locks movement | `LASER_TOWER_BUILD_SECONDS`, `_laser_build_locked` | `tests/test_laser_tower.gd` |
| Engineer builds faster | `PlayerController.apply_character_profile("engineer")` | `tests/test_laser_tower.gd` |
| Tower can only be built on ground | `_get_valid_laser_tower_ground_position()` checks collider name `Ground` | `tests/test_laser_tower.gd` |
| Only one tower per round | `_laser_tower_built_this_round` | `tests/test_laser_tower.gd` |
| Tower waits 30 seconds before firing | `LaserTower.ARM_SECONDS := 30.0` | `tests/test_laser_tower.gd` |
| Tower kills 3 random enemies and draws lasers | `scripts/laser_tower.gd` | `tests/test_laser_tower.gd` |

## AI

| Feature | Implementation | Verification |
|---|---|---|
| Blue teammates push to frontline | `TEAMMATE_FRONTLINE_DISTANCE_MULTIPLIER`, battle routes | `tests/test_ai_balance.gd` |
| AI respects walls and uses navigation graph | `AStar3D`, `_choose_context_steering_direction()` | `tests/test_ai_balance.gd` |
| AI recovers from being stuck | `_update_stuck_recovery()`, `_choose_escape_direction()` | `tests/test_ai_balance.gd` |
| AI seeks ammo when empty | `AIState.SEEK_AMMO`, `get_closest_ammo_drop()` | `tests/test_ai_balance.gd` |
| AI can use spawn resupply | `MatchManager._update_spawn_resupply()` | `tests/test_ai_balance.gd`, `tests/test_map_registry.gd` |
| AI can target and destroy structures | `AIController` target logic and `LaserTower` health | `tests/test_ai_balance.gd`, `tests/test_laser_tower.gd` |
| Difficulty modes: easy, normal, hard | `GameSettings.bot_difficulty`, `AIController._apply_difficulty()` | `tests/test_settings.gd`, `tests/test_ai_balance.gd` |

## Maps

| Feature | Implementation | Verification |
|---|---|---|
| 11 registered maps | `scripts/map_registry.gd` | `tests/test_map_registry.gd` |
| Free maps: city, desert, snow | `MapRegistry.get_free_map_ids()` | `tests/test_map_registry.gd` |
| Unlock costs: 0/6/10/12/15/18 progression | `MapRegistry.MAPS` | `tests/test_map_registry.gd` |
| Loading map overlay before match | `map_select.gd`, `match_manager.gd` | `tests/test_map_registry.gd` |
| Brighter high-quality procedural materials | `scripts/base_map.gd` | `tests/test_map_registry.gd` |
| Ultra shadows and higher material resolution | `BaseMap._build_lighting()`, `MATERIAL_TEXTURE_SIZE` | `tests/test_map_registry.gd` |
| Space low gravity | `MatchManager._apply_map_rules()` | `tests/test_map_registry.gd` |
| Volcano lava hazard | `MatchManager._update_map_hazards()` | `tests/test_map_registry.gd` |
| Weapon-limited maps | `MatchManager._get_map_allowed_weapons()` | `tests/test_map_registry.gd`, `tests/test_weapon_configs.gd` |
| Snow base achievement | `MatchManager._check_snow_ace_achievement()` | `tests/test_map_registry.gd`, `tests/test_player_data.gd` |

## Mobile Controls

| Feature | Implementation | Verification |
|---|---|---|
| Joystick slightly up/right | `scripts/mobile_controls.gd` | `tests/test_mobile_controls.gd` |
| Large right fire button | `FIRE_BUTTON_DIAMETER` | `tests/test_mobile_controls.gd` |
| Left upper fire button | `LEFT_FIRE_BUTTON_DIAMETER` | `tests/test_mobile_controls.gd` |
| Weapon, jump, reload, scope, grenade, prone, tower buttons | `mobile_controls.gd` button callbacks | `tests/test_mobile_controls.gd` |
| Buttons use symbols/icons, not Latin letters | `_icon_button()` | `tests/test_mobile_controls.gd` |
| Scope and weapon buttons have debounce | `_request_scope_toggle()`, `_request_next_weapon()` | `tests/test_mobile_controls.gd` |
| Controls hide/reset during spectate or result panels | `_is_gameplay_input_enabled()`, `_reset_all_inputs()` | `tests/test_mobile_controls.gd` |

## Roles And Tactical Chips

| Feature | Implementation | Verification |
|---|---|---|
| Assault role | `PlayerController.apply_character_profile()` | `tests/test_settings.gd`, `tests/test_mobile_controls.gd` |
| Sniper role | `apply_character_profile()` | `tests/test_settings.gd` |
| Engineer role | `apply_character_profile()` and laser tower bonus | `tests/test_laser_tower.gd` |
| Medic role | `MatchManager._get_resupply_seconds()` | `tests/test_ai_balance.gd` |
| Tactical chips: grenade boost, speed boost, tower boost | `scripts/tactical_chip.gd`, `PlayerController.apply_tactical_chip()` | `tests/test_ai_balance.gd`, `tests/test_laser_tower.gd` |

## Progression, Tutorial, And Achievements

| Feature | Implementation | Verification |
|---|---|---|
| Stars stored locally | `scripts/player_data.gd` | `tests/test_player_data.gd` |
| Map unlocks with stars | `PlayerData.unlock_map()` and `map_select.gd` | `tests/test_player_data.gd`, `tests/test_map_registry.gd` |
| Rewarded star placeholder for missing stars | `MonetizationService.request_rewarded_stars()` | `tests/test_map_registry.gd` |
| Daily reward | `PlayerData.claim_daily_reward()` | `tests/test_player_data.gd` |
| Daily tasks | `PlayerData.get_daily_tasks()`, `record_match_for_daily_tasks()` | `tests/test_player_data.gd` |
| Home tutorial and playable tutorial | `main_menu.gd`, `MatchManager.TUTORIAL_ACTION_STEPS` | `tests/test_tutorial_flow.gd`, `tests/test_map_registry.gd` |
| Achievement list | `main_menu.gd`, `PlayerData.get_achievements()` | `tests/test_player_data.gd`, `tests/test_map_registry.gd` |
| Snow achievement: `解锁成就：西蒙海耶` | `MatchManager._check_snow_ace_achievement()` | `tests/test_map_registry.gd`, `tests/test_player_data.gd` |

## Audio And Visuals

| Feature | Implementation | Verification |
|---|---|---|
| Original procedural menu/combat music | `scripts/sound_manager.gd` | `tests/test_sound_manager.gd` |
| Original generated SFX | `SoundManager._make_*()` | `tests/test_sound_manager.gd` |
| Higher-quality map materials | `scripts/base_map.gd` | `tests/test_map_registry.gd` |
| Higher-quality character and weapon materials | `scripts/model_factory.gd` | `tests/test_map_registry.gd` |
| Dynamic crosshair, hit marker, damage numbers, kill effect | `scripts/hud.gd`, `damage_number.gd`, `kill_effect.gd` | `tests/test_mobile_controls.gd`, `tests/test_sound_manager.gd` |
| Ultra quality mode | `scripts/settings.gd`, `scripts/settings_menu.gd` | `tests/test_settings.gd` |

## Build And Release

| Feature | Implementation | Verification |
|---|---|---|
| Android package `com.liacgames.cs5v5` | `export_presets.cfg`, `project.godot` | `tests/test_release_config.gd` |
| Release export path `build/android/DustCityFPS.apk` | Export preset and local build flow | Manual export command plus `tests/test_release_config.gd` |
| Release preflight script | `scripts/release_preflight.sh` | `tests/test_release_config.gd` |
| Git versioning after changes | Local Git workflow | Manual commit check |

## Manual Checks Still Needed

Automated source tests cannot fully prove runtime feel. Before calling a major release stable, do these on a real phone:

- Install the latest APK and play at least one full round.
- Verify touch buttons are visible and do not overlap.
- Verify second jump works by tapping jump once, then again while airborne.
- Verify M416 and Barrett reload animations are visible.
- Verify enemy and teammate models are visible.
- Verify entering a map shows the loading overlay instead of a black/frozen screen.
- Verify ultra quality mode does not cause black screen or severe frame drops on the target phone.
