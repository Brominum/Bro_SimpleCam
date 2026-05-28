#include "\a3\ui_f\hpp\defineDIKCodes.inc"

// Translations are loaded by the PreInit step (see config.cpp). Local alias
// for brevity; falls through to the key itself if translations failed to load.
private _L = { _this call Bro_SCam_L };
private _modName = "[Bro] Simple Cinematic Camera";

// --- LANGUAGE OVERRIDE ---
// Determines the language used by all in-camera HUD / notifications.
// "" / "auto" follows the game language. Setting labels (this dialog) always
// follow the game language because CBA reads them at this point only.
[
	"Bro_SCam_Language", "LIST",
	[["s_lng_lbl"] call _L, ["s_lng_tip"] call _L],
	_modName,
	[
		["", "english", "french", "spanish", "german", "italian", "polish", "russian"],
		[["s_lng_auto"] call _L, "English", "Français", "Español", "Deutsch", "Italiano", "Polski", "Русский"],
		0
	],
	nil
] call CBA_Settings_fnc_init;

// --- CBA SETTINGS (Clamped Scales) ---

[
	"Bro_SCam_Whitelist", "EDITBOX",
	[["s_wl_lbl"] call _L, ["s_wl_tip"] call _L],
	_modName, "", true
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SavePos", "CHECKBOX",
	[["s_sp_lbl"] call _L, ["s_sp_tip"] call _L],
	_modName, true, nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_HUDDefault", "CHECKBOX",
	[["s_hd_lbl"] call _L, ["s_hd_tip"] call _L],
	_modName, true, nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_HideAI", "CHECKBOX",
	[["s_ai_lbl"] call _L, ["s_ai_tip"] call _L],
	_modName, false, nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_AudioSpectator", "CHECKBOX",
	[["s_as_lbl"] call _L, ["s_as_tip"] call _L],
	_modName, true, nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_Sens", "SLIDER",
	[["s_ms_lbl"] call _L, ["s_ms_tip"] call _L],
	_modName, [1, 100, 15, 0], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_Speed", "SLIDER",
	[["s_bs_lbl"] call _L, ["s_bs_tip"] call _L],
	_modName, [1, 30, 7, 0], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothPos", "SLIDER",
	[["s_pr_lbl"] call _L, ["s_pr_tip"] call _L],
	_modName, [0.1, 10, 1, 1], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothRot", "SLIDER",
	[["s_rr_lbl"] call _L, ["s_rr_tip"] call _L],
	_modName, [0.1, 10, 1, 1], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothBrg", "SLIDER",
	[["s_or_lbl"] call _L, ["s_or_tip"] call _L],
	_modName, [0.1, 10, 5, 1], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothFOV", "SLIDER",
	[["s_zr_lbl"] call _L, ["s_zr_tip"] call _L],
	_modName, [0.1, 10, 1, 1], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_SmoothSpd", "SLIDER",
	[["s_sr_lbl"] call _L, ["s_sr_tip"] call _L],
	_modName, [0.1, 10, 5, 1], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_RollSpeed", "SLIDER",
	[["s_rs_lbl"] call _L, ["s_rs_tip"] call _L],
	_modName, [1, 50, 10, 0], nil
] call CBA_Settings_fnc_init;

// --- CONTROLLER (XBOX) SETTINGS ---
[
	"Bro_SCam_Controller", "CHECKBOX",
	[["s_pad_lbl"] call _L, ["s_pad_tip"] call _L],
	_modName, false, nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_PadDeadzone", "SLIDER",
	[["s_pdz_lbl"] call _L, ["s_pdz_tip"] call _L],
	_modName, [0, 0.4, 0.15, 2], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_PadLookSens", "SLIDER",
	[["s_pls_lbl"] call _L, ["s_pls_tip"] call _L],
	_modName, [10, 400, 120, 0], nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_PadInvertY", "CHECKBOX",
	[["s_piy_lbl"] call _L, ["s_piy_tip"] call _L],
	_modName, false, nil
] call CBA_Settings_fnc_init;

[
	"Bro_SCam_PadVertSens", "SLIDER",
	[["s_pvs_lbl"] call _L, ["s_pvs_tip"] call _L],
	_modName, [0.5, 50.0, 25.0, 1], nil
] call CBA_Settings_fnc_init;

// --- START-PAUSED + NUMPAD TIMESCALE PRESETS ---
[
	"Bro_SCam_StartPaused", "CHECKBOX",
	[["s_strtp_lbl"] call _L, ["s_strtp_tip"] call _L],
	_modName, false, nil
] call CBA_Settings_fnc_init;

