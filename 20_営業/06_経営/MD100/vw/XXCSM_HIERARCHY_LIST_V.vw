CREATE OR REPLACE VIEW XXCSM_HIERARCHY_LIST_V
(
  hierarchy_code
 ,hierarchy_name
)
AS
  SELECT ffv.flex_value      base_code
        ,ffvt.description    base_name
  FROM   fnd_flex_value_sets ffvs
        ,fnd_flex_values    ffv
        ,fnd_flex_values_tl ffvt
        ,xxcsm_process_date_v  xpcdv
  WHERE  ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
  AND    ffvs.flex_value_set_id = ffv.flex_value_set_id
  AND    ffv.flex_value_id = ffvt.flex_value_id
  AND    ffvt.language = USERENV('LANG')
  AND    ffv.enabled_flag = 'Y'
  AND    (ffv.start_date_active <= xpcdv.process_date
          OR ffv.start_date_active IS NULL)
  AND    (ffv.end_date_active >= xpcdv.process_date
          OR ffv.end_date_active IS NULL)
  AND    exists (SELECT 'X'
                 FROM   fnd_lookup_values  flv                      --�N�C�b�N�R�[�h�l
                 WHERE  flv.lookup_type = 'XXCSM1_CALC_POINT_LEVEL'    --�R�[�h�^�C�v:�|�C���g�Z�o�p�����K�w���w��������i�hXXCSM1_CALC_POINT_LEVEL�h�j
                 AND    flv.language    = 'JA'                         --����
                 AND    NVL(flv.start_date_active,sysdate) <= sysdate    --�L���J�n��<=�Ɩ����t
                 AND    NVL(flv.end_date_active,sysdate) >= sysdate      --�L���I����>=�Ɩ����t
                 AND    flv.enabled_flag = 'Y'
                 AND    flv.lookup_code =  ffv.hierarchy_level)         --�ŉ��w���x�����Q�ƃ^�C�v�ŕԂ��Ă����l
;
--
COMMENT ON COLUMN xxcsm_hierarchy_list_v.hierarchy_code    IS '����R�[�h';
COMMENT ON COLUMN xxcsm_hierarchy_list_v.hierarchy_name    IS '���喼��';
--
COMMENT ON TABLE  xxcsm_hierarchy_list_v IS '���i�|�C���g����ꗗ�r���[';
/
