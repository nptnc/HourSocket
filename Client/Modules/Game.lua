return function(api)
    local module = {}

    local old
    module.once = function()
        old = getrenv()._G.TalentPopup
        getrenv()._G.TalentPopup = api.createHook(getrenv()._G.TalentPopup,function(hook,...)
            if api.isHost() then
                local message = api.prepareMessage("intermissionStarted")
                api.sendToServer(message)
            end
            return hook.call(...)
        end)
    end

    module.gameShowTalentPopup = function()
        getrenv()._G.Map:Die()
        old()
    end
<<<<<<< HEAD

    return module
=======
>>>>>>> de2b4cb5010ffc1928efe9e6fc93ac8cd87eecb9
end