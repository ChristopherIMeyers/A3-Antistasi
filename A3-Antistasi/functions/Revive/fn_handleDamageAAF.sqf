// HandleDamage event handler for enemy (gov/inv) AIs

params ["_unit","_part","_damage","_injurer","_projectile","_hitIndex","_instigator","_hitPoint"];

// Functionality unrelated to Antistasi revive
if (side _injurer == teamPlayer) then
{
	// Helmet popping: use _hitpoint rather than _part to work around ACE calling its fake hitpoint "head"
	if (_damage >= 1 && {_hitPoint == "hithead"}) then
	{
		if (random 100 < helmetLossChance) then
		{
			removeHeadgear _unit;
		};
	};

	private _groupX = group _unit;
	if (time > _groupX getVariable ["movedToCover",0]) then
	{
		if ((behaviour leader _groupX != "COMBAT") and (behaviour leader _groupX != "STEALTH")) then
		{
			_groupX setVariable ["movedToCover",time + 120];
			{[_x,_injurer] call A3A_fnc_unitGetToCover} forEach units _groupX;
		};
	};

	if (_part == "" && _damage < 1) then 
	{
		if (_damage > 0.6) then {[_unit,_injurer] spawn A3A_fnc_unitGetToCover};
	};
};

// Let ACE medical handle the rest (inc return value) if it's running
if (hasACEMedical) exitWith {};


private _makeUnconscious =
{
	params ["_unit", "_injurer"];
	_unit setVariable ["incapacitated",true,true];
	_unit setUnconscious true;
	if (vehicle _unit != _unit) then
	{
		moveOut _unit;
	};
	if (isPlayer _unit) then {_unit allowDamage false};
	[_unit,_injurer] spawn A3A_fnc_unconsciousAAF;
};

if (side _injurer == teamPlayer) then
{
	if (_part == "") then
	{
		if (_damage >= 1) then
		{
			if (!(_unit getVariable ["incapacitated",false])) then
			{
				_damage = 0.9;
				[_unit,_injurer] call _makeUnconscious;
			}
			else
			{
				// already unconscious, check whether we're pushed into death
				_overall = (_unit getVariable ["overallDamage",0]) + (_damage - 1);
				if (_overall > 0.5) then
				{
					_unit removeAllEventHandlers "HandleDamage";
				}
				else
				{
					_unit setVariable ["overallDamage",_overall];
					_damage = 0.9;

				};
			};
		}
		else
		{

            //Abort helping if hit too hard
			if (_damage > 0.25) then
			{
				if (_unit getVariable ["helping",false]) then
				{
					_unit setVariable ["cancelRevive",true];
				};
			};
		};
	}
	else
	{
		if (_damage >= 1) then
		{
			if !(_part in ["arms","hands","legs"]) then
			{
				_damage = 0.9;
				// Don't trigger unconsciousness on sub-part hits (face/pelvis etc), only the container
				if (_part in ["head","body"]) then
				{
					if !(_unit getVariable ["incapacitated",false]) then
					{
						[_unit,_injurer] call _makeUnconscious;

					};
				};
			};
		};
	};
};

_damage

