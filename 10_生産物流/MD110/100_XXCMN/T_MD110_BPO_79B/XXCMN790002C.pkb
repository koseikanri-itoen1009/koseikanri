CREATE OR REPLACE PACKAGE BODY xxcmn790002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn790002c(body)
 * Description      : 半製品原価計算処理
 * MD.050           : ロット別実際原価計算 T_MD050_BPO_790
 * MD.070           : 半製品原価計算処理 T_MD070_BPO_79B
 * Version          : 1.4
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  get_opening_period           在庫オープン期間取得処理(B-1)
 *  get_row_materials            投入品データ抽出処理(B-5)
 *  set_decition_unit_price      半製品単価確定処理(B-7)
 *  get_inject_prod_unit_price   投入品単価確定処理(B-8)
 *  ins_table_batch              半製品データ登録処理(B-9)
 *  get_data_dump                データダンプ取得処理
 *  put_success_dump             成功データダンプ出力処理
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/2/13     1.0   Y.Kanami         新規作成
 *  2008/04/25    1.2   Marushita        TE080_BPO_790 不具合ID 1
 *  2008/06/03    1.3   Marushita        TE080_BPO_790 不具合ID 1
 *  2008/07/03    1.4   Marushita        ST不具合314対応
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
  gn_error_cnt     NUMBER DEFAULT 0;          -- エラー件数
  gn_warn_cnt      NUMBER DEFAULT 0;          -- スキップ件数
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
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxcmn790002c';  -- パッケージ名
--
  gv_xxcmn          CONSTANT VARCHAR2(100)  := 'XXCMN';         -- モジュール名省略：XXCMNマスタ共通
--
  gv_msg_xxcmn10039 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10039';
                                            -- メッセージ：オープン期間取得エラー
  gv_msg_xxcmn10036 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10036';
                                            -- メッセージ：データ取得エラー
  gv_msg_xxcmn10002 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10002';  
                                            -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
  gv_msg_xxcmn00005 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-00005';  
                                            -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
  gv_tkn_ng_profile CONSTANT VARCHAR2(100)  := 'NG_PROFILE';
                                            -- トークン：NG_PROFILE
--
  gv_doc_type_prod    CONSTANT VARCHAR2(100)  := 'PROD';  -- 文書タイプ：生産
  gn_completion       CONSTANT NUMBER         := 1;       -- 完了区分：完了
  gn_l_type_finished  CONSTANT NUMBER         := 1;       -- 明細タイプ：完成品
  gn_l_type_product   CONSTANT NUMBER         := 2;       -- 明細タイプ：副産物
  gn_l_type_materials CONSTANT NUMBER         := -1;      -- 明細タイプ：投入品
  gv_real_cost_price  CONSTANT VARCHAR2(1)    := '0';     -- 実際原価：0
  gv_standard_cost    CONSTANT VARCHAR2(1)    := '1';     -- 標準原価：1
  gn_cmpcls_material  CONSTANT NUMBER         := 1;       -- コンポーネント区分：原料
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- データダンプ用レコード型
  TYPE data_dump_rtype IS RECORD(
      batch_id    xxcmn_txn_lot_cost.doc_id%TYPE      -- バッチID
    , trans_date  ic_tran_pnd.trans_date%TYPE         -- 取引日
    , item_id     xxcmn_txn_lot_cost.item_id%TYPE     -- 品目ID
    , item_code   xxcmn_txn_lot_cost.item_code%TYPE   -- 品目コード
    , lot_id      xxcmn_txn_lot_cost.lot_id%TYPE      -- ロットID
    , lot_num     xxcmn_txn_lot_cost.lot_num%TYPE     -- ロットNO
    , trans_qty   xxcmn_txn_lot_cost.trans_qty%TYPE   -- 取引数量
    , unit_price  xxcmn_txn_lot_cost.unit_price%TYPE  -- 半製品単価
  );
--
  -- 投入品PL/SQL表レコード
  TYPE row_materials_rtype IS RECORD(
      item_id               xxcmn_item_mst_v.item_id%TYPE       -- 品目ID
    , lot_id                ic_lots_mst.lot_id%TYPE             -- ロットID
    , materials_qty         ic_tran_pnd.trans_qty%TYPE          -- 投入数量
    , materials_unit_price  xxcmn_txn_lot_cost.unit_price%TYPE  -- 投入品単価
    , materials_cost_price  NUMBER  -- 投入品原価：投入数量*投入品単価
  );
--
  -- 投入品PL/SQL表型
  TYPE row_materials_ttype IS TABLE OF row_materials_rtype INDEX BY BINARY_INTEGER;
--
  -- 半製品PL/SQL表用レコード型
  TYPE half_finish_goods_rtype IS RECORD(
      batch_id        ic_tran_pnd.doc_id%TYPE             -- バッチID
    , trans_date      ic_tran_pnd.trans_date%TYPE         -- 取引日
    , item_id         xxcmn_item_mst_v.item_id%TYPE       -- 品目ID
    , item_no         xxcmn_item_mst_v.item_no%TYPE       -- 品目コード
    , lot_id          ic_lots_mst.lot_id%TYPE             -- ロットID
    , lot_no          ic_lots_mst.lot_no%TYPE             -- ロットNO
    , trans_qty       ic_tran_pnd.trans_qty%TYPE          -- 取引数量
    , by_prod_qty     ic_tran_pnd.trans_qty%TYPE          -- 副産物取引数量
    , by_prod_price   cm_cmpt_dtl.cmpnt_cost%TYPE         -- 副産物単価
    , half_fin_price  xxcmn_txn_lot_cost.unit_price%TYPE  -- 半製品単価
    , row_materials   row_materials_ttype                 -- 投入品PL/SQL表型
  );
