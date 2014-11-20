CREATE OR REPLACE PACKAGE BODY xxcmn790003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn790003c(body)
 * Description      : 加重平均計算処理
 * MD.050           : ロット別実際原価計算 T_MD050_BPO_790
 * MD.070           : 加重平均計算処理 T_MD070_BPO_79C
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_table_data         ロット別原価テーブル削除処理(C-1)
 *  get_lot_cost           ロット別原価データ抽出処理(C-2)
 *                         ロット別原価データ編集処理(C-3)
 *  ins_table_batch        ロット別原価データ登録処理(C-4)
 *  get_data_dump          データダンプ取得処理
 *  put_success_dump       成功データダンプ出力処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/2/6      1.0   R.Matusita       新規作成
 *  2008/12/02    1.1   H.Marushita      数量ゼロの取引別ロット原価を抽出対象外とする。
 *  2008/12/05    1.2   H.Marushita      本番435対応
 *  2008/12/19    1.3   H.Marushita      在庫調整用に更新と登録を行うように修正
 *  2009/01/14    1.4   H.Marushita      ロットマスタの単価変更反映条件の見直し
 *  2013/01/08    1.5   M.Kitajima       ロット別原価アドオンの単価更新条件の見直し
 *                                       (E_本稼動_10355)
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
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxcmn790003c';  -- パッケージ名
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
-- 2008/12/19 ADD S
-- ロットマスタ単価反映用
  TYPE xlc_item_id_ttype    IS TABLE OF xxcmn_lot_cost.item_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 品目ID
  TYPE xlc_lot_id_ttype     IS TABLE OF xxcmn_lot_cost.lot_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ロットID
  TYPE xlc_trans_qty_ttype  IS TABLE OF xxcmn_lot_cost.trans_qty%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 取引数量
  TYPE xlc_unit_price_ttype IS TABLE OF xxcmn_lot_cost.unit_ploce%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- 単価
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
  TYPE unit_price_flag_ttype IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;    -- 更新フラグ
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--
-- 
-- ロットマスタ単価反映用PL/SQL表
  gt_xlc_item_id_tab    xlc_item_id_ttype;
  gt_xlc_lot_id_tab     xlc_lot_id_ttype;
  gt_xlc_trans_qty_tab  xlc_trans_qty_ttype;
  gt_xlc_unit_price_tab xlc_unit_price_ttype;
-- 2008/12/19 ADD E
--
  -- 登録用PL/SQL表
  gt_item_id_ins_tab    item_id_ttype;      -- 品目ID
  gt_item_code_ins_tab  item_code_ttype;    -- 品目コード
  gt_lot_id_ins_tab     lot_id_ttype;       -- ロットID
  gt_lot_num_ins_tab    lot_num_ttype;      -- ロットNo
  gt_trans_qty_ins_tab  trans_qty_ttype;    -- 取引数量
  gt_unit_price_ins_tab unit_price_ttype;   -- 単価
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
  gt_unit_price_ins_flag_tbl unit_price_flag_ttype; --単価更新フラグ
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--
  -- 更新用PL/SQL表
  gt_item_id_upd_tab    item_id_ttype;      -- 品目ID
  gt_lot_id_upd_tab     lot_id_ttype;       -- ロットID
  gt_trans_qty_upd_tab  trans_qty_ttype;    -- 取引数量
  gt_unit_price_upd_tab unit_price_ttype;   -- 単価
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
  gt_unit_price_upd_flag_tbl unit_price_flag_ttype; --単価更新フラグ
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--
  -- 入力データダンプ用PL/SQL表型
  TYPE msg_ttype      IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 在庫オープン期間
--2013/01/08 DEL AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
--  gv_opening_date     DATE;
--2013/01/08 DEL AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
  -- OPM在庫カレンダの直近締月
  gt_close_yyyymm     XXINV_STC_INVENTORY_MONTH_STCK.INVENT_YM%TYPE;
                                              -- 直近の締め済の年月
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
  gn_ins_cnt          NUMBER DEFAULT 0;       -- 登録件数
  gn_upd_cnt          NUMBER DEFAULT 0;       -- 更新件数
