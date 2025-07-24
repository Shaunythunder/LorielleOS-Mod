local internet = require("internet")
local filesystem = require("filesystem")

local installer_url = "https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/main/installer.lua"
local installer_path = "/tmp/installer.lua"
local content = ""

local short_delay = 0.5

print("Welcome to the LorielleOS Installer Bootstrap!")
os.sleep(short_delay)

print("Extracting installer from LorielleOS-Mod GitHub...")
os.sleep(short_delay)

---@diagnostic disable-next-line: undefined-field
local response = internet.request(installer_url)
print("Downloading...")
os.sleep(short_delay)

if not response then
    print("No response. Please check connection and URL.")
    return
end

print("Response Received. Reading content")
os.sleep(short_delay)
for chunk in response do
    content = content .. chunk
    print("Received chunk of size: " .. #chunk)
end

print("Download complete. Total size: " .. #content .. " bytes")
os.sleep(short_delay)

if #content == 0 then
    print("Download failed. Check your connection or the URL.")
    return
end

local file = io.open(installer_path, "w")
if not file then
    print("Failed to write to file. Check permissions.")
    return
end
file:write(content)
print("File written successfully.")
os.sleep(short_delay)
file:close()

local answer
repeat
    io.write("Do you want to run the installer now? (y/n): ")
    answer = io.read():lower()
until answer == "y" or answer == "n"

if answer == "n" then
    print("Halting install. Enter 'lua installer.lua' to run installer.")
    return
end

print("Running installer...")

local func, err = load(content, "@/tmp/installer.lua")
if not func then
    print("Failed to load installer:" .. err)
    return
end

local success, error = pcall(func)
if not success then
    print("Installer error: " .. error)
    return
end

print("Installer completed successfully.")