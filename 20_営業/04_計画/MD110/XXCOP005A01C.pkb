create or replace PACKAGE BODY      XXCOP005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP005A01C(body)
 * Description      : 工場出荷計画
 * MD.050           : 工場出荷計画 MD050_COP_005_A01
 * Version          : 2.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  delete_table           テーブルデータ削除(A-11)
 *  init                   初期処理(A-1)
 *  get_plant_mark         工場固有記号取得処理（A-21）
 *  insert_wk_tbl          ワークテーブルデータ登録(A-22)
 *  get_schedule_date      基準生産計画取得（A-2）
 *  get_shipping_pace      出荷ペース取得処理(A-52)
 *  get_plant_shipping     工場出荷計画制御マスタ取得（A-3）
 *  get_base_yokomst       基本横持ち制御マスタ取得（A-4）
 *  get_pace_sum           下位倉庫出荷ペース取得（A-51）
 *  get_under_lvl_pace     出荷ペース取得処理（A-5）
 *  get_stock_qty          在庫数取得処理（A-6）
 *  get_move_qty           移動数取得処理（A-7）
 *  insert_wk_output       工場出荷計画出力ワークテーブル作成（A-8）
 *  csv_output             工場出荷計画CSV出力(A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.0   SCS Uda          新規作成
 *  2009/02/25    1.1   SCS Uda          結合テスト仕様変更（結合障害No.014）
 *  2009/04/07    1.2   SCS Uda          システムテスト障害対応（T1_0277、T1_0278、T1_0280、T1_0281、T1_0368）
 *  2009/04/14    1.3   SCS Uda          システムテスト障害対応（T1_0542）
 *  2009/04/21    1.4   SCS Uda          システムテスト障害対応（T1_0722）
 *  2009/04/28    1.5   SCS Uda          システムテスト障害対応（T1_0845、T1_0847）
 *  2009/05/20    1.6   SCS Uda          システムテスト障害対応（T1_1096）
 *  2009/06/04    1.7   SCS Fukada       システムテスト障害対応（T1_1328）プログラムの最後に「/」を追加
 *  2009/06/16    1.8   SCS Kikuchi      システムテスト障害対応（T1_1463、T1_1464）
 *  2009/09/01    2.0   T.Tsukino        新規作成
 *  2009/10/29    2.1   Y.Goto           I_E_479_007
 *  2009/11/04    2.2   Y.Goto           I_E_479_010
 *  2009/11/20    2.3   Y.Goto           I_E_479_018
 *  2009/11/19    2.4   T.Tsukino        deleteエラーの修正
 *  2009/12/03    2.5   Y.Goto           I_E_479_021(アプリPT対応)
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  --
  internal_api_expt         EXCEPTION;     -- コンカレント内部共通例外
  param_invalid_expt        EXCEPTION;     -- 入力パラメータチェックエラー
  internal_process_expt     EXCEPTION;     -- 内部PROCEDURE/FUNCTIONエラーハンドリング用
  date_invalid_expt         EXCEPTION;     -- 日付チェックエラー
  past_date_invalid_expt    EXCEPTION;     -- 過去日チェックエラー
  expt_next_record          EXCEPTION;     -- レコードスキップ用
  resource_busy_expt        EXCEPTION;     -- デッドロックエラー
  reverse_invalid_expt      EXCEPTION;     -- 日付逆転エラー
  no_data_skip_expt         EXCEPTION;
  nested_loop_expt          EXCEPTION;     -- 階層ループエラー
  no_action_expt            EXCEPTION;
  
  PRAGMA EXCEPTION_INIT(nested_loop_expt, -01436);
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);

  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOP005A01C';
  --プログラム実行日時
  cd_sys_date                   CONSTANT DATE        := TRUNC(SYSDATE);                    --プログラム実行日時
--  -- 入力パラメータログ出力用
  cv_plan_from                  CONSTANT VARCHAR2(100) :=  '計画立案期間（FROM）';
  cv_plan_to                    CONSTANT VARCHAR2(100) :=  '計画立案期間（TO）';
  cv_pace_type                  CONSTANT VARCHAR2(100) :=  '対象出荷区分';
  cv_pace_from                  CONSTANT VARCHAR2(100) :=  '出荷ペース計画期間（FROM）';
  cv_pace_to                    CONSTANT VARCHAR2(100) :=  '出荷ペース計画期間（TO）';
  cv_forcast_from               CONSTANT VARCHAR2(100) :=  '出荷予測期間（FROM)';
  cv_forcast_to                 CONSTANT VARCHAR2(100) :=  '出荷予測期間（TO）';
  cv_schedule_date              CONSTANT VARCHAR2(100) :=  '出荷引当済日';
  cv_pm_part                    CONSTANT VARCHAR2(6)   := ' : ';
--
--
  --メッセージ共通
  cv_msg_appl_cont              CONSTANT VARCHAR2(100) := 'XXCOP';                 -- アプリケーション短縮名
--  --メッセージ名
  cv_msg_00065     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00065';      -- 業務日付取得エラーメッセージ
  cv_msg_00055     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00055';      -- パラメータエラーメッセージ
  cv_msg_00011     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00011';      -- DATE型チェックエラーメッセージ
  cv_msg_00025     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';      -- 値逆転エラーメッセージ
  cv_msg_00047     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';      -- 未来日メッセージ
  cv_msg_00053     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00053';      -- 配送リードタイム取得エラー
  cv_msg_00056     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00056';      -- 設定期間中稼働日チェックエラーメッセージ
  cv_msg_00049     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00049';      -- 品目情報取得エラー
  cv_msg_00050     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00050';      -- 倉庫情報取得エラー
  cv_msg_00042     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';      -- 削除処理エラー
  cv_msg_10025     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10025';      -- 工場固有記号取得エラー
  cv_msg_00060     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00060';      -- 経路情報ループエラーメッセージ
  cv_msg_00003     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';      -- 対象データなし
  cv_msg_00027     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';      -- 登録処理エラーメッセージ
  cv_msg_00028     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00028';      -- 更新処理エラーメッセージ
  cv_msg_00062     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00062';      -- 経路エラーメッセージ
  cv_msg_00063     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00063';      -- 按分ゼロ計算不正警告
  cv_msg_00066     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00066';      -- 着日取得エラー
  cv_msg_10009     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10009';      -- 過去日付入力メッセージ
  cv_msg_10048     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10048';      -- 工場出荷計画パラメータ出力メッセージ
  cv_msg_10049     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10049';      -- 工場出荷計画CSVファイル出力ヘッダー
  -- メッセージ関連
  cv_msg_application            CONSTANT VARCHAR2(100) := 'XXCOP';
  cv_others_err_msg             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';
  cv_others_err_msg_tkn_lbl1    CONSTANT VARCHAR2(100) := 'ERRMSG';
  --メッセージトークン
  cv_msg_00011_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00025_token_1      CONSTANT VARCHAR2(100) := 'PERIOD_FROM';
  cv_msg_00025_token_2      CONSTANT VARCHAR2(100) := 'PERIOD_TO';
  cv_msg_00047_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_00053_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE_FROM';
  cv_msg_00053_token_2      CONSTANT VARCHAR2(100) := 'WHSE_CODE_TO';
  cv_msg_00056_token_1      CONSTANT VARCHAR2(100) := 'FROM_DATE';
  cv_msg_00056_token_2      CONSTANT VARCHAR2(100) := 'TO_DATE';
  cv_msg_00049_token_1      CONSTANT VARCHAR2(100) := 'ITEMID';
  cv_msg_00050_token_1      CONSTANT VARCHAR2(100) := 'ORGID';
  cv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_10025_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10025_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_00060_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00060_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00062_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00062_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00027_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00028_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00063_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00066_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00066_token_2      CONSTANT VARCHAR2(100) := 'CALENDAR_CODE';
  cv_msg_00066_token_3      CONSTANT VARCHAR2(100) := 'SHIP_DATE';
  cv_msg_10009_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10048_token_1      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_FROM';
  cv_msg_10048_token_2      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_TO';
  cv_msg_10048_token_3      CONSTANT VARCHAR2(100) := 'PLAN_TYPE';
  cv_msg_10048_token_4      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_FROM';
  cv_msg_10048_token_5      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_TO';
  cv_msg_10048_token_6      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_FROM';
  cv_msg_10048_token_7      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_TO';
  cv_msg_10048_token_8      CONSTANT VARCHAR2(100) := 'ALLOCATED_DATE';
--
  --メッセージトークン値
  cv_msg_wk_tbl             CONSTANT VARCHAR2(100) := '物流計画ワークテーブル';
  cv_msg_wk_tbl_output      CONSTANT VARCHAR2(100) := '工場出荷計画出力ワークテーブル';
--
  cv_date_format            CONSTANT VARCHAR2(8)   := 'YYYYMMDD';               -- 年月日
  cv_date_format_slash      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';             -- 年/月/日
--  cv_datetime_format        CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';  -- 年月日時分秒(24時間表記)
--  cv_month_format           CONSTANT VARCHAR2(8)   := 'MM';                     -- 精度指定子(月)
--  --割当セット区分
  cv_base_plan              CONSTANT VARCHAR2(1)   := '1';                      -- 基本横持計画
  cv_factory_ship_plan      CONSTANT VARCHAR2(1)   := '3';                      -- 工場出荷計画
--  --プロファイル取得
  cv_master_org_id          CONSTANT VARCHAR2(20)  := 'XXCMN_MASTER_ORG_ID';           -- プロファイル取得用 マスタ組織
--  --クイックコードタイプ
  cv_assign_type_priority   CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';   -- 割当先タイプ優先度
  cv_assign_name            CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';        -- 割当セット名
  cv_flv_language           CONSTANT VARCHAR2(100) := USERENV('LANG');                 -- 言語
  cv_flv_enabled_flg_y      CONSTANT VARCHAR2(100) := 'Y';
--  --移動数マイナスフラグ
  cn_cnt_from               CONSTANT NUMBER        := 1;                        --親件数
--
--  --入力パラメータ
  cv_buy_type               CONSTANT VARCHAR2(1)   := '3';                      -- 基準計画分類（購入計画）
  cv_plan_type_pace         CONSTANT VARCHAR2(100) := '1';                      -- 出荷ペース
  cv_plan_type_fgorcate     CONSTANT VARCHAR2(100) := '2';                      -- 出荷予測
--
  cv_own_flg_on             CONSTANT VARCHAR2(1)   := '1';                      -- 自工場対象フラグYes
  cv_plan_typep             CONSTANT VARCHAR2(1)   := '1';                      -- 計画区分（出荷ペース）
  cv_plan_typef             CONSTANT VARCHAR2(1)   := '2';                      -- 計画区分（出荷予測）
  cn_data_lvl_plant         CONSTANT NUMBER        := 0;                        -- 組織データレベル(工場レベル)
  cn_data_lvl_output        CONSTANT NUMBER        := 1;                        -- 組織データレベル(工場出荷レベル)
  cn_data_lvl_yokomt        CONSTANT NUMBER        := 2;                        -- 組織データレベル(基本横持レベル)
  cn_delivery_lead_time     CONSTANT NUMBER        := 0;
  cn_frq_on                 CONSTANT NUMBER        := 1;                        -- 代表倉庫（存在）
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
  cn_schedule_level         CONSTANT NUMBER        := 2;                        -- スケジュールレベル
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
  --移動数マイナスフラグ
  cv_move_minus_flg_on      CONSTANT VARCHAR2(2)   := '1';                      -- 移動数マイナス
  -- CSV出力用
  cv_csv_part                   CONSTANT VARCHAR2(1)   := '"';
  cv_csv_cont                   CONSTANT VARCHAR2(1)   := ',';
