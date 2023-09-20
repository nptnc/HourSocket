setthreadidentity(2)

if getgenv()._G.LEExecuted then
    return
end
getgenv()._G.LEExecuted = true

local http = game:GetService("HttpService")
local rs = game:GetService("RunService")

local player = game.Players.LocalPlayer

local char = player.Character
char.Archivable = true

local fps = 30
local sinceLastFPS = 0
local seperator = ":::" -- dont change, this has to be the same on the server and the client otherwise one or the other wont receive information.
local connections = {}

local branch = "main"
local github = `https://raw.githubusercontent.com/nptnc/HourSocket/{branch}/Client`

local modules = {
    "Gui",
    "Interface",
    "Entity",
    "MultiplayerQOL",
    "Player",
    "Game",
}

local main = {}
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
    intermissionStarted = 13,
    damageRequest = 14,
}

main.player = player
main.registeredPlayers = {}
main.globals = {}

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
            warn(`an error occured while trying to call method of module {moduleName}.\n{error2}`)
        end
    end
end

main.apiCall = apiCall

main.doesPlayerHaveEntity = function(playerdata)
    if playerdata.entity == nil then
        return false
    end
    return true
end

main.isHost = function()
    return main.getMe().serverData.isHost
end

main.findOutVariable = function(var)
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

main.createPlayer = function(playerdata)
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

    if playerdata.cframe then
        entity.RootPart.CFrame = playerdata.cframe
    end
    return entity
end

main.len = function(a)
    local ind = 0
    for _,_ in a do
        ind += 1
    end
    return ind
end

main.optimize = function(n)
    return math.round(n * 50) / 50
end

main.hardOptimize = function(n)
    return math.round(n)
end

local packetsSentOut = 0
local throttleAt = 70
main.isThrottling = false
main.sendToServer = function(...)
    if packetsSentOut > throttleAt then
        main.isThrottling = true
        apiCall("sentMessage",nil, packetsSentOut, packetsSentOut <= throttleAt and true or false)
        return
    end
    packetsSentOut += 1
    main.socket:Send(...)
    apiCall("sentMessage",nil, packetsSentOut, packetsSentOut <= throttleAt and true or false)
end

main.createHook = function(old,replace)
    local meta = {}
    meta.old = old
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
            local realArgs = {}
            for index,value in args3 do
                if index == 1 then
                    continue
                end
                realArgs[tonumber(index) and index-1 or index] = value
            end
            return table.unpack(realArgs)
        end,
    })
    return meta
end

main.getMe = function()
    return main.registeredPlayers[player.UserId]
end

main.destroyPlayerEntity = function(userid)
    local targetPlayer = main.registeredPlayers[userid]
    if not targetPlayer.entity then
        return
    end
    getrenv()._G.Entities[targetPlayer.entity.Id].Character:Destroy()
    getrenv()._G.Entities[targetPlayer.entity.Id] = nil
    targetPlayer.entity = nil
end

main.prepareMessage = function(messageId,...)
    messageId = messageIds[messageId] or messageId
    local endString = `{messageId}{seperator}{player.UserId}{seperator}`
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

-- i have no idea if pcalls yield,m they progbably dont tho

