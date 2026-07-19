local TARGET_FILE = "full_dump.lua"
local OUTPUT_DIR = "luarmor_dump"
local MIN_DUMP_SIZE = 64

local env = (getgenv and getgenv()) or _G
local baseLoadstring = env.loadstring or loadstring

assert(type(baseLoadstring) == "function", "loadstring is unavailable")
assert(type(readfile) == "function", "readfile is unavailable")
assert(type(writefile) == "function", "writefile is unavailable")

if type(makefolder) == "function" then
    pcall(makefolder, OUTPUT_DIR)
end

local seen = {}
local dumpIndex = 0

local function checksum(data)
    local a, b = 1, 0

    for i = 1, #data do
        a = (a + string.byte(data, i)) % 65521
        b = (b + a) % 65521
    end

    return string.format("%08x", b * 65536 + a)
end

local function sanitize(value)
    value = tostring(value or "chunk")
    value = value:gsub("[^%w%._%-]", "_")

    if #value > 50 then
        value = value:sub(1, 50)
    end

    return value
end

local function saveCompiledData(source, chunkName)
    if type(source) ~= "string" or #source < MIN_DUMP_SIZE then
        return
    end

    local id = checksum(source) .. "_" .. tostring(#source)
    if seen[id] then
        return
    end

    seen[id] = true
    dumpIndex = dumpIndex + 1

    local extension = source:sub(1, 4) == "\27Lua" and ".luac" or ".lua"
    local filename = string.format(
        "%s/%03d_%s_%s%s",
        OUTPUT_DIR,
        dumpIndex,
        sanitize(chunkName),
        id,
        extension
    )

    local ok, err = pcall(writefile, filename, source)
    if ok then
        print(string.format("[dumper] saved %s (%d bytes)", filename, #source))
    else
        warn("[dumper] write failed: " .. tostring(err))
    end
end

local originalLoadstring

local function hookedLoadstring(source, chunkName)
    saveCompiledData(source, chunkName)
    return originalLoadstring(source, chunkName)
end

if type(hookfunction) == "function" then
    originalLoadstring = hookfunction(baseLoadstring, hookedLoadstring)
else
    originalLoadstring = baseLoadstring
    env.loadstring = hookedLoadstring

    if _G ~= env then
        _G.loadstring = hookedLoadstring
    end
end

local function copyCachedInitializer()
    local cachePath = "static_content_130525/init-74c74f95fd0-marbeg.lua"

    if type(isfile) == "function" and not isfile(cachePath) then
        return
    end

    local ok, content = pcall(readfile, cachePath)
    if ok and type(content) == "string" then
        pcall(writefile, OUTPUT_DIR .. "/cached_initializer.lua", content)
    end
end

copyCachedInitializer()

local okRead, targetSource = pcall(readfile, TARGET_FILE)
assert(okRead and type(targetSource) == "string", "cannot read " .. TARGET_FILE)

saveCompiledData(targetSource, "target_file_raw")

local repairedSource, repairCount = targetSource:gsub(
    "([\r\n])(%s*)_bsdata(%s*%-%-[^\r\n]*)",
    "%1%2%3",
    1
)

if repairCount > 0 then
    targetSource = repairedSource
    pcall(writefile, OUTPUT_DIR .. "/target_repaired.lua", targetSource)
    print("[dumper] removed broken standalone _bsdata token")
end

saveCompiledData(targetSource, "target_file")

local targetFunction, compileError = originalLoadstring(targetSource, "@" .. TARGET_FILE)
assert(targetFunction, compileError)

local results = table.pack(pcall(targetFunction))
copyCachedInitializer()

if not results[1] then
    error(results[2], 0)
end

return table.unpack(results, 2, results.n)
