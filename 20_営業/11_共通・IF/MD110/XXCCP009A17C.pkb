CREATE OR REPLACE PACKAGE BODY APPS.XXCCP009A17C
AS
/*****************************************************************************************
 *
 * Package Name     : XXCCP009A17C(body)
 * Description      : OIFパージ機能（AP_AR_GL）
 * Version          : 1.0
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *  ap_header                APヘッダープロシージャ
 *  ap_line                  AP明細プロシージャ
 *  ar_header                ARヘッダープロシージャ
 *  ar_line                  AR明細プロシージャ
 *  gl_header                GLヘッダープロシージャ
 *  gl_line                  GL明細プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/12/10    1.0   SCSK及川領      新規作成
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
  gv_out_msg         VARCHAR2(2000);
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
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20)  := 'XXCCP009A17C';
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';        -- アドオン：共通・IF領域
--
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'REQ_ID';            -- 要求IDメッセージ用トークン名
  cv_req_ap_header_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00029';  -- 削除対象要求IDメッセージ（AP部門入力ヘッダ）
  cv_req_ap_line_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00030';  -- 削除対象要求IDメッセージ（AP部門入力明細）
  cv_req_ar_header_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00031';  -- 削除対象要求IDメッセージ（AR部門入力ヘッダ）
  cv_req_ar_line_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00032';  -- 削除対象要求IDメッセージ（AR部門入力明細）
  cv_req_gl_header_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00033';  -- 削除対象要求IDメッセージ（GL部門入力ヘッダ）
  cv_req_gl_line_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00034';  -- 削除対象要求IDメッセージ（GL部門入力明細）
  -- フェーズ
  cv_phase_code_normal      CONSTANT VARCHAR2(30)  := 'C';         -- 完了
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_ap_header_cnt   NUMBER;             -- APヘッダー対象件数
  gn_ap_line_cnt     NUMBER;             -- AP明細対象件数
  gn_ar_header_cnt   NUMBER;             -- ARヘッダー対象件数
  gn_ar_line_cnt     NUMBER;             -- AR明細対象件数
  gn_gl_header_cnt   NUMBER;             -- GLヘッダー対象件数
  gn_gl_line_cnt     NUMBER;             -- GL明細対象件数
  gn_error_cnt       NUMBER;             -- エラー件数
--
  --==================================================
  -- グローバルカーソル
  --==================================================
--
  /**********************************************************************************
   * Procedure Name   : ap_header
   * Description      : APヘッダープロシージャ
   **********************************************************************************/
  PROCEDURE ap_header(
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'ap_header';   -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_request_id    xx03_payment_slips_if.request_id%TYPE; -- 要求ID
--
  --==================================================
  -- ローカルカーソル
  --==================================================
    -- APヘッダー
    CURSOR ap_header_cur
    IS
      SELECT DISTINCT xpsi.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- コンカレント情報
             xx03_payment_slips_if xpsi                -- APヘッダーOIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- フェーズ
      AND    fcr.request_id  = xpsi.request_id
      ;
    ap_header_rec ap_header_cur%ROWTYPE;
--
    -- APヘッダー（排他）
    CURSOR ap_header_lock_cur(
      in_request_id IN NUMBER   -- 1.要求ID
    ) IS
      SELECT xpsi.request_id request_id
      FROM   xx03_payment_slips_if xpsi                -- APヘッダーOIF
      WHERE  xpsi.request_id = in_request_id
      FOR UPDATE OF xpsi.request_id NOWAIT
      ;
    ap_header_lock_rec ap_header_lock_cur%ROWTYPE;
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
    BEGIN
        -- APヘッダーOIF
        FOR ap_header_rec IN ap_header_cur LOOP
--
          BEGIN
            -- 排他処理
            OPEN ap_header_lock_cur(
              ap_header_rec.request_id    -- 1.要求ID
            );
            FETCH ap_header_lock_cur INTO ap_header_lock_rec;
            CLOSE ap_header_lock_cur;
--
            -- 削除処理
            DELETE  xx03_payment_slips_if xpsi
              WHERE xpsi.request_id   = ap_header_rec.request_id
            ;
--
            --件数カウント
            gn_ap_header_cnt   := gn_ap_header_cnt + SQL%ROWCOUNT;
--
            --削除対象ID出力(APヘッダー)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_ap_header_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  ap_header_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( ap_header_lock_cur%ISOPEN ) THEN
                -- カーソルのクローズ
                CLOSE ap_header_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
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
--####################################  固定部 END   ##########################################
--
  END ap_header;
--
  /**********************************************************************************
   * Procedure Name   : ap_line
   * Description      : AP明細プロシージャ
   **********************************************************************************/
  PROCEDURE ap_line(
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'ap_line';   -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_request_id    xx03_payment_slip_lines_if.request_id%TYPE; -- 要求ID
--
  --==================================================
  -- ローカルカーソル
  --==================================================
    -- AP明細
    CURSOR ap_line_cur
    IS
      SELECT DISTINCT xpsli.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- コンカレント情報
             xx03_payment_slip_lines_if xpsli          -- AP明細OIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- フェーズ
      AND    fcr.request_id  = xpsli.request_id
      ;
    ap_line_rec ap_line_cur%ROWTYPE;
--
    -- AP明細（排他）
    CURSOR ap_line_lock_cur(
      in_request_id IN NUMBER   -- 1.要求ID
    ) IS
      SELECT xpsli.request_id request_id
      FROM   xx03_payment_slip_lines_if xpsli          -- AP明細OIF
      WHERE  xpsli.request_id = in_request_id
      FOR UPDATE OF xpsli.request_id NOWAIT
      ;
    ap_line_lock_rec ap_line_lock_cur%ROWTYPE;
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
    BEGIN
        -- AP明細OIF
        FOR ap_line_rec IN ap_line_cur LOOP
--
          BEGIN
--
            -- 排他処理
            OPEN ap_line_lock_cur(
              ap_line_rec.request_id    -- 1.要求ID
            );
            FETCH ap_line_lock_cur INTO ap_line_lock_rec;
            CLOSE ap_line_lock_cur;
--
            -- 削除処理
            DELETE  xx03_payment_slip_lines_if xpsli
              WHERE xpsli.request_id   = ap_line_rec.request_id
            ;
--
            --件数カウント
            gn_ap_line_cnt   := gn_ap_line_cnt + SQL%ROWCOUNT;
--
            --削除対象ID出力(AP明細)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_ap_line_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  ap_line_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( ap_line_lock_cur%ISOPEN ) THEN
                -- カーソルのクローズ
                CLOSE ap_line_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
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
--####################################  固定部 END   ##########################################
--
  END ap_line;
--
  /**********************************************************************************
   * Procedure Name   : ar_header
   * Description      : ARヘッダープロシージャ
   **********************************************************************************/
  PROCEDURE ar_header(
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'ar_header';   -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_request_id    xx03_receivable_slips_if.request_id%TYPE; -- 要求ID
--
  --==================================================
  -- ローカルカーソル
  --==================================================
    -- ARヘッダー
    CURSOR ar_header_cur
    IS
      SELECT DISTINCT xrsi.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- コンカレント情報
             xx03_receivable_slips_if xrsi             -- ARヘッダーOIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- フェーズ
      AND    fcr.request_id  = xrsi.request_id
      ;
    ar_header_rec ar_header_cur%ROWTYPE;
--
    -- ARヘッダー（排他）
    CURSOR ar_header_lock_cur(
      in_request_id IN NUMBER   -- 1.要求ID
    ) IS
      SELECT xrsi.request_id request_id
      FROM   xx03_receivable_slips_if xrsi             -- ARヘッダーOIF
      WHERE  xrsi.request_id = in_request_id
      FOR UPDATE OF xrsi.request_id NOWAIT
      ;
    ar_header_lock_rec ar_header_lock_cur%ROWTYPE;
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
    BEGIN
        -- ARヘッダーOIF
        FOR ar_header_rec IN ar_header_cur LOOP
--
          BEGIN
            -- 排他処理
            OPEN ar_header_lock_cur(
              ar_header_rec.request_id    -- 1.要求ID
            );
            FETCH ar_header_lock_cur INTO ar_header_lock_rec;
            CLOSE ar_header_lock_cur;
--
            -- 削除処理
            DELETE  xx03_receivable_slips_if xrsi
              WHERE xrsi.request_id   = ar_header_rec.request_id
            ;
            --件数カウント
            gn_ar_header_cnt   := gn_ar_header_cnt + SQL%ROWCOUNT;
--
            --削除対象ID出力(ARヘッダー)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_ar_header_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  ar_header_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( ar_header_lock_cur%ISOPEN ) THEN
                -- カーソルのクローズ
                CLOSE ar_header_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
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
--####################################  固定部 END   ##########################################
--
  END ar_header;
--
  /**********************************************************************************
   * Procedure Name   : ar_line
   * Description      : AR明細プロシージャ
   **********************************************************************************/
  PROCEDURE ar_line(
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'ar_line';   -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_request_id    xx03_receivable_slips_line_if.request_id%TYPE; -- 要求ID
--
  --==================================================
  -- ローカルカーソル
  --==================================================
    -- AR明細
    CURSOR ar_line_cur
    IS
      SELECT DISTINCT xrsli.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- コンカレント情報
             xx03_receivable_slips_line_if xrsli       -- AR明細OIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- フェーズ
      AND    fcr.request_id  = xrsli.request_id
      ;
    ar_line_rec ar_line_cur%ROWTYPE;
--
    -- AR明細（排他）
    CURSOR ar_line_lock_cur(
      in_request_id IN NUMBER   -- 1.要求ID
    ) IS
      SELECT xrsli.request_id request_id
      FROM   xx03_receivable_slips_line_if xrsli       -- AR明細OIF
      WHERE  xrsli.request_id = in_request_id
      FOR UPDATE OF xrsli.request_id NOWAIT
      ;
    ar_line_lock_rec ar_line_lock_cur%ROWTYPE;
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
    BEGIN
        -- AR明細OIF
        FOR ar_line_rec IN ar_line_cur LOOP
--
          BEGIN
            -- 排他処理
            OPEN ar_line_lock_cur(
              ar_line_rec.request_id    -- 1.要求ID
            );
            FETCH ar_line_lock_cur INTO ar_line_lock_rec;
            CLOSE ar_line_lock_cur;
--
            -- 削除処理
            DELETE  xx03_receivable_slips_line_if xrsli
              WHERE xrsli.request_id   = ar_line_rec.request_id
            ;
            --件数カウント
            gn_ar_line_cnt   := gn_ar_line_cnt + SQL%ROWCOUNT;
--
            --削除対象ID出力(AR明細)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_ar_line_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  ar_line_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( ar_line_lock_cur%ISOPEN ) THEN
                -- カーソルのクローズ
                CLOSE ar_line_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
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
--####################################  固定部 END   ##########################################
--
  END ar_line;
--
  /**********************************************************************************
   * Procedure Name   : gl_header
   * Description      : GLヘッダープロシージャ
   **********************************************************************************/
  PROCEDURE gl_header(
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'gl_header';   -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_request_id    xx03_journal_slips_if.request_id%TYPE; -- 要求ID
--
  --==================================================
  -- ローカルカーソル
  --==================================================
    -- GLヘッダー
    CURSOR gl_header_cur
    IS
      SELECT DISTINCT xjsi.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- コンカレント情報
             xx03_journal_slips_if xjsi                -- GLヘッダーOIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- フェーズ
      AND    fcr.request_id  = xjsi.request_id
      ;
    gl_header_rec gl_header_cur%ROWTYPE;
--
    -- GLヘッダー（排他）
    CURSOR gl_header_lock_cur(
      in_request_id IN NUMBER   -- 1.要求ID
    ) IS
      SELECT xjsi.request_id request_id
      FROM   xx03_journal_slips_if xjsi                -- GLヘッダーOIF
      WHERE  xjsi.request_id = in_request_id
      FOR UPDATE OF xjsi.request_id NOWAIT
      ;
    gl_header_lock_rec gl_header_lock_cur%ROWTYPE;
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
    BEGIN
        -- GLヘッダーOIF
        FOR gl_header_rec IN gl_header_cur LOOP
--
          BEGIN
            -- 排他処理
            OPEN gl_header_lock_cur(
              gl_header_rec.request_id    -- 1.要求ID
            );
            FETCH gl_header_lock_cur INTO gl_header_lock_rec;
            CLOSE gl_header_lock_cur;
--
            -- 削除処理
            DELETE  xx03_journal_slips_if xjsi
              WHERE xjsi.request_id   = gl_header_rec.request_id
            ;
            --件数カウント
            gn_gl_header_cnt   := gn_gl_header_cnt + SQL%ROWCOUNT;
--
            --削除対象ID出力(GLヘッダー)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_gl_header_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  gl_header_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( gl_header_lock_cur%ISOPEN ) THEN
                -- カーソルのクローズ
                CLOSE gl_header_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
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
--####################################  固定部 END   ##########################################
--
  END gl_header;
--
  /**********************************************************************************
   * Procedure Name   : gl_line
   * Description      : GL明細プロシージャ
   **********************************************************************************/
  PROCEDURE gl_line(
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'gl_line';   -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_request_id    xx03_journal_slip_lines_if.request_id%TYPE; -- 要求ID
--
  --==================================================
  -- ローカルカーソル
  --==================================================
    -- GL明細
    CURSOR gl_line_cur
    IS
      SELECT DISTINCT xjsli.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- コンカレント情報
             xx03_journal_slip_lines_if xjsli          -- GL明細OIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- フェーズ
      AND    fcr.request_id  = xjsli.request_id
      ;
    gl_line_rec gl_line_cur%ROWTYPE;
--
    -- GL明細（排他）
    CURSOR gl_line_lock_cur(
      in_request_id IN NUMBER   -- 1.要求ID
    ) IS
      SELECT xjsli.request_id request_id
      FROM   xx03_journal_slip_lines_if xjsli          -- GL明細OIF
      WHERE  xjsli.request_id = in_request_id
      FOR UPDATE OF xjsli.request_id NOWAIT
      ;
    gl_line_lock_rec gl_line_lock_cur%ROWTYPE;

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
    BEGIN
        -- GL明細OIF
        FOR gl_line_rec IN gl_line_cur LOOP
--
          BEGIN
            -- 排他処理
            OPEN gl_line_lock_cur(
              gl_line_rec.request_id    -- 1.要求ID
            );
            FETCH gl_line_lock_cur INTO gl_line_lock_rec;
            CLOSE gl_line_lock_cur;
--
            -- 削除処理
            DELETE  xx03_journal_slip_lines_if xjsli
              WHERE xjsli.request_id   = gl_line_rec.request_id
            ;
            --件数カウント
            gn_gl_line_cnt   := gn_gl_line_cnt + SQL%ROWCOUNT;
--
            --削除対象ID出力(GL明細)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_gl_line_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  gl_line_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( gl_line_lock_cur%ISOPEN ) THEN
                -- カーソルのクローズ
                CLOSE gl_line_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
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
--####################################  固定部 END   ##########################################
--
  END gl_line;
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';   -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  --==================================================
  -- ローカルカーソル
  --==================================================
--
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
    BEGIN
      -- APヘッダーOIF
      ap_header(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --エラーメッセージ
        );
      END IF;
--
      -- AP明細OIF
      ap_line(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --エラーメッセージ
        );
      END IF;
--
      -- ARヘッダーOIF
      ar_header(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --エラーメッセージ
        );
      END IF;
--
      -- AR明細OIF
      ar_line(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --エラーメッセージ
        );
      END IF;
--
      -- GLヘッダーOIF
      gl_header(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --エラーメッセージ
        );
      END IF;
--
      -- GL明細OIF
      gl_line(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --エラーメッセージ
        );
      END IF;
--
    END;
--
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
    cv_prg_name          CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_cnt_token         CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_del_ap_header_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00023'; -- 削除件数メッセージ（XX03_PAYMENT_SLIPS_IF）
    cv_del_ap_line_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00024'; -- 削除件数メッセージ（XX03_PAYMENT_SLIP_LINES_IF）
    cv_del_ar_header_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00025'; -- 削除件数メッセージ（XX03_RECEIVABLE_SLIPS_IF）
    cv_del_ar_line_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00026'; -- 削除件数メッセージ（XX03_RECEIVABLE_SLIPS_LINE_IF）
    cv_del_gl_header_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00027'; -- 削除件数メッセージ（XX03_JOURNAL_SLIPS_IF）
    cv_del_gl_line_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00028'; -- 削除件数メッセージ（XX03_JOURNAL_SLIP_LINES_IF）
    cv_error_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_msg_err_end       CONSTANT VARCHAR2(100) := '処理がエラー終了しました。';     -- エラー終了メッセージ
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
    gn_ap_header_cnt := 0;
    gn_ap_line_cnt   := 0;
    gn_ar_header_cnt := 0;
    gn_ar_line_cnt   := 0;
    gn_gl_header_cnt := 0;
    gn_gl_line_cnt   := 0;
    gn_error_cnt     := 0;
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
    --対象件数出力(APヘッダー)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_ap_header_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_ap_header_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力(AP明細)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_ap_line_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_ap_line_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力(ARヘッダー)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_ar_header_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_ar_header_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力(AR明細)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_ar_line_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_ar_line_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力(GLヘッダー)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_gl_header_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_gl_header_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力(GL明細)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_gl_line_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_gl_line_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    -- 正常
    IF ( gn_error_cnt = 0
      AND ( gn_ap_header_cnt + gn_ap_line_cnt + gn_ar_header_cnt + gn_ar_line_cnt + gn_gl_header_cnt + gn_gl_line_cnt > 0 ) ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
      lv_retcode := cv_status_normal;
    -- 警告
    ELSIF ( gn_error_cnt = 0
      AND ( gn_ap_header_cnt + gn_ap_line_cnt + gn_ar_header_cnt + gn_ar_line_cnt + gn_gl_header_cnt + gn_gl_line_cnt = 0 ) ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
      lv_retcode := cv_status_warn;
    -- 異常
    ELSIF( gn_error_cnt > 0 ) THEN
      gv_out_msg := cv_msg_err_end;
      lv_retcode := cv_status_error;
      ROLLBACK;
    END IF;
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
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
END XXCCP009A17C;
/
