return function(api)
    local module = {}

    local sidebar

    module.once = function()
        local gui : ScreenGui = Instance.new("ScreenGui")
        gui.Parent = api.player.PlayerGui
        gui.ZIndex = 99
        gui.Name = "MultiplayerUI"

        sidebar = Instance.new("Frame")
        sidebar.Parent = gui
        sidebar.BackgroundColor3 = Color3.fromRGB()
        sidebar.BackgroundTransparency = 0.7
        sidebar.BorderSizePixel = 0
        sidebar.Size = UDim2.new(0.09,1)

        local uilistlayout = Instance.new("UIListLayout")
        uilistlayout.Padding = UDim.new()
        uilistlayout.Parent = sidebar
    end

    module.playerRegistered = function(userid,data)
        local frame = Instance.new("Frame")
        frame.Parent = sidebar
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1,0,0.4,0)
        
        local textlabel = Instance.new("TextLabel")
        textlabel.Parent = frame
        textlabel.Text = data.serverData.username
        textlabel.BackgroundTransparency = 1
        textlabel.Size = UDim2.new(1,0,1,0)
        textlabel.TextColor3 = Color3.fromRGB(255,255,255)
        textlabel.TextScaled = true
    end

    return module
end