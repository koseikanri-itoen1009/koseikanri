CREATE OR REPLACE PACKAGE BODY APPS.XXCOP006A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP006A01C(body)
 * Description      : 横持計画
 * MD.050           : 横持計画 MD050_COP_006_A01
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  entry_xwypo            横持計画出力ワークテーブル登録
 *  fix_delivery_unit      配送単位の決定
 *  fix_plan_lots          計画ロットの決定
 *  proc_maximum_plan_qty  計画数(最大)の計算
 *  proc_minimum_plan_qty  計画数(最小)の計算
 *  proc_balance_plan_qty  計画数(バランス)の計算
 *  get_stock_quantity     在庫数の取得
 *  entry_xwsp             物流計画ワークテーブル登録
 *  proc_ship_pace         出荷ペースの計算
 *  chk_route_prereq       経路の前提条件チェック
 *  get_ship_route         出荷倉庫経路取得
 *  delete_table           テーブルデータ削除
 *  init                   初期処理(A-1)
 *  get_msr_route          横持計画制御マスタ取得(A-2)
 *  get_xwsp               物流計画ワークテーブル取得(A-3)
 *  output_xwypo           横持計画CSV出力(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19    1.0   Y.Goto           新規作成
 *  2009/04/07    1.1   Y.Goto           T1_0273,T1_0274,T1_0289,T1_0366,T1_0367対応
 *  2009/04/14    1.2   Y.Goto           T1_0539,T1_0541対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  internal_api_expt         EXCEPTION;     -- コンカレント内部共通例外
  param_invalid_expt        EXCEPTION;     -- 入力パラメータチェックエラー
  date_invalid_expt         EXCEPTION;     -- 日付チェックエラー
  past_date_invalid_expt    EXCEPTION;     -- 過去日チェックエラー
  resource_busy_expt        EXCEPTION;     -- デッドロックエラー
  profile_invalid_expt      EXCEPTION;     -- プロファイル値エラー
  stock_days_expt           EXCEPTION;     -- 在庫日数チェックエラー
  no_condition_expt         EXCEPTION;     -- 鮮度条件未登録エラー
  no_working_days_expt      EXCEPTION;     -- 稼働日エラー
  obsolete_skip_expt        EXCEPTION;     -- 廃止スキップ例外
  short_supply_expt         EXCEPTION;     -- 在庫不足例外
  nested_loop_expt          EXCEPTION;     -- 階層ループエラー
  zero_divide_expt          EXCEPTION;     -- ゼロ除算エラー
--
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
  PRAGMA EXCEPTION_INIT(nested_loop_expt, -01436);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP006A01C';           -- パッケージ名
  --メッセージ共通
  cv_msg_appl_cont          CONSTANT VARCHAR2(100) := 'XXCOP';                  -- アプリケーション短縮名
  --言語
  cv_lang                   CONSTANT VARCHAR2(100) := USERENV('LANG');          -- 言語
  --プログラム実行年月日
  cd_sysdate                CONSTANT DATE := TRUNC(SYSDATE);                    -- システム日付（年月日）
  --日付型フォーマット
  cv_date_format            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';             -- 年月日
  cv_trunc_month            CONSTANT VARCHAR2(100) := 'MM';                     -- 年月
  --タイムスタンプ型フォーマット
  cv_timestamp_format       CONSTANT VARCHAR2(100) := 'HH24:MI:SS.FF3';         -- 年月日時分秒
  --メッセージ名
  cv_msg_00002              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';       -- プロファイル値取得失敗
  cv_msg_00003              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';       -- 対象データなし
  cv_msg_00011              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00011';       -- DATE型チェックエラーメッセージ
  cv_msg_00025              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';       -- 値逆転メッセージ
  cv_msg_00027              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';       -- 登録処理エラーメッセージ
  cv_msg_00041              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';       -- CSVアウトプット機能システムエラーメッセージ
  cv_msg_00042              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';       -- 削除処理エラーメッセージ
  cv_msg_00047              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';       -- 未来日入力メッセージ
  cv_msg_00050              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00050';       -- 倉庫情報取得エラー
  cv_msg_00053              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00053';       -- 配送リードタイム取得エラー
  cv_msg_00055              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00055';       -- パラメータエラー
  cv_msg_00056              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00056';       -- 設定期間中稼働日チェックエラーメッセージ
  cv_msg_00057              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00057';       -- 配送単位取得エラー
  cv_msg_00058              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00058';       -- 按分ゼロ計算不正エラーメッセージ
  cv_msg_00059              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00059';       -- 配送単位ゼロエラー
  cv_msg_00060              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00060';       -- 経路情報ループエラーメッセージ
  cv_msg_00061              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00061';       -- ケース入数不正エラーメッセージ
  cv_msg_10038              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10038';       -- 鮮度条件未登録エラー
  cv_msg_10039              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10039';       -- 開始製造年月日未登録エラー
  cv_msg_10040              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10040';       -- 出荷倉庫鮮度条件未登録エラー
  cv_msg_10041              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10041';       -- 鮮度条件在庫日数チェックエラー
  --メッセージトークン
  cv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  cv_msg_00011_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00025_token_1      CONSTANT VARCHAR2(100) := 'PERIOD_FROM';
  cv_msg_00025_token_2      CONSTANT VARCHAR2(100) := 'PERIOD_TO';
  cv_msg_00027_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00041_token_1      CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00047_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_00050_token_1      CONSTANT VARCHAR2(100) := 'ORGID';
  cv_msg_00053_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE_FROM';
  cv_msg_00053_token_2      CONSTANT VARCHAR2(100) := 'WHSE_CODE_TO';
  cv_msg_00056_token_1      CONSTANT VARCHAR2(100) := 'FROM_DATE';
  cv_msg_00056_token_2      CONSTANT VARCHAR2(100) := 'TO_DATE';
  cv_msg_00057_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00058_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME1';
  cv_msg_00058_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NAME2';
  cv_msg_00059_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00060_token_1      CONSTANT VARCHAR2(100) := 'WHSE_NAME';
  cv_msg_00061_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10038_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10039_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10040_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10041_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10041_token_2      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  --メッセージトークン値
  cv_table_xwypo            CONSTANT VARCHAR2(100) := '横持計画出力ワークテーブル';
  cv_table_xwsp             CONSTANT VARCHAR2(100) := '物流計画ワークテーブル';
  cv_msg_00058_value_1      CONSTANT VARCHAR2(100) := '計画数';
  cv_msg_00058_value_2      CONSTANT VARCHAR2(100) := '出荷ペース';
  cv_msg_10041_value_1      CONSTANT VARCHAR2(100) := '在庫維持日数';
  cv_msg_10041_value_2      CONSTANT VARCHAR2(100) := '最大在庫日数';
  --入力パラメータ
  cv_plan_type_tl           CONSTANT VARCHAR2(100) := '計画区分';
  gv_shipment_from_tl       CONSTANT VARCHAR2(100) := '出荷ペース計画期間(FROM)';
  gv_shipment_to_tl         CONSTANT VARCHAR2(100) := '出荷ペース計画期間(TO)';
  cv_forcast_type_tl        CONSTANT VARCHAR2(100) := '出荷予測区分';
  --プロファイル
  cv_pf_master_org_id       CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';
  cv_upf_master_org_id      CONSTANT VARCHAR2(100) := 'XXCMN:マスタ組織';
  cv_pf_dummy_src_org_id    CONSTANT VARCHAR2(100) := 'XXCOP1_DUMMY_SOURCE_ORG_ID';
  cv_upf_dummy_src_org_id   CONSTANT VARCHAR2(100) := 'XXCOP：ダミー出荷組織';
  cv_pf_fresh_buffer_days   CONSTANT VARCHAR2(100) := 'XXCOP1_FRESHNESS_BUFFER_DAYS';
  cv_upf_fresh_buffer_days  CONSTANT VARCHAR2(100) := 'XXCOP：鮮度条件バッファ日数';
  cv_pf_deadline_months     CONSTANT VARCHAR2(100) := 'XXCOP1_DEADLINE_MONTHS';
  cv_upf_deadline_months    CONSTANT VARCHAR2(100) := 'XXCOP：最終期限月数';
  cv_pf_deadline_days       CONSTANT VARCHAR2(100) := 'XXCOP1_DEADLINE_BUFFER_DAYS';
  cv_upf_deadline_days      CONSTANT VARCHAR2(100) := 'XXCOP：最終期限バッファ日数';
  --クイックコードタイプ
  cv_flv_assignment_name    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';
  cv_flv_assign_priority    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';
  cv_flv_lot_status         CONSTANT VARCHAR2(100) := 'XXCMN_LOT_STATUS';
  cv_flv_freshness_cond     CONSTANT VARCHAR2(100) := 'XXCMN_FRESHNESS_CONDITION';
  cv_flv_unit_delivery      CONSTANT VARCHAR2(100) := 'XXCOP1_UNIT_DELIVERY';
  cv_enable                 CONSTANT VARCHAR2(100) := 'Y';
  --計画区分
  cv_plan_type_shipped      CONSTANT VARCHAR2(100) := '1';                      -- 出荷ペース
  cv_plan_type_fgorcate     CONSTANT VARCHAR2(100) := '2';                      -- 出荷予測
  --出荷予測区分
  cv_forcast_type_this      CONSTANT VARCHAR2(100) := '1';                      -- 当月分
  cv_forcast_type_next      CONSTANT VARCHAR2(100) := '2';                      -- 翌月分
  cv_forcast_type_2month    CONSTANT VARCHAR2(100) := '3';                      -- 当月＋翌月分
  --割当セット区分
  cv_base_plan              CONSTANT VARCHAR2(1)   := '1';                      -- 基本横持計画
  cv_custom_plan            CONSTANT VARCHAR2(1)   := '2';                      -- 特別横持計画
  cv_factory_ship_plan      CONSTANT VARCHAR2(1)   := '3';                      -- 工場出荷計画
  --鮮度条件の分類
  cv_condition_general      CONSTANT VARCHAR2(1)   := '0';                      -- 一般
  cv_condition_expiration   CONSTANT VARCHAR2(1)   := '1';                      -- 賞味期限基準
  cv_condition_manufacture  CONSTANT VARCHAR2(1)   := '2';                      -- 製造日基準
  --計画タイプ
  cv_plan_balance           CONSTANT VARCHAR2(1)   := '0';                      -- バランス
  cv_plan_minimum           CONSTANT VARCHAR2(1)   := '1';                      -- 最小
  cv_plan_maximum           CONSTANT VARCHAR2(1)   := '2';                      -- 最大
  --配送単位
  cv_unit_palette           CONSTANT VARCHAR2(10)  := '1';                      -- パレット
  cv_unit_step              CONSTANT VARCHAR2(10)  := '2';                      -- 段
  cv_unit_case              CONSTANT VARCHAR2(10)  := '3';                      -- ケース
--
  --商品区分
  cv_product_class_drink    CONSTANT VARCHAR2(1)   := '2';                      -- 商品区分-ドリンク
  --品目カテゴリマスタ
  cv_xicv_status            CONSTANT VARCHAR2(8)   := 'Inactive';               -- 
  cn_xicv_inactive          CONSTANT NUMBER := 1;                               -- 
  cn_xsr_plan_item          CONSTANT NUMBER := 1;                               -- 計画商品
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_START
  --DISC品目アドオンマスタ
  cn_xsib_status_temporary  CONSTANT NUMBER := 20;                              -- 仮登録
  cn_xsib_status_registered CONSTANT NUMBER := 30;                              -- 本登録
  cn_xsib_status_obsolete   CONSTANT NUMBER := 40;                              -- 廃
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_END
  --入出庫予定情報ビュー
  cv_xstv_status            CONSTANT VARCHAR2(1)   := '1';                      -- 予定
--
  --CSVファイル出力フォーマット
  cv_csv_date_format        CONSTANT VARCHAR2(10)  := 'YYYYMMDD';               -- 年月日
  cv_csv_char_bracket       CONSTANT VARCHAR2(1)   := '"';                      -- ダブルクォーテーション
  cv_csv_delimiter          CONSTANT VARCHAR2(1)   := ',';                      -- カンマ
  cv_csv_mark               CONSTANT VARCHAR2(1)   := '*';                      -- アスタリスク
  --CSVファイル出力ヘッダー
  cv_put_column_01          CONSTANT VARCHAR2(100) := '出荷日';                 -- 
  cv_put_column_02          CONSTANT VARCHAR2(100) := '着日';                   -- 
  cv_put_column_03          CONSTANT VARCHAR2(100) := '移動元倉庫ＣＤ';         -- 
  cv_put_column_04          CONSTANT VARCHAR2(100) := '移動元倉庫名';           -- 
  cv_put_column_05          CONSTANT VARCHAR2(100) := '移動先倉庫ＣＤ';         -- 
  cv_put_column_06          CONSTANT VARCHAR2(100) := '移動先倉庫名';           -- 
  cv_put_column_07          CONSTANT VARCHAR2(100) := '品目ＣＤ';               -- 
  cv_put_column_08          CONSTANT VARCHAR2(100) := '品目名';                 -- 
  cv_put_column_09          CONSTANT VARCHAR2(100) := '鮮度条件';               -- 
  cv_put_column_10          CONSTANT VARCHAR2(100) := '製造年月日';             -- 
  cv_put_column_11          CONSTANT VARCHAR2(100) := '品質';                   -- 
  cv_put_column_12          CONSTANT VARCHAR2(100) := '計画数(最小)';           -- 
  cv_put_column_13          CONSTANT VARCHAR2(100) := '計画数(最大)';           -- 
  cv_put_column_14          CONSTANT VARCHAR2(100) := '計画数(バランス)';       -- 
  cv_put_column_15          CONSTANT VARCHAR2(100) := '配送単位';               -- 
  cv_put_column_16          CONSTANT VARCHAR2(100) := '横持前在庫';             -- 
  cv_put_column_17          CONSTANT VARCHAR2(100) := '横持後在庫';             -- 
  cv_put_column_18          CONSTANT VARCHAR2(100) := '安全在庫';               -- 
  cv_put_column_19          CONSTANT VARCHAR2(100) := '最大在庫';               -- 
  cv_put_column_20          CONSTANT VARCHAR2(100) := '出荷ペース';             -- 
  cv_put_column_21          CONSTANT VARCHAR2(100) := '特別横持ち';             -- 
  cv_put_column_22          CONSTANT VARCHAR2(100) := '補充不可';               -- 
  cv_put_column_23          CONSTANT VARCHAR2(100) := 'ロット逆転';             -- 
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --物流計画ワークテーブルコレクション型
  TYPE g_xwsp_ttype IS TABLE OF xxcop_wk_ship_planning%ROWTYPE
    INDEX BY BINARY_INTEGER;
  --横持計画出力ワークテーブルコレクション型
  TYPE g_xwypo_ttype IS TABLE OF xxcop_wk_yoko_plan_output%ROWTYPE
    INDEX BY BINARY_INTEGER;
--
  --物流計画ワークテーブル倉庫情報参照レコード型
  TYPE g_xwsp_ref_rtype IS RECORD (
     item_id                 xxcop_wk_ship_planning.item_id%TYPE
    ,item_no                 xxcop_wk_ship_planning.item_no%TYPE
    ,ship_org_id             xxcop_wk_ship_planning.ship_org_id%TYPE
    ,ship_org_code           xxcop_wk_ship_planning.ship_org_code%TYPE
    ,shipping_date           xxcop_wk_ship_planning.shipping_date%TYPE
    ,before_stock            xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,manufacture_date        xxcop_wk_yoko_plan_output.manu_date%TYPE
    ,shipping_pace           xxcop_wk_ship_planning.shipping_pace%TYPE
    ,stock_maintenance_days  xxcop_wk_ship_planning.stock_maintenance_days%TYPE
    ,max_stock_days          xxcop_wk_ship_planning.max_stock_days%TYPE
  );
  --物流計画ワークテーブル倉庫情報参照コレクション型
  TYPE g_xwsp_ref_ttype IS TABLE OF g_xwsp_ref_rtype
    INDEX BY BINARY_INTEGER;
  --横持計画出力ワークテーブル倉庫情報参照レコード型
  TYPE g_xwypo_ref_rtype IS RECORD (
     transaction_id          xxcop_wk_yoko_plan_output.transaction_id%TYPE
    ,shipping_date           xxcop_wk_yoko_plan_output.shipping_date%TYPE
    ,receipt_date            xxcop_wk_yoko_plan_output.receipt_date%TYPE
    ,ship_org_code           xxcop_wk_yoko_plan_output.ship_org_code%TYPE
    ,ship_org_name           xxcop_wk_yoko_plan_output.ship_org_name%TYPE
    ,receipt_org_code        xxcop_wk_yoko_plan_output.receipt_org_code%TYPE
    ,receipt_org_name        xxcop_wk_yoko_plan_output.receipt_org_name%TYPE
    ,item_id                 xxcop_wk_yoko_plan_output.item_id%TYPE
    ,item_no                 xxcop_wk_yoko_plan_output.item_no%TYPE
    ,item_name               xxcop_wk_yoko_plan_output.item_name%TYPE
    ,freshness_priority      xxcop_wk_yoko_plan_output.freshness_priority%TYPE
    ,freshness_condition     xxcop_wk_yoko_plan_output.freshness_condition%TYPE
    ,manu_date               xxcop_wk_yoko_plan_output.manu_date%TYPE
    ,lot_status              xxcop_wk_yoko_plan_output.lot_status%TYPE
    ,plan_min_qty            xxcop_wk_yoko_plan_output.plan_min_qty%TYPE
    ,plan_max_qty            xxcop_wk_yoko_plan_output.plan_max_qty%TYPE
    ,plan_bal_qty            xxcop_wk_yoko_plan_output.plan_bal_qty%TYPE
    ,plan_lot_qty            xxcop_wk_yoko_plan_output.plan_lot_qty%TYPE
    ,delivery_unit           xxcop_wk_yoko_plan_output.delivery_unit%TYPE
    ,before_stock            xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,after_stock             xxcop_wk_yoko_plan_output.after_stock%TYPE
    ,safety_days             xxcop_wk_yoko_plan_output.safety_days%TYPE
    ,max_days                xxcop_wk_yoko_plan_output.max_days%TYPE
    ,shipping_pace           xxcop_wk_yoko_plan_output.shipping_pace%TYPE
    ,under_lvl_pace          xxcop_wk_yoko_plan_output.shipping_pace%TYPE
    ,special_yoko_type       xxcop_wk_yoko_plan_output.special_yoko_type%TYPE
    ,supp_bad_type           xxcop_wk_yoko_plan_output.supp_bad_type%TYPE
    ,lot_revers_type         xxcop_wk_yoko_plan_output.lot_revers_type%TYPE
    ,earliest_manu_date      xxcop_wk_yoko_plan_output.earliest_manu_date%TYPE
    ,start_manu_date         xxcop_wk_yoko_plan_output.start_manu_date%TYPE
    ,num_of_case             xxcop_wk_ship_planning.num_of_case%TYPE
    ,palette_max_cs_qty      xxcop_wk_ship_planning.palette_max_cs_qty%TYPE
    ,palette_max_step_qty    xxcop_wk_ship_planning.palette_max_step_qty%TYPE
  );
  --横持計画出力ワークテーブル倉庫情報参照コレクション型
  TYPE g_xwypo_ref_ttype IS TABLE OF g_xwypo_ref_rtype
    INDEX BY BINARY_INTEGER;
  --鮮度条件レコード型
  TYPE g_freshness_condition_rtype IS RECORD (
     freshness_condition     xxcop_wk_ship_planning.freshness_condition%TYPE
    ,stock_maintenance_days  xxcop_wk_ship_planning.stock_maintenance_days%TYPE
    ,max_stock_days          xxcop_wk_ship_planning.max_stock_days%TYPE
  );
  --鮮度条件コレクション型
  TYPE g_freshness_condition_ttype IS TABLE OF g_freshness_condition_rtype
    INDEX BY BINARY_INTEGER;
  --鮮度条件優先順位レコード型
  TYPE g_condition_priority_rtype IS RECORD (
     freshness_priority      xxcop_wk_ship_planning.freshness_priority%TYPE
    ,freshness_condition     xxcop_wk_ship_planning.freshness_condition%TYPE
    ,condition_type          fnd_lookup_values.attribute1%TYPE
    ,condition_value         NUMBER
  );
  --鮮度条件優先順位コレクション型
  TYPE g_condition_priority_ttype IS TABLE OF g_condition_priority_rtype
    INDEX BY BINARY_INTEGER;
  --計画数計算レコード型
  TYPE g_proc_plan_rtype IS RECORD (
     stock_quantity          NUMBER               -- 在庫数
    ,stock_days              NUMBER               -- 在庫日数
    ,require_quantity        NUMBER               -- 要求在庫数
    ,require_days            NUMBER               -- 要求在庫日数
    ,crunch_quantity         NUMBER               -- 不足在庫数
    ,margin_quantity         NUMBER               -- 余裕在庫数
    ,margin_stock_days       NUMBER               -- 余裕在庫日数
  );
  --計画数計算コレクション型
  TYPE g_proc_plan_ttype IS TABLE OF g_proc_plan_rtype
    INDEX BY BINARY_INTEGER;
  --製造ロットレコード型
  TYPE g_manufacture_lot_rtype IS RECORD (
     lot_quantity            xxcop_wk_yoko_plan_output.plan_lot_qty%TYPE
    ,manufacture_date        xxcop_wk_yoko_plan_output.manu_date%TYPE
    ,lot_status              xxcop_wk_yoko_plan_output.lot_status%TYPE
    ,lot_revers              xxcop_wk_yoko_plan_output.lot_revers_type%TYPE
  );
  --製造ロットコレクション型
  TYPE g_manufacture_lot_ttype IS TABLE OF g_manufacture_lot_rtype
    INDEX BY BINARY_INTEGER;
  --横持計画出力ワークテーブルCSV出力レコード型
  TYPE g_xwypo_csv_rtype IS RECORD (
     shipping_date           xxcop_wk_yoko_plan_output.shipping_date%TYPE
    ,receipt_date            xxcop_wk_yoko_plan_output.receipt_date%TYPE
    ,ship_org_code           xxcop_wk_yoko_plan_output.ship_org_code%TYPE
    ,ship_org_name           xxcop_wk_yoko_plan_output.ship_org_name%TYPE
    ,receipt_org_code        xxcop_wk_yoko_plan_output.receipt_org_code%TYPE
    ,receipt_org_name        xxcop_wk_yoko_plan_output.receipt_org_name%TYPE
    ,item_no                 xxcop_wk_yoko_plan_output.item_no%TYPE
    ,item_name               xxcop_wk_yoko_plan_output.item_name%TYPE
    ,manu_date               xxcop_wk_yoko_plan_output.manu_date%TYPE
    ,lot_status              xxcop_wk_yoko_plan_output.lot_status%TYPE
    ,plan_min_qty            xxcop_wk_yoko_plan_output.plan_min_qty%TYPE
    ,plan_max_qty            xxcop_wk_yoko_plan_output.plan_max_qty%TYPE
    ,plan_bal_qty            xxcop_wk_yoko_plan_output.plan_bal_qty%TYPE
    ,delivery_unit           xxcop_wk_yoko_plan_output.delivery_unit%TYPE
    ,before_stock            xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,after_stock             xxcop_wk_yoko_plan_output.after_stock%TYPE
    ,safety_stock            xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,max_stock               xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,shipping_pace           xxcop_wk_yoko_plan_output.shipping_pace%TYPE
    ,special_yoko_type       xxcop_wk_yoko_plan_output.special_yoko_type%TYPE
    ,supp_bad_type           xxcop_wk_yoko_plan_output.supp_bad_type%TYPE
    ,lot_revers_type         xxcop_wk_yoko_plan_output.lot_revers_type%TYPE
    ,freshness_condition     fnd_lookup_values.description%TYPE
    ,quality_type            fnd_lookup_values.meaning%TYPE
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
    ,num_of_case             NUMBER
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
  );
  --横持計画出力ワークテーブルCSV出力コレクション型
  TYPE g_xwypo_csv_ttype IS TABLE OF g_xwypo_csv_rtype
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_debug_mode             VARCHAR2(256);                                      --デバックモード
  gn_group_id               NUMBER;                                             --横持計画グループID
  gd_plan_date              DATE;                                               --横持計画作成日
  --起動パラメータ
  gv_plan_type              VARCHAR2(1);                                        --計画区分
  gd_shipment_from          DATE;                                               --出荷ペース計画期間FROM
  gd_shipment_to            DATE;                                               --出荷ペース計画期間TO
  gd_forcast_from           DATE;                                               --出荷予測期間FROM
  gd_forcast_to             DATE;                                               --出荷予測期間TO
  --プロファイル値
  gn_master_org_id          NUMBER;                                             --マスタ組織ID
  gn_dummy_src_org_id       NUMBER;                                             --ダミー出荷組織ID
  gn_freshness_buffer_days  NUMBER;                                             --鮮度条件バッファ日数
  gn_deadline_months        NUMBER;                                             --最終期限月数
  gn_deadline_buffer_days   NUMBER;                                             --最終期限バッファ日数
--
  /**********************************************************************************
   * Procedure Name   : entry_xwypo
   * Description      : 横持計画出力ワークテーブル登録
   ***********************************************************************************/
  PROCEDURE entry_xwypo(
    i_xwypo_rec      IN     g_xwypo_ref_rtype,
    io_ml_tab        IN OUT g_manufacture_lot_ttype,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xwypo'; -- プログラム名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    BEGIN
      IF ( io_ml_tab.COUNT = 0 ) THEN 
        io_ml_tab(1).lot_quantity     := NULL;
        io_ml_tab(1).manufacture_date := NULL;
        io_ml_tab(1).lot_status       := NULL;
        io_ml_tab(1).lot_revers       := NULL;
      END IF;
      <<entry_xwypo_loop>>
      FOR ln_lot_idx IN io_ml_tab.FIRST .. io_ml_tab.LAST LOOP
        --横持計画出力ワークテーブル登録
        INSERT INTO xxcop_wk_yoko_plan_output(
           transaction_id
          ,group_id
          ,shipping_date
          ,receipt_date
          ,ship_org_code
          ,ship_org_name
          ,receipt_org_code
          ,receipt_org_name
          ,item_id
          ,item_no
          ,item_name
          ,freshness_priority
          ,freshness_condition
          ,manu_date
          ,lot_status
          ,plan_min_qty
          ,plan_max_qty
          ,plan_bal_qty
          ,plan_lot_qty
          ,delivery_unit
          ,before_stock
          ,after_stock
          ,safety_days
          ,max_days
          ,shipping_pace
          ,special_yoko_type
          ,supp_bad_type
          ,lot_revers_type
          ,earliest_manu_date
          ,start_manu_date
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
        ) VALUES(
           cn_request_id
          ,gn_group_id
          ,i_xwypo_rec.shipping_date
          ,i_xwypo_rec.receipt_date
          ,i_xwypo_rec.ship_org_code
          ,i_xwypo_rec.ship_org_name
          ,i_xwypo_rec.receipt_org_code
          ,i_xwypo_rec.receipt_org_name
          ,i_xwypo_rec.item_id
          ,i_xwypo_rec.item_no
          ,i_xwypo_rec.item_name
          ,i_xwypo_rec.freshness_priority
          ,i_xwypo_rec.freshness_condition
          ,io_ml_tab(ln_lot_idx).manufacture_date
          ,io_ml_tab(ln_lot_idx).lot_status
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.plan_min_qty
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.plan_max_qty
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.plan_bal_qty
               ELSE NULL
           END
          ,io_ml_tab(ln_lot_idx).lot_quantity
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.delivery_unit
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.before_stock
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.after_stock
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.safety_days
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.max_days
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.under_lvl_pace
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.special_yoko_type
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.supp_bad_type
               ELSE NULL
           END
          ,io_ml_tab(ln_lot_idx).lot_revers
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.earliest_manu_date
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.start_manu_date
               ELSE NULL
           END
          ,cn_created_by
          ,cd_creation_date
          ,cn_last_updated_by
          ,cd_last_update_date
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
        );
      END LOOP entry_xwypo_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwypo
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END entry_xwypo;
--
  /**********************************************************************************
   * Procedure Name   : fix_delivery_unit
   * Description      : 配送単位の決定
   ***********************************************************************************/
  PROCEDURE fix_delivery_unit(
    io_xwypo_rec     IN OUT g_xwypo_ref_rtype,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fix_delivery_unit'; -- プログラム名
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
    ln_unit_quantity          NUMBER;              --配送単位数量
--
    -- *** ローカル・カーソル ***
    --配送単位の基準数
    CURSOR flv_cur IS
      SELECT flv.lookup_code             lookup_code
            ,flv.meaning                 meaning
            ,flv.description             description
      FROM fnd_lookup_values flv
      WHERE flv.lookup_type            = cv_flv_unit_delivery
        AND flv.language               = cv_lang
        AND flv.source_lang            = cv_lang
        AND flv.enabled_flag           = cv_enable
        AND cd_sysdate BETWEEN NVL(flv.start_date_active, cd_sysdate)
                           AND NVL(flv.end_date_active, cd_sysdate)
      ORDER BY flv.lookup_code ASC;
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    <<flv_loop>>
    FOR flv_rec IN flv_cur LOOP
      CASE
        WHEN flv_rec.lookup_code = cv_unit_palette THEN
          --パレットの基準数で判定
          ln_unit_quantity := io_xwypo_rec.plan_bal_qty / io_xwypo_rec.num_of_case
                                                        / io_xwypo_rec.palette_max_cs_qty
                                                        / io_xwypo_rec.palette_max_step_qty;
        WHEN flv_rec.lookup_code = cv_unit_step THEN
          --段の基準数で判定
          ln_unit_quantity := io_xwypo_rec.plan_bal_qty / io_xwypo_rec.num_of_case
                                                        / io_xwypo_rec.palette_max_cs_qty;
        WHEN flv_rec.lookup_code = cv_unit_case THEN
          --ケースの基準数で判定
          ln_unit_quantity := io_xwypo_rec.plan_bal_qty / io_xwypo_rec.num_of_case;
      END CASE;
      IF ( ln_unit_quantity > TO_NUMBER(flv_rec.description) ) THEN
        io_xwypo_rec.delivery_unit := flv_rec.meaning;
        EXIT flv_loop;
      END IF;
    END LOOP flv_loop;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END fix_delivery_unit;
--
  /**********************************************************************************
   * Procedure Name   : fix_plan_lots
   * Description      : 計画ロットの決定
   ***********************************************************************************/
  PROCEDURE fix_plan_lots(
    i_xwsp_rec       IN     g_xwsp_ref_rtype,    -- 1.出荷倉庫情報
    i_cp_rec         IN     g_condition_priority_rtype,
    io_xwypo_tab     IN OUT g_xwypo_ref_ttype,   -- 2.受入倉庫情報
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fix_plan_lots'; -- プログラム名
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
    ln_plan_quantity          NUMBER;
    ln_lot_idx                NUMBER;
--
    -- *** ローカル・カーソル ***
    --鮮度条件（一般）のロット
    CURSOR general_qty_cur( 
              in_item_id          NUMBER
             ,iv_whse_code        VARCHAR2
             ,id_plan_date        DATE
             ,in_stock_days       NUMBER
             ,id_manufacture_date DATE
    ) IS
      SELECT NVL(SUM(ilmv.lot_quantity), 0) lot_quantity
            ,ilmv.manufacture_date          manufacture_date
            ,ilmv.lot_status                lot_status
      FROM (
        --OPMロットマスタ
        SELECT ili.loct_onhand                                             lot_quantity
              ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,ic_loct_inv ili
        WHERE ilm.item_id          = ili.item_id
          AND ilm.lot_id           = ili.lot_id
          AND ili.item_id          = in_item_id
          AND ili.whse_code        = iv_whse_code
          --最終期限ルール
          AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
                           - in_stock_days
                           - gn_freshness_buffer_days
          --開始製造年月日(特別横持計画)
          AND TO_DATE(ilm.attribute1, cv_date_format) >= NVL(id_manufacture_date
                                                            ,TO_DATE(ilm.attribute1, cv_date_format))
        UNION ALL
        --入出庫予定情報ビュー
        SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) lot_quantity
              ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,xxcop_stc_trans_v xstv
        WHERE ilm.item_id          = xstv.item_id
          AND ilm.lot_id           = xstv.lot_id
          AND xstv.item_id         = in_item_id
          AND xstv.whse_code       = iv_whse_code
          AND xstv.status          = cv_xstv_status
          AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                    AND id_plan_date
                                    AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
          --最終期限ルール
          AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
                           - in_stock_days
                           - gn_freshness_buffer_days
          --開始製造年月日(特別横持計画)
          AND TO_DATE(xstv.manufacture_date, cv_date_format) >= NVL(id_manufacture_date
                                                                   ,TO_DATE(xstv.manufacture_date, cv_date_format))
        UNION ALL
        --横持計画出力ワークテーブル
        SELECT xwypo.plan_lot_qty * -1                                     lot_quantity
              ,xwypo.manu_date                                             manufacture_date
              ,xwypo.lot_status                                            lot_status
        FROM xxcop_wk_yoko_plan_output xwypo
        WHERE xwypo.transaction_id = cn_request_id
          AND xwypo.group_id       = gn_group_id
          AND xwypo.ship_org_code  = iv_whse_code
          AND xwypo.item_id        = in_item_id
      ) ilmv
      GROUP BY ilmv.manufacture_date
              ,ilmv.lot_status
      HAVING   SUM(ilmv.lot_quantity) > 0
      ORDER BY ilmv.manufacture_date ASC
              ,ilmv.lot_status       ASC;
--
    --鮮度条件（賞味期限基準）のロット
    CURSOR expiration_qty_cur(
              in_item_id          NUMBER
             ,iv_whse_code        VARCHAR2
             ,id_plan_date        DATE
             ,in_stock_days       NUMBER
             ,id_manufacture_date DATE
    ) IS
      SELECT NVL(SUM(ilmv.lot_quantity), 0) lot_quantity
            ,ilmv.manufacture_date          manufacture_date
            ,ilmv.lot_status                lot_status
      FROM (
        --OPMロットマスタ
        SELECT ili.loct_onhand                                             lot_quantity
              ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,ic_loct_inv ili
        WHERE ilm.item_id          = ili.item_id
          AND ilm.lot_id           = ili.lot_id
          AND ili.item_id          = in_item_id
          AND ili.whse_code        = iv_whse_code
          --最終期限ルール
          AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
          --鮮度条件
          AND id_plan_date < TO_DATE(ilm.attribute1, cv_date_format)
                           + CEIL(( TO_DATE(ilm.attribute3, cv_date_format)
                                  - TO_DATE(ilm.attribute1, cv_date_format)
                                  ) / i_cp_rec.condition_value
                             )
                           - in_stock_days
                           - gn_freshness_buffer_days
          --開始製造年月日(特別横持計画)
          AND TO_DATE(ilm.attribute1, cv_date_format) >= NVL(id_manufacture_date
                                                            ,TO_DATE(ilm.attribute1, cv_date_format))
        UNION ALL
        --入出庫予定情報ビュー
        SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) lot_quantity
              ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,xxcop_stc_trans_v xstv
        WHERE ilm.item_id          = xstv.item_id
          AND ilm.lot_id           = xstv.lot_id
          AND xstv.item_id         = in_item_id
          AND xstv.whse_code       = iv_whse_code
          AND xstv.status          = cv_xstv_status
          AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                    AND id_plan_date
                                    AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
          --最終期限ルール
          AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
          --鮮度条件
          AND id_plan_date < TO_DATE(xstv.manufacture_date, cv_date_format )
                           + CEIL(( TO_DATE(xstv.expiration_date , cv_date_format)
                                  - TO_DATE(xstv.manufacture_date, cv_date_format)
                                  ) / i_cp_rec.condition_value
                             )
                           - in_stock_days
                           - gn_freshness_buffer_days
          --開始製造年月日(特別横持計画)
          AND TO_DATE(xstv.manufacture_date, cv_date_format) >= NVL(id_manufacture_date
                                                                   ,TO_DATE(xstv.manufacture_date, cv_date_format))
        UNION ALL
        --横持計画出力ワークテーブル
        SELECT xwypo.plan_lot_qty * -1                                     lot_quantity
              ,xwypo.manu_date                                             manufacture_date
              ,xwypo.lot_status                                            lot_status
        FROM xxcop_wk_yoko_plan_output xwypo
        WHERE xwypo.transaction_id = cn_request_id
          AND xwypo.group_id       = gn_group_id
          AND xwypo.ship_org_code  = iv_whse_code
          AND xwypo.item_id        = in_item_id
      ) ilmv
      GROUP BY ilmv.manufacture_date
              ,ilmv.lot_status
      HAVING   SUM(ilmv.lot_quantity) > 0
      ORDER BY ilmv.manufacture_date ASC
              ,ilmv.lot_status       ASC;
--
    --鮮度条件（製造日基準）のロット
    CURSOR manufacture_qty_cur(
              in_item_id          NUMBER
             ,iv_whse_code        VARCHAR2
             ,id_plan_date        DATE
             ,in_stock_days       NUMBER
             ,id_manufacture_date DATE
    ) IS
      SELECT NVL(SUM(ilmv.lot_quantity), 0) lot_quantity
            ,ilmv.manufacture_date          manufacture_date
            ,ilmv.lot_status                lot_status
      FROM (
        --OPMロットマスタ
        SELECT ili.loct_onhand                                             lot_quantity
              ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,ic_loct_inv ili
            ,fnd_lookup_values flv
        WHERE ilm.item_id          = ili.item_id
          AND ilm.lot_id           = ili.lot_id
          AND ili.item_id          = in_item_id
          AND ili.whse_code        = iv_whse_code
          --最終期限ルール
          AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
          --鮮度条件
          AND id_plan_date < TO_DATE(ilm.attribute1, cv_date_format)
                           + i_cp_rec.condition_value
                           - in_stock_days
                           - gn_freshness_buffer_days
          --開始製造年月日(特別横持計画)
          AND TO_DATE(ilm.attribute1, cv_date_format) >= NVL(id_manufacture_date
                                                            ,TO_DATE(ilm.attribute1, cv_date_format))
        UNION ALL
        --入出庫予定情報ビュー
        SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) lot_quantity
              ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,xxcop_stc_trans_v xstv
            ,fnd_lookup_values flv
        WHERE ilm.item_id          = xstv.item_id
          AND ilm.lot_id           = xstv.lot_id
          AND xstv.item_id         = in_item_id
          AND xstv.whse_code       = iv_whse_code
          AND xstv.status          = cv_xstv_status
          AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                    AND id_plan_date
                                    AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
          --最終期限ルール
          AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
          --鮮度条件
          AND id_plan_date < TO_DATE(xstv.manufacture_date, cv_date_format)
                           + i_cp_rec.condition_value
                           - in_stock_days
                           - gn_freshness_buffer_days
          --開始製造年月日(特別横持計画)
          AND TO_DATE(xstv.manufacture_date, cv_date_format) >= NVL(id_manufacture_date
                                                                   ,TO_DATE(xstv.manufacture_date, cv_date_format))
        UNION ALL
        --横持計画出力ワークテーブル
        SELECT xwypo.plan_lot_qty * -1                                     lot_quantity
              ,xwypo.manu_date                                             manufacture_date
              ,xwypo.lot_status                                            lot_status
        FROM xxcop_wk_yoko_plan_output xwypo
        WHERE xwypo.transaction_id = cn_request_id
          AND xwypo.group_id       = gn_group_id
          AND xwypo.ship_org_code  = iv_whse_code
          AND xwypo.item_id        = in_item_id
      ) ilmv
      GROUP BY ilmv.manufacture_date
              ,ilmv.lot_status
      HAVING   SUM(ilmv.lot_quantity) > 0
      ORDER BY ilmv.manufacture_date ASC
              ,ilmv.lot_status       ASC;
--
    -- *** ローカル・レコード ***
    l_ml_tab                  g_manufacture_lot_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    <<xwypo_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --配送単位を決定
      fix_delivery_unit(
         io_xwypo_rec        => io_xwypo_tab(ln_xwypo_idx)
        ,ov_errbuf           => lv_errbuf
        ,ov_retcode          => lv_retcode
        ,ov_errmsg           => lv_errmsg
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        IF ( lv_errbuf IS NULL ) THEN
          RAISE internal_api_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END IF;
--
      --横持後在庫の設定
      io_xwypo_tab(ln_xwypo_idx).after_stock := io_xwypo_tab(ln_xwypo_idx).before_stock
                                              + io_xwypo_tab(ln_xwypo_idx).plan_bal_qty;
      --補充不可フラグの設定
      IF ( io_xwypo_tab(ln_xwypo_idx).after_stock
         < io_xwypo_tab(ln_xwypo_idx).max_days * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace )
      THEN
        io_xwypo_tab(ln_xwypo_idx).supp_bad_type := cv_csv_mark;
      END IF;
--
      IF ( io_xwypo_tab(ln_xwypo_idx).plan_bal_qty > 0 ) THEN
        --ロット決定の初期化
        ln_plan_quantity := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty;
        ln_lot_idx := 1;
  --
        IF ( i_cp_rec.condition_type = cv_condition_general ) THEN
          --鮮度条件（一般）
          <<general_lot_loop>>
          FOR l_lot_rec IN general_qty_cur(
                              i_xwsp_rec.item_id
                             ,i_xwsp_rec.ship_org_code
                             ,i_xwsp_rec.shipping_date
                             ,io_xwypo_tab(ln_xwypo_idx).max_days
                             ,io_xwypo_tab(ln_xwypo_idx).start_manu_date
                           ) LOOP
            IF ( l_lot_rec.lot_quantity > 0 ) THEN
              --ロットを引当
              l_ml_tab(ln_lot_idx).lot_quantity     := LEAST(ln_plan_quantity, l_lot_rec.lot_quantity);
              l_ml_tab(ln_lot_idx).manufacture_date := l_lot_rec.manufacture_date;
              l_ml_tab(ln_lot_idx).lot_status       := l_lot_rec.lot_status;
              --ロットに引当できない分を算出
              ln_plan_quantity := ln_plan_quantity - l_ml_tab(ln_lot_idx).lot_quantity;
              --ロット逆転を判定
              IF ( l_lot_rec.manufacture_date < io_xwypo_tab(ln_xwypo_idx).earliest_manu_date ) THEN
                l_ml_tab(ln_lot_idx).lot_revers := cv_csv_mark;
              END IF;
              EXIT general_lot_loop WHEN ( ln_plan_quantity <= 0 );
              ln_lot_idx := ln_lot_idx + 1;
            END IF;
          END LOOP general_lot_loop;
        END IF;
  --
        IF ( i_cp_rec.condition_type = cv_condition_expiration ) THEN
          --鮮度条件（賞味期限基準）
          <<expiration_lot_loop>>
          FOR l_lot_rec IN expiration_qty_cur(
                              i_xwsp_rec.item_id
                             ,i_xwsp_rec.ship_org_code
                             ,i_xwsp_rec.shipping_date
                             ,io_xwypo_tab(ln_xwypo_idx).max_days
                             ,io_xwypo_tab(ln_xwypo_idx).start_manu_date
                           ) LOOP
            IF ( l_lot_rec.lot_quantity > 0 ) THEN
              --ロットを引当
              l_ml_tab(ln_lot_idx).lot_quantity     := LEAST(ln_plan_quantity, l_lot_rec.lot_quantity);
              l_ml_tab(ln_lot_idx).manufacture_date := l_lot_rec.manufacture_date;
              l_ml_tab(ln_lot_idx).lot_status       := l_lot_rec.lot_status;
              --ロットに引当できない分を算出
              ln_plan_quantity := ln_plan_quantity - l_ml_tab(ln_lot_idx).lot_quantity;
              --ロット逆転を判定
              IF ( l_lot_rec.manufacture_date < io_xwypo_tab(ln_xwypo_idx).earliest_manu_date ) THEN
                l_ml_tab(ln_lot_idx).lot_revers := cv_csv_mark;
              END IF;
              EXIT expiration_lot_loop WHEN ( ln_plan_quantity <= 0 );
              ln_lot_idx := ln_lot_idx + 1;
            END IF;
          END LOOP expiration_lot_loop;
        END IF;
  --
        IF ( i_cp_rec.condition_type = cv_condition_manufacture ) THEN
          --鮮度条件（製造日基準）
          <<manufacture_lot_loop>>
          FOR l_lot_rec IN manufacture_qty_cur(
                              i_xwsp_rec.item_id
                             ,i_xwsp_rec.ship_org_code
                             ,i_xwsp_rec.shipping_date
                             ,io_xwypo_tab(ln_xwypo_idx).max_days
                             ,io_xwypo_tab(ln_xwypo_idx).start_manu_date
                           ) LOOP
            IF ( l_lot_rec.lot_quantity > 0 ) THEN
              --ロットを引当
              l_ml_tab(ln_lot_idx).lot_quantity     := LEAST(ln_plan_quantity, l_lot_rec.lot_quantity);
              l_ml_tab(ln_lot_idx).manufacture_date := l_lot_rec.manufacture_date;
              l_ml_tab(ln_lot_idx).lot_status       := l_lot_rec.lot_status;
              --ロットに引当できない分を算出
              ln_plan_quantity := ln_plan_quantity - l_ml_tab(ln_lot_idx).lot_quantity;
              --ロット逆転を判定
              IF ( l_lot_rec.manufacture_date < io_xwypo_tab(ln_xwypo_idx).earliest_manu_date ) THEN
                l_ml_tab(ln_lot_idx).lot_revers := cv_csv_mark;
              END IF;
              EXIT manufacture_lot_loop WHEN ( ln_plan_quantity <= 0 );
              ln_lot_idx := ln_lot_idx + 1;
            END IF;
          END LOOP manufacture_lot_loop;
        END IF;
      END IF;
--
      --横持計画出力ワークテーブル登録
      entry_xwypo(
         i_xwypo_rec         => io_xwypo_tab(ln_xwypo_idx)
        ,io_ml_tab           => l_ml_tab
        ,ov_errbuf           => lv_errbuf
        ,ov_retcode          => lv_retcode
        ,ov_errmsg           => lv_errmsg
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        IF ( lv_errbuf IS NULL ) THEN
          RAISE internal_api_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END IF;
      l_ml_tab.DELETE;
    END LOOP xwypo_loop;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END fix_plan_lots;
--
  /**********************************************************************************
   * Procedure Name   : proc_maximum_plan_qty
   * Description      : 計画数(最大)の計算
   ***********************************************************************************/
  PROCEDURE proc_maximum_plan_qty(
    i_xwsp_rec       IN     g_xwsp_ref_rtype,    -- 1.出荷倉庫情報
    io_xwypo_tab     IN OUT g_xwypo_ref_ttype,   -- 2.受入倉庫情報
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_maximum_plan_qty'; -- プログラム名
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
    ln_supplies_quantity      NUMBER;              --補充可能在庫数
    ln_shipping_pace          NUMBER;              --総出荷ペース
    ln_crunch_quantity        NUMBER;              --総不足在庫数
    ln_greatest_require_days  NUMBER;              --要求在庫日数の最大値
    ln_greatest_stock_days    NUMBER;              --在庫日数/要求在庫日数の最大値
    ln_less_stock_days        NUMBER;              --要求在庫日数の最小の次点
    ln_least_stock_days       NUMBER;              --要求在庫日数の最小
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_pp_tab                g_proc_plan_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --ローカル変数初期化
    ln_shipping_pace         := 0;
    ln_crunch_quantity       := 0;
    ln_greatest_require_days := 0;
    ln_greatest_stock_days   := 0;
--
    --3.3.1 移動元倉庫の補充可能在庫数を算出
    ln_supplies_quantity := i_xwsp_rec.before_stock - ( i_xwsp_rec.max_stock_days * i_xwsp_rec.shipping_pace );
--
    --3.3.2 移動先倉庫の安全在庫日数まで補充
    --移動先倉庫の不足在庫数を集計
    <<safety_require_quantity_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --初期化
      io_xwypo_tab(ln_xwypo_idx).plan_max_qty := 0;
      --要求在庫数/要求在庫日数の算出(要求=安全在庫)
      l_pp_tab(ln_xwypo_idx).require_quantity := FLOOR(io_xwypo_tab(ln_xwypo_idx).safety_days
                                                     * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                 );
      l_pp_tab(ln_xwypo_idx).require_days     := io_xwypo_tab(ln_xwypo_idx).safety_days;
      --在庫数/在庫日数の算出
      l_pp_tab(ln_xwypo_idx).stock_quantity   := LEAST(l_pp_tab(ln_xwypo_idx).require_quantity
                                                      ,io_xwypo_tab(ln_xwypo_idx).before_stock
                                                 );
      l_pp_tab(ln_xwypo_idx).stock_days       := l_pp_tab(ln_xwypo_idx).stock_quantity
                                               / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --不足在庫数/不足在庫日数の算出
      l_pp_tab(ln_xwypo_idx).crunch_quantity  := GREATEST(0, l_pp_tab(ln_xwypo_idx).require_quantity
                                                           - l_pp_tab(ln_xwypo_idx).stock_quantity
                                                 );
      --総不足在庫数/総不足在庫日数の集計
      ln_crunch_quantity                      := ln_crunch_quantity + l_pp_tab(ln_xwypo_idx).crunch_quantity;
      --総出荷ペースの集計
      ln_shipping_pace                        := ln_shipping_pace + io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --要求在庫日数の最大値を取得
      ln_greatest_require_days                := GREATEST(ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).require_days
                                                 );
      --在庫日数/要求在庫日数の最大値を取得
      ln_greatest_stock_days                  := GREATEST(ln_greatest_stock_days
                                                         ,ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).stock_days
                                                 );
    END LOOP safety_require_quantity_loop;
    --補充可能数が0以下の場合
    IF ( ln_supplies_quantity <= 0 ) THEN
      RAISE short_supply_expt;
    END IF;
    --移動先倉庫で不足在庫数がある場合
    IF ( ln_crunch_quantity > 0 ) THEN
      --不足在庫の補充
      IF ( ln_supplies_quantity >= ln_crunch_quantity ) THEN
        --補充可能在庫数が不足在庫数を満たしている場合
        --要求在庫数を計画数(最大)に設定
        <<safety_supply_loop>>
        FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
          io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                   + l_pp_tab(ln_xwypo_idx).crunch_quantity;
        END LOOP safety_supply_loop;
        ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
      ELSE
        --補充可能在庫数が不足在庫数に満たない場合
        --補充ポイント毎に計画数(最大)を設定
        <<safety_division_loop>>
        LOOP
          --初期化
          ln_less_stock_days  := ln_greatest_stock_days;
          ln_least_stock_days := ln_greatest_stock_days;
          ln_crunch_quantity  := 0;
          --在庫日数の最小、最小の次点を取得
          <<safety_least_stock_days_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --要求在庫日数に満たない場合
            IF ( l_pp_tab(ln_xwypo_idx).stock_days < l_pp_tab(ln_xwypo_idx).require_days ) THEN
              --在庫日数
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).stock_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).stock_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).stock_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).stock_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).stock_days;
              END IF;
              --要求在庫日数
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).require_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).require_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).require_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).require_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).require_days;
              END IF;
            END IF;
          END LOOP safety_least_stock_days_loop;
          --最小在庫日数と要求在庫日数の最大値が同じ場合
          --補充完了のため終了
          EXIT safety_division_loop WHEN ( ln_least_stock_days = ln_greatest_require_days );
          --次の補充ポイントまでの不足在庫数を集計
          <<safety_point_req_qty_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --在庫数が補充ポイントの次点より小さいかつ
            --要求在庫日数を超えていない場合
            IF (  ln_less_stock_days                  > l_pp_tab(ln_xwypo_idx).stock_days
              AND l_pp_tab(ln_xwypo_idx).require_days > l_pp_tab(ln_xwypo_idx).stock_days )
            THEN
              --不足在庫数の算出
              l_pp_tab(ln_xwypo_idx).crunch_quantity := CEIL(( ln_less_stock_days
                                                             - l_pp_tab(ln_xwypo_idx).stock_days )
                                                             * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        );
              --総不足在庫数の集計
              ln_crunch_quantity                     := ln_crunch_quantity
                                                      + l_pp_tab(ln_xwypo_idx).crunch_quantity;
            ELSE
              --要求在庫数を満たしているので、不足在庫数はなし
              l_pp_tab(ln_xwypo_idx).crunch_quantity := 0;
            END IF;
          END LOOP safety_point_req_qty_loop;
          --不足在庫数がない場合
          --補充完了のため終了
          EXIT safety_division_loop WHEN ( ln_crunch_quantity = 0 );
          --補充ポイントまで補充できるか判断
          IF ( ln_supplies_quantity > ln_crunch_quantity ) THEN
            --補充可能数が補充ポイントまでの不足在庫数を満たしている場合
            --要求在庫数を計画数(最大)に加算
            <<safety_point_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --計画数(最大)を加算
              io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                       + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --計画数(最大)を加算後の在庫数の算出
              l_pp_tab(ln_xwypo_idx).stock_quantity := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --計画数(最大)を加算後の在庫日数の算出
              l_pp_tab(ln_xwypo_idx).stock_days     := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
            END LOOP safety_point_supply_loop;
            --補充可能数から不足在庫数を減算
            ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
          ELSE
            --補充可能数が補充ポイントまでの不足在庫数に満たない場合
            --補充可能数を出荷ペースで按分して計画数(最大)に加算
            <<safety_pace_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              IF ( l_pp_tab(ln_xwypo_idx).crunch_quantity > 0 ) THEN
                io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                         + FLOOR(ln_supplies_quantity
                                                               * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                               / ln_shipping_pace
                                                           );
              END IF;
            END LOOP safety_pace_supply_loop;
            --補充可能数が不足したため終了
            RAISE short_supply_expt;
          END IF;
        END LOOP safety_division_loop;
      END IF;
    END IF;
