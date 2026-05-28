/*
	Simple Cinematic Camera
	Usage: [] execVM "bro_simplecam\simplecam.sqf";
    
    Updated: 3-Stage HUD Toggle (Full -> Light -> Off)
*/
if (!hasInterface) exitWith {};
disableSerialization;
// --- CONSTANTS ---
#define NOTIFY_DURATION 0.3
#define LIST_UPDATE_INTERVAL 2.0
#define HUD_UPDATE_FPS 30
#define MIN_GROUND_CLEARANCE 0.25

// --- XBOX CONTROLLER DIK KEYCODES ---
// Arma 3 routes Xbox / XInput controller buttons through the standard
// KeyDown event with these extended DIK codes (above 256). Detected
// natively — no CBA rebind required when controller mode is enabled.
#define DIK_XBOX_A              327680
#define DIK_XBOX_B              327681
#define DIK_XBOX_X              327682
#define DIK_XBOX_Y              327683
#define DIK_XBOX_DPAD_UP        327684
#define DIK_XBOX_DPAD_DOWN      327685
#define DIK_XBOX_DPAD_LEFT      327686
#define DIK_XBOX_DPAD_RIGHT     327687
#define DIK_XBOX_START          327688
#define DIK_XBOX_BACK           327689
#define DIK_XBOX_LB             327690
#define DIK_XBOX_RB             327691
#define DIK_XBOX_LT             327692
#define DIK_XBOX_RT             327693
#define DIK_XBOX_L3             327694
#define DIK_XBOX_R3             327695

// --- COLORS ---
#define C_LABEL "#aaaaaa"
#define C_VAL "#ffffff"
#define C_ACCENT "#00dbff"
#define C_WARN "#ffaa00"
#define C_ERR "#ff3333"
#define C_GOOD "#33ff33"

// --- WHITELIST CHECK ---
private _wlRaw = missionNamespace getVariable ["Bro_SCam_Whitelist", ""];
if (_wlRaw != "") then {
	private _wlArray = (_wlRaw splitString ",") apply {
		private _trimmed = _x;
		while {_trimmed select [0, 1] == " "} do { _trimmed = _trimmed select [1] };
		while {_trimmed select [count _trimmed - 1, 1] == " "} do {
			_trimmed = _trimmed select [0, count _trimmed - 1]
		};
		_trimmed
	};
	if !(profileName in _wlArray) exitWith {
		systemChat (["n_denied"] call Bro_SCam_L);
		breakOut "main_scope";
	};
};
scopeName "main_scope";

// --- PREVENT MULTIPLE INSTANCES ---
if (!isNil "SCam_Data" && {SCam_Data get "Active"}) exitWith {
	systemChat (["n_already"] call Bro_SCam_L);
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
_d set ["K_L_At",  "Bro_SCam_Look_At" call (_d get "fnc_LoadBind")];
_d set ["K_Rst",   "Bro_SCam_Reset" call (_d get "fnc_LoadBind")];
_d set ["K_Fol",   "Bro_SCam_Follow" call (_d get "fnc_LoadBind")];
_d set ["K_J_Nxt", "Bro_SCam_Jump_Next" call (_d get "fnc_LoadBind")];
_d set ["K_J_Prv", "Bro_SCam_Jump_Prev" call (_d get "fnc_LoadBind")];
_d set ["K_L_Up",  "Bro_SCam_List_Up" call (_d get "fnc_LoadBind")];
_d set ["K_L_Dn",  "Bro_SCam_List_Down" call (_d get "fnc_LoadBind")];
_d set ["K_Sel",   "Bro_SCam_Select" call (_d get "fnc_LoadBind")]; 

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
	// Only update list if we are in FULL HUD mode (State 0)
	if ((_d get "HUD_State") != 0) exitWith { (_d get "HUD_List") ctrlShow false; };
	
	private _actualTarget = _d get "Target";
    private _listTarget = _d get "ListTarget";
    
    if (isNull _listTarget || {!alive _listTarget}) then {
        _listTarget = _actualTarget;
        _d set ["ListTarget", _actualTarget];
    };
    
	private _fullList = call (_d get "fnc_GetSortedUnits");
	_d set ["CachedList", _fullList];
	
	private _curIdx = _fullList findIf { (_x select 1) == _listTarget };
	if (_curIdx == -1) then { _curIdx = 0; };
	
    private _count = count _fullList;
	private _range = 8;
	private _start = (_curIdx - _range) max 0;
	private _end = (_curIdx + _range) min (_count - 1);
	private _text = "";
	for "_i" from _start to _end do {
		private _item = _fullList select _i;
		_item params ["_displayName", "_u", "_isP"];
		
        private _color = "#888888"; 
		if (_isP) then { _color = "#cccccc"; };
		
        if (_u == _actualTarget) then {
            _color = C_ACCENT; 
        };

		if (_i == _curIdx) then { 
             _displayName = format["> %1 <", _displayName];
             _color = "#ffffff";
        } else {
             _displayName = format["  %1", _displayName];
        };
        
		private _prefix = if (_isP) then { "<t size='0.7' color='#00aaff'>PL</t>" } else { "<t size='0.7' color='#aaaaaa'>AI</t>" };
		_text = _text + format ["<t color='%1' size='0.9' font='RobotoCondensedBold'>%2 %3</t><br/>", _color, _prefix, _displayName];
	};
	private _hudList = _d get "HUD_List";
	_hudList ctrlSetStructuredText parseText _text;
	_hudList ctrlShow true;
}];

