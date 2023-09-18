return function(api)
    local module = {}

    local getVector3 = function(v3)
        return api.optimize(v3.X),api.optimize(v3.Y),api.optimize(v3.Z)
    end

    local entityDatabase = {}

    local globalEntityId = 0
    local reg = function(entity,realId,entitymodelid,x,y,z,xr,yr,zr)
        globalEntityId += 1

        entityDatabase[globalEntityId] = {
            cframe = CFrame.new(x,y,z) * CFrame.Angles(math.rad(xr),math.rad(yr),math.rad(zr)),
            realId = realId,
        }
        local message = api.prepareMessage("registerEntity",globalEntityId,entitymodelid,entity.DamageTeam,entity.IsBoss or false,x,y,z,xr,yr,zr)
        api.sendToServer(message)
        print(`registering entity {realId} as {globalEntityId} on network`)
    end

    module.playerRegistered = function(playerid,data)
        if not data.serverData.isHost then
            return
        end
        --[[for realEntityId, entity in getrenv()._G.Entities do
            if realEntityId == 1 or entity.specialId ~= nil then
                continue
            end
            local x,y,z = getVector3(entity.RootPart.Position)
            local xr,yr,zr = getVector3(entity.RootPart.Rotation)
            reg(entity,entity.Name,x,y,z,xr,yr,zr)
        end--]]
    end

    module.once = function()
        -- hook when this function is called by hours, what we'll do is check if we are allowed to spawn an entity or not.
        
        if api.getMe() ~= nil then
            --[[for realEntityId, entity in getrenv()._G.Entities do
                if realEntityId == 1 or entity.specialId ~= nil then
                    continue
                end
                local x,y,z = getVector3(entity.RootPart.Position)
                local xr,yr,zr = getVector3(entity.RootPart.Rotation)
                reg(entity,entity.Name,x,y,z,xr,yr,zr)
            end--]]
        end
        
        getrenv()._G.SpawnCreature = api.createHook(getrenv()._G.SpawnCreature,function(hook,...)
            local args = {...}
            args = args[1]

            local isHost = api.getMe().serverData.isHost
            if isHost then
                local realEntityId = hook.call(...) -- spawn the enemy
                local entity = getrenv()._G.Entities[realEntityId]

                local x,y,z = getVector3(entity.RootPart.Position)
                local xr,yr,zr = getVector3(entity.RootPart.Rotation)

                -- lets stop from creating infinite loops of players
                if not args.IsPlayer then
                    reg(entity,realEntityId,args.Name,x,y,z,xr,yr,zr)
                end

                return realEntityId
            else
                if args.Bypass then
                    -- spawn the enemy, bypass is only usually used on players when you arent the host.
                    local realEntityId = hook.call(...) 
                    local entity = getrenv()._G.Entities[realEntityId]

                    if not args.IsPlayer then
                        entity.Update = function() end
                        entity.ProcessAI = function() end

                         -- we gonna stop the animations from playing unless its networked.
                        entity.SwitchAnimation = api.createHook(entity.SwitchAnimation,function(hook,...)
                            local args = {...}
                            if args[4] ~= false then
                                return
                            end
                            return hook.call(...)
                        end)
                    end

                    return realEntityId
                end
                -- dont spawn the enemy because we arent allowed to.
                return
            end
            return hook.call(...)
        end)
    end

    local sinceLastUpdate = tick()

    local warnedAboutNoCFrame = {}

    local lastEntityStuff = {}
    module.update = function()
        -- non host
        for entityId,entityData in api.getMe().serverData.isHost and {} or entityDatabase do
            local realId = entityData.realId
            local entity = getrenv()._G.Entities[realId]

            if entity == nil then
                warn("unregistered entity non host")
                entityDatabase[entityId] = nil
                continue
            end

            local currentCF = entity.RootPart.CFrame
            local targetCF = entityData.cframe
            if not targetCF and warnedAboutNoCFrame[entity] == nil then
                warnedAboutNoCFrame[entityId] = true
                warn("no cf")
            end

            if not targetCF then
                continue
            end

            local distanceFromTarget = (targetCF.Position-currentCF.Position).Magnitude
            entity.Resources.Health = entityData.health
            entity.MoveDirection = {distanceFromTarget > 0.5 and 1 or 0,0}
            entity.MovePosition = targetCF.Position
            entity.FacingPosition = (targetCF.Position + targetCF.LookVector*1000)
            entity.TargetCFrame = targetCF
            entity.Facing = true
            --entity.Dead = playerdata.serverData.dead
        end

        -- host
        for entityId,entityData in api.getMe().serverData.isHost and entityDatabase or {} do
            local realId = entityData.realId
            local entity = getrenv()._G.Entities[realId]

            if entity == nil then
                warn("unregistered entity host")
                entityDatabase[entityId] = nil
                continue
            end

            if not lastEntityStuff[entityId] then
                lastEntityStuff[entityId] = {
                    health = entity.Resources.Health,
                }
            end

            if entity.Resources.Health ~= lastEntityStuff[entityId].Health then
                local message = api.prepareMessage("updateEntityState",
                    entityId,
                    "health",
                    entity.Resources.Health
                )
                api.sendToServer(message)
            end

            lastEntityStuff[entityId]["health"] = entity.Resources.Health
        end

        local networkEntities = api.len(entityDatabase)
        local fps = (30/networkEntities)
        if networkEntities == 0 or tick() - sinceLastUpdate < 1/fps  then
            return
        end

        print(`entity update fps is {fps} {networkEntities}`)
        sinceLastUpdate = tick()

        -- host
        for entityId,entityData in api.getMe().serverData.isHost and entityDatabase or {} do
            local realId = entityData.realId
            local entity = getrenv()._G.Entities[realId]
            
            local pos = entity.RootPart.Position
            local rot = entity.RootPart.Rotation

            local message = api.prepareMessage("updateEntityCF",
                entityId,
                api.optimize(pos.X),
                api.optimize(pos.Y),
                api.optimize(pos.Z),
                api.optimize(rot.X),
                api.optimize(rot.Y),
                api.optimize(rot.Z)
            )
            api.sendToServer(message)
        end
    end

    module.networkEntityUpdate = function(entityid,posx,posy,posz,rotx,roty,rotz)
        local entityData = entityDatabase[entityid]
        entityData.cframe = CFrame.new(posx,posy,posz) * CFrame.Angles(math.rad(rotx),math.rad(roty),math.rad(rotz))
    end

    module.networkedEntityCreated = function(entityId,realEntityId,posx,posy,posz)
        warn(`non host, registering entity {entityId} in script entity database`)
        entityDatabase[entityId] = {
            cframe = CFrame.new(posx,posy,posz),
            realId = realEntityId,
            health = getrenv()._G.Entities[realEntityId].Resources.Health or 100,
        }
    end

    module.networkEntityStateUpdate = function(entityid,index,value)
        local entityData = entityDatabase[entityid]
        entityData[index] = value
    end

    return module
end