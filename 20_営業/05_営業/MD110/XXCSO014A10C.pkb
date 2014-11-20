CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A10C(spec)
 * Description      : 訪問予定ファイルをHHTへ連携するためのCSVファイルを作成します。
 *                    
 * MD.050           : MD050_IPO_CSO_014_A10_HHT-EBSインターフェース：(OUT)訪問予定ファイル
 *                    
 * Version          : 1.4
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  chk_parm_date               パラメータチェック (A-2)
 *  get_profile_info            プロファイル値取得 (A-3)
 *  ins_task_info               タスク情報抽出処理 (A-10)
 *  open_csv_file               CSVファイルオープン (A-4)
 *  get_csv_data                CSVファイルに出力する関連情報取得 (A-6)
 *  create_csv_rec              訪問予定データCSV出力 (A-7)
 *  close_csv_file              CSVファイルクローズ処理 (A-8)
 *  submain                     メイン処理プロシージャ
 *                                訪問予定データ抽出処理 (A-5)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-18    1.0   Syoei.Kin        新規作成
 *  2009-03-18    1.1   K.Boku           【結合障害069】抽出期間設定箇所修正
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2010-01-15    1.3   Kazuyo.Hosoi     E_本稼動_01179対応
 *  2012-02-29    1.4   SCSK A.Shirakawa E_本稼動_08894対応
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
--
  gv_value                  VARCHAR2(100);             -- 処理実行日(YYYYMMDD)
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
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD Start
  --*** データエラー例外 ***
  global_data_expt          EXCEPTION;
--
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD End
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A10C';      -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';             -- アプリケーション短縮名
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';             -- アドオン：共通・IF領域
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- アクティブ
  cv_dumm_day_month      CONSTANT VARCHAR2(2)   := '99';                -- 月別場合の日にち（99）
  cv_monday_kbn_month    CONSTANT VARCHAR2(1)   := '1';                 -- 月日区分（月別：1）
  cv_monday_kbn_day      CONSTANT VARCHAR2(1)   := '2';                 -- 月日区分（日別：2）
  cv_upd_kbn_sales_month CONSTANT VARCHAR2(1)   := '6';                 -- HHT連携更新機能区分（売上計画：6）  
  cv_upd_kbn_sales_day   CONSTANT VARCHAR2(1)   := '7';                 -- HHT連携更新機能区分（売上計画日別：7）    
  cv_houmon_kbn_taget    CONSTANT VARCHAR2(1)   := '1';                 -- 訪問対象区分（訪問対象：1）
  cv_source_obj_type_cd  CONSTANT VARCHAR2(10)  := 'PARTY';             -- ソースオブジェクトタイプコード
  cv_delete_flg          CONSTANT VARCHAR2(10)  := 'N';                 -- 削除フラグ
--
  -- メッセージコード
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';     -- プロファイル取得エラー
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00150';     -- パラメータデフォルトセット
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';     -- 業務処理日付取得エラー
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';     -- 日付書式エラー
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';     -- CSVファイル残存エラー
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';     -- CSVファイルオープンエラー
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';     -- 訪問予定データ抽出エラー
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';     -- CSVファイル出力0件エラー
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00060';     -- 抽出エラー
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00061';     -- 営業員コード取得関数エラー
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00246';     -- CSVファイル出力エラー
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';     -- CSVファイルクローズエラー
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00147';     -- パラメータ処理実行日
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';     -- インターフェースファイル名
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD Start
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';     -- データ削除エラー
  cv_tkn_number_16    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00431';     -- データ登録エラー
  cv_tkn_number_17    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00638';     -- テーブル登録件数メッセージ
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD End
  -- トークンコード
  cv_tkn_prof_name       CONSTANT VARCHAR2(20) := 'PROF_NAME';          -- プロファイル名
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';            -- SQLエラーメッセージ
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'VALUE';              -- 入力されたパラメータ値
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';             -- リターンステータス(日付書式チェック結果)
  cv_tkn_message         CONSTANT VARCHAR2(20) := 'MESSAGE';            -- リターンメッセージ(日付書式チェック) 
  cv_tkn_csv_location    CONSTANT VARCHAR2(20) := 'CSV_LOCATION';       -- CSVファイル出力先
  cv_tkn_csv_file_name   CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';      -- CSVファイル名
  cv_tkn_year_month      CONSTANT VARCHAR2(20) := 'YEAR_MONTH';         -- 年月
  cv_tkn_day             CONSTANT VARCHAR2(20) := 'DAY';                -- 日
  cv_tkn_location_cd     CONSTANT VARCHAR2(20) := 'LOCATION_CD';        -- 売上拠点コード
  cv_tkn_customer_cd     CONSTANT VARCHAR2(20) := 'CUSTOMER_CD';        -- 顧客コード
  cv_tkn_proc_name       CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';    -- 抽出処理名
  cv_tkn_count           CONSTANT VARCHAR2(20) := 'COUNT';              -- 処理件数
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';              -- テーブル名
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD Start
  cv_tkn_err_message     CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';        -- SQLエラーメッセージ
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD End
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< 年度取得処理 >>';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'ln_business_year = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg9           CONSTANT VARCHAR2(200) := 'lv_file_dir    = ';
  cv_debug_msg10          CONSTANT VARCHAR2(200) := 'lv_file_name     = ';
  cv_debug_msg11          CONSTANT VARCHAR2(200) := 'lv_cntrbt_sls = ';
  cv_debug_msg12          CONSTANT VARCHAR2(200) := '<< CSVファイルをオープンしました >>' ;
  cv_debug_msg13          CONSTANT VARCHAR2(200) := '<< CSVファイルをクローズしました >>' ;
  cv_debug_msg14          CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  cv_debug_msg15          CONSTANT VARCHAR2(200) := 'lv_task_id     = ';
  cv_debug_msg16          CONSTANT VARCHAR2(200) := '<< 担当営業員コード抽出処理 >>' ;
  cv_debug_msg17          CONSTANT VARCHAR2(200) := 'lt_emp_number     = ';
  cv_debug_msg18          CONSTANT VARCHAR2(200) := '<< 前週訪問時刻抽出処理 >>' ;
  cv_debug_msg19          CONSTANT VARCHAR2(200) := 'lv_visite_p_week_date     = ';
  cv_debug_msg20          CONSTANT VARCHAR2(200) := '<< 販売実績金額抽出処理 >>' ;
  cv_debug_msg21          CONSTANT VARCHAR2(200) := 'lt_pure_amount_sum     = ';
  cv_debug_msg22          CONSTANT VARCHAR2(200) := '<< 日別売上計画合計抽出処理 >>' ;
  cv_debug_msg23          CONSTANT VARCHAR2(200) := 'lt_sales_plan_amt_sum     = ';
  cv_debug_msg24          CONSTANT VARCHAR2(200) := '<< 計画差取得処理 >>' ;
  cv_debug_msg25          CONSTANT VARCHAR2(200) := 'ln_plan_diff     = ';  
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
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
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand    UTL_FILE.FILE_TYPE;
--
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD Start
   gd_gv_value_7_from  DATE;  --タスク取得期間FROM
   gd_gv_value_7_to    DATE;  --タスク取得期間TO
