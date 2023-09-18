
# Hour Socket
This requires the Microsoft Store Roblox Version 592.586.0 to be downloaded, any higher and [Byfron / Hyperion](https://devforum.roblox.com/t/welcoming-byfron-to-roblox/2018233) will be installed, you can install 592.586.0 [here]().

# HourSocket <sub>a multiplayer mod for [Hours](https://www.roblox.com/games/5732973455/HOURS)</sub>

[Public server statistics](http://salamithecat.com:4040) · [Trello](https://trello.com/b/e1gvvbzK/hours-multiplayer-script) · [Mod Showcase](https://www.youtube.com/watch?v=IsCv-xNTXe4)

Server programmed by [PeeblyWeeb](https://discord.com/users/904032786854346795)  
Client programmed by [nptnc](https://discord.com/users/397930609894490122)

## How do I play?
~~If you're stupid, here's a video tutorial on how to play on a [public server](https://google.com/) or [private server](https://google.com/).~~

### Creating a server
- [Download Python](https://www.python.org/downloads/release/python-3110/) (If you already have Python, skip this step)
- Clone this repository using `git clone https://github.com/nptnc/HourSocket`
- Port Forward `7171` and optionally `4040`
- Run `main.py` and optionally `webserver.py`

### Connecting to a server
- Using an executor of your choice (we suggest [Synapse X](https://x.synapse.to)<sub>Patched</sub> or [krnl](https://krnl.place)<sub>Patched</sub>)
- Inject in to Roblox using your executor
- Optionally set your server's IP and Port (If you aren't using a private server you can skip this step)
- Execute the script:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nptnc/HourSocket/main/Client/Client.lua"))()
````
