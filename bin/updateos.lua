-- LorielleOS Updater

local options = require("shell").parse(...)
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

local download_path
if options.d then 
    -- d is for dev. This is used for development purposes.
    -- It sets the download path to a local server.
    download_path = "https://localhost:8000/"
else
    -- Otherwise, it sets the download path to the LorielleOS-Mod repository.
    download_path = "https://raw.githubusercontent.com/Shaunythunder/LorielleOS-mod/main/"
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

local function getOSMount()
    local running_OS_mount_address = filesystem.get("/home")
    for mnt in filesystem.list("/mnt") do
        local mnt_path = filesystem.concat("/mnt", mnt)
        local mnt_address = filesystem.get(mnt_path)
        if mnt_address == running_OS_mount_address then
            local os_mnt = mnt
            local os_path = mnt_path
            return os_mnt, os_path
        end
    end
end

local function deleteAndReplace(base_path, file)
    local file_path = filesystem.concat(base_path, file)
    if filesystem.exists(file_path) then
        filesystem.remove(file_path)
        if not filesystem.exists(file_path) then
            print("Removed file: " .. file_path)
        else
            print("Failed to remove file: " .. file_path)
            return false
        end
    end
    -- If the file is in the exclusions table, it will not be downloaded.
        print("Updating " .. file .. "...")
        -- Downloads the file, concats the content into a string and then writes it to the disk.
        local filepath = file_path
        local url = filesystem.concat(download_path, filepath)
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
            print("Updating " .. file_path)
            file:close()
        end
end

print("Welcome to LorielleOS Updater 0.1!")
os.sleep(short_delay)
print("Do not shut down the computer while the updater is running.")
os.sleep(short_delay)

local target_mnt, base_path = getOSMount()

os.sleep(short_delay)
print("Fetching update manifest...")
os.sleep(short_delay)

-- Pulls install manifest from GitHub.
-- The manifest is a text file that contains the list of files to be installed.
-- It is stored in the LorielleOS-Mod repository.
local manifest_url = filesystem.concat(download_path, "install_manifest.lua")
local response = internet.request(manifest_url)
if not response then
    print("Failed to download manifest. Please check your internet connection.")
    os.sleep(short_delay)
    local input
    repeat
        print("Connect again? Nothing is written. There is no risk")
        print("if disk imager is exited at this point.")
        print("Please ensure active internet connection.")
        print("Test by typing " .. manifest_url .. " in browser.")
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
        print("Install failed. Please check your internet connection.")
        os.sleep(extreme_delay)
        return
    end
end

print("Manifest found. Parsing...")
os.sleep(short_delay)
local content = ""

-- Handles packets from the response.
-- It concatenates the chunks into a single string.
-- The string is the content of the manifest file.
for chunk in response do
    content = content .. chunk
end

input = nil
while #content == 0 do
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
            content = ""
            for chunk in response do
                content = content .. chunk
            end
        end
    end
end

print("Manifest downloaded successfully.")
local manifest_path = "/tmp/install_manifest.lua"
local manifest = io.open(manifest_path, "w")
if manifest then
print("Writing manifest to RAM...")
manifest:write(content)
print("Manifest written to RAM.")
manifest:close()
else
    print("Failed to open install_manifest.lua for writing. Please check your permissions.")
    os.sleep(short_delay)
    print("Exiting updater.")
    os.sleep(extreme_delay)
    return
end

print("Manifest downloaded successfully.")

local host_manifest = dofile("/install_manifest.lua")
local update_manifest = dofile(manifest_path)


print("Checking for updates...")

validateChecksum(host_manifest, update_manifest)

if #updates_needed == 0 then
    print("No updates needed. Exiting updater.")
    return
end

for update in updates_needed do
    if not deleteAndReplace(base_path, update) then
        print("Failed to update " .. update .. ".")
        os.sleep(short_delay)
        print("Aborting updater.")
        return
    end
end

os.execute("cp /tmp/install_manifest.lua /install_manifest.lua")


print("All files updated. Exiting updater.")
os.sleep(short_delay)