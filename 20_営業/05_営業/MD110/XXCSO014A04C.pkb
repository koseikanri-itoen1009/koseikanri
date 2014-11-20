CREATE OR REPLACE PACKAGE BODY XXCSO014A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A04C(body)
 * Description      : ルート情報ワークテーブル(アドオン)に取り込まれたルート情報を、
 *                    顧客情報と関連付けてEBS上の顧客マスタに登録します。
 *                    
 * MD.050           : MD050_CSO_014_A04_HHT-EBSインターフェース：(IN）ルート情報
 *                    
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  chk_mst_is_exists           マスタ存在チェック (A-3)
 *  chk_is_new_recode           最新レコードチェック (A-4)
 *  upd_route_info              ルート情報テーブルデータ登録及び更新 (A-5)
 *  del_wrk_tbl_data            ルート情報ワークテーブルデータ削除 (A-7)
 *  submain                     メイン処理プロシージャ
 *                                ルート情報ワークテーブルデータ抽出 (A-2)
 *                                セーブポイント設定 (A-6)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                終了処理(A-8)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-1-16    1.0   Kenji.Sai        新規作成
 *  2009-2-18    1.1   Kenji.Sai        データ抽出エラーは警告、スキップ処理にする 
 *
 *****************************************************************************************/
-- 
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
--
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_skip_cnt      NUMBER;                    -- スキップ件数
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A04C';      -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- アクティブ
--
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00390';  -- データ抽出エラー
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00391';  -- 顧客コードなし警告
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00393';  -- データ更新エラー
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';  -- データ削除エラー
--
  -- トークンコード
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';  
  cv_tkn_sequence        CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_cstm_cd         CONSTANT VARCHAR2(20) := 'CUSTOMERCODE';
  cv_tkn_cstm_nm         CONSTANT VARCHAR2(20) := 'CUSTOMERNAME';
  cv_route_cd            CONSTANT VARCHAR2(20) := 'ROUTECODE';
  cv_tkn_ym              CONSTANT VARCHAR2(20) := 'DATE';
  cv_tkn_cnt             CONSTANT VARCHAR2(20) := 'COUNT';
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<<スキップ処理されたデータ>>';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_process_date        DATE;                                                 -- 業務処理日
  -- ファイル・ハンドルの宣言
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 取得情報格納レコード型定義
--
  -- ルート情報ワークテーブル＆関連情報抽出データ
  TYPE g_get_route_info_rtype IS RECORD(
    no_seq                xxcso_in_route_no.no_seq%TYPE,                 -- シーケンス番号
    record_number         xxcso_in_route_no.record_number%TYPE,          -- レコード番号
    account_number        xxcso_in_route_no.account_number%TYPE,         -- 顧客コード
    route_no              xxcso_in_route_no.route_no%TYPE,               -- ルートNO
    input_date            xxcso_in_route_no.input_date%TYPE,             -- 入力日付（DATE型）
    coalition_trance_date xxcso_in_route_no.coalition_trance_date%TYPE,  -- 連携処理日（DATE型）
    input_date_ymd        VARCHAR2(8),                                   -- 入力日付（VARCHAR2:YYYYMMDD）
    account_name          xxcso_cust_accounts_v.account_name%TYPE        -- 顧客名称
  );
  -- テーブル型定義
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
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
    cv_app_name2           CONSTANT VARCHAR2(10)     := 'XXCCP';             -- アドオン：共通・IF領域
    cv_no_para_msg         CONSTANT VARCHAR2(100)    := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
    -- *** ローカル変数 ***
    lv_noprm_msg    VARCHAR2(5000);  -- コンカレント入力パラメータなしメッセージ格納用
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
                        iv_application  => cv_app_name2,             -- アプリケーション短縮名
                        iv_name         => cv_no_para_msg            -- メッセージコード
                      );
    -- メッセージ出力
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => ''           || CHR(10) ||     -- 空行の挿入
                lv_noprm_msg || CHR(10) ||
                 ''                            -- 空行の挿入
    );
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
   * Procedure Name   : chk_mst_is_exists                                  
   * Description      : マスタ存在チェック (A-3)
   ***********************************************************************************/
  PROCEDURE chk_mst_is_exists(
    io_route_info_rec       IN OUT NOCOPY g_get_route_info_rtype,  -- ルート情報ワークテーブル＆関連情報抽出データ
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_mst_is_exists';     -- プログラム名
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
    cv_table_name        CONSTANT VARCHAR2(100) := '顧客マスタビュー';            -- 顧客マスタビュー名
    -- *** ローカル変数 ***
    lt_account_name        xxcso_cust_accounts_v.account_name%TYPE;               -- 顧客名称
--
    -- *** ローカル・レコード ***
    l_route_info_rec  g_get_route_info_rtype; 
-- INパラメータ.ルート情報ワークテーブルデータ格納
    --*** ローカル・例外 ***
    warning_expt       EXCEPTION;
-- 
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- INパラメータをレコード変数に代入
    l_route_info_rec := io_route_info_rec;
--
    -- ===========================
    -- 顧客マスタ存在チェック 
    -- ===========================
    BEGIN
--
      -- 顧客マスタビューから顧客名称を抽出する
      SELECT xcav.account_name account_name          -- 顧客コード
      INTO   lt_account_name                         -- 顧客コード 
      FROM   xxcso_cust_accounts_v xcav              -- 顧客マスタビュー
      WHERE  xcav.account_number = io_route_info_rec.account_number    -- 顧客コード
        AND  xcav.account_status = cv_active_status                    -- 顧客ステータス（A)
        AND  xcav.party_status   = cv_active_status;                   -- パーティステータス（A)
