/************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_tax_rate_v
 * Description     : ����ŗ�view
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Kumamoto       �V�K�쐬
 *  2009/02/25    1.1   S.Nakamura       [COS_135]ar_vat_tax_all_b�̗L�������ǉ�
 *
 ************************************************************************************/
CREATE OR REPLACE VIEW xxcos_tax_rate_v (
  cust_account_id         --�ڋqID
 ,account_number          --�ڋq�R�[�h
 ,chain_store_code        --�`�F�[���X�R�[�h
 ,ship_storage_code       --�o�׌��ۊǏꏊ
 ,customer_class_code     --�ڋq�敪
 ,set_of_books_id         --GL��v����ID
 ,tax_div                 --����ŋ敪
 ,tax_code                --����ŃR�[�h
 ,tax_rate                --����ŗ�
 ,start_date_active       --�K�p�J�n��
 ,end_date_active         --�K�p�I����
 ,tax_start_date          --�ŊJ�n��     --1.1 COS_135
 ,tax_end_date            --�ŏI����     --1.1 COS_135
)
AS
  SELECT  hca.cust_account_id         cust_account_id
         ,hca.account_number          account_number
         ,xca.chain_store_code        chain_store_code
         ,xca.ship_storage_code       ship_storage_code
         ,hca.customer_class_code     customer_class_code
         ,avtab.set_of_books_id       set_of_books_id
         ,xca.tax_div                 tax_div
         ,avtab.tax_code              tax_code
         ,avtab.tax_rate              tax_rate
         ,flv.start_date_active       start_date_active
         ,flv.end_date_active         end_date_active
         ,avtab.start_date            tax_start_date
         ,avtab.end_date              tax_end_date  
  FROM    hz_cust_accounts            hca
         ,xxcmm_cust_accounts         xca
         ,fnd_lookup_values           flv
         ,ar_vat_tax_all_b            avtab
  WHERE   xca.customer_id  = hca.cust_account_id
  AND     flv.lookup_type  = 'XXCOS1_CONSUMPTION_TAX_CLASS'
  AND     flv.attribute3   = xca.tax_div
  AND     avtab.tax_code   = flv.attribute2
  AND     avtab.tax_rate IS NOT NULL
  AND     avtab.enabled_flag = 'Y'
  AND     flv.enabled_flag   = 'Y'
  AND     flv.language       = userenv('LANG')
  AND     flv.source_lang    = userenv('LANG')
;
COMMENT ON  COLUMN  xxcos_tax_rate_v.cust_account_id      IS  '�ڋqID';
COMMENT ON  COLUMN  xxcos_tax_rate_v.account_number       IS  '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_tax_rate_v.chain_store_code     IS  '�`�F�[���X�R�[�h';
COMMENT ON  COLUMN  xxcos_tax_rate_v.ship_storage_code    IS  '�o�׌��ۊǏꏊ';
COMMENT ON  COLUMN  xxcos_tax_rate_v.customer_class_code  IS  '�ڋq�敪';
COMMENT ON  COLUMN  xxcos_tax_rate_v.set_of_books_id      IS  'GL��v����ID';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_div              IS  '����ŋ敪';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_code             IS  '����ŃR�[�h';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_rate             IS  '����ŗ�';
COMMENT ON  COLUMN  xxcos_tax_rate_v.start_date_active    IS  '�K�p�J�n��';
COMMENT ON  COLUMN  xxcos_tax_rate_v.end_date_active      IS  '�K�p�I����';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_start_date       IS  '�ŊJ�n��';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_end_date         IS  '�ŏI����';
--
COMMENT ON  TABLE   xxcos_tax_rate_v                      IS  '����ŗ��r���[';
