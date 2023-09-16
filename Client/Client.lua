local http = game:GetService("HttpService")
local rs = game:GetService("RunService")

local player = game.Players.LocalPlayer

local char = player.Character
char.Archivable = true

local ip = "salamithecat.com"
local port = "7171"

local fps = 50
local sinceLastFPS = 0
local seperator = ":::" -- dont change, this has to be the same on the server and the client otherwise one or the other wont receive information.
local connections = {}

local socket = Krnl.WebSocket.connect(`http://{ip}:{port}`)

local branch = "main"
local github = `https://raw.githubusercontent.com/nptnc/HoursMultiplayer/{branch}/Client`

local modules = {
    "Gui",
    "Entity",
    "MultiplayerQOL",
    "Player",
}

local main = {}

main.player = player
main.socket = socket
main.registeredPlayers = {}
main.globals = {}

main.doesPlayerHaveEntity = function(playerdata)
    if playerdata.entity == nil then
        return false
    end
    return true
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

main.createHook = function(old,replace)
    local meta = {}
    meta.old = old
    meta.call = function(...)
        return meta.old(...)
    end
    setmetatable(meta,{
        __call = function(t,...)
            local packedArgs = table.pack(replace(t,...))
            -- debug here if you want lol
            return table.unpack(packedArgs)
        end,
    })
    return meta
end

main.getMe = function()
    return main.registeredPlayers[player.UserId]
end

local messageIds = {
    disconnect = 0,
    registerPlayer = 1,
    updatePlayer = 2,
    updateState = 3,
    doAttack = 4,
    registerEntity = 5,
    updateEntity = 6,
}

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

local requiredModules = {}
for _,module in modules do
    requiredModules[module] = loadstring(game:HttpGet(`{github}/Modules/{module}.lua`))()(main)
    local newModule = requiredModules[module]
    if newModule.once then
        newModule.once()
    end
end

local apiCall = function(method,...)
    for moduleName, module in requiredModules do
        if not module[method] then
            continue
        end
        module[method](...)
    end
end

local messages = {}

local findOutVariable = function(var)
    local newVar = var
    if newVar == "false" then
        newVar = false
    elseif newVar == "true" then
        newVar = true
    else
        newVar = var
    end
    return newVar
end

local registerMessage = function(id,messageCallback)
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

    main.registeredPlayers[userId].entity:Destroy()

    main.registeredPlayers[userId] = nil
    print(`received disconnect for player {userId}`)
end)

local registerPlayer = function(userid,data)
    if main.registeredPlayers[userid] then
        return
    end
    main.registeredPlayers[userid] = {
        model = nil,
        serverData = data,
    }

    for index,value in main.registeredPlayers[userid].serverData do
        main.registeredPlayers[userid].serverData[index] = findOutVariable(value)
    end
    
    print(`received register player {userid}`)

    apiCall("playerRegistered",userid,main.registeredPlayers[userid])
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
    messageplayer.serverData[key] = findOutVariable(value)

    if key == "class" then
        local entityId = getEntityIdByEntity(messageplayer.entity)
        local entity = getrenv()._G.Entities[entityId]
        entity.Character:Destroy()
        getrenv()._G.Entities[entityId] = nil
        messageplayer.entity = nil
    end
end)

registerMessage(4,function(userid,action)
    userid = tonumber(userid)

    if not main.registeredPlayers[userid] then
        warn(`no userid ({userid}) is not a userid`)
        return
    end

    main.registeredPlayers[userid].entity.ActionFunctions[action]()
end)

registerMessage(5,function(entityid,entityname,damageTeam,isBoss,posx,posy,posz)
    damageTeam = tonumber(damageTeam)
    isBoss = findOutVariable(isBoss)
    posx = tonumber(posx)
    posy = tonumber(posy)
    posz = tonumber(posz)

    print(`received spawn entity packet {entityname} {damageTeam} {isBoss} {posx} {posy} {posz}`)

    getrenv()._G.SpawnCreature({
        Name = entityname,
        SpawnCFrame = CFrame.new(posx,posy,posz),
        DamageTeam = damageTeam,
        IsBoss = isBoss,
        Bypass = true,
    })
end)

socket.OnMessage:Connect(function(msg)
    local args = string.split(msg,seperator)
    --warn(`server sent {msg}`)
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

workspace.ChildRemoved:Connect(function(child)
    if main.registeredPlayers[tonumber(child.Name)] == nil then
        return
    end
    repeat rs.Heartbeat:Wait() until getrenv()._G.GameState ~= "Combat"
    repeat rs.Heartbeat:Wait() until getrenv()._G.GameState == "Combat"
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

hookToMyEntity()

local lastMyEntity = getrenv()._G.Entities[1]
local lastClass = getrenv()._G.Class
table.insert(connections,rs.Heartbeat:Connect(function(dt)
    if main.getMe() == nil then
        return
    end

    if getrenv()._G.Entities ~= nil and lastMyEntity ~= getrenv()._G.Entities[1] then
        hookToMyEntity()
    end

    apiCall("update")

    if lastClass ~= getrenv()._G.Class then
        -- update class lol
        local message = main.prepareMessage("updateState","class",getrenv()._G.Class)
        main.socket:Send(message)
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