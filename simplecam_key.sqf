#include "\a3\ui_f\hpp\defineDIKCodes.inc"

// --- CBA SETTINGS (Clamped Scales) ---

[
	"Bro_SCam_Whitelist", "EDITBOX", 
	["Allowed Users (Whitelist)", "Comma-separated usernames, e.g.: PV1 John,Billy,1LT Bob"], 
	"[Bro] Simple Cinematic Camera", "", true 
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SavePos", "CHECKBOX", 
	["Save Last Camera Position", "If checked, reopening the camera resumes from where you left it. Uncheck to always reset to player."], 
	"[Bro] Simple Cinematic Camera", true, nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_HUDDefault", "CHECKBOX", 
	["HUD Default On", "If checked, HUD is visible on start."], 
	"[Bro] Simple Cinematic Camera", true, nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_HideAI", "CHECKBOX", 
	["Hide AI Units", "If checked, AI units are removed from the jump list, showing only players."], 
	"[Bro] Simple Cinematic Camera", false, nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_Sens", "SLIDER", 
	["Mouse Sensitivity", "Higher = Faster mouse look."], 
	"[Bro] Simple Cinematic Camera", [1, 100, 15, 0], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_Speed", "SLIDER", 
	["Base Movement Speed", "Higher = Faster base speed before multiplier."], 
	"[Bro] Simple Cinematic Camera", [1, 30, 7, 0], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothPos", "SLIDER", 
	["Position Responsiveness", "1 = Heavy/Slow, 10 = Instant."], 
	"[Bro] Simple Cinematic Camera", [0.1, 10, 1, 1], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothRot", "SLIDER", 
	["Rotation Responsiveness (Mouse)", "1 = Heavy/Smooth, 10 = Instant."], 
	"[Bro] Simple Cinematic Camera", [0.1, 10, 1, 1], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothBrg", "SLIDER", 
	["Orientation Lock Responsiveness", "How fast it tracks the target's angles."], 
	"[Bro] Simple Cinematic Camera", [0.1, 10, 5, 1], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothFOV", "SLIDER", 
	["Zoom Responsiveness", "1 = Slow Zoom, 10 = Instant."], 
	"[Bro] Simple Cinematic Camera", [0.1, 10, 1, 1], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothSpd", "SLIDER", 
	["Speed Change Responsiveness", "How fast Shift/Ctrl changes speed."], 
	"[Bro] Simple Cinematic Camera", [0.1, 10, 5, 1], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_RollSpeed", "SLIDER", 
	["Roll Speed", "Higher = Faster rolling."], 
	"[Bro] Simple Cinematic Camera", [1, 50, 10, 0], nil
] call CBA_Settings_fnc_init;

// --- KEYBINDINGS ---
private _modName = "[Bro] Simple Cinematic Camera";

[_modName, "Bro_SCam_Open", "Open Camera", { [] execVM "bro_simplecam\simplecam.sqf"; }, {}, [DIK_B, [true, true, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Exit", "Exit Camera", {}, {}, [DIK_SPACE, [false, false, false]]] call CBA_fnc_addKeybind;

// Movement
[_modName, "Bro_SCam_Move_Fwd", "Move Forward", {}, {}, [DIK_W, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Move_Back", "Move Back", {}, {}, [DIK_S, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Move_Left", "Move Left", {}, {}, [DIK_A, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Move_Right", "Move Right", {}, {}, [DIK_D, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Move_Up", "Move Up", {}, {}, [DIK_Q, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Move_Down", "Move Down", {}, {}, [DIK_Z, [false, false, false]]] call CBA_fnc_addKeybind;

// Roll
[_modName, "Bro_SCam_Roll_Left", "Roll Left", {}, {}, [DIK_E, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Roll_Right", "Roll Right", {}, {}, [DIK_R, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Roll_Reset", "Reset Roll", {}, {}, [DIK_T, [false, false, false]]] call CBA_fnc_addKeybind;

// Speed
[_modName, "Bro_SCam_Speed_Fast", "Speed Increase", {}, {}, [DIK_LSHIFT, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Speed_Slow", "Speed Decrease", {}, {}, [DIK_LCONTROL, [false, false, false]]] call CBA_fnc_addKeybind;

// Toggles / Actions
[_modName, "Bro_SCam_Reset", "Reset to Player", {}, {}, [DIK_G, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Follow", "Toggle Follow Mode", {}, {}, [DIK_F, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Lock_Alt", "Toggle Altitude Lock", {}, {}, [DIK_V, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Lock_Ori", "Toggle Orientation Lock", {}, {}, [DIK_B, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Vision", "Cycle Vision Mode", {}, {}, [DIK_N, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_HUD", "Toggle HUD", {}, {}, [DIK_L, [false, false, false]]] call CBA_fnc_addKeybind;

// Jump (Players Only)
[_modName, "Bro_SCam_Jump_Prev", "Jump to Prev Player", {}, {}, [DIK_LEFT, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Jump_Next", "Jump to Next Player", {}, {}, [DIK_RIGHT, [false, false, false]]] call CBA_fnc_addKeybind;

// List Navigation (Players + AI)
[_modName, "Bro_SCam_List_Up", "Jump List Up", {}, {}, [DIK_UP, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_List_Down", "Jump List Down", {}, {}, [DIK_DOWN, [false, false, false]]] call CBA_fnc_addKeybind;