#include "\a3\editor_f\Data\Scripts\dikCodes.h"

// --- KEYBIND ---
[
    "[Bro] Simple Cinematic Camera",
    "bro_simplecamOpen",
    "Open Simple Cinematic Camera",
    {[] execVM "bro_simplecam\simplecam.sqf";},
    ""
] call CBA_fnc_addKeybind;

// --- CBA SETTINGS (Addon Options) ---

// 1. Mouse Sensitivity
[
    "Bro_SCam_Sens", 
    "SLIDER", 
    ["Mouse Sensitivity", "How fast the camera turns."], 
    "[Bro] Simple Cinematic Camera", 
    [0.01, 1.0, 0.15, 2], // Min, Max, Default, Decimals
    nil // Client-side setting (not forced by server)
] call CBA_Settings_fnc_init;

// 2. Movement Speed Base
[
    "Bro_SCam_Speed", 
    "SLIDER", 
    ["Base Movement Speed", "The starting speed before Shift/Ctrl modifiers."], 
    "[Bro] Simple Cinematic Camera", 
    [0.01, 2.0, 0.07, 2], 
    nil
] call CBA_Settings_fnc_init;

// 3. Position Smoothing (Inertia)
[
    "Bro_SCam_SmoothPos", 
    "SLIDER", 
    ["Position Inertia", "Lower values = Heavier camera, takes longer to stop."], 
    "[Bro] Simple Cinematic Camera", 
    [0.001, 0.5, 0.01, 3], 
    nil
] call CBA_Settings_fnc_init;

// 4. Rotation Smoothing
[
    "Bro_SCam_SmoothRot", 
    "SLIDER", 
    ["Rotation Smoothness", "Lower values = Smoother mouse movement."], 
    "[Bro] Simple Cinematic Camera", 
    [0.001, 0.5, 0.01, 3], 
    nil
] call CBA_Settings_fnc_init;

// 5. FOV Smoothing
[
    "Bro_SCam_SmoothFOV", 
    "SLIDER", 
    ["Zoom Smoothness", "How fast the zoom reacts."], 
    "[Bro] Simple Cinematic Camera", 
    [0.001, 0.5, 0.01, 3], 
    nil
] call CBA_Settings_fnc_init;

// 6. Roll Speed
[
    "Bro_SCam_RollSpeed", 
    "SLIDER", 
    ["Roll Speed", "How fast E and R roll the camera."], 
    "[Bro] Simple Cinematic Camera", 
    [0.01, 2.0, 0.1, 2], 
    nil
] call CBA_Settings_fnc_init;