--
  -- 半製品PL/SQL表型
  TYPE half_finish_goods_ttype IS TABLE OF half_finish_goods_rtype INDEX BY BINARY_INTEGER;
--
  -- 確定データPL/SQL表型
  TYPE doc_id_ttype       IS TABLE OF xxcmn_txn_lot_cost.doc_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 文書ID
  TYPE trans_date_ttype   IS TABLE OF ic_tran_pnd.trans_date%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 取引日付
  TYPE item_id_ttype      IS TABLE OF xxcmn_txn_lot_cost.item_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 品目ID
  TYPE item_code_ttype    IS TABLE OF xxcmn_txn_lot_cost.item_code%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 品目コード
  TYPE lot_id_ttype       IS TABLE OF xxcmn_txn_lot_cost.lot_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ロットID
  TYPE lot_num_ttype      IS TABLE OF xxcmn_txn_lot_cost.lot_num%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ロットNo
  TYPE trans_qty_ttype    IS TABLE OF xxcmn_txn_lot_cost.trans_qty%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 取引数量
  TYPE unit_price_ttype   IS TABLE OF xxcmn_txn_lot_cost.unit_price%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 単価
--
  -- 半製品単価確定チェック用PL/SQL表型
  TYPE decision_chk_ttype IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_whse_code        xxcmn_item_locations_v.whse_code%TYPE;  -- 倉庫コード
  gd_opening_date     DATE;                                   -- 在庫オープン期間
  gn_index_cnt        NUMBER  DEFAULT 0;                      -- 半製品取得データカウント
  gn_decision_cnt     NUMBER  DEFAULT 0;                      -- 確定データカウント
  gn_row_material_cnt NUMBER  DEFAULT 0;                      -- 投入品データカウント
--
  -- 半製品PL/SQL表
  gt_half_finish_goods_tab  half_finish_goods_ttype;
--
  -- 確定データPL/SQL表
  gt_doc_id_ins_tab     doc_id_ttype;       -- 文書ID
  gt_trans_date_ins_tab trans_date_ttype;   -- 取引日
  gt_item_id_ins_tab    item_id_ttype;      -- 品目ID
  gt_item_code_ins_tab  item_code_ttype;    -- 品目コード
  gt_lot_id_ins_tab     lot_id_ttype;       -- ロットID
  gt_lot_num_ins_tab    lot_num_ttype;      -- ロットNo
  gt_trans_qty_ins_tab  trans_qty_ttype;    -- 取引数量
  gt_unit_price_ins_tab unit_price_ttype;   -- 単価
