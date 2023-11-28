local M = {}
local config = {}

M.defaults =
{
  openUrlCommand = nil,  -- start/open/xdg-open
  forced_browser = nil,    -- firefox/chrome/msedge etc
  displayMethod = "html" -- html/kitty
}

function M.get_config()
  return config or M.defaults
end

function M.setup(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend("force", M.defaults, user_config)

  return config
end

return M