--
  /**********************************************************************************
   * Procedure Name   : del_table_data
   * Description      : ロット別原価テーブル削除処理(C-1)
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
      FROM    xxcmn_lot_cost xtlc   -- ロット別原価（アドオン）
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
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn          -- モジュール名略称：XXCMN マスタ・経理共通
                     ,gv_msg_xxcmn10146 -- メッセージ：ロック取得エラー
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- ロット別原価（アドオン）削除
    -- =====================================
    DELETE FROM xxcmn_lot_cost xtlc   -- ロット別原価（アドオン）
    WHERE NOT EXISTS
    (SELECT 'X'
     FROM ic_lots_mst ilm
     WHERE xtlc.item_id = ilm.item_id
     AND   xtlc.lot_id  = ilm.lot_id)  -- OPMロットマスタ
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
   * Procedure Name   : get_lot_cost
   * Description      : ロット別原価データ抽出処理(C-2)
   *                  : ロット別原価データ編集処理(C-3)
   ***********************************************************************************/
  PROCEDURE get_lot_cost(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lot_cost'; -- プログラム名
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
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
    cv_update_flag      CONSTANT VARCHAR2(1) := '*';  --ロットマスタの単価を使用した場合セットする
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--
    -- *** ローカル変数 ***
    ln_user_id          NUMBER;            -- ログインしているユーザー
    ln_login_id         NUMBER;            -- 最終更新ログイン
    ln_conc_request_id  NUMBER;            -- 要求ID
    ln_prog_appl_id     NUMBER;            -- コンカレント・プログラム・アプリケーションID
    ln_conc_program_id  NUMBER;            -- コンカレント・プログラムID
    ln_loop_cnt         NUMBER;            -- ループカーソル変数
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
    ln_data_cnt   NUMBER; -- 棚卸月末在庫テーブルの存在チェックに使用
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--
    -- *** ローカル・カーソル ***
--
    -- 表ロック取得
    CURSOR get_tab_lock_cur
    IS
      SELECT  xlc.lot_id
      FROM    xxcmn_lot_cost xlc   -- ロット別原価（アドオン）
      FOR UPDATE NOWAIT
      ;
--      
-- 2008/12/19 ADD S
    -- 更新用
    -- ロットマスタと金額差異があるロット別実際原価のデータを更新する
    CURSOR upd_lot_cost_date_cur
    IS
      SELECT  ilm.item_id               item_id
            , ilm.lot_id                lot_id
            , ilm.trans_cnt             trans_cnt
            , TO_NUMBER(ilm.attribute7) unit_price
      FROM 
            ic_lots_mst ilm
           ,ic_item_mst_b imb
           ,xxcmn_lot_cost xlc
      WHERE ilm.lot_id > 0  -- デフォルトロットを除く
        AND TO_NUMBER(NVL(ilm.attribute7,0)) <> 0 -- 実際原価が設定されているもの
        AND ilm.item_id = imb.item_id
        AND imb.attribute15 = '0' -- 実際原価
        AND imb.lot_ctl     = '1' -- ロット管理品
        AND ilm.item_id = xlc.item_id
        AND ilm.lot_id  = xlc.lot_id
        AND TO_NUMBER(NVL(ilm.attribute7,0)) <> NVL(xlc.UNIT_PLOCE,0)
      ;
-- 2008/12/19 ADD E
    -- 登録用
    -- ロット別原価（アドオン）テーブルに同一品目・同一ロットのデータが存在しないデータ
    CURSOR ins_lot_data_cur
    IS
      SELECT  xtlc.item_id               item_id         -- 品目ID
            , xtlc.item_code             item_code       -- 品目コード
            , xtlc.lot_id                lot_id          -- ロットID
            , xtlc.lot_num               lot_num         -- ロットNo
            , SUM(NVL(xtlc.trans_qty,0)) trans_qty       -- 取引数量
            , SUM(NVL(xtlc.unit_price,0)
                * NVL(xtlc.trans_qty,0)) price           -- 単価*数量（=取引金額）
      FROM    xxcmn_txn_lot_cost xtlc                    -- 取引別ロット別原価（アドオン）
      WHERE NOT EXISTS
      (SELECT 'X'
       FROM xxcmn_lot_cost xlc            -- ロット別原価（アドオン）
       WHERE xtlc.item_id   = xlc.item_id
       AND   xtlc.lot_id    = xlc.lot_id
      )
-- 2008/12/02 ADD START
      AND   xtlc.trans_qty > 0
-- 2008/12/02 ADD END
      GROUP BY xtlc.item_id, xtlc.item_code ,xtlc.lot_id ,xtlc.lot_num
      ;
--
    -- 更新用
    -- ロット別原価（アドオン）テーブルに同一品目・同一ロットのデータが存在するデータ
    CURSOR upd_lot_data_cur
    IS
      SELECT  xtlc.item_id               item_id   -- 品目ID
            , xtlc.lot_id                lot_id    -- ロットID
            , SUM(NVL(xtlc.trans_qty,0)) trans_qty -- 取引数量
            , SUM(NVL(xtlc.unit_price,0)
                * NVL(xtlc.trans_qty,0)) price     -- 単価*数量（=取引金額）
      FROM    xxcmn_txn_lot_cost xtlc              -- 取引別ロット別原価（アドオン）
            , xxcmn_lot_cost xlc                   -- ロット別原価（アドオン）
      WHERE xtlc.item_id   = xlc.item_id
      AND   xtlc.lot_id    = xlc.lot_id
-- 2008/12/02 ADD START
      AND   xtlc.trans_qty > 0
-- 2008/12/02 ADD END
      GROUP BY xtlc.item_id, xtlc.item_code ,xtlc.lot_id ,xtlc.lot_num
      ;
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
   /**********************************************************************************
   * ロット別原価データ編集処理(C-3)
   ***********************************************************************************/
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
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn          -- モジュール名略称：XXCMN マスタ・経理共通
                     ,gv_msg_xxcmn10146 -- メッセージ：ロック取得エラー
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- 共通更新情報の取得
    ln_user_id         := FND_GLOBAL.USER_ID;        -- ログインしているユーザーのID取得
    ln_login_id        := FND_GLOBAL.LOGIN_ID;       -- 最終更新ログイン
    ln_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID;-- 要求ID
    ln_prog_appl_id    := FND_GLOBAL.PROG_APPL_ID;   -- コンカレント・プログラム・アプリケーションID
    ln_conc_program_id := FND_GLOBAL.CONC_PROGRAM_ID;-- コンカレント・プログラムID
--
    -- ======================================
    -- 在庫調整等作成ロット実際原価反映
    -- ======================================
--2008/12/19 ADD S
    ln_loop_cnt := 0;
    <<upd_lot_cost_date_loop>>
    FOR loop_cnt IN upd_lot_cost_date_cur LOOP
--
      -- データカウント
      ln_loop_cnt :=  ln_loop_cnt + 1;
--
      -- 値セット
      gt_xlc_item_id_tab(ln_loop_cnt)     := loop_cnt.item_id;              -- 品目ID
      gt_xlc_lot_id_tab(ln_loop_cnt)      := loop_cnt.lot_id;               -- ロットID
      gt_xlc_trans_qty_tab(ln_loop_cnt)   := loop_cnt.trans_cnt;            -- 数量
      gt_xlc_unit_price_tab(ln_loop_cnt)  := loop_cnt.unit_price;           -- 単価
--
    END LOOP upd_lot_cost_date_loop;
--
    -- 一括更新処理
-- 2009/01/14 MOD S
--    FORALL ln_loop_cnt IN 1 .. gt_item_id_upd_tab.COUNT
--
    FORALL ln_loop_cnt IN 1 .. gt_xlc_item_id_tab.COUNT
--
-- 2009/01/14 MOD E
      -- ロット別実際原価マスタ更新
      UPDATE xxcmn_lot_cost
      SET trans_qty               = gt_xlc_trans_qty_tab(ln_loop_cnt) -- 取引数量
         ,unit_ploce              = gt_xlc_unit_price_tab(ln_loop_cnt)-- 単価 
         ,last_updated_by         = ln_user_id                   -- 最終更新者
         ,last_update_date        = SYSDATE                      -- 最終更新日
         ,last_update_login       = ln_login_id                  -- 最終更新ログイン
         ,request_id              = ln_conc_request_id           -- 要求ID
         ,program_application_id  = ln_prog_appl_id              -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
         ,program_id              = ln_conc_program_id           -- コンカレント・プログラムID
         ,program_update_date     = SYSDATE                      -- プログラム更新日
      WHERE item_id   = gt_xlc_item_id_tab(ln_loop_cnt)          -- 品目ID
      AND   lot_id    = gt_xlc_lot_id_tab(ln_loop_cnt);          -- ロットID
--2008/12/19 ADD E
--
        INSERT INTO xxcmn_lot_cost(
          item_id
        , item_code
        , lot_id
        , lot_num
        , trans_qty
        , unit_ploce
        , created_by
        , creation_date
        , last_updated_by
        , last_update_date
        , last_update_login
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        ) SELECT 
         iim.item_id
        ,iim.item_no
        ,ilm.lot_id
        ,ilm.lot_no
        ,ilm.trans_cnt
        ,to_number(ilm.attribute7) AS unit_price
        ,ln_user_id                             -- 作成者
        ,SYSDATE                                -- 作成日
        ,ln_user_id                             -- 最終更新者
        ,SYSDATE                                -- 最終更新日
        ,ln_login_id                            -- 最終更新ログイン
        ,ln_conc_request_id                     -- 要求ID
        ,ln_prog_appl_id                        -- コンカレント・プログラム・アプリケーションID
        ,ln_conc_program_id                     -- コンカレント・プログラムID
        ,SYSDATE                                -- プログラム更新日
        FROM 
         ic_lots_mst ilm
        ,ic_item_mst_b iim
        WHERE ilm.lot_id > 0  -- デフォルトロットを除く
        AND TO_NUMBER(NVL(ilm.attribute7,0)) <> 0 -- 実際原価が設定されているもの
        AND iim.item_id = ilm.item_id
        AND iim.attribute15 = '0'
        AND iim.lot_ctl     = '1'
        AND NOT EXISTS (
          SELECT 1 
          FROM  xxcmn_lot_cost xlc
          WHERE xlc.item_id = ilm.item_id
          AND   xlc.lot_id  = ilm.lot_id
        );
--
    -- ========================================
    -- 登録用取引別原価データをPL/SQL表にセット
    -- ========================================
    <<ins_data_loop>>
    FOR loop_cnt IN ins_lot_data_cur LOOP
--
      -- データカウント
      gn_ins_cnt :=  gn_ins_cnt + 1;
      -- 処理件数をカウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 値セット
      gt_item_id_ins_tab(gn_ins_cnt)     := loop_cnt.item_id;              -- 品目ID
      gt_item_code_ins_tab(gn_ins_cnt)   := loop_cnt.item_code;            -- 品目コード
      gt_lot_id_ins_tab(gn_ins_cnt)      := loop_cnt.lot_id;               -- ロットID
      gt_lot_num_ins_tab(gn_ins_cnt)     := loop_cnt.lot_num;              -- ロットNo
      gt_trans_qty_ins_tab(gn_ins_cnt)   := loop_cnt.trans_qty;            -- 数量
      IF ( loop_cnt.trans_qty = 0 ) THEN
        gt_unit_price_ins_tab(gn_ins_cnt) := 0;                            -- 取引金額
      ELSE
        gt_unit_price_ins_tab(gn_ins_cnt) := ROUND(loop_cnt.price
                                                 / loop_cnt.trans_qty, 2); -- 取引金額/数量
      END IF;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
      -- 更新フラグは必要ないがダンプ出力共通関数のINPUTパラメータとして使用する為、ダミーで入力
      gt_unit_price_ins_flag_tbl(gn_ins_cnt) := NULL;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--
    END LOOP ins_data_loop;
--
    -- ========================================
    -- 更新用取引別原価データをPL/SQL表にセット
    -- ========================================
    <<upd_data_loop>>
    FOR loop_cnt IN upd_lot_data_cur LOOP
      -- データカウント
      gn_upd_cnt :=  gn_upd_cnt + 1;
      -- 処理件数をカウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 値セット
      gt_item_id_upd_tab(gn_upd_cnt)     := loop_cnt.item_id;              -- 品目ID
      gt_lot_id_upd_tab(gn_upd_cnt)      := loop_cnt.lot_id;               -- ロットID
      gt_trans_qty_upd_tab(gn_upd_cnt)   := loop_cnt.trans_qty;            -- 数量
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
      gt_unit_price_upd_flag_tbl(gn_upd_cnt) := NULL;                      -- 単価更新フラグ
      -- 棚卸月末在庫テーブルを参照し当月発生分のロットかの判断を実施
      SELECT /*+ INDEX(xsims XXINV_SIMS_N04) */
        COUNT(1) AS COUNT
      INTO   ln_data_cnt
      FROM   xxinv_stc_inventory_month_stck xsims
      WHERE  xsims.item_id          = loop_cnt.item_id
      AND    xsims.lot_id           = loop_cnt.lot_id
      AND    xsims.invent_ym       <= gt_close_yyyymm
      AND    ROWNUM               = 1;
      IF ( ln_data_cnt = 0 ) THEN
        -- 棚卸月末在庫テーブルの直近締め月以下に未存在の場合は当月にロットが発生
        IF ( loop_cnt.trans_qty = 0 ) THEN
          gt_unit_price_upd_tab(gn_upd_cnt) := 0;                            -- 取引金額
        ELSE
          gt_unit_price_upd_tab(gn_upd_cnt) := ROUND(loop_cnt.price
                                                   / loop_cnt.trans_qty, 2); -- 取引金額/数量
        END IF;
      ELSE
        -- 棚卸月末在庫テーブルの直近締め月以下に存在する場合は単価変更なし
        IF ( loop_cnt.trans_qty = 0 ) THEN
          gt_unit_price_upd_tab(gn_upd_cnt) := 0;                            -- 取引金額
        ELSE
          SELECT /*+ INDEX(ilm IC_LOTS_MST_PK) */
            TO_NUMBER(NVL(ilm.attribute7,'0')) AS unit_price
          INTO   gt_unit_price_upd_tab(gn_upd_cnt)                           -- ロットマスタの単価設定
          FROM   ic_lots_mst ilm
          WHERE  ilm.item_id = loop_cnt.item_id
          AND    ilm.lot_id  = loop_cnt.lot_id;
          --単価更新はロットマスタの単価を取得する為、更新しない
          gt_unit_price_upd_flag_tbl(gn_upd_cnt) := cv_update_flag;          -- 更新
        END IF;
      END IF;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--2013/01/08 DEL AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
--      IF ( loop_cnt.trans_qty = 0 ) THEN
--        gt_unit_price_upd_tab(gn_upd_cnt) := 0;                            -- 取引金額
--      ELSE
--        gt_unit_price_upd_tab(gn_upd_cnt) := ROUND(loop_cnt.price
--                                                 / loop_cnt.trans_qty, 2); -- 取引金額/数量
--      END IF;
--2013/01/08 DEL AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--
    END LOOP upd_data_loop;
--
    IF ( gn_ins_cnt + gn_upd_cnt > 0 ) THEN
      -- データカウントを成功データカウントにセット
      gn_normal_cnt := gn_ins_cnt + gn_upd_cnt;
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
  END get_lot_cost;
--
  /**********************************************************************************
   * Procedure Name   : ins_table_batch
   * Description      : ロット別原価データ登録処理(C-4)
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
    ln_user_id          NUMBER;            -- ログインしているユーザー
    ln_login_id         NUMBER;            -- 最終更新ログイン
    ln_conc_request_id  NUMBER;            -- 要求ID
    ln_prog_appl_id     NUMBER;            -- コンカレント・プログラム・アプリケーションID
    ln_conc_program_id  NUMBER;            -- コンカレント・プログラムID
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
    -- 共通更新情報の取得
    ln_user_id         := FND_GLOBAL.USER_ID;        -- ログインしているユーザーのID取得
    ln_login_id        := FND_GLOBAL.LOGIN_ID;       -- 最終更新ログイン
    ln_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID;-- 要求ID
    ln_prog_appl_id    := FND_GLOBAL.PROG_APPL_ID;   -- コンカレント・プログラム・アプリケーションID
    ln_conc_program_id := FND_GLOBAL.CONC_PROGRAM_ID;-- コンカレント・プログラムID
--
    -- =====================================
    -- 一括登録処理
    -- =====================================
    FORALL ln_cnt IN 1..gt_item_id_ins_tab.COUNT
      INSERT INTO xxcmn_lot_cost(
          item_id
        , item_code
        , lot_id
        , lot_num
        , trans_qty
        , unit_ploce
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
          gt_item_id_ins_tab(ln_cnt)            -- 品目ID
        , gt_item_code_ins_tab(ln_cnt)          -- 品目コード
        , gt_lot_id_ins_tab(ln_cnt)             -- ロットID
        , gt_lot_num_ins_tab(ln_cnt)            -- ロットNo
        , gt_trans_qty_ins_tab(ln_cnt)          -- 取引数量
        , gt_unit_price_ins_tab(ln_cnt)         -- 単価
        ,ln_user_id                             -- 作成者
        ,SYSDATE                                -- 作成日
        ,ln_user_id                             -- 最終更新者
        ,SYSDATE                                -- 最終更新日
        ,ln_login_id                            -- 最終更新ログイン
        ,ln_conc_request_id                     -- 要求ID
        ,ln_prog_appl_id                        -- コンカレント・プログラム・アプリケーションID
        ,ln_conc_program_id                     -- コンカレント・プログラムID
        ,SYSDATE);                              -- プログラム更新日
--
    -- =====================================
    -- 一括更新処理
    -- =====================================
      FORALL ln_cnt IN 1 .. gt_item_id_upd_tab.COUNT
        -- 品目マスタ更新(予約フラグOFF)
        UPDATE xxcmn_lot_cost
        SET trans_qty               = gt_trans_qty_upd_tab(ln_cnt) -- 取引数量
           ,unit_ploce              = gt_unit_price_upd_tab(ln_cnt)-- 単価 
           ,last_updated_by         = ln_user_id                   -- 最終更新者
           ,last_update_date        = SYSDATE                      -- 最終更新日
           ,last_update_login       = ln_login_id                  -- 最終更新ログイン
           ,request_id              = ln_conc_request_id           -- 要求ID
           ,program_application_id  = ln_prog_appl_id              -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
           ,program_id              = ln_conc_program_id           -- コンカレント・プログラムID
           ,program_update_date     = SYSDATE                      -- プログラム更新日
        WHERE item_id   = gt_item_id_upd_tab(ln_cnt)               -- 品目ID
        AND   lot_id    = gt_lot_id_upd_tab(ln_cnt);               -- ロットID
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
    ir_xxcmn_lot_cost     IN  xxcmn_lot_cost%ROWTYPE,  
                                                -- 取引別ロット別原価（アドオン）
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
    iv_unit_price_flag    IN  VARCHAR2,         -- 更新フラグ
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
    ov_dump               OUT NOCOPY VARCHAR2,  -- データダンプ文字列
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2,  -- ユーザー・エラー・メッセージ --# 固定 #
    in_ins_upd_flg        IN  NUMBER)           -- 登録更新フラグ(登録：0・更新：1)
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
--
    IF ( in_ins_upd_flg =0 ) THEN
      -- 登録分
      ov_dump :=  TO_CHAR(ir_xxcmn_lot_cost.item_id)    -- 品目ID
                  || gv_msg_comma ||
                  ir_xxcmn_lot_cost.item_code           -- 品目コード
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.lot_id)     -- ロットID
                  || gv_msg_comma ||
                  ir_xxcmn_lot_cost.lot_num             -- ロットNO
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.trans_qty)  -- 取引数量
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.unit_ploce) -- 単価
                  ;
     ELSE
      -- 更新分
      ov_dump :=  TO_CHAR(ir_xxcmn_lot_cost.item_id)    -- 品目ID
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.lot_id)     -- ロットID
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.trans_qty)  -- 取引数量
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.unit_ploce) -- 単価
                  ;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
      -- 更新フラグがNOT NULLの場合
      IF ( iv_unit_price_flag IS NOT NULL ) THEN
       ov_dump := ov_dump || gv_msg_comma ||
                             iv_unit_price_flag;
      END IF;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
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
    in_ins_upd_flg NUMBER;   -- 登録更新フラグ(登録：0・更新：1)
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    ins_data_rec  xxcmn_lot_cost%ROWTYPE; -- ロット別原価（アドオン）型レコード
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
    -- 登録データ  
    << success_dump_ins_set_loop >>
    FOR ln_rec_cnt IN 1..gt_item_id_ins_tab.COUNT LOOP
--
      -- =============================
      -- ダンプ用レコードにセット
      -- =============================
      ins_data_rec.item_id    := gt_item_id_ins_tab(ln_rec_cnt);     -- 品目ID
      ins_data_rec.item_code  := gt_item_code_ins_tab(ln_rec_cnt);   -- 品目コード
      ins_data_rec.lot_id     := gt_lot_id_ins_tab(ln_rec_cnt);      -- ロットID
      ins_data_rec.lot_num    := gt_lot_num_ins_tab(ln_rec_cnt);     -- ロットNo
      ins_data_rec.trans_qty  := gt_trans_qty_ins_tab(ln_rec_cnt);   -- 数量
      ins_data_rec.unit_ploce := gt_unit_price_ins_tab(ln_rec_cnt);  -- 単価
--
      -- =============================
      -- データダンプ取得処理
      -- =============================
      get_data_dump(
          ir_xxcmn_lot_cost => ins_data_rec
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
        , iv_unit_price_flag    => gt_unit_price_ins_flag_tbl(ln_rec_cnt) -- 更新フラグ
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
        , ov_dump               => lv_dump
        , ov_errbuf             => lv_errbuf
        , ov_retcode            => lv_retcode
        , ov_errmsg             => lv_errmsg
        , in_ins_upd_flg        => 0
      );
      -- データダンプ取得処理がエラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- 成功データを出力
      -- =============================
      IF ( ln_rec_cnt = 1) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'（登録データ）');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dump);
--
    END LOOP success_dump_ins_set_loop;
--
    -- 更新データ
    << success_dump_upd_set_loop >>
    FOR ln_rec_cnt IN 1..gt_item_id_upd_tab.COUNT LOOP
--
      -- =============================
      -- ダンプ用レコードにセット
      -- =============================
      ins_data_rec.item_id    := gt_item_id_upd_tab(ln_rec_cnt);     -- 品目ID
      ins_data_rec.lot_id     := gt_lot_id_upd_tab(ln_rec_cnt);      -- ロットID
      ins_data_rec.trans_qty  := gt_trans_qty_upd_tab(ln_rec_cnt);   -- 数量
      ins_data_rec.unit_ploce := gt_unit_price_upd_tab(ln_rec_cnt);  -- 単価
--
      -- =============================
      -- データダンプ取得処理
      -- =============================
      get_data_dump(
          ir_xxcmn_lot_cost => ins_data_rec
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
        , iv_unit_price_flag    => gt_unit_price_upd_flag_tbl(ln_rec_cnt) -- 更新フラグ
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
        , ov_dump               => lv_dump
        , ov_errbuf             => lv_errbuf
        , ov_retcode            => lv_retcode
        , ov_errmsg             => lv_errmsg
        , in_ins_upd_flg        => 1
      );
      -- データダンプ取得処理がエラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- 成功データを出力
      -- =============================
      IF ( ln_rec_cnt = 1) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'（更新データ）');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dump);
--
    END LOOP success_dump_upd_set_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    gt_item_id_ins_tab.DELETE;    -- 品目ID
    gt_item_code_ins_tab.DELETE;  -- 品目コード
    gt_lot_id_ins_tab.DELETE;     -- ロットID
    gt_lot_num_ins_tab.DELETE;    -- ロットNo
    gt_trans_qty_ins_tab.DELETE;  -- 取引数量
    gt_unit_price_ins_tab.DELETE; -- 単価
--
    -- 更新用PL/SQL表初期化
    gt_item_id_upd_tab.DELETE;    -- 品目ID
    gt_lot_id_upd_tab.DELETE;     -- ロットID
    gt_trans_qty_upd_tab.DELETE;  -- 取引数量
    gt_unit_price_upd_tab.DELETE; -- 単価
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
    gt_unit_price_ins_flag_tbl.DELETE; -- 単価更新フラグ(INSERT)
    gt_unit_price_upd_flag_tbl.DELETE; -- 単価更新フラグ(UPDATE)
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 START
    -- =======================================
    -- OPM在庫カレンダの直近締月取得
    -- =======================================
    gt_close_yyyymm := xxcmn_common_pkg.get_opminv_close_period;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.5 CONTENT:E_本稼動_10355 END
--
    -- =======================================
    -- C-1.ロット別原価テーブル削除処理
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
    -- C-2.ロット別原価データ抽出処理(C-3.ロット別原価データ編集処理)
    -- =======================================
    get_lot_cost(
       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- C-4.ロット別原価データ登録処理
    -- =======================================
    ins_table_batch(
       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- ロット別原価データ登録処理がエラーの場合
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
    errbuf        OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT NOCOPY VARCHAR2       --   リターン・コード    --# 固定 #
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
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
END xxcmn790003c;
/