--
      -- 取得した顧客マスタデータをOUTパラメータに設定
      io_route_info_rec.account_name      := lt_account_name;            -- 顧客名称
--
    EXCEPTION
      -- *** 該当データが存在しない例外ハンドラ ***
      WHEN NO_DATA_FOUND THEN
      -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02                         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                               -- トークンコード1
                       ,iv_token_value1 => cv_table_name                            -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_sequence                          -- トークンコード2
                       ,iv_token_value2 => io_route_info_rec.no_seq                 -- シーケンス番号
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- トークンコード3
                       ,iv_token_value3 => io_route_info_rec.account_number         -- 顧客コード
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- トークンコード4
                       ,iv_token_value4 => io_route_info_rec.account_name           -- 顧客名称
                       ,iv_token_name5  => cv_route_cd                              -- トークンコード5
                       ,iv_token_value5 => io_route_info_rec.route_no               -- ルートコード
                       ,iv_token_name6  => cv_tkn_ym                                -- トークンコード6
                       ,iv_token_value6 => io_route_info_rec.input_date_ymd         -- 入力日付
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01                         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_errmsg                            -- トークンコード1
                       ,iv_token_value1 => SQLERRM                                  -- SQLERRM
                       ,iv_token_name2  => cv_tkn_tbl                               -- トークンコード2
                       ,iv_token_value2 => cv_table_name                            -- エラー発生のテーブル名
                       ,iv_token_name3  => cv_tkn_sequence                          -- トークンコード3
                       ,iv_token_value3 => io_route_info_rec.no_seq                 -- シーケンス番号
                       ,iv_token_name4  => cv_tkn_cstm_cd                           -- トークンコード4
                       ,iv_token_value4 => io_route_info_rec.account_number         -- 顧客コード
                       ,iv_token_name5  => cv_tkn_cstm_nm                           -- トークンコード5
                       ,iv_token_value5 => io_route_info_rec.account_name           -- 顧客名称
                       ,iv_token_name6  => cv_route_cd                              -- トークンコード6
                       ,iv_token_value6 => io_route_info_rec.route_no               -- ルートコード
                       ,iv_token_name7  => cv_tkn_ym                                -- トークンコード7
                       ,iv_token_value7 => io_route_info_rec.input_date_ymd         -- 入力日付
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
    END;
--    
  EXCEPTION