--
    --ローカル変数初期化
    ln_shipping_pace         := 0;
    ln_crunch_quantity       := 0;
    ln_greatest_require_days := 0;
    ln_greatest_stock_days   := 0;
--
    --3.3.2 移動先倉庫の最大在庫日数まで補充
    --移動先倉庫の不足在庫数を集計
    <<max_require_quantity_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --要求在庫数/要求在庫日数の算出(要求=最大在庫)
      l_pp_tab(ln_xwypo_idx).require_quantity := FLOOR(( io_xwypo_tab(ln_xwypo_idx).max_days
                                                       - io_xwypo_tab(ln_xwypo_idx).safety_days )
                                                       * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                 );
      l_pp_tab(ln_xwypo_idx).require_days     := io_xwypo_tab(ln_xwypo_idx).max_days
                                               - io_xwypo_tab(ln_xwypo_idx).safety_days;
      --在庫数/在庫日数の算出
      l_pp_tab(ln_xwypo_idx).stock_quantity   := LEAST(l_pp_tab(ln_xwypo_idx).require_quantity
                                                      ,( io_xwypo_tab(ln_xwypo_idx).before_stock
                                                       + io_xwypo_tab(ln_xwypo_idx).plan_max_qty )
                                                     - ( io_xwypo_tab(ln_xwypo_idx).safety_days
                                                       * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace )
                                                 );
      l_pp_tab(ln_xwypo_idx).stock_days       := l_pp_tab(ln_xwypo_idx).stock_quantity
                                               / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --不足在庫数/不足在庫日数の算出
      l_pp_tab(ln_xwypo_idx).crunch_quantity  := GREATEST(0, l_pp_tab(ln_xwypo_idx).require_quantity
                                                           - l_pp_tab(ln_xwypo_idx).stock_quantity
                                                 );
      --総不足在庫数/総不足在庫日数の集計
      ln_crunch_quantity                      := ln_crunch_quantity + l_pp_tab(ln_xwypo_idx).crunch_quantity;
      --総出荷ペースの集計
      ln_shipping_pace                        := ln_shipping_pace + io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --要求在庫日数の最大値を取得
      ln_greatest_require_days                := GREATEST(ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).require_days
                                                 );
      --在庫日数/要求在庫日数の最大値を取得
      ln_greatest_stock_days                  := GREATEST(ln_greatest_stock_days
                                                         ,ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).stock_days
                                                 );
    END LOOP max_require_quantity_loop;
    --補充可能数が0以下の場合
    IF ( ln_supplies_quantity <= 0 ) THEN
      RAISE short_supply_expt;
    END IF;
    --移動先倉庫で不足在庫数がある場合
    IF ( ln_crunch_quantity > 0 ) THEN
      --不足在庫の補充
      IF ( ln_supplies_quantity >= ln_crunch_quantity ) THEN
        --補充可能在庫数が不足在庫数を満たしている場合
        --要求在庫数を計画数(最大)に設定
        <<max_supply_loop>>
        FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
          io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                   + l_pp_tab(ln_xwypo_idx).crunch_quantity;
        END LOOP max_supply_loop;
        ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
      ELSE
        --補充可能在庫数が不足在庫数に満たない場合
        --補充ポイント毎に計画数(最大)を設定
        <<max_division_loop>>
        LOOP
          --初期化
          ln_less_stock_days  := ln_greatest_stock_days;
          ln_least_stock_days := ln_greatest_stock_days;
          ln_crunch_quantity  := 0;
          --在庫日数の最小、最小の次点を取得
          <<max_least_stock_days_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --要求在庫日数に満たない場合
            IF ( l_pp_tab(ln_xwypo_idx).stock_days < l_pp_tab(ln_xwypo_idx).require_days ) THEN
              --在庫日数
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).stock_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).stock_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).stock_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).stock_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).stock_days;
              END IF;
              --要求在庫日数
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).require_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).require_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).require_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).require_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).require_days;
              END IF;
            END IF;
          END LOOP max_least_stock_days_loop;
          --最小在庫日数と要求在庫日数の最大値が同じ場合
          --補充完了のため終了
          EXIT max_division_loop WHEN ( ln_least_stock_days = ln_greatest_require_days );
          --次の補充ポイントまでの不足在庫数を集計
          <<max_point_req_qty_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --在庫数が補充ポイントの次点より小さいかつ
            --要求在庫日数を超えていない場合
            IF (  ln_less_stock_days                  > l_pp_tab(ln_xwypo_idx).stock_days
              AND l_pp_tab(ln_xwypo_idx).require_days > l_pp_tab(ln_xwypo_idx).stock_days )
            THEN
              --不足在庫数の算出
              l_pp_tab(ln_xwypo_idx).crunch_quantity := CEIL(( ln_less_stock_days
                                                             - l_pp_tab(ln_xwypo_idx).stock_days )
                                                             * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        );
              --総不足在庫数の集計
              ln_crunch_quantity                     := ln_crunch_quantity
                                                      + l_pp_tab(ln_xwypo_idx).crunch_quantity;
            ELSE
              --要求在庫数を満たしているので、不足在庫数はなし
              l_pp_tab(ln_xwypo_idx).crunch_quantity := 0;
            END IF;
          END LOOP max_point_req_qty_loop;
          --不足在庫数がない場合
          --補充完了のため終了
          EXIT max_division_loop WHEN ( ln_crunch_quantity = 0 );
          --補充ポイントまで補充できるか判断
          IF ( ln_supplies_quantity > ln_crunch_quantity ) THEN
            --補充可能数が補充ポイントまでの不足在庫数を満たしている場合
            --要求在庫数を計画数(最大)に加算
            <<max_point_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --計画数(最大)を加算
              io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                       + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --計画数(最大)を加算後の在庫数の算出
              l_pp_tab(ln_xwypo_idx).stock_quantity := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --計画数(最大)を加算後の在庫日数の算出
              l_pp_tab(ln_xwypo_idx).stock_days     := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
            END LOOP max_point_supply_loop;
            --補充可能数から不足在庫数を減算
            ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
          ELSE
            --補充可能数が補充ポイントまでの不足在庫数に満たない場合
            --補充可能数を出荷ペースで按分して計画数(最大)に加算
            <<max_pace_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              IF ( l_pp_tab(ln_xwypo_idx).crunch_quantity > 0 ) THEN
                io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                         + FLOOR(ln_supplies_quantity
                                                               * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                               / ln_shipping_pace
                                                           );
              END IF;
            END LOOP max_pace_supply_loop;
            --補充可能数が不足したため終了
            RAISE short_supply_expt;
          END IF;
        END LOOP max_division_loop;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN short_supply_expt THEN
      NULL;
    WHEN ZERO_DIVIDE THEN
      RAISE zero_divide_expt;
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_maximum_plan_qty;
--
  /**********************************************************************************
   * Procedure Name   : proc_minimum_plan_qty
   * Description      : 計画数(最小)の計算
   ***********************************************************************************/
  PROCEDURE proc_minimum_plan_qty(
    i_xwsp_rec       IN     g_xwsp_ref_rtype,    -- 1.出荷倉庫情報
    io_xwypo_tab     IN OUT g_xwypo_ref_ttype,   -- 2.受入倉庫情報
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_minimum_plan_qty'; -- プログラム名
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
    ln_supplies_quantity      NUMBER;              --補充可能在庫数
    ln_shipping_pace          NUMBER;              --総出荷ペース
    ln_crunch_quantity        NUMBER;              --総不足在庫数
    ln_greatest_require_days  NUMBER;              --要求在庫日数の最大値
    ln_greatest_stock_days    NUMBER;              --在庫日数/要求在庫日数の最大値
    ln_less_stock_days        NUMBER;              --要求在庫日数の最小の次点
    ln_least_stock_days       NUMBER;              --要求在庫日数の最小
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_pp_tab                g_proc_plan_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --ローカル変数初期化
    ln_shipping_pace         := 0;
    ln_crunch_quantity       := 0;
    ln_greatest_require_days := 0;
    ln_greatest_stock_days   := 0;
--
    --3.2.1 移動元倉庫の補充可能在庫数を算出
    ln_supplies_quantity := i_xwsp_rec.before_stock - ( i_xwsp_rec.max_stock_days * i_xwsp_rec.shipping_pace );
--
    --3.2.2 移動先倉庫の安全在庫日数まで補充
    --移動先倉庫の不足在庫数を集計
    <<safety_require_quantity_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --初期化
      io_xwypo_tab(ln_xwypo_idx).plan_min_qty := 0;
      --要求在庫数/要求在庫日数の算出(要求=安全在庫)
      l_pp_tab(ln_xwypo_idx).require_quantity := FLOOR(io_xwypo_tab(ln_xwypo_idx).safety_days
                                                     * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                 );
      l_pp_tab(ln_xwypo_idx).require_days     := io_xwypo_tab(ln_xwypo_idx).safety_days;
      --在庫数/在庫日数の算出
      l_pp_tab(ln_xwypo_idx).stock_quantity   := LEAST(l_pp_tab(ln_xwypo_idx).require_quantity
                                                      ,io_xwypo_tab(ln_xwypo_idx).before_stock
                                                 );
      l_pp_tab(ln_xwypo_idx).stock_days       := l_pp_tab(ln_xwypo_idx).stock_quantity
                                               / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --不足在庫数/不足在庫日数の算出
      l_pp_tab(ln_xwypo_idx).crunch_quantity  := GREATEST(0, l_pp_tab(ln_xwypo_idx).require_quantity
                                                           - l_pp_tab(ln_xwypo_idx).stock_quantity
                                                 );
      --総不足在庫数/総不足在庫日数の集計
      ln_crunch_quantity                      := ln_crunch_quantity + l_pp_tab(ln_xwypo_idx).crunch_quantity;
      --総出荷ペースの集計
      ln_shipping_pace                        := ln_shipping_pace + io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --要求在庫日数の最大値を取得
      ln_greatest_require_days                := GREATEST(ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).require_days
                                                 );
      --在庫日数/要求在庫日数の最大値を取得
      ln_greatest_stock_days                  := GREATEST(ln_greatest_stock_days
                                                         ,ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).stock_days
                                                 );
    END LOOP safety_require_quantity_loop;
    --補充可能数が0以下の場合
    IF ( ln_supplies_quantity <= 0 ) THEN
      RAISE short_supply_expt;
    END IF;
    --移動先倉庫で不足在庫数がある場合
    IF ( ln_crunch_quantity > 0 ) THEN
      --不足在庫の補充
      IF ( ln_supplies_quantity >= ln_crunch_quantity ) THEN
        --補充可能在庫数が不足在庫数を満たしている場合
        --要求在庫数を計画数(最小)に設定
        <<safety_supply_loop>>
        FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
          io_xwypo_tab(ln_xwypo_idx).plan_min_qty := io_xwypo_tab(ln_xwypo_idx).plan_min_qty
                                                   + l_pp_tab(ln_xwypo_idx).crunch_quantity;
        END LOOP safety_supply_loop;
        ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
      ELSE
        --補充可能在庫数が不足在庫数に満たない場合
        --補充ポイント毎に計画数(最小)を設定
        <<safety_division_loop>>
        LOOP
          --初期化
          ln_less_stock_days  := ln_greatest_stock_days;
          ln_least_stock_days := ln_greatest_stock_days;
          ln_crunch_quantity  := 0;
          --在庫日数の最小、最小の次点を取得
          <<safety_least_stock_days_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --要求在庫日数に満たない場合
            IF ( l_pp_tab(ln_xwypo_idx).stock_days < l_pp_tab(ln_xwypo_idx).require_days ) THEN
              --在庫日数
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).stock_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).stock_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).stock_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).stock_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).stock_days;
              END IF;
              --要求在庫日数
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).require_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).require_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).require_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).require_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).require_days;
              END IF;
            END IF;
          END LOOP safety_least_stock_days_loop;
          --最小在庫日数と要求在庫日数の最大値が同じ場合
          --補充完了のため終了
          EXIT safety_division_loop WHEN ( ln_least_stock_days = ln_greatest_require_days );
          --次の補充ポイントまでの不足在庫数を集計
          <<safety_point_req_qty_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --在庫数が補充ポイントの次点より小さいかつ
            --要求在庫日数を超えていない場合
            IF (  ln_less_stock_days                  > l_pp_tab(ln_xwypo_idx).stock_days
              AND l_pp_tab(ln_xwypo_idx).require_days > l_pp_tab(ln_xwypo_idx).stock_days )
            THEN
              --不足在庫数の算出
              l_pp_tab(ln_xwypo_idx).crunch_quantity := CEIL(( ln_less_stock_days
                                                             - l_pp_tab(ln_xwypo_idx).stock_days )
                                                             * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        );
              --総不足在庫数の集計
              ln_crunch_quantity                     := ln_crunch_quantity
                                                      + l_pp_tab(ln_xwypo_idx).crunch_quantity;
            ELSE
              --要求在庫数を満たしているので、不足在庫数はなし
              l_pp_tab(ln_xwypo_idx).crunch_quantity := 0;
            END IF;
          END LOOP safety_point_req_qty_loop;
          --不足在庫数がない場合
          --補充完了のため終了
          EXIT safety_division_loop WHEN ( ln_crunch_quantity = 0 );
          --補充ポイントまで補充できるか判断
          IF ( ln_supplies_quantity > ln_crunch_quantity ) THEN
            --補充可能数が補充ポイントまでの不足在庫数を満たしている場合
            --要求在庫数を計画数(最小)に加算
            <<safety_point_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --計画数(最小)を加算
              io_xwypo_tab(ln_xwypo_idx).plan_min_qty := io_xwypo_tab(ln_xwypo_idx).plan_min_qty
                                                       + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --計画数(最小)を加算後の在庫数の算出
              l_pp_tab(ln_xwypo_idx).stock_quantity := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --計画数(最小)を加算後の在庫日数の算出
              l_pp_tab(ln_xwypo_idx).stock_days     := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
            END LOOP safety_point_supply_loop;
            --補充可能数から不足在庫数を減算
            ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
          ELSE
            --補充可能数が補充ポイントまでの不足在庫数に満たない場合
            --補充可能数を出荷ペースで按分して計画数(最小)に加算
            <<safety_pace_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              IF ( l_pp_tab(ln_xwypo_idx).crunch_quantity > 0 ) THEN
                io_xwypo_tab(ln_xwypo_idx).plan_min_qty := io_xwypo_tab(ln_xwypo_idx).plan_min_qty
                                                         + FLOOR(ln_supplies_quantity
                                                               * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                               / ln_shipping_pace
                                                           );
              END IF;
            END LOOP safety_pace_supply_loop;
            --補充可能数が不足したため終了
            RAISE short_supply_expt;
          END IF;
        END LOOP safety_division_loop;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN short_supply_expt THEN
      NULL;
    WHEN ZERO_DIVIDE THEN
      RAISE zero_divide_expt;
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_minimum_plan_qty;
--
  /**********************************************************************************
   * Procedure Name   : proc_balance_plan_qty
   * Description      : 計画数(バランス)の計算
   ***********************************************************************************/
  PROCEDURE proc_balance_plan_qty(
    i_xwsp_rec       IN     g_xwsp_ref_rtype,    -- 1.出荷倉庫情報
    io_xwypo_tab     IN OUT g_xwypo_ref_ttype,   -- 2.受入倉庫情報
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_balance_plan_qty'; -- プログラム名
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
    ln_supplies_quantity      NUMBER;              --補充可能在庫数
    ln_shipping_pace          NUMBER;              --総出荷ペース
    ln_crunch_quantity        NUMBER;              --総不足在庫数
    ln_greatest_require_days  NUMBER;              --要求在庫日数の最大値
    ln_greatest_stock_days    NUMBER;              --在庫日数/要求在庫日数の最大値
    ln_less_stock_days        NUMBER;              --要求在庫日数の最小の次点
    ln_least_stock_days       NUMBER;              --要求在庫日数の最小
    ln_so_margin_quantity     NUMBER;              --移動元倉庫余裕在庫数
    ln_ro_margin_quantity     NUMBER;              --移動先倉庫総余裕在数
    ln_so_margin_stock_days   NUMBER;              --移動元倉庫余裕在庫日数
    ln_ro_margin_stock_days   NUMBER;              --移動先倉庫総余裕在庫日数
    ln_ro_shipping_pace       NUMBER;              --移動先倉庫総出荷ペース
    ln_balance_days           NUMBER;              --バランス在庫日数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_pp_tab                g_proc_plan_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --ローカル変数初期化
    ln_shipping_pace         := 0;
    ln_crunch_quantity       := 0;
    ln_greatest_require_days := 0;
    ln_greatest_stock_days   := 0;
    ln_ro_margin_quantity    := 0;
    ln_ro_margin_stock_days  := 0;
    ln_ro_shipping_pace      := 0;
--
    --移動元倉庫の余裕在庫数
    ln_so_margin_quantity   := i_xwsp_rec.before_stock - ( i_xwsp_rec.stock_maintenance_days
                                                         * i_xwsp_rec.shipping_pace );
    --移動元倉庫の余裕在庫日数
    ln_so_margin_stock_days := i_xwsp_rec.max_stock_days - i_xwsp_rec.stock_maintenance_days;
    <<balance_days_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --移動先倉庫の余裕在庫数
      l_pp_tab(ln_xwypo_idx).margin_quantity   := io_xwypo_tab(ln_xwypo_idx).before_stock
                                                - ( io_xwypo_tab(ln_xwypo_idx).safety_days
                                                  * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace );
      --移動先倉庫の余裕在庫日数
      l_pp_tab(ln_xwypo_idx).margin_stock_days := io_xwypo_tab(ln_xwypo_idx).max_days
                                                - io_xwypo_tab(ln_xwypo_idx).safety_days;
      --余裕在庫数の集計
      ln_ro_margin_quantity   := ln_ro_margin_quantity   + l_pp_tab(ln_xwypo_idx).margin_quantity;
      --余裕在庫日数の集計
      ln_ro_margin_stock_days := ln_ro_margin_stock_days + l_pp_tab(ln_xwypo_idx).margin_stock_days;
      --総出荷ペースの集計
      ln_ro_shipping_pace     := ln_ro_shipping_pace     + io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
    END LOOP balance_days_loop;
    --3.1.1 バランス在庫日数を算出
    ln_balance_days := ( ln_so_margin_quantity + ln_ro_margin_quantity )
                     / ( i_xwsp_rec.shipping_pace + ln_ro_shipping_pace );
    --3.1.2 移動元倉庫の補充可能在庫数を算出
    ln_supplies_quantity := ln_so_margin_quantity - GREATEST(ln_balance_days + i_xwsp_rec.stock_maintenance_days
                                                            ,i_xwsp_rec.max_stock_days )
                                                  * i_xwsp_rec.shipping_pace;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'balance_init'            || ','
                      || ln_supplies_quantity      || ','
                      || ROUND(ln_balance_days, 3) || ','
                      || ln_so_margin_quantity     || '/'
                      || i_xwsp_rec.shipping_pace  || ','
                      || ln_ro_margin_quantity     || '/'
                      || ln_ro_shipping_pace
    );
