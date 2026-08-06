local M = {}

M.hl = {
  purple = "DashboardArtPurple",
  yellow = "DashboardArtYellow",
  cyan = "DashboardArtCyan",
  grey = "DashboardArtGrey",
  signature = "DashboardArtSignature",
}

local function set_palette()
  vim.api.nvim_set_hl(0, M.hl.purple, { fg = "#bd5eff" })
  vim.api.nvim_set_hl(0, M.hl.yellow, { fg = "#f1ff5e", bold = true })
  vim.api.nvim_set_hl(0, M.hl.cyan, { fg = "#5ef1ff" })
  vim.api.nvim_set_hl(0, M.hl.grey, { fg = "#9aa5b1" })
  vim.api.nvim_set_hl(0, M.hl.signature, { fg = "#b8abd4", italic = true })
end

local palette_group = vim.api.nvim_create_augroup("dashboard_ascii_palette", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", { group = palette_group, callback = set_palette })
set_palette()

function M.render(lines, highlight_at)
  local header = {}
  for line_number, line in ipairs(lines) do
    local run = ""
    local run_hl

    local function flush()
      if run ~= "" then
        header[#header + 1] = { run, hl = run_hl }
        run = ""
      end
    end

    local col = 0
    for char in line:gmatch(".") do
      col = col + 1
      local hl = highlight_at(line_number, col, char, line)
      if hl ~= run_hl then
        flush()
        run_hl = hl
      end
      run = run .. char
    end
    flush()

    if line_number < #lines then
      header[#header + 1] = { "\n" }
    end
  end
  return header
end

return M
