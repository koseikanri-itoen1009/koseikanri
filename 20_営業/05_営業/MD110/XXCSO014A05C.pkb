CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A05C(body)
 * Description      : CSVファイルから取得したノート情報をEBSの
 *                    ノートへ登録します。
 * MD.050           : MD050_CSO_014_A05_HHT-EBSインターフェース：
 *                    (IN)ノート
 * Version          : 1.0
 *
 * Program List
 * -------------------------------- ----------------------------------------------------------
 *  Name                            Description
 * -------------------------------- ----------------------------------------------------------
 *  init                            初期処理(A-1)
 *  master_exist_check              顧客コード、営業員コードマスタ存在チェック(A-3)
 *  insert_notes                    ノート情報登録(A-4)
 *  del_notes_data                  ノートワークテーブルデータ削除(A-6)
 *  submain                         メイン処理プロシージャ
 *                                    ノート情報抽出(A-2)
 *                                    savepoint設定(A-5)
 *  main                            コンカレント実行ファイル登録プロシージャ
 *                                    終了処理(A-7)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-12    1.0   shun.sou         新規作成
 *  2009-01-27    1.1   Kenji.Sai        (A-3)にselect_data_expt例外を追加
 *  2009-03-16    1.1   K.Boku           【障害番号064】リソースマスタチェックの有効期間修正
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START  #######################
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
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCSO014A05C';     -- パッケージ名
  cv_app_name          CONSTANT VARCHAR2(5)   := 'XXCSO';            -- アプリケーション短縮名
  cv_active_status     CONSTANT VARCHAR2(1)   := 'A';                -- アクティブ
--
  -- メッセージコード
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00085';  -- データ抽出エラー
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00086';  -- 顧客コードなしエラー
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00087';  -- 営業員コードなしエラー
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00088';  -- データ追加エラー
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';  -- データ削除エラー
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし

  cv_tgt_cnt_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- 処理対象件数
  cv_nml_cnt_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- 正常処理件数
  cv_err_cnt_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- エラー処理件数
--
  -- トークンコード
  cv_tkn_errmsg              CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_prof_nm             CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_sequence            CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_account_cd          CONSTANT VARCHAR2(20) := 'CUSTOMERCODE';
  cv_tkn_account_nm          CONSTANT VARCHAR2(20) := 'CUSTOMERNAME';
  cv_tkn_sales_cd            CONSTANT VARCHAR2(20) := 'SALESCODE';
  cv_tkn_sales_nm            CONSTANT VARCHAR2(20) := 'SALESNAME';
  cv_tkn_date                CONSTANT VARCHAR2(20) := 'DATE';
  cv_tkn_tbl                 CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_cnt                 CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_process             CONSTANT VARCHAR2(20) := 'PROCESS'; 
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1              CONSTANT VARCHAR2(200) := 'ノート登録処理がが完了しました。';
  cv_debug_msg2              CONSTANT VARCHAR2(200) := 'ワークテーブルのデータを削除しました。';
  cv_debug_msg3              CONSTANT VARCHAR2(200) := 'セーブポイントを設定しました。';
  cv_debug_msg4              CONSTANT VARCHAR2(200) := '正常件数がないから直接ロールバックします。';
  cv_debug_msg5              CONSTANT VARCHAR2(200) := 'セーブポイントに戻ります。';
  cv_debug_msg6              CONSTANT VARCHAR2(200) := '抽出されたデータ件数は＝';
  cv_debug_msg7              CONSTANT VARCHAR2(200) := '件です。';
  cv_debug_msg8              CONSTANT VARCHAR2(200) := ' ノートワークテーブル抽出データ：';
  cv_debug_msg9              CONSTANT VARCHAR2(200) := ' カーソルがクローズされました。';
  cv_debug_msg10             CONSTANT VARCHAR2(200) := '顧客マスタビューで取得されたデータ:';
  cv_debug_msg11             CONSTANT VARCHAR2(200) := '顧客マスタビューで取得されたデータ:';
  cv_account_number          CONSTANT VARCHAR2(200) := '顧客コード';
  cv_party_id                CONSTANT VARCHAR2(200) := 'パーティID：';
  cv_account_name            CONSTANT VARCHAR2(200) := '顧客名称：';
  cv_resource_id             CONSTANT VARCHAR2(200) := 'リソースID：';
  cv_full_name               CONSTANT VARCHAR2(200) := '氏名：';
  cv_user_id                 CONSTANT VARCHAR2(200) := 'ユーザーID：';
  cv_notetype                CONSTANT VARCHAR2(200) := 'A-1:ノートタイプ：';
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 取得情報格納レコード型定義
--
  -- ノート情報抽出データ
  TYPE g_get_notes_data_rtype IS RECORD(
    no_seq                   xxcso_in_notes.no_seq%TYPE,                    -- シーケンス番号
    account_number           xxcso_in_notes.account_number%TYPE,            -- 顧客コード
    account_name             xxcso_cust_accounts_v.account_name%TYPE,       -- 顧客名称
    notes                    xxcso_in_notes.notes%TYPE,                     -- ノート
    employee_number          xxcso_in_notes.employee_number%TYPE,           -- 営業員コード
    full_name                xxcso_resources_v.full_name%TYPE,              -- 営業員名称
    input_date               xxcso_in_notes.input_date%TYPE,                -- 入力日付
    input_time               xxcso_in_notes.input_time%TYPE,                -- 入力時刻
    coalition_trance_date    xxcso_in_notes.coalition_trance_date%TYPE,     -- 連携処理日
    party_id                 xxcso_cust_accounts_v.party_id%TYPE,           -- パーティID
    user_id                  xxcso_resources_v.user_id%TYPE,                -- ユーザーID
    resource_id              xxcso_resources_v.resource_id%TYPE,            -- リソースID
    note_type                VARCHAR2(20)                                   -- ノートタイプ
  );
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_note_type        VARCHAR2(20);                -- ノートタイプを格納する
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_note_type        OUT NOCOPY VARCHAR2,     -- ノートタイプ
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    cv_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';   -- アプリケーション短縮名
    cv_prfnm_note_type   CONSTANT VARCHAR2(50)  := 'XXCSO1_HHT_NOTE_TYPE';   -- プロファイル名
