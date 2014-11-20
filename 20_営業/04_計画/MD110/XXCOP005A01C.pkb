create or replace PACKAGE BODY      XXCOP005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP005A01C(body)
 * Description      : 工場出荷計画
 * MD.050           : 工場出荷計画 MD050_COP_005_A01
 * Version          : 1.3
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
 *  get_cnt_from_org       親倉庫件数取得処理(A-31)
 *  get_plant_shipping     工場出荷計画制御マスタ取得（A-3）
 *  get_base_yokomst       基本横持ち制御マスタ取得（A-4）
 *  get_under_lvl_pace     下位倉庫出荷ペース取得処理（A-5）
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
  param_invalid_expt        EXCEPTION;     -- 入力パラメータチェックエラー
  internal_process_expt     EXCEPTION;     -- 内部PROCEDURE/FUNCTIONエラーハンドリング用
  date_invalid_expt         EXCEPTION;     -- 日付チェックエラー
  past_date_invalid_expt    EXCEPTION;     -- 過去日チェックエラー
  expt_next_record          EXCEPTION;     -- レコードスキップ用
  resource_busy_expt        EXCEPTION;     -- デッドロックエラー
  reverse_invalid_expt      EXCEPTION;     -- 日付逆転エラー
  profile_validate_expt     EXCEPTION;     -- プロファイル取得エラー
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
  item_status_expt          EXCEPTION;     -- 品目ステータス不正警告メッセージ
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END

  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOP005A01C';
  --プログラム実行日時
  cd_sys_date                   CONSTANT DATE        := TRUNC(SYSDATE);                    --プログラム実行日時
  -- 入力パラメータログ出力用
  cv_plan_type_tl               CONSTANT VARCHAR2(100) := '計画区分';
  cv_pace_from_tl               CONSTANT VARCHAR2(100) := '出荷ペース計画期間FROM';
  cv_pace_to_tl                 CONSTANT VARCHAR2(100) := '出荷ペース計画期間TO';
  cv_forcast_type_tl            CONSTANT VARCHAR2(100) := '出荷予測区分';
  cv_pm_part                    CONSTANT VARCHAR2(6)   := ' : ';
  --メッセージ共通
  cv_msg_appl_cont              CONSTANT VARCHAR2(100) := 'XXCOP';                 -- アプリケーション短縮名
  --メッセージ名
  cv_msg_00002     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';      -- プロファイル値取得失敗
  cv_msg_00055     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00055';      -- パラメータエラーメッセージ
  cv_msg_00011     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00011';      -- DATE型チェックエラーメッセージ
  cv_msg_00025     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';      -- 値逆転エラーメッセージ
  cv_msg_00047     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';      -- 未来日メッセージ
  cv_msg_00053     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00053';      -- 配送リードタイム取得エラー
  cv_msg_00056     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00056';      -- 設定期間中稼働日チェックエラーメッセージ
  cv_msg_00057     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00057';      -- 配送単位取得エラーメッセージ
  cv_msg_00049     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00049';      -- 品目情報取得エラー
  cv_msg_00050     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00050';      -- 組織情報取得エラー
  cv_msg_00058     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00058';      -- 按分ゼロ計算不正エラーメッセージ
  cv_msg_00059     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00059';      -- 配送単位ゼロエラー
  cv_msg_00042     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';      -- 削除処理エラー
  cv_msg_10025     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10025';      -- 工場固有記号取得エラー
  cv_msg_00060     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00060';      -- 経路情報ループエラーメッセージ
  cv_msg_00003     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';      -- 対象データなし
  cv_msg_00027     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';      -- 登録処理エラーメッセージ
  cv_msg_00061     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00061';      -- ケース入数不正メッセージ
  cv_msg_00028     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00028';      -- 更新処理エラーメッセージ
  cv_msg_00062     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00062';      -- 経路エラーメッセージ
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
  cv_msg_10042     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10042';      -- 経路エラーメッセージ
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
  -- メッセージ関連
  cv_msg_application            CONSTANT VARCHAR2(100) := 'XXCOP';
  cv_others_err_msg             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';
  cv_others_err_msg_tkn_lbl1    CONSTANT VARCHAR2(100) := 'ERRMSG';
  --メッセージトークン
  cv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
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
  cv_msg_00057_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00058_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME1';
  cv_msg_00058_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NAME2';
  cv_msg_00059_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
--20090407_Ver1.2_T1_0281_SCS_Uda_MOD_START
--  cv_msg_10025_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
--  cv_msg_10025_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10025_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10025_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
--20090407_Ver1.2_T1_0281_SCS_Uda_MOD_END
  cv_msg_00060_token_1      CONSTANT VARCHAR2(100) := 'WHSE_NAME';
  cv_msg_00061_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00062_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00027_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00028_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
  cv_msg_10042_token_1      CONSTANT VARCHAR2(100) := 'ORG_CODE';
  cv_msg_10042_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10042_token_3      CONSTANT VARCHAR2(100) := 'DATE';
  cv_msg_10042_token_4      CONSTANT VARCHAR2(100) := 'STATUS';
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
--
  --メッセージトークン値
  cv_msg_unit_delivery      CONSTANT VARCHAR2(100) := '配送単位';
  cv_msg_wk_tbl             CONSTANT VARCHAR2(100) := '物流計画ワークテーブル';
  cv_msg_wk_tbl_output      CONSTANT VARCHAR2(100) := '工場出荷計画出力ワークテーブル';
  cv_msg_stock_dates        CONSTANT VARCHAR2(100) := '在庫日数';
  cv_msg_item               CONSTANT VARCHAR2(100) := '品目';
  cv_msg_item_name          CONSTANT VARCHAR2(100) := '　品目名';
  cv_msg_org_name           CONSTANT VARCHAR2(100) := '　倉庫名';
  cv_msg_stock_days         CONSTANT VARCHAR2(100) := '在庫日数';
  cv_msg_sum_pace           CONSTANT VARCHAR2(100) := '総出荷ペース';
  cv_msg_palette            CONSTANT VARCHAR2(100) := '配数';
  cv_msg_move_qty           CONSTANT VARCHAR2(100) := '移動数';
  cv_msg_wk_output          CONSTANT VARCHAR2(100) := '出力ワークテーブル';
--
  --項目のサイズ
  cv_column_len_01          CONSTANT NUMBER := 30;                              -- 割当セット名
  cv_column_len_02          CONSTANT NUMBER := 80;                              -- 割当セット摘要
  cv_column_len_03          CONSTANT NUMBER := 1;                               -- 割当セット区分
  cv_column_len_04          CONSTANT NUMBER := 1;                               -- 割当先タイプ
  cv_column_len_05          CONSTANT NUMBER := 3;                               -- 組織コード
  cv_column_len_06          CONSTANT NUMBER := 7;                               -- 品目コード
  cv_column_len_07          CONSTANT NUMBER := 1;                               -- 物流構成表/ソースルールタイプ
  cv_column_len_08          CONSTANT NUMBER := 30;                              -- 物流構成表/ソースルールタイプ名
  cv_column_len_09          CONSTANT NUMBER := 1;                               -- 削除フラグ
  cv_column_len_10          CONSTANT NUMBER := 1;                               -- 出荷区分
  cv_column_len_11          CONSTANT NUMBER := 2;                               -- 鮮度条件
  --必須判定
  cv_must_item              CONSTANT VARCHAR2(4) := 'MUST';                     -- 必須項目
  cv_null_item              CONSTANT VARCHAR2(4) := 'NULL';                     -- NULL項目
  cv_any_item               CONSTANT VARCHAR2(4) := 'ANY';                      -- 任意項目
  --日付型フォーマット
  cv_date_format            CONSTANT VARCHAR2(8)   := 'YYYYMMDD';               -- 年月日
  cv_date_format_slash      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';             -- 年/月/日
  cv_datetime_format        CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';  -- 年月日時分秒(24時間表記)
  cv_month_format           CONSTANT VARCHAR2(8)   := 'MM';                     -- 精度指定子(月)
  --割当セット区分
  cv_base_plan              CONSTANT VARCHAR2(1)   := '1';                      -- 基本横持計画
  cv_custom_plan            CONSTANT VARCHAR2(1)   := '2';                      -- 特別横持計画
  cv_factory_ship_plan      CONSTANT VARCHAR2(1)   := '3';                      -- 工場出荷計画
  --割当先タイプ
  cv_global                 CONSTANT NUMBER        := 1;                        -- グローバル
  cv_item                   CONSTANT NUMBER        := 3;                        -- 品目
  cv_organization           CONSTANT NUMBER        := 4;                        -- 組織
  cv_item_organization      CONSTANT NUMBER        := 6;                        -- 品目-組織
  --ソースルールタイプ
  cv_source_rule            CONSTANT NUMBER        := 1;                        -- ソースルール
  cv_mrp_sourcing_rule      CONSTANT NUMBER        := 2;                        -- 物流構成表
  --翌週取得用コンスタント
  cv_sunday                 CONSTANT VARCHAR2(100)        := '日';              -- 翌週開始日取得用
  cv_saturday               CONSTANT VARCHAR2(100)        := '土';              -- 翌週終了日取得用
  --プロファイル取得
  cv_master_org_id          CONSTANT VARCHAR2(20)  := 'XXCMN_MASTER_ORG_ID';           -- プロファイル取得用 マスタ組織
  cv_profile_name_mo_id     CONSTANT VARCHAR2(20)  := 'マスタ組織';                    -- プロファイル名 マスタ組織
  --クイックコードタイプ
  cv_assign_type_priority   CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';   -- 割当先タイプ優先度
  cv_assign_name            CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';        -- 割当セット名
  cv_flv_language           CONSTANT VARCHAR2(100) := USERENV('LANG');                 -- 言語
  cv_flv_enabled_flg_y      CONSTANT VARCHAR2(100) := 'Y';
--
  --入力パラメータ
  cv_buy_type               CONSTANT VARCHAR2(1)   := '3';                      -- 基準計画分類（購入計画）
  cv_plan_type_pace         CONSTANT VARCHAR2(100) := '1';                      -- 出荷ペース
  cv_plan_type_fgorcate     CONSTANT VARCHAR2(100) := '2';                      -- 出荷予測
  cv_forcast_type_this      CONSTANT VARCHAR2(100) := '1';                      -- 当月分
  cv_forcast_type_next      CONSTANT VARCHAR2(100) := '2';                      -- 翌月分
  cv_forcast_type_2month    CONSTANT VARCHAR2(100) := '3';                      -- 当月＋翌月分
--
--
  cn_schedule_level         CONSTANT NUMBER        := 2;                        -- 基準計画レベル（レベル２）
  cv_own_flg_on             CONSTANT VARCHAR2(1)   := '1';                      -- 自工場対象フラグYes
  cn_inactive_ind           CONSTANT NUMBER        := 1;                        -- 無効チェックあり
  cv_inv_status_code_inactive CONSTANT VARCHAR2(100) := 'Inactive';             -- 無効
  cv_obsolete_class         CONSTANT VARCHAR2(1)   := '1';                      -- 廃止チェックあり
  cn_del_mark_n             CONSTANT NUMBER        := 0;                        -- 有効
  cn_active_ind_y           CONSTANT NUMBER        := 1;                        -- 有効
  cn_active_ind_n           CONSTANT NUMBER        := 0;                        -- 無効
  cv_ship_plan_type         CONSTANT VARCHAR2(1)   := '1';                      -- 基準計画分類（出荷予測）
  cv_plant_ship_type        CONSTANT VARCHAR2(1)   := '2';                      -- 基準計画分類（工場出荷計画）
  cv_code_class             CONSTANT VARCHAR2(1)   := '4';                      -- 配送リードタイムコードクラス（倉庫）
  cv_plan_typep             CONSTANT VARCHAR2(1)   := '1';                      -- 計画区分（出荷ペース）
  cv_plan_typef             CONSTANT VARCHAR2(1)   := '2';                      -- 計画区分（出荷予測）
  cn_data_lvl_plant         CONSTANT NUMBER        := 0;                        -- 組織データレベル(工場レベル)
  cn_data_lvl_output        CONSTANT NUMBER        := 1;                        -- 組織データレベル(工場出荷レベル)
--20090407_Ver1.2_T1_0368_SCS.Uda_ADD_START
  --DISC品目アドオンマスタ
  cn_xsib_status_temporary  CONSTANT NUMBER := 20;                              -- 仮登録
  cn_xsib_status_registered CONSTANT NUMBER := 30;                              -- 本登録
  cn_xsib_status_obsolete   CONSTANT NUMBER := 40;                              -- 廃
