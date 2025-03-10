CREATE OR REPLACE VIEW XXCSM_DUTIES_LIST_V
(
  duties_cd
 ,duties_name
)
AS
  SELECT
    ppf.attribute15 duties_cd
   ,ppf.attribute16 duties_name
  FROM
    per_people_f           ppf
   ,per_periods_of_service ppos
   ,xxcsm_process_date_v   xpcdv
   ,(SELECT fpov.profile_option_value duties_cd
     FROM   fnd_profile_options       fpo
           ,fnd_profile_option_values fpov
     WHERE  fpo.profile_option_id = fpov.profile_option_id
     AND    fpo.profile_option_name = 'XXCSM1_NO_DUTIES_NAME'
     AND    fpo.application_id = fpov.application_id
    ) prof_v
  WHERE ppf.attribute15 IS NOT NULL
    AND (ppf.attribute16 IS NOT NULL
         OR ppf.attribute15 = prof_v.duties_cd)
    AND ppf.person_id = ppos.person_id
    AND (ppos.actual_termination_date IS NULL
         OR ppos.actual_termination_date > xpcdv.process_date)
  UNION
  SELECT
    ppf.attribute17 duties_cd
   ,ppf.attribute18 duties_name
  FROM
    per_people_f           ppf
   ,per_periods_of_service ppos
   ,xxcsm_process_date_v   xpcdv
   ,(SELECT fpov.profile_option_value duties_cd
     FROM   fnd_profile_options       fpo
           ,fnd_profile_option_values fpov
     WHERE  fpo.profile_option_id = fpov.profile_option_id
     AND    fpo.profile_option_name = 'XXCSM1_NO_DUTIES_NAME'
     AND    fpo.application_id = fpov.application_id
    ) prof_v
  WHERE ppf.attribute17 IS NOT NULL
    AND (ppf.attribute18 IS NOT NULL
         OR ppf.attribute17 = prof_v.duties_cd)
    AND ppf.person_id = ppos.person_id
    AND (ppos.actual_termination_date IS NULL
         OR ppos.actual_termination_date > xpcdv.process_date)
;
--
COMMENT ON COLUMN xxcsm_duties_list_v.duties_cd   IS '�E���R�[�h';
COMMENT ON COLUMN xxcsm_duties_list_v.duties_name IS '�E����';
--
COMMENT ON TABLE  xxcsm_duties_list_v IS '�E���ꗗ�r���[';