local hasLoadedModules = false 
for index,module in modules do
    local success,error = pcall(function()
        local response = loadstring(request({
            Url = `{github}/Modules/{module}.lua`,
            Method = 'GET', -- <optional> | GET/POST/HEAD, etc.
        }).Body)()
        requiredModules[module] = response(main)
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

registerMessage(999,function(errorMessage)
    print(`server caught error {errorMessage}`)
end)

registerMessage(0,function(userId)
    userId = tonumber(userId)

    apiCall("playerDisconnected",nil,userId)
    main.destroyPlayerEntity(userId)
    main.registeredPlayers[userId] = nil
    print(`received disconnect for player {userId}`)
end)

local registerPlayer = function(userid,data)
    if main.registeredPlayers[userid] then
        return
    end
    main.registeredPlayers[userid] = {
        model = nil,
        cframe = CFrame.new(data.position[1],data.position[2],data.position[3]) * CFrame.Angles(math.rad(data.rotation[1]),math.rad(data.rotation[2]),math.rad(data.rotation[3])),
        serverData = data,
    }

    for index,value in main.registeredPlayers[userid].serverData do
        main.registeredPlayers[userid].serverData[index] = main.findOutVariable(value)
    end
    
    print(`received register player {userid}`)

    apiCall("playerRegistered",nil,userid,main.registeredPlayers[userid])
    if tonumber(userid) ~= player.UserId then
        return
    end

    warn("client registered")
end

registerMessage(1,function(userId,jsonDataForPlayer)
    userId = tonumber(userId)
    if userId == -1 then
        local decoded = http:JSONDecode(jsonDataForPlayer)
        for foundUserId,data in decoded do
            registerPlayer(tonumber(foundUserId),data)
        end
    else
        local decoded = http:JSONDecode(jsonDataForPlayer)
        registerPlayer(userId,decoded)
    end
end)

registerMessage(2,function(userid,x,y,z,xr,yr,zr)
    userid = tonumber(userid)

    if not main.registeredPlayers[userid] then
        warn(`no userid ({userid}) is not a userid`)
        return
    end
    local messageplayer = main.registeredPlayers[userid]
    messageplayer.cframe = CFrame.new(x,y,z) * CFrame.Angles(math.rad(xr),math.rad(yr),math.rad(zr))
end)

registerMessage(3,function(userid,key,value)
    userid = tonumber(userid)

    if not main.registeredPlayers[userid] then
        warn(`no userid ({userid}) is not a userid`)
        return
    end

    local messageplayer = main.registeredPlayers[userid]

    if key == "class" then
        messageplayer.serverData[key] = main.findOutVariable(value)
        local entityId = getEntityIdByEntity(messageplayer.entity)
        local entity = getrenv()._G.Entities[entityId]
        entity.Character:Destroy()
        getrenv()._G.Entities[entityId] = nil
        messageplayer.entity = nil
    end
    apiCall("playerStateUpdate",nil,userid,key,value)
end)

registerMessage(4,function(userid,knockbackIndex,x,y,z)
    userid = tonumber(userid)
    knockbackIndex = tonumber(knockbackIndex)
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)

    apiCall("playerEntityKnockbackUpdate",nil,userid,knockbackIndex,Vector3.new(x,y,z))
end)

registerMessage(5,function(entityid,entityname,damageTeam,isBoss,posx,posy,posz)
    entityid = tonumber(entityid)
    damageTeam = tonumber(damageTeam)
    isBoss = main.findOutVariable(isBoss)
    posx = tonumber(posx)
    posy = tonumber(posy)
    posz = tonumber(posz)

    print(`received spawn entity packet {entityid} {entityname} {damageTeam} {isBoss} {posx} {posy} {posz}`)

    local realEntityId = getrenv()._G.SpawnCreature({
        Name = entityname,
        SpawnCFrame = CFrame.new(posx,posy,posz),
        DamageTeam = damageTeam,
        IsBoss = isBoss,
        Bypass = true,
    })

    apiCall("networkedEntityCreated",nil,entityid,realEntityId,posx,posy,posz)
end)

registerMessage(6,function(entityid,posx,posy,posz,rosx,rosy,rosz)
    entityid = tonumber(entityid)
    posx = tonumber(posx)
    posy = tonumber(posy)
    posz = tonumber(posz)
    rosx = tonumber(rosx)
    rosy = tonumber(rosy)
    rosz = tonumber(rosz)

    apiCall("networkEntityUpdate",nil,entityid,posx,posy,posz,rosx,rosy,rosz)
end)

registerMessage("doInput",function(userid,input,posx,posy,posz,rotx,roty,rotz)
    userid = tonumber(userid)
    posx = tonumber(posx)
    posy = tonumber(posy)
    posz = tonumber(posz)
    rotx = tonumber(rotx)
    roty = tonumber(roty)
    rotz = tonumber(rotz)

    local messageplayer = main.registeredPlayers[userid]
    local entity = messageplayer.entity

    local realInput = nil
    for index,value in entity.Inputs do
        if value == input then
            realInput = index
        end 
    end
    
    if not realInput then
        warn("input non existent cant input.")
        return
    end

    entity.Input = realInput
    entity.InputTimer = 0.5
    entity.InputCameraCFrame = CFrame.new(posx,posy,posz) * CFrame.Angles(math.rad(rotx),math.rad(roty),math.rad(rotz))
    if not entity.InputCameraCFrame then
        warn("cf is nil")
        return
    end

    print(`received input {input} {realInput} {userid}`)
    --entity.InputFunctions[input](entity)
end)

registerMessage(9,function(entityid,index,value)
    entityid = tonumber(entityid)
    if index == "health" then
        value = tonumber(value)
    end
    apiCall("networkEntityStateUpdate",nil,entityid,index,value)
end)

registerMessage(10,function(talentindex)
    talentindex = tonumber(talentindex)
    apiCall("chooseTalent",nil,talentindex)
end)

registerMessage(11,function(timeTarget,special)
    special = tonumber(special)
    apiCall("startTempo",nil,timeTarget)
end)