--
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD End
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 訪問予定情報データ
    TYPE g_value_rtype IS RECORD(
      base_code             xxcso_account_sales_plans.base_code%TYPE,            -- 売上拠点コード
      account_number        xxcso_account_sales_plans.account_number%TYPE,       -- 顧客コード
      year_month            xxcso_account_sales_plans.year_month%TYPE,           -- 年月
      plan_day              xxcso_account_sales_plans.plan_day%TYPE,             -- 日
      plan_date             xxcso_account_sales_plans.plan_date%TYPE,            -- 年月日(訪問予定日)
      sales_plan_day_amt    xxcso_account_sales_plans.sales_plan_day_amt%TYPE,   -- 日別売上計画(計画金額)
      final_call_date       VARCHAR2(100),                                       -- 最終訪問日(前回訪問日)
      sales_person_cd       xxcso_cust_resources_v.employee_number%type,         -- 担当営業員コード
      visite_p_week_date    VARCHAR2(100),                                       -- 前週訪問時刻
      plan_diff             NUMBER                                               -- 計画差
    );
  --*** データ登録、更新例外 ***
  global_ins_upd_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_ins_upd_expt,-30000);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    od_process_date     OUT NOCOPY DATE,      -- 業務処理日
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_process_date      DATE;        -- 業務処理日
    lv_init_msg          VARCHAR2(5000);   -- エラーメッセージを格納
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 起動パラメータを出力
    lv_init_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_13
                    ,iv_token_name1  => cv_tkn_value
                    ,iv_token_value1 => gv_value
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                  lv_init_msg || CHR(10) ||
                 ''
    );
    -- パラメータが「NULL」であるかどうかを確認
    -- 業務処理日付取得処理 
    ld_process_date := xxccp_common_pkg2.get_process_date; 
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(ld_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- 業務処理日付取得に失敗した場合
    IF (ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
              iv_application  => cv_app_name                 -- アプリケーション短縮名
             ,iv_name         => cv_tkn_number_03            -- メッセージコード
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- パラメータデフォルトセット
    IF (gv_value IS NULL) THEN
      gv_value := TO_CHAR(ld_process_date,'YYYYMMDD');
      -- パラメータデフォルトセットメッセージ
      lv_init_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_tkn_number_02
                     );
      -- メッセージを出力
      fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_init_msg
      );
      -- メッセージをログ出力
      fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   =>  cv_pkg_name || cv_msg_cont||
                     cv_prg_name || cv_msg_part||
                     lv_init_msg || CHR(10) ||
                     '' 
      );
    END IF;
    -- 取得した業務処理日付をOUTパラメータに設定
    od_process_date := ld_process_date;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_parm_date
   * Description      : パラメータチェック (A-2)
   ***********************************************************************************/
  PROCEDURE chk_parm_date(
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ   --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_parm_date';     -- プログラム名
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
    cv_false               CONSTANT VARCHAR2(10)  := 'false';
    -- *** ローカル変数 ***
    lv_format                 VARCHAR2(20);  -- 日付のフォーマット
    lb_check_date_value       BOOLEAN;       -- 日付の書式チェックのリターンステータス
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lv_format            := 'YYYYMMDD';     -- 日付のフォーマット
--
    --取得したパラメータの書式が指定された日付の書式（YYYYMMDD）であるかを確認
    lb_check_date_value := xxcso_util_common_pkg.check_date(
                                  iv_date         => gv_value
                                 ,iv_date_format  => lv_format
    );
    --リターンステータスが「FALSE」の場合,例外処理を行う
    IF (lb_check_date_value = cb_false) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name               -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_04          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_value              -- トークンコード1
                      ,iv_token_value1 => gv_value                  -- トークン値1パラメータ
                      ,iv_token_name2  => cv_tkn_status             -- トークンコード2
                      ,iv_token_value2 => cv_false                  -- トークン値2リターンステータス
                      ,iv_token_name3  => cv_tkn_message            -- トークンコード3
                      ,iv_token_value3 => NULL                      -- トークン値3リターンメッセージ
      );
      lv_errbuf  := lv_errmsg;
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
  END chk_parm_date;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値を取得 (A-3)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_file_dir             OUT NOCOPY VARCHAR2,        -- XXCSO:HTT連携用CSVファイル出力先
    ov_file_name            OUT NOCOPY VARCHAR2,        -- XXCSO:HTT連携用CSVファイル名
    ov_task_id              OUT NOCOPY VARCHAR2,        -- XXCSO:タスクステータスID(クローズ)
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ   --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';          -- プログラム名
--
    cv_tkn_csv_name     CONSTANT VARCHAR2(100)  := 'CSV_FILE_NAME';
      -- インターフェースファイル名トークン名
    cv_file_dir         CONSTANT VARCHAR2(100)  := 'XXCSO1_HHT_OUT_CSV_DIR';
      --XXCSO:HTT連携用CSVファイル出力先
    cv_file_name        CONSTANT VARCHAR2(100)  := 'XXCSO1_HHT_OUT_CSV_VISIT_PLAN';
      --XXCSO:HTT連携用CSVファイル名
    cv_task_id          CONSTANT VARCHAR2(100)  := 'XXCSO1_TASK_STATUS_CLOSED_ID';
      --XXCSO:タスクステータスID(クローズ)   
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
    -- *** ローカル変数 ***
    lv_file_dir       VARCHAR2(1000);      -- XXCSO:HTT連携用CSVファイル出力先
    lv_file_name      VARCHAR2(1000);      -- XXCSO:HTT連携用CSVファイル名
    lv_task_id        VARCHAR2(1000);      -- XXCSO:タスクステータスID(クローズ)
    lv_msg_set        VARCHAR2(1000);      -- メッセージ格納
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- プロファイル値を取得
    -- ===============================