--
    --3.1.3 移動先倉庫の安全在庫日数まで補充
    --移動先倉庫の要求在庫数を集計
    <<safety_require_quantity_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --初期化
      io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := 0;
      --要求在庫数/要求在庫日数の算出(要求=安全在庫)
      l_pp_tab(ln_xwypo_idx).require_quantity := FLOOR(io_xwypo_tab(ln_xwypo_idx).safety_days
                                                     * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                 );
      l_pp_tab(ln_xwypo_idx).require_days     := io_xwypo_tab(ln_xwypo_idx).safety_days;
      --在庫数/在庫日数の算出
      l_pp_tab(ln_xwypo_idx).stock_quantity   := LEAST(l_pp_tab(ln_xwypo_idx).require_quantity
                                                      ,io_xwypo_tab(ln_xwypo_idx).before_stock
                                                 );
      l_pp_tab(ln_xwypo_idx).stock_days       := l_pp_tab(ln_xwypo_idx).stock_quantity
                                               / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --不足在庫数/不足在庫日数の算出
      l_pp_tab(ln_xwypo_idx).crunch_quantity  := GREATEST(0, l_pp_tab(ln_xwypo_idx).require_quantity
                                                           - l_pp_tab(ln_xwypo_idx).stock_quantity
                                                 );
      --総不足在庫数/総不足在庫日数の集計
      ln_crunch_quantity                      := ln_crunch_quantity + l_pp_tab(ln_xwypo_idx).crunch_quantity;
      --要求在庫日数の最大値を取得
      ln_greatest_require_days                := GREATEST(ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).require_days
                                                 );
      --在庫日数/要求在庫日数の最大値を取得
      ln_greatest_stock_days                  := GREATEST(ln_greatest_stock_days
                                                         ,ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).stock_days
                                                 );
      --デバックメッセージ出力
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => 'balance_safety_qty'                          || ':'
                        || io_xwypo_tab(ln_xwypo_idx).receipt_org_code   || ','
                        || l_pp_tab(ln_xwypo_idx).require_quantity       || '/'
                        || ROUND(l_pp_tab(ln_xwypo_idx).require_days, 2) || ','
                        || l_pp_tab(ln_xwypo_idx).stock_quantity         || '/'
                        || ROUND(l_pp_tab(ln_xwypo_idx).stock_days, 2)   || '-'
                        || io_xwypo_tab(ln_xwypo_idx).under_lvl_pace     || '-'
                        || ln_crunch_quantity                            || ','
                        || ROUND(ln_greatest_require_days, 2)            || ','
                        || ROUND(ln_greatest_stock_days, 2)
      );
    END LOOP safety_require_quantity_loop;
    --補充可能数が0以下の場合
    IF ( ln_supplies_quantity <= 0 ) THEN
      RAISE short_supply_expt;
    END IF;
    --移動先倉庫で不足在庫数がある場合
    IF ( ln_crunch_quantity > 0 ) THEN
      --不足在庫の補充
      IF ( ln_supplies_quantity >= ln_crunch_quantity ) THEN
        --補充可能在庫数が不足在庫数を満たしている場合
        --要求在庫数を計画数(バランス)に設定
        <<safety_supply_loop>>
        FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
          io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                   + l_pp_tab(ln_xwypo_idx).crunch_quantity;
        END LOOP safety_supply_loop;
        ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
      ELSE
        --補充可能在庫数が不足在庫数に満たない場合
        --補充ポイント毎に計画数(バランス)を設定
        <<safety_division_loop>>
        LOOP
          --初期化
          ln_less_stock_days  := ln_greatest_stock_days;
          ln_least_stock_days := ln_greatest_stock_days;
          ln_crunch_quantity  := 0;
          --在庫日数の最小、最小の次点を取得
          <<safety_least_stock_days_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --要求在庫日数に満たない場合
            IF ( l_pp_tab(ln_xwypo_idx).stock_days < l_pp_tab(ln_xwypo_idx).require_days ) THEN
              --在庫日数
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).stock_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).stock_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).stock_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).stock_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).stock_days;
              END IF;
              --要求在庫日数
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).require_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).require_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).require_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).require_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).require_days;
              END IF;
            END IF;
          END LOOP safety_least_stock_days_loop;
          --最小在庫日数と要求在庫日数の最大値が同じ場合
          --補充完了のため終了
          EXIT safety_division_loop WHEN ( ln_least_stock_days = ln_greatest_require_days );
          --次の補充ポイントまでの不足在庫数を集計
          <<safety_point_req_qty_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --在庫数が補充ポイントの次点より小さいかつ
            --要求在庫日数を超えていない場合
            IF (  ln_less_stock_days                  > l_pp_tab(ln_xwypo_idx).stock_days
              AND l_pp_tab(ln_xwypo_idx).require_days > l_pp_tab(ln_xwypo_idx).stock_days )
            THEN
              --不足在庫数の算出
              l_pp_tab(ln_xwypo_idx).crunch_quantity := CEIL(( ln_less_stock_days
                                                             - l_pp_tab(ln_xwypo_idx).stock_days )
                                                             * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        );
              --総不足在庫数の集計
              ln_crunch_quantity                     := ln_crunch_quantity
                                                      + l_pp_tab(ln_xwypo_idx).crunch_quantity;
            ELSE
              --要求在庫数を満たしているので、不足在庫数はなし
              l_pp_tab(ln_xwypo_idx).crunch_quantity := 0;
            END IF;
          END LOOP safety_point_req_qty_loop;
          --不足在庫数がない場合
          --補充完了のため終了
          EXIT safety_division_loop WHEN ( ln_crunch_quantity = 0 );
          --補充ポイントまで補充できるか判断
          IF ( ln_supplies_quantity > ln_crunch_quantity ) THEN
            --補充可能数が補充ポイントまでの不足在庫数を満たしている場合
            --要求在庫数を計画数(バランス)に加算
            <<safety_point_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --計画数(バランス)を加算
              io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                       + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --計画数(バランス)を加算後の在庫数の算出
              l_pp_tab(ln_xwypo_idx).stock_quantity := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --計画数(バランス)を加算後の在庫日数の算出
              l_pp_tab(ln_xwypo_idx).stock_days     := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
            END LOOP safety_point_supply_loop;
            --補充可能数から不足在庫数を減算
            ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
          ELSE
            --補充可能数が補充ポイントまでの不足在庫数に満たない場合
            IF ( ln_balance_days <= ln_so_margin_stock_days ) THEN
              --3.1.4.1 余裕在庫日数≦移動元倉庫の余裕在庫日数の場合
              --補充可能数を移動先倉庫の出荷ペースで按分して計画数(バランス)に加算
              ln_shipping_pace := ln_ro_shipping_pace;
            ELSE
              --3.1.4.2 余裕在庫日数＞移動元倉庫の余裕在庫日数の場合
              --補充可能数を移動元倉庫、移動先倉庫の出荷ペースで按分して計画数(バランス)に加算
              ln_shipping_pace := i_xwsp_rec.shipping_pace + ln_ro_shipping_pace;
            END IF;
            --補充可能数を出荷ペースで按分して計画数(バランス)に加算
            <<safety_pace_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              IF ( l_pp_tab(ln_xwypo_idx).crunch_quantity > 0 ) THEN
                io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                         + FLOOR(ln_supplies_quantity
                                                               * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                               / ln_shipping_pace
                                                           );
              END IF;
            END LOOP safety_pace_supply_loop;
            --補充可能数が不足したため終了
            RAISE short_supply_expt;
          END IF;
        END LOOP safety_division_loop;
      END IF;
    END IF;
