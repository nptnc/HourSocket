return function(api)
    local module = {}

    local old
    local damageOld
    module.once = function()
        old = getrenv()._G.TalentPopup
        getrenv()._G.TalentPopup = api.createHook(getrenv()._G.TalentPopup,function(hook,...)
            hook.call(...)
            if api.isHost() then
                local message = api.prepareMessage("intermissionStarted",getrenv()._G.ArenaMode)
                api.sendToServer(message)
            end
        end)
        
        getrenv()._G.DamageRequest = api.createHook(getrenv()._G.DamageRequest,function(hook,...)
            local args = {...}
            args = args[1]

            local target = nil
            api.apiCall("getEntityFromRealId",function(entity)
                target = entity.networkId
            end,args.Target)

            if not api.isHost() then
                local message = api.prepareMessage("damageRequest",target,args.Amount,args.PartName,args.Name,args.ScreenShake)
                api.sendToServer(message)
                return
            elseif api.isHost() then
                for userid,playerdata in api.registeredPlayers do
                    if playerdata.entity and playerdata.entity.Id == args.Source and args.Networked ~= true then
                        return
                    end
                end
            end
            return hook.call(...)
        end)
    end

    module.gameDealDamage = function(userid,entityid,damage,partname,damagename,screenshake)
        local realId = nil
        api.apiCall("getEntityFromNetworkId",function(entity) 
            realId = entity.realId
        end,entityid)

        if not realId then
            warn("no real id, cant damage entity")
            return
        end

        damageOld({
            Source = api.registeredPlayers[userid].entity.Id,
            Amount = damage,
            Target = realId,
            PartName = partname,
            Name = damagename,
            ScreenShake = screenshake,
            Networked = true,
            Actions = {},
        })
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