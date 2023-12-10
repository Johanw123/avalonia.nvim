local M = {}
local ffi = require'ffi'
local api = vim.api
local cmd = vim.cmd
local fn = vim.fn
local uv = vim.uv
local bson = require("avalonia.bson")
local struct = require("avalonia.struct")
local utils = require("avalonia.utils")
local config = require("avalonia.config")

local function is_win()
  return package.config:sub(1, 1) == '\\'
end
local on_windows = vim.loop.os_uname().version:match("Windows")

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
    -- vim.print_debug(vim.inspect(au))
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
--   vim.print_debug(base_path)
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
-- --         on_stdout = function(job_id, data, event) print_debug(vim.inspect(data)) end,
-- --         on_stderr = function(job_id, data, event) print_debug(vim.inspect(data)) end,
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
-- print_debug("Return from Test: " .. apa)
--
-- -- local bepa = lib.StartServer("")
-- -- print_debug("Return from Bepa: " .. bepa)
--
-- -- local bepa = lib.TestString("hello world")
-- -- print_debug("Return from TestString: " .. ffi.string(bepa))
-- --
-- end

-- function M.clear_preview()
--   local deleteCall = vim.fn.system(base_path .. "delete.sh")
--   stdout:write(deleteCall)
-- end

local socket = uv.new_tcp()


local function print_debug(message)
  local conf = config.get_config()
  if conf.debug then
    print(message)
  end
end

function str_split(delim,str)
    local t = {}

    for substr in string.gmatch(str, "[^".. delim.. "]*") do
        if substr ~= nil and string.len(substr) > 0 then
            table.insert(t,substr)
        end
    end

    return t
end

local function get_free_port()
  local tcp = vim.loop.new_tcp()
	tcp:bind("127.0.0.1", 0)
	local port = tcp:getsockname().port
	tcp:shutdown()
	tcp:close()
  return port
end

local function create_server(host, port, on_connect)
  local server = uv.new_tcp()

  print_debug("Creating server: " .. host .. " - " .. port)

  local rtn = server:bind(host, port)
  -- print_debug("Bind: " .. rtn)
  rtn = server:listen(128, function(err)
    -- print_debug("Listening on port: " .. port)
    assert(not err, err)
    rtn = server:accept(socket)
    -- print_debug("Accept: " .. rtn)
    on_connect(socket)
  end)
  -- print_debug("Listen: " .. rtn)
  return server
end


function M.setup(user_config)
  config.setup(user_config or {})
end

local messageIds = {
  startDesignerSession = "854887CF26944EB6B4997461B6FB96C7",
  clientRenderInfo = "7A3C25D33652438D8EF186E942CC96C0",
  clientSupportedPixelFormats = "63481025701643FEBADCF2FD0F88609E",
  updateXaml = "9AEC9A2E63154066B4BAE9A9EFD0F8CC"
  }



function parse_sln(sln_path)

  local content = read_all(sln_path)
  vim.print(vim.inspect(content))
  local apa = string.match(content, "Project*")
  vim.print(apa)


  local projects = {}

  for line in content:gmatch("([^\n]*)\n?") do
    local apa = string.match(line, "Project%(")
    if apa ~= nil then
      local split1 = str_split("=", line)
      vim.print(split1)
      if #split1 > 1 then
        local split2 = str_split(",", split1[2])
        vim.print(split2)

        if #split2 > 2 then
          -- local project_name = split2[1]
          local project_path = split2[2]

          table.insert(projects, project_path)
        end
      end
    end
  end

  return projects
end

function get_avalonia_version(sln_dir)
  local props_file = sln_dir .. "/Directory.Build.props"
  local content = read_all(props_file)
  local version = string.match(content, "<AvaloniaVersion>(.-)</AvaloniaVersion>")
  print("AvaloniaVersion: " .. version)
  return version
end

function create_message(message, messageType)
  local bsonMessage = bson.encode(message)
  local dataLength = struct.pack("<I", string.len(bsonMessage))

  local typeHex = messageType
  local type = adjust_guid(utils.hex_decode(typeHex))

  local fullMessage = dataLength .. type .. bsonMessage

  return fullMessage
end

function adjust_guid(guid)
  local sub1 = string.sub(guid, 1, 4)
  local sub2 = string.sub(guid, 5, 6)
  local sub3 = string.sub(guid, 7, 8)
  local sub4 = string.sub(guid, 9)

  -- print_debug("sub1: " .. sub1)
  -- print_debug("sub2: " .. sub2)
  -- print_debug("sub3: " .. sub3)
  -- print_debug("sub4: " .. sub4)
  --
  -- print_debug("sub1R: " .. string.reverse(sub1))
  -- print_debug("sub2R: " .. string.reverse(sub2))
  -- print_debug("sub3R: " .. string.reverse(sub3))

  return string.reverse(sub1) .. string.reverse(sub2) .. string.reverse(sub3) .. sub4
end


-- local path = "C:\\Users\\Johan\\source\\repos\\AvaloniaApplication3\\AvaloniaApplication3.Desktop\\bin\\x64\\Release\\net7.0"
-- local dllPath = path .. "\\AvaloniaApplication3.Desktop.dll"
-- local assemblyPath = "C:\\Users\\Johan\\source\\repos\\AvaloniaApplication3\\AvaloniaApplication3\\bin\\x64\\Release\\net7.0\\AvaloniaApplication3.dll"
-- local configPath = path .. "\\AvaloniaApplication3.Desktop.runtimeconfig.json"
-- local depsPath = path .. "\\AvaloniaApplication3.Desktop.deps.json"


