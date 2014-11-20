/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOS_CREATED_BY_OWN_BASE_V
 * Description     : 全ユーザ所属する自拠点ビュー
 * Version         : 1.3
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/21    1.0   T.Tyou           新規作成
 *  2009/07/22    1.1   M.Maruyama       障害番号0000640 対応
 *  2009/09/03    1.2   M.Sano           障害番号0001227 対応
 *  2009/10/16    1.3   K.Atsushiba      障害番号0001113 対応
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_created_by_own_base_v (
  base_code,                            --拠点コード
  user_id                               --ユーザID
)
AS 
 SELECT
    hca.account_number                  base_code,
    obc.user_id                         user_id
  FROM
    hz_cust_accounts                    hca,
    hz_parties                          hp,
    ( SELECT
        CASE
          WHEN pd.process_date          >= TRUNC(
                                             NVL(  FND_DATE.STRING_TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' ),
                                               pd.process_date
                                             )
                                           )
          THEN paaf.ass_attribute5
-- 2009/10/16 Ver1.3 Mod Start
          ELSE paaf.ass_attribute6                                              --拠点コード（旧）
--          ELSE paaf.ass_attribute4                                              --拠点コード（旧）
-- 2009/10/16 Ver1.3 Mod Start
        END                             own_base_code,
        pd.process_date                 process_date,
        fu.user_id                      user_id
      FROM
        fnd_user                        fu,  
        per_all_people_f                papf, 
        per_all_assignments_f           paaf, 
        per_person_types                ppt, 
        (
-- 2009/09/03 Ver1.2 Mod Start
--          SELECT
--            TRUNC( xxccp_common_pkg2.get_process_date )     process_date     
--          FROM
--            dual
          SELECT
            TRUNC( xpd.process_date )   process_date
          FROM
            xxccp_process_dates         xpd
-- 2009/09/03 Ver1.2 Mod End
        )                               pd                             
      WHERE 
      --fu.user_id                  = NVL( :order.created_by, fnd_global.user_id )
      fu.employee_id                    = papf.person_id
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
  WHERE hca.party_id                    = hp.party_id
  AND hca.account_number                = obc.own_base_code
  AND hca.customer_class_code           = '1'
--  2009/7/22 Ver1.1 Del Start
--  AND obc.process_date                  >= TRUNC(
--                                             NVL(  FND_DATE.STRING_TO_DATE( hca.attribute3,  'RRRR/MM/DD' ),
--                                               obc.process_date
--                                             )
--                                           )
--  2009/7/22 Ver1.1 Del End
;
COMMENT ON  COLUMN  xxcos_created_by_own_base_v.base_code       IS  '拠点コード';
COMMENT ON  COLUMN  xxcos_created_by_own_base_v.user_id         IS  'ユーザID';
--
COMMENT ON  TABLE   xxcos_created_by_own_base_v                 IS  '全ユーザ所属する自拠点ビュー';
