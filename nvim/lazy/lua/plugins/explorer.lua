return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          -- Default is hidden (hidden/ignored off). Keep the H/I toggle state
          -- across closing and reopening the explorer for the session.
          -- snacks saves the last toggle value to resume state on close,
          -- so we re-inject it on open. (resets on nvim restart)
          config = function(opts)
            local last = require("snacks.picker.resume").state.explorer
            if last and last.opts then
              opts.hidden = last.opts.hidden
              opts.ignored = last.opts.ignored
            end
            return require("snacks.picker.source.explorer").setup(opts)
          end,
        },
      },
    },
  },
}
