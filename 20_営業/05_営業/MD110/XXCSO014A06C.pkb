CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A06C(body)
 * Description      : 営業員管理ファイルをHHTに送信するための 
 *                    CSVファイルを作成します。
 * MD.050           : MD050_CSO_014_A06_HHT-EBSインターフェース：
 *                    (OUT)営業員管理ファイル
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_profile_info       プロファイル値取得 (A-2)
 *  open_csv_file          CSVファイルオープン (A-3)
 *  get_sum_cnt_data       CSVファイルに出力する関連情報取得 (A-5)
 *  get_prsncd_data        営業員管理データを抽出 (A-6)
 *  create_csv_rec         CSVファイル出力 (A-7) 
 *  close_csv_file         CSVファイルクローズ (A-8) 
 *  get_sum_sls_tgt_data   売上目標データ初期処理(A-9)
 *  ins_work_results       実績データワークテーブル格納(A-11)
 *  submain                メイン処理プロシージャ
 *                           リソースデータ取得 (A-4)
 *                           売上目標データ取得処理（実績あり）(A-10)
 *                           売上目標データ取得処理（目標のみ）(A-12)
 *                           月初表示用目標データ取得処理(A-13)
 *                           売上目標データCSV出力処理(A-14)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-15)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-28    1.0   Seirin.Kin        新規作成
 *  2009-02-19    1.1   K.Sai             レビュー結果反映
 *  2009-03-17    1.1   M.Maruyama        実績振替の集計追加変更によりデータ取得VIEWを
 *                                        売上実績ビューから、営業員用売上実績VIEWへ修正
 *  2009-03-18    1.1   M.Maruyama        DEBUGLOGメッセージ修正
 *  2009-05-01    1.2   Tomoko.Mori       T1_0897対応
 *  2009-05-20    1.3   K.Satomura        T1_1082対応
 *  2009-05-28    1.4   K.Satomura        T1_1236対応
 *  2009-06-03    1.5   K.Satomura        T1_1304対応
 *  2009-06-09    1.6   K.Satomura        T1_1304対応(再修正)
 *  2009-10-19    1.7   K.Kubo            T4_00046対応
 *  2009-11-23    1.8   T.Maruyama        E_本番_00331対応（当月売上実績を営業成績表と同様
 *                                        成績計上者ベースとする）
 *  2010-08-26    1.9   K.Kiriu           E_本番_04153対応（PT対応)
 *  2013-05-13    1.10  K.Kiriu           E_本番_10735対応(営業員別月別ノルマ実績)
 *  2013-06-18    1.11  T.Ishiwata        E_本番_10837対応(メール配信機能対応)
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
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
  gn_target_cnt2   NUMBER;                    -- 対象件数(売上目標)
  gn_normal_cnt2   NUMBER;                    -- 正常件数(売上目標)
  gn_warn_cnt2     NUMBER;                    -- スキップ件数(売上目標)
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A06C';   -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';          -- アプリケーション短縮名
  cv_duty_cd             CONSTANT VARCHAR2(30)  := '010';            -- 職務コード010(固定)
  cv_duty_cd_vl          CONSTANT VARCHAR2(30)  := 'ルートセールス';   -- 職務コード010(固定)
  /* 2009.10.19 K.Kubo T4_00046対応 START */
  cv_duty_cd_050         CONSTANT VARCHAR2(30)  := '050';                -- 職務コード050(固定)
  cv_duty_cd_050_vl      CONSTANT VARCHAR2(30)  := '専門店、百貨店販売'; -- 職務コード050(固定)
  /* 2009.10.19 K.Kubo T4_00046対応 END */
  cv_object_cd           CONSTANT VARCHAR2(30)  := 'PARTY';          -- ソースコード(固定)
  cv_delete_flag         CONSTANT VARCHAR2(1)   := 'N';              -- タスク削除フラグ
  cv_owner_type_code     CONSTANT VARCHAR2(30)  := 'RS_EMPLOYEE';    -- タスクオーナータイプ
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
  cv_yes                 CONSTANT VARCHAR2(1)   := 'Y';
  cv_no                  CONSTANT VARCHAR2(1)   := 'N';
  cv_app_name_cmm        CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_app_name_ccp        CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- 参照タイプ
  ct_item_group_summary  CONSTANT  fnd_lookup_values_vl.lookup_type%TYPE := 'XXCMM1_ITEM_GROUP_SUMMARY';  --商品別売上集計マスタ
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
--
  -- メッセージコード
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSVファイルオープンエラー
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSVファイルクローズエラー
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSVファイル残存エラー
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00141';  -- データ抽出エラー
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00144';  -- CSVファイル出力エラー
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- インタファースファイル名
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSVファイル出力0件エラー
  /* 2009.05.28 K.Satomura T1_1236対応 START */
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00572';  -- リソースグループ有効エラー
  /* 2009.05.28 K.Satomura T1_1236対応 END */
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';  -- テーブル削除エラー
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00649';  -- テーブル挿入エラー
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00054';  -- 値取得エラー
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00054';  -- データ取得エラー
--
  --他領域メッセージ
  cv_tkn_number_cmm_01  CONSTANT VARCHAR2(100) := 'APP-XXCMM1-00602';  -- 目標管理項目コード
  cv_tkn_number_cmm_02  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10114';  -- 半角数値チェック
--
  --トークン値
  cv_tkn_value_01     CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00650';  -- 売上目標ワークテーブル
  cv_tkn_value_02     CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00651';  -- 稼働日カレンダ
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
--
  -- トークンコード
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_prof_nm          CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc          CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_csv_fnm          CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_duty_cd          CONSTANT VARCHAR2(20) := 'DUTY_CODE';
  cv_tkn_loc_cd           CONSTANT VARCHAR2(20) := 'LOCATION_CODE';
  cv_tkn_sales_cd         CONSTANT VARCHAR2(20) := 'SALES_CODE';
  cv_tkn_sales_nm         CONSTANT VARCHAR2(20) := 'SALES_NAME';
  cv_tkn_ymd              CONSTANT VARCHAR2(20) := 'YEAR_MONTH_DAY';
  cv_tkn_tbl              CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_cnt              CONSTANT VARCHAR2(20) := 'COUNT';
  /* 2009.05.28 K.Satomura T1_1236対応 START */
  cv_tkn_emp_num          CONSTANT VARCHAR2(20) := 'EMPLOYEE_NUMBER';
  cv_tkn_emp_name         CONSTANT VARCHAR2(20) := 'EMPLOYEE__NAME';
  /* 2009.05.28 K.Satomura T1_1236対応 END */
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cb_false                CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< プロファイル値、クローズID >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'ファイル出力先 : ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := 'ファイル名 : ';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'クローズID : ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< 年度取得処理 >>';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'ファイルをクローズしました';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := 'ロールバックししました';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '業務処理日付:';
  cv_debug_msg9           CONSTANT VARCHAR2(200) := '<<ファイルをオープンしました。>>';
  cv_debug_msg10          CONSTANT VARCHAR2(200) := 'レコードが存在しないため販売実績に0をセットしました。';
  cv_debug_msg11          CONSTANT VARCHAR2(200) := 'レコードが存在しないため訪問実績に0をセットしました。'; 
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_sum        CONSTANT VARCHAR2(200) := '販売実績：';
  cv_debug_msg_cnt        CONSTANT VARCHAR2(200) := '訪問実績：';
  cv_debug_base_code      CONSTANT VARCHAR2(200) := '拠点コード：';
  cv_debug_em_num         CONSTANT VARCHAR2(200) := '営業員コード：';
  cv_debug_sls_amt        CONSTANT VARCHAR2(200) := '当月営業員ノルマ金額：';
  cv_debug_vis_amt        CONSTANT VARCHAR2(200) := '当月訪問ノルマ：';
  cv_debug_msg12          CONSTANT VARCHAR2(200) := 'レコードが存在しないため当月営業員ノルマ金額と訪問ノルマに0をセットしました。';
  cv_debug_msg13          CONSTANT VARCHAR2(200) := 'レコードが存在しないため翌月営業員ノルマ金額と訪問ノルマに0をセットしました。';
  cv_debug_sls_amtnext    CONSTANT VARCHAR2(200) :=  '翌月営業員ノルマ金額：';
  cv_debug_vis_amtnext    CONSTANT VARCHAR2(200) := '翌月訪問ノルマ：';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< 例外処理内でCSVファイルをクローズしました >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< カーソルをオープンしました >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others例外';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
  cv_debug_msg14          CONSTANT VARCHAR2(200) := '売上目標データ作成処理開始';
  cv_debug_msg15          CONSTANT VARCHAR2(200) := '売上目標データ作成処理終了';
  cv_debug_msg16          CONSTANT VARCHAR2(200) := '実績取得処理';
  cv_debug_msg17          CONSTANT VARCHAR2(200) := '目標のみ取得処理';
  cv_debug_msg18          CONSTANT VARCHAR2(200) := '月初表示用目標の取得処理';
  cv_debug_msg19          CONSTANT VARCHAR2(200) := 'ＣＳＶ出力処理';
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand       UTL_FILE.FILE_TYPE;
--
  gv_closed_id           VARCHAR2(10);        -- クローズID
  gd_process_date        DATE;                -- 業務処理日
  gd_process_date_next   DATE;                -- 業務処理日翌日
  /* 2009.10.19 K.Kubo T4_00046対応 START */
  gv_duty_cd             VARCHAR2(30);        -- 職務コード
  gv_duty_cd_vl          VARCHAR2(30);        -- 職務コード名
  /* 2009.10.19 K.Kubo T4_00046対応 END */
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
  gv_err_tkn_val_01      VARCHAR2(100);       -- 売上目標ワークテーブル
  gv_keeping_month       VARCHAR2(6);         -- 営業成績表の保持期間(YYYYMM形式)
  gv_log_control_flag    VARCHAR2(1);         -- 終了時のログ制御用
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 取得情報格納レコード型定義
--
  -- 営業員管理(ファイル)情報ワークテーブルデータ
  TYPE g_prsncd_data_rtype IS RECORD(
    base_code           xxcso_sls_prsn_mnthly_plns.base_code%TYPE,                 -- 拠点ＣＤ
    employee_number     xxcso_sls_prsn_mnthly_plns.employee_number%TYPE,           -- 営業員ＣＤ
    pure_amount_sum     xxcos_sales_exp_headers.pure_amount_sum%TYPE,              -- 販売実績金額
    sls_amt             xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_total_amt%TYPE,  -- 当月営業員ノルマ金額
    sls_next_amt        xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_total_amt%TYPE,  -- 翌月営業員ノルマ金額
    vis_amt             xxcso_sls_prsn_mnthly_plns.vis_prsn_total_amt%TYPE,        -- 当月訪問ノルマ
    vis_next_amt        xxcso_sls_prsn_mnthly_plns.vis_prsn_total_amt%TYPE,        -- 翌月訪問ノルマ
    person_id           xxcso_resources_v.person_id%TYPE,                          -- 従業員ID
    resource_id         xxcso_resources_v.resource_id%TYPE,                        -- リソースID
    full_name           xxcso_resources_v.full_name%TYPE,                          -- 営業員氏名
    prsn_total_cnt      NUMBER(10)                                                 -- 当月訪問実績
  );
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
  -- 営業員売上目標の日数データ
  TYPE g_date_cnt_rtype IS RECORD(
    actual_day_cnt      NUMBER,                                                    -- 実働日数
    passed_day_cnt      NUMBER                                                     -- 経過日数
  );
  -- 売上目標ワークテーブル
  TYPE g_sales_target_rtype IS RECORD(
    base_code               xxcso_wk_sales_target.base_code%TYPE,                  --拠点コード
    employee_code           xxcso_wk_sales_target.employee_code%TYPE,              --営業員コード
    sale_amount_month_sum   xxcso_wk_sales_target.sale_amount_month_sum%TYPE,      --実績金額
    target_amount           xxcso_wk_sales_target.target_amount%TYPE,              --目標金額
    target_management_code  xxcso_wk_sales_target.target_management_code%TYPE,     --目標管理項目コード
    target_month            xxcso_wk_sales_target.target_month%TYPE,               --年月
    actual_day_cnt          xxcso_wk_sales_target.actual_day_cnt%TYPE,             --実働日数
    passed_day_cnt          xxcso_wk_sales_target.passed_day_cnt%TYPE              --経過日数
  );