--20090407_Ver1.2_T1_0368_SCS.Uda_ADD_END
  -- CSV出力用
  cv_csv_part                   CONSTANT VARCHAR2(1)   := '"';
  cv_csv_cont                   CONSTANT VARCHAR2(1)   := ',';
  cv_csv_header1                CONSTANT VARCHAR2(100) := '出荷日';
  cv_csv_header2                CONSTANT VARCHAR2(100) := '着日';
  cv_csv_header3                CONSTANT VARCHAR2(100) := '移動元倉庫ＣＤ';
  cv_csv_header4                CONSTANT VARCHAR2(100) := '移動元倉庫名';
  cv_csv_header5                CONSTANT VARCHAR2(100) := '移動先倉庫ＣＤ';
  cv_csv_header6                CONSTANT VARCHAR2(100) := '移動先倉庫名';
  cv_csv_header7                CONSTANT VARCHAR2(100) := '品目ＣＤ';
  cv_csv_header8                CONSTANT VARCHAR2(100) := '品目名';
  cv_csv_header9                CONSTANT VARCHAR2(100) := '計画数';
  cv_csv_header10               CONSTANT VARCHAR2(100) := '前在庫';
  cv_csv_header11               CONSTANT VARCHAR2(100) := '後在庫';
  cv_csv_header12               CONSTANT VARCHAR2(100) := '在庫日数';
  cv_csv_header13               CONSTANT VARCHAR2(100) := '出荷ペース';
  cv_csv_header14               CONSTANT VARCHAR2(100) := '工場固有記号';
  cv_csv_header15               CONSTANT VARCHAR2(100) := '生産予定日';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ格納用変数
  gv_plan_type                   VARCHAR2(1);              -- 1.計画区分
  gd_pace_from                   DATE;                     -- 2.出荷ペース(実績)期間FROM
  gd_pace_to                     DATE;                     -- 3.出荷ペース（実績）期間TO
  gv_forcast_type                VARCHAR2(1);              -- 4.出荷予測期間
  gd_forcast_from                DATE;                     -- 出荷予測期間FROM
  gd_forcast_to                  DATE;                     -- 出荷予測期間TO
  gn_pace_days                   NUMBER;                   -- 出荷実績稼働日数
  gn_forcast_days                NUMBER;                   -- 出荷予測稼働日数
--
  gn_under_lvl_pace              NUMBER := 0;              -- 下位倉庫出荷ペース
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
--
    -- *** ローカル・レコード ***
    TYPE rowid_ttype IS TABLE OF rowid INDEX BY BINARY_INTEGER;
    lr_rowid         rowid_ttype;
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
    );
    -- ===============================
    -- 工場出荷計画ワークテーブル
    -- ===============================
    BEGIN
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
    END;
--
    -- ===============================
    -- 工場出荷計画出力ワークテーブル
    -- ===============================
    BEGIN
      --ロックの取得
      SELECT xwspo.ROWID
      BULK COLLECT INTO lr_rowid
      FROM xxcop_wk_ship_planning_output xwspo
      FOR UPDATE NOWAIT;
      --データ削除
      DELETE FROM xxcop_wk_ship_planning_output;
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        NULL;
    END;
--
  EXCEPTION
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
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_plan_type     IN     VARCHAR2,   -- 1.計画区分
    iv_shipment_from IN     VARCHAR2,   -- 2.出荷ペース計画期間(FROM)
    iv_shipment_to   IN     VARCHAR2,   -- 3.出荷ペース計画期間(TO)
    iv_forcast_type  IN     VARCHAR2,   -- 4.出荷予測区分
    ov_errbuf        OUT   VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT   VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg        OUT   VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
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
    lb_chk_value         BOOLEAN;         -- 日付型フォーマットチェック結果
    lv_invalid_value     VARCHAR2(100);   -- エラーメッセージ値
    lv_profile_name      VARCHAR2(100);   -- プロファイル名
    lv_value             VARCHAR2(100);   -- プロファイル値
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
    );
    --空白行を挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    --入力パラメータの出力
    --計画区分
    lv_errmsg := cv_plan_type_tl || cv_msg_part || iv_plan_type;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --出荷ペース計画期間(FROM)
    lv_errmsg := cv_pace_from_tl || cv_msg_part || iv_shipment_from;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --出荷ペース計画期間(TO)
    lv_errmsg := cv_pace_to_tl || cv_msg_part || iv_shipment_to;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --出荷予測区分
    lv_errmsg := cv_forcast_type_tl || cv_msg_part || iv_forcast_type;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --空白行を挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    lv_value := fnd_profile.value( cv_master_org_id );
    IF ( lv_value IS NULL ) THEN
      lv_profile_name := cv_profile_name_mo_id;
      RAISE profile_validate_expt;
    END IF;
    --入力パラメータチェック
    --計画区分
    IF ( iv_plan_type = cv_plan_type_pace ) THEN
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
    --出荷ペース計画期間(FROM)
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_shipment_from
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := iv_shipment_from;
      RAISE date_invalid_expt;
    END IF;
    gd_pace_from := TO_DATE( iv_shipment_from, cv_date_format_slash );
    --出荷ペース計画期間(TO)
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_shipment_to
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := iv_shipment_to;
      RAISE date_invalid_expt;
    END IF;
    gd_pace_to := TO_DATE( iv_shipment_to, cv_date_format_slash );
    --出荷ペース計画期間(FROM)-出荷ペース計画期間(TO)逆転チェック
    IF ( gd_pace_from >= gd_pace_to ) THEN
      RAISE reverse_invalid_expt;
    END IF;
    --出荷ペース計画期間(FROM)過去日チェック
    IF ( gd_pace_from > cd_sys_date ) THEN
      lv_invalid_value := cv_pace_from_tl;
      RAISE past_date_invalid_expt;
    END IF;
    --出荷ペース計画期間(TO)過去日チェック
    IF ( gd_pace_to > cd_sys_date ) THEN
      lv_invalid_value := cv_pace_to_tl;
      RAISE past_date_invalid_expt;
    END IF;
    --出荷予測期間の取得
    IF ( iv_forcast_type = cv_forcast_type_this ) THEN
      --当月
      gd_forcast_from := TRUNC( cd_sys_date, cv_month_format );
      gd_forcast_to   := LAST_DAY( cd_sys_date );
    ELSIF ( iv_forcast_type = cv_forcast_type_next ) THEN
      --翌月
      gd_forcast_from := ADD_MONTHS( TRUNC( cd_sys_date, cv_month_format ), 1 );
      gd_forcast_to   := LAST_DAY( ADD_MONTHS( cd_sys_date, 1 ) );
    ELSIF ( iv_forcast_type = cv_forcast_type_2month ) THEN
      --当月+翌月
      gd_forcast_from := TRUNC( cd_sys_date, cv_month_format );
      gd_forcast_to   := LAST_DAY( ADD_MONTHS( cd_sys_date, 1 ) );
    ELSE
      --NULL
      gd_forcast_from := NULL;
      gd_forcast_to   := NULL;
    END IF;
    --
  -- ワークテーブルデータ削除
    delete_table(
            ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
           ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
           ,ov_retcode         =>   lv_retcode       --   リターン・コード
    );
    IF lv_retcode = cv_status_error THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00042
                     ,iv_token_name1  => cv_msg_00042_token_1
                     ,iv_token_value1 =>cv_msg_wk_tbl || '、' || cv_msg_wk_tbl_output
                   );
      lv_retcode := cv_status_error;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN profile_validate_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00002
                     ,iv_token_name1  => cv_msg_00002_token_1
                     ,iv_token_value1 => lv_profile_name
                   );
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
                     ,iv_token_value1 => cv_pace_from_tl
                     ,iv_token_name2  => cv_msg_00025_token_2
                     ,iv_token_value2 => cv_pace_to_tl
                   );
      ov_retcode := cv_status_error;
    WHEN past_date_invalid_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00047
                     ,iv_token_name1  => cv_msg_00047_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
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
   * Procedure Name   : get_plant_mark
   * Description      : 工場固有記号取得処理（A-21）
   ***********************************************************************************/
  PROCEDURE get_plant_mark(
    io_xwsp_rec            IN OUT XXCOP_WK_SHIP_PLANNING%ROWTYPE,    --   工場出荷ワークレコードタイプ
    ov_errbuf                OUT VARCHAR2,                                  --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                                  --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                                  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_plant_mark'; -- プログラム名
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
    --工場固有記号取得処理取得
    BEGIN
      SELECT ffmb.attribute6
      INTO   io_xwsp_rec.plant_mark
      FROM   fm_matl_dtl      fmd
         ,   fm_form_mst_b  ffmb
      WHERE  fmd.formula_id = ffmb.formula_id
      AND    fmd.item_id = io_xwsp_rec.item_id
      AND    ffmb.attribute6 is not null
      AND    ROWNUM = 1
      ;
    EXCEPTION
      --既存データがない場合
      WHEN NO_DATA_FOUND THEN
        ov_retcode := cv_status_warn;
    END;
--
  EXCEPTION
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
  END get_plant_mark;
--
  /**********************************************************************************
   * Procedure Name   : insert_wk_tbl
   * Description      : ワークテーブルデータ登録(A-22)
   ***********************************************************************************/
  PROCEDURE insert_wk_tbl(
    ir_xwsp_rec         IN  xxcop_wk_ship_planning%ROWTYPE,    --   工場出荷ワークレコードタイプ
    ov_errbuf           OUT VARCHAR2,                           --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,                           --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)                           --   ユーザー・エラー・メッセージ --# 固定 #
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
        ,prod_class_code
        ,num_of_case
        ,palette_max_cs_qty
        ,palette_max_step_qty
        ,product_schedule_date
        ,product_schedule_qty
        ,ship_org_id
        ,ship_org_code
        ,ship_org_name
        ,ship_org_forcast_stock
        ,ship_org_onhand_qty
        ,receipt_org_id
        ,receipt_org_code
        ,receipt_org_name
        ,receipt_org_forcast_stock
        ,receipt_org_onhand_qty
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
        ,set_qty
        ,movement_qty
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
        ,ir_xwsp_rec.prod_class_code
        ,ir_xwsp_rec.num_of_case
        ,ir_xwsp_rec.palette_max_cs_qty
        ,ir_xwsp_rec.palette_max_step_qty
        ,ir_xwsp_rec.product_schedule_date
        ,ir_xwsp_rec.product_schedule_qty
        ,ir_xwsp_rec.ship_org_id
        ,ir_xwsp_rec.ship_org_code
        ,ir_xwsp_rec.ship_org_name
        ,ir_xwsp_rec.ship_org_forcast_stock
        ,ir_xwsp_rec.ship_org_onhand_qty
        ,ir_xwsp_rec.receipt_org_id
        ,ir_xwsp_rec.receipt_org_code
        ,ir_xwsp_rec.receipt_org_name
        ,ir_xwsp_rec.receipt_org_forcast_stock
        ,ir_xwsp_rec.receipt_org_onhand_qty
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
        ,ir_xwsp_rec.set_qty
        ,ir_xwsp_rec.movement_qty
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
    ln_organization_id    hr_all_organization_units.organization_id%TYPE;
    lv_organization_code  mtl_parameters.organization_code%TYPE;
    lv_organization_name  ic_whse_mst.whse_name%TYPE;
    lv_whse_code          ic_whse_mst.whse_code%TYPE;
    ln_product_schedule_qty  xxcop_wk_ship_planning.product_schedule_qty%TYPE;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
    ln_item_status        xxcmm_system_items_b.item_status%TYPE;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
--20090414_Ver1.2_T1_0542_SCS_Uda_ADD_START
    ln_item_code          xxcmm_system_items_b.item_code%TYPE;
--20090414_Ver1.2_T1_0542_SCS_Uda_ADD_END
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
--20090414_Ver1.2_T1_0542_SCS_Uda_ADD_START
    --組織情報取得処理
    xxcop_common_pkg2.get_org_info(
      in_organization_id     =>   io_xwsp_rec.plant_org_id,  --   組織ID
      ov_organization_code   =>   lv_organization_code,      --   組織コード
      ov_whse_name           =>   lv_organization_name,      --   倉庫名
      ov_errmsg              =>   lv_errmsg,                 --   エラー・メッセージ
      ov_errbuf              =>   lv_errbuf,                 --   リターン・コード
      ov_retcode             =>   lv_retcode                 --   ユーザー・エラー・メッセージ
      );
    IF lv_retcode = cv_status_error THEN
      RAISE global_api_expt;
    ELSIF lv_retcode = cv_status_warn THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00050
                      ,iv_token_name1  => cv_msg_00050_token_1
                      ,iv_token_value1 => io_xwsp_rec.plant_org_id
                    );
      RAISE internal_process_expt;
    END IF;
    --
    -- 工場出荷ワーク組織情報セット
    io_xwsp_rec.ship_org_id         := io_xwsp_rec.plant_org_id;  -- 出荷組織ID
    io_xwsp_rec.plant_org_code      := lv_organization_code;      -- 工場組織コード
    io_xwsp_rec.ship_org_code       := lv_organization_code;      -- 出荷組織コード
    io_xwsp_rec.plant_org_name      := lv_organization_name;      -- 工場組織名称
    io_xwsp_rec.ship_org_name       := lv_organization_name;      -- 出荷組織名称
    --
    --品目ステータス取得処理
    SELECT xsib.item_status,msib.segment1
    INTO   ln_item_status,ln_item_code
    FROM  xxcmm_system_items_b  xsib
         ,mtl_system_items_b    msib
    WHERE xsib.item_status_apply_date     <= cd_sys_date
    AND   xsib.item_code                   = msib.segment1
    AND   msib.inventory_item_id           = io_xwsp_rec.inventory_item_id
    AND   msib.organization_id             = to_number(fnd_profile.value(cv_master_org_id));
    IF ln_item_status NOT IN (cn_xsib_status_temporary,cn_xsib_status_registered,cn_xsib_status_obsolete) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_10042
                      ,iv_token_name1  => cv_msg_10042_token_1
                      ,iv_token_value1 => io_xwsp_rec.plant_org_code
                      ,iv_token_name2  => cv_msg_10042_token_2
                      ,iv_token_value2 => ln_item_code
                      ,iv_token_name3  => cv_msg_10042_token_3
                      ,iv_token_value3 => TO_CHAR(io_xwsp_rec.product_schedule_date,cv_date_format_slash)
                      ,iv_token_name4  => cv_msg_10042_token_4
                      ,iv_token_value4 => TO_CHAR(ln_item_status)
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      RAISE item_status_expt;
    END IF;