--
    -- CSVファイル出力先の値取得
    fnd_profile.get(
                  cv_file_dir
                 ,lv_file_dir
    );
    -- CSVファイル名の値取得
    fnd_profile.get(
                  cv_file_name
                 ,lv_file_name
    );
    --タスクステータスID(クローズ)の値取得
    fnd_profile.get(
                  cv_task_id
                 ,lv_task_id
    );
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg7  || CHR(10) ||
                 cv_debug_msg9  || lv_file_dir    || CHR(10) ||
                 cv_debug_msg10 || lv_file_name     || CHR(10) ||
                 cv_debug_msg15 || lv_task_id     || CHR(10) ||
                 ''
    );
    --戻り値が「NULL」であった場合,例外処理を行う
    --XXCSO:HTT連携用CSVファイル出力先
    IF (lv_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_01         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                        ,iv_token_value1 => cv_file_dir              -- トークン値1CSVファイル出力先
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --XXCSO:HTT連携用CSVファイル名
    IF (lv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_01         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                        ,iv_token_value1 => cv_file_name             -- トークン値1CSVファイル名
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --XXCSO:タスクステータスID(クローズ)
    IF (lv_task_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_01         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                        ,iv_token_value1 => cv_task_id               -- トークン値1CSVファイル名
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --インターフェースファイル名メッセージ出力
    lv_msg_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_14
                    ,iv_token_name1  => cv_tkn_csv_name
                    ,iv_token_value1 => lv_file_name
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                   lv_msg_set ||CHR(10) ||
                 ''                           -- 空行の挿入
    );
    -- 取得したCSVファイル出力先とファイル名をOUTパラメータに設定
    ov_file_dir   := lv_file_dir;       -- XXCSO:HTT連携用CSVファイル出力先
    ov_file_name  := lv_file_name;      -- XXCSO:HTT連携用CSVファイル名
    ov_task_id    := lv_task_id;        -- XXCSO:タスクステータスID(クローズ)
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
  END get_profile_info;
--
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD Start
  /**********************************************************************************
   * Procedure Name   : ins_task_info
   * Description      : タスク情報抽出処理 (A-10)
   ***********************************************************************************/
  PROCEDURE ins_task_info(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_task_info'; -- プログラム名
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
    cv_xxcso_task_info  CONSTANT VARCHAR2(100) := 'タスク情報保持テーブル';
--
    -- *** ローカル変数 ***
    ln_ins_task_count  NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.削除処理
    --==================================
    BEGIN
--
      -- 対象テーブルを全件削除
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcso.xxcso_task_info';
--
    EXCEPTION
      WHEN OTHERS THEN
        -- データ削除エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name               -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_15          -- メッセージコード
                        ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                        ,iv_token_value1 => cv_xxcso_task_info        -- トークン値1パラメータ
                        ,iv_token_name2  => cv_tkn_err_message        -- トークンコード2
                        ,iv_token_value2 => SQLERRM                   -- トークン値2パラメータ
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_data_expt;
    END;
--
    --==================================
    -- 2.登録処理
    --==================================
    BEGIN
      -- タスク情報保持テーブルにタスクデータを登録
      INSERT INTO xxcso_task_info(
        task_id,                              -- タスクID
        created_by,                           -- 作成者
        creation_date,                        -- 作成日
        last_updated_by,                      -- 最終更新者
        last_update_date,                     -- 最終更新日
        last_update_login,                    -- 最終更新ログイン
        object_version_number,                -- オブジェクトバージョン番号
        task_number,                          -- タスク番号
        task_type_id,                         -- タスクタイプID
        task_status_id,                       -- タスクステータスID
        task_priority_id,                     -- タスク優先ID
        owner_id,                             -- 所有者ID
        owner_type_code,                      -- 所有者タイプコード
        owner_territory_id,                   -- 所有者区域ID
        assigned_by_id,                       -- 割当者ID
        cust_account_id,                      -- アカウントID
        customer_id,                          -- 顧客ID
        address_id,                           -- アドレスID
        planned_start_date,                   -- 計画開始日
        planned_end_date,                     -- 計画終了日
        scheduled_start_date,                 -- 予定開始日
        scheduled_end_date,                   -- 予定終了日
        actual_start_date,                    -- 実績開始日
        actual_end_date,                      -- 実績終了日
        source_object_type_code,              -- ソースオブジェクトタイプコード
        timezone_id,                          -- 時差ID
        source_object_id,                     -- ソースオブジェクトID
        source_object_name,                   -- ソースオブジェクト名
        duration,                             -- 持続
        duration_uom,                         -- 持続単位
        planned_effort,                       -- 活動計画
        planned_effort_uom,                   -- 活動計画単位
        actual_effort,                        -- 活動実績
        actual_effort_uom,                    -- 活動実績単位
        percentage_complete,                  -- 進捗率
        reason_code,                          -- 理由コード
        private_flag,                         -- プライベートフラグ
        publish_flag,                         -- 発行フラグ
        restrict_closure_flag,                -- 閉鎖制限フラグ
        multi_booked_flag,                    -- マルチ予約フラグ
        milestone_flag,                       -- マイルストーンフラグ
        holiday_flag,                         -- 休日フラグ
        billable_flag,                        -- 請求可能フラグ
        bound_mode_code,                      -- バウンドモードコード
        soft_bound_flag,                      -- ソフトバウンドフラグ
        workflow_process_id,                  -- ワークフロープロセスID
        notification_flag,                    -- 通知フラグ
        notification_period,                  -- 通知期間
        notification_period_uom,              -- 通知期間単位
        parent_task_id,                       -- 親タスクID
        recurrence_rule_id,                   -- 再発規則ID
        alarm_start,                          -- 警告開始
        alarm_start_uom,                      -- 警告開始単位
        alarm_on,                             -- 警告中
        alarm_count,                          -- 警告カウント
        alarm_fired_count,                    -- 解雇警告カウント
        alarm_interval,                       -- 警告間隔
        alarm_interval_uom,                   -- 警告間隔単位
        deleted_flag,                         -- 削除済フラグ
        palm_flag,                            -- 扁平フラグ
        wince_flag,                           -- ウィンスフラグ
        laptop_flag,                          -- ラップトップフラグ
        device1_flag,                         -- デバイス１
        device2_flag,                         -- デバイス２
        device3_flag,                         -- デバイス３
        costs,                                -- 経費
        currency_code,                        -- 通貨コード
        org_id,                               -- 組織ID
        escalation_level,                     -- エスカレーションレベル
        attribute1,                           -- 訪問区分１
        attribute2,                           -- 訪問区分２
        attribute3,                           -- 訪問区分３
        attribute4,                           -- 訪問区分４
        attribute5,                           -- 訪問区分５
        attribute6,                           -- 訪問区分６
        attribute7,                           -- 訪問区分７
        attribute8,                           -- 訪問区分８
        attribute9,                           -- 訪問区分９
        attribute10,                          -- 訪問区分１０
        attribute11,                          -- 有効訪問区分
        attribute12,                          -- 登録元区分
        attribute13,                          -- 登録元ソース番号
        attribute14,                          -- 顧客ステータス
        attribute15,                          --
        attribute_category,                   -- 属性分類
        security_group_id,                    -- セキュリティグループID
        orig_system_reference,                -- オリジナルシステムリファレンス
        orig_system_reference_id,             -- オリジナルシステムリファレンスID
        update_status_flag,                   -- ステータス更新フラグ
        calendar_start_date,                  -- カレンダー開始日
        calendar_end_date,                    -- カレンダー終了日
        date_selected,                        -- 選択日
        template_id,                          -- テンプレートID
        template_group_id,                    -- テンプレートグループID
        object_changed_date,                  -- オブジェクト変更日
        task_confirmation_status,             -- タスク確認開始
        task_confirmation_counter,            -- タスク確認カウンター
        task_split_flag,                      -- タスク分割フラグ
        open_flag,                            -- オープンフラグ
        entity,                               -- 実体
        child_position,                       -- 子ポジション
        child_sequence_num                    -- 子シーケンス番号
      )
      (SELECT 
              jtb.task_id,                        -- タスクID
              jtb.created_by,                     -- 作成者
              jtb.creation_date,                  -- 作成日
              jtb.last_updated_by,                -- 最終更新者
              jtb.last_update_date,               -- 最終更新日
              jtb.last_update_login,              -- 最終更新ログイン
              jtb.object_version_number,          -- オブジェクトバージョン番号
              jtb.task_number,                    -- タスク番号
              jtb.task_type_id,                   -- タスクタイプID
              jtb.task_status_id,                 -- タスクステータスID
              jtb.task_priority_id,               -- タスク優先ID
              jtb.owner_id,                       -- 所有者ID
              jtb.owner_type_code,                -- 所有者タイプコード
              jtb.owner_territory_id,             -- 所有者区域ID
              jtb.assigned_by_id,                 -- 割当者ID
              jtb.cust_account_id,                -- アカウントID
              jtb.customer_id,                    -- 顧客ID
              jtb.address_id,                     -- アドレスID
              jtb.planned_start_date,             -- 計画開始日
              jtb.planned_end_date,               -- 計画終了日
              jtb.scheduled_start_date,           -- 予定開始日
              jtb.scheduled_end_date,             -- 予定終了日
              jtb.actual_start_date,              -- 実績開始日
              jtb.actual_end_date,                -- 実績終了日
              jtb.source_object_type_code,        -- ソースオブジェクトタイプコード
              jtb.timezone_id,                    -- 時差ID
              jtb.source_object_id,               -- ソースオブジェクトID
              jtb.source_object_name,             -- ソースオブジェクト名
              jtb.duration,                       -- 持続
              jtb.duration_uom,                   -- 持続単位
              jtb.planned_effort,                 -- 活動計画
              jtb.planned_effort_uom,             -- 活動計画単位
              jtb.actual_effort,                  -- 活動実績
              jtb.actual_effort_uom,              -- 活動実績単位
              jtb.percentage_complete,            -- 進捗率
              jtb.reason_code,                    -- 理由コード
              jtb.private_flag,                   -- プライベートフラグ
              jtb.publish_flag,                   -- 発行フラグ
              jtb.restrict_closure_flag,          -- 閉鎖制限フラグ
              jtb.multi_booked_flag,              -- マルチ予約フラグ
              jtb.milestone_flag,                 -- マイルストーンフラグ
              jtb.holiday_flag,                   -- 休日フラグ
              jtb.billable_flag,                  -- 請求可能フラグ
              jtb.bound_mode_code,                -- バウンドモードコード
              jtb.soft_bound_flag,                -- ソフトバウンドフラグ
              jtb.workflow_process_id,            -- ワークフロープロセスID
              jtb.notification_flag,              -- 通知フラグ
              jtb.notification_period,            -- 通知期間
              jtb.notification_period_uom,        -- 通知期間単位
              jtb.parent_task_id,                 -- 親タスクID
              jtb.recurrence_rule_id,             -- 再発規則ID
              jtb.alarm_start,                    -- 警告開始
              jtb.alarm_start_uom,                -- 警告開始単位
              jtb.alarm_on,                       -- 警告中
              jtb.alarm_count,                    -- 警告カウント
              jtb.alarm_fired_count,              -- 解雇警告カウント
              jtb.alarm_interval,                 -- 警告間隔
              jtb.alarm_interval_uom,             -- 警告間隔単位
              jtb.deleted_flag,                   -- 削除済フラグ
              jtb.palm_flag,                      -- 扁平フラグ
              jtb.wince_flag,                     -- ウィンスフラグ
              jtb.laptop_flag,                    -- ラップトップフラグ
              jtb.device1_flag,                   -- デバイス１
              jtb.device2_flag,                   -- デバイス２
              jtb.device3_flag,                   -- デバイス３
              jtb.costs,                          -- 経費
              jtb.currency_code,                  -- 通貨コード
              jtb.org_id,                         -- 組織ID
              jtb.escalation_level,               -- エスカレーションレベル
              jtb.attribute1,                     -- 訪問区分１
              jtb.attribute2,                     -- 訪問区分２
              jtb.attribute3,                     -- 訪問区分３
              jtb.attribute4,                     -- 訪問区分４
              jtb.attribute5,                     -- 訪問区分５
              jtb.attribute6,                     -- 訪問区分６
              jtb.attribute7,                     -- 訪問区分７
              jtb.attribute8,                     -- 訪問区分８
              jtb.attribute9,                     -- 訪問区分９
              jtb.attribute10,                    -- 訪問区分１０
              jtb.attribute11,                    -- 有効訪問区分
              jtb.attribute12,                    -- 登録元区分
              jtb.attribute13,                    -- 登録元ソース番号
              jtb.attribute14,                    -- 顧客ステータス
              jtb.attribute15,                    --
              jtb.attribute_category,             -- 属性分類
              jtb.security_group_id,              -- セキュリティグループID
              jtb.orig_system_reference,          -- オリジナルシステムリファレンス
              jtb.orig_system_reference_id,       -- オリジナルシステムリファレンスID
              jtb.update_status_flag,             -- ステータス更新フラグ
              jtb.calendar_start_date,            -- カレンダー開始日
              jtb.calendar_end_date,              -- カレンダー終了日
              jtb.date_selected,                  -- 選択日
              jtb.template_id,                    -- テンプレートID
              jtb.template_group_id,              -- テンプレートグループID
              jtb.object_changed_date,            -- オブジェクト変更日
              jtb.task_confirmation_status,       -- タスク確認開始
              jtb.task_confirmation_counter,      -- タスク確認カウンター
              jtb.task_split_flag,                -- タスク分割フラグ
              jtb.open_flag,                      -- オープンフラグ
              jtb.entity,                         -- 実体
              jtb.child_position,                 -- 子ポジション
              jtb.child_sequence_num              -- 子シーケンス番号
        FROM  jtf_tasks_b jtb                 -- タスクテーブル
        WHERE TRUNC(jtb.actual_end_date) >= TRUNC(gd_gv_value_7_from)  --メインデータ取得開始日から7日前
        AND   TRUNC(jtb.actual_end_date) <= TRUNC(gd_gv_value_7_to)    --メインデータ取得終了日から7日前
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        -- データ登録エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name               -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_16          -- メッセージコード
                        ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                        ,iv_token_value1 => cv_xxcso_task_info        -- トークン値1パラメータ
                        ,iv_token_name2  => cv_tkn_err_message        -- トークンコード2
                        ,iv_token_value2 => SQLERRM                   -- トークン値2パラメータ
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_data_expt;
    END;
--
    --登録件数カウント
    ln_ins_task_count := SQL%ROWCOUNT;
--
    --  処理件数メッセージ編集（タスク抽出処理件数）
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name               -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_17          -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                    ,iv_token_value1 => cv_xxcso_task_info        -- トークン値1パラメータ
                    ,iv_token_name2  => cv_tkn_count              -- トークンコード2
                    ,iv_token_value2 => ln_ins_task_count         -- トークン値2パラメータ
    );
--
    --  テーブル登録件数メッセージ
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
--
  EXCEPTION
    -- *** データ例外ハンドラ ***
    WHEN global_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END ins_task_info;
--
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD End
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : CSVファイルオープン (A-4)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    iv_file_dir             IN  VARCHAR2,               -- XXCSO:HTT連携用CSVファイル出力先
    iv_file_name            IN  VARCHAR2,               -- XXCSO:HTT連携用CSVファイル名
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'open_csv_file';     -- プログラム名
--
    cv_open_writer          CONSTANT VARCHAR2(100)  := 'W';                 -- 入出力モード
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
    -- *** ローカル変数 ***
    lv_file_dir       VARCHAR2(1000);      --XXCSO:HTT連携用CSVファイル出力先
    lv_file_name      VARCHAR2(1000);      --XXCSO:HTT連携用CSVファイル名
    lv_exists         BOOLEAN;             --存在チェック結果
    lv_file_length    VARCHAR2(1000);      --ファイルサイズ
    lv_blocksize      VARCHAR2(1000);      --ブロックサイズ
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
    -- INパラメータをローカル変数に代入
    lv_file_dir   := iv_file_dir;       --XXCSO:HTT連携用CSVファイル出力先
    lv_file_name  := iv_file_name;      --XXCSO:HTT連携用CSVファイル名
    -- ========================
    -- CSVファイル存在チェック 
    -- ========================
    UTL_FILE.FGETATTR(
                  location    => lv_file_dir
                 ,filename    => lv_file_name
                 ,fexists     => lv_exists
                 ,file_length => lv_file_length
                 ,block_size  => lv_blocksize
    );
    --CSVファイルが存在した場合
    IF (lv_exists = cb_true) THEN
      -- CSVファイル残存エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_05         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location      -- トークンコード1
                        ,iv_token_value1 => lv_file_dir              -- トークン値1CSVファイル出力先
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- トークンコード1
                        ,iv_token_value2 => lv_file_name             -- トークン値1CSVファイル名
      );
      lv_errbuf := lv_errmsg;
      RAISE file_err_expt;
    END IF;
    -- ========================
    -- CSVファイルオープン 
    -- ========================
    BEGIN
--
      -- ファイルIDを取得
      gf_file_hand := UTL_FILE.FOPEN(
                           location   => lv_file_dir
                          ,filename   => lv_file_name
                          ,open_mode  => cv_open_writer
        );
      -- *** DEBUG_LOG ***
      -- ファイルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12   || CHR(10)   ||
                   cv_debug_msg_fnm || lv_file_name || CHR(10) ||
                   ''
      );
      EXCEPTION
        WHEN UTL_FILE.INVALID_PATH       OR       -- ファイルパス不正エラー
             UTL_FILE.INVALID_MODE       OR       -- open_modeパラメータ不正エラー
             UTL_FILE.INVALID_OPERATION  OR       -- オープン不可能エラー
             UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
          -- CSVファイルオープンエラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_06         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location      -- トークンコード1
                        ,iv_token_value1 => lv_file_dir              -- トークン値1CSVファイル出力先
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- トークンコード1
                        ,iv_token_value2 => lv_file_name             -- トークン値1CSVファイル名
          );
          lv_errbuf := lv_errmsg;
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      -- 取得したパラメータをOUTパラメータに設定
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
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
   * Procedure Name   : get_csv_data
   * Description      : CSVファイルに出力する関連情報取得 (A-6)
   ***********************************************************************************/
  PROCEDURE get_csv_data(
    io_get_rec      IN OUT NOCOPY g_value_rtype,       -- 訪問予定情報データ
    id_process_date IN DATE,                           -- 業務処理日
    iv_task_id      IN VARCHAR2,                       -- タスクステータスID(クローズ)
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD Start
    in_party_id     IN NUMBER,                         -- パーティID
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD End
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'get_csv_data';       -- プログラム名
    cv_sep_com                 CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot               CONSTANT VARCHAR2(3)    := '"';
    cv_p_week_visit            CONSTANT VARCHAR2(100)  := '前週訪問時刻';
    cv_pure_amount_sum         CONSTANT VARCHAR2(100)  := '販売実績金額';
    cv_sales_plan_amt_sum      CONSTANT VARCHAR2(100)  := '売上計画金額';
    /* 2010.01.15 K.Hosoi E_本稼動_01179対応 START */
    cv_plan_diff               CONSTANT VARCHAR2(100)  := '計画差';
    cv_plan_diff_errmsg        CONSTANT VARCHAR2(100)  := '計画差が6バイトを超えたため、当該レコードをスキップします。';
    /* 2010.01.15 K.Hosoi E_本稼動_01179対応 END */
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--_
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_process_date        DATE;              -- 業務処理日
    lv_visite_p_week_date  VARCHAR2(100);     -- 前週訪問時刻
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD Start
--    lv_task_id             VARCHAR2(1000);    -- タスクステータスID(クローズ)
    ln_task_id             NUMBER;            -- タスクステータスID(クローズ)
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD End
    ld_year_month_01       DATE;              -- 年月||'01'
    ld_plan_date           DATE;              -- 年月日
    ld_plan_date_7         DATE;              -- 年月日-7
    ld_plan_date_1         DATE;              -- 年月日-1
    lt_emp_number          xxcso_cust_resources_v.employee_number%type;          -- 担当営業員コード
    lt_pure_amount_sum     xxcos_sales_exp_headers.pure_amount_sum%TYPE;         -- 販売実績金額
    /* 2010.01.15 K.Hosoi E_本稼動_01179対応 START */
    --lt_sales_plan_amt_sum  xxcso_account_sales_plans.sales_plan_day_amt%TYPE;    -- 日別売上計画の合計
    lt_sales_plan_amt_sum  xxcso_account_sales_plans.sales_plan_month_amt%TYPE;    -- 日別売上計画の合計
    /* 2010.01.15 K.Hosoi E_本稼動_01179対応 END */
    ln_plan_diff           NUMBER;            -- 計画差
    -- *** ローカル・レコード ***
    l_get_rec       g_value_rtype;            -- 訪問予定情報データ
    -- *** ローカル例外 ***
    select_error_expt     EXCEPTION;          -- データ出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをローカル変数に代入
    ld_process_date   := id_process_date;     -- 業務処理日
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD Start
--    lv_task_id        := iv_task_id;          -- タスクステータスID(クローズ)
    ln_task_id        := TO_NUMBER(iv_task_id); -- タスクステータスID(クローズ)
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD End
    l_get_rec         := io_get_rec;          -- 訪問予定を格納するレコード
    ld_plan_date_7    := TO_DATE(l_get_rec.plan_date,'YYYYMMDD')-7;            -- 年月日-7
    ld_plan_date      := TO_DATE(l_get_rec.plan_date,'YYYYMMDD');              -- 年月日
    ld_year_month_01  := TO_DATE((l_get_rec.year_month||'01'),'YYYYMMDD');     -- 年月||'01'
    ld_plan_date_1    := (TO_DATE(l_get_rec.plan_date,'YYYYMMDD')-1);          -- 年月日-1
    -- 担当営業員コード抽出
    BEGIN
-- 
      SELECT xcrv.employee_number
      INTO   lt_emp_number                         -- 担当営業員コード
      FROM   xxcso_cust_resources_v xcrv
      WHERE  xcrv.account_number = l_get_rec.account_number
        AND  ld_plan_date BETWEEN TRUNC(xcrv.start_date_active) 
               AND TRUNC(NVL(xcrv.end_date_active,ld_plan_date));
--
    EXCEPTION
      WHEN OTHERS THEN
        -- 営業員コード取得関数エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                    -- アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_10               -- メッセージコード
                  ,iv_token_name1  => cv_tkn_location_cd             -- トークンコード1
                  ,iv_token_value1 => TO_CHAR(l_get_rec.base_code)   -- トークン値1売上拠点コード
                  ,iv_token_name2  => cv_tkn_customer_cd             -- トークンコード2
                  ,iv_token_value2 => l_get_rec.account_number       -- トークン値2顧客コード
                  ,iv_token_name3  => cv_tkn_year_month              -- トークンコード3
                  ,iv_token_value3 => l_get_rec.year_month           -- トークン値3年月
                  ,iv_token_name4  => cv_tkn_day                     -- トークンコード4
                  ,iv_token_value4 => l_get_rec.plan_day             -- トークン値4日
            );
        lv_errbuf     := lv_errmsg;
      RAISE select_error_expt;
    END;
