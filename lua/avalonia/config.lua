local M = {}
local config = {}

M.defaults =
{
  openUrlCommand = nil,  -- start/open/xdg-open
  forced_browser = nil,    -- firefox/chrome/msedge etc
  displayMethod = "html", -- html/kitty(not implemented yet)
  tcp_port = 0, -- port for connecting to avalonia preview rendering process, leave as 0 to let OS decide
  debug = false,
}

function M.get_config()
  if not next(config) then
    return M.defaults
  end

  return config
end

function M.setup(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend("force", M.defaults, user_config)

  return config
end

return M
