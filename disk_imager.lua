local filesystem = require("filesystem")
local process = require("process")
local os = require("os")
local io = require("io")
local print = print
local internet = require("internet")

local short_delay = .5
local long_delay = 2
local extreme_delay = 5

local function wipeDirectory(path)
    for file in filesystem.list(path) do
        local full_path = filesystem.concat(path, file)
            if filesystem.isDirectory(full_path) then
                wipeDirectory(full_path) 
                filesystem.remove(full_path)
                print("Removed directory: " .. full_path)
            else
                filesystem.remove(full_path)
                print("Removed file: " .. full_path)
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

print("Welcome to the LorielleOS Imager!")
print("*************************************")
os.sleep(short_delay)
print("Intended for use with OpenComputers.")
print("*************************************")
os.sleep(short_delay)
print("USER WARNING: This imager will completely")
print("wipe your disk and install LorielleOS.")
print("*************************************")
os.sleep(short_delay)
print("If you are sure you want to proceed, type 'install' to continue")
os.sleep(short_delay)
print("*************************************")
print("If you would like to exit the installer, type 'exit' to cancel.")
os.sleep(short_delay)
print("**************************************")

local input
repeat
    io.write("Wipe disk and install? (install/exit):")
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
target_mnt = nil
local valid_mnt = false
repeat
    print("Please ensure you have a floppy disk mounted at /mnt/*floppy*.")
    print("Make sure you don't enter the hard drive mount.")
    print("or files may be wiped and install will fail.")
    io.write("Input 3 character target mnt (type exit to quit, or type info for how to find floppy address): ")
    input = io.read()
    if input then 
        input = input:lower() 
    end
    if input and #input ~= 3 and input ~= "exit" and input ~= "info" then
        print("Invalid input. Please enter exactly 3 characters.")
    end
    if #input == 3 then
        target_mnt = input:lower()
        local mnt_path = "/mnt/" .. target_mnt .. "/"
        if filesystem.exists(mnt_path) and filesystem.isDirectory(mnt_path) then
            valid_mnt = true
        else
            print("Mount point does not exist or is not a directory. Please try again.")
        end
    end
    if input == "info" then
        print("To find the floppy address, follow these steps:")
        print("1. Exit the installer.")
        print("2. Type cd to get to home.")
        print("3. Then type cd .., cd mnt, ls. This will show you the mounted directories.")
        print("4. Remove floppy and type ls again.")
        print("5. Put the floppy back in and type ls again. the three character code that appears is the floppy address.")
        print("The three digit code that stays is your hard drive address.")
        print("DO NOT USE THE HARD DRIVE ADDRESS. If there are multiple drives you'll see multiple codes.")
        print("6. Type cd to return to home, then run the installer again.")
    end

until valid_mnt or input == "exit"
if input == "exit" then
    print("Exiting installer. You can run it later by typing 'lua installer.lua'.")
    return
end

base_path = "/mnt/" .. target_mnt .. "/"

print("Proceeding with installation...")
os.sleep(short_delay)
print("Wiping hard drive...")
os.sleep(short_delay)
wipeDirectory("/mnt/".. target_mnt .. "/")
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
    os.sleep(10)
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
    outpath = filesystem.concat(base_path, filepath)
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
    end

    local dir = filesystem.path(outpath)
    if dir and not filesystem.exists(dir) then
        filesystem.makeDirectory(dir)
        print("Created directory: " .. dir)
        os.sleep(short_delay)
    end

    local file = io.open(outpath, "w")
    if file then
        file:write(file_content)
        print(outpath)
        file:close()
    else
        -- This is the line to add/modify:
        print("!!! CRITICAL ERROR: Failed to open file for writing: " .. filepath .. ". Error: " .. tostring(open_err))
        os.sleep(short_delay)
        print("Install failed. Hard drive may be irrecoverable.")
        print("Reinstall openOS and try again or toss the drive. Good luck!")
        os.sleep(extreme_delay)
        return
    end
end
print("All files downloaded and installed on disk.")
os.sleep(short_delay)
print("LorielleOS installation complete!")
os.sleep(short_delay)
print("You can now install LorielleOS on a blank hard drive.")
os.sleep(short_delay)
