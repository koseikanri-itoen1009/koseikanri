CREATE OR REPLACE PACKAGE BODY xxwip200001
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip200001(BODY)
 * Description            : ���Y�o�b�`���b�g�ڍ׉�ʃf�[�^�\�[�X�p�b�P�[�W(BODY)
 * MD.050                 : T_MD050_BPO_200_���Y�o�b�`.doc
 * MD.070                 : T_MD070_BPO_20A_���Y�o�b�`�ꗗ���.doc
 * Version                : 1.8
 *
 * Program List
 *  --------------------  ---- ----- -------------------------------------------------
 *   Name                 Type  Ret   Description
 *  --------------------  ---- ----- -------------------------------------------------
 *  blk_ilm_qry             P    -    �f�[�^�擾
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/08/28   1.0   D.Nihei          �V�K�쐬
 *  2008/10/07   1.1   D.Nihei          ������Q#123�Ή��iPT 6-2_31�j
 *  2008/10/22   1.2   D.Nihei          ������Q#123�Ή��iPT 6-2_31�j(���b�g�X�e�[�^�XVIEW�ӏ��C��)
 *  2008/10/29   1.3   D.Nihei          ������Q#481�Ή��iORDER BY��ҏW) 
 *  2008/11/19   1.4   D.Nihei          ������Q#681�Ή��i�����ǉ�) 
 *  2008/12/02   1.5   D.Nihei          �{�ԏ�Q#251�Ή��i�����ǉ�) 
 *  2008/12/19   1.6   D.Nihei          �{�ԏ�Q#645�Ή��i�����C��) 
 *                                      �{�ԏ�Q#648�Ή��i�����C��) 
 *  2008/12/24   1.7   D.Nihei          �{�ԏ�Q#836�Ή��i���o�ӏ��ҏW) 
 *                                      �{�ԏ�Q#837�Ή��i���o�ӏ��ҏW) 
 *  2009/01/05   1.8   D.Nihei          �{�ԏ�Q#912�Ή��i���oSQL�ǉ�) 
 *****************************************************************************************/
--
  -- �萔�錾
  cv_status_normal        CONSTANT VARCHAR2(1)  := '0';
  cv_status_warning       CONSTANT VARCHAR2(1)  := '1';
  cv_status_error         CONSTANT VARCHAR2(1)  := '2';
  cv_shizai               CONSTANT VARCHAR2(1)  := '2';
--
  /***********************************************************************************
   * Procedure Name   : blk_ilm_qry
   * Description      : �f�[�^�擾(REF�J�[�\���I�[�v��)
   ***********************************************************************************/
  PROCEDURE blk_ilm_qry(
    ior_ilm_data            IN OUT NOCOPY tbl_ilm_block
  , in_material_detail_id   IN gme_material_details.material_detail_id%TYPE   -- ���Y�����ڍ�ID
  , id_material_date        IN DATE                                           -- �������ɗ\���
  )
  IS
--
    -- �ϐ��錾
    lt_item_class_code       xxcmn_item_categories5_v.item_class_code%TYPE;       -- �i�ڋ敪
    lt_prod_class_code       xxcmn_item_categories5_v.prod_class_code%TYPE;       -- ���i�敪
    lt_location1             xxcmn_item_locations_v.segment1%TYPE;                -- �o�ɑq��1
    lt_location2             xxcmn_item_locations_v.segment1%TYPE;                -- �o�ɑq��2
    lt_location3             xxcmn_item_locations_v.segment1%TYPE;                -- �o�ɑq��3
    lt_location4             xxcmn_item_locations_v.segment1%TYPE;                -- �o�ɑq��4
    lt_location5             xxcmn_item_locations_v.segment1%TYPE;                -- �o�ɑq��5
    lt_item_id               xxcmn_item_mst_v.item_id%TYPE;                       -- �i��ID
    lt_inv_item_id           xxcmn_item_mst_v.inventory_item_id%TYPE;             -- INV�i��ID
    lt_item_no               xxcmn_item_mst_v.item_no%TYPE;                       -- �i��No
    wk_sql1                  VARCHAR2(32767);
    wk_sql2                  VARCHAR2(32767);
    lt_batch_id              gme_batch_header.batch_id%TYPE;                      -- �o�b�`ID
    TYPE wk_cur IS REF CURSOR;
    wk_cv   wk_cur;
    ln_cnt                   NUMBER;                                              -- �z��̓Y��
-- 2008/10/22 D.Nihei ADD START
    lt_dummy                 ic_lots_mst.attribute23%TYPE;                        -- 
-- 2008/10/22 D.Nihei ADD END
-- 2008/12/24 D.Nihei ADD START �{�ԏ�Q#837
    lt_prod_item_id          ic_lots_mst.item_id%TYPE;                            -- �i��ID(�����i)
    lt_prod_lot_id           ic_lots_mst.lot_id%TYPE;                             -- ���b�gID(�����i)
-- 2008/12/24 D.Nihei ADD END
--
  BEGIN
--
    BEGIN
      --==========================
      -- �Ώۑq�ɏ��擾
      --==========================
      SELECT gmd.batch_id
           , gmd.item_id
           , gmd.attribute13
           , gmd.attribute18
           , gmd.attribute19
           , gmd.attribute20
           , gmd.attribute21
      INTO   lt_batch_id
           , lt_item_id
           , lt_location1
           , lt_location2
           , lt_location3
           , lt_location4
           , lt_location5
      FROM   gme_material_details gmd -- ���Y�����ڍ�
      WHERE  gmd.material_detail_id = in_material_detail_id
      ;
--
      --==========================
      -- �i�ڋ敪�A���i�敪�擾
      --==========================
      SELECT ximv.item_no           item_no
           , ximv.inventory_item_id inventory_item_id
           , xicv.item_class_code   item_class_code
           , xicv.prod_class_code   prod_class_code
      INTO   lt_item_no
           , lt_inv_item_id
           , lt_item_class_code
           , lt_prod_class_code
      FROM   xxcmn_item_mst_v         ximv  -- OPM�i�ڃ}�X�^VIEW
           , xxcmn_item_categories5_v xicv  -- �i�ڃJ�e�S�����VIEW5
      WHERE  ximv.item_id = xicv.item_id
      AND    xicv.item_id = lt_item_id
      ;
