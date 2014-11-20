CREATE OR REPLACE PACKAGE BODY XXCOK014A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A03C(body)
 * Description      : 販手残高計算処理
 * MD.050           : 販売手数料（自販機）の支払予定額（未払残高）を計算 MD050_COK_014_A03
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  update_bm_bal_resv     販手残高保留データの更新(A-12)
 *  update_cond_bm_support 販手残高登録結果データの更新（A-11）
 *  insert_bm_bal          販手残高計算結果データの登録(A-10)
 *  delete_bm_bal_last     販手残高前回処理データの削除(A-9)
 *  get_bm_calc_end_date   販手残高計算終了日の取得(A-8)
 *  get_cond_bm_support    販手残高計算データの取得(A-7)
 *  set_bm_bal_resv        販手残高保留情報の退避(A-6)
 *  update_bm_resv_init    販手残高保留情報の初期化(A-5)
 *  get_bm_calc_start_date 販手残高計算開始日の取得(A-4)
 *  get_bm_bal_resv        販手残高保留データの取得(A-3)
 *  delete_bm_period_out   販手残高保持期間外データの削除(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   A.Yano           新規作成
 *  2009/02/17    1.1   T.Abe            [障害COK_041] 販手残高計算データの取得件数が0件の場合、正常終了するように修正
 *  2009/03/25    1.2   S.Kayahara       最終行にスラッシュ追加
 *  2009/05/28    1.3   M.Hiruta         [障害T1_1138] 販手残高保留情報の初期化で正しく保留情報を初期化できるよう変更
 *
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20)  := 'XXCOK014A03C';
  -- ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- 異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;         -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;         -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id; -- PROGRAM_ID
  -- セパレータ
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1)   := '.';
  -- アプリケーション短縮名
  cv_app_name_ccp           CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_app_name_cok           CONSTANT VARCHAR2(5)   := 'XXCOK';
  -- メッセージ
  cv_msg_xxccp_90000        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';         -- 対象件数メッセージ
  cv_msg_xxccp_90001        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';         -- 成功件数メッセージ
  cv_msg_xxccp_90002        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';         -- エラー件数メッセージ
  cv_msg_xxccp_90004        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';         -- 正常終了メッセージ
  cv_msg_xxccp_90006        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';         -- エラー終了全ロールバック
  cv_msg_xxcok_00003        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00003';         -- プロファイル取得エラー
  cv_msg_xxcok_00022        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00022';         -- コンカレント入力パラメータ
  cv_msg_xxcok_00027        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00027';         -- 営業日取得エラー
  cv_msg_xxcok_00028        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00028';         -- 業務処理日付取得エラー
  cv_msg_xxcok_00051        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00051';         -- 条件別販手販協登録結果ロックエラー
  cv_msg_xxcok_10296        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10296';         -- 販手残高保持期間外情報ロックエラー
  cv_msg_xxcok_10297        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10297';         -- 販手残高保持期間外情報削除エラー
  cv_msg_xxcok_10298        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10298';         -- 販手残高前回保留情報ロックエラー
  cv_msg_xxcok_10299        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10299';         -- 販手残高前回保留情報更新エラー
  cv_msg_xxcok_10300        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10300';         -- 販手残高計算情報取得エラー
  cv_msg_xxcok_10301        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10301';         -- 販手残高前回処理情報ロックエラー
  cv_msg_xxcok_10302        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10302';         -- 販手残高前回処理情報削除エラー
  cv_msg_xxcok_10303        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10303';         -- 販手残高計算結果登録エラー
  cv_msg_xxcok_10305        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10305';         -- 条件別販手販協登録結果更新エラー
  cv_msg_xxcok_10306        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10306';         -- 販手残高保留情報ロックエラー
  cv_msg_xxcok_10307        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10307';         -- 販手残高保留情報更新エラー
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  cv_msg_xxcok_10454        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10454';         -- 締め・支払日取得エラー
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- トークン
  cv_tkn_count              CONSTANT VARCHAR2(10)  := 'COUNT';                    -- 件数メッセージ用
  cv_tkn_profile_name       CONSTANT VARCHAR2(10)  := 'PROFILE';                  -- プロファイル名
  cv_tkn_business_date      CONSTANT VARCHAR2(20)  := 'BUSINESS_DATE';            -- 業務処理日付
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  cv_tkn_cust_code          CONSTANT VARCHAR2(10)  := 'CUST_CODE';                -- 顧客コード
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- プロファイル名
  -- XXCOK:条件別販手販協計算処理期間（From）
  cv_bm_support_period_from CONSTANT VARCHAR2(30)  := 'XXCOK1_BM_SUPPORT_PERIOD_FROM';
  -- XXCOK:条件別販手販協計算処理期間（To）
  cv_bm_support_period_to   CONSTANT VARCHAR2(30)  := 'XXCOK1_BM_SUPPORT_PERIOD_TO';
  -- XXCOK:販手販協計算結果保持期間
  cv_sales_retention_period CONSTANT VARCHAR2(30)  := 'XXCOK1_SALES_RETENTION_PERIOD';
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- XXCOK:支払条件_デフォルト
  cv_default_term_name      CONSTANT VARCHAR2(30)  := 'XXCOK1_DEFAULT_TERM_NAME';
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- 連携ステータス
  cv_interface_status_0     CONSTANT VARCHAR2(1)   := '0';                        -- 未処理
  cv_interface_status_1     CONSTANT VARCHAR2(1)   := '1';                        -- 処理済
  -- フラグ
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                        -- 保留
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';                        -- 保留解除
  -- 処理区分
  cn_proc_type              CONSTANT NUMBER        := 1;                          -- 前
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  cn_proc_type_after        CONSTANT NUMBER        := 2;                          -- 後
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- 販手残高テーブル登録データ
  cn_payment_amt_tax        CONSTANT NUMBER        := 0;                          -- 支払額（税込）
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- 契約管理情報
  cv_status_1               CONSTANT VARCHAR2(1)   := '1';                        -- 確定
  -- 支払条件用区切文字
  cv_underbar               CONSTANT VARCHAR2(1)   := '_';                        -- アンダーバー
  -- 支払条件_支払月_契約管理抽出値
  cv_term_this_month        CONSTANT VARCHAR2(2)   := '40';                       -- 当月
  cv_term_next_month        CONSTANT VARCHAR2(2)   := '50';                       -- 翌月
  -- 支払条件_支払月_契約管理変換後
  cv_term_this_month_concat CONSTANT VARCHAR2(2)   := '00';                       -- 当月
  cv_term_next_month_concat CONSTANT VARCHAR2(2)   := '01';                       -- 翌月
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_target_cnt               NUMBER   DEFAULT 0;     -- 対象件数
  gn_normal_cnt               NUMBER   DEFAULT 0;     -- 正常件数
  gn_error_cnt                NUMBER   DEFAULT 0;     -- エラー件数
  gn_warn_cnt                 NUMBER   DEFAULT 0;     -- スキップ件数
  gd_process_date             DATE     DEFAULT NULL;  -- 業務処理日付
  gd_bm_hold_period_date      DATE     DEFAULT NULL;  -- 販手販協保持期限日
  -- プロファイル値
  gn_bm_support_period_from   NUMBER   DEFAULT NULL;  -- 条件別販手販協計算処理期間（From）
  gn_bm_support_period_to     NUMBER   DEFAULT NULL;  -- 条件別販手販協計算処理期間（To）
  gn_sales_retention_period   NUMBER   DEFAULT NULL;  -- 販手販協計算結果保持期間
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  gv_default_term_name        VARCHAR2(10) DEFAULT NULL;  -- 支払条件_デフォルト
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- ===============================
  -- グローバルカーソル
  -- ===============================
  -- 販手残高保留データ
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--  CURSOR g_bm_bal_resv_cur
  CURSOR g_bm_bal_resv_cur (
         iv_cust_code IN xxcok_backmargin_balance.cust_code%TYPE -- 顧客コード
         )
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  IS
    SELECT  xbb.base_code              AS base_code              -- 拠点コード
           ,xbb.supplier_code          AS supplier_code          -- 仕入先コード
           ,xbb.supplier_site_code     AS supplier_site_code     -- 仕入先サイトコード
           ,xbb.cust_code              AS cust_code              -- 顧客コード
           ,xbb.closing_date           AS closing_date           -- 締め日
           ,xbb.selling_amt_tax        AS selling_amt_tax        -- 販売金額（税込）
           ,xbb.backmargin             AS backmargin             -- 販売手数料（税抜）
           ,xbb.backmargin_tax         AS backmargin_tax         -- 販売手数料（消費税額）
           ,xbb.electric_amt           AS electric_amt           -- 電気料（税抜）
           ,xbb.electric_amt_tax       AS electric_amt_tax       -- 電気料（消費税額）
           ,xbb.tax_code               AS tax_code               -- 税金コード
           ,xbb.expect_payment_date    AS expect_payment_date    -- 支払予定日
           ,xbb.expect_payment_amt_tax AS expect_payment_amt_tax -- 支払予定額（税込）
           ,xbb.payment_amt_tax        AS payment_amt_tax        -- 支払額（税込）
           ,xbb.resv_flag              AS resv_flag              -- 保留フラグ
           ,xbb.return_flag            AS return_flag            -- 組み戻しフラグ
           ,xbb.publication_date       AS publication_date       -- 案内書発効日
           ,xbb.fb_interface_status    AS fb_interface_status    -- 連携ステータス（本振用FB）
           ,xbb.fb_interface_date      AS fb_interface_date      -- 連携日（本振用FB）
           ,xbb.edi_interface_status   AS edi_interface_status   -- 連携ステータス（EDI支払案内書）
           ,xbb.edi_interface_date     AS edi_interface_date     -- 連携日（EDI支払案内書）
           ,xbb.gl_interface_status    AS gl_interface_status    -- 連携ステータス（GL）
           ,xbb.gl_interface_date      AS gl_interface_date      -- 連携日（GL）
    FROM    xxcok_backmargin_balance  xbb
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--    WHERE  ( ( xbb.resv_flag   = cv_flag_y )
--           OR( xbb.return_flag = cv_flag_y ) )
    WHERE  xbb.cust_code = iv_cust_code
    AND    ( ( xbb.resv_flag   = cv_flag_y )
           OR( xbb.return_flag = cv_flag_y ) )
  ;
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--
  -- 販手残高計算データ
  CURSOR g_cond_bm_cur
  IS
    SELECT xcbs.base_code                            AS base_code           -- 拠点コード
          ,xcbs.supplier_code                        AS supplier_code       -- 仕入先コード
          ,xcbs.supplier_site_code                   AS supplier_site_code  -- 仕入先サイトコード
          ,xcbs.delivery_cust_code                   AS delivery_cust_code  -- 顧客コード(納品先)
          ,xcbs.closing_date                         AS closing_date        -- 締め日
          ,xcbs.expect_payment_date                  AS expect_payment_date -- 支払予定日
          ,xcbs.tax_code                             AS tax_code            -- 税金コード
          ,SUM( xcbs.selling_amt_tax )               AS selling_amt_tax     -- 売上金額（税込）
          ,SUM( NVL( xcbs.cond_bm_amt_no_tax , 0 ) ) AS cond_bm_amt         -- 条件別手数料額（税抜）
          ,SUM( NVL( xcbs.cond_tax_amt       , 0 ) ) AS cond_tax_amt        -- 条件別消費税額
          ,SUM( NVL( xcbs.electric_amt_no_tax, 0 ) ) AS electric_amt        -- 電気料(税抜)
          ,SUM( NVL( xcbs.electric_tax_amt   , 0 ) ) AS electric_tax_amt    -- 電気料消費税額
    FROM   xxcok_cond_bm_support xcbs
    WHERE  xcbs.bm_interface_status = cv_interface_status_0
    GROUP BY xcbs.base_code
            ,xcbs.supplier_code
            ,xcbs.supplier_site_code
            ,xcbs.delivery_cust_code
            ,xcbs.closing_date
            ,xcbs.expect_payment_date
            ,xcbs.tax_code
  ;
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- 契約管理テーブル情報取得ループ
  CURSOR g_managements_cur
  IS
    SELECT xcm.install_account_number AS cust_code           -- 設置先顧客コード
          ,xcm.close_day_code         AS close_day_code      -- 締め日
          ,xcm.transfer_day_code      AS transfer_day_code   -- 支払日
          ,xcm.transfer_month_code    AS transfer_month_code -- 支払月
    FROM   xxcso_contract_managements xcm
          ,(
           SELECT MAX( xcm_2.contract_number ) AS contract_number -- 契約書番号
                 ,xcm_2.install_account_id     AS cust_id         -- 設置先顧客ID
           FROM   xxcso_contract_managements xcm_2 -- 契約管理テーブル
           WHERE  xcm_2.status = cv_status_1 -- 確定済
           AND EXISTS (
                      SELECT 'X'
                      FROM   xxcok_backmargin_balance xbb
                            ,hz_cust_accounts         hca
                      WHERE  xbb.cust_code       = hca.account_number
                      AND    hca.cust_account_id = xcm_2.install_account_id
                      AND    ( ( xbb.resv_flag   = cv_flag_y )
                             OR( xbb.return_flag = cv_flag_y ) )
                      )
           GROUP BY
                  xcm_2.install_account_id
           ) xcm_max
    WHERE  xcm.contract_number    = xcm_max.contract_number
    AND    xcm.install_account_id = xcm_max.cust_id
    AND    xcm.status             = cv_status_1 -- 確定済
  ;
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- ===============================
  -- グローバルTABLE型
  -- ===============================
  -- 販手残高保留情報
  TYPE g_bm_bal_resv_ttype IS TABLE OF g_bm_bal_resv_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  -- ===============================
  -- グローバルPL/SQL表
  -- ===============================
  -- 販手残高保留情報
  g_bm_bal_resv_tab    g_bm_bal_resv_ttype;
  -- ===============================
  -- 例外
  -- ===============================
  --*** 処理部共通例外 ***
  global_process_expt         EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt             EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION;