--
  --テーブル型定義
  TYPE g_date_cnt_ttype IS TABLE OF g_date_cnt_rtype INDEX BY VARCHAR2(6);
  g_date_cnt_tab        g_date_cnt_ttype;
  /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';              -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_appl_short_name      CONSTANT VARCHAR2(10)      := 'XXCCP';             -- アプリケーション短縮名
    cv_tkn_number_17        CONSTANT VARCHAR2(100)     := 'APP-XXCCP1-90008';  -- コンカレント入力テータなし
    -- *** ローカル変数 ***
    ld_process_date DATE;             -- 業務処理日付格納用
    lv_noprm_msg    VARCHAR2(4000);   -- コンカレント入力パラメータなしメッセージ格納用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================================
    -- 入力パラメータなしメッセージ出力 
    -- =======================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name --       -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_17            -- メッセージコード
                      );
    -- メッセージ出力
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => ''           || CHR(10) ||     -- 空行の挿入
                lv_noprm_msg || CHR(10) ||
                 ''                            -- 空行の挿入
    );
--
    -- ===========================
    -- 業務処理日付取得処理 
    -- ===========================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
  -- *** DEBUG_LOG ***
    fnd_file.put_line(
      which  => FND_FILE.LOG,
      buff   => cv_prg_name || cv_msg_part ||
                cv_debug_msg8 || ld_process_date || CHR(10) ||
                ''
    );
--
    -- 業務処理日付取得に失敗した場合
    IF (ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name              --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_01         --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- 業務処理日付を設定
    gd_process_date        := ld_process_date;
    -- 業務処理日翌日を設定
    gd_process_date_next   := gd_process_date+1;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_csv_dir        OUT NOCOPY VARCHAR2  -- CSVファイル出力先
   ,ov_csv_nm         OUT NOCOPY VARCHAR2  -- CSVファイル名
   ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
   ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
   ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
  -- ===============================
  -- 固定ローカル定数
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_profile_info';     -- プログラム名
  --
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  -- ===============================
  -- ユーザー宣言部
  -- ===============================
  -- *** ローカル定数 ***
  -- プロファイル名
    cv_csv_dir        CONSTANT VARCHAR2(30)   := 'XXCSO1_HHT_OUT_CSV_DIR';
  -- XXCSO:HHT連携用CSVファイル出力先
    cv_csv_sls_mng    CONSTANT VARCHAR2(30)   := 'XXCSO1_HHT_OUT_CSV_SALES_MNG';
  -- XXCSO:HHT連携用CSVファイル名(営業員管理ファイル)
    cv_closed_id      CONSTANT VARCHAR2(30)   := 'XXCSO1_TASK_STATUS_CLOSED_ID';
  -- XXCSO:タスクステータス(クローズ)ID    
--
  -- *** ローカル変数 ***    
    lv_csv_dir        VARCHAR2(2000);   -- CSVファイル出力先
    lv_csv_nm         VARCHAR2(2000);   -- CSVファイル名
    lv_closed_id      VARCHAR2(2000);   -- クローズのタスクステータスID(固定)
    lv_msg            VARCHAR2(4000);   -- 取得データメッセージ出力用
    lv_tkn_value      VARCHAR2(1000);   -- プロファイル値取得失敗時 トークン値格納用  
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================
    -- 変数初期化処理 
    -- ====================
    lv_tkn_value := NULL;
--
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    FND_PROFILE.GET(
                    cv_csv_dir
                   ,lv_csv_dir
                   ); -- CSVファイル出力先
    FND_PROFILE.GET(
                    cv_csv_sls_mng
                   ,lv_csv_nm
                   ); -- CSVファイル名
    FND_PROFILE.GET(
                    cv_closed_id
                   ,gv_closed_id
                    ); --クローズのタスクステータスID(固定)
--
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_csv_dir || CHR(10) ||
                 cv_debug_msg3  || lv_csv_nm  || CHR(10) ||
                 cv_debug_msg4  || gv_closed_id || CHR(10) ||
                 ''
    );
--  
    -- 取得したCSVファイル名をメッセージ出力する
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name           --アプリケーション短縮名
                ,iv_name         => cv_tkn_number_08      --メッセージコード
                ,iv_token_name1  => cv_tkn_csv_fnm        --トークンコード1
                ,iv_token_value1 => lv_csv_nm             --トークン値1
              );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                   -- 空行の挿入
    );
--
    -- プロファイル値取得に失敗した場合
    -- CSVファイル出力先取得失敗時
    IF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_csv_dir;
    -- CSVファイル名取得失敗時
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_csv_sls_mng;
    -- クローズのタスクステータスID取得失敗時
    ELSIF (gv_closed_id IS NULL) THEN
      lv_tkn_value := cv_closed_id;
    END IF;
    -- エラーメッセージ取得
    IF lv_tkn_value IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02             -- メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm               -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                 -- トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;  
