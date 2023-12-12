local utils = {}

local config = require("avalonia.config")

function utils.hex_decode(hex)
   return (hex:gsub("%x%x", function(digits) return string.char(tonumber(digits, 16)) end))
end

function utils.hex_encode(str)
   return (str:gsub(".", function(char) return string.format("%02x", char:byte()) end))
end

function utils.open_url(url)
  local open_url_command
  local conf = config.get_config()

  if conf.open_command ~= nil then
    open_url_command = conf.open_command
  elseif vim.fn.has('win32') == 1 and vim.fn.has("wsl") == 0 then
    open_url_command = "start"
  elseif vim.fn.has('mac') then
    open_url_command = "open"
  else--if vim.fn.has('linux') then
    open_url_command = "xdg-open"
  end

  if conf.forced_browser then
    io.popen(open_url_command .. " " .. conf.forced_browser .. " " .. url)
else
    io.popen(open_url_command .. " " .. url)
  end
end

function utils.file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

-- local on_windows = vim.loop.os_uname().version:match("Windows")

function utils.get_file_extension(url)
  return url:match("^.+(%..+)$")
end

function utils.get_file_name(url)
  return url:match("^.+/(.+)$")
end

function utils.get_file_path(str)
  if utils.is_win() then
    str = str:gsub('/', '\\')
  end

  return str:match("(.*".. utils.get_path_separator() ..")")
end

function utils.is_win()
  return package.config:sub(1, 1) == '\\'
end

function utils.get_path_separator()
  if utils.is_win() then
    return '\\'
  end
    return '/'
end

function utils.script_path()
  local str = debug.getinfo(2, 'S').source:sub(2)
  if utils.is_win() then
    str = str:gsub('/', '\\')
  end
  return str:match('(.*' .. utils.get_path_separator() .. ')')
end

function utils.read_all_text(file)
    local f = io.open(file, "rb")
    if f == nil then
      return nil
    end
    local content = f:read("*all")
    f:close()
    return content
end

return utils
