CREATE OR REPLACE FORCE VIEW XX03_APPROVER_PERSON_V(
/*************************************************************************
 * 
 * View Name       : XX03_APPROVER_PERSON_V
 * Description     : BFA承認者ビュー
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2009/07/28    1.0  SCS 嵐田勇人    初回修正
 *                                     [障害0000376]BFA パフォーマンス対応
 ************************************************************************/
  "PERSON_ID",                          -- 従業員ID
  "EFFECTIVE_START_DATE",               -- 有効開始日
  "EFFECTIVE_END_DATE",                 -- 有効終了日
  "ATTRIBUTE28",                        -- 所属部門
  "EMPLOYEE_DISP",                      -- 従業員表示
  "USER_ID",                            -- ユーザーID
  "RESPONSIBILITY_ID",                  -- 職責ID
  "PROFILE_NAME_ORG",                   -- プロファイル名_組織
  "PROFILE_VAL_ORG",                    -- プロファイル値_組織
  "PROFILE_NAME_AUTH",                  -- プロファイル名_部門入力権限
  "PROFILE_VAL_AUTH",                   -- プロファイル値_部門入力権限
  "PROFILE_NAME_DEP",                   -- プロファイル名_部門承認可能モジュール
  "PROFILE_VAL_DEP",                    -- プロファイル値_部門承認可能モジュール
  "PROFILE_NAME_ACC",                   -- プロファイル名_経理承認可能モジュール
  "PROFILE_VAL_ACC",                    -- プロファイル値_経理承認可能モジュール
  "R_START_DATE",                       -- ユーザー職責_開始日
  "R_END_DATE",                         -- ユーザー職責_終了日
  "U_START_DATE",                       -- ユーザー_開始日
  "U_END_DATE",                         -- ユーザー_終了日
  "LAST_UPDATE_DATE",                   -- 従業員_最終更新日
  "LAST_UPDATED_BY",                    -- 従業員_最終更新者
  "CREATION_DATE",                      -- 従業員_作成日
  "CREATED_BY",                         -- 従業員_作成者
  "LAST_UPDATE_LOGIN"                   -- 従業員_最終更新ログイン
) AS 
    SELECT ppf.person_id                                                            -- 従業員ID
           ,ppf.effective_start_date                                                -- 有効開始日
           ,ppf.effective_end_date                                                  -- 有効終了日
           ,ppf.attribute28                                                         -- 所属部門
           ,ppf.employee_number ||
              XX00_PROFILE_PKG.VALUE('xx03_text_delimiter') ||
              ppf.per_information18 ||
              ' ' ||
              ppf.per_information19 as employee_disp                                -- 従業員表示
           ,fu.user_id                                                              -- ユーザーID
           ,xfurv.responsibility_id                                                 -- 職責ID
           ,fpo1.user_profile_option_name  profile_name_org                         -- プロファイル名_組織
           ,fpo1.profile_option_value      profile_val_org                          -- プロファイル値_組織
           ,fpo2.user_profile_option_name  profile_name_auth                        -- プロファイル名_部門入力権限
           ,fpo2.profile_option_value      profile_val_auth                         -- プロファイル値_部門入力権限
           ,fpo3.user_profile_option_name         profile_name_dep                  -- プロファイル名_部門承認可能モジュール
           ,NVL(fpo3.profile_option_value,'ALL')  profile_val_dep                   -- プロファイル値_部門承認可能モジュール
           ,fpo4.user_profile_option_name         profile_name_acc                  -- プロファイル名_経理承認可能モジュール
           ,NVL(fpo4.profile_option_value,'ALL')  profile_val_acc                   -- プロファイル値_経理承認可能モジュール
           ,xfurv.start_date                                         r_start_date   -- ユーザー職責_開始日
           ,NVL(xfurv.end_date, TO_DATE('4712/12/31','YYYY/MM/DD'))  r_end_date     -- ユーザー職責_終了日
           ,fu.start_date                                           u_start_date    -- ユーザー_開始日
           ,NVL(fu.end_date  , TO_DATE('4712/12/31','YYYY/MM/DD'))  u_end_date      -- ユーザー_終了日
           ,ppf.last_update_date                                                    -- 従業員_最終更新日
           ,ppf.last_updated_by                                                     -- 従業員_最終更新者
           ,ppf.creation_date                                                       -- 従業員_作成日
           ,ppf.created_by                                                          -- 従業員_作成者
           ,ppf.last_update_login                                                   -- 従業員_最終更新ログイン
      FROM   per_people_f          ppf                                          -- 従業員マスタビュー
            ,fnd_user              fu                                           -- ユーザーマスタ
            ,xxcfo_fnd_user_resp_grp_v  xfurv                                   -- ユーザー職責承認部門ビュー
            ,(SELECT fpov.level_value_application_id
                    ,fpov.level_value
                    ,fpov.profile_option_value
                    ,fpovl.user_profile_option_name
              FROM   fnd_profile_option_values  fpov
                    ,fnd_profile_options_vl     fpovl
              WHERE  fpovl.application_id       = fpov.application_id
                AND  fpovl.profile_option_id    = fpov.profile_option_id
                AND  fpovl.profile_option_name  = 'ORG_ID'
              )                    fpo1                                         -- プロファイル（組織）
            ,(SELECT fpov.level_value_application_id
                    ,fpov.level_value
                    ,fpov.profile_option_value
                    ,fpovl.user_profile_option_name
              FROM   fnd_profile_option_values  fpov
                    ,fnd_profile_options_vl     fpovl
              WHERE  fpovl.application_id       = fpov.application_id
                AND  fpovl.profile_option_id    = fpov.profile_option_id
                AND  fpovl.profile_option_name  = 'XX03_SLIP_AUTHORITIES'
              )                    fpo2                                         -- プロファイル（部門入力権限）
            ,(SELECT fpov.level_value_application_id
                    ,fpov.level_value
                    ,fpov.profile_option_value
                    ,fpovl.user_profile_option_name
              FROM   fnd_profile_option_values  fpov
                    ,fnd_profile_options_vl     fpovl
              WHERE  fpovl.application_id       = fpov.application_id
                AND  fpovl.profile_option_id    = fpov.profile_option_id
                AND  fpovl.profile_option_name  = 'XX03_SLIP_DEP_APPROVE_MODULE'
              )                    fpo3                                         -- プロファイル（部門承認可能モジュール）
            ,(SELECT fpov.level_value_application_id
                    ,fpov.level_value
                    ,fpov.profile_option_value
                    ,fpovl.user_profile_option_name
              FROM   fnd_profile_option_values  fpov
                    ,fnd_profile_options_vl     fpovl
              WHERE  fpovl.application_id       = fpov.application_id
                AND  fpovl.profile_option_id    = fpov.profile_option_id
                AND  fpovl.profile_option_name  = 'XX03_SLIP_ACC_APPROVE_MODULE'
              )                    fpo4                                         -- プロファイル（経理承認可能モジュール）
      WHERE  ppf.current_employee_flag           = 'Y'
        AND  fu.employee_id                      = ppf.person_id
        AND  xfurv.user_id                       = fu.user_id
        AND  fpo1.level_value_application_id     = xfurv.responsibility_application_id
        AND  fpo1.level_value                    = xfurv.responsibility_id
        AND  fpo1.profile_option_value           = XX00_PROFILE_PKG.VALUE('ORG_ID')
        AND  fpo2.level_value_application_id     = xfurv.responsibility_application_id
        AND  fpo2.level_value                    = xfurv.responsibility_id
        AND  fpo2.profile_option_value           BETWEEN '1' AND '9'
        AND  fpo3.level_value_application_id (+) = xfurv.responsibility_application_id
        AND  fpo3.level_value                (+) = xfurv.responsibility_id
        AND  fpo4.level_value_application_id (+) = xfurv.responsibility_application_id
        AND  fpo4.level_value                (+) = xfurv.responsibility_id
