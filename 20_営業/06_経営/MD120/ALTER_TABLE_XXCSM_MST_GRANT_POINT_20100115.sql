ALTER TABLE xxcsm.xxcsm_mst_grant_point
  DROP CONSTRAINT xxcsm_mst_grant_point_pk
;

ALTER TABLE xxcsm.xxcsm_mst_grant_point
  ADD CONSTRAINT xxcsm_mst_grant_point_pk
  PRIMARY KEY (subject_year, post_cd, duties_cd, custom_condition_cd, grant_point_condition_price)
;
