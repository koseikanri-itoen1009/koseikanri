CREATE OR REPLACE VIEW xxcmn_vendor_sites_v
(
  vendor_site_id,
  vendor_id,
  vendor_site_code,
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
  WHERE pvs.vendor_site_id      = xvs.vendor_site_id
  AND   pvs.vendor_id           = xvs.vendor_id
  AND   pvs.org_id              = FND_PROFILE.VALUE('ORG_ID')
  AND   pvs.inactive_date       IS NULL
  AND   xvs.start_date_active   <= TRUNC(SYSDATE)
  AND   xvs.end_date_active     >= TRUNC(SYSDATE)
;
--
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_site_id          IS '仕入先サイトID';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_id               IS '仕入先ID';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_site_code        IS '仕入先サイト名';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_stock_whse       IS '相手先在庫入庫先';
COMMENT ON COLUMN xxcmn_vendor_sites_v.delivery_whse           IS '発注納入先';
COMMENT ON COLUMN xxcmn_vendor_sites_v.memo                    IS '備考';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare1                  IS '予備1';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare2                  IS '予備2';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare3                  IS '予備3';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare4                  IS '予備4';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare5                  IS '予備5';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare6                  IS '予備6';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare7                  IS '予備7';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare8                  IS '予備8';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare9                  IS '予備9';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare10                 IS '予備10';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare11                 IS '予備11';
COMMENT ON COLUMN xxcmn_vendor_sites_v.start_date_active       IS '適用開始日';
COMMENT ON COLUMN xxcmn_vendor_sites_v.end_date_active         IS '適用終了日';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_site_name        IS '正式名';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_site_short_name  IS '略称';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_site_name_alt    IS 'カナ名';
COMMENT ON COLUMN xxcmn_vendor_sites_v.zip                     IS '郵便番号';
COMMENT ON COLUMN xxcmn_vendor_sites_v.address_line1           IS '住所１';
COMMENT ON COLUMN xxcmn_vendor_sites_v.address_line2           IS '住所２';
COMMENT ON COLUMN xxcmn_vendor_sites_v.phone                   IS '電話番号';
COMMENT ON COLUMN xxcmn_vendor_sites_v.fax                     IS 'FAX番号';
--
COMMENT ON TABLE  xxcmn_vendor_sites_v IS '仕入先サイト情報VIEW';
