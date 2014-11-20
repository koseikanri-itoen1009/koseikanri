/*************************************************************************
 * 
 * View  Name      : XXSKZ_VENDORS_V
 * Description     : XXSKZ_VENDORS_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_VENDORS_V
(
 VENDOR_ID
,SEGMENT1
,VENDOR_NAME
,VENDOR_SHORT_NAME
,START_DATE_ACTIVE
,END_DATE_ACTIVE
)
AS
SELECT  PV.vendor_id
       ,PV.segment1
       ,XV.vendor_name
       ,XV.vendor_short_name
       ,XV.start_date_active
       ,XV.end_date_active
  FROM  po_vendors      PV
       ,xxcmn_vendors   XV
 WHERE  PV.vendor_id = XV.vendor_id
   AND  PV.end_date_active IS NULL
   AND  XV.start_date_active <= TRUNC(SYSDATE)
   AND  XV.end_date_active   >= TRUNC(SYSDATE)
/
COMMENT ON TABLE APPS.XXSKZ_VENDORS_V IS 'SKYLINK�p����VIEW �d������VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.VENDOR_ID         IS '�d����ID'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.SEGMENT1          IS '�d����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.VENDOR_NAME       IS '�d���於'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.VENDOR_SHORT_NAME IS '�d����Z�k��'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.START_DATE_ACTIVE IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.END_DATE_ACTIVE   IS '�K�p�I����'
/