--
    -- 取得したプロファイル値をOUTパラメータに設定
    ov_csv_dir        :=  lv_csv_dir;          -- CSVファイル出力先
    ov_csv_nm         :=  lv_csv_nm;           -- CSVファイル名
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : CSVファイルオープン (A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     iv_csv_dir        IN  VARCHAR2  -- CSVファイル出力先
    ,iv_csv_nm         IN  VARCHAR2  -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_w            CONSTANT VARCHAR2(1) := 'w';
--
    -- *** ローカル変数 ***
    -- ファイル存在チェック戻り値用
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ========================
    -- CSVファイル存在チェック 
    -- ========================
--
    -- CSVファイル存在チェック
    UTL_FILE.FGETATTR(
       location    => iv_csv_dir              -- CSVファイル格納先ディレクト
      ,filename    => iv_csv_nm               -- CSVファイル名(営業員管理ファイル)  
      ,fexists     => lb_retcd                -- 戻り値：「TRUE」OR「FALSE」
      ,file_length => ln_file_size            -- 戻り値：ファイルサイズ
      ,block_size  => ln_block_size           -- 戻り値：ファイルのブロックサイズ
    );
--
    -- すでにファイルが存在した場合
    IF (lb_retcd = cb_true ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_05             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_csv_loc               -- トークンコード1
                     ,iv_token_value1 => iv_csv_dir                   -- トークン値1
                     ,iv_token_name2  => cv_tkn_csv_fnm               -- トークンコード1
                     ,iv_token_value2 => iv_csv_nm                    -- トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSVファイルオープン 
    -- ========================
    BEGIN
      -- ファイルオープン
      gf_file_hand := UTL_FILE.FOPEN(
                         location   => iv_csv_dir     -- CSVファイル格納先ディレクト
                        ,filename   => iv_csv_nm      -- CSVファイル名(営業員管理ファイル) 
                        ,open_mode  => cv_w           -- オープンモード（書き込み）
                      );
      -- *** DEBUG_LOG ***
      -- ファイルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg9   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH         OR     -- ファイルパス不正エラー
           UTL_FILE.INVALID_MODE         OR     -- open_modeパラメータ不正エラー
           UTL_FILE.INVALID_OPERATION    OR     -- オープン不可能エラー
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_03     --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc       --トークンコード1
                      ,iv_token_value1 => iv_csv_dir           --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --トークンコード1
                      ,iv_token_value2 => iv_csv_nm            --トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err1 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err2 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : get_sum_cnt_data
   * Description      : CSVファイルに出力する関連情報取得 (A-5)
  ***********************************************************************************/
  PROCEDURE get_sum_cnt_data(
     io_prsncd_data_rec   IN OUT NOCOPY g_prsncd_data_rtype   -- 出力する関連情報格納
    ,ov_errbuf               OUT NOCOPY VARCHAR2              -- エラー・メッセージ           --# 固定 #
    ,ov_retcode              OUT NOCOPY VARCHAR2              -- リターン・コード             --# 固定 #
    ,ov_errmsg               OUT NOCOPY VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_sum_cnt_data';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    cv_table_name_xrcv     CONSTANT VARCHAR2(100) := '営業員担当顧客ビュー';     -- 営業員担当顧客ビュー名
    cv_table_name_xseh     CONSTANT VARCHAR2(100) := '販売実績ヘッダテーブル';   -- 販売実績ヘッダテーブル名
    cv_table_name_jtb      CONSTANT VARCHAR2(100) := 'タスクテーブル';           -- タスクテーブル
    /* 2009.11.23 T.Maruyama E_本番_00331対応 START */
    ct_prof_electric_fee_item_cd
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
    /* 2009.11.23 T.Maruyama E_本番_00331対応 END */    
    -- *** ローカル変数 ***
--
    lt_pure_amount_sum     xxcos_sales_exp_headers.pure_amount_sum%TYPE;     -- 販売実績金額
    lt_resource_id         xxcso_resources_v.resource_id%TYPE;               -- リソースID
    lt_prsn_total_cnt      NUMBER(10);                                       -- 当月訪問実績
    lt_process_back_date   DATE;                                             -- 業務処理日前日
    ld_process_date_next01 DATE;                                             -- 業務処理日翌日年月の初日
    ln__closed_id          NUMBER;                                           -- クローズIDを型変化
--
    -- *** ローカル・レコード ***
    l_prsncd_data_rec  g_prsncd_data_rtype; 
-- INパラメータ.出力するテータをワークテーブルデータ格納
    -- *** ローカル・例外 ***
    error_expt      EXCEPTION;            -- データ抽出エラー例外
-- 
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- INパラメータをレコード変数に代入
    l_prsncd_data_rec      := io_prsncd_data_rec;
    -- A-4で抽出テータをワークテーブル抽出データをローカル変数に代入
    lt_pure_amount_sum     := 0;                                -- 販売実績金額 
    lt_prsn_total_cnt      := 0;                                -- 当月訪問実績
    lt_resource_id         := io_prsncd_data_rec.resource_id;   -- リソースID
    /* 2009.11.23 T.Maruyama E_本番_00331対応 START */    
--    lt_process_back_date   := gd_process_date - 1;              -- 業務処理日前日
--    ld_process_date_next01 := TO_DATE(TO_CHAR(gd_process_date_next, 'YYYYMM') || '01', 'YYYY/MM/DD'); 
    lt_process_back_date   := gd_process_date;                  -- 業務処理日（当日分まで）
    ld_process_date_next01 := TO_DATE(TO_CHAR(gd_process_date_next, 'YYYYMM') || '01', 'YYYYMMDD'); 
    /* 2009.11.23 T.Maruyama E_本番_00331対応 END */    
    ln__closed_id          := TO_NUMBER(gv_closed_id);
--
    -- 販売売り上げビュー、顧客マスタビューから販売実績金額を抽出する
    BEGIN
      /* 2009.11.23 T.Maruyama E_本番_00331対応 START */
--      SELECT  ROUND(SUM(sfpv.pure_amount)/1000) pure_amount_sum  -- 販売実績金額(千円単位に取得)
--        INTO  lt_pure_amount_sum                                 -- 販売実績金額
--        FROM  xxcso_sales_for_sls_prsn_v sfpv                    -- 営業員用売上実績ビュー
--             ,xxcso_resource_custs_v xrcv                        -- 営業員担当顧客ビュー
--       WHERE  sfpv.account_number   = xrcv.account_number
--         AND  xrcv.employee_number  = l_prsncd_data_rec.employee_number
--         AND  gd_process_date_next BETWEEN TRUNC(xrcv.start_date_active) 
--                AND TRUNC(NVL(xrcv.end_date_active,gd_process_date_next))
--         AND  TRUNC(sfpv.delivery_date) BETWEEN ld_process_date_next01
--                AND lt_process_back_date;

        --販売実績テーブルの成績計上者が当該営業員のデータを抽出する。
        SELECT ROUND(sum(sael.pure_amount) /1000) pure_amount_sum  -- 販売実績金額(千円単位に取得)
        INTO   lt_pure_amount_sum
        FROM  xxcos_sales_exp_headers       saeh,
              xxcos_sales_exp_lines         sael
        WHERE sael.sales_exp_header_id      =       saeh.sales_exp_header_id
        AND   sael.item_code                <>      FND_PROFILE.VALUE( ct_prof_electric_fee_item_cd ) --売上に含まない
        AND   saeh.sales_base_code       = l_prsncd_data_rec.base_code       --拠点CD
        AND   saeh.results_employee_code = l_prsncd_data_rec.employee_number --成績計上者：従業員CD
        AND   saeh.delivery_date BETWEEN ld_process_date_next01
                                     AND lt_process_back_date
        ;
      /* 2009.11.23 T.Maruyama E_本番_00331対応 END */
--
      --INレコードに格納
      IF (lt_pure_amount_sum IS NULL) THEN
        lt_pure_amount_sum := 0;
      END IF;
--
      io_prsncd_data_rec.pure_amount_sum := lt_pure_amount_sum;
--
      -- *** DEBUG_LOG ***
      -- 販売実績をログに出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_sum   || lt_pure_amount_sum || CHR(10) || ''
      );
--
    --レコード存在チェック
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_pure_amount_sum := 0;  -- レコードがない場合０を代入する
        io_prsncd_data_rec.pure_amount_sum := lt_pure_amount_sum;
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_debug_msg10 || CHR(10) ||
                   ''
        );
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06                     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                           -- トークン値1
                       ,iv_token_value1 => cv_table_name_xseh || '、' || cv_table_name_xrcv  -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_errmsg                        --トークンコード2
                       ,iv_token_value2 => SQLERRM                              --トークン値2
                       ,iv_token_name3  => cv_tkn_duty_cd                       -- トークンコード3
                       /* 2009.10.19 K.Kubo T4_00046対応 START */
                       --,iv_token_value3 => cv_duty_cd                           -- 職務コード
                       ,iv_token_value3 => gv_duty_cd                           -- 職務コード
                       /* 2009.10.19 K.Kubo T4_00046対応 END */
                       ,iv_token_name4  => cv_tkn_ymd                           -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(gd_process_date,'YYYYMMDD')  -- 業務処理日
                       ,iv_token_name5  => cv_tkn_loc_cd                        -- トークンコード5
                       ,iv_token_value5 => io_prsncd_data_rec.base_code         -- A-4で抽出した拠点コード
                       ,iv_token_name6  => cv_tkn_sales_cd                      -- トークンコード6
                       ,iv_token_value6 => io_prsncd_data_rec.employee_number   -- A-4で抽出した営業員コード
                       ,iv_token_name7  => cv_tkn_sales_nm                      -- トークンコード7
                       ,iv_token_value7 => io_prsncd_data_rec.full_name         -- 営業員名称
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE error_expt;
    END;
--
    -- 当月訪問実績データを取得
    BEGIN
     SELECT  COUNT(*) prsn_total_cnt  -- 当月訪問実績
       INTO  lt_prsn_total_cnt        -- 当月訪問実績
       FROM  jtf_tasks_b jtb          -- タスクテーブル
      WHERE  jtb.source_object_type_code = cv_object_cd
        AND  jtb.task_status_id          = ln__closed_id
        AND  jtb.deleted_flag            = cv_delete_flag
        AND  TRUNC(jtb.actual_end_date) BETWEEN ld_process_date_next01
               AND lt_process_back_date
        AND  jtb.owner_type_code         = cv_owner_type_code
        AND  jtb.owner_id                = lt_resource_id;
--
      --当月訪問実績データ件数INレコードに格納
      io_prsncd_data_rec.prsn_total_cnt  := lt_prsn_total_cnt;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_cnt   || lt_prsn_total_cnt || CHR(10) ||
                   ''
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06                     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                           -- トークン値1
                       ,iv_token_value1 => cv_table_name_jtb                    -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_errmsg                        --トークンコード2
                       ,iv_token_value2 => SQLERRM                              --トークン値2
                       ,iv_token_name3  => cv_tkn_duty_cd                       -- トークンコード3
                       /* 2009.10.19 K.Kubo T4_00046対応 START */
                       --,iv_token_value3 => cv_duty_cd                           -- 職務コード
                       ,iv_token_value3 => gv_duty_cd                           -- 職務コード
                       /* 2009.10.19 K.Kubo T4_00046対応 END */
                       ,iv_token_name4  => cv_tkn_ymd                           -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(gd_process_date,'YYYYMMDD')  -- 業務処理日
                       ,iv_token_name5  => cv_tkn_loc_cd                        -- トークンコード5
                       ,iv_token_value5 => io_prsncd_data_rec.base_code         -- A-4で抽出した拠点コード
                       ,iv_token_name6  => cv_tkn_sales_cd                      -- トークンコード6
                       ,iv_token_value6 => io_prsncd_data_rec.employee_number   -- A-4で抽出した営業員コード
                       ,iv_token_name7  => cv_tkn_sales_nm                      -- トークンコード7
                       ,iv_token_value7 => io_prsncd_data_rec.full_name         -- 営業員名称
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE error_expt;
    END;
    
--
  EXCEPTION
    -- *** データ抽出時の例外ハンドラ ***
    WHEN error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;  
--#####################################  固定部 START ##########################################
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sum_cnt_data;

 /**********************************************************************************
   * Procedure Name   : get_prsncd_data
   * Description      : 営業員管理データを抽出 (A-6)
   ***********************************************************************************/
  PROCEDURE get_prsncd_data(
     io_prsncd_data_rec   IN OUT NOCOPY g_prsncd_data_rtype -- 出力する関連情報格納
    ,ov_errbuf               OUT NOCOPY VARCHAR2            -- エラー・メッセージ           --# 固定 #
    ,ov_retcode              OUT NOCOPY VARCHAR2            -- リターン・コード             --# 固定 #
    ,ov_errmsg               OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_prsncd_data';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_table_name_xdmp   CONSTANT VARCHAR2(100) := '拠点別月別計画テーブル';       -- 拠点別月別計画テーブル名
    cv_table_name_xspmp  CONSTANT VARCHAR2(100) := '営業員別月別計画テーブル';     -- 営業員別月別計画テーブル
--  
    -- *** ローカル変数 ***
    lt_sls_amt             xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_total_amt%TYPE;   -- 当月営業員ノルマ金額
    lt_sls_next_amt        xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_total_amt%TYPE;   -- 翌月営業員ノルマ金額
    lt_vis_amt             xxcso_sls_prsn_mnthly_plns.vis_prsn_total_amt%TYPE;         -- 当月訪問ノルマ
    lt_vis_next_amt        xxcso_sls_prsn_mnthly_plns.vis_prsn_total_amt%TYPE;         -- 翌月訪問ノルマ
    lt_year                xxcso_dept_monthly_plans.fiscal_year%TYPE;                  -- 年度格納
    lt_year_next           xxcso_dept_monthly_plans.fiscal_year%TYPE;                  -- 年度格納
    lt_employee_number     xxcso_sls_prsn_mnthly_plns.employee_number%TYPE;            -- 営業員コード
    lv_year_month          VARCHAR2(6);                                                -- 年月
    lv_year_month_next     VARCHAR2(6);                                                -- 年月
    lt_base_code           xxcso_sls_prsn_mnthly_plns.base_code%TYPE;                  -- 拠点コード
--    
    -- *** ローカル・レコード ***
    l_prsncd_data_rec  g_prsncd_data_rtype; 
-- INパラメータ.出力するテータをワークテーブルデータ格納
    -- *** ローカル・例外 ***
    warning_expt      EXCEPTION;            -- NOFOUND警告例外
-- 
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- INパラメータをレコード変数に代入
    l_prsncd_data_rec  := io_prsncd_data_rec;
    -- 業務処理日当月の年月をセット
    lv_year_month      := TO_CHAR(gd_process_date_next,'YYYYMM');
    lv_year_month_next := TO_CHAR(ADD_MONTHS(gd_process_date_next,1),'YYYYMM');
    -- 業務処理日当月の年度取得
    lt_year            := TO_CHAR(xxcso_util_common_pkg.get_business_year(lv_year_month));
    lt_year_next       := TO_CHAR(xxcso_util_common_pkg.get_business_year(lv_year_month_next));
--  
    -- 当月営業員別月別計画テータを抽出する
    BEGIN
      SELECT xspmp.base_code base_code                               -- 拠点コード
            ,xspmp.employee_number employee_number                   -- 営業員コード
            ,DECODE(xdmp.sales_plan_rel_div
              ,'1', xspmp.tgt_sales_prsn_total_amt
              ,'2', xspmp.bsc_sls_prsn_total_amt) sls_prsn_total_amt -- 当月営業員ノルマ金額
            ,xspmp.vis_prsn_total_amt vis_prsn_total_amt             -- 当月訪問ノルマ
      INTO   lt_base_code                                            -- 拠点コード
            ,lt_employee_number                                      -- 営業員コード
            ,lt_sls_amt                                              -- 当月営業員ノルマ金額
            ,lt_vis_amt                                              -- 当月訪問ノルマ
      FROM   xxcso_dept_monthly_plans xdmp                           -- 拠点別月別計画テーブル
            ,xxcso_sls_prsn_mnthly_plns xspmp                        -- 営業員別月別計画テーブル
      WHERE  xdmp.base_code         = xspmp.base_code 
        AND  xdmp.year_month        = xspmp.year_month
        AND  xdmp.fiscal_year       = lt_year
        AND  xspmp.base_code        = io_prsncd_data_rec.base_code
        AND  xspmp.employee_number  = io_prsncd_data_rec.employee_number
        AND  xspmp.year_month       = lv_year_month;
--
      --OUTレコードに格納
      io_prsncd_data_rec.sls_amt   := lt_sls_amt;
      io_prsncd_data_rec.vis_amt   := lt_vis_amt;
      -- *** DEBUG_LOG ***
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name || CHR(10) ||
                   cv_debug_base_code || lt_base_code ||
                   cv_debug_em_num    || lt_employee_number ||
                   cv_debug_sls_amt   || lt_sls_amt ||
                   cv_debug_vis_amt   || lt_vis_amt || CHR(10) ||
                   ''
      );
--    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- レコードがない場合０を代入する
        io_prsncd_data_rec.sls_amt := 0;
        io_prsncd_data_rec.vis_amt := 0;
--
        fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
        );
--
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06                      -- メッセージコード
                         ,iv_token_name1  => cv_tkn_tbl                            -- トークン値1
                         ,iv_token_value1 => cv_table_name_xdmp || '、' || cv_table_name_xspmp 
                           -- エラー発生のテーブル名
                         ,iv_token_name2  => cv_tkn_duty_cd                        -- トークンコード2
                         /* 2009.10.19 K.Kubo T4_00046対応 START */
                         --,iv_token_value2 => cv_duty_cd || cv_duty_cd_vl           -- 職務コード 
                         ,iv_token_value2 => gv_duty_cd || gv_duty_cd_vl           -- 職務コード 
                         /* 2009.10.19 K.Kubo T4_00046対応 END */
                         ,iv_token_name3  => cv_tkn_ymd                            -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(gd_process_date,'YYYYMMDD' )  -- 業務処理日
                         ,iv_token_name4  => cv_tkn_sales_cd                       -- トークンコード4
                         ,iv_token_value4 => io_prsncd_data_rec.base_code          -- A-4で抽出した拠点コード
                         ,iv_token_name5  => cv_tkn_sales_cd                       -- トークンコード5
                         ,iv_token_value5 => io_prsncd_data_rec.employee_number    -- A-4で抽出した営業員コード
                         ,iv_token_name6  => cv_tkn_sales_nm                       -- トークンコード6
                         ,iv_token_value6 => io_prsncd_data_rec.full_name          -- 営業員名称
                         ,iv_token_name7  => cv_tkn_errmsg                         -- トークンコード7
                         ,iv_token_value7 => SQLERRM                               -- SQLエラーメッセージ
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
    END;
