local PointerManager = {}
PointerManager.pointerList = {}
PointerManager.pointerEspCache = {}
PointerManager.nextId = 1
function PointerManager.createPointer(name, position, visible)
    local pointer = {
        Id = PointerManager.nextId,
        Name = name or "Pointer " .. PointerManager.nextId,
        Position = position or Vector3.new(0,0,0),
        Visible = visible ~= nil and visible or true,
    }
    PointerManager.nextId = PointerManager.nextId + 1
    table.insert(PointerManager.pointerList, pointer)
    return pointer
end
function PointerManager.removePointer(id)
    for i, p in ipairs(PointerManager.pointerList) do
        if p.Id == id then
            table.remove(PointerManager.pointerList, i)
            PointerManager.removePointerEsp(id)
            return true
        end
    end
    return false
end
function PointerManager.updatePointer(id, newPos, newName, newVisible)
    for _, p in ipairs(PointerManager.pointerList) do
        if p.Id == id then
            if newPos then p.Position = newPos end
            if newName then p.Name = newName end
            if newVisible ~= nil then p.Visible = newVisible end
            return true
        end
    end
    return false
end
function PointerManager.getAllPointers()
    return PointerManager.pointerList
end
function PointerManager.teleportTo(id)
    local player = game:GetService("Players").LocalPlayer
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    for _, p in ipairs(PointerManager.pointerList) do
        if p.Id == id then
            hrp.CFrame = CFrame.new(p.Position)
            return true
        end
    end
    return false
end
return PointerManager
