/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcoi_vd_col_m_mtc_v
 * Description     : VD�R�����}�X�^�����e�i���X��ʃr���[
 * Version         : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/18    1.0   SCS H.Wada       �V�K�쐬
 *  2008/12/04    1.1   SCS H.Wada       �C���iVD�R�����}�X�^���C���j
 *  2009/08/20    1.2   SCS T.Murakami   �݌ɑg�D���uS01�v���uZ99�v�ɕύX
 *  2009/09/08    1.3   SCS H.Sasaki     [0001266]OPM�i�ڃA�h�I���̔ŊǗ��Ή�
 *  2011/09/29    1.4   SCS K.Nakamura   [E_�{�ғ�_08440]�[�i��1�`5�A�{��1�`5�A�R�����X�V����ǉ�
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_VD_COL_M_MTC_V
  (vd_column_mst_id                                                           -- 1.VD�R�����}�X�^ID
  ,customer_id                                                                -- 2.�ڋqID
  ,column_no                                                                  -- 3.�R������
  ,item_code                                                                  -- 4.�i�ڃR�[�h(����)
  ,last_item_code                                                             -- 5.�i�ڃR�[�h(�O��)
-- == 2009/09/08 V1.3 Deleted START ===============================================================
--  ,item_name                                                                  -- 6.�i�ږ���(����)
--  ,last_item_name                                                             -- 7.�i�ږ���(�O��)
-- == 2009/09/08 V1.3 Deleted END   ===============================================================
  ,item_id                                                                    -- 8.�i��ID(����)
  ,last_item_id                                                               -- 9.�i��ID(�O��)
  ,primary_uom_code                                                           -- 10.��P��(����)
  ,last_primary_uom_code                                                      -- 11.��P��(�O��)
  ,inventory_quantity                                                         -- 12.��݌ɐ�(����)
  ,last_inventory_quantity                                                    -- 13.��݌ɐ�(�O��)
  ,price                                                                      -- 14.�P��(����)
  ,last_price                                                                 -- 15.�P��(�O��)
  ,hot_cold                                                                   -- 16.H/C�l(����)
  ,last_hot_cold                                                              -- 17.H/C�l(�O��)
  ,rack_quantity                                                              -- 18.���b�N��
-- == 2011/09/29 V1.4 Added   START ===============================================================
  ,dlv_date_1                                                                 -- 28.�[�i��1
  ,quantity_1                                                                 -- 29.�{��1
  ,dlv_date_2                                                                 -- 30.�[�i��2
  ,quantity_2                                                                 -- 31.�{��2
  ,dlv_date_3                                                                 -- 32.�[�i��3
  ,quantity_3                                                                 -- 33.�{��3
  ,dlv_date_4                                                                 -- 34.�[�i��4
  ,quantity_4                                                                 -- 35.�{��4
  ,dlv_date_5                                                                 -- 36.�[�i��5
  ,quantity_5                                                                 -- 37.�{��5
  ,column_change_date                                                         -- 38.�R�����ύX��
-- == 2011/09/29 V1.4 Added   END   ===============================================================
  ,created_by                                                                 -- 23.�쐬��
  ,creation_date                                                              -- 24.�쐬��
  ,last_updated_by                                                            -- 25.�ŏI�X�V��
  ,last_update_date                                                           -- 26.�ŏI�X�V��
  ,last_update_login                                                          -- 27.�ŏI�X�V���O�C��
  )
AS
SELECT   xmvc.vd_column_mst_id               AS vd_column_mst_id              -- 1.VD�R�����}�X�^ID
        ,xmvc.customer_id                    AS customer_id                   -- 2.�ڋqID
        ,xmvc.column_no                      AS column_no                     -- 3.�R������
        ,sub_query1.item_code                AS item_code                     -- 4.�i�ڃR�[�h(����)
        ,sub_query2.item_code                AS last_item_code                -- 5.�i�ڃR�[�h(�O��)
-- == 2009/09/08 V1.3 Deleted START ===============================================================
--        ,sub_query1.short_name               AS item_short_name               -- 6.�i�ږ���(����)
--        ,sub_query2.short_name               AS last_item_short_name          -- 7.�i�ږ���(�O��)
-- == 2009/09/08 V1.3 Deleted END   ===============================================================
        ,sub_query1.item_id                  AS item_id                       -- 8.�i��ID(����)
        ,sub_query2.item_id                  AS last_item_id                  -- 9.�i��ID(�O��)
        ,sub_query1.primary_unit_of_measure  AS primary_uom_code              -- 10.��P��(����)
        ,sub_query2.primary_unit_of_measure  AS last_primary_uom_code         -- 11.��P��(�O��)
        ,xmvc.inventory_quantity             AS inventory_quantity            -- 12.��݌ɐ�(����)
        ,xmvc.last_month_inventory_quantity  AS last_inventory_quantity       -- 13.��݌ɐ�(�O��)
        ,xmvc.price                          AS price                         -- 14.�P��(����)
        ,xmvc.last_month_price               AS last_price                    -- 15.�P��(�O��)
        ,xmvc.hot_cold                       AS hot_cold                      -- 16.H/C�l(����)
        ,xmvc.last_month_hot_cold            AS last_hot_cold                 -- 17.H/C�l(�O��)
        ,xmvc.rack_quantity                  AS rack_quantity                 -- 18.���b�N��
-- == 2011/09/29 V1.4 Added START   ===============================================================
        ,xmvc.dlv_date_1                     AS dlv_date1                     -- 28.�[�i��1
        ,xmvc.quantity_1                     AS quantity_1                    -- 29.�{��1
        ,xmvc.dlv_date_2                     AS dlv_date2                     -- 30.�[�i��2
        ,xmvc.quantity_2                     AS quantity_2                    -- 31.�{��2
        ,xmvc.dlv_date_3                     AS dlv_date3                     -- 32.�[�i��3
        ,xmvc.quantity_3                     AS quantity_3                    -- 33.�{��3
        ,xmvc.dlv_date_4                     AS dlv_date4                     -- 34.�[�i��4
        ,xmvc.quantity_4                     AS quantity_4                    -- 35.�{��4
        ,xmvc.dlv_date_5                     AS dlv_date_5                    -- 36.�[�i��5
        ,xmvc.quantity_5                     AS quantity_5                    -- 37.�{��5
        ,xmvc.column_change_date             AS column_change_date            -- 38.�R�����ύX��
-- == 2011/09/29 V1.4 Added END     ===============================================================
        ,xmvc.created_by                     AS created_by                    -- 23.�쐬��
        ,xmvc.creation_date                  AS creation_date                 -- 24.�쐬��
        ,xmvc.last_updated_by                AS last_updated_by               -- 25.�ŏI�X�V��
        ,xmvc.last_update_date               AS last_update_date              -- 26.�ŏI�X�V��
        ,xmvc.last_update_login              AS last_update_login             -- 27.�ŏI�X�V���O�C��
FROM     xxcoi_mst_vd_column                 xmvc                             -- VD�R�����}�X�^
-- == 2009/09/08 V1.3 Deleted START ===============================================================
--        ,(SELECT msib.segment1          AS item_code
--                ,ximb.item_short_name   AS short_name
--                ,msib.inventory_item_id AS item_id
--                ,msib.primary_uom_code  AS primary_unit_of_measure
--          FROM   mtl_system_items_b   msib
--                ,ic_item_mst_b        iimb
--                ,xxcmn_item_mst_b     ximb
--                ,xxcmm_system_items_b xsib
--          WHERE  msib.segment1 = iimb.item_no
--          AND    msib.organization_id = xxcoi_common_pkg.get_organization_id('S01')
--          AND    iimb.item_id = ximb.item_id
--          AND    iimb.item_id = xsib.item_id 
--          AND    iimb.attribute26 = '1')     sub_query1                       -- 2.�i�ڏ��T�u�N�G���[1
--        ,(SELECT msib.segment1          AS item_code
--                ,ximb.item_short_name   AS short_name
--                ,msib.inventory_item_id AS item_id
--                ,msib.primary_uom_code  AS primary_unit_of_measure
--          FROM   mtl_system_items_b   msib
--                ,ic_item_mst_b        iimb
--                ,xxcmn_item_mst_b     ximb
--                ,xxcmm_system_items_b xsib
--          WHERE  msib.segment1 = iimb.item_no
--          AND    msib.organization_id = xxcoi_common_pkg.get_organization_id('S01')
--          AND    iimb.item_id = ximb.item_id
--          AND    iimb.item_id = xsib.item_id 
--          AND    iimb.attribute26 = '1')     sub_query2                       -- 3.�i�ڏ��T�u�N�G���[2
        ,(SELECT msib.segment1          AS item_code
                ,msib.inventory_item_id AS item_id
                ,msib.primary_uom_code  AS primary_unit_of_measure
          FROM   mtl_system_items_b   msib
                ,ic_item_mst_b        iimb
                ,xxcmm_system_items_b xsib
          WHERE  msib.segment1 = iimb.item_no
          AND    msib.organization_id = xxcoi_common_pkg.get_organization_id('Z99')
          AND    iimb.item_id = xsib.item_id 
          AND    iimb.attribute26 = '1')     sub_query1                       -- 2.�i�ڏ��T�u�N�G���[1
        ,(SELECT msib.segment1          AS item_code
                ,msib.inventory_item_id AS item_id
                ,msib.primary_uom_code  AS primary_unit_of_measure
          FROM   mtl_system_items_b   msib
                ,ic_item_mst_b        iimb
                ,xxcmm_system_items_b xsib
          WHERE  msib.segment1 = iimb.item_no
          AND    msib.organization_id = xxcoi_common_pkg.get_organization_id('Z99')
          AND    iimb.item_id = xsib.item_id 
          AND    iimb.attribute26 = '1')     sub_query2                       -- 3.�i�ڏ��T�u�N�G���[2
-- == 2009/09/08 V1.3 Deleted END   ===============================================================
WHERE    xmvc.item_id                        = sub_query1.item_id(+)
AND      xmvc.last_month_item_id             = sub_query2.item_id(+)
-- == 2009/09/08 V1.3 Deleted START ===============================================================
--ORDER BY xmvc.customer_id, xmvc.column_no
-- == 2009/09/08 V1.3 Deleted END   ===============================================================
/
COMMENT ON TABLE xxcoi_vd_col_m_mtc_v IS 'VD�R�����}�X�^�����e�i���X��ʃr���['
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.vd_column_mst_id              IS 'VD�R�����}�X�^ID';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.customer_id                   IS '�ڋqID';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.column_no                     IS '�R������';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.item_code                     IS '�i�ڃR�[�h(����)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_item_code                IS '�i�ڃR�[�h(�O��)';
/
-- == 2009/09/08 V1.3 Deleted START ===============================================================
--COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.item_name                     IS '�i�ږ���(����)';
--/
--COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_item_name                IS '�i�ږ���(�O��)';
--/
-- == 2009/09/08 V1.3 Deleted END   ===============================================================
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.item_id                       IS '�i��ID(����)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_item_id                  IS '�i��ID(�O��)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.primary_uom_code              IS '��P��(����)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_primary_uom_code         IS '��P��(�O��)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.inventory_quantity            IS '��݌ɐ�(����)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_inventory_quantity       IS '��݌ɐ�(�O��)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.price                         IS '�P��(����)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_price                    IS '�P��(�O��)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.hot_cold                      IS 'H/C�l(����)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_hot_cold                 IS 'H/C�l(�O��)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.rack_quantity                 IS '���b�N��';
/
-- == 2011/09/29 V1.4 Added   START ===============================================================
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.dlv_date_1                    IS '�[�i��1';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.quantity_1                    IS '�{��1';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.dlv_date_2                    IS '�[�i��2';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.quantity_2                    IS '�{��2';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.dlv_date_3                    IS '�[�i��3';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.quantity_3                    IS '�{��3';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.dlv_date_4                    IS '�[�i��4';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.quantity_4                    IS '�{��4';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.dlv_date_5                    IS '�[�i��5';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.quantity_5                    IS '�{��5';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.column_change_date            IS '�R�����ύX��';
/
-- == 2011/09/29 V1.4 Added   END   ===============================================================
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.created_by                    IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.creation_date                 IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_updated_by               IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_update_date              IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_update_login             IS '�ŏI�X�V���O�C��';
/
