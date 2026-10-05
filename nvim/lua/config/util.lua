-- ─── shared helpers ───────────────────────────────────────────
-- Small functions more than one plugin spec needs. Not required from
-- init.lua: each spec requires it where it uses it.

local M = {}

-- A highlight group's colour as "#rrggbb", resolving links, or nil when the
-- active colorscheme leaves that attribute unset (e.g. `Normal` bg under a
-- transparent theme), so callers can chain `or` fallbacks.
function M.hl_hex(group, attr)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  return hl[attr] and string.format("#%06x", hl[attr]) or nil
end

return M
