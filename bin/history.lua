local filesystem = require("filesystem")
local os = require("os")

local history_path = "/tmp/sh_history.log"

print("Loading LorielleOS history viewer...")
if history_path and filesystem.exists(history_path) and not filesystem.isDirectory(history_path) then
    os.execute(os.getenv("PAGER") .. " --history " .. history_path)
    os.exit()
end