local server = nil
local port = nil

function M.start_server()

  if server ~= nil then
    print_debug("server already running")
    -- print_debug(vim.inspect(server))
    -- vim.pretty_print_debug(server)
    return
  end

  local conf = config.get_config()

  if conf.tcp_port == 0 then
    port = get_free_port()
  else
    port = conf.tcp_port
  end

  local htmlUrl = "http://127.0.0.1:" .. tostring(port + 1)
  local hostPath

  local cwd = vim.fn.getcwd()

  -- local root_dir = vim.fs.dirname(vim.fs.find({'*.sln'}, { upward = true })[1])
       local root = vim.fs.find(function(name, _)
          return name:match('.*%.sln$')
        end, {limit = math.huge, type = 'file', upward=true})

  print("CWD: " .. cwd)
  print(vim.inspect(root))

  local solution_path = root[1]
  local solution_dir = utils.get_file_path(solution_path)

  parse_sln(solution_path)


  local output_path
  local assembly_name

   local test = vim.fs.find(function(name, _)
    return name:match('.*%.runtimeconfig.json$')
  end, {limit = math.huge, type = 'file'})

  if #test > 0 then
    local first_find = test[1]
    output_path = utils.get_file_path(first_find)
    print("output_path: " .. output_path)

    assembly_name = utils.get_file_name(first_find)
    assembly_name = assembly_name:gsub(".runtimeconfig.json", "")
    print("Assembly Name: " .. assembly_name)
  end
  -- print(vim.inspect(test))


  -- local path = "C:\\Users\\Johan\\source\\repos\\AvaloniaApplication3\\AvaloniaApplication3.Desktop\\bin\\x64\\Release\\net7.0"
  local dllPath = output_path .. "/" .. assembly_name .. ".dll"
  -- local assemblyPath = output_path .. "/AvaloniaApplication3.dll"
  local configPath = output_path .. "/" .. assembly_name .. ".runtimeconfig.json"
  local depsPath = output_path .. "/" .. assembly_name .. ".deps.json"

  local avalonia_version = nil

  if conf.overrideHostAppPath == nil and conf.AvaloniaHostAppVersion == nil then
  -- if hostapp version or path isnt specified try getting avalonia version  from current project and find path from nuget with it.
    avalonia_version = get_avalonia_version(solution_dir)
  elseif conf.overrideHostAppPath ~= nil then
    hostPath = conf.overrideHostAppPath
  elseif conf.AvaloniaHostAppVersion ~= nil then
    avalonia_version = conf.AvaloniaHostAppVersion
  end

  if avalonia_version ~= nil then
    if is_win() then
      hostPath = "$HOME\\.nuget\\packages\\avalonia\\" .. avalonia_version .. "\\tools\\netcoreapp2.0\\designer\\Avalonia.Designer.HostApp.dll"
    else
      hostPath = "~/.nuget/packages/avalonia/" .. avalonia_version .. "/tools/netcoreapp2.0/designer/Avalonia.Designer.HostApp.dll"
    end
  end

  hostPath = vim.fn.expand(hostPath)
  print("HostPath: " .. hostPath)

  vim.defer_fn(function()
    local cmd = "dotnet exec --runtimeconfig " .. configPath .. " --depsfile " .. depsPath .. " " .. hostPath .. " --method avalonia-remote --method html --html-url " .. htmlUrl .. " --transport tcp-bson://127.0.0.1:" .. port .. " " .. dllPath
    vim.fn.jobstart(
        cmd,
        {
          cwd = base_path,
          on_stdout = function(job_id, data, event) print_debug(vim.inspect(data)) end,
          on_stderr = function(job_id, data, event) print_debug(vim.inspect(data)) end,
          -- on_exit = function() print_debug("On Exit")  end,
        }
    )
  end, 100)

  server = create_server('127.0.0.1', port, function(sock)
      sock:read_start(function(err, chunk)
        assert(not err, err)

        local sockname = uv.tcp_getsockname(sock)
        port = sockname.port

        print_debug("Running server on port: " .. port)

        if chunk then
          local typeS = string.sub(chunk, 5, 20)
          local hexS =  adjust_guid(typeS)
          local hex = string.upper(utils.hex_encode(hexS))

          if hex == messageIds.startDesignerSession then
            local pixelFormatMessage = create_message({formats ={1}}, messageIds.clientSupportedPixelFormats)
            socket:write(pixelFormatMessage)

            vim.schedule(function()
              utils.open_url(htmlUrl)
              M.update_xaml()
            end)
          end

        else
          sock:close()
        end
      end)
    end)
end

function M.update_xaml()
  local xaml = vim.fn.expand('%:p')
  local ext = utils.get_file_extension(xaml)

  if ext == nil then
    return
  end
  print_debug("xaml: " .. xaml)
  print_debug("extension: " .. ext)

  if ext == ".axaml" then
    local content = read_all(xaml)
    local message = create_message({assemblyPath = assemblyPath, xaml = content}, messageIds.updateXaml)
    print_debug("Sending message: update_xaml")
    socket:write(message)
  end
end


-- M.setup({})

return M
