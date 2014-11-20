CREATE OR REPLACE PACKAGE BODY xxwsh_common_get_qty_pkg 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwsh_common_get_qty_pkg(BODY)
 * Description            : 共通関数引当数(BODY)
 * MD.070(CMD.050)        : なし
 * Version                : 1.4
 *
 * Program List
 *  ----------------------   ---- ----- --------------------------------------------------
 *   Name                    Type  Ret   Description
 *  ----------------------   ---- ----- --------------------------------------------------
 *  get_demsup_qy             F    NUM   在庫数以外の引当可能数
 *  get_stock_qty             F    NUM   在庫数取得
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/12/25   1.0   Oracle 北寒寺正夫 新規作成
 *  2009/01/21   1.1   SCS二瓶           本番障害#1020
 *  2009/11/25   1.2   SCS北寒寺         営業障害管理表No11
 *  2009/11/27   1.3   SCS伊藤           営業障害管理表No11
 *  2010/02/23   1.4   SCS伊藤           E_本稼動_01612対応
 *****************************************************************************************/
--
  cv_doc_type_10 CONSTANT VARCHAR2(2) := '10';
  cv_doc_type_20 CONSTANT VARCHAR2(2) := '20';
  cv_doc_type_30 CONSTANT VARCHAR2(2) := '30';
  cv_doc_type_40 CONSTANT VARCHAR2(2) := '40';
  cv_doc_type_50 CONSTANT VARCHAR2(2) := '50';
  cv_doc_type_pr CONSTANT VARCHAR2(10) := 'PROD';
--
  cv_rec_type_10 CONSTANT VARCHAR2(2) := '10';
  cv_rec_type_20 CONSTANT VARCHAR2(2) := '20';
  cv_rec_type_30 CONSTANT VARCHAR2(2) := '30';
--
  cv_status_02   CONSTANT VARCHAR2(2) := '02';
  cv_status_03   CONSTANT VARCHAR2(2) := '03';
  cv_status_04   CONSTANT VARCHAR2(2) := '04';
  cv_status_05   CONSTANT VARCHAR2(2) := '05';
  cv_status_06   CONSTANT VARCHAR2(2) := '06';
  cv_status_07   CONSTANT VARCHAR2(2) := '07';
  cv_status_08   CONSTANT VARCHAR2(2) := '08';
  cv_status_20   CONSTANT VARCHAR2(2) := '20';
  cv_status_25   CONSTANT VARCHAR2(2) := '25';
--
  cv_flag_y      CONSTANT VARCHAR2(1) := 'Y';
  cv_flag_n      CONSTANT VARCHAR2(1) := 'N';
--
  cv_type_1      CONSTANT VARCHAR2(1) := '1';
  cv_type_2      CONSTANT VARCHAR2(1) := '2';
  cv_type_3      CONSTANT VARCHAR2(1) := '3';
--
  cn_type_m1     CONSTANT NUMBER := -1;
  cn_type_0      CONSTANT NUMBER := 0;
  cn_type_1      CONSTANT NUMBER := 1;
  cn_type_2      CONSTANT NUMBER := 2;
--
  FUNCTION get_demsup_qty (it_item_id   IN ic_item_mst_b.item_id%TYPE
                          ,it_lot_ctl   IN ic_item_mst_b.lot_ctl%TYPE
                          ,it_lot_id    IN ic_lots_mst.lot_id%TYPE
                          ,it_lot_no    IN ic_lots_mst.lot_no%TYPE
                          ,it_org_id    IN mtl_system_items_b.organization_id%TYPE
                          ,id_trn_date  IN DATE
                          ,id_max_date  IN DATE
                          ,it_loc_id    IN mtl_item_locations.inventory_location_id%TYPE
                          ,it_loc_code  IN mtl_item_locations.segment1%TYPE
                          ,it_head_loc  IN mtl_item_locations.segment1%TYPE
                          ,it_dummy_loc IN mtl_item_locations.segment1%TYPE) RETURN NUMBER
  AS
--
    --戻り値用変数
    ln_ret_qty           NUMBER;
    --計算用変数(トランザクション日)
    ln_demsup_self_trn   NUMBER;
    ln_demsup_all_trn    NUMBER;
    ln_demsup_parent_trn NUMBER;
    --計算用変数(最大日)
    ln_demsup_self_max   NUMBER;
    ln_demsup_all_max    NUMBER;
    ln_demsup_parent_max NUMBER;
    --自身以外の在庫数用変数
    ln_stock_other       NUMBER;
--
    --対象倉庫の需給数を取得するカーソル
    CURSOR get_demsup_self_cur (id_target_date IN DATE) IS
      SELECT
        ( -- S1)供給数  移動入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
        WHERE   mrih.ship_to_locat_id   = it_loc_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_arrival_date  <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_10
        ) + 
        ( -- S2)供給数  発注受入予定
        SELECT  NVL(SUM(pla.quantity), 0)
        FROM    ic_item_mst_b      iimb
               ,mtl_system_items_b msib
               ,po_lines_all       pla
               ,po_headers_all     pha
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = it_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute1         = it_lot_no
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1        IN (cv_status_20,cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date,'YYYY/MM/DD')
        AND     pha.attribute5         = it_loc_code
        ) + 
        ( -- S3)供給数  生産入庫予定
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
               ,ic_tran_pnd           itp  -- OPM保留在庫トランザクション
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
        WHERE   gbh.batch_status      IN (cn_type_1,cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type         IN (cn_type_1,cn_type_2)
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = itp.line_id
        AND     itp.completed_ind      = cn_type_0
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.lot_id             = mld.lot_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     grb.attribute9         = it_loc_code
        -- yoshida 2008/12/18 v1.17 add start
        AND     itp.delete_mark        = cn_type_0
        -- yoshida 2008/12/18 v1.17 add end
        ) + 
        ( -- S4)供給数  実績計上済の移動出庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
        WHERE   mrih.ship_to_locat_id   = it_loc_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_04
        AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- D1)需要数  実績未計上の出荷依頼
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
        WHERE   oha.deliver_from_id       = it_loc_id
        AND     oha.req_status            = cv_status_03
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_1
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D2)需要数  実績未計上の支給指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
        WHERE   oha.deliver_from_id       = it_loc_id
        AND     oha.req_status            = cv_status_07
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D3)需要数  実績未計上の移動指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
        WHERE   mrih.shipped_locat_id   = it_loc_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_ship_date  <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_10
        ) - 
        ( -- D4)需要数  実績計上済の移動入庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
        WHERE   mrih.shipped_locat_id   = it_loc_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_05
        AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_doc_type_30
        ) - 
        ( -- D5)需要数  実績未計上の生産投入予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,ic_tran_pnd           itp  -- 保留在庫トランザクション
        WHERE   gbh.batch_status      IN (cn_type_1,cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type          = cn_type_m1
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     grb.attribute9         = it_loc_code
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     itp.line_id            = gmd.material_detail_id 
        AND     itp.item_id            = gmd.item_id
        AND     itp.lot_id             = mld.lot_id
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.delete_mark        = cn_type_0
        AND     itp.completed_ind      = cn_type_0
        ) - 
        ( -- D6)需要数  実績未計上の相手先倉庫発注入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    ic_item_mst_b         iimb
               ,mtl_system_items_b    msib    -- 品目マスタ
               ,po_lines_all          pla     -- 発注明細
               ,po_headers_all        pha     -- 発注ヘッダ
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = it_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.attribute12        = it_loc_code
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1        IN (cv_status_20,cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date,'YYYY/MM/DD')
        AND     pla.po_line_id         = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     mld.document_type_code = cv_doc_type_50
        AND     mld.record_type_code   = cv_rec_type_10
        ) demand_supply
      FROM DUAL;
