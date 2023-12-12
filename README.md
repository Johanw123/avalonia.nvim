# avalonia.nvim
Avalonia preview integration for Neovim

Lazy.nvim
```
  {
    "Johanw123/avalonia.nvim",
  }
```

Default Settings
```
  require("avalonia.nvim").setup {
    openUrlCommand = nil,  -- start/open/xdg-open
    forced_browser = nil,    -- firefox/chrome/msedge etc
    displayMethod = "html", -- html/kitty(not implemented yet)
    tcp_port = 0, -- port for connecting to avalonia preview rendering process, leave as 0 to let OS decide
    debug = false,
}
```


