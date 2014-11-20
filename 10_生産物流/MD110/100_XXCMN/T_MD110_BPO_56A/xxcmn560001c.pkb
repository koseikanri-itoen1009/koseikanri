CREATE OR REPLACE PACKAGE BODY xxcmn560001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn560001c(body)
 * Description      : トレーサビリティ
 * MD.050           : トレーサビリティ T_MD050_BPO_560
 * MD.070           : トレーサビリティ(56A) T_MD070_BPO_56A
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_item_id            品目ID取得
 *  get_lot_id             ロットID取得
 *  parameter_check        パラメータチェック                       (A-1)
 *  del_lot_trace          登録対象テーブル削除                     (A-2)
 *  get_lots_data          ロット系統データ抽出                     (A-3/A-5/A-7/A-9/A-11)
 *  put_lots_data_no1      ロット系統データ格納                     (A-4/A-6/A-8/A-10/A-12)
 *  insert_lots_data       ロット系統データ一括登録                 (A-13)
 *  disp_report            処理結果レポート出力
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/08    1.0   ORACLE 岩佐智治  main新規作成
 *  2008/05/27    1.1   Masayuki Ikeda   不具合修正
 *  2008/07/02    1.2   ORACLE 丸下博宣  循環参照防止にバッチIDを追加
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
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  required_expt          EXCEPTION;               -- 必須チェック例外
  not_exist_expt         EXCEPTION;               -- 存在チェック例外
  validate_expt          EXCEPTION;               -- 妥当性チェック例外
  lock_expt              EXCEPTION;               -- ロック取得例外
  profile_expt           EXCEPTION;               -- プロファイル取得例外
  no_data_expt           EXCEPTION;               -- 対象データ取得なし例外
  PRAGMA EXCEPTION_INIT(lock_expt, -54);          -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- メッセージ用定数
  gv_pkg_name         CONSTANT VARCHAR2(15) := 'xxcmn560001c';      -- パッケージ名
  gv_app_name         CONSTANT VARCHAR2(5)  := 'XXCMN';             -- アプリケーション短縮名
  gv_tkn_name_01      CONSTANT VARCHAR2(50) := '品目コード';        -- パラメータ：品目コード
  gv_tkn_name_02      CONSTANT VARCHAR2(50) := 'ロットNo';          -- パラメータ：ロットNo
  gv_tkn_name_03      CONSTANT VARCHAR2(50) := '出力制御';          -- パラメータ：出力制御
  gv_tkn_name_04      CONSTANT VARCHAR2(50) := 'XXCMN_KEEP_PERIOD'; -- プロファイル  ：保存期間
  gv_tkn_name_05      CONSTANT VARCHAR2(50) := '保存期間';          -- プロファイル名：保存期間
  gv_tkn_name_06      CONSTANT VARCHAR2(50) := 'ORG_ID';            -- プロファイル  ：組織ID
  gv_tkn_name_07      CONSTANT VARCHAR2(50) := '組織ID';            -- プロファイル名：組織ID
  gv_tkn_name_08      CONSTANT VARCHAR2(50) := 'OPM品目マスタ';     -- テーブル名
  gv_tkn_name_09      CONSTANT VARCHAR2(50) := 'OPMロットマスタ';   -- テーブル名
--
  -- メッセージ
  gv_msg_xxcmn10002   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';   -- プロファイル取得エラー
  gv_msg_xxcmn10019   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';   -- ロック取得エラー
  gv_msg_xxcmn10033   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10033';   -- パラメータエラー：必須
  gv_msg_xxcmn10034   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10034';   -- パラメータエラー：存在１
  gv_msg_xxcmn10035   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10035';   -- パラメータエラー：入力値
--
  -- トークン
  gv_tkn_para_name    CONSTANT VARCHAR2(10) := 'PARAM_NAME';        -- トークン：パラメータ名
  gv_tkn_table_name   CONSTANT VARCHAR2(10) := 'TABLE_NAME';        -- トークン：テーブル名
  gv_tkn_para_value   CONSTANT VARCHAR2(11) := 'PARAM_VALUE';       -- トークン：パラメータ値
  gv_tkn_profile      CONSTANT VARCHAR2(10) := 'NG_PROFILE';        -- トークン：プロファイル名
  gv_tkn_table        CONSTANT VARCHAR2(10) := 'TABLE';             -- トークン：テーブル名
--
  -- ユーザー定数
  gv_trace            CONSTANT VARCHAR2(1)  := '1';                 -- 出力制御：ロットトレース
  gv_trace_back       CONSTANT VARCHAR2(1)  := '2';                 -- 出力制御：ロットトレースバック
  gv_rcv_tran_type    CONSTANT VARCHAR2(10) := 'RECEIVE';           -- 受入取引タイプ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  -- 在庫トランザクション生産レコード
  TYPE mst_itp_rec IS RECORD(
    -- ロット基本情報
    p_item_id           ic_tran_pnd.item_id%TYPE,                         -- 親品目ID
    p_lot_id            ic_tran_pnd.lot_id%TYPE,                          -- 親ロットID
    p_batch_id          gme_material_details.batch_id%TYPE,               -- 親バッチID
    p_item_no           ic_item_mst_b.item_no%TYPE,                       -- 親品目コード
    p_item_name         xxcmn_item_mst_b.item_name%TYPE,                  -- 親品目名称
    p_lot_no            ic_lots_mst.lot_no%TYPE,                          -- 親ロットNo
    p_whse_code         ic_tran_pnd.whse_code%TYPE,                       -- 倉庫コード
    c_item_id           ic_tran_pnd.item_id%TYPE,                         -- 子品目ID
    c_lot_id            ic_tran_pnd.lot_id%TYPE,                          -- 子ロットID
    c_batch_id          gme_material_details.batch_id%TYPE,               -- 子バッチID
    c_item_no           ic_item_mst_b.item_no%TYPE,                       -- 子品目コード
    c_item_name         xxcmn_item_mst_b.item_name%TYPE,                  -- 子品目名称
    c_lot_no            ic_lots_mst.lot_no%TYPE,                          -- 子ロットNo
    -- OPMロット情報
    lot_date            ic_lots_mst.attribute1%TYPE,                      -- 製造年月日
    lot_sign            ic_lots_mst.attribute2%TYPE,                      -- 固有記号
    best_bfr_date       ic_lots_mst.attribute3%TYPE,                      -- 賞味期限
    dlv_date_first      ic_lots_mst.attribute4%TYPE,                      -- 納入日(初回)
    dlv_date_last       ic_lots_mst.attribute5%TYPE,                      -- 納入日(最終)
    stock_ins_amount    ic_lots_mst.attribute6%TYPE,                      -- 在庫入数
    tea_period_dev      ic_lots_mst.attribute10%TYPE,                     -- 茶期区分
    product_year        ic_lots_mst.attribute11%TYPE,                     -- 年度
    product_home        ic_lots_mst.attribute12%TYPE,                     -- 産地
    product_type        ic_lots_mst.attribute13%TYPE,                     -- タイプ
    product_ranc_1      ic_lots_mst.attribute14%TYPE,                     -- ランク１
    product_ranc_2      ic_lots_mst.attribute15%TYPE,                     -- ランク２
    product_slip_dev    ic_lots_mst.attribute16%TYPE,                     -- 生産伝票区分
    description         ic_lots_mst.attribute18%TYPE,                     -- 摘要
    inspect_req         ic_lots_mst.attribute22%TYPE,                     -- 検査依頼No
    -- 生産系情報
    batch_num           gme_batch_header.batch_no%TYPE,                   -- 製造バッチNo
    batch_date          gme_material_details.attribute17%TYPE,            -- 製造日
    line_num            gmd_routings_b.routing_no%TYPE,                   -- ライン番号
    -- 投入系情報
    turn_date           gme_material_details.attribute11%TYPE,            -- 投入日
    turn_batch_num      gme_batch_header.batch_no%TYPE                    -- 投入バッチNo
  );
--
  -- 受入情報取得
  TYPE mst_rcv_rec IS RECORD(
    p_item_id           ic_tran_pnd.item_id%TYPE,                         -- 親品目ID
    p_lot_id            ic_tran_pnd.lot_id%TYPE,                          -- 親ロットID
    p_item_no           ic_item_mst_b.item_no%TYPE,                       -- 親品目コード
    p_item_name         xxcmn_item_mst_b.item_name%TYPE,                  -- 親品目名称
    p_lot_no            ic_lots_mst.lot_no%TYPE,                          -- 親ロットNo
    whse_code           ic_tran_pnd.whse_code%TYPE,                       -- 倉庫コード
    receipt_date        rcv_transactions.transaction_date%TYPE,           -- 受入日
    receipt_num         rcv_shipment_headers.receipt_num%TYPE,            -- 受入番号
    order_num           po_headers_all.segment1%TYPE,                     -- 発注番号
    supp_name           xxcmn_vendors.vendor_name%TYPE,                   -- 仕入先名
    supp_code           po_vendors.segment1%TYPE,                         -- 仕入先コード
    trader_name         xxcmn_vendors.vendor_name%TYPE,                   -- 斡旋業者
    -- OPMロット情報
    lot_date            ic_lots_mst.attribute1%TYPE,                      -- 製造年月日
    lot_sign            ic_lots_mst.attribute2%TYPE,                      -- 固有記号
    best_bfr_date       ic_lots_mst.attribute3%TYPE,                      -- 賞味期限
    dlv_date_first      ic_lots_mst.attribute4%TYPE,                      -- 納入日(初回)
    dlv_date_last       ic_lots_mst.attribute5%TYPE,                      -- 納入日(最終)
    stock_ins_amount    ic_lots_mst.attribute6%TYPE,                      -- 在庫入数
    tea_period_dev      ic_lots_mst.attribute10%TYPE,                     -- 茶期区分
    product_year        ic_lots_mst.attribute11%TYPE,                     -- 年度
    product_home        ic_lots_mst.attribute12%TYPE,                     -- 産地
    product_type        ic_lots_mst.attribute13%TYPE,                     -- タイプ
    product_ranc_1      ic_lots_mst.attribute14%TYPE,                     -- ランク１
    product_ranc_2      ic_lots_mst.attribute15%TYPE,                     -- ランク２
    product_slip_dev    ic_lots_mst.attribute16%TYPE,                     -- 生産伝票区分
    description         ic_lots_mst.attribute18%TYPE,                     -- 摘要
    inspect_req         ic_lots_mst.attribute22%TYPE                      -- 検査依頼No
  );
--
  -- ロットトレース削除用レコード
  TYPE mst_del_lot_rec IS RECORD(
    division            xxcmn_lot_trace.division%TYPE,                    -- 区分
    level_num           xxcmn_lot_trace.level_num%TYPE,                   -- レベル番号
    item_code           xxcmn_lot_trace.item_code%TYPE,                   -- 親品目コード
    lot_num             xxcmn_lot_trace.lot_num%TYPE,                     -- 親ロットNo
    request_id          xxcmn_lot_trace.request_id%TYPE                   -- 要求ID
  );
