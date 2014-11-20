CREATE OR REPLACE PACKAGE BODY XXCFO011A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO011A01C
 * Description     : 人事システムデータ連携
 * MD.050          : MD050_CFO_011_A01_人事システムデータ連携
 * MD.070          : MD050_CFO_011_A01_人事システムデータ連携
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init              P        入力パラメータ値ログ出力処理                  (A-1)
 *  get_system_value  P        各種システム値取得処理                        (A-2)
 *  submit_request_sql_loader P 人事システムデータ連携(SQL*Loader)起動処理   (A-3)
 *  wait_request      P        人事システムデータ連携(SQL*Loader)監視処理    (A-4)
 *  error_request_sql_loader P  人事システムデータ連携(SQL*Loader)エラー処理 (A-5)
 *  insert_xx03_gl_interface P 外部公開GLアドオンOIF挿入処理                 (A-6)
 *  truncate_adps_gl_interface P 人事システム用GLアドオンOIF　TRUNCATE処理   (A-7)
 *  submit_request_err_check P BFA:GLI/Fエラーチェック起動処理               (A-8)
 *  wait_request      P        BFA:GLI/Fエラーチェック監視処理               (A-9)
 *  error_request_err_check P  BFA:GLI/Fエラーチェックエラー処理             (A-10)
 *  del_xx03_gl_interface P    外部公開GLアドオンOIF削除処理                 (A-10-1)
 *  submit_request_transfer P  BFA:GLI/F転送起動処理                         (A-11)
 *  wait_request      P        BFA:GLI/F転送監視処理                         (A-12)
 *  error_request_transfer P   BFA:GLI/F転送エラー処理                       (A-13)
 *  submit_request_import P    仕訳インポート起動処理                        (A-14)
 *  wait_request      P        仕訳インポート監視処理                        (A-15)
 *  error_request_import P     仕訳インポートエラー処理                      (A-16)
 *  submain           P        メイン処理プロシージャ
 *  main              P        コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-25    1.0  SCS 加藤 忠   初回作成
 ************************************************************************/
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
  -- ユーザー定義例外
  -- ===============================
--
  lock_expt                 EXCEPTION;      -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFO011A01C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';        -- アドオン：マスタ・経理・共通のアプリケーション短縮名
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';        -- アドオン：共通・IF領域のアプリケーション短縮名
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';        -- アドオン：会計・アドオン領域のアプリケーション短縮名
  cv_msg_kbn_03      CONSTANT VARCHAR2(5)   := 'XX03';         -- アドオン：BFAのアプリケーション短縮名
--
  -- メッセージ番号
  cv_msg_011a01_001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; --プロファイル取得エラーメッセージ
  cv_msg_011a01_002  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00021'; --コンカレント起動エラーメッセージ
  cv_msg_011a01_003  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00022'; --コンカレント監視エラーメッセージ
  cv_msg_011a01_004  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00023'; --監視プログラムエラー終了メッセージ
  cv_msg_011a01_005  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024'; --データ挿入エラーメッセージ
  cv_msg_011a01_006  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019'; --ロックエラーメッセージ
  cv_msg_011a01_007  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025'; --データ削除エラーメッセージ
  cv_msg_011a01_008  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00026'; --仕訳ソース取得エラーメッセージ
--
  -- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(20) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_program     CONSTANT VARCHAR2(20) := 'PROGRAM_NAME';     -- 実行コンカレントプログラム名
  cv_tkn_request     CONSTANT VARCHAR2(20) := 'REQUEST_ID';       -- 実行コンカレントプログラム要求ID
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';            -- テーブル名
  cv_tkn_errmsg      CONSTANT VARCHAR2(20) := 'ERRMSG';           -- ORACLEエラーの内容
  cv_tkn_je_source   CONSTANT VARCHAR2(20) := 'JE_SOURCE_NAME';   -- 仕訳インポート対象の仕訳ソースコード
--
  -- 日本語辞書
  cv_dict_sql_loader CONSTANT VARCHAR2(100) := 'CFO011A01001';    -- コンカレントプログラム名：人事システムデータ連携(SQL*Loader)
  cv_dict_err_check  CONSTANT VARCHAR2(100) := 'CFO011A01002';    -- コンカレントプログラム名：GLI/Fエラーチェック
  cv_dict_transfer   CONSTANT VARCHAR2(100) := 'CFO011A01003';    -- コンカレントプログラム名：GLI/F転送
  cv_dict_import     CONSTANT VARCHAR2(100) := 'CFO011A01004';    -- コンカレントプログラム名：GL仕訳インポートの起動
  cv_dict_tab_03glif CONSTANT VARCHAR2(100) := 'CFO011A01005';    -- 外部公開GLアドオンOIFテーブル名
