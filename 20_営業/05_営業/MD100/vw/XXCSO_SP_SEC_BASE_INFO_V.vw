/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * VIEW Name      : XXCSO_SP_SEC_BASE_INFO_V
 * Description    : SP専決セキュリティ拠点ビュー
 * Version        : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2015/02/10    1.0   S.Yamashita      新規作成
 *
 ****************************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_SP_SEC_BASE_INFO_V
(
 base_code
,base_name
)
AS
SELECT ffv.flex_value  base_code
      ,ffv.attribute4  base_name
FROM   fnd_flex_value_sets   ffvs
      ,fnd_flex_values       ffv
      ,fnd_flex_values_tl    ffvt
      ,per_all_people_f      papf
      ,per_all_assignments_f paaf
      ,fnd_user fu
WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id
AND    ffv.flex_value_id        = ffvt.flex_value_id
AND    ffvt.language            = 'JA'
AND    ffv.enabled_flag         = 'Y'
AND    ffv.summary_flag         = 'N'
AND    ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
AND    fu.user_id               = fnd_global.user_id
AND    fu.employee_id           = papf.person_id
AND    papf.person_id           = paaf.person_id
AND    xxccp_common_pkg2.get_process_date BETWEEN TRUNC( papf.effective_start_date )
                                              AND TRUNC( papf.effective_end_date   )
AND    xxccp_common_pkg2.get_process_date BETWEEN TRUNC( paaf.effective_start_date )
                                              AND TRUNC( paaf.effective_end_date   )
AND  (
        ( ffv.flex_value         = paaf.ass_attribute5 )
  OR    ( EXISTS ( SELECT 'X'
                   FROM   hz_cust_accounts    hca
                        , xxcmm_cust_accounts xca
                   WHERE  hca.cust_account_id      = xca.customer_id
                     AND  hca.account_number       = ffv.flex_value
                     AND  hca.customer_class_code  = '1'
                     AND  xca.management_base_code = paaf.ass_attribute5
                 )
        )
  OR    ( EXISTS ( SELECT 'X'
                   FROM   fnd_lookup_values_vl flvv
                   WHERE  flvv.lookup_type  = 'XXCSO1_SP_MGR_BASE_CD'
                   AND    flvv.enabled_flag = 'Y'
                   AND    xxccp_common_pkg2.get_process_date  >= NVL(flvv.start_date_active, xxccp_common_pkg2.get_process_date)
                   AND    xxccp_common_pkg2.get_process_date  <= NVL(flvv.end_date_active  , xxccp_common_pkg2.get_process_date)
                   AND    flvv.lookup_code  = paaf.ass_attribute5
                   AND    flvv.attribute2   = 'Y'
                 )
        )
     )
;
COMMENT ON COLUMN XXCSO_SP_SEC_BASE_INFO_V.base_code   IS '拠点コード';
COMMENT ON COLUMN XXCSO_SP_SEC_BASE_INFO_V.base_name   IS '拠点名称';
COMMENT ON TABLE XXCSO_SP_SEC_BASE_INFO_V              IS 'SP専決セキュリティ拠点ビュー';
