/*
	Simple Cinematic Camera
	Usage: [] execVM "bro_simplecam\simplecam.sqf";
*/
if (!hasInterface) exitWith {};
disableSerialization;
#define MOD_NAME "[Bro] Simple Cinematic Camera"
#define NOTIFY_DURATION 0.3
#define LIST_UPDATE_INTERVAL 2.0
#define HUD_UPDATE_FPS 30
#define MIN_GROUND_CLEARANCE 0.25
// Xbox buttons arrive through KeyDown as extended DIK codes
#define DIK_XBOX_A 327680
#define DIK_XBOX_B 327681
#define DIK_XBOX_X 327682
#define DIK_XBOX_Y 327683
#define DIK_XBOX_DPAD_UP 327684
#define DIK_XBOX_DPAD_DOWN 327685
#define DIK_XBOX_DPAD_LEFT 327686
#define DIK_XBOX_DPAD_RIGHT 327687
#define DIK_XBOX_START 327688
#define DIK_XBOX_BACK 327689
#define DIK_XBOX_LB 327690
#define DIK_XBOX_RB 327691
#define DIK_XBOX_LT 327692
#define DIK_XBOX_RT 327693
#define DIK_XBOX_L3 327694
#define DIK_XBOX_R3 327695
#define C_LABEL "#aaaaaa"
#define C_DIM "#888888"
#define C_OFF "#444444"
#define C_ACCENT "#00dbff"
#define C_WARN "#ffaa00"
#define C_ERR "#ff3333"
#define C_GOOD "#33ff33"

// --- ACCESS CHECKS ---
private _wlRaw = missionNamespace getVariable ["Bro_SCam_Whitelist", ""];
private _allowed = _wlRaw == "";
if (!_allowed) then {
	{
		private _name = _x;
		while {_name select [0, 1] == " "} do { _name = _name select [1] };
		while {count _name > 0 && {_name select [count _name - 1, 1] == " "}} do { _name = _name select [0, count _name - 1] };
		if (_name == profileName) exitWith { _allowed = true };
	} forEach (_wlRaw splitString ",");
};
if (!_allowed) exitWith { systemChat localize "STR_Bro_SCam_n_denied" };

private _oldData = uiNamespace getVariable ["Bro_SCam_Data", createHashMap];
if (_oldData getOrDefault ["Active", false] && {isNull (_oldData getOrDefault ["Cam", objNull])}) then {
	uiNamespace setVariable ["Bro_SCam_Data", nil];
};

if ((uiNamespace getVariable ["Bro_SCam_Data", createHashMap]) getOrDefault ["Active", false]) exitWith {
	systemChat localize "STR_Bro_SCam_n_already";
};
if (!isNull findDisplay 312) exitWith { systemChat localize "STR_Bro_SCam_n_zeus" };

// --- STATE ---
private _d = createHashMap;
uiNamespace setVariable ["Bro_SCam_Data", _d];
private _tapActs = ["Exit", "HUD", "Vision", "Time_Inc", "Time_Dec", "Lock_Alt", "Look_At", "Lock_Ori", "Reset", "Follow", "List_Up", "List_Down", "Jump_Prev", "Jump_Next", "Select", "Names", "Reset_Full"];
private _binds = createHashMap;
{
	private _bind = [MOD_NAME, "Bro_SCam_" + _x] call CBA_fnc_getKeybind;
	_binds set [_x, if (isNil "_bind") then { [0, [false, false, false]] } else { _bind select 5 }];
} forEach (_tapActs + ["Move_Fwd", "Move_Back", "Move_Left", "Move_Right", "Move_Up", "Move_Down", "Roll_Left", "Roll_Right", "Roll_Reset", "Speed_Fast", "Speed_Slow"]);
private _initState = if (missionNamespace getVariable ["Bro_SCam_HUDDefault", true]) then { 0 } else { 2 };
{ _d set _x } forEach [
	["Active", true],
	["Binds", _binds],
	["TapActs", _tapActs],
	["PadMap", createHashMapFromArray [
		[DIK_XBOX_B, "Exit"], [DIK_XBOX_X, "HUD"], [DIK_XBOX_Y, "Vision"], [DIK_XBOX_L3, "Follow"], [DIK_XBOX_R3, "Look_At"],
		[DIK_XBOX_DPAD_UP, "List_Up"], [DIK_XBOX_DPAD_DOWN, "List_Down"], [DIK_XBOX_START, "Reset"], [DIK_XBOX_BACK, "Lock_Alt"]
	]],
	["Keys", []],
	["MouseD", [0, 0]],
	["Pos", [0, 0, 0]],
	["PosDes", [0, 0, 0]],
	["Ang", [0, 0]],
	["AngDes", [0, 0]],
	["OrientRef", objNull],
	["LastCam", [[0, 0, 0], [0, 1, 0], [0, 0, 1]]],
	["Roll", 0],
	["RollDes", 0],
	["Fov", 0.7],
	["FovDes", 0.7],
	["SpeedMult", 1],
	["SpeedMultDes", 1],
	["Target", player],
	["ListTarget", player],
	["HUD_State", _initState],
	["Follow", false],
	["VisionMode", 0],
	["AltLock", false],
	["OrientLock", false],
	["LookAtLock", false],
	["LastHUDUpdate", 0],
	["LastListUpdate", 0],
	["NotifyEnd", 0],
	["CachedList", []],
	["VehNames", createHashMap],
	["TopText", ""],
	["BotText", ""],
	["PadMode", -1],
	["EH_List", []],
	["EH_Names", -1],
	["NoTgt", localize "STR_Bro_SCam_h_notgt"],
	["TopTmpl", "<t valign='middle' size='1.1' shadow='2'><t align='left' font='RobotoCondensedBold' color='%1'> %2 <t color='" + C_DIM + "'>|</t> %3 <t color='" + C_DIM + "'>|</t> " + localize "STR_Bro_SCam_h_tscale" + ": <t color='%4'>%5x</t></t><t align='center' font='RobotoCondensedBold'>%6</t><t align='right' font='RobotoCondensedBold' color='%1'>" + localize "STR_Bro_SCam_h_grid" + ": %7 </t></t>"]
];

