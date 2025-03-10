CREATE OR REPLACE VIEW xxcmn_locations_v
(
  location_id,
  location_code,
  description,
  ship_mng_code,
  purchase_role_flag,
  ship_role_flag,
  role1,
  role2,
  role3,
  role4,
  role5,
  role6,
  role7,
  role8,
  role9,
  role10,
  parent_location_id,
  spare1,
  spare2,
  block_name,
  other_shipment_div,
  start_date_active,
  end_date_active,
  location_name,
  location_short_name,
  location_name_alt,
  zip,
  address_line1,
  phone,
  fax,
  division_code
)
AS
  SELECT  hl.location_id,
          hl.location_code,
          hl.description,
          hl.attribute1,
          hl.attribute3,
          hl.attribute4,
          hl.attribute5,
          hl.attribute6,
          hl.attribute7,
          hl.attribute8,
          hl.attribute9,
          hl.attribute10,
          hl.attribute11,
          hl.attribute12,
          hl.attribute13,
          hl.attribute14,
          hl.attribute17,
          hl.attribute18,
          hl.attribute19,
          hl.attribute20,
          hl.attribute18,
          xl.start_date_active,
          xl.end_date_active,
          xl.location_name,
          xl.location_short_name,
          xl.location_name_alt,
          xl.zip,
          xl.address_line1,
          xl.phone,
          xl.fax,
          xl.division_code
  FROM    hr_locations_all    hl,
          xxcmn_locations_all xl
  WHERE   hl.location_id        = xl.location_id
  AND     hl.inactive_date      IS NULL
  AND     xl.start_date_active  <= TRUNC(SYSDATE)
  AND     xl.end_date_active    >= TRUNC(SYSDATE)
;
--
COMMENT ON COLUMN xxcmn_locations_v.location_id          IS 'ÆID';
COMMENT ON COLUMN xxcmn_locations_v.location_code        IS 'ÆR[h';
COMMENT ON COLUMN xxcmn_locations_v.description          IS 'Ev';
COMMENT ON COLUMN xxcmn_locations_v.ship_mng_code        IS 'o×Ç³æª';
COMMENT ON COLUMN xxcmn_locations_v.purchase_role_flag   IS 'wStO';
COMMENT ON COLUMN xxcmn_locations_v.ship_role_flag       IS 'o×StO';
COMMENT ON COLUMN xxcmn_locations_v.role1                IS 'SEÓ1';
COMMENT ON COLUMN xxcmn_locations_v.role2                IS 'SEÓ2';
COMMENT ON COLUMN xxcmn_locations_v.role3                IS 'SEÓ3';
COMMENT ON COLUMN xxcmn_locations_v.role4                IS 'SEÓ4';
COMMENT ON COLUMN xxcmn_locations_v.role5                IS 'SEÓ5';
COMMENT ON COLUMN xxcmn_locations_v.role6                IS 'SEÓ6';
COMMENT ON COLUMN xxcmn_locations_v.role7                IS 'SEÓ7';
COMMENT ON COLUMN xxcmn_locations_v.role8                IS 'SEÓ8';
COMMENT ON COLUMN xxcmn_locations_v.role9                IS 'SEÓ9';
COMMENT ON COLUMN xxcmn_locations_v.role10               IS 'SEÓ10';
COMMENT ON COLUMN xxcmn_locations_v.parent_location_id   IS 'eÆID';
COMMENT ON COLUMN xxcmn_locations_v.spare1               IS '\õ1';
COMMENT ON COLUMN xxcmn_locations_v.spare2               IS '\õ2';
COMMENT ON COLUMN xxcmn_locations_v.block_name           IS 'næ¼';
COMMENT ON COLUMN xxcmn_locations_v.other_shipment_div   IS '¼_o×Ëì¬ÂÛæª';
COMMENT ON COLUMN xxcmn_locations_v.start_date_active    IS 'KpJnú';
COMMENT ON COLUMN xxcmn_locations_v.end_date_active      IS 'KpI¹ú';
COMMENT ON COLUMN xxcmn_locations_v.location_name        IS '³®¼';
COMMENT ON COLUMN xxcmn_locations_v.location_short_name  IS 'ªÌ';
COMMENT ON COLUMN xxcmn_locations_v.location_name_alt    IS 'Ji¼';
COMMENT ON COLUMN xxcmn_locations_v.zip                  IS 'XÖÔ';
COMMENT ON COLUMN xxcmn_locations_v.address_line1        IS 'Z';
COMMENT ON COLUMN xxcmn_locations_v.phone                IS 'dbÔ';
COMMENT ON COLUMN xxcmn_locations_v.fax                  IS 'FAXÔ';
COMMENT ON COLUMN xxcmn_locations_v.division_code        IS '{R[h';
--
COMMENT ON TABLE  xxcmn_locations_v IS 'ÆîñVIEW';
