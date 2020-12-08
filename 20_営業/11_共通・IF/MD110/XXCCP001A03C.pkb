CREATE OR REPLACE PACKAGE BODY APPS.XXCCP001A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCCP001A03C(body)
 * Description      : WF不正受注明細検知＆対象外更新
 * MD.070           : WF不正受注明細検知＆対象外更新 (MD070_IPO_CCP_001_A03)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/12/03    1.0   N.Koyama         [E_本稼動_16819]新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  gv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_update_cnt             NUMBER;                    -- 更新件数
  gn_error_cnt              NUMBER;                    -- エラー件数
  gn_warn_cnt               NUMBER;                    -- 警告件数
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
  gv_appl_short_name_xxccp  CONSTANT VARCHAR2(10)    := 'XXCCP';
  -- パッケージ名
  gv_pkg_name               CONSTANT VARCHAR2(100)   := 'XXCCP001A03C';      -- パッケージ名
  gv_appl_short_name        CONSTANT VARCHAR2(10)    := 'XXCCP';             -- アドオン：共通・IF領域
--
  gv_0                      CONSTANT VARCHAR2(1)     := '0';                 -- ログ出力のみ
  gv_1                      CONSTANT VARCHAR2(1)     := '1';                 -- ログ出力およびデータ更新
  gv_flag_p                 CONSTANT VARCHAR2(1)     := 'P';                 -- フラグ「P」
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  --===============================================================
  -- グローバル例外
  --===============================================================
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_exe_mode           IN  VARCHAR2      --   実行モード
   ,in_back_num           IN  NUMBER        --   対象FROM数
   ,ov_errbuf             OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';   -- プログラム名
    cv_item_type            CONSTANT VARCHAR2(100) := 'OEOL';
    cv_entered              CONSTANT VARCHAR2(100) := 'ENTERED';
    cv_booked               CONSTANT VARCHAR2(100) := 'BOOKED';
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
    lv_exe_mode           VARCHAR2(1);                             -- 実行モード
    ln_max_line_id        NUMBER;                                  -- 最大受注明細ID
    ln_go_back_count      NUMBER;                                  -- 対象FROM数
    ln_order_number       oe_order_headers_all.order_number%TYPE;  -- 受注番号
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- WF不正受注明細レコード取得
    CURSOR main_cur
    IS
--  WF不正受注明細
      SELECT ooha.header_id    header_id,      -- 受注ヘッダーID
             ooha.order_number order_number,   -- 受注番号
             oola.line_id      line_id,        -- 受注明細ID
             oola.line_number  line_number     -- 受注明細番号
        FROM apps.oe_order_headers_all ooha,
             apps.oe_order_lines_all oola
       WHERE 1=1
         AND ooha.header_id = oola.header_id
         AND oola.line_id  >= ( ln_max_line_id - ln_go_back_count )
         AND oola.flow_status_code IN ( cv_entered, cv_booked )
         AND NOT EXISTS (
                          SELECT 1
                            FROM apps.wf_item_activity_statuses wias
                           WHERE wias.item_type = cv_item_type
                             AND wias.item_key  = TO_CHAR( oola.line_id )
                        )
      ;
--
    -- 受注明細（排他）
    CURSOR order_lines_lock_cur(
      in_header_id IN NUMBER   -- 1.受注ヘッダーID
    ) IS
      SELECT  oola.header_id           header_id   -- 受注ヘッダーID
        FROM  apps.oe_order_lines_all  oola
       WHERE  oola.header_id = in_header_id
      FOR UPDATE OF oola.header_id NOWAIT
      ;
--
    -- メインカーソルレコード型
    main_rec               main_cur%ROWTYPE;
    -- 受注明細（排他）カーソルレコード型
    order_lines_lock_rec   order_lines_lock_cur%ROWTYPE;
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
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_update_cnt := 0;
--
    -- ===============================
    -- init部
    -- ===============================
--
    -- INパラメータを変数に退避
    lv_exe_mode      := iv_exe_mode;
    ln_go_back_count := in_back_num;
