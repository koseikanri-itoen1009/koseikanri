CREATE OR REPLACE PACKAGE BODY xxcmn790001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn790001c(body)
 * Description      : 原料費原価計算処理
 * MD.050           : ロット別実際原価計算 T_MD050_BPO_790
 * MD.070           : 原料費原価計算処理 T_MD070_BPO_79A
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_table_data         取引別ロット別原価テーブル削除処理(A-1)
 *  get_opening_period     在庫オープン期間取得処理(A-2)
 *  get_ins_data           登録データ取得処理
 *  ins_table_batch        在庫データ抽出・登録処理(A-3)
 *  get_data_dump          データダンプ取得処理
 *  put_success_dump       成功データダンプ出力処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/1/31     1.0   Y.Kanami         新規作成
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
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  lock_expt                 EXCEPTION;     -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxcmn790001c';  -- パッケージ名
--
  gv_xxcmn          CONSTANT VARCHAR2(100)  := 'XXCMN';         -- モジュール名省略：XXCMNマスタ共通
--
  -- メッセージ
  gv_msg_xxcmn10146 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10146';  
                                            -- メッセージ：ロック取得エラー
  gv_msg_xxcmn10039 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10039';
                                            -- メッセージ：オープン期間取得エラー
  gv_msg_xxcmn10036 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10036';
                                            -- メッセージ：データ取得エラー
  gv_msg_xxcmn00005 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-00005';  
                                            -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 登録用PL/SQL表型
  TYPE doc_type_ttype   IS TABLE OF xxcmn_txn_lot_cost.doc_type%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 文書タイプ
  TYPE doc_id_ttype     IS TABLE OF xxcmn_txn_lot_cost.doc_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 文書ID
  TYPE item_id_ttype    IS TABLE OF xxcmn_txn_lot_cost.item_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 品目ID
  TYPE item_code_ttype  IS TABLE OF xxcmn_txn_lot_cost.item_code%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 品目コード
  TYPE lot_id_ttype     IS TABLE OF xxcmn_txn_lot_cost.lot_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ロットID
  TYPE lot_num_ttype    IS TABLE OF xxcmn_txn_lot_cost.lot_num%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ロットNo
  TYPE trans_qty_ttype  IS TABLE OF xxcmn_txn_lot_cost.trans_qty%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 取引数量
  TYPE unit_price_ttype IS TABLE OF xxcmn_txn_lot_cost.unit_price%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 単価
--
  -- 登録用PL/SQL表
  gt_doc_type_ins_tab   doc_type_ttype;     -- 文書タイプ
  gt_doc_id_ins_tab     doc_id_ttype;       -- 文書ID
  gt_item_id_ins_tab    item_id_ttype;      -- 品目ID
  gt_item_code_ins_tab  item_code_ttype;    -- 品目コード
  gt_lot_id_ins_tab     lot_id_ttype;       -- ロットID
  gt_lot_num_ins_tab    lot_num_ttype;      -- ロットNo
  gt_trans_qty_ins_tab  trans_qty_ttype;    -- 取引数量
  gt_unit_price_ins_tab unit_price_ttype;   -- 単価
--
  -- 入力データダンプ用PL/SQL表型
  TYPE msg_ttype      IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 在庫オープン期間
  gd_opening_date     DATE;
