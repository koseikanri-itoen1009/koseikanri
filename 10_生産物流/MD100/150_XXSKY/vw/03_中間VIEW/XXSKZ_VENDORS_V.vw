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
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
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
COMMENT ON TABLE APPS.XXSKZ_VENDORS_V IS 'SKYLINK用中間VIEW 仕入先情報VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.VENDOR_ID         IS '仕入先ID'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.SEGMENT1          IS '仕入先番号'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.VENDOR_NAME       IS '仕入先名'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.VENDOR_SHORT_NAME IS '仕入先短縮名'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.START_DATE_ACTIVE IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDORS_V.END_DATE_ACTIVE   IS '適用終了日'
/