// --- FUNCTIONS (first param is always the data map) ---
_d set ["fnc_Msg", {
	params ["_d", "_text"];
	private _ctrl = _d get "Notify";
	_ctrl ctrlSetStructuredText parseText format ["<t align='center' size='1.1' font='RobotoCondensedBold' color='%2' shadow='2'>%1</t>", _text, C_ACCENT];
	_ctrl ctrlShow true;
	_d set ["NotifyEnd", diag_tickTime + NOTIFY_DURATION];
}];
// Sets the pose from a position and dir/up vectors in whatever space they were given
_d set ["fnc_SetPose", {
	params ["_d", "_pos", "_dir", "_up"];
	private _yaw = (_dir select 0) atan2 (_dir select 1);
	private _pit = asin (_dir select 2) max -89 min 89;
	private _rightH = [cos _yaw, -(sin _yaw), 0];
	private _roll = (_up vectorDotProduct _rightH) atan2 (_up vectorDotProduct (_rightH vectorCrossProduct _dir));
	_d set ["Pos", _pos];
	_d set ["PosDes", +_pos];
	_d set ["Ang", [_yaw, _pit]];
	_d set ["AngDes", [_yaw, _pit]];
	{ _d set [_x, _roll] } forEach ["Roll", "RollDes"];
}];
// Converts the last rendered world pose into a vehicle's model space
_d set ["fnc_Glue", {
	params ["_d", "_ref"];
	(_d get "LastCam") params ["_p", "_wDir", "_wUp"];
	[_d, _ref worldToModelVisual (ASLToAGL _p), _ref vectorWorldToModelVisual _wDir, _ref vectorWorldToModelVisual _wUp] call (_d get "fnc_SetPose");
	_d set ["OrientRef", _ref];
}];
// Switches Orientation Lock, converting the pose between world and vehicle space
_d set ["fnc_Orient", {
	params ["_d", "_on"];
	if (_on isEqualTo (_d get "OrientLock")) exitWith {};
	_d set ["OrientLock", _on];
	if (_on) exitWith { [_d, vehicle (_d get "Target")] call (_d get "fnc_Glue") };
	(_d get "LastCam") params ["_p", "_wDir", "_wUp"];
	private _t = _d get "Target";
	if ((_d get "Follow") && {!isNull _t && {alive _t}}) then { _p = _p vectorDiff (getPosASLVisual _t) };
	[_d, _p, _wDir, _wUp] call (_d get "fnc_SetPose");
}];
_d set ["fnc_SetAudioSpectator", {
	params ["_state"];
	if (_state && {!(missionNamespace getVariable ["Bro_SCam_AudioSpectator", true])}) exitWith {};
	if (!isNil "tfar_fnc_forceSpectator") then {
		[player, _state] call tfar_fnc_forceSpectator;
	} else {
		if (!isNil "tf_radio_fnc_forceSpectator") then { [player, _state] call tf_radio_fnc_forceSpectator };
	};
	if (!isNil "acre_api_fnc_setSpectator") then { [_state] call acre_api_fnc_setSpectator };
}];
_d set ["fnc_RefreshList", {
	params ["_d"];
	private _names = _d get "VehNames";
	private _prep = {
		params ["_u", "_isP"];
		private _label = name _u;
		private _veh = vehicle _u;
		if (_veh != _u) then {
			private _type = typeOf _veh;
			private _vName = _names getOrDefault [_type, ""];
			if (_vName == "") then {
				_vName = getText (configFile >> "CfgVehicles" >> _type >> "displayName");
				_names set [_type, _vName];
			};
			_label = format ["%1 (%2)", _vName, _label];
		};
		[_label, _u, _isP]
	};
	private _players = (allPlayers select { alive _x }) apply { [_x, true] call _prep };
	private _ai = [];
	if !(missionNamespace getVariable ["Bro_SCam_HideAI", false]) then {
		_ai = (allUnits select { alive _x && !isPlayer _x && side _x != sideLogic }) apply { [_x, false] call _prep };
	};
	_players sort true;
	_ai sort true;
	_d set ["CachedList", _players + _ai];
}];
_d set ["fnc_UpdateListUI", {
	params ["_d"];
	private _hudList = _d get "HUD_List";
	if ((_d get "HUD_State") != 0) exitWith { _hudList ctrlShow false };
	private _actual = _d get "Target";
	private _sel = _d get "ListTarget";
	if (isNull _sel || {!alive _sel}) then {
		_sel = _actual;
		_d set ["ListTarget", _sel];
	};
	private _list = _d get "CachedList";
	private _cur = (_list findIf { (_x select 1) == _sel }) max 0;
	private _text = "";
	for "_i" from ((_cur - 8) max 0) to ((_cur + 8) min (count _list - 1)) do {
		(_list select _i) params ["_label", "_u", "_isP"];
		private _color = if (_isP) then { "#cccccc" } else { C_DIM };
		if (_u == _actual) then { _color = C_ACCENT };
		if (_i == _cur) then {
			_label = format ["> %1 <", _label];
			_color = "#ffffff";
		} else {
			_label = format ["  %1", _label];
		};
		private _prefix = if (_isP) then { "<t size='0.7' color='#00aaff'>PL</t>" } else { "<t size='0.7' color='#aaaaaa'>AI</t>" };
		_text = _text + format ["<t color='%1' size='0.9' font='RobotoCondensedBold'>%2 %3</t><br/>", _color, _prefix, _label];
	};
	_hudList ctrlSetStructuredText parseText _text;
	_hudList ctrlShow true;
}];
// Moves the list highlight; wraps at both ends
_d set ["fnc_Nav", {
	params ["_d", "_playersOnly", "_step"];
	private _list = _d get "CachedList";
	if (_playersOnly) then { _list = _list select { _x select 2 } };
	if (_list isEqualTo []) exitWith {};
	private _cur = _d get "ListTarget";
	if (isNull _cur) then { _cur = _d get "Target" };
	private _i = ((_list findIf { (_x select 1) == _cur }) max 0) + _step + count _list;
	_d set ["ListTarget", (_list select (_i mod count _list)) select 1];
	[_d] call (_d get "fnc_UpdateListUI");
}];
// Puts the camera behind a unit; _full also resets speed, FOV and locks
_d set ["fnc_Focus", {
	params ["_d", "_t", "_full"];
	private _pos = [0, -2, 2];
	private _ang = [0, 0];
	if (!_full && {_d get "OrientLock"}) then {
		_d set ["OrientRef", vehicle _t];
	} else {
		private _dir = vectorDirVisual _t;
		_dir set [2, 0];
		_pos = ((vectorNormalized _dir) vectorMultiply -2) vectorAdd [0, 0, 2];
		if !(_d get "Follow") then { _pos = _pos vectorAdd (getPosASLVisual _t) };
		_ang = [getDir _t, 0];
	};
	_d set ["Pos", _pos];
	_d set ["PosDes", +_pos];
	_d set ["Ang", _ang];
	_d set ["AngDes", +_ang];
	_d set ["Roll", 0];
	_d set ["RollDes", 0];
	_d set ["ListTarget", _t];
	if (_full) then {
		{ _d set [_x, 1] } forEach ["SpeedMult", "SpeedMultDes"];
		{ _d set [_x, 0.7] } forEach ["Fov", "FovDes"];
		{ _d set [_x, false] } forEach ["AltLock", "OrientLock", "LookAtLock"];
	};
}];
_d set ["fnc_Exit", {
	disableSerialization;
	params ["_d"];
	[_d, false] call (_d get "fnc_Orient");
	_d set ["Active", false];
	private _tgt = _d get "Target";
	if (missionNamespace getVariable ["Bro_SCam_SavePos", true]) then {
		private _pos = _d get "Pos";
		if ((_d get "Follow") && {!isNull _tgt && {alive _tgt}}) then { _pos = (getPosASLVisual _tgt) vectorAdd _pos };
		uiNamespace setVariable ["Bro_SCam_LastState", [worldName, _pos, _d get "Ang", _d get "Roll", _d get "Fov", _tgt]];
	};
	private _display = findDisplay 46;
	private _eh = _d get "EH_List";
	if (count _eh > 0 && {!isNull _display}) then {
		_display displayRemoveEventHandler ["KeyDown", _eh select 0];
		_display displayRemoveEventHandler ["KeyUp", _eh select 1];
		_display displayRemoveEventHandler ["MouseMoving", _eh select 2];
		_display displayRemoveEventHandler ["MouseZChanged", _eh select 3];
	};
	if (count _eh > 0) then { removeMissionEventHandler ["EachFrame", _eh select 4] };
	if ((_d get "EH_Names") >= 0) then {
		removeMissionEventHandler ["Draw3D", _d get "EH_Names"];
		_d set ["EH_Names", -1];
		cameraEffectEnableHUD false;
	};
	private _cam = _d get "Cam";
	_cam cameraEffect ["Terminate", "Back"];
	camDestroy _cam;
	{ ctrlDelete (_d get _x) } forEach ["HUD_Top", "HUD_Bot", "HUD_List", "HUD_Keys", "Notify"];
	camUseNVG false;
	false setCamUseTi 0;
	[false] call (_d get "fnc_SetAudioSpectator");
	if (!isMultiplayer) then { setAccTime 1 };
	uiNamespace setVariable ["Bro_SCam_Data", nil];
}];
// Every camera action, whether triggered by keyboard or controller
_d set ["fnc_Act", {
	params ["_d", "_act"];
	private _tgt = _d get "Target";
	private _valid = !isNull _tgt && {alive _tgt};
	private _msgKey = "";
	private _args = [];
	switch (_act) do {
		case "Exit": { [_d] call (_d get "fnc_Exit") };
		case "HUD": {
			private _s = ((_d get "HUD_State") + 1) mod 3;
			_d set ["HUD_State", _s];
			(_d get "HUD_Top") ctrlShow (_s != 2);
			(_d get "HUD_Bot") ctrlShow (_s != 2);
			(_d get "HUD_List") ctrlShow (_s == 0);
			(_d get "HUD_Keys") ctrlShow (_s == 0);
			if (_s == 0) then {
				_d set ["ListTarget", _tgt];
				[_d] call (_d get "fnc_RefreshList");
				[_d] call (_d get "fnc_UpdateListUI");
			};
			_msgKey = ["n_hud_full", "n_hud_light", "n_hud_off"] select _s;
		};
		case "Vision": {
			private _mode = ((_d get "VisionMode") + 1) mod 4;
			_d set ["VisionMode", _mode];
			camUseNVG (_mode == 1);
			(_mode >= 2) setCamUseTi ((_mode - 2) max 0);
			_msgKey = ["n_vis_norm", "n_vis_nvg", "n_vis_whot", "n_vis_bhot"] select _mode;
		};
		case "Time_Inc";
		case "Time_Dec": {
			if (isMultiplayer) exitWith {};
			private _now = accTime;
			private _next = if (_act == "Time_Inc") then { _now + ([0.1, 0.05] select (_now < 1)) } else { _now - ([0.1, 0.05] select (_now <= 1)) };
			_next = ((round (_next * 100)) / 100) max 0 min 4;
			setAccTime _next;
			_msgKey = "n_ts_fmt";
			_args = [_next];
		};
		case "Lock_Alt": {
			private _on = !(_d get "AltLock");
			_d set ["AltLock", _on];
			_msgKey = ["n_alt_off", "n_alt_on"] select _on;
		};
		case "Look_At": {
			private _on = !(_d get "LookAtLock");
			if (_on) then { [_d, false] call (_d get "fnc_Orient") };
			_d set ["LookAtLock", _on];
			_msgKey = ["n_lat_off", "n_lat_on"] select _on;
		};
		case "Lock_Ori": {
			if (_d get "OrientLock") exitWith {
				[_d, false] call (_d get "fnc_Orient");
				_msgKey = "n_ori_off";
			};
			_d set ["LookAtLock", false];
			if (!_valid) exitWith { _msgKey = "n_ori_failt" };
			if (!alive (vehicle _tgt)) exitWith { _msgKey = "n_ori_failv" };
			[_d, true] call (_d get "fnc_Orient");
			_msgKey = "n_ori_on";
		};
		case "Reset": {
			if (!_valid) exitWith { _msgKey = "n_rst_fail" };
			[_d, _tgt, false] call (_d get "fnc_Focus");
			[_d] call (_d get "fnc_UpdateListUI");
			_msgKey = "n_cam_reset";
		};
		case "Reset_Full": {
			if (!alive player) exitWith { _msgKey = "n_rst_fail" };
			[_d, false] call (_d get "fnc_Orient");
			_d set ["Follow", false];
			_d set ["Target", player];
			[_d, player, true] call (_d get "fnc_Focus");
			_d set ["VisionMode", 0];
			camUseNVG false;
			false setCamUseTi 0;
			[_d] call (_d get "fnc_UpdateListUI");
			_msgKey = "n_cam_reset_full";
		};
		case "Follow": {
			if (!_valid) exitWith { _msgKey = "n_fol_fail" };
			private _on = !(_d get "Follow");
			private _tPos = getPosASLVisual _tgt;
			{
				private _p = _d get _x;
				_d set [_x, if (_on) then { _p vectorDiff _tPos } else { _p vectorAdd _tPos }];
			} forEach ["Pos", "PosDes"];
			_d set ["Follow", _on];
			_msgKey = ["n_fol_off", "n_fol_on"] select _on;
		};
		case "List_Up";
		case "List_Down": { [_d, false, [-1, 1] select (_act == "List_Down")] call (_d get "fnc_Nav") };
		case "Jump_Prev";
		case "Jump_Next": { [_d, true, [-1, 1] select (_act == "Jump_Next")] call (_d get "fnc_Nav") };
		case "Select": {
			private _new = _d get "ListTarget";
			if (isNull _new || {!alive _new}) exitWith {};
			_d set ["Target", _new];
			[_d, _new, false] call (_d get "fnc_Focus");
			[_d] call (_d get "fnc_UpdateListUI");
			_msgKey = "n_tgt_fmt";
			_args = [name _new];
		};
		case "Names": {
			private _on = (_d get "EH_Names") < 0;
			if (_on) then {
				_d set ["EH_Names", addMissionEventHandler ["Draw3D", {
					private _d = uiNamespace getVariable ["Bro_SCam_Data", createHashMap];
					if !(_d getOrDefault ["Active", false]) exitWith { removeMissionEventHandler ["Draw3D", _thisEventHandler] };
					private _vehNames = _d get "VehNames";
					{
						private _sideColor = [side _x] call BIS_fnc_sideColor;
						private _posArray = [ASLToAGL getPosASLVisual _x select 0, ASLToAGL getPosASLVisual _x select 1, (ASLToAGL getPosASLVisual _x select 2) + 2.3];
						private _tgtName = name _x;
						private _veh = vehicle _x;
						if (_veh != _x) then {
							private _type = typeOf _veh;
							private _vName = _vehNames getOrDefault [_type, ""];
							if (_vName == "") then {
								_vName = getText (configFile >> "CfgVehicles" >> _type >> "displayName");
								_vehNames set [_type, _vName];
							};
							_tgtName = format ["%1 (%2)", _tgtName, _vName];
							// Sit above the vehicle and stack crew labels so they don't overlap
							private _vPos = ASLToAGL getPosASLVisual _veh;
							_posArray = [_vPos select 0, _vPos select 1, (_vPos select 2) + (((boundingBoxReal _veh) select 1) select 2) + 0.5 + (0.4 * ((crew _veh) find _x))];
						};
						drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Targeting\Empty_ca.paa", _sideColor, _posArray, 0.1, 0.1, 0, _tgtName, 2, 0.035, "RobotoCondensedBold", "center"];
					} forEach (allPlayers select { alive _x && {side group _x != sideLogic} });
				}]];
				// drawIcon3D is only visible through a custom camera while its HUD is enabled
				cameraEffectEnableHUD true;
			} else {
				removeMissionEventHandler ["Draw3D", _d get "EH_Names"];
				_d set ["EH_Names", -1];
				cameraEffectEnableHUD false;
			};
			_msgKey = ["n_names_off", "n_names_on"] select _on;
		};
		case "FovOut": { _d set ["FovDes", ((_d get "FovDes") + 0.05) min 2] };
		case "FovIn": { _d set ["FovDes", ((_d get "FovDes") - 0.05) max 0.05] };
		case "RollL";
		case "RollR": {
			private _step = (missionNamespace getVariable ["Bro_SCam_RollSpeed", 10]) / 2;
			_d set ["RollDes", (_d get "RollDes") + ([-_step, _step] select (_act == "RollR"))];
		};
	};
	if (_msgKey != "") then { [_d, format ([localize ("STR_Bro_SCam_" + _msgKey)] + _args)] call (_d get "fnc_Msg") };
}];