--20090414_Ver1.2_T1_0542_SCS_Uda_ADD_END
    --品目情報取得処理
    xxcop_common_pkg2.get_item_info(
       in_inventory_item_id  =>   io_xwsp_rec.inventory_item_id  --   在庫品目ID
      ,on_item_id            =>   io_xwsp_rec.item_id            --   OPM品目ID
      ,ov_item_no            =>   io_xwsp_rec.item_no            --   OPM品目コード
      ,ov_item_name          =>   io_xwsp_rec.item_name          --   OPM品目名
      ,ov_prod_class_code    =>   io_xwsp_rec.prod_class_code    --   商品区分
      ,on_num_of_case        =>   io_xwsp_rec.num_of_case        --   ケース入数
      ,ov_errbuf             =>   lv_errbuf                      --   エラー・メッセージ           --# 固定 #
      ,ov_retcode            =>   lv_retcode                     --   リターン・コード             --# 固定 #
      ,ov_errmsg             =>   lv_errmsg                      --   ユーザー・エラー・メッセージ
    );
    --
    IF lv_retcode = cv_status_error THEN
      RAISE global_api_expt;
    ELSIF lv_retcode = cv_status_warn THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00049
                      ,iv_token_name1  => cv_msg_00049_token_1
                      ,iv_token_value1 => io_xwsp_rec.inventory_item_id
                    );
      RAISE internal_process_expt;
    END IF;
    --
    IF NVL(io_xwsp_rec.num_of_case,0) = 0 THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00061
                      ,iv_token_name1  => cv_msg_00061_token_1
                      ,iv_token_value1 => io_xwsp_rec.item_no || cv_msg_item_name || cv_pm_part || io_xwsp_rec.item_name
                    );
      RAISE internal_process_expt;
    END IF;
    ln_product_schedule_qty := io_xwsp_rec.product_schedule_qty ;
    --
--20090414_Ver1.2_T1_0542_SCS_Uda_DEL_START
--    --組織情報取得処理
--    xxcop_common_pkg2.get_org_info(
--      in_organization_id     =>   io_xwsp_rec.plant_org_id,  --   組織ID
--      ov_organization_code   =>   lv_organization_code,      --   組織コード
--      ov_whse_name           =>   lv_organization_name,      --   倉庫名
--      ov_errmsg              =>   lv_errmsg,                 --   エラー・メッセージ
--      ov_errbuf              =>   lv_errbuf,                 --   リターン・コード
--      ov_retcode             =>   lv_retcode                 --   ユーザー・エラー・メッセージ
--      );
--    IF lv_retcode = cv_status_error THEN
--      RAISE global_api_expt;
--    ELSIF lv_retcode = cv_status_warn THEN
--      lv_errmsg :=  xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_appl_cont
--                      ,iv_name         => cv_msg_00050
--                      ,iv_token_name1  => cv_msg_00050_token_1
--                      ,iv_token_value1 => io_xwsp_rec.plant_org_id
--                    );
--      RAISE internal_process_expt;
--    END IF;
--    --
--    -- 工場出荷ワーク組織情報セット
--    io_xwsp_rec.ship_org_id         := io_xwsp_rec.plant_org_id;  -- 出荷組織ID
--    io_xwsp_rec.plant_org_code      := lv_organization_code;      -- 工場組織コード
--    io_xwsp_rec.ship_org_code       := lv_organization_code;      -- 出荷組織コード
--    io_xwsp_rec.plant_org_name      := lv_organization_name;      -- 工場組織名称
--    io_xwsp_rec.ship_org_name       := lv_organization_name;      -- 出荷組織名称
--    --
----20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
--    SELECT item_status
--    INTO   ln_item_status
--    FROM  xxcmm_system_items_b
--    WHERE item_status_apply_date     <= cd_sys_date
--    AND   item_id                     = io_xwsp_rec.item_id;
--    IF ln_item_status NOT IN (cn_xsib_status_temporary,cn_xsib_status_registered,cn_xsib_status_obsolete) THEN
--      lv_errmsg :=  xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_appl_cont
--                      ,iv_name         => cv_msg_10042
--                      ,iv_token_name1  => cv_msg_10042_token_1
--                      ,iv_token_value1 => io_xwsp_rec.plant_org_code
--                      ,iv_token_name2  => cv_msg_10042_token_2
--                      ,iv_token_value2 => io_xwsp_rec.item_no
--                      ,iv_token_name3  => cv_msg_10042_token_3
--                      ,iv_token_value3 => TO_CHAR(io_xwsp_rec.product_schedule_date,cv_date_format_slash)
--                      ,iv_token_name4  => cv_msg_10042_token_4
--                      ,iv_token_value4 => TO_CHAR(ln_item_status)
--                    );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errmsg
--      );
--      RAISE item_status_expt;
--    END IF;
----20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
--20090414_Ver1.2_T1_0542_SCS_Uda_DEL_END
    -- 組織品目チェック処理
    xxcop_common_pkg2.chk_item_exists(
       in_inventory_item_id => io_xwsp_rec.inventory_item_id
      ,in_organization_id   => io_xwsp_rec.ship_org_id
      ,ov_errbuf            => lv_errbuf
      ,ov_retcode           => lv_retcode
      ,ov_errmsg            => lv_errmsg
    );
    IF lv_retcode = cv_status_error THEN
      RAISE global_api_expt;
    ELSIF lv_retcode = cv_status_warn THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00050
                      ,iv_token_name1  => cv_msg_00050_token_1
                      ,iv_token_value1 => io_xwsp_rec.plant_org_id
                    );
      RAISE internal_process_expt;
    END IF;
    -- 工場固有記号取得
    get_plant_mark(
      io_xwsp_rec          =>   io_xwsp_rec,  --   工場出荷ワークレコードタイプ
      ov_errmsg            =>   lv_errmsg,    --   エラー・メッセージ
      ov_errbuf            =>   lv_errbuf,    --   リターン・コード
      ov_retcode           =>   lv_retcode    --   ユーザー・エラー・メッセージ
      );
    IF lv_retcode = cv_status_error THEN
      RAISE global_api_expt;
    ELSIF lv_retcode = cv_status_warn THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_10025
--20090407_Ver1.2_T1_0281_SCS_Uda_MOD_START
--                      ,iv_token_name1  => cv_msg_10025_token_1
--                      ,iv_token_value1 => io_xwsp_rec.plant_org_code || cv_msg_org_name || cv_pm_part || io_xwsp_rec.plant_org_name
                      ,iv_token_name1  => cv_msg_10025_token_1
                      ,iv_token_value1 => io_xwsp_rec.item_no
                      ,iv_token_name2  => cv_msg_10025_token_2
                      ,iv_token_value2 => io_xwsp_rec.item_name
--20090407_Ver1.2_T1_0281_SCS_Uda_MOD_END
                    );
      RAISE internal_process_expt;
    END IF;
    -- 配送単位取得処理
    xxcop_common_pkg2.get_unit_delivery(
       in_item_id               =>   io_xwsp_rec.item_id                --   OPM品目ID
      ,id_ship_date             =>   io_xwsp_rec.product_schedule_date  --   生産予定日
      ,on_palette_max_cs_qty    =>   io_xwsp_rec.palette_max_cs_qty     --   配数
      ,on_palette_max_step_qty  =>   io_xwsp_rec.palette_max_step_qty   --   段数
      ,ov_errmsg                =>   lv_errmsg                          --   エラー・メッセージ
      ,ov_errbuf                =>   lv_errbuf                          --   リターン・コード
      ,ov_retcode               =>   lv_retcode                         --   ユーザー・エラー・メッセージ
    );
    IF lv_retcode = cv_status_error THEN
      RAISE global_api_expt;
    ELSIF lv_retcode = cv_status_warn THEN
      --エラーメッセージ出力
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00057
                      ,iv_token_name1  => cv_msg_00057_token_1
                      ,iv_token_value1 => cv_msg_item || cv_pm_part || io_xwsp_rec.item_no || cv_msg_item_name || cv_pm_part ||io_xwsp_rec.item_name
                    );
      RAISE internal_process_expt;
    END IF;
    --配送単位ゼロエラー
    IF io_xwsp_rec.palette_max_cs_qty = 0 OR io_xwsp_rec.palette_max_step_qty = 0 THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00059
                      ,iv_token_name1  => cv_msg_00059_token_1
                      ,iv_token_value1 => io_xwsp_rec.item_no || cv_msg_item_name || cv_pm_part ||io_xwsp_rec.item_name
                    );
      RAISE internal_process_expt;
    END IF;
    --
    -- 工場出荷計画ワークテーブル登録処理
    insert_wk_tbl(
      ir_xwsp_rec          =>   io_xwsp_rec,           --   工場出荷ワークレコードタイプ
      ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
      ov_errbuf            =>   lv_errbuf,             --   リターン・コード
      ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
      );
    IF lv_retcode = cv_status_error THEN
      RAISE internal_process_expt;
    END IF;
    --
  EXCEPTION
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
    WHEN item_status_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
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
  END get_schedule_date;
