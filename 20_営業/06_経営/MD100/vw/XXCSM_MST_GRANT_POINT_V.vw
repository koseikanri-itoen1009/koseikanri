CREATE OR REPLACE VIEW XXCSM_MST_GRANT_POINT_V
(
  row_id
 ,subject_year
 ,post_cd
 ,duties_cd
 ,custom_condition_cd
 ,custom_condition_name
 ,grant_condition_point
 ,grant_condition_point_name
 ,grant_point_target_1st_month
 ,grant_point_target_2nd_month
 ,grant_point_target_3rd_month
 ,grant_point_condition_price
 ,created_by
 ,creation_date
 ,last_updated_by
 ,last_update_date
 ,last_update_login
 ,request_id
 ,program_application_id
 ,program_id
 ,program_update_date
)
AS
SELECT xmgp.rowid
      ,xmgp.subject_year
      ,xmgp.post_cd
      ,xmgp.duties_cd
      ,xmgp.custom_condition_cd
      ,cflv.meaning                                          -- 顧客業態名
      ,xmgp.grant_condition_point
      ,pflv.meaning                                          -- ポイント付与条件名
      ,xmgp.grant_point_target_1st_month
      ,xmgp.grant_point_target_2nd_month
      ,xmgp.grant_point_target_3rd_month
      ,ROUND( xmgp.grant_point_condition_price / 1000 )  -- ポイント付与条件金額（単位：千円）小数点１桁を四捨五入
      ,xmgp.created_by
      ,xmgp.creation_date
      ,xmgp.last_updated_by
      ,xmgp.last_update_date
      ,xmgp.last_update_login
      ,xmgp.request_id
      ,xmgp.program_application_id
      ,xmgp.program_id
      ,xmgp.program_update_date
  FROM xxcsm_mst_grant_point     xmgp
      ,fnd_lookup_values         cflv    -- 顧客業態名取得用
      ,fnd_lookup_values         pflv    -- ポイント付与条件名取得用
      ,xxcsm_process_date_v      xpcdv
 WHERE cflv.lookup_code  = xmgp.custom_condition_cd    -- 顧客業態名取得用抽出条件
   AND cflv.language     = USERENV('LANG')
   AND cflv.lookup_type  = 'XXCSM1_TYPE_OF_INDUSTRY'
   AND cflv.enabled_flag = 'Y'
   AND NVL(cflv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
   AND NVL(cflv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
   AND pflv.lookup_code  = xmgp.grant_condition_point   -- ポイント付与条件名取得用抽出条件
   AND pflv.language     = USERENV('LANG')
   AND pflv.lookup_type  = 'XXCSM1_GRANT_CONDITION_POINT'
   AND pflv.enabled_flag = 'Y'
   AND NVL(pflv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
   AND NVL(pflv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date;
--
COMMENT ON COLUMN xxcsm_mst_grant_point_v.row_id                        IS 'ＲＯＷ＿ＩＤ';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.subject_year                  IS '対象年度';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.post_cd                       IS '部署コード';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.duties_cd                     IS '職務コード';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.custom_condition_cd           IS '顧客業態コード';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.custom_condition_name         IS '顧客業態名';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_condition_point         IS 'ポイント付与条件';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_condition_point_name    IS 'ポイント付与条件名';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_point_target_1st_month  IS 'ポイント付与条件対象月_当月';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_point_target_2nd_month  IS 'ポイント付与条件対象月_翌月';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_point_target_3rd_month  IS 'ポイント付与条件対象月_翌々月';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_point_condition_price   IS 'ポイント付与条件金額';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.created_by                    IS '作成者';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.creation_date                 IS '作成日';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.last_updated_by               IS '最終更新者';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.last_update_date              IS '最終更新日';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.last_update_login             IS '最終更新ログインID';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.request_id                    IS '要求ID';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.program_application_id        IS 'プログラムアプリケーションID';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.program_id                    IS 'プログラムID';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.program_update_date           IS 'プログラム更新日';
--
COMMENT ON TABLE  xxcsm_mst_grant_point_v IS 'ポイント付与条件マスタビュー';
