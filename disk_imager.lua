-- LorielleOS Installer/Disk Imager
-- This script is designed to wipe a disk and install LorielleOS from a manifest file.

local filesystem = require("filesystem")
local process = require("process")
local os = require("os")
local io = require("io")
local print = print
local internet = require("internet")

local short_delay = .5
local long_delay = 2
local extreme_delay = 5

--These aren't technically needed but are here to satisfy an argument.
local wipe_exclusions = {
    ["/tmp"] = true,
    ["/tmp/disk_imager.lua"] = true,
}

local function wipeDirectory(path)
    -- Logic for wiping the target drive
    -- Uses the inital path (argument: path) to signify the drive to wipe.
    for file in filesystem.list(path) do
        -- Concatenate is /mnt/path/ + relative file path.
        local full_path = filesystem.concat(path, file)
            if filesystem.isDirectory(full_path) then
                --Recursive system call to wipe the directory
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
    -- Runs through the directory to make sure that there is nothing left. 
    for file in filesystem.list(path)do
        local full_path = filesystem.concat(path, file)
        -- Skips over the . and .. directories as those are always present.
        -- Also skips over any files or directories that are in the exclusions table.
        if file ~= "." and file ~= ".." and not exclusions[full_path] then
            if path == "/" and file == "tmp" then
                -- Skip the tmp directory to avoid removing it
                local clean, culprit = checkCleanWipe(full_path, exclusions)
                -- If there is an issue, it throws an error with the offending file or directory.
                if not clean then
                    return false, culprit
                end
            elseif filesystem.isDirectory(full_path) then
                -- If there is an issue, it throws an error with the offending file or directory.
                local clean, culprit = checkCleanWipe(full_path, exclusions)
                if not clean then
                    return false, culprit
                end
            else
                return false, full_path
            end
        end
    end
    -- If it gets here, then it didn't detect anything.
    return true
end

print("Welcome to the LorielleOS Installer/Disk Imager v1.4 Alpha!")
print("*************************************")
os.sleep(short_delay)
print("Intended for use with OpenComputers.")
print("*************************************")
os.sleep(short_delay)
print("USER WARNING: This imager will completely")
print("wipe your disk and install LorielleOS.")
print("*************************************")
print("Failure during installation may result in an unbootable system.")
os.sleep(short_delay)

local input
repeat
    io.write("Wipe disk and install? (install/exit):")
    input = io.read()
    if input then 
        input = input:lower()
    end
until input == "install" or input == "exit"
if input == "exit" then
    print("Exiting disk imager. You can run it later by typing '/tmp/disk_imager.lua'.")
    return
end

input = nil
local target_mnt = nil
local valid_mnt = false
local mnt_path = nil
repeat
    print("Please ensure you have either a hard drive or floppy disk mounted at /mnt/*target*.")
    print("Make sure you don't enter the mount of the current OS (OpenOS flopppy or OS hard drive).")
    print("or files may be wiped and install will fail.")
    io.write("Input 3 character target mnt (type exit to quit, or type info for information on how to find floppy address): ")
    input = io.read()
    if input then 
        input = input:lower() 
    end
    if input and #input ~= 3 and input ~= "exit" and input ~= "info" then
        print("Invalid input. Please enter exactly 3 characters.")
    end
    if #input == 3 then
        -- Takes the valid input and sets the mount point.
        -- It checks if the mount point exists and is a directory.
        -- If it does, it sets valid_mnt to true.
        target_mnt = input:lower()
        mnt_path = "/mnt/" .. target_mnt .. "/"
        if filesystem.exists(mnt_path) and filesystem.isDirectory(mnt_path) then
            valid_mnt = true
        else
            print("Mount point does not exist or is not a directory. Please try again.")
        end
    end
    if input == "info" then
        print("To find the floppy or hard drive address, follow these steps:")
        print("1. Exit the installer.")
        os.sleep(long_delay)
        print("2. Type cd to get to home.")
        os.sleep(long_delay)
        print("3. Then type cd .., cd mnt, ls. This will show you the mounted directories.")
        os.sleep(long_delay)
        print("4. Remove floppy and type ls again.")
        os.sleep(long_delay)
        print("5. Put the floppy back in and type ls again. the three character code that appears is the floppy address.")
        os.sleep(long_delay)
        print("The three digit code that stays is your hard drive address.")
        os.sleep(long_delay)
        print("DO NOT USE THE HARD DRIVE ADDRESS. If there are multiple drives you'll see multiple codes.")
        os.sleep(long_delay)
        print("6. Type cd to return to home, then run the installer again.")
        os.sleep(long_delay)
        
    end

