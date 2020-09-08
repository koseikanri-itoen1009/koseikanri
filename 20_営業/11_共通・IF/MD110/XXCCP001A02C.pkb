CREATE OR REPLACE PACKAGE BODY APPS.XXCCP001A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCCP001A02C(body)
 * Description      : 不正販売実績検知
 * MD.070           : 不正販売実績検知(MD070_IPO_CCP_001_A02)
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
 *  2020/08/06    1.0   N.Koyama         [E_本稼動_16546]新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- 警告件数
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
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP001A02C'; -- パッケージ名
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_process_date       IN  VARCHAR2      --   業務日付
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
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
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
    ld_date    DATE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 不正販売実績レコード取得
    CURSOR main_cur
    IS
--  販売実績ヘッダ金額不正
       SELECT  1                                          AS error_kind
              ,xseh.sales_exp_header_id                   AS sales_exp_header_id
              ,xseh.ship_to_customer_code                 AS ship_to_customer_code
              ,TO_CHAR(xseh.delivery_date,'YYYY/MM/DD')   AS delivery_date
              ,xseh.sale_amount_sum                       AS sale_amount_sum
              ,SUM(xsel.sale_amount)                      AS sale_amount_sum_l
              ,xseh.results_employee_code                 AS results_employee_code
         FROM xxcos_sales_exp_headers xseh
             ,xxcos_sales_exp_lines   xsel
        WHERE xseh.business_date = ld_date
          AND xseh.sales_exp_header_id = xsel.sales_exp_header_id
        GROUP BY 1
                ,xseh.sales_exp_header_id
                ,xseh.ship_to_customer_code
                ,TO_CHAR(xseh.delivery_date,'YYYY/MM/DD')
                ,xseh.sale_amount_sum
                ,xseh.results_employee_code
       HAVING xseh.sale_amount_sum <> SUM(xsel.sale_amount)     
       UNION ALL
--  販売実績ヘッダ成績者コード不正
       SELECT  2                                          AS error_kind
              ,xseh.sales_exp_header_id                   AS sales_exp_header_id
              ,xseh.ship_to_customer_code                 AS ship_to_customer_code
              ,TO_CHAR(xseh.delivery_date,'YYYY/MM/DD')   AS delivery_date
              ,NULL                                       AS sale_amount_sum
              ,NULL                                       AS sale_amount_sum_l
              ,xseh.results_employee_code                 AS results_employee_code
         FROM xxcos_sales_exp_headers xseh
       WHERE xseh.business_date = ld_date
         AND NOT EXISTS  (SELECT 1
                            FROM per_all_people_f pap
                           WHERE pap.employee_number  = xseh.results_employee_code
                             AND xseh.delivery_date BETWEEN pap.effective_start_date
                               AND  NVL( pap.effective_end_date, ld_date ))
      ;
    -- メインカーソルレコード型
    main_rec  main_cur%ROWTYPE;
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
    gn_error_cnt  := 0;
--
    -- ===============================
    -- init部
    -- ===============================
--
    IF ( iv_process_date IS NULL ) THEN
      ld_date := xxccp_common_pkg2.get_process_date;
    ELSE
      ld_date := TO_DATE(iv_process_date,'YYYY/MM/DD HH24:MI:SS');
    END IF;
    -- 処理業務日付出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => '処理業務日付：'|| TO_CHAR(ld_date,'YYYY/MM/DD')
    );
--
    -- ===============================
    -- 処理部
    -- ===============================
--
    -- データ部出力
    FOR main_rec IN main_cur LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      IF ( main_rec.error_kind = 1 )
      THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '販売実績ヘッダの合計金額と販売実績明細の合計金額が一致していません。'     ||
                     ' 販売実績ID:'   || main_rec.sales_exp_header_id                           ||  -- 販売実績ID
                     ' 顧客コード:'   || main_rec.ship_to_customer_code                         ||  -- 顧客コード
                     ' 納品日:'       || main_rec.delivery_date                                 ||  -- 納品日
                     ' ヘッダ金額:'   || main_rec.sale_amount_sum                               ||  -- ヘッダ金額
                     ' 明細金額合計:' || main_rec.sale_amount_sum_l                                 -- 明細金額合計
        );
      ELSE
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '販売実績ヘッダの成績者コードが従業員マスタに存在しません。'               ||
                     ' 販売実績ID:'   || main_rec.sales_exp_header_id                           ||  -- 販売実績ID
                     ' 顧客コード:'   || main_rec.ship_to_customer_code                         ||  -- 顧客コード
                     ' 納品日:'       || main_rec.delivery_date                                 ||  -- 納品日
                     ' 成績者コード:' || main_rec.results_employee_code                             -- 成績者コード
        );
      END IF;
    END LOOP;
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
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
    errbuf                OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode               OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_process_date       IN  VARCHAR2      --   業務日付
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
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
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
       iv_process_date                             -- 業務日付
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP001A02C;
/