registerMessage(12,function(entityid,knockbackIndex,x,y,z)
    entityid = tonumber(entityid)
    knockbackIndex = tonumber(knockbackIndex)
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)

    apiCall("entityKnockbackUpdate",nil,entityid,knockbackIndex,Vector3.new(x,y,z))
end)

registerMessage(13,function(isArena)
    isArena = main.findOutVariable(isArena)

    getrenv()._G.ArenaMode = isArena or false
    getrenv()._G.GameState = "Intermission"
    getrenv()._G.TimeEnabled = false
    local humrp = getrenv()._G.Entities[1].RootPart
    humrp.Anchored = true
    apiCall("gameShowTalentPopup")
end)

registerMessage(14,function(userid,entityid,damage,partname,damagename,screenshake)
    userid = tonumber(userid)
    entityid = tonumber(entityid)
    damage = tonumber(damage)
    screenshake = tonumber(screenshake)

    print("trying to deal damage from network!")
    apiCall("gameDealDamage",nil,userid,entityid,damage,partname,damagename,screenshake)
end)

main.disconnect = function()
    if not main.socket then
        return
    end
    main.socket:close()
    main.connected = false
    main.socket = nil
    for userid,_ in main.registeredPlayers do
        main.destroyPlayerEntity(userid)
    end
    main.registeredPlayers = {}
end

main.tryToConnect = function(ip)
    local socket = Krnl.WebSocket.connect(ip)
    main.socket = socket
    main.connected = true

    apiCall("connected")
    apiCall("createNotification",nil,`connected to server {ip}`)

    socket.OnMessage:Connect(function(msg)
        local args = string.split(msg,seperator)
        --warn(`server sent {msg}`)
        apiCall("receivedMessage")
        local messageId = tonumber(args[1])
        local newArgs = {}
        for index,value in args do
            if index == 1 then
                continue
            end
            newArgs[index-1] = value
        end
        if not messages[messageId] then
            warn(`message id {messageId} does not exist.`)
            return
        end
        messages[messageId](table.unpack(newArgs))
    end)

    socket.OnClose:Connect(function()
        warn("Connection was closed")
    end)
end

workspace.ChildRemoved:Connect(function(child)
    if not main.connected then
        return
    end
    if main.registeredPlayers[tonumber(child.Name)] == nil then
        return
    end
    repeat rs.Heartbeat:Wait() until getrenv()._G.GameState ~= "Combat"
    main.registeredPlayers[tonumber(child.Name)].entity = nil
end)

local hookToMyEntity = function()
    print("hooked to me")

    warn(`dead state changed false`)
    getrenv()._G.Entities[1].Dead = false

    apiCall("playerRespawned")

    local getVariableChanged = function(a,b,onChanged)
        local last = a[b]
        rs.Heartbeat:Connect(function(dt)
            if last ~= a[b] then
                onChanged(a[b])
            end
            last = a[b]
        end)
    end
    
    getVariableChanged(getrenv()._G.Entities[1],"Dead",function(value)
        warn(`dead state changed {value}`)
        if value then
            apiCall("playerDied")
        end
    end)
end

if getrenv()._G.Entities[1] ~= nil then
    hookToMyEntity()
end

local sinceLastWipe = tick()

local lastMyEntity = getrenv()._G.Entities[1]
local lastClass = getrenv()._G.Class
table.insert(connections,rs.Heartbeat:Connect(function(dt)
    if not main.connected then
        return
    end

    if tick() - sinceLastWipe > 1 then
        sinceLastWipe = tick()
        packetsSentOut = 0
        apiCall("resetPacketInformation")
        main.isThrottling = false
    end

    if main.getMe() == nil then
        return
    end

    if not main.getMe().serverData.isHost then
        getrenv()._G.EnemyCap = 0
    else
        getrenv()._G.EnemyCap = 2
    end

    if getrenv()._G.GameState ~= "Combat" then
        for userid,_ in main.registeredPlayers do
            main.destroyPlayerEntity(userid)
        end
    end

    if getrenv()._G.Entities ~= nil and lastMyEntity ~= getrenv()._G.Entities[1] then
        hookToMyEntity()
    end

    apiCall("update")

    if lastClass ~= getrenv()._G.Class then
        -- update class lol
        local message = main.prepareMessage("updateState","class",getrenv()._G.Class)
        main.sendToServer(message)
    end

    lastMyEntity = getrenv()._G.Entities[1]
    lastClass = getrenv()._G.Class
 
    if tick() - sinceLastFPS < 1/fps then
        return
    end
    sinceLastFPS = tick()

    apiCall("updateWithFPS")
end))

game.Players.PlayerRemoving:Connect(function()
    apiCall("onDisconnect")
end)