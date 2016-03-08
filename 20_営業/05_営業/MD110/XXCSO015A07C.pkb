CREATE OR REPLACE PACKAGE BODY APPS.XXCSO015A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCSO015A07C(body)
 * Description      : 契約にてオーナー変更が発生した時、自販機管理システムに
 *                    顧客と物件を連携するために、CSVファイルを作成します。
 * MD.050           : MD050_自販機-EBSインタフェース：（OUT））EBS自販機変更
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理                       (A-1)
 *  open_csv_file               CSVファイルオープン            (A-2)
 *  upd_cont_manage             契約管理テーブル更新処理       (A-5)
 *  create_csv_rec              EBS自販機変更データCSV出力     (A-6)
 *  close_csv_file              CSVファイルクローズ処理        (A-7)
 *  submain                     メイン処理プロシージャ
 *                                EBS自販機変更データ抽出処理  (A-3)
 *                                セーブポイント発行           (A-4)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                終了処理                     (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016-02-22    1.0   Y.Shoji          新規作成
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
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSO015A07C';      -- パッケージ名
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  -- メッセージコード
  cv_msg_xxcso00496       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00496';  -- パラメータ出力
  cv_msg_xxcso00796       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00796';  -- 対象日
  cv_msg_xxcso00797       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00797';  -- 対象時間
  cv_msg_xxcso00012       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';  -- 日付書式エラーメッセージ
  cv_msg_xxcso00014       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラーメッセージ
  cv_msg_xxcso00152       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- インターフェースファイル名
  cv_msg_xxcso00123       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSVファイル残存エラーメッセージ
  cv_msg_xxcso00015       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSVファイルオープンエラーメッセージ
  cv_msg_xxcso00224       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSVファイル出力0件メッセージ
  cv_msg_xxcso00024       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- データ抽出エラーメッセージ
  cv_msg_xxcso00075       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00075';  -- 桁数エラー2
  cv_msg_xxcso00696       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00696';  -- 物件コード
  cv_msg_xxcso00159       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00159';  -- 禁則文字チェックエラーメッセージ
  cv_msg_xxcso00798       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00798';  -- 設置先名（社名）
  cv_msg_xxcso00799       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00799';  -- 設置先ｶﾅ
  cv_msg_xxcso00800       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00800';  -- 契約管理テーブル
  cv_msg_xxcso00801       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00801';  -- 契約書番号
  cv_msg_xxcso00241       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00241';  -- ロックエラーメッセージ
  cv_msg_xxcso00782       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00782';  -- データ更新エラーメッセージ
  cv_msg_xxcso00793       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00793';  -- CSVファイル出力エラーメッセージ（EBS自販機変更）
  cv_msg_xxcso00794       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00794';  -- 正常連携メッセージ（EBS自販機変更）
  cv_msg_xxcso00018       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSVファイルクローズエラーメッセージ
--
  -- トークンコード
  cv_tkn_param_name       CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_value            CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_status           CONSTANT VARCHAR2(20) := 'STATUS';
  cv_tkn_message          CONSTANT VARCHAR2(20) := 'MESSAGE';
  cv_tkn_prof_name        CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_file_name    CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_csv_location     CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_column           CONSTANT VARCHAR2(20) := 'COLUMN';
  cv_tkn_digit            CONSTANT VARCHAR2(20) := 'DIGIT';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_item_value       CONSTANT VARCHAR2(20) := 'ITEM_VALUE';
  cv_tkn_check_range      CONSTANT VARCHAR2(20) := 'CHECK_RANGE';
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_install_code     CONSTANT VARCHAR2(20) := 'INSTALL_CODE';
  cv_tkn_cont_num         CONSTANT VARCHAR2(20) := 'CONT_NUM';
--;
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< SYSTEM DATE >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< PROFILE VALUE >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'lv_csv_dir    = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := 'lv_csv_nm     = ';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '<< CSV FILE OPEN >>' ;
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '<< CSV FILE CLOSE >>' ;
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '<< ROLLBACK >>' ;
  cv_debug_msg9           CONSTANT VARCHAR2(200) := 'GET DATA　';
  cv_debug_msg10          CONSTANT VARCHAR2(200) := 'contract_number = ';
  cv_debug_msg11          CONSTANT VARCHAR2(200) := 'install_code = ';
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< EXCEPTION : CSV FILE CLOSE >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< CURSOR OPEN >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< CURSOR CLOSE >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< EXCEPTION : CURSOR CLOSE >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others exception';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'global_process_expt';
--
  cv_yes                  CONSTANT VARCHAR2(1)  := 'Y';                      -- 汎用固定値「Y」
  cv_no                   CONSTANT VARCHAR2(1)  := 'N';                      -- 汎用固定値「N」
  cb_true                 CONSTANT BOOLEAN      := TRUE;
  cv_half_space           CONSTANT VARCHAR2(1)  := ' ';
  cv_format_date_time     CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';  -- 日付フォーマット(YYYY/MD/DD HH24:MI:SS)
  cv_format_date          CONSTANT VARCHAR2(8)  := 'YYYYMMDD';               -- 日付フォーマット(YYYYMDDD)
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 起動パラメータ
  gv_proc_date        VARCHAR2(100);                                     -- 対象日
  gv_proc_time        VARCHAR2(100);                                     -- 対象時間
  gv_proc_date_time   VARCHAR2(100);                                     -- 対象日時
  gd_proc_date_time   DATE;                                              -- 対象日時
--
  -- ファイル・ハンドルの宣言
  gf_file_hand    UTL_FILE.FILE_TYPE;
--
  -- ロールバックフラグ
  gb_rollback_upd_flg           BOOLEAN := FALSE;                        -- TRUE : ロールバック
--
  -- CSV出力データ格納用レコード型定義
  TYPE g_get_data_rtype IS RECORD(
     contract_number             xxcso_contract_managements.contract_number%TYPE         -- 契約書番号
    ,install_code                csi_item_instances.external_reference%TYPE              -- 物件コード
    ,install_account_number      xxcso_contract_managements.install_account_number%TYPE  -- 顧客コード
    ,install_date                VARCHAR2(8)                                             -- 設置日（取引開始日）
    ,party_name                  hz_parties.party_name%TYPE                              -- 設置先名（社名）
    ,organization_name_phonetic  hz_parties.organization_name_phonetic%TYPE              -- 設置先ｶﾅ
    ,address_lines_phonetic      hz_locations.address_lines_phonetic%TYPE                -- 設置先TEL
  );
--
  -- *** ユーザー定義グローバル例外 ***
  global_skip_expt           EXCEPTION;
  global_lock_expt           EXCEPTION;                                  -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     od_sysdate           OUT DATE                 -- システム日付
    ,ov_csv_dir           OUT NOCOPY VARCHAR2      -- CSVファイル出力先
    ,ov_csv_nm            OUT NOCOPY VARCHAR2      -- CSVファイル名
    ,ov_errbuf            OUT NOCOPY VARCHAR2      -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2      -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    cv_false           CONSTANT VARCHAR2(100)   := 'FALSE';
    cb_false           CONSTANT BOOLEAN         := FALSE;
--
    -- プロファイル名
    cv_csv_dir         CONSTANT VARCHAR2(30)   := 'XXCSO1_VM_OUT_CSV_DIR';     -- XXCSO:自販機管理システム連携用CSVファイル出力先
    cv_csv_nm          CONSTANT VARCHAR2(30)   := 'XXCSO1_VM_OUT_CSV_VD_MOD';  -- XXCSO:自販機管理システム連携用CSVファイル名（EBS自販機変更情報）
--
    -- *** ローカル変数 ***
    -- プロファイル値取得戻り値
    lb_check_date_value       BOOLEAN;                    -- 日付の書式判断
    lv_csv_dir                VARCHAR2(2000);             -- CSVファイル出力先
    lv_csv_nm                 VARCHAR2(2000);             -- CSVファイル名
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value              VARCHAR2(1000);
    -- 取得データメッセージ出力用
    lv_msg                    VARCHAR2(5000);
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
    -- 1.システム日付取得処理
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- 取得したシステム日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate, cv_format_date_time) || CHR(10) ||
                 ''
    );
