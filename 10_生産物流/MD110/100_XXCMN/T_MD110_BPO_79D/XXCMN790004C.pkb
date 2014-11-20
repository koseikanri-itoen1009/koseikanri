CREATE OR REPLACE PACKAGE BODY xxcmn790004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn790004c(body)
 * Description      : 実際原価洗替処理
 * MD.050           : ロット別実際原価計算 T_MD050_BPO_790
 * MD.070           : 実際原価洗替処理 T_MD070_BPO_79D
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_lot_cost           ロット別原価データ抽出処理(D-1)
 *  upd_table_api          OPMロットマスタ更新処理(D-2)
 *  get_data_dump          データダンプ取得処理
 *  put_success_dump       成功データダンプ出力処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/2/20     1.0   R.Matusita       新規作成
 *  2008/04/25    1.1   Marushita        TE080_BPO_790 不具合ID 2,3
 *  2008/06/03    1.2   Marushita        TE080_BPO_790 不具合ID 4
 *  2008/09/11    1.3   A.Shiina         処理対象レコードが0件の場合、正常終了とする。
 *  2013/01/08    1.4   M.Kitajima       ロットマスタの単価更新条件の見直し
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
-- 2008/09/11 ADD START
  no_data_expt              EXCEPTION;     -- 取得データ0件時例外
-- 2008/09/11 ADD END
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxcmn790004c'; -- パッケージ名
--
  gv_xxcmn          CONSTANT VARCHAR2(100)  := 'XXCMN';        -- モジュール名省略：XXCMNマスタ共通
--
  -- メッセージ
  gv_msg_xxcmn10146 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10146';  
                                            -- メッセージ：ロック取得エラー
  gv_msg_xxcmn10036 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10036';
                                            -- メッセージ：データ取得エラー
  gv_msg_xxcmn00005 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-00005';  
                                            -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
  gv_update_flag    CONSTANT VARCHAR2(1) := '*';  --ロットマスタの単価を使用した場合セットする
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 更新用PL/SQL表型
  TYPE item_id_ttype    IS TABLE OF xxcmn_lot_cost.item_id%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- 品目ID
  TYPE item_code_ttype  IS TABLE OF xxcmn_lot_cost.item_code%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- 品目コード
  TYPE lot_id_ttype     IS TABLE OF xxcmn_lot_cost.lot_id%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ロットID
  TYPE lot_num_ttype    IS TABLE OF xxcmn_lot_cost.lot_num%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ロットNo
  TYPE trans_qty_ttype  IS TABLE OF xxcmn_lot_cost.trans_qty%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- 取引数量
  TYPE  attribute1_ttype IS TABLE OF ic_lots_mst.attribute1%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１
  TYPE  attribute2_ttype IS TABLE OF ic_lots_mst.attribute2%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２
  TYPE  attribute3_ttype IS TABLE OF ic_lots_mst.attribute3%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目３
  TYPE  attribute4_ttype IS TABLE OF ic_lots_mst.attribute4%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目４
  TYPE  attribute5_ttype IS TABLE OF ic_lots_mst.attribute5%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目５
  TYPE  attribute6_ttype IS TABLE OF ic_lots_mst.attribute6%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目６
  TYPE unit_price_ttype IS TABLE OF xxcmn_lot_cost.unit_ploce%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- 単価
  TYPE  attribute8_ttype IS TABLE OF ic_lots_mst.attribute8%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目８
  TYPE  attribute9_ttype IS TABLE OF ic_lots_mst.attribute9%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目９
  TYPE attribute10_ttype IS TABLE OF ic_lots_mst.attribute10%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１０
  TYPE attribute11_ttype IS TABLE OF ic_lots_mst.attribute11%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１１
  TYPE attribute12_ttype IS TABLE OF ic_lots_mst.attribute12%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１２
  TYPE attribute13_ttype IS TABLE OF ic_lots_mst.attribute13%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１３
  TYPE attribute14_ttype IS TABLE OF ic_lots_mst.attribute14%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１４
  TYPE attribute15_ttype IS TABLE OF ic_lots_mst.attribute15%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１５
  TYPE attribute16_ttype IS TABLE OF ic_lots_mst.attribute16%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１６
  TYPE attribute17_ttype IS TABLE OF ic_lots_mst.attribute17%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１７
  TYPE attribute18_ttype IS TABLE OF ic_lots_mst.attribute18%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１８
  TYPE attribute19_ttype IS TABLE OF ic_lots_mst.attribute19%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目１９
  TYPE attribute20_ttype IS TABLE OF ic_lots_mst.attribute20%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２０
  TYPE attribute21_ttype IS TABLE OF ic_lots_mst.attribute21%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２１
  TYPE attribute22_ttype IS TABLE OF ic_lots_mst.attribute22%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２２
  TYPE attribute23_ttype IS TABLE OF ic_lots_mst.attribute23%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２３
  TYPE attribute24_ttype IS TABLE OF ic_lots_mst.attribute24%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２４
  TYPE attribute25_ttype IS TABLE OF ic_lots_mst.attribute25%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２５
  TYPE attribute26_ttype IS TABLE OF ic_lots_mst.attribute26%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２６
  TYPE attribute27_ttype IS TABLE OF ic_lots_mst.attribute27%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２７
  TYPE attribute28_ttype IS TABLE OF ic_lots_mst.attribute28%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２８
  TYPE attribute29_ttype IS TABLE OF ic_lots_mst.attribute29%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目２９
  TYPE attribute30_ttype IS TABLE OF ic_lots_mst.attribute30%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ＤＦＦ項目３０
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
  --  更新フラグ
  TYPE unit_price_flag_ttype IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
