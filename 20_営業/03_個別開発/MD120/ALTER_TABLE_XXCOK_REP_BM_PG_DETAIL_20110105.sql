ALTER TABLE xxcok.xxcok_rep_bm_pg_detail
MODIFY (
  CONTACT_BASE            VARCHAR2(6),
  SELLING_BASE            VARCHAR2(6)
)
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_PG_DETAIL.CONTACT_BASE           IS '本部コード(連絡先拠点)'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_PG_DETAIL.SELLING_BASE           IS '本部コード(売上計上拠点)'
/