-- 
    -- 翌月営業員別月別計画テータを抽出する
    BEGIN 
     SELECT  xspmp.base_code                                -- 拠点コード
            ,xspmp.employee_number                          -- 営業員コード
            ,DECODE(xdmp.sales_plan_rel_div
            ,'1', xspmp.tgt_sales_prsn_total_amt
            ,'2' , xspmp.bsc_sls_prsn_total_amt) sls_prsn_total_amt -- 翌月営業員ノルマ金額
            ,xspmp.vis_prsn_total_amt                       -- 翌月訪問ノルマ
       INTO  lt_base_code                                   -- 拠点コード
            ,lt_employee_number                             -- 営業員コード
            ,lt_sls_next_amt                                -- 翌月営業員ノルマ金額
            ,lt_vis_next_amt                                -- 翌月訪問ノルマ
       FROM  xxcso_dept_monthly_plans xdmp                  -- 拠点別月別計画テーブル
            ,xxcso_sls_prsn_mnthly_plns xspmp               -- 営業員別月別計画テーブル
      WHERE  xdmp.base_code         = xspmp.base_code 
        AND  xdmp.year_month        = xspmp.year_month
        AND  xdmp.fiscal_year       = lt_year_next
        AND  xspmp.base_code        = io_prsncd_data_rec.base_code
        AND  xspmp.employee_number  = io_prsncd_data_rec.employee_number
        AND  xspmp.year_month       = lv_year_month_next;
--
      --OUTレコードに格納
      io_prsncd_data_rec.sls_next_amt    := lt_sls_next_amt;
      io_prsncd_data_rec.vis_next_amt    := lt_vis_next_amt;
      -- *** DEBUG_LOG ***
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name || CHR(10) ||
                   cv_debug_base_code || lt_base_code ||
                   cv_debug_em_num    || lt_employee_number ||
                   cv_debug_sls_amtnext   || lt_sls_next_amt ||
                   cv_debug_vis_amtnext   || lt_vis_next_amt || CHR(10) ||
                   ''
      );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- レコードがない場合０を代入する 
        io_prsncd_data_rec.sls_next_amt    := 0;
        io_prsncd_data_rec.vis_next_amt    := 0;
--
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_debug_msg13 || CHR(10) ||
                   ''
        );
--
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06               -- メッセージコード
                         ,iv_token_name1  => cv_tkn_tbl                     -- トークン値1
                         ,iv_token_value1 => cv_table_name_xdmp || '、' || cv_table_name_xspmp 
                           -- エラー発生のテーブル名
                         ,iv_token_name2  => cv_tkn_duty_cd                 -- トークンコード2
                         /* 2009.10.19 K.Kubo T4_00046対応 START */
                         --,iv_token_value2 => cv_duty_cd || cv_duty_cd_vl    -- 職務コード                       
                         ,iv_token_value2 => gv_duty_cd || gv_duty_cd_vl    -- 職務コード                       
                         /* 2009.10.19 K.Kubo T4_00046対応 END */
                         ,iv_token_name3  => cv_tkn_ymd                     -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(gd_process_date,'YYYYMMDD')   -- 業務処理日
                         ,iv_token_name4  => cv_tkn_sales_cd                -- トークンコード4
                         ,iv_token_value4 => io_prsncd_data_rec.base_code   -- A-4で抽出した拠点コード
                         ,iv_token_name5  => cv_tkn_sales_cd                -- トークンコード5
                         ,iv_token_value5 => io_prsncd_data_rec.employee_number    -- A-4で抽出した営業員コード
                         ,iv_token_name6  => cv_tkn_sales_nm                -- トークンコード6
                         ,iv_token_value6 => io_prsncd_data_rec.full_name   -- 営業員名称
                         ,iv_token_name7  => cv_tkn_errmsg                  -- トークンコード7
                         ,iv_token_value7 => SQLERRM                        -- SQLエラーメッセージ
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
      END;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_prsncd_data;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSVファイル出力 (A-7)
  ***********************************************************************************/
  PROCEDURE create_csv_rec(
     ir_prsncd_data_rec  IN g_prsncd_data_rtype    -- 営業員別計画抽出データ
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_sep_com       CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot     CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ローカル変数 ***
    lv_data          VARCHAR2(4000);  -- 編集データ格納
--
    -- *** ローカル・レコード ***
    l_prsncd_data_rec g_prsncd_data_rtype; -- INパラメータ.営業員別計画抽出データ格納
    -- *** ローカル例外 ***
    file_put_line_expt   EXCEPTION;    -- データ出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをレコード変数に格納
    l_prsncd_data_rec := ir_prsncd_data_rec; -- 営業員別計画抽出データ
--
    -- ======================
    -- CSV出力処理 
    -- ======================
    BEGIN 
--
      -- データ作成
      lv_data := cv_sep_wquot || l_prsncd_data_rec.base_code || cv_sep_wquot    -- 拠点コード
        || cv_sep_com || cv_sep_wquot || l_prsncd_data_rec.employee_number || cv_sep_wquot  -- 営業員コード
        || cv_sep_com || l_prsncd_data_rec.pure_amount_sum                      -- 当月販売実績金額
        || cv_sep_com || l_prsncd_data_rec.sls_amt                              -- 当月営業員ノルマ金額
        || cv_sep_com || l_prsncd_data_rec.sls_next_amt                         -- 翌月営業員ノルマ金額
        || cv_sep_com || l_prsncd_data_rec.prsn_total_cnt                       -- 当月訪問実績
        || cv_sep_com || l_prsncd_data_rec.vis_amt                              -- 当月訪問ノルマ
        || cv_sep_com || l_prsncd_data_rec.vis_next_amt ;                       -- 翌月訪問ノルマ
--
      -- データ出力
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand
       ,buffer => lv_data
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- ファイル・ハンドル無効エラー
           UTL_FILE.INVALID_OPERATION  OR     -- オープン不可能エラー
           UTL_FILE.WRITE_ERROR  THEN         -- 書込み操作中オペレーティングエラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                          --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07                     --メッセージコード
                       ,iv_token_name1  => cv_tkn_duty_cd                       -- トークンコード1
                       /* 2009.10.19 K.Kubo T4_00046対応 START */
                       --,iv_token_value1 => cv_duty_cd                           -- 職務コード
                       ,iv_token_value1 => gv_duty_cd                           -- 職務コード
                       /* 2009.10.19 K.Kubo T4_00046対応 END */
                       ,iv_token_name2  => cv_tkn_ymd                           -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gd_process_date,'YYYYMMDD' ) -- 業務処理日
                       ,iv_token_name3  => cv_tkn_loc_cd                      -- トークンコード3
                       ,iv_token_value3 => ir_prsncd_data_rec.base_code         -- A-4で抽出した拠点コード
                       ,iv_token_name4  => cv_tkn_sales_cd                      -- トークンコード4
                       ,iv_token_value4 => ir_prsncd_data_rec.employee_number   -- A-4で抽出した営業員コード
                       ,iv_token_name5  => cv_tkn_sales_nm                      -- トークンコード5
                       ,iv_token_value5 => ir_prsncd_data_rec.full_name         -- 営業員名称
                       ,iv_token_name6  => cv_tkn_errmsg                        -- トークンコード6
                       ,iv_token_value6 => SQLERRM                              -- SQLエラーメッセージ
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_put_line_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSVファイルクローズ処理 (A-8)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSVファイル出力先
    ,iv_csv_nm         IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================
    -- CSVファイルクローズ 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_04             --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                      ,iv_token_value1 => iv_csv_dir                   --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード1
                      ,iv_token_value2 => iv_csv_nm                    --トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END close_csv_file;
--
/* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
  /**********************************************************************************
   * Procedure Name   : get_sum_sls_tgt_data
   * Description      : 売上目標データ初期処理 (A-9)
   ***********************************************************************************/
  PROCEDURE get_sum_sls_tgt_data(
     ov_errbuf         OUT  NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT  NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT  NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sum_sls_tgt_data';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --メッセージ用
    cv_paren1           CONSTANT VARCHAR2(2)  := '( ';    -- 左カッコ
    cv_paren2           CONSTANT VARCHAR2(2)  := ' )';    -- 右カッコ
    -- XXCOS:営業成績集約情報保存期間
    ct_prof_002a03_keeping_period
      CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_002A03_KEEPING_PERIOD';
    -- XXCOS:カレンダコード
    ct_prof_bus_cal_code
      CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BUSINESS_CALENDAR_CODE';
    -- *** ローカル変数 ***
    lv_token_value    VARCHAR2(100);                                       --トークン値取得用
    ln_keeping_period NUMBER;                                              --営業成績集約情報保存期間
    lt_bus_cla_code   fnd_profile_option_values.profile_option_value%TYPE; --カレンダコード
    lv_chk_err_flag   VARCHAR2(1);                                         --チェックエラーフラグ
    ld_first_date     DATE;
    ld_end_date       DATE;
    lv_month          VARCHAR2(6);
    -- *** ローカルカーソル ***
    --参照タイプ項目チェック用カーソル
    CURSOR chk_lookup_cur
    IS
      SELECT   SUBSTRB( flv.lookup_code, 1,9 )  target_management_code -- 目標管理項目コード
      FROM     fnd_lookup_values_vl flv
      WHERE    flv.lookup_type         =  ct_item_group_summary  -- 商品別売上集計マスタ
      AND      flv.attribute3          =  cv_yes                 -- 商品別売上集計マスタの送信データ
      AND      flv.enabled_flag        =  cv_yes                 -- 有効なもののみ
      AND      flv.start_date_active  <= gd_process_date
      AND      (
                 ( flv.end_date_active IS NULL )
                 OR
                 ( LAST_DAY( ADD_MONTHS( flv.end_date_active, 1 ) ) >= gd_process_date )
               )
    ;
    TYPE g_chk_lookup_ttype IS TABLE OF chk_lookup_cur%ROWTYPE INDEX BY PLS_INTEGER;
    g_chk_lookup_tab  g_chk_lookup_ttype;
    -- *** ローカル例外 ***
    lookup_chk_exp    EXCEPTION;
    sls_tgt_data_exp  EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ----------------------------------------------------------------------
    --エラー発生時のトークン値取得
    ----------------------------------------------------------------------
    --売上目標ワークテーブル
    gv_err_tkn_val_01 :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name          -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_value_01      -- メッセージコード
                          );
    ----------------------------------------------------------------------
    --売上目標ワークテーブルのトランケート
    ----------------------------------------------------------------------
    BEGIN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcso.xxcso_wk_sales_target';
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name            -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_11       -- メッセージコード
                      ,iv_token_name1  => cv_tkn_tbl             -- トークンコード1
                      ,iv_token_value1 => gv_err_tkn_val_01      -- トークン値1
                      ,iv_token_name2  => cv_tkn_errmsg          -- トークンコード2
                      ,iv_token_value2 => SQLERRM                -- トークン値2
                     );
        RAISE sls_tgt_data_exp;
    END;
--
    ----------------------------------------------------------------------
    --参照タイプ（商品別売上集計マスタ）の項目チェック
    ----------------------------------------------------------------------
    --初期化
    lv_chk_err_flag := cv_no;
    --データ取得
    OPEN  chk_lookup_cur;
    FETCH chk_lookup_cur BULK COLLECT INTO g_chk_lookup_tab;
    CLOSE chk_lookup_cur;
--
    --チェック
    <<chk_loop>>
    FOR i IN 1..g_chk_lookup_tab.COUNT LOOP
