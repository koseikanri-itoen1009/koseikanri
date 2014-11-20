/*************************************************************************
 * 
 * View  Name      : XXSKZ_LOCATIONS2_V
 * Description     : XXSKZ_LOCATIONS2_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_LOCATIONS2_V
(
 LOCATION_ID
,LOCATION_CODE
,LOCATION_NAME
,LOCATION_SHORT_NAME
,INACTIVE_DATE
,START_DATE_ACTIVE
,END_DATE_ACTIVE
)
AS
SELECT  XLA.location_id
       ,HLA.location_code
       ,XLA.location_name
       ,XLA.location_short_name
       ,HLA.inactive_date
       ,XLA.start_date_active
       ,XLA.end_date_active
  FROM  hr_locations_all         HLA
       ,xxcmn_locations_all   XLA
 WHERE  HLA.location_id = XLA.location_id
   AND  HLA.inactive_date IS NULL
/
COMMENT ON TABLE APPS.XXSKZ_LOCATIONS2_V IS 'SKYLINK用中間VIEW 事業所情報VIEW2'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS2_V.LOCATION_ID         IS '事業所ID'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS2_V.LOCATION_CODE       IS '事業所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS2_V.LOCATION_NAME       IS '事業所名'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS2_V.LOCATION_SHORT_NAME IS '事業所短縮名'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS2_V.INACTIVE_DATE       IS '失効日'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS2_V.START_DATE_ACTIVE   IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS2_V.END_DATE_ACTIVE     IS '適用終了日'
/
