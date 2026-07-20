-- plugins for previewing and authoring markdown
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- global off (noisy while editing); user.util.float enables it buf-scoped for the
    -- read-only :Docs viewer. these styles only show there. merged on top of LazyVim's
    -- markdown extra (sign=false, code width=block) and cyberdream's render-markdown
    -- extension (per-level H1..H6 colors) — so we only add what those don't: a code
    -- border, block-width headings (makes cyberdream's per-level bg show as tidy
    -- blocks), rounded tables, and the heading icons LazyVim blanked out (icons = {}).
    opts = {
      enabled = false,
      heading = {
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        width = "block",
        left_pad = 1,
        right_pad = 2,
      },
      code = { width = "block", border = "thick", left_pad = 2, right_pad = 2 },
      pipe_table = { preset = "round" },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    config = function()
      vim.g.mkdp_auto_close = 0
    end,
  },
  -- highlight ```mermaid``` fenced blocks (injected into markdown)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "mermaid" } },
  },
}
