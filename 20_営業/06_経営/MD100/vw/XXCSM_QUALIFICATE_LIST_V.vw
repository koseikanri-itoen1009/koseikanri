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
;
--
COMMENT ON COLUMN xxcsm_qualificate_list_v.qualificate_cd   IS '資格コード';
COMMENT ON COLUMN xxcsm_qualificate_list_v.qualificate_name IS '資格名';
--
COMMENT ON TABLE  xxcsm_qualificate_list_v IS '資格一覧ビュー';
