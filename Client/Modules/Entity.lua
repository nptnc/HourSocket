return function(api)
    local module = {}

    local getVector3 = function(v3)
        return api.optimize(v3.X),api.optimize(v3.Y),api.optimize(v3.Z)
    end

    local entityDatabase = {}

    local globalEntityId = 0
    local reg = function(entity,entitymodelid,x,y,z,xr,yr,zr)
        globalEntityId += 1

        entityDatabase[globalEntityId] = {
            entity = entity,
        }
        local message = api.prepareMessage("registerEntity",globalEntityId,entitymodelid,entity.DamageTeam,entity.IsBoss or false,x,y,z,xr,yr,zr)
        api.socket:Send(message)
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
                    reg(entity,args.Name,x,y,z,xr,yr,zr)
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

    module.networkedEntityCreated = function(entityId,realEntityId,posx,posy,posz)
        warn(`non host, registering entity {entityId} in script entity database`)
        entityDatabase[entityId] = {
            cframe = CFrame.new(posx,posy,posz),
            realId = realEntityId,
        }
    end

    local warnedAboutNoCFrame = {}
    module.update = function()
        for entityId,entityData in api.getMe().serverData.isHost and {} or entityDatabase do
            local entity = entityData.entity

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
            --entity.Resources.Health = 10000
            entity.MoveDirection = {distanceFromTarget > 0.5 and 1 or 0,0}
            entity.MovePosition = targetCF.Position
            entity.FacingPosition = (targetCF.Position + targetCF.LookVector*1000)
            entity.TargetCFrame = targetCF
            entity.Facing = true
            --entity.Dead = playerdata.serverData.dead
        end
    end

    module.updateWithFPS = function()
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
            api.socket:Send(message)
        end
    end

    module.networkEntityUpdate = function(entityid,posx,posy,posz,rotx,roty,rotz)
        local entityData = entityDatabase[entityid]
        entityData.cframe = CFrame.new(posx,posy,posz) * CFrame.Angles(rotx,roty,rotz)
    end

    return module
end