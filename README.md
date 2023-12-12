# avalonia.nvim
Avalonia preview integration for Neovim.
This plugin is experimental so expect bugs. It also expects a fairly standing file structure with a .sln file in the root.

Lazy.nvim
```lua
  {
    "Johanw123/avalonia.nvim",
  }
```

Default Settings
```lua
  require("avalonia.nvim").setup {
    openUrlCommand = nil,  -- start/open/xdg-open
    forced_browser = nil,    -- firefox/chrome/msedge etc
    displayMethod = "html", -- html/kitty(not implemented yet)
    tcp_port = 0, -- port for connecting to avalonia preview rendering process, leave as 0 to let OS decide
    debug = false,
}
```


