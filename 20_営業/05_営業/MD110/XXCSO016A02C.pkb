CREATE OR REPLACE PACKAGE BODY XXCSO016A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A02C(body)
 * Description      : 営業員マスタデータを情報系システムに送信するための
 *                    CSVファイルを作成します。
 * MD.050           : MD050_CSO_016_A02_情報系-EBSインターフェース：
 *                    (OUT)営業員マスタ
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_profile_info       プロファイル値取得(A-2)
 *  open_csv_file          営業員マスタ情報CSVファイルオープン(A-3)
 *  get_prsn_cnnct_data    営業員マスタ関連情報抽出処理(A-5)
 *  create_csv_rec         営業員マスタCSV出力(A-6)
 *  close_csv_file         営業員マスタ情報CSVファイルクローズ処理(A-7)
 *  submain                メイン処理プロシージャ
 *                           営業員マスタ情報抽出処理(A-4)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-26    1.0   Kazuyo.Hosoi     新規作成
 *  2009-02-26    1.1   K.Sai            レビュー結果反映
 *  2009-03-26    1.2   M.Maruyama      【ST障害T01_208】データ取得元をリソース関連マスタビューに変更
 *  2009-04-16    1.3   K.Satomura      【ST障害T01_0172】営業員名称、営業員名称（カナ）を全角置換
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A02C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSVファイルオープンエラー
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';  -- データ抽出エラー
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSVファイルクローズエラー
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00019';  -- CSVファイル出力エラーメッセージ(営業員マスタ)
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSVファイル残存エラーメッセージ
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- インターフェースファイル名
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSVファイル出力0件エラーメッセージ
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  -- トークンコード
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_errmessage      CONSTANT VARCHAR2(20) := 'ERR_MESSAGE'; 
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc         CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_csv_fnm         CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_prcss_nm        CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';
  cv_tkn_slspsn_cd       CONSTANT VARCHAR2(20) := 'SALESPARSON_CD';
  cv_sls_pttn            CONSTANT VARCHAR2(20) := 'SALES_PATTERN';
  cv_grp_cd              CONSTANT VARCHAR2(20) := 'GROUP_CD';
  cv_base_cd             CONSTANT VARCHAR2(20) := 'BASE_CODE';
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cn_name_lengthb         CONSTANT NUMBER := 20;  -- 姓、名を切るバイト数
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg4          CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5          CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg6          CONSTANT VARCHAR2(200) := 'lv_company_cd = ';
  cv_debug_msg7          CONSTANT VARCHAR2(200) := 'lv_csv_dir    = ';
  cv_debug_msg8          CONSTANT VARCHAR2(200) := 'lv_csv_nm     = ';
  cv_debug_msg9          CONSTANT VARCHAR2(200) := '<< CSVファイルをオープンしました >>' ;
  cv_debug_msg10         CONSTANT VARCHAR2(200) := '<< CSVファイルをクローズしました >>' ;
  cv_debug_msg11         CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  cv_debug_msg_fnm       CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls      CONSTANT VARCHAR2(200) := '<< 例外処理内でCSVファイルをクローズしました >>';
  cv_debug_msg_copn      CONSTANT VARCHAR2(200) := '<< カーソルをオープンしました >>';
  cv_debug_msg_ccls1     CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2     CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
  cv_debug_msg_err1      CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2      CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3      CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4      CONSTANT VARCHAR2(200) := 'others例外';
  cv_debug_msg_err5      CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6      CONSTANT VARCHAR2(200) := 'global_process_expt';
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand    UTL_FILE.FILE_TYPE;
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSV出力データ格納用レコード型定義
  TYPE g_get_data_rtype IS RECORD(
     company_cd         VARCHAR2(3)                                                        -- 会社コード
    ,employee_number    per_people_f.employee_number%TYPE                                  -- 営業員コード
    ,base_code          VARCHAR2(150)                                                      -- 拠点コード
    /* 2009.04.16 K.Satomura T1_0172対応 START */
    --,person_name        VARCHAR2(42)                                                       -- 営業員名称
    --,person_name_kana   VARCHAR2(42)                                                       -- 営業員氏名(カナ)
    ,person_name        VARCHAR2(40)                                                       -- 営業員名称
    ,person_name_kana   VARCHAR2(40)                                                       -- 営業員氏名(カナ)
    /* 2009.04.16 K.Satomura T1_0172対応 END */
    ,business_form      jtf_rs_resource_extns.attribute10%TYPE                             -- 営業形態
    ,group_leader_flag  jtf_rs_group_members.attribute1%TYPE                               -- グループ長区分
    ,group_cd           jtf_rs_group_members.attribute2%TYPE                               -- グループコード
    ,cprtn_date         DATE                                                               -- 連携日時
    ,resource_id        jtf_rs_resource_extns.resource_id%TYPE                             -- リソースID
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     od_sysdate          OUT DATE             -- システム日付
    ,od_process_date     OUT DATE             -- 業務処理日付
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';   -- アプリケーション短縮名
    -- *** ローカル変数 ***
    lv_noprm_msg     VARCHAR2(5000);  -- コンカレント入力パラメータなしメッセージ格納用
    ld_process_date  DATE;            -- 業務処理日付格納用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- システム日付取得処理 
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- 取得したシステム日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- =================================
    -- 入力パラメータなしメッセージ出力 
    -- =================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name           --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_10             --メッセージコード
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- 空行の挿入
    );
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(od_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
--
    -- 業務処理日付取得に失敗した場合
    IF (od_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_01             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
     ov_company_cd     OUT NOCOPY VARCHAR2  -- 会社コード（固定値001）
    ,ov_csv_dir        OUT NOCOPY VARCHAR2  -- CSVファイル出力先
    ,ov_csv_nm         OUT NOCOPY VARCHAR2  -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_info';  -- プログラム名
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
    -- *** ローカル定数 ***
    -- プロファイル名
    -- XXCSO:情報系連携用会社コード
    cv_prfnm_cmp_cd         CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_COMPANY_CD';
    -- XXCSO:情報系連携用CSVファイル出力先
    cv_prfnm_csv_dir        CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_DIR';
    -- XXCSO:情報系連携用CSVファイル名(営業員マスタ)
    cv_prfnm_csv_sls_prsn   CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_SLS_PRSN';
--
    -- *** ローカル変数 ***
    -- プロファイル値取得戻り値格納用
    lv_company_cd               VARCHAR2(2000);      -- 会社コード（固定値001）
    lv_csv_dir                  VARCHAR2(2000);      -- CSVファイル出力先
    lv_csv_nm                   VARCHAR2(2000);      -- CSVファイル名
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value                VARCHAR2(1000);
    -- 取得データメッセージ出力用
    lv_msg                      VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================
    -- 変数初期化処理 
    -- =======================
    lv_tkn_value := NULL;
--
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    FND_PROFILE.GET(
                    name => cv_prfnm_cmp_cd
                   ,val  => lv_company_cd
                   ); -- 会社コード（固定値001）
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_dir
                   ,val  => lv_csv_dir
                   ); -- CSVファイル出力先
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_sls_prsn
                   ,val  => lv_csv_nm
                   ); -- CSVファイル名
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg6  || lv_company_cd || CHR(10) ||
                 cv_debug_msg7  || lv_csv_dir    || CHR(10) ||
                 cv_debug_msg8  || lv_csv_nm     || CHR(10) ||
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
    -- 会社コード取得失敗時
    IF (lv_company_cd IS NULL) THEN
      lv_tkn_value := cv_prfnm_cmp_cd;
    -- CSVファイル出力先取得失敗時
    ELSIF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_dir;
    -- CSVファイル名取得失敗時
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_sls_prsn;
    END IF;
    -- エラーメッセージ取得
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm               --トークンコード1
                    ,iv_token_value1 => lv_tkn_value                 --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- 取得したプロファイル値をOUTパラメータに設定
    ov_company_cd     :=  lv_company_cd;       -- 会社コード（固定値001）
    ov_csv_dir        :=  lv_csv_dir;          -- CSVファイル出力先
    ov_csv_nm         :=  lv_csv_nm;           -- CSVファイル名
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
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : 営業員マスタ情報CSVファイルオープン(A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- プログラム名
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
    UTL_FILE.FGETATTR(
       location    => iv_csv_dir
      ,filename    => iv_csv_nm
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- すでにファイルが存在した場合
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_07             --メッセージコード
                    ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                    ,iv_token_value1 => iv_csv_dir                   --トークン値1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード2
                    ,iv_token_value2 => iv_csv_nm                    --トークン値2
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
                         location   => iv_csv_dir
                        ,filename   => iv_csv_nm
                        ,open_mode  => cv_w
                      );
    -- *** DEBUG_LOG ***
    -- ファイルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg9    || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- ファイルパス不正エラー
           UTL_FILE.INVALID_MODE       OR       -- open_modeパラメータ不正エラー
           UTL_FILE.INVALID_OPERATION  OR       -- オープン不可能エラー
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_03     --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc       --トークンコード1
                      ,iv_token_value1 => iv_csv_dir           --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --トークンコード2
                      ,iv_token_value2 => iv_csv_nm            --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
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
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
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
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
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
  /* 2009/03/26 M.Maruyama ST0156対応 START */
  --/**********************************************************************************
  -- * Procedure Name   : get_prsn_cnnct_data
  -- * Description      : 営業員マスタ関連情報抽出処理(A-5)
  -- ***********************************************************************************/
  --PROCEDURE get_prsn_cnnct_data(
  --   io_person_data_rec IN OUT NOCOPY g_get_data_rtype -- 営業員マスタ情報
  --  ,id_process_date    IN     DATE                    -- 業務処理日付
  --  ,ov_errbuf          OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
  --  ,ov_retcode         OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
  --  ,ov_errmsg          OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  --)
  --IS
  --  -- ===============================
  --  -- 固定ローカル定数
  --  -- ===============================
  --  cv_prg_name   CONSTANT VARCHAR2(100) := 'get_prsn_cnnct_data';  -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
----
  --  lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
  --  lv_retcode VARCHAR2(1);     -- リターン・コード
  --  lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
  --  -- ===============================
  --  -- ユーザー宣言部
  --  -- ===============================
  --  -- *** ローカル定数 ***
  --  cv_no               CONSTANT VARCHAR2(1)   :=  'N';
  --  cv_processing_name  CONSTANT VARCHAR2(100) :=  '営業員マスタ関連情報';
  --  -- *** ローカル変数 ***
  --  --取得データ格納用
  --  lt_attribute1  jtf_rs_group_members.attribute1%TYPE;    -- グループ長区分
  --  lt_attribute2  jtf_rs_group_members.attribute2%TYPE;    -- グループコード
  --  ld_date        DATE;                                    -- 業務処理日付格納用('yyyymmdd'形式)
  --  -- *** ローカル・例外 ***
  --  error_expt      EXCEPTION;            -- データ抽出エラー例外
----
  --BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
  --  ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
  ---- 業務処理日付を'yyyymmdd'形式で格納
  --ld_date := TRUNC(id_process_date);
  --  -- ============================
  --  -- 営業員マスタ関連情報抽出処理
  --  -- ============================
  --  BEGIN
  --    SELECT  jrgm.attribute1   --グループ長区分
  --           ,jrgm.attribute2   --グループコード
  --    INTO    lt_attribute1
  --           ,lt_attribute2
  --    FROM    jtf_rs_group_members  jrgm    -- リソースグループメンバーテーブル
  --           ,jtf_rs_groups_b       jrgb    -- リソースグループテーブル
  --    WHERE  jrgm.resource_id   = io_person_data_rec.resource_id
  --      AND  jrgm.group_id      = jrgb.group_id
  --      AND  jrgb.attribute1    = io_person_data_rec.base_code
  --      AND  jrgm.delete_flag   = cv_no
  --      AND  NVL(jrgb.start_date_active,ld_date) <= ld_date
  --      AND  NVL(jrgb.end_date_active,ld_date) >= ld_date
  --    ;
  --  EXCEPTION
  --    WHEN NO_DATA_FOUND THEN
  --      -- データが存在しない場合はNULLを設定
  --      lt_attribute1 := NULL;
  --      lt_attribute2 := NULL;
  --    WHEN OTHERS THEN
  --      lv_errmsg := xxccp_common_pkg.get_msg(
  --                        iv_application  => cv_app_name                           -- アプリケーション短縮名
  --                       ,iv_name         => cv_tkn_number_04                      -- メッセージコード
  --                       ,iv_token_name1  => cv_tkn_prcss_nm                       -- トークン値1
  --                       ,iv_token_value1 => cv_processing_name                    -- エラー発生処理名
  --                       ,iv_token_name2  => cv_tkn_errmessage                     -- トークンコード2
  --                       ,iv_token_value2 => SQLERRM                               -- SQLエラーメッセージ
  --                    );
  --      lv_errbuf  := lv_errmsg||SQLERRM;
  --      RAISE error_expt;
  --  END;
  --  -- 取得した値をOUTパラメータに設定
  --  io_person_data_rec.group_leader_flag := lt_attribute1; --グループ長区分
  --  io_person_data_rec.group_cd          := lt_attribute2; --グループコード
----
  --EXCEPTION
----
  ---- *** データ抽出例外ハンドラ ***
  --  WHEN error_expt THEN
  --    ov_errmsg  := lv_errmsg;
  --    ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
  --    ov_retcode := cv_status_error;
----
----#################################  固定例外処理部 START   ####################################
----
  --  -- *** 共通関数例外ハンドラ ***
  --  WHEN global_api_expt THEN
  --    ov_errmsg  := lv_errmsg;
  --    ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
  --    ov_retcode := cv_status_error;
  --  -- *** 共通関数OTHERS例外ハンドラ ***
  --  WHEN global_api_others_expt THEN
  --    ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  --    ov_retcode := cv_status_error;
  --  -- *** OTHERS例外ハンドラ ***
  --  WHEN OTHERS THEN
  --    ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  --    ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
  --END get_prsn_cnnct_data;
----
  /* 2009/03/26 M.Maruyama ST0156対応 END */
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : 営業員マスタCSV出力(A-6)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     i_person_data_rec   IN  g_get_data_rtype    -- 営業員マスタ情報
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
    cv_sep_com         CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot       CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ローカル変数 ***
    lv_data            VARCHAR2(5000);   -- 編集データ格納
--
    -- *** ローカル・レコード ***
    l_person_data_rec  g_get_data_rtype; -- INパラメータ.営業員別計画抽出データ格納
    -- *** ローカル例外 ***
    file_put_line_expt   EXCEPTION;      -- データ出力処理例外
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
    l_person_data_rec := i_person_data_rec; -- 営業員別計画抽出データ
--
    -- ======================
    -- CSV出力処理 
    -- ======================
    BEGIN
      -- データ作成
      lv_data := cv_sep_wquot || l_person_data_rec.company_cd || cv_sep_wquot                 -- 会社コード
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.employee_number   || cv_sep_wquot  -- 営業員コード
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.base_code         || cv_sep_wquot  -- 拠点コード
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.person_name       || cv_sep_wquot  -- 営業員名称
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.person_name_kana  || cv_sep_wquot  -- 営業員氏名（カナ）
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.business_form     || cv_sep_wquot  -- 営業形態
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.group_leader_flag || cv_sep_wquot  -- グループ長区分
        || cv_sep_com || l_person_data_rec.group_cd                                           -- グループコード
        || cv_sep_com || TO_CHAR(l_person_data_rec.cprtn_date, 'yyyymmddhh24miss')            -- 連携日時
      ;
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
                       iv_application  => cv_app_name                     --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_06                --メッセージコード
                      ,iv_token_name1  => cv_tkn_slspsn_cd                --トークンコード1
                      ,iv_token_value1 => l_person_data_rec.company_cd    --トークン値1
                      ,iv_token_name2  => cv_base_cd                      --トークンコード2
                      ,iv_token_value2 => l_person_data_rec.base_code     --トークン値2
                      ,iv_token_name3  => cv_sls_pttn                     --トークンコード3
                      ,iv_token_value3 => l_person_data_rec.business_form --トークン値3
                      ,iv_token_name4  => cv_grp_cd                       --トークンコード4
                      ,iv_token_value4 => l_person_data_rec.group_cd      --トークン値4
                      ,iv_token_name5  => cv_tkn_errmsg                   --トークンコード4
                      ,iv_token_value5 => SQLERRM                         --トークン値4
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
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
   * Description      : 営業員マスタ情報CSVファイルクローズ処理(A-7)
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
      ,buff   => cv_debug_msg10    || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05             --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                      ,iv_token_value1 => iv_csv_dir                   --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード2
                      ,iv_token_value2 => iv_csv_nm                    --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
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
      cv_space        CONSTANT VARCHAR2(2) := '　';       -- 全角スペース
      cv_category     CONSTANT VARCHAR2(8) := 'EMPLOYEE'; -- 抽出条件カテゴリーに当てる値
    -- *** ローカル変数 ***
    -- OUTパラメータ格納用
    ld_sysdate      DATE;           -- システム日付
    ld_process_date DATE;           -- 業務処理日付
    ln_year         NUMBER;         -- データ抽出パラメータ(年度)
    lv_company_cd   VARCHAR2(2000); -- 会社コード（固定値001）
    lv_csv_dir      VARCHAR2(2000); -- CSVファイル出力先
    lv_csv_nm       VARCHAR2(2000); -- CSVファイル名
    lv_cntrbt_sls   VARCHAR2(2000); -- 貢献売上の値(固定値15000)
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- 業務処理日付格納用('yyyymmdd'形式)
    ld_date         DATE;
--
    -- *** ローカル・カーソル ***
  /* 2009/03/26 M.Maruyama ST0156対応 START */
    CURSOR get_person_data_cur
    IS
      SELECT  xrrv.employee_number employee_number  -- 営業員コード
             ,( CASE
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd') <= ld_date THEN
                   xrrv.work_dept_code_new          -- 勤務地拠点コード(新)
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd')  > ld_date THEN
                   xrrv.work_dept_code_old          -- 勤務地拠点コード(旧)
                 WHEN xrrv.issue_date IS NULL THEN
                   xrrv.work_dept_code_old          -- 勤務地拠点コード(旧)
                 END
              )  base_code                          -- 拠点コード
             /* 2009.04.16 K.Satomura T1_0172対応 START */
             --,SUBSTRB(xrrv.last_name,1,cn_name_lengthb) || cv_space ||
             --  SUBSTRB(xrrv.first_name,1,cn_name_lengthb)  person_name            -- 営業員名称
             --,SUBSTRB(xrrv.last_name_kana,1,cn_name_lengthb) || cv_space ||
             --  SUBSTRB(xrrv.first_name_kana,1,cn_name_lengthb)  person_name_kana  -- 営業員氏名（カナ）
             ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(
                SUBSTRB(xrrv.last_name,1,cn_name_lengthb) || cv_space || SUBSTRB(xrrv.first_name,1,cn_name_lengthb)
             ),1,40) person_name -- 営業員名称
             ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(
                SUBSTRB(xrrv.last_name_kana,1,cn_name_lengthb) || cv_space || SUBSTRB(xrrv.first_name_kana,1,cn_name_lengthb)
             ),1,40) person_name_kana -- 営業員氏名（カナ）
             /* 2009.04.16 K.Satomura T1_0172対応 END */
             ,xrrv.sales_style  sales_style         -- 営業形態
             ,xrrv.resource_id  resource_id         -- リソースID
             ,( CASE
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd') <= ld_date THEN
                   xrrv.group_leader_flag_new       -- グループ長区分(新)
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd')  > ld_date THEN
                   xrrv.group_leader_flag_old       -- グループ長区分(旧)
                 WHEN xrrv.issue_date IS NULL THEN
                   xrrv.group_leader_flag_old       -- グループ長区分(旧)
                 END
              )  group_leader_flag                  -- グループ長区分
             ,( CASE
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd') <= ld_date THEN
                   xrrv.group_number_new            -- グループ番号(新)
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd')  > ld_date THEN
                   xrrv.group_number_old            -- グループ番号(旧)
                 WHEN xrrv.issue_date IS NULL THEN
                   xrrv.group_number_old            -- グループ番号(旧)
                 END
              )  group_number                       -- グループ番号
      FROM   xxcso_resource_relations_v xrrv        -- リソース関連マスタビュー
      WHERE  xrrv.employee_start_date <= ld_date
        AND  xrrv.employee_end_date   >= ld_date
        AND  xrrv.assign_start_date   <= ld_date
        AND  xrrv.assign_end_date     >= ld_date
        AND  xrrv.resource_start_date <= ld_date
        AND  NVL(xrrv.resource_end_date,ld_date)     >= ld_date
        AND  NVL(xrrv.start_date_active_new,ld_date) <= ld_date
        AND  NVL(xrrv.end_date_active_new,ld_date)   >= ld_date
        AND  NVL(xrrv.start_date_active_old,ld_date) <= ld_date
        AND  NVL(xrrv.end_date_active_old,ld_date)   >= ld_date
      ;
    --CURSOR get_person_data_cur
    --IS
    --  SELECT  papf.employee_number  employee_number                    -- 営業員コード
    --         ,( CASE
    --             WHEN TO_DATE(paaf.ass_attribute2, 'yyyy/mm/dd') <= ld_date THEN
    --               paaf.ass_attribute3  -- 勤務地拠点コード(新)
    --             WHEN TO_DATE(paaf.ass_attribute2, 'yyyy/mm/dd')  > ld_date THEN
    --               paaf.ass_attribute4  -- 勤務地拠点コード(旧)
    --             WHEN paaf.ass_attribute2 IS NULL THEN
    --               paaf.ass_attribute4  -- 勤務地拠点コード(旧)
    --             END
    --          )  base_code                                            -- 拠点コード
    --         ,SUBSTRB(papf.per_information18,1,cn_name_lengthb) || cv_space ||
    --           SUBSTRB(papf.per_information19,1,cn_name_lengthb)  person_name     -- 営業員名称
    --         ,SUBSTRB(papf.last_name,1,cn_name_lengthb) || cv_space ||
    --           SUBSTRB(papf.first_name,1,cn_name_lengthb)  person_name_kana       -- 営業員氏名（カナ）
    --         ,jrre.attribute1    business_form                         -- 営業形態
    --         ,jrre.resource_id  resource_id                            -- リソースID
    --  FROM   per_people_f           papf                        -- 従業員マスタ
    --        ,per_assignments_f      paaf                        -- 従業員マスタアサイメント
    --        ,jtf_rs_resource_extns  jrre                        -- リソーステーブル
    --  WHERE  jrre.category  = cv_category
    --    AND  jrre.source_id = papf.person_id
    --    AND  papf.person_id = paaf.person_id
    --    AND  papf.effective_start_date <= ld_date
    --    AND  papf.effective_end_date   >= ld_date
    --    AND  paaf.effective_start_date <= ld_date
    --    AND  paaf.effective_end_date   >= ld_date
    --    AND  jrre.start_date_active    <= ld_date
    --    AND  NVL(jrre.end_date_active,ld_date) >= ld_date
    --  ;
  /* 2009/03/26 M.Maruyama ST0156対応 END */
