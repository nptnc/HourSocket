return function(api)
    local module = {}

    local hook2 = function()
        local entities = getrenv()._G.Entities
        --[[entities[1].SwitchAnimation = api.createHook(entities[1].SwitchAnimation,function(hook,...)
            local args = {...}
            local blacklistedAnimations = {"Idle","Run"}

            -- we dont really need idle or run to be networked since they are already handled by the games ai when we create a player.
            if not table.find(blacklistedAnimations,args[3]) then
                local message = api.prepareMessage("animationChange",args[2],args[3])
                api.sendToServer(message)
            end
            return hook.call(...)
        end)--]]

        --[[getrenv()._G.TimeControl.Begin = api.createHook(getrenv()._G.TimeControl.Begin,function(hook)
            local message = api.prepareMessage("startTempo",getrenv()._G.TimePower,getrenv()._G.TimeControl.Special)
            api.sendToServer(message)
        end)--]]

        local rs = game:GetService("RunService")
        local entity = getrenv()._G.Entities[1] -- get the games player entity
        local lastInput = entity.Input
        rs.Heartbeat:Connect(function(dt)
            if lastInput ~= entity.Input and entity.Input ~= nil and entity.Input ~= false then
                local input = entity.Inputs[entity.Input] -- we need to get the actual input name lol
                if input == nil then
                    -- this shouldnt happen but protection is always needed when inserting new things into the codebase!
                    lastInput = entity.Input
                    return
                end

                local cf = workspace.CurrentCamera.CFrame

                local rx, ry, rz = cf:ToOrientation()
                local rotation = Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz))

                print(`networking input {input}`)
        
                local message = api.prepareMessage("doInput",
                    input,
                    api.hardOptimize(cf.Position.X),
                    api.hardOptimize(cf.Position.Y),
                    api.hardOptimize(cf.Position.Z),
                    api.hardOptimize(rotation.X),
                    api.hardOptimize(rotation.Y),
                    api.hardOptimize(rotation.Z)
                )
                api.sendToServer(message)
            end
            lastInput = entity.Input
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

    module.playerRegistered = function(userid)
        if userid ~= game.Players.LocalPlayer.UserId then
            return
        end
        if api.isHost() then
            return
        end
        api.destroyAllEntities()
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

        if (lastNetworkedRotation - pos).Magnitude < 1 and (lastNetworkedPosition - pos).Magnitude < 1 then
            return
        end
        
        local message = api.prepareMessage("updatePlayer",
            api.hardOptimize(pos.X),
            api.hardOptimize(pos.Y),
            api.hardOptimize(pos.Z),
            api.hardOptimize(rot.X),
            api.hardOptimize(rot.Y),
            api.hardOptimize(rot.Z)
        )

        api.sendToServer(message)

        lastNetworkedPosition = pos
        lastNetworkedRotation = rot

        lastUpdated = {pos,rot}
    end

    module.playerStateUpdate = function(userid,index,value)
        value = api.findOutVariable(userid,index,value)
        
        local messageplayer = api.registeredPlayers[userid]
        messageplayer.serverData[index] = value
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

            if getrenv()._G.GameState ~= "Combat" then
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
            --entity.SpeedMultiplier = 1
            
            for knockbackIndex,knockback in entity.knockback or {} do
                entity.Knockback[knockbackIndex].Knockback = knockback
            end

            for cooldownName,cooldownData in entity.Cooldowns do
                cooldownData.Cooldown = 0
                cooldownData.MaxCooldown = 0
            end
        end
    end

    module.playerEntityKnockbackUpdate = function(userid,index,x,y,z)
        local messageplayer = api.registeredPlayers[userid]
        if not messageplayer.knockback then
            messageplayer.knockback = {}
        end
        messageplayer.knockback[index] = Vector3.new(x,y,z)
    end

    module.onDisconnect = function()
        api.socket:Close()
    end

    return module
end