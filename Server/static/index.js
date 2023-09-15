window.onload = () => {
    const ws = new WebSocket("ws://salamithecat.com:7171")
    const grid = document.getElementById('player-grid')
    const playercountdisplay = document.getElementById('connectedplayers')
    ws.onopen = () => {
        ws.send(-1)
    }



    ws.addEventListener("message", ({ data }) => {
        if (data.split(':::')[0] == 0) {
            const key = data.split(':::')[1]
            if (document.getElementById(key) != undefined) {
                document.getElementById(key).remove()
            }
            return
        }

        const {players} = JSON.parse(data);
        
        for (var playerID in players) {
            if (document.getElementById(playerID) == undefined) {
                const playerinfobox = document.createElement("div")
                playerinfobox.classList.add('playerinfobox')
                playerinfobox.id = playerID
                
                username = document.createElement("h3")
                username.innerText = `${players[playerID].username} (${playerID})`
                playerinfobox.appendChild(username)

                for (var key in players[playerID]) {
                    if (key == "username") {
                        continue
                    }
                    display_key = document.createElement("p")
                    display_key.id = `${playerID}${key}`
                    playerinfobox.appendChild(display_key)
                }
            
                grid.appendChild(playerinfobox)
            }
            
            for (var key in players[playerID]) {
                if (key == "username") {
                    continue
                }
                document.getElementById(`${playerID}${key}`).innerText = `${key}: ${players[playerID][key]}`
            }
        }

        playercountdisplay.innerText = `${Object.keys(players).length} Connected Player(s)`
    });
}