--
    -- 前週訪問時刻を抽出
    BEGIN
--
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD Start
--      SELECT TO_CHAR(MAX(jtb.actual_end_date),'HH24MI')
      SELECT /*+
               INDEX( jtb XXCSO_TASK_INFO_N01 )
             */
             TO_CHAR(MAX(jtb.actual_end_date),'HH24MI')
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD End
      INTO   lv_visite_p_week_date                          -- 前週訪問時刻
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD Start
--      FROM   jtf_tasks_b jtb
--            ,xxcso_cust_accounts_v xcav
      FROM   xxcso_task_info jtb
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD End
      WHERE  jtb.source_object_type_code = cv_source_obj_type_cd
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD Start
--        AND  xcav.account_number = l_get_rec.account_number
--        AND  jtb.source_object_id = xcav.party_id
--        AND  jtb.task_status_id = lv_task_id
        AND  jtb.source_object_id = in_party_id
        AND  jtb.task_status_id   = ln_task_id
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD End
        AND  jtb.deleted_flag = cv_delete_flg
        AND  TRUNC(jtb.actual_end_date) = ld_plan_date_7
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD Start
--        AND  xcav.account_status = cv_active_status
--        AND  xcav.party_status = cv_active_status;
        ;
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD End
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_visite_p_week_date := NULL;
      WHEN OTHERS THEN
        -- 前週訪問時刻抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                         -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_09                    -- メッセージコード
                ,iv_token_name1  => cv_tkn_proc_name                    -- トークンコード1
                ,iv_token_value1 => cv_p_week_visit                     -- トークン値1パラメータ
                ,iv_token_name2  => cv_tkn_location_cd                  -- トークンコード2
                ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)        -- トークン値2売上拠点コード
                ,iv_token_name3  => cv_tkn_customer_cd                  -- トークンコード3
                ,iv_token_value3 => l_get_rec.account_number            -- トークン値3顧客コード
                ,iv_token_name4  => cv_tkn_year_month                   -- トークンコード4
                ,iv_token_value4 => l_get_rec.year_month                -- トークン値4年月
                ,iv_token_name5  => cv_tkn_day                          -- トークンコード5
                ,iv_token_value5 => l_get_rec.plan_day                  -- トークン値5日
                ,iv_token_name6  => cv_tkn_err_msg                      -- トークンコード6
                ,iv_token_value6 => SQLERRM                             -- トークン値6
              );
        lv_errbuf  := lv_errmsg;
      RAISE select_error_expt;
    END;
