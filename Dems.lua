if getgenv then
    if type(getgenv().vLnware_DEMO_Unload) == "function" then
        pcall(getgenv().vLnware_DEMO_Unload)
        getgenv().vLnware_DEMO_Unload = nil
    end
    pcall(function()
        local value_1086
        local value_1087
        value_1086 = {
            game:GetService("CoreGui"),
        }
        if gethui then
            table.insert(value_1086, gethui())
        end
        value_1087 = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if value_1087 then
            table.insert(value_1086, value_1087)
        end
        for index_1337, item_1338 in ipairs(value_1086) do
            for index_1411, item_1412 in ipairs(item_1338:GetChildren()) do
                if item_1412:IsA("ScreenGui") and (item_1412.Name:sub(1, 4) == "vLn_") then
                    item_1412:Destroy()
                end
            end
        end
    end)
    getgenv().vLnware_DEMO = true
end
local BUILD_NAME = "Demonology v5.9"
local DISABLE_TELEPORT_QUEUE = false
local DISCORD_INVITE = "https://discord.gg/s3wc8JPzc7"
local FEATURES = {
    "Auto-detect evidence + Ghost ESP",
    "Hunt alert, haunt warning & auto-escape",
    "Auto Spirit Box, lights & fuse",
}
local CHANGELOG = {
    {
        v = "v5.9",
        ["notes"] = {
            "More accurate ghost detection (Specter fixed)",
            "Steadier type tells — fewer false reads from lag",
            "Fixed: Auto fuse box now powers ON (not just opens it)",
        },
    },
}

local scriptKey = script_key or (getgenv and getgenv().script_key)
if (type(scriptKey) ~= "string") or (scriptKey == "") then
    scriptKey = nil
end
if scriptKey and getgenv then
    getgenv().script_key = scriptKey
end
if scriptKey then
    pcall(function()
        if type(writefile) == "function" then
            if (type(makefolder) == "function") and (type(isfolder) == "function") and not isfolder("vilanxware") then
                makefolder("vilanxware")
            end
            writefile("vilanxware/key.txt", scriptKey)
        end
    end)
end

local OBSIDIAN_BASE_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local CACHE_FOLDER = "vLnware/cache"
local function hasFileApi()
    return (type(writefile) == "function") and (type(readfile) == "function") and (type(isfile) == "function")
end
local function cacheFilename(relativePath)
    return CACHE_FOLDER .. "/" .. (relativePath:gsub("[/\\]", "_"))
end
local function executeSource(sourceCode)
    if (type(sourceCode) ~= "string") or (sourceCode == "") then
        return nil
    end
    local compiledChunk = loadstring(sourceCode)
    if type(compiledChunk) ~= "function" then
        return nil
    end
    local executionSucceeded, moduleResult = pcall(compiledChunk)
    return (executionSucceeded and moduleResult) or nil
end
local function loadUiModule(modulePath)
    local cachePath
    local downloadedSource
    cachePath = cacheFilename(modulePath)
    if hasFileApi() then
        local cachedSource
        pcall(function()
            if isfile(cachePath) then
                cachedSource = readfile(cachePath)
            end
        end)
        if cachedSource and (cachedSource ~= "") then
            local value_1006
            value_1006 = executeSource(cachedSource)
            if value_1006 ~= nil then
                return value_1006
            end
            pcall(function()
                if type(delfile) == "function" then
                    delfile(cachePath)
                end
            end)
        end
    end
    downloadedSource = nil
    pcall(function()
        downloadedSource = game:HttpGet(OBSIDIAN_BASE_URL .. modulePath)
    end)
    if (type(downloadedSource) ~= "string") or (downloadedSource == "") then
        return nil
    end
    if hasFileApi() then
        pcall(function()
            if type(makefolder) == "function" then
                local folderApiAvailable
                folderApiAvailable = type(isfolder) == "function"
                if not (folderApiAvailable and isfolder("vLnware")) then
                    pcall(makefolder, "vLnware")
                end
                if not (folderApiAvailable and isfolder(CACHE_FOLDER)) then
                    pcall(makefolder, CACHE_FOLDER)
                end
            end
            writefile(cachePath, downloadedSource)
        end)
    end
    return executeSource(downloadedSource)
end
local function clearUiCache()
    if not hasFileApi() then
        return 
    end
    for moduleIndex, moduleFilename in ipairs({
        "Library.lua",
        "addons/ThemeManager.lua",
        "addons/SaveManager.lua",
    }) do
        pcall(function()
            local cachedModulePath
            cachedModulePath = cacheFilename(moduleFilename)
            if (type(delfile) == "function") and isfile(cachedModulePath) then
                delfile(cachedModulePath)
            end
        end)
    end
end
local Library = loadUiModule("Library.lua")
local ThemeManager = loadUiModule("addons/ThemeManager.lua")
local SaveManager = loadUiModule("addons/SaveManager.lua")
if not Library then
    warn("[vLnware] Failed to load the Obsidian UI library.")
    if getgenv then
        getgenv().vLnware_DEMO = nil
    end
    return 
end
if getgenv then
    getgenv().vLnware_DEMO_Unload = function()
        pcall(function()
            Library:Unload()
        end)
        getgenv().vLnware_DEMO = nil
    end
end
local main
local function clearLoadedFlag()
    if getgenv then
        getgenv().vLnware_DEMO = nil
    end
end
local function runMainSafely()
    local mainSucceeded
    local mainError
    mainSucceeded, mainError = pcall(main)
    if not mainSucceeded then
        warn("[vLnware] suite failed to load: " .. tostring(mainError))
        pcall(function()
            Library:Notify({
                ["Title"] = "vLnware",
                ["Description"] = "Load error: " .. tostring(mainError),
                ["Time"] = 8,
            })
        end)
        clearLoadedFlag()
    end