--
  -- 更新用PL/SQL表
  gt_item_id_upd_tab     item_id_ttype;      -- 品目ID
  gt_item_code_upd_tab   item_code_ttype;    -- 品目コード
  gt_lot_id_upd_tab      lot_id_ttype;       -- ロットID
  gt_lot_num_upd_tab     lot_num_ttype;      -- ロットNo
  gt_trans_qty_upd_tab   trans_qty_ttype;    -- 取引数量
  gt_attribute1_upd_tab  attribute1_ttype;   -- ＤＦＦ項目１
  gt_attribute2_upd_tab  attribute2_ttype;   -- ＤＦＦ項目２
  gt_attribute3_upd_tab  attribute3_ttype;   -- ＤＦＦ項目３
  gt_attribute4_upd_tab  attribute4_ttype;   -- ＤＦＦ項目４
  gt_attribute5_upd_tab  attribute5_ttype;   -- ＤＦＦ項目５
  gt_attribute6_upd_tab  attribute6_ttype;   -- ＤＦＦ項目６
  gt_unit_price_upd_tab  unit_price_ttype;   -- 単価
  gt_attribute8_upd_tab  attribute8_ttype;   -- ＤＦＦ項目８
  gt_attribute9_upd_tab  attribute9_ttype;   -- ＤＦＦ項目９
  gt_attribute10_upd_tab attribute10_ttype;  -- ＤＦＦ項目１０
  gt_attribute11_upd_tab attribute11_ttype;  -- ＤＦＦ項目１１
  gt_attribute12_upd_tab attribute12_ttype;  -- ＤＦＦ項目１２
  gt_attribute13_upd_tab attribute13_ttype;  -- ＤＦＦ項目１３
  gt_attribute14_upd_tab attribute14_ttype;  -- ＤＦＦ項目１４
  gt_attribute15_upd_tab attribute15_ttype;  -- ＤＦＦ項目１５
  gt_attribute16_upd_tab attribute16_ttype;  -- ＤＦＦ項目１６
  gt_attribute17_upd_tab attribute17_ttype;  -- ＤＦＦ項目１７
  gt_attribute18_upd_tab attribute18_ttype;  -- ＤＦＦ項目１８
  gt_attribute19_upd_tab attribute19_ttype;  -- ＤＦＦ項目１９
  gt_attribute20_upd_tab attribute20_ttype;  -- ＤＦＦ項目２０
  gt_attribute21_upd_tab attribute21_ttype;  -- ＤＦＦ項目２１
  gt_attribute22_upd_tab attribute22_ttype;  -- ＤＦＦ項目２２
  gt_attribute23_upd_tab attribute23_ttype;  -- ＤＦＦ項目２３
  gt_attribute24_upd_tab attribute24_ttype;  -- ＤＦＦ項目２４
  gt_attribute25_upd_tab attribute25_ttype;  -- ＤＦＦ項目２５
  gt_attribute26_upd_tab attribute26_ttype;  -- ＤＦＦ項目２６
  gt_attribute27_upd_tab attribute27_ttype;  -- ＤＦＦ項目２７
  gt_attribute28_upd_tab attribute28_ttype;  -- ＤＦＦ項目２８
  gt_attribute29_upd_tab attribute29_ttype;  -- ＤＦＦ項目２９
  gt_attribute30_upd_tab attribute30_ttype;  -- ＤＦＦ項目３０
