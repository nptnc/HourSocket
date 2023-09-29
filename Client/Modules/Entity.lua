return function(api)
    local module = {}

    local getVector3 = function(v3)
        return api.optimize(v3.X),api.optimize(v3.Y),api.optimize(v3.Z)
    end

    local getVector3Hard = function(v3)
        return api.hardOptimize(v3.X),api.hardOptimize(v3.Y),api.hardOptimize(v3.Z)
    end

    local getVector3Hard2 = function(v3)
        return Vector3.new(api.hardOptimize(v3.X),api.hardOptimize(v3.Y),api.hardOptimize(v3.Z))
    end

    api.globals.entityDatabase = {}

    local globalEntityId = 0
    local reg = function(entity,realId,entitymodelid,pos,rot)
        globalEntityId += 1

        getrenv()._G.Entities[realId].NetworkID = globalEntityId

        api.globals.entityDatabase[globalEntityId] = {
            cframe = CFrame.new(pos) * CFrame.Angles(math.rad(rot.X),math.rad(rot.Y),math.rad(rot.Z)),
            realId = realId,
            networkId = globalEntityId,
        }

        local message = api.prepareMessage("registerEntity",globalEntityId,entitymodelid,entity.DamageTeam,entity.IsBoss or false,api.encodeV3(pos),api.encodeV3(rot))
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
            if entity.NetworkID == networkId then
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

                local pos = getVector3Hard2(entity.RootPart.Position)
                local rot = getVector3Hard2(entity.RootPart.Rotation)

                -- lets stop from creating infinite loops of players
                if not args.IsPlayer then
                    local entitynetworkid = reg(entity,realEntityId,args.Name,pos,rot)

                    -- syncs enemy attacks (kinda, some break the game, im trying to figure out how to do this properly.)
                    entity.SwitchAnimation = api.createHook(entity.SwitchAnimation,function(hook2,...)
                        local args2 = {...}

                        local animationName = args2[3]
                        local blacklistedAnimations = {"Idle","Run","Death"}
                        if not table.find(blacklistedAnimations,animationName) then
                            local message = api.prepareMessage("entityInput",entitynetworkid,args2[2],args2[3])
                            api.sendToServer(message)
                            print(`networking entity attack {args2[2]} {args2[3]}`)
                        end
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
    local sinceLastHealthCheck = tick()
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

        if tick() - sinceLastHealthCheck > 1/10 then
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

                local entityHealth = math.ceil(entity.Resources.Health)
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

            sinceLastHealthCheck = tick()
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
            
            local pos = getVector3Hard2(entity.RootPart.Position)
            local rot = getVector3Hard2(entity.RootPart.Rotation)

            if entityData.lastNetworkedInformation and entityData.lastNetworkedInformation.Position == pos and entityData.lastNetworkedInformation.Rotation == rot then
                return
            end

            local message = api.prepareMessage("updateEntityCF",
                entityId,
                api.encodeV3(pos),
                api.encodeV3(rot)
            )
            api.sendToServer(message)

            entityData.lastNetworkedInformation = {
                Position = pos,
                Rotation = rot,
            }
        end
    end

    module.networkEntityUpdate = function(entityid,pos,rot)
        local entityData = api.globals.entityDatabase[entityid]
        if not entityData then
            return
        end
        entityData.cframe = CFrame.new(pos) * CFrame.Angles(math.rad(rot.X),math.rad(rot.Y),math.rad(rot.Z))
    end

    module.networkedEntityCreated = function(entityId,realEntityId,pos,rot)
        warn(`non host, registering entity {entityId} in script entity database`)
        api.globals.entityDatabase[entityId] = {
            cframe = CFrame.new(pos) * CFrame.Angles(math.rad(rot.X),math.rad(rot.Y),math.rad(rot.Z)),
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

    module.entityDoInput = function(entityid,someIndex,input)
        local entity = getRealEntityFromNetworkId(entityid)
        if not entity then
            print("entity doesnt exist cant do input")
            return
        end
        entity.SwitchAnimation(entity,someIndex,input)
    end

    return module
end