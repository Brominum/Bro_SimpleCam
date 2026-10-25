# Simple Cinematic Camera
A modern cinematic camera system for Arma 3, built as a spiritual successor to GCam.

## Features
- Smooth, framerate-independent rendering using per-frame event handlers instead of sleep loops, eliminating camera stutter
- Camera roll and banking through true 6-DOF vector math
- Native Xbox controller support with pressure-sensitive analog panning and custom deadzones
- Fully rebindable controls integrated directly into the CBA settings menu
- TFAR and ACRE support that automatically moves your simulated hearing to the camera's physical position
- True vehicle orientation lock that glues the camera to the vehicle's local model space for flawless tracking
- Altitude lock toggle for perfectly level horizontal panning without vertical drift
- Optimized performance and memory by replacing global variables with a local HashMap and throttling UI updates
- Built-in server whitelist to restrict camera access to specific players
- State saving that remembers your exact position, roll, and FOV when reopening the camera
- 9 camera bookmarks (Ctrl+1-9 to save, 1-9 to load) that store position, angle, roll, FOV, vision mode, speed, target and lock modes, with an instant jump or a smooth ease in/out of 0.1 seconds to 5 minutes
- Optional depth of field that focuses on the current target
- Composition overlays with the full HUD: Rule of Thirds, Golden Triangle
- FOV shown in degrees and as a full-frame focal length in mm
- Instant timescale hotkeys for single-player slow motion without navigating menus

## Usage
Default keybind: `Ctrl + Shift + B`
With ACE: Use self-interact menu -> Cinematic Camera
All controls are displayed on the HUD and fully rebindable in CBA Settings under `[Bro] Simple Cinematic Camera`.

## License
[Arma Public License Share Alike (APL-SA)](https://www.bohemia.net/community/licenses/arma-public-license-sa)

## Credits
Created by Bromine. Camera core scripting (`simplecam.sqf` and `simplecam_key.sqf`) assisted by Google Gemini and Claude Code, then refined and optimized by human review.