--
  -- ***************************************
  -- ***      登録用項目テーブル型       ***
  -- ***************************************
  -- 登録用
  -- 区分
  TYPE reg_division               IS TABLE OF  xxcmn_lot_trace.division               %TYPE INDEX BY BINARY_INTEGER;
  -- レベル番号
  TYPE reg_level_num              IS TABLE OF  xxcmn_lot_trace.level_num              %TYPE INDEX BY BINARY_INTEGER;
  -- 親品目ID
  TYPE reg_item_id                IS TABLE OF  ic_tran_pnd.item_id                    %TYPE INDEX BY BINARY_INTEGER;
  -- 親品目コード
  TYPE reg_item_code              IS TABLE OF  ic_item_mst_b.item_no                  %TYPE INDEX BY BINARY_INTEGER;
  -- 親品目名称
  TYPE reg_item_name              IS TABLE OF  xxcmn_item_mst_b.item_name             %TYPE INDEX BY BINARY_INTEGER;
  -- 親ロットID
  TYPE reg_lot_id                 IS TABLE OF  ic_lots_mst.lot_id                     %TYPE INDEX BY BINARY_INTEGER;
  -- 親ロットNo
  TYPE reg_lot_num                IS TABLE OF  ic_lots_mst.lot_no                     %TYPE INDEX BY BINARY_INTEGER;
  -- 子品目ID
  TYPE reg_trace_item_id          IS TABLE OF  ic_item_mst_b.item_id                  %TYPE INDEX BY BINARY_INTEGER;
  -- 子品目コード
  TYPE reg_trace_item_code        IS TABLE OF  ic_item_mst_b.item_no                  %TYPE INDEX BY BINARY_INTEGER;
  -- 子品目名称
  TYPE reg_trace_item_name        IS TABLE OF  xxcmn_item_mst_b.item_name             %TYPE INDEX BY BINARY_INTEGER;
  -- 子ロットID
  TYPE reg_trace_lot_id           IS TABLE OF  ic_lots_mst.lot_id                     %TYPE INDEX BY BINARY_INTEGER;
  -- 子ロットNo
  TYPE reg_trace_lot_num          IS TABLE OF  ic_lots_mst.lot_no                     %TYPE INDEX BY BINARY_INTEGER;
  -- 製造バッチNo
  TYPE reg_batch_num              IS TABLE OF  gme_batch_header.batch_no              %TYPE INDEX BY BINARY_INTEGER;
  -- 製造日
  TYPE reg_batch_date             IS TABLE OF  gme_material_details.attribute17       %TYPE INDEX BY BINARY_INTEGER;
  -- 倉庫コード
  TYPE reg_whse_code              IS TABLE OF  ic_tran_pnd.whse_code                  %TYPE INDEX BY BINARY_INTEGER;
  -- ライン番号
  TYPE reg_line_num               IS TABLE OF  gmd_routings_b.routing_no              %TYPE INDEX BY BINARY_INTEGER;
  -- 生産日
  TYPE reg_turn_date              IS TABLE OF  gme_material_details.attribute11       %TYPE INDEX BY BINARY_INTEGER;
  -- 投入バッチNo
  TYPE reg_turn_batch_num         IS TABLE OF  gme_batch_header.batch_no              %TYPE INDEX BY BINARY_INTEGER;
  -- 受入日
  TYPE reg_receipt_date           IS TABLE OF  rcv_transactions.transaction_date      %TYPE INDEX BY BINARY_INTEGER;
  -- 受入番号
  TYPE reg_receipt_num            IS TABLE OF  rcv_shipment_headers.receipt_num       %TYPE INDEX BY BINARY_INTEGER;
  -- 発注番号
  TYPE reg_order_num              IS TABLE OF  po_headers_all.segment1                %TYPE INDEX BY BINARY_INTEGER;
  -- 仕入先名
  TYPE reg_supp_name              IS TABLE OF  xxcmn_vendors.vendor_name              %TYPE INDEX BY BINARY_INTEGER;
  -- 仕入先コード
  TYPE reg_supp_code              IS TABLE OF  po_vendors.segment1                    %TYPE INDEX BY BINARY_INTEGER;
  -- 斡旋業者
  TYPE reg_trader_name            IS TABLE OF  xxcmn_vendors.vendor_name              %TYPE INDEX BY BINARY_INTEGER;
  -- 製造年月日
  TYPE reg_lot_date               IS TABLE OF  ic_lots_mst.attribute1                 %TYPE INDEX BY BINARY_INTEGER;
  -- 固有記号
  TYPE reg_lot_sign               IS TABLE OF  ic_lots_mst.attribute2                 %TYPE INDEX BY BINARY_INTEGER;
  -- 賞味期限
  TYPE reg_best_bfr_date          IS TABLE OF  ic_lots_mst.attribute3                 %TYPE INDEX BY BINARY_INTEGER;
  -- 納入日(初回)
  TYPE reg_dlv_date_first         IS TABLE OF  ic_lots_mst.attribute4                 %TYPE INDEX BY BINARY_INTEGER;
  -- 納入日(最終)
  TYPE reg_dlv_date_last          IS TABLE OF  ic_lots_mst.attribute5                 %TYPE INDEX BY BINARY_INTEGER;
  -- 在庫入数
  TYPE reg_stock_ins_amount       IS TABLE OF  ic_lots_mst.attribute6                 %TYPE INDEX BY BINARY_INTEGER;
  -- 茶期区分
  TYPE reg_tea_period_dev         IS TABLE OF  ic_lots_mst.attribute10                %TYPE INDEX BY BINARY_INTEGER;
  -- 年度
  TYPE reg_product_year           IS TABLE OF  ic_lots_mst.attribute11                %TYPE INDEX BY BINARY_INTEGER;
  -- 産地
  TYPE reg_product_home           IS TABLE OF  ic_lots_mst.attribute12                %TYPE INDEX BY BINARY_INTEGER;
  -- タイプ
  TYPE reg_product_type           IS TABLE OF  ic_lots_mst.attribute13                %TYPE INDEX BY BINARY_INTEGER;
  -- ランク１
  TYPE reg_product_ranc_1         IS TABLE OF  ic_lots_mst.attribute14                %TYPE INDEX BY BINARY_INTEGER;
  -- ランク２
  TYPE reg_product_ranc_2         IS TABLE OF  ic_lots_mst.attribute15                %TYPE INDEX BY BINARY_INTEGER;
  -- 生産伝票区分
  TYPE reg_product_slip_dev       IS TABLE OF  ic_lots_mst.attribute16                %TYPE INDEX BY BINARY_INTEGER;
  -- 摘要
  TYPE reg_description            IS TABLE OF  ic_lots_mst.attribute18                %TYPE INDEX BY BINARY_INTEGER;
  -- 検査依頼No
  TYPE reg_inspect_req            IS TABLE OF  ic_lots_mst.attribute22                %TYPE INDEX BY BINARY_INTEGER;
  -- 作成者
  TYPE reg_created_by             IS TABLE OF  xxcmn_lot_trace.created_by             %TYPE INDEX BY BINARY_INTEGER;
  -- 作成日
  TYPE reg_creation_date          IS TABLE OF  xxcmn_lot_trace.creation_date          %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE reg_last_updated_by        IS TABLE OF  xxcmn_lot_trace.last_updated_by        %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE reg_last_update_date       IS TABLE OF  xxcmn_lot_trace.last_update_date       %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE reg_last_update_login      IS TABLE OF  xxcmn_lot_trace.last_update_login      %TYPE INDEX BY BINARY_INTEGER;
  -- 要求ID
  TYPE reg_request_id             IS TABLE OF  xxcmn_lot_trace.request_id             %TYPE INDEX BY BINARY_INTEGER;
  -- プログラムID
  TYPE reg_program_id             IS TABLE OF  xxcmn_lot_trace.program_id             %TYPE INDEX BY BINARY_INTEGER;
  -- プログラムアプリケーションID
  TYPE reg_program_application_id IS TABLE OF xxcmn_lot_trace.program_application_id  %TYPE INDEX BY BINARY_INTEGER;
  -- プログラム更新日
  TYPE reg_program_update_date    IS TABLE OF xxcmn_lot_trace.program_update_date     %TYPE INDEX BY BINARY_INTEGER;
--
  -- 削除用
  -- 区分
  TYPE del_division               IS TABLE OF  xxcmn_lot_trace.division               %TYPE INDEX BY BINARY_INTEGER;
  -- レベル番号
  TYPE del_level_num              IS TABLE OF  xxcmn_lot_trace.level_num              %TYPE INDEX BY BINARY_INTEGER;
  -- 親品目コード
  TYPE del_item_code              IS TABLE OF  xxcmn_lot_trace.item_code              %TYPE INDEX BY BINARY_INTEGER;
  -- 親ロットNo
  TYPE del_lot_num                IS TABLE OF  xxcmn_lot_trace.lot_num                %TYPE INDEX BY BINARY_INTEGER;
  -- 要求ID
  TYPE del_request_id             IS TABLE OF  xxcmn_lot_trace.request_id             %TYPE INDEX BY BINARY_INTEGER;
--
  -- パラメータ情報(トレース情報キー項目)
  gv_item_id            ic_item_mst_b.item_id%TYPE;                       -- 品目ID
  gv_lot_id             ic_lots_mst.lot_id%TYPE;                          -- ロットID
--
  -- ***************************************
  -- ***      項目格納テーブル型定義     ***
  -- ***************************************
--
  -- ロットトレースアドオン格納用テーブル型定義
  -- 生産情報レコード
  TYPE mst_itp_tbl        IS TABLE OF mst_itp_rec       INDEX BY PLS_INTEGER;
  -- 受入情報レコード
  TYPE mst_rcv_tbl        IS TABLE OF mst_rcv_rec       INDEX BY PLS_INTEGER;
  -- ロットトレースアドオン削除用レコード
  TYPE mst_del_lot_tbl    IS TABLE OF mst_del_lot_rec   INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 定数
  gn_keep_period              NUMBER;                     -- プロファイル：保存期間
  gn_org_id                   NUMBER;                     -- プロファイル：組織ID
  gn_created_by               NUMBER;                     -- 作成者
  gd_creation_date            DATE;                       -- 作成日
  gd_last_update_date         DATE;                       -- 最終更新日
  gn_last_update_by           NUMBER;                     -- 最終更新者
  gn_last_update_login        NUMBER;                     -- 最終更新ログイン
  gn_request_id               NUMBER;                     -- 要求ID
  gn_program_application_id   NUMBER;                     -- プログラムアプリケーションID
  gn_program_id               NUMBER;                     -- プログラムID
  gd_program_update_date      DATE;                       -- プログラム更新日
--
  -- テーブル型グローバル変数
  gt_itp_tbl                  mst_itp_tbl;                -- 生産情報
  gt_itp01_tbl                mst_itp_tbl;                -- 生産情報第一階層
  gt_itp02_tbl                mst_itp_tbl;                -- 生産情報第二階層
  gt_itp03_tbl                mst_itp_tbl;                -- 生産情報第三階層
  gt_itp04_tbl                mst_itp_tbl;                -- 生産情報第四階層
  gt_itp05_tbl                mst_itp_tbl;                -- 生産情報第五階層
  gt_rcv_tbl                  mst_rcv_tbl;                -- 受入情報
  gt_rcv01_tbl                mst_rcv_tbl;                -- 受入情報第一階層
  gt_rcv02_tbl                mst_rcv_tbl;                -- 受入情報第二階層
  gt_rcv03_tbl                mst_rcv_tbl;                -- 受入情報第三階層
  gt_rcv04_tbl                mst_rcv_tbl;                -- 受入情報第四階層
  gt_rcv05_tbl                mst_rcv_tbl;                -- 受入情報第五階層
  gt_del_lot_tbl              mst_del_lot_tbl;            -- ロットトレース削除用レコード
