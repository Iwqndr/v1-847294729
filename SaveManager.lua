local HttpService = game:GetService("HttpService")
local folder = "PLife-Settings"
local file = folder .. "/config.json"

if typeof(makefolder) == "function" then pcall(function() makefolder(folder) end) end

_G.PLifeSave = function(data)
    if typeof(writefile) == "function" then
        local success, str = pcall(function() return HttpService:JSONEncode(data) end)
        if success then writefile(file, str) end
    end
end

_G.PLifeLoad = function()
    if typeof(readfile) == "function" and isfile(file) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
        return success and data or nil
    end
    return nil
end
