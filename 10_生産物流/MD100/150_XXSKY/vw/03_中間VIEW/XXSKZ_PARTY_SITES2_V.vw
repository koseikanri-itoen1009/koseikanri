/*************************************************************************
 * 
 * View  Name      : XXSKZ_PARTY_SITES2_V
 * Description     : XXSKZ_PARTY_SITES2_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_PARTY_SITES2_V
(
 PARTY_SITE_ID
,PARTY_ID
,LOCATION_ID
,PARTY_SITE_NUMBER
,PARTY_SITE_NAME
,PARTY_SITE_SHORT_NAME
,STATUS
,START_DATE_ACTIVE
,END_DATE_ACTIVE
)
AS
SELECT  XPS.party_site_id
       ,XPS.party_id
       ,XPS.location_id
       ,HZL.province
       ,XPS.party_site_name
       ,XPS.party_site_short_name
       ,HPS.status
       ,XPS.start_date_active
       ,XPS.end_date_active
  FROM  XXCMN.xxcmn_party_sites XPS
       ,hz_party_sites       HPS
       ,hz_locations         HZL
 WHERE  HPS.status = 'A'
   AND  XPS.party_site_id = HPS.party_site_id
   AND  XPS.party_id      = HPS.party_id
   AND  XPS.location_id   = HPS.location_id
   AND  HPS.location_id   = HZL.location_id
/
COMMENT ON TABLE APPS.XXSKZ_PARTY_SITES2_V IS 'SKYLINK用中間VIEW 配送先情報VIEW2'
/
COMMENT ON COLUMN APPS.XXSKZ_PARTY_SITES2_V.PARTY_SITE_ID        IS 'パーティサイトID'
/
COMMENT ON COLUMN APPS.XXSKZ_PARTY_SITES2_V.PARTY_ID             IS 'パーティID'
/
COMMENT ON COLUMN APPS.XXSKZ_PARTY_SITES2_V.LOCATION_ID          IS 'ロケーションID'
/
COMMENT ON COLUMN APPS.XXSKZ_PARTY_SITES2_V.PARTY_SITE_NUMBER    IS '配送先番号'
/
COMMENT ON COLUMN APPS.XXSKZ_PARTY_SITES2_V.PARTY_SITE_NAME      IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_PARTY_SITES2_V.PARTY_SITE_SHORT_NAME IS '配送先短縮名'
/
COMMENT ON COLUMN APPS.XXSKZ_PARTY_SITES2_V.STATUS               IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_PARTY_SITES2_V.START_DATE_ACTIVE    IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_PARTY_SITES2_V.END_DATE_ACTIVE      IS '適用終了日'
/
