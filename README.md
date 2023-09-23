
# ⚠️ Notice
This requires the Microsoft Store Roblox Version [2.592.586.0](https://github.com/cerealwithmilk/uwp/releases/download/2.592.586.0/RobloxUWP-2.592.586.0-cerealwithmilk.Msixbundle) to be downloaded, any higher and [Hyperion Anticheat](https://devforum.roblox.com/t/welcoming-byfron-to-roblox/2018233) will be installed.

# HourSocket <sub>a multiplayer mod for [Hours](https://www.roblox.com/games/5732973455/HOURS)</sub>

[Public server statistics](http://salamithecat.com:4040) · [Trello](https://trello.com/b/e1gvvbzK/hours-multiplayer-script) · [Mod Showcase](https://www.youtube.com/watch?v=IsCv-xNTXe4)

Server programmed by [PeeblyWeeb](https://discord.com/users/904032786854346795)  
Client programmed by [nptnc](https://discord.com/users/397930609894490122)

This is a Roblox "Hack" that connects to an external server using websockets which sends information and receives information from it,
I am not held liable for any modifications users make to the server or the client, anyone can modify either side to overload or send modified information,
Please only connect to servers that you trust as it may be unsafe as people can modify the server to log your ip address, do not use modified clients unless they are safe because they could open up vulnerabilities.

### Supported Executors
[Synapse X](https://x.synapse.to)<sub> $20</sub>
[krnl](https://krnl.place)<sub> Free</sub>

### Creating a server
- [Download Python](https://www.python.org/downloads/release/python-3110/) (If you already have Python, skip this step)
- Clone this repository using `git clone https://github.com/nptnc/HourSocket`
- Port Forward `7171` and optionally `4040`
- Run `main.py` and optionally `webserver.py`

### Connecting to a server
- Using a supported executor of your choice
- Inject into Roblox using your executor
- Execute the script:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nptnc/HourSocket/main/Client/Client.lua"))()
````
