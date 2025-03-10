CREATE OR REPLACE VIEW xxcmn_vendor_sites2_v
(
  vendor_site_id,
  vendor_id,
  vendor_site_code,
  inactive_date,
  vendor_stock_whse,
  delivery_whse,
  memo,
  spare1,
  spare2,
  spare3,
  spare4,
  spare5,
  spare6,
  spare7,
  spare8,
  spare9,
  spare10,
  spare11,
  start_date_active,
  end_date_active,
  vendor_site_name,
  vendor_site_short_name,
  vendor_site_name_alt,
  zip,
  address_line1,
  address_line2,
  phone,
  fax
)
AS
  SELECT  pvs.vendor_site_id,
          pvs.vendor_id,
          pvs.vendor_site_code,
          pvs.inactive_date,
          pvs.attribute1,
          pvs.attribute2,
          pvs.attribute4,
          pvs.attribute5,
          pvs.attribute6,
          pvs.attribute7,
          pvs.attribute8,
          pvs.attribute9,
          pvs.attribute10,
          pvs.attribute11,
          pvs.attribute12,
          pvs.attribute13,
          pvs.attribute14,
          pvs.attribute15,
          xvs.start_date_active,
          xvs.end_date_active,
          xvs.vendor_site_name,
          xvs.vendor_site_short_name,
          xvs.vendor_site_name_alt,
          xvs.zip,
          xvs.address_line1,
          xvs.address_line2,
          xvs.phone,
          xvs.fax
  FROM    po_vendor_sites_all     pvs,
          xxcmn_vendor_sites_all  xvs
  WHERE   pvs.vendor_site_id = xvs.vendor_site_id
  AND     pvs.vendor_id      = xvs.vendor_id
  AND     pvs.org_id         = FND_PROFILE.VALUE('ORG_ID')
;
--
COMMENT ON COLUMN xxcmn_vendor_sites2_v.vendor_site_id          IS 'düæTCgID';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.vendor_id               IS 'düæID';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.vendor_site_code        IS 'düæTCg¼';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.inactive_date           IS '³øú';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.vendor_stock_whse       IS 'èæÝÉüÉæ';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.delivery_whse           IS '­[üæ';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.memo                    IS 'õl';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare1                  IS '\õ1';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare2                  IS '\õ2';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare3                  IS '\õ3';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare4                  IS '\õ4';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare5                  IS '\õ5';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare6                  IS '\õ6';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare7                  IS '\õ7';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare8                  IS '\õ8';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare9                  IS '\õ9';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare10                 IS '\õ10';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.spare11                 IS '\õ11';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.start_date_active       IS 'KpJnú';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.end_date_active         IS 'KpI¹ú';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.vendor_site_name        IS '³®¼';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.vendor_site_short_name  IS 'ªÌ';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.vendor_site_name_alt    IS 'Ji¼';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.zip                     IS 'XÖÔ';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.address_line1           IS 'ZP';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.address_line2           IS 'ZQ';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.phone                   IS 'dbÔ';
COMMENT ON COLUMN xxcmn_vendor_sites2_v.fax                     IS 'FAXÔ';
--
COMMENT ON TABLE  xxcmn_vendor_sites2_v IS 'düæTCgîñVIEW2';
