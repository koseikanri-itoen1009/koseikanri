CREATE OR REPLACE PACKAGE BODY xxwip200001
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip200001(BODY)
 * Description            : 生産バッチロット詳細画面データソースパッケージ(BODY)
 * MD.050                 : T_MD050_BPO_200_生産バッチ.doc
 * MD.070                 : T_MD070_BPO_20A_生産バッチ一覧画面.doc
 * Version                : 1.16
 *
 * Program List
 *  --------------------  ---- ----- -------------------------------------------------
 *   Name                 Type  Ret   Description
 *  --------------------  ---- ----- -------------------------------------------------
 *  blk_ilm_qry             P    -    データ取得
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/08/28   1.0   D.Nihei          新規作成
 *  2008/10/07   1.1   D.Nihei          統合障害#123対応（PT 6-2_31）
 *  2008/10/22   1.2   D.Nihei          統合障害#123対応（PT 6-2_31）(ロットステータスVIEW箇所修正)
 *  2008/10/29   1.3   D.Nihei          統合障害#481対応（ORDER BY句編集) 
 *  2008/11/19   1.4   D.Nihei          統合障害#681対応（条件追加) 
 *  2008/12/02   1.5   D.Nihei          本番障害#251対応（条件追加) 
 *  2008/12/19   1.6   D.Nihei          本番障害#645対応（条件修正) 
 *                                      本番障害#648対応（条件修正) 
 *  2008/12/24   1.7   D.Nihei          本番障害#836対応（抽出箇所編集) 
 *                                      本番障害#837対応（抽出箇所編集) 
 *  2009/01/05   1.8   D.Nihei          本番障害#912対応（抽出SQL追加) 
 *  2009/02/02   1.9   D.Nihei          本番障害#1112対応（総引当ベースロジック追加) 
 *  2009/02/18   1.10  N.Yoshida        統合障害#701対応（条件追加) 
 *  2009/03/03   1.11  D.Nihei          本番障害#@@@@対応（手配コピー時の条件追加) 
 *  2009/03/19   1.12  H.Itou           本番障害#1332対応（他倉庫ロットの元指示総数が0になる不具合修正）
 *  2009/03/25   1.13  H.Itou           本番障害#1312対応（相手先在庫管理倉庫は対象外とする）
 *  2009/03/30   1.14  H.Itou           本番障害#1346対応（営業単位対応）
 *  2011/12/06   1.15  Y.Horikawa       E_本稼動_07421対応（パフォーマンス改善）
 *  2012/12/17   1.16  K.Kiriu          E_本稼動_10347対応（2013年以降引当ができない障害対応）
 *****************************************************************************************/
--
  -- 定数宣言
  cv_status_normal        CONSTANT VARCHAR2(1)  := '0';
  cv_status_warning       CONSTANT VARCHAR2(1)  := '1';
  cv_status_error         CONSTANT VARCHAR2(1)  := '2';
  cv_shizai               CONSTANT VARCHAR2(1)  := '2';
--
  /***********************************************************************************
   * Procedure Name   : blk_ilm_qry
   * Description      : データ取得(REFカーソルオープン)
   ***********************************************************************************/
  PROCEDURE blk_ilm_qry(
    ior_ilm_data            IN OUT NOCOPY tbl_ilm_block
  , in_material_detail_id   IN gme_material_details.material_detail_id%TYPE   -- 生産原料詳細ID
  , id_material_date        IN DATE                                           -- 原料入庫予定日
  )
  IS
--
-- 2009/03/30 H.Itou ADD START 本番障害#1346
    cv_prf_org_id            CONSTANT VARCHAR2(100) := 'ORG_ID';                  -- プロファイル：ORG_ID
-- 2009/03/30 H.Itou ADD END
    -- 変数宣言
    lt_item_class_code       xxcmn_item_categories5_v.item_class_code%TYPE;       -- 品目区分
    lt_prod_class_code       xxcmn_item_categories5_v.prod_class_code%TYPE;       -- 商品区分
    lt_location1             xxcmn_item_locations_v.segment1%TYPE;                -- 出庫倉庫1
    lt_location2             xxcmn_item_locations_v.segment1%TYPE;                -- 出庫倉庫2
    lt_location3             xxcmn_item_locations_v.segment1%TYPE;                -- 出庫倉庫3
    lt_location4             xxcmn_item_locations_v.segment1%TYPE;                -- 出庫倉庫4
    lt_location5             xxcmn_item_locations_v.segment1%TYPE;                -- 出庫倉庫5
    lt_item_id               xxcmn_item_mst_v.item_id%TYPE;                       -- 品目ID
    lt_inv_item_id           xxcmn_item_mst_v.inventory_item_id%TYPE;             -- INV品目ID
    lt_item_no               xxcmn_item_mst_v.item_no%TYPE;                       -- 品目No
    wk_sql1                  VARCHAR2(32767);
    wk_sql2                  VARCHAR2(32767);
-- 2009/02/02 D.Nihei ADD START
    wk_sql3                  VARCHAR2(32767);
    wk_sql4                  VARCHAR2(32767);
    ln_enabeled_qty_all      NUMBER;                                              -- 引当可能数(総引当ベース)
    ln_enabeled_qty_time     NUMBER;                                              -- 引当可能数(有効日ベース)
    ld_max_date              DATE;                                                -- MAX日付
    ln_inbound_qty_all       NUMBER;                                              -- 入庫予定数(総引当ベース)
    ln_outbound_qty_all      NUMBER;                                              -- 出庫予定数(総引当ベース)
-- 2009/02/02 D.Nihei ADD END
    lt_batch_id              gme_batch_header.batch_id%TYPE;                      -- バッチID
    TYPE wk_cur IS REF CURSOR;
    wk_cv   wk_cur;
    ln_cnt                   NUMBER;                                              -- 配列の添字
-- 2009/03/03 D.Nihei ADD START
    ln_inst_cnt              NUMBER;                                              -- 予定区分4の件数取得
-- 2009/03/03 D.Nihei ADD END
-- 2008/10/22 D.Nihei ADD START
    lt_dummy                 ic_lots_mst.attribute23%TYPE;                        -- 
-- 2008/10/22 D.Nihei ADD END
-- 2008/12/24 D.Nihei ADD START 本番障害#837
    lt_prod_item_id          ic_lots_mst.item_id%TYPE;                            -- 品目ID(完成品)
    lt_prod_lot_id           ic_lots_mst.lot_id%TYPE;                             -- ロットID(完成品)
-- 2008/12/24 D.Nihei ADD END
-- 2009/03/30 H.Itou ADD START 本番障害#1346
    lv_org_id                VARCHAR2(1000);                                      -- ORG_ID
-- 2009/03/30 H.Itou ADD END
--
  BEGIN
--
-- 2009/03/30 H.Itou ADD START 本番障害#1346
    --==========================
    -- ORG_ID取得
    --==========================
    lv_org_id := FND_PROFILE.VALUE(cv_prf_org_id);
-- 2009/03/30 H.Itou ADD END
    BEGIN
      --==========================
      -- 対象倉庫情報取得
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
      FROM   gme_material_details gmd -- 生産原料詳細
      WHERE  gmd.material_detail_id = in_material_detail_id
      ;
--
      --==========================
      -- 品目区分、商品区分取得
      --==========================
      SELECT ximv.item_no           item_no
           , ximv.inventory_item_id inventory_item_id
           , xicv.item_class_code   item_class_code
           , xicv.prod_class_code   prod_class_code
      INTO   lt_item_no
           , lt_inv_item_id
           , lt_item_class_code
           , lt_prod_class_code
      FROM   xxcmn_item_mst_v         ximv  -- OPM品目マスタVIEW
           , xxcmn_item_categories5_v xicv  -- 品目カテゴリ情報VIEW5
      WHERE  ximv.item_id = xicv.item_id
      AND    xicv.item_id = lt_item_id
      ;
-- 2008/12/24 D.Nihei ADD START 本番障害#837
      --==========================
      -- 完成品情報取得
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
-- 2009/02/02 D.Nihei ADD START
      --==========================
      -- MAX日付設定
      --==========================
-- 2012/12/17 K.Kiriu MOD START
--      ld_max_date  := FND_DATE.STRING_TO_DATE('4712/12/31', 'YYYY/MM/DD');
      ld_max_date  := FND_DATE.STRING_TO_DATE('2049/12/31', 'YYYY/MM/DD');
-- 2012/12/17 K.Kiriu MOD END
--
-- 2009/02/02 D.Nihei ADD END
      --==========================
      -- 動的SQL作成
      --==========================
      wk_sql1 := NULL;
      wk_sql2 := NULL;
-- 2011/12/06 Mod Start Ver.1.15
--      wk_sql1 := wk_sql1 || 'SELECT  enable_lot.inventory_location_id      storehouse_id            '; -- 保管倉庫ID
      wk_sql1 := wk_sql1 || 'SELECT  /*+ leading(enable_lot) index(ilm ic_lots_mst_pk) use_nl(enable_lot ilm) */ ';
      wk_sql1 := wk_sql1 || '        enable_lot.inventory_location_id      storehouse_id            '; -- 保管倉庫ID
