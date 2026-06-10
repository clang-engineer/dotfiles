-- ~/.ssh/config에 LocalForward 15432 10.1.2.6:15432 설정 후 사용
return {
  { name = "[eras] via SSH", url = "postgresql://eras@localhost:15432/eras" },
}