--
    -- *** ローカル・レコード ***
    l_get_person_data_rec   get_person_data_cur%ROWTYPE;
    l_get_data_rec          g_get_data_rtype;
    -- *** ローカル例外 ***
    no_data_expt       EXCEPTION;
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
--
    -- ========================================
    -- A-1.初期処理 
    -- ========================================
    init(
       od_sysdate      => ld_sysdate          -- システム日付
      ,od_process_date => ld_process_date     -- 業務処理日付
      ,ov_errbuf       => lv_errbuf           -- エラー・メッセージ            --# 固定 #
      ,ov_retcode      => lv_retcode          -- リターン・コード              --# 固定 #
      ,ov_errmsg       => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-2.プロファイル値取得 
    -- ========================================
    get_profile_info(
       ov_company_cd  => lv_company_cd  -- 会社コード（固定値001）
      ,ov_csv_dir     => lv_csv_dir     -- CSVファイル出力先
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
--
    -- =================================================
    -- A-3.営業員マスタ情報CSVファイルオープン
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
    -- ========================================
    -- A-4.営業員マスタ情報抽出処理
    -- ========================================
    -- 業務処理日付を'yyyymmdd'形式で格納
    ld_date := TRUNC(ld_process_date);
    -- カーソルオープン
    OPEN get_person_data_cur;
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
      FETCH get_person_data_cur INTO l_get_person_data_rec;
      -- 処理対象件数格納
      gn_target_cnt := get_person_data_cur%ROWCOUNT;
--
      EXIT WHEN get_person_data_cur%NOTFOUND
      OR  get_person_data_cur%ROWCOUNT = 0;
      -- レコード変数初期化
      l_get_data_rec := NULL;
      -- 取得データを格納
      l_get_data_rec.company_cd        := lv_company_cd;                            -- 会社コード
      l_get_data_rec.employee_number   := l_get_person_data_rec.employee_number;    -- 営業員コード
      l_get_data_rec.base_code         := l_get_person_data_rec.base_code;          -- 拠点コード
      l_get_data_rec.person_name       := l_get_person_data_rec.person_name;        -- 営業員名称
      l_get_data_rec.person_name_kana  := l_get_person_data_rec.person_name_kana;   -- 営業員氏名(カナ)
  /* 2009/03/26 M.Maruyama ST0156対応 START */
      --l_get_data_rec.business_form     := l_get_person_data_rec.business_form;    -- 営業形態
      l_get_data_rec.business_form     := l_get_person_data_rec.sales_style;        -- 営業形態
  /* 2009/03/26 M.Maruyama ST0156対応 END */
      l_get_data_rec.cprtn_date        := ld_sysdate;                               -- 連携日時
      l_get_data_rec.resource_id       := l_get_person_data_rec.resource_id;        -- リソースID
  /* 2009/03/26 M.Maruyama ST0156対応 START */
      l_get_data_rec.group_leader_flag := l_get_person_data_rec.group_leader_flag;  -- グループ長区分
      l_get_data_rec.group_cd          := l_get_person_data_rec.group_number;       -- グループ番号
--
      ---- ========================================
      ---- A-5.営業員マスタ関連情報抽出処理
      ---- ========================================
      --get_prsn_cnnct_data(
      --   io_person_data_rec => l_get_data_rec   --営業員マスタ情報
      --  ,id_process_date    => ld_process_date  -- 業務処理日付
      --  ,ov_errbuf          => lv_errbuf        -- エラー・メッセージ            --# 固定 #
      --  ,ov_retcode         => lv_retcode       -- リターン・コード              --# 固定 #
      --  ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
      --);
--    --
      --IF (lv_retcode = cv_status_error) THEN
      --  RAISE global_process_expt;
      --END IF;
  /* 2009/03/26 M.Maruyama ST0156対応 END */
--
      -- ========================================
      -- A-6.営業員マスタCSV出力
      -- ========================================
      create_csv_rec(
        i_person_data_rec  =>  l_get_data_rec   --営業員マスタ情報
       ,ov_errbuf          =>  lv_errbuf        -- エラー・メッセージ            --# 固定 #
       ,ov_retcode         =>  lv_retcode       -- リターン・コード              --# 固定 #
       ,ov_errmsg          =>  lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- 正常件数カウントアップ
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP get_data_loop;
--
    -- カーソルクローズ
    CLOSE get_person_data_cur;
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
    -- ========================================
    -- CSVファイルクローズ (A-7) 
    -- ========================================
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
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      -- カーソルがクローズされていない場合
      IF (get_person_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_person_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || CHR(10) ||
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
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err6 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_person_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_person_data_cur;
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
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_person_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_person_data_cur;
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
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_person_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_person_data_cur;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    -- A-8.終了処理 
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
        ,buff   => cv_debug_msg11 || CHR(10) ||
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
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO016A02C;
/