--
    -- =================================
    -- 2.入力パラメータを出力
    -- =================================
    -- パラメータ対象日
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_xxcso00496
               ,iv_token_name1  => cv_tkn_param_name
               ,iv_token_value1 => cv_msg_xxcso00796
               ,iv_token_name2  => cv_tkn_value
               ,iv_token_value2 => gv_proc_date
              );
    -- 出力ファイルに出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                  lv_msg
    );
    -- パラメータ対象時間
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_xxcso00496
               ,iv_token_name1  => cv_tkn_param_name
               ,iv_token_value1 => cv_msg_xxcso00797
               ,iv_token_name2  => cv_tkn_value
               ,iv_token_value2 => gv_proc_time
              );
    -- 出力ファイルに出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''
    );
--
    -- =================================
    -- 3.処理日付書式チェック
    -- =================================
    -- パラメータが「NULL」であるかのチェック
    IF (gv_proc_date_time IS NOT NULL) THEN
      --取得したパラメータの書式が指定された日付の書式（YYYY/MM/DD HH24:MI:SS）であるかを確認
      lb_check_date_value := xxcso_util_common_pkg.check_date(
                                    iv_date         => gv_proc_date || cv_half_space || gv_proc_time
                                   ,iv_date_format  => cv_format_date_time
      );
      --リターンステータスが「FALSE」の場合,例外処理を行う
      IF (lb_check_date_value = cb_false) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcso00012                              -- メッセージコード
                        ,iv_token_name1  => cv_tkn_value                                   -- トークンコード1
                        ,iv_token_value1 => gv_proc_date || cv_half_space || gv_proc_time  -- トークン値1パラメータ
                        ,iv_token_name2  => cv_tkn_status                                  -- トークンコード2
                        ,iv_token_value2 => cv_false                                       -- トークン値2リターンステータス
                        ,iv_token_name3  => cv_tkn_message                                 -- トークンコード3
                        ,iv_token_value3 => NULL                                           -- トークン値3リターンメッセージ
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
      ELSE
        gd_proc_date_time := TO_DATE(gv_proc_date || cv_half_space || gv_proc_time, cv_format_date_time);
      END IF;
    END IF;
