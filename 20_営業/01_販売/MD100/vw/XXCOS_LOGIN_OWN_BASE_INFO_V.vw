/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_login_own_base_info_v
 * Description     : ログインユーザ自拠点ビュー
 * Version         : 1.3
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   K.Kakishita      新規作成
 *  2009/07/22    1.1   M.Maruyama       障害番号0000640 対応
 *  2009/09/03    1.2   M.Sano           障害番号0001227 対応
 *  2009/10/16    1.3   K.Atsushiba      障害番号0001113 対応
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_login_own_base_info_v (
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
    (
      SELECT
        CASE
          WHEN pd.process_date          >= TRUNC(
                                             NVL( TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' ),
                                               pd.process_date
                                             )
                                           )
          THEN paaf.ass_attribute5                                              --拠点コード（新）
-- 2009/10/16 Ver1.3 Mod Start
          ELSE paaf.ass_attribute6                                              --拠点コード（旧）
--          ELSE paaf.ass_attribute4                                              --拠点コード（旧）
-- 2009/10/16 Ver1.3 Mod Start
        END                             own_base_code,                          --拠点コード
        pd.process_date                 process_date                            --業務日付
      FROM
        fnd_user                        fu,                                     --ユーザマスタ
        per_all_people_f                papf,                                   --従業員マスタ
        per_all_assignments_f           paaf,                                   --アサインメントマスタ
        per_person_types                ppt,                                    --従業員タイプマスタ
        (
-- 2009/09/03 Ver1.2 Mod Start
--          SELECT
--            TRUNC( xxccp_common_pkg2.get_process_date )     process_date        --業務日付
--          FROM
--            dual
          SELECT TRUNC( xpd.process_date )                  process_date        --業務日付
          FROM   xxccp_process_dates xpd
-- 2009/09/03 Ver1.2 Mod End
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
    )                                   obc
  WHERE
    hca.party_id                        = hp.party_id
  AND hca.account_number                = obc.own_base_code
  AND hca.customer_class_code           = '1'
--  2009/7/22 Ver1.1 Del Start
--  AND obc.process_date                  >= TRUNC(
--                                             NVL( TO_DATE( hca.attribute3,  'RRRR/MM/DD' ),
--                                               obc.process_date
--                                             )
--                                           )
--  2009/7/22 Ver1.1 Del End
  ;
COMMENT ON  COLUMN  xxcos_login_own_base_info_v.base_code        IS  '拠点コード'; 
COMMENT ON  COLUMN  xxcos_login_own_base_info_v.base_name        IS  '拠点名称';
COMMENT ON  COLUMN  xxcos_login_own_base_info_v.base_short_name  IS  '拠点略称';
--
COMMENT ON  TABLE   xxcos_login_own_base_info_v                  IS  'ログインユーザ自拠点ビュー';