--
--
  /**********************************************************************************
   * Function Name    : get_cnt_from_org
   * Description      : 親倉庫件数取得処理(A-31)
   ***********************************************************************************/
  FUNCTION get_cnt_from_org(
    in_inventory_item_id     IN NUMBER,
    in_organization_id       IN NUMBER,
--    id_product_schedule_date IN DATE,
    ov_errbuf                OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
    RETURN NUMBER IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cnt_from_org'; -- プログラム名
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
    ln_cnt_factory_plan NUMBER := 0;
    ln_cnt_base_plan    NUMBER := 0;
    on_count_from_org   NUMBER := 0;
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
    --経路情報取得カーソル(受入→出荷)
    --工場出荷制御マスタ親件数取得
    SELECT COUNT(source_organization_id)
    INTO ln_cnt_factory_plan
    FROM(
      SELECT
        inventory_item_id                                                   --在庫品目ID
       ,organization_id                                                     --組織ID
       ,source_organization_id                                              --出荷組織
       ,receipt_organization_id                                             --受入組織
       ,own_flg                                                             --自倉庫フラグ
       ,ship_plan_type                                                      --出荷計画区分
       ,yusen                                                               --割当先優先度
       ,row_number
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
              AND    mas.attribute1               = cv_factory_ship_plan   --工場出荷計画
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = in_inventory_item_id     --入力項目の組織品目id
              OR     msa.inventory_item_id        IS NULL)
              AND    msro.receipt_organization_id  = in_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)  >= cd_sys_date
              AND    flv.lookup_code              = to_char(msa.assignment_type)
              AND    flv.language                 = cv_flv_language)
        )
      )
      WHERE row_number <= 1
    );
    --基本横持ち制御マスタ親件数取得
    SELECT COUNT(source_organization_id)
    INTO ln_cnt_base_plan
    FROM(
      SELECT
        inventory_item_id                                                   --在庫品目ID
       ,organization_id                                                     --組織ID
       ,source_organization_id                                              --出荷組織
       ,receipt_organization_id                                             --受入組織
       ,own_flg                                                             --自倉庫フラグ
       ,ship_plan_type                                                      --出荷計画区分
       ,yusen                                                               --割当先優先度
       ,row_number
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
              AND    mas.attribute1               = cv_base_plan           --基本横持ち計画
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = in_inventory_item_id     --入力項目の組織品目id
              OR     msa.inventory_item_id        IS NULL)
              AND    msro.receipt_organization_id  = in_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)  >= cd_sys_date
              AND    flv.lookup_code              = to_char(msa.assignment_type)
              AND    flv.language                 = cv_flv_language)
        )
      )
      WHERE row_number <= 1
    );
    on_count_from_org := ln_cnt_base_plan + ln_cnt_factory_plan;
    RETURN on_count_from_org;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      RETURN 0;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      RETURN 0;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      RETURN 0;