--
    -- 変数初期化処理
    lv_tkn_value := NULL;
--
    -- =======================
    -- 4.プロファイル値取得処理
    -- =======================
    FND_PROFILE.GET(
                    cv_csv_dir
                   ,lv_csv_dir
                   ); -- CSVファイル出力先
    FND_PROFILE.GET(
                    cv_csv_nm
                   ,lv_csv_nm
                   ); -- CSVファイル名
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3  || CHR(10)           ||
                 cv_debug_msg4  || lv_csv_dir        || CHR(10) ||
                 cv_debug_msg5  || lv_csv_nm         || CHR(10) ||
                 ''
    );
--
    -- 取得したCSVファイル名をメッセージ出力する
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name           --アプリケーション短縮名
                ,iv_name         => cv_msg_xxcso00152     --メッセージコード
                ,iv_token_name1  => cv_tkn_csv_file_name  --トークンコード1
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
      lv_tkn_value := cv_csv_nm;
    END IF;
    -- エラーメッセージ取得
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcso00014            --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name             --トークンコード1
                    ,iv_token_value1 => lv_tkn_value                 --トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 取得したプロファイル値をOUTパラメータに設定
    ov_csv_dir          :=  lv_csv_dir;          -- CSVファイル出力先
    ov_csv_nm           :=  lv_csv_nm;           -- CSVファイル名
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
   * Procedure Name   : open_csv_file
   * Description      : CSVファイルオープン(A-2)
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
                    ,iv_name         => cv_msg_xxcso00123            --メッセージコード
                    ,iv_token_name1  => cv_tkn_csv_location          --トークンコード1
                    ,iv_token_value1 => iv_csv_dir                   --トークン値1
                    ,iv_token_name2  => cv_tkn_csv_file_name         --トークンコード2
                    ,iv_token_value2 => iv_csv_nm                    --トークン値2
                   );
      lv_errbuf := lv_errmsg;
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
        ,buff   => cv_debug_msg6    || CHR(10)   ||
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
                       iv_application  => cv_app_name           --アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcso00015     --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_location   --トークンコード1
                      ,iv_token_value1 => iv_csv_dir            --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_file_name  --トークンコード2
                      ,iv_token_value2 => iv_csv_nm             --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
--
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
  /**********************************************************************************
   * Procedure Name   : upd_cont_manage
   * Description      : 契約管理テーブル更新処理(A-5)
   ***********************************************************************************/
  PROCEDURE upd_cont_manage(
     i_get_data_rec     IN     g_get_data_rtype        -- 出力用EBS自販機変更情報
    ,ib_break_flag      IN     BOOLEAN                 -- ブレークフラグ
    ,iv_error_flag      IN     VARCHAR2                -- 請求書番号単位エラーフラグ
    ,id_sysdate         IN     DATE                    -- システム日付
    ,ov_errbuf          OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode         OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_cont_manage';  -- プログラム名
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
    cn_install_code_max_legth     CONSTANT  NUMBER         := 9;                        -- 物件コード最大桁数
    cv_check_range                CONSTANT  VARCHAR2(30)   := 'VENDING_MACHINE_SYSTEM';
    cv_vdms_interface_flag_2      CONSTANT  VARCHAR2(1)    := '2';
--
    -- *** ローカル変数 ***
    lb_str_check_flg         BOOLEAN;                                              -- 禁則文字チェックフラグ
    lt_contract_number       xxcso_contract_managements.contract_number%TYPE;      -- 契約書番号
    lv_cont_num              VARCHAR2(12);                                         -- 契約書番号（ロック取得用）
--
    -- *** ローカル・例外 ***
    update_error_expt       EXCEPTION;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 契約書番号
    lt_contract_number     := i_get_data_rec.contract_number;
--
    -- ============================
    -- 物件コードの桁数チェック
    -- ============================
    IF (LENGTHB(i_get_data_rec.install_code) > cn_install_code_max_legth) THEN
      -- 桁数エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcso00075          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_column              -- トークンコード1
                     ,iv_token_value1 => cv_msg_xxcso00696          -- トークン値1
                     ,iv_token_name2  => cv_tkn_digit               -- トークンコード2
                     ,iv_token_value2 => cn_install_code_max_legth  -- トークン値2
                   );
      lv_errbuf := lv_errmsg;
      RAISE update_error_expt;
    END IF;
