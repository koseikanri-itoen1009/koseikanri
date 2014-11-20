/*************************************************************************
 * 
 * View  Name      : XXSKZ_CUST_ACCOUNTS_V
 * Description     : XXSKZ_CUST_ACCOUNTS_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_CUST_ACCOUNTS_V
(
 PARTY_ID
,PARTY_NUMBER
,PARTY_NAME
,PARTY_SHORT_NAME
,START_DATE_ACTIVE
,END_DATE_ACTIVE
,CUSTOMER_CLASS_CODE
)
AS
SELECT  HP.party_id
       ,HCA.account_number
       ,XP.party_name
       ,XP.party_short_name
       ,XP.start_date_active
       ,XP.end_date_active
       ,HCA.customer_class_code
  FROM  hz_parties           HP
       ,hz_cust_accounts     HCA
       ,xxcmn_parties        XP
 WHERE  HP.party_id = HCA.party_id
   AND  HP.party_id = XP.party_id
   AND  HP.status  = 'A'
-- 2009/10/02 DEL START
--   AND  HCA.status = 'A'
-- 2009/10/02 DEL END
   AND  XP.start_date_active <= TRUNC(SYSDATE)
   AND  XP.end_date_active   >= TRUNC(SYSDATE)
/
COMMENT ON TABLE APPS.XXSKZ_CUST_ACCOUNTS_V                      IS 'SKYLINK用中間VIEW 顧客情報VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS_V.PARTY_ID            IS 'パーティーID'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS_V.PARTY_NUMBER        IS '組織番号'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS_V.PARTY_NAME          IS '正式名'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS_V.PARTY_SHORT_NAME    IS '短縮名'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS_V.START_DATE_ACTIVE   IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS_V.END_DATE_ACTIVE     IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_CUST_ACCOUNTS_V.CUSTOMER_CLASS_CODE IS '顧客拠点区分'
/
