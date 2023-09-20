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
    end

    return module
end