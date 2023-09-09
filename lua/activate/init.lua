local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")

local utils = require("activate.utils")

local function setup_display(items)
	local max_category_length = 0
	local max_plugin_name_length = 0
	for _, item in ipairs(items) do
		max_category_length = math.max(max_category_length, #item.category)
		max_plugin_name_length = math.max(max_plugin_name_length, #item.plugin_name)
	end

	max_category_length = max_category_length + 1
	max_plugin_name_length = max_plugin_name_length + 1

	return entry_display.create({
		separator = " ",
		items = {
			{ width = max_category_length },
			{ width = 3 },
			{ width = max_plugin_name_length },
			{ remaining = true },
		},
	})
end

local function create_picker(title, prompt, items, mappings_func)
	local displayer = setup_display(items)

	local function make_display(entry)
		return displayer({
			entry.category,
			entry.status,
			entry.plugin_name,
			entry.owner,
		})
	end

	-- Attempt to scope wrap to preview window..
	vim.api.nvim_create_autocmd("User", {
		pattern = "TelescopePreviewerLoaded",
		callback = function()
			local bufnr = vim.api.nvim_get_current_buf()
			local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
			if lines[1] and lines[1]:sub(1, 1) == "#" then
				vim.wo.wrap = true
			end
		end,
	})

	-- FIXME:
	-- * show preview in vertical layout if window is narrow
	-- local width = vim.api.nvim_win_get_width(0) -- Get the width of the current window
	-- local layout_strategy = "horizontal"
	-- local layout_config = {}
	--
	-- if width < 100 then -- Adjust this threshold as needed
	-- 	layout_strategy = "vertical"
	-- 	layout_config = {
	-- 		mirror = true, -- Mirror the preview to the right side
	-- 	}
	-- end

	local plugin_picker = pickers.new({
		-- layout_strategy = layout_strategy,
		-- layout_config = layout_config,
	}, {
		results_title = title,
		prompt_title = prompt,
		finder = finders.new_table({
			results = items,
			entry_maker = function(entry)
				entry.status = utils.get_plugin_status(entry.plugin_name, entry.config)
				entry.display = make_display
				return entry
			end,
		}),
		sorter = conf.generic_sorter({}),
		previewer = previewers.new_buffer_previewer({
			define_preview = function(self, entry, _)
				if not entry then
					return
				end
				local bufnr = self.state.bufnr
				vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
				local contents = {
					"# " .. entry.category .. " - " .. entry.owner .. "/" .. entry.plugin_name,
					"",
					"## Status",
					"",
					utils.get_status_description(entry.status),
					"",
					"## Description",
					"",
					entry.description,
					"",
					"## URL",
					"",
					entry.url,
				}
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
			end,
		}),
		attach_mappings = mappings_func,
	})

	plugin_picker:find()
end

M.list_plugins = function()
	local items = utils.get_all_plugins()
	create_picker(
		"[(1) All Plugins] - Category | Status | Plugin | Author",
		"<CR> = Install plugin and/or edit the config, [?] = for help",
		items,
		utils.all_plugins_mappings
	)
end

M.list_installed_plugins = function()
	local items = utils.get_installed_plugins()
	create_picker(
		"[(2) Installed Plugins] - Category | Status | Plugin | Author",
		"<CR> = Edit the config, [?] = for help",
		items,
		utils.installed_plugins_mappings
	)
end

M.list_installed_and_configured_plugins = function()
	local items = utils.get_installed_and_configured_plugins()
	create_picker(
		"[(3) Installed and Configured Plugins] - Category | Status | Plugin | Author",
		"<CR> = Edit the config, [?] = for help",
		items,
		utils.installed_plugins_mappings
	)
end

return M
