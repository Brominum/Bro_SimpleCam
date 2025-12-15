/* 
    Simple Cinematic Camera (Final + No Momentum Exit)
    Usage: [] execVM "bro_simplecam\simplecam.sqf";
    
    Controls:
    WASD         - Move Horizontal
    Q / Z        - Move Up / Down
    E / R        - Roll Left / Right
    T            - Reset Roll to Horizon
    G            - Reset to Player
    F            - Toggle Follow Mode (Locks to target movement)
    N            - Cycle Vision (Normal / NVG / White Hot / Black Hot)
    Scroll       - Zoom In / Out (FOV)
    Hold Shift   - Increase Speed
    Hold Ctrl    - Decrease Speed
    L            - Toggle Info HUD
    Arrows L/R   - Jump to Players
    Space        - Exit
*/

if (!hasInterface) exitWith {};
disableSerialization; 

// --- WHITELIST CHECK ---
private _wlRaw = missionNamespace getVariable ["Bro_SCam_Whitelist", ""];

if (_wlRaw != "") then {
    private _wlArray = _wlRaw splitString ",";
    _wlArray = _wlArray apply { 
        private _arr = toArray _x;
        while {count _arr > 0 && {_arr select 0 == 32}} do { _arr deleteAt 0; };
        while {count _arr > 0 && {_arr select (count _arr - 1) == 32}} do { _arr deleteAt (count _arr - 1); };
        toString _arr
    };
    
    if !(profileName in _wlArray) exitWith {
        systemChat "ACCESS DENIED: You are not on the Cinematic Camera whitelist.";
        breakOut "main_scope"; 
    };
};

scopeName "main_scope";

// --- CONFIGURATION ---
// Note: Actual values are pulled from CBA Settings in the loop
#define CAM_SPEED_BASE 0.07    
#define CAM_SMOOTH_POS 0.01
#define CAM_SMOOTH_ROT 0.01
#define CAM_SMOOTH_FOV 0.01
#define MOUSE_SENS_BASE 0.15
#define ROLL_SPEED 0.1

// --- INITIALIZATION ---
if (!isNil "SCam_Data") exitWith { systemChat "Camera already active."; };

SCam_Data = createHashMap;
SCam_Data set ["Active", true];

// --- CAMERA SETUP ---
private _startPos = getPosASLVisual player;
_startPos set [2, (_startPos select 2) + 2]; 

private _cam = "camera" camCreate _startPos;
_cam cameraEffect ["Internal", "Back"];
_cam camSetFov 0.7;
showCinemaBorder false;

SCam_Data set ["Cam", _cam];

// --- UI SETUP ---
private _display = findDisplay 46;

// 1. Main Info HUD
private _hud = _display ctrlCreate ["RscStructuredText", -1];
_hud ctrlSetPosition [safeZoneX + safeZoneW - 0.45, safeZoneY + safeZoneH - 0.55, 0.45, 0.55]; 
_hud ctrlSetBackgroundColor [0,0,0,0.5]; 
_hud ctrlShow true; 
_hud ctrlCommit 0;

SCam_Data set ["HUD", _hud];

// 2. Notification Box
private _notify = _display ctrlCreate ["RscStructuredText", -1];
_notify ctrlSetPosition [safeZoneX + (safeZoneW * 0.3), safeZoneY + safeZoneH - 0.15, safeZoneW * 0.4, 0.06];
_notify ctrlSetBackgroundColor [0,0,0,0]; 
_notify ctrlShow false; 
_notify ctrlCommit 0;

SCam_Data set ["Notify", _notify];
SCam_Data set ["NotifyEnd", 0];

// --- POPULATE STATE ---
SCam_Data set ["Keys", []];
SCam_Data set ["MouseD", [0,0]];

SCam_Data set ["Pos", _startPos];
SCam_Data set ["PosDes", _startPos];

SCam_Data set ["Ang", [getDir player, 0]];
SCam_Data set ["AngDes", [getDir player, 0]];
SCam_Data set ["Roll", 0];
SCam_Data set ["RollDes", 0];
SCam_Data set ["Fov", 0.7];
SCam_Data set ["FovDes", 0.7];
SCam_Data set ["SpeedMult", 1.0];
SCam_Data set ["Target", player];
SCam_Data set ["HUD_Vis", true]; 
SCam_Data set ["EH_List", []]; 
SCam_Data set ["Follow", false];
SCam_Data set ["VisionMode", 0]; 

// --- HELPER FUNCTIONS ---