--
    -- ============================
    -- 禁則文字チェック処理
    -- ============================
    -- 設置先名（社名）
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.party_name, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcso00159                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                            -- トークンコード1
                       ,iv_token_value1 => cv_msg_xxcso00798                      -- トークン値1
                       ,iv_token_name2  => cv_tkn_item_value                      -- トークンコード2
                       ,iv_token_value2 => i_get_data_rec.party_name              -- トークン値2
                       ,iv_token_name3  => cv_tkn_check_range                     -- トークンコード3
                       ,iv_token_value3 => cv_check_range                         -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 設置先ｶﾅ
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.organization_name_phonetic, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcso00159                          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                                -- トークンコード1
                       ,iv_token_value1 => cv_msg_xxcso00799                          -- トークン値1
                       ,iv_token_name2  => cv_tkn_item_value                          -- トークンコード2
                       ,iv_token_value2 => i_get_data_rec.organization_name_phonetic  -- トークン値2
                       ,iv_token_name3  => cv_tkn_check_range                         -- トークンコード3
                       ,iv_token_value3 => cv_check_range                             -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- INパラメータがNULL（定期実行）の時
    IF ( gv_proc_date_time IS NULL ) THEN
      -- 同一契約書番号の最後の行でエラーがない場合、ロック・更新を行う
      IF ( ( ib_break_flag = TRUE ) AND ( iv_error_flag = cv_no ) ) THEN
        -- ============================
        -- 更新前のロック処理
        -- ============================
        BEGIN
          SELECT  xcm.contract_number cont_num
          INTO    lv_cont_num
          FROM    xxcso_contract_managements xcm
          WHERE   xcm.contract_number = lt_contract_number
          FOR UPDATE NOWAIT
          ;
        EXCEPTION
          -- ロックに失敗した場合の例外
          WHEN global_lock_expt THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                  -- アプリケーション短縮名
                           ,iv_name         => cv_msg_xxcso00241            -- メッセージコード
                           ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                           ,iv_token_value1 => cv_msg_xxcso00800            -- トークン値1
                           ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                           ,iv_token_value2 => cv_msg_xxcso00801            -- トークン値2
                           ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
                           ,iv_token_value3 => lt_contract_number           -- トークン値3
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
          -- 抽出に失敗した場合の例外
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                  -- アプリケーション短縮名
                           ,iv_name         => cv_msg_xxcso00024            -- メッセージコード
                           ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                           ,iv_token_value1 => cv_msg_xxcso00800            -- トークン値1
                           ,iv_token_name2  => cv_tkn_err_msg               -- トークンコード2
                           ,iv_token_value2 => SQLERRM                      -- トークン値2
                          );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
        BEGIN
          -- ==========================================
          -- 契約管理テーブル更新処理
          -- ==========================================
          UPDATE xxcso_contract_managements xcm
          SET    xcm.vdms_interface_flag    = cv_vdms_interface_flag_2  -- 自販機S連携フラグ
                ,xcm.vdms_interface_date    = id_sysdate                -- 自販機S連携日
                ,xcm.last_updated_by        = cn_last_updated_by        -- 最終更新者
                ,xcm.last_update_date       = cd_last_update_date       -- 最終更新日
                ,xcm.last_update_login      = cn_last_update_login      -- 最終更新ログイン
                ,xcm.request_id             = cn_request_id             -- 要求ID
                ,xcm.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
                ,xcm.program_id             = cn_program_id             -- コンカレント・プログラムID
                ,xcm.program_update_date    = cd_program_update_date    -- プログラム更新日
          WHERE  xcm.contract_number = lt_contract_number
          ;
        EXCEPTION
          -- *** OTHERS例外ハンドラ ***
          WHEN OTHERS THEN
            -- 更新失敗ロールバックフラグの設定
            gb_rollback_upd_flg := TRUE;
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                  -- アプリケーション短縮名
                           ,iv_name         => cv_msg_xxcso00782            -- メッセージコード
                           ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                           ,iv_token_value1 => cv_msg_xxcso00800            -- トークン値1
                           ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                           ,iv_token_value2 => cv_msg_xxcso00801            -- トークン値2
                           ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
                           ,iv_token_value3 => lt_contract_number           -- トークン値3
                           ,iv_token_name4  => cv_tkn_err_msg               -- トークンコード4
                           ,iv_token_value4 => SQLERRM                      -- トークン値4
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
        END;
      END IF;
    END IF;
