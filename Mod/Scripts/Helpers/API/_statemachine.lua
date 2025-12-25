--- BZCC LUA Extended API StateMachineIter.
-- 
-- State Machine and State Machine Iterator for serial event sequences across game turns.
-- 
-- @module _statemachine
-- @author John "Nielk1" Klein
-- @usage local statemachine = require("_statemachine");
-- 
-- statemachine.Create("TestMachine2",
--     {
--         ["state_a"] = function(state)
--             print("test D");
--             state:switch("state_b");
--         end,
--         ["state_b"] = statemachine.SleepSeconds(10,"state_c"),
--         ["state_c"] = function(state)
--             print("test E");
--             state:switch("state_d");
--         end,
--         ["state_d"] = statemachine.SleepSeconds(15,"state_e"),
--         ["state_e"] = function(state)
--             print("test F");
--             state:switch("state_f");
--         end
--     });
-- 
-- hook.Add("InitialSetup", "Custom_InitialSetup", function(turn)
--     MissionData.TestSMI = statemachine.Start("TestMachine2","state_a",{test='c',test2="d"});
-- end);
-- 
-- hook.Add("Update", "Custom_Update", function(turn)
--     MissionData.TestSMI:run();
-- end);

local debugprint = debugprint or function() end;

debugprint("_statemachine Loading");

local _api = require("_api");

local _statemachine = {};

_statemachine.Machines = {};

--- Is this object an instance of StateMachineIter?
-- @param object Object in question
-- @return bool
function isstatemachineiter(object)
  return (type(object) == "table" and object.__type == "StateMachineIter");
end

--- StateMachineIter.
-- An object containing all functions and data related to an StateMachineIter.
local StateMachineIter = {}; -- the table representing the class, which will double as the metatable for the instances
--GameObject.__index = GameObject; -- failed table lookups on the instances should fallback to the class table, to get methods
StateMachineIter.__index = function(table, key)
  local retVal = rawget(table, key);
  if retVal ~= nil then return retVal; end
  if rawget(table, "addonData") ~= nil and rawget(rawget(table, "addonData"), key) ~= nil then return rawget(rawget(table, "addonData"), key); end
  return rawget(StateMachineIter, key); -- if you fail to get it from the subdata, move on to base (looking for functions)
end
StateMachineIter.__newindex = function(table, key, value)
  if key ~= "template" and key ~= "state_key" and key ~= "timer" and key ~= "addonData" then
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
StateMachineIter.__type = "StateMachineIter";

--- Create StateMachineIter
-- @param name StateMachineIter template (string)
-- @param timer Timer's value, -1 for not set (int)
-- @param state_key Current state (string)
-- @param values Table of values embeded in the StateMachineIter
local CreateStateMachineIter = function(name, timer, state_key, values)
  local self = setmetatable({}, StateMachineIter);
  self.template = name;
  self.timer = timer;
  self.state_key = state_key;
  
  if istable(values) then
    for k, v in pairs( values ) do 
      self[k] = v;
    end
  end
  
  return self;
end

--- Run StateMachineIter.
-- @param self FuncArrayIter instance
function StateMachineIter.run(self)
    if not isstatemachineiter(self) then error("Paramater self must be StateMachineIter instance."); end
    
    local machine = _statemachine.Machines[self.template];
    if machine == nil then return false; end

    if isfunction(machine[self.state_key]) then
        return true, machine[self.state_key](self);
    end
    if istable(machine[self.state_key]) then
        if isfunction(machine[self.state_key][1]) then
            return true, machine[self.state_key][1](self, table.unpack(machine[self.state_key][2]));
        end
    end
    return false;
end

--- Switch StateMachineIter State.
-- @param self StateMachineIter instance
-- @param key State to switch to
function StateMachineIter.switch(self, key)
    self.state_key = key;
end

-- Creates an StateMachineIter Template with the given indentifier.
-- @param name Name of the StateMachineIter Template (string)
-- @param states State function table
function _statemachine.Create( name, states )
    if not isstring(name) then error("Paramater name must be a string."); end
    
    if (_statemachine.Machines[ name ] == nil) then
        _statemachine.Machines[ name ] = {};
    end
    
    _statemachine.Machines[ name ] = states;
end

-- Starts an StateMachineIter based on the StateMachineIter Template with the given indentifier.
-- @param event Name of the StateMachineIter Template (string)
-- @param state_key Initial state (string)
-- @param init Initial data (table)
function _statemachine.Start( name, state_key, init )
    if not isstring(name) then error("Paramater name must be a string."); end
    if init ~= nil and not istable(init) then error("Paramater init must be table or nil."); end
    if (_statemachine.Machines[ name ] == nil) then error('StateMachineIter Template "' .. name .. '" not found.'); end

    return CreateStateMachineIter(name, -1, state_key, init);
end

-- Wait a set period of time on this state.
-- @param state StateMachineIter data (StateMachineIter)
-- @param seconds How many seconds to wait (int)
-- @param next_state Next state when timer hits zero (string)
function _statemachine.SleepSeconds( seconds, next_state )
    if not isinteger(seconds) then error("Paramater seconds must be an integer."); end
    if not isstring(next_state) then error("Paramater next_state must be a string."); end

    return {(function(state, ...)
        local seconds, next_state = ...;
        if state.timer == -1 then
            state.timer = seconds * GetTPS();
        elseif state.timer == 0 then
            state:switch(next_state);
            state.timer = -1;
        else
            state.timer = state.timer - 1;
        end
    end), {seconds, next_state}};
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- StateMachineIter - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Save event function.
-- INTERNAL USE.
-- @param self StateMachineIter instance
-- @return ...
function StateMachineIter.Save(self)
    return self;
end

--- Load event function.
-- INTERNAL USE.
-- @param data
function StateMachineIter.Load(data)
    return CreateStateMachineIter(data.template, data.timer, data.state_key, data.addonData);
end

--- BulkSave event function.
-- INTERNAL USE.
-- @return data to save in bulk
function StateMachineIter.BulkSave()
    return;
end

--- BulkLoad event function.
-- INTERNAL USE.
-- @param data
function StateMachineIter.BulkLoad(data)

end

--- BulkPostLoad event function.
-- INTERNAL USE.
function StateMachineIter.BulkPostLoad()

end

_api.RegisterCustomSavableType(StateMachineIter);

debugprint("_statemachine Loaded");

return _statemachine;