--
    -- *** ローカル変数 ***
    lv_note_type         VARCHAR2(20);       -- プロファイル値取得戻り値
    lv_tkn_value         VARCHAR2(1000);     -- プロファイル値取得失敗時 トークン値格納用
    lv_msg               VARCHAR2(5000);     -- 取得データメッセージ出力用
    lv_noprm_msg         VARCHAR2(5000);     -- コンカレント入力パラメータなしメッセージ格納用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ================
    -- 変数初期化処理 
    -- ================
    lv_tkn_value := NULL;
--
    -- ==================================
    -- 入力パラメータなしメッセージ出力
    -- ==================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name       -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07         -- メッセージコード
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- 空行の挿入
    );
--
    -- ========================
    -- プロファイル値取得処理
    -- ========================
    FND_PROFILE.GET(
                    name => cv_prfnm_note_type
                   ,val  => lv_note_type
                   ); -- ノートタイプ（ノート登録時の設定値）
--
   -- DEBUG用
   fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => cv_notetype || lv_note_type);
--
    -- プロファイル値取得に失敗した場合
    -- ノートタイプ取得失敗時
    IF (lv_note_type IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm               --トークンコード1
                    ,iv_token_value1 => lv_tkn_value                 --トークン値1
                   );
      lv_errbuf := lv_errmsg||SQLERRM;
--
      RAISE global_api_expt;
    END IF;
--
    -- 取得したプロファイル値をOUTパラメータに設定
    gv_note_type   :=  lv_note_type;       -- ノートタイプ（ノート登録時の設定値）
--
  EXCEPTION
