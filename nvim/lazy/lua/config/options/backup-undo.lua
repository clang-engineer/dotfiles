-- backup-undo.lua: 백업, swap, undo 파일 설정
-- 파일 손실 방지 및 영구 undo 히스토리 유지

local data_dir = vim.fn.stdpath("data")

-- 영구 undo 활성화 (Neovim 재시작 후에도 undo 히스토리 유지)
vim.opt.undofile = true
vim.opt.undodir = data_dir .. "/undo"

-- Swap 파일 설정 (크래시 복구용)
vim.opt.swapfile = true
vim.opt.directory = data_dir .. "/swap//"

-- 백업 파일 설정
vim.opt.backup = false -- 저장 시 백업 파일 생성 안 함 (git이 있으므로)
vim.opt.writebackup = true -- 저장 중에만 임시 백업 (안전성)

-- 디렉토리 자동 생성
local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

ensure_dir(vim.opt.undodir:get()[1])
ensure_dir(vim.opt.directory:get()[1])

-- Undo 파일 보관 기간 설정
vim.opt.undolevels = 10000 -- undo 단계 수
vim.opt.undoreload = 10000 -- 버퍼 다시 로드 시 undo 가능한 라인 수