--
  /**********************************************************************************
   * Procedure Name   : del_table_data
   * Description      : 取引別ロット別原価テーブル削除処理(A-1)
   ***********************************************************************************/
  PROCEDURE del_table_data(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_table_data'; -- プログラム名
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
    -- *** ローカル・カーソル ***
    -- 表ロック取得
    CURSOR get_tab_lock_cur
    IS
      SELECT  xtlc.lot_id
      FROM    xxcmn_txn_lot_cost xtlc   -- 取引別ロット別原価（アドオン）
      FOR UPDATE NOWAIT
      ;
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
    -- ===============================
    -- 表ロック取得
    -- ===============================
    BEGIN
      <<get_lock_loop>>
      FOR loop_cnt IN get_tab_lock_cur LOOP
        EXIT;
      END LOOP get_lock_loop;
--
    EXCEPTION
      --*** ロック取得エラー ***
      WHEN lock_expt THEN
        IF (get_tab_lock_cur%ISOPEN) THEN
          CLOSE get_tab_lock_cur;
        END IF;
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn          -- モジュール名略称：XXCMN マスタ・経理共通
                     ,gv_msg_xxcmn10146 -- メッセージ：ロック取得エラー
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- 取引別ロット別原価（アドオン）全件削除
    -- =====================================
    DELETE FROM xxcmn_txn_lot_cost xtlc -- 取引別ロット別原価（アドオン）
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( get_tab_lock_cur%ISOPEN ) THEN
        CLOSE get_tab_lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( get_tab_lock_cur%ISOPEN ) THEN
        CLOSE get_tab_lock_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( get_tab_lock_cur%ISOPEN ) THEN
        CLOSE get_tab_lock_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_table_data;
--
  /**********************************************************************************
   * Procedure Name   : get_opening_period
   * Description      : 在庫オープン期間取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_opening_period(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_opening_period'; -- プログラム名
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
    cv_whse_code  CONSTANT VARCHAR2(100)  := 'XXCMN_COST_PRICE_WHSE_CODE';  -- 倉庫コード
--
    -- *** ローカル変数 ***
    lt_whse_code  xxcmn_item_locations_v.whse_code%TYPE;                    -- 倉庫コード
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================
    -- 倉庫コードを取得
    -- =====================================
    lt_whse_code  :=  FND_PROFILE.VALUE(cv_whse_code);
    IF (lt_whse_code IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- 会計期間開始日を取得
    -- =====================================
    SELECT  MIN(oap.period_start_date)                        -- 会計期間開始日
    INTO    gd_opening_date
    FROM    org_acct_periods       oap,                       -- 在庫会計期間
            xxcmn_item_locations_v ilv                        -- OPM保管場所情報VIEW
    WHERE   ilv.whse_code        = lt_whse_code               -- 倉庫コード
    AND     oap.organization_id  = ilv.mtl_organization_id    -- 組織ID
    AND     oap.open_flag        = 'Y'                        -- オープンフラグ
    ;
    IF (gd_opening_date IS NULL) THEN
--
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- モジュール名略称：XXCMN マスタ・経理共通
                   ,gv_msg_xxcmn10039   -- メッセージ：APP-XXCMN-10039 オープン期間取得エラー
                   ),1,5000);
      RAISE global_api_expt;
    END IF;
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
  END get_opening_period;
--
  /**********************************************************************************
   * Procedure Name   : get_ins_data
   * Description      : 登録データ取得処理
   ***********************************************************************************/
  PROCEDURE get_ins_data(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ins_data'; -- プログラム名
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
    cv_doc_type_porc      CONSTANT VARCHAR2(100)  := 'PORC';      -- 購買
    cv_doc_type_adji      CONSTANT VARCHAR2(100)  := 'ADJI';      -- 棚卸調整
    cv_dest_type_deliver  CONSTANT VARCHAR2(100)  := 'DELIVER';   -- 取引タイプ：購買
    cn_completion         CONSTANT NUMBER         := 1;           -- 完了区分：完了
    cv_zero               CONSTANT VARCHAR2(1)    := '0';         -- 実際原価：0
    cv_reason_cd_hamaoka  CONSTANT VARCHAR2(100)  := '浜岡受入';  -- 事由コード：浜岡受入
--
    -- *** ローカル変数 ***
    ln_data_cnt           NUMBER DEFAULT 0;   -- データカウント
--
    -- *** ローカル・カーソル ***
    -- 購買データ、浜岡受入データ取得カーソル
    CURSOR ins_data_cur IS
      SELECT  itp.doc_type          doc_type                    -- 文書タイプ
            , itp.doc_id            doc_id                      -- 文書ID
            , ximv.item_id          item_id                     -- 品目ID
            , ximv.item_no          item_no                     -- 品目コード
            , ilm.lot_id            lot_id                      -- ロットID
            , ilm.lot_no            lot_no                      -- ロットNo
            , SUM(itp.trans_qty)    trans_qty                   -- 数量
            , pla.unit_price        price                       -- 発注単価
      FROM    ic_tran_pnd           itp                         -- 保留在庫トランザクション
            , xxcmn_item_mst_v      ximv                        -- OPM品目情報View
            , rcv_shipment_lines    rsl                         -- 受入明細
            , rcv_transactions      rt                          -- 受入取引
            , ic_lots_mst           ilm                         -- OPMロットマスタ
            , po_lines_all          pla                         -- 発注明細
      WHERE itp.doc_type            =   cv_doc_type_porc        -- 文書タイプ：購買
      AND   itp.completed_ind       =   cn_completion           -- 完了区分：完了
      AND   itp.trans_date          >=  gd_opening_date         -- 取引日
      AND   itp.item_id             =   ximv.item_id            -- 品目ID
      AND   ximv.cost_manage_code   =   cv_zero                 -- 原価管理区分：0
      AND   itp.doc_id              =   rsl.shipment_header_id  -- 文書ID
      AND   itp.doc_line            =   rsl.line_num            -- 明細番号
      AND   rsl.shipment_header_id  =   rt.shipment_header_id   -- 受入内部ID
      AND   rsl.shipment_line_id    =   rt.shipment_line_id     -- 受入明細内部ID
      AND   rt.transaction_type     =   cv_dest_type_deliver    -- 取引タイプ
      AND   itp.item_id             =   ilm.item_id             -- 品目ID
      AND   itp.lot_id              =   ilm.lot_id              -- ロットID
      AND   rsl.po_line_id          =   pla.po_line_id          -- 発注明細ID
      GROUP BY  itp.doc_type        -- 文書タイプ
              , itp.doc_id          -- 文書ID
              , ximv.item_id        -- 品目ID
              , ximv.item_no        -- 品目コード
              , ilm.lot_id          -- ロットID
              , ilm.lot_no          -- ロットNo
              , pla.unit_price      -- 発注単価
      UNION ALL
      SELECT  itc.doc_type          doc_type                    -- 文書タイプ
            , itc.doc_id            doc_id                      -- 文書ID
            , ximv2.item_id         item_id                     -- 品目ID
            , ximv2.item_no         item_no                     -- 品目コード
            , ilm2.lot_id           lot_id                      -- ロットID
            , ilm2.lot_no           lot_no                      -- ロットNo
            , SUM(itc.trans_qty)    trans_qty                   -- 数量
            , lcad.adjustment_cost  price                       -- 原価調整単価
      FROM    ic_tran_cmp                   itc                 -- 完了在庫トランザクション
            , xxcmn_item_mst_v              ximv2               -- OPM品目情報View
            , gmf_lot_cost_adjustments      lca                 -- ロット原価調整
            , gmf_lot_cost_adjustment_dtls  lcad                -- ロット原価調整明細
            , ic_lots_mst                   ilm2                -- OPMロットマスタ
            , sy_reas_cds_vl                srcv                -- 事由コード
      WHERE itc.doc_type              =   cv_doc_type_adji      -- 文書タイプ：棚卸調整
      AND   srcv.reason_desc1         =   cv_reason_cd_hamaoka  -- 適用：浜岡受入
      AND   itc.reason_code           =   srcv.reason_code      -- 事由コード
      AND   itc.trans_date            >=  gd_opening_date       -- 取引日
      AND   itc.item_id               =   ximv2.item_id         -- 品目ID
      AND   ximv2.cost_manage_code    =   cv_zero               -- 原価管理区分：0
      AND   itc.item_id               =   ilm2.item_id          -- 品目ID
      AND   itc.lot_id                =   ilm2.lot_id           -- ロットID
      AND   itc.item_id               =   lca.item_id           -- 品目ID
      AND   itc.lot_id                =   lca.lot_id            -- ロットID
      AND   lca.adjustment_id         =   lcad.adjustment_id    -- ロット原価調整ID
      GROUP BY  itc.doc_type          -- 文書タイプ
              , itc.doc_id            -- 文書ID
              , ximv2.item_id         -- 品目ID
              , ximv2.item_no         -- 品目コード
              , ilm2.lot_id           -- ロットID
              , ilm2.lot_no           -- ロットNo
              , lcad.adjustment_cost  -- 原価調整単価
      ;
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
    -- ========================================
    -- 購買、浜岡受入データをPL/SQL表にセット
    -- ========================================
    << get_data_cur >>
    FOR loop_cnt IN ins_data_cur LOOP
--
      -- 数量が0の場合は取り込まない
      IF (loop_cnt.trans_qty > 0) THEN
--
        -- データカウント
        ln_data_cnt :=  ln_data_cnt + 1;
--
        -- 値セット
        gt_doc_type_ins_tab(ln_data_cnt)    := loop_cnt.doc_type;   -- 文書タイプ
        gt_doc_id_ins_tab(ln_data_cnt)      := loop_cnt.doc_id;     -- 文書ID
        gt_item_id_ins_tab(ln_data_cnt)     := loop_cnt.item_id;    -- 品目ID
        gt_item_code_ins_tab(ln_data_cnt)   := loop_cnt.item_no;    -- 品目コード
        gt_lot_id_ins_tab(ln_data_cnt)      := loop_cnt.lot_id;     -- ロットID
        gt_lot_num_ins_tab(ln_data_cnt)     := loop_cnt.lot_no;     -- ロットNo
        gt_trans_qty_ins_tab(ln_data_cnt)   := loop_cnt.trans_qty;  -- 数量
        gt_unit_price_ins_tab(ln_data_cnt)  := loop_cnt.price;      -- 発注単価/原価調整単価
--
      END IF;
--
    END LOOP get_data_cur;
--
    IF ( ln_data_cnt > 0 ) THEN
      -- データカウントを成功データカウントにセット
      gn_normal_cnt :=  ln_data_cnt;
    ELSE
      -- 処理対象レコードが0件の場合
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- モジュール名略称：XXCMN マスタ・経理共通
                   ,gv_msg_xxcmn10036   -- メッセージ：APP-XXCMN-10036 データ取得エラー
                   ),1,5000);
      RAISE global_api_expt;
    END IF;
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
  END get_ins_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_table_batch
   * Description      : 在庫データ抽出・登録処理(A-3)
   ***********************************************************************************/
  PROCEDURE ins_table_batch(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_table_batch'; -- プログラム名
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
    -- =====================================
    -- 登録データ取得処理
    -- =====================================
    get_ins_data(
       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 登録データ取得処理がエラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- 一括登録処理
    -- =====================================
    FORALL ln_cnt IN 1..gt_doc_type_ins_tab.COUNT
      INSERT INTO xxcmn_txn_lot_cost(
          doc_type
        , doc_id
        , item_id
        , item_code
        , lot_id
        , lot_num
        , trans_qty
        , unit_price
        , created_by
        , creation_date
        , last_updated_by
        , last_update_date
        , last_update_login
        , request_id
        , program_application_id
        , program_id
        , program_update_date
      ) VALUES (
          gt_doc_type_ins_tab(ln_cnt)           -- 文書タイプ
        , gt_doc_id_ins_tab(ln_cnt)             -- 文書ID
        , gt_item_id_ins_tab(ln_cnt)            -- 品目ID
        , gt_item_code_ins_tab(ln_cnt)          -- 品目コード
        , gt_lot_id_ins_tab(ln_cnt)             -- ロットID
        , gt_lot_num_ins_tab(ln_cnt)            -- ロットNo
        , NVL(gt_trans_qty_ins_tab(ln_cnt), 0)  -- 取引数量
        , NVL(gt_unit_price_ins_tab(ln_cnt), 0) -- 単価
        , FND_GLOBAL.USER_ID                    -- 作成者
        , SYSDATE                               -- 作成日
        , FND_GLOBAL.USER_ID                    -- 最終更新者
        , SYSDATE                               -- 最終更新日
        , FND_GLOBAL.LOGIN_ID                   -- 最終更新ログイン
        , FND_GLOBAL.CONC_REQUEST_ID            -- 要求ID
        , FND_GLOBAL.PROG_APPL_ID               -- コンカレント・プログラム・アプリケーションID
        , FND_GLOBAL.CONC_PROGRAM_ID            -- コンカレント・プログラムID
        , SYSDATE                               -- プログラム更新日
      );
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
  END ins_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : get_data_dump
   * Description      : データダンプ取得処理
   ***********************************************************************************/
  PROCEDURE get_data_dump(
    ir_xxcmn_txn_lot_cost IN  xxcmn_txn_lot_cost%ROWTYPE,  
                                                -- 取引別ロット別原価（アドオン）
    ov_dump               OUT NOCOPY VARCHAR2,  -- データダンプ文字列
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data_dump'; -- プログラム名
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
    -- ===============================
    -- データダンプ作成
    -- ===============================
    ov_dump :=  ir_xxcmn_txn_lot_cost.doc_type            -- 文書タイプ
                || gv_msg_comma ||  
                TO_CHAR(ir_xxcmn_txn_lot_cost.doc_id)     -- 文書ID
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.item_id)    -- 品目ID
                || gv_msg_comma ||
                ir_xxcmn_txn_lot_cost.item_code           -- 品目コード
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.lot_id)     -- ロットID
                || gv_msg_comma ||
                ir_xxcmn_txn_lot_cost.lot_num             -- ロットNO
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.trans_qty)  -- 取引数量
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.unit_price) -- 単価
                ;
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
  END get_data_dump;