--
  -- プロファイル
  cv_adps_interval   CONSTANT VARCHAR2(30) := 'XXCFO1_ADPS_INTERVAL';  -- XXCFO:人事システムデータ連携要求完了チェック待機秒数
  cv_adps_max_wait   CONSTANT VARCHAR2(30) := 'XXCFO1_ADPS_MAX_WAIT';  -- XXCFO:人事システムデータ連携要求完了待機最大秒数
  cv_adps_je_source  CONSTANT VARCHAR2(30) := 'XXCFO1_ADPS_JE_SOURCE'; -- XXCFO:人事システムデータ連携処理対象仕訳ソース
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';      -- 会計帳簿ID
--
  -- コンカレントプログラム短縮名
  cv_sql_loader_name CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFO011A11D';  -- 人事システムデータ連携(SQL*Loader)
  cv_err_check_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XX031EC001C';   -- GLI/Fエラーチェック
  cv_transfer_name   CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XX031GT001C';   -- GLI/F転送
  cv_import_name     CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XX031JI001C';   -- GL仕訳インポートの起動
  -- コンカレントパラメータ値'Y/N'
  cv_conc_param_y    CONSTANT VARCHAR2(1) := 'Y';
  cv_conc_param_n    CONSTANT VARCHAR2(1) := 'N';
  -- コンカレントパラメータ値'O'
  cv_conc_param_o    CONSTANT VARCHAR2(1) := 'O';
  -- コンカレントdevフェーズ
  cv_dev_phase_complete   CONSTANT VARCHAR2(30) := 'COMPLETE';    -- '完了'
  -- コンカレントdevステータス
  cv_dev_status_normal    CONSTANT VARCHAR2(30) := 'NORMAL';      -- '正常'
  cv_dev_status_warn      CONSTANT VARCHAR2(30) := 'WARNING';     -- '警告'
  cv_dev_status_err       CONSTANT VARCHAR2(30) := 'ERROR';       -- 'エラー';
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';      -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';         -- ログ出力
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_adps_interval        NUMBER;                                 -- XXCFO:人事システムデータ連携要求完了チェック待機秒数
  gn_adps_max_wait        NUMBER;                                 -- XXCFO:人事システムデータ連携要求完了待機最大秒数
  gv_adps_je_source       gl_je_sources.je_source_name%TYPE;      -- XXCFO:人事システムデータ連携処理対象仕訳ソース
  gv_user_je_source_name  gl_je_sources.user_je_source_name%TYPE; -- 処理対象仕訳ソース名
  gn_set_of_bks_id        NUMBER;                                 -- 会計帳簿ID
