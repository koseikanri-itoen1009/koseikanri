/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCFR_UPD_OBJ_CAN_V
 * Description : �U���˗��l���X�V�Ώۈꗗ
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/11/18    1.0   H.Sasaki         �V�K�쐬
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
        xcan.alt_name               alt_name              --  �U���˗��l��
      , xcan.cust_account_id        cust_account_id       --  �ڋqID
      , hp.party_name               party_name            --  �ڋq��
      , hca.account_number          account_number        --  �ڋq�ԍ�
      , xca.receiv_base_code        receiv_base_code      --  �������_
      , xcan.receiv_base_code       regist_base_code      --  �o�^���_
      , xcan.created_by             created_by            --  �쐬��
      , xcan.creation_date          creation_date         --  �쐬��
      , xcan.last_updated_by        last_updated_by       --  �ŏI�X�V��
      , xcan.last_update_date       last_update_date      --  �ŏI�X�V��
      , xcan.last_update_login      last_update_login     --  �ŏI�X�V���O�C����
FROM    xxcfr_cust_alt_name         xcan
      , hz_cust_accounts            hca
      , xxcmm_cust_accounts         xca
      , hz_parties                  hp
WHERE   xcan.cust_account_id        =   hca.cust_account_id
AND     hca.cust_account_id         =   xca.customer_id
AND     hca.party_id                =   hp.party_id
;
/
COMMENT ON TABLE  XXCFR_UPD_OBJ_CAN_V                       IS  '�U���˗��l���X�V�Ώۈꗗ';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.ALT_NAME              IS  '�U���˗��l��';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.CUST_ACCOUNT_ID       IS  '�ڋqID';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.PARTY_NAME            IS  '�ڋq��';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.ACCOUNT_NUMBER        IS  '�ڋq�ԍ�';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.RECEIV_BASE_CODE      IS  '�������_';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.REGIST_BASE_CODE      IS  '�o�^���_';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.CREATED_BY            IS  '�쐬��';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.CREATION_DATE         IS  '�쐬��';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.LAST_UPDATED_BY       IS  '�ŏI�X�V��';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.LAST_UPDATE_DATE      IS  '�ŏI�X�V��';
/
COMMENT ON COLUMN XXCFR_UPD_OBJ_CAN_V.LAST_UPDATE_LOGIN     IS  '�ŏI�X�V���O�C����';
/
