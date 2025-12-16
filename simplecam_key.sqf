#include "\a3\ui_f\hpp\defineDIKCodes.inc"

// --- CBA SETTINGS (Sliders/Options) ---
// (Kept your existing settings, added HUD Default at the end)

[
	"Bro_SCam_Whitelist", "EDITBOX", 
	["Allowed Users (Whitelist)", "Comma-separated list: SGT John,Billy,1LT Hoang"], 
	"[Bro] Simple Cinematic Camera", "", true 
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_Sens", "SLIDER", 
	["Mouse Sensitivity", "Lower = Smoother / Slower"], 
	"[Bro] Simple Cinematic Camera", [0.01, 1.0, 0.15, 2], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_Speed", "SLIDER", 
	["Base Movement Speed", "Lower = Smoother / Slower"], 
	"[Bro] Simple Cinematic Camera", [0.01, 2.0, 0.07, 2], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothPos", "SLIDER", 
	["Position Inertia", "Lower = Smoother / Slower"], 
	"[Bro] Simple Cinematic Camera", [0.001, 0.5, 0.01, 3], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothRot", "SLIDER", 
	["Rotation Smoothness", "Lower = Smoother / Slower"], 
	"[Bro] Simple Cinematic Camera", [0.001, 0.5, 0.01, 3], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothBrg", "SLIDER", 
	["Orientation Lock Smoothness", "Lower = Smoother / Slower"], 
	"[Bro] Simple Cinematic Camera", [0.001, 0.5, 0.05, 3], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothFOV", "SLIDER", 
	["Zoom Smoothness", "Lower = Smoother / Slower"], 
	"[Bro] Simple Cinematic Camera", [0.001, 0.5, 0.01, 3], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothSpd", "SLIDER", 
	["Speed Smoothness", "Lower = Smoother / Slower"], 
	"[Bro] Simple Cinematic Camera", [0.001, 0.5, 0.02, 3], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_RollSpeed", "SLIDER", 
	["Roll Speed", "Lower = Smoother / Slower"], 
	"[Bro] Simple Cinematic Camera", [0.01, 2.0, 0.1, 2], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_HUDDefault", "CHECKBOX", 
	["HUD Default On", "If checked, HUD is visible when camera opened each time."], 
	"[Bro] Simple Cinematic Camera", true, nil
] call CBA_Settings_fnc_init;

// --- KEYBINDINGS ---
// We register these so the user can change them in Options -> Controls -> Configure Addons
// We pass {} as the code because simplecam.sqf handles the input loop manually.

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
[_modName, "Bro_SCam_Reset", "Reset camera and modes (except follow)", {}, {}, [DIK_G, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Follow", "Toggle Follow Mode", {}, {}, [DIK_F, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Lock_Alt", "Toggle Altitude Lock", {}, {}, [DIK_V, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Lock_Ori", "Toggle Orientation Lock", {}, {}, [DIK_B, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Vision", "Cycle Vision Mode", {}, {}, [DIK_N, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_HUD", "Toggle HUD", {}, {}, [DIK_L, [false, false, false]]] call CBA_fnc_addKeybind;

// Jump
[_modName, "Bro_SCam_Jump_Prev", "Jump to Prev Unit", {}, {}, [DIK_LEFT, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Jump_Next", "Jump to Next Unit", {}, {}, [DIK_RIGHT, [false, false, false]]] call CBA_fnc_addKeybind;