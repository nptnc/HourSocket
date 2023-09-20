return function(api)
    local module = {}

    local fakeTimeControls = {}
    module.once = function()
        for _,timeControlModule in game.ReplicatedStorage.Scripts.TimeControl:GetChildren() do
            local module = require(timeControlModule)
            fakeTimeControls[timeControlModule.Name] = module
        end
    end

    module.playerRespawned = function()
        local tc = getrenv()._G.TimeControl
        tc.Begin = api.createHook(tc.Begin,function(hook,...)
            local args2 = table.pack(hook.call(...))
            if tc.Active then
                local message = api.prepareMessage("startTempo",getrenv()._G.TimePower,tc.Special)
                api.sendToServer(message)
            end
            return table.unpack(args2)
        end)
    end

    module.startTempo = function(timeTarget,special)
        local timemodule = fakeTimeControls[timeTarget]
        timemodule.Init(timemodule)
        timemodule.Special = special
        timemodule.Begin(timemodule)

        local rs = game:GetService("RunService")

        local loops = {}
        table.insert(loops,rs.Stepped:Connect(function()
            timemodule.Update(timemodule,(1/400)/5)
        end))
        table.insert(loops,rs.Heartbeat:Connect(function()
            timemodule.UpdatePost(timemodule,(1/400)/5)
            for _,loop in loops do
                loop:Disconect()
            end
        end))
    end

    return module
end