--
  no_data_expt                EXCEPTION;    -- データ取得例外
  operating_day_expt          EXCEPTION;    -- 営業日取得例外
  lock_expt                   EXCEPTION;    -- ロック取得例外
  status_warn_expt            EXCEPTION;    -- 警告例外
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : update_bm_bal_resv
   * Description      : 販手残高保留データの更新(A-12)
   ***********************************************************************************/
  PROCEDURE update_bm_bal_resv(
     ov_errbuf          OUT VARCHAR2        -- エラー・メッセージ
    ,ov_retcode         OUT VARCHAR2        -- リターン・コード
    ,ov_errmsg          OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(20) := 'update_bm_bal_resv'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    ln_index                  NUMBER         DEFAULT 0;                    -- インデックス
    -- *** ローカルカーソル ***
    -- 販手残高テーブルロック取得
    CURSOR l_bm_update_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_backmargin_balance xbb
      WHERE  xbb.base_code           =  g_bm_bal_resv_tab( ln_index ).base_code
      AND    xbb.supplier_code       =  g_bm_bal_resv_tab( ln_index ).supplier_code
      AND    xbb.supplier_site_code  =  g_bm_bal_resv_tab( ln_index ).supplier_site_code
      AND    xbb.cust_code           =  g_bm_bal_resv_tab( ln_index ).cust_code
      AND    xbb.closing_date        =  g_bm_bal_resv_tab( ln_index ).closing_date
      AND    xbb.expect_payment_date =  g_bm_bal_resv_tab( ln_index ).expect_payment_date
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    <<update_loop>>
    FOR i IN g_bm_bal_resv_tab.FIRST .. g_bm_bal_resv_tab.LAST LOOP
      -- ===============================================
      -- 販手残高テーブルのロック取得
      -- ===============================================
      OPEN  l_bm_update_lock_cur;
      CLOSE l_bm_update_lock_cur;
--
      BEGIN
        -- ===============================================
        -- 販手残高保留データの更新
        -- ===============================================
        UPDATE xxcok_backmargin_balance
        SET    resv_flag              = g_bm_bal_resv_tab( ln_index ).resv_flag    -- 保留フラグ
              ,return_flag            = g_bm_bal_resv_tab( ln_index ).return_flag  -- 組み戻しフラグ
              ,last_updated_by        = cn_last_updated_by
              ,last_update_date       = SYSDATE
              ,last_update_login      = cn_last_update_login
              ,request_id             = cn_request_id
              ,program_application_id = cn_program_application_id
              ,program_id             = cn_program_id
              ,program_update_date    = SYSDATE
        WHERE  base_code           =  g_bm_bal_resv_tab( ln_index ).base_code
        AND    supplier_code       =  g_bm_bal_resv_tab( ln_index ).supplier_code
        AND    supplier_site_code  =  g_bm_bal_resv_tab( ln_index ).supplier_site_code
        AND    cust_code           =  g_bm_bal_resv_tab( ln_index ).cust_code
        AND    closing_date        =  g_bm_bal_resv_tab( ln_index ).closing_date
        AND    expect_payment_date =  g_bm_bal_resv_tab( ln_index ).expect_payment_date
        ;
--
      EXCEPTION
        -- *** 販手残高保留情報更新例外ハンドラ ***
        WHEN OTHERS THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name_cok
                          ,iv_name         => cv_msg_xxcok_10307
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           FND_FILE.OUTPUT
                          ,lv_out_msg
                          ,0
                        );
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
          ov_retcode := cv_status_error;
      END;
      ln_index := ln_index + 1;
