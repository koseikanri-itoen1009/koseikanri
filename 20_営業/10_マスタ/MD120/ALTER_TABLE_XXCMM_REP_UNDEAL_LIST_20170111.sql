-- 未取引客チェックリストワーク項目追加スクリプト
ALTER TABLE xxcmm.xxcmm_rep_undeal_list ADD(
  rep_title               VARCHAR2(50),
  nodata_msg              VARCHAR2(50)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_rep_undeal_list.rep_title               IS '帳票タイトル'
/
COMMENT ON COLUMN xxcmm.xxcmm_rep_undeal_list.nodata_msg              IS 'データなしメッセージ'
/