--
  -- FND_CONCURRENT.SUBMIT_REQUESTの戻り
  gn_submit_req_id        NUMBER;         -- 要求ID
  gn_submit_req_id_err_check  NUMBER;     -- 要求ID：GLI/Fエラーチェック
  -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り
  gb_wait_request         BOOLEAN;        -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値
  gv_wait_phase           VARCHAR2(100);  -- 要求フェーズ
  gv_wait_status          VARCHAR2(100);  -- 要求ステータス
  gv_wait_dev_phase       VARCHAR2(100);  -- 要求フェーズコード
  gv_wait_dev_status      VARCHAR2(100);  -- 要求ステータスコード
  gv_wait_message         VARCHAR2(5000); -- 完了メッセージ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_file_name IN  VARCHAR2,     --   連携ファイル名
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out     -- メッセージ出力
      ,iv_conc_param1  => iv_target_file_name  -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
     END IF; 
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log     -- ログ出力
      ,iv_conc_param1  => iv_target_file_name  -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_system_value
   * Description      : 各種システム値取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_system_value(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_system_value'; -- プログラム名
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
    -- プロファイルからXXCFO:人事システムデータ連携要求完了チェック待機秒数
    gn_adps_interval := FND_PROFILE.VALUE( cv_adps_interval );
    -- 取得エラー時
    IF ( gn_adps_interval IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_adps_interval ))
                                                                       -- XXCFO:人事システムデータ連携要求完了チェック待機秒数
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFO:人事システムデータ連携要求完了待機最大秒数
    gn_adps_max_wait := FND_PROFILE.VALUE( cv_adps_max_wait );
    -- 取得エラー時
    IF ( gn_adps_max_wait IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_adps_max_wait ))
                                                                       -- XXCFO:人事システムデータ連携要求完了待機最大秒数
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFO:人事システムデータ連携処理対象仕訳ソース
    gv_adps_je_source := FND_PROFILE.VALUE( cv_adps_je_source );
    -- 取得エラー時
    IF ( gv_adps_je_source IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_adps_je_source ))
                                                                       -- XXCFO:人事システムデータ連携処理対象仕訳ソース
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからGL会計帳簿ID取得
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- 取得エラー時
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id ))
                                                                       -- GL会計帳簿ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:人事システムデータ連携処理対象仕訳ソースの仕訳ソース名を取得する
    BEGIN
      SELECT gljs.user_je_source_name user_je_source_name
      INTO gv_user_je_source_name
      FROM gl_je_sources gljs
      WHERE gljs.je_source_name = gv_adps_je_source
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                      ,cv_msg_011a01_008  -- 仕訳ソース取得エラー
                                                      ,cv_tkn_je_source   -- トークン'JE_SOURCE_NAME'
                                                      ,gv_adps_je_source) -- 仕訳ソースコード
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END get_system_value;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_sql_loader
   * Description      : 人事システムデータ連携(SQL*Loader)起動処理(A-3)
   ***********************************************************************************/
  PROCEDURE submit_request_sql_loader(
    iv_target_file_name IN  VARCHAR2,     --   連携ファイル名
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_sql_loader'; -- プログラム名
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
    -- 人事システムデータ連携(SQL*Loader)コンカレント発行
    gn_submit_req_id := 
    FND_REQUEST.SUBMIT_REQUEST(application => cv_msg_kbn_cfo,          -- アプリケーション短縮名
                               program     => cv_sql_loader_name,      -- コンカレントプログラム短縮名
                               argument1   => iv_target_file_name      -- コンカレントパラメータ(ファイル名)
                              );
    -- コンカレント起動に失敗した場合メッセージを出力
    IF ( gn_submit_req_id = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_002 -- コンカレント起動エラー
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_sql_loader
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      COMMIT;
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
  END submit_request_sql_loader;
--
  /**********************************************************************************
   * Procedure Name   : wait_request
   * Description      : 人事システムデータ連携(SQL*Loader)監視処理(A-4)
   *                    BFA:GLI/Fエラーチェック監視処理(A-9)
   *                    BFA:GLI/F転送監視処理(A-12)
   *                    仕訳インポート監視処理(A-15)
   ***********************************************************************************/
  PROCEDURE wait_request(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wait_request'; -- プログラム名
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
    -- 人事システムデータ連携(SQL*Loader)コンカレント要求監視
    gb_wait_request := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => gn_submit_req_id,
                                                       interval   => gn_adps_interval,
                                                       max_wait   => gn_adps_max_wait,
                                                       phase      => gv_wait_phase,
                                                       status     => gv_wait_status,
                                                       dev_phase  => gv_wait_dev_phase,
                                                       dev_status => gv_wait_dev_status,
                                                       message    => gv_wait_message
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END wait_request;
--
  /**********************************************************************************
   * Procedure Name   : error_request_sql_loader
   * Description      : 人事システムデータ連携(SQL*Loader)エラー処理(A-5)
   ***********************************************************************************/
  PROCEDURE error_request_sql_loader(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_request_sql_loader'; -- プログラム名
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
    -- 人事システムデータ連携(SQL*Loader)監視処理がエラーの場合
    IF ( gb_wait_request = FALSE ) THEN
      -- 人事システム用GLアドオンOIFテーブルをTRUNCATEする
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcfo.xxcfo_adps_gl_interface';
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_003 -- コンカレント監視エラー
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_sql_loader
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF ( gv_wait_dev_phase = cv_dev_phase_complete )
      AND ( gv_wait_dev_status = cv_dev_status_normal ) THEN
      -- 正常終了の場合、処理続行する
      gn_normal_cnt := gn_normal_cnt + 1;
--
    ELSE
      -- 人事システム用GLアドオンOIFテーブルをTRUNCATEする
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcfo.xxcfo_adps_gl_interface';
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_004 -- 監視プログラムエラー終了
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_sql_loader
                                                     )
                                                    ,cv_tkn_request    -- トークン'REQUEST_ID'
                                                    ,gn_submit_req_id) -- 人事システムデータ連携(SQL*Loader)処理のREQUEST_ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
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
  END error_request_sql_loader;
--
  /**********************************************************************************
   * Procedure Name   : insert_xx03_gl_interface
   * Description      : 外部公開GLアドオンOIF挿入処理(A-6)
   ***********************************************************************************/
  PROCEDURE insert_xx03_gl_interface(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xx03_gl_interface'; -- プログラム名
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
    -- 外部公開GLアドオンOIFへのINSERT処理
    BEGIN
      INSERT INTO xx03_gl_interface (
        status,                                     -- ステータス
        set_of_books_id,                            -- 会計帳簿ID
        accounting_date,                            -- 仕訳計上日
        currency_code,                              -- 通貨コード
        date_created,                               -- 作成日
        created_by,                                 -- 作成者ユーザーID
        actual_flag,                                -- 実績フラグ
        user_je_category_name,                      -- 仕訳カテゴリ
        user_je_source_name,                        -- 仕訳ソース名
        currency_conversion_date,                   -- 通貨換算日
        encumbrance_type_id,                        -- 予算引当タイプID
        budget_version_id,                          -- 予算バージョンID
        user_currency_conversion_type,              -- 通貨換算タイプ
        currency_conversion_rate,                   -- 通貨換算レート
        average_journal_flag,                       -- 平均仕訳フラグ
        originating_bal_seg_value,                  -- バランスセグメント値
        segment1,                                   -- セグメント1（会社）
        segment2,                                   -- セグメント2（部門）
        segment3,                                   -- セグメント3（勘定科目）
        segment4,                                   -- セグメント4（補助科目）
        segment5,                                   -- セグメント5（顧客）
        segment6,                                   -- セグメント6（企業）
        segment7,                                   -- セグメント7(事業区分)
        segment8,                                   -- セグメント8(予備)
        segment9,                                   -- セグメント9
        segment10,                                  -- セグメント10
        segment11,                                  -- セグメント11
        segment12,                                  -- セグメント12
        segment13,                                  -- セグメント13
        segment14,                                  -- セグメント14
        segment15,                                  -- セグメント15
        segment16,                                  -- セグメント16
        segment17,                                  -- セグメント17
        segment18,                                  -- セグメント18
        segment19,                                  -- セグメント19
        segment20,                                  -- セグメント20
        segment21,                                  -- セグメント21
        segment22,                                  -- セグメント22
        segment23,                                  -- セグメント23
        segment24,                                  -- セグメント24
        segment25,                                  -- セグメント25
        segment26,                                  -- セグメント26
        segment27,                                  -- セグメント27
        segment28,                                  -- セグメント28
        segment29,                                  -- セグメント29
        segment30,                                  -- セグメント30
        entered_dr,                                 -- 借方金額
        entered_cr,                                 -- 貸方金額
        accounted_dr,                               -- 機能通貨借方金額
        accounted_cr,                               -- 機能通貨貸方金額
        transaction_date,                           -- トランザクション日
        reference1,                                 -- リファレンス１(バッチ名)
        reference2,                                 -- リファレンス２(バッチ摘要)
        reference3,                                 -- リファレンス３
        reference4,                                 -- リファレンス４(仕訳名)
        reference5,                                 -- リファレンス５(仕訳摘要)
        reference6,                                 -- リファレンス６(仕訳参照)
        reference7,                                 -- リファレンス７(逆仕訳フラグ)
        reference8,                                 -- リファレンス８
        reference9,                                 -- リファレンス９(逆仕訳期間)
        reference10,                                -- リファレンス１０(仕訳明細摘要)
        reference11,                                -- リファレンス１１
        reference12,                                -- リファレンス１２
        reference13,                                -- リファレンス１３
        reference14,                                -- リファレンス１４
        reference15,                                -- リファレンス１５
        reference16,                                -- リファレンス１６
        reference17,                                -- リファレンス１７
        reference18,                                -- リファレンス１８
        reference19,                                -- リファレンス１９
        reference20,                                -- リファレンス２０
        reference21,                                -- リファレンス２１
        reference22,                                -- リファレンス２２
        reference23,                                -- リファレンス２３
        reference24,                                -- リファレンス２４
        reference25,                                -- リファレンス２５
        reference26,                                -- リファレンス２６
        reference27,                                -- リファレンス２７
        reference28,                                -- リファレンス２８
        reference29,                                -- リファレンス２９
        reference30,                                -- リファレンス３０
        je_batch_id,                                -- 仕訳バッチID
        period_name,                                -- 会計期間
        je_header_id,                               -- 仕訳ヘッダID
        je_line_num,                                -- 明細番号
        chart_of_accounts_id,                       -- 勘定体系ID
        functional_currency_code,                   -- 機能通貨コード
        code_combination_id,                        -- CCID
        date_created_in_gl,                         -- GL作成日
        warning_code,                               -- 警告コード
        status_description,                         -- ステータス内容
        stat_amount,                                -- 統計数値
        group_id,                                   -- グループID
        request_id,                                 -- 要求ID
        subledger_doc_sequence_id,                  -- 副会計帳簿文書連番ID
        subledger_doc_sequence_value,               -- 副会計帳簿文書連番
        attribute1,                                 -- DFF1(税区分)
        attribute2,                                 -- DFF2(増減事由)
        gl_sl_link_id,                              -- GL_SLリンクID
        gl_sl_link_table,                           -- GL_SLリンクテーブル
        attribute3,                                 -- DFF3(伝票番号)
        attribute4,                                 -- DFF4(起票部門)
        attribute5,                                 -- DFF5(伝票入力者)
        attribute6,                                 -- DFF6(修正元伝票番号)
        attribute7,                                 -- DFF7(予備１)
        attribute8,                                 -- DFF8(予備２)
        attribute9,                                 -- DFF9(予備３)
        attribute10,                                -- DFF10(予備４)
        attribute11,                                -- DFF11
        attribute12,                                -- DFF12
        attribute13,                                -- DFF13
        attribute14,                                -- DFF14
        attribute15,                                -- DFF15
        attribute16,                                -- DFF16
        attribute17,                                -- DFF17
        attribute18,                                -- DFF18
        attribute19,                                -- DFF19
        attribute20,                                -- DFF20
        context,                                    -- コンテキスト
        context2,                                   -- コンテキスト２
        invoice_date,                               -- 請求書日
        tax_code,                                   -- 税金コード
        invoice_identifier,                         -- 請求書識別子
        invoice_amount,                             -- 請求書金額
        context3,                                   -- コンテキスト３
        ussgl_transaction_code,                     -- USSGL取引コード
        descr_flex_error_message,                   -- DFFエラーメッセージ
        jgzz_recon_ref,                             -- 消込参照
        reference_date                              -- 参照日
      )
      SELECT xxagi.status,                          -- ステータス
             xxagi.set_of_books_id,                 -- 会計帳簿ID
             xxagi.accounting_date,                 -- 仕訳計上日
             xxagi.currency_code,                   -- 通貨コード
             xxagi.date_created,                    -- 作成日
             xxagi.created_by,                      -- 作成者ユーザーID
             xxagi.actual_flag,                     -- 実績フラグ
             xxagi.user_je_category_name,           -- 仕訳カテゴリ
             xxagi.user_je_source_name,             -- 仕訳ソース名
             xxagi.currency_conversion_date,        -- 通貨換算日
             xxagi.encumbrance_type_id,             -- 予算引当タイプID
             xxagi.budget_version_id,               -- 予算バージョンID
             xxagi.user_currency_conversion_type,   -- 通貨換算タイプ
             xxagi.currency_conversion_rate,        -- 通貨換算レート
             xxagi.average_journal_flag,            -- 平均仕訳フラグ
             xxagi.originating_bal_seg_value,       -- バランスセグメント値
             xxagi.segment1,                        -- セグメント1（会社）
             xxagi.segment2,                        -- セグメント2（部門）
             xxagi.segment3,                        -- セグメント3（勘定科目）
             xxagi.segment4,                        -- セグメント4（補助科目）
             xxagi.segment5,                        -- セグメント5（顧客）
             xxagi.segment6,                        -- セグメント6（企業）
             xxagi.segment7,                        -- セグメント7(事業区分)
             xxagi.segment8,                        -- セグメント8(予備)
             xxagi.segment9,                        -- セグメント9
             xxagi.segment10,                       -- セグメント10
             xxagi.segment11,                       -- セグメント11
             xxagi.segment12,                       -- セグメント12
             xxagi.segment13,                       -- セグメント13
             xxagi.segment14,                       -- セグメント14
             xxagi.segment15,                       -- セグメント15
             xxagi.segment16,                       -- セグメント16
             xxagi.segment17,                       -- セグメント17
             xxagi.segment18,                       -- セグメント18
             xxagi.segment19,                       -- セグメント19
             xxagi.segment20,                       -- セグメント20
             xxagi.segment21,                       -- セグメント21
             xxagi.segment22,                       -- セグメント22
             xxagi.segment23,                       -- セグメント23
             xxagi.segment24,                       -- セグメント24
             xxagi.segment25,                       -- セグメント25
             xxagi.segment26,                       -- セグメント26
             xxagi.segment27,                       -- セグメント27
             xxagi.segment28,                       -- セグメント28
             xxagi.segment29,                       -- セグメント29
             xxagi.segment30,                       -- セグメント30
             xxagi.entered_dr,                      -- 借方金額
             xxagi.entered_cr,                      -- 貸方金額
             xxagi.accounted_dr,                    -- 機能通貨借方金額
             xxagi.accounted_cr,                    -- 機能通貨貸方金額
             xxagi.transaction_date,                -- トランザクション日
             xxagi.reference1,                      -- リファレンス１(バッチ名)
             xxagi.reference2,                      -- リファレンス２(バッチ摘要)
             xxagi.reference3,                      -- リファレンス３
             xxagi.reference4,                      -- リファレンス４(仕訳名)
             xxagi.reference5,                      -- リファレンス５(仕訳摘要)
             xxagi.reference6,                      -- リファレンス６(仕訳参照)
             xxagi.reference7,                      -- リファレンス７(逆仕訳フラグ)
             xxagi.reference8,                      -- リファレンス８
             xxagi.reference9,                      -- リファレンス９(逆仕訳期間)
             xxagi.reference10,                     -- リファレンス１０(仕訳明細摘要)
             xxagi.reference11,                     -- リファレンス１１
             xxagi.reference12,                     -- リファレンス１２
             xxagi.reference13,                     -- リファレンス１３
             xxagi.reference14,                     -- リファレンス１４
             xxagi.reference15,                     -- リファレンス１５
             xxagi.reference16,                     -- リファレンス１６
             xxagi.reference17,                     -- リファレンス１７
             xxagi.reference18,                     -- リファレンス１８
             xxagi.reference19,                     -- リファレンス１９
             xxagi.reference20,                     -- リファレンス２０
             xxagi.reference21,                     -- リファレンス２１
             xxagi.reference22,                     -- リファレンス２２
             xxagi.reference23,                     -- リファレンス２３
             xxagi.reference24,                     -- リファレンス２４
             xxagi.reference25,                     -- リファレンス２５
             xxagi.reference26,                     -- リファレンス２６
             xxagi.reference27,                     -- リファレンス２７
             xxagi.reference28,                     -- リファレンス２８
             xxagi.reference29,                     -- リファレンス２９
             xxagi.reference30,                     -- リファレンス３０
             xxagi.je_batch_id,                     -- 仕訳バッチID
             xxagi.period_name,                     -- 会計期間
             xxagi.je_header_id,                    -- 仕訳ヘッダID
             xxagi.je_line_num,                     -- 明細番号
             xxagi.chart_of_accounts_id,            -- 勘定体系ID
             xxagi.functional_currency_code,        -- 機能通貨コード
             xxagi.code_combination_id,             -- CCID
             xxagi.date_created_in_gl,              -- GL作成日
             xxagi.warning_code,                    -- 警告コード
             xxagi.status_description,              -- ステータス内容
             xxagi.stat_amount,                     -- 統計数値
             xxagi.group_id,                        -- グループID
             cn_request_id,                         -- 本コンカレントプログラムの要求ID
             xxagi.subledger_doc_sequence_id,       -- 副会計帳簿文書連番ID
             xxagi.subledger_doc_sequence_value,    -- 副会計帳簿文書連番
             xxagi.attribute1,                      -- DFF1(税区分)
             xxagi.attribute2,                      -- DFF2(増減事由)
             xxagi.gl_sl_link_id,                   -- GL_SLリンクID
             xxagi.gl_sl_link_table,                -- GL_SLリンクテーブル
             xxagi.attribute3,                      -- DFF3(伝票番号)
             xxagi.attribute4,                      -- DFF4(起票部門)
             xxagi.attribute5,                      -- DFF5(伝票入力者)
             xxagi.attribute6,                      -- DFF6(修正元伝票番号)
             xxagi.attribute7,                      -- DFF7(予備１)
             xxagi.attribute8,                      -- DFF8(予備２)
             xxagi.attribute9,                      -- DFF9(予備３)
             xxagi.attribute10,                     -- DFF10(予備４)
             xxagi.attribute11,                     -- DFF11
             xxagi.attribute12,                     -- DFF12
             xxagi.attribute13,                     -- DFF13
             xxagi.attribute14,                     -- DFF14
             xxagi.attribute15,                     -- DFF15
             xxagi.attribute16,                     -- DFF16
             xxagi.attribute17,                     -- DFF17
             xxagi.attribute18,                     -- DFF18
             xxagi.attribute19,                     -- DFF19
             xxagi.attribute20,                     -- DFF20
             xxagi.context,                         -- コンテキスト
             xxagi.context2,                        -- コンテキスト２
             xxagi.invoice_date,                    -- 請求書日
             xxagi.tax_code,                        -- 税金コード
             xxagi.invoice_identifier,              -- 請求書識別子
             xxagi.invoice_amount,                  -- 請求書金額
             xxagi.context3,                        -- コンテキスト３
             xxagi.ussgl_transaction_code,          -- USSGL取引コード
             xxagi.descr_flex_error_message,        -- DFFエラーメッセージ
             xxagi.jgzz_recon_ref,                  -- 消込参照
             xxagi.reference_date                   -- 参照日
      FROM xxcfo_adps_gl_interface xxagi
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                      ,cv_msg_011a01_005 -- データ挿入エラー
                                                      ,cv_tkn_table      -- トークン'TABLE'
                                                      ,xxcfr_common_pkg.lookup_dictionary(
                                                         cv_msg_kbn_cfo
                                                        ,cv_dict_tab_03glif
                                                       ) -- 外部公開GLアドオンOIFテーブル
                                                      ,cv_tkn_errmsg     -- トークン'ERRMSG'
                                                      ,SQLERRM )
                                                     ,1
                                                     ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
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
  END insert_xx03_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : truncate_adps_gl_interface
   * Description      : 人事システム用GLアドオンOIF　TRUNCATE処理(A-7)
   ***********************************************************************************/
  PROCEDURE truncate_adps_gl_interface(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'truncate_adps_gl_interface'; -- プログラム名
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
    -- 人事システム用GLアドオンOIFテーブルをTRUNCATEする
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcfo.xxcfo_adps_gl_interface';
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
  END truncate_adps_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_err_check
   * Description      : BFA:GLI/Fエラーチェック起動処理(A-8)
   ***********************************************************************************/
  PROCEDURE submit_request_err_check(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_err_check'; -- プログラム名
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
    -- BFA:GLI/Fエラーチェックコンカレント発行
    gn_submit_req_id := 
    FND_REQUEST.SUBMIT_REQUEST(application => cv_msg_kbn_03,           -- アプリケーション短縮名
                               program     => cv_err_check_name,       -- コンカレントプログラム短縮名
                               argument1   => gn_set_of_bks_id,        -- コンカレントパラメータ(会計帳簿ID)
                               argument2   => cv_conc_param_n,         -- コンカレントパラメータ(GL I/Fテーブル標準区分)
                               argument3   => gv_user_je_source_name,  -- コンカレントパラメータ(仕訳ソース名)
                               argument4   => cn_request_id,           -- コンカレントパラメータ(要求ID)
                               argument5   => NULL                     -- コンカレントパラメータ(グループID)
                              );
    -- コンカレント起動に失敗した場合メッセージを出力
    IF ( gn_submit_req_id = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_002 -- コンカレント起動エラー
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_err_check
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      COMMIT;
    END IF;
--
    -- 後続コンカレントで使用する為、BFA:GLI/Fエラーチェックの要求IDを保存しておく
    gn_submit_req_id_err_check := gn_submit_req_id;
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
  END submit_request_err_check;
--
  /**********************************************************************************
   * Procedure Name   : del_xx03_gl_interface
   * Description      : 外部公開GLアドオンOIF削除処理(A-10-1)
   ***********************************************************************************/
  PROCEDURE del_xx03_gl_interface(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_xx03_gl_interface'; -- プログラム名
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
    -- テーブルロックカーソル
    CURSOR del_table_lock_cur
    IS
      SELECT xxgi.ROWID      xxgi_rowid
      FROM xx03_gl_interface xxgi
      WHERE xxgi.request_id = gn_submit_req_id
      FOR UPDATE NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    del_table_lock_rec    del_table_lock_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 外部公開GLアドオンOIFロックを行う
    OPEN del_table_lock_cur;
--
    BEGIN
      <<delete_lines_loop>>
      LOOP
        FETCH del_table_lock_cur INTO del_table_lock_rec;
        EXIT delete_lines_loop WHEN del_table_lock_cur%NOTFOUND;
        --対象データを削除
        DELETE FROM xx03_gl_interface xxgi
        WHERE CURRENT OF del_table_lock_cur;
      END LOOP delete_lines_loop;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                      ,cv_msg_011a01_007 -- データ削除エラー
                                                      ,cv_tkn_table      -- トークン'TABLE'
                                                      ,xxcfr_common_pkg.lookup_dictionary(
                                                         cv_msg_kbn_cfo
                                                        ,cv_dict_tab_03glif
                                                       ) -- 外部公開GLアドオンOIFテーブル
                                                      ,cv_tkn_errmsg     -- トークン'ERRMSG'
                                                      ,SQLERRM )
                                                     ,1
                                                     ,5000);
        lv_errbuf := lv_errmsg;
        -- カーソルクローズ
        CLOSE del_table_lock_cur;
        RAISE global_api_expt;
    END;
--
    -- カーソルクローズ
    CLOSE del_table_lock_cur;
    COMMIT;
--
  EXCEPTION
--
    -- テーブルロックエラー
    WHEN lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_006 -- ロックエラー
                                                    ,cv_tkn_table      -- トークン'TABLE'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_tab_03glif
                                                     )) -- 外部公開GLアドオンOIFテーブル
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
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
  END del_xx03_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : error_request_err_check
   * Description      : BFA:GLI/Fエラーチェックエラー処理(A-10)
   ***********************************************************************************/
  PROCEDURE error_request_err_check(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_request_err_check'; -- プログラム名
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
    lv_errbuf2 VARCHAR2(5000);  -- エラー・メッセージ
    lv_errmsg2 VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    -- BFA:GLI/Fエラーチェック監視処理がエラーの場合
    IF ( gb_wait_request = FALSE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_003 -- コンカレント監視エラー
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_err_check
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
--
      -- =====================================================
      --  外部公開GLアドオンOIF削除処理 (A-10-1)
      -- =====================================================
      del_xx03_gl_interface(
         lv_errbuf2            -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg2);          -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 外部公開GLアドオンOIF削除処理が異常終了時は、外部公開GLアドオンOIF削除処理の異常を出力する
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg := lv_errmsg2;
        lv_errbuf := lv_errbuf2;
      END IF;
--
      RAISE global_api_expt;
    END IF;
--
    IF ( gv_wait_dev_phase = cv_dev_phase_complete )
      AND ( gv_wait_dev_status = cv_dev_status_normal ) THEN
      -- 正常終了の場合、処理続行する
      gn_normal_cnt := gn_normal_cnt + 1;
--
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_004 -- 監視プログラムエラー終了
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_err_check
                                                     )
                                                    ,cv_tkn_request    -- トークン'REQUEST_ID'
                                                    ,gn_submit_req_id) -- BFA:GLI/Fエラーチェック処理のREQUEST_ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
--
      -- =====================================================
      --  外部公開GLアドオンOIF削除処理 (A-10-1)
      -- =====================================================
      del_xx03_gl_interface(
         lv_errbuf2            -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg2);          -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 外部公開GLアドオンOIF削除処理が異常終了時は、外部公開GLアドオンOIF削除処理の異常を出力する
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg := lv_errmsg2;
        lv_errbuf := lv_errbuf2;
      END IF;
--
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
  END error_request_err_check;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_transfer
   * Description      : BFA:GLI/F転送起動処理(A-11)
   ***********************************************************************************/
  PROCEDURE submit_request_transfer(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_transfer'; -- プログラム名
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
    -- BFA:GLI/F転送コンカレント発行
    gn_submit_req_id := 
    FND_REQUEST.SUBMIT_REQUEST(application => cv_msg_kbn_03,           -- アプリケーション短縮名
                               program     => cv_transfer_name,        -- コンカレントプログラム短縮名
                               argument1   => gn_set_of_bks_id,        -- コンカレントパラメータ(会計帳簿ID)
                               argument2   => gv_user_je_source_name,  -- コンカレントパラメータ(仕訳ソース名)
                               argument3   => gn_submit_req_id_err_check, -- コンカレントパラメータ(要求ID)
                               argument4   => cv_conc_param_n          -- コンカレントパラメータ(警告データの転送)
                              );
    -- コンカレント起動に失敗した場合メッセージを出力
    IF ( gn_submit_req_id = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_002 -- コンカレント起動エラー
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_transfer
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      COMMIT;
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
  END submit_request_transfer;
--
  /**********************************************************************************
   * Procedure Name   : error_request_transfer
   * Description      : BFA:GLI/F転送エラー処理(A-13)
   ***********************************************************************************/
  PROCEDURE error_request_transfer(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_request_transfer'; -- プログラム名
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
    -- BFA:GLI/F転送監視処理がエラーの場合
    IF ( gb_wait_request = FALSE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_003 -- コンカレント監視エラー
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_transfer
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF ( gv_wait_dev_phase = cv_dev_phase_complete )
      AND ( gv_wait_dev_status = cv_dev_status_normal ) THEN
      -- 正常終了の場合、処理続行する
      gn_normal_cnt := gn_normal_cnt + 1;
--
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_004 -- 監視プログラムエラー終了
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_transfer
                                                     )
                                                    ,cv_tkn_request    -- トークン'REQUEST_ID'
                                                    ,gn_submit_req_id) -- BFA:GLI/F転送処理のREQUEST_ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
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
  END error_request_transfer;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_import
   * Description      : 仕訳インポート起動処理(A-14)
   ***********************************************************************************/
  PROCEDURE submit_request_import(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_import'; -- プログラム名
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
    -- 仕訳インポートコンカレント発行
    gn_submit_req_id := 
    FND_REQUEST.SUBMIT_REQUEST(application => cv_msg_kbn_03,           -- アプリケーション短縮名
                               program     => cv_import_name,          -- コンカレントプログラム短縮名
                               argument1   => gn_set_of_bks_id,        -- コンカレントパラメータ(会計帳簿ID)
                               argument2   => gv_adps_je_source,       -- コンカレントパラメータ(仕訳ソース名)
                               argument3   => NULL,                    -- コンカレントパラメータ(グループID)
                               argument4   => cv_conc_param_n,         -- コンカレントパラメータ(エラーを仮勘定に転記)
                               argument5   => cv_conc_param_n,         -- コンカレントパラメータ(要約仕訳の作成)
                               argument6   => NULL,                    -- コンカレントパラメータ(日付範囲(自))
                               argument7   => NULL,                    -- コンカレントパラメータ(日付範囲(至))
                               argument8   => cv_conc_param_o          -- コンカレントパラメータ(DFFインポート)
                              );
    -- コンカレント起動に失敗した場合メッセージを出力
    IF ( gn_submit_req_id = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_002 -- コンカレント起動エラー
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_import
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      COMMIT;
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
  END submit_request_import;
--
  /**********************************************************************************
   * Procedure Name   : error_request_import
   * Description      : 仕訳インポートエラー処理(A-16)
   ***********************************************************************************/
  PROCEDURE error_request_import(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_request_import'; -- プログラム名
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
    -- 仕訳インポート監視処理がエラーの場合
    IF ( gb_wait_request = FALSE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_003 -- コンカレント監視エラー
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_import
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF ( gv_wait_dev_phase = cv_dev_phase_complete )
      AND ( gv_wait_dev_status = cv_dev_status_normal ) THEN
      -- 正常終了の場合、処理続行する
      gn_normal_cnt := gn_normal_cnt + 1;
--
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_004 -- 監視プログラムエラー終了
                                                    ,cv_tkn_program    -- トークン'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_import
                                                     )
                                                    ,cv_tkn_request    -- トークン'REQUEST_ID'
                                                    ,gn_submit_req_id) -- 仕訳インポート起動処理のREQUEST_ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
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
  END error_request_import;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_file_name IN  VARCHAR2,     --   連携ファイル名
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    gn_target_cnt := 4;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  入力パラメータ値ログ出力処理(A-1)
    -- =====================================================
    init(
       iv_target_file_name   -- 連携ファイル名
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  各種システム値取得処理(A-2)
    -- =====================================================
    get_system_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  人事システムデータ連携(SQL*Loader)起動処理(A-3)
    -- =====================================================
    submit_request_sql_loader(
       iv_target_file_name   -- 連携ファイル名
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  人事システムデータ連携(SQL*Loader)監視処理(A-4)
    -- =====================================================
    wait_request(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  人事システムデータ連携(SQL*Loader)エラー処理(A-5)
    -- =====================================================
    error_request_sql_loader(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  外部公開GLアドオンOIF挿入処理(A-6)
    -- =====================================================
    insert_xx03_gl_interface(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  人事システム用GLアドオンOIF　TRUNCATE処理(A-7)
    -- =====================================================
    truncate_adps_gl_interface(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/Fエラーチェック起動処理(A-8)
    -- =====================================================
    submit_request_err_check(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/Fエラーチェック監視処理(A-9)
    -- =====================================================
    wait_request(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/Fエラーチェックエラー処理(A-10)
    -- =====================================================
    error_request_err_check(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/F転送起動処理(A-11)
    -- =====================================================
    submit_request_transfer(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/F転送監視処理(A-12)
    -- =====================================================
    wait_request(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/F転送エラー処理(A-13)
    -- =====================================================
    error_request_transfer(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  仕訳インポート起動処理(A-14)
    -- =====================================================
    submit_request_import(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  仕訳インポート監視処理(A-15)
    -- =====================================================
    wait_request(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  仕訳インポートエラー処理(A-16)
    -- =====================================================
    error_request_import(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
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
    errbuf              OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_target_file_name IN  VARCHAR2       --   連携ファイル名
  )
--
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_target_file_name -- 連携ファイル名
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 異常終了時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt  := 1;
    END IF;
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
END XXCFO011A01C;
/
