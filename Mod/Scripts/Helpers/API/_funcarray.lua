--- BZCC LUA Extended API FuncArrayIter.
-- 
-- Function Array and Function Array Iterator for serial event sequences across game turns.
-- 
-- @module _funcarray
-- @author John "Nielk1" Klein
-- @usage local funcarray = require("_funcarray");
-- 
-- funcarray.Create("TestMachine",
--     function(state)
--         print("test A");
--         state:next();
--     end,
--     funcarray.SleepSeconds(10),
--     function(state)
--         print("test B");
--         state:next();
--     end,
--     funcarray.SleepSeconds(15),
--     function(state)
--         print("test C");
--         state:next();
--     end);
-- 
-- hook.Add("InitialSetup", "Custom_InitialSetup", function(turn)
--     MissionData.TestFAI = funcarray.Start("TestMachine",{test='a',test2="b"});
-- end);
-- 
-- hook.Add("Update", "Custom_Update", function(turn)
--     MissionData.TestFAI:run();
-- end);

local debugprint = debugprint or function() end;

debugprint("_funcarray Loading");

local _api = require("_api");

local _funcarray = {};

_funcarray.Machines = {};

--- Is this object an instance of FuncArrayIter?
-- @param object Object in question
-- @return bool
function isfuncarrayiter(object)
  return (type(object) == "table" and object.__type == "FuncArrayIter");
end

--- FuncArrayIter.
-- An object containing all functions and data related to an FuncArrayIter.
local FuncArrayIter = {}; -- the table representing the class, which will double as the metatable for the instances
--GameObject.__index = GameObject; -- failed table lookups on the instances should fallback to the class table, to get methods
FuncArrayIter.__index = function(table, key)
  local retVal = rawget(table, key);
  if retVal ~= nil then return retVal; end
  if rawget(table, "addonData") ~= nil and rawget(rawget(table, "addonData"), key) ~= nil then return rawget(rawget(table, "addonData"), key); end
  return rawget(FuncArrayIter, key); -- if you fail to get it from the subdata, move on to base (looking for functions)
end
FuncArrayIter.__newindex = function(table, key, value)
  if key ~= "template" and key ~= "state_index" and key ~= "timer" and key ~= "addonData" then
    local addonData = rawget(table, "addonData");
    if addonData == nil then
      rawset(table, "addonData", {});
      addonData = rawget(table, "addonData");
    end
    rawset(addonData, key, value);
  else
    rawset(table, key, value);
  end
end
FuncArrayIter.__type = "FuncArrayIter";

--- Create FuncArrayIter
-- @param name FuncArrayIter template (string)
-- @param timer Timer's value, -1 for not set (int)
-- @param state_index Current state (int)
-- @param values Table of values embeded in the FuncArrayIter
local CreateFuncArrayIter = function(name, timer, state_index, values)
  local self = setmetatable({}, FuncArrayIter);
  self.template = name;
  self.timer = timer;
  self.state_index = state_index;
  
  if istable(values) then
    for k, v in pairs( values ) do 
      self[k] = v;
    end
  end
  
  return self;
end

--- Run FuncArrayIter.
-- @param self FuncArrayIter instance
function FuncArrayIter.run(self)
    if not isfuncarrayiter(self) then error("Paramater self must be FuncArrayIter instance."); end
    
    local machine = _funcarray.Machines[self.template];
    if machine == nil then return false; end
    if #machine < self.state_index then return false; end
    
    if isfunction(machine[self.state_index]) then
        return true, machine[self.state_index](self);
    end
    if istable(machine[self.state_index]) then
        if isfunction(machine[self.state_index][1]) then
            return true, machine[self.state_index][1](self, table.unpack(machine[self.state_index][2]));
        end
    end
    return false;
end

--- Next FuncArrayIter State.
-- @param self FuncArrayIter instance
function FuncArrayIter.next(self)
    self.state_index = self.state_index + 1;
end

-- Creates an FuncArrayIter Template with the given indentifier.
-- @param name Name of the FuncArrayIter Template (string)
-- @param ... State functions
function _funcarray.Create( name, ... )
    if not isstring(name) then error("Paramater name must be a string."); end
    
    if (_funcarray.Machines[ name ] == nil) then
        _funcarray.Machines[ name ] = {};
    end
    
    _funcarray.Machines[ name ] = { ... };
end

-- Starts an FuncArrayIter based on the FuncArrayIter Template with the given indentifier.
-- @param event Name of the FuncArrayIter Template (string)
-- @param init Initial data (table)
function _funcarray.Start( name, init )
    if not isstring(name) then error("Paramater name must be a string."); end
    if init ~= nil and not istable(init) then error("Paramater init must be table or nil."); end
    if (_funcarray.Machines[ name ] == nil) then error('FuncArrayIter Template "' .. name .. '" not found.'); end

    return CreateFuncArrayIter(name, -1, 1, init);
end

-- Wait a set period of time on this state.
-- @param state FuncArrayIter data (FuncArrayIter)
-- @param seconds How many seconds to wait (int)
function _funcarray.SleepSeconds( seconds )
    if not isinteger(seconds) then error("Paramater seconds must be an integer."); end

    return {(function(state, ...)
        local seconds = ...;
        if state.timer == -1 then
            state.timer = seconds * GetTPS();
        elseif state.timer == 0 then
            state:next();
            state.timer = -1;
        else
            state.timer = state.timer - 1;
        end
    end), {seconds}};
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FuncArrayIter - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Save event function.
-- INTERNAL USE.
-- @param self FuncArrayIter instance
-- @return ...
function FuncArrayIter.Save(self)
    return self;
end

--- Load event function.
-- INTERNAL USE.
-- @param data
function FuncArrayIter.Load(data)
    return CreateFuncArrayIter(data.template, data.timer, data.state_index, data.addonData);
end

--- BulkSave event function.
-- INTERNAL USE.
-- @return data to save in bulk
function FuncArrayIter.BulkSave()
    return;
end

--- BulkLoad event function.
-- INTERNAL USE.
-- @param data
function FuncArrayIter.BulkLoad(data)

end

--- BulkPostLoad event function.
-- INTERNAL USE.
function FuncArrayIter.BulkPostLoad()

end

_api.RegisterCustomSavableType(FuncArrayIter);

debugprint("_funcarray Loaded");

return _funcarray;