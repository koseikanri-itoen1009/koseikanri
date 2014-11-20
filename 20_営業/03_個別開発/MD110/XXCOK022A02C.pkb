CREATE OR REPLACE PACKAGE BODY XXCOK022A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK022A02C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : アドオン：販手販協予算データファイル作成 販売物流 MD050_COK_022_A02
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  open_file_p            ファイルオープン(A-2)
 *  create_flat_file_p     フラットファイル作成(A-4)/連携済データステータス更新(A-5)
 *  close_file_p           ファイルクローズ(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/20    1.0   K.Suenaga        新規作成
 *  2009/02/05    1.1   K.Suenaga        [障害COK_010]ディレクトリパスの出力方法を変更
 *  2009/07/13    1.2   K.Yamaguchi      [障害0000294]パフォーマンス改善
 *  2010/07/29    1.3   S.Arizumi        [E_本稼動_03332]仕様変更（機能の見直し）
 *
 *****************************************************************************************/
  -- ===============================
  -- グローバル定数
  -- ===============================
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE  
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
  --記号
  cv_msg_double             CONSTANT VARCHAR2(1)    := '"';                          -- ダブルコーテーション
  cv_msg_comma              CONSTANT VARCHAR2(1)    := ',';                          -- カンマ
  cv_slash                  CONSTANT VARCHAR2(1)    := '/';                          -- スラッシュ
  cv_msg_part               CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)    := '.';
  --パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(100)  := 'XXCOK022A02C';               -- パッケージ名
  --アプリケーション短縮名
  cv_appli_xxccp_name       CONSTANT VARCHAR2(10)   := 'XXCCP';                      -- アプリケーション短縮名
  cv_appli_xxcok_name       CONSTANT VARCHAR2(10)   := 'XXCOK';                      -- アプリケーション短縮名
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  cv_appli_sqlgl_name       CONSTANT VARCHAR2(10)   := 'SQLGL';                      -- アプリケーション短縮名
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
  --メッセージ
  cv_concurrent_msg         CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90008';           -- コンカレント入力パラメータなし
  cv_profile_msg            CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-00003';           -- プロファイル取得エラー
  cv_dire_name_msg          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00067';           -- ディレクトリ名メッセージ出力
  cv_file_name_msg          CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-00006';           -- ファイル名メッセージ出力
  cv_close_status_msg       CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-00057';           -- オープン会計期間取得エラー
  cv_effective_msg          CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-00059';           -- 有効会計期間取得エラー
  cv_file_err_msg           CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-00009';           -- ファイル存在チェックエラー
  cv_lock_err_msg           CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-10178';           -- ロックエラーメッセージ
  cv_status_err_msg         CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-10180';           -- 連携済データステータス更新エラー
  cv_target_rec_msg         CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90000';           -- 対象件数メッセージ
  cv_success_rec_msg        CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90001';           -- 成功件数メッセージ
  cv_error_rec_msg          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90002';           -- エラー件数メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90004';           -- 正常終了メッセージ
  cv_error_msg              CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90006';           -- エラー終了全ロールバック
  --トークン
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  cv_company_token          CONSTANT VARCHAR2(100)  := 'COMPANY_CODE';               -- 会社コード
--  cv_budget_token           CONSTANT VARCHAR2(100)  := 'BUDGET_YEAR';                -- 予算年度
--  cv_location_token         CONSTANT VARCHAR2(100)  := 'LOCATION_CODE';              -- 拠点コード
--  cv_corporate_token        CONSTANT VARCHAR2(100)  := 'CORPORATE_CODE';             -- 企業コード
--  cv_store_token            CONSTANT VARCHAR2(100)  := 'STORE_CODE';                 -- 問屋帳合先コード
--  cv_account_token          CONSTANT VARCHAR2(100)  := 'ACCOUNT_CODE';               -- 勘定科目コード
--  cv_sub_token              CONSTANT VARCHAR2(100)  := 'SUB_CODE';                   -- 補助科目コード
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
  cv_profile_token          CONSTANT VARCHAR2(100)  := 'PROFILE';                    -- プロファイル名
  cv_dire_name_token        CONSTANT VARCHAR2(15)   := 'DIRECTORY';                  -- ディレクトリ名
  cv_file_token             CONSTANT VARCHAR2(100)  := 'FILE_NAME';                  -- ファイル名
  cv_cnt_token              CONSTANT VARCHAR2(10)   := 'COUNT';                      -- 件数メッセージ用トークン名
  --プロファイル
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  cv_set_of_bks_id          CONSTANT VARCHAR2(100)  := 'GL_SET_OF_BKS_ID';           -- 会計帳簿ID
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
  cv_bm_dire_path           CONSTANT VARCHAR2(100)  := 'XXCOK1_BM_BUDGET_DIRE_PATH'; -- 販手販協予算ディレクトリパス
  cv_bm_file_name           CONSTANT VARCHAR2(100)  := 'XXCOK1_BM_BUDGET_FILE_NAME'; -- 販手販協予算ファイル名
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  --フラグ
--  cv_adjustment_flag        CONSTANT VARCHAR2(1)    := 'N';                          -- 調整フラグ
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
  --ステータス
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  cv_open_status            CONSTANT VARCHAR2(1)    := 'O';                          -- ステータス
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
  cv_unsettled_status       CONSTANT VARCHAR2(1)    := '0';                          -- ステータス(情報系連携未済)
  cv_settled_status         CONSTANT VARCHAR2(1)    := '1';                          -- ステータス(情報系連携済)
