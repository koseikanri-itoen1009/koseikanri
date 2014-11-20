CREATE OR REPLACE VIEW XXCSM_LOCATION_ALL_V
(
  location_cd
 ,location_nm
)
AS
  SELECT xlnlv.base_code  location_cd
        ,xlnlv.base_name  location_nm
  FROM   xxcsm_loc_name_list_v xlnlv
  WHERE  EXISTS (SELECT 'X'
                 FROM   xxcsm_item_plan_result xipr
                 WHERE  xlnlv.base_code = xipr.location_cd)
  UNION ALL
  SELECT flv.lookup_code  location_cd  --"1"
        ,flv.meaning      location_nm  --�S���_
  FROM   fnd_lookup_values flv
        ,xxcsm_process_date_v  xpcdv
  WHERE  flv.lookup_type = 'XXCSM1_FORM_PARAMETER_VALUE'
  AND    flv.language = USERENV('LANG')
  AND    flv.enabled_flag = 'Y'
  AND    NVL(flv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
  AND    NVL(flv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
  ;
--
COMMENT ON COLUMN xxcsm_location_all_v.location_cd           IS '���_�R�[�h';
COMMENT ON COLUMN xxcsm_location_all_v.location_nm           IS '���_��';
--                
COMMENT ON TABLE  xxcsm_location_all_v IS '�e���_+�u�S���_�v�r���[';
                  
