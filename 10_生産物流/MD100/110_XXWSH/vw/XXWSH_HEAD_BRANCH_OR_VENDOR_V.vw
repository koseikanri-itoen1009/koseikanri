CREATE OR REPLACE VIEW xxwsh_head_branch_or_vendor_v
(
  biz_type,
  party_vendor_number,
  party_vendor_short_name,
  category
)
AS
  SELECT '1', --'o× _'
         xcav.party_number,
         xcav.party_short_name,
         '_'
-- ***** #1648 2009/10/7 S *****
--  FROM xxcmn_cust_accounts_v xcav
  FROM xxcmn_cust_accounts3_v xcav
-- ***** #1648 2009/10/7 E *****
  WHERE xcav.customer_class_code = '1'
  UNION
  SELECT '2', --'x æøæ'
         xvv.segment1,
         xvv.vendor_short_name,
         'æøæ'
  FROM xxcmn_vendors_v xvv
;
--
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.biz_type                IS 'Æ±íÊ';
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.party_vendor_number     IS 'Ç_/æøæ';
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.party_vendor_short_name IS 'Ç_/æøæ¼Ì';
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.category                IS 'ªÞ';
--
COMMENT ON TABLE  xxwsh_head_branch_or_vendor_v IS 'Ç_/æøæVIEW';
