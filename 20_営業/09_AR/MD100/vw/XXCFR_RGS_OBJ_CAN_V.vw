/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCFR_RGS_OBJ_CAN_V
 * Description : UËl¼o^ÎÛê
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/10/13    1.0   H.Sasaki         VKì¬
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCFR_RGS_OBJ_CAN_V(
  alt_name
, cust_account_id
, party_name
, account_number
, receiv_base_code
, receipt_date
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
) AS
SELECT
        acra.attribute1             alt_name              --  UËl¼
      , acra.pay_from_customer      cust_account_id       --  ÚqID
      , hp.party_name               party_name            --  Úq¼
      , hca.account_number          account_number        --  ÚqÔ
      , xca.receiv_base_code        receiv_base_code      --  üà_
      , acra.receipt_date           receipt_date          --  üàú
      , NULL                        created_by            --  ì¬Ò
      , NULL                        creation_date         --  ì¬ú
      , NULL                        last_updated_by       --  ÅIXVÒ
      , NULL                        last_update_date      --  ÅIXVú
      , NULL                        last_update_login     --  ÅIXVOCÒ
FROM    ar_cash_receipts_all        acra                  --  üàe[u
      , hz_cust_accounts            hca
      , xxcmm_cust_accounts         xca
      , hz_parties                  hp
WHERE   acra.pay_from_customer      =   hca.cust_account_id
AND     hca.cust_account_id         =   xca.customer_id
AND     hca.party_id                =   hp.party_id
AND     acra.status                 =   'APP'
AND     hca.status                  =   'A'
AND     acra.attribute1 IS NOT NULL
AND NOT EXISTS( SELECT  1
                FROM    xxcfr_cust_alt_name         xcan          --  UËl}X^
                WHERE   xcan.alt_name     =   acra.attribute1
        )
AND     acra.org_id                 =   TO_NUMBER(fnd_profile.value('ORG_ID'))
AND     acra.set_of_books_id        =   TO_NUMBER(fnd_profile.value('GL_SET_OF_BKS_ID'))
;
/
COMMENT ON TABLE  XXCFR_RGS_OBJ_CAN_V                       IS  'UËl¼o^ÎÛê';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.ALT_NAME              IS  'UËl¼';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.CUST_ACCOUNT_ID       IS  'ÚqID';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.PARTY_NAME            IS  'Úq¼';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.ACCOUNT_NUMBER        IS  'ÚqÔ';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.RECEIV_BASE_CODE      IS  'üà_';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.RECEIPT_DATE          IS  'üàú';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.CREATED_BY            IS  'ì¬Ò';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.CREATION_DATE         IS  'ì¬ú';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.LAST_UPDATED_BY       IS  'ÅIXVÒ';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.LAST_UPDATE_DATE      IS  'ÅIXVú';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.LAST_UPDATE_LOGIN     IS  'ÅIXVOCÒ';
/
