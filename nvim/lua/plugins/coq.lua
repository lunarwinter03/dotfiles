return {
  {
    "neovim/nvim-lspconfig",
    lazy = false, -- WICHTIG: coq muss direkt beim Start geladen werden
    dependencies = {
      { "ms-jpq/coq_nvim", branch = "coq" },
      { "ms-jpq/coq.artifacts", branch = "artifacts" },
      { "ms-jpq/coq.thirdparty", branch = "3p" },
    },
    init = function()
      -- Globale Einstellungen müssen vor dem Laden des Plugins gesetzt werden
      vim.g.coq_settings = {
        
      }
    end,
    config = function()
      -- Initialisiert coq ohne manuelle Capabilites-Injektion
      require("coq")

      -- Registrieren Sie Ihre Sprachserver direkt über die neue native API
      vim.lsp.config("pyright", {
        -- Hier können server-spezifische Einstellungen rein (z.B. settings = ...)
      })
      vim.lsp.config("ts_ls", {})
      vim.lsp.config("lua_ls", {})

      -- Aktiviert die Sprachserver nativ
      vim.lsp.enable({ "pyright", "ts_ls", "lua_ls" })
    end,
  }
}
