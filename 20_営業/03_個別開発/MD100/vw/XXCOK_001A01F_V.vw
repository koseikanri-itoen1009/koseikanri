/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_001A01F_V
 * Description : 顧客移行入力画面（顧客単位）ビュー
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          新規作成
 *  2011/02/03    1.1   M.Hirose         [E_本稼動_02010,06187]対応
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_001a01f_v(
  row_id
 ,cust_shift_id
 ,cust_code
 ,cust_name
 ,prev_base_code
 ,prev_base_name
 ,new_base_code
 ,new_base_name
 ,target_acctg_year
 ,cust_shift_date
 ,status
 ,emp_code
 ,shift_type
 ,input_date
 ,create_chg_je_flag
 ,vd_inv_trnsfr_status
 ,sale_base_code
 ,management_base_code
-- 2011/02/03 Ver.1.1 [E_本稼動_02010,06187] SCS M.Hirose REPAIR START
 ,department_code
 ,new_base_code_from
 ,new_base_code_to
 ,customer_class_code
-- 2011/02/03 Ver.1.1 [E_本稼動_02010,06187] SCS M.Hirose REPAIR END
 ,created_by
 ,creation_date
 ,last_updated_by
 ,last_update_date
 ,last_update_login
)
AS
SELECT xcsi.ROWID                       AS row_id
     , xcsi.cust_shift_id               AS cust_shift_id
     , xcsi.cust_code                   AS cust_code
     , hp1.party_name                   AS cust_name
     , xcsi.prev_base_code              AS prev_base_code
     , hp2.party_name                   AS prev_base_name
     , xcsi.new_base_code               AS new_base_code
     , hp3.party_name                   AS new_base_name
     , xcsi.target_acctg_year           AS target_acctg_year
     , xcsi.cust_shift_date             AS cust_shift_date
     , xcsi.status                      AS status
     , xcsi.emp_code                    AS emp_code
     , xcsi.shift_type                  AS shift_type
     , xcsi.input_date                  AS input_date
     , xcsi.create_chg_je_flag          AS create_chg_je_flag
     , xcsi.vd_inv_trnsfr_status        AS vd_inv_trnsfr_status
     , xca.sale_base_code               AS sale_base_code
     , xca.management_base_code         AS management_base_code
-- 2011/02/03 Ver.1.1 [E_本稼動_02010,06187] SCS M.Hirose REPAIR START
     , xadv.aff_department_code         AS department_code
     , TRUNC(xadv.start_date_active)    AS new_base_code_from
     , TRUNC(xadv.end_date_active  )    AS new_base_code_to
     , hca1.customer_class_code         AS customer_class_code
-- 2011/02/03 Ver.1.1 [E_本稼動_02010,06187] SCS M.Hirose REPAIR END
     , xcsi.created_by                  AS created_by
     , xcsi.creation_date               AS creation_date
     , xcsi.last_updated_by             AS last_updated_by
     , xcsi.last_update_date            AS last_update_date
     , xcsi.last_update_login           AS last_update_login
FROM xxcok_cust_shift_info    xcsi
   , hz_cust_accounts         hca1
   , hz_cust_accounts         hca2
   , hz_cust_accounts         hca3
   , hz_parties               hp1
   , hz_parties               hp2
   , hz_parties               hp3
   , xxcmm_cust_accounts      xca
-- 2011/02/03 Ver.1.1 [E_本稼動_02010,06187] SCS M.Hirose REPAIR START
   , xxcff_aff_department_v   xadv
-- 2011/02/03 Ver.1.1 [E_本稼動_02010,06187] SCS M.Hirose REPAIR END
WHERE xcsi.cust_code          = hca1.account_number
  AND xcsi.prev_base_code     = hca2.account_number
  AND xcsi.new_base_code      = hca3.account_number
  AND hca1.party_id           = hp1.party_id
  AND hca2.party_id           = hp2.party_id
  AND hca3.party_id           = hp3.party_id
  AND hca1.cust_account_id    = xca.customer_id
-- 2011/02/03 Ver.1.1 [E_本稼動_02010,06187] SCS M.Hirose REPAIR START
  AND xcsi.new_base_code      = xadv.aff_department_code(+)
-- 2011/02/03 Ver.1.1 [E_本稼動_02010,06187] SCS M.Hirose REPAIR END
/
COMMENT ON TABLE  apps.xxcok_001a01f_v                           IS '顧客移行入力画面（顧客単位）ビュー'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.row_id                    IS 'ROW_ID'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.cust_shift_id             IS '顧客移行ID'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.cust_code                 IS '顧客コード'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.cust_name                 IS '顧客名称'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.prev_base_code            IS '旧拠点コード'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.prev_base_name            IS '旧拠点名称'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.new_base_code             IS '新拠点コード'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.new_base_name             IS '新拠点名称'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.target_acctg_year         IS '年度'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.cust_shift_date           IS '顧客移行日'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.status                    IS 'ステータス'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.emp_code                  IS '担当者'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.shift_type                IS '移行区分'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.input_date                IS '入力日'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.create_chg_je_flag        IS '釣銭仕訳作成フラグ'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.vd_inv_trnsfr_status      IS 'VD在庫保管場所転送ステータス'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.sale_base_code            IS '売上担当拠点コード'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.management_base_code      IS '管理元拠点コード'
/
-- 2011/02/03 Ver.1.1 [E_本稼動_02010,06187] SCS M.Hirose REPAIR START
COMMENT ON COLUMN apps.xxcok_001a01f_v.department_code           IS '新拠点コード（AFF）'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.new_base_code_from        IS '新拠点コード開始日'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.new_base_code_to          IS '新拠点コード終了日'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.customer_class_code       IS '顧客区分'
/
-- 2011/02/03 Ver.1.1 [E_本稼動_02010,06187] SCS M.Hirose REPAIR END
COMMENT ON COLUMN apps.xxcok_001a01f_v.created_by                IS '作成者'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.creation_date             IS '作成日'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.last_updated_by           IS '最終更新者'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.last_update_date          IS '最終更新日'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.last_update_login         IS '最終更新ログイン'
/
