CREATE OR REPLACE VIEW APPS.XXSKY_CARRIERS2_V
(
 PARTY_ID
,FREIGHT_CODE
,PARTY_STATUS
,PARTY_NAME
,PARTY_SHORT_NAME
,START_DATE_ACTIVE
,END_DATE_ACTIVE
)
AS
SELECT  HP.party_id
       ,WC.freight_code
       ,HP.status
       ,XP.party_name
       ,XP.party_short_name
       ,XP.start_date_active
       ,XP.end_date_active
  FROM  hz_parties      HP
       ,wsh_carriers    WC
       ,xxcmn_parties   XP
 WHERE  HP.party_id = WC.carrier_id
  AND   HP.party_id = XP.party_id
  AND   HP.status   = 'A'
/
COMMENT ON TABLE APPS.XXSKY_CARRIERS2_V                    IS 'SKYLINK用中間VIEW 運送業者情報VIEW2'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS2_V.PARTY_ID          IS 'パーティーID'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS2_V.FREIGHT_CODE      IS '運送業者コード'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS2_V.PARTY_STATUS      IS '組織ステータス'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS2_V.PARTY_NAME        IS '正式名'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS2_V.PARTY_SHORT_NAME  IS '短縮名'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS2_V.START_DATE_ACTIVE IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS2_V.END_DATE_ACTIVE   IS '適用終了日'
/