--
    --対象倉庫の子倉庫の在庫数を取得するカーソル
    CURSOR get_stock_child_cur IS
      SELECT
        ( -- I0)EBS手持在庫取得
        SELECT NVL(SUM(ili.loct_onhand),0)
        FROM   ic_loct_inv ili
              ,mtl_item_locations mil
        WHERE  ili.item_id                 = it_item_id
        AND    ili.lot_id                  = it_lot_id
        AND    ili.location                = mil.segment1
        AND    mil.segment1               <> mil.attribute5
        AND    mil.attribute5              = it_head_loc
        ) + 
        ( -- I1)実績未取在庫数  移動入庫（入出庫報告有）
          -- I2)実績未取在庫数  移動入庫（入庫報告有）
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+ INDEX(MIL MTL_ITEM_LOCATIONS_U1) */
-- Ver1.3 2009/11/27 END
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mil.segment1           <> mil.attribute5
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_05,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- I3)実績未取在庫数  移動出庫（入出庫報告有）
          -- I4)実績未取在庫数  移動出庫（出庫報告有）
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+ INDEX(MIL MTL_ITEM_LOCATIONS_U1) */
-- Ver1.3 2009/11/27 END
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mil.segment1           <> mil.attribute5
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_04,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- I5)実績未取在庫数  出荷
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+  INDEX(mil MTL_ITEM_LOCATIONS_U1)*/
-- Ver1.3 2009/11/27 END
                NVL(
--        SELECT  NVL(
-- Ver1.2 2009/11/25 END
                  SUM(
                    CASE otta.order_category_code
                    WHEN 'ORDER' THEN
                      NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                    WHEN 'RETURN' THEN
                      (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                    END),0)
        FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.attribute5            = it_head_loc
        AND     mil.segment1             <> mil.attribute5
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_04
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
-- 2009/01/21 D.Nihei MOD START
--        AND     mld.record_type_code      = cv_rec_type_10
        AND     mld.record_type_code      = cv_rec_type_20
-- 2009/01/21 D.Nihei MOD END
        AND     otta.attribute1           IN (cv_type_1,cv_type_3)
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- I6)実績未取在庫数  支給
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+  INDEX(mil MTL_ITEM_LOCATIONS_U1)*/
-- Ver1.3 2009/11/27 END
                NVL(
--        SELECT  NVL(
-- Ver1.2 2009/11/25 END
                  SUM(
                    CASE otta.order_category_code
                    WHEN 'ORDER' THEN
                      NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                    WHEN 'RETURN' THEN
                      (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                    END),0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta   -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.attribute5            = it_head_loc
        AND     mil.segment1             <> mil.attribute5
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_08
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) + 
        ( -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+ INDEX(MIL MTL_ITEM_LOCATIONS_U1) */
-- Ver1.3 2009/11/27 END
               NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
--        SELECT  NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mil.segment1           <> mil.attribute5
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) + 
        ( -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+ INDEX(MIL MTL_ITEM_LOCATIONS_U1) */
-- Ver1.3 2009/11/27 END
               NVL(SUM(mld.before_actual_quantity),0) - NVL(SUM(mld.actual_quantity),0)
--        SELECT  NVL(SUM(mld.before_actual_quantity),0) - NVL(SUM(mld.actual_quantity),0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mil.segment1           <> mil.attribute5
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) + 
        ( -- I0)EBS手持在庫取得
        SELECT NVL(SUM(ili.loct_onhand),0)
        FROM   ic_loct_inv ili
              ,xxwsh_frq_item_locations xfil
        WHERE  ili.item_id                 = it_item_id
        AND    ili.lot_id                  = it_lot_id
        AND    ili.location                = xfil.item_location_code
        AND    xfil.frq_item_location_code = it_head_loc
        AND    xfil.item_id                = it_item_id
        ) + 
        ( -- I1)実績未取在庫数  移動入庫（入出庫報告有）
          -- I2)実績未取在庫数  移動入庫（入庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_05,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- I3)実績未取在庫数  移動出庫（入出庫報告有）
          -- I4)実績未取在庫数  移動出庫（出庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.shipped_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_04,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- I5)実績未取在庫数  出荷
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(
--        SELECT  NVL(
-- Ver1.2 2009/11/25 END
                  SUM(
                    CASE otta.order_category_code
                    WHEN 'ORDER' THEN
                      NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                    WHEN 'RETURN' THEN
                      (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                    END),0)
        FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id              = it_item_id
        AND     oha.deliver_from_id       = xfil.item_location_id
        AND     oha.req_status            = cv_status_04
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
-- 2009/01/21 D.Nihei MOD START
--        AND     mld.record_type_code      = cv_rec_type_10
        AND     mld.record_type_code      = cv_rec_type_20
-- 2009/01/21 D.Nihei MOD END
        AND     otta.attribute1           IN (cv_type_1,cv_type_3)
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- I6)実績未取在庫数  支給
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(
--        SELECT  NVL(
-- Ver1.2 2009/11/25 END
                  SUM(
                    CASE otta.order_category_code
                    WHEN 'ORDER' THEN
                      NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                    WHEN 'RETURN' THEN
                      (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                    END),0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta   -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id              = it_item_id
        AND     oha.deliver_from_id       = xfil.item_location_id
        AND     oha.req_status            = cv_status_08
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) + 
        ( -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
        --SELECT  NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) + 
        ( -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.before_actual_quantity),0) - NVL(SUM(mld.actual_quantity),0)
--        SELECT  NVL(SUM(mld.before_actual_quantity),0) - NVL(SUM(mld.actual_quantity),0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.shipped_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) stock_qty
      FROM DUAL;
--
    --対象倉庫の親と子倉庫の需給数を取得するカーソル(親子別に取得する必要がないため)
    CURSOR get_demsup_all_cur (id_target_date IN DATE) IS
      SELECT
        ( -- S1)供給数  移動入庫予定
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+ INDEX(MIL MTL_ITEM_LOCATIONS_U1) */
-- Ver1.3 2009/11/27 END
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_arrival_date  <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_10
        ) + 
        ( -- S2)供給数  発注受入予定
-- Ver1.3 2009/11/27 START
--        SELECT  NVL(SUM(pla.quantity), 0)
        SELECT  /*+ LEADING(iimb msib pla pha) INDEX(mil MTL_ITEM_LOCATION_N1) */
                NVL(SUM(pla.quantity), 0)
-- Ver1.3 2009/11/27 END
        FROM    ic_item_mst_b      iimb
               ,mtl_system_items_b msib
               ,po_lines_all       pla
               ,po_headers_all     pha
               ,mtl_item_locations mil
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = it_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute1         = it_lot_no
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1        IN (cv_status_20,cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date,'YYYY/MM/DD')
        AND     pha.attribute5         = mil.segment1
        AND     mil.attribute5         = it_head_loc
        ) + 
        ( -- S3)供給数  生産入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
               ,ic_tran_pnd           itp  -- OPM保留在庫トランザクション
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,mtl_item_locations    mil
        WHERE   gbh.batch_status      IN (cn_type_1,cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type         IN (cn_type_1,cn_type_2)
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = itp.line_id
        AND     itp.completed_ind      = cn_type_0
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.lot_id             = mld.lot_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     grb.attribute9         = mil.segment1
        AND     mil.attribute5         = it_head_loc
        -- yoshida 2008/12/18 v1.17 add start
        AND     itp.delete_mark        = cn_type_0
        -- yoshida 2008/12/18 v1.17 add end
        ) + 
        ( -- S4)供給数  実績計上済の移動出庫実績
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+ INDEX(MIL MTL_ITEM_LOCATIONS_U1) */
-- Ver1.3 2009/11/27 END
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_04
        AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- D1)需要数  実績未計上の出荷依頼
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+  INDEX(mil MTL_ITEM_LOCATIONS_U1)*/
-- Ver1.3 2009/11/27 END
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.attribute5            = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_03
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_1
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D2)需要数  実績未計上の支給指示
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+  INDEX(mil MTL_ITEM_LOCATIONS_U1)*/
-- Ver1.3 2009/11/27 END
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.attribute5            = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_07
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D3)需要数  実績未計上の移動指示
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+ INDEX(MIL MTL_ITEM_LOCATIONS_U1) */
-- Ver1.3 2009/11/27 END
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_ship_date  <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_10
        ) - 
        ( -- D4)需要数  実績計上済の移動入庫実績
