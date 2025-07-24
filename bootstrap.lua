local internet = require("internet")
local filesystem = require("filesystem")

local imager_url = "https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/refs/heads/disc_imager_start/disk_imager.lua"
local imager_path = "/tmp/disk_imager.lua"
local content = ""

local short_delay = 0.5

print("Welcome to the LorielleOS disk imager Bootstrap!")
os.sleep(short_delay)

print("Extracting disk imager from LorielleOS-Mod GitHub...")
os.sleep(short_delay)

---@diagnostic disable-next-line: undefined-field
local response = internet.request(imager_url)
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

local file = io.open(imager_path, "w")
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
    io.write("Do you want to run the disk imager now? (y/n): ")
    answer = io.read():lower()
until answer == "y" or answer == "n"

if answer == "n" then
    print("Halting install. Enter 'lua disk imager.lua' to run disk imager.")
    return
end

print("Running disk imager...")

local func, err = load(content, "@/tmp/disk_imager.lua")
if not func then
    print("Failed to load disk imager:" .. err)
    return
end

local success, error = pcall(func)
if not success then
    print("disk imager error: " .. error)
    return
end

print("disk imager completed successfully.")