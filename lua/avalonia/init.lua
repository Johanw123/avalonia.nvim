local M = {}
local ffi = require'ffi'
local api = vim.api
local cmd = vim.cmd
local fn = vim.fn
local bson = require("avalonia.bson")
local struct = require("avalonia.struct")

local function is_win()
  return package.config:sub(1, 1) == '\\'
end

local function get_path_separator()
  if is_win() then
    return '\\'
  end
  return '/'
end


local function script_path()
  local str = debug.getinfo(2, 'S').source:sub(2)
  if is_win() then
    str = str:gsub('/', '\\')
  end
  return str:match('(.*' .. get_path_separator() .. ')')
end

local function read_all(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end


local is_visible = function(bufnr)
  for _, tabid in ipairs(api.nvim_list_tabpages()) do
    for _, winid in ipairs(api.nvim_tabpage_list_wins(tabid)) do
      local winbufnr = api.nvim_win_get_buf(winid)
      local winvalid = api.nvim_win_is_valid(winid)

      if winvalid and winbufnr == bufnr then
        return true
      end
    end
  end

  return false
end

function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

local base_path = script_path() .. "../../"
local buf = api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_option(buf, 'modifiable', false)
vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
local win = nil
local stdout = vim.loop.new_tty(1, false)

api.nvim_create_autocmd({ "BufWinLeave" }, {
  callback = function(au)
    -- vim.print(vim.inspect(au))
    if au.buf == buf then
      -- M.clear_preview() --for kitty protocol
    end
  end,
})

api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    if is_visible(buf) then
     -- M.generate_preivew_image() -- for kitty protocol
    end
  M.update_xaml()
  end,
})

api.nvim_create_autocmd({ "BufEnter" }, {
  callback = function()
    if is_visible(buf) then
     -- M.generate_preivew_image() -- for kitty protocol
    end
  M.update_xaml()
  end,
})

-- local preview_win_restore

-- function M.toggle_window()
--   vim.print(base_path)
--
--   if is_visible(buf) then
--     api.nvim_win_close(win, false)  -- do not force
--   else
--     local cur_win = api.nvim_get_current_win()
--     local winrestore = fn.winsaveview()
--     vim.cmd('vsplit')
--     win = api.nvim_get_current_win()
--     api.nvim_win_set_buf(win, buf)
--     
--     preview_win_restore = fn.winsaveview()
--
--     vim.defer_fn(function()
--      M.generate_preivew_image()
--     end, 10)
--
--     api.nvim_set_current_win(cur_win)
--         fn.winrestview(winrestore)
--
--     -- M.draw_preview()
--   end
-- end

-- function M.draw_preview()
--  if is_visible(buf) then
--     M.clear_preview()
--
--     local cur_win = api.nvim_get_current_win()
--     local winrestore = fn.winsaveview()
--
--      api.nvim_set_current_win(win)
--         fn.winrestview(preview_win_restore)
--
--     -- local cur_win =
--     -- vim.api.nvim_win_set_cursor(win, { 0, 0 })
--     local test = vim.fn.system(base_path .. "draw.sh " .. base_path .. "Test.png")
--     vim.defer_fn(function()
--       stdout:write(test)
--       -- vim.cmd([[redraw]])
--     api.nvim_set_current_win(cur_win)
--     fn.winrestview(winrestore)
--
--     end, 10)
--   end
-- end

-- local lib

