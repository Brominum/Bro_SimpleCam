#include "\a3\ui_f\hpp\defineDIKCodes.inc"
if (!hasInterface) exitWith {};
private _modName = "[Bro] Simple Cinematic Camera";

Bro_SCam_SetTimescale = {
	params ["_value"];
	if (isMultiplayer) exitWith {};
	_value = _value max 0 min 4;
	setAccTime _value;
	private _msg = format [localize "STR_Bro_SCam_n_ts_fmt", _value];
	private _d = uiNamespace getVariable ["Bro_SCam_Data", nil];
	if (!isNil "_d" && {_d getOrDefault ["Active", false]}) then {
		[_d, _msg] call (_d get "fnc_Msg");
	} else {
		systemChat _msg;
	};
};

// Setting labels follow the game language: CBA reads them only at this point
{
	_x params ["_id", "_name", "_type", "_value", ["_global", false]];
	[
		"Bro_SCam_" + _name, _type,
		[localize ("STR_Bro_SCam_" + _id + "_lbl"), localize ("STR_Bro_SCam_" + _id + "_tip")],
		_modName, _value, _global
	] call CBA_Settings_fnc_init;
} forEach [
	["s_wl", "Whitelist", "EDITBOX", "", true],
	["s_sp", "SavePos", "CHECKBOX", true],
	["s_hd", "HUDDefault", "CHECKBOX", true],
	["s_ai", "HideAI", "CHECKBOX", false],
	["s_as", "AudioSpectator", "CHECKBOX", true],
	["s_ms", "Sens", "SLIDER", [1, 100, 15, 0]],
	["s_bs", "Speed", "SLIDER", [1, 30, 7, 0]],
	["s_pr", "SmoothPos", "SLIDER", [0.1, 10, 1, 1]],
	["s_rr", "SmoothRot", "SLIDER", [0.1, 10, 1, 1]],
	["s_or", "SmoothBrg", "SLIDER", [0.1, 10, 5, 1]],
	["s_zr", "SmoothFOV", "SLIDER", [0.1, 10, 1, 1]],
	["s_sr", "SmoothSpd", "SLIDER", [0.1, 10, 5, 1]],
	["s_rs", "RollSpeed", "SLIDER", [1, 50, 10, 0]],
	["s_pad", "Controller", "CHECKBOX", false],
	["s_pdz", "PadDeadzone", "SLIDER", [0, 0.4, 0.15, 2]],
	["s_pls", "PadLookSens", "SLIDER", [10, 400, 120, 0]],
	["s_piy", "PadInvertY", "CHECKBOX", false],
	["s_pvs", "PadVertSens", "SLIDER", [0.5, 50, 25, 1]],
	["s_strtp", "StartPaused", "CHECKBOX", false]
];

// Numpad 2-9 timescale presets (Numpad 0 / 1 are fixed at pause / normal)
private _tsPresets = [0.1, 0.25, 0.5, 0.75, 1.5, 2, 3, 4];
{
	[
		format ["Bro_SCam_TS_Num%1", 2 + _forEachIndex], "SLIDER",
		[format [localize "STR_Bro_SCam_s_ts_lbl_fmt", 2 + _forEachIndex], localize "STR_Bro_SCam_s_ts_tip"],
		_modName, [0.05, 4, _x, 2]
	] call CBA_Settings_fnc_init;
} forEach _tsPresets;
[_modName, "Bro_SCam_Open", "Open Camera", { [] execVM "bro_simplecam\simplecam.sqf"; }, {}, [DIK_B, [true, true, false]]] call CBA_fnc_addKeybind;
// Camera keys are read by simplecam.sqf, so these have no handlers; [shift, ctrl, alt]
{
	_x params ["_id", "_label", "_dik", ["_mods", [false, false, false]]];
	[_modName, "Bro_SCam_" + _id, _label, {}, {}, [_dik, _mods]] call CBA_fnc_addKeybind;
} forEach [
	["Exit", "Exit Camera", DIK_SPACE],
	["Move_Fwd", "Move Forward", DIK_W],
	["Move_Back", "Move Back", DIK_S],
	["Move_Left", "Move Left", DIK_A],
	["Move_Right", "Move Right", DIK_D],
	["Move_Up", "Move Up", DIK_Q],
	["Move_Down", "Move Down", DIK_Z],
	["Roll_Left", "Roll Left", DIK_E],
	["Roll_Right", "Roll Right", DIK_R],
	["Roll_Reset", "Reset Roll", DIK_T],
	["Speed_Fast", "Speed Increase", DIK_LSHIFT],
	["Speed_Slow", "Speed Decrease", DIK_LCONTROL],
	["Time_Inc", "Timescale Increase (+)", DIK_EQUALS],
	["Time_Dec", "Timescale Decrease (-)", DIK_MINUS],
	["Reset", "Reset to Target (Keep Modes)", DIK_G],
	["Reset_Full", "Full Reset to Player (All Modes)", DIK_G, [false, false, true]],
	["Follow", "Toggle Follow Mode", DIK_F],
	["Lock_Alt", "Toggle Altitude Lock", DIK_V],
	["Lock_Ori", "Toggle Orientation Lock", DIK_B],
	["Look_At", "Toggle Look At Target", DIK_F, [false, false, true]],
	["Vision", "Cycle Vision Mode", DIK_N],
	["Names", "Toggle Player Names", DIK_P],
	["HUD", "Toggle HUD", DIK_L],
	["Jump_Prev", "Jump to Prev Player", DIK_LEFT],
	["Jump_Next", "Jump to Next Player", DIK_RIGHT],
	["List_Up", "Jump List Up", DIK_UP],
	["List_Down", "Jump List Down", DIK_DOWN],
	["Select", "Select Target", DIK_RETURN]
];
// Timescale hotkeys work anywhere (SP only); Numpad 2-9 read their slider
private _numpad = [DIK_NUMPAD0, DIK_NUMPAD1, DIK_NUMPAD2, DIK_NUMPAD3, DIK_NUMPAD4, DIK_NUMPAD5, DIK_NUMPAD6, DIK_NUMPAD7, DIK_NUMPAD8, DIK_NUMPAD9];
{
	private _code = if (_forEachIndex < 2) then {
		format ["[%1] call Bro_SCam_SetTimescale", _forEachIndex]
	} else {
		format ["[missionNamespace getVariable ['Bro_SCam_TS_Num%1', %2]] call Bro_SCam_SetTimescale", _forEachIndex, _tsPresets select (_forEachIndex - 2)]
	};
	[
		_modName, format ["Bro_SCam_Num%1", _forEachIndex],
		format ["Timescale: Numpad %1%2", _forEachIndex, [" (Pause)", " (Normal)"] param [_forEachIndex, ""]],
		compile _code, {}, [_x, [false, false, false]]
	] call CBA_fnc_addKeybind;
} forEach _numpad;
