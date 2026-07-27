if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Environment = type(getgenv) == "function" and getgenv() or _G

if Environment.__UnboxingBoxesApiLogger then
    warn("[BoxesApiLogger] Already running")
    return
end

Environment.__UnboxingBoxesApiLogger = true

local Boxes = require(
    ReplicatedStorage
        :WaitForChild("Modules")
        :WaitForChild("Remotes")
        :WaitForChild("Boxes")
)

local Remote = ReplicatedStorage
    :WaitForChild("ZAP")
    :WaitForChild("Boxes_RELIABLE")

local LogFile = "UnboxingBoxesApiLog.txt"
local Counter = 0

if type(writefile) == "function" then
    pcall(writefile, LogFile, "")
end

local function emit(message)
    Counter += 1

    local line = string.format(
        "[BoxesApiLogger:%04d] %s",
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

    if valueType ~= "table" then
        return tostring(value)
    end

    if seen[value] then
        return "<cycle>"
    end

    if depth >= 5 then
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

        table.insert(
            parts,
            "["
                .. serialize(key, depth + 1, seen)
                .. "]="
                .. serialize(item, depth + 1, seen)
        )
    end

    seen[value] = nil

    return "{" .. table.concat(parts, ", ") .. "}"
end

local function packArguments(...)
    local values = table.pack(...)
    local parts = table.create(values.n)

    for index = 1, values.n do
        parts[index] = tostring(index)
            .. "="
            .. serialize(values[index], 0, {})
    end

    return table.concat(parts, " | ")
end

local function inspectFunction(label, target)
    if typeof(target) ~= "function" then
        emit(label .. " is not a function")
        return
    end

    if type(getconstants) == "function" then
        local ok, constants = pcall(getconstants, target)

        if ok then
            emit(
                label
                    .. " constants="
                    .. serialize(constants, 0, {})
            )
        else
            emit(
                label
                    .. " constants error="
                    .. tostring(constants)
            )
        end
    end

    if type(getupvalues) == "function" then
        local ok, upvalues = pcall(getupvalues, target)

        if ok then
            emit(
                label
                    .. " upvalues="
                    .. serialize(upvalues, 0, {})
            )
        else
            emit(
                label
                    .. " upvalues error="
                    .. tostring(upvalues)
            )
        end
    end

    if type(getprotos) == "function" then
        local ok, protos = pcall(getprotos, target)

        if ok then
            emit(
                label
                    .. " protos="
                    .. serialize(protos, 0, {})
            )
        else
            emit(
                label
                    .. " protos error="
                    .. tostring(protos)
            )
        end
    end
end

local function hookApiFunction(label, container, key)
    if typeof(container) ~= "table" then
        emit(label .. " container is unavailable")
        return
    end

    local target = container[key]

    if typeof(target) ~= "function" then
        emit(label .. " is unavailable")
        return
    end

    inspectFunction(label, target)

    if type(hookfunction) == "function" then
        local original

        original = hookfunction(target, function(...)
            emit(
                "CALL "
                    .. label
                    .. " | "
                    .. packArguments(...)
            )

            local results = table.pack(original(...))

            emit(
                "RETURN "
                    .. label
                    .. " | "
                    .. packArguments(
                        table.unpack(results, 1, results.n)
                    )
            )

            return table.unpack(results, 1, results.n)
        end)

        emit("Hooked " .. label)
        return
    end

    container[key] = function(...)
        emit(
            "CALL "
                .. label
                .. " | "
                .. packArguments(...)
        )

        local results = table.pack(target(...))

        emit(
            "RETURN "
                .. label
                .. " | "
                .. packArguments(
                    table.unpack(results, 1, results.n)
                )
        )

        return table.unpack(results, 1, results.n)
    end

    emit("Wrapped " .. label)
end

hookApiFunction("Boxes.AttackBox.Fire", Boxes.AttackBox, "Fire")
hookApiFunction("Boxes.CLICK_COUNT.Fire", Boxes.CLICK_COUNT, "Fire")
hookApiFunction("Boxes.GetFieldList.Call", Boxes.GetFieldList, "Call")
hookApiFunction("Boxes.FieldSubscribe.Fire", Boxes.FieldSubscribe, "Fire")
hookApiFunction("Boxes.CancelBox.Fire", Boxes.CancelBox, "Fire")

if type(hookmetamethod) == "function"
    and type(getnamecallmethod) == "function"
then
    local previousNamecall

    previousNamecall = hookmetamethod(
        game,
        "__namecall",
        newcclosure(function(self, ...)
            if self == Remote
                and getnamecallmethod() == "FireServer"
            then
                emit(
                    "REMOTE Boxes_RELIABLE.FireServer | "
                        .. packArguments(...)
                )
            end

            return previousNamecall(self, ...)
        end)
    )

    emit("Hooked Boxes_RELIABLE.FireServer")
else
    emit("Remote hook is unavailable")
end

emit("Ready")
emit("Manually attack one box once")
emit("Send UnboxingBoxesApiLog.txt")