-- function M.generate_preivew_image()
--   local xaml = vim.fn.expand('%:p')
--  -- local t = "/mnt/c/Users/Johan/source/repos/AvaloniaApplication3/AvaloniaApplication3/Views/MainView.axaml"
--
-- -- local job = vim.fn.jobstart(
-- --     base_path .. 'AvaloniaPreviewTest ' .. xaml,
-- --     {
-- --         cwd = base_path,
-- --         on_stdout = function(job_id, data, event) print(vim.inspect(data)) end,
-- --         on_stderr = function(job_id, data, event) print(vim.inspect(data)) end,
-- --         on_exit = function() M.draw_preview() end,
-- --     }
-- -- )
--
--
-- ffi.cdef [[int Test();]]
-- ffi.cdef [[int Test2();]]
-- ffi.cdef [[void UpdateXaml(const char* s);]]
-- ffi.cdef [[void StartServer(const char* s);]]
-- -- lib = ffi.load('./Test/AvaloniaPreviewTest.dll')
-- lib = ffi.load("C:\\Users\\Johan\\source\\repos\\AvaloniaPreviewTest\\bin\\out\\win10-x64\\AvaloniaPreviewTest.dll")
-- local apa = lib.Test()
-- print("Return from Test: " .. apa)
--
-- -- local bepa = lib.StartServer("")
-- -- print("Return from Bepa: " .. bepa)
--
-- -- local bepa = lib.TestString("hello world")
-- -- print("Return from TestString: " .. ffi.string(bepa))
-- --
-- end

-- function M.clear_preview()
--   local deleteCall = vim.fn.system(base_path .. "delete.sh")
--   stdout:write(deleteCall)
-- end

local socket = vim.uv.new_tcp()

local function create_server(host, port, on_connect)
  local server = vim.uv.new_tcp()
  server:bind(host, port)
  server:listen(128, function(err)
    assert(not err, err)  -- Check for errors.
    server:accept(socket)  -- Accept client connection.
    on_connect(socket)  -- Start reading messages.
  end)
  return server
end

local function hexdecode(hex)
   return (hex:gsub("%x%x", function(digits) return string.char(tonumber(digits, 16)) end))
end

local function hexencode(str)
   return (str:gsub(".", function(char) return string.format("%02x", char:byte()) end))
end


local messageIds = {
  startDesignerSession = "854887CF26944EB6B4997461B6FB96C7",
  clientRenderInfo = "7A3C25D33652438D8EF186E942CC96C0",
  clientSupportedPixelFormats = "63481025701643FEBADCF2FD0F88609E",
  updateXaml = "9AEC9A2E63154066B4BAE9A9EFD0F8CC"
  }


function create_message(message, messageType)
  local bsonMessage = bson.encode(message)
  local dataLength = struct.pack("<I", string.len(bsonMessage))

  local typeHex = messageType
  local type = adjust_guid(hexdecode(typeHex))

  local fullMessage = dataLength .. type .. bsonMessage
  -- print("Len: " .. dataLength .. " Actual: " .. string.len(bsonMessage))
  -- print("creating message: " .. fullMessage)
  return fullMessage
end

function adjust_guid(guid)
  local sub1 = string.sub(guid, 1, 4)
  local sub2 = string.sub(guid, 5, 6)
  local sub3 = string.sub(guid, 7, 8)
  local sub4 = string.sub(guid, 9)

  -- print("sub1: " .. sub1)
  -- print("sub2: " .. sub2)
  -- print("sub3: " .. sub3)
  -- print("sub4: " .. sub4)
  --
  -- print("sub1R: " .. string.reverse(sub1))
  -- print("sub2R: " .. string.reverse(sub2))
  -- print("sub3R: " .. string.reverse(sub3))

  return string.reverse(sub1) .. string.reverse(sub2) .. string.reverse(sub3) .. sub4
end

function get_file_extension(url)
  return url:match("^.+(%..+)$")
end

local openUrlCommand

local config =
{
  openUrlCommand = nil,  -- start/open/xdg-open
  forceBrowser = nil,    -- firefox/chrome/msedge etc
  displayMethod = "html" -- html/kitty
}

local open_url = function(url)
  if config.openUrlCommand ~= nil then
    openUrlCommand = config.openUrlCommand
  elseif fn.has('win32') == 1 and fn.has("wsl") == 0 then
    openUrlCommand = "start"
  elseif fn.has('mac') then
    openUrlCommand = "open"
  else--if vim.fn.has('linux') then
    openUrlCommand = "xdg-open"
  end

  if config.forceBrowser then
    io.popen(openUrlCommand .. " " .. config.forceBrowser .. " " .. url)
  else
    io.popen(openUrlCommand .. " " .. url)
  end
