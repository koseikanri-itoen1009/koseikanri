/*************************************************************************
 * 
 * View  Name      : XXSKZ_CUST_ACCOUNTS2_V
 * Description     : XXSKZ_CUST_ACCOUNTS2_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_CUST_ACCOUNTS2_V
(
 PARTY_ID
,PARTY_NUMBER
,PARTY_STATUS
,PARTY_NAME
,PARTY_SHORT_NAME
,START_DATE_ACTIVE
,END_DATE_ACTIVE
,CUSTOMER_CLASS_CODE
)
AS
SELECT  HP.party_id
       ,HCA.account_number
       ,HP.status
       ,XP.party_name
       ,XP.party_short_name
       ,XP.start_date_active
       ,XP.end_date_active
       ,HCA.customer_class_code
  FROM  hz_parties          HP
       ,hz_cust_accounts    HCA
       ,xxcmn_parties       XP
 WHERE  HP.party_id = HCA.party_id
   AND  HP.party_id = XP.party_id
   AND  HP.status  = 'A'
-- 2009/10/02 DEL START
--   AND  HCA.status = 'A'
-- 2009/10/02 DEL END
/
COMMENT ON TABLE APPS.XXSKZ_CUST_ACCOUNTS2_V IS 'SKYLINK�p����VIEW �ڋq���VIEW2'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS2_V.PARTY_ID            IS '�p�[�e�B�[ID'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS2_V.PARTY_NUMBER        IS '�g�D�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS2_V.PARTY_STATUS        IS '�g�D�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS2_V.PARTY_NAME          IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS2_V.PARTY_SHORT_NAME    IS '�Z�k��'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS2_V.START_DATE_ACTIVE   IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS2_V.END_DATE_ACTIVE     IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS2_V.CUSTOMER_CLASS_CODE IS '�ڋq���_�敪'
/