-- Ver1.2 2009/11/25 START
-- Ver1.3 2009/11/27 START
--        SELECT  /*+  LEADING(mld)*/
        SELECT  /*+ INDEX(MIL MTL_ITEM_LOCATIONS_U1) */
-- Ver1.3 2009/11/27 END
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_05
        AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- D5)需要数  実績未計上の生産投入予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,ic_tran_pnd           itp  -- 保留在庫トランザクション
               ,mtl_item_locations    mil
        WHERE   gbh.batch_status      IN (cn_type_1,cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type          = cn_type_m1
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     itp.line_id            = gmd.material_detail_id 
        AND     itp.item_id            = gmd.item_id
        AND     itp.lot_id             = mld.lot_id
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.delete_mark        = cn_type_0
        AND     itp.completed_ind      = cn_type_0
        AND     grb.attribute9         = mil.segment1
        AND     mil.attribute5         = it_head_loc
        ) - 
        ( -- D6)需要数  実績未計上の相手先倉庫発注入庫予定
-- Ver1.3 2009/11/27 START
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
        SELECT  /*+ LEADING(iimb msib pla pha) INDEX(mil MTL_ITEM_LOCATION_N1) */
                NVL(SUM(mld.actual_quantity), 0)
-- Ver1.3 2009/11/27 END
        FROM    ic_item_mst_b         iimb
               ,mtl_system_items_b    msib    -- 品目マスタ
               ,po_lines_all          pla     -- 発注明細
               ,po_headers_all        pha     -- 発注ヘッダ
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations    mil
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = it_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1        IN (cv_status_20,cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date,'YYYY/MM/DD')
        AND     pla.po_line_id         = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     mld.document_type_code = cv_doc_type_50
        AND     mld.record_type_code   = cv_rec_type_10
        AND     pla.attribute12        = mil.segment1
        AND     mil.attribute5         = it_head_loc
        ) + 
        ( -- S1)供給数  移動入庫予定
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_arrival_date  <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_10
        ) + 
        ( -- S2)供給数  発注受入予定
        SELECT  NVL(SUM(pla.quantity), 0)
        FROM    ic_item_mst_b      iimb
               ,mtl_system_items_b msib
               ,po_lines_all       pla
               ,po_headers_all     pha
               ,xxwsh_frq_item_locations xfil
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = it_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute1         = it_lot_no
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1        IN (cv_status_20,cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date,'YYYY/MM/DD')
        AND     pha.attribute5         = xfil.item_location_code
        AND     xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id           = it_item_id
        ) + 
        ( -- S3)供給数  生産入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
               ,ic_tran_pnd           itp  -- OPM保留在庫トランザクション
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,xxwsh_frq_item_locations xfil
        WHERE   gbh.batch_status      IN (cn_type_1,cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type         IN (cn_type_1,cn_type_2)
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = itp.line_id
        AND     itp.completed_ind      = cn_type_0
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.lot_id             = mld.lot_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     grb.attribute9         = xfil.item_location_code
        AND     xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id           = it_item_id
        -- yoshida 2008/12/18 v1.17 add start
        AND     itp.delete_mark        = cn_type_0
        -- yoshida 2008/12/18 v1.17 add end
        ) + 
        ( -- S4)供給数  実績計上済の移動出庫実績
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_04
        AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- D1)需要数  実績未計上の出荷依頼
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id              = it_item_id
        AND     oha.deliver_from_id       = xfil.item_location_id
        AND     oha.req_status            = cv_status_03
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_1
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D2)需要数  実績未計上の支給指示
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id              = it_item_id
        AND     oha.deliver_from_id       = xfil.item_location_id
        AND     oha.req_status            = cv_status_07
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D3)需要数  実績未計上の移動指示
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.shipped_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_ship_date  <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_10
        ) - 
        ( -- D4)需要数  実績計上済の移動入庫実績
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.shipped_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_05
        AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- D5)需要数  実績未計上の生産投入予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,ic_tran_pnd           itp  -- 保留在庫トランザクション
               ,xxwsh_frq_item_locations xfil
        WHERE   gbh.batch_status      IN (cn_type_1,cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type          = cn_type_m1
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     itp.line_id            = gmd.material_detail_id 
        AND     itp.item_id            = gmd.item_id
        AND     itp.lot_id             = mld.lot_id
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.delete_mark        = cn_type_0
        AND     itp.completed_ind      = cn_type_0
        AND     grb.attribute9         = xfil.item_location_code
        AND     xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id           = it_item_id
        ) - 
        ( -- D6)需要数  実績未計上の相手先倉庫発注入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    ic_item_mst_b         iimb
               ,mtl_system_items_b    msib    -- 品目マスタ
               ,po_lines_all          pla     -- 発注明細
               ,po_headers_all        pha     -- 発注ヘッダ
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations xfil
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = it_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1        IN (cv_status_20,cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date,'YYYY/MM/DD')
        AND     pla.po_line_id         = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     mld.document_type_code = cv_doc_type_50
        AND     mld.record_type_code   = cv_rec_type_10
        AND     pla.attribute12        = xfil.item_location_code
        AND     xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id           = it_item_id
        ) demand_supply
      FROM DUAL;
