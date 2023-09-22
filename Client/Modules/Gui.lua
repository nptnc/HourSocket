return function(api)
    local module = {}

    local leftbar
    local rightbar
    local middle
    
    local createFrame = function(text,parent,isHost)
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
        textlabel.Position = UDim2.new(0.55,0,0.5,0)
        textlabel.AnchorPoint = Vector2.new(0.5,0.5)
        textlabel.TextColor3 = Color3.fromRGB(255,255,255)
        textlabel.TextScaled = true
        textlabel.TextXAlignment = Enum.TextXAlignment.Left
        textlabel.Font = Enum.Font.RobotoMono

        if isHost == true then
            textlabel.Position = UDim2.new(0.75,0,0.5,0)

            local imageLabel = Instance.new("ImageLabel")
            imageLabel.Parent = frame
            imageLabel.Position = UDim2.new(0.04,0,0.475,0)
            imageLabel.BackgroundTransparency = 1
            imageLabel.Size = UDim2.new(0.185,0,0.9,0)
            imageLabel.AnchorPoint = Vector2.new(0,0.5)
            imageLabel.Image = "rbxassetid://14842080275"
        end

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
        gui.Parent = api.player.PlayerGui
        gui.Name = "MultiplayerUI"
        gui.DisplayOrder = 999

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
        uilistlayout3.HorizontalAlignment = Enum.HorizontalAlignment.Center
        uilistlayout3.VerticalAlignment = Enum.VerticalAlignment.Bottom

        packetInFrame = createFrame("packets in: 0/s",rightbar)
        packetOutFrame = createFrame("packets out: 0/s",rightbar)
    end

    local corresponding = {}
    module.playerRegistered = function(userid,data)
        if userid ~= api.player.UserId then
            createNotification(`{data.serverData.username} has joined the server`)
        end
        local frame = createFrame(data.serverData.username,leftbar,data.serverData.isHost)
        corresponding[userid] = frame
    end

    module.playerDisconnected = function(userid,data)
       corresponding[userid]:Destroy()
       corresponding[userid] = nil
    end

    module.receivedMessage = function()
        packetsIn += 1
    end

    module.sentMessage = function(sentOut,sent)
        packetsOut = sentOut
        packetOutFrame.TextLabel.Text = `packets out: {packetsOut}/s{api.isThrottling and " THROTTLING" or ""}`
    end

    module.resetPacketInformation = function()
        packetOutFrame.TextLabel.Text = `packets out: {0}/s{api.isThrottling and " THROTTLING" or ""}`
    end

    module.createNotification = function(text)
        createNotification(text)
    end

    local start = tick()
    module.update = function()
        if tick() - start > 1 then
            start = tick()
            packetInFrame.TextLabel.Text = `packets in: {packetsIn}/s`
            packetsIn = 0
        end
    end

    return module
end