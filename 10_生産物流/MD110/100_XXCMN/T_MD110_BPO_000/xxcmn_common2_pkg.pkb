CREATE OR REPLACE PACKAGE BODY xxcmn_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxcmn_common2_pkg(BODY)
 * Description            : 共通関数2(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_000_引当可能数算出（補足資料）.doc
 * Version                : 1.19
 *
 * Program List
 *  ---------------------------- ---- ----- --------------------------------------------------
 *   Name                        Type  Ret   Description
 *  ---------------------------- ---- ----- --------------------------------------------------
 *  get_inv_onhand_lot            p   なし  ロット    I0  EBS手持在庫
 *  get_inv_lot_in_inout_rpt_qty  p   なし  ロット    I1  実績未取在庫数  移動入庫（入出庫報告有）
 *  get_inv_lot_in_in_rpt_qty     p   なし  ロット    I2  実績未取在庫数  移動入庫（入庫報告有）
 *  get_inv_lot_out_inout_rpt_qty p   なし  ロット    I3  実績未取在庫数  移動出庫（入出庫報告有）
 *  get_inv_lot_out_out_rpt_qty   p   なし  ロット    I4  実績未取在庫数  移動出庫（出庫報告有）
 *  get_inv_lot_ship_qty          p   なし  ロット    I5  実績未取在庫数  出荷
 *  get_inv_lot_provide_qty       p   なし  ロット    I6  実績未取在庫数  支給
 *  get_inv_lot_in_inout_cor_qty  P   なし  ロット    I7  実績未取在庫数  移動入庫訂正（入出庫報告有）
 *  get_inv_lot_out_inout_cor_qty P   なし  ロット    I8  実績未取在庫数  移動出庫訂正（入出庫報告有）
 *  get_sup_lot_inv_in_qty        p   なし  ロット    S1  供給数  移動入庫予定
 *  get_sup_lot_order_qty         p   なし  ロット    S2  供給数  発注受入予定
 *  get_sup_lot_produce_qty       p   なし  ロット    S3  供給数  生産入庫予定
 *  get_sup_lot_inv_out_qty       p   なし  ロット    S4  供給数  実績計上済の移動出庫実績
 *  get_dem_lot_ship_qty          p   なし  ロット    D1  需要数  実績未計上の出荷依頼（IDベース）
 *  get_dem_lot_ship_qty2         p   なし  ロット    D1  需要数  実績未計上の出荷依頼（CODEベース）
 *  get_dem_lot_provide_qty       p   なし  ロット    D2  需要数  実績未計上の支給指示（IDベース）
 *  get_dem_lot_provide_qty2      p   なし  ロット    D2  需要数  実績未計上の支給指示（CODEベース）
 *  get_dem_lot_inv_out_qty       p   なし  ロット    D3  需要数  実績未計上の移動指示
 *  get_dem_lot_inv_in_qty        p   なし  ロット    D4  需要数  実績計上済の移動入庫実績
 *  get_dem_lot_produce_qty       p   なし  ロット    D5  需要数  実績未計上の生産投入予定
 *  get_dem_lot_order_qty         p   なし  ロット    D6  需要数  実績未計上の相手先倉庫発注入庫予定
 *  get_inv_onhand                p   なし  非ロット  I0  EBS手持在庫
 *  get_inv_in_inout_rpt_qty      p   なし  非ロット  I1  実績未取在庫数  移動入庫（入出庫報告有）
 *  get_inv_in_in_rpt_qty         p   なし  非ロット  I2  実績未取在庫数  移動入庫（入庫報告有）
 *  get_inv_out_inout_rpt_qty     p   なし  非ロット  I3  実績未取在庫数  移動出庫（入出庫報告有）
 *  get_inv_out_out_rpt_qty       p   なし  非ロット  I4  実績未取在庫数  移動出庫（出庫報告有）
 *  get_inv_ship_qty              p   なし  非ロット  I5  実績未取在庫数  出荷
 *  get_inv_provide_qty           p   なし  非ロット  I6  実績未取在庫数  支給
 *  get_inv_in_inout_cor_qty      P   なし  非ロット  I7  実績未取在庫数  移動入庫訂正（入出庫報告有）
 *  get_inv_out_inout_cor_qty     P   なし  非ロット  I8  実績未取在庫数  移動出庫訂正（入出庫報告有）
 *  get_sup_inv_in_qty            p   なし  非ロット  S1  供給数  移動入庫予定
 *  get_sup_order_qty             p   なし  非ロット  S2  供給数  発注受入予定
 *  get_sup_inv_out_qty           p   なし  非ロット  S4  供給数  実績計上済の移動出庫実績
 *  get_dem_ship_qty              p   なし  非ロット  D1  需要数  実績未計上の出荷依頼
 *  get_dem_provide_qty           p   なし  非ロット  D2  需要数  実績未計上の支給指示
 *  get_dem_inv_out_qty           p   なし  非ロット  D3  需要数  実績未計上の移動指示
 *  get_dem_inv_in_qty            p   なし  非ロット  D4  需要数  実績計上済の移動入庫実績
 *  get_dem_produce_qty           p   なし  非ロット  D5  需要数  実績未計上の生産投入予定
 *  get_can_enc_total_qty         F   NUM   総引当可能数算出API(廃止：有効日ベース引当可能数算出APIで代用)
 *  get_can_enc_in_time_qty       F   NUM   有効日ベース引当可能数算出API
 *  get_stock_qty                 F   NUM   手持在庫数量算出API
 *  get_can_enc_qty               F   NUM   引当可能数算出API
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2007/12/26   1.0   oracle 丸下     新規作成
 *
 *  2008/02/04   抽出元のテーブルは、ビューを使用しない事とする。
 *  2008/04/03   1.1   oracle 丸下     内部変更要求#32 get_stock_qty修正
 *  2008/05/22   1.2   oracle 椎名     内部変更要求#98対応
 *  2008/06/19   1.3   oracle 吉田     結合テスト不具合対応(D6 引数設定の変数(品目コード)変更)
 *  2008/06/24   1.4   oracle 竹本     結合テスト不具合対応(I5,I6 引数設定の変数(品目コード)変更)
 *  2008/06/24   1.4   oracle 新藤     システムテスト不具合対応#75(D5)
 *  2008/07/16   1.5   oracle 北寒寺   変更要求#93対応
 *  2008/07/25   1.6   oracle 北寒寺   結合テスト不具合対応
 *  2008/09/09   1.7   oracle 椎名     PT 6-1_28 指摘44 対応
 *  2008/09/09   1.8   oracle 椎名     PT 6-1_28 指摘44 修正
 *  2008/09/11   1.9   oracle 椎名     PT 6-1_28 指摘73 対応
 *  2008/07/18   1.10  oracle 北寒寺   TE080_BPO540指摘5対応
 *  2008/09/16   1.11  oracle 椎名     TE080_BPO540指摘5修正
 *  2008/09/17   1.12  oracle 椎名     PT 6-1_28 指摘73 追加修正
 *  2008/11/19   1.13  oracle 伊藤     統合障害#681修正
 *  2008/12/02   1.14  oracle 二瓶     本番障害#251対応（条件追加) 
 *  2008/12/15   1.15  oracle 伊藤     本番障害#645対応 D4,S4 予定日でなく実績日で取得する。
 *  2008/12/18   1.16  oracle 伊藤     本番障害#648対応 I5,I6 訂正前数量 - 実績数量を返す。
 *  2008/12/24   1.17  oracle 山本     本番障害#836対応 S3    生産入庫予定抽出条件追加
 *  2009/03/31   1.18  野村            本番障害#1346対応
 *  2010/02/23   1.19  SCS伊藤         E_本稼動_01612対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcmn_common2_pkg'; -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : get_inv_onhand_lot
   * Description      : ロット I0)EBS手持在庫取得プロシージャ
   ***********************************************************************************/
  PROCEDURE get_inv_onhand_lot(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_whse_id     OUT NOCOPY NUMBER,       -- 保管倉庫ID
    on_item_id     OUT NOCOPY NUMBER,       -- 品目ID
    on_lot_id      OUT NOCOPY NUMBER,       -- ロットID
    on_onhand      OUT NOCOPY NUMBER,       -- 手持数量
    ov_whse_code   OUT NOCOPY VARCHAR2,     -- 保管倉庫コード
    ov_rep_whse    OUT NOCOPY VARCHAR2,     -- 代表倉庫
    ov_item_code   OUT NOCOPY VARCHAR2,     -- 品目コード
    ov_lot_no      OUT NOCOPY VARCHAR2,     -- ロットNO
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_onhand_lot'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT mst_data.whse_code,
           mst_data.rep_wheh,
           mst_data.wheh_code,
           mst_data.item_id,
           mst_data.item_no,
           mst_data.lot_no,
           mst_data.lot_id,
           NVL(ili.loct_onhand,0)
    INTO ov_whse_code,
         ov_rep_whse,
         on_whse_id,
         on_item_id,
         ov_item_code,
         ov_lot_no,
         on_lot_id,
         on_onhand
    FROM
    (
      SELECT  mil.segment1                AS whse_code,
              mil.attribute5              AS rep_wheh,
              mil.inventory_location_id   AS wheh_code,
              iimb.item_id                AS item_id,
              iimb.item_no                AS item_no,
              ilm.lot_id                  AS lot_id,
              ilm.lot_no                  AS lot_no
      FROM  ic_item_mst_b       iimb,   -- OPM品目マスタ
            ic_lots_mst         ilm,    -- OPMロットマスタ
            mtl_item_locations  mil,    -- 保管場所
            ic_whse_mst         iwm     -- 倉庫
      WHERE iimb.item_id              = in_item_id
      AND   ilm.item_id               = iimb.item_id
      AND   ilm.lot_id                = in_lot_id
      AND   mil.inventory_location_id = in_whse_id
      AND   mil.organization_id       = iwm.mtl_organization_id
    ) mst_data,
      ic_loct_inv ili  -- 手持数量
    WHERE mst_data.whse_code  = ili.location(+)
    AND   mst_data.item_id    = ili.item_id(+)
    AND   mst_data.lot_id     = ili.lot_id(+) ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_error;
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_onhand_lot;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_in_inout_rpt_qty
   * Description      : ロット I1)実績未取在庫数  移動入庫（入出庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_lot_in_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_in_inout_rpt_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '30';  -- 入庫実績
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- 入出庫報告有
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
              NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/17 v1.12 UPDATE End 
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_lot_in_inout_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_in_in_rpt_qty
   * Description      : ロット I2)実績未取在庫数  移動入庫（入庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_lot_in_in_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_in_in_rpt_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '30';  -- 入庫実績
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '05';  -- 入庫報告有
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/17 v1.12 UPDATE End 
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_lot_in_in_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_out_inout_rpt_qty
   * Description      : ロット I3)実績未取在庫数  移動出庫（入出庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_lot_out_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_out_inout_rpt_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '20';  -- 出庫実績
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- 入出庫報告有
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/17 v1.12 UPDATE End 
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_lot_out_inout_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_out_out_rpt_qty
   * Description      : ロット I4)実績未取在庫数  移動出庫（出庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_lot_out_out_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_out_out_rpt_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '20';  -- 出庫実績
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '04';  -- 出庫報告有
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/17 v1.12 UPDATE End 
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_lot_out_out_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_ship_qty
   * Description      : ロット I5)実績未取在庫数  出荷
   ***********************************************************************************/
  PROCEDURE get_inv_lot_ship_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_ship_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off       CONSTANT VARCHAR2(1)  := 'N';       -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1)  := 'Y';       -- ON
    cv_req_status     CONSTANT VARCHAR2(2)  := '04';      -- 出荷実績計上済
    cv_doc_type       CONSTANT VARCHAR2(2)  := '10';      -- 出荷依頼
    cv_rec_type       CONSTANT VARCHAR2(2)  := '20';      -- 出庫実績
    cv_ship_pro_type  CONSTANT VARCHAR2(1)  := '1';       -- 出荷依頼
    cv_warehouse_type CONSTANT VARCHAR2(1)  := '3';       -- 倉替
    cv_cate_order     CONSTANT VARCHAR2(10) := 'ORDER';   -- 受注
    cv_cate_return    CONSTANT VARCHAR2(10) := 'RETURN';  -- 返品
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(CASE
    SELECT  /*+ leading(oha otta ola mld) */
            NVL(SUM(CASE
-- 2008/09/17 v1.12 UPDATE End 
                      WHEN (otta.order_category_code = cv_cate_order) THEN
-- 2008/12/18 H.Itou Mod Start 本番障害#648
--                        mld.actual_quantity
                        NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
-- 2008/12/18 H.Itou Mod End
                      WHEN (otta.order_category_code = cv_cate_return) THEN
-- 2008/12/18 H.Itou Mod Start 本番障害#648
--                        mld.actual_quantity * -1
                       (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
-- 2008/12/18 H.Itou Mod End
                    END), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v   mld,   -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     mld.item_id               = in_item_id
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           IN (cv_ship_pro_type, cv_warehouse_type)
    AND     otta.transaction_type_id  = oha.order_type_id
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_lot_ship_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_provide_qty
   * Description      : ロット I6)実績未取在庫数  支給
   ***********************************************************************************/
  PROCEDURE get_inv_lot_provide_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_provide_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off       CONSTANT VARCHAR2(1)  := 'N';       -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1)  := 'Y';       -- ON
    cv_req_status     CONSTANT VARCHAR2(2)  := '08';      -- 出荷実績計上済
    cv_doc_type       CONSTANT VARCHAR2(2)  := '30';      -- 支給指示
    cv_rec_type       CONSTANT VARCHAR2(2)  := '20';      -- 出庫実績
    cv_ship_pro_type  CONSTANT VARCHAR2(1)  := '2';       -- 支給依頼
    cv_cate_order     CONSTANT VARCHAR2(10) := 'ORDER';   -- 受注
    cv_cate_return    CONSTANT VARCHAR2(10) := 'RETURN';  -- 返品
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(CASE
    SELECT  /*+ leading(oha otta ola mld) */
            NVL(SUM(CASE
-- 2008/09/17 v1.12 UPDATE End 
                      WHEN (otta.order_category_code = cv_cate_order) THEN
-- 2008/12/18 H.Itou Mod Start 本番障害#648
--                        mld.actual_quantity
                        NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
-- 2008/12/18 H.Itou Mod End
                      WHEN (otta.order_category_code = cv_cate_return) THEN
-- 2008/12/18 H.Itou Mod Start 本番障害#648
--                        mld.actual_quantity * -1
                       (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
-- 2008/12/18 H.Itou Mod End
                    END), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v    mld,  -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     mld.item_id               = in_item_id
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_lot_provide_qty;
--
-- Ver1.10 M.Hokkanji Start
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_in_inout_cor_qty
   * Description      : ロット I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_lot_in_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_before_qty  OUT NOCOPY NUMBER,       -- 訂正前数量
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_in_inout_cor_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '30';  -- 入庫実績
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on     CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- 入出庫報告有
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.before_actual_quantity),0),
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.before_actual_quantity),0),
-- 2008/09/17 v1.12 UPDATE End 
-- 2008/09/16 v1.11 UPDATE START
--            NVL(SUM(mril.ship_to_quantity),0)
            NVL(SUM(mld.actual_quantity),0)
