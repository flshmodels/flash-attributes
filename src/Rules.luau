local Rules = {}

function Rules.parse(name, kind, text)
    assert(type(name) == "string" and #name > 0 and #name <= 100 and name:match("^[%w_./-]+$") and name:sub(1, 3):lower() ~= "rbx", "Attribute names must be 1-100 ASCII letters, digits, periods, hyphens, slashes or underscores, without an RBX prefix.")
    if kind == "Delete" then return nil end
    assert(type(text) == "string", "Enter an attribute value.")
    if kind == "String" then
        assert(#text <= 1024 and utf8.len(text), "String values must be valid UTF-8 and at most 1024 bytes.")
        return text
    elseif kind == "Number" then
        local value = tonumber(text)
        assert(value and value == value and math.abs(value) <= 1000000000000, "Enter a finite number between -1e12 and 1e12.")
        return value
    elseif kind == "Boolean" then
        assert(text == "true" or text == "false", "Boolean values must be exactly true or false.")
        return text == "true"
    end
    error("Choose String, Number, Boolean or Delete.")
end

function Rules.plan(rows, options)
    assert(#rows > 0 and #rows <= 500, "Select between 1 and 500 objects.")
    local value = Rules.parse(options.name, options.kind, options.text)
    local plan = {}
    for _, row in ipairs(rows) do
        if options.kind ~= "Delete" and row.value ~= nil then
            assert(type(row.value) == type(value), "An existing attribute has a different type. Delete it first if the change is intentional.")
        end
        if row.value ~= value then table.insert(plan, { before = row, after = value, attribute = options.name }) end
    end
    return plan
end

return Rules
