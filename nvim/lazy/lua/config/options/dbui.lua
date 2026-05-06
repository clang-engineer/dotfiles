vim.g.dbs = {
  {
    name = "docker postgres",
    url = "postgres://myuser@localhost:5432/mydb",
  },
  {
    name = "remote postgres (SSH tunnel)",
    url = "postgresql://myuser@REDACTED_IP:5432/mydb?connect_timeout=5",
  },
}
