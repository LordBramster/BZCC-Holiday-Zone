--- BZCC LUA Extended API Print Fix.
-- 
-- Hot-patches print to handle newlines in console
-- 
-- @module _printfix
-- @author John "Nielk1" Klein

local oldPrint = print;
print = function(...)
    for s in table.concat({...}, "\t"):gmatch("[^\r\n]+") do
        oldPrint(s);
    end
end