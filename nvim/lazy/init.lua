-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- docs viewer/search over knowledge roots (:Docs / :DocsGrep)
require("user.docs").setup({
  roots = {
    { name = "vault", dir = "$VAULT_DIR" },
    { name = "devkit", dir = "$DEVKIT_DIR" },
    { name = "blog", dir = "$BLOG_DIR", grep_only = true },
    { name = "analysis", dir = "$VAULT_DIR/analysis", scoped = true, subdirs = true },
    -- { name = "notes", dir = "$VAULT_DIR/notes", scoped = true },
    -- { name = "wiki", dir = "~/personal-wiki" },
  },
})