--
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
  gt_unit_price_upd_flag_tbl unit_price_flag_ttype; --単価更新フラグ
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
--
  -- ロット別原価データを格納するレコード
  TYPE lot_data_rec IS RECORD(
    item_id     xxcmn_lot_cost.item_id%TYPE,        -- 品目ID
    item_code   xxcmn_lot_cost.item_code%TYPE,      -- 品目コード
    lot_id      xxcmn_lot_cost.lot_id%TYPE,         -- ロットID
    lot_num     xxcmn_lot_cost.lot_num%TYPE,        -- ロットNo
    trans_qty   xxcmn_lot_cost.trans_qty%TYPE,      -- 取引数量
    attribute1  ic_lots_mst.attribute1%TYPE,        -- ＤＦＦ項目１
    attribute2  ic_lots_mst.attribute2%TYPE,        -- ＤＦＦ項目２
    attribute3  ic_lots_mst.attribute3%TYPE,        -- ＤＦＦ項目３
    attribute4  ic_lots_mst.attribute4%TYPE,        -- ＤＦＦ項目４
    attribute5  ic_lots_mst.attribute5%TYPE,        -- ＤＦＦ項目５
    attribute6  ic_lots_mst.attribute6%TYPE,        -- ＤＦＦ項目６
    unit_price  xxcmn_lot_cost.unit_ploce%TYPE,     -- 単価
    attribute8  ic_lots_mst.attribute8%TYPE,        -- ＤＦＦ項目８
    attribute9  ic_lots_mst.attribute9%TYPE,        -- ＤＦＦ項目９
    attribute10 ic_lots_mst.attribute10%TYPE,       -- ＤＦＦ項目１０
    attribute11 ic_lots_mst.attribute11%TYPE,       -- ＤＦＦ項目１１
    attribute12 ic_lots_mst.attribute12%TYPE,       -- ＤＦＦ項目１２
    attribute13 ic_lots_mst.attribute13%TYPE,       -- ＤＦＦ項目１３
    attribute14 ic_lots_mst.attribute14%TYPE,       -- ＤＦＦ項目１４
    attribute15 ic_lots_mst.attribute15%TYPE,       -- ＤＦＦ項目１５
    attribute16 ic_lots_mst.attribute16%TYPE,       -- ＤＦＦ項目１６
    attribute17 ic_lots_mst.attribute17%TYPE,       -- ＤＦＦ項目１７
    attribute18 ic_lots_mst.attribute18%TYPE,       -- ＤＦＦ項目１８
    attribute19 ic_lots_mst.attribute19%TYPE,       -- ＤＦＦ項目１９
    attribute20 ic_lots_mst.attribute20%TYPE,       -- ＤＦＦ項目２０
    attribute21 ic_lots_mst.attribute21%TYPE,       -- ＤＦＦ項目２１
    attribute22 ic_lots_mst.attribute22%TYPE,       -- ＤＦＦ項目２２
    attribute23 ic_lots_mst.attribute23%TYPE,       -- ＤＦＦ項目２３
    attribute24 ic_lots_mst.attribute24%TYPE,       -- ＤＦＦ項目２４
    attribute25 ic_lots_mst.attribute25%TYPE,       -- ＤＦＦ項目２５
    attribute26 ic_lots_mst.attribute26%TYPE,       -- ＤＦＦ項目２６
    attribute27 ic_lots_mst.attribute27%TYPE,       -- ＤＦＦ項目２７
    attribute28 ic_lots_mst.attribute28%TYPE,       -- ＤＦＦ項目２８
    attribute29 ic_lots_mst.attribute29%TYPE,       -- ＤＦＦ項目２９
    attribute30 ic_lots_mst.attribute30%TYPE        -- ＤＦＦ項目３０
  );
--
  -- 入力データダンプ用PL/SQL表型
  TYPE msg_ttype      IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_upd_cnt          NUMBER DEFAULT 0;      -- 更新件数
--
  gv_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCMN';
  --メッセージ番号
  gv_msg_80a_016      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018';  --APIエラー(コンカレント)
  --トークン
  gv_tkn_api_name     CONSTANT VARCHAR2(15) := 'API_NAME';
--
  TYPE lot_data_tbl IS TABLE OF lot_data_rec INDEX BY PLS_INTEGER;
--
  gt_lot_data_tbl     lot_data_tbl;           -- 結合配列の定義
--
  gd_date     DATE;           -- SYSDATE格納
  gn_user_id  NUMBER(15,0);   -- USER_ID格納
-- 2008/09/11 ADD START
  gn_no_data  NUMBER;         -- 取得データ0件時用変数
-- 2008/09/11 ADD END
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
  -- OPM在庫カレンダの直近締月
  gt_close_yyyymm     XXINV_STC_INVENTORY_MONTH_STCK.INVENT_YM%TYPE;
                                              -- 直近の締め済の年月
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
--
  /**********************************************************************************
   * Procedure Name   : get_lot_cost
   * Description      : ロット別原価データ抽出処理(D-1)
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
--
    -- *** ローカル変数 ***
--
    ln_cnt   NUMBER DEFAULT 0;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
    ln_data_cnt   NUMBER; -- 棚卸月末在庫テーブルの存在チェックに使用
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
-- 2008/09/11 ADD START
-- 取得データ0件時用変数の初期化
   gn_no_data := 0;
--
-- 2008/09/11 ADD END
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
   /**********************************************************************************
   * データ編集処理
   ***********************************************************************************/
