/*************************************************************************
 * 
 * View  Name      : XXSKZ_CARRIERS2_V
 * Description     : XXSKZ_CARRIERS2_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_CARRIERS2_V
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
COMMENT ON TABLE APPS.XXSKZ_CARRIERS2_V                    IS 'SKYLINK用中間VIEW 運送業者情報VIEW2'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.PARTY_ID          IS 'パーティーID'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.FREIGHT_CODE      IS '運送業者コード'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.PARTY_STATUS      IS '組織ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.PARTY_NAME        IS '正式名'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.PARTY_SHORT_NAME  IS '短縮名'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.START_DATE_ACTIVE IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.END_DATE_ACTIVE   IS '適用終了日'
/