--
    -- 抽出結果が「NULL」の場合
    IF (lv_visite_p_week_date IS NULL) THEN
      lv_visite_p_week_date := '9999';
    END IF;
--
    -- 販売実績金額抽出
    IF (l_get_rec.year_month = SUBSTR(gv_value,1,6)) THEN
      BEGIN
--
        SELECT ROUND(SUM(pure_amount)/1000)        
        INTO   lt_pure_amount_sum 
        FROM   xxcso_sales_for_sls_prsn_v xsfsp
        WHERE  xsfsp.account_number = l_get_rec.account_number
          AND  xsfsp.delivery_date BETWEEN ld_year_month_01 AND ld_plan_date_1;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- 販売実績金額抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                         -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_09                    -- メッセージコード
                ,iv_token_name1  => cv_tkn_proc_name                    -- トークンコード1
                ,iv_token_value1 => cv_pure_amount_sum                  -- トークン値1パラメータ
                ,iv_token_name2  => cv_tkn_location_cd                  -- トークンコード2
                ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)        -- トークン値2売上拠点コード
                ,iv_token_name3  => cv_tkn_customer_cd                  -- トークンコード3
                ,iv_token_value3 => l_get_rec.account_number            -- トークン値3顧客コード
                ,iv_token_name4  => cv_tkn_year_month                   -- トークンコード4
                ,iv_token_value4 => l_get_rec.year_month                -- トークン値4年月
                ,iv_token_name5  => cv_tkn_day                          -- トークンコード5
                ,iv_token_value5 => l_get_rec.plan_day                  -- トークン値5日
                ,iv_token_name6  => cv_tkn_err_msg                      -- トークンコード6
                ,iv_token_value6 => SQLERRM                             -- トークン値6
              );
        lv_errbuf  := lv_errmsg;
      RAISE select_error_expt;
    END;
