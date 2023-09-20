return function(api)
    local module = {}

    local old
    module.once = function()
        old = getrenv()._G.TalentPopup
        getrenv()._G.TalentPopup = api.createHook(getrenv()._G.TalentPopup,function(hook,...)
            hook.call(...)
            if api.isHost() then
                local message = api.prepareMessage("intermissionStarted",getrenv()._G.ArenaMode)
                api.sendToServer(message)
            end
        end)
    end

    module.gameShowTalentPopup = function()
        local map = getrenv()._G.Map
        map.Die(map)
        old()

        for index,aidata in getrenv()._G.Entities do
            if aidata.specialId then
                continue
            end
            aidata.Interrupt(aidata)
            aidata.InterruptBase(aidata)
            aidata.Character:Destroy()
            getrenv()._G.Entities[index] = nil
        end
    end

    return module
end