--
  /**********************************************************************************
   * Procedure Name   : get_opening_period
   * Description      : 在庫オープン期間取得処理(B-1)
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
    cv_whse_code      CONSTANT VARCHAR2(100)  := 'XXCMN_COST_PRICE_WHSE_CODE';  -- PROFILE:原価倉庫
    cv_whse_code_name CONSTANT VARCHAR2(100)  := 'XXCMN:原価倉庫';              -- PROFILE名:原価倉庫
    cv_yes            CONSTANT VARCHAR2(1)    := 'Y';                           -- YES
--
    -- *** ローカル変数 ***
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
    gt_whse_code  :=  FND_PROFILE.VALUE(cv_whse_code);
    IF (gt_whse_code IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- モジュール名略称：XXCMN 共通
                   ,gv_msg_xxcmn10002   -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                   ,gv_tkn_ng_profile   -- トークン：NGプロファイル名
                   ,cv_whse_code_name   -- 原価倉庫
                   ),1,5000);
--
      RAISE global_api_expt;
--
    END IF;
--
    -- =====================================
    -- 会計期間開始日を取得
    -- =====================================
    SELECT  MIN(oap.period_start_date)                        -- 会計期間開始日
    INTO    gd_opening_date
    FROM    org_acct_periods       oap,                       -- 在庫会計期間
            xxcmn_item_locations_v ilv                        -- OPM保管場所情報VIEW
    WHERE   ilv.whse_code        = gt_whse_code               -- 倉庫コード
    AND     oap.organization_id  = ilv.mtl_organization_id    -- 組織ID
    AND     oap.open_flag        = cv_yes                     -- オープンフラグ
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
   * Procedure Name   : get_row_materials
   * Description      : 投入品データ抽出処理(B-5)
   ***********************************************************************************/
  PROCEDURE get_row_materials(
    in_batch_id   IN  ic_tran_pnd.doc_id%TYPE,  -- バッチID
    ov_errbuf     OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_row_materials'; -- プログラム名
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
    cv_item_div_material  CONSTANT VARCHAR2(1)  :=  '2';  -- 品目区分：資材
--
    -- *** ローカル変数 ***
    ln_loop_cnt             NUMBER DEFAULT 0;     -- データカウンタ
    ln_data_cnt             NUMBER DEFAULT 0;     -- データカウンタ
    ln_cost_price           NUMBER DEFAULT NULL;  -- 投入品原価
    ln_sum_cost_price       NUMBER DEFAULT 0;     -- 投入品原価合算
    ln_half_fin_unit_price  NUMBER DEFAULT 0;     -- 半製品単価
    ln_by_prod_cost_price   NUMBER DEFAULT 0;     -- 副産物原価
--
    -- *** ローカル・カーソル ***
--
    -- 投入品データ取得
    CURSOR row_materials_cur(batch_id ic_tran_pnd.doc_id%TYPE) IS
      SELECT  ximv.item_id              item_id             -- 品目ID
            , itp.lot_id                lot_id              -- ロットID
            , SUM(itp.trans_qty)        trans_qty           -- 投入数量
            , xtlc.unit_price           unit_price          -- 単価
      FROM    ic_tran_pnd               itp                 -- 保留在庫トランザクション
            , xxcmn_item_mst_v          ximv                -- OPM品目情報View
            , xxcmn_txn_lot_cost        xtlc                -- 取引別ロット別原価（アドオン）
            , xxcmn_item_categories4_v  xic                 -- OPM品目カテゴリ割当情報VIEW4
      WHERE itp.doc_id            =   batch_id              -- バッチID
      AND   itp.doc_type          =   gv_doc_type_prod      -- 文書タイプ：生産
      AND   itp.completed_ind     =   gn_completion         -- 完了区分：完了
      AND   itp.line_type         =   gn_l_type_materials   -- 明細タイプ：投入品
      AND   itp.reverse_id        IS NULL
      AND   itp.item_id           =   ximv.item_id          -- 品目ID
      AND   ximv.cost_manage_code =   gv_real_cost_price    -- 原価管理区分：実際原価
      AND   itp.item_id           =   xtlc.item_id(+)       -- 品目ID
      AND   itp.lot_id            =   xtlc.lot_id(+)        -- ロットID
      AND   itp.item_id           =   xic.item_id           -- 品目ID
      AND   xic.item_class_code   <>  cv_item_div_material  -- 品目区分：資材以外
      GROUP BY 
              ximv.item_id
            , itp.lot_id
            , xtlc.unit_price
      UNION ALL
      SELECT  ximv.item_id                item_id           -- 品目ID
            , itp.lot_id                  lot_id            -- ロットID
            , NVL(SUM(itp.trans_qty),0)   trans_qty         -- 投入数量
            , ccd.cmpnt_cost              unit_price        -- 単価
      FROM    ic_tran_pnd               itp                 -- 保留在庫トランザクション
            , xxcmn_item_mst_v          ximv                -- OPM品目情報View
            , (SELECT cc.calendar_code          calendar_code
                     ,cc.item_id                item_id
                     ,NVL(SUM(cc.cmpnt_cost),0) cmpnt_cost
               FROM  cm_cmpt_dtl cc
               WHERE cc.whse_code =   gt_whse_code
               GROUP BY calendar_code,item_id ) ccd         -- 標準原価マスタ
            , cm_cldr_hdr_b             clh                 -- 原価カレンダヘッダ
            , cm_cldr_dtl               cll                 -- 原価カレンダ明細
            , xxcmn_item_categories4_v  xic                 -- OPM品目カテゴリ割当情報VIEW4
      WHERE itp.doc_id            =   batch_id              -- バッチID
      AND   itp.doc_type          =   gv_doc_type_prod      -- 文書タイプ：生産
      AND   itp.completed_ind     =   gn_completion         -- 完了区分：完了
      AND   itp.line_type         =   gn_l_type_materials   -- 明細タイプ：投入品
      AND   itp.reverse_id        IS NULL
      AND   itp.item_id           =   ximv.item_id          -- 品目ID
      AND   ximv.cost_manage_code =   gv_standard_cost      -- 原価管理区分：標準原価
      AND   itp.item_id           =   ccd.item_id           -- 品目ID
      AND   ccd.calendar_code     =   clh.calendar_code     -- 原価カレンダーコード
      AND   clh.calendar_code     =   cll.calendar_code     -- 原価カレンダーコード
      AND   itp.trans_date        >=  cll.start_date        -- 期間（自）
      AND   itp.trans_date        <=  cll.end_date          -- 期間（至）
      AND   itp.item_id           =   xic.item_id           -- 品目ID
      AND   xic.item_class_code   <>  cv_item_div_material  -- 品目区分：資材以外
      GROUP BY
              ximv.item_id
            , itp.lot_id
            , ccd.cmpnt_cost
      ;
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
    --=================================
    -- B-6.投入品データ格納処理
    --=================================
    <<get_materials_loop>>
    FOR materials_loop IN row_materials_cur(in_batch_id) LOOP
--
      ln_loop_cnt := ln_loop_cnt + 1;
      gt_half_finish_goods_tab(gn_index_cnt).row_materials(ln_loop_cnt).item_id
          := materials_loop.item_id;                                                -- 品目ID
      gt_half_finish_goods_tab(gn_index_cnt).row_materials(ln_loop_cnt).lot_id
          := materials_loop.lot_id;                                                 -- ロットID
      gt_half_finish_goods_tab(gn_index_cnt).row_materials(ln_loop_cnt).materials_qty
          := materials_loop.trans_qty * -1;                                         -- 投入数量*-1
      gt_half_finish_goods_tab(gn_index_cnt).row_materials(ln_loop_cnt).materials_unit_price
          := materials_loop.unit_price;                                             -- 投入品単価
      gt_half_finish_goods_tab(gn_index_cnt).row_materials(ln_loop_cnt).materials_cost_price
          := materials_loop.unit_price * materials_loop.trans_qty * -1;             -- 投入品原価
--
    END LOOP get_meterials_loop;
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
  END get_row_materials;
  /**********************************************************************************
   * Procedure Name   : set_decition_unit_price
   * Description      : 半製品単価確定処理(B-7)
   ***********************************************************************************/
  PROCEDURE set_decition_unit_price(
    in_index_cnt  IN          NUMBER,         -- INDEXカウンタ
    ov_errbuf     OUT NOCOPY  VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY  VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY  VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_decition_unit_price'; -- プログラム名
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
    cv_item_div_material  CONSTANT VARCHAR2(1)  :=  '2';  -- 品目区分：資材
--
    -- *** ローカル変数 ***
    ln_data_cnt             NUMBER DEFAULT 0;     -- データカウンタ
    ln_cost_price           NUMBER DEFAULT NULL;  -- 投入品原価
    ln_sum_cost_price       NUMBER DEFAULT 0;     -- 投入品原価合算
    ln_half_fin_unit_price  NUMBER DEFAULT 0;     -- 半製品単価
    ln_by_prod_cost_price   NUMBER DEFAULT 0;     -- 副産物原価
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
    -- 投入品原価が確定したか確認
    <<unit_price_decision_loop>>
    FOR i IN 1..gt_half_finish_goods_tab(in_index_cnt).row_materials.COUNT LOOP
      ln_data_cnt :=  ln_data_cnt + 1;
      -- 投入品原価取得
      ln_cost_price :=  gt_half_finish_goods_tab(in_index_cnt)
                        .row_materials(ln_data_cnt)
                        .materials_cost_price;
--
      IF (ln_cost_price IS NULL) THEN
        ln_sum_cost_price  := NULL;
        EXIT;
      ELSE
        -- 合算する
        ln_sum_cost_price := ln_sum_cost_price + ln_cost_price;
      END IF;
    END LOOP unit_price_decision_loop;
--
    -- 投入品が存在する場合
    IF (ln_data_cnt > 0) THEN
--
      -- 全ての投入品原価が確定した場合
      IF (ln_sum_cost_price IS NOT NULL) THEN
        -- =================================
        -- 半製品単価計算処理
        -- =================================
        -- 副産物原価を算出する
        ln_by_prod_cost_price :=  gt_half_finish_goods_tab(in_index_cnt).by_prod_price  
                                                                          -- 副産物単価
                                  * gt_half_finish_goods_tab(in_index_cnt).by_prod_qty;
                                                                          -- 副産物取引数量
--
        -- 半製品単価を算出する
        IF (gt_half_finish_goods_tab(in_index_cnt).trans_qty = 0) THEN
          -- 取引数量が0の場合
          ln_half_fin_unit_price  := 0;
        ELSE
          ln_half_fin_unit_price  := ROUND((ln_sum_cost_price - ln_by_prod_cost_price)
                                                                          -- 投入品原価 - 副産物原価
                                      / gt_half_finish_goods_tab(in_index_cnt).trans_qty, 2);
                                                                          -- 取引数量
        END IF;
--
        -- 半製品PL/SQL表の半製品単価にセットする
        gt_half_finish_goods_tab(in_index_cnt).half_fin_price :=  ln_half_fin_unit_price;
--
        -- =================================
        -- 半製品原価情報確定処理
        -- =================================
        gn_decision_cnt :=  gn_decision_cnt + 1;  -- 確定データカウント
        -- 確定データPL/SQL表に格納する
        gt_doc_id_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).batch_id;       -- 文書ID
        gt_trans_date_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).trans_date;     -- 取引日                                      -- 文書タイプ
        gt_item_id_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).item_id;        -- 品目ID
        gt_item_code_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).item_no;        -- 品目コード
        gt_lot_id_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).lot_id;         -- ロットID
        gt_lot_num_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).lot_no;         -- ロットNO
        gt_trans_qty_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).trans_qty;      -- 取引数量
        gt_unit_price_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).half_fin_price; -- 単価