--
  EXCEPTION
--
    -- *** データ更新例外ハンドラ ***
    WHEN update_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理例外ハンドラ ***
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
--#####################################  固定部 END   ##########################################
--
  END upd_cont_manage;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : EBS自販機変更データCSV出力(A-6)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     i_get_data_rec      IN  g_get_data_rtype    -- 出力用EBS自販機変更情報
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
    cv_sep_wquot      CONSTANT VARCHAR2(1)  := '"';
    cv_sep_com        CONSTANT VARCHAR2(1)  := ',';
--
    -- *** ローカル変数 ***
    lv_data                    VARCHAR2(5000);                                   -- 編集データ格納
    lv_info                    VARCHAR2(5000);                                   -- 正常メッセージ格納
    lt_log_contract_number     xxcso_contract_managements.contract_number%TYPE;  -- 契約書番号
    lt_log_install_code        csi_item_instances.external_reference%TYPE;       -- 物件コード
    -- *** ローカル・レコード ***
    l_get_data_rec  g_get_data_rtype;        -- EBS自販機変更情報
    -- *** ローカル例外 ***
    file_put_line_expt     EXCEPTION;        -- データ出力処理例外
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
    l_get_data_rec         := i_get_data_rec;
    -- 契約書番号
    lt_log_contract_number := l_get_data_rec.contract_number;
    -- 物件コード
    lt_log_install_code    := l_get_data_rec.install_code;
--
    -- ======================
    -- CSV出力処理
    -- ======================
    BEGIN
      -- データ作成
      lv_data :=         cv_sep_wquot || l_get_data_rec.install_code               || cv_sep_wquot -- 物件コード
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.install_account_number     || cv_sep_wquot -- 顧客コード
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.install_date               || cv_sep_wquot -- 設置日（取引開始日）
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.party_name                 || cv_sep_wquot -- 設置先名（社名）
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.organization_name_phonetic || cv_sep_wquot -- 設置先ｶﾅ
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.address_lines_phonetic     || cv_sep_wquot -- 設置先TEL
      ;
--
      -- データ出力
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand
       ,buffer => lv_data
      );
--
     lv_info := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                  -- アプリケーション短縮名
                  ,iv_name         => cv_msg_xxcso00794            -- メッセージコード
                  ,iv_token_name1  => cv_tkn_cont_num              -- トークンコード1
                  ,iv_token_value1 => lt_log_contract_number       -- トークン値1
                  ,iv_token_name2  => cv_tkn_install_code          -- トークンコード2
                  ,iv_token_value2 => lt_log_install_code          -- トークン値2
     );
      -- 結果をログに出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_info
      );
      -- 結果を出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_info
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- ファイル・ハンドル無効エラー
           UTL_FILE.INVALID_OPERATION  OR     -- オープン不可能エラー
           UTL_FILE.WRITE_ERROR  THEN         -- 書込み操作中オペレーティングエラー
        -- エラーメッセージ取得
        -- 更新失敗ロールバックフラグの設定
        gb_rollback_upd_flg := TRUE;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcso00793            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_cont_num              -- トークンコード1
                       ,iv_token_value1 => lt_log_contract_number       -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg               -- トークンコード2
                       ,iv_token_value2 => SQLERRM                      -- トークン値2
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
   * Description      : CSVファイルクローズ処理(A-7)
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
      ,buff   => cv_debug_msg7    || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
        -- CSVファイルクローズ失敗
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcso00018            --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_location          --トークンコード1
                      ,iv_token_value1 => iv_csv_dir                   --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_file_name         --トークンコード2
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
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_sub_retcode VARCHAR2(1);     -- サーブリターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_length_start           CONSTANT NUMBER       := 1;                  -- 開始位置：1
    cn_length_100             CONSTANT NUMBER       := 100;                -- 文字列長：100
    cn_length_50              CONSTANT NUMBER       := 50;                 -- 文字列長：50
    cn_length_20              CONSTANT NUMBER       := 20;                 -- 文字列長：20
    cv_hyphen                 CONSTANT VARCHAR2(1)  := '-';
    cv_vdms_interface_flag_1  CONSTANT VARCHAR2(1)  := '1';                -- 自販機S連携フラグ：1（未連携）
    cv_vdms_interface_flag_2  CONSTANT VARCHAR2(1)  := '2';                -- 自販機S連携フラグ：2（連携済）
    cv_comma                  CONSTANT VARCHAR2(1)  := ',';                -- 区切り文字