-- 2008/09/16 v1.11 UPDATE END
    INTO    on_before_qty,
            on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_on
    AND     mrih.correct_actual_flg = cv_flag_on
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_lot_in_inout_cor_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_out_inout_cor_qty
   * Description      : ロット I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_lot_out_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_before_qty  OUT NOCOPY NUMBER,       -- 訂正前数量
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_out_inout_cor_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '20';  -- 出庫実績
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on     CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- 入出庫報告有
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.before_actual_quantity),0),
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.before_actual_quantity),0),
-- 2008/09/17 v1.12 UPDATE End 
-- 2008/09/16 v1.11 UPDATE START
--            NVL(SUM(mril.ship_to_quantity),0)
            NVL(SUM(mld.actual_quantity),0)
-- 2008/09/16 v1.11 UPDATE END
    INTO    on_before_qty,
            on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_on
    and     mrih.correct_actual_flg = cv_flag_on
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_lot_out_inout_cor_qty;
-- Ver1.10 M.Hokkanji End
--
  /**********************************************************************************
   * Procedure Name   : get_sup_lot_inv_in_qty
   * Description      : ロット S1)供給数  移動入庫予定
   ***********************************************************************************/
  PROCEDURE get_sup_lot_inv_in_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_lot_inv_in_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '10';  -- 指示
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status_req_fin CONSTANT VARCHAR2(2) := '02';  -- 依頼済み
    cv_move_status_adjust  CONSTANT VARCHAR2(2) := '03';  -- 調整中
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/17 v1.12 UPDATE End 
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status
              IN (cv_move_status_req_fin, cv_move_status_adjust)
    AND     mrih.schedule_arrival_date  <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sup_lot_inv_in_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_lot_order_qty
   * Description      : ロット S2)供給数  発注受入予定
   ***********************************************************************************/
  PROCEDURE get_sup_lot_order_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    iv_item_code   IN VARCHAR2,             -- 品目コード
    iv_lot_no      IN VARCHAR2,             -- ロットNO
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_lot_order_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_po_status_order_fin  CONSTANT VARCHAR2(2) := '20';  -- 発注作成済
    cv_po_status_accept     CONSTANT VARCHAR2(2) := '25';  -- 受入あり
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(pla.quantity), 0)
    INTO    on_qty
    FROM    mtl_system_items_b msib,
            po_lines_all       pla,
            po_headers_all     pha
    WHERE   msib.segment1          = iv_item_code
    AND     msib.organization_id   = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id = pla.item_id
    AND     pla.attribute1         = iv_lot_no
    AND     pla.attribute13        = cv_flag_off -- 数量確定フラグ
    AND     pla.cancel_flag        = cv_flag_off
    AND     pla.po_header_id       = pha.po_header_id
    AND     pha.attribute1        IN (cv_po_status_order_fin, cv_po_status_accept)
    AND     pha.attribute5         = iv_whse_code
    AND     pha.attribute4        <= TO_CHAR(id_eff_date, 'YYYY/MM/DD') -- 納入日
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     pha.org_id             = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sup_lot_order_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_lot_produce_qty
   * Description      : ロット S3)供給数  生産入庫予定
   ***********************************************************************************/
  PROCEDURE get_sup_lot_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_lot_produce_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cn_batch_status_wip     CONSTANT NUMBER(5,0) := 2;     -- WIP
    cn_batch_status_reserv  CONSTANT NUMBER(5,0) := 1;     -- 保留
    cn_line_type_product    CONSTANT NUMBER(5,0) := 1;     -- 完成品
    cn_line_type_byproduct  CONSTANT NUMBER(5,0) := 2;     -- 副産物
    cv_doc_type             CONSTANT VARCHAR2(2) := '40';  -- 生産指示
    cv_rec_type             CONSTANT VARCHAR2(2) := '10';  -- 指示
    ln_not_yet              CONSTANT NUMBER(1,0) := 0;     -- 未決定
    lv_tran_doc_type        CONSTANT VARCHAR2(4) := 'PROD';
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    gme_batch_header      gbh, -- 生産バッチ
            gme_material_details  gmd, -- 生産原料詳細
            ic_tran_pnd           itp, -- OPM保留在庫トランザクション
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld,     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v  mld,     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
            gmd_routings_b        grb  -- 工順マスタ
    WHERE   gbh.batch_status      IN (cn_batch_status_wip, cn_batch_status_reserv)
    AND     gbh.plan_start_date   <= id_eff_date
    AND     gbh.batch_id           = gmd.batch_id
    AND     gmd.line_type         IN (cn_line_type_product, cn_line_type_byproduct)
    AND     gmd.item_id            = in_item_id
    AND     gmd.material_detail_id = itp.line_id
    AND     itp.completed_ind      = ln_not_yet        -- 未決定
    AND     itp.doc_type           = lv_tran_doc_type
    AND     itp.lot_id             = in_lot_id
