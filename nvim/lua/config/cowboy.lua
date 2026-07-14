-- ─── 🤠 cowboy mode ───────────────────────────────────────────
-- If you press h/j/k/l more than 10 times in 2 seconds, it blocks
-- and shows "Hold it Cowboy!". Educational goal: it forces you to use
-- efficient motions (w, b, f<char>, /search) instead of hammering
-- arrow keys / hjkl.
--
-- Does NOT cover +/- (increment/decrement) — for those there's no
-- "motion-style" alternative; mashing `+` 10 times is legitimate use. It also
-- interfered with dial.nvim (which intercepts <C-a>/<C-x> with smart increment).
--
-- Credit: original idea from craftzdog/Takuya Matsuyama.
-- https://github.com/craftzdog/dotfiles-public

local M = {}

function M.setup()
  local ok = true
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    local count = 0
    local timer = assert(vim.uv.new_timer())
    local map = key
    vim.keymap.set("n", key, function()
      -- If you use an explicit count (e.g. `5j`), it doesn't count as spam.
      if vim.v.count > 0 then count = 0 end
      if count >= 10 and vim.bo.buftype ~= "nofile" then
        ok = pcall(vim.notify, "🤠 Hold it Cowboy!", vim.log.levels.WARN, {
          icon = "🤠",
          id = "cowboy",
          keep = function() return count >= 10 end,
        })
        if not ok then return map end
      else
        count = count + 1
        timer:start(2000, 0, function() count = 0 end)
        return map
      end
    end, { expr = true, silent = true })
  end
end

return M
