debugprint = debugprint or function() end;
debugprint("_api_editor_tunnelfix Loading");

local script_edit_fixtunnel = CalcCRC("script.edit.fixtunnel");
IFace_CreateCommand("script.edit.fixtunnel");
IFace_ConsoleCmd("bind p script.edit.fixtunnel");

local ObjectsToAdjust = {};
hook.Add("Update", "TunnelFixer_Update", function(object)
    for i, bld in ipairs(ObjectsToAdjust) do
        local pos = bld:GetPosition();
        pos.x = math.floor(pos.x + 0.5);
        pos.z = math.floor(pos.z + 0.5);
        bld:SetPosition(pos);
        print("Adjusting Position of " .. tostring(bld:GetHandle()));
    end
    ObjectsToAdjust = {};
end);

hook.Add("AddObject", "TunnelFixer_AddObject", function(obj)
    --if string.find(obj:GetOdf(), "^pbatun%d%d%.odf$") then
    --    print("Will adjust object " .. tostring(obj:GetHandle()));
    --    table.insert(ObjectsToAdjust, obj);
    --end
end);

hook.Add("ProcessCommand", "TunnelFixer_ProcessCommand", function(crc)
    if crc == script_edit_fixtunnel then
        local player = GetPlayerGameObject(1);
        local bld = player:InBuilding();
        if isgameobject(bld) then
            local front = Normalize(player:GetFront());
            local pos = bld:GetPosition();
            local x = math.abs(front.x);
            local z = math.abs(front.z);
            print(x .. "," .. z);
            if x > z then
                pos.x = math.floor(pos.x + 0.5) + (1 * math.ceil(front.x/math.abs(front.x)));
            else
                pos.z = math.floor(pos.z + 0.5) + (1 * math.ceil(front.z/math.abs(front.z)));
            end           
            bld:SetPosition(pos);
        end
    end
end);

debugprint("_api_editor_tunnelfix Loaded");