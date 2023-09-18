return function(api)
    local module = {}

    module.playerRespawned = function()
        local message = api.prepareMessage("updateState","dead",false)
        api.socket:Send(message)

        local entities = getrenv()._G.Entities

        -- old system
        [[--entities[1].SwitchAnimation = api.createHook(entities[1].SwitchAnimation,function(hook,...)
            local args = {...}
            local blacklistedAnimations = {"Idle","Run"}
            
            -- we dont really need idle or run to be networked since they are already handled by the games ai when we create a player.
            if not table.find(blacklistedAnimations,args[3]) then
                local message = api.prepareMessage("animationChange",args[2],args[3])
                api.socket:Send(message)
            end
            return hook.call(...)
        end)--]]

        for actionName,actionFunction in entities[1].ActionFunctions do
            entities[1].ActionFunctions[actionName] = api.createHook(entities[1].ActionFunctions[actionName],function(hook,...)
                local args = {...}
                
                local attackInformationType = typeof(args[1]) == "table" and 1 or 2
                local arg1 = args[1]
                local arg2 = args[2]
                if attackInformationType == 1 then
                    arg1 = game:GetService("HttpService"):JSONEncode(arg1)
                end

                local message = api.prepareMessage("doAttack",attackInformationType,actionName,arg1,arg2)
                api.socket:Send(message)

                return hook.call(...)
            end)
        end
    end

    module.playerDied = function()
        local message = api.prepareMessage("updateState","dead",true)
        api.socket:Send(message)
    end

    module.once = function()
        local message = api.prepareMessage("registerPlayer",api.player.Name,getrenv()._G.Class)
        api.socket:Send(message)
    end
    
    local lastUpdated = {Vector3.zero,Vector3.zero}
    module.updateWithFPS = function()
        local char = api.player.Character
        local pos = char.HumanoidRootPart.Position
        local rot = char.HumanoidRootPart.Rotation

        if lastUpdated[1] == pos and lastUpdated[2] == rot then
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

        api.socket:Send(message)

        lastUpdated = {pos,rot}
    end

    module.update = function()
        --[[if getrenv()._G.GameState ~= "Combat" then
            -- oh shit.
            for userid,player in api.registeredPlayers do
                --api.destroyPlayerEntity(userid)
                player.entity = nil
            end
        end--]]
        
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