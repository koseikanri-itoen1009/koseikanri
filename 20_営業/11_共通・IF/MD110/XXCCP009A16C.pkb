CREATE OR REPLACE PACKAGE BODY APPS.XXCCP009A16C
AS
/*****************************************************************************************
 *
 * Package Name     :  XXCCP009A16C(body)
 * Description      : GLインターフェースエラー検知
 * Version          : 1.0
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/02/27    1.0   SCSK矢崎栄司     新規作成
 *
 *****************************************************************************************/
--
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- アプリケーション短縮名
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP009A16C';
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  --==================================================
  -- グローバルカーソル
  --==================================================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
--
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'submain';            -- プログラム名
    cv_set_of_bks_id    CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_ID';   -- 会計帳簿ID
--
    cv_code_ef01               CONSTANT VARCHAR2(4)   := 'EF01';
    cv_code_ef02               CONSTANT VARCHAR2(4)   := 'EF02';
    cv_code_ef03               CONSTANT VARCHAR2(4)   := 'EF03';
    cv_code_ef04               CONSTANT VARCHAR2(4)   := 'EF04';
    cv_msg_ef01                CONSTANT VARCHAR2(200) := '会計FF記帳日エラー';
    cv_msg_ef02                CONSTANT VARCHAR2(200) := '会計FF転記許可エラー';
    cv_msg_ef03                CONSTANT VARCHAR2(200) := '会計FF使用不可エラー';
    cv_msg_ef04                CONSTANT VARCHAR2(200) := '無効な会計FFエラー';
    cv_msg_others              CONSTANT VARCHAR2(200) := 'その他エラー';
--
    cv_token_request_id        CONSTANT VARCHAR2(9)   := '要求ID： ';
    cv_token_date_created      CONSTANT VARCHAR2(9)   := '作成日： ';
    cv_token_accounting_date   CONSTANT VARCHAR2(13)  := '仕訳計上日： ';
    cv_token_source            CONSTANT VARCHAR2(15)  := '仕訳ソース名： ';
    cv_token_category          CONSTANT VARCHAR2(15)  := '仕訳カテゴリ： ';
    cv_token_status            CONSTANT VARCHAR2(13)  := 'ステータス： ';
    cv_token_kugiri1           CONSTANT VARCHAR2(2)   := '、';
    cv_token_kugiri2           CONSTANT VARCHAR2(1)   := ' ';
    cv_token_kugiri3           CONSTANT VARCHAR2(1)   := ')';
--
    cv_msg_no_parameter CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- パラメータなし
    cv_msg_profile_err  CONSTANT VARCHAR2(100) := 'プロファイルからGL会計帳簿IDの取得に失敗しました。';
--
    cv_status_new                CONSTANT VARCHAR2(3)   := 'NEW';      -- ステータス NEW
    cv_closing_status_open       CONSTANT VARCHAR2(1)   := 'O';        -- 会計期間のステータス(オープン)
    cv_appl_shrt_name_gl         CONSTANT VARCHAR2(5)   := 'SQLGL';    -- アプリケーション短縮名(一般会計)
    cn_before_2months            CONSTANT NUMBER        := -2;         -- ２ヶ月前
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_set_of_bks_id NUMBER           := 0;    -- プロファイル値：会計帳簿ID
--
    ln_glif_err_cnt  NUMBER           := 0;    -- GLインターフェースエラーデータ件数
    lv_err_msg       VARCHAR2(200)    := NULL; -- エラーメッセージ格納変数
    lv_out_msg       VARCHAR2(2000)   := NULL; -- 出力文字列格納用変数
--
  --==================================================
  -- ローカルカーソル
  --==================================================
    CURSOR gl_interface_err_cur
    IS
      SELECT gi.request_id             AS request_id            -- ：要求ID
            ,gi.date_created           AS date_created          -- ：作成日
            ,gi.accounting_date        AS accounting_date       -- ：仕訳計上日
            ,gi.user_je_source_name    AS user_je_source_name   -- ：仕訳ソース名
            ,gi.user_je_category_name  AS user_je_category_name -- ：仕訳カテゴリ
            ,gi.status                 AS status                -- ：ステータス
      FROM   gl_interface              gi                       -- ：GLインターフェース
      WHERE 1=1
      AND    gi.status          <> cv_status_new
      AND    gi.set_of_books_id =  ln_set_of_bks_id
      AND    gi.accounting_date >= ( SELECT ADD_MONTHS ( MIN( gps.start_date ), cn_before_2months ) AS min_start_date_before_2months   -- ：会計期間最小開始日２ヶ月前
                                     FROM   gl_period_statuses   gps   -- 会計期間テーブル
                                           ,fnd_application      fa    -- アプリケーション
                                     WHERE  gps.set_of_books_id        = ln_set_of_bks_id
                                     AND    gps.application_id         = fa.application_id
                                     AND    gps.closing_status         = cv_closing_status_open
                                     AND    fa.application_short_name  = cv_appl_shrt_name_gl
                                   )
      ORDER BY gi.request_id, gi.date_created, gi.accounting_date, gi.user_je_source_name, gi.user_je_category_name, gi.status
    ;
    gl_interface_err_rec gl_interface_err_cur%ROWTYPE;
--
--###########################  固定部 END   ####################################
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
    -- ***************************************
--
    --ローカル変数初期化
    lv_err_msg         := NULL;
    lv_out_msg         := NULL;
    ln_glif_err_cnt    := 0;
--
    --==============================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_msg_no_parameter
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
    -- 空行出力
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => NULL
                     );
--
    -- プロファイルからGL会計帳簿ID取得
    ln_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- 取得エラー時
    IF ( ln_set_of_bks_id IS NULL ) THEN
      lv_errbuf := cv_msg_profile_err;
      RAISE global_api_expt;
    END IF;
