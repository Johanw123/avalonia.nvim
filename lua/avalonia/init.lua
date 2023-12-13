local M = {}
-- local ffi = require'ffi'
local api = vim.api
-- local cmd = vim.cmd
local fn = vim.fn
local uv = vim.loop
local fs = vim.fs
local bson = require("avalonia.bson")
local struct = require("avalonia.struct")
local utils = require("avalonia.utils")
local config = require("avalonia.config")
local output_path
local socket

local setup_done = false

local messageIds = {
  startDesignerSession = "854887CF26944EB6B4997461B6FB96C7",
  clientRenderInfo = "7A3C25D33652438D8EF186E942CC96C0",
  clientSupportedPixelFormats = "63481025701643FEBADCF2FD0F88609E",
  updateXaml = "9AEC9A2E63154066B4BAE9A9EFD0F8CC"
}

local m_server = nil
local m_port = nil
local html_url = nil

-- local is_visible = function(bufnr)
--   for _, tabid in ipairs(api.nvim_list_tabpages()) do
--     for _, winid in ipairs(api.nvim_tabpage_list_wins(tabid)) do
--       local winbufnr = api.nvim_win_get_buf(winid)
--       local winvalid = api.nvim_win_is_valid(winid)
--
--       if winvalid and winbufnr == bufnr then
--         return true
--       end
--     end
--   end
--
--   return false
-- end

-- local buf = api.nvim_create_buf(false, true)
-- vim.api.nvim_buf_set_option(buf, 'modifiable', false)
-- vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
-- local win = nil
-- local stdout = vim.loop.new_tty(1, false)
--
-- api.nvim_create_autocmd({ "BufWinLeave" }, {
--   callback = function(au)
--     -- vim.print_debug(vim.inspect(au))
--     -- if au.buf == buf then
--     --   -- M.clear_preview() --for kitty protocol
--     -- end
--   end,
-- })

api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    -- if is_visible(buf) then
    --  -- M.generate_preivew_image() -- for kitty protocol
    -- end
  M.update_xaml()
  end,
})

api.nvim_create_autocmd({ "BufEnter" }, {
  callback = function()
    -- if is_visible(buf) then
    --  -- M.generate_preivew_image() -- for kitty protocol
    -- end
  M.update_xaml()
  end,
})

