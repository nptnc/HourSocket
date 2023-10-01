
# ⚠️ Notice
This requires the Microsoft Store Roblox Version [2.592.586.0](https://github.com/cerealwithmilk/uwp/releases/download/2.592.586.0/RobloxUWP-2.592.586.0-cerealwithmilk.Msixbundle) to be downloaded, any higher and [Hyperion Anticheat](https://devforum.roblox.com/t/welcoming-byfron-to-roblox/2018233) will be installed.

# HourSocket <sub>a multiplayer mod for [Hours](https://www.roblox.com/games/5732973455/HOURS)</sub>

[Trello](https://trello.com/b/e1gvvbzK/hours-multiplayer-script) · [Mod Showcase](https://www.youtube.com/watch?v=IsCv-xNTXe4)

Old Server programmed by [PeeblyWeeb](https://discord.com/users/904032786854346795)  

Client programmed by [nptnc](https://discord.com/users/397930609894490122)  
Server programmed by [nptnc](https://discord.com/users/397930609894490122)

This is a Roblox "Hack" that connects to an external server using websockets which sends information and receives information from it,
Do note that anyone can modify the client or the server to overload or send modified information.

### Open Source Credits:  
[\[fleck\] server](https://github.com/statianzo/Fleck)

### Supported Executors
[Synapse X](https://x.synapse.to)<sub> $20</sub>  
[krnl](https://krnl.place)<sub> Free</sub>

### Creating a server
- Go to releases and download the latest version.
- Extract it.
- Port Forward `7171` or what you put in the configuration file.
- Launch HourSocketServerCS.exe

### Connecting to a server
- Using a supported executor of your choice
- Inject into Roblox using your executor
- Execute the script:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nptnc/HourSocket/main/Client/Client.lua"))()("github")

--[[ 
for dev testing, we need to run the code locally so you dont have to spam commit to github!
local path = "HoursMPSource/Client"
loadfile(`{path}/Client.lua`)()("local",path)
--]]
````
