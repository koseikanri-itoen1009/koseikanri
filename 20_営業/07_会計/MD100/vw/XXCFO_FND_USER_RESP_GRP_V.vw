CREATE OR REPLACE FORCE VIEW XXCFO_FND_USER_RESP_GRP_V(
/*************************************************************************
 * 
 * View Name       : XXCFO_FND_USER_RESP_GRP_V
 * Description     : ユーザー職責承認部門ビュー
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2009/07/28    1.0  SCS 嵐田勇人    初回作成
 *                                     [障害0000376]BFA パフォーマンス対応
 ************************************************************************/
  "USER_ID",                            -- ユーザーID
  "RESPONSIBILITY_ID",                  -- 職責ID
  "RESPONSIBILITY_APPLICATION_ID",      -- 職責アプリケーションID
  "SECURITY_GROUP_ID",                  -- セキュリティグループID
  "START_DATE",                         -- 開始日
  "END_DATE",                           -- 終了日
  "DESCRIPTION",                        -- 摘要
  "CREATED_BY",                         -- 作成者
  "CREATION_DATE",                      -- 作成日
  "LAST_UPDATED_BY",                    -- 最終更新者
  "LAST_UPDATE_DATE",                   -- 最終更新日
  "LAST_UPDATE_LOGIN"                   -- 最終更新ログイン
) AS
    SELECT u.user_id user_id,                                   -- ユーザーID
           wur.role_orig_system_id responsibility_id,           -- ロールオリジナルシステムID
           (SELECT application_id
              FROM fnd_application
             WHERE application_short_name =/* Val between 1st and 2nd separator */
                     REPLACE(
                       SUBSTR(wura.role_name,
                            INSTR(wura.role_name, '|', 1, 1)+1,
                                 ( INSTR(wura.role_name, '|', 1, 2)
                                  -INSTR(wura.role_name, '|', 1, 1)-1)
                            )
                       ,'%col', ':')
           ) responsibility_application_id,                     -- 職責アプリケーションID
           (SELECT security_group_id
              FROM fnd_security_groups
             WHERE security_group_key =/* Val after 3rd separator */
                     REPLACE(
                       SUBSTR(wura.role_name,
                              INSTR(wura.role_name, '|', 1, 3)+1
                            )
                       ,'%col', ':')
           ) security_group_id,                                 -- セキュリティグループID
           fnd_date.canonical_to_date('1000/01/01') start_date, -- 開始日
           to_date(NULL) end_date,                              -- 終了日
           to_char(NULL) description,                           -- 摘要
           to_number(NULL) created_by,                          -- 作成者
           to_date(NULL) creation_date,                         -- 作成日
           to_number(NULL) last_updated_by,                     -- 最終更新者
           to_date(NULL) last_update_date,                      -- 最終更新日
           to_number(NULL) last_update_login                    -- 最終更新ログイン
      FROM fnd_user u                                           -- ユーザーマスタ
           ,wf_user_role_assignments_v wura                     -- ワークフローユーザーロールアサイメントビュー
           ,wf_user_roles wur                                   -- ワークフローユーザーロールビュー
           ,xx03_per_peoples_v xppv2                            -- BFA従業員ビュー
           ,xx03_flex_value_children_v xfvcv2                   -- BFAフレックス部門親子ビュー
           ,per_people_f ppf2                                   -- 従業員マスタビュー
     WHERE wura.user_name = u.user_name
       AND wur.role_orig_system = 'FND_RESP'
       AND wur.partition_id = 2
       AND wura.role_name = wur.role_name
       AND wura.user_name = wur.user_name
       AND xfvcv2.flex_value = ppf2.attribute28
       AND xppv2.attribute30 = xfvcv2.parent_flex_value
       AND xppv2.user_id = XX00_PROFILE_PKG.VALUE('USER_ID')
       AND TRUNC(SYSDATE) BETWEEN xppv2.effective_start_date
                              AND xppv2.effective_end_date
       AND u.employee_id = ppf2.person_id
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.user_id                        IS 'ユーザーID'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.responsibility_id              IS '職責ID'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.responsibility_application_id  IS '職責アプリケーションID'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.security_group_id              IS 'セキュリティグループID'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.start_date                     IS '開始日'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.end_date                       IS '終了日'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.description                    IS '摘要'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.created_by                     IS '作成者'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.creation_date                  IS '作成日'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.last_updated_by                IS '最終更新者'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.last_update_date               IS '最終更新日'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.last_update_login              IS '最終更新ログイン'
/
COMMENT ON TABLE  xxcfo_fnd_user_resp_grp_v IS 'ユーザー職責承認部門ビュー'
/
