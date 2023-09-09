# 🚀 activate.nvim

![activate.nvim demo](https://github.com/roobert/activate.nvim/assets/226654/6c9c6f77-7375-4e83-8a41-8784c47f3ade)

`activate.nvim` is a plugin installation system for Neovim, designed to complement [folke/lazy.nvim](https://github.com/folke/lazy.nvim).

## Features

- **Curated Plugin List**: Utilizes a curated list of plugins from the [rockerBOO/awesome-neovim](https://github.com/rockerBOO/awesome-neovim) repository.
- **Intuitive Interface**: Allows users to easily browse, search, install, and uninstall Neovim plugins through the telescope interface.
- **Automated Configuration**: If a plugin adheres to the unofficial configuration standard, `activate.nvim` can automatically generate a default setup. This aims to reduce the initial setup time for new plugins.

## How It Works

### Plugin Updates

After a plugin is installed using activate.nvim, its updates are managed by `lazy.nvim`. This ensures plugins are kept up-to-date.

### Database Refresh

To provide the latest plugins, a Github pipeline checks the awesome-neovim repository every three hours for updates. If changes are detected, the `data/data.json` file is updated. As a result, `lazy.nvim` will recognize the changes to activate.nvim, ensuring that the latest plugins are always accessible.

### Unofficial Standard: `setup.lua.example`

Plugin authors can support `activate.nvim` by adhering to an unofficial standard. This involves creating a file named `setup.lua.example` in their plugin repository. The file should return a `lazy.nvim` compatible configuration in the `$HOME/.config/nvim/lua/plugins` directory, as demonstrated below:

```lua
return {
  "roobert/tabtree.nvim",
  config = function()
    require("tabtree").setup()
  end,
}
```

### Non-Standard Plugins

When plugins don't conform to the unofficial standard outlined above, then a placeholder config is generated, for example, `$HOME/.config/nvim/lua/plugins/grapple.lua`:

```lua
-- No example configuration was found for this plugin.
--
-- For detailed information on configuring this plugin, please refer to its
-- official documentation:
--
--   https://github.com/cbochs/grapple.nvim
--
-- If you wish to use this plugin, you can optionally modify and then uncomment
-- the configuration below.

return {
  -- "cbochs/grapple.nvim"
}
```

## Installation

For `lazy.nvim`, add this config to `~/.config/nvim/lua/plugins/activate.lua`:

```lua
return {
  "roobert/activate.nvim",
  keys = {
    {
      "<leader>P",
      '<CMD>lua require("activate").list_plugins()<CR>',
      desc = "Plugins",
    },
  }
}
```
