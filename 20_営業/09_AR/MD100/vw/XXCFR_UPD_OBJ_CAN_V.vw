/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCFR_UPD_OBJ_CAN_V
 * Description : 振込依頼人名更新対象一覧
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/11/18    1.0   H.Sasaki         新規作成
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
        xcan.alt_name               alt_name              --  振込依頼人名
      , xcan.cust_account_id        cust_account_id       --  顧客ID
      , hp.party_name               party_name            --  顧客名
      , hca.account_number          account_number        --  顧客番号
      , xca.receiv_base_code        receiv_base_code      --  入金拠点
      , xcan.receiv_base_code       regist_base_code      --  登録拠点
      , xcan.created_by             created_by            --  作成者
      , xcan.creation_date          creation_date         --  作成日
      , xcan.last_updated_by        last_updated_by       --  最終更新者
      , xcan.last_update_date       last_update_date      --  最終更新日
      , xcan.last_update_login      last_update_login     --  最終更新ログイン者
FROM    xxcfr_cust_alt_name         xcan
      , hz_cust_accounts            hca
      , xxcmm_cust_accounts         xca
      , hz_parties                  hp
WHERE   xcan.cust_account_id        =   hca.cust_account_id
AND     hca.cust_account_id         =   xca.customer_id
AND     hca.party_id                =   hp.party_id
;
/
COMMENT ON TABLE  XXCFR_UPD_OBJ_CAN_V                       IS  '振込依頼人名更新対象一覧';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.ALT_NAME              IS  '振込依頼人名';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.CUST_ACCOUNT_ID       IS  '顧客ID';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.PARTY_NAME            IS  '顧客名';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.ACCOUNT_NUMBER        IS  '顧客番号';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.RECEIV_BASE_CODE      IS  '入金拠点';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.REGIST_BASE_CODE      IS  '登録拠点';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.CREATED_BY            IS  '作成者';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.CREATION_DATE         IS  '作成日';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.LAST_UPDATED_BY       IS  '最終更新者';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.LAST_UPDATE_DATE      IS  '最終更新日';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.LAST_UPDATE_LOGIN     IS  '最終更新ログイン者';
/