--
    --対象倉庫の親倉庫(ダミー)の在庫数を取得するカーソル
    CURSOR get_stock_dummy_cur IS
      SELECT
        ( -- I0)EBS手持在庫取得
        SELECT NVL(SUM(ili.loct_onhand),0)
        FROM   ic_loct_inv ili
              ,xxwsh_frq_item_locations xfil
        WHERE  ili.item_id                 = it_item_id
        AND    ili.lot_id                  = it_lot_id
-- 2009/01/21 D.Nihei MOD START
--        AND    ili.location                = xfil.item_location_code
--        AND    xfil.frq_item_location_code = it_loc_code
        AND    ili.location                = xfil.frq_item_location_code
        AND    xfil.item_location_code     = it_loc_code
-- 2009/01/21 D.Nihei MOD END
        AND    xfil.item_id                = it_item_id
        ) + 
        ( -- I1)実績未取在庫数  移動入庫（入出庫報告有）
          -- I2)実績未取在庫数  移動入庫（入庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT /*+ LEADING(mld mril mrih xfil) */
                NVL(SUM(mld.actual_quantity), 0)
        --SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END

        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id            = it_item_id
--        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        WHERE   xfil.item_location_code = it_loc_code
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_05,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- I3)実績未取在庫数  移動出庫（入出庫報告有）
          -- I4)実績未取在庫数  移動出庫（出庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld mril mrih xfil) */
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id            = it_item_id
--        AND     mrih.shipped_locat_id   = xfil.item_location_id
        WHERE   xfil.item_location_code = it_loc_code
        AND     xfil.item_id            = it_item_id
        AND     mrih.shipped_locat_id   = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_04,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- I5)実績未取在庫数  出荷
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld ola oha xfil otta)*/
                NVL(
--        SELECT  NVL(
-- Ver1.2 2009/11/25 END
                  SUM(
                    CASE otta.order_category_code
                    WHEN 'ORDER' THEN
                      NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                    WHEN 'RETURN' THEN
                      (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                    END),0)
        FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id            = it_item_id
--        AND     oha.deliver_from_id     = xfil.item_location_id
        WHERE   xfil.item_location_code   = it_loc_code
        AND     xfil.item_id              = it_item_id
        AND     oha.deliver_from_id       = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     oha.req_status            = cv_status_04
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
-- 2009/01/21 D.Nihei MOD START
--        AND     mld.record_type_code      = cv_rec_type_10
        AND     mld.record_type_code      = cv_rec_type_20
-- 2009/01/21 D.Nihei MOD END
        AND     otta.attribute1           IN (cv_type_1,cv_type_3)
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- I6)実績未取在庫数  支給
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld ola oha otta xfil)*/
                NVL(
--        SELECT  NVL(
-- Ver1.2 2009/11/25 END
                  SUM(
                    CASE otta.order_category_code
                    WHEN 'ORDER' THEN
                      NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                    WHEN 'RETURN' THEN
                      (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                    END),0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta   -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id              = it_item_id
--        AND     oha.deliver_from_id       = xfil.item_location_id
        WHERE   xfil.item_location_code   = it_loc_code
        AND     xfil.item_id              = it_item_id
        AND     oha.deliver_from_id       = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     oha.req_status            = cv_status_08
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) + 
        ( -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld mril mrih xfil)*/
                NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
--        SELECT  NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id            = it_item_id
--        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        WHERE   xfil.item_location_code = it_loc_code
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) + 
        ( -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld mril mrih xfil)*/
                NVL(SUM(mld.before_actual_quantity),0) - NVL(SUM(mld.actual_quantity),0)
--        SELECT  NVL(SUM(mld.before_actual_quantity),0) - NVL(SUM(mld.actual_quantity),0)
-- Ver1.2 2009/11/25 START
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id            = it_item_id
--        AND     mrih.shipped_locat_id   = xfil.item_location_id
        WHERE   xfil.item_location_code = it_loc_code
        AND     xfil.item_id            = it_item_id
        AND     mrih.shipped_locat_id   = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) stock_qty
      FROM DUAL;
--
    --対象倉庫の親倉庫(ダミー)の需給数を取得するカーソル
    CURSOR get_demsup_dummy_cur (id_target_date IN DATE) IS
      SELECT
        ( -- S1)供給数  移動入庫予定
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld mril mrih xfil)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id            = it_item_id
--        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        WHERE   xfil.item_location_code = it_loc_code
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_arrival_date  <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_10
        ) + 
        ( -- S2)供給数  発注受入予定
        SELECT  NVL(SUM(pla.quantity), 0)
        FROM    ic_item_mst_b      iimb
               ,mtl_system_items_b msib
               ,po_lines_all       pla
               ,po_headers_all     pha
               ,xxwsh_frq_item_locations xfil
        WHERE   iimb.item_id            = it_item_id
        AND     msib.segment1           = iimb.item_no
        AND     msib.organization_id    = it_org_id
        AND     msib.inventory_item_id  = pla.item_id
        AND     pla.attribute1          = it_lot_no
        AND     pla.attribute13         = cv_flag_n
        AND     pla.cancel_flag         = cv_flag_n
        AND     pla.po_header_id        = pha.po_header_id
        AND     pha.attribute1          IN (cv_status_20,cv_status_25)
        AND     pha.attribute4        < = TO_CHAR(id_target_date,'YYYY/MM/DD')
