local URL = "https://raw.githubusercontent.com/MMoonlights/e/refs/heads/main/Demz.lua"

local ok, source = pcall(function()
    return game:HttpGet(URL .. "?cb=" .. tostring(tick()))
end)

if not ok or type(source) ~= "string" or source == "" then
    warn("[BOOT] Download failed: " .. tostring(source))
    return
end

print("[BOOT] Demo bytes:", #source)

local chunk, compileError = loadstring(source)
if type(chunk) ~= "function" then
    warn("[BOOT] COMPILE FAIL Demo.lua:\n" .. tostring(compileError))
    return
end

local ran, runtimeError = xpcall(chunk, function(err)
    if debug and type(debug.traceback) == "function" then
        return debug.traceback(tostring(err), 2)
    end
    return tostring(err)
end)

if not ran then
    warn("[BOOT] RUNTIME FAIL:\n" .. tostring(runtimeError))
end
