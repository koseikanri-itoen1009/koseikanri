CREATE OR REPLACE VIEW APPS.XXSKY_VENDOR_SITES2_V
(
 VENDOR_SITE_ID
,VENDOR_ID
,VENDOR_SITE_CODE
,VENDOR_SITE_NAME
,VENDOR_SITE_SHORT_NAME
,INACTIVE_DATE
,START_DATE_ACTIVE
,END_DATE_ACTIVE
)
AS
SELECT  PVS.vendor_site_id
       ,PVS.vendor_id
       ,PVS.vendor_site_code
       ,XVS.vendor_site_name
       ,XVS.vendor_site_short_name
       ,PVS.inactive_date
       ,XVS.start_date_active
       ,XVS.end_date_active
  FROM  po_vendor_sites_all       PVS
       ,xxcmn_vendor_sites_all    XVS
 WHERE  PVS.vendor_site_id = XVS.vendor_site_id
   AND  PVS.vendor_id      = XVS.vendor_id
   AND  PVS.org_id         = FND_PROFILE.VALUE('ORG_ID')
   AND   PVS.inactive_date IS NULL
/
COMMENT ON TABLE APPS.XXSKY_VENDOR_SITES2_V IS 'SKYLINK�p����VIEW �d����T�C�g���VIEW2'
/
COMMENT ON COLUMN APPS.XXSKY_VENDOR_SITES2_V.VENDOR_SITE_ID         IS '�d����T�C�gID'
/
COMMENT ON COLUMN APPS.XXSKY_VENDOR_SITES2_V.VENDOR_ID              IS '�d����ID'
/
COMMENT ON COLUMN APPS.XXSKY_VENDOR_SITES2_V.VENDOR_SITE_CODE       IS '�d����T�C�g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_VENDOR_SITES2_V.VENDOR_SITE_NAME       IS '�d����T�C�g��'
/
COMMENT ON COLUMN APPS.XXSKY_VENDOR_SITES2_V.VENDOR_SITE_SHORT_NAME IS '�d����T�C�g�Z�k��'
/
COMMENT ON COLUMN APPS.XXSKY_VENDOR_SITES2_V.INACTIVE_DATE          IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_VENDOR_SITES2_V.START_DATE_ACTIVE      IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_VENDOR_SITES2_V.END_DATE_ACTIVE        IS '�K�p�I����'
/