--
    --ローカル変数初期化
    ln_shipping_pace         := 0;
    ln_crunch_quantity       := 0;
    ln_greatest_require_days := 0;
    ln_greatest_stock_days   := 0;
--
    --3.1.4 移動先倉庫のバランス在庫日数まで補充
    --移動先倉庫の不足在庫数を集計
    <<max_require_quantity_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --要求在庫数/要求在庫日数の算出(要求数=バランス在庫)
      l_pp_tab(ln_xwypo_idx).require_quantity := FLOOR(LEAST(ln_balance_days, l_pp_tab(ln_xwypo_idx).margin_stock_days)
                                                     * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                 );
      l_pp_tab(ln_xwypo_idx).require_days     := LEAST(ln_balance_days, l_pp_tab(ln_xwypo_idx).margin_stock_days);
      --在庫数/在庫日数の算出
      l_pp_tab(ln_xwypo_idx).stock_quantity   := LEAST(l_pp_tab(ln_xwypo_idx).require_quantity
                                                      ,( io_xwypo_tab(ln_xwypo_idx).before_stock
                                                       + io_xwypo_tab(ln_xwypo_idx).plan_bal_qty )
                                                     - ( io_xwypo_tab(ln_xwypo_idx).safety_days
                                                       * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace )
                                                 );
      l_pp_tab(ln_xwypo_idx).stock_days       := l_pp_tab(ln_xwypo_idx).stock_quantity
                                               / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --不足在庫数/不足在庫日数の算出
      l_pp_tab(ln_xwypo_idx).crunch_quantity  := GREATEST(0, l_pp_tab(ln_xwypo_idx).require_quantity
                                                           - l_pp_tab(ln_xwypo_idx).stock_quantity
                                                 );
      --総不足在庫数/総不足在庫日数の集計
      ln_crunch_quantity                      := ln_crunch_quantity + l_pp_tab(ln_xwypo_idx).crunch_quantity;
      --総出荷ペースの集計
      ln_shipping_pace                        := ln_shipping_pace + io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --要求在庫日数の最大値を取得
      ln_greatest_require_days                := GREATEST(ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).require_days
                                                 );
      --在庫日数/要求在庫日数の最大値を取得
      ln_greatest_stock_days                  := GREATEST(ln_greatest_stock_days
                                                         ,ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).stock_days
                                                 );
      --デバックメッセージ出力
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => 'balance_max_qty   '                          || ':'
                        || io_xwypo_tab(ln_xwypo_idx).receipt_org_code   || ','
                        || l_pp_tab(ln_xwypo_idx).require_quantity       || '/'
                        || ROUND(l_pp_tab(ln_xwypo_idx).require_days, 2) || ','
                        || l_pp_tab(ln_xwypo_idx).stock_quantity         || '/'
                        || ROUND(l_pp_tab(ln_xwypo_idx).stock_days, 2)   || '-'
                        || io_xwypo_tab(ln_xwypo_idx).under_lvl_pace     || '-'
                        || ln_crunch_quantity                            || ','
                        || ROUND(ln_greatest_require_days, 2)            || ','
                        || ROUND(ln_greatest_stock_days, 2)
      );
    END LOOP max_require_quantity_loop;
    --補充可能数が0以下の場合
    IF ( ln_supplies_quantity <= 0 ) THEN
      RAISE short_supply_expt;
    END IF;
    --移動先倉庫で不足在庫数がある場合
    IF ( ln_crunch_quantity > 0 ) THEN
      --不足在庫の補充
      IF ( ln_supplies_quantity >= ln_crunch_quantity ) THEN
        --補充可能在庫数が不足在庫数を満たしている場合
        --要求在庫数を計画数(バランス)に設定
        <<max_supply_loop>>
        FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
          io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                   + l_pp_tab(ln_xwypo_idx).crunch_quantity;
        END LOOP max_supply_loop;
        ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
      ELSE
        --補充可能在庫数が不足在庫数に満たない場合
        --補充ポイント毎に計画数(バランス)を設定
        <<max_division_loop>>
        LOOP
          --初期化
          ln_less_stock_days  := ln_greatest_stock_days;
          ln_least_stock_days := ln_greatest_stock_days;
          ln_crunch_quantity  := 0;
          --在庫日数の最小、最小の次点を取得
          <<max_least_stock_days_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --要求在庫日数に満たない場合
            IF ( l_pp_tab(ln_xwypo_idx).stock_days < l_pp_tab(ln_xwypo_idx).require_days ) THEN
              --在庫日数
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).stock_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).stock_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).stock_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).stock_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).stock_days;
              END IF;
              --要求在庫日数
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).require_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).require_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).require_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).require_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).require_days;
              END IF;
            END IF;
          END LOOP max_least_stock_days_loop;
          --最小在庫日数と要求在庫日数の最大値が同じ場合
          --補充完了のため終了
          EXIT max_division_loop WHEN ( ln_least_stock_days = ln_greatest_require_days );
          --次の補充ポイントまでの不足在庫数を集計
          <<max_point_req_qty_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --在庫数が補充ポイントの次点より小さいかつ
            --要求在庫日数を超えていない場合
            IF (  ln_less_stock_days                  > l_pp_tab(ln_xwypo_idx).stock_days
              AND l_pp_tab(ln_xwypo_idx).require_days > l_pp_tab(ln_xwypo_idx).stock_days )
            THEN
              --不足在庫数の算出
              l_pp_tab(ln_xwypo_idx).crunch_quantity := CEIL(( ln_less_stock_days
                                                             - l_pp_tab(ln_xwypo_idx).stock_days )
                                                             * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        );
              --総不足在庫数の集計
              ln_crunch_quantity                     := ln_crunch_quantity
                                                      + l_pp_tab(ln_xwypo_idx).crunch_quantity;
            ELSE
              --要求在庫数を満たしているので、不足在庫数はなし
              l_pp_tab(ln_xwypo_idx).crunch_quantity := 0;
            END IF;
          END LOOP max_point_req_qty_loop;
          --不足在庫数がない場合
          --補充完了のため終了
          EXIT max_division_loop WHEN ( ln_crunch_quantity = 0 );
          --補充ポイントまで補充できるか判断
          IF ( ln_supplies_quantity > ln_crunch_quantity ) THEN
            --補充可能数が補充ポイントまでの不足在庫数を満たしている場合
            --要求在庫数を計画数(バランス)に加算
            <<max_point_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --計画数(バランス)を加算
              io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                       + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --計画数(バランス)を加算後の在庫数の算出
              l_pp_tab(ln_xwypo_idx).stock_quantity := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --計画数(バランス)を加算後の在庫日数の算出
              l_pp_tab(ln_xwypo_idx).stock_days     := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
            END LOOP max_point_supply_loop;
            --補充可能数から不足在庫数を減算
            ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
          ELSE
            --補充可能数が補充ポイントまでの不足在庫数に満たない場合
            IF ( ln_balance_days <= ln_so_margin_stock_days ) THEN
              --3.1.4.1 余裕在庫日数≦移動元倉庫の余裕在庫日数の場合
              --補充可能数を移動先倉庫の出荷ペースで按分して計画数(バランス)に加算
              ln_shipping_pace := ln_ro_shipping_pace;
            ELSE
              --3.1.4.2 余裕在庫日数＞移動元倉庫の余裕在庫日数の場合
              --補充可能数を移動元倉庫、移動先倉庫の出荷ペースで按分して計画数(バランス)に加算
              ln_shipping_pace := i_xwsp_rec.shipping_pace + ln_ro_shipping_pace;
            END IF;
            --補充可能数を出荷ペースで按分して計画数(バランス)に加算
            <<max_pace_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --デバックメッセージ出力
              xxcop_common_pkg.put_debug_message(
                 iov_debug_mode => gv_debug_mode
                ,iv_value       => 'div_qty'                                   || ':'
                                || io_xwypo_tab(ln_xwypo_idx).receipt_org_code || ','
                                || ln_supplies_quantity                        || ','
                                || io_xwypo_tab(ln_xwypo_idx).under_lvl_pace   || ','
                                || ln_shipping_pace                            || ','
                                || io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
              );
              IF ( l_pp_tab(ln_xwypo_idx).crunch_quantity > 0 ) THEN
                io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                         + FLOOR(ln_supplies_quantity
                                                               * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                               / ln_shipping_pace
                                                           );
              END IF;
            END LOOP max_pace_supply_loop;
            --補充可能数が不足したため終了
            RAISE short_supply_expt;
          END IF;
        END LOOP max_division_loop;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN short_supply_expt THEN
      NULL;
    WHEN ZERO_DIVIDE THEN
      RAISE zero_divide_expt;
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_balance_plan_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_quantity
   * Description      : 在庫数の取得
   ***********************************************************************************/
  PROCEDURE get_stock_quantity(
    in_item_id       IN     ic_loct_inv.item_id%TYPE,
    iv_whse_code     IN     ic_loct_inv.whse_code%TYPE,
    id_plan_date     IN     xxcop_wk_yoko_plan_output.receipt_date%TYPE,
    in_stock_days    IN     xxcop_wk_yoko_plan_output.max_days%TYPE,
    i_cp_rec         IN     g_condition_priority_rtype,
    on_stock_quantity   OUT xxcop_wk_yoko_plan_output.before_stock%TYPE,
    od_manufacture_date OUT xxcop_wk_yoko_plan_output.manu_date%TYPE,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_quantity'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --鮮度条件（一般）
    IF ( i_cp_rec.condition_type = cv_condition_general ) THEN
      SELECT NVL(SUM(stock_quantity), 0)        stock_quantity
            ,MIN(manufacture_date)              manufacture_date
      INTO on_stock_quantity
          ,od_manufacture_date
      FROM (
        SELECT NVL(SUM(ilmv.stock_quantity), 0) stock_quantity
              ,ilmv.manufacture_date            manufacture_date
        FROM (
          --OPMロットマスタ
          SELECT ili.loct_onhand                                             stock_quantity
                ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
          FROM ic_lots_mst ilm
              ,ic_loct_inv ili
          WHERE ilm.item_id          = ili.item_id
            AND ilm.lot_id           = ili.lot_id
            AND ili.item_id          = in_item_id
            AND ili.whse_code        = iv_whse_code
            --最終期限ルール
            AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --入出庫予定情報ビュー
          SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) stock_quantity
                ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
          FROM xxcop_stc_trans_v xstv
          WHERE xstv.item_id         = in_item_id
            AND xstv.whse_code       = iv_whse_code
            AND xstv.status          = cv_xstv_status
            AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                      AND id_plan_date
                                      AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
            --最終期限ルール
            AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --横持計画出力ワークテーブル
          SELECT xwypo.plan_lot_qty * -1                                     stock_quantity
                ,xwypo.manu_date                                             manufacture_date
          FROM xxcop_wk_yoko_plan_output xwypo
          WHERE xwypo.transaction_id = cn_request_id
            AND xwypo.group_id       = gn_group_id
            AND xwypo.ship_org_code  = iv_whse_code
            AND xwypo.item_id        = in_item_id
        ) ilmv
        GROUP BY ilmv.manufacture_date
        HAVING   SUM(ilmv.stock_quantity) > 0
        ORDER BY ilmv.manufacture_date ASC
      );
    END IF;
    --鮮度条件（賞味期限基準）
    IF ( i_cp_rec.condition_type = cv_condition_expiration ) THEN
      SELECT NVL(SUM(stock_quantity), 0)        stock_quantity
            ,MIN(manufacture_date)              manufacture_date
      INTO on_stock_quantity
          ,od_manufacture_date
      FROM (
        SELECT NVL(SUM(ilmv.stock_quantity), 0) stock_quantity
              ,ilmv.manufacture_date            manufacture_date
        FROM (
          --OPMロットマスタ
          SELECT ili.loct_onhand                                             stock_quantity
                ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
          FROM ic_lots_mst ilm
              ,ic_loct_inv ili
          WHERE ilm.item_id          = ili.item_id
            AND ilm.lot_id           = ili.lot_id
            AND ili.item_id          = in_item_id
            AND ili.whse_code        = iv_whse_code
            --最終期限ルール
            AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
            --鮮度条件
            AND id_plan_date < TO_DATE(ilm.attribute1, cv_date_format)
                             + CEIL(( TO_DATE(ilm.attribute3, cv_date_format)
                                    - TO_DATE(ilm.attribute1, cv_date_format)
                                    ) / i_cp_rec.condition_value
                               )
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --入出庫予定情報ビュー
          SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) stock_quantity
                ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
          FROM xxcop_stc_trans_v xstv
          WHERE xstv.item_id         = in_item_id
            AND xstv.whse_code       = iv_whse_code
            AND xstv.status          = cv_xstv_status
            AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                      AND id_plan_date
                                      AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
            --最終期限ルール
            AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
            --鮮度条件
            AND id_plan_date < TO_DATE(xstv.manufacture_date, cv_date_format)
                             + CEIL(( TO_DATE(xstv.expiration_date , cv_date_format)
                                    - TO_DATE(xstv.manufacture_date, cv_date_format)
                                    ) / i_cp_rec.condition_value
                               )
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --横持計画出力ワークテーブル
          SELECT xwypo.plan_lot_qty * -1                                     stock_quantity
                ,xwypo.manu_date                                             manufacture_date
          FROM xxcop_wk_yoko_plan_output xwypo
          WHERE xwypo.transaction_id = cn_request_id
            AND xwypo.group_id       = gn_group_id
            AND xwypo.ship_org_code  = iv_whse_code
            AND xwypo.item_id        = in_item_id
        ) ilmv
        GROUP BY ilmv.manufacture_date
        HAVING   SUM(ilmv.stock_quantity) > 0
        ORDER BY ilmv.manufacture_date ASC
      );
    END IF;
    --鮮度条件（製造日基準）
    IF ( i_cp_rec.condition_type = cv_condition_manufacture ) THEN
      SELECT NVL(SUM(stock_quantity), 0)        stock_quantity
            ,MIN(manufacture_date)              manufacture_date
      INTO on_stock_quantity
          ,od_manufacture_date
      FROM (
        SELECT NVL(SUM(ilmv.stock_quantity), 0) stock_quantity
              ,ilmv.manufacture_date            manufacture_date
        FROM (
          --OPMロットマスタ
          SELECT ili.loct_onhand                                             stock_quantity
                ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
          FROM ic_lots_mst ilm
              ,ic_loct_inv ili
          WHERE ilm.item_id          = ili.item_id
            AND ilm.lot_id           = ili.lot_id
            AND ili.item_id          = in_item_id
            AND ili.whse_code        = iv_whse_code
            --最終期限ルール
            AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
            --鮮度条件
            AND id_plan_date < TO_DATE(ilm.attribute1, cv_date_format)
                             + i_cp_rec.condition_value
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --入出庫予定情報ビュー
          SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) stock_quantity
                ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
          FROM xxcop_stc_trans_v xstv
          WHERE xstv.item_id     = in_item_id
            AND xstv.whse_code   = iv_whse_code
            AND xstv.status      = cv_xstv_status
            AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                      AND id_plan_date
                                      AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
            --最終期限ルール
            AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
            --鮮度条件
            AND id_plan_date < TO_DATE(xstv.manufacture_date, cv_date_format)
                             + i_cp_rec.condition_value
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --横持計画出力ワークテーブル
          SELECT xwypo.plan_lot_qty * -1                                     stock_quantity
                ,xwypo.manu_date                                             manufacture_date
          FROM xxcop_wk_yoko_plan_output xwypo
          WHERE xwypo.transaction_id = cn_request_id
            AND xwypo.group_id       = gn_group_id
            AND xwypo.ship_org_code  = iv_whse_code
            AND xwypo.item_id        = in_item_id
        ) ilmv
        GROUP BY ilmv.manufacture_date
        HAVING   SUM(ilmv.stock_quantity) > 0
        ORDER BY ilmv.manufacture_date ASC
      );
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      on_stock_quantity   := 0;
      od_manufacture_date := NULL;
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_stock_quantity;
--
  /**********************************************************************************
   * Procedure Name   : entry_xwsp
   * Description      : 物流計画ワークテーブル登録
   ***********************************************************************************/
  PROCEDURE entry_xwsp(
    i_xwsp_rec       IN     xxcop_wk_ship_planning%ROWTYPE,
    i_fc_tab         IN     g_freshness_condition_ttype,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xwsp'; -- プログラム名
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
    ln_condition_idx          NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_xwsp_rec                xxcop_wk_ship_planning%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    BEGIN
      --要求固定値の設定
      l_xwsp_rec                            := i_xwsp_rec;
      l_xwsp_rec.transaction_id             := cn_request_id;
      l_xwsp_rec.created_by                 := cn_created_by;
      l_xwsp_rec.creation_date              := cd_creation_date;
      l_xwsp_rec.last_updated_by            := cn_last_updated_by;
      l_xwsp_rec.last_update_date           := cd_last_update_date;
      l_xwsp_rec.last_update_login          := cn_last_update_login;
      l_xwsp_rec.request_id                 := cn_request_id;
      l_xwsp_rec.program_application_id     := cn_program_application_id;
      l_xwsp_rec.program_id                 := cn_program_id;
      l_xwsp_rec.program_update_date        := cd_program_update_date;
      <<condition_loop>>
      FOR ln_priority_idx IN i_fc_tab.FIRST .. i_fc_tab.LAST LOOP
        IF ( i_fc_tab(ln_priority_idx).freshness_condition IS NOT NULL ) THEN
          l_xwsp_rec.freshness_priority     := ln_priority_idx;
          l_xwsp_rec.freshness_condition    := i_fc_tab(ln_priority_idx).freshness_condition;
          l_xwsp_rec.stock_maintenance_days := i_fc_tab(ln_priority_idx).stock_maintenance_days;
          l_xwsp_rec.max_stock_days         := i_fc_tab(ln_priority_idx).max_stock_days;
          --物流計画ワークテーブル登録
          INSERT INTO xxcop_wk_ship_planning VALUES l_xwsp_rec;
        END IF;
      END LOOP condition_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwsp
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END entry_xwsp;
--
  /**********************************************************************************
   * Procedure Name   : proc_ship_pace
   * Description      : 出荷ペースの計算
   ***********************************************************************************/
  PROCEDURE proc_ship_pace(
    io_xwsp_rec      IN OUT xxcop_wk_ship_planning%ROWTYPE,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ship_pace'; -- プログラム名
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
    ld_calender_from                 DATE;
    ld_calender_to                   DATE;
    ln_shipped_qty                   NUMBER;     --出荷数
    ln_working_days                  NUMBER;     --稼動日数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --初期化
    io_xwsp_rec.shipping_pace := 0;
--
    BEGIN
      IF   ( gv_plan_type = cv_plan_type_shipped AND io_xwsp_rec.shipping_type = cv_plan_type_shipped )
        OR ( gv_plan_type = cv_plan_type_shipped AND io_xwsp_rec.shipping_type IS NULL                )
        OR ( gv_plan_type IS NULL                AND io_xwsp_rec.shipping_type = cv_plan_type_shipped )
        OR ( gv_plan_type IS NULL                AND io_xwsp_rec.shipping_type IS NULL                )
      THEN
        ld_calender_from := gd_shipment_from;
        ld_calender_to   := gd_shipment_to;
        --出荷実績を取得
        xxcop_common_pkg2.get_num_of_shipped(
           iv_organization_code  => io_xwsp_rec.receipt_org_code
          ,iv_item_no            => io_xwsp_rec.item_no
          ,id_plan_date_from     => ld_calender_from
          ,id_plan_date_to       => ld_calender_to
          ,on_quantity           => ln_shipped_qty
          ,ov_errbuf             => lv_errbuf
          ,ov_retcode            => lv_retcode
          ,ov_errmsg             => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
        --移動先倉庫の稼動日数を取得
        xxcop_common_pkg2.get_working_days(
           in_organization_id    => io_xwsp_rec.receipt_org_id
          ,id_from_date          => ld_calender_from
          ,id_to_date            => ld_calender_to
          ,on_working_days       => ln_working_days
          ,ov_errbuf             => lv_errbuf
          ,ov_retcode            => lv_retcode
          ,ov_errmsg             => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        IF ( ln_working_days = 0 ) THEN
          RAISE no_working_days_expt;
        END IF;
        --出荷ペースを算出
        io_xwsp_rec.shipping_pace := ROUND(ln_shipped_qty / ln_working_days);
      END IF;
      IF   ( gv_plan_type = cv_plan_type_fgorcate AND io_xwsp_rec.shipping_type = cv_plan_type_fgorcate )
        OR ( gv_plan_type = cv_plan_type_fgorcate AND io_xwsp_rec.shipping_type IS NULL                 )
        OR ( gv_plan_type IS NULL                 AND io_xwsp_rec.shipping_type = cv_plan_type_fgorcate )
      THEN
        ld_calender_from := gd_forcast_from;
        ld_calender_to   := gd_forcast_to;
        --出荷予測を取得
        xxcop_common_pkg2.get_num_of_forcast(
           in_organization_id    => io_xwsp_rec.receipt_org_id
          ,in_inventory_item_id  => io_xwsp_rec.inventory_item_id
          ,id_plan_date_from     => ld_calender_from
          ,id_plan_date_to       => ld_calender_to
          ,on_quantity           => ln_shipped_qty
          ,ov_errbuf             => lv_errbuf
          ,ov_retcode            => lv_retcode
          ,ov_errmsg             => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
        --移動先倉庫の稼動日数を取得
        xxcop_common_pkg2.get_working_days(
           in_organization_id    => io_xwsp_rec.receipt_org_id
          ,id_from_date          => ld_calender_from
          ,id_to_date            => ld_calender_to
          ,on_working_days       => ln_working_days
          ,ov_errbuf             => lv_errbuf
          ,ov_retcode            => lv_retcode
          ,ov_errmsg             => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        IF ( ln_working_days = 0 ) THEN
          RAISE no_working_days_expt;
        END IF;
        --出荷ペースを算出
        io_xwsp_rec.shipping_pace := ROUND(ln_shipped_qty / ln_working_days);
      END IF;
    EXCEPTION
      WHEN no_working_days_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00056
                       ,iv_token_name1  => cv_msg_00056_token_1
                       ,iv_token_value1 => TO_CHAR(ld_calender_from, cv_date_format)
                       ,iv_token_name2  => cv_msg_00056_token_2
                       ,iv_token_value2 => TO_CHAR(ld_calender_to, cv_date_format)
                     );
        RAISE internal_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_ship_pace;
--
  /**********************************************************************************
   * Procedure Name   : chk_route_prereq
   * Description      : 経路の前提条件チェック
   ***********************************************************************************/
  PROCEDURE chk_route_prereq(
    i_xwsp_rec       IN     xxcop_wk_ship_planning%ROWTYPE,
    i_fc_tab         IN     g_freshness_condition_ttype,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_route_prereq'; -- プログラム名
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
    ln_priority_idx           NUMBER;
    ln_condition_cnt          NUMBER;
    lv_item_name              VARCHAR2(100);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --基本横持計画または特別横持計画の場合
    IF i_xwsp_rec.assignment_set_type IN (cv_base_plan, cv_custom_plan) THEN
      BEGIN
        ln_condition_cnt := 0;
        <<priority_loop>>
        FOR ln_priority_idx IN i_fc_tab.FIRST .. i_fc_tab.LAST LOOP
          --鮮度条件
          IF ( i_fc_tab(ln_priority_idx).freshness_condition IS NOT NULL ) THEN
            --在庫維持日数
            IF ( NVL(i_fc_tab(ln_priority_idx).stock_maintenance_days, 0) <= 0 ) THEN
              lv_item_name := cv_msg_10041_value_1;
              RAISE stock_days_expt;
            END IF;
            --最大在庫日数
            IF ( NVL(i_fc_tab(ln_priority_idx).max_stock_days, 0) <= 0 ) THEN
              lv_item_name := cv_msg_10041_value_2;
              RAISE stock_days_expt;
            END IF;
            ln_condition_cnt := ln_condition_cnt + 1;
          END IF;
        END LOOP priority_loop;
        --鮮度条件が登録されていない場合
        IF ( ln_condition_cnt = 0 ) THEN
          RAISE no_condition_expt;
        END IF;
      EXCEPTION
        WHEN stock_days_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_10041
                         ,iv_token_name1  => cv_msg_10041_token_1
                         ,iv_token_value1 => lv_item_name
                         ,iv_token_name2  => cv_msg_10041_token_1
                         ,iv_token_value2 => i_xwsp_rec.receipt_org_code
                       );
          RAISE internal_api_expt;
        WHEN no_condition_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_10038
                         ,iv_token_name1  => cv_msg_10038_token_1
                         ,iv_token_value1 => i_xwsp_rec.receipt_org_code
                       );
          RAISE internal_api_expt;
      END;
    END IF;
    --特別横持計画の場合
    IF i_xwsp_rec.assignment_set_type IN (cv_custom_plan) THEN
      --開始製造年月日
      IF ( i_xwsp_rec.manufacture_date IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_10039
                       ,iv_token_name1  => cv_msg_10039_token_1
                       ,iv_token_value1 => i_xwsp_rec.receipt_org_code
                     );
        RAISE internal_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_route_prereq;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_route
   * Description      : 出荷倉庫経路取得
   ***********************************************************************************/
  PROCEDURE get_ship_route(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_route'; -- プログラム名
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
    ln_condition_idx          NUMBER;
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_START
    ln_exists                 NUMBER;
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_END
--
    -- *** ローカル・カーソル ***
    --出荷倉庫を取得
    CURSOR xwsp_ship_cur IS
      SELECT xwsp.inventory_item_id
            ,xwsp.item_id
            ,xwsp.item_no
            ,xwsp.item_name
            ,xwsp.ship_org_id
            ,xwsp.ship_org_code
            ,xwsp.ship_org_name
      FROM xxcop_wk_ship_planning xwsp
      WHERE xwsp.transaction_id = cn_request_id
      GROUP BY xwsp.inventory_item_id
              ,xwsp.item_id
              ,xwsp.item_no
              ,xwsp.item_name
              ,xwsp.ship_org_id
              ,xwsp.ship_org_code
              ,xwsp.ship_org_name;
--
    --出荷倉庫経路を取得
    CURSOR msr_ship_cur(
              in_inventory_item_id NUMBER
             ,in_organization_id   NUMBER
    ) IS
      SELECT source_organization_id
            ,assignment_set_type
            ,assignment_type
            ,sourcing_rule_type
            ,sourcing_rule_name
            ,shipping_type
            ,freshness_condition1
            ,stock_maintenance_days1
            ,max_stock_days1
            ,freshness_condition2
            ,stock_maintenance_days2
            ,max_stock_days2
            ,freshness_condition3
            ,stock_maintenance_days3
            ,max_stock_days3
            ,freshness_condition4
            ,stock_maintenance_days4
            ,max_stock_days4
      FROM (
        WITH msr_vw AS (
          --全経路(基本横持計画、出荷計画区分ダミー経路)
          SELECT msso.source_organization_id             source_organization_id --移動元倉庫ID
                ,msro.receipt_organization_id           receipt_organization_id --移動先組織ID
                ,mas.assignment_set_name                    assignment_set_name --割当セット名
                ,NVL(msa.organization_id, in_organization_id)   organization_id --組織
                ,mas.attribute1                             assignment_set_type --割当セット区分
                ,msa.assignment_type                            assignment_type --割当先タイプ
                ,msa.sourcing_rule_type                      sourcing_rule_type --ソースルールタイプ
                ,msr.sourcing_rule_name                      sourcing_rule_name --ソースルール名
                ,msa.attribute1                                      attribute1 --
                ,msa.attribute2                                      attribute2 --
                ,msa.attribute3                                      attribute3 --
                ,msa.attribute4                                      attribute4 --
                ,msa.attribute5                                      attribute5 --
                ,msa.attribute6                                      attribute6 --
                ,msa.attribute7                                      attribute7 --
                ,msa.attribute8                                      attribute8 --
                ,msa.attribute9                                      attribute9 --
                ,msa.attribute10                                    attribute10 --
                ,msa.attribute11                                    attribute11 --
                ,msa.attribute12                                    attribute12 --
                ,msa.attribute13                                    attribute13 --
                ,flv2.description                          assign_type_priority --割当先タイプ優先度
          FROM mrp_assignment_sets mas
              ,mrp_sr_assignments  msa
              ,mrp_sourcing_rules  msr
              ,mrp_sr_receipt_org  msro
              ,mrp_sr_source_org   msso
              ,fnd_lookup_values   flv1
              ,fnd_lookup_values   flv2
          WHERE mas.assignment_set_id       = msa.assignment_set_id
            AND mas.attribute1             IN (cv_base_plan)
            AND msr.sourcing_rule_id        = msa.sourcing_rule_id
            AND msro.sourcing_rule_id       = msr.sourcing_rule_id
            AND msro.sr_receipt_id          = msso.sr_receipt_id
            AND cd_sysdate BETWEEN NVL(msro.effective_date, cd_sysdate)
                               AND NVL(msro.disable_date, cd_sysdate)
            AND flv1.lookup_type            = cv_flv_assignment_name
            AND flv1.lookup_code            = mas.assignment_set_name
            AND flv1.language               = cv_lang
            AND flv1.source_lang            = cv_lang
            AND flv1.enabled_flag           = cv_enable
            AND cd_sysdate BETWEEN NVL(flv1.start_date_active, cd_sysdate)
                               AND NVL(flv1.end_date_active, cd_sysdate)
            AND flv2.lookup_type            = cv_flv_assign_priority
            AND flv2.lookup_code            = msa.assignment_type
            AND flv2.language               = cv_lang
            AND flv2.source_lang            = cv_lang
            AND flv2.enabled_flag           = cv_enable
            AND cd_sysdate BETWEEN NVL(flv2.start_date_active, cd_sysdate)
                               AND NVL(flv2.end_date_active, cd_sysdate)
            AND msso.source_organization_id IN (gn_dummy_src_org_id, gn_master_org_id)
            AND NVL(msa.inventory_item_id, in_inventory_item_id) = in_inventory_item_id
            AND NVL(msa.organization_id, in_organization_id)     = in_organization_id
        )
        , msr_dummy_vw AS (
          --出荷計画区分ダミー経路
          SELECT msrv.source_organization_id             source_organization_id --移動元倉庫ID
                ,msrv.receipt_organization_id           receipt_organization_id --移動先組織ID
                ,msrv.assignment_set_name                   assignment_set_name --割当セット名
                ,msrv.organization_id                           organization_id --組織
                ,msrv.assignment_set_type                   assignment_set_type --割当セット区分
                ,msrv.assignment_type                           assignment_type --割当先タイプ
                ,msrv.sourcing_rule_type                     sourcing_rule_type --ソースルールタイプ
                ,msrv.sourcing_rule_name                     sourcing_rule_name --ソースルール名
                ,msrv.attribute1                                     attribute1 --出荷計画区分
                ,msrv.attribute2                                     attribute2 --鮮度条件1
                ,msrv.attribute3                                     attribute3 --在庫維持日数1
                ,msrv.attribute4                                     attribute4 --最大在庫日数1
                ,msrv.attribute5                                     attribute5 --鮮度条件2
                ,msrv.attribute6                                     attribute6 --在庫維持日数2
                ,msrv.attribute7                                     attribute7 --最大在庫日数2
                ,msrv.attribute8                                     attribute8 --鮮度条件3
                ,msrv.attribute9                                     attribute9 --在庫維持日数3
                ,msrv.attribute10                                   attribute10 --最大在庫日数3
                ,msrv.attribute11                                   attribute11 --鮮度条件4
                ,msrv.attribute12                                   attribute12 --在庫維持日数4
                ,msrv.attribute13                                   attribute13 --最大在庫日数4
                ,msrv.assign_type_priority                 assign_type_priority --割当先タイプ優先度
                ,ROW_NUMBER() OVER ( PARTITION BY msrv.source_organization_id
                                                 ,msrv.organization_id
                                     ORDER BY     msrv.assign_type_priority ASC
                                   )                                   priority --優先順位
          FROM msr_vw msrv
          WHERE msrv.assignment_set_type    IN (cv_base_plan)
            AND msrv.source_organization_id IN (gn_master_org_id)
        )
        , msr_base_vw AS (
          --基本横持計画
          SELECT msrv.source_organization_id             source_organization_id --移動元倉庫ID
                ,msrv.receipt_organization_id           receipt_organization_id --移動先組織ID
                ,msrv.assignment_set_name                   assignment_set_name --割当セット名
                ,msrv.organization_id                           organization_id --組織
                ,msrv.assignment_set_type                   assignment_set_type --割当セット区分
                ,msrv.assignment_type                           assignment_type --割当先タイプ
                ,msrv.sourcing_rule_type                     sourcing_rule_type --ソースルールタイプ
                ,msrv.sourcing_rule_name                     sourcing_rule_name --ソースルール名
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute1)
                     ELSE TO_NUMBER(msrv.attribute1)
                 END                                              shipping_type --出荷計画区分
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute2
                     ELSE msrv.attribute2
                 END                                       freshness_condition1 --鮮度条件1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute3)
                     ELSE TO_NUMBER(msrv.attribute3)
                 END                                    stock_maintenance_days1 --在庫維持日数1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute4)
                     ELSE TO_NUMBER(msrv.attribute4)
                 END                                            max_stock_days1 --最大在庫日数1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute5
                     ELSE msrv.attribute5
                 END                                       freshness_condition2 --鮮度条件2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute6)
                     ELSE TO_NUMBER(msrv.attribute6)
                 END                                    stock_maintenance_days2 --在庫維持日数2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute7)
                     ELSE TO_NUMBER(msrv.attribute7)
                 END                                            max_stock_days2 --最大在庫日数2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute8
                     ELSE msrv.attribute8
                 END                                       freshness_condition3 --鮮度条件3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute9)
                     ELSE TO_NUMBER(msrv.attribute9)
                 END                                    stock_maintenance_days3 --在庫維持日数3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute10)
                     ELSE TO_NUMBER(msrv.attribute10)
                 END                                            max_stock_days3 --最大在庫日数3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute11
                     ELSE msrv.attribute11
                 END                                       freshness_condition4 --鮮度条件4
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute12)
                     ELSE TO_NUMBER(msrv.attribute12)
                 END                                    stock_maintenance_days4 --在庫維持日数4
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute13)
                     ELSE TO_NUMBER(msrv.attribute13)
                 END                                            max_stock_days4 --最大在庫日数4
                ,msrv.assign_type_priority                 assign_type_priority --割当先タイプ優先度
                ,ROW_NUMBER() OVER ( PARTITION BY msrv.source_organization_id
                                                 ,msrv.receipt_organization_id
                                     ORDER BY     msrv.assign_type_priority ASC
                                                 ,msrv.sourcing_rule_type   DESC
                                   )                                   priority --優先順位
          FROM msr_vw msrv
              ,msr_dummy_vw mdv
          WHERE msrv.assignment_set_type    IN (cv_base_plan)
            AND msrv.source_organization_id IN (gn_dummy_src_org_id)
            AND msrv.organization_id = mdv.organization_id(+)
            AND mdv.priority(+) = 1
        )
        SELECT mbv.source_organization_id   source_organization_id
              ,mbv.receipt_organization_id  receipt_organization_id
              ,mbv.organization_id          organization_id
              ,mbv.assignment_set_type      assignment_set_type
              ,mbv.assignment_type          assignment_type
              ,mbv.sourcing_rule_type       sourcing_rule_type
              ,mbv.sourcing_rule_name       sourcing_rule_name
              ,mbv.shipping_type            shipping_type
              ,mbv.freshness_condition1     freshness_condition1
              ,mbv.stock_maintenance_days1  stock_maintenance_days1
              ,mbv.max_stock_days1          max_stock_days1
              ,mbv.freshness_condition2     freshness_condition2
              ,mbv.stock_maintenance_days2  stock_maintenance_days2
              ,mbv.max_stock_days2          max_stock_days2
              ,mbv.freshness_condition3     freshness_condition3
              ,mbv.stock_maintenance_days3  stock_maintenance_days3
              ,mbv.max_stock_days3          max_stock_days3
              ,mbv.freshness_condition4     freshness_condition4
              ,mbv.stock_maintenance_days4  stock_maintenance_days4
              ,mbv.max_stock_days4          max_stock_days4
        FROM msr_base_vw mbv
        WHERE mbv.priority = 1
      );