--
    --エラーデータの存在確認
    SELECT COUNT( gi.status )  AS err_cnt            -- ：エラー件数
    INTO   ln_glif_err_cnt
    FROM   gl_interface gi
    WHERE 1=1
    AND    gi.status          <> cv_status_new
    AND    gi.set_of_books_id =  ln_set_of_bks_id
    AND    gi.accounting_date >= ( SELECT ADD_MONTHS ( MIN( gps.start_date ), cn_before_2months ) AS min_start_date_before_2months   -- ：会計期間最小開始日２ヶ月前
                                   FROM   gl_period_statuses   gps   -- 会計期間テーブル
                                         ,fnd_application      fa    -- アプリケーション
                                   WHERE  gps.set_of_books_id        = ln_set_of_bks_id
                                   AND    gps.application_id         = fa.application_id
                                   AND    gps.closing_status         = cv_closing_status_open
                                   AND    fa.application_short_name  = cv_appl_shrt_name_gl
                                 );
--
    BEGIN
      IF ln_glif_err_cnt > 0 THEN
        --GLインターフェースエラーが0件より大きい場合、警告終了とし、エラーメッセージを出力する。
        ov_retcode := cv_status_warn;
        FOR gl_interface_err_rec IN gl_interface_err_cur LOOP
          --エラーメッセージ名セット
          IF gl_interface_err_rec.status = cv_code_ef01 THEN
            lv_err_msg  := cv_msg_ef01;
          ELSIF gl_interface_err_rec.status = cv_code_ef02 THEN
            lv_err_msg  := cv_msg_ef02;
          ELSIF gl_interface_err_rec.status = cv_code_ef03 THEN
            lv_err_msg  := cv_msg_ef03;
          ELSIF gl_interface_err_rec.status = cv_code_ef04 THEN
            lv_err_msg  := cv_msg_ef04;
          ELSE
            lv_err_msg  := cv_msg_others;
          END IF;
--
          --出力文字列作成
          lv_out_msg := cv_token_request_id                                                                 ; -- 要求ID(ﾀｲﾄﾙ)
          lv_out_msg := lv_out_msg || gl_interface_err_rec.request_id                                       ; -- 要求ID
          lv_out_msg := lv_out_msg ||  cv_token_kugiri1 ;
          lv_out_msg := lv_out_msg || cv_token_date_created                                                 ; -- 作成日(ﾀｲﾄﾙ)
          lv_out_msg := lv_out_msg || TO_CHAR( gl_interface_err_rec.date_created, 'YYYY/MM/DD HH24:MI:SS' ) ; -- 作成日
          lv_out_msg := lv_out_msg || cv_token_kugiri1 ;
          lv_out_msg := lv_out_msg || cv_token_accounting_date                                              ; -- 仕訳計上日(ﾀｲﾄﾙ)
          lv_out_msg := lv_out_msg || TO_CHAR( gl_interface_err_rec.accounting_date, 'YYYY/MM/DD' )         ; -- 仕訳計上日
          lv_out_msg := lv_out_msg || cv_token_kugiri1 ;
          lv_out_msg := lv_out_msg || cv_token_source                                                       ; -- 仕訳ソース名(ﾀｲﾄﾙ)
          lv_out_msg := lv_out_msg || gl_interface_err_rec.user_je_source_name                              ; -- 仕訳ソース名
          lv_out_msg := lv_out_msg || cv_token_kugiri1 ;
          lv_out_msg := lv_out_msg || cv_token_category                                                     ; -- 仕訳カテゴリ(ﾀｲﾄﾙ)
          lv_out_msg := lv_out_msg || gl_interface_err_rec.user_je_category_name                            ; -- 仕訳カテゴリ
          lv_out_msg := lv_out_msg || cv_token_kugiri1 ;
          lv_out_msg := lv_out_msg || cv_token_status                                                       ; -- ｽﾃｰﾀｽ(ﾀｲﾄﾙ)
          lv_out_msg := lv_out_msg || gl_interface_err_rec.status                                           ; -- ｽﾃｰﾀｽｺｰﾄﾞ
          lv_out_msg := lv_out_msg || cv_token_kugiri2 ;
          lv_out_msg := lv_out_msg || lv_err_msg                                                            ; -- ｽﾃｰﾀｽ名
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_out_msg
          );
          --件数カウント
          gn_target_cnt      := gn_target_cnt + 1;
          gn_error_cnt       := gn_error_cnt  + 1;
        END LOOP;
      ELSE
      --GLインターフェースエラーが0件の場合、正常終了とする。
        ov_retcode := cv_status_normal;
        --件数カウント
        gn_target_cnt      := 0;
        gn_error_cnt       := 0;
      END IF;
--
    END;
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
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
    errbuf              OUT    VARCHAR2,       --   エラー・メッセージ  --# 固定 #
    retcode             OUT    VARCHAR2        --   リターン・コード    --# 固定 #
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_msg_err_end     CONSTANT VARCHAR2(100) := '処理がエラー終了しました。';     -- エラー終了メッセージ
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    --
  BEGIN
--
    -- ===============================================
    -- 初期処理
    -- ===============================================
    --
    -- 1.変数初期化
    gn_target_cnt := 0;
    gn_error_cnt  := 0;
--
      -- ===============================================
      -- submainの呼び出し（実際の処理はsubmainで行う）
      -- ===============================================
      submain(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      --対象件数クリア
      gn_target_cnt := 0;
      --エラー件数
      gn_error_cnt  := 1;
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
    ELSIF(lv_retcode = cv_status_warn) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
    ELSIF(lv_retcode = cv_status_error) THEN
      gv_out_msg := cv_msg_err_end;
    END IF;
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCCP009A16C;
/
