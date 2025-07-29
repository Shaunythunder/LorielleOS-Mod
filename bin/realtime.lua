local args, options = require("shell").parse(...)
local internet = require("internet")
local filesystem = require("filesystem")
local os = require("os")
local short_delay = 0.5
local long_delay = 1.5
local extreme_delay = 3

local manifest_url = "http://worldtimeapi.org/api/timezone/America/New_York"
local response = internet.request(manifest_url)
if not response then
    print("Failed to connect. Please check your internet connection.")
    os.sleep(short_delay)
    local input
    repeat
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
        print("Connection failed. Please check your internet connection.")
        os.sleep(extreme_delay)
        return
    end
end

local content = ""

-- Handles packets from the response.
-- It concatenates the chunks into a single string.
-- The string is the content of the manifest file.
for chunk in response do
    content = content .. chunk
end

input = nil
while #content == 0 do
   print("Failed to connect. Please check your internet connection.")
    os.sleep(1)
    repeat
        print("Test by typing " .. manifest_url .. " in browser.")
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
    until input == "yes" or input == "no"

    if input == "no" then
        print("Please check your internet connection.")
        os.sleep(extreme_delay)
        return
    elseif input == "yes" then
        response = internet.request(manifest_url)
        if response then
            content = ""
            for chunk in response do
                content = content .. chunk
            end
        end
    end
end

local datetime = content:match('"datetime":"(.-)"')
local date = datetime:match("^(%d+-%d+-%d+)")
local time = datetime:match("T(%d+:%d+:%d+)")
local date_time = date .. " " .. time

if options.t then
    print(time)
elseif options.d then
    print(date)
else
    print(date_time)
end