--
    -- *** ローカル・レコード ***
    l_fc_tab                  g_freshness_condition_ttype;
    l_xwsp_rec                xxcop_wk_ship_planning%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    OPEN xwsp_ship_cur;
    <<xwsp_ship_loop>>
    LOOP
      --出荷倉庫を取得
      FETCH xwsp_ship_cur INTO l_xwsp_rec.inventory_item_id
                              ,l_xwsp_rec.item_id
                              ,l_xwsp_rec.item_no
                              ,l_xwsp_rec.item_name
                              ,l_xwsp_rec.receipt_org_id
                              ,l_xwsp_rec.receipt_org_code
                              ,l_xwsp_rec.receipt_org_name;
      EXIT WHEN xwsp_ship_cur%NOTFOUND;
      --デバックメッセージ出力(出荷倉庫)
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => l_xwsp_rec.item_no           || ','
                        || l_xwsp_rec.inventory_item_id || ','
                        || l_xwsp_rec.receipt_org_id    || ','
                        || l_xwsp_rec.receipt_org_code
      );
      OPEN msr_ship_cur(
              l_xwsp_rec.inventory_item_id
             ,l_xwsp_rec.receipt_org_id
           );
      <<msr_ship_loop>>
      LOOP
        --経路情報の取得
        FETCH msr_ship_cur INTO l_xwsp_rec.plant_org_id
                               ,l_xwsp_rec.assignment_set_type
                               ,l_xwsp_rec.assignment_type
                               ,l_xwsp_rec.sourcing_rule_type
                               ,l_xwsp_rec.sourcing_rule_name
                               ,l_xwsp_rec.shipping_type
                               ,l_fc_tab(1).freshness_condition
                               ,l_fc_tab(1).stock_maintenance_days
                               ,l_fc_tab(1).max_stock_days
                               ,l_fc_tab(2).freshness_condition
                               ,l_fc_tab(2).stock_maintenance_days
                               ,l_fc_tab(2).max_stock_days
                               ,l_fc_tab(3).freshness_condition
                               ,l_fc_tab(3).stock_maintenance_days
                               ,l_fc_tab(3).max_stock_days
                               ,l_fc_tab(4).freshness_condition
                               ,l_fc_tab(4).stock_maintenance_days
                               ,l_fc_tab(4).max_stock_days;
        EXIT WHEN msr_ship_cur%NOTFOUND;
        --デバックメッセージ出力(経路)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => l_xwsp_rec.assignment_set_type || ','
                          || l_xwsp_rec.assignment_type     || ','
                          || l_xwsp_rec.sourcing_rule_name  || ','
                          || l_xwsp_rec.plant_org_id        || ','
                          || l_xwsp_rec.receipt_org_id
        );
        --前提条件のチェック
        chk_route_prereq(
           i_xwsp_rec   => l_xwsp_rec
          ,i_fc_tab     => l_fc_tab
          ,ov_errbuf    => lv_errbuf
          ,ov_retcode   => lv_retcode
          ,ov_errmsg    => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          IF ( lv_errbuf IS NULL ) THEN
            RAISE internal_api_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
        --出荷日
        l_xwsp_rec.shipping_date := gd_plan_date;
        --着荷日
        l_xwsp_rec.receipt_date  := gd_plan_date;
        --出荷ペースの計算
        proc_ship_pace(
           io_xwsp_rec  => l_xwsp_rec
          ,ov_retcode   => lv_retcode
          ,ov_errbuf    => lv_errbuf
          ,ov_errmsg    => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          IF ( lv_errbuf IS NULL ) THEN
            RAISE internal_api_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
        --物流計画ワークテーブル登録
        entry_xwsp(
           i_xwsp_rec   => l_xwsp_rec
          ,i_fc_tab     => l_fc_tab
          ,ov_retcode   => lv_retcode
          ,ov_errbuf    => lv_errbuf
          ,ov_errmsg    => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          IF ( lv_errbuf IS NULL ) THEN
            RAISE internal_api_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_START
        --移動先倉庫の鮮度条件が全て登録されているかチェック
        SELECT COUNT(*)
        INTO ln_exists
        FROM xxcop_wk_ship_planning xwsp
        WHERE xwsp.transaction_id = cn_request_id
          AND xwsp.item_id        = l_xwsp_rec.item_id
          AND xwsp.ship_org_id    = l_xwsp_rec.receipt_org_id
          AND NOT EXISTS (
            SELECT 'x'
            FROM xxcop_wk_ship_planning xwspv
            WHERE xwspv.transaction_id      = cn_request_id
              AND xwspv.plant_org_id        = gn_dummy_src_org_id
              AND xwspv.item_id             = l_xwsp_rec.item_id
              AND xwspv.receipt_org_id      = l_xwsp_rec.receipt_org_id
              AND xwspv.freshness_condition = xwsp.freshness_condition
          );
          IF ( ln_exists <> 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_10040
                           ,iv_token_name1  => cv_msg_10040_token_1
                           ,iv_token_value1 => l_xwsp_rec.receipt_org_code
                         );
            RAISE internal_api_expt;
          END IF;
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_END
      END LOOP msr_ship_loop;
      IF ( msr_ship_cur%ROWCOUNT = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_10040
                       ,iv_token_name1  => cv_msg_10040_token_1
                       ,iv_token_value1 => l_xwsp_rec.receipt_org_code
                     );
        RAISE internal_api_expt;
      END IF;
      CLOSE msr_ship_cur;
    END LOOP xwsp_ship_loop;
    CLOSE xwsp_ship_cur;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ship_route;
--
  /**********************************************************************************
   * Procedure Name   : delete_table
   * Description      : テーブルデータ削除
   ***********************************************************************************/
  PROCEDURE delete_table(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_table'; -- プログラム名
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
    lv_table_name             VARCHAR2(100);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    TYPE rowid_ttype IS TABLE OF rowid INDEX BY BINARY_INTEGER;
    lr_rowid                  rowid_ttype;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
    -- ===============================
    -- 物流計画ワークテーブル
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xwsp;
      --ロックの取得
      SELECT xwsp.ROWID
      BULK COLLECT INTO lr_rowid
      FROM xxcop_wk_ship_planning xwsp
      FOR UPDATE NOWAIT;
      --データ削除
      DELETE FROM xxcop_wk_ship_planning;
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        NULL;
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00042
                       ,iv_token_name1  => cv_msg_00042_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- 横持計画出力ワークテーブル
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xwypo;
      --ロックの取得
      SELECT xwspo.ROWID
      BULK COLLECT INTO lr_rowid
      FROM xxcop_wk_yoko_plan_output xwspo
      FOR UPDATE NOWAIT;
      --データ削除
      DELETE FROM xxcop_wk_yoko_plan_output;
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        NULL;
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00042
                       ,iv_token_name1  => cv_msg_00042_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_table;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_plan_type     IN     VARCHAR2,       -- 1.計画区分
    iv_shipment_from IN     VARCHAR2,       -- 2.出荷ペース計画期間(FROM)
    iv_shipment_to   IN     VARCHAR2,       -- 3.出荷ペース計画期間(TO)
    iv_forcast_type  IN     VARCHAR2,       -- 4.出荷予測区分
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    lv_param_msg         VARCHAR2(100);   -- パラメータ出力
    lb_chk_value         BOOLEAN;         -- 日付型フォーマットチェック結果
    lv_invalid_value     VARCHAR2(100);   -- エラーメッセージ値
    lv_value             VARCHAR2(100);   -- プロファイル値
    lv_profile_name      VARCHAR2(100);   -- ユーザプロファイル名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
    --空白行を挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    --入力パラメータの出力
    --計画区分
    lv_param_msg := cv_plan_type_tl || cv_msg_part || iv_plan_type;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --出荷ペース計画期間(FROM)
    lv_param_msg := gv_shipment_from_tl || cv_msg_part || iv_shipment_from;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --出荷ペース計画期間(TO)
    lv_param_msg := gv_shipment_to_tl || cv_msg_part || iv_shipment_to;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --出荷予測区分
    lv_param_msg := cv_forcast_type_tl || cv_msg_part || iv_forcast_type;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --空白行を挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ===============================
    -- 1.計画区分
    -- ===============================
    BEGIN
      IF ( iv_plan_type = cv_plan_type_shipped ) THEN
        IF ( iv_shipment_from IS NULL OR iv_shipment_to IS NULL ) THEN
          RAISE param_invalid_expt;
        END IF;
      ELSIF ( iv_plan_type = cv_plan_type_fgorcate ) THEN
        IF ( iv_forcast_type IS NULL ) THEN
          RAISE param_invalid_expt;
        END IF;
      ELSE
        IF ( iv_shipment_from IS NULL OR iv_shipment_to IS NULL OR iv_forcast_type IS NULL ) THEN
          RAISE param_invalid_expt;
        END IF;
      END IF;
      gv_plan_type := iv_plan_type;
    EXCEPTION
      WHEN param_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00055
                     );
        RAISE internal_api_expt;
    END;
--
    -- ===============================
    -- 2.出荷ペース計画期間(FROM-TO)
    -- ===============================
    BEGIN
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_shipment_from
                        ,iv_format      => cv_date_format
                      );
      IF ( NOT lb_chk_value ) THEN
        lv_invalid_value := iv_shipment_from;
        RAISE date_invalid_expt;
      END IF;
      gd_shipment_from := TO_DATE(iv_shipment_from, cv_date_format);
--
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_shipment_to
                        ,iv_format      => cv_date_format
                      );
      IF ( NOT lb_chk_value ) THEN
        lv_invalid_value := iv_shipment_to;
        RAISE date_invalid_expt;
      END IF;
      gd_shipment_to := TO_DATE(iv_shipment_to, cv_date_format);
--
    EXCEPTION
      WHEN date_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00011
                       ,iv_token_name1  => cv_msg_00011_token_1
                       ,iv_token_value1 => lv_invalid_value
                     );
        RAISE internal_api_expt;
    END;
