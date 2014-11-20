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
 * Version          : 1.8
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
 *  submain                メイン処理プロシージャ
 *                           リソースデータ取得 (A-4)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-9)
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
    -- *** ローカル変数 ***
    -- OUTパラメータ格納用
    lv_csv_dir           VARCHAR2(2000); -- CSVファイル出力先
    lv_csv_nm            VARCHAR2(2000); -- CSVファイル名
    lb_fopn_retcd        BOOLEAN;        -- ファイルオープン確認戻り値格納
    lv_err_rec_info      VARCHAR2(5000); -- データ項目内容メッセージ出力用
    lv_process_date_next VARCHAR2(150);  -- データ項目内容メッセージ出力用 
    
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
      ;
      /* 2009.06.03 K.Satomura T1_1304対応 END */
--
    -- *** ローカル・レコード ***
    l_xrv_v_cur_rec       xrv_v_cur%ROWTYPE;
    l_prsncd_data_rec     g_prsncd_data_rtype;
    -- *** ローカル例外 ***
    no_data_expt               EXCEPTION;
    error_skip_data_expt       EXCEPTION;
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
        -- =================================================
        -- A-5.CSVファイルに出力する関連情報取得
        -- =================================================
        get_sum_cnt_data(
           io_prsncd_data_rec => l_prsncd_data_rec   -- 営業員管理(ファイル)情報ワークテーブルデータ
          ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ            --# 固定 #
          ,ov_retcode         => lv_retcode          -- リターン・コード              --# 固定 #
          ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
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