--
    BEGIN
    -- ロット別原価（アドオン）テーブルに同一品目・同一ロット、
    -- 単価違いのデータが存在するデータ
      SELECT  xlc.item_id               item_id         -- ロット別原価（アドオン）品目ID
            , xlc.item_code             item_code       -- ロット別原価（アドオン）品目コード
            , xlc.lot_id                lot_id          -- ロット別原価（アドオン）ロットID
            , xlc.lot_num               lot_num         -- ロット別原価（アドオン）ロットNo
            , NVL(xlc.trans_qty,0)      trans_qty       -- ロット別原価（アドオン）取引数量
            , ilm.attribute1            attribute1      -- OPMロットマスタ ＤＦＦ項目１
            , ilm.attribute2            attribute2      -- OPMロットマスタ ＤＦＦ項目２
            , ilm.attribute3            attribute3      -- OPMロットマスタ ＤＦＦ項目３
            , ilm.attribute4            attribute4      -- OPMロットマスタ ＤＦＦ項目４
            , ilm.attribute5            attribute5      -- OPMロットマスタ ＤＦＦ項目５
            , ilm.attribute6            attribute6      -- OPMロットマスタ ＤＦＦ項目６
            , NVL(xlc.unit_ploce,0)     price           -- ロット別原価（アドオン）単価
            , ilm.attribute8            attribute8      -- OPMロットマスタ ＤＦＦ項目８
            , ilm.attribute9            attribute9      -- OPMロットマスタ ＤＦＦ項目９
            , ilm.attribute10           attribute10     -- OPMロットマスタ ＤＦＦ項目１０
            , ilm.attribute11           attribute11     -- OPMロットマスタ ＤＦＦ項目１１
            , ilm.attribute12           attribute12     -- OPMロットマスタ ＤＦＦ項目１２
            , ilm.attribute13           attribute13     -- OPMロットマスタ ＤＦＦ項目１３
            , ilm.attribute14           attribute14     -- OPMロットマスタ ＤＦＦ項目１４
            , ilm.attribute15           attribute15     -- OPMロットマスタ ＤＦＦ項目１５
            , ilm.attribute16           attribute16     -- OPMロットマスタ ＤＦＦ項目１６
            , ilm.attribute17           attribute17     -- OPMロットマスタ ＤＦＦ項目１７
            , ilm.attribute18           attribute18     -- OPMロットマスタ ＤＦＦ項目１８
            , ilm.attribute19           attribute19     -- OPMロットマスタ ＤＦＦ項目１９
            , ilm.attribute20           attribute20     -- OPMロットマスタ ＤＦＦ項目２０
            , ilm.attribute21           attribute21     -- OPMロットマスタ ＤＦＦ項目２１
            , ilm.attribute22           attribute22     -- OPMロットマスタ ＤＦＦ項目２２
            , ilm.attribute23           attribute23     -- OPMロットマスタ ＤＦＦ項目２３
            , ilm.attribute24           attribute24     -- OPMロットマスタ ＤＦＦ項目２４
            , ilm.attribute25           attribute25     -- OPMロットマスタ ＤＦＦ項目２５
            , ilm.attribute26           attribute26     -- OPMロットマスタ ＤＦＦ項目２６
            , ilm.attribute27           attribute27     -- OPMロットマスタ ＤＦＦ項目２７
            , ilm.attribute28           attribute28     -- OPMロットマスタ ＤＦＦ項目２８
            , ilm.attribute29           attribute29     -- OPMロットマスタ ＤＦＦ項目２９
            , ilm.attribute30           attribute30     -- OPMロットマスタ ＤＦＦ項目３０
      BULK COLLECT INTO gt_lot_data_tbl
      FROM    xxcmn_lot_cost xlc                        -- ロット別原価（アドオン）
            , ic_lots_mst    ilm                        -- OPMロットマスタ
      WHERE xlc.item_id    =  ilm.item_id
      AND   xlc.lot_id     =  ilm.lot_id
      AND   ilm.lot_id     >  0 -- デフォルトロットを対象外とする
      AND   xlc.unit_ploce <> TO_NUMBER(NVL(ilm.attribute7,'0'))
      FOR UPDATE OF ilm.item_id
                  , ilm.lot_id
      NOWAIT
      ;
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
    -- ========================================
    -- 更新用データをPL/SQL表にセット
    -- ========================================
    <<upd_data_loop>>
    FOR ln_cnt IN 1 .. NVL(gt_lot_data_tbl.LAST,0) LOOP
--2013/01/08 DEL AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
--        -- データカウント
--      gn_upd_cnt :=  gn_upd_cnt + 1;
--2013/01/08 DEL AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
        -- 処理件数をカウント
      gn_target_cnt := gn_target_cnt + 1;
--
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
        -- 棚卸月末在庫テーブルを参照し当月発生分のロットかの判断を実施
      SELECT /*+ INDEX(xsims XXINV_SIMS_N04) */
        COUNT(1) AS COUNT
      INTO   ln_data_cnt
      FROM   xxinv_stc_inventory_month_stck xsims
      WHERE  xsims.item_id          = gt_lot_data_tbl(ln_cnt).item_id
      AND    xsims.lot_id           = gt_lot_data_tbl(ln_cnt).lot_id
      AND    xsims.invent_ym       <= gt_close_yyyymm
      AND    ROWNUM               = 1;
      IF ( ln_data_cnt = 0 ) THEN
        -- 当月発生分ロットの為、単価を更新する
        gt_unit_price_upd_tab(gn_target_cnt)  := gt_lot_data_tbl(ln_cnt).unit_price;  -- 単価
        gt_unit_price_upd_flag_tbl(gn_target_cnt) := NULL;                            -- 更新する
        gn_upd_cnt :=  gn_upd_cnt + 1;
      ELSE
        -- 棚卸月末在庫テーブルの直近締め月以下に存在する場合は単価変更なし
        SELECT /*+ INDEX(ilm IC_LOTS_MST_PK) */
          TO_NUMBER(NVL(ilm.attribute7,0)) AS unit_price
        INTO   gt_unit_price_upd_tab(gn_target_cnt)                                 -- ロットマスタの単価設定
        FROM   ic_lots_mst ilm
        WHERE  ilm.item_id = gt_lot_data_tbl(ln_cnt).item_id
        AND    ilm.lot_id  = gt_lot_data_tbl(ln_cnt).lot_id;
        --単価更新はロットマスタの単価を取得する為、更新しない
        gt_unit_price_upd_flag_tbl(gn_target_cnt) := gv_update_flag;                -- 更新しない
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
--
      -- 値セット
