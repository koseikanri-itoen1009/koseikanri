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
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
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
COMMENT ON TABLE APPS.XXSKZ_CARRIERS2_V                    IS 'SKYLINK�p����VIEW �^���Ǝҏ��VIEW2'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.PARTY_ID          IS '�p�[�e�B�[ID'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.FREIGHT_CODE      IS '�^���Ǝ҃R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.PARTY_STATUS      IS '�g�D�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.PARTY_NAME        IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.PARTY_SHORT_NAME  IS '�Z�k��'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.START_DATE_ACTIVE IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_CARRIERS2_V.END_DATE_ACTIVE   IS '�K�p�I����'
/
