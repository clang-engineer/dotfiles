-- SSH 터널 필요 (Keras VPC 경유)
-- 터널 열기:  ssh -N keras-eras-tunnel   (~/.ssh/config.d/45-keras 참고)
-- 백그라운드: ssh -fN keras-eras-tunnel
return {
  { name = "[eras] via SSH", url = "postgresql://eras@localhost:15432/eras" },
}