-- 2008/12/18 v1.17 Y.Yamamoto add start 本番障害#836
    AND     itp.delete_mark        = 0
-- 2008/12/18 v1.17 Y.Yamamoto add end   本番障害#836
    AND     gmd.material_detail_id = mld.mov_line_id
    AND     mld.document_type_code = cv_doc_type
    AND     mld.record_type_code   = cv_rec_type
    AND     gbh.routing_id         = grb.routing_id
    AND     grb.attribute9         = iv_whse_code       -- 納品場所
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sup_lot_produce_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_lot_inv_out_qty
   * Description      : ロット S4)供給数  実績計上済の移動出庫実績
   ***********************************************************************************/
  PROCEDURE get_sup_lot_inv_out_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_lot_inv_out_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '20';  -- 出庫実績
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '04';  -- 出庫報告あり
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/17 v1.12 UPDATE End 
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v       mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
-- 2008/12/15 H.Itou Mod Start 本番障害#645
--    AND     mrih.schedule_arrival_date  <= id_eff_date
    AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_eff_date
-- 2008/12/15 H.Itou Mod End
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sup_lot_inv_out_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_ship_qty
   * Description      : ロット D1)需要数  実績未計上の出荷依頼
   ***********************************************************************************/
  PROCEDURE get_dem_lot_ship_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
-- 2008/09/10 v1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    in_item_id     IN NUMBER,               -- 品目ID
    in_item_code   IN VARCHAR2,               -- 品目
-- 2008/09/09 v1.7 UPDATE END
*/
    in_item_id     IN NUMBER,               -- 品目ID
-- 2008/09/10 v1.8 UPDATE END
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_ship_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '03';  -- 締め済み
    cv_doc_type       CONSTANT VARCHAR2(2) := '10';  -- 出荷依頼
    cv_rec_type       CONSTANT VARCHAR2(2) := '10';  -- 指示
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '1';   -- 出荷依頼
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(oha otta ola mld) */
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/17 v1.12 UPDATE End 
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld,  -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v    mld,  -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
-- 2008/09/10 v1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    AND     mld.item_id               = in_item_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = in_item_code
-- 2008/09/09 v1.7 UPDATE END
*/
    AND     mld.item_id               = in_item_id
-- 2008/09/10 v1.8 UPDATE END
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_lot_ship_qty;
--
-- 2008/09/10 v1.8 ADD START
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_ship_qty2
   * Description      : ロット D1)需要数  実績未計上の出荷依頼（CODEベース）
   ***********************************************************************************/
  PROCEDURE get_dem_lot_ship_qty2(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_code   IN VARCHAR2,             -- 品目
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_ship_qty2'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '03';  -- 締め済み
    cv_doc_type       CONSTANT VARCHAR2(2) := '10';  -- 出荷依頼
    cv_rec_type       CONSTANT VARCHAR2(2) := '10';  -- 指示
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '1';   -- 出荷依頼
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/11 v1.9 UPDATE START
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(oha otta ola mld) */ 
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/11 v1.9 UPDATE END
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details    mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v    mld,  -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = in_item_code
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_lot_ship_qty2;
--
-- 2008/09/10 v1.8 ADD END
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_provide_qty
   * Description      : ロット D2)需要数  実績未計上の支給指示
   ***********************************************************************************/
  PROCEDURE get_dem_lot_provide_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
-- 2008/09/10 v1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    in_item_id     IN NUMBER,               -- 品目ID
    in_item_code   IN VARCHAR2,               -- 品目
-- 2008/09/09 v1.7 UPDATE END
*/
    in_item_id     IN NUMBER,               -- 品目ID
-- 2008/09/10 v1.8 UPDATE END
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_provide_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '07';  -- 受領済み
    cv_doc_type       CONSTANT VARCHAR2(2) := '30';  -- 支給指示
    cv_rec_type       CONSTANT VARCHAR2(2) := '10';  -- 指示
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '2';   -- 支給依頼
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(oha otta ola mld) */
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/17 v1.12 UPDATE End 
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld,  -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v    mld,  -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
-- 2008/09/10 v1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    AND     mld.item_id               = in_item_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = in_item_code
-- 2008/09/09 v1.7 UPDATE END
*/
    AND     mld.item_id               = in_item_id
-- 2008/09/10 v1.8 UPDATE END
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_lot_provide_qty;
--
-- 2008/09/10 v1.8 ADD START
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_provide_qty2
   * Description      : ロット D2)需要数  実績未計上の支給指示（CODEベース）
   ***********************************************************************************/
  PROCEDURE get_dem_lot_provide_qty2(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_code   IN VARCHAR2,             -- 品目
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_provide_qty2'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '07';  -- 受領済み
    cv_doc_type       CONSTANT VARCHAR2(2) := '30';  -- 支給指示
    cv_rec_type       CONSTANT VARCHAR2(2) := '10';  -- 指示
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '2';   -- 支給依頼
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/11 v1.9 UPDATE START
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(oha otta ola mld) */ 
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/11 v1.9 UPDATE END
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details    mld,    -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v    mld,  -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = in_item_code
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_lot_provide_qty2;
--
-- 2008/09/10 v1.8 ADD END
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_inv_out_qty
   * Description      : ロット D3)需要数  実績未計上の移動指示
   ***********************************************************************************/
  PROCEDURE get_dem_lot_inv_out_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_inv_out_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '10';  -- 指示
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status_req_fin CONSTANT VARCHAR2(2) := '02';  -- 依頼済み
    cv_move_status_adjust  CONSTANT VARCHAR2(2) := '03';  -- 調整中
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/17 v1.12 UPDATE End 
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status
              IN (cv_move_status_req_fin, cv_move_status_adjust)
    AND     mrih.schedule_ship_date  <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_lot_inv_out_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_inv_in_qty
   * Description      : ロット D4)需要数  実績計上済の移動入庫実績
   ***********************************************************************************/
  PROCEDURE get_dem_lot_inv_in_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_inv_in_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル定数 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '30';  -- 入庫実績
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '05';  -- 入庫報告あり
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.actual_quantity), 0)
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
-- 2008/09/17 v1.12 UPDATE End 
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
-- 2008/12/15 H.Itou Mod Start 本番障害#645
--    AND     mrih.schedule_ship_date  <= id_eff_date
    AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_eff_date
-- 2008/12/15 H.Itou Mod End
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_lot_inv_in_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_produce_qty
   * Description      : ロット D5)需要数  実績未計上の生産投入予定
   ***********************************************************************************/
  PROCEDURE get_dem_lot_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_produce_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cn_batch_status_wip     CONSTANT NUMBER(5,0) := 2;     -- WIP
    cn_batch_status_reserv  CONSTANT NUMBER(5,0) := 1;     -- 保留
    cn_line_type            CONSTANT NUMBER(5,0) := -1;    -- 投入品
    cv_doc_type             CONSTANT VARCHAR2(2) := '40';  -- 生産指示
    cv_rec_type             CONSTANT VARCHAR2(2) := '10';  -- 指示
-- 2008/11/19 H.Itou Add Start 統合障害#681
    lv_tran_doc_type        CONSTANT VARCHAR2(4) := 'PROD';
-- 2008/11/19 H.Itou Add End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    gme_batch_header      gbh, -- 生産バッチ
            gme_material_details  gmd, -- 生産原料詳細
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details mld,  -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v mld,  -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
            gmd_routings_b        grb, -- 工順マスタ
            ic_tran_pnd           itp  -- 保留在庫トランザクション
    WHERE   gbh.batch_status      IN (cn_batch_status_wip, cn_batch_status_reserv)
    AND     gbh.plan_start_date   <= id_eff_date
    AND     gbh.batch_id           = gmd.batch_id
    AND     gmd.line_type          = cn_line_type
    AND     gmd.item_id            = in_item_id
    AND     gmd.material_detail_id = mld.mov_line_id
    AND     mld.lot_id             = in_lot_id
    AND     gbh.routing_id         = grb.routing_id
    AND     grb.attribute9         = iv_whse_code       -- 納品場所
    AND     mld.document_type_code = cv_doc_type
    AND     mld.record_type_code   = cv_rec_type
    AND     itp.line_id            = gmd.material_detail_id 
    AND     itp.item_id            = gmd.item_id
    AND     itp.lot_id             = mld.lot_id
-- 2008/11/19 H.Itou Add Start 統合障害#681
    AND     itp.doc_type           = lv_tran_doc_type
-- 2008/11/19 H.Itou Add End
-- 2008/12/02 v1.5 D.Nihei ADD START 統合障害#251
    AND     itp.delete_mark        = 0
