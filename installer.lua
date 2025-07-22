local filesystem = require("filesystem")

local function wipeDirectory(path)
    for file in filesystem.list(path) do
        local full_path = filesystem.concat(path, file)
        if filesystem.isDirectory(full_path) then
            wipeDirectory(full_path) 
            filesystem.remove(full_path)
        else
            filesystem.remove(full_path)
        end
    end
end

print("Welcome to the LorielleOS Installer!")
os.sleep(1)
print("Intended for use with OpenComputers in Minecraft.")
os.sleep(1)
print("USER WARNING: This installer will completely wipe your hard drive and install LorielleOS.")
os.sleep(1)
print("Please ensure you do not have sensitive data or files that you need before running this installer.")
os.sleep(1)
print("All files will be lost forever. Please backup any important data before proceeding.")
os.sleep(1)
print("For more information, please exit the installer and type 'maninstall.'")
os.sleep(1)
print("For more information on backing up, please exit the installer and 'type man backup.'")
os.sleep(5)

print("If you are sure you want to proceed, type 'install' to continue")
os.sleep(1)
print("If you would like to exit the installer, type 'exit' to cancel.")
os.sleep(1)

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