--
--#####################################  固定部 END   ##########################################
--
  END get_cnt_from_org;
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
    ln_organization_id    hr_all_organization_units.organization_id%TYPE;
    ln_inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE;
    lv_organization_code  mtl_parameters.organization_code%TYPE;
    lv_organization_name  ic_whse_mst.whse_name%TYPE;
    lv_whse_code          ic_whse_mst.whse_code%TYPE;
    ln_after_stock        xxcop_wk_ship_planning.after_stock%TYPE;
    ln_sum_of_pace        NUMBER := 0;
    ln_cnt_from_org       NUMBER := 0;
    ln_own_flg_cnt        NUMBER := 0;
    ld_product_schedule_date        DATE := NULL;
    ln_pace_days          NUMBER := 0;
    ln_forcast_days       NUMBER := 0;
    ln_loop_cnt           NUMBER := 0;
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
       ,inventory_item_id
       ,item_id
       ,item_no
       ,item_name
       ,prod_class_code
       ,num_of_case
       ,palette_max_cs_qty
       ,palette_max_step_qty
       ,product_schedule_date
       ,product_schedule_qty
       ,ship_org_id
       ,ship_org_code
       ,ship_org_name
       ,shipping_date
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_plant
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_code
      ;
    --経路情報取得カーソル(出荷→受入)
    CURSOR get_plant_ship_cur IS
      SELECT
        inventory_item_id                                                   --在庫品目ID
       ,organization_id                                                     --組織ID
       ,source_organization_id                                              --出荷組織
       ,receipt_organization_id                                             --受入組織
       ,own_flg                                                             --自倉庫フラグ
       ,ship_plan_type                                                      --出荷計画区分
       ,yusen                                                               --割当先優先度
       ,row_number
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
              AND    mas.attribute1               = cv_factory_ship_plan   --工場出荷計画
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id     --入力項目の組織品目id
              OR     msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = ln_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)  >= cd_sys_date
              AND    flv.lookup_code              = to_char(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
            )
          ) keiro,
          (
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
              AND    mas.attribute1               = cv_factory_ship_plan
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id
              OR     msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = to_number(fnd_profile.value(cv_master_org_id))
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag             = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)         >= cd_sys_date
              AND    flv.lookup_code              = TO_CHAR(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_START
              ORDER BY yusen
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_END
            )
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_START
            WHERE ROWNUM = 1
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_END
          ) dummy
          WHERE keiro.receipt_organization_id = NVL(dummy.organization_id(+),keiro.receipt_organization_id)
        )
      )
      WHERE row_number <= 1
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
      --
      --変数初期化
      lr_xwsp_rec := NULL;
      ln_loop_cnt := 0;
      ln_own_flg_cnt := 0;
      --
      --工場出荷ワークレコードセット
      lr_xwsp_rec.transaction_id           := get_wk_ship_planning_rec.transaction_id;         --工場出荷計画WorkテーブルID
      lr_xwsp_rec.org_data_lvl             := cn_data_lvl_output;                              --組織データレベル
      lr_xwsp_rec.plant_org_id             := get_wk_ship_planning_rec.plant_org_id;           --工場組織
      lr_xwsp_rec.plant_org_code           := get_wk_ship_planning_rec.plant_org_code;         --工場倉庫コード
      lr_xwsp_rec.plant_org_name           := get_wk_ship_planning_rec.plant_org_name;         --工場倉庫名
      lr_xwsp_rec.plant_mark               := get_wk_ship_planning_rec.plant_mark;             --工場固有記号
      lr_xwsp_rec.inventory_item_id        := get_wk_ship_planning_rec.inventory_item_id;      --在庫品目ID
      lr_xwsp_rec.item_id                  := get_wk_ship_planning_rec.item_id;                --OPM品目ID
      lr_xwsp_rec.item_no                  := get_wk_ship_planning_rec.item_no;                --品目コード
      lr_xwsp_rec.item_name                := get_wk_ship_planning_rec.item_name;              --品目名称
      lr_xwsp_rec.prod_class_code          := get_wk_ship_planning_rec.prod_class_code;        --商品区分
      lr_xwsp_rec.num_of_case              := get_wk_ship_planning_rec.num_of_case;            --ケース入数
      lr_xwsp_rec.palette_max_cs_qty       := get_wk_ship_planning_rec.palette_max_cs_qty;     --配数
      lr_xwsp_rec.palette_max_step_qty     := get_wk_ship_planning_rec.palette_max_step_qty;   --段数
      lr_xwsp_rec.product_schedule_date    := get_wk_ship_planning_rec.product_schedule_date;  --生産予定日
      lr_xwsp_rec.product_schedule_qty     := get_wk_ship_planning_rec.product_schedule_qty;   --生産計画数
      lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.ship_org_id;            --移動元組織
      lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.ship_org_code;          --移動元倉庫コード
      lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.ship_org_name;          --移動元倉庫名
      lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.shipping_date;          --出荷日
      --
      --カーソル変数代入
      ln_organization_id   := lr_xwsp_rec.ship_org_id;
      ln_inventory_item_id := lr_xwsp_rec.inventory_item_id;
      --
      --工場出荷計画制御マスタより受入組織データ抽出（出荷→受入）
      <<get_plant_ship_loop>>
      FOR get_plant_ship_rec IN get_plant_ship_cur LOOP
        ln_loop_cnt := ln_loop_cnt + 1;
        --ループ変数セット
        lr_xwsp_rec.receipt_org_id          := get_plant_ship_rec.receipt_organization_id;
        lr_xwsp_rec.own_flg                 := get_plant_ship_rec.own_flg;
        lr_xwsp_rec.shipping_type           := get_plant_ship_rec.ship_plan_type;
        --===================================
        --受入組織情報取得処理
        --===================================
        xxcop_common_pkg2.get_org_info(
          in_organization_id     =>   get_plant_ship_rec.receipt_organization_id,  --   組織ID
          ov_organization_code   =>   lv_organization_code,                        --   組織コード
          ov_whse_name           =>   lv_organization_name,                        --   倉庫名
          ov_errmsg              =>   lv_errmsg,                                   --   エラー・メッセージ
          ov_errbuf              =>   lv_errbuf,                                   --   リターン・コード
          ov_retcode             =>   lv_retcode                                   --   ユーザー・エラー・メッセージ
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        ELSIF lv_retcode = cv_status_warn THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00050
                          ,iv_token_name1  => cv_msg_00050_token_1
                          ,iv_token_value1 => get_plant_ship_rec.receipt_organization_id
                        );
          RAISE internal_process_expt;
        END IF;
        --
        -- 工場出荷ワーク受入組織情報セット
        lr_xwsp_rec.receipt_org_id      := get_plant_ship_rec.receipt_organization_id;  -- 受入組織ID
        lr_xwsp_rec.receipt_org_code    := lv_organization_code;                        -- 受入組織コード
        lr_xwsp_rec.receipt_org_name    := lv_organization_name;                        -- 受入組織名称
        --
        --===================================
        -- 配送リードタイム取得処理
        --===================================
        xxcop_common_pkg2.get_deliv_lead_time(
           iv_from_org_code     =>   lr_xwsp_rec.ship_org_code          --   出荷組織コード
          ,iv_to_org_code       =>   lr_xwsp_rec.receipt_org_code       --   受入組織コード
          ,id_product_date      =>   lr_xwsp_rec.product_schedule_date  --   生産予定日
          ,on_delivery_lt       =>   lr_xwsp_rec.delivery_lead_time     --   配送リードタイム
          ,ov_errmsg            =>   lv_errmsg                          --   エラー・メッセージ
          ,ov_errbuf            =>   lv_errbuf                          --   リターン・コード
          ,ov_retcode           =>   lv_retcode                         --   ユーザー・エラー・メッセージ
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        ELSIF lv_retcode = cv_status_warn THEN
          --エラーメッセージ出力
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00053
                          ,iv_token_name1  => cv_msg_00053_token_1
                          ,iv_token_value1 => lr_xwsp_rec.ship_org_code
                          ,iv_token_name2  => cv_msg_00053_token_2
                          ,iv_token_value2 => lr_xwsp_rec.receipt_org_code
                        );
          RAISE internal_process_expt;
        END IF;
        --
        --着日計算
        IF NVL(lr_xwsp_rec.delivery_lead_time,0) <> 0 THEN
          lr_xwsp_rec.receipt_date := lr_xwsp_rec.shipping_date + lr_xwsp_rec.delivery_lead_time;
        ELSE
          lr_xwsp_rec.receipt_date := lr_xwsp_rec.shipping_date;
          lr_xwsp_rec.delivery_lead_time := 0;
        END IF;
        --===================================
        -- 自倉庫出荷ペース取得処理
        --===================================
        IF ( gv_plan_type IS NULL AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep)
          OR
           ( gv_plan_type = cv_plan_typep AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep) THEN
          --出荷実績取得処理
          xxcop_common_pkg2.get_num_of_shipped(
              iv_organization_code =>   lr_xwsp_rec.receipt_org_code  --   受入組織コード
             ,iv_item_no           =>   lr_xwsp_rec.item_no           --   OPM品目コード
             ,id_plan_date_from    =>   gd_pace_from                  --   出荷ペース(実績)期間FROM
             ,id_plan_date_to      =>   gd_pace_to                    --   出荷ペース（実績）期間TO
             ,on_quantity          =>   ln_sum_of_pace                --   総出荷実績数
             ,ov_errmsg            =>   lv_errmsg                     --   エラー・メッセージ
             ,ov_errbuf            =>   lv_errbuf                     --   リターン・コード
             ,ov_retcode           =>   lv_retcode                    --   ユーザー・エラー・メッセージ
          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          END IF;
          --  出荷実績稼働日数取得
          xxcop_common_pkg2.get_working_days(
              in_organization_id =>   lr_xwsp_rec.receipt_org_id  --   受入組織ID
             ,id_from_date       =>   gd_pace_from
             ,id_to_date         =>   gd_pace_to
             ,on_working_days    =>   ln_pace_days
             ,ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
             ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
             ,ov_retcode         =>   lv_retcode       --   リターン・コード
          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          END IF;
          IF ln_pace_days = 0 THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00056
                           ,iv_token_name1  => cv_msg_00056_token_1
                           ,iv_token_value1 => gd_pace_from
                           ,iv_token_name2  => cv_msg_00056_token_2
                           ,iv_token_value2 => gd_pace_to
                         );
            RAISE internal_process_expt;
          END IF;
          IF ln_sum_of_pace <> 0 AND ln_pace_days <> 0 THEN
            lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace / ln_pace_days);         --自倉庫出荷ペース算出
          ELSE
            lr_xwsp_rec.shipping_pace := 0;
          END IF;
          --
        ELSIF
          ( gv_plan_type IS NULL
            AND
            NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typef
          )
          OR
          ( gv_plan_type = cv_plan_typef
            AND
            NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typef
          ) THEN
          --出荷予測取得処理
          xxcop_common_pkg2.get_num_of_forcast(
              in_organization_id   =>   lr_xwsp_rec.receipt_org_id,    --   受入組織コード
              in_inventory_item_id =>   lr_xwsp_rec.inventory_item_id, --   OPM品目コード
              id_plan_date_from    =>   gd_forcast_from,               --   出荷ペース(実績)期間FROM
              id_plan_date_to      =>   gd_forcast_to,                 --   出荷ペース（実績）期間TO
              on_quantity          =>   ln_sum_of_pace,                --   総出荷実績数
              ov_errmsg            =>   lv_errmsg,                     --   エラー・メッセージ
              ov_errbuf            =>   lv_errbuf,                     --   リターン・コード
              ov_retcode           =>   lv_retcode                     --   ユーザー・エラー・メッセージ
          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          END IF;
          --  出荷予測稼働日数取得
          xxcop_common_pkg2.get_working_days(
              in_organization_id =>   lr_xwsp_rec.receipt_org_id   --   受入組織ID
             ,id_from_date       =>   gd_forcast_from
             ,id_to_date         =>   gd_forcast_to
             ,on_working_days    =>   ln_forcast_days
             ,ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
             ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
             ,ov_retcode         =>   lv_retcode       --   リターン・コード
          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          END IF;
          IF ln_forcast_days = 0 THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00056
                           ,iv_token_name1  => cv_msg_00056_token_1
                           ,iv_token_value1 => gd_pace_from
                           ,iv_token_name2  => cv_msg_00056_token_2
                           ,iv_token_value2 => gd_pace_to
                         );
            RAISE internal_process_expt;
          END IF;
          IF ln_sum_of_pace <> 0 AND ln_forcast_days <> 0 THEN
            lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace / ln_forcast_days);         --自倉庫出荷ペース算出
          ELSE
            lr_xwsp_rec.shipping_pace := 0;
          END IF;
        ELSE
          --入力パラメータの設定と異なるので0をセット
          lr_xwsp_rec.shipping_pace := 0;
        END IF;
        --===================================
        --親組織件数取得処理
        --===================================
        ln_cnt_from_org := get_cnt_from_org(
                              in_inventory_item_id     => lr_xwsp_rec.inventory_item_id
                             ,in_organization_id       => lr_xwsp_rec.receipt_org_id
                             ,ov_errbuf                => lv_errmsg
                             ,ov_retcode               => lv_errbuf
                             ,ov_errmsg                => lv_retcode
                           );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        lr_xwsp_rec.cnt_ship_org := ln_cnt_from_org;
        --
        --工場出荷計画ワークテーブル登録処理
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
          ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
          ov_errbuf            =>   lv_errbuf,             --   リターン・コード
          ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
          );
        IF lv_retcode = cv_status_error THEN
          RAISE internal_process_expt;
        END IF;
        --自倉庫対象フラグYesの場合
        IF lr_xwsp_rec.own_flg = cv_own_flg_on
        AND ln_own_flg_cnt = 0 THEN
          ln_own_flg_cnt                       := ln_own_flg_cnt + 1;
          lr_xwsp_rec.transaction_id           := get_wk_ship_planning_rec.transaction_id;         --工場出荷計画WorkテーブルID
          lr_xwsp_rec.org_data_lvl             := cn_data_lvl_output;                              --組織データレベル
          lr_xwsp_rec.plant_org_id             := get_wk_ship_planning_rec.plant_org_id;           --工場組織
          lr_xwsp_rec.plant_org_code           := get_wk_ship_planning_rec.plant_org_code;         --工場倉庫コード
          lr_xwsp_rec.plant_org_name           := get_wk_ship_planning_rec.plant_org_name;         --工場倉庫名
          lr_xwsp_rec.inventory_item_id        := get_wk_ship_planning_rec.inventory_item_id;      --在庫品目ID
          lr_xwsp_rec.item_id                  := get_wk_ship_planning_rec.item_id;                --OPM品目ID
          lr_xwsp_rec.item_no                  := get_wk_ship_planning_rec.item_no;                --品目コード
          lr_xwsp_rec.item_name                := get_wk_ship_planning_rec.item_name;              --品目名称
          lr_xwsp_rec.prod_class_code          := get_wk_ship_planning_rec.prod_class_code;        --商品区分
          lr_xwsp_rec.num_of_case              := get_wk_ship_planning_rec.num_of_case;            --ケース入数
          lr_xwsp_rec.product_schedule_date    := get_wk_ship_planning_rec.product_schedule_date;  --生産予定日
          lr_xwsp_rec.palette_max_cs_qty       := get_wk_ship_planning_rec.palette_max_cs_qty;     --配数
          lr_xwsp_rec.palette_max_step_qty     := get_wk_ship_planning_rec.palette_max_step_qty;   --段数
          lr_xwsp_rec.product_schedule_qty     := get_wk_ship_planning_rec.product_schedule_qty;   --生産計画数
          lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.ship_org_id;            --移動元組織
          lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.ship_org_code;          --移動元倉庫コード
          lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.ship_org_name;          --移動元倉庫名
          lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.shipping_date;          --出荷日
          lr_xwsp_rec.receipt_org_id           := get_wk_ship_planning_rec.ship_org_id;            --移動元組織
          lr_xwsp_rec.receipt_org_code         := get_wk_ship_planning_rec.ship_org_code;          --移動元倉庫コード
          lr_xwsp_rec.receipt_org_name         := get_wk_ship_planning_rec.ship_org_name;          --移動元倉庫名
          lr_xwsp_rec.receipt_date             := get_wk_ship_planning_rec.shipping_date;          --出荷日
          lr_xwsp_rec.shipping_type            := gv_plan_type;                                    --出荷計画区分
          lr_xwsp_rec.delivery_lead_time       := 0;                                               --配送リードタイム
          --
          --===================================
          -- 自倉庫出荷ペース取得処理
          --===================================
          IF ( gv_plan_type IS NULL AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep)
            OR
             ( gv_plan_type = cv_plan_typep AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep) THEN
            --出荷実績取得処理
            xxcop_common_pkg2.get_num_of_shipped(
                iv_organization_code =>   lr_xwsp_rec.receipt_org_code  --   受入組織コード
               ,iv_item_no           =>   lr_xwsp_rec.item_no           --   OPM品目コード
               ,id_plan_date_from    =>   gd_pace_from                  --   出荷ペース(実績)期間FROM
               ,id_plan_date_to      =>   gd_pace_to                    --   出荷ペース（実績）期間TO
               ,on_quantity          =>   ln_sum_of_pace                --   総出荷実績数
               ,ov_errmsg            =>   lv_errmsg                     --   エラー・メッセージ
               ,ov_errbuf            =>   lv_errbuf                     --   リターン・コード
               ,ov_retcode           =>   lv_retcode                     --   ユーザー・エラー・メッセージ
            );
            IF lv_retcode = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
            --  出荷実績稼働日数取得
            xxcop_common_pkg2.get_working_days(
                in_organization_id =>   lr_xwsp_rec.receipt_org_id  --   受入組織ID
               ,id_from_date       =>   gd_pace_from
               ,id_to_date         =>   gd_pace_to
               ,on_working_days    =>   ln_pace_days
               ,ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
               ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
               ,ov_retcode         =>   lv_retcode       --   リターン・コード
            );
            IF lv_retcode = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
            IF ln_pace_days = 0 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_appl_cont
                             ,iv_name         => cv_msg_00056
                             ,iv_token_name1  => cv_msg_00056_token_1
                             ,iv_token_value1 => gd_pace_from
                             ,iv_token_name2  => cv_msg_00056_token_2
                             ,iv_token_value2 => gd_pace_to
                           );
              RAISE internal_process_expt;
            END IF;
            --
            IF ln_sum_of_pace <> 0 and ln_pace_days <> 0 THEN
              lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace / ln_pace_days);         --自倉庫出荷ペース算出
            ELSE
              lr_xwsp_rec.shipping_pace := 0;
            END IF;
          ELSIF
            ( gv_plan_type IS NULL AND lr_xwsp_rec.shipping_type = cv_plan_typef)
            OR
            ( gv_plan_type = cv_plan_typef AND lr_xwsp_rec.shipping_type = cv_plan_typef) THEN
            --出荷予測取得処理
            xxcop_common_pkg2.get_num_of_forcast(
                in_organization_id   =>   lr_xwsp_rec.receipt_org_id    --   受入組織コード
               ,in_inventory_item_id =>   lr_xwsp_rec.inventory_item_id --   OPM品目コード
               ,id_plan_date_from    =>   gd_forcast_from               --   出荷ペース(実績)期間FROM
               ,id_plan_date_to      =>   gd_forcast_to                 --   出荷ペース（実績）期間TO
               ,on_quantity          =>   ln_sum_of_pace                --   総出荷実績数
               ,ov_errmsg            =>   lv_errmsg                     --   エラー・メッセージ
               ,ov_errbuf            =>   lv_errbuf                     --   リターン・コード
               ,ov_retcode           =>   lv_retcode                     --   ユーザー・エラー・メッセージ
            );
            IF lv_retcode = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
            --  出荷予測稼働日数取得
            xxcop_common_pkg2.get_working_days(
                in_organization_id =>   lr_xwsp_rec.receipt_org_id   --   受入組織ID
               ,id_from_date       =>   gd_forcast_from
               ,id_to_date         =>   gd_forcast_to
               ,on_working_days    =>   ln_forcast_days
               ,ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
               ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
               ,ov_retcode         =>   lv_retcode       --   リターン・コード
            );
            IF lv_retcode = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
            IF ln_forcast_days = 0 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_appl_cont
                             ,iv_name         => cv_msg_00056
                             ,iv_token_name1  => cv_msg_00056_token_1
                             ,iv_token_value1 => gd_pace_from
                             ,iv_token_name2  => cv_msg_00056_token_2
                             ,iv_token_value2 => gd_pace_to
                           );
              RAISE internal_process_expt;
            END IF;
            --
            IF ln_sum_of_pace <> 0 and ln_forcast_days <> 0 THEN
              lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace / ln_forcast_days);         --自倉庫出荷ペース算出
            ELSE
              lr_xwsp_rec.shipping_pace := 0;
            END IF;
          ELSE
            ln_sum_of_pace := 0;   --入力パラメータの設定と異なるので0をセット
            lr_xwsp_rec.shipping_pace   := 0;
          END IF;
          --工場出荷計画ワークテーブル登録処理
          insert_wk_tbl(
            ir_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
            ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
            ov_errbuf            =>   lv_errbuf,             --   リターン・コード
            ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
          );
          IF lv_retcode = cv_status_error THEN
            RAISE internal_process_expt;
          END IF;
        END IF;
      END LOOP get_plant_ship_cur;
      IF ln_loop_cnt = 0 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00062
                       ,iv_token_name1  => cv_msg_00062_token_1
                       ,iv_token_value1 => lr_xwsp_rec.plant_org_code || cv_msg_org_name ||cv_pm_part || lr_xwsp_rec.plant_org_name
                     );
        RAISE internal_process_expt;
      END IF;
    END LOOP get_wk_ship_planning_cur;
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
  END get_plant_shipping;
