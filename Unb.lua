if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local State = type(getgenv) == "function" and getgenv() or _G

if State.__UnboxingBoxesLogger then
    warn("[BoxesLogger] Already running")
    return
end

State.__UnboxingBoxesLogger = true

local ZAP = ReplicatedStorage:WaitForChild("ZAP")
local Remote = ZAP:WaitForChild("Boxes_RELIABLE")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Remotes = Modules:WaitForChild("Remotes")
local ModuleScript = Remotes:WaitForChild("Boxes")
local LogFile = "UnboxingBoxesLog.txt"
local Sequence = 0

local function stringify(value)
    local valueType = typeof(value)

    if valueType == "string" then
        return string.format("%q", value)
    end

    if valueType == "Instance" then
        return value:GetFullName()
    end

    return tostring(value)
end

local function emit(message)
    Sequence += 1

    local line = string.format(
        "[BoxesLogger:%04d] %s",
        Sequence,
        tostring(message)
    )

    print(line)

    if type(appendfile) == "function" then
        pcall(appendfile, LogFile, line .. "\n")
    end
end

if type(writefile) == "function" then
    pcall(writefile, LogFile, "")
end

local function bufferToHex(value)
    local length = buffer.len(value)
    local parts = table.create(length)

    for index = 0, length - 1 do
        parts[index + 1] = string.format(
            "%02X",
            buffer.readu8(value, index)
        )
    end

    return table.concat(parts, " ")
end

local function bufferToEscaped(value)
    local length = buffer.len(value)
    local parts = table.create(length)

    for index = 0, length - 1 do
        parts[index + 1] = string.format(
            "\\x%02X",
            buffer.readu8(value, index)
        )
    end

    return table.concat(parts)
end

local function describeBuffer(value)
    local length = buffer.len(value)
    local output = {
        "type=buffer",
        "length=" .. tostring(length),
        "hex=" .. bufferToHex(value),
        "escaped=" .. bufferToEscaped(value)
    }

    if length >= 1 then
        table.insert(
            output,
            "u8@0=" .. tostring(buffer.readu8(value, 0))
        )
    end

    if length >= 2 then
        table.insert(
            output,
            "u16@0=" .. tostring(buffer.readu16(value, 0))
        )
    end

    if length >= 4 then
        table.insert(
            output,
            "u32@0=" .. tostring(buffer.readu32(value, 0))
        )
    end

    if length >= 5 then
        table.insert(
            output,
            "u32@1=" .. tostring(buffer.readu32(value, 1))
        )
    end

    return table.concat(output, " | ")
end

local function describeTable(value, depth, seen)
    if seen[value] then
        return "<cycle>"
    end

    if depth >= 4 then
        return "<max-depth>"
    end

    seen[value] = true

    local parts = {}
    local count = 0

    for key, item in pairs(value) do
        count += 1

        if count > 100 then
            table.insert(parts, "<truncated>")
            break
        end

        local itemType = typeof(item)
        local itemText

        if itemType == "buffer" then
            itemText = describeBuffer(item)
        elseif itemType == "table" then
            itemText = describeTable(item, depth + 1, seen)
        else
            itemText = stringify(item)
        end

        table.insert(
            parts,
            tostring(key) .. "=" .. itemText
        )
    end

    seen[value] = nil

    return "{" .. table.concat(parts, ", ") .. "}"
end

local function describe(value)
    local valueType = typeof(value)

    if valueType == "buffer" then
        return describeBuffer(value)
    end

    if valueType == "table" then
        return describeTable(value, 0, {})
    end

    return "type=" .. valueType .. " | value=" .. stringify(value)
end

local function inspectModule(value, path, depth, seen)
    if depth > 5 then
        return
    end

    if typeof(value) ~= "table" then
        emit(path .. " = " .. describe(value))
        return
    end

    if seen[value] then
        emit(path .. " = <cycle>")
        return
    end

    seen[value] = true

    local entries = {}

    for key, item in pairs(value) do
        table.insert(entries, {
            Key = key,
            Value = item
        })
    end

    table.sort(entries, function(left, right)
        return tostring(left.Key) < tostring(right.Key)
    end)

    for _, entry in ipairs(entries) do
        local childPath = path .. "." .. tostring(entry.Key)
        local itemType = typeof(entry.Value)

        if itemType == "table" then
            emit(childPath .. " = table")
            inspectModule(
                entry.Value,
                childPath,
                depth + 1,
                seen
            )
        elseif itemType == "function" then
            local source = "unknown"
            local name = "unknown"
            local line = "unknown"

            if debug and type(debug.info) == "function" then
                local sourceOk, sourceValue = pcall(
                    debug.info,
                    entry.Value,
                    "s"
                )

                local nameOk, nameValue = pcall(
                    debug.info,
                    entry.Value,
                    "n"
                )

                local lineOk, lineValue = pcall(
                    debug.info,
                    entry.Value,
                    "l"
                )

                if sourceOk then
                    source = tostring(sourceValue)
                end

                if nameOk then
                    name = tostring(nameValue)
                end

                if lineOk then
                    line = tostring(lineValue)
                end
            end

            emit(
                childPath
                    .. " = function"
                    .. " | name=" .. name
                    .. " | source=" .. source
                    .. " | line=" .. line
            )
        else
            emit(childPath .. " = " .. describe(entry.Value))
        end
    end

    seen[value] = nil
end

local moduleOk, moduleValue = pcall(require, ModuleScript)

if moduleOk then
    emit("Module loaded")
    emit("Module result: " .. describe(moduleValue))
    inspectModule(moduleValue, "Boxes", 0, {})
else
    emit("Module load failed: " .. tostring(moduleValue))
end

if type(hookmetamethod) ~= "function" then
    emit("hookmetamethod is unavailable")
    return
end

if type(getnamecallmethod) ~= "function" then
    emit("getnamecallmethod is unavailable")
    return
end

local previousNamecall

previousNamecall = hookmetamethod(
    game,
    "__namecall",
    newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if self == Remote and method == "FireServer" then
            local arguments = table.pack(...)

            emit(
                "OUT FireServer"
                    .. " | arguments=" .. tostring(arguments.n)
            )

            for index = 1, arguments.n do
                emit(
                    "OUT argument "
                        .. tostring(index)
                        .. " | "
                        .. describe(arguments[index])
                )
            end
        end

        return previousNamecall(self, ...)
    end)
)

Remote.OnClientEvent:Connect(function(...)
    local arguments = table.pack(...)

    emit(
        "IN OnClientEvent"
            .. " | arguments=" .. tostring(arguments.n)
    )

    for index = 1, arguments.n do
        emit(
            "IN argument "
                .. tostring(index)
                .. " | "
                .. describe(arguments[index])
        )
    end
end)

emit("Ready")
emit("Manually attack one box now")
emit("Log file: " .. LogFile)
