/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : xxcos_edi_stc_headers_sum_v
 * Description     : ���ɗ\��v��r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/14    1.0   K.Kiriu         �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_edi_stc_headers_sum_v
(
   header_id                    --�w�b�_ID
  ,party_id                     --�p�[�e�BID
  ,organization_id              --�g�DID
  ,to_subinventory_code         --������ۊǏꏊ�i�R�[�h�j
  ,to_subinventory_name         --������ۊǏꏊ�i���́j
  ,move_order_num               --�ړ��I�[�_�[�ԍ�
  ,edi_chain_code               --EDI�`�F�[���X�R�[�h
  ,edi_chain_name               --EDI�`�F�[���X����
  ,shop_code                    --�X�R�[�h
  ,center_code                  --�Z���^�[�R�[�h
  ,other_party_department_code  --����敔��R�[�h
  ,invoice_number               --�`�[�ԍ�
  ,schedule_shipping_date       --�o�ח\���
  ,schedule_arrival_date        --���ɗ\���
  ,rcpt_possible_date           --����\��
  ,inspect_schedule_date        --���i�\���
  ,invoice_class                --�`�[�敪
  ,classification_class         --���ދ敪
  ,whse_class                   --�q�ɋ敪
  ,regular_ar_sale_class        --���/�����敪
  ,opportunity_code             --�փR�[�h
  ,fix_flag                     --�m��t���O
  ,fix_conditions               --�m���
  ,edi_send_flag                --EDI���M�ς݃t���O
  ,edi_send_conditions          --EDI���M��
  ,edi_send_date                --EDI���M����
  ,created_by                   --�쐬��
  ,creation_date                --�쐬��
  ,last_updated_by              --�ŏI�X�V��
  ,last_update_date             --�ŏI�X�V��
)
AS
SELECT   xesh.header_id                    header_id                    --�w�b�_ID
        ,hca2.party_id                     party_id                     --�p�[�e�BID
        ,xesh.organization_id              organization_id              --�g�DID
        ,xesh.to_subinventory_code         to_subinventory_code         --������ۊǏꏊ�i�R�[�h�j
        ,msi.description                   to_subinventory_name         --������ۊǏꏊ�i���́j
        ,xesh.move_order_num               move_order_num               --�ړ��I�[�_�[�ԍ�
        ,xesh.edi_chain_code               edi_chain_code               --EDI�`�F�[���X�R�[�h
        ,hca2.party_name                   edi_chain_name               --EDI�`�F�[���X����
        ,xesh.shop_code                    shop_code                    --�X�R�[�h
        ,xesh.center_code                  center_code                  --�Z���^�[�R�[�h
        ,xesh.other_party_department_code  other_party_department_code  --����敔��R�[�h
        ,xesh.invoice_number               invoice_number               --�`�[�ԍ�
        ,xesh.schedule_shipping_date       schedule_shipping_date       --�o�ח\���
        ,xesh.schedule_arrival_date        schedule_arrival_date        --���ɗ\���
        ,xesh.rcpt_possible_date           rcpt_possible_date           --����\��
        ,xesh.inspect_schedule_date        inspect_schedule_date        --���i�\���
        ,xesh.invoice_class                invoice_class                --�`�[�敪
        ,xesh.classification_class         classification_class         --���ދ敪
        ,xesh.whse_class                   whse_class                   --�q�ɋ敪
        ,xesh.regular_ar_sale_class        regular_ar_sale_class        --���/�����敪
        ,xesh.opportunity_code             opportunity_code             --�փR�[�h
        ,xesh.fix_flag                     fix_flag                     --�m��t���O
        ,flvv.meaning                      fix_conditions               --�m���
        ,xesh.edi_send_flag                edi_send_flag                --EDI���M�ς݃t���O
        ,DECODE(  xesh.edi_send_flag
                 ,'Y', xxccp_common_pkg.get_msg(
                          'XXCOS'
                         ,'APP-XXCOS1-12456'  --��
                       )
                 ,'N', xxccp_common_pkg.get_msg(
                          'XXCOS'
                         ,'APP-XXCOS1-12457'  --��
                       ) )                 edi_send_conditions          --EDI���M��
        ,xesh.edi_send_date                edi_send_date                --EDI���M����
        ,xesh.created_by                   created_by                   --�쐬��
        ,xesh.creation_date                creation_date                --�쐬��
        ,xesh.last_updated_by              last_updated_by              --�ŏI�X�V��
        ,xesh.last_update_date             last_update_date             --�ŏI�X�V��
FROM     xxcos_edi_stc_headers      xesh   --���ɗ\��w�b�_
        ,( SELECT   xca.ship_storage_code  ship_storage_code   --�o�׌��ۊǏꏊ
                   ,xca.chain_store_code   chain_store_code    --EDI�`�F�[���X�R�[�h
                   ,hca.account_number     account_number      --�ڋq�R�[�h
                   ,xca.delivery_base_code delivery_base_code  --�o�׌����_
           FROM     hz_cust_accounts         hca
                   ,xxcmm_cust_accounts      xca
                   ,hz_parties               hp
                   ,xxcos_login_base_info_v  xlbiv
           WHERE    hca.customer_class_code =  '10'  -- �ڋq
           AND      hca.status              =  'A'   -- �X�e�[�^�X(�L��)
           AND      hp.duns_number_c        <> '90'  -- �ڋq�X�e�[�^�X(���~���وȊO)
           AND      hca.party_id            =  hp.party_id
           AND      hca.cust_account_id     =  xca.customer_id
           AND      xca.delivery_base_code  =  xlbiv.base_code
         )                          hca1   --�ڋq
        ,mtl_secondary_inventories  msi    --�ۊǏꏊ�}�X�^
        ,( SELECT   xca.chain_store_code   chain_store_code  --EDI�`�F�[���X�R�[�h
                   ,hp.party_name          party_name        --�ڋq����
                   ,hp.party_id            party_id          --�p�[�e�BID
           FROM     hz_cust_accounts    hca
                   ,xxcmm_cust_accounts xca
                   ,hz_parties          hp
           WHERE    hca.customer_class_code =  '18'  -- �`�F�[���X
           AND      hca.cust_account_id     =  xca.customer_id
           AND      hca.party_id            =  hp.party_id
         )                          hca2   --�ڋq(�`�F�[���X)
        ,fnd_lookup_values_vl       flvv   --�N�C�b�N�R�[�h(�m��t���O)
WHERE    xesh.to_subinventory_code  = hca1.ship_storage_code
AND      xesh.edi_chain_code        = hca1.chain_store_code
AND      hca1.account_number        =
           ( SELECT   MAX(hca.account_number)
             FROM     hz_cust_accounts    hca
                     ,xxcmm_cust_accounts xca
                     ,hz_parties          hp
             WHERE    hca.customer_class_code =  '10'
             AND      hca.status              =  'A'
             AND      hp.duns_number_c        <> '90'
             AND      hca.party_id            =  hp.party_id
             AND      hca.cust_account_id     =  xca.customer_id
             AND      xca.ship_storage_code   =  hca1.ship_storage_code
             AND      xca.chain_store_code    =  hca1.chain_store_code
             AND      xca.delivery_base_code  =  hca1.delivery_base_code
           )                               --�ڋq�����������݂���ׁA1���ɍi��
AND      xesh.to_subinventory_code  = msi.secondary_inventory_name
AND      xesh.organization_id       = msi.organization_id
AND      xesh.edi_chain_code        = hca2.chain_store_code
AND      flvv.lookup_type           = 'XXCOS1_FIX_FLAG'
AND      xesh.fix_flag              = flvv.lookup_code
AND      flvv.enabled_flag          = 'Y'
AND      (
           ( flvv.start_date_active IS NULL )
           OR
           ( flvv.start_date_active <= TRUNC(SYSDATE) )
         )
AND      (
           ( flvv.end_date_active IS NULL )
           OR
           ( flvv.end_date_active >=  TRUNC(SYSDATE) )
         )
/
