CREATE OR REPLACE VIEW APPS.XXSKY_LOCATIONS_V
(
 LOCATION_ID
,LOCATION_CODE
,LOCATION_NAME
,LOCATION_SHORT_NAME
,START_DATE_ACTIVE
,END_DATE_ACTIVE
)
AS
SELECT  XLA.location_id
       ,HLA.location_code
       ,XLA.location_name
       ,XLA.location_short_name
       ,XLA.start_date_active
       ,XLA.end_date_active
  FROM  hr_locations_all      HLA
       ,xxcmn_locations_all   XLA	
 WHERE  HLA.location_id = XLA.location_id
   AND  HLA.inactive_date IS NULL
   AND  XLA.start_date_active <= TRUNC(SYSDATE)
   AND  XLA.end_date_active >= TRUNC(SYSDATE)
/
COMMENT ON TABLE APPS.XXSKY_LOCATIONS_V IS 'SKYLINK用中間VIEW 事業所情報VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_LOCATIONS_V.LOCATION_ID         IS '事業所ID'
/
COMMENT ON COLUMN APPS.XXSKY_LOCATIONS_V.LOCATION_CODE       IS '事業所コード'
/
COMMENT ON COLUMN APPS.XXSKY_LOCATIONS_V.LOCATION_NAME       IS '事業所名'
/
COMMENT ON COLUMN APPS.XXSKY_LOCATIONS_V.LOCATION_SHORT_NAME IS '事業所短縮名'
/
COMMENT ON COLUMN APPS.XXSKY_LOCATIONS_V.START_DATE_ACTIVE   IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_LOCATIONS_V.END_DATE_ACTIVE     IS '適用終了日'
/
