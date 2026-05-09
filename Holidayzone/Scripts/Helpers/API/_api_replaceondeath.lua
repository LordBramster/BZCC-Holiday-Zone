--- BZCC LUA Extended API Replace on Death Extension.
--
-- Replace objects with alternate objects when they die.
--
-- Dependencies: `_hook`, `_api`
-- @module _api_replaceondeath
-- @author John "Nielk1" Klein

debugprint = debugprint or function() end;

debugprint("_api_replaceondeath Loading");

hook.Add("AddObject", "ReplaceOnDeath_AddObject", function(object)
    local newObjectOdf = object:GetOdf();
    local replaceWith,success = GetODFString(newObjectOdf, "ReplaceOnDeath", "ReplaceWith", "");
    if not success then return; end
    if not DoesODFExist(replaceWith) then return; end
    
    object.ReplaceOnDeathData = {};
    object.ReplaceOnDeathData.Item = replaceWith;
    object.ReplaceOnDeathData.Team = GetODFInt(newObjectOdf, "ReplaceOnDeath", "Team", -1);
    object.ReplaceOnDeathData.Height = GetODFFloat(newObjectOdf, "ReplaceOnDeath", "Height", 0);
end);

hook.Add("DeleteObject", "ReplaceOnDeath_DeleteObject", function(object)
    if object.ReplaceOnDeathData == nil or not istable(object.ReplaceOnDeathData) then return; end
    
    local Item = object.ReplaceOnDeathData.Item;
    local Team = object.ReplaceOnDeathData.Team;
    local Height = object.ReplaceOnDeathData.Height;
    
    if not isstring(Item) then return; end
    if not isinteger(Team) or Team == -1 then Team = object:GetTeamNum(); end
    if not isnumber(Height) then Height = 0; end
    
    local pos = object:GetPosition2();
    pos.y = pos.y + Height;
    local NewObject = BuildGameObject(Item, Team, pos);
end);

debugprint("_api_replaceondeath Loaded");