--
      --目標管理項目コード(半角英数)
      IF ( xxccp_common_pkg.chk_number( g_chk_lookup_tab(i).target_management_code ) = FALSE ) THEN
        --エラーフラグを更新
        lv_chk_err_flag := cv_yes;
        --トークン値取得
        lv_token_value := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name_cmm        -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_cmm_01   -- メッセージコード
                          );
        --メッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_ccp        -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_cmm_02   -- メッセージコード
                      ,iv_token_name1  => cv_tkn_item            -- トークンコード1
                      ,iv_token_value1 => lv_token_value
                                          || cv_paren1 || g_chk_lookup_tab(i).target_management_code || cv_paren2 -- トークン値1
                     );
        --メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT --出力
          ,buff   => lv_errmsg       --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG    --ログ
          ,buff => lv_errmsg         --エラーメッセージ
        );
        --警告カウント
        gn_warn_cnt2 := gn_warn_cnt2 + 1;
      END IF;
--
    END LOOP chk_loop;
--
    --配列削除
    g_chk_lookup_tab.DELETE;
--
    --参照タイプのチェックNGの場合、処理終了
    IF ( lv_chk_err_flag = cv_yes ) THEN
      RAISE lookup_chk_exp;
    END IF;
--
    ----------------------------------------------------------------------
    --プロファイルの取得
    ----------------------------------------------------------------------
    --営業成績表保持期間
    ln_keeping_period := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_002a03_keeping_period ) );
    -- プロファイルが取得できない場合はエラー
    IF ( ln_keeping_period IS NULL ) THEN
      --メッセージ生成
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                   -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_14              -- メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm                -- トークンコード1
                    ,iv_token_value1 => ct_prof_002a03_keeping_period -- トークン値1
                   );
      RAISE sls_tgt_data_exp;
    END IF;
    --営業成績表を保持している最小月を取得
    gv_keeping_month  := TO_CHAR( LAST_DAY( ADD_MONTHS( gd_process_date, ln_keeping_period * -1 ) ) + 1, 'YYYYMM');
    --カレンダコード
    lt_bus_cla_code   := FND_PROFILE.VALUE( ct_prof_bus_cal_code );
    -- プロファイルが取得できない場合はエラー
    IF ( lt_bus_cla_code IS NULL ) THEN
      --メッセージ生成
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                   -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_14              -- メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm                -- トークンコード1
                    ,iv_token_value1 => ct_prof_bus_cal_code          -- トークン値1
                   );
      RAISE sls_tgt_data_exp;
    END IF;
--
    ----------------------------------------------------------------------
    --実働日数と経過日数を取得（営業成績表保持期間分）
    ----------------------------------------------------------------------
    --翌月の目標送信対象日の場合、翌月分も取得
    IF ( gd_process_date = LAST_DAY( gd_process_date ) ) THEN
      --翌月の取得設定
      ld_first_date     := TRUNC( gd_process_date + 1, 'MM' );  --翌月1日
      ln_keeping_period := ln_keeping_period + 1;               --営業成績表保持期間 + 1(翌月分)
    ELSE
      --当月の取得設定
      ld_first_date     := TRUNC( gd_process_date, 'MM' );      --当月1日
    END IF;
--
    ld_end_date         := LAST_DAY( ld_first_date );           --上記いずれかの最終日
    lv_month            := TO_CHAR( ld_first_date, 'YYYYMM' );  --配列添え字
--
    <<day_cnt_loop>>
    FOR i IN 1..ln_keeping_period LOOP
--
      BEGIN
        SELECT  SUM(CASE
                      WHEN  cal.seq_num IS NOT NULL
                      THEN  1
                      ELSE  0
                    END)                    AS  actual_day_cnt,
                SUM(CASE 
                      WHEN  cal.seq_num IS NOT NULL
                      AND   cal.calendar_date <= gd_process_date
                      THEN  1
                      ELSE  0
                    END)                    AS  passed_day_cnt
        INTO    g_date_cnt_tab(lv_month).actual_day_cnt
               ,g_date_cnt_tab(lv_month).passed_day_cnt
        FROM    bom_calendar_dates  cal
        WHERE   cal.calendar_code       =       lt_bus_cla_code
        AND     cal.calendar_date       BETWEEN ld_first_date
                                        AND     ld_end_date
        ;
        --取得設定の前月以前
        ld_first_date  := ADD_MONTHS( ld_first_date, -1 );
        ld_end_date    := LAST_DAY( ld_first_date );
        lv_month       := TO_CHAR( ld_first_date, 'YYYYMM' );
--
      EXCEPTION
        WHEN OTHERS THEN
           --トークン値取得
          lv_token_value := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name_cmm        -- アプリケーション短縮名
                             ,iv_name         => cv_tkn_value_02        -- メッセージコード
                            );
          --メッセージ生成
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name       -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_15  -- メッセージコード
                        ,iv_token_name1  => cv_tkn_item       -- トークンコード1
                        ,iv_token_value1 => lv_token_value    -- トークン値1
                        ,iv_token_name2  => cv_tkn_err_msg    -- トークンコード2
                        ,iv_token_value2 => SQLERRM           -- トークン値2
                       );
          RAISE sls_tgt_data_exp;
      END;
--
    END LOOP day_cnt_loop;
--
  EXCEPTION
--
    -- *** 参照タイプチェックエラー *** --
    WHEN lookup_chk_exp THEN
--
      --終了時ログ出力
      gv_log_control_flag := 'N';
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
--
    -- *** データ取得エラー *** --
    WHEN sls_tgt_data_exp THEN
--
      --警告カウント
      gn_warn_cnt2 := 1;
      --終了時ログ出力
      gv_log_control_flag := 'Y';
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,4000);
      ov_retcode   := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
--
      --警告カウント
      gn_warn_cnt2 := 1;
      --終了時ログ出力
      gv_log_control_flag := 'Y';
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode   := cv_status_warn;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      --警告カウント
      gn_warn_cnt2 := 1;
      --終了時ログ出力
      gv_log_control_flag := 'Y';
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode   := cv_status_warn;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      --警告カウント
      gn_warn_cnt2 := 1;
      --終了時ログ出力
      gv_log_control_flag := 'Y';
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_warn;
--
--#####################################  固定部 END   ##########################################
--
  END get_sum_sls_tgt_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_results
   * Description      : 実績データワークテーブル格納 (A-11)
   ***********************************************************************************/
  PROCEDURE ins_work_results(
     i_sales_target_rec  IN  g_sales_target_rtype        -- 売上目標ワークテーブル
    ,ov_errbuf           OUT NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_results';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_msg_tkn_value1 VARCHAR2(100);
    lv_msg_tkn_value2 VARCHAR2(100);
    -- *** ローカル例外 ***
    work_results_ins_exp EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------
    -- ワークテーブル格納
    ------------------------------
    BEGIN
      INSERT INTO xxcso_wk_sales_target(
         base_code              --拠点コード
        ,employee_code          --営業員コード
        ,sale_amount_month_sum  --実績金額
        ,target_amount          --目標金額
        ,target_management_code --目標管理項目コード
        ,target_month           --年月
        ,actual_day_cnt         --実働日数
        ,passed_day_cnt         --経過日数
        ,created_by             --作成者
        ,creation_date          --作成日
        ,last_updated_by        --最終更新者
        ,last_update_date       --最終更新日
        ,last_update_login      --最終更新ログイン
        ,request_id             --要求ID
        ,program_application_id --コンカレント・プログラム・アプリケーションID
        ,program_id             --コンカレント・プログラムID
        ,program_update_date    --プログラム更新日
      ) VALUES (
         i_sales_target_rec.base_code               --拠点コード
        ,i_sales_target_rec.employee_code           --営業員コード
        ,i_sales_target_rec.sale_amount_month_sum   --実績金額
        ,i_sales_target_rec.target_amount           --目標金額
        ,i_sales_target_rec.target_management_code  --目標管理項目コード
        ,i_sales_target_rec.target_month            --年月
        ,i_sales_target_rec.actual_day_cnt          --実働日数
        ,i_sales_target_rec.passed_day_cnt          --経過日数
        ,cn_created_by                              --作成者
        ,cd_creation_date                           --作成日
        ,cn_last_updated_by                         --最終更新者
        ,cd_last_update_date                        --最終更新日
        ,cn_last_update_login                       --最終更新ログイン
        ,cn_request_id                              --要求ID
        ,cn_program_application_id                  --コンカレント・プログラム・アプリケーションID
        ,cn_program_id                              --コンカレント・プログラムID
        ,cd_program_update_date                     --プログラム更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_12         --メッセージコード
                      ,iv_token_name1  => cv_tkn_tbl               --トークンコード1
                      ,iv_token_value1 => gv_err_tkn_val_01        --トークン値1
                      ,iv_token_name2  => cv_tkn_errmsg            --トークンコード2
                      ,iv_token_value2 => SQLERRM                  --トークン値2
                     );
        RAISE work_results_ins_exp;
    END;
--
  EXCEPTION
--
    WHEN work_results_ins_exp THEN
--
      --警告カウント
      gn_warn_cnt2 := 1;
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,4000);
      ov_retcode   := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
--
      --警告カウント
      gn_warn_cnt2 := 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_warn;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      --警告カウント
      gn_warn_cnt2 := 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_warn;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      --警告カウント
      gn_warn_cnt2 := 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_warn;
--
--#####################################  固定部 END   ##########################################
--
  END ins_work_results;
--
/* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    /* 2010.08.26 K.Kiriu E_本番_04153対応 START */
    -- *** ローカル定数 ***
    ct_prof_electric_fee_item_cd
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
    /* 2010.08.26 K.Kiriu E_本番_04153対応 END */
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
    ct_base_code
    CONSTANT  xxcso_wk_sales_target.base_code%TYPE         := '0';
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
    -- *** ローカル変数 ***
    -- OUTパラメータ格納用
    lv_csv_dir           VARCHAR2(2000); -- CSVファイル出力先
    lv_csv_nm            VARCHAR2(2000); -- CSVファイル名
    lb_fopn_retcd        BOOLEAN;        -- ファイルオープン確認戻り値格納
    lv_err_rec_info      VARCHAR2(5000); -- データ項目内容メッセージ出力用
    lv_process_date_next VARCHAR2(150);  -- データ項目内容メッセージ出力用 
    /* 2010.08.26 K.Kiriu E_本番_04153対応 START */
    -- カーソル条件用
    lt_elextric_item_cd    xxcos_sales_exp_lines.item_code%TYPE; -- 変動電気代品目コード(プロファイル値)格納用
    ln_closed_id           NUMBER;                               -- クローズID格納用
    ld_process_date_next01 DATE;                                 -- 業務日翌日の月初日格納用
    /* 2010.08.26 K.Kiriu E_本番_04153対応 END */
    