-- 2008/12/02 v1.5 D.Nihei ADD END
    AND     itp.completed_ind      = 0
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_lot_produce_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_order_qty
   * Description      : ロット D6)需要数  実績未計上の相手先倉庫発注入庫予定
   ***********************************************************************************/
  PROCEDURE get_dem_lot_order_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    iv_item_code   IN VARCHAR2,             -- 品目コード
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_order_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_po_status_order_fin  CONSTANT VARCHAR2(2) := '20';  -- 発注作成済
    cv_po_status_accept     CONSTANT VARCHAR2(2) := '25';  -- 受入あり
    cv_doc_type             CONSTANT VARCHAR2(2) := '50';  -- 発注
    cv_rec_type             CONSTANT VARCHAR2(2) := '10';  -- 指示
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    mtl_system_items_b    msib,   -- 品目マスタ
            po_lines_all          pla,    -- 発注明細
            po_headers_all        pha,    -- 発注ヘッダ
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   msib.segment1          = iv_item_code
    AND     msib.organization_id   = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id = pla.item_id
    AND     pla.attribute13        = cv_flag_off  -- 数量確定フラグ
    AND     pla.cancel_flag        = cv_flag_off
    AND     pla.attribute12        = iv_whse_code -- 相手先在庫入庫先
    AND     pla.po_header_id       = pha.po_header_id
    AND     pha.attribute1        IN (cv_po_status_order_fin, cv_po_status_accept)
    AND     pha.attribute4        <= TO_CHAR(id_eff_date, 'YYYY/MM/DD') -- 納入日
    AND     pla.po_line_id         = mld.mov_line_id
    AND     mld.lot_id             = in_lot_id
    AND     mld.document_type_code = cv_doc_type
    AND     mld.record_type_code   = cv_rec_type
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     pha.org_id             = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_lot_order_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_onhand
   * Description      : 非ロット  I0)EBS手持在庫
   ***********************************************************************************/
  PROCEDURE get_inv_onhand(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_whse_id     OUT NOCOPY NUMBER,       -- 保管倉庫ID
    on_item_id     OUT NOCOPY NUMBER,       -- 品目ID
    on_onhand      OUT NOCOPY NUMBER,       -- 手持数量
    ov_whse_code   OUT NOCOPY VARCHAR2,     -- 保管倉庫コード
    ov_rep_whse    OUT NOCOPY VARCHAR2,     -- 代表倉庫
    ov_item_code   OUT NOCOPY VARCHAR2,     -- 品目コード
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_onhand'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ln_no_lot_ctl    CONSTANT NUMBER(1,0) := 0;   -- 非ロット管理
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT mst_data.whse_code,
           mst_data.rep_wheh,
           mst_data.wheh_code,
           mst_data.item_id,
           mst_data.item_no,
           NVL(ili.loct_onhand,0)
    INTO ov_whse_code,
         ov_rep_whse,
         on_whse_id,
         on_item_id,
         ov_item_code,
         on_onhand
    FROM
    (
      SELECT  mil.segment1                AS whse_code,
              mil.attribute5              AS rep_wheh,
              mil.inventory_location_id   AS wheh_code,
              iimb.item_id                AS item_id,
              iimb.item_no                AS item_no
      FROM  ic_item_mst_b       iimb,   -- OPM品目マスタ
            mtl_item_locations  mil,    -- 保管場所
            ic_whse_mst         iwm     -- 倉庫
      WHERE iimb.item_id              = in_item_id
      AND   iimb.lot_ctl              = ln_no_lot_ctl
      AND   mil.inventory_location_id = in_whse_id
      AND   mil.organization_id       = iwm.mtl_organization_id
    ) mst_data,
      ic_loct_inv ili  -- 手持数量
    WHERE mst_data.whse_code  = ili.location(+)
    AND   mst_data.item_id    = ili.item_id(+);
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_error;
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_onhand;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_in_inout_rpt_qty
   * Description      : 非ロット  I1)実績未取在庫数  移動入庫（入出庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_in_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_in_inout_rpt_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- 入出庫報告有
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.ship_to_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_in_inout_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_in_in_rpt_qty
   * Description      : 非ロット  I2)実績未取在庫数  移動入庫（入庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_in_in_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_in_in_rpt_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '05';  -- 入庫報告有
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.ship_to_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_in_in_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_out_inout_rpt_qty
   * Description      : 非ロット  I3)実績未取在庫数  移動出庫（入出庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_out_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_out_inout_rpt_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- 入出庫報告有
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.shipped_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_out_inout_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_out_out_rpt_qty
   * Description      : 非ロット  I4)実績未取在庫数  移動出庫（出庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_out_out_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_out_out_rpt_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '04';  -- 出庫報告有
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.shipped_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_out_out_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_ship_qty
   * Description      : 非ロット  I5  実績未取在庫数  出荷
   ***********************************************************************************/
  PROCEDURE get_inv_ship_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    iv_item_code   IN VARCHAR2,             -- 品目コード
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_ship_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off       CONSTANT VARCHAR2(1)  := 'N';       -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1)  := 'Y';       -- ON
    cv_req_status     CONSTANT VARCHAR2(2)  := '04';      -- 出荷実績計上済
-- 2008/12/18 H.Itou Add Start 本番障害#648
    cv_doc_type       CONSTANT VARCHAR2(2)  := '10';      -- 出荷依頼
    cv_rec_type       CONSTANT VARCHAR2(2)  := '20';      -- 出庫実績
-- 2008/12/18 H.Itou Add End
    cv_ship_pro_type  CONSTANT VARCHAR2(1)  := '1';       -- 出荷依頼
    cv_warehouse_type CONSTANT VARCHAR2(1)  := '3';       -- 倉替
    cv_cate_order     CONSTANT VARCHAR2(10) := 'ORDER';   -- 受注
    cv_cate_return    CONSTANT VARCHAR2(10) := 'RETURN';  -- 返品
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/12/18 H.Itou Mod Start 本番障害#648
--    SELECT  NVL(SUM(CASE
--                      WHEN (otta.order_category_code = cv_cate_order) THEN
--                        ola.shipped_quantity
--                      WHEN (otta.order_category_code = cv_cate_return) THEN
--                        ola.shipped_quantity * -1
--                    END), 0)
--    INTO    on_qty
--    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
--            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
--            mtl_system_items_b        msib,  -- 品目マスタ
--            oe_transaction_types_all  otta   -- 受注タイプ
--    WHERE   msib.segment1             = iv_item_code
--    AND     msib.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
--    AND     msib.inventory_item_id    = ola.shipping_inventory_item_id
--    AND     oha.deliver_from_id       = in_whse_id
--    AND     oha.req_status            = cv_req_status
--    AND     oha.actual_confirm_class  = cv_flag_off
--    AND     oha.latest_external_flag  = cv_flag_on
--    AND     oha.order_header_id       = ola.order_header_id
--    AND     ola.delete_flag           = cv_flag_off
--    AND     otta.attribute1           IN (cv_ship_pro_type, cv_warehouse_type)
--    AND     otta.transaction_type_id  = oha.order_type_id
--
    SELECT  /*+ leading(oha otta ola mld) */
            NVL(SUM(CASE
                      WHEN (otta.order_category_code = cv_cate_order) THEN
                        NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                      WHEN (otta.order_category_code = cv_cate_return) THEN
                       (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                    END), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details      mld,    -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v    mld,  -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     mld.item_code             = iv_item_code
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           IN (cv_ship_pro_type, cv_warehouse_type)
    AND     otta.transaction_type_id  = oha.order_type_id
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
-- 2008/12/18 H.Itou Mod End
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_ship_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_provide_qty
   * Description      : 非ロット  I6)実績未取在庫数  支給
   ***********************************************************************************/
  PROCEDURE get_inv_provide_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    iv_item_code   IN VARCHAR2,             -- 品目コード
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_provide_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off       CONSTANT VARCHAR2(1)  := 'N';       -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1)  := 'Y';       -- ON
    cv_req_status     CONSTANT VARCHAR2(2)  := '08';      -- 出荷実績計上済
-- 2008/12/18 H.Itou Add Start 本番障害#648
    cv_doc_type       CONSTANT VARCHAR2(2)  := '30';      -- 支給指示
    cv_rec_type       CONSTANT VARCHAR2(2)  := '20';      -- 出庫実績
-- 2008/12/18 H.Itou Add End
    cv_ship_pro_type  CONSTANT VARCHAR2(1)  := '2';       -- 支給依頼
    cv_cate_order     CONSTANT VARCHAR2(10) := 'ORDER';   -- 受注
    cv_cate_return    CONSTANT VARCHAR2(10) := 'RETURN';  -- 返品
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/12/18 H.Itou Mod Start 本番障害#648
--    SELECT  NVL(SUM(CASE
--                      WHEN (otta.order_category_code = cv_cate_order) THEN
--                        ola.shipped_quantity
--                      WHEN (otta.order_category_code = cv_cate_return) THEN
--                        ola.shipped_quantity * -1
--                    END), 0)
--    INTO    on_qty
--    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
--            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
--            mtl_system_items_b        msib,  -- 品目マスタ
--            oe_transaction_types_all  otta   -- 受注タイプ
--    WHERE   msib.segment1             = iv_item_code
--    AND     msib.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
--    AND     msib.inventory_item_id    = ola.shipping_inventory_item_id
--    AND     oha.deliver_from_id       = in_whse_id
--    AND     oha.req_status            = cv_req_status
--    AND     oha.actual_confirm_class  = cv_flag_off
--    AND     oha.latest_external_flag  = cv_flag_on
--    AND     oha.order_header_id       = ola.order_header_id
--    AND     ola.delete_flag           = cv_flag_off
--    AND     otta.attribute1           = cv_ship_pro_type
--    AND     otta.transaction_type_id  = oha.order_type_id
--
    SELECT  /*+ leading(oha otta ola mld) */
            NVL(SUM(CASE
                      WHEN (otta.order_category_code = cv_cate_order) THEN
                        NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                      WHEN (otta.order_category_code = cv_cate_return) THEN
                       (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                    END), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details      mld, -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v    mld,  -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     mld.item_code             = iv_item_code
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
-- 2008/12/18 H.Itou Mod End
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_provide_qty;
-- Ver1.10 M.Hokkanji Start
--
  /**********************************************************************************
   * Procedure Name   : get_inv_in_inout_cor_qty
   * Description      : 非ロット  I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_in_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_before_qty  OUT NOCOPY NUMBER,       -- 訂正前数量
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_in_inout_cor_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_on     CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- 入出庫報告有
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '30';  -- 入庫実績
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.before_actual_quantity),0),
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.before_actual_quantity),0),
-- 2008/09/17 v1.12 UPDATE End 
-- 2008/09/16 v1.11 UPDATE START
--            NVL(SUM(mril.ship_to_quantity),0)
            NVL(SUM(mld.actual_quantity),0)
-- 2008/09/16 v1.11 UPDATE END
    INTO    on_before_qty,
            on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_on
    AND     mrih.correct_actual_flg = cv_flag_on
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    AND     mld.mov_line_id         = mril.mov_line_id
    AND     mld.item_id             = mril.item_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_in_inout_cor_qty;
  
   /**********************************************************************************
   * Procedure Name   : get_inv_out_inout_cor_qty
   * Description      : 非ロット  I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
   ***********************************************************************************/
  PROCEDURE get_inv_out_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_before_qty  OUT NOCOPY NUMBER,       -- 訂正前数量
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_out_inout_cor_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on     CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- 入出庫報告有
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- 移動
    cv_rec_type    CONSTANT VARCHAR2(2) := '20';  -- 出庫実績
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/09/17 v1.12 UPDATE Start 
--    SELECT  NVL(SUM(mld.before_actual_quantity),0),
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.before_actual_quantity),0),
-- 2008/09/17 v1.12 UPDATE End 
-- 2008/09/16 v1.11 UPDATE START
--            NVL(SUM(mril.ship_to_quantity),0)
            NVL(SUM(mld.actual_quantity),0)
