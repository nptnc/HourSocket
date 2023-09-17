return function(api)
    local module = {}

    local getVector3 = function(v3)
        return api.optimize(v3.X),api.optimize(v3.Y),api.optimize(v3.Z)
    end

    local entityDatabase = {}

    local entityId = 0
    module.once = function()
        getrenv()._G.SpawnCreature = api.createHook(getrenv()._G.SpawnCreature,function(hook,...)
            local args = {...}
            args = args[1]

            local isHost = api.getMe().serverData.isHost
            if isHost then
                entityId += 1

                local realEntityId = hook.call(...)
                local entity = getrenv()._G.Entities[realEntityId]

                local x,y,z = getVector3(entity.RootPart.Position)
                local xr,yr,zr = getVector3(entity.RootPart.Rotation)

                if not args.IsPlayer then
                    entityDatabase[entityId] = {
                        entity = entity,
                    }
                    local message = api.prepareMessage("registerEntity",entityId,args.Name,entity.DamageTeam,entity.IsBoss or false,x,y,z,xr,yr,zr)
                    api.socket:Send(message)
                end

                return realEntityId
            else
                if args.Bypass then
                    return hook.call(...)
                end
            end
            return hook.call(...)
        end)
    end

    module.networkedEntityCreated = function(entityId,realEntityId,posx,posy,posz)
        entityDatabase[entityId] = {
            cframe = CFrame.new(posx,posy,posz),
            entity = getrenv()._G.Entities[realEntityId],
        }
    end

    module.update = function()
        for entityId,entityData in api.getMe().serverData.isHost and {} or entityDatabase do
            entityData.entity.RootPart.CFrame = entityData.cframe
        end
    end

    module.updateWithFPS = function()
        for entityId,entityData in api.getMe().serverData.isHost and {} or entityDatabase do
            local pos = entityData.cframe.Position
            local rx, ry, rz = entityData.cframe.Rotation:ToOrientation()
			local rot = Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz))

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

    module.entityUpdateNonHost = function(entityid,posx,posy,posz,rotx,roty,rotz)
        local entityData = entityDatabase[entityid]
        entityData.cframe = CFrame.new(posx,posy,posz) * CFrame.Angles(rotx,roty,rotz)
    end

    return module
end