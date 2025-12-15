#include "\a3\editor_f\Data\Scripts\dikCodes.h"

[
	"[Bro] Simple Cinematic Camera",
	"bro_simplecamOpen",
	"Open Simple Cinematic Camera",
	{[] execVM "bro_simplecam\simplecam.sqf";},
	""
] call CBA_fnc_addKeybind;