// --- CAMERA ---
private _saved = uiNamespace getVariable ["Bro_SCam_LastState", []];
if ((missionNamespace getVariable ["Bro_SCam_SavePos", true]) && {count _saved > 0 && {(_saved select 0) == worldName}}) then {
	_saved params ["", "_pos", "_ang", "_roll", "_fov", "_tgt"];
	_d set ["Pos", _pos];
	_d set ["PosDes", +_pos];
	_d set ["Ang", _ang];
	_d set ["AngDes", +_ang];
	{ _d set [_x, _roll] } forEach ["Roll", "RollDes"];
	{ _d set [_x, _fov] } forEach ["Fov", "FovDes"];
	if (!isNull _tgt && {alive _tgt}) then {
		_d set ["Target", _tgt];
		_d set ["ListTarget", _tgt];
	};
} else {
	[_d, player, true] call (_d get "fnc_Focus");
};
private _cam = "camera" camCreate (ASLToAGL (_d get "Pos"));
_cam cameraEffect ["Internal", "Back"];
_cam camSetFov (_d get "Fov");
showCinemaBorder false;
_d set ["Cam", _cam];
[true] call (_d get "fnc_SetAudioSpectator");
if (!isMultiplayer && {missionNamespace getVariable ["Bro_SCam_StartPaused", false]}) then { setAccTime 0 };

