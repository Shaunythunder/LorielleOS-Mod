local shell = require("shell")
local os = require("os")
local io = require("io")
local internet = require("internet")
local filesystem = require("filesystem")
local arg, options = shell.parse(...)

local short_delay = 0.5
local long_delay = 2
local extreme_delay = 5

local function saveNewPath(file_path)
    filesystem.remove("/etc/dev_save.json")
    local file = io.open("/etc/dev_save.json", "w")
    if file then
        file:write(file_path)
        file:close()
    end
end

local function getSavedPath()
    local file = io.open("/etc/dev_save.json", "r")
    if file then
        local path = file:read("*a")
        file:close()
        if #path == 0 then
            return nil
        else
            return path
        end
    end
end

if #arg == 1 then
    saveNewPath(arg[1])
    print("Saved new path: " .. arg[1])
elseif #arg > 1 then
    print("Usage: dev.lua <file_path>")
    print("Saves the file path to /etc/dev_save.json")
    return 1
end

local file_path = getSavedPath()
if file_path == nil then
    print("No path saved yet or invalid path.")
    os.exit()
end

local removal_path = filesystem.concat("/tmp/", file_path)
filesystem.remove(removal_path)

-- Pulls install manifest from GitHub.
-- The manifest is a text file that contains the list of files to be installed.
-- It is stored in the LorielleOS-Mod repository.
local download_path = "http://localhost:8000/" .. file_path
local response = internet.request(download_path)
if not response then
    print("Failed to download file. Please check your internet connection.")
    os.sleep(short_delay)
    local input
    repeat
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
        if input == "yes" then
            response = internet.request(download_path)
        end
    until response or input == "no"
    if input == "no" then
        print("Download failed. Please check your internet connection.")
        os.sleep(extreme_delay)
        return
    end
end

print("Downloading " .. file_path .. "...")
os.sleep(short_delay)
local file_content = ""


-- Handles packets from the response.
-- It concatenates the chunks into a single string.
-- The string is the content of the manifest file.

for chunk in response do
    file_content = file_content .. chunk
end

local input = nil
while #file_content == 0 do
   print("Failed to download file. Please check your internet connection.")
    os.sleep(1)
    repeat
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
    until input == "yes" or input == "no"

    if input == "no" then
        print("Download failed. Please check your internet connection.")
        os.sleep(extreme_delay)
        return
    elseif input == "yes" then
        response = internet.request(download_path)
        if response then
            file_content = ""
            for chunk in response do
                file_content = file_content .. chunk
            end
        end
    end
end

local full_path = "bin/osupdater.lua"
local filename = full_path:match("([^/]+)$")

local temp_file_path = filesystem.concat("/tmp/", filename)
local file = io.open(temp_file_path, "w")

if file then
    file:write(file_content)
    file:close()
else
    print("Failed to open " .. temp_file_path .. " for writing. Please check your permissions.")
    os.sleep(short_delay)
    print("Exiting bootstrap.")
    os.sleep(extreme_delay)
    return
end

print("File downloaded successfully to " .. temp_file_path)
os.sleep(short_delay)
print("Running " .. temp_file_path .. "...")
os.sleep(short_delay)
dofile(temp_file_path)