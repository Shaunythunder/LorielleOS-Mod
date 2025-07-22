local filesystem = require("filesystem")

local wipe_exclusions = {
    ["/home/installer.lua"] = true,
    ["/home/bootstrap.lua"] = true,
}
local download_exclusions = {
    ["/home/README.txt"] = true,
    ["/home/license.txt"] = true,
}

local function wipeDirectory(path)
    for file in filesystem.list(path) do
        local full_path = filesystem.concat(path, file)
        if not wipe_exclusions[full_path] then
            if filesystem.isDirectory(full_path) then
                wipeDirectory(full_path) 
                filesystem.remove(full_path)
            else
                filesystem.remove(full_path)
            end
        end
    end
end

print("Welcome to the LorielleOS Installer!")
print("*************************************")
os.sleep(1)
print("Intended for use with OpenComputers.")
print("*************************************")
os.sleep(1)
print("USER WARNING: This installer will completely")
print("wipe your hard drive and install LorielleOS.")
print("*************************************")
os.sleep(2.5)
print("Please ensure you do not have sensitive data or")
print("files that you need before running this installer.")
print("*************************************")
os.sleep(2.5)
print("All files will be lost forever.")
print("*************************************")
os.sleep(2.5)
print("Please backup any important data before proceeding.")
print("*************************************")
os.sleep(2.5)
print("For more information, please exit the installer")
print("and type 'man install.'")
print("*************************************")
os.sleep(2.5)
print("For more information on backing up,")
print("please exit the installer and type 'man backup.'")
print("*************************************")
os.sleep(5)

print("If you are sure you want to proceed, type 'install' to continue")
os.sleep(2)
print("*************************************")
print("If you would like to exit the installer, type 'exit' to cancel.")
os.sleep(2)

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

local answer
repeat
    io.write("***POINT OF NO RETURN*** Proceed? (yes/no): ")
    answer = io.read()
    if answer then 
        answer = answer:lower() 
    end
until answer == "yes" or answer == "no"

if answer == "no" then
    print("Exiting installer. You can run it later by typing 'lua installer.lua'.")
    return
end

print("Proceeding with installation...")
os.sleep(1)
print("Wiping hard drive...")
os.sleep(1)
wipeDirectory("/")
