/************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Table Name      : XXCMM_CUST_ACCOUNTS
 * Description     : �ڋq�ǉ����
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/11/21    1.0  Y.Nagasue        [E_�{�ғ�_12237]�q�ɊǗ��V�X�e���Ή�
 *
 ************************************************************************/
ALTER TABLE XXCMM.XXCMM_CUST_ACCOUNTS ADD(
  CUST_FRESH_CON_CODE VARCHAR2(2)
)
/
COMMENT ON COLUMN XXCMM.XXCMM_CUST_ACCOUNTS.CUST_FRESH_CON_CODE IS '�ڋq�ʑN�x�����R�[�h';
/
