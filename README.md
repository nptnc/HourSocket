
# ⚠️ Notice
This requires the [Fluster](github.com/cerealwithmilk/uwp/releases/download/upgrade-required/Fluster.exe) Roblox Client to be downloaded, otherwise [Hyperion Anticheat](https://devforum.roblox.com/t/welcoming-byfron-to-roblox/2018233) will be installed.

# HourSocket a multiplayer mod for [Hours](https://www.roblox.com/games/5732973455/HOURS)

[Trello](https://trello.com/b/e1gvvbzK/hours-multiplayer-script) · [Mod Showcase](https://www.youtube.com/watch?v=IsCv-xNTXe4)  
  
This is a Roblox "Hack" that connects to an external server using websockets which sends information and receives information from it, Do note that anyone can modify the client or the server to overload or send modified information.

### Open Source Credits:  
[Fleck](https://github.com/statianzo/Fleck) [networker]  
[NewtonSoft.Json](https://github.com/JamesNK/Newtonsoft.Json) [configuration helper]  

### Supported Executors
[Fluxus](https://fluxteam.net)<sub> Free</sub> dev note: CANT TEST LOCAL?  
[krnl](https://krnl.place)<sub> Free</sub>  
[Electron](https://ryos.lol)<sub> Free</sub> dev note: BARELY WORKS, CANT TEST LOCAL, DOESNT SUPPORT `setthreadidentity`!

### Creating a server
- Go to releases and download the latest version.
- Extract it.
- Port Forward `6969` or what you put in the configuration file.
- Launch HourSocketServerCS.exe

### Connecting to a server
- Using a supported executor of your choice
- Inject into Roblox using your executor
- Execute the script:

```lua
local url = "https://raw.githubusercontent.com/nptnc/HourSocket/source/Client/Client.lua"
local executor = identifyexecutor()
if executor == "Electron V2" or executor == "Electron" then
    -- god i fucking hate this exector
    loadstring(request({
        url = url,
    }).Body)()("github")
else
    loadstring(game:HttpGet(url))()("github")
end

--[[ 
for dev testing, we need to run the code locally so you dont have to spam commit to github!,
oh it also only works on krnl cause electron is a shit exploit!!!!!!

local path = "HoursMPSource/Client"
loadfile(`{path}/Client.lua`)()("local",path)
--]]
````