--
    ELSIF (l_get_rec.year_month = TO_CHAR(ADD_MONTHS(TO_DATE(gv_value,'YYYYMMDD'),1),'YYYYMM')) THEN
      lt_pure_amount_sum := 0;
    END IF;
    -- 日別売上計画合計抽出
    BEGIN
--
      SELECT SUM(NVL(xasp.sales_plan_day_amt,0))
      INTO   lt_sales_plan_amt_sum
      FROM   xxcso_account_sales_plans xasp
      WHERE  xasp.base_code = l_get_rec.base_code
        AND  xasp.account_number = l_get_rec.account_number
        AND  xasp.year_month = l_get_rec.year_month
        AND  xasp.plan_day <= l_get_rec.plan_day
        AND  xasp.month_date_div = cv_monday_kbn_day;
--
    EXCEPTION
      WHEN OTHERS THEN
          -- 日別売上計画合計抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                         -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_09                    -- メッセージコード
                ,iv_token_name1  => cv_tkn_proc_name                    -- トークンコード1
                ,iv_token_value1 => cv_sales_plan_amt_sum               -- トークン値1パラメータ
                ,iv_token_name2  => cv_tkn_location_cd                  -- トークンコード2
                ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)        -- トークン値2売上拠点コード
                ,iv_token_name3  => cv_tkn_customer_cd                  -- トークンコード3
                ,iv_token_value3 => l_get_rec.account_number            -- トークン値3顧客コード
                ,iv_token_name4  => cv_tkn_year_month                   -- トークンコード4
                ,iv_token_value4 => l_get_rec.year_month                -- トークン値4年月
                ,iv_token_name5  => cv_tkn_day                          -- トークンコード5
                ,iv_token_value5 => l_get_rec.plan_day                  -- トークン値5日
                ,iv_token_name6  => cv_tkn_err_msg                      -- トークンコード6
                ,iv_token_value6 => SQLERRM                             -- トークン値6
              );
        lv_errbuf  := lv_errmsg;
      RAISE select_error_expt;
    END;
    -- 計画差を取得
    ln_plan_diff := NVL(lt_pure_amount_sum,0) - NVL(lt_sales_plan_amt_sum,0);
    /* 2010.01.15 K.Hosoi E_本稼動_01179対応 START */
    IF (LENGTHB(ln_plan_diff) > 6) THEN
          -- 日別売上計画合計抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                         -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_09                    -- メッセージコード
                ,iv_token_name1  => cv_tkn_proc_name                    -- トークンコード1
                ,iv_token_value1 => cv_plan_diff                        -- トークン値1パラメータ
                ,iv_token_name2  => cv_tkn_location_cd                  -- トークンコード2
                ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)        -- トークン値2売上拠点コード
                ,iv_token_name3  => cv_tkn_customer_cd                  -- トークンコード3
                ,iv_token_value3 => l_get_rec.account_number            -- トークン値3顧客コード
                ,iv_token_name4  => cv_tkn_year_month                   -- トークンコード4
                ,iv_token_value4 => l_get_rec.year_month                -- トークン値4年月
                ,iv_token_name5  => cv_tkn_day                          -- トークンコード5
                ,iv_token_value5 => l_get_rec.plan_day                  -- トークン値5日
                ,iv_token_name6  => cv_tkn_err_msg                      -- トークンコード6
                ,iv_token_value6 => cv_plan_diff_errmsg                 -- トークン値6
              );
        lv_errbuf  := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    /* 2010.01.15 K.Hosoi E_本稼動_01179対応 END */
