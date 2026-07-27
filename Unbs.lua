if not game:IsLoaded() then
    game.Loaded:Wait()
end

local source = game:HttpGet(
    "https://raw.githubusercontent.com/MMoonlights/e/main/loader.lua"
)

local chunk, compileError = loadstring(source)

assert(chunk, compileError)
return chunk()