--
    -- 変数初期化
    ln_order_number := 0;
--
    -- パラメータ：実行モード
    IF ( lv_exe_mode = gv_0 ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '実行モード：0（ログ出力のみ）'
          );
    ELSIF ( lv_exe_mode = gv_1 ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '実行モード：1（ログ出力およびデータ更新）'
          );
    END IF;
--
    -- パラメータ：範囲FROM
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '範囲FROM： ' || TO_CHAR( ln_go_back_count )
        );
--
    -- 現時点の最大受注明細ID
    SELECT MAX(ola.line_id)  max_line_id
      INTO ln_max_line_id
      FROM oe_order_lines_all ola
    ;
--
    -- 基準明細ID
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '基準明細ID： ' || TO_CHAR( ln_max_line_id - ln_go_back_count )
        );
    -- 最大明細ID
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '最大明細ID： ' || TO_CHAR( ln_max_line_id )
        );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- ===============================
    -- 処理部
    -- ===============================
--
    -- データ部出力
    FOR main_rec IN main_cur LOOP
      -- 更新対象の受注番号、受注明細番号を出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '受注番号 ： ' || main_rec.order_number  || ' 受注明細番号 ： ' || main_rec.line_number || ' のWFの紐つきが不正です。'
          );
--
      -- 対象データがある場合は警告終了
      ov_retcode  := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
--
      -- 更新ありの場合
      IF ( lv_exe_mode = gv_1 ) THEN
        BEGIN
--
          -- 排他処理
          OPEN order_lines_lock_cur(
            main_rec.header_id    -- 1.受注ヘッダーID
          );
          FETCH order_lines_lock_cur INTO order_lines_lock_rec;
          CLOSE order_lines_lock_cur;
--
          UPDATE apps.oe_order_lines_all oola
             SET oola.global_attribute5 = gv_flag_p  -- 販売実績連携済フラグ
           WHERE oola.header_id = main_rec.header_id
          ;
--
          IF ( ln_order_number <> main_rec.order_number ) THEN
            -- 更新対象の受注番号、明細数を出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => '受注番号 ： ' || main_rec.order_number || ' の全明細の販売実績作成済フラグを更新しました。明細数 ： ' || SQL%ROWCOUNT
                );
--
            -- 更新件数カウント
            gn_update_cnt := gn_update_cnt + SQL%ROWCOUNT;
--
          END IF;
--
          -- 受注番号退避
          ln_order_number  := main_rec.order_number;
--
          COMMIT;
--
        EXCEPTION
          WHEN lock_expt THEN  -- テーブルロックエラー
            IF ( order_lines_lock_cur%ISOPEN ) THEN
              -- カーソルのクローズ
              CLOSE order_lines_lock_cur;
            END IF;
--
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => '他のユーザーにより使用中です。受注番号 ： ' || main_rec.order_number || ' 受注明細番号 ： ' || main_rec.line_number
                );
--
            ov_retcode   := gv_status_error;
            gn_error_cnt := gn_error_cnt + 1;
            ROLLBACK;
          WHEN OTHERS THEN
            IF ( order_lines_lock_cur%ISOPEN ) THEN
              -- カーソルのクローズ
              CLOSE order_lines_lock_cur;
            END IF;
--
            ov_errbuf    := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
            ov_retcode   := gv_status_error;
            gn_error_cnt := gn_error_cnt + 1;
            ROLLBACK;
        END;
      END IF;
--
    END LOOP;
--
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := gv_status_error;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
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
    errbuf                OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode               OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_exe_mode           IN  VARCHAR2      --   実行モード
   ,in_back_num           IN  NUMBER        --   対象FROM数
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_exe_mode                              -- 実行モード
      ,in_back_num                                 -- 対象FROM数
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = gv_status_error) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --更新件数出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '更新件数  ：  ' || TO_CHAR(gn_update_cnt) || ' 件'
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_appl_short_name
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
    IF (lv_retcode = gv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = gv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = gv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
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
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP001A03C;
/