--
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_org_data_lvl       NUMBER := 1;   --初回ループはデータ出力レベル
    ln_loop_cnt           NUMBER := 0;   --ループカウント
    ln_organization_id    hr_all_organization_units.organization_id%TYPE;
    ln_inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE;
    lv_organization_code  mtl_parameters.organization_code%TYPE;
    lv_organization_name  ic_whse_mst.whse_name%TYPE;
    lv_whse_code          ic_whse_mst.whse_code%TYPE;
    ln_after_stock        xxcop_wk_ship_planning.after_stock%TYPE;
    ln_sum_of_pace        NUMBER := 0;
    ln_cnt_from_org       NUMBER := 0;
    ln_own_flg_cnt        NUMBER := 0;
    ld_product_schedule_date        DATE := NULL;
    ln_pace_days          NUMBER := 0;
    ln_forcast_days       NUMBER := 0;
    ln_loop_chk           NUMBER := 0;
    ln_dual_chk           NUMBER := 0;
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
       ,inventory_item_id
       ,item_id
       ,item_no
       ,item_name
       ,prod_class_code
       ,num_of_case
       ,product_schedule_date
       ,product_schedule_qty
       ,receipt_org_id
       ,receipt_org_code
       ,receipt_org_name
       ,receipt_date
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = ln_org_data_lvl
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_code
      ;
    --経路情報取得カーソル(出荷→受入)
    CURSOR get_plant_ship_cur IS
      SELECT
        inventory_item_id                                                   --在庫品目ID
       ,organization_id                                                     --組織ID
       ,source_organization_id                                              --出荷組織
       ,receipt_organization_id                                             --受入組織
       ,own_flg                                                             --自倉庫フラグ
       ,ship_plan_type                                                      --出荷計画区分
       ,yusen                                                               --割当先優先度
       ,row_number
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
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id     --入力項目の組織品目id
              OR    msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = ln_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)  >= cd_sys_date
              AND    flv.lookup_code              = to_char(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
            )
          ) keiro,
          (
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
              AND    mas.attribute1               = cv_base_plan    --基本横持ち制御マスタ
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id
              OR    msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = to_number(fnd_profile.value(cv_master_org_id))
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag             = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)         >= cd_sys_date
              AND    flv.lookup_code              = to_char(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_START
              ORDER BY yusen
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_END
            )
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_START
            WHERE ROWNUM = 1
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_END
          ) dummy
          WHERE keiro.receipt_organization_id = NVL(dummy.organization_id(+),keiro.receipt_organization_id)
        )
      )
      WHERE row_number <= 1
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
  --===================================
  --ワークテーブルよりデータ抽出
  --===================================
    <<lvl_countup_loop>>
    LOOP
      --変数初期化
      ln_loop_cnt := 0;
      <<get_wk_loop>>
      FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
        --ループカウントカウントアップ
        ln_loop_cnt := ln_loop_cnt + 1;
        --変数初期化
        lr_xwsp_rec := NULL;
        --
        --工場出荷ワークレコードセット
        lr_xwsp_rec.transaction_id           := get_wk_ship_planning_rec.transaction_id;         --工場出荷計画WorkテーブルID
        lr_xwsp_rec.org_data_lvl             := ln_org_data_lvl + 1;     --組織データレベル
        lr_xwsp_rec.plant_org_id             := get_wk_ship_planning_rec.plant_org_id;           --工場組織
        lr_xwsp_rec.plant_org_code           := get_wk_ship_planning_rec.plant_org_code;         --工場倉庫コード
        lr_xwsp_rec.plant_org_name           := get_wk_ship_planning_rec.plant_org_name;         --工場倉庫名
        lr_xwsp_rec.inventory_item_id        := get_wk_ship_planning_rec.inventory_item_id;      --在庫品目ID
        lr_xwsp_rec.item_id                  := get_wk_ship_planning_rec.item_id;                --OPM品目ID
        lr_xwsp_rec.item_no                  := get_wk_ship_planning_rec.item_no;                --品目コード
        lr_xwsp_rec.item_name                := get_wk_ship_planning_rec.item_name;              --品目名称
        lr_xwsp_rec.prod_class_code          := get_wk_ship_planning_rec.prod_class_code;        --商品区分
        lr_xwsp_rec.num_of_case              := get_wk_ship_planning_rec.num_of_case;            --ケース入数
        lr_xwsp_rec.product_schedule_date    := get_wk_ship_planning_rec.product_schedule_date;  --生産予定日
        lr_xwsp_rec.product_schedule_qty     := get_wk_ship_planning_rec.product_schedule_qty;   --生産計画数
        lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.receipt_org_id;         --移動元組織
        lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.receipt_org_code;       --移動元倉庫コード
        lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.receipt_org_name;       --移動元倉庫名
        lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.receipt_date;           --出荷日
        --
        --カーソル変数代入
        ln_organization_id   := lr_xwsp_rec.ship_org_id;
        ln_inventory_item_id := lr_xwsp_rec.inventory_item_id;
        --
        --工場出荷計画制御マスタより受入組織データ抽出（出荷→受入）
        <<get_plant_ship_loop>>
        FOR get_plant_ship_rec IN get_plant_ship_cur LOOP
          --ループ変数セット
          lr_xwsp_rec.receipt_org_id          := get_plant_ship_rec.receipt_organization_id;
          lr_xwsp_rec.own_flg                 := get_plant_ship_rec.own_flg;
          lr_xwsp_rec.shipping_type           := get_plant_ship_rec.ship_plan_type;
          --
          --===================================
          --受入組織情報取得処理
          --===================================
          xxcop_common_pkg2.get_org_info(
            in_organization_id     =>   get_plant_ship_rec.receipt_organization_id,  --   組織ID
            ov_organization_code   =>   lv_organization_code,                        --   組織コード
            ov_whse_name           =>   lv_organization_name,                        --   倉庫名
            ov_errmsg              =>   lv_errmsg,                                   --   エラー・メッセージ
            ov_errbuf              =>   lv_errbuf,                                   --   リターン・コード
            ov_retcode             =>   lv_retcode                                   --   ユーザー・エラー・メッセージ
          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          ELSIF lv_retcode = cv_status_warn THEN
            lv_errmsg :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_appl_cont
                            ,iv_name         => cv_msg_00050
                            ,iv_token_name1  => cv_msg_00050_token_1
                            ,iv_token_value1 => io_xwsp_rec.plant_org_id
                          );
            RAISE internal_process_expt;
          END IF;
          --
          -- 工場出荷ワーク受入組織情報セット
          lr_xwsp_rec.receipt_org_id      := get_plant_ship_rec.receipt_organization_id;     -- 受入組織ID
          lr_xwsp_rec.receipt_org_code    := lv_organization_code;                 -- 受入組織コード
          lr_xwsp_rec.receipt_org_name    := lv_organization_name;                 -- 受入組織名称
          --
          --===================================
          --受入組織ループチェック処理
          --===================================
          BEGIN
            SELECT COUNT(transaction_id)
            INTO ln_loop_chk
            FROM xxcop_wk_ship_planning
            WHERE transaction_id = lr_xwsp_rec.transaction_id
            AND plant_org_id   = lr_xwsp_rec.plant_org_id
            AND inventory_item_id = lr_xwsp_rec.inventory_item_id
            AND product_schedule_date = lr_xwsp_rec.product_schedule_date
            AND ship_org_id = lr_xwsp_rec.receipt_org_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
            NULL;
          END;
          IF ln_loop_chk > 0 THEN
            lv_errmsg :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_appl_cont
                            ,iv_name         => cv_msg_00060
                            ,iv_token_name1  => cv_msg_00060_token_1
                            ,iv_token_value1 => lr_xwsp_rec.receipt_org_code || cv_pm_part || lr_xwsp_rec.receipt_org_name
                          );
            RAISE internal_process_expt;
          END IF;
          --===================================
          --重複レコードチェック処理
          --===================================
          BEGIN
            SELECT COUNT(transaction_id)
            INTO ln_dual_chk
            FROM xxcop_wk_ship_planning
            WHERE transaction_id = lr_xwsp_rec.transaction_id
            AND plant_org_id   = lr_xwsp_rec.plant_org_id
            AND inventory_item_id = lr_xwsp_rec.inventory_item_id
            AND product_schedule_date = lr_xwsp_rec.product_schedule_date
            AND receipt_org_id = lr_xwsp_rec.receipt_org_id
            AND ship_org_id = lr_xwsp_rec.ship_org_id;
            IF ln_dual_chk > 0 THEN
              RAISE expt_next_record;
            END IF;
            --
            --===================================
            -- 自倉庫出荷ペース取得処理
            --===================================
            IF ( gv_plan_type IS NULL AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep)
              OR
               ( gv_plan_type = cv_plan_typep AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep) THEN
              --===================================
              --出荷実績取得処理
              --===================================
              xxcop_common_pkg2.get_num_of_shipped(
                  iv_organization_code =>   lr_xwsp_rec.receipt_org_code  --   受入組織コード
                 ,iv_item_no           =>   lr_xwsp_rec.item_no           --   OPM品目コード
                 ,id_plan_date_from    =>   gd_pace_from                  --   出荷ペース(実績)期間FROM
                 ,id_plan_date_to      =>   gd_pace_to                    --   出荷ペース（実績）期間TO
                 ,on_quantity          =>   ln_sum_of_pace                --   総出荷実績数
                 ,ov_errmsg            =>   lv_errmsg                     --   エラー・メッセージ
                 ,ov_errbuf            =>   lv_errbuf                     --   リターン・コード
                 ,ov_retcode           =>   lv_retcode                    --   ユーザー・エラー・メッセージ
              );
              IF lv_retcode = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
              --===================================
              --  出荷実績稼働日数取得
              --===================================
              xxcop_common_pkg2.get_working_days(
                  in_organization_id =>   lr_xwsp_rec.receipt_org_id  --   受入組織ID
                 ,id_from_date       =>   gd_pace_from
                 ,id_to_date         =>   gd_pace_to
                 ,on_working_days    =>   ln_pace_days
                 ,ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
                 ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
                 ,ov_retcode         =>   lv_retcode       --   リターン・コード
              );
              IF lv_retcode = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
              IF ln_pace_days = 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_appl_cont
                               ,iv_name         => cv_msg_00056
                               ,iv_token_name1  => cv_msg_00056_token_1
                               ,iv_token_value1 => gd_pace_from
                               ,iv_token_name2  => cv_msg_00056_token_2
                               ,iv_token_value2 => gd_pace_to
                             );
                RAISE internal_process_expt;
              END IF;
              IF ln_sum_of_pace <> 0 AND ln_pace_days <> 0 THEN
                lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace / ln_pace_days);         --自倉庫出荷ペース算出
              ELSE
                lr_xwsp_rec.shipping_pace := 0;
              END IF;
              --
            ELSIF
              ( gv_plan_type IS NULL
                AND
                NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typef
              )
              OR
              ( gv_plan_type = cv_plan_typef
                AND
                NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typef
              ) THEN
              --===================================
              --出荷予測取得処理
              --===================================
              xxcop_common_pkg2.get_num_of_forcast(
                  in_organization_id   =>   lr_xwsp_rec.receipt_org_id,    --   受入組織ID
                  in_inventory_item_id =>   lr_xwsp_rec.inventory_item_id, --   在庫品目ID
                  id_plan_date_from    =>   gd_forcast_from,               --   出荷ペース(予測)期間FROM
                  id_plan_date_to      =>   gd_forcast_to,                 --   出荷ペース（予測）期間TO
                  on_quantity          =>   ln_sum_of_pace,                --   総出荷予測数
                  ov_errmsg            =>   lv_errmsg,                     --   エラー・メッセージ
                  ov_errbuf            =>   lv_errbuf,                     --   リターン・コード
                  ov_retcode           =>   lv_retcode                     --   ユーザー・エラー・メッセージ
              );
              IF lv_retcode = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
              --===================================
              --  出荷予測稼働日数取得
              --===================================
              xxcop_common_pkg2.get_working_days(
                  in_organization_id =>   lr_xwsp_rec.receipt_org_id   --   受入組織ID
                 ,id_from_date       =>   gd_forcast_from
                 ,id_to_date         =>   gd_forcast_to
                 ,on_working_days    =>   ln_forcast_days
                 ,ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
                 ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
                 ,ov_retcode         =>   lv_retcode       --   リターン・コード
              );
              IF lv_retcode = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
              IF ln_forcast_days = 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_appl_cont
                               ,iv_name         => cv_msg_00056
                               ,iv_token_name1  => cv_msg_00056_token_1
                               ,iv_token_value1 => gd_pace_from
                               ,iv_token_name2  => cv_msg_00056_token_2
                               ,iv_token_value2 => gd_pace_to
                             );
                RAISE internal_process_expt;
              END IF;
              IF ln_sum_of_pace <> 0 AND ln_forcast_days <> 0 THEN
                lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace  / ln_forcast_days); --自倉庫出荷ペース算出
              ELSE
                lr_xwsp_rec.shipping_pace := 0;
              END IF;
            ELSE
              ln_sum_of_pace := 0;   --入力パラメータの設定と異なるので0をセット
              lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace);
            END IF;
            --
            --===================================
            --親組織件数取得処理
            --===================================
            ln_cnt_from_org := get_cnt_from_org(
                                  in_inventory_item_id     => lr_xwsp_rec.inventory_item_id
                                 ,in_organization_id       => lr_xwsp_rec.receipt_org_id
                                 ,ov_errbuf                => lv_errmsg
                                 ,ov_retcode               => lv_errbuf
                                 ,ov_errmsg                => lv_retcode
                               );
            IF lv_retcode = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
            lr_xwsp_rec.cnt_ship_org := ln_cnt_from_org;
            --
            --===================================
            --工場出荷計画ワークテーブル登録処理
            --===================================
            insert_wk_tbl(
              ir_xwsp_rec          =>   lr_xwsp_rec,           --   工場出荷ワークレコードタイプ
              ov_errmsg            =>   lv_errmsg,             --   エラー・メッセージ
              ov_errbuf            =>   lv_errbuf,             --   リターン・コード
              ov_retcode           =>   lv_retcode             --   ユーザー・エラー・メッセージ
              );
            IF lv_retcode = cv_status_error THEN
              RAISE internal_process_expt;
            END IF;
          EXCEPTION
            WHEN expt_next_record THEN
              NULL;
          END;
        END LOOP get_plant_ship_cur;
      END LOOP get_wk_ship_planning_cur;
      IF ln_loop_cnt = 0 THEN
        EXIT;
      ELSE
        ln_org_data_lvl := ln_org_data_lvl + 1;
      END IF;
    END LOOP;
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
  END get_base_yokomst;
