return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          -- 기본은 숨김(hidden/ignored off). H/I로 토글한 상태를
          -- explorer를 닫았다 다시 열어도 세션 동안 유지한다.
          -- snacks가 close 시 마지막 토글값을 resume 상태에 저장하므로
          -- 열 때 그 값을 다시 주입한다. (nvim 재시작하면 리셋)
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