-- 2008/09/16 v1.11 UPDATE END
    INTO    on_before_qty,
            on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
-- Ver1.19 H.Itou Mod Start
--            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
            xxinv_mov_lot_details_v     mld     -- 移動ロット詳細（アドオン）
-- Ver1.19 H.Itou Mod End
-- 2008/09/16 v1.11 UPDATE START
--    WHERE   mrih.ship_to_locat_id   = in_whse_id
    WHERE   mrih.shipped_locat_id   = in_whse_id
-- 2008/09/16 v1.11 UPDATE END
    AND     mrih.comp_actual_flg    = cv_flag_on
    AND     mrih.correct_actual_flg = cv_flag_on
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    AND     mld.mov_line_id         = mril.mov_line_id
    AND     mld.item_id             = mril.item_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_out_inout_cor_qty;
-- Ver1.10 M.Hokkanji End
--
  /**********************************************************************************
   * Procedure Name   : get_sup_inv_in_qty
   * Description      : 非ロット  S1)供給数  移動入庫予定
   ***********************************************************************************/
  PROCEDURE get_sup_inv_in_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_inv_in_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status_req_fin CONSTANT VARCHAR2(2) := '02';  -- 依頼済み
    cv_move_status_adjust  CONSTANT VARCHAR2(2) := '03';  -- 調整中
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.instruct_qty), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status            IN (cv_move_status_req_fin, cv_move_status_adjust)
    AND     mrih.schedule_arrival_date <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sup_inv_in_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_order_qty
   * Description      : 非ロット  S2)供給数  発注受入予定
   ***********************************************************************************/
  PROCEDURE get_sup_order_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    iv_item_code   IN VARCHAR2,             -- 品目コード
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_order_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_po_status_order_fin  CONSTANT VARCHAR2(2) := '20';  -- 発注作成済
    cv_po_status_accept     CONSTANT VARCHAR2(2) := '25';  -- 受入あり
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(pla.quantity), 0)
    INTO    on_qty
    FROM    mtl_system_items_b msib,
            po_lines_all       pla,
            po_headers_all     pha
    WHERE   msib.segment1          = iv_item_code
    AND     msib.organization_id   = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id = pla.item_id
    AND     pla.attribute13        = cv_flag_off -- 数量確定フラグ
    AND     pla.po_header_id       = pha.po_header_id
    AND     pha.attribute1        IN (cv_po_status_order_fin, cv_po_status_accept)
    AND     pha.attribute5         = iv_whse_code
    AND     pha.attribute4        <= TO_CHAR(id_eff_date, 'YYYY/MM/DD') -- 納入日
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     pha.org_id             = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sup_order_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_inv_out_qty
   * Description      : 非ロット  S4)供給数  実績計上済の移動出庫実績
   ***********************************************************************************/
  PROCEDURE get_sup_inv_out_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_inv_out_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '04';  -- 出庫報告あり
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.shipped_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
    WHERE   mrih.ship_to_locat_id       = in_whse_id
    AND     mrih.comp_actual_flg        = cv_flag_off
    AND     mrih.status                 = cv_move_status
-- 2008/12/15 H.Itou Mod Start 本番障害#645
--    AND     mrih.schedule_arrival_date <= id_eff_date
    AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date)   <= id_eff_date
-- 2008/12/15 H.Itou Mod End
    AND     mrih.mov_hdr_id             = mril.mov_hdr_id
    AND     mril.delete_flg             = cv_flag_off
    AND     mril.item_id                = in_item_id
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sup_inv_out_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_ship_qty
   * Description      : 非ロット  D1)需要数  実績未計上の出荷依頼
   ***********************************************************************************/
  PROCEDURE get_dem_ship_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    iv_item_code   IN VARCHAR2,             -- 品目コード
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 引当数
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_ship_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '03';  -- 締め済み
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '1';   -- 出荷依頼
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(ola.reserved_quantity), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
            mtl_system_items_b        msib,  -- 品目マスタ
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   msib.segment1             = iv_item_code
    AND     msib.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id    = ola.shipping_inventory_item_id
    AND     oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_ship_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_provide_qty
   * Description      : 非ロット  D2)需要数  実績未計上の支給指示
   ***********************************************************************************/
  PROCEDURE get_dem_provide_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    iv_item_code   IN VARCHAR2,             -- 品目コード
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 引当数
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_provide_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '07';  -- 受領済
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '2';   -- 支給依頼
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(ola.reserved_quantity), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
            mtl_system_items_b        msib,  -- 品目マスタ
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   msib.segment1             = iv_item_code
    AND     msib.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id    = ola.shipping_inventory_item_id
    AND     oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 START *--------*
    AND     otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
-- *--------* 2009/03/31 Ver.1.18 本番障害#1346対応 END   *--------*
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_provide_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_inv_out_qty
   * Description      : 非ロット  D3)需要数  実績未計上の移動指示
   ***********************************************************************************/
  PROCEDURE get_dem_inv_out_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 引当数
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_inv_out_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off            CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status_req_fin CONSTANT VARCHAR2(2) := '02';  -- 依頼済み
    cv_move_status_adjust  CONSTANT VARCHAR2(2) := '03';  -- 調整中
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.reserved_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status            IN (cv_move_status_req_fin, cv_move_status_adjust)
    AND     mrih.schedule_ship_date <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_inv_out_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_inv_in_qty
   * Description      : 非ロット  D4)需要数  実績計上済の移動入庫実績
   ***********************************************************************************/
  PROCEDURE get_dem_inv_in_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_inv_in_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '05';  -- 入庫報告有
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.ship_to_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
-- 2008/12/15 H.Itou Mod Start 本番障害#645
--    AND     mrih.schedule_ship_date <= id_eff_date
    AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date)  <= id_eff_date
-- 2008/12/15 H.Itou Mod End
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_inv_in_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_produce_qty
   * Description      : 非ロット  D5)需要数  実績未計上の生産投入予定
   ***********************************************************************************/
  PROCEDURE get_dem_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    in_item_id     IN NUMBER,               -- 品目ID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_produce_qty'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cn_batch_status_wip     CONSTANT NUMBER(5,0) := 2;     -- WIP
    cn_batch_status_reserv  CONSTANT NUMBER(5,0) := 1;     -- 保留
    cn_line_type            CONSTANT NUMBER(5,0) := -1;    -- 投入品
    cv_plan_type            CONSTANT VARCHAR2(1) := '4';   -- 投入
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  NVL(SUM(xmd.instructions_qty), 0)
    INTO    on_qty
    FROM    gme_batch_header      gbh, -- 生産バッチ
            gme_material_details  gmd, -- 生産原料詳細
            xxwip_material_detail xmd, -- 生産原料詳細（アドオン）
            gmd_routings_b        grb  -- 工順マスタ
    WHERE   gbh.batch_status      IN (cn_batch_status_wip, cn_batch_status_reserv)
    AND     gbh.plan_start_date   <= id_eff_date
    AND     gbh.batch_id           = gmd.batch_id
    AND     gmd.line_type          = cn_line_type
    AND     gmd.item_id            = in_item_id
    AND     gmd.material_detail_id = xmd.material_detail_id
    AND     xmd.plan_type          = cv_plan_type
    AND     gbh.routing_id         = grb.routing_id
    AND     grb.attribute9         = iv_whse_code       -- 納品場所
    AND     xmd.invested_qty       = 0
    ;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dem_produce_qty;
--
--
--  /**********************************************************************************
--   * Function Name    : get_can_enc_total_qty
--   * Description      : 総引当可能数算出API
--   ***********************************************************************************/
--  FUNCTION get_can_enc_total_qty(
--    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
--    in_item_id          IN NUMBER,                    -- OPM品目ID
--    in_lot_id           IN NUMBER DEFAULT NULL)       -- ロットID
--    RETURN NUMBER
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_total_qty'; --プログラム名
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prf_max_date_name CONSTANT VARCHAR2(15)  := 'MAX日付'; --プロファイル名
----
--    -- *** ローカル変数 ***
--    ld_eff_date    DATE;          -- 有効日
--    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
--    -- ===============================
--    -- ユーザー定義例外
--    -- ===============================
--    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
----
--  BEGIN
----
--    -- ***********************************************
--    -- ***      共通関数処理ロジックの記述         ***
--    -- ***********************************************
--    -- MAX日付を取得
--    ld_eff_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'),'YYYY/MM/DD');
--    IF (ld_eff_date IS NULL) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN', 'APP-XXCMN-10002', 'NG_PROFILE', cv_prf_max_date_name);
--      RAISE process_exp;
--    END IF;
----
--    -- 総引当可能数
--    RETURN get_can_enc_in_time_qty(in_whse_id, in_item_id, in_lot_id, ld_eff_date);
----
--  EXCEPTION
--    WHEN process_exp THEN
--      RAISE_APPLICATION_ERROR
--        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
----
----###############################  固定例外処理部 START   ###################################
----
--    WHEN OTHERS THEN
--      RAISE_APPLICATION_ERROR
--        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
----
----###################################  固定部 END   #########################################
----
--  END get_can_enc_total_qty;
--
  /**********************************************************************************
   * Function Name    : get_can_enc_in_time_qty
   * Description      : 有効日ベース引当可能数算出API
   ***********************************************************************************/
  FUNCTION get_can_enc_in_time_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ロットID
    in_active_date      IN DATE   DEFAULT NULL)       -- 有効日
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_in_time_qty'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- *** ローカル変数 ***
    ln_whse_id     NUMBER;        -- 保管倉庫ID
    ln_item_id     NUMBER;        -- 品目ID
    ln_lot_id      NUMBER;        -- ロットID
    ln_item_code   VARCHAR2(40);  -- 品目コード
    lv_whse_code   VARCHAR2(40);  -- 保管倉庫コード
    lv_rep_whse    VARCHAR2(150); -- 代表倉庫
    lv_item_code   VARCHAR2(32);  -- 品目コード
    lv_lot_no      VARCHAR2(32);  -- ロットNO
    ld_eff_date    DATE;          -- 有効日
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    -- *** ローカル定数 ***
    cv_prf_max_date_name CONSTANT VARCHAR2(15)  := 'MAX日付'; --プロファイル名
