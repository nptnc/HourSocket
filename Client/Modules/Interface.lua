local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
return function(api)
    local module = {}

    module.once = function()
        local isActive = true
        
        local ui = Instance.new("ScreenGui")
        ui.Parent = game:GetService("CoreGui")

        rs.Heartbeat:Connect(function(dt)
            ui.Enabled = isActive
            if isActive then
                uis.MouseBehavior = Enum.MouseBehavior.Default
            elseif not isActive and getrenv()._G.GameState == "Combat" then
                uis.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        end)
        
        uis.InputBegan:Connect(function(input, gameProcessedEvent)
            if gameProcessedEvent then
                return
            end

            if input.KeyCode == Enum.KeyCode.LeftBracket then
                isActive = false
            end
        end)
        
        local createInstance = function(Type,data)
            local object = Instance.new(Type)
            for index,value in data do
                object[index] = value
            end
            return object
        end
        
        local frame = createInstance("Frame",{
            Size = UDim2.new(0.24,0,0.3,0),
            Parent = ui,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(0,0,0),
            BackgroundTransparency = 0.6,
            Position = UDim2.new(0.5,0,0.5,0),
            AnchorPoint = Vector2.new(0.5,0.5),
        })
        
        local mod = createInstance("TextLabel",{
            Size = UDim2.new(1,0,0.06,0),
            Parent = frame,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextTransparency = 0,
            TextColor3 = Color3.fromRGB(255,255,255),
            ZIndex = 4,
            Text = "Hours Socket",
            LayoutOrder = 0,
        })
        
        createInstance("UIListLayout",{
            Parent = frame,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0.02,0)
        })
        
        local createCheckbox = function(text)
            local mod = createInstance("TextLabel",{
                Size = UDim2.new(1,0,0.06,0),
                Parent = frame,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                TextTransparency = 0,
                TextColor3 = Color3.fromRGB(255,255,255),
                ZIndex = 4,
                Text = text,
                LayoutOrder = 1,
            })
        end
        
        local createTextbox = function(label,defaultText)
            local newFrame = createInstance("Frame",{
                Size = UDim2.new(0,0,0.06,0),
                Parent = frame,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                ZIndex = 4,
                LayoutOrder = 1,
            })
            local text = createInstance("TextLabel",{
                Size = UDim2.new(0,0,0.06,0),
                Position = UDim2.new(1.5,0,0.5,0),
                AnchorPoint = Vector2.new(1,0.5),
                Parent = newFrame,
                AutomaticSize = Enum.AutomaticSize.X,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                TextTransparency = 0,
                TextColor3 = Color3.fromRGB(255,255,255),
                ZIndex = 4,
                Text = `{label} `,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local box = createInstance("TextBox",{
                Size = UDim2.new(0,0,1,0),
                Position = UDim2.new(0,0,0.5,0),
                AnchorPoint = Vector2.new(0,0.5),
                Parent = newFrame,
                BorderSizePixel = 1,
                BorderColor3 = Color3.fromRGB(255,255,255),
                BackgroundTransparency = 0.2,
                BackgroundColor3 = Color3.fromRGB(0,0,0),
                TextTransparency = 0,
                AutomaticSize = Enum.AutomaticSize.X,
                TextColor3 = Color3.fromRGB(255,255,255),
                ZIndex = 7,
                PlaceholderText = defaultText,
                Text = defaultText,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        end
        
        local createLabel = function(label)
            local newFrame = createInstance("Frame",{
                Size = UDim2.new(0,0,0.06,0),
                Parent = frame,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                ZIndex = 4,
                LayoutOrder = 1,
            })
            local text = createInstance("TextLabel",{
                Size = UDim2.new(0,0,0.06,0),
                Position = UDim2.new(0.5,0,0.5,0),
                AnchorPoint = Vector2.new(0.5,0.5),
                Parent = newFrame,
                AutomaticSize = Enum.AutomaticSize.X,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                TextTransparency = 0,
                TextColor3 = Color3.fromRGB(255,255,255),
                ZIndex = 4,
                Text = `{label} `,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        end
        
        local createButton = function(label,callback)
            local newFrame = createInstance("Frame",{
                Size = UDim2.new(0,0,0.06,0),
                Parent = frame,
                BorderSizePixel = 0,
                BackgroundTransparency = 0,
                ZIndex = 4,
                LayoutOrder = 1,
            })
            local box = createInstance("TextButton",{
                Size = UDim2.new(0,0,1,0),
                Position = UDim2.new(0.5,0,0.5,0),
                AnchorPoint = Vector2.new(0.5,0.5),
                Parent = newFrame,
                BorderSizePixel = 1,
                BorderColor3 = Color3.fromRGB(255,255,255),
                BackgroundTransparency = 0.2,
                BackgroundColor3 = Color3.fromRGB(0,0,0),
                TextTransparency = 0,
                AutomaticSize = Enum.AutomaticSize.X,
                TextColor3 = Color3.fromRGB(255,255,255),
                ZIndex = 7,
                Text = label,
                TextXAlignment = Enum.TextXAlignment.Center,
            })
            box.MouseButton1Click:Connect(function()
                callback()
            end)
        end
        
        createLabel("you can press [ to hide this ui")
        createTextbox("ip","salamithecat.com")
        createTextbox("port","7171")
        createButton("connect",function()
            api.tryToConnect()
        end)
        --createCheckbox("hi")
    end

    return module
end