--
    -- *** 該当データが存在しない、データ抽出エラー発生時エラー発生時の例外ハンドラ ***
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ステータスは警告
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_mst_is_exists;
--
  /**********************************************************************************
   * Procedure Name   : chk_is_new_recode                                             
   * Description      : 最新レコードチェック (A-4)
   ***********************************************************************************/
  PROCEDURE chk_is_new_recode(
    io_route_info_rec       IN OUT NOCOPY g_get_route_info_rtype, -- ルート情報ワークテーブルデータ
    ob_not_exists_new_data  OUT BOOLEAN,                          -- 最新レコードチェックフラグ
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_is_new_recode';     -- プログラム名
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
    -- *** ローカル・定数 ***
    cv_table_name       CONSTANT VARCHAR2(100)  := 'ルート情報ワークテーブル';   -- ルート情報ワークテーブル
    -- *** ローカル・変数 ***
    lt_max_no_seq          xxcso_in_route_no.no_seq%TYPE;          -- 最大シーケンス番号
    lv_table_name          VARCHAR2(200);                          -- テーブル名
    lb_not_exists_new_data BOOLEAN;                                -- 最新レコード存在チェックフラグ
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・例外 ***
    select_error_expt EXCEPTION;
--    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    --当該レコードより最新レコードが存在するかを判断するチェックフラグの初期化
    lb_not_exists_new_data := cb_true;                    -- 最新レコードが存在しない
--
    -- ================================================================
    -- ルート情報ワークテーブルから該当最大シーケンス番号を取得 
    -- ================================================================
    BEGIN
      SELECT  MAX(xirn.no_seq) max_no_seq      -- 最大シーケンス番号
      INTO    lt_max_no_seq                    -- 最大シーケンス番号 
      FROM    xxcso_in_route_no  xirn          -- ルート情報ワークテーブル
      WHERE   xirn.account_number = io_route_info_rec.account_number;        -- 顧客コード
--
      -- 当該レコードのシーケンス番号が最大シーケンス番号より、大きい場合、スキップする
      -- 当該レコードのシーケンス番号が最大シーケンス番号と同じ場合、正常
      IF (lt_max_no_seq > io_route_info_rec.no_seq) THEN
        lb_not_exists_new_data := cb_false;               -- 最新レコードが存在する
      END IF;
      -- 取得した最新レコードチェック結果をOUTパラメータに設定
      ob_not_exists_new_data := lb_not_exists_new_data;
--
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01                         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_errmsg                            -- トークンコード1
                       ,iv_token_value1 => SQLERRM                                  -- SQLERRM
                       ,iv_token_name2  => cv_tkn_tbl                               -- トークンコード2
                       ,iv_token_value2 => cv_table_name                            -- エラー発生のテーブル名
                       ,iv_token_name3  => cv_tkn_sequence                          -- トークンコード3
                       ,iv_token_value3 => io_route_info_rec.no_seq                 -- シーケンス番号
                       ,iv_token_name4  => cv_tkn_cstm_cd                           -- トークンコード4
                       ,iv_token_value4 => io_route_info_rec.account_number         -- 顧客コード
                       ,iv_token_name5  => cv_tkn_cstm_nm                           -- トークンコード5
                       ,iv_token_value5 => io_route_info_rec.account_name           -- 顧客名称
                       ,iv_token_name6  => cv_route_cd                              -- トークンコード6
                       ,iv_token_value6 => io_route_info_rec.route_no               -- ルートコード
                       ,iv_token_name7  => cv_tkn_ym                                -- トークンコード7
                       ,iv_token_value7 => io_route_info_rec.input_date_ymd         -- 入力日付
                      );
          lv_errbuf  := lv_errmsg||SQLERRM;
          RAISE select_error_expt;
    END;
