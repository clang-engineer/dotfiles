return {
  "folke/snacks.nvim",
  dependencies = { "christoomey/vim-tmux-navigator" },
  init = function()
    require("cmdtreemap").setup()
  end,
  keys = {
    {
      "<leader>ft",
      function()
        Snacks.picker("cmdtreemap", { auto_close = false })
      end,
      desc = "Cmd TreeMap",
    },
  },
}