--
  /**********************************************************************************
   * Procedure Name   : get_pace_sum
   * Description      : 出荷ペース取得処理（A-51）
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
    ln_loop_cnt    NUMBER := 0;
    ln_undr_lvl_pace NUMBER := 0;
    ln_bro_lvl_pace  NUMBER := 0;
--
    -- *** ローカル・カーソル ***
    --
    CURSOR get_wk_cur IS
      SELECT ship_org_id
        ,receipt_org_id
        ,shipping_pace
        ,cnt_ship_org
      FROM   xxcop_wk_ship_planning
      WHERE  ship_org_id            = in_receipt_org_id
        AND  plant_org_id           = in_plant_org_id
        AND  inventory_item_id      = in_inventory_item_id
        AND  product_schedule_date  = id_product_schedule_date
        AND  org_data_lvl           > cn_data_lvl_output
        AND  transaction_id         = in_transaction_id;
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
    ln_loop_cnt := 0;
    FOR get_wk_rec IN get_wk_cur LOOP
      ln_loop_cnt := ln_loop_cnt + 1;
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
      IF lv_retcode = cv_status_error THEN
        RAISE global_api_expt;
      END IF;
      ln_bro_lvl_pace := ln_bro_lvl_pace + ROUND((ln_undr_lvl_pace + get_wk_rec.shipping_pace) / get_wk_rec.cnt_ship_org);
    END LOOP;
    IF ln_loop_cnt = 0 THEN
      on_undr_lvl_pace  := 0;
    ELSE
      on_undr_lvl_pace := ln_bro_lvl_pace;
    END IF;
  EXCEPTION
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
  END get_pace_sum;
--
  /**********************************************************************************
   * Procedure Name   : get_under_lvl_pace
   * Description      : 下位倉庫出荷ペース取得処理（A-5）
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
    ln_undr_lvl_pace_out  NUMBER := 0;        -- 下位倉庫出荷ペース工場倉庫レベル
    ln_shipping_pace      NUMBER := 0;        -- 出荷ペース
    ln_own_pace           NUMBER := 0;        -- 自倉庫出荷ペース
    ln_receipt_org_id     NUMBER := NULL;     -- 移動先組織ID
    ln_plant_org_id       NUMBER := NULL;
    ln_inventory_item_id  NUMBER := NULL;
    ld_schedule_date      DATE;
    ln_lvl                NUMBER := 0;
    ln_indx               NUMBER := 0;
--
    -- *** ローカル・カーソル ***
    --ワークテーブル取得カーソル（出力データレベル）
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id
        ,plant_org_id
        ,inventory_item_id
        ,product_schedule_date
        ,receipt_org_id
        ,shipping_pace
        ,cnt_ship_org
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_code;
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
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      --変数初期化
      ln_undr_lvl_pace := 0;
      ln_receipt_org_id := get_wk_ship_planning_rec.receipt_org_id;
      --下位組織情報取得
      get_pace_sum( in_receipt_org_id         => ln_receipt_org_id
                   ,in_plant_org_id           => get_wk_ship_planning_rec.plant_org_id
                   ,in_inventory_item_id      => get_wk_ship_planning_rec.inventory_item_id
                   ,id_product_schedule_date  => get_wk_ship_planning_rec.product_schedule_date
                   ,in_transaction_id         => get_wk_ship_planning_rec.transaction_id
                   ,on_undr_lvl_pace          => ln_undr_lvl_pace
                   ,ov_errbuf                 => lv_errbuf
                   ,ov_retcode                => lv_retcode
                   ,ov_errmsg                 => lv_errmsg
                   );
      --自倉庫出荷ペース＋下位倉庫出荷ペース
      ln_undr_lvl_pace := ROUND((get_wk_ship_planning_rec.shipping_pace + ln_undr_lvl_pace) /get_wk_ship_planning_rec.cnt_ship_org);
      BEGIN
        UPDATE xxcop_wk_ship_planning
        SET under_lvl_pace = ln_undr_lvl_pace
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
    END LOOP get_wk_ship_planning_cur;
    --下位倉庫出荷ペース
    io_xwsp_rec.under_lvl_pace := ln_shipping_pace;
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
  END get_under_lvl_pace;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_qty
   * Description      : 在庫数取得処理（A-6）
   ***********************************************************************************/
  PROCEDURE get_stock_qty(
    io_xwsp_rec            IN OUT xxcop_wk_ship_planning%ROWTYPE,   --   工場出荷ワークレコードタイプ
    ov_errbuf                OUT VARCHAR2,              --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,              --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)              --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_plant_org_code          xxcop_wk_ship_planning.plant_org_code%TYPE := NULL;
    ld_product_schedule_date   xxcop_wk_ship_planning.product_schedule_date%TYPE := NULL;
    ln_before_stock            xxcop_wk_ship_planning.before_stock%TYPE := NULL;
    ln_num_of_case             xxcop_wk_ship_planning.num_of_case%TYPE := NULL;
    ln_working_days            NUMBER := 0;
    ln_receipt_plan_qty        NUMBER := 0;
    ln_onhand_qty              NUMBER := 0;
--
    -- *** ローカル・カーソル ***
    --ワークテーブル取得カーソル（出力データレベル）
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id
        ,inventory_item_id
        ,item_no
        ,item_id
        ,product_schedule_date
        ,receipt_org_id
        ,receipt_org_code
        ,under_lvl_pace
        ,plant_org_id
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_code;
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
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      --変数初期化
      ln_before_stock := NULL;
      BEGIN
--20090407_Ver1.2_T1_0278_SCS_Uda_ADD_START
        SELECT
             plant_org_code
          ,  product_schedule_date
          ,  after_stock
          ,  num_of_case
        INTO
             lv_plant_org_code
          ,  ld_product_schedule_date
          ,  ln_before_stock
          ,  ln_num_of_case
        FROM(
--20090407_Ver1.2_T1_0278_SCS_Uda_ADD_END
          SELECT
               plant_org_code
            ,  product_schedule_date
            ,  after_stock
            ,  num_of_case
--20090407_Ver1.2_T1_0278_SCS_Uda_DEL_START
--        INTO
--             lv_plant_org_code
--          ,  ld_product_schedule_date
--          ,  ln_before_stock
--          ,  ln_num_of_case
--20090407_Ver1.2_T1_0278_SCS_Uda_DEL_END
          FROM  xxcop_wk_ship_planning
          WHERE transaction_id = get_wk_ship_planning_rec.transaction_id
            AND org_data_lvl = cn_data_lvl_output
            AND inventory_item_id = get_wk_ship_planning_rec.inventory_item_id
            AND receipt_org_id = get_wk_ship_planning_rec.receipt_org_id
            AND after_stock IS NOT NULL
--20090407_Ver1.2_T1_0278_SCS_Uda_MOD_START
--            AND product_schedule_date < get_wk_ship_planning_rec.product_schedule_date
--            AND ROWNUM = 1
--          ORDER BY product_schedule_date DESC;
          ORDER BY product_schedule_date DESC,plant_org_code DESC
          )
        WHERE ROWNUM = 1;
