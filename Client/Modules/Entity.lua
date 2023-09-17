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

                if not args[1].IsPlayer then
                    entityDatabase[entityId] = {
                        entity = entity,
                    }
                    local message = api.prepareMessage("registerEntity",entityId,args.Name,entity.DamageTeam,entity.IsBoss or false,x,y,z,xr,yr,zr)
                    api.socket:Send(message)
                end

                return realEntityId
            else
                if args[1].Bypass then
                    return hook.call(...)
                end
            end
            return hook.call(...)
        end)
    end

    module.networkedEntityCreated = function(entityId,realEntityId)
        entityDatabase[entityId] = {
            entity = getrenv()._G.Entities[realEntityId],
        }
    end

    module.update = function()

    end

    module.entityUpdateNonHost = function(entityid,posx,posy,posz,rotx,roty,rotz)

    end

    return module
end