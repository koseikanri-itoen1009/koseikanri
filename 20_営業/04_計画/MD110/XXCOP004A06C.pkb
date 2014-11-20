CREATE OR REPLACE PACKAGE BODY XXCOP004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A06C(body)
 * Description      : 引取計画(情報系IF)
 * MD.050           : 引取計画(情報系IF) MD050_COP_004_A06
 * Version          : ver1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理           (A-1)
 *  get_lastdate           前回起動日時取得   (A-2)
 *  open_utl_file          UTLファイルオープン(A-3)
 *  write_h_plan_csv       引取計画CSV作成    (A-5)
 *  update_lastdate        前回起動日時更新   (A-6)
 *  close_utl_file         UTLファイルクローズ(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/06    1.0   SCS.Uchida       新規作成
 *  2009/02/16    1.1   SCS.Fukada       結合障害012対応(A-1：ディレクトリ名取得処理変更)
 *  2009/02/20    1.2   SCS.Fukada       結合障害013対応(デバッグメッセージを削除)
 *
 *****************************************************************************************/
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  gn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  --システム設定
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'XXCOP004A06C';       -- パッケージ名
  gv_debug_mode              VARCHAR2(10)  := 'OFF';--NULL;                 -- デバッグモード：ON/OFF
  --メッセージ設定
  gv_xxcop          CONSTANT VARCHAR2(100) := 'XXCOP';              -- アプリケーション短縮名
  gv_m_e_get_who    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00001';   -- WHOカラム取得失敗
  gv_m_e_get_pro    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';   -- プロファイル値取得失敗
  gv_m_e_no_data    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';   -- 対象データなし
  gv_m_e_lock       CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00007';   -- テーブルロックエラーメッセージ
  gv_m_n_fname      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00033';   -- ファイル名出力メッセージ
  gv_m_e_fopen      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00034';   -- ファイルオープン処理失敗
  gv_m_e_public     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00035';   -- 標準API/Oracleエラーメッセージ
  gv_m_e_get_item   CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00048';   -- 項目取得失敗メッセージ
  gv_m_e_fwrite     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10013';   -- ファイル書込み処理失敗
  gv_m_e_fopen_p    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10014';   -- ファイルオープン処理失敗／ファイルパス不正
  gv_m_e_fopen_n    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10015';   -- ファイルオープン処理失敗／ファイル名不正
  gv_m_e_perm_acc   CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10016';   -- ファイルアクセス権限エラー
  gv_m_e_update     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10017';   -- 前回起動日時更新エラー
  --トークン設定
  gv_t_prof_name    CONSTANT VARCHAR2(100) := 'PROF_NAME'       ;   -- APP-XXCOP1-00002
  gv_t_value        CONSTANT VARCHAR2(100) := 'VALUE'           ;   -- APP-XXCOP1-00005
  gv_t_table        CONSTANT VARCHAR2(100) := 'TABLE'           ;   -- APP-XXCOP1-00007
  gv_t_file_name    CONSTANT VARCHAR2(100) := 'FILE_NAME'       ;   -- APP-XXCOP1-00033
  gv_t_data         CONSTANT VARCHAR2(100) := 'DATA'            ;   -- APP-XXCOP1-10013
  gv_t_item_name    CONSTANT VARCHAR2(100) := 'ITEM_NAME'       ;
  --プロファイル名
  gv_p_if_dir       CONSTANT VARCHAR2(100) := 'XXCOP1_IF_DIRECTORY' ;  -- 情報系連携ディレクトリパス
  gv_p_file_hiki    CONSTANT VARCHAR2(100) := 'XXCOP1_FILE_HIKITORI';  -- 引取計画ファイル名
  gv_p_com_cd       CONSTANT VARCHAR2(100) := 'XXCOP1_COMPANY_CODE' ;  -- 会社コード
  --UTL_FILEオプション
  gv_utl_open_modew CONSTANT VARCHAR2(100)  := 'w'              ;   -- オープンモード [書き込みモード]
  gv_utl_max_size   CONSTANT BINARY_INTEGER := 32767            ;   -- 最大レコード数 [max_linesize]
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    od_conv_date               OUT DATE,       --   連携日時
    ov_inf_conv_dir_path       OUT VARCHAR2,   --   情報系連携ディレクトリパス
    ov_h_plan_file_name        OUT VARCHAR2,   --   引取計画ファイル名
    ov_company_cd              OUT VARCHAR2,   --   会社コード
    ov_errbuf                  OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_dir_path  VARCHAR2(5000); -- 情報系連携ディレクトリパス[プロファイル値]
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --1.連携日時取得
    od_conv_date := SYSDATE;
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★連携日時 ： ' || TO_CHAR(od_conv_date),gv_debug_mode);
    --
--
    --2.whoカラム情報取得
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★CREATED_BY ： ' || TO_CHAR(gn_created_by),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('★CREATION_DATE ： ' || TO_CHAR(gd_creation_date),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('★LAST_UPDATED_BY ： ' || TO_CHAR(gn_last_updated_by),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('★LAST_UPDATE_DATE ： ' || TO_CHAR(gd_last_update_date),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('★LAST_UPDATE_LOGIN ： ' || TO_CHAR(gn_last_update_login),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('★REQUEST_ID ： ' || TO_CHAR(gn_request_id),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('★PROGRAM_APPLICATION_ID ： ' || TO_CHAR(gn_program_application_id),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('★PROGRAM_ID ： ' || TO_CHAR(gn_program_id),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('★PROGRAM_UPDATE_DATE ： ' || TO_CHAR(gd_program_update_date),gv_debug_mode);
    --
    IF ( gn_created_by              IS NULL
      OR gd_creation_date           IS NULL
      OR gn_last_updated_by         IS NULL
      OR gd_last_update_date        IS NULL
      OR gn_last_update_login       IS NULL
      OR gn_request_id              IS NULL
      OR gn_program_application_id  IS NULL
      OR gn_program_id              IS NULL
      OR gd_program_update_date     IS NULL
    )THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_who
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--==1.1 Modify Start ===========================================================================
    --3.情報系連携ディレクトリパス取得
    --3-1.ディレクトリ名の取得
   ov_inf_conv_dir_path := FND_PROFILE.VALUE(gv_p_if_dir);
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★Dir_Object： ' || ov_inf_conv_dir_path,gv_debug_mode);
    --
    IF ( ov_inf_conv_dir_path IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_pro
                     ,iv_token_name1  => gv_t_prof_name
                     ,iv_token_value1 => '情報系連携ディレクトリパス'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    --3-2.ディレクトリ・オブジェクト存在確認
    BEGIN
      SELECT directory_path                              -- ディレクトリ・オブジェクト名
      INTO   lv_dir_path                                 -- 情報系連携ディレクトリパス[引数]
      FROM   all_directories                             -- ディレクトリオブジェクトテーブル
      WHERE  directory_name = ov_inf_conv_dir_path       -- ディレクトリパス比較
      ;
      --★デバッグログ（開発用）
      xxcop_common_pkg.put_debug_message('★Dir_Path ： ' || lv_dir_path,gv_debug_mode);
      --
    EXCEPTION
      WHEN TOO_MANY_ROWS OR NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_get_pro
                       ,iv_token_name1  => gv_t_prof_name
                       ,iv_token_value1 => '情報系連携ディレクトリパス'
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END;

--
--    --3.情報系連携ディレクトリパス取得
--    --3-1.絶対パスの取得（プロファイル）
--    lv_dir_path := FND_PROFILE.VALUE(gv_p_if_dir);
--    --★デバッグログ（開発用）
--    xxcop_common_pkg.put_debug_message('★Dir_Path ： ' || lv_dir_path,gv_debug_mode);
--    --
--    IF ( lv_dir_path IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => gv_xxcop
--                     ,iv_name         => gv_m_e_get_pro
--                     ,iv_token_name1  => gv_t_prof_name
--                     ,iv_token_value1 => '情報系連携ディレクトリパス'
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_process_expt;
--    END IF;
--    --
--    --3-2.ディレクトリ・オブジェクト名の取得（テーブル）
--    BEGIN
--      SELECT directory_name                              -- ディレクトリ・オブジェクト名
--      INTO   ov_inf_conv_dir_path                        -- 情報系連携ディレクトリパス[引数]
--      FROM   all_directories                             -- ディレクトリオブジェクトテーブル
--      WHERE  directory_path = lv_dir_path                -- ディレクトリパス比較
--      ;
--      --★デバッグログ（開発用）
--      xxcop_common_pkg.put_debug_message('★Dir_Object ： ' || ov_inf_conv_dir_path,gv_debug_mode);
--      --
--    EXCEPTION
--      WHEN TOO_MANY_ROWS OR NO_DATA_FOUND THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => gv_xxcop
--                       ,iv_name         => gv_m_e_get_pro
--                       ,iv_token_name1  => gv_t_prof_name
--                       ,iv_token_value1 => '情報系連携ディレクトリパス'
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--      END;
--==1.1 Modify End =============================================================================
--
    --4.引取計画ファイル名取得        [プロファイル情報]
    ov_h_plan_file_name := FND_PROFILE.VALUE(gv_p_file_hiki);
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★引取計画ファイル名 ： ' || ov_h_plan_file_name,gv_debug_mode);
    --
    IF ( ov_h_plan_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_pro
                     ,iv_token_name1  => gv_t_prof_name
                     ,iv_token_value1 => '引取計画ファイル名'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --5.会社コード取得               [プロファイル情報]
    ov_company_cd := FND_PROFILE.VALUE(gv_p_com_cd);
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★会社コード ： ' || ov_company_cd,gv_debug_mode);
    --
    IF ( ov_company_cd IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_pro
                     ,iv_token_name1  => gv_t_prof_name
                     ,iv_token_value1 => '会社コード'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : get_lastdate
   * Description      : 前回起動日時取得(A-2)
   ***********************************************************************************/
--
  PROCEDURE get_lastdate(
    od_last_if_date   OUT DATE,         --   前回起動日時
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lastdate'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --1.前回起動日時取得
    SELECT last_process_date               -- 最終連携日時
    INTO   od_last_if_date                 -- 前回起動日時 [引数]
    FROM   xxcop_appl_controls             -- 計画用コントロールテーブル
    WHERE  function_id = gv_pkg_name       -- プログラム名比較
    ;
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★前回起動日時 ： ' || TO_CHAR(od_last_if_date),gv_debug_mode);
    --
    IF ( od_last_if_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_item
                     ,iv_token_name1  => gv_t_item_name
                     ,iv_token_value1 => '前回起動日時'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- 複数件取得又は0件取得の場合 （記述ルールより）
    WHEN TOO_MANY_ROWS OR NO_DATA_FOUND THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END get_lastdate;
--
--
  /**********************************************************************************
   * Procedure Name   : open_utl_file
   * Description      : UTLファイルオープン(A-3)
   ***********************************************************************************/
--
  PROCEDURE open_utl_file(
    iv_inf_conv_dir_path  IN  VARCHAR2,            --  情報系連携ディレクトリパス
    iv_h_plan_file_name   IN  VARCHAR2,            --  引取計画ファイル名
    ot_file_handle        OUT UTL_FILE.FILE_TYPE,  --  ファイルハンドル
    ov_errbuf             OUT VARCHAR2,            --  エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,            --  リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)            --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_utl_file'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      --1.ファイルオープン
      ot_file_handle := UTL_FILE.FOPEN(
                           iv_inf_conv_dir_path  --  情報系連携ディレクトリパス
                          ,iv_h_plan_file_name   --  引取計画ファイル名
                          ,gv_utl_open_modew     --  オープンモード [書き込みモード]
                          ,gv_utl_max_size       --  最大レコード数 [max_linesize]
                        );
    --
    --[UTL_FILE.FOPEN]の例外
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN         -- ファイルパス不正エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_fopen_p
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN UTL_FILE.INVALID_FILENAME THEN     -- ファイル名不正エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_fopen_n
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN UTL_FILE.ACCESS_DENIED THEN        -- ファイルアクセス権限エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_perm_acc
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN                        -- その他オープン時エラー全般
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_fopen
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END open_utl_file;
--
  /**********************************************************************************
   * Procedure Name   :
   * Description      : 引取計画情報抽出(A-4)
   ***********************************************************************************/
   --以下の処理はカーソルオープンのみである為、submainで実施
   --1.引取計画情報抽出
   --2.ケース数算出
--
  /**********************************************************************************
   * Procedure Name   : write_h_plan_csv
   * Description      : 引取計画CSV作成(A-5)
   ***********************************************************************************/
--
  PROCEDURE write_h_plan_csv(
    it_file_handle     IN  UTL_FILE.FILE_TYPE,  --  ファイルハンドル
    iv_output_csv_buf  IN  VARCHAR2,            --  出力文字列
    ov_errbuf          OUT VARCHAR2,            --  エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,            --  リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)            --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_utl_file'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      --1.引取計画CSV作成
      UTL_FILE.PUT_LINE(
         it_file_handle     --  ファイルハンドル
        ,iv_output_csv_buf  --  出力文字列
      );
    --
    --[UTL_FILE.PUT_LINE]の例外
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_fwrite
                       ,iv_token_name1  => gv_t_data
                       ,iv_token_value1 => iv_output_csv_buf
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END write_h_plan_csv;
--
  /**********************************************************************************
   * Procedure Name   : update_lastdate
   * Description      : 前回起動日時更新(A-6)
   ***********************************************************************************/
--
  PROCEDURE update_lastdate(
    id_conv_date    IN  DATE,       --   連携日時
    ov_errbuf       OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_lastdate'; -- プログラム名
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
    -- *** ローカル変数 ***
    ld_last_if_date      xxcop_appl_controls.last_process_date%TYPE;
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
    resource_busy_expt   EXCEPTION;     -- デッドロックエラー
--
    PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --1.テーブルロック
    BEGIN
      SELECT last_process_date                      -- 最終連携日時
      INTO   ld_last_if_date
      FROM   xxcop_appl_controls                    -- 計画用コントロールテーブル
      WHERE  function_id = gv_pkg_name              -- プログラム名比較
      FOR UPDATE OF last_process_date NOWAIT
      ;
    EXCEPTION
      WHEN resource_busy_expt                  -- リソースビジー（ロック中）
        OR NO_DATA_FOUND                       -- 対象データ無し
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_lock
                       ,iv_token_name1  => gv_t_table
                       ,iv_token_value1 => '計画用コントロールテーブル'
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --2.前回起動日時更新
    UPDATE xxcop_appl_controls                                 -- 計画用コントロールテーブル
    SET    last_process_date      = id_conv_date               -- 最終連携日時
           --以下WHOカラム
          ,last_updated_by        = gn_last_updated_by         -- LAST_UPDATED_BY
          ,last_update_date       = gd_last_update_date        -- LAST_UPDATE_DATE
          ,last_update_login      = gn_last_update_login       -- LAST_UPDATE_LOGIN
          ,request_id             = gn_request_id              -- REQUEST_ID
          ,program_application_id = gn_program_application_id  -- PROGRAM_APPLICATION_ID
          ,program_id             = gn_program_id              -- PROGRAM_ID
          ,program_update_date    = gd_program_update_date     -- PROGRAM_UPDATE_DATE
    WHERE  function_id = gv_pkg_name                           -- プログラム名比較
    ;
    --更新エラー
    IF ( SQL%ROWCOUNT != 1 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_update
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END update_lastdate;
--
  /**********************************************************************************
   * Procedure Name   : close_utl_file
   * Description      : UTLファイルクローズ(A-7)
   ***********************************************************************************/
--
  PROCEDURE close_utl_file(
    iot_file_handle  IN OUT UTL_FILE.FILE_TYPE,  --  ファイルハンドル
    ov_errbuf        OUT    VARCHAR2,            --  エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,            --  リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2)            --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_utl_file'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
      UTL_FILE.FCLOSE( iot_file_handle );
    --
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END close_utl_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
--
  PROCEDURE submain(
    ov_h_plan_file_name  OUT VARCHAR2,     --   引取計画ファイル名
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ld_conv_date               DATE;            -- 連携日時
    lv_inf_conv_dir_path       VARCHAR2(5000);  -- 情報系連携ディレクトリパス
    lv_h_plan_file_name        VARCHAR2(1000);  -- 引取計画ファイル名
    lv_company_cd              VARCHAR2(10);    -- 会社コード
    ld_last_if_date            DATE;            -- 前回起動日時
    ln_case_quantity           NUMBER;          -- ケース数量
--
    lf_file_hand               UTL_FILE.FILE_TYPE;
    lv_output_csv_buf          VARCHAR2(100);   -- CSVファイル書き込み用レコードバッファ
--
    -- *** ローカルRECORD型 ***
    CURSOR l_h_plan_info_cur
    IS
      SELECT lv_company_cd                    c_cd                                      -- 会社コード [ローカル変数]
            ,TO_CHAR(mfda.forecast_date,'YYYYMM')  fsda                                 -- フォーキャスト開始日
            ,mfda.attribute5                  b_cd                                      -- 拠点コード(DFF5)
            ,iimb.item_no                     i_no                                      -- 品目（商品コード）
            ,SUM(mfda.original_forecast_quantity)  fo_q                                 -- 数量
            ,ld_conv_date                     coda                                      -- 連携日時 [ローカル変数]
      FROM   mrp_forecast_dates               mfda                                      -- フォーキャスト日付
            ,mrp_forecast_designators         mfde                                      -- フォーキャスト名
            ,ic_item_mst_b                    iimb                                      -- OPM品目マスタ
            ,xxcop_item_categories1_v         xicv                                      -- 【共通view】計画_品目カテゴリビュー1
      WHERE  mfda.forecast_designator  =  mfde.forecast_designator                      --フォーキャスト名比較
      AND    mfda.organization_id      =  mfde.organization_id                          --在庫組織ID比較
      AND    mfde.attribute1           =  '01'                                          --フォーキャスト分類(1引取計画)
      AND    mfda.inventory_item_id    =  xicv.inventory_item_id                        --品目ID比較1(INV品目ID)
      AND    xicv.item_id              =  iimb.item_id                                  --品目ID比較2(OPM品目ID)
      AND    TO_CHAR(mfda.forecast_date,'YYYYMM') >= TO_CHAR(ld_last_if_date,'YYYYMM')  --当月以降のデータ
      GROUP BY TO_CHAR(mfda.forecast_date,'YYYYMM')
              ,mfda.attribute5
              ,iimb.item_no
    ;
--
    -- *** ローカル・レコード ***
    l_h_plan_info_rec l_h_plan_info_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
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
    --*********************************************
    --*** 処理名：初期処理                        ***
    --*** 処理NO：A-1                            ***
    --*********************************************
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★[A-1]Process Start',gv_debug_mode);
    --
    init(
       ld_conv_date                 --   連携日時
      ,lv_inf_conv_dir_path         --   情報系連携ディレクトリパス
      ,lv_h_plan_file_name          --   引取計画ファイル名
      ,lv_company_cd                --   会社コード
      ,lv_errbuf                    --   エラー・メッセージ          --# 固定 #
      ,lv_retcode                   --   リターン・コード            --# 固定 #
      ,lv_errmsg                    --   ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--      --デバッグログ
--      fnd_file.put_line(FND_FILE.LOG,'A-1:Process Error');
--==1.2 Delete End   ===========================================================================
      RAISE global_process_expt;
    END IF;
--==1.2 Delete Start ===========================================================================
--    --デバッグログ
--    fnd_file.put_line(FND_FILE.LOG,'A-1:Process Success');
--==1.2 Delete End   ===========================================================================
--
    --*********************************************
    --*** 処理名：前回起動日時取得                 ***
    --*** 処理NO：A-2                            ***
    --*********************************************
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★[A-2]Process Start',gv_debug_mode);
    --
    get_lastdate(
       ld_last_if_date              --   前回起動日時
      ,lv_errbuf                    --   エラー・メッセージ           --# 固定 #
      ,lv_retcode                   --   リターン・コード             --# 固定 #
      ,lv_errmsg                    --   ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--      --デバッグログ
--      fnd_file.put_line(FND_FILE.LOG,'A-2:Process Error');
--==1.2 Delete End   ===========================================================================
      RAISE global_process_expt;
    END IF;
--==1.2 Delete Start ===========================================================================
--    --デバッグログ
--    fnd_file.put_line(FND_FILE.LOG,'A-2:Process Success');
--==1.2 Delete End   ===========================================================================
--
    --*********************************************
    --*** 処理名：UTLファイルオープン              ***
    --*** 処理NO：A-3                            ***
    --*********************************************
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★[A-3]Process Start',gv_debug_mode);
    --
    open_utl_file(
      lv_inf_conv_dir_path  --   情報系連携ディレクトリパス
     ,lv_h_plan_file_name   --   引取計画ファイル名
     ,lf_file_hand          --   ファイルハンドル
     ,lv_errbuf             --   エラー・メッセージ           --# 固定 #
     ,lv_retcode            --   リターン・コード             --# 固定 #
     ,lv_errmsg             --   ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--      --デバッグログ
--      fnd_file.put_line(FND_FILE.LOG,'A-3:Process Error');
--==1.2 Delete End   ===========================================================================
      RAISE global_process_expt;
    END IF;
--==1.2 Delete Start ===========================================================================
--    --デバッグログ
--    fnd_file.put_line(FND_FILE.LOG,'A-3:Process Success');
--==1.2 Delete End   ===========================================================================
--
    --*********************************************
    --*** 処理名：引取計画情報抽出                 ***
    --*** 処理NO：A-4                            ***
    --*********************************************
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★[A-4]Process Start',gv_debug_mode);
    --
    --カーソルオープン
    OPEN l_h_plan_info_cur;
--==1.2 Delete Start ===========================================================================
--    --デバッグログ
--    fnd_file.put_line(FND_FILE.LOG,'A-4:Process Success');
--==1.2 Delete End   ===========================================================================
--
    --*********************************************
    --*** 処理名：引取計画CSV作成                  ***
    --*** 処理NO：A-5                            ***
    --*********************************************
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★[A-5]Process Start',gv_debug_mode);
    --
    <<row_loop>>
    LOOP
      FETCH l_h_plan_info_cur INTO l_h_plan_info_rec ;
      EXIT WHEN l_h_plan_info_cur%NOTFOUND;
      --
      --[共通関数]ケース数換算関数の呼び出し（ケース数計算）
      xxcop_common_pkg.get_case_quantity(
        iv_item_no               => l_h_plan_info_rec.i_no  -- 品目コード
       ,in_individual_quantity   => l_h_plan_info_rec.fo_q  -- バラ数量
       ,in_trunc_digits          => 0                       -- 切捨て桁数
       ,on_case_quantity         => ln_case_quantity        -- ケース数量
       ,ov_retcode               => lv_retcode              -- リターンコード
       ,ov_errbuf                => lv_errbuf               -- エラー・メッセージ
       ,ov_errmsg                => lv_errmsg               -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--        --デバッグログ
--        fnd_file.put_line(FND_FILE.LOG,'A-5:Process Error');
--==1.2 Delete End   ===========================================================================
        RAISE global_api_others_expt;
      END IF;
      --
      --ファイル書込みデータ作成
      lv_output_csv_buf := '"' || l_h_plan_info_rec.c_cd || '"'                -- 会社コード
                 || ',' || l_h_plan_info_rec.fsda                              -- 年月
                 || ',' || '"' || l_h_plan_info_rec.b_cd || '"'                -- 拠点（部門）コード
                 || ',' || '"' || l_h_plan_info_rec.i_no || '"'                -- 商品コード
                 || ',' || ln_case_quantity                                    -- ケース数
                 || ',' || TO_CHAR(l_h_plan_info_rec.coda,'YYYYMMDDHH24MISS'); -- 連携日時
      --
      write_h_plan_csv(
         lf_file_hand       --  ファイルハンドル
        ,lv_output_csv_buf  --  出力文字列
        ,lv_errbuf          --  エラー・メッセージ           --# 固定 #
        ,lv_retcode         --  リターン・コード             --# 固定 #
        ,lv_errmsg          --  ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = gv_status_error ) THEN
        gn_target_cnt := l_h_plan_info_cur%ROWCOUNT;
        gn_normal_cnt := gn_target_cnt - 1;
        gn_error_cnt  := 1;
        --デバッグログ
        fnd_file.put_line(FND_FILE.LOG,'A-5:Process Error');
        fnd_file.put_line(FND_FILE.LOG,'Record_NO:'||l_h_plan_info_cur%ROWCOUNT);
        fnd_file.put_line(FND_FILE.LOG,'Record_INFO:'||lv_output_csv_buf);
        RAISE global_process_expt;
      END IF;
      --★デバッグログ（開発用）
      xxcop_common_pkg.put_debug_message('★' || to_char(l_h_plan_info_cur%ROWCOUNT,'00000') || ':' || lv_output_csv_buf,gv_debug_mode);
      --
    END LOOP row_loop;
    --
    --処理件数集計
    gn_target_cnt := l_h_plan_info_cur%ROWCOUNT;
    gn_normal_cnt := gn_target_cnt;
    --
    CLOSE l_h_plan_info_cur;
    --
    --0件処理判定
    IF ( gn_target_cnt = 0 ) THEN
--==1.2 Delete Start ===========================================================================
--      --デバッグログ
--      fnd_file.put_line(FND_FILE.LOG,'A-5:Process Success(0件)');
--==1.2 Delete End   ===========================================================================
      --
      --メッセージ取得
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_no_data
                   );
    ELSE
--==1.2 Delete Start ===========================================================================
--      --デバッグログ
--      fnd_file.put_line(FND_FILE.LOG,'A-5:Process Success');
--==1.2 Delete End   ===========================================================================
      --
      --*********************************************
      --*** 処理名：前回起動日時更新                 ***
      --*** 処理NO：A-6                            ***
      --*********************************************
      --★デバッグログ（開発用）
      xxcop_common_pkg.put_debug_message('★[A-6]Process Start',gv_debug_mode);
      --
      update_lastdate(
         ld_conv_date                 --   連携日時
        ,lv_errbuf                    --   エラー・メッセージ           --# 固定 #
        ,lv_retcode                   --   リターン・コード             --# 固定 #
        ,lv_errmsg                    --   ユーザー・エラー・メッセージ --# 固定 #
        );
      --
      IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--        --デバッグログ
--        fnd_file.put_line(FND_FILE.LOG,'A-6:Process Error');
--==1.2 Delete End   ===========================================================================
        RAISE global_process_expt;
      END IF;
--==1.2 Delete Start ===========================================================================
--      --デバッグログ
--      fnd_file.put_line(FND_FILE.LOG,'A-6:Process Success');
--==1.2 Delete End   ===========================================================================
    END IF;
--
    --*********************************************
    --*** 処理名：UTLファイルクローズ              ***
    --*** 処理NO：A-7                            ***
    --*********************************************
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★[A-7]Process Start',gv_debug_mode);
    --
    close_utl_file(
       lf_file_hand    --  ファイルハンドル
      ,lv_errbuf       --  エラー・メッセージ           --# 固定 #
      ,lv_retcode      --  リターン・コード             --# 固定 #
      ,lv_errmsg       --  ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--      --デバッグログ
--      fnd_file.put_line(FND_FILE.LOG,'A-7:Process Error');
--==1.2 Delete End   ===========================================================================
      RAISE global_process_expt;
    END IF;
--==1.2 Delete Start ===========================================================================
--    --デバッグログ
--    fnd_file.put_line(FND_FILE.LOG,'A-7:Process Success');
--==1.2 Delete End   ===========================================================================
--
    --取得したファイル名をmainに返す
    ov_h_plan_file_name := lv_h_plan_file_name;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- ファイルクローズ処理
      IF ( UTL_FILE.IS_OPEN(lf_file_hand) ) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- ファイルクローズ処理
      IF ( UTL_FILE.IS_OPEN(lf_file_hand) ) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルクローズ処理
      IF ( UTL_FILE.IS_OPEN(lf_file_hand) ) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  固定部 END   ##########################################
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
    errbuf             OUT VARCHAR2,        --   エラーメッセージ #固定#
    retcode            OUT VARCHAR2         --   エラーコード     #固定#
  )
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --ｴﾗｰ終了メッセージ（全件処理前戻し）
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code      VARCHAR2(100);
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_h_plan_file_name  VARCHAR2(1000);  -- 引取計画ファイル名
--
  BEGIN
--
  --[retcode]初期化（記述ルールより）
  retcode := gv_status_normal;
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
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    --行間
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- 入力パラメータ出力処理
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => 'APP-XXCCP1-90008'
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --行間
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_h_plan_file_name  -- 引取計画ファイル名
      ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,lv_retcode           -- リターン・コード             --# 固定 #
      ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --ステータスセット
    retcode := lv_retcode;
--
    -- ===============================
    -- 出力ファイル名・出力処理
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcop
                    ,iv_name         => gv_m_n_fname
                    ,iv_token_name1  => gv_t_file_name
                    ,iv_token_value1 => lv_h_plan_file_name
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --行間
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- エラーメッセージ出力処理
    -- ===============================
    IF ( retcode = gv_status_error ) AND ( lv_errmsg IS NULL ) THEN
      --定型メッセージ・セット
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_public
                   );
    END IF;
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg --ユーザー・エラーメッセージ
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --エラーメッセージ
    );
    --
    --行間
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- 対象件数出力処理
    -- ===============================
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
    -- ===============================
    -- 成功件数出力処理
    -- ===============================
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
    -- ===============================
    -- エラー件数出力処理
    -- ===============================
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
/*★★★★★★★★★★★★★★★★★★★★以下使用せず★★★★★★★★★★★★★★★★★★★★
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
★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★*/
    --
    --行間
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- 終了メッセージ出力
    -- ===============================
    IF ( retcode = gv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    --ELSIF( lv_retcode = gv_status_warn ) THEN
    --  lv_message_code := cv_warn_msg;
    ELSIF( retcode = gv_status_error ) THEN
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
    -- ===============================
    -- エラー処理（ROLLBACK）
    -- ===============================
    IF ( retcode = gv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
  END main;
--
END XXCOP004A06C;
/