// Numpad 2-9 timescale slider presets (Numpad 0 / 1 are fixed at 0× / 1×).
// Range 0.05 - 4.0 mirrors what setAccTime accepts (0 = pause; we keep
// 0.05 as the minimum so the slider can't actually pause via these presets).
{
	_x params ["_idx", "_def"];
	[
		format ["Bro_SCam_TS_Num%1", _idx], "SLIDER",
		[format [["s_ts_lbl_fmt"] call _L, _idx], ["s_ts_tip"] call _L],
		_modName, [0.05, 4.0, _def, 2], nil
	] call CBA_Settings_fnc_init;
} forEach [
	[2, 0.1],   // extreme slow-mo
	[3, 0.25],  // very slow
	[4, 0.5],   // slow
	[5, 0.75],  // slight slow
	[6, 1.5],   // slight fast
	[7, 2.0],   // fast
	[8, 3.0],   // very fast
	[9, 4.0]    // max
];

// --- KEYBINDINGS ---

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

// Timescale (SP Only)
[_modName, "Bro_SCam_Time_Inc", "Timescale Increase (+)", {}, {}, [DIK_EQUALS, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Time_Dec", "Timescale Decrease (-)", {}, {}, [DIK_MINUS, [false, false, false]]] call CBA_fnc_addKeybind;

// Toggles / Actions
[_modName, "Bro_SCam_Reset", "Reset to Player", {}, {}, [DIK_G, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Follow", "Toggle Follow Mode", {}, {}, [DIK_F, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Lock_Alt", "Toggle Altitude Lock", {}, {}, [DIK_V, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Lock_Ori", "Toggle Orientation Lock", {}, {}, [DIK_B, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Look_At", "Toggle Look At Target", {}, {}, [DIK_F, [false, false, true]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Vision", "Cycle Vision Mode", {}, {}, [DIK_N, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_HUD", "Toggle HUD", {}, {}, [DIK_L, [false, false, false]]] call CBA_fnc_addKeybind;

// Jump (Players Only)
[_modName, "Bro_SCam_Jump_Prev", "Jump to Prev Player", {}, {}, [DIK_LEFT, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Jump_Next", "Jump to Next Player", {}, {}, [DIK_RIGHT, [false, false, false]]] call CBA_fnc_addKeybind;

// List Navigation (Players + AI)
[_modName, "Bro_SCam_List_Up", "Jump List Up", {}, {}, [DIK_UP, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_List_Down", "Jump List Down", {}, {}, [DIK_DOWN, [false, false, false]]] call CBA_fnc_addKeybind;

// Select tgt in Jump list
[_modName, "Bro_SCam_Select", "Select Target", {}, {}, [DIK_RETURN, [false, false, false]]] call CBA_fnc_addKeybind;

// --- NUMPAD TIMESCALE HOTKEYS (global, SP only) ---
// Numpad 0 and 1 are fixed (pause / normal); 2-9 read their configured slider.
[_modName, "Bro_SCam_Num0", "Timescale: Numpad 0 (Pause)",  { [0] call Bro_SCam_SetTimescale }, {}, [DIK_NUMPAD0, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Num1", "Timescale: Numpad 1 (Normal)", { [1] call Bro_SCam_SetTimescale }, {}, [DIK_NUMPAD1, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Num2", "Timescale: Numpad 2", { [missionNamespace getVariable ["Bro_SCam_TS_Num2", 0.10]] call Bro_SCam_SetTimescale }, {}, [DIK_NUMPAD2, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Num3", "Timescale: Numpad 3", { [missionNamespace getVariable ["Bro_SCam_TS_Num3", 0.25]] call Bro_SCam_SetTimescale }, {}, [DIK_NUMPAD3, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Num4", "Timescale: Numpad 4", { [missionNamespace getVariable ["Bro_SCam_TS_Num4", 0.50]] call Bro_SCam_SetTimescale }, {}, [DIK_NUMPAD4, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Num5", "Timescale: Numpad 5", { [missionNamespace getVariable ["Bro_SCam_TS_Num5", 0.75]] call Bro_SCam_SetTimescale }, {}, [DIK_NUMPAD5, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Num6", "Timescale: Numpad 6", { [missionNamespace getVariable ["Bro_SCam_TS_Num6", 1.50]] call Bro_SCam_SetTimescale }, {}, [DIK_NUMPAD6, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Num7", "Timescale: Numpad 7", { [missionNamespace getVariable ["Bro_SCam_TS_Num7", 2.00]] call Bro_SCam_SetTimescale }, {}, [DIK_NUMPAD7, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Num8", "Timescale: Numpad 8", { [missionNamespace getVariable ["Bro_SCam_TS_Num8", 3.00]] call Bro_SCam_SetTimescale }, {}, [DIK_NUMPAD8, [false, false, false]]] call CBA_fnc_addKeybind;
[_modName, "Bro_SCam_Num9", "Timescale: Numpad 9", { [missionNamespace getVariable ["Bro_SCam_TS_Num9", 4.00]] call Bro_SCam_SetTimescale }, {}, [DIK_NUMPAD9, [false, false, false]]] call CBA_fnc_addKeybind;
