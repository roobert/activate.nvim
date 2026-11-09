# 🚀 activate.nvim

![activate.nvim demo](https://github.com/roobert/activate.nvim/assets/226654/7ae4890e-50d1-4e45-bf7e-7b39e47374ff)

`activate.nvim` is a plugin installation system for Neovim, designed to complement [folke/lazy.nvim](https://github.com/folke/lazy.nvim).

## Demos

## Features

- **Curated Plugin List**: Generated from the list of plugins at [rockerBOO/awesome-neovim](https://github.com/rockerBOO/awesome-neovim).
- **Intuitive Interface**: Allows users to easily browse, search, install, and uninstall Neovim plugins through the telescope interface.
- **Automatic Configuration**: If a plugin adheres to the unofficial configuration standard, `activate.nvim` can automatically generate a default setup. This aims to reduce the initial setup time for new plugins.
- **Automatic Plugin List Updates**: A github action periodically checks to see if there
  are any updates in the `awesome-neovim` repository and updates this plugins `data.json` file which is then sync'd down to Neovim by `lazy.nvim`, just like any other plugin.

## How It Works

### Plugin Updates

After a plugin is installed using `activate.nvim`, plugin updates are managed by `lazy.nvim` in the same way as any other plugin.

### Database Refresh

To provide the latest plugins, a Github pipeline checks the awesome-neovim repository every three hours for updates. If changes are detected, the `data/data.json` file is updated. As a result, `lazy.nvim` will recognize the changes to `activate.nvim`, ensuring that the latest plugins are always accessible.

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
-- No example configuration was found for this plugin, a default has been configured.
-- For detailed information on configuring this plugin, please refer to its
-- official documentation:
--
--   https://github.com/cbochs/grapple.nvim
--
-- If you wish to use this plugin, you can optionally modify and then uncomment
-- the configuration below.

return {
  "cbochs/grapple.nvim",
  opts = {}
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
  },
  dependencies = {
    { 'nvim-telescope/telescope.nvim', branch = '0.1.x', dependencies = { 'nvim-lua/plenary.nvim' } }
  }
}
```

## Configuration

```lua
{
  open_config_after_creation = true
}
```
