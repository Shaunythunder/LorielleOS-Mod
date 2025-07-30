-- LorielleOS Updater

local args, options = require("shell").parse(...)
local filesystem = require("filesystem")
local component = require("component")
local process = require("process")
local os = require("os")
local table = require("table")
local io = require("io")
local print = print
local internet = require("internet")

local short_delay = .5
local long_delay = 2
local extreme_delay = 5

local manifest_download_path
local download_path
if options.d then 
    -- d is for dev. This is used for development purposes.
    -- It sets the download path to a local server.
    manifest_download_path = "http://localhost:8000/install_manifest.lua"
    download_path = "http://localhost:8000/"
    print("Running in development mode. Download path set to: " .. manifest_download_path)
    os.sleep(short_delay)
else
    -- Otherwise, it sets the download path to the LorielleOS-Mod repository.
    manifest_download_path = "https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/main/install_manifest.lua"
    download_path = "https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/main/"
    os.sleep(short_delay)
end

local updates_needed = {}

local function validateChecksum(host_manifest, update_manifest)
    local installed = {}
    for _, file in pairs(host_manifest) do
        installed[file.filename] = file.checksum
    end
    for _, file in ipairs(update_manifest) do
        if installed[file.filename] ~= file.checksum then
            table.insert(updates_needed, file.filename)
        end
    end
end

local function deleteAndReplace(base_path, file)
    local file_path = filesystem.concat(base_path, file)
    if filesystem.exists(file_path) then
        filesystem.remove(file_path)
        if filesystem.exists(file_path) then
            print("Failed to remove file: " .. file_path)
            return false
        end
    end
    -- If the file is in the exclusions table, it will not be downloaded.
        -- Downloads the file, concats the content into a string and then writes it to the disk.
        local filepath = file_path
        local url = download_path .. file
        local outpath = filesystem.concat(base_path, filepath)
        local file_path = filepath
        local file_response = internet.request(url)
        if not file_response then
            print("Failed to download " .. filepath)
            os.sleep(short_delay)
            print("Update failed. Please check your internet connection.")
            os.sleep(extreme_delay)
            return false
        end

        local file_content = ""
        for chunk in file_response do
            file_content = file_content .. chunk
        end

        local dir = filesystem.path(outpath)
        if dir and not filesystem.exists(dir) then
            -- Creates the directory if it does not exist.
            filesystem.makeDirectory(dir)
            os.sleep(short_delay)
        end
        local file = io.open(outpath, "w")
        if file then
            -- Writes the content to the file.
            file:write(file_content)
            file:close()
            return true
        end
end

print("Welcome to LorielleOS Updater v1.1!")
os.sleep(short_delay)
print("Do not shut down the computer while the updater is running.")
os.sleep(short_delay)

if not filesystem.exists("/install_manifest.lua") then
    print("No install manifest found in root. Cannot update.")
    os.sleep(short_delay)
    print("Please reinstall LorielleOS.")
    os.sleep(extreme_delay)
    return
end

print("Fetching update manifest...")
os.sleep(short_delay)

-- Pulls install manifest from GitHub.
-- The manifest is a text file that contains the list of files to be installed.
-- It is stored in the LorielleOS-Mod repository.
local response = internet.request(manifest_download_path)
if not response then
    print("Failed to download manifest. Please check your internet connection.")
    os.sleep(short_delay)
    local input
    repeat
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
        if input == "yes" then
            response = internet.request(manifest_url)
        end
    until response or input == "no"
    if input == "no" then
        print("Update failed. Please check your internet connection.")
        os.sleep(extreme_delay)
        return
    end
end

print("Manifest found. Parsing...")
os.sleep(short_delay)
local manifest_content = ""


-- Handles packets from the response.
-- It concatenates the chunks into a single string.
-- The string is the content of the manifest file.

for chunk in response do
    manifest_content = manifest_content .. chunk
end

local input = nil
while #manifest_content == 0 do
   print("Failed to download manifest. Please check your internet connection.")
    os.sleep(1)
    repeat
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
    until input == "yes" or input == "no"

    if input == "no" then
        print("Update failed. Please check your internet connection.")
        os.sleep(extreme_delay)
        return
    elseif input == "yes" then
        response = internet.request(manifest_url)
        if response then
            manifest_content = ""
            for chunk in response do
                manifest_content = manifest_content .. chunk
            end
        end
    end
end

local manifest_path = "/tmp/install_manifest.lua"
local temp_manifest = io.open(manifest_path, "w")

if temp_manifest then
temp_manifest:write(manifest_content)
temp_manifest:close()
else
    print("Failed to open install_manifest.lua for writing. Please check your permissions.")
    os.sleep(short_delay)
    print("Exiting updater.")
    os.sleep(extreme_delay)
    return
end

print("Manifest downloaded successfully.")
os.sleep(short_delay)

local host_manifest = dofile("/install_manifest.lua")
local update_manifest = dofile(manifest_path)

print("Checking for updates...")
os.sleep(short_delay)

validateChecksum(host_manifest, update_manifest)

if #updates_needed == 0 then
    print("No updates needed. Exiting updater.")
    return
end
if #updates_needed == 1 then
    print("Update needed! 1 file to be updated.")
else
    print("Updates needed!  " .. #updates_needed .. " files to update.")
end

os.sleep(short_delay)
for i, update in ipairs(updates_needed) do
    print("Updating file " .. i .. " of " .. #updates_needed .. ": " .. update)
    os.sleep(long_delay)
    local result = deleteAndReplace("/", update)
    if not result then
        print("Failed to update " .. tostring(update) .. ".")
        os.sleep(short_delay)
        print("Aborting updater.")
        return
    end
end

filesystem.remove("/install_manifest.lua")
local os_manifest_path = "/install_manifest.lua"
local os_manifest = io.open(os_manifest_path, "w")

if os_manifest then
os_manifest:write(manifest_content)
os_manifest:close()
else
    print("Failed to open install_manifest.lua for writing. Please check your permissions.")
    os.sleep(short_delay)
    print("Exiting updater.")
    os.sleep(extreme_delay)
    return
end

print("All files updated!")
os.sleep(short_delay)
print("Restarting Computer...")
os.sleep(1.5)
os.execute("reboot")