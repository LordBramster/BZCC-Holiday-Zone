--- BZCC LUA Extended API Hook.
-- 
-- Event hook for event observer pattern.
-- 
-- @module _hook
-- @author John "Nielk1" Klein

local debugprint = debugprint or function() end;

debugprint("_hook Loading");

local hook = {};

hook.Hooks = {};
hook.SaveLoadHooks = {};

local priorities = {};

--- Table of all hooks.
function hook.GetTable() return hook.Hooks end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

--- Add a hook to listen to the specified event.
-- @param event Event to be hooked (string)
-- @param identifier Identifier for this hook observer (string)
-- @param func Function to be executed (function)
-- @param priority Higher numbers are higher priority (number) (optional, default 0)
function hook.Add( event, identifier, func, priority )
    if not isstring(event) then error("Paramater event must be a string."); end
    if not isstring(identifier) then error("Paramater identifier must be a string."); end
    if not isfunction(func) then error("Paramater func must be a function."); end
    if priority == nil or not isnumber(priority) then priority = 0; end

    if (hook.Hooks[ event ] == nil) then
        hook.Hooks[ event ] = {};
    end

    if not has_value(priorities, priority) then
        table.insert(priorities, priority);
        table.sort(priorities);
    end

    hook.Hooks[ event ][ identifier ] = { priority = priority, func = func };
  
    debugprint("Added " .. event .. " hook for " .. identifier .. " with priority " .. priority );
end

-- Removes the hook with the given indentifier.
-- @param event Event to be hooked (string)
-- @param identifier Identifier for this hook observer (string)
function hook.Remove( event, name )
    if not isstring(event) then error("Paramater event must be a string."); end
    if not isstring(identifier) then error("Paramater identifier must be a string."); end
    hook.Hooks[ event ][ name ] = nil;
    
    debugprint("Removed " .. event .. " hook for " .. identifier);
end

--- Add a hook to listen to the Save, Load, and PostLoad event.
-- @param identifier Identifier for this hook observer (string)
-- @param save Function to be executed for Save (function) (optional)
-- @param load Function to be executed for Load (function) (optional)
-- @param postload Function to be executed for PostLoad (function) (optional)
function hook.AddSaveLoad( identifier, save, load, postload )
    if not isstring(identifier) then error("Paramater identifier must be a string."); end
    if save == nil and load == nil and postload == nil then error("At least one of paramaters save, load, and postload must be supplied."); end
    if save ~= nil and not isfunction(save) then error("Paramater save must be a function."); end
    if load ~= nil and not isfunction(load) then error("Paramater load must be a function."); end
    if postload ~= nil and not isfunction(postload) then error("Paramater postload must be a function."); end

    if (hook.SaveLoadHooks[ identifier ] == nil) then
        hook.SaveLoadHooks[identifier ] = {};
    end

    hook.SaveLoadHooks[ identifier ]['Save'] = save;
    hook.SaveLoadHooks[ identifier ]['Load'] = load;
    hook.SaveLoadHooks[ identifier ]['PostLoad'] = postload;
    
    debugprint("Added Save/Load hooks for " .. identifier);
end

--- Removes the Save, Load, and PostLoad hooks with the given indentifier.
-- @param identifier Identifier for this hook observer (string)
function hook.RemoveSaveLoad( identifier )
    if not isstring(identifier) then error("Paramater identifier must be a string."); end
    if ( not hook.SaveLoadHooks[ identifier ] ) then return; end
    hook.SaveLoadHooks[ identifier ] = nil;
    
    debugprint("Removed Save/Load hooks for " .. identifier);
end

--- Calls hooks associated with Save.
function hook.CallSave()
    if ( hook.SaveLoadHooks ~= nil ) then
        local ret = {};
        for k, v in pairs( hook.SaveLoadHooks ) do 
            if v.Save ~= nil and isfunction(v.Save) then
                ret[k] = {v.Save()};
            else
                ret[k] = {};
            end
        end
        return ret
    end
    return
end

--- Calls hooks associated with Load.
function hook.CallLoad(SaveData)
    if ( hook.SaveLoadHooks ~= nil ) then
        local ret = {};
        for k, v in pairs( hook.SaveLoadHooks ) do
            if v.Load ~= nil and isfunction(v.Load) then
                v.Load(table.unpack(SaveData[k]));
            end
        end
        return ret
    end
    return
end

--- Calls hooks associated with PostLoad.
function hook.CallPostLoad()
    if ( hook.SaveLoadHooks ~= nil ) then
        local ret = {};
        for k, v in pairs( hook.SaveLoadHooks ) do 
            if v.PostLoad ~= nil and isfunction(v.PostLoad) then
                v.PostLoad();
            end
        end
        return ret
    end
    return
end

local range = function(from, to, step)
  step = step or 1
  return function(_, lastvalue)
    local nextvalue = lastvalue + step
    if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
       step == 0
    then
      return nextvalue
    end
  end, nil, from - step
end


--- Calls hooks associated with the hook name ignoring any return values.
-- @param event Event to be hooked (string)
-- @param ... Paramaters passed to every hooked function
-- @todo this function must be rewritten to not be n*m and awful.
function hook.CallAllNoReturn( event, ... )
    local HookTable = hook.Hooks[ event ]
    if ( HookTable ~= nil ) then
        for i = #priorities, 1, -1 do
            local j = priorities[i];
            for k, v in pairs( HookTable ) do 
                if ( isstring( k ) ) then
                    if ( v.priority == j ) then
                        v.func( ... );
                    end
                else
                    HookTable[ k ] = nil
                end
            end
        end
    end
end

local function appendhelper(a, n, b, ...)
  if   n == 0 then return a
  else             return b, appendhelper(a, n-1, ...) end
end
local function appendvargs(a, ...)
  return appendhelper(a, select('#', ...), ...)
end

--- Calls hooks associated with the hook name passing each return to the next.
-- Hooked functions may return 2 values.  The first will be passed to the next
-- as the last paramater.  The second, if true, will stop the execution of hooks.
-- @param event Event to be hooked (string)
-- @param ... Paramaters passed to every hooked function
-- @todo this function must be rewritten to not be n*m and awful.
function hook.CallAllPassReturn( event, ... )
    local HookTable = hook.Hooks[ event ]
    local lastreturn = nil;
    local stopnow = false;
    if ( HookTable ~= nil ) then
        for i = #priorities, 1, -1 do
            local j = priorities[i];
            for k, v in pairs( HookTable ) do 
                if ( isstring( k ) ) then
                    if ( v.priority == j ) then
                        lastreturn, stopnow = v.func( appendvargs(lastreturn, ...) );
                        if stopnow == true then break; end
                    end
                else
                    HookTable[ k ] = nil
                end
            end
            if stopnow == true then break; end
        end
    end
    return lastreturn, stopnow;
end

debugprint("_hook Loaded");

return hook;