local fs = require("filesystem")
local shell = require("shell")
local lib = {}

function lib.reportNotFound(path, reason)
  checkArg(1, path, "string")
  if fs.isDirectory(shell.resolve(path)) then
    io.stderr:write(path .. ": is a directory\n")
    return 126
  elseif type(reason) == "string" then
    io.stderr:write(path .. ": " .. reason .. "\n")
  end
  return 127
end

return lib
