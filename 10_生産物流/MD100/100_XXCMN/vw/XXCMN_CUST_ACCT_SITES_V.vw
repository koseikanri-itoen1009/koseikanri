CREATE OR REPLACE VIEW xxcmn_cust_acct_sites_v
(
  party_site_id,
  party_id,
  location_id,
  party_site_number,
  party_site_name,
  recept_date,
  cust_account_id,
  cust_acct_site_id,
  drink_calender,
  jpr_user_code,
  prefecture_code,
  num_of_vehicle,
  appoint_item_div,
  sub_lift_div,
  sub_slip_div,
  sub_palette_move_div,
  sub_pack_div,
  sub_palette_div,
  rule_div,
  pileup_div,
  pass_permit_div,
  enter_permit_div,
  vehicle_div,
  contact_at_delivery_div,
  department_code,
  ship_to_no,
  leaf_calender,
  spare2,
  site_use_id,
  site_use_code,
  primary_flag,
  start_date_active,
  end_date_active,
  base_code,
  party_site_full_name,
  party_site_short_name,
  party_site_name_alt,
  zip,
  address_line1,
  address_line2,
  phone,
  fax,
  freshness_condition
)
AS
  SELECT  hps.party_site_id,
          hps.party_id,
          hps.location_id,
          hzl.province,
          hzl.county,
          hps.attribute20,
          hcas.cust_account_id,
          hcas.cust_acct_site_id,
          hcas.attribute1,
          hcas.attribute2,
          hcas.attribute3,
          hcas.attribute4,
          hcas.attribute5,
          hcas.attribute6,
          hcas.attribute7,
          hcas.attribute8,
          hcas.attribute9,
          hcas.attribute10,
          hcas.attribute11,
          hcas.attribute12,
          hcas.attribute13,
          hcas.attribute14,
          hcas.attribute15,
          hcas.attribute16,
          hcas.attribute17,
          hzl.province,
          hcas.attribute19,
          hcas.attribute20,
          hcsu.site_use_id,
          hcsu.site_use_code,
          hcsu.primary_flag,
          xps.start_date_active,
          xps.end_date_active,
          xps.base_code,
          xps.party_site_name,
          xps.party_site_short_name,
          xps.party_site_name_alt,
          xps.zip,
          xps.address_line1,
          xps.address_line2,
          xps.phone,
          xps.fax,
          xps.freshness_condition
  FROM    hz_party_sites          hps,
          hz_cust_acct_sites_all  hcas,
          hz_cust_site_uses_all   hcsu,
          xxcmn_party_sites       xps,
          hz_locations            hzl
  WHERE   hps.party_site_id       = hcas.party_site_id
  AND     hcas.org_id             = FND_PROFILE.VALUE('ORG_ID')
  AND     hcas.cust_acct_site_id  = hcsu.cust_acct_site_id
  AND     hps.party_site_id       = xps.party_site_id
  AND     hps.party_id            = xps.party_id
  AND     hps.location_id         = xps.location_id
  AND     hps.status              = 'A'
  AND     hcas.status             = 'A'
  AND     hcsu.site_use_code      = 'SHIP_TO'
  AND     hcsu.status             = 'A'
  AND     xps.start_date_active   <= TRUNC(SYSDATE)
  AND     xps.end_date_active     >= TRUNC(SYSDATE)
  AND     hps.location_id         = hzl.location_id
;
--
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_id                 IS 'p[eBTCgID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_id                      IS 'p[eB[ID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.location_id                   IS 'P[VID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_number             IS 'TCgÔ';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_name               IS 'TCg¼';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.recept_date                   IS '}X^óMú';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.cust_account_id               IS 'ÚqID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.cust_acct_site_id             IS 'ÚqTCgID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.drink_calender                IS 'hNîJ_';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.jpr_user_code                 IS 'JPR[UR[h';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.prefecture_code               IS 's¹{§R[h';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.num_of_vehicle                IS 'ÅåüÉÔçq';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.appoint_item_div              IS 'wèÚæª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.sub_lift_div                  IS 'tÑÆ±tgæª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.sub_slip_div                  IS 'tÑÆ±êp`[æª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.sub_palette_move_div          IS 'tÑÆ±pbgÏÖæª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.sub_pack_div                  IS 'tÑÆ±×¢æª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.sub_palette_div               IS 'tÑÆ±êppbgJSæª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.rule_div                      IS '[æª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.pileup_div                    IS 'iÏAÂÛæª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.pass_permit_div               IS 'ÊsÂØæª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.enter_permit_div              IS 'üêÂØæª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.vehicle_div                   IS 'Ôçqwèæª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.contact_at_delivery_div       IS '[iAæª';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.department_code               IS 'R[h';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.ship_to_no                    IS 'zæÔ';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.leaf_calender                 IS '[tîJ_';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.spare2                        IS '\õ2';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.site_use_id                   IS 'gpÚIID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.site_use_code                 IS 'gpÚIR[h';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.primary_flag                  IS 'åtO';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.start_date_active             IS 'KpJnú';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.end_date_active               IS 'KpI¹ú';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.base_code                     IS '_R[h';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_full_name          IS '³®¼';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_short_name         IS 'ªÌ';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_name_alt           IS 'Ji¼';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.zip                           IS 'XÖÔ';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.address_line1                 IS 'ZP';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.address_line2                 IS 'ZQ';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.phone                         IS 'dbÔ';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.fax                           IS 'FAXÔ';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.freshness_condition           IS 'Nxð';
--
COMMENT ON TABLE  xxcmn_cust_acct_sites_v IS 'ÚqTCgîñVIEW';
