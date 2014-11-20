CREATE OR REPLACE VIEW APPS.XXSKY_PARTY_SITES_V
(
 PARTY_SITE_ID
,PARTY_ID
,LOCATION_ID
,PARTY_SITE_NUMBER
,PARTY_SITE_NAME
,PARTY_SITE_SHORT_NAME
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
       ,XPS.start_date_active
       ,XPS.end_date_active
  FROM  xxcmn_party_sites   XPS
       ,hz_party_sites      HPS
       ,hz_locations        HZL
 WHERE  HPS.status = 'A'
   AND  XPS.start_date_active <= TRUNC(SYSDATE)
   AND  XPS.end_date_active   >= TRUNC(SYSDATE)
   AND  XPS.party_site_id     = HPS.party_site_id
   AND  XPS.party_id          = HPS.party_id
   AND  XPS.location_id       = HPS.location_id
   AND  HPS.location_id       = HZL.location_id
-- 2010/01/28 M.Miyagawa ADD Start 本番障害#1694
UNION ALL
SELECT  XPS.party_site_id
       ,XPS.party_id
       ,XPS.location_id
       ,HZL.province
       ,XPS.party_site_name
       ,XPS.party_site_short_name
       ,XPS.start_date_active
       ,XPS.end_date_active
  FROM  XXCMN.xxcmn_party_sites   XPS
       ,apps.hz_party_sites       HPS
       ,apps.hz_locations         HZL
 WHERE  XPS.party_site_id = HPS.party_site_id
   AND  XPS.party_id      = HPS.party_id
   AND  XPS.location_id   = HPS.location_id
   AND  HPS.location_id   = HZL.location_id
   AND  HZL.province IS NOT NULL
   AND  NOT EXISTS(
        SELECT 'X'
        FROM   apps.hz_party_sites       x1
              ,apps.hz_locations         x2
        WHERE x1.location_id       = x2.location_id
        AND   x1.status            = 'A'
        AND   x2.province = HZL.province
)
   AND  NOT EXISTS(
                SELECT 'Y'
        FROM   apps.hz_party_sites       y1
              ,apps.hz_locations         y2
        WHERE y1.location_id       = y2.location_id
        AND   y1.status            = 'I'
        AND   y2.province          = HZL.province
        AND   y1.LAST_UPDATE_DATE  > hps.LAST_UPDATE_DATE
)
-- 2010/01/28 M.Miyagawa ADD End
/
COMMENT ON TABLE APPS.XXSKY_PARTY_SITES_V IS 'SKYLINK用中間VIEW 配送先情報VIEWM'
/
COMMENT ON COLUMN APPS.XXSKY_PARTY_SITES_V.PARTY_SITE_ID         IS 'パーティサイトID'
/
COMMENT ON COLUMN APPS.XXSKY_PARTY_SITES_V.PARTY_ID              IS 'パーティID'
/
COMMENT ON COLUMN APPS.XXSKY_PARTY_SITES_V.LOCATION_ID           IS 'ロケーションID'
/
COMMENT ON COLUMN APPS.XXSKY_PARTY_SITES_V.PARTY_SITE_NUMBER     IS '配送先番号'
/
COMMENT ON COLUMN APPS.XXSKY_PARTY_SITES_V.PARTY_SITE_NAME       IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKY_PARTY_SITES_V.PARTY_SITE_SHORT_NAME IS '配送先短縮名'
/
COMMENT ON COLUMN APPS.XXSKY_PARTY_SITES_V.START_DATE_ACTIVE     IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_PARTY_SITES_V.END_DATE_ACTIVE       IS '適用終了日'
/
