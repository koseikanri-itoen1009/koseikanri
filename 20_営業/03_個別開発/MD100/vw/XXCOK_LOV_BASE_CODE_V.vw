/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_LOV_BASE_CODE_V
 * Description : 拠点ビュー（セキュリティ付）
 *               ログインユーザの所属する拠点
 *               またはログインユーザの所属する拠点が管理する拠点を表示
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/28    1.0   K.Yamaguchi      新規作成
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_lov_base_code_v(
  base_code
, base_name
)
AS
SELECT hca.account_number     AS base_code
     , hp.party_name          AS base_name
FROM hz_cust_accounts         hca
   , hz_parties               hp
   , xxcmm_cust_accounts      xca
   , per_all_people_f         papf
   , per_all_assignments_f    paaf
   , fnd_user                 fu
WHERE hca.party_id            = hp.party_id
  AND hca.cust_account_id     = xca.customer_id
  AND hca.customer_class_code = '1'          -- 拠点
  AND papf.person_id          = paaf.person_id
  AND papf.person_id          = fu.employee_id
  AND fu.user_id              = FND_PROFILE.VALUE( 'USER_ID' )
  AND TRUNC( SYSDATE )  BETWEEN fu.start_date
                            AND NVL( fu.end_date, TRUNC( SYSDATE ) )
  AND TRUNC( SYSDATE )  BETWEEN papf.effective_start_date
                            AND NVL( papf.effective_end_date, TRUNC( SYSDATE ) )
  AND (    hca.account_number       = CASE
                                      WHEN TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' ) > TRUNC( SYSDATE ) THEN
                                        paaf.ass_attribute6
                                      ELSE
                                        paaf.ass_attribute5
                                      END
        OR xca.management_base_code = CASE
                                      WHEN TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' ) > TRUNC( SYSDATE ) THEN
                                        paaf.ass_attribute6
                                      ELSE
                                        paaf.ass_attribute5
                                      END
      )
/
COMMENT ON TABLE  apps.xxcok_lov_base_code_v                     IS '拠点ビュー（セキュリティ付）'
/
COMMENT ON COLUMN apps.xxcok_lov_base_code_v.base_code           IS '拠点コード'
/
COMMENT ON COLUMN apps.xxcok_lov_base_code_v.base_name           IS '拠点名称'
/
