local internet = require("internet")
local filesystem = require("filesystem")

local content = ""

print("Welcome to the LorielleOS Installer Bootstrap!")
os.sleep(1)
print("Checking for existing installer...")

local file = io.open("installer.lua", "r")
if file then
    print("Installer detected. Replacing old installer.")
    file:close()
    filesystem.remove("/home/installer.lua")
end

local file = io.open("installer.lua", "r")
if file then
    print("Failed to remove old installer. Please check permissions.")
    file:close()
    return
end
print("No existing installer found. Proceeding to download new installer...")
os.sleep(1)

print("Downloading installer.lua from LorielleOS-Mod GitHub...")
os.sleep(1)

---@diagnostic disable-next-line: undefined-field
local response = internet.request("https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/main/installer.lua")
print("Downloading...")
os.sleep(1)

if not response then
    print("No response. Please check connection and URL.")
    return
end

print("Response Received. Reading content...")
os.sleep(1)
for chunk in response do
    content = content .. chunk
    print("Received chunk of size: " .. #chunk)
    os.sleep(0.5)  -- Simulate processing time for each chunk
end

print("Download complete. Total size: " .. #content .. " bytes")
os.sleep(1)

if #content == 0 then
    print("Download failed. Check your connection or the URL.")
    return
end

local file = io.open("installer.lua", "w")
if not file then
    print("Failed to write to file. Check permissions.")
    return
end
file:write(content)
print("File written successfully.")
os.sleep(1)
file:close()

local answer
repeat
    io.write("Do you want to run the installer now? (y/n): ")
    answer = io.read():lower()
until answer == "y" or answer == "n"

if answer == "n" then
    print("Halting install. You can run it later by typing 'lua installer.lua'.")
    return
end

print("Running installer...")
os.sleep(1)
os.execute("installer.lua")