--
  cv_open_mode              CONSTANT VARCHAR2(1)    := 'w';
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_target_cnt           NUMBER             DEFAULT NULL;   -- 対象件数
  gn_normal_cnt           NUMBER             DEFAULT NULL;   -- 正常件数
  gn_error_cnt            NUMBER             DEFAULT NULL;   -- エラー件数
  gn_warn_cnt             NUMBER             DEFAULT NULL;   -- スキップ件数
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  gv_set_of_bks_id        VARCHAR2(100)      DEFAULT NULL;   -- 会計帳簿ID変数
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
  gv_bm_dire_path         VARCHAR2(100)      DEFAULT NULL;   -- 販手販協ディレクトリパス変数
  gv_bm_file_name         VARCHAR2(100)      DEFAULT NULL;   -- 販手販協ファイル名変数
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  gn_account_year         NUMBER             DEFAULT NULL;   -- オープン会計年数変数
--  gn_target_account_year  NUMBER             DEFAULT NULL;   -- 処理対象会計年度変数
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
  g_open_file             UTL_FILE.FILE_TYPE DEFAULT NULL;   -- オープンファイルハンドルの変数
  gd_system_date          DATE               DEFAULT NULL;   -- システム日付の変数
  -- ===============================
  -- グローバルカーソル
  -- ===============================
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi REPAIR START
--  CURSOR g_bm_support_budget_cur
--  IS
--    SELECT xbsb.bm_support_budget_id AS bm_support_budget_id -- 販手販協予算ID
--         , xbsb.company_code         AS company_code         -- 会社コード
--         , xbsb.budget_year          AS budget_year          -- 予算年度
--         , xbsb.base_code            AS base_code            -- 拠点コード
--         , xbsb.corp_code            AS corp_code            -- 企業コード
--         , xbsb.sales_outlets_code   AS sales_outlets_code   -- 問屋帳合先コード
--         , xbsb.acct_code            AS acct_code            -- 勘定科目コード
--         , xbsb.sub_acct_code        AS sub_acct_code        -- 補助科目コード
--         , xbsb.target_month         AS target_month         -- 月度
--         , xbsb.budget_amt           AS budget_amt           -- 予算金額
--    FROM   xxcok_bm_support_budget      xbsb                 -- 販手販協予算テーブル
--    WHERE  xbsb.budget_year           = gn_target_account_year
--    AND    xbsb.info_interface_status = cv_unsettled_status;
  CURSOR g_bm_support_budget_cur
  IS
    SELECT xbsb.bm_support_budget_id AS bm_support_budget_id -- 販手販協予算ID
         , xbsb.company_code         AS company_code         -- 会社コード
         , xbsb.budget_year          AS budget_year          -- 予算年度
         , xbsb.base_code            AS base_code            -- 拠点コード
         , xbsb.corp_code            AS corp_code            -- 企業コード
         , xbsb.sales_outlets_code   AS sales_outlets_code   -- 問屋帳合先コード
         , xbsb.acct_code            AS acct_code            -- 勘定科目コード
         , xbsb.sub_acct_code        AS sub_acct_code        -- 補助科目コード
         , xbsb.target_month         AS target_month         -- 月度
         , xbsb.budget_amt           AS budget_amt           -- 予算金額
    FROM   xxcok_bm_support_budget      xbsb                 -- 販手販協予算テーブル
    WHERE  xbsb.info_interface_status = cv_unsettled_status
    FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT
  ;
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi REPAIR END
--
-- 2009/07/13 Ver.1.2 [障害0000294] SCS K.Yamaguchi DELETE START
--  TYPE g_bm_support_budget_ttype IS TABLE OF g_bm_support_budget_cur%ROWTYPE;
--  g_bm_support_budget_tab g_bm_support_budget_ttype;
-- 2009/07/13 Ver.1.2 [障害0000294] SCS K.Yamaguchi DELETE END
  -- ===============================
  -- グローバル例外
  -- ===============================
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
  --*** ロックエラー ***
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2                         -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                         -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                         -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;   -- エラー・メッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;   -- リターン・コード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;   -- ユーザー・エラー・メッセージ
    lb_retcode       BOOLEAN        DEFAULT NULL;   -- メッセージ出力関数の戻り値
    lv_out_msg       VARCHAR2(5000) DEFAULT NULL;   -- メッセージ出力変数
    lv_profile       VARCHAR2(100)  DEFAULT NULL;   -- プロファイル格納変数
    -- ===============================
    -- ローカル例外
    -- ===============================
    profile_expt     EXCEPTION;                     -- プロファイル取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --コンカレント入力パラメータなし項目をメッセージ出力
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_concurrent_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 1                  -- 改行
                  );
        lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.LOG       -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 1                  -- 改行
                  );
    --==============================================================
    --システム日付を取得
    --==============================================================
    gd_system_date := SYSDATE;
    --==============================================================
    --プロファイルを取得
    --==============================================================
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--    gv_set_of_bks_id := FND_PROFILE.VALUE( cv_set_of_bks_id ); -- 会計帳簿ID
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
    gv_bm_dire_path  := FND_PROFILE.VALUE( cv_bm_dire_path  ); -- 販手販協ディレクトリパス
    gv_bm_file_name  := FND_PROFILE.VALUE( cv_bm_file_name  ); -- 販手販協ファイル名
