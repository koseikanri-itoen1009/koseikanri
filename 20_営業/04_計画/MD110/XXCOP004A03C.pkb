CREATE OR REPLACE PACKAGE BODY XXCOP004A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A03C(body)
 * Description      : 引取計画集計
 * MD.050           : 引取計画集計 MD050_COP_004_A03
 * Version          : 1.2
 *
 * Program List
 * ------------------------------ ----------------------------------------------------------
 *  Name                           Description
 * ------------------------------ ----------------------------------------------------------
 *  init                           初期処理(A-1)
 *  insert_whse_totaling           分割対象外拠点 出荷倉庫集計データ登録（A-3,A-4）
 *  get_management_forcast_total   分割対象拠点 管理元拠点計画数量集計データ抽出（A-5）
 *  get_management_result_total    分割対象拠点 管理元拠点実績数量集計データ抽出（A-6）
 *  get_whse_totaling              分割対象拠点 管理元出荷倉庫別実績数量データ抽出(A-7)
 *  insert_base_totaling           分割対象拠点 引取計画数量按分データ登録(A-8,A-9)
 *  csv_output                     引取計画集計結果CSV出力(A-10)
 *  output_warn_msg                警告データメッセージ出力
 *  delete_work_table              引取計画集計ワークテーブル削除
 *  submain                        メイン処理プロシージャ
 *  main                           コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/03    1.0  SCS.Kikuchi       新規作成
 *  2009/02/13    1.1  SCS.Kikuchi       結合テスト仕様変更（結合障害No.008,009）
 *  2009/04/07    1.2  SCS.Kikuchi       T1_0271対応
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
  internal_process_expt        EXCEPTION;     -- 内部PROCEDURE/FUNCTIONエラーハンドリング用
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOP004A03C';        -- パッケージ名

  -- 入力パラメータログ出力用
  cv_pm_base_code_tl            CONSTANT VARCHAR2(100) := '拠点';
  cv_pm_prod_class_code_tl      CONSTANT VARCHAR2(100) := '商品区分';
  cv_pm_results_clt_prd_tl      CONSTANT VARCHAR2(100) := '実績収集期間';
  cv_pm_forecast_clt_prd_tl     CONSTANT VARCHAR2(100) := '計画収集期間';
  cv_pm_part                    CONSTANT VARCHAR2(6)   := '　：　';
  cv_pm_part2                   CONSTANT VARCHAR2(6)   := '　～　';

  -- 日付変換書式
  cv_date_format1               CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24MISS';
  cv_date_format2               CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';
  cv_date_format3               CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_date_format4               CONSTANT VARCHAR2(2)   := 'DD';
  cv_date_format5               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_date_format6               CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  cv_date_start_time            CONSTANT VARCHAR2(6)   := '000000';
  cv_date_end_time              CONSTANT VARCHAR2(6)   := '235959';

  -- 検索条件リテラル値
  cv_forecast_class             CONSTANT VARCHAR2(2)   := '01';                         -- フォーキャスト分類：引取計画
  cv_flv_lookup_type            CONSTANT VARCHAR2(100) := 'XXCOP1_DIVISION_TARGET_BASE';-- クイックコード：分割対象拠点
  cv_flv_language               CONSTANT VARCHAR2(2)   := USERENV('LANG');
  cv_flv_enabled_flag           CONSTANT VARCHAR2(1)   := 'Y';
  cv_customer_class_code_base   CONSTANT VARCHAR2(1)   := '1';                -- 顧客区分（拠点）
  cv_leaf_whse_code             CONSTANT VARCHAR2(5)   := '12020';            -- ﾘｰﾌ･相良倉庫
  cv_drink_whse_code            CONSTANT VARCHAR2(5)   := '22100';            -- ﾄﾞﾘﾝｸ･飲料部
  cv_inactive_ind               CONSTANT VARCHAR2(1)   := '1';                -- 無効
  cv_inventory_item_status_code CONSTANT VARCHAR2(20)  := 'Inactive';         -- 品目ステータス
  cv_obsolete_class             CONSTANT VARCHAR2(1)   := '1';                -- 廃止区分
  cv_no_shipment_results        CONSTANT VARCHAR2(1)   := '*';                -- 出荷実績なし
  cv_schedule_type              CONSTANT VARCHAR2(1)   := '1';                -- 計画区分
  -- 物流構成表データ警告区分
  cv_srwt_0                     CONSTANT VARCHAR2(1)   := '0';                -- 正常
  cv_srwt_1                     CONSTANT VARCHAR2(1)   := '1';                -- 分割対象外：物流構成表倉庫不一致
  cv_srwt_2                     CONSTANT VARCHAR2(1)   := '2';                -- 分割対象外：物流構成表未存在
  cv_srwt_3                     CONSTANT VARCHAR2(1)   := '3';                -- 分割対象：物流構成表無
  cv_srwt_4                     CONSTANT VARCHAR2(1)   := '4';                -- 分割対象：物流構成表有(合計実績数無）
  -- 集計開始日：日付
  cv_week_day_1                 CONSTANT VARCHAR2(2)   := '07';               -- １週目：開始日付
  cv_week_day_2                 CONSTANT VARCHAR2(2)   := '14';               -- ２週目：開始日付
  cv_week_day_3                 CONSTANT VARCHAR2(2)   := '21';               -- ３週目：開始日付
  -- 計画商品フラグ置換用
 cv_planed_item_flg_0           CONSTANT VARCHAR2(1)   := '0';
 cv_planed_item_flg_1           CONSTANT VARCHAR2(1)   := '1';
 cv_planed_item_flg_null        CONSTANT VARCHAR2(1)   := NULL;

  -- メッセージ関連
  cv_msg_application            CONSTANT VARCHAR2(100) := 'XXCOP';
  cv_param_chk_msg1             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';
  cv_param_chk_msg1_tkn_lbl1    CONSTANT VARCHAR2(100) := 'PERIOD_FROM';
  cv_param_chk_msg1_tkn_lbl2    CONSTANT VARCHAR2(100) := 'PERIOD_TO';
  cv_param_chk_msg1_tkn_val1_1  CONSTANT VARCHAR2(100) := '実績収集期間（FROM）';
  cv_param_chk_msg1_tkn_val2_1  CONSTANT VARCHAR2(100) := '実績収集期間（TO）';
  cv_param_chk_msg1_tkn_val1_2  CONSTANT VARCHAR2(100) := '計画収集期間（FROM）';
  cv_param_chk_msg1_tkn_val2_2  CONSTANT VARCHAR2(100) := '計画収集期間（TO）';
  cv_param_chk_msg2             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';
  cv_param_chk_msg2_tkn_lbl1    CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_param_chk_msg2_tkn_val1_1  CONSTANT VARCHAR2(100) := '実績収集期間（FROM）';
  cv_param_chk_msg2_tkn_val1_2  CONSTANT VARCHAR2(100) := '実績収集期間（TO）';
  cv_param_chk_msg3             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10009';
  cv_param_chk_msg3_tkn_lbl1    CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_param_chk_msg3_tkn_val1_1  CONSTANT VARCHAR2(100) := '計画収集期間（FROM）';
  cv_param_chk_msg3_tkn_val1_2  CONSTANT VARCHAR2(100) := '計画収集期間（TO）';
  cv_param_chk_msg4             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';
  cv_param_chk_msg4_tkn_lbl1    CONSTANT VARCHAR2(100) := 'PROF_NAME';
  cv_param_chk_msg4_tkn_val1    CONSTANT VARCHAR2(100) := '実績収集日数';
  cv_ins_err_msg                CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';
  cv_ins_err_msg_tkn_lbl1       CONSTANT VARCHAR2(100) := 'TABLE';
  cv_ins_err_msg_tkn_val1       CONSTANT VARCHAR2(100) := '引取計画集計ワークテーブル';
  cv_others_err_msg             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';
  cv_others_err_msg_tkn_lbl1    CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_norules1_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10001';
  cv_norules1_err_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'ITEM';
  cv_norules1_err_msg_tkn_lbl2  CONSTANT VARCHAR2(100) := 'BASE';
--★v1.1 Upd Start
  cv_norules1_err_msg_tkn_lbl3  CONSTANT VARCHAR2(100) := 'WHSE';
--★  cv_norules1_err_msg_tkn_lbl3  CONSTANT VARCHAR2(100) := 'YYYYMMDD';
--★  cv_norules1_err_msg_tkn_lbl4  CONSTANT VARCHAR2(100) := 'WHSE';
--★v1.1 Upd End
  cv_norules2_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10005';
  cv_norules2_err_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'ITEM';
  cv_norules2_err_msg_tkn_lbl2  CONSTANT VARCHAR2(100) := 'BASE';
--★v1.1 Del  cv_norules2_err_msg_tkn_lbl3  CONSTANT VARCHAR2(100) := 'FROM';
--★v1.1 Del  cv_norules2_err_msg_tkn_lbl4  CONSTANT VARCHAR2(100) := 'TO';
  cv_noresult_note_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10010';

  -- CSV出力用
  cv_csv_part                   CONSTANT VARCHAR2(1)   := '"';
  cv_csv_cont                   CONSTANT VARCHAR2(1)   := ',';
  cv_csv_header1                CONSTANT VARCHAR2(100) := '計画区分';
  cv_csv_header2                CONSTANT VARCHAR2(100) := '出荷倉庫';
  cv_csv_header3                CONSTANT VARCHAR2(100) := '商品区分';
  cv_csv_header4                CONSTANT VARCHAR2(100) := '品目コード';
  cv_csv_header5                CONSTANT VARCHAR2(100) := '集計期間(FROM)';
  cv_csv_header6                CONSTANT VARCHAR2(100) := '集計期間(TO)';
  cv_csv_header7                CONSTANT VARCHAR2(100) := '引取数量合計';
  cv_csv_header8                CONSTANT VARCHAR2(100) := '計画商品フラグ';
  cv_csv_header9                CONSTANT VARCHAR2(100) := '出荷実績なし';
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 引取計画集計レコード型（分割対象拠点－管理元拠点単位）
  TYPE frcst_base_total1_trec IS RECORD(
      schedule_type        xxcop_wk_forecast_totaling.schedule_type      %TYPE    -- 計画区分
    , management_base_code xxcop_wk_forecast_totaling.base_code          %TYPE    -- 管理元拠点
    , forecast_whse_code   xxcop_wk_forecast_totaling.whse_code          %TYPE    -- フォーキャスト出荷倉庫
    , prod_class           xxcop_wk_forecast_totaling.prod_class         %TYPE    -- 商品区分
    , item_code            xxcop_wk_forecast_totaling.item_code          %TYPE    -- 品目コード
    , count_period_from    xxcop_wk_forecast_totaling.count_period_from  %TYPE    -- 集計期間From
    , count_period_to      xxcop_wk_forecast_totaling.count_period_to    %TYPE    -- 集計期間To
    , forecast_qty         NUMBER                                                 -- 管理元拠点集計：引取計画数量
    , ship_result_qty      NUMBER                                                 -- 管理元拠点集計：出荷実績数量
    );

  -- 引取計画集計PL/SQL表（分割対象拠点－管理元拠点単位）
  TYPE frcst_base_total1_ttype IS
    TABLE OF frcst_base_total1_trec INDEX BY BINARY_INTEGER;

  -- 引取計画集計レコード型（分割対象拠点－配下拠点単位）
  TYPE frcst_base_total2_trec IS RECORD(
      whse_code                xxcop_wk_forecast_totaling.whse_code               %TYPE  -- 倉庫
    , planed_item_flg          xxcop_wk_forecast_totaling.planed_item_flg         %TYPE  -- 計画商品フラグ
    , no_shipment_results      xxcop_wk_forecast_totaling.no_shipment_results     %TYPE  -- 出荷実績なし
    , sourcing_rules_warn_type xxcop_wk_forecast_totaling.sourcing_rules_warn_type%TYPE  -- 物流構成表データ警告区分
    , base_code                xxcop_wk_forecast_totaling.base_code               %TYPE  -- 配下拠点
    , ship_result_qty          NUMBER                                                    -- 出荷倉庫集計：出荷実績数量
    );

  -- 引取計画集計PL/SQL表（分割対象拠点－配下拠点単位）
  TYPE frcst_base_total2_ttype IS
    TABLE OF frcst_base_total2_trec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ格納用変数
  gv_base_code                   VARCHAR2(4);              -- 1.拠点
  gv_prod_class_code             VARCHAR2(1);              -- 2.商品区分
  gd_results_collect_period_st   DATE;                     -- 3.実績収集期間（自）
  gd_results_collect_period_ed   DATE;                     -- 4.実績収集期間（至）
  gd_forecast_collect_period_st  DATE;                     -- 5.計画収集期間（自）
  gd_forecast_collect_period_ed  DATE;                     -- 6.計画収集期間（至）
  
  -- 処理制御用変数
  gd_sysdate                     DATE;                     -- システム日付
  gd_totaling_start_date         DATE;                     -- 集計開始日
  gd_totaling_end_date           DATE;                     -- 集計終了日
  g_frcst_base_total_tbl1        frcst_base_total1_ttype;  -- 引取計画集計PL/SQL表（分割対象拠点－管理元配下拠点単位）
  g_frcst_base_total_tbl1_init   frcst_base_total1_ttype;  -- 初期化用
  g_frcst_base_total_tbl2        frcst_base_total2_ttype;  -- 引取計画集計PL/SQL表（分割対象拠点－配下拠点単位）
  g_frcst_base_total_tbl2_init   frcst_base_total2_ttype;  -- 初期化用
  gn_base_total_amount           NUMBER;                   -- 管理元拠点単位 実績数量加算
  gn_internal_warn_cnt           NUMBER;                   -- 内部警告件数
  gn_noresults_cnt               NUMBER;                   -- 出荷実績なし件数

  -- デバッグ用
  gv_debug_mode                  VARCHAR2(30);
--
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    --------------------------------------------------------
    -- 1.日付逆転チェック
    --------------------------------------------------------
    --(1)実績収集期間
    IF (gd_results_collect_period_st > gd_results_collect_period_ed) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg1
                    ,iv_token_name1  => cv_param_chk_msg1_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg1_tkn_val1_1
                    ,iv_token_name2  => cv_param_chk_msg1_tkn_lbl2
                    ,iv_token_value2 => cv_param_chk_msg1_tkn_val2_1
                   );
      RAISE internal_process_expt;
    END IF;

    --(2)計画収集期間
    IF (gd_forecast_collect_period_st > gd_forecast_collect_period_ed) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg1
                    ,iv_token_name1  => cv_param_chk_msg1_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg1_tkn_val1_2
                    ,iv_token_name2  => cv_param_chk_msg1_tkn_lbl2
                    ,iv_token_value2 => cv_param_chk_msg1_tkn_val2_2
                   );
      RAISE internal_process_expt;
    END IF;

    --------------------------------------------------------
    -- 2.未来日チェック
    --------------------------------------------------------
    --(1)実績収集期間（自）
    IF  (gd_results_collect_period_st > gd_sysdate) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg2
                    ,iv_token_name1  => cv_param_chk_msg2_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg2_tkn_val1_1
                   );
      RAISE internal_process_expt;
    END IF;

    --(2)実績収集期間（至）
    IF  (TRUNC(gd_results_collect_period_ed) > gd_sysdate) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg2
                    ,iv_token_name1  => cv_param_chk_msg2_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg2_tkn_val1_2
                   );
      RAISE internal_process_expt;
    END IF;

    --------------------------------------------------------
    -- 3.過去日チェック
    --------------------------------------------------------
    --(1)計画収集期間（自）
    IF  (gd_forecast_collect_period_st < gd_sysdate) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg3
                    ,iv_token_name1  => cv_param_chk_msg3_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg3_tkn_val1_1
                   );
      RAISE internal_process_expt;
    END IF;

    --(2)計画収集期間（至）
    IF  (TRUNC(gd_forecast_collect_period_ed) < gd_sysdate) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg3
                    ,iv_token_name1  => cv_param_chk_msg3_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg3_tkn_val1_2
                   );
      RAISE internal_process_expt;
    END IF;

    --------------------------------------------------------
    -- 4.WHO情報取得
    --   ※変数定義部で設定済み
    --------------------------------------------------------
    NULL;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
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
   * Procedure Name   : insert_whse_totaling
   * Description      : 分割対象外拠点 出荷倉庫集計データ登録(A-3,A-4)
   *                    対象データ抽出（出荷倉庫集計）(A-3)
   *                    ワークテーブル登録(A-4)
   *                    ※処理簡略化の為、INSERT～SELECTに変更
   ***********************************************************************************/
  PROCEDURE insert_whse_totaling(
     ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_whse_totaling'; -- プログラム名
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
    -----------------------------------------------------------
    -- 引取計画集計ワークテーブル登録
    --  （分割対象外拠点 品目、拠点、出荷倉庫単位集計）
    -----------------------------------------------------------
    INSERT
    INTO   xxcop_wk_forecast_totaling(
        schedule_type                               -- 計画区分
      , whse_code                                   -- 出荷倉庫
      , prod_class                                  -- 商品区分
      , item_code                                   -- 品目コード
      , count_period_from                           -- 集計期間From
      , count_period_to                             -- 集計期間To
      , total_amount                                -- 引取数量合計
      , planed_item_flg                             -- 計画商品フラグ
      , no_shipment_results                         -- 出荷実績なし
      , sourcing_rules_warn_type                    -- 物流構成表データ警告区分
      , base_code                                   -- 拠点
      , forecast_date                               -- フォーキャスト日付
      , created_by                                  -- 作成者
      , creation_date                               -- 作成日
      , last_updated_by                             -- 最終更新者
      , last_update_date                            -- 最終更新日
      , last_update_login                           -- 最終更新ログイン
      , request_id                                  -- 要求ID
      , program_application_id                      -- プログラムアプリケーションID
      , program_id                                  -- プログラムID
      , program_update_date                         -- プログラム更新日
      )
    SELECT
        cv_schedule_type                     schedule_type                            -- 計画区分：出荷予測
      , DECODE( v1.prod_class_code||v1.whse_code
                        ,v1.prod_class_code||xsr.delivery_whse_code ,v1.whse_code
                        ,cv_leaf_whse_code                          ,NVL(xsr.delivery_whse_code,v1.whse_code)
                        ,cv_drink_whse_code                         ,NVL(xsr.delivery_whse_code,v1.whse_code)
                                                                    ,v1.whse_code
              ) whse_code                                                             -- 出荷管理先コード
      , v1.prod_class_code                   prod_class                               -- 商品区分
      , v1.item_no                           item_code                                -- 品目コード
      , gd_totaling_start_date               count_period_from                        -- 集計開始日
      , gd_totaling_end_date                 count_period_to                          -- 集計終了日
      , v1.original_forecast_quantity        total_amount                             -- 数量
      , DECODE( v1.prod_class_code||v1.whse_code
                        ,v1.prod_class_code||xsr.delivery_whse_code ,xsr.plan_item_flag
                        ,cv_leaf_whse_code                 ,NVL2(xsr.delivery_whse_code,xsr.plan_item_flag,null)
                        ,cv_drink_whse_code                ,NVL2(xsr.delivery_whse_code,xsr.plan_item_flag,null)
                                                           ,null
              ) planed_item_flg                                                       -- 計画商品フラグ
      , NULL                                 no_shipment_results                      -- 出荷実績なし
      , DECODE( v1.prod_class_code||v1.whse_code
                        ,v1.prod_class_code||xsr.delivery_whse_code ,cv_srwt_0
                        ,cv_leaf_whse_code                          ,NVL2(xsr.delivery_whse_code,cv_srwt_0,cv_srwt_2)
                        ,cv_drink_whse_code                         ,NVL2(xsr.delivery_whse_code,cv_srwt_0,cv_srwt_2)
                                                                    ,NVL2(xsr.delivery_whse_code,cv_srwt_1,cv_srwt_2)
              ) sourcing_rules_warn_type                                              -- 物流構成表データ警告区分
      , v1.base_code                 base_code                                        -- 拠点
      , v1.forecast_date             forecast_date                                    -- フォーキャスト日付
      , cn_created_by                created_by                                       -- 作成者
      , cd_creation_date             creation_date                                    -- 作成日
      , cn_last_updated_by           last_updated_by                                  -- 最終更新者
      , cd_last_update_date          last_update_date                                 -- 最終更新日
      , cn_last_update_login         last_update_login                                -- 最終更新ログイン
      , cn_request_id                request_id                                       -- 要求ID
      , cn_program_application_id    program_application_id                           -- プログラムアプリケーションID
      , cn_program_id                program_id                                       -- プログラムID
      , cd_program_update_date       program_update_date                              -- プログラム更新日
     FROM
     ( SELECT
           mfde.attribute3                 base_code                                  -- 拠点
         , mfde.attribute2                 whse_code                                  -- 出荷管理先コード
         , xic1v.prod_class_code           prod_class_code                            -- 商品区分
         , xic1v.item_no                   item_no                                    -- 品目コード
         , mfda.original_forecast_quantity original_forecast_quantity                 -- 数量
         , mfda.forecast_date              forecast_date                              -- フォーキャスト日付
       FROM
              mrp_forecast_designators mfde                                           -- フォーキャスト名
         ,    mrp_forecast_dates       mfda                                           -- フォーキャスト日付
         ,    xxcop_item_categories1_v xic1v                                          -- 計画_品目カテゴリビュー1
       WHERE
              mfde.forecast_designator         =  mfda.forecast_designator            -- フォーキャスト名
       AND    mfde.organization_id             =  mfda.organization_id                -- 組織ID
       AND    mfde.attribute1                  =  cv_forecast_class                   -- FORECAST分類：引取計画
       AND    mfde.attribute3                  =  NVL(gv_base_code,mfde.attribute3)   -- 拠点コード
       AND    mfda.forecast_date               BETWEEN gd_totaling_start_date
                                               AND     gd_totaling_end_date
       AND    xic1v.inventory_item_id          =  mfda.inventory_item_id
       AND    xic1v.start_date_active          <= mfda.forecast_date
       AND    xic1v.end_date_active            >= mfda.forecast_date
       AND    xic1v.prod_class_code            =  gv_prod_class_code                  -- 商品区分
       AND    xic1v.inactive_ind               <> cv_inactive_ind                     -- 無効
       AND    xic1v.inventory_item_status_code <> cv_inventory_item_status_code       -- 品目ステータス
       AND    xic1v.obsolete_class             <> cv_obsolete_class                   -- 廃止区分
       AND    NOT EXISTS(                         
                SELECT 'X'
                FROM   fnd_lookup_values                                              -- クイックコード
                WHERE  lookup_type  = cv_flv_lookup_type
                AND    language     = cv_flv_language
                AND    description  = mfde.attribute3
                AND    enabled_flag = cv_flv_enabled_flag
                AND    mfda.forecast_date  BETWEEN NVL(start_date_active ,mfda.forecast_date)
                                               AND NVL(end_date_active   ,mfda.forecast_date)
             )
     )v1
       ,    xxcmn_sourcing_rules   xsr                                                -- 物流構成表アドオン
     WHERE  xsr.item_code         (+)    =  v1.item_no                                -- 品目コード
     AND    xsr.base_code         (+)    =  v1.base_code                              -- 拠点
     AND    xsr.start_date_active (+)    <= v1.forecast_date                          -- 適用開始日
     AND    xsr.end_date_active   (+)    >= v1.forecast_date                          -- 適用終了日
     ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --↓ユーザエラーメッセージ追加↓
      ov_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_ins_err_msg
                    ,iv_token_name1  => cv_ins_err_msg_tkn_lbl1
                    ,iv_token_value1 => cv_ins_err_msg_tkn_val1
                    );
      --↑ユーザエラーメッセージ追加↑
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_whse_totaling;
--
  /**********************************************************************************
   * Procedure Name   : get_management_forcast_total
   * Description      : 分割対象拠点 管理元拠点計画数量集計データ抽出（A-5）
   ***********************************************************************************/
  PROCEDURE get_management_forcast_total(
     ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_management_forcast_total'; -- プログラム名
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
    ------------------------------------------------------------
    --  分割対象拠点 管理元拠点抽出
    --   管理元拠点に紐付く全拠点の計画数量を、
    --   品目、管理元拠点単位に集計する。
    ------------------------------------------------------------
    SELECT cv_schedule_type                            schedule_type                 -- 計画区分：出荷予測
       ,   mfde.attribute3                             management_base_code          -- 管理元拠点
       ,   mfde.attribute2                             forecast_whse_code            -- 出荷倉庫
       ,   xic1v.prod_class_code                       prod_class_code               -- 商品区分
       ,   xic1v.item_no                               item_no                       -- 品目コード
       ,   gd_totaling_start_date                      totaling_start_date           -- 集計開始日
       ,   gd_totaling_end_date                        totaling_end_date             -- 集計終了日
       ,   SUM(NVL(mfda.original_forecast_quantity,0)) original_forecast_quantity    -- 引取計画数量
       ,   NULL
    BULK COLLECT
    INTO 
           g_frcst_base_total_tbl1
    FROM   mrp_forecast_designators mfde                                           -- フォーキャスト名
      ,    mrp_forecast_dates       mfda                                           -- フォーキャスト日付
      ,    xxcop_item_categories1_v xic1v                                          -- 計画_品目カテゴリビュー1
    WHERE
           mfde.forecast_designator         =  mfda.forecast_designator            -- フォーキャスト名
    AND    mfde.organization_id             =  mfda.organization_id                -- 組織ID
    AND    mfde.attribute1                  =  cv_forecast_class
    AND    mfde.attribute3                  =  NVL(gv_base_code,mfde.attribute3)
    AND    mfda.forecast_date               BETWEEN gd_totaling_start_date
                                            AND     gd_totaling_end_date
    AND    xic1v.inventory_item_id          =  mfda.inventory_item_id
    AND    xic1v.start_date_active          <= mfda.forecast_date
    AND    xic1v.end_date_active            >= mfda.forecast_date
    AND    xic1v.prod_class_code            =  gv_prod_class_code
    AND    xic1v.inactive_ind               <> cv_inactive_ind                     -- 無効
    AND    xic1v.inventory_item_status_code <> cv_inventory_item_status_code       -- 品目ステータス
    AND    xic1v.obsolete_class             <> cv_obsolete_class                   -- 廃止区分
    AND    EXISTS(
             SELECT 'X'
             FROM   fnd_lookup_values                                              -- クイックコード表
             WHERE  lookup_type  = cv_flv_lookup_type
             AND    language     = cv_flv_language
             AND    description  = mfde.attribute3
             AND    enabled_flag = cv_flv_enabled_flag
             AND    mfda.forecast_date   BETWEEN NVL(start_date_active ,mfda.forecast_date)
                                             AND NVL(end_date_active   ,mfda.forecast_date)
           )
    GROUP
    BY     mfde.attribute3
      ,    mfde.attribute2
      ,    xic1v.prod_class_code
      ,    xic1v.item_no
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_management_forcast_total;
--
--
  /**********************************************************************************
   * Procedure Name   : get_management_result_total
   * Description      : 分割対象拠点 管理元拠点実績数量集計データ抽出（A-6）
   ***********************************************************************************/
  PROCEDURE get_management_result_total(
     in_index             IN  NUMBER      --   管理元拠点集計データ抽出ループIndex
   , ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_management_result_total'; -- プログラム名
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
    ------------------------------------------------------------
    --  管理元拠点実績数量集計データ抽出
    --   A-5で取得した品目、管理元拠点毎に、
    --   管理元拠点に紐付く全拠点、全倉庫の実績数量を集計する。
    ------------------------------------------------------------
    SELECT  
            SUM(NVL(xsrst.quantity,0))         quantity                                -- 出荷実績数量
    INTO 
            g_frcst_base_total_tbl1(in_index).ship_result_qty                          -- 管理元拠点集計：出荷実績数量
    FROM( 
      SELECT    v1.management_base_code        management_base_code                    -- 管理元拠点
              , v1.base_code                   base_code                               -- 配下拠点
              , v1.item_no                     item_no                                 -- 品目コード
              , xsr.delivery_whse_code         delivery_whse_code                      -- 倉庫
      FROM(
        SELECT
               mfde.attribute3                 management_base_code                    -- 管理元拠点
          ,    hca.account_number              base_code                               -- 配下拠点
          ,    xic1v.item_no                   item_no                                 -- 品目コード
          ,    mfda.forecast_date              forecast_date                           -- フォーキャスト日付
        FROM
               mrp_forecast_designators mfde                                           -- フォーキャスト名
          ,    mrp_forecast_dates       mfda                                           -- フォーキャスト日付
          ,    xxcop_item_categories1_v xic1v                                          -- 計画_品目カテゴリビュー1
          ,    xxcmm_cust_accounts      xca                                            -- 顧客追加情報
          ,    hz_cust_accounts         hca                                            -- 顧客マスタ
        WHERE
               mfde.forecast_designator         =  mfda.forecast_designator            -- フォーキャスト名
        AND    mfde.organization_id             =  mfda.organization_id                -- 組織ID
        AND    mfde.attribute1                  =  cv_forecast_class
        AND    mfde.attribute2                  =  g_frcst_base_total_tbl1(in_index).forecast_whse_code
        AND    mfde.attribute3                  =  g_frcst_base_total_tbl1(in_index).management_base_code
        AND    mfda.forecast_date               BETWEEN gd_totaling_start_date
                                                AND     gd_totaling_end_date
        AND    xic1v.inventory_item_id          =  mfda.inventory_item_id
        AND    xic1v.item_no                    =  g_frcst_base_total_tbl1(in_index).item_code
        AND    xic1v.start_date_active          <= mfda.forecast_date
        AND    xic1v.end_date_active            >= mfda.forecast_date
        AND    xic1v.prod_class_code            =  gv_prod_class_code
        AND    xic1v.inactive_ind               <> cv_inactive_ind                     -- 無効
        AND    xic1v.inventory_item_status_code <> cv_inventory_item_status_code       -- 品目ステータス
        AND    xic1v.obsolete_class             <> cv_obsolete_class                   -- 廃止区分
        AND    (   xca.management_base_code     =  mfde.attribute3
               OR  hca.account_number           =  mfde.attribute3  )
        AND    hca.cust_account_id              =  xca.customer_id
        AND    hca.customer_class_code          =  cv_customer_class_code_base         -- 顧客区分
      )v1
        ,    xxcmn_sourcing_rules     xsr                                -- 物流構成表アドオン
      WHERE  xsr.item_code             (+) =  v1.item_no
      AND    xsr.base_code             (+) =  v1.base_code
      AND    xsr.start_date_active     (+) <= v1.forecast_date
      AND    xsr.end_date_active       (+) >= v1.forecast_date
      GROUP
      BY  v1.management_base_code                                              -- 管理元拠点
        , v1.base_code                                                         -- 配下拠点
        , v1.item_no                                                           -- 品目コード
        , xsr.delivery_whse_code                                               -- 倉庫
    )v2
      ,    xxcop_shipment_results   xsrst                                      -- 親コード出荷実績表
    WHERE  xsrst.item_no             (+) =  v2.item_no
    AND    xsrst.base_code           (+) =  v2.base_code
    AND    xsrst.latest_deliver_from (+) =  v2.delivery_whse_code
    AND    xsrst.shipment_date       (+) BETWEEN gd_results_collect_period_st
                                         AND     gd_results_collect_period_ed
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_management_result_total;
--
  /**********************************************************************************
   * Procedure Name   : get_whse_totaling
   * Description      : 分割対象拠点 管理元出荷倉庫別実績数量データ抽出(A-7)
   ***********************************************************************************/
  PROCEDURE get_whse_totaling(
     in_index             IN  NUMBER      --   管理元拠点集計データ抽出ループIndex
   , ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_whse_totaling'; -- プログラム名
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
    -----------------------------------------------------------------
    -- 出荷倉庫別出荷実績抽出
    --  管理元拠点に紐付く拠点から物流構成表より出荷倉庫を特定し、
    --  その拠点、倉庫単位で実績数量を集計する
    -----------------------------------------------------------------
    SELECT  
            v2.delivery_whse_code                           delivery_whse_code            -- 出荷倉庫
       ,    SUBSTRB(TO_CHAR(v2.plan_item_flag),9,1)         plan_item_flag                -- 計画商品フラグ
       ,    NVL2(xsrst.item_no,NULL,cv_no_shipment_results) no_shipment_results           -- 出荷実績なし
       ,    v2.sourcing_rules_warn_type                     sourcing_rules_warn_type      -- 物流構成表データ警告区分
       ,    v2.base_code                                    base_code                     -- 配下拠点
       ,    SUM(NVL(xsrst.quantity,0))                      quantity                      -- 出荷実績数量
    BULK COLLECT
    INTO 
           g_frcst_base_total_tbl2
    FROM( 
      SELECT v1.management_base_code           management_base_code      -- 管理元拠点
           , v1.item_no                        item_no                   -- 品目コード
           , v1.base_code                      base_code                 -- 配下拠点
           , xsr.delivery_whse_code            delivery_whse_code        -- 倉庫
           , MAX(TO_CHAR(v1.forecast_date,cv_date_format6)
             ||xsr.plan_item_flag) plan_item_flag                        -- 計画商品フラグ
           , NVL2(xsr.delivery_whse_code
                       ,DECODE(g_frcst_base_total_tbl1(in_index).ship_result_qty ,0 ,cv_srwt_4
                                                                                    ,cv_srwt_0)
                       ,cv_srwt_3
                                            )  sourcing_rules_warn_type  -- 物流構成表データ警告区分
      FROM(
        SELECT
               mfde.attribute3                 management_base_code                    -- 管理元拠点
          ,    hca.account_number              base_code                               -- 配下拠点
          ,    xic1v.item_no                   item_no                                 -- 品目コード
          ,    mfda.forecast_date              forecast_date                           -- フォーキャスト日付
        FROM
               mrp_forecast_designators mfde                                           -- フォーキャスト名
          ,    mrp_forecast_dates       mfda                                           -- フォーキャスト日付
          ,    xxcop_item_categories1_v xic1v                                          -- 計画_品目カテゴリビュー1
          ,    xxcmm_cust_accounts      xca                                            -- 顧客追加情報
          ,    hz_cust_accounts         hca                                            -- 顧客マスタ
        WHERE
               mfde.forecast_designator         =  mfda.forecast_designator            -- フォーキャスト名
        AND    mfde.organization_id             =  mfda.organization_id                -- 組織ID
        AND    mfde.attribute1                  =  cv_forecast_class
        AND    mfde.attribute2                  =  g_frcst_base_total_tbl1(in_index).forecast_whse_code
        AND    mfde.attribute3                  =  g_frcst_base_total_tbl1(in_index).management_base_code
        AND    mfda.forecast_date               BETWEEN gd_totaling_start_date
                                                AND     gd_totaling_end_date
        AND    xic1v.inventory_item_id          =  mfda.inventory_item_id
        AND    xic1v.item_no                    =  g_frcst_base_total_tbl1(in_index).item_code
        AND    xic1v.start_date_active          <= mfda.forecast_date
        AND    xic1v.end_date_active            >= mfda.forecast_date
        AND    xic1v.prod_class_code            =  gv_prod_class_code
        AND    xic1v.inactive_ind               <> cv_inactive_ind                     -- 無効
        AND    xic1v.inventory_item_status_code <> cv_inventory_item_status_code       -- 品目ステータス
        AND    xic1v.obsolete_class             <> cv_obsolete_class                   -- 廃止区分
        AND    (   xca.management_base_code     =  mfde.attribute3
               OR  hca.account_number           =  mfde.attribute3  )
        AND    hca.cust_account_id              =  xca.customer_id
        AND    hca.customer_class_code          =  cv_customer_class_code_base         -- 顧客区分
      )v1
        ,    xxcmn_sourcing_rules     xsr                                -- 物流構成表アドオン
      WHERE  xsr.item_code             (+) =  v1.item_no
      AND    xsr.base_code             (+) =  v1.base_code
      AND    xsr.start_date_active     (+) <= v1.forecast_date
      AND    xsr.end_date_active       (+) >= v1.forecast_date
      GROUP
      BY     v1.management_base_code
           , v1.item_no
           , v1.base_code
           , xsr.delivery_whse_code
           , NVL2(xsr.delivery_whse_code
                       ,DECODE(g_frcst_base_total_tbl1(in_index).ship_result_qty ,0 ,cv_srwt_4
                                                                                    ,cv_srwt_0)
                       ,cv_srwt_3
                 )
    )v2
      ,    xxcop_shipment_results   xsrst                                      -- 親コード出荷実績表
    WHERE  xsrst.item_no             (+) =  v2.item_no
    AND    xsrst.base_code           (+) =  v2.base_code
    AND    xsrst.latest_deliver_from (+) =  v2.delivery_whse_code
    AND    xsrst.shipment_date       (+) BETWEEN gd_results_collect_period_st
                                         AND     gd_results_collect_period_ed
    GROUP
    BY      v2.delivery_whse_code                                                 -- 出荷倉庫
       ,    SUBSTRB(TO_CHAR(v2.plan_item_flag),9,1)                               -- 計画商品フラグ
       ,    NVL2(xsrst.item_no,NULL,cv_no_shipment_results)                       -- 出荷実績なし
       ,    v2.sourcing_rules_warn_type                                           -- 物流構成表データ警告区分
       ,    v2.base_code                                                          -- 配下拠点
    ORDER
    BY     DECODE(SUM(NVL(xsrst.quantity,0)),0,0
                                              ,1 )                                -- 数量ゼロを先にソートする
      ,    v2.delivery_whse_code                                                  -- 出荷保管倉庫コード
      ,    v2.base_code                                                           -- 配下拠点
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_whse_totaling;
--
--
  /**********************************************************************************
   * Procedure Name   : insert_base_totaling
   * Description      : 分割対象拠点 引取計画数量按分データ登録(A-8,A-9)
   *                    引取計画数按分(A-8)
   *                    引取計画集計(按分)ワークテーブル登録(A-9)
   *                    ※処理簡略化の為、A-8,A-9を統合
   ***********************************************************************************/
  PROCEDURE insert_base_totaling(
     in_index             IN  NUMBER      --   管理元拠点集計データ抽出ループIndex
   , in_index2            IN  NUMBER      --   配下拠点・出荷倉庫別出荷実績抽出ループIndex
   , ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_base_totaling'; -- プログラム名
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
    xxcop_wk_forecast_totaling_rec    xxcop_wk_forecast_totaling%rowtype;
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
    IF (in_index2 IS NOT NULL) THEN

      -- 出荷倉庫単位実績数量合がゼロより大きい場合のみ按分を行なう
      IF (g_frcst_base_total_tbl2(in_index2).ship_result_qty > 0) THEN

        -- 管理元拠点単位での按分の余りをセットする為、
        -- 最終レコードに管理元拠点単位実績数量合計－現在までのトータル数量をセットする。
        -- （按分を行なわない実績数量≠ゼロのデータをソート順で後方に持ってきている）
        IF (g_frcst_base_total_tbl2.COUNT = in_index2) THEN
          xxcop_wk_forecast_totaling_rec.total_amount
                               := g_frcst_base_total_tbl1(in_index).forecast_qty - gn_base_total_amount;

        -- 最終レコードで無い場合は、
        -- 管理元拠点単位引取計画数量合計×按分比率（配下拠点・倉庫単位実績数量合計÷管理元拠点単位実績数量合計）
        -- を行い、小数部は切捨てを行なう。
        ELSE
          xxcop_wk_forecast_totaling_rec.total_amount
                               := TRUNC( g_frcst_base_total_tbl1(in_index).forecast_qty
                                       * ( g_frcst_base_total_tbl2(in_index2).ship_result_qty
                                         / g_frcst_base_total_tbl1(in_index).ship_result_qty  )
                                  );

          -- 現在の合計値をグローバルに保持する（最終レコードの余り加算の為）
          gn_base_total_amount := gn_base_total_amount + xxcop_wk_forecast_totaling_rec.total_amount;
        END IF;

      -- 出荷倉庫単位実績数量合計がゼロの場合、按分は行なわない
      ELSE
        xxcop_wk_forecast_totaling_rec.total_amount := 0;
      END IF;
      xxcop_wk_forecast_totaling_rec.whse_code
                              := g_frcst_base_total_tbl2(in_index2).whse_code;
      xxcop_wk_forecast_totaling_rec.planed_item_flg
                              := g_frcst_base_total_tbl2(in_index2).planed_item_flg;
      xxcop_wk_forecast_totaling_rec.no_shipment_results
                              := g_frcst_base_total_tbl2(in_index2).no_shipment_results;
      xxcop_wk_forecast_totaling_rec.sourcing_rules_warn_type
                              := g_frcst_base_total_tbl2(in_index2).sourcing_rules_warn_type;
      xxcop_wk_forecast_totaling_rec.base_code
                              := g_frcst_base_total_tbl2(in_index2).base_code;
    ELSE
      xxcop_wk_forecast_totaling_rec.whse_code                := g_frcst_base_total_tbl1(in_index).forecast_whse_code;
      xxcop_wk_forecast_totaling_rec.total_amount             := g_frcst_base_total_tbl1(in_index).forecast_qty;
      xxcop_wk_forecast_totaling_rec.planed_item_flg          := NULL;
      xxcop_wk_forecast_totaling_rec.no_shipment_results      := cv_no_shipment_results;
      xxcop_wk_forecast_totaling_rec.sourcing_rules_warn_type := cv_srwt_0;
      xxcop_wk_forecast_totaling_rec.base_code                := NULL;
    END IF;

--★v1.1 Del Start
--★    -- 出荷実績なし件数カウント
--★    IF (xxcop_wk_forecast_totaling_rec.no_shipment_results=cv_no_shipment_results) THEN
--★      gn_noresults_cnt := gn_noresults_cnt + 1;
--★    END IF;
--★v1.1 Del End

    -----------------------------------------------
    --         引取計画集計ワークテーブル
    -----------------------------------------------
    INSERT
    INTO   xxcop_wk_forecast_totaling(
        schedule_type                                                     -- 計画区分
      , whse_code                                                         -- 出荷倉庫
      , prod_class                                                        -- 商品区分
      , item_code                                                         -- 品目コード
      , count_period_from                                                 -- 集計期間From
      , count_period_to                                                   -- 集計期間To
      , total_amount                                                      -- 引取数量合計
      , planed_item_flg                                                   -- 計画商品フラグ
      , no_shipment_results                                               -- 出荷実績なし
      , sourcing_rules_warn_type                                          -- 物流構成表データ警告区分
      , base_code                                                         -- 拠点
      , forecast_date                                                     -- フォーキャスト日付
      , created_by                                                        -- 作成者
      , creation_date                                                     -- 作成日
      , last_updated_by                                                   -- 最終更新者
      , last_update_date                                                  -- 最終更新日
      , last_update_login                                                 -- 最終更新ログイン
      , request_id                                                        -- 要求ID
      , program_application_id                                            -- プログラムアプリケーションID
      , program_id                                                        -- プログラムID
      , program_update_date                                               -- プログラム更新日
      )
    VALUES(
        g_frcst_base_total_tbl1(in_index).schedule_type                   -- 計画区分：出荷予測
      , xxcop_wk_forecast_totaling_rec.whse_code                          -- 出荷管理先コード
      , g_frcst_base_total_tbl1(in_index).prod_class                      -- 商品区分
      , g_frcst_base_total_tbl1(in_index).item_code                       -- 品目コード
      , g_frcst_base_total_tbl1(in_index).count_period_from               -- 集計開始日
      , g_frcst_base_total_tbl1(in_index).count_period_to                 -- 集計終了日
      , xxcop_wk_forecast_totaling_rec.total_amount                       -- 数量
      , xxcop_wk_forecast_totaling_rec.planed_item_flg                    -- 計画商品フラグ
      , xxcop_wk_forecast_totaling_rec.no_shipment_results                -- 出荷実績なし
      , xxcop_wk_forecast_totaling_rec.sourcing_rules_warn_type           -- 物流構成表データ警告区分
      , xxcop_wk_forecast_totaling_rec.base_code                          -- 拠点
      , NULL                                                              -- フォーキャスト日付
      , cn_created_by                                                     -- 作成者
      , cd_creation_date                                                  -- 作成日
      , cn_last_updated_by                                                -- 最終更新者
      , cd_last_update_date                                               -- 最終更新日
      , cn_last_update_login                                              -- 最終更新ログイン
      , cn_request_id                                                     -- 要求ID
      , cn_program_application_id                                         -- プログラムアプリケーションID
      , cn_program_id                                                     -- プログラムID
      , cd_program_update_date                                            -- プログラム更新日
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --↓ユーザエラーメッセージ追加↓
      ov_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_ins_err_msg
                    ,iv_token_name1  => cv_ins_err_msg_tkn_lbl1
                    ,iv_token_value1 => cv_ins_err_msg_tkn_val1
                    );
      --↑ユーザエラーメッセージ追加↑
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_base_totaling;
--
--
  /**********************************************************************************
   * Procedure Name   : csv_output
   * Description      : 引取計画集計結果CSV出力(A-10)
   ***********************************************************************************/
  PROCEDURE csv_output(
     ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_output'; -- プログラム名
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
    -- エラーメッセージ
--
    -- *** ローカル変数 ***
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_START
    -- 共通関数：ケース換算用
    ln_case_quantity   NUMBER;          -- ケース数量
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_END

    -- 処理結果レポート出力文字列バッファ
    lv_title_buff VARCHAR2(256);
    lv_buff       VARCHAR2(256);
--
    -- *** ローカル・カーソル ***
    CURSOR get_csv_output_cur IS
    SELECT schedule_type       schedule_type                                                         -- 計画区分
      ,    whse_code           whse_code                                                             -- 出荷倉庫
      ,    prod_class          prod_class                                                            -- 商品区分
      ,    item_code           item_code                                                             -- 品目コード
      ,    count_period_from   count_period_from                                                     -- 集計期間From
      ,    count_period_to     count_period_to                                                       -- 集計期間To
      ,    SUM(total_amount)   total_amount                                                          -- 引取数量合計
      ,    REPLACE(planed_item_flg ,cv_planed_item_flg_0 ,cv_planed_item_flg_null ) planed_item_flg  -- 計画商品フラグ
      ,    no_shipment_results no_shipment_results                                                   -- 出荷実績なし
    FROM   xxcop_wk_forecast_totaling
    WHERE  request_id = cn_request_id
    AND    sourcing_rules_warn_type NOT IN (cv_srwt_3,cv_srwt_4)
    AND    NVL(planed_item_flg,' ') <> cv_planed_item_flg_1
--★v1.1 Add Start
    AND    NOT(   no_shipment_results =  cv_no_shipment_results
              AND NVL(total_amount,0) =  0
              )
--★v1.1 Add End
    GROUP
    BY     schedule_type
      ,    whse_code
      ,    prod_class
      ,    item_code
      ,    count_period_from
      ,    count_period_to
      ,    REPLACE(planed_item_flg ,cv_planed_item_flg_0 ,cv_planed_item_flg_null )
      ,    no_shipment_results
    ORDER
    BY     whse_code
      ,    item_code
      ,    count_period_from
      ,    no_shipment_results DESC
      ,    planed_item_flg DESC
    ;
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
    -------------------------------------------------------------
    --                      CSV出力
    -------------------------------------------------------------
    -- タイトル行設定
    lv_title_buff :=       cv_csv_header1  
        || cv_csv_cont ||  cv_csv_header2  
        || cv_csv_cont ||  cv_csv_header3  
        || cv_csv_cont ||  cv_csv_header4  
        || cv_csv_cont ||  cv_csv_header5  
        || cv_csv_cont ||  cv_csv_header6  
        || cv_csv_cont ||  cv_csv_header7  
        || cv_csv_cont ||  cv_csv_header8  
        || cv_csv_cont ||  cv_csv_header9  
        ;

    <<csv_output_loop>>
    FOR get_csv_output_rec IN get_csv_output_cur LOOP

      -- タイトル行出力
      IF (lv_title_buff IS NOT NULL) THEN

        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_title_buff
        );
        
        lv_title_buff := NULL;
      END IF;

--★v1.1 Add Start
      -- 出荷実績なし件数カウント
      IF (get_csv_output_rec.no_shipment_results=cv_no_shipment_results) THEN
        gn_noresults_cnt := gn_noresults_cnt + 1;
      END IF;
--★v1.1 Add End

--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_START
      --[共通関数]ケース数換算関数の呼び出し（ケース数計算）
      xxcop_common_pkg.get_case_quantity(
        iv_item_no               => get_csv_output_rec.item_code     -- 品目コード
       ,in_individual_quantity   => get_csv_output_rec.total_amount  -- バラ数量
       ,in_trunc_digits          => 0                                -- 切捨て桁数
       ,on_case_quantity         => ln_case_quantity        -- ケース数量
       ,ov_retcode               => lv_retcode              -- リターンコード
       ,ov_errbuf                => lv_errbuf               -- エラー・メッセージ
       ,ov_errmsg                => lv_errmsg               -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE internal_process_expt;
      END IF;
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_END

      -- データ行
      lv_buff :=           get_csv_output_rec.schedule_type
        || cv_csv_cont ||  get_csv_output_rec.whse_code
        || cv_csv_cont ||  get_csv_output_rec.prod_class
        || cv_csv_cont ||  get_csv_output_rec.item_code
        || cv_csv_cont ||  TO_CHAR(get_csv_output_rec.count_period_from,cv_date_format6)
        || cv_csv_cont ||  TO_CHAR(get_csv_output_rec.count_period_to  ,cv_date_format6)
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_MOD_START
--        || cv_csv_cont ||  TO_CHAR(get_csv_output_rec.total_amount)
        || cv_csv_cont ||  TO_CHAR(ln_case_quantity)
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_MOD_END
        || cv_csv_cont ||  get_csv_output_rec.planed_item_flg
        || cv_csv_cont ||  get_csv_output_rec.no_shipment_results
        ;
      -- データ行出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_buff
      );

      -- 正常件数加算
      gn_normal_cnt := gn_normal_cnt + 1;

    END LOOP csv_output_loop;
--
  EXCEPTION
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_START
    WHEN internal_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NVL(lv_errbuf,lv_errmsg);
      ov_retcode := cv_status_error;

      -- 正常件数加算
      gn_normal_cnt := 0;
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_END
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END csv_output;
--
  /**********************************************************************************
   * Procedure Name   : output_warn_msg
   * Description      : 警告データメッセージ出力
   ***********************************************************************************/
  PROCEDURE output_warn_msg(
     ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_warn_msg'; -- プログラム名
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
    -- ログ出力文字列バッファ
    lv_buff VARCHAR2(1024);
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR get_warn_data_cur IS
    SELECT item_code                                  item_code                 -- 品目コード
      ,    base_code                                  base_code                 -- 拠点
--★v1.1 Del       ,    TO_CHAR(forecast_date,cv_date_format5)     forecast_date             -- フォーキャスト日付
--★v1.1 Del       ,    TO_CHAR(count_period_from,cv_date_format5) count_period_from         -- 集計期間From
--★v1.1 Del       ,    TO_CHAR(count_period_to,cv_date_format5)   count_period_to           -- 集計期間To
      ,    whse_code                                  whse_code                 -- 出荷倉庫
      ,    sourcing_rules_warn_type                   sourcing_rules_warn_type  -- 物流構成表データ警告区分
    FROM   xxcop_wk_forecast_totaling                                           -- 引取計画集計ワークテーブル
    WHERE  request_id = cn_request_id
    AND    sourcing_rules_warn_type not in (cv_srwt_0,cv_srwt_4)
    GROUP
    BY     item_code                                    -- 品目コード
      ,    base_code                                    -- 拠点
--★v1.1 Del      ,    TO_CHAR(forecast_date,cv_date_format5)       -- フォーキャスト日付
--★v1.1 Del      ,    TO_CHAR(count_period_from,cv_date_format5)   -- 集計期間From
--★v1.1 Del      ,    TO_CHAR(count_period_to,cv_date_format5)     -- 集計期間To
      ,    whse_code                                    -- 出荷倉庫
      ,    sourcing_rules_warn_type                     -- 物流構成表データ警告区分
    ORDER
    BY     sourcing_rules_warn_type
      ,    item_code
      ,    base_code
--★v1.1 Upd End      ,    forecast_date
--★v1.1 Upd End      ,    count_period_from
      ,    whse_code
    ;
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
    -------------------------------------------------------------
    --                  警告メッセージ出力
    -------------------------------------------------------------
    <<warn_output_loop>>
    FOR get_warn_data_rec IN get_warn_data_cur LOOP

      -- 内部警告件数加算
      gn_internal_warn_cnt := gn_internal_warn_cnt + 1;

      -- 分割対象外：物流構成表未存在
      -- 分割対象：物流構成表無
--★v1.1 Upd Start
--★      IF (get_warn_data_rec.sourcing_rules_warn_type IN (cv_srwt_1,cv_srwt_2)) THEN
      IF (get_warn_data_rec.sourcing_rules_warn_type IN (cv_srwt_1,cv_srwt_2))
      AND(get_warn_data_rec.whse_code<>SUBSTRB(cv_drink_whse_code,2,4))
      THEN
--★v1.1 Upd End
        -- 物流構成表アドオンに登録されていません。
        lv_buff :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_norules1_err_msg
                      ,iv_token_name1  => cv_norules1_err_msg_tkn_lbl1
                      ,iv_token_value1 => get_warn_data_rec.item_code           -- 品目コード
                      ,iv_token_name2  => cv_norules1_err_msg_tkn_lbl2
                      ,iv_token_value2 => get_warn_data_rec.base_code           -- 拠点
--★v1.1 Upd Start
                      ,iv_token_name3  => cv_norules1_err_msg_tkn_lbl3
                      ,iv_token_value3 => get_warn_data_rec.whse_code           -- 出荷倉庫
--★                      ,iv_token_name3  => cv_norules1_err_msg_tkn_lbl3
--★                      ,iv_token_value3 => get_warn_data_rec.forecast_date       -- フォーキャスト日付
--★                      ,iv_token_name4  => cv_norules1_err_msg_tkn_lbl4
--★                      ,iv_token_value4 => get_warn_data_rec.whse_code           -- 出荷倉庫
--★v1.1 Upd End
                      );
      END IF;

      -- 分割対象：物流構成表有(合計実績数無）
--★v1.1 Upd Start
--★      IF (get_warn_data_rec.sourcing_rules_warn_type = cv_srwt_3) THEN
      IF (get_warn_data_rec.sourcing_rules_warn_type = cv_srwt_3)
      OR (  (get_warn_data_rec.sourcing_rules_warn_type IN (cv_srwt_1,cv_srwt_2))
         AND(get_warn_data_rec.whse_code=SUBSTRB(cv_drink_whse_code,2,4))
         )
      THEN
--★v1.1 Upd End
        -- 集計期間内で物流構成表アドオンに登録されていないデータがあります。
        lv_buff :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_norules2_err_msg
                      ,iv_token_name1  => cv_norules2_err_msg_tkn_lbl1
                      ,iv_token_value1 => get_warn_data_rec.item_code           -- 品目コード
                      ,iv_token_name2  => cv_norules2_err_msg_tkn_lbl2
                      ,iv_token_value2 => get_warn_data_rec.base_code           -- 拠点
--★v1.1 Del Start
--★                      ,iv_token_name3  => cv_norules2_err_msg_tkn_lbl3
--★                      ,iv_token_value3 => get_warn_data_rec.count_period_from   -- 集計期間From
--★                      ,iv_token_name4  => cv_norules2_err_msg_tkn_lbl4
--★                      ,iv_token_value4 => get_warn_data_rec.count_period_to     -- 集計期間To
--★v1.1 Del End
                      );
      END IF;

      -- データ行出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_buff
      );

    END LOOP warn_output_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_warn_msg;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_table
   * Description      : 引取計画集計ワークテーブル削除
   ***********************************************************************************/
  PROCEDURE delete_work_table(
     ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_table'; -- プログラム名
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
    -------------------------------------------------------------
    --            引取計画集計ワークテーブル削除
    -------------------------------------------------------------
    DELETE
    FROM   xxcop_wk_forecast_totaling
    WHERE  request_id = cn_request_id
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_work_table;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_base_code                  IN  VARCHAR2         -- 1.拠点
    ,iv_prod_class_code            IN  VARCHAR2         -- 2.商品区分
    ,iv_results_collect_period_st  IN  VARCHAR2         -- 3.実績収集期間（自）
    ,iv_results_collect_period_ed  IN  VARCHAR2         -- 4.実績収集期間（至）
    ,iv_forecast_collect_period_st IN  VARCHAR2         -- 5.計画収集期間（自）
    ,iv_forecast_collect_period_ed IN  VARCHAR2         -- 6.計画収集期間（至）
    ,ov_errbuf                     OUT VARCHAR2         --   エラー・メッセージ           --# 固定 #
    ,ov_retcode                    OUT VARCHAR2         --   リターン・コード             --# 固定 #
    ,ov_errmsg                     OUT VARCHAR2)        --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名

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
    lv_year_month      VARCHAR2(6);
    ln_day             NUMBER(2);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;

    -- パラメータをログ出力
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');    -- 改行
    FND_FILE.PUT_LINE(FND_FILE.LOG,cv_pm_base_code_tl        || cv_pm_part  || iv_base_code                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG,cv_pm_prod_class_code_tl  || cv_pm_part  || iv_prod_class_code           );
    FND_FILE.PUT_LINE(FND_FILE.LOG,cv_pm_results_clt_prd_tl  || cv_pm_part  || iv_results_collect_period_st
                                                             || cv_pm_part2 || iv_results_collect_period_ed );
    FND_FILE.PUT_LINE(FND_FILE.LOG,cv_pm_forecast_clt_prd_tl || cv_pm_part  || iv_forecast_collect_period_st
                                                             || cv_pm_part2 || iv_forecast_collect_period_ed);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');    -- 改行

    -- グローバル変数に入力パラメータを設定
    gv_base_code                   := RTRIM(iv_base_code);
    gv_prod_class_code             := RTRIM(iv_prod_class_code);
    gd_results_collect_period_st   := TO_DATE(iv_results_collect_period_st ||' '||cv_date_start_time ,cv_date_format1);
    gd_results_collect_period_ed   := TO_DATE(iv_results_collect_period_ed ||' '||cv_date_end_time   ,cv_date_format1);
    gd_forecast_collect_period_st  := TO_DATE(iv_forecast_collect_period_st||' '||cv_date_start_time ,cv_date_format1);
    gd_forecast_collect_period_ed  := TO_DATE(iv_forecast_collect_period_ed||' '||cv_date_end_time   ,cv_date_format1);

    -- 内部処理用グローバル変数初期化
    gd_sysdate           := TRUNC(SYSDATE);
    gn_internal_warn_cnt := 0;
    gn_noresults_cnt     := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --        A-1 初期処理
    -- ===============================
    init(
      lv_errbuf                            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                           -- リターン・コード             --# 固定 #
     ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;

    -- ===============================
    --    A-2 引取計画集計期間設定
    -- ===============================
    <<totaling_period_loop>>
    LOOP

      --------------------------------
      --       集計開始日設定
      --------------------------------
      IF (gd_totaling_start_date IS NULL) THEN
         gd_totaling_start_date := gd_forecast_collect_period_st;
      ELSE
         gd_totaling_start_date := trunc(gd_totaling_end_date + 1);
      END IF;

      --------------------------------
      --       集計終了日設定
      --------------------------------
      lv_year_month := TO_CHAR(gd_totaling_start_date,cv_date_format3);
      ln_day        := TO_NUMBER(TO_CHAR(gd_totaling_start_date,cv_date_format4));

      IF (ln_day <= 7) THEN
        gd_totaling_end_date   := TO_DATE(lv_year_month||cv_week_day_1||cv_date_end_time,cv_date_format2);
      ELSIF (ln_day <= 14) THEN
        gd_totaling_end_date   := TO_DATE(lv_year_month||cv_week_day_2||cv_date_end_time,cv_date_format2);
      ELSIF (ln_day <= 21) THEN
        gd_totaling_end_date   := TO_DATE(lv_year_month||cv_week_day_3||cv_date_end_time,cv_date_format2);
      ELSE
        gd_totaling_end_date   := ADD_MONTHS(TO_DATE(lv_year_month,cv_date_format3),1) - (1/24/60/60);
      END IF;

      -- 集計終了日が計画収集期間（至）より大きくなった場合、
      -- 集計終了日を計画収集期間（至）に設定する。
      IF (gd_totaling_end_date>gd_forecast_collect_period_ed) THEN
        gd_totaling_end_date := gd_forecast_collect_period_ed;
      END IF;

      -- ワーク初期化
      g_frcst_base_total_tbl1 := g_frcst_base_total_tbl1_init;

      -- =========================================
      --   A-3.対象データ抽出（出荷倉庫集計）
      --   A-4.ワークテーブル登録
      --    ※処理簡略化の為、INSERT～SELECTに変更
      -- =========================================
      insert_whse_totaling(
        lv_errbuf                            -- エラー・メッセージ           --# 固定 #
       ,lv_retcode                           -- リターン・コード             --# 固定 #
       ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE internal_process_expt;
      END IF;

      -- ===================================================
      -- 分割対象拠点 管理元拠点計画数量集計データ抽出（A-5）
      -- ===================================================
      get_management_forcast_total(
        lv_errbuf                            -- エラー・メッセージ           --# 固定 #
       ,lv_retcode                           -- リターン・コード             --# 固定 #
       ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE internal_process_expt;
      END IF;

      <<management_base_loop>>
      FOR ix IN 1..g_frcst_base_total_tbl1.COUNT LOOP

        -- ===================================================
        -- 分割対象拠点 管理元拠点実績数量集計データ抽出（A-6）
        -- ===================================================
        get_management_result_total(
          ix                                   -- 管理元拠点集計データ抽出ループIndex
         ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
         ,lv_retcode                           -- リターン・コード             --# 固定 #
         ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;

        -- ワーク初期化
        gn_base_total_amount    := 0;
        g_frcst_base_total_tbl2 := g_frcst_base_total_tbl2_init;

        -- ===================================================
        --  配下拠点・出荷倉庫別出荷実績抽出(A-7)
        -- ===================================================
        get_whse_totaling(
          ix                                   -- 管理元拠点集計データ抽出ループIndex
         ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
         ,lv_retcode                           -- リターン・コード             --# 固定 #
         ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;

        <<base_loop>>
        FOR ix2 IN 1..g_frcst_base_total_tbl2.COUNT LOOP
          -- ===================================================
          -- 引取計画集計(按分)ワークテーブル登録(A-9)
          -- ※処理簡略化の為、引取計画数按分(A-8)を統合
          -- ===================================================
          insert_base_totaling(
            ix                                   -- 管理元拠点集計データ抽出ループIndex
           ,ix2                                  -- 配下拠点・出荷倉庫別出荷実績抽出ループIndex
           ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
           ,lv_retcode                           -- リターン・コード             --# 固定 #
           ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE internal_process_expt;
          END IF;
        END LOOP base_loop;

        IF (g_frcst_base_total_tbl1(ix).ship_result_qty = 0) THEN
          -- ================================================================
          -- 管理元拠点単位での実績数量がゼロで全て実績なしの場合、
          -- 按分出来なかった計画数量をCSVに出力する為、
          -- フォーキャスト倉庫で引取計画集計ワークテーブルの登録を行なう。
          -- ================================================================
          insert_base_totaling(
            ix                                   -- 管理元拠点集計データ抽出ループIndex
           ,NULL
           ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
           ,lv_retcode                           -- リターン・コード             --# 固定 #
           ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE internal_process_expt;
          END IF;
        END IF;
      END LOOP management_base_loop;

      -- 計画収集期間まで完了したらループを抜ける。
      IF (gd_totaling_end_date>=gd_forecast_collect_period_ed) THEN
        EXIT totaling_period_loop;
      END IF;

    END LOOP totaling_period_loop;

    -- ===================================================
    --  引取計画集計結果CSV出力(A-10)
    -- ===================================================
    csv_output(
      lv_errbuf                            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                           -- リターン・コード             --# 固定 #
     ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;

    -- ===================================================
    --  CSV警告データメッセージ出力
    -- ===================================================
    output_warn_msg(
      lv_errbuf                            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                           -- リターン・コード             --# 固定 #
     ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;

    -- ===================================================
    --  引取計画集計ワークテーブル削除
    -- ===================================================
    delete_work_table(
      lv_errbuf                            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                           -- リターン・コード             --# 固定 #
     ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;

    -- 出荷実績なし出力ノート
    IF (gn_noresults_cnt>0) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_noresult_note_msg
                    )
        );
    END IF;

    -- 対象件数算出
    gn_target_cnt := gn_normal_cnt;

    -- 警告メッセージを出力した場合、警告終了で戻す
    IF (  (gn_internal_warn_cnt>0) OR (gn_noresults_cnt>0) ) THEN
      ov_retcode := cv_status_warn;
    END IF;

  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF (lv_errbuf IS NULL) THEN
        ov_errbuf := NULL;
      ELSE
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 処理部共通例外ハンドラ ***
--■    WHEN global_process_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラーカウントアップ
      gn_error_cnt := gn_error_cnt + 1;
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
     errbuf                        OUT VARCHAR2         --   エラーメッセージ #固定#
    ,retcode                       OUT VARCHAR2         --   エラーコード     #固定#
    ,iv_base_code                  IN  VARCHAR2         -- 1.拠点
    ,iv_prod_class_code            IN  VARCHAR2         -- 2.商品区分
    ,iv_results_collect_period_st  IN  VARCHAR2         -- 3.実績収集期間（自）
    ,iv_results_collect_period_ed  IN  VARCHAR2         -- 4.実績収集期間（至）
    ,iv_forecast_collect_period_st IN  VARCHAR2         -- 5.計画収集期間（自）
    ,iv_forecast_collect_period_ed IN  VARCHAR2         -- 6.計画収集期間（至）
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_base_code                      -- 1.拠点
      ,iv_prod_class_code                -- 2.商品区分
      ,iv_results_collect_period_st      -- 3.実績収集期間（自）
      ,iv_results_collect_period_ed      -- 4.実績収集期間（至）
      ,iv_forecast_collect_period_st     -- 5.計画収集期間（自）
      ,iv_forecast_collect_period_ed     -- 6.計画収集期間（至）
      ,lv_errbuf                         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                        -- リターン・コード             --# 固定 #
      ,lv_errmsg                         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN

      -- ユーザエラーメッセージをログ出力
      IF (lv_errmsg IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   lv_errmsg
        );
      END IF;

      -- システムエラーメッセージをログ出力
      IF (lv_errbuf IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_others_err_msg
                    ,iv_token_name1  => cv_others_err_msg_tkn_lbl1
                    ,iv_token_value1 => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                    )
        );
      END IF;
    END IF;

    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
--    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOP004A03C;
/
