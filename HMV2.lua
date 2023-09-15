local http = game:GetService("HttpService")
local rs = game:GetService("RunService")

local player = game.Players.LocalPlayer

local char = player.Character
char.Archivable = true

local ip = "salamithecat.com"
local port = "7171"

local fps = 50
local sinceLastFPS = 0
local seperator = ":::" -- dont change
local connections = {}

local socket = Krnl.WebSocket.connect(`http://{ip}:{port}`)

local messages = {}
local messageIds = {
    disconnect = 0,
    registerPlayer = 1,
    updatePlayer = 2,
    updateState = 3,
    doAttack = 4,
    registerEntity = 5,
}

local prepareMessage = function(messageId,...)
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

local findOutVariable = function(var)
    local newVar = var
    if newVar == "false" then
        warn("false")
        newVar = false
    elseif newVar == "true" then
        warn("true")
        newVar = true
    else
        warn(`is something other "{var}"`)
        newVar = var
    end
    return newVar
end

local createHook = function(old,replace)
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

local registerMessage = function(id,messageCallback)
    messages[id] = messageCallback
end

local registeredPlayers = {}

local getMe = function()
    return registeredPlayers[player.UserId]
end

local isClientRegistered = false

registerMessage(999,function(errorMessage)
    print(`server caught error {errorMessage}`)
end)

registerMessage(0,function(userId)
    userId = tonumber(userId)

    registeredPlayers[userId].entity:Destroy()

    registeredPlayers[userId] = nil
    print(`received disconnect for player {userId}`)
end)

local registerPlayer = function(userid,data)
    if registeredPlayers[userid] then
        return
    end
    registeredPlayers[userid] = {
        model = nil,
        serverData = data,
    }

    for index,value in registeredPlayers[userid].serverData do
        registeredPlayers[userid].serverData[index] = findOutVariable(value)
    end
    
    print(`received register player {userid}`)
    if tonumber(userid) ~= player.UserId then
        return
    end
    isClientRegistered = true
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

    if not registeredPlayers[userid] then
        warn(`no userid ({userid}) is not a userid`)
        return
    end
    local messageplayer = registeredPlayers[userid]
    messageplayer.cframe = CFrame.new(x,y,z) * CFrame.Angles(math.rad(xr),math.rad(yr),math.rad(zr))
end)

registerMessage(3,function(userid,key,value)
    userid = tonumber(userid)

    if not registeredPlayers[userid] then
        warn(`no userid ({userid}) is not a userid`)
        return
    end

    local messageplayer = registeredPlayers[userid]
    messageplayer.serverData[key] = findOutVariable(value)
end)

registerMessage(4,function(userid,action)
    userid = tonumber(userid)

    if not registeredPlayers[userid] then
        warn(`no userid ({userid}) is not a userid`)
        return
    end

    registeredPlayers[userid].entity.ActionFunctions[action]()
end)

registerMessage(5,function(entityid,entityname,damageTeam,isBoss,posx,posy,posz)
    damageTeam = tonumber(damageTeam)
    isBoss = findOutVariable(isBoss)
    posx = tonumber(posx)
    posy = tonumber(posy)
    posz = tonumber(posz)
    
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
    if registeredPlayers[tonumber(child.Name)] == nil then
        return
    end
    repeat rs.Heartbeat:Wait() until getrenv()._G.GameState ~= "Combat"
    repeat rs.Heartbeat:Wait() until getrenv()._G.GameState == "Combat"
    registeredPlayers[tonumber(child.Name)].entity = nil
end)

getrenv()._G.SpawnCreature = createHook(getrenv()._G.SpawnCreature,function(hook,...)
    local args = {...}
    args = args[1]

    local me = getMe()
    if me.serverData.isHost == true then
        warn("i am host!")
        local entityId = hook.call(...)
        local entity = getrenv()._G.Entities[entityId]
        if not args.IsPlayer then
            local message = prepareMessage("registerEntity",args.Name,entityId,args.DamageTeam or 1,args.IsBoss or false,entity.RootPart.Position.X,entity.RootPart.Position.Y,entity.RootPart.Position.Z)
            socket:Send(message)
        else
            warn("tried to register a entity which is a player!")
        end
        return entityId
    elseif me.serverData.isHost == false then
        warn("i am not host!")
        if args.Bypass ~= true then
            warn("no bypass bye bye")
            return
        end
        return hook.call(...)
    end
    warn("unexpected error?, none of the other functions were called")
    return hook.call(...)
end)

local createPlayer = function(playerdata)
    local entity = getrenv()._G.SpawnCreature({
        Name = playerdata.serverData.class,
        Bypass = true,
        IsPlayer = true,
    })
    print(entity)
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
    --entity.Character.
    return entity
end

-- register our player on the servers end, player userid already gets sent per message so we jsut add player name
local message = prepareMessage("registerPlayer",player.Name,getrenv()._G.Class)
socket:Send(message)

--[[
    hookfunction just crashes. this is on hold until synapse is back
--]]

--[[local actions = getrenv()._G.Entities[1].ActionFunctions
for actionName,actionFunction in actions do
    local old
    old = hookfunction(actionFunction,function(...)
        local message = prepareMessage("doAttack",actionName)
        socket:Send(message)
        return old(...)
    end)
end--]]

local hookToMyEntity = function()
    print("hooked to me")

    warn(`dead state changed false`)
    getrenv()._G.Entities[1].Dead = false

    local message = prepareMessage("updateState","dead",false)
    socket:Send(message)

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
        local message = prepareMessage("updateState","dead",value)
        socket:Send(message)
    end)
end

hookToMyEntity()

local lastMyEntity = getrenv()._G.Entities[1]
table.insert(connections,rs.Heartbeat:Connect(function(dt)
    if getMe() == nil then
        return
    end

    local doesPlayerHaveEntity = function(playerdata)
        if playerdata.entity == nil then
            return false
        end
        return true
    end

    if lastMyEntity ~= getrenv()._G.Entities[1] then
        hookToMyEntity()
    end

    if registeredPlayers[player.UserId] and registeredPlayers[player.UserId].serverData.isHost then
        -- yo
    end
    lastMyEntity = getrenv()._G.Entities[1]

    for userid,playerdata in registeredPlayers do
        if userid == player.UserId then
            -- no creaty yourselfy!
            continue
        end

        if not playerdata.cframe then
            continue
        end

        -- no player entity?, create one!
        if doesPlayerHaveEntity(playerdata) == false then
            local entity = createPlayer(playerdata)
            playerdata.entity = entity
        end
        -- still no player entity? fuck off!
        if doesPlayerHaveEntity(playerdata) == false then
            continue
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
 
    if tick() - sinceLastFPS < 1/fps then
        return
    end
    sinceLastFPS = tick()

    local pos = char.HumanoidRootPart.Position
    local rot = char.HumanoidRootPart.Rotation

    local roundy = function(numby)
        return math.round(numby * 50) / 50
    end

    local message = prepareMessage("updatePlayer",roundy(pos.X),roundy(pos.Y),roundy(pos.Z),roundy(rot.X),roundy(rot.Y),roundy(rot.Z))
    socket:Send(message)
end))

game.Players.PlayerRemoving:Connect(function()
    socket:Close()
end)
