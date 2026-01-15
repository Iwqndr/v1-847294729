local mainUrl = "https://raw.githubusercontent.com/Iwqndr/v1-847294729/main/PLU.Lua?t=" .. tick()

print("-------------------------------------------")
print("Initializing System...")
task.wait(0.3)

local success, code = pcall(function()
    return game:HttpGet(mainUrl)
end)

if success then
    local currentHash = #code + (string.byte(string.sub(code, 1, 1)) or 0) + (string.byte(string.sub(code, -1)) or 0)
    
    if _G.LastScriptHash ~= nil and _G.LastScriptHash ~= currentHash then
        print("Update Detected!")
        print("Installing new patches...")
        task.wait(0.5)
    elseif _G.LastScriptHash == nil then
        print("First time load initialized.")
    else
        print("No updates found, Your all good!")
    end
    
    _G.LastScriptHash = currentHash
    
    print("Loading PLU.Lua...")
    print("-------------------------------------------")
    loadstring(code)()
else
    warn("CRITICAL ERROR: Connection failed.")
end
