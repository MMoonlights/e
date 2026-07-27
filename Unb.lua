if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Environment = type(getgenv) == "function" and getgenv() or _G

if Environment.__UnboxingBoxesStateLogger then
    warn("[BoxesStateLogger] Already running")
    return
end

Environment.__UnboxingBoxesStateLogger = true

local Boxes = require(
    ReplicatedStorage
        :WaitForChild("Modules")
        :WaitForChild("Remotes")
        :WaitForChild("Boxes")
)

local LogFile = "UnboxingBoxesStateLog.txt"
local Counter = 0

if type(writefile) == "function" then
    pcall(writefile, LogFile, "")
end

local function emit(message)
    Counter += 1

    local line = string.format(
        "[BoxesStateLogger:%04d] %s",
        Counter,
        tostring(message)
    )

    print(line)

    if type(appendfile) == "function" then
        pcall(appendfile, LogFile, line .. "\n")
    end
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

local function serialize(value, depth, seen)
    local valueType = typeof(value)

    if valueType == "buffer" then
        return string.format(
            "buffer(%d): %s",
            buffer.len(value),
            bufferToHex(value)
        )
    end

    if valueType == "Instance" then
        return value:GetFullName()
    end

    if valueType == "string" then
        return string.format("%q", value)
    end

    if valueType == "Vector3"
        or valueType == "Vector2"
        or valueType == "CFrame"
        or valueType == "Color3"
    then
        return tostring(value)
    end

    if valueType ~= "table" then
        return tostring(value)
    end

    if seen[value] then
        return "<cycle>"
    end

    if depth >= 8 then
        return "<max-depth>"
    end

    seen[value] = true

    local entries = {}
    local count = 0

    for key, item in pairs(value) do
        count += 1

        if count > 500 then
            table.insert(entries, "<truncated>")
            break
        end

        table.insert(
            entries,
            "["
                .. serialize(key, depth + 1, seen)
                .. "]="
                .. serialize(item, depth + 1, seen)
        )
    end

    seen[value] = nil

    return "{" .. table.concat(entries, ", ") .. "}"
end

local function argumentsToString(...)
    local arguments = table.pack(...)
    local entries = table.create(arguments.n)

    for index = 1, arguments.n do
        entries[index] = tostring(index)
            .. "="
            .. serialize(arguments[index], 0, {})
    end

    return table.concat(entries, " | ")
end

local function subscribe(label, event)
    if typeof(event) ~= "table"
        or typeof(event.On) ~= "function"
    then
        emit(label .. " unavailable")
        return
    end

    local ok, result = pcall(function()
        return event.On(function(...)
            emit(
                "EVENT "
                    .. label
                    .. " | "
                    .. argumentsToString(...)
            )
        end)
    end)

    if ok then
        emit("Subscribed " .. label)
    else
        emit(
            "Subscribe failed "
                .. label
                .. " | "
                .. tostring(result)
        )
    end
end

subscribe("FieldAdded", Boxes.FieldAdded)
subscribe("FieldRemoved", Boxes.FieldRemoved)
subscribe("FieldSync", Boxes.FieldSync)
subscribe("FieldBaseline", Boxes.FieldBaseline)
subscribe("FieldDelta", Boxes.FieldDelta)
subscribe("BoxFocusUpdate", Boxes.BoxFocusUpdate)
subscribe("AttackState", Boxes.AttackState)
subscribe("AttackZone", Boxes.AttackZone)
subscribe("AttackZoneHit", Boxes.AttackZoneHit)
subscribe("LocalPerkDamage", Boxes.LocalPerkDamage)

task.spawn(function()
    if typeof(Boxes.GetFieldList) ~= "table"
        or typeof(Boxes.GetFieldList.Call) ~= "function"
    then
        emit("GetFieldList.Call unavailable")
        return
    end

    emit("Calling GetFieldList.Call")

    local result = table.pack(
        pcall(Boxes.GetFieldList.Call)
    )

    if not result[1] then
        emit(
            "GetFieldList.Call failed | "
                .. tostring(result[2])
        )
        return
    end

    emit(
        "GetFieldList.Call returned | "
            .. argumentsToString(
                table.unpack(result, 2, result.n)
            )
    )
end)

emit("Ready")
emit("Wait five seconds, move near boxes, and manually hit one box")
emit("Send UnboxingBoxesStateLog.txt")
