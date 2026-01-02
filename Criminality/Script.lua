local Interface = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/main/source.lua", true))()

local InterfaceSettings = {
  Name = "Criminality",
  Subtitle = "https://github.com/MMoonlights",
  LogoID = "77782645018929",
  LoadingEnabled = true,
  LoadingTitle = "MMoonlights",
  LoadingSubtitle = "Loading...",
  ConfigSettings = {
    RootFolder = nil,
    ConfigFolder = "Criminality",
  },
  KeySystem = false,
}

local Window = Interface:CreateWindow(InterfaceSettings)

local AimTab = Window:CreateTab({
  Name = "Aim",
  Icon = "110743239876005",
  ImageSource = "Custom",
  ShowTitle = true,
})

local EspTab = Window:CreateTab({
  Name = "Esp",
  Icon = "93700138170227",
  ImageSource = "Custom",
  ShowTitle = true,
})

local ModsTab = Window:CreateTab({
  Name = "Mods",
  Icon = "109205628721611",
  ImageSource = "Custom",
  ShowTitle = true,
})

AimTab:CreateButton({
  Name = "Aimbot",
  Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/e/refs/heads/main/Criminality/Aim/Aim.lua"))()
  end,
})

EspTab:CreateButton({
  Name = "ESP",
  Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/e/refs/heads/main/Criminality/Esp/Esp.lua"))()
  end,
})

ModsTab:CreateButton({
  Name = "No Recoil",
  Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/e/refs/heads/main/Criminality/Utility/No%20Recoil.lua"))()
  end,
})
