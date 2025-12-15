#include "\a3\editor_f\Data\Scripts\dikCodes.h"

// --- KEYBIND ---
[
    "[Bro] Simple Cinematic Camera",
    "bro_simplecamOpen",
    "Open Simple Cinematic Camera",
    {[] execVM "bro_simplecam\simplecam.sqf";},
    ""
] call CBA_fnc_addKeybind;

// --- CBA SETTINGS ---

// 1. Whitelist (New)
[
    "Bro_SCam_Whitelist", 
    "EDITBOX", 
    ["Allowed Users (Whitelist)", "Comma-separated list of profile names allowed to use the camera. Leave EMPTY to allow everyone.\nExample: Bromine, Fluorine, John Army"], 
    "[Bro] Simple Cinematic Camera", 
    "", // Default empty
    true // Global (Server can force this setting)
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

// 5. Rotation Smoothing
[
    "Bro_SCam_SmoothRot", 
    "SLIDER", 
    ["Rotation Smoothness", "Lower values = Smoother mouse movement."], 
    "[Bro] Simple Cinematic Camera", 
    [0.001, 0.5, 0.01, 3], 
    nil
] call CBA_Settings_fnc_init;

// 6. FOV Smoothing
[
    "Bro_SCam_SmoothFOV", 
    "SLIDER", 
    ["Zoom Smoothness", "How fast the zoom reacts."], 
    "[Bro] Simple Cinematic Camera", 
    [0.001, 0.5, 0.01, 3], 
    nil
] call CBA_Settings_fnc_init;

// 7. Roll Speed
[
    "Bro_SCam_RollSpeed", 
    "SLIDER", 
    ["Roll Speed", "How fast E and R roll the camera."], 
    "[Bro] Simple Cinematic Camera", 
    [0.01, 2.0, 0.1, 2], 
    nil
] call CBA_Settings_fnc_init;