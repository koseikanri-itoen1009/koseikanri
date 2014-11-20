CREATE OR REPLACE VIEW XXCSM_QUALIFICATE_LIST_V
(
  qualificate_cd
 ,qualificate_name
)
AS
  SELECT
    ppf.attribute7  qualificate_cd 
   ,ppf.attribute8  qualificate_name
  FROM
    per_people_f ppf
   ,per_periods_of_service ppos
   ,xxcsm_process_date_v   xpcdv
  WHERE ppf.attribute7 IS NOT NULL
    AND ppf.attribute8 IS NOT NULL
    AND ppf.person_id = ppos.person_id
    AND (ppos.actual_termination_date IS NULL
         OR ppos.actual_termination_date > xpcdv.process_date)
    AND  EXISTS (SELECT 'X'
                 FROM   fnd_lookup_values  flv                      --�N�C�b�N�R�[�h�l
                       ,xxcsm_process_date_v   xpcdv2
                 WHERE  flv.lookup_type = 'XXCSM1_POINT_COUNTCD'
                 AND    flv.language    = 'JA'                      --����
                 AND    NVL(flv.start_date_active,xpcdv2.process_date) <= xpcdv2.process_date    --�L���J�n��<=�Ɩ����t
                 AND    NVL(flv.end_date_active,xpcdv2.process_date) >= xpcdv2.process_date      --�L���I����>=�Ɩ����t
                 AND    flv.enabled_flag = 'Y'
                 AND    flv.lookup_code =  ppf.attribute7)
  UNION
  SELECT
    ppf.attribute9  qualificate_cd 
   ,ppf.attribute10 qualificate_name
  FROM
    per_people_f ppf
   ,per_periods_of_service ppos
   ,xxcsm_process_date_v   xpcdv
  WHERE ppf.attribute9  IS NOT NULL
    AND ppf.attribute10 IS NOT NULL
    AND ppf.person_id = ppos.person_id
    AND (ppos.actual_termination_date IS NULL
         OR ppos.actual_termination_date > xpcdv.process_date)
    AND  EXISTS (SELECT 'X'
                 FROM   fnd_lookup_values  flv                      --�N�C�b�N�R�[�h�l
                       ,xxcsm_process_date_v   xpcdv2
                 WHERE  flv.lookup_type = 'XXCSM1_POINT_COUNTCD'
                 AND    flv.language    = 'JA'                      --����
                 AND    NVL(flv.start_date_active,xpcdv2.process_date) <= xpcdv2.process_date    --�L���J�n��<=�Ɩ����t
                 AND    NVL(flv.end_date_active,xpcdv2.process_date) >= xpcdv2.process_date      --�L���I����>=�Ɩ����t
                 AND    flv.enabled_flag = 'Y'
                 AND    flv.lookup_code =  ppf.attribute9)
;
--
COMMENT ON COLUMN xxcsm_qualificate_list_v.qualificate_cd   IS '���i�R�[�h';
COMMENT ON COLUMN xxcsm_qualificate_list_v.qualificate_name IS '���i��';
--
COMMENT ON TABLE  xxcsm_qualificate_list_v IS '���i�ꗗ�r���[';
