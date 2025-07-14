---@module "activate.types"
local M = {}

local api = vim.api

local CONFIG_PATH = vim.fn.stdpath("config")
local DATA_PATH = vim.fn.stdpath("data")
local PLUGIN_PATH = string.format("%s/lazy", DATA_PATH)

local function display_popup(content)
	if type(content) == "string" then
		content = content:gsub("^      ", ""):gsub("\n      +", "\n")
		content = vim.split(content, "\n")
	end

	local bufnr = api.nvim_create_buf(false, true)
	api.nvim_buf_set_lines(bufnr, 0, -1, false, content)

	local width = vim.o.columns
	local height = vim.o.lines

	local win_height = math.min(#content + 2, height - 4)
	local row = math.floor((height - win_height) / 2)

	local win_width = math.min(80, width - 4)
	local col = math.floor((width - win_width) / 2)

	local win_opts = {
		relative = "editor",
		row = row,
		col = col,
		width = win_width,
		height = win_height,
		style = "minimal",
		border = "single",
	}

	api.nvim_open_win(bufnr, true, win_opts)

	local exit_command = "<CMD>close<CR>|<CMD>lua require('activate').list_plugins()<CR>"
	api.nvim_buf_set_keymap(bufnr, "n", "q", exit_command, { noremap = true, silent = true })
	api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", exit_command, { noremap = true, silent = true })
end

M.get_plugin_status = function(plugin_name, config)
	local plugin_path = string.format("%s/lazy/%s", DATA_PATH, plugin_name)
	local config_path = string.format("%s/lua/plugins/%s", CONFIG_PATH, config)

	local plugin_exists = vim.fn.isdirectory(plugin_path) == 1
	local config_exists = vim.fn.filereadable(config_path) == 1

	if plugin_exists and config_exists then
		return "IC"
	elseif plugin_exists then
		return "I-"
	elseif config_exists then
		return "-C"
	else
		return "--"
	end
end

M.get_status_description = function(status)
	local description_map = {
		["IC"] = "Both plugin and configuration exist.",
		["I-"] = "Only the plugin exists, perhaps this is a core plugin, or the config was removed.",
		["-C"] = "Only the configuration exists.",
		["--"] = "Neither plugin nor configuration exist.",
	}

	return description_map[status] or "Unknown status."
end

M.detect_example_config = function(plugin_dir)
	local setup_example_path = plugin_dir .. "/setup.lua.example"
	local f = io.open(setup_example_path, "r")
	if f then
		local content = f:read("*all")
		f:close()
		return content
	end
	return nil
end

M.parse_json = function(str)
	local ok, result = pcall(vim.fn.json_decode, str)
	if ok then
		return result
	else
		return nil, result
	end
end

M.load_json_from_file = function()
	local plugin_file = debug.getinfo(1, "S").source:sub(2)
	local plugin_dir = vim.fn.fnamemodify(plugin_file, ":h")
	local filepath = plugin_dir .. "/../../data/data.json"

	local f = io.open(filepath, "r")
	if f then
		local content = f:read("*all")
		f:close()
		return M.parse_json(content)
	end
	return nil, "Could not open file"
end

M.edit_plugin_file = function(plugin_name, config)
	local file_path = string.format("%s/lua/plugins/%s", CONFIG_PATH, config)

	local f = io.open(file_path, "r")
	if f then
		f:close()
		vim.cmd("silent! e " .. file_path)
	else
		print(string.format("Error: Config file for plugin '%s' does not exist. Please try reinstalling!", plugin_name))
	end
end

M.create_plugin_file = function(plugin_name, repo, _config, edit)
	local plugin_dir = string.format("%s/lazy/%s", DATA_PATH, plugin_name)
	local file_path = string.format("%s/lua/plugins/%s", CONFIG_PATH, _config)

	local f = io.open(file_path, "r")
	if f then
		f:close()
		print("Plugin configuration file already exists.")
	else
		f = io.open(file_path, "w")
		if f then
			local config = M.detect_example_config(plugin_dir)
			if config then
				f:write(config)
			else
				local disclaimer = [[
        -- No example configuration was found for this plugin.
        -- So a default has been configured.
        -- For detailed information on configuring this plugin, please refer to its
        -- official documentation:
        --
        --   https://github.com/]] .. repo .. [[

        --
        -- If you wish to use this plugin, you can optionally modify and then uncomment
        -- the configuration below.

        ]]
				disclaimer = disclaimer:gsub("^%s+", ""):gsub("\n%s+", "\n")
				f:write(disclaimer)
				f:write("\n")
				f:write("return {\n")
				f:write(string.format('  "%s",\n', repo))
				f:write('  opts = {}\n')
				f:write("}")
			end
			f:close()
		else
			print("Error: Could not create plugin configuration file.")
			return
		end
	end
	if edit then
		vim.cmd("silent! e " .. file_path)
	end
end

M._install_plugin = function(entry)
	local cmd =
		string.format("git clone --depth 1 %s %s/lazy/%s", entry.url, DATA_PATH, entry.plugin_name)
	vim.cmd("!" .. cmd)
end

M._uninstall_plugin = function(entry)
	local confirm = vim.fn.input("Are you sure you want to delete the plugin and its configuration? [y/N]: ")

	-- Clear the prompt
	vim.cmd('echo ""')

	if confirm:lower() == "y" then
		local plugin_path = string.format("%s/lazy/%s", DATA_PATH, entry.plugin_name)
		local config_path = string.format("%s/lua/plugins/%s", CONFIG_PATH, entry.config)
		local plugin_deleted = false
		local config_deleted = false

		if vim.fn.isdirectory(plugin_path) == 1 and os.execute("rm -rf " .. vim.fn.shellescape(plugin_path)) == 0 then
			plugin_deleted = true
		end

		if os.remove(config_path) then
			config_deleted = true
		end

		-- Consolidate feedback message
		local feedback_msg = "Result: "
		if plugin_deleted and config_deleted then
			feedback_msg = feedback_msg .. "Plugin and configuration successfully deleted for " .. entry.plugin_name
		elseif plugin_deleted then
			feedback_msg = feedback_msg .. "Plugin deleted but configuration not found for " .. entry.plugin_name
		elseif config_deleted then
			feedback_msg = feedback_msg .. "Configuration deleted but plugin not found for " .. entry.plugin_name
		else
			feedback_msg = feedback_msg .. "Error: Plugin and/or configuration not found for " .. entry.plugin_name
		end
		print(feedback_msg)
	else
		print("Uninstallation aborted.")
	end
end

M.get_all_plugins = function()
	local data, err = M.load_json_from_file()
	if not data then
		print("Error loading JSON:", err)
		return {}
	end

	local items = {}
	for category, plugins in pairs(data) do
		for _, plugin in ipairs(plugins) do
			local list_entry = "" .. category .. " - " .. plugin.name .. " - " .. plugin.owner
			table.insert(items, {
				plugin_name = plugin.name,
				url = plugin.url,
				config = plugin.config,
				plugin.name,
				description = plugin.description,
				category = category,
				owner = plugin.owner,
				value = plugin,
				ordinal = list_entry,
			})
		end
	end
	return items
end

M.get_installed_plugins = function()
	local function get_directories(path)
		local command = "ls -d " .. path .. "/*/ | xargs -n 1 basename"
		local handle = io.popen(command)
		local result = handle:read("*a")
		handle:close()
		return vim.split(result, "\n")
	end

	local installed_plugins = get_directories(PLUGIN_PATH)
	local all_plugins = M.get_all_plugins()

	local items = {}
	for _, plugin in ipairs(all_plugins) do
		if vim.tbl_contains(installed_plugins, plugin.plugin_name) then
			table.insert(items, plugin)
		end
	end
	return items
end

M.get_installed_and_configured_plugins = function()
	local function get_directories(path)
		local command = "ls -d " .. path .. "/*/ | xargs -n 1 basename"
		local handle = io.popen(command)
		local result = handle:read("*a")
		handle:close()
		return vim.split(result, "\n")
	end

	local installed_plugins = get_directories(PLUGIN_PATH)
	local all_plugins = M.get_all_plugins()

	local items = {}
	for _, plugin in ipairs(all_plugins) do
		if vim.tbl_contains(installed_plugins, plugin.plugin_name) then
			local config_path = string.format("%s/lua/plugins/%s", CONFIG_PATH, plugin.config)
			local config_exists = vim.fn.filereadable(config_path) == 1
			if config_exists then
				table.insert(items, plugin)
			end
		end
	end
	return items
end

local function filter_by_all_plugins()
	vim.cmd('lua require("activate").list_plugins()')
end
local function filter_by_installed_plugins()
	vim.cmd('lua require("activate").list_installed_plugins()')
end
local function filter_by_installed_and_configured_plugins()
	vim.cmd('lua require("activate").list_installed_and_configured_plugins()')
end

M.current_view = "all"

M.cycle_views = function()
	if M.current_view == "all" then
		M.current_view = "installed"
		filter_by_installed_plugins()
	elseif M.current_view == "installed" then
		M.current_view = "configured"
		filter_by_installed_and_configured_plugins()
	else
		M.current_view = "all"
		filter_by_all_plugins()
	end
end

local function help()
	local content = [[
      # activate.nvim

      ## Keybindings

        <CR>  = Install plugin and/or edit the config

        1     = All Plugins view
        2     = Installed Plugins view
        3     = Installed and Configured Plugins view
        <Tab> = Cycle views

        [I]   = Install plugin, don't open config
        [U]   = Uninstall plugin and config
        [h]   = Help

        <esc> = exit
    ]]
	display_popup(content)
end

M.all_plugins_mappings = function(prompt_bufnr, map)
	---@class Activate.Config
	local user_conf = require("activate.config").config
	local action_state = require("telescope.actions.state")

	local function install_and_or_configure_plugin()
		local entry = action_state.get_selected_entry()
		vim.api.nvim_buf_delete(prompt_bufnr, { force = true })
		M._install_plugin(entry)
		local repo_path = entry.url:gsub("https://github.com/", "")
		local edit = user_conf.open_config_after_creation
		M.create_plugin_file(entry.plugin_name, repo_path, entry.config, edit)
	end

	map("i", "<CR>", install_and_or_configure_plugin)
	map("n", "<CR>", install_and_or_configure_plugin)

	local function uninstall_plugin()
		local entry = action_state.get_selected_entry()
		M._uninstall_plugin(entry)
	end

	map("i", "U", uninstall_plugin)
	map("n", "U", uninstall_plugin)

	local function install_plugin()
		local entry = action_state.get_selected_entry()
		vim.api.nvim_buf_delete(prompt_bufnr, { force = true })
		M._install_plugin(entry)
		local repo_path = entry.url:gsub("https://github.com/", "")
		local edit = false
		M.create_plugin_file(entry.plugin_name, repo_path, entry.config, edit)
	end

	map("i", "I", install_plugin)
	map("n", "I", install_plugin)

	map("n", "<Tab>", M.cycle_views)
	map("i", "<Tab>", M.cycle_views)

	map("n", "1", filter_by_all_plugins)
	map("n", "2", filter_by_installed_plugins)
	map("n", "3", filter_by_installed_and_configured_plugins)

	map("n", "h", help)

	return true
end

M.installed_plugins_mappings = function(_, map)
	local action_state = require("telescope.actions.state")

	local function edit_config()
		local entry = action_state.get_selected_entry()
		M.edit_plugin_file(entry.plugin_name, entry.config)
	end

	map("i", "<CR>", edit_config)
	map("n", "<CR>", edit_config)

	local function uninstall_plugin()
		local entry = action_state.get_selected_entry()
		M._uninstall_plugin(entry)
	end

	map("i", "U", uninstall_plugin)
	map("n", "U", uninstall_plugin)

	map("n", "<Tab>", M.cycle_views)
	map("i", "<Tab>", M.cycle_views)

	map("n", "1", filter_by_all_plugins)
	map("n", "2", filter_by_installed_plugins)
	map("n", "3", filter_by_installed_and_configured_plugins)

	map("n", "h", help)

	return true
end

M.installed_and_configured_plugins_mappings = function(_, map)
	local action_state = require("telescope.actions.state")

	local function edit_config()
		local entry = action_state.get_selected_entry()
		M.edit_plugin_file(entry.plugin_name, entry.config)
	end

	map("i", "<CR>", edit_config)
	map("n", "<CR>", edit_config)

	local function uninstall_plugin()
		local entry = action_state.get_selected_entry()
		M._uninstall_plugin(entry)
	end

	map("i", "U", uninstall_plugin)
	map("n", "U", uninstall_plugin)

	map("n", "<Tab>", M.cycle_views)
	map("i", "<Tab>", M.cycle_views)

	map("n", "1", filter_by_all_plugins)
	map("n", "2", filter_by_installed_plugins)
	map("n", "3", filter_by_installed_and_configured_plugins)

	map("n", "h", help)

	return true
end

return M