// --- HUD ---
private _display = findDisplay 46;
private _showBars = _initState != 2;
private _showWidgets = _initState == 0;
private _mk = {
	params ["_pos", "_show", "_bg"];
	private _ctrl = _display ctrlCreate ["RscStructuredText", -1];
	_ctrl ctrlSetPosition _pos;
	_ctrl ctrlSetBackgroundColor [0, 0, 0, _bg];
	_ctrl ctrlShow _show;
	_ctrl ctrlCommit 0;
	_ctrl
};
_d set ["HUD_Top", [[safeZoneX, safeZoneY, safeZoneW, 0.045], _showBars, 0.25] call _mk];
_d set ["HUD_Bot", [[safeZoneX, safeZoneY + safeZoneH - 0.06, safeZoneW, 0.06], _showBars, 0.25] call _mk];
_d set ["HUD_List", [[safeZoneX + 0.01, safeZoneY + (safeZoneH * 0.3), 0.45, 0.4], _showWidgets, 0] call _mk];
_d set ["HUD_Keys", [[safeZoneX + safeZoneW - 0.32, safeZoneY + safeZoneH - 0.65, 0.32, 0.55], _showWidgets, 0] call _mk];
_d set ["Notify", [[safeZoneX, safeZoneY + safeZoneH - 0.12, safeZoneW, 0.05], false, 0] call _mk];

