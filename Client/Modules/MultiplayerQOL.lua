return function(api)
    local module = {}

    module.once = function()
        local old = getrenv()._G.EndGame
        getrenv()._G.EndGame = function()
            
        end
        api.globals.hasCalledGameEnd = false
        api.globals.oldEndGame = old

        getrenv()._G.TalentChosen = api.createHook(getrenv()._G.TalentChosen,function(hook,...)
            if not api.connected then
                return hook.call(...)
            end
            local args = {...}
            if args[2] ~= true then
                local message = api.prepareMessage("pickTalent",args[1])
                api.sendToServer(message)
                print("sent picked talent to server")
                return -- we return nothing and let the server know so they deem when we can choose
            end
            return hook.call(...)
        end)
    end

    module.update = function()
        if getrenv()._G.Entities[1].Dead == true then
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
                api.globals.oldEndGame()
            end
        else
            api.globals.hasCalledGameEnd = false
        end
    end

    return module
end