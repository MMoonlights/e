local URLS = {
    Demo = "https://raw.githubusercontent.com/MMoonlights/e/refs/heads/main/Demz.lua",

    Library = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua",

    ThemeManager = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua",

    SaveManager = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua",
}

local requestFunction =
    (syn and syn.request)
    or (http and http.request)
    or http_request
    or request

local function tracebackHandler(err)
    if debug and type(debug.traceback) == "function" then
        return debug.traceback(tostring(err), 2)
    end

    return tostring(err)
end

local function fetchSource(name, url)
    local cacheBuster = tostring(os.clock()):gsub("%.", "")
    local finalUrl = url .. "?cb=" .. cacheBuster

    print(("[BOOT] Downloading %s..."):format(name))

    if type(requestFunction) == "function" then
        local ok, response = pcall(requestFunction, {
            Url = finalUrl,
            Method = "GET",
            Headers = {
                ["Cache-Control"] = "no-cache",
                ["Pragma"] = "no-cache",
            },
        })

        if not ok then
            warn(("[BOOT] HTTP FAIL %s:\n%s"):format(
                name,
                tostring(response)
            ))
            return nil
        end

        local body = response and (response.Body or response.body)
        local status = response and (
            response.StatusCode
            or response.Status
            or response.status_code
        )

        print(("[BOOT] %s HTTP=%s bytes=%s"):format(
            name,
            tostring(status),
            type(body) == "string" and tostring(#body) or "nil"
        ))

        if type(body) ~= "string" or body == "" then
            warn("[BOOT] Empty response: " .. name)
            return nil
        end

        if tonumber(status) and tonumber(status) >= 400 then
            warn(("[BOOT] Bad HTTP status for %s: %s"):format(
                name,
                tostring(status)
            ))
            return nil
        end

        return body
    end

    local ok, body = pcall(function()
        return game:HttpGet(finalUrl)
    end)

    if not ok then
        warn(("[BOOT] HttpGet FAIL %s:\n%s"):format(
            name,
            tostring(body)
        ))
        return nil
    end

    if type(body) ~= "string" or body == "" then
        warn("[BOOT] Empty response: " .. name)
        return nil
    end

    print(("[BOOT] %s bytes=%d"):format(name, #body))

    return body
end

local function compileSource(name, source)
    if type(loadstring) ~= "function" then
        warn("[BOOT] loadstring is unavailable")
        return nil
    end

    local compiled, compileError = loadstring(source)

    if type(compiled) ~= "function" then
        warn(("[BOOT] COMPILE FAIL %s:\n%s"):format(
            name,
            tostring(compileError)
        ))

        return nil
    end

    print("[BOOT] COMPILE OK: " .. name)

    return compiled
end

do
    local testChunk, testError = loadstring("return 123456")

    if type(testChunk) ~= "function" then
        warn("[BOOT] Executor compiler test failed: " .. tostring(testError))
        return
    end

    local ok, result = pcall(testChunk)

    if not ok or result ~= 123456 then
        warn("[BOOT] Executor compiler runtime test failed: " .. tostring(result))
        return
    end

    print("[BOOT] Executor compiler OK")
end

for _, moduleName in ipairs({
    "Library",
    "ThemeManager",
    "SaveManager",
}) do
    local moduleSource = fetchSource(moduleName, URLS[moduleName])

    if not moduleSource then
        return
    end

    local moduleChunk = compileSource(moduleName, moduleSource)

    if not moduleChunk then
        warn("[BOOT] UI dependency is incompatible with this executor: " .. moduleName)
        return
    end
end

local demoSource = fetchSource("Demo", URLS.Demo)

if not demoSource then
    return
end

local demoChunk = compileSource("Demo.lua", demoSource)

if not demoChunk then
    return
end

print("[BOOT] Starting Demo.lua...")

local executionOk, executionError = xpcall(
    demoChunk,
    tracebackHandler
)

if not executionOk then
    warn("[BOOT] RUNTIME FAIL:\n" .. tostring(executionError))
    return
end

print("[BOOT] Demo.lua finished initialization")
