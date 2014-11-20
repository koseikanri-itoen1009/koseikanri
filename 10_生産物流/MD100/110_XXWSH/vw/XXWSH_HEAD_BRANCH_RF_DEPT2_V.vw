CREATE OR REPLACE VIEW xxwsh_head_branch_rf_dept2_v
(
  user_id,
  party_number,
  party_short_name
)
AS
  SELECT fu.user_id
        ,prty.party_number
        ,prty.party_short_name
  FROM fnd_user fu
      ,per_all_people_f papf
      ,per_all_assignments_f paaf
      ,xxcmn_locations_v xlv
      ,(SELECT '1'                   AS other_shipment_div
              ,NULL                  AS user_id
              ,xcav.party_number     AS party_number
              ,xcav.party_short_name AS  party_short_name
       FROM xxcmn_cust_accounts3_v xcav
       WHERE xcav.customer_class_code = '1'
       UNION ALL
       SELECT NVL(xlv.other_shipment_div,'0') AS other_shipment_div
              ,fu.user_id                     AS user_id
              ,xcav.party_number              AS party_number
              ,xcav.party_short_name          AS  party_short_name
       FROM fnd_user fu
           ,per_all_people_f papf
           ,per_all_assignments_f paaf
           ,xxcmn_locations_v xlv
           ,xxcmn_cust_accounts3_v xcav
       WHERE fu.employee_id = papf.person_id 
       AND   papf.person_id = paaf.person_id 
       AND   (paaf.effective_start_date IS NULL OR paaf.effective_start_date <= TRUNC(SYSDATE))
       AND   (paaf.effective_end_date IS NULL OR paaf.effective_end_date >= TRUNC(SYSDATE))
       AND   (papf.effective_start_date IS NULL OR papf.effective_start_date <= TRUNC(SYSDATE))
       AND   (papf.effective_end_date IS NULL OR papf.effective_end_date >= TRUNC(SYSDATE))
       AND   paaf.location_id = xlv.location_id 
       AND   (xlv.other_shipment_div IS NULL OR xlv.other_shipment_div = '0')
       AND   xlv.location_code = xcav.party_number) prty
  WHERE fu.employee_id = papf.person_id 
  AND   papf.person_id = paaf.person_id
  AND   (paaf.effective_start_date IS NULL OR paaf.effective_start_date <= TRUNC(SYSDATE))
  AND   (paaf.effective_end_date IS NULL OR paaf.effective_end_date >= TRUNC(SYSDATE))
  AND   (papf.effective_start_date IS NULL OR papf.effective_start_date <= TRUNC(SYSDATE))
  AND   (papf.effective_end_date IS NULL OR papf.effective_end_date >= TRUNC(SYSDATE))
  AND   paaf.location_id = xlv.location_id 
  AND   ((xlv.other_shipment_div = '1'
         AND xlv.other_shipment_div = prty.other_shipment_div)
         OR
        (NVL(xlv.other_shipment_div,'0') = '0'
         AND NVL(xlv.other_shipment_div,'0') = prty.other_shipment_div
         AND xlv.location_code = prty.party_number
         AND fu.user_id = prty.user_id))
;
--
COMMENT ON COLUMN xxwsh_head_branch_rf_dept2_v.user_id          IS 'ユーザID';
COMMENT ON COLUMN xxwsh_head_branch_rf_dept2_v.party_number     IS '管轄拠点';
COMMENT ON COLUMN xxwsh_head_branch_rf_dept2_v.party_short_name IS '管轄拠点名称';
--
COMMENT ON TABLE  xxwsh_head_branch_rf_dept2_v IS '管轄拠点(部署情報参照)VIEW2';