// Keyboard hint panel, with the player's current bindings
private _keyName = {
	params ["_ids", ["_sep", "/"]];
	(_ids apply { (_binds get _x) call CBA_fnc_localizeKey }) joinString _sep
};
private _single = { format ["[%1]", [[_this]] call _keyName] };
private _rows = [
	["p_move", [["Move_Fwd", "Move_Left", "Move_Back", "Move_Right"], ""] call _keyName],
	["p_elev", [["Move_Up", "Move_Down"]] call _keyName],
	["p_speed", [["Speed_Fast", "Speed_Slow"]] call _keyName],
	["p_zoom", localize "STR_Bro_SCam_p_zoom_val"],
	["p_scrollall", [["List_Up", "List_Down"]] call _keyName],
	["p_scrollpl", [["Jump_Prev", "Jump_Next"]] call _keyName],
	["p_select", "Select" call _single],
	["p_time", [["Time_Inc", "Time_Dec"]] call _keyName],
	["", ""],
	["p_follow", "Follow" call _single],
	["p_lookat", "Look_At" call _single],
	["p_lockori", "Lock_Ori" call _single],
	["p_lockalt", "Lock_Alt" call _single],
	["p_vision", "Vision" call _single],
	["p_names", "Names" call _single],
	["p_reset", "Reset" call _single],
	["p_resetfull", "Reset_Full" call _single],
	["p_togglehud", "HUD" call _single]
];
private _html = "<t align='right' size='0.8' font='RobotoCondensedBold' shadow='2'>";
{
	_x params ["_label", "_val"];
	_html = _html + (if (_label == "") then { "-----<br/>" } else { format ["%1 <t color='%2'>%3</t><br/>", localize ("STR_Bro_SCam_" + _label), C_ACCENT, _val] });
} forEach _rows;
_d set ["ControlsHTML", _html + format ["%1 <t color='%2'>%3</t></t>", localize "STR_Bro_SCam_p_exit", C_ERR, "Exit" call _single]];

// Controller hint panel; labels missing from the translation table (ROLL:) show as written
private _padRows = [
	["c_move", "L-STICK", C_ACCENT],
	["c_look", "R-STICK", C_ACCENT],
	["c_updn", "RT / LT", C_ACCENT],
	["c_speed", "RB / LB", C_ACCENT],
	["c_listud", "DPAD U/D", C_ACCENT],
	["c_playerpn", "DPAD L/R", C_ACCENT],
	["c_fn", "[A] HOLD", C_WARN],
	["c_fov", "[A] + LB / RB", C_WARN],
	["ROLL:", "[A] + DPAD L/R", C_WARN],
	["c_select", "[A] x2", C_ACCENT],
	["c_follow", "[L3]", C_ACCENT],
	["c_lookat", "[R3]", C_ACCENT],
	["c_vision", "[Y]", C_ACCENT],
	["c_hud", "[X]", C_ACCENT],
	["c_altlock", "[BACK]", C_ACCENT],
	["c_reset", "[START]", C_ACCENT]
];
_html = format ["<t align='right' size='0.8' font='RobotoCondensedBold' shadow='2'><t color='%1'>%2</t><br/>", C_ACCENT, localize "STR_Bro_SCam_c_title"];
{
	_x params ["_label", "_val", "_color"];
	_html = _html + format ["%1 <t color='%2'>%3</t><br/>", if (_label == "ROLL:") then { _label } else { localize ("STR_Bro_SCam_" + _label) }, _color, _val];
} forEach _padRows;
_d set ["PadHTML", _html + format ["%1 <t color='%2'>[B]</t></t>", localize "STR_Bro_SCam_c_exit", C_ERR]];