--
  -- 項目テーブル型定義
  gt_division                 reg_division;               -- 区分
  gt_level_num                reg_level_num;              -- レベル番号
  gt_item_id                  reg_item_id;                -- 親品目ID
  gt_item_code                reg_item_code;              -- 親品目コード
  gt_item_name                reg_item_name;              -- 親品目名称
  gt_lot_id                   reg_lot_id;                 -- 親ロットID
  gt_lot_num                  reg_lot_num;                -- 親ロットNo
  gt_trace_item_id            reg_trace_item_id;          -- 子品目ID
  gt_trace_item_code          reg_trace_item_code;        -- 子品目コード
  gt_trace_item_name          reg_trace_item_name;        -- 子品目名称
  gt_trace_lot_id             reg_trace_lot_id;           -- 子ロットID
  gt_trace_lot_num            reg_trace_lot_num;          -- 子ロットNo
  gt_batch_num                reg_batch_num;              -- 製造バッチNo
  gt_batch_date               reg_batch_date;             -- 製造日
  gt_whse_code                reg_whse_code;              -- 倉庫コード
  gt_line_num                 reg_line_num;               -- ライン番号
  gt_turn_date                reg_turn_date;              -- 生産日
  gt_turn_batch_num           reg_turn_batch_num;         -- 投入バッチNo
  gt_receipt_date             reg_receipt_date;           -- 受入日
  gt_receipt_num              reg_receipt_num;            -- 受入番号
  gt_order_num                reg_order_num;              -- 発注番号
  gt_supp_name                reg_supp_name;              -- 仕入先名
  gt_supp_code                reg_supp_code;              -- 仕入先コード
  gt_trader_name              reg_trader_name;            -- 斡旋業者
  gt_lot_date                 reg_lot_date;               -- 製造年月日
  gt_lot_sign                 reg_lot_sign;               -- 固有記号
  gt_best_bfr_date            reg_best_bfr_date;          -- 賞味期限
  gt_dlv_date_first           reg_dlv_date_first;         -- 納入日(初回)
  gt_dlv_date_last            reg_dlv_date_last;          -- 納入日(最終)
  gt_stock_ins_amount         reg_stock_ins_amount;       -- 在庫入数
  gt_tea_period_dev           reg_tea_period_dev;         -- 茶期区分
  gt_product_year             reg_product_year;           -- 年度
  gt_product_home             reg_product_home;           -- 産地
  gt_product_type             reg_product_type;           -- タイプ
  gt_product_ranc_1           reg_product_ranc_1;         -- ランク１
  gt_product_ranc_2           reg_product_ranc_2;         -- ランク２
  gt_product_slip_dev         reg_product_slip_dev;       -- 生産伝票区分
  gt_description              reg_description;            -- 摘要
  gt_inspect_req              reg_inspect_req;            -- 検査依頼No
  gt_created_by               reg_created_by;             -- 作成者
  gt_creation_date            reg_creation_date;          -- 作成日
  gt_last_updated_by          reg_last_updated_by;        -- 最終更新者
  gt_last_update_date         reg_last_update_date;       -- 最終更新日
  gt_last_update_login        reg_last_update_login;      -- 最終更新ログイン
  gt_request_id               reg_request_id;             -- 要求ID
  gt_program_id               reg_program_id;             -- プログラムID
  gt_program_application_id   reg_program_application_id; -- プログラムアプリケーションID
  gt_program_update_date      reg_program_update_date;    -- プログラム更新日
