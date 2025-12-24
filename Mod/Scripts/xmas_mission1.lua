--[[

 _______  _______           _______    _______           _______ _________ _______ _________ _______  _______  _______ 
(  ____ \(  ___  )|\     /|(  ____ \  (  ____ \|\     /|(  ____ )\__   __/(  ____ \\__   __/(       )(  ___  )(  ____ \
| (    \/| (   ) || )   ( || (    \/  | (    \/| )   ( || (    )|   ) (   | (    \/   ) (   | () () || (   ) || (    \/
| (_____ | (___) || |   | || (__      | |      | (___) || (____)|   | |   | (_____    | |   | || || || (___) || (_____ 
(_____  )|  ___  |( (   ) )|  __)     | |      |  ___  ||     __)   | |   (_____  )   | |   | |(_)| ||  ___  |(_____  )
      ) || (   ) | \ \_/ / | (        | |      | (   ) || (\ (      | |         ) |   | |   | |   | || (   ) |      ) |
/\____) || )   ( |  \   /  | (____/\  | (____/\| )   ( || ) \ \_____) (___/\____) |   | |   | )   ( || )   ( |/\____) |
\_______)|/     \|   \_/   (_______/  (_______/|/     \||/   \__/\_______/\_______)   )_(   |/     \||/     \|\_______)
                                                                                                                       
Battlezone Combat Commander: Holiday Zone
Event Scripting: F9bomber
]] --

assert(load(assert(LoadFile("_requirefix.lua")),"_requirefix.lua"))();
local config = require("mission1_config");

local Mission = {
	--Integers--
	TurnCounter = 0;

	--Mission Variables--
	_Text1 = "OBJECTIVE: Build a base as soon as possible.";
	_Text1Success = "COMPLETED: Setup a base.\n\n";
	_Text2 = "OBJECTIVE: Secure and evacuate all elves and holiday cargo. Utilize the Transport and Tug to extract and safeguard Christmas Eve. Both vessels cannot be lost.";
	_Text2Success = "COMPLETED: Transport and Tug have arrived.\n\n";
	_Text3 = "OBJECTIVE: Use the Transport to save the elves.";
	_Text3Success = "COMPLETED: Transport has safely picked up the elves.\n\n";
	_Text4 = "OBJECTIVE: Escort the Transport back to base.";
	_Text4Success = "COMPLETED: Transport is safe!\n\n";
	_Text5 = "OBJECTIVE: Use the Tug to haul the presents back to base.";
	_Text5Success = "COMPLETED: All presents are accounted for.\n\n";
	_Text6 = "OBJECTIVE: Tell Santa Claus to destroy the enemy HQ.";
	_Success = "Christmas is now saved! Congratulations Commander.";
	_Fail = "Consider yourself on the naughty list!";
	_TransportGone = "Transport lost!";
	_TugGone = "Transport lost!";
	_TugAndTransportGone = "Both Tug and Transport are gone!";
	
	--Booleans--
	IsTransportsSpawnedIn = false;
	IsTransportsInRoute = false;
	IsBaseOperational = false;
	FirstObjective = false;
	GoToBunker = false;
	Pickup = false;
	PilotMoveOut = false;
	TransportToBase = false;
	HostagesRecovered = false;
	GiftsBack = false;
	BombBase = false;
	Success = false;
	
	--Handles--
	Transport;
	Tug;
	NavBeacon;
	Defender1 = GetHandle(config.defender1);
	Defender2 = GetHandle(config.defender2);
	Defender3 = GetHandle(config.defender3);
	
	Gift1 = GetHandle(config.presentOne);
	Gift2 = GetHandle(config.presentTwo);
	Gift3 = GetHandle(config.presentThree);
	
	SantaPower = GetHandle(config.power);
	Santa = GetHandle(config.santaClaus);
	EnemyHQ = GetHandle(config.enemyBuilding);
	
	Building;
	Pilots;
	PlayerH = GetPlayerHandle();
	Recycler = GetHandle(config.recyclerHandle);
	Factory = GetHandle(config.factoryHandle);
}

function Save()
	return Mission
end

function Load(...)
	if select("#", ...) > 0 then
	  Mission = ...
	end
end

function AddObject(h) 
	if (IsOdf(h, config.recyclerVehicleODF)) then
		Mission.Recycler = h
		AddScrap(1, 40)
	end
	
	if (IsOdf(h, config.recyclerBuildingODF)) then
		Mission.Recycler = h
	end
	
	if (IsOdf(h, config.factoryODF)) then
		Mission.Factory = h
	end
	
end

function DeleteObject(h)
end

function InitialSetup()
	Mission.TPS = EnableHighTPS();
	AllowRandomTracks(true);

	local preloadODF = {
		config.recyclerVehicleODF,
		config.factoryODF,
		config.defender1,
		config.defender2,
		config.defender3,
	}

	for k, v in pairs(preloadODF) do
		PreloadODF(v);
	end
end

function Start()
	-- StopCheats() -- HOHOHO (COULD THIS WORK HERE?)
	print("Holiday Zone mission by " .. config.author);
	AddObjective(Mission._Text1, "blue", 15.0);
	Ally(1, 2);

	SetupTeamColors() -- Enemy team (6) is RED, while Player has no active teamcolor.

	AudioMessage("mission1_1.wav");

	AttackWave(config.wave1A, "transport_spawn", "transport_path", 2);
	AttackWave(config.wave1D, "transport_spawn", "transport_path", 2);
	AttackWave(config.wave1B, "gtow3", "Recycler", 2);
	AttackWave(config.wave1C, "gtow2", "Recycler", 1);
	AttackWave(config.wave1C, "stage3", "Recycler", 2);
	AttackWave(config.wave1D, "stage3", "Recycler", 3);
end

function Update()
	-- StopCheats() -- HOHOHO
	Mission.TurnCounter = Mission.TurnCounter + 1; -- if we needed to any time based events
	MissionLogic();
	DeletePilots();
	
	if Mission.IsTransportsInRoute == true then
		CheckVehicles()
	end
	
end

function SpawnPilots()

    Mission.Pilots = {}

    local spawnArea = GetPosition("bunk")
    local pos = SetVector(spawnArea.x, spawnArea.y, spawnArea.z)

    local count = 8
    local radius = 20

    for i = 1, count do
        local angle = (i / count) * (2 * 3.14159265)
        local offsetX = math.cos(angle) * radius
        local offsetZ = math.sin(angle) * radius

        local spawnPos = SetVector(pos.x + offsetX, pos.y, pos.z + offsetZ)

        local h = BuildObject("ispilo", 2, spawnPos)
		SetObjectiveOn(h)
		SetObjectiveName(h, "Elf");
        Mission.Pilots[i] = h
    end

    for i, pilot in ipairs(Mission.Pilots) do
        if pilot and Mission.Transport then
            Goto(pilot, Mission.Transport, 1)
        end
    end
	
end

function DeletePilots()
    if not Mission.Pilots then
        return true
    end

    if Mission.Transport then
        for i, pilot in pairs(Mission.Pilots) do
            if pilot and GetDistance(pilot, Mission.Transport) < 15.0 then
                RemoveObject(pilot)
                Mission.Pilots[i] = nil
            end
        end
    end

    return next(Mission.Pilots) == nil
end

function AttackWave(odfName, spawnPath, destPath, unitCount)
	local spawnMinRange = 10
	local spawnMaxRange = 75 -- 50
	for i = 1, unitCount  do
		Goto(BuildObject(odfName, 6, GetPositionNear(spawnPath, 0, spawnMinRange, spawnMaxRange)), destPath);
	end
end

function SetupTeamColors()
 	-- Team6=RED
	SetTeamColor(6, 140, 45, 45)
end

function CheckVehicles()
    local tugAround = IsAround(Mission.Tug)
    local transportAround = IsAround(Mission.Transport)

    if tugAround and transportAround then
    elseif tugAround and not transportAround then
		ClearObjectives();
		AddObjective(Mission._Fail, "red", 15.0);
		AddObjective(Mission._TransportGone, "white", 15.0);
		FailMission(5, "mission1_fail.des") -- TODO: Add des file here 

    elseif not tugAround and transportAround then
		ClearObjectives();
		AddObjective(Mission._Fail, "red", 15.0);
		AddObjective(Mission._TugGone, "white", 15.0);
		FailMission(5, "mission1_fail.des") -- TODO: Add des file here 

    else
		ClearObjectives();
		AddObjective(Mission._Fail, "red", 15.0);
		AddObjective(Mission._TugAndTransportGone, "white", 15.0);
		FailMission(5, "mission1_fail.des") -- TODO: Add des file here 
    end
end

function MissionLogic()	
	if (IsAround(Mission.Recycler)) and (IsAround(Mission.Factory)) then
		Mission.IsTransportsSpawnedIn = true;		
	end
	
	if  (Mission.IsTransportsSpawnedIn == true) and (Mission.IsTransportsInRoute == false) then
		ClearObjectives();
		AddObjective(Mission._Text1Success, "green", 15.0);
		AddObjective(Mission._Text2, "blue", 15.0);

		Mission.IsTransportsInRoute = true;
		Mission.Transport = BuildObject(config.transportODF, 2, "transport_spawn");
		SetObjectiveName(Mission.Transport, "Transport");
		SetObjectiveOn(Mission.Transport)
		Goto(Mission.Transport, "transport_path");
		
		local TransportPos = GetPosition(Mission.Transport);
	
		local pos = SetVector(TransportPos.x,
							   TransportPos.y,
							   TransportPos.z + 20);

		Mission.Tug = BuildObject(config.tugODF, 2, pos);
		SetObjectiveName(Mission.Tug, "Tug");
		SetObjectiveOn(Mission.Tug)
		Follow(Mission.Tug, Mission.Transport);

		AudioMessage("mission1_2.wav");
		
		AttackWave(config.wave1A, "gtow2", "Recycler", 2);
		AttackWave(config.wave1B, "gtow3", "Recycler", 2);
		AttackWave(config.wave1C, "recyclerEnemy", "Recycler", 3);
		AttackWave(config.wave1D, "recyclerEnemy", "Recycler", 3);
	end
	
	if ((GetDistance(Mission.Transport, "transport_give") < 50.0) and Mission.IsBaseOperational == false) then
		SetObjectiveOff(Mission.Transport);
		SetObjectiveOff(Mission.Tug);
		SetTeamNum(Mission.Transport, 1);
		SetTeamNum(Mission.Tug, 1);
		SetGroup(Mission.Transport, 8);
		SetGroup(Mission.Tug, 9);
		Stop(Mission.Tug, 0);
		Stop(Mission.Transport, 0);
		Mission.IsBaseOperational = true;
	end
	
	if (Mission.IsBaseOperational == true) and (Mission.FirstObjective == false) then
		ClearObjectives();
		AddObjective(Mission._Text2Success, "green", 15.0);
		AddObjective(Mission._Text3, "blue", 15.0);

		Mission.NavBeacon = BuildObject(config.navMarker, 1, "nav1");
		SetObjectiveName(Mission.NavBeacon, "Trapped Elves");
		SetObjectiveOn(Mission.NavBeacon)
		Mission.Defender1 = BuildObject(config.defender1, 6, "df1");
		Mission.Defender2 = BuildObject(config.defender2, 6, "df2");
		Mission.Defender3 = BuildObject(config.defender3, 6, "df3");
		Mission.Building = BuildObject(config.hostageBuilding, 0, "bunk");
		Mission.FirstObjective = true;

		AudioMessage("mission1_3.wav");

		AttackWave(config.wave1D, "recyclerEnemy", "Recycler", 3);
		AttackWave(config.wave2A, "recyclerEnemy", "nav1", 1);
		AttackWave(config.wave2B, "recyclerEnemy", "nav1", 2);
		AttackWave(config.wave2C, "transport_spawn", "transport_path", 2);
	end
	
	local check = Mission.GoToBunker;
	
	if (GetDistance(Mission.Transport, "nav1") < 700.0) then
		SetObjectiveOff(Mission.NavBeacon);
		
		if (IsAround(Mission.Defender1) == false and IsAround(Mission.Defender2) == false and 
		IsAround(Mission.Defender3) == false) then
			SetTeamNum(Mission.Transport, 2);
			check = true;
		end
		
		if (check == true) and (Mission.Pickup == false) then
			local hostageBuildingPos = GetPosition(Mission.Building);
			local pos = SetVector(hostageBuildingPos.x,
					   hostageBuildingPos.y,
					   hostageBuildingPos.z + 20);
			Goto(Mission.Transport, pos, 1);
			Mission.Pickup = true;
		end		
		
		if (GetDistance(Mission.Transport, "bunk") < 30.0 and Mission.PilotMoveOut == false) then
			ClearObjectives();
			AddObjective(Mission._Text3Success, "green", 15.0);
			AddObjective(Mission._Text4, "blue", 15.0);

			SpawnPilots()
			Stop(Mission.Transport, 0);
			Mission.PilotMoveOut = true;

			AudioMessage("mission1_4.wav");

			AttackWave(config.wave1B, "transport_spawn", "transport_path", 2);
			AttackWave(config.wave1C, "recyclerEnemy", "Recycler", 2);
			AttackWave(config.wave1D, "recyclerEnemy", "Recycler", 3);
			AttackWave(config.wave2B, "recyclerEnemy", "Recycler", 2);
			AttackWave(config.wave3A, "recyclerEnemy", "nav1", 1);
			AttackWave(config.wave3B, "recyclerEnemy", "nav1", 2);
			AttackWave(config.wave3C, "recyclerEnemy", "hold4", 2);
			AttackWave(config.wave0A, "recyclerEnemy", "gtow3", 1);
			AttackWave(config.wave0B, "recyclerEnemy", "gtow4", 1);
			AttackWave(config.wave0B, "recyclerEnemy", "gtow5", 1);
		end		
	end
	
    if Mission.PilotMoveOut and DeletePilots() then
        -- ClearObjectives();
        SetTeamNum(Mission.Transport, 1);
		SetGroup(Mission.Transport, 8);
        Mission.TransportToBase = true
    end
	
	if (GetDistance(Mission.Transport, "transport_give") < 150.0) and Mission.TransportToBase == true and Mission.HostagesRecovered == false then
		ClearObjectives();
		AddObjective(Mission._Text4Success, "green", 15.0);
		AddObjective(Mission._Text5, "blue", 15.0);

		SetTeamNum(Mission.Transport, 2);

		Mission.NavBeacon = BuildObject(config.navMarker, 1, "nav2");
		SetObjectiveName(Mission.NavBeacon, "Presents");
		SetObjectiveOn(Mission.NavBeacon)
		Mission.Gift1 = BuildObject(config.presentOne, 0, "pres1");
		Mission.Gift2 = BuildObject(config.presentTwo, 0, "pres2");
		Mission.Gift3 = BuildObject(config.presentThree, 0, "pres3");
		
		SetObjectiveOn(Mission.Gift1)
		SetObjectiveName(Mission.Gift1, "Present");
		
		SetObjectiveOn(Mission.Gift2)
		SetObjectiveName(Mission.Gift2, "Present");
		
		SetObjectiveOn(Mission.Gift3)
		SetObjectiveName(Mission.Gift3, "Present");

		Mission.HostagesRecovered = true;

		AudioMessage("mission1_5.wav");

		AttackWave(config.wave1D, "recyclerEnemy", "Recycler", 3);
		AttackWave(config.wave2B, "recyclerEnemy", "Recycler", 1);
		AttackWave(config.wave3A, "recyclerEnemy", "Recycler", 1);
		AttackWave(config.wave2B, "recyclerEnemy", "Recycler", 2);
		AttackWave(config.wave3A, "recyclerEnemy", "nav2", 1);
		AttackWave(config.wave2B, "recyclerEnemy", "nav2", 2);
		AttackWave(config.wave3C, "recyclerEnemy", "nav2", 3);
		AttackWave(config.wave0A, "gtow1", "nav2", 1);
		AttackWave(config.wave0B, "recyclerEnemy", "nav2", 1);
	end
	
	if (GetDistance(Mission.Gift1, "transport_give") < 350.0) and (GetDistance(Mission.Gift2, "transport_give") < 350.0)
	and (GetDistance(Mission.Gift3, "transport_give") < 350.0) then
		Mission.GiftsBack = true;
	end
	
	if Mission.GiftsBack == true and Mission.BombBase == false then
		ClearObjectives();
		AddObjective(Mission._Text5Success, "green", 15.0);
		AddObjective(Mission._Text6, "blue", 15.0);
		
		SetObjectiveOff(Mission.Gift1)
		SetObjectiveOff(Mission.Gift2)
		SetObjectiveOff(Mission.Gift3)

		Mission.EnemyHQ = BuildObject(config.enemyBuilding, 6, "hq");
		Mission.Santa = BuildObject(config.santaClaus, 1, "santa");
		Mission.SantaPower = BuildObject(config.power, 1, "pow");
		SetObjectiveOn(Mission.EnemyHQ)
		Mission.BombBase = true;

		AudioMessage("mission1_6.wav");
		
		AttackWave(config.wave1D, "recyclerEnemy", "Recycler", 3);
		AttackWave(config.wave2B, "recyclerEnemy", "Recycler", 1);
		AttackWave(config.wave3A, "recyclerEnemy", "Recycler", 2);
		AttackWave(config.wave2B, "recyclerEnemy", "Recycler", 2);
		AttackWave(config.wave3A, "recyclerEnemy", "Recycler", 2);
		AttackWave(config.wave2B, "recyclerEnemy", "Recycler", 2);
		AttackWave(config.wave3A, "recyclerEnemy", "Recycler", 1);
		AttackWave(config.wave3C, "recyclerEnemy", "gtow3", 3);
		AttackWave(config.wave3B, "recyclerEnemy", "gtow3", 2);
		AttackWave(config.wave3B, "recyclerEnemy", "gtow2", 3);
		AttackWave(config.wave0B, "recyclerEnemy", "hold1", 1);
		AttackWave(config.wave0B, "recyclerEnemy", "hold2", 1);

	end
	
	if Mission.BombBase == true and not IsAround(Mission.EnemyHQ) then
		ClearObjectives();
		AddObjective(Mission._Success, "green", 15.0);
		SucceedMission(5, "mission1_pass.des") -- TODO: Add des file here
		Mission.Success = true
	end
	
	
end