--
    -- ===============================
    -- 3.出荷ペース計画期間(FROM-TO)逆転チェック
    -- ===============================
    IF ( gd_shipment_from >= gd_shipment_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00025
                     ,iv_token_name1  => cv_msg_00025_token_1
                     ,iv_token_value1 => gv_shipment_from_tl
                     ,iv_token_name2  => cv_msg_00025_token_2
                     ,iv_token_value2 => gv_shipment_to_tl
                   );
      RAISE internal_api_expt;
    END IF;
--
    -- ===============================
    -- 4.出荷ペース計画期間(FROM-TO)過去日チェック
    -- ===============================
    BEGIN
      IF ( gd_shipment_from > cd_sysdate ) THEN
        lv_invalid_value := gv_shipment_from_tl;
        RAISE past_date_invalid_expt;
      END IF;
--
      IF ( gd_shipment_to > cd_sysdate ) THEN
        lv_invalid_value := gv_shipment_to_tl;
        RAISE past_date_invalid_expt;
      END IF;
--
    EXCEPTION
      WHEN past_date_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00047
                       ,iv_token_name1  => cv_msg_00047_token_1
                       ,iv_token_value1 => lv_invalid_value
                     );
        RAISE internal_api_expt;
    END;
--
    -- ===============================
    -- 5.出荷予測期間の取得
    -- ===============================
    IF ( iv_forcast_type = cv_forcast_type_this ) THEN
      --当月
      gd_forcast_from := TRUNC(cd_sysdate, cv_trunc_month);
      gd_forcast_to   := LAST_DAY(cd_sysdate);
    ELSIF ( iv_forcast_type = cv_forcast_type_next ) THEN
      --翌月
      gd_forcast_from := ADD_MONTHS(TRUNC(cd_sysdate, cv_trunc_month), 1);
      gd_forcast_to   := LAST_DAY(ADD_MONTHS(cd_sysdate, 1));
    ELSIF ( iv_forcast_type = cv_forcast_type_2month ) THEN
      --当月+翌月
      gd_forcast_from := TRUNC(cd_sysdate, cv_trunc_month);
      gd_forcast_to   := LAST_DAY(ADD_MONTHS(cd_sysdate, 1));
    ELSE
      --NULL
      gd_forcast_from := NULL;
      gd_forcast_to   := NULL;
    END IF;
--
    -- ===============================
    -- 6.プロファイルの取得
    -- ===============================
    BEGIN
      --マスタ組織
      lv_profile_name := cv_upf_master_org_id;
      lv_value := fnd_profile.value( cv_pf_master_org_id );
      IF ( lv_value IS NULL ) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_master_org_id := TO_NUMBER(lv_value);
--
      --ダミー出荷組織
      lv_profile_name := cv_upf_dummy_src_org_id;
      lv_value := fnd_profile.value( cv_pf_dummy_src_org_id );
      IF ( lv_value IS NULL ) THEN
        RAISE profile_invalid_expt;
      END IF;
--20090414_Ver1.2_T1_0541_SCS.Goto_MOD_START
--      gn_dummy_src_org_id := TO_NUMBER(lv_value);
      BEGIN
        SELECT mp.organization_id
        INTO gn_dummy_src_org_id
        FROM mtl_parameters mp
        WHERE mp.organization_code = lv_value;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE profile_invalid_expt;
      END;
--20090414_Ver1.2_T1_0541_SCS.Goto_MOD_END
--
      --鮮度条件バッファ日数
      lv_profile_name := cv_upf_fresh_buffer_days;
      lv_value := fnd_profile.value( cv_pf_fresh_buffer_days );
      IF ( lv_value IS NULL ) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_freshness_buffer_days := TO_NUMBER(lv_value);
--
      --最終期限月数
      lv_profile_name := cv_upf_deadline_months;
      lv_value := fnd_profile.value( cv_pf_deadline_months );
      IF ( lv_value IS NULL ) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_deadline_months := TO_NUMBER(lv_value);
--
      --最終期限バッファ日数
      lv_profile_name := cv_upf_deadline_days;
      lv_value := fnd_profile.value( cv_pf_deadline_days );
      IF ( lv_value IS NULL ) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_deadline_buffer_days := TO_NUMBER(lv_value);
--
    EXCEPTION
      WHEN profile_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00002
                       ,iv_token_name1  => cv_msg_00002_token_1
                       ,iv_token_value1 => lv_profile_name
                     );
        RAISE internal_api_expt;
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00002
                       ,iv_token_name1  => cv_msg_00002_token_1
                       ,iv_token_value1 => lv_profile_name
                     );
        RAISE internal_api_expt;
    END;
--
    -- ===============================
    -- 7.横持計画作成日の取得
    -- ===============================
    gd_plan_date := cd_sysdate + 1;
