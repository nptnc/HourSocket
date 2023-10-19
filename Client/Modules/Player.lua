return function(api)
    local module = {}

    local toDisconnect = {}

    local getVector3Hard = function(v3)
        return Vector3.new(api.hardOptimize(v3.X),api.hardOptimize(v3.Y),api.hardOptimize(v3.Z))
    end

    local hook2 = function()
        --[[getrenv()._G.TimeControl.Begin = api.createHook(getrenv()._G.TimeControl.Begin,function(hook)
            local message = api.prepareMessage("startTempo",getrenv()._G.TimePower,getrenv()._G.TimeControl.Special)
            api.sendToServer(message)
        end)--]]

        local rs = game:GetService("RunService")
        local entity = getrenv()._G.Entities[1] -- get the games player entity

        local canDoInput = function(input)
            if entity.Cooldowns[input] and entity.Cooldowns[input].Cooldown > 0 and entity.Cooldowns[input].Charges > 0 then
                return false
            end
            return true
        end

        if entity.Name == "Class7" then
            entity.ActionFunctions.AddPotion = api.createHook(entity.ActionFunctions.AddPotion,function(hook,...)
                local args = {...}
                args = args[1]

                local message = api.prepareMessage("subjectPotionAdd",
                    args[1],
                    args[2]
                )
                api.sendToServer(message)
                return hook.call(...)
            end)
        end
        
        local lastInput = entity.Input
        local lastInputTimer = entity.InputTimer
        table.insert(toDisconnect,rs.Stepped:Connect(function(dt)
            if lastInput ~= entity.Input and entity.Input ~= nil and canDoInput() and entity.Input ~= false or lastInput == entity.Input and lastInputTimer < entity.InputTimer and canDoInput() then
                local input = entity.Inputs[entity.Input] -- we need to get the actual input name lol
                if input == nil then
                    -- this shouldnt happen but protection is always needed when inserting new things into the codebase!
                    lastInput = entity.Input
                    return
                end

                local cf = workspace.CurrentCamera.CFrame

                local rx, ry, rz = cf:ToOrientation()
                local rot = getVector3Hard(Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz)))
                local pos = getVector3Hard(cf.Position)

                print(`networking input {input}`)

                local message = api.prepareMessage("doInput",
                    input,
                    api.encodeV3(pos),
                    api.encodeV3(rot)
                )
                api.sendToServer(message)
            end
            lastInput = entity.Input
            lastInputTimer = entity.InputTimer
        end))
    end

    module.onDisconnected = function()
        for _,loop in toDisconnect do
            loop:Disconnect()
        end
    end

    module.playerRespawned = function()
        if not api.connected then
            return
        end
        
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

    module.connected = function()
        local entity = getrenv()._G.Entities[1] -- get the games player entity

        local message = api.prepareMessage("registerPlayer",
            api.player.Name,
            api.player.UserId,
            getrenv()._G.Class,
            api.encodeV3(entity.RootPart.Position),
            api.encodeV3(entity.RootPart.Rotation)
        )
        api.sendToServer(message)

        if getrenv()._G.Entities[1] then
            hook2()
        end
    end

    module.networkedSubjectPotion = function()
        
    end
    
    local lastUpdated = {Vector3.zero,Vector3.zero}
    module.updateWithFPS = function()
        local char = api.player.Character
        local pos = char.HumanoidRootPart.Position
        local rot = char.HumanoidRootPart.Rotation
        pos = getVector3Hard(pos)
        rot = getVector3Hard(rot)

        if lastUpdated[1] == pos and lastUpdated[2] == rot then
            return
        end
        
        local message = api.prepareMessage("updatePlayer",
            api.encodeV3(pos),
            api.encodeV3(rot)
        )

        api.sendToServer(message)

        lastUpdated = {pos,rot}
    end

    module.playerStateUpdate = function(userid,index,value)
        value = api.findOutVariable(userid,index,value)
        print(`updating player state {index} {value}`)
        
        api.registeredPlayers[userid].serverData[index] = value
    end

    local previousValues = {}
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
            local currentValues = {
                health = math.ceil(myEntity.Resources.Health),
            }

            if currentValues.health ~= previousValues.health then
                print("networking current health")
                local message = api.prepareMessage("updateState",
                    "health",
                    currentValues.health
                )
                api.sendToServer(message)
            end

            for knockbackIndex,knockbackData in myEntity.Knockback do
                if knockbackPreviousValues[knockbackIndex] == nil then
                    continue
                end
                local previousKnockback = knockbackPreviousValues[knockbackIndex]
                if previousKnockback ~= knockbackData.Knockback then
                    local message = api.prepareMessage("updateKnockback",
                        knockbackIndex,
                        api.encodeV3(knockbackData.Knockback)
                    )
                    api.sendToServer(message)
                end
            end
            for knockbackIndex,knockbackData in myEntity.Knockback do
                knockbackPreviousValues[knockbackIndex] = knockbackData.Knockback
            end
            
            previousValues = table.clone(currentValues)
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
            entity.Resources.Health = playerdata.serverData.health or 10000
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
        end
    end

    module.playerEntityKnockbackUpdate = function(userid,index,x,y,z)
        local messageplayer = api.registeredPlayers[userid]
        if not messageplayer.knockback then
            messageplayer.knockback = {}
        end
        messageplayer.knockback[index] = Vector3.new(x,y,z)
    end

    return module
end