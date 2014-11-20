CREATE OR REPLACE VIEW APPS.XXSKY_CARRIERS_V
(
 PARTY_ID
,FREIGHT_CODE
,PARTY_NAME
,PARTY_SHORT_NAME
,START_DATE_ACTIVE
,END_DATE_ACTIVE
)
AS
SELECT  HP.party_id
       ,WC.freight_code
       ,XP.party_name
       ,XP.party_short_name
       ,XP.start_date_active
       ,XP.end_date_active
  FROM  hz_parties      HP
       ,wsh_carriers    WC
       ,xxcmn_parties   XP
 WHERE  HP.party_id = WC.carrier_id
   AND  HP.party_id = XP.party_id
   AND  HP.status   = 'A'
   AND  XP.start_date_active <= TRUNC(SYSDATE)
   AND  XP.end_date_active   >= TRUNC(SYSDATE)
/
COMMENT ON TABLE APPS.XXSKY_CARRIERS_V                     IS 'SKYLINK�p����VIEW �^���Ǝҏ��VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS_V.PARTY_ID           IS '�p�[�e�B�[ID'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS_V.FREIGHT_CODE       IS '�^���Ǝ҃R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS_V.PARTY_NAME         IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS_V.PARTY_SHORT_NAME   IS '�Z�k��'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS_V.START_DATE_ACTIVE  IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_CARRIERS_V.END_DATE_ACTIVE    IS '�K�p�I����'
/
