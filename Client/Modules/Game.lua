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

    local talentScreen = function(yes)
        local toHide = {"Talent1","Talent2","Talent3","Skip"}
        for _,object in toHide do
            getrenv()._G.AllGui.Talents[object].Visible = not yes
        end
        getrenv()._G.AllGui.Talents.Instruction.Text = yes and "Waiting for others." or "Choose an upgrade."
    end

    local old
    local damageOld
    local talentOld
    module.once = function()
        old = getrenv()._G.TalentPopup
        getrenv()._G.TalentPopup = api.createHook(getrenv()._G.TalentPopup,function(hook,...)
            hook.call(...)
            talentScreen(false)
            if api.isHost() then
                local message = api.prepareMessage("intermissionStarted",getrenv()._G.ArenaMode)
                api.sendToServer(message)
            end
        end)

        talentOld = getrenv()._G.TalentChosen
        getrenv()._G.TalentChosen = api.createHook(getrenv()._G.TalentChosen,function(hook,...)
            if not api.connected then
                return hook.call(...)
            end
            local args = {...}

            talentScreen(true)
            local message = api.prepareMessage("pickTalent",args[1])
            api.sendToServer(message)
            print("sent picked talent to server")
            return -- we return nothing and let the server know so they deem when we can choose
        end)

        damageOld = getrenv()._G.DamageRequest
        getrenv()._G.DamageRequest = api.createHook(getrenv()._G.DamageRequest,function(hook,...)
            if not api.connected then
                return hook.call(...)
            end

            local args = {...}
            args = args[1]

            local target = getEntityByRealId(args.Target)
            if target and target.specialId then
                -- this basically just means this is a player entity
                return -- we dont want players to be hit unless they say they've been hit
            end

            if args.Networked ~= true then
                -- dont let players hit enemies on our screen, only let them determine whether they hit them or not
                for _,playerdata in api.registeredPlayers do
                    if playerdata.entity and playerdata.entity.Id == args.Source then
                        return -- nope this is by a player entity, this means that they hit something on our screen
                    end
                end
            end 

            if not api.isHost() then
                if target and target.NetworkID ~= nil then
                    local message = api.prepareMessage("damageRequest",target.NetworkID,args.Amount,args.PartName,args.Name,args.ScreenShake or 0)
                    api.sendToServer(message)
                    print("networking damage request")
                else
                    warn(`entity isnt registered on server.\ntarget is nil: {target == nil}\nnetworkId: {target and target.NetworkID or "none"}`)
                end
                return -- stops hit from registering
            end
            return hook.call(...)
        end)
    end

    module.chooseTalent = function(talentindex)
        print(`picking talent {talentindex}`)
        talentOld(talentindex)
        talentScreen(false)
    end
    
    local findEntityByNetworkId = function(networkId)
        for id,entity in getrenv()._G.Entities do
            if entity.NetworkID == nil or entity.NetworkID ~= networkId then
                continue
            end
            return entity
        end
    end

    module.gameDealDamage = function(userid,entityid,damage,partname,damagename,screenshake)
        local entity = findEntityByNetworkId(entityid)
        if not entity then
            print(`entity doesnt exist cant damage them\nentity: {entity}\nentityid: {entityid}`)
            return
        end

        print(`dealing damage to entity {entityid}`)

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
            if index == 1 then
                continue
            end
            local char = aidata.Character
            char:Destroy()
            local ui = aidata.BossGui
            if ui then
                ui:Destroy()
            end
            getrenv()._G.Entities[index] = nil
        end

        local map = getrenv()._G.Map
        map.Die(map)
        old()
    end

    return module
end