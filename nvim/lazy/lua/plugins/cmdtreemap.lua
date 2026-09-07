local f = "user.cmdtreemap.finder"

return {
  "folke/snacks.nvim",
  init = function()
    vim.api.nvim_create_user_command("CmdTreeMap", function()
      Snacks.picker("cmdtreemap")
    end, { desc = "CLI command evolution tree" })
  end,
  keys = {
    {
      "<leader>ft",
      function()
        Snacks.picker("cmdtreemap")
      end,
      desc = "Cmd TreeMap",
    },
  },
  opts = {
    picker = {
      sources = {
        cmdtreemap = {
          layout = { preset = "sidebar" },
          focus = "list",
          finder = function(opts, ctx)
            return require(f).finder(opts, ctx)
          end,
          format = function(item, picker)
            return require(f).format(item, picker)
          end,
          actions = {
            confirm = function(picker)
              return require(f).expand(picker)
            end,
            expand = function(picker)
              return require(f).expand(picker)
            end,
            collapse = function(picker)
              return require(f).collapse(picker)
            end,
            expand_all = function(picker)
              require(f).expand_all()
              picker.list:set_target()
              return picker:find()
            end,
            collapse_all = function(picker)
              require(f).collapse_all()
              picker.list:set_target()
              return picker:find()
            end,
            copy_url = function(picker)
              return require(f).copy_url(picker)
            end,
            copy_install = function(picker)
              return require(f).copy_install(picker)
            end,
            open_url = function(picker)
              return require(f).open_url(picker)
            end,
          },
          win = {
            list = {
              keys = {
                ["<C-h>"] = "focus_list",
                ["<C-l>"] = "focus_preview",
                ["<C-j>"] = "list_down",
                ["<C-k>"] = "list_up",
                l = "expand",
                h = "collapse",
                o = "open_url",
                ["zR"] = "expand_all",
                ["zM"] = "collapse_all",
                y = "copy_url",
                Y = "copy_install",
              },
            },
            preview = {
              keys = {
                ["<C-h>"] = "focus_list",
                ["<C-l>"] = "focus_preview",
                l = "focus_list",
                h = "focus_list",
              },
            },
          },
        },
      },
    },
  },
}
