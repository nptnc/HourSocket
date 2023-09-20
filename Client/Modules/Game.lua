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
        
        local getEntityByRealId = function(realid)
            for _,entity in api.globals.entityDatabase do
                print(`\nentityId: {getrenv()._G.Entities[entity.realId].Id}\ntargetId: {realid}`)
                if getrenv()._G.Entities[entity.realId].Id == realid then
                    return entity
                end
            end
        end

        getrenv()._G.DamageRequest = api.createHook(getrenv()._G.DamageRequest,function(hook,...)
            if not api.connected then
                return hook.call(...)
            end

            local args = {...}
            args = args[1]

            if not api.isHost() then
                local target = getEntityByRealId(args.Target)
                if target then
                    local message = api.prepareMessage("damageRequest",target,args.Amount,args.PartName,args.Name,args.ScreenShake)
                    api.sendToServer(message)
                else
                    warn("entity isnt registered on server.")
                end
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
            aidata.Die()
        end
    end

    return module
end