--
--#################################  固定例外処理部  ####################################
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
   * Procedure Name   : master_exist_check
   * Description      : 顧客コード、営業員コードマスタ存在チェック(A-3)
   ***********************************************************************************/
  PROCEDURE master_exist_check(
    io_notes_data_rec   IN OUT NOCOPY g_get_notes_data_rtype,    -- ノートワークテーブルデータ
    ov_errbuf              OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg              OUT NOCOPY VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'master_exist_check'; -- プログラム名
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
    cv_table_name1           CONSTANT VARCHAR2(21)   := '顧客マスタビュー';         -- 顧客マスタビュー名
    cv_table_name2           CONSTANT VARCHAR2(20)   := 'リソースマスタビュー';     -- リソースマスタビュー名
--
    -- *** ローカル変数 ***
    lt_account_number        xxcso_in_notes.account_number%TYPE;          -- 顧客コード
    lt_party_id              xxcso_cust_accounts_v.party_id%TYPE;         -- パーティID
    lt_account_name          xxcso_cust_accounts_v.account_name%TYPE;     -- 顧客名称
    lt_resource_id           xxcso_resources_v.resource_id%TYPE;          -- リソースID
    lt_full_name             xxcso_resources_v.full_name%TYPE;            -- 営業員名称
    lt_user_id               xxcso_resources_v.user_id%TYPE;              -- ユーザーID
--
    -- *** ローカル・レコード ***
    lr_notes_data_rec    g_get_notes_data_rtype;    -- INパラメータ.ノートワークテーブルデータ格納
    -- *** ローカル例外 ***
    warning_expt       EXCEPTION;     -- マスタ存在チェック例外
    select_data_expt   EXCEPTION;     -- データ抽出エラー例外
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--  
  -- INパラメータをレコード変数に代入
    lr_notes_data_rec := io_notes_data_rec;
--
    BEGIN
    -- =========================
    -- 顧客マスタ存在チェック
    -- =========================
      -- 顧客マスタビューから顧客コード、パーティID、顧客名称抽出する
      -- 該当データが存在しない場合は警告とする
      SELECT xcav.account_number account_number,    -- 顧客コード
             xcav.party_id party_id,                -- パーティID
             xcav.account_name account_name         -- 顧客名称
      INTO   lt_account_number,                     -- 顧客コード
             lt_party_id,                           -- パーティID
             lt_account_name                        -- 顧客名称
      FROM   xxcso_cust_accounts_v  xcav
      WHERE  xcav.account_number = lr_notes_data_rec.account_number
        AND  xcav.account_status = cv_active_status 
        AND  xcav.party_status   = cv_active_status;
--
      -- 取得した顧客マスタデータをOUTパラメータに設定
      io_notes_data_rec.account_number   := lt_account_number;            -- 顧客コード
      io_notes_data_rec.party_id         := lt_party_id;                  -- パーティID
      io_notes_data_rec.account_name     := lt_account_name;              -- 顧客名称
      -- ログに出力
      fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg10  || CHR(10) ||
                 cv_account_number || lt_account_number || CHR(10) ||
                 cv_party_id || lt_party_id  || CHR(10) ||
                 cv_account_name || lt_account_name || CHR(10) ||
                 ''
      );
    EXCEPTION
    -- 顧客コードが存在しない場合の後処理
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_03         -- メッセージコード
                      ,iv_token_name1  => cv_tkn_tbl               -- トークンコード1
                      ,iv_token_value1 => cv_table_name1           -- トークン値1顧客マスタビュー名
                      ,iv_token_name2  => cv_tkn_sequence          -- トークンコード2
                      ,iv_token_value2 => io_notes_data_rec.no_seq -- トークン値2シーケンス番号
                      ,iv_token_name3  => cv_tkn_account_cd                 -- トークンコード3
                      ,iv_token_value3 => io_notes_data_rec.account_number  -- トークン値3顧客コード
                      ,iv_token_name4  => cv_tkn_account_nm                 -- トークンコード4
                      ,iv_token_value4 => io_notes_data_rec.account_name    -- トークン値4顧客名称
                      ,iv_token_name5  => cv_tkn_sales_cd                   -- トークンコード5
                      ,iv_token_value5 => io_notes_data_rec.employee_number -- トークン値5営業員コード
                      ,iv_token_name6  => cv_tkn_sales_nm                   -- トークンコード6
                      ,iv_token_value6 => io_notes_data_rec.full_name       -- トークン値6営業員名称
                      ,iv_token_name7  => cv_tkn_date                       -- トークンコード7
                      ,iv_token_value7 => io_notes_data_rec.input_date      -- トークン値7入力日付
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE  warning_expt;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_01         -- メッセージコード
                      ,iv_token_name1  => cv_tkn_tbl               -- トークンコード1
                      ,iv_token_value1 => cv_table_name1           -- トークン値1顧客マスタビュー名
                      ,iv_token_name2  => cv_tkn_errmsg            -- トークンコード2
                      ,iv_token_value2 => SQLERRM                  -- トークン値2SQLERRM                      
                      ,iv_token_name3  => cv_tkn_sequence          -- トークンコード3
                      ,iv_token_value3 => io_notes_data_rec.no_seq -- トークン値3シーケンス番号
                      ,iv_token_name4  => cv_tkn_account_cd                 -- トークンコード4
                      ,iv_token_value4 => io_notes_data_rec.account_number  -- トークン値4顧客コード
                      ,iv_token_name5  => cv_tkn_account_nm                 -- トークンコード5
                      ,iv_token_value5 => io_notes_data_rec.account_name    -- トークン値5顧客名称
                      ,iv_token_name6  => cv_tkn_sales_cd                   -- トークンコード6
                      ,iv_token_value6 => io_notes_data_rec.employee_number -- トークン値6営業員コード
                      ,iv_token_name7  => cv_tkn_sales_nm                   -- トークンコード7
                      ,iv_token_value7 => io_notes_data_rec.full_name       -- トークン値7営業員名称
                      ,iv_token_name8  => cv_tkn_date                       -- トークンコード8
                      ,iv_token_value8 => io_notes_data_rec.input_date      -- トークン値8入力日付
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE  select_data_expt;  
--
    END;
