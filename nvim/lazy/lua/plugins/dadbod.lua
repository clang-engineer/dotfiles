-- dadbod-ui settings. The plugin itself is provided by lazyvim.plugins.extras.lang.sql.
-- Here we only add the connection list (vim.g.dbs) and result-window readability.
return {
  {
    "kristijanhusak/vim-dadbod-ui",
    init = function()
      require("user.vim-dadbod-ui-profiles").setup({
          picker_layout = "dropdown",
          prefix_by_profile = true,
          icon_style = "emoji",
        })

      -- Improve query result window (dbout) readability:
      --   1) Disable folds (maintainer's official recommendation: PR #203 comment)
      --   2) Resize to fit content line count, capped at half the screen (small results stay narrow, large ones cut at half)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "dbout",
        callback = function()
          vim.opt_local.foldenable = false
          local lines = vim.api.nvim_buf_line_count(0)
          local cap = math.floor(vim.o.lines / 2)
          local height = math.max(8, math.min(lines + 1, cap))
          vim.cmd("resize " .. height)
        end,
      })
    end,
  },
}