SCam_Data set ["fnc_Msg", {
    params ["_text"];
    private _d = SCam_Data;
    private _ctrl = _d get "Notify";
    _ctrl ctrlSetStructuredText parseText format ["<t align='center' size='0.8' font='RobotoCondensedLight'>%1</t>", _text];
    _ctrl ctrlShow true;
    _d set ["NotifyEnd", diag_tickTime + 1.0]; 
}];

SCam_Data set ["fnc_Exit", {
    disableSerialization;
    private _data = SCam_Data;
    private _display = findDisplay 46;
    
    private _ehList = _data get "EH_List";
    _display displayRemoveEventHandler ["KeyDown", _ehList select 0];
    _display displayRemoveEventHandler ["KeyUp", _ehList select 1];
    _display displayRemoveEventHandler ["MouseMoving", _ehList select 2];
    _display displayRemoveEventHandler ["MouseZChanged", _ehList select 3];
    removeMissionEventHandler ["EachFrame", _ehList select 4];
    
    private _cam = _data get "Cam";
    _cam cameraEffect ["Terminate", "Back"];
    camDestroy _cam;
    
    ctrlDelete (_data get "HUD");
    ctrlDelete (_data get "Notify");
    
    camUseNVG false; 
    false setCamUseTi 0;

    SCam_Data = nil;
}];

// --- EVENT HANDLERS ---
private _ehIds = [];