-- 2008/12/24 D.Nihei ADD START �{�ԏ�Q#837
      --==========================
      -- �����i���擾
      --==========================
      BEGIN
        SELECT item_id
             , lot_id
        INTO   lt_prod_item_id
             , lt_prod_lot_id
        FROM   ic_tran_pnd           
        WHERE  doc_id      = lt_batch_id 
        AND    doc_type    = 'PROD'
        AND    delete_mark = 0
        AND    line_type   = 1
        AND    reverse_id  IS NULL
        AND    lot_id      <> 0
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_prod_item_id := 0;
          lt_prod_lot_id  := 0;
      END;
-- 2008/12/24 D.Nihei ADD END
--
      --==========================
      -- ���ISQL�쐬
      --==========================
      wk_sql1 := NULL;
      wk_sql2 := NULL;
      wk_sql1 := wk_sql1 || 'SELECT  enable_lot.inventory_location_id      storehouse_id            '; -- �ۊǑq��ID
      wk_sql1 := wk_sql1 || '      , enable_lot.storehouse_code            storehouse_code          '; -- �ۊǑq��(�R�[�h)
      wk_sql1 := wk_sql1 || '      , enable_lot.description                storehouse_name          '; -- �ۊǑq��(����)
      wk_sql1 := wk_sql1 || '      , ' || lt_batch_id || '                 batch_id                 '; -- �o�b�`ID
      wk_sql1 := wk_sql1 || '      , ' || in_material_detail_id || '       material_detail_id       '; -- ���Y�����ڍ�ID
      wk_sql1 := wk_sql1 || '      , enable_lot.mtl_detail_addon_id        mtl_detail_addon_id      '; -- ���Y�����ڍ׃A�h�I��ID
      wk_sql1 := wk_sql1 || '      , enable_lot.mov_lot_dtl_id             mov_lot_dtl_id           '; -- �ړ����b�g�ڍ�ID
      wk_sql1 := wk_sql1 || '      , NULL                                  trans_id                 '; -- 
      wk_sql1 := wk_sql1 || '      , enable_lot.item_id                    item_id                  '; -- �i��ID
      wk_sql1 := wk_sql1 || '      , ''' || lt_item_no || '''              item_no                  '; -- �i��(�R�[�h)
      wk_sql1 := wk_sql1 || '      , enable_lot.lot_id                     lot_id                   '; -- ���b�gID
      --==========================
      -- ����
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
        wk_sql1 := wk_sql1 || '    , NULL ';
      --==========================
      -- ���ވȊO
      --==========================
      ELSE
        wk_sql1 := wk_sql1 || '    , ilm.lot_no ';
      END IF;
      wk_sql1 := wk_sql1 || '                                              lot_no                   '; -- ���b�gNo
      wk_sql1 := wk_sql1 || '      , ilm.attribute24                       lot_create_type          '; -- �쐬�敪
      wk_sql1 := wk_sql1 || '      , enable_lot.instructions_qty           instructions_qty         '; -- �w������
      wk_sql1 := wk_sql1 || '      , enable_lot.instructions_qty           instructions_qty_orig    '; -- ���w������
      --==========================
      -- ����
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
--        wk_sql1 := wk_sql1 || '    , xxcmn_common_pkg.get_stock_qty(enable_lot.inventory_location_id, enable_lot.item_id, NULL ) stock_qty'; -- �݌ɑ���
        wk_sql1 := wk_sql1 || '    ,( ';
        wk_sql1 := wk_sql1 || '      (SELECT NVL(SUM(ili.loct_onhand), 0) ';
        wk_sql1 := wk_sql1 || '       FROM   ic_whse_mst         iwm ';
        wk_sql1 := wk_sql1 || '             ,mtl_item_locations  mil ';
        wk_sql1 := wk_sql1 || '             ,ic_loct_inv         ili ';
        wk_sql1 := wk_sql1 || '       WHERE  mil.segment1              = ili.location ';
        wk_sql1 := wk_sql1 || '       AND    mil.organization_id       = iwm.mtl_organization_id ';
        wk_sql1 := wk_sql1 || '       AND    mil.inventory_location_id = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND    ili.item_id               = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND    ili.lot_id                = ilm.lot_id) ';
        wk_sql1 := wk_sql1 || '       + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mril.ship_to_quantity),0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.ship_to_locat_id   = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.item_id            = enable_lot.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status             IN (''05'',''06'') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg    = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg         = ''N'') ';
        wk_sql1 := wk_sql1 || '      - ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mril.shipped_quantity),0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.shipped_locat_id   = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.item_id            = enable_lot.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status             IN (''04'',''06'') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg    = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg         = ''N'') ';
        wk_sql1 := wk_sql1 || '      - ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(CASE ';
        wk_sql1 := wk_sql1 || '               WHEN (otta.order_category_code = ''ORDER'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 ola.shipped_quantity ';
        wk_sql1 := wk_sql1 || '                 NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0) ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql1 := wk_sql1 || '               WHEN (otta.order_category_code = ''RETURN'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 ola.shipped_quantity * -1 ';
        wk_sql1 := wk_sql1 || '                 (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1 ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql1 := wk_sql1 || '               END), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxwsh_order_headers_all    oha  ';
        wk_sql1 := wk_sql1 || '             , xxwsh_order_lines_all      ola  ';
-- 2008/12/19 D.Nihei ADD START
        wk_sql1 := wk_sql1 || '             , xxinv_mov_lot_details      mld  ';
-- 2008/12/19 D.Nihei ADD END
        wk_sql1 := wk_sql1 || '             , oe_transaction_types_all   otta ';
        wk_sql1 := wk_sql1 || '       WHERE   ola.shipping_inventory_item_id = ' || lt_inv_item_id ;
-- 2008/12/19 D.Nihei ADD START
        wk_sql1 := wk_sql1 || '       AND     ola.order_line_id              = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code         = ''10'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code           = ''20'' ';
-- 2008/12/19 D.Nihei ADD END
        wk_sql1 := wk_sql1 || '       AND     oha.deliver_from_id            = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.order_header_id            = ola.order_header_id ';
        wk_sql1 := wk_sql1 || '       AND     otta.transaction_type_id       = oha.order_type_id ';
        wk_sql1 := wk_sql1 || '       AND     otta.attribute1                IN (''1'',''3'') ';
        wk_sql1 := wk_sql1 || '       AND     oha.req_status                 = ''04'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.actual_confirm_class       = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.latest_external_flag       = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     ola.delete_flag                = ''N'') ';
        wk_sql1 := wk_sql1 || '      - ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(CASE ';
        wk_sql1 := wk_sql1 || '               WHEN (otta.order_category_code = ''ORDER'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 ola.shipped_quantity ';
        wk_sql1 := wk_sql1 || '                 NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0) ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql1 := wk_sql1 || '               WHEN (otta.order_category_code = ''RETURN'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 ola.shipped_quantity * -1 ';
        wk_sql1 := wk_sql1 || '                 (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1 ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql1 := wk_sql1 || '               END), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql1 := wk_sql1 || '             , xxwsh_order_lines_all      ola ';
-- 2008/12/19 D.Nihei ADD START
        wk_sql1 := wk_sql1 || '             , xxinv_mov_lot_details      mld  ';
-- 2008/12/19 D.Nihei ADD END
        wk_sql1 := wk_sql1 || '             , oe_transaction_types_all   otta ';
        wk_sql1 := wk_sql1 || '       WHERE   ola.shipping_inventory_item_id = ' || lt_inv_item_id ;
-- 2008/12/19 D.Nihei ADD START
        wk_sql1 := wk_sql1 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code    = ''30'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code      = ''20'' ';
-- 2008/12/19 D.Nihei ADD END
        wk_sql1 := wk_sql1 || '       AND     oha.deliver_from_id       = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql1 := wk_sql1 || '       AND     otta.transaction_type_id  = oha.order_type_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.req_status            = ''08'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     otta.attribute1           = ''2'') ';
-- 2009/01/05 D.Nihei ADD START
        wk_sql1 := wk_sql1 || '      + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_lot_details       mld  ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.ship_to_locat_id   = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg    = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.correct_actual_flg = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status             = ''06'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code    = ''30'') ';
        wk_sql1 := wk_sql1 || '      + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_lot_details       mld  ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.shipped_locat_id   = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg    = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.correct_actual_flg = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status             = ''06'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code    = ''20'') ';
-- 2009/01/05 D.Nihei ADD END
        wk_sql1 := wk_sql1 || '     )                                      stock_qty                '; -- �݌ɑ���
-- ���ɗ\��SQL
        wk_sql1 := wk_sql1 || '    ,( ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(pla.quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    po_lines_all       pla ';
        wk_sql1 := wk_sql1 || '             , po_headers_all     pha ';
        wk_sql1 := wk_sql1 || '       WHERE   pla.item_id       = ' || lt_inv_item_id ;
        wk_sql1 := wk_sql1 || '       AND     pla.po_header_id  = pha.po_header_id ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute5    = enable_lot.storehouse_code ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute1    IN (''20'',''25'') ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute4   <= TO_CHAR(TO_DATE(''' || id_material_date || '''), ''YYYY/MM/DD'') ';
        wk_sql1 := wk_sql1 || '       AND     pla.attribute13   = ''N'') ';
        wk_sql1 := wk_sql1 || '      + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(CASE ';
        wk_sql1 := wk_sql1 || '               WHEN (mrih.status IN (''02'',''03'')) THEN ';
        wk_sql1 := wk_sql1 || '                 mril.instruct_qty ';
        wk_sql1 := wk_sql1 || '               WHEN (mrih.status = ''04'') THEN ';
        wk_sql1 := wk_sql1 || '                 mril.shipped_quantity ';
        wk_sql1 := wk_sql1 || '               END), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.ship_to_locat_id       = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.item_id                = enable_lot.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status                 IN (''02'',''03'',''04'') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.schedule_arrival_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg        = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg             = ''N'') ';
        wk_sql1 := wk_sql1 || '     )                                      inbound_qty              '; -- ���ɗ\�萔
-- �o�ɗ\��SQL
        wk_sql1 := wk_sql1 || '    ,( ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(CASE ';
        wk_sql1 := wk_sql1 || '               WHEN (mrih.status IN (''02'',''03'')) THEN ';
        wk_sql1 := wk_sql1 || '                 mril.reserved_quantity ';
        wk_sql1 := wk_sql1 || '               WHEN (mrih.status = ''05'') THEN ';
        wk_sql1 := wk_sql1 || '                 mril.ship_to_quantity ';
        wk_sql1 := wk_sql1 || '               END), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.shipped_locat_id       = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.item_id                = enable_lot.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status                 IN (''02'',''03'',''05'') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.schedule_arrival_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg        = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg             = ''N'') ';
        wk_sql1 := wk_sql1 || '      + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(ola.reserved_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql1 := wk_sql1 || '             , xxwsh_order_lines_all      ola ';
        wk_sql1 := wk_sql1 || '             , oe_transaction_types_all  otta ';
        wk_sql1 := wk_sql1 || '       WHERE   ola.shipping_inventory_item_id = ' || lt_inv_item_id ;
        wk_sql1 := wk_sql1 || '       AND     oha.deliver_from_id            = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.order_header_id            = ola.order_header_id ';
        wk_sql1 := wk_sql1 || '       AND     otta.transaction_type_id       = oha.order_type_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.schedule_ship_date        <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     oha.req_status                 = ''03'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.actual_confirm_class       = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.latest_external_flag       = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     ola.delete_flag                = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     otta.attribute1                = ''1'') ';
        wk_sql1 := wk_sql1 || '      + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(ola.reserved_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql1 := wk_sql1 || '             , xxwsh_order_lines_all      ola ';
        wk_sql1 := wk_sql1 || '             , oe_transaction_types_all   otta ';
        wk_sql1 := wk_sql1 || '       WHERE   ola.shipping_inventory_item_id = ' || lt_inv_item_id ;
        wk_sql1 := wk_sql1 || '       AND     oha.deliver_from_id            = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.order_header_id            = ola.order_header_id ';
        wk_sql1 := wk_sql1 || '       AND     otta.transaction_type_id       = oha.order_type_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.schedule_ship_date        <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     oha.req_status                 = ''07'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.actual_confirm_class       = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.latest_external_flag       = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     ola.delete_flag                = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     otta.attribute1                = ''2'') ';
        wk_sql1 := wk_sql1 || '      + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(xmd.instructions_qty), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    gme_batch_header      gbh ';
        wk_sql1 := wk_sql1 || '             , gme_material_details  gmd ';
        wk_sql1 := wk_sql1 || '             , xxwip_material_detail xmd ';
        wk_sql1 := wk_sql1 || '             , gmd_routings_b        grb ';
        wk_sql1 := wk_sql1 || '       WHERE   gbh.batch_id           = gmd.batch_id ';
        wk_sql1 := wk_sql1 || '       AND     gmd.item_id            = enable_lot.item_id ';
        wk_sql1 := wk_sql1 || '       AND     gmd.material_detail_id = xmd.material_detail_id ';
        wk_sql1 := wk_sql1 || '       AND     gbh.routing_id         = grb.routing_id ';
        wk_sql1 := wk_sql1 || '       AND     grb.attribute9         = enable_lot.storehouse_code ';
        wk_sql1 := wk_sql1 || '       AND     gbh.batch_status       IN (1,2) ';
        wk_sql1 := wk_sql1 || '       AND     gbh.plan_start_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     gmd.line_type          = -1 ';
        wk_sql1 := wk_sql1 || '       AND     xmd.plan_type          = ''4'' ';
        wk_sql1 := wk_sql1 || '       AND     xmd.invested_qty       = 0) ';
        wk_sql1 := wk_sql1 || '     )                                      outbound_qty             '; -- �o�ɗ\�萔
      --==========================
      -- ���ވȊO
      --==========================
      ELSE
        wk_sql1 := wk_sql1 || '    ,( ';
        wk_sql1 := wk_sql1 || '      (SELECT NVL(SUM(ili.loct_onhand), 0) ';
        wk_sql1 := wk_sql1 || '       FROM   ic_whse_mst         iwm ';
        wk_sql1 := wk_sql1 || '             ,mtl_item_locations  mil ';
        wk_sql1 := wk_sql1 || '             ,ic_loct_inv         ili ';
        wk_sql1 := wk_sql1 || '       WHERE mil.segment1              = ili.location ';
        wk_sql1 := wk_sql1 || '       AND   mil.organization_id       = iwm.mtl_organization_id ';
        wk_sql1 := wk_sql1 || '       AND   mil.inventory_location_id = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND   ili.item_id               = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND   ili.lot_id                = ilm.lot_id) ';
        wk_sql1 := wk_sql1 || '       + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.ship_to_locat_id   = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg    = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status             IN (''05'', ''06'') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code    = ''30'') ';
        wk_sql1 := wk_sql1 || '       - ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.shipped_locat_id   = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg    = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status             IN (''04'', ''06'') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code    = ''20'') ';
        wk_sql1 := wk_sql1 || '       - ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(CASE ';
        wk_sql1 := wk_sql1 || '               WHEN (otta.order_category_code = ''ORDER'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 mld.actual_quantity ';
        wk_sql1 := wk_sql1 || '                 NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0) ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql1 := wk_sql1 || '               WHEN (otta.order_category_code = ''RETURN'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 mld.actual_quantity * -1 ';
        wk_sql1 := wk_sql1 || '                 (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1 ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql1 := wk_sql1 || '               END), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql1 := wk_sql1 || '              ,xxwsh_order_lines_all      ola ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details      mld ';
        wk_sql1 := wk_sql1 || '              ,oe_transaction_types_all   otta ';
        wk_sql1 := wk_sql1 || '       WHERE   oha.deliver_from_id       = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.req_status            = ''04'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql1 := wk_sql1 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id               = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id                = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code    = ''10'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code      = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     otta.attribute1           IN (''1'', ''3'') ';
        wk_sql1 := wk_sql1 || '       AND     otta.transaction_type_id  = oha.order_type_id) ';
        wk_sql1 := wk_sql1 || '       - ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(CASE ';
        wk_sql1 := wk_sql1 || '               WHEN (otta.order_category_code = ''ORDER'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 mld.actual_quantity ';
        wk_sql1 := wk_sql1 || '                 NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0) ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql1 := wk_sql1 || '               WHEN (otta.order_category_code = ''RETURN'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 mld.actual_quantity * -1 ';
        wk_sql1 := wk_sql1 || '                 (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1 ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql1 := wk_sql1 || '               END), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql1 := wk_sql1 || '              ,xxwsh_order_lines_all      ola ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details      mld ';
        wk_sql1 := wk_sql1 || '              ,oe_transaction_types_all   otta ';
        wk_sql1 := wk_sql1 || '       WHERE   oha.deliver_from_id       = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.req_status            = ''08'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql1 := wk_sql1 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id               = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id                = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code    = ''30'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code      = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     otta.attribute1           = ''2'' ';
        wk_sql1 := wk_sql1 || '       AND     otta.transaction_type_id  = oha.order_type_id) ';
-- 2009/01/05 D.Nihei ADD START
        wk_sql1 := wk_sql1 || '      + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_lot_details       mld  ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.ship_to_locat_id   = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg    = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.correct_actual_flg = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status             = ''06'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code    = ''30'') ';
        wk_sql1 := wk_sql1 || '      + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '             , xxinv_mov_lot_details       mld  ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.shipped_locat_id   = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg    = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.correct_actual_flg = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status             = ''06'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code    = ''20'') ';
-- 2009/01/05 D.Nihei ADD END
        wk_sql1 := wk_sql1 || '     )                                      stock_qty                '; -- �݌ɑ���
-- ���ɗ\��SQL
        wk_sql1 := wk_sql1 || '    ,( ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(pla.quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    po_lines_all       pla ';
        wk_sql1 := wk_sql1 || '              ,po_headers_all     pha ';
        wk_sql1 := wk_sql1 || '       WHERE   pla.item_id      = ' || lt_inv_item_id ;
        wk_sql1 := wk_sql1 || '       AND     pla.attribute1   = ilm.lot_no ';
        wk_sql1 := wk_sql1 || '       AND     pla.attribute13  = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     pla.cancel_flag  = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     pla.po_header_id = pha.po_header_id ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute1   IN (''20'', ''25'') ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute5   = enable_lot.storehouse_code ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute4  <= TO_CHAR(TO_DATE(''' || id_material_date || '''), ''YYYY/MM/DD'')) ';
        wk_sql1 := wk_sql1 || '       + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.ship_to_locat_id       = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg        = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status                 IN (''02'', ''03'') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.schedule_arrival_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.mov_line_id            = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg             = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id                 = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id                  = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code      = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code        = ''10'') ';
        wk_sql1 := wk_sql1 || '       + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.ship_to_locat_id       = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg        = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status                 = ''04'' ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '       AND     mrih.schedule_arrival_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= TO_DATE(''' || id_material_date || ''') ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.mov_line_id            = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg             = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id                 = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id                  = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code      = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code        = ''20'') ';
        wk_sql1 := wk_sql1 || '       + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    gme_batch_header      gbh ';
        wk_sql1 := wk_sql1 || '              ,gme_material_details  gmd ';
        wk_sql1 := wk_sql1 || '              ,ic_tran_pnd           itp ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details mld ';
        wk_sql1 := wk_sql1 || '              ,gmd_routings_b        grb ';
        wk_sql1 := wk_sql1 || '       WHERE   gbh.batch_status       IN (1, 2) ';
        wk_sql1 := wk_sql1 || '       AND     gbh.plan_start_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     gbh.batch_id           = gmd.batch_id ';
        wk_sql1 := wk_sql1 || '       AND     gmd.line_type          IN (1,2) ';
        wk_sql1 := wk_sql1 || '       AND     gmd.item_id            = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     gmd.material_detail_id = itp.line_id ';
        wk_sql1 := wk_sql1 || '       AND     itp.completed_ind      = 0 ';
        wk_sql1 := wk_sql1 || '       AND     itp.doc_type           = ''PROD'' ';
        wk_sql1 := wk_sql1 || '       AND     itp.lot_id             = ilm.lot_id ';
-- 2008/12/24 D.Nihei ADD START �{�ԏ�Q#836
        wk_sql1 := wk_sql1 || '       AND     itp.delete_mark        = 0 ';
-- 2008/12/24 D.Nihei ADD END
        wk_sql1 := wk_sql1 || '       AND     gmd.material_detail_id = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code = ''40'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code   = ''10'' ';
        wk_sql1 := wk_sql1 || '       AND     gbh.routing_id         = grb.routing_id ';
        wk_sql1 := wk_sql1 || '       AND     grb.attribute9         = enable_lot.storehouse_code) ';
        wk_sql1 := wk_sql1 || '      )                                     inbound_qty              '; -- ���ɗ\�萔
        wk_sql1 := wk_sql1 || '    ,( ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.shipped_locat_id    = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg     = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status              IN (''02'', ''03'') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.schedule_ship_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id          = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.mov_line_id         = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg          = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id              = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id               = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code   = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code     = ''10'') ';
        wk_sql1 := wk_sql1 || '       + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql1 := wk_sql1 || '       WHERE   mrih.shipped_locat_id   = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg    = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.status             = ''05'' ';
        wk_sql1 := wk_sql1 || '       AND     mrih.schedule_ship_date  <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code    = ''30'') ';
        wk_sql1 := wk_sql1 || '       + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql1 := wk_sql1 || '              ,xxwsh_order_lines_all      ola ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details      mld ';
        wk_sql1 := wk_sql1 || '              ,oe_transaction_types_all   otta ';
        wk_sql1 := wk_sql1 || '       WHERE   oha.deliver_from_id       = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.req_status            = ''03'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.schedule_ship_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql1 := wk_sql1 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id               = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id                = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code    = ''10'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code      = ''10'' ';
        wk_sql1 := wk_sql1 || '       AND     otta.attribute1           = ''1'' ';
        wk_sql1 := wk_sql1 || '       AND     otta.transaction_type_id  = oha.order_type_id) ';
        wk_sql1 := wk_sql1 || '       + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql1 := wk_sql1 || '              ,xxwsh_order_lines_all      ola ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details      mld ';
        wk_sql1 := wk_sql1 || '              ,oe_transaction_types_all  otta ';
        wk_sql1 := wk_sql1 || '       WHERE   oha.deliver_from_id       = enable_lot.inventory_location_id ';
        wk_sql1 := wk_sql1 || '       AND     oha.req_status            = ''07'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql1 := wk_sql1 || '       AND     oha.schedule_ship_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql1 := wk_sql1 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.item_id               = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id                = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code    = ''30'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code      = ''10'' ';
        wk_sql1 := wk_sql1 || '       AND     otta.attribute1           = ''2'' ';
        wk_sql1 := wk_sql1 || '       AND     otta.transaction_type_id  = oha.order_type_id) ';
        wk_sql1 := wk_sql1 || '       + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    gme_batch_header      gbh ';
        wk_sql1 := wk_sql1 || '              ,gme_material_details  gmd ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details mld ';
        wk_sql1 := wk_sql1 || '              ,gmd_routings_b        grb ';
        wk_sql1 := wk_sql1 || '              ,ic_tran_pnd           itp ';
        wk_sql1 := wk_sql1 || '       WHERE   gbh.batch_status      IN (1, 2) ';
        wk_sql1 := wk_sql1 || '       AND     gbh.plan_start_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     gbh.batch_id           = gmd.batch_id ';
        wk_sql1 := wk_sql1 || '       AND     gmd.line_type          = -1 ';
        wk_sql1 := wk_sql1 || '       AND     gmd.item_id            = ilm.item_id ';
        wk_sql1 := wk_sql1 || '       AND     gmd.material_detail_id = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id             = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     gbh.routing_id         = grb.routing_id ';
        wk_sql1 := wk_sql1 || '       AND     grb.attribute9         = enable_lot.storehouse_code ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code = ''40'' ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code   = ''10'' ';
-- 2008/11/19 v1.4 D.Nihei ADD START ������Q#681
        wk_sql1 := wk_sql1 || '       AND     itp.doc_type           = ''PROD'' ';
-- 2008/11/19 v1.4 D.Nihei ADD END
-- 2008/12/02 v1.5 D.Nihei ADD START ������Q#251
        wk_sql1 := wk_sql1 || '       AND     itp.delete_mark        = 0 ';
-- 2008/12/02 v1.5 D.Nihei ADD END
        wk_sql1 := wk_sql1 || '       AND     itp.line_id            = gmd.material_detail_id  ';
        wk_sql1 := wk_sql1 || '       AND     itp.item_id            = gmd.item_id ';
        wk_sql1 := wk_sql1 || '       AND     itp.lot_id             = mld.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     itp.completed_ind      = 0) ';
        wk_sql1 := wk_sql1 || '       + ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    po_lines_all          pla ';
        wk_sql1 := wk_sql1 || '              ,po_headers_all        pha ';
        wk_sql1 := wk_sql1 || '              ,xxinv_mov_lot_details mld ';
        wk_sql1 := wk_sql1 || '       WHERE   pla.item_id            = ' || lt_inv_item_id ;
        wk_sql1 := wk_sql1 || '       AND     pla.attribute13        = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     pla.cancel_flag        = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     pla.attribute12        = enable_lot.storehouse_code ';
        wk_sql1 := wk_sql1 || '       AND     pla.po_header_id       = pha.po_header_id ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute1         IN (''20'', ''25'') ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute4        <= TO_CHAR(TO_DATE(''' || id_material_date || '''), ''YYYY/MM/DD'') ';
        wk_sql1 := wk_sql1 || '       AND     pla.po_line_id         = mld.mov_line_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.lot_id             = ilm.lot_id ';
        wk_sql1 := wk_sql1 || '       AND     mld.document_type_code = ''50''  ';
        wk_sql1 := wk_sql1 || '       AND     mld.record_type_code   = ''10'') ';
        wk_sql1 := wk_sql1 || '      )                                     outbound_qty             '; -- �o�ɗ\�萔
      END IF;
      wk_sql1 := wk_sql1 || '      , 0                                     enabled_qty              '; -- �\��
      wk_sql1 := wk_sql1 || '      , TO_NUMBER( DECODE( ilm.attribute6, ''0'', NULL, ilm.attribute6 ))';
      wk_sql1 := wk_sql1 || '                                              entity_inner             '; -- �݌ɓ���
      wk_sql2 := wk_sql2 || '      , TO_NUMBER( ilm.attribute7 )           unit_price               '; -- �P��
      wk_sql2 := wk_sql2 || '      , ilm.attribute8                        orgn_code                '; -- �����R�[�h
      wk_sql2 := wk_sql2 || '      , (SELECT xvv.vendor_short_name ';
      wk_sql2 := wk_sql2 || '         FROM   xxcmn_vendors2_v xvv  ';  -- �d������VIEW
      wk_sql2 := wk_sql2 || '         WHERE  xvv.segment1           = ilm.attribute8 ';
      wk_sql2 := wk_sql2 || '         AND    xvv.start_date_active <= trunc( TO_DATE(''' || id_material_date || ''')) ';
      wk_sql2 := wk_sql2 || '         AND    xvv.end_date_active   >= trunc( TO_DATE(''' || id_material_date || ''')) ';
      wk_sql2 := wk_sql2 || '        )                                     orgn_name                '; -- ����於��
      wk_sql2 := wk_sql2 || '      , (SELECT xlvv_l05.meaning ';
      wk_sql2 := wk_sql2 || '         FROM   xxcmn_lookup_values_v xlvv_l05 ';
      wk_sql2 := wk_sql2 || '         WHERE  xlvv_l05.lookup_code = ilm.attribute9  ';
      wk_sql2 := wk_sql2 || '         AND    xlvv_l05.lookup_type = ''XXCMN_L05''   ';
      wk_sql2 := wk_sql2 || '        )                                     stocking_form            '; -- �d���`��
      wk_sql2 := wk_sql2 || '      , (SELECT xlvv_l06.meaning ';
      wk_sql2 := wk_sql2 || '         FROM   xxcmn_lookup_values_v xlvv_l06 ';
      wk_sql2 := wk_sql2 || '         WHERE  xlvv_l06.lookup_code = ilm.attribute10 ';
      wk_sql2 := wk_sql2 || '         AND    xlvv_l06.lookup_type = ''XXCMN_L06''   ';
      wk_sql2 := wk_sql2 || '        )                                     tea_season_type          '; -- �����敪
      wk_sql2 := wk_sql2 || '      , ilm.attribute11                       period_of_year           '; -- �N�x
      wk_sql2 := wk_sql2 || '      , (SELECT xlvv_l07.meaning ';
      wk_sql2 := wk_sql2 || '         FROM   xxcmn_lookup_values_v xlvv_l07 ';
      wk_sql2 := wk_sql2 || '         WHERE  xlvv_l07.lookup_code = ilm.attribute12 ';
      wk_sql2 := wk_sql2 || '         AND    xlvv_l07.lookup_type = ''XXCMN_L07''   ';
      wk_sql2 := wk_sql2 || '        )                                     producing_area           '; -- �Y�n
      wk_sql2 := wk_sql2 || '      , (SELECT xlvv_l08.meaning ';
      wk_sql2 := wk_sql2 || '         FROM   xxcmn_lookup_values_v xlvv_l08  ';
      wk_sql2 := wk_sql2 || '         WHERE  xlvv_l08.lookup_code = ilm.attribute13 ';
      wk_sql2 := wk_sql2 || '         AND    xlvv_l08.lookup_type = ''XXCMN_L08''   ';
      wk_sql2 := wk_sql2 || '        )                                     package_type             '; -- �^�C�v
      wk_sql2 := wk_sql2 || '      , ilm.attribute14                       rank1                    '; -- R1
      wk_sql2 := wk_sql2 || '      , ilm.attribute15                       rank2                    '; -- R2
      wk_sql2 := wk_sql2 || '      , ilm.attribute19                       rank3                    '; -- R3
      wk_sql2 := wk_sql2 || '      , ilm.attribute1                        maker_date               '; -- ������
      wk_sql2 := wk_sql2 || '      , ilm.attribute3                        use_by_date              '; -- �ܖ�������
      wk_sql2 := wk_sql2 || '      , ilm.attribute2                        unique_sign              '; -- �ŗL�L��
      wk_sql2 := wk_sql2 || '      , ilm.attribute4                        dely_date                '; -- �[�����i����j
      wk_sql2 := wk_sql2 || '      , (SELECT xlvv_l03.meaning ';
      wk_sql2 := wk_sql2 || '         FROM   xxcmn_lookup_values_v xlvv_l03  ';
      wk_sql2 := wk_sql2 || '         WHERE  xlvv_l03.lookup_code = ilm.attribute16 ';
      wk_sql2 := wk_sql2 || '         AND    xlvv_l03.lookup_type = ''XXCMN_L03''   ';
      wk_sql2 := wk_sql2 || '        )                                     slip_type_name           '; -- �`�[�敪(����)
      wk_sql2 := wk_sql2 || '      , ilm.attribute17                       routing_no               '; -- ���C��No
      wk_sql2 := wk_sql2 || '      , (SELECT grv.attribute1     ';
      wk_sql2 := wk_sql2 || '         FROM   gmd_routings_b grv '; -- �H���}�X�^VIEW
      wk_sql2 := wk_sql2 || '         WHERE  grv.routing_no = ilm.attribute17 ';
      wk_sql2 := wk_sql2 || '        )                                     routing_name             '; -- ���C������
      wk_sql2 := wk_sql2 || '      , ilm.attribute18                       remarks_column           '; -- �E�v
      wk_sql2 := wk_sql2 || '      , enable_lot.record_type                record_type              ';
      wk_sql2 := wk_sql2 || '      , ilm.created_by                        created_by               ';
      wk_sql2 := wk_sql2 || '      , ilm.creation_date                     creation_date            ';
      wk_sql2 := wk_sql2 || '      , ilm.last_updated_by                   last_updated_by          ';
      wk_sql2 := wk_sql2 || '      , ilm.last_update_date                  last_update_date         ';
      wk_sql2 := wk_sql2 || '      , ilm.last_update_login                 last_update_login        ';
      wk_sql2 := wk_sql2 || '      , enable_lot.xmd_last_update_date       xmd_last_update_date     ';
      wk_sql2 := wk_sql2 || '      , NVL(enable_lot.whse_inside_outside_div, ''2'')  ';
      wk_sql2 := wk_sql2 || '                                              whse_inside_outside_div  '; -- ���O�q�ɋ敪
      wk_sql2 := wk_sql2 || '      FROM ';
      wk_sql2 := wk_sql2 || '        ic_lots_mst ilm '; -- OPM���b�g
      wk_sql2 := wk_sql2 || '      , ( SELECT 1                               record_type             ';       -- �X�V
      wk_sql2 := wk_sql2 || '               , xmd.mtl_detail_addon_id         mtl_detail_addon_id     ';       -- ���Y�����ڍ׃A�h�I��ID
      wk_sql2 := wk_sql2 || '               , xmd.item_id                     item_id                 ';       -- �i��ID
      wk_sql2 := wk_sql2 || '               , xmd.lot_id                      lot_id                  ';       -- ���b�gID
      wk_sql2 := wk_sql2 || '               , xmd.location_code               storehouse_code         ';       -- �ۊǏꏊ�R�[�h
      wk_sql2 := wk_sql2 || '               , xmd.instructions_qty            instructions_qty        ';       -- �w������
      wk_sql2 := wk_sql2 || '               , xmd.last_update_date            xmd_last_update_date     '; -- �ŏI�X�V��(�r������p)
      wk_sql2 := wk_sql2 || '               , xmld.mov_lot_dtl_id             mov_lot_dtl_id           '; -- �ړ����b�g�ڍ�ID
      wk_sql2 := wk_sql2 || '               , xilv.inventory_location_id      inventory_location_id    '; -- �ۊǑq��ID
      wk_sql2 := wk_sql2 || '               , xilv.description                description              '; -- �ۊǑq��(����)
      wk_sql2 := wk_sql2 || '               , xilv.whse_inside_outside_div    whse_inside_outside_div  '; -- ���O�q�ɋ敪
      wk_sql2 := wk_sql2 || '          FROM   xxwip_material_detail           xmd  '; -- ���Y�����ڍ׃A�h�I��
      wk_sql2 := wk_sql2 || '               , xxinv_mov_lot_details           xmld '; -- �ړ����b�g�ڍ�
      wk_sql2 := wk_sql2 || '               , xxcmn_item_locations_v          xilv '; -- �ۊǑq��
      wk_sql2 := wk_sql2 || '          WHERE  xmd.material_detail_id  = ' || in_material_detail_id;
      wk_sql2 := wk_sql2 || '          AND    xmd.plan_type           IN ( ''1'', ''2'', ''3'' )     ';
      wk_sql2 := wk_sql2 || '          AND    xilv.segment1           = xmd.location_code ';
      wk_sql2 := wk_sql2 || '          AND    xmld.mov_line_id(+)     = xmd.mtl_detail_addon_id ';
      wk_sql2 := wk_sql2 || '          AND    xmld.lot_id(+)          = xmd.lot_id ';
      wk_sql2 := wk_sql2 || '          UNION ALL ';
      wk_sql2 := wk_sql2 || '          SELECT 0                               record_type               '; -- �}��
      wk_sql2 := wk_sql2 || '               , NULL                            mtl_detail_addon_id       '; -- ���Y�����ڍ׃A�h�I��ID
      wk_sql2 := wk_sql2 || '               , lot.item_id                     item_id                   '; -- �i��ID
      wk_sql2 := wk_sql2 || '               , lot.lot_id                      lot_id                    '; -- ���b�gID
      wk_sql2 := wk_sql2 || '               , xilv.segment1                   storehouse_code           '; -- �ۊǏꏊ�R�[�h
      wk_sql2 := wk_sql2 || '               , NULL                            instructions_qty          '; -- �w������
      wk_sql2 := wk_sql2 || '               , NULL                            xmd_last_update_date      '; -- �ŏI�X�V��(�r������p)
      wk_sql2 := wk_sql2 || '               , NULL                            mov_lot_dtl_id            '; -- �ړ����b�g�ڍ�ID
      wk_sql2 := wk_sql2 || '               , xilv.inventory_location_id      inventory_location_id     '; -- �ۊǑq��ID
      wk_sql2 := wk_sql2 || '               , xilv.description                description               '; -- �ۊǑq��(����)
      wk_sql2 := wk_sql2 || '               , xilv.whse_inside_outside_div    whse_inside_outside_div   '; -- ���O�q�ɋ敪
      wk_sql2 := wk_sql2 || '          FROM   xxcmn_item_locations_v xilv ';   -- �ۊǑq��
      wk_sql2 := wk_sql2 || '               , ( ';
      --==========================
      -- ����
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
        wk_sql2 := wk_sql2 || '                 SELECT mil.inventory_location_id location_id ';
        wk_sql2 := wk_sql2 || '                      , ili.item_id               item_id ';
        wk_sql2 := wk_sql2 || '                      , ili.lot_id                lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   mtl_item_locations  mil ';
        wk_sql2 := wk_sql2 || '                      , ic_whse_mst         iwm ';
        wk_sql2 := wk_sql2 || '                      , ic_loct_inv         ili ';
        wk_sql2 := wk_sql2 || '                 WHERE  ili.item_id               = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND    mil.segment1              = ili.location ';
        wk_sql2 := wk_sql2 || '                 AND    mil.organization_id       = iwm.mtl_organization_id ';
        wk_sql2 := wk_sql2 || '                 AND    ili.loct_onhand           > 0 ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT mrih.ship_to_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                      , mril.item_id                item_id ';
        wk_sql2 := wk_sql2 || '                      , 0                           lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '                      , xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '                 WHERE  mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND    mril.item_id            = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND    mrih.status             IN (''05'',''06'') ';
        wk_sql2 := wk_sql2 || '                 AND    mrih.comp_actual_flg    = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    mril.delete_flg         = ''N'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT mrih.shipped_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                      , mril.item_id                item_id ';
        wk_sql2 := wk_sql2 || '                      , 0                           lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '                      , xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '                 WHERE  mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND    mril.item_id            = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND    mrih.status             IN (''04'',''06'') ';
        wk_sql2 := wk_sql2 || '                 AND    mrih.comp_actual_flg    = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    mril.delete_flg         = ''N'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT /*+ index(MLD XXINV_MLD_N99) */ oha.deliver_from_id  location_id ';
        wk_sql2 := wk_sql2 || '                      , ' || lt_item_id || ' item_id ';
        wk_sql2 := wk_sql2 || '                      , 0                    lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   xxwsh_order_headers_all    oha ';
        wk_sql2 := wk_sql2 || '                      , xxwsh_order_lines_all      ola ';
        wk_sql2 := wk_sql2 || '                      , oe_transaction_types_all   otta ';
        wk_sql2 := wk_sql2 || '                 WHERE  oha.order_header_id            = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '                 AND    otta.transaction_type_id       = oha.order_type_id ';
        wk_sql2 := wk_sql2 || '                 AND    ola.shipping_inventory_item_id = ' || lt_inv_item_id;
        wk_sql2 := wk_sql2 || '                 AND    otta.attribute1                IN (''1'',''3'') ';
        wk_sql2 := wk_sql2 || '                 AND    oha.req_status                 = ''04'' ';
        wk_sql2 := wk_sql2 || '                 AND    oha.actual_confirm_class       = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    oha.latest_external_flag       = ''Y'' ';
        wk_sql2 := wk_sql2 || '                 AND    ola.delete_flag                = ''N'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT /* index(MLD XXINV_MLD_N99) */ oha.deliver_from_id  location_id ';
        wk_sql2 := wk_sql2 || '                      , ' || lt_item_id || ' item_id ';
        wk_sql2 := wk_sql2 || '                      , 0                    lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   xxwsh_order_headers_all    oha ';
        wk_sql2 := wk_sql2 || '                      , xxwsh_order_lines_all      ola ';
        wk_sql2 := wk_sql2 || '                      , oe_transaction_types_all   otta ';
        wk_sql2 := wk_sql2 || '                 WHERE  oha.order_header_id            = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '                 AND    otta.transaction_type_id       = oha.order_type_id ';
        wk_sql2 := wk_sql2 || '                 AND    ola.shipping_inventory_item_id = ' || lt_inv_item_id;
        wk_sql2 := wk_sql2 || '                 AND    oha.req_status                 = ''08'' ';
        wk_sql2 := wk_sql2 || '                 AND    oha.actual_confirm_class       = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    oha.latest_external_flag       = ''Y'' ';
        wk_sql2 := wk_sql2 || '                 AND    ola.delete_flag                = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    otta.attribute1                = ''2'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT mil.inventory_location_id   location_id ';
        wk_sql2 := wk_sql2 || '                      , ' || lt_item_id || '        item_id ';
        wk_sql2 := wk_sql2 || '                      , 0                           lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   po_lines_all       pla ';
        wk_sql2 := wk_sql2 || '                      , po_headers_all     pha ';
        wk_sql2 := wk_sql2 || '                      , mtl_item_locations mil ';
        wk_sql2 := wk_sql2 || '                 WHERE  pla.po_header_id = pha.po_header_id ';
        wk_sql2 := wk_sql2 || '                 AND    pha.attribute5   = mil.segment1 ';
        wk_sql2 := wk_sql2 || '                 AND    pla.item_id      = ' || lt_inv_item_id;
        wk_sql2 := wk_sql2 || '                 AND    pla.attribute13  = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    pha.attribute1   IN (''20'',''25'') ';
        wk_sql2 := wk_sql2 || '                 AND    pha.attribute4  <= TO_CHAR(TO_DATE(''' || id_material_date || '''), ''YYYY/MM/DD'')  ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT mrih.ship_to_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                      , mril.item_id                item_id ';
        wk_sql2 := wk_sql2 || '                      , 0                           lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '                      , xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '                 WHERE  mrih.comp_actual_flg        = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    mrih.status                 IN (''02'',''03'',''04'') ';
        wk_sql2 := wk_sql2 || '                 AND    mrih.schedule_arrival_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND    mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND    mril.delete_flg             = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    mril.item_id                = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT mrih.shipped_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                      , mril.item_id                item_id ';
        wk_sql2 := wk_sql2 || '                      , 0                           lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '                      , xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '                 WHERE  mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND    mril.item_id                = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND    mrih.schedule_arrival_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND    mrih.comp_actual_flg        = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    mril.delete_flg             = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    mrih.status                 IN (''02'',''03'',''05'') ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT oha.deliver_from_id  location_id ';
        wk_sql2 := wk_sql2 || '                      , ' || lt_item_id || ' item_id ';
        wk_sql2 := wk_sql2 || '                      , 0                    lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   xxwsh_order_headers_all    oha ';
        wk_sql2 := wk_sql2 || '                      , xxwsh_order_lines_all      ola ';
        wk_sql2 := wk_sql2 || '                      , oe_transaction_types_all  otta ';
        wk_sql2 := wk_sql2 || '                 WHERE  ola.shipping_inventory_item_id = ' || lt_inv_item_id;
        wk_sql2 := wk_sql2 || '                 AND    otta.transaction_type_id       = oha.order_type_id ';
        wk_sql2 := wk_sql2 || '                 AND    oha.order_header_id            = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '                 AND    oha.schedule_ship_date        <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND    oha.req_status                 = ''03'' ';
        wk_sql2 := wk_sql2 || '                 AND    oha.actual_confirm_class       = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    oha.latest_external_flag       = ''Y'' ';
        wk_sql2 := wk_sql2 || '                 AND    ola.delete_flag                = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    otta.attribute1                = ''1'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT oha.deliver_from_id  location_id ';
        wk_sql2 := wk_sql2 || '                      , ' || lt_item_id || ' item_id ';
        wk_sql2 := wk_sql2 || '                      , 0                    lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   xxwsh_order_headers_all    oha ';
        wk_sql2 := wk_sql2 || '                      , xxwsh_order_lines_all      ola ';
        wk_sql2 := wk_sql2 || '                      , oe_transaction_types_all   otta ';
        wk_sql2 := wk_sql2 || '                 WHERE  ola.shipping_inventory_item_id = ' || lt_inv_item_id;
        wk_sql2 := wk_sql2 || '                 AND    otta.transaction_type_id       = oha.order_type_id ';
        wk_sql2 := wk_sql2 || '                 AND    oha.order_header_id            = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '                 AND    oha.schedule_ship_date        <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND    oha.req_status                 = ''07'' ';
        wk_sql2 := wk_sql2 || '                 AND    oha.actual_confirm_class       = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    oha.latest_external_flag       = ''Y'' ';
        wk_sql2 := wk_sql2 || '                 AND    ola.delete_flag                = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND    otta.attribute1                = ''2'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT mil.inventory_location_id   location_id ';
        wk_sql2 := wk_sql2 || '                      , gmd.item_id                 item_id ';
        wk_sql2 := wk_sql2 || '                      , 0                           lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM   gme_batch_header      gbh ';
        wk_sql2 := wk_sql2 || '                      , gme_material_details  gmd ';
        wk_sql2 := wk_sql2 || '                      , xxwip_material_detail xmd ';
        wk_sql2 := wk_sql2 || '                      , gmd_routings_b        grb ';
        wk_sql2 := wk_sql2 || '                      , mtl_item_locations    mil ';
        wk_sql2 := wk_sql2 || '                 WHERE  gbh.batch_status       IN (1, 2) ';
        wk_sql2 := wk_sql2 || '                 AND    gbh.plan_start_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND    gbh.batch_id           = gmd.batch_id ';
        wk_sql2 := wk_sql2 || '                 AND    gmd.line_type          = -1 ';
        wk_sql2 := wk_sql2 || '                 AND    gmd.item_id            = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND    gmd.material_detail_id = xmd.material_detail_id ';
        wk_sql2 := wk_sql2 || '                 AND    xmd.plan_type          = ''4'' ';
        wk_sql2 := wk_sql2 || '                 AND    gbh.routing_id         = grb.routing_id ';
        wk_sql2 := wk_sql2 || '                 AND    grb.attribute9         = mil.segment1 ';
        wk_sql2 := wk_sql2 || '                 AND    xmd.invested_qty       = 0 ';
      --==========================
      -- ���ވȊO
      --==========================
      ELSE
        wk_sql2 := wk_sql2 || '                 SELECT mil.inventory_location_id location_id ';
        wk_sql2 := wk_sql2 || '                      , ili.item_id               item_id     ';
        wk_sql2 := wk_sql2 || '                      , ili.lot_id                lot_id      ';
        wk_sql2 := wk_sql2 || '                 FROM   mtl_item_locations        mil    ';
        wk_sql2 := wk_sql2 || '                      , ic_whse_mst               iwm    ';
        wk_sql2 := wk_sql2 || '                      , ic_loct_inv               ili    ';
        wk_sql2 := wk_sql2 || '                 WHERE ili.item_id            = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND   mil.segment1           = ili.location ';
        wk_sql2 := wk_sql2 || '                 AND   mil.organization_id    = iwm.mtl_organization_id ';
        wk_sql2 := wk_sql2 || '                 AND   ili.loct_onhand        > 0 ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  mrih.ship_to_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                 item_id     ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                  lot_id      ';
        wk_sql2 := wk_sql2 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql2 := wk_sql2 || '                 WHERE   mrih.comp_actual_flg   = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.status            IN (''05'', ''06'') ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.mov_hdr_id        = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.mov_line_id       = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.delete_flg        = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id            = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code = ''20'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code   = ''30'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  mrih.shipped_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                 item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                  lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql2 := wk_sql2 || '                 WHERE   mrih.comp_actual_flg   = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.status            IN (''04'', ''06'') ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.mov_hdr_id        = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.mov_line_id       = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.delete_flg        = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id            = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code = ''20'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code   = ''20'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  /*+ index(MLD XXINV_MLD_N99) */ oha.deliver_from_id        location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                item_id     ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                 lot_id      ';
        wk_sql2 := wk_sql2 || '                 FROM    xxwsh_order_headers_all    oha  ';
        wk_sql2 := wk_sql2 || '                       , xxwsh_order_lines_all      ola  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details      mld  ';
        wk_sql2 := wk_sql2 || '                       , oe_transaction_types_all   otta ';
        wk_sql2 := wk_sql2 || '                 WHERE   oha.req_status           = ''04'' ';
        wk_sql2 := wk_sql2 || '                 AND     oha.actual_confirm_class = ''N''  ';
        wk_sql2 := wk_sql2 || '                 AND     oha.latest_external_flag = ''Y''  ';
        wk_sql2 := wk_sql2 || '                 AND     oha.order_header_id      = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '                 AND     ola.delete_flag          = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     ola.order_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id              = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code   = ''10'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code     = ''20'' ';
        wk_sql2 := wk_sql2 || '                 AND     otta.attribute1          IN (''1'', ''3'') ';
        wk_sql2 := wk_sql2 || '                 AND     otta.transaction_type_id = oha.order_type_id ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  /*+ index(MLD XXINV_MLD_N99) */ oha.deliver_from_id        location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                item_id     ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                 lot_id      ';
        wk_sql2 := wk_sql2 || '                 FROM    xxwsh_order_headers_all    oha   ';
        wk_sql2 := wk_sql2 || '                       , xxwsh_order_lines_all      ola   ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details      mld   ';
        wk_sql2 := wk_sql2 || '                       , oe_transaction_types_all   otta  ';
        wk_sql2 := wk_sql2 || '                 WHERE   oha.req_status           = ''08'' ';
        wk_sql2 := wk_sql2 || '                 AND     oha.actual_confirm_class = ''N''  ';
        wk_sql2 := wk_sql2 || '                 AND     oha.latest_external_flag = ''Y''  ';
        wk_sql2 := wk_sql2 || '                 AND     oha.order_header_id      = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '                 AND     ola.delete_flag          = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     ola.order_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id              = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code   = ''30'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code     = ''20'' ';
        wk_sql2 := wk_sql2 || '                 AND     otta.attribute1          = ''2'' ';
        wk_sql2 := wk_sql2 || '                 AND     otta.transaction_type_id = oha.order_type_id ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  mil.inventory_location_id  location_id ';
        wk_sql2 := wk_sql2 || '                       , ilm.item_id                item_id     ';
        wk_sql2 := wk_sql2 || '                       , ilm.lot_id                 lot_id      ';
        wk_sql2 := wk_sql2 || '                 FROM    po_lines_all               pla  ';
        wk_sql2 := wk_sql2 || '                       , po_headers_all             pha  ';
        wk_sql2 := wk_sql2 || '                       , mtl_item_locations         mil  ';
        wk_sql2 := wk_sql2 || '                       , ic_lots_mst                ilm  ';
        wk_sql2 := wk_sql2 || '                 WHERE   pla.item_id       = ' || lt_inv_item_id;
        wk_sql2 := wk_sql2 || '                 AND     pla.attribute1    = ilm.lot_no ';
        wk_sql2 := wk_sql2 || '                 AND     ilm.item_id       = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     pla.attribute13   = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     pla.cancel_flag   = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     pla.po_header_id  = pha.po_header_id ';
        wk_sql2 := wk_sql2 || '                 AND     pha.attribute1    IN (''20'', ''25'') ';
        wk_sql2 := wk_sql2 || '                 AND     pha.attribute5    = mil.segment1 ';
        wk_sql2 := wk_sql2 || '                 AND     pha.attribute4   <= TO_CHAR(TO_DATE(''' || id_material_date || '''), ''YYYY/MM/DD'') ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  mrih.ship_to_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                 item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                  lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql2 := wk_sql2 || '                 WHERE   mrih.comp_actual_flg        = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.status                 IN (''02'', ''03'') ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.schedule_arrival_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.mov_line_id            = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.delete_flg             = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id                 = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code      = ''20'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code        = ''10'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  mrih.ship_to_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                 item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                  lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql2 := wk_sql2 || '                 WHERE   mrih.comp_actual_flg        = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.status                 = ''04'' ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql2 := wk_sql2 || '                 AND     mrih.schedule_ship_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= TO_DATE(''' || id_material_date || ''') ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql2 := wk_sql2 || '                 AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.mov_line_id            = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.delete_flg             = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id                 = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code      = ''20'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code        = ''20'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  /*+ use_nl(gmd mld gbh grb itp mil) */ mil.inventory_location_id location_id ';
        wk_sql2 := wk_sql2 || '                       , gmd.item_id                item_id ';
        wk_sql2 := wk_sql2 || '                       , itp.lot_id                 lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    gme_batch_header           gbh  ';
        wk_sql2 := wk_sql2 || '                       , gme_material_details       gmd  ';
        wk_sql2 := wk_sql2 || '                       , ic_tran_pnd                itp  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details      mld  ';
        wk_sql2 := wk_sql2 || '                       , gmd_routings_b             grb  ';
        wk_sql2 := wk_sql2 || '                       , mtl_item_locations         mil  ';
        wk_sql2 := wk_sql2 || '                 WHERE   gbh.batch_status       IN (1, 2) ';
        wk_sql2 := wk_sql2 || '                 AND     gbh.plan_start_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND     gbh.batch_id           = gmd.batch_id ';
        wk_sql2 := wk_sql2 || '                 AND     gmd.line_type          IN (1, 2) ';
        wk_sql2 := wk_sql2 || '                 AND     gmd.line_type          = itp.line_type ';
        wk_sql2 := wk_sql2 || '                 AND     gmd.item_id            = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     gmd.material_detail_id = itp.line_id ';
        wk_sql2 := wk_sql2 || '                 AND     itp.completed_ind      = 0 ';
        wk_sql2 := wk_sql2 || '                 AND     itp.doc_type           = ''PROD'' ';
-- 2008/12/24 D.Nihei ADD START �{�ԏ�Q#836
        wk_sql2 := wk_sql2 || '                 AND     itp.delete_mark        = 0 ';
-- 2008/12/24 D.Nihei ADD END
        wk_sql2 := wk_sql2 || '                 AND     gmd.material_detail_id = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code = ''40'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code   = ''10'' ';
        wk_sql2 := wk_sql2 || '                 AND     gbh.routing_id         = grb.routing_id ';
        wk_sql2 := wk_sql2 || '                 AND     grb.attribute9         = mil.segment1  ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  mrih.shipped_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                 item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                  lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql2 := wk_sql2 || '                 WHERE   mrih.comp_actual_flg     = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.status              IN (''02'', ''03'') ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.schedule_ship_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.mov_hdr_id          = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.mov_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.delete_flg          = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id              = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code   = ''20'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code     = ''10'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  mrih.shipped_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                 item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                  lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql2 := wk_sql2 || '                 WHERE   mrih.comp_actual_flg     = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.status              = ''05'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.schedule_ship_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.mov_hdr_id          = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.mov_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.delete_flg          = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id              = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code   = ''20'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code     = ''30'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  /*+ index(MLD XXINV_MLD_N99) */ oha.deliver_from_id        location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                 lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    xxwsh_order_headers_all    oha  ';
        wk_sql2 := wk_sql2 || '                       , xxwsh_order_lines_all      ola  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details      mld  ';
        wk_sql2 := wk_sql2 || '                       , oe_transaction_types_all   otta ';
        wk_sql2 := wk_sql2 || '                 WHERE   oha.req_status           = ''03'' ';
        wk_sql2 := wk_sql2 || '                 AND     oha.actual_confirm_class = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     oha.latest_external_flag = ''Y'' ';
        wk_sql2 := wk_sql2 || '                 AND     oha.schedule_ship_date  <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND     oha.order_header_id      = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '                 AND     ola.delete_flag          = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     ola.order_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id              = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code   = ''10'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code     = ''10'' ';
        wk_sql2 := wk_sql2 || '                 AND     otta.attribute1          = ''1'' ';
        wk_sql2 := wk_sql2 || '                 AND     otta.transaction_type_id = oha.order_type_id ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  /*+ index(MLD XXINV_MLD_N99) */ oha.deliver_from_id      location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id              item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id               lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    xxwsh_order_headers_all  oha  ';
        wk_sql2 := wk_sql2 || '                       , xxwsh_order_lines_all    ola  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details    mld  ';
        wk_sql2 := wk_sql2 || '                       , oe_transaction_types_all otta ';
        wk_sql2 := wk_sql2 || '                 WHERE   oha.req_status            = ''07'' ';
        wk_sql2 := wk_sql2 || '                 AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql2 := wk_sql2 || '                 AND     oha.schedule_ship_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '                 AND     ola.delete_flag           = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id               = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code    = ''30'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code      = ''10'' ';
        wk_sql2 := wk_sql2 || '                 AND     otta.attribute1           = ''2'' ';
        wk_sql2 := wk_sql2 || '                 AND     otta.transaction_type_id  = oha.order_type_id ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  /*+ use_nl(gmd mld gbh grb itp mil) */ mil.inventory_location_id  location_id ';
        wk_sql2 := wk_sql2 || '                       , gmd.item_id                item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                 lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    gme_batch_header           gbh  ';
        wk_sql2 := wk_sql2 || '                       , gme_material_details       gmd  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details      mld  ';
        wk_sql2 := wk_sql2 || '                       , gmd_routings_b             grb  ';
        wk_sql2 := wk_sql2 || '                       , ic_tran_pnd                itp  ';
        wk_sql2 := wk_sql2 || '                       , mtl_item_locations         mil  ';
        wk_sql2 := wk_sql2 || '                 WHERE   gbh.batch_status       IN (1, 2) ';
        wk_sql2 := wk_sql2 || '                 AND     gbh.plan_start_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '                 AND     gbh.batch_id           = gmd.batch_id ';
        wk_sql2 := wk_sql2 || '                 AND     gmd.line_type          = -1 ';
        wk_sql2 := wk_sql2 || '                 AND     gmd.item_id            = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     gmd.material_detail_id = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     gbh.routing_id         = grb.routing_id ';
        wk_sql2 := wk_sql2 || '                 AND     grb.attribute9         = mil.segment1  ';
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code = ''40'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code   = ''10'' ';
-- 2008/11/19 v1.4 D.Nihei ADD START ������Q#681
        wk_sql2 := wk_sql2 || '                 AND     itp.doc_type           = ''PROD'' ';
-- 2008/11/19 v1.4 D.Nihei ADD END
-- 2008/12/02 v1.5 D.Nihei ADD START ������Q#251
        wk_sql2 := wk_sql2 || '                 AND     itp.delete_mark        = 0 ';
-- 2008/12/02 v1.5 D.Nihei ADD END
        wk_sql2 := wk_sql2 || '                 AND     itp.line_id            = gmd.material_detail_id  ';
        wk_sql2 := wk_sql2 || '                 AND     itp.item_id            = gmd.item_id ';
        wk_sql2 := wk_sql2 || '                 AND     itp.lot_id             = mld.lot_id ';
        wk_sql2 := wk_sql2 || '                 AND     itp.completed_ind      = 0 ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  mil.inventory_location_id  location_id ';
        wk_sql2 := wk_sql2 || '                       , ' || lt_item_id || '       item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                 lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    po_lines_all               pla   ';
        wk_sql2 := wk_sql2 || '                       , po_headers_all             pha   ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details      mld   ';
        wk_sql2 := wk_sql2 || '                       , mtl_item_locations         mil   ';
        wk_sql2 := wk_sql2 || '                 WHERE   pla.item_id            = ' || lt_inv_item_id;
        wk_sql2 := wk_sql2 || '                 AND     pla.attribute13        = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     pla.cancel_flag        = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     pla.attribute12        = mil.segment1      ';
        wk_sql2 := wk_sql2 || '                 AND     pla.po_header_id       = pha.po_header_id  ';
        wk_sql2 := wk_sql2 || '                 AND     pha.attribute1         IN (''20'', ''25'') ';
        wk_sql2 := wk_sql2 || '                 AND     pha.attribute4        <= TO_CHAR(TO_DATE(''' || id_material_date || '''), ''YYYY/MM/DD'') ';
        wk_sql2 := wk_sql2 || '                 AND     pla.po_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code = ''50'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code   = ''10'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  mrih.ship_to_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                 item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                  lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql2 := wk_sql2 || '                 WHERE   mrih.comp_actual_flg    = ''Y'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.correct_actual_flg = ''Y'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.status             = ''06'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.delete_flg         = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id             = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code  = ''20'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code    = ''30'' ';
        wk_sql2 := wk_sql2 || '                 UNION ';
        wk_sql2 := wk_sql2 || '                 SELECT  mrih.shipped_locat_id       location_id ';
        wk_sql2 := wk_sql2 || '                       , mld.item_id                 item_id ';
        wk_sql2 := wk_sql2 || '                       , mld.lot_id                  lot_id ';
        wk_sql2 := wk_sql2 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql2 := wk_sql2 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql2 := wk_sql2 || '                 WHERE   mrih.comp_actual_flg    = ''Y'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.correct_actual_flg = ''Y'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.status             = ''06'' ';
        wk_sql2 := wk_sql2 || '                 AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '                 AND     mril.delete_flg         = ''N'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.item_id             = ' || lt_item_id;
        wk_sql2 := wk_sql2 || '                 AND     mld.document_type_code  = ''20'' ';
        wk_sql2 := wk_sql2 || '                 AND     mld.record_type_code    = ''20'' ';
      END IF;
      wk_sql2 := wk_sql2 || '                 ) inv ';
-- 2008/10/22 D.Nihei MOD START
--      wk_sql2 := wk_sql2 || '               , ( SELECT  ilm.item_id  item_id ';
--      wk_sql2 := wk_sql2 || '                         , ilm.lot_id   lot_id  ';
--      wk_sql2 := wk_sql2 || '                   FROM    ic_lots_mst        ilm     '; -- OPM���b�g�}�X�^
--      --==========================
--      -- ����
--      --==========================
--      IF ( lt_item_class_code = cv_shizai ) 
--      THEN
--        wk_sql2 := wk_sql2 || '                 WHERE   ilm.item_id = ' || lt_item_id;
--      --==========================
--      -- ���ވȊO
--      --==========================
--      ELSE
--        wk_sql2 := wk_sql2 || '                       , xxcmn_lot_status_v xlsv '; -- ���b�g�X�e�[�^�X
--        wk_sql2 := wk_sql2 || '                 WHERE   ilm.item_id                  = '   || lt_item_id;
--        wk_sql2 := wk_sql2 || '                 AND     xlsv.prod_class_code         = ''' || lt_prod_class_code || '''';
--        wk_sql2 := wk_sql2 || '                 AND     xlsv.raw_mate_turn_m_reserve = ''Y''           ';
--        wk_sql2 := wk_sql2 || '                 AND     xlsv.lot_status              = ilm.attribute23 ';
--      END IF;
--      wk_sql2 := wk_sql2 || '                 ) lot ';
      wk_sql2 := wk_sql2 || '                 , ic_lots_mst lot ';
-- 2008/10/22 D.Nihei MOD END
      wk_sql2 := wk_sql2 || '               WHERE NOT EXISTS (SELECT 1  ';
      wk_sql2 := wk_sql2 || '                                 FROM   xxwip_material_detail   xmdd ';     -- ���Y�����ڍ׃A�h�I��
      wk_sql2 := wk_sql2 || '                                 WHERE  xmdd.material_detail_id  = ' || in_material_detail_id;
      wk_sql2 := wk_sql2 || '                                 AND    xmdd.plan_type           IN ( ''1'', ''2'', ''3'' )     ';
      wk_sql2 := wk_sql2 || '                                 AND    xilv.segment1           = xmdd.location_code ';
      wk_sql2 := wk_sql2 || '                                 AND    lot.lot_id              = xmdd.lot_id ) ';
      wk_sql2 := wk_sql2 || '               AND   inv.item_id     = lot.item_id ';
      wk_sql2 := wk_sql2 || '               AND   inv.location_id = xilv.inventory_location_id ';
      wk_sql2 := wk_sql2 || '               AND   inv.lot_id      = lot.lot_id ';
      --==========================
      -- ���������F�o�q��1�`5�̂����ꂩ���w�肳��Ă���ꍇ
      --==========================
      IF ( ( lt_location1 IS NOT NULL )
        OR ( lt_location2 IS NOT NULL )
        OR ( lt_location3 IS NOT NULL )
        OR ( lt_location4 IS NOT NULL )
        OR ( lt_location5 IS NOT NULL )
         )
      THEN
        wk_sql2 := wk_sql2 || '             AND  xilv.segment1 IN ( ''' || lt_location1 || ''', ''' 
                                                                        || lt_location2 || ''', ''' 
                                                                        || lt_location3 || ''', ''' 
                                                                        || lt_location4 || ''', ''' 
                                                                        || lt_location5 || ''' ) ';
      END IF;
      wk_sql2 := wk_sql2 || '        ) enable_lot ';
      wk_sql2 := wk_sql2 || '      WHERE ilm.item_id = enable_lot.item_id ';
      wk_sql2 := wk_sql2 || '        AND ilm.lot_id  = enable_lot.lot_id ';
      wk_sql2 := wk_sql2 || '      ORDER BY enable_lot.record_type             DESC ';
      wk_sql2 := wk_sql2 || '              ,enable_lot.whse_inside_outside_div DESC ';
      wk_sql2 := wk_sql2 || '              ,enable_lot.storehouse_code ';
-- 2008/10/29 D.Nihei MOD START ������Q#481
--      wk_sql2 := wk_sql2 || '              ,TO_NUMBER( lot_no ) ';
      wk_sql2 := wk_sql2 || '              ,TO_NUMBER( DECODE(lot_id ,0, NULL,lot_no) ) ';
-- 2008/10/29 D.Nihei MOD END
--
-- 2008/10/07 D.Nihei DEL START
--      EXECUTE IMMEDIATE wk_sql BULK COLLECT INTO ior_ilm_data ;
-- 2008/10/07 D.Nihei DEL END
      -- �ϐ��̏�����
      ln_cnt := 1;
      OPEN wk_cv FOR wk_sql1 || wk_sql2;
      LOOP
        FETCH wk_cv 
        INTO ior_ilm_data(ln_cnt).storehouse_id
           , ior_ilm_data(ln_cnt).storehouse_code
           , ior_ilm_data(ln_cnt).storehouse_name
           , ior_ilm_data(ln_cnt).batch_id
           , ior_ilm_data(ln_cnt).material_detail_id
           , ior_ilm_data(ln_cnt).mtl_detail_addon_id
           , ior_ilm_data(ln_cnt).mov_lot_dtl_id
           , ior_ilm_data(ln_cnt).trans_id
           , ior_ilm_data(ln_cnt).item_id
           , ior_ilm_data(ln_cnt).item_no
           , ior_ilm_data(ln_cnt).lot_id
           , ior_ilm_data(ln_cnt).lot_no
           , ior_ilm_data(ln_cnt).lot_create_type
           , ior_ilm_data(ln_cnt).instructions_qty
           , ior_ilm_data(ln_cnt).instructions_qty_orig
           , ior_ilm_data(ln_cnt).stock_qty
           , ior_ilm_data(ln_cnt).inbound_qty
           , ior_ilm_data(ln_cnt).outbound_qty
           , ior_ilm_data(ln_cnt).enabled_qty
           , ior_ilm_data(ln_cnt).entity_inner
           , ior_ilm_data(ln_cnt).unit_price
           , ior_ilm_data(ln_cnt).orgn_code
           , ior_ilm_data(ln_cnt).orgn_name
           , ior_ilm_data(ln_cnt).stocking_form
           , ior_ilm_data(ln_cnt).tea_season_type
           , ior_ilm_data(ln_cnt).period_of_year
           , ior_ilm_data(ln_cnt).producing_area
           , ior_ilm_data(ln_cnt).package_type
           , ior_ilm_data(ln_cnt).rank1
           , ior_ilm_data(ln_cnt).rank2
           , ior_ilm_data(ln_cnt).rank3
           , ior_ilm_data(ln_cnt).maker_date
           , ior_ilm_data(ln_cnt).use_by_date
           , ior_ilm_data(ln_cnt).unique_sign
           , ior_ilm_data(ln_cnt).dely_date
           , ior_ilm_data(ln_cnt).slip_type_name
           , ior_ilm_data(ln_cnt).routing_no
           , ior_ilm_data(ln_cnt).routing_name
           , ior_ilm_data(ln_cnt).remarks_column
           , ior_ilm_data(ln_cnt).record_type
           , ior_ilm_data(ln_cnt).created_by
           , ior_ilm_data(ln_cnt).creation_date
           , ior_ilm_data(ln_cnt).last_updated_by
           , ior_ilm_data(ln_cnt).last_update_date
           , ior_ilm_data(ln_cnt).last_update_login
           , ior_ilm_data(ln_cnt).xmd_last_update_date
           , ior_ilm_data(ln_cnt).whse_inside_outside_div;
        EXIT WHEN wk_cv%NOTFOUND;
        ior_ilm_data(ln_cnt).enabled_qty := ior_ilm_data(ln_cnt).stock_qty + ior_ilm_data(ln_cnt).inbound_qty - ior_ilm_data(ln_cnt).outbound_qty;
        IF ( ( ior_ilm_data(ln_cnt).enabled_qty <= 0 ) 
         AND ( ior_ilm_data(ln_cnt).record_type =  0 ) ) 
        THEN
          ior_ilm_data.DELETE(ln_cnt);
-- 2008/12/24 D.Nihei ADD START �{�ԏ�Q#837
        ELSIF ( ( lt_prod_item_id = ior_ilm_data(ln_cnt).item_id ) 
            AND ( lt_prod_lot_id  = ior_ilm_data(ln_cnt).lot_id ) ) 
        THEN
         ior_ilm_data.DELETE(ln_cnt);
-- 2008/12/24 D.Nihei ADD END
-- 2008/10/22 D.Nihei ADD START
        ELSIF ( ( lt_item_class_code              <> cv_shizai ) 
            AND ( ior_ilm_data(ln_cnt).record_type =  0        ) ) 
        THEN
          BEGIN
            SELECT  ilm.attribute23
            INTO    lt_dummy
            FROM    xxcmn_lot_status_v xlsv
                   ,ic_lots_mst        ilm
            WHERE   ilm.item_id                  = lt_item_id
            AND     ilm.lot_id                   = ior_ilm_data(ln_cnt).lot_id
            AND     xlsv.prod_class_code         = lt_prod_class_code
            AND     xlsv.raw_mate_turn_m_reserve = 'Y'
            AND     xlsv.lot_status              = ilm.attribute23
            
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ior_ilm_data.DELETE(ln_cnt);
          END;
-- 2008/10/22 D.Nihei ADD END
        END IF;
--
        ln_cnt := ln_cnt + 1;
      END LOOP;
--
      CLOSE wk_cv;
--
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
  END blk_ilm_qry;
--
END xxwip200001;
/