api.nvim_create_autocmd({ "ExitPre" }, {
  callback = function()
    if socket ~= nil then
      socket:close()
    end
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



local function print_debug(message)
  local conf = config.get_config()
  if conf.debug then
    print(message)
  end
end

local function str_split(delim,str)
    local t = {}

    for substr in string.gmatch(str, "[^".. delim.. "]*") do
        if substr ~= nil and string.len(substr) > 0 then
            table.insert(t,substr)
        end
    end

    return t
end

local function get_free_port()
  local tcp = uv.new_tcp()
	tcp:bind("127.0.0.1", 0)
	local free_port = tcp:getsockname().port
	tcp:shutdown()
	tcp:close()
  return free_port
end

local function create_server(host, port, on_connect)
  local new_server = uv.new_tcp()

  print_debug("Creating server: " .. host .. " - " .. port)

  new_server:bind(host, port)
  new_server:listen(128, function(err)
    assert(not err, err)
    new_server:accept(socket)
    on_connect(socket)
  end)
  return new_server
end

local function parse_sln(sln_path)

  local content = utils.read_all_text(sln_path)

  if content == nil then
    return nil
  end

  local projects = {}
  local i = 1

  for line in content:gmatch("([^\n]*)\n?") do
    local match = string.match(line, "Project%(")
    if match ~= nil then
      local split1 = str_split("=", line)
      -- print_debug(split1)
      if #split1 > 1 then
        local split2 = str_split(",", split1[2])
        -- print_debug(split2)

        if #split2 > 2 then
          local project_path = split2[2]

          projects[i] = project_path
          i = i + 1
        end
      end
    end
  end

  return projects
end

local function parse_csproj(proj_path)
  local content = utils.read_all_text(proj_path)
  if content == nil then
    return nil
  end
  for line in content:gmatch("([^\n]*)\n?") do
    local m1 = string.match(line, "PackageReference")
    local m2 = string.match(line, "Avalonia")
    local m3 = string.match(line, "Version")

    if m1 and m2 and m3 then
      local split = str_split("=", line)
      if #split > 2 then
        local verString = split[3]
        local major, minor, patch = string.match(verString, "(%d+)%.(%d+)%.(%d+)")
        if major and minor and patch then
          local version = major .. "." .. minor .. "." .. patch
          -- print_debug(s)
          return version
        end
      end
      -- print(vim.inspect(split))
    end
  end
  return nil
end

local function get_avalonia_version(solution_dir, solution_path)
  local props_file = solution_dir .. "/Directory.Build.props"
  local content = utils.read_all_text(props_file)
  local version = nil

  if content ~= nil then
    version = string.match(content, "<AvaloniaVersion>(.-)</AvaloniaVersion>")
    print_debug("AvaloniaVersion: " .. version)
    return version
  end

  local projects = parse_sln(solution_path)

  for i = 1, #projects do
    local s = projects[i]:gsub("%s+", "")
    s = s:sub(2, -2)
    print_debug("project: " .. s)
    print_debug("path: " .. solution_dir .. s)
    local parsedVersion = parse_csproj(solution_dir .. s)
    if parsedVersion ~= nil then
      version = parsedVersion
    end
  end

  return version
end

local function adjust_guid(guid)
  local sub1 = string.sub(guid, 1, 4)
  local sub2 = string.sub(guid, 5, 6)
  local sub3 = string.sub(guid, 7, 8)
  local sub4 = string.sub(guid, 9)
  return string.reverse(sub1) .. string.reverse(sub2) .. string.reverse(sub3) .. sub4
end

local function create_message(message, messageType)
  local bsonMessage = bson.encode(message)
  local dataLength = struct.pack("<I", string.len(bsonMessage))

  local typeHex = messageType
  local type = adjust_guid(utils.hex_decode(typeHex))

  local fullMessage = dataLength .. type .. bsonMessage

  return fullMessage
end

function M.setup(user_config)
  if setup_done then
    print("Setup already called")
    return
  end

  config.setup(user_config or {})
  setup_done = true
end


function M.open_preview()

  if m_server ~= nil then
    print_debug("server already running")

    if html_url == nil then
      print("Error: the html_url is nil, something is wrong")
      return
    end

    vim.schedule(function()
      utils.open_url(html_url)
      M.update_xaml()
    end)
    return
  end

  socket = uv.new_tcp()
  local conf = config.get_config()

  if conf.tcp_port == 0 then
    m_port = get_free_port()
  else
    m_port = conf.tcp_port
  end

  html_url = "http://127.0.0.1:" .. tostring(m_port + 1)
  local hostPath

  local cwd = fn.getcwd()

  -- local root_dir = vim.fs.dirname(vim.fs.find({'*.sln'}, { upward = true })[1])
  local root = fs.find(function(name, _)
    return name:match('.*%.sln$')
   end, {limit = math.huge, type = 'file', upward=true})

  print_debug("CWD: " .. cwd)
  print_debug(vim.inspect(root))

  local solution_path = root[1]
  local solution_dir = utils.get_file_path(solution_path)

  local assembly_name

  local runtimeconfig = fs.find(function(name, _)
    return name:match('.*%.runtimeconfig.json$')
  end, {limit = math.huge, type = 'file'})

  if #runtimeconfig > 0 then
    local first_find = runtimeconfig[1]
    print_debug("runtimeconf: " .. first_find)
    output_path = utils.get_file_path(first_find)
    print_debug("output_path: " .. output_path)

    assembly_name = utils.get_file_name(first_find)
    assembly_name = assembly_name:gsub(".runtimeconfig.json", "")
    print_debug("Assembly Name: " .. assembly_name)
  end

  if assembly_name == nil then
    print("Could not locate assembly, try building the project.")
    return
  end

  local dllPath = output_path .. "/" .. assembly_name .. ".dll"
  local configPath = output_path .. "/" .. assembly_name .. ".runtimeconfig.json"
  local depsPath = output_path .. "/" .. assembly_name .. ".deps.json"

  local avalonia_version = get_avalonia_version(solution_dir, solution_path)

  local nuget_path
  local host_part

  if utils.is_win() then
    nuget_path = "$HOME\\.nuget\\packages\\avalonia\\"
    host_part = "\\tools\\netcoreapp2.0\\designer\\Avalonia.Designer.HostApp.dll"
  else
    nuget_path = "~/.nuget/packages/avalonia/"
    host_part = "/tools/netcoreapp2.0/designer/Avalonia.Designer.HostApp.dll"
  end

  if avalonia_version ~= nil then
    hostPath = nuget_path .. avalonia_version .. host_part
  else
    print("Error: Could not find avalonia version")
    return
  end

  hostPath = fn.expand(hostPath)
  print_debug("HostPath: " .. hostPath)

  if not utils.file_exists(hostPath) then
    print("Error: Target avalonia version not installed: " .. avalonia_version .. " (Try building the project)")
    return
  end

  local base_path = utils.script_path() .. "../../"

  vim.defer_fn(function()
    local cmd = "dotnet exec --runtimeconfig " .. configPath .. " --depsfile " .. depsPath .. " " .. hostPath .. " --method avalonia-remote --method html --html-url " .. html_url .. " --transport tcp-bson://127.0.0.1:" .. m_port .. " " .. dllPath
    fn.jobstart(
        cmd,
        {
          cwd = base_path,
          on_stdout = function(job_id, data, event) print_debug(vim.inspect(data)) end,
          on_stderr = function(job_id, data, event) print_debug(vim.inspect(data)) end,
          -- on_exit = function() print_debug("On Exit")  end,
        }
    )
  end, 100)

  m_server = create_server('127.0.0.1', m_port, function(sock)
      sock:read_start(function(err, chunk)
        assert(not err, err)

        local sockname = uv.tcp_getsockname(sock)
        m_port = sockname.port

        print_debug("Running server on port: " .. m_port)

        if chunk then
          local typeS = string.sub(chunk, 5, 20)
          local hexS =  adjust_guid(typeS)
          local hex = string.upper(utils.hex_encode(hexS))

          if hex == messageIds.startDesignerSession then
            local pixelFormatMessage = create_message({formats ={1}}, messageIds.clientSupportedPixelFormats)
            socket:write(pixelFormatMessage)

            vim.schedule(function()
              utils.open_url(html_url)
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
  local xaml = fn.expand('%:p')
  local ext = utils.get_file_extension(xaml)

  if ext == nil then
    return
  end

  if output_path == nil then
    return
  end

  print_debug("xaml: " .. xaml)
  print_debug("extension: " .. ext)

  if ext == ".axaml" then
    local cur_path = utils.get_file_path(xaml)

    local projs = fs.find(function(name, _)
        return name:match('.*%.csproj$')
      end, {limit = math.huge, type = 'file', upward=true, path=cur_path})

    if #projs > 0 then
      local proj = projs[1]
      local proj_name = utils.get_file_name(proj)
      local assemblyPath = output_path .. proj_name:gsub(".csproj", ".dll")

      print_debug("Assembly Path: " .. assemblyPath)
      local content = utils.read_all_text(xaml)
      local message = create_message({ assemblyPath = assemblyPath, xaml = content }, messageIds.updateXaml)
      print_debug("Sending message: update_xaml")
      socket:write(message)
    end
  end
end

return M
