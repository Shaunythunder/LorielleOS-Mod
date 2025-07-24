local filesystem = require("filesystem")
local process = require("process")
local os = require("os")
local io = require("io")
local print = print
local internet = require("internet")

local short_delay = .5
local long_delay = 2
local extreme_delay = 5

local wipe_exclusions = {
    ["/tmp"] = true,
    ["/tmp/installer.lua"] = true,
    ["/tmp/bootstrap.lua"] = true,
}

local function wipeDirectory(path)
    for file in filesystem.list(path) do
        local full_path = filesystem.concat(path, file)
        if wipe_exclusions[full_path] then
            print("Skipping excluded path: " .. full_path)
            os.sleep(short_delay)
        end
        if not wipe_exclusions[full_path] then
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
os.sleep(short_delay)
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
    os.sleep(10)
    print("Wipe successful.")
    os.sleep(short_delay)
end

-- If not, adjust 'first_filepath' accordingly or add a check.
local first_filepath = files[1]
local first_file_url = "https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/main/" .. first_filepath

print("Attempting to write the first OS file: " .. first_filepath .. " (with retries if needed)...")

local first_file_content = ""
local first_file_response = internet.request(first_file_url)
if first_file_response then
    for chunk in first_file_response do
        first_file_content = first_file_content .. chunk
    end
else
    print("!!! ERROR: Could not download first OS file (" .. first_filepath .. ") for test. Check URL/connection.")
    os.sleep(extreme_delay)
    return
end
if #first_file_content == 0 then
    print("!!! ERROR: Downloaded content for first OS file (" .. first_filepath .. ") is empty for test.")
    os.sleep(extreme_delay)
    return
end

local first_dir = filesystem.path(first_filepath)
-- Ensure parent directory for the first file, only if it's not the root
if #first_dir > 0 and not filesystem.exists(first_dir) then 
    local mk_dir_success, mk_dir_err = filesystem.makeDirectory(first_dir)
    if not mk_dir_success then
        print("!!! CRITICAL ERROR: Failed to create directory for first file: " .. first_dir .. ". Error: " .. tostring(mk_dir_err))
        print("Installation cannot proceed.")
        os.sleep(extreme_delay)
        return
    end
    print("Created directory for first file: " .. first_dir)
    os.sleep(short_delay)
end


local max_retries = 5
local retry_count = 0
local first_file_written = false

while not first_file_written and retry_count < max_retries do
    local file, open_err = io.open("/" .. first_filepath, "w") -- Ensure full path for root files
    if file then
        file:write(first_file_content)
        file:close()
        print("Successfully wrote first file: " .. first_filepath)
        first_file_written = true
    else
        retry_count = retry_count + 1
        print("!!! WARNING: Failed to write " .. first_filepath .. " (Attempt " .. retry_count .. "/" .. max_retries .. "). Error: " .. tostring(open_err))
        os.sleep(long_delay) -- Longer delay for retries
    end
end

if not first_file_written then
    print("!!! CRITICAL ERROR: Failed to write " .. first_filepath .. " after multiple retries.")
    print("Installation cannot proceed. Hard drive may be irrecoverable.")
    os.sleep(extreme_delay)
    return
end

-- Remove the first file from the 'files' table so the main loop doesn't try to write it again
table.remove(files, 1) 

-- >>> END OF NEW LOGIC <<<


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
        -- This is the line to add/modify:
        print("!!! CRITICAL ERROR: Failed to open file for writing: " .. filepath .. ". Error: " .. tostring(open_err))
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