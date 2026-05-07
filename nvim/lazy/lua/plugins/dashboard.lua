-- snacks dashboard: 2-pane 레이아웃 (열 때마다 명언/팁 랜덤 회전)
--   pane 1 (좌): Header(명언+팁) / Shortcuts / Recent Files
--   pane 2 (우): Projects / Branches / Git Status / Recent Commits / Stashes
local tips = {
  "<leader>ff 파일 찾기 · <leader>sg 텍스트 grep",
  "gd 정의 점프 · gr 참조 보기 · K 호버 문서",
  "<leader>e Neo-tree 토글 · <leader>fe cwd 기준 열기",
  "<leader>gg LazyGit 실행",
  "<S-h> / <S-l> 버퍼 이동 · <leader>bd 버퍼 닫기",
  "<C-/> 터미널 토글",
  "<leader>ca 코드 액션 · <leader>cf 포맷팅",
  "<leader>cr LSP 이름 변경 (rename)",
  "<leader>L Lazy 매니저 · <leader>cm Mason",
  "<leader>qs 세션 복원 · <leader>qd 세션 삭제",
  "gcc 라인 주석 · gc 비주얼 영역 주석",
  "<leader>w 윈도우 명령 · <C-w>v/s 분할",
  "<leader>xx Trouble 진단 리스트",
  "<leader>un 알림 닫기 · <leader>uh inlay hint 토글",
  "<C-h/j/k/l> vim/tmux 통합 윈도우 이동",
}
local quotes = {
  "Make it work, make it right, make it fast. — Kent Beck",
  "Premature optimization is the root of all evil. — Donald Knuth",
  "Simplicity is the soul of efficiency. — Austin Freeman",
  "Code is read more often than it is written. — Guido van Rossum",
  "The best code is no code at all. — Jeff Atwood",
  "Talk is cheap. Show me the code. — Linus Torvalds",
  "Programs must be written for people to read. — Abelson & Sussman",
  "Any fool can write code a computer understands; good programmers write code humans understand. — Martin Fowler",
  "First, solve the problem. Then, write the code. — John Johnson",
  "Simple is better than complex. — The Zen of Python",
  "Readability counts. — The Zen of Python",
  "There are only two hard things: cache invalidation and naming things. — Phil Karlton",
  "Walking on water and developing software from a spec are easy if both are frozen. — Edward Berard",
  "Make the change easy, then make the easy change. — Kent Beck",
  "Weeks of programming can save you hours of planning. — Anonymous",
}
math.randomseed(os.time())
local tip_idx = math.random(#tips)
local quote_idx = math.random(#quotes)

local divider = string.rep("━", 60)
local header = table.concat({
  divider,
  "",
  "“" .. quotes[quote_idx] .. "”",
  "",
  "Tip · " .. tips[tip_idx],
  "",
  divider,
}, "\n")

return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        header = header,
      },
      sections = {
        { section = "header", padding = 2 },
        { section = "keys", gap = 1, padding = 1 },
        { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", cwd = true, indent = 2, padding = 1 },
        { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
        {
          pane = 2,
          icon = " ",
          title = "Branches",
          section = "terminal",
          key = "b",
          action = function()
            Snacks.picker.git_branches()
          end,
          enabled = function()
            return Snacks.git.get_root() ~= nil
          end,
          cmd = "git branch --sort=-committerdate",
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        {
          pane = 2,
          icon = " ",
          title = "Git Status",
          section = "terminal",
          key = "S",
          action = function()
            vim.cmd("LazyGit")
          end,
          enabled = function()
            return Snacks.git.get_root() ~= nil
          end,
          cmd = "git status --short --renames",
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        {
          pane = 2,
          icon = " ",
          title = "Recent Commits",
          section = "terminal",
          key = "C",
          action = function()
            Snacks.picker.git_log()
          end,
          enabled = function()
            return Snacks.git.get_root() ~= nil
          end,
          cmd = "git log --oneline --decorate --color=never -5",
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        {
          pane = 2,
          icon = " ",
          title = "Stashes",
          section = "terminal",
          key = "t",
          action = function()
            Snacks.picker.git_stash()
          end,
          enabled = function()
            if Snacks.git.get_root() == nil then
              return false
            end
            local out = vim.fn.system({ "git", "stash", "list" })
            return vim.v.shell_error == 0 and out ~= ""
          end,
          cmd = "git stash list",
          height = 4,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        { section = "startup" },
      },
    },
  },
}
