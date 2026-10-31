local Transaction = {}

function Transaction.apply(plan, adapter, history)
    if #plan == 0 then return false, "Nothing to change." end
    local checked, valid, reason = pcall(adapter.validate, plan)
    if not checked then return false, "The preview could not be checked. Preview again: " .. tostring(valid) end
    if not valid then return false, reason end
    local started, recording = pcall(history.begin)
    if not started or not recording then
        return false, "Studio could not start an undo recording. Try again in edit mode."
    end
    local ok, err = pcall(function()
        for _, entry in ipairs(plan) do adapter.write(entry) end
    end)
    if ok then
        ok, err = pcall(history.finish, recording, true)
    end
    if not ok then
        local cancelled = pcall(history.finish, recording, false)
        if not cancelled then
            return false, "The edit failed and Studio could not cancel its recording. Check the place and undo history: " .. tostring(err)
        end
        return false, "The batch was cancelled: " .. tostring(err)
    end
    return true, string.format("Applied %d changes. Use Studio Undo to revert the batch.", #plan)
end

return Transaction