--
    -- =================================
    -- 営業員コードマスタ存在チェック
    -- =================================
--
    BEGIN
      -- リソースマスタビューからリソースID、営業員名称、ユーザーID抽出する
      -- 該当データが存在しない場合は警告とする
      SELECT xrv.resource_id resource_id         -- リソースID
            ,xrv.full_name full_name             -- 営業員名称
            ,xrv.user_id user_id                 -- ユーザーID
      INTO   lt_resource_id,                     -- リソースID
             lt_full_name,                       -- 営業員名称
             lt_user_id                          -- ユーザーID
      FROM   xxcso_resources_v  xrv
      WHERE  xrv.employee_number = lr_notes_data_rec.employee_number
        AND  lr_notes_data_rec.input_date 
             BETWEEN TRUNC(xrv.start_date) AND 
             TRUNC(NVL(xrv.end_date,lr_notes_data_rec.input_date))
        AND  lr_notes_data_rec.input_date 
             BETWEEN TRUNC(xrv.employee_start_date) AND 
             TRUNC(NVL(xrv.employee_end_date, lr_notes_data_rec.input_date))
        AND  lr_notes_data_rec.input_date 
             BETWEEN TRUNC(xrv.assign_start_date) AND 
             TRUNC(NVL(xrv.assign_end_date, lr_notes_data_rec.input_date))
        AND  lr_notes_data_rec.input_date 
             BETWEEN TRUNC(xrv.resource_start_date) AND 
-- 障害対応064
--             TRUNC(NVL(xrv.resource_start_date, lr_notes_data_rec.input_date));
             TRUNC(NVL(xrv.resource_end_date, lr_notes_data_rec.input_date));
--
      -- 取得したリソースマスタデータをOUTパラメータに設定
      io_notes_data_rec.resource_id    := lt_resource_id;               -- リソースID
      io_notes_data_rec.full_name      := lt_full_name;                 -- 営業員名称
      io_notes_data_rec.user_id        := lt_user_id;                   -- ユーザーID
      -- ログに出力
      fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg11  || CHR(10) ||
                 cv_resource_id  || lt_resource_id || CHR(10) ||
                 cv_full_name    || lt_full_name   || CHR(10) ||
                 cv_user_id      || lt_user_id     || CHR(10) ||
                 ''
      );
--
    EXCEPTION
    -- 営業員コードが存在しない場合の後処理
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_04         -- メッセージコード
                      ,iv_token_name1  => cv_tkn_tbl               -- トークンコード1
                      ,iv_token_value1 => cv_table_name2           -- トークン値1リソースマスタビュー名
                      ,iv_token_name2  => cv_tkn_sequence          -- トークンコード2
                      ,iv_token_value2 => io_notes_data_rec.no_seq -- トークン値2シーケンス番号
                      ,iv_token_name3  => cv_tkn_account_cd                 -- トークンコード3
                      ,iv_token_value3 => io_notes_data_rec.account_number  -- トークン値3顧客コード
                      ,iv_token_name4  => cv_tkn_account_nm                 -- トークンコード4
                      ,iv_token_value4 => io_notes_data_rec.account_name    -- トークン値4顧客名称
                      ,iv_token_name5  => cv_tkn_sales_cd                   -- トークンコード5
                      ,iv_token_value5 => io_notes_data_rec.employee_number -- トークン値5営業員コード
                      ,iv_token_name6  => cv_tkn_sales_nm                   -- トークンコード6
                      ,iv_token_value6 => io_notes_data_rec.full_name       -- トークン値6営業員名称
                      ,iv_token_name7  => cv_tkn_date                       -- トークンコード7
                      ,iv_token_value7 => io_notes_data_rec.input_date      -- トークン値7入力日付
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE warning_expt;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_01         -- メッセージコード
                      ,iv_token_name1  => cv_tkn_tbl               -- トークンコード1
                      ,iv_token_value1 => cv_table_name2           -- トークン値1リソースマスタビュー名
                      ,iv_token_name2  => cv_tkn_errmsg            -- トークンコード2
                      ,iv_token_value2 => SQLERRM                  -- トークン値2SQLERRM                      
                      ,iv_token_name3  => cv_tkn_sequence          -- トークンコード3
                      ,iv_token_value3 => io_notes_data_rec.no_seq -- トークン値3シーケンス番号
                      ,iv_token_name4  => cv_tkn_account_cd                 -- トークンコード4
                      ,iv_token_value4 => io_notes_data_rec.account_number  -- トークン値4顧客コード
                      ,iv_token_name5  => cv_tkn_account_nm                 -- トークンコード5
                      ,iv_token_value5 => io_notes_data_rec.account_name    -- トークン値5顧客名称
                      ,iv_token_name6  => cv_tkn_sales_cd                   -- トークンコード6
                      ,iv_token_value6 => io_notes_data_rec.employee_number -- トークン値6営業員コード
                      ,iv_token_name7  => cv_tkn_sales_nm                   -- トークンコード7
                      ,iv_token_value7 => io_notes_data_rec.full_name       -- トークン値7営業員名称
                      ,iv_token_name8  => cv_tkn_date                       -- トークンコード8
                      ,iv_token_value8 => io_notes_data_rec.input_date      -- トークン値8入力日付
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE  select_data_expt;  
--
    END;
