/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_STORAGE_INFORMATION_V
 * Description     : ���Ɋm�F�^�������͉�ʃr���[
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-12-05    1.0   S.Moriyama       �V�K�쐬
 *  2009-03-30    1.1   S.Moriyama       �o�����敪��ǉ�
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_storage_information_v
  (  transaction_id                                                   -- ���ID
   , base_code                                                        -- ���_�R�[�h
   , warehouse_code                                                   -- �q�ɃR�[�h
   , slip_date                                                        -- �`�[���t
   , slip_num                                                         -- �`�[No
   , slip_type                                                        -- �`�[�敪�R�[�h
   , meaning                                                          -- �`�[�敪
   , parent_item_code                                                 -- �e�i�ڃR�[�h
   , item_code                                                        -- �q�i�ڃR�[�h
   , item_short_name                                                  -- �i�ڗ���
   , case_in_qty                                                      -- �P�[�X����
   , ship_case_qty                                                    -- �o�ɐ��ʃP�[�X��
   , ship_singly_qty                                                  -- �o�ɐ��ʃo����
   , ship_summary_qty                                                 -- �o�ɐ��ʑ��o����
   , summary_data_flag                                                -- �T�}���[�f�[�^�t���O
   , store_check_flag                                                 -- ���Ɋm�F�t���O
   , material_transaction_set_flag                                    -- ���ގ���A�g�σt���O
   , auto_store_check_flag                                            -- �������Ɋm�F�t���O
   , check_warehouse_code                                             -- �m�F�q�ɃR�[�h
   , baracha_div                                                      -- �o�����敪
   , created_by                                                       -- �쐬��
   , creation_date                                                    -- �쐬��
   , last_updated_by                                                  -- �ŏI�X�V��
   , last_update_date                                                 -- �ŏI�X�V��
   , last_update_login                                                -- �ŏI�X�V���[�U
  )
AS
  SELECT   xsi.transaction_id                                         -- ���ID
         , xsi.base_code                                              -- ���_�R�[�h
         , xsi.warehouse_code                                         -- �q�ɃR�[�h
         , xsi.slip_date                                              -- �`�[���t
         , xsi.slip_num                                               -- �`�[No
         , xsi.slip_type                                              -- �`�[�敪�R�[�h
         , flv.meaning                                                -- �`�[�敪
         , xsi.parent_item_code                                       -- �e�i�ڃR�[�h
         , xsi.item_code                                              -- �q�i�ڃR�[�h
         , ximb.item_short_name                                       -- �i�ڗ���
         , xsi.case_in_qty                                            -- �P�[�X����
         , xsi.ship_case_qty                                          -- �o�ɐ��ʃP�[�X��
         , xsi.ship_singly_qty                                        -- �o�ɐ��ʃo����
         , xsi.ship_summary_qty                                       -- �o�ɐ��ʑ��o����
         , xsi.summary_data_flag                                      -- �T�}���[�f�[�^�t���O
         , xsi.store_check_flag                                       -- ���Ɋm�F�t���O
         , xsi.material_transaction_set_flag                          -- ���ގ���A�g�σt���O
         , xsi.auto_store_check_flag                                  -- �������Ɋm�F�t���O
         , xsi.check_warehouse_code                                   -- �m�F�q�ɃR�[�h
         , xsib.baracha_div                                           -- �o�����敪
         , xsi.created_by                                             -- �쐬��
         , xsi.creation_date                                          -- �쐬��
         , xsi.last_updated_by                                        -- �ŏI�X�V��
         , xsi.last_update_date                                       -- �ŏI�X�V��
         , xsi.last_update_login                                      -- �ŏI�X�V���[�U
  FROM     xxcoi_storage_information xsi
         , fnd_lookup_values         flv
         , xxcmn_item_mst_b          ximb
         , ic_item_mst_b             iimb
         , xxcmm_system_items_b      xsib
  WHERE    flv.lookup_type = 'XXCOI1_STOCKED_VOUCH_DIV'
  AND      flv.language = USERENV('LANG')
  AND      flv.enabled_flag = 'Y'
  AND      TRUNC ( SYSDATE ) BETWEEN TRUNC ( NVL ( flv.start_date_active, SYSDATE ) )
                         AND TRUNC ( NVL ( flv.end_date_active, SYSDATE ) )
  AND      flv.lookup_code = xsi.slip_type
  AND      iimb.item_id = ximb.item_id
  AND      xsi.item_code = iimb.item_no
  AND      iimb.item_id = xsib.item_id
/
COMMENT ON TABLE xxcoi_storage_information_v IS '���Ɋm�F�^������ʃr���['
/
COMMENT ON COLUMN xxcoi_storage_information_v.transaction_id IS '���ID'
/
COMMENT ON COLUMN xxcoi_storage_information_v.base_code IS '���_�R�[�h'
/
COMMENT ON COLUMN xxcoi_storage_information_v.warehouse_code IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN xxcoi_storage_information_v.slip_date IS '�`�[���t'
/
COMMENT ON COLUMN xxcoi_storage_information_v.slip_num IS '�`�[No'
/
COMMENT ON COLUMN xxcoi_storage_information_v.slip_type IS '�`�[�敪�R�[�h'
/
COMMENT ON COLUMN xxcoi_storage_information_v.meaning IS '�`�[�敪'
/
COMMENT ON COLUMN xxcoi_storage_information_v.parent_item_code IS '�e�i�ڃR�[�h'
/
COMMENT ON COLUMN xxcoi_storage_information_v.item_code IS '�q�i�ڃR�[�h'
/
COMMENT ON COLUMN xxcoi_storage_information_v.item_short_name IS '�i�ڗ���'
/
COMMENT ON COLUMN xxcoi_storage_information_v.case_in_qty IS '�P�[�X����'
/
COMMENT ON COLUMN xxcoi_storage_information_v.ship_case_qty IS '�o�ɐ��ʃP�[�X��'
/
COMMENT ON COLUMN xxcoi_storage_information_v.ship_singly_qty IS '�o�ɐ��ʃo����'
/
COMMENT ON COLUMN xxcoi_storage_information_v.ship_summary_qty IS '�o�ɐ��ʑ��o����'
/
COMMENT ON COLUMN xxcoi_storage_information_v.summary_data_flag IS '�T�}���[�f�[�^�t���O'
/
COMMENT ON COLUMN xxcoi_storage_information_v.store_check_flag IS '���Ɋm�F�t���O'
/
COMMENT ON COLUMN xxcoi_storage_information_v.material_transaction_set_flag IS '���ގ���A�g�σt���O'
/
COMMENT ON COLUMN xxcoi_storage_information_v.auto_store_check_flag IS '�������Ɋm�F�t���O'
/
COMMENT ON COLUMN xxcoi_storage_information_v.check_warehouse_code IS '�m�F�q�ɃR�[�h'
/
COMMENT ON COLUMN xxcoi_storage_information_v.baracha_div IS '�o�����敪'
/
COMMENT ON COLUMN xxcoi_storage_information_v.created_by IS '�쐬��'
/
COMMENT ON COLUMN xxcoi_storage_information_v.creation_date IS '�쐬��'
/
COMMENT ON COLUMN xxcoi_storage_information_v.last_updated_by IS '�ŏI�X�V��'
/
COMMENT ON COLUMN xxcoi_storage_information_v.last_update_date IS '�ŏI�X�V��'
/
COMMENT ON COLUMN xxcoi_storage_information_v.last_update_login IS '�ŏI�X�V���[�U'
/
