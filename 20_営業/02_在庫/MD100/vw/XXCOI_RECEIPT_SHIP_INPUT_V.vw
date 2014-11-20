/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_RECEIPT_SHIP_INPUT_V
 * Description     : ���o�ɓ��͉�ʃr���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-12-03    1.0   SCS M.Yoshioka   �V�K�쐬
 *  2009/04/30    1.1   T.Nakamura       [��QT1_0877] �Z�~�R������ǉ�
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_RECEIPT_SHIP_INPUT_V
  (row_id
  ,transaction_id                                                     -- ���o�Ɉꎞ�\ID
  ,column_no                                                          -- �R������
  ,hot_cold_div                                                       -- H/C
  ,inventory_item_id                                                  -- �i��ID
  ,item_code                                                          -- �i�ڃR�[�h
  ,case_in_quantity                                                   -- ����
  ,case_quantity                                                      -- �P�[�X��
  ,quantity                                                           -- �{��
  ,primary_uom_code                                                   -- ��P��
  ,unit_price                                                         -- �P��
  ,total_quantity                                                     -- ���{��
  ,last_update_date                                                   -- �ŏI�X�V��
  ,last_updated_by                                                    -- �ŏI�X�V��
  ,creation_date                                                      -- �쐬��
  ,created_by                                                         -- �쐬��
  ,last_update_login                                                  -- �ŏI�X�V���[�U
  ,request_id                                                         -- �v��ID
  ,program_application_id                                             -- �v���O�����A�v���P�[�V����ID
  ,program_id                                                         -- �v���O����ID
  ,program_update_date                                                -- �v���O�����X�V��
  )
AS
SELECT xhiw.rowid                                                     -- rowid
      ,xhiw.transaction_id                                            -- ���o�Ɉꎞ�\ID
      ,xhiw.column_no                                                 -- �R������
      ,xhiw.hot_cold_div                                              -- H/C
      ,xhiw.inventory_item_id                                         -- �i��ID
      ,xhiw.item_code                                                 -- �i�ڃR�[�h
      ,xhiw.case_in_quantity                                          -- ����
      ,xhiw.case_quantity                                             -- �P�[�X��
      ,xhiw.quantity                                                  -- �{��
      ,xhiw.primary_uom_code                                          -- ��P��
      ,xhiw.unit_price                                                -- �P��
      ,xhiw.total_quantity                                            -- ���{��
      ,xhiw.last_update_date                                          -- �ŏI�X�V��
      ,xhiw.last_updated_by                                           -- �ŏI�X�V��
      ,xhiw.creation_date                                             -- �쐬��
      ,xhiw.created_by                                                -- �쐬��
      ,xhiw.last_update_login                                         -- �ŏI�X�V���[�U
      ,xhiw.request_id                                                -- �v��ID
      ,xhiw.program_application_id                                    -- �v���O�����A�v���P�[�V����ID
      ,xhiw.program_id                                                -- �v���O����ID
      ,xhiw.program_update_date                                       -- �v���O�����X�V��
FROM   xxcoi_hht_inv_transactions   xhiw;                             -- HHT���o�Ɉꎞ�\
/
COMMENT ON TABLE xxcoi_receipt_ship_input_v IS '���o�ɓ��͉�ʃr���[';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.transaction_id IS '���o�Ɉꎞ�\ID';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.column_no IS '�R������';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.hot_cold_div IS 'H/C';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.inventory_item_id IS '�i��ID';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.item_code IS '�i�ڃR�[�h';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.case_in_quantity IS '����';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.case_quantity IS '�P�[�X��';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.quantity IS '�{��';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.primary_uom_code IS '��P��';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.unit_price IS '�P��';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.total_quantity IS '���{��';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.last_update_date IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.last_updated_by IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.creation_date IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.created_by IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.last_update_login IS '�ŏI�X�V���[�U';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.request_id IS '�v��ID';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.program_application_id IS '�v���O�����A�v���P�[�V����ID';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.program_id IS '�v���O����ID';
/
COMMENT ON COLUMN xxcoi_receipt_ship_input_v.program_update_date IS '�v���O�����X�V��';
/
