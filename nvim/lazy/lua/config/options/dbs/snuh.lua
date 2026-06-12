return {
  -- 운영 PostgreSQL (metadb.snuh.org → 172.26.33.28)
  { name = "[SNUH] 운영 rex", url = "postgresql://postgres@metadb.snuh.org:80/rex" },
  { name = "[SNUH] 운영 rex_stage", url = "postgresql://postgres@metadb.snuh.org:80/rex_stage" },
  { name = "[SNUH] 운영 psd_client", url = "postgresql://postgres@metadb.snuh.org:80/psd_client" },
  { name = "[SNUH] 운영 ctdw_new", url = "postgresql://postgres@metadb.snuh.org:80/ctdw_new" },

  -- 가명화(구) 172.26.33.23
  { name = "[SNUH] 가명화(구) psd_server", url = "postgresql://postgres@172.26.33.23:5432/psd_server" },
  { name = "[SNUH] 가명화(구) psd_client", url = "postgresql://postgres@172.26.33.23:5432/psd_client" },
  { name = "[SNUH] 가명화(구) kmimic", url = "postgresql://postgres@172.26.33.23:5432/kmimic" },

  -- 개발(구) 172.26.33.18
  { name = "[SNUH] 개발(구) rex", url = "postgresql://rex@172.26.33.18:5432/rex" },

  -- Vertica: dadbod-vertica.nvim 어댑터로 활성화. 별도로 vsql 클라이언트가 PATH에 있어야 함.
  { name = "[SNUH] Vertica CDW (vertica)", url = "vertica://vertica@172.26.33.19:5433/CDW" },
  { name = "[SNUH] Vertica ODS (emr)", url = "vertica://emr@172.26.33.19:5433/CDW" },
  { name = "[SNUH] Vertica CDW (cdw)", url = "vertica://rex@cdwdb.snuh.org:80/CDW" },

  -- Oracle: dadbod이 sqlplus 클라이언트 필요. 설치 후 주석 해제.
  -- { name = "[SNUH] Oracle SNUH_IRB", url = "oracle://SNUHOCS@172.26.76.38:13625/orcl" },
  -- { name = "[SNUH] Oracle SNUH_HIS", url = "oracle://inf_ncdw@172.26.103.102:9991/DRHIS" },
  -- { name = "[SNUH] Oracle crisdb",   url = "oracle://SNUHOCS@crisdb.snuh.org:80/orcl" },
  -- { name = "[SNUH] Oracle hisdb",    url = "oracle://inf_ncdw@hisdb.snuh.org:80/DRHIS" },
}
