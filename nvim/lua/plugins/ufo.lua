-- ─── nvim-ufo ─────────────────────────────────────────────────
-- Folding moderno: preview en hover, virtual text con cantidad
-- de líneas plegadas, provider treesitter con fallback a indent
-- (sirve en buffers sin parser TS, tipo logs o txt).
--
-- Opciones de fold (foldlevel=99, foldenable=true, foldcolumn="1")
-- viven en config/options.lua — ufo necesita esos defaults antes
-- de attachear sus handlers.
--
-- Keymaps:
--   zR  abre todos los folds
--   zM  cierra todos los folds
--   zr  reduce un nivel de folding
--   zm  aumenta un nivel de folding
--   K   peek del fold bajo el cursor — vive en plugins/lsp.lua porque
--       el mapeo buffer-local del LspAttach gana sobre cualquier
--       mapeo global que registremos acá.

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
    -- Virtual text al final de la línea plegada: muestra ícono +
    -- cantidad de líneas. Reemplaza el clásico "+--- N lines ---"
    -- por algo legible y discreto.
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
    -- Provider por filetype: treesitter primero (preciso, respeta
    -- bloques semánticos), indent como fallback (sirve para todo).
    provider_selector = function(_, _, _)
      return { "treesitter", "indent" }
    end,
  },
}
