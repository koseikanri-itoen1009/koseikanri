/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_order_customer_number_v
 * Description     : �ڋq�R�[�h�̃Z�L�����e�B�i�N�C�b�N�󒍗p�j
 * Version         : 1.3
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/26    1.0   T.Tyou           �V�K�쐬
 *  2009/05/18    1.1   S.Tomita         [T1_0976]�N�C�b�N�󒍃I�[�K�i�C�U�Z�L�����e�B�Ή�
 *  2009/07/06    1.2   K.Kakishita      [T3_0317]�p�t�H�[�}���X�Ή�
 *                                       �E�q���g��ǉ��AIN�傩��EXISTS�ւ̕ύX
 *                                       �E���_�R�[�h�A�ڋq�X�e�[�^�X���ڂ̍폜
 *  2009/07/10    1.3   K.Kakishita      [T3_0317]�p�t�H�[�}���X�Ή�
 *                                       �E�q���g��ǉ��AEXISTS����IN�ւ̕ύX
 *  2009/07/15    1.4   K.Kakishita      [T3_0757]�d���f�[�^���\��������Q�Ή�
 *                                       �EGROUP BY���ǉ�
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_order_customer_number_v (
  account_number,
  account_description,
  registry_id,
  party_name,
  party_type,
  cust_account_id,
  email_address,
  gsa_indicator
)
AS
  SELECT
    /*+
      INDEX ( acct HZ_CUST_ACCOUNTS_N06 )
      INDEX ( party HZ_PARTIES_U1 )
      INDEX ( xca XXCMM_CUST_ACCOUNTS_PK )
    */
    acct.account_number                   account_number,
    acct.account_name                     account_description,
    party.party_number                    registry_id,
    party.party_name                      party_name,
    party.party_type                      party_type,
    acct.cust_account_id                  cust_account_id,
    party.email_address                   email_address,
    NVL( party.gsa_indicator_flag, 'N' )  gsa_indicator
  FROM
    hz_parties                            party,
    hz_cust_accounts                      acct,
    xxcmm_cust_accounts                   xca,
    xxcos_login_base_info_v               xlbiv
  WHERE
    acct.party_id                       = party.party_id
  AND acct.status                       = 'A'
  AND acct.cust_account_id              = xca.customer_id
  AND xlbiv.base_code IN ( xca.sale_base_code, xca.past_sale_base_code, xca.delivery_base_code )
  AND EXISTS(
        SELECT 'Y' exists_flag
        FROM fnd_lookup_values flv
        WHERE flv.lookup_type = 'XXCOS1_CUS_CLASS_MST_005_A01'
        AND flv.meaning = acct.customer_class_code
        AND flv.enabled_flag = 'Y'
        AND flv.language = userenv('LANG')
        AND xxccp_common_pkg2.get_process_date >= flv.start_date_active
        AND xxccp_common_pkg2.get_process_date <= NVL(flv.end_date_active, xxccp_common_pkg2.get_process_date )
      )
  GROUP BY
    acct.account_number,
    acct.account_name,
    party.party_number,
    party.party_name,
    party.party_type,
    acct.cust_account_id,
    party.email_address,
    NVL( party.gsa_indicator_flag, 'N' )
;
COMMENT ON  COLUMN  xxcos_order_customer_number_v.account_number       IS  '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.account_description  IS  '�ڋq����';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.registry_id          IS  '�p�[�e�B�ԍ�';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.party_name           IS  '�p�[�e�B����';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.party_type           IS  '�p�[�e�B�^�C�v';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.cust_account_id      IS  '�ڋqID';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.email_address        IS  '���[���A�h���X';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.gsa_indicator        IS  '�t���O';
--
COMMENT ON  TABLE   xxcos_order_customer_number_v                      IS  '�ڋq�R�[�h�̃Z�L�����e�B(�N�C�b�N�󒍗p)';
