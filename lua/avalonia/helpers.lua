-- local utils = require("image/utils")
local codes = require("image/backends/kitty/codes")
local buffer = nil
local stdout = vim.loop.new_tty(1, false)
if not stdout then error("failed to open stdout") end

-- https://github.com/edluffy/hologram.nvim/blob/main/lua/hologram/terminal.lua#L77
local get_chunked = function(str)
  local chunks = {}
  for i = 1, #str, 4096 do
    local chunk = str:sub(i, i + 4096 - 1):gsub("%s", "")
    if #chunk > 0 then table.insert(chunks, chunk) end
  end
  return chunks
end


local ffi = require("ffi")

local b64 = ffi.new("unsigned const char[65]", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-")

function encode(str)
  ---@diagnostic disable-next-line: undefined-global
  local band, bor, lsh, rsh = bit.band, bit.bor, bit.lshift, bit.rshift
  local len = #str
  local enc_len = 4 * math.ceil(len / 3) -- (len + 2) // 3 * 4 after Lua 5.3

  local src = ffi.new("unsigned const char[?]", len + 1, str)
  local enc = ffi.new("unsigned char[?]", enc_len + 1)

  local i, j = 0, 0
  while i < len - 2 do
    enc[j] = b64[band(rsh(src[i], 2), 0x3F)]
    enc[j + 1] = b64[bor(lsh(band(src[i], 0x3), 4), rsh(band(src[i + 1], 0xF0), 4))]
    enc[j + 2] = b64[bor(lsh(band(src[i + 1], 0xF), 2), rsh(band(src[i + 2], 0xC0), 6))]
    enc[j + 3] = b64[band(src[i + 2], 0x3F)]
    i, j = i + 3, j + 4
  end

  if i < len then
    enc[j] = b64[band(rsh(src[i], 2), 0x3F)]
    if i == len - 1 then
      enc[j + 1] = b64[lsh(band(src[i], 0x3), 4)]
      enc[j + 2] = 0x3D
    else
      enc[j + 1] = b64[bor(lsh(band(src[i], 0x3), 4), rsh(band(src[i + 1], 0xF0), 4))]
      enc[j + 2] = b64[lsh(band(src[i + 1], 0xF), 2)]
    end
    enc[j + 3] = 0x3D
  end

  return ffi.string(enc, enc_len)
end



---@param data string
---@param tty? string
---@param escape? boolean
local write = function(data, tty)
  vim.print("write start")
  if data == "" then return end

  local payload = data
  -- if escape and utils.tmux.is_tmux then payload = utils.tmux.escape(data) end
  -- utils.debug("write:", vim.inspect(payload), tty)
  if tty then
    local handle = io.open(tty, "w")
    if not handle then error("failed to open tty") end
    handle:write(payload)
    handle:close()
  else
    -- vim.fn.chansend(vim.v.stderr, payload)
    stdout:write(payload)

    -- vim.print("buffer: " .. buffer)
    -- vim.api.nvim_buf_set_lines(16, -1, -1, true, {data})
  end
end

local move_cursor = function(x, y, save)
  -- if utils.tmux.is_tmux then
  --   -- When tmux is running over ssh, set-cursor sometimes doesn't actually get sent
  --   -- I don't know why this fixes the issue...
  --   local cx = utils.tmux.get_cursor_x()
  --   local cy = utils.tmux.get_cursor_y()
  -- end
  if save then write("\x1b[s") end
  write("\x1b[" .. y .. ";" .. x .. "H")
  vim.loop.sleep(1)
end

local restore_cursor = function()
  write("\x1b[u")
end

local update_sync_start = function()
  write("\x1b[?2026h")
end

local update_sync_end = function()
  write("\x1b[?2026l")
end

---@param config KittyControlConfig
---@param data? string
-- https://github.com/edluffy/hologram.nvim/blob/main/lua/hologram/terminal.lua#L52
--https://stackoverflow.com/questions/75141843/create-a-temporary-readonly-buffer-for-test-output
--
local write_graphics = function(config, data)
  local control_payload = ""

  -- utils.debug("kitty.write_graphics()", config, data)
  for k, v in pairs(config) do
    if v ~= nil then
      local key = codes.control.keys[k]
      if key then control_payload = control_payload .. key .. "=" .. v .. "," end
    end
  end
  control_payload = control_payload:sub(0, -2)
  if data then
    if config.transmit_medium == codes.control.transmit_medium.direct then
      local file = io.open(data,"rb")
      data = file:read("*all")
    end
    data = encode(data):gsub("%-","/")
    data = data:gsub("%-", "/")
    local chunks = get_chunked(data)
    local m = #chunks > 1 and 1 or 0
    control_payload = control_payload .. ",m=" .. m
    for i = 1, #chunks do
      write("\x1b_G" .. control_payload .. ";" .. chunks[i] .. "\x1b\\", nil, true)
      if i == #chunks - 1 then
        control_payload = "m=0"
      else
        control_payload = "m=1"
      end
    end
  else
    -- utils.debug("kitty control payload:", control_payload)
    write("\x1b_G" .. control_payload .. "\x1b\\", nil, true)
  end
end

local write_placeholder = function(image_id, x, y, width, height)
  local foreground = "\x1b[38;5;" .. image_id .. "m"
  local restore = "\x1b[39m"

  write(foreground)
  for i = 0, height - 1 do
    move_cursor(x, y + i + 1)
    for j = 0, width - 1 do
      write(codes.placeholder .. codes.diacritics[i + 1] .. codes.diacritics[j + 1])
    end
  end
  write(restore)
end

return {
  buffer = buffer,
  move_cursor = move_cursor,
  restore_cursor = restore_cursor,
  write = write,
  write_graphics = write_graphics,
  write_placeholder = write_placeholder,
  update_sync_start = update_sync_start,
  update_sync_end = update_sync_end,
}