return function(api)
    local module = {}

    local getEntityByRealId = function(realid)
        for _,entity in getrenv()._G.Entities do
            --print(`\nentityId: {getrenv()._G.Entities[entity.realId].Id}\ntargetId: {realid}`)
            if entity.Id == realid then
                return entity
            end
        end
    end

    local getEntityFromNetworkId = function(networkId)
        return api.globals.entityDatabase[networkId]
    end

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
            if not api.connected then
                return hook.call(...)
            end

            local args = {...}
            args = args[1]

            if not api.isHost() then
                local target = getEntityByRealId(args.Target)
                if target and target.NetworkID ~= nil then
                    local message = api.prepareMessage("damageRequest",target.NetworkID,args.Amount,args.PartName,args.Name,args.ScreenShake)
                    api.sendToServer(message)
                    print("networking damage request")
                else
                    warn(`entity isnt registered on server.\ntarget is nil: {target == nil}\nnetworkId: {target and target.NetworkID or "none"}`)
                end
                return
            elseif api.isHost() and args.Networked ~= true then
                for userid,playerdata in api.registeredPlayers do
                    if playerdata.entity and playerdata.entity.Id == args.Source then
                        return
                    end
                end
            end
            return hook.call(...)
        end)
    end

    local findEntityByNetworkId = function(networkId)
        for id,entity in getrenv()._G.Entities do
            if entity.NetworkID == nil or entity.NetworkID ~= networkId then
                continue
            end
            return id
        end
    end

    module.gameDealDamage = function(userid,entityid,damage,partname,damagename,screenshake)
        local entity = findEntityByNetworkId(entityid)
        if not entity then
            print(`entity doesnt exist cant damage them\nentity: {entity}\nentityid: {entityid}`)
            return
        end

        print(`dealing damage tp entity {entityid}`)

        damageOld({
            Source = api.registeredPlayers[userid].entity.Id,
            Amount = damage,
            Target = entity.Id,
            PartName = partname,
            Name = damagename,
            ScreenShake = screenshake,
            Networked = true,
            Actions = {},
        })
    end

    module.gameShowTalentPopup = function()
        for index,aidata in getrenv()._G.Entities do
            if aidata.specialId then
                continue
            end
            aidata.Die(aidata)
        end

        local map = getrenv()._G.Map
        map.Die(map)
        old()
    end

    return module
end