--
  EXCEPTION
    -- *** データ抽出時の例外ハンドラ ***
    WHEN select_error_expt THEN
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_is_new_recode;
--
  /**********************************************************************************
   * Procedure Name   : upd_route_info                                                               
   * Description      : ルート情報データの登録及び更新 (A-5)
   ***********************************************************************************/
  PROCEDURE upd_route_info(
    io_route_info_rec        IN OUT NOCOPY g_get_route_info_rtype,   -- ルート情報ワークテーブルデータ
    ov_errbuf                OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_route_info';     -- プログラム名
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
    -- ルート情報テーブル名をローカル変数に代入
    cv_table_name          CONSTANT VARCHAR2(100) := '組織プロファイル拡張テーブル';  -- 組織プロファイル拡張テーブル
    -- *** ローカル変数 ***
    lv_msg_code            VARCHAR2(100);                                             -- メッセージコード
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・例外 ***
    ins_upd_expt      EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 共通関数により、ルート情報テーブルのデータ更新を行う
    xxcso_rtn_rsrc_pkg.regist_route_no(
                         iv_account_number => io_route_info_rec.account_number,          -- 顧客コード
                         iv_route_no       => io_route_info_rec.route_no,                -- ルートNo
                         id_start_date     => TRUNC(io_route_info_rec.input_date,'MM'),  -- 入力日付
                         ov_errbuf         => lv_errbuf,                             -- ユーザー・エラー・メッセージ
                         ov_retcode        => lv_retcode,                            -- リターン・コード 
                         ov_errmsg         => lv_errmsg                              -- エラー・メッセージ
                       );
--
    IF (lv_retcode <> cv_status_normal) THEN
      -- エラーメッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                              -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_03                         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_errmsg                            -- トークンコード1
                     ,iv_token_value1 => SQLERRM                                  -- SQLERRM
                     ,iv_token_name2  => cv_tkn_tbl                               -- トークンコード2
                     ,iv_token_value2 => cv_table_name                            -- エラー発生のテーブル名
                     ,iv_token_name3  => cv_tkn_sequence                          -- トークンコード3
                     ,iv_token_value3 => io_route_info_rec.no_seq                 -- シーケンス番号
                     ,iv_token_name4  => cv_tkn_cstm_cd                           -- トークンコード4
                     ,iv_token_value4 => io_route_info_rec.account_number         -- 顧客コード
                     ,iv_token_name5  => cv_tkn_cstm_nm                           -- トークンコード5
                     ,iv_token_value5 => io_route_info_rec.account_name           -- 顧客名称
                     ,iv_token_name6  => cv_route_cd                              -- トークンコード6
                     ,iv_token_value6 => io_route_info_rec.route_no               -- ルートコード
                     ,iv_token_name7  => cv_tkn_ym                                -- トークンコード7
                     ,iv_token_value7 => io_route_info_rec.input_date_ymd         -- 入力日付
                    );
      lv_errbuf  := lv_errmsg||SQLERRM;  
      RAISE ins_upd_expt;
    END IF;
--
  EXCEPTION
    -- *** データ登録更新例外ハンドラ ***
    WHEN ins_upd_expt THEN  
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_route_info;
--
  /**********************************************************************************
   * Procedure Name   : del_wrk_tbl_data                                                                         
   * Description      : ルート情報ワークテーブルデータ削除 (A-7)
   ***********************************************************************************/
  PROCEDURE del_wrk_tbl_data(
    ov_errbuf               OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100)    := 'del_wrk_tbl_data';         -- プログラム名
    cv_table_name            CONSTANT VARCHAR2(100)    := 'ルート情報ワークテーブル'; -- ルート情報ワークテーブル名
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
    -- ***       ルート情報ワークテーブルデータ削除        ***
    -- ***************************************************
    BEGIN
      DELETE
      FROM  xxcso_in_route_no;
--
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04              -- メッセージコード データ削除エラー
                       ,iv_token_name1  => cv_tkn_tbl                    -- トークンコード1
                       ,iv_token_value1 => cv_table_name                 -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_errmsg                 -- トークンコード2
                       ,iv_token_value2 => SQLERRM                       -- ORACLEエラー
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
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END del_wrk_tbl_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- エラー・メッセージ             --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- リターン・コード               --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ   --# 固定 #
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
--
    -- *** ローカル変数 ***
    ln_sales_plan_cnt      NUMBER;                     -- 日別売上計画連携チェック用のデータ件数
    lb_not_exists_new_data BOOLEAN;                    -- 最新レコード存在チェックフラグ
    lv_msg_code            VARCHAR2(100);              -- メッセージコード
    lv_err_rec_info        VARCHAR2(5000);             -- エラーデータ格納用
    lt_visit_target_div    xxcso_cust_accounts_v.vist_target_div%TYPE;    -- 訪問対象区分