--
      END IF;
--
      -- 成功データカウント
      gn_normal_cnt := gn_decision_cnt;
--
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
  END set_decition_unit_price;
--
  /**********************************************************************************
   * Procedure Name   : get_inject_prod_unit_price
   * Description      : 投入品単価確定処理(B-8)
   ***********************************************************************************/
  PROCEDURE get_inject_prod_unit_price(
    ov_errbuf     OUT NOCOPY  VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY  VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY  VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inject_prod_unit_price'; -- プログラム名
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
    cn_decision           CONSTANT NUMBER := 1; -- 単価確定
    cn_non_decision       CONSTANT NUMBER := 0; -- 単価未確定
    cn_no_change          CONSTANT NUMBER := 0; -- 変更なし
    cn_change             CONSTANT NUMBER := 1; -- 変更あり
    cn_first              CONSTANT NUMBER := 1; -- 初回
    cn_second             CONSTANT NUMBER := 2; -- ２回目
--
    -- *** ローカル変数 ***
    lt_pre_chk_tab        decision_chk_ttype;           -- 前回チェック
    lt_curr_chk_tab       decision_chk_ttype;           -- 今回チェック
    ln_half_fin_goods_cnt NUMBER DEFAULT 0;             -- 半製品読込カウンタ
    lb_decition_flag      BOOLEAN DEFAULT TRUE;         -- 単価確定フラグ
    ln_change_flag        NUMBER DEFAULT cn_no_change;  -- 変更チェックフラグ
    ln_chk_cnt            NUMBER DEFAULT 0;             -- ループ回数チェック
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
    -- 単価確定チェック用PL/SQL表初期化
    lt_pre_chk_tab.DELETE;
    lt_curr_chk_tab.DELETE;
--
    -- 半製品データ読込
    <<half_finish_goods_loop>>
    LOOP
--
      ln_half_fin_goods_cnt :=  ln_half_fin_goods_cnt + 1;
--
      -- 半製品単価が未確定の場合
      IF (gt_half_finish_goods_tab(ln_half_fin_goods_cnt).half_fin_price IS NULL) THEN
--
        -- 投入品データ読込
        <<row_materials_loop>>
        FOR ln_cnt_2 IN 1..gt_half_finish_goods_tab(ln_half_fin_goods_cnt).row_materials.COUNT LOOP
--
          -- 投入品原価が未確定の場合
          IF (gt_half_finish_goods_tab(ln_half_fin_goods_cnt).row_materials(ln_cnt_2)
              .materials_cost_price IS NULL) THEN
--
            -- 確定データPL/SQL表読込
            <<decition_data_loop>>
            FOR ln_cnt_3 IN 1..gt_doc_id_ins_tab.COUNT LOOP
--
              -- 確定データに品目ID、ロットIDが一致するデータが存在する場合
              IF (
                    (gt_half_finish_goods_tab(ln_half_fin_goods_cnt).row_materials(ln_cnt_2).item_id 
                      = gt_item_id_ins_tab(ln_cnt_3))                                   -- 品目ID
                AND
                    (gt_half_finish_goods_tab(ln_half_fin_goods_cnt).row_materials(ln_cnt_2).lot_id
                      = gt_lot_id_ins_tab(ln_cnt_3))                                    -- ロットID
                 )                                    
              THEN
--
                -- 単価を投入品PL/SQL表の投入品単価にセットする
                gt_half_finish_goods_tab(ln_half_fin_goods_cnt)
                  .row_materials(ln_cnt_2).materials_unit_price 
                :=  gt_unit_price_ins_tab(ln_cnt_3);                              -- 単価
--
                -- 単価*数量を投入品PL/SQL表の投入品原価にセットする
                gt_half_finish_goods_tab(ln_half_fin_goods_cnt)
                  .row_materials(ln_cnt_2).materials_cost_price 
                := gt_half_finish_goods_tab(ln_half_fin_goods_cnt)
                  .row_materials(ln_cnt_2).materials_qty * gt_unit_price_ins_tab(ln_cnt_3);  
                                                                                  -- 投入品原価
--
              END IF;
--
            END LOOP decition_data_loop;
--
          END IF;
--
        END LOOP row_materials_loop;
--
        --=================================
        -- B-7.半製品単価確定処理
        --=================================
        set_decition_unit_price(
            in_index_cnt  =>  ln_half_fin_goods_cnt -- データカウンタ
          , ov_errbuf     =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
          , ov_retcode    =>  lv_retcode            -- リターン・コード             --# 固定 #
          , ov_errmsg     =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- エラーの場合は処理終了
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;

--
      END IF;
--
      -- 最後まで読み込んだ場合
      IF (ln_half_fin_goods_cnt = gn_index_cnt) THEN
        <<chk_unit_price_loop>>
        -- 半製品の単価が全て確定したか確認する
        FOR i IN 1..gn_index_cnt LOOP
          -- 未確定の単価が存在した場合
          IF (gt_half_finish_goods_tab(i).half_fin_price IS NULL) THEN
--
            -- 確定フラグを未確定にする
            lb_decition_flag  := FALSE;
--
            -- 今回チェックPL/SQL表に未確定をセット
            lt_curr_chk_tab(i)  := cn_non_decision; -- 未確定
          ELSE
            -- 今回チェックPL/SQL表に確定をセット
            lt_curr_chk_tab(i)  := cn_decision;     -- 確定
          END IF;
--
        END LOOP chk_unit_price_loop;
--
        IF (lb_decition_flag) THEN
          -- 全ての半製品単価が確定した場合
          EXIT;
        ELSE
          -- チェック回数をセット
          ln_chk_cnt := ln_chk_cnt + 1;
--
          -- 半製品読込カウンタリセット
          ln_half_fin_goods_cnt := 0;
          -- 確定フラグをリセット
          lb_decition_flag := TRUE;
--
          IF (ln_chk_cnt = cn_first) THEN
--
            <<set_loop_1>>
            FOR cnt_1 IN 1..gn_index_cnt LOOP
              -- 今回のチェック結果を前回チェックにセットする
              lt_pre_chk_tab(cnt_1) := lt_curr_chk_tab(cnt_1);
            END LOOP set_loop_1;
            -- 今回チェックPL/SQL表を初期化
            lt_curr_chk_tab.DELETE;
--
          ELSIF (ln_chk_cnt >= cn_second) THEN
            <<chk_loop>>
            FOR cnt_2 IN 1..gn_index_cnt LOOP
--
              IF (lt_pre_chk_tab(cnt_2) <> lt_curr_chk_tab(cnt_2)) THEN
--
                ln_change_flag := cn_change;
                -- 1箇所でも変更箇所があればループを抜ける
                EXIT;
              END IF;
            END LOOP chk_loop;
--
            -- 前回より確定された単価が存在する場合
            IF (ln_change_flag = cn_change) THEN
              -- 前回チェックPL/SQL表を初期化
              lt_pre_chk_tab.DELETE;
              -- 今回のチェック結果を前回チェック結果にセットする
              <<set_loop_2>>
              FOR cnt_3 IN 1..gn_index_cnt LOOP
                -- 今回のチェック結果を前回チェックにセットする
                lt_pre_chk_tab(cnt_3) := lt_curr_chk_tab(cnt_3);
              END LOOP set_loop_2;
              -- 今回チェックPL/SQL表を初期化
              lt_curr_chk_tab.DELETE;
              -- 変更チェックフラグをリセット
              ln_change_flag := cn_no_change;
--
            ELSE
              -- 前回と変更がない場合は処理を終了する
              EXIT;
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP half_finish_goods_loop;
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
  END get_inject_prod_unit_price;
--
  /**********************************************************************************
   * Procedure Name   : ins_table_batch
   * Description      : 半製品データ登録処理(B-9)
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
    lt_user_id          xxcmn_txn_lot_cost.created_by%TYPE;             -- 作成者、最終更新者
    lt_login_id         xxcmn_txn_lot_cost.last_update_login%TYPE;      -- 最終更新ログイン
    lt_conc_request_id  xxcmn_txn_lot_cost.request_id%TYPE;             -- 要求ID
    lt_prog_appl_id     xxcmn_txn_lot_cost.program_application_id%TYPE; -- アプリケーションID
    lt_conc_program_id  xxcmn_txn_lot_cost.program_id%TYPE;             -- プログラムID
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
    -- WHOカラム取得
    lt_user_id          := FND_GLOBAL.USER_ID;          -- 作成者、最終更新者
    lt_login_id         := FND_GLOBAL.LOGIN_ID;         -- 最終更新ログイン
    lt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- 要求ID
    lt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- アプリケーションID
    lt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- プログラムID
--
    -- 一括登録
    FORALL ln_cnt IN 1..gt_doc_id_ins_tab.COUNT
      INSERT INTO xxcmn_txn_lot_cost(     -- 取引別ロット別原価(アドオン)
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
      )
      VALUES
      (
          gv_doc_type_prod                -- 文書タイプ
        , gt_doc_id_ins_tab(ln_cnt)       -- 文書ID
        , gt_item_id_ins_tab(ln_cnt)      -- 品目ID
        , gt_item_code_ins_tab(ln_cnt)    -- 品目コード
        , gt_lot_id_ins_tab(ln_cnt)       -- ロットID
        , gt_lot_num_ins_tab(ln_cnt)      -- ロットNo
        , gt_trans_qty_ins_tab(ln_cnt)    -- 取引数量
        , gt_unit_price_ins_tab(ln_cnt)   -- 単価
        , lt_user_id                      -- 作成者
        , SYSDATE                         -- 作成日
        , lt_user_id                      -- 最終更新者
        , SYSDATE                         -- 最終更新日
        , lt_login_id                     -- 最終更新ログイン
        , lt_conc_request_id              -- 要求ID
        , lt_prog_appl_id                 -- コンカレント・プログラム・アプリケーションID
        , lt_conc_program_id              -- コンカレント・プログラムID
        , SYSDATE                         -- プログラム更新日
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
    ir_xxcmn_txn_lot_cost IN  data_dump_rtype,  -- データダンプ用レコード
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
    ov_dump :=  TO_CHAR(ir_xxcmn_txn_lot_cost.batch_id)                             -- 文書ID
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.trans_date, 'YYYY/MM/DD HH24:MI:SS')  -- 取引日
                || gv_msg_comma ||  
                TO_CHAR(ir_xxcmn_txn_lot_cost.item_id)                              -- 品目ID
                || gv_msg_comma ||
                ir_xxcmn_txn_lot_cost.item_code                                     -- 品目コード
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.lot_id)                               -- ロットID
                || gv_msg_comma ||
                ir_xxcmn_txn_lot_cost.lot_num                                       -- ロットNO
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.trans_qty)                            -- 取引数量
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.unit_price)                           -- 単価
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
    ins_data_rec  data_dump_rtype; -- データダンプ用レコード
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
    FOR ln_rec_cnt IN 1..gt_doc_id_ins_tab.COUNT LOOP
--
      -- =============================
      -- ダンプ用レコードにセット
      -- =============================
      ins_data_rec.batch_id   := gt_doc_id_ins_tab(ln_rec_cnt);      -- 文書ID
      ins_data_rec.trans_date := gt_trans_date_ins_tab(ln_rec_cnt);  -- 取引日
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
    ov_errbuf   OUT NOCOPY  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY  VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- 半製品データ抽出
    CURSOR half_finished_goods_cur
    IS
      SELECT  itp.doc_id          doc_id                  -- 文書ID
            , itp.trans_date      trans_date              -- 取引日
            , ximv.item_id        item_id                 -- 品目ID
            , ximv.item_no        item_no                 -- 品目コード
            , ilm.lot_id          lot_id                  -- ロットID
            , ilm.lot_no          lot_no                  -- ロットNO
            , SUM(itp.trans_qty)  trans_qty               -- 取引数量
      FROM    ic_tran_pnd         itp                     -- 保留在庫トランザクション
            , xxcmn_item_mst_v    ximv                    -- OPM品目情報View
            , ic_lots_mst         ilm                     -- OPMロットマスタ
      WHERE itp.doc_type          =   gv_doc_type_prod    -- 文書タイプ：生産
      AND   itp.completed_ind     =   gn_completion       -- 完了区分：完了
      AND   itp.line_type         =   gn_l_type_finished  -- 明細タイプ：完成品
      AND   itp.trans_date        >=  gd_opening_date     -- 取引日
      AND   itp.reverse_id        IS NULL
      AND   itp.item_id           =   ximv.item_id        -- 品目ID
      AND   ximv.cost_manage_code =   gv_real_cost_price  -- 原価管理区分：0(実際原価)
      AND   itp.item_id           =   ilm.item_id         -- 品目ID
      AND   itp.lot_id            =   ilm.lot_id          -- ロットID
      GROUP BY
          itp.doc_id                                      -- 文書ID
        , itp.trans_date                                  -- 取引日
        , ximv.item_id                                    -- 品目ID
        , ximv.item_no                                    -- 品目コード
        , ilm.lot_id                                      -- ロットID
        , ilm.lot_no                                      -- ロットNO
    ;
--
  -- 副産物単価取得
  CURSOR by_product_price_cur(batch_id ic_tran_pnd.doc_id%TYPE) IS
    SELECT  ccd.cmpnt_cost        cmpnt_cost              -- コンポーネント原価
    FROM    ic_tran_pnd           itp                     -- 保留在庫トランザクション
          ,(SELECT cc.calendar_code          calendar_code
                  ,cc.item_id                item_id
                  ,NVL(SUM(cc.cmpnt_cost),0) cmpnt_cost
            FROM  cm_cmpt_dtl cc
            WHERE cc.whse_code =   gt_whse_code
            GROUP BY calendar_code,item_id ) ccd          -- 標準原価マスタ
          , cm_cldr_hdr_b         clh                     -- 原価カレンダヘッダ
          , cm_cldr_dtl           cll                     -- 原価カレンダ明細
    WHERE   itp.doc_type          =   gv_doc_type_prod    -- 文書タイプ：生産
    AND     itp.doc_id            =   batch_id            -- バッチID
    AND     itp.completed_ind     =   gn_completion       -- 完了区分：完了
    AND     itp.line_type         =   gn_l_type_product   -- 明細タイプ：副産物
    AND     itp.reverse_id        IS NULL
    AND     itp.item_id           =   ccd.item_id         -- 品目ID
    AND     ccd.calendar_code     =   clh.calendar_code   -- 原価カレンダーコード
    AND     clh.calendar_code     =   cll.calendar_code   -- 原価カレンダーコード
    AND     itp.trans_date        >=  cll.start_date      -- 期間（自）
    AND     itp.trans_date        <=  cll.end_date        -- 期間（至）
  ;
--
  -- 副産物取引数量取得
  CURSOR by_product_qty_cur(batch_id ic_tran_pnd.doc_id%TYPE) IS
    SELECT  itp.trans_qty         trans_qty
    FROM    ic_tran_pnd           itp                     -- 保留在庫トランザクション
          , xxcmn_item_mst_v      ximv                    -- OPM品目情報View
    WHERE   itp.doc_type          = gv_doc_type_prod      -- 文書タイプ：生産
    AND     itp.doc_id            = batch_id              -- バッチID
    AND     itp.completed_ind     = gn_completion         -- 完了区分：完了
    AND     itp.line_type         = gn_l_type_product     -- 明細タイプ：副産物
    AND     itp.reverse_id        IS NULL
    AND     itp.item_id           = ximv.item_id          -- 品目ID
  ;
--
    -- <カーソル名>レコード型
    half_finished_goods_cur_rec   half_finished_goods_cur%ROWTYPE;  -- 半製品データ
    by_product_price_cur_rec      by_product_price_cur%ROWTYPE;     -- 副産物単価
    by_product_qty_cur_rec        by_product_qty_cur%ROWTYPE;       -- 副産物取引数量
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
    gn_normal_cnt := 0;
--
    -- 登録用PL/SQL表初期化
    gt_trans_date_ins_tab.DELETE; -- 文書タイプ
    gt_doc_id_ins_tab.DELETE;     -- 文書ID
    gt_item_id_ins_tab.DELETE;    -- 品目ID
    gt_item_code_ins_tab.DELETE;  -- 品目コード
    gt_lot_id_ins_tab.DELETE;     -- ロットID
    gt_lot_num_ins_tab.DELETE;    -- ロットNo
    gt_trans_qty_ins_tab.DELETE;  -- 取引数量
    gt_unit_price_ins_tab.DELETE; -- 単価
--
    -- =======================================
    -- B-1.在庫オープン期間取得処理
    -- =======================================
    get_opening_period(
       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラーの場合は終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- データ存在確認
    OPEN half_finished_goods_cur;
    FETCH half_finished_goods_cur INTO half_finished_goods_cur_rec;
    IF (half_finished_goods_cur%NOTFOUND) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- モジュール名略称：XXCMN 共通
                   ,gv_msg_xxcmn10036   -- メッセージ：APP-XXCMN-10036 データ取得エラー
                   ),1,5000);
      RAISE global_process_expt;
    END IF;
    CLOSE half_finished_goods_cur;
--
    -- =======================================
    -- B-2.半製品データ抽出処理
    -- =======================================
    <<get_half_finish_loop>>
    FOR loop_cnt IN half_finished_goods_cur LOOP
--
      -- 変数初期化
      by_product_price_cur_rec.cmpnt_cost := NULL;  -- 副産物単価
      by_product_qty_cur_rec.trans_qty    := NULL;  -- 副産物取引数量
--
      -- データカウント
      gn_index_cnt :=  gn_index_cnt + 1;  -- データカウント
--
      --=================================
      -- B-3.副産物データ抽出処理
      --=================================
      -- 副産物単価取得
      OPEN by_product_price_cur(loop_cnt.doc_id);
      FETCH by_product_price_cur INTO by_product_price_cur_rec;
      CLOSE by_product_price_cur;
--
      -- 副産物取引数量取得
      OPEN by_product_qty_cur(loop_cnt.doc_id);
      FETCH by_product_qty_cur INTO by_product_qty_cur_rec;
      CLOSE by_product_qty_cur;
--
      --=================================
      -- B-4.半製品データ格納処理
      --=================================
      gt_half_finish_goods_tab(gn_index_cnt).batch_id   :=  loop_cnt.doc_id;      -- バッチID
      gt_half_finish_goods_tab(gn_index_cnt).trans_date :=  loop_cnt.trans_date;  -- 取引日
      gt_half_finish_goods_tab(gn_index_cnt).item_id    :=  loop_cnt.item_id;     -- 品目ID
      gt_half_finish_goods_tab(gn_index_cnt).item_no    :=  loop_cnt.item_no;     -- 品目コード
      gt_half_finish_goods_tab(gn_index_cnt).lot_id     :=  loop_cnt.lot_id;      -- ロットID
      gt_half_finish_goods_tab(gn_index_cnt).lot_no     :=  loop_cnt.lot_no;      -- ロットNO
      gt_half_finish_goods_tab(gn_index_cnt).trans_qty  :=  loop_cnt.trans_qty;   -- 取引数量
      -- 副産物単価
      IF (by_product_price_cur_rec.cmpnt_cost IS NOT NULL) THEN
        gt_half_finish_goods_tab(gn_index_cnt).by_prod_price := by_product_price_cur_rec.cmpnt_cost;
      ELSE
        -- データが取得できない場合は0をセット
        gt_half_finish_goods_tab(gn_index_cnt).by_prod_price := 0;
      END IF;
      -- 副産物取引数量
      IF (by_product_qty_cur_rec.trans_qty IS NOT NULL) THEN
        gt_half_finish_goods_tab(gn_index_cnt).by_prod_qty := by_product_qty_cur_rec.trans_qty;
      ELSE
        -- データが取得できない場合は0をセット
        gt_half_finish_goods_tab(gn_index_cnt).by_prod_qty := 0;
      END IF;
      gt_half_finish_goods_tab(gn_index_cnt).half_fin_price  := NULL;          -- 半製品単価
--
      --=================================
      -- B-5.投入品データ抽出処理
      --=================================
      get_row_materials(
          in_batch_id       =>  loop_cnt.doc_id   -- バッチID
        , ov_errbuf         =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode        =>  lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg         =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- エラーの場合は処理終了
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --=================================
      -- B-7.半製品単価確定処理
      --=================================
      set_decition_unit_price(
          in_index_cnt      =>  gn_index_cnt
        , ov_errbuf         =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode        =>  lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg         =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- エラーの場合は処理終了
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP get_half_finish_loop;
--
    --=================================
    -- B-8.投入品単価確定処理
    --=================================
    get_inject_prod_unit_price(
          ov_errbuf         =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode        =>  lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg         =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
    -- エラーの場合は処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --=================================
    -- B-9.半製品データ登録処理
    --=================================
    ins_table_batch(
          ov_errbuf         =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode        =>  lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg         =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
    -- エラーの場合は処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --=================================
    -- 成功データダンプ出力処理
    --=================================
    put_success_dump(
          ov_errbuf         =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode        =>  lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg         =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
    -- エラーの場合は処理終了
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
      IF (half_finished_goods_cur%ISOPEN) THEN
        CLOSE half_finished_goods_cur;
      END IF;
      IF (by_product_price_cur%ISOPEN) THEN
        CLOSE by_product_price_cur;
      END IF;
      IF (by_product_qty_cur%ISOPEN) THEN
        CLOSE by_product_qty_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (half_finished_goods_cur%ISOPEN) THEN
        CLOSE half_finished_goods_cur;
      END IF;
      IF (by_product_price_cur%ISOPEN) THEN
        CLOSE by_product_price_cur;
      END IF;
      IF (by_product_qty_cur%ISOPEN) THEN
        CLOSE by_product_qty_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (half_finished_goods_cur%ISOPEN) THEN
        CLOSE half_finished_goods_cur;
      END IF;
      IF (by_product_price_cur%ISOPEN) THEN
        CLOSE by_product_price_cur;
      END IF;
      IF (by_product_qty_cur%ISOPEN) THEN
        CLOSE by_product_qty_cur;
      END IF;
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
    errbuf    OUT NOCOPY  VARCHAR2,   --   エラー・メッセージ  --# 固定 #
    retcode   OUT NOCOPY  VARCHAR2    --   リターン・コード    --# 固定 #
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
END xxcmn790002c;
/