// --- AUDIO INTEGRATION FUNCTION ---
SCam_Data set ["fnc_SetAudioSpectator", {
	params ["_state"];
	private _useSpectatorAudio = missionNamespace getVariable ["Bro_SCam_AudioSpectator", true];
	if (_state && !_useSpectatorAudio) exitWith {};

	if (isClass (configFile >> "CfgPatches" >> "task_force_radio") || isClass (configFile >> "CfgPatches" >> "TFAR_Core")) then {
		try {
			if (!isNil "tfar_fnc_forceSpectator") then {
				[player, _state] call tfar_fnc_forceSpectator;
			} else {
				if (!isNil "tf_radio_fnc_forceSpectator") then {
					[player, _state] call tf_radio_fnc_forceSpectator;
				};
			};
		} catch {};
	};
	if (isClass (configFile >> "CfgPatches" >> "acre_main")) then {
		try {
			if (!isNil "acre_api_fnc_setSpectator") then {
				[_state] call acre_api_fnc_setSpectator;
			};
		} catch {};
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
	if (count _lastState > 4) then {
		private _t = _lastState select 4;
		if (!isNull _t && {alive _t}) then {
			_startTarget = _t;
		};
	};
} else {
	private _vDir = vectorDirVisual player;
	_vDir set [2,0];
	if (vectorMagnitude _vDir > 0) then { _vDir = vectorNormalized _vDir; };
	_startPos = _startPos vectorAdd (_vDir vectorMultiply -2) vectorAdd [0,0,2];
};
private _cam = "camera" camCreate _startPos;
_cam cameraEffect ["Internal", "Back"];
_cam camSetFov _startFov;
showCinemaBorder false;
SCam_Data set ["Cam", _cam];
[true] call (SCam_Data get "fnc_SetAudioSpectator");

// --- START PAUSED (SP only) ---
if (!isMultiplayer && {missionNamespace getVariable ["Bro_SCam_StartPaused", false]}) then {
	setAccTime 0;
};

// --- MODERN UI SETUP ---
disableSerialization;
private _display = findDisplay 46;

// Determine Initial State
// 0 = FULL, 1 = LIGHT, 2 = OFF
private _initState = if (missionNamespace getVariable ["Bro_SCam_HUDDefault", true]) then { 0 } else { 2 };
private _showBars = (_initState != 2);
private _showWidgets = (_initState == 0);

// 1. TOP BAR
private _hudTop = _display ctrlCreate ["RscStructuredText", -1];
_hudTop ctrlSetPosition [safeZoneX, safeZoneY, safeZoneW, 0.045];
_hudTop ctrlSetBackgroundColor [0,0,0,0.25];
_hudTop ctrlShow _showBars;
_hudTop ctrlCommit 0;
SCam_Data set ["HUD_Top", _hudTop];

// 2. BOTTOM BAR
private _hudBot = _display ctrlCreate ["RscStructuredText", -1];
_hudBot ctrlSetPosition [safeZoneX, safeZoneY + safeZoneH - 0.06, safeZoneW, 0.06];
_hudBot ctrlSetBackgroundColor [0,0,0,0.25];
_hudBot ctrlShow _showBars;
_hudBot ctrlCommit 0;
SCam_Data set ["HUD_Bot", _hudBot];

// 3. UNIT LIST
private _hudList = _display ctrlCreate ["RscStructuredText", -1];
_hudList ctrlSetPosition [safeZoneX + 0.01, safeZoneY + (safeZoneH * 0.3), 0.45, 0.4];
_hudList ctrlSetBackgroundColor [0,0,0,0];
_hudList ctrlShow _showWidgets;
_hudList ctrlCommit 0;
SCam_Data set ["HUD_List", _hudList];
SCam_Data set ["LastListUpdate", 0];
SCam_Data set ["CachedList", []];

// 4. CONTROLS HINT
private _hudKeys = _display ctrlCreate ["RscStructuredText", -1];
_hudKeys ctrlSetPosition [safeZoneX + safeZoneW - 0.32, safeZoneY + safeZoneH - 0.65, 0.32, 0.55];
_hudKeys ctrlSetBackgroundColor [0,0,0,0]; 
_hudKeys ctrlShow _showWidgets;
_hudKeys ctrlCommit 0;
SCam_Data set ["HUD_Keys", _hudKeys];

// Pre-generate Key Strings
private _s_move = format["%1%2%3%4", "Bro_SCam_Move_Fwd" call (_d get "fnc_GetKeyName"), "Bro_SCam_Move_Left" call (_d get "fnc_GetKeyName"), "Bro_SCam_Move_Back" call (_d get "fnc_GetKeyName"), "Bro_SCam_Move_Right" call (_d get "fnc_GetKeyName")];
private _s_ud   = format["%1/%2", "Bro_SCam_Move_Up" call (_d get "fnc_GetKeyName"), "Bro_SCam_Move_Down" call (_d get "fnc_GetKeyName")];
private _s_spd  = format["%1/%2", "Bro_SCam_Speed_Fast" call (_d get "fnc_GetKeyName"), "Bro_SCam_Speed_Slow" call (_d get "fnc_GetKeyName")];
private _s_list = format["%1/%2", "Bro_SCam_List_Up" call (_d get "fnc_GetKeyName"), "Bro_SCam_List_Down" call (_d get "fnc_GetKeyName")];
private _s_sel  = "Bro_SCam_Select" call (_d get "fnc_GetKeyName");
private _s_plyr = format["%1/%2", "Bro_SCam_Jump_Prev" call (_d get "fnc_GetKeyName"), "Bro_SCam_Jump_Next" call (_d get "fnc_GetKeyName")];
private _s_time = format["%1/%2", "Bro_SCam_Time_Inc" call (_d get "fnc_GetKeyName"), "Bro_SCam_Time_Dec" call (_d get "fnc_GetKeyName")];
private _s_exit = "Bro_SCam_Exit" call (_d get "fnc_GetKeyName");
private _s_hud  = "Bro_SCam_HUD" call (_d get "fnc_GetKeyName");
private _s_fol  = "Bro_SCam_Follow" call (_d get "fnc_GetKeyName");
private _s_lat  = "Bro_SCam_Look_At" call (_d get "fnc_GetKeyName");
private _s_ori  = "Bro_SCam_Lock_Ori" call (_d get "fnc_GetKeyName");
private _s_alt  = "Bro_SCam_Lock_Alt" call (_d get "fnc_GetKeyName");
private _s_vis  = "Bro_SCam_Vision" call (_d get "fnc_GetKeyName");
private _s_rst  = "Bro_SCam_Reset" call (_d get "fnc_GetKeyName");

// Generate Controls HTML Once. Labels are concatenated from the localization
// table into the format template, then format substitutes the %N keybinds.
private _tmpl =
    "<t align='right' size='0.8' font='RobotoCondensedBold' shadow='2'>" +
    (["p_move"] call Bro_SCam_L)       + " <t color='%1'>%2</t><br/>" +
    (["p_elev"] call Bro_SCam_L)       + " <t color='%1'>%3</t><br/>" +
    (["p_speed"] call Bro_SCam_L)      + " <t color='%1'>%4</t><br/>" +
    (["p_zoom"] call Bro_SCam_L)       + " <t color='%1'>" + (["p_zoom_val"] call Bro_SCam_L) + "</t><br/>" +
    (["p_scrollall"] call Bro_SCam_L)  + " <t color='%1'>%5</t><br/>" +
    (["p_scrollpl"] call Bro_SCam_L)   + " <t color='%1'>%16</t><br/>" +
    (["p_select"] call Bro_SCam_L)     + " <t color='%1'>[%15]</t><br/>" +
    (["p_time"] call Bro_SCam_L)       + " <t color='%1'>%6</t><br/>" +
    "-----<br/>" +
    (["p_follow"] call Bro_SCam_L)     + " <t color='%1'>[%7]</t><br/>" +
    (["p_lookat"] call Bro_SCam_L)     + " <t color='%1'>[%8]</t><br/>" +
    (["p_lockori"] call Bro_SCam_L)    + " <t color='%1'>[%9]</t><br/>" +
    (["p_lockalt"] call Bro_SCam_L)    + " <t color='%1'>[%10]</t><br/>" +
    (["p_vision"] call Bro_SCam_L)     + " <t color='%1'>[%11]</t><br/>" +
    (["p_reset"] call Bro_SCam_L)      + " <t color='%1'>[%12]</t><br/>" +
    (["p_togglehud"] call Bro_SCam_L)  + " <t color='%1'>[%13]</t><br/>" +
    (["p_exit"] call Bro_SCam_L)       + " <t color='#ff3333'>[%14]</t>" +
    "</t>";
private _controlsHTML = format [
    _tmpl,
    C_ACCENT, _s_move, _s_ud, _s_spd, _s_list, _s_time, _s_fol, _s_lat, _s_ori, _s_alt, _s_vis, _s_rst, _s_hud, _s_exit, _s_sel, _s_plyr
];
SCam_Data set ["ControlsHTML", _controlsHTML];

// --- CONTROLLER HINT (single panel, native XInput bindings — no rebind needed) ---
private _padTmpl =
	"<t align='right' size='0.8' font='RobotoCondensedBold' shadow='2'>" +
	"<t color='%1'>" + (["c_title"] call Bro_SCam_L) + "</t><br/>" +
	(["c_move"] call Bro_SCam_L)     + " <t color='%1'>L-STICK</t><br/>" +
	(["c_look"] call Bro_SCam_L)     + " <t color='%1'>R-STICK</t><br/>" +
	(["c_updn"] call Bro_SCam_L)     + " <t color='%1'>RT / LT</t><br/>" +
	(["c_speed"] call Bro_SCam_L)    + " <t color='%1'>RB / LB</t><br/>" +
	(["c_listud"] call Bro_SCam_L)   + " <t color='%1'>DPAD U/D</t><br/>" +
	(["c_playerpn"] call Bro_SCam_L) + " <t color='%1'>DPAD L/R</t><br/>" +
	(["c_fn"] call Bro_SCam_L)       + " <t color='%2'>[A] HOLD</t><br/>" +
	(["c_fov"] call Bro_SCam_L)      + " <t color='%2'>[A] + LB / RB</t><br/>" +
	"ROLL: <t color='%2'>[A] + DPAD L/R</t><br/>" +
	(["c_select"] call Bro_SCam_L)   + " <t color='%1'>[A] x2</t><br/>" +
	(["c_follow"] call Bro_SCam_L)   + " <t color='%1'>[L3]</t><br/>" +
	(["c_lookat"] call Bro_SCam_L)   + " <t color='%1'>[R3]</t><br/>" +
	(["c_vision"] call Bro_SCam_L)   + " <t color='%1'>[Y]</t><br/>" +
	(["c_hud"] call Bro_SCam_L)      + " <t color='%1'>[X]</t><br/>" +
	(["c_altlock"] call Bro_SCam_L)  + " <t color='%1'>[BACK]</t><br/>" +
	(["c_reset"] call Bro_SCam_L)    + " <t color='%1'>[START]</t><br/>" +
	(["c_exit"] call Bro_SCam_L)     + " <t color='#ff3333'>[B]</t>" +
	"</t>";
private _padHTML = format [_padTmpl, C_ACCENT, C_WARN];
SCam_Data set ["PadHTML", _padHTML];
SCam_Data set ["LastPadHintMode", -1]; // forces a refresh on first frame

private _initPad = missionNamespace getVariable ["Bro_SCam_Controller", false];
_hudKeys ctrlSetStructuredText parseText (if (_initPad) then { _padHTML } else { _controlsHTML });

// 5. NOTIFICATION CENTER
private _notify = _display ctrlCreate ["RscStructuredText", -1];
_notify ctrlSetPosition [safeZoneX, safeZoneY + safeZoneH - 0.12, safeZoneW, 0.05];
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
SCam_Data set ["ListTarget", _startTarget];
SCam_Data set ["HUD_State", _initState]; // Used to be HUD_Vis, now Integer 0,1,2
SCam_Data set ["EH_List", []];
SCam_Data set ["Follow", false];
SCam_Data set ["VisionMode", 0];
SCam_Data set ["AltLock", false];
SCam_Data set ["OrientLock", false];
SCam_Data set ["LookAtLock", false];
SCam_Data set ["LastHUDUpdate", 0];

// --- HELPER FUNCTIONS ---
SCam_Data set ["fnc_Msg", {
	params ["_text"];
	private _d = SCam_Data;
	private _ctrl = _d get "Notify";
	_ctrl ctrlSetStructuredText parseText format ["<t align='center' size='1.1' font='RobotoCondensedBold' color='%2' shadow='2'>%1</t>", _text, C_ACCENT];
	_ctrl ctrlShow true;
	_d set ["NotifyEnd", diag_tickTime + NOTIFY_DURATION];
}];
SCam_Data set ["fnc_Exit", {
	disableSerialization;
	private _data = SCam_Data;
	_data set ["Active", false];
	private _display = findDisplay 46;
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
	private _ehList = _data get "EH_List";
	if (count _ehList > 0) then {
		_display displayRemoveEventHandler ["KeyDown", _ehList select 0];
		_display displayRemoveEventHandler ["KeyUp", _ehList select 1];
		_display displayRemoveEventHandler ["MouseMoving", _ehList select 2];
		_display displayRemoveEventHandler ["MouseZChanged", _ehList select 3];
		removeMissionEventHandler ["EachFrame", _ehList select 4];
	};
	private _cam = _data get "Cam";
	if (!isNil "_cam" && {!isNull _cam}) then {
		_cam cameraEffect ["Terminate", "Back"];
		camDestroy _cam;
	};
	ctrlDelete (_data get "HUD_Top");
	ctrlDelete (_data get "HUD_Bot");
	ctrlDelete (_data get "HUD_List");
	ctrlDelete (_data get "HUD_Keys");
	ctrlDelete (_data get "Notify");
	camUseNVG false;
	false setCamUseTi 0;
	[false] call (_data get "fnc_SetAudioSpectator");
	SCam_Data = nil;
}];

// --- EVENT HANDLERS ---
private _ehIds = [];
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
	if ("K_Exit" call _fnc_Trigger) exitWith { [] call (_d get "fnc_Exit"); true };
	
    // UPDATED HUD TOGGLE: Full (0) -> Light (1) -> Off (2)
    if ("K_HUD" call _fnc_Trigger) then {
		private _s = _d get "HUD_State";
        _s = _s + 1;
        if (_s > 2) then { _s = 0; };
        _d set ["HUD_State", _s];
        
        // Visibility Logic
        private _showBars = (_s != 2); // Show on Full(0) and Light(1)
        private _showWidgets = (_s == 0); // Show only on Full(0)
        
        // Apply
		(_d get "HUD_Top") ctrlShow _showBars;
		(_d get "HUD_Bot") ctrlShow _showBars;
		(_d get "HUD_List") ctrlShow _showWidgets;
		(_d get "HUD_Keys") ctrlShow _showWidgets;
        
        // If we switched to Full, sync the list target to verify visuals
        if (_showWidgets) then {
            _d set ["ListTarget", _d get "Target"];
            [] call (_d get "fnc_UpdateListUI");
        };
        
        // Optional Feedback
        private _msg = switch (_s) do { case 0: {["n_hud_full"] call Bro_SCam_L}; case 1: {["n_hud_light"] call Bro_SCam_L}; case 2: {["n_hud_off"] call Bro_SCam_L}; };
        [_msg] call (_d get "fnc_Msg");
	};
    
	if ("K_Vis" call _fnc_Trigger) then {
		private _mode = _d get "VisionMode";
		_mode = _mode + 1;
		if (_mode > 3) then { _mode = 0; };
		_d set ["VisionMode", _mode];
		private _msg = switch (_mode) do {
			case 0: { camUseNVG false; false setCamUseTi 0; ["n_vis_norm"] call Bro_SCam_L; };
			case 1: { camUseNVG true; false setCamUseTi 0; ["n_vis_nvg"] call Bro_SCam_L; };
			case 2: { camUseNVG false; true setCamUseTi 0; ["n_vis_whot"] call Bro_SCam_L; };
			case 3: { camUseNVG false; true setCamUseTi 1; ["n_vis_bhot"] call Bro_SCam_L; };
		};
		[_msg] call (_d get "fnc_Msg");
	};
	if (!isMultiplayer) then {
		if ("K_T_Inc" call _fnc_Trigger) then {
			private _now = accTime;
			private _next = _now + 0.1;
			if (_now < 1.0) then { _next = _now + 0.05; };
			_next = (round (_next * 100)) / 100;
			if (_next > 4.0) then { _next = 4.0; };
			setAccTime _next;
			[format [["n_ts_fmt"] call Bro_SCam_L, _next]] call (_d get "fnc_Msg");
		};
		if ("K_T_Dec" call _fnc_Trigger) then {
			private _now = accTime;
			private _next = _now - 0.1;
			if (_now <= 1.0) then { _next = _now - 0.05; };
			_next = (round (_next * 100)) / 100;
			if (_next < 0) then { _next = 0; };
			setAccTime _next;
			[format [["n_ts_fmt"] call Bro_SCam_L, _next]] call (_d get "fnc_Msg");
		};
	};
	if ("K_L_Alt" call _fnc_Trigger) then {
		private _l = !(_d get "AltLock");
		_d set ["AltLock", _l];
		[if (_l) then {["n_alt_on"] call Bro_SCam_L} else {["n_alt_off"] call Bro_SCam_L}] call (_d get "fnc_Msg");
	};
	if ("K_L_At" call _fnc_Trigger) then {
		private _l = !(_d get "LookAtLock");
		_d set ["LookAtLock", _l];
		if (_l) then { _d set ["OrientLock", false]; };
		[if (_l) then {["n_lat_on"] call Bro_SCam_L} else {["n_lat_off"] call Bro_SCam_L}] call (_d get "fnc_Msg");
	};
	if ("K_L_Ori" call _fnc_Trigger) then {
		private _b = !(_d get "OrientLock");
		_d set ["OrientLock", _b];
		if (_b) then {
			_d set ["LookAtLock", false];
			private _currAng = _d get "AngDes";
			private _currRoll = _d get "RollDes";
			private _target = _d get "Target";
			if (isNull _target || {!alive _target}) exitWith {
				_d set ["OrientLock", false];
				[["n_ori_failt"] call Bro_SCam_L] call (_d get "fnc_Msg");
			};
			private _refObj = vehicle _target;
			if (isNull _refObj || {!alive _refObj}) exitWith {
				_d set ["OrientLock", false];
				[["n_ori_failv"] call Bro_SCam_L] call (_d get "fnc_Msg");
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
			[["n_ori_on"] call Bro_SCam_L] call (_d get "fnc_Msg");
		} else {
			[["n_ori_off"] call Bro_SCam_L] call (_d get "fnc_Msg");
		};
	};
	if ("K_Rst" call _fnc_Trigger) then {
		private _target = _d get "Target";
		if (isNull _target || {!alive _target}) exitWith {
			[["n_rst_fail"] call Bro_SCam_L] call (_d get "fnc_Msg");
		};
		private _pPos = getPosASLVisual _target;
		private _vDir = vectorDirVisual _target;
		_vDir set [2, 0];
		if (vectorMagnitude _vDir > 0) then { _vDir = vectorNormalized _vDir; };
		private _offset = (_vDir vectorMultiply -2) vectorAdd [0,0,2];
		
		if (_d get "Follow") then {
			_d set ["Pos", _offset];
			_d set ["PosDes", _offset];
		} else {
			_d set ["Pos", _pPos vectorAdd _offset];
			_d set ["PosDes", _pPos vectorAdd _offset];
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
		_d set ["LookAtLock", false];
        _d set ["ListTarget", _target];
		[["n_cam_reset"] call Bro_SCam_L] call (_d get "fnc_Msg");
		[] call (_d get "fnc_UpdateListUI");
	};
	if ("K_Fol" call _fnc_Trigger) then {
		private _isFollowing = _d get "Follow";
		private _target = _d get "Target";
		if (isNull _target || {!alive _target}) exitWith {
			[["n_fol_fail"] call Bro_SCam_L] call (_d get "fnc_Msg");
		};
		private _currPos = _d get "Pos";
		private _currPosDes = _d get "PosDes";
		private _tPos = getPosASLVisual _target;
		if (_isFollowing) then {
			_d set ["Pos", _tPos vectorAdd _currPos];
			_d set ["PosDes", _tPos vectorAdd _currPosDes];
			[["n_fol_off"] call Bro_SCam_L] call (_d get "fnc_Msg");
		} else {
			_d set ["Pos", _currPos vectorDiff _tPos];
			_d set ["PosDes", _currPosDes vectorDiff _tPos];
			[["n_fol_on"] call Bro_SCam_L] call (_d get "fnc_Msg");
		};
		_d set ["Follow", !_isFollowing];
	};
    // UPDATED: Standard List Scroll (All units)
	if (("K_L_Up" call _fnc_Trigger) || ("K_L_Dn" call _fnc_Trigger)) then {
		private _fullList = call (_d get "fnc_GetSortedUnits");
		if (count _fullList > 0) then {
			private _curr = _d get "ListTarget";
            if (isNull _curr) then { _curr = _d get "Target"; };
			private _idx = _fullList findIf { (_x select 1) == _curr };
			if (_idx == -1) then { _idx = 0; };
			if ("K_L_Dn" call _fnc_Trigger) then { _idx = _idx + 1; } else { _idx = _idx - 1; };
			if (_idx >= count _fullList) then { _idx = 0; };
			if (_idx < 0) then { _idx = (count _fullList) - 1; };
            private _newHighlight = (_fullList select _idx) select 1;
			_d set ["ListTarget", _newHighlight];
			[] call (_d get "fnc_UpdateListUI");
		};
	};
    // UPDATED: Player-Only Scroll (Left/Right) - Moves Highlight Only
    if (("K_J_Prv" call _fnc_Trigger) || ("K_J_Nxt" call _fnc_Trigger)) then {
		private _fullList = _d get "CachedList"; 
        if (isNil "_fullList" || {count _fullList == 0}) then { _fullList = call (_d get "fnc_GetSortedUnits"); };
        
        private _playerList = _fullList select { _x select 2 }; // select isP is true
        
        if (count _playerList > 0) then {
            private _curr = _d get "ListTarget";
            if (isNull _curr) then { _curr = _d get "Target"; };
            
            private _idx = _playerList findIf { (_x select 1) == _curr };
            if (_idx == -1) then { _idx = 0; };
            
            if ("K_J_Nxt" call _fnc_Trigger) then { _idx = _idx + 1; } else { _idx = _idx - 1; };
            
            if (_idx >= count _playerList) then { _idx = 0; };
            if (_idx < 0) then { _idx = (count _playerList) - 1; };
            
            private _newHighlight = (_playerList select _idx) select 1;
            _d set ["ListTarget", _newHighlight];
            [] call (_d get "fnc_UpdateListUI");
        };
    };
    
    // NEW: Selection / Confirmation Key
    if ("K_Sel" call _fnc_Trigger) then {
        private _newTarget = _d get "ListTarget";
        if (!isNull _newTarget && {alive _newTarget}) then {
            _d set ["Target", _newTarget];
			private _newTPos = getPosASLVisual _newTarget;
			private _vDir = vectorDirVisual _newTarget;
			_vDir set [2, 0];
			if (vectorMagnitude _vDir > 0) then { _vDir = vectorNormalized _vDir; };
			private _offset = (_vDir vectorMultiply -2) vectorAdd [0,0,2];

			if (_d get "Follow") then {
				_d set ["Pos", _offset];
				_d set ["PosDes", _offset];
			} else {
				_d set ["Pos", _newTPos vectorAdd _offset];
				_d set ["PosDes", _newTPos vectorAdd _offset];
			};
			_d set ["AngDes", [getDir _newTarget, 0]];
			_d set ["Ang", [getDir _newTarget, 0]];
			_d set ["RollDes", 0];
			_d set ["Roll", 0];
			[format [["n_tgt_fmt"] call Bro_SCam_L, name _newTarget]] call (_d get "fnc_Msg");
			[] call (_d get "fnc_UpdateListUI");
        };
    };

    // --- NATIVE XBOX CONTROLLER DISPATCHER (tap-style actions) ---
    // Xbox buttons arrive through the standard KeyDown event with extended DIK codes.
    // Tap actions are dispatched here; held actions (LT/RT vertical, LB/RB speed) are
    // read from the Keys array in the EachFrame loop.
    if (missionNamespace getVariable ["Bro_SCam_Controller", false]) then {
        private _fnc_msg = _d get "fnc_Msg";
        switch (_key) do {
            // A — FN modifier (hold) / double-tap = Select highlighted target.
            // Hold A alone = enters FN mode (Pad_A_Down flag + FN tag on HUD).
            // Hold A + LB/RB = FOV adjust (handled in the LB/RB cases below).
            // Tap A twice within 0.4s = fire Select (the original A action).
            case DIK_XBOX_A: {
                // Only act on the initial press; ignore autorepeat while held.
                if !(_d getOrDefault ["Pad_A_Down", false]) then {
                    _d set ["Pad_A_Down", true];
                    private _now = diag_tickTime;
                    private _last = _d getOrDefault ["Pad_A_LastPress", 0];
                    if ((_now - _last) > 0 && {(_now - _last) < 0.4}) then {
                        // Double-tap → original Select Target action
                        private _newTarget = _d get "ListTarget";
                        if (!isNull _newTarget && {alive _newTarget}) then {
                            _d set ["Target", _newTarget];
                            private _newTPos = getPosASLVisual _newTarget;
                            private _vDir = vectorDirVisual _newTarget;
                            _vDir set [2, 0];
                            if (vectorMagnitude _vDir > 0) then { _vDir = vectorNormalized _vDir; };
                            private _offset = (_vDir vectorMultiply -2) vectorAdd [0,0,2];
                            if (_d get "Follow") then {
                                _d set ["Pos", _offset]; _d set ["PosDes", _offset];
                            } else {
                                _d set ["Pos", _newTPos vectorAdd _offset]; _d set ["PosDes", _newTPos vectorAdd _offset];
                            };
                            _d set ["AngDes", [getDir _newTarget, 0]]; _d set ["Ang", [getDir _newTarget, 0]];
                            _d set ["RollDes", 0]; _d set ["Roll", 0];
                            [format [["n_tgt_fmt"] call Bro_SCam_L, name _newTarget]] call _fnc_msg;
                            [] call (_d get "fnc_UpdateListUI");
                        };
                        _d set ["Pad_A_LastPress", 0]; // reset to avoid chain triggers
                    } else {
                        _d set ["Pad_A_LastPress", _now];
                    };
                };
            };
            // LB — A+LB = FOV out (bare LB held = speed slow, handled in EachFrame)
            case DIK_XBOX_LB: {
                if (DIK_XBOX_A in _keys) then {
                    private _curr = _d get "FovDes";
                    _d set ["FovDes", (_curr + 0.05) min 2.0];
                };
            };
            // RB — A+RB = FOV in (bare RB held = speed fast, handled in EachFrame)
            case DIK_XBOX_RB: {
                if (DIK_XBOX_A in _keys) then {
                    private _curr = _d get "FovDes";
                    _d set ["FovDes", (_curr - 0.05) max 0.05];
                };
            };
            // B — Exit camera
            case DIK_XBOX_B: { [] call (_d get "fnc_Exit"); };
            // X — Cycle HUD
            case DIK_XBOX_X: {
                private _s = ((_d get "HUD_State") + 1) mod 3;
                _d set ["HUD_State", _s];
                private _showBars = (_s != 2);
                private _showWidgets = (_s == 0);
                (_d get "HUD_Top") ctrlShow _showBars;
                (_d get "HUD_Bot") ctrlShow _showBars;
                (_d get "HUD_List") ctrlShow _showWidgets;
                (_d get "HUD_Keys") ctrlShow _showWidgets;
                if (_showWidgets) then {
                    _d set ["ListTarget", _d get "Target"];
                    [] call (_d get "fnc_UpdateListUI");
                };
                [switch (_s) do { case 0: {["n_hud_full"] call Bro_SCam_L}; case 1: {["n_hud_light"] call Bro_SCam_L}; case 2: {["n_hud_off"] call Bro_SCam_L}; }] call _fnc_msg;
            };
            // Y — Cycle vision
            case DIK_XBOX_Y: {
                private _mode = ((_d get "VisionMode") + 1) mod 4;
                _d set ["VisionMode", _mode];
                [switch (_mode) do {
                    case 0: { camUseNVG false; false setCamUseTi 0; ["n_vis_norm"] call Bro_SCam_L; };
                    case 1: { camUseNVG true;  false setCamUseTi 0; ["n_vis_nvg"] call Bro_SCam_L; };
                    case 2: { camUseNVG false; true  setCamUseTi 0; ["n_vis_whot"] call Bro_SCam_L; };
                    case 3: { camUseNVG false; true  setCamUseTi 1; ["n_vis_bhot"] call Bro_SCam_L; };
                }] call _fnc_msg;
            };
            // L3 — Follow toggle
            case DIK_XBOX_L3: {
                private _isFol = _d get "Follow";
                private _t = _d get "Target";
                if (isNull _t || {!alive _t}) exitWith { [["n_fol_fail"] call Bro_SCam_L] call _fnc_msg; };
                private _currPos = _d get "Pos";
                private _currPosDes = _d get "PosDes";
                private _tPos = getPosASLVisual _t;
                if (_isFol) then {
                    _d set ["Pos", _tPos vectorAdd _currPos];
                    _d set ["PosDes", _tPos vectorAdd _currPosDes];
                    [["n_fol_off"] call Bro_SCam_L] call _fnc_msg;
                } else {
                    _d set ["Pos", _currPos vectorDiff _tPos];
                    _d set ["PosDes", _currPosDes vectorDiff _tPos];
                    [["n_fol_on"] call Bro_SCam_L] call _fnc_msg;
                };
                _d set ["Follow", !_isFol];
            };
            // R3 — Look At toggle
            case DIK_XBOX_R3: {
                private _l = !(_d get "LookAtLock");
                _d set ["LookAtLock", _l];
                if (_l) then { _d set ["OrientLock", false]; };
                [if (_l) then {["n_lat_on"] call Bro_SCam_L} else {["n_lat_off"] call Bro_SCam_L}] call _fnc_msg;
            };
            // D-pad UP / DOWN — list nav
            case DIK_XBOX_DPAD_UP;
            case DIK_XBOX_DPAD_DOWN: {
                private _fullList = call (_d get "fnc_GetSortedUnits");
                if (count _fullList > 0) then {
                    private _curr = _d get "ListTarget";
                    if (isNull _curr) then { _curr = _d get "Target"; };
                    private _idx = _fullList findIf { (_x select 1) == _curr };
                    if (_idx == -1) then { _idx = 0; };
                    _idx = if (_key == DIK_XBOX_DPAD_DOWN) then { _idx + 1 } else { _idx - 1 };
                    if (_idx >= count _fullList) then { _idx = 0; };
                    if (_idx < 0) then { _idx = (count _fullList) - 1; };
                    _d set ["ListTarget", (_fullList select _idx) select 1];
                    [] call (_d get "fnc_UpdateListUI");
                };
            };
            // D-pad LEFT / RIGHT — prev/next player (or roll step if A held = FN mode)
            case DIK_XBOX_DPAD_LEFT;
            case DIK_XBOX_DPAD_RIGHT: {
                if (DIK_XBOX_A in _keys) then {
                    // A + D-pad L/R = roll step (~5° per tap, scaled by RollSpeed setting)
                    private _rs = (missionNamespace getVariable ["Bro_SCam_RollSpeed", 10]) / 100;
                    private _step = (_rs * 50) * (if (_key == DIK_XBOX_DPAD_RIGHT) then { 1 } else { -1 });
                    _d set ["RollDes", (_d get "RollDes") + _step];
                } else {
                    private _fullList = _d get "CachedList";
                    if (isNil "_fullList" || {count _fullList == 0}) then { _fullList = call (_d get "fnc_GetSortedUnits"); };
                    private _playerList = _fullList select { _x select 2 };
                    if (count _playerList > 0) then {
                        private _curr = _d get "ListTarget";
                        if (isNull _curr) then { _curr = _d get "Target"; };
                        private _idx = _playerList findIf { (_x select 1) == _curr };
                        if (_idx == -1) then { _idx = 0; };
                        _idx = if (_key == DIK_XBOX_DPAD_RIGHT) then { _idx + 1 } else { _idx - 1 };
                        if (_idx >= count _playerList) then { _idx = 0; };
                        if (_idx < 0) then { _idx = (count _playerList) - 1; };
                        _d set ["ListTarget", (_playerList select _idx) select 1];
                        [] call (_d get "fnc_UpdateListUI");
                    };
                };
            };
            // Start — Reset to current target
            case DIK_XBOX_START: {
                private _t = _d get "Target";
                if (isNull _t || {!alive _t}) exitWith { [["n_rst_fail"] call Bro_SCam_L] call _fnc_msg; };
                private _pPos = getPosASLVisual _t;
                private _vDir = vectorDirVisual _t;
                _vDir set [2, 0];
                if (vectorMagnitude _vDir > 0) then { _vDir = vectorNormalized _vDir; };
                private _offset = (_vDir vectorMultiply -2) vectorAdd [0,0,2];
                if (_d get "Follow") then {
                    _d set ["Pos", _offset]; _d set ["PosDes", _offset];
                } else {
                    _d set ["Pos", _pPos vectorAdd _offset]; _d set ["PosDes", _pPos vectorAdd _offset];
                };
                _d set ["AngDes", [getDir _t, 0]]; _d set ["Ang", [getDir _t, 0]];
                _d set ["RollDes", 0]; _d set ["Roll", 0];
                _d set ["SpeedMultDes", 1.0]; _d set ["SpeedMult", 1.0];
                _d set ["FovDes", 0.7]; _d set ["Fov", 0.7];
                (_d get "Cam") camSetFov 0.7;
                _d set ["AltLock", false]; _d set ["OrientLock", false]; _d set ["LookAtLock", false];
                _d set ["ListTarget", _t];
                [["n_cam_reset"] call Bro_SCam_L] call _fnc_msg;
                [] call (_d get "fnc_UpdateListUI");
            };
            // Back / View — Toggle Altitude Lock
            case DIK_XBOX_BACK: {
                private _l = !(_d get "AltLock");
                _d set ["AltLock", _l];
                [if (_l) then {["n_alt_on"] call Bro_SCam_L} else {["n_alt_off"] call Bro_SCam_L}] call _fnc_msg;
            };
        };
    };
	false
}]);
_ehIds pushBack (_display displayAddEventHandler ["KeyUp", {
	params ["_disp", "_key", "_shift", "_ctrl", "_alt"];
	private _d = SCam_Data;
	if (isNil "_d" || {!(_d get "Active")}) exitWith { true };
	_d set ["KeyMods", [_shift, _ctrl, _alt]];
	_d set ["Keys", (_d get "Keys") - [_key]];
	// Track Xbox A release for double-tap detection (see KeyDown case DIK_XBOX_A)
	if (_key == DIK_XBOX_A) then { _d set ["Pad_A_Down", false]; };
	false
}]);
_ehIds pushBack (_display displayAddEventHandler ["MouseMoving", {
	params ["_disp", "_x", "_y"];
	if (isNil "SCam_Data" || {!(SCam_Data get "Active")}) exitWith { true };
	SCam_Data set ["MouseD", [_x, _y]];
	false
}]);
_ehIds pushBack (_display displayAddEventHandler ["MouseZChanged", {
	params ["_disp", "_z"];
	private _d = SCam_Data;
	if (isNil "_d" || {!(_d get "Active")}) exitWith { true };
	private _des = _d get "FovDes";
	private _change = _z * 0.05;
	_d set ["FovDes", (_des - _change) max 0.01 min 2.0];
	false
}]);

_ehIds pushBack (addMissionEventHandler ["EachFrame", {
	if (isNil "SCam_Data" || {!(SCam_Data get "Active")}) exitWith {
		removeMissionEventHandler ["EachFrame", _thisEventHandler];
	};
	private _d = SCam_Data;
	// Cache config values
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
	private _checkKey = _d get "fnc_CheckKey";

	// --- CONTROLLER POLLING (RIGHT STICK -> piped through _mouse delta) ---
	// Arma's "AimUp/Down/Left/Right" actions include BOTH the right stick AND the
	// mouse axes — so polling them while the mouse is moving would double-count
	// the mouse delta (cam goes too fast, mouse-edge clamping triggers).
	// Workaround: only poll the stick when the mouse delta is zero this frame.
	// When the user releases the mouse, the stick takes over seamlessly.
	private _usePad = missionNamespace getVariable ["Bro_SCam_Controller", false];
	private _mouseActive = ((abs (_mouse select 0)) > 0.001) || {(abs (_mouse select 1)) > 0.001};
	if (_usePad && !_mouseActive) then {
		private _padDz = missionNamespace getVariable ["Bro_SCam_PadDeadzone", 0.15];
		private _padLookSens = (missionNamespace getVariable ["Bro_SCam_PadLookSens", 120]) / 100;
		private _padInvY = missionNamespace getVariable ["Bro_SCam_PadInvertY", false];

		// Right stick (look) — additive to mouse delta.
		// X: cubic curve for fine yaw aim near center.
		// Y: linear, with a dedicated multiplier slider so the user can compensate
		// for Arma's built-in vertical aim dampening on controllers without
		// affecting yaw responsiveness.
		private _padVertSens = missionNamespace getVariable ["Bro_SCam_PadVertSens", 25.0];
		private _rsX = (inputAction "AimRight") - (inputAction "AimLeft");
		private _rsY = (inputAction "AimUp")    - (inputAction "AimDown");
		if (abs _rsX < _padDz) then { _rsX = 0 } else { _rsX = (_rsX - (_padDz * (_rsX/abs _rsX))) / (1 - _padDz); };
		if (abs _rsY < _padDz) then { _rsY = 0 } else { _rsY = (_rsY - (_padDz * (_rsY/abs _rsY))) / (1 - _padDz); };
		_rsX = (_rsX * abs _rsX) * (abs _rsX);  // cubic response on yaw
		_rsY = _rsY * _padVertSens;             // linear pitch with user-tunable multiplier
		if (_padInvY) then { _rsY = -_rsY; };

		// Treat stick as equivalent mouse delta per frame. Scale to mouse-style units
		// so existing _sens (= cfgSens * fov) gives a sane feel; tune via PadLookSens.
		private _dt = diag_deltaTime max 0.001;
		private _padScale = _padLookSens * _dt * 0.6 / (_cfgSens max 0.01);
		_mouse = [(_mouse select 0) + (_rsX * _padScale), (_mouse select 1) - (_rsY * _padScale)];
	};


	if (_d get "LookAtLock") then {
		private _target = _d get "Target";
		if (isNull _target || {!alive _target}) then {
			_d set ["LookAtLock", false];
			[["n_lat_dis"] call Bro_SCam_L] call (_d get "fnc_Msg");
		} else {
			private _tPosReal = getPosASLVisual _target;
			private _camPosAbs = if (_d get "Follow") then { _tPosReal vectorAdd (_d get "Pos") } else { _d get "Pos" };
			if (vehicle _target == _target) then {
				_tPosReal = _tPosReal vectorAdd [0, 0, 1];
			};
			private _lookVec = _tPosReal vectorDiff _camPosAbs;
			private _yawTgt = (_lookVec select 0) atan2 (_lookVec select 1);
			private _dist = vectorMagnitude _lookVec;
			private _pitTgt = if (_dist > 0) then { asin ((_lookVec select 2) / _dist) } else { 0 };
			_d set ["AngDes", [_yawTgt, _pitTgt]];
			if (["K_R_L", false] call _checkKey) then { _rollDes = _rollDes - _cfgRollSpeed; };
			if (["K_R_R", false] call _checkKey) then { _rollDes = _rollDes + _cfgRollSpeed; };
			if (["K_R_Rst", false] call _checkKey) then { _rollDes = 0; };
			_d set ["RollDes", _rollDes];
		};
	} else {
		if (_d get "OrientLock") then {
			private _target = _d get "Target";
			if (isNull _target || {!alive _target}) then {
				_d set ["OrientLock", false];
				[["n_ori_dist"] call Bro_SCam_L] call (_d get "fnc_Msg");
			} else {
				private _rotOffset = _d get "RotOffset";
				_rotOffset set [0, (_rotOffset select 0) + ((_mouse select 0) * _sens)];
				_rotOffset set [1, ((_rotOffset select 1) - ((_mouse select 1) * _sens)) max -89 min 89];
				if (["K_R_L", false] call _checkKey) then { _rotOffset set [2, (_rotOffset select 2) - _cfgRollSpeed]; };
				if (["K_R_R", false] call _checkKey) then { _rotOffset set [2, (_rotOffset select 2) + _cfgRollSpeed]; };
				if (["K_R_Rst", false] call _checkKey) then { _rotOffset set [2, 0]; };
				_d set ["RotOffset", _rotOffset];
				private _refObj = vehicle _target;
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
					[["n_ori_disv"] call Bro_SCam_L] call (_d get "fnc_Msg");
				};
			};
		} else {
			private _yawDes = (_angDes select 0) + ((_mouse select 0) * _sens);
			private _pitDes = ((_angDes select 1) - ((_mouse select 1) * _sens)) max -89 min 89;
			_d set ["AngDes", [_yawDes, _pitDes]];
			if (["K_R_L", false] call _checkKey) then { _rollDes = _rollDes - _cfgRollSpeed; };
			if (["K_R_R", false] call _checkKey) then { _rollDes = _rollDes + _cfgRollSpeed; };
			if (["K_R_Rst", false] call _checkKey) then { _rollDes = 0; };
			_d set ["RollDes", _rollDes];
		};
	};
	
	private _ang = _d get "Ang";
	private _roll = _d get "Roll";
	private _lerp = { params ["_a", "_b", "_t"]; _a + ((_b - _a) * _t) };
	private _lerpAngle = {
		params ["_cur", "_des", "_t"];
		private _diff = _des - _cur;
		_diff = _diff - (360 * floor((_diff + 180) / 360));
		_cur + (_diff * _t)
	};
	private _rotSmooth = if (_d get "OrientLock" || _d get "LookAtLock") then { _cfgSmoothBrg } else { _cfgSmoothRot };
	private _yawNew = [_ang select 0, (_d get "AngDes") select 0, _rotSmooth] call _lerpAngle;
	private _pitNew = [_ang select 1, (_d get "AngDes") select 1, _rotSmooth] call _lerp;
	private _rollSmooth = if (_d get "OrientLock") then { _rotSmooth } else { _cfgSmoothRot };
	private _rollNew = [_roll, _rollDes, _rollSmooth] call _lerpAngle;
	_d set ["Ang", [_yawNew, _pitNew]];
	_d set ["Roll", _rollNew];

	private _vx = sin(_yawNew) * cos(_pitNew);
	private _vy = cos(_yawNew) * cos(_pitNew);
	private _vz = sin(_pitNew);
	private _vecDir = [_vx, _vy, _vz];
	private _vecRightH = [cos(_yawNew), -sin(_yawNew), 0];
	private _vecUpBase = _vecRightH vectorCrossProduct _vecDir;
	private _vecUp = (_vecUpBase vectorMultiply cos(_rollNew)) vectorAdd (_vecRightH vectorMultiply sin(_rollNew));
	private _vecFwdFlat = [_vx, _vy, 0];
	if (vectorMagnitude _vecFwdFlat > 0) then { _vecFwdFlat = vectorNormalized _vecFwdFlat; };

	private _spdDes = _d get "SpeedMultDes";
	if (["K_S_Fst", false] call _checkKey) then { _spdDes = _spdDes * 1.02; };
	if (["K_S_Slw", false] call _checkKey) then { _spdDes = _spdDes * 0.98; };
	if (_usePad) then {
		private _keysHeldS = _d get "Keys";
		// Suppress LB/RB speed when A is held (FN mode) so A+LB/RB does FOV only
		if !(DIK_XBOX_A in _keysHeldS) then {
			if (DIK_XBOX_RB in _keysHeldS) then { _spdDes = _spdDes * 1.02; };
			if (DIK_XBOX_LB in _keysHeldS) then { _spdDes = _spdDes * 0.98; };
		};
	};
	_spdDes = _spdDes max 0.01 min 200;
	_d set ["SpeedMultDes", _spdDes];
	private _currSpd = _d get "SpeedMult";
	private _newSpd = [_currSpd, _spdDes, _cfgSmoothSpd] call _lerp;
	_d set ["SpeedMult", _newSpd];
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

	// --- CONTROLLER: Left stick translation + LB/RB vertical/zoom ---
	// inputAction returns the MAX of all sources for that action (W key + stick = max 1),
	// so keyboard + stick can over-contribute to _moveVec. The magnitude clamp below
	// (clamps when > 1) absorbs the overlap without dragging the direction back to zero,
	// which avoids breaking users who have rebinded movement keys away from WASD.
	if (_usePad) then {
		private _padDz = missionNamespace getVariable ["Bro_SCam_PadDeadzone", 0.15];
		// Arma's default Xbox preset wires LS forward through MoveFastForward/MoveSlowForward
		// (not MoveForward, which is W-key only). Poll all candidates with max so the stick
		// fires whichever variant the user's preset uses.
		private _fwdIn = (inputAction "MoveForward") max (inputAction "MoveFastForward") max (inputAction "MoveSlowForward");
		private _bckIn = (inputAction "MoveBack")    max (inputAction "MoveFastBack")    max (inputAction "MoveSlowBack");
		private _rgtIn = (inputAction "TurnRight")   max (inputAction "MoveRight");
		private _lftIn = (inputAction "TurnLeft")    max (inputAction "MoveLeft");
		private _lsX = _rgtIn - _lftIn;
		private _lsY = _fwdIn - _bckIn;
		// Radial deadzone + quadratic response for smoother slow-pushes near center
		private _mag2 = sqrt (_lsX*_lsX + _lsY*_lsY);
		if (_mag2 < _padDz) then {
			_lsX = 0; _lsY = 0;
		} else {
			private _adj = ((_mag2 - _padDz) / (1 - _padDz)) min 1;
			private _scaled = (_adj * _adj) / _mag2; // quadratic
			_lsX = _lsX * _scaled;
			_lsY = _lsY * _scaled;
		};
		if (_lsX != 0) then { _moveVec = _moveVec vectorAdd (_vecRightH vectorMultiply _lsX); };
		if (_lsY != 0) then { _moveVec = _moveVec vectorAdd (_fwdRef    vectorMultiply _lsY); };

		// Triggers (LT down / RT up) — detected via Keys array using extended Xbox DIK codes.
		// LT/RT fire as digital KeyDown events when pulled past Arma's threshold.
		private _keysHeld = _d get "Keys";
		if (DIK_XBOX_RT in _keysHeld) then { _moveVec = _moveVec vectorAdd [0,0, 1]; };
		if (DIK_XBOX_LT in _keysHeld) then { _moveVec = _moveVec vectorAdd [0,0,-1]; };
	};

	// Clamp magnitude to 1 (so diagonal isn't faster) but PRESERVE analog magnitudes < 1
	private _moveMag = vectorMagnitude _moveVec;
	if (_moveMag > 0) then {
		if (_moveMag > 1) then { _moveVec = vectorNormalized _moveVec; };
		_moveVec = _moveVec vectorMultiply _finalSpeed;
	};
	private _posDes = (_d get "PosDes") vectorAdd _moveVec;

	private _target = _d get "Target";
	private _targetBase = if (_d get "Follow" && {!isNull _target && {alive _target}}) then {
		getPosASLVisual _target
	} else {
		[0,0,0]
	};
	private _absPosDes = _targetBase vectorAdd _posDes;
	private _terrZ = getTerrainHeightASL _absPosDes;
	private _minZ = _terrZ + MIN_GROUND_CLEARANCE;
	if ((_absPosDes select 2) < _minZ) then { _absPosDes set [2, _minZ]; };
	if (_d get "Follow") then { _posDes = _absPosDes vectorDiff _targetBase; } else { _posDes = _absPosDes; };
	_d set ["PosDes", _posDes];
	private _pos = (_d get "Pos");
	_pos = _pos vectorAdd ((_posDes vectorDiff _pos) vectorMultiply _cfgSmoothPos);
	_d set ["Pos", _pos];
	
	private _finalCamPos = [0,0,0];
	if (_d get "Follow" && {!isNull _target && {alive _target}}) then {
		private _tPos = getPosASLVisual _target;
		_finalCamPos = _tPos vectorAdd _pos;
	} else {
		_finalCamPos = _pos;
	};

	private _fovDes = _d get "FovDes";
	private _fovNew = [_fov, _fovDes, _cfgSmoothFOV] call _lerp;
	_d set ["Fov", _fovNew];
	(_d get "Cam") camSetFov _fovNew;

	if (diag_tickTime > (_d get "LastListUpdate") + LIST_UPDATE_INTERVAL) then {
		_d set ["LastListUpdate", diag_tickTime];
		if ((_d get "HUD_State") == 0) then { [] call (_d get "fnc_UpdateListUI"); };
	};
    
	if ((_d get "HUD_State") != 2 && {diag_tickTime > (_d get "LastHUDUpdate") + (1 / HUD_UPDATE_FPS)}) then {
		_d set ["LastHUDUpdate", diag_tickTime];

        // Refresh the controls hint panel when controller mode / secondary state changes
        if ((_d get "HUD_State") == 0) then {
            // _hintMode: -1 = keyboard, 1 = pad
            private _hintMode = if (_usePad) then { 1 } else { -1 };
            if (_hintMode != (_d get "LastPadHintMode")) then {
                _d set ["LastPadHintMode", _hintMode];
                private _html = if (_usePad) then { _d get "PadHTML" } else { _d get "ControlsHTML" };
                (_d get "HUD_Keys") ctrlSetStructuredText parseText _html;
            };
        };

        private _tgtName = ["h_notgt"] call Bro_SCam_L;
		if (!isNull _target && {alive _target}) then { _tgtName = name _target; };

        private _cAlt = if (_d get "AltLock") then { C_GOOD } else { "#444444" };
        private _cOri = if (_d get "OrientLock") then { C_GOOD } else { "#444444" };
        private _cLat = if (_d get "LookAtLock") then { C_GOOD } else { "#444444" };
        private _cFol = if (_d get "Follow") then { C_WARN } else { "#444444" };

        private _visMode = _d get "VisionMode";
        private _vText = ["NRM", "NVG", "WHOT", "BHOT"] select _visMode;
        private _cVis = if (_visMode > 0) then { C_ACCENT } else { C_LABEL };

        private _date = date;
        private _dateStr = format["%1-%2-%3", _date select 0, _date select 1, _date select 2];
        private _timeStr = [daytime, "HH:MM"] call BIS_fnc_timeToString;
        
		(_d get "HUD_Top") ctrlSetStructuredText parseText format [
            "<t valign='middle' size='1.1' shadow='2'>" +
            "<t align='left' font='RobotoCondensedBold' color='%1'> %2 <t color='#888888'>|</t> %3 <t color='#888888'>|</t> %8: <t color='%6'>%7x</t></t>" +
            "<t align='center' font='RobotoCondensedBold'>%4</t>" +
            "<t align='right' font='RobotoCondensedBold' color='%1'>%9: %5 </t>" +
            "</t>",
            C_ACCENT, // 1
            _dateStr, // 2
            _timeStr, // 3
            toUpper(_tgtName), // 4
            mapGridPosition _finalCamPos, // 5
            if (accTime != 1) then { C_WARN } else { "#888888" }, // 6
            accTime, // 7
            ["h_tscale"] call Bro_SCam_L, // 8
            ["h_grid"] call Bro_SCam_L // 9
        ];
        
        private _padTag = "";
        if (_usePad) then {
            private _isFn = DIK_XBOX_A in (_d get "Keys");
            _padTag = if (_isFn) then {
                format ["   <t color='%1'>PAD/FN</t>", C_WARN]
            } else {
                format ["   <t color='%1'>PAD</t>", C_ACCENT]
            };
        };

        (_d get "HUD_Bot") ctrlSetStructuredText parseText format [
             "<t valign='middle' size='1.1' shadow='2'>" +
             "<t align='left' font='RobotoCondensedBold'> SPD <t color='%1'>%2</t>  FOV <t color='%1'>%3</t>  ROLL <t color='%1'>%4</t></t>" +
             "<t align='center' font='RobotoCondensedBold'>" +
             "<t color='%5'>ALT</t>  " +
             "<t color='%6'>ORI</t>  " +
             "<t color='%7'>LAT</t>  " +
             "<t color='%8'>FOL</t>   " +
             "VIS:<t color='%9'>%10</t>%11" +
             "</t>" +
             "</t>",
             C_ACCENT, // 1
             (round(_newSpd * 100) / 100) toFixed 2, // 2
             (round(_fovNew * 100) / 100) toFixed 2, // 3
             (round(_rollNew * 10) / 10) toFixed 1, // 4
             _cAlt, _cOri, _cLat, _cFol, _cVis, _vText, _padTag
        ];
	};
    
	if (diag_tickTime > (_d get "NotifyEnd")) then {
		(_d get "Notify") ctrlShow false;
	};

	private _cam = _d get "Cam";
	if (!isNil "_cam" && {!isNull _cam}) then {
		_cam setPosASL _finalCamPos;
		_cam setVectorDirAndUp [_vecDir, _vecUp];
		_cam camCommit 0;
	};
}]);
SCam_Data set ["EH_List", _ehIds];

[["n_cam_on"] call Bro_SCam_L] call (SCam_Data get "fnc_Msg");
[] call (SCam_Data get "fnc_UpdateListUI");
