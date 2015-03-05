/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_LOT_TRANS_INFO_V
 * Description     : ���b�g�ʎ������ʃr���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/11/04    1.0   Y.Umino          �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_lot_trans_info_v
  (  transaction_id                                                   -- ���ID
   , transaction_set_id                                               -- ����Z�b�gID
   , organization_id                                                  -- �݌ɑg�DID
   , slip_num                                                         -- �`�[No
   , item_kbn                                                         -- ���i�敪
   , item_kbn_name                                                    -- ���i�敪��
   , parent_item_id                                                   -- �e�i��ID
   , parent_item_cd                                                   -- �e�i�ڃR�[�h
   , parent_item_name                                                 -- �e�i�ږ���
   , child_item_id                                                    -- �q�i��ID
   , child_item_cd                                                    -- �q�i�ڃR�[�h
   , child_item_name                                                  -- �q�i�ږ���
   , lot                                                              -- ���b�g
   , difference_summary_code                                          -- �ŗL�L��
   , subinventory_code                                                -- �ۊǏꏊ
   , location_code                                                    -- ���P�[�V�����R�[�h
   , location_name                                                    -- ���P�[�V��������
   , case_in_qty                                                      -- ����
   , case_qty                                                         -- �P�[�X��
   , singly_qty                                                       -- �o����
   , summary_qty                                                      -- ����
   , transaction_date                                                 -- ���t
   , transfer_subinventory                                            -- �]����ۊǏꏊ�R�[�h
   , transfer_subinventory_name                                       -- �]����ۊǏꏊ����
   , transaction_type_code                                            -- ����^�C�v�R�[�h
   , transaction_type_name                                            -- ����^�C�v����
   , status_code                                                      -- �X�e�[�^�X�i�R�[�h�j
   , status_name                                                      -- �X�e�[�^�X�i���́j
   , transfer_location_code                                           -- �]���惍�P�[�V�����R�[�h
   , sign_div                                                         -- �����敪
   , source_code                                                      -- �\�[�X�R�[�h
   , relation_key                                                     -- �R�t���L�[
   , reserve_transaction_type_code                                    -- ����������^�C�v�R�[�h
   , reason                                                           -- �E�v
   , fix_user_code                                                    -- �m��҃R�[�h
   , fix_user_name                                                    -- �m��Җ�
   , created_by                                                       -- �쐬��
   , creation_date                                                    -- �쐬��
   , last_updated_by                                                  -- �ŏI�X�V��
   , last_update_date                                                 -- �ŏI�X�V��
   , last_update_login                                                -- �ŏI�X�V���O�C��
  )
AS
  SELECT
    xltt.transaction_id
   ,xltt.transaction_set_id
   ,xltt.organization_id
   ,xltt.slip_num
   ,mcv.segment1
   ,mcv.description
   ,xltt.parent_item_id
   ,iimb_oya.item_no
   ,ximb_oya.item_short_name
   ,xltt.child_item_id
   ,iimb_ko.item_no
   ,ximb_ko.item_short_name
   ,xltt.lot
   ,xltt.difference_summary_code
   ,xltt.subinventory_code
   ,xltt.location_code
   ,xmwl.location_name
   ,xltt.case_in_qty
   ,xltt.case_qty
   ,xltt.singly_qty
   ,xltt.summary_qty
   ,TO_CHAR(xltt.transaction_date, 'yyyy/mm/dd')
   ,xltt.transfer_subinventory
   ,(
      CASE
        WHEN ( LENGTHB(xltt.transfer_subinventory) = '4' ) THEN
          ( SELECT mil.attribute12
            FROM mtl_item_locations  mil
            WHERE mil.segment1 = xltt.transfer_subinventory
           )
        ELSE
          ( SELECT msi.description
            FROM mtl_secondary_inventories  msi
            WHERE msi.organization_id = xltt.organization_id
              AND msi.secondary_inventory_name = xltt.transfer_subinventory
           )
      END
     ) transfer_subinventory_name
   ,(
      CASE
        WHEN ( xltt.transaction_type_code = '10' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt1.lookup_code
            FROM fnd_lookup_values  flv_tt1
            WHERE flv_tt1.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt1.lookup_code = '11'
              AND flv_tt1.attribute1 = xltt.transaction_type_code
              AND flv_tt1.enabled_flag = 'Y'
              AND flv_tt1.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt1.start_date_active
                                                     AND     NVL(flv_tt1.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '10' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt2.lookup_code
            FROM fnd_lookup_values  flv_tt2
            WHERE flv_tT2.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt2.lookup_code = '12'
              AND flv_tt2.attribute1 = xltt.transaction_type_code
              AND flv_tt2.enabled_flag = 'Y'
              AND flv_tt2.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt2.start_date_active
                                                     AND     NVL(flv_tt2.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '20' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt3.lookup_code
            FROM fnd_lookup_values  flv_tt3
            WHERE flv_tt3.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt3.lookup_code = '21'
              AND flv_tt3.attribute1 = xltt.transaction_type_code
              AND flv_tt3.enabled_flag = 'Y'
              AND flv_tt3.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt3.start_date_active
                                                     AND     NVL(flv_tt3.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '20' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt4.lookup_code
            FROM fnd_lookup_values  flv_tt4
            WHERE flv_tt4.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt4.lookup_code = '22'
              AND flv_tt4.attribute1 = xltt.transaction_type_code
              AND flv_tt4.enabled_flag = 'Y'
              AND flv_tt4.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt4.start_date_active
                                                     AND     NVL(flv_tt4.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '70' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt5.lookup_code
            FROM fnd_lookup_values  flv_tt5
            WHERE flv_tt5.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt5.lookup_code = '71'
              AND flv_tt5.attribute1 = xltt.transaction_type_code
              AND flv_tt5.enabled_flag = 'Y'
              AND flv_tt5.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt5.start_date_active
                                                     AND     NVL(flv_tt5.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '70' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt6.lookup_code
            FROM fnd_lookup_values  flv_tt6
            WHERE flv_tt6.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt6.lookup_code = '72'
              AND flv_tt6.attribute1 = xltt.transaction_type_code
              AND flv_tt6.enabled_flag = 'Y'
              AND flv_tt6.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt6.start_date_active
                                                     AND     NVL(flv_tt6.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        ELSE flv_tt.lookup_code
      END
     ) transaction_type_code
   ,(
      CASE
        WHEN ( xltt.transaction_type_code = '10' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt1.meaning
            FROM fnd_lookup_values  flv_tt1
            WHERE flv_tt1.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt1.lookup_code = '11'
              AND flv_tt1.attribute1 = xltt.transaction_type_code
              AND flv_tt1.enabled_flag = 'Y'
              AND flv_tt1.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt1.start_date_active
                                                     AND     NVL(flv_tt1.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '10' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt2.meaning
            FROM fnd_lookup_values  flv_tt2
            WHERE flv_tT2.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt2.lookup_code = '12'
              AND flv_tt2.attribute1 = xltt.transaction_type_code
              AND flv_tt2.enabled_flag = 'Y'
              AND flv_tt2.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt2.start_date_active
                                                     AND     NVL(flv_tt2.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '20' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt3.meaning
            FROM fnd_lookup_values  flv_tt3
            WHERE flv_tt3.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt3.lookup_code = '21'
              AND flv_tt3.attribute1 = xltt.transaction_type_code
              AND flv_tt3.enabled_flag = 'Y'
              AND flv_tt3.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt3.start_date_active
                                                     AND     NVL(flv_tt3.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '20' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt4.meaning
            FROM fnd_lookup_values  flv_tt4
            WHERE flv_tt4.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt4.lookup_code = '22'
              AND flv_tt4.attribute1 = xltt.transaction_type_code
              AND flv_tt4.enabled_flag = 'Y'
              AND flv_tt4.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt4.start_date_active
                                                     AND     NVL(flv_tt4.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '70' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt5.meaning
            FROM fnd_lookup_values  flv_tt5
            WHERE flv_tt5.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt5.lookup_code = '71'
              AND flv_tt5.attribute1 = xltt.transaction_type_code
              AND flv_tt5.enabled_flag = 'Y'
              AND flv_tt5.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt5.start_date_active
                                                     AND     NVL(flv_tt5.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '70' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt6.meaning
            FROM fnd_lookup_values  flv_tt6
            WHERE flv_tt6.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt6.lookup_code = '72'
              AND flv_tt6.attribute1 = xltt.transaction_type_code
              AND flv_tt6.enabled_flag = 'Y'
              AND flv_tt6.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt6.start_date_active
                                                     AND     NVL(flv_tt6.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        ELSE flv_tt.meaning
      END
     ) transaction_type_name
   ,flv_st.lookup_code
   ,flv_st.meaning
   ,xltt.transfer_location_code
   ,xltt.sign_div
   ,xltt.source_code
   ,xltt.relation_key
   ,NULL
   ,NULL
   ,NULL
   ,NULL
   ,xltt.created_by
   ,xltt.creation_date
   ,xltt.last_updated_by
   ,xltt.last_update_date
   ,xltt.last_update_login
  FROM
    xxcoi_lot_transactions_temp         xltt               -- ���b�g�ʎ��TEMP
   ,mtl_system_items_b                  msib_oya           -- Disc�i�ڃ}�X�^_�e
   ,mtl_system_items_b                  msib_ko            -- Disc�i�ڃ}�X�^_�q
   ,ic_item_mst_b                       iimb_oya           -- OPM�i�ڃ}�X�^_�e
   ,ic_item_mst_b                       iimb_ko            -- OPM�i�ڃ}�X�^_�q
   ,xxcmn_item_mst_b                    ximb_oya           -- OPM�i�ڃA�h�I���}�X�^_�e
   ,xxcmn_item_mst_b                    ximb_ko            -- OPM�i�ڃA�h�I���}�X�^_�q
   ,gmi_item_categories                 gic                -- �i�ڃJ�e�S��
   ,mtl_category_sets_vl                mcsv               -- �i�ڃJ�e�S���Z�b�g�r���[
   ,mtl_categories_vl                   mcv                -- �i�ڃJ�e�S���r���[
   ,xxcoi_warehouse_location_mst_v      xmwl               -- �q�Ƀ��P�[�V�����}�X�^
   ,fnd_lookup_values                   flv_st             -- �N�C�b�N�R�[�h�i�X�e�[�^�X�j
   ,fnd_lookup_values                   flv_tt             -- �N�C�b�N�R�[�h�i����^�C�v���j
  WHERE
      xltt.organization_id = msib_oya.organization_id
  AND xltt.parent_item_id = msib_oya.inventory_item_id
  AND xltt.organization_id = msib_ko.organization_id(+)
  AND xltt.child_item_id = msib_ko.inventory_item_id(+)
  AND msib_oya.segment1 = iimb_oya.item_no
  AND msib_ko.segment1 = iimb_ko.item_no(+)
  AND iimb_oya.item_id = ximb_oya.item_id
  AND xltt.transaction_date
        BETWEEN ximb_oya.start_date_active AND ximb_oya.end_date_active
  AND iimb_ko.item_id = ximb_ko.item_id(+)
  AND ( xltt.child_item_id IS NULL OR
      xltt.transaction_date
        BETWEEN ximb_ko.start_date_active AND ximb_ko.end_date_active )
  AND gic.category_set_id = mcsv.category_set_id(+)
  AND ((xltt.child_item_id IS NULL) OR (xltt.child_item_id IS NOT NULL AND mcsv.category_set_name = '�{�Џ��i�敪'))
  AND gic.category_id = mcv.category_id(+)
  AND gic.item_id(+) = iimb_ko.item_id
  AND xltt.organization_id = xmwl.organization_id(+)
  AND xltt.base_code = xmwl.base_code(+)
  AND xltt.subinventory_code = xmwl.subinventory_code(+)
  AND xltt.location_code = xmwl.location_code(+)
  AND flv_st.lookup_type = 'XXCOI1_CREATE_DIV'
  AND flv_st.lookup_code = 10
  AND flv_st.enabled_flag = 'Y'
  AND flv_st.language = USERENV('LANG')
  AND xxccp_common_pkg2.get_process_date BETWEEN flv_st.start_date_active
                                         AND     NVL(flv_st.end_date_active, xxccp_common_pkg2.get_process_date)
  AND flv_tt.lookup_type = 'XXCOI1_TRANSACTION_TYPE_NAME'
  AND flv_tt.lookup_code = xltt.transaction_type_code
  AND flv_tt.enabled_flag = 'Y'
  AND flv_tt.language = USERENV('LANG')
  AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt.start_date_active
                                         AND     NVL(flv_tt.end_date_active, xxccp_common_pkg2.get_process_date)
  UNION ALL
  SELECT
    xlt.transaction_id
   ,xlt.transaction_set_id
   ,xlt.organization_id
   ,xlt.slip_num
   ,mcv.segment1
   ,mcv.description
   ,xlt.parent_item_id
   ,iimb_oya.item_no
   ,ximb_oya.item_short_name
   ,xlt.child_item_id
   ,iimb_ko.item_no
   ,ximb_ko.item_short_name
   ,xlt.lot
   ,xlt.difference_summary_code
   ,xlt.subinventory_code
   ,xlt.location_code
   ,xmwl.location_name
   ,xlt.case_in_qty
   ,xlt.case_qty
   ,xlt.singly_qty
   ,xlt.summary_qty
   ,TO_CHAR(xlt.transaction_date, 'yyyy/mm/dd')
   ,xlt.transfer_subinventory
   ,(
      CASE
        WHEN ( LENGTHB(xlt.transfer_subinventory) = '4' ) THEN
          ( SELECT mil.attribute12
            FROM mtl_item_locations  mil
            WHERE mil.segment1 = xlt.transfer_subinventory
           )
        ELSE
          ( SELECT msi.description
            FROM mtl_secondary_inventories  msi
            WHERE msi.organization_id = xlt.organization_id
              AND msi.secondary_inventory_name = xlt.transfer_subinventory
           )
      END
     ) transfer_subinventory_name
   ,(
      CASE
        WHEN ( xlt.transaction_type_code = '10' AND xlt.summary_qty > 0 ) THEN
          ( SELECT flv_t1.lookup_code
            FROM fnd_lookup_values  flv_t1
            WHERE flv_t1.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t1.lookup_code = '11'
              AND flv_t1.attribute1 = xlt.transaction_type_code
              AND flv_t1.enabled_flag = 'Y'
              AND flv_t1.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t1.start_date_active
                                                     AND     NVL(flv_t1.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '10' AND xlt.summary_qty < 0 ) THEN
          ( SELECT flv_t2.lookup_code
            FROM fnd_lookup_values  flv_t2
            WHERE flv_t2.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t2.lookup_code = '12'
              AND flv_t2.attribute1 = xlt.transaction_type_code
              AND flv_t2.enabled_flag = 'Y'
              AND flv_t2.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t2.start_date_active
                                                     AND     NVL(flv_t2.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '20' AND xlt.summary_qty > 0 ) THEN
          ( SELECT flv_t3.lookup_code
            FROM fnd_lookup_values  flv_t3
            WHERE flv_t3.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t3.lookup_code = '21'
              AND flv_t3.attribute1 = xlt.transaction_type_code
              AND flv_t3.enabled_flag = 'Y'
              AND flv_t3.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t3.start_date_active
                                                     AND     NVL(flv_t3.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '20' AND xlt.summary_qty < 0 ) THEN
          ( SELECT flv_t4.lookup_code
            FROM fnd_lookup_values  flv_t4
            WHERE flv_t4.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t4.lookup_code = '22'
              AND flv_t4.attribute1 = xlt.transaction_type_code
              AND flv_t4.enabled_flag = 'Y'
              AND flv_t4.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t4.start_date_active
                                                     AND     NVL(flv_t4.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '70' AND xlt.summary_qty > 0 ) THEN
          ( SELECT flv_t5.lookup_code
            FROM fnd_lookup_values  flv_t5
            WHERE flv_t5.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t5.lookup_code = '71'
              AND flv_t5.attribute1 = xlt.transaction_type_code
              AND flv_t5.enabled_flag = 'Y'
              AND flv_t5.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t5.start_date_active
                                                     AND     NVL(flv_t5.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '70' AND xlt.summary_qty < 0 ) THEN
          ( SELECT flv_t6.lookup_code
            FROM fnd_lookup_values  flv_t6
            WHERE flv_t6.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t6.lookup_code = '72'
              AND flv_t6.attribute1 = xlt.transaction_type_code
              AND flv_t6.enabled_flag = 'Y'
              AND flv_t6.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t6.start_date_active
                                                     AND     NVL(flv_t6.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        ELSE flv_tt.lookup_code
      END
     ) transaction_type_code
   ,(
      CASE
        WHEN ( xlt.transaction_type_code = '10' AND xlt.summary_qty > 0 ) THEN
          ( SELECT flv_t1.meaning
            FROM fnd_lookup_values  flv_t1
            WHERE flv_t1.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t1.lookup_code = '11'
              AND flv_t1.attribute1 = xlt.transaction_type_code
              AND flv_t1.enabled_flag = 'Y'
              AND flv_t1.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t1.start_date_active
                                                     AND     NVL(flv_t1.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '10' AND xlt.summary_qty < 0 ) THEN
          ( SELECT flv_t2.meaning
            FROM fnd_lookup_values  flv_t2
            WHERE flv_t2.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t2.lookup_code = '12'
              AND flv_t2.attribute1 = xlt.transaction_type_code
              AND flv_t2.enabled_flag = 'Y'
              AND flv_t2.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t2.start_date_active
                                                     AND     NVL(flv_t2.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '20' AND xlt.summary_qty > 0 ) THEN
          ( SELECT flv_t3.meaning
            FROM fnd_lookup_values  flv_t3
            WHERE flv_t3.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t3.lookup_code = '21'
              AND flv_t3.attribute1 = xlt.transaction_type_code
              AND flv_t3.enabled_flag = 'Y'
              AND flv_t3.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t3.start_date_active
                                                     AND     NVL(flv_t3.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '20' AND xlt.summary_qty < 0 ) THEN
          ( SELECT flv_t4.meaning
            FROM fnd_lookup_values  flv_t4
            WHERE flv_t4.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t4.lookup_code = '22'
              AND flv_t4.attribute1 = xlt.transaction_type_code
              AND flv_t4.enabled_flag = 'Y'
              AND flv_t4.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t4.start_date_active
                                                     AND     NVL(flv_t4.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '70' AND xlt.summary_qty > 0 ) THEN
          ( SELECT flv_t5.meaning
            FROM fnd_lookup_values  flv_t5
            WHERE flv_t5.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t5.lookup_code = '71'
              AND flv_t5.attribute1 = xlt.transaction_type_code
              AND flv_t5.enabled_flag = 'Y'
              AND flv_t5.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t5.start_date_active
                                                     AND     NVL(flv_t5.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '70' AND xlt.summary_qty < 0 ) THEN
          ( SELECT flv_t6.meaning
            FROM fnd_lookup_values  flv_t6
            WHERE flv_t6.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t6.lookup_code = '72'
              AND flv_t6.attribute1 = xlt.transaction_type_code
              AND flv_t6.enabled_flag = 'Y'
              AND flv_t6.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t6.start_date_active
                                                     AND     NVL(flv_t6.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        ELSE flv_tt.meaning
      END
     ) transaction_type_name
   ,flv_st.lookup_code
   ,flv_st.meaning
   ,xlt.transfer_location_code
   ,NULL
   ,xlt.source_code
   ,xlt.relation_key
   ,xlt.reserve_transaction_type_code
   ,xlt.reason
   ,xlt.fix_user_code
   ,xlt.fix_user_name
   ,xlt.created_by
   ,xlt.creation_date
   ,xlt.last_updated_by
   ,xlt.last_update_date
   ,xlt.last_update_login
  FROM
    xxcoi_lot_transactions              xlt                -- ���b�g�ʎ������
   ,mtl_system_items_b                  msib_oya           -- Disc�i�ڃ}�X�^_�e
   ,mtl_system_items_b                  msib_ko            -- Disc�i�ڃ}�X�^_�q
   ,ic_item_mst_b                       iimb_oya           -- OPM�i�ڃ}�X�^_�e
   ,ic_item_mst_b                       iimb_ko            -- OPM�i�ڃ}�X�^_�q
   ,xxcmn_item_mst_b                    ximb_oya           -- OPM�i�ڃA�h�I���}�X�^_�e
   ,xxcmn_item_mst_b                    ximb_ko            -- OPM�i�ڃA�h�I���}�X�^_�q
   ,gmi_item_categories                 gic                -- �i�ڃJ�e�S��
   ,mtl_category_sets_vl                mcsv               -- �i�ڃJ�e�S���Z�b�g�r���[
   ,mtl_categories_vl                   mcv                -- �i�ڃJ�e�S���r���[
   ,xxcoi_warehouse_location_mst_v      xmwl               -- �q�Ƀ��P�[�V�����}�X�^
   ,fnd_lookup_values                   flv_st             -- �N�C�b�N�R�[�h�i�X�e�[�^�X�j
   ,fnd_lookup_values                   flv_tt             -- �N�C�b�N�R�[�h�i����^�C�v���j
  WHERE
      xlt.organization_id = msib_oya.organization_id
  AND xlt.parent_item_id = msib_oya.inventory_item_id
  AND xlt.organization_id = msib_ko.organization_id
  AND xlt.child_item_id = msib_ko.inventory_item_id
  AND msib_oya.segment1 = iimb_oya.item_no
  AND iimb_oya.item_id = ximb_oya.item_id
  AND xlt.transaction_date
        BETWEEN ximb_oya.start_date_active AND ximb_oya.end_date_active
  AND msib_ko.segment1 = iimb_ko.item_no
  AND iimb_ko.item_id = ximb_ko.item_id
  AND xlt.transaction_date
        BETWEEN ximb_ko.start_date_active AND ximb_ko.end_date_active
  AND gic.category_set_id = mcsv.category_set_id
  AND gic.category_set_id = mcsv.category_set_id
  AND mcsv.category_set_name = '�{�Џ��i�敪'
  AND gic.category_id = mcv.category_id
  AND gic.item_id = iimb_ko.item_id
  AND xlt.organization_id = xmwl.organization_id
  AND xlt.base_code = xmwl.base_code
  AND xlt.subinventory_code = xmwl.subinventory_code
  AND xlt.location_code = xmwl.location_code
  AND flv_st.lookup_type = 'XXCOI1_CREATE_DIV'
  AND flv_st.lookup_code = 20
  AND flv_st.enabled_flag = 'Y'
  AND flv_st.language = USERENV('LANG')
  AND xxccp_common_pkg2.get_process_date BETWEEN flv_st.start_date_active
                                         AND     NVL(flv_st.end_date_active, xxccp_common_pkg2.get_process_date)
  AND flv_tt.lookup_type = 'XXCOI1_TRANSACTION_TYPE_NAME'
  AND flv_tt.lookup_code = xlt.transaction_type_code
  AND flv_tt.enabled_flag = 'Y'
  AND flv_tt.language = USERENV('LANG')
  AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt.start_date_active
                                         AND     NVL(flv_tt.end_date_active, xxccp_common_pkg2.get_process_date)
/
COMMENT ON TABLE xxcoi_lot_trans_info_v IS '���b�g�ʎ�����쐬�Ɖ��ʃr���[';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transaction_id IS '���ID';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transaction_set_id IS '����Z�b�gID';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.organization_id IS '�݌ɑg�DID';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.slip_num IS '�`�[No';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.item_kbn IS '���i�敪';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.item_kbn_name IS '���i�敪��';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.parent_item_id IS '�e�i��ID';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.parent_item_cd IS '�e�i�ڃR�[�h';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.parent_item_name IS '�e�i�ږ���';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.child_item_id IS '�q�i��ID';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.child_item_cd IS '�q�i�ڃR�[�h';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.child_item_name IS '�q�i�ږ���';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.lot IS '���b�g';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.difference_summary_code IS '�ŗL�L��';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.subinventory_code IS '�ۊǏꏊ';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.location_code IS '���P�[�V�����R�[�h';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.location_name IS '���P�[�V��������';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.case_in_qty IS '����';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.case_qty IS '�P�[�X��';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.singly_qty IS '�o����';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.summary_qty IS '����';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transaction_date IS '���t';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transfer_subinventory IS '�]����ۊǏꏊ�R�[�h';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transfer_subinventory_name IS '�]����ۊǏꏊ����';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transaction_type_code IS '����^�C�v�R�[�h';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transaction_type_name IS '����^�C�v����';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.status_code IS '�X�e�[�^�X�i�R�[�h�j';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.status_name IS '�X�e�[�^�X�i���́j';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transfer_location_code IS '�]���惍�P�[�V�����R�[�h';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.sign_div IS '�����敪';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.source_code IS '�\�[�X�R�[�h';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.relation_key IS '�R�t���L�[';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.reserve_transaction_type_code IS '����������^�C�v�R�[�h';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.reason IS '�E�v';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.fix_user_code IS '�m��҃R�[�h';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.fix_user_name IS '�m��Җ�';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.created_by IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.creation_date IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.last_updated_by IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.last_update_date IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.last_update_login IS '�ŏI�X�V���O�C��';
/