--
    -- *** ローカル変数 ***
    -- OUTパラメータ格納用
    ld_sysdate                DATE;                                            -- システム日付
    lv_csv_dir                VARCHAR2(2000);                                  -- CSVファイル出力先
    lv_csv_nm                 VARCHAR2(2000);                                  -- CSVファイル名
    lb_fopn_retcd             BOOLEAN;                                         -- ファイルオープン確認戻り値格納
    lb_break_flag             BOOLEAN;                                         -- ブレーク判定用
    lt_contract_number        xxcso_contract_managements.contract_number%TYPE; -- ブレーク判定用
    lv_error_flag             VARCHAR2(1);                                     -- 契約書番号単位エラー判定用フラグ
--
    -- *** ローカル・カーソル ***
    CURSOR get_cont_manage_data_cur
    IS
      SELECT /*+
               LEADING( xcm )
               INDEX( xcm xxcso_contract_managements_n07 )
               USE_NL(xcm hca hcas hps hl hp cii)
               USE_CONCAT
             */
             xcm.contract_number                                                                    contract_number             -- 契約書番号
            ,REPLACE(cii.external_reference, cv_hyphen)                                             install_code                -- 物件コード・ハイフン除く
            ,xcm.install_account_number                                                             install_account_number      -- 顧客コード
            ,TO_CHAR(xcm.install_date, cv_format_date)                                              install_date                -- 設置日（取引開始日）
            ,SUBSTRB(hp.party_name, cn_length_start, cn_length_100)                                 party_name                  -- 設置先名（社名）・100BYTE
            ,SUBSTRB(hp.organization_name_phonetic, cn_length_start, cn_length_50)                  organization_name_phonetic  -- 設置先ｶﾅ・50BYTE
            ,SUBSTRB(REPLACE(hl.address_lines_phonetic, cv_hyphen), cn_length_start, cn_length_20)  address_lines_phonetic      -- 設置先TEL・ハイフン除く・20BYTE
      FROM   xxcso_contract_managements  xcm        -- 契約管理テーブル
            ,apps.hz_cust_accounts       hca        -- 顧客マスタ
            ,apps.hz_parties             hp         -- パーティマスタ
            ,apps.hz_cust_acct_sites     hcas       -- 顧客サイト
            ,apps.hz_party_sites         hps        -- パーティサイト
            ,apps.hz_locations           hl         -- 顧客事業所
            ,apps.csi_item_instances     cii        -- 物件マスタ（付帯物）
      WHERE  (
               (
                     gv_proc_date_time       IS NULL                       -- INパラメータがNULL(定期実行）
                 AND xcm.vdms_interface_flag  = cv_vdms_interface_flag_1   -- 自販機S連携フラグ：未連携
               )
               OR
               (
                     gv_proc_date_time       IS NOT NULL                    -- INパラメータがNULLではない(手動実行）
                 AND xcm.vdms_interface_flag  = cv_vdms_interface_flag_2    -- 自販機S連携フラグ：連携済
                 AND xcm.vdms_interface_date  = gd_proc_date_time           -- 自販機S連携日
               )
             )
      AND    xcm.install_account_id      = hca.cust_account_id
      AND    hca.party_id                = hp.party_id
      AND    hca.cust_account_id         = hcas.cust_account_id
      AND    hcas.party_site_id          = hps.party_site_id
      AND    hps.location_id             = hl.location_id
      AND    xcm.install_account_id      = cii.owner_party_account_id  --指定された物件（自販機本体）と同じ顧客の物件（付帯物）
      ORDER BY xcm.contract_number    -- 契約書番号順
      ;
--
    -- *** ローカル・レコード ***
    l_get_cont_manage_data_rec      get_cont_manage_data_cur%ROWTYPE;
    l_get_data_rec                  g_get_data_rtype;
    -- *** ローカル・テーブル型 ***
    TYPE l_get_cont_manage_data_ttype IS TABLE OF get_cont_manage_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE g_get_data_ttype             IS TABLE OF g_get_data_rtype INDEX BY BINARY_INTEGER;
    l_get_cont_manage_data_tab  l_get_cont_manage_data_ttype; -- カーソルデータ一括取得用
    l_get_data_tbl              g_get_data_ttype;             -- 契約書番号単位の保持用
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
    gn_warn_cnt   := 0;
--
    -- ================================
    -- A-1.初期処理
    -- ================================
    init(
       od_sysdate            => ld_sysdate          -- システム日付
      ,ov_csv_dir            => lv_csv_dir          -- CSVファイル出力先
      ,ov_csv_nm             => lv_csv_nm           -- CSVファイル名
      ,ov_errbuf             => lv_errbuf           -- エラー・メッセージ            --# 固定 #
      ,ov_retcode            => lv_retcode          -- リターン・コード              --# 固定 #
      ,ov_errmsg             => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-2.CSVファイルオープン
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
    -- A-3. EBS自販機変更データ抽出処理
    -- ========================================
    -- カーソルオープン
    OPEN get_cont_manage_data_cur;
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn || CHR(10) ||
                 ''
    );
--
    -- 変数初期化
    lb_break_flag  := FALSE;
    lv_error_flag  := cv_no;
--
    BEGIN
      FETCH get_cont_manage_data_cur BULK COLLECT INTO l_get_cont_manage_data_tab;
      CLOSE get_cont_manage_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1 || cv_half_space || TO_CHAR(SYSDATE, cv_format_date_time) ||
                 ''
      );
      -- 処理対象件数格納
      gn_target_cnt := l_get_cont_manage_data_tab.COUNT;
    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcso00024            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                       ,iv_token_value1 => cv_msg_xxcso00800            -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg               -- トークンコード2
                       ,iv_token_value2 => SQLERRM                      -- トークン値2
                      );
        lv_errbuf  := lv_errmsg;
     RAISE global_process_expt;
    END;
