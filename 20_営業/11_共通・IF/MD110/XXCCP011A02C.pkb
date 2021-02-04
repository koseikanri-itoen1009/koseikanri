CREATE OR REPLACE PACKAGE BODY APPS.XXCCP011A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCCP011A02C(body)
 * Description      : シーケンス更新(汎用版)
 * MD.050           : 
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *                            終了処理
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/02/02    1.0   N.Koyama         main新規作成
 *
 *****************************************************************************************/
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(20)   :=  'XXCCP011A02C';
--
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)   :=  'XXCCP';
--
  -- ステータス
  cv_status_normal            CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn              CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_error;  -- 異常:2
--
  -- メッセージ
  cv_msg_xxccp_90004          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90004';  -- 正常終了
  cv_msg_xxccp_90005          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90005';  -- 警告終了
  cv_msg_xxccp_90006          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90006';  -- エラー終了全ロールバック
--
  -- トークン
--
  -- セパレータ
  cv_msg_part                 CONSTANT VARCHAR2(3)    :=  ' : ';
  cv_msg_cont                 CONSTANT VARCHAR2(1)    :=  '.';
  cv_empty                    CONSTANT VARCHAR2(1)    :=  '';
--
  -- その他定数
  cv_space                    CONSTANT VARCHAR2(1)    :=  ' ';                 -- 半角スペース
  --
  -- ===============================================
  -- グローバル変数
  -- ===============================================
--
  -- ===============================================
  -- グローバルカーソル
  -- ===============================================
--
  -- ===============================================
  -- 共通例外
  -- ===============================================
  --*** 処理部共通例外 ***
  global_process_expt             EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                 EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt          EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_seq_name      IN  VARCHAR2      --   シーケンス名
   ,ov_errbuf        OUT VARCHAR2
   ,ov_retcode       OUT VARCHAR2
   ,ov_errmsg        OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- 固定ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'submain';
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;  -- 出力用メッセージ
    --
    ln_sequence_nextval   NUMBER; -- シーケンス値格納用
    lt_cache_size         dba_sequences.cache_size%TYPE;                   -- キャッシュサイズ
    lv_sequence_name      dba_sequences.sequence_name%TYPE;                -- シーケンス名
    lv_sql_stmt           VARCHAR2(32767)  DEFAULT NULL;                   -- 動的SQL用文字列
--
    -- ===============================================
    -- ローカル例外
    -- ===============================================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lv_sequence_name := UPPER(iv_seq_name);
    -- ===============================================
    -- 入力パラメータの出力
    -- ===============================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '対象シーケンス:' || iv_seq_name
    );
    -- 空行を出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
--
    -- ===============================================
    -- シーケンス情報取得
    -- ===============================================
    BEGIN
      SELECT ds.cache_size       AS cache_size -- キャッシュサイズ
      INTO   lt_cache_size
      FROM   dba_sequences ds  -- シーケンス情報
      WHERE  ds.sequence_name = lv_sequence_name -- シーケンス名
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 取得できなかった場合
        lv_errbuf := '指定したシーケンスが存在しません。';
        RAISE global_process_expt;
    END;
    -- キャッシュサイズを出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'キャッシュサイズ:' || lt_cache_size
    );
    -- 空行を出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
    -- =======================================================
    -- 動的SQL文の作成(現在値取得)
    -- =======================================================
    lv_sql_stmt := ( 'SELECT ' || lv_sequence_name || '.NEXTVAL sequence_num FROM DUAL' );
    -- =======================================================
    -- ===============================================
    -- シーケンス現在値取得
    -- ===============================================
    -- 動的SQL文の実行
    -- =======================================================
    EXECUTE IMMEDIATE lv_sql_stmt INTO ln_sequence_nextval;
--
    -- 更新前シーケンス値を出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '更新前の値:' || ln_sequence_nextval
    );
    -- =======================================================
    -- 動的SQL文の作成(カウントアップ)
    -- =======================================================
    lv_sql_stmt := ( 'SELECT ' || lv_sequence_name || '.NEXTVAL sequence_num FROM DUAL' );
    -- =======================================================
    <<seq_loop>>
    FOR i IN 1 .. ( lt_cache_size ) LOOP
      -- シーケンスアップ
    -- ===============================================
    -- 動的SQL文の実行
    -- =======================================================
      EXECUTE IMMEDIATE lv_sql_stmt INTO ln_sequence_nextval;
    END LOOP seq_loop;
--
    -- 更新後シーケンス値を出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '更新後の値:' || ln_sequence_nextval
    );    
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf        OUT VARCHAR2
   ,retcode       OUT VARCHAR2
   ,iv_seq_name       VARCHAR2          --   更新シーケンス
  )
  IS
--
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(30)  := 'main';  -- プログラム名
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- エラーメッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターンコード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ユーザーエラーメッセージ
    lv_outmsg        VARCHAR2(5000) DEFAULT NULL;              -- メッセージ変数
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- メッセージコード
--
  BEGIN
    -- ===============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_seq_name     => iv_seq_name
    , ov_errbuf       => lv_errbuf
    , ov_retcode      => lv_retcode
    , ov_errmsg       => lv_errmsg
    );
--
    -- ============================
    --  エラー出力
    -- ============================
    IF ( lv_retcode = cv_status_error ) THEN
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf
      );
      -- 空行を出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => cv_space
      );
--
    END IF;
--
    -- ============================
    --  空行出力
    -- ============================
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ============================
    -- 処理終了メッセージ出力
    -- ============================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_xxccp_90005;
    ELSE
      lv_message_code := cv_msg_xxccp_90006;
    END IF;
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => lv_message_code
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ===============================================
    -- ステータスセット
    -- ===============================================
    retcode := lv_retcode;
--
    -- ===============================================
    -- 終了ステータスエラー時、ロールバック
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCCP011A02C;
/