--2013/01/08 DEL AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
--      gt_item_id_upd_tab(gn_upd_cnt)     := gt_lot_data_tbl(ln_cnt).item_id;     -- 品目ID
--      gt_item_code_upd_tab(gn_upd_cnt)   := gt_lot_data_tbl(ln_cnt).item_code;   -- 品目コード
--      gt_lot_id_upd_tab(gn_upd_cnt)      := gt_lot_data_tbl(ln_cnt).lot_id;      -- ロットID
--      gt_lot_num_upd_tab(gn_upd_cnt)     := gt_lot_data_tbl(ln_cnt).lot_num;     -- ロットNo
--      gt_trans_qty_upd_tab(gn_upd_cnt)   := gt_lot_data_tbl(ln_cnt).trans_qty;   -- 数量
--      gt_attribute1_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute1;  -- OPMロットマスタ ＤＦＦ項目１
--      gt_attribute2_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute2;  -- OPMロットマスタ ＤＦＦ項目２
--      gt_attribute3_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute3;  -- OPMロットマスタ ＤＦＦ項目３
--      gt_attribute4_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute4;  -- OPMロットマスタ ＤＦＦ項目４
--      gt_attribute5_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute5;  -- OPMロットマスタ ＤＦＦ項目５
--      gt_attribute6_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute6;  -- OPMロットマスタ ＤＦＦ項目６
--      gt_unit_price_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).unit_price;  -- 単価
--      gt_attribute8_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute8;  -- OPMロットマスタ ＤＦＦ項目８
--      gt_attribute9_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute9;  -- OPMロットマスタ ＤＦＦ項目９
--      gt_attribute10_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute10; -- OPMロットマスタ ＤＦＦ項目１０
--      gt_attribute11_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute11; -- OPMロットマスタ ＤＦＦ項目１１
--      gt_attribute12_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute12; -- OPMロットマスタ ＤＦＦ項目１２
--      gt_attribute13_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute13; -- OPMロットマスタ ＤＦＦ項目１３
--      gt_attribute14_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute14; -- OPMロットマスタ ＤＦＦ項目１４
--      gt_attribute15_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute15; -- OPMロットマスタ ＤＦＦ項目１５
--      gt_attribute16_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute16; -- OPMロットマスタ ＤＦＦ項目１６
--      gt_attribute17_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute17; -- OPMロットマスタ ＤＦＦ項目１７
--      gt_attribute18_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute18; -- OPMロットマスタ ＤＦＦ項目１８
--      gt_attribute19_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute19; -- OPMロットマスタ ＤＦＦ項目１９
--      gt_attribute20_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute20; -- OPMロットマスタ ＤＦＦ項目２０
--      gt_attribute21_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute21; -- OPMロットマスタ ＤＦＦ項目２１
--      gt_attribute22_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute22; -- OPMロットマスタ ＤＦＦ項目２２
--      gt_attribute23_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute23; -- OPMロットマスタ ＤＦＦ項目２３
--      gt_attribute24_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute24; -- OPMロットマスタ ＤＦＦ項目２４
--      gt_attribute25_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute25; -- OPMロットマスタ ＤＦＦ項目２５
--      gt_attribute26_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute26; -- OPMロットマスタ ＤＦＦ項目２６
--      gt_attribute27_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute27; -- OPMロットマスタ ＤＦＦ項目２７
--      gt_attribute28_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute28; -- OPMロットマスタ ＤＦＦ項目２８
--      gt_attribute29_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute29; -- OPMロットマスタ ＤＦＦ項目２９
--      gt_attribute30_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute30; -- OPMロットマスタ ＤＦＦ項目３０
--2013/01/08 DEL AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
      gt_item_id_upd_tab(gn_target_cnt)     := gt_lot_data_tbl(ln_cnt).item_id;     -- 品目ID
      gt_item_code_upd_tab(gn_target_cnt)   := gt_lot_data_tbl(ln_cnt).item_code;   -- 品目コード
      gt_lot_id_upd_tab(gn_target_cnt)      := gt_lot_data_tbl(ln_cnt).lot_id;      -- ロットID
      gt_lot_num_upd_tab(gn_target_cnt)     := gt_lot_data_tbl(ln_cnt).lot_num;     -- ロットNo
      gt_trans_qty_upd_tab(gn_target_cnt)   := gt_lot_data_tbl(ln_cnt).trans_qty;   -- 数量
      gt_attribute1_upd_tab(gn_target_cnt)  := gt_lot_data_tbl(ln_cnt).attribute1;  -- OPMロットマスタ ＤＦＦ項目１
      gt_attribute2_upd_tab(gn_target_cnt)  := gt_lot_data_tbl(ln_cnt).attribute2;  -- OPMロットマスタ ＤＦＦ項目２
      gt_attribute3_upd_tab(gn_target_cnt)  := gt_lot_data_tbl(ln_cnt).attribute3;  -- OPMロットマスタ ＤＦＦ項目３
      gt_attribute4_upd_tab(gn_target_cnt)  := gt_lot_data_tbl(ln_cnt).attribute4;  -- OPMロットマスタ ＤＦＦ項目４
      gt_attribute5_upd_tab(gn_target_cnt)  := gt_lot_data_tbl(ln_cnt).attribute5;  -- OPMロットマスタ ＤＦＦ項目５
      gt_attribute6_upd_tab(gn_target_cnt)  := gt_lot_data_tbl(ln_cnt).attribute6;  -- OPMロットマスタ ＤＦＦ項目６
      gt_attribute8_upd_tab(gn_target_cnt)  := gt_lot_data_tbl(ln_cnt).attribute8;  -- OPMロットマスタ ＤＦＦ項目８
      gt_attribute9_upd_tab(gn_target_cnt)  := gt_lot_data_tbl(ln_cnt).attribute9;  -- OPMロットマスタ ＤＦＦ項目９
      gt_attribute10_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute10; -- OPMロットマスタ ＤＦＦ項目１０
      gt_attribute11_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute11; -- OPMロットマスタ ＤＦＦ項目１１
      gt_attribute12_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute12; -- OPMロットマスタ ＤＦＦ項目１２
      gt_attribute13_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute13; -- OPMロットマスタ ＤＦＦ項目１３
      gt_attribute14_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute14; -- OPMロットマスタ ＤＦＦ項目１４
      gt_attribute15_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute15; -- OPMロットマスタ ＤＦＦ項目１５
      gt_attribute16_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute16; -- OPMロットマスタ ＤＦＦ項目１６
      gt_attribute17_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute17; -- OPMロットマスタ ＤＦＦ項目１７
      gt_attribute18_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute18; -- OPMロットマスタ ＤＦＦ項目１８
      gt_attribute19_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute19; -- OPMロットマスタ ＤＦＦ項目１９
      gt_attribute20_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute20; -- OPMロットマスタ ＤＦＦ項目２０
      gt_attribute21_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute21; -- OPMロットマスタ ＤＦＦ項目２１
      gt_attribute22_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute22; -- OPMロットマスタ ＤＦＦ項目２２
      gt_attribute23_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute23; -- OPMロットマスタ ＤＦＦ項目２３
      gt_attribute24_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute24; -- OPMロットマスタ ＤＦＦ項目２４
      gt_attribute25_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute25; -- OPMロットマスタ ＤＦＦ項目２５
      gt_attribute26_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute26; -- OPMロットマスタ ＤＦＦ項目２６
      gt_attribute27_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute27; -- OPMロットマスタ ＤＦＦ項目２７
      gt_attribute28_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute28; -- OPMロットマスタ ＤＦＦ項目２８
      gt_attribute29_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute29; -- OPMロットマスタ ＤＦＦ項目２９
      gt_attribute30_upd_tab(gn_target_cnt) := gt_lot_data_tbl(ln_cnt).attribute30; -- OPMロットマスタ ＤＦＦ項目３０
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
--
    END LOOP upd_data_loop;