-- 2009/01/21 D.Nihei MOD START
--        AND     pha.attribute5         = xfil.item_location_code
--        AND     xfil.frq_item_location_code = it_loc_code
        AND     pha.attribute5          = xfil.frq_item_location_code
        AND     xfil.item_location_code = it_loc_code
-- 2009/01/21 D.Nihei MOD END
        AND     xfil.item_id            = it_item_id
        ) + 
        ( -- S3)供給数  生産入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
               ,ic_tran_pnd           itp  -- OPM保留在庫トランザクション
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,xxwsh_frq_item_locations xfil
        WHERE   gbh.batch_status        IN (cn_type_1,cn_type_2)
        AND     gbh.plan_start_date    <= id_target_date
        AND     gbh.batch_id            = gmd.batch_id
        AND     gmd.line_type           IN (cn_type_1,cn_type_2)
        AND     gmd.item_id             = it_item_id
        AND     gmd.material_detail_id  = itp.line_id
        AND     itp.completed_ind       = cn_type_0
        AND     itp.doc_type            = cv_doc_type_pr
        AND     itp.lot_id              = mld.lot_id
        AND     gmd.material_detail_id  = mld.mov_line_id
        AND     mld.document_type_code  = cv_doc_type_40
        AND     mld.record_type_code    = cv_rec_type_10
        AND     mld.lot_id              = it_lot_id
        AND     gbh.routing_id          = grb.routing_id
-- 2009/01/21 D.Nihei MOD START
--        AND     grb.attribute9         = xfil.item_location_code
--        AND     xfil.frq_item_location_code = it_loc_code
        AND     grb.attribute9          = xfil.frq_item_location_code
        AND     xfil.item_location_code = it_loc_code
-- 2009/01/21 D.Nihei MOD END
        AND     xfil.item_id            = it_item_id
        -- yoshida 2008/12/18 v1.17 add start
        AND     itp.delete_mark        = cn_type_0
        -- yoshida 2008/12/18 v1.17 add end
        ) + 
        ( -- S4)供給数  実績計上済の移動出庫実績
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld mril mrih xfil)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id            = it_item_id
--        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        WHERE   xfil.item_location_code = it_loc_code
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_04
        AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- D1)需要数  実績未計上の出荷依頼
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld ola oha xfil otta)*/
                NVL(SUM(mld.actual_quantity), 0)
        --SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id              = it_item_id
--        AND     oha.deliver_from_id       = xfil.item_location_id
        WHERE   xfil.item_location_code   = it_loc_code
        AND     xfil.item_id              = it_item_id
        AND     oha.deliver_from_id       = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     oha.req_status            = cv_status_03
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_1
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D2)需要数  実績未計上の支給指示
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld ola oha xfil otta)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id              = it_item_id
--        AND     oha.deliver_from_id       = xfil.item_location_id
        WHERE   xfil.item_location_code   = it_loc_code
        AND     xfil.item_id              = it_item_id
        AND     oha.deliver_from_id       = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     oha.req_status            = cv_status_07
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D3)需要数  実績未計上の移動指示
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld mril mrih xfil)*/
               NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id            = it_item_id
--        AND     mrih.shipped_locat_id   = xfil.item_location_id
        WHERE   xfil.item_location_code = it_loc_code
        AND     xfil.item_id            = it_item_id
        AND     mrih.shipped_locat_id   = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_ship_date  <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_10
        ) - 
        ( -- D4)需要数  実績計上済の移動入庫実績
-- Ver1.2 2009/11/25 START
        SELECT  /*+  LEADING(mld mril mrih xfil)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations    xfil
-- 2009/01/21 D.Nihei MOD START
--        WHERE   xfil.frq_item_location_code = it_loc_code
--        AND     xfil.item_id            = it_item_id
--        AND     mrih.shipped_locat_id   = xfil.item_location_id
        WHERE   xfil.item_location_code = it_loc_code
        AND     xfil.item_id            = it_item_id
        AND     mrih.shipped_locat_id   = xfil.frq_item_location_id
-- 2009/01/21 D.Nihei MOD END
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_05
        AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- D5)需要数  実績未計上の生産投入予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,ic_tran_pnd           itp  -- 保留在庫トランザクション
               ,xxwsh_frq_item_locations xfil
        WHERE   gbh.batch_status        IN (cn_type_1,cn_type_2)
        AND     gbh.plan_start_date   < = id_target_date
        AND     gbh.batch_id            = gmd.batch_id
        AND     gmd.line_type           = cn_type_m1
        AND     gmd.item_id             = it_item_id
        AND     gmd.material_detail_id  = mld.mov_line_id
        AND     mld.lot_id              = it_lot_id
        AND     gbh.routing_id          = grb.routing_id
        AND     mld.document_type_code  = cv_doc_type_40
        AND     mld.record_type_code    = cv_rec_type_10
        AND     itp.line_id             = gmd.material_detail_id 
        AND     itp.item_id             = gmd.item_id
        AND     itp.lot_id              = mld.lot_id
        AND     itp.doc_type            = cv_doc_type_pr
        AND     itp.delete_mark         = cn_type_0
        AND     itp.completed_ind       = cn_type_0
-- 2009/01/21 D.Nihei MOD START
--        AND     grb.attribute9         = xfil.item_location_code
--        AND     xfil.frq_item_location_code = it_loc_code
        AND     grb.attribute9          = xfil.frq_item_location_code
        AND     xfil.item_location_code = it_loc_code
-- 2009/01/21 D.Nihei MOD END
        AND     xfil.item_id            = it_item_id
        ) - 
        ( -- D6)需要数  実績未計上の相手先倉庫発注入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    ic_item_mst_b         iimb
               ,mtl_system_items_b    msib    -- 品目マスタ
               ,po_lines_all          pla     -- 発注明細
               ,po_headers_all        pha     -- 発注ヘッダ
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,xxwsh_frq_item_locations xfil
        WHERE   iimb.item_id            = it_item_id
        AND     msib.segment1           = iimb.item_no
        AND     msib.organization_id    = it_org_id
        AND     msib.inventory_item_id  = pla.item_id
        AND     pla.attribute13         = cv_flag_n
        AND     pla.cancel_flag         = cv_flag_n
        AND     pla.po_header_id        = pha.po_header_id
        AND     pha.attribute1          IN (cv_status_20,cv_status_25)
        AND     pha.attribute4        < = TO_CHAR(id_target_date,'YYYY/MM/DD')
        AND     pla.po_line_id          = mld.mov_line_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_50
        AND     mld.record_type_code    = cv_rec_type_10
-- 2009/01/21 D.Nihei MOD START
--        AND     pla.attribute12        = xfil.item_location_code
--        AND     xfil.frq_item_location_code = it_loc_code
        AND     pla.attribute12         = xfil.frq_item_location_code
        AND     xfil.item_location_code = it_loc_code
-- 2009/01/21 D.Nihei MOD END
        AND     xfil.item_id            = it_item_id
        ) demand_supply
      FROM DUAL;
--
    --対象倉庫の親倉庫の在庫数を取得するカーソル
    CURSOR get_stock_parent_cur IS
      SELECT
        ( -- I0)EBS手持在庫取得
-- Ver1.2 2009/11/25 START
        SELECT  /*+  USE_NL(ili mil)*/
               NVL(SUM(ili.loct_onhand),0)
