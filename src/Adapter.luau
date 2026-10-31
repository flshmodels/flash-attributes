local Rules = require(script.Parent.Rules)
local Adapter = {}

local function describe(value)
    if value == nil then return "(absent)" end
    local text = tostring(value):gsub("%c", " ")
    if not utf8.len(text) then return "(invalid UTF-8) [" .. typeof(value) .. "]" end
    local stop = utf8.offset(text, 121)
    if stop then text = string.sub(text, 1, stop - 1) .. "..." end
    return text .. " [" .. typeof(value) .. "]"
end

function Adapter.controls(panel, changed)
    panel.label("Set or remove one attribute on selected objects only. Existing attributes with another type are refused. Delete removes the named attribute, not the object.")
    local name = panel.field("Attribute name", "InteractionId")
    local kind = panel.cycle("Operation / type", { "String", "Number", "Boolean", "Delete" }, changed)
    local value = panel.field("Value (ignored for Delete)", "")
    name:GetPropertyChangedSignal("Text"):Connect(changed)
    value:GetPropertyChangedSignal("Text"):Connect(changed)
    return function() return { name = name.Text, kind = kind(), text = value.Text } end
end

function Adapter.plan(selection, options)
    Rules.parse(options.name, options.kind, options.text)
    local rows, seen = {}, {}
    assert(#selection <= 500, "Select no more than 500 objects.")
    for _, object in ipairs(selection) do
        assert(object.Parent and object:IsDescendantOf(game) and object.Parent ~= game, "Select objects inside a service, not the service itself.")
        if not seen[object] then
            seen[object] = true
            table.insert(rows, { target = object, parent = object.Parent, value = object:GetAttribute(options.name) })
        end
    end
    local plan = Rules.plan(rows, options)
    for _, entry in ipairs(plan) do
        entry.label = entry.before.target:GetFullName() .. "\n" .. entry.attribute .. ": " .. describe(entry.before.value) .. " -> " .. describe(entry.after)
    end
    return plan
end

function Adapter.validate(plan)
    for _, entry in ipairs(plan) do
        local before = entry.before
        if not before.target:IsDescendantOf(game) or before.target.Parent ~= before.parent or before.target:GetAttribute(entry.attribute) ~= before.value then
            return false, "An object or attribute changed after the preview. Preview again."
        end
    end
    return true
end

function Adapter.write(entry)
    entry.before.target:SetAttribute(entry.attribute, entry.after)
end

return Adapter