--
    -- 取得したパラメータをOUTパラメータに設定
    l_get_rec.sales_person_cd     := lt_emp_number;            -- 担当営業員コード
    l_get_rec.visite_p_week_date  := lv_visite_p_week_date;    -- 前週訪問時刻
    l_get_rec.plan_diff           := ln_plan_diff;             -- 計画差
    io_get_rec                    := l_get_rec;                -- 訪問予定情報データ
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN select_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSVファイル出力 (A-7)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    i_get_rec   IN g_value_rtype,                  -- 訪問予定情報データ
    ov_errbuf   OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'create_csv_rec';       -- プログラム名
    cv_sep_com              CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)    := '"';
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--_
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_data          VARCHAR2(5000);                -- 編集データ
    -- *** ローカル・レコード ***
    l_get_rec       g_value_rtype;                  -- 訪問予定情報データ
    -- *** ローカル例外 ***
    file_put_line_expt             EXCEPTION;       -- データ出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをローカル変数に代入
    l_get_rec  := i_get_rec;       -- 訪問予定を格納するレコード
    BEGIN
--
      --データ作成
      lv_data := cv_sep_wquot || TO_CHAR(l_get_rec.base_code) || cv_sep_wquot            -- 売上拠点コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.sales_person_cd || cv_sep_wquot       -- 担当営業員コード
        || cv_sep_com || l_get_rec.plan_date                                             -- 訪問予定日
        || cv_sep_com || TO_CHAR(l_get_rec.visite_p_week_date)                           -- 前週訪問時刻
        || cv_sep_com || cv_sep_wquot || l_get_rec.account_number || cv_sep_wquot        -- 顧客コード
        || cv_sep_com || TO_CHAR(l_get_rec.final_call_date)                              -- 前回訪問日
        || cv_sep_com || TO_CHAR(l_get_rec.sales_plan_day_amt)                           -- 計画金額
        || cv_sep_com || TO_CHAR(l_get_rec.plan_diff);                                   -- 計画差
      -- データ出力
      UTL_FILE.PUT_LINE(
         file   => gf_file_hand
        ,buffer => lv_data
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- ファイル・ハンドル無効エラー
           UTL_FILE.INVALID_OPERATION  OR     -- オープン不可能エラー
           UTL_FILE.WRITE_ERROR  THEN         -- 書込み操作中オペレーティングエラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                       --アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_11                  --メッセージコード
                     ,iv_token_name1  => cv_tkn_customer_cd                --トークンコード1
                     ,iv_token_value1 => l_get_rec.account_number          --トークン値1顧客コード
                     ,iv_token_name2  => cv_tkn_location_cd                --トークンコード2
                     ,iv_token_value2 => l_get_rec.base_code               --トークン値2売上拠点コード
                     ,iv_token_name3  => cv_tkn_year_month                 --トークンコード3
                     ,iv_token_value3 => l_get_rec.year_month              --トークン値3年月
                     ,iv_token_name4  => cv_tkn_day                        --トークンコード4
                     ,iv_token_value4 => l_get_rec.plan_day                --トークン値4日
                     ,iv_token_name5  => cv_tkn_err_msg                    --トークンコード5
                     ,iv_token_value5 => SQLERRM                           --トークン値5
                    );
        lv_errbuf := lv_errmsg;
      RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_put_line_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
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
     iv_file_dir       IN  VARCHAR2         -- CSVファイル出力先
    ,iv_file_name      IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ              --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード                --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'close_csv_file';    -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
        ,buff   => cv_debug_msg13   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_file_name || CHR(10) ||
                   ''
      );
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
             UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_12             --メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location          --トークンコード1
                        ,iv_token_value1 => iv_file_dir                  --トークン値1
                        ,iv_token_name2  => cv_tkn_csv_file_name         --トークンコード1
                        ,iv_token_value2 => iv_file_name                 --トークン値1
                       );
          lv_errbuf := lv_errmsg;
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
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
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
---- *** ローカル定数 ***
    cv_sep_com              CONSTANT VARCHAR2(3)     := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)     := '"';
    cv_visit_plan           CONSTANT VARCHAR2(100)   := '訪問予定テーブル';
    cv_p_week_visit         CONSTANT VARCHAR2(100)   := '前週訪問時刻';
    -- *** ローカル変数 ***
    lv_sub_retcode         VARCHAR2(1);                -- サーブメイン用リターン・コード
    lv_sub_msg             VARCHAR2(5000);             -- 警告用メッセージ
    lv_sub_buf             VARCHAR2(5000);             -- 警告用エラー・メッセージ
    ld_process_date        DATE;                       -- 業務処理日
    lv_target_cnt          NUMBER;                     -- 処理対象件数格納
    lb_csv_putl_rec        VARCHAR2(2000);             -- CSVファイル出力判断
    lv_file_dir            VARCHAR2(2000);             -- CSVファイル出力先
    lv_file_name           VARCHAR2(2000);             -- CSVファイル名
    lv_task_id             VARCHAR2(1000);             -- タスクステータスID(クローズ)
    lv_gv_value_1          VARCHAR2(100);              -- 処理実行日+1
    lv_gv_value_8          VARCHAR2(100);              -- 処理実行日+8
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- メッセージ出力用
    lv_msg          VARCHAR2(2000);
    -- *** ローカル・カーソル ***
    CURSOR xsasp_xcav_data_cur
    IS
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD Start
--      SELECT xsasp.base_code base_code                                 -- 売上拠点コード
      SELECT /*+
               LEADING(xsasp)
               USE_NL(xcav.hca xcav.hp xcav.xca)
             */
             xsasp.base_code base_code                                 -- 売上拠点コード