--
  EXCEPTION
    -- データが存在しない例外
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- データ抽出エラー例外
    WHEN select_data_expt THEN
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
  END master_exist_check;
--
  /**********************************************************************************
   * Procedure Name   : insert_notes
   * Description      : ノート情報登録(A-4)
   **********************************************************************************/
  PROCEDURE insert_notes(
    io_notes_data_rec  IN OUT  NOCOPY  g_get_notes_data_rtype,  -- ノートワークテーブルデータ
    ov_errbuf             OUT  NOCOPY  VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT  NOCOPY  VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg             OUT  NOCOPY  VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT  VARCHAR2(100) := 'insert_notes'; -- プログラム名
    cv_source_object_cd  CONSTANT  VARCHAR2(5)   := 'PARTY';        -- API関数用
    cv_note_status       CONSTANT  VARCHAR2(1)   := 'I';            -- API関数用
    cv_p_commit          CONSTANT  VARCHAR2(1)   := 'F';            -- API関数用
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
--
    -- *** ローカル定数 ***
    cv_table_name           CONSTANT VARCHAR2(20)   := 'ノート情報';     -- ノート情報テーブル名
    cv_process_name         CONSTANT VARCHAR2(20)   := '登録';           -- プロセス名
--
    -- *** ローカル変数 ***
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    lv_msg_data         VARCHAR2(2000);
    ln_note_id          NUMBER;
--
    lt_no_seq                xxcso_in_notes.no_seq%TYPE;                 -- シーケンス番号
    lt_account_number        xxcso_in_notes.account_number%TYPE;         -- 顧客コード
    lt_employee_number       xxcso_in_notes.employee_number%TYPE;        -- 営業員コード
    lt_account_name          xxcso_cust_accounts_v.account_name%TYPE;    -- 顧客名称
    lt_full_name             xxcso_resources_v.full_name%TYPE;           -- 営業員名称
    lt_input_date            xxcso_in_notes.input_date%TYPE;             -- 入力日付
    lt_party_id              xxcso_cust_accounts_v.party_id%TYPE;        -- パーティID
    lt_resource_id           xxcso_resources_v.resource_id%TYPE;         -- リソースID
    lt_user_id               xxcso_resources_v.user_id%TYPE;             -- ユーザーID
    lt_notes                 xxcso_in_notes.notes%TYPE;                  -- ノート内容
    lv_note_type             VARCHAR2(2000);                             -- ノートタイプ

    ln_dummy_cnt             NUMBER(10);         -- API関数LOG出力用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_notes_data_rec   g_get_notes_data_rtype;   -- INパラメータ.ノートワークテーブルデータ格納
--
    -- *** ローカル例外 ***
    warning_expt   EXCEPTION;            -- データ登録例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
  -- INパラメータをローカルレコード、変数に代入
    lr_notes_data_rec     := io_notes_data_rec;
  -- ノートワークテーブル抽出データをローカル変数に代入
    lt_no_seq             := lr_notes_data_rec.no_seq;             -- シーケンス番号
    lt_account_number     := lr_notes_data_rec.account_number;     -- 顧客コード
    lt_employee_number    := lr_notes_data_rec.employee_number;    -- 営業員コード
    lt_account_name       := lr_notes_data_rec.account_name;       -- 顧客名称
    lt_full_name          := lr_notes_data_rec.full_name;          -- 営業員名称
    lt_input_date         := lr_notes_data_rec.input_date;         -- 入力日付
    lt_party_id           := lr_notes_data_rec.party_id;           -- パーティID
    lt_resource_id        := lr_notes_data_rec.resource_id;        -- リソースID
    lt_user_id            := lr_notes_data_rec.user_id;            -- ユーザーID
    lt_notes              := lr_notes_data_rec.notes;              -- ノート内容
    lv_note_type          := lr_notes_data_rec.note_type;          -- ノートタイプ
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ******************
    -- * ノート情報登録 *
    -- ******************
--
    -- ノートデータ登録処理
    -- ノート登録トランザクションの作成
    JTF_NOTES_PUB.CREATE_NOTE(
       p_api_version         => 1.0                       -- バージョンナンバー
      ,p_init_msg_list       => FND_API.G_TRUE            -- p_init_msg_list
      ,p_commit              => cv_p_commit               -- コミット
      ,x_return_status       => lv_return_status          -- リターンステータス
      ,x_msg_count           => ln_msg_count              -- x_msg_count
      ,x_msg_data            => lv_msg_data               -- x_msg_data
      ,p_source_object_id    => lt_party_id               -- ソースオブジェクトID
      ,p_source_object_code  => cv_source_object_cd       -- ソースオブジェクトコード
      ,p_notes               => lt_notes                  -- ノート記述
      ,p_note_status         => cv_note_status            -- ノートステータス
      ,p_note_type           => lv_note_type              -- ノートタイプ
      ,p_entered_by          => lt_user_id                -- ノート登録者
      ,p_entered_date        => lt_input_date             -- ノート登録日
      ,x_jtf_note_id         => ln_note_id                -- ノートID
      ,p_last_update_date    => cd_last_update_date       -- ノート最終更新日
      ,p_last_updated_by     => cn_last_updated_by        -- ノート最終更新者
      ,p_creation_date       => cd_creation_date          -- ノート作成日
      ,p_created_by          => cn_last_updated_by        -- ノート作成者
      ,p_last_update_login   => cn_last_update_login      -- ノート最終更新ログインID
      );
--
-- *** ノート情報登録例外 ***
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05         -- メッセージコード
                      ,iv_token_name1  => cv_tkn_tbl               -- トークンコード1
                      ,iv_token_value1 => cv_table_name            -- トークン値1ノート情報テーブル名
                      ,iv_token_name2  => cv_tkn_errmsg            -- トークンコード2
                      ,iv_token_value2 => SQLERRM                  -- トークン値2SQLERRM 
                      ,iv_token_name3  => cv_tkn_sequence          -- トークンコード3
                      ,iv_token_value3 => lt_no_seq                -- トークン値3シーケンス番号
                      ,iv_token_name4  => cv_tkn_account_cd        -- トークンコード4
                      ,iv_token_value4 => lt_account_number        -- トークン値4顧客コード
                      ,iv_token_name5  => cv_tkn_account_nm        -- トークンコード5
                      ,iv_token_value5 => lt_account_name          -- トークン値5顧客名称
                      ,iv_token_name6  => cv_tkn_sales_cd          -- トークンコード6
                      ,iv_token_value6 => lt_employee_number       -- トークン値6営業員コード
                      ,iv_token_name7  => cv_tkn_sales_nm          -- トークンコード7
                      ,iv_token_value7 => lt_full_name             -- トークン値7営業員名称
                      ,iv_token_name8  => cv_tkn_date              -- トークンコード8
                      ,iv_token_value8 => lt_input_date            -- トークン値8入力日付
                  );
      lv_errbuf := lv_errmsg;
      -- APIエラーメッセージのログ出力
      <<count_msg_loop>>
      FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG LOOP
        -- メッセージ取得
        FND_MSG_PUB.GET(
           p_msg_index      => i
          ,p_encoded        => FND_API.G_FALSE
          ,p_data           => lv_msg_data
          ,p_msg_index_out  => ln_dummy_cnt
        );
        -- ログ出力
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg_data);
        lv_errbuf := SUBSTRB(lv_errbuf||lv_msg_data,5000);
      END LOOP count_msg_loop;
