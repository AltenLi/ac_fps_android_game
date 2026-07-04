# CS 5v5 Current Design

Last updated: 2026-07-04

This document is the handoff source for the current playable design. Read it first after clearing chat context.

## Product Direction

CS 5v5 is a single-player mobile FPS built with Godot 4.7. The player joins the blue team with 4 allied AI teammates against 5 orange enemy AI units. The target feel is a polished tactical mobile shooter with clear controls, readable maps, strong weapon feedback, and original assets. Do not copy maps, characters, music, brands, UI, or art from other commercial games.

The game is currently a playable Android prototype. Every gameplay change should be followed by self-test, a git commit, and, when requested or when Android behavior is affected, APK export and phone install.

## Core Match Rules

- Match format: player + 4 blue AI vs 5 orange AI.
- Match length: 300 seconds.
- Win condition: one team is eliminated, or the timer ends and the side with more living units wins.
- Tie condition: equal living units when the timer ends.
- Player health: 100 HP plus shield.
- AI health: 100 HP.
- Dead player can spectate teammates.

## Weapons

Current weapon set:

- M416: automatic rifle, main sustained-fire weapon.
- Barrett: high-damage sniper rifle.
- Tactical knife: melee weapon, no ammo, no projectile, unlimited swings, 0.5 seconds per attack, 50 damage per hit.
- Grenade: throwable arcing explosive, 10 per round, 2 second throw cooldown.
- Laser tower: buildable tactical structure, not a carried weapon.

Weapon behavior:

- All guns can aim.
- Scope cycle is one tap for 2.5x, second tap for 5.0x, third tap closes scope.
- Barrett uses scoped aim behavior.
- Knife must never show ammo or fire bullets.
- Grenades can launch the player upward if they explode near the player, without self-damage. Self-launch height target is about 6 human heights.

## Movement

- Player can move in the air.
- Jump is a two-step jump:
  - First tap jumps normally.
  - While airborne, second tap triggers the double jump.
  - Double-jump height target is about 1.5 human heights.
- Player can crouch/prone.
- Prone height target is one fifth of standing height.
- While prone, enemies only have a 30 percent chance to detect the player.

## Mobile Controls

Mobile buttons are built in `scripts/mobile_controls.gd`.

Expected layout:

- Left side: floating joystick, slightly moved to the upper-right compared with the old position.
- Right lower area: large fire button.
- Left of fire: weapon switch button.
- Left of weapon switch: jump button.
- Upper-left area: additional fire button, so the player can fire while adjusting view.
- Near aim controls: grenade button placed to the left of the aim/scope button.
- Attack button should be larger than secondary buttons.
- Other action buttons should spread outward so they do not overlap.
- Buttons should use icons or symbols, not Latin letters.

Important regression:

- Switching character/role must not make mobile buttons disappear.
- The known fixed cause was `if icon == "laser":` in `scripts/mobile_controls.gd`; it must remain `if icon_type == "laser":`.

## Characters And Roles

Selected role is stored in `GameSettings.selected_character_id`.

Current roles:

- Assault: movement speed bonus and M416 damage bonus.
- Sniper: Barrett cooldown bonus.
- Engineer: faster laser tower build and extra laser target.
- Medic: faster spawn-circle resupply.

Role selection appears on the map select screen and is applied when the match starts.

## AI Teammates And Enemies

- Blue teammates should push toward the front and fight enemies, not stay passive.
- AI should respect map navigation and walls.
- AI can target enemy players and important structures such as laser towers.
- Enemies should attempt to destroy player-built laser towers.
- AI should not ignore walls or wander randomly through blocked areas.

## Maps

Maps are registered in `scripts/map_registry.gd`.

Current map design goals:

- Materials should be brighter and more polished than the early prototype.
- Map art should feel higher quality while remaining original and mobile-friendly.
- Loading transitions should show a "loading map" state rather than a plain freeze.

Special map rules:

- Snow base: killing all enemies unlocks and displays the achievement text `解锁成就：西蒙海耶`.
- Space: lower gravity.
- Volcano: intermittent lava damage.
- Cave / ruins: limited to Barrett and knife.
- Factory / harbor: limited to M416 and knife.
- Snow: all current weapons allowed.

## Spawn Resupply Circle

Each team has a blue spawn resupply circle.

Rules:

- If supplies are low, enter the circle and stay for 5 seconds to reset supplies to their starting state.
- The unit cannot move during the 5 second resupply.
- The circle also heals while inside.
- Enemies can also use their own spawn resupply behavior.
- Medic role reduces resupply time to 3 seconds.

## Grenades