--
    IF ( gn_upd_cnt > 0 ) THEN
      -- データカウントを成功データカウントにセット
      gn_normal_cnt := gn_upd_cnt;
    ELSE
      -- 処理対象レコードが0件の場合
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- モジュール名略称：XXCMN マスタ・経理共通
                   ,gv_msg_xxcmn10036   -- メッセージ：APP-XXCMN-10036 データ取得エラー
                   ),1,5000);
-- 2008/09/11 ADD START
      gn_no_data := 1;     -- 取得データ0件時用変数
-- 2008/09/11 ADD END
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
   * Procedure Name   : upd_table_api
   * Description      : OPMロットマスタ更新処理(D-2)
   ***********************************************************************************/
  PROCEDURE upd_table_api(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_table_api'; -- プログラム名
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
    in_api_version      NUMBER DEFAULT 1.0;
    lv_return_status    VARCHAR2(30);
    ln_msg_count        NUMBER;
    lv_msg_data         VARCHAR2(2000);
    lr_lot_rec          ic_lots_mst%ROWTYPE;
    lv_api_name         VARCHAR2(200);
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
    -- 更新処理
    -- =====================================
    <<upd_lot_loop>>
    FOR ln_cnt IN 1..gt_item_id_upd_tab.COUNT LOOP
--
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
      -- 棚卸月末在庫にデータが存在する場合はマスタ更新不可とする
      IF ( gt_unit_price_upd_flag_tbl(ln_cnt) IS NULL ) THEN
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
        lr_lot_rec.item_id     := gt_item_id_upd_tab(ln_cnt);     -- 品目ID
        lr_lot_rec.lot_id      := gt_lot_id_upd_tab(ln_cnt);      -- ロットID
        lr_lot_rec.lot_no      := gt_lot_num_upd_tab(ln_cnt);     -- ロットNo
        lr_lot_rec.attribute1  := gt_attribute1_upd_tab(ln_cnt);  -- ＤＦＦ項目１
        lr_lot_rec.attribute2  := gt_attribute2_upd_tab(ln_cnt);  -- ＤＦＦ項目２
        lr_lot_rec.attribute3  := gt_attribute3_upd_tab(ln_cnt);  -- ＤＦＦ項目３
        lr_lot_rec.attribute4  := gt_attribute4_upd_tab(ln_cnt);  -- ＤＦＦ項目４
        lr_lot_rec.attribute5  := gt_attribute5_upd_tab(ln_cnt);  -- ＤＦＦ項目５
        lr_lot_rec.attribute6  := gt_attribute6_upd_tab(ln_cnt);  -- ＤＦＦ項目６
        lr_lot_rec.attribute7  := gt_unit_price_upd_tab(ln_cnt);  -- 単価
        lr_lot_rec.attribute8  := gt_attribute8_upd_tab(ln_cnt);  -- ＤＦＦ項目８
        lr_lot_rec.attribute9  := gt_attribute9_upd_tab(ln_cnt);  -- ＤＦＦ項目９
        lr_lot_rec.attribute10 := gt_attribute10_upd_tab(ln_cnt); -- ＤＦＦ項目１０
        lr_lot_rec.attribute11 := gt_attribute11_upd_tab(ln_cnt); -- ＤＦＦ項目１１
        lr_lot_rec.attribute12 := gt_attribute12_upd_tab(ln_cnt); -- ＤＦＦ項目１２
        lr_lot_rec.attribute13 := gt_attribute13_upd_tab(ln_cnt); -- ＤＦＦ項目１３
        lr_lot_rec.attribute14 := gt_attribute14_upd_tab(ln_cnt); -- ＤＦＦ項目１４
        lr_lot_rec.attribute15 := gt_attribute15_upd_tab(ln_cnt); -- ＤＦＦ項目１５
        lr_lot_rec.attribute16 := gt_attribute16_upd_tab(ln_cnt); -- ＤＦＦ項目１６
        lr_lot_rec.attribute17 := gt_attribute17_upd_tab(ln_cnt); -- ＤＦＦ項目１７
        lr_lot_rec.attribute18 := gt_attribute18_upd_tab(ln_cnt); -- ＤＦＦ項目１８
        lr_lot_rec.attribute19 := gt_attribute19_upd_tab(ln_cnt); -- ＤＦＦ項目１９
        lr_lot_rec.attribute20 := gt_attribute20_upd_tab(ln_cnt); -- ＤＦＦ項目２０
        lr_lot_rec.attribute21 := gt_attribute21_upd_tab(ln_cnt); -- ＤＦＦ項目２１
        lr_lot_rec.attribute22 := gt_attribute22_upd_tab(ln_cnt); -- ＤＦＦ項目２２
        lr_lot_rec.attribute23 := gt_attribute23_upd_tab(ln_cnt); -- ＤＦＦ項目２３
        lr_lot_rec.attribute24 := gt_attribute24_upd_tab(ln_cnt); -- ＤＦＦ項目２４
        lr_lot_rec.attribute25 := gt_attribute25_upd_tab(ln_cnt); -- ＤＦＦ項目２５
        lr_lot_rec.attribute26 := gt_attribute26_upd_tab(ln_cnt); -- ＤＦＦ項目２６
        lr_lot_rec.attribute27 := gt_attribute27_upd_tab(ln_cnt); -- ＤＦＦ項目２７
        lr_lot_rec.attribute28 := gt_attribute28_upd_tab(ln_cnt); -- ＤＦＦ項目２８
        lr_lot_rec.attribute29 := gt_attribute29_upd_tab(ln_cnt); -- ＤＦＦ項目２９
        lr_lot_rec.attribute30 := gt_attribute30_upd_tab(ln_cnt); -- ＤＦＦ項目３０
        -- 2004/04/25 1.1
        lr_lot_rec.last_update_date := gd_date;
        lr_lot_rec.last_updated_by  := gn_user_id;
--
        -- OPMロットマスタ
        GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF (
            P_API_VERSION          => in_api_version
           ,X_RETURN_STATUS        => lv_return_status
           ,X_MSG_COUNT            => ln_msg_count
           ,X_MSG_DATA             => lv_msg_data
           ,P_LOT_REC              => lr_lot_rec
        );
--
        -- 失敗
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          lv_api_name := 'GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF';
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_016,
                                              gv_tkn_api_name, lv_api_name);