// 1. KeyDown
_ehIds pushBack (_display displayAddEventHandler ["KeyDown", {
    params ["_disp", "_key"];
    private _d = SCam_Data;
    
    if (_key == 57) exitWith { [] call (_d get "fnc_Exit"); true };
    
    // Toggle HUD (L)
    if (_key == 38) then {
        private _v = !(_d get "HUD_Vis");
        _d set ["HUD_Vis", _v];
        (_d get "HUD") ctrlShow _v;
    };

    // Vision Mode (N)
    if (_key == 49) then {
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
    
    // G (Full Reset)
    if (_key == 34) then {
        _d set ["Target", player];
        
        private _pPos = getPosASLVisual player;
        private _resetPos = _pPos vectorAdd [0,0,2];
        
        if (_d get "Follow") then {
            _d set ["Pos", [0,0,2]];
            _d set ["PosDes", [0,0,2]];
        } else {
            _d set ["Pos", _resetPos];
            _d set ["PosDes", _resetPos];
        };
        
        // Snap Reset
        _d set ["AngDes", [getDir player, 0]];
        _d set ["Ang", [getDir player, 0]]; // Snap angle
        _d set ["RollDes", 0];
        _d set ["Roll", 0]; 
        _d set ["SpeedMult", 1.0];
        _d set ["FovDes", 0.7];
        _d set ["Fov", 0.7]; 
        (_d get "Cam") camSetFov 0.7;
        
        ["Camera Reset"] call (_d get "fnc_Msg");
    };

    // F (Follow Toggle - NO MOMENTUM)
    if (_key == 33) then {
        private _isFollowing = _d get "Follow";
        private _target = _d get "Target";
        private _currPos = _d get "Pos";
        private _currPosDes = _d get "PosDes";
        private _tPos = getPosASLVisual _target;

        if (_isFollowing) then {
            // Switching to FREE
            // Convert Relative Offset back to World Position directly
            _d set ["Pos", _tPos vectorAdd _currPos];
            _d set ["PosDes", _tPos vectorAdd _currPosDes];
            ["Follow Mode: OFF"] call (_d get "fnc_Msg");
        } else {
            // Switching to FOLLOW
            // Convert World Position to Relative Offset
            _d set ["Pos", _currPos vectorDiff _tPos];
            _d set ["PosDes", _currPosDes vectorDiff _tPos];
            ["Follow Mode: ON"] call (_d get "fnc_Msg");
        };
        
        _d set ["Follow", !_isFollowing];
    };

    // Arrows (Jump)
    if (_key == 203 || _key == 205) then {
        private _list = allPlayers select { alive _x };
        if (count _list > 0) then {
            private _curr = _d get "Target";
            private _idx = _list find _curr;
            if (_idx == -1) then { _idx = 0; };
            
            if (_key == 205) then { _idx = _idx + 1; } else { _idx = _idx - 1; };
            if (_idx >= count _list) then { _idx = 0; };
            if (_idx < 0) then { _idx = (count _list) - 1; };
            
            private _newTarget = _list select _idx;
            _d set ["Target", _newTarget];
            
            // JUMP LOGIC
            private _newTPos = getPosASLVisual _newTarget;
            
            if (_d get "Follow") then {
                private _offset = [0,0,2];
                _d set ["Pos", _offset];
                _d set ["PosDes", _offset];
            } else {
                private _worldPos = _newTPos vectorAdd [0,0,2];
                _d set ["Pos", _worldPos];
                _d set ["PosDes", _worldPos];
            };

            // Snap Rotation
            private _newAng = [getDir _newTarget, 0];
            _d set ["AngDes", _newAng];
            _d set ["Ang", _newAng]; 
            _d set ["RollDes", 0];
            _d set ["Roll", 0];
            
            [format ["Jump to: %1", name _newTarget]] call (_d get "fnc_Msg");
        };
    };

    private _keys = _d get "Keys";
    if !(_key in _keys) then { _keys pushBack _key; };
    false
}]);

// 2. KeyUp
_ehIds pushBack (_display displayAddEventHandler ["KeyUp", {
    params ["_disp", "_key"];
    private _keys = SCam_Data get "Keys";
    SCam_Data set ["Keys", _keys - [_key]];
    false
}]);

// 3. MouseMoving
_ehIds pushBack (_display displayAddEventHandler ["MouseMoving", {
    params ["_disp", "_x", "_y"];
    SCam_Data set ["MouseD", [_x, _y]];
    false
}]);

// 4. Scroll
_ehIds pushBack (_display displayAddEventHandler ["MouseZChanged", {
    params ["_disp", "_z"];
    private _d = SCam_Data;
    private _des = _d get "FovDes";
    private _change = _z * 0.05;
    _d set ["FovDes", (_des - _change) max 0.01 min 2.0];
    false
}]);

// 5. EachFrame
_ehIds pushBack (addMissionEventHandler ["EachFrame", {
    if (isNil "SCam_Data") exitWith {};
    private _d = SCam_Data;
    
    // --- INPUTS ---
    private _mouse = _d get "MouseD";
    _d set ["MouseD", [0,0]]; 
    private _keys = _d get "Keys";
    
    // --- ROTATION ---
    private _fov = _d get "Fov";
    private _sens = Bro_SCam_Sens * _fov;
    
    private _angDes = _d get "AngDes";
    private _yawDes = (_angDes select 0) + ((_mouse select 0) * _sens);
    private _pitDes = ((_angDes select 1) - ((_mouse select 1) * _sens)) max -89 min 89;
    _d set ["AngDes", [_yawDes, _pitDes]];
    
    // --- ROLL ---
    private _rollDes = _d get "RollDes";
    if (18 in _keys) then { _rollDes = _rollDes - Bro_SCam_RollSpeed; }; // E
    if (19 in _keys) then { _rollDes = _rollDes + Bro_SCam_RollSpeed; }; // R
    if (20 in _keys) then { _rollDes = 0; }; // T
    _d set ["RollDes", _rollDes];

    // --- SMOOTHING ---
    private _ang = _d get "Ang";
    private _roll = _d get "Roll";
    private _lerp = { params ["_a", "_b", "_t"]; _a + ((_b - _a) * _t) };
    
    private _yawNew = [_ang select 0, _yawDes, Bro_SCam_SmoothRot] call _lerp;
    private _pitNew = [_ang select 1, _pitDes, Bro_SCam_SmoothRot] call _lerp;
    private _rollNew = [_roll, _rollDes, Bro_SCam_SmoothRot] call _lerp;
    
    _d set ["Ang", [_yawNew, _pitNew]];
    _d set ["Roll", _rollNew];

    // --- VECTORS ---
    private _vx = sin(_yawNew) * cos(_pitNew);
    private _vy = cos(_yawNew) * cos(_pitNew);
    private _vz = sin(_pitNew);
    private _vecDir = [_vx, _vy, _vz];
    
    private _vecRightH = [cos(_yawNew), -sin(_yawNew), 0]; 
    private _vecUpBase = _vecRightH vectorCrossProduct _vecDir; 
    private _vecUp = (_vecUpBase vectorMultiply cos(_rollNew)) vectorAdd (_vecRightH vectorMultiply sin(_rollNew));

    // --- SPEED ---
    private _mult = _d get "SpeedMult";
    if (42 in _keys) then { _mult = _mult * 1.02; }; // Shift
    if (29 in _keys) then { _mult = _mult * 0.98; }; // Ctrl
    _mult = _mult max 0.01 min 200;
    _d set ["SpeedMult", _mult];

    // --- MOVEMENT ---
    private _speed = Bro_SCam_Speed * _mult;
    private _moveVec = [0,0,0];
    
    if (17 in _keys) then { _moveVec = _moveVec vectorAdd _vecDir; };
    if (31 in _keys) then { _moveVec = _moveVec vectorDiff _vecDir; };
    if (32 in _keys) then { _moveVec = _moveVec vectorAdd _vecRightH; };
    if (30 in _keys) then { _moveVec = _moveVec vectorDiff _vecRightH; };
    if (16 in _keys) then { _moveVec = _moveVec vectorAdd [0,0,1]; };
    if (44 in _keys) then { _moveVec = _moveVec vectorAdd [0,0,-1]; };
    
    if (vectorMagnitude _moveVec > 0) then {
        _moveVec = (vectorNormalized _moveVec) vectorMultiply _speed;
    };

    private _posDes = (_d get "PosDes") vectorAdd _moveVec;
    
    // --- GROUND COLLISION FIX ---
    private _targetBase = if (_d get "Follow") then { getPosASLVisual (_d get "Target") } else { [0,0,0] };
    private _absPosDes = _targetBase vectorAdd _posDes;
    private _terrZ = getTerrainHeightASL _absPosDes;
    
    if ((_absPosDes select 2) < (_terrZ + 0.5)) then {
        _absPosDes set [2, _terrZ + 0.5];
        if (_d get "Follow") then {
            _posDes = _absPosDes vectorDiff _targetBase;
        } else {
            _posDes = _absPosDes;
        };
    };

    _d set ["PosDes", _posDes];
    
    // Inertia Application
    private _pos = (_d get "Pos");
    _pos = _pos vectorAdd ((_posDes vectorDiff _pos) vectorMultiply Bro_SCam_SmoothPos);
    _d set ["Pos", _pos];

    // --- FINAL POSITION RESOLUTION ---
    private _finalCamPos = [0,0,0];
    
    if (_d get "Follow") then {
        private _tPos = getPosASLVisual (_d get "Target");
        _finalCamPos = _tPos vectorAdd _pos;
    } else {
        _finalCamPos = _pos;
    };

    // --- FOV APPLY ---
    private _fovDes = _d get "FovDes";
    private _fovNew = [_fov, _fovDes, Bro_SCam_SmoothFOV] call _lerp;
    _d set ["Fov", _fovNew];
    (_d get "Cam") camSetFov _fovNew;

    // --- HUD UPDATE ---
    if (_d get "HUD_Vis") then {
        private _followTxt = if (_d get "Follow") then { "<t color='#ff0000'>[FOLLOW]</t>" } else { "" };
        private _tgtName = name (_d get "Target");
        
        private _visMode = _d get "VisionMode";
        private _visStr = switch (_visMode) do {
            case 0: { "NORM" };
            case 1: { "NVG" };
            case 2: { "WHOT" };
            case 3: { "BHOT" };
            default { "NORM" };
        };

        (_d get "HUD") ctrlSetStructuredText parseText format [
            "<t align='left' size='1.2' font='RobotoCondensedLight'>" +
            "SPD: <t color='#00ff00'>%1</t><br/>" +
            "FOV: <t color='#00ffff'>%2</t><br/>" +
            "ROL: <t color='#ff00ff'>%3</t><br/>" +
            "POS: <t color='#ffff00'>%4</t> %5<br/>" +
            "TGT: <t color='#ffa500'>%6</t><br/>" +
            "VIS: <t color='#ffa500'>%7</t><br/>" +
            "<t size='0.8'>------------------------------</t><br/>" +
            "<t size='0.8' color='#dddddd'>CONTROLS</t><br/>" +
            "<t size='0.8'>" +
            "[WASD] Move <t color='#888888'>|</t> [Q/Z] Up/Down<br/>" +
            "[E/R] Roll <t color='#888888'>|</t> [T] Reset Roll<br/>" +
            "[Scroll] Zoom <t color='#888888'>|</t> [Shift/Ctrl] Speed<br/>" +
            "[F] Follow <t color='#888888'>|</t> [Arrows] Jump<br/>" +
            "[N] Vision <t color='#888888'>|</t> [G] Reset<br/>" +
            "[L] HUD <t color='#888888'>|</t> [Space] Exit" +
            "</t></t>",
            round(_mult * 100) / 100,
            round(_fovNew * 100) / 100,
            round(_rollNew * 10) / 10,
            mapGridPosition _finalCamPos,
            _followTxt,
            _tgtName,
            _visStr
        ];
    };
    
    // --- NOTIFICATION UPDATE ---
    if (diag_tickTime > (_d get "NotifyEnd")) then {
        (_d get "Notify") ctrlShow false;
    };

    // --- COMMIT ---
    private _cam = _d get "Cam";
    _cam setPosASL _finalCamPos;
    _cam setVectorDirAndUp [_vecDir, _vecUp];
    _cam camCommit 0;
}]);

SCam_Data set ["EH_List", _ehIds];

// Show Start Notification
["Cinematic Camera ON"] call (SCam_Data get "fnc_Msg");