-- Eigene Tastenbelegungen
local map = vim.keymap.set

-- Einrücken im visuellen Modus, Auswahl bleibt erhalten
map("v", ">", ">gv", { desc = "Indent right and keep selection" })
map("v", "<", "<gv", { desc = "Indent left and keep selection" })