end

local path = "C:\\Users\\Johan\\source\\repos\\AvaloniaApplication3\\AvaloniaApplication3.Desktop\\bin\\x64\\Release\\net7.0"
local dllPath = path .. "\\AvaloniaApplication3.Desktop.dll"
local assemblyPath = "C:\\Users\\Johan\\source\\repos\\AvaloniaApplication3\\AvaloniaApplication3\\bin\\x64\\Release\\net7.0\\AvaloniaApplication3.dll"
local configPath = path .. "\\AvaloniaApplication3.Desktop.runtimeconfig.json"
local depsPath = path .. "\\AvaloniaApplication3.Desktop.deps.json"


local server = nil

function M.start_server()

  if server ~= nil then
    print("server already running")
    return
  end

  local port = 9031

  -- print("creating server...")
  server = create_server('127.0.0.1', port, function(sock)
      sock:read_start(function(err, chunk)
        assert(not err, err)  -- Check for errors.
        if chunk then
        print(type(chunk))
          -- print('received: ' .. chunk)
        -- local lenS = string.sub(chunk, 1, 4)
        -- local unpacked =  struct.unpack("<I", lenS)
        -- print("unpacked: " .. unpacked)

        local typeS = string.sub(chunk, 5, 20)
        -- local data = string.sub(chunk, 21)
        -- local message = string.sub(chunk, 21)


        local hexS =  adjust_guid(typeS)
        local hex = string.upper(hexencode(hexS))

        -- print("lenth: " .. lenS)
        -- print("message: " .. message)

        -- local decodedMessage = bson.decode(message)
        -- print(vim.inspect(decodedMessage))

        if hex == messageIds.startDesignerSession then
          -- print("Start Designer message received")
          local pixelFormatMessage = create_message({formats ={1}}, messageIds.clientSupportedPixelFormats)
          -- print("Sending pixel format response...")
          socket:write(pixelFormatMessage)


          vim.schedule(function()
            open_url("http://127.0.0.1:9032/")
            M.update_xaml()
          end)
        end

        else  -- EOF (stream closed).
          -- print('closing socket')
          sock:close()  -- Always close handles to avoid leaks.
        end
      end)
    end)
    -- print('TCP echo-server listening on port: '.. port)


  local htmlUrl = "http://127.0.0.1:" .. tostring(port +1)
  local hostPath = "C:\\Users\\Johan\\.nuget\\packages\\avalonia\\11.0.5\\tools\\netcoreapp2.0\\designer\\Avalonia.Designer.HostApp.dll"

local cmd = "dotnet exec --runtimeconfig " .. configPath .. " --depsfile " .. depsPath .. " " .. hostPath .. " --method avalonia-remote --method html --html-url " .. htmlUrl .. " --transport tcp-bson://127.0.0.1:" .. port .. " " .. dllPath
local job = vim.fn.jobstart(
    cmd,
    {
      cwd = base_path,
      on_stdout = function(job_id, data, event) print(vim.inspect(data)) end,
      on_stderr = function(job_id, data, event) print(vim.inspect(data)) end,
      on_exit = function() print("On Exit")  end,
    }
)

end

function M.update_xaml()
  -- local t = "C:\\Users\\Johan\\source\\repos\\AvaloniaApplication3\\AvaloniaApplication3\\Views\\MainWindow.axaml"
  local xaml = vim.fn.expand('%:p')
  local ext = get_file_extension(xaml)

  if ext == nil then
    return
  end

  print("extension: " .. ext)

  if ext == ".axaml" then
    local content = read_all(xaml)
    local message = create_message({assemblyPath = assemblyPath, xaml = content}, messageIds.updateXaml)
    socket:write(message)
  end
end
-- M.generate_preivew_image()
-- M.start_server()
-- M.update_test()
-- M.haj()
-- require("image").setup({})
return M
