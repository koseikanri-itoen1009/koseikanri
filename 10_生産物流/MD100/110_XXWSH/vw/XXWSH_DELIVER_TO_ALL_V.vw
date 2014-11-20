CREATE OR REPLACE VIEW xxwsh_deliver_to_all_v
(
  biz_type,
  deliver_to,
  deliver_to_name,
  category
)
AS
  SELECT '1',
         xcasv.ship_to_no,
         xcasv.party_site_full_name,
         '配送先'
  FROM xxcmn_cust_acct_sites_v xcasv
  UNION
  SELECT '2',
         xvsv.vendor_site_code,
         xvsv.vendor_site_short_name,
         '支給先'
  FROM xxcmn_vendor_sites_v xvsv
  UNION
  SELECT '3',
         xilv.segment1,
         xilv.description,
         '倉庫'
  FROM xxcmn_item_locations_v xilv
;
--
COMMENT ON COLUMN xxwsh_deliver_to_all_v.biz_type          IS '業務種別';
COMMENT ON COLUMN xxwsh_deliver_to_all_v.deliver_to        IS '配送先';
COMMENT ON COLUMN xxwsh_deliver_to_all_v.deliver_to_name   IS '配送先名';
COMMENT ON COLUMN xxwsh_deliver_to_all_v.category          IS '分類';
--
COMMENT ON TABLE  xxwsh_deliver_to_all_v IS '配送先/入庫先情報(全て)VIEW';
