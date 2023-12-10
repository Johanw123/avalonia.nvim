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

function utils.get_file_extension(url)
  return url:match("^.+(%..+)$")
end

function utils.get_file_name(url)
  return url:match("^.+/(.+)$")
end

function utils.get_file_path(str,sep)
    sep=sep or'/'
    return str:match("(.*"..sep..")")
end

return utils
