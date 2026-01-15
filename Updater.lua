local mainUrl = "https://raw.githubusercontent.com/Iwqndr/v1-847294729/main/PLU.Lua?t=" .. tick()

print("Connecting to server...")
task.wait(0.5)
print("Checking for updates.")
task.wait(0.5)

local success, code = pcall(function()
    return game:HttpGet(mainUrl)
end)

if success then
    print("No updates found, Your all good!")
    task.wait(0.5)
    print("Loading PLU.Lua...")
    loadstring(code)()
else
    warn("Update check failed. Connection error.")
end
