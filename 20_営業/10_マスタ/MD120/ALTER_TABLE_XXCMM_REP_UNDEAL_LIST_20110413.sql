-- 未取引客チェックリストワーク項目追加スクリプト
ALTER TABLE xxcmm_rep_undeal_list ADD (
  employee_number      VARCHAR2(30),
  employee_name        VARCHAR2(20)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_rep_undeal_list.employee_number         IS '担当営業員コード'
/
COMMENT ON COLUMN xxcmm.xxcmm_rep_undeal_list.employee_name           IS '担当営業員'
/

-- 未取引客チェックリストワーク項目変更スクリプト
ALTER TABLE xxcmm_rep_undeal_list MODIFY (
  install_code         VARCHAR2(12),
  change_amount        NUMBER(9,0)
)
/