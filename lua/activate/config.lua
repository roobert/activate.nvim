local M = {}

---@class Activate.Config
M.config = {}

---@class Activate.Config
local defaults = {
  open_config_after_creation = true,
}

M.setup = function(user_config)
  M.config = vim.tbl_deep_extend("force", defaults, user_config or {})
end

return M
