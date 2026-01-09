/*
	Simple Cinematic Camera
	Usage: [] execVM "bro_simplecam\simplecam.sqf";
*/
if (!hasInterface) exitWith {};
disableSerialization;
// --- CONSTANTS ---
#define NOTIFY_DURATION 0.3
#define LIST_UPDATE_INTERVAL 2.0
#define HUD_UPDATE_FPS 30
#define MIN_GROUND_CLEARANCE 0.25
// --- WHITELIST CHECK ---
private _wlRaw = missionNamespace getVariable ["Bro_SCam_Whitelist", ""];
if (_wlRaw != "") then {
	private _wlArray = (_wlRaw splitString ",") apply {
		// Efficient whitespace removal
		private _trimmed = _x;
		while {_trimmed select [0, 1] == " "} do { _trimmed = _trimmed select [1] };
		while {_trimmed select [count _trimmed - 1, 1] == " "} do {
			_trimmed = _trimmed select [0, count _trimmed - 1]
		};
		_trimmed
	};
	if !(profileName in _wlArray) exitWith {
		systemChat "ACCESS DENIED: You are not on the Cinematic Camera whitelist.";
		breakOut "main_scope";
	};
};
scopeName "main_scope";
// --- PREVENT MULTIPLE INSTANCES ---
if (!isNil "SCam_Data" && {SCam_Data get "Active"}) exitWith {
	systemChat "Cinematic Camera is already active!";
};
// --- INITIALIZATION ---
SCam_Data = createHashMap;
SCam_Data set ["Active", true];
// --- HELPER FUNCTIONS FOR KEYS ---
SCam_Data set ["fnc_LoadBind", {
	params ["_actionName"];
	private _bind = ["[Bro] Simple Cinematic Camera", _actionName] call CBA_fnc_getKeybind;
	if (isNil "_bind") exitWith { [0, [false,false,false]] };
	_bind select 5
}];
SCam_Data set ["fnc_GetKeyName", {
	params ["_actionName"];
	private _bind = ["[Bro] Simple Cinematic Camera", _actionName] call CBA_fnc_getKeybind;
	if (isNil "_bind") exitWith { "UNBOUND" };
	(_bind select 5) call CBA_fnc_localizeKey;
}];
// --- LOAD KEYBINDS ---
private _d = SCam_Data;
_d set ["K_Exit",  "Bro_SCam_Exit" call (_d get "fnc_LoadBind")];
_d set ["K_HUD",   "Bro_SCam_HUD" call (_d get "fnc_LoadBind")];
_d set ["K_Vis",   "Bro_SCam_Vision" call (_d get "fnc_LoadBind")];
_d set ["K_L_Alt", "Bro_SCam_Lock_Alt" call (_d get "fnc_LoadBind")];
_d set ["K_L_Ori", "Bro_SCam_Lock_Ori" call (_d get "fnc_LoadBind")];
_d set ["K_Rst",   "Bro_SCam_Reset" call (_d get "fnc_LoadBind")];
_d set ["K_Fol",   "Bro_SCam_Follow" call (_d get "fnc_LoadBind")];
_d set ["K_J_Nxt", "Bro_SCam_Jump_Next" call (_d get "fnc_LoadBind")];
_d set ["K_J_Prv", "Bro_SCam_Jump_Prev" call (_d get "fnc_LoadBind")];
_d set ["K_L_Up",  "Bro_SCam_List_Up" call (_d get "fnc_LoadBind")];
_d set ["K_L_Dn",  "Bro_SCam_List_Down" call (_d get "fnc_LoadBind")];
_d set ["K_M_F",   "Bro_SCam_Move_Fwd" call (_d get "fnc_LoadBind")];
_d set ["K_M_B",   "Bro_SCam_Move_Back" call (_d get "fnc_LoadBind")];
_d set ["K_M_L",   "Bro_SCam_Move_Left" call (_d get "fnc_LoadBind")];
_d set ["K_M_R",   "Bro_SCam_Move_Right" call (_d get "fnc_LoadBind")];
_d set ["K_M_U",   "Bro_SCam_Move_Up" call (_d get "fnc_LoadBind")];
_d set ["K_M_D",   "Bro_SCam_Move_Down" call (_d get "fnc_LoadBind")];
_d set ["K_R_L",   "Bro_SCam_Roll_Left" call (_d get "fnc_LoadBind")];
_d set ["K_R_R",   "Bro_SCam_Roll_Right" call (_d get "fnc_LoadBind")];
_d set ["K_R_Rst", "Bro_SCam_Roll_Reset" call (_d get "fnc_LoadBind")];
_d set ["K_S_Fst", "Bro_SCam_Speed_Fast" call (_d get "fnc_LoadBind")];
_d set ["K_S_Slw", "Bro_SCam_Speed_Slow" call (_d get "fnc_LoadBind")];
_d set ["K_T_Inc", "Bro_SCam_Time_Inc" call (_d get "fnc_LoadBind")];
_d set ["K_T_Dec", "Bro_SCam_Time_Dec" call (_d get "fnc_LoadBind")];
// --- CHECK KEY INPUT FUNCTION ---
SCam_Data set ["fnc_CheckKey", {
	params ["_keyId", "_exactMod"];
	private _bindData = SCam_Data get _keyId;
	_bindData params ["_dik", "_reqMods"];
	if !(_dik in (SCam_Data get "Keys")) exitWith { false };
	if (!_exactMod) exitWith { true };
	private _currMods = SCam_Data get "KeyMods";
	if (_currMods isEqualTo _reqMods) exitWith { true };
	false
}];
// --- UNIT LIST MANAGEMENT ---
SCam_Data set ["fnc_GetSortedUnits", {
	private _players = allPlayers select { alive _x };
	private _hideAI = missionNamespace getVariable ["Bro_SCam_HideAI", false];
	private _ai = [];
	if (!_hideAI) then {
		_ai = allUnits select { alive _x && !isPlayer _x && side _x != sideLogic };
	};
	private _fnc_prep = {
		params ["_u", "_isP"];
		private _name = name _u;
		private _veh = vehicle _u;
		private _sortStr = _name;
		if (_veh != _u) then {
			private _vName = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");
			_sortStr = format ["%1 (%2)", _vName, _name];
		};
		[_sortStr, _u, _isP]
	};
	private _pList = _players apply { [_x, true] call _fnc_prep };
	private _aList = _ai apply { [_x, false] call _fnc_prep };
	_pList sort true;
	_aList sort true;
	(_pList + _aList)
}];
SCam_Data set ["fnc_UpdateListUI", {
	private _d = SCam_Data;
	if !(_d get "HUD_Vis") exitWith { (_d get "HUD_List") ctrlShow false; };
	private _target = _d get "Target";
	// Validate target before using
	if (isNull _target || {!alive _target}) exitWith {
		(_d get "HUD_List") ctrlShow false;
	};
	private _fullList = call (_d get "fnc_GetSortedUnits");
	_d set ["CachedList", _fullList];
	private _curIdx = _fullList findIf { (_x select 1) == _target };
	if (_curIdx == -1) then { _curIdx = 0; };
	private _count = count _fullList;
	private _range = 10;
	private _start = (_curIdx - _range) max 0;
	private _end = (_curIdx + _range) min (_count - 1);
	private _text = "";
	for "_i" from _start to _end do {
		private _item = _fullList select _i;
		_item params ["_displayName", "_u", "_isP"];
		private _color = "#dddddd";
		if (_isP) then { _color = "#00aaff"; };
		if (_i == _curIdx) then { _color = "#ffcc00"; };
		private _prefix = if (_isP) then { "[PL]" } else { "[AI]" };
		_text = _text + format ["<t color='%1' size='0.8' font='RobotoCondensedBold'>%2 %3</t><br/>", _color, _prefix, _displayName];
	};
	private _hudList = _d get "HUD_List";
	_hudList ctrlSetStructuredText parseText _text;
	_hudList ctrlShow true;
}];
// --- AUDIO INTEGRATION FUNCTION ---
SCam_Data set ["fnc_SetAudioSpectator", {
	params ["_state"];
	// TFAR Integration (Support for both 0.9.x and 1.0+)
	if (isClass (configFile >> "CfgPatches" >> "task_force_radio") || isClass (configFile >> "CfgPatches" >> "TFAR_Core")) then {
		try {
			// New TFAR (1.0+)
			if (!isNil "tfar_fnc_forceSpectator") then {
				[player, _state] call tfar_fnc_forceSpectator;
			} else {
				// Old TFAR (0.9.12)
				if (!isNil "tf_radio_fnc_forceSpectator") then {
					[player, _state] call tf_radio_fnc_forceSpectator;
				};
			};
		} catch {
			diag_log format ["[SimpleCam] TFAR spectator mode failed: %1", _exception];
		};
	};
	// ACRE2 Integration
	if (isClass (configFile >> "CfgPatches" >> "acre_main")) then {
		try {
			if (!isNil "acre_api_fnc_setSpectator") then {
				[_state] call acre_api_fnc_setSpectator;
			};
		} catch {
			diag_log format ["[SimpleCam] ACRE spectator mode failed: %1", _exception];
		};
	};
}];
// --- CAMERA SETUP & STATE RESTORATION ---
private _useSavedState = missionNamespace getVariable ["Bro_SCam_SavePos", false];
private _lastState = missionNamespace getVariable "Bro_SCam_LastState";
private _startPos = getPosASLVisual player;
private _startAng = [getDir player, 0];
private _startRoll = 0;
private _startFov = 0.7;
private _startTarget = player;
if (_useSavedState && !isNil "_lastState") then {
	_startPos = _lastState select 0;
	_startAng = _lastState select 1;
	_startRoll = _lastState select 2;
	_startFov = _lastState select 3;
	// Load saved target if available, not null, and alive
	if (count _lastState > 4) then {
		private _t = _lastState select 4;
		if (!isNull _t && {alive _t}) then {
			_startTarget = _t;
		};
	};
} else {
	_startPos set [2, (_startPos select 2) + 2];
};
private _cam = "camera" camCreate _startPos;
_cam cameraEffect ["Internal", "Back"];
_cam camSetFov _startFov;
showCinemaBorder false;
SCam_Data set ["Cam", _cam];
// --- ENABLE AUDIO SPECTATOR ---
[true] call (SCam_Data get "fnc_SetAudioSpectator");
// --- UI SETUP ---
private _display = findDisplay 46;
private _hudDefault = missionNamespace getVariable ["Bro_SCam_HUDDefault", true];
// 1. Right Info HUD
private _hud = _display ctrlCreate ["RscStructuredText", -1];
_hud ctrlSetPosition [safeZoneX + safeZoneW - 0.45, safeZoneY + safeZoneH - 0.85, 0.45, 0.8];
_hud ctrlSetBackgroundColor [0,0,0,0.5];
_hud ctrlShow _hudDefault;
_hud ctrlCommit 0;
SCam_Data set ["HUD", _hud];
// 2. Left Unit List HUD
private _hudList = _display ctrlCreate ["RscStructuredText", -1];
_hudList ctrlSetPosition [safeZoneX + safeZoneW - 0.45, safeZoneY + safeZoneH - 1.35, 0.45, 0.5];
_hudList ctrlSetBackgroundColor [0,0,0,0.5];
_hudList ctrlShow _hudDefault;
_hudList ctrlCommit 0;
SCam_Data set ["HUD_List", _hudList];
SCam_Data set ["LastListUpdate", 0];
SCam_Data set ["CachedList", []];
// Generate HUD Strings ONCE
private _s_move = format["[%1%2%3%4]", "Bro_SCam_Move_Fwd" call (_d get "fnc_GetKeyName"), "Bro_SCam_Move_Left" call (_d get "fnc_GetKeyName"), "Bro_SCam_Move_Back" call (_d get "fnc_GetKeyName"), "Bro_SCam_Move_Right" call (_d get "fnc_GetKeyName")];
private _s_ud   = format["[%1/%2]", "Bro_SCam_Move_Up" call (_d get "fnc_GetKeyName"), "Bro_SCam_Move_Down" call (_d get "fnc_GetKeyName")];
private _s_roll = format["[%1/%2]", "Bro_SCam_Roll_Left" call (_d get "fnc_GetKeyName"), "Bro_SCam_Roll_Right" call (_d get "fnc_GetKeyName")];
private _s_rstR = format["[%1]", "Bro_SCam_Roll_Reset" call (_d get "fnc_GetKeyName")];
private _s_spd  = format["[%1/%2]", "Bro_SCam_Speed_Fast" call (_d get "fnc_GetKeyName"), "Bro_SCam_Speed_Slow" call (_d get "fnc_GetKeyName")];
private _s_fol  = format["[%1]", "Bro_SCam_Follow" call (_d get "fnc_GetKeyName")];
private _s_jmp  = format["[%1/%2]", "Bro_SCam_Jump_Prev" call (_d get "fnc_GetKeyName"), "Bro_SCam_Jump_Next" call (_d get "fnc_GetKeyName")];
private _s_lst  = format["[%1/%2]", "Bro_SCam_List_Up" call (_d get "fnc_GetKeyName"), "Bro_SCam_List_Down" call (_d get "fnc_GetKeyName")];
private _s_vis  = format["[%1]", "Bro_SCam_Vision" call (_d get "fnc_GetKeyName")];
private _s_rst  = format["[%1]", "Bro_SCam_Reset" call (_d get "fnc_GetKeyName")];
private _s_alt  = format["[%1]", "Bro_SCam_Lock_Alt" call (_d get "fnc_GetKeyName")];
private _s_ori  = format["[%1]", "Bro_SCam_Lock_Ori" call (_d get "fnc_GetKeyName")];
private _s_hud  = format["[%1]", "Bro_SCam_HUD" call (_d get "fnc_GetKeyName")];
private _s_exit = format["[%1]", "Bro_SCam_Exit" call (_d get "fnc_GetKeyName")];
private _s_time = format["[%1/%2]", "Bro_SCam_Time_Inc" call (_d get "fnc_GetKeyName"), "Bro_SCam_Time_Dec" call (_d get "fnc_GetKeyName")];
SCam_Data set ["HUD_Str", [_s_move, _s_ud, _s_roll, _s_rstR, _s_spd, _s_fol, _s_jmp, _s_lst, _s_vis, _s_rst, _s_alt, _s_ori, _s_hud, _s_exit, _s_time]];
private _notify = _display ctrlCreate ["RscStructuredText", -1];
_notify ctrlSetPosition [safeZoneX + (safeZoneW * 0.3), safeZoneY + safeZoneH - 0.15, safeZoneW * 0.4, 0.06];
_notify ctrlSetBackgroundColor [0,0,0,0];
_notify ctrlShow false;
_notify ctrlCommit 0;
SCam_Data set ["Notify", _notify];
SCam_Data set ["NotifyEnd", 0];
// --- POPULATE STATE ---
SCam_Data set ["Keys", []];
SCam_Data set ["KeyMods", [false, false, false]];
SCam_Data set ["MouseD", [0,0]];
SCam_Data set ["Pos", _startPos];
SCam_Data set ["PosDes", _startPos];
SCam_Data set ["Ang", _startAng];
SCam_Data set ["AngDes", _startAng];
SCam_Data set ["RotOffset", [0, 0, 0]];
SCam_Data set ["Roll", _startRoll];
SCam_Data set ["RollDes", _startRoll];
SCam_Data set ["Fov", _startFov];
SCam_Data set ["FovDes", _startFov];
SCam_Data set ["SpeedMult", 1.0];
SCam_Data set ["SpeedMultDes", 1.0];
SCam_Data set ["Target", _startTarget];
SCam_Data set ["HUD_Vis", _hudDefault];
SCam_Data set ["EH_List", []];
SCam_Data set ["Follow", false];
SCam_Data set ["VisionMode", 0];
SCam_Data set ["AltLock", false];
SCam_Data set ["OrientLock", false];
SCam_Data set ["LastHUDUpdate", 0];
// --- HELPER FUNCTIONS ---
SCam_Data set ["fnc_Msg", {
	params ["_text"];
	private _d = SCam_Data;
	private _ctrl = _d get "Notify";
	_ctrl ctrlSetStructuredText parseText format ["<t align='center' size='0.8' font='RobotoCondensed'>%1</t>", _text];
	_ctrl ctrlShow true;
	_d set ["NotifyEnd", diag_tickTime + NOTIFY_DURATION];
}];
SCam_Data set ["fnc_Exit", {
	disableSerialization;
	private _data = SCam_Data;
	// Mark as inactive immediately
	_data set ["Active", false];
	private _display = findDisplay 46;
	// Save State logic
	if (missionNamespace getVariable ["Bro_SCam_SavePos", false]) then {
		private _savePos = _data get "Pos";
		if (_data get "Follow") then {
			private _target = _data get "Target";
			if (!isNull _target && {alive _target}) then {
				_savePos = (getPosASLVisual _target) vectorAdd _savePos;
			};
		};
		missionNamespace setVariable ["Bro_SCam_LastState", [
			_savePos,
			_data get "Ang",
			_data get "Roll",
			_data get "Fov",
			_data get "Target"
		]];
	};
	// Remove event handlers
	private _ehList = _data get "EH_List";
	if (count _ehList > 0) then {
		_display displayRemoveEventHandler ["KeyDown", _ehList select 0];
		_display displayRemoveEventHandler ["KeyUp", _ehList select 1];
		_display displayRemoveEventHandler ["MouseMoving", _ehList select 2];
		_display displayRemoveEventHandler ["MouseZChanged", _ehList select 3];
		removeMissionEventHandler ["EachFrame", _ehList select 4];
	};
	// Cleanup camera
	private _cam = _data get "Cam";
	if (!isNil "_cam" && {!isNull _cam}) then {
		_cam cameraEffect ["Terminate", "Back"];
		camDestroy _cam;
	};
	// Cleanup UI
	ctrlDelete (_data get "HUD");
	ctrlDelete (_data get "HUD_List");
	ctrlDelete (_data get "Notify");
	// Reset vision modes
	camUseNVG false;
	false setCamUseTi 0;
	// Disable audio spectator
	[false] call (_data get "fnc_SetAudioSpectator");
	// Clear data
	SCam_Data = nil;
}];
// --- EVENT HANDLERS ---
private _ehIds = [];
// 1. KeyDown
_ehIds pushBack (_display displayAddEventHandler ["KeyDown", {
	params ["_disp", "_key", "_shift", "_ctrl", "_alt"];
	private _d = SCam_Data;
	if (isNil "_d" || {!(_d get "Active")}) exitWith { true };
	_d set ["KeyMods", [_shift, _ctrl, _alt]];
	private _keys = _d get "Keys";
	if !(_key in _keys) then { _keys pushBack _key; };
	private _fnc_Trigger = {
		params ["_bindId"];
		private _bindData = _d get _bindId;
		if (_key != (_bindData select 0)) exitWith { false };
		if !((_d get "KeyMods") isEqualTo (_bindData select 1)) exitWith { false };
		true
	};
	// --- TRIGGER ACTIONS ---
	if ("K_Exit" call _fnc_Trigger) exitWith { [] call (_d get "fnc_Exit"); true };
	if ("K_HUD" call _fnc_Trigger) then {
		private _v = !(_d get "HUD_Vis");
		_d set ["HUD_Vis", _v];
		(_d get "HUD") ctrlShow _v;
		(_d get "HUD_List") ctrlShow _v;
		if (_v) then { [] call (_d get "fnc_UpdateListUI"); };
	};
	if ("K_Vis" call _fnc_Trigger) then {
		private _mode = _d get "VisionMode";
		_mode = _mode + 1;
		if (_mode > 3) then { _mode = 0; };
		_d set ["VisionMode", _mode];
		private _msg = switch (_mode) do {
			case 0: { camUseNVG false; false setCamUseTi 0; "Vision: Normal"; };
			case 1: { camUseNVG true; false setCamUseTi 0; "Vision: NVG"; };
			case 2: { camUseNVG false; true setCamUseTi 0; "Vision: White Hot"; };
			case 3: { camUseNVG false; true setCamUseTi 1; "Vision: Black Hot"; };
		};
		[_msg] call (_d get "fnc_Msg");
	};
	// Timescale Logic (SP Only)
	if (!isMultiplayer) then {
		if ("K_T_Inc" call _fnc_Trigger) then {
			private _now = accTime;
			private _next = _now;
			if (_now >= 1.0) then {
				_next = _now + 0.1;
			} else {
				_next = _now + 0.02;
			};
			_next = (round (_next * 100)) / 100;
			if (_next > 4.0) then { _next = 4.0; };
			setAccTime _next;
			[format ["Timescale: %1", _next]] call (_d get "fnc_Msg");
		};
		if ("K_T_Dec" call _fnc_Trigger) then {
			private _now = accTime;
			private _next = _now;
			if (_now > 1.001) then {
				_next = _now - 0.1;
			} else {
				_next = _now - 0.02;
			};
			_next = (round (_next * 100)) / 100;
			if (_next < 0) then { _next = 0; };
			setAccTime _next;
			[format ["Timescale: %1", _next]] call (_d get "fnc_Msg");
		};
	};
	if ("K_L_Alt" call _fnc_Trigger) then {
		private _l = !(_d get "AltLock");
		_d set ["AltLock", _l];
		[if (_l) then {"Altitude Lock: ON"} else {"Altitude Lock: OFF"}] call (_d get "fnc_Msg");
	};
	if ("K_L_Ori" call _fnc_Trigger) then {
		private _b = !(_d get "OrientLock");
		_d set ["OrientLock", _b];
		if (_b) then {
			private _currAng = _d get "AngDes";
			private _currRoll = _d get "RollDes";
			private _target = _d get "Target";
			if (isNull _target || {!alive _target}) exitWith {
				_d set ["OrientLock", false];
				["Orientation Lock: FAILED (Invalid Target)"] call (_d get "fnc_Msg");
			};
			private _refObj = vehicle _target;
			if (isNull _refObj || {!alive _refObj}) exitWith {
				_d set ["OrientLock", false];
				["Orientation Lock: FAILED (Invalid Vehicle)"] call (_d get "fnc_Msg");
			};
			private _tgtDir = getDirVisual _refObj;
			private _vDir = vectorDirVisual _refObj;
			private _vUp = vectorUpVisual _refObj;
			private _tgtPitch = asin (_vDir select 2);
			private _vSide = _vDir vectorCrossProduct _vUp;
			private _tgtBank = (_vSide select 2) atan2 (_vUp select 2);
			private _diffYaw = (_currAng select 0) - _tgtDir;
			if (_diffYaw > 180) then { _diffYaw = _diffYaw - 360; };
			if (_diffYaw < -180) then { _diffYaw = _diffYaw + 360; };
			private _diffPitch = (_currAng select 1) - _tgtPitch;
			private _diffRoll = _currRoll - _tgtBank;
			_d set ["RotOffset", [_diffYaw, _diffPitch, _diffRoll]];
			["Orientation Lock: ON"] call (_d get "fnc_Msg");
		} else {
			["Orientation Lock: OFF"] call (_d get "fnc_Msg");
		};
	};
	if ("K_Rst" call _fnc_Trigger) then {
		private _target = _d get "Target";
		if (isNull _target || {!alive _target}) exitWith {
			["Reset: FAILED (Invalid Target)"] call (_d get "fnc_Msg");
		};
		private _pPos = getPosASLVisual _target;
		private _resetPos = _pPos vectorAdd [0,0,2];
		if (_d get "Follow") then {
			_d set ["Pos", [0,0,2]];
			_d set ["PosDes", [0,0,2]];
		} else {
			_d set ["Pos", _resetPos];
			_d set ["PosDes", _resetPos];
		};
		_d set ["AngDes", [getDir _target, 0]];
		_d set ["Ang", [getDir _target, 0]];
		_d set ["RollDes", 0];
		_d set ["Roll", 0];
		_d set ["SpeedMultDes", 1.0];
		_d set ["SpeedMult", 1.0];
		_d set ["FovDes", 0.7];
		_d set ["Fov", 0.7];
		(_d get "Cam") camSetFov 0.7;
		_d set ["AltLock", false];
		_d set ["OrientLock", false];
		["Camera Reset"] call (_d get "fnc_Msg");
		[] call (_d get "fnc_UpdateListUI");
	};
	if ("K_Fol" call _fnc_Trigger) then {
		private _isFollowing = _d get "Follow";
		private _target = _d get "Target";
		if (isNull _target || {!alive _target}) exitWith {
			["Follow: FAILED (Invalid Target)"] call (_d get "fnc_Msg");
		};
		private _currPos = _d get "Pos";
		private _currPosDes = _d get "PosDes";
		private _tPos = getPosASLVisual _target;
		if (_isFollowing) then {
			_d set ["Pos", _tPos vectorAdd _currPos];
			_d set ["PosDes", _tPos vectorAdd _currPosDes];
			["Follow Mode: OFF"] call (_d get "fnc_Msg");
		} else {
			_d set ["Pos", _currPos vectorDiff _tPos];
			_d set ["PosDes", _currPosDes vectorDiff _tPos];
			["Follow Mode: ON"] call (_d get "fnc_Msg");
		};
		_d set ["Follow", !_isFollowing];
	};
	if (("K_J_Prv" call _fnc_Trigger) || ("K_J_Nxt" call _fnc_Trigger)) then {
		private _list = allPlayers select { alive _x };
		_list sort true;
		if (count _list > 0) then {
			private _curr = _d get "Target";
			private _idx = _list find _curr;
			if (_idx == -1) then { _idx = 0; };
			if ("K_J_Nxt" call _fnc_Trigger) then { _idx = _idx + 1; } else { _idx = _idx - 1; };
			if (_idx >= count _list) then { _idx = 0; };
			if (_idx < 0) then { _idx = (count _list) - 1; };
			private _newTarget = _list select _idx;
			_d set ["Target", _newTarget];
			private _newTPos = getPosASLVisual _newTarget;
			if (_d get "Follow") then {
				_d set ["Pos", [0,0,2]];
				_d set ["PosDes", [0,0,2]];
			} else {
				_d set ["Pos", _newTPos vectorAdd [0,0,2]];
				_d set ["PosDes", _newTPos vectorAdd [0,0,2]];
			};
			_d set ["AngDes", [getDir _newTarget, 0]];
			_d set ["Ang", [getDir _newTarget, 0]];
			_d set ["RollDes", 0];
			_d set ["Roll", 0];
			[format ["Jump to Player: %1", name _newTarget]] call (_d get "fnc_Msg");
			[] call (_d get "fnc_UpdateListUI");
		};
	};
	if (("K_L_Up" call _fnc_Trigger) || ("K_L_Dn" call _fnc_Trigger)) then {
		private _fullList = call (_d get "fnc_GetSortedUnits");
		if (count _fullList > 0) then {
			private _curr = _d get "Target";
			private _idx = _fullList findIf { (_x select 1) == _curr };
			if (_idx == -1) then { _idx = 0; };
			if ("K_L_Dn" call _fnc_Trigger) then { _idx = _idx + 1; } else { _idx = _idx - 1; };
			if (_idx >= count _fullList) then { _idx = 0; };
			if (_idx < 0) then { _idx = (count _fullList) - 1; };
			private _newTarget = (_fullList select _idx) select 1;
			_d set ["Target", _newTarget];
			private _newTPos = getPosASLVisual _newTarget;
			if (_d get "Follow") then {
				_d set ["Pos", [0,0,2]];
				_d set ["PosDes", [0,0,2]];
			} else {
				_d set ["Pos", _newTPos vectorAdd [0,0,2]];
				_d set ["PosDes", _newTPos vectorAdd [0,0,2]];
			};
			_d set ["AngDes", [getDir _newTarget, 0]];
			_d set ["Ang", [getDir _newTarget, 0]];
			_d set ["RollDes", 0];
			_d set ["Roll", 0];
			[format ["Jump to: %1", name _newTarget]] call (_d get "fnc_Msg");
			[] call (_d get "fnc_UpdateListUI");
		};
	};
	false
}]);
// 2. KeyUp
_ehIds pushBack (_display displayAddEventHandler ["KeyUp", {
	params ["_disp", "_key", "_shift", "_ctrl", "_alt"];
	private _d = SCam_Data;
	if (isNil "_d" || {!(_d get "Active")}) exitWith { true };
	_d set ["KeyMods", [_shift, _ctrl, _alt]];
	_d set ["Keys", (_d get "Keys") - [_key]];
	false
}]);
// 3. MouseMoving
_ehIds pushBack (_display displayAddEventHandler ["MouseMoving", {
	params ["_disp", "_x", "_y"];
	if (isNil "SCam_Data" || {!(SCam_Data get "Active")}) exitWith { true };
	SCam_Data set ["MouseD", [_x, _y]];
	false
}]);
// 4. Scroll
_ehIds pushBack (_display displayAddEventHandler ["MouseZChanged", {
	params ["_disp", "_z"];
	private _d = SCam_Data;
	if (isNil "_d" || {!(_d get "Active")}) exitWith { true };
	private _des = _d get "FovDes";
	private _change = _z * 0.05;
	_d set ["FovDes", (_des - _change) max 0.01 min 2.0];
	false
}]);
// 5. EachFrame
_ehIds pushBack (addMissionEventHandler ["EachFrame", {
	if (isNil "SCam_Data" || {!(SCam_Data get "Active")}) exitWith {
		// Cleanup if somehow data was cleared without proper exit
		removeMissionEventHandler ["EachFrame", _thisEventHandler];
	};
	private _d = SCam_Data;
	// Cache config values (read once per frame instead of multiple times)
	private _cfgSens = (missionNamespace getVariable ["Bro_SCam_Sens", 15]) / 100;
	private _cfgRollSpeed = (missionNamespace getVariable ["Bro_SCam_RollSpeed", 10]) / 100;
	private _cfgSmoothRot = (missionNamespace getVariable ["Bro_SCam_SmoothRot", 1]) / 100;
	private _cfgSmoothBrg = (missionNamespace getVariable ["Bro_SCam_SmoothBrg", 5]) / 100;
	private _cfgSmoothPos = (missionNamespace getVariable ["Bro_SCam_SmoothPos", 1]) / 100;
	private _cfgSmoothFOV = (missionNamespace getVariable ["Bro_SCam_SmoothFOV", 1]) / 100;
	private _cfgSmoothSpd = (missionNamespace getVariable ["Bro_SCam_SmoothSpd", 5]) / 100;
	private _speed = (missionNamespace getVariable ["Bro_SCam_Speed", 7]) / 100;
	private _mouse = _d get "MouseD";
	_d set ["MouseD", [0,0]];
	private _fov = _d get "Fov";
	private _sens = _cfgSens * _fov;
	private _angDes = _d get "AngDes";
	private _angCurr = _d get "Ang";
	private _rollDes = _d get "RollDes";
	// Cache fnc_CheckKey
	private _checkKey = _d get "fnc_CheckKey";
	if (_d get "OrientLock") then {
		private _target = _d get "Target";
		// Validate target before using
		if (isNull _target || {!alive _target}) then {
			_d set ["OrientLock", false];
			["Orientation Lock: DISABLED (Target Lost)"] call (_d get "fnc_Msg");
		} else {
			private _rotOffset = _d get "RotOffset";
			_rotOffset set [0, (_rotOffset select 0) + ((_mouse select 0) * _sens)];
			_rotOffset set [1, ((_rotOffset select 1) - ((_mouse select 1) * _sens)) max -89 min 89];
			if (["K_R_L", false] call _checkKey) then { _rotOffset set [2, (_rotOffset select 2) - _cfgRollSpeed]; };
			if (["K_R_R", false] call _checkKey) then { _rotOffset set [2, (_rotOffset select 2) + _cfgRollSpeed]; };
			if (["K_R_Rst", false] call _checkKey) then { _rotOffset set [2, 0]; };
			_d set ["RotOffset", _rotOffset];
			private _refObj = vehicle _target;
			// Validate vehicle
			if (!isNull _refObj && {alive _refObj}) then {
				private _tgtDir = getDirVisual _refObj;
				private _vDir = vectorDirVisual _refObj;
				private _vUp = vectorUpVisual _refObj;
				private _tgtPitch = asin (_vDir select 2);
				private _vSide = _vDir vectorCrossProduct _vUp;
				private _tgtBank = (_vSide select 2) atan2 (_vUp select 2);
				private _yawDes = _tgtDir + (_rotOffset select 0);
				private _pitDes = _tgtPitch + (_rotOffset select 1);
				_rollDes = _tgtBank + (_rotOffset select 2);
				_d set ["AngDes", [_yawDes, _pitDes]];
				_d set ["RollDes", _rollDes];
			} else {
				_d set ["OrientLock", false];
				["Orientation Lock: DISABLED (Vehicle Lost)"] call (_d get "fnc_Msg");
			};
		};
	} else {
		// Free look
		private _yawDes = (_angDes select 0) + ((_mouse select 0) * _sens);
		private _pitDes = ((_angDes select 1) - ((_mouse select 1) * _sens)) max -89 min 89;
		_d set ["AngDes", [_yawDes, _pitDes]];
		if (["K_R_L", false] call _checkKey) then { _rollDes = _rollDes - _cfgRollSpeed; };
		if (["K_R_R", false] call _checkKey) then { _rollDes = _rollDes + _cfgRollSpeed; };
		if (["K_R_Rst", false] call _checkKey) then { _rollDes = 0; };
		_d set ["RollDes", _rollDes];
	};
	// --- SMOOTHING ---
	private _ang = _d get "Ang";
	private _roll = _d get "Roll";
	// Standard Linear Interpolation
	private _lerp = { params ["_a", "_b", "_t"]; _a + ((_b - _a) * _t) };
	// Optimized Angular Interpolation
	private _lerpAngle = {
		params ["_cur", "_des", "_t"];
		private _diff = _des - _cur;
		// Normalize to -180..180 using efficient calculation
		_diff = _diff - (360 * floor((_diff + 180) / 360));
		_cur + (_diff * _t)
	};
	private _rotSmooth = if (_d get "OrientLock") then { _cfgSmoothBrg } else { _cfgSmoothRot };
	private _yawNew = [_ang select 0, (_d get "AngDes") select 0, _rotSmooth] call _lerpAngle;
	private _pitNew = [_ang select 1, (_d get "AngDes") select 1, _rotSmooth] call _lerp;
	private _rollSmooth = if (_d get "OrientLock") then { _rotSmooth } else { _cfgSmoothRot };
	private _rollNew = [_roll, _rollDes, _rollSmooth] call _lerpAngle;
	_d set ["Ang", [_yawNew, _pitNew]];
	_d set ["Roll", _rollNew];
	// --- VECTOR CALCULATION (Always calculate for smooth camera) ---
	private _vx = sin(_yawNew) * cos(_pitNew);
	private _vy = cos(_yawNew) * cos(_pitNew);
	private _vz = sin(_pitNew);
	private _vecDir = [_vx, _vy, _vz];
	private _vecRightH = [cos(_yawNew), -sin(_yawNew), 0];
	private _vecUpBase = _vecRightH vectorCrossProduct _vecDir;
	private _vecUp = (_vecUpBase vectorMultiply cos(_rollNew)) vectorAdd (_vecRightH vectorMultiply sin(_rollNew));
	private _vecFwdFlat = [_vx, _vy, 0];
	if (vectorMagnitude _vecFwdFlat > 0) then { _vecFwdFlat = vectorNormalized _vecFwdFlat; };
	// --- SPEED ---
	private _spdDes = _d get "SpeedMultDes";
	if (["K_S_Fst", false] call _checkKey) then { _spdDes = _spdDes * 1.02; };
	if (["K_S_Slw", false] call _checkKey) then { _spdDes = _spdDes * 0.98; };
	_spdDes = _spdDes max 0.01 min 200;
	_d set ["SpeedMultDes", _spdDes];
	private _currSpd = _d get "SpeedMult";
	private _newSpd = [_currSpd, _spdDes, _cfgSmoothSpd] call _lerp;
	_d set ["SpeedMult", _newSpd];
	// --- MOVEMENT ---
	private _finalSpeed = _speed * _newSpd;
	private _moveVec = [0,0,0];
	private _lock = _d get "AltLock";
	private _fwdRef = if (_lock) then { _vecFwdFlat } else { _vecDir };
	if (["K_M_F", false] call _checkKey) then { _moveVec = _moveVec vectorAdd _fwdRef; };
	if (["K_M_B", false] call _checkKey) then { _moveVec = _moveVec vectorDiff _fwdRef; };
	if (["K_M_R", false] call _checkKey) then { _moveVec = _moveVec vectorAdd _vecRightH; };
	if (["K_M_L", false] call _checkKey) then { _moveVec = _moveVec vectorDiff _vecRightH; };
	if (["K_M_U", false] call _checkKey) then { _moveVec = _moveVec vectorAdd [0,0,1]; };
	if (["K_M_D", false] call _checkKey) then { _moveVec = _moveVec vectorAdd [0,0,-1]; };
	if (vectorMagnitude _moveVec > 0) then {
		_moveVec = (vectorNormalized _moveVec) vectorMultiply _finalSpeed;
	};
	private _posDes = (_d get "PosDes") vectorAdd _moveVec;
	// --- TERRAIN-ONLY GROUND CHECK (Allows underwater) ---
	private _target = _d get "Target";
	private _targetBase = if (_d get "Follow" && {!isNull _target && {alive _target}}) then {
		getPosASLVisual _target
	} else {
		[0,0,0]
	};
	private _absPosDes = _targetBase vectorAdd _posDes;
	private _terrZ = getTerrainHeightASL _absPosDes;
	// Only check terrain height, not water - allows underwater filming
	private _minZ = _terrZ + MIN_GROUND_CLEARANCE;
	if ((_absPosDes select 2) < _minZ) then {
		_absPosDes set [2, _minZ];
	};
	if (_d get "Follow") then {
		_posDes = _absPosDes vectorDiff _targetBase;
	} else {
		_posDes = _absPosDes;
	};
	_d set ["PosDes", _posDes];
	private _pos = (_d get "Pos");
	_pos = _pos vectorAdd ((_posDes vectorDiff _pos) vectorMultiply _cfgSmoothPos);
	_d set ["Pos", _pos];
	// --- FINAL POSITION ---
	private _finalCamPos = [0,0,0];
	if (_d get "Follow" && {!isNull _target && {alive _target}}) then {
		private _tPos = getPosASLVisual _target;
		_finalCamPos = _tPos vectorAdd _pos;
	} else {
		_finalCamPos = _pos;
	};
	// --- FOV ---
	private _fovDes = _d get "FovDes";
	private _fovNew = [_fov, _fovDes, _cfgSmoothFOV] call _lerp;
	_d set ["Fov", _fovNew];
	(_d get "Cam") camSetFov _fovNew;
	// --- PERIODIC UI UPDATE (Slow) ---
	if (diag_tickTime > (_d get "LastListUpdate") + LIST_UPDATE_INTERVAL) then {
		_d set ["LastListUpdate", diag_tickTime];
		if (_d get "HUD_Vis") then { [] call (_d get "fnc_UpdateListUI"); };
	};
	// --- THROTTLED HUD UPDATE (30 FPS) ---
	if (_d get "HUD_Vis" && {diag_tickTime > (_d get "LastHUDUpdate") + (1 / HUD_UPDATE_FPS)}) then {
		_d set ["LastHUDUpdate", diag_tickTime];
		private _followTxt = if (_d get "Follow") then { "<t color='#ff0000'>[FOLLOW]</t>" } else { "" };
		private _lockTxt = if (_lock) then { "<t color='#ff0000'>[LOCK]</t>" } else { "<t color='#888888'>OFF</t>" };
		private _oriTxt = if (_d get "OrientLock") then { "<t color='#ff0000'>[LOCK]</t>" } else { "<t color='#888888'>OFF</t>" };
		private _tgtName = "NONE";
		if (!isNull _target && {alive _target}) then {
			_tgtName = name _target;
		};
		private _visMode = _d get "VisionMode";
		private _visStr = switch (_visMode) do {
			case 0: {"NORM"};
			case 1: {"NVG"};
			case 2: {"WHOT"};
			case 3: {"BHOT"};
			default {"NORM"};
		};
		(_d get "HUD_Str") params ["_s_move", "_s_ud", "_s_roll", "_s_rstR", "_s_spd", "_s_fol", "_s_jmp", "_s_lst", "_s_vis", "_s_rst", "_s_alt", "_s_ori", "_s_hud", "_s_exit", "_s_time"];
		(_d get "HUD") ctrlSetStructuredText parseText format [
			"<t align='left' size='1.2' font='RobotoCondensedLight'>" +
			"SPD: <t color='#00ff00'>%1</t><br/>" +
			"FOV: <t color='#00ffff'>%2</t><br/>" +
			"ROL: <t color='#ff00ff'>%3</t><br/>" +
			"ALT: %8<br/>" +
			"ORI: %9<br/>" +
			"POS: <t color='#ffff00'>%4</t> %5<br/>" +
			"TGT: <t color='#ffa500'>%6</t><br/>" +
			"VIS: <t color='#ffa500'>%7</t><br/>" +
			"TIME: <t color='#00ff00'>%24</t><br/>" +
			"<t size='0.8'>------------------------------</t><br/>" +
			"<t size='0.8' color='#dddddd'>CONTROLS</t><br/>" +
			"<t size='0.8'>" +
			"%10 Move <t color='#888888'>|</t> %11 Up/Down<br/>" +
			"%12 Roll <t color='#888888'>|</t> %13 Reset Roll<br/>" +
			"[Scroll] Zoom <t color='#888888'>|</t> %14 Speed<br/>" +
			"%15 Follow <t color='#888888'>|</t> %16 Players<br/>" +
			"%17 List Select <t color='#888888'>|</t> %18 Vision<br/>" +
			"%19 Reset <t color='#888888'>|</t> %20 Alt Lock<br/>" +
			"%21 Ori Lock <t color='#888888'>|</t> %22 HUD <t color='#888888'>|</t> %23 Exit<br/>" +
			"%25 Timescale" +
			"</t></t>",
			round(_newSpd * 100) / 100,
			round(_fovNew * 100) / 100,
			round(_rollNew * 10) / 10,
			mapGridPosition _finalCamPos,
			_followTxt,
			_tgtName,
			_visStr,
			_lockTxt,
			_oriTxt,
			_s_move, _s_ud, _s_roll, _s_rstR, _s_spd, _s_fol, _s_jmp, _s_lst, _s_vis, _s_rst, _s_alt, _s_ori, _s_hud, _s_exit,
			accTime, _s_time
		];
	};
	// --- NOTIFICATION TIMEOUT ---
	if (diag_tickTime > (_d get "NotifyEnd")) then {
		(_d get "Notify") ctrlShow false;
	};
	// --- COMMIT ---
	private _cam = _d get "Cam";
	if (!isNil "_cam" && {!isNull _cam}) then {
		_cam setPosASL _finalCamPos;
		_cam setVectorDirAndUp [_vecDir, _vecUp];
		_cam camCommit 0;
	};
}]);
SCam_Data set ["EH_List", _ehIds];
["Cinematic Camera ON"] call (SCam_Data get "fnc_Msg");
[] call (SCam_Data get "fnc_UpdateListUI");