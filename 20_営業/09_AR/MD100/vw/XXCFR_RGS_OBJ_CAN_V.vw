/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCFR_RGS_OBJ_CAN_V
 * Description : 振込依頼人名登録対象一覧
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/10/13    1.0   H.Sasaki         新規作成
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
        acra.attribute1             alt_name              --  振込依頼人名
      , acra.pay_from_customer      cust_account_id       --  顧客ID
      , hp.party_name               party_name            --  顧客名
      , hca.account_number          account_number        --  顧客番号
      , xca.receiv_base_code        receiv_base_code      --  入金拠点
      , acra.receipt_date           receipt_date          --  入金日
      , NULL                        created_by            --  作成者
      , NULL                        creation_date         --  作成日
      , NULL                        last_updated_by       --  最終更新者
      , NULL                        last_update_date      --  最終更新日
      , NULL                        last_update_login     --  最終更新ログイン者
FROM    ar_cash_receipts_all        acra                  --  入金テーブル
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
                FROM    xxcfr_cust_alt_name         xcan          --  振込依頼人マスタ
                WHERE   xcan.alt_name     =   acra.attribute1
        )
AND     acra.org_id                 =   TO_NUMBER(fnd_profile.value('ORG_ID'))
AND     acra.set_of_books_id        =   TO_NUMBER(fnd_profile.value('GL_SET_OF_BKS_ID'))
;
/
COMMENT ON TABLE  XXCFR_RGS_OBJ_CAN_V                       IS  '振込依頼人名登録対象一覧';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.ALT_NAME              IS  '振込依頼人名';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.CUST_ACCOUNT_ID       IS  '顧客ID';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.PARTY_NAME            IS  '顧客名';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.ACCOUNT_NUMBER        IS  '顧客番号';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.RECEIV_BASE_CODE      IS  '入金拠点';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.RECEIPT_DATE          IS  '入金日';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.CREATED_BY            IS  '作成者';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.CREATION_DATE         IS  '作成日';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.LAST_UPDATED_BY       IS  '最終更新者';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.LAST_UPDATE_DATE      IS  '最終更新日';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.LAST_UPDATE_LOGIN     IS  '最終更新ログイン者';
/
