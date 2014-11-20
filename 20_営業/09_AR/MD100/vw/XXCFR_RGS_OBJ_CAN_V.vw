/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCFR_RGS_OBJ_CAN_V
 * Description : �U���˗��l���o�^�Ώۈꗗ
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/10/13    1.0   H.Sasaki         �V�K�쐬
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
        acra.attribute1             alt_name              --  �U���˗��l��
      , acra.pay_from_customer      cust_account_id       --  �ڋqID
      , hp.party_name               party_name            --  �ڋq��
      , hca.account_number          account_number        --  �ڋq�ԍ�
      , xca.receiv_base_code        receiv_base_code      --  �������_
      , acra.receipt_date           receipt_date          --  ������
      , NULL                        created_by            --  �쐬��
      , NULL                        creation_date         --  �쐬��
      , NULL                        last_updated_by       --  �ŏI�X�V��
      , NULL                        last_update_date      --  �ŏI�X�V��
      , NULL                        last_update_login     --  �ŏI�X�V���O�C����
FROM    ar_cash_receipts_all        acra                  --  �����e�[�u��
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
                FROM    xxcfr_cust_alt_name         xcan          --  �U���˗��l�}�X�^
                WHERE   xcan.alt_name     =   acra.attribute1
        )
AND     acra.org_id                 =   TO_NUMBER(fnd_profile.value('ORG_ID'))
AND     acra.set_of_books_id        =   TO_NUMBER(fnd_profile.value('GL_SET_OF_BKS_ID'))
;
/
COMMENT ON TABLE  XXCFR_RGS_OBJ_CAN_V                       IS  '�U���˗��l���o�^�Ώۈꗗ';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.ALT_NAME              IS  '�U���˗��l��';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.CUST_ACCOUNT_ID       IS  '�ڋqID';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.PARTY_NAME            IS  '�ڋq��';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.ACCOUNT_NUMBER        IS  '�ڋq�ԍ�';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.RECEIV_BASE_CODE      IS  '�������_';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.RECEIPT_DATE          IS  '������';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.CREATED_BY            IS  '�쐬��';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.CREATION_DATE         IS  '�쐬��';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.LAST_UPDATED_BY       IS  '�ŏI�X�V��';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.LAST_UPDATE_DATE      IS  '�ŏI�X�V��';
/
COMMENT ON COLUMN XXCFR_RGS_OBJ_CAN_V.LAST_UPDATE_LOGIN     IS  '�ŏI�X�V���O�C����';
/
