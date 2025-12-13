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
local config = require("mission_config");

local Mission = {
	--Integers--
	TurnCounter = 0;

	--Mission Variables--
	_Text1 = "OBJECTIVE: Setup a base and awhile further orders.";
	_Text1Success = "OBJECTIVE: Setup a base.\n\n";
	_Text2 = "OBJECTIVE: Secure and evacuate all hostages and holiday cargo. Utilize the transport and tug to extract and safeguard these assets. Both vessels is essential and critical to the success of Christmas.";
	_Text2Success = "OBJECTIVE: Transport and Tug arrived in base.\n\n";
	_Text3 = "OBJECTIVE: Use the Transport to save the hostages.";
	_Text3Success = "OBJECTIVE: Transport has safely picked up the hostages.\n\n";
	_Text4 = "OBJECTIVE: Escort the Transport back to base.";
	_Text4Success = "OBJECTIVE: Transport is back at base.\n\n";
	_Text5 = "OBJECTIVE: Use the Tug to bring the presents back to base.";
	_Text5Success = "OBJECTIVE: All presents are back at base.\n\n";
	_Text6 = "OBJECTIVE: Use Santa Claus to destroy the enemey HQ.";
	_Success = "Christmas is now saved! Congratulations Commander.";
	_Fail = "Consider yourself on the naughty list.";
	_TransportGone = "Transport is gone!";
	_TugGone = "Transport is gone!";
	_TugAndTransportGone = "Both Tuge and Transport are gone!";
	
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
	Defender1 = GetHandle(config.defender);
	Defender2 = GetHandle(config.defender);
	Defender3 = GetHandle(config.defender);
	
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
		config.defender,
	}

	for k, v in pairs(preloadODF) do
		PreloadODF(v);
	end
end

function Start()
	print("Holiday Zone mission by " .. config.author);
	AddObjective(Mission._Text1, "yellow", 15.0);
	Ally(1, 2);
end

function Update()
	StopCheats()
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
		SetObjectiveName(h, "Hostage");
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

function CheckVehicles()
    local tugAround = IsAround(Mission.Tug)
    local transportAround = IsAround(Mission.Transport)

    if tugAround and transportAround then
    elseif tugAround and not transportAround then
		ClearObjectives();
		AddObjective(Mission._Fail, "red", 15.0);
		AddObjective(Mission._TransportGone, "white", 15.0);
		FailMission(5.0, "") -- TODO: Add des file here 

    elseif not tugAround and transportAround then
		ClearObjectives();
		AddObjective(Mission._Fail, "red", 15.0);
		AddObjective(Mission._TugGone, "white", 15.0);
		FailMission(5.0, "") -- TODO: Add des file here 

    else
		ClearObjectives();
		AddObjective(Mission._Fail, "red", 15.0);
		AddObjective(Mission._TugAndTransportGone, "white", 15.0);
		FailMission(5.0, "") -- TODO: Add des file here 
    end
end

function MissionLogic()	
	if (IsAround(Mission.Recycler)) and (IsAround(Mission.Factory)) then
		Mission.IsTransportsSpawnedIn = true;		
	end
	
	if  (Mission.IsTransportsSpawnedIn == true) and (Mission.IsTransportsInRoute == false) then
		ClearObjectives();
		AddObjective(Mission._Text1Success, "green", 15.0);
		AddObjective(Mission._Text2, "yellow", 15.0);
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
	end
	
	if ((GetDistance(Mission.Transport, "transport_give") < 20.0) and Mission.IsBaseOperational == false) then
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
		AddObjective(Mission._Text3, "yellow", 15.0);
		Mission.NavBeacon = BuildObject(config.navMarker, 1, "nav1");
		SetObjectiveName(Mission.NavBeacon, "Hostages");
		SetObjectiveOn(Mission.NavBeacon)
		Mission.Defender1 = BuildObject(config.defender, 6, "df1");
		Mission.Defender2 = BuildObject(config.defender, 6, "df2");
		Mission.Defender3 = BuildObject(config.defender, 6, "df3");
		Mission.Building = BuildObject(config.hostageBuilding, 0, "bunk");
		Mission.FirstObjective = true;
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
			AddObjective(Mission._Text4, "yellow", 15.0);
			SpawnPilots()
			Stop(Mission.Transport, 0);
			Mission.PilotMoveOut = true;
		end		
	end
	
    if Mission.PilotMoveOut and DeletePilots() then
        ClearObjectives();
        SetTeamNum(Mission.Transport, 1);
		SetGroup(Mission.Transport, 8);
        Mission.TransportToBase = true
    end
	
	if (GetDistance(Mission.Transport, "transport_give") < 150.0) and Mission.TransportToBase == true and Mission.HostagesRecovered == false then
		ClearObjectives();
		AddObjective(Mission._Text4Success, "green", 15.0);
		AddObjective(Mission._Text5, "yellow", 15.0);
		
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
	end
	
	if (GetDistance(Mission.Gift1, "transport_give") < 150.0) and (GetDistance(Mission.Gift2, "transport_give") < 150.0)
	and (GetDistance(Mission.Gift3, "transport_give") < 150.0) then
		Mission.GiftsBack = true;
	end
	
	if Mission.GiftsBack == true and Mission.BombBase == false then
		ClearObjectives();
		AddObjective(Mission._Text5Success, "green", 15.0);
		AddObjective(Mission._Text6, "yellow", 15.0);
	
	
		SetObjectiveOff(Mission.Gift1)
		SetObjectiveOff(Mission.Gift2)
		SetObjectiveOff(Mission.Gift3)
		
		Mission.EnemyHQ = BuildObject(config.enemyBuilding, 6, "hq");
		Mission.Santa = BuildObject(config.santaClaus, 1, "santa");
		Mission.SantaPower = BuildObject(config.power, 1, "pow");
		SetObjectiveOn(Mission.EnemyHQ)
		Mission.BombBase = true;
	end
	
	if Mission.BombBase == true and not IsAround(Mission.EnemyHQ) then
		ClearObjectives();
		AddObjective(Mission._Success, "green", 15.0);
		SucceedMission(5.0, "") -- TODO: Add des file here
		Mission.Success = true
	end
	
	
end


