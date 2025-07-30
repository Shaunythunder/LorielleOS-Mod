local shell = require("shell")
local filesystem = require("filesystem")
local arg, options = shell.parse(...)

local file_name = arg_file

local _function saveNewPath(file_path)
    filesystem.remove("/etc/dev_save.json")
    local file = io.open("/etc/dev_save.json", "w")
    if file then
        file:write(file_path)
        file:close()
    end

local _function getSavedPath()
    local file = io.open("/etc/dev_save.json", "r")
    if file then
        local path = file:read("*a")
        file:close()
        return path
    end
    return nil
end

if #arg == 1 then
   saveNewPath(arg[1])
   print("Saved new path: " .. arg[1])
elseif #arg > 1 then
   print("Usage: dev.lua <file_path>")
   print("Saves the file path to /etc/dev_save.json")
   return 1
end

local saved_path = getSavedPath()
if saved_path then
    