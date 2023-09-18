return function(api)
    local module = {}

    local hook2 = function()
        local entities = getrenv()._G.Entities
        entities[1].SwitchAnimation = api.createHook(entities[1].SwitchAnimation,function(hook,...)
            local args = {...}
            local blacklistedAnimations = {"Idle","Run"}

            -- we dont really need idle or run to be networked since they are already handled by the games ai when we create a player.
            if not table.find(blacklistedAnimations,args[3]) then
                local message = api.prepareMessage("animationChange",args[2],args[3])
                api.sendToServer(message)
            end
            return hook.call(...)
        end)
    end

    module.playerRespawned = function()
        if not api.connected then
            return
        end
        
        local message = api.prepareMessage("updateState","dead",false)
        api.sendToServer(message)

        hook2()
    end

    module.playerDied = function()
        local message = api.prepareMessage("updateState","dead",true)
        api.sendToServer(message)
    end

    module.connected = function()
        local message = api.prepareMessage("registerPlayer",api.player.Name,getrenv()._G.Class)
        api.sendToServer(message)

        if getrenv()._G.Entities[1] then
            hook2()
        end
    end
    
    local lastUpdated = {Vector3.zero,Vector3.zero}
    local lastNetworkedPosition = Vector3.zero
    local lastNetworkedRotation = Vector3.zero
    module.updateWithFPS = function()
        local char = api.player.Character
        local pos = char.HumanoidRootPart.Position
        local rot = char.HumanoidRootPart.Rotation

        if lastUpdated[1] == pos and lastUpdated[2] == rot then
            return
        end

        if (lastNetworkedRotation - pos).Magnitude < 1 or (lastNetworkedPosition - pos).Magnitude < 1 then
            return
        end
        
        local message = api.prepareMessage("updatePlayer",
            api.optimize(pos.X),
            api.optimize(pos.Y),
            api.optimize(pos.Z),
            api.optimize(rot.X),
            api.optimize(rot.Y),
            api.optimize(rot.Z)
        )

        api.sendToServer(message)

        lastNetworkedPosition = pos
        lastNetworkedRotation = rot

        lastUpdated = {pos,rot}
    end

    local knockbackPreviousValues = {}
    module.update = function()
        if not api.connected then
            return
        end
        --[[if getrenv()._G.GameState ~= "Combat" then
            -- oh shit.
            for userid,player in api.registeredPlayers do
                --api.destroyPlayerEntity(userid)
                player.entity = nil
            end
        end--]]

        -- to make hellion shift, e, right click to work we must sync knockback over the network, i've only tested hellion this could add support to others though.
        local myEntity = getrenv()._G.Entities[1]
        if myEntity then 
            for knockbackIndex,knockbackData in myEntity.Knockback do
                if knockbackPreviousValues[knockbackIndex] == nil then
                    continue
                end
                local previousKnockback = knockbackPreviousValues[knockbackIndex]
                if previousKnockback ~= knockbackData.Knockback then
                    local message = api.prepareMessage("updateKnockback",
                        knockbackIndex,
                        api.optimize(knockbackData.Knockback.X),
                        api.optimize(knockbackData.Knockback.Y),
                        api.optimize(knockbackData.Knockback.Z)
                    )
                    api.sendToServer(message)
                    print("networking knockback change")
                end
            end
            for knockbackIndex,knockbackData in myEntity.Knockback do
                knockbackPreviousValues[knockbackIndex] = knockbackData.Knockback
            end
        end
        
        for userid,playerdata in api.registeredPlayers do
            if userid == api.player.UserId then
                -- no creaty yourselfy!
                continue
            end
    
            -- no player entity?, create one!
            if api.doesPlayerHaveEntity(playerdata) == false and getrenv()._G.GameState == "Combat" then
                local entity = api.createPlayer(playerdata)
                playerdata.entity = entity
            end
            
            local entity = playerdata.entity
            if not entity then
                continue
            end

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
            entity.TimeSpeed = 1
        end
    end

    module.onDisconnect = function()
        api.socket:Close()
    end

    return module
end