--
    ln_inv_lot_onhand             NUMBER; -- ロット I0)結果数量
    ln_inv_lot_in_inout_rpt_qty   NUMBER; -- ロット I1)結果数量
    ln_inv_lot_in_in_rpt_qty      NUMBER; -- ロット I2)結果数量
    ln_inv_lot_out_inout_rpt_qty  NUMBER; -- ロット I3)結果数量
    ln_inv_lot_out_out_rpt_qty    NUMBER; -- ロット I4)結果数量
    ln_inv_lot_ship_qty           NUMBER; -- ロット I5)結果数量
    ln_inv_lot_provide_qty        NUMBER; -- ロット I6)結果数量
-- Ver1.10 M.Hokkanji Start
    ln_inv_lot_in_inout_bef_qty   NUMBER; -- ロット I7)結果数量(訂正前)
    ln_inv_lot_in_inout_cor_qty   NUMBER; -- ロット I7)結果数量(訂正後)
    ln_inv_lot_out_inout_bef_qty  NUMBER; -- ロット I8)結果数量(訂正前)
    ln_inv_lot_out_inout_cor_qty  NUMBER; -- ロット I8)結果数量(訂正後)
-- Ver1.10 M.Hokkanji End
    ln_inv_onhand                 NUMBER; -- 非ロット I0)結果数量
    ln_inv_in_inout_rpt_qty       NUMBER; -- 非ロット I1)結果数量
    ln_inv_in_in_rpt_qty          NUMBER; -- 非ロット I2)結果数量
    ln_inv_out_inout_rpt_qty      NUMBER; -- 非ロット I3)結果数量
    ln_inv_out_out_rpt_qty        NUMBER; -- 非ロット I4)結果数量
    ln_inv_ship_qty               NUMBER; -- 非ロット I5)結果数量
    ln_inv_provide_qty            NUMBER; -- 非ロット I6)結果数量
-- Ver1.10 M.Hokkanji Start
    ln_inv_in_inout_bef_qty       NUMBER; -- 非ロット I7)結果数量(訂正前)
    ln_inv_in_inout_cor_qty       NUMBER; -- 非ロット I7)結果数量(訂正後)
    ln_inv_out_inout_bef_qty      NUMBER; -- 非ロット I8)結果数量(訂正前)
    ln_inv_out_inout_cor_qty      NUMBER; -- 非ロット I8)結果数量(訂正後)
-- Ver1.10 M.Hokkanji End
    ln_sup_lot_inv_in_qty         NUMBER; -- ロット S1)結果数量
    ln_sup_lot_order_qty          NUMBER; -- ロット S2)結果数量
    ln_sup_lot_produce_qty        NUMBER; -- ロット S3)結果数量
    ln_sup_lot_inv_out_qty        NUMBER; -- ロット S4)結果数量
    ln_dem_lot_ship_qty           NUMBER; -- ロット D1)結果数量
    ln_dem_lot_provide_qty        NUMBER; -- ロット D2)結果数量
    ln_dem_lot_inv_out_qty        NUMBER; -- ロット D3)結果数量
    ln_dem_lot_inv_in_qty         NUMBER; -- ロット D4)結果数量
    ln_dem_lot_produce_qty        NUMBER; -- ロット D5)結果数量
    ln_dem_lot_order_qty          NUMBER; -- ロット D6)結果数量
    ln_sup_inv_in_qty             NUMBER; -- 非ロット S1)結果数量
    ln_sup_order_qty              NUMBER; -- 非ロット S2)結果数量
    ln_sup_inv_out_qty            NUMBER; -- 非ロット S4)結果数量
    ln_dem_ship_qty               NUMBER; -- 非ロット D1)結果数量
    ln_dem_provide_qty            NUMBER; -- 非ロット D2)結果数量
    ln_dem_inv_out_qty            NUMBER; -- 非ロット D3)結果数量
    ln_dem_inv_in_qty             NUMBER; -- 非ロット D4)結果数量
    ln_dem_produce_qty            NUMBER; -- 非ロット D5)結果数量
--
    ln_stock_qty  NUMBER; -- 在庫数
    ln_supply_qty NUMBER; -- 供給数
    ln_demand_qty NUMBER; -- 需要数
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    ln_stock_qty  := 0;
    ln_supply_qty := 0;
    ln_demand_qty := 0;
--
    -- 有効日を取得
    IF (in_active_date IS NULL) THEN
        -- MAX日付を取得
      ld_eff_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'),'YYYY/MM/DD');
      IF (ld_eff_date IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                              'APP-XXCMN-10002',
                                              'NG_PROFILE',
                                              cv_prf_max_date_name);
        RAISE process_exp;
      END IF;
    ELSE
      ld_eff_date := in_active_date;
    END IF;
--
    --ロット管理の場合
    IF (in_lot_id IS NOT NULL) THEN
      -- ロット I0 EBS手持在庫
      get_inv_onhand_lot(
        in_whse_id,
        in_item_id,
        in_lot_id,
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_onhand,
        lv_whse_code,
        lv_rep_whse,
        lv_item_code,
        lv_lot_no,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I1 実績未取在庫数  移動入庫（入出庫報告有）
      get_inv_lot_in_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_in_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I2 実績未取在庫数  移動入庫（入庫報告有）
      get_inv_lot_in_in_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_in_in_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I3 実績未取在庫数  移動出庫（入出庫報告有）
      get_inv_lot_out_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_out_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I4 実績未取在庫数  移動出庫（出庫報告有）
      get_inv_lot_out_out_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_out_out_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I5 実績未取在庫数  出荷
      get_inv_lot_ship_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I6 実績未取在庫数  支給
      get_inv_lot_provide_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
-- Ver1.10 M.Hokkanji Start
--
      -- ロット I7 実績未取在庫数  移動入庫訂正（入出庫報告有）
      get_inv_lot_in_inout_cor_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_in_inout_bef_qty,
        ln_inv_lot_in_inout_cor_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I8 実績未取在庫数  移動出庫訂正（入出庫報告有）
      get_inv_lot_out_inout_cor_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_out_inout_bef_qty,
        ln_inv_lot_out_inout_cor_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
-- Ver1.10 M.Hokkanji End
--
      -- ロット S1)供給数  移動入庫予定
     get_sup_lot_inv_in_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_sup_lot_inv_in_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット S2)供給数  発注受入予定
     get_sup_lot_order_qty(
        lv_whse_code,
        lv_item_code,
        lv_lot_no,
        ld_eff_date,
        ln_sup_lot_order_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット S3)供給数  生産入庫予定
     get_sup_lot_produce_qty(
        lv_whse_code,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_sup_lot_produce_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット S4)供給数  実績計上済の移動出庫実績
     get_sup_lot_inv_out_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_sup_lot_inv_out_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット D1)需要数  実績未計上の出荷依頼
