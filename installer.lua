local filesystem = require("filesystem")
local os = require("os")
local io = require("io")
local print = print
local internet = require("internet")

local short_delay = .5
local long_delay = 2
local extreme_delay = 5

local wipe_exclusions = {
    ["/tmp/installer.lua"] = true,
    ["/tmp/bootstrap.lua"] = true,
}

local function wipeDirectory(path)
    for file in filesystem.list(path) do
        local full_path = filesystem.concat(path, file)
        if not wipe_exclusions[full_path] then
            if filesystem.isDirectory(full_path) then
                wipeDirectory(full_path) 
                filesystem.remove(full_path)
                print(full_path)
            else
                filesystem.remove(full_path)
                print(full_path)
            end
        end
    end
end

local function checkCleanWipe(path, exclusions)
    for file in filesystem.list(path)do
        local full_path = filesystem.concat(path, file)
        if file ~= "." and file ~= ".." and not exclusions[full_path] then
            if path == "/" and file == "tmp" then
                -- Skip the tmp directory to avoid removing it
                local clean, culprit = checkCleanWipe(full_path, exclusions)
                if not clean then
                    return false, culprit
                end
            elseif filesystem.isDirectory(full_path) then
                local clean, culprit = checkCleanWipe(full_path, exclusions)
                if not clean then
                    return false, culprit
                end
            else
                return false, full_path
            end
        end
    end
    return true
end

print("Welcome to the LorielleOS Installer!")
print("*************************************")
os.sleep(short_delay)
print("Intended for use with OpenComputers.")
print("*************************************")
os.sleep(short_delay)
print("USER WARNING: This installer will completely")
print("wipe your hard drive and install LorielleOS.")
print("*************************************")
os.sleep(long_delay)
print("Please ensure you do not have sensitive data or")
print("files that you need before running this installer.")
print("*************************************")
os.sleep(long_delay)
print("All files will be lost forever.")
print("*************************************")
os.sleep(long_delay)
print("Please backup any important data before proceeding.")
print("*************************************")
os.sleep(long_delay)
print("Install failure may result in an irrecoverable hard drive.")
print("*************************************")
os.sleep(long_delay)
print("For more information, please exit the installer")
print("and type 'man install.'")
print("*************************************")
os.sleep(long_delay)
print("For more information on backing up,")
print("please exit the installer and type 'man backup.'")
print("*************************************")
os.sleep(long_delay)

print("If you are sure you want to proceed, type 'install' to continue")
os.sleep(short_delay)
print("*************************************")
print("If you would like to exit the installer, type 'exit' to cancel.")
os.sleep(short_delay)
print("**************************************")
print("Ensure installer and bootstrap are in the tmp directory.")
print("**************************************")
print("If not abort install move them.")

local input
repeat
    io.write("Wipe hard drive and install? (install/exit):")
    input = io.read()
    if input then 
        input = input:lower()
    end
until input == "install" or input == "exit"
if input == "exit" then
    print("Exiting installer. You can run it later by typing 'lua installer.lua'.")
    return
end

input = nil
repeat
    io.write("***POINT OF NO RETURN*** Proceed? (yes/no): ")
    input = io.read()
    if input then 
        input = input:lower() 
    end
until input == "yes" or input == "no"

if input == "no" then
    print("Exiting installer. You can run it later by typing 'lua installer.lua'.")
    return
end

print("Proceeding with installation...")
os.sleep(short_delay)
print("Wiping hard drive...")
os.sleep(short_delay)
wipeDirectory("/")
os.sleep(short_delay)
local clean, culprit = checkCleanWipe("/", wipe_exclusions)
if not clean then
    for i = 1, 5 do
        wipeDirectory("/")
        clean, culprit = checkCleanWipe("/", wipe_exclusions)
        if clean then
            break
        end
    end
end
if not clean then
    print("Wiped failed. Could not remove: " .. culprit)
    os.sleep(short_delay)
    print("Install can still continue, but file conflicts may occur.")
    os.sleep(short_delay)
    print("Installation may fail outright and hard drive irrecoverable.")
    os.sleep(short_delay)
    print("Continue at your own risk.")
    local response 
    repeat 
        io.write("Do you want to continue installation? (yes/no): ")
        response = io.read()
        if response then 
            response = response:lower() 
        end
    until response == "yes" or response == "no"
    if response == "no" then
        print("Install failed, hard drive may be irrecoverable. Reinstall openOS")
        print("and try again or toss the drive. Good luck!")
        os.sleep(5)
        return
    end
else
    print("Wipe successful.")
    os.sleep(short_delay)