--        SELECT NVL(SUM(ili.loct_onhand),0)
-- Ver1.2 2009/11/25 END
        FROM   ic_loct_inv ili
              ,mtl_item_locations mil
        WHERE  ili.item_id                 = it_item_id
        AND    ili.lot_id                  = it_lot_id
        AND    ili.location                = mil.segment1
        AND    mil.segment1                = it_head_loc
        ) + 
        ( -- I1)実績未取在庫数  移動入庫（入出庫報告有）
          -- I2)実績未取在庫数  移動入庫（入庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld mril mrih mil)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_05,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- I3)実績未取在庫数  移動出庫（入出庫報告有）
          -- I4)実績未取在庫数  移動出庫（出庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld mril mrih mil)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_04,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- I5)実績未取在庫数  出荷
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld ola oha mil otta)*/
                NVL(
--        SELECT  NVL(
-- Ver1.2 2009/11/25 END
                  SUM(
                    CASE otta.order_category_code
                    WHEN 'ORDER' THEN
                      NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                    WHEN 'RETURN' THEN
                      (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                    END),0)
        FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.segment1              = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_04
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
-- 2009/01/21 D.Nihei MOD START
--        AND     mld.record_type_code      = cv_rec_type_10
        AND     mld.record_type_code      = cv_rec_type_20
-- 2009/01/21 D.Nihei MOD END
        AND     otta.attribute1           IN (cv_type_1,cv_type_3)
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- I6)実績未取在庫数  支給
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld ola oha mil otta)*/
                NVL(
--        SELECT  NVL(
-- Ver1.2 2009/11/25 END
                  SUM(
                    CASE otta.order_category_code
                    WHEN 'ORDER' THEN
                      NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                    WHEN 'RETURN' THEN
                      (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                    END),0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta   -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.segment1              = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_08
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) + 
        ( -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld ola oha mil otta)*/
                NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
--        SELECT  NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) + 
        ( -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld mril mrih mil)*/
               NVL(SUM(mld.before_actual_quantity),0) - NVL(SUM(mld.actual_quantity),0)
--        SELECT  NVL(SUM(mld.before_actual_quantity),0) - NVL(SUM(mld.actual_quantity),0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) stock_qty
      FROM DUAL;
--
    --対象倉庫の親倉庫の需給数を取得するカーソル
    CURSOR get_demsup_parent_cur (id_target_date IN DATE) IS
      SELECT
        ( -- S1)供給数  移動入庫予定
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mid mril mrih mil) USE_NL(mld mril mrih mil) */
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_arrival_date  <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_10
        ) + 
        ( -- S2)供給数  発注受入予定
        SELECT  NVL(SUM(pla.quantity), 0)
        FROM    ic_item_mst_b      iimb
               ,mtl_system_items_b msib
               ,po_lines_all       pla
               ,po_headers_all     pha
               ,mtl_item_locations mil
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = it_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute1         = it_lot_no
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1        IN (cv_status_20,cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date,'YYYY/MM/DD')
        AND     pha.attribute5         = mil.segment1
        AND     mil.segment1           = it_head_loc
        ) + 
        ( -- S3)供給数  生産入庫予定
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld) USE_NL(mld itp gmd gmh grb mil)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
               ,ic_tran_pnd           itp  -- OPM保留在庫トランザクション
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,mtl_item_locations    mil
        WHERE   gbh.batch_status      IN (cn_type_1,cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type         IN (cn_type_1,cn_type_2)
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = itp.line_id
        AND     itp.completed_ind      = cn_type_0
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.lot_id             = mld.lot_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     grb.attribute9         = mil.segment1
        AND     mil.segment1           = it_head_loc
        -- yoshida 2008/12/18 v1.17 add start
        AND     itp.delete_mark        = cn_type_0
        -- yoshida 2008/12/18 v1.17 add end
        ) + 
        ( -- S4)供給数  実績計上済の移動出庫実績
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld mril mrih mil) */
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_04
        AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- D1)需要数  実績未計上の出荷依頼
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld ola oha otta mil) */
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.segment1              = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_03
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_1
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D2)需要数  実績未計上の支給指示
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld ola oha otta mil) */
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.segment1              = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_07
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D3)需要数  実績未計上の移動指示
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld mril mrih mil) */
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_ship_date  <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_10
        ) - 
        ( -- D4)需要数  実績計上済の移動入庫実績
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld mril mrih mil) */
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_05
        AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- D5)需要数  実績未計上の生産投入予定
-- Ver1.2 2009/11/25 START
        SELECT  /*+ LEADING(mld gmb gbh grb mil itp) USE_NL(mld gmb gbh grb mil itp)*/
                NVL(SUM(mld.actual_quantity), 0)
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
-- Ver1.2 2009/11/25 END
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,ic_tran_pnd           itp  -- 保留在庫トランザクション
               ,mtl_item_locations    mil
        WHERE   gbh.batch_status      IN (cn_type_1,cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type          = cn_type_m1
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     itp.line_id            = gmd.material_detail_id 
        AND     itp.item_id            = gmd.item_id
        AND     itp.lot_id             = mld.lot_id
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.delete_mark        = cn_type_0
        AND     itp.completed_ind      = cn_type_0
        AND     grb.attribute9         = mil.segment1
        AND     mil.segment1           = it_head_loc
        ) - 
        ( -- D6)需要数  実績未計上の相手先倉庫発注入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    ic_item_mst_b         iimb
               ,mtl_system_items_b    msib    -- 品目マスタ
               ,po_lines_all          pla     -- 発注明細
               ,po_headers_all        pha     -- 発注ヘッダ
