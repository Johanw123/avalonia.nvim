# avalonia.nvim
Avalonia preview integration for Neovim.

This plugin is experimental so expect bugs. It also expects a fairly standing file structure with a .sln file in the root.


# Usage
1. Open .axaml file
2. Call `require("avalonia").open_preview()` 
3. Edit .axaml
4. Preview will update on saving the buffer or opening a new .axaml

![avalonia nvim](https://github.com/Johanw123/avalonia.nvim/assets/5846087/0c1483c6-5344-4e12-a823-94e3cf11df24)

https://github.com/Johanw123/avalonia.nvim/assets/5846087/10d4cdfc-9387-4192-ad3a-0873149b46bc

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

# Extra
For avalonia completion on .axaml im using the LSP from vscode-avalonia extension.

```lua
  -- windows
  local avalonia_lsp_bin = "%USERPROFILE%\\.vscode\\extensions\\avaloniateam.vscode-avalonia-0.0.25\\avaloniaServer\\AvaloniaLanguageServer.dll"
  -- linux
  local avalonia_lsp_bin = "~/.vscode/extensions/avaloniateam.vscode-avalonia-0.0.25/avaloniaServer/AvaloniaLanguageServer.dll"
```

```lua   
  vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"},{ pattern = {"*.axaml"}, callback =
    function()
      vim.cmd.setfiletype("xml")
      vim.lsp.start({
        name = "Avalonia LSP",
        cmd = { "dotnet", avalonia_lsp_bin },
        root_dir = vim.fn.getcwd(),
      })
    end})
```

# References
- https://github.com/AvaloniaUI/Avalonia
- https://github.com/AvaloniaUI/Avalonia/wiki/XAML-previewer-protocol
- https://marketplace.visualstudio.com/items?itemName=AvaloniaTeam.vscode-avalonia
- https://github.com/kuiperzone/AvantGarde
