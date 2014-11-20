/***********************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_login_base_info_v
 * Description     : ログインユーザ拠点ビュー
 * Version         : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   K.Kakishita      新規作成
 *  2009/07/17    1.1   K.Atsushiba      障害番号0000488 対応
 *  2009/07/22    1.2   M.Maruyama       障害番号0000640 対応
 *  2009/09/03    1.3   M.Sano           障害番号0001227 対応
 *  2009/10/16    1.4   K.Atsushiba      障害番号0001113 対応
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_login_base_info_v (
  base_code,                            --拠点コード
  base_name,                            --拠点名称
  base_short_name                       --拠点略称
)
AS
  SELECT
    hca.account_number                  base_code,                              --拠点コード
    hp.party_name                       base_name,                              --拠点名称
    hca.account_name                    base_short_name                         --拠点略称
  FROM
    hz_cust_accounts                    hca,                                    --顧客マスタ
    hz_parties                          hp,                                     --パーティマスタ
--  2009/07/17 Ver1.1 Add Start
    xxcmm_cust_accounts                 xca,                                    --顧客追加情報マスタ
--  2009/07/17 Ver1.1 Add End
    (
      SELECT
        CASE
--  2009/07/17 Ver1.1 Mod Start   
--          WHEN pd.process_date          >= TRUNC(
--                                             NVL( TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' ),
--                                               pd.process_date
--                                             )
--                                           )
          WHEN pd.process_date          >= NVL( TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' ),
                                               pd.process_date
                                             )
--  2009/07/17 Ver1.1 Mod End
          THEN paaf.ass_attribute5                                              --拠点コード（新）
-- 2009/10/16 Ver1.3 Mod Start
          ELSE paaf.ass_attribute6                                              --拠点コード（旧）
--          ELSE paaf.ass_attribute4                                              --拠点コード（旧）
-- 2009/10/16 Ver1.3 Mod Start
        END own_base_code,
        pd.process_date                 process_date                            --業務日付
      FROM
        fnd_user                        fu,                                     --ユーザマスタ
        per_all_people_f                papf,                                   --従業員マスタ
        per_all_assignments_f           paaf,                                   --アサインメントマスタ
        per_person_types                ppt,                                    --従業員タイプマスタ
        (
--  2009/09/03 Ver1.3 Mod Start   
--          SELECT
--            TRUNC( xxccp_common_pkg2.get_process_date )     process_date
--          FROM
--            dual
          SELECT
            TRUNC( xpd.process_date ) process_date
          FROM
            xxccp_process_dates       xpd
--  2009/09/03 Ver1.3 Mod End   
        )                               pd                                      --業務日付
      WHERE
        fu.user_id                      = fnd_global.user_id
      AND fu.employee_id                = papf.person_id
      AND papf.person_id                = paaf.person_id
      AND pd.process_date               >= papf.effective_start_date
      AND pd.process_date               <= papf.effective_end_date
      AND pd.process_date               >= paaf.effective_start_date
      AND pd.process_date               <= paaf.effective_end_date
      AND ppt.business_group_id         = fnd_global.per_business_group_id
      AND ppt.system_person_type        = 'EMP'
      AND ppt.active_flag               = 'Y'
      AND papf.person_type_id           = ppt.person_type_id
      )                                 obc                                     --自拠点情報
  WHERE
    hca.party_id                        = hp.party_id
--  2009/07/17 Ver1.1 Mod Start
--  AND  hca.account_number                = obc.own_base_code
  AND ( hca.account_number                = obc.own_base_code
        OR
        xca.management_base_code          = obc.own_base_code
      )
  AND xca.customer_id               = hca.cust_account_id
--  2009/07/17 Ver1.1 Mod End
  AND hca.customer_class_code           = '1'
--  2009/07/17 Ver1.1 Mod Start
--  AND obc.process_date                  >= TRUNC(
--                                             NVL( TO_DATE( hca.attribute3,  'RRRR/MM/DD' ),
--                                               obc.process_date
--                                             )
--                                           )                                           
--  2009/07/22 Ver1.2 Del Start
--  AND obc.process_date                  >= NVL( TO_DATE( hca.attribute3,  'RRRR/MM/DD' ),
--                                               obc.process_date
--                                             )
--  2009/07/22 Ver1.2 Del End
--  2009/07/17 Ver1.1 Mod End
--  2009/07/17 Ver1.1 Del Start
--  UNION
--  SELECT
--    hca.account_number                  base_code,                              --拠点コード
--    hp.party_name                       base_name,                              --拠点名称
--    hca.account_name                    base_short_name                         --拠点略称
--  FROM
--    hz_cust_accounts                    hca,                                    --顧客マスタ
--    hz_parties                          hp,                                     --パーティマスタ
--    xxcmm_cust_accounts                 xca,                                    --顧客追加情報マスタ
--    (
--      SELECT
--        CASE
--          WHEN pd.process_date          >= NVL( TO_DATE( paaf.ass_attribute2,  'RRRRMMDD' ),
--                                                pd.process_date
--                                              )
--          THEN paaf.ass_attribute5                                              --拠点コード（新）
--          ELSE paaf.ass_attribute4                                              --拠点コード（旧）
--        END own_base_code,
--        pd.process_date                 process_date                            --業務日付
--      FROM
--        fnd_user                        fu,                                     --ユーザマスタ
--        per_all_people_f                papf,                                   --従業員マスタ
--        per_all_assignments_f           paaf,                                   --アサインメントマスタ
--        per_person_types                ppt,                                    --従業員タイプマスタ
--        (
--          SELECT
--            TRUNC( xxccp_common_pkg2.get_process_date )     process_date        --業務日付
--          FROM
--            dual
--        )                               pd                                      --業務日付
--      WHERE
--        fu.user_id                      = fnd_global.user_id
--      AND fu.employee_id                = papf.person_id
--      AND papf.person_id                = paaf.person_id
--      AND pd.process_date               >= papf.effective_start_date
--      AND pd.process_date               <= papf.effective_end_date
--      AND pd.process_date               >= paaf.effective_start_date
--      AND pd.process_date               <= paaf.effective_end_date
--      AND ppt.business_group_id         = fnd_global.per_business_group_id
--      AND ppt.system_person_type        = 'EMP'
--      AND ppt.active_flag               = 'Y'
--      AND papf.person_type_id           = ppt.person_type_id
--    )                                   obc                                     --自拠点管轄拠点情報
--  WHERE
--    hca.party_id                        = hp.party_id
--  AND xca.management_base_code          = obc.own_base_code
--  AND  hca.account_number               =    management_base_code
--  AND hca.cust_account_id               = xca.customer_id
--  AND hca.customer_class_code           = '1'
--  AND obc.process_date                  >= NVL( TO_DATE( hca.attribute3,  'RRRR/MM/DD' ),
--                                               obc.process_date
--                                             )
--  2009/07/17 Ver1.1 Del End
  ;
COMMENT ON  COLUMN  xxcos_login_base_info_v.base_code        IS  '拠点コード'; 
COMMENT ON  COLUMN  xxcos_login_base_info_v.base_name        IS  '拠点名称';
COMMENT ON  COLUMN  xxcos_login_base_info_v.base_short_name  IS  '拠点略称';
--
COMMENT ON  TABLE   xxcos_login_base_info_v                  IS  'ログインユーザ拠点ビュー';