Rules:

- Each player gets at most 10 grenades per round.
- Grenade cooldown is 2 seconds.
- When all 10 are used, no more grenades can be thrown that round.
- Grenades are thrown only when pressing the grenade button.
- Grenades use an arcing/parabolic path.
- The old automatic RPG-style projectile behavior was changed into grenade-style throwing.
- Top-center HUD shows the grenade/RPG countdown and grenade count as needed.

## Laser Tower

Laser tower rules:

- Player can build a laser tower on the ground only.
- Build time is 4 seconds.
- During build, the player cannot move.
- Engineer build time is 3 seconds.
- The tower does not fire immediately after being built.
- Enemies should approach and try to destroy it.
- When active, it can kill 3 random enemies regardless of location.
- During kills, it fires visible lasers toward the selected enemy directions.
- Engineer or tactical-chip bonuses can increase target count.

## Tactical Chips

Tactical chips are pickup bonuses spawned by `MatchManager`.

Current chip effects:

- Grenade radius boost.
- Temporary speed boost.
- Laser tower target bonus.

## Progression

- Stars unlock maps.
- Stars are local soft currency, not real-money currency.
- Daily rewards and daily missions exist as local progression features.
- Player stats and settings are saved locally.

## Visual Direction

The desired direction is "top-tier tactical mobile FPS materials" while staying original and performant.

Priority areas:

- Higher quality procedural materials.
- Brighter and more readable maps.
- Better first-person gun and weapon switching animations.
- Better jump/prone/scope feedback.
- Higher quality character and weapon presentation without copying protected assets.

## Android Build And Install

Known local paths:

- Godot console: `C:\Users\game1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe`
- ADB: `C:\Users\game1\AppData\Local\Android\Sdk\platform-tools\adb.exe`
- APK: `build/android/DustCityFPS.apk`
- Package: `com.liacgames.cs5v5`

Normal validation flow:

1. Run Godot headless tests.
2. Export Android APK.
3. Commit changed source and exported APK when the user asked to keep version changes committed.
4. Install to connected phone with ADB.
5. Start package `com.liacgames.cs5v5/com.godot.game.GodotAppLauncher`.

SSH remote:

- `git@github.com:AltenLi/ac_fps_android_game.git`

Current SSH push may require adding this public key to GitHub:

- `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF/n1kJmiPa9aypX/R+7hq7JUZ6YMLrU5W914FLg9f7J ac_fps_android_game@game1`

## Test Policy

The user requested self-tests for future work.

Default after every change:

- Run the Godot test runner when code or gameplay changes.
- Add or update focused tests for each bug fix or new gameplay rule.
- Export/install to phone when the change affects Android, controls, rendering, packaging, or user asks for install.
- Keep commits small and named after the gameplay or bug fix.

Current test runner command:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
```

Current export command:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --export-release "Android Release" build/android/DustCityFPS.apk
```

Current install/start command:

```powershell
$adb='C:\Users\game1\AppData\Local\Android\Sdk\platform-tools\adb.exe'
& $adb install -r "E:\game\android_cs\build\android\DustCityFPS.apk"
& $adb shell am force-stop com.liacgames.cs5v5
& $adb shell am start -n com.liacgames.cs5v5/com.godot.game.GodotAppLauncher
```

## Key Implementation Files

- `scripts/match_manager.gd`: match flow, map setup, teams, resupply circles, laser tower placement, tactical chips.
- `scripts/player_controller.gd`: movement, jump/double jump, prone, scope, grenades, laser build input, role effects.
- `scripts/mobile_controls.gd`: Android touch controls.
- `scripts/weapon_system.gd`: weapon switching, firing, ammo, cooldowns.
- `scripts/weapon_config.gd`: weapon values and metadata.
- `scripts/ai_controller.gd`: teammate/enemy behavior.
- `scripts/hud.gd`: HUD, countdowns, scope overlay, match result UI.
- `scripts/map_select.gd`: map and character selection.
- `scripts/settings.gd`: saved settings and selected character.
- `scripts/laser_tower.gd`: laser tower behavior.
- `scripts/tactical_chip.gd`: tactical chip pickup behavior.
- `scripts/projectile.gd`: grenade/projectile behavior and self-knockback.

## Known Open Risks

- Some older documentation displays mojibake in PowerShell, so this file should be treated as the clean current handoff document.
- Button icons include non-ASCII symbols; Android font compatibility should keep being tested on the real phone.
- Some untracked/generated build files exist in the working tree and should not be blindly committed unless intentionally needed.
- SSH push is blocked until the public key is added to GitHub.
