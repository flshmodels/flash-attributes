if not plugin then return end

local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Ui = require(script.Ui)
local Adapter = require(script.Adapter)
local Transaction = require(script.Transaction)
local panel = Ui.new(plugin, "FlashAttributes", "Flash Attributes", "Attributes")
local plan = nil
local status
local preview
local function invalidate()
    plan = nil
    if status then status.Text = "Selection or options changed. Preview again before applying." end
    if preview then preview.Text = "" end
end
local options = Adapter.controls(panel, invalidate)
status = panel.label("Select objects in Explorer, then preview the changes.")
panel.button("Preview selection", function()
    plan = nil
    preview.Text = ""
    if RunService:IsRunning() then status.Text = "Stop the play test first." return end
    local ok, result = pcall(Adapter.plan, Selection:Get(), options())
    if not ok then status.Text = tostring(result) return end
    plan = result
    status.Text = string.format("%d changes. Preview shows up to 100 rows. No objects have been edited.", #plan)
    local lines = {}
    for index, entry in ipairs(plan) do
        if index > 100 then break end
        table.insert(lines, entry.label)
    end
    preview.Text = table.concat(lines, "\n\n")
end)
panel.button("Apply preview", function()
    if RunService:IsRunning() then status.Text = "Stop the play test first." invalidate() return end
    if not plan then status.Text = "Preview the selection first." return end
    local _, message = Transaction.apply(plan, Adapter, {
        begin = function() return ChangeHistoryService:TryBeginRecording("FlashAttributes.Apply", "Flash Attributes") end,
        finish = function(recording, commit)
            ChangeHistoryService:FinishRecording(recording, if commit then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel)
        end,
    })
    plan = nil
    status.Text = message
    preview.Text = ""
end)
preview = panel.label("")
preview.TextSize = 14
local selectionConnection = Selection.SelectionChanged:Connect(invalidate)
plugin.Unloading:Connect(function()
    selectionConnection:Disconnect()
    panel.destroy()
end)