--
    -- *** ローカル・カーソル ***
    CURSOR xirn_data_cur
    IS
      SELECT  xirn.no_seq  no_seq,                                    -- シーケンス番号
              xirn.record_number record_number,                       -- レコード番号
              xirn.account_number account_number,                     -- 顧客コード
              xirn.route_no route_no,                                 -- ルートコード
              xirn.input_date input_date,                             -- 入力日付
              xirn.coalition_trance_date coalition_trance_date        -- 連携処理日
      FROM   xxcso_in_route_no  xirn                                  -- ルート情報ワークテーブル
      ORDER BY xirn.no_seq;
--
    -- *** ローカル・レコード ***
    l_xirn_data_rec      xirn_data_cur%ROWTYPE;
    l_get_data_rec       g_get_route_info_rtype;
--
    -- *** ローカル例外 ***
    skip_data_expt             EXCEPTION;  -- 正常処理でスキップ処理される例外（最新レコードチェックなど）
    error_skip_data_expt       EXCEPTION;  -- マスタ存在チェックエラーなどで発生した例外
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
    gn_skip_cnt   := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
      ov_errbuf  => lv_errbuf,          -- エラー・メッセージ            --# 固定 #
      ov_retcode => lv_retcode,         -- リターン・コード              --# 固定 #
      ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- A-2.売上計画情報抽出 
    -- ====================================
    -- カーソルオープン
    OPEN xirn_data_cur;
--
    <<get_data_loop>>
    LOOP
--
      BEGIN
        FETCH xirn_data_cur INTO l_xirn_data_rec;
        -- 処理対象件数格納
        gn_target_cnt := xirn_data_cur%ROWCOUNT;
--
        EXIT WHEN xirn_data_cur%NOTFOUND
        OR  xirn_data_cur%ROWCOUNT = 0;
--
        -- レコード変数初期化
        l_get_data_rec := NULL;
--
        l_get_data_rec.no_seq                  := l_xirn_data_rec.no_seq;                -- シーケンス番号
        l_get_data_rec.record_number           := l_xirn_data_rec.record_number;         -- レコード番号
        l_get_data_rec.account_number          := l_xirn_data_rec.account_number;        -- 顧客コード
        l_get_data_rec.route_no                := l_xirn_data_rec.route_no;              -- ルートNO
        l_get_data_rec.input_date              := l_xirn_data_rec.input_date;            -- 入力日付（DATE型）
        l_get_data_rec.coalition_trance_date   := l_xirn_data_rec.coalition_trance_date; -- 連携処理日（DATE型）
        -- 入力日付のVARCHAR2型で変換
        l_get_data_rec.input_date_ymd          := TO_CHAR(l_get_data_rec.input_date,'YYYYMMDD');
--      
        -- INPUTデータの項目をカンマ区切りで文字連結してログに出力する用
        lv_err_rec_info := l_get_data_rec.no_seq||','
                        || l_get_data_rec.record_number  || ','
                        || l_get_data_rec.account_number || ','
                        || l_get_data_rec.route_no       || ','
                        || l_get_data_rec.input_date_ymd || ' ';
