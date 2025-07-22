require ("internet")

local content = ""

print("Downloading test.lua from GitHub...")
local response = internet.request("https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/main/test.lua")
print("Downloading...")

if not response then
    print("No response. Please check connection and URL.")
    return
end

print("Response Received. Reading content...")
os.sleep(1)
for chunk in response do
    content = content .. chunk
end

if #content == 0 then
    print("Download failed. :(")
    return
end

local file = io.open("test.lua", "w")
file:write(content)
file:close()
print("File downloaded successfully!")

print("Running test.lua...")
os.execute("lua test.lua")
print("Test completed. Cleaning up...")
os.execute("rm -f test.lua")

local file = io.open("test.lua", "r")
if not file then
    print("Clean up completed successfully!")
    return
end
file:close()
print("Clean up failed. :(")

