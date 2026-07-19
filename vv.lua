local RAW_URL = "https://raw.githubusercontent.com/MMoonlights/e/refs/heads/main/b.lua"
local OUTPUT_DIR = "luarmor_dump"
local MIN_DUMP_SIZE = 1

local env = (getgenv and getgenv()) or _G
local nativeLoadstring = rawget(env, "loadstring") or loadstring

assert(type(nativeLoadstring) == "function", "loadstring is unavailable")
assert(type(writefile) == "function", "writefile is unavailable")

if type(makefolder) == "function" then
    pcall(makefolder, OUTPUT_DIR)
end

local seen = {}
local dumpIndex = 0
local originalLoadstring = nativeLoadstring

local function pack(...)
    return { n = select("#", ...), ... }
end

local function unpackPacked(values, first)
    return table.unpack(values, first or 1, values.n)
end

local function checksum(data)
    local a = 1
    local b = 0

    for index = 1, #data do
        a = (a + string.byte(data, index)) % 65521
        b = (b + a) % 65521
    end

    return string.format("%08x", b * 65536 + a)
end

local function sanitize(value)
    value = tostring(value or "chunk")
    value = value:gsub("^@", "")
    value = value:gsub("[^%w%._%-]", "_")

    if value == "" then
        value = "chunk"
    end

    if #value > 64 then
        value = value:sub(1, 64)
    end

    return value
end

local function fileExists(path)
    if type(isfile) ~= "function" then
        return false
    end

    local ok, result = pcall(isfile, path)
    return ok and result == true
end

local function uniquePath(basePath, extension)
    local path = basePath .. extension
    local suffix = 1

    while fileExists(path) do
        path = string.format("%s_%d%s", basePath, suffix, extension)
        suffix = suffix + 1
    end

    return path
end

local function saveData(source, chunkName)
    if type(source) ~= "string" or #source < MIN_DUMP_SIZE then
        return nil
    end

    local id = checksum(source) .. "_" .. tostring(#source)
    if seen[id] then
        return nil
    end

    seen[id] = true
    dumpIndex = dumpIndex + 1

    local extension = source:sub(1, 4) == "\27Lua" and ".luac" or ".lua"
    local basePath = string.format(
        "%s/%03d_%s_%s",
        OUTPUT_DIR,
        dumpIndex,
        sanitize(chunkName),
        id
    )
    local path = uniquePath(basePath, extension)

    local ok, err = pcall(writefile, path, source)
    if ok then
        print(string.format("[dumper] saved %s (%d bytes)", path, #source))
        return path
    end

    warn("[dumper] failed to save " .. path .. ": " .. tostring(err))
    return nil
end

local function callOriginalLoadstring(source, chunkName)
    if chunkName ~= nil then
        local result = pack(pcall(originalLoadstring, source, chunkName))

        if result[1] then
            return unpackPacked(result, 2)
        end
    end

    return originalLoadstring(source)
end

local function hookedLoadstring(source, chunkName)
    saveData(source, chunkName or "loadstring_chunk")
    return callOriginalLoadstring(source, chunkName)
end

local hookInstalled = false

if type(hookfunction) == "function" then
    local ok, oldFunction = pcall(hookfunction, nativeLoadstring, hookedLoadstring)

    if ok and type(oldFunction) == "function" then
        originalLoadstring = oldFunction
        hookInstalled = true
        print("[dumper] hookfunction installed")
    else
        warn("[dumper] hookfunction failed; using global replacement")
    end
end

-- Also replace visible globals. This catches scripts that resolve loadstring
-- from getgenv() or _G after the hook is installed.
env.loadstring = hookedLoadstring
_G.loadstring = hookedLoadstring

local function httpGet(url)
    if game and type(game.HttpGet) == "function" then
        local ok, body = pcall(function()
            return game:HttpGet(url, true)
        end)

        if ok and type(body) == "string" and #body > 0 then
            return body
        end
    end

    local requestFunction =
        rawget(env, "request")
        or rawget(env, "http_request")
        or (syn and syn.request)

    if type(requestFunction) == "function" then
        local response = requestFunction({
            Url = url,
            Method = "GET",
            Headers = {
                ["Cache-Control"] = "no-cache",
                ["Pragma"] = "no-cache"
            }
        })

        if type(response) == "table" then
            local status = response.StatusCode or response.Status
            local body = response.Body

            if (status == nil or (status >= 200 and status < 300))
                and type(body) == "string"
                and #body > 0 then
                return body
            end

            error("HTTP request failed: " .. tostring(status))
        end
    end

    error("no working HTTP function is available")
end

local function copyCachedInitializer()
    local cachePath = "static_content_130525/init-74c74f95fd0-marbeg.lua"

    if type(readfile) ~= "function" then
        return
    end

    if type(isfile) == "function" then
        local ok, exists = pcall(isfile, cachePath)
        if not ok or not exists then
            return
        end
    end

    local ok, content = pcall(readfile, cachePath)
    if ok and type(content) == "string" and #content > 0 then
        pcall(writefile, OUTPUT_DIR .. "/cached_initializer.lua", content)
        saveData(content, "cached_initializer")
    end
end

copyCachedInitializer()

print("[dumper] downloading target")
local targetSource = httpGet(RAW_URL)

assert(
    targetSource:find("_bsdata0", 1, true),
    "downloaded data does not look like the expected Luarmor loader"
)

pcall(writefile, OUTPUT_DIR .. "/raw_target.lua", targetSource)
saveData(targetSource, "raw_target")

print(string.format("[dumper] downloaded %d bytes", #targetSource))
print("[dumper] compiling target")

local targetFunction, compileError = callOriginalLoadstring(
    targetSource,
    "@luarmor_raw_target.lua"
)

assert(type(targetFunction) == "function", tostring(compileError))

print("[dumper] running target")
local results = pack(pcall(targetFunction))

copyCachedInitializer()

if not results[1] then
    warn("[dumper] target error: " .. tostring(results[2]))
    error(results[2], 0)
end

print(string.format(
    "[dumper] finished; captured %d unique loadstring input(s)%s",
    dumpIndex,
    hookInstalled and " with hookfunction" or ""
))

return unpackPacked(results, 2)
