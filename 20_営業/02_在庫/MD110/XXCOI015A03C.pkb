CREATE OR REPLACE PACKAGE BODY APPS.XXCOI015A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOI015A03C(body)
 * Description      : 資材取引シーケンス更新
 * MD.050           : 
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  upd_sequence              資材取引シーケンス更新(A-2)
 *  init                      初期処理(A-1)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *                            終了処理(A-3)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/11/15    1.0   S.Yamashita      main新規作成
 *
 *****************************************************************************************/
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(20)   :=  'XXCOI015A03C';
--
  -- アプリケーション短縮名
  cv_appl_name_xxcoi          CONSTANT VARCHAR2(10)   :=  'XXCOI';
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)   :=  'XXCCP';
--
  -- ステータス
  cv_status_normal            CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn              CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_error;  -- 異常:2
--
  -- WHOカラム
  cn_created_by               CONSTANT NUMBER         :=  fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by          CONSTANT NUMBER         :=  fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login        CONSTANT NUMBER         :=  fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER         :=  fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER         :=  fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER         :=  fnd_global.conc_program_id;  -- PROGRAM_ID
--
  -- メッセージ
  cv_msg_xxccp_90000          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90000';  -- 対象件数
  cv_msg_xxccp_90001          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90001';  -- 成功件数
  cv_msg_xxccp_90002          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90002';  -- エラー件数
  cv_msg_xxccp_90003          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90003';  -- 警告件数
  cv_msg_xxccp_90004          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90004';  -- 正常終了
  cv_msg_xxccp_90005          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90005';  -- 警告終了
  cv_msg_xxccp_90006          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90006';  -- エラー終了全ロールバック
--
  cv_msg_xxcoi_10387          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10387';  -- コンカレント入力パラメータなしメッセージ
  cv_msg_xxcoi_10724          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10724';  -- 取引ID取得エラーメッセージ
  cv_msg_xxcoi_10725          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10725';  -- 資材取引シーケンス情報取得エラーメッセージ
--
  -- トークン
  cv_token_count              CONSTANT VARCHAR2(20)   :=  'COUNT';
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
  gn_target_cnt               NUMBER  DEFAULT 0;     -- 対象件数
  gn_normal_cnt               NUMBER  DEFAULT 0;     -- 更新件数
  gn_error_cnt                NUMBER  DEFAULT 0;     -- エラー件数
  gn_warn_cnt                 NUMBER  DEFAULT 0;     -- 警告件数
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
   * Procedure Name   : upd_sequence
   * Description      : 資材取引シーケンス更新(A-2)
   ***********************************************************************************/
  PROCEDURE upd_sequence(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name           CONSTANT VARCHAR2(30) := 'upd_sequence';  -- プログラム名
    cv_pgsname_a09c       CONSTANT VARCHAR2(30) := 'XXCOI006A09C';  -- データ連携制御テーブル用プログラム名
    cv_sequence_name      CONSTANT VARCHAR2(50) := 'MTL_MATERIAL_TRANSACTIONS_S';   -- 対象シーケンス名
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf             VARCHAR2(5000) DEFAULT NULL;                              -- エラー・メッセージ
    lv_retcode            VARCHAR2(1)    DEFAULT cv_status_normal;                  -- リターン・コード
    lv_errmsg             VARCHAR2(5000) DEFAULT NULL;                              -- ユーザー・エラー・メッセージ
    lv_outmsg             VARCHAR2(5000) DEFAULT NULL;                              -- 出力用メッセージ
--
    ln_sequence_nextval   NUMBER; -- シーケンス値格納用
    lt_max_transaction_id mtl_material_transactions.transaction_id%TYPE;   -- 資材取引ID(最大値)
    lt_cache_size         dba_sequences.cache_size%TYPE;                   -- キャッシュサイズ
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 資材取引ID(最大値)取得
    -- ===============================================
    BEGIN
      SELECT  xcc.transaction_id    AS transaction_id    -- 取引ID
      INTO    lt_max_transaction_id
      FROM    xxcoi_cooperation_control   xcc         -- データ連携制御テーブル
      WHERE   xcc.program_short_name = cv_pgsname_a09c
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         -- 取得できなかった場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcoi
                       , iv_name         => cv_msg_xxcoi_10724  -- 取引ID取得エラーメッセージ
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================================
    -- シーケンス情報取得
    -- ===============================================
    BEGIN
      SELECT ds.cache_size       AS cache_size -- キャッシュサイズ
      INTO   lt_cache_size
      FROM   dba_sequences ds  -- シーケンス情報
      WHERE  ds.sequence_name = cv_sequence_name -- 資材取引シーケンス
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 取得できなかった場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcoi
                       , iv_name         => cv_msg_xxcoi_10725  -- 資材取引シーケンス情報取得エラーメッセージ
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ##### debug log #####
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   =>               '##### debug log #####'
                 || CHR(10) || 'max_transaction_id : ' || lt_max_transaction_id
                 || CHR(10) || 'cache_size         : ' || lt_cache_size
    );
--
    -- ===============================================
    -- シーケンス現在値取得
    -- ===============================================
    SELECT mtl_material_transactions_s.NEXTVAL AS sequence_nextval
    INTO   ln_sequence_nextval
    FROM   dual
    ;
--
    -- ##### debug log #####
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'Before sequence_val  : ' || ln_sequence_nextval
    );
--
    -- 資材取引ID(最大値)よりもシーケンス現在値が小さい場合
    IF ( lt_max_transaction_id > ln_sequence_nextval ) THEN
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      <<seq_loop>>
      FOR i IN 1 .. ( lt_cache_size ) LOOP
        -- シーケンス更新
        SELECT mtl_material_transactions_s.NEXTVAL AS sequence_nextval
        INTO   ln_sequence_nextval
        FROM   dual
        ;
      END LOOP seq_loop;
--
      -- 成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END IF;
--
    -- ##### debug log #####
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'After sequence_val   : ' || ln_sequence_nextval
    );
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--
--#####################################  固定部 END   ##########################################
--
  END upd_sequence;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2
   ,ov_retcode  OUT VARCHAR2
   ,ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'init';  -- プログラム名
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 入力パラメータの出力
    -- ===============================================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi_10387
                   );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_outmsg
    );
    -- 空行を出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT VARCHAR2
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
    -- ===============================================
    -- ローカル例外
    -- ===============================================
--
  BEGIN
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
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      ov_errbuf   => lv_errbuf
     ,ov_retcode  => lv_retcode
     ,ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 資材取引シーケンス更新(A-2)
    -- ===============================================
    upd_sequence(
      ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
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
      ov_errbuf       => lv_errbuf
    , ov_retcode      => lv_retcode
    , ov_errmsg       => lv_errmsg
    );
--
    -- ===============================================
    -- 終了処理(A-3)
    -- ===============================================
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
      -- エラー件数カウント
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
--
    END IF;
--
    -- ============================
    --  対象件数出力
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_msg_xxccp_90000
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  成功件数出力
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_msg_xxccp_90001
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  エラー件数出力
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_msg_xxccp_90002
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
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
END XXCOI015A03C;
/