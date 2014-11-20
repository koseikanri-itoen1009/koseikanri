/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_input_sales_branch_v
 * Description     : 出荷依頼実績入力拠点ビュー
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/04/05    1.0   S.Tomita         新規作成
 *  2010/05/11    1.1   H.Itou           E_本稼動_02627
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_input_sales_branch_v (
  dsp_code         -- 表示順
 ,input_base_code  -- 拠点コード
 ,input_base_name  -- 拠点名称
)
AS
SELECT  flv.lookup_code  dsp_code
       ,flv.meaning      input_base_code
       ,flv.description  input_base_name
FROM   xxcos_lookup_values_v flv
WHERE  trunc(sysdate) >=flv.start_date_active
AND    trunc(sysdate) <=NVL(flv.end_date_active,trunc(sysdate))
AND    flv.lookup_type ='XXCOS1_INPUT_SALES_BRANCH'
UNION
-- 2010/05/11 Ver1.1 H.Itou Mod Start E_本稼動_02627
SELECT  '00'                  dsp_code
       ,xcav.party_number     input_base_code
       ,xcav.party_short_name input_base_name
FROM    fnd_user              fu
       ,per_all_people_f      papf
       ,per_all_assignments_f paaf
       ,xxcmn_locations_v     xlv
       ,xxcmn_cust_accounts_v xcav
WHERE   fu.user_id               = FND_PROFILE.VALUE('USER_ID')
AND     fu.employee_id           = papf.person_id
AND     papf.person_id           = paaf.person_id
AND     NVL(paaf.effective_start_date, TO_DATE('19000101', 'RRRRMMDD')) <= TRUNC(SYSDATE)
AND     NVL(paaf.effective_end_date,   TO_DATE('99991231', 'RRRRMMDD')) >= TRUNC(SYSDATE)
AND     NVL(papf.effective_start_date, TO_DATE('19000101', 'RRRRMMDD')) <= TRUNC(SYSDATE)
AND     NVL(papf.effective_end_date,   TO_DATE('99991231', 'RRRRMMDD')) >= TRUNC(SYSDATE)
AND     paaf.location_id         = xlv.location_id
AND     xlv.location_code        = xcav.party_number
AND     xcav.customer_class_code = '1'
;
--SELECT '00'              dsp_code
--       ,base_code        input_base_code
--       ,base_short_name  input_base_name
--FROM   xxcos_login_own_base_info_v;
-- 2010/05/11 Ver1.1 H.Itou Mod End E_本稼動_02627
--
COMMENT ON  COLUMN  xxcos_input_sales_branch_v.dsp_code          IS  '表示順';
COMMENT ON  COLUMN  xxcos_input_sales_branch_v.input_base_code   IS  '拠点コード';
COMMENT ON  COLUMN  xxcos_input_sales_branch_v.input_base_name   IS  '拠点名称';
--
COMMENT ON  TABLE   xxcos_input_sales_branch_v                   IS  '出荷依頼実績入力拠点ビュー';