--
-- *** ローカル・カーソル ***
    -- 営業員コード、拠点コード、リソースIDの取得を行うカーソルの定義
    CURSOR xrv_v_cur
    IS
      SELECT xrv.employee_number  employee_number  -- 営業員コード
             /* 2009.05.20 K.Satomura T1_1082対応 START */
              --(CASE WHEN xrv.issue_date <= lv_process_date_next THEN
              --        xrv.work_dept_code_new
              --      WHEN lv_process_date_next < xrv.issue_date THEN
              --        xrv.work_dept_code_old
              --      END
              -- ) work_base_code                      -- 拠点コード
             ,xxcso_util_common_pkg.get_rs_base_code(
                 xrv.resource_id
                ,gd_process_date_next
             ) work_base_code                        -- 拠点コード
             /* 2009.05.20 K.Satomura T1_1082対応 END */
             ,xrv.resource_id resource_id            -- リソースID
             ,xrv.full_name full_name                -- 営業員名称 
             /* 2009.10.19 K.Kubo T4_00046対応 START */
             ,(CASE WHEN  (xrv.issue_date          <= lv_process_date_next
                         AND TRIM(xrv.duty_code_new) IN (cv_duty_cd, cv_duty_cd_050))
                    THEN
                      TRIM(xrv.duty_code_new)
                    WHEN  (lv_process_date_next    <  xrv.issue_date
                         AND TRIM(xrv.duty_code_old) IN (cv_duty_cd, cv_duty_cd_050))
                    THEN
                      TRIM(xrv.duty_code_old)
                    ELSE
                      NULL
                    END
              ) duty_code                            -- 業務コード
             /* 2009.10.19 K.Kubo T4_00046対応 END */
             /* 2010.08.26 K.Kiriu E_本番_04153対応 START */
             ,NVL(se_amt.pure_amount_sum ,0)     pure_amount_sum
             ,NVL(jtb_cnt.prsn_total_cnt ,0)     prsn_total_cnt
             /* 2010.08.26 K.Kiriu E_本番_04153対応 END */
      FROM   xxcso_resources_v  xrv                  -- リソースマスタビュー
            /* 2009.06.03 K.Satomura T1_1304対応 START */
            ,(
               SELECT per.person_id                 person_id
                     ,MAX(per.effective_start_date) max_effective_start_date
               FROM   per_people_f per
                     /* 2009.06.03 K.Satomura T1_1304対応(再修正) START */
                     ,per_assignments_f paf
                     /* 2009.06.03 K.Satomura T1_1304対応(再修正) END */
               WHERE  per.effective_start_date <= gd_process_date_next
               /* 2009.06.03 K.Satomura T1_1304対応(再修正) START */
               AND    per.person_id            =  paf.person_id
               AND    per.effective_start_date =  paf.effective_start_date
               /* 2009.06.03 K.Satomura T1_1304対応(再修正) END */
               GROUP BY per.person_id
             ) ppf
            /* 2009.06.03 K.Satomura T1_1304対応 END */
      /* 2009.10.19 K.Kubo T4_00046対応 START */
      --  WHERE  (
      --               xrv.issue_date          <= lv_process_date_next
      --           AND TRIM(xrv.duty_code_new) =  cv_duty_cd
      --           OR  lv_process_date_next    <  xrv.issue_date
      --           AND TRIM(xrv.duty_code_old) =  cv_duty_cd
      --         )
            /* 2010.08.26 K.Kiriu E_本番_04153対応 START */
            ,(
              SELECT /*+
                       USE_NL(saeh sael)
                       INDEX(saeh xxcos_sales_exp_headers_n11)
                     */
                     saeh.sales_base_code        sales_base_code
                    ,saeh.results_employee_code  results_employee_code
                    ,ROUND(SUM(sael.pure_amount) /1000) pure_amount_sum   -- 販売実績金額(千円単位に取得)
              FROM   xxcos_sales_exp_headers  saeh,
                     xxcos_sales_exp_lines    sael
              WHERE  sael.sales_exp_header_id      =  saeh.sales_exp_header_id
              AND    sael.item_code                <> lt_elextric_item_cd -- 変動電気代(プロファイル)
              AND    saeh.delivery_date BETWEEN ld_process_date_next01
                                            AND gd_process_date
              GROUP BY
                     saeh.sales_base_code
                    ,saeh.results_employee_code
             ) se_amt
            ,(
              SELECT /*+
                       INDEX(jtb xxcso_jtf_tasks_b_n20)
                     */
                     jtb.owner_id  owner_id
                    ,COUNT(1)      prsn_total_cnt  -- 当月訪問実績
              FROM   jtf_tasks_b  jtb
              WHERE  jtb.source_object_type_code = cv_object_cd        -- ソースコード:'PARTY'
              AND    jtb.task_status_id          = ln_closed_id        -- クローズID(プロファイル)
              AND    jtb.deleted_flag            = cv_delete_flag      -- 未削除
              AND    TRUNC(jtb.actual_end_date) BETWEEN ld_process_date_next01
                                                    AND gd_process_date
              AND    jtb.owner_type_code         = cv_owner_type_code  -- オーナータイプ:'RS_EMPLOYEE'
              GROUP BY
                     jtb.owner_id
             ) jtb_cnt
             /* 2010.08.26 K.Kiriu E_本番_04153対応 END */
      WHERE  (
                (xrv.issue_date          <= lv_process_date_next
               AND TRIM(xrv.duty_code_new) IN (cv_duty_cd, cv_duty_cd_050))  -- 職務 010：ルートセールスと050：専門百貨店販売
             OR (lv_process_date_next    <  xrv.issue_date
               AND TRIM(xrv.duty_code_old) IN (cv_duty_cd, cv_duty_cd_050))  -- 職務 010：ルートセールスと050：専門百貨店販売
             )
      /* 2009.10.19 K.Kubo T4_00046対応 END */
      /* 2009.06.03 K.Satomura T1_1304対応 START */
      --  AND gd_process_date_next BETWEEN TRUNC(xrv.start_date)
      --        AND TRUNC(NVL(xrv.end_date, gd_process_date_next)) 
      --  AND gd_process_date_next BETWEEN TRUNC(xrv.employee_start_date)
      --        AND TRUNC(NVL(xrv.employee_end_date,gd_process_date_next))
      --  AND gd_process_date_next BETWEEN TRUNC(xrv.assign_start_date)
      --        AND TRUNC(NVL(xrv.assign_end_date,gd_process_date_next))
      --  AND gd_process_date_next BETWEEN TRUNC(xrv.resource_start_date) 
      --        AND TRUNC(NVL(xrv.resource_end_date, gd_process_date_next));
      AND    ppf.person_id = xrv.person_id
      -- ユーザー：従業員最新レコードに紐づく
      AND    ppf.max_effective_start_date BETWEEN TRUNC(xrv.start_date)
      AND    TRUNC(NVL(xrv.end_date, ppf.max_effective_start_date)) -- NVLをMAX開始日
      -- 従業員：リソースに紐づく最新レコード）
      AND    ppf.max_effective_start_date BETWEEN TRUNC(xrv.employee_start_date)
      AND    TRUNC(NVL(xrv.employee_end_date,ppf.max_effective_start_date)) -- NVLをMAX開始日
      -- アサイメント：従業員最新レコードに紐づく
      AND    ppf.max_effective_start_date BETWEEN TRUNC(xrv.assign_start_date)
      AND    TRUNC(NVL(xrv.assign_end_date,ppf.max_effective_start_date)) -- NVLをMAX開始日
        -- リソース：（業務処理日＋１）時点で有効（有効判断はリソースのみ。）
      AND    gd_process_date_next BETWEEN TRUNC(xrv.resource_start_date) -- 基準日で有効判断する。
      AND    TRUNC(NVL(xrv.resource_end_date, gd_process_date_next))
      /* 2010.08.26 K.Kiriu E_本番_04153対応 START */
      AND    se_amt.results_employee_code(+) = xrv.employee_number
      AND    se_amt.sales_base_code(+)       = xxcso_util_common_pkg.get_rs_base_code(
                                                 xrv.resource_id
                                                ,gd_process_date_next)
      AND    jtb_cnt.owner_id(+)             = xrv.resource_id
      /* 2010.08.26 K.Kiriu E_本番_04153対応 END */
      ;
      /* 2009.06.03 K.Satomura T1_1304対応 END */
--
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
    -- 翌月の目標データ(1日にHHTで表示する)の取得を行うカーソルの定義
    CURSOR target_start_cur
    IS
      SELECT /*+
               LEADING(flv)
               USE_NL(flv xstm)
               INDEX(xstm xxcso_sales_target_mst_pk)
             */
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD START */
--              ct_base_code                                      base_code              --拠点コード
              xstm.base_code                                    base_code              --拠点コード
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD END   */
             ,xstm.employee_code                                employee_code          --営業員コード
             ,0                                                 sale_amount_month_sum  --実績金額
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD START */
--             ,ROUND( NVL( xstm.target_amount,0 ) / 1000 )       target_amount          --目標金額
             ,NVL( xstm.target_amount,0 )                       target_amount          --目標金額
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD END   */
             ,xstm.target_management_code                       target_management_code --目標管理項目コード
             ,xstm.target_month                                 target_month           --年月
             ,''                                                actual_day_cnt         --実働日数
             ,''                                                passed_day_cnt         --経過日数
      FROM   xxcso_sales_target_mst  xstm  --売上目標マスタ
            ,fnd_lookup_values_vl    flv   --商品別売上集計マスタ(送信)
      WHERE  flv.lookup_type                               = ct_item_group_summary      --XXCMM1_ITEM_GROUP_SUMMARY
      AND    flv.enabled_flag                              = cv_yes                     --有効のみ
      AND    flv.attribute3                                = cv_yes                     --商品別売上集計マスタの送信データ
      AND    SUBSTRB(flv.lookup_code, 1, 9)                = xstm.target_management_code
      AND    ( TO_DATE( xstm.target_month, 'YYYYMM' ) -1 ) = gd_process_date            --業務日付が目標年月の前日
      AND    (
               ( flv.end_date_active IS NULL )
               OR
               ( TO_CHAR( flv.end_date_active, 'YYYYMM') >= xstm.target_month )
             )                                                               --集計期間が終了していない
      ;
    -- 売上目標データ処理で実績が存在する場合の取得を行うカーソルの定義
    CURSOR sales_exist_cur
    IS
      SELECT /*+
               LEADING(sum_d)
             */ 
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD START */
--              ct_base_code                                          base_code              --拠点(部門)コード
              sum_d.base_code                                       base_code              --拠点(部門)コード
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD END   */
             ,sum_d.employee_code                                   employee_code          --営業員コード
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD START */
--             ,ROUND( NVL(sum_d.sale_amount_month_sum, 0 ) /1000 )   sale_amount_month_sum  --実績金額
--             ,ROUND( NVL( xstm.target_amount, 0 ) /1000 )           target_amount          --目標金額
             ,NVL( sum_d.sale_amount_month_sum, 0 )                sale_amount_month_sum  --実績金額
             ,NVL( xstm.target_amount, 0 )                         target_amount          --目標金額
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD END   */
             ,SUBSTRB(flv.lookup_code, 1, 9)                        target_management_code --目標管理項目コード(小計行)
             ,sum_d.target_month                                    target_month           --対象年月(YYYYMM形式)
             ,NULL                                                  actual_day_cnt         --実働日数
             ,NULL                                                  passed_day_cnt         --経過日数
      FROM    ( SELECT /*+
                         LEADING(flv)
                         USE_NL(flv xrbsgs)
                       */
                       flv.attribute2                      sum_code                --小計区分
                      ,TO_CHAR(xrbsgs.dlv_date, 'YYYYMM')  target_month            --対象年月
                      ,xrbsgs.results_employee_code        employee_code           --営業員コード
                      ,SUM(xrbsgs.sale_amount)             sale_amount_month_sum   --月別純売上金額合計
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 ADD START */
                      ,xrbsgs.sale_base_code               base_code               --拠点コード
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 ADD END   */
                FROM   fnd_lookup_values_vl        flv     --商品別売上集計マスタ(集約)
                      ,xxcos_rep_bus_s_group_sum   xrbsgs  --営業成績表 政策群別実績集計テーブル
                WHERE  flv.lookup_type         =  ct_item_group_summary      --XXCMM1_ITEM_GROUP_SUMMARY
                AND    flv.enabled_flag        =  cv_yes                     --有効のみ
                AND    flv.attribute3          =  cv_no                      --商品別売上集計マスタの集約データ
                AND    flv.start_date_active   <= gd_process_date            --商品別売上集計マスタの有効開始日が業務日付以前
                AND    (
                         ( flv.end_date_active IS NULL )
                         OR
                         ( LAST_DAY( ADD_MONTHS( flv.end_date_active, 1 ) ) >= gd_process_date )
                       )                                                     --集計対象期間の翌月末日(クローズする月の末日)まで集計
                AND    flv.attribute1          =  xrbsgs.policy_group_code
                AND    xrbsgs.dlv_date         >= flv.start_date_active                       --納品日が商品別売上集計マスタの有効開始日以降
                AND    xrbsgs.dlv_date         <= NVL(flv.end_date_active, gd_process_date )  --納品日が商品別売上集計マスタの有効終了日以前
                GROUP BY
                       flv.attribute2                      --小計区分
                      ,TO_CHAR(xrbsgs.dlv_date, 'YYYYMM')  --納品日(月単位)
                      ,xrbsgs.results_employee_code        --成績計上者コード
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 ADD START */
                      ,xrbsgs.sale_base_code               --拠点コード
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 ADD END   */
              ) sum_d                             --営業員別売上サマリ
             ,fnd_lookup_values_vl        flv     --商品別売上集計マスタ(送信)
             ,xxcso_sales_target_mst      xstm    --売上目標マスタ
      WHERE   flv.lookup_type                        = ct_item_group_summary      --XXCMM1_ITEM_GROUP_SUMMARY
      AND     flv.enabled_flag                       = cv_yes                     --有効のみ
      AND     flv.attribute3                         = cv_yes                     --商品別売上集計マスタの送信データ
      AND     SUBSTRB(flv.lookup_code, 1, 9)         = sum_d.sum_code
      AND     sum_d.sum_code                         = xstm.target_management_code(+)
      AND     sum_d.employee_code                    = xstm.employee_code(+)
      AND     sum_d.target_month                     = xstm.target_month(+)
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 ADD START */
      AND     sum_d.base_code                        = xstm.base_code(+)
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 ADD END */
      ;
