return function(api)
    local rs = game:GetService("RunService")
    local uis = game:GetService("UserInputService")

    local module = {}

    local createInstance = function(Type,data)
        local object = Instance.new(Type)
        for index,value in data do
            object[index] = value
        end
        return object
    end

    module.once = function()
        local isActive = true
        
        local ui : ScreenGui = Instance.new("ScreenGui")
        ui.Parent = api.player.PlayerGui --game:GetService("CoreGui")
        ui.DisplayOrder = 999

        local hovertext : TextLabel = createInstance("TextLabel",{
            Size = UDim2.new(0,0,0.02,0),
            Position = UDim2.new(1.5,0,0.1,0),
            AnchorPoint = Vector2.new(1,0.9),
            Parent = ui,
            AutomaticSize = Enum.AutomaticSize.X,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(0,0,0),
            BackgroundTransparency = 0.5,
            TextTransparency = 0,
            TextColor3 = Color3.fromRGB(255,255,255),
            ZIndex = 99,
            Text = `GOOGOO GA GA!!!`,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local showHoverThing = false
        rs.Heartbeat:Connect(function(dt)
            ui.Enabled = isActive

            local mousepos = uis:GetMouseLocation()
            hovertext.Visible = showHoverThing
            hovertext.Position = UDim2.new(0,mousepos.X,0,mousepos.Y)

            local shouldLock = not isActive
            if getrenv()._G.Pause then
                shouldLock = false
            end
            if shouldLock == false then
                uis.MouseBehavior = Enum.MouseBehavior.Default
            elseif shouldLock and getrenv()._G.GameState == "Combat" then
                uis.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        end)
        
        uis.InputBegan:Connect(function(input, gameProcessedEvent)
            if gameProcessedEvent then
                return
            end

            if input.KeyCode == Enum.KeyCode.LeftBracket then
                isActive = not isActive
            end
        end)
        
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
            return {
                get = function()
                    return box.Text or box.PlaceholderText
                end
            }
        end

        local createEnum = function(data)
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
                Text = "",
                TextXAlignment = Enum.TextXAlignment.Center,
            })

            if data.tooltip then
                box.MouseEnter:Connect(function()
                    showHoverThing = true
                    hovertext.Text = data.tooltip
                end)
                box.MouseLeave:Connect(function()
                    showHoverThing = false
                end)
            end

            local selectedIndex = 1
            local selectedType = data.options[selectedIndex]
            local updateTheThing = function()
                box.Text = data.display and string.format(data.display,selectedType.text) or selectedType.text
            end
            updateTheThing()

            box.MouseButton1Click:Connect(function()
                selectedIndex += 1
                selectedType = data.options[selectedIndex]
                if selectedType == nil then
                    selectedIndex = 1
                    selectedType = data.options[selectedIndex]
                end
                updateTheThing()
            end)

            local enumapi = {
                getSelected = function()
                    return selectedType.id
                end
            }
            return enumapi
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

            local buttonapi = {
                changeText = function(t)
                    box.Text = t
                end
            }
            box.MouseButton1Click:Connect(function()
                callback(buttonapi)
            end)
            return buttonapi
        end
        
        createLabel("you can press [ to hide this ui")
        local ip = createTextbox("ip","localhost")
        local port = createTextbox("port","6969")
        createButton("connect",function(button)
            if api.connected then
                api.disconnect()
                button.changeText(api.connected and "disconnect" or "connect")
                return
            end
            api.tryToConnect(`ws://{ip.get()}:{port.get()}`)
            button.changeText(api.connected and "disconnect" or "connect")
        end)
        --createCheckbox("hi")
    end

    return module
end