--
          FND_MSG_PUB.GET( P_MSG_INDEX     => 1, 
                           P_ENCODED       => FND_API.G_FALSE,
                           P_DATA          => lv_msg_data,
                           P_MSG_INDEX_OUT => ln_msg_count );
--
          lv_errbuf := lv_msg_data;
          RAISE global_api_expt;
        END IF;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
      END IF;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
--
    END LOOP upd_lot_loop;
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
  END upd_table_api;
--
  /**********************************************************************************
   * Procedure Name   : get_data_dump
   * Description      : データダンプ取得処理
   ***********************************************************************************/
  PROCEDURE get_data_dump(
    ir_xxcmn_lot_cost     IN  xxcmn_lot_cost%ROWTYPE,  
                                                -- ロット別原価（アドオン）
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
    iv_unit_price_flag    IN  VARCHAR2,         -- 更新フラグ
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
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
--
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
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
    -- 更新可否フラグが未更新の場合
    IF  iv_unit_price_flag = gv_update_flag THEN
      ov_dump := ov_dump
                 || gv_msg_comma ||
                 iv_unit_price_flag                   -- 更新未更新分
               ;
    END IF;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
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
    upd_data_rec  xxcmn_lot_cost%ROWTYPE; -- ロット別原価（アドオン）型レコード
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
    FOR ln_rec_cnt IN 1..gt_item_id_upd_tab.COUNT LOOP
--
      -- =============================
      -- ダンプ用レコードにセット
      -- =============================
      upd_data_rec.item_id    := gt_item_id_upd_tab(ln_rec_cnt);     -- 品目ID
      upd_data_rec.item_code  := gt_item_code_upd_tab(ln_rec_cnt);   -- 品目コード
      upd_data_rec.lot_id     := gt_lot_id_upd_tab(ln_rec_cnt);      -- ロットID
      upd_data_rec.lot_num    := gt_lot_num_upd_tab(ln_rec_cnt);     -- ロットNo
      upd_data_rec.trans_qty  := gt_trans_qty_upd_tab(ln_rec_cnt);   -- 数量
      upd_data_rec.unit_ploce := gt_unit_price_upd_tab(ln_rec_cnt);  -- 単価
--
      -- =============================
      -- データダンプ取得処理
      -- =============================
      get_data_dump(
          ir_xxcmn_lot_cost => upd_data_rec
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
        , iv_unit_price_flag => gt_unit_price_upd_flag_tbl(ln_rec_cnt) -- 更新フラグ
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
        , ov_dump           => lv_dump
        , ov_errbuf         => lv_errbuf
        , ov_retcode        => lv_retcode
        , ov_errmsg         => lv_errmsg
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
    gd_date       := SYSDATE;
    gn_user_id    := FND_GLOBAL.USER_ID;
--
    -- 更新用PL/SQL表初期化
    gt_item_id_upd_tab.DELETE;     -- 品目ID
    gt_item_code_upd_tab.DELETE;   -- 品目コード
    gt_lot_id_upd_tab.DELETE;      -- ロットID
    gt_lot_num_upd_tab.DELETE;     -- ロットNo
    gt_trans_qty_upd_tab.DELETE;   -- 取引数量
    gt_attribute1_upd_tab.DELETE;  -- ＤＦＦ項目１
    gt_attribute2_upd_tab.DELETE;  -- ＤＦＦ項目２
    gt_attribute3_upd_tab.DELETE;  -- ＤＦＦ項目３
    gt_attribute4_upd_tab.DELETE;  -- ＤＦＦ項目４
    gt_attribute5_upd_tab.DELETE;  -- ＤＦＦ項目５
    gt_attribute6_upd_tab.DELETE;  -- ＤＦＦ項目６
    gt_unit_price_upd_tab.DELETE;  -- 単価
    gt_attribute8_upd_tab.DELETE;  -- ＤＦＦ項目８
    gt_attribute9_upd_tab.DELETE;  -- ＤＦＦ項目９
    gt_attribute10_upd_tab.DELETE; -- ＤＦＦ項目１０
    gt_attribute11_upd_tab.DELETE; -- ＤＦＦ項目１１
    gt_attribute12_upd_tab.DELETE; -- ＤＦＦ項目１２
    gt_attribute13_upd_tab.DELETE; -- ＤＦＦ項目１３
    gt_attribute14_upd_tab.DELETE; -- ＤＦＦ項目１４
    gt_attribute15_upd_tab.DELETE; -- ＤＦＦ項目１５
    gt_attribute16_upd_tab.DELETE; -- ＤＦＦ項目１６
    gt_attribute17_upd_tab.DELETE; -- ＤＦＦ項目１７
    gt_attribute18_upd_tab.DELETE; -- ＤＦＦ項目１８
    gt_attribute19_upd_tab.DELETE; -- ＤＦＦ項目１９
    gt_attribute20_upd_tab.DELETE; -- ＤＦＦ項目２０
    gt_attribute21_upd_tab.DELETE; -- ＤＦＦ項目２１
    gt_attribute22_upd_tab.DELETE; -- ＤＦＦ項目２２
    gt_attribute23_upd_tab.DELETE; -- ＤＦＦ項目２３
    gt_attribute24_upd_tab.DELETE; -- ＤＦＦ項目２４
    gt_attribute25_upd_tab.DELETE; -- ＤＦＦ項目２５
    gt_attribute26_upd_tab.DELETE; -- ＤＦＦ項目２６
    gt_attribute27_upd_tab.DELETE; -- ＤＦＦ項目２７
    gt_attribute28_upd_tab.DELETE; -- ＤＦＦ項目２８
    gt_attribute29_upd_tab.DELETE; -- ＤＦＦ項目２９
    gt_attribute30_upd_tab.DELETE; -- ＤＦＦ項目３０
--
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
    gt_unit_price_upd_flag_tbl.DELETE; -- 単価更新フラグ(UPDATE)
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
--
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 START
    -- =======================================
    -- OPM在庫カレンダの直近締月取得
    -- =======================================
    -- 直近締め年月を取得
    gt_close_yyyymm := xxcmn_common_pkg.get_opminv_close_period;
--2013/01/08 ADD AUTHOR:M.Kitajima VER：1.4 CONTENT:E_本稼動_10355 END
--
    -- =======================================
    -- D-1.ロット別原価データ抽出処理
    -- =======================================
    get_lot_cost(
       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
-- 2008/09/11 UPDATE START
--    IF (lv_retcode = gv_status_error) THEN
--      RAISE global_process_expt;
    IF (gn_no_data = 1) THEN
      RAISE no_data_expt;
    ELSIF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- D-2.OPMロットマスタ更新処理
    -- =======================================
    upd_table_api(
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
-- 2008/09/11 ADD START
    -- 取得データ0件時例外
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_normal;
--
-- 2008/09/11 ADD END
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
END xxcmn790004c;
/
