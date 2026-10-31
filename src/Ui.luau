local Ui = {}

function Ui.new(plugin, id, title, action)
    local studio = settings().Studio
    local colors = {}
    local connections = {}
    local toolbar = plugin:CreateToolbar(title)
    local toggle = toolbar:CreateButton(id, title, "", action)
    local widget = plugin:CreateDockWidgetPluginGuiAsync(id .. "_v1", DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Right, false, false, 380, 600, 280, 260
    ))
    widget.Title = title
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.fromScale(1, 1)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new()
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.Parent = widget
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 14)
    padding.PaddingBottom = UDim.new(0, 14)
    padding.PaddingLeft = UDim.new(0, 14)
    padding.PaddingRight = UDim.new(0, 20)
    padding.Parent = scroll
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 9)
    layout.Parent = scroll
    local order = 0
    local function theme(object, property, color)
        table.insert(colors, { object, property, color })
        object[property] = studio.Theme:GetColor(Enum.StudioStyleGuideColor[color])
    end
    theme(scroll, "BackgroundColor3", "MainBackground")
    theme(scroll, "ScrollBarImageColor3", "MainText")
    local function add(class, text)
        order = order + 1
        local object = Instance.new(class)
        object.LayoutOrder = order
        object.Size = UDim2.new(1, 0, 0, 32)
        object.BorderSizePixel = 0
        object.Font = Enum.Font.SourceSans
        object.TextSize = 16
        object.Text = text
        object.TextWrapped = true
        object.Parent = scroll
        theme(object, "TextColor3", "MainText")
        return object
    end
    local panel = { widget = widget }
    function panel.label(text)
        local object = add("TextLabel", text)
        object.Size = UDim2.new(1, 0, 0, 0)
        object.AutomaticSize = Enum.AutomaticSize.Y
        object.BackgroundTransparency = 1
        object.TextXAlignment = Enum.TextXAlignment.Left
        return object
    end
    function panel.field(caption, initial)
        panel.label(caption)
        local object = add("TextBox", initial)
        object.ClearTextOnFocus = false
        object.TextWrapped = false
        theme(object, "BackgroundColor3", "InputFieldBackground")
        return object
    end
    function panel.button(text, callback)
        local object = add("TextButton", text)
        theme(object, "BackgroundColor3", "Button")
        table.insert(connections, object.Activated:Connect(callback))
        return object
    end
    function panel.cycle(caption, choices, changed)
        local index = 1
        local button
        button = panel.button(caption .. ": " .. choices[index], function()
            index = index % #choices + 1
            button.Text = caption .. ": " .. choices[index]
            changed()
        end)
        return function() return choices[index] end
    end
    panel.label(title)
    table.insert(connections, toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end))
    table.insert(connections, widget:GetPropertyChangedSignal("Enabled"):Connect(function()
        toggle:SetActive(widget.Enabled)
    end))
    table.insert(connections, studio.ThemeChanged:Connect(function()
        for _, item in ipairs(colors) do
            item[1][item[2]] = studio.Theme:GetColor(Enum.StudioStyleGuideColor[item[3]])
        end
    end))
    toggle:SetActive(widget.Enabled)
    function panel.destroy()
        for _, connection in ipairs(connections) do connection:Disconnect() end
        widget:Destroy()
        toolbar:Destroy()
    end
    return panel
end

return Ui