/
COMMENT ON COLUMN  xx03_approver_person_v.person_id                     IS '従業員ID'
/
COMMENT ON COLUMN  xx03_approver_person_v.effective_start_date          IS '有効開始日'
/
COMMENT ON COLUMN  xx03_approver_person_v.effective_end_date            IS '有効終了日'
/
COMMENT ON COLUMN  xx03_approver_person_v.attribute28                   IS '所属部門'
/
COMMENT ON COLUMN  xx03_approver_person_v.employee_disp                 IS '従業員表示'
/
COMMENT ON COLUMN  xx03_approver_person_v.user_id                       IS 'ユーザーID'
/
COMMENT ON COLUMN  xx03_approver_person_v.responsibility_id             IS '職責ID'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_name_org              IS 'プロファイル名_組織'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_val_org               IS 'プロファイル値_組織'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_name_auth             IS 'プロファイル名_部門入力権限'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_val_auth              IS 'プロファイル値_部門入力権限'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_name_dep              IS 'プロファイル名_部門承認可能モジュール'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_val_dep               IS 'プロファイル値_部門承認可能モジュール'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_name_acc              IS 'プロファイル名_経理承認可能モジュール'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_val_acc               IS 'プロファイル値_経理承認可能モジュール'
/
COMMENT ON COLUMN  xx03_approver_person_v.r_start_date                  IS 'ユーザー職責_開始日'
/
COMMENT ON COLUMN  xx03_approver_person_v.r_end_date                    IS 'ユーザー職責_終了日'
/
COMMENT ON COLUMN  xx03_approver_person_v.u_start_date                  IS 'ユーザー_開始日'
/
COMMENT ON COLUMN  xx03_approver_person_v.u_end_date                    IS 'ユーザー_終了日'
/
COMMENT ON COLUMN  xx03_approver_person_v.last_update_date              IS '従業員_最終更新日'
/
COMMENT ON COLUMN  xx03_approver_person_v.last_updated_by               IS '従業員_最終更新者'
/
COMMENT ON COLUMN  xx03_approver_person_v.creation_date                 IS '従業員_作成日'
/
COMMENT ON COLUMN  xx03_approver_person_v.created_by                    IS '従業員_作成者'
/
COMMENT ON COLUMN  xx03_approver_person_v.last_update_login             IS '従業員_最終更新ログイン'
/
COMMENT ON TABLE  xx03_approver_person_v IS 'BFA承認者ビュー'
/