--
    -- 売上目標データ処理で実績が存在しない場合に目標のみ(月初を除く)の取得を行うカーソルの定義
    CURSOR target_only_cur
    IS
      SELECT  /*+ 
                LEADING(flv) 
                USE_NL(flv xstm)
                INDEX(xstm xxcso_sales_target_mst_pk)
              */
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD START */
--              ct_base_code                                  base_code              --拠点コード
              xstm.base_code                                base_code              --拠点コード
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD END   */
             ,xstm.employee_code                            employee_code          --営業員コード
             ,0                                             sale_amount_month_sum  --実績金額
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD START */
--             ,ROUND( NVL( xstm.target_amount, 0 ) / 1000 )  target_amount          --目標金額
             ,NVL( xstm.target_amount, 0 )                  target_amount          --目標金額
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD END   */
             ,xstm.target_management_code                   target_management_code --目標管理項目コード
             ,xstm.target_month                             target_month           --年月
             ,''                                            actual_day_cnt         --実働日数
             ,''                                            passed_day_cnt         --経過日数
      FROM    xxcso_sales_target_mst xstm --売上目標マスタ
             ,fnd_lookup_values_vl   flv  --商品別売上集計マスタ
      WHERE   flv.lookup_type         = ct_item_group_summary 
      AND     flv.enabled_flag        = cv_yes  --有効のみ
      AND     flv.attribute3          = cv_yes  --小計行
      AND     SUBSTRB(flv.lookup_code, 1, 9)    = xstm.target_management_code
      AND     xstm.target_month                >= gv_keeping_month                     --目標の対象期間に実績が保持されている(過去を対象としない)
      AND     xstm.target_month                <= TO_CHAR( gd_process_date, 'YYYYMM')  --目標の対象期間に業務日付が到来している(未来を対象としない)
      AND     xstm.target_month                >= TO_CHAR( flv.start_date_active, 'YYYYMM') --集計期間の開始以降で取得
      AND     (
                ( flv.end_date_active IS NULL )
                OR
                (
                  ( LAST_DAY( ADD_MONTHS( flv.end_date_active, 1 ) ) >= gd_process_date )
                  AND
                  ( TO_CHAR( flv.end_date_active, 'YYYYMM') >= xstm.target_month )
                )
              )                                                                        --集計対象期間が終了後、翌月月末までは対象(但し、期間終了後の目標は対象としない)
      AND     NOT EXISTS (
                SELECT 1
                FROM   xxcso_wk_sales_target xwst  --売上目標ワークテーブル
                WHERE  xwst.target_management_code = xstm.target_management_code
                AND    xwst.employee_code          = xstm.employee_code
                AND    xwst.target_month           = xstm.target_month
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 ADD START */
                AND    xwst.base_code              = xstm.base_code
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 ADD END */
                AND    rownum                      = 1
              )  --営業員の目標は存在するが対象の月の実績は存在しない
      ;
--
    -- 売上目標データCSV出力を行うカーソルの定義
    CURSOR sales_target_out_cur
    IS
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD START */
--      SELECT  xwst.base_code                   base_code               --拠点コード
      SELECT  ct_base_code                      base_code               --拠点コード
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD END   */
             ,xwst.employee_code               employee_code           --営業員コード
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD START */
--             ,xwst.sale_amount_month_sum       sale_amount_month_sum   --実績金額
--             ,xwst.target_amount               target_amount           --目標金額
             ,ROUND( SUM( xwst.sale_amount_month_sum ) / 1000 )
                                                 sale_amount_month_sum   --実績金額(サマリ後に四捨五入)
             ,ROUND( SUM( xwst.target_amount         ) / 1000 )
                                                 target_amount           --目標金額(サマリ後に四捨五入)
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 MOD END   */
             ,xwst.target_management_code      target_management_code  --目標管理項目コード
             ,SUBSTRB(xwst.target_month, 3, 4) target_month            --年月(YYMM形式とする)
             ,xwst.actual_day_cnt              actual_day_cnt          --実働日数
             ,xwst.passed_day_cnt              passed_day_cnt          --経過日数
             ,xwst.target_month                output_month            --CSV出力エラー時のメッセージに使用
      FROM   xxcso_wk_sales_target xwst  --売上目標ワークテーブル
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 ADDD START */
      GROUP BY
             xwst.employee_code           --営業員コード
            ,xwst.target_management_code  --目標管理項目コード
            ,xwst.target_month            --年月
            ,xwst.actual_day_cnt          --実働日数
            ,xwst.passed_day_cnt          --経過日数
/* 2013.06.18 T.Ishiwata E_本稼動_10873対応 ADD END   */
      ;
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
    -- *** ローカル・レコード ***
    l_xrv_v_cur_rec       xrv_v_cur%ROWTYPE;
    l_prsncd_data_rec     g_prsncd_data_rtype;
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
    l_output_cur_rec      sales_target_out_cur%ROWTYPE;
    l_sum_cur_rec         g_sales_target_rtype;
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
    -- *** ローカル例外 ***
    no_data_expt               EXCEPTION;
    error_skip_data_expt       EXCEPTION;
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
    sales_target_process_expt  EXCEPTION;
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
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
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
    gn_target_cnt2 := 0;
    gn_normal_cnt2 := 0;
    gn_warn_cnt2   := 0;
    gv_log_control_flag := 'N';
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
--
  -- ========================================
  -- A-1.初期処理 
  -- ========================================
    init(
      ov_errbuf        => lv_errbuf           -- エラー・メッセージ            --# 固定 #
     ,ov_retcode       => lv_retcode          -- リターン・コード              --# 固定 #
     ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  -- ========================================
  -- A-2.プロファイル値取得 
  -- ========================================
    get_profile_info(
       ov_csv_dir     => lv_csv_dir     -- CSVファイル出力先
      ,ov_csv_nm      => lv_csv_nm      -- CSVファイル名
      ,ov_errbuf      => lv_errbuf      -- エラー・メッセージ            --# 固定 #
      ,ov_retcode     => lv_retcode     -- リターン・コード              --# 固定 #
      ,ov_errmsg      => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-3.CSVファイルオープン
    -- =================================================
    open_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSVファイル出力先
      ,iv_csv_nm    => lv_csv_nm    -- CSVファイル名
      ,ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-4.リソースデータ取得
    -- =================================================
    lv_process_date_next  := TO_CHAR(gd_process_date_next, 'YYYYMMDD');
    /* 2010.08.26 K.Kiriu E_本番_04153対応 START */
    ln_closed_id           := TO_NUMBER(gv_closed_id);
    lt_elextric_item_cd    := FND_PROFILE.VALUE(ct_prof_electric_fee_item_cd);
    ld_process_date_next01 := TO_DATE(TO_CHAR(gd_process_date_next, 'YYYYMM') || '01', 'YYYYMMDD');
    /* 2010.08.26 K.Kiriu E_本番_04153対応 END */
--
    --カーソルオープン
    OPEN xrv_v_cur;
--
    <<get_data_loop>>
    LOOP 
      BEGIN
        FETCH xrv_v_cur INTO l_xrv_v_cur_rec;
--
        --処理対象件数格納
        gn_target_cnt := xrv_v_cur%ROWCOUNT;
--
        
        EXIT WHEN xrv_v_cur%NOTFOUND
          OR  xrv_v_cur%ROWCOUNT = 0;
        -- レコード変数初期化
        l_prsncd_data_rec := NULL;
        -- 取得データを格納
        l_prsncd_data_rec.employee_number   := l_xrv_v_cur_rec.employee_number;
        l_prsncd_data_rec.base_code         := l_xrv_v_cur_rec.work_base_code;
        l_prsncd_data_rec.resource_id       := l_xrv_v_cur_rec.resource_id;
        l_prsncd_data_rec.full_name         := l_xrv_v_cur_rec.full_name;
        /* 2009.10.19 K.Kubo T4_00046対応 START */
        /* 2010.08.26 K.Kiriu E_本番_04153対応 START */
        l_prsncd_data_rec.pure_amount_sum   := l_xrv_v_cur_rec.pure_amount_sum;
        l_prsncd_data_rec.prsn_total_cnt    := l_xrv_v_cur_rec.prsn_total_cnt;
        /* 2010.08.26 K.Kiriu E_本番_04153対応 END */
        --職務コード
        gv_duty_cd                          := l_xrv_v_cur_rec.duty_code;
        --職務コード名
        IF (gv_duty_cd = cv_duty_cd ) THEN
          gv_duty_cd_vl                     := cv_duty_cd_vl;      -- ルートセールス
        ELSIF (gv_duty_cd = cv_duty_cd_050 ) THEN
          gv_duty_cd_vl                     := cv_duty_cd_050_vl;  -- 専門店、百貨店販売
        ELSE
          gv_duty_cd_vl                     := NULL;
        END IF;
        /* 2009.10.19 K.Kubo T4_00046対応 END */
        -- 抽出した項目をカンマ区切りで文字連結してログに出力する用
        lv_err_rec_info := l_prsncd_data_rec.employee_number||','
                        || l_prsncd_data_rec.base_code ||','
                        || l_prsncd_data_rec.resource_id||','
                        || l_prsncd_data_rec.full_name;
        fnd_file.put_line(
            which  => FND_FILE.LOG,
            buff   => lv_err_rec_info
          );
--
        /* 2009.05.28 K.Satomura T1_1236対応 START */
        IF (l_prsncd_data_rec.base_code IS NULL) THEN
          -- 拠点コードがNULLの場合（リソースグループが設定されていない場合）
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                       -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_10                  -- メッセージコード
                         ,iv_token_name1  => cv_tkn_emp_num                    -- トークンコード1
                         ,iv_token_value1 => l_prsncd_data_rec.employee_number -- トークン値1
                         ,iv_token_name2  => cv_tkn_emp_name                   -- トークンコード2
                         ,iv_token_value2 => l_prsncd_data_rec.full_name       -- トークン値2
                       );
          --
          lv_errbuf := lv_errmsg;
          RAISE error_skip_data_expt;
          --
        END IF;
        --
        /* 2009.05.28 K.Satomura T1_1236対応 END */
        /* 2010.08.26 K.Kiriu E_本番_04153対応 START */
        -- =================================================
        -- A-5.CSVファイルに出力する関連情報取得
        -- =================================================
        --get_sum_cnt_data(
        --   io_prsncd_data_rec => l_prsncd_data_rec   -- 営業員管理(ファイル)情報ワークテーブルデータ
        --  ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ            --# 固定 #
        --  ,ov_retcode         => lv_retcode          -- リターン・コード              --# 固定 #
        --  ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
        --);
        --IF (lv_retcode = cv_status_error) THEN
        --  RAISE global_process_expt;
        --END IF;
        -- 販売実績額をログに出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_sum   || TO_CHAR(l_prsncd_data_rec.pure_amount_sum)
        );
        -- 当月訪問実績件数をログに出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_cnt   || TO_CHAR(l_prsncd_data_rec.prsn_total_cnt) || CHR(10)
        );
        /* 2010.08.26 K.Kiriu E_本番_04153対応 END */
