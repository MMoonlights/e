# Moonlights Farm Boxes

A focused Unboxing Simulator farm with a custom loader and animated menu.

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/e/main/Unbs.lua"))()
```

## Structure

- `Unbs.lua` compatibility entry point
- `loader.lua` animated loader
- `src/main.lua` application bootstrap
- `src/ui.lua` custom interface and notifications
- `src/farm.lua` Farm Boxes engine

The farm locks the field where it is enabled and does not move into another location. Disable and enable it again after moving to a different field.