-- 2008/09/10 v1.8 UPDATE START
--      get_dem_lot_ship_qty(
      get_dem_lot_ship_qty2(
-- 2008/09/10 v1.8 UPDATE END
        ln_whse_id,
-- 2008/09/09 v1.7 UPDATE START
--        ln_item_id,
        lv_item_code,
-- 2008/09/09 v1.7 UPDATE END
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット D2)需要数  実績未計上の支給指示
-- 2008/09/10 v1.8 UPDATE START
--      get_dem_lot_provide_qty(
      get_dem_lot_provide_qty2(
-- 2008/09/10 v1.8 UPDATE END
        ln_whse_id,
-- 2008/09/09 v1.7 UPDATE START
--        ln_item_id,
        lv_item_code,
-- 2008/09/09 v1.7 UPDATE END
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット D3)需要数  実績未計上の移動指示
      get_dem_lot_inv_out_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_inv_out_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット D4)需要数  実績計上済の移動入庫実績
      get_dem_lot_inv_in_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_inv_in_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット D5)需要数  実績未計上の生産投入予定
      get_dem_lot_produce_qty(
        lv_whse_code,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_produce_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット D6)需要数  実績未計上の相手先倉庫発注入庫予定
      get_dem_lot_order_qty(
        lv_whse_code,
        lv_item_code,
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_order_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット管理品在庫数
      ln_stock_qty := ln_inv_lot_onhand 
                    + ln_inv_lot_in_inout_rpt_qty
                    + ln_inv_lot_in_in_rpt_qty
                    - ln_inv_lot_out_inout_rpt_qty
                    - ln_inv_lot_out_out_rpt_qty
                    - ln_inv_lot_ship_qty
                    - ln_inv_lot_provide_qty
-- Ver1.10 M.Hokkanji Start
                    - ln_inv_lot_in_inout_bef_qty
                    + ln_inv_lot_in_inout_cor_qty
                    + ln_inv_lot_out_inout_bef_qty
                    - ln_inv_lot_out_inout_cor_qty;
-- Ver1.10 M.Hokkanji End
--
      -- ロット管理品供給数
      ln_supply_qty := ln_sup_lot_inv_in_qty
                     + ln_sup_lot_order_qty
                     + ln_sup_lot_produce_qty
                     + ln_sup_lot_inv_out_qty;
--
      -- ロット管理品需要数
      ln_demand_qty := ln_dem_lot_ship_qty
                     + ln_dem_lot_provide_qty
                     + ln_dem_lot_inv_out_qty
                     + ln_dem_lot_inv_in_qty 
                     + ln_dem_lot_produce_qty
                     + ln_dem_lot_order_qty;
--
    ELSE
      --非ロット  I0  EBS手持在庫
      get_inv_onhand(
        in_whse_id,
        in_item_id,
        ln_whse_id,
        ln_item_id,
        ln_inv_onhand,
        lv_whse_code,
        lv_rep_whse,
        lv_item_code,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I1  実績未取在庫数  移動入庫（入出庫報告有）
      get_inv_in_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_in_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I2  実績未取在庫数  移動入庫（入庫報告有）
      get_inv_in_in_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_in_in_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I3  実績未取在庫数  移動出庫（入出庫報告有）
      get_inv_out_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_out_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I4  実績未取在庫数  移動出庫（出庫報告有）
      get_inv_out_out_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_out_out_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I5  実績未取在庫数  出荷
      get_inv_ship_qty(
        ln_whse_id,
-- 2008.06.24 mod S.Takemoto start
--        ln_item_id,
        lv_item_code,
-- 2008.06.24 mod S.Takemoto end
        ln_inv_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I6  実績未取在庫数  支給
      get_inv_provide_qty(
        ln_whse_id,
-- 2008.06.24 mod S.Takemoto start
--        ln_item_id,
        lv_item_code,
-- 2008.06.24 mod S.Takemoto end
        ln_inv_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
-- Ver1.10 M.Hokkanji Start
      -- 非ロット  I7  実績未取在庫数  移動入庫訂正（入出庫報告有）
      get_inv_in_inout_cor_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_in_inout_bef_qty,
        ln_inv_in_inout_cor_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I8  実績未取在庫数  移動出庫訂正（入出庫報告有）
      get_inv_out_inout_cor_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_out_inout_bef_qty,
        ln_inv_out_inout_cor_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
-- Ver1.10 M.Hokkanji End
      -- 非ロット  S1)供給数  移動入庫予定
      get_sup_inv_in_qty(
        ln_whse_id,
        ln_item_id,
        ld_eff_date,
        ln_sup_inv_in_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  S2)供給数  発注受入予定
      get_sup_order_qty(
        lv_whse_code,
        lv_item_code,
        ld_eff_date,
        ln_sup_order_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  S4)供給数  実績計上済の移動出庫実績
      get_sup_inv_out_qty(
        ln_whse_id,
        ln_item_id,
        ld_eff_date,
        ln_sup_inv_out_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  D1)需要数  実績未計上の出荷依頼
      get_dem_ship_qty(
        ln_whse_id,
        lv_item_code,
        ld_eff_date,
        ln_dem_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  D2)需要数  実績未計上の支給指示
      get_dem_provide_qty(
        ln_whse_id,
        lv_item_code,
        ld_eff_date,
        ln_dem_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  D3)需要数  実績未計上の移動指示
      get_dem_inv_out_qty(
        ln_whse_id,
        ln_item_id,
        ld_eff_date,
        ln_dem_inv_out_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  D4)需要数  実績計上済の移動入庫実績
      get_dem_inv_in_qty(
        ln_whse_id,
        ln_item_id,
        ld_eff_date,
        ln_dem_inv_in_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  D5)需要数  実績未計上の生産投入予定
      get_dem_produce_qty(
        lv_whse_code,
        ln_item_id,
        ld_eff_date,
        ln_dem_produce_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット管理品在庫数
      ln_stock_qty := ln_inv_onhand
                    + ln_inv_in_inout_rpt_qty
                    + ln_inv_in_in_rpt_qty
                    - ln_inv_out_inout_rpt_qty
                    - ln_inv_out_out_rpt_qty
                    - ln_inv_ship_qty
                    - ln_inv_provide_qty
-- Ver1.10 M.Hokkanji Start
                    - ln_inv_in_inout_bef_qty
                    + ln_inv_in_inout_cor_qty
                    + ln_inv_out_inout_bef_qty
                    - ln_inv_out_inout_cor_qty;
-- Ver1.10 M.Hokkanji End
--
      -- 非ロット管理品供給数
      ln_supply_qty := ln_sup_inv_in_qty
                     + ln_sup_order_qty
                     + ln_sup_inv_out_qty;
--
      -- 非ロット管理品需要数
      ln_demand_qty := ln_dem_ship_qty
                     + ln_dem_provide_qty
                     + ln_dem_inv_out_qty
                     + ln_dem_inv_in_qty
                     + ln_dem_produce_qty;
--
    END IF;
--
    -- 有効日ベース引当可能数
    RETURN ln_stock_qty + ln_supply_qty - ln_demand_qty;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_can_enc_in_time_qty;
--
  /**********************************************************************************
   * Function Name    : get_stock_qty
   * Description      : 手持在庫数量算出API
   ***********************************************************************************/
  FUNCTION get_stock_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ロットID
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_qty'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    ln_whse_id     NUMBER;        -- 保管倉庫ID
    ln_item_id     NUMBER;        -- 品目ID
    ln_lot_id      NUMBER;        -- ロットID
    lv_whse_code   VARCHAR2(40);  -- 保管倉庫コード
    lv_rep_whse    VARCHAR2(150); -- 代表倉庫
    lv_item_code   VARCHAR2(32);  -- 品目コード
    lv_lot_no      VARCHAR2(32);  -- ロットNO
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_inv_lot_onhand             NUMBER; -- ロット I0)結果数量
    ln_inv_lot_in_inout_rpt_qty   NUMBER; -- ロット I1)結果数量
    ln_inv_lot_in_in_rpt_qty      NUMBER; -- ロット I2)結果数量
    ln_inv_lot_out_inout_rpt_qty  NUMBER; -- ロット I3)結果数量
    ln_inv_lot_out_out_rpt_qty    NUMBER; -- ロット I4)結果数量
    ln_inv_lot_ship_qty           NUMBER; -- ロット I5)結果数量
    ln_inv_lot_provide_qty        NUMBER; -- ロット I6)結果数量
-- Ver1.10 M.Hokkanji Start
    ln_inv_lot_in_inout_bef_qty   NUMBER; -- ロット I7)結果数量(訂正前)
    ln_inv_lot_in_inout_cor_qty   NUMBER; -- ロット I7)結果数量(訂正後)
    ln_inv_lot_out_inout_bef_qty  NUMBER; -- ロット I8)結果数量(訂正前)
    ln_inv_lot_out_inout_cor_qty  NUMBER; -- ロット I8)結果数量(訂正後)
-- Ver1.10 M.Hokkanji End
    ln_inv_onhand                 NUMBER; -- 非ロット I0)結果数量
    ln_inv_in_inout_rpt_qty       NUMBER; -- 非ロット I1)結果数量
    ln_inv_in_in_rpt_qty          NUMBER; -- 非ロット I2)結果数量
    ln_inv_out_inout_rpt_qty      NUMBER; -- 非ロット I3)結果数量
    ln_inv_out_out_rpt_qty        NUMBER; -- 非ロット I4)結果数量
    ln_inv_ship_qty               NUMBER; -- 非ロット I5)結果数量
    ln_inv_provide_qty            NUMBER; -- 非ロット I6)結果数量
-- Ver1.10 M.Hokkanji Start
    ln_inv_in_inout_bef_qty       NUMBER; -- 非ロット I7)結果数量(訂正前)
    ln_inv_in_inout_cor_qty       NUMBER; -- 非ロット I7)結果数量(訂正後)
    ln_inv_out_inout_bef_qty      NUMBER; -- 非ロット I8)結果数量(訂正前)
    ln_inv_out_inout_cor_qty      NUMBER; -- 非ロット I8)結果数量(訂正後)