end
function main()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local CollectionService = game:GetService("CollectionService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local HUB_NAME = "vilanxware"
    local running = true
    local remoteCallLog = {
    }
    local function safeRequire(moduleScript)
        if not moduleScript then
            return nil
        end
        local requireSucceeded, requiredValue = pcall(require, moduleScript)
        return (requireSucceeded and requiredValue) or nil
    end
    local Modules = ReplicatedStorage:FindFirstChild("Modules")
    local EquipmentInfo = safeRequire(Modules and Modules:FindFirstChild("EquipmentInfo"))
    local JobSiteInfo = safeRequire(Modules and Modules:FindFirstChild("JobSiteInfo")) or {
    }
    local Events = ReplicatedStorage:FindFirstChild("Events")
    local EVIDENCE_NAMES = {
        "EMF Level 5",
        "Spirit Box",
        "Inscription",
        "Freezing Temperatures",
        "Ghost Orb",
        "Prints",
        "Laser Projector",
        "Wither",
    }
    local function buildGhostEvidenceMap()
        local ghostTypesFolder
        local evidenceNameById
        local ghostEvidenceMap
        local mappedGhostCount
        ghostTypesFolder = Modules and Modules:FindFirstChild("GhostTypes")
        if not ghostTypesFolder then
            return nil
        end
        evidenceNameById = {
            [1] = "EMF Level 5",
            [2] = "Spirit Box",
            [3] = "Inscription",
            [4] = "Freezing Temperatures",
            [5] = "Ghost Orb",
            [6] = "Prints",
            [7] = "Laser Projector",
            [8] = "Wither",
        }
        ghostEvidenceMap, mappedGhostCount = {
        }, 0
        for index_778, item_779 in ipairs(ghostTypesFolder:GetChildren()) do
            if item_779:IsA("ModuleScript") then
                local value_1008
                local value_1009
                value_1008, value_1009 = pcall(require, item_779)
                if value_1008 and (type(value_1009) == "table") and (type(value_1009.Evidence) == "table") then
                    local value_1340
                    value_1340 = {
                    }
                    for index_1523, item_1524 in ipairs(value_1009.Evidence) do
                        local indexed_value_1525 = evidenceNameById[item_1524]
                        if indexed_value_1525 then
                            value_1340[#value_1340 + 1] = indexed_value_1525
                        end
                    end
                    if #value_1340 > 0 then
                        ghostEvidenceMap[tostring(value_1009.Name or item_779.Name)] = table.concat(value_1340, ", ")
                        mappedGhostCount = mappedGhostCount + 1
                    end
                end
            end
        end
        return ((mappedGhostCount > 0) and ghostEvidenceMap) or nil
    end
    local GhostEvidence = buildGhostEvidenceMap() or {
        ["Aswang"] = "Wither, EMF Level 5, Inscription",
        ["Banshee"] = "Ghost Orb, Prints, Freezing Temperatures",
        ["Demon"] = "EMF Level 5, Prints, Freezing Temperatures",
        ["Dybbuk"] = "Wither, Freezing Temperatures, Prints",
        ["Entity"] = "Spirit Box, Prints, Laser Projector",
        ["Ghoul"] = "Spirit Box, Freezing Temperatures, Ghost Orb",
        ["Leviathan"] = "Inscription, Ghost Orb, Prints",
        ["Nightmare"] = "EMF Level 5, Spirit Box, Ghost Orb",
        ["Oni"] = "Laser Projector, Freezing Temperatures, Spirit Box",
        ["Phantom"] = "EMF Level 5, Prints, Ghost Orb",
        ["Revenant"] = "Inscription, Freezing Temperatures, EMF Level 5",
        ["Shadow"] = "EMF Level 5, Inscription, Laser Projector",
        ["Skinwalker"] = "Inscription, Spirit Box, Freezing Temperatures",
        ["Specter"] = "EMF Level 5, Freezing Temperatures, Laser Projector",
        ["Siren"] = "Wither, Spirit Box, EMF Level 5",
        ["Spirit"] = "Prints, Inscription, Spirit Box",
        ["Umbra"] = "Ghost Orb, Prints, Laser Projector",
        ["Wendigo"] = "Inscription, Ghost Orb, Laser Projector",
        ["Wisp"] = "Wither, Laser Projector, Ghost Orb",
        ["Wraith"] = "EMF Level 5, Spirit Box, Laser Projector",
        ["Dullahan"] = "Wither, Freezing Temperatures, Laser Projector",
        ["Vex"] = "Wither, Freezing Temperatures, Ghost Orb",
        ["Keres"] = "Wither, Spirit Box, Prints",
        ["Ravager"] = "EMF Level 5, Inscription, Spirit Box",
        ["Vesper"] = "Wither, Inscription, Prints",
    }
    local GhostCount = 0
    for ghostName_145 in pairs(GhostEvidence) do
        GhostCount = GhostCount + 1
    end
    local GHOST_TRAITS = {
        ["Aswang"] = "Speeds up with EACH kill; salt slows it. Evidence: Wither + Ghost Writing.",
        ["Banshee"] = "Breaks MULTIPLE windows/mirrors at once; unique wail at hunt start; often female.",
        ["Demon"] = "Very frequent hunts (low cooldown, chains even at high energy); crosses burn/float visibly.",
        ["Dullahan"] = "Headless in PHOTOS; speeds up with prolonged line-of-sight.",
        ["Dybbuk"] = "Stunned by the first Music Box play; can throw corpses.",
        ["Entity"] = "Teleports between rooms (smoke effect); throws items rarely.",
        ["Ghoul"] = "Hunts from excessive chat/Spirit Box; CANNOT disable electronics (flashlight stays on in a hunt).",
        ["Keres"] = "Speed DECREASES with kills; targets the lowest-energy player (or you if solo under ~90%).",
        ["Leviathan"] = "Passively turns lights OFF; throws multiple objects.",
        ["Nightmare"] = "Auditory hallucinations; afraid of LIT rooms (less active in light).",
        ["Oni"] = "Extremely fast in hunts; very active/frequent manifestations; more visible on Laser.",
        ["Phantom"] = "Slower blink in hunts; moves faster while invisible; lower hunt chance in groups.",
        ["Ravager"] = "Throws MANY objects at once + chain reactions; ~1/3 hunt vortex; EVERY interaction gives EMF 5.",
        ["Revenant"] = "Low hunt cooldown; STOPS hunting right after a kill.",
        ["Shadow"] = "Small temp drops; less active in light; speed varies with light.",
        ["Siren"] = "Female voice/model; slows players in line-of-sight; '-HUMMING-' on Spirit Box.",
        ["Skinwalker"] = "Fakes Ghost Orbs; mimics other ghosts' abilities — don't trust orbs alone.",
        ["Specter"] = "Frequent throws; stays mostly in the ghost room (limited roaming).",
        ["Spirit"] = "Turns lit candles BLUE; otherwise standard, no major strengths.",
        ["Umbra"] = "NO footstep sounds; slower in lit rooms, faster in dark (like Shadow).",
        ["Vesper"] = "Blind — hunts purely by SOUND, tracks through walls; stand still/crouch to be immune.",
        ["Vex"] = "Invisible on LIDAR; walks through walls — closets/looping are risky.",
        ["Wendigo"] = "Hunts more near groups/low flames; speeds up as energy drops.",
        ["Wisp"] = "Walks through holy oil/fire; hunts only when you're in the ghost room; can light candles.",
        ["Wraith"] = "Rapid energy drain (~0.2-0.4%/s); AVOIDS salt (no salt prints).",
    }
    local GHOST_TIPS = {
        ["Aswang"] = "Drop salt to slow it; gather evidence fast (deadlier per kill).",
        ["Banshee"] = "Listen for the wail as an early hunt warning.",
        ["Demon"] = "Use crosses defensively; prioritise evidence + escape fast.",
        ["Dullahan"] = "Photo Camera to spot the headless figure; break line-of-sight in hunts.",
        ["Dybbuk"] = "Use the Music Box to stun and buy time.",
        ["Entity"] = "Stay mobile — teleports make looping risky.",
        ["Ghoul"] = "If electronics keep working in a hunt, it's a Ghoul; limit chat/Spirit Box.",
        ["Keres"] = "Keep your energy high to avoid being targeted; survive early hunts.",
        ["Leviathan"] = "Keep lights ON where you can.",
        ["Nightmare"] = "Keep rooms LIT to deter it; trust evidence over hallucinations.",
        ["Oni"] = "Don't loop (it excels at it); use the Laser Projector.",
        ["Phantom"] = "Watch blink rate; group up to lower hunt chance.",
        ["Ravager"] = "Watch for the vortex + EMF 5 on every interaction; stay mobile.",
        ["Revenant"] = "If a hunt ends right after a death, it's a Revenant — avoid early deaths.",
        ["Shadow"] = "Use lighting to slow it.",
        ["Siren"] = "Listen for humming on the Spirit Box; break LOS to avoid slowing.",
        ["Skinwalker"] = "Cross-reference behaviours; test with Spirit Box questions.",
        ["Specter"] = "Investigate one room — it barely roams.",
        ["Spirit"] = "Easy one — classic tactics work.",
        ["Umbra"] = "Use lights to slow it; listen for absent footsteps.",
        ["Vesper"] = "Stand still / crouch / stay silent during hunts to be immune.",
        ["Vex"] = "LIDAR is unreliable; use closets carefully (it phases walls).",
        ["Wendigo"] = "Manage group energy; use candles/lanterns to deter; don't cluster.",
        ["Wisp"] = "Restrict it to its favourite room; fire lines work poorly.",
        ["Wraith"] = "Salt is a great detector/counter; manage your energy.",
    }
    local EQUIPMENT_ALIASES = {
        ["Blacklight"] = {
            "UV Wand",
            "Blacklight Gun",
            "BIG BLACKLIGHT",
            "PCB EMF variant",
        },
        ["EMF Reader"] = {
            "PCB EMF",
            "Tactical EMF",
            "Green Phone",
            "Festive EMF",
            "Halloween",
        },
        ["Flashlight"] = {
            "BIG FLASHLIGHT",
            "Candy Cane Flashlight",
            "Pocket Flashlight",
        },
        ["Flower Pot"] = {
            "Flower Vase",
            "Antique Flower Pot",
        },
        ["Laser Projector"] = {
            "Disco Ball",
            "Compact Projector",
        },
        ["Spirit Book"] = {
            "Easel",
            "Weathered Book",
            "Santas List",
        },
        ["Spirit Box"] = {
            "Black Phone",
            "Vintage Spirit Box",
            "Festive Spirit Box",
        },
        ["Thermometer"] = {
            "Digital Thermometer",
            "House Thermometer",
        },
        ["Video Camera"] = {
            "Vintage Camera",
            "Hollywood Camera",
            "Field Camera",
        },
        ["Cross"] = {
            "Golden Cross",
            "Celtic Cross",
        },
        ["Energy Drink"] = {
            "Coffee",
            "Hot Cocoa",
        },
        ["Energy Watch"] = {
            "Money Watch",
            "Biter Watch",
        },
        ["Head Mounted Camera"] = {
            "Spy Glasses",
            "Balloon Crown",
        },
        ["Holy Oil"] = {
            "Divine Elixir",
            "Sanctified Elixir",
            "Ancient Holy Oil",
        },
        ["Lantern"] = {
            "Lava Lamp",
            "Christmas Lantern",
            "Jack o Lantern",
        },
        ["Lighter"] = {
            "Metal Lighter",
        },
        ["Photo Camera"] = {
            "Field Camera",
            "Printer Camera",
        },
        ["Salt Canister"] = {
            "Grandpa's Ashes",
            "Salt Shaker",
            "Salt Grinder",
            "Witches' Salt",
        },
        ["Plushie"] = {
            "Biter Plushie",
            "Ratched Plushie",
        },
        ["Defibrillator"] = {
            "SciFi Defib",
        },
        ["Rock Salt Shotgun"] = {
            "Finger Gun",
            "Big Iron",
        },
    }
    local CURSED_ITEMS = {
        "Ouija Board",
        "Umbra Board",
        "Haunted Mirror",
        "Music Box",
        "Summoning Circle",
        "Fortune Teller",
        "Magnifying Glass",
    }
    local AliasToEquipment = {
    }
    for equipmentName, equipmentAliases in pairs(EQUIPMENT_ALIASES) do
        for index_407, item_408 in ipairs(equipmentAliases) do
            AliasToEquipment[item_408:lower()] = equipmentName
        end
    end
    local CursedItemLookup = {
    }
    for cursedItemIndex, cursedItemName in ipairs(CURSED_ITEMS) do
        CursedItemLookup[cursedItemName:lower()] = true
    end
    local function classifyItemName(itemName)
        if not itemName then
            return nil
        end
        local lowerItemName = tostring(itemName):lower()
        if CursedItemLookup[lowerItemName] then
            return itemName, "cursed"
        end
        if (type(EquipmentInfo) == "table") and EquipmentInfo[itemName] then
            return itemName, "equipment"
        end
        local canonicalItemName = AliasToEquipment[lowerItemName]
        if canonicalItemName then
            return canonicalItemName, "equipment"
        end
        return nil
    end
    local function notify(message_154, duration_155)
        pcall(function()
            Library:Notify({
                ["Title"] = HUB_NAME,
                ["Description"] = tostring(message_154),
                ["Time"] = duration_155 or 3,
            })
        end)
    end
    local function toggleEnabled(toggleId_156)
        local toggleControl
        toggleControl = Library.Toggles[toggleId_156]
        return toggleControl and (toggleControl.Value == true)
    end
    local function optionValue(optionId_159)
        local optionControl_161
        optionControl_161 = Library.Options[optionId_159]
        return optionControl_161 and optionControl_161.Value
    end
    local function numericOption(optionId_162, fallbackValue_163)
        local optionControl_164 = Library.Options[optionId_162]
        return (optionControl_164 and tonumber(optionControl_164.Value)) or fallbackValue_163
    end
    local function optionDefault(optionId_165, fallbackValue_166)
        local optionControl_167 = Library.Options[optionId_165]
        return (optionControl_167 and optionControl_167.Value) or fallbackValue_166
    end
    local function tableOption(optionId_168)
        local optionValueResult
        optionValueResult = optionValue(optionId_168)
        return ((type(optionValueResult) == "table") and optionValueResult) or {
        }
    end
    local function getCharacter()
        return LocalPlayer.Character
    end
    local function getHumanoid()
        local character_172
        character_172 = getCharacter()
        return character_172 and character_172:FindFirstChildOfClass("Humanoid")
    end
    local function getRootPart()
        local character_174
        character_174 = getCharacter()
        return character_174 and character_174:FindFirstChild("HumanoidRootPart")
    end
    local MIN_LOOP_DELAY = 0.05
    local function startToggleLoop(toggleId_175, delayOrProvider, loopCallback)
        local usesDelayProvider
        usesDelayProvider = type(delayOrProvider) == "function"
        task.spawn(function()
            while running do
                local indexed_value_892 = Library.Toggles[toggleId_175]
                if indexed_value_892 and indexed_value_892.Value then
                    local value_1091
                    value_1091 = (usesDelayProvider and (tonumber(select(2, pcall(delayOrProvider))) or MIN_LOOP_DELAY)) or delayOrProvider
                    task.wait(math.max(tonumber(value_1091) or MIN_LOOP_DELAY, MIN_LOOP_DELAY))
                    if running and indexed_value_892.Value then
                        local value_1414
                        local value_1415
                        value_1414, value_1415 = pcall(loopCallback)
                        if not value_1414 then
                            warn("[vLnware] loop '" .. toggleId_175 .. "': " .. tostring(value_1415))
                        end
                    end
                else
                    task.wait(0.5)
                end
            end
        end)
    end
    local function fireEvent(eventName, ...)
        local remoteEvent
        local eventArguments
        remoteEvent = nil
        eventArguments = nil
        if not Events then
            return false
        end
        remoteEvent = Events:FindFirstChild(eventName)
        if not remoteEvent then
            return false
        end
        eventArguments = {
            ...,
        }
        return (pcall(function()
            if remoteEvent:IsA("RemoteEvent") then
                remoteEvent:FireServer(table.unpack(eventArguments))
            else
                remoteEvent:Fire(table.unpack(eventArguments))
            end
        end))
    end
    local function findMap()
        local mapModel_185 = workspace:FindFirstChild("Map")
        if mapModel_185 then
            return mapModel_185
        end
        for index_410, item_411 in ipairs(workspace:GetChildren()) do
            if (item_411:IsA("Model") or item_411:IsA("Folder")) and item_411:FindFirstChild("Rooms") then
                return item_411
            end
        end
        return nil
    end
    local function getJobSiteInfo(mapModel_186)
        local jobSiteName
        if not mapModel_186 then
            return nil
        end
        for key_780, value_781 in pairs(JobSiteInfo) do
            if (mapModel_186.Name == key_780) or (mapModel_186:GetAttribute("JobSite") == key_780) or mapModel_186:FindFirstChild(key_780) then
                return key_780, value_781
            end
        end
        jobSiteName = mapModel_186:GetAttribute("JobSite") or mapModel_186:GetAttribute("Site")
        if jobSiteName and JobSiteInfo[jobSiteName] then
            return jobSiteName, JobSiteInfo[jobSiteName]
        end
        return nil
    end
    local GhostNameLookup = {
    }
    for ghostName_189 in pairs(GhostEvidence) do
        GhostNameLookup[ghostName_189:lower()] = true
    end
    local cachedGhost, cachedGhostAt = nil, 0
    local function findGhost()
        local directGhostModel = workspace:FindFirstChild("Ghost")
        if directGhostModel and directGhostModel:IsA("Model") and directGhostModel:FindFirstChildOfClass("Humanoid") then
            return directGhostModel
        end
        local now = tick()
        if ((now - cachedGhostAt) < 0.5) and (not cachedGhost or cachedGhost.Parent) then
            return cachedGhost
        end
        cachedGhostAt = now
        local currentCamera = workspace.CurrentCamera
        local mapModel_194 = workspace:FindFirstChild("Map")
        local foundGhostModel
        for index_412, item_413 in ipairs(workspace:GetDescendants()) do
            if item_413:IsA("Humanoid") then
                local parent_661 = item_413.Parent
                if parent_661 and parent_661:IsA("Model") and not Players:GetPlayerFromCharacter(parent_661) and (parent_661.Name ~= "Viewmodel") and not (currentCamera and parent_661:IsDescendantOf(currentCamera)) and not (mapModel_194 and parent_661:IsDescendantOf(mapModel_194)) then
                    if (parent_661:GetAttribute("IsGhost") == true) or GhostNameLookup[parent_661.Name:lower()] or parent_661.Name:lower():find("ghost") then
                        foundGhostModel = parent_661
                        break
                    end
                end
            end
        end
        cachedGhost = foundGhostModel
        return cachedGhost
    end
    local function ghostFlagActive()
        local ghostContainer_197
        ghostContainer_197 = workspace:FindFirstChild("Ghost")
        return ghostContainer_197 and (ghostContainer_197:GetAttribute("IsGhost") == true)
    end
    local ITEM_TAG_NAMES = {
        ["Flashlight"] = "Flashlight",
        ["EMFReader"] = "EMF Reader",
        ["VideoCamera"] = "Video Camera",
        ["Blacklight"] = "Blacklight",
        ["LaserProjector"] = "Laser Projector",
        ["Thermometer"] = "Thermometer",
        ["SpiritBox"] = "Spirit Box",
        ["Lighter"] = "Lighter",
        ["FlowerPot"] = "Flower Pot",
        ["MagnifyingGlass"] = "Magnifying Glass",
        ["FortuneTeller"] = "Fortune Teller",
        ["Mirror"] = "Haunted Mirror",
    }
    local KnownItemNames = {
    }
    local registerKnownItemName
    registerKnownItemName = nil
    function registerKnownItemName(arg_790)
        if (type(arg_790) == "string") and (arg_790 ~= "") then
            KnownItemNames[arg_790:lower()] = arg_790
        end
    end
    if type(EquipmentInfo) == "table" then
        for key_1010 in pairs(EquipmentInfo) do
            registerKnownItemName(key_1010)
        end
    end
    for key_788, value_789 in pairs(EQUIPMENT_ALIASES) do
        registerKnownItemName(key_788)
        for index_893, item_894 in ipairs(value_789) do
            KnownItemNames[item_894:lower()] = AliasToEquipment[item_894:lower()] or key_788
        end
    end
    for index_782, item_783 in ipairs(CURSED_ITEMS) do
        registerKnownItemName(item_783)
    end
    for key_784, value_785 in pairs(ITEM_TAG_NAMES) do
        registerKnownItemName(value_785)
    end
    for index_786, item_787 in ipairs({
        "Fortune Coin",
        "Fortune Ticket",
        "Spirit Book",
        "Salt Canister",
    }) do
        registerKnownItemName(item_787)
    end
    local function identifyItem(instance_200)
        local explicitItemName
        local canonicalName
        local itemCategory
        local knownItemName
        explicitItemName = instance_200:GetAttribute("ItemName")
        if (type(explicitItemName) == "string") and (explicitItemName ~= "") then
            local value_897
            local value_898
            value_897, value_898 = classifyItemName(explicitItemName)
            return value_897 or explicitItemName, value_898 or (CursedItemLookup[explicitItemName:lower()] and "cursed") or "equipment"
        end
        canonicalName, itemCategory = classifyItemName(instance_200.Name)
        if canonicalName then
            return canonicalName, itemCategory
        end
        for key_791, value_792 in pairs(ITEM_TAG_NAMES) do
            if CollectionService:HasTag(instance_200, key_791) then
                return value_792, (CursedItemLookup[value_792:lower()] and "cursed") or "equipment"
            end
        end
        knownItemName = KnownItemNames[instance_200.Name:lower()]
        if knownItemName then
            return knownItemName, (CursedItemLookup[knownItemName:lower()] and "cursed") or "equipment"
        end
        return nil
    end
    local cachedItems, cachedItemsAt = nil, 0
    local function scanItems()
        local foundItems
        local seenInstances
        local addScannedItem
        local itemSearchRoots
        local mapModel_211
        if cachedItems and ((tick() - cachedItemsAt) < 0.3) then
            return cachedItems
        end
        foundItems, seenInstances = {
        }, {
        }
        addScannedItem = nil
        function addScannedItem(arg_793, arg_794)
            local value_796
            local value_797
            if seenInstances[arg_793] or not arg_793:IsDescendantOf(workspace) then
                return 
            end
            value_796, value_797 = identifyItem(arg_793)
            if value_796 then
                seenInstances[arg_793] = true
                foundItems[#foundItems + 1] = {
                    ["inst"] = arg_793,
                    ["name"] = value_796,
                    ["cat"] = arg_794 or value_797 or "equipment",
                    ["uses"] = arg_793:GetAttribute("Uses"),
                    ["maxUses"] = arg_793:GetAttribute("MaxUses"),
                }
            end
        end
        for index_798, item_799 in ipairs({
            "Item",
            "CursedPossession",
        }) do
            local value_802
            local value_803
            value_802 = nil
            value_803 = nil
            value_802, value_803 = pcall(function()
                return CollectionService:GetTagged(item_799)
            end)
            if value_802 and (type(value_803) == "table") then
                for index_1457, item_1458 in ipairs(value_803) do
                    addScannedItem(item_1458, ((item_799 == "CursedPossession") and "cursed") or nil)
                end
            end
        end
        itemSearchRoots = {
            {
                workspace:FindFirstChild("Items"),
                nil,
            },
            {
                workspace:FindFirstChild("CursedPossessionHolder"),
                "cursed",
            },
        }
        mapModel_211 = workspace:FindFirstChild("Map")
        if mapModel_211 then
            itemSearchRoots[#itemSearchRoots + 1 + 0] = {
                mapModel_211:FindFirstChild("InMapItems"),
                nil,
            }
        end
        for index_804, item_805 in ipairs(itemSearchRoots) do
            local indexed_value_806 = item_805[1]
            if indexed_value_806 then
                for index_1092, item_1093 in ipairs(indexed_value_806:GetDescendants()) do
                    if item_1093:GetAttribute("ItemName") or KnownItemNames[item_1093.Name:lower()] then
                        addScannedItem(item_1093, item_805[2])
                    end
                end
            end
        end
        local table_807 = {
        }
        for index_900, item_901 in ipairs(foundItems) do
            local value_903
            value_903 = false
            for index_1251, item_1252 in ipairs(foundItems) do
                if (item_1252 ~= item_901) and item_901.inst:IsDescendantOf(item_1252.inst) then
                    value_903 = true
                    break
                end
            end
            if not value_903 then
                table_807[#table_807 + 1] = item_901
            end
        end
        foundItems = table_807
        cachedItems, cachedItemsAt = foundItems, tick()
        return foundItems
    end
    local function groundY(x, z, startY)
        local raycastParams
        local character_217
        local raycastResult
        raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        character_217 = getCharacter()
        raycastParams.FilterDescendantsInstances = (character_217 and {
            character_217,
        }) or {
        }
        raycastParams.IgnoreWater = true
        raycastResult = workspace:Raycast(Vector3.new(x, (startY or 0) + 4, z), Vector3.new(0, -50, 0), raycastParams)
        return (raycastResult and raycastResult.Position.Y) or nil
    end
    local function objectCFrame(object)
        if not object then
            return nil
        end
        local lowestBottomY, sumX, sumZ, partCount = math.huge, 0, 0, 0
        local function accumulatePart(part)
            local partBottomY
            partCount = partCount + 1
            sumX = sumX + part.Position.X
            sumZ = sumZ + part.Position.Z
            partBottomY = part.Position.Y - (part.Size.Y * 0.5)
            if partBottomY < lowestBottomY then
                lowestBottomY = partBottomY
            end
        end
        if object:IsA("BasePart") then
            accumulatePart(object)
        end
        for index_417, item_418 in ipairs(object:GetDescendants()) do
            if item_418:IsA("BasePart") then
                accumulatePart(item_418)
            end
        end
        if partCount == 0 then
            return nil
        end
        local averageX, averageZ = sumX / partCount, sumZ / partCount
        local groundLevel = groundY(averageX, averageZ, lowestBottomY)
        return CFrame.new(averageX, groundLevel or (lowestBottomY + 2), averageZ)
    end
    local function findBaseCampCFrame()
        local mapModel_229
        local spawnFolder
        local roomsFolder_231
        local baseCampRoom
        mapModel_229 = findMap()
        if not mapModel_229 then
            return nil
        end
        spawnFolder = mapModel_229:FindFirstChild("Spawns")
        if spawnFolder then
            for index_1253, item_1254 in ipairs(spawnFolder:GetDescendants()) do
                local value_1255
                if item_1254:IsA("BasePart") then
                    value_1255 = item_1254.Position
                elseif item_1254:IsA("Attachment") then
                    value_1255 = item_1254.WorldPosition
                end
                if value_1255 then
                    local value_1343
                    value_1343 = groundY(value_1255.X, value_1255.Z, value_1255.Y)
                    return CFrame.new(value_1255.X, (value_1343 or value_1255.Y) + 0.5, value_1255.Z)
                end
            end
        end
        roomsFolder_231 = mapModel_229:FindFirstChild("Rooms")
        baseCampRoom = roomsFolder_231 and roomsFolder_231:FindFirstChild("Base Camp")
        if baseCampRoom then
            local value_1152
            value_1152 = objectCFrame(baseCampRoom)
            if value_1152 then
                return value_1152
            end
        end
        return nil
    end
    local function findGhostRoomCFrame()
        local mapModel_234
        local roomsFolder_235
        local ghostModel_236
        local roomName
        local roomModel_238
        mapModel_234 = findMap()
        roomsFolder_235 = mapModel_234 and mapModel_234:FindFirstChild("Rooms")
        if not roomsFolder_235 then
            return nil
        end
        ghostModel_236 = findGhost()
        roomName = ghostModel_236 and (ghostModel_236:GetAttribute("FavoriteRoom") or ghostModel_236:GetAttribute("CurrentRoom"))
        roomModel_238 = roomName and roomsFolder_235:FindFirstChild(roomName)
        if not roomModel_238 then
            local value_1154
            local value_1155
            value_1154, value_1155 = nil
            for index_1418, item_1419 in ipairs(roomsFolder_235:GetChildren()) do
                local value_1421
                value_1421 = item_1419:GetAttribute("Temperature")
                if (type(value_1421) == "number") and (not value_1155 or (value_1421 < value_1155)) then
                    value_1154, value_1155 = item_1419, value_1421
                end
            end
            roomModel_238 = value_1154
        end
        return roomModel_238 and objectCFrame(roomModel_238)
    end
    local function findClosets()
        local closets, seenClosetNames, mapModel_241 = {
        }, {
        }, findMap()
        if not mapModel_241 then
            return closets
        end
        for index_421, item_422 in ipairs(mapModel_241:GetDescendants()) do
            if item_422:IsA("Model") or item_422:IsA("BasePart") then
                local value_667
                value_667 = item_422.Name:lower()
                if value_667:find("closet") and not value_667:find("ghostcloset") and not seenClosetNames[item_422.Name] then
                    seenClosetNames[item_422.Name] = true
                    closets[#closets + 1] = item_422
                end
            end
        end
        return closets
    end
    local function getBasePart(instance_242)
        if instance_242:IsA("BasePart") then
            return instance_242
        end
        return instance_242:FindFirstChildWhichIsA("BasePart", true) or (instance_242:IsA("Model") and instance_242.PrimaryPart)
    end
    pcall(function()
        Library.DPIScale = 0.85
    end)
    local Window = Library:CreateWindow({
        ["Title"] = HUB_NAME,
        ["Footer"] = "vilanxware / " .. BUILD_NAME,
        ["ShowCustomCursor"] = true,
        ["NotifySide"] = "Right",
        ["Resizable"] = true,
    })
    local Connections, Highlights, Billboards = {
    }, {
    }, {
    }
    local function trackConnection(connection_245)
        if connection_245 then
            Connections[#Connections + 1] = connection_245
        end
        return connection_245
    end
    pcall(function()
        Library:OnUnload(function()
            running = false
            for index_591, item_592 in ipairs(Connections) do
                pcall(function()
                    item_592:Disconnect()
                end)
            end
            for key_593, value_594 in pairs(Highlights) do
                pcall(function()
                    value_594:Destroy()
                end)
            end
            for key_595, value_596 in pairs(Billboards) do
                pcall(function()
                    value_596:Destroy()
                end)
            end
            table.clear(Connections)
            table.clear(Highlights)
            table.clear(Billboards)
        end)
    end)
    local function addTab(tabTitle, tabIcon)
        local tabCreated, tab = pcall(function()
            return Window:AddTab(tabTitle, tabIcon)
        end)
        if not tabCreated or not tab then
            tabCreated, tab = pcall(function()
                return Window:AddTab(tabTitle)
            end)
        end
        if not tabCreated then
            warn("[vLnware] AddTab '" .. tostring(tabTitle) .. "' failed.")
            return nil
        end
        return tab
    end
    local function setControlText(control_251, text)
        pcall(function()
            if typeof(control_251.SetText) == "function" then
                control_251:SetText(text)
            elseif typeof(control_251.SetValue) == "function" then
                control_251:SetValue(text)
            end
        end)
    end
    local function addColorPicker(control_253, colorPickerId, defaultColor)
        pcall(function()
            control_253:AddColorPicker(colorPickerId, {
                ["Default"] = defaultColor,
                ["Title"] = "Color",
            })
        end)
        return control_253
    end
    local function removeHighlight(highlightKey_256)
        local highlight_257 = Highlights[highlightKey_256]
        if highlight_257 then
            pcall(function()
                highlight_257:Destroy()
            end)
            Highlights[highlightKey_256] = nil
        end
    end
    local function setHighlight(highlightKey_258, adornee_259, highlightColor, fillTransparency)
        if not adornee_259 then
            removeHighlight(highlightKey_258)
            return 
        end
        local highlight_262 = Highlights[highlightKey_258]
        if not highlight_262 then
            highlight_262 = Instance.new("Highlight")
            highlight_262.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            Highlights[highlightKey_258] = highlight_262
        end
        highlight_262.Adornee = adornee_259
        highlight_262.Parent = adornee_259
        highlight_262.FillColor = highlightColor
        highlight_262.OutlineColor = Color3.new(1, 1, 1)
        highlight_262.FillTransparency = fillTransparency or 0.6000000000000227
        highlight_262.Enabled = true
    end
    local function removeBillboard(billboardKey_269)
        local billboard_271
        billboard_271 = Billboards[billboardKey_269]
        if billboard_271 then
            pcall(function()
                billboard_271:Destroy()
            end)
            Billboards[billboardKey_269] = nil
        end
    end
    local function setBillboard(billboardKey_272, adornee_273, billboardText, textColor)
        local basePart
        local billboard_278
        basePart = adornee_273 and ((adornee_273:IsA("BasePart") and adornee_273) or getBasePart(adornee_273))
        if not basePart then
            removeBillboard(billboardKey_272)
            return 
        end
        billboard_278 = Billboards[billboardKey_272]
        if not billboard_278 then
            local value_909
            billboard_278 = Instance.new("BillboardGui")
            billboard_278.Size = UDim2.fromOffset(220, 26)
            billboard_278.StudsOffset = Vector3.new(0, 2.6, 0)
            billboard_278.AlwaysOnTop = true
            billboard_278.MaxDistance = 5000
            value_909 = Instance.new("TextLabel")
            value_909.Name = "L"
            value_909.BackgroundTransparency = 1
            value_909.Size = UDim2.fromScale(1, 1)
            value_909.Font = Enum.Font.GothamSemibold
            value_909.TextSize = 13
            value_909.TextStrokeTransparency = 0.35
            value_909.Parent = billboard_278
            Billboards[billboardKey_272] = billboard_278
        end
        billboard_278.Adornee = basePart
        billboard_278.Parent = basePart
        billboard_278.L.Text = billboardText
        billboard_278.L.TextColor3 = textColor or Color3.new(1, 1, 1)
        billboard_278.Enabled = true
    end
    local autoDetectedEvidence = {
    }
    local journalConfirmedEvidence = {
    }
    local lastManualLightActionAt = 0
    local function readFuseBoxState()
        local mapModel_280
        local fuseBox
        mapModel_280 = findMap()
        fuseBox = mapModel_280 and mapModel_280:FindFirstChild("FuseBox")
        if not fuseBox then
            return nil
        end
        for index_1094, item_1095 in ipairs({
            "On",
            "IsOn",
            "State",
            "Enabled",
            "Active",
            "Powered",
            "FuseBoxOn",
        }) do
            local get_attribute_1096 = fuseBox:GetAttribute(item_1095)
            if type(get_attribute_1096) == "boolean" then
                return get_attribute_1096
            end
        end
        for index_1097, item_1098 in ipairs(fuseBox:GetDescendants()) do
            for index_1175, item_1176 in ipairs({
                "On",
                "IsOn",
                "State",
                "Enabled",
                "Powered",
            }) do
                local value_1178
                value_1178 = item_1098:GetAttribute(item_1176)
                if type(value_1178) == "boolean" then
                    return value_1178
                end
            end
        end
        return nil
    end
    local detectionState = {
        ["ghostType"] = nil,
        ["ghostPct"] = nil,
        ["roamPct"] = nil,
        ["noOrb"] = false,
    }
    local function appendDetectionLog()

    end
    local homeTab = addTab("Home", "house")
    if homeTab then
        local value_603
        local value_604
        local value_605
        value_603 = homeTab:AddLeftGroupbox("Features · " .. BUILD_NAME)
        for index_1258, item_1259 in ipairs(FEATURES) do
            value_603:AddLabel("• " .. item_1259, true)
        end
        value_604 = homeTab:AddLeftGroupbox("What's New")
        for index_1256, item_1257 in ipairs(CHANGELOG) do
            value_604:AddLabel(item_1257.v, false)
            for index_1303, item_1304 in ipairs(item_1257.notes) do
                value_604:AddLabel("• " .. item_1304, true)
            end
        end
        value_605 = homeTab:AddRightGroupbox("vilanxware Community")
        value_605:AddLabel("Join our Discord for updates, support, and giveaways — and to never miss a new release.", true)
        value_605:AddButton({
            ["Text"] = "Join Discord (copy invite)",
            ["Func"] = function()
                if type(setclipboard) == "function" then
                    pcall(setclipboard, DISCORD_INVITE)
                end
                notify("Discord invite copied! " .. DISCORD_INVITE, 8)
            end,
        })
        value_605:AddLabel(DISCORD_INVITE, true)
        task.delay(2.5, function()
            pcall(notify, BUILD_NAME .. " loaded — open the Home tab and join our Discord!", 8)
        end)
    end
    local evidenceTab = addTab("Evidence", "search")
    local detectionsTab = addTab("Detections", "ghost")
    local utilitiesTab = addTab("Utilities", "wrench")
    local recentGhostTells = {
    }
    local lastPlayerDeathAt = 0
    local function markGhostTell(ghostType_424)
        if ghostType_424 then
            if not recentGhostTells[ghostType_424] then
                appendDetectionLog("Tell: " .. ghostType_424)
            end
            recentGhostTells[ghostType_424] = tick()
        end
    end
    local function notifyGhostTell(message_425, duration_426, ghostType_427)
        local hintsToggle = Library.Toggles and Library.Toggles.GH_Hints
        if (hintsToggle == nil) or (hintsToggle.Value == true) then
            notify(message_425, duration_426)
        end
        markGhostTell(ghostType_427)
    end
    local eventsFolder_429 = ReplicatedStorage:FindFirstChild("Events")
    local playerDiedEvent = eventsFolder_429 and eventsFolder_429:FindFirstChild("PlayerDied")
    if playerDiedEvent and playerDiedEvent:IsA("RemoteEvent") then
        trackConnection(playerDiedEvent.OnClientEvent:Connect(function()
            lastPlayerDeathAt = tick()
        end))
    end
    local liveGhostGroup = detectionsTab:AddLeftGroupbox("Active Ghost (live)")
    local ghostStateLabel = liveGhostGroup:AddLabel("State: no ghost spawned", true)
    liveGhostGroup:AddToggle("GH_Telemetry", {
        ["Text"] = "Live telemetry",
        ["Default"] = true,
    })
    liveGhostGroup:AddToggle("GH_HuntAlert", {
        ["Text"] = "Hunt alert (notify)",
        ["Default"] = true,
    })
    liveGhostGroup:AddToggle("GH_Haunt", {
        ["Text"] = "On-screen haunt warning",
        ["Default"] = true,
    })
    liveGhostGroup:AddToggle("GH_Hints", {
        ["Text"] = "Tip notifications",
        ["Default"] = true,
        ["Tooltip"] = "Pop-up tips like 'Glass → Banshee'. Turn OFF to silence them — detection & auto-guess still work.",
    })
    liveGhostGroup:AddToggle("GH_Behaviour", {
        ["Text"] = "Ghost-type detectors",
        ["Default"] = true,
        ["Tooltip"] = "Live tells: Banshee (glass — esp. heavy during a hunt), Entity (teleports), Vex (invisible on LIDAR / walks through walls), plus any ability flag the game exposes on the ghost (Umbra no-footsteps, Skinwalker mimic, etc.). Siren (always-female voice) and Ravager (auto EMF 5) are listed as tells in the Identifier.",
    })
    local ghostTellsGroup
    local ghostTellsLabel
    ghostTellsGroup = detectionsTab:AddRightGroupbox("Ghost-Type Tells (possible now)")
    ghostTellsLabel = ghostTellsGroup:AddLabel("Spawn a ghost and add evidence to narrow the list.", true)
    task.spawn(function()
        while running do
            local value_1020
            local value_1021
            value_1020 = detectionState.possible
            value_1021 = nil
            if not value_1020 or (#value_1020 == 0) then
                value_1021 = "Spawn a ghost and add evidence to narrow the list."
            else
                local value_1347
                local value_1348
                local value_1349
                value_1347 = #value_1020 <= 8
                value_1348 = {
                }
                for index_1526, item_1527 in ipairs(value_1020) do
                    if GHOST_TRAITS[item_1527] then
                        local value_1565
                        value_1565 = ("%s — %s"):format(item_1527, GHOST_TRAITS[item_1527])
                        if value_1347 and GHOST_TIPS[item_1527] then
                            value_1565 = value_1565 .. ("\n    ↳ counter: %s"):format(GHOST_TIPS[item_1527])
                        end
                        value_1348[#value_1348 + 1] = value_1565
                    end
                end
                value_1349 = (value_1347 and "") or (("%d still possible — watch for:\n"):format(#value_1020))
                value_1021 = ((#value_1348 > 0) and (value_1349 .. table.concat(value_1348, (value_1347 and "\n\n") or "\n"))) or "No specific tells for the current candidates."
            end
            setControlText(ghostTellsLabel, value_1021)
            task.wait(0.5)
        end
    end)
    local ignoredGhostAttributes = {
        ["Age"] = true,
        ["CameraKillOffset"] = true,
        ["CurrentRoom"] = true,
        ["FavoriteRoom"] = true,
        ["Gender"] = true,
        ["Hunting"] = true,
        ["InLaser"] = true,
        ["IsGhost"] = true,
        ["LaserVisible"] = true,
        ["LastEMFLevel5Time"] = true,
        ["PhotoRewardAvailable"] = true,
        ["Transparency"] = true,
        ["TransparencyLocked"] = true,
        ["VisualModel"] = true,
        ["DisturbedSaltRecently"] = true,
        ["EventActive"] = true,
        ["SkinApplied"] = true,
        ["PhotoRewardGiven"] = true,
        ["AnimationsLocked"] = true,
        ["Slowed"] = true,
    }
    local ghostAttributeDescriptions = {
        ["InvisibleOnLIDAR"] = "invisible on LIDAR → Vex",
        ["WalkThroughWalls"] = "walks through walls → Vex",
        ["WalksThroughWalls"] = "walks through walls → Vex",
        ["NoFootsteps"] = "no footstep sounds → Umbra",
        ["NoFootstepSounds"] = "no footstep sounds → Umbra",
        ["Mimic"] = "mimicking another ghost → Skinwalker",
        ["Mimicking"] = "mimicking another ghost → Skinwalker",
        ["Copying"] = "mimicking another ghost → Skinwalker",
        ["Headless"] = "appears HEADLESS → Dullahan",
    }
    local ghostTypeByAttribute = {
        ["InvisibleOnLIDAR"] = "Vex",
        ["WalkThroughWalls"] = "Vex",
        ["WalksThroughWalls"] = "Vex",
        ["NoFootsteps"] = "Umbra",
        ["NoFootstepSounds"] = "Umbra",
        ["Mimic"] = "Skinwalker",
        ["Mimicking"] = "Skinwalker",
        ["Copying"] = "Skinwalker",
        ["Headless"] = "Dullahan",
    }
    local previousBrokenGlassCount, previousGhostPosition_438, huntGlassBaseline, reportedGhostAttributes, trackedGhost = nil, nil, nil, {
    }, nil
    local previousHuntPosition, fastHuntReported, previousLightsOnCount, hasLightSample, unusedBehaviorFlag = nil, false, nil, false, false
    local previousHuntingState, huntCount, huntWindowStartedAt = false, 0, tick()
    local previousRoomName, favoriteRoomSamples, roomSamples, favoriteRoomHits, electronicsStayedOn, teleportTellCount = nil, 0, 0, 0, false, 0
    task.spawn(function()
        while running do
            if toggleEnabled("GH_Behaviour") then
                local value_1180
                local value_1181
                local value_1182
                local value_1183
                local value_1184
                local value_1185
                value_1180 = findGhost()
                value_1181 = value_1180 and (value_1180:GetAttribute("Hunting") == true)
                if value_1180 ~= trackedGhost then
                    trackedGhost = value_1180
                    reportedGhostAttributes = {
                    }
                    previousHuntPosition, fastHuntReported, hasLightSample, unusedBehaviorFlag = nil, false, false, false
                    previousHuntingState, huntCount, huntWindowStartedAt = false, 0, tick()
                    previousRoomName, favoriteRoomSamples, roomSamples, favoriteRoomHits, electronicsStayedOn, teleportTellCount = nil, 0, 0, 0, false, 0
                end
                value_1182 = workspace:FindFirstChild("BrokenGlass")
                value_1183 = (value_1182 and #value_1182:GetChildren()) or 0
                if (previousBrokenGlassCount ~= nil) and (value_1183 > previousBrokenGlassCount) and not value_1181 then
                    notifyGhostTell("Glass shattered outside a hunt → possible Banshee.", 4, "Banshee")
                end
                if value_1181 then
                    huntGlassBaseline = huntGlassBaseline or value_1183
                    if (value_1183 - huntGlassBaseline) >= 3 then
                        notifyGhostTell("Heavy glass-breaking this hunt → likely Banshee.", 4, "Banshee")
                        huntGlassBaseline = value_1183
                    end
                else
                    huntGlassBaseline = nil
                end
                previousBrokenGlassCount = value_1183
                value_1184 = value_1180 and getBasePart(value_1180)
                if value_1184 then
                    if previousGhostPosition_438 and ((value_1184.Position - previousGhostPosition_438).Magnitude > 40) and not value_1181 then
                        teleportTellCount = teleportTellCount + 1
                        if teleportTellCount >= 2 then
                            notifyGhostTell("Ghost teleported → possible Entity.", 4, "Entity")
                        end
                    end
                    previousGhostPosition_438 = value_1184.Position
                end
                if value_1180 then
                    local value_1469
                    local value_1470
                    value_1469, value_1470 = pcall(function()
                        return value_1180:GetAttributes()
                    end)
                    if value_1469 and (type(value_1470) == "table") then
                        for key_1608, value_1609 in pairs(value_1470) do
                            if (value_1609 == true) and not ignoredGhostAttributes[key_1608] and not reportedGhostAttributes[key_1608] then
                                reportedGhostAttributes[key_1608] = true
                                notify("Ghost tell: " .. (ghostAttributeDescriptions[key_1608] or (key_1608 .. " = true")), 5)
                                markGhostTell(ghostTypeByAttribute[key_1608])
                            end
                        end
                    end
                end
                if value_1181 and value_1184 then
                    if previousHuntPosition then
                        local magnitude_1533 = (value_1184.Position - previousHuntPosition).Magnitude
                        if (magnitude_1533 > 18) and not fastHuntReported then
                            notify(("Fast hunt (~%d studs/s) → speeds up on sight (Demon/Umbra-type)."):format(math.floor(magnitude_1533)), 4)
                            fastHuntReported = true
                        end
                    end
                    previousHuntPosition = value_1184.Position
                else
                    previousHuntPosition = nil
                end
                local find_map_1424 = findMap()
                local value_1425 = find_map_1424 and find_map_1424:FindFirstChild("Rooms")
                if value_1425 then
                    local number_1496 = 0
                    for index_1530, item_1531 in ipairs(value_1425:GetChildren()) do
                        local light_switch_1532 = item_1531:FindFirstChild("LightSwitch")
                        if light_switch_1532 and (light_switch_1532:GetAttribute("State") == true) then
                            number_1496 = number_1496 + 1
                        end
                    end
                    local value_1497 = (tick() - lastManualLightActionAt) < 3
                    if hasLightSample and previousLightsOnCount and (number_1496 == (previousLightsOnCount - 1)) and not value_1181 and not value_1497 and (readFuseBoxState() ~= false) then
                        notifyGhostTell("A light switched off on its own → possible Leviathan.", 4, "Leviathan")
                    end
                    previousLightsOnCount, hasLightSample = number_1496, true
                end
                if value_1181 and not previousHuntingState then
                    huntCount = huntCount + 1 + 0
                end
                if previousHuntingState and not value_1181 and (lastPlayerDeathAt > 0) and ((tick() - lastPlayerDeathAt) < 4) then
                    notifyGhostTell("Hunt ended right after a death → possible Revenant.", 5, "Revenant")
                end
                previousHuntingState = value_1181
                if (huntCount >= 2) and ((tick() - huntWindowStartedAt) < 180) then
                    markGhostTell("Demon")
                end
                if value_1181 then
                    for index_1494, item_1495 in ipairs(scanItems()) do
                        if (item_1495.name == "Flashlight") and (item_1495.inst:GetAttribute("Enabled") == true) then
                            markGhostTell("Ghoul")
                            break
                        end
                    end
                end
                value_1185 = LocalPlayer:GetAttribute("Energy")
                if (type(value_1185) == "number") and previousRoomName then
                    if ((previousRoomName - value_1185) > 0.12) and (LocalPlayer:GetAttribute("Sprinting") ~= true) and not value_1181 then
                        favoriteRoomSamples = favoriteRoomSamples + 1
                        if favoriteRoomSamples >= 5 then
                            markGhostTell("Wraith")
                        end
                    else
                        favoriteRoomSamples = 0
                    end
                end
                if type(value_1185) == "number" then
                    previousRoomName = value_1185
                end
                local value_1423
                value_1423 = value_1180:GetAttribute("CameraKillOffset")
                if (type(value_1423) == "number") and (value_1423 >= 3) then
                    markGhostTell("Ravager")
                end
                if value_1180 and not value_1181 then
                    local current_room_1462, favorite_room_1463 = value_1180:GetAttribute("CurrentRoom"), value_1180:GetAttribute("FavoriteRoom")
                    if current_room_1462 and favorite_room_1463 then
                        roomSamples = roomSamples + 1
                        if current_room_1462 == favorite_room_1463 then
                            favoriteRoomHits = favoriteRoomHits + 1
                        end
                        if (roomSamples >= 30) and ((favoriteRoomHits / roomSamples) >= 0.8) then
                            markGhostTell("Specter")
                            if not electronicsStayedOn then
                                notifyGhostTell("Ghost barely leaves its room → likely Specter.", 5)
                                electronicsStayedOn = true
                            end
                        end
                    end
                end
                detectionState.roamPct = ((roomSamples >= 5) and math.floor((favoriteRoomHits / roomSamples) * 100)) or nil
                if not unusedBehaviorFlag then
                    local value_1465
                    value_1465 = 0
                    for key_1624 in pairs(recentGhostTells) do
                        if key_1624 ~= "Skinwalker" then
                            value_1465 = value_1465 + 1 + 0
                        end
                    end
                    if value_1465 >= 3 then
                        notifyGhostTell("Conflicting behaviour tells → possible Skinwalker (mimic).", 5)
                        markGhostTell("Skinwalker")
                        unusedBehaviorFlag = true
                    end
                end
            end
            task.wait(1)
        end
    end)
    local counterToolsGroup = detectionsTab:AddLeftGroupbox("Counter Tools")
    local energyStatusLabel = counterToolsGroup:AddLabel("Energy: —", true)
    counterToolsGroup:AddToggle("CT_EnergyAlert", {
        ["Text"] = "Low-energy alert",
        ["Default"] = false,
        ["Tooltip"] = "Keres/Wendigo target the LOWEST-energy player; Wraith drains you. Warns when your Energy drops below the threshold.",
    })
    counterToolsGroup:AddSlider("CT_EnergyThr", {
        ["Text"] = "Alert below",
        ["Default"] = 90,
        ["Min"] = 10,
        ["Max"] = 100,
        ["Rounding"] = 0,
        ["Suffix"] = "%",
    })
    counterToolsGroup:AddButton({
        ["Text"] = "Turn ON all room lights",
        ["Func"] = function()
            local value_607
            local value_608
            local value_609
            value_607 = findMap()
            value_608 = value_607 and value_607:FindFirstChild("Rooms")
            if not value_608 then
                notify("No mission.")
                return 
            end
            value_609 = 0
            for index_1022, item_1023 in ipairs(value_608:GetChildren()) do
                local value_1025
                value_1025 = item_1023:FindFirstChild("LightSwitch")
                if value_1025 and (value_1025:GetAttribute("State") ~= true) then
                    local proximity_prompt_1351 = value_1025:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local flag_1352 = false
                    if proximity_prompt_1351 and (type(fireproximityprompt) == "function") then
                        local max_activation_distance_1472 = proximity_prompt_1351.MaxActivationDistance
                        pcall(function()
                            proximity_prompt_1351.RequiresLineOfSight = false
                            proximity_prompt_1351.MaxActivationDistance = 10000000
                        end)
                        flag_1352 = pcall(fireproximityprompt, proximity_prompt_1351)
                        pcall(function()
                            proximity_prompt_1351.MaxActivationDistance = max_activation_distance_1472
                        end)
                    end
                    if not flag_1352 then
                        pcall(function()
                            fireEvent("UseLightSwitch", value_1025)
                        end)
                    end
                    value_609 = value_609 + 1
                end
            end
            notify(("Flipped %d light switch(es) — light slows Umbra/Shadow/Nightmare."):format(value_609))
        end,
    })
    counterToolsGroup:AddLabel("Vesper: stand still / crouch in a hunt to be unhearable.\nWraith / Aswang: salt slows + detects them.\nDemon: keep a crucifix close.", true)
    task.spawn(function()
        local value_611
        value_611 = false
        while running do
            local energy_1026 = LocalPlayer:GetAttribute("Energy")
            local salt_piles_1027 = workspace:FindFirstChild("SaltPiles")
            local value_1028 = (salt_piles_1027 and #salt_piles_1027:GetChildren()) or 0
            if type(energy_1026) == "number" then
                setControlText(energyStatusLabel, ("Energy: %d%%    Salt piles: %d"):format(math.floor(energy_1026), value_1028))
                if toggleEnabled("CT_EnergyAlert") and (energy_1026 < numericOption("CT_EnergyThr", 90)) then
                    if not value_611 then
                        notify(("Low energy (%d%%) — you may be the ghost's target."):format(math.floor(energy_1026)), 4)
                        value_611 = true
                    end
                else
                    value_611 = false
                end
            else
                setControlText(energyStatusLabel, ("Energy: —    Salt piles: %d"):format(value_1028))
            end
            task.wait(1)
        end
    end)
    local lightsPowerGroup = utilitiesTab:AddRightGroupbox("Lights / Power")
    lightsPowerGroup:AddToggle("LP_LightsOn", {
        ["Text"] = "Auto turn ON lights",
        ["Default"] = false,
        ["Tooltip"] = "Keeps every room light ON (light slows Umbra/Shadow/Nightmare + helps you see). Needs the fuse box ON.",
    })
    lightsPowerGroup:AddToggle("LP_LightsOff", {
        ["Text"] = "Auto turn OFF lights",
        ["Default"] = false,
        ["Tooltip"] = "Keeps every room light OFF (dark).",
    })
    lightsPowerGroup:AddToggle("LP_FuseOn", {
        ["Text"] = "Auto turn ON fuse box",
        ["Default"] = false,
        ["Tooltip"] = "Flips the fuse box back ON whenever it reads as off, so lights work.",
    })
    lightsPowerGroup:AddLabel("ON/OFF are exclusive — ON wins if both are set.", true)
    local function firePrompt(arg_612)
        local value_615
        local value_616
        value_615 = nil
        value_616 = nil
        if not (arg_612 and (type(fireproximityprompt) == "function")) then
            return false
        end
        value_615 = arg_612.MaxActivationDistance
        pcall(function()
            arg_612.RequiresLineOfSight = false
            arg_612.MaxActivationDistance = 10000000
        end)
        value_616 = pcall(fireproximityprompt, arg_612)
        pcall(function()
            arg_612.MaxActivationDistance = value_615
        end)
        return value_616
    end
    local function toggleLightSwitch(arg_617)
        if not firePrompt(arg_617:FindFirstChildWhichIsA("ProximityPrompt", true)) then
            pcall(function()
                fireEvent("UseLightSwitch", arg_617)
            end)
        end
        lastManualLightActionAt = tick()
    end
    task.spawn(function()
        while running do
            if ghostFlagActive() then
                local value_1190
                local value_1191
                local value_1192
                local value_1193
                value_1190 = findMap()
                if toggleEnabled("LP_FuseOn") and (readFuseBoxState() == false) then
                    local value_1474
                    value_1474 = value_1190 and value_1190:FindFirstChild("FuseBox")
                    if value_1474 then
                        local value_1593
                        value_1593 = nil
                        function value_1593()
                            local value_1633
                            value_1633 = false
                            for index_1642, item_1643 in ipairs(value_1474:GetDescendants()) do
                                if item_1643:IsA("ProximityPrompt") and item_1643.Enabled then
                                    firePrompt(item_1643)
                                    value_1633 = true
                                    task.wait(0.05)
                                end
                            end
                            return value_1633
                        end
                        if not value_1593() then
                            pcall(function()
                                fireEvent("ToggleFuseBox")
                            end)
                        end
                        if readFuseBoxState() == false then
                            task.wait(0.3499999999999943)
                            value_1593()
                        end
                    else
                        pcall(function()
                            fireEvent("ToggleFuseBox")
                        end)
                    end
                    lastManualLightActionAt = tick()
                end
                value_1191 = value_1190 and value_1190:FindFirstChild("Rooms")
                value_1192 = toggleEnabled("LP_LightsOn")
                value_1193 = not value_1192 and toggleEnabled("LP_LightsOff")
                if value_1191 and (value_1192 or value_1193) then
                    for index_1500, item_1501 in ipairs(value_1191:GetChildren()) do
                        local light_switch_1502 = item_1501:FindFirstChild("LightSwitch")
                        if light_switch_1502 then
                            local value_1549
                            value_1549 = light_switch_1502:GetAttribute("State") == true
                            if value_1192 and not value_1549 then
                                toggleLightSwitch(light_switch_1502)
                            elseif value_1193 and value_1549 then
                                toggleLightSwitch(light_switch_1502)
                            end
                        end
                    end
                end
            end
            task.wait(1.2)
        end
    end)
    local escapeGroup = utilitiesTab:AddLeftGroupbox("Escape")
    local function teleportToBaseCamp()
        local baseCampCFrame = findBaseCampCFrame()
        local rootPart_462 = getRootPart()
        if baseCampCFrame and rootPart_462 then
            rootPart_462.CFrame = baseCampCFrame + Vector3.new(0, 3, 0)
            return true
        end
        return false
    end
    local escapeButton = escapeGroup:AddButton({
        ["Text"] = "Escape to spawn now",
        ["Func"] = function()
            notify((teleportToBaseCamp() and "Teleported to spawn.") or "Spawn not found — are you in a mission?")
        end,
    })
    pcall(function()
        escapeGroup:AddLabel("Escape key"):AddKeyPicker("GH_EscapeKey", {
            ["Default"] = "T",
            ["Mode"] = "Toggle",
            ["Text"] = "Escape",
            ["SyncToggleState"] = false,
        })
    end)
    escapeGroup:AddToggle("GH_AutoEscape", {
        ["Text"] = "Auto-escape on hunt",
        ["Default"] = false,
        ["Tooltip"] = "Instantly TP to the map spawn the moment a hunt starts.",
    })
    local ghostRoomGroup = utilitiesTab:AddLeftGroupbox("Thermo / Ghost Room")
    local ghostRoomLabel = ghostRoomGroup:AddLabel("Ghost room: —", true)
    local function findLikelyGhostRoom()
        local mapModel_464
        local roomsFolder_465
        local ghostModel_466
        local reportedRoomName
        local coldestRoom
        local coldestTemperature
        mapModel_464 = findMap()
        roomsFolder_465 = mapModel_464 and mapModel_464:FindFirstChild("Rooms")
        if not roomsFolder_465 then
            return nil
        end
        ghostModel_466 = findGhost()
        reportedRoomName = ghostModel_466 and (ghostModel_466:GetAttribute("CurrentRoom") or ghostModel_466:GetAttribute("FavoriteRoom"))
        if reportedRoomName then
            local find_first_child_1030 = roomsFolder_465:FindFirstChild(reportedRoomName)
            if find_first_child_1030 then
                return find_first_child_1030, reportedRoomName, (ghostModel_466:GetAttribute("CurrentRoom") and "ghost") or "favorite"
            end
        end
        coldestRoom, coldestTemperature = nil
        for index_913, item_914 in ipairs(roomsFolder_465:GetChildren()) do
            local value_916
            value_916 = item_914:GetAttribute("Temperature")
            if (type(value_916) == "number") and (not coldestTemperature or (value_916 < coldestTemperature)) then
                coldestRoom, coldestTemperature = item_914, value_916
            end
        end
        return coldestRoom, coldestRoom and coldestRoom.Name, "coldest"
    end
    local function getRoomCFrame(roomModel_470)
        return (roomModel_470 and objectCFrame(roomModel_470)) or nil
    end
    local function teleportToGhostRoom()
        local targetCFrame
        local rootPart_473
        targetCFrame, rootPart_473 = getRoomCFrame(findLikelyGhostRoom()), getRootPart()
        if targetCFrame and rootPart_473 then
            rootPart_473.CFrame = targetCFrame + Vector3.new(0, 1, 0)
            return true
        end
        return false
    end
    ghostRoomGroup:AddToggle("TR_Alert", {
        ["Text"] = "Alert on room change",
        ["Default"] = true,
        ["Tooltip"] = "Notifies when the ghost moves room (it roams on higher difficulties). Read-only — no auto-TP.",
    })
    local lastRoomName
    lastRoomName = nil
    task.spawn(function()
        while running do
            local value_1032
            local value_1033
            local value_1034
            local value_1035
            local value_1036
            local value_1037
            value_1032, value_1033, value_1034 = findLikelyGhostRoom()
            value_1035 = findGhost()
            value_1036 = value_1035 and value_1035:GetAttribute("CurrentRoom")
            value_1037 = "—"
            if value_1032 then
                local temperature_1353 = value_1032:GetAttribute("Temperature")
                if type(temperature_1353) == "number" then
                    value_1037 = ("%.1f°C"):format(temperature_1353)
                end
            end
            setControlText(ghostRoomLabel, ("Ghost room: %s (%s)\nRoom temp: %s"):format(tostring(value_1033 or "—"), tostring(value_1034 or "—"), value_1037))
            if value_1036 and (value_1036 ~= lastRoomName) then
                if lastRoomName ~= nil then
                    if toggleEnabled("TR_Alert") then
                        notify("Ghost moved to: " .. value_1036, 4)
                    end
                    appendDetectionLog("Room: " .. value_1036)
                end
                lastRoomName = value_1036
            end
            task.wait(1)
        end
    end)
    local teleportsGroup = utilitiesTab:AddRightGroupbox("Teleports")
    local function handleTeleportToGhostRoom()
        local ghostModel_477
        ghostModel_477 = findGhost()
        if ghostModel_477 and (ghostModel_477:GetAttribute("Hunting") == true) then
            notify("Blocked — a hunt is active (that's instant death).")
            return 
        end
        notify((teleportToGhostRoom() and "Teleported to ghost room.") or "Ghost room not found.")
    end
    local function teleportToGhost()
        local ghostModel_479
        local ghostPart_480
        local rootPart_481
        ghostModel_479 = findGhost()
        if not ghostModel_479 then
            notify("No ghost spawned.")
            return 
        end
        if ghostModel_479:GetAttribute("Hunting") == true then
            notify("Blocked — a hunt is active (that's instant death).")
            return 
        end
        ghostPart_480, rootPart_481 = getBasePart(ghostModel_479), getRootPart()
        if ghostPart_480 and rootPart_481 then
            local position_1038 = ghostPart_480.Position
            local ground_y_1039 = groundY(position_1038.X, position_1038.Z, position_1038.Y)
            rootPart_481.CFrame = CFrame.new(position_1038.X, (ground_y_1039 or position_1038.Y) + 3, position_1038.Z)
            notify("Teleported to the ghost.")
        else
            notify("Ghost position unavailable.")
        end
    end
    local teleportRoomButton = teleportsGroup:AddButton({
        ["Text"] = "TP to ghost room",
        ["Func"] = handleTeleportToGhostRoom,
    })
    local teleportGhostButton = teleportsGroup:AddButton({
        ["Text"] = "TP to ghost",
        ["Func"] = teleportToGhost,
    })
    pcall(function()
        teleportsGroup:AddLabel("TP room key"):AddKeyPicker("TP_RoomKey", {
            ["Default"] = "V",
            ["Mode"] = "Toggle",
            ["Text"] = "TP room",
            ["SyncToggleState"] = false,
        })
    end)
    pcall(function()
        teleportsGroup:AddLabel("TP ghost key"):AddKeyPicker("TP_GhostKey", {
            ["Default"] = "H",
            ["Mode"] = "Toggle",
            ["Text"] = "TP ghost",
            ["SyncToggleState"] = false,
        })
    end)
    local getKeybindValue
    getKeybindValue = nil
    function getKeybindValue(arg_920, arg_921)
        local value_922 = Library and Library.Options and Library.Options[arg_920]
        return (value_922 and value_922.Value and tostring(value_922.Value)) or arg_921
    end
    trackConnection(UserInputService.InputBegan:Connect(function(arg_917, arg_918)
        if not running or arg_918 or (arg_917.UserInputType ~= Enum.UserInputType.Keyboard) then
            return 
        end
        local name_919 = arg_917.KeyCode.Name
        if name_919 == getKeybindValue("GH_EscapeKey", "T") then
            teleportToBaseCamp()
        elseif name_919 == getKeybindValue("TP_RoomKey", "V") then
            handleTeleportToGhostRoom()
        elseif name_919 == getKeybindValue("TP_GhostKey", "H") then
            teleportToGhost()
        end
    end))
    local ghostIdentifierGroup = evidenceTab:AddLeftGroupbox("Ghost Identifier")
    ghostIdentifierGroup:AddDropdown("ID_Confirmed", {
        ["Values"] = EVIDENCE_NAMES,
        ["Default"] = {
        },
        ["Multi"] = true,
        ["Text"] = "Confirmed evidence",
    })
    ghostIdentifierGroup:AddDropdown("ID_RuledOut", {
        ["Values"] = EVIDENCE_NAMES,
        ["Default"] = {
        },
        ["Multi"] = true,
        ["Text"] = "Ruled-out evidence",
    })
    ghostIdentifierGroup:AddToggle("ID_AutoNeg", {
        ["Text"] = "Auto rule-out absent Ghost Orb",
        ["Default"] = true,
        ["Tooltip"] = "The orb Part stays all match for orb-ghosts; if it's absent after the 15s grace, this ghost gives NO orb — auto-rules-out Ghost Orb to narrow the list.",
    })
    local possibleGhostsLabel = ghostIdentifierGroup:AddLabel("Possible (" .. GhostCount .. "): all", true)
    local ghostTraitsLabel = nil
    local journalEvidenceIdByName = {
        ["EMF Level 5"] = "EMFLevel5",
        ["Spirit Box"] = "SpiritBox",
        ["Inscription"] = "GhostWriting",
        ["Freezing Temperatures"] = "FreezingTemperatures",
        ["Ghost Orb"] = "GhostOrb",
        ["Prints"] = "Handprints",
        ["Laser Projector"] = "LaserProjector",
        ["Wither"] = "Wither",
    }
    local journalMarkedEvidence = {
    }
    local journalSelectedGhost = nil
    local function findJournalPath(...)
        local value_485
        value_485 = LocalPlayer:FindFirstChild("PlayerGui")
        value_485 = value_485 and value_485:FindFirstChild("Journal")
        for index_923, item_924 in ipairs({
            ...,
        }) do
            value_485 = value_485 and value_485:FindFirstChild(item_924)
        end
        return value_485
    end
    local function activateGuiButton(arg_486)
        local value_488
        local value_489
        if not (arg_486 and arg_486:IsA("GuiButton")) then
            return false
        end
        value_488 = arg_486.AbsolutePosition.X + (arg_486.AbsoluteSize.X * 0.5)
        value_489 = arg_486.AbsolutePosition.Y + (arg_486.AbsoluteSize.Y * 0.5)
        if type(getconnections) == "function" then
            for index_1476, item_1477 in ipairs({
                "MouseButton1Click",
                "Activated",
                "MouseButton1Down",
            }) do
                local ok_1478, result_1479 = pcall(function()
                    return getconnections(arg_486[item_1477])
                end)
                if ok_1478 and result_1479 and (#result_1479 > 0) then
                    for index_1610, item_1611 in ipairs(result_1479) do
                        if typeof(item_1611.Fire) == "function" then
                            pcall(function()
                                item_1611:Fire(value_488, value_489)
                            end)
                        elseif type(item_1611.Function) == "function" then
                            pcall(item_1611.Function, value_488, value_489)
                        end
                    end
                    return true
                end
            end
        end
        if type(firesignal) == "function" then
            return pcall(firesignal, arg_486.MouseButton1Click, value_488, value_489)
        end
        return false
    end
    local function activateButtonRepeatedly(arg_490, arg_491)
        for index_1354 = 1, arg_491 or 1 do
            if not activateGuiButton(arg_490) then
                return false
            end
            task.wait()
        end
        return true
    end
    local function toggleJournalEvidence(arg_494, arg_495)
        local value_496 = arg_494 and arg_494:FindFirstChild(arg_495)
        return activateGuiButton(value_496 and value_496:FindFirstChild("Detection", true))
    end
    local function findJournalEvidenceContainer()
        local value_498
        value_498 = findJournalPath("Holder", "Pages")
        if not value_498 then
            return nil
        end
        for index_925, item_926 in ipairs(value_498:GetChildren()) do
            local value_929
            local value_930
            local value_931
            local value_932
            value_929 = nil
            value_930 = nil
            value_931 = nil
            value_932 = nil
            value_929 = item_926:FindFirstChild("Left")
            value_929 = value_929 and value_929:FindFirstChild("Page")
            value_930 = item_926:FindFirstChild("Right")
            value_930 = value_930 and value_930:FindFirstChild("Page")
            value_931 = value_929 and value_929:FindFirstChild("EvidenceTypes")
            value_932 = value_930 and value_930:FindFirstChild("GhostTypes")
            if value_931 and value_932 then
                return value_931
            end
        end
        return nil
    end
    local function findJournalGhostButton(arg_499)
        local value_501
        value_501 = findJournalPath("Holder", "Pages")
        if not value_501 then
            return nil
        end
        for index_1194, item_1195 in ipairs(value_501:GetChildren()) do
            local value_1198
            local value_1199
            local value_1200
            local value_1201
            value_1198 = nil
            value_1199 = nil
            value_1200 = nil
            value_1201 = nil
            value_1198 = item_1195:FindFirstChild("Right")
            value_1198 = value_1198 and value_1198:FindFirstChild("Page")
            value_1199 = value_1198 and value_1198:FindFirstChild("GhostTypes")
            value_1200 = value_1199 and value_1199:FindFirstChild(arg_499)
            value_1201 = value_1200 and value_1200:FindFirstChild("Detection", true)
            if value_1201 and value_1201:IsA("GuiButton") then
                return value_1201
            end
        end
        return nil
    end
    local function syncJournalSelections(arg_502, arg_503)
        local value_505
        local value_506
        local value_507
        value_505 = findJournalEvidenceContainer()
        if not value_505 then
            return 0
        end
        value_506 = {
        }
        for key_1202 in pairs(arg_502) do
            local value_1204
            value_1204 = journalEvidenceIdByName[key_1202]
            if value_1204 then
                value_506[value_1204] = true
            end
        end
        value_507 = 0
        for key_934 in pairs(value_506) do
            if not journalMarkedEvidence[key_934] and toggleJournalEvidence(value_505, key_934) then
                journalMarkedEvidence[key_934] = true
                value_507 = value_507 + 1
            end
        end
        for key_933 in pairs(journalMarkedEvidence) do
            if not value_506[key_933] then
                local find_first_child_1101 = value_505:FindFirstChild(key_933)
                activateButtonRepeatedly(find_first_child_1101 and find_first_child_1101:FindFirstChild("Detection", true), 2)
                journalMarkedEvidence[key_933] = nil
                value_507 = value_507 + 1
            end
        end
        if arg_503 ~= journalSelectedGhost then
            if journalSelectedGhost then
                activateButtonRepeatedly(findJournalGhostButton(journalSelectedGhost), 2)
                journalSelectedGhost = nil
                value_507 = value_507 + 1
            end
            if arg_503 and activateGuiButton(findJournalGhostButton(arg_503)) then
                journalSelectedGhost = arg_503
                value_507 = value_507 + 1
            end
        end
        return value_507
    end
    local evidenceDisplayOrder = {
        "EMF Level 5",
        "Spirit Box",
        "Inscription",
        "Freezing Temperatures",
        "Ghost Orb",
        "Prints",
        "Laser Projector",
        "Wither",
    }
    local evidenceStatusGroup = evidenceTab:AddLeftGroupbox("Evidence Status")
    local evidenceStatusLabel = evidenceStatusGroup:AddLabel("—", true)
    local autoGuessGroup = evidenceTab:AddRightGroupbox("Auto Guess / Profile")
    local autoGuessLabel = autoGuessGroup:AddLabel("—", true)
    local singlePossibleGhost
    ghostIdentifierGroup:AddButton({
        ["Text"] = "Mark all detected in journal",
        ["Func"] = function()
            if not findJournalEvidenceContainer() then
                notify("Evidence page not found — open the journal's EVIDENCE tab once, then retry.", 7)
                return 
            end
            local table_508 = {
            }
            for key_620 in pairs(tableOption("ID_Confirmed")) do
                table_508[key_620] = true
            end
            for key_622 in pairs(autoDetectedEvidence) do
                table_508[key_622] = true
            end
            local v317_509 = syncJournalSelections(table_508, singlePossibleGhost)
            task.spawn(function()
                local value_625
                local value_626
                local value_627
                local value_628
                local value_629
                task.wait(0.6)
                value_625, value_626 = {
                }, {
                }
                for key_1043 in pairs(table_508) do
                    if journalConfirmedEvidence[key_1043] then
                        value_625[#value_625 + 1] = key_1043
                    else
                        value_626[#value_626 + 1] = key_1043
                    end
                end
                value_627 = nil
                value_628 = Events and Events:FindFirstChild("GetSelectedGhost")
                if value_628 and value_628:IsA("RemoteFunction") then
                    pcall(function()
                        value_627 = value_628:InvokeServer()
                    end)
                end
                value_629 = {
                    ("Fired %d mark(s)."):format(v317_509),
                }
                value_629[#value_629 + 1] = ((#value_625 > 0) and ("Game confirmed: " .. table.concat(value_625, ", "))) or "Game confirmed: (none yet)"
                if #value_626 > 0 then
                    value_629[#value_629 + 1] = "Pending: " .. table.concat(value_626, ", ")
                end
                if value_627 and (tostring(value_627) ~= "") then
                    value_629[#value_629 + 1] = "Ghost on record: " .. tostring(value_627)
                end
                notify(table.concat(value_629, "\n"), 10)
                appendDetectionLog("Journal verify — confirmed: " .. ((next(value_625) and table.concat(value_625, ", ")) or "none") .. ((value_627 and (" | ghost=" .. tostring(value_627))) or ""))
            end)
        end,
    })
    local autoDetectGroup = evidenceTab:AddRightGroupbox("Auto-Detect Evidence")
    local autoDetectToggle = autoDetectGroup:AddToggle("AD_Detect", {
        ["Text"] = "Auto-detect evidence",
        ["Default"] = true,
        ["Tooltip"] = "Reads the game's real signals — handprints / orb / writing / wither, freezing, EMF 5, laser, spirit box — plus journal sync, and feeds the identifier.",
    })
    pcall(function()
        autoDetectToggle:AddKeyPicker("AD_DetectKey", {
            ["Default"] = "K",
            ["Mode"] = "Toggle",
            ["Text"] = "Auto-detect",
            ["SyncToggleState"] = true,
        })
    end)
    autoDetectGroup:AddSlider("AD_Freeze", {
        ["Text"] = "Freezing at ≤",
        ["Default"] = 0.5,
        ["Min"] = -5,
        ["Max"] = 10,
        ["Rounding"] = 1,
        ["Suffix"] = " °C",
    })
    local autoSpiritToggle = autoDetectGroup:AddToggle("AD_AutoSpirit", {
        ["Text"] = "Auto Spirit Box",
        ["Default"] = false,
        ["Tooltip"] = "Grabs + activates a Spirit Box, holds a steady ~8-stud distance from the ghost inside the house (no orbiting — anti-cheat safe), and asks every ~1.5s; pauses during a hunt.",
    })
    pcall(function()
        autoSpiritToggle:AddKeyPicker("AD_AutoSpiritKey", {
            ["Default"] = "P",
            ["Mode"] = "Toggle",
            ["Text"] = "Auto Spirit",
            ["SyncToggleState"] = true,
        })
    end)
    autoDetectGroup:AddButton({
        ["Text"] = "Reset auto-detected",
        ["Func"] = function()
            local value_512
            local value_513
            value_512 = nil
            value_513 = nil
            value_512 = {
            }
            for key_1356 in pairs(autoDetectedEvidence) do
                value_512[key_1356] = true
            end
            table.clear(autoDetectedEvidence)
            value_513 = Library.Options.ID_Confirmed
            if value_513 and (type(value_513.Value) == "table") then
                local value_1267
                value_1267 = {
                }
                for key_1481, value_1482 in pairs(value_513.Value) do
                    if value_1482 and not value_512[key_1481] then
                        value_1267[key_1481] = value_1482
                    end
                end
                pcall(function()
                    value_513:SetValue(value_1267)
                end)
            end
            notify("Cleared auto-detected evidence.")
        end,
    })
    local autoDetectedLabel = autoDetectGroup:AddLabel("Auto-detected: (none)", true)
    local function parseEvidenceSet(arg_514)
        local value_516
        value_516 = {
        }
        for iterator_1208 in tostring(arg_514):gmatch("[^,]+") do
            value_516[(iterator_1208:gsub("^%s+", ""):gsub("%s+$", ""))] = true
        end
        return value_516
    end
    local currentMissionGhost, wasInLobby = nil, false
    local previousGhostPosition_331, previousGhostSampleAt = nil, nil
    local function resetEvidenceDetectionState()
        for key_936 in pairs(autoDetectedEvidence) do
            autoDetectedEvidence[key_936] = nil
        end
        table.clear(journalMarkedEvidence)
        journalSelectedGhost = nil
        table.clear(journalConfirmedEvidence)
        pcall(function()
            Library.Options.ID_Confirmed:SetValue({
            })
        end)
        pcall(function()
            Library.Options.ID_RuledOut:SetValue({
            })
        end)
    end
    task.spawn(function()
        while running do
            local value_632
            local value_633
            value_632 = workspace:FindFirstChild("Ghost")
            value_633 = value_632 and (value_632:GetAttribute("IsGhost") == true)
            if not value_633 then
                if not wasInLobby then
                    wasInLobby = true
                    currentMissionGhost = nil
                    resetEvidenceDetectionState()
                    table.clear(recentGhostTells)
                end
                setControlText(possibleGhostsLabel, "In lobby — start a mission to detect.")
                setControlText(ghostTraitsLabel, "")
                setControlText(autoDetectedLabel, "")
                setControlText(ghostStateLabel, "State: no mission")
                setControlText(evidenceStatusLabel, "—")
                setControlText(autoGuessLabel, "—")
                singlePossibleGhost = nil
                detectionState.ghostType, detectionState.ghostPct, detectionState.ghostSpeed = nil, nil, nil
                task.wait(0.6)
            else
                local value_1110
                local value_1111
                local value_1112
                local value_1113
                local value_1114
                local value_1115
                local value_1116
                local value_1117
                local value_1118
                if value_632 ~= currentMissionGhost then
                    currentMissionGhost = value_632
                    resetEvidenceDetectionState()
                    table.clear(recentGhostTells)
                end
                wasInLobby = false
                value_1110 = {
                }
                for key_1374 in pairs(tableOption("ID_Confirmed")) do
                    value_1110[key_1374] = true
                end
                for key_1360 in pairs(autoDetectedEvidence) do
                    value_1110[key_1360] = true
                end
                local value_1363
                local value_1364
                value_1363 = 0
                for index_1536, item_1537 in ipairs(scanItems()) do
                    if item_1537.name == "EMF Reader" then
                        local value_1572
                        value_1572 = item_1537.inst:GetAttribute("ReadingLevel")
                        if (type(value_1572) == "number") and (value_1572 > value_1363) then
                            value_1363 = value_1572
                        end
                    end
                end
                value_1364 = {
                    "EMF reading: " .. (((value_1363 > 0) and ("Level " .. value_1363 .. "/5")) or "—"),
                }
                for index_1538, item_1539 in ipairs(evidenceDisplayOrder) do
                    if value_1110[item_1539] then
                        value_1364[#value_1364 + 1] = item_1539 .. ": YES"
                    end
                end
                setControlText(evidenceStatusLabel, table.concat(value_1364, "\n"))
                value_1111 = {
                }
                for key_1365 in pairs(tableOption("ID_RuledOut")) do
                    value_1111[key_1365] = true
                end
                if toggleEnabled("ID_AutoNeg") and detectionState.noOrb then
                    value_1111["Ghost Orb"] = true
                end
                value_1112, value_1113 = {
                }, nil
                value_1114 = value_632:GetAttribute("Gender")
                if value_1114 == "Male" then
                    value_1112.Keres = true
                    value_1112.Siren = true
                    value_1113 = "Gender Male → Keres & Siren ruled out"
                end
                value_1115 = {
                }
                for key_1358, value_1359 in pairs(GhostEvidence) do
                    if not value_1112[key_1358] then
                        local value_1484
                        local value_1485
                        value_1484 = parseEvidenceSet(value_1359)
                        value_1485 = true
                        for key_1570 in pairs(value_1110) do
                            if not value_1484[key_1570] then
                                value_1485 = false
                                break
                            end
                        end
                        if value_1485 then
                            for key_1612 in pairs(value_1111) do
                                if value_1484[key_1612] then
                                    value_1485 = false
                                    break
                                end
                            end
                        end
                        if value_1485 then
                            value_1115[#value_1115 + 1] = key_1358
                        end
                    end
                end
                table.sort(value_1115)
                value_1116, value_1117 = 0, nil
                for key_1373 in pairs(value_1110) do
                    value_1116 = value_1116 + 1
                end
                if (value_1116 >= 4) and not value_1112.Skinwalker and GhostEvidence["Skinwalker"] then
                    local value_1441
                    local value_1442
                    value_1441, value_1442 = parseEvidenceSet(GhostEvidence["Skinwalker"]), true
                    for key_1559 in pairs(value_1441) do
                        if not value_1110[key_1559] then
                            value_1442 = false
                            break
                        end
                    end
                    if value_1442 then
                        value_1115 = {
                            "Skinwalker",
                        }
                        value_1117 = "4th evidence → Skinwalker (mimic faking an extra evidence)"
                    end
                end
                setControlText(possibleGhostsLabel, ("Possible (%d): %s%s%s"):format(#value_1115, ((#value_1115 > 0) and table.concat(value_1115, ", ")) or "none — re-check", (value_1113 and ("\n" .. value_1113)) or "", (value_1117 and ("\n" .. value_1117)) or ""))
                detectionState.possible = value_1115
                value_1118 = {
                }
                if #value_1115 <= 5 then
                    local value_1439
                    value_1439 = 0
                    for index_1557, item_1558 in ipairs(value_1115) do
                        if GHOST_TRAITS[item_1558] and (value_1439 < 3) then
                            value_1439 = value_1439 + 1
                            value_1118[#value_1118 + 1] = ("%s — %s"):format(item_1558, GHOST_TRAITS[item_1558])
                            if GHOST_TIPS[item_1558] then
                                value_1118[#value_1118 + 1 + 0] = ("    ↳ counter: %s"):format(GHOST_TIPS[item_1558])
                            end
                        end
                    end
                end
                setControlText(ghostTraitsLabel, table.concat(value_1118, "\n"))
                singlePossibleGhost = ((#value_1115 == 1) and value_1115[1]) or nil
                local value_1368
                local value_1369
                local value_1370
                value_1368, value_1369 = {
                }, 0
                for index_1597, item_1598 in ipairs(value_1115) do
                    local value_1600
                    local value_1601
                    local value_1602
                    value_1600 = parseEvidenceSet(GhostEvidence[item_1598])
                    value_1601 = 0
                    for key_1634 in pairs(value_1110) do
                        if value_1600[key_1634] then
                            value_1601 = value_1601 + 1
                        end
                    end
                    value_1602 = 1 + (value_1601 * 2)
                    if recentGhostTells[item_1598] and ((tick() - recentGhostTells[item_1598]) < 60) then
                        value_1602 = value_1602 + 4
                    end
                    value_1368[#value_1368 + 1] = {
                        ["name"] = item_1598,
                        s = value_1602,
                    }
                    value_1369 = value_1369 + value_1602
                end
                table.sort(value_1368, function(arg_1540, arg_1541)
                    return arg_1540.s > arg_1541.s
                end)
                if value_1368[1] then
                    detectionState.ghostType = value_1368[1].name
                    detectionState.ghostPct = ((value_1369 > 0) and math.floor(((value_1368[1].s / value_1369) * 100) + 0.5)) or 0
                else
                    detectionState.ghostType, detectionState.ghostPct = nil, nil
                end
                value_1370 = {
                    ("Model: %s    Gender: %s"):format(tostring(value_632:GetAttribute("VisualModel") or "—"), tostring(value_1114 or "—")),
                }
                if value_1113 then
                    value_1370[#value_1370 + 1] = value_1113
                end
                value_1370[#value_1370 + 1] = ("— Ranked guess (%d) —"):format(#value_1368)
                if #value_1368 == 0 then
                    value_1370[#value_1370 + 1] = "none — re-check evidence"
                else
                    for index_1574, item_1575 in ipairs(value_1368) do
                        if index_1574 > 3 then
                            break
                        end
                        local value_1576 = ((value_1369 > 0) and math.floor(((item_1575.s / value_1369) * 100) + 0.5)) or 0
                        value_1370[#value_1370 + 1] = ("%d. %s — %d%%%s"):format(index_1574, item_1575.name, value_1576, ((index_1574 == 1) and (#value_1368 == 1) and "  ✓") or "")
                    end
                end
                setControlText(autoGuessLabel, table.concat(value_1370, "\n"))
                if toggleEnabled("GH_Telemetry") then
                    local find_ghost_1431 = findGhost()
                    local text_1432, text_1433 = "—", "—"
                    if find_ghost_1431 then
                        local get_base_part_1505, get_root_part_1506 = getBasePart(find_ghost_1431), getRootPart()
                        if get_base_part_1505 and get_root_part_1506 then
                            text_1432 = ("%d studs"):format((get_base_part_1505.Position - get_root_part_1506.Position).Magnitude)
                        end
                        if get_base_part_1505 then
                            local value_1556
                            value_1556 = tick()
                            if previousGhostPosition_331 and previousGhostSampleAt and ((value_1556 - previousGhostSampleAt) > 0) then
                                local value_1630
                                value_1630 = (get_base_part_1505.Position - previousGhostPosition_331).Magnitude / (value_1556 - previousGhostSampleAt)
                                detectionState.ghostSpeed = ((value_1630 < 40) and math.floor(value_1630 + 0.5)) or nil
                                if detectionState.ghostSpeed then
                                    text_1433 = detectionState.ghostSpeed .. " studs/s"
                                end
                            end
                            previousGhostPosition_331, previousGhostSampleAt = get_base_part_1505.Position, value_1556
                        end
                    end
                    local text_1434 = "no ghost spawned"
                    if find_ghost_1431 then
                        text_1434 = ((find_ghost_1431:GetAttribute("Hunting") == true) and "HUNTING") or "spawned"
                    end
                    local value_1435 = find_ghost_1431 and find_ghost_1431:GetAttribute("VisualModel")
                    local value_1436 = find_ghost_1431 and find_ghost_1431:GetAttribute("Gender")
                    local value_1437 = (detectionState.roamPct and (detectionState.roamPct .. "% in fav room" .. (((detectionState.roamPct >= 80) and " (Specter-like)") or ""))) or "sampling..."
                    setControlText(ghostStateLabel, ("State: %s\nSpeed: %s\nDistance: %s\nRoaming: %s"):format(text_1434, text_1433, text_1432, value_1437))
                else
                    setControlText(ghostStateLabel, "State: telemetry off")
                end
                local value_1372
                value_1372 = {
                }
                for key_1603 in pairs(autoDetectedEvidence) do
                    value_1372[#value_1372 + 1] = key_1603
                end
                table.sort(value_1372)
                setControlText(autoDetectedLabel, "Auto-detected: " .. (((#value_1372 > 0) and table.concat(value_1372, ", ")) or "(none)"))
                task.wait(0.40000000000009095)
            end
        end
    end)
    local huntWarningGui, huntWarningLabel
    local function ensureHuntWarningGui()
        if huntWarningGui then
            return 
        end
        huntWarningGui = Instance.new("ScreenGui")
        huntWarningGui.Name = "vLn_DemoWarn"
        huntWarningGui.ResetOnSpawn = false
        huntWarningGui.IgnoreGuiInset = true
        pcall(function()
            huntWarningGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        end)
        huntWarningLabel = Instance.new("TextLabel")
        huntWarningLabel.Size = UDim2.new(1, 0, 0, 60)
        huntWarningLabel.Position = UDim2.new(0, 0, 0.12, 0)
        huntWarningLabel.BackgroundTransparency = 1
        huntWarningLabel.Font = Enum.Font.GothamBold
        huntWarningLabel.TextSize = 34
        huntWarningLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
        huntWarningLabel.TextStrokeTransparency = 0.3
        huntWarningLabel.Text = ""
        huntWarningLabel.Visible = false
        huntWarningLabel.Parent = huntWarningGui
    end
    local function isHuntActive(ghostModel_520)
        for index_938, item_939 in ipairs({
            ghostModel_520,
            findMap(),
            workspace,
        }) do
            if item_939 then
                for index_1211, item_1212 in ipairs({
                    "Hunting",
                    "IsHunting",
                    "Hunt",
                    "HuntActive",
                }) do
                    if item_939:GetAttribute(item_1212) == true then
                        return true
                    end
                end
            end
        end
        return false
    end
    local huntWasActive, huntHeartbeatAccumulator = false, 0
    trackConnection(RunService.Heartbeat:Connect(function(deltaTime_522)
        local huntActive
        local huntJustStarted
        if not running then
            return 
        end
        huntHeartbeatAccumulator = huntHeartbeatAccumulator + (deltaTime_522 or 0)
        if huntHeartbeatAccumulator < 0.19999999999998863 then
            return 
        end
        huntHeartbeatAccumulator = 0
        huntActive = isHuntActive(findGhost())
        huntJustStarted = huntActive and not huntWasActive
        huntWasActive = huntActive
        if huntJustStarted and toggleEnabled("GH_HuntAlert") then
            notify("⚠  HUNT STARTED!", 4)
        end
        if huntJustStarted and toggleEnabled("GH_AutoEscape") then
            teleportToBaseCamp()
        end
        if toggleEnabled("GH_Haunt") then
            ensureHuntWarningGui()
            huntWarningLabel.Visible = huntActive
            huntWarningLabel.Text = (huntActive and "⚠  HUNT ACTIVE ⚠ ") or ""
        elseif huntWarningLabel then
            huntWarningLabel.Visible = false
        end
    end))
    local espTab = addTab("ESP", "eye")
    local ghostEspGroup = espTab:AddLeftGroupbox("Ghost ESP")
    addColorPicker(ghostEspGroup:AddToggle("ESP_Ghost", {
        ["Text"] = "Ghost ESP",
        ["Default"] = false,
    }), "ESP_GhostColor", Color3.fromRGB(255, 70, 70))
    addColorPicker(ghostEspGroup:AddToggle("ESP_FavRoom", {
        ["Text"] = "Highlight favorite room",
        ["Default"] = false,
    }), "ESP_FavColor", Color3.fromRGB(170, 90, 230))
    addColorPicker(ghostEspGroup:AddToggle("ESP_Orb", {
        ["Text"] = "Ghost Orb ESP",
        ["Default"] = false,
        ["Tooltip"] = "Reveals the Ghost Orb part — it's normally invisible/dormant — so you can find and photograph it.",
    }), "ESP_OrbColor", Color3.fromRGB(120, 200, 255))
    addColorPicker(ghostEspGroup:AddToggle("ESP_Hand", {
        ["Text"] = "Handprint / Footprint ESP",
        ["Default"] = false,
        ["Tooltip"] = "Reveals every print in the Handprints folder — UV handprints AND footprints in salt — without a blacklight, each tagged by type.",
    }), "ESP_HandColor", Color3.fromRGB(255, 120, 220))
    local teammateEspGroup = espTab:AddRightGroupbox("Teammate ESP")
    addColorPicker(teammateEspGroup:AddToggle("ESP_Team", {
        ["Text"] = "Player ESP",
        ["Default"] = false,
    }), "ESP_TeamColor", Color3.fromRGB(80, 220, 120))
    teammateEspGroup:AddToggle("ESP_TeamHP", {
        ["Text"] = "Show energy/health on tag",
        ["Default"] = true,
    })
    local itemEspGroup = espTab:AddLeftGroupbox("Item ESP")
    addColorPicker(itemEspGroup:AddToggle("ESP_Item", {
        ["Text"] = "Item ESP",
        ["Default"] = false,
    }), "ESP_ItemColor", Color3.fromRGB(245, 190, 70))
    addColorPicker(itemEspGroup:AddToggle("ESP_Special", {
        ["Text"] = "Special items only",
        ["Default"] = false,
    }), "ESP_SpecialColor", Color3.fromRGB(60, 230, 180))
    local espFiltersGroup = espTab:AddRightGroupbox("Filters")
    espFiltersGroup:AddSlider("ESP_MaxDist", {
        ["Text"] = "Max distance",
        ["Default"] = 1000,
        ["Min"] = 50,
        ["Max"] = 5000,
        ["Rounding"] = 0,
        ["Suffix"] = " studs",
    })
    espFiltersGroup:AddToggle("ESP_AppendDist", {
        ["Text"] = "Append distance to tags",
        ["Default"] = true,
    })
    espFiltersGroup:AddSlider("ESP_Rate", {
        ["Text"] = "ESP update rate",
        ["Default"] = 30,
        ["Min"] = 5,
        ["Max"] = 60,
        ["Rounding"] = 0,
        ["Suffix"] = " Hz",
        ["Tooltip"] = "Lower = lighter on performance. The ESP refreshes at this many times per second.",
    })
    local playerBillboards = {
    }
    local function removePlayerBillboard(player_526)
        local billboard_527 = playerBillboards[player_526]
        if billboard_527 then
            pcall(function()
                billboard_527:Destroy()
            end)
            playerBillboards[player_526] = nil
        end
    end
    local function getPlayerBillboardLabel(player_528, rootPart_529)
        local billboard_530 = playerBillboards[player_528]
        if not billboard_530 then
            billboard_530 = Instance.new("BillboardGui")
            billboard_530.Size = UDim2.fromOffset(200, 30)
            billboard_530.StudsOffset = Vector3.new(0, 3, 0)
            billboard_530.AlwaysOnTop = true
            billboard_530.Adornee = rootPart_529
            billboard_530.Parent = rootPart_529
            local result_686 = Instance.new("TextLabel")
            result_686.BackgroundTransparency = 1
            result_686.Size = UDim2.fromScale(1, 1)
            result_686.Font = Enum.Font.GothamSemibold
            result_686.TextSize = 13
            result_686.TextStrokeTransparency = 0.4
            result_686.Name = "L"
            result_686.Parent = billboard_530
            playerBillboards[player_528] = billboard_530
        end
        billboard_530.Adornee = rootPart_529
        return billboard_530.L
    end
    local espAccumulator = 0
    trackConnection(RunService.Heartbeat:Connect(function(deltaTime_532)
        if not running then
            return 
        end
        espAccumulator = espAccumulator + (deltaTime_532 or 0)
        if espAccumulator < (1 / math.max(1, numericOption("ESP_Rate", 30))) then
            return 
        end
        espAccumulator = 0
        local localRootPart = getRootPart()
        local maxEspDistance = numericOption("ESP_MaxDist", 1000)
        local appendDistance = toggleEnabled("ESP_AppendDist")
        local function isWithinEspDistance(arg_634)
            if not (localRootPart and arg_634) then
                return true
            end
            return (arg_634.Position - localRootPart.Position).Magnitude <= maxEspDistance
        end
        if toggleEnabled("ESP_Ghost") then
            local value_697
            local value_698
            value_697 = findGhost()
            value_698 = optionDefault("ESP_GhostColor", Color3.fromRGB(255, 70, 70))
            setHighlight("ghost", value_697, value_698, 0.5)
            if value_697 then
                local gender_1214 = value_697:GetAttribute("Gender")
                local get_base_part_1215 = getBasePart(value_697)
                local value_1216 = (gender_1214 and tostring(gender_1214)) or "Ghost"
                if value_697:GetAttribute("Hunting") == true then
                    value_1216 = "HUNTING · " .. value_1216
                end
                if appendDistance and localRootPart and get_base_part_1215 then
                    value_1216 = value_1216 .. ("  %dm"):format(math.floor((get_base_part_1215.Position - localRootPart.Position).Magnitude))
                end
                if (value_697:GetAttribute("Hunting") == true) and detectionState.ghostSpeed then
                    value_1216 = value_1216 .. (" · %d/s"):format(detectionState.ghostSpeed)
                end
                if detectionState.ghostType then
                    value_1216 = value_1216 .. "\n» " .. detectionState.ghostType .. ((detectionState.ghostPct and (" (" .. detectionState.ghostPct .. "%)")) or "")
                end
                setBillboard("ghost", value_697, value_1216, value_698)
            else
                removeBillboard("ghost")
            end
        else
            removeHighlight("ghost")
            removeBillboard("ghost")
        end
        if toggleEnabled("ESP_FavRoom") then
            local find_ghost_699 = findGhost()
            local find_map_700 = findMap()
            local value_701 = find_ghost_699 and (find_ghost_699:GetAttribute("FavoriteRoom") or find_ghost_699:GetAttribute("FavouriteRoom"))
            local value_702 = find_map_700 and find_map_700:FindFirstChild("Rooms")
            local value_703 = value_701 and value_702 and value_702:FindFirstChild(value_701)
            local option_default_704 = optionDefault("ESP_FavColor", Color3.fromRGB(170, 90, 230))
            setHighlight("favroom", value_703, option_default_704, 0.85)
            setBillboard("favroom", value_703, (value_703 and ("Favorite room: " .. value_701)) or nil, option_default_704)
        else
            removeHighlight("favroom")
            removeBillboard("favroom")
        end
        if toggleEnabled("ESP_Orb") then
            local value_707
            local value_708
            value_707 = workspace:FindFirstChild("GhostOrb")
            value_708 = optionDefault("ESP_OrbColor", Color3.fromRGB(120, 200, 255))
            if value_707 and value_707:IsA("BasePart") and isWithinEspDistance(value_707) then
                setHighlight("orb", value_707, value_708, 0.2)
                local text_1217 = "Ghost Orb"
                if appendDistance and localRootPart then
                    text_1217 = text_1217 .. ("  %dm"):format(math.floor((value_707.Position - localRootPart.Position).Magnitude))
                end
                setBillboard("orb", value_707, text_1217, value_708)
            else
                removeHighlight("orb")
                removeBillboard("orb")
            end
        else
            removeHighlight("orb")
            removeBillboard("orb")
        end
        if toggleEnabled("ESP_Hand") then
            local value_710
            local value_711
            local value_712
            local value_713
            value_710 = workspace:FindFirstChild("Handprints")
            value_711 = optionDefault("ESP_HandColor", Color3.fromRGB(255, 120, 220))
            value_712, value_713 = {
            }, 0
            if value_710 then
                for index_1268, item_1269 in ipairs(value_710:GetChildren()) do
                    if item_1269:IsA("BasePart") and isWithinEspDistance(item_1269) then
                        value_713 = value_713 + 1
                        local text_1376 = "hand_" .. value_713
                        value_712[text_1376] = true
                        setHighlight(text_1376, item_1269, value_711, 0.2)
                        local value_1378 = (item_1269.Name:find("Footprint") and "Footprint") or "Handprint"
                        if appendDistance and localRootPart then
                            value_1378 = value_1378 .. ("  %dm"):format(math.floor((item_1269.Position - localRootPart.Position).Magnitude))
                        end
                        setBillboard(text_1376, item_1269, value_1378, value_711)
                    end
                end
            end
            for key_1133 in pairs(Highlights) do
                if (key_1133:sub(1, 5) == "hand_") and not value_712[key_1133] then
                    removeHighlight(key_1133)
                end
            end
            for key_1134 in pairs(Billboards) do
                if (key_1134:sub(1, 5) == "hand_") and not value_712[key_1134] then
                    removeBillboard(key_1134)
                end
            end
        else
            for key_1309 in pairs(Highlights) do
                if key_1309:sub(1, 5) == "hand_" then
                    removeHighlight(key_1309)
                end
            end
            for key_1310 in pairs(Billboards) do
                if key_1310:sub(1, 5) == "hand_" then
                    removeBillboard(key_1310)
                end
            end
        end
        if toggleEnabled("ESP_Item") then
            local table_716, toggle_enabled_717, number_718 = {
            }, toggleEnabled("ESP_Special"), 0
            local option_default_719 = optionDefault("ESP_ItemColor", Color3.fromRGB(245, 190, 70))
            local option_default_720 = optionDefault("ESP_SpecialColor", Color3.fromRGB(60, 230, 180))
            for index_811, item_812 in ipairs(scanItems()) do
                local value_813 = item_812.cat == "cursed"
                if not toggle_enabled_717 or value_813 then
                    local value_1047
                    value_1047 = getBasePart(item_812.inst)
                    if value_1047 and isWithinEspDistance(value_1047) then
                        local value_1380
                        local value_1381
                        local value_1382
                        number_718 = number_718 + 1
                        value_1380 = "item_" .. number_718
                        table_716[value_1380] = true
                        value_1381 = (value_813 and option_default_720) or option_default_719
                        if (item_812.name == "Cross") and (item_812.inst:GetAttribute("Burned") == true) then
                            value_1381 = Color3.fromRGB(125, 125, 125)
                        end
                        setHighlight(value_1380, item_812.inst, value_1381, 0.5)
                        value_1382 = item_812.name
                        if item_812.name == "Cross" then
                            value_1382 = ((item_812.inst:GetAttribute("Burned") == true) and "Cross (BURNT)") or "Cross (active)"
                        end
                        if appendDistance and localRootPart then
                            value_1382 = value_1382 .. ("  %dm"):format(math.floor((value_1047.Position - localRootPart.Position).Magnitude))
                        end
                        setBillboard(value_1380, item_812.inst, value_1382, value_1381)
                    end
                end
            end
            for key_814 in pairs(Highlights) do
                if (key_814:sub(1, 5) == "item_") and not table_716[key_814] then
                    removeHighlight(key_814)
                end
            end
            for key_815 in pairs(Billboards) do
                if (key_815:sub(1, 5) == "item_") and not table_716[key_815] then
                    removeBillboard(key_815)
                end
            end
        else
            for key_816 in pairs(Highlights) do
                if key_816:sub(1, 5) == "item_" then
                    removeHighlight(key_816)
                end
            end
            for key_817 in pairs(Billboards) do
                if key_817:sub(1, 5) == "item_" then
                    removeBillboard(key_817)
                end
            end
        end
        local teamEspEnabled = toggleEnabled("ESP_Team")
        for index_636, item_637 in ipairs(Players:GetPlayers()) do
            if item_637 ~= LocalPlayer then
                local character_818 = item_637.Character
                local value_819 = character_818 and character_818:FindFirstChild("HumanoidRootPart")
                local value_820 = character_818 and character_818:FindFirstChildOfClass("Humanoid")
                local value_821 = teamEspEnabled and value_819 and value_820 and (value_820.Health > 0) and isWithinEspDistance(value_819)
                if value_821 then
                    local value_1049
                    local value_1050
                    setHighlight("team_" .. item_637.Name, character_818, optionDefault("ESP_TeamColor", Color3.fromRGB(80, 220, 120)), 0.7)
                    value_1049 = getPlayerBillboardLabel(item_637, value_819)
                    value_1050 = item_637.Name
                    if toggleEnabled("ESP_TeamHP") then
                        local value_1384
                        value_1384 = item_637:GetAttribute("Energy") or item_637:GetAttribute("Stamina")
                        value_1050 = ("%s  [%d hp%s]"):format(item_637.Name, math.floor(value_820.Health), (value_1384 and (" • " .. tostring(math.floor(value_1384)) .. "e")) or "")
                    end
                    if appendDistance and localRootPart then
                        value_1050 = value_1050 .. ("  %dm"):format(math.floor((value_819.Position - localRootPart.Position).Magnitude))
                    end
                    value_1049.Text = value_1050
                    value_1049.TextColor3 = optionDefault("ESP_TeamColor", Color3.fromRGB(80, 220, 120))
                else
                    removeHighlight("team_" .. item_637.Name)
                    removePlayerBillboard(item_637)
                end
            end
        end
    end))
    Players.PlayerRemoving:Connect(function(player_538)
        removePlayerBillboard(player_538)
        removeHighlight("team_" .. player_538.Name)
    end)
    local itemsTab = addTab("Items", "box")
    local worldItemsGroup = itemsTab:AddLeftGroupbox("World Items")
    local worldItemCountLabel = worldItemsGroup:AddLabel("Items in world: —", true)
    worldItemsGroup:AddToggle("IT_Counter", {
        ["Text"] = "Live item counter",
        ["Default"] = true,
    })
    worldItemsGroup:AddToggle("IT_CrossAlert", {
        ["Text"] = "Alert when a Cross is used",
        ["Default"] = true,
        ["Tooltip"] = "Notifies the moment a Cross gets burned (it floats/burns when it prevents a hunt). Burnt crosses also turn grey on the Item ESP.",
    })
    worldItemsGroup:AddButton({
        ["Text"] = "List items to console",
        ["Func"] = function()
            local items = scanItems()
            print(("[vLnware] %d world items:"):format(#items))
            for index_638, item_639 in ipairs(items) do
                print(("  %s [%s] @ %s"):format(item_639.name, item_639.cat, item_639.inst:GetFullName()))
            end
            notify(("Listed %d items to console."):format(#items))
        end,
    })
    local itemPlacementRunning = false
    worldItemsGroup:AddToggle("IT_PlaceActive", {
        ["Text"] = "Activate items before dropping",
        ["Default"] = true,
        ["Tooltip"] = "Right-click (ToggleItemState) each item on before dropping it in the ghost room.",
    })
    local function startItemPlacement()
        if itemPlacementRunning then
            return 
        end
        local rootPart_542 = getRootPart()
        if not rootPart_542 then
            notify("No character.")
            return 
        end
        itemPlacementRunning = true
        task.spawn(function()
            while itemPlacementRunning and running do
                local ghost_722 = workspace:FindFirstChild("Ghost")
                if ghost_722 and (ghost_722:GetAttribute("Hunting") == true) then
                    itemPlacementRunning = false
                    notify("Stopped — hunt started.", 4)
                    break
                end
                task.wait(0.1)
            end
        end)
        task.spawn(function()
            local function countOccupiedInventorySlots()
                local number_723 = 0
                for index_822 = 1, 3 do
                    if (LocalPlayer:GetAttribute("InvSlot" .. index_822) or "") ~= "" then
                        number_723 = number_723 + 1
                    end
                end
                return number_723
            end
            local function isGhostHunting()
                local value_725
                value_725 = findGhost()
                return value_725 and (value_725:GetAttribute("Hunting") == true)
            end
            local activatableItems = {
                ["Spirit Box"] = true,
                ["Blacklight"] = true,
                ["EMF Reader"] = true,
                ["Laser Projector"] = true,
                ["Thermometer"] = true,
                ["Flashlight"] = true,
            }
            local bringableItems = {
                ["Blacklight"] = true,
                ["EMF Reader"] = true,
                ["Flashlight"] = true,
                ["Flower Pot"] = true,
                ["Laser Projector"] = true,
                ["Spirit Book"] = true,
                ["Spirit Box"] = true,
                ["Thermometer"] = true,
                ["Video Camera"] = true,
                ["Photo Camera"] = true,
            }
            local placementCandidates = {
            }
            for index_726, item_727 in ipairs(scanItems()) do
                local current_room_728 = item_727.inst:GetAttribute("CurrentRoom")
                if bringableItems[item_727.name] and (not current_room_728 or (current_room_728 == "Base Camp")) then
                    placementCandidates[#placementCandidates + 1 + 0] = item_727
                end
            end
            local placedCount, pickupFailureCount, candidateCount_647, ghostRoomMissing, candidateIndex = 0, 0, #placementCandidates, false, 1
            while (candidateIndex <= #placementCandidates) and itemPlacementRunning and running do
                if isGhostHunting() then
                    notify("Stopped — hunt active.")
                    break
                end
                local table_729 = {
                }
                while (#table_729 < 3) and (candidateIndex <= #placementCandidates) and itemPlacementRunning and running do
                    local value_824
                    local value_825
                    local value_826
                    value_824 = placementCandidates[candidateIndex]
                    candidateIndex = candidateIndex + 1
                    value_825, value_826 = countOccupiedInventorySlots(), false
                    for index_1385 = 1, 4 do
                        if not (itemPlacementRunning and running) then
                            break
                        end
                        local get_base_part_1386 = getBasePart(value_824.inst)
                        if not get_base_part_1386 then
                            break
                        end
                        rootPart_542.CFrame = get_base_part_1386.CFrame + Vector3.new(0, 2.5, 0)
                        task.wait(0.3)
                        fireEvent("RequestItemPickup", value_824.inst)
                        task.wait(0.3)
                        if countOccupiedInventorySlots() > value_825 then
                            value_826 = true
                            break
                        end
                        task.wait(0.25)
                    end
                    if value_826 then
                        table_729[#table_729 + 1] = value_824
                    else
                        pickupFailureCount = pickupFailureCount + 1
                    end
                end
                if #table_729 == 0 then
                    break
                end
                local find_ghost_room_cframe_730 = findGhostRoomCFrame()
                if not find_ghost_room_cframe_730 then
                    ghostRoomMissing = true
                end
                for index_827, item_828 in ipairs(table_729) do
                    if not (itemPlacementRunning and running) then
                        break
                    end
                    if isGhostHunting() then
                        itemPlacementRunning = false
                        notify("Stopped — hunt started.", 4)
                        break
                    end
                    if find_ghost_room_cframe_730 then
                        local value_1053
                        local value_1054
                        local value_1055
                        local value_1056
                        local value_1057
                        value_1053, value_1054 = placedCount % 3, math.floor(placedCount / 3)
                        value_1055, value_1056 = find_ghost_room_cframe_730.X + ((value_1053 - 1) * 2.5), find_ghost_room_cframe_730.Z + ((value_1054 - 1) * 2.5)
                        value_1057 = groundY(value_1055, value_1056, find_ghost_room_cframe_730.Y)
                        if not value_1057 then
                            value_1055, value_1056, value_1057 = find_ghost_room_cframe_730.X, find_ghost_room_cframe_730.Z, groundY(find_ghost_room_cframe_730.X, find_ghost_room_cframe_730.Z, find_ghost_room_cframe_730.Y)
                        end
                        if value_1057 then
                            rootPart_542.CFrame = CFrame.new(value_1055, value_1057 + 3, value_1056)
                            task.wait(0.3)
                        end
                    end
                    fireEvent("RequestItemEquip", "InvSlot1")
                    task.wait(0.25)
                    if toggleEnabled("IT_PlaceActive") and activatableItems[item_828.name] then
                        for index_1137 = 1, 3 do
                            if item_828.inst:GetAttribute("Enabled") == true then
                                break
                            end
                            fireEvent("ToggleItemState", item_828.inst)
                            task.wait(0.25)
                        end
                    end
                    fireEvent("RequestItemDrop", "InvSlot1")
                    task.wait(0.25)
                    placedCount = placedCount + 1
                end
            end
            itemPlacementRunning = false
            local placementSummary = ("Placed %d/%d candidate(s)%s%s."):format(placedCount, candidateCount_647, ((pickupFailureCount > 0) and (", " .. pickupFailureCount .. " pickup-failed")) or "", (ghostRoomMissing and " — GHOST ROOM NOT FOUND") or "")
            if candidateCount_647 == 0 then
                placementSummary = "No items to bring (none are bringable gear sitting at Base Camp — already placed, or held)."
            end
            notify(placementSummary, 8)
            pcall(function()
                if Library.Toggles and Library.Toggles.IT_Place then
                    Library.Toggles.IT_Place:SetValue(false)
                end
            end)
        end)
    end
    local autoPlaceToggle = worldItemsGroup:AddToggle("IT_Place", {
        ["Text"] = "Auto-place items in ghost room",
        ["Default"] = false,
        ["Tooltip"] = "Carries all bringable gear to the ghost room, 3 at a time, then turns itself off.",
    })
    pcall(function()
        autoPlaceToggle:AddKeyPicker("IT_PlaceKey", {
            ["Default"] = "I",
            ["Mode"] = "Toggle",
            ["Text"] = "Place items",
            ["SyncToggleState"] = true,
        })
    end)
    task.spawn(function()
        local previousAutoPlaceToggle
        previousAutoPlaceToggle = false
        while running do
            local value_942
            value_942 = toggleEnabled("IT_Place")
            if value_942 and not previousAutoPlaceToggle then
                startItemPlacement()
            end
            previousAutoPlaceToggle = value_942
            task.wait(0.20000000000004547)
        end
    end)
    task.spawn(function()
        local burnedCrosses
        burnedCrosses = {
        }
        while running do
            if toggleEnabled("IT_CrossAlert") then
                for index_1391, item_1392 in ipairs(scanItems()) do
                    if item_1392.name == "Cross" then
                        if item_1392.inst:GetAttribute("Burned") == true then
                            if not burnedCrosses[item_1392.inst] then
                                burnedCrosses[item_1392.inst] = true
                                notify("A Cross was just used (burned) — a hunt was prevented.", 5)
                            end
                        else
                            burnedCrosses[item_1392.inst] = nil
                        end
                    end
                end
            end
            task.wait(0.39999999999997726)
        end
    end)
    task.spawn(function()
        while running do
            if toggleEnabled("IT_Counter") then
                setControlText(worldItemCountLabel, ("Items in world: %d"):format(#scanItems()))
            else
                setControlText(worldItemCountLabel, "Items in world: off")
            end
            task.wait(1)
        end
    end)
    local playerTab
    local movementGroup
    local noclipToggle
    local selfGroup
    local playerStatusLabel
    playerTab = addTab("Player", "user")
    movementGroup = playerTab:AddLeftGroupbox("Movement")
    movementGroup:AddLabel("⚠ Server-authoritative — may revert/kick.", true)
    movementGroup:AddToggle("PL_SpeedOn", {
        ["Text"] = "Custom WalkSpeed",
        ["Default"] = false,
        ["Risky"] = true,
    })
    movementGroup:AddSlider("PL_Speed", {
        ["Text"] = "WalkSpeed",
        ["Default"] = 16,
        ["Min"] = 16,
        ["Max"] = 60,
        ["Rounding"] = 0,
    })
    movementGroup:AddToggle("PL_JumpOn", {
        ["Text"] = "Custom JumpPower",
        ["Default"] = false,
        ["Risky"] = true,
    })
    movementGroup:AddSlider("PL_Jump", {
        ["Text"] = "JumpPower",
        ["Default"] = 50,
        ["Min"] = 50,
        ["Max"] = 150,
        ["Rounding"] = 0,
    })
    noclipToggle = movementGroup:AddToggle("PL_Noclip", {
        ["Text"] = "Noclip",
        ["Default"] = false,
        ["Risky"] = true,
    })
    pcall(function()
        noclipToggle:AddKeyPicker("PL_NoclipKey", {
            ["Default"] = "N",
            ["Mode"] = "Toggle",
            ["Text"] = "Noclip",
            ["SyncToggleState"] = true,
        })
    end)
    selfGroup = playerTab:AddRightGroupbox("Self")
    playerStatusLabel = selfGroup:AddLabel("Room: —\nHP: —   Energy: —", true)
    trackConnection(RunService.Heartbeat:Connect(function()
        if not running then
            return 
        end
        local get_humanoid_831 = getHumanoid()
        if get_humanoid_831 then
            if toggleEnabled("PL_SpeedOn") then
                get_humanoid_831.WalkSpeed = numericOption("PL_Speed", 16)
            end
            if toggleEnabled("PL_JumpOn") then
                get_humanoid_831.UseJumpPower = true
                get_humanoid_831.JumpPower = numericOption("PL_Jump", 50)
            end
        end
    end))
    trackConnection(RunService.Stepped:Connect(function()
        local value_830
        if not running or not toggleEnabled("PL_Noclip") then
            return 
        end
        value_830 = getCharacter()
        if value_830 then
            for index_1311, item_1312 in ipairs(value_830:GetDescendants()) do
                if item_1312:IsA("BasePart") and item_1312.CanCollide then
                    item_1312.CanCollide = false
                end
            end
        end
    end))
    task.spawn(function()
        while running do
            local value_945
            local value_946
            value_945 = getHumanoid()
            value_946 = LocalPlayer:GetAttribute("Energy") or LocalPlayer:GetAttribute("Stamina")
            setControlText(playerStatusLabel, ("Room: %s\nHP: %s   Energy: %s"):format(tostring(LocalPlayer:GetAttribute("CurrentRoom") or "—"), (value_945 and tostring(math.floor(value_945.Health))) or "—", (value_946 and tostring(math.floor(value_946))) or "—"))
            task.wait(0.5)
        end
    end)
    local visualsTab = addTab("Visuals", "sun")
    local lightingGroup = visualsTab:AddLeftGroupbox("Lighting & Camera")
    lightingGroup:AddToggle("VIS_Fullbright", {
        ["Text"] = "Fullbright",
        ["Default"] = false,
    })
    lightingGroup:AddSlider("VIS_Bright", {
        ["Text"] = "Brightness",
        ["Default"] = 2,
        ["Min"] = 1,
        ["Max"] = 5,
        ["Rounding"] = 1,
    })
    lightingGroup:AddToggle("VIS_NoFog", {
        ["Text"] = "No Fog",
        ["Default"] = false,
    })
    lightingGroup:AddToggle("VIS_FOVOn", {
        ["Text"] = "Custom FOV",
        ["Default"] = false,
    })
    lightingGroup:AddSlider("VIS_FOV", {
        ["Text"] = "Field of view",
        ["Default"] = 70,
        ["Min"] = 40,
        ["Max"] = 120,
        ["Rounding"] = 0,
    })
    local originalLighting = {
        ["Brightness"] = Lighting.Brightness,
        ["ClockTime"] = Lighting.ClockTime,
        ["GlobalShadows"] = Lighting.GlobalShadows,
        ["Ambient"] = Lighting.Ambient,
        ["OutdoorAmbient"] = Lighting.OutdoorAmbient,
        ["FogStart"] = Lighting.FogStart,
        ["FogEnd"] = Lighting.FogEnd,
    }
    local fullbrightApplied, fogOverrideApplied, fovOverrideApplied, originalFov = false, false, false, nil
    trackConnection(RunService.RenderStepped:Connect(function()
        if not running then
            return 
        end
        local fullbrightEnabled = toggleEnabled("VIS_Fullbright")
        if fullbrightEnabled then
            Lighting.Brightness = numericOption("VIS_Bright", 2)
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        elseif fullbrightApplied then
            Lighting.Brightness = originalLighting.Brightness
            Lighting.ClockTime = originalLighting.ClockTime
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.Ambient = originalLighting.Ambient
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        end
        fullbrightApplied = fullbrightEnabled
        local noFogEnabled = toggleEnabled("VIS_NoFog")
        if noFogEnabled then
            Lighting.FogStart = 1000000000
            Lighting.FogEnd = 1000000000
        elseif fogOverrideApplied then
            Lighting.FogStart = originalLighting.FogStart
            Lighting.FogEnd = originalLighting.FogEnd
        end
        fogOverrideApplied = noFogEnabled
        local camera = workspace.CurrentCamera
        local customFovEnabled = toggleEnabled("VIS_FOVOn")
        if camera then
            if customFovEnabled then
                if not originalFov then
                    originalFov = camera.FieldOfView
                end
                camera.FieldOfView = numericOption("VIS_FOV", 70)
            elseif fovOverrideApplied and originalFov then
                camera.FieldOfView = originalFov
                originalFov = nil
            end
        end
        fovOverrideApplied = customFovEnabled
    end))
    local evidenceSignals = {
        ["EMF Level 5"] = "EMF Level 5",
        ["EMFLevel5"] = "EMF Level 5",
        [1] = "EMF Level 5",
        ["Spirit Box"] = "Spirit Box",
        ["SpiritBox"] = "Spirit Box",
        [2] = "Spirit Box",
        ["Inscription"] = "Inscription",
        ["GhostWriting"] = "Inscription",
        [3] = "Inscription",
        ["Freezing Temperatures"] = "Freezing Temperatures",
        ["FreezingTemperatures"] = "Freezing Temperatures",
        [4] = "Freezing Temperatures",
        ["Ghost Orb"] = "Ghost Orb",
        ["GhostOrb"] = "Ghost Orb",
        [5] = "Ghost Orb",
        ["Prints"] = "Prints",
        ["Handprints"] = "Prints",
        [6] = "Prints",
        ["Laser Projector"] = "Laser Projector",
        ["LaserProjector"] = "Laser Projector",
        [7] = "Laser Projector",
        ["Wither"] = "Wither",
        [8] = "Wither",
    }
    local function normalizeEvidenceName(evidenceName_551)
        local normalized
        local alias
        local canonicalEvidence_555
        normalized = Library and Library.Options and Library.Options.ID_Confirmed
        if not normalized then
            return 
        end
        alias, canonicalEvidence_555 = normalized.Value, {
        }
        if type(alias) == "table" then
            for key_1139, value_1140 in pairs(alias) do
                if value_1140 then
                    canonicalEvidence_555[key_1139] = value_1140
                end
            end
        end
        if canonicalEvidence_555[evidenceName_551] then
            return 
        end
        canonicalEvidence_555[evidenceName_551] = true
        pcall(function()
            normalized:SetValue(canonicalEvidence_555)
        end)
    end
    local function markEvidenceDetected(evidenceName_556)
        if not ghostFlagActive() then
            return 
        end
        if evidenceName_556 and not autoDetectedEvidence[evidenceName_556] then
            autoDetectedEvidence[evidenceName_556] = true
            normalizeEvidenceName(evidenceName_556)
            notify("Evidence detected: " .. evidenceName_556, 3)
            appendDetectionLog("Evidence: " .. evidenceName_556)
        end
    end
    local function connectEvidenceSignal(remote)
        if (type(remote) == "number") or (type(remote) == "string") then
            markEvidenceDetected(evidenceSignals[remote])
        end
    end
    local eventsFolder_377 = Events or ReplicatedStorage:FindFirstChild("Events")
    local lastWritingCount, lastEmfTimestamp, missionStartedAt = 0, nil, 0
    local objectWitheredEvent = eventsFolder_377 and eventsFolder_377:FindFirstChild("ObjectWithered")
    if objectWitheredEvent and objectWitheredEvent:IsA("RemoteEvent") then
        trackConnection(objectWitheredEvent.OnClientEvent:Connect(function()
            if toggleEnabled("AD_Detect") then
                markEvidenceDetected("Wither")
            end
        end))
    end
    local journalEvidenceEvent = eventsFolder_377 and eventsFolder_377:FindFirstChild("EvidenceMarkedInJournal")
    local askSpiritBoxEvent = eventsFolder_377 and eventsFolder_377:FindFirstChild("AskSpiritBoxFromUI")
    local lastSpiritQuestionAt = 0
    local spiritBoxResponses = {
    }
    for signalIndex, signalDefinition in ipairs({
        "RequestItemPickup",
        "RequestItemDrop",
        "ToggleItemState",
        "ChangeSelectedItem",
        "RequestItemEquip",
        "RequestItemUnequip",
        "ForceChangeItemState",
    }) do
        local connection_563
        connection_563 = eventsFolder_377 and eventsFolder_377:FindFirstChild(signalDefinition)
        if connection_563 then
            spiritBoxResponses[connection_563] = signalDefinition
        end
    end
    if journalEvidenceEvent and journalEvidenceEvent:IsA("RemoteEvent") then
        trackConnection(journalEvidenceEvent.OnClientEvent:Connect(function(...)
            for index_834, item_835 in ipairs({
                ...,
            }) do
                local value_837
                value_837 = evidenceSignals[item_835]
                if value_837 then
                    journalConfirmedEvidence[value_837] = true
                end
                if toggleEnabled("AD_Detect") then
                    connectEvidenceSignal(item_835)
                end
            end
        end))
    end
    if askSpiritBoxEvent and askSpiritBoxEvent:IsA("RemoteEvent") then
        trackConnection(askSpiritBoxEvent.OnClientEvent:Connect(function()
            if toggleEnabled("AD_Detect") then
                markEvidenceDetected("Spirit Box")
            end
        end))
    end
    local function findActiveSpiritBox()
        local spiritBox_565
        local itemPart
        spiritBox_565 = LocalPlayer:FindFirstChild("PlayerGui")
        itemPart = spiritBox_565 and spiritBox_565:FindFirstChild("SpiritBoxQuestions")
        if not (itemPart and itemPart:IsA("ScreenGui")) then
            return false
        end
        if itemPart.Enabled == false then
            return false
        end
        for index_953, item_954 in ipairs(itemPart:GetDescendants()) do
            if item_954:IsA("GuiObject") and item_954.Visible and (item_954.AbsoluteSize.X > 1) then
                return true
            end
        end
        return itemPart.Enabled == true
    end
    local subtitleEvent = eventsFolder_377 and eventsFolder_377:FindFirstChild("ShowSubtitle")
    if subtitleEvent and subtitleEvent:IsA("RemoteEvent") then
        trackConnection(subtitleEvent.OnClientEvent:Connect(function(...)
            if not toggleEnabled("AD_Detect") then
                return 
            end
            if ((tick() - lastSpiritQuestionAt) < 8) or findActiveSpiritBox() then
                markEvidenceDetected("Spirit Box")
            end
            for index_1315, item_1316 in ipairs({
                ...,
            }) do
                if (type(item_1316) == "string") and item_1316:upper():find("HUMMING") then
                    hint("Siren")
                    break
                end
            end
        end))
    end
    startToggleLoop("AD_Detect", 0.5, function()
        if findActiveSpiritBox() then
            lastSpiritQuestionAt = tick()
        end
    end)
    startToggleLoop("AD_Detect", 1, function()
        local ghostContainer_567 = workspace:FindFirstChild("Ghost")
        local missionActive = ghostContainer_567 and (ghostContainer_567:GetAttribute("IsGhost") == true)
        if missionActive then
            local handprints_737 = workspace:FindFirstChild("Handprints")
            if handprints_737 then
                for index_1060, item_1061 in ipairs(handprints_737:GetChildren()) do
                    if item_1061.Name:find("Handprint") then
                        markEvidenceDetected("Prints")
                        break
                    end
                end
            end
            if ghostContainer_567:GetAttribute("LaserVisible") == true then
                markEvidenceDetected("Laser Projector")
            end
            local last_emflevel5_time_738 = ghostContainer_567:GetAttribute("LastEMFLevel5Time")
            if (type(last_emflevel5_time_738) == "number") and (last_emflevel5_time_738 > 0) then
                markEvidenceDetected("EMF Level 5")
            end
            if (ghostContainer_567:GetAttribute("SpiritBoxReplied") == true) or (ghostContainer_567:GetAttribute("RespondedToSpiritBox") == true) then
                markEvidenceDetected("Spirit Box")
            end
            if ghostContainer_567 ~= lastEmfTimestamp then
                lastEmfTimestamp = ghostContainer_567
                missionStartedAt = tick()
                lastWritingCount = 0
            end
            local ghost_orb_739 = workspace:FindFirstChild("GhostOrb")
            if ((tick() - missionStartedAt) > 15) and ghost_orb_739 then
                lastWritingCount = lastWritingCount + 1
                if lastWritingCount >= 3 then
                    markEvidenceDetected("Ghost Orb")
                end
            else
                lastWritingCount = 0
            end
            detectionState.noOrb = ((tick() - missionStartedAt) > 15) and not ghost_orb_739
        else
            lastEmfTimestamp, missionStartedAt, lastWritingCount = nil, 0, 0
            detectionState.noOrb = false
        end
        local mapModel_569 = findMap()
        local roomsFolder_570 = mapModel_569 and mapModel_569:FindFirstChild("Rooms")
        local freezingThreshold = numericOption("AD_Freeze", 0.5)
        if roomsFolder_570 then
            for index_838, item_839 in ipairs(roomsFolder_570:GetChildren()) do
                local temperature_840 = item_839:GetAttribute("Temperature")
                if (type(temperature_840) == "number") and (temperature_840 ~= 0) and (temperature_840 <= freezingThreshold) then
                    markEvidenceDetected("Freezing Temperatures")
                    break
                end
            end
        end
        for index_651, item_652 in ipairs(scanItems()) do
            if item_652.name == "Thermometer" then
                local value_842
                local value_843
                local value_844
                value_842 = item_652.inst:GetAttribute("LocalTempModifier")
                value_843 = item_652.inst:GetAttribute("CurrentRoom")
                value_844 = value_843 and roomsFolder_570 and roomsFolder_570:FindFirstChild(value_843) and roomsFolder_570:FindFirstChild(value_843):GetAttribute("Temperature")
                if (type(value_842) == "number") and (type(value_844) == "number") and (value_844 ~= 0) and ((value_844 + value_842) <= freezingThreshold) then
                    markEvidenceDetected("Freezing Temperatures")
                end
            elseif (item_652.name == "EMF Reader") and (item_652.inst:GetAttribute("ReadingLevel") == 5) then
                markEvidenceDetected("EMF Level 5")
            elseif item_652.name == "Flower Pot" then
                if item_652.inst:GetAttribute("PhotoRewardType") == "WitheredFlowers" then
                    markEvidenceDetected("Wither")
                end
            elseif item_652.name == "Spirit Book" then
                if item_652.inst:GetAttribute("PhotoRewardType") == "Inscription" then
                    markEvidenceDetected("Inscription")
                else
                    for index_1486, item_1487 in ipairs(item_652.inst:GetDescendants()) do
                        if item_1487:IsA("Decal") and (tostring(item_1487.Texture) ~= "") then
                            markEvidenceDetected("Inscription")
                            break
                        end
                    end
                end
            end
        end
    end)
    local spiritBoxQuestions = {
        "Are you in the room with me?",
        "How long ago did you die?",
        "Why are you here?",
        "When did you pass away?",
        "What do you want?",
    }
    local function askSpiritQuestion(question)
        for index_1230, item_1231 in ipairs(scanItems()) do
            if item_1231.name == "Spirit Box" then
                local value_1317
                for index_1396 = 1, 4 do
                    local get_base_part_1397 = getBasePart(item_1231.inst)
                    if not get_base_part_1397 then
                        break
                    end
                    local table_1398 = {
                    }
                    for index_1448 = 1, 3 do
                        table_1398[index_1448] = LocalPlayer:GetAttribute("InvSlot" .. index_1448) or ""
                    end
                    question.CFrame = get_base_part_1397.CFrame + Vector3.new(0, 2.5, 0)
                    task.wait(0.3)
                    fireEvent("RequestItemPickup", item_1231.inst)
                    task.wait(0.3)
                    for index_1450 = 1, 3 do
                        local value_1451 = LocalPlayer:GetAttribute("InvSlot" .. index_1450) or ""
                        if (value_1451 ~= "") and (value_1451 ~= table_1398[index_1450]) then
                            value_1317 = "InvSlot" .. index_1450
                            break
                        end
                    end
                    if value_1317 then
                        break
                    end
                    task.wait(0.25)
                end
                if not value_1317 then
                    return nil
                end
                fireEvent("RequestItemEquip", value_1317)
                task.wait(0.25)
                for index_1400 = 1, 3 do
                    if item_1231.inst:GetAttribute("Enabled") == true then
                        break
                    end
                    fireEvent("ToggleItemState", item_1231.inst)
                    task.wait(0.25)
                end
                return item_1231.inst
            end
        end
        return nil
    end
    local evidenceLoopAccumulator, spiritLoopAccumulator = 0, 0
    local lastGhostOrb, lastGhostOrbSeenAt = nil, 0
    startToggleLoop("AD_AutoSpirit", 0.3, function()
        local ghostModel_575
        local ghostPart_576
        local playerRoot
        local spiritBox_578
        local spiritBoxPart
        ghostModel_575 = findGhost()
        if not ghostModel_575 then
            return 
        end
        if ghostModel_575:GetAttribute("Hunting") == true then
            return 
        end
        ghostPart_576, playerRoot = getBasePart(ghostModel_575), getRootPart()
        if not (ghostPart_576 and playerRoot) then
            return 
        end
        if not (lastGhostOrb and lastGhostOrb.Parent) then
            if (tick() - lastGhostOrbSeenAt) > 3 then
                lastGhostOrbSeenAt = tick()
                lastGhostOrb = askSpiritQuestion(playerRoot)
            end
        elseif lastGhostOrb:GetAttribute("Enabled") ~= true then
            fireEvent("ToggleItemState", lastGhostOrb)
            task.wait(0.15)
        end
        spiritBox_578 = (playerRoot.Position - ghostPart_576.Position) * Vector3.new(1, 0, 1)
        spiritBoxPart = spiritBox_578.Magnitude
        if (spiritBoxPart < 5) or (spiritBoxPart > 14) then
            local value_1063 = ((spiritBoxPart > 0.1) and spiritBox_578.Unit) or Vector3.new(0, 0, 1)
            playerRoot.CFrame = CFrame.lookAt(ghostPart_576.Position + (value_1063 * 8) + Vector3.new(0, 2, 0), ghostPart_576.Position)
        end
        evidenceLoopAccumulator = evidenceLoopAccumulator + 1
        if (evidenceLoopAccumulator % 5) == 0 then
            local value_1066
            value_1066 = eventsFolder_377 and eventsFolder_377:FindFirstChild("AskSpiritBoxFromUI")
            if value_1066 and value_1066:IsA("RemoteEvent") then
                spiritLoopAccumulator = (spiritLoopAccumulator % #spiritBoxQuestions) + 1
                pcall(function()
                    value_1066:FireServer(spiritBoxQuestions[spiritLoopAccumulator])
                end)
                lastSpiritQuestionAt = tick()
            end
        end
    end)
    local settingsTab = addTab("UI Settings", "settings")
    local miscSettingsGroup = settingsTab:AddLeftGroupbox("Misc")
    pcall(function()
        miscSettingsGroup:AddLabel("Menu toggle key"):AddKeyPicker("MenuKeybind", {
            ["Default"] = "RightControl",
            ["NoUI"] = true,
            ["Text"] = "Menu toggle",
        })
        Library.ToggleKeybind = Library.Options.MenuKeybind
    end)
    miscSettingsGroup:AddButton({
        ["Text"] = "Unload",
        ["Func"] = function()
            running = false
            if getgenv then
                getgenv().vLnware_DEMO = nil
                getgenv().vLnware_DEMO_Unload = nil
            end
            pcall(function()
                Library:Unload()
            end)
        end,
    })
    miscSettingsGroup:AddButton({
        ["Text"] = "Forget saved key (re-key)",
        ["Func"] = function()
            pcall(function()
                if (type(delfile) == "function") and (type(isfile) == "function") and isfile("vilanxware/key.txt") then
                    delfile("vilanxware/key.txt")
                end
            end)
            if getgenv then
                getgenv().script_key = nil
                getgenv().vLnware_DEMO = nil
                getgenv().vLnware_DEMO_Unload = nil
            end
            notify("Saved key forgotten. Unloading — re-execute the loader to enter a new key.", 7)
            running = false
            pcall(function()
                Library:Unload()
            end)
        end,
    })
    miscSettingsGroup:AddButton({
        ["Text"] = "Clear UI cache (redownload)",
        ["Func"] = function()
            clearUiCache()
            notify("UI cache cleared — re-downloads next launch.")
        end,
    })
    local debugGroup = settingsTab:AddRightGroupbox("Debug")
    debugGroup:AddButton({
        ["Text"] = "Copy debug info",
        ["Func"] = function()
            local debugStatusLabel
            local debugScanButton
            local debugJournalButton
            local clearCacheButton
            local unloadButton
            debugStatusLabel = workspace:FindFirstChild("Ghost")
            debugScanButton = 0
            for key_958 in pairs(autoDetectedEvidence) do
                debugScanButton = debugScanButton + 1 + 0
            end
            debugJournalButton = "?"
            pcall(function()
                if identifyexecutor then
                    debugJournalButton = tostring((identifyexecutor()))
                end
            end)
            clearCacheButton = table.concat({
                "vilanxware " .. BUILD_NAME,
                "exec=" .. debugJournalButton,
                "place=" .. tostring(game.PlaceId) .. " game=" .. tostring(game.GameId),
                "state=" .. ((ghostFlagActive() and "mission") or "lobby"),
                "ghost=" .. ((debugStatusLabel and tostring(debugStatusLabel:GetAttribute("VisualModel"))) or "-") .. " guess=" .. (detectionState.ghostType or "-"),
                "evidence=" .. debugScanButton,
            }, " | ")
            unloadButton = setclipboard or toclipboard or (syn and syn.write_clipboard)
            if unloadButton then
                pcall(unloadButton, clearCacheButton)
            end
            notify("Debug info copied to clipboard.", 5)
        end,
    })
    if DISABLE_TELEPORT_QUEUE then
        debugGroup:AddLabel("Run INSIDE a mission, then send the saved file.", true)
        debugGroup:AddButton({
            ["Text"] = "Dump captured remote calls",
            ["Func"] = function()
                local debugOutput
                if #remoteCallLog == 0 then
                    notify("None yet — manually mark an evidence / pick up / drop an item first.", 6)
                    return 
                end
                print("[vLnware] === captured remote calls (journal + spirit + items) ===")
                for index_1144, item_1145 in ipairs(remoteCallLog) do
                    print("  " .. item_1145)
                end
                debugOutput = table.concat(remoteCallLog, "\n")
                if hasFileApi() then
                    pcall(function()
                        writefile("vLnware/Demonology_item_calls.txt", debugOutput)
                    end)
                    notify("Saved -> vLnware/Demonology_item_calls.txt", 6)
                else
                    notify(("Printed %d call(s) to console."):format(#remoteCallLog), 6)
                end
            end,
        })
        debugGroup:AddButton({
            ["Text"] = "Dump journal pages (open EVIDENCE tab first)",
            ["Func"] = function()
                local playerGui_748 = LocalPlayer:FindFirstChild("PlayerGui")
                local journalGui = playerGui_748 and playerGui_748:FindFirstChild("Journal")
                if not journalGui then
                    notify("Journal GUI not found — are you in a mission?", 6)
                    return 
                end
                pcall(function()
                    journalGui.Enabled = true
                end)
                task.wait(0.15)
                local getConnectionsAvailable = type(getconnections) == "function"
                local function appendJournalLine(arg_849)
                    local value_851
                    value_851 = arg_849
                    while value_851 and (value_851 ~= journalGui) do
                        if value_851:IsA("GuiObject") and (value_851.Visible == false) then
                            return false
                        end
                        value_851 = value_851.Parent
                    end
                    return true
                end
                local function describeGuiObject(arg_852)
                    local value_854
                    local value_855
                    if not (getConnectionsAvailable and arg_852) then
                        return "?"
                    end
                    value_854, value_855 = pcall(getconnections, arg_852.MouseButton1Click)
                    return (value_854 and tostring(#value_855)) or "err"
                end
                local journalDumpLines = {
                    "== Journal PAGES dump (open the EVIDENCE tab before clicking) ==",
                    "getconnections available: " .. tostring(getConnectionsAvailable),
                }
                local function walkGuiTree(arg_856, arg_857)
                    local value_859
                    if not arg_856 then
                        return 
                    end
                    value_859 = {
                    }
                    for index_1237, item_1238 in ipairs(arg_856:GetChildren()) do
                        if item_1238:IsA("GuiObject") then
                            local value_1319
                            value_1319 = item_1238:FindFirstChild("Detection")
                            value_859[#value_859 + 1] = item_1238.Name .. ((value_1319 and (" <Detection " .. value_1319.ClassName .. " MB1=" .. describeGuiObject(value_1319) .. ">")) or "")
                        end
                    end
                    journalDumpLines[#journalDumpLines + 1] = ("    %s (visible=%s): %s"):format(arg_857, tostring(appendJournalLine(arg_856)), table.concat(value_859, ", "))
                end
                local journalPages = journalGui:FindFirstChild("Holder") and journalGui.Holder:FindFirstChild("Pages")
                if journalPages then
                    for index_1069, item_1070 in ipairs(journalPages:GetChildren()) do
                        journalDumpLines[#journalDumpLines + 1 + 0] = ("PAGE [%s] visible=%s"):format(item_1070.Name, tostring(appendJournalLine(item_1070)))
                        for index_1320, item_1321 in ipairs({
                            "Left",
                            "Right",
                        }) do
                            local value_1324
                            local value_1325
                            value_1324 = nil
                            value_1325 = nil
                            value_1324 = item_1070:FindFirstChild(item_1321)
                            value_1325 = value_1324 and value_1324:FindFirstChild("Page")
                            if value_1325 then
                                walkGuiTree(value_1325:FindFirstChild("EvidenceTypes"), item_1321 .. ".EvidenceTypes")
                                walkGuiTree(value_1325:FindFirstChild("GhostTypes"), item_1321 .. ".GhostTypes")
                            end
                        end
                    end
                else
                    journalDumpLines[#journalDumpLines + 1 + 0] = "Holder.Pages not found."
                end
                journalDumpLines[#journalDumpLines + 1] = "-- VISIBLE 'Detection' buttons (the open tab's real targets) --"
                for index_860, item_861 in ipairs(journalGui:GetDescendants()) do
                    if (item_861.Name == "Detection") and item_861:IsA("GuiButton") and appendJournalLine(item_861) then
                        journalDumpLines[#journalDumpLines + 1 + 0] = "  " .. item_861:GetFullName()
                    end
                end
                local journalDumpText = table.concat(journalDumpLines, "\n")
                if hasFileApi() then
                    pcall(function()
                        writefile("vLnware/Demonology_journal_pages.txt", journalDumpText)
                    end)
                    notify("Saved -> vLnware/Demonology_journal_pages.txt", 6)
                else
                    print(journalDumpText)
                    notify("Printed to console (no file access).", 6)
                end
            end,
        })
        debugGroup:AddButton({
            ["Text"] = "Scan mission now",
            ["Func"] = function()
                local scanLines = {
                }
                local function appendScanLine(arg_862)
                    scanLines[#scanLines + 1] = arg_862
                end
                appendScanLine("== vLnware Demonology mission scan ==")
                appendScanLine("PlaceId: " .. tostring(game.PlaceId))
                local mapModel_760 = findMap()
                appendScanLine("Map: " .. ((mapModel_760 and mapModel_760:GetFullName()) or "NOT FOUND (lobby / not in mission)"))
                if mapModel_760 then
                    local value_965
                    local value_966
                    appendScanLine("Map children:")
                    for index_1283, item_1284 in ipairs(mapModel_760:GetChildren()) do
                        appendScanLine(("  [%s] %s"):format(item_1284.ClassName, item_1284.Name))
                    end
                    value_965 = mapModel_760:FindFirstChild("FuseBox")
                    if value_965 then
                        local value_1328
                        value_1328 = {
                        }
                        for key_1580, value_1581 in pairs(value_965:GetAttributes()) do
                            value_1328[#value_1328 + 1] = key_1580 .. "=" .. tostring(value_1581)
                        end
                        appendScanLine("FuseBox attrs: " .. ((next(value_1328) and table.concat(value_1328, ", ")) or "none"))
                        appendScanLine("FuseBox tree:")
                        for index_1515, item_1516 in ipairs(value_965:GetDescendants()) do
                            local value_1518
                            value_1518 = {
                            }
                            for key_1639, value_1640 in pairs(item_1516:GetAttributes()) do
                                value_1518[#value_1518 + 1] = key_1639 .. "=" .. tostring(value_1640)
                            end
                            appendScanLine(("  [%s] %s%s"):format(item_1516.ClassName, item_1516.Name, ((#value_1518 > 0) and ("  {" .. table.concat(value_1518, ", ") .. "}")) or ""))
                        end
                    end
                    value_966 = mapModel_760:FindFirstChild("Rooms")
                    if value_966 then
                        appendScanLine("Rooms (" .. #value_966:GetChildren() .. "):")
                        for index_1511, item_1512 in ipairs(value_966:GetChildren()) do
                            local value_1514
                            value_1514 = item_1512:FindFirstChild("LightSwitch")
                            appendScanLine(("  - %s%s"):format(item_1512.Name, (value_1514 and (" [LightSwitch State=" .. tostring(value_1514:GetAttribute("State")) .. "]")) or ""))
                        end
                    end
                end
                local ghostModel_761 = findGhost()
                appendScanLine("Ghost candidate: " .. ((ghostModel_761 and ghostModel_761:GetFullName()) or "none"))
                if ghostModel_761 then
                    local value_968
                    value_968 = {
                    }
                    for key_1285, value_1286 in pairs(ghostModel_761:GetAttributes()) do
                        value_968[#value_968 + 1] = key_1285 .. "=" .. tostring(value_1286)
                    end
                    table.sort(value_968)
                    appendScanLine("  attributes: " .. ((next(value_968) and table.concat(value_968, ", ")) or "none"))
                end
                appendScanLine("Local player attributes:")
                local value_865
                value_865 = {
                }
                for key_1239, value_1240 in pairs(LocalPlayer:GetAttributes()) do
                    value_865[#value_865 + 1 + 0] = key_1239 .. "=" .. tostring(value_1240)
                end
                table.sort(value_865)
                appendScanLine("  " .. ((next(value_865) and table.concat(value_865, ", ")) or "none"))
                local attributesSucceeded, ghostAttributes = pcall(function()
                    return CollectionService:GetAllTags()
                end)
                if attributesSucceeded and (type(ghostAttributes) == "table") and (#ghostAttributes > 0) then
                    appendScanLine("Tags: " .. table.concat(ghostAttributes, ", "))
                end
                appendScanLine("Hiding-spot candidates (closet/locker/hide):")
                for index_866, item_867 in ipairs(workspace:GetDescendants()) do
                    local value_869
                    value_869 = item_867.Name:lower()
                    if value_869:find("closet") or value_869:find("locker") or value_869:find("hid") then
                        appendScanLine(("  - [%s] %s"):format(item_867.ClassName, item_867:GetFullName()))
                    end
                end
                appendScanLine("World items (" .. #scanItems() .. "):")
                for index_870, item_871 in ipairs(scanItems()) do
                    appendScanLine(("  - %s [%s] @ %s"):format(item_871.name, item_871.cat, item_871.inst:GetFullName()))
                end
                appendScanLine("Evidence-object state:")
                local ghost_orb_872 = workspace:FindFirstChild("GhostOrb")
                if ghost_orb_872 then
                    local value_1074
                    value_1074 = {
                    }
                    for key_1490, value_1491 in pairs(ghost_orb_872:GetAttributes()) do
                        value_1074[#value_1074 + 1] = key_1490 .. "=" .. tostring(value_1491)
                    end
                    appendScanLine(("  GhostOrb [%s] Transparency=%s Parent=%s children=%d attrs={%s}"):format(ghost_orb_872.ClassName, tostring((ghost_orb_872:IsA("BasePart") and ghost_orb_872.Transparency) or "n/a"), (ghost_orb_872.Parent and ghost_orb_872.Parent.Name) or "nil", #ghost_orb_872:GetChildren(), table.concat(value_1074, ", ")))
                else
                    appendScanLine("  GhostOrb: not found")
                end
                for index_969, item_970 in ipairs({
                    "Airballs",
                    "Handprints",
                    "ScratchText",
                    "EffectHolder",
                    "SaltPiles",
                    "BrokenGlass",
                }) do
                    local find_first_child_971 = workspace:FindFirstChild(item_970)
                    local value_972 = (find_first_child_971 and find_first_child_971:GetChildren()) or {
                    }
                    local table_973 = {
                    }
                    for index_1075 = 1, math.min(#value_972, 5) do
                        table_973[index_1075] = value_972[index_1075].ClassName .. ":" .. value_972[index_1075].Name
                    end
                    appendScanLine(("  %s: %d child(ren)%s"):format(item_970, #value_972, ((#table_973 > 0) and (" [" .. table.concat(table_973, ", ") .. "]")) or ""))
                end
                for index_974, item_975 in ipairs({
                    "Handprints",
                    "SaltPiles",
                }) do
                    local value_977
                    value_977 = workspace:FindFirstChild(item_975)
                    if value_977 then
                        for index_1405, item_1406 in ipairs(value_977:GetChildren()) do
                            local value_1408
                            value_1408 = {
                            }
                            for key_1543, value_1544 in pairs(item_1406:GetAttributes()) do
                                value_1408[#value_1408 + 1] = key_1543 .. "=" .. tostring(value_1544)
                            end
                            appendScanLine(("  %s child [%s] %s attrs={%s}"):format(item_975, item_1406.ClassName, item_1406.Name, table.concat(value_1408, ", ")))
                        end
                    end
                end
                for index_978, item_979 in ipairs(scanItems()) do
                    if (item_979.name == "Spirit Book") or (item_979.name == "Flower Pot") then
                        local table_1147 = {
                        }
                        for key_1242, value_1243 in pairs(item_979.inst:GetAttributes()) do
                            table_1147[#table_1147 + 1 + 0] = key_1242 .. "=" .. tostring(value_1243)
                        end
                        appendScanLine(("  %s @ %s attrs={%s}"):format(item_979.name, item_979.inst:GetFullName(), table.concat(table_1147, ", ")))
                        for index_1245, item_1246 in ipairs(item_979.inst:GetDescendants()) do
                            local value_1248
                            local value_1249
                            value_1248 = {
                            }
                            for key_1452, value_1453 in pairs(item_1246:GetAttributes()) do
                                value_1248[#value_1248 + 1] = key_1452 .. "=" .. tostring(value_1453)
                            end
                            value_1249 = ((item_1246:IsA("Decal") or item_1246:IsA("Texture")) and (" Texture=" .. tostring(item_1246.Texture))) or ""
                            if item_1246:IsA("BasePart") then
                                value_1249 = value_1249 .. " T=" .. tostring(item_1246.Transparency)
                            end
                            appendScanLine(("    [%s] %s%s%s"):format(item_1246.ClassName, item_1246.Name, value_1249, ((#value_1248 > 0) and (" {" .. table.concat(value_1248, ", ") .. "}")) or ""))
                        end
                    end
                end
                for index_980, item_981 in ipairs({
                    "BoardPapers",
                }) do
                    local value_983
                    local value_984
                    value_983, value_984 = pcall(function()
                        return CollectionService:GetTagged(item_981)
                    end)
                    if value_983 and (type(value_984) == "table") and value_984[1] then
                        appendScanLine(("  %s (%d): %s"):format(item_981, #value_984, value_984[1]:GetFullName()))
                    end
                end
                for index_985, item_986 in ipairs(workspace:GetDescendants()) do
                    local value_988
                    value_988 = item_986.Name:lower()
                    if value_988:find("writ") or value_988:find("scribble") or value_988:find("ink") or value_988:find("paper") then
                        appendScanLine(("  name~write: [%s] %s"):format(item_986.ClassName, item_986:GetFullName()))
                    end
                end
                appendScanLine("All item attrs:")
                for index_989, item_990 in ipairs(scanItems()) do
                    local value_992
                    value_992 = {
                    }
                    for key_1289, value_1290 in pairs(item_990.inst:GetAttributes()) do
                        value_992[#value_992 + 1] = key_1289 .. "=" .. tostring(value_1290)
                    end
                    table.sort(value_992)
                    appendScanLine(("  %s [%s] {%s}"):format(item_990.name, item_990.cat, table.concat(value_992, ", ")))
                end
                appendScanLine("ReplicatedStorage children:")
                for index_873, item_874 in ipairs(ReplicatedStorage:GetChildren()) do
                    appendScanLine(("  [%s] %s"):format(item_874.ClassName, item_874.Name))
                end
                local eventsFolder_764 = ReplicatedStorage:FindFirstChild("Events")
                if eventsFolder_764 then
                    appendScanLine("Events remotes:")
                    for index_1292, item_1293 in ipairs(eventsFolder_764:GetChildren()) do
                        appendScanLine(("  [%s] %s"):format(item_1293.ClassName, item_1293.Name))
                    end
                end
                appendScanLine("Workspace top-level:")
                for index_875, item_876 in ipairs(workspace:GetChildren()) do
                    appendScanLine(("  [%s] %s"):format(item_876.ClassName, item_876.Name))
                end
                local mapModel_765 = findMap()
                local roomsFolder_766 = mapModel_765 and mapModel_765:FindFirstChild("Rooms")
                if roomsFolder_766 then
                    appendScanLine("Room temperatures:")
                    for index_1077, item_1078 in ipairs(roomsFolder_766:GetChildren()) do
                        local value_1080
                        value_1080 = item_1078:GetAttribute("Temperature")
                        if value_1080 ~= nil then
                            appendScanLine(("  %s = %s"):format(item_1078.Name, tostring(value_1080)))
                        end
                    end
                end
                for index_877, item_878 in ipairs(scanItems()) do
                    if item_878.name == "Thermometer" then
                        appendScanLine(("Thermometer: CurrentRoom=%s LocalTempModifier=%s"):format(tostring(item_878.inst:GetAttribute("CurrentRoom")), tostring(item_878.inst:GetAttribute("LocalTempModifier"))))
                    end
                end
                appendScanLine("Tag examples:")
                for index_879, item_880 in ipairs({
                    "Item",
                    "DisturbedSalt",
                    "LightSwitch",
                    "Door",
                    "Mirror",
                    "FortuneTeller",
                    "MagnifyingGlass",
                    "Candle",
                    "Lamp",
                }) do
                    local value_882
                    local value_883
                    value_882, value_883 = pcall(function()
                        return CollectionService:GetTagged(item_880)
                    end)
                    if value_882 and (type(value_883) == "table") and value_883[1] then
                        local value_1295
                        value_1295 = {
                        }
                        for key_1560, value_1561 in pairs(value_883[1]:GetAttributes()) do
                            value_1295[#value_1295 + 1] = key_1560 .. "=" .. tostring(value_1561)
                        end
                        appendScanLine(("  %s (%d): %s%s"):format(item_880, #value_883, value_883[1]:GetFullName(), (next(value_1295) and ("  {" .. table.concat(value_1295, ", ") .. "}")) or ""))
                    end
                end
                if ghostModel_761 then
                    appendScanLine("Ghost children:")
                    for index_1081, item_1082 in ipairs(ghostModel_761:GetChildren()) do
                        appendScanLine(("  [%s] %s"):format(item_1082.ClassName, item_1082.Name))
                    end
                end
                local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")
                if modulesFolder then
                    appendScanLine("RS.Modules children:")
                    for index_1296, item_1297 in ipairs(modulesFolder:GetChildren()) do
                        appendScanLine(("  [%s] %s"):format(item_1297.ClassName, item_1297.Name))
                    end
                end
                local function dumpTable(arg_884, arg_885, arg_886)
                    for key_995, value_996 in pairs(arg_884) do
                        local value_998
                        value_998 = type(value_996)
                        if value_998 == "table" then
                            local value_1330
                            local value_1331
                            value_1330, value_1331 = {
                            }, 0
                            for key_1519, value_1520 in pairs(value_996) do
                                value_1331 = value_1331 + 1
                                if value_1331 <= 12 then
                                    value_1330[#value_1330 + 1 + 0] = tostring(key_1519) .. "=" .. tostring(value_1520)
                                end
                            end
                            appendScanLine(("%s%s = { %s }"):format(arg_885, tostring(key_995), table.concat(value_1330, ", ")))
                            if arg_886 > 0 then
                                dumpTable(value_996, arg_885 .. "  ", arg_886 - 1)
                            end
                        elseif value_998 ~= "function" then
                            appendScanLine(("%s%s = %s"):format(arg_885, tostring(key_995), tostring(value_996)))
                        end
                    end
                end
                if modulesFolder then
                    local value_1000
                    local value_1001
                    value_1000 = modulesFolder:FindFirstChild("EvidenceTypes")
                    if value_1000 then
                        local ok_1334, result_1335 = pcall(require, value_1000)
                        if ok_1334 and (type(result_1335) == "table") then
                            appendScanLine("EvidenceTypes module:")
                            dumpTable(result_1335, "  ", 1)
                        end
                    end
                    value_1001 = modulesFolder:FindFirstChild("GhostTypes")
                    if value_1001 then
                        appendScanLine("GhostTypes modules (REAL evidence combos):")
                        for index_1585, item_1586 in ipairs(value_1001:GetChildren()) do
                            if item_1586:IsA("ModuleScript") then
                                local value_1619
                                local value_1620
                                value_1619 = nil
                                value_1620 = nil
                                value_1619, value_1620 = pcall(require, item_1586)
                                appendScanLine(("  --- %s ---"):format(item_1586.Name))
                                if value_1619 and (type(value_1620) == "table") then
                                    dumpTable(value_1620, "    ", 1)
                                else
                                    appendScanLine("    (require failed: " .. tostring(value_1620) .. ")")
                                end
                            end
                        end
                    end
                end
                local playerGui_769 = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui_769 then
                    appendScanLine("PlayerGui top-level:")
                    for index_1083, item_1084 in ipairs(playerGui_769:GetChildren()) do
                        appendScanLine(("  [%s] %s"):format(item_1084.ClassName, item_1084.Name))
                    end
                    local journal_1002 = playerGui_769:FindFirstChild("Journal")
                    if journal_1002 then
                        local value_1149
                        appendScanLine("Journal tree (open it to the ghost list first):")
                        value_1149 = 0
                        for index_1409, item_1410 in ipairs(journal_1002:GetDescendants()) do
                            value_1149 = value_1149 + 1
                            if value_1149 <= 200 then
                                appendScanLine(("  [%s] %s"):format(item_1410.ClassName, item_1410.Name))
                            end
                        end
                        if value_1149 > 200 then
                            appendScanLine(("  …(+%d more)"):format(value_1149 - 200))
                        end
                    end
                end
                appendScanLine("Named-signal candidates (hunt/evidence/favorite/journal):")
                local candidateCount_770, seenSignalNames = 0, {
                }
                for index_887, item_888 in ipairs(workspace:GetDescendants()) do
                    local value_890
                    value_890 = item_888.Name:lower()
                    if (value_890:find("hunt") or value_890:find("evidence") or value_890:find("favorite") or value_890:find("favourite") or value_890:find("journal")) and not seenSignalNames[item_888.Name] then
                        seenSignalNames[item_888.Name] = true
                        candidateCount_770 = candidateCount_770 + 1
                        if candidateCount_770 <= 25 then
                            appendScanLine(("  [%s] %s"):format(item_888.ClassName, item_888:GetFullName()))
                        end
                    end
                end
                local scanText = table.concat(scanLines, "\n")
                print(scanText)
                if hasFileApi() then
                    pcall(function()
                        if (type(makefolder) == "function") and (type(isfolder) == "function") and not isfolder("vLnware") then
                            makefolder("vLnware")
                        end
                        writefile("vLnware/Demonology_mission_scan.txt", scanText)
                    end)
                    notify("Scan saved -> vLnware/Demonology_mission_scan.txt", 6)
                else
                    notify("Scan printed to console (no file access).", 6)
                end
            end,
        })
    end
    pcall(function()
        if SaveManager then
            SaveManager:SetLibrary(Library)
            SaveManager:IgnoreThemeSettings()
            pcall(function()
                SaveManager:SetIgnoreIndexes({
                    "ID_Confirmed",
                    "ID_RuledOut",
                })
            end)
            SaveManager:SetFolder("vLnware/Demonology")
        end
        if ThemeManager then
            ThemeManager:SetLibrary(Library)
            ThemeManager:SetFolder("vLnware/Demonology")
        end
        if SaveManager then
            SaveManager:BuildConfigSection(settingsTab)
        end
        if ThemeManager then
            ThemeManager:ApplyToTab(settingsTab)
        end
        if SaveManager then
            SaveManager:LoadAutoloadConfig()
        end
    end)
    pcall(function()
        Library.Options.ID_Confirmed:SetValue({
        })
    end)
    pcall(function()
        Library.Options.ID_RuledOut:SetValue({
        })
    end)
    notify(HUB_NAME .. " " .. BUILD_NAME .. " loaded.", 5)
    task.delay(2, function()
        notify("Join the Discord: " .. DISCORD_INVITE, 10)
    end)
end
runMainSafely()