until valid_mnt or input == "exit"
if input == "exit" then
    print("Exiting installer. You can run it later by typing '/tmp/disk_imager.lua'.")
    return
end

local base_path = "/mnt/" .. target_mnt .. "/"

print("Proceeding with installation...")
os.sleep(short_delay)
print("Wiping hard drive...")
os.sleep(short_delay)
wipeDirectory("/mnt/".. target_mnt .. "/")
os.sleep(short_delay)
local clean, culprit = checkCleanWipe("/mnt/".. target_mnt .. "/", wipe_exclusions)
if not clean then
    -- If the wipe fails, it will try to wipe the directory 5 times.
    for i = 1, 5 do
        wipeDirectory("/")
        clean, culprit = checkCleanWipe("/mnt/".. target_mnt .. "/", wipe_exclusions)
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
        print("Install failed, drive may be irrecoverable.")
        print("Try again or toss the drive. Good luck!")
        os.sleep(5)
        return
    end
else
    os.sleep(1)
    print("Wipe successful.")
    os.sleep(short_delay)
end

print("Installing LorielleOS...")
os.sleep(short_delay)
print("Fetching install manifest...")
os.sleep(short_delay)


-- Pulls install manifest from GitHub.
-- The manifest is a text file that contains the list of files to be installed.
-- It is stored in the LorielleOS-Mod repository.
local manifest_url = "https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/refs/heads/main/install_manifest.txt"
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
        print("Type /tmp/disk_imager.lua to try again. Good luck!")
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
        print("Connect again? Nothing is written. There is no risk")
        print("if disk imager is exited at this point.")
        print("Please ensure active internet connection.")
        print("Test by typing " .. manifest_url .. " in browser.")
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
    until input == "yes" or input == "no"

    if input == "no" then
        print("Install failed. Please check your internet connection.")
        print("Type /tmp/disk_imager.lua to try again. Good luck!")
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

local manifest = io.open("install_manifest.lua", "w")
manifest:write(content)
manifest:close()

os.sleep(short_delay)
print("Manifest downloaded successfully.")
os.sleep(short_delay)
print("Parsing manifest...")

local files = dofile("install_manifest.lua")

for _, entry in ipairs(files) do
    -- Downloads the file, concats the content into a string and then writes it to the disk.
    local filepath = entry.filename
    local url = "https://raw.githubusercontent.com/shaunythunder/LorielleOS-mod/main/" .. filepath
    local outpath = filesystem.concat(base_path, filepath)
    local file_path = filepath
    local file_response = internet.request(url)
    if not file_response then
        print("Failed to download " .. filepath)
        os.sleep(short_delay)
        print("Install failed. Hard drive may be irrecoverable.")
        print("Reinstall OpenOS and try again or toss the drive. Good luck!")
        os.sleep(extreme_delay)
        return
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
        print("GitHub/LorielleOS-Mod/main/" .. file_path .. " -> " .. outpath)
        file:close()
    else
        print("Failed to open file for writing: " .. filepath .. ". Error: " .. tostring(open_err))
        os.sleep(short_delay)
        print("This means you picked a read only drive. Computer needs to be restarted.")
        print("Run the disk imager and try again. Good luck!")
        os.sleep(extreme_delay)
        return
    end
end
print("All files downloaded and installed on disk.")
os.sleep(short_delay)
print("LorielleOS installation complete!")
os.sleep(short_delay)
print("If you are running this on a hard drive, remove any floppy disks and reboot the computer.")
os.sleep(short_delay)
