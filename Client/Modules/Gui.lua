return function(api)
    local module = {}

    local leftbar
    local rightbar
    
    local createFrame = function(text,parent)
        local frame = Instance.new("Frame")
        frame.Parent = leftbar
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

        if parent == rightbar then
            frame.Position = UDim2.new(1,0,0,0)
            frame.AnchorPoint = Vector2.new(1,0)
        end

        return frame
    end

    local packetsIn,packetsOut = 0,0

    local receivedPacketFrame
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
        rightbar.Position = UDim2.new(1,0)

        local uilistlayout2 = Instance.new("UIListLayout")
        uilistlayout2.Padding = UDim.new()
        uilistlayout2.Parent = rightbar

        receivedPacketFrame = createFrame("packets in: 0",rightbar)
    end

    local corresponding = {}
    module.playerRegistered = function(userid,data)
        corresponding[userid] = createFrame(data.serverData.username,leftbar)
    end

    module.playerDisconnected = function(userid,data)
       corresponding[userid]:Destroy()
       corresponding[userid] = nil
    end

    module.receivedMessage = function()
        packetsIn += 1
        receivedPacketFrame.TextLabel.Text = `packets in: {packetsIn}`
    end

    local start = tick()
    module.update = function()
        if tick() - start > 1 then
            start = tick()
            packetsOut = 0
            packetsIn = 0
        end
    end

    return module
end