--        
       -- =====================================================
        -- A-6.営業員管理データを抽出 
        -- =================================================
        get_prsncd_data(
           io_prsncd_data_rec => l_prsncd_data_rec         -- 営業員管理(ファイル)情報ワークテーブルデータ
          ,ov_errbuf          => lv_errbuf                 -- エラー・メッセージ            --# 固定 #
          ,ov_retcode         => lv_retcode                -- リターン・コード              --# 固定 #
          ,ov_errmsg          => lv_errmsg                 -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
        -- =====================================================
        -- A-7.CSVファイル出力 
        -- =================================================
        create_csv_rec(
           ir_prsncd_data_rec => l_prsncd_data_rec   -- 営業員管理(ファイル)情報ワークテーブルデータ
          ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ            --# 固定 #
          ,ov_retcode         => lv_retcode          -- リターン・コード              --# 固定 #
          ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
--
        gn_normal_cnt   := gn_normal_cnt + 1;    -- 正常対象件数
--
      EXCEPTION
        WHEN error_skip_data_expt THEN
          -- エラー件数カウント
          gn_error_cnt := gn_error_cnt + 1;
          -- エラー出力
          fnd_file.put_line(
          which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
          );
          -- エラーログ（データ情報＋エラーメッセージ）
          fnd_file.put_line(
            which  => FND_FILE.LOG
            ,buff   => lv_err_rec_info || ',' || lv_errbuf || CHR(10) ||
            ''
            );
          ov_retcode := cv_status_warn;
      END;
    END LOOP get_data_loop;
--
    -- カーソルクローズ
    CLOSE xrv_v_cur;
    -- *** DEBUG_LOG ***
    -- カーソルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_09             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE no_data_expt;
    END IF;
--
/* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
    -- 売上目標データ処理開始をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg14 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    -- =================================================
    -- A-9.売上目標データ初期処理
    -- =================================================
    get_sum_sls_tgt_data(
       ov_errbuf          => lv_errbuf   -- エラー・メッセージ            --# 固定 #
      ,ov_retcode         => lv_retcode  -- リターン・コード              --# 固定 #
      ,ov_errmsg          => lv_errmsg   -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sales_target_process_expt;
    END IF;
--
    -- 実績取得処理開始をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg16 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    -- =================================================
    -- A-10.売上目標データ取得処理（実績あり）
    -- =================================================
    --カーソルオープン
    OPEN sales_exist_cur;
--
    <<get_sales_exista_loop>>
    LOOP 
      BEGIN
        FETCH sales_exist_cur INTO l_sum_cur_rec;
        EXIT WHEN sales_exist_cur%NOTFOUND;
--
        -- 実稼動日数・経過日数の編集
        l_sum_cur_rec.actual_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).actual_day_cnt;
        l_sum_cur_rec.passed_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).passed_day_cnt;
--
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ生成
          lv_errmsg := SQLERRM;
          --警告カウント
          gn_warn_cnt2 := 1;
          --終了時ログ出力
          gv_log_control_flag := 'Y';
          RAISE sales_target_process_expt;
      END;
--
      --------------------------------------
      -- A-11.実績データワークテーブル格納
      --------------------------------------
      ins_work_results(
         i_sales_target_rec => l_sum_cur_rec  -- 売上目標ワークテーブル
        ,ov_errbuf          => lv_errbuf      -- エラー・メッセージ            --# 固定 #
        ,ov_retcode         => lv_retcode     -- リターン・コード              --# 固定 #
        ,ov_errmsg          => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        --終了時ログ出力
        gv_log_control_flag := 'Y';
        RAISE sales_target_process_expt;
      END IF;
--
    END LOOP get_sales_exista_loop;
--
    -- カーソルクローズ
    CLOSE sales_exist_cur;
--
    -- 目標のみ取得取得処理開始をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg17 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    -- =================================================
    -- A-12.売上目標データ取得処理（目標のみ）
    -- =================================================
    --初期化
    l_sum_cur_rec := NULL;
    --カーソルオープン
    OPEN target_only_cur;
--
    <<get_target_only_loop>>
    LOOP 
      BEGIN
        FETCH target_only_cur INTO l_sum_cur_rec;
        EXIT WHEN target_only_cur%NOTFOUND;
--
        -- 実稼動日数・経過日数の編集
        l_sum_cur_rec.actual_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).actual_day_cnt;
        l_sum_cur_rec.passed_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).passed_day_cnt;
--
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ生成
          lv_errmsg := SQLERRM;
          --警告カウント
          gn_warn_cnt2 := 1;
          --終了時ログ出力
          gv_log_control_flag := 'Y';
          RAISE sales_target_process_expt;
      END;
--
      --------------------------------------
      -- A-11.実績データワークテーブル格納
      --------------------------------------
      ins_work_results(
         i_sales_target_rec => l_sum_cur_rec  -- 売上目標ワークテーブル
        ,ov_errbuf          => lv_errbuf      -- エラー・メッセージ            --# 固定 #
        ,ov_retcode         => lv_retcode     -- リターン・コード              --# 固定 #
        ,ov_errmsg          => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        --終了時ログ出力
        gv_log_control_flag := 'Y';
        RAISE sales_target_process_expt;
      END IF;
--
    END LOOP get_target_only_loop;
--
    -- カーソルクローズ
    CLOSE target_only_cur;
--
    -- 月初表示用目標の取得取得処理開始をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg18 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    -- =================================================
    -- A-13.月初表示用目標データ取得処理
    -- =================================================
    --初期化
    l_sum_cur_rec := NULL;
    --カーソルオープン
    OPEN target_start_cur;
--
    <<get_target_start_loop>>
    LOOP 
      BEGIN
        FETCH target_start_cur INTO l_sum_cur_rec;
        EXIT WHEN target_start_cur%NOTFOUND;
--
        -- 実稼動日数・経過日数の編集
        l_sum_cur_rec.actual_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).actual_day_cnt;
        l_sum_cur_rec.passed_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).passed_day_cnt;
--
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ生成
          lv_errmsg := SQLERRM;
          --警告カウント
          gn_warn_cnt2 := 1;
          --終了時ログ出力
          gv_log_control_flag := 'Y';
          RAISE sales_target_process_expt;
      END;
--
      --------------------------------------
      -- A-11.実績データワークテーブル格納
      --------------------------------------
      ins_work_results(
         i_sales_target_rec => l_sum_cur_rec  -- 売上目標ワークテーブル
        ,ov_errbuf          => lv_errbuf      -- エラー・メッセージ            --# 固定 #
        ,ov_retcode         => lv_retcode     -- リターン・コード              --# 固定 #
        ,ov_errmsg          => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE sales_target_process_expt;
      END IF;
--
    END LOOP get_target_start_loop;
--
    -- カーソルクローズ
    CLOSE target_start_cur;
--
    -- CSV出力処理開始をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg19 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    --------------------------------------
    -- A-14.売上目標データCSV出力処理
    --------------------------------------
    --初期化
    l_prsncd_data_rec := NULL;
    --カーソルオープン
    OPEN sales_target_out_cur;
--
    <<sales_target_out_loop>>
    LOOP
      BEGIN
        FETCH sales_target_out_cur INTO l_output_cur_rec;
        EXIT WHEN sales_target_out_cur%NOTFOUND;
--
        --初期化
        l_prsncd_data_rec := NULL;
        --対象件数カウント
        gn_target_cnt2    := gn_target_cnt2 + 1;
--
        --CSVファイル出力用変数に項目をセット
        l_prsncd_data_rec.base_code        := l_output_cur_rec.base_code;                       --"0"(拠点（部門）コード)
        l_prsncd_data_rec.employee_number  := l_output_cur_rec.employee_code;                   --営業員コード(営業員コード)
        l_prsncd_data_rec.pure_amount_sum  := l_output_cur_rec.sale_amount_month_sum;           --実績金額(当月営業員実績計)
        l_prsncd_data_rec.sls_amt          := l_output_cur_rec.target_amount;                   --目標金額(当月営業員ノルマ金額)
        l_prsncd_data_rec.sls_next_amt     := l_output_cur_rec.target_management_code;          --目標管理項目コード(次月営業員ノルマ金額)
        l_prsncd_data_rec.prsn_total_cnt   := l_output_cur_rec.target_month;                    --年月(当月訪問実績)
        l_prsncd_data_rec.vis_amt          := l_output_cur_rec.actual_day_cnt;                  --実働日数(当月訪問ノルマ)
        l_prsncd_data_rec.vis_next_amt     := l_output_cur_rec.passed_day_cnt;                  --経過日数(翌月訪問ノルマ)
        --エラー時出力の為のメッセージ用項目設定
        gv_duty_cd                         := TO_CHAR(l_output_cur_rec.target_management_code);  --目標管理項目コード
        l_prsncd_data_rec.full_name        := l_output_cur_rec.output_month;                     --対象年月
--
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ生成
          lv_errmsg := SQLERRM;
          --警告カウント
          gn_warn_cnt2 := 1;
          --終了時ログ出力
          gv_log_control_flag := 'Y';
          RAISE sales_target_process_expt;
      END;

      -- =================================================
      -- A-7.CSVファイル出力 
      -- =================================================
      create_csv_rec(
         ir_prsncd_data_rec => l_prsncd_data_rec   -- 売上目標ワークテーブルデータ
        ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ            --# 固定 #
        ,ov_retcode         => lv_retcode          -- リターン・コード              --# 固定 #
        ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      --正常件数カウント
      gn_normal_cnt2 := gn_normal_cnt2 + 1;
--
    END LOOP sales_target_out_loop;
--
    -- 売上目標データ処理終了をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg15 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END */
--
  -- =====================================================
  -- A-8.CSVファイルクローズ
  -- =================================================
    close_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSVファイル出力先
      ,iv_csv_nm    => lv_csv_nm    -- CSVファイル名
      ,ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理対象データ0件例外ハンドラ ***
    WHEN no_data_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xrv_v_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xrv_v_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
    -- *** 営業員別売上目標処理例外ハンドラ ***
    WHEN sales_target_process_expt THEN
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_warn;
--
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xrv_v_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xrv_v_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xrv_v_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xrv_v_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xrv_v_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xrv_v_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
    ,retcode       OUT NOCOPY VARCHAR2 )  --   リターン・コード    --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 MOD START */
    cv_target_rec_msg2 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00652'; -- 売上目標処理対象件数メッセージ
    cv_suc_rec_msg2    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00653'; -- 売上目標処理成功件数メッセージ
    cv_warn_rec_msg2   CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00654'; -- 売上目標処理警告件数メッセージ
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 MOD END   */
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
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
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 MOD START */
--    IF (lv_retcode = cv_status_error) THEN
    IF ( 
         ( lv_retcode = cv_status_error )
         OR
         ( gv_log_control_flag = 'Y' )
       ) THEN
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 MOD END */
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-15.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力(売上目標データ処理)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_target_rec_msg2
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt2)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力(売上目標データ処理)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_suc_rec_msg2
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt2)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --警告件数出力(売上目標データ処理)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_warn_rec_msg2
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt2)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD START */
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    /* 2013.05.13 K.Kiriu E_本稼動_10735対応 ADD END   */
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg7 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO014A06C;
/