--
    <<get_data_loop>>
    FOR i IN 1..l_get_cont_manage_data_tab.COUNT LOOP
      BEGIN
        -- 初期化
        l_get_cont_manage_data_rec := NULL;
        l_get_data_rec             := NULL;
        lt_contract_number         := NULL;
--
        -- カーソル行のデータ取得
        l_get_cont_manage_data_rec   := l_get_cont_manage_data_tab(i);
--
        -----------------------
        -- ブレーク判定の処理
        -----------------------
        -- 最終行でない場合
        IF ( gn_target_cnt <> i ) THEN
          -- 次の行から契約書番号を取得
          lt_contract_number := l_get_cont_manage_data_tab(i+1).contract_number;
        ELSE
          -- 最終行の場合NULLを設定
          lt_contract_number := NULL;
        END IF;
        -- 現レコードと次のレコードの契約書番号を比較しブレーク判定をする
        IF (
             ( l_get_cont_manage_data_rec.contract_number <> lt_contract_number )
             OR
             ( lt_contract_number IS NULL )
           ) THEN
          -- 次のレコードでブレークもしくは、最終行
          lb_break_flag:= TRUE;
        END IF;
--
        -- 取得したデータキーをログ出力
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => CHR(10) || cv_debug_msg9 ||
                     cv_debug_msg10 || l_get_cont_manage_data_rec.contract_number || cv_half_space || cv_comma || -- 契約書番号
                     cv_debug_msg11 || l_get_cont_manage_data_rec.install_code    || cv_half_space ||             -- 物件コード
                     ''
        );
--
        -- *** 取得データ格納 ***
        l_get_data_rec.contract_number            := l_get_cont_manage_data_rec.contract_number;            -- 契約書番号
        l_get_data_rec.install_code               := l_get_cont_manage_data_rec.install_code;               -- 物件コード
        l_get_data_rec.install_account_number     := l_get_cont_manage_data_rec.install_account_number;     -- 顧客コード
        l_get_data_rec.install_date               := l_get_cont_manage_data_rec.install_date;               -- 設置日（取引開始日）
        l_get_data_rec.party_name                 := l_get_cont_manage_data_rec.party_name;                 -- 設置先名（社名）
        l_get_data_rec.organization_name_phonetic := l_get_cont_manage_data_rec.organization_name_phonetic; -- 設置先ｶﾅ
        l_get_data_rec.address_lines_phonetic     := l_get_cont_manage_data_rec.address_lines_phonetic;     -- 設置先TEL
--
        -- ========================================
        -- A-4.セーブポイント設定
        -- ========================================
        SAVEPOINT reqst_proc_up;