-- Ver1.4 H.Itou Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
               ,mtl_item_locations    mil
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = it_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1        IN (cv_status_20,cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date,'YYYY/MM/DD')
        AND     pla.po_line_id         = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     mld.document_type_code = cv_doc_type_50
        AND     mld.record_type_code   = cv_rec_type_10
        AND     pla.attribute12        = mil.segment1
        AND     mil.segment1           = it_head_loc
        ) demand_supply
      FROM DUAL;
--
  BEGIN
--
    --ロット管理品の場合
    IF (it_lot_ctl = 1) THEN
--
      --代表倉庫がない場合
      IF (it_head_loc IS NULL) THEN
--
        --自分の需給数[b] (get_demsup_self_cur IN id_trn_date)
        OPEN  get_demsup_self_cur(id_trn_date);
        FETCH get_demsup_self_cur INTO ln_demsup_self_trn;
        CLOSE get_demsup_self_cur;
--
        --自分の需給数[b'](get_demsup_self_cur IN id_max_date)
        OPEN  get_demsup_self_cur(id_max_date);
        FETCH get_demsup_self_cur INTO ln_demsup_self_max;
        CLOSE get_demsup_self_cur;
--
        -- 少ない方が引当可能数( b <= b' ==> b を採用)
        IF (ln_demsup_self_trn <= ln_demsup_self_max) THEN
          ln_ret_qty := ln_demsup_self_trn;
        -- 少ない方が引当可能数( b > b' ==> b' を採用)
        ELSE
          ln_ret_qty := ln_demsup_self_max;
        END IF;
--
      --代表倉庫:親の場合
      ELSIF (it_loc_code = it_head_loc) THEN
--
        --代表倉庫親以外の在庫数[c]
        OPEN  get_stock_child_cur;
        FETCH get_stock_child_cur INTO ln_stock_other;
        CLOSE get_stock_child_cur;
--
        --代表倉庫配下の需給数[d] (get_demsup_all_cur IN id_trn_date)
        OPEN  get_demsup_all_cur(id_trn_date);
        FETCH get_demsup_all_cur INTO ln_demsup_all_trn;
        CLOSE get_demsup_all_cur;
--
        --代表倉庫配下の需給数[d'](get_demsup_all_cur IN id_max_date)
        OPEN  get_demsup_all_cur(id_max_date);
        FETCH get_demsup_all_cur INTO ln_demsup_all_max;
        CLOSE get_demsup_all_cur;
--
        -- 少ない方が引当可能数( d <= d' ==> d を採用)
        IF (ln_demsup_all_trn <= ln_demsup_all_max) THEN
          ln_ret_qty := ln_stock_other + ln_demsup_all_trn;
        -- 少ない方が引当可能数( d > d' ==> d' を採用)
        ELSE
          ln_ret_qty := ln_stock_other + ln_demsup_all_max;
        END IF;
--
      --代表倉庫:子の場合
      ELSE
--
        --自分の需給数[b] (get_demsup_self_cur IN id_trn_date)
        OPEN  get_demsup_self_cur(id_trn_date);
        FETCH get_demsup_self_cur INTO ln_demsup_self_trn;
        CLOSE get_demsup_self_cur;
--
        --自分の需給数[b'](get_demsup_self_cur IN id_max_date)
        OPEN  get_demsup_self_cur(id_max_date);
        FETCH get_demsup_self_cur INTO ln_demsup_self_max;
        CLOSE get_demsup_self_cur;
--
        --代表倉庫がダミーの場合、倉庫品目マスタ参照
        IF (it_head_loc = it_dummy_loc) THEN
--
          --在庫数
          OPEN  get_stock_dummy_cur;
          FETCH get_stock_dummy_cur INTO ln_stock_other;
          CLOSE get_stock_dummy_cur;
--
          --需給数
          OPEN  get_demsup_dummy_cur(id_trn_date);
          FETCH get_demsup_dummy_cur INTO ln_demsup_parent_trn;
          CLOSE get_demsup_dummy_cur;
--
          --需給数
          OPEN  get_demsup_dummy_cur(id_max_date);
          FETCH get_demsup_dummy_cur INTO ln_demsup_parent_max;
          CLOSE get_demsup_dummy_cur;
--
        ELSE
--
          --在庫数
          OPEN  get_stock_parent_cur;
          FETCH get_stock_parent_cur INTO ln_stock_other;
          CLOSE get_stock_parent_cur;
--
          --需給数
          OPEN  get_demsup_parent_cur(id_trn_date);
          FETCH get_demsup_parent_cur INTO ln_demsup_parent_trn;
          CLOSE get_demsup_parent_cur;
--
          --需給数
          OPEN  get_demsup_parent_cur(id_max_date);
          FETCH get_demsup_parent_cur INTO ln_demsup_parent_max;
          CLOSE get_demsup_parent_cur;
--
        END IF;
--
-- 20081226 M.Hokkanji Start
--        IF (ln_demsup_parent_trn < 0) THEN
        IF ((ln_demsup_parent_trn + ln_stock_other) < 0) THEN
--          ln_demsup_self_trn := ln_demsup_self_trn + ln_demsup_parent_trn;
          ln_demsup_self_trn := ln_demsup_self_trn + ln_stock_other + ln_demsup_parent_trn;
-- 20081226 M.Hokkanji End
        END IF;
--
-- 20081226 M.Hokkanji Start
--        IF (ln_demsup_parent_max < 0) THEN
        IF ((ln_demsup_parent_max + ln_stock_other) < 0) THEN
--          ln_demsup_self_max := ln_demsup_self_max + ln_demsup_parent_max;
          ln_demsup_self_max := ln_demsup_self_max + ln_stock_other + ln_demsup_parent_max;
-- 20081226 M.Hokkanji End
        END IF;
--
        -- 少ない方が引当可能数
        IF (ln_demsup_self_trn <= ln_demsup_self_max) THEN
-- 20081226 M.Hokkanji Start
--          ln_ret_qty := ln_stock_other + ln_demsup_self_trn;
          ln_ret_qty := ln_demsup_self_trn;
-- 20081226 M.Hokkanji End
        -- 少ない方が引当可能数
        ELSE
-- 20081226 M.Hokkanji Start
--          ln_ret_qty := ln_stock_other + ln_demsup_self_max;
          ln_ret_qty := ln_demsup_self_max;
-- 20081226 M.Hokkanji End
        END IF;
--
      END IF;
--



    END IF;
--
    RETURN ln_ret_qty;
--
  EXCEPTION
    WHEN OTHERS THEN
      IF (get_demsup_self_cur%ISOPEN) THEN
        CLOSE get_demsup_self_cur;
      END IF;
      IF (get_stock_child_cur%ISOPEN) THEN
        CLOSE get_stock_child_cur;
      END IF;
      IF (get_demsup_all_cur%ISOPEN) THEN
        CLOSE get_demsup_all_cur;
      END IF;
      IF (get_stock_dummy_cur%ISOPEN) THEN
        CLOSE get_stock_dummy_cur;
      END IF;
      IF (get_demsup_dummy_cur%ISOPEN) THEN
        CLOSE get_demsup_dummy_cur;
      END IF;
      IF (get_stock_parent_cur%ISOPEN) THEN
        CLOSE get_stock_parent_cur;
      END IF;
      IF (get_demsup_parent_cur%ISOPEN) THEN
        CLOSE get_demsup_parent_cur;
      END IF;
  END get_demsup_qty;
--
  FUNCTION get_stock_qty(it_item_id IN ic_item_mst_b.item_id%TYPE
                        ,it_lot_ctl IN ic_item_mst_b.lot_ctl%TYPE
                        ,it_lot_id  IN ic_lots_mst.lot_id%TYPE
                        ,it_loc_id  IN mtl_item_locations.inventory_location_id%TYPE) RETURN NUMBER
  AS
    ln_ret_qty NUMBER;
  BEGIN
--
    --ロット管理品の場合
    IF (it_lot_ctl = 1) THEN
--
      SELECT
          ( -- I0)EBS手持在庫取得
-- mod ohashi start
--          SELECT NVL(ili.loct_onhand,0)
          SELECT NVL(SUM(ili.loct_onhand),0)
-- mod ohashi end
          FROM   ic_loct_inv ili
                ,mtl_item_locations mil
          WHERE  ili.item_id               = it_item_id
          AND    ili.lot_id                = it_lot_id
          AND    ili.location              = mil.segment1
          AND    mil.inventory_location_id = it_loc_id
          ) + 
          ( -- I1)実績未取在庫数  移動入庫（入出庫報告有）
            -- I2)実績未取在庫数  移動入庫（入庫報告有）
          SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
                 ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--                 ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
                 ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
          WHERE   mrih.ship_to_locat_id   = it_loc_id
          AND     mrih.comp_actual_flg    = cv_flag_n
          AND     mrih.status            IN (cv_status_05,cv_status_06)
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = cv_flag_n
          AND     mld.item_id             = it_item_id
          AND     mld.lot_id              = it_lot_id
          AND     mld.document_type_code  = cv_doc_type_20
          AND     mld.record_type_code    = cv_rec_type_30
          ) - 
          ( -- I3)実績未取在庫数  移動出庫（入出庫報告有）
            -- I4)実績未取在庫数  移動出庫（出庫報告有）
          SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
                 ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--                 ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
                 ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
          WHERE   mrih.shipped_locat_id   = it_loc_id
          AND     mrih.comp_actual_flg    = cv_flag_n
          AND     mrih.status            IN (cv_status_04,cv_status_06)
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = cv_flag_n
          AND     mld.item_id             = it_item_id
          AND     mld.lot_id              = it_lot_id
          AND     mld.document_type_code  = cv_doc_type_20
          AND     mld.record_type_code    = cv_rec_type_20
          ) - 
          ( -- I5)実績未取在庫数  出荷
          SELECT  NVL(
                    SUM(
                      CASE otta.order_category_code
                      WHEN 'ORDER' THEN
                        NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                      WHEN 'RETURN' THEN
                        (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                      END),0)
          FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
                 ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--                 ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
                 ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
                 ,oe_transaction_types_all   otta -- 受注タイプ
          WHERE   oha.deliver_from_id       = it_loc_id
          AND     oha.req_status            = cv_status_04
          AND     oha.actual_confirm_class  = cv_flag_n
          AND     oha.latest_external_flag  = cv_flag_y
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = cv_flag_n
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.item_id               = it_item_id
          AND     mld.lot_id                = it_lot_id
          AND     mld.document_type_code    = cv_doc_type_10
          AND     mld.record_type_code      = cv_rec_type_20
          AND     otta.attribute1           IN (cv_type_1,cv_type_3)
          AND     otta.transaction_type_id  = oha.order_type_id
          ) - 
          ( -- I6)実績未取在庫数  支給
          SELECT  NVL(
                    SUM(
                      CASE otta.order_category_code
                      WHEN 'ORDER' THEN
                        NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                      WHEN 'RETURN' THEN
                        (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                      END),0)
          FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
                 ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--                 ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
                 ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
                 ,oe_transaction_types_all   otta   -- 受注タイプ
          WHERE   oha.deliver_from_id       = it_loc_id
          AND     oha.req_status            = cv_status_08
          AND     oha.actual_confirm_class  = cv_flag_n
          AND     oha.latest_external_flag  = cv_flag_y
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = cv_flag_n
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.item_id               = it_item_id
          AND     mld.lot_id                = it_lot_id
          AND     mld.document_type_code    = cv_doc_type_30
          AND     mld.record_type_code      = cv_rec_type_20
          AND     otta.attribute1           = cv_type_2
          AND     otta.transaction_type_id  = oha.order_type_id
          ) + 
          ( -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
          SELECT  NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
          FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
                 ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--                 ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
                 ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
          WHERE   mrih.ship_to_locat_id   = it_loc_id
          AND     mrih.comp_actual_flg    = cv_flag_y
          AND     mrih.correct_actual_flg = cv_flag_y
          AND     mrih.status             = cv_status_06
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = cv_flag_n
          AND     mld.item_id             = it_item_id
          AND     mld.lot_id              = it_lot_id
          AND     mld.document_type_code  = cv_doc_type_20
          AND     mld.record_type_code    = cv_rec_type_30
          ) + 
          ( -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
          SELECT  NVL(SUM(mld.before_actual_quantity),0) - NVL(SUM(mld.actual_quantity),0)
          FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
                 ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.4 H.Itou Mod Start
--                 ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
                 ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.4 H.Itou Mod End
          WHERE   mrih.shipped_locat_id   = it_loc_id
          AND     mrih.comp_actual_flg    = cv_flag_y
          AND     mrih.correct_actual_flg = cv_flag_y
          AND     mrih.status             = cv_status_06
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = cv_flag_n
          AND     mld.item_id             = it_item_id
          AND     mld.lot_id              = it_lot_id
          AND     mld.document_type_code  = cv_doc_type_20
          AND     mld.record_type_code    = cv_rec_type_20
          ) stock_qty
      INTO   ln_ret_qty
      FROM   DUAL
      ;


--
    END IF;
--
    RETURN ln_ret_qty;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ln_ret_qty := 0;
      RETURN ln_ret_qty;
  END get_stock_qty;
--
END xxwsh_common_get_qty_pkg;
/

