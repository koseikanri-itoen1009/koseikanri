/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCFR_UPD_OBJ_CAN_V
 * Description : UËl¼XVÎÛê
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/11/18    1.0   H.Sasaki         VKì¬
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCFR_UPD_OBJ_CAN_V(
  alt_name
, cust_account_id
, party_name
, account_number
, receiv_base_code
, regist_base_code
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
) AS
SELECT
        xcan.alt_name               alt_name              --  UËl¼
      , xcan.cust_account_id        cust_account_id       --  ÚqID
      , hp.party_name               party_name            --  Úq¼
      , hca.account_number          account_number        --  ÚqÔ
      , xca.receiv_base_code        receiv_base_code      --  üà_
      , xcan.receiv_base_code       regist_base_code      --  o^_
      , xcan.created_by             created_by            --  ì¬Ò
      , xcan.creation_date          creation_date         --  ì¬ú
      , xcan.last_updated_by        last_updated_by       --  ÅIXVÒ
      , xcan.last_update_date       last_update_date      --  ÅIXVú
      , xcan.last_update_login      last_update_login     --  ÅIXVOCÒ
FROM    xxcfr_cust_alt_name         xcan
      , hz_cust_accounts            hca
      , xxcmm_cust_accounts         xca
      , hz_parties                  hp
WHERE   xcan.cust_account_id        =   hca.cust_account_id
AND     hca.cust_account_id         =   xca.customer_id
AND     hca.party_id                =   hp.party_id
;
/
COMMENT ON TABLE  XXCFR_UPD_OBJ_CAN_V                       IS  'UËl¼XVÎÛê';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.ALT_NAME              IS  'UËl¼';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.CUST_ACCOUNT_ID       IS  'ÚqID';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.PARTY_NAME            IS  'Úq¼';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.ACCOUNT_NUMBER        IS  'ÚqÔ';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.RECEIV_BASE_CODE      IS  'üà_';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.REGIST_BASE_CODE      IS  'o^_';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.CREATED_BY            IS  'ì¬Ò';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.CREATION_DATE         IS  'ì¬ú';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.LAST_UPDATED_BY       IS  'ÅIXVÒ';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.LAST_UPDATE_DATE      IS  'ÅIXVú';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.LAST_UPDATE_LOGIN     IS  'ÅIXVOCÒ';
/
