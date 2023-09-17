return function(api)
    local module = {}

    local leftbar
    local rightbar
    local middle
    
    local createFrame = function(text,parent)
        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.BackgroundColor3 = Color3.fromRGB()
        frame.BackgroundTransparency = 0.7
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(1,0,0.04,0)
        
        local textlabel = Instance.new("TextLabel")
        textlabel.Parent = frame
        textlabel.Text = text
        textlabel.BackgroundTransparency = 1
        textlabel.Size = UDim2.new(1,0,0.75,0)
        textlabel.TextColor3 = Color3.fromRGB(255,255,255)
        textlabel.TextScaled = true
        --textlabel.Font = Enum.Font.Code

        if parent == rightbar then
            frame.Position = UDim2.new(1,0,0,0)
            frame.AnchorPoint = Vector2.new(1,0)
        end

        return frame
    end

    local createNotification = function(text,duration)
        local frame = Instance.new("Frame")
        frame.Parent = middle
        frame.BackgroundColor3 = Color3.fromRGB()
        frame.BackgroundTransparency = 0.7
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(0,0,0.04,0)
        frame.AutomaticSize = Enum.AutomaticSize.X
        
        local textlabel = Instance.new("TextLabel")
        textlabel.Parent = frame
        textlabel.Text = text
        textlabel.BackgroundTransparency = 1
        textlabel.Size = UDim2.new(1,0,0.75,0)
        textlabel.TextColor3 = Color3.fromRGB(255,255,255)
        textlabel.TextScaled = false
        textlabel.AutomaticSize = Enum.AutomaticSize.X

        task.delay(duration or 5,function()
            frame:Destroy()
        end)

        return frame
    end

    local packetsIn,packetsOut = 0,0

    local packetInFrame
    local packetOutFrame
    module.once = function()
        local gui : ScreenGui = Instance.new("ScreenGui")
        gui.Parent = game:GetService("CoreGui")
        gui.Name = "MultiplayerUI"

        leftbar = Instance.new("Frame")
        leftbar.Parent = gui
        leftbar.BackgroundTransparency = 1
        leftbar.BorderSizePixel = 0
        leftbar.Size = UDim2.new(0.09,0,1,0)

        local uilistlayout = Instance.new("UIListLayout")
        uilistlayout.Padding = UDim.new()
        uilistlayout.Parent = leftbar
        
        rightbar = Instance.new("Frame")
        rightbar.Parent = gui
        rightbar.BackgroundTransparency = 1
        rightbar.BorderSizePixel = 0
        rightbar.Size = UDim2.new(0.09,0,1,0)
        rightbar.AnchorPoint = Vector2.new(1,0)
        rightbar.Position = UDim2.new(1,0,0,0)

        local uilistlayout2 = Instance.new("UIListLayout")
        uilistlayout2.Padding = UDim.new()
        uilistlayout2.Parent = rightbar

        middle = Instance.new("Frame")
        middle.Parent = gui
        middle.BackgroundTransparency = 1
        middle.BorderSizePixel = 0
        middle.Size = UDim2.new(0.09,0,0.8,0)
        middle.AnchorPoint = Vector2.new(0.5,0)
        middle.Position = UDim2.new(0.5,0,0,0)

        local uilistlayout3 = Instance.new("UIListLayout")
        uilistlayout3.Padding = UDim.new()
        uilistlayout3.Parent = middle
        uilistlayout3.VerticalAlignment = Enum.VerticalAlignment.Bottom

        packetInFrame = createFrame("packets in: 0/s",rightbar)
        packetOutFrame = createFrame("packets out: 0/s",rightbar)
    end

    local corresponding = {}
    module.playerRegistered = function(userid,data)
        if userid == api.player.UserId then
            createNotification(`has joined the server {data.serverData.username}`)
        end
        corresponding[userid] = createFrame(data.serverData.username,leftbar)
    end

    module.playerDisconnected = function(userid,data)
       corresponding[userid]:Destroy()
       corresponding[userid] = nil
    end

    module.receivedMessage = function()
        packetsIn += 1
    end

    module.sentMessage = function()
        packetsOut += 1
    end

    module.createNotification = function(text)
        createNotification(text)
    end

    local start = tick()
    module.update = function()
        if tick() - start > 1 then
            start = tick()
            packetInFrame.TextLabel.Text = `packets in: {packetsIn}/s`
            packetOutFrame.TextLabel.Text = `packets out: {packetsOut}/s`
            packetsOut = 0
            packetsIn = 0
        end
    end

    return module
end