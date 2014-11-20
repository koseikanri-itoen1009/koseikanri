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
  WHERE ppf.attribute15 IS NOT NULL
    AND ppf.attribute16 IS NOT NULL
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
  WHERE ppf.attribute17 IS NOT NULL
    AND ppf.attribute18 IS NOT NULL
    AND ppf.person_id = ppos.person_id
    AND (ppos.actual_termination_date IS NULL
         OR ppos.actual_termination_date > xpcdv.process_date)
;
--
COMMENT ON COLUMN xxcsm_duties_list_v.duties_cd   IS '職務コード';
COMMENT ON COLUMN xxcsm_duties_list_v.duties_name IS '職務名';
--
COMMENT ON TABLE  xxcsm_duties_list_v IS '職務一覧ビュー';