--
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--    IF( gv_set_of_bks_id IS NULL ) THEN
--      lv_profile := cv_set_of_bks_id;
--      RAISE profile_expt;
--    END IF;
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
--
    IF( gv_bm_dire_path IS NULL ) THEN
      lv_profile := cv_bm_dire_path;
      RAISE profile_expt;
    END IF;
--
    IF( gv_bm_file_name IS NULL ) THEN
      lv_profile := cv_bm_file_name;
      RAISE profile_expt;
    END IF;
    --===============================================================
    --ディレクトリ名・ファイル名をメッセージ出力
    --===============================================================
    lv_out_msg   := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_dire_name_msg
                    , cv_dire_name_token
                    , xxcok_common_pkg.get_directory_path_f( gv_bm_dire_path )
                    );
    lb_retcode   := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
    lv_out_msg   := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_file_name_msg
                    , cv_file_token
                    , gv_bm_file_name
                    );
    lb_retcode   := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 1                  -- 改行
                    );
--
  EXCEPTION
    -- *** プロファイル取得エラー ***
    WHEN profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_profile_msg
                    , cv_profile_token
                    , lv_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--  /**********************************************************************************
--   * Procedure Name   : get_target_account_p
--   * Description      : 処理対象会計年度取得(A-2)
--   ***********************************************************************************/
--  PROCEDURE get_target_account_p(
--    ov_errbuf  OUT VARCHAR2                                            -- エラー・メッセージ
--  , ov_retcode OUT VARCHAR2                                            -- リターン・コード
--  , ov_errmsg  OUT VARCHAR2                                            -- ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_account_p'; -- プログラム名
--    -- ===============================
--    -- ローカル変数
--    -- ===============================
--    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                            -- エラー・メッセージ
--    lv_retcode VARCHAR2(1)    DEFAULT NULL;                            -- リターン・コード
--    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                            -- ユーザー・エラー・メッセージ
--    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                            -- メッセージ出力変数
--    lb_retcode BOOLEAN        DEFAULT NULL;                            -- メッセージ出力関数の戻り値
--    -- ===============================
--    -- ローカル例外
--    -- ===============================
--    close_status_expt EXCEPTION;                                       -- オープン会計年度取得エラー
--    effective_expt    EXCEPTION;                                       -- 有効会計期間取得エラー
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    --==============================================================
--    --会計年数を取得
--    --==============================================================
--    SELECT COUNT(*)
--    INTO   gn_account_year
--    FROM(
--      SELECT   gps.period_year                                   -- オープン会計年数
--      FROM     gl_period_statuses           gps
--             , fnd_application              fa
--      WHERE    gps.application_id         = fa.application_id
--      AND      gps.set_of_books_id        = gv_set_of_bks_id
--      AND      fa.application_short_name  = cv_appli_sqlgl_name
--      AND      gps.adjustment_period_flag = cv_adjustment_flag
--      AND      gps.closing_status         = cv_open_status
--      GROUP BY gps.period_year
--    );
--    --==============================================================
--    --会計年数が1の場合、オープンしている会計年度の翌年を処理対象とする
--    --==============================================================
--    IF( gn_account_year = 1 ) THEN
--      SELECT   gps.period_year + 1                               -- 処理対象会計年度
--      INTO     gn_target_account_year
--      FROM     gl_period_statuses           gps
--             , fnd_application              fa
--      WHERE    gps.application_id         = fa.application_id
--      AND      gps.set_of_books_id        = gv_set_of_bks_id
--      AND      fa.application_short_name  = cv_appli_sqlgl_name
--      AND      gps.adjustment_period_flag = cv_adjustment_flag
--      AND      gps.closing_status         = cv_open_status
--      GROUP BY gps.period_year;
--    --==============================================================
--    --会計年数が2の場合、大きい方の年度を処理対象とする
--    --==============================================================
--    ELSIF( gn_account_year = 2 ) THEN
--      SELECT MAX( period_year )
--      INTO   gn_target_account_year
--      FROM( 
--        SELECT   gps.period_year                                 -- 処理対象会計年度
--        FROM     gl_period_statuses           gps
--               , fnd_application              fa
--        WHERE    gps.application_id         = fa.application_id
--        AND      gps.set_of_books_id        = gv_set_of_bks_id
--        AND      fa.application_short_name  = cv_appli_sqlgl_name
--        AND      gps.adjustment_period_flag = cv_adjustment_flag
--        AND      gps.closing_status         = cv_open_status
--        GROUP BY gps.period_year
--      );
--    --==============================================================
--    --会計期間のステータスがオープンしていない時、エラーとして処理
--    --==============================================================
--    ELSIF( gn_account_year = 0 ) THEN
--      RAISE close_status_expt;
--    --==============================================================
--    --会計年数が上記以外の場合、エラーとして処理
--    --==============================================================
--    ELSE
--      RAISE effective_expt;
--    END IF;
----
--  EXCEPTION
--    -- *** オープン会計期間取得エラー ***
--    WHEN close_status_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                      cv_appli_xxcok_name
--                    , cv_close_status_msg
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f( 
--                      FND_FILE.OUTPUT    -- 出力区分
--                    , lv_out_msg         -- メッセージ
--                    , 0                  -- 改行
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 有効会計期間取得エラー ***
--    WHEN effective_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                      cv_appli_xxcok_name
--                    , cv_effective_msg
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f( 
--                      FND_FILE.OUTPUT    -- 出力区分
--                    , lv_out_msg         -- メッセージ
--                    , 0                  -- 改行
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END get_target_account_p;
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--
  /**********************************************************************************
   * Procedure Name   : open_file_p
   * Description      : ファイルオープン(A-2)
   ***********************************************************************************/
  PROCEDURE open_file_p(
    ov_errbuf  OUT VARCHAR2                                -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_file_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;            -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT NULL;            -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;            -- ユーザー・エラー・メッセージ
    lv_out_msg     VARCHAR2(5000) DEFAULT NULL;            -- メッセージ出力変数
    lb_retcode     BOOLEAN        DEFAULT NULL;            -- メッセージ出力関数の戻り値
    lb_fexists     BOOLEAN        DEFAULT NULL;            -- BOOLEANの変数
    ln_file_length NUMBER         DEFAULT NULL;            -- ファイルの長さ変数
    ln_block_size  NUMBER         DEFAULT NULL;            -- ブロックサイズ変数
    -- ===============================
    -- ローカル例外
    -- ===============================
    file_expt      EXCEPTION;                              -- ファイル存在チェックエラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    --=============================================================
    --ファイルの存在チェック
    --=============================================================
    UTL_FILE.FGETATTR(
      location    =>  gv_bm_dire_path                      -- ディレクトリパス
    , filename    =>  gv_bm_file_name                      -- ファイル名
    , fexists     =>  lb_fexists                           -- ファイルの存在
    , file_length =>  ln_file_length                       -- ファイルの長さ
    , block_size  =>  ln_block_size                        -- ブロックサイズ
    );
--
    IF( lb_fexists = TRUE ) THEN
    -- *** ファイル存在チェックエラー ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_file_err_msg
                    , cv_file_token
                    , gv_bm_file_name
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      RAISE global_api_expt;
    END IF;
    --=============================================================
    --ファイルのオープン
    --=============================================================
    g_open_file := UTL_FILE.FOPEN(
                     gv_bm_dire_path                       -- ディレクトリパス
                   , gv_bm_file_name                       -- ファイル名
                   , cv_open_mode                          -- モード
                   , cn_max_linesize                       -- 最大文字数
                   );
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf ,1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END open_file_p;
--
-- 2009/07/13 Ver.1.2 [障害0000294] SCS K.Yamaguchi DELETE START
--  /**********************************************************************************
--   * Procedure Name   : get_budget_info_p
--   * Description      : 連携対象販手販協予算情報取得(A-4)
--   ***********************************************************************************/
--  PROCEDURE get_budget_info_p(
--    ov_errbuf  OUT VARCHAR2                                      -- エラー・メッセージ
--  , ov_retcode OUT VARCHAR2                                      -- リターン・コード
--  , ov_errmsg  OUT VARCHAR2                                      -- ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_budget_info_p'; -- プログラム名
--    -- ===============================
--    -- ローカル変数
--    -- ===============================
--    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                      -- エラー・メッセージ
--    lv_retcode VARCHAR2(1)    DEFAULT NULL;                      -- リターン・コード
--    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                      -- ユーザー・エラー・メッセージ
--    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                      -- メッセージ出力変数
--    lb_retcode BOOLEAN        DEFAULT NULL;                      -- メッセージ出力関数の戻り値
----
--  BEGIN
--    ov_retcode := cv_status_normal;
----
--    OPEN  g_bm_support_budget_cur;
--    FETCH g_bm_support_budget_cur BULK COLLECT INTO g_bm_support_budget_tab;
--    CLOSE g_bm_support_budget_cur;
--    --==============================================================
--    --対象件数カウント
--    --==============================================================
--    gn_target_cnt := g_bm_support_budget_tab.COUNT;
----
--  EXCEPTION
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END get_budget_info_p;
----
-- 2009/07/13 Ver.1.2 [障害0000294] SCS K.Yamaguchi DELETE END
  /**********************************************************************************
   * Procedure Name   : create_flat_file_p
   * Description      : フラットファイル作成(A-4)/連携済データステータス更新(A-5)
   ***********************************************************************************/
  PROCEDURE create_flat_file_p(
    ov_errbuf  OUT VARCHAR2                                       -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                       -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                       -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_flat_file_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf             VARCHAR2(5000) DEFAULT NULL;            -- エラー・メッセージ
    lv_retcode            VARCHAR2(1)    DEFAULT NULL;            -- リターン・コード
    lv_errmsg             VARCHAR2(5000) DEFAULT NULL;            -- ユーザー・エラー・メッセージ
    lv_out_msg            VARCHAR2(5000) DEFAULT NULL;            -- メッセージ出力変数
    lb_retcode            BOOLEAN        DEFAULT NULL;            -- メッセージ出力関数の戻り値
    lv_flat               VARCHAR2(1000) DEFAULT NULL;            -- フラットファイル作成変数
    lv_budget_year        VARCHAR2(100)  DEFAULT NULL;            -- 予算年度変換変数
    lv_target_month       VARCHAR2(100)  DEFAULT NULL;            -- 月度変換変数
    lv_budget_amt         VARCHAR2(100)  DEFAULT NULL;            -- 予算金額変換変数
    lv_system_date        VARCHAR2(100)  DEFAULT NULL;            -- システム日付変換変数
    lv_company_code       VARCHAR2(100)  DEFAULT NULL;            -- 会社コードの変数
    lv_base_code          VARCHAR2(100)  DEFAULT NULL;            -- 拠点コードの変数
    lv_corp_code          VARCHAR2(100)  DEFAULT NULL;            -- 企業コードの変数
    lv_sales_outlets_code VARCHAR2(100)  DEFAULT NULL;            -- 問屋帳合先コードの変数
    lv_acct_code          VARCHAR2(100)  DEFAULT NULL;            -- 勘定科目コードの変数
    lv_sub_acct_code      VARCHAR2(100)  DEFAULT NULL;            -- 補助科目コードの変数
    -- ===============================
    -- ローカル変数
    -- ===============================
    upd_expt EXCEPTION;
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--    --==============================================================
--    --ロック取得用カーソル
--    --==============================================================
--    CURSOR l_upd_cur(
--             in_bm_support_budget_id IN NUMBER
--           )
--    IS
--      SELECT 'X'
--      FROM   xxcok_bm_support_budget xbsb
--      WHERE  xbsb.bm_support_budget_id = in_bm_support_budget_id
--      FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT;
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
--
  BEGIN
    ov_retcode := cv_status_normal;
-- 2009/07/13 Ver.1.2 [障害0000294] SCS K.Yamaguchi REPAIR START
--    --===============================================================
--    --ループ開始
--    --===============================================================
--    <<file_loop>>
--    FOR i IN 1 .. g_bm_support_budget_tab.COUNT LOOP
--      lv_company_code       := g_bm_support_budget_tab(i).company_code;
--      lv_budget_year        := g_bm_support_budget_tab(i).budget_year;
--      lv_base_code          := g_bm_support_budget_tab(i).base_code;
--      lv_corp_code          := g_bm_support_budget_tab(i).corp_code;
--      lv_sales_outlets_code := g_bm_support_budget_tab(i).sales_outlets_code;
--      lv_acct_code          := g_bm_support_budget_tab(i).acct_code;
--      lv_sub_acct_code      := g_bm_support_budget_tab(i).sub_acct_code;
--      lv_target_month       := g_bm_support_budget_tab(i).target_month;
--      lv_budget_amt         := g_bm_support_budget_tab(i).budget_amt;
--      lv_system_date        := TO_CHAR( gd_system_date, 'YYYYMMDDHH24MISS' );
----
--      lv_flat := (
--        cv_msg_double || lv_company_code       || cv_msg_double || cv_msg_comma ||     -- 会社コード
--                         lv_budget_year        || cv_msg_comma  ||                     -- 予算年度
--        cv_msg_double || lv_base_code          || cv_msg_double || cv_msg_comma ||     -- 拠点コード
--        cv_msg_double || lv_corp_code          || cv_msg_double || cv_msg_comma ||     -- 企業コード
--        cv_msg_double || lv_sales_outlets_code || cv_msg_double || cv_msg_comma ||     -- 問屋帳合先コード
--        cv_msg_double || lv_acct_code          || cv_msg_double || cv_msg_comma ||     -- 勘定科目コード
--        cv_msg_double || lv_sub_acct_code      || cv_msg_double || cv_msg_comma ||     -- 補助科目コード
--                         lv_target_month       || cv_msg_comma  ||                     -- 月度
--                         lv_budget_amt         || cv_msg_comma  ||                     -- 予算金額
--                         lv_system_date                                                -- システム日付
--      );
--      --==============================================================
--      --フラットファイルを作成
--      --==============================================================
--      UTL_FILE.PUT_LINE(
--        file   => g_open_file           -- ファイルハンドル
--      , buffer => lv_flat               -- テキストバッファ
--      );
--      --==============================================================
--      --連携済データステータス更新
--      --==============================================================
--    OPEN  l_upd_cur(
--            g_bm_support_budget_tab(i).bm_support_budget_id
--          );
--    CLOSE l_upd_cur;
--    BEGIN
--      UPDATE xxcok_bm_support_budget       xbsb
--      SET    xbsb.info_interface_status  = cv_settled_status         -- 情報系連携ステータス
--           , xbsb.last_updated_by        = cn_last_updated_by        -- ログインユーザーID
--           , xbsb.last_update_date       = SYSDATE                   -- システム日付
--           , xbsb.last_update_login      = cn_last_update_login      -- ログインID
--           , xbsb.request_id             = cn_request_id             -- コンカレント要求ID
--           , xbsb.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
--           , xbsb.program_id             = cn_program_id             -- コンカレント・プログラムID
--           , xbsb.program_update_date    = SYSDATE                   -- システム日付
--      WHERE  xbsb.bm_support_budget_id   = g_bm_support_budget_tab(i).bm_support_budget_id;
--    EXCEPTION
--      WHEN OTHERS THEN
--        -- *** 連携済データステータス更新エラー ***
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                        cv_appli_xxcok_name
--                      , cv_status_err_msg
--                      , cv_company_token
--                      , lv_company_code          -- 会社コード
--                      , cv_budget_token
--                      , lv_budget_year           -- 予算年度
--                      , cv_location_token
--                      , lv_base_code             -- 拠点コード
--                      , cv_corporate_token
--                      , lv_corp_code             -- 企業コード
--                      , cv_store_token
--                      , lv_sales_outlets_code    -- 問屋帳合先コード
--                      , cv_account_token
--                      , lv_acct_code             -- 勘定科目コード
--                      , cv_sub_token
--                      , lv_sub_acct_code         -- 補助科目コード
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f( 
--                        FND_FILE.OUTPUT    -- 出力区分
--                      , lv_out_msg         -- メッセージ
--                      , 0                  -- 改行
--                      );
--        ov_errmsg  := NULL;
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--      RAISE upd_expt;
--    END;
--    --==============================================================
--    --成功件数カウント
--    --==============================================================
--    gn_normal_cnt := gn_normal_cnt + 1;
----
--    END LOOP file_loop;
    --===============================================================
    --連携対象販手販協予算情報取得(A-4)
    --===============================================================
    << file_loop >>
    FOR g_bm_support_budget_rec IN g_bm_support_budget_cur LOOP
      lv_company_code       := g_bm_support_budget_rec.company_code;
      lv_budget_year        := g_bm_support_budget_rec.budget_year;
      lv_base_code          := g_bm_support_budget_rec.base_code;
      lv_corp_code          := g_bm_support_budget_rec.corp_code;
      lv_sales_outlets_code := g_bm_support_budget_rec.sales_outlets_code;
      lv_acct_code          := g_bm_support_budget_rec.acct_code;
      lv_sub_acct_code      := g_bm_support_budget_rec.sub_acct_code;
      lv_target_month       := g_bm_support_budget_rec.target_month;
      lv_budget_amt         := g_bm_support_budget_rec.budget_amt;
      lv_system_date        := TO_CHAR( gd_system_date, 'YYYYMMDDHH24MISS' );
      lv_flat := (
        cv_msg_double || lv_company_code       || cv_msg_double || cv_msg_comma ||     -- 会社コード
                         lv_budget_year                         || cv_msg_comma ||     -- 予算年度
        cv_msg_double || lv_base_code          || cv_msg_double || cv_msg_comma ||     -- 拠点コード
        cv_msg_double || lv_corp_code          || cv_msg_double || cv_msg_comma ||     -- 企業コード
        cv_msg_double || lv_sales_outlets_code || cv_msg_double || cv_msg_comma ||     -- 問屋帳合先コード
        cv_msg_double || lv_acct_code          || cv_msg_double || cv_msg_comma ||     -- 勘定科目コード
        cv_msg_double || lv_sub_acct_code      || cv_msg_double || cv_msg_comma ||     -- 補助科目コード
                         lv_target_month                        || cv_msg_comma ||     -- 月度
                         lv_budget_amt                          || cv_msg_comma ||     -- 予算金額
                         lv_system_date                                                -- システム日付
      );
      --==============================================================
      --フラットファイルを作成
      --==============================================================
      UTL_FILE.PUT_LINE(
        file   => g_open_file           -- ファイルハンドル
      , buffer => lv_flat               -- テキストバッファ
      );
      --==============================================================
      --連携済データステータス更新
      --==============================================================
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--      OPEN  l_upd_cur(
--              g_bm_support_budget_rec.bm_support_budget_id
--            );
--      CLOSE l_upd_cur;
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
      BEGIN
        UPDATE xxcok_bm_support_budget       xbsb
        SET    xbsb.info_interface_status  = cv_settled_status         -- 情報系連携ステータス
             , xbsb.last_updated_by        = cn_last_updated_by        -- ログインユーザーID
             , xbsb.last_update_date       = SYSDATE                   -- システム日付
             , xbsb.last_update_login      = cn_last_update_login      -- ログインID
             , xbsb.request_id             = cn_request_id             -- コンカレント要求ID
             , xbsb.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
             , xbsb.program_id             = cn_program_id             -- コンカレント・プログラムID
             , xbsb.program_update_date    = SYSDATE                   -- システム日付
        WHERE  xbsb.bm_support_budget_id   = g_bm_support_budget_rec.bm_support_budget_id;
      EXCEPTION
        WHEN OTHERS THEN
          -- *** 連携済データステータス更新エラー ***
          lv_out_msg := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_status_err_msg
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--                        , cv_company_token
--                        , lv_company_code          -- 会社コード
--                        , cv_budget_token
--                        , lv_budget_year           -- 予算年度
--                        , cv_location_token
--                        , lv_base_code             -- 拠点コード
--                        , cv_corporate_token
--                        , lv_corp_code             -- 企業コード
--                        , cv_store_token
--                        , lv_sales_outlets_code    -- 問屋帳合先コード
--                        , cv_account_token
--                        , lv_acct_code             -- 勘定科目コード
--                        , cv_sub_token
--                        , lv_sub_acct_code         -- 補助科目コード
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
                        );
          lb_retcode := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- 出力区分
                        , lv_out_msg         -- メッセージ
                        , 0                  -- 改行
                        );
          ov_errmsg  := NULL;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
        RAISE upd_expt;
      END;
      --==============================================================
      --対象件数カウント
      --==============================================================
      gn_target_cnt := gn_target_cnt + 1;
      --==============================================================
      --成功件数カウント
      --==============================================================
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP file_loop;
-- 2009/07/13 Ver.1.2 [障害0000294] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** ロックエラーメッセージ ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_lock_err_msg
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--                    , cv_company_token
--                    , lv_company_code          -- 会社コード
--                    , cv_budget_token
--                    , lv_budget_year           -- 予算年度
--                    , cv_location_token
--                    , lv_base_code             -- 拠点コード
--                    , cv_corporate_token
--                    , lv_corp_code             -- 企業コード
--                    , cv_store_token
--                    , lv_sales_outlets_code    -- 問屋帳合先コード
--                    , cv_account_token
--                    , lv_acct_code             -- 勘定科目コード
--                    , cv_sub_token
--                    , lv_sub_acct_code         -- 補助科目コード
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 連携済データステータス更新エラー ***
    WHEN upd_expt THEN
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END create_flat_file_p;
--
  /**********************************************************************************
   * Procedure Name   : close_file_p
   * Description      : ファイルクローズ(A-6)
   ***********************************************************************************/
  PROCEDURE close_file_p(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_file_p'; -- プログラム名
    -- ===============================
    -- ローカル定数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(5000)  DEFAULT NULL;                 -- メッセージ出力変数
    lb_retcode BOOLEAN        DEFAULT NULL;                 -- メッセージ出力関数の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --オープン・ファイルをファイル・ハンドルが識別しているかテスト
    --==============================================================
    IF( UTL_FILE.IS_OPEN( g_open_file ) ) THEN
      --==============================================================
      --ファイルのクローズ
      --==============================================================
      UTL_FILE.FCLOSE(
        file => g_open_file
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END close_file_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2                            -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                            -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                            -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;            -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;            -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;            -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(5000)  DEFAULT NULL;            -- メッセージ出力変数
    lb_retcode BOOLEAN        DEFAULT NULL;            -- メッセージ出力関数の戻り値
    -- ===============================
    -- ローカル例外
    -- ===============================
    file_close_expt EXCEPTION;                         -- ファイルクローズエラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --グローバル変数の初期化
    --==============================================================
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --===============================================================
    --initの呼び出し(初期処理(A-1))
    --===============================================================
    init(
      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
    , ov_retcode => lv_retcode                         -- リターン・コード
    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--    --===============================================================
--    --get_target_account_pの呼び出し(処理対象会計年度取得(A-2))
--    --===============================================================
--    get_target_account_p(
--      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
--    , ov_retcode => lv_retcode                         -- リターン・コード
--    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
-- 2010/07/29 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
    --===============================================================
    --open_file_pの呼び出し(ファイルオープン(A-2))
    --===============================================================
    open_file_p(
      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
    , ov_retcode => lv_retcode                         -- リターン・コード
    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/07/13 Ver.1.2 [障害0000294] SCS K.Yamaguchi REPAIR START
--    --===============================================================
--    --get_budget_info_pの呼び出し(連携対象販手販協予算情報取得(A-4))
--    --===============================================================
--    get_budget_info_p(
--      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
--    , ov_retcode => lv_retcode                         -- リターン・コード
--    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    IF( gn_target_cnt > 0 ) THEN
--      --===============================================================
--      --create_flat_file_pの呼び出し(フラットファイル作成(A-5))
--      --===============================================================
--      create_flat_file_p(
--        ov_errbuf  => lv_errbuf                        -- エラー・メッセージ
--      , ov_retcode => lv_retcode                       -- リターン・コード
--      , ov_errmsg  => lv_errmsg                        -- ユーザー・エラー・メッセージ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--    END IF;
    --===============================================================
    --create_flat_file_pの呼び出し(フラットファイル作成(A-4)/連携済データステータス更新(A-5))
    --===============================================================
    create_flat_file_p(
      ov_errbuf  => lv_errbuf                        -- エラー・メッセージ
    , ov_retcode => lv_retcode                       -- リターン・コード
    , ov_errmsg  => lv_errmsg                        -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/07/13 Ver.1.2 [障害0000294] SCS K.Yamaguchi REPAIR END
    --===============================================================
    --close_file_pの呼び出し(ファイルクローズ(A-6))
    --===============================================================
    close_file_p(
      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
    , ov_retcode => lv_retcode                         -- リターン・コード
    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE file_close_expt;
    END IF;
--
  EXCEPTION
    -- *** ファイルクローズエラー ***
    WHEN file_close_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;      
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- エラー・メッセージ
      , ov_retcode  => lv_retcode                      -- リターン・コード
      , ov_errmsg   => lv_errmsg                       -- ユーザー・エラー・メッセージ
      );
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- エラー・メッセージ
      , ov_retcode  => lv_retcode                      -- リターン・コード
      , ov_errmsg   => lv_errmsg                       -- ユーザー・エラー・メッセージ
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- エラー・メッセージ
      , ov_retcode  => lv_retcode                      -- リターン・コード
      , ov_errmsg   => lv_errmsg                       -- ユーザー・エラー・メッセージ
      );
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                             -- エラー・メッセージ
  , retcode OUT VARCHAR2                                             -- リターン・コード  
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL;                  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)    DEFAULT NULL;                  -- リターン・コード
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL;                  -- ユーザー・エラー・メッセージ
    lv_out_msg         VARCHAR2(5000)  DEFAULT NULL;                  -- メッセージ出力変数
    lb_retcode         BOOLEAN        DEFAULT NULL;                  -- メッセージ出力関数の戻り値
    lv_message_code    VARCHAR2(100)  DEFAULT NULL;                  -- 終了メッセージコード
--
  BEGIN
    --===============================================================
    --コンカレントヘッダメッセージ出力関数の呼び出し
    --===============================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , NULL               -- メッセージ
                  , 1                  -- 改行
                  );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --===============================================================
    --submainの呼び出し（実際の処理はsubmainで行う）
    --===============================================================
    submain(
      ov_errbuf  => lv_errbuf          -- エラー・メッセージ
    , ov_retcode => lv_retcode         -- リターン・コード
    , ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ
    );
    --===============================================================
    --エラー出力
    --===============================================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_errmsg          -- メッセージ
                    , 1                  -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.LOG       -- 出力区分
                    , lv_errbuf          -- メッセージ
                    , 0                  -- 改行
                    );
    END IF;
    --===============================================================
    --対象件数出力
    --===============================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_target_rec_msg
                  , cv_cnt_token
                  , TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --===============================================================
    --成功件数出力
    --===============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_success_rec_msg
                  , cv_cnt_token
                  , TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --===============================================================
    --エラー件数出力
    --===============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_error_rec_msg
                  , cv_cnt_token
                  , TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --===============================================================
    --終了メッセージ
    --===============================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
      retcode         := cv_status_normal;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
      retcode         := cv_status_error;
    END IF;
    --
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --終了ステータスがエラーの場合はROLLBACKする
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode := cv_status_error;
  END main;
END XXCOK022A02C;
/
