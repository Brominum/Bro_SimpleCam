# Simple Cinematic Camera

A modern cinematic camera system for Arma 3, designed as a spiritual successor to GCam with improved performance and features.

## Features

- Smooth camera movement: Multi-directional movement with adjustable speed
- Camera roll: Full control over camera banking/rotation
- Follow mode: Track units while maintaining relative camera position
- Altitude lock: Maintain constant height during movement
- Orientation lock: Lock camera rotation to target's orientation
- Vision modes: Normal, NVG, White Hot, Black Hot thermal
- Player/AI jumping: Quick navigation between units
- Timescale control: Adjust time speed for slow-motion shots (SP only)
- TFAR/ACRE integration: Hear radio comms from camera position
- Fully rebindable controls: Customize all keybinds via CBA
- Xbox controller support: Full native gamepad layout (sticks, triggers, all buttons) — no rebind required
- Whitelist support: Server-side access control for cinematographers

## Requirements

- [CBA_A3](https://steamcommunity.com/workshop/filedetails/?id=450814997) (required)
- ACE3 (optional: adds self-interact menu)

## Installation

Subscribe on the [Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3624526073)

## Usage

Default keybind: `Ctrl + Shift + B`

With ACE: Use self-interact menu -> Cinematic Camera

All controls are displayed on the HUD and fully rebindable in CBA Settings under `[Bro] Simple Cinematic Camera`.

## Xbox Controller

Enable `Enable Xbox Controller Input` in CBA Addon Options. All bindings below are **native** — Arma's standard XInput keycodes wire straight to the camera, no CBA rebind required. The HUD shows the controller layout and a `PAD` indicator in the bottom bar.

| Input | Action |
|---|---|
| Left stick | Strafe + forward/back (analog, radial deadzone) |
| Right stick | Look — yaw + pitch (analog, cubic response curve) |
| RT (held) | Move UP |
| LT (held) | Move DOWN |
| RB (held) | Speed FAST modifier |
| LB (held) | Speed SLOW modifier |
| **A (held)** | **FN modifier mode** (`PAD/FN` tag appears on HUD) |
| A held + LB | FOV out (zoom out, step) |
| A held + RB | FOV in (zoom in, step) |
| A held + D-pad ← / → | Roll left / right step |
| A double-tap | Select highlighted target |
| B | Exit camera |
| X | Cycle HUD (Full / Light / Off) |
| Y | Cycle vision (Normal / NVG / WHOT / BHOT) |
| L3 (LS click) | Toggle Follow mode |
| R3 (RS click) | Toggle Look At |
| D-pad ↑ / ↓ | List prev/next unit (players + AI) |
| D-pad ← / → | Jump to prev/next player |
| Start | Reset camera to current target |
| Back / View | Toggle Altitude Lock |

Controller-specific settings (CBA Addon Options):
- **Stick deadzone** (default 0.15) — radial deadzone with quadratic response for fine control
- **Look sensitivity** (default 120) — right-stick rotation speed
- **Invert look Y** — flight-style pitch inversion

## Configuration

Settings available in CBA Addon Options:
- Mouse sensitivity
- Movement speed and responsiveness
- Rotation smoothing
- Roll speed
- HUD defaults
- Xbox controller (enable + deadzone, sensitivity, invert Y)
- Whitelist (server-side)

## Improvements over GCam

- Framerate independent camera movement (no server-FPS dependent stuttering)
- Simultaneous multi-directional movement
- Smooth speed adjustments
- Camera roll capability
- Better script performance and maintainability

## License

[Arma Public License Share Alike (APL-SA)](https://www.bohemia.net/community/licenses/arma-public-license-sa)

## Credits

Created by Bromine

Camera core scripting (simplecam.sqf and simplecam_key.sqf) assisted by Google Gemini 3 Pro and Claude Code, then refined and optimized by human review.
