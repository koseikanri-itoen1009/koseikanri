/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_order_cusomter_number_v
 * Description     : �ڋq�R�[�h�̃Z�L�����e�B�i�N�C�b�N�󒍗p�j
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/1/26     1.0   T.Tyou           �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_order_cusomter_number_v (
  account_number,
  account_description,
  registry_id,
  party_name,
  party_type,
  cust_account_id,
  email_address,
  gsa_indicator,
  base_code,
  duns_number_c
)
AS 
SELECT acct.account_number account_number,
  acct.account_name account_description,
  party.party_number registry_id,
  party.party_name party_name,
  party.party_type,
  acct.cust_account_id cust_account_id,
  party.email_address email_address,
  nvl(party.gsa_indicator_flag,   'N') gsa_indicator
  ,CASE WHEN  xca.sale_base_code IN  (
    SELECT
        base_code                 base_code
    FROM
        xxcos_login_base_info_v   xlbiv
    )
  THEN
   xca.sale_base_code
  WHEN xca.past_sale_base_code IN  (
    SELECT
        base_code                 base_code
    FROM
        xxcos_login_base_info_v   xlbiv
    )
  THEN
    xca.past_sale_base_code
  WHEN xca.delivery_base_code IN  (
    SELECT
        base_code                 base_code
    FROM
        xxcos_login_base_info_v   xlbiv
    )
  THEN
    xca.delivery_base_code
  END base_code
  ,party.duns_number_c duns_number_c
FROM hz_parties party,
  hz_cust_accounts acct
  ,xxcmm_cust_accounts xca
WHERE acct.party_id = party.party_id
 AND acct.status = 'A'
 AND acct.cust_account_id = xca.customer_id
 AND (
 xca.sale_base_code IN  (
    SELECT
        base_code                 base_code
    FROM
        xxcos_login_base_info_v   xlbiv
    )
 OR xca.past_sale_base_code IN  (
    SELECT
        base_code                 base_code
    FROM
        xxcos_login_base_info_v   xlbiv
    )
 OR xca.delivery_base_code IN  (
    SELECT
        base_code                 base_code
    FROM
        xxcos_login_base_info_v   xlbiv
    )
 )
;
COMMENT ON  COLUMN  xxcos_order_cusomter_number_v.account_number       IS  '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_order_cusomter_number_v.account_description  IS  '�ڋq����';
COMMENT ON  COLUMN  xxcos_order_cusomter_number_v.registry_id          IS  '�p�[�e�B�ԍ�';
COMMENT ON  COLUMN  xxcos_order_cusomter_number_v.party_name           IS  '�p�[�e�B����';
COMMENT ON  COLUMN  xxcos_order_cusomter_number_v.party_type           IS  '�p�[�e�B�^�C�v';
COMMENT ON  COLUMN  xxcos_order_cusomter_number_v.cust_account_id      IS  '�ڋqID';
COMMENT ON  COLUMN  xxcos_order_cusomter_number_v.email_address        IS  '���[���A�h���X';
COMMENT ON  COLUMN  xxcos_order_cusomter_number_v.gsa_indicator        IS  '�t���O';
COMMENT ON  COLUMN  xxcos_order_cusomter_number_v.base_code            IS  '���_�R�[�h';
COMMENT ON  COLUMN  xxcos_order_cusomter_number_v.duns_number_c        IS  '�ڋq�X�e�[�^�X';
--
COMMENT ON  TABLE   xxcos_order_cusomter_number_v                      IS  '�ڋq�R�[�h�̃Z�L�����e�B(�N�C�b�N�󒍗p)';