-- 2012-02-29 Ver.1.4 A.Shirakawa MOD End
            ,xsasp.account_number account_number                       -- 顧客コード
            ,xsasp.year_month year_month                               -- 年月
            ,xsasp.plan_day plan_day                                   -- 日
            ,xsasp.plan_date plan_date                                 -- 年月日
            ,xsasp.sales_plan_day_amt sales_plan_day_amt               -- 日別売上計画
            ,TO_CHAR(xcav.final_call_date,'YYYYMMDD') final_call_date  -- 最終訪問日
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD Start
            ,xcav.party_id party_id                                    -- パーティID
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD End
      FROM   xxcso_cust_accounts_v xcav                                -- 顧客マスタビュー
            ,xxcso_account_sales_plans xsasp                           -- 顧客別売上計画テーブル
      WHERE  xcav.account_number = xsasp.account_number
        AND  xcav.vist_target_div = cv_houmon_kbn_taget
        AND  xsasp.plan_date BETWEEN lv_gv_value_1 AND lv_gv_value_8 
        AND  xsasp.sales_plan_day_amt > 0
        AND  xsasp.month_date_div = cv_monday_kbn_day
        AND  xcav.account_status = cv_active_status
        AND  xcav.party_status = cv_active_status
      ORDER BY xsasp.base_code        ASC                        -- 売上拠点コード
              ,xsasp.account_number   ASC                        -- 顧客コード
              ,xsasp.year_month       ASC                        -- 年月
              ,xsasp.plan_day         ASC;                       -- 日
    -- *** ローカル・レコード ***
    l_xsasp_xcav_data_rec   xsasp_xcav_data_cur%ROWTYPE;
    l_get_rec               g_value_rtype;                       -- 訪問予定情報データ
    -- *** ローカル・例外 ***
    select_error_expt EXCEPTION;
    lv_process_expt   EXCEPTION;
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
--
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
      od_process_date     => ld_process_date,  -- 業務処理日
      ov_errbuf           => lv_errbuf,        -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,       -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    ); 
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-2.パラメータチェック 
    -- ================================
    chk_parm_date(
      ov_errbuf           => lv_errbuf,         -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,        -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ    --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ローカル変数の初期化
    lv_gv_value_1  := TO_CHAR(TO_DATE(gv_value,'YYYYMMDD') + 1,'YYYYMMDD');
    lv_gv_value_8  := TO_CHAR(TO_DATE(gv_value,'YYYYMMDD') + 8,'YYYYMMDD');
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || 'FromTo' || CHR(10) ||
                 lv_gv_value_1 || '～' || lv_gv_value_8 || CHR(10) ||
                 ''
    );
    -- =================================================
    -- A-3.プロファイル値を取得 
    -- =================================================
    get_profile_info(
       ov_file_dir   => lv_file_dir   -- CSVファイル出力先
      ,ov_file_name  => lv_file_name  -- CSVファイル名
      ,ov_task_id    => lv_task_id    -- タスクステータスID(クローズ)
      ,ov_errbuf     => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode    => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ    --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD Start
    -- =================================================
    -- A-10.タスク情報抽出処理
    -- =================================================
--
    --対象期間取得
    gd_gv_value_7_from  :=  TO_DATE(lv_gv_value_1,'YYYYMMDD') -7;  --メインデータ取得開始から7日前
    gd_gv_value_7_to    :=  TO_DATE(lv_gv_value_8,'YYYYMMDD') -7;  --メインデータ取得終了から7日前
--
    --タスク情報抽出処理
    ins_task_info(
      ov_errbuf           => lv_errbuf,         -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,        -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ    --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD End
    -- =================================================
    -- A-4.CSVファイルオープン 
    -- =================================================
--
    open_csv_file(
       iv_file_dir  => lv_file_dir   -- CSVファイル出力先
      ,iv_file_name => lv_file_name  -- CSVファイル名
      ,ov_errbuf    => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-5.訪問予定データ抽出処理
    -- =================================================
--
    -- カーソルオープン
    OPEN xsasp_xcav_data_cur;
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn || CHR(10) ||
                 ''
    );
--
    <<get_data_loop>>
    LOOP
--
      BEGIN
--
        BEGIN
          FETCH xsasp_xcav_data_cur INTO l_xsasp_xcav_data_rec;
--
        EXCEPTION
          WHEN OTHERS THEN
            -- 訪問予定データ抽出エラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name               -- アプリケーション短縮名
                                ,iv_name         => cv_tkn_number_07          -- メッセージコード
                                ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                                ,iv_token_value1 => cv_visit_plan             -- トークン値1リターンステータス
                                ,iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                                ,iv_token_value2 => SQLERRM                   -- トークン値2リターンステータス
                );
            lv_errbuf  := lv_errmsg;
          RAISE lv_process_expt;
        END;
--
        -- データ初期化
        lv_sub_msg := NULL;
        lv_sub_buf := NULL;
        -- レコード変数初期化
        l_get_rec         := NULL;    -- 訪問予定データ格納
        -- 処理対象件数格納
        gn_target_cnt := xsasp_xcav_data_cur%ROWCOUNT;
        -- 対象件数がO件の場合
        EXIT WHEN xsasp_xcav_data_cur%NOTFOUND
        OR  xsasp_xcav_data_cur%ROWCOUNT = 0;
        
        -- 取得データを格納
        l_get_rec.base_code             := l_xsasp_xcav_data_rec.base_code;             -- 売上拠点コード
        l_get_rec.account_number        := l_xsasp_xcav_data_rec.account_number;        -- 顧客コード
        l_get_rec.year_month            := l_xsasp_xcav_data_rec.year_month;            -- 年月
        l_get_rec.plan_day              := l_xsasp_xcav_data_rec.plan_day;              -- 日
        l_get_rec.plan_date             := l_xsasp_xcav_data_rec.plan_date;             -- 年月日
        l_get_rec.sales_plan_day_amt    := l_xsasp_xcav_data_rec.sales_plan_day_amt;    -- 日別売上計画
        l_get_rec.final_call_date       := l_xsasp_xcav_data_rec.final_call_date;       -- 最終訪問日
--
        -- ================================================================
        -- A-6 CSVファイルに出力する関連情報取得
        -- ================================================================
--
        get_csv_data(
           io_get_rec       => l_get_rec        -- 訪問予定情報データ
          ,id_process_date  => ld_process_date  -- 業務処理日
          ,iv_task_id       => lv_task_id       -- タスクステータスID(クローズ)
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD Start
          ,in_party_id      => l_xsasp_xcav_data_rec.party_id  -- パーティID
-- 2012-02-29 Ver.1.4 A.Shirakawa ADD End
          ,ov_errbuf        => lv_sub_buf       -- エラー・メッセージ            --# 固定 #
          ,ov_retcode       => lv_sub_retcode   -- リターン・コード              --# 固定 #
          ,ov_errmsg        => lv_sub_msg       -- ユーザー・エラー・メッセージ    --# 固定 #
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE select_error_expt;
        END IF;
--
        -- ========================================
        -- A-7. 訪問予定データCSVファイル出力 
        -- ========================================
        create_csv_rec(
          i_get_rec                    =>  l_get_rec                -- 訪問予定データを格納するレコード
         ,ov_errbuf                     =>  lv_sub_buf              -- エラー・メッセージ
         ,ov_retcode                    =>  lv_sub_retcode          -- リターン・コード
         ,ov_errmsg                     =>  lv_sub_msg              -- ユーザー・エラー・メッセージ
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE select_error_expt;
        END IF;
        --成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- *** データ抽出時のエラー例外ハンドラ ***
        WHEN lv_process_expt THEN
          RAISE global_process_expt;
        -- *** データ抽出時の警告例外ハンドラ ***
        WHEN select_error_expt THEN
          --エラー件数カウント
          gn_error_cnt   := gn_error_cnt + 1;
          --
          lv_sub_retcode := cv_status_warn;
          ov_retcode     := lv_sub_retcode;
          --警告出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_sub_msg                  --ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_sub_buf                  --エラーメッセージ
          );
      END;
--
    END LOOP get_data_loop;
--
    --出力件数が０件の場合、メッセージを出力する
    IF (gn_target_cnt = 0) THEN
      gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_08             --メッセージコード
                   );
      -- メッセージ出力
      fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg 
      );
      -- メッセージをログに出力
      fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    gv_out_msg
       );
    END IF;
--
    -- カーソルクローズ
    CLOSE xsasp_xcav_data_cur;
    -- *** DEBUG_LOG ***
    -- カーソルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- ========================================
    -- A-8.CSVファイルクローズ  
    -- ========================================
--
    close_csv_file(
       iv_file_dir   => lv_file_dir   -- CSVファイル出力先
      ,iv_file_name  => lv_file_name  -- CSVファイル名
      ,ov_errbuf     => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode    => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ    --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
                     cv_debug_msg_err6 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xsasp_xcav_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xsasp_xcav_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xsasp_xcav_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xsasp_xcav_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || CHR(10) ||
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
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xsasp_xcav_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xsasp_xcav_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || CHR(10) ||
''
       );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf              OUT NOCOPY VARCHAR2     -- エラー・メッセージ  --# 固定 #
    ,retcode             OUT NOCOPY VARCHAR2     -- リターン・コード    --# 固定 #
    ,iv_value            IN VARCHAR2             --   処理実行日(YYYYMMDD)
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    -- INパラメータをローカル変数に代入
    gv_value        := iv_value;       -- 処理実行日
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
    IF (lv_retcode = cv_status_error) THEN
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
    -- A-9.終了処理 
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
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
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
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO014A10C;
/