--
    END LOOP update_loop;
--
  EXCEPTION
    -- *** 販手残高保留情報ロック例外ハンドラ ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_10306
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END update_bm_bal_resv;
--
  /**********************************************************************************
   * Procedure Name   : update_cond_bm_support
   * Description      : 販手残高登録結果データの更新（A-11）
   ***********************************************************************************/
  PROCEDURE update_cond_bm_support(
     ov_errbuf               OUT VARCHAR2                                       -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2                                       -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2                                       -- ユーザー・エラー・メッセージ
    ,it_base_code            IN  xxcok_cond_bm_support.base_code%TYPE           -- 販手残高計算データ.拠点コード
    ,it_supplier_code        IN  xxcok_cond_bm_support.supplier_code%TYPE       -- 販手残高計算データ.仕入先コード
    ,it_supplier_site_code   IN  xxcok_cond_bm_support.supplier_site_code%TYPE  -- 販手残高計算データ.仕入先サイトコード
    ,it_delivery_cust_code   IN  xxcok_cond_bm_support.delivery_cust_code%TYPE  -- 販手残高計算データ.顧客コード
    ,it_closing_date         IN  xxcok_cond_bm_support.closing_date%TYPE        -- 販手残高計算データ.締め日
    ,it_expect_payment_date  IN  xxcok_cond_bm_support.expect_payment_date%TYPE -- 販手残高保留データ.支払予定日
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'update_cond_bm_support'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    -- *** ローカルカーソル ***
    -- 条件別販手販協テーブルロック取得
    CURSOR l_cond_bm_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_cond_bm_support xcbs
      WHERE  xcbs.base_code            =  it_base_code
      AND    xcbs.supplier_code        =  it_supplier_code
      AND    xcbs.supplier_site_code   =  it_supplier_site_code
      AND    xcbs.delivery_cust_code   =  it_delivery_cust_code
      AND    xcbs.closing_date         =  it_closing_date
      AND    xcbs.expect_payment_date  =  it_expect_payment_date
      AND    xcbs.bm_interface_status  =  cv_interface_status_0
      FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 条件別販手販協テーブルのロックを取得
    -- ===============================================
    OPEN  l_cond_bm_lock_cur;
    CLOSE l_cond_bm_lock_cur;
--
    BEGIN
      -- ===============================================
      -- 条件別販手販協テーブルの更新
      -- ===============================================
      UPDATE xxcok_cond_bm_support
      SET    bm_interface_status    = cv_interface_status_1    -- 連携ステータス（販手残高）
            ,bm_interface_date      = gd_process_date          -- 連携日（販手残高）
            ,last_updated_by        = cn_last_updated_by
            ,last_update_date       = SYSDATE
            ,last_update_login      = cn_last_update_login
            ,request_id             = cn_request_id
            ,program_application_id = cn_program_application_id
            ,program_id             = cn_program_id
            ,program_update_date    = SYSDATE
      WHERE  base_code            =  it_base_code
      AND    supplier_code        =  it_supplier_code
      AND    supplier_site_code   =  it_supplier_site_code
      AND    delivery_cust_code   =  it_delivery_cust_code
      AND    closing_date         =  it_closing_date
      AND    expect_payment_date  =  it_expect_payment_date
      AND    bm_interface_status  =  cv_interface_status_0
      ;
--
    EXCEPTION
      -- *** 条件別販手販協登録結果更新例外ハンドラ ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10305
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** 条件別販手販協登録結果ロック例外ハンドラ ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_00051
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END update_cond_bm_support;
--
  /**********************************************************************************
   * Procedure Name   : insert_bm_bal
   * Description      : 販手残高計算結果データの登録(A-10)
   ***********************************************************************************/
  PROCEDURE insert_bm_bal(
     ov_errbuf          OUT VARCHAR2                   -- エラー・メッセージ
    ,ov_retcode         OUT VARCHAR2                   -- リターン・コード
    ,ov_errmsg          OUT VARCHAR2                   -- ユーザー・エラー・メッセージ
    ,i_cond_bm_rec      IN  g_cond_bm_cur%ROWTYPE      -- 販手残高計算データ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(15) := 'insert_bm_bal'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;              -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数の戻り値
    lt_expect_payment_amt_tax xxcok_backmargin_balance.expect_payment_amt_tax%TYPE DEFAULT 0;  -- 支払予定額
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- 支払予定額（税込）
    lt_expect_payment_amt_tax := i_cond_bm_rec.cond_bm_amt  + i_cond_bm_rec.cond_tax_amt +
                                 i_cond_bm_rec.electric_amt + i_cond_bm_rec.electric_tax_amt;
    BEGIN
      -- ===============================================
      -- 販手残高計算結果データの登録
      -- ===============================================
      INSERT INTO xxcok_backmargin_balance(
         bm_balance_id                -- 販手残高ID
        ,base_code                    -- 拠点コード
        ,supplier_code                -- 仕入先コード
        ,supplier_site_code           -- 仕入先サイトコード
        ,cust_code                    -- 顧客コード
        ,closing_date                 -- 締め日
        ,selling_amt_tax              -- 販売金額（税込）
        ,backmargin                   -- 販売手数料
        ,backmargin_tax               -- 販売手数料（消費税額）
        ,electric_amt                 -- 電気料
        ,electric_amt_tax             -- 電気料（消費税額）
        ,tax_code                     -- 税金コード
        ,expect_payment_date          -- 支払予定日
        ,expect_payment_amt_tax       -- 支払予定額（税込）
        ,payment_amt_tax              -- 支払額（税込）
        ,resv_flag                    -- 保留フラグ
        ,return_flag                  -- 組み戻しフラグ
        ,publication_date             -- 案内書発効日
        ,fb_interface_status          -- 連携ステータス（本振用FB）
        ,fb_interface_date            -- 連携日（本振用FB）
        ,edi_interface_status         -- 連携ステータス（EDI支払案内書）
        ,edi_interface_date           -- 連携日（EDI支払案内書）
        ,gl_interface_status          -- 連携ステータス（GL）
        ,gl_interface_date            -- 連携日（GL）
        -- WHOカラム
        ,created_by                   -- 作成者
        ,creation_date                -- 作成日
        ,last_updated_by              -- 最終更新者
        ,last_update_date             -- 最終更新日
        ,last_update_login            -- 最終更新ログイン
        ,request_id                   -- 要求ID
        ,program_application_id       -- コンカレント・プログラム・アプリケーションID
        ,program_id                   -- コンカレント・プログラムID
        ,program_update_date          -- プログラム更新日
      ) VALUES (
         xxcok_backmargin_balance_s01.NEXTVAL   -- 販手残高ID
        ,i_cond_bm_rec.base_code                -- 拠点コード
        ,i_cond_bm_rec.supplier_code            -- 仕入先コード
        ,i_cond_bm_rec.supplier_site_code       -- 仕入先サイトコード
        ,i_cond_bm_rec.delivery_cust_code       -- 顧客コード
        ,i_cond_bm_rec.closing_date             -- 締め日
        ,i_cond_bm_rec.selling_amt_tax          -- 販売金額（税込）
        ,i_cond_bm_rec.cond_bm_amt              -- 販売手数料
        ,i_cond_bm_rec.cond_tax_amt             -- 販売手数料（消費税額）
        ,i_cond_bm_rec.electric_amt             -- 電気料
        ,i_cond_bm_rec.electric_tax_amt         -- 電気料（消費税額）
        ,i_cond_bm_rec.tax_code                 -- 税金コード
        ,i_cond_bm_rec.expect_payment_date      -- 支払予定日
        ,lt_expect_payment_amt_tax              -- 支払予定額（税込）
        ,cn_payment_amt_tax                     -- 支払額（税込）
        ,NULL                                   -- 保留フラグ
        ,NULL                                   -- 組み戻しフラグ
        ,NULL                                   -- 案内書発効日
        ,cv_interface_status_0                  -- 連携ステータス（本振用FB）
        ,NULL                                   -- 連携日（本振用FB）
        ,cv_interface_status_0                  -- 連携ステータス（EDI支払案内書）
        ,NULL                                   -- 連携日（EDI支払案内書）
        ,cv_interface_status_0                  -- 連携ステータス（GL）
        ,NULL                                   -- 連携日（GL）
        -- WHOカラム
        ,cn_created_by                          -- 作成者
        ,SYSDATE                                -- 作成日
        ,cn_last_updated_by                     -- 最終更新者
        ,SYSDATE                                -- 最終更新日
        ,cn_last_update_login                   -- 最終更新ログイン
        ,cn_request_id                          -- 要求ID
        ,cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id                          -- コンカレント・プログラムID
        ,SYSDATE                                -- プログラム更新日
      );
--
    EXCEPTION
      -- *** 販手残高計算結果登録例外ハンドラ ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10303
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END insert_bm_bal;
--
  /**********************************************************************************
   * Procedure Name   : delete_bm_bal_last
   * Description      : 販手残高前回処理データの削除(A-9)
   ***********************************************************************************/
  PROCEDURE delete_bm_bal_last(
     ov_errbuf              OUT VARCHAR2                                       -- エラー・メッセージ
    ,ov_retcode             OUT VARCHAR2                                       -- リターン・コード
    ,ov_errmsg              OUT VARCHAR2                                       -- ユーザー・エラー・メッセージ
    ,it_base_code           IN  xxcok_cond_bm_support.base_code%TYPE           -- 拠点コード
    ,it_supplier_code       IN  xxcok_cond_bm_support.supplier_code%TYPE       -- 仕入先コード
    ,it_supplier_site_code  IN  xxcok_cond_bm_support.supplier_site_code%TYPE  -- 仕入先サイトコード
    ,it_delivery_cust_code  IN  xxcok_cond_bm_support.delivery_cust_code%TYPE  -- 顧客コード
    ,it_closing_date        IN  xxcok_cond_bm_support.closing_date%TYPE        -- 締め日
    ,it_expect_payment_date IN  xxcok_cond_bm_support.expect_payment_date%TYPE -- 支払予定日
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(20) := 'delete_bm_bal_last'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    -- *** ローカルカーソル ***
    -- 販手残高テーブルロック取得
    CURSOR l_delete_bm_last_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_backmargin_balance xbb
      WHERE  xbb.base_code           =  it_base_code
      AND    xbb.supplier_code       =  it_supplier_code
      AND    xbb.supplier_site_code  =  it_supplier_site_code
      AND    xbb.cust_code           =  it_delivery_cust_code
      AND    xbb.closing_date        =  it_closing_date
      AND    xbb.expect_payment_date =  it_expect_payment_date
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高テーブルのロック取得
    -- ===============================================
    OPEN  l_delete_bm_last_lock_cur;
    CLOSE l_delete_bm_last_lock_cur;
--
    BEGIN
      -- ===============================================
      -- 販手残高前回処理データの削除
      -- ===============================================
      DELETE FROM xxcok_backmargin_balance
      WHERE  base_code           =  it_base_code
      AND    supplier_code       =  it_supplier_code
      AND    supplier_site_code  =  it_supplier_site_code
      AND    cust_code           =  it_delivery_cust_code
      AND    closing_date        =  it_closing_date
      AND    expect_payment_date =  it_expect_payment_date
      ;
--
    EXCEPTION
      -- *** 販手残高前回処理情報削除例外ハンドラ ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10302
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** 販手残高前回処理情報ロック例外ハンドラ ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_10301
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END delete_bm_bal_last;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_calc_end_date
   * Description      : 販手残高計算終了日の取得(A-8)
   ***********************************************************************************/
  PROCEDURE get_bm_calc_end_date(
     ov_errbuf          OUT VARCHAR2                                   -- エラー・メッセージ
    ,ov_retcode         OUT VARCHAR2                                   -- リターン・コード
    ,ov_errmsg          OUT VARCHAR2                                   -- ユーザー・エラー・メッセージ
    ,it_closing_date    IN  xxcok_cond_bm_support.closing_date%TYPE    -- 販手残高計算データ.締め日
    ,od_calc_end_date   OUT DATE                                       -- 販手残高計算終了日（営業日）
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'get_bm_calc_end_date'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    ld_operating_day          DATE           DEFAULT NULL;                 -- 販手残高計算終了日（営業日）
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高計算終了日の取得
    -- ===============================================
    ld_operating_day := xxcok_common_pkg.get_operating_day_f(
                           it_closing_date           -- 処理日
                          ,gn_bm_support_period_to   -- 日数
                          ,cn_proc_type              -- 処理区分
                        );
    IF( ld_operating_day IS NULL ) THEN
      RAISE operating_day_expt;
    END IF;
    -- ===============================================
    -- OUTパラメータ設定
    -- ===============================================
    od_calc_end_date := ld_operating_day;   -- 販手残高計算終了日（営業日）
--
  EXCEPTION
    -- *** 営業日取得例外ハンドラ ***
    WHEN operating_day_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_00027
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_bm_calc_end_date;
--
  /**********************************************************************************
   * Procedure Name   : get_cond_bm_support
   * Description      : 販手残高計算データの取得(A-7)
   ***********************************************************************************/
  PROCEDURE get_cond_bm_support(
     ov_errbuf            OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode           OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg            OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'get_cond_bm_support'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    ld_calc_end_date          DATE           DEFAULT NULL;                 -- 販手残高計算終了日
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高計算データの取得
    -- ===============================================
    <<main_loop>>
    FOR l_cond_bm_rec IN g_cond_bm_cur LOOP
--
      -- 対象件数
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================================
      -- 販手残高計算終了日の取得(A-8)
      -- ===============================================
      get_bm_calc_end_date(
         ov_errbuf               =>   lv_errbuf                      -- エラー・メッセージ
        ,ov_retcode              =>   lv_retcode                     -- リターン・コード
        ,ov_errmsg               =>   lv_errmsg                      -- ユーザー・エラー・メッセージ
        ,it_closing_date         =>   l_cond_bm_rec.closing_date     -- 販手残高計算データ.締め日
        ,od_calc_end_date        =>   ld_calc_end_date               -- 販手残高計算終了日（営業日）
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- 販手残高前回処理データの削除(A-9)
      -- ===============================================
      delete_bm_bal_last(
         ov_errbuf                =>   lv_errbuf                         -- エラー・メッセージ
        ,ov_retcode               =>   lv_retcode                        -- リターン・コード
        ,ov_errmsg                =>   lv_errmsg                         -- ユーザー・エラー・メッセージ
        ,it_base_code             =>   l_cond_bm_rec.base_code           -- 拠点コード
        ,it_supplier_code         =>   l_cond_bm_rec.supplier_code       -- 仕入先コード
        ,it_supplier_site_code    =>   l_cond_bm_rec.supplier_site_code  -- 仕入先サイトコード
        ,it_delivery_cust_code    =>   l_cond_bm_rec.delivery_cust_code  -- 顧客コード
        ,it_closing_date          =>   l_cond_bm_rec.closing_date        -- 締め日
        ,it_expect_payment_date   =>   l_cond_bm_rec.expect_payment_date -- 支払予定日
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- 販手残高計算結果データの登録(A-10)
      -- ===============================================
      insert_bm_bal(
         ov_errbuf                =>   lv_errbuf               -- エラー・メッセージ
        ,ov_retcode               =>   lv_retcode              -- リターン・コード
        ,ov_errmsg                =>   lv_errmsg               -- ユーザー・エラー・メッセージ
        ,i_cond_bm_rec            =>   l_cond_bm_rec           -- 販手残高計算データ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 正常件数
      gn_normal_cnt := gn_normal_cnt + 1;
--
      -- ===============================================
      -- 業務処理日付と販手残高計算終了日が一致する場合
      -- ===============================================
      IF( gd_process_date = ld_calc_end_date ) THEN
        -- ===============================================
        -- 販手残高登録結果データの更新(A-11)
        -- ===============================================
        update_cond_bm_support(
           ov_errbuf                =>   lv_errbuf                         -- エラー・メッセージ
          ,ov_retcode               =>   lv_retcode                        -- リターン・コード
          ,ov_errmsg                =>   lv_errmsg                         -- ユーザー・エラー・メッセージ
          ,it_base_code             =>   l_cond_bm_rec.base_code           -- 拠点コード
          ,it_supplier_code         =>   l_cond_bm_rec.supplier_code       -- 仕入先コード
          ,it_supplier_site_code    =>   l_cond_bm_rec.supplier_site_code  -- 仕入先サイトコード
          ,it_delivery_cust_code    =>   l_cond_bm_rec.delivery_cust_code  -- 顧客コード
          ,it_closing_date          =>   l_cond_bm_rec.closing_date        -- 締め日
          ,it_expect_payment_date   =>   l_cond_bm_rec.expect_payment_date -- 支払予定日
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP main_loop;
    -- ===============================================
    -- 対象件数が0件の場合
    -- ===============================================
    IF( gn_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
  EXCEPTION
    WHEN no_data_expt THEN
      -- *** 販手残高計算情報取得例外ハンドラ ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_10300
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_warn;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_cond_bm_support;
--
  /**********************************************************************************
   * Procedure Name   : set_bm_bal_resv
   * Description      : 販手残高保留情報の退避(A-6)
   ***********************************************************************************/
  PROCEDURE set_bm_bal_resv(
     ov_errbuf            OUT VARCHAR2                   -- エラー・メッセージ
    ,ov_retcode           OUT VARCHAR2                   -- リターン・コード
    ,ov_errmsg            OUT VARCHAR2                   -- ユーザー・エラー・メッセージ
    ,i_bm_bal_resv_rec    IN  g_bm_bal_resv_cur%ROWTYPE  -- 販手残高保留データ
    ,in_index             IN  NUMBER                     -- インデックス
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(20) := 'set_bm_bal_resv'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高保留情報の退避
    -- ===============================================
    g_bm_bal_resv_tab( in_index ) := i_bm_bal_resv_rec;
--
  EXCEPTION
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END set_bm_bal_resv;
--
  /**********************************************************************************
   * Procedure Name   : update_bm_resv_init
   * Description      : 販手残高保留情報の初期化（A-5）
   ***********************************************************************************/
  PROCEDURE update_bm_resv_init(
     ov_errbuf              OUT VARCHAR2                                          -- エラー・メッセージ
    ,ov_retcode             OUT VARCHAR2                                          -- リターン・コード
    ,ov_errmsg              OUT VARCHAR2                                          -- ユーザー・エラー・メッセージ
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    ,it_cust_code           IN  xxcok_backmargin_balance.cust_code%TYPE           -- 販手残高保留.顧客コード
--    ,it_base_code           IN  xxcok_backmargin_balance.base_code%TYPE           -- 販手残高保留.拠点コード
--    ,it_supplier_code       IN  xxcok_backmargin_balance.supplier_code%TYPE       -- 販手残高保留.仕入先コード
--    ,it_supplier_site_code  IN  xxcok_backmargin_balance.supplier_site_code%TYPE  -- 販手残高保留.仕入先サイトコード
--    ,it_expect_payment_date IN  xxcok_backmargin_balance.expect_payment_date%TYPE -- 販手残高保留.支払予定日
--    ,it_resv_flag           IN  xxcok_backmargin_balance.resv_flag%TYPE           -- 販手残高保留.保留フラグ
--    ,it_return_flag         IN  xxcok_backmargin_balance.return_flag%TYPE         -- 販手残高保留.組み戻しフラグ
--    ,id_calc_start_date     IN  DATE                                              -- 販手残高計算開始日（営業日）
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'update_bm_resv_init'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    -- *** ローカルカーソル ***
    -- 販手残高テーブルロック取得
    CURSOR l_bm_init_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_backmargin_balance xbb
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--      WHERE  xbb.base_code            =  it_base_code
--      AND    xbb.supplier_code        =  it_supplier_code
--      AND    xbb.supplier_site_code   =  it_supplier_site_code
--      AND    xbb.cust_code            =  it_cust_code
--      AND    xbb.closing_date         <  id_calc_start_date
--      AND    xbb.expect_payment_date  =  it_expect_payment_date
--      AND    ( ( xbb.resv_flag        =  it_resv_flag   )
--             OR( xbb.return_flag      =  it_return_flag ) )
      WHERE  xbb.cust_code    = it_cust_code
      AND    ( ( xbb.resv_flag   = cv_flag_y )
             OR( xbb.return_flag = cv_flag_y ) )
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高テーブルのロックを取得
    -- ===============================================
    OPEN  l_bm_init_lock_cur;
    CLOSE l_bm_init_lock_cur;
--
    BEGIN
      -- ===============================================
      -- 販手残高テーブルの更新（初期化）
      -- ===============================================
      UPDATE xxcok_backmargin_balance
      SET    resv_flag              = NULL        -- 保留フラグ
            ,last_updated_by        = cn_last_updated_by
            ,last_update_date       = SYSDATE
            ,last_update_login      = cn_last_update_login
            ,request_id             = cn_request_id
            ,program_application_id = cn_program_application_id
            ,program_id             = cn_program_id
            ,program_update_date    = SYSDATE
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--      WHERE  base_code            =  it_base_code
--      AND    supplier_code        =  it_supplier_code
--      AND    supplier_site_code   =  it_supplier_site_code
--      AND    cust_code            =  it_cust_code
--      AND    closing_date         <  id_calc_start_date
--      AND    expect_payment_date  =  it_expect_payment_date
--      AND    ( ( resv_flag        =  it_resv_flag   )
--             OR( return_flag      =  it_return_flag ) )
      WHERE  cust_code            =  it_cust_code
      AND    ( ( resv_flag   = cv_flag_y )
             OR( return_flag = cv_flag_y ) )
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
      ;
--
    EXCEPTION
      -- *** 販手残高前回保留情報更新例外ハンドラ ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10299
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** 販手残高前回保留情報ロック例外ハンドラ ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_10298
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END update_bm_resv_init;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_calc_start_date
   * Description      : 販手残高計算開始日の取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_bm_calc_start_date(
     ov_errbuf          OUT VARCHAR2                                   -- エラー・メッセージ
    ,ov_retcode         OUT VARCHAR2                                   -- リターン・コード
    ,ov_errmsg          OUT VARCHAR2                                   -- ユーザー・エラー・メッセージ
    ,it_closing_date    IN  xxcok_backmargin_balance.closing_date%TYPE -- 販手残高保留データ.締め日
    ,od_calc_start_date OUT DATE                                       -- 販手残高計算開始日（営業日）
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'get_bm_calc_start_date'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    ld_operating_day          DATE           DEFAULT NULL;                 -- 販手残高計算開始日（営業日）
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高計算開始日の取得
    -- ===============================================
    ld_operating_day := xxcok_common_pkg.get_operating_day_f(
                           it_closing_date              -- 処理日
                          ,gn_bm_support_period_from    -- 日数
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--                          ,cn_proc_type                 -- 処理区分
                          ,cn_proc_type_after           -- 処理区分
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
                        );
    IF( ld_operating_day IS NULL ) THEN
      RAISE operating_day_expt;
    END IF;
    -- ===============================================
    -- OUTパラメータ設定
    -- ===============================================
    od_calc_start_date := ld_operating_day;   -- 販手残高計算開始日（営業日）
--
  EXCEPTION
    -- *** 営業日取得例外ハンドラ ***
    WHEN operating_day_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_00027
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_bm_calc_start_date;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_bal_resv
   * Description      : 販手残高保留データの取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_bm_bal_resv(
     ov_errbuf             OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode            OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg             OUT VARCHAR2      -- ユーザー・エラー・メッセージ
    ,ov_resv_update_flag   OUT VARCHAR2      -- 販手残高保留情報の初期化済フラグ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(20) := 'get_bm_bal_resv';  -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    ld_calc_start_date        DATE           DEFAULT NULL;                 -- 販手残高計算開始日（営業日）
    ln_index                  NUMBER         DEFAULT 0;                    -- インデックス
    lv_resv_update_flag       VARCHAR2(1)    DEFAULT cv_flag_y;            -- 販手残高保留データ更新フラグ
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    lv_pay_cond               VARCHAR2(10)   DEFAULT NULL;                 -- 支払条件
    lv_term_month             VARCHAR2(2)    DEFAULT NULL;                 -- 支払条件_支払月
    ld_close_date             DATE           DEFAULT NULL;                 -- 締め日
    ld_pay_date               DATE           DEFAULT NULL;                 -- 支払日（取得するだけで未使用）
    -- *** ローカル例外 ***
    close_date_err_expt       EXCEPTION;                                   -- 締め・支払日取得取得エラー
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--    -- ===============================================
--    -- 販手残高保留データの取得
--    -- ===============================================
--    <<bm_bal_resv_loop>>
--    FOR l_bm_bal_resv_rec IN g_bm_bal_resv_cur LOOP
--      -- ===============================================
--      -- 販手残高計算開始日の取得（A-4）
--      -- ===============================================
--      get_bm_calc_start_date(
--         ov_errbuf          =>   lv_errbuf                      -- エラー・メッセージ
--        ,ov_retcode         =>   lv_retcode                     -- リターン・コード
--        ,ov_errmsg          =>   lv_errmsg                      -- ユーザー・エラー・メッセージ
--        ,it_closing_date    =>   l_bm_bal_resv_rec.closing_date -- 販手残高保留データ.締め日
--        ,od_calc_start_date =>   ld_calc_start_date             -- 販手残高計算開始日（営業日）
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
----
--      -- ===============================================
--      -- 業務処理日付と販手残高計算開始日が一致した場合
--      -- ===============================================
--      IF( gd_process_date = ld_calc_start_date ) THEN
--        -- ===============================================
--        -- 販手残高保留情報の初期化（A-5）
--        -- ===============================================
--        update_bm_resv_init(
--           ov_errbuf                =>   lv_errbuf                             -- エラー・メッセージ
--          ,ov_retcode               =>   lv_retcode                            -- リターン・コード
--          ,ov_errmsg                =>   lv_errmsg                             -- ユーザー・エラー・メッセージ
--          ,it_base_code             =>   l_bm_bal_resv_rec.base_code           -- 販手残高保留データ.拠点コード
--          ,it_supplier_code         =>   l_bm_bal_resv_rec.supplier_code       -- 販手残高保留データ.仕入先コード
--          ,it_supplier_site_code    =>   l_bm_bal_resv_rec.supplier_site_code  -- 販手残高保留データ.仕入先サイトコード
--          ,it_cust_code             =>   l_bm_bal_resv_rec.cust_code           -- 販手残高保留データ.顧客コード
--          ,it_expect_payment_date   =>   l_bm_bal_resv_rec.expect_payment_date -- 販手残高保留データ.支払予定日
--          ,it_resv_flag             =>   l_bm_bal_resv_rec.resv_flag           -- 販手残高保留データ.保留フラグ
--          ,it_return_flag           =>   l_bm_bal_resv_rec.return_flag         -- 販手残高保留データ.組み戻しフラグ
--          ,id_calc_start_date       =>   ld_calc_start_date                    -- 販手残高計算開始日（営業日）
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        -- ===============================================
--        -- 販手残高保留情報の初期化をした場合
--        -- ===============================================
--        lv_resv_update_flag := cv_flag_n;
----
--      -- ===============================================
--      -- 業務処理日付と販手残高計算開始日が一致しない場合
--      -- ===============================================
--      ELSE
--        -- ===============================================
--        -- 販手残高保留情報の退避（A-6）
--        -- ===============================================
--        set_bm_bal_resv(
--           ov_errbuf                =>   lv_errbuf             -- エラー・メッセージ
--          ,ov_retcode               =>   lv_retcode            -- リターン・コード
--          ,ov_errmsg                =>   lv_errmsg             -- ユーザー・エラー・メッセージ
--          ,i_bm_bal_resv_rec        =>   l_bm_bal_resv_rec     -- 販手残高保留データ
--          ,in_index                 =>   ln_index              -- インデックス
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        ln_index := ln_index + 1;
--      END IF;
----
--    END LOOP bm_bal_resv_loop;
--
    -- ===============================================
    -- 契約管理テーブル情報の取得
    -- ===============================================
    <<managements_loop>>
    FOR l_managements_rec IN g_managements_cur LOOP
      -- ===============================================
      -- 支払条件チェック
      -- ===============================================
      -- 契約管理テーブル情報から取得した支払条件「締め日」「支払日」「支払月」のいずれかがNULLである場合、
      -- 締め日取得時にデフォルト値を使用する。
      IF ( ( l_managements_rec.close_day_code      IS NULL ) OR
           ( l_managements_rec.transfer_day_code   IS NULL ) OR
           ( l_managements_rec.transfer_month_code IS NULL ) )
      THEN
        lv_pay_cond := gv_default_term_name;
      ELSE
        -- 取得した支払月を変換する。
        IF ( l_managements_rec.transfer_month_code = cv_term_this_month ) THEN
          lv_term_month := cv_term_this_month_concat; -- 当月
        ELSE
          lv_term_month := cv_term_next_month_concat; -- 翌月
        END IF;
--
        lv_pay_cond := l_managements_rec.close_day_code      || cv_underbar ||
                       l_managements_rec.transfer_day_code   || cv_underbar ||
                       lv_term_month;
      END IF;
      -- ===============================================
      -- 締め日取得
      -- ===============================================
      xxcok_common_pkg.get_close_date_p(
         ov_errbuf     => lv_errbuf                                 -- エラーメッセージ
        ,ov_retcode    => lv_retcode                                -- リターン・コード
        ,ov_errmsg     => lv_errmsg                                 -- ユーザー・エラーメッセージ
        ,id_proc_date  => gd_process_date - gn_bm_support_period_to -- 処理日
        ,iv_pay_cond   => lv_pay_cond                               -- 支払条件
        ,od_close_date => ld_close_date                             -- 締め日
        ,od_pay_date   => ld_pay_date                               -- 支払日
      );
      IF( lv_retcode = cv_status_error ) THEN
        -- メッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10454
                        ,iv_token_name1  => cv_tkn_cust_code
                        ,iv_token_value1 => l_managements_rec.cust_code
                      );
        RAISE close_date_err_expt;
      END IF;
--
      -- ===============================================
      -- 販手残高計算開始日の取得（A-4）
      -- ===============================================
      get_bm_calc_start_date(
         ov_errbuf          => lv_errbuf          -- エラー・メッセージ
        ,ov_retcode         => lv_retcode         -- リターン・コード
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ
        ,it_closing_date    => ld_close_date      -- 販手残高保留データ.締め日
        ,od_calc_start_date => ld_calc_start_date -- 販手残高計算開始日（営業日）
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- 業務処理日付と販手残高計算開始日が一致した場合
      -- ===============================================
      IF( gd_process_date = ld_calc_start_date ) THEN
        -- ===============================================
        -- 販手残高保留情報の初期化（A-5）
        -- ===============================================
        update_bm_resv_init(
           ov_errbuf          => lv_errbuf                   -- エラー・メッセージ
          ,ov_retcode         => lv_retcode                  -- リターン・コード
          ,ov_errmsg          => lv_errmsg                   -- ユーザー・エラー・メッセージ
          ,it_cust_code       => l_managements_rec.cust_code -- 契約管理テーブル情報.顧客コード
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================================
        -- 販手残高保留情報の初期化をした場合
        -- ===============================================
        lv_resv_update_flag := cv_flag_n;
--
      -- ===============================================
      -- 業務処理日付と販手残高計算開始日が一致しない場合
      -- ===============================================
      ELSE
        -- ===============================================
        -- 販手残高保留情報の退避（A-6）
        -- ===============================================
        <<bm_bal_resv_loop>>
        FOR l_bm_bal_resv_rec IN g_bm_bal_resv_cur (
                                    iv_cust_code => l_managements_rec.cust_code -- 顧客コード
                                 )
        LOOP
          set_bm_bal_resv(
             ov_errbuf          => lv_errbuf             -- エラー・メッセージ
            ,ov_retcode         => lv_retcode            -- リターン・コード
            ,ov_errmsg          => lv_errmsg             -- ユーザー・エラー・メッセージ
            ,i_bm_bal_resv_rec  => l_bm_bal_resv_rec     -- 販手残高保留データ
            ,in_index           => ln_index              -- インデックス
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          ln_index := ln_index + 1;
        END LOOP bm_bal_resv_loop;
      END IF;
    END LOOP managements_loop;
--
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    -- ===============================================
    -- OUTパラメータ設定
    -- ===============================================
    ov_resv_update_flag := lv_resv_update_flag;
--
  EXCEPTION
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    -- *** 締め・支払日取得取得例外ハンドラ ***
    WHEN close_date_err_expt THEN
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT -- 出力区分
                      ,lv_out_msg      -- メッセージ
                      ,0               -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_bm_bal_resv;
--
  /**********************************************************************************
   * Procedure Name   : delete_bm_period_out
   * Description      : 販手残高保持期間外データの削除(A-2)
   ***********************************************************************************/
  PROCEDURE delete_bm_period_out(
     ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'delete_bm_period_out'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    -- *** ローカルカーソル ***
    -- 販手残高テーブルロック取得
    CURSOR l_bm_delete_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_backmargin_balance xbb
      WHERE  xbb.closing_date         <  gd_bm_hold_period_date
      AND    xbb.publication_date     IS NOT NULL
      AND    xbb.fb_interface_status  <> cv_interface_status_0
      AND    xbb.gl_interface_status  <> cv_interface_status_0
      AND    xbb.edi_interface_status <> cv_interface_status_0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高テーブルのロックを取得する
    -- ===============================================
    OPEN  l_bm_delete_lock_cur;
    CLOSE l_bm_delete_lock_cur;
--
    BEGIN
      -- ===============================================
      -- 販手残高保持期間外データの削除
      -- ===============================================
      DELETE FROM xxcok_backmargin_balance
      WHERE  closing_date         <  gd_bm_hold_period_date
      AND    publication_date     IS NOT NULL
      AND    fb_interface_status  <> cv_interface_status_0
      AND    gl_interface_status  <> cv_interface_status_0
      AND    edi_interface_status <> cv_interface_status_0
      ;
--
    EXCEPTION
      -- *** 販手残高保持期間外情報削除例外ハンドラ ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10297
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** 販手残高保持期間外情報ロック例外ハンドラ ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_10296
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END delete_bm_period_out;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf        OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode       OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2      -- ユーザー・エラー・メッセージ
    ,iv_process_date  IN  VARCHAR2      -- 業務処理日付
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name                CONSTANT VARCHAR2(5)  := 'init';            -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                -- ユーザー・エラー・メッセージ
    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                -- 出力メッセージ
    lb_retcode                 BOOLEAN        DEFAULT TRUE;                -- メッセージ出力関数の戻り値
    lv_nodata_profile          VARCHAR2(30)   DEFAULT NULL;                -- 未取得のプロファイル名
    -- *** ローカル例外 ***
    nodata_profile_expt        EXCEPTION;         -- プロファイル値取得例外
    process_date_expt          EXCEPTION;         -- 業務処理日付取得例外
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 1. パラメータ出力
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_cok
                    ,iv_name         => cv_msg_xxcok_00022
                    ,iv_token_name1  => cv_tkn_business_date
                    ,iv_token_value1 => iv_process_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.LOG
                    ,lv_out_msg
                    ,2
                  );
--
    BEGIN
      -- ===============================================
      -- 2. パラメータに業務処理日付が設定されている場合、
      --    日付型に変換
      -- ===============================================
      IF( iv_process_date IS NOT NULL ) THEN
        gd_process_date := FND_DATE.CANONICAL_TO_DATE( iv_process_date );
      ELSE
        -- ===============================================
        -- 3. パラメータに業務処理日付が設定されていない場合、
        --    業務処理日付を取得
        -- ===============================================
        gd_process_date := xxccp_common_pkg2.get_process_date;
        IF( gd_process_date IS NULL ) THEN
          RAISE process_date_expt;
        END IF;
      END IF;
--
    EXCEPTION
      -- *** 業務処理日付取得例外ハンドラ ***
      WHEN OTHERS THEN
        lv_out_msg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_00028
                       );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        RAISE process_date_expt;
    END;
--
    -- ===============================================
    -- 4. プロファイル：条件別販手販協計算処理期間（From）を取得
    -- ===============================================
    gn_bm_support_period_from := TO_NUMBER( FND_PROFILE.VALUE( cv_bm_support_period_from ) );
    IF( gn_bm_support_period_from IS NULL ) THEN
      lv_nodata_profile := cv_bm_support_period_from;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ===============================================
    -- 5. プロファイル：条件別販手販協計算処理期間（To）を取得
    -- ===============================================
    gn_bm_support_period_to := TO_NUMBER( FND_PROFILE.VALUE( cv_bm_support_period_to ) );
    IF( gn_bm_support_period_to IS NULL ) THEN
      lv_nodata_profile := cv_bm_support_period_to;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ===============================================
    -- 6. プロファイル：販手販協計算結果保持期間を取得
    -- ===============================================
    gn_sales_retention_period := TO_NUMBER( FND_PROFILE.VALUE( cv_sales_retention_period ) );
    IF( gn_sales_retention_period IS NULL ) THEN
      lv_nodata_profile := cv_sales_retention_period;
      RAISE nodata_profile_expt;
    END IF;
--
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    -- ===============================================
    -- 7. プロファイル：支払条件_デフォルトを取得
    -- ===============================================
    gv_default_term_name := FND_PROFILE.VALUE( cv_default_term_name );
    IF( gv_default_term_name IS NULL ) THEN
      lv_nodata_profile := cv_default_term_name;
      RAISE nodata_profile_expt;
    END IF;
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--
    -- ===============================================
    -- 8. 販手販協保持期限日を取得
    -- ===============================================
    gd_bm_hold_period_date := ADD_MONTHS( TRUNC( gd_process_date, 'MM' ), -gn_sales_retention_period );
--
  EXCEPTION
    -- *** プロファイル取得例外ハンドラ ****
    WHEN nodata_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_00003
                      ,iv_token_name1  => cv_tkn_profile_name
                      ,iv_token_value1 => lv_nodata_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 業務処理日付取得例外ハンドラ ***
    WHEN process_date_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf        OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode       OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2      -- ユーザー・エラー・メッセージ
    ,iv_process_date  IN  VARCHAR2      -- 業務処理日付
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(10) := 'submain'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000)  DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)     DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000)  DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000)  DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN         DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    lv_resv_update_flag       VARCHAR2(1)     DEFAULT cv_flag_y;            -- 販手残高保留データ更新フラグ
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- グローバル変数の初期化
    -- ===============================================
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
       ov_errbuf        =>   lv_errbuf         -- エラー・メッセージ
      ,ov_retcode       =>   lv_retcode        -- リターン・コード
      ,ov_errmsg        =>   lv_errmsg         -- ユーザー・エラー・メッセージ
      ,iv_process_date  =>   iv_process_date   -- 業務処理日付
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 販手残高保持期間外データの削除(A-2)
    -- ===============================================
    delete_bm_period_out(
       ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ
      ,ov_retcode    =>    lv_retcode     -- リターン・コード
      ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 販手残高保留データの取得(A-3)
    -- ===============================================
    get_bm_bal_resv(
       ov_errbuf             =>    lv_errbuf            -- エラー・メッセージ
      ,ov_retcode            =>    lv_retcode           -- リターン・コード
      ,ov_errmsg             =>    lv_errmsg            -- ユーザー・エラー・メッセージ
      ,ov_resv_update_flag   =>    lv_resv_update_flag  -- 販手残高保留データ更新フラグ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 販手残高計算データの取得(A-7)
    -- ===============================================
    get_cond_bm_support(
       ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ
      ,ov_retcode    =>    lv_retcode     -- リターン・コード
      ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      RAISE status_warn_expt;
    END IF;
--
    -- ===============================================
    -- 販手残高保留データ更新フラグがY（保留）かつ
    -- 販手残高保留データがある場合
    -- ===============================================
    IF(  ( lv_resv_update_flag     = cv_flag_y )
      AND( g_bm_bal_resv_tab.COUNT > 0         ) )
    THEN
      -- ===============================================
      -- 販手残高保留データの更新(A-12)
      -- ===============================================
      update_bm_bal_resv(
         ov_errbuf     =>   lv_errbuf        -- エラー・メッセージ
        ,ov_retcode    =>   lv_retcode       -- リターン・コード
        ,ov_errmsg     =>   lv_errmsg        -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** 警告処理ハンドラ ***
    WHEN status_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_normal;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf          OUT    VARCHAR2       -- エラー・メッセージ
    ,retcode         OUT    VARCHAR2       -- リターン・コード
    ,iv_process_date IN     VARCHAR2       -- 業務処理日付
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name        CONSTANT VARCHAR2(5)   := 'main';           -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf          VARCHAR2(5000)  DEFAULT NULL;               -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)     DEFAULT cv_status_normal;   -- リターン・コード
    lv_errmsg          VARCHAR2(5000)  DEFAULT NULL;               -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100)   DEFAULT NULL;               -- 終了メッセージ
    lv_out_msg         VARCHAR2(2000)  DEFAULT NULL;               -- 出力メッセージ
    lb_retcode         BOOLEAN         DEFAULT TRUE;               -- メッセージ出力関数の戻り値
--
  BEGIN
--
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf        =>    lv_errbuf        -- エラー・メッセージ
      ,ov_retcode       =>    lv_retcode       -- リターン・コード
      ,ov_errmsg        =>    lv_errmsg        -- ユーザー・エラー・メッセージ
      ,iv_process_date  =>    iv_process_date  -- 業務処理日付
    );
    -- ===============================================
    -- エラー出力
    -- ===============================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_errmsg  --ユーザー・エラー・メッセージ
                      ,1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.LOG
                      ,lv_errbuf  --エラーメッセージ
                      ,1
                    );
    END IF;
    -- ===============================================
    -- 異常終了の場合の件数セット
    -- ===============================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    -- ===============================================
    -- 対象件数出力
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_xxccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
    -- ===============================================
    -- 成功件数出力
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_xxccp_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
    -- ===============================================
    -- エラー件数出力
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_xxccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
    -- ===============================================
    -- 終了メッセージ
    -- ===============================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp_90004;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_msg_xxccp_90006;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
    -- ===============================================
    -- ステータスセット
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- 終了ステータスがエラーの場合はROLLBACKする
    -- ===============================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK014A03C;
/
