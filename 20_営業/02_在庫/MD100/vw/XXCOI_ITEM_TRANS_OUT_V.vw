/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_ITEM_TRANS_OUT_V
 * Description     : ���i�U�֓��͉�ʏo�ɗp�r���[
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009-1-14     1.0   SCS M.Yoshioka   �V�K�쐬
 *  2009/04/30    1.1   T.Nakamura       [��QT1_0877] �Z�~�R������ǉ�
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_ITEM_TRANS_OUT_V
  (row_id
  ,transaction_id                                                     -- ���o�Ɉꎞ�\ID
  ,inventory_item_id                                                  -- �i��ID
  ,item_code                                                          -- �i�ڃR�[�h
  ,primary_uom_code                                                   -- ��P��
  ,quantity                                                           -- �{��
  ,unit_price                                                         -- �P��
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
      ,xhiw.inventory_item_id                                         -- �i��ID
      ,xhiw.item_code                                                 -- �i�ڃR�[�h
      ,xhiw.primary_uom_code                                          -- ��P��
      ,xhiw.quantity                                                  -- �{��
      ,xhiw.unit_price                                                -- �P��
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
COMMENT ON TABLE xxcoi_item_trans_out_v IS '���i�U�֓��͉�ʏo�ɗp�r���[';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.transaction_id IS '���o�Ɉꎞ�\ID';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.inventory_item_id IS '�i��ID';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.item_code IS '�i�ڃR�[�h';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.primary_uom_code IS '��P��';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.quantity IS '�{��';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.unit_price IS '�P��';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.last_update_date IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.last_updated_by IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.creation_date IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.created_by IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.last_update_login IS '�ŏI�X�V���[�U';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.request_id IS '�v��ID';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.program_application_id IS '�v���O�����A�v���P�[�V����ID';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.program_id IS '�v���O����ID';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.program_update_date IS '�v���O�����X�V��';
/