--
    -- ===============================
    -- 8.関連テーブル削除
    -- ===============================
    delete_table(
       ov_errbuf  => lv_errbuf
      ,ov_retcode => lv_retcode
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      IF ( lv_errbuf IS NULL ) THEN
        RAISE internal_api_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_msr_route
   * Description      : 横持計画制御マスタ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_msr_route(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_msr_route'; -- プログラム名
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
    ln_ship_org_forcast_qty          NUMBER;     --移動元倉庫入庫予定数
    ln_receipt_org_forcast_qty       NUMBER;     --移動先倉庫入庫予定数
    ln_exists                        NUMBER;     --存在チェック
--
    -- *** ローカル・カーソル ***
    --品目情報の取得
    CURSOR xicv_cur IS
      SELECT xicv.inventory_item_id
            ,xicv.item_id
            ,xicv.item_no
            ,xicv.item_short_name
            ,xicv.prod_class_code
--20090407_Ver1.1_T1_0273_SCS.Goto_MOD_START
--            ,TO_NUMBER(xicv.num_of_cases)
            ,NVL(TO_NUMBER(xicv.num_of_cases), 1)
--20090407_Ver1.1_T1_0273_SCS.Goto_MOD_END
      FROM  xxcop_item_categories1_v xicv
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_START
           ,xxcmm_system_items_b     xsib
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_END
      WHERE xicv.inactive_ind               <> cn_xicv_inactive
        AND xicv.inventory_item_status_code <> cv_xicv_status
        AND xicv.prod_class_code             = cv_product_class_drink
        AND cd_sysdate BETWEEN NVL(xicv.start_date_active, cd_sysdate)
                           AND NVL(xicv.end_date_active, cd_sysdate)
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_START
        AND xsib.item_status                IN (cn_xsib_status_temporary
                                               ,cn_xsib_status_registered
                                               ,cn_xsib_status_obsolete)
        AND xsib.item_status_apply_date     <= cd_sysdate
        AND xicv.item_id                     = xsib.item_id
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_END
        AND NOT EXISTS (
          SELECT 'x'
          FROM xxcmn_sourcing_rules xsr
          WHERE xsr.plan_item_flag = cn_xsr_plan_item
            AND xsr.item_code      = xicv.item_no
            AND cd_sysdate BETWEEN NVL(xsr.start_date_active, cd_sysdate)
                               AND NVL(xsr.end_date_active, cd_sysdate)
        )
--20090414_Ver1.2_T1_0539_SCS.Goto_DEL_START
--        AND xicv.item_no IN ( '0006999', '0007000', '0007001' )
--20090414_Ver1.2_T1_0539_SCS.Goto_DEL_END
      ORDER BY xicv.item_no ASC;
--
    --経路情報の取得
    CURSOR msr_cur(
              in_inventory_item_id NUMBER
    ) IS
      SELECT source_organization_id
            ,receipt_organization_id
            ,assignment_set_type
            ,assignment_type
            ,sourcing_rule_type
            ,sourcing_rule_name
            ,shipping_type
            ,freshness_condition1
            ,stock_maintenance_days1
            ,max_stock_days1
            ,freshness_condition2
            ,stock_maintenance_days2
            ,max_stock_days2
            ,freshness_condition3
            ,stock_maintenance_days3
            ,max_stock_days3
            ,freshness_condition4
            ,stock_maintenance_days4
            ,max_stock_days4
            ,manufacture_date
            ,start_date_active
            ,end_date_active
            ,set_qty
            ,movement_qty
      FROM (
        WITH msr_vw AS (
          --全経路(基本横持計画、特別横持計画、出荷計画区分ダミー経路)
          SELECT msso.source_organization_id             source_organization_id --移動元倉庫ID
                ,msro.receipt_organization_id           receipt_organization_id --移動先組織ID
                ,mas.assignment_set_name                    assignment_set_name --割当セット名
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_START
--                ,NVL(msa.organization_id, msro.receipt_organization_id)
--                                                               organization_id --組織
                ,msa.organization_id                            organization_id --組織
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_END
                ,mas.attribute1                             assignment_set_type --割当セット区分
                ,msa.assignment_type                            assignment_type --割当先タイプ
                ,msa.sourcing_rule_type                      sourcing_rule_type --ソースルールタイプ
                ,msr.sourcing_rule_name                      sourcing_rule_name --ソースルール名
                ,msa.attribute1                                      attribute1 --
                ,msa.attribute2                                      attribute2 --
                ,msa.attribute3                                      attribute3 --
                ,msa.attribute4                                      attribute4 --
                ,msa.attribute5                                      attribute5 --
                ,msa.attribute6                                      attribute6 --
                ,msa.attribute7                                      attribute7 --
                ,msa.attribute8                                      attribute8 --
                ,msa.attribute9                                      attribute9 --
                ,msa.attribute10                                    attribute10 --
                ,msa.attribute11                                    attribute11 --
                ,msa.attribute12                                    attribute12 --
                ,msa.attribute13                                    attribute13 --
                ,flv2.description                          assign_type_priority --割当先タイプ優先度
          FROM mrp_assignment_sets mas
              ,mrp_sr_assignments  msa
              ,mrp_sourcing_rules  msr
              ,mrp_sr_receipt_org  msro
              ,mrp_sr_source_org   msso
              ,fnd_lookup_values   flv1
              ,fnd_lookup_values   flv2
          WHERE mas.assignment_set_id       = msa.assignment_set_id
            AND mas.attribute1             IN (cv_base_plan
                                              ,cv_custom_plan)
            AND msr.sourcing_rule_id        = msa.sourcing_rule_id
            AND msro.sourcing_rule_id       = msr.sourcing_rule_id
            AND msro.sr_receipt_id          = msso.sr_receipt_id
            AND cd_sysdate BETWEEN NVL(msro.effective_date, cd_sysdate)
                               AND NVL(msro.disable_date, cd_sysdate)
            AND flv1.lookup_type            = cv_flv_assignment_name
            AND flv1.lookup_code            = mas.assignment_set_name
            AND flv1.language               = cv_lang
            AND flv1.source_lang            = cv_lang
            AND flv1.enabled_flag           = cv_enable
            AND cd_sysdate BETWEEN NVL(flv1.start_date_active, cd_sysdate)
                               AND NVL(flv1.end_date_active, cd_sysdate)
            AND flv2.lookup_type            = cv_flv_assign_priority
            AND flv2.lookup_code            = msa.assignment_type
            AND flv2.language               = cv_lang
            AND flv2.source_lang            = cv_lang
            AND flv2.enabled_flag           = cv_enable
            AND cd_sysdate BETWEEN NVL(flv2.start_date_active, cd_sysdate)
                               AND NVL(flv2.end_date_active, cd_sysdate)
            AND NVL(msa.inventory_item_id, in_inventory_item_id) = in_inventory_item_id
        )
        , msr_dummy_vw AS (
          --出荷計画区分ダミー経路
          SELECT msrv.source_organization_id             source_organization_id --移動元倉庫ID
                ,msrv.receipt_organization_id           receipt_organization_id --移動先組織ID
                ,msrv.assignment_set_name                   assignment_set_name --割当セット名
                ,msrv.organization_id                           organization_id --組織
                ,msrv.assignment_set_type                   assignment_set_type --割当セット区分
                ,msrv.assignment_type                           assignment_type --割当先タイプ
                ,msrv.sourcing_rule_type                     sourcing_rule_type --ソースルールタイプ
                ,msrv.sourcing_rule_name                     sourcing_rule_name --ソースルール名
                ,msrv.attribute1                                     attribute1 --出荷計画区分
                ,msrv.attribute2                                     attribute2 --鮮度条件1
                ,msrv.attribute3                                     attribute3 --在庫維持日数1
                ,msrv.attribute4                                     attribute4 --最大在庫日数1
                ,msrv.attribute5                                     attribute5 --鮮度条件2
                ,msrv.attribute6                                     attribute6 --在庫維持日数2
                ,msrv.attribute7                                     attribute7 --最大在庫日数2
                ,msrv.attribute8                                     attribute8 --鮮度条件3
                ,msrv.attribute9                                     attribute9 --在庫維持日数3
                ,msrv.attribute10                                   attribute10 --最大在庫日数3
                ,msrv.attribute11                                   attribute11 --鮮度条件4
                ,msrv.attribute12                                   attribute12 --在庫維持日数4
                ,msrv.attribute13                                   attribute13 --最大在庫日数4
                ,msrv.assign_type_priority                 assign_type_priority --割当先タイプ優先度
--20090407_Ver1.1_T1_0367_SCS.Goto_DEL_START
--                ,ROW_NUMBER() OVER ( PARTITION BY msrv.source_organization_id
--                                                 ,msrv.organization_id
--                                     ORDER BY     msrv.assign_type_priority ASC
--                                   )                                   priority --優先順位
--20090407_Ver1.1_T1_0367_SCS.Goto_DEL_END
          FROM msr_vw msrv
          WHERE msrv.assignment_set_type    IN (cv_base_plan)
            AND msrv.source_organization_id IN (gn_master_org_id)
        )
        , msr_base_vw AS (
          --基本横持計画
          SELECT msrv.source_organization_id             source_organization_id --移動元倉庫ID
                ,msrv.receipt_organization_id           receipt_organization_id --移動先組織ID
                ,msrv.assignment_set_name                   assignment_set_name --割当セット名
                ,msrv.organization_id                           organization_id --組織
                ,msrv.assignment_set_type                   assignment_set_type --割当セット区分
                ,msrv.assignment_type                           assignment_type --割当先タイプ
                ,msrv.sourcing_rule_type                     sourcing_rule_type --ソースルールタイプ
                ,msrv.sourcing_rule_name                     sourcing_rule_name --ソースルール名
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute1)
                     ELSE TO_NUMBER(msrv.attribute1)
                 END                                              shipping_type --出荷計画区分
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute2
                     ELSE msrv.attribute2
                 END                                       freshness_condition1 --鮮度条件1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute3)
                     ELSE TO_NUMBER(msrv.attribute3)
                 END                                    stock_maintenance_days1 --在庫維持日数1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute4)
                     ELSE TO_NUMBER(msrv.attribute4)
                 END                                            max_stock_days1 --最大在庫日数1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute5
                     ELSE msrv.attribute5
                 END                                       freshness_condition2 --鮮度条件2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute6)
                     ELSE TO_NUMBER(msrv.attribute6)
                 END                                    stock_maintenance_days2 --在庫維持日数2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute7)
                     ELSE TO_NUMBER(msrv.attribute7)
                 END                                            max_stock_days2 --最大在庫日数2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute8
                     ELSE msrv.attribute8
                 END                                       freshness_condition3 --鮮度条件3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute9)
                     ELSE TO_NUMBER(msrv.attribute9)
                 END                                    stock_maintenance_days3 --在庫維持日数3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute10)
                     ELSE TO_NUMBER(msrv.attribute10)
                 END                                            max_stock_days3 --最大在庫日数3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute11
                     ELSE msrv.attribute11
                 END                                       freshness_condition4 --鮮度条件4
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute12)
                     ELSE TO_NUMBER(msrv.attribute12)
                 END                                    stock_maintenance_days4 --在庫維持日数4
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute13)
                     ELSE TO_NUMBER(msrv.attribute13)
                 END                                            max_stock_days4 --最大在庫日数4
                ,msrv.assign_type_priority                 assign_type_priority --割当先タイプ優先度
                ,ROW_NUMBER() OVER ( PARTITION BY msrv.source_organization_id
                                                 ,msrv.receipt_organization_id
                                     ORDER BY     msrv.assign_type_priority ASC
                                                 ,msrv.sourcing_rule_type   DESC
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_START
                                                 ,mdv.assign_type_priority  ASC
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_END
                                   )                                   priority --優先順位
                ,RANK () OVER ( PARTITION BY msrv.receipt_organization_id
                                ORDER BY     msrv.assign_type_priority    ASC
                                            ,msrv.sourcing_rule_type      DESC
                                            ,msrv.source_organization_id  DESC
                              )                            custom_plan_priority --特別横持計画優先順位
          FROM msr_vw msrv
              ,msr_dummy_vw mdv
          WHERE msrv.assignment_set_type        IN (cv_base_plan)
            AND msrv.source_organization_id NOT IN (gn_master_org_id
                                                   ,gn_dummy_src_org_id)
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_START
--            AND msrv.receipt_organization_id = mdv.organization_id(+)
--            AND mdv.priority(+) = 1
            AND msrv.receipt_organization_id = NVL( mdv.organization_id(+), msrv.receipt_organization_id )
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_END
        )
        , msr_custom_vw AS (
          --特別横持計画
          SELECT msrv.source_organization_id             source_organization_id --移動元倉庫ID
                ,msrv.receipt_organization_id           receipt_organization_id --移動先組織ID
                ,msrv.assignment_set_name                   assignment_set_name --割当セット名
                ,msrv.organization_id                           organization_id --組織
                ,msrv.assignment_set_type                   assignment_set_type --割当セット区分
                ,msrv.assignment_type                           assignment_type --割当先タイプ
                ,msrv.sourcing_rule_type                     sourcing_rule_type --ソースルールタイプ
                ,msrv.sourcing_rule_name                     sourcing_rule_name --ソースルール名
                ,mbv.shipping_type                                shipping_type --出荷計画区分
                ,mbv.freshness_condition1                  freshness_condition1 --鮮度条件1
                ,mbv.stock_maintenance_days1            stock_maintenance_days1 --在庫維持日数1
                ,mbv.max_stock_days1                            max_stock_days1 --最大在庫日数1
                ,mbv.freshness_condition2                  freshness_condition2 --鮮度条件2
                ,mbv.stock_maintenance_days2            stock_maintenance_days2 --在庫維持日数2
                ,mbv.max_stock_days2                            max_stock_days2 --最大在庫日数2
                ,mbv.freshness_condition3                  freshness_condition3 --鮮度条件3
                ,mbv.stock_maintenance_days3            stock_maintenance_days3 --在庫維持日数3
                ,mbv.max_stock_days3                            max_stock_days3 --最大在庫日数3
                ,mbv.freshness_condition4                  freshness_condition4 --鮮度条件4
                ,mbv.stock_maintenance_days4            stock_maintenance_days4 --在庫維持日数4
                ,mbv.max_stock_days4                            max_stock_days4 --最大在庫日数4
                ,TO_DATE(msrv.attribute1, cv_date_format)      manufacture_date --開始製造年月日
                ,TO_DATE(msrv.attribute2, cv_date_format)     start_date_active --有効開始日
                ,TO_DATE(msrv.attribute3, cv_date_format)       end_date_active --有効終了日
                ,TO_NUMBER(msrv.attribute4)                             set_qty --設定数量
                ,TO_NUMBER(msrv.attribute5)                        movement_qty --移動数
                ,msrv.assign_type_priority                 assign_type_priority --割当先タイプ優先度
          FROM msr_vw msrv
              ,msr_base_vw mbv
          WHERE msrv.assignment_set_type        IN (cv_custom_plan)
            AND msrv.source_organization_id NOT IN (gn_master_org_id
                                                   ,gn_dummy_src_org_id)
            AND msrv.receipt_organization_id = mbv.receipt_organization_id
            AND mbv.custom_plan_priority = 1
        )
        SELECT mbv.source_organization_id   source_organization_id
              ,mbv.receipt_organization_id  receipt_organization_id
              ,mbv.organization_id          organization_id
              ,mbv.assignment_set_type      assignment_set_type
              ,mbv.assignment_type          assignment_type
              ,mbv.sourcing_rule_type       sourcing_rule_type
              ,mbv.sourcing_rule_name       sourcing_rule_name
              ,mbv.shipping_type            shipping_type
              ,mbv.freshness_condition1     freshness_condition1
              ,mbv.stock_maintenance_days1  stock_maintenance_days1
              ,mbv.max_stock_days1          max_stock_days1
              ,mbv.freshness_condition2     freshness_condition2
              ,mbv.stock_maintenance_days2  stock_maintenance_days2
              ,mbv.max_stock_days2          max_stock_days2
              ,mbv.freshness_condition3     freshness_condition3
              ,mbv.stock_maintenance_days3  stock_maintenance_days3
              ,mbv.max_stock_days3          max_stock_days3
              ,mbv.freshness_condition4     freshness_condition4
              ,mbv.stock_maintenance_days4  stock_maintenance_days4
              ,mbv.max_stock_days4          max_stock_days4
              ,NULL                         manufacture_date
              ,NULL                         start_date_active
              ,NULL                         end_date_active
              ,NULL                         set_qty
              ,NULL                         movement_qty
        FROM msr_base_vw mbv
        WHERE mbv.priority = 1
        UNION ALL
        SELECT mcv.source_organization_id   source_organization_id
              ,mcv.receipt_organization_id  receipt_organization_id
              ,mcv.organization_id          organization_id
              ,mcv.assignment_set_type      assignment_set_type
              ,mcv.assignment_type          assignment_type
              ,mcv.sourcing_rule_type       sourcing_rule_type
              ,mcv.sourcing_rule_name       sourcing_rule_name
              ,mcv.shipping_type            shipping_type
              ,mcv.freshness_condition1     freshness_condition1
              ,mcv.stock_maintenance_days1  stock_maintenance_days1
              ,mcv.max_stock_days1          max_stock_days1
              ,mcv.freshness_condition2     freshness_condition2
              ,mcv.stock_maintenance_days2  stock_maintenance_days2
              ,mcv.max_stock_days2          max_stock_days2
              ,mcv.freshness_condition3     freshness_condition3
              ,mcv.stock_maintenance_days3  stock_maintenance_days3
              ,mcv.max_stock_days3          max_stock_days3
              ,mcv.freshness_condition4     freshness_condition4
              ,mcv.stock_maintenance_days4  stock_maintenance_days4
              ,mcv.max_stock_days4          max_stock_days4
              ,mcv.manufacture_date         manufacture_date
              ,mcv.start_date_active        start_date_active
              ,mcv.end_date_active          end_date_active
              ,mcv.set_qty                  set_qty
              ,mcv.movement_qty             movement_qty
        FROM msr_custom_vw mcv
      )
      ORDER BY assignment_set_type DESC;
    -- *** ローカル・レコード ***
    l_xwsp_rec                xxcop_wk_ship_planning%ROWTYPE;
    l_fc_tab                  g_freshness_condition_ttype;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    OPEN xicv_cur;
    <<xicv_loop>>
    LOOP
      --品目情報の取得
      FETCH xicv_cur INTO l_xwsp_rec.inventory_item_id
                         ,l_xwsp_rec.item_id
                         ,l_xwsp_rec.item_no
                         ,l_xwsp_rec.item_name
                         ,l_xwsp_rec.prod_class_code
                         ,l_xwsp_rec.num_of_case;
      EXIT WHEN xicv_cur%NOTFOUND;
      IF ( l_xwsp_rec.num_of_case = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00061
                       ,iv_token_name1  => cv_msg_00061_token_1
                       ,iv_token_value1 => l_xwsp_rec.item_no
                     );
        RAISE internal_api_expt;
      END IF;
      --デバックメッセージ出力(品目)
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => l_xwsp_rec.item_no     || ','
                        || l_xwsp_rec.num_of_case
      );
      --配送単位の取得
      xxcop_common_pkg2.get_unit_delivery(
         in_item_id              => l_xwsp_rec.item_id
        ,id_ship_date            => gd_plan_date
        ,on_palette_max_cs_qty   => l_xwsp_rec.palette_max_cs_qty
        ,on_palette_max_step_qty => l_xwsp_rec.palette_max_step_qty
        ,ov_errbuf               => lv_errbuf
        ,ov_retcode              => lv_retcode
        ,ov_errmsg               => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00057
                       ,iv_token_name1  => cv_msg_00057_token_1
                       ,iv_token_value1 => l_xwsp_rec.item_no
                     );
        RAISE internal_api_expt;
      END IF;
      IF ( l_xwsp_rec.palette_max_cs_qty = 0
        OR l_xwsp_rec.palette_max_step_qty = 0 )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00059
                       ,iv_token_name1  => cv_msg_00059_token_1
                       ,iv_token_value1 => l_xwsp_rec.item_no
                     );
        RAISE internal_api_expt;
      END IF;
      OPEN msr_cur( l_xwsp_rec.inventory_item_id );
      <<msr_loop>>
      LOOP
        BEGIN
          --経路情報の取得
          FETCH msr_cur INTO l_xwsp_rec.ship_org_id
                            ,l_xwsp_rec.receipt_org_id
                            ,l_xwsp_rec.assignment_set_type
                            ,l_xwsp_rec.assignment_type
                            ,l_xwsp_rec.sourcing_rule_type
                            ,l_xwsp_rec.sourcing_rule_name
                            ,l_xwsp_rec.shipping_type
                            ,l_fc_tab(1).freshness_condition
                            ,l_fc_tab(1).stock_maintenance_days
                            ,l_fc_tab(1).max_stock_days
                            ,l_fc_tab(2).freshness_condition
                            ,l_fc_tab(2).stock_maintenance_days
                            ,l_fc_tab(2).max_stock_days
                            ,l_fc_tab(3).freshness_condition
                            ,l_fc_tab(3).stock_maintenance_days
                            ,l_fc_tab(3).max_stock_days
                            ,l_fc_tab(4).freshness_condition
                            ,l_fc_tab(4).stock_maintenance_days
                            ,l_fc_tab(4).max_stock_days
                            ,l_xwsp_rec.manufacture_date
                            ,l_xwsp_rec.start_date_active
                            ,l_xwsp_rec.end_date_active
                            ,l_xwsp_rec.set_qty
                            ,l_xwsp_rec.movement_qty;
          EXIT WHEN msr_cur%NOTFOUND;
          --デバックメッセージ出力(経路)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => l_xwsp_rec.assignment_set_type || ','
                            || l_xwsp_rec.assignment_type     || ','
                            || l_xwsp_rec.sourcing_rule_name  || ','
                            || l_xwsp_rec.ship_org_id         || ','
                            || l_xwsp_rec.receipt_org_id
          );
          --基本横持計画の場合
          IF ( l_xwsp_rec.assignment_set_type = cv_base_plan ) THEN
            --特別横持計画で同じ経路が登録されている場合、スキップ
            SELECT COUNT(*)
            INTO   ln_exists
            FROM xxcop_wk_ship_planning xwsp
            WHERE xwsp.transaction_id = cn_request_id
              AND xwsp.item_id        = l_xwsp_rec.item_id
              AND xwsp.ship_org_id    = l_xwsp_rec.ship_org_id
              AND xwsp.receipt_org_id = l_xwsp_rec.receipt_org_id;
            IF ( ln_exists > 0 ) THEN
              RAISE obsolete_skip_expt;
            END IF;
          END IF;
          --移動元倉庫情報の取得
          xxcop_common_pkg2.get_org_info(
             in_organization_id    => l_xwsp_rec.ship_org_id
            ,ov_organization_code  => l_xwsp_rec.ship_org_code
            ,ov_whse_name          => l_xwsp_rec.ship_org_name
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00050
                           ,iv_token_name1  => cv_msg_00050_token_1
                           ,iv_token_value1 => l_xwsp_rec.ship_org_id
                         );
            RAISE internal_api_expt;
          END IF;
          --移動元倉庫の在庫品目チェック
          xxcop_common_pkg2.chk_item_exists(
             in_inventory_item_id  => l_xwsp_rec.inventory_item_id
            ,in_organization_id    => l_xwsp_rec.ship_org_id
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00050
                           ,iv_token_name1  => cv_msg_00050_token_1
                           ,iv_token_value1 => l_xwsp_rec.ship_org_code
                         );
            RAISE internal_api_expt;
          END IF;
          --移動先倉庫情報の取得
          xxcop_common_pkg2.get_org_info(
             in_organization_id    => l_xwsp_rec.receipt_org_id
            ,ov_organization_code  => l_xwsp_rec.receipt_org_code
            ,ov_whse_name          => l_xwsp_rec.receipt_org_name
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00050
                           ,iv_token_name1  => cv_msg_00050_token_1
                           ,iv_token_value1 => l_xwsp_rec.receipt_org_id
                         );
            RAISE internal_api_expt;
          END IF;
          --移動先倉庫の在庫品目チェック
          xxcop_common_pkg2.chk_item_exists(
             in_inventory_item_id  => l_xwsp_rec.inventory_item_id
            ,in_organization_id    => l_xwsp_rec.receipt_org_id
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00050
                           ,iv_token_name1  => cv_msg_00050_token_1
                           ,iv_token_value1 => l_xwsp_rec.receipt_org_code
                         );
            RAISE internal_api_expt;
          END IF;
          --前提条件のチェック
          chk_route_prereq(
             i_xwsp_rec            => l_xwsp_rec
            ,i_fc_tab              => l_fc_tab
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            IF ( lv_errbuf IS NULL ) THEN
              RAISE internal_api_expt;
            ELSE
              RAISE global_api_expt;
            END IF;
          END IF;
          --配送リードタイムの取得
          xxcop_common_pkg2.get_deliv_lead_time(
             iv_from_org_code      => l_xwsp_rec.ship_org_code
            ,iv_to_org_code        => l_xwsp_rec.receipt_org_code
            ,id_product_date       => gd_plan_date
            ,on_delivery_lt        => l_xwsp_rec.delivery_lead_time
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00053
                           ,iv_token_name1  => cv_msg_00053_token_1
                           ,iv_token_value1 => l_xwsp_rec.ship_org_code
                           ,iv_token_name2  => cv_msg_00053_token_2
                           ,iv_token_value2 => l_xwsp_rec.receipt_org_code
                         );
            RAISE internal_api_expt;
          END IF;
          --出荷日
          l_xwsp_rec.shipping_date := gd_plan_date;
          --着荷日
          l_xwsp_rec.receipt_date  := gd_plan_date + l_xwsp_rec.delivery_lead_time;
          --特別横持計画のチェック
          IF ( l_xwsp_rec.assignment_set_type = cv_custom_plan ) THEN
            --着荷日が有効開始日～有効終了日の期間外の場合、スキップ
            IF ( NOT ( l_xwsp_rec.start_date_active <= l_xwsp_rec.receipt_date
                   AND l_xwsp_rec.end_date_active   >= l_xwsp_rec.receipt_date ) )
            THEN
              RAISE obsolete_skip_expt;
            END IF;
          END IF;
          --出荷ペースの計算
          proc_ship_pace(
             io_xwsp_rec  => l_xwsp_rec
            ,ov_retcode   => lv_retcode
            ,ov_errbuf    => lv_errbuf
            ,ov_errmsg    => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            IF ( lv_errbuf IS NULL ) THEN
              RAISE internal_api_expt;
            ELSE
              RAISE global_api_expt;
            END IF;
          END IF;
          --物流計画ワークテーブル登録
          entry_xwsp(
             i_xwsp_rec   => l_xwsp_rec
            ,i_fc_tab     => l_fc_tab
            ,ov_retcode   => lv_retcode
            ,ov_errbuf    => lv_errbuf
            ,ov_errmsg    => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            IF ( lv_errbuf IS NULL ) THEN
              RAISE internal_api_expt;
            ELSE
              RAISE global_api_expt;
            END IF;
          END IF;
        EXCEPTION
          WHEN obsolete_skip_expt THEN
            NULL;
        END;
      END LOOP msr_loop;
      CLOSE msr_cur;
    END LOOP xicv_loop;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '品目マスタ対象件数 :' || xicv_cur%ROWCOUNT
    );
    CLOSE xicv_cur;
    --対象件数の確認
    SELECT COUNT(*)
    INTO   ln_exists
    FROM xxcop_wk_ship_planning xwsp
    WHERE transaction_id = cn_request_id;
    IF ( ln_exists = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00003
                   );
      RAISE internal_api_expt;
    END IF;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '経路情報件数 :' || ln_exists
    );
    --出荷倉庫の横持計画制御マスタを取得
    get_ship_route(
       ov_retcode   => lv_retcode
      ,ov_errbuf    => lv_errbuf
      ,ov_errmsg    => lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      IF ( lv_errbuf IS NULL ) THEN
        RAISE internal_api_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_msr_route;
--
  /**********************************************************************************
   * Procedure Name   : get_xwsp
   * Description      : 物流計画ワークテーブル取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_xwsp(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xwsp'; -- プログラム名
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
    lv_receipt_org_code       xxcop_wk_ship_planning.receipt_org_code%TYPE;
--
    -- *** ローカル・カーソル ***
    --移動先倉庫を取得
    CURSOR xwsp_cur IS
      SELECT xwsp.item_no                     item_no
            ,xwsp.receipt_org_code            receipt_org_code
      FROM xxcop_wk_ship_planning xwsp
      WHERE xwsp.transaction_id = cn_request_id
        AND xwsp.plant_org_id  IS NULL
      GROUP BY xwsp.item_no
              ,xwsp.receipt_org_code
      ORDER BY xwsp.item_no                 ASC
              ,MIN(xwsp.delivery_lead_time) ASC
              ,xwsp.receipt_org_code        ASC;
--
    --移動元倉庫を取得
    CURSOR xwsp_so_cur(
              lv_item_no          VARCHAR2
             ,lv_receipt_org_code VARCHAR2
    ) IS
      SELECT xwsp.item_no                     item_no
            ,xwsp.ship_org_code               ship_org_code
            ,xwsp.assignment_set_type         assignment_set_type
      FROM xxcop_wk_ship_planning xwsp
      WHERE xwsp.transaction_id   = cn_request_id
        AND xwsp.item_no          = lv_item_no
        AND xwsp.receipt_org_code = lv_receipt_org_code
        AND xwsp.plant_org_id    IS NULL
        AND NOT EXISTS (
          SELECT 'x'
          FROM xxcop_wk_yoko_plan_output xwypo
          WHERE xwypo.transaction_id   = xwsp.transaction_id
            AND xwypo.ship_org_code    = xwsp.ship_org_code
            AND xwypo.item_no          = xwsp.item_no
        )
      GROUP BY xwsp.item_no
              ,xwsp.ship_org_code
              ,xwsp.assignment_set_type
      ORDER BY xwsp.assignment_set_type DESC
              ,xwsp.ship_org_code       ASC;
--
    -- *** ローカル・レコード ***
    l_xwsp_rec                g_xwsp_ref_rtype;
    l_xwypo_tab               g_xwypo_ref_ttype;
    l_cp_tab                  g_condition_priority_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --初期化
    gn_group_id := 0;
--
    --移動先倉庫を取得
    <<xwsp_ro_loop>>
    FOR l_xwsp_ro_rec IN xwsp_cur LOOP
      --デバックメッセージ出力
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => 'xwsp_ro_loop'                  || ','
                        || l_xwsp_ro_rec.item_no           || ','
                        || l_xwsp_ro_rec.receipt_org_code
      );
      BEGIN
        --移動元倉庫を取得
        <<xwsp_so_loop>>
        FOR l_xwsp_so_rec IN xwsp_so_cur(
                                l_xwsp_ro_rec.item_no
                               ,l_xwsp_ro_rec.receipt_org_code
                             ) LOOP
          --デバックメッセージ出力
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => 'xwsp_so_loop'              || ','
                            || l_xwsp_so_rec.item_no       || ','
                            || l_xwsp_so_rec.ship_org_code
          );
          gn_group_id := gn_group_id + 1;
          --優先順位の高い鮮度条件から横持計画作成
          SELECT MIN(xwsp.freshness_priority)   freshness_priority
                ,xwsp.freshness_condition       freshness_condition
                ,MIN(flv.attribute1)            condition_type
                ,TO_NUMBER(MIN(flv.attribute2)) condition_value
          BULK COLLECT INTO l_cp_tab
          FROM xxcop_wk_ship_planning xwsp
              ,fnd_lookup_values      flv
          WHERE xwsp.transaction_id      = cn_request_id
            AND xwsp.item_no             = l_xwsp_so_rec.item_no
            AND xwsp.ship_org_code       = l_xwsp_so_rec.ship_org_code
            AND flv.lookup_type          = cv_flv_freshness_cond
            AND flv.lookup_code          = xwsp.freshness_condition
            AND flv.language             = cv_lang
            AND flv.source_lang          = cv_lang
            AND flv.enabled_flag         = cv_enable
            AND cd_sysdate BETWEEN NVL(flv.start_date_active, cd_sysdate)
                               AND NVL(flv.end_date_active, cd_sysdate)
          GROUP BY xwsp.freshness_condition
          ORDER BY freshness_priority ASC
                  ,condition_type     DESC
                  ,condition_value    ASC;
          <<priority_loop>>
          FOR l_cp_idx IN l_cp_tab.FIRST .. l_cp_tab.LAST LOOP
            --デバックメッセージ出力
            xxcop_common_pkg.put_debug_message(
               iov_debug_mode => gv_debug_mode
              ,iv_value       => 'priority_loop'                        || ','
                              || l_cp_tab(l_cp_idx).freshness_condition
            );
            --移動元倉庫の鮮度条件を取得
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_START
            SELECT xwspv.item_id
                  ,xwspv.item_no
                  ,xwspv.ship_org_id
                  ,xwspv.ship_org_code
                  ,xwspv.shipping_date
                  ,xwspv.before_stock
                  ,xwspv.manufacture_date
                  ,xwspv.shipping_pace
                  ,xwspv.stock_maintenance_days
                  ,xwspv.max_stock_days
            INTO l_xwsp_rec
            FROM (
              SELECT xwsp.item_id                     item_id
                    ,xwsp.item_no                     item_no
                    ,xwsp.receipt_org_id              ship_org_id
                    ,xwsp.receipt_org_code            ship_org_code
                    ,xwsp.shipping_date               shipping_date
                    ,NULL                             before_stock
                    ,NULL                             manufacture_date
                    ,xwsp.shipping_pace               shipping_pace
                    ,xwsp.stock_maintenance_days      stock_maintenance_days
                    ,xwsp.max_stock_days              max_stock_days
                    ,ROW_NUMBER() OVER ( ORDER BY xwsp.freshness_priority ASC )
                                                      freshness_priority
              FROM xxcop_wk_ship_planning xwsp
              WHERE xwsp.transaction_id      = cn_request_id
                AND xwsp.item_no             = l_xwsp_so_rec.item_no
                AND xwsp.plant_org_id        = gn_dummy_src_org_id
                AND xwsp.receipt_org_code    = l_xwsp_so_rec.ship_org_code
                AND xwsp.freshness_condition = l_cp_tab(l_cp_idx).freshness_condition
            ) xwspv
            WHERE xwspv.freshness_priority = 1;
--            SELECT xwsp.item_id                     item_id
--                  ,xwsp.item_no                     item_no
--                  ,xwsp.receipt_org_id              ship_org_id
--                  ,xwsp.receipt_org_code            ship_org_code
--                  ,xwsp.shipping_date               shipping_date
--                  ,NULL                             before_stock
--                  ,NULL                             manufacture_date
--                  ,xwsp.shipping_pace               shipping_pace
--                  ,xwsp.stock_maintenance_days      stock_maintenance_days
--                  ,xwsp.max_stock_days              max_stock_days
--            INTO l_xwsp_rec
--            FROM xxcop_wk_ship_planning xwsp
--            WHERE xwsp.transaction_id      = cn_request_id
--              AND xwsp.item_no             = l_xwsp_so_rec.item_no
--              AND xwsp.plant_org_id        = gn_dummy_src_org_id
--              AND xwsp.receipt_org_code    = l_xwsp_so_rec.ship_org_code
--              AND xwsp.freshness_condition = l_cp_tab(l_cp_idx).freshness_condition;
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_END
            --移動元倉庫の鮮度条件を満たす在庫数の取得
            get_stock_quantity(
               in_item_id          => l_xwsp_rec.item_id
              ,iv_whse_code        => l_xwsp_rec.ship_org_code
              ,id_plan_date        => l_xwsp_rec.shipping_date
              ,in_stock_days       => l_xwsp_rec.max_stock_days
              ,i_cp_rec            => l_cp_tab(l_cp_idx)
              ,on_stock_quantity   => l_xwsp_rec.before_stock
              ,od_manufacture_date => l_xwsp_rec.manufacture_date
              ,ov_errbuf           => lv_errbuf
              ,ov_retcode          => lv_retcode
              ,ov_errmsg           => lv_errmsg
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_errbuf IS NULL ) THEN
                RAISE internal_api_expt;
              ELSE
                RAISE global_api_expt;
              END IF;
            END IF;
            --鮮度条件が同じ移動先倉庫を取得
            SELECT xwsp.transaction_id                                                 transaction_id
                  ,xwsp.shipping_date                                                  shipping_date
                  ,xwsp.receipt_date                                                   receipt_date
                  ,xwsp.ship_org_code                                                  ship_org_code
                  ,xwsp.ship_org_name                                                  ship_org_name
                  ,xwsp.receipt_org_code                                               receipt_org_code
                  ,xwsp.receipt_org_name                                               receipt_org_name
                  ,xwsp.item_id                                                        item_id
                  ,xwsp.item_no                                                        item_no
                  ,xwsp.item_name                                                      item_name
                  ,xwsp.freshness_priority                                             freshness_priority
                  ,xwsp.freshness_condition                                            freshness_condition
                  ,NULL                                                                manu_date
                  ,NULL                                                                lot_status
                  ,NULL                                                                plan_min_qty
                  ,NULL                                                                plan_max_qty
                  ,NULL                                                                plan_bal_qty
                  ,NULL                                                                plan_lot_qty
                  ,NULL                                                                delivery_unit
                  ,NULL                                                                before_stock
                  ,NULL                                                                after_stock
                  ,xwsp.stock_maintenance_days                                         safety_days
                  ,xwsp.max_stock_days                                                 max_days
                  ,xwsp.shipping_pace                                                  shipping_pace
                  ,NULL                                                                under_lvl_pace
                  ,DECODE(xwsp.assignment_set_type, cv_custom_plan, cv_csv_mark, NULL) special_yoko_type
                  ,NULL                                                                supp_bad_type
                  ,NULL                                                                lot_revers_type
                  ,NULL                                                                earliest_manu_date
                  ,xwsp.manufacture_date                                               start_manu_date
                  ,xwsp.num_of_case                                                    num_of_case
                  ,xwsp.palette_max_cs_qty                                             palette_max_cs_qty
                  ,xwsp.palette_max_step_qty                                           palette_max_step_qty
            BULK COLLECT INTO l_xwypo_tab
            FROM xxcop_wk_ship_planning xwsp
            WHERE xwsp.transaction_id      = cn_request_id
              AND xwsp.item_no             = l_xwsp_rec.item_no
              AND xwsp.ship_org_code       = l_xwsp_rec.ship_org_code
              AND xwsp.freshness_condition = l_cp_tab(l_cp_idx).freshness_condition
            ORDER BY xwsp.assignment_set_type DESC
                    ,xwsp.receipt_org_code    ASC;
            <<xwypo_loop>>
            FOR ln_xwypo_idx IN l_xwypo_tab.FIRST .. l_xwypo_tab.LAST LOOP
              --デバックメッセージ出力
              xxcop_common_pkg.put_debug_message(
                 iov_debug_mode => gv_debug_mode
                ,iv_value       => 'xwypo_loop'                               || ','
                                || l_xwypo_tab(ln_xwypo_idx).receipt_org_code
              );
              --移動先倉庫の鮮度条件を満たす在庫数の取得
              get_stock_quantity(
                 in_item_id          => l_xwypo_tab(ln_xwypo_idx).item_id
                ,iv_whse_code        => l_xwypo_tab(ln_xwypo_idx).receipt_org_code
                ,id_plan_date        => l_xwypo_tab(ln_xwypo_idx).receipt_date
                ,in_stock_days       => l_xwypo_tab(ln_xwypo_idx).max_days
                ,i_cp_rec            => l_cp_tab(l_cp_idx)
                ,on_stock_quantity   => l_xwypo_tab(ln_xwypo_idx).before_stock
                ,od_manufacture_date => l_xwypo_tab(ln_xwypo_idx).earliest_manu_date
                ,ov_errbuf           => lv_errbuf
                ,ov_retcode          => lv_retcode
                ,ov_errmsg           => lv_errmsg
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                IF ( lv_errbuf IS NULL ) THEN
                  RAISE internal_api_expt;
                ELSE
                  RAISE global_api_expt;
                END IF;
              END IF;
              lv_receipt_org_code := l_xwypo_tab(ln_xwypo_idx).receipt_org_code;
              --総出荷ペースの取得
              SELECT NVL(SUM(xwspv.shipping_pace), 0)
              INTO   l_xwypo_tab(ln_xwypo_idx).under_lvl_pace
              FROM (
                SELECT xwsp.ship_org_code
                      ,xwsp.receipt_org_code
                      ,xwsp.item_id
                      ,xwsp.shipping_pace
                FROM xxcop_wk_ship_planning xwsp
                WHERE xwsp.transaction_id   = cn_request_id
                  AND xwsp.item_id          = l_xwypo_tab(ln_xwypo_idx).item_id
                  AND xwsp.plant_org_id    IS NULL
                GROUP BY xwsp.ship_org_code
                      ,xwsp.receipt_org_code
                      ,xwsp.item_id
                      ,xwsp.shipping_pace
              ) xwspv
              START WITH       xwspv.ship_org_code    = lv_receipt_org_code
              CONNECT BY PRIOR xwspv.receipt_org_code = xwspv.ship_org_code;
              --デバックメッセージ出力
              xxcop_common_pkg.put_debug_message(
                 iov_debug_mode => gv_debug_mode
                ,iv_value       => 'ship_pace'                             || ','
                               || l_xwypo_tab(ln_xwypo_idx).under_lvl_pace || ','
                               || l_xwypo_tab(ln_xwypo_idx).shipping_pace
              );
              l_xwypo_tab(ln_xwypo_idx).under_lvl_pace := l_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        + l_xwypo_tab(ln_xwypo_idx).shipping_pace;
            END LOOP xwypo_loop;
            --計画数(バランス)の算出
            proc_balance_plan_qty(
               i_xwsp_rec          => l_xwsp_rec
              ,io_xwypo_tab        => l_xwypo_tab
              ,ov_errbuf           => lv_errbuf
              ,ov_retcode          => lv_retcode
              ,ov_errmsg           => lv_errmsg
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_errbuf IS NULL ) THEN
                RAISE internal_api_expt;
              ELSE
                RAISE global_api_expt;
              END IF;
            END IF;
            --計画数(最小)の算出
            proc_minimum_plan_qty(
               i_xwsp_rec          => l_xwsp_rec
              ,io_xwypo_tab        => l_xwypo_tab
              ,ov_errbuf           => lv_errbuf
              ,ov_retcode          => lv_retcode
              ,ov_errmsg           => lv_errmsg
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_errbuf IS NULL ) THEN
                RAISE internal_api_expt;
              ELSE
                RAISE global_api_expt;
              END IF;
            END IF;
            --計画数(最大)の算出
            proc_maximum_plan_qty(
               i_xwsp_rec          => l_xwsp_rec
              ,io_xwypo_tab        => l_xwypo_tab
              ,ov_errbuf           => lv_errbuf
              ,ov_retcode          => lv_retcode
              ,ov_errmsg           => lv_errmsg
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_errbuf IS NULL ) THEN
                RAISE internal_api_expt;
              ELSE
                RAISE global_api_expt;
              END IF;
            END IF;
            --計画ロットの決定
            fix_plan_lots(
               i_xwsp_rec          => l_xwsp_rec
              ,i_cp_rec            => l_cp_tab(l_cp_idx)
              ,io_xwypo_tab        => l_xwypo_tab
              ,ov_errbuf           => lv_errbuf
              ,ov_retcode          => lv_retcode
              ,ov_errmsg           => lv_errmsg
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_errbuf IS NULL ) THEN
                RAISE internal_api_expt;
              ELSE
                RAISE global_api_expt;
              END IF;
            END IF;
          END LOOP priority_loop;
        END LOOP xwsp_so_loop;
      EXCEPTION
        WHEN nested_loop_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00060
                         ,iv_token_name1  => cv_msg_00060_token_1
                         ,iv_token_value1 => lv_receipt_org_code
                       );
          RAISE internal_api_expt;
        WHEN zero_divide_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00058
                         ,iv_token_name1  => cv_msg_00058_token_1
                         ,iv_token_value1 => cv_msg_00058_value_1
                         ,iv_token_name2  => cv_msg_00058_token_2
                         ,iv_token_value2 => cv_msg_00058_value_2
                       );
          RAISE internal_api_expt;
      END;
    END LOOP xwsp_ro_loop;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_xwsp;
--
  /**********************************************************************************
   * Procedure Name   : output_xwypo
   * Description      : 横持計画CSV出力(A-4)
   ***********************************************************************************/
  PROCEDURE output_xwypo(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_xwypo'; -- プログラム名
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
    lv_csvbuff                VARCHAR2(5000);             -- 横持計画出力領域
    lv_ship_loct_code         ic_loct_mst.location%TYPE;  -- 移動元保管倉庫
    lv_ship_loct_desc         ic_loct_mst.loct_desc%TYPE; -- 移動元保管倉庫名称
    lv_receipt_loct_code      ic_loct_mst.location%TYPE;  -- 移動先保管倉庫
    lv_receipt_loct_desc      ic_loct_mst.loct_desc%TYPE; -- 移動先保管倉庫名称
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_xwypo_csv_tab           g_xwypo_csv_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --横持計画出力ワークテーブル取得
    SELECT xwypo.shipping_date
          ,xwypo.receipt_date
          ,xwypo.ship_org_code
          ,xwypo.ship_org_name
          ,xwypo.receipt_org_code
          ,xwypo.receipt_org_name
          ,xwypo.item_no
          ,xwypo.item_name
          ,xwypo.manu_date
          ,xwypo.lot_status
          ,xwypo.plan_min_qty
          ,xwypo.plan_max_qty
          ,xwypo.plan_bal_qty
          ,xwypo.delivery_unit
          ,xwypo.before_stock
          ,xwypo.after_stock
          ,( xwypo.safety_days * xwypo.shipping_pace ) safety_stock
          ,( xwypo.max_days    * xwypo.shipping_pace ) max_stock
          ,xwypo.shipping_pace
          ,xwypo.special_yoko_type
          ,xwypo.supp_bad_type
          ,xwypo.lot_revers_type
          ,flv1.description                            freshness_condition
          ,flv2.meaning                                quality_type
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
          ,NVL(TO_NUMBER(iimb.attribute11), 1)         num_of_case
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
    BULK COLLECT INTO l_xwypo_csv_tab
    FROM xxcop_wk_yoko_plan_output xwypo
        ,fnd_lookup_values         flv1
        ,fnd_lookup_values         flv2
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
        ,ic_item_mst_b             iimb
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
    WHERE xwypo.transaction_id = cn_request_id
      AND flv1.lookup_type     = cv_flv_freshness_cond
      AND flv1.lookup_code     = xwypo.freshness_condition
      AND flv1.language        = cv_lang
      AND flv1.source_lang     = cv_lang
      AND flv1.enabled_flag    = cv_enable
      AND cd_sysdate BETWEEN NVL(flv1.start_date_active, cd_sysdate)
                         AND NVL(flv1.end_date_active, cd_sysdate)
      AND flv2.lookup_type(+)  = cv_flv_lot_status
      AND flv2.lookup_code(+)  = xwypo.lot_status
      AND flv2.language(+)     = cv_lang
      AND flv2.source_lang(+)  = cv_lang
      AND flv2.enabled_flag(+) = cv_enable
      AND cd_sysdate BETWEEN NVL(flv2.start_date_active(+), cd_sysdate)
                         AND NVL(flv2.end_date_active(+), cd_sysdate)
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
      AND xwypo.item_id        = iimb.item_id
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
    ORDER BY xwypo.shipping_date      ASC
            ,xwypo.ship_org_code      ASC
            ,xwypo.receipt_org_code   ASC
            ,xwypo.item_no            ASC
            ,xwypo.freshness_priority ASC
            ,xwypo.before_stock       ASC
            ,xwypo.manu_date          ASC
            ,xwypo.lot_status         ASC;
--
    --対象件数をセット
    gn_target_cnt := l_xwypo_csv_tab.COUNT;
    --CSVファイルヘッダ出力
    lv_csvbuff := cv_csv_char_bracket || cv_put_column_01 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_02 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_03 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_04 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_05 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_06 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_07 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_08 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_09 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_10 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_11 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_12 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_13 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_14 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_15 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_16 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_17 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_18 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_19 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_20 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_21 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_22 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_23 || cv_csv_char_bracket;
    --処理結果レポートに出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csvbuff
    );
    --CSVファイル明細出力
    <<xwypo_loop>>
    FOR l_xwypo_idx IN l_xwypo_csv_tab.FIRST .. l_xwypo_csv_tab.LAST LOOP
      --初期化
      lv_csvbuff := NULL;
      --移動元保管倉庫の取得
      xxcop_common_pkg2.get_loct_info(
         iv_organization_code => l_xwypo_csv_tab(l_xwypo_idx).ship_org_code
        ,ov_loct_code         => lv_ship_loct_code
        ,ov_loct_name         => lv_ship_loct_desc
        ,ov_errbuf            => lv_errbuf
        ,ov_retcode           => lv_retcode
        ,ov_errmsg            => lv_errmsg
      );
      --移動先保管倉庫の取得
      xxcop_common_pkg2.get_loct_info(
         iv_organization_code => l_xwypo_csv_tab(l_xwypo_idx).receipt_org_code
        ,ov_loct_code         => lv_receipt_loct_code
        ,ov_loct_name         => lv_receipt_loct_desc
        ,ov_errbuf            => lv_errbuf
        ,ov_retcode           => lv_retcode
        ,ov_errmsg            => lv_errmsg
      );
      --項目の編集
      lv_csvbuff := cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).shipping_date, cv_csv_date_format)
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).receipt_date, cv_csv_date_format)
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || lv_ship_loct_code
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || lv_ship_loct_desc
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || lv_receipt_loct_code
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || lv_receipt_loct_desc
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).item_no
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).item_name
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).freshness_condition
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).manu_date, cv_csv_date_format)
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).quality_type
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).plan_min_qty)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).plan_min_qty
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).plan_max_qty)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).plan_max_qty
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).plan_bal_qty)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).plan_bal_qty
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).delivery_unit
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).before_stock)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).before_stock
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).after_stock)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).after_stock
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).safety_stock)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).safety_stock
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).max_stock)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).max_stock
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).shipping_pace)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).shipping_pace
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).special_yoko_type
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).supp_bad_type
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).lot_revers_type
                 || cv_csv_char_bracket;
      --処理結果レポートに出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csvbuff
      );
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP xwypo_loop;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_xwypo;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_plan_type     IN     VARCHAR2,       -- 1.計画区分
    iv_shipment_from IN     VARCHAR2,       -- 2.出荷ペース計画期間(FROM)
    iv_shipment_to   IN     VARCHAR2,       -- 3.出荷ペース計画期間(TO)
    iv_forcast_type  IN     VARCHAR2,       -- 4.出荷予測区分
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    BEGIN
      -- ===============================
      -- A-1．初期処理
      -- ===============================
      init(
         iv_plan_type                   -- 計画区分
        ,iv_shipment_from               -- 出荷ペース計画期間(FROM)
        ,iv_shipment_to                 -- 出荷ペース計画期間(TO)
        ,iv_forcast_type                -- 出荷予測区分
        ,lv_errbuf                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-2．横持計画制御マスタ取得
      -- ===============================
      get_msr_route(
         lv_errbuf                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-3．物流計画ワークテーブル取得
      -- ===============================
      get_xwsp(
         lv_errbuf                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-4．横持計画CSV出力
      -- ===============================
      output_xwypo(
         lv_errbuf                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
    EXCEPTION
      WHEN global_process_expt THEN
        --対象件数、エラー件数のカウント
        gn_target_cnt := gn_target_cnt + 1;
        gn_error_cnt  := gn_error_cnt + 1;
    END;
--
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      --終了ステータスがエラーの場合、ワークテーブルを残すためコミットする。
      COMMIT;
      IF ( lv_errbuf IS NOT NULL ) THEN
        RAISE global_process_expt;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
    errbuf           OUT    VARCHAR2,       --   エラーメッセージ #固定#
    retcode          OUT    VARCHAR2,       --   エラーコード     #固定#
    iv_plan_type     IN     VARCHAR2,       -- 1.計画区分
    iv_shipment_from IN     VARCHAR2,       -- 2.出荷ペース計画期間(FROM)
    iv_shipment_to   IN     VARCHAR2,       -- 3.出荷ペース計画期間(TO)
    iv_forcast_type  IN     VARCHAR2        -- 4.出荷予測区分
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
    lv_message_code        VARCHAR2(100);
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --正常終了メッセージ
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --警告終了メッセージ
--    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --異常終了メッセージ
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; --異常終了メッセージ
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_plan_type                     -- 計画区分
      ,iv_shipment_from                 -- 出荷ペース計画期間(FROM)
      ,iv_shipment_to                   -- 出荷ペース計画期間(TO)
      ,iv_forcast_type                  -- 出荷予測区分
      ,lv_errbuf                        -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                       -- リターン・コード             --# 固定 #
      ,lv_errmsg                        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
--      --エラー出力
--      fnd_file.put_line(
--         which  => FND_FILE.OUTPUT
--        ,buff => lv_errmsg --ユーザー・エラーメッセージ
--      );
--
--      fnd_file.put_line(
--         which  => FND_FILE.LOG
--        ,buff => lv_errbuf --エラーメッセージ
--      );
      --エラー出力(CSV出力のためログに出力)
      IF ( lv_errmsg IS NOT NULL ) THEN
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff => lv_errmsg --ユーザー・エラーメッセージ
        );
      END IF;
      IF ( lv_errbuf IS NOT NULL ) THEN
        --システムエラーの編集
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00041
                       ,iv_token_name1  => cv_msg_00041_token_1
                       ,iv_token_value1 => lv_errbuf
                     );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff => lv_errbuf --エラーメッセージ
        );
      END IF;
      --空行挿入
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => NULL
      );
    END IF;
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90000'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90001'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90002'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90003'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOP006A01C;
/
