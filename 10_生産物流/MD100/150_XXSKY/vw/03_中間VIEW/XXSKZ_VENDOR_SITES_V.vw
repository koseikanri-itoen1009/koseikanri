/*************************************************************************
 * 
 * View  Name      : XXSKZ_VENDOR_SITES_V
 * Description     : XXSKZ_VENDOR_SITES_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_VENDOR_SITES_V
(
 VENDOR_SITE_ID
,VENDOR_ID
,VENDOR_SITE_CODE
,VENDOR_SITE_NAME
,VENDOR_SITE_SHORT_NAME
,START_DATE_ACTIVE
,END_DATE_ACTIVE
)
AS
SELECT  PVS.vendor_site_id
       ,PVS.vendor_id
       ,PVS.vendor_site_code
       ,XVS.vendor_site_name
       ,XVS.vendor_site_short_name
       ,XVS.start_date_active
       ,XVS.end_date_active  
  FROM  po_vendor_sites_all     PVS
       ,xxcmn_vendor_sites_all  XVS
 WHERE  PVS.vendor_site_id    = XVS.vendor_site_id
  AND   PVS.vendor_id         = XVS.vendor_id
  AND   PVS.org_id            = FND_PROFILE.VALUE('ORG_ID')
  AND   PVS.inactive_date     IS NULL
  AND   XVS.start_date_active <= TRUNC(SYSDATE)
  AND   XVS.end_date_active   >= TRUNC(SYSDATE)
/
COMMENT ON TABLE APPS.XXSKZ_VENDOR_SITES_V IS 'SKYLINK用中間VIEW 仕入先サイト情報VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDOR_SITES_V.VENDOR_SITE_ID         IS '仕入先サイトID'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDOR_SITES_V.VENDOR_ID              IS '仕入先ID'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDOR_SITES_V.VENDOR_SITE_CODE       IS '仕入先サイトコード'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDOR_SITES_V.VENDOR_SITE_NAME       IS '仕入先サイト名'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDOR_SITES_V.VENDOR_SITE_SHORT_NAME IS '仕入先サイト短縮名'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDOR_SITES_V.START_DATE_ACTIVE      IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_VENDOR_SITES_V.END_DATE_ACTIVE        IS '適用終了日'
/