--
        -- ==================================================
        -- A-5.契約管理テーブル更新処理
        -- ==================================================
        upd_cont_manage(
           i_get_data_rec             => l_get_data_rec          -- 出力用EBS自販機変更情報
          ,ib_break_flag              => lb_break_flag           -- ブレークフラグ
          ,iv_error_flag              => lv_error_flag           -- 請求書番号単位エラーフラグ
          ,id_sysdate                 => ld_sysdate              -- システム日付
          ,ov_errbuf                  => lv_errbuf               -- エラー・メッセージ            --# 固定 #
          ,ov_retcode                 => lv_sub_retcode          -- リターン・コード              --# 固定 #
          ,ov_errmsg                  => lv_errmsg               -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_expt;
        END IF;
--
        -- チェック・更新でエラーが無い場合、契約書番号単位でデータ保持
        l_get_data_tbl(i) := l_get_data_rec;
--
        -- 契約書番号単位でエラーがない場合、CSVを出力する
        IF ( ( lb_break_flag = TRUE ) AND ( lv_error_flag = cv_no ) ) THEN
          << output_loop >>
          FOR j IN l_get_data_tbl.FIRST..l_get_data_tbl.LAST LOOP
            -- 初期化
            l_get_data_rec := NULL;
            -- 値を設定
            l_get_data_rec := l_get_data_tbl(j);
--
            -- ========================================
            -- A-6.EBS自販機変更データCSV出力
            -- ========================================
            create_csv_rec(
              i_get_data_rec     =>  l_get_data_rec   -- 出力用EBS自販機変更情報
             ,ov_errbuf          =>  lv_errbuf        -- エラー・メッセージ            --# 固定 #
             ,ov_retcode         =>  lv_sub_retcode   -- リターン・コード              --# 固定 #
             ,ov_errmsg          =>  lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
            );
            --
            IF (lv_sub_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
          END LOOP output_loop;
--
          -- 正常件数カウントアップ
          gn_normal_cnt := gn_normal_cnt + l_get_data_tbl.COUNT;
        END IF;
--
        -- 契約書番号単位の初期化
        IF ( lb_break_flag = TRUE ) THEN
          l_get_data_tbl.DELETE;    -- 契約書番号単位のテーブルクリア
          lb_break_flag := FALSE;   -- ブレーク用フラグ初期化
          lv_error_flag := cv_no;   -- 契約書番号単位エラーフラグ初期化
        END IF;
--
      EXCEPTION
        -- *** スキップ例外ハンドラ ***
        WHEN global_skip_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
          lv_retcode   := cv_status_warn;
--
          -- 1契約書番号で最後の行がエラーの場合、契約書番号単位の初期化
          IF ( lb_break_flag = TRUE ) THEN
            l_get_data_tbl.DELETE;    -- 契約書番号単位のテーブルクリア
            lb_break_flag := FALSE;   -- ブレーク用フラグ初期化
            lv_error_flag := cv_no;   -- 契約書番号単位エラーフラグ初期化
          -- 1契約書番号で最後以外の行でエラーの場合、エラーフラグON
          ELSE
            lv_error_flag := cv_yes;
          END IF;
--
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- エラーメッセージ
          );
--
          -- ロールバック
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT reqst_proc_up;          -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg8|| CHR(10)
            );
          END IF;
--
        -- *** スキップ例外OTHERSハンドラ ***
        WHEN OTHERS THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
          lv_retcode   := cv_status_warn;
--
          -- 1契約書番号で最後の行がエラーの場合、契約書番号単位の初期化
          IF ( lb_break_flag = TRUE ) THEN
            l_get_data_tbl.DELETE;    -- 契約書番号単位のテーブルクリア
            lb_break_flag := FALSE;   -- ブレーク用フラグ初期化
            lv_error_flag := cv_no;   -- 契約書番号単位エラーフラグ初期化
          -- 1契約書番号で最後以外の行でエラーの場合、エラーフラグON
          ELSE
            lv_error_flag := cv_yes;
          END IF;
--
          -- ログ出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf  ||SQLERRM              -- エラーメッセージ
          );
--
          -- ロールバック
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT reqst_proc_up;          -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg8|| CHR(10)
            );
          END IF;
      END;
--
    END LOOP get_data_loop;
--
    ov_retcode   := lv_retcode;
--
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcso00224            --メッセージコード
                   );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                        -- ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errmsg                                         -- エラーメッセージ
          );
    END IF;
    -- ========================================
    -- A-7.CSVファイルクローズ
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
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
      -- カーソルがクローズされていない場合
      IF (get_cont_manage_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_cont_manage_data_cur;
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
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
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
      IF (get_cont_manage_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_cont_manage_data_cur;
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
      IF (get_cont_manage_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_cont_manage_data_cur;
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
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT  NOCOPY  VARCHAR2,      -- エラー・メッセージ  --# 固定 #
    retcode       OUT  NOCOPY  VARCHAR2,      -- リターン・コード    --# 固定 #
    iv_proc_date  IN VARCHAR2,                -- 対象日
    iv_proc_time  IN VARCHAR2                 -- 対象時間
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
    -- INパラメータを代入
    gv_proc_date      := iv_proc_date;                  -- 対象日
    gv_proc_time      := iv_proc_time;                  -- 対象時間
    gv_proc_date_time := gv_proc_date || gv_proc_time;  -- 対象日時
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf   => lv_errbuf,           -- エラー・メッセージ            --# 固定 #
      ov_retcode  => lv_retcode,          -- リターン・コード              --# 固定 #
      ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
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
    -- A-10.終了処理
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg8 || CHR(10) ||
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
        ,buff   => cv_debug_msg8 || CHR(10) ||
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
        ,buff   => cv_debug_msg8 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO015A07C;
/