end

print("Installing LorielleOS...")
os.sleep(short_delay)
print("Fetching install manifest...")
os.sleep(short_delay)

local manifest_url = "https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/refs/heads/main/install_manifest.txt"
local response = internet.request(manifest_url)
if not response then
    print("Failed to download manifest. Please check your internet connection.")
    os.sleep(short_delay)
    local input
    repeat
        print("Connect again? Hardrive may be irrecoverable")
        print("if installer is exited at this point.")
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
        print("Install failed, hard drive may be irrecoverable. Reinstall openOS")
        print("and try again or toss the drive. Good luck!")
        os.sleep(extreme_delay)
        return
    end
end

print("Manifest found. Parsing...")
os.sleep(short_delay)
local content = ""

for chunk in response do
    content = content .. chunk
    print("Received chunk of size: " .. #chunk)
    os.sleep(0.5)  -- Simulate processing time for each chunk
end

input = nil
while #content == 0 do
   print("Failed to download manifest. Please check your internet connection.")
    os.sleep(1)
    repeat
        print("Connect again? Hardrive may be irrecoverable")
        print("if installer is exited at this point.")
        print("Please ensure active internet connection.")
        print("Test by typing " .. manifest_url .. " in browser.")
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
    until input == "yes" or input == "no"

    if input == "no" then
        print("Install failed, hard drive may be irrecoverable. Reinstall openOS")
        print("and try again or toss the drive. Good luck!")
        os.sleep(extreme_delay)
        return
    elseif input == "yes" then
        response = internet.request(manifest_url)
        if response then
            content = ""
            for chunk in response do
                content = content .. chunk
                print("Received chunk of size: " .. #chunk)
                os.sleep(short_delay)  -- Simulate processing time for each chunk
            end
        end
    end
end

print("Download complete. Total size: " .. #content .. " bytes")
os.sleep(short_delay)
print("Manifest downloaded successfully.")
os.sleep(short_delay)
print("Parsing manifest...")

local files = {}

for line in content:gmatch("[^\r\n]+") do
    table.insert(files, line)
end

for _, filepath in ipairs(files) do
    local url = "https://raw.githubusercontent.com/shaunythunder/LorielleOS-mod/main/" .. filepath
    print("Downloading " .. filepath .. "...")
    local file_response = internet.request(url)
    if not file_response then
        print("Failed to download " .. filepath)
        os.sleep(short_delay)
        print("Install failed. Hard drive may be irrecoverable.")
        print("Reinstall openOS and try again or toss the drive. Good luck!")
        os.sleep(extreme_delay)
        return
    end

    local file_content = ""
    for chunk in file_response do
        file_content = file_content .. chunk
        print("Received chunk of size: " .. #chunk)
        os.sleep(0.5)  -- Simulate processing time for each chunk
    end

    local dir = filesystem.path(filepath)
    if dir and not filesystem.exists(dir) then
        filesystem.makeDirectory(dir)
        print("Created directory: " .. dir)
        os.sleep(short_delay)
    end

    local file = io.open(filepath, "w")
    if file then
        file:write(file_content)
        print(filepath)
        file:close()
    else
        print("Failed to write file: " .. filepath)
        os.sleep(short_delay)
        print("Install failed. Hard drive may be irrecoverable.")
        print("Reinstall openOS and try again or toss the drive. Good luck!")
        os.sleep(extreme_delay)
        return
    end
end
print("All files downloaded and installed successfully.")
os.sleep(short_delay)
print("LorielleOS installation complete! Have fun!")
os.sleep(short_delay)

input = nil
repeat
    io.write("Would you like to remove installation files? (y/n): ")
    input = io.read()
    if input then
        input = input:lower()
    end
until input == "y" or input == "n"
if input == "y" then
    local file = io.open("installer.lua", "r")
    if file then
        print("Removing installer.lua...")
        os.sleep(short_delay)
        file:close()
        filesystem.remove("/tmp/installer.lua")
    else
        print("No installer.lua found to remove.")
    end

    file = io.open("bootstrap.lua", "r")
    if file then
        print("Removing bootstrap.lua...")
        os.sleep(short_delay)
        file:close()
        filesystem.remove("/tmp/bootstrap.lua")
    else
        print("No bootstrap.lua found to remove.")
    end

else
    print("Installer files retained. You can run the installer again later.")
end

input = nil
repeat
    io.write("Would you like to reboot? (y/n): ")
    input = io.read()
    if input then
        input = input:lower()
    end
until input == "y" or input == "n"

if input == "y" then
    os.restart()
else
    return
end