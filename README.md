# avalonia.nvim
Avalonia preview integration for Neovim

nuget install avalonia -version 11.0.5

```
M.defaults =
{
  overrideHostAppPath = nil, -- specify path to Avalonia.Designer.HostApp.dll (~/.nuget/packages/ )
  AvaloniaHostAppVersion = nil, -- Or specify an avalonia version and search the nuget default directory for the HostApp dll
  openUrlCommand = nil,  -- start/open/xdg-open
  forced_browser = nil,    -- firefox/chrome/msedge etc
  displayMethod = "html", -- html/kitty
  tcp_port = 0, -- port for connecting to avalonia preview rendering process, leave as 0 to let OS decide
  debug = true,
}
```