--20090407_Ver1.2_T1_0278_SCS_Uda_MOD_END
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_before_stock := NULL;
      END;
      --後在庫が他倉庫に存在するとき
      IF ln_before_stock IS NOT NULL THEN
        --稼働日数取得処理
        xxcop_common_pkg2.get_working_days(
            in_organization_id =>   get_wk_ship_planning_rec.receipt_org_id  --   受入組織ID
           ,id_from_date       =>   ld_product_schedule_date
           ,id_to_date         =>   get_wk_ship_planning_rec.product_schedule_date
           ,on_working_days    =>   ln_working_days
           ,ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
           ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
           ,ov_retcode         =>   lv_retcode       --   リターン・コード
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        --入庫予定取得処理
        xxcop_common_pkg2.get_stock_plan(
            in_organization_id =>   get_wk_ship_planning_rec.receipt_org_id  --   受入組織ID
           ,iv_item_no         =>   get_wk_ship_planning_rec.item_no
           ,id_plan_date_from  =>   ld_product_schedule_date
           ,id_plan_date_to    =>   get_wk_ship_planning_rec.product_schedule_date
           ,on_quantity        =>   ln_receipt_plan_qty
           ,ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
           ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
           ,ov_retcode         =>   lv_retcode       --   リターン・コード
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        --前在庫数（後在庫(同一倉庫の同品目で生産予定日が最大のものの後在庫) + 入庫予定数 - 出荷ペース * 稼働日）
        ln_before_stock := ln_before_stock + ln_receipt_plan_qty - get_wk_ship_planning_rec.under_lvl_pace * ln_working_days;
      --
      --後在庫が存在しないとき
      ELSE
        --
        --手持在庫取得処理
        xxcop_common_pkg2.get_onhand_qty(
            iv_organization_code =>   get_wk_ship_planning_rec.receipt_org_code  --   受入組織ID
           ,in_item_id           =>   get_wk_ship_planning_rec.item_id           --   OPM品目ID
           ,on_quantity          =>   ln_onhand_qty                              --   手持在庫数
           ,ov_errmsg            =>   lv_errmsg                                  --   ユーザー・エラー・メッセージ
           ,ov_errbuf            =>   lv_errbuf                                  --   エラー・メッセージ
           ,ov_retcode           =>   lv_retcode                                 --   リターン・コード
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        --
        --稼働日数取得処理
        xxcop_common_pkg2.get_working_days(
            in_organization_id =>   get_wk_ship_planning_rec.receipt_org_id           --   受入組織ID
           ,id_from_date       =>   cd_sys_date                                       --   システム日付
           ,id_to_date         =>   get_wk_ship_planning_rec.product_schedule_date    --   生産予定日
           ,on_working_days    =>   ln_working_days                                   --   稼働日数
           ,ov_errmsg          =>   lv_errmsg                                         --   ユーザー・エラー・メッセージ
           ,ov_errbuf          =>   lv_errbuf                                         --   エラー・メッセージ
           ,ov_retcode         =>   lv_retcode                                        --   リターン・コード
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        --
        --入庫予定取得処理
        xxcop_common_pkg2.get_stock_plan(
            in_organization_id =>   get_wk_ship_planning_rec.receipt_org_id  --   受入組織ID
           ,iv_item_no         =>   get_wk_ship_planning_rec.item_no
           ,id_plan_date_from  =>   cd_sys_date
           ,id_plan_date_to    =>   get_wk_ship_planning_rec.product_schedule_date
           ,on_quantity        =>   ln_receipt_plan_qty
           ,ov_errmsg          =>   lv_errmsg        --   ユーザー・エラー・メッセージ
           ,ov_errbuf          =>   lv_errbuf        --   エラー・メッセージ
           ,ov_retcode         =>   lv_retcode       --   リターン・コード
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        --
        --前在庫数（後在庫(同一倉庫の同品目で生産予定日が最大のものの後在庫) + 入庫予定数 - 出荷ペース * 稼働日）
        ln_before_stock := ln_onhand_qty + ln_receipt_plan_qty - get_wk_ship_planning_rec.under_lvl_pace * ln_working_days;
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
    END LOOP get_wk_ship_planning_cur;
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
  END get_stock_qty;
--
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
    ln_sum_pace NUMBER := 0;
    ln_sum_before_stock NUMBER := 0;
    ln_stock_days NUMBER := 0;
    ln_stock NUMBER := 0;
    ln_product_schedule_qty NUMBER := 0;
    ln_move_qty NUMBER := 0;
    ln_after_stock NUMBER := 0;
    ln_palette_qty NUMBER := 0;
--
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
      ORDER BY product_schedule_date,item_no,plant_org_code;
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
    --総出荷ペース取得
    SELECT
       product_schedule_qty
      ,SUM(NVL(under_lvl_pace,0))
      ,SUM(NVL(before_stock,0))
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
    GROUP BY transaction_id,plant_org_id,plant_org_code
            ,inventory_item_id,item_no,product_schedule_date,product_schedule_qty;
    -- 按分計算ゼロチェック
    IF NVL(ln_sum_pace,0) = 0 THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00058
                     ,iv_token_name1  => cv_msg_00058_token_1
                     ,iv_token_value1 => cv_msg_stock_days
                     ,iv_token_name2  => cv_msg_00058_token_2
                     ,iv_token_value2 => cv_msg_sum_pace
                   );
      RAISE internal_process_expt;
    END IF;
    --
    --在庫日数算出
    IF NVL(ln_sum_pace,0) <> 0 THEN
      ln_stock_days := ROUND((ln_product_schedule_qty + ln_sum_before_stock) / ln_sum_pace);
    ELSE
      ln_stock_days := 0;
    END IF;
--
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      --在庫数
      ln_stock := ln_stock_days * get_wk_ship_planning_rec.under_lvl_pace;
      --移動数
      IF ln_stock <> 0 THEN
        ln_move_qty :=ln_stock - get_wk_ship_planning_rec.before_stock;
      ELSE
        ln_move_qty := 0;
      END IF;
      --移動パレット変換
      ln_palette_qty := get_wk_ship_planning_rec.num_of_case * get_wk_ship_planning_rec.palette_max_cs_qty * get_wk_ship_planning_rec.palette_max_step_qty;
      --
      IF NVL(ln_palette_qty,0) = 0 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00058
                       ,iv_token_name1  => cv_msg_00058_token_1
                       ,iv_token_value1 => cv_msg_palette
                       ,iv_token_name2  => cv_msg_00058_token_2
                       ,iv_token_value2 => cv_msg_move_qty
                     );
        RAISE internal_process_expt;
      END IF;
      --移動数パレット換算後
      ln_move_qty :=ln_palette_qty * ROUND(ln_move_qty / ln_palette_qty);
      --後在庫
      ln_after_stock := ln_move_qty + get_wk_ship_planning_rec.before_stock;
      --
      BEGIN
        UPDATE xxcop_wk_ship_planning
        SET   schedule_qty = ln_move_qty
             ,after_stock = ln_after_stock
             ,stock_days = ln_stock_days
        WHERE inventory_item_id         = get_wk_ship_planning_rec.inventory_item_id
        AND   transaction_id            = get_wk_ship_planning_rec.transaction_id
        AND   org_data_lvl              = cn_data_lvl_output
        AND   plant_org_id              = get_wk_ship_planning_rec.plant_org_id
        AND   product_schedule_date     = get_wk_ship_planning_rec.product_schedule_date
        AND   receipt_org_id            = get_wk_ship_planning_rec.receipt_org_id;
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
    END LOOP get_wk_ship_planning_cur;
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
  END get_move_qty;
--
  /**********************************************************************************
   * Procedure Name   : insert_wk_output
   * Description      : 工場出荷計画出力ワークテーブル作成（A-8）
   ***********************************************************************************/
  PROCEDURE insert_wk_output(
     in_transaction_id   IN NUMBER
    ,ov_errbuf           OUT VARCHAR2                                      --   エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT VARCHAR2                                      --   リターン・コード             --# 固定 #
    ,ov_errmsg           OUT VARCHAR2)                                     --   ユーザー・エラー・メッセージ --# 固定 #
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
     ,ship_org_name
     ,receipt_org_code
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
     ,ship_org_name
     ,receipt_org_code
     ,receipt_org_name
     ,item_no
     ,item_name
     ,ROUND(schedule_qty / num_of_case)
     ,ROUND(before_stock / num_of_case)
     ,ROUND(after_stock / num_of_case)
     ,stock_days
     ,ROUND(under_lvl_pace/ num_of_case)
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
    ORDER BY plant_org_code,item_no,product_schedule_date,receipt_org_code
    ;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
  END insert_wk_output;
--
  /**********************************************************************************
   * Procedure Name   : csv_output
   * Description      : 工場出荷計画CSV出力(A-9)
   ***********************************************************************************/
  PROCEDURE csv_output(
     in_transaction_id    IN  NUMBER
   , ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
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
    -- 処理結果レポート出力文字列バッファ
    lv_buff VARCHAR2(500);
--
    -- *** ローカル・カーソル ***
    CURSOR get_csv_output_cur IS
      SELECT
        transaction_id
       ,shipping_date
       ,receipt_date
       ,ship_org_code
       ,ship_org_name
       ,receipt_org_code
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
      FROM
        xxcop_wk_ship_planning_output
      WHERE transaction_id = in_transaction_id
      ORDER BY ship_org_code,item_no,schedule_date,receipt_org_code;
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
    lv_buff :=            cv_csv_part || cv_csv_header1  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header2  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header3  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header4  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header5  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header6  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header7  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header8  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header9  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header10 || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header11 || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header12 || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header13 || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header14 || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header15 || cv_csv_part
        ;
    --
    -- タイトル行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_buff
    );
    --
    <<csv_output_loop>>
    FOR get_csv_output_rec IN get_csv_output_cur LOOP
      --
      -- データ行
      lv_buff :=          cv_csv_part || TO_CHAR(get_csv_output_rec.shipping_date,cv_date_format)      || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.receipt_date,cv_date_format)       || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.ship_org_code                              || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.ship_org_name                              || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.receipt_org_code                           || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.receipt_org_name                           || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.item_no                                    || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.item_name                                  || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.schedule_qty)                      || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.before_stock)                      || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.after_stock)                       || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.stock_days)                        || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.shipping_pace)                     || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.plant_mark                                 || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.schedule_date,cv_date_format)      || cv_csv_part
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
  END csv_output;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_plan_type                  IN  VARCHAR2         --  1.計画区分
    ,iv_pace_from                  IN  VARCHAR2         --  2.出荷ペース(実績)期間FROM
    ,iv_pace_to                    IN  VARCHAR2         --  3.出荷ペース（実績）期間TO
    ,iv_forcast_type               IN  VARCHAR2         --  4.出荷予測期間
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
    CURSOR get_schedule_cur IS
    SELECT
--20090407_Ver1.2_T1_0280_SCS_Uda_DEL_START
--       msdate.schedule_designator    schedule_designator      --基準計画名
--20090407_Ver1.2_T1_0280_SCS_Uda_DEL_END
       msdate.organization_id        plant_org_id             --工場倉庫
      ,msdate.inventory_item_id      inventory_item_id        --在庫品目ID
      ,msdate.schedule_date          product_schedule_date    --計画日付
      ,SUM(msdate.schedule_quantity)      product_schedule_qty     --計画数量
    FROM
       mrp_schedule_designators  msdesi        --基準計画名テーブル
      ,mrp_schedule_dates        msdate        --基準計画日付テーブル
    WHERE  msdate.schedule_designator =  msdesi.schedule_designator
      AND  msdate.organization_id     =  msdesi.organization_id
      AND  msdate.schedule_date      >=  NEXT_DAY(cd_sys_date,cv_sunday)
      AND  msdate.schedule_date      <   NEXT_DAY(NEXT_DAY(cd_sys_date,cv_sunday),cv_saturday)
      AND  msdesi.attribute1          =  cv_buy_type       --基準計画分類「3：購入計画」
      AND  msdate.schedule_level      =  cn_schedule_level --レベル２
    GROUP BY
--20090407_Ver1.2_T1_0280_SCS_Uda_DEL_START
--       msdate.schedule_designator
--20090407_Ver1.2_T1_0280_SCS_Uda_DEL_END
       msdate.organization_id
      ,msdate.inventory_item_id
      ,msdate.schedule_date
    ORDER BY msdate.schedule_date,msdate.inventory_item_id , msdate.organization_id
    ;
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- グローバル変数に入力パラメータを設定
    gv_plan_type       := iv_plan_type;
    gd_pace_from       := TO_DATE(iv_pace_from,cv_date_format_slash);
    gd_pace_to         := TO_DATE(iv_pace_to  ,cv_date_format_slash);
    gv_forcast_type    := iv_forcast_type;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --      A-1 初期処理
    -- ===============================
    init(
      iv_plan_type      -- 計画区分
     ,iv_pace_from      -- 出荷ペース計画期間(FROM)
     ,iv_pace_to        -- 出荷ペース計画期間(TO)
     ,iv_forcast_type   -- 出荷予測区分
     ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,lv_retcode        -- リターン・コード             --# 固定 #
     ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;
    <<Base_loop>>
    FOR get_schedule_rec IN get_schedule_cur LOOP
      --変数初期化
      lr_xwsp_rec := NULL;
      --処理行数カウント
      ln_loop_cnt := ln_loop_cnt + 1;
      --工場出荷ワークレコードセット
      lr_xwsp_rec.transaction_id          := cn_request_id;                               -- 要求ID
      lr_xwsp_rec.org_data_lvl            := cn_data_lvl_plant;                           -- 組織データレベル(出力データレベル)
      lr_xwsp_rec.inventory_item_id       := get_schedule_rec.inventory_item_id;          -- 在庫品目ID
      lr_xwsp_rec.plant_org_id            := get_schedule_rec.plant_org_id;               -- 工場組織ID
      lr_xwsp_rec.ship_org_id             := get_schedule_rec.plant_org_id;               -- 移動元組織ID
      lr_xwsp_rec.product_schedule_date   := get_schedule_rec.product_schedule_date;      -- 生産予定日
      lr_xwsp_rec.product_schedule_qty    := get_schedule_rec.product_schedule_qty;       -- 生産計画数
      lr_xwsp_rec.shipping_date           := get_schedule_rec.product_schedule_date;      -- 出荷日
      --
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
      BEGIN
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
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
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
        ELSIF (lv_retcode = cv_status_warn) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
          RAISE expt_next_record;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
        END IF;
        -- =============================================
        --      A-3 工場出荷計画制御マスタ取得
        -- =============================================
        get_plant_shipping(
          io_xwsp_rec          =>   lr_xwsp_rec     --   工場出荷ワークレコードタイプ
         ,ov_errmsg            =>   lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
         ,ov_errbuf            =>   lv_errbuf        -- エラー・メッセージ           --# 固定 #
         ,ov_retcode           =>   lv_retcode       -- リターン・コード             --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
        -- =============================================
        --      A-4 基本横持制御マスタ取得
        -- =============================================
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
        IF lv_retcode = cv_status_error THEN
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
        IF lv_retcode = cv_status_error THEN
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
        IF lv_retcode = cv_status_error THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
      EXCEPTION
        WHEN expt_next_record THEN
          NULL;
      END;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
    END LOOP get_schedule_cur;
    --
    IF ln_loop_cnt = 0 THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00003      --対象データなし
                   );
      RAISE internal_process_expt;
    END IF;
    --
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
    -- 対象件数算出
    gn_target_cnt := gn_normal_cnt + gn_warn_cnt;

    -- 警告メッセージを出力した場合、警告終了で戻す
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
    WHEN internal_process_expt THEN
      --カーソルクローズ
      IF get_schedule_cur%ISOPEN = TRUE THEN
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
      IF get_schedule_cur%ISOPEN = TRUE THEN
        CLOSE get_schedule_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --カーソルクローズ
      IF get_schedule_cur%ISOPEN = TRUE THEN
        CLOSE get_schedule_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --カーソルクローズ
      IF get_schedule_cur%ISOPEN = TRUE THEN
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
    ,iv_plan_type                  IN  VARCHAR2         -- 1.計画区分
    ,iv_pace_from                  IN  VARCHAR2         -- 2.出荷ペース(実績)期間FROM
    ,iv_pace_to                    IN  VARCHAR2         -- 3.出荷ペース（実績）期間TO
    ,iv_forcast_type               IN  VARCHAR2         -- 4.出荷予測期間
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
       iv_plan_type                      -- 1.計画区分
      ,iv_pace_from                      -- 2.出荷ペース(実績)期間FROM
      ,iv_pace_to                        -- 3.出荷ペース（実績）期間TO
      ,iv_forcast_type                   -- 4.出荷予測期間
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
    --終了ステータスがエラーの場合はROLLBACKする
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
