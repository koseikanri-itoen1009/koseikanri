/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_edi_stc_chain_store_v
 * Description     : EDI�`�F�[���X�R�[�hview
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   x.xxxxxxx        �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_edi_stc_chain_store_v (
   chain_store_code   --EDI�`�F�[���X�R�[�h
  ,customer_name      --�ڋq����
  ,ship_storage_code  --�o�׌��ۊǏꏊ(����)
)
AS
   SELECT   hca2.chain_store_code
           ,hca2.party_name
           ,hca1.ship_storage_code
   FROM     ( SELECT  xca.ship_storage_code  ship_storage_code --�o�׌��ۊǏꏊ
                     ,xca.chain_store_code   chain_store_code  --EDI�`�F�[���X�R�[�h
                     ,hca.account_number     account_number    --�ڋq�R�[�h
              FROM    hz_cust_accounts         hca   --�ڋq
                     ,xxcmm_cust_accounts      xca   --�ڋq�ǉ����
                     ,hz_parties               hp    --�p�[�e�B
                     ,xxcos_login_base_info_v  xlbiv --���O�C�����[�U���_
              WHERE   hca.customer_class_code =  '10'  -- �ڋq
              AND     hca.status              =  'A'   -- �X�e�[�^�X
              AND     hp.duns_number_c        <> '90'  -- �ڋq�X�e�[�^�X
              AND     hca.party_id            =  hp.party_id
              AND     hca.cust_account_id     =  xca.customer_id
              AND     xca.delivery_base_code  =  xlbiv.base_code
            )                       hca1   --�ڋq
           ,( SELECT  xca.chain_store_code   chain_store_code  --EDI�`�F�[���X�R�[�h
                     ,hp.party_name          party_name        --�ڋq����
              FROM    hz_cust_accounts    hca  --�ڋq
                     ,xxcmm_cust_accounts xca  --�ڋq�ǉ����
                     ,hz_parties          hp   --�p�[�e�B
              WHERE   hca.customer_class_code =  '18'  -- �`�F�[���X
              AND     hca.cust_account_id     =  xca.customer_id
              AND     hca.party_id            =  hp.party_id
            )                       hca2   --�ڋq(�`�F�[���X)
   WHERE    hca1.chain_store_code = hca2.chain_store_code
   AND      hca1.account_number =
              ( SELECT   MAX(hca.account_number)
                FROM     hz_cust_accounts    hca
                        ,xxcmm_cust_accounts xca
                        ,hz_parties          hp    --�p�[�e�B
                WHERE    hca.customer_class_code =  '10'  -- �ڋq
                AND      hca.status              =  'A'   -- �X�e�[�^�X
                AND      hp.duns_number_c        <> '90'  -- �ڋq�X�e�[�^�X
                AND      hca.party_id            =  hp.party_id
                AND      hca.cust_account_id     =  xca.customer_id
                AND      xca.ship_storage_code   =  hca1.ship_storage_code
                AND      xca.chain_store_code    =  hca1.chain_store_code
              )
;
COMMENT ON  COLUMN  xxcos_edi_stc_chain_store_v.chain_store_code       IS 'EDI�`�F�[���X�R�[�h'; 
COMMENT ON  COLUMN  xxcos_edi_stc_chain_store_v.customer_name          IS '�ڋq����';
COMMENT ON  COLUMN  xxcos_edi_stc_chain_store_v.ship_storage_code      IS '�o�׌��ۊǏꏊ(����)';
--
COMMENT ON  TABLE   xxcos_edi_stc_chain_store_v                        IS 'EDI�`�F�[���X�R�[�h�r���[';
