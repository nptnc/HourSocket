local start = function(executionMethod,localPath)
    setthreadidentity(2)

    if getgenv()._G.LEExecuted == true then
        return
    end
    getgenv()._G.LEExecuted = true
    
    local rs = game:GetService("RunService")
    local http = game:GetService("HttpService")
    
    local player = game.Players.LocalPlayer
    
    local char = player.Character
    char.Archivable = true
    
    local websocketLayer = {}
    local exploit = identifyexecutor()
    local supported = false

    local branch = "source"
    local github = `https://raw.githubusercontent.com/nptnc/HourSocket/{branch}/Client`

    local exploits = {
        {
            supportedExecutors = {"Electron","Electron V2"},
            websocketLayer = {
                request = function(what)
                    return request({
                        url = what,
                    }).Body
                end,
                connect = function(...)
                    return WebSocket.connect(...)
                end,
            },
        },
        {
            supportedExecutors = {"Krnl"},
            websocketLayer = {
                request = function(what)
                    return request({
                        Url = what,
                        Method = 'GET',
                    }).Body
                end,
                connect = function(...)
                    return Krnl.WebSocket.connect(...)
                end
            },
        },
    }

    for _,data in exploits do
        if table.find(data.supportedExecutors,exploit) then
            supported = true
            websocketLayer = data.websocketLayer
            print(`supported exploit found {exploit}!`)
        end
    end
    
    if supported == false then
        getgenv()._G.LEExecuted = false
        error(`{exploit} is not a supported exploit!`)
        return
    end
    
    local fps = 30
    local sinceLastFPS = 0
    local seperator = ":::" -- dont change, this has to be the same on the server and the client otherwise one or the other wont receive information.
    local connections = {}
    
    local modules = {
        "Gui",
        "Interface",
        "Entity",
        "MultiplayerQOL",
        "Player",
        "Game",
    }
    
    local api = {}
    local requiredModules = {}
    
    local messageIds = {
        disconnect = 0,
        registerPlayer = 1,
        updatePlayer = 2,
        updateState = 3,
        updateKnockback = 4,
        registerEntity = 5,
        updateEntityCF = 6,
        doInput = 8,
        updateEntityState = 9,
        pickTalent = 10,
        startTempo = 11,
        updateEntityKnockback = 12,
        worldStateChanged = 13,
        damageRequest = 14,
        entityInput = 15,
        sayChatMessage = 16,
        subjectPotionAdd = 17,
    }
    
    api.player = player
    api.registeredPlayers = {}
    api.globals = {}
    api.worldState = getrenv()._G.GameState
    api.previousWorldState = api.worldState

    local cutTable = function(t,ind)
        local newT = {}
        for index,value in t do
            if type(index) == "number" and index <= ind then
                continue
            end
            if type(index) == "number" then
                newT[index-ind] = value
                continue
            end
            newT[index] = value
        end
        return newT
    end
    
    local apiCall = function(method,callback,...)
        for moduleName, module in requiredModules do
            if not module[method] then
                continue
            end
            local args = {...}
            local success,error2 = pcall(function()
                if not callback then
                    module[method](table.unpack(args))
                    return
                end
                callback(table.unpack(module[method](table.unpack(args)) or {}))
            end)
            if success == false then
                warn(`an error occured while trying to call method of module {moduleName} {method}.\n{error2}`)
            end
        end
    end
    
    api.apiCall = apiCall
    
    api.doesPlayerHaveEntity = function(playerdata)
        if playerdata.entity == nil then
            return false
        end
        return true
    end
    
    api.isHost = function()
        return api.getMe().serverData.isHost
    end
    
    api.respawnPlayer = function()
        --[[hookToMyEntity()
    
        local aidata = getrenv()._G.Entities[1]
        if aidata then
            local aichar = aidata.Character
            game.Players.LocalPlayer.Character.Parent = workspace
            aichar:Destroy()
            local ui = aidata.BossGui
            if ui then
                ui:Destroy()
            end
            getrenv()._G.Entities[1] = nil
        end
        for _,frame in getrenv()._G.Player.PlayerGui.AllGui.AllFrame.Skills:GetChildren() do
            if not frame:IsA("Frame") then
                continue
            end
            frame:Destroy()
        end
        getrenv()._G.PreparePlayerCharacter({})--]]
    end

    api.encodeV3 = function(vector3)
        return `{vector3.X}_{vector3.Y}_{vector3.Z}`
    end
    
    api.destroyAllEntities = function()
        for index,aidata in getrenv()._G.Entities do
            if aidata.specialId then
                continue
            end
            if index == 1 then
                continue
            end
            local aichar = aidata.Character
            aichar:Destroy()
            local ui = aidata.BossGui
            if ui then
                ui:Destroy()
            end
            getrenv()._G.Entities[index] = nil
        end
    end
    
    api.findOutVariable = function(var)
        local newVar = var
        if newVar == "false" then
            newVar = false
        elseif newVar == "true" then
            newVar = true
        elseif tonumber(newVar) then
            newVar = tonumber(newVar)
        else
            newVar = var
        end
        return newVar
    end
    
    local findOutVariableFromString = {
        ["number"] = function(a)
            if not tonumber(a) then
                return false
            end
            return true,tonumber(a)
        end,
        ["string"] = function(a)
            return true,a -- its always a string lil bro.
        end,
        ["vector3"] = function(a)
            local split = string.split(a,"_")
            return true,Vector3.new(split[1],split[2],split[3])
        end,
        ["any"] = function(a)
            return true,a -- uh its any
        end,
        ["boolean"] = {{"false",false},{"true",true}},
    }
    api.findOutVariableWithTarget = function(var,targetType)
        if findOutVariableFromString[targetType] then
            if type(findOutVariableFromString[targetType]) == "function" then
                -- unimplemented
                local success,newValue = findOutVariableFromString[targetType](var)
                if not success then
                    return nil
                end
                return newValue
            elseif type(findOutVariableFromString[targetType]) == "table" then
                for _,variableValue in findOutVariableFromString[targetType] do
                    if variableValue[1] ~= var then
                        continue
                    end
                    return variableValue[2]
                end
            end
        end
    end
    
    api.createPlayer = function(playerdata)
        local entity = getrenv()._G.SpawnCreature({
            Name = playerdata.serverData.class,
            Bypass = true,
            IsPlayer = true,
        })
        if not entity then
            return
        end
        entity = getrenv()._G.Entities[entity]
        entity.DamageTeam = 1
        entity.specialId = tonumber(playerdata.serverData.id)
        entity.Character.Name = playerdata.serverData.id
        entity.Resources.Health = 10000
        
        local nametag = entity.Character.Head2.NameTag
        nametag.TextLabel.Text = playerdata.serverData.username or "no username?"
        nametag.TextLabel.TextColor3 = Color3.fromRGB(255,255,255)
        --[[entity.Interrupt = function()
            
        end--]]

        entity.NetworkFunctions = {}
        if entity.Name == "Class7" then
            entity.NetworkFunctions.addPotion = entity.ActionFunctions.AddPotion
            entity.ActionFunctions.AddPotion = api.createHook(entity.ActionFunctions.AddPotion,function(hook,...)
                return -- we return because we dont want to dictate what their potions are, we let them do it
            end)
        end
    
        if playerdata.cframe then
            entity.RootPart.CFrame = playerdata.cframe
        end
        return entity
    end
    
    api.len = function(a)
        local ind = 0
        for _,_ in a do
            ind += 1
        end
        return ind
    end
    
    api.optimize = function(n)
        return math.round(n * 50) / 50
    end
    
    api.hardOptimize = function(n)
        return math.round(n)
    end
    
    local packetsSentOut = 0
    local throttleAt = 70
    api.isThrottling = false
    api.sendToServer = function(...)
        if packetsSentOut > throttleAt then
            api.isThrottling = true
            apiCall("sentMessage",nil, packetsSentOut, packetsSentOut <= throttleAt and true or false)
            return
        end
        packetsSentOut += 1
        api.socket:Send(...)
        apiCall("sentMessage",nil, packetsSentOut, packetsSentOut <= throttleAt and true or false)
    end
    
    api.createHook = function(old,replace)
        local meta = {}
        meta.hook = true
        meta.old = old
        if typeof(old) == "table" and old.hook then
            meta.old = old.old
            print("overrided hook.") -- dont know when this will happen but it could!
        end
        meta.call = function(...)
            return meta.old(...)
        end
        setmetatable(meta,{
            __call = function(t,...)
                local args = {...}
                local args3 = table.pack(pcall(function()
                    local packedArgs = table.pack(replace(t,table.unpack(args)))
                    return table.unpack(packedArgs)
                end))
                if args3[1] == false then
                    warn(`caught an error in hooked function {debug.getinfo(old).name}\n{args3[2]}`)
                end
                local realArgs = cutTable(args3,1)
                return table.unpack(realArgs)
            end,
        })
        return meta
    end
    
    api.getMe = function()
        return api.registeredPlayers[player.UserId]
    end
    
    api.destroyPlayerEntity = function(userid)
        local targetPlayer = api.registeredPlayers[userid]
        if not targetPlayer.entity then
            return
        end
        getrenv()._G.Entities[targetPlayer.entity.Id].Character:Destroy()
        getrenv()._G.Entities[targetPlayer.entity.Id] = nil
        targetPlayer.entity = nil
    end
    
    api.prepareMessage = function(messageId,...)
        messageId = messageIds[messageId] or messageId
        local endString = `{messageId}{seperator}`
        if #{...} > 0 then
            for index,value in {...} do
                if index < #{...} then
                    endString ..= `{value}{seperator}`
                else
                    endString ..= `{value}`
                end
            end
        else
            endString = `{messageId}{seperator}{player.UserId}`
        end
        return endString
    end
    
    local hasLoadedModules = false 
    for index,module in modules do
        local success,error = pcall(function()
            if executionMethod == "github" then
                local response = loadstring(websocketLayer.request(`{github}/Modules/{module}.lua`))()
                requiredModules[module] = response(api)
            elseif executionMethod == "local" then
                local response = loadfile(`{localPath}/Modules/{module}.lua`)()
                requiredModules[module] = response(api)
            end
        end)
        if not success then
            warn(`caught an error trying to fetch module\n{error}`)
        end
        if index == #modules then
            hasLoadedModules = true
        end
    end
    repeat rs.Heartbeat:Wait() until hasLoadedModules
    apiCall("once")
    
    local messages = {}
    local messagesExpectedTypes = {}
    
    local expectMessage = function(id,types)
        print(`expected message {id}s response with {table.concat(types,", ")}`)
        messagesExpectedTypes[id] = {}
        for index,datatype in types do
            messagesExpectedTypes[id][index] = datatype
        end
    end
    
    local registerMessage = function(id,messageCallback)
        if type(id) == "string" then
            print(`registered message {messageIds[id]}`)
            messages[messageIds[id]] = messageCallback
            return
        end
        print(`registered message {id}`)
        messages[id] = messageCallback
    end
    
    local getEntityIdByEntity = function(entity)
        for entityId,entityData in getrenv()._G.Entities do
            if entityData == entity then
                return entityId
            end
        end
    end
    
    expectMessage(999,{"string"})
    registerMessage(999,function(errorMessage)
        print(`server caught error {errorMessage}`)
    end)
    
    expectMessage(0,{"number"})
    registerMessage(0,function(userId)
        apiCall("playerDisconnected",nil,userId)
        api.destroyPlayerEntity(userId)
        apiCall("createNotification",nil,`{api.registeredPlayers[userId].serverData.username} disconnected`)
        api.registeredPlayers[userId] = nil
        print(`received disconnect for player {userId}`)
    end)
    
    local registerPlayer = function(userid,data)
        if api.registeredPlayers[userid] then
            return
        end
    
        local chatColors = {
            Color3.fromRGB(255, 0, 72),
            Color3.fromRGB(247, 0, 255),
            Color3.fromRGB(0, 234, 255),
            Color3.fromRGB(77, 255, 0),
            Color3.fromRGB(255, 255, 0),
            Color3.fromRGB(255, 89, 0),
            Color3.fromRGB(255, 0, 0),
        }
    
        api.registeredPlayers[userid] = {
            model = nil,
            cframe = CFrame.new(data.position.X,data.position.Y,data.position.Z) * CFrame.Angles(math.rad(data.rotation.X),math.rad(data.rotation.Y),math.rad(data.rotation.Z)),
            chatcolor = chatColors[math.random(1,#chatColors)],
            serverData = data,
        }
    
        for index,value in api.registeredPlayers[userid].serverData do
            api.registeredPlayers[userid].serverData[index] = api.findOutVariable(value)
        end
        
        print(`received register player {userid}`)
    
        apiCall("playerRegistered",nil,userid,api.registeredPlayers[userid])
        if tonumber(userid) ~= player.UserId then
            return
        end
    end
    
    expectMessage(1,{"number","string","string","vector3","vector3","boolean","boolean"})
    registerMessage(1,function(userId,username,class,position,rotation,isHost,isMe)
        if isMe then
            userId = player.UserId
        end
        registerPlayer(userId,{
            username = username,
            class = class,
            position = position,
            rotation = rotation,
            id = userId,
            isHost = isHost,
        })
    end)
    
    expectMessage(2,{"number","vector3","vector3"})
    registerMessage(2,function(userid,position,rotation)
        if not api.registeredPlayers[userid] then
            warn(`no userid ({userid}, {typeof(userid)}) is not a userid`)
            return
        end
        local messageplayer = api.registeredPlayers[userid]
        messageplayer.cframe = CFrame.new(position.X,position.Y,position.Z) * CFrame.Angles(math.rad(rotation.X),math.rad(rotation.Y),math.rad(rotation.Z))
    end)
    
    expectMessage(3,{"number","any","any"})
    registerMessage(3,function(userid,key,value)
        if not api.registeredPlayers[userid] then
            warn(`no userid ({userid}) is not a userid`)
            return
        end
    
        local messageplayer = api.registeredPlayers[userid]
    
        if key == "class" then
            messageplayer.serverData[key] = api.findOutVariable(value)
            local entityId = getEntityIdByEntity(messageplayer.entity)
            local entity = getrenv()._G.Entities[entityId]
            if entity then
                entity.Character:Destroy()
                getrenv()._G.Entities[entityId] = nil
                messageplayer.entity = nil
            end
        end
    
        warn(userid,key,value)
        apiCall("playerStateUpdate",nil,userid,key,value)
    end)
    
    expectMessage(4,{"number","number","vector3"})
    registerMessage(4,function(userid,knockbackIndex,v3)
        apiCall("playerEntityKnockbackUpdate",nil,userid,knockbackIndex,v3)
    end)
    
    expectMessage(5,{"number","string","number","boolean","vector3","vector3"})
    registerMessage(5,function(entityid,entityname,damageTeam,isBoss,pos,rot)
        print(`received spawn entity packet {entityid} {entityname} {damageTeam} {isBoss} {pos} {rot}`)
    
        local realEntityId = getrenv()._G.SpawnCreature({
            Name = entityname,
            SpawnCFrame = CFrame.new(pos) * CFrame.Angles(math.rad(rot.X),math.rad(rot.Y),math.rad(rot.Z)),
            DamageTeam = damageTeam,
            IsBoss = isBoss,
            Bypass = true,
        })
    
        apiCall("networkedEntityCreated",nil,entityid,realEntityId,pos,rot)
    end)
    
    expectMessage(6,{"number","vector3","vector3"})
    registerMessage(6,function(entityid,pos,rot)
        apiCall("networkEntityUpdate",nil,entityid,pos,rot)
    end)
    
    expectMessage(8,{"number","string","vector3","vector3"})
    registerMessage(8,function(userid,input,cameraPos,cameraRot)
        local messageplayer = api.registeredPlayers[userid]
        local entity = messageplayer.entity
        if entity == nil then
            warn("cant do input, player entity is nil")
            return
        end
        entity.Input = input
        entity.InputTimer = 0.5
        entity.InputCameraCFrame = CFrame.new(cameraPos) * CFrame.Angles(math.rad(cameraRot.X),math.rad(cameraRot.Y),math.rad(cameraRot.Z))
        entity.InputFunctions[input](entity)
        if not entity.InputCameraCFrame then
            warn("cf is nil")
            return
        end
    
        print(`received input {input} {userid}`)
    end)
    
    expectMessage(9,{"number","any","any"})
    registerMessage(9,function(entityid,index,value)
        if index == "health" then
            value = tonumber(value)
        end
        apiCall("networkEntityStateUpdate",nil,entityid,index,value)
    end)
    
    expectMessage(10,{"number"})
    registerMessage(10,function(talentindex)
        apiCall("chooseTalent",nil,talentindex)
    end)
    
    expectMessage(11,{"string","number"})
    registerMessage(11,function(timeTarget,special)
        --apiCall("startTempo",nil,timeTarget,special)
    end)
    
    expectMessage(12,{"number","number","number","number","number"})
    registerMessage(12,function(entityid,knockbackIndex,x,y,z)
        apiCall("entityKnockbackUpdate",nil,entityid,knockbackIndex,Vector3.new(x,y,z))
    end)
    
    -- talent popup for non hosts.
    expectMessage(13,{"boolean","any"})
    registerMessage(13,function(state,isArena)
        if state == "Intermission" then
            isArena = api.findOutVariable(isArena)
    
            getrenv()._G.GameState = "Intermission"
            getrenv()._G.TimeEnabled = false
            getrenv()._G.SetCameraLock(false)
            local humrp = getrenv()._G.Entities[1].RootPart
            humrp.Anchored = true
            apiCall("gameShowTalentPopup")
            getrenv()._G.ArenaMode = isArena or false
        end
    end)
    
    -- damage entity for host
    expectMessage(14,{"number","number","number","string","string","number"})
    registerMessage(14,function(userid,entityid,damage,partname,damagename,screenshake)
        if not entityid then
            print("entity id is nil from network")
            return
        end
        print(`trying to deal damage to entity {entityid} from network!`)
        apiCall("gameDealDamage",nil,userid,entityid,damage,partname,damagename,screenshake)
    end)
    
    -- entity input
    expectMessage(15,{"number","number","string"})
    registerMessage(15,function(entityid,someIndex,input)
        if not entityid then
            print("entity id is nil from network")
            return
        end
        
        print(`doing entity input {input}`)
        apiCall("entityDoInput",nil,entityid,someIndex,input)
    end)
    
    -- player text messages
    expectMessage(16,{"number","string"})
    registerMessage(16,function(userid,text)
        local messageplayer = api.registeredPlayers[userid]
        game.StarterGui:SetCore("ChatMakeSystemMessage",{
            Text = `[{messageplayer.serverData.username}]: {text}`,
            Color = messageplayer.chatcolor,
            Font = Enum.Font.SourceSansBold,
            TextSize = 18,
        })
    end)
    
    -- damage for host to non hosts
    expectMessage(17,{"number","number","number","string","string","number"})
    registerMessage(17,function(userid,entityid,damage,partname,damagename,screenshake)
        if not entityid then
            print("entity id is nil from network")
            return
        end
        print(`trying to deal damage to entity {entityid} from network, non host`)
    end)

    -- subject potion sync
    expectMessage(18,{"number","string","number"})
    registerMessage(18,function(userid,section,index)
        if not api.registeredPlayers[userid].entity then
            return
        end
        api.registeredPlayers[userid].entity.NetworkFunctions.addPotion({
            section,
            index,
        })
        print(`subject potion add`)
    end)
    
    player.Chatted:Connect(function(messagecontents)
        if not api.connected then
            return
        end
    
        local message = api.prepareMessage("sayChatMessage",messagecontents)
        api.sendToServer(message)
    end)
    
    api.disconnect = function()
        if api.socket then
            api.socket:Close()
            api.connected = false
            api.socket = nil
            return
        end
        for userid,_ in api.registeredPlayers do
            api.destroyPlayerEntity(userid)
        end
        api.registeredPlayers = {}
        apiCall("createNotification",nil,`disconnected from server`)
        apiCall("onDisconnected")
    end
    
    api.tryToConnect = function(ip)
        local success,error = pcall(function()
            api.socket = websocketLayer.connect(ip)
        end)
        if not success then
            apiCall("createNotification",nil,`failed to connect to server\neither the server is down or you used the wrong connection type.`)
            return
        end
        api.connected = true
    
        apiCall("connected")
        apiCall("createNotification",nil,`connected to server {ip}`)
    
        api.socket.OnMessage:Connect(function(msg)
            local args = string.split(msg,seperator)
            local messageId = tonumber(args[1])
            if not messages[messageId] then
                warn(`message id {messageId} is not a valid message id.\nthis usually means the server is modified.`)
                return
            end
            apiCall("receivedMessage")
    
            if messagesExpectedTypes[messageId] and #args-1 > #messagesExpectedTypes[messageId] then
                warn(`message id {messageId} expected {#messagesExpectedTypes[messageId]} arguments, got {#args-1}.\nthis usually means the server is modified.`)
                return
            end
    
            local newArgs = cutTable(args,1)
            for index,value in newArgs do
                if not messagesExpectedTypes[messageId] then
                    continue
                end
                if not messagesExpectedTypes[messageId][index] then
                    continue
                end
                value = api.findOutVariableWithTarget(value,messagesExpectedTypes[messageId][index])
                if value == nil then
                    warn(`message id {messageId} at index {index} got {value} expected {messagesExpectedTypes[messageId][index]}.\nthis usually means the server is modified`)
                    return
                end
                newArgs[index] = value
            end
            messages[messageId](table.unpack(newArgs))
        end)
    
        api.socket.OnClose:Connect(function()
            api.disconnect()
        end)
    end
    
    workspace.ChildRemoved:Connect(function(child)
        if not api.connected then
            return
        end
        if api.registeredPlayers[tonumber(child.Name)] == nil then
            return
        end
        repeat rs.Heartbeat:Wait() until getrenv()._G.GameState ~= "Combat"
        api.registeredPlayers[tonumber(child.Name)].entity = nil
    end)
    
    local hookToMyEntity = function()
        print("hooked to me")
        apiCall("playerRespawned")
    end
    
    if getrenv()._G.Entities[1] ~= nil then
        hookToMyEntity()
    end
    
    local sinceLastWipe = tick()
    
    local lastMyEntity = getrenv()._G.Entities[1]
    local lastClass = getrenv()._G.Class
    table.insert(connections,rs.Heartbeat:Connect(function(dt)
        if not api.connected then
            return
        end

        api.worldState = getrenv()._G.GameState
        if api.previousWorldState ~= api.worldState then
            api.previousWorldState = api.worldState
            local message = api.prepareMessage("worldStateChanged",api.worldState)
            api.sendToServer(message)
        end
    
        if tick() - sinceLastWipe > 1 then
            sinceLastWipe = tick()
            packetsSentOut = 0
            apiCall("resetPacketInformation")
            api.isThrottling = false
        end
    
        if api.getMe() == nil then
            return
        end
    
        if not api.getMe().serverData.isHost then
            getrenv()._G.EnemyCap = 0
        else
            getrenv()._G.EnemyCap = 2
        end
    
        if getrenv()._G.GameState ~= "Combat" then
            for userid,_ in api.registeredPlayers do
                api.destroyPlayerEntity(userid)
            end
        end
    
        if getrenv()._G.Entities ~= nil and lastMyEntity ~= getrenv()._G.Entities[1] then
            hookToMyEntity()
        end
    
        apiCall("update")
    
        if lastClass ~= getrenv()._G.Class then
            -- update class lol
            local message = api.prepareMessage("updateState","class",getrenv()._G.Class)
            api.sendToServer(message)
        end
    
        lastMyEntity = getrenv()._G.Entities[1]
        lastClass = getrenv()._G.Class
     
        if tick() - sinceLastFPS < 1/fps then
            return
        end
        sinceLastFPS = tick()
    
        apiCall("updateWithFPS")
    end))
    
    game.Players.PlayerRemoving:Connect(function(aaa)
        api.disconnect()
    end)
end
return start