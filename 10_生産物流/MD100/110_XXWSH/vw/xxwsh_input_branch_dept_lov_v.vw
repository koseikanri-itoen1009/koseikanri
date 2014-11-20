CREATE OR REPLACE VIEW xxwsh_input_branch_dept_lov_v
(
  code,
  name
)
AS
  SELECT xca.party_number
        ,xca.party_short_name
  FROM   xxcmn_cust_accounts_v xca
  WHERE  xca.customer_class_code='1'
  UNION ALL
  SELECT  xlv.location_code
         ,xlv.location_short_name
  FROM    xxcmn_locations_v xlv
  WHERE   xlv.parent_location_id    <> xlv.location_id
;
--
COMMENT ON COLUMN xxwsh_input_branch_dept_lov_v.code    IS '���_/����';
COMMENT ON COLUMN xxwsh_input_branch_dept_lov_v.name    IS '���_/��������';
--
COMMENT ON TABLE  xxwsh_input_branch_dept_lov_v IS '���_/����LOV�pVIEW';
