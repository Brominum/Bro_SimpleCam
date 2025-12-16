#include "\a3\ui_f\hpp\defineDIKCodes.inc"

// --- KEYBIND ---
[
	"[Bro] Simple Cinematic Camera",
	"bro_simplecamOpen",
	"Open Simple Cinematic Camera",
	{ [] execVM "bro_simplecam\simplecam.sqf"; },
	{}, 
	[DIK_B, [true, true, false]] // Default: Ctrl + Shift + B
] call CBA_fnc_addKeybind;

// --- CBA SETTINGS ---

// 1. Whitelist
[
	"Bro_SCam_Whitelist", 
	"EDITBOX", 
	["Allowed Users (Whitelist)", "Comma-separated list of profile names allowed to use the camera. Leave EMPTY to allow everyone.\nExample: John,PFC Bob,1SGT Joe"], 
	"[Bro] Simple Cinematic Camera", 
	"", 
	true 
] call CBA_Settings_fnc_init;

// 2. Mouse Sensitivity
[
	"Bro_SCam_Sens", 
	"SLIDER", 
	["Mouse Sensitivity", "How fast the camera turns."], 
	"[Bro] Simple Cinematic Camera", 
	[0.01, 1.0, 0.15, 2], 
	nil
] call CBA_Settings_fnc_init;

// 3. Movement Speed Base
[
	"Bro_SCam_Speed", 
	"SLIDER", 
	["Base Movement Speed", "The starting speed before Shift/Ctrl modifiers."], 
	"[Bro] Simple Cinematic Camera", 
	[0.01, 2.0, 0.07, 2], 
	nil
] call CBA_Settings_fnc_init;

// 4. Position Smoothing
[
	"Bro_SCam_SmoothPos", 
	"SLIDER", 
	["Position Inertia", "Lower values = Heavier camera."], 
	"[Bro] Simple Cinematic Camera", 
	[0.001, 0.5, 0.01, 3], 
	nil
] call CBA_Settings_fnc_init;

// 5. Rotation Smoothing (Mouse)
[
	"Bro_SCam_SmoothRot", 
	"SLIDER", 
	["Rotation Smoothness", "Lower values = Smoother mouse movement."], 
	"[Bro] Simple Cinematic Camera", 
	[0.001, 0.5, 0.01, 3], 
	nil
] call CBA_Settings_fnc_init;

// 6. Orientation Lock Smoothing (Target Tracking)
[
	"Bro_SCam_SmoothBrg", 
	"SLIDER", 
	["Orientation Lock Smoothness", "How fast the camera tracks the target's rotation (Yaw/Pitch/Roll) when Lock is ON."], 
	"[Bro] Simple Cinematic Camera", 
	[0.001, 0.5, 0.05, 3], // Default changed to 0.05
	nil
] call CBA_Settings_fnc_init;

// 7. FOV Smoothing
[
	"Bro_SCam_SmoothFOV", 
	"SLIDER", 
	["Zoom Smoothness", "How fast the zoom reacts."], 
	"[Bro] Simple Cinematic Camera", 
	[0.001, 0.5, 0.01, 3], 
	nil
] call CBA_Settings_fnc_init;

// 8. Speed Smoothing
[
	"Bro_SCam_SmoothSpd", 
	"SLIDER", 
	["Speed Smoothness", "How fast the camera accelerates when changing speed (Shift/Ctrl)."], 
	"[Bro] Simple Cinematic Camera", 
	[0.001, 0.5, 0.02, 3], 
	nil
] call CBA_Settings_fnc_init;

// 9. Roll Speed
[
	"Bro_SCam_RollSpeed", 
	"SLIDER", 
	["Roll Speed", "How fast E and R roll the camera."], 
	"[Bro] Simple Cinematic Camera", 
	[0.01, 2.0, 0.1, 2], 
	nil
] call CBA_Settings_fnc_init;
// 10. HUD Default On
[
	"Bro_SCam_HUDDefault", 
	"CHECKBOX", 
	["HUD Starts On", "If checked, the HUD will be visible immediately when opening the camera."], 
	"[Bro] Simple Cinematic Camera", 
	true, 
	nil
] call CBA_Settings_fnc_init;