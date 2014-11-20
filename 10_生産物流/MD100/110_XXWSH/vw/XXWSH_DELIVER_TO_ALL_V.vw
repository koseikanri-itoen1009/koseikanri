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
         '�z����'
  FROM xxcmn_cust_acct_sites_v xcasv
  UNION
  SELECT '2',
         xvsv.vendor_site_code,
         xvsv.vendor_site_short_name,
         '�x����'
  FROM xxcmn_vendor_sites_v xvsv
  UNION
  SELECT '3',
         xilv.segment1,
         xilv.description,
         '�q��'
  FROM xxcmn_item_locations_v xilv
;
--
COMMENT ON COLUMN xxwsh_deliver_to_all_v.biz_type          IS '�Ɩ����';
COMMENT ON COLUMN xxwsh_deliver_to_all_v.deliver_to        IS '�z����';
COMMENT ON COLUMN xxwsh_deliver_to_all_v.deliver_to_name   IS '�z���於';
COMMENT ON COLUMN xxwsh_deliver_to_all_v.category          IS '����';
--
COMMENT ON TABLE  xxwsh_deliver_to_all_v IS '�z����/���ɐ���(�S��)VIEW';
