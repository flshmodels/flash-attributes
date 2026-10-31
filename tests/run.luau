local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local Rules = require("../src/Rules")
local Transaction = require("../src/Transaction")
local count = 0
local function test(name, callback)
    local ok, err = pcall(callback)
    assert(ok, name .. ": " .. tostring(err))
    count += 1
    print("PASS " .. name)
end
local function rejects(callback)
    assert(not pcall(callback), "expected an error")
end
for _, name in ipairs(fs.readDir("src")) do
    if name:match("%.luau$") then luau.compile(fs.readFile("src/" .. name)) end
end

test("transaction commits one batch", function()
    local writes, commits = 0, 0
    local ok = Transaction.apply({ {}, {} }, {
        validate = function() return true end,
        write = function() writes += 1 end,
    }, {
        begin = function() return "recording" end,
        finish = function(id, commit) assert(id == "recording" and commit) commits += 1 end,
    })
    assert(ok and writes == 2 and commits == 1)
end)
test("empty, stale and uncheckable plans never begin a recording", function()
    local function forbidden() error("must not be called") end
    for _, mode in ipairs({ "empty", "stale", "throw" }) do
        local began = false
        local ok = Transaction.apply(if mode == "empty" then {} else { {} }, {
            validate = function() if mode == "throw" then error("deleted") end return false, "stale" end,
            write = forbidden,
        }, { begin = function() began = true return "id" end, finish = forbidden })
        assert(not ok and not began)
    end
end)
test("refused or failing undo recordings do not edit objects", function()
    for _, mode in ipairs({ "refuse", "throw" }) do
        local writes = 0
        local ok = Transaction.apply({ {} }, { validate = function() return true end, write = function() writes += 1 end }, {
            begin = function() if mode == "throw" then error("busy") end return nil end,
            finish = function() error("must not finish") end,
        })
        assert(not ok and writes == 0)
    end
end)
test("write failures cancel and restore the fake scene", function()
    local state, snapshot, cancelled = 0, 0, false
    local ok = Transaction.apply({ {}, {} }, {
        validate = function() return true end,
        write = function() state += 1 if state == 2 then error("locked") end end,
    }, {
        begin = function() snapshot = state return "id" end,
        finish = function(_, commit) assert(not commit) state = snapshot cancelled = true end,
    })
    assert(not ok and cancelled and state == 0)
end)
test("failed commits attempt cancellation", function()
    local cancelled = false
    local ok = Transaction.apply({ {} }, { validate = function() return true end, write = function() end }, {
        begin = function() return "id" end,
        finish = function(_, commit) if commit then error("commit failed") end cancelled = true end,
    })
    assert(not ok and cancelled)
end)
test("failed cancellation is reported", function()
    local ok, message = Transaction.apply({ {} }, { validate = function() return true end, write = function() error("write failed") end }, {
        begin = function() return "id" end,
        finish = function() error("cancel failed") end,
    })
    assert(not ok and message:find("could not cancel", 1, true))
end)

local gameRoot = { Name = "Game" }
local world = { Name = "Workspace", Parent = gameRoot, children = {} }
function world:GetChildren() return self.children end
function world:IsDescendantOf(ancestor) return ancestor == gameRoot end
local function object(name, parent, class)
    local node = { Name = name, Parent = parent, children = {}, attributes = {}, Anchored = true, Locked = false, connected = {} }
    node.CFrame = roblox.CFrame.new(0.4, -0.5, 3.6) * roblox.CFrame.Angles(0, 0.4, 0)
    setmetatable(node, { __index = function(self, key) if key == "Position" then return self.CFrame.Position end return nil end })
    function node:IsA(candidate) return candidate == "BasePart" and class == "BasePart" end
    function node:IsDescendantOf(ancestor)
        local cursor = self.Parent
        while cursor do if cursor == ancestor then return true end cursor = cursor.Parent end
        return false
    end
    function node:GetFullName()
        local names, cursor = {}, self
        while cursor and cursor ~= gameRoot do table.insert(names, 1, cursor.Name) cursor = cursor.Parent end
        return table.concat(names, ".")
    end
    function node:GetChildren() return self.children end
    function node:GetConnectedParts() return self.connected end
    function node:GetAttribute(name) return self.attributes[name] end
    function node:SetAttribute(name, value) self.attributes[name] = value end
    if parent and parent.children then table.insert(parent.children, node) end
    return node
end
local Adapter = luau.load(fs.readFile("src/Adapter.luau"), { environment = {
    require = function() return Rules end,
    script = { Parent = { Rules = {} } },
    game = gameRoot, workspace = world, Vector3 = roblox.Vector3,
} })()

test("parses string, number and boolean values without coercing strings", function()
    assert(Rules.parse("Id", "String", "001") == "001")
    assert(Rules.parse("Price", "Number", "12.5") == 12.5)
    assert(Rules.parse("Enabled", "Boolean", "false") == false)
    assert(Rules.parse("Enabled", "Boolean", "true") == true)
end)
test("reserved names, invalid values and oversized strings are refused", function()
    for _, name in ipairs({ "", "RBX_Test", "rbx_Test", "a b", "a@b", string.rep("a", 101) }) do
        rejects(function() Rules.parse(name, "String", "x") end)
    end
    for _, value in ipairs({ "nan", "inf", "1e999", "1000000000001", "text" }) do
        rejects(function() Rules.parse("Value", "Number", value) end)
    end
    rejects(function() Rules.parse("Value", "Boolean", "1") end)
    rejects(function() Rules.parse("Value", "String", string.rep("x", 1025)) end)
end)
test("type mismatches are refused for the whole preview", function()
    local a, b = object("A", world), object("B", world)
    b:SetAttribute("Price", "old")
    rejects(function() Adapter.plan({ a, b }, { name = "Price", kind = "Number", text = "50" }) end)
    assert(a:GetAttribute("Price") == nil and b:GetAttribute("Price") == "old")
end)
test("false attributes survive planning and writes", function()
    local a = object("A", world)
    a:SetAttribute("Enabled", true)
    local plan = Adapter.plan({ a, a }, { name = "Enabled", kind = "Boolean", text = "false" })
    assert(#plan == 1 and Adapter.validate(plan))
    Adapter.write(plan[1])
    assert(a:GetAttribute("Enabled") == false)
end)
test("delete removes attributes and missing values are no-ops", function()
    local a, b = object("A", world), object("B", world)
    a:SetAttribute("Count", 0)
    local plan = Adapter.plan({ a, b }, { name = "Count", kind = "Delete", text = "ignored" })
    assert(#plan == 1)
    Adapter.write(plan[1])
    assert(a:GetAttribute("Count") == nil)
end)
test("attribute changes and reparenting invalidate a preview", function()
    local a = object("A", world)
    local plan = Adapter.plan({ a }, { name = "Id", kind = "String", text = "DoorA" })
    a:SetAttribute("Id", "Other")
    assert(not Adapter.validate(plan))
    a:SetAttribute("Id", nil)
    a.Parent = nil
    assert(not Adapter.validate(plan))
end)

test("preview shortening preserves UTF-8", function()
    local a = object("Unicode", world)
    a:SetAttribute("Description", string.rep("🍃", 121))
    local plan = Adapter.plan({ a }, { name = "Description", kind = "String", text = "New" })
    assert(utf8.len(plan[1].label) and plan[1].label:find("...", 1, true))
end)
print(string.format("%d checks passed", count))