-- Ver1.10 M.Hokkanji End
--
    ln_stock_qty NUMBER;
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    ln_stock_qty := 0;
--
    IF (in_lot_id IS NOT NULL) THEN
      -- ロット I0 EBS手持在庫
      get_inv_onhand_lot(
        in_whse_id,
        in_item_id,
        in_lot_id,
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_onhand,
        lv_whse_code,
        lv_rep_whse,
        lv_item_code,
        lv_lot_no,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I1 実績未取在庫数  移動入庫（入出庫報告有）
      get_inv_lot_in_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_in_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I2 実績未取在庫数  移動入庫（入庫報告有）
      get_inv_lot_in_in_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_in_in_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I3 実績未取在庫数  移動出庫（入出庫報告有）
      get_inv_lot_out_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_out_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I4 実績未取在庫数  移動出庫（出庫報告有）
      get_inv_lot_out_out_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_out_out_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I5 実績未取在庫数  出荷
      get_inv_lot_ship_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I6 実績未取在庫数  支給
      get_inv_lot_provide_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
-- Ver1.10 M.Hokkanji Start
--
      -- ロット I7 実績未取在庫数  移動入庫訂正（入出庫報告有）
      get_inv_lot_in_inout_cor_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_in_inout_bef_qty,
        ln_inv_lot_in_inout_cor_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- ロット I8 実績未取在庫数  移動出庫訂正（入出庫報告有）
      get_inv_lot_out_inout_cor_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_out_inout_bef_qty,
        ln_inv_lot_out_inout_cor_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
-- Ver1.10 M.Hokkanji End
--
      ln_stock_qty := ln_inv_lot_onhand 
                    + ln_inv_lot_in_inout_rpt_qty
                    + ln_inv_lot_in_in_rpt_qty
                    - ln_inv_lot_out_inout_rpt_qty
                    - ln_inv_lot_out_out_rpt_qty
                    - ln_inv_lot_ship_qty
                    - ln_inv_lot_provide_qty
-- Ver1.10 M.Hokkanji Start
                    - ln_inv_lot_in_inout_bef_qty
                    + ln_inv_lot_in_inout_cor_qty
                    + ln_inv_lot_out_inout_bef_qty
                    - ln_inv_lot_out_inout_cor_qty;
-- Ver1.10 M.Hokkanji End
--
    ELSE
      --非ロット  I0  EBS手持在庫
      get_inv_onhand(
        in_whse_id,
        in_item_id,
        ln_whse_id,
        ln_item_id,
        ln_inv_onhand,
        lv_whse_code,
        lv_rep_whse,
        lv_item_code,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I1  実績未取在庫数  移動入庫（入出庫報告有）
      get_inv_in_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_in_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I2  実績未取在庫数  移動入庫（入庫報告有）
      get_inv_in_in_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_in_in_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I3  実績未取在庫数  移動出庫（入出庫報告有）
      get_inv_out_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_out_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I4  実績未取在庫数  移動出庫（出庫報告有）
      get_inv_out_out_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_out_out_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I5  実績未取在庫数  出荷
      get_inv_ship_qty(
        ln_whse_id,
        lv_item_code,
        ln_inv_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I6  実績未取在庫数  支給
      get_inv_provide_qty(
        ln_whse_id,
        lv_item_code,
        ln_inv_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
-- Ver1.10 M.Hokkanji Start
      -- 非ロット  I7  実績未取在庫数  移動入庫訂正（入出庫報告有）
      get_inv_in_inout_cor_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_in_inout_bef_qty,
        ln_inv_in_inout_cor_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
      -- 非ロット  I8  実績未取在庫数  移動出庫訂正（入出庫報告有）
      get_inv_out_inout_cor_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_out_inout_bef_qty,
        ln_inv_out_inout_cor_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラーメッセージは設定済み
        RAISE process_exp;
      END IF;
--
-- Ver1.10 M.Hokkanji End
      ln_stock_qty := ln_inv_onhand
                    + ln_inv_in_inout_rpt_qty
                    + ln_inv_in_in_rpt_qty
                    - ln_inv_out_inout_rpt_qty
                    - ln_inv_out_out_rpt_qty
                    - ln_inv_ship_qty
                    - ln_inv_provide_qty
-- Ver1.10 M.Hokkanji Start
                    - ln_inv_in_inout_bef_qty
                    + ln_inv_in_inout_cor_qty
                    + ln_inv_out_inout_bef_qty
                    - ln_inv_out_inout_cor_qty;
-- Ver1.10 M.Hokkanji End
--
    END IF;
--
    RETURN ln_stock_qty;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_stock_qty;
--
  /**********************************************************************************
   * Function Name    : get_can_enc_qty
   * Description      : 引当可能数算出API
   ***********************************************************************************/
  FUNCTION get_can_enc_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ロットID
    in_active_date      IN DATE)                      -- 有効日
    RETURN NUMBER                                     -- 引当可能数
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_qty'; --プログラム名
-- Ver1.6 M.Hokkanji Start
    cv_xxcmn                CONSTANT VARCHAR2(10)  := 'XXCMN';
    cv_dummy_frequent_whse  CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';
    cv_error_10002          CONSTANT VARCHAR2(30)  := 'APP-XXCMN-10002'; --プロファイル取得エラー
    cv_tkn_ng_profile       CONSTANT VARCHAR2(30)  := 'NG_PROFILE'; --トークン
-- Ver1.6 M.Hokkanji End
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_whse_id     NUMBER;        -- 保管倉庫ID
    ln_item_id     NUMBER;        -- 品目ID
    ln_lot_id      NUMBER;        -- ロットID
    lv_whse_code   VARCHAR2(40);  -- 保管倉庫コード
    lv_rep_whse    VARCHAR2(150); -- 代表倉庫
    lv_item_code   VARCHAR2(32);  -- 品目コード
    lv_lot_no      VARCHAR2(32);  -- ロットNO
    ld_eff_date    DATE;          -- 有効日
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    ln_all_enc_qty      NUMBER;     -- 対象の総引当可能数
    ln_in_time_enc_qty  NUMBER;     -- 対象の有効日ベース引当可能数
    ln_enc_qty          NUMBER;     -- 引当可能数
    ln_ref_all_enc_qty      NUMBER; -- 対象親や子の総引当可能数
    ln_ref_in_time_enc_qty  NUMBER; -- 対象親や子の有効日ベース引当可能数
    lt_inventory_location_id mtl_item_locations.inventory_location_id%TYPE; -- 保管倉庫ID
-- Ver1.6 M.Hokkanji Start
    lt_dummy_frequent_whse  mtl_item_locations.segment1%TYPE; --ダミー代表倉庫
-- Ver1.6 M.Hokkanji End
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
-- Ver1.6 M.Hokkanji Start
    profile_exp               EXCEPTION;     -- プロファイル取得失敗
-- Ver1.6 M.Hokkanji End
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
-- Ver1.6 M.Hokkanji Start
    PRAGMA EXCEPTION_INIT(profile_exp, -20002);
-- Ver1.6 M.Hokkanji End
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    -- 数量の初期化
    ln_all_enc_qty     := 0;
    ln_in_time_enc_qty := 0;
--
    BEGIN
      -- 代表倉庫を取得
      SELECT  mil.segment1,              -- 保管倉庫コード
              mil.attribute5             -- 代表倉庫
      INTO    lv_whse_code,
              lv_rep_whse
      FROM    mtl_item_locations  mil   -- 保管場所
      WHERE   mil.inventory_location_id = in_whse_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE process_exp;
    END;
--
    -- 単体の引当可能数を算出
    ln_all_enc_qty     := get_can_enc_in_time_qty(in_whse_id, in_item_id, in_lot_id);
    ln_in_time_enc_qty := get_can_enc_in_time_qty(in_whse_id,
                                                  in_item_id,
                                                  in_lot_id,
                                                  in_active_date);
--
    -- 代表倉庫でない場合
    IF (lv_rep_whse IS NULL) THEN
      ln_ref_all_enc_qty      := 0;
      ln_ref_in_time_enc_qty  := 0;
--
    -- 代表倉庫（親）の場合
    ELSIF (lv_rep_whse = lv_whse_code) THEN
      -- 代表倉庫（子）の合計を取得
      SELECT  NVL(SUM(get_can_enc_in_time_qty(mil.inventory_location_id,
                                              in_item_id,
                                              in_lot_id)),0),
              NVL(SUM(get_can_enc_in_time_qty(mil.inventory_location_id,
                                              in_item_id,
                                              in_lot_id,
                                              in_active_date)),0)
      INTO    ln_ref_all_enc_qty,
              ln_ref_in_time_enc_qty
      FROM    mtl_item_locations  mil    -- 保管場所
      WHERE   mil.attribute5            = lv_rep_whse -- 代表倉庫
      AND     mil.segment1             <> mil.attribute5;
--
      -- 足し込み
      ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
      ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
--
      -- 代表倉庫(子)(倉庫・品目単位)の合計を取得
       SELECT  NVL(SUM(get_can_enc_in_time_qty(xfil.item_location_id,
                                              in_item_id,
                                              in_lot_id)),0),
               NVL(SUM(get_can_enc_in_time_qty(xfil.item_location_id,
                                              in_item_id,
                                              in_lot_id,
                                              in_active_date)),0)
       INTO    ln_ref_all_enc_qty,
               ln_ref_in_time_enc_qty
       FROM    xxwsh_frq_item_locations xfil
       WHERE   xfil.frq_item_location_code = lv_rep_whse -- 代表倉庫コード
       AND     xfil.item_id = in_item_id;                -- OPM品目ID
--
      -- 足し込み
      ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
      ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
--
    -- 代表倉庫（子）の場合
    ELSE
      -- ダミー代表倉庫を取得
      lt_dummy_frequent_whse := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
      -- 取得に失敗した場合
      IF (lt_dummy_frequent_whse IS NULL) THEN
        RAISE profile_exp ;
      END IF ;
      IF (lv_rep_whse = lt_dummy_frequent_whse) THEN
        BEGIN
          -- 倉庫品目マスタを参照
          SELECT  NVL(SUM(get_can_enc_in_time_qty(xfil.frq_item_location_id,
                                                  in_item_id,
                                                  in_lot_id)),0),
                  NVL(SUM(get_can_enc_in_time_qty(xfil.frq_item_location_id,
                                                  in_item_id,
                                                  in_lot_id,
                                                  in_active_date)),0)
          INTO    ln_ref_all_enc_qty,
                  ln_ref_in_time_enc_qty
          FROM    xxwsh_frq_item_locations xfil
          WHERE   xfil.item_location_code = lv_whse_code         -- 元倉庫
          AND     xfil.item_id = in_item_id;                     -- OPM品目ID
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_ref_all_enc_qty := 0;
            ln_ref_in_time_enc_qty := 0;
        END;
      ELSE
        BEGIN
          -- 代表倉庫（親）を取得
          SELECT  NVL(SUM(get_can_enc_in_time_qty(mil.inventory_location_id,
                                                  in_item_id,
                                                  in_lot_id)),0),
                  NVL(SUM(get_can_enc_in_time_qty(mil.inventory_location_id,
                                                  in_item_id,
                                                  in_lot_id,
                                                  in_active_date)),0)
          INTO    ln_ref_all_enc_qty,
                  ln_ref_in_time_enc_qty
          FROM    mtl_item_locations  mil    -- 保管場所
          WHERE   mil.attribute5            = lv_rep_whse -- 代表倉庫
          AND     mil.segment1              = mil.attribute5;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_ref_all_enc_qty := 0;
            ln_ref_in_time_enc_qty := 0;
        END;
      END IF;
      -- 親単体の引当可能数がマイナスの場合のみ足し込む
      IF (ln_ref_all_enc_qty < 0) THEN
        ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
      END IF;
      IF (ln_ref_in_time_enc_qty < 0) THEN
        ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
      END IF;
    END IF;
--
    -- 少ない方が引当可能数
    IF (ln_all_enc_qty < ln_in_time_enc_qty) THEN
      ln_enc_qty := ln_all_enc_qty;
    ELSE
      ln_enc_qty := ln_in_time_enc_qty;
    END IF;
--
    -- 引当可能数
    RETURN ln_enc_qty;
--
  EXCEPTION
-- Ver1.6 M.Hokkanji Start
    WHEN profile_exp THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( cv_xxcmn
                                            ,cv_error_10002
                                            ,cv_tkn_ng_profile
                                            ,cv_dummy_frequent_whse
                                           ) ;
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
-- Ver1.6 M.Hokkanji End
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_can_enc_qty;
--
END xxcmn_common2_pkg;
/
