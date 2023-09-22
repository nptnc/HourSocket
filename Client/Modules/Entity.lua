return function(api)
    local module = {}

    local getVector3 = function(v3)
        return api.optimize(v3.X),api.optimize(v3.Y),api.optimize(v3.Z)
    end

    local getVector3Hard = function(v3)
        return api.hardOptimize(v3.X),api.hardOptimize(v3.Y),api.hardOptimize(v3.Z)
    end

    api.globals.entityDatabase = {}

    local globalEntityId = 0
    local reg = function(entity,realId,entitymodelid,x,y,z,xr,yr,zr)
        globalEntityId += 1

        getrenv()._G.Entities[realId].NetworkID = globalEntityId

        api.globals.entityDatabase[globalEntityId] = {
            cframe = CFrame.new(x,y,z) * CFrame.Angles(math.rad(xr),math.rad(yr),math.rad(zr)),
            realId = realId,
            networkId = globalEntityId,
        }

        local message = api.prepareMessage("registerEntity",globalEntityId,entitymodelid,entity.DamageTeam,entity.IsBoss or false,x,y,z,xr,yr,zr)
        api.sendToServer(message)
        print(`registering entity {realId} as {globalEntityId} on network`)
        return globalEntityId
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

    local getEntityByRealId = function(realid)
        for _,entity in getrenv()._G.Entities do
            if entity.Id == realid then
                return entity
            end
        end
    end

    local getRealEntityFromNetworkId = function(networkId)
        for _,entity in getrenv()._G.Entities do
            if entity.networkId == networkId then
                return entity
            end
        end
    end

    local getEntityFromNetworkId = function(networkId)
        return api.globals.entityDatabase[networkId]
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

                local x,y,z = getVector3Hard(entity.RootPart.Position)
                local xr,yr,zr = getVector3Hard(entity.RootPart.Rotation)

                -- lets stop from creating infinite loops of players
                if not args.IsPlayer then
                    local entitynetworkid = reg(entity,realEntityId,args.Name,x,y,z,xr,yr,zr)
                    entity.SwitchAnimation = api.createHook(entity.SwitchAnimation,function(hook2,...)
                        local args = {...}
                        local message = api.prepareMessage("entityInput",entitynetworkid,args[2])
                        api.sendToServer(message)
                        print(`networking entity attack {args[2]}`)
                        return hook2.call(...)
                    end)
                end

                return realEntityId
            else
                if args.Bypass then
                    -- spawn the enemy, bypass is only usually used on players when you arent the host.
                    local realEntityId = hook.call(...) 
                    local entity = getrenv()._G.Entities[realEntityId]

                    if not args.IsPlayer then
                        entity.ProcessAI = function() end -- bye bye ai
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

    local findEntityByNetworkId = function(networkId)
        for id,entity in getrenv()._G.Entities do
            if entity.NetworkID == nil or entity.NetworkID ~= networkId then
                continue
            end
            return id
        end
    end

    module.update = function()
        -- non host
        for entityId,entityData in api.getMe().serverData.isHost and {} or api.globals.entityDatabase do
            local realId = entityData.realId
            local entity = getrenv()._G.Entities[realId]

            if findEntityByNetworkId(entityData.networkId) == nil or entity == nil then
                warn("unregistered entity non host")
                api.globals.entityDatabase[entityId] = nil
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
          
            for knockbackIndex,knockback in entity.knockback or {} do
                entity.Knockback[knockbackIndex].Knockback = knockback
            end
            --entity.Dead = playerdata.serverData.dead
        end

        local networkEntities = api.len(api.globals.entityDatabase)
        local fps = (20/networkEntities)
        if networkEntities == 0 or tick() - sinceLastUpdate < 1/fps  then
            return
        end

        --print(`entity update fps is {fps} {networkEntities}`)
        sinceLastUpdate = tick()

        -- host
        for entityId,entityData in api.getMe().serverData.isHost and api.globals.entityDatabase or {} do
            local realId = entityData.realId
            local entity = getrenv()._G.Entities[realId]
            if entity == nil then
                warn("unregistered entity host loop 1")
                api.globals.entityDatabase[entityId] = nil
                continue
            end

            if findEntityByNetworkId(entityData.networkId) == nil or entity == nil then
                warn("unregistered entity host loop 1")
                api.globals.entityDatabase[entityId] = nil
                continue
            end

            local entityHealth = entity.Resources.Health
            if not lastEntityStuff[entityId] then
                lastEntityStuff[entityId] = {
                    health = entityHealth or 100,
                }
            end

            local lastEntityHealth = lastEntityStuff[entityId].health

            if entityHealth ~= lastEntityHealth then
                local message = api.prepareMessage("updateEntityState",
                    entityId,
                    "health",
                    entityHealth
                )
                api.sendToServer(message)
                print("updating entity health, guh hopefully this doesnt spam the server")
            end

            lastEntityStuff[entityId].health = entityHealth
        end

        -- host
        for entityId,entityData in api.getMe().serverData.isHost and api.globals.entityDatabase or {} do
            local realId = entityData.realId
            local entity = getrenv()._G.Entities[realId]
            
            local pos = entity.RootPart.Position
            local rot = entity.RootPart.Rotation

            if entityData.lastNetworkedInformation and (entityData.lastNetworkedInformation.Position-pos).Magnitude < 1 and (entityData.lastNetworkedInformation.Rotation-rot).Magnitude < 1 then
                return
            end

            local message = api.prepareMessage("updateEntityCF",
                entityId,
                api.hardOptimize(pos.X),
                api.hardOptimize(pos.Y),
                api.hardOptimize(pos.Z),
                api.hardOptimize(rot.X),
                api.hardOptimize(rot.Y),
                api.hardOptimize(rot.Z)
            )
            api.sendToServer(message)

            entityData.lastNetworkedInformation = {
                Position = Vector3.new(pos.X,pos.Y,pos.Z),
                Rotation = Vector3.new(rot.X,rot.Y,rot.Z)
            }
        end
    end

    module.networkEntityUpdate = function(entityid,posx,posy,posz,rotx,roty,rotz)
        local entityData = api.globals.entityDatabase[entityid]
        if not entityData then
            return
        end
        entityData.cframe = CFrame.new(posx,posy,posz) * CFrame.Angles(math.rad(rotx),math.rad(roty),math.rad(rotz))
    end

    module.networkedEntityCreated = function(entityId,realEntityId,posx,posy,posz)
        warn(`non host, registering entity {entityId} in script entity database`)
        api.globals.entityDatabase[entityId] = {
            cframe = CFrame.new(posx,posy,posz),
            realId = realEntityId,
            health = getrenv()._G.Entities[realEntityId].Resources.Health or 100,
            networkId = entityId,
        }
        getrenv()._G.Entities[realEntityId].NetworkID = entityId
    end

    module.playerEntityKnockbackUpdate = function(entityid,index,x,y,z)
        local entity = api.globals.entityDatabase[entityid]
        if not entity.knockback then
            entity.knockback = {}
        end
        entity.knockback[index] = Vector3.new(x,y,z)
    end

    module.networkEntityStateUpdate = function(entityid,index,value)
        local entityData = api.globals.entityDatabase[entityid]
        if not entityData then
            return
        end
        entityData[index] = value
    end

    module.entityDoInput = function(entityid,input)
        local entity = getRealEntityFromNetworkId(entityid)
        if not entity then
            return
        end
        local inputFunction = entity.InputFunctions[input]
        if not inputFunction then
            warn(`input function {input} doesnt exist for entity {entityid}`)
            return
        end
        entity.SwitchAnimation(entity,input)
    end

    return module
end