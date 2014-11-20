/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_TXN_ENABLE_ITEM_INFO_V
 * Description     : �݌Ɏ���\�i�ڃr���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-12-03    1.0   SCS M.Yoshioka   �V�K�쐬
 *  2008-12-26    1.1   SCS H.Nakajima   Disc�i�ڃA�h�I���̌���������ύX
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_TXN_ENABLE_ITEM_INFO_V
  (row_id
  ,inventory_item_id                                                  -- �i��ID
  ,organization_id                                                    -- �݌ɑg�DID
  ,item_code                                                          -- �i�ڃR�[�h
  ,item_short_name                                                    -- �i�ڗ���
  ,primary_uom_code                                                   -- ��P��
  ,policy_group_apply_date                                            -- �Q���ޓK�p�J�n��
  ,policy_group_new                                                   -- �Q�R�[�h(�V)
  ,policy_group_old                                                   -- ���Q�R�[�h
  ,discrete_cost_apply_date                                           -- �c�ƌ����K�p�J�n��
  ,discrete_cost_new                                                  -- �c�ƌ���(�V)
  ,discrete_cost_old                                                  -- ���c�ƌ���
  ,fixed_price_apply_date                                             -- �艿�K�p�J�n��
  ,fixed_price_new                                                    -- �艿(�V)
  ,fixed_price_old                                                    -- ���艿
  ,case_in_qty                                                        -- �P�[�X����
  ,start_date_active                                                  -- OPM�K�p�J�n��
  ,end_date_active                                                    -- OPM�K�p�I����
  ,active_flag                                                        -- OPM�K�p�σt���O
  ,baracha_div                                                        -- �o�����敪
  )
AS
SELECT msib.rowid                                                     -- rowid
      ,msib.inventory_item_id                                         -- �i��ID
      ,msib.organization_id                                           -- �݌ɑg�DID
      ,msib.segment1                                                  -- �i�ڃR�[�h
      ,ximb.item_short_name                                           -- �i�ڗ���
      ,msib.primary_uom_code                                          -- ��P��
      ,iimb.attribute3                                                -- �Q���ޓK�p�J�n��
      ,iimb.attribute2                                                -- �Q�R�[�h(�V)
      ,iimb.attribute1                                                -- ���Q�R�[�h
      ,iimb.attribute9                                                -- �c�ƌ����K�p�J�n��
      ,iimb.attribute8                                                -- �c�ƌ���(�V)
      ,iimb.attribute7                                                -- ���c�ƌ���
      ,iimb.attribute6                                                -- �艿�K�p�J�n��
      ,iimb.attribute5                                                -- �艿(�V)
      ,iimb.attribute4                                                -- ���艿
      ,iimb.attribute11                                               -- �P�[�X����
      ,ximb.start_date_active                                         -- �K�p�J�n��
      ,ximb.end_date_active                                           -- �K�p�I����
      ,ximb.active_flag                                               -- �K�p�σt���O
      ,xsib.baracha_div                                               -- �o�����敪
FROM   mtl_system_items_b   msib                                      -- Disc�i��
      ,ic_item_mst_b        iimb                                      -- OPM�i��
      ,xxcmn_item_mst_b     ximb                                      -- OPM�i�ڃA�h�I��
      ,xxcmm_system_items_b xsib                                      -- Disc�i�ڃA�h�I��
WHERE msib.segment1 = iimb.item_no
  AND msib.organization_id = xxcoi_common_pkg.get_organization_id('S01')
  AND msib.inventory_item_status_code <> 'Inactive'
  AND msib.customer_order_enabled_flag = 'Y'
  AND msib.mtl_transactions_enabled_flag = 'Y'
  AND msib.stock_enabled_flag = 'Y'
  AND msib.returnable_flag = 'Y'
  AND iimb.item_id = ximb.item_id
  AND iimb.item_id = xsib.item_id 
  AND iimb.attribute26 = '1'
/
COMMENT ON TABLE xxcoi_txn_enable_item_info_v IS '�݌Ɏ���\�i�ڃr���['
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.inventory_item_id IS '�i��ID'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.organization_id IS '�݌ɑg�DID'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.item_code IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.item_short_name IS '�i�ڗ���'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.primary_uom_code IS '��P��'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.policy_group_apply_date IS '�Q���ޓK�p�J�n��'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.policy_group_new IS '�Q�R�[�h(�V)'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.policy_group_old IS '���Q�R�[�h'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.discrete_cost_apply_date IS '�c�ƌ����K�p�J�n��'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.discrete_cost_new IS '�c�ƌ���(�V)'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.discrete_cost_old IS '���c�ƌ���'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.fixed_price_apply_date IS '�艿�K�p�J�n��'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.fixed_price_new IS '�艿(�V)'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.fixed_price_old IS '���艿'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.case_in_qty IS '�P�[�X����'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.start_date_active IS 'OPM�K�p�J�n��'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.end_date_active IS 'OPM�K�p�I����'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.active_flag IS 'OPM�K�p�σt���O'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.baracha_div IS '�o�����敪'
/