--
  /**********************************************************************************
   * Procedure Name   : get_item_id
   * Description      : 品目ID取得
   ***********************************************************************************/
  PROCEDURE get_item_id(
    iv_item_code        IN     VARCHAR,                 -- 入力パラメータ(品目コード)
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'get_item_id';           -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_item_code            VARCHAR2(15)            := iv_item_code;            -- 品目コード
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
    -- ***************************************
    -- ***            品目ID取得           ***
    -- ***************************************
    SELECT iimb.item_id
    INTO gv_item_id
    FROM ic_item_mst_b iimb
    WHERE iimb.item_no         = lv_item_code;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                             --*** 存在チェック例外 ***
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10034,  -- メッセージ：APP-XXCMN-10034 パラメータエラー：存在１
                            gv_tkn_para_name,   -- トークン：パラメータ名
                            gv_tkn_name_01,     -- トークン：品目コード
                            gv_tkn_table_name,  -- トークン：テーブル名
                            gv_tkn_name_08      -- トークン：OPM品目マスタ
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
  END get_item_id;
--
  /**********************************************************************************
   * Procedure Name   : get_lot_id
   * Description      : ロットID取得
   ***********************************************************************************/
  PROCEDURE get_lot_id(
    iv_lot_no           IN     VARCHAR,                 -- 入力パラメータ(ロットNo)
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'get_lot_id';            -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_lot_no               VARCHAR2(15)            := iv_lot_no;               -- ロットNo
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
    -- ***************************************
    -- ***           ロットNo取得          ***
    -- ***************************************
    SELECT ilm.lot_id
    INTO gv_lot_id
    FROM ic_lots_mst ilm
    WHERE ilm.lot_no        = lv_lot_no
    AND   ilm.item_id       = gv_item_id;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                             --*** 存在チェック例外 ***
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10034,  -- メッセージ：APP-XXCMN-10034 パラメータエラー：存在１
                            gv_tkn_para_name,   -- トークン：パラメータ名
                            gv_tkn_name_02,     -- トークン：ロットNo
                            gv_tkn_table_name,  -- トークン：テーブル名
                            gv_tkn_name_09      -- トークン：OPM品目マスタ
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
  END get_lot_id;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータチェック(A-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_item_code        IN     VARCHAR2,                -- 品目コード
    iv_lot_no           IN     VARCHAR2,                -- ロットNo
    iv_out_control      IN     VARCHAR2,                -- 出力制御
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'parameter_check';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_item_code            CONSTANT VARCHAR2(20)   := '品目コード';            -- パラメータ名：品目コード
    cv_lot_no               CONSTANT VARCHAR2(20)   := 'ロットNo';              -- パラメータ名：ロットNo
    cv_out_control          CONSTANT VARCHAR2(20)   := '出力制御';              -- パラメータ名：出力制御
--
    -- *** ローカル変数 ***
    lv_item_code            VARCHAR2(10)            := iv_item_code;            -- 品目コード
    lv_lot_no               VARCHAR2(10)            := iv_lot_no;               -- ロットNo
    lv_out_control          VARCHAR2(10)            := iv_out_control;          -- 出力制御
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
    -- ***************************************
    -- ***     必須チェック(品目コード)    ***
    -- ***************************************
    -- 
    IF (lv_item_code IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10033,  -- メッセージ：APP-XXCMN-10033 パラメータエラー：必須
                            gv_tkn_para_name,   -- トークン：パラメータ名
                            gv_tkn_name_01      -- パラメータ：品目コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE required_expt;
    END IF;
--
    -- ***************************************
    -- ***      必須チェック(ロットNo)     ***
    -- ***************************************
    -- 
    IF (lv_lot_no IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10033,  -- メッセージ：APP-XXCMN-10033 パラメータエラー：必須
                            gv_tkn_para_name,   -- トークン：パラメータ名
                            gv_tkn_name_02      -- パラメータ：ロットNo
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE required_expt;
    END IF;
--
    -- ***************************************
    -- ***      必須チェック(出力制御)     ***
    -- ***************************************
    -- 
    IF (lv_out_control IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10033,  -- メッセージ：APP-XXCMN-10033 パラメータエラー：必須
                            gv_tkn_para_name,   -- トークン：パラメータ名
                            gv_tkn_name_03      -- パラメータ：出力制御
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE required_expt;
    END IF;
--
    -- ***************************************
    -- ***           存在チェック          ***
    -- ***************************************
    -- 品目コードの存在チェック
    get_item_id(
      lv_item_code,       -- 入力パラメータ(品目コード)
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE not_exist_expt;
    END IF;
--
    -- ロットNoの存在チェック
    get_lot_id(
      lv_lot_no,          -- 入力パラメータ(ロットNo)
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE not_exist_expt;
    END IF;
--
    -- ***************************************
    -- ***          妥当性チェック         ***
    -- ***************************************
    -- 出力制御の妥当性チェック
    IF ( (lv_out_control <> gv_trace) AND (lv_out_control <> gv_trace_back) ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10035,  -- メッセージ：APP-XXCMN-10035 パラメータエラー：入力値
                            gv_tkn_para_name,   -- トークン：パラメータ名
                            gv_tkn_name_03,     -- トークン：出力制御
                            gv_tkn_para_value,  -- トークン：テーブル名
                            lv_out_control      -- パラメータ：出力制御
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE validate_expt;
    END IF;
--
    -- ***************************************
    -- ***         プロファイル取得        ***
    -- ***************************************
    -- プロファイル：保存期間の取得
    gn_keep_period := TO_NUMBER( FND_PROFILE.VALUE(gv_tkn_name_04) );
    -- 取得エラー時
    IF (gn_keep_period IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10002,  -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_profile,     -- トークン：NG_PROFILE
                            gv_tkn_name_05      -- 保存期間
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- プロファイル：組織IDの取得
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE(gv_tkn_name_06) );
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10002,  -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_profile,     -- トークン：NG_PROFILE
                            gv_tkn_name_07      -- 組織ID
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- WHOカラムの取得
    gn_created_by             :=  FND_GLOBAL.USER_ID;
    gd_creation_date          :=  SYSDATE;
    gn_last_update_by         :=  FND_GLOBAL.USER_ID;
    gd_last_update_date       :=  SYSDATE;
    gn_last_update_login      :=  FND_GLOBAL.LOGIN_ID;
    gn_request_id             :=  FND_GLOBAL.CONC_REQUEST_ID;
    gn_program_application_id :=  FND_GLOBAL.PROG_APPL_ID;
    gn_program_id             :=  FND_GLOBAL.CONC_PROGRAM_ID;
    gd_program_update_date    :=  SYSDATE;
--
  EXCEPTION
    WHEN required_expt THEN                             --*** パラメータ例外 ***
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    WHEN not_exist_expt THEN                            --*** パラメータ例外 ***
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    WHEN validate_expt THEN                             --*** パラメータ例外 ***
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    WHEN profile_expt THEN                              --*** プロファイル取得エラー ***
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : del_lot_trace
   * Description      : 登録対象テーブル削除(A-2)
   ***********************************************************************************/
  PROCEDURE del_lot_trace(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'del_lot_trace';         -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_tbl_name             CONSTANT VARCHAR2(50)   := 'ロットトレース';        -- テーブル名
--
    -- *** ローカル変数 ***
    ln_del_cont             NUMBER;                         -- 削除対象レコード件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_division             del_division;                   -- 区分
    lt_level_num            del_level_num;                  -- レベル番号
    lt_item_code            del_item_code;                  -- 品目コード
    lt_lot_num              del_lot_num;                    -- ロット番号
    lt_request_id           del_request_id;                 -- 要求ID
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
    -- ***   ロットトレースアドオン削除    ***
    -- ***************************************
    -- ロットトレースアドオン情報取得(削除対象レコード)
    SELECT xlt.division,                                                -- 区分
           xlt.level_num,                                               -- レベル番号
           xlt.item_code,                                               -- 親品目コード
           xlt.lot_num,                                                 -- 親ロットNo
           xlt.request_id                                               -- 要求ID
    BULK COLLECT INTO gt_del_lot_tbl
    FROM xxcmn_lot_trace xlt
    WHERE xlt.creation_date <= (TRUNC(SYSDATE) - gn_keep_period)
    FOR UPDATE NOWAIT;
--
    -- 対象レコード削除
    IF ( gt_del_lot_tbl IS NOT NULL ) THEN
      -- ループ処理にて、バルク取得したデータを項目単位のテーブル型へ移行
      -- 項目単位のテーブル型を使用して、対象レコードを削除する
      << del_loop >>
      FOR col_cnt IN 1 .. gt_del_lot_tbl.COUNT LOOP
        lt_division(col_cnt)    := gt_del_lot_tbl(col_cnt).division;
        lt_level_num(col_cnt)   := gt_del_lot_tbl(col_cnt).level_num;
        lt_item_code(col_cnt)   := gt_del_lot_tbl(col_cnt).item_code;
        lt_lot_num(col_cnt)     := gt_del_lot_tbl(col_cnt).lot_num;
        lt_request_id(col_cnt)  := gt_del_lot_tbl(col_cnt).request_id;
      END LOOP;
--
      FORALL del_cnt IN 1 .. lt_division.COUNT
        -- ロットトレース一括削除
        DELETE
        FROM xxcmn_lot_trace xlt
        WHERE division   = lt_division(del_cnt)
        AND   level_num  = lt_level_num(del_cnt)
        AND   item_code  = lt_item_code(del_cnt)
        AND   lot_num    = lt_lot_num(del_cnt)
        AND   request_id = lt_request_id(del_cnt);
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN                                 --*** ロック取得例外 ***
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10019,  -- メッセージ：APP-XXCMN-10019 ロックエラー
                            gv_tkn_table,       -- トークンTABLE
                            cv_tbl_name         -- テーブル名：ロットトレース
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
  END del_lot_trace;
--
  /**********************************************************************************
   * Procedure Name   : get_lots_data
   * Description      : ロット系統データ抽出(A-3/A-5/A-7/A-9/A-11)
   ***********************************************************************************/
  PROCEDURE get_lots_data(
    iv_item_id          IN     VARCHAR2,                -- 品目ID
    iv_lot_id           IN     VARCHAR2,                -- ロットID
    iv_batch_id         IN     VARCHAR2,                -- バッチID
    iv_out_control      IN     VARCHAR2,                -- 出力制御
    in_level_num        IN     NUMBER,                  -- 階層
    ot_itp_tbl          OUT    NOCOPY mst_itp_tbl,      -- 生産情報
    ot_rcv_tbl          OUT    NOCOPY mst_rcv_tbl,      -- 受入情報
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'get_lots_data';         -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_doc_type             CONSTANT VARCHAR2(4)    := 'PROD';                  -- 文書タイプ
    cv_comp_ind             CONSTANT VARCHAR2(1)    := '1';                     -- 完了インジケータ：完了
    cv_line_type_01         CONSTANT VARCHAR2(2)    := '1';                     -- 完成品
    cv_line_type_02         CONSTANT VARCHAR2(2)    := '2';                     -- 副産物
    cv_line_type_03         CONSTANT VARCHAR2(2)    := '-1';                    -- 投入品
    cv_batch_status         CONSTANT VARCHAR2(2)    := '-1';                    -- 取消
    cv_out_trace            CONSTANT VARCHAR2(1)    := '1';                     -- ロットトレース(原料へ)
    cv_out_back             CONSTANT VARCHAR2(1)    := '2';                     -- トレースバック(製品へ)
    cv_sql_dot              CONSTANT VARCHAR2(1)    := ',';                     -- カンマ
    cv_sql_l_block          CONSTANT VARCHAR2(1)    := '(';                     -- カッコ'('
    cv_sql_r_block          CONSTANT VARCHAR2(1)    := ')';                     -- カッコ')'
    -- *** ローカル変数 ***
    lv_sql_select_01        VARCHAR2(5000);                                     -- 生産系SELECT句(共通)
    lv_sql_select_02        VARCHAR2(1000);                                     -- 生産系SELECT句(トレース)
    lv_sql_select_03        VARCHAR2(1000);                                     -- 生産系SELECT句(トレースバック)
    lv_sql_from             VARCHAR2(1000);                                     -- 生産系FROM句(共通)
    lv_sql_01               VARCHAR2(6000);                                     -- 副問合せ(親品目ロットトレース)
    lv_sql_02               VARCHAR2(6000);                                     -- 副問合せ(子品目ロットトレース)
    lv_sql_03               VARCHAR2(6000);                                     -- 副問合せ(親品目トレースバック)
    lv_sql_04               VARCHAR2(6000);                                     -- 副問合せ(子品目トレースバック)
    lv_sql_par              VARCHAR2(100);                                      -- 別名(親)用SQL
    lv_sql_chi              VARCHAR2(100);                                      -- 別名(子)用SQL
    lv_sql_where_01         VARCHAR2(3000);                                     -- 生産系WHERE句(共通)
    lv_sql_where_02         VARCHAR2(3000);                                     -- 生産系WHERE句(共通)
--
    lv_sql_sel              VARCHAR2(8000);
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
    -- ***************************************
    -- ***      ロット系統データ抽出       ***
    -- ***************************************
    -- 生産系情報取得SQLの作成
--
    -- SELECT文(共通)定義
    lv_sql_select_01 := 'SELECT pp.item_id      p_item_id '
                     ||       ',pp.lot_id       p_lot_id '
                     ||       ',pp.batch_id     p_batch_id '
                     ||       ',pp.item_no      p_item_no '
                     ||       ',pp.item_name    p_item_name '
                     ||       ',pp.lot_no       p_lot_no '
                     ||       ',pp.whse_code    p_whse_code '
                     ||       ',cp.item_id      c_item_id '
                     ||       ',cp.lot_id       c_lot_id '
                     ||       ',cp.batch_id     c_batch_id '
                     ||       ',cp.item_no      c_item_no '
                     ||       ',cp.item_name    c_item_name '
                     ||       ',cp.lot_no       c_lot_no '
                     ||       ',ilm.attribute1  l_lot_date '
                     ||       ',ilm.attribute2  l_lot_sign '
                     ||       ',ilm.attribute3  l_best_bfr_date '
                     ||       ',ilm.attribute4  l_dlv_date_first '
                     ||       ',ilm.attribute5  l_dlv_date_last '
                     ||       ',ilm.attribute6  l_stock_ins_amount '
                     ||       ',ilm.attribute10 l_tea_period_dev '
                     ||       ',ilm.attribute11 l_product_year '
                     ||       ',ilm.attribute12 l_product_home '
                     ||       ',ilm.attribute13 l_product_type '
                     ||       ',ilm.attribute14 l_product_ranc_1 '
                     ||       ',ilm.attribute15 l_product_ranc_2 '
                     ||       ',ilm.attribute16 l_product_slip_dev '
                     ||       ',ilm.attribute18 l_description '
                     ||       ',ilm.attribute22 l_inspect_req ';
--
    -- SELECT文(ロットトレース)定義
    lv_sql_select_02 := ',pp.batch_no       l_batch_num '
                     || ',pp.attribute17    l_batch_date '
                     || ',pp.routing_no     l_line_num '
                     || ',pp.attribute11    l_turn_date '
                     || ',pp.turn_batch_no  l_turn_batch_num ';
--
    -- FROM句定義
    lv_sql_from := 'FROM ic_lots_mst ilm, ';
--
    -- 副問合せ(親品目ロットトレース)定義
    lv_sql_01 := 'SELECT itp.item_id '
              ||       ',itp.lot_id '
              ||       ',SUM( itp.trans_qty ) '
              ||       ',gbh.batch_id '
              ||       ',ximv.item_no '
              ||       ',ximv.item_name '
              ||       ',ilm.lot_no '
              ||       ',itp.whse_code '
              ||       ',gbh.batch_no batch_no'
              ||       ',gmd.attribute17 '
              ||       ',grb.routing_no '
              ||       ',bc.batch_no  turn_batch_no'
              ||       ',bc.attribute11 '
              || 'FROM  ic_tran_pnd          itp '
              ||      ',ic_lots_mst          ilm '
              ||      ',xxcmn_item_mst2_v    ximv'
              ||      ',gme_material_details gmd '
              ||      ',gme_batch_header     gbh '
              ||      ',gmd_routings_b       grb '
              ||      ',( SELECT itp.item_id '
              ||               ',itp.lot_id '
              ||               ',gbh.batch_id '
              ||               ',gbh.batch_no '
              ||               ',gmd.attribute11 '
              ||         'FROM ic_tran_pnd          itp '
              ||             ',gme_material_details gmd '
              ||             ',gme_batch_header     gbh '
              ||         'WHERE itp.doc_type      = :para_doc_type '
              ||         'AND   itp.completed_ind = :para_comp_ind '
              ||         'AND   itp.line_type    IN (:para_line_type_03) '
              ||         'AND   itp.doc_line      = gmd.line_no '
              ||         'AND   itp.doc_id        = gmd.batch_id '
              ||         'AND   itp.item_id       = gmd.item_id '
              ||         'AND   gmd.batch_id      = gbh.batch_id '
              ||         'GROUP BY itp.item_id '
              ||                 ',itp.lot_id '
              ||                 ',gbh.batch_id '
              ||                 ',gbh.batch_no '
              ||                 ',gmd.attribute11 '
              ||       ') bc '
              || 'WHERE  itp.doc_type            = :para_doc_type '
              || 'AND    itp.completed_ind       = :para_comp_ind '
              || 'AND    itp.line_type           IN (:para_line_type_01,:para_line_type_02) '
              || 'AND    itp.doc_line            = gmd.line_no '
              || 'AND    itp.doc_id              = gmd.batch_id '
              || 'AND    itp.item_id             = gmd.item_id '
              || 'AND    gmd.batch_id            = gbh.batch_id '
              || 'AND    gbh.formula_id          IS NOT NULL '
              || 'AND    itp.item_id             = ximv.item_id '
              || 'AND    itp.item_id             = ilm.item_id '
              || 'AND    itp.lot_id              = ilm.lot_id '
-- S 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ S --
              || 'AND    ilm.lot_id             <> 0'
-- E 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ E --
              || 'AND    itp.item_id             = bc.item_id(+) '
              || 'AND    itp.lot_id              = bc.lot_id(+) '
-- S 2008/05/27 1.1 DEL BY M.Ikeda ------------------------------------------------------------ S --
--              || 'AND    gbh.batch_id           <> bc.batch_id '
-- E 2008/05/27 1.1 DEL BY M.Ikeda ------------------------------------------------------------ E --
              || 'AND    gbh.routing_id          = grb.routing_id '
              || 'AND    ximv.start_date_active <= trunc(itp.last_update_date) '
              || 'AND    ximv.end_date_active   >= trunc(itp.last_update_date) '
              || 'AND    (( gbh.batch_status    <> :para_batch_status ) '
              || 'OR      ( gbh.attribute4      <> :para_batch_status )) '
              || 'GROUP BY itp.item_id '
              ||         ',itp.lot_id '
              ||         ',gbh.batch_id '
              ||         ',ximv.item_no '
              ||         ',ximv.item_name '
              ||         ',ilm.lot_no '
              ||         ',itp.whse_code '
              ||         ',gbh.batch_no '
              ||         ',gmd.attribute17 '
              ||         ',grb.routing_no '
              ||         ',bc.batch_no '
              ||         ',bc.attribute11 '
              || 'HAVING   SUM( itp.trans_qty ) <> 0 '
              || 'ORDER BY itp.item_id '
              ||         ',itp.lot_id ';
--
    -- 副問合せ(子品目ロットトレース)定義
    lv_sql_02 := 'SELECT itp.item_id '
              ||       ',itp.lot_id '
              ||       ',SUM( itp.trans_qty ) '
              ||       ',gbh.batch_id '
              ||       ',ximv.item_no '
              ||       ',ximv.item_name '
              ||       ',ilm.lot_no '
              || 'FROM   ic_tran_pnd          itp '
              ||       ',ic_lots_mst          ilm '
              ||       ',xxcmn_item_mst2_v    ximv'
              ||       ',gme_material_details gmd '
              ||       ',gme_batch_header     gbh '
              || 'WHERE  itp.doc_type            = :para_doc_type '
              || 'AND    itp.completed_ind       = :para_comp_ind '
              || 'AND    itp.line_type           IN (:para_line_type_03) '
              || 'AND    itp.doc_line            = gmd.line_no '
              || 'AND    itp.doc_id              = gmd.batch_id '
              || 'AND    itp.item_id             = gmd.item_id '
              || 'AND    gmd.batch_id            = gbh.batch_id '
              || 'AND    itp.item_id             = ximv.item_id '
              || 'AND    itp.item_id             = ilm.item_id '
              || 'AND    itp.lot_id              = ilm.lot_id '
-- S 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ S --
              || 'AND    ilm.lot_id             <> 0'
-- E 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ E --
              || 'AND    ximv.start_date_active <= trunc(itp.last_update_date) '
              || 'AND    ximv.end_date_active   >= trunc(itp.last_update_date) '
              || 'AND    (( gbh.batch_status    <> :para_batch_status ) '
              || 'OR      ( gbh.attribute4      <> :para_batch_status )) '
              || 'GROUP BY itp.item_id '
              ||         ',itp.lot_id '
              ||         ',gbh.batch_id '
              ||         ',ximv.item_no '
              ||         ',ximv.item_name '
              ||         ',ilm.lot_no '
              || 'HAVING   SUM( itp.trans_qty ) <> 0 '
              || 'ORDER BY itp.item_id '
              ||         ',itp.lot_id ';
--
    -- 副問合せ(親品目トレースバック)定義
    lv_sql_03 := 'SELECT itp.item_id '
              ||       ',itp.lot_id '
              ||       ',SUM( itp.trans_qty ) '
              ||       ',gbh.batch_id '
              ||       ',ximv.item_no '
              ||       ',ximv.item_name '
              ||       ',ilm.lot_no '
              ||       ',itp.whse_code '
              ||       ',bp.batch_no  batch_no'
              ||       ',bp.attribute17 '
              ||       ',grb.routing_no '
              ||       ',gbh.batch_no turn_batch_no'
              ||       ',gmd.attribute11 '
              || 'FROM  ic_tran_pnd          itp '
              ||      ',ic_lots_mst          ilm '
              ||      ',xxcmn_item_mst2_v    ximv'
              ||      ',gme_material_details gmd '
              ||      ',gme_batch_header     gbh '
              ||      ',gmd_routings_b       grb '
              ||      ',( SELECT itp.item_id '
              ||               ',itp.lot_id '
              ||               ',gbh.batch_id '
              ||               ',gbh.batch_no '
              ||               ',gmd.attribute17 '
              ||         'FROM ic_tran_pnd          itp '
              ||             ',gme_material_details gmd '
              ||             ',gme_batch_header     gbh '
              ||         'WHERE itp.doc_type      = :para_doc_type '
              ||         'AND   itp.completed_ind = :para_comp_ind '
              ||         'AND   itp.line_type    IN (:para_line_type_01,:para_line_type_02) '
              ||         'AND   itp.doc_line      = gmd.line_no '
              ||         'AND   itp.doc_id        = gmd.batch_id '
              ||         'AND   itp.item_id       = gmd.item_id '
              ||         'AND   gmd.batch_id      = gbh.batch_id '
              ||         'GROUP BY itp.item_id '
              ||                 ',itp.lot_id '
              ||                 ',gbh.batch_id '
              ||                 ',gbh.batch_no '
              ||                 ',gmd.attribute17 '
              ||       ') bp '
              || 'WHERE  itp.doc_type            = :para_doc_type '
              || 'AND    itp.completed_ind       = :para_comp_ind '
              || 'AND    itp.line_type           IN (:para_line_type_03) '
              || 'AND    itp.doc_line            = gmd.line_no '
              || 'AND    itp.doc_id              = gmd.batch_id '
              || 'AND    itp.item_id             = gmd.item_id '
              || 'AND    gmd.batch_id            = gbh.batch_id '
              || 'AND    itp.item_id             = ximv.item_id '
              || 'AND    itp.item_id             = ilm.item_id '
              || 'AND    itp.lot_id              = ilm.lot_id '
-- S 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ S --
              || 'AND    ilm.lot_id             <> 0'
-- E 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ E --
              || 'AND    itp.item_id             = bp.item_id(+) '
              || 'AND    itp.lot_id              = bp.lot_id(+) '
              || 'AND    gbh.routing_id          = grb.routing_id '
              || 'AND    ximv.start_date_active <= trunc(itp.last_update_date) '
              || 'AND    ximv.end_date_active   >= trunc(itp.last_update_date) '
              || 'AND    (( gbh.batch_status    <> :para_batch_status ) '
              || 'OR      ( gbh.attribute4      <> :para_batch_status )) '
              || 'GROUP BY itp.item_id '
              ||         ',itp.lot_id '
              ||         ',gbh.batch_id '
              ||         ',ximv.item_no '
              ||         ',ximv.item_name '
              ||         ',ilm.lot_no '
              ||         ',itp.whse_code '
              ||         ',bp.batch_no '
              ||         ',bp.attribute17 '
              ||         ',grb.routing_no '
              ||         ',gbh.batch_no '
              ||         ',gmd.attribute11 '
              || 'HAVING   SUM( itp.trans_qty ) <> 0 '
              || 'ORDER BY itp.item_id '
              ||         ',itp.lot_id ';
--
    -- 副問合せ(子品目トレースバック)定義
    lv_sql_04 := 'SELECT itp.item_id '
              ||       ',itp.lot_id '
              ||       ',SUM( itp.trans_qty ) '
              ||       ',gbh.batch_id '
              ||       ',ximv.item_no '
              ||       ',ximv.item_name '
              ||       ',ilm.lot_no '
              || 'FROM   ic_tran_pnd          itp '
              ||       ',ic_lots_mst          ilm '
              ||       ',xxcmn_item_mst2_v    ximv'
              ||       ',gme_material_details gmd '
              ||       ',gme_batch_header     gbh '
              || 'WHERE  itp.doc_type            = :para_doc_type '
              || 'AND    itp.completed_ind       = :para_comp_ind '
              || 'AND    itp.line_type           IN (:para_line_type_01,:para_line_type_02) '
              || 'AND    itp.doc_line            = gmd.line_no '
              || 'AND    itp.doc_id              = gmd.batch_id '
              || 'AND    itp.item_id             = gmd.item_id '
              || 'AND    gmd.batch_id            = gbh.batch_id '
              || 'AND    gbh.formula_id          IS NOT NULL '
              || 'AND    itp.item_id             = ximv.item_id '
              || 'AND    itp.item_id             = ilm.item_id '
              || 'AND    itp.lot_id              = ilm.lot_id '
-- S 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ S --
              || 'AND    ilm.lot_id             <> 0'
-- E 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ E --
              || 'AND    ximv.start_date_active <= trunc(itp.last_update_date) '
              || 'AND    ximv.end_date_active   >= trunc(itp.last_update_date) '
              || 'AND    (( gbh.batch_status    <> :para_batch_status ) '
              || 'OR      ( gbh.attribute4      <> :para_batch_status )) '
              || 'GROUP BY itp.item_id '
              ||         ',itp.lot_id '
              ||         ',gbh.batch_id '
              ||         ',ximv.item_no '
              ||         ',ximv.item_name '
              ||         ',ilm.lot_no '
              || 'HAVING   SUM( itp.trans_qty ) <> 0 '
              || 'ORDER BY itp.item_id '
              ||         ',itp.lot_id ';
--
    -- 別名(親)
    lv_sql_par  := ' pp ';
--
    -- 別名(子)
    lv_sql_chi  := ' cp ';
--
    -- WHERE句(定義)定義
    lv_sql_where_01 := 'WHERE pp.batch_id    = cp.batch_id(+) '
                    || 'AND   pp.lot_id     <> cp.lot_id(+) '
                    || 'AND   pp.lot_id      = ilm.lot_id '
                    || 'AND   pp.item_id     = ilm.item_id '
                    || 'AND   cp.item_id     IS NOT NULL '
                    || 'AND   pp.item_id     = :para_item_id '
                    || 'AND   pp.lot_id      = :para_lot_id ';
--
    IF ( iv_batch_id IS NOT NULL ) THEN
      lv_sql_where_01 := lv_sql_where_01 
                    || 'AND   pp.batch_id    > ' || iv_batch_id || ' ';
    END IF;
--
    -- WHERE句(定義)定義
    lv_sql_where_02 := 'WHERE pp.batch_id    = cp.batch_id(+) '
                    || 'AND   pp.lot_id     <> cp.lot_id(+) '
                    || 'AND   pp.lot_id      = ilm.lot_id '
                    || 'AND   pp.item_id     = ilm.item_id '
                    || 'AND   cp.item_id     IS NOT NULL '
                    || 'AND   pp.item_id     = :para_item_id '
                    || 'AND   pp.lot_id      = :para_lot_id ';
--
    IF ( iv_batch_id IS NOT NULL ) THEN
      lv_sql_where_02 := lv_sql_where_02 
                    || 'AND   pp.batch_id    < ' || iv_batch_id || ' ';
    END IF;
--
    -- 出力制御(1：ロットトレース)
    IF ( iv_out_control = cv_out_trace ) THEN
--
      lv_sql_sel := '';
      lv_sql_sel := lv_sql_sel || lv_sql_select_01 || lv_sql_select_02 || lv_sql_from || cv_sql_l_block;
      lv_sql_sel := lv_sql_sel || lv_sql_01        || cv_sql_r_block   || lv_sql_par  || cv_sql_dot || cv_sql_l_block;
      lv_sql_sel := lv_sql_sel || lv_sql_02        || cv_sql_r_block   || lv_sql_chi  || lv_sql_where_01;
--
      EXECUTE IMMEDIATE lv_sql_sel BULK COLLECT INTO ot_itp_tbl USING cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_03
                                                                     ,cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_01
                                                                     ,cv_line_type_02
                                                                     ,cv_batch_status
                                                                     ,cv_batch_status
                                                                     ,cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_03
                                                                     ,cv_batch_status
                                                                     ,cv_batch_status
                                                                     ,iv_item_id
                                                                     ,iv_lot_id;
--
    -- 出力制御(2：ロットトレースバック)
    ELSIF ( iv_out_control = cv_out_back ) THEN
--
      lv_sql_sel := '';
      lv_sql_sel := lv_sql_sel || lv_sql_select_01 || lv_sql_select_02 || lv_sql_from || cv_sql_l_block;
      lv_sql_sel := lv_sql_sel || lv_sql_03        || cv_sql_r_block   || lv_sql_par  || cv_sql_dot || cv_sql_l_block;
      lv_sql_sel := lv_sql_sel || lv_sql_04        || cv_sql_r_block   || lv_sql_chi  || lv_sql_where_02;
--
      EXECUTE IMMEDIATE lv_sql_sel BULK COLLECT INTO ot_itp_tbl USING cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_01
                                                                     ,cv_line_type_02
                                                                     ,cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_03
                                                                     ,cv_batch_status
                                                                     ,cv_batch_status
                                                                     ,cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_01
                                                                     ,cv_line_type_02
                                                                     ,cv_batch_status
                                                                     ,cv_batch_status
                                                                     ,iv_item_id
                                                                     ,iv_lot_id;
--
    END IF;
--
    -- 生産系情報の取得チェック
    -- 子品目情報の在庫情報が存在しない場合、受入情報を取得
    SELECT itp.item_id
          ,ilm.lot_id
          ,ximv.item_no
          ,ximv.item_name
          ,ilm.lot_no
          ,itp.whse_code
          ,rct.transaction_date
          ,rsh.receipt_num
          ,pha.segment1
          ,ven1.supp_name
          ,ven1.segment1
          ,ven2.trader_name
          ,ilm.attribute1
          ,ilm.attribute2
          ,ilm.attribute3
          ,ilm.attribute4
          ,ilm.attribute5
          ,ilm.attribute6
          ,ilm.attribute10
          ,ilm.attribute11
          ,ilm.attribute12
          ,ilm.attribute13
          ,ilm.attribute14
          ,ilm.attribute15
          ,ilm.attribute16
          ,ilm.attribute18
          ,ilm.attribute22
    BULK COLLECT INTO ot_rcv_tbl
    FROM   ic_tran_pnd          itp
          ,xxcmn_item_mst2_v    ximv
          ,ic_lots_mst          ilm
          ,rcv_shipment_headers rsh
          ,rcv_shipment_lines   rsl
          ,rcv_transactions     rct
          ,po_headers_all       pha
          ,( SELECT xpv1.segment1
                   ,xpv1.vendor_name supp_name
                   ,xpv1.vendor_id   supp_id
             FROM   po_headers_all   pha
                   ,xxcmn_vendors2_v xpv1
             WHERE  pha.vendor_id    = xpv1.vendor_id
             GROUP BY xpv1.segment1
                     ,xpv1.vendor_name
                     ,xpv1.vendor_id
           ) ven1
          ,( SELECT xpv2.vendor_name trader_name
                   ,xpv2.vendor_id   trader_id
             FROM   po_headers_all   pha
                   ,xxcmn_vendors2_v xpv2
             WHERE  pha.attribute3   = xpv2.vendor_id
             GROUP BY xpv2.vendor_name
                     ,xpv2.vendor_id
           ) ven2
    WHERE itp.item_id             = iv_item_id
    AND   itp.lot_id              = iv_lot_id
    AND   itp.item_id             = ximv.item_id
    AND   itp.item_id             = ilm.item_id
    AND   itp.lot_id              = ilm.lot_id
-- S 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ S --
    AND   ilm.lot_id             <> 0
-- E 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ E --
    AND   itp.doc_line            = rsl.line_num
    AND   itp.doc_id              = rsl.shipment_header_id
    AND   rsl.shipment_header_id  = rct.shipment_header_id
    AND   rsl.shipment_line_id    = rct.shipment_line_id
    AND   rsl.shipment_header_id  = rsh.shipment_header_id
    AND   rct.transaction_type    = gv_rcv_tran_type
    AND   rsl.po_header_id        = pha.po_header_id
    AND   ximv.start_date_active <= trunc(itp.last_update_date)
    AND   ximv.end_date_active   >= trunc(itp.last_update_date)
    AND   pha.vendor_id           = ven1.supp_id(+)
    AND   pha.attribute3          = ven2.trader_id(+)
    AND   pha.org_id              = gn_org_id;
--
    IF ( (ot_itp_tbl.COUNT = 0) AND (ot_rcv_tbl.COUNT = 0) ) THEN
      RAISE NO_DATA_FOUND;
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_warn;
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
  END get_lots_data;
--
  /**********************************************************************************
   * Procedure Name   : put_lots_data
   * Description      : ロット系統データ格納(A-4/A-6/A-8/A-10/A-12)
   ***********************************************************************************/
  PROCEDURE put_lots_data(
    in_total_cnt        IN OUT NOCOPY NUMBER,           -- 処理件数
    in_cnt              IN     NUMBER,                  -- ループカウント
    iv_out_control      IN     VARCHAR2,                -- 出力制御
    in_level_num        IN     NUMBER,                  -- 階層
    it_itp_tbl          IN     mst_itp_tbl,             -- 生産情報
    it_rcv_tbl          IN     mst_rcv_tbl,             -- 受入情報
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'put_lots_data';         -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_rcv_cnt              NUMBER                  := 0;                       -- 受入処理カウント
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
    -- ***************************************
    -- ***      ロット系統データ格納       ***
    -- ***************************************
    -- 処理件数のカウントアップ
    in_total_cnt := in_total_cnt + 1;
    -- 区分
    gt_division(in_total_cnt) := iv_out_control;
    -- レベル番号
    gt_level_num(in_total_cnt) := in_level_num;
--
    -- 生産系情報の格納
    IF ((it_itp_tbl.COUNT > 0) AND (it_itp_tbl.COUNT >= in_cnt)) THEN
      gt_item_code(in_total_cnt)        := NVL(it_itp_tbl(in_cnt).p_item_no,'');
      gt_item_name(in_total_cnt)        := NVL(it_itp_tbl(in_cnt).p_item_name,'');
      gt_lot_num(in_total_cnt)          := NVL(it_itp_tbl(in_cnt).p_lot_no,'');
      gt_trace_item_code(in_total_cnt)  := NVL(it_itp_tbl(in_cnt).c_item_no,'');
      gt_trace_item_name(in_total_cnt)  := NVL(it_itp_tbl(in_cnt).c_item_name,'');
      gt_trace_lot_num(in_total_cnt)    := NVL(it_itp_tbl(in_cnt).c_lot_no,'');
      gt_batch_num(in_total_cnt)        := NVL(it_itp_tbl(in_cnt).batch_num,'');
      gt_batch_date(in_total_cnt)       := NVL(it_itp_tbl(in_cnt).batch_date,'');
      gt_whse_code(in_total_cnt)        := NVL(it_itp_tbl(in_cnt).p_whse_code,'');
      gt_line_num(in_total_cnt)         := NVL(it_itp_tbl(in_cnt).line_num,'');
      gt_turn_date(in_total_cnt)        := NVL(it_itp_tbl(in_cnt).turn_date,'');
      gt_turn_batch_num(in_total_cnt)   := NVL(it_itp_tbl(in_cnt).turn_batch_num,'');
      gt_receipt_date(in_total_cnt)     := '';
      gt_receipt_num(in_total_cnt)      := '';
      gt_order_num(in_total_cnt)        := '';
      gt_supp_name(in_total_cnt)        := '';
      gt_supp_code(in_total_cnt)        := '';
      gt_trader_name(in_total_cnt)      := '';
      gt_lot_date(in_total_cnt)         := NVL(it_itp_tbl(in_cnt).lot_date,'');
      gt_lot_sign(in_total_cnt)         := NVL(it_itp_tbl(in_cnt).lot_sign,'');
      gt_best_bfr_date(in_total_cnt)    := NVL(it_itp_tbl(in_cnt).best_bfr_date,'');
      gt_dlv_date_first(in_total_cnt)   := NVL(it_itp_tbl(in_cnt).dlv_date_first,'');
      gt_dlv_date_last(in_total_cnt)    := NVL(it_itp_tbl(in_cnt).dlv_date_last,'');
      gt_stock_ins_amount(in_total_cnt) := NVL(it_itp_tbl(in_cnt).stock_ins_amount,'');
      gt_tea_period_dev(in_total_cnt)   := NVL(it_itp_tbl(in_cnt).tea_period_dev,'');
      gt_product_year(in_total_cnt)     := NVL(it_itp_tbl(in_cnt).product_year,'');
      gt_product_home(in_total_cnt)     := NVL(it_itp_tbl(in_cnt).product_home,'');
      gt_product_type(in_total_cnt)     := NVL(it_itp_tbl(in_cnt).product_type,'');
      gt_product_ranc_1(in_total_cnt)   := NVL(it_itp_tbl(in_cnt).product_ranc_1,'');
      gt_product_ranc_2(in_total_cnt)   := NVL(it_itp_tbl(in_cnt).product_ranc_2,'');
      gt_product_slip_dev(in_total_cnt) := NVL(it_itp_tbl(in_cnt).product_slip_dev,'');
      gt_description(in_total_cnt)      := NVL(it_itp_tbl(in_cnt).description,'');
      gt_inspect_req(in_total_cnt)      := NVL(it_itp_tbl(in_cnt).inspect_req,'');

      -- WHOカラムの格納
      gt_created_by(in_total_cnt)             := gn_created_by;
      gt_creation_date(in_total_cnt)          := gd_creation_date;
      gt_last_updated_by(in_total_cnt)        := gn_last_update_by;
      gt_last_update_date(in_total_cnt)       := gd_last_update_date;
      gt_last_update_login(in_total_cnt)      := gn_last_update_login;
      gt_request_id(in_total_cnt)             := gn_request_id;
      gt_program_id(in_total_cnt)             := gn_program_id;
      gt_program_application_id(in_total_cnt) := gn_program_application_id;
      gt_program_update_date(in_total_cnt)    := gd_program_update_date;
--
    ELSIF (it_rcv_tbl.COUNT > 0) THEN
      -- 受入処理件数
      ln_rcv_cnt := in_cnt - it_itp_tbl.COUNT;
--
      -- 受入系情報の格納
      gt_item_code(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).p_item_no,'');
      gt_item_name(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).p_item_name,'');
      gt_lot_num(in_total_cnt)          := NVL(it_rcv_tbl(ln_rcv_cnt).p_lot_no,'');
      gt_trace_item_code(in_total_cnt)  := '';
      gt_trace_item_name(in_total_cnt)  := '';
      gt_trace_lot_num(in_total_cnt)    := '';
      gt_batch_num(in_total_cnt)        := '';
      gt_batch_date(in_total_cnt)       := '';
      gt_whse_code(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).whse_code,'');
      gt_line_num(in_total_cnt)         := '';
      gt_turn_date(in_total_cnt)        := '';
      gt_turn_batch_num(in_total_cnt)   := '';
      gt_receipt_date(in_total_cnt)     := NVL(it_rcv_tbl(ln_rcv_cnt).receipt_date,'');
      gt_receipt_num(in_total_cnt)      := NVL(it_rcv_tbl(ln_rcv_cnt).receipt_num,'');
      gt_order_num(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).order_num,'');
      gt_supp_name(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).supp_name,'');
      gt_supp_code(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).supp_code,'');
      gt_trader_name(in_total_cnt)      := NVL(it_rcv_tbl(ln_rcv_cnt).trader_name,'');
      gt_lot_date(in_total_cnt)         := NVL(it_rcv_tbl(ln_rcv_cnt).lot_date,'');
      gt_lot_sign(in_total_cnt)         := NVL(it_rcv_tbl(ln_rcv_cnt).lot_sign,'');
      gt_best_bfr_date(in_total_cnt)    := NVL(it_rcv_tbl(ln_rcv_cnt).best_bfr_date,'');
      gt_dlv_date_first(in_total_cnt)   := NVL(it_rcv_tbl(ln_rcv_cnt).dlv_date_first,'');
      gt_dlv_date_last(in_total_cnt)    := NVL(it_rcv_tbl(ln_rcv_cnt).dlv_date_last,'');
      gt_stock_ins_amount(in_total_cnt) := NVL(it_rcv_tbl(ln_rcv_cnt).stock_ins_amount,'');
      gt_tea_period_dev(in_total_cnt)   := NVL(it_rcv_tbl(ln_rcv_cnt).tea_period_dev,'');
      gt_product_year(in_total_cnt)     := NVL(it_rcv_tbl(ln_rcv_cnt).product_year,'');
      gt_product_home(in_total_cnt)     := NVL(it_rcv_tbl(ln_rcv_cnt).product_home,'');
      gt_product_type(in_total_cnt)     := NVL(it_rcv_tbl(ln_rcv_cnt).product_type,'');
      gt_product_ranc_1(in_total_cnt)   := NVL(it_rcv_tbl(ln_rcv_cnt).product_ranc_1,'');
      gt_product_ranc_2(in_total_cnt)   := NVL(it_rcv_tbl(ln_rcv_cnt).product_ranc_2,'');
      gt_product_slip_dev(in_total_cnt) := NVL(it_rcv_tbl(ln_rcv_cnt).product_slip_dev,'');
      gt_description(in_total_cnt)      := NVL(it_rcv_tbl(ln_rcv_cnt).description,'');
      gt_inspect_req(in_total_cnt)      := NVL(it_rcv_tbl(ln_rcv_cnt).inspect_req,'');
--
      -- WHOカラムの格納
      gt_created_by(in_total_cnt)             := gn_created_by;
      gt_creation_date(in_total_cnt)          := gd_creation_date;
      gt_last_updated_by(in_total_cnt)        := gn_last_update_by;
      gt_last_update_date(in_total_cnt)       := gd_last_update_date;
      gt_last_update_login(in_total_cnt)      := gn_last_update_login;
      gt_request_id(in_total_cnt)             := gn_request_id;
      gt_program_id(in_total_cnt)             := gn_program_id;
      gt_program_application_id(in_total_cnt) := gn_program_application_id;
      gt_program_update_date(in_total_cnt)    := gd_program_update_date;
--
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END put_lots_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_lots_data
   * Description      : ロット系統データ一括登録(A-13)
   ***********************************************************************************/
  PROCEDURE insert_lots_data(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'insert_lots_data';      -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        品目マスタ一括更新       ***
    -- ***************************************
      FORALL itp_cnt IN 1 .. gt_division.COUNT
        -- ロットトレースアドオン一括登録
        INSERT INTO xxcmn_lot_trace
          ( division
           ,level_num
           ,item_code
           ,item_name
           ,lot_num
           ,trace_item_code
           ,trace_item_name
           ,trace_lot_num
           ,batch_num
           ,batch_date
           ,whse_code
           ,line_num
           ,turn_date
           ,turn_batch_num
           ,receipt_date
           ,receipt_num
           ,order_num
           ,supp_name
           ,supp_code
           ,trader_name
           ,lot_date
           ,lot_sign
           ,best_bfr_date
           ,dlv_date_first
           ,dlv_date_last
           ,stock_ins_amount
           ,tea_period_dev
           ,product_year
           ,product_home
           ,product_type
           ,product_ranc_1
           ,product_ranc_2
           ,product_slip_dev
           ,description
           ,inspect_req
           ,created_by
           ,creation_date
           ,last_updated_by
           ,last_update_date
           ,last_update_login
           ,request_id
           ,program_application_id
           ,program_id
           ,program_update_date
        )
        VALUES
        (
          gt_division(itp_cnt)
         ,gt_level_num(itp_cnt)
         ,gt_item_code(itp_cnt)
         ,gt_item_name(itp_cnt)
         ,gt_lot_num(itp_cnt)
         ,gt_trace_item_code(itp_cnt)
         ,gt_trace_item_name(itp_cnt)
         ,gt_trace_lot_num(itp_cnt)
         ,gt_batch_num(itp_cnt)
         ,FND_DATE.STRING_TO_DATE(gt_batch_date(itp_cnt),'YYYY/MM/DD')
         ,gt_whse_code(itp_cnt)
         ,gt_line_num(itp_cnt)
         ,FND_DATE.STRING_TO_DATE(gt_turn_date(itp_cnt),'YYYY/MM/DD')
         ,gt_turn_batch_num(itp_cnt)
         ,gt_receipt_date(itp_cnt)
         ,gt_receipt_num(itp_cnt)
         ,gt_order_num(itp_cnt)
         ,gt_supp_name(itp_cnt)
         ,gt_supp_code(itp_cnt)
         ,gt_trader_name(itp_cnt)
         ,FND_DATE.STRING_TO_DATE(gt_lot_date(itp_cnt),'YYYY/MM/DD')
         ,gt_lot_sign(itp_cnt)
         ,FND_DATE.STRING_TO_DATE(gt_best_bfr_date(itp_cnt),'YYYY/MM/DD')
         ,FND_DATE.STRING_TO_DATE(gt_dlv_date_first(itp_cnt),'YYYY/MM/DD')
         ,FND_DATE.STRING_TO_DATE(gt_dlv_date_last(itp_cnt),'YYYY/MM/DD')
         ,gt_stock_ins_amount(itp_cnt)
         ,gt_tea_period_dev(itp_cnt)
         ,gt_product_year(itp_cnt)
         ,gt_product_home(itp_cnt)
         ,gt_product_type(itp_cnt)
         ,gt_product_ranc_1(itp_cnt)
         ,gt_product_ranc_2(itp_cnt)
         ,gt_product_slip_dev(itp_cnt)
         ,gt_description(itp_cnt)
         ,gt_inspect_req(itp_cnt)
         ,gt_created_by(itp_cnt)
         ,gt_creation_date(itp_cnt)
         ,gt_last_updated_by(itp_cnt)
         ,gt_last_update_date(itp_cnt)
         ,gt_last_update_login(itp_cnt)
         ,gt_request_id(itp_cnt)
         ,gt_program_id(itp_cnt)
         ,gt_program_application_id(itp_cnt)
         ,gt_program_update_date(itp_cnt)
        );
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END insert_lots_data;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : 処理結果レポート出力
   ***********************************************************************************/
  PROCEDURE disp_report(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'disp_report';           -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_dspbuf               VARCHAR2(5000);                                     -- エラー・メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 処理結果レポートの出力
    <<disp_report_loop>>
    FOR report_cnt IN 1 .. gt_division.COUNT
    LOOP
--
      --入力データダンプ出力
      -- 品目関連情報
      lv_dspbuf := '';
      lv_dspbuf := gt_division(report_cnt)                                || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_level_num(report_cnt)                  || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_item_code(report_cnt)                  || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_item_name(report_cnt)                  || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_lot_num(report_cnt)                    || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_trace_item_code(report_cnt)            || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_trace_item_name(report_cnt)            || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_trace_lot_num(report_cnt)              || gv_msg_pnt;
--
      -- 生産系情報
      lv_dspbuf := lv_dspbuf || gt_batch_num(report_cnt)  || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_batch_date(report_cnt) || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_whse_code(report_cnt)  || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_line_num(report_cnt)   || gv_msg_pnt;
--
      -- 受入系情報
      lv_dspbuf := lv_dspbuf || gt_turn_date(report_cnt)      || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_turn_batch_num(report_cnt) || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || TO_CHAR(gt_receipt_date(report_cnt),'YYYY/MM/DD')   || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_receipt_num(report_cnt)    || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_order_num(report_cnt)      || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_supp_name(report_cnt)      || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_supp_code(report_cnt)      || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_trader_name(report_cnt)    || gv_msg_pnt;
--
      -- OPMロット情報
      lv_dspbuf := lv_dspbuf || gt_lot_date(report_cnt)         || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_lot_sign(report_cnt)         || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_best_bfr_date(report_cnt)    || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || TO_CHAR(FND_DATE.STRING_TO_DATE(gt_dlv_date_first(report_cnt),'YYYY/MM/DD'),'YYYY/MM/DD')   || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || TO_CHAR(FND_DATE.STRING_TO_DATE(gt_dlv_date_last(report_cnt),'YYYY/MM/DD'),'YYYY/MM/DD')    || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_stock_ins_amount(report_cnt) || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_tea_period_dev(report_cnt)   || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_year(report_cnt)     || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_home(report_cnt)     || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_type(report_cnt)     || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_ranc_1(report_cnt)   || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_ranc_2(report_cnt)   || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_slip_dev(report_cnt) || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_description(report_cnt)      || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_inspect_req(report_cnt)      || gv_msg_pnt;
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
    END LOOP disp_report_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_item_code        IN     VARCHAR2,                -- 品目コード
    iv_lot_no           IN     VARCHAR2,                -- ロットNo
    iv_out_control      IN     VARCHAR2,                -- 出力制御
    ov_errbuf           OUT    VARCHAR2,                -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    VARCHAR2,                -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    VARCHAR2)                -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submain';               -- プログラム名
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
    cv_item_code            CONSTANT VARCHAR2(20)   := '品目コード';            -- パラメータ名：品目コード
    cv_lot_no               CONSTANT VARCHAR2(20)   := 'ロットNo';              -- パラメータ名：ロットNo
    cv_out_control          CONSTANT VARCHAR2(20)   := '出力制御';              -- パラメータ名：出力制御
--
    -- *** ローカル変数 ***
    -- パラメータ情報
    lv_item_code            VARCHAR2(30)            := iv_item_code;            -- 品目コード
    lv_lot_no               VARCHAR2(30)            := iv_lot_no;               -- ロットNo
    lv_out_control          VARCHAR2(30)            := iv_out_control;          -- 出力制御
--
    -- ループカウント(階層)
    ln_cnt_01               NUMBER                  := 0;                       -- 第一階層カウント
    ln_cnt_02               NUMBER                  := 0;                       -- 第二階層カウント
    ln_cnt_03               NUMBER                  := 0;                       -- 第三階層カウント
    ln_cnt_04               NUMBER                  := 0;                       -- 第四階層カウント
    ln_cnt_05               NUMBER                  := 0;                       -- 第五階層カウント
    ln_total_01             NUMBER                  := 0;                       -- 処理件数
    ln_loop_cnt_01          NUMBER                  := 0;                       -- ループ(第一階層)
    ln_loop_cnt_02          NUMBER                  := 0;                       -- ループ(第二階層)
    ln_loop_cnt_03          NUMBER                  := 0;                       -- ループ(第三階層)
    ln_loop_cnt_04          NUMBER                  := 0;                       -- ループ(第四階層)
    ln_loop_cnt_05          NUMBER                  := 0;                       -- ループ(第五階層)
--
    -- 階層毎のパラメータ
    lv_item_id_01           VARCHAR2(30);                                       -- 品目ID(第一階層)
    lv_item_id_02           VARCHAR2(30);                                       -- 品目ID(第二階層)
    lv_item_id_03           VARCHAR2(30);                                       -- 品目ID(第三階層)
    lv_item_id_04           VARCHAR2(30);                                       -- 品目ID(第四階層)
    lv_item_id_05           VARCHAR2(30);                                       -- 品目ID(第五階層)
    lv_lot_id_01            VARCHAR2(30);                                       -- ロットID(第一階層)
    lv_lot_id_02            VARCHAR2(30);                                       -- ロットID(第二階層)
    lv_lot_id_03            VARCHAR2(30);                                       -- ロットID(第三階層)
    lv_lot_id_04            VARCHAR2(30);                                       -- ロットID(第四階層)
    lv_lot_id_05            VARCHAR2(30);                                       -- ロットID(第五階層)
    lv_batch_id_02          VARCHAR2(30);                                       -- バッチID(第二階層)
    lv_batch_id_03          VARCHAR2(30);                                       -- バッチID(第三階層)
    lv_batch_id_04          VARCHAR2(30);                                       -- バッチID(第四階層)
    lv_batch_id_05          VARCHAR2(30);                                       -- バッチID(第五階層)
    lv_level_num_01         NUMBER                  := 1;                       -- 階層(第一階層)
    lv_level_num_02         NUMBER                  := 2;                       -- 階層(第二階層)
    lv_level_num_03         NUMBER                  := 3;                       -- 階層(第三階層)
    lv_level_num_04         NUMBER                  := 4;                       -- 階層(第四階層)
    lv_level_num_05         NUMBER                  := 5;                       -- 階層(第五階層)
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;

    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ================================
    -- A-1.パラメータチェック
    -- ================================
    parameter_check(
      lv_item_code,       -- 品目コード
      lv_lot_no,          -- ロットNo
      lv_out_control,     -- 出力制御
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-2.登録対象テーブル削除
    -- ================================
    del_lot_trace(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-3.第一階層ロット系統データ抽出
    -- ================================
--
    -- 引数設定
    lv_item_id_01 := gv_item_id;
    lv_lot_id_01  := gv_lot_id;
--
    get_lots_data(
      lv_item_id_01,      -- 品目ID
      lv_lot_id_01,       -- ロットID
      NULL,               -- バッチID
      lv_out_control,     -- 出力制御
      lv_level_num_01,    -- 階層
      gt_itp01_tbl,       -- 生産情報(第一階層)
      gt_rcv01_tbl,       -- 受入情報(第一階層)
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 取得件数が１件以上存在する場合のみ、以後の処理を実施
    IF (lv_retcode = gv_status_normal) THEN
--
      -- 処理件数
      ln_loop_cnt_01 := gt_itp01_tbl.COUNT + gt_rcv01_tbl.COUNT;
--
      << lot_trace_loop_01 >>
      FOR ln_cnt_01 IN 1..ln_loop_cnt_01 LOOP
        -- ================================
        -- A-4.第一階層ロット系統データ格納
        -- ================================
        -- ループカウント(第一階層分)
        put_lots_data(
          ln_total_01,        -- 処理件数
          ln_cnt_01,          -- ループカウント(第一階層)
          lv_out_control,     -- 出力制御
          lv_level_num_01,    -- 階層
          gt_itp01_tbl,       -- 生産情報(第一階層)
          gt_rcv01_tbl,       -- 受入情報(第一階層)
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 第一階層の子品目を親品目へ置換え
        IF ((gt_itp01_tbl.COUNT > 0) AND (gt_itp01_tbl.COUNT >= ln_cnt_01)) THEN
          IF (gt_itp01_tbl(ln_cnt_01).c_item_no IS NOT NULL) THEN
            lv_item_id_02  := gt_itp01_tbl(ln_cnt_01).c_item_id;
            lv_lot_id_02   := gt_itp01_tbl(ln_cnt_01).c_lot_id;
            lv_batch_id_02 := gt_itp01_tbl(ln_cnt_01).p_batch_id;
--
            -- ================================
            -- A-5.第二階層ロット系統データ抽出
            -- ================================
            get_lots_data(
              lv_item_id_02,      -- 品目ID
              lv_lot_id_02,       -- ロットID
              lv_batch_id_02,     -- バッチID
              lv_out_control,     -- 出力制御
              lv_level_num_02,    -- 階層
              gt_itp02_tbl,       -- 生産情報(第二階層)
              gt_rcv02_tbl,       -- 受入情報(第二階層)
              lv_errbuf,          -- エラー・メッセージ           --# 固定 #
              lv_retcode,         -- リターン・コード             --# 固定 #
              lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- 処理件数
            ln_loop_cnt_02 := gt_itp02_tbl.COUNT + gt_rcv02_tbl.COUNT;
--
            << lot_trace_loop_02 >>
            FOR ln_cnt_02 IN 1..ln_loop_cnt_02 LOOP
              -- ================================
              -- A-6.第二階層ロット系統データ格納
              -- ================================
              -- ループカウント(第二階層分)
              put_lots_data(
                ln_total_01,        -- 処理件数
                ln_cnt_02,          -- ループカウント(第二階層)
                lv_out_control,     -- 出力制御
                lv_level_num_02,    -- 階層
                gt_itp02_tbl,       -- 生産情報(第二階層)
                gt_rcv02_tbl,       -- 受入情報(第二階層)
                lv_errbuf,          -- エラー・メッセージ           --# 固定 #
                lv_retcode,         -- リターン・コード             --# 固定 #
                lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- 第二階層の子品目を親品目へ置換え
              IF ((gt_itp02_tbl.COUNT > 0) AND (gt_itp02_tbl.COUNT >= ln_cnt_02)) THEN
                IF (gt_itp02_tbl(ln_cnt_02).c_item_no IS NOT NULL) THEN
                  lv_item_id_03  := gt_itp02_tbl(ln_cnt_02).c_item_id;
                  lv_lot_id_03   := gt_itp02_tbl(ln_cnt_02).c_lot_id;
                  lv_batch_id_03 := gt_itp02_tbl(ln_cnt_02).p_batch_id;
--
                  -- ================================
                  -- A-7.第三階層ロット系統データ抽出
                  -- ================================
                  get_lots_data(
                    lv_item_id_03,      -- 品目ID
                    lv_lot_id_03,       -- ロットID
                    lv_batch_id_03,     -- バッチID
                    lv_out_control,     -- 出力制御
                    lv_level_num_03,    -- 階層
                    gt_itp03_tbl,       -- 生産情報(第三階層)
                    gt_rcv03_tbl,       -- 受入情報(第三階層)
                    lv_errbuf,          -- エラー・メッセージ           --# 固定 #
                    lv_retcode,         -- リターン・コード             --# 固定 #
                    lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
--
                  -- 処理件数
                  ln_loop_cnt_03 := gt_itp03_tbl.COUNT + gt_rcv03_tbl.COUNT;
--
                  << lot_trace_loop_03 >>
                  FOR ln_cnt_03 IN 1..ln_loop_cnt_03 LOOP
                    -- ================================
                    -- A-8.第三階層ロット系統データ格納
                    -- ================================
                    -- ループカウント(第三階層分)
                    put_lots_data(
                      ln_total_01,        -- 処理件数
                      ln_cnt_03,          -- ループカウント(第三階層)
                      lv_out_control,     -- 出力制御
                      lv_level_num_03,    -- 階層
                      gt_itp03_tbl,       -- 生産情報(第三階層)
                      gt_rcv03_tbl,       -- 受入情報(第三階層)
                      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
                      lv_retcode,         -- リターン・コード             --# 固定 #
                      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
                    IF (lv_retcode = gv_status_error) THEN
                      RAISE global_process_expt;
                    END IF;
--
                    -- 第三階層の子品目を親品目へ置換え
                    IF ((gt_itp03_tbl.COUNT > 0) AND (gt_itp03_tbl.COUNT >= ln_cnt_03)) THEN
                      IF (gt_itp03_tbl(ln_cnt_03).c_item_no IS NOT NULL) THEN
                        lv_item_id_04  := gt_itp03_tbl(ln_cnt_03).c_item_id;
                        lv_lot_id_04   := gt_itp03_tbl(ln_cnt_03).c_lot_id;
                        lv_batch_id_04 := gt_itp03_tbl(ln_cnt_03).p_batch_id;
--
                        -- ================================
                        -- A-9.第四階層ロット系統データ抽出
                        -- ================================
                        get_lots_data(
                          lv_item_id_04,      -- 品目ID
                          lv_lot_id_04,       -- ロットID
                          lv_batch_id_04,     -- バッチID
                          lv_out_control,     -- 出力制御
                          lv_level_num_04,    -- 階層
                          gt_itp04_tbl,       -- 生産情報(第四階層)
                          gt_rcv04_tbl,       -- 受入情報(第四階層)
                          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
                          lv_retcode,         -- リターン・コード             --# 固定 #
                          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
                        IF (lv_retcode = gv_status_error) THEN
                          RAISE global_process_expt;
                        END IF;
--
                        -- 処理件数
                        ln_loop_cnt_04 := gt_itp04_tbl.COUNT + gt_rcv04_tbl.COUNT;
--
                        << lot_trace_loop_04 >>
                        FOR ln_cnt_04 IN 1..ln_loop_cnt_04 LOOP
                          -- =================================
                          -- A-10.第四階層ロット系統データ格納
                          -- =================================
                          -- ループカウント(第四階層分)
                          put_lots_data(
                            ln_total_01,        -- 処理件数
                            ln_cnt_04,          -- ループカウント(第四階層)
                            lv_out_control,     -- 出力制御
                            lv_level_num_04,    -- 階層
                            gt_itp04_tbl,       -- 生産情報(第四階層)
                            gt_rcv04_tbl,       -- 受入情報(第四階層)
                            lv_errbuf,          -- エラー・メッセージ           --# 固定 #
                            lv_retcode,         -- リターン・コード             --# 固定 #
                            lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
                          IF (lv_retcode = gv_status_error) THEN
                            RAISE global_process_expt;
                          END IF;
--
                          -- 第四階層の子品目を親品目へ置換え
                          IF ((gt_itp04_tbl.COUNT > 0) AND (gt_itp04_tbl.COUNT >= ln_cnt_04)) THEN
                            IF (gt_itp04_tbl(ln_cnt_04).c_item_no IS NOT NULL) THEN
                              lv_item_id_05  := gt_itp04_tbl(ln_cnt_04).c_item_id;
                              lv_lot_id_05   := gt_itp04_tbl(ln_cnt_04).c_lot_id;
                              lv_batch_id_05 := gt_itp04_tbl(ln_cnt_04).p_batch_id;
--
                              -- =================================
                              -- A-11.第五階層ロット系統データ抽出
                              -- =================================
                              get_lots_data(
                                lv_item_id_05,      -- 品目ID
                                lv_lot_id_05,       -- ロットID
                                lv_batch_id_05,     -- バッチID
                                lv_out_control,     -- 出力制御
                                lv_level_num_05,    -- 階層
                                gt_itp05_tbl,       -- 生産情報(第五階層)
                                gt_rcv05_tbl,       -- 受入情報(第五階層)
                                lv_errbuf,          -- エラー・メッセージ           --# 固定 #
                                lv_retcode,         -- リターン・コード             --# 固定 #
                                lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
                              IF (lv_retcode = gv_status_error) THEN
                                RAISE global_process_expt;
                              END IF;
--
                              -- 処理件数
                              ln_loop_cnt_05 := gt_itp05_tbl.COUNT + gt_rcv05_tbl.COUNT;
--
                              << lot_trace_loop_05 >>
                              FOR ln_cnt_05 IN 1..ln_loop_cnt_05 LOOP
                                -- =================================
                                -- A-12.第五階層ロット系統データ格納
                                -- =================================
                                -- ループカウント(第五階層分)
                                put_lots_data(
                                  ln_total_01,        -- 処理件数
                                  ln_cnt_05,          -- ループカウント(第五階層)
                                  lv_out_control,     -- 出力制御
                                  lv_level_num_05,    -- 階層
                                  gt_itp05_tbl,       -- 生産情報(第五階層)
                                  gt_rcv05_tbl,       -- 受入情報(第五階層)
                                  lv_errbuf,          -- エラー・メッセージ           --# 固定 #
                                  lv_retcode,         -- リターン・コード             --# 固定 #
                                  lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
                                IF (lv_retcode = gv_status_error) THEN
                                  RAISE global_process_expt;
                                END IF;
--
                              END LOOP lot_trace_loop_05;
                            END IF;                   -- 第五階層親子品目置換え
                          END IF;                     -- 第五階層件数チェック終了
                        END LOOP lot_trace_loop_04;
                      END IF;                         -- 第四階層親子品目置換え
                    END IF;                           -- 第四階層件数チェック終了
                  END LOOP lot_trace_loop_03;
                END IF;                               -- 第三階層親子品目置換え
              END IF;                                 -- 第三階層件数チェック終了
            END LOOP lot_trace_loop_02;
          END IF;                                     -- 第二階層親子品目置換え
        END IF;                                       -- 第二階層件数チェック終了
      END LOOP lot_trace_loop_01;
      -- ================================
      -- A-13.ロット系統データ一括登録
      -- ================================
      insert_lots_data(
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    END IF;
    -- 処理件数
    gn_normal_cnt := ln_total_01;
--
    -- 正常終了件数取得
    IF ((gn_normal_cnt > 0) AND (lv_retcode = gv_status_normal)) THEN
      -- ログ出力処理
      disp_report(lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--##########################################
--##### その他処理が必要なら、追加する #####
--##########################################
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
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
    errbuf              OUT    VARCHAR2,                -- エラー・メッセージ           --# 固定 #
    retcode             OUT    VARCHAR2,                -- リターン・コード             --# 固定 #
    iv_item_code        IN     VARCHAR2,                -- 品目コード
    iv_lot_no           IN     VARCHAR2,                -- ロットNo
    iv_out_control      IN     VARCHAR2)                -- 出力制御
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'main';                  -- プログラム名
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
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_item_code,                                -- 1.品目コード
      iv_lot_no,                                   -- 2.ロットNo
      iv_out_control,                              -- 3.出力制御
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
--
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
END xxcmn560001c;
/
