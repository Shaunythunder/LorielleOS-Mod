_G.IN_PAGER = false

function loadfile(filename, ...)
  if filename:sub(1,1) ~= "/" then
    filename = (os.getenv("PWD") or "/") .. "/" .. filename
  end
  local handle, open_reason = require("filesystem").open(filename)
  if not handle then
    return nil, open_reason
  end
  local buffer = {}
  while true do
    local data, reason = handle:read(1024)
    if not data then
      handle:close()
      if reason then
        return nil, reason
      end
      break
    end
    buffer[#buffer + 1] = data
  end
  return load(table.concat(buffer), "=" .. filename, ...)
end

function dofile(filename)
  local program, reason = loadfile(filename)
  if not program then
    return error(reason .. ':' .. filename, 0)
  end
  return program()
end

function print(...)
  local args = table.pack(...)
  local stdout = io.stdout
  local pre = ""
  local history_message = ""
  for i = 1, args.n do
    local print_string = ((assert(tostring(args[i]), "'tostring' must return a string to 'print'")))
    stdout:write(pre, print_string)
    history_message = history_message .. pre .. print_string
    pre = "\t"
  end
  stdout:write("\n")
  stdout:flush()
  if not _G.IN_PAGER then
    local history_file = io.open("/tmp/history.txt", "a")
    if history_file then
      history_file:write(history_message .. "\n")
      history_file:close()
    end
  end
end