--20091203_Ver2.5_I_E_479_021_SCS.Goto_MOD_START
--  cv_csv_point                  CONSTANT VARCHAR2(1)   := '''';
  cv_csv_point                  CONSTANT VARCHAR2(1)   := '';
--20091203_Ver2.5_I_E_479_021_SCS.Goto_MOD_END
  -- 代表倉庫コード
  cv_org_code                   CONSTANT VARCHAR2(10)  := 'ZZZZ';
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================

  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ格納用変数
  gd_plan_from                  DATE;                     -- 計画立案期間（FROM）
  gd_plan_to                    DATE;                     -- 計画立案期間（TO）
  gv_pace_type                  VARCHAR2(1);              -- 対象出荷区分
  gd_pace_from                  DATE;                     -- 出荷ペース期間（FROM）
  gd_pace_to                    DATE;                     -- 出荷ペース期間（TO)
  gd_forcast_from               DATE;                     -- 出荷予測期間（FROM）
  gd_forcast_to                 DATE;                     -- 出荷予測期間（TO）
  gd_schedule_date              DATE;                     -- 出荷引当済日
  gd_process_date               DATE;                     -- 業務日付
--
--
  gv_debug_mode                  VARCHAR2(2) := '';     -- debug用
--
  /**********************************************************************************
   * Procedure Name   : delete_table
   * Description      : テーブルデータ削除(A-11)
   ***********************************************************************************/
  PROCEDURE delete_table(
    ov_errbuf        OUT VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル・カーソル ***
--20091119_修正_SCS.Tsukino_ADD_START
  CURSOR delete_xwsp_cur
  IS
    SELECT xwsp.rowid
    FROM   xxcop_wk_ship_planning xwsp
    FOR UPDATE NOWAIT;
  CURSOR delete_xwspo_cur
  IS
    SELECT xwspo.rowid
    FROM   xxcop_wk_ship_planning_output xwspo
    FOR UPDATE NOWAIT;
--20091119_修正_SCS.Tsukino_ADD_END
--20091119_修正_SCS.Tsukino_DEL_START
--
--    -- *** ローカル・レコード ***
--    TYPE rowid_ttype IS TABLE OF rowid INDEX BY BINARY_INTEGER;
--    lr_ttype         rowid_ttype;
----
--20091119_修正_SCS.Tsukino_DEL_END
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
--20091119_修正_SCS.Tsukino_ADD_START
  -- 物流計画ワークテーブル削除処理
    BEGIN
      OPEN delete_xwsp_cur;
      CLOSE delete_xwsp_cur;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE resource_busy_expt;
    END;
    BEGIN
      OPEN delete_xwspo_cur;
      CLOSE delete_xwspo_cur;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE resource_busy_expt;
    END;
      DELETE FROM xxcop_wk_ship_planning;
      DELETE FROM xxcop_wk_ship_planning_output;
  EXCEPTION
    -- *** データ削除例外ハンドラ ***
    WHEN resource_busy_expt THEN
      ov_retcode := cv_status_error;
--20091119_修正_SCS.Tsukino_ADD_END
--20091119_修正_SCS.Tsukino_DEL_START
--    -- ===============================
--    -- 物流計画ワークテーブル
--    -- ===============================
--    BEGIN
--      --ロックの取得
--      SELECT xwsp.ROWID
--      BULK COLLECT INTO lr_ttype
--      FROM xxcop_wk_ship_planning xwsp
--      FOR UPDATE NOWAIT;
--      --データ削除
--      DELETE FROM xxcop_wk_ship_planning;
----
--    EXCEPTION
--      WHEN resource_busy_expt THEN
--        NULL;
--    END;
----
--    -- ===============================
--    -- 工場出荷計画出力ワークテーブル
--    -- ===============================
--   BEGIN
--      --ロックの取得
--      SELECT xwspo.ROWID
--      BULK COLLECT INTO lr_ttype
--      FROM xxcop_wk_ship_planning_output xwspo
--      FOR UPDATE NOWAIT;
--      --データ削除
--      DELETE FROM xxcop_wk_ship_planning_output;
--
--    EXCEPTION
--      WHEN resource_busy_expt THEN
--        NULL;
--    END;
--
--  EXCEPTION
--20091119_修正_SCS.Tsukino_DEL_END
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
     iv_plan_from     IN    VARCHAR2    --   1.計画立案期間（FROM）
    ,iv_plan_to       IN    VARCHAR2    --   2.計画立案期間（TO）
    ,iv_pace_type     IN    VARCHAR2    --   3.対象出荷区分
    ,iv_pace_from     IN    VARCHAR2    --   4.出荷ペース計画期間（FROM）
    ,iv_pace_to       IN    VARCHAR2    --   5.出荷ペース計画期間（TO）
    ,iv_forcast_from  IN    VARCHAR2    --   6.出荷予測期間（FROM)
    ,iv_forcast_to    IN    VARCHAR2    --   7.出荷予測期間（TO）
    ,iv_schedule_date IN    VARCHAR2    --   8.出荷引当済日
    ,ov_errbuf        OUT   VARCHAR2    --   エラー・メッセージ           --# 固定 #
    ,ov_retcode       OUT   VARCHAR2    --   リターン・コード             --# 固定 #
    ,ov_errmsg        OUT   VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
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
--    -- *** ローカル変数 ***
    lb_chk_value         BOOLEAN;         -- 日付型フォーマットチェック結果
    lv_invalid_value     VARCHAR2(100);   -- エラーメッセージ値
    lv_plan_from         VARCHAR2(100);
    lv_plan_to           VARCHAR2(100);
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
    --空白行を挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    -- =======================
    -- 入力パラメータの出力
    -- =======================
    --空白行を挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    -- ヘッダ情報の抽出
    lv_errmsg := xxccp_common_pkg.get_msg(          
             iv_application  => cv_msg_appl_cont    
            ,iv_name         => cv_msg_10048        
            ,iv_token_name1  => cv_msg_10048_token_1
            ,iv_token_value1 => iv_plan_from        
            ,iv_token_name2  => cv_msg_10048_token_2
            ,iv_token_value2 => iv_plan_to          
            ,iv_token_name3  => cv_msg_10048_token_3
            ,iv_token_value3 => iv_pace_type        
            ,iv_token_name4  => cv_msg_10048_token_4
            ,iv_token_value4 => iv_pace_from        
            ,iv_token_name5  => cv_msg_10048_token_5
            ,iv_token_value5 => iv_pace_to          
            ,iv_token_name6  => cv_msg_10048_token_6
            ,iv_token_value6 => iv_forcast_from     
            ,iv_token_name7  => cv_msg_10048_token_7
            ,iv_token_value7 => iv_forcast_to       
            ,iv_token_name8  => cv_msg_10048_token_8
            ,iv_token_value8 => iv_schedule_date    
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_others_expt;
    END IF;
--
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => lv_errmsg
                     );
    -- ==================
    -- 業務日付の取得
    -- ==================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => TO_CHAR(gd_process_date,cv_date_format_slash)
    );
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00065
                   );
      RAISE internal_api_expt;
    END IF;
--
    -- =================================================
    -- 出荷ペース・計画期間、出荷予測区分入力チェック
    -- =================================================
    -- 対象出荷区分をグローバル変数へ格納
    gv_pace_type                  := iv_pace_type;              -- 対象出荷区分
    -- 対象出荷区分がNULL値の場合、出荷ペース計画期間、出荷予測計画期間は必須
    IF (gv_pace_type IS NULL) THEN
      IF (iv_pace_from IS NULL) OR (iv_pace_to IS NULL) OR (iv_forcast_from IS NULL) OR (iv_forcast_to IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
    -- 対象出荷区分が出荷ペースで指定されている場合、出荷ペース計画期間は必須
    ELSIF (gv_pace_type = cv_plan_type_pace) THEN
      IF (iv_pace_from IS NULL) OR (iv_pace_to IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
    -- 対象出荷区分が出荷予測で指定されている場合、出荷予測計画期間は必須
    ELSIF (gv_pace_type = cv_plan_type_fgorcate) THEN
      IF (iv_forcast_from IS NULL) OR (iv_forcast_to IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
    END IF;
    -- ==============================
    -- 出荷引当済日の日付型チェック
    -- ==============================
    -- 出荷引当済
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_schedule_date
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_schedule_date;
      RAISE date_invalid_expt;
    END IF;
    -- グローバル変数に入力パラメータを設定(出荷引当済日以外はinitで設定）
    gd_schedule_date              := TO_DATE(iv_schedule_date, cv_date_format_slash);-- 出荷引当済日
    -- ================================
    -- 計画立案期間FROM,TO日付チェック
    -- ================================
    --共通関数:chk_date_formatで日付のチェックを行い、
    --グローバル変数へ格納
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_plan_from
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_plan_from;
      RAISE date_invalid_expt;
    END IF;
    --from-toの逆転チェックと、from-toの未来日チェックを行います
    --
    -- 計画立案期間from
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_plan_from
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_plan_from;
      RAISE date_invalid_expt;
    END IF;
    gd_plan_from := TO_DATE( iv_plan_from, cv_date_format_slash );
    -- 計画立案期間to
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_plan_to
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_plan_to;
      RAISE date_invalid_expt;
    END IF;
    gd_plan_to   := TO_DATE( iv_plan_to, cv_date_format_slash );
    --計画立案期間(FROM)-計画立案期間(TO)逆転チェック
    IF ( gd_plan_from > gd_plan_to ) THEN
      lv_plan_from := cv_plan_from;
      lv_plan_to   := cv_plan_to;
      RAISE reverse_invalid_expt;
    END IF;
    --計画立案期間(FROM)過去日チェック
    IF ( gd_plan_from < gd_process_date ) THEN
      lv_invalid_value := cv_plan_from;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_10009
                     ,iv_token_name1  => cv_msg_10009_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    --計画立案期間(TO)過去日チェック
    IF ( gd_plan_to < gd_process_date ) THEN
      lv_invalid_value := cv_plan_to;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_10009
                     ,iv_token_name1  => cv_msg_10009_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    -- =======================================
    -- 出荷ペース計画期間FROM,TO日付チェック
    -- =======================================
    -- 出荷ペース計画期間from
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_pace_from
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_pace_from;
      RAISE date_invalid_expt;
    END IF;
    gd_pace_from := TO_DATE( iv_pace_from, cv_date_format_slash );
    -- 出荷ペース計画期間to
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_pace_to
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_pace_to;
      RAISE date_invalid_expt;
    END IF;
    gd_pace_to   := TO_DATE( iv_pace_to, cv_date_format_slash );
    --出荷ペース計画期間(FROM)-出荷ペース計画期間(TO)逆転チェック
    IF ( gd_pace_from > gd_pace_to ) THEN
      lv_plan_from := cv_pace_from;
      lv_plan_to   := cv_pace_to;
      RAISE reverse_invalid_expt;
    END IF;
    --出荷ペース計画期間(FROM)過去日チェック
    IF ( gd_pace_from > gd_process_date ) THEN
      lv_invalid_value := cv_pace_from;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00047
                     ,iv_token_name1  => cv_msg_00047_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    --出荷ペース計画期間(TO)過去日チェック
    IF ( gd_pace_to > gd_process_date ) THEN
      lv_invalid_value := cv_pace_to;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00047
                     ,iv_token_name1  => cv_msg_00047_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    -- ===========================================
    -- 出荷予測期間FROM,TO日付チェック
    -- ===========================================
    -- 出荷予測期間from
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_forcast_from
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_forcast_from;
      RAISE date_invalid_expt;
    END IF;
    gd_forcast_from := TO_DATE( iv_forcast_from, cv_date_format_slash );
    -- 出荷予測期間to
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_forcast_to
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_forcast_to;
      RAISE date_invalid_expt;
    END IF;
    gd_forcast_to   := TO_DATE( iv_forcast_to, cv_date_format_slash );
    --出荷予測期間(FROM)-出荷予測期間(TO)逆転チェック
    IF ( gd_forcast_from > gd_forcast_to ) THEN
      lv_plan_from := cv_forcast_from;
      lv_plan_to   := cv_forcast_to;
      RAISE reverse_invalid_expt;
    END IF;
    --出荷予測期間(FROM)過去日チェック
    IF ( gd_forcast_from < gd_process_date ) THEN
      lv_invalid_value := cv_forcast_from;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_10009
                     ,iv_token_name1  => cv_msg_10009_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    --出荷予測期間(TO)過去日チェック
    IF ( gd_forcast_to < gd_process_date ) THEN
      lv_invalid_value := cv_forcast_to;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_10009
                     ,iv_token_name1  => cv_msg_10009_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    -- =====================================
    -- 関連テーブル削除処理
    -- =====================================
  -- ワークテーブルデータ削除
    delete_table(
            ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
           ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
           ,ov_retcode         =>   lv_retcode       --   リターン・コード
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00042
                     ,iv_token_name1  => cv_msg_00042_token_1
                     ,iv_token_value1 => cv_msg_wk_tbl || '、' || cv_msg_wk_tbl_output
                   );
      lv_retcode := cv_status_error;
--20091119_修正_SCS.Tsukino_ADD_START
      RAISE internal_api_expt;
--20091119_修正_SCS.Tsukino_ADD_END
    END IF;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    WHEN param_invalid_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00055
                   );
      ov_retcode := cv_status_error;
    WHEN date_invalid_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00011
                     ,iv_token_name1  => cv_msg_00011_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      ov_retcode := cv_status_error;
    WHEN reverse_invalid_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00025
                     ,iv_token_name1  => cv_msg_00025_token_1
                     ,iv_token_value1 => lv_plan_from
                     ,iv_token_name2  => cv_msg_00025_token_2
                     ,iv_token_value2 => lv_plan_to
                   );
      ov_retcode := cv_status_error;
    WHEN past_date_invalid_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 START   ########################################
--
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
--20091104_Ver2.2_I_E_479_010_SCS.Goto_DEL_START
--  /**********************************************************************************
--   * Procedure Name   : get_plant_mark
--   * Description      : 工場固有記号取得処理（A-21）
--   ***********************************************************************************/
--  PROCEDURE get_plant_mark(
--     io_xwsp_rec              IN OUT XXCOP_WK_SHIP_PLANNING%ROWTYPE    --   工場出荷ワークレコードタイプ
--    ,ov_errbuf                OUT VARCHAR2                             --   エラー・メッセージ           --# 固定 #
--    ,ov_retcode               OUT VARCHAR2                             --   リターン・コード             --# 固定 #
--    ,ov_errmsg                OUT VARCHAR2                             --   ユーザー・エラー・メッセージ --# 固定 #
--    )
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_plant_mark'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
----
--    -- *** ローカル・カーソル ***
----
--    -- *** ローカル・レコード ***
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        実処理の記述             ***
--    -- ***       共通関数の呼び出し        ***
--    -- ***************************************
----
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--    );
--    --工場固有記号取得処理
--    BEGIN
--      SELECT ffmb.attribute6 attribut6
--      INTO   io_xwsp_rec.plant_mark
--      FROM   fm_matl_dtl      fmd
--            ,fm_form_mst_b    ffmb
--      WHERE  fmd.formula_id = ffmb.formula_id
--      AND    fmd.item_id = io_xwsp_rec.item_id
--          AND    ffmb.attribute6 is not null
--      AND    ROWNUM = 1
--      ;
--    EXCEPTION
--      --既存データがない場合
--      WHEN NO_DATA_FOUND THEN
--        ov_retcode := cv_status_warn;
--    END;
----
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END get_plant_mark;
----
--20091104_Ver2.2_I_E_479_010_SCS.Goto_DEL_END
  /**********************************************************************************
   * Procedure Name   : insert_wk_tbl
   * Description      : ワークテーブルデータ登録(A-22)
   ***********************************************************************************/
  PROCEDURE insert_wk_tbl(
     ir_xwsp_rec         IN  xxcop_wk_ship_planning%ROWTYPE    --   工場出荷ワークレコードタイプ
    ,ov_errbuf           OUT VARCHAR2                          --   エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT VARCHAR2                          --   リターン・コード             --# 固定 #
    ,ov_errmsg           OUT VARCHAR2)                         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_wk_tbl'; -- プログラム名
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
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    BEGIN
    --ファイルアップロードテーブルデータ登録処理
      INSERT INTO xxcop_wk_ship_planning(
         transaction_id
        ,org_data_lvl
        ,plant_org_id
        ,plant_org_code
        ,plant_org_name
        ,plant_mark
        ,own_flg
        ,inventory_item_id
        ,item_id
        ,item_no
        ,item_name
        ,num_of_case
        ,palette_max_cs_qty
        ,palette_max_step_qty
        ,product_schedule_date
        ,product_schedule_qty
        ,ship_org_id
        ,ship_org_code
        ,ship_org_name
        ,ship_lct_id
        ,ship_lct_code
        ,ship_lct_name
        ,ship_calendar_code
        ,receipt_org_id
        ,receipt_org_code
        ,receipt_org_name
        ,receipt_lct_id
        ,receipt_lct_code
        ,receipt_lct_name
        ,receipt_calendar_code
        ,cnt_ship_org
        ,shipping_date
        ,receipt_date
        ,delivery_lead_time
        ,shipping_pace
        ,under_lvl_pace
        ,schedule_qty
        ,before_stock
        ,after_stock
        ,stock_days
        ,assignment_set_type
        ,assignment_type
        ,sourcing_rule_type
        ,sourcing_rule_name
        ,shipping_type
        ,minus_flg
        ,frq_location_id
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
      VALUES(
         ir_xwsp_rec.transaction_id
        ,ir_xwsp_rec.org_data_lvl
        ,ir_xwsp_rec.plant_org_id
        ,ir_xwsp_rec.plant_org_code
        ,ir_xwsp_rec.plant_org_name
        ,ir_xwsp_rec.plant_mark
        ,ir_xwsp_rec.own_flg
        ,ir_xwsp_rec.inventory_item_id
        ,ir_xwsp_rec.item_id
        ,ir_xwsp_rec.item_no
        ,ir_xwsp_rec.item_name
        ,ir_xwsp_rec.num_of_case
        ,ir_xwsp_rec.palette_max_cs_qty
        ,ir_xwsp_rec.palette_max_step_qty
        ,ir_xwsp_rec.product_schedule_date
        ,ir_xwsp_rec.product_schedule_qty
        ,ir_xwsp_rec.ship_org_id
        ,ir_xwsp_rec.ship_org_code
        ,ir_xwsp_rec.ship_org_name
        ,ir_xwsp_rec.ship_lct_id
        ,ir_xwsp_rec.ship_lct_code
        ,ir_xwsp_rec.ship_lct_name
        ,ir_xwsp_rec.ship_calendar_code
        ,ir_xwsp_rec.receipt_org_id
        ,ir_xwsp_rec.receipt_org_code
        ,ir_xwsp_rec.receipt_org_name
        ,ir_xwsp_rec.receipt_lct_id
        ,ir_xwsp_rec.receipt_lct_code
        ,ir_xwsp_rec.receipt_lct_name
        ,ir_xwsp_rec.receipt_calendar_code
        ,ir_xwsp_rec.cnt_ship_org
        ,ir_xwsp_rec.shipping_date
        ,ir_xwsp_rec.receipt_date
        ,ir_xwsp_rec.delivery_lead_time
        ,ir_xwsp_rec.shipping_pace
        ,ir_xwsp_rec.under_lvl_pace
        ,ir_xwsp_rec.schedule_qty
        ,ir_xwsp_rec.before_stock
        ,ir_xwsp_rec.after_stock
        ,ir_xwsp_rec.stock_days
        ,ir_xwsp_rec.assignment_set_type
        ,ir_xwsp_rec.assignment_type
        ,ir_xwsp_rec.sourcing_rule_type
        ,ir_xwsp_rec.sourcing_rule_name
        ,ir_xwsp_rec.shipping_type
        ,ir_xwsp_rec.minus_flg
        ,ir_xwsp_rec.frq_location_id
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
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        NULL;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_msg_wk_tbl
                     );
        RAISE internal_process_expt;
    END;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END insert_wk_tbl;
--
  /**********************************************************************************
   * Procedure Name   : get_schedule_date
   * Description      : 基準生産計画取得（A-2）
   ***********************************************************************************/
  PROCEDURE get_schedule_date(
     io_xwsp_rec         IN OUT xxcop_wk_ship_planning%ROWTYPE       --   工場出荷ワークレコードタイプ
    ,ov_errbuf           OUT VARCHAR2            --   エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT VARCHAR2            --   リターン・コード             --# 固定 #
    ,ov_errmsg           OUT VARCHAR2)           --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_schedule_date'; -- プログラム名
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
    -- *** ローカル・レコード ***
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
  --倉庫情報取得処理
    xxcop_common_pkg2.get_loct_info(
       id_target_date       =>    io_xwsp_rec.product_schedule_date            -- 対象日付
      ,in_organization_id   =>    io_xwsp_rec.plant_org_id                     -- 組織ID(工場倉庫ID）
      ,ov_organization_code =>    io_xwsp_rec.ship_org_code                    -- 組織コード
      ,ov_organization_name =>    io_xwsp_rec.ship_org_name                    -- 組織名称
      ,on_loct_id           =>    io_xwsp_rec.ship_lct_id                      -- 保管倉庫ID
      ,ov_loct_code         =>    io_xwsp_rec.ship_lct_code                    -- 保管倉庫コード
      ,ov_loct_name         =>    io_xwsp_rec.ship_lct_name                    -- 保管倉庫名称
      ,ov_calendar_code     =>    io_xwsp_rec.ship_calendar_code               -- カレンダコード
      ,ov_errbuf            =>    lv_errbuf               --   エラー・メッセージ           --# 固定 #
      ,ov_retcode           =>    lv_retcode              --   リターン・コード             --# 固定 #
      ,ov_errmsg            =>    lv_errmsg               --   ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00050
                      ,iv_token_name1  => cv_msg_00050_token_1
                      ,iv_token_value1 => TO_CHAR(io_xwsp_rec.plant_org_id)
                    );
      RAISE global_api_expt;
    --データが1件も取得できなかった場合、倉庫情報取得エラーを出力し、後処理中止
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00050
                      ,iv_token_name1  => cv_msg_00050_token_1
                      ,iv_token_value1 => io_xwsp_rec.ship_org_code
                    );
      RAISE internal_process_expt;
    END IF;
  --品目情報取得処理
    xxcop_common_pkg2.get_item_info(
       id_target_date          =>      io_xwsp_rec.product_schedule_date       -- 計画日付
      ,in_organization_id      =>      io_xwsp_rec.plant_org_id                -- 工場倉庫ID
      ,in_inventory_item_id    =>      io_xwsp_rec.inventory_item_id           -- 在庫品目ID
      ,on_item_id              =>      io_xwsp_rec.item_id                     -- OPM品目ID
      ,ov_item_no              =>      io_xwsp_rec.item_no                     -- 品目コード
      ,ov_item_name            =>      io_xwsp_rec.item_name                   -- 品目名称
      ,on_num_of_case          =>      io_xwsp_rec.num_of_case                 -- ケース入数
      ,on_palette_max_cs_qty   =>      io_xwsp_rec.palette_max_cs_qty          -- 配数
      ,on_palette_max_step_qty =>      io_xwsp_rec.palette_max_step_qty        -- 段数
      ,ov_errbuf               =>      lv_errbuf               --   エラー・メッセージ           --# 固定 #
      ,ov_retcode              =>      lv_retcode              --   リターン・コード             --# 固定 #
      ,ov_errmsg               =>      lv_errmsg               --   ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00049
                      ,iv_token_name1  => cv_msg_00049_token_1
                      ,iv_token_value1 => io_xwsp_rec.inventory_item_id
                   );
      RAISE global_api_expt;
    --データが1件も取得できなかった場合、品目情報取得エラーを出力し、処理をスキップ
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00049
                      ,iv_token_name1  => cv_msg_00049_token_1
                      ,iv_token_value1 => io_xwsp_rec.item_no
                    );
      RAISE expt_next_record;
    END IF;
--20091104_Ver2.2_I_E_479_010_SCS.Goto_DEL_START
--  -- 工場固有記号取得
--    get_plant_mark(
--       io_xwsp_rec          =>   io_xwsp_rec  --   工場出荷ワークレコードタイプ
--      ,ov_errmsg            =>   lv_errmsg    --   エラー・メッセージ
--      ,ov_errbuf            =>   lv_errbuf    --   リターン・コード
--      ,ov_retcode           =>   lv_retcode    --   ユーザー・エラー・メッセージ
--      );
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_api_expt;
--    --工場固有記号を取得できなかった場合、工場固有記号取得エラーを出力し、後処理中止
--    ELSIF (lv_retcode = cv_status_warn) THEN
--      lv_errmsg :=  xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_appl_cont
--                      ,iv_name         => cv_msg_10025
--                      ,iv_token_name1  => cv_msg_10025_token_1
--                      ,iv_token_value1 => io_xwsp_rec.item_no
--                      ,iv_token_name2  => cv_msg_10025_token_2
--                      ,iv_token_value2 => io_xwsp_rec.item_name
--                    );
--      RAISE internal_process_expt;
--    END IF;
--20091104_Ver2.2_I_E_479_010_SCS.Goto_DEL_END
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name ||'工場出荷計画ワークテーブル登録処理実施前'
    );
    -- 工場出荷計画ワークテーブル登録処理
    insert_wk_tbl(
       ir_xwsp_rec          =>   io_xwsp_rec           --   工場出荷ワークレコードタイプ
      ,ov_errmsg            =>   lv_errmsg             --   エラー・メッセージ
      ,ov_errbuf            =>   lv_errbuf             --   リターン・コード
      ,ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN
      RAISE internal_process_expt;
    END IF;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name ||'工場出荷計画ワークテーブル登録処理実施後'
    );
--
  EXCEPTION
    WHEN expt_next_record THEN
      fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => lv_errmsg
                     );
      ov_retcode := cv_status_warn;
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END get_schedule_date;
--
  /**********************************************************************************
   * Procedure Name   : get_shipping_pace
   * Description      : 出荷ペース取得処理（A-52）
   ***********************************************************************************/
  PROCEDURE get_shipping_pace(
     io_xwsp_rec         IN OUT xxcop_wk_ship_planning%ROWTYPE       --   工場出荷ワークレコードタイプ
    ,ov_errbuf           OUT VARCHAR2            --   エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT VARCHAR2            --   リターン・コード             --# 固定 #
    ,ov_errmsg           OUT VARCHAR2)           --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_shipping_pace'; -- プログラム名

--#####################  固定ローカル変数宣言部 START   ########################

    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ

--###########################  固定部 END   ####################################

    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***

    -- *** ローカル変数 ***
    ln_quantity     NUMBER;
    ln_working_days NUMBER;
    ln_shipped_quantity  NUMBER;
    
    -- *** ローカル・レコード ***
    lr_xwsp_rec   xxcop_wk_ship_planning%ROWTYPE;
  BEGIN
--##################  固定ステータス初期化部 START   ###################

    ov_retcode := cv_status_normal;

--###########################  固定部 END   ############################

    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
  -- ====================================
  -- 出荷ペース取得処理
  -- ====================================
  --処理2で取得した、出荷計画区分が予測の場合（入力パラメータの出荷計画区分が予測）
  IF (io_xwsp_rec.shipping_type = cv_plan_typef) THEN    --出荷予測'2'
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '予測' 
          );  
    --共通関数:出荷予測取得処理
    xxcop_common_pkg2.get_num_of_forecast(
       in_organization_id          =>         io_xwsp_rec.receipt_org_id  --(処理1で取得)在庫組織ID
      ,in_inventory_item_id        =>         io_xwsp_rec.inventory_item_id  --(処理4で取得)在庫品目ID
      ,id_plan_date_from           =>         gd_forcast_from             --(入力パラメータ)出荷予測期間(FROM)
      ,id_plan_date_to             =>         gd_forcast_to               --(入力パラメータ)出荷予測期間(TO)
      ,in_loct_id                  =>         io_xwsp_rec.receipt_lct_id  --OPM保管場所ID
      ,on_quantity                 =>         ln_quantity                 --出荷予測数
      ,ov_errbuf                   =>         lv_errbuf
      ,ov_retcode                  =>         lv_retcode
      ,ov_errmsg                   =>         lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
     --  出荷実績稼働日数取得
    xxcop_common_pkg2.get_working_days(
       iv_calendar_code            =>           io_xwsp_rec.receipt_calendar_code
      ,in_organization_id          =>           NULL
      ,in_loct_id                  =>           NULL
      ,id_from_date                =>           gd_forcast_from
      ,id_to_date                  =>           gd_forcast_to
      ,on_working_days             =>           ln_working_days           -- 稼動日
      ,ov_errbuf                   =>           lv_errbuf
      ,ov_retcode                  =>           lv_retcode
      ,ov_errmsg                   =>           lv_errmsg
      );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    ELSIF (ln_working_days = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00056
                     ,iv_token_name1  => cv_msg_00056_token_1
                     ,iv_token_value1 => TO_CHAR(gd_forcast_from,cv_date_format_slash)
                     ,iv_token_name2  => cv_msg_00056_token_2
                     ,iv_token_value2 => TO_CHAR(gd_forcast_to,cv_date_format_slash)
                   );
      RAISE internal_process_expt;
    END IF;
    --1稼動日あたりの出荷ペースを取得
  io_xwsp_rec.shipping_pace  :=   ROUND(ln_quantity/ln_working_days,0);
  --デバックメッセージ出力
  xxcop_common_pkg.put_debug_message(
     iov_debug_mode => gv_debug_mode
    ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name||','||'予測'||','||TO_CHAR(io_xwsp_rec.receipt_org_id)||','||TO_CHAR(io_xwsp_rec.shipping_pace)||'='||TO_CHAR(ln_quantity)||'/'||TO_CHAR(ln_working_days)
  );  
    --
  --処理2で取得した、出荷計画区分が実績の場合（入力パラメータの出荷計画区分がペース）
  ELSIF (io_xwsp_rec.shipping_type = cv_plan_typep) THEN
  --デバックメッセージ出力
  xxcop_common_pkg.put_debug_message(
     iov_debug_mode => gv_debug_mode
    ,iv_value       => '実績' 
        );  
    xxcop_common_pkg2.get_num_of_shipped(
         in_deliver_from_id          =>         io_xwsp_rec.receipt_lct_id --(処理4で取得)保管先倉庫ID
        ,in_item_id                  =>         io_xwsp_rec.item_id        --(処理1で取得)品目ID
        ,id_shipment_date_from       =>         gd_pace_from               --(入力パラメータ）出荷実績取得期間(FROM)
        ,id_shipment_date_to         =>         gd_pace_to                 --(入力パラメータ）出荷実績取得期間(TO)
        ,iv_freshness_condition      =>         NULL                       --鮮度条件
--20091203_Ver2.5_I_E_479_021_SCS.Goto_ADD_START
        ,in_inventory_item_id        =>         io_xwsp_rec.inventory_item_id
--20091203_Ver2.5_I_E_479_021_SCS.Goto_ADD_END
        ,on_shipped_quantity         =>         ln_shipped_quantity        --出荷実績数
        ,ov_errbuf                   =>         lv_errbuf
        ,ov_retcode                  =>         lv_retcode
        ,ov_errmsg                   =>         lv_errmsg
      );
    IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
    END IF;
    --  出荷実績稼働日数取得
    xxcop_common_pkg2.get_working_days(
         iv_calendar_code            =>           io_xwsp_rec.receipt_calendar_code
        ,in_organization_id          =>           NULL
        ,in_loct_id                  =>           NULL
        ,id_from_date                =>           gd_pace_from
        ,id_to_date                  =>           gd_pace_to
        ,on_working_days             =>           ln_working_days
        ,ov_errbuf                   =>           lv_errbuf
        ,ov_retcode                  =>           lv_retcode
        ,ov_errmsg                   =>           lv_errmsg
      );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    ELSIF (ln_working_days = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_appl_cont
                    ,iv_name         => cv_msg_00056
                    ,iv_token_name1  => cv_msg_00056_token_1
                    ,iv_token_value1 => TO_CHAR(gd_pace_from,cv_date_format_slash)
                    ,iv_token_name2  => cv_msg_00056_token_2
                    ,iv_token_value2 => TO_CHAR(gd_pace_to,cv_date_format_slash)
      );
      RAISE internal_process_expt;
    END IF;
    --1稼動日あたりの出荷ペースを取得
    io_xwsp_rec.shipping_pace  :=   ROUND(ln_shipped_quantity/ln_working_days,0);
    --  io_xwsp_rec := lr_xwsp_rec;
  END IF;
--  
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;

--#####################################  固定部 END   ##########################################
  END get_shipping_pace;
--
  /**********************************************************************************
   * Procedure Name   : get_plant_shipping
   * Description      : 工場出荷計画制御マスタ取得（A-3）
   ***********************************************************************************/
  PROCEDURE get_plant_shipping(
     io_xwsp_rec         IN OUT xxcop_wk_ship_planning%ROWTYPE  --   工場出荷ワークレコードタイプ
    ,ov_errbuf           OUT VARCHAR2                           --   エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT VARCHAR2                           --   リターン・コード             --# 固定 #
    ,ov_errmsg           OUT VARCHAR2)                          --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_plant_shipping'; -- プログラム名
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
    --倉庫情報取得処理にて使用
    ln_quantity           mrp_schedule_dates.schedule_quantity%TYPE := NULL;
    ln_shipped_quantity   xxinv_mov_lot_details.actual_quantity%TYPE := NULL;
    ln_working_days       NUMBER := 0;
--
    ln_organization_id    hr_all_organization_units.organization_id%TYPE := NULL;
    ln_inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE := NULL;
    ln_own_flg_cnt        NUMBER := 0;
    ln_loop_cnt           NUMBER := 0;
    ln_receipt_code       NUMBER := NULL;
    lv_receipt_code       VARCHAR2(4) := NULL;
--
    -- *** ローカル・カーソル ***
    --ワークテーブル取得カーソル（工場倉庫データレベル）
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id
        ,org_data_lvl
        ,plant_org_id
        ,plant_org_code
        ,plant_org_name
        ,plant_mark
        ,own_flg
        ,inventory_item_id
        ,item_id
        ,item_no
        ,item_name
        ,num_of_case
        ,palette_max_cs_qty
        ,palette_max_step_qty
        ,product_schedule_date
        ,product_schedule_qty
        ,ship_org_id
        ,ship_org_code
        ,ship_org_name
        ,ship_lct_id
        ,ship_lct_code
        ,ship_lct_name
        ,ship_calendar_code
        ,receipt_org_id
        ,receipt_org_code
        ,receipt_org_name
        ,receipt_lct_id
        ,receipt_lct_code
        ,receipt_lct_name
        ,receipt_calendar_code
        ,cnt_ship_org
        ,shipping_date
        ,receipt_date
        ,delivery_lead_time
        ,shipping_pace
        ,under_lvl_pace
        ,schedule_qty
        ,before_stock
        ,after_stock
        ,stock_days
        ,assignment_set_type
        ,assignment_type
        ,sourcing_rule_type
        ,sourcing_rule_name
     --   ,shipping_type
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_plant             --0 組織データレベル(工場レベル)
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_id
      ;
    --経路情報取得カーソル(出荷→受入)
    CURSOR get_plant_ship_cur IS
      SELECT
        inventory_item_id        inventory_item_id                     --在庫品目ID
       ,organization_id          organization_id                       --組織ID
       ,source_organization_id   source_organization_id                --出荷組織
       ,receipt_organization_id  receipt_organization_id               --受入組織
       ,own_flg                  own_flg                               --自倉庫フラグ
       ,ship_plan_type           ship_plan_type                        --出荷計画区分
       ,yusen                    yusen                                 --割当先優先度
       ,row_number               row_number
      FROM(
        SELECT
           inventory_item_id       inventory_item_id                        --在庫品目ID
          ,organization_id         organization_id                          --組織ID
          ,source_organization_id  source_organization_id                   --出荷組織
          ,receipt_organization_id receipt_organization_id                  --受入組織
          ,own_flg                 own_flg                                  --自倉庫フラグ
          ,ship_plan_type                                                   --出荷計画区分
          ,yusen                                                            --割当先優先度
          ,row_number()
          OVER(
           PARTITION BY  source_organization_id
                        ,receipt_organization_id
           ORDER BY yusen,sourcing_rule_type DESC
          ) AS  row_number
        FROM(
          SELECT
            keiro.inventory_item_id       inventory_item_id                 --在庫品目ID
           ,keiro.organization_id         organization_id                   --組織ID
           ,keiro.sourcing_rule_type      sourcing_rule_type                --ソースルールタイプ
           ,keiro.source_organization_id  source_organization_id            --出荷組織
           ,keiro.receipt_organization_id receipt_organization_id           --受入組織
           ,keiro.own_flg                 own_flg                           --自倉庫フラグ
           ,CASE WHEN dummy.yusen IS NOT NULL THEN dummy.ship_plan_type
                 ELSE keiro.ship_plan_type
            END                           ship_plan_type                    --出荷計画区分
           ,keiro.yusen                   yusen                             --割当先優先度
          FROM(
            SELECT
              inventory_item_id                                             --在庫品目ID
             ,organization_id                                               --組織ID
             ,sourcing_rule_type                                            --ソースルールタイプ
             ,source_organization_id                                        --出荷組織
             ,receipt_organization_id                                       --受入組織
             ,own_flg                                                       --自倉庫フラグ
             ,ship_plan_type                                                --出荷計画区分
             ,yusen                                                         --割当先優先度
            FROM(
              SELECT
                msso.source_organization_id   source_organization_id        --出荷組織ID
               ,msro.receipt_organization_id  receipt_organization_id       --受入組織ID
               ,msa.organization_id           organization_id               --組織ID
               ,msr.sourcing_rule_type        sourcing_rule_type            --ソースルールタイプ
               ,msa.inventory_item_id         inventory_item_id             --在庫品目ID
               ,msro.attribute1               own_flg                       --自工場対象フラグ
               ,msa.attribute1                ship_plan_type                --出荷計画区分
               ,flv.description               yusen                         --割当先優先度
              FROM
                mrp_assignment_sets    mas                                  --割当セットヘッダ表
               ,mrp_sr_assignments     msa                                  --割当セット明細表
               ,mrp_sourcing_rules     msr                                  --ソースルール/物流構成表
               ,mrp_sr_source_org      msso                                 --ソースルール出荷組織表
               ,mrp_sr_receipt_org     msro                                 --ソースルール受入組織表
               ,fnd_lookup_values      flv                                  --クイックコード
              WHERE  msa.sourcing_rule_id         = msr.sourcing_rule_id
              AND    msr.sourcing_rule_id         = msro.sourcing_rule_id
              AND    mas.attribute1               = cv_factory_ship_plan    -- '3' 工場出荷計画
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= gd_process_date
                                                      AND NVL(end_date_active,gd_process_date) >= gd_process_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id     --入力項目の組織品目id
              OR     msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = ln_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= io_xwsp_rec.product_schedule_date
              AND    NVL(msro.disable_date,io_xwsp_rec.product_schedule_date)           >= io_xwsp_rec.product_schedule_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= gd_process_date
              AND    NVL(flv.end_date_active,gd_process_date)  >= gd_process_date
              AND    flv.lookup_code              = TO_CHAR(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
            )
          ) keiro,
          (
            SELECT
              inventory_item_id           inventory_item_id                                         --在庫品目ID
             ,organization_id             organization_id                                           --組織ID
             ,sourcing_rule_type          sourcing_rule_type                                        --ソースルールタイプ
             ,source_organization_id      source_organization_id                                    --出荷組織
             ,receipt_organization_id     receipt_organization_id                                   --受入組織
             ,own_flg                     own_flg                                                   --自倉庫フラグ
             ,ship_plan_type              ship_plan_type                                            --出荷計画区分
             ,yusen                       yusen                                                     --割当先優先度
            FROM(
              SELECT
                msso.source_organization_id   source_organization_id        --出荷組織ID
               ,msro.receipt_organization_id  receipt_organization_id       --受入組織ID
               ,msa.organization_id           organization_id               --組織ID
               ,msr.sourcing_rule_type        sourcing_rule_type            --ソースルールタイプ
               ,msa.inventory_item_id         inventory_item_id             --在庫品目ID
               ,msro.attribute1               own_flg                       --自工場対象フラグ
               ,msa.attribute1                ship_plan_type                --出荷計画区分
               ,flv.description               yusen                         --割当先優先度
              FROM
                mrp_assignment_sets    mas                                  --割当セットヘッダ表
               ,mrp_sr_assignments     msa                                  --割当セット明細表
               ,mrp_sourcing_rules     msr                                  --ソースルール/物流構成表
               ,mrp_sr_source_org      msso                                 --ソースルール出荷組織表
               ,mrp_sr_receipt_org     msro                                 --ソースルール受入組織表
               ,fnd_lookup_values      flv                                  --クイックコード
              WHERE  msa.sourcing_rule_id         = msr.sourcing_rule_id
              AND    msr.sourcing_rule_id         = msro.sourcing_rule_id
              AND    mas.attribute1               = cv_factory_ship_plan
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= gd_process_date
                                                      AND NVL(end_date_active,gd_process_date) >= gd_process_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id
              OR     msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = TO_NUMBER(fnd_profile.value(cv_master_org_id))
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= io_xwsp_rec.product_schedule_date
              AND    NVL(msro.disable_date,io_xwsp_rec.product_schedule_date)  >= io_xwsp_rec.product_schedule_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag             = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= gd_process_date
              AND    NVL(flv.end_date_active,gd_process_date)         >= gd_process_date
              AND    flv.lookup_code              = TO_CHAR(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
              ORDER BY yusen
            )
            WHERE ROWNUM = 1
          ) dummy
          WHERE keiro.receipt_organization_id = NVL(dummy.organization_id(+),keiro.receipt_organization_id)
        )
      )
      WHERE row_number <= 1
      AND   ship_plan_type = NVL(gv_pace_type, ship_plan_type)
    ;
    -- *** ローカル・レコード ***
    lr_xwsp_rec   xxcop_wk_ship_planning%ROWTYPE := NULL;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --ワークテーブルよりデータ抽出
    <<get_wk_loop>>
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
    BEGIN
      --
      --変数初期化
      lr_xwsp_rec := NULL;
      ln_loop_cnt := 0;
      ln_own_flg_cnt := 0;
      --
      --工場出荷ワークレコードセット
      --↓全項目
      --工場出荷計画WorkテーブルID
      lr_xwsp_rec.transaction_id           := get_wk_ship_planning_rec.transaction_id;
      --1:組織データレベル(工場出荷レベル)
      lr_xwsp_rec.org_data_lvl             := cn_data_lvl_output;
      lr_xwsp_rec.plant_org_id             := get_wk_ship_planning_rec.plant_org_id;           --工場倉庫ID
      lr_xwsp_rec.plant_org_code           := get_wk_ship_planning_rec.plant_org_code;         --工場倉庫コード
      lr_xwsp_rec.plant_org_name           := get_wk_ship_planning_rec.plant_org_name;         --工場倉庫名
      lr_xwsp_rec.plant_mark               := get_wk_ship_planning_rec.plant_mark;             --工場固有記号
      lr_xwsp_rec.own_flg                  := get_wk_ship_planning_rec.own_flg;                --自工場対象フラグ
      lr_xwsp_rec.inventory_item_id        := get_wk_ship_planning_rec.inventory_item_id;      --在庫品目ID
      lr_xwsp_rec.item_id                  := get_wk_ship_planning_rec.item_id;                --OPM品目ID
      lr_xwsp_rec.item_no                  := get_wk_ship_planning_rec.item_no;                --品目コード
      lr_xwsp_rec.item_name                := get_wk_ship_planning_rec.item_name;              --品目名称
      lr_xwsp_rec.num_of_case              := get_wk_ship_planning_rec.num_of_case;            --ケース入数
      lr_xwsp_rec.palette_max_cs_qty       := get_wk_ship_planning_rec.palette_max_cs_qty;     --配数
      lr_xwsp_rec.palette_max_step_qty     := get_wk_ship_planning_rec.palette_max_step_qty;   --段数
      lr_xwsp_rec.product_schedule_date    := get_wk_ship_planning_rec.product_schedule_date;  --生産予定日
      lr_xwsp_rec.product_schedule_qty     := get_wk_ship_planning_rec.product_schedule_qty;   --生産計画数
      lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.ship_org_id;            --移動元組織ID
      lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.ship_org_code;          --移動元組織コード
      lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.ship_org_name;          --移動元組織名
      lr_xwsp_rec.ship_lct_id              := get_wk_ship_planning_rec.ship_lct_id;            --移動元保管場所ID
      lr_xwsp_rec.ship_lct_code            := get_wk_ship_planning_rec.ship_lct_code;          --移動元保管場所コード
      lr_xwsp_rec.ship_lct_name            := get_wk_ship_planning_rec.ship_lct_name;          --移動元保管場所名
      lr_xwsp_rec.ship_calendar_code       := get_wk_ship_planning_rec.ship_calendar_code;     --移動元カレンダコード
      lr_xwsp_rec.receipt_org_id           := get_wk_ship_planning_rec.receipt_org_id;         --移動先組織ID
      lr_xwsp_rec.receipt_org_code         := get_wk_ship_planning_rec.receipt_org_code;       --移動先組織コード
      lr_xwsp_rec.receipt_org_name         := get_wk_ship_planning_rec.receipt_org_name;       --移動先組織名
      lr_xwsp_rec.receipt_lct_id           := get_wk_ship_planning_rec.receipt_lct_id;         --移動先保管場所ID
      lr_xwsp_rec.receipt_lct_code         := get_wk_ship_planning_rec.receipt_lct_code;       --移動先保管場所コード
      lr_xwsp_rec.receipt_lct_name         := get_wk_ship_planning_rec.receipt_lct_name;       --移動先保管場所名
      lr_xwsp_rec.receipt_calendar_code    := get_wk_ship_planning_rec.receipt_calendar_code;  --移動先カレンダコード
      lr_xwsp_rec.cnt_ship_org             := get_wk_ship_planning_rec.cnt_ship_org;           --親倉庫件数
      lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.shipping_date;          --出荷日
      lr_xwsp_rec.receipt_date             := get_wk_ship_planning_rec.receipt_date;           --着荷日
      lr_xwsp_rec.delivery_lead_time       := get_wk_ship_planning_rec.delivery_lead_time;     --配送リードタイム
      lr_xwsp_rec.shipping_pace            := get_wk_ship_planning_rec.shipping_pace;          --出荷実績ペース
      lr_xwsp_rec.under_lvl_pace           := get_wk_ship_planning_rec.under_lvl_pace;         --下位倉庫出荷ペース
      lr_xwsp_rec.schedule_qty             := get_wk_ship_planning_rec.schedule_qty;           --計画数
      lr_xwsp_rec.before_stock             := get_wk_ship_planning_rec.before_stock;           --前在庫
      lr_xwsp_rec.after_stock              := get_wk_ship_planning_rec.after_stock;            --後在庫
      lr_xwsp_rec.stock_days               := get_wk_ship_planning_rec.stock_days;             --在庫日数
      lr_xwsp_rec.assignment_set_type      := get_wk_ship_planning_rec.assignment_set_type;    --割当セット区分
      lr_xwsp_rec.assignment_type          := get_wk_ship_planning_rec.assignment_type;        --割当先タイプ
      lr_xwsp_rec.sourcing_rule_type       := get_wk_ship_planning_rec.sourcing_rule_type;     --ソースルールタイプ
      lr_xwsp_rec.sourcing_rule_name       := get_wk_ship_planning_rec.sourcing_rule_name;     --ソースルール名
  --    lr_xwsp_rec.shipping_type            := gv_pace_type;          --出荷計画区分
      --↑全項目
      --カーソル変数代入
      ln_organization_id   := lr_xwsp_rec.ship_org_id;
      ln_inventory_item_id := lr_xwsp_rec.inventory_item_id;
      --
      --工場出荷計画制御マスタより受入組織データ抽出（出荷→受入）
      <<get_plant_ship_loop>>
      FOR get_plant_ship_rec IN get_plant_ship_cur LOOP
        ln_loop_cnt := ln_loop_cnt + 1;
        --ループ変数セット
        lr_xwsp_rec.receipt_org_id          := get_plant_ship_rec.receipt_organization_id; --受入組織（移動先倉庫ID）
        lr_xwsp_rec.own_flg                 := get_plant_ship_rec.own_flg;                 --自倉庫フラグ
        lr_xwsp_rec.shipping_type           := get_plant_ship_rec.ship_plan_type;          --出荷計画区分
        -- ===================================
        -- 倉庫情報取得処理
        -- ===================================
        xxcop_common_pkg2.get_loct_info(
           id_target_date         =>       lr_xwsp_rec.product_schedule_date    --（処理1で取得）計画日付
          ,in_organization_id     =>       lr_xwsp_rec.receipt_org_id           --（処理2で取得）移動先倉庫ID
          ,ov_organization_code   =>       lr_xwsp_rec.receipt_org_code           -- 移動先組織ID
          ,ov_organization_name   =>       lr_xwsp_rec.receipt_org_name         -- 移動先組織コード
          ,on_loct_id             =>       lr_xwsp_rec.receipt_lct_id           -- 保管倉庫ID
          ,ov_loct_code           =>       lr_xwsp_rec.receipt_lct_code         -- 保管倉庫コード
          ,ov_loct_name           =>       lr_xwsp_rec.receipt_lct_name         -- 保管倉庫名称
          ,ov_calendar_code       =>       lr_xwsp_rec.receipt_calendar_code    -- カレンダコード
          ,ov_errbuf              =>       lv_errbuf               --   エラー・メッセージ           --# 固定 #
          ,ov_retcode             =>       lv_retcode              --   リターン・コード             --# 固定 #
          ,ov_errmsg              =>       lv_errmsg               --   ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00050
                          ,iv_token_name1  => cv_msg_00050_token_1
                          ,iv_token_value1 => lr_xwsp_rec.receipt_org_id
                        );
          RAISE global_api_expt;
        --データが1件も取得できなかった場合、倉庫情報取得エラーを出力し、後処理中止
        ELSIF (lv_retcode = cv_status_warn) THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00050
                          ,iv_token_name1  => cv_msg_00050_token_1
                          ,iv_token_value1 => lr_xwsp_rec.receipt_org_code
                        );
          RAISE internal_process_expt;
        END IF;
        -- ===================================
        -- 配送リードタイム取得処理
        -- ===================================
        xxcop_common_pkg2.get_deliv_lead_time(
           id_target_date       =>      lr_xwsp_rec.product_schedule_date  --   (処理1で取得）計画日付
          ,iv_from_loct_code    =>      lr_xwsp_rec.ship_lct_code         --   (処理1で取得）出荷保管倉庫コード
          ,iv_to_loct_code      =>      lr_xwsp_rec.receipt_lct_code      --   (処理4で取得）受入保管倉庫コード
          ,on_delivery_lt       =>      lr_xwsp_rec.delivery_lead_time     --   リードタイム(日)
          ,ov_errbuf            =>      lv_errbuf                          --   エラー・メッセージ
          ,ov_retcode           =>      lv_retcode                          --   リターン・コード
          ,ov_errmsg            =>      lv_errmsg                         --   ユーザー・エラー・メッセージ
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --エラーメッセージ出力
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00053
                          ,iv_token_name1  => cv_msg_00053_token_1
                          ,iv_token_value1 => lr_xwsp_rec.ship_lct_code
                          ,iv_token_name2  => cv_msg_00053_token_2
                          ,iv_token_value2 => lr_xwsp_rec.receipt_lct_code
                        );
          RAISE internal_process_expt;
        END IF;
        --
        -- ===============================
        -- 出荷ペース取得処理
        -- ===============================
        get_shipping_pace(
          io_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
          ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
          ov_errbuf            =>   lv_errbuf,             --   リターン・コード
          ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
        END IF; 
        -- 着荷日取得処理
        xxcop_common_pkg2.get_receipt_date(
           iv_calendar_code         =>      lr_xwsp_rec.receipt_calendar_code
          ,in_organization_id       =>      lr_xwsp_rec.receipt_org_id
          ,in_loct_id               =>      lr_xwsp_rec.receipt_lct_id
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--          ,id_shipment_date         =>      lr_xwsp_rec.product_schedule_date
          ,id_shipment_date         =>      lr_xwsp_rec.shipping_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
          ,in_lead_time             =>      lr_xwsp_rec.delivery_lead_time
          ,od_receipt_date          =>      lr_xwsp_rec.receipt_date
          ,ov_errbuf                =>      lv_errbuf
          ,ov_retcode               =>      lv_retcode
          ,ov_errmsg                =>      lv_errmsg
        );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          ELSIF (lr_xwsp_rec.receipt_date IS NULL) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00066
                           ,iv_token_name1  => cv_msg_00066_token_1
                           ,iv_token_value1 => lr_xwsp_rec.receipt_lct_code
                           ,iv_token_name2  => cv_msg_00066_token_2
                           ,iv_token_value2 => lr_xwsp_rec.receipt_calendar_code
                           ,iv_token_name3  => cv_msg_00066_token_3
                           ,iv_token_value3 => TO_CHAR(lr_xwsp_rec.product_schedule_date,cv_date_format_slash)
                          );
            RAISE internal_process_expt;
          END IF;
        -- 工場出荷計画ワークテーブル登録処理
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
          ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
          ov_errbuf            =>   lv_errbuf,             --   リターン・コード
          ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
        END IF;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '代表倉庫存在チェック前' 
          );  
-------------------------------------------------------
        --代表倉庫存在チェック
        BEGIN
          BEGIN
            SELECT  mil2.organization_id
                   ,mil.attribute5
            INTO   ln_receipt_code
                  ,lv_receipt_code
            FROM    mtl_item_locations mil
                   ,(SELECT  mil3.organization_id  organization_id
                            , mil3.segment1        segment1
                     FROM   mtl_item_locations mil3
                     WHERE  mil3.segment1 =  mil3.attribute5
                     AND    mil3.attribute5 IS NOT NULL) mil2
            WHERE    mil.attribute5 IS NOT NULL
            AND      mil.segment1 = lr_xwsp_rec.receipt_lct_code
            AND      mil.attribute5 <> lr_xwsp_rec.receipt_lct_code
            AND      mil.attribute5 = mil2.segment1(+)
            ; 
          EXCEPTION 
            WHEN NO_DATA_FOUND THEN
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'when_no_data_found'
          );  
              RAISE no_action_expt;
          END;
          IF (ln_receipt_code IS NULL and lv_receipt_code = cv_org_code) THEN
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'zzzz'
          );  
            ln_receipt_code := NULL;
            lv_receipt_code := NULL;
            BEGIN
              SELECT  xxwfil.frq_item_location_id
                     ,xxwfil.frq_item_location_code
              INTO    ln_receipt_code
                     ,lv_receipt_code
              FROM   xxwsh_frq_item_locations xxwfil
              WHERE  xxwfil.item_location_id         =  lr_xwsp_rec.receipt_lct_id
              AND    xxwfil.item_id                  =  lr_xwsp_rec.item_id
              AND    xxwfil.frq_item_location_code   IS NOT NULL
              AND    xxwfil.frq_item_location_id     IS NOT NULL
              AND    xxwfil.frq_item_location_code   <> lr_xwsp_rec.receipt_lct_code
              ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RAISE no_action_expt;
            END;
--              IF (ln_receipt_code IS NULL) THEN
--                RAISE no_action_expt;
          END IF;
--            END;
--          ELSIF (ln_receipt_code IS NULL) THEN
--            RAISE no_action_expt;  
--          END IF;
--          END;
          lr_xwsp_rec.frq_location_id       := lr_xwsp_rec.receipt_lct_code;
          lr_xwsp_rec.receipt_org_id           := ln_receipt_code;
          lr_xwsp_rec.receipt_lct_code         := lv_receipt_code;
       -- 工場出荷計画ワークテーブル登録処理
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
          ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
          ov_errbuf            =>   lv_errbuf,             --   リターン・コード
          ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
          );
          lr_xwsp_rec.receipt_org_id      := NULL;
          lr_xwsp_rec.receipt_lct_code     := NULL;
          lr_xwsp_rec.frq_location_id     := NULL;
          IF (lv_retcode = cv_status_error) THEN
            RAISE internal_process_expt;
          END IF;
        EXCEPTION
          WHEN no_action_expt THEN
          NULL;
        END;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '代表倉庫存在チェック後' 
          );  
-------------------------------------------------------
        --自倉庫対象フラグYesの場合
        IF (lr_xwsp_rec.own_flg = cv_own_flg_on) AND (ln_own_flg_cnt = 0) THEN
          ln_own_flg_cnt                       := ln_own_flg_cnt + 1;
      --↓全項目
          lr_xwsp_rec.org_data_lvl             := cn_data_lvl_output;                          --組織データレベル
          lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.ship_org_id;        --移動元組織ID
          lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.ship_org_code;      --移動元組織コード
          lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.ship_org_name;      --移動元組織名
          lr_xwsp_rec.ship_lct_id              := get_wk_ship_planning_rec.ship_lct_id;        --移動元保管場所ID
          lr_xwsp_rec.ship_lct_code            := get_wk_ship_planning_rec.ship_lct_code;      --移動元保管場所コード
          lr_xwsp_rec.ship_lct_name            := get_wk_ship_planning_rec.ship_lct_name;      --移動元保管場所名
          lr_xwsp_rec.ship_calendar_code       := get_wk_ship_planning_rec.ship_calendar_code; --移動元カレンダコード
          lr_xwsp_rec.receipt_org_id           := get_wk_ship_planning_rec.ship_org_id;        --移動元組織ID
          lr_xwsp_rec.receipt_org_code         := get_wk_ship_planning_rec.ship_org_code;      --移動元組織コード
          lr_xwsp_rec.receipt_org_name         := get_wk_ship_planning_rec.ship_org_name;      --移動元組織名
          lr_xwsp_rec.receipt_lct_id           := get_wk_ship_planning_rec.ship_lct_id;        --移動元保管場所ID
          lr_xwsp_rec.receipt_lct_code         := get_wk_ship_planning_rec.ship_lct_code;      --移動元保管場所コード
          lr_xwsp_rec.receipt_lct_name         := get_wk_ship_planning_rec.ship_lct_name;      --移動元保管場所名
          lr_xwsp_rec.receipt_calendar_code    := get_wk_ship_planning_rec.ship_calendar_code; --移動元カレンダコード
          lr_xwsp_rec.cnt_ship_org             := cn_cnt_from;                                 --親件数 固定値1をセット
--20091120_Ver2.3_I_E_479_018_SCS.Goto_MOD_START
--          lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.product_schedule_date;  --出荷日
--          lr_xwsp_rec.receipt_date             := get_wk_ship_planning_rec.product_schedule_date;  --着荷日
          lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.shipping_date;      --出荷日
          lr_xwsp_rec.receipt_date             := get_wk_ship_planning_rec.shipping_date;      --着荷日
--20091120_Ver2.3_I_E_479_018_SCS.Goto_MOD_END
          lr_xwsp_rec.delivery_lead_time       := cn_delivery_lead_time;                           --配送リードタイム
          lr_xwsp_rec.shipping_pace            := get_wk_ship_planning_rec.shipping_pace;         --出荷実績ペース
         -- lr_xwsp_rec.shipping_type            := get_plant_ship_rec.ship_plan_type;               --出荷計画区分
          --↑全項目
          --
        -- ===============================
        -- 出荷ペース取得処理
        -- ===============================
        get_shipping_pace(
          io_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
          ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
          ov_errbuf            =>   lv_errbuf,             --   リターン・コード
          ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
        END IF; 
        -- 工場出荷計画ワークテーブル登録処理
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
          ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
          ov_errbuf            =>   lv_errbuf,             --   リターン・コード
          ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
          END IF;
        END IF;
      END LOOP get_plant_ship_loop;
      IF (ln_loop_cnt = 0) THEN
        RAISE no_data_skip_expt;
      END IF;
      EXCEPTION
      WHEN no_data_skip_expt THEN
        EXIT;
      END;
    END LOOP get_wk_loop;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END get_plant_shipping;
--
  /**********************************************************************************
   * Procedure Name   : get_base_yokomst
   * Description      : 基本横持ち制御マスタ取得（A-4）
   ***********************************************************************************/
  PROCEDURE get_base_yokomst(
     io_xwsp_rec         IN OUT xxcop_wk_ship_planning%ROWTYPE  --   工場出荷ワークレコードタイプ
    ,ov_errbuf           OUT VARCHAR2                           --   エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT VARCHAR2                           --   リターン・コード             --# 固定 #
    ,ov_errmsg           OUT VARCHAR2)                          --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_base_yokomst'; -- プログラム名
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
--    -- *** ローカル定数 ***
--
--    -- *** ローカル変数 ***
    ln_org_data_lvl       NUMBER := 1;   --初回ループはデータ出力レベル
    ln_loop_cnt           NUMBER := 0;   --ループカウント
    ln_organization_id    hr_all_organization_units.organization_id%TYPE := NULL;
    ln_inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE := NULL;
    ln_dual_chk           NUMBER := 0;
    ln_quantity           NUMBER := 0;
    ln_working_days       NUMBER := 0;
    ln_shipped_quantity  NUMBER := 0;
    ln_count_check        NUMBER;        --重複レコードチェック用
    ln_item_flg           NUMBER;
    ln_count_label        NUMBER;
    ln_receipt_code       NUMBER := NULL;
    lv_receipt_code       VARCHAR2(4) := NULL;
    --
    -- *** ローカル・カーソル ***
    --ワークテーブル取得カーソル
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id
        ,org_data_lvl
        ,plant_org_id
        ,plant_org_code
        ,plant_org_name
        ,plant_mark
        ,own_flg
        ,inventory_item_id
        ,item_id
        ,item_no
        ,item_name
        ,num_of_case
        ,palette_max_cs_qty
        ,palette_max_step_qty
        ,product_schedule_date
        ,product_schedule_qty
        ,ship_org_id
        ,ship_org_code
        ,ship_org_name
        ,ship_lct_id
        ,ship_lct_code
        ,ship_lct_name
        ,ship_calendar_code
        ,receipt_org_id
        ,receipt_org_code
        ,receipt_org_name
        ,receipt_lct_id
        ,receipt_lct_code
        ,receipt_lct_name
        ,receipt_calendar_code
        ,cnt_ship_org
        ,shipping_date
        ,receipt_date
        ,delivery_lead_time
        ,shipping_pace
        ,under_lvl_pace
        ,schedule_qty
        ,before_stock
        ,after_stock
        ,stock_days
        ,assignment_set_type
        ,assignment_type
        ,sourcing_rule_type
        ,sourcing_rule_name
        ,shipping_type
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = ln_org_data_lvl
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_id
      ;
    --経路情報取得カーソル(出荷→受入)
    CURSOR get_plant_ship_cur IS
      SELECT
        inventory_item_id            inventory_item_id                                              --在庫品目ID
       ,organization_id              organization_id                                                --組織ID
       ,source_organization_id       source_organization_id                                         --出荷組織
       ,receipt_organization_id      receipt_organization_id                                        --受入組織
       ,own_flg                      own_flg                                                        --自倉庫フラグ
   --    ,ship_plan_type               ship_plan_type                                                 --出荷計画区分
       ,yusen                        yusen                                                          --割当先優先度
       ,row_number                   row_number
      FROM(
        SELECT
           inventory_item_id       inventory_item_id                        --在庫品目ID
          ,organization_id         organization_id                          --組織ID
          ,source_organization_id  source_organization_id                   --出荷組織
          ,receipt_organization_id receipt_organization_id                  --受入組織
          ,own_flg                 own_flg                                  --自倉庫フラグ
          ,ship_plan_type                                                   --出荷計画区分
          ,yusen                                                            --割当先優先度
          ,row_number()
          OVER(
           PARTITION BY  source_organization_id
                        ,receipt_organization_id
           ORDER BY yusen,sourcing_rule_type DESC
          ) AS  row_number
        FROM(
          SELECT
            keiro.inventory_item_id       inventory_item_id                 --在庫品目ID
           ,keiro.organization_id         organization_id                   --組織ID
           ,keiro.sourcing_rule_type      sourcing_rule_type                --ソースルールタイプ
           ,keiro.source_organization_id  source_organization_id            --出荷組織
           ,keiro.receipt_organization_id receipt_organization_id           --受入組織
           ,keiro.own_flg                 own_flg                           --自倉庫フラグ
           ,CASE WHEN dummy.yusen IS NOT NULL THEN dummy.ship_plan_type
                 ELSE keiro.ship_plan_type
            END                           ship_plan_type                    --出荷計画区分
           ,keiro.yusen                   yusen                             --割当先優先度
          FROM(
            SELECT
              inventory_item_id                                             --在庫品目ID
             ,organization_id                                               --組織ID
             ,sourcing_rule_type                                            --ソースルールタイプ
             ,source_organization_id                                        --出荷組織
             ,receipt_organization_id                                       --受入組織
             ,own_flg                                                       --自倉庫フラグ
             ,ship_plan_type                                                --出荷計画区分
             ,yusen                                                         --割当先優先度
            FROM(
              SELECT
                msso.source_organization_id   source_organization_id        --出荷組織ID
               ,msro.receipt_organization_id  receipt_organization_id       --受入組織ID
               ,msa.organization_id           organization_id               --組織ID
               ,msr.sourcing_rule_type        sourcing_rule_type            --ソースルールタイプ
               ,msa.inventory_item_id         inventory_item_id             --在庫品目ID
               ,msro.attribute1               own_flg                       --自工場対象フラグ
               ,msa.attribute1                ship_plan_type                --出荷計画区分
               ,flv.description               yusen                         --割当先優先度
              FROM
                mrp_assignment_sets    mas                                  --割当セットヘッダ表
               ,mrp_sr_assignments     msa                                  --割当セット明細表
               ,mrp_sourcing_rules     msr                                  --ソースルール/物流構成表
               ,mrp_sr_source_org      msso                                 --ソースルール出荷組織表
               ,mrp_sr_receipt_org     msro                                 --ソースルール受入組織表
               ,fnd_lookup_values      flv                                  --クイックコード
              WHERE  msa.sourcing_rule_id         = msr.sourcing_rule_id
              AND    msr.sourcing_rule_id         = msro.sourcing_rule_id
              AND    mas.attribute1               = cv_base_plan   --基本横持ち制御マスタ
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= gd_process_date
                                                      AND NVL(end_date_active,gd_process_date) >= gd_process_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id     --入力項目の組織品目id
              OR    msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = ln_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= io_xwsp_rec.product_schedule_date
              AND    NVL(msro.disable_date,io_xwsp_rec.product_schedule_date)  >= io_xwsp_rec.product_schedule_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= gd_process_date
              AND    NVL(flv.end_date_active,gd_process_date)  >= gd_process_date
              AND    flv.lookup_code              = TO_CHAR(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
            )
          ) keiro,
          (
            SELECT
              inventory_item_id          inventory_item_id                                           --在庫品目ID
             ,organization_id            organization_id                                             --組織ID
             ,sourcing_rule_type         sourcing_rule_type                                          --ソースルールタイプ
             ,source_organization_id     source_organization_id                                      --出荷組織
             ,receipt_organization_id    receipt_organization_id                                     --受入組織
             ,own_flg                    own_flg                                                     --自倉庫フラグ
             ,ship_plan_type             ship_plan_type                                              --出荷計画区分
             ,yusen                      yusen                                                       --割当先優先度
            FROM(
              SELECT
                msso.source_organization_id   source_organization_id        --出荷組織ID
               ,msro.receipt_organization_id  receipt_organization_id       --受入組織ID
               ,msa.organization_id           organization_id               --組織ID
               ,msr.sourcing_rule_type        sourcing_rule_type            --ソースルールタイプ
               ,msa.inventory_item_id         inventory_item_id             --在庫品目ID
               ,msro.attribute1               own_flg                       --自工場対象フラグ
               ,msa.attribute1                ship_plan_type                --出荷計画区分
               ,flv.description               yusen                         --割当先優先度
              FROM
                mrp_assignment_sets    mas                                  --割当セットヘッダ表
               ,mrp_sr_assignments     msa                                  --割当セット明細表
               ,mrp_sourcing_rules     msr                                  --ソースルール/物流構成表
               ,mrp_sr_source_org      msso                                 --ソースルール出荷組織表
               ,mrp_sr_receipt_org     msro                                 --ソースルール受入組織表
               ,fnd_lookup_values      flv                                  --クイックコード
              WHERE  msa.sourcing_rule_id         = msr.sourcing_rule_id
              AND    msr.sourcing_rule_id         = msro.sourcing_rule_id
              AND    mas.attribute1               = cv_base_plan    --基本横持ち制御マスタ
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= gd_process_date
                                                      AND NVL(end_date_active,gd_process_date) >= gd_process_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id
              OR    msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = TO_NUMBER(fnd_profile.value(cv_master_org_id))
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= io_xwsp_rec.product_schedule_date
              AND    NVL(msro.disable_date,io_xwsp_rec.product_schedule_date)  >= io_xwsp_rec.product_schedule_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag             = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= gd_process_date
              AND    NVL(flv.end_date_active,gd_process_date)         >= gd_process_date
              AND    flv.lookup_code              = TO_CHAR(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
              ORDER BY yusen
            )
            WHERE ROWNUM = 1
          ) dummy
          WHERE keiro.receipt_organization_id = NVL(dummy.organization_id(+),keiro.receipt_organization_id)
        )
      )
      WHERE row_number <= 1
    ;
    -- *** ローカル・レコード ***
    lr_xwsp_rec   xxcop_wk_ship_planning%ROWTYPE := NULL;
    get_wk_ship_planning_rec get_wk_ship_planning_cur%ROWTYPE;
    get_plant_ship_rec get_plant_ship_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  --===================================
  --ワークテーブルよりデータ抽出
  --===================================
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    <<lvl_countup_loop>>
    LOOP
    OPEN get_wk_ship_planning_cur;
    <<get_wk_loop>>
    LOOP
    FETCH get_wk_ship_planning_cur INTO  get_wk_ship_planning_rec;
      IF (get_wk_ship_planning_cur%NOTFOUND)
         OR  (get_wk_ship_planning_cur%ROWCOUNT = 0) THEN
          --ln_item_flg := 1;
          EXIT;
      END IF;
      ln_count_label  := ln_org_data_lvl + 1;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name||'1'
    );
      --変数初期化
      ln_item_flg := 1;
      lr_xwsp_rec := NULL;
      --
      --工場出荷ワークレコードセット
      --↓全項目
      --工場出荷計画WorkテーブルID
      lr_xwsp_rec.transaction_id           := get_wk_ship_planning_rec.transaction_id;
--      IF (ln_org_data_lvl = 1) THEN
      lr_xwsp_rec.org_data_lvl             := ln_org_data_lvl + 1;                                 --組織データレベル
--      ELSE
--      lr_xwsp_rec.org_data_lvl             := ln_org_data_lvl;
--      END IF;
      lr_xwsp_rec.plant_org_id             := get_wk_ship_planning_rec.plant_org_id;           --工場倉庫ID
      lr_xwsp_rec.plant_org_code           := get_wk_ship_planning_rec.plant_org_code;         --工場倉庫コード
      lr_xwsp_rec.plant_org_name           := get_wk_ship_planning_rec.plant_org_name;         --工場倉庫名
      lr_xwsp_rec.plant_mark               := get_wk_ship_planning_rec.plant_mark;             --工場固有記号
      lr_xwsp_rec.own_flg                  := get_wk_ship_planning_rec.own_flg;                --自工場対象フラグ
      lr_xwsp_rec.inventory_item_id        := get_wk_ship_planning_rec.inventory_item_id;      --在庫品目ID
      lr_xwsp_rec.item_id                  := get_wk_ship_planning_rec.item_id;                --OPM品目ID
      lr_xwsp_rec.item_no                  := get_wk_ship_planning_rec.item_no;                --品目コード
      lr_xwsp_rec.item_name                := get_wk_ship_planning_rec.item_name;              --品目名称
      lr_xwsp_rec.num_of_case              := get_wk_ship_planning_rec.num_of_case;            --ケース入数
      lr_xwsp_rec.palette_max_cs_qty       := get_wk_ship_planning_rec.palette_max_cs_qty;     --配数
      lr_xwsp_rec.palette_max_step_qty     := get_wk_ship_planning_rec.palette_max_step_qty;   --段数
      lr_xwsp_rec.product_schedule_date    := get_wk_ship_planning_rec.product_schedule_date;  --生産予定日
      lr_xwsp_rec.product_schedule_qty     := get_wk_ship_planning_rec.product_schedule_qty;   --生産計画数
      lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.receipt_org_id;         --移動元組織ID
      lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.receipt_org_code;       --移動元組織コード
      lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.receipt_org_name;       --移動元組織名
      lr_xwsp_rec.ship_lct_id              := get_wk_ship_planning_rec.receipt_lct_id;         --移動元保管場所ID
      lr_xwsp_rec.ship_lct_code            := get_wk_ship_planning_rec.receipt_lct_code;       --移動元保管場所コード
      lr_xwsp_rec.ship_lct_name            := get_wk_ship_planning_rec.receipt_lct_name;       --移動元保管場所名
      lr_xwsp_rec.ship_calendar_code       := get_wk_ship_planning_rec.receipt_calendar_code;  --移動元カレンダコード
      lr_xwsp_rec.cnt_ship_org             := get_wk_ship_planning_rec.cnt_ship_org;           --親倉庫件数
      lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.shipping_date;          --出荷日
      lr_xwsp_rec.receipt_date             := get_wk_ship_planning_rec.receipt_date;           --着荷日
      lr_xwsp_rec.delivery_lead_time       := get_wk_ship_planning_rec.delivery_lead_time;     --配送リードタイム
      lr_xwsp_rec.shipping_pace            := get_wk_ship_planning_rec.shipping_pace;          --出荷実績ペース
      lr_xwsp_rec.under_lvl_pace           := get_wk_ship_planning_rec.under_lvl_pace;         --下位倉庫出荷ペース
      lr_xwsp_rec.schedule_qty             := get_wk_ship_planning_rec.schedule_qty;           --計画数
      lr_xwsp_rec.before_stock             := get_wk_ship_planning_rec.before_stock;           --前在庫
      lr_xwsp_rec.after_stock              := get_wk_ship_planning_rec.after_stock;            --後在庫
      lr_xwsp_rec.stock_days               := get_wk_ship_planning_rec.stock_days;             --在庫日数
      lr_xwsp_rec.assignment_set_type      := get_wk_ship_planning_rec.assignment_set_type;    --割当セット区分
      lr_xwsp_rec.assignment_type          := get_wk_ship_planning_rec.assignment_type;        --割当先タイプ
      lr_xwsp_rec.sourcing_rule_type       := get_wk_ship_planning_rec.sourcing_rule_type;     --ソースルールタイプ
      lr_xwsp_rec.sourcing_rule_name       := get_wk_ship_planning_rec.sourcing_rule_name;     --ソースルール名
      lr_xwsp_rec.shipping_type            := get_wk_ship_planning_rec.shipping_type;          --出荷計画区分
    --  lr_xwsp_rec.shipping_type            := NULL;          --出荷計画区分

      --
      --カーソル変数代入
      ln_organization_id   := lr_xwsp_rec.ship_org_id;--受入側
      ln_inventory_item_id := lr_xwsp_rec.inventory_item_id;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'カーソル変数'||TO_CHAR(ln_organization_id)
    );
      --
      --工場出荷計画制御マスタより受入組織データ抽出（出荷→受入）
      <<get_plant_ship_loop>>
      OPEN get_plant_ship_cur;
      LOOP
      FETCH get_plant_ship_cur INTO get_plant_ship_rec;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name||'2'
    );
        IF (get_plant_ship_cur%NOTFOUND)
            OR  (get_plant_ship_cur%ROWCOUNT = 0) THEN
          --UPDATE 物流計画ワークテーブル内のWK2レコードのレベル
            UPDATE xxcop_wk_ship_planning xxwsp
            SET xxwsp.org_data_lvl = ln_count_label
            WHERE xxwsp.transaction_id         = lr_xwsp_rec.transaction_id
            AND   xxwsp.plant_org_id           = lr_xwsp_rec.plant_org_id
            AND   xxwsp.inventory_item_id      = lr_xwsp_rec.inventory_item_id
            AND   xxwsp.product_schedule_date  = lr_xwsp_rec.product_schedule_date
            AND   xxwsp.org_data_lvl >= ln_count_label   --レベル以上ln_count_label
            AND   xxwsp.org_data_lvl <= ln_org_data_lvl  --ラベル以下ln_org_data_lvl
            ;
            EXIT;
        END IF;
        --ループ変数セット
        lr_xwsp_rec.receipt_org_id          := get_plant_ship_rec.receipt_organization_id;--受入側
        lr_xwsp_rec.own_flg                 := get_plant_ship_rec.own_flg;
   --     lr_xwsp_rec.shipping_type           := get_plant_ship_rec.ship_plan_type;
        -- ===================================
        -- 倉庫情報取得処理
        -- ===================================
        xxcop_common_pkg2.get_loct_info(
           id_target_date         =>       lr_xwsp_rec.product_schedule_date  --（処理1で取得）計画日付
          ,in_organization_id     =>       lr_xwsp_rec.receipt_org_id         --（処理1で取得）移動先倉庫ID
          ,ov_organization_code   =>       lr_xwsp_rec.receipt_org_code       -- 組織コード
          ,ov_organization_name   =>       lr_xwsp_rec.receipt_org_name       -- 組織名称
          ,on_loct_id             =>       lr_xwsp_rec.receipt_lct_id         -- 保管倉庫ID
          ,ov_loct_code           =>       lr_xwsp_rec.receipt_lct_code       -- 保管倉庫コード
          ,ov_loct_name           =>       lr_xwsp_rec.receipt_lct_name       -- 保管倉庫名称
          ,ov_calendar_code       =>       lr_xwsp_rec.receipt_calendar_code  -- カレンダコード
          ,ov_errbuf              =>       lv_errbuf               --   エラー・メッセージ           --# 固定 #
          ,ov_retcode             =>       lv_retcode              --   リターン・コード             --# 固定 #
          ,ov_errmsg              =>       lv_errmsg               --   ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00050
                          ,iv_token_name1  => cv_msg_00050_token_1
                          ,iv_token_value1 => lr_xwsp_rec.receipt_org_id
                        );
          RAISE global_api_expt;
        --データが1件も取得できなかった場合、倉庫情報取得エラーを出力し、後処理中止
        ELSIF (lv_retcode = cv_status_warn) THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00050
                          ,iv_token_name1  => cv_msg_00050_token_1
                          ,iv_token_value1 => lr_xwsp_rec.receipt_org_code
                        );
          RAISE internal_process_expt;
        END IF;
        -- ===============================
        -- 出荷ペース取得処理
        -- ===============================
        get_shipping_pace(
          io_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
          ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
          ov_errbuf            =>   lv_errbuf,             --   リターン・コード
          ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
        END IF; 
        -- ===================================
        -- 配送リードタイム取得処理
        -- ===================================
        xxcop_common_pkg2.get_deliv_lead_time   (
           id_target_date       =>      lr_xwsp_rec.product_schedule_date  --   (処理1で取得）計画日付
          ,iv_from_loct_code    =>      lr_xwsp_rec.ship_lct_code         --   (処理1で取得）移動元保管場所コード
          ,iv_to_loct_code      =>      lr_xwsp_rec.receipt_lct_code      --   (処理4で取得）移動先保管場所コード
          ,on_delivery_lt       =>      lr_xwsp_rec.delivery_lead_time     --   リードタイム(日)
          ,ov_errbuf            =>      lv_errbuf                          --   ユーザー・エラー・メッセージ
          ,ov_retcode           =>      lv_retcode                          -- リターン・コード
          ,ov_errmsg            =>      lv_errmsg                         --   エラー・メッセージ
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --エラーメッセージ出力
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00053
                          ,iv_token_name1  => cv_msg_00053_token_1
                          ,iv_token_value1 => lr_xwsp_rec.ship_lct_code
                          ,iv_token_name2  => cv_msg_00053_token_2
                          ,iv_token_value2 => lr_xwsp_rec.receipt_lct_code
                        );
          RAISE internal_process_expt;
        END IF;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name || 'lv_retcode' || lv_retcode 
    );
        -- 着荷日取得処理
        xxcop_common_pkg2.get_receipt_date(
           iv_calendar_code         =>      lr_xwsp_rec.ship_calendar_code
          ,in_organization_id       =>      lr_xwsp_rec.receipt_org_id
          ,in_loct_id               =>      lr_xwsp_rec.receipt_lct_id
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--          ,id_shipment_date         =>      lr_xwsp_rec.product_schedule_date
          ,id_shipment_date         =>      lr_xwsp_rec.shipping_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
          ,in_lead_time             =>      lr_xwsp_rec.delivery_lead_time
          ,od_receipt_date          =>      lr_xwsp_rec.receipt_date
          ,ov_errbuf                =>      lv_errbuf
          ,ov_retcode               =>      lv_retcode
          ,ov_errmsg                =>      lv_errmsg
        );
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name || '着荷日' || TO_CHAR(lr_xwsp_rec.receipt_date,'YYYY/MM/DD')
    );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        ELSIF (lr_xwsp_rec.receipt_date IS NULL) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00066
                       ,iv_token_name1  => cv_msg_00066_token_1
                       ,iv_token_value1 => lr_xwsp_rec.receipt_lct_code
                       ,iv_token_name2  => cv_msg_00066_token_2
                       ,iv_token_value2 => lr_xwsp_rec.ship_calendar_code
                       ,iv_token_name3  => cv_msg_00066_token_3
                       ,iv_token_value3 => TO_CHAR(lr_xwsp_rec.product_schedule_date,cv_date_format_slash)
                      );
          RAISE internal_process_expt;
        END IF;
        -- 工場出荷計画ワークテーブル登録処理
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
          ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
          ov_errbuf            =>   lv_errbuf,             --   リターン・コード
          ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
        END IF;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '代表倉庫存在チェック前' 
          );  
-------------------------------------------------------
        --代表倉庫存在チェック
        BEGIN
          BEGIN
            SELECT  mil2.organization_id
                   ,mil.attribute5
            INTO   ln_receipt_code
                  ,lv_receipt_code
            FROM    mtl_item_locations mil
                   ,(SELECT  mil3.organization_id  organization_id
                            , mil3.segment1        segment1
                     FROM   mtl_item_locations mil3
                     WHERE  mil3.segment1 =  mil3.attribute5
                     AND    mil3.attribute5 IS NOT NULL) mil2
            WHERE    mil.attribute5 IS NOT NULL
            AND      mil.segment1 = lr_xwsp_rec.receipt_lct_code
            AND      mil.attribute5 <> lr_xwsp_rec.receipt_lct_code
            AND      mil.attribute5 = mil2.segment1(+)
            ; 
          EXCEPTION 
            WHEN NO_DATA_FOUND THEN
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'when_no_data_found'
          );  
              RAISE no_action_expt;
          END;
          IF (ln_receipt_code IS NULL and lv_receipt_code = cv_org_code) THEN
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'zzzz'
          );  
            ln_receipt_code := NULL;
            lv_receipt_code := NULL;
            BEGIN
              SELECT  xxwfil.frq_item_location_id
                     ,xxwfil.frq_item_location_code
              INTO    ln_receipt_code
                     ,lv_receipt_code
              FROM   xxwsh_frq_item_locations xxwfil
              WHERE  xxwfil.item_location_id         =  lr_xwsp_rec.receipt_lct_id
              AND    xxwfil.item_id                  =  lr_xwsp_rec.item_id
              AND    xxwfil.frq_item_location_code   IS NOT NULL
              AND    xxwfil.frq_item_location_id     IS NOT NULL
              AND    xxwfil.frq_item_location_code   <> lr_xwsp_rec.receipt_lct_code
              ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RAISE no_action_expt;
            END;
--              IF (ln_receipt_code IS NULL) THEN
--                RAISE no_action_expt;
          END IF;
--            END;
--          ELSIF (ln_receipt_code IS NULL) THEN
--            RAISE no_action_expt;  
--          END IF;
--          END;
          lr_xwsp_rec.frq_location_id       := lr_xwsp_rec.receipt_lct_code;
          lr_xwsp_rec.receipt_org_id           := ln_receipt_code;
          lr_xwsp_rec.receipt_lct_code         := lv_receipt_code;
       -- 工場出荷計画ワークテーブル登録処理
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
          ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
          ov_errbuf            =>   lv_errbuf,             --   リターン・コード
          ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
          );
          lr_xwsp_rec.receipt_org_id      := NULL;
          lr_xwsp_rec.receipt_lct_code     := NULL;
          lr_xwsp_rec.frq_location_id     := NULL;
          IF (lv_retcode = cv_status_error) THEN
            RAISE internal_process_expt;
          END IF;
        EXCEPTION
          WHEN no_action_expt THEN
          NULL;
        END;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '代表倉庫存在チェック後' 
          );  
-------------------------------------------------------
        --==============================
        --重複レコードチェック
        --==============================
        BEGIN
        SELECT COUNT(1)
        INTO ln_count_check
        FROM   xxcop_wk_ship_planning  xxwsp
        WHERE xxwsp.transaction_id         = lr_xwsp_rec.transaction_id
        AND   xxwsp.plant_org_id           = lr_xwsp_rec.plant_org_id
        AND   xxwsp.inventory_item_id      = lr_xwsp_rec.inventory_item_id
        AND   xxwsp.product_schedule_date  = lr_xwsp_rec.product_schedule_date
        AND   xxwsp.cnt_ship_org           <> 1
        START WITH
              xxwsp.receipt_org_id = lr_xwsp_rec.receipt_org_id
        CONNECT BY PRIOR
                  xxwsp.ship_org_id = xxwsp.receipt_org_id
        AND PRIOR  xxwsp.cnt_ship_org           <> 1 
         ;
        EXCEPTION
        WHEN nested_loop_expt THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00060
                          ,iv_token_name1  => cv_msg_00060_token_1
                          ,iv_token_value1 => lr_xwsp_rec.receipt_lct_name
                          ,iv_token_name2  => cv_msg_00060_token_2
                          ,iv_token_value2 => lr_xwsp_rec.item_no
                          );
          RAISE internal_process_expt;
        END;
        END LOOP get_plant_ship_loop;
      CLOSE get_plant_ship_cur;
        --ln_org_data_lvl := ln_org_data_lvl + 1;
      END LOOP get_wk_loop;
    CLOSE get_wk_ship_planning_cur;
      IF ln_item_flg = 1 THEN
        ln_org_data_lvl := ln_count_label;
        ln_item_flg := 0;
      ELSE
        EXIT;
      END IF;
    END LOOP lvl_countup_loop;
    --
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END get_base_yokomst;
  /**********************************************************************************
   * Procedure Name   : get_pace_sum
   * Description      : 下位倉庫出荷ペース取得（A-51）
   ***********************************************************************************/
  PROCEDURE get_pace_sum(
    in_receipt_org_id         IN  xxcop_wk_ship_planning.receipt_org_id%TYPE,
    in_plant_org_id           IN  xxcop_wk_ship_planning.plant_org_id%TYPE,
    in_inventory_item_id      IN  xxcop_wk_ship_planning.inventory_item_id%TYPE,
    id_product_schedule_date  IN  xxcop_wk_ship_planning.product_schedule_date%TYPE,
    in_transaction_id         IN  xxcop_wk_ship_planning.transaction_id%TYPE,
    on_undr_lvl_pace          OUT xxcop_wk_ship_planning.under_lvl_pace%TYPE,
    ov_errbuf                 OUT VARCHAR2,              --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,              --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2)              --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_pace_sum'; -- プログラム名
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
    ln_undr_lvl_pace  NUMBER := 0;
    ln_undr_lvl_count NUMBER := 0;
--
    -- *** ローカル・カーソル ***
    --
    CURSOR get_wk_cur IS
      SELECT NVL(xxwsp.shipping_pace,0)  under_lvl_pace
            ,xxwsp.receipt_org_id        receipt_org_id
      FROM   xxcop_wk_ship_planning  xxwsp
        WHERE  xxwsp.ship_org_id        =     in_receipt_org_id
        AND  xxwsp.plant_org_id         =     in_plant_org_id
        AND  xxwsp.inventory_item_id    =     in_inventory_item_id
        AND  xxwsp.product_schedule_date    = id_product_schedule_date
        AND  xxwsp.transaction_id           = in_transaction_id
        AND  xxwsp.org_data_lvl             >= cn_data_lvl_yokomt
        ;
    -- *** ローカル・レコード ***
    get_wk_rec   get_wk_cur%ROWTYPE := NULL;

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
    );
    OPEN get_wk_cur;
    <<get_wk_loop>>
    LOOP
      FETCH get_wk_cur INTO get_wk_rec;
        EXIT WHEN get_wk_cur%NOTFOUND;
      --
        get_pace_sum( in_receipt_org_id         => get_wk_rec.receipt_org_id
                     ,in_plant_org_id           => in_plant_org_id
                     ,in_inventory_item_id      => in_inventory_item_id
                     ,id_product_schedule_date  => id_product_schedule_date
                     ,in_transaction_id         => in_transaction_id
                     ,on_undr_lvl_pace          => ln_undr_lvl_pace
                     ,ov_errbuf                 => lv_errbuf
                     ,ov_retcode                => lv_retcode
                     ,ov_errmsg                 => lv_errmsg
                     );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      ln_undr_lvl_count := ln_undr_lvl_count + ln_undr_lvl_pace + get_wk_rec.under_lvl_pace;
    END LOOP get_wk_loop;
    CLOSE get_wk_cur;
      on_undr_lvl_pace := ln_undr_lvl_count;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END get_pace_sum;
--
  /**********************************************************************************
   * Procedure Name   : get_under_lvl_pace
   * Description      : 出荷ペース取得処理（A-5）
   ***********************************************************************************/
  PROCEDURE get_under_lvl_pace(
    io_xwsp_rec            IN OUT xxcop_wk_ship_planning%ROWTYPE,   --   工場出荷ワークレコードタイプ
    ov_errbuf                OUT VARCHAR2,              --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,              --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)              --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_under_lvl_pace'; -- プログラム名
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
    ln_undr_lvl_pace      NUMBER := 0;        -- 下位倉庫出荷ペース
    ln_under_lvl_count    NUMBER := 0;        -- 計出荷ペース
    ln_receipt_org_id     NUMBER := NULL;     -- 移動先組織ID
--
    -- *** ローカル・カーソル ***
    --ワークテーブル取得カーソル（出力データレベル）
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id             transaction_id
        ,plant_org_id               plant_org_id
        ,product_schedule_date      product_schedule_date
        ,receipt_org_id             receipt_org_id
        ,inventory_item_id          inventory_item_id
        ,shipping_pace              shipping_pace
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      AND   frq_location_id       IS NULL
      ;
    --
    --ワークテーブル取得カーソル(代表倉庫）
    CURSOR get_wk_ship_organization_cur IS
      SELECT 
         transaction_id             transaction_id
        ,plant_org_id               plant_org_id
        ,product_schedule_date      product_schedule_date
        ,receipt_org_id             receipt_org_id
        ,inventory_item_id          inventory_item_id
        ,frq_location_id            frq_location_id
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      AND   frq_location_id       IS NOT NULL
      ;
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
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    <<get_wk_ship_planning_loop>>
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      ln_receipt_org_id := get_wk_ship_planning_rec.receipt_org_id;
      --下位組織情報取得
      get_pace_sum(
                    in_receipt_org_id         => ln_receipt_org_id
                   ,in_plant_org_id           => get_wk_ship_planning_rec.plant_org_id
                   ,in_inventory_item_id      => get_wk_ship_planning_rec.inventory_item_id
                   ,id_product_schedule_date  => get_wk_ship_planning_rec.product_schedule_date
                   ,in_transaction_id         => get_wk_ship_planning_rec.transaction_id
                   ,on_undr_lvl_pace          => ln_undr_lvl_pace
                   ,ov_errbuf                 => lv_errbuf
                   ,ov_retcode                => lv_retcode
                   ,ov_errmsg                 => lv_errmsg
                   );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      --計出荷ペース ＝ （自倉庫出荷ペース ＋ 下位組織情報取得下位倉庫出荷ペース）
      ln_under_lvl_count := (get_wk_ship_planning_rec.shipping_pace + ln_undr_lvl_pace) ;
      BEGIN
        UPDATE xxcop_wk_ship_planning
        SET under_lvl_pace = ln_under_lvl_count
        WHERE plant_org_id = io_xwsp_rec.plant_org_id
        AND   inventory_item_id = io_xwsp_rec.inventory_item_id
        AND   product_schedule_date = io_xwsp_rec.product_schedule_date
        AND   org_data_lvl = cn_data_lvl_output
        AND   transaction_id = io_xwsp_rec.transaction_id
        AND   receipt_org_id = ln_receipt_org_id;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00028
                          ,iv_token_name1  => cv_msg_00028_token_1
                          ,iv_token_value1 => cv_msg_wk_tbl
                        );
          RAISE internal_process_expt;
      END;
    END LOOP get_wk_ship_planning_loop;
    ln_under_lvl_count := NULL;
    <<get_wk_ship_organization_loop>>
    FOR get_wk_ship_organization_rec IN get_wk_ship_organization_cur LOOP
          ln_receipt_org_id := get_wk_ship_organization_rec.receipt_org_id;
      --下位組織情報取得
      get_pace_sum(
                    in_receipt_org_id         => ln_receipt_org_id
                   ,in_plant_org_id           => get_wk_ship_organization_rec.plant_org_id
                   ,in_inventory_item_id      => get_wk_ship_organization_rec.inventory_item_id
                   ,id_product_schedule_date  => get_wk_ship_organization_rec.product_schedule_date
                   ,in_transaction_id         => get_wk_ship_organization_rec.transaction_id
                   ,on_undr_lvl_pace          => ln_undr_lvl_pace
                   ,ov_errbuf                 => lv_errbuf
                   ,ov_retcode                => lv_retcode
                   ,ov_errmsg                 => lv_errmsg
                   );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      --計出荷ペース ＝ 下位組織情報取得下位倉庫出荷ペース
      ln_under_lvl_count := ln_undr_lvl_pace;
      BEGIN
        UPDATE xxcop_wk_ship_planning
        SET under_lvl_pace = under_lvl_pace + ln_under_lvl_count
        WHERE plant_org_id = io_xwsp_rec.plant_org_id
        AND   inventory_item_id = io_xwsp_rec.inventory_item_id
        AND   product_schedule_date = io_xwsp_rec.product_schedule_date
        AND   org_data_lvl = cn_data_lvl_output
        AND   transaction_id = io_xwsp_rec.transaction_id
        AND   receipt_lct_code = get_wk_ship_organization_rec.frq_location_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00028
                          ,iv_token_name1  => cv_msg_00028_token_1
                          ,iv_token_value1 => cv_msg_wk_tbl
                        );
          RAISE internal_process_expt;
      END;
    END LOOP get_wk_ship_organization_loop;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END get_under_lvl_pace;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_qty
   * Description      : 在庫数取得処理（A-6）
   ***********************************************************************************/
  PROCEDURE get_stock_qty(
     io_xwsp_rec            IN OUT xxcop_wk_ship_planning%ROWTYPE   --   工場出荷ワークレコードタイプ
    ,ov_errbuf                OUT VARCHAR2              --   エラー・メッセージ           --# 固定 #
    ,ov_retcode               OUT VARCHAR2              --   リターン・コード             --# 固定 #
    ,ov_errmsg                OUT VARCHAR2)             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_qty'; -- プログラム名
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
    lv_plant_org_id          xxcop_wk_ship_planning.plant_org_id%TYPE := NULL;
    ld_product_schedule_date   xxcop_wk_ship_planning.product_schedule_date%TYPE := NULL;
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
    ld_receipt_date            xxcop_wk_ship_planning.receipt_date%TYPE := NULL;
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
    ln_before_stock            xxcop_wk_ship_planning.before_stock%TYPE := NULL;
    ln_after_stock             xxcop_wk_ship_planning.after_stock%TYPE := NULL;
    ln_num_of_case             xxcop_wk_ship_planning.num_of_case%TYPE := NULL;
    ln_working_days            NUMBER := 0;
    ln_receipt_plan_qty        NUMBER := 0;
    ln_onhand_qty              NUMBER := 0;
    ld_from_date               xxcop_wk_ship_planning.product_schedule_date%TYPE := NULL;
--
    -- *** ローカル・カーソル ***
    --ワークテーブル取得カーソル（出力データレベル）
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id           transaction_id
        ,inventory_item_id        inventory_item_id
        ,item_no                  item_no
        ,item_id                  item_id
        ,product_schedule_date    product_schedule_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
        ,receipt_date             receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
        ,receipt_org_id           receipt_org_id
        ,receipt_org_code         receipt_org_code
        ,receipt_lct_id           receipt_lct_id
        ,under_lvl_pace           under_lvl_pace
        ,plant_org_id             plant_org_id
        ,cnt_ship_org             cnt_ship_org
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      AND   frq_location_id         IS NULL
      ORDER BY product_schedule_date,item_no,plant_org_id;
    --
    -- *** ローカル・レコード ***
    get_wk_ship_planning_rec     get_wk_ship_planning_cur%ROWTYPE := NULL;
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
    );
    <<get_wk_ship_planning_loop>>
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      --変数初期化
      ln_before_stock := NULL;
      --
--      lr_xwsp_rec.transaction_id := get_wk_ship_planning_rec.transaction_id;
--      lr_xwsp_rec.inventory_item_id := get_wk_ship_planning_rec.inventory_item_id;
--      lr_xwsp_rec.receipt_org_id := get_wk_ship_planning_rec.receipt_org_id
--      lr_xwsp_rec.product_schedule_date := get_wk_ship_planning_rec.product_schedule_date
--      lr_xwsp_rec.receipt_org_id := get_wk_ship_planning_rec.receipt_org_id;
--      lr_xwsp_rec.
      -- ===============
      -- 後在庫取得処理
      -- ===============
      BEGIN
        SELECT
           inn_xxwsp.plant_org_id            plant_org_id
          ,inn_xxwsp.product_schedule_date   product_schedule_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
          ,inn_xxwsp.receipt_date            receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
          ,inn_xxwsp.after_stock             after_stock
          ,inn_xxwsp.num_of_case             num_of_case
        INTO
           lv_plant_org_id
          ,ld_product_schedule_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
          ,ld_receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
          ,ln_after_stock
          ,ln_num_of_case
        FROM(
             SELECT
                plant_org_id
               ,product_schedule_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
               ,receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
               ,after_stock
               ,num_of_case
             FROM  xxcop_wk_ship_planning
             WHERE transaction_id = get_wk_ship_planning_rec.transaction_id
               AND org_data_lvl = cn_data_lvl_output
               AND inventory_item_id = get_wk_ship_planning_rec.inventory_item_id
               AND receipt_org_id = get_wk_ship_planning_rec.receipt_org_id
               AND after_stock IS NOT NULL
             ORDER BY product_schedule_date DESC,plant_org_id DESC
             )  inn_xxwsp
        WHERE ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_after_stock := NULL;
      END;
      --後在庫が他倉庫に存在するとき
      IF (ln_after_stock IS NOT NULL) THEN
          --1で取得した生産予定日＞出荷引当済日の場合、
          --共通関数「稼働日数取得処理」より移動先倉庫の稼働日数を取得します。
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--          IF (get_wk_ship_planning_rec.product_schedule_date >  gd_schedule_date) THEN
--            IF (ld_product_schedule_date > gd_schedule_date) THEN
--              ld_from_date := ld_product_schedule_date;
--            ELSIF (ld_product_schedule_date <= gd_schedule_date) THEN
--              ld_from_date := gd_schedule_date;
--            END IF;
          IF (get_wk_ship_planning_rec.receipt_date >  gd_schedule_date) THEN
            IF (ld_receipt_date > gd_schedule_date) THEN
              ld_from_date := ld_receipt_date + 1;
            ELSIF (ld_receipt_date <= gd_schedule_date) THEN
              ld_from_date := gd_schedule_date + 1;
            END IF;
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
            xxcop_common_pkg2.get_working_days(
               iv_calendar_code       =>    io_xwsp_rec.receipt_calendar_code
              ,in_organization_id     =>    NULL
              ,in_loct_id             =>    NULL
              ,id_from_date           =>    ld_from_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--              ,id_to_date             =>    get_wk_ship_planning_rec.product_schedule_date
              ,id_to_date             =>    get_wk_ship_planning_rec.receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
              ,on_working_days        =>    ln_working_days                                   --   稼働日数
              ,ov_errbuf              =>    lv_errmsg        --   ユーザー・エラー・メッセージ
              ,ov_retcode             =>    lv_errbuf        --   エラー・メッセージ
              ,ov_errmsg              =>    lv_retcode       --   リターン・コード
              );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
          --入庫予定取得処理 -- 2009/10/05 入庫予定処理なし（入庫予定数を）
          xxcop_common_pkg2.get_stock_plan(
              in_loct_id        =>   get_wk_ship_planning_rec.receipt_lct_id  --   受入組織ID
             ,in_item_id        =>   get_wk_ship_planning_rec.item_id
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--             ,id_plan_date_from =>   ld_product_schedule_date
--             ,id_plan_date_to   =>   get_wk_ship_planning_rec.product_schedule_date
             ,id_plan_date_from =>   ld_receipt_date + 1
             ,id_plan_date_to   =>   get_wk_ship_planning_rec.receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
             ,on_quantity       =>   ln_receipt_plan_qty
             ,ov_errbuf         =>   lv_errmsg        --   ユーザー・エラー・メッセージ
             ,ov_retcode        =>   lv_errbuf        --   エラー・メッセージ
             ,ov_errmsg         =>   lv_retcode       --   リターン・コード
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
          --取得した稼働日数および入庫予定数より前在庫数を取得します。
          --前在庫数 ＝ 2.で取得の後在庫数 ＋ 入庫予定数 －（1.で取得の下位倉庫出荷ペース＊稼動日数）
          ln_before_stock := ln_after_stock + ln_receipt_plan_qty -
                             (get_wk_ship_planning_rec.under_lvl_pace * ln_working_days);
      --
      --後在庫が存在しないとき
      ELSIF (ln_after_stock IS NULL) THEN
        --
        --手持在庫取得処理
        xxcop_common_pkg2.get_onhand_qty(
           in_loct_id         =>   get_wk_ship_planning_rec.receipt_lct_id          --   受入組織ID
          ,in_item_id         =>   get_wk_ship_planning_rec.item_id                 --   OPM品目ID
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--          ,id_target_date     =>   get_wk_ship_planning_rec.product_schedule_date   --   対象日付
          ,id_target_date     =>   get_wk_ship_planning_rec.receipt_date   --   対象日付
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
          ,id_allocated_date  =>   gd_schedule_date                                 --   引当済日
          ,on_quantity        =>   ln_onhand_qty                                    -- 手持在庫数量
          ,ov_errbuf          =>   lv_errmsg                                  --   ユーザー・エラー・メッセージ
          ,ov_retcode         =>   lv_errbuf                                  --   エラー・メッセージ
          ,ov_errmsg          =>   lv_retcode                                 --   リターン・コード
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        --生産予定日＞出荷引当済日の場合、共通関数「稼働日数取得処理」より移動先倉庫の稼働日数を取得します。
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--        IF (get_wk_ship_planning_rec.product_schedule_date > gd_schedule_date) THEN
        IF (get_wk_ship_planning_rec.receipt_date > gd_schedule_date) THEN
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
          xxcop_common_pkg2.get_working_days(
               iv_calendar_code       =>    io_xwsp_rec.receipt_calendar_code
              ,in_organization_id     =>    NULL
              ,in_loct_id             =>    NULL
              ,id_from_date           =>    gd_schedule_date + 1
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--              ,id_to_date             =>    get_wk_ship_planning_rec.product_schedule_date
              ,id_to_date             =>    get_wk_ship_planning_rec.receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
              ,on_working_days        =>    ln_working_days                                   --   稼働日数
              ,ov_errbuf              =>    lv_errmsg        --   ユーザー・エラー・メッセージ
              ,ov_retcode             =>    lv_errbuf        --   エラー・メッセージ
              ,ov_errmsg              =>    lv_retcode       --   リターン・コード
              );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        ELSE
        --出荷引当済日が生産予定日より未来の場合手持ち在庫数量をそのまま前在庫数とする（通常なし）
          ln_working_days := 0;  
        END IF;
        --
        --取得した稼働日数および入庫予定数より前在庫数を取得します。
        --前在庫数 ＝ 手持在庫数量 －（1.で取得の下位倉庫出荷ペース＊稼動日数）
        ln_before_stock := ln_onhand_qty - (get_wk_ship_planning_rec.under_lvl_pace * ln_working_days);
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '後在庫が他倉庫に存在しない・倉庫ID'||TO_CHAR(get_wk_ship_planning_rec.receipt_org_id)||
                          '対象日付(生産予定日）,'||TO_CHAR(get_wk_ship_planning_rec.product_schedule_date,cv_date_format_slash)||
                          '引当済日,'||TO_CHAR(gd_schedule_date,cv_date_format_slash)||
                          '稼動日'||TO_CHAR(ln_working_days)||
                          '前在庫数'||TO_CHAR(ln_before_stock)||
                          '手持在庫数'||TO_CHAR(ln_onhand_qty)||'-(下位出荷ペース'||TO_CHAR(get_wk_ship_planning_rec.under_lvl_pace)||'*稼動日'||TO_CHAR(ln_working_days)
    );
      END IF;
      -- 前在庫更新
      BEGIN
        UPDATE xxcop_wk_ship_planning
        SET   before_stock = ln_before_stock
        WHERE inventory_item_id         = get_wk_ship_planning_rec.inventory_item_id
        AND   transaction_id            = get_wk_ship_planning_rec.transaction_id
        AND   org_data_lvl              = cn_data_lvl_output
        AND   plant_org_id              = get_wk_ship_planning_rec.plant_org_id
        AND   product_schedule_date     = get_wk_ship_planning_rec.product_schedule_date
        AND   receipt_org_id            = get_wk_ship_planning_rec.receipt_org_id
        AND   before_stock              IS NULL;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00028
                          ,iv_token_name1  => cv_msg_00028_token_1
                          ,iv_token_value1 => cv_msg_wk_tbl
                        );
          RAISE internal_process_expt;
      END;
      io_xwsp_rec.receipt_org_id:= get_wk_ship_planning_rec.receipt_org_id;
    END LOOP get_wk_ship_planning_loop;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END get_stock_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_move_qty
   * Description      : 移動数取得処理（A-7）
   ***********************************************************************************/
  PROCEDURE get_move_qty(
    io_xwsp_rec              IN OUT xxcop_wk_ship_planning%ROWTYPE,   --   工場出荷ワークレコードタイプ
    ov_errbuf                OUT VARCHAR2,              --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,              --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)              --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_move_qty'; -- プログラム名
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
    ln_sum_pace             NUMBER := 0;
    ln_sum_before_stock     NUMBER := 0;
    ln_stock_days           NUMBER := 0;
    ln_stock                NUMBER := 0;
    ln_product_schedule_qty NUMBER := 0;
    ln_move_qty             NUMBER := 0;
    ln_after_stock          NUMBER := 0;
    ln_palette_qty          NUMBER := 0;
    lb_minus_flg            BOOLEAN := TRUE;
    -- *** ローカル・カーソル ***
    --ワークテーブル取得カーソル（出力データレベル）
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id
        ,plant_org_id
        ,inventory_item_id
        ,num_of_case
        ,palette_max_cs_qty
        ,palette_max_step_qty
        ,item_no
        ,item_id
        ,product_schedule_date
        ,receipt_org_id
        ,receipt_org_code
        ,under_lvl_pace
        ,before_stock
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      AND   minus_flg             IS NULL
      AND   frq_location_id       IS NULL
      ORDER BY product_schedule_date,item_no,plant_org_code;
    --
    -- *** ローカル・レコード ***
    lr_xwsp_rec     xxcop_wk_ship_planning%ROWTYPE := NULL;
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
    );
    LOOP
      BEGIN
        lb_minus_flg := TRUE;
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '出荷倉庫:'||io_xwsp_rec.plant_org_id
    );
        --総出荷ペース取得
        --組織データレベル0（工場倉庫）下の組織データレベル1の複数倉庫の出荷ペースと
        --前在庫数を合計します
        SELECT
           product_schedule_qty        --計画数
          ,SUM(NVL(under_lvl_pace,0))  --総出荷ペース
          ,SUM(NVL(before_stock,0))    --総前在庫数
        INTO
           ln_product_schedule_qty
          ,ln_sum_pace
          ,ln_sum_before_stock
        FROM
          xxcop_wk_ship_planning
        WHERE org_data_lvl          = cn_data_lvl_output
        AND   transaction_id        = io_xwsp_rec.transaction_id
        AND   plant_org_id          = io_xwsp_rec.plant_org_id
        AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
        AND   product_schedule_date = io_xwsp_rec.product_schedule_date
        AND   minus_flg             IS NULL
        AND   frq_location_id       IS NULL
        GROUP BY transaction_id,plant_org_id,plant_org_code
                ,inventory_item_id,item_no,product_schedule_date,product_schedule_qty;
        -- 按分計算ゼロチェック
        --組織データレベル0（工場倉庫）の総出荷ペース値が０かNULL値の場合、
        --対象倉庫をスキップ
        IF NVL(ln_sum_pace,0) = 0 THEN
        -- 総出荷ペースゼロ警告メッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00063
                         ,iv_token_name1  => cv_msg_00063_token_1
                         ,iv_token_value1 => io_xwsp_rec.plant_org_id
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          RAISE nested_loop_expt;
        END IF;
        --在庫日数の算出
        IF (ln_sum_pace <> 0) THEN
           --在庫日数(少数点第2位)＝(計画数 + 前在庫数)/下位倉庫出荷ベース
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--          ln_stock_days :=  ROUND(((ln_product_schedule_qty + ln_sum_before_stock) / ln_sum_pace));
          ln_stock_days :=  ROUND(((ln_product_schedule_qty + ln_sum_before_stock) / ln_sum_pace), 2);
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
        ELSE
          ln_stock_days :=  0;  --通常なし
        END IF;
        FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
          --在庫数＝出荷ペース×在庫日数
          ln_stock := get_wk_ship_planning_rec.under_lvl_pace * ln_stock_days;  --出荷ペースが0の場合、在庫数は0になりうる
          --移動数＝在庫数－自倉庫の前在庫数
          IF (ln_stock <> 0) THEN
            ln_move_qty := ln_stock - get_wk_ship_planning_rec.before_stock;
          ELSE 
            ln_move_qty := 0;
           END IF;
  --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
      iov_debug_mode => gv_debug_mode
     ,iv_value       => '計画数='||ln_move_qty
    );
  --
          -- 移動数が0以上（工場倉庫から一倉庫への計画数が0以上で移動が存在する）
          IF (ln_move_qty >= 0) THEN 
          --移動パレット変換＝ケース入数×配数×段数
          ln_palette_qty := get_wk_ship_planning_rec.num_of_case * get_wk_ship_planning_rec.palette_max_cs_qty * get_wk_ship_planning_rec.palette_max_step_qty;
          --移動パレット換算後の計画数
          ln_move_qty :=ln_palette_qty * ROUND(ln_move_qty / ln_palette_qty);
          --後在庫数
          ln_after_stock := ln_move_qty + get_wk_ship_planning_rec.before_stock;
  --
  --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
      iov_debug_mode => gv_debug_mode
     ,iv_value       => '計画数='||ln_move_qty || ',' || '後在庫='||ln_after_stock || ',' || '在庫日数='||ln_stock_days
    );
  --
            BEGIN
              UPDATE xxcop_wk_ship_planning
              SET   schedule_qty = ln_move_qty
                   ,after_stock = ln_after_stock
                   ,stock_days =  ln_stock_days
              WHERE inventory_item_id         = get_wk_ship_planning_rec.inventory_item_id
              AND   transaction_id            = get_wk_ship_planning_rec.transaction_id
              AND   org_data_lvl              = cn_data_lvl_output
              AND   plant_org_id              = get_wk_ship_planning_rec.plant_org_id
              AND   product_schedule_date     = get_wk_ship_planning_rec.product_schedule_date
              AND   receipt_org_id            = get_wk_ship_planning_rec.receipt_org_id
              AND   frq_location_id         IS NULL 
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg :=  xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_appl_cont
                                ,iv_name         => cv_msg_00028
                                ,iv_token_name1  => cv_msg_00028_token_1
                                ,iv_token_value1 => cv_msg_wk_tbl
                              );
                RAISE internal_process_expt;
            END;
          --移動数がマイナス値（一倉庫の前在庫数が工場倉庫の計画数より大きい場合）の場合
          ELSE
            lb_minus_flg := FALSE;
            --移動数
            ln_move_qty   := 0;
            --在庫日数
            ln_stock_days := 0;
            --後在庫
            ln_after_stock := get_wk_ship_planning_rec.before_stock;
            BEGIN
              UPDATE xxcop_wk_ship_planning
              SET   minus_flg    = cv_move_minus_flg_on
                   ,schedule_qty = ln_move_qty
                   ,after_stock  = ln_after_stock
                   ,stock_days   = ln_stock_days
              WHERE inventory_item_id         = get_wk_ship_planning_rec.inventory_item_id
              AND   transaction_id            = get_wk_ship_planning_rec.transaction_id
              AND   org_data_lvl              = cn_data_lvl_output
              AND   plant_org_id              = get_wk_ship_planning_rec.plant_org_id
              AND   product_schedule_date     = get_wk_ship_planning_rec.product_schedule_date
              AND   receipt_org_id            = get_wk_ship_planning_rec.receipt_org_id
              AND   frq_location_id         IS NULL
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg :=  xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_appl_cont
                                ,iv_name         => cv_msg_00028
                                ,iv_token_name1  => cv_msg_00028_token_1
                                ,iv_token_value1 => cv_msg_wk_tbl
                              );
                RAISE internal_process_expt;
            END;
          END IF;
        END LOOP get_wk_ship_planning_cur;
      EXCEPTION
        WHEN nested_loop_expt THEN  
        NULL;
        WHEN NO_DATA_FOUND THEN  --工場出荷制御マスタに基準計画に紐付く倉庫がない場合
        NULL;
      END;
      EXIT WHEN lb_minus_flg;
    END LOOP;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END get_move_qty;
--
  /**********************************************************************************
   * Procedure Name   : insert_wk_output
   * Description      : 工場出荷計画出力ワークテーブル作成（A-8）
   ***********************************************************************************/
  PROCEDURE insert_wk_output(
     in_transaction_id   IN NUMBER
    ,ov_errbuf           OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT VARCHAR2    --   リターン・コード             --# 固定 #
    ,ov_errmsg           OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'insert_wk_output'; -- プログラム名
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
    --ワークテーブルよりデータ抽出
    INSERT INTO xxcop_wk_ship_planning_output(
       transaction_id
      ,shipping_date
      ,receipt_date
      ,ship_org_code
      ,ship_lct_code
      ,ship_org_name
      ,receipt_org_code
      ,receipt_lct_code
      ,receipt_org_name
      ,item_no
      ,item_name
      ,schedule_qty
      ,before_stock
      ,after_stock
      ,stock_days
      ,shipping_pace
      ,plant_mark
      ,schedule_date
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
    SELECT
       transaction_id
      ,shipping_date
      ,receipt_date
      ,ship_org_code
      ,ship_lct_code
      ,ship_org_name
      ,receipt_org_code
      ,receipt_lct_code
      ,receipt_org_name
      ,item_no
      ,item_name
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--      ,product_schedule_qty
--      ,before_stock
--      ,after_stock
--      ,stock_days
--      ,shipping_pace
      ,TRUNC(schedule_qty / num_of_case)
      ,TRUNC(before_stock / num_of_case)
      ,TRUNC(after_stock / num_of_case)
      ,ROUND(stock_days, 2)
      ,ROUND(under_lvl_pace / num_of_case)
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
      ,plant_mark
      ,product_schedule_date
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    FROM
      xxcop_wk_ship_planning
    WHERE org_data_lvl = cn_data_lvl_output
      AND transaction_id = in_transaction_id
      AND frq_location_id         IS NULL 
    ORDER BY ship_org_code,receipt_org_code,item_no,product_schedule_date
    ;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END insert_wk_output;
--
  /**********************************************************************************
   * Procedure Name   : csv_output
   * Description      : 工場出荷計画CSV出力(A-9)
   ***********************************************************************************/
  PROCEDURE csv_output(
     in_transaction_id    IN  NUMBER
    ,ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
    ,ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- 処理結果レポート出力文字列バッファ
    lv_buff  VARCHAR2(5000) := NULL;
--
    -- *** ローカル・カーソル ***
    CURSOR get_csv_output_cur IS
      SELECT
         shipping_date
        ,receipt_date
        ,ship_org_code
        ,ship_lct_code
        ,ship_org_name
        ,receipt_org_code
        ,receipt_lct_code
        ,receipt_org_name
        ,item_no
        ,item_name
        ,schedule_qty
        ,before_stock
        ,after_stock
        ,stock_days
        ,shipping_pace
        ,plant_mark
        ,schedule_date
      FROM
        xxcop_wk_ship_planning_output
      WHERE transaction_id = in_transaction_id
      ORDER BY ship_lct_code,receipt_lct_code,item_no,schedule_date;
--
    -- *** ローカル・レコード ***
    get_csv_output_rec get_csv_output_cur%ROWTYPE;
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
--  ヘッダ情報の抽出
    lv_buff := xxccp_common_pkg.get_msg(                                                            
             iv_application  => cv_msg_appl_cont                                                    -- アプリケーション短縮名
            ,iv_name         => cv_msg_10049                                                        -- メッセージコード
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_others_expt;
    END IF;
    -- タイトル行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_buff
    );
    --
    <<csv_output_loop>>
    FOR get_csv_output_rec IN get_csv_output_cur LOOP
      -- データ行
      lv_buff :=          cv_csv_point || TO_CHAR(get_csv_output_rec.shipping_date,cv_date_format)
        || cv_csv_cont || cv_csv_point || TO_CHAR(get_csv_output_rec.receipt_date,cv_date_format)
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.ship_org_code
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.ship_lct_code
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.ship_org_name
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.receipt_org_code
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.receipt_lct_code
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.receipt_org_name
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.item_no
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.item_name
        || cv_csv_cont || get_csv_output_rec.schedule_qty
        || cv_csv_cont || get_csv_output_rec.before_stock
        || cv_csv_cont || get_csv_output_rec.after_stock
        || cv_csv_cont || get_csv_output_rec.stock_days
        || cv_csv_cont || get_csv_output_rec.shipping_pace
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.plant_mark
        || cv_csv_cont || cv_csv_point || TO_CHAR(get_csv_output_rec.schedule_date,cv_date_format)
        ;
      -- データ行出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_buff
      );
      --
      -- 正常件数加算
      gn_normal_cnt := gn_normal_cnt + 1;
      --
    END LOOP csv_output_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END csv_output;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_plan_from     IN    VARCHAR2    --   1.計画立案期間（FROM）
    ,iv_plan_to       IN    VARCHAR2    --   2.計画立案期間（TO）
    ,iv_pace_type     IN    VARCHAR2    --   3.対象出荷区分
    ,iv_pace_from     IN    VARCHAR2    --   4.出荷ペース計画期間（FROM）
    ,iv_pace_to       IN    VARCHAR2    --   5.出荷ペース計画期間（TO）
    ,iv_forcast_from  IN    VARCHAR2    --   6.出荷予測期間（FROM)
    ,iv_forcast_to    IN    VARCHAR2    --   7.出荷予測期間（TO）
    ,iv_schedule_date IN    VARCHAR2    --   8.出荷引当済日
    ,ov_errbuf        OUT   VARCHAR2    --   エラー・メッセージ           --# 固定 #
    ,ov_retcode       OUT   VARCHAR2    --   リターン・コード             --# 固定 #
    ,ov_errmsg        OUT   VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
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
--###########################  固定部 END  ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_loop_cnt   NUMBER := 0;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --計画立案期間FROM、TOに対して、基準計画名、基準計画日付よりデータを取得します。
    CURSOR get_schedule_cur IS
      SELECT
         msdate.organization_id        plant_org_id                   --工場倉庫
        ,msdate.inventory_item_id      inventory_item_id              --在庫品目ID
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
        ,msdate.schedule_date          schedule_date                  --計画日付
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
        ,NVL(TO_DATE(msdate.attribute5,cv_date_format_slash), msdate.schedule_date)  product_schedule_date  --生産予定日
        ,mp.organization_code          plant_org_code                 --工場倉庫コード
        ,SUM(msdate.schedule_quantity) product_schedule_qty           --計画数量
      FROM
         mrp_schedule_designators  msdesi                             --基準計画名テーブル
        ,mrp_schedule_dates        msdate                             --基準計画日付テーブル
        ,mtl_parameters            mp                                 --組織パラメータ
      WHERE  msdate.schedule_designator =  msdesi.schedule_designator
        AND  msdate.organization_id     =  msdesi.organization_id
        AND  msdate.schedule_date      >=  gd_plan_from
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--        AND  msdate.schedule_date      <   gd_plan_to
        AND  msdate.schedule_date      <=  gd_plan_to
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
        AND  msdesi.attribute1          =  cv_buy_type
        AND  msdate.organization_id     =  mp.organization_id
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
        AND  msdate.schedule_level      =  cn_schedule_level
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
      GROUP BY
         msdate.organization_id                                                     --工場倉庫ID
        ,msdate.inventory_item_id                                                   --在庫品目ID
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
        ,msdate.schedule_date                                                       --計画日付
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
        ,NVL(TO_DATE(msdate.attribute5,cv_date_format_slash), msdate.schedule_date) --計画日付
        ,mp.organization_code                                                       --組織コード
      ORDER BY product_schedule_date, inventory_item_id, plant_org_id
      ;
    -- *** ローカル・レコード ***
    lr_xwsp_rec          xxcop_wk_ship_planning%ROWTYPE := NULL;
    -- *** ローカル例外 ***
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    --      A-1 初期処理
    -- ===============================
    init(
       iv_plan_from     =>      iv_plan_from        --   1.計画立案期間（FROM）
      ,iv_plan_to       =>      iv_plan_to          --   2.計画立案期間（TO）
      ,iv_pace_type     =>      iv_pace_type        --   3.対象出荷区分
      ,iv_pace_from     =>      iv_pace_from        --   4.出荷ペース計画期間（FROM）
      ,iv_pace_to       =>      iv_pace_to          --   5.出荷ペース計画期間（TO）
      ,iv_forcast_from  =>      iv_forcast_from     --   6.出荷予測期間（FROM)
      ,iv_forcast_to    =>      iv_forcast_to       --   7.出荷予測期間（TO）
      ,iv_schedule_date =>      iv_schedule_date    --   8.出荷引当済日
      ,ov_errbuf        =>      lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       =>      lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        =>      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;
    <<Base_loop>>
    FOR get_schedule_rec IN get_schedule_cur LOOP
      --対象件数
      gn_target_cnt := gn_target_cnt + 1;
      --変数初期化
      lr_xwsp_rec := NULL;
      --処理行数カウント
      ln_loop_cnt := ln_loop_cnt + 1;
      --工場出荷ワークレコードセット
      lr_xwsp_rec.transaction_id          := cn_request_id;                         -- 要求ID
      lr_xwsp_rec.org_data_lvl            := cn_data_lvl_plant;                     -- 組織データレベル
      lr_xwsp_rec.inventory_item_id       := get_schedule_rec.inventory_item_id;    -- 在庫品目ID
      lr_xwsp_rec.plant_org_id            := get_schedule_rec.plant_org_id;         -- 工場組織ID
      lr_xwsp_rec.ship_org_id             := get_schedule_rec.plant_org_id;         -- 移動元組織ID
      lr_xwsp_rec.product_schedule_date   := get_schedule_rec.product_schedule_date;-- 生産予定日
      lr_xwsp_rec.product_schedule_qty    := get_schedule_rec.product_schedule_qty; -- 生産計画数
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--      lr_xwsp_rec.shipping_date           := get_schedule_rec.product_schedule_date;-- 出荷日
      lr_xwsp_rec.shipping_date           := get_schedule_rec.schedule_date;        -- 出荷日
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
      --
      BEGIN
  --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
      iov_debug_mode => gv_debug_mode
     ,iv_value       => '対象組織'||lr_xwsp_rec.plant_org_id
    );
  --
        -- =============================================
        --      A-2 基準生産計画取得
        -- =============================================
        get_schedule_date(
          io_xwsp_rec          =>   lr_xwsp_rec      --   工場出荷ワークレコードタイプ
         ,ov_errmsg            =>   lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
         ,ov_errbuf            =>   lv_errbuf        -- エラー・メッセージ           --# 固定 #
         ,ov_retcode           =>   lv_retcode       -- リターン・コード             --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
          RAISE expt_next_record;
        END IF;
        -- =============================================
        --      A-3 工場出荷計画制御マスタ情報取得
        -- =============================================
        get_plant_shipping(
           io_xwsp_rec          =>   lr_xwsp_rec      --   工場出荷ワークレコードタイプ
          ,ov_errbuf            =>   lv_errbuf        -- ユーザー・エラー・メッセージ --# 固定 #
          ,ov_retcode           =>   lv_retcode        -- エラー・メッセージ           --# 固定 #
          ,ov_errmsg            =>   lv_errmsg       -- リターン・コード             --# 固定 #
          );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
          RAISE expt_next_record;
        END IF;
        -- ===============================================
        --      A-4 基本横持制御マスター情報取得処理
        -- ===============================================
        --基本横持制御マスタ取得処理
        get_base_yokomst(
          io_xwsp_rec          =>   lr_xwsp_rec      --   工場出荷ワークレコードタイプ
         ,ov_errmsg            =>   lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
         ,ov_errbuf            =>   lv_errbuf        -- エラー・メッセージ           --# 固定 #
         ,ov_retcode           =>   lv_retcode       -- リターン・コード             --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
        -- =============================================
        --      A-5 下位倉庫出荷ペース取得
        -- =============================================
        --下位倉庫出荷ペース取得処理
        get_under_lvl_pace(
          io_xwsp_rec          =>   lr_xwsp_rec      --   工場出荷ワークレコードタイプ
         ,ov_errmsg            =>   lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
         ,ov_errbuf            =>   lv_errbuf        -- エラー・メッセージ           --# 固定 #
         ,ov_retcode           =>   lv_retcode       -- リターン・コード             --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
        -- =============================================
        --      A-6 在庫数取得
        -- =============================================
        --在庫数取得処理
        get_stock_qty(
          io_xwsp_rec          =>   lr_xwsp_rec      --   工場出荷ワークレコードタイプ
         ,ov_errmsg            =>   lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
         ,ov_errbuf            =>   lv_errbuf        -- エラー・メッセージ           --# 固定 #
         ,ov_retcode           =>   lv_retcode       -- リターン・コード             --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
        -- =============================================
        --      A-7 移動数取得
        -- =============================================
        --移動数取得処理
        get_move_qty(
          io_xwsp_rec          =>   lr_xwsp_rec      --   工場出荷ワークレコードタイプ
         ,ov_errmsg            =>   lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
         ,ov_errbuf            =>   lv_errbuf        -- エラー・メッセージ           --# 固定 #
         ,ov_retcode           =>   lv_retcode       -- リターン・コード             --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
      EXCEPTION
        WHEN expt_next_record THEN
          NULL;
      END;
    END LOOP Base_loop;
    --
    IF (ln_loop_cnt = 0) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00003      --対象データなし
                   );
      RAISE internal_process_expt;
    END IF;
    -- =============================================
    --     A-8 工場出荷計画出力ワークテーブル作成
    -- =============================================
    insert_wk_output(
      cn_request_id
     ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                           -- リターン・コード             --# 固定 #
     ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00027
                     ,iv_token_name1  => cv_msg_00027_token_1
                     ,iv_token_value1 => cv_msg_wk_tbl_output
                   );
      RAISE internal_process_expt;
    END IF;
    -- =============================================
    --     A-9 工場出荷計画CSV出力
    -- =============================================
    csv_output(
      cn_request_id
     ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                           -- リターン・コード             --# 固定 #
     ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;
    -- 警告メッセージを出力した場合、警告終了で戻す
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
    WHEN internal_process_expt THEN
      --カーソルクローズ
      IF (get_schedule_cur%ISOPEN = TRUE) THEN
        CLOSE get_schedule_cur;
      END IF;
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
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      --カーソルクローズ
      IF (get_schedule_cur%ISOPEN = TRUE) THEN
        CLOSE get_schedule_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --カーソルクローズ
      IF (get_schedule_cur%ISOPEN = TRUE) THEN
        CLOSE get_schedule_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --カーソルクローズ
      IF (get_schedule_cur%ISOPEN = TRUE) THEN
        CLOSE get_schedule_cur;
      END IF;
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
    ,iv_plan_from                  IN  VARCHAR2         --   1.計画立案期間（FROM）
    ,iv_plan_to                    IN  VARCHAR2         --   2.計画立案期間（TO）
    ,iv_pace_type                  IN  VARCHAR2         --   3.対象出荷区分
    ,iv_pace_from                  IN  VARCHAR2         --   4.出荷ペース計画期間（FROM）
    ,iv_pace_to                    IN  VARCHAR2         --   5.出荷ペース計画期間（TO）
    ,iv_forcast_from               IN  VARCHAR2         --   6.出荷予測期間（FROM)
    ,iv_forcast_to                 IN  VARCHAR2         --   7.出荷予測期間（TO）
    ,iv_schedule_date              IN  VARCHAR2         --   8.出荷引当済日
  )
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
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- エラー終了 一部完了メッセージ
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
       iv_plan_from     =>       iv_plan_from     --   1.計画立案期間（FROM）
      ,iv_plan_to       =>       iv_plan_to       --   2.計画立案期間（TO）
      ,iv_pace_type     =>       iv_pace_type     --   3.対象出荷区分
      ,iv_pace_from     =>       iv_pace_from     --   4.出荷ペース計画期間（FROM）
      ,iv_pace_to       =>       iv_pace_to       --   5.出荷ペース計画期間（TO）
      ,iv_forcast_from  =>       iv_forcast_from  --   6.出荷予測期間（FROM)
      ,iv_forcast_to    =>       iv_forcast_to    --   7.出荷予測期間（TO）
      ,iv_schedule_date =>       iv_schedule_date --   8.出荷引当済日
      ,ov_errbuf        =>       lv_errbuf        --   エラー・メッセージ           --# 固定 #
      ,ov_retcode       =>       lv_retcode       --   リターン・コード             --# 固定 #
      ,ov_errmsg        =>       lv_errmsg        --   ユーザー・エラー・メッセージ --# 固定 #
      );

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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
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
    --終了ステータスがエラーの場合はCOMMITする
    IF (retcode = cv_status_error) THEN
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      COMMIT;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      COMMIT;
  END main;
END XXCOP005A01C;
/
