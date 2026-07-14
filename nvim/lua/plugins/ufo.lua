-- ─── nvim-ufo ─────────────────────────────────────────────────
-- Modern folding: preview on hover, virtual text with the number
-- of folded lines, treesitter provider with an indent fallback
-- (works in buffers without a TS parser, like logs or txt).
--
-- Fold options (foldlevel=99, foldenable=true, foldcolumn="1")
-- live in config/options.lua — ufo needs those defaults before
-- attaching its handlers.
--
-- Keymaps:
--   zR  opens all folds
--   zM  closes all folds
--   zr  reduces one folding level
--   zm  increases one folding level
--   K   peek of the fold under the cursor — lives in plugins/lsp.lua because
--       LspAttach's buffer-local mapping wins over any global
--       mapping we register here.

return {
  "kevinhwang91/nvim-ufo",
  dependencies = { "kevinhwang91/promise-async" },
  event = "BufReadPost",
  keys = {
    { "zR", function() require("ufo").openAllFolds()  end, desc = "Open all folds"  },
    { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
    { "zr", function() require("ufo").openFoldsExceptKinds() end, desc = "Reduce fold level" },
    { "zm", function() require("ufo").closeFoldsWith() end, desc = "Increase fold level" },
  },
  opts = {
    -- Virtual text at the end of the folded line: shows an icon +
    -- the number of lines. Replaces the classic "+--- N lines ---"
    -- with something legible and discreet.
    fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
      local newVirtText = {}
      local suffix = ("  󰁂 %d "):format(endLnum - lnum)
      local sufWidth = vim.fn.strdisplaywidth(suffix)
      local targetWidth = width - sufWidth
      local curWidth = 0
      for _, chunk in ipairs(virtText) do
        local chunkText  = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
          table.insert(newVirtText, chunk)
        else
          chunkText = truncate(chunkText, targetWidth - curWidth)
          local hlGroup = chunk[2]
          table.insert(newVirtText, { chunkText, hlGroup })
          chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if curWidth + chunkWidth < targetWidth then
            suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
          end
          break
        end
        curWidth = curWidth + chunkWidth
      end
      table.insert(newVirtText, { suffix, "MoreMsg" })
      return newVirtText
    end,
    -- Provider per filetype: treesitter first (precise, respects
    -- semantic blocks), indent as fallback (works for everything).
    provider_selector = function(_, _, _)
      return { "treesitter", "indent" }
    end,
  },
}