-- 2011/12/06 Mod End Ver.1.15
      wk_sql1 := wk_sql1 || '      , enable_lot.storehouse_code            storehouse_code          '; -- 保管倉庫(コード)
      wk_sql1 := wk_sql1 || '      , enable_lot.description                storehouse_name          '; -- 保管倉庫(名称)
      wk_sql1 := wk_sql1 || '      , ' || lt_batch_id || '                 batch_id                 '; -- バッチID
      wk_sql1 := wk_sql1 || '      , ' || in_material_detail_id || '       material_detail_id       '; -- 生産原料詳細ID
      wk_sql1 := wk_sql1 || '      , enable_lot.mtl_detail_addon_id        mtl_detail_addon_id      '; -- 生産原料詳細アドオンID
      wk_sql1 := wk_sql1 || '      , enable_lot.mov_lot_dtl_id             mov_lot_dtl_id           '; -- 移動ロット詳細ID
      wk_sql1 := wk_sql1 || '      , NULL                                  trans_id                 '; -- 
      wk_sql1 := wk_sql1 || '      , enable_lot.item_id                    item_id                  '; -- 品目ID
      wk_sql1 := wk_sql1 || '      , ''' || lt_item_no || '''              item_no                  '; -- 品目(コード)
      wk_sql1 := wk_sql1 || '      , enable_lot.lot_id                     lot_id                   '; -- ロットID
      --==========================
      -- 資材
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
        wk_sql1 := wk_sql1 || '    , NULL ';
      --==========================
      -- 資材以外
      --==========================
      ELSE
        wk_sql1 := wk_sql1 || '    , ilm.lot_no ';
      END IF;
      wk_sql1 := wk_sql1 || '                                              lot_no                   '; -- ロットNo
      wk_sql1 := wk_sql1 || '      , ilm.attribute24                       lot_create_type          '; -- 作成区分
      wk_sql1 := wk_sql1 || '      , enable_lot.instructions_qty           instructions_qty         '; -- 指示総数
      wk_sql1 := wk_sql1 || '      , enable_lot.instructions_qty           instructions_qty_orig    '; -- 元指示総数
      --==========================
      -- 資材
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
--        wk_sql1 := wk_sql1 || '    , xxcmn_common_pkg.get_stock_qty(enable_lot.inventory_location_id, enable_lot.item_id, NULL ) stock_qty'; -- 在庫総数
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
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql1 := wk_sql1 || '       AND     otta.org_id                    = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
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
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql1 := wk_sql1 || '       AND     otta.org_id               = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
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
        wk_sql1 := wk_sql1 || '     )                                      stock_qty                '; -- 在庫総数
-- 入庫予定SQL(有効日ベース)
        wk_sql1 := wk_sql1 || '    ,( ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(pla.quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    po_lines_all       pla ';
        wk_sql1 := wk_sql1 || '             , po_headers_all     pha ';
        wk_sql1 := wk_sql1 || '       WHERE   pla.item_id       = ' || lt_inv_item_id ;
        wk_sql1 := wk_sql1 || '       AND     pla.po_header_id  = pha.po_header_id ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute5    = enable_lot.storehouse_code ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql1 := wk_sql1 || '       AND     pha.org_id        = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
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
        wk_sql1 := wk_sql1 || '     )                                      inbound_qty              '; -- 入庫予定数
-- 出庫予定SQL(有効日ベース)
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
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql1 := wk_sql1 || '       AND     otta.org_id                    = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
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
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql1 := wk_sql1 || '       AND     otta.org_id                    = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
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
        wk_sql1 := wk_sql1 || '     )                                      outbound_qty             '; -- 出庫予定数
-- 2009/02/02 D.Nihei ADD START
-- 入庫予定SQL(総引当ベース)
        wk_sql1 := wk_sql1 || '    ,( ';
        wk_sql1 := wk_sql1 || '      (SELECT  NVL(SUM(pla.quantity), 0) ';
        wk_sql1 := wk_sql1 || '       FROM    po_lines_all       pla ';
        wk_sql1 := wk_sql1 || '             , po_headers_all     pha ';
        wk_sql1 := wk_sql1 || '       WHERE   pla.item_id       = ' || lt_inv_item_id ;
        wk_sql1 := wk_sql1 || '       AND     pla.po_header_id  = pha.po_header_id ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute5    = enable_lot.storehouse_code ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql1 := wk_sql1 || '       AND     pha.org_id        = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql1 := wk_sql1 || '       AND     pha.attribute1    IN (''20'',''25'') ';
        wk_sql1 := wk_sql1 || '       AND     pha.attribute4   <= TO_CHAR(TO_DATE(''' || ld_max_date || '''), ''YYYY/MM/DD'') ';
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
        wk_sql1 := wk_sql1 || '       AND     mrih.schedule_arrival_date <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     mrih.comp_actual_flg        = ''N'' ';
        wk_sql1 := wk_sql1 || '       AND     mril.delete_flg             = ''N'') ';
        wk_sql1 := wk_sql1 || '     )                                      inbound_qty_all '; -- 入庫予定数
-- 出庫予定SQL(総引当ベース)
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
        wk_sql1 := wk_sql1 || '       AND     mrih.schedule_arrival_date <= TO_DATE(''' || ld_max_date || ''') ';
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
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql1 := wk_sql1 || '       AND     otta.org_id                    = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql1 := wk_sql1 || '       AND     oha.schedule_ship_date        <= TO_DATE(''' || ld_max_date || ''') ';
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
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql1 := wk_sql1 || '       AND     otta.org_id                    = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql1 := wk_sql1 || '       AND     oha.schedule_ship_date        <= TO_DATE(''' || ld_max_date || ''') ';
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
        wk_sql1 := wk_sql1 || '       AND     gbh.plan_start_date   <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql1 := wk_sql1 || '       AND     gmd.line_type          = -1 ';
        wk_sql1 := wk_sql1 || '       AND     xmd.plan_type          = ''4'' ';
        wk_sql1 := wk_sql1 || '       AND     xmd.invested_qty       = 0) ';
        wk_sql1 := wk_sql1 || '     )                                      outbound_qty_all '; -- 出庫予定数
-- 2009/02/02 D.Nihei ADD END
      --==========================
      -- 資材以外
      --==========================
      ELSE
        wk_sql2 := wk_sql2 || '    ,( ';
        wk_sql2 := wk_sql2 || '      (SELECT NVL(SUM(ili.loct_onhand), 0) ';
        wk_sql2 := wk_sql2 || '       FROM   ic_whse_mst         iwm ';
        wk_sql2 := wk_sql2 || '             ,mtl_item_locations  mil ';
        wk_sql2 := wk_sql2 || '             ,ic_loct_inv         ili ';
        wk_sql2 := wk_sql2 || '       WHERE mil.segment1              = ili.location ';
        wk_sql2 := wk_sql2 || '       AND   mil.organization_id       = iwm.mtl_organization_id ';
        wk_sql2 := wk_sql2 || '       AND   mil.inventory_location_id = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND   ili.item_id               = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND   ili.lot_id                = ilm.lot_id) ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.ship_to_locat_id   = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg    = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status             IN (''05'', ''06'') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code    = ''30'') ';
        wk_sql2 := wk_sql2 || '       - ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.shipped_locat_id   = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg    = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status             IN (''04'', ''06'') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code    = ''20'') ';
        wk_sql2 := wk_sql2 || '       - ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(CASE ';
        wk_sql2 := wk_sql2 || '               WHEN (otta.order_category_code = ''ORDER'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 mld.actual_quantity ';
        wk_sql2 := wk_sql2 || '                 NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0) ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql2 := wk_sql2 || '               WHEN (otta.order_category_code = ''RETURN'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 mld.actual_quantity * -1 ';
        wk_sql2 := wk_sql2 || '                 (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1 ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql2 := wk_sql2 || '               END), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql2 := wk_sql2 || '              ,xxwsh_order_lines_all      ola ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details      mld ';
        wk_sql2 := wk_sql2 || '              ,oe_transaction_types_all   otta ';
        wk_sql2 := wk_sql2 || '       WHERE   oha.deliver_from_id       = enable_lot.inventory_location_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql2 := wk_sql2 || '       AND     otta.org_id               = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql2 := wk_sql2 || '       AND     oha.req_status            = ''04'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id               = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id                = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code    = ''10'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code      = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.attribute1           IN (''1'', ''3'') ';
        wk_sql2 := wk_sql2 || '       AND     otta.transaction_type_id  = oha.order_type_id) ';
        wk_sql2 := wk_sql2 || '       - ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(CASE ';
        wk_sql2 := wk_sql2 || '               WHEN (otta.order_category_code = ''ORDER'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 mld.actual_quantity ';
        wk_sql2 := wk_sql2 || '                 NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0) ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql2 := wk_sql2 || '               WHEN (otta.order_category_code = ''RETURN'') THEN ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '                 mld.actual_quantity * -1 ';
        wk_sql2 := wk_sql2 || '                 (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1 ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql2 := wk_sql2 || '               END), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql2 := wk_sql2 || '              ,xxwsh_order_lines_all      ola ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details      mld ';
        wk_sql2 := wk_sql2 || '              ,oe_transaction_types_all   otta ';
        wk_sql2 := wk_sql2 || '       WHERE   oha.deliver_from_id       = enable_lot.inventory_location_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql2 := wk_sql2 || '       AND     otta.org_id               = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql2 := wk_sql2 || '       AND     oha.req_status            = ''08'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id               = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id                = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code    = ''30'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code      = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.attribute1           = ''2'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.transaction_type_id  = oha.order_type_id) ';
-- 2009/01/05 D.Nihei ADD START
        wk_sql2 := wk_sql2 || '      + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '             , xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '             , xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.ship_to_locat_id   = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg    = ''Y'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.correct_actual_flg = ''Y'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status             = ''06'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code    = ''30'') ';
        wk_sql2 := wk_sql2 || '      + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '             , xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '             , xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.shipped_locat_id   = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg    = ''Y'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.correct_actual_flg = ''Y'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status             = ''06'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code    = ''20'') ';
-- 2009/01/05 D.Nihei ADD END
        wk_sql2 := wk_sql2 || '     )                                      stock_qty                '; -- 在庫総数
-- 入庫予定SQL(有効日ベース)
        wk_sql2 := wk_sql2 || '    ,( ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(pla.quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    po_lines_all       pla ';
        wk_sql2 := wk_sql2 || '              ,po_headers_all     pha ';
        wk_sql2 := wk_sql2 || '       WHERE   pla.item_id      = ' || lt_inv_item_id ;
        wk_sql2 := wk_sql2 || '       AND     pla.attribute1   = ilm.lot_no ';
        wk_sql2 := wk_sql2 || '       AND     pla.attribute13  = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     pla.cancel_flag  = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     pla.po_header_id = pha.po_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql2 := wk_sql2 || '       AND     pha.org_id       = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql2 := wk_sql2 || '       AND     pha.attribute1   IN (''20'', ''25'') ';
        wk_sql2 := wk_sql2 || '       AND     pha.attribute5   = enable_lot.storehouse_code ';
        wk_sql2 := wk_sql2 || '       AND     pha.attribute4  <= TO_CHAR(TO_DATE(''' || id_material_date || '''), ''YYYY/MM/DD'')) ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.ship_to_locat_id       = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg        = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status                 IN (''02'', ''03'') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.schedule_arrival_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id            = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg             = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id                 = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id                  = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code      = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code        = ''10'') ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.ship_to_locat_id       = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg        = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status                 = ''04'' ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql1 := wk_sql1 || '       AND     mrih.schedule_arrival_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= TO_DATE(''' || id_material_date || ''') ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id            = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg             = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id                 = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id                  = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code      = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code        = ''20'') ';
        wk_sql2 := wk_sql2 || '       + ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '      (SELECT  /*+ leading(grb) use_nl(grb gbh gmd mld itp) index(gmd gme_material_details_n1) index(mld xxinv_mld_n03) index(itp ic_tran_pndi3) */ ';
        wk_sql2 := wk_sql2 || '               NVL(SUM(mld.actual_quantity), 0) ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql2 := wk_sql2 || '       FROM    gme_batch_header      gbh ';
        wk_sql2 := wk_sql2 || '              ,gme_material_details  gmd ';
        wk_sql2 := wk_sql2 || '              ,ic_tran_pnd           itp ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details mld ';
        wk_sql2 := wk_sql2 || '              ,gmd_routings_b        grb ';
        wk_sql2 := wk_sql2 || '       WHERE   gbh.batch_status       IN (1, 2) ';
        wk_sql2 := wk_sql2 || '       AND     gbh.plan_start_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     gbh.batch_id           = gmd.batch_id ';
        wk_sql2 := wk_sql2 || '       AND     gmd.line_type          IN (1,2) ';
        wk_sql2 := wk_sql2 || '       AND     gmd.item_id            = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     gmd.material_detail_id = itp.line_id ';
        wk_sql2 := wk_sql2 || '       AND     itp.completed_ind      = 0 ';
        wk_sql2 := wk_sql2 || '       AND     itp.doc_type           = ''PROD'' ';
        wk_sql2 := wk_sql2 || '       AND     itp.lot_id             = ilm.lot_id ';
-- 2008/12/24 D.Nihei ADD START 本番障害#836
        wk_sql2 := wk_sql2 || '       AND     itp.delete_mark        = 0 ';
-- 2008/12/24 D.Nihei ADD END
        wk_sql2 := wk_sql2 || '       AND     gmd.material_detail_id = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code = ''40'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code   = ''10'' ';
        wk_sql2 := wk_sql2 || '       AND     gbh.routing_id         = grb.routing_id ';
        wk_sql2 := wk_sql2 || '       AND     grb.attribute9         = enable_lot.storehouse_code) ';
        wk_sql2 := wk_sql2 || '      )                                     inbound_qty              '; -- 入庫予定数
-- 出庫予定SQL(有効日ベース)
        wk_sql2 := wk_sql2 || '    ,( ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.shipped_locat_id    = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg     = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status              IN (''02'', ''03'') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.schedule_ship_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id          = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg          = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id              = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id               = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code   = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code     = ''10'') ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.shipped_locat_id   = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg    = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status             = ''05'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.schedule_ship_date  <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code    = ''30'') ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql2 := wk_sql2 || '              ,xxwsh_order_lines_all      ola ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details      mld ';
        wk_sql2 := wk_sql2 || '              ,oe_transaction_types_all   otta ';
        wk_sql2 := wk_sql2 || '       WHERE   oha.deliver_from_id       = enable_lot.inventory_location_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql2 := wk_sql2 || '       AND     otta.org_id               = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql2 := wk_sql2 || '       AND     oha.req_status            = ''03'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.schedule_ship_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id               = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id                = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code    = ''10'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code      = ''10'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.attribute1           = ''1'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.transaction_type_id  = oha.order_type_id) ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql2 := wk_sql2 || '              ,xxwsh_order_lines_all      ola ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details      mld ';
        wk_sql2 := wk_sql2 || '              ,oe_transaction_types_all  otta ';
        wk_sql2 := wk_sql2 || '       WHERE   oha.deliver_from_id       = enable_lot.inventory_location_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql2 := wk_sql2 || '       AND     otta.org_id               = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql2 := wk_sql2 || '       AND     oha.req_status            = ''07'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.schedule_ship_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id               = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id                = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code    = ''30'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code      = ''10'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.attribute1           = ''2'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.transaction_type_id  = oha.order_type_id) ';
        wk_sql2 := wk_sql2 || '       + ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '      (SELECT  /*+ leading(grb) use_nl(grb gbh gmd mld itp) index(gmd gme_material_details_n1) index(mld xxinv_mld_n03) index(itp ic_tran_pndi3) */ ';
        wk_sql2 := wk_sql2 || '               NVL(SUM(mld.actual_quantity), 0) ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql2 := wk_sql2 || '       FROM    gme_batch_header      gbh ';
        wk_sql2 := wk_sql2 || '              ,gme_material_details  gmd ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details mld ';
        wk_sql2 := wk_sql2 || '              ,gmd_routings_b        grb ';
        wk_sql2 := wk_sql2 || '              ,ic_tran_pnd           itp ';
        wk_sql2 := wk_sql2 || '       WHERE   gbh.batch_status      IN (1, 2) ';
        wk_sql2 := wk_sql2 || '       AND     gbh.plan_start_date   <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     gbh.batch_id           = gmd.batch_id ';
        wk_sql2 := wk_sql2 || '       AND     gmd.line_type          = -1 ';
        wk_sql2 := wk_sql2 || '       AND     gmd.item_id            = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     gmd.material_detail_id = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id             = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     gbh.routing_id         = grb.routing_id ';
        wk_sql2 := wk_sql2 || '       AND     grb.attribute9         = enable_lot.storehouse_code ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code = ''40'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code   = ''10'' ';
-- 2008/11/19 v1.4 D.Nihei ADD START 統合障害#681
        wk_sql2 := wk_sql2 || '       AND     itp.doc_type           = ''PROD'' ';
-- 2008/11/19 v1.4 D.Nihei ADD END
-- 2008/12/02 v1.5 D.Nihei ADD START 統合障害#251
        wk_sql2 := wk_sql2 || '       AND     itp.delete_mark        = 0 ';
-- 2008/12/02 v1.5 D.Nihei ADD END
        wk_sql2 := wk_sql2 || '       AND     itp.line_id            = gmd.material_detail_id  ';
        wk_sql2 := wk_sql2 || '       AND     itp.item_id            = gmd.item_id ';
        wk_sql2 := wk_sql2 || '       AND     itp.lot_id             = mld.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     itp.completed_ind      = 0) ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    po_lines_all          pla ';
        wk_sql2 := wk_sql2 || '              ,po_headers_all        pha ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details mld ';
        wk_sql2 := wk_sql2 || '       WHERE   pla.item_id            = ' || lt_inv_item_id ;
        wk_sql2 := wk_sql2 || '       AND     pla.attribute13        = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     pla.cancel_flag        = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     pla.attribute12        = enable_lot.storehouse_code ';
        wk_sql2 := wk_sql2 || '       AND     pla.po_header_id       = pha.po_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql2 := wk_sql2 || '       AND     pha.org_id             = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql2 := wk_sql2 || '       AND     pha.attribute1         IN (''20'', ''25'') ';
        wk_sql2 := wk_sql2 || '       AND     pha.attribute4        <= TO_CHAR(TO_DATE(''' || id_material_date || '''), ''YYYY/MM/DD'') ';
        wk_sql2 := wk_sql2 || '       AND     pla.po_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id             = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code = ''50''  ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code   = ''10'') ';
        wk_sql2 := wk_sql2 || '      )                                     outbound_qty             '; -- 出庫予定数
-- 2009/02/02 D.Nihei ADD START
-- 入庫予定SQL(総引当ベース)
        wk_sql2 := wk_sql2 || '    ,( ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(pla.quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    po_lines_all       pla ';
        wk_sql2 := wk_sql2 || '              ,po_headers_all     pha ';
        wk_sql2 := wk_sql2 || '       WHERE   pla.item_id      = ' || lt_inv_item_id ;
        wk_sql2 := wk_sql2 || '       AND     pla.attribute1   = ilm.lot_no ';
        wk_sql2 := wk_sql2 || '       AND     pla.attribute13  = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     pla.cancel_flag  = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     pla.po_header_id = pha.po_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql2 := wk_sql2 || '       AND     pha.org_id       = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql2 := wk_sql2 || '       AND     pha.attribute1   IN (''20'', ''25'') ';
        wk_sql2 := wk_sql2 || '       AND     pha.attribute5   = enable_lot.storehouse_code ';
        wk_sql2 := wk_sql2 || '       AND     pha.attribute4  <= TO_CHAR(TO_DATE(''' || ld_max_date || '''), ''YYYY/MM/DD'')) ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.ship_to_locat_id       = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg        = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status                 IN (''02'', ''03'') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.schedule_arrival_date <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id            = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg             = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id                 = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id                  = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code      = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code        = ''10'') ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.ship_to_locat_id       = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg        = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status                 = ''04'' ';
        wk_sql2 := wk_sql2 || '       AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id            = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg             = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id                 = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id                  = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code      = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code        = ''20'') ';
        wk_sql2 := wk_sql2 || '       + ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '      (SELECT  /*+ leading(grb) use_nl(grb gbh gmd mld itp) index(gmd gme_material_details_n1) index(mld xxinv_mld_n03) index(itp ic_tran_pndi3) */ ';
        wk_sql2 := wk_sql2 || '               NVL(SUM(mld.actual_quantity), 0) ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql2 := wk_sql2 || '       FROM    gme_batch_header      gbh ';
        wk_sql2 := wk_sql2 || '              ,gme_material_details  gmd ';
        wk_sql2 := wk_sql2 || '              ,ic_tran_pnd           itp ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details mld ';
        wk_sql2 := wk_sql2 || '              ,gmd_routings_b        grb ';
        wk_sql2 := wk_sql2 || '       WHERE   gbh.batch_status       IN (1, 2) ';
        wk_sql2 := wk_sql2 || '       AND     gbh.plan_start_date   <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     gbh.batch_id           = gmd.batch_id ';
        wk_sql2 := wk_sql2 || '       AND     gmd.line_type          IN (1,2) ';
        wk_sql2 := wk_sql2 || '       AND     gmd.item_id            = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     gmd.material_detail_id = itp.line_id ';
        wk_sql2 := wk_sql2 || '       AND     itp.completed_ind      = 0 ';
        wk_sql2 := wk_sql2 || '       AND     itp.doc_type           = ''PROD'' ';
        wk_sql2 := wk_sql2 || '       AND     itp.lot_id             = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     itp.delete_mark        = 0 ';
        wk_sql2 := wk_sql2 || '       AND     gmd.material_detail_id = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code = ''40'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code   = ''10'' ';
        wk_sql2 := wk_sql2 || '       AND     gbh.routing_id         = grb.routing_id ';
        wk_sql2 := wk_sql2 || '       AND     grb.attribute9         = enable_lot.storehouse_code) ';
        wk_sql2 := wk_sql2 || '      )                                     inbound_qty_all '; -- 入庫予定数
-- 出庫予定SQL(総引当ベース)
        wk_sql2 := wk_sql2 || '    ,( ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.shipped_locat_id    = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg     = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status              IN (''02'', ''03'') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.schedule_ship_date <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id          = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg          = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id              = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id               = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code   = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code     = ''10'') ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxinv_mov_req_instr_headers mrih ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_req_instr_lines   mril ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details       mld  ';
        wk_sql2 := wk_sql2 || '       WHERE   mrih.shipped_locat_id   = enable_lot.inventory_location_id ';
        wk_sql2 := wk_sql2 || '       AND     mrih.comp_actual_flg    = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.status             = ''05'' ';
        wk_sql2 := wk_sql2 || '       AND     mrih.schedule_ship_date  <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mril.delete_flg         = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id             = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id              = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code  = ''20'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code    = ''30'') ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql2 := wk_sql2 || '              ,xxwsh_order_lines_all      ola ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details      mld ';
        wk_sql2 := wk_sql2 || '              ,oe_transaction_types_all   otta ';
        wk_sql2 := wk_sql2 || '       WHERE   oha.deliver_from_id       = enable_lot.inventory_location_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql2 := wk_sql2 || '       AND     otta.org_id               = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql2 := wk_sql2 || '       AND     oha.req_status            = ''03'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.schedule_ship_date   <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id               = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id                = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code    = ''10'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code      = ''10'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.attribute1           = ''1'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.transaction_type_id  = oha.order_type_id) ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    xxwsh_order_headers_all    oha ';
        wk_sql2 := wk_sql2 || '              ,xxwsh_order_lines_all      ola ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details      mld ';
        wk_sql2 := wk_sql2 || '              ,oe_transaction_types_all  otta ';
        wk_sql2 := wk_sql2 || '       WHERE   oha.deliver_from_id       = enable_lot.inventory_location_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql2 := wk_sql2 || '       AND     otta.org_id               = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql2 := wk_sql2 || '       AND     oha.req_status            = ''07'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql2 := wk_sql2 || '       AND     oha.schedule_ship_date   <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     oha.order_header_id       = ola.order_header_id ';
        wk_sql2 := wk_sql2 || '       AND     ola.delete_flag           = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.item_id               = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id                = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code    = ''30'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code      = ''10'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.attribute1           = ''2'' ';
        wk_sql2 := wk_sql2 || '       AND     otta.transaction_type_id  = oha.order_type_id) ';
        wk_sql2 := wk_sql2 || '       + ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '      (SELECT  /*+ leading(grb) use_nl(grb gbh gmd mld itp) index(gmd gme_material_details_n1) index(mld xxinv_mld_n03) index(itp ic_tran_pndi3) */ ';
        wk_sql2 := wk_sql2 || '               NVL(SUM(mld.actual_quantity), 0) ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql2 := wk_sql2 || '       FROM    gme_batch_header      gbh ';
        wk_sql2 := wk_sql2 || '              ,gme_material_details  gmd ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details mld ';
        wk_sql2 := wk_sql2 || '              ,gmd_routings_b        grb ';
        wk_sql2 := wk_sql2 || '              ,ic_tran_pnd           itp ';
        wk_sql2 := wk_sql2 || '       WHERE   gbh.batch_status      IN (1, 2) ';
        wk_sql2 := wk_sql2 || '       AND     gbh.plan_start_date   <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql2 := wk_sql2 || '       AND     gbh.batch_id           = gmd.batch_id ';
        wk_sql2 := wk_sql2 || '       AND     gmd.line_type          = -1 ';
        wk_sql2 := wk_sql2 || '       AND     gmd.item_id            = ilm.item_id ';
        wk_sql2 := wk_sql2 || '       AND     gmd.material_detail_id = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id             = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     gbh.routing_id         = grb.routing_id ';
        wk_sql2 := wk_sql2 || '       AND     grb.attribute9         = enable_lot.storehouse_code ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code = ''40'' ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code   = ''10'' ';
        wk_sql2 := wk_sql2 || '       AND     itp.doc_type           = ''PROD'' ';
        wk_sql2 := wk_sql2 || '       AND     itp.delete_mark        = 0 ';
        wk_sql2 := wk_sql2 || '       AND     itp.line_id            = gmd.material_detail_id  ';
        wk_sql2 := wk_sql2 || '       AND     itp.item_id            = gmd.item_id ';
        wk_sql2 := wk_sql2 || '       AND     itp.lot_id             = mld.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     itp.completed_ind      = 0) ';
        wk_sql2 := wk_sql2 || '       + ';
        wk_sql2 := wk_sql2 || '      (SELECT  NVL(SUM(mld.actual_quantity), 0) ';
        wk_sql2 := wk_sql2 || '       FROM    po_lines_all          pla ';
        wk_sql2 := wk_sql2 || '              ,po_headers_all        pha ';
        wk_sql2 := wk_sql2 || '              ,xxinv_mov_lot_details mld ';
        wk_sql2 := wk_sql2 || '       WHERE   pla.item_id            = ' || lt_inv_item_id ;
        wk_sql2 := wk_sql2 || '       AND     pla.attribute13        = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     pla.cancel_flag        = ''N'' ';
        wk_sql2 := wk_sql2 || '       AND     pla.attribute12        = enable_lot.storehouse_code ';
        wk_sql2 := wk_sql2 || '       AND     pla.po_header_id       = pha.po_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql2 := wk_sql2 || '       AND     pha.org_id             = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql2 := wk_sql2 || '       AND     pha.attribute1         IN (''20'', ''25'') ';
        wk_sql2 := wk_sql2 || '       AND     pha.attribute4        <= TO_CHAR(TO_DATE(''' || ld_max_date || '''), ''YYYY/MM/DD'') ';
        wk_sql2 := wk_sql2 || '       AND     pla.po_line_id         = mld.mov_line_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.lot_id             = ilm.lot_id ';
        wk_sql2 := wk_sql2 || '       AND     mld.document_type_code = ''50''  ';
        wk_sql2 := wk_sql2 || '       AND     mld.record_type_code   = ''10'') ';
        wk_sql2 := wk_sql2 || '      )                                     outbound_qty_all '; -- 出庫予定数
-- 2009/02/02 D.Nihei ADD END
      END IF;
      wk_sql2 := wk_sql2 || '      , 0                                     enabled_qty              '; -- 可能数
      wk_sql3 := wk_sql3 || '      , TO_NUMBER( DECODE( ilm.attribute6, ''0'', NULL, ilm.attribute6 ))';
      wk_sql3 := wk_sql3 || '                                              entity_inner             '; -- 在庫入数
      wk_sql3 := wk_sql3 || '      , TO_NUMBER( ilm.attribute7 )           unit_price               '; -- 単価
      wk_sql3 := wk_sql3 || '      , ilm.attribute8                        orgn_code                '; -- 取引先コード
      wk_sql3 := wk_sql3 || '      , (SELECT xvv.vendor_short_name ';
      wk_sql3 := wk_sql3 || '         FROM   xxcmn_vendors2_v xvv  ';  -- 仕入先情報VIEW
      wk_sql3 := wk_sql3 || '         WHERE  xvv.segment1           = ilm.attribute8 ';
      wk_sql3 := wk_sql3 || '         AND    xvv.start_date_active <= trunc( TO_DATE(''' || id_material_date || ''')) ';
      wk_sql3 := wk_sql3 || '         AND    xvv.end_date_active   >= trunc( TO_DATE(''' || id_material_date || ''')) ';
-- 2009/02/18 N.Yoshida ADD START
      wk_sql3 := wk_sql3 || '         AND    xvv.inactive_date IS NULL ';
-- 2009/02/18 N.Yoshida ADD END
      wk_sql3 := wk_sql3 || '        )                                     orgn_name                '; -- 取引先名称
      wk_sql3 := wk_sql3 || '      , (SELECT xlvv_l05.meaning ';
      wk_sql3 := wk_sql3 || '         FROM   xxcmn_lookup_values_v xlvv_l05 ';
      wk_sql3 := wk_sql3 || '         WHERE  xlvv_l05.lookup_code = ilm.attribute9  ';
      wk_sql3 := wk_sql3 || '         AND    xlvv_l05.lookup_type = ''XXCMN_L05''   ';
      wk_sql3 := wk_sql3 || '        )                                     stocking_form            '; -- 仕入形態
      wk_sql3 := wk_sql3 || '      , (SELECT xlvv_l06.meaning ';
      wk_sql3 := wk_sql3 || '         FROM   xxcmn_lookup_values_v xlvv_l06 ';
      wk_sql3 := wk_sql3 || '         WHERE  xlvv_l06.lookup_code = ilm.attribute10 ';
      wk_sql3 := wk_sql3 || '         AND    xlvv_l06.lookup_type = ''XXCMN_L06''   ';
      wk_sql3 := wk_sql3 || '        )                                     tea_season_type          '; -- 茶期区分
      wk_sql3 := wk_sql3 || '      , ilm.attribute11                       period_of_year           '; -- 年度
      wk_sql3 := wk_sql3 || '      , (SELECT xlvv_l07.meaning ';
      wk_sql3 := wk_sql3 || '         FROM   xxcmn_lookup_values_v xlvv_l07 ';
      wk_sql3 := wk_sql3 || '         WHERE  xlvv_l07.lookup_code = ilm.attribute12 ';
      wk_sql3 := wk_sql3 || '         AND    xlvv_l07.lookup_type = ''XXCMN_L07''   ';
      wk_sql3 := wk_sql3 || '        )                                     producing_area           '; -- 産地
      wk_sql3 := wk_sql3 || '      , (SELECT xlvv_l08.meaning ';
      wk_sql3 := wk_sql3 || '         FROM   xxcmn_lookup_values_v xlvv_l08  ';
      wk_sql3 := wk_sql3 || '         WHERE  xlvv_l08.lookup_code = ilm.attribute13 ';
      wk_sql3 := wk_sql3 || '         AND    xlvv_l08.lookup_type = ''XXCMN_L08''   ';
      wk_sql3 := wk_sql3 || '        )                                     package_type             '; -- タイプ
      wk_sql3 := wk_sql3 || '      , ilm.attribute14                       rank1                    '; -- R1
      wk_sql3 := wk_sql3 || '      , ilm.attribute15                       rank2                    '; -- R2
      wk_sql3 := wk_sql3 || '      , ilm.attribute19                       rank3                    '; -- R3
      wk_sql3 := wk_sql3 || '      , ilm.attribute1                        maker_date               '; -- 製造日
      wk_sql3 := wk_sql3 || '      , ilm.attribute3                        use_by_date              '; -- 賞味期限日
      wk_sql3 := wk_sql3 || '      , ilm.attribute2                        unique_sign              '; -- 固有記号
      wk_sql3 := wk_sql3 || '      , ilm.attribute4                        dely_date                '; -- 納入日（初回）
      wk_sql3 := wk_sql3 || '      , (SELECT xlvv_l03.meaning ';
      wk_sql3 := wk_sql3 || '         FROM   xxcmn_lookup_values_v xlvv_l03  ';
      wk_sql3 := wk_sql3 || '         WHERE  xlvv_l03.lookup_code = ilm.attribute16 ';
      wk_sql3 := wk_sql3 || '         AND    xlvv_l03.lookup_type = ''XXCMN_L03''   ';
      wk_sql3 := wk_sql3 || '        )                                     slip_type_name           '; -- 伝票区分(名称)
      wk_sql3 := wk_sql3 || '      , ilm.attribute17                       routing_no               '; -- ラインNo
      wk_sql3 := wk_sql3 || '      , (SELECT grv.attribute1     ';
      wk_sql3 := wk_sql3 || '         FROM   gmd_routings_b grv '; -- 工順マスタVIEW
      wk_sql3 := wk_sql3 || '         WHERE  grv.routing_no = ilm.attribute17 ';
      wk_sql3 := wk_sql3 || '        )                                     routing_name             '; -- ライン名称
      wk_sql3 := wk_sql3 || '      , ilm.attribute18                       remarks_column           '; -- 摘要
      wk_sql3 := wk_sql3 || '      , enable_lot.record_type                record_type              ';
      wk_sql3 := wk_sql3 || '      , ilm.created_by                        created_by               ';
      wk_sql3 := wk_sql3 || '      , ilm.creation_date                     creation_date            ';
      wk_sql3 := wk_sql3 || '      , ilm.last_updated_by                   last_updated_by          ';
      wk_sql3 := wk_sql3 || '      , ilm.last_update_date                  last_update_date         ';
      wk_sql3 := wk_sql3 || '      , ilm.last_update_login                 last_update_login        ';
      wk_sql3 := wk_sql3 || '      , enable_lot.xmd_last_update_date       xmd_last_update_date     ';
      wk_sql3 := wk_sql3 || '      , NVL(enable_lot.whse_inside_outside_div, ''2'')  ';
      wk_sql3 := wk_sql3 || '                                              whse_inside_outside_div  '; -- 内外倉庫区分
      wk_sql3 := wk_sql3 || '      FROM ';
      wk_sql3 := wk_sql3 || '        ic_lots_mst ilm '; -- OPMロット
      wk_sql3 := wk_sql3 || '      , ( SELECT 1                               record_type             ';       -- 更新
      wk_sql3 := wk_sql3 || '               , xmd.mtl_detail_addon_id         mtl_detail_addon_id     ';       -- 生産原料詳細アドオンID
      wk_sql3 := wk_sql3 || '               , xmd.item_id                     item_id                 ';       -- 品目ID
      wk_sql3 := wk_sql3 || '               , xmd.lot_id                      lot_id                  ';       -- ロットID
      wk_sql3 := wk_sql3 || '               , xmd.location_code               storehouse_code         ';       -- 保管場所コード
      wk_sql3 := wk_sql3 || '               , xmd.instructions_qty            instructions_qty        ';       -- 指示総数
      wk_sql3 := wk_sql3 || '               , xmd.last_update_date            xmd_last_update_date     '; -- 最終更新日(排他制御用)
      wk_sql3 := wk_sql3 || '               , xmld.mov_lot_dtl_id             mov_lot_dtl_id           '; -- 移動ロット詳細ID
      wk_sql3 := wk_sql3 || '               , xilv.inventory_location_id      inventory_location_id    '; -- 保管倉庫ID
      wk_sql3 := wk_sql3 || '               , xilv.description                description              '; -- 保管倉庫(名称)
      wk_sql3 := wk_sql3 || '               , xilv.whse_inside_outside_div    whse_inside_outside_div  '; -- 内外倉庫区分
      wk_sql3 := wk_sql3 || '          FROM   xxwip_material_detail           xmd  '; -- 生産原料詳細アドオン
      wk_sql3 := wk_sql3 || '               , xxinv_mov_lot_details           xmld '; -- 移動ロット詳細
      wk_sql3 := wk_sql3 || '               , xxcmn_item_locations_v          xilv '; -- 保管倉庫
      wk_sql3 := wk_sql3 || '          WHERE  xmd.material_detail_id  = ' || in_material_detail_id;
      wk_sql3 := wk_sql3 || '          AND    xmd.plan_type           IN ( ''1'', ''2'', ''3'' )     ';
      wk_sql3 := wk_sql3 || '          AND    xilv.segment1           = xmd.location_code ';
      wk_sql3 := wk_sql3 || '          AND    xmld.mov_line_id(+)     = xmd.mtl_detail_addon_id ';
      wk_sql3 := wk_sql3 || '          AND    xmld.lot_id(+)          = xmd.lot_id ';
      wk_sql3 := wk_sql3 || '          UNION ALL ';
      wk_sql3 := wk_sql3 || '          SELECT 0                               record_type               '; -- 挿入
      wk_sql3 := wk_sql3 || '               , NULL                            mtl_detail_addon_id       '; -- 生産原料詳細アドオンID
      wk_sql3 := wk_sql3 || '               , lot.item_id                     item_id                   '; -- 品目ID
      wk_sql3 := wk_sql3 || '               , lot.lot_id                      lot_id                    '; -- ロットID
      wk_sql3 := wk_sql3 || '               , xilv.segment1                   storehouse_code           '; -- 保管場所コード
      wk_sql3 := wk_sql3 || '               , NULL                            instructions_qty          '; -- 指示総数
      wk_sql3 := wk_sql3 || '               , NULL                            xmd_last_update_date      '; -- 最終更新日(排他制御用)
      wk_sql3 := wk_sql3 || '               , NULL                            mov_lot_dtl_id            '; -- 移動ロット詳細ID
      wk_sql3 := wk_sql3 || '               , xilv.inventory_location_id      inventory_location_id     '; -- 保管倉庫ID
      wk_sql3 := wk_sql3 || '               , xilv.description                description               '; -- 保管倉庫(名称)
      wk_sql3 := wk_sql3 || '               , xilv.whse_inside_outside_div    whse_inside_outside_div   '; -- 内外倉庫区分
      wk_sql3 := wk_sql3 || '          FROM   xxcmn_item_locations_v xilv ';   -- 保管倉庫
      wk_sql3 := wk_sql3 || '               , ( ';
      --==========================
      -- 資材
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
        wk_sql3 := wk_sql3 || '                 SELECT mil.inventory_location_id location_id ';
        wk_sql3 := wk_sql3 || '                      , ili.item_id               item_id ';
        wk_sql3 := wk_sql3 || '                      , ili.lot_id                lot_id ';
        wk_sql3 := wk_sql3 || '                 FROM   mtl_item_locations  mil ';
        wk_sql3 := wk_sql3 || '                      , ic_whse_mst         iwm ';
        wk_sql3 := wk_sql3 || '                      , ic_loct_inv         ili ';
        wk_sql3 := wk_sql3 || '                 WHERE  ili.item_id               = ' || lt_item_id;
        wk_sql3 := wk_sql3 || '                 AND    mil.segment1              = ili.location ';
        wk_sql3 := wk_sql3 || '                 AND    mil.organization_id       = iwm.mtl_organization_id ';
        wk_sql3 := wk_sql3 || '                 AND    ili.loct_onhand           > 0 ';
        wk_sql3 := wk_sql3 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql3 := wk_sql3 || '                 SELECT mrih.ship_to_locat_id       location_id ';
        wk_sql3 := wk_sql3 || '                 SELECT /*+ leading(mrih) index(mrih xxinv_mrih_sales_n01) use_nl(mril) */ ';
        wk_sql3 := wk_sql3 || '                        mrih.ship_to_locat_id       location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql3 := wk_sql3 || '                      , mril.item_id                item_id ';
        wk_sql3 := wk_sql3 || '                      , 0                           lot_id ';
        wk_sql3 := wk_sql3 || '                 FROM   xxinv_mov_req_instr_headers mrih ';
        wk_sql3 := wk_sql3 || '                      , xxinv_mov_req_instr_lines   mril ';
        wk_sql3 := wk_sql3 || '                 WHERE  mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql3 := wk_sql3 || '                 AND    mril.item_id            = ' || lt_item_id;
        wk_sql3 := wk_sql3 || '                 AND    mrih.status             IN (''05'',''06'') ';
        wk_sql3 := wk_sql3 || '                 AND    mrih.comp_actual_flg    = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    mril.delete_flg         = ''N'' ';
        wk_sql3 := wk_sql3 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql3 := wk_sql3 || '                 SELECT mrih.shipped_locat_id       location_id ';
        wk_sql3 := wk_sql3 || '                 SELECT /*+ leading(mrih) index(mrih xxinv_mrih_sales_n01) use_nl(mril) */ ';
        wk_sql3 := wk_sql3 || '                        mrih.shipped_locat_id       location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql3 := wk_sql3 || '                      , mril.item_id                item_id ';
        wk_sql3 := wk_sql3 || '                      , 0                           lot_id ';
        wk_sql3 := wk_sql3 || '                 FROM   xxinv_mov_req_instr_headers mrih ';
        wk_sql3 := wk_sql3 || '                      , xxinv_mov_req_instr_lines   mril ';
        wk_sql3 := wk_sql3 || '                 WHERE  mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql3 := wk_sql3 || '                 AND    mril.item_id            = ' || lt_item_id;
        wk_sql3 := wk_sql3 || '                 AND    mrih.status             IN (''04'',''06'') ';
        wk_sql3 := wk_sql3 || '                 AND    mrih.comp_actual_flg    = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    mril.delete_flg         = ''N'' ';
        wk_sql3 := wk_sql3 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql3 := wk_sql3 || '                 SELECT /*+ index(MLD XXINV_MLD_N99) */ oha.deliver_from_id  location_id ';
        wk_sql3 := wk_sql3 || '                 SELECT oha.deliver_from_id  location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql3 := wk_sql3 || '                      , ' || lt_item_id || ' item_id ';
        wk_sql3 := wk_sql3 || '                      , 0                    lot_id ';
        wk_sql3 := wk_sql3 || '                 FROM   xxwsh_order_headers_all    oha ';
        wk_sql3 := wk_sql3 || '                      , xxwsh_order_lines_all      ola ';
        wk_sql3 := wk_sql3 || '                      , oe_transaction_types_all   otta ';
        wk_sql3 := wk_sql3 || '                 WHERE  oha.order_header_id            = ola.order_header_id ';
        wk_sql3 := wk_sql3 || '                 AND    otta.transaction_type_id       = oha.order_type_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql3 := wk_sql3 || '                 AND    otta.org_id                    = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql3 := wk_sql3 || '                 AND    ola.shipping_inventory_item_id = ' || lt_inv_item_id;
        wk_sql3 := wk_sql3 || '                 AND    otta.attribute1                IN (''1'',''3'') ';
        wk_sql3 := wk_sql3 || '                 AND    oha.req_status                 = ''04'' ';
        wk_sql3 := wk_sql3 || '                 AND    oha.actual_confirm_class       = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    oha.latest_external_flag       = ''Y'' ';
        wk_sql3 := wk_sql3 || '                 AND    ola.delete_flag                = ''N'' ';
        wk_sql3 := wk_sql3 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql3 := wk_sql3 || '                 SELECT /* index(MLD XXINV_MLD_N99) */ oha.deliver_from_id  location_id ';
        wk_sql3 := wk_sql3 || '                 SELECT oha.deliver_from_id  location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql3 := wk_sql3 || '                      , ' || lt_item_id || ' item_id ';
        wk_sql3 := wk_sql3 || '                      , 0                    lot_id ';
        wk_sql3 := wk_sql3 || '                 FROM   xxwsh_order_headers_all    oha ';
        wk_sql3 := wk_sql3 || '                      , xxwsh_order_lines_all      ola ';
        wk_sql3 := wk_sql3 || '                      , oe_transaction_types_all   otta ';
        wk_sql3 := wk_sql3 || '                 WHERE  oha.order_header_id            = ola.order_header_id ';
        wk_sql3 := wk_sql3 || '                 AND    otta.transaction_type_id       = oha.order_type_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql3 := wk_sql3 || '                 AND    otta.org_id                    = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql3 := wk_sql3 || '                 AND    ola.shipping_inventory_item_id = ' || lt_inv_item_id;
        wk_sql3 := wk_sql3 || '                 AND    oha.req_status                 = ''08'' ';
        wk_sql3 := wk_sql3 || '                 AND    oha.actual_confirm_class       = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    oha.latest_external_flag       = ''Y'' ';
        wk_sql3 := wk_sql3 || '                 AND    ola.delete_flag                = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    otta.attribute1                = ''2'' ';
        wk_sql3 := wk_sql3 || '                 UNION ';
        wk_sql3 := wk_sql3 || '                 SELECT mil.inventory_location_id   location_id ';
        wk_sql3 := wk_sql3 || '                      , ' || lt_item_id || '        item_id ';
        wk_sql3 := wk_sql3 || '                      , 0                           lot_id ';
        wk_sql3 := wk_sql3 || '                 FROM   po_lines_all       pla ';
        wk_sql3 := wk_sql3 || '                      , po_headers_all     pha ';
        wk_sql3 := wk_sql3 || '                      , mtl_item_locations mil ';
        wk_sql3 := wk_sql3 || '                 WHERE  pla.po_header_id = pha.po_header_id ';
        wk_sql3 := wk_sql3 || '                 AND    pha.attribute5   = mil.segment1 ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql3 := wk_sql3 || '                 AND    pha.org_id       = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql3 := wk_sql3 || '                 AND    pla.item_id      = ' || lt_inv_item_id;
        wk_sql3 := wk_sql3 || '                 AND    pla.attribute13  = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    pha.attribute1   IN (''20'',''25'') ';
        wk_sql3 := wk_sql3 || '                 AND    pha.attribute4  <= TO_CHAR(TO_DATE(''' || ld_max_date || '''), ''YYYY/MM/DD'')  ';
        wk_sql3 := wk_sql3 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql3 := wk_sql3 || '                 SELECT mrih.ship_to_locat_id       location_id ';
        wk_sql3 := wk_sql3 || '                 SELECT /*+ leading(mrih) index(mrih xxinv_mrih_sales_n01) use_nl(mril) */ ';
        wk_sql3 := wk_sql3 || '                        mrih.ship_to_locat_id       location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql3 := wk_sql3 || '                      , mril.item_id                item_id ';
        wk_sql3 := wk_sql3 || '                      , 0                           lot_id ';
        wk_sql3 := wk_sql3 || '                 FROM   xxinv_mov_req_instr_headers mrih ';
        wk_sql3 := wk_sql3 || '                      , xxinv_mov_req_instr_lines   mril ';
        wk_sql3 := wk_sql3 || '                 WHERE  mrih.comp_actual_flg        = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    mrih.status                 IN (''02'',''03'',''04'') ';
        wk_sql3 := wk_sql3 || '                 AND    mrih.schedule_arrival_date <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql3 := wk_sql3 || '                 AND    mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql3 := wk_sql3 || '                 AND    mril.delete_flg             = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    mril.item_id                = ' || lt_item_id;
        wk_sql3 := wk_sql3 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql3 := wk_sql3 || '                 SELECT mrih.shipped_locat_id       location_id ';
        wk_sql3 := wk_sql3 || '                 SELECT /*+ leading(mrih) index(mrih xxinv_mrih_sales_n01) use_nl(mril) */ ';
        wk_sql3 := wk_sql3 || '                        mrih.shipped_locat_id       location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql3 := wk_sql3 || '                      , mril.item_id                item_id ';
        wk_sql3 := wk_sql3 || '                      , 0                           lot_id ';
        wk_sql3 := wk_sql3 || '                 FROM   xxinv_mov_req_instr_headers mrih ';
        wk_sql3 := wk_sql3 || '                      , xxinv_mov_req_instr_lines   mril ';
        wk_sql3 := wk_sql3 || '                 WHERE  mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql3 := wk_sql3 || '                 AND    mril.item_id                = ' || lt_item_id;
        wk_sql3 := wk_sql3 || '                 AND    mrih.schedule_arrival_date <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql3 := wk_sql3 || '                 AND    mrih.comp_actual_flg        = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    mril.delete_flg             = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    mrih.status                 IN (''02'',''03'',''05'') ';
        wk_sql3 := wk_sql3 || '                 UNION ';
        wk_sql3 := wk_sql3 || '                 SELECT oha.deliver_from_id  location_id ';
        wk_sql3 := wk_sql3 || '                      , ' || lt_item_id || ' item_id ';
        wk_sql3 := wk_sql3 || '                      , 0                    lot_id ';
        wk_sql3 := wk_sql3 || '                 FROM   xxwsh_order_headers_all    oha ';
        wk_sql3 := wk_sql3 || '                      , xxwsh_order_lines_all      ola ';
        wk_sql3 := wk_sql3 || '                      , oe_transaction_types_all  otta ';
        wk_sql3 := wk_sql3 || '                 WHERE  ola.shipping_inventory_item_id = ' || lt_inv_item_id;
        wk_sql3 := wk_sql3 || '                 AND    otta.transaction_type_id       = oha.order_type_id ';
        wk_sql3 := wk_sql3 || '                 AND    oha.order_header_id            = ola.order_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql3 := wk_sql3 || '                 AND    otta.org_id                    = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql3 := wk_sql3 || '                 AND    oha.schedule_ship_date        <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql3 := wk_sql3 || '                 AND    oha.req_status                 = ''03'' ';
        wk_sql3 := wk_sql3 || '                 AND    oha.actual_confirm_class       = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    oha.latest_external_flag       = ''Y'' ';
        wk_sql3 := wk_sql3 || '                 AND    ola.delete_flag                = ''N'' ';
        wk_sql3 := wk_sql3 || '                 AND    otta.attribute1                = ''1'' ';
        wk_sql3 := wk_sql3 || '                 UNION ';
        wk_sql3 := wk_sql3 || '                 SELECT oha.deliver_from_id  location_id ';
        wk_sql3 := wk_sql3 || '                      , ' || lt_item_id || ' item_id ';
        wk_sql3 := wk_sql3 || '                      , 0                    lot_id ';
        wk_sql3 := wk_sql3 || '                 FROM   xxwsh_order_headers_all    oha ';
        wk_sql4 := wk_sql4 || '                      , xxwsh_order_lines_all      ola ';
        wk_sql4 := wk_sql4 || '                      , oe_transaction_types_all   otta ';
        wk_sql4 := wk_sql4 || '                 WHERE  ola.shipping_inventory_item_id = ' || lt_inv_item_id;
        wk_sql4 := wk_sql4 || '                 AND    otta.transaction_type_id       = oha.order_type_id ';
        wk_sql4 := wk_sql4 || '                 AND    oha.order_header_id            = ola.order_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql4 := wk_sql4 || '                 AND    otta.org_id                    = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql4 := wk_sql4 || '                 AND    oha.schedule_ship_date        <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql4 := wk_sql4 || '                 AND    oha.req_status                 = ''07'' ';
        wk_sql4 := wk_sql4 || '                 AND    oha.actual_confirm_class       = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND    oha.latest_external_flag       = ''Y'' ';
        wk_sql4 := wk_sql4 || '                 AND    ola.delete_flag                = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND    otta.attribute1                = ''2'' ';
        wk_sql4 := wk_sql4 || '                 UNION ';
        wk_sql4 := wk_sql4 || '                 SELECT mil.inventory_location_id   location_id ';
        wk_sql4 := wk_sql4 || '                      , gmd.item_id                 item_id ';
        wk_sql4 := wk_sql4 || '                      , 0                           lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM   gme_batch_header      gbh ';
        wk_sql4 := wk_sql4 || '                      , gme_material_details  gmd ';
        wk_sql4 := wk_sql4 || '                      , xxwip_material_detail xmd ';
        wk_sql4 := wk_sql4 || '                      , gmd_routings_b        grb ';
        wk_sql4 := wk_sql4 || '                      , mtl_item_locations    mil ';
        wk_sql4 := wk_sql4 || '                 WHERE  gbh.batch_status       IN (1, 2) ';
        wk_sql4 := wk_sql4 || '                 AND    gbh.plan_start_date   <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql4 := wk_sql4 || '                 AND    gbh.batch_id           = gmd.batch_id ';
        wk_sql4 := wk_sql4 || '                 AND    gmd.line_type          = -1 ';
        wk_sql4 := wk_sql4 || '                 AND    gmd.item_id            = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND    gmd.material_detail_id = xmd.material_detail_id ';
        wk_sql4 := wk_sql4 || '                 AND    xmd.plan_type          = ''4'' ';
        wk_sql4 := wk_sql4 || '                 AND    gbh.routing_id         = grb.routing_id ';
        wk_sql4 := wk_sql4 || '                 AND    grb.attribute9         = mil.segment1 ';
        wk_sql4 := wk_sql4 || '                 AND    xmd.invested_qty       = 0 ';
      --==========================
      -- 資材以外
      --==========================
      ELSE
        wk_sql4 := wk_sql4 || '                 SELECT mil.inventory_location_id location_id ';
        wk_sql4 := wk_sql4 || '                      , ili.item_id               item_id     ';
        wk_sql4 := wk_sql4 || '                      , ili.lot_id                lot_id      ';
        wk_sql4 := wk_sql4 || '                 FROM   mtl_item_locations        mil    ';
        wk_sql4 := wk_sql4 || '                      , ic_whse_mst               iwm    ';
        wk_sql4 := wk_sql4 || '                      , ic_loct_inv               ili    ';
        wk_sql4 := wk_sql4 || '                 WHERE ili.item_id            = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND   mil.segment1           = ili.location ';
        wk_sql4 := wk_sql4 || '                 AND   mil.organization_id    = iwm.mtl_organization_id ';
        wk_sql4 := wk_sql4 || '                 AND   ili.loct_onhand        > 0 ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  mrih.ship_to_locat_id       location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  /*+ leading(mrih) index(mrih xxinv_mrih_sales_n01) use_nl(mril mld) */ ';
        wk_sql4 := wk_sql4 || '                         mrih.ship_to_locat_id       location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , mld.item_id                 item_id     ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                  lot_id      ';
        wk_sql4 := wk_sql4 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql4 := wk_sql4 || '                 WHERE   mrih.comp_actual_flg   = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.status            IN (''05'', ''06'') ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.mov_hdr_id        = mril.mov_hdr_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.mov_line_id       = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.delete_flg        = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id            = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code = ''20'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code   = ''30'' ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  mrih.shipped_locat_id       location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  /*+ leading(mrih) index(mrih xxinv_mrih_sales_n01) use_nl(mril mld) */ ';
        wk_sql4 := wk_sql4 || '                         mrih.shipped_locat_id       location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , mld.item_id                 item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                  lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql4 := wk_sql4 || '                 WHERE   mrih.comp_actual_flg   = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.status            IN (''04'', ''06'') ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.mov_hdr_id        = mril.mov_hdr_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.mov_line_id       = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.delete_flg        = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id            = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code = ''20'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code   = ''20'' ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  /*+ index(MLD XXINV_MLD_N99) */ oha.deliver_from_id        location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  oha.deliver_from_id        location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , mld.item_id                item_id     ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                 lot_id      ';
        wk_sql4 := wk_sql4 || '                 FROM    xxwsh_order_headers_all    oha  ';
        wk_sql4 := wk_sql4 || '                       , xxwsh_order_lines_all      ola  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details      mld  ';
        wk_sql4 := wk_sql4 || '                       , oe_transaction_types_all   otta ';
        wk_sql4 := wk_sql4 || '                 WHERE   oha.req_status           = ''04'' ';
        wk_sql4 := wk_sql4 || '                 AND     oha.actual_confirm_class = ''N''  ';
        wk_sql4 := wk_sql4 || '                 AND     oha.latest_external_flag = ''Y''  ';
        wk_sql4 := wk_sql4 || '                 AND     oha.order_header_id      = ola.order_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql4 := wk_sql4 || '                 AND     otta.org_id              = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql4 := wk_sql4 || '                 AND     ola.delete_flag          = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     ola.order_line_id        = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id              = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code   = ''10'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code     = ''20'' ';
        wk_sql4 := wk_sql4 || '                 AND     otta.attribute1          IN (''1'', ''3'') ';
        wk_sql4 := wk_sql4 || '                 AND     otta.transaction_type_id = oha.order_type_id ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  /*+ index(MLD XXINV_MLD_N99) */ oha.deliver_from_id        location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  oha.deliver_from_id        location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , mld.item_id                item_id     ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                 lot_id      ';
        wk_sql4 := wk_sql4 || '                 FROM    xxwsh_order_headers_all    oha   ';
        wk_sql4 := wk_sql4 || '                       , xxwsh_order_lines_all      ola   ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details      mld   ';
        wk_sql4 := wk_sql4 || '                       , oe_transaction_types_all   otta  ';
        wk_sql4 := wk_sql4 || '                 WHERE   oha.req_status           = ''08'' ';
        wk_sql4 := wk_sql4 || '                 AND     oha.actual_confirm_class = ''N''  ';
        wk_sql4 := wk_sql4 || '                 AND     oha.latest_external_flag = ''Y''  ';
        wk_sql4 := wk_sql4 || '                 AND     oha.order_header_id      = ola.order_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql4 := wk_sql4 || '                 AND     otta.org_id              = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql4 := wk_sql4 || '                 AND     ola.delete_flag          = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     ola.order_line_id        = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id              = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code   = ''30'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code     = ''20'' ';
        wk_sql4 := wk_sql4 || '                 AND     otta.attribute1          = ''2'' ';
        wk_sql4 := wk_sql4 || '                 AND     otta.transaction_type_id = oha.order_type_id ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  mil.inventory_location_id  location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  /*+ leading(pha) index(pha po_pha_n03) use_nl(pha pla ilm mil) */ ';
        wk_sql4 := wk_sql4 || '                         mil.inventory_location_id  location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , ilm.item_id                item_id     ';
        wk_sql4 := wk_sql4 || '                       , ilm.lot_id                 lot_id      ';
        wk_sql4 := wk_sql4 || '                 FROM    po_lines_all               pla  ';
        wk_sql4 := wk_sql4 || '                       , po_headers_all             pha  ';
        wk_sql4 := wk_sql4 || '                       , mtl_item_locations         mil  ';
        wk_sql4 := wk_sql4 || '                       , ic_lots_mst                ilm  ';
        wk_sql4 := wk_sql4 || '                 WHERE   pla.item_id       = ' || lt_inv_item_id;
        wk_sql4 := wk_sql4 || '                 AND     pla.attribute1    = ilm.lot_no ';
        wk_sql4 := wk_sql4 || '                 AND     ilm.item_id       = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     pla.attribute13   = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     pla.cancel_flag   = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     pla.po_header_id  = pha.po_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql4 := wk_sql4 || '                 AND     pha.org_id        = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql4 := wk_sql4 || '                 AND     pha.attribute1    IN (''20'', ''25'') ';
        wk_sql4 := wk_sql4 || '                 AND     pha.attribute5    = mil.segment1 ';
        wk_sql4 := wk_sql4 || '                 AND     pha.attribute4   <= TO_CHAR(TO_DATE(''' || ld_max_date || '''), ''YYYY/MM/DD'') ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  mrih.ship_to_locat_id       location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  /*+ leading(mrih) index(mrih xxinv_mrih_sales_n01) use_nl(mril mld) */ ';
        wk_sql4 := wk_sql4 || '                         mrih.ship_to_locat_id       location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , mld.item_id                 item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                  lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql4 := wk_sql4 || '                 WHERE   mrih.comp_actual_flg        = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.status                 IN (''02'', ''03'') ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.schedule_arrival_date <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.mov_line_id            = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.delete_flg             = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id                 = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code      = ''20'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code        = ''10'' ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  mrih.ship_to_locat_id       location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  /*+ leading(mrih) index(mrih xxinv_mrih_sales_n01) use_nl(mril mld) */ ';
        wk_sql4 := wk_sql4 || '                         mrih.ship_to_locat_id       location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , mld.item_id                 item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                  lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql4 := wk_sql4 || '                 WHERE   mrih.comp_actual_flg        = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.status                 = ''04'' ';
-- 2008/12/19 D.Nihei MOD START
--        wk_sql2 := wk_sql2 || '                 AND     mrih.schedule_ship_date <= TO_DATE(''' || id_material_date || ''') ';
        wk_sql4 := wk_sql4 || '                 AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= TO_DATE(''' || ld_max_date || ''') ';
-- 2008/12/19 D.Nihei MOD END
        wk_sql4 := wk_sql4 || '                 AND     mrih.mov_hdr_id             = mril.mov_hdr_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.mov_line_id            = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.delete_flg             = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id                 = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code      = ''20'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code        = ''20'' ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  /*+ use_nl(gmd mld gbh grb itp mil) */ mil.inventory_location_id location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  /*+ leading(gmd gbh grb mil mld itp) use_nl(grb mil) index(itp ic_tran_pndi3) */ ';
        wk_sql4 := wk_sql4 || '                         mil.inventory_location_id location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , gmd.item_id                item_id ';
        wk_sql4 := wk_sql4 || '                       , itp.lot_id                 lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    gme_batch_header           gbh  ';
        wk_sql4 := wk_sql4 || '                       , gme_material_details       gmd  ';
        wk_sql4 := wk_sql4 || '                       , ic_tran_pnd                itp  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details      mld  ';
        wk_sql4 := wk_sql4 || '                       , gmd_routings_b             grb  ';
        wk_sql4 := wk_sql4 || '                       , mtl_item_locations         mil  ';
        wk_sql4 := wk_sql4 || '                 WHERE   gbh.batch_status       IN (1, 2) ';
        wk_sql4 := wk_sql4 || '                 AND     gbh.plan_start_date   <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql4 := wk_sql4 || '                 AND     gbh.batch_id           = gmd.batch_id ';
        wk_sql4 := wk_sql4 || '                 AND     gmd.line_type          IN (1, 2) ';
        wk_sql4 := wk_sql4 || '                 AND     gmd.line_type          = itp.line_type ';
        wk_sql4 := wk_sql4 || '                 AND     gmd.item_id            = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     gmd.material_detail_id = itp.line_id ';
        wk_sql4 := wk_sql4 || '                 AND     itp.completed_ind      = 0 ';
        wk_sql4 := wk_sql4 || '                 AND     itp.doc_type           = ''PROD'' ';
-- 2008/12/24 D.Nihei ADD START 本番障害#836
        wk_sql4 := wk_sql4 || '                 AND     itp.delete_mark        = 0 ';
-- 2008/12/24 D.Nihei ADD END
        wk_sql4 := wk_sql4 || '                 AND     gmd.material_detail_id = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code = ''40'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code   = ''10'' ';
        wk_sql4 := wk_sql4 || '                 AND     gbh.routing_id         = grb.routing_id ';
        wk_sql4 := wk_sql4 || '                 AND     grb.attribute9         = mil.segment1  ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  mrih.shipped_locat_id       location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  /*+ leading(mrih) index(mrih xxinv_mrih_sales_n01) use_nl(mril mld) */ ';
        wk_sql4 := wk_sql4 || '                         mrih.shipped_locat_id       location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , mld.item_id                 item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                  lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql4 := wk_sql4 || '                 WHERE   mrih.comp_actual_flg     = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.status              IN (''02'', ''03'') ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.schedule_ship_date <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.mov_hdr_id          = mril.mov_hdr_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.mov_line_id         = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.delete_flg          = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id              = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code   = ''20'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code     = ''10'' ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  mrih.shipped_locat_id       location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  /*+ leading(mrih) index(mrih xxinv_mrih_sales_n01) use_nl(mril mld) */ ';
        wk_sql4 := wk_sql4 || '                         mrih.shipped_locat_id       location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , mld.item_id                 item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                  lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql4 := wk_sql4 || '                 WHERE   mrih.comp_actual_flg     = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.status              = ''05'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.schedule_ship_date <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.mov_hdr_id          = mril.mov_hdr_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.mov_line_id         = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.delete_flg          = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id              = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code   = ''20'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code     = ''30'' ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  /*+ index(MLD XXINV_MLD_N99) */ oha.deliver_from_id        location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  oha.deliver_from_id        location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , mld.item_id                item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                 lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    xxwsh_order_headers_all    oha  ';
        wk_sql4 := wk_sql4 || '                       , xxwsh_order_lines_all      ola  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details      mld  ';
        wk_sql4 := wk_sql4 || '                       , oe_transaction_types_all   otta ';
        wk_sql4 := wk_sql4 || '                 WHERE   oha.req_status           = ''03'' ';
        wk_sql4 := wk_sql4 || '                 AND     oha.actual_confirm_class = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     oha.latest_external_flag = ''Y'' ';
        wk_sql4 := wk_sql4 || '                 AND     oha.schedule_ship_date  <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql4 := wk_sql4 || '                 AND     oha.order_header_id      = ola.order_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql4 := wk_sql4 || '                 AND     otta.org_id              = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql4 := wk_sql4 || '                 AND     ola.delete_flag          = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     ola.order_line_id        = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id              = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code   = ''10'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code     = ''10'' ';
        wk_sql4 := wk_sql4 || '                 AND     otta.attribute1          = ''1'' ';
        wk_sql4 := wk_sql4 || '                 AND     otta.transaction_type_id = oha.order_type_id ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  /*+ index(MLD XXINV_MLD_N99) */ oha.deliver_from_id      location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  oha.deliver_from_id      location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , mld.item_id              item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id               lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    xxwsh_order_headers_all  oha  ';
        wk_sql4 := wk_sql4 || '                       , xxwsh_order_lines_all    ola  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details    mld  ';
        wk_sql4 := wk_sql4 || '                       , oe_transaction_types_all otta ';
        wk_sql4 := wk_sql4 || '                 WHERE   oha.req_status            = ''07'' ';
        wk_sql4 := wk_sql4 || '                 AND     oha.actual_confirm_class  = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     oha.latest_external_flag  = ''Y'' ';
        wk_sql4 := wk_sql4 || '                 AND     oha.schedule_ship_date   <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql4 := wk_sql4 || '                 AND     oha.order_header_id       = ola.order_header_id ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql4 := wk_sql4 || '                 AND     otta.org_id              = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql4 := wk_sql4 || '                 AND     ola.delete_flag           = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     ola.order_line_id         = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id               = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code    = ''30'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code      = ''10'' ';
        wk_sql4 := wk_sql4 || '                 AND     otta.attribute1           = ''2'' ';
        wk_sql4 := wk_sql4 || '                 AND     otta.transaction_type_id  = oha.order_type_id ';
        wk_sql4 := wk_sql4 || '                 UNION ';
-- 2011/12/06 Mod Start Ver.1.15
--        wk_sql4 := wk_sql4 || '                 SELECT  /*+ use_nl(gmd mld gbh grb itp mil) */ mil.inventory_location_id  location_id ';
        wk_sql4 := wk_sql4 || '                 SELECT  /*+ leading(gmd gbh grb mil mld itp) use_nl(grb mil) index(itp ic_tran_pndi3) */ ';
        wk_sql4 := wk_sql4 || '                         mil.inventory_location_id  location_id ';
-- 2011/12/06 Mod End Ver.1.15
        wk_sql4 := wk_sql4 || '                       , gmd.item_id                item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                 lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    gme_batch_header           gbh  ';
        wk_sql4 := wk_sql4 || '                       , gme_material_details       gmd  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details      mld  ';
        wk_sql4 := wk_sql4 || '                       , gmd_routings_b             grb  ';
        wk_sql4 := wk_sql4 || '                       , ic_tran_pnd                itp  ';
        wk_sql4 := wk_sql4 || '                       , mtl_item_locations         mil  ';
        wk_sql4 := wk_sql4 || '                 WHERE   gbh.batch_status       IN (1, 2) ';
        wk_sql4 := wk_sql4 || '                 AND     gbh.plan_start_date   <= TO_DATE(''' || ld_max_date || ''') ';
        wk_sql4 := wk_sql4 || '                 AND     gbh.batch_id           = gmd.batch_id ';
        wk_sql4 := wk_sql4 || '                 AND     gmd.line_type          = -1 ';
        wk_sql4 := wk_sql4 || '                 AND     gmd.item_id            = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     gmd.material_detail_id = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     gbh.routing_id         = grb.routing_id ';
        wk_sql4 := wk_sql4 || '                 AND     grb.attribute9         = mil.segment1  ';
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code = ''40'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code   = ''10'' ';
-- 2008/11/19 v1.4 D.Nihei ADD START 統合障害#681
        wk_sql4 := wk_sql4 || '                 AND     itp.doc_type           = ''PROD'' ';
-- 2008/11/19 v1.4 D.Nihei ADD END
-- 2008/12/02 v1.5 D.Nihei ADD START 統合障害#251
        wk_sql4 := wk_sql4 || '                 AND     itp.delete_mark        = 0 ';
-- 2008/12/02 v1.5 D.Nihei ADD END
        wk_sql4 := wk_sql4 || '                 AND     itp.line_id            = gmd.material_detail_id  ';
        wk_sql4 := wk_sql4 || '                 AND     itp.item_id            = gmd.item_id ';
        wk_sql4 := wk_sql4 || '                 AND     itp.lot_id             = mld.lot_id ';
        wk_sql4 := wk_sql4 || '                 AND     itp.completed_ind      = 0 ';
        wk_sql4 := wk_sql4 || '                 UNION ';
        wk_sql4 := wk_sql4 || '                 SELECT  mil.inventory_location_id  location_id ';
        wk_sql4 := wk_sql4 || '                       , ' || lt_item_id || '       item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                 lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    po_lines_all               pla   ';
        wk_sql4 := wk_sql4 || '                       , po_headers_all             pha   ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details      mld   ';
        wk_sql4 := wk_sql4 || '                       , mtl_item_locations         mil   ';
        wk_sql4 := wk_sql4 || '                 WHERE   pla.item_id            = ' || lt_inv_item_id;
        wk_sql4 := wk_sql4 || '                 AND     pla.attribute13        = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     pla.cancel_flag        = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     pla.attribute12        = mil.segment1      ';
        wk_sql4 := wk_sql4 || '                 AND     pla.po_header_id       = pha.po_header_id  ';
-- 2009/03/30 H.Itou ADD START 本番障害#1346
        wk_sql4 := wk_sql4 || '                 AND     pha.org_id              = TO_NUMBER('''|| lv_org_id || ''')';
-- 2009/03/30 H.Itou ADD END
        wk_sql4 := wk_sql4 || '                 AND     pha.attribute1         IN (''20'', ''25'') ';
        wk_sql4 := wk_sql4 || '                 AND     pha.attribute4        <= TO_CHAR(TO_DATE(''' || ld_max_date || '''), ''YYYY/MM/DD'') ';
        wk_sql4 := wk_sql4 || '                 AND     pla.po_line_id         = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code = ''50'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code   = ''10'' ';
        wk_sql4 := wk_sql4 || '                 UNION ';
        wk_sql4 := wk_sql4 || '                 SELECT  mrih.ship_to_locat_id       location_id ';
        wk_sql4 := wk_sql4 || '                       , mld.item_id                 item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                  lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql4 := wk_sql4 || '                 WHERE   mrih.comp_actual_flg    = ''Y'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.correct_actual_flg = ''Y'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.status             = ''06'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.delete_flg         = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id             = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code  = ''20'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code    = ''30'' ';
        wk_sql4 := wk_sql4 || '                 UNION ';
        wk_sql4 := wk_sql4 || '                 SELECT  mrih.shipped_locat_id       location_id ';
        wk_sql4 := wk_sql4 || '                       , mld.item_id                 item_id ';
        wk_sql4 := wk_sql4 || '                       , mld.lot_id                  lot_id ';
        wk_sql4 := wk_sql4 || '                 FROM    xxinv_mov_req_instr_headers mrih  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_req_instr_lines   mril  ';
        wk_sql4 := wk_sql4 || '                       , xxinv_mov_lot_details       mld   ';
        wk_sql4 := wk_sql4 || '                 WHERE   mrih.comp_actual_flg    = ''Y'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.correct_actual_flg = ''Y'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.status             = ''06'' ';
        wk_sql4 := wk_sql4 || '                 AND     mrih.mov_hdr_id         = mril.mov_hdr_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.mov_line_id        = mld.mov_line_id ';
        wk_sql4 := wk_sql4 || '                 AND     mril.delete_flg         = ''N'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.item_id             = ' || lt_item_id;
        wk_sql4 := wk_sql4 || '                 AND     mld.document_type_code  = ''20'' ';
        wk_sql4 := wk_sql4 || '                 AND     mld.record_type_code    = ''20'' ';
      END IF;
      wk_sql4 := wk_sql4 || '                 ) inv ';
-- 2008/10/22 D.Nihei MOD START
--      wk_sql2 := wk_sql2 || '               , ( SELECT  ilm.item_id  item_id ';
--      wk_sql2 := wk_sql2 || '                         , ilm.lot_id   lot_id  ';
--      wk_sql2 := wk_sql2 || '                   FROM    ic_lots_mst        ilm     '; -- OPMロットマスタ
--      --==========================
--      -- 資材
--      --==========================
--      IF ( lt_item_class_code = cv_shizai ) 
--      THEN
--        wk_sql2 := wk_sql2 || '                 WHERE   ilm.item_id = ' || lt_item_id;
--      --==========================
--      -- 資材以外
--      --==========================
--      ELSE
--        wk_sql2 := wk_sql2 || '                       , xxcmn_lot_status_v xlsv '; -- ロットステータス
--        wk_sql2 := wk_sql2 || '                 WHERE   ilm.item_id                  = '   || lt_item_id;
--        wk_sql2 := wk_sql2 || '                 AND     xlsv.prod_class_code         = ''' || lt_prod_class_code || '''';
--        wk_sql2 := wk_sql2 || '                 AND     xlsv.raw_mate_turn_m_reserve = ''Y''           ';
--        wk_sql2 := wk_sql2 || '                 AND     xlsv.lot_status              = ilm.attribute23 ';
--      END IF;
--      wk_sql2 := wk_sql2 || '                 ) lot ';
      wk_sql4 := wk_sql4 || '                 , ic_lots_mst lot ';
-- 2008/10/22 D.Nihei MOD END
      wk_sql4 := wk_sql4 || '               WHERE NOT EXISTS (SELECT 1  ';
      wk_sql4 := wk_sql4 || '                                 FROM   xxwip_material_detail   xmdd ';     -- 生産原料詳細アドオン
      wk_sql4 := wk_sql4 || '                                 WHERE  xmdd.material_detail_id  = ' || in_material_detail_id;
      wk_sql4 := wk_sql4 || '                                 AND    xmdd.plan_type           IN ( ''1'', ''2'', ''3'' )     ';
      wk_sql4 := wk_sql4 || '                                 AND    xilv.segment1           = xmdd.location_code ';
      wk_sql4 := wk_sql4 || '                                 AND    lot.lot_id              = xmdd.lot_id ) ';
      wk_sql4 := wk_sql4 || '               AND   inv.item_id     = lot.item_id ';
      wk_sql4 := wk_sql4 || '               AND   inv.location_id = xilv.inventory_location_id ';
      wk_sql4 := wk_sql4 || '               AND   inv.lot_id      = lot.lot_id ';
-- 2009/03/25 H.Itou ADD START 本番障害#1312 伊藤園在庫管理倉庫のみ抽出。相手先在庫は対象外
      wk_sql4 := wk_sql4 || '               AND   xilv.customer_stock_whse = ''0'' ';
-- 2009/03/25 H.Itou ADD END
      --==========================
      -- 検索条件：出倉庫1～5のいずれかが指定されている場合
      --==========================
      IF ( ( lt_location1 IS NOT NULL )
        OR ( lt_location2 IS NOT NULL )
        OR ( lt_location3 IS NOT NULL )
        OR ( lt_location4 IS NOT NULL )
        OR ( lt_location5 IS NOT NULL )
         )
      THEN
        wk_sql4 := wk_sql4 || '             AND  xilv.segment1 IN ( ''' || lt_location1 || ''', ''' 
                                                                        || lt_location2 || ''', ''' 
                                                                        || lt_location3 || ''', ''' 
                                                                        || lt_location4 || ''', ''' 
                                                                        || lt_location5 || ''' ) ';
      END IF;
      wk_sql4 := wk_sql4 || '        ) enable_lot ';
      wk_sql4 := wk_sql4 || '      WHERE ilm.item_id = enable_lot.item_id ';
      wk_sql4 := wk_sql4 || '        AND ilm.lot_id  = enable_lot.lot_id ';
      wk_sql4 := wk_sql4 || '      ORDER BY enable_lot.record_type             DESC ';
      wk_sql4 := wk_sql4 || '              ,enable_lot.whse_inside_outside_div DESC ';
      wk_sql4 := wk_sql4 || '              ,enable_lot.storehouse_code ';
-- 2008/10/29 D.Nihei MOD START 統合障害#481
--      wk_sql2 := wk_sql2 || '              ,TO_NUMBER( lot_no ) ';
      wk_sql4 := wk_sql4 || '              ,TO_NUMBER( DECODE(lot_id ,0, NULL,lot_no) ) ';
-- 2008/10/29 D.Nihei MOD END
--
-- 2008/10/07 D.Nihei DEL START
--      EXECUTE IMMEDIATE wk_sql BULK COLLECT INTO ior_ilm_data ;
-- 2008/10/07 D.Nihei DEL END
      -- 変数の初期化
      ln_cnt := 1;
      OPEN wk_cv FOR wk_sql1 || wk_sql2 || wk_sql3 || wk_sql4;
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
-- 2009/02/02 D.Nihei ADD START
           , ln_inbound_qty_all
           , ln_outbound_qty_all
-- 2009/02/02 D.Nihei ADD END
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
-- 2009/03/03 D.Nihei ADD START 本番障害#@@@@
        IF ( ior_ilm_data(ln_cnt).instructions_qty IS NOT NULL ) THEN
          SELECT COUNT(1)
          INTO   ln_inst_cnt
          FROM   xxwip_material_detail xmd
          WHERE  xmd.material_detail_id = ior_ilm_data(ln_cnt).material_detail_id
          AND    xmd.item_id            = ior_ilm_data(ln_cnt).item_id
          AND    xmd.lot_id             = ior_ilm_data(ln_cnt).lot_id
-- 2009/03/19 H.Itou DEL START 本番障害#1332 他倉庫からの引当でも、予定区分4は自倉庫で作成するため、条件不要
--          AND    xmd.location_code      = ior_ilm_data(ln_cnt).storehouse_code
-- 2009/03/19 H.Itou DEL END
          AND    xmd.plan_type          = '4' -- 予定区分
          AND    ROWNUM                 = 1
          ;
          -- 予定区分4が存在しない場合、手配コピーからの遷移なので元指示総数を0にする
          IF ( ln_inst_cnt = 0 ) THEN
            ior_ilm_data(ln_cnt).instructions_qty_orig := 0; -- 元指示総数
          END IF;
        END IF;
-- 2009/03/03 D.Nihei ADD END
-- 2009/02/02 D.Nihei MOD START
--        ior_ilm_data(ln_cnt).enabled_qty := ior_ilm_data(ln_cnt).stock_qty + ior_ilm_data(ln_cnt).inbound_qty - ior_ilm_data(ln_cnt).outbound_qty;
        -- 引当可能数(有効日ベース)
        ln_enabeled_qty_time := ior_ilm_data(ln_cnt).stock_qty + ior_ilm_data(ln_cnt).inbound_qty - ior_ilm_data(ln_cnt).outbound_qty;
--
        -- 引当可能数(総引当ベース)
        ln_enabeled_qty_all  := ior_ilm_data(ln_cnt).stock_qty + ln_inbound_qty_all - ln_outbound_qty_all;
--
        -- 有効日ベース < 総引当ベースの場合
        IF ( ln_enabeled_qty_time < ln_enabeled_qty_all ) THEN
          ior_ilm_data(ln_cnt).enabled_qty := ln_enabeled_qty_time;
--
        ELSE
          ior_ilm_data(ln_cnt).enabled_qty := ln_enabeled_qty_all;
        END IF;
--
-- 2009/02/02 D.Nihei MOD END
        IF ( ( ior_ilm_data(ln_cnt).enabled_qty <= 0 ) 
         AND ( ior_ilm_data(ln_cnt).record_type =  0 ) ) 
        THEN
          ior_ilm_data.DELETE(ln_cnt);
-- 2008/12/24 D.Nihei ADD START 本番障害#837
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
--    EXCEPTION
--      WHEN OTHERS THEN
--        NULL;
    END;
--
  END blk_ilm_qry;
--
END xxwip200001;
/
