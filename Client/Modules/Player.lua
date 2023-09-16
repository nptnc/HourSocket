return function(api)
    local module = {}

    module.playerRespawned = function()
        local message = api.prepareMessage("updateState","dead",false)
        api.socket:Send(message)
    end

    module.playerDied = function()
        local message = api.prepareMessage("updateState","dead",true)
        api.socket:Send(message)
    end

    module.once = function()
        local message = api.prepareMessage("registerPlayer",api.player.Name,getrenv()._G.Class)
        api.socket:Send(message)
    end
    
    module.updateWithFPS = function()
        local char = api.player.Character
        local pos = char.HumanoidRootPart.Position
        local rot = char.HumanoidRootPart.Rotation
        
        local message = api.prepareMessage("updatePlayer",
            api.optimize(pos.X),
            api.optimize(pos.Y),
            api.optimize(pos.Z),
            api.optimize(rot.X),
            api.optimize(rot.Y),
            api.optimize(rot.Z)
        )

        api.socket:Send(message)
    end

    module.update = function()
        if getrenv()._G.GameState ~= "Combat" then
            -- oh shit.
            for userid,_ in api.registeredPlayers do
                api.destroyPlayerEntity(userid)
            end
        end
        
        for userid,playerdata in api.registeredPlayers do
            if userid == api.player.UserId then
                -- no creaty yourselfy!
                continue
            end
    
            if not playerdata.cframe then
                continue
            end
    
            -- no player entity?, create one!
            if api.doesPlayerHaveEntity(playerdata) == false then
                local entity = api.createPlayer(playerdata)
                playerdata.entity = entity
            end
            
            local entity = playerdata.entity
            local erp = entity.RootPart.Position
            local theirCF = playerdata.cframe
    
            local distanceFromTarget = (theirCF.Position-erp).Magnitude
            entity.Resources.Health = 10000
            entity.MoveDirection = {distanceFromTarget > 0.5 and 1 or 0,0}
            entity.MovePosition = theirCF.Position
            entity.FacingPosition = (theirCF.Position + theirCF.LookVector*1000)
            entity.TargetCFrame = theirCF
            entity.Facing = true
            entity.Dead = playerdata.serverData.dead
        end
    end

    module.onDisconnect = function()
        api.socket:Close()
    end

    return module
end