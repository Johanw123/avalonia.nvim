# avalonia.nvim
Avalonia preview integration for Neovim.

This plugin is experimental so expect bugs. It also expects a fairly standing file structure with a .sln file in the root.


# Usage
1. Open .axaml file
2. Call `require("avalonia").open_preview()` 
3. Edit .axaml
4. Preview will update on saving the buffer or opening a new .axaml
   
![image](https://github.com/Johanw123/avalonia.nvim/assets/5846087/2e7e066d-9056-4d97-bd41-33e7b9c7e0fb)

### Lazy.nvim
```lua
  {
    "Johanw123/avalonia.nvim",
  }
```

### Default Settings
```lua
  require("avalonia.nvim").setup {
    openUrlCommand = nil,  -- start/open/xdg-open
    forced_browser = nil,    -- firefox/chrome/msedge etc
    displayMethod = "html", -- html/kitty(not implemented yet)
    tcp_port = 0, -- port for connecting to avalonia preview rendering process, leave as 0 to let OS decide
    debug = false,
}
```
# Future plans
- kitty grahpics protocol support

# References
- https://github.com/AvaloniaUI/Avalonia
- https://github.com/AvaloniaUI/Avalonia/wiki/XAML-previewer-protocol
- https://marketplace.visualstudio.com/items?itemName=AvaloniaTeam.vscode-avalonia
- https://github.com/kuiperzone/AvantGarde