--
      RAISE warning_expt;
    END IF;
    fnd_file.put_line(
          which  => FND_FILE.LOG,
          buff   => cv_debug_msg1
    );    
--
  EXCEPTION
--
    -- 警告処理例外
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_notes;
--
 /**********************************************************************************
   * Procedure Name   : del_notes_data
   * Description      : ノートワークテーブルデータ削除(A-6)
-- **********************************************************************************/
  PROCEDURE del_notes_data(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'del_notes_data';       -- プログラム名
    cv_table_name_note_wrk  CONSTANT VARCHAR2(20)   := 'ノートワークテーブル'; -- ノートワークテーブル名
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
    -- *** ローカル・例外 ***
    del_tbl_data_expt     EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- ***************************************************
    -- ***       ノートワークテーブルデータ削除        ***
    -- ***************************************************
    BEGIN
      DELETE
      FROM  xxcso_in_notes xin;
--
      fnd_file.put_line(
        which  => FND_FILE.LOG,
        buff   => cv_debug_msg2
      );
--
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06         -- メッセージコード データ削除エラー
                       ,iv_token_name1  => cv_tkn_tbl               -- トークンコード1
                       ,iv_token_value1 => cv_table_name_note_wrk   -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_errmsg            -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- ORACLEエラー
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE del_tbl_data_expt;
    END;
--    
  EXCEPTION
    -- *** データ削除時の例外ハンドラ ***
    WHEN del_tbl_data_expt THEN
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
  END del_notes_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
    cv_table_name  CONSTANT VARCHAR2(100) := 'ノートワークテーブル';   -- ノートワークテーブル名
--
    -- *** ローカル変数 ***
    lv_note_type            VARCHAR2(2000);                            -- ノートタイプ
    lv_err_rec_info         VARCHAR2(5000);                            --　データ項目全部の内容
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ノートワークテーブルデータを取得するカーソル
    CURSOR xin_data_cur
    IS
      SELECT xin.no_seq                no_seq                          -- シーケンス番号
            ,xin.account_number        account_number                  -- 顧客コード
            ,xin.notes                 notes                           -- ノート
            ,xin.employee_number       employee_number                 -- 営業員コード
            ,xin.input_date            input_date                      -- 入力日付
            ,xin.input_time            input_time                      -- 入力時刻
            ,xin.coalition_trance_date coalition_trance_date           -- 連携処理日
      FROM  xxcso_in_notes   xin
      ORDER BY xin.no_seq  ASC;
    -- *** ローカル・レコード ***
    lr_xin_data_rec       xin_data_cur%ROWTYPE;
    lr_get_data_rec       g_get_notes_data_rtype;   -- INパラメータ.ノートワークテーブルデータ格納
    -- *** ローカル例外 ***
    error_skip_data_expt       EXCEPTION;             -- データスキップ例外
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
    -- ===============
    -- A-1.初期処理
    -- ===============
    init(
       ov_note_type      => gv_note_type        -- ノートタイプ
      ,ov_errbuf         => lv_errbuf           -- エラー・メッセージ            --# 固定 #
      ,ov_retcode        => lv_retcode          -- リターン・コード              --# 固定 #
      ,ov_errmsg         => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
   -- DEBUG用
   fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => ' A-2.ノートワークテーブルデータ抽出開始：');
--
    -- ====================================
    -- A-2.ノートワークテーブルデータ抽出
    -- ====================================
    -- カーソルオープン
    OPEN xin_data_cur;
--
    <<get_data_loop>>
    LOOP
      
      BEGIN
        FETCH xin_data_cur INTO lr_xin_data_rec;
--
        -- 処理対象件数格納
        gn_target_cnt := xin_data_cur%ROWCOUNT;
--
        -- DEBUG用
        fnd_file.put_line(
          which => FND_FILE.LOG
          ,buff  => ' A-2.処理対象件数：'|| gn_target_cnt);
--
        EXIT WHEN xin_data_cur%NOTFOUND
        OR  xin_data_cur%ROWCOUNT = 0;
--
        -- レコード変数初期化
        lr_get_data_rec := NULL;
--
        lr_get_data_rec.no_seq                 := lr_xin_data_rec.no_seq;                -- シーケンス番号
        lr_get_data_rec.account_number         := lr_xin_data_rec.account_number;        -- 顧客コード
        lr_get_data_rec.notes                  := lr_xin_data_rec.notes;                 -- ノート
        lr_get_data_rec.employee_number        := lr_xin_data_rec.employee_number;       -- 営業員コード
        lr_get_data_rec.input_date             := lr_xin_data_rec.input_date;            -- 入力日付
        lr_get_data_rec.input_time             := lr_xin_data_rec.input_time;            -- 入力時刻
        lr_get_data_rec.coalition_trance_date  := lr_xin_data_rec.coalition_trance_date; -- 連携処理日
        lr_get_data_rec.note_type              := gv_note_type;                          -- ノートタイプ
--
        -- INPUTデータの項目をカンマ区切りで文字連結してログに出力する用
        lv_err_rec_info := lr_get_data_rec.no_seq||','
                        || lr_get_data_rec.notes ||','
                        || lr_get_data_rec.account_number||','
                        || lr_get_data_rec.employee_number||','
                        || lr_get_data_rec.input_date||','
                        || lr_get_data_rec.input_time||','
                        || lr_get_data_rec.coalition_trance_date||','
                        || lr_get_data_rec.note_type;
        fnd_file.put_line(
          which => FND_FILE.LOG
          ,buff  => cv_debug_msg8 || lv_err_rec_info);
--
        -- ================================================
        -- A-3.顧客コード、営業員コードマスタ存在チェック
        -- ================================================
--
        master_exist_check(
          io_notes_data_rec =>lr_get_data_rec,   -- ノートワークテーブルデータ
          ov_errbuf         =>lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          ov_retcode        =>lv_retcode,        -- リターン・コード             --# 固定 #
          ov_errmsg         =>lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;  
        END IF;
--
        -- ========================
        -- A-4.ノート情報登録処理
        -- ========================
--
        insert_notes(
          io_notes_data_rec  =>lr_get_data_rec,     -- ノート情報データ
          ov_errbuf          =>lv_errbuf,           -- エラー・メッセージ           --# 固定 #
          ov_retcode         =>lv_retcode,          -- リターン・コード             --# 固定 #
          ov_errmsg          =>lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE error_skip_data_expt;
        END IF;
        -- ========================
        -- A-5.セーブポイント設定
        -- ========================
        SAVEPOINT a;
        fnd_file.put_line(
            which  => FND_FILE.LOG,
            buff   => cv_debug_msg3
          );
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- データチェック、登録エラーにてスキップ
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
              ,buff   => lv_err_rec_info || ' ' || lv_errbuf || CHR(10) ||
                         ''
            );
          -- ロールバック
          IF (gn_normal_cnt = 0) THEN
            ROLLBACK;
            fnd_file.put_line(
                  which  => FND_FILE.LOG,
                  buff   => cv_debug_msg4
                );
          ELSE
            ROLLBACK TO SAVEPOINT a;
            fnd_file.put_line(
                  which  => FND_FILE.LOG,
                  buff   => cv_debug_msg5
                );
          END IF;
          -- 全体の処理ステータスに警告セット
          ov_retcode := cv_status_warn;
      END;
--
    END LOOP get_data_loop;
--
    -- カーソルクローズ
    CLOSE xin_data_cur;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''  || CHR(10) ||
                 cv_debug_msg9 ||
                 ''
    );
--
    -- ========================================
    -- A-6.ノートワークテーブルデータ削除処理
    -- ========================================
    del_notes_data(
      ov_errbuf           =>lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode          =>lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg           =>lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
-- 
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN error_skip_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルがクローズされていない場合
      IF (xin_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xin_data_cur;
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''  || CHR(10) ||
                 cv_debug_msg9 ||
                 ''
        );
      END IF;
--
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (xin_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xin_data_cur;
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''  || CHR(10) ||
                 cv_debug_msg9 ||
                 ''
        );
      END IF;
--
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_01         -- メッセージコード
                      ,iv_token_name1  => cv_tkn_tbl               -- トークンコード1
                      ,iv_token_value1 => cv_table_name            -- トークン値1ノートワークテーブル名
                      ,iv_token_name2  => cv_tkn_errmsg            -- トークンコード2
                      ,iv_token_value2 => SQLERRM                  -- トークン値2SQLERRM                      
                      ,iv_token_name3  => cv_tkn_sequence          -- トークンコード3
                      ,iv_token_value3 => lr_get_data_rec.no_seq   -- トークン値3シーケンス番号
                      ,iv_token_name4  => cv_tkn_account_cd               -- トークンコード4
                      ,iv_token_value4 => lr_get_data_rec.account_number  -- トークン値4顧客コード
                      ,iv_token_name5  => cv_tkn_account_nm               -- トークンコード5
                      ,iv_token_value5 => lr_get_data_rec.account_name    -- トークン値5顧客名称
                      ,iv_token_name6  => cv_tkn_sales_cd                 -- トークンコード6
                      ,iv_token_value6 => lr_get_data_rec.employee_number -- トークン値6営業員コード
                      ,iv_token_name7  => cv_tkn_sales_nm                 -- トークンコード7
                      ,iv_token_value7 => lr_get_data_rec.full_name       -- トークン値7営業員名称
                      ,iv_token_name8  => cv_tkn_date                     -- トークンコード8
                      ,iv_token_value8 => lr_get_data_rec.input_date      -- トークン値8入力日付
                     );
      -- カーソルがクローズされていない場合
      IF (xin_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xin_data_cur;
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''  || CHR(10) ||
                 cv_debug_msg9 ||
                 ''
        );
      END IF;
--
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
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
    errbuf        OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT NOCOPY VARCHAR2       --   リターン・コード    --# 固定 #
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
    
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_message_code  VARCHAR2(100);  -- 終了メッセージ名格納
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
       ov_errbuf   =>lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  =>lv_retcode  -- リターン・コード             --# 固定 #
      ,ov_errmsg   =>lv_errmsg   -- ユーザー・エラー・メッセージ  --# 固定 #
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
    -- ===============
    -- A-7.終了処理
    -- ===============
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
END XXCSO014A05C;
/
