local M = {}

local DEFAULT_LIMIT = 20
local DEFAULT_EXTENSIONS = {
  "c",
  "cc",
  "cpp",
  "cs",
  "go",
  "h",
  "hpp",
  "java",
  "js",
  "jsx",
  "kt",
  "lua",
  "md",
  "py",
  "rb",
  "rs",
  "sh",
  "swift",
  "ts",
  "tsx",
  "vim",
  "viml",
  "yaml",
  "yml",
  "json",
  "toml",
  "ini",
}

local COMPLEXITY_KEYWORDS = {
  "if",
  "elseif",
  "else",
  "for",
  "while",
  "repeat",
  "until",
  "case",
  "switch",
  "match",
  "when",
  "catch",
  "try",
  "finally",
  "function",
}

local default_opts = {
  command_name = "RefactorCandidates",
  limit = DEFAULT_LIMIT,
  extensions = DEFAULT_EXTENSIONS,
  max_changes = 120,
}

local function extension_allowed(file, extensions)
  local ext = file:match("%.([^.]+)$")
  if not ext then
    return false
  end
  ext = ext:lower()
  for _, allowed in ipairs(extensions) do
    if ext == allowed then
      return true
    end
  end
  return false
end

local function project_root()
  local root = vim.trim(vim.fn.system({ "git", "rev-parse", "--show-toplevel" }))
  if vim.v.shell_error ~= 0 or root == "" then
    return nil
  end
  return root
end

local function list_files(root)
  local files = vim.fn.systemlist({ "git", "-C", root, "ls-files" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return files
end

local function complexity_score(lines)
  local count = 0
  for _, line in ipairs(lines) do
    for _, keyword in ipairs(COMPLEXITY_KEYWORDS) do
      local _, hits = line:gsub("%f[%w]" .. keyword .. "%f[^%w_]", "")
      count = count + hits
    end
  end
  return count
end

local function file_stats(root, path)
  local absolute = vim.fs.joinpath(root, path)
  local lines = vim.fn.readfile(absolute)
  local loc = #lines
  local complexity = complexity_score(lines)

  local revisions = #vim.fn.systemlist({
    "git",
    "-C",
    root,
    "log",
    "--max-count=" .. M._opts.max_changes,
    "--pretty=format:%h",
    "--",
    path,
  })
  if vim.v.shell_error ~= 0 then
    revisions = 0
  end

  local score = loc + (complexity * 2) + (revisions * 8)
  return {
    loc = loc,
    complexity = complexity,
    revisions = revisions,
    score = score,
    path = path,
    absolute = absolute,
  }
end

local function render_candidates(results, limit)
  if #results == 0 then
    return { "No candidate files found in this repository." }
  end

  table.sort(results, function(a, b)
    if a.score == b.score then
      return a.path < b.path
    end
    return a.score > b.score
  end)

  local lines = {
    "Top refactor candidates (score = LOC + complexity*2 + revisions*8)",
    "Score  LOC  Cpx  Rev  Path",
    "----------------------------------------",
  }

  local max = math.min(limit, #results)
  for idx = 1, max do
    local item = results[idx]
    lines[#lines + 1] = string.format(
      "%-5d %4d %4d %4d  %s",
      item.score,
      item.loc,
      item.complexity,
      item.revisions,
      item.path
    )
  end

  if #results > max then
    lines[#lines + 1] = string.format("... and %d more files", #results - max)
  end

  return lines
end

local function open_candidates_buffer(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.cmd("botright split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, math.min(#lines + 2, 30))
  vim.keymap.set("n", "q", "<cmd>q!<cr>", { silent = true, buffer = buf })
  vim.keymap.set("n", "<esc>", "<cmd>q!<cr>", { silent = true, buffer = buf })
  vim.bo[buf].filetype = "text"
end

local function run_report(raw_args)
  local root = project_root()
  if not root then
    return vim.notify("RefactorCandidates: run inside a git repository", vim.log.levels.WARN)
  end

  local args = vim.trim(raw_args)
  local limit = M._opts.limit
  if args ~= "" then
    local parsed = tonumber(args)
    if not parsed or parsed <= 0 then
      return vim.notify("RefactorCandidates: limit must be a positive integer", vim.log.levels.ERROR)
    end
    limit = parsed
  end

  local files = list_files(root)
  if not files then
    return vim.notify("RefactorCandidates: failed to list git files", vim.log.levels.ERROR)
  end

  local candidates = {}
  for _, path in ipairs(files) do
    if extension_allowed(path, M._opts.extensions) then
      local ok, stats = pcall(file_stats, root, path)
      if ok then
        candidates[#candidates + 1] = stats
      end
    end
  end

  if #candidates == 0 then
    return vim.notify("RefactorCandidates: no matching files under supported extensions", vim.log.levels.INFO)
  end

  local lines = render_candidates(candidates, limit)
  open_candidates_buffer(lines)
end

function M.setup(opts)
  M._opts = vim.tbl_extend("force", default_opts, opts or {})
  vim.api.nvim_create_user_command(M._opts.command_name, function(cmd)
    run_report(cmd.args)
  end, {
    nargs = "?",
    desc = "Show refactor candidate files sorted by lines/complexity/revisions",
    complete = function(arg_lead)
      local lead = arg_lead or ""
      local suggestions = { tostring(M._opts.limit) }
      return vim.tbl_filter(function(value)
        return vim.startswith(value, lead)
      end, suggestions)
    end,
  })
end

return M
