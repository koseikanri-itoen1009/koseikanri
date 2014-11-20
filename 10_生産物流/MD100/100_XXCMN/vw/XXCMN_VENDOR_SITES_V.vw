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
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_site_id          IS '�d����T�C�gID';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_id               IS '�d����ID';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_site_code        IS '�d����T�C�g��';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_stock_whse       IS '�����݌ɓ��ɐ�';
COMMENT ON COLUMN xxcmn_vendor_sites_v.delivery_whse           IS '�����[����';
COMMENT ON COLUMN xxcmn_vendor_sites_v.memo                    IS '���l';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare1                  IS '�\��1';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare2                  IS '�\��2';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare3                  IS '�\��3';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare4                  IS '�\��4';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare5                  IS '�\��5';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare6                  IS '�\��6';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare7                  IS '�\��7';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare8                  IS '�\��8';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare9                  IS '�\��9';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare10                 IS '�\��10';
COMMENT ON COLUMN xxcmn_vendor_sites_v.spare11                 IS '�\��11';
COMMENT ON COLUMN xxcmn_vendor_sites_v.start_date_active       IS '�K�p�J�n��';
COMMENT ON COLUMN xxcmn_vendor_sites_v.end_date_active         IS '�K�p�I����';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_site_name        IS '������';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_site_short_name  IS '����';
COMMENT ON COLUMN xxcmn_vendor_sites_v.vendor_site_name_alt    IS '�J�i��';
COMMENT ON COLUMN xxcmn_vendor_sites_v.zip                     IS '�X�֔ԍ�';
COMMENT ON COLUMN xxcmn_vendor_sites_v.address_line1           IS '�Z���P';
COMMENT ON COLUMN xxcmn_vendor_sites_v.address_line2           IS '�Z���Q';
COMMENT ON COLUMN xxcmn_vendor_sites_v.phone                   IS '�d�b�ԍ�';
COMMENT ON COLUMN xxcmn_vendor_sites_v.fax                     IS 'FAX�ԍ�';
--
COMMENT ON TABLE  xxcmn_vendor_sites_v IS '�d����T�C�g���VIEW';
