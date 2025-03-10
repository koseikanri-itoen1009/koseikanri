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
      ,cflv.meaning                                          -- ÚqÆÔ¼
      ,xmgp.grant_condition_point
      ,pflv.meaning                                          -- |Cgt^ð¼
      ,xmgp.grant_point_target_1st_month
      ,xmgp.grant_point_target_2nd_month
      ,xmgp.grant_point_target_3rd_month
      ,ROUND( xmgp.grant_point_condition_price / 1000 )  -- |Cgt^ðàziPÊFç~j¬_PðlÌÜü
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
      ,fnd_lookup_values         cflv    -- ÚqÆÔ¼æ¾p
      ,fnd_lookup_values         pflv    -- |Cgt^ð¼æ¾p
      ,xxcsm_process_date_v      xpcdv
 WHERE cflv.lookup_code  = xmgp.custom_condition_cd    -- ÚqÆÔ¼æ¾poð
   AND cflv.language     = USERENV('LANG')
   AND cflv.lookup_type  = 'XXCSM1_TYPE_OF_INDUSTRY'
   AND cflv.enabled_flag = 'Y'
   AND NVL(cflv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
   AND NVL(cflv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
   AND pflv.lookup_code  = xmgp.grant_condition_point   -- |Cgt^ð¼æ¾poð
   AND pflv.language     = USERENV('LANG')
   AND pflv.lookup_type  = 'XXCSM1_GRANT_CONDITION_POINT'
   AND pflv.enabled_flag = 'Y'
   AND NVL(pflv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
   AND NVL(pflv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date;
--
COMMENT ON COLUMN xxcsm_mst_grant_point_v.row_id                        IS 'qnvQhc';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.subject_year                  IS 'ÎÛNx';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.post_cd                       IS 'R[h';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.duties_cd                     IS 'E±R[h';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.custom_condition_cd           IS 'ÚqÆÔR[h';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.custom_condition_name         IS 'ÚqÆÔ¼';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_condition_point         IS '|Cgt^ð';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_condition_point_name    IS '|Cgt^ð¼';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_point_target_1st_month  IS '|Cgt^ðÎÛ_';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_point_target_2nd_month  IS '|Cgt^ðÎÛ_';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_point_target_3rd_month  IS '|Cgt^ðÎÛ_X';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.grant_point_condition_price   IS '|Cgt^ðàz';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.created_by                    IS 'ì¬Ò';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.creation_date                 IS 'ì¬ú';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.last_updated_by               IS 'ÅIXVÒ';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.last_update_date              IS 'ÅIXVú';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.last_update_login             IS 'ÅIXVOCID';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.request_id                    IS 'vID';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.program_application_id        IS 'vOAvP[VID';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.program_id                    IS 'vOID';
COMMENT ON COLUMN xxcsm_mst_grant_point_v.program_update_date           IS 'vOXVú';
--
COMMENT ON TABLE  xxcsm_mst_grant_point_v IS '|Cgt^ð}X^r[';