// --- EVENT HANDLERS ---
private _ehIds = [];
_ehIds pushBack (_display displayAddEventHandler ["KeyDown", {
	params ["", "_key", "_shift", "_ctrl", "_alt"];
	private _d = uiNamespace getVariable ["Bro_SCam_Data", createHashMap];
	if !(_d getOrDefault ["Active", false]) exitWith { false };
	private _keys = _d get "Keys";
	_keys pushBackUnique _key;
	private _binds = _d get "Binds";
	private _mods = [_shift, _ctrl, _alt];
	private _taps = _d get "TapActs";
	private _i = _taps findIf { private _b = _binds get _x; _key == (_b select 0) && {_mods isEqualTo (_b select 1)} };
	private _act = if (_i >= 0) then { _taps select _i } else { "" };
	if (_act == "" && {missionNamespace getVariable ["Bro_SCam_Controller", false]}) then {
		private _fn = DIK_XBOX_A in _keys;
		switch (_key) do {
			// A held = FN modifier; a second tap within 0.4s selects the highlighted target
			case DIK_XBOX_A: {
				if !(_d getOrDefault ["Pad_A_Down", false]) then {
					_d set ["Pad_A_Down", true];
					private _now = diag_tickTime;
					private _gap = _now - (_d getOrDefault ["Pad_A_LastPress", 0]);
					if (_gap > 0 && {_gap < 0.4}) then {
						_act = "Select";
						_d set ["Pad_A_LastPress", 0];
					} else {
						_d set ["Pad_A_LastPress", _now];
					};
				};
			};
			case DIK_XBOX_LB: { if (_fn) then { _act = "FovOut" } };
			case DIK_XBOX_RB: { if (_fn) then { _act = "FovIn" } };
			case DIK_XBOX_DPAD_LEFT: { _act = ["Jump_Prev", "RollL"] select _fn };
			case DIK_XBOX_DPAD_RIGHT: { _act = ["Jump_Next", "RollR"] select _fn };
			default { _act = (_d get "PadMap") getOrDefault [_key, ""] };
		};
	};
	if (_act != "") then { [_d, _act] call (_d get "fnc_Act") };
	_act == "Exit"
}]);
_ehIds pushBack (_display displayAddEventHandler ["KeyUp", {
	params ["", "_key"];
	private _d = uiNamespace getVariable ["Bro_SCam_Data", createHashMap];
	if !(_d getOrDefault ["Active", false]) exitWith { false };
	_d set ["Keys", (_d get "Keys") - [_key]];
	if (_key == DIK_XBOX_A) then { _d set ["Pad_A_Down", false] };
	false
}]);
_ehIds pushBack (_display displayAddEventHandler ["MouseMoving", {
	params ["", "_dx", "_dy"];
	private _d = uiNamespace getVariable ["Bro_SCam_Data", createHashMap];
	if !(_d getOrDefault ["Active", false]) exitWith { false };
	_d set ["MouseD", [_dx, _dy]];
	false
}]);
_ehIds pushBack (_display displayAddEventHandler ["MouseZChanged", {
	params ["", "_z"];
	private _d = uiNamespace getVariable ["Bro_SCam_Data", createHashMap];
	if !(_d getOrDefault ["Active", false]) exitWith { false };
	_d set ["FovDes", ((_d get "FovDes") - (_z * 0.05)) max 0.01 min 2];
	false
}]);
_ehIds pushBack (addMissionEventHandler ["EachFrame", {
	private _d = uiNamespace getVariable ["Bro_SCam_Data", createHashMap];
	if !(_d getOrDefault ["Active", false]) exitWith { removeMissionEventHandler ["EachFrame", _thisEventHandler] };
	// Failsafe: leave the camera when the player dies or the HUD display is gone
	if (!alive player || {isNull (_d get "HUD_Top")}) exitWith { [_d] call (_d get "fnc_Exit") };
	private _usePad = missionNamespace getVariable ["Bro_SCam_Controller", false];
	private _padDz = missionNamespace getVariable ["Bro_SCam_PadDeadzone", 0.15];
	private _cfgSens = (missionNamespace getVariable ["Bro_SCam_Sens", 15]) / 100;
	private _cfgRoll = (missionNamespace getVariable ["Bro_SCam_RollSpeed", 10]) / 100;
	private _cfgSmoothRot = (missionNamespace getVariable ["Bro_SCam_SmoothRot", 1]) / 100;
	private _cfgSmoothBrg = (missionNamespace getVariable ["Bro_SCam_SmoothBrg", 5]) / 100;
	private _cfgSmoothPos = (missionNamespace getVariable ["Bro_SCam_SmoothPos", 1]) / 100;
	private _cfgSmoothFOV = (missionNamespace getVariable ["Bro_SCam_SmoothFOV", 1]) / 100;
	private _cfgSmoothSpd = (missionNamespace getVariable ["Bro_SCam_SmoothSpd", 5]) / 100;
	private _speed = (missionNamespace getVariable ["Bro_SCam_Speed", 7]) / 100;
	private _keys = _d get "Keys";
	private _binds = _d get "Binds";
	private _held = { ((_binds get _this) select 0) in _keys };
	private _lerp = { params ["_a", "_b", "_t"]; _a + ((_b - _a) * _t) };
	private _lerpAngle = {
		params ["_cur", "_des", "_t"];
		private _diff = _des - _cur;
		_cur + ((_diff - (360 * floor ((_diff + 180) / 360))) * _t)
	};
	private _mouse = _d get "MouseD";
	_d set ["MouseD", [0, 0]];
	// MouseMoving deltas are inversely scaled by timescale; cancel it (floor keeps the paused case usable)
	private _tsComp = accTime max 0.1;
	_mouse = [(_mouse select 0) * _tsComp, (_mouse select 1) * _tsComp];
	private _fov = _d get "Fov";
	private _sens = _cfgSens * _fov;

	// Right stick feeds the mouse delta, but only on frames where the mouse is idle (inputAction includes mouse axes)
	if (_usePad && {abs (_mouse select 0) <= 0.001 && {abs (_mouse select 1) <= 0.001}}) then {
		private _axis = { if (abs _this <= _padDz) then { 0 } else { (_this - (_padDz * ([-1, 1] select (_this > 0)))) / (1 - _padDz) } };
		private _rsX = ((inputAction "AimRight") - (inputAction "AimLeft")) call _axis;
		private _rsY = ((inputAction "AimUp") - (inputAction "AimDown")) call _axis;
		_rsX = _rsX * abs _rsX * abs _rsX;
		_rsY = _rsY * (missionNamespace getVariable ["Bro_SCam_PadVertSens", 25]);
		if (missionNamespace getVariable ["Bro_SCam_PadInvertY", false]) then { _rsY = -_rsY };
		private _padScale = ((missionNamespace getVariable ["Bro_SCam_PadLookSens", 120]) / 100) * (diag_deltaTime max 0.001) * 0.6 / (_cfgSens max 0.01);
		_mouse = [(_mouse select 0) + (_rsX * _padScale), (_mouse select 1) - (_rsY * _padScale)];
	};

	private _target = _d get "Target";
	private _hasTarget = !isNull _target && {alive _target};
	private _ref = vehicle _target;
	private _follow = _d get "Follow";
	private _lookAt = _d get "LookAtLock";
	private _orient = _d get "OrientLock";
	private _lostKey = "";
	if ((_lookAt || _orient) && {!_hasTarget}) then {
		_lostKey = ["n_ori_dist", "n_lat_dis"] select _lookAt;
		_lookAt = false;
		_orient = false;
	};
	if (_orient && {!alive _ref}) then {
		_lostKey = "n_ori_disv";
		_orient = false;
	};
	if (_lostKey != "") then {
		_d set ["LookAtLock", _lookAt];
		[_d, _orient] call (_d get "fnc_Orient");
		[_d, localize ("STR_Bro_SCam_" + _lostKey)] call (_d get "fnc_Msg");
	};
	if (_orient && {_ref != (_d get "OrientRef")}) then { [_d, _ref] call (_d get "fnc_Glue") };
	// Follow needs a live target. Keep the camera at its world position and stop Follow.
	if (_follow && {!_hasTarget}) then {
		private _shift = ((_d get "LastCam") select 0) vectorDiff (_d get "Pos");
		{ _d set [_x, (_d get _x) vectorAdd _shift] } forEach ["Pos", "PosDes"];
		_d set ["Follow", false];
		_follow = false;
		[_d, localize "STR_Bro_SCam_n_fol_off"] call (_d get "fnc_Msg");
	};

	private _rollDelta = ([0, _cfgRoll] select ("Roll_Right" call _held)) - ([0, _cfgRoll] select ("Roll_Left" call _held));
	private _rollReset = "Roll_Reset" call _held;
	private _mx = (_mouse select 0) * _sens;
	private _my = (_mouse select 1) * _sens;
	private _angDes = _d get "AngDes";
	private _rollDes = _d get "RollDes";
	if (_lookAt) then {
		private _tPos = getPosASLVisual _target;
		private _camAbs = if (_follow) then { _tPos vectorAdd (_d get "Pos") } else { _d get "Pos" };
		if (_ref == _target) then { _tPos = _tPos vectorAdd [0, 0, 1] };
		private _look = _tPos vectorDiff _camAbs;
		private _dist = vectorMagnitude _look;
		_angDes = [(_look select 0) atan2 (_look select 1), if (_dist > 0) then { asin ((_look select 2) / _dist) } else { 0 }];
		_rollDes = if (_rollReset) then { 0 } else { _rollDes + _rollDelta };
	} else {
		_angDes = [(_angDes select 0) + _mx, ((_angDes select 1) - _my) max -89 min 89];
		_rollDes = if (_rollReset) then { 0 } else { _rollDes + _rollDelta };
	};
	_d set ["AngDes", _angDes];
	_d set ["RollDes", _rollDes];

	private _ang = _d get "Ang";
	private _rotSmooth = [_cfgSmoothRot, _cfgSmoothBrg] select _lookAt;
	private _yaw = [_ang select 0, _angDes select 0, _rotSmooth] call _lerpAngle;
	private _pit = [_ang select 1, _angDes select 1, _rotSmooth] call _lerp;
	private _rollNew = [_d get "Roll", _rollDes, _cfgSmoothRot] call _lerpAngle;
	_d set ["Ang", [_yaw, _pit]];
	_d set ["Roll", _rollNew];

	private _cosPit = cos _pit;
	private _vecDir = [sin _yaw * _cosPit, cos _yaw * _cosPit, sin _pit];
	private _vecRightH = [cos _yaw, -(sin _yaw), 0];
	private _vecUp = ((_vecRightH vectorCrossProduct _vecDir) vectorMultiply cos _rollNew) vectorAdd (_vecRightH vectorMultiply sin _rollNew);
	private _fwd = _vecDir;
	if (_d get "AltLock") then { _fwd = vectorNormalized [_vecDir select 0, _vecDir select 1, 0] };

	// Speed multiplier; with A held the bumpers do FOV instead
	private _padBumpers = _usePad && {!(DIK_XBOX_A in _keys)};
	private _spdDes = _d get "SpeedMultDes";
	if (("Speed_Fast" call _held) || {_padBumpers && {DIK_XBOX_RB in _keys}}) then { _spdDes = _spdDes * 1.02 };
	if (("Speed_Slow" call _held) || {_padBumpers && {DIK_XBOX_LB in _keys}}) then { _spdDes = _spdDes * 0.98 };
	_spdDes = _spdDes max 0.01 min 200;
	_d set ["SpeedMultDes", _spdDes];
	private _newSpd = [_d get "SpeedMult", _spdDes, _cfgSmoothSpd] call _lerp;
	_d set ["SpeedMult", _newSpd];

	private _move = [0, 0, 0];
	if ("Move_Fwd" call _held) then { _move = _move vectorAdd _fwd };
	if ("Move_Back" call _held) then { _move = _move vectorDiff _fwd };
	if ("Move_Right" call _held) then { _move = _move vectorAdd _vecRightH };
	if ("Move_Left" call _held) then { _move = _move vectorDiff _vecRightH };
	if ("Move_Up" call _held) then { _move = _move vectorAdd [0, 0, 1] };
	if ("Move_Down" call _held) then { _move = _move vectorAdd [0, 0, -1] };
	if (_usePad) then {
		// Stick forward may come through any of these actions depending on the user's preset
		private _lsX = ((inputAction "TurnRight") max (inputAction "MoveRight")) - ((inputAction "TurnLeft") max (inputAction "MoveLeft"));
		private _lsY = ((inputAction "MoveForward") max (inputAction "MoveFastForward") max (inputAction "MoveSlowForward")) - ((inputAction "MoveBack") max (inputAction "MoveFastBack") max (inputAction "MoveSlowBack"));
		private _lsMag = sqrt (_lsX * _lsX + _lsY * _lsY);
		if (_lsMag >= _padDz) then {
			private _adj = ((_lsMag - _padDz) / (1 - _padDz)) min 1;
			private _scale = (_adj * _adj) / _lsMag;
			_move = (_move vectorAdd (_vecRightH vectorMultiply (_lsX * _scale))) vectorAdd (_fwd vectorMultiply (_lsY * _scale));
		};
		if (DIK_XBOX_RT in _keys) then { _move = _move vectorAdd [0, 0, 1] };
		if (DIK_XBOX_LT in _keys) then { _move = _move vectorAdd [0, 0, -1] };
	};
	// Clamp to 1 so diagonals aren't faster, but keep analog magnitudes below 1
	if (vectorMagnitude _move > 1) then { _move = vectorNormalized _move };

	private _base = [0, 0, 0];
	if (!_orient && {_follow && {_hasTarget}}) then { _base = getPosASLVisual _target };
	private _abs = _base vectorAdd ((_d get "PosDes") vectorAdd (_move vectorMultiply (_speed * _newSpd)));
	// Ground clearance is skipped while glued so the rig stays rigid
	if (!_orient) then { _abs set [2, (_abs select 2) max ((getTerrainHeightASL _abs) + MIN_GROUND_CLEARANCE)] };
	private _posDes = _abs vectorDiff _base;
	_d set ["PosDes", _posDes];
	private _pos = _d get "Pos";
	_pos = _pos vectorAdd ((_posDes vectorDiff _pos) vectorMultiply _cfgSmoothPos);
	_d set ["Pos", _pos];
	private _camPos = _base vectorAdd _pos;
	// Glued: Pos, direction and up are in the vehicle's model space, so convert to world
	if (_orient) then {
		_camPos = _ref modelToWorldVisualWorld _camPos;
		_vecDir = _ref vectorModelToWorldVisual _vecDir;
		_vecUp = _ref vectorModelToWorldVisual _vecUp;
	};

	private _fovNew = [_fov, _d get "FovDes", _cfgSmoothFOV] call _lerp;
	_d set ["Fov", _fovNew];
	private _cam = _d get "Cam";
	_cam camSetFov _fovNew;

	if (diag_tickTime > (_d get "LastListUpdate") + LIST_UPDATE_INTERVAL) then {
		_d set ["LastListUpdate", diag_tickTime];
		[_d] call (_d get "fnc_RefreshList");
		[_d] call (_d get "fnc_UpdateListUI");
	};

	private _hudState = _d get "HUD_State";
	if (_hudState != 2 && {diag_tickTime > (_d get "LastHUDUpdate") + (1 / HUD_UPDATE_FPS)}) then {
		_d set ["LastHUDUpdate", diag_tickTime];
		if (_hudState == 0 && {!(_usePad isEqualTo (_d get "PadMode"))}) then {
			_d set ["PadMode", _usePad];
			(_d get "HUD_Keys") ctrlSetStructuredText parseText (_d get (if (_usePad) then { "PadHTML" } else { "ControlsHTML" }));
		};
		(date) params ["_year", "_month", "_day", "_hour", "_min"];
		private _top = format [
			_d get "TopTmpl",
			C_ACCENT,
			format ["%1-%2-%3", _year, _month, _day],
			format ["%1%2:%3%4", ["", "0"] select (_hour < 10), _hour, ["", "0"] select (_min < 10), _min],
			if (accTime != 1) then { C_WARN } else { C_DIM },
			accTime,
			toUpper (if (_hasTarget) then { name _target } else { _d get "NoTgt" }),
			mapGridPosition _camPos
		];
		if !(_top isEqualTo (_d get "TopText")) then {
			_d set ["TopText", _top];
			(_d get "HUD_Top") ctrlSetStructuredText parseText _top;
		};
		private _vis = _d get "VisionMode";
		private _padTag = "";
		if (_usePad) then {
			private _fn = DIK_XBOX_A in _keys;
			_padTag = format ["   <t color='%1'>PAD%2</t>", [C_ACCENT, C_WARN] select _fn, ["", "/FN"] select _fn];
		};
		private _bot = format [
			"<t valign='middle' size='1.1' shadow='2'><t align='left' font='RobotoCondensedBold'> SPD <t color='%1'>%2</t>  FOV <t color='%1'>%3</t>  ROLL <t color='%1'>%4</t></t><t align='center' font='RobotoCondensedBold'><t color='%5'>ALT</t>  <t color='%6'>ORI</t>  <t color='%7'>LAT</t>  <t color='%8'>FOL</t>   VIS:<t color='%9'>%10</t>%11</t></t>",
			C_ACCENT,
			_newSpd toFixed 2,
			_fovNew toFixed 2,
			_rollNew toFixed 1,
			[C_OFF, C_GOOD] select (_d get "AltLock"),
			[C_OFF, C_GOOD] select _orient,
			[C_OFF, C_GOOD] select _lookAt,
			[C_OFF, C_WARN] select _follow,
			[C_LABEL, C_ACCENT] select (_vis > 0),
			["NRM", "NVG", "WHOT", "BHOT"] select _vis,
			_padTag
		];
		if !(_bot isEqualTo (_d get "BotText")) then {
			_d set ["BotText", _bot];
			(_d get "HUD_Bot") ctrlSetStructuredText parseText _bot;
		};
	};
	private _notify = _d get "Notify";
	if (ctrlShown _notify && {diag_tickTime > (_d get "NotifyEnd")}) then { _notify ctrlShow false };

	_d set ["LastCam", [_camPos, _vecDir, _vecUp]];
	_cam setPosASL _camPos;
	_cam setVectorDirAndUp [_vecDir, _vecUp];
	_cam camCommit 0;
}]);
_d set ["EH_List", _ehIds];
[_d, localize "STR_Bro_SCam_n_cam_on"] call (_d get "fnc_Msg");
[_d] call (_d get "fnc_RefreshList");
[_d] call (_d get "fnc_UpdateListUI");