--
        -- ========================================
        -- A-3.マスタ存在チェック 
        -- ========================================
        chk_mst_is_exists(
          io_route_info_rec        => l_get_data_rec,  -- ルート情報ワークテーブルデータ
          ov_errbuf                => lv_errbuf,       -- エラー・メッセージ            --# 固定 #
          ov_retcode               => lv_retcode,      -- リターン・コード              --# 固定 #
          ov_errmsg                => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        -- マスタ存在チェックでエラーが発生する場合、中断、警告の場合はスキップ処理
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
--
        -- ========================================
        -- A-4.最新レコードチェック
        -- ========================================
        chk_is_new_recode(
          io_route_info_rec         => l_get_data_rec,              -- ルート情報ワークテーブルデータ
          ob_not_exists_new_data    => lb_not_exists_new_data,      -- 最新レコード存在チェックフラグ
          ov_errbuf                 => lv_errbuf,      -- エラー・メッセージ             --# 固定 #
          ov_retcode                => lv_retcode,     -- リターン・コード               --# 固定 #
          ov_errmsg                 => lv_errmsg       -- ユーザー・エラー・メッセージ   --# 固定 #
        );
        -- エラーが発生する場合は中断、警告の場合はスキップ処理、最新レコードが存在する場合は正常スキップ
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        ELSIF (lb_not_exists_new_data = cb_false) THEN
          RAISE skip_data_expt;
        END IF;
--
        -- 最新レコードが存在しない（当該レコードよりシーケンス番号が大きいレコードがない）場合
        -- ========================================
        -- A-5.ルート情報テーブルデータ登録及び更新 
        -- ========================================  
        upd_route_info(
          io_route_info_rec        => l_get_data_rec, -- ルート情報ワークテーブルデータ
          ov_errbuf                => lv_errbuf,      -- エラー・メッセージ            --# 固定 #
          ov_retcode               => lv_retcode,     -- リターン・コード              --# 固定 #
          ov_errmsg                => lv_errmsg       -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        -- ルート情報データ登録＆更新でエラーが発生する場合は中断、警告の場合スキップ
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
--
        -- ========================
        -- A-6.セーブポイント設定
        -- ========================
        SAVEPOINT a;
--
        -- 正常件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
          -- データ処理対象外にてスキップ
          WHEN skip_data_expt THEN
            -- スキップ件数カウント
            gn_skip_cnt := gn_skip_cnt + 1;
            -- スキップデータログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_debug_msg3 || lv_err_rec_info || CHR(10) ||
                         ''
            );
          -- データチェック、登録エラーにてスキップ
          WHEN error_skip_data_expt THEN
            -- エラー件数カウント
            gn_error_cnt := gn_error_cnt + 1;
            -- エラー出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
            );
            -- エラーログ（データ情報＋エラーメッセージ）
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_err_rec_info || lv_errbuf || CHR(10) ||
                         ''
            );
          -- ロールバック
          IF (gn_normal_cnt = 0) THEN
            ROLLBACK;
          ELSE
            ROLLBACK TO SAVEPOINT a;
          END IF;
          -- 全体の処理ステータスに警告セット
          ov_retcode := cv_status_warn;
      END;
    END LOOP get_data_loop;
    -- カーソルクローズ
    CLOSE xirn_data_cur;
--
    -- ========================================
    -- A-7.ルート情報ワークテーブルデータ削除処理
    -- ========================================
    del_wrk_tbl_data(
      ov_errbuf           => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode          => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
-- 
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- エラー件数カウント
      -- カーソルがクローズされていない場合
      IF xirn_data_cur%ISOPEN THEN
        -- カーソルクローズ
        CLOSE xirn_data_cur;
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
      gn_error_cnt := gn_error_cnt + 1;                           -- エラー件数カウント
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- エラー件数カウント
      -- カーソルがクローズされていない場合
      IF xirn_data_cur%ISOPEN THEN
        -- カーソルクローズ
        CLOSE xirn_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- エラー件数カウント
      -- カーソルがクローズされていない場合
      IF xirn_data_cur%ISOPEN THEN
        -- カーソルクローズ
        CLOSE xirn_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
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
    errbuf        OUT NOCOPY VARCHAR2,    --   エラー・メッセージ  --# 固定 #
    retcode       OUT NOCOPY VARCHAR2     --   リターン・コード    --# 固定 #
  )
  IS
--
--###########################  固定部 START   ###########################
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
    lv_message_code  VARCHAR2(100);  -- 終了メッセージ名格納
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
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
      ov_errbuf   => lv_errbuf,           -- エラー・メッセージ            --# 固定 #
      ov_retcode  => lv_retcode,          -- リターン・コード              --# 固定 #
      ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ  --# 固定 #
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
    -- A-9.終了処理
    -- ===============
    -- 空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_success_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_skip_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_error_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
--
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;      
    ELSIF (lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => lv_message_code
                   );
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
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
END XXCSO014A04C;
/