--
  /**********************************************************************************
   * Procedure Name   : put_success_dump
   * Description      : 成功データダンプ出力処理
   ***********************************************************************************/
  PROCEDURE put_success_dump(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_success_dump'; -- プログラム名
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
    lv_msg  VARCHAR2(5000);  -- メッセージ
    lv_dump VARCHAR2(5000);  -- データダンプ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    ins_data_rec  xxcmn_txn_lot_cost%ROWTYPE; -- 取引別ロット別原価（アドオン）型レコード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 成功データ（見出し）
    lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                 gv_xxcmn               -- モジュール名略称：XXCMN 共通
                ,gv_msg_xxcmn00005      -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
                ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    << success_dump_set_loop >>
    FOR ln_rec_cnt IN 1..gt_doc_type_ins_tab.COUNT LOOP
--
      -- =============================
      -- ダンプ用レコードにセット
      -- =============================
      ins_data_rec.doc_type   := gt_doc_type_ins_tab(ln_rec_cnt);    -- 文書タイプ
      ins_data_rec.doc_id     := gt_doc_id_ins_tab(ln_rec_cnt);      -- 文書ID
      ins_data_rec.item_id    := gt_item_id_ins_tab(ln_rec_cnt);     -- 品目ID
      ins_data_rec.item_code  := gt_item_code_ins_tab(ln_rec_cnt);   -- 品目コード
      ins_data_rec.lot_id     := gt_lot_id_ins_tab(ln_rec_cnt);      -- ロットID
      ins_data_rec.lot_num    := gt_lot_num_ins_tab(ln_rec_cnt);     -- ロットNo
      ins_data_rec.trans_qty  := gt_trans_qty_ins_tab(ln_rec_cnt);   -- 数量
      ins_data_rec.unit_price := gt_unit_price_ins_tab(ln_rec_cnt);  -- 単価
--
      -- =============================
      -- データダンプ取得処理
      -- =============================
      get_data_dump(
          ir_xxcmn_txn_lot_cost => ins_data_rec
        , ov_dump               => lv_dump
        , ov_errbuf             => lv_errbuf
        , ov_retcode            => lv_retcode
        , ov_errmsg             => lv_errmsg
      );
      -- データダンプ取得処理がエラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- 成功データを出力
      -- =============================
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dump);
--
    END LOOP success_dump_set_loop;
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
  END put_success_dump;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- 登録用PL/SQL表初期化
    gt_doc_type_ins_tab.DELETE;   -- 文書タイプ
    gt_doc_id_ins_tab.DELETE;     -- 文書ID
    gt_item_id_ins_tab.DELETE;    -- 品目ID
    gt_item_code_ins_tab.DELETE;  -- 品目コード
    gt_lot_id_ins_tab.DELETE;     -- ロットID
    gt_lot_num_ins_tab.DELETE;    -- ロットNo
    gt_trans_qty_ins_tab.DELETE;  -- 取引数量
    gt_unit_price_ins_tab.DELETE; -- 単価
--
    -- =======================================
    -- A-1.取引別ロット別原価テーブル削除処理
    -- =======================================
    del_table_data(
       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- A-2.在庫オープン期間取得処理
    -- =======================================
    get_opening_period(
       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- A-3.在庫データ抽出・登録処理
    -- =======================================
    ins_table_batch(
       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 在庫データ抽出・登録処理がエラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- 成功データダンプ出力処理
    -- =======================================
    put_success_dump(
       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 成功データダンプ出力処理がエラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf  OUT NOCOPY VARCHAR2,  --   エラー・メッセージ  --# 固定 #
    retcode OUT NOCOPY VARCHAR2   --   リターン・コード    --# 固定 #
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxcmn790001c;
/
