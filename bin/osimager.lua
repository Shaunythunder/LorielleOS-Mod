-- LorielleOS Installer/Disk Imager
-- This script is designed to wipe a disk and install LorielleOS from a manifest file.

local filesystem = require("filesystem")
local component = require("component")
local os = require("os")
local table = require("table")
local io = require("io")
local print = print

local short_delay = .5
local long_delay = 2
local extreme_delay = 5

--These aren't technically needed but are here to satisfy an argument.
local wipe_exclusions = {
    ["/tmp"] = true,
    ["/tmp/disk_imager.lua"] = true,
}
local proxy, reason

local function labelDrive(mnt)
    print("Labeling drive as 'LorielleOS'...")
    os.execute("label /mnt/" .. mnt .. " " .. "LorielleOS")
end

local function cloneOS(os_mnt, target_mnt, manifest)
    -- Recursive function to copy files from the OS mount to the target mount.
    local os_base_path = "/mnt/" .. os_mnt .. "/"
    local target_base_path = "/mnt/" .. target_mnt .. "/"
    for _, entry in ipairs(manifest) do
        local os_file_path = filesystem.concat(os_base_path, entry.filename)
        local target_file_path = filesystem.concat(target_base_path, entry.filename)
        local dir = filesystem.path(target_file_path)
        if dir and not filesystem.exists(dir) then
            filesystem.makeDirectory(dir)
        end
        -- Opens the file and copies the binary to the target location.
        local os_file = io.open(os_file_path, "rb")
        local target_file = io.open(target_file_path, "wb")
        if os_file and target_file then
            target_file:write(os_file:read("*a"))
            os_file:close()
            target_file:close()
            print(os_base_path .. entry.filename .. " -> " .. target_base_path .. entry.filename)
        else
            print("Failed to copy:", os_file_path, "to", target_file_path)
            return false
        end
    end
    return true
end

local function checkValidMounts()
    local running_OS_mount_address = filesystem.get("/home")
    local valid_mnts = {}
    for mnt in filesystem.list("/mnt") do
        local mnt_path = filesystem.concat("/mnt", mnt)
        local mnt_address = filesystem.get(mnt_path)
        if mnt_address ~= running_OS_mount_address then
            local file_path = filesystem.concat(mnt_path, "fhae45q54h789qthq43w8thfw78hfgew.lua")
            local file = io.open(file_path, "w")
            if file then
                file:close()
                filesystem.remove(file_path)
                table.insert(valid_mnts, mnt)
            end
        else 
            local os_mnt = mnt
        end
    end
    return valid_mnts, os_mnt
end

local function printValidMounts()
    local mounts, os_mnt = checkValidMounts()
    if #mounts == 0 then
        print("No valid mounts found.")
        return
    end
    print("Available mounts:")
    for _, mnt in ipairs(mounts) do
        mnt = string.sub(mnt, 1, 3) -- Ensure only the first 3 characters are used
        print(mnt)
    end
end

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

print("Welcome to LorielleOS Installer/Disk Imager v2.2.1!")
os.sleep(short_delay)
print("USER WARNING: This imager will completely wipe your disk and install LorielleOS.")
os.sleep(short_delay)
print("Failure during installation may result in an unbootable system.")
os.sleep(short_delay)

::new_disk::
local input
local target_mnt = nil
local valid_mnt = false
local mnt_path = nil
local valid_mnts, os_mnt = checkValidMounts()
repeat
    ::refresh::
    printValidMounts()
    io.write("Input 3 character target mnt (XXX/refresh/exit/info): ")
    input = io.read()
    if input then 
        input = input:lower() 
    end
    if input and #input ~= 3 and input ~= "exit" and input ~= "info" and input ~= "refresh" then
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
        print("To find the floppy or hard drive address manually, follow these steps:")
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
        print("The three digit code that stays is your OS address.")
        os.sleep(long_delay)
        print("DO NOT USE THE OS ADDRESS. If there are multiple drives you'll see multiple codes.")
        os.sleep(long_delay)
        print("You can enter in a three character code to select the drive even if not listed in writable mounts, but install will fail if drive is read only.")
        os.sleep(long_delay)
        print("6. Type cd to return to home, then run the disk imager again.")
        os.sleep(long_delay) 
    end
    if input == "refresh" then
        -- Refreshes the list of valid mounts.
        print("Refreshing mount list...")
        os.sleep(short_delay)
        goto refresh
    end

until valid_mnt or input == "exit"
if input == "exit" then
    print("Exiting disk imager.")
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
print("Parsing manifest...")
os.sleep(short_delay)
local manifest = dofile("/install_manifest.lua")


if cloneOS(os_mnt, target_mnt, manifest) then
    print("LorielleOS files cloned successfully.")
else
    print("Failed to clone LorielleOS files. Please try again.")
    os.sleep(short_delay)
    return
end

print("All files downloaded and installed on disk.")
os.sleep(short_delay)
labelDrive(target_mnt)
print("LorielleOS installation complete!")
os.sleep(short_delay)
print("If installing from OpenOS, remove any OpenOS floppy disks or hard drives and reboot the computer.")

input = nil
repeat
    io.write("Install to another disk? (yes/no/reboot): ")
    input = io.read()
    if input then
        input = input:lower()
    end
until input == "yes" or input == "no" or input == "reboot"
if input == "yes" then
    print("Please insert another disk or drive.")
    os.sleep(short_delay)
    local answer
    repeat
    io.write("Have you inserted another disk or drive? (yes/exit): ")
    answer = io.read()
    if answer then
        answer = answer:lower()
    end
    until answer == "yes" or answer == "exit"
    if answer == "exit" then
        print("Exiting disk imager.")
        return
    end
    goto new_disk
elseif input == "no" then
    print("Exiting disk imager.")
elseif input == "reboot" then
    print("Rebooting computer...")
    os.sleep(short_delay)
    os.execute("reboot")
end
print("Disk imager exited.")
