return function(api)
    local module = {}

    module.once = function()
        local old = getrenv()._G.EndGame
        getrenv()._G.EndGame = function()
            
        end
        api.globals.hasCalledGameEnd = false
        api.globals.oldEndGame = old
    end

    module.update = function()
        if getrenv()._G.Entities[1] and getrenv()._G.Entities[1].Dead == true then
            local deadPeople = {}
            for userid,playerdata in api.registeredPlayers do
                if userid == api.player.UserId then
                    continue
                end
                if playerdata.serverData.dead == false then
                    continue
                end
                table.insert(deadPeople,userid)
            end
            if #deadPeople == api.len(api.registeredPlayers)-1 and api.globals.hasCalledGameEnd == false then
                api.globals.hasCalledGameEnd = true
                --api.respawnPlayer()
                api.globals.oldEndGame()
            end
        else
            api.globals.hasCalledGameEnd = false
        end
    end

    return module
end