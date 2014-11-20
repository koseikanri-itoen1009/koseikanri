CREATE OR REPLACE VIEW xxwsh_head_branch_or_vendor_v
(
  biz_type,
  party_vendor_number,
  party_vendor_short_name,
  category
)
AS
  SELECT '1', --'出荷 拠点'
         xcav.party_number,
         xcav.party_short_name,
         '拠点'
-- ***** #1648 2009/10/7 S *****
--  FROM xxcmn_cust_accounts_v xcav
  FROM xxcmn_cust_accounts3_v xcav
-- ***** #1648 2009/10/7 E *****
  WHERE xcav.customer_class_code = '1'
  UNION
  SELECT '2', --'支給 取引先'
         xvv.segment1,
         xvv.vendor_short_name,
         '取引先'
  FROM xxcmn_vendors_v xvv
;
--
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.biz_type                IS '業務種別';
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.party_vendor_number     IS '管轄拠点/取引先';
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.party_vendor_short_name IS '管轄拠点/取引先名称';
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.category                IS '分類';
--
COMMENT ON TABLE  xxwsh_head_branch_or_vendor_v IS '管轄拠点/取引先VIEW';
