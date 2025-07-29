local filesystem = require("filesystem")
local os = require("os")

local history_path = "/tmp/history.txt"

if history_path and filesystem.exists(history_path) and not filesystem.isDirectory(history_path) then
    os.execute(os.getenv("PAGER") .. " " .. history_path)
    os.exit()
end