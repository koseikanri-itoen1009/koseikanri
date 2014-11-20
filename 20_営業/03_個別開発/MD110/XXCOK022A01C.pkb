CREATE OR REPLACE PACKAGE BODY XXCOK022A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK022A01C(body)
 * Description      : 販手販協予算Excelアップロード
 * MD.050           : 販手販協予算Excelアップロード MD050_COK_022_A01
 * Version          : 2.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  del_mrp_file_ul_interface    ファイルアップロードIFの削除     (A-9)
 *  purge_bm_support_budget      パージ処理                       (A-8)
 *  ins_bm_support_budget        販手販協予算情報の登録           (A-7)
 *  del_duplicate_budget_year    重複予算年度データの削除         (A-6)
 *  ins_xxcok_tmp_022a01c        アップロード情報一時表の登録     (A-5)
 *  chk_data_amount              妥当性チェック：予算金額         (A-4-8)
 *  chk_data_month               妥当性チェック：対象年月         (A-4-7)
 *  chk_data_sub_acct_code       妥当性チェック：補助科目コード   (A-4-6)
 *  chk_data_acct_code           妥当性チェック：勘定科目コード   (A-4-5)
 *  chk_data_corp_code           妥当性チェック：企業コード       (A-4-3)
 *  chk_data_base_code           妥当性チェック：拠点コード       (A-4-2)
 *  chk_data_budget_year         妥当性チェック：予算年度         (A-4-1)
 *  chk_data                     妥当性チェック                   (A-4)
 *  import_upload_file_data      アップロードファイルデータの取込 (A-3)
 *  get_upload_file_data         アップロードファイルデータの取得 (A-2)
 *  init                         初期処理                         (A-1)
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   T.Osada          新規作成
 *  2009/06/12    1.1   K.Yamaguchi      [障害T1_1433]年月設定不正対応
 *  2010/08/02    2.0   S.Arizumi        [E_本稼動_03332]仕様変更（機能の見直し）
 *  2010/08/24    2.0   S.Arizumi        [E_本稼動_03332]仕様変更（マイナス金額対応）
 *
 *****************************************************************************************/
-- 2010/08/02 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi REPAIR START
--  -- =============================================================================
--  -- グローバル定数
--  -- =============================================================================
--  --パッケージ名
--  cv_pkg_name                CONSTANT VARCHAR2(20) := 'XXCOK022A01C';
--  --アプリケーション短縮名
--  cv_xxcok_appl_name         CONSTANT VARCHAR2(10) := 'XXCOK';
--  cv_xxccp_appl_name         CONSTANT VARCHAR2(10) := 'XXCCP';
--  cv_sqlgl_appl_name         CONSTANT VARCHAR2(10) := 'SQLGL';
--  --ステータス・コード
--  cv_status_normal           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
--  cv_status_warn             CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
--  cv_status_error            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
--  cv_status_continue         CONSTANT VARCHAR2(1)  := '9';                                --継続エラー
--  cv_status_open             CONSTANT VARCHAR2(1)  := 'O';                                --会計期間オープン
--  --メッセージ名称
--  cv_err_msg_00003           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00003';   --プロファイル取得エラー
--  cv_err_msg_00039           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00039';   --空ファイルエラー
--  cv_err_msg_00041           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00041';   --BLOBデータ変換エラー
--  cv_err_msg_00057           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00057';   --オープン会計期間取得エラー
--  cv_err_msg_00059           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00059';   --有効会計期間取得エラー
--  cv_err_msg_00061           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00061';   --IF表ロック取得エラー
--  cv_err_msg_00062           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00062';   --ファイルアップロードIFテーブル削除エラー
--  cv_err_msg_10107           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10107';   --販手販協予算テーブルデータロックエラー
--  cv_err_msg_10108           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10108';   --予算年度重複データ削除エラー
--  cv_err_msg_10109           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10109';   --予算年度相違エラー
--  cv_err_msg_10111           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10111';   --前々予算年度データ削除エラー
--  cv_err_msg_10123           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10123';   --予算金額半角英数字エラー
--  cv_err_msg_10125           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10125';   --問屋帳合先コード桁数チェックエラー
--  cv_err_msg_10126           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10126';   --拠点コード桁数チェックエラー
--  cv_err_msg_10127           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10127';   --企業コード桁数チェックエラー
--  cv_err_msg_10128           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10128';   --勘定科目コード桁数チェックエラー
--  cv_err_msg_10129           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10129';   --補助科目コード桁数チェックエラー
--  cv_err_msg_10130           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10130';   --予算金額桁数チェックエラー
--  cv_err_msg_10135           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10135';   --拠点コード半角英数字チェックエラー
--  cv_err_msg_10136           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10136';   --企業コード半角英数字チェックエラー
--  cv_err_msg_10137           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10137';   --問屋帳合先コード半角英数字チェックエラー
--  cv_err_msg_10138           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10138';   --勘定科目コード半角英数字チェックエラー
--  cv_err_msg_10139           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10139';   --補助科目コード半角英数字チェックエラー
--  cv_err_msg_10417           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10417';   --予算年度項目NULLエラー
--  cv_err_msg_10418           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10418';   --拠点コード項目NULLエラー
--  cv_err_msg_10419           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10419';   --企業コード項目NULLエラー
--  cv_err_msg_10420           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10420';   --問屋帳合先コード項目NULLエラー
--  cv_err_msg_10421           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10421';   --勘定科目コード項目NULLエラー
--  cv_err_msg_10422           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10422';   --補助科目コード項目NULLエラー
--  cv_err_msg_10423           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10423';   --月度項目NULLチェックエラー
--  cv_err_msg_10424           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10424';   --予算金額項目NULLチェックエラー
--  cv_err_msg_10425           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10425';   --日付型変換チェックエラー
--  cv_err_msg_10449           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10449';   --販手販協予算テーブル追加エラー
--  cv_message_00006           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00006';   --ファイル名メッセージ出力
--  cv_message_00016           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00016';   --入力パラメータ(ファイルID)
--  cv_message_00017           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00017';   --入力パラメータ(フォーマットパターン)
--  cv_message_90000           CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90000';   --対象件数メッセージ
--  cv_message_90001           CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90001';   --成功件数メッセージ
--  cv_message_90002           CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90002';   --エラー件数メッセージ
--  cv_message_90004           CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90004';   --正常終了メッセージ
--  cv_message_90006           CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90006';   --エラー終了全ロールバックメッセージ
--  --プロファイル
--  cv_set_of_bks_id           CONSTANT VARCHAR2(50) := 'GL_SET_OF_BKS_ID';         --会計帳簿ID
--  cv_company_code            CONSTANT VARCHAR2(50) := 'XXCOK1_AFF1_COMPANY_CODE'; --会社コード
--  --トークン
--  cv_token_file_id           CONSTANT VARCHAR2(10) := 'FILE_ID';         --トークン名(FILE_ID)
--  cv_token_format            CONSTANT VARCHAR2(10) := 'FORMAT';          --トークン名(FORMAT)
--  cv_token_file_name         CONSTANT VARCHAR2(10) := 'FILE_NAME';       --トークン名(FILE_NAME)
--  cv_token_row_num           CONSTANT VARCHAR2(20) := 'ROW_NUM';         --トークン名(ROW_NUM)
--  cv_token_occurs            CONSTANT VARCHAR2(20) := 'OCCURS';          --トークン名(OCCURS)
--  cv_token_budget_year       CONSTANT VARCHAR2(20) := 'BUDGET_YEAR';     --トークン名(BUDGET_YEAR)
--  cv_token_object_year       CONSTANT VARCHAR2(50) := 'OBJECT_YEAR';     --トークン名(OBJECT_YEAR)
--  cv_token_profile           CONSTANT VARCHAR2(10) := 'PROFILE';         --トークン名(PROFILE)
--  cv_token_count             CONSTANT VARCHAR2(5)  := 'COUNT';           --トークン名(COUNT)
--  --フォーマット
--  cv_date_format_yyyymm      CONSTANT VARCHAR2(8)  := 'FXYYYYMM';        --日付型変換チェック用フォーマット
---- 2009/06/12 Ver.1.1 [障害T1_1433] SCS K.Yamaguchi ADD START
--  cv_date_format_mm          CONSTANT VARCHAR2(2)  := 'MM';              --月のみ取得
---- 2009/06/12 Ver.1.1 [障害T1_1433] SCS K.Yamaguchi ADD END
--  --記号
--  cv_msg_part                CONSTANT VARCHAR2(3)  := ' : ';   --コロン
--  cv_msg_cont                CONSTANT VARCHAR2(3)  := '.';     --ピリオド
--  cv_comma                   CONSTANT VARCHAR2(1)  := ',';     --カンマ
--  --文字列
--  cv_info_interface_status   CONSTANT VARCHAR2(1)  := '0';    --情報系連携ステータス(0:未連携)
--  --値
--  cv_0                       CONSTANT VARCHAR2(1)  := '0';    --月度日付型変換チェック用
--  --数値
--  cn_0                       CONSTANT NUMBER       :=  0;     --数値:0
--  cn_1                       CONSTANT NUMBER       :=  1;     --数値:1
--  cn_2                       CONSTANT NUMBER       :=  2;     --数値:2
--  cn_3                       CONSTANT NUMBER       :=  3;     --数値:3
--  cn_4                       CONSTANT NUMBER       :=  4;     --数値:4
--  cn_5                       CONSTANT NUMBER       :=  5;     --数値:4
--  cn_6                       CONSTANT NUMBER       :=  6;     --数値:6
--  cn_9                       CONSTANT NUMBER       :=  9;     --数値:9
--  cn_12                      CONSTANT NUMBER       := 12;     --数値:12
--  --フラグ
--  cv_adjustment_flag         CONSTANT VARCHAR2(1)  := 'N';                          -- 調整フラグ
--  --WHOカラム
--  cn_created_by              CONSTANT NUMBER       := fnd_global.user_id;           --CREATED_BY
--  cn_last_updated_by         CONSTANT NUMBER       := fnd_global.user_id;           --LAST_UPDATED_BY
--  cn_last_update_login       CONSTANT NUMBER       := fnd_global.login_id;          --LAST_UPDATE_LOGIN
--  cn_request_id              CONSTANT NUMBER       := fnd_global.conc_request_id;   --REQUEST_ID
--  cn_program_application_id  CONSTANT NUMBER       := fnd_global.prog_appl_id;      --PROGRAM_APPLICATION_ID
--  cn_program_id              CONSTANT NUMBER       := fnd_global.conc_program_id;   --PROGRAM_ID
--  -- =============================================================================
--  -- グローバル変数
--  -- =============================================================================
--  gn_target_cnt           NUMBER        DEFAULT 0;      --対象件数
--  gn_normal_cnt           NUMBER        DEFAULT 0;      --成功件数
--  gn_error_cnt            NUMBER        DEFAULT 0;      --エラー件数
--  gn_line_no              NUMBER        DEFAULT 0;      --行数カウンタ
--  gv_set_of_books_id      VARCHAR2(100) DEFAULT NULL;   --会計帳簿ID
--  gv_company_code         VARCHAR2(100) DEFAULT NULL;   --会社コード
--  gn_account_year         NUMBER        DEFAULT NULL;   --オープン会計年数変数
--  gn_target_account_year  NUMBER        DEFAULT NULL;   --処理対象会計年度変数
--  gv_chk_code             VARCHAR2(1)   DEFAULT cv_status_normal;   --妥当性チェックの処理結果ステータス
--  -- =============================================================================
--  -- グローバルレコード型
--  -- =============================================================================
--  TYPE gr_csv_bm_support_budget_tab IS RECORD(
--    budget_year          VARCHAR2(100)   DEFAULT NULL
--   ,base_code            VARCHAR2(100)   DEFAULT NULL
--   ,corp_code            VARCHAR2(100)   DEFAULT NULL
--   ,sales_outlets_code   VARCHAR2(100)   DEFAULT NULL
--   ,acct_code            VARCHAR2(100)   DEFAULT NULL
--   ,sub_acct_code        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_01      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_01        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_02      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_02        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_03      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_03        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_04      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_04        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_05      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_05        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_06      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_06        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_07      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_07        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_08      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_08        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_09      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_09        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_10      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_10        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_11      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_11        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_12      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_12        VARCHAR2(100)   DEFAULT NULL);
--   -- 変数の宣言
--   gr_csv_bm_support_budget_rec gr_csv_bm_support_budget_tab;
--  -- =============================================================================
--  -- グローバル例外
--  -- =============================================================================
--  -- *** ロックエラーハンドラ ***
--  global_lock_fail          EXCEPTION;
--  -- *** 処理部共通例外 ***
--  global_process_expt       EXCEPTION;
--  -- *** 共通関数例外 ***
--  global_api_expt           EXCEPTION;
--  -- *** 共通関数OTHERS例外 ***
--  global_api_others_expt    EXCEPTION;
----
--  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
--  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
----
--  /**********************************************************************************
--   * Procedure Name   : del_interface_at_error
--   * Description      : エラー時IFデータ削除(A-10)
--   ***********************************************************************************/
--  PROCEDURE del_interface_at_error(
--    ov_errbuf   OUT VARCHAR2    --エラー・メッセージ
--  , ov_retcode  OUT VARCHAR2    --リターン・コード
--  , ov_errmsg   OUT VARCHAR2    --ユーザー・エラー・メッセージ
--  , in_file_id  IN  NUMBER      --ファイルID
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'del_interface_at_error';   --プログラム名
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_msg     VARCHAR2(5000) DEFAULT NULL;  --メッセージ取得変数
--    lb_retcode BOOLEAN        DEFAULT TRUE;  --メッセージ出力の戻り値
--    lv_target  VARCHAR2(1)    DEFAULT NULL;  --IFテーブル削除対象レコード有無
--    -- =======================
--    -- ローカルカーソル
--    -- =======================
--    CURSOR xmfui_cur
--    IS
--      SELECT 'X'
--      FROM   xxccp_mrp_file_ul_interface xmfui
--      WHERE  xmfui.file_id = in_file_id
--      FOR UPDATE OF xmfui.file_id NOWAIT;
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- ファイルアップロードIFテーブルのロック取得
--    -- =============================================================================
--    BEGIN
--      SELECT 'X'
--      INTO   lv_target
--      FROM   xxccp_mrp_file_ul_interface xmfui
--      WHERE  xmfui.file_id = in_file_id;
----
--      OPEN  xmfui_cur;
--      CLOSE xmfui_cur;
--      -- =============================================================================
--      -- ファイルアップロードIFテーブルの削除処理
--      -- =============================================================================
--      BEGIN
--        DELETE FROM xxccp_mrp_file_ul_interface xmfui
--        WHERE  xmfui.file_id = in_file_id;
--      EXCEPTION
--        -- *** 削除処理に失敗 ***
--        WHEN OTHERS THEN
--          lv_msg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_name
--                    , iv_name         => cv_err_msg_00062
--                    , iv_token_name1  => cv_token_file_id
--                    , iv_token_value1 => TO_CHAR( in_file_id )
--                    );
--          lb_retcode := xxcok_common_pkg.put_message_f(
--                          in_which    => FND_FILE.OUTPUT     --出力区分
--                        , iv_message  => lv_msg              --メッセージ
--                        , in_new_line => 0                   --改行
--                        );
--          ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--          ov_retcode := cv_status_error;
--      END;
--    EXCEPTION
--      -- *** ロック失敗 ***
--      WHEN global_lock_fail THEN
--        lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcok_appl_name
--                  , iv_name         => cv_err_msg_00061
--                  , iv_token_name1  => cv_token_file_id
--                  , iv_token_value1 => TO_CHAR( in_file_id )
--                  );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --出力区分
--                      , iv_message  => lv_msg            --メッセージ
--                      , in_new_line => 0                 --改行
--                      );
--        ov_errmsg  := NULL;
--        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--        ov_retcode := cv_status_error;
--      -- *** 対象無し ***
--      WHEN OTHERS THEN
--        NULL;
--    END;
--  EXCEPTION
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END del_interface_at_error;
----
--  /**********************************************************************************
--   * Procedure Name   : del_mrp_file_ul_interface
--   * Description      : 処理データ削除(A-8)
--   ***********************************************************************************/
--  PROCEDURE del_mrp_file_ul_interface(
--    ov_errbuf   OUT VARCHAR2    --エラー・メッセージ
--  , ov_retcode  OUT VARCHAR2    --リターン・コード
--  , ov_errmsg   OUT VARCHAR2    --ユーザー・エラー・メッセージ
--  , in_file_id  IN  NUMBER      --ファイルID
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'del_mrp_file_ul_interface';   --プログラム名
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
--    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
--    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
--    lv_msg     VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
--    lb_retcode BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- ファイルアップロードIFテーブルの削除処理
--    -- =============================================================================
--    BEGIN
--      DELETE FROM xxccp_mrp_file_ul_interface xmfui
--      WHERE  xmfui.file_id = in_file_id;
--    EXCEPTION
--      -- *** 削除処理に失敗 ***
--      WHEN OTHERS THEN
--        lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcok_appl_name
--                  , iv_name         => cv_err_msg_00062
--                  , iv_token_name1  => cv_token_file_id
--                  , iv_token_value1 => TO_CHAR( in_file_id )
--                  );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT     --出力区分
--                      , iv_message  => lv_msg              --メッセージ
--                      , in_new_line => 0                   --改行
--                      );
--        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--        ov_retcode := cv_status_error;
--    END;
--  EXCEPTION
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END del_mrp_file_ul_interface;
----
--  /**********************************************************************************
--   * Procedure Name   : del_past_acct_year_data
--   * Description      : 前々予算年度データ削除(A-7)
--   ***********************************************************************************/
--  PROCEDURE del_past_acct_year_data(
--    ov_errbuf  OUT VARCHAR2    --エラー・メッセージ
--  , ov_retcode OUT VARCHAR2    --リターン・コード
--  , ov_errmsg  OUT VARCHAR2    --ユーザー・エラー・メッセージ
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name  CONSTANT VARCHAR2(50) := 'del_past_acct_year_data';   --プログラム名
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
--    lv_retcode              VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
--    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
--    lv_msg                  VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
--    ln_two_years_past_year  NUMBER         DEFAULT 0;      --処理対象予算年度の前々予算年度
--    lb_retcode              BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
--    -- =============================================================================
--    -- 1.販手販協予算テーブルのロックを取得
--    -- =============================================================================
--    CURSOR lock_acct_cur(
--             in_two_years_past_year IN NUMBER
--           )
--    IS
--      SELECT 'X'
--      FROM   xxcok_bm_support_budget xbsb
--      WHERE  TO_NUMBER( xbsb.budget_year ) <= in_two_years_past_year
--      FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT;
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- 処理対象予算年度の前々予算年度を求める
--    -- =============================================================================
--    ln_two_years_past_year := gn_target_account_year - cn_2;
--    -- =============================================================================
--    -- 販手販協予算テーブルのロックを取得
--    -- =============================================================================
--    OPEN  lock_acct_cur(
--            ln_two_years_past_year
--          );
--    CLOSE lock_acct_cur;
--    -- =============================================================================
--    -- 販手販協予算テーブルよりレコードを削除
--    -- =============================================================================
--    BEGIN
--      DELETE FROM xxcok_bm_support_budget xbsb
--      WHERE  TO_NUMBER( xbsb.budget_year ) <= ln_two_years_past_year;
--    EXCEPTION
--      -- *** 削除に失敗した場合 ***
--      WHEN OTHERS THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10111
--                , iv_token_name1  => cv_token_object_year
--                , iv_token_value1 => TO_CHAR( ln_two_years_past_year )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT     --出力区分
--                    , iv_message  => lv_msg              --メッセージ
--                    , in_new_line => 0                   --改行
--                    );
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    END;
--  EXCEPTION
--    -- ***ロックに失敗した場合 ***
--    WHEN global_lock_fail THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10107
--                , iv_token_name1  => cv_token_object_year
--                , iv_token_value1 => TO_CHAR( ln_two_years_past_year )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT     --出力区分
--                    , iv_message  => lv_msg              --メッセージ
--                    , in_new_line => 0                   --改行
--                    );
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END del_past_acct_year_data;
----
--  /**********************************************************************************
--   * Procedure Name   : ins_bm_support_budget
--   * Description      : 販手販協予算テーブルデータ登録(A-6)
--   ***********************************************************************************/
--  PROCEDURE ins_bm_support_budget(
--    ov_errbuf               OUT VARCHAR2    --エラー・メッセージ
--  , ov_retcode              OUT VARCHAR2    --リターン・コード
--  , ov_errmsg               OUT VARCHAR2    --ユーザー・エラー・メッセージ
--  , iv_budget_year          IN  VARCHAR2    --予算年度
--  , iv_base_code            IN  VARCHAR2    --拠点コード
--  , iv_corp_code            IN  VARCHAR2    --企業コード
--  , iv_sales_outlets_code   IN  VARCHAR2    --問屋帳合先コード
--  , iv_acct_code            IN  VARCHAR2    --勘定科目コード
--  , iv_sub_acct_code        IN  VARCHAR2    --補助科目コード
--  , iv_target_month         IN  VARCHAR2    --月度
--  , iv_budget_amt           IN  VARCHAR2    --予算金額
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'ins_bm_support_budget';   --プログラム名
---- 2009/06/12 Ver.1.1 [障害T1_1433] SCS K.Yamaguchi ADD START
--    cv_no_adj_flag               gl_periods.adjustment_period_flag%TYPE := 'N';
---- 2009/06/12 Ver.1.1 [障害T1_1433] SCS K.Yamaguchi ADD END
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_errbuf                    VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
--    lv_retcode                   VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
--    lv_errmsg                    VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
--    lv_msg                       VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
--    lb_retcode                   BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
--    ln_bm_support_budget_id      NUMBER         DEFAULT 0;                  --販手販協予算ID
--    lv_target_month              VARCHAR2(2)    DEFAULT NULL;               --月度
--    ln_chr_length                NUMBER         DEFAULT 0;                  --月度文字列長
---- 2009/06/12 Ver.1.1 [障害T1_1433] SCS K.Yamaguchi ADD START
--    lt_target_ym                 xxcok_bm_support_budget.target_month%TYPE DEFAULT NULL; -- 年月
---- 2009/06/12 Ver.1.1 [障害T1_1433] SCS K.Yamaguchi ADD END
----
--  BEGIN
--    ov_retcode := cv_status_normal;
----
--    -- =============================================================================
--    -- 販手販協予算IDをシーケンスより取得
--    -- =============================================================================
--    SELECT xxcok_bm_support_budget_s01.NEXTVAL AS xxcok_bm_support_budget_s01
--    INTO   ln_bm_support_budget_id
--    FROM   DUAL;
--    -- =============================================================================
--    -- 月度桁数調整
--    -- =============================================================================
--    ln_chr_length := LENGTHB( iv_target_month );
--    --１桁で入力されている場合、頭'０'を付与し２桁にする
--    IF ( ln_chr_length = cn_1 ) THEN
--      lv_target_month := ( cv_0 || iv_target_month );
--    ELSE
--      lv_target_month := iv_target_month;
--    END IF;
---- 2009/06/12 Ver.1.1 [障害T1_1433] SCS K.Yamaguchi ADD START
--    -- =============================================================================
--    -- 年月決定
--    -- =============================================================================
--    SELECT TO_CHAR( gp.start_date, 'RRRRMM' )
--    INTO lt_target_ym
--    FROM gl_periods                gp                          -- 会計カレンダテーブル
--       , gl_sets_of_books          gsob                        -- 会計帳簿マスタ
--    WHERE gp.period_set_name             = gsob.period_set_name
--      AND gsob.set_of_books_id           = TO_NUMBER( gv_set_of_books_id )
--      AND gp.period_year                 = TO_NUMBER( iv_budget_year )
--      AND gp.adjustment_period_flag      = cv_no_adj_flag
--      AND TO_CHAR( gp.start_date, 'MM' ) = lv_target_month
--    ;
---- 2009/06/12 Ver.1.1 [障害T1_1433] SCS K.Yamaguchi ADD END
--    -- =============================================================================
--    -- 販手販協予算テーブルへレコードの追加
--    -- =============================================================================
--    INSERT INTO xxcok_bm_support_budget(
--      bm_support_budget_id                                 --販手販協予算ID
--    , company_code                                         --会社コード
--    , budget_year                                          --予算年度
--    , base_code                                            --拠点コード
--    , corp_code                                            --企業コード
--    , sales_outlets_code                                   --問屋帳合先コード
--    , acct_code                                            --勘定科目コード
--    , sub_acct_code                                        --補助科目コード
--    , target_month                                         --月度
--    , budget_amt                                           --予算金額
--    , info_interface_status                                --情報系連携ステータス
--    , created_by                                           --作成者
--    , creation_date                                        --作成日
--    , last_updated_by                                      --最終更新者
--    , last_update_date                                     --最終更新日
--    , last_update_login                                    --最終更新ログイン
--    , request_id                                           --要求ID
--    , program_application_id                               --コンカレント・プログラム・アプリケーションID
--    , program_id                                           --コンカレント・プログラムID
--    , program_update_date                                  --プログラム更新日
--    ) VALUES (
--      ln_bm_support_budget_id                              --bm_support_budget_id
--    , gv_company_code                                      --company_code
--    , iv_budget_year                                       --budget_year
--    , iv_base_code                                         --base_code
--    , iv_corp_code                                         --corp_code
--    , iv_sales_outlets_code                                --sales_outlets_code
--    , iv_acct_code                                         --acct_code
--    , iv_sub_acct_code                                     --sub_acct_code
---- 2009/06/12 Ver.1.1 [障害T1_1433] SCS K.Yamaguchi REPAIR START
----    , iv_budget_year || lv_target_month                    --target_month
--    , lt_target_ym                                         --target_month
---- 2009/06/12 Ver.1.1 [障害T1_1433] SCS K.Yamaguchi REPAIR END
--    , TO_NUMBER( iv_budget_amt )                           --budget_amt
--    , cv_info_interface_status                             --info_interface_status
--    , cn_created_by                                        --created_by
--    , SYSDATE                                              --creation_date
--    , cn_last_updated_by                                   --last_updated_by
--    , SYSDATE                                              --last_update_date
--    , cn_last_update_login                                 --last_update_login
--    , cn_request_id                                        --request_id
--    , cn_program_application_id                            --program_application_id
--    , cn_program_id                                        --program_id
--    , SYSDATE                                              --program_update_date
--    );
--    -- *** 成功件数カウント ***
--    gn_normal_cnt := gn_normal_cnt + 1;
--  EXCEPTION
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ (追加処理エラー) ***
--    WHEN OTHERS THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10449
--                , iv_token_name1  => cv_token_budget_year
--                , iv_token_value1 => iv_budget_year
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END ins_bm_support_budget;
----
--  /**********************************************************************************
--   * Procedure Name   : chk_data_month_amt
--   * Description      : 妥当性チェック(月度、予算金額)(A-5-1)
--   ***********************************************************************************/
--  PROCEDURE chk_data_month_amt(
--    ov_errbuf                    OUT VARCHAR2                     --エラー・メッセージ
--  , ov_retcode                   OUT VARCHAR2                     --リターン・コード
--  , ov_errmsg                    OUT VARCHAR2                     --ユーザー・エラー・メッセージ
--  , iv_target_month              IN  VARCHAR2                     --月度
--  , iv_budget_amt                IN  VARCHAR2                     --予算金額
--  , in_occurs                    IN  NUMBER                       --月度、予算金額の順番
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'chk_data_month_amt';     --プログラム名
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
--    lv_retcode              VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
--    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
--    lv_msg                  VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
--    lv_target_month         VARCHAR2(2)    DEFAULT NULL;               --月度退避用
--    lv_occurs               VARCHAR2(2)    DEFAULT NULL;               --月度、予算金額の順番(表示用)
--    lb_retcode              BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
--    lb_chk_number           BOOLEAN        DEFAULT TRUE;               --半角数字チェックの結果
--    ln_chr_length           NUMBER         DEFAULT 0;                  --桁数チェック
--    ld_chk_month            DATE           DEFAULT NULL;               --日付型変換チェック用
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- 月度、予算金額の順番(表示用)を設定
--    -- =============================================================================
--    ln_chr_length := LENGTHB( in_occurs );
--    IF ( ln_chr_length = cn_1 ) THEN
--      lv_occurs   := ( cv_0 || TO_CHAR( in_occurs ) );
--    ELSE
--      lv_occurs   := TO_CHAR( in_occurs );
--    END IF;
--    -- =============================================================================
--    -- 必須項目チェック
--    -- =============================================================================
--    --月度
--    IF ( iv_target_month IS NULL ) THEN
--      -- *** 項目がNULLの場合、例外処理 ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10423
--                , iv_token_name1  => cv_token_occurs
--                , iv_token_value1 => lv_occurs
--                , iv_token_name2  => cv_token_row_num
--                , iv_token_value2 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --予算金額
--    IF ( iv_budget_amt IS NULL ) THEN
--      -- *** 項目がNULLの場合、例外処理 ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10424
--                , iv_token_name1  => cv_token_occurs
--                , iv_token_value1 => lv_occurs
--                , iv_token_name2  => cv_token_row_num
--                , iv_token_value2 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    -- =============================================================================
--    -- データ型チェック(半角数字チェック)
--    -- =============================================================================
--    --予算金額
--    lb_chk_number := xxccp_common_pkg.chk_number(
--                       iv_check_char => iv_budget_amt
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10123
--                , iv_token_name1  => cv_token_occurs
--                , iv_token_value1 => lv_occurs
--                , iv_token_name2  => cv_token_row_num
--                , iv_token_value2 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
--    -- =============================================================================
--    -- 日付型変換チェック(値がNULLの場合チェック対象外)
--    -- =============================================================================
--    --月度
--    BEGIN
--      IF ( iv_target_month IS NOT NULL ) THEN
--        ln_chr_length := LENGTHB( iv_target_month );
--        --１桁で入力されている場合、頭'０'を付与し２桁にしてチェックする
--        IF ( ln_chr_length = cn_1 ) THEN
--          lv_target_month := ( cv_0 || iv_target_month );
--        ELSE
--          lv_target_month := iv_target_month;
--        END IF;
--        ld_chk_month  := TO_DATE( TO_CHAR( gn_target_account_year ) || lv_target_month, cv_date_format_yyyymm );
--      END IF;
--    EXCEPTION
--      -- *** 変換できなかった場合、例外処理 ***
--      WHEN OTHERS THEN
--        lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcok_appl_name
--                  , iv_name         => cv_err_msg_10425
--                  , iv_token_name1  => cv_token_occurs
--                  , iv_token_value1 => lv_occurs
--                  , iv_token_name2  => cv_token_row_num
--                  , iv_token_value2 => TO_CHAR( gn_line_no )
--                  );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --出力区分
--                      , iv_message  => lv_msg            --メッセージ
--                      , in_new_line => 0                 --改行
--                      );
--        ov_retcode := cv_status_continue;
--    END;
--    -- =============================================================================
--    -- 桁数チェック(値がNULLの場合チェック対象外)
--    -- =============================================================================
--    --予算金額
--    IF ( iv_budget_amt IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( iv_budget_amt );
----
--       IF ( ln_chr_length > cn_12 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10130
--                   , iv_token_name1  => cv_token_occurs
--                   , iv_token_value1 => lv_occurs
--                   , iv_token_name2  => cv_token_row_num
--                   , iv_token_value2 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --出力区分
--                       , iv_message  => lv_msg            --メッセージ
--                       , in_new_line => 0                 --改行
--                       );
--         ov_retcode := cv_status_continue;
--      END IF;
----
--    END IF;
----
--  EXCEPTION
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END chk_data_month_amt;
----
--  /**********************************************************************************
--   * Procedure Name   : chk_data
--   * Description      : 妥当性チェック(A-5)
--   ***********************************************************************************/
--  PROCEDURE chk_data(
--    ov_errbuf                    OUT VARCHAR2                      --エラー・メッセージ
--  , ov_retcode                   OUT VARCHAR2                      --リターン・コード
--  , ov_errmsg                    OUT VARCHAR2                      --ユーザー・エラー・メッセージ
--  , it_csv_bm_support_budget_rec IN  gr_csv_bm_support_budget_tab  --CSV販手販協予算データ・レコード型
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'chk_data';     --プログラム名
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
--    lv_retcode              VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
--    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
--    lv_msg                  VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
--    lv_target_month         VARCHAR2(100)  DEFAULT NULL;               --月度
--    lv_budget_amt           VARCHAR2(100)  DEFAULT NULL;               --予算金額
--    lb_retcode              BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
--    lb_chk_number           BOOLEAN        DEFAULT TRUE;               --半角数字チェックの結果
--    ln_chr_length           NUMBER         DEFAULT 0;                  --桁数チェック
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- 必須項目チェック
--    -- =============================================================================
--    --予算年度
--    IF ( it_csv_bm_support_budget_rec.budget_year IS NULL ) THEN
--      -- *** 項目がNULLの場合、例外処理 ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10417
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --拠点コード
--    IF ( it_csv_bm_support_budget_rec.base_code IS NULL ) THEN
--      -- *** 項目がNULLの場合、例外処理 ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10418
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --企業コード
--    IF ( it_csv_bm_support_budget_rec.corp_code IS NULL ) THEN
--      -- *** 項目がNULLの場合、例外処理 ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10419
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --問屋帳合先コード
--    IF ( it_csv_bm_support_budget_rec.sales_outlets_code IS NULL ) THEN
--      -- *** 項目がNULLの場合、例外処理 ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10420
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --勘定科目コード
--    IF ( it_csv_bm_support_budget_rec.acct_code IS NULL ) THEN
--      -- *** 項目がNULLの場合、例外処理 ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10421
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --補助科目コード
--    IF ( it_csv_bm_support_budget_rec.sub_acct_code IS NULL ) THEN
--      -- *** 項目がNULLの場合、例外処理 ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10422
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    -- =============================================================================
--    -- CSVファイルの予算年度と処理対象会計年度の比較
--    -- =============================================================================
--    IF ( it_csv_bm_support_budget_rec.budget_year IS NOT NULL ) THEN
--      IF ( it_csv_bm_support_budget_rec.budget_year <> TO_CHAR( gn_target_account_year ) ) THEN
--        -- *** 予算年度と処理対象会計年度が相違する場合、例外処理 ***
--        lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcok_appl_name
--                  , iv_name         => cv_err_msg_10109
--                  , iv_token_name1  => cv_token_budget_year
--                  , iv_token_value1 => it_csv_bm_support_budget_rec.budget_year
--                  , iv_token_name2  => cv_token_object_year
--                  , iv_token_value2 => TO_CHAR( gn_target_account_year )
--                  , iv_token_name3  => cv_token_row_num
--                  , iv_token_value3 => TO_CHAR( gn_line_no )
--                  );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --出力区分
--                      , iv_message  => lv_msg            --メッセージ
--                      , in_new_line => 0                 --改行
--                      );
--        ov_retcode := cv_status_continue;
--      END IF;
--    END IF;
----
--    -- =============================================================================
--    -- データ型チェック(半角英数字チェック)
--    -- =============================================================================
--    --拠点コード
--    lb_chk_number := xxccp_common_pkg.chk_alphabet_number_only(
--                       iv_check_char => it_csv_bm_support_budget_rec.base_code
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10135
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --企業コード
--    lb_chk_number := xxccp_common_pkg.chk_alphabet_number_only(
--                       iv_check_char => it_csv_bm_support_budget_rec.corp_code
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10136
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --問屋帳合先コード
--    lb_chk_number := xxccp_common_pkg.chk_alphabet_number_only(
--                       iv_check_char => it_csv_bm_support_budget_rec.sales_outlets_code
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10137
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --勘定科目コード
--    lb_chk_number := xxccp_common_pkg.chk_alphabet_number_only(
--                       iv_check_char => it_csv_bm_support_budget_rec.acct_code
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10138
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --補助科目コード
--    lb_chk_number := xxccp_common_pkg.chk_alphabet_number_only(
--                       iv_check_char => it_csv_bm_support_budget_rec.sub_acct_code
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10139
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    -- =============================================================================
--    -- 桁数チェック(値がNULLの場合チェック対象外)
--    -- =============================================================================
--    --拠点コード
--    IF ( it_csv_bm_support_budget_rec.base_code IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( it_csv_bm_support_budget_rec.base_code );
----
--       IF ( ln_chr_length <> cn_4 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10126
--                   , iv_token_name1  => cv_token_row_num
--                   , iv_token_value1 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --出力区分
--                       , iv_message  => lv_msg            --メッセージ
--                       , in_new_line => 0                 --改行
--                       );
--         ov_retcode := cv_status_continue;
--      END IF;
----
--    END IF;
----
--    --企業コード
--    IF ( it_csv_bm_support_budget_rec.corp_code IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( it_csv_bm_support_budget_rec.corp_code );
----
--       IF ( ln_chr_length <> cn_6 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10127
--                   , iv_token_name1  => cv_token_row_num
--                   , iv_token_value1 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --出力区分
--                       , iv_message  => lv_msg            --メッセージ
--                       , in_new_line => 0                 --改行
--                       );
--         ov_retcode := cv_status_continue;
--       END IF;
----
--    END IF;
----
--    --問屋帳合先コード
--    IF ( it_csv_bm_support_budget_rec.sales_outlets_code IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( it_csv_bm_support_budget_rec.sales_outlets_code );
----
--       IF ( ln_chr_length <> cn_9 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10125
--                   , iv_token_name1  => cv_token_row_num
--                   , iv_token_value1 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --出力区分
--                       , iv_message  => lv_msg            --メッセージ
--                       , in_new_line => 0                 --改行
--                       );
--         ov_retcode := cv_status_continue;
--       END IF;
----
--    END IF;
----
--    --勘定科目コード
--    IF ( it_csv_bm_support_budget_rec.acct_code IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( it_csv_bm_support_budget_rec.acct_code );
----
--       IF ( ln_chr_length <> cn_5 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10128
--                   , iv_token_name1  => cv_token_row_num
--                   , iv_token_value1 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --出力区分
--                       , iv_message  => lv_msg            --メッセージ
--                       , in_new_line => 0                 --改行
--                       );
--         ov_retcode := cv_status_continue;
--       END IF;
----
--    END IF;
----
--    --補助科目コード
--    IF ( it_csv_bm_support_budget_rec.sub_acct_code IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( it_csv_bm_support_budget_rec.sub_acct_code );
----
--       IF ( ln_chr_length <> cn_5 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10129
--                   , iv_token_name1  => cv_token_row_num
--                   , iv_token_value1 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --出力区分
--                       , iv_message  => lv_msg            --メッセージ
--                       , in_new_line => 0                 --改行
--                       );
--         ov_retcode := cv_status_continue;
--       END IF;
----
--    END IF;
----
--    -- =============================================================================
--    -- 月度、予算金額チェック
--    -- =============================================================================
--    <<chk_loop>>
--    FOR ln_idx IN 1 .. 12 LOOP
--      IF ln_idx = 1 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_01;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_01;
--      ELSIF ln_idx = 2 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_02;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_02;
--      ELSIF ln_idx = 3 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_03;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_03;
--      ELSIF ln_idx = 4 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_04;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_04;
--      ELSIF ln_idx = 5 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_05;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_05;
--      ELSIF ln_idx = 6 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_06;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_06;
--      ELSIF ln_idx = 7 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_07;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_07;
--      ELSIF ln_idx = 8 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_08;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_08;
--      ELSIF ln_idx = 9 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_09;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_09;
--      ELSIF ln_idx = 10 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_10;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_10;
--      ELSIF ln_idx = 11 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_11;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_11;
--      ELSIF ln_idx = 12 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_12;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_12;
--      END IF;
----
--      -- =============================================================================
--      -- 妥当性チェック(月度、予算金額)(A-5-1)呼出し
--      -- =============================================================================
--      chk_data_month_amt(
--        ov_errbuf                    => lv_errbuf                          --エラー・メッセージ
--      , ov_retcode                   => lv_retcode                         --リターン・コード
--      , ov_errmsg                    => lv_errmsg                          --ユーザー・エラー・メッセージ
--      , iv_target_month              => lv_target_month                    --月度
--      , iv_budget_amt                => lv_budget_amt                      --予算金額
--      , in_occurs                    => ln_idx                             --月度、予算金額の順番
--      );
--      IF ( lv_retcode = cv_status_continue ) THEN
--        ov_retcode := cv_status_continue;
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--    END LOOP chk_loop;
----
--  EXCEPTION
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END chk_data;
----
--  /**********************************************************************************
--   * Procedure Name   : get_file_data
--   * Description      : ファイルデータ取得(A-4)
--   ***********************************************************************************/
--  PROCEDURE get_file_data(
--    ov_errbuf   OUT VARCHAR2     --エラー・メッセージ
--  , ov_retcode  OUT VARCHAR2     --リターン・コード
--  , ov_errmsg   OUT VARCHAR2     --ユーザー・エラー・メッセージ
--  , in_file_id  IN  NUMBER       --ファイルID
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'get_file_data';   --プログラム名
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_errbuf               VARCHAR2(5000)  DEFAULT NULL;               --エラー・メッセージ
--    lv_retcode              VARCHAR2(1)     DEFAULT cv_status_normal;   --リターン・コード
--    lv_errmsg               VARCHAR2(5000)  DEFAULT NULL;               --ユーザー・エラー・メッセージ
--    lv_msg                  VARCHAR2(5000)  DEFAULT NULL;               --メッセージ取得変数
--    lv_file_name            VARCHAR2(256)   DEFAULT NULL;               --ファイル名
--    lv_line                 VARCHAR2(32767) DEFAULT NULL;               --1行のデータ
--    lb_retcode              BOOLEAN         DEFAULT TRUE;               --メッセージ出力の戻り値
--    ln_col                  NUMBER          DEFAULT 0;                  --カラム
--    ln_loop_cnt             NUMBER          DEFAULT 0;                  --LOOPカウンタ
--    ln_csv_col_cnt          NUMBER          DEFAULT 0;                  --CSV項目数
--    lv_target_month         VARCHAR2(100)   DEFAULT NULL;               --月度(退避用)
--    lv_budget_amt           VARCHAR2(100)   DEFAULT NULL;               --予算金額(退避用)
--    -- =======================
--    -- ローカルTABLE型変数
--    -- =======================
--    l_file_data_tab   xxccp_common_pkg2.g_file_data_tbl;   --行テーブル格納領域
--    l_split_csv_tab   xxcok_common_pkg.g_split_csv_tbl;    --CSV分割データ格納領域
--    -- =======================
--    -- ローカルカーソル
--    -- =======================
--    -- =============================================================================
--    -- ファイルアップロードIF表のデータ・ロックを取得
--    -- =============================================================================
--    CURSOR xmfui_cur
--    IS
--      SELECT xmfui.file_name AS file_name
--      FROM   xxccp_mrp_file_ul_interface xmfui
--      WHERE  xmfui.file_id = in_file_id
--      FOR UPDATE OF xmfui.file_id NOWAIT;
--    -- =======================
--    -- ローカルレコード
--    -- =======================
--    xmfui_rec  xmfui_cur%ROWTYPE;
--    -- =======================
--    -- ローカル例外
--    -- =======================
--    blob_expt  EXCEPTION;   --BLOBデータ変換エラー
--    file_expt  EXCEPTION;   --空ファイルエラー
----
--  BEGIN
--    ov_retcode := cv_status_normal;
----
--    OPEN  xmfui_cur;
--      FETCH xmfui_cur INTO xmfui_rec;
--      lv_file_name := xmfui_rec.file_name;
--    CLOSE xmfui_cur;
--    -- =============================================================================
--    -- ファイル名メッセージ出力
--    -- =============================================================================
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxcok_appl_name
--              , iv_name         => cv_message_00006
--              , iv_token_name1  => cv_token_file_name
--              , iv_token_value1 => lv_file_name
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT   --出力区分
--                  , iv_message  => lv_msg            --メッセージ
--                  , in_new_line => 1                 --改行
--                  );
--    -- =============================================================================
--    -- BLOBデータ変換
--    -- =============================================================================
--    xxccp_common_pkg2.blob_to_varchar2(
--      ov_errbuf    => lv_errbuf
--    , ov_retcode   => lv_retcode
--    , ov_errmsg    => lv_errmsg
--    , in_file_id   => in_file_id
--    , ov_file_data => l_file_data_tab
--    );
--    -- *** リターンコードが0(正常)以外の場合、例外処理 ***
--    IF NOT ( lv_retcode = cv_status_normal ) THEN
--      RAISE blob_expt;
--    END IF;
--    -- =============================================================================
--    -- 取得したデータ件数をチェック(件数が1件以下の場合、例外処理)
--    -- =============================================================================
--    IF ( l_file_data_tab.COUNT <= cn_1 ) THEN
--      RAISE file_expt;
--    END IF;
--    -- =============================================================================
--    -- 対象件数を設定
--    -- =============================================================================
--    gn_target_cnt := l_file_data_tab.COUNT - cn_1;
--    -- =============================================================================
--    -- 文字列を分割
--    -- =============================================================================
--    <<main_loop>>
--    FOR ln_index IN 2 .. l_file_data_tab.COUNT LOOP
--      --LOOPカウンタ
--      ln_loop_cnt := ln_loop_cnt + 1;
--      --1行毎のデータを格納
--      lv_line := l_file_data_tab( ln_index );
--      -- =============================================================================
--      -- 変数の初期化
--      -- =============================================================================
--      l_split_csv_tab.delete;
----
--      gr_csv_bm_support_budget_rec := NULL;
--      -- =============================================================================
--      -- CSV文字列分割
--      -- =============================================================================
--      xxcok_common_pkg.split_csv_data_p(
--        ov_errbuf        => lv_errbuf         --エラーバッファ
--      , ov_retcode       => lv_retcode        --リターンコード
--      , ov_errmsg        => lv_errmsg         --エラーメッセージ
--      , iv_csv_data      => lv_line           --CSV文字列
--      , on_csv_col_cnt   => ln_csv_col_cnt    --CSV項目数
--      , ov_split_csv_tab => l_split_csv_tab   --CSV分割データ
--      );
--      <<comma_loop>>
--      FOR ln_cnt IN 1 .. ln_csv_col_cnt LOOP
--        --項目1(予算年度)
--        IF    ( ln_cnt = 1 ) THEN
--          gr_csv_bm_support_budget_rec.budget_year         := l_split_csv_tab( ln_cnt );
--        --項目2(拠点コード)
--        ELSIF ( ln_cnt = 2 ) THEN
--          gr_csv_bm_support_budget_rec.base_code           := l_split_csv_tab( ln_cnt );
--        --項目3(企業コード)
--        ELSIF ( ln_cnt = 3 ) THEN
--          gr_csv_bm_support_budget_rec.corp_code           := l_split_csv_tab( ln_cnt );
--        --項目4(問屋帳合先コード)
--        ELSIF ( ln_cnt = 4 ) THEN
--          gr_csv_bm_support_budget_rec.sales_outlets_code  := l_split_csv_tab( ln_cnt );
--        --項目5(勘定科目コード)
--        ELSIF ( ln_cnt = 5 ) THEN
--          gr_csv_bm_support_budget_rec.acct_code           := l_split_csv_tab( ln_cnt );
--        --項目6(補助科目コード)
--        ELSIF ( ln_cnt = 6 ) THEN
--          gr_csv_bm_support_budget_rec.sub_acct_code       := l_split_csv_tab( ln_cnt );
--        --項目7(月度_01)
--        ELSIF ( ln_cnt = 7 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_01     := l_split_csv_tab( ln_cnt );
--        --項目8(予算金額_01)
--        ELSIF ( ln_cnt = 8 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_01       := l_split_csv_tab( ln_cnt );
--        --項目9(月度_02)
--        ELSIF ( ln_cnt = 9 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_02     := l_split_csv_tab( ln_cnt );
--        --項目10(予算金額_02)
--        ELSIF ( ln_cnt = 10 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_02       := l_split_csv_tab( ln_cnt );
--        --項目11(月度_03)
--        ELSIF ( ln_cnt = 11 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_03     := l_split_csv_tab( ln_cnt );
--        --項目12(予算金額_03)
--        ELSIF ( ln_cnt = 12 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_03       := l_split_csv_tab( ln_cnt );
--        --項目13(月度_04)
--        ELSIF ( ln_cnt = 13 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_04     := l_split_csv_tab( ln_cnt );
--        --項目14(予算金額_04)
--        ELSIF ( ln_cnt = 14 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_04       := l_split_csv_tab( ln_cnt );
--        --項目15(月度_05)
--        ELSIF ( ln_cnt = 15 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_05     := l_split_csv_tab( ln_cnt );
--        --項目16(予算金額_05)
--        ELSIF ( ln_cnt = 16 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_05       := l_split_csv_tab( ln_cnt );
--        --項目17(月度_06)
--        ELSIF ( ln_cnt = 17 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_06     := l_split_csv_tab( ln_cnt );
--        --項目18(予算金額_06)
--        ELSIF ( ln_cnt = 18 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_06       := l_split_csv_tab( ln_cnt );
--        --項目19(月度_07)
--        ELSIF ( ln_cnt = 19 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_07     := l_split_csv_tab( ln_cnt );
--        --項目20(予算金額_07)
--        ELSIF ( ln_cnt = 20 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_07       := l_split_csv_tab( ln_cnt );
--        --項目21(月度_08)
--        ELSIF ( ln_cnt = 21 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_08     := l_split_csv_tab( ln_cnt );
--        --項目22(予算金額_08)
--        ELSIF ( ln_cnt = 22 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_08       := l_split_csv_tab( ln_cnt );
--        --項目23(月度_09)
--        ELSIF ( ln_cnt = 23 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_09     := l_split_csv_tab( ln_cnt );
--        --項目24(予算金額_09)
--        ELSIF ( ln_cnt = 24 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_09       := l_split_csv_tab( ln_cnt );
--        --項目25(月度_10)
--        ELSIF ( ln_cnt = 25 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_10     := l_split_csv_tab( ln_cnt );
--        --項目26(予算金額_10)
--        ELSIF ( ln_cnt = 26 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_10       := l_split_csv_tab( ln_cnt );
--        --項目27(月度_11)
--        ELSIF ( ln_cnt = 27 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_11     := l_split_csv_tab( ln_cnt );
--        --項目28(予算金額_11)
--        ELSIF ( ln_cnt = 28 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_11       := l_split_csv_tab( ln_cnt );
--        --項目29(月度_12)
--        ELSIF ( ln_cnt = 29 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_12     := l_split_csv_tab( ln_cnt );
--        --項目30(予算金額_12)
--        ELSIF ( ln_cnt = 30 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_12       := l_split_csv_tab( ln_cnt );
--        END IF;
--      END LOOP comma_loop;
----
--      --行数カウンタをグローバル変数へセット
--      gn_line_no := ln_index;
--      -- =============================================================================
--      -- 妥当性チェック(A-5)呼出し
--      -- =============================================================================
--      chk_data(
--        ov_errbuf                    => lv_errbuf                          --エラー・メッセージ
--      , ov_retcode                   => lv_retcode                         --リターン・コード
--      , ov_errmsg                    => lv_errmsg                          --ユーザー・エラー・メッセージ
--      , it_csv_bm_support_budget_rec => gr_csv_bm_support_budget_rec       --CSV販手販協予算データ・レコード型
--      );
----
--      IF ( lv_retcode = cv_status_continue ) THEN
--        gv_chk_code  := lv_retcode;
--        ov_retcode   := lv_retcode;
--        gn_error_cnt := gn_error_cnt + 1;
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      -- =============================================================================
--      -- 妥当性チェックでエラーが発生していなければA-6を実行
--      -- =============================================================================
--      IF NOT ( gv_chk_code = cv_status_continue ) THEN
--         <<ins_loop>>
--         FOR ln_idx2 IN 1 .. 12 LOOP
--           IF ln_idx2 = 1 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_01;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_01;
--           ELSIF ln_idx2 = 2 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_02;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_02;
--           ELSIF ln_idx2 = 3 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_03;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_03;
--           ELSIF ln_idx2 = 4 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_04;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_04;
--           ELSIF ln_idx2 = 5 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_05;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_05;
--           ELSIF ln_idx2 = 6 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_06;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_06;
--           ELSIF ln_idx2 = 7 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_07;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_07;
--           ELSIF ln_idx2 = 8 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_08;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_08;
--           ELSIF ln_idx2 = 9 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_09;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_09;
--           ELSIF ln_idx2 = 10 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_10;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_10;
--           ELSIF ln_idx2 = 11 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_11;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_11;
--           ELSIF ln_idx2 = 12 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_12;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_12;
--           END IF;
--           -- =============================================================================
--           -- 販手販協予算情報登録(A-6)呼出し
--           -- =============================================================================
--           ins_bm_support_budget(
--             ov_errbuf              => lv_errbuf                          --エラー・メッセージ
--           , ov_retcode             => lv_retcode                         --リターン・コード
--           , ov_errmsg              => lv_errmsg                          --ユーザー・エラー・メッセージ
--           , iv_budget_year         => gr_csv_bm_support_budget_rec.budget_year         --予算年度
--           , iv_base_code           => gr_csv_bm_support_budget_rec.base_code           --拠点コード
--           , iv_corp_code           => gr_csv_bm_support_budget_rec.corp_code           --企業コード
--           , iv_sales_outlets_code  => gr_csv_bm_support_budget_rec.sales_outlets_code  --問屋帳合先コード
--           , iv_acct_code           => gr_csv_bm_support_budget_rec.acct_code           --勘定科目コード
--           , iv_sub_acct_code       => gr_csv_bm_support_budget_rec.sub_acct_code       --補助科目コード
--           , iv_target_month        => lv_target_month                                  --月度
--           , iv_budget_amt          => lv_budget_amt                                    --予算金額
--           );
--           IF ( lv_retcode = cv_status_error ) THEN
--             RAISE global_process_expt;
--           END IF;
--         END LOOP ins_loop;
--      END IF;
----
--    END LOOP main_loop;
----
--      -- =============================================================================
--      -- 妥当性チェックでエラーが発生していなければA-7を実行
--      -- =============================================================================
--      IF NOT ( gv_chk_code = cv_status_continue ) THEN
--        -- =============================================================================
--        -- 前々年度予算データ削除(A-7)呼出し
--        -- =============================================================================
--        del_past_acct_year_data(
--          ov_errbuf              => lv_errbuf                                         --エラー・メッセージ
--        , ov_retcode             => lv_retcode                                        --リターン・コード
--        , ov_errmsg              => lv_errmsg                                         --ユーザー・エラー・メッセージ
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      ELSE
--        -- =============================================================================
--        -- 妥当性チェックでエラーが発生していた場合は予算年度重複データを削除しない
--        -- =============================================================================
--        ROLLBACK TO del_acct_year_dupl_save;
--      END IF;
----
--  EXCEPTION
--    -- *** ロック失敗 ***
--    WHEN global_lock_fail THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_00061
--                , iv_token_name1  => cv_token_file_id
--                , iv_token_value1 => TO_CHAR( in_file_id )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** BLOBデータ変換エラー ***
--    WHEN blob_expt THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_00041
--                , iv_token_name1  => cv_token_file_id
--                , iv_token_value1 => TO_CHAR( in_file_id )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 空ファイルエラー ***
--    WHEN file_expt THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_00039
--                , iv_token_name1  => cv_token_file_id
--                , iv_token_value1 => TO_CHAR( in_file_id )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END get_file_data;
----
--  /**********************************************************************************
--   * Procedure Name   : del_acct_year_dupl_data
--   * Description      : 予算年度重複データ削除(A-3)
--   ***********************************************************************************/
--  PROCEDURE del_acct_year_dupl_data(
--    ov_errbuf  OUT VARCHAR2    --エラー・メッセージ
--  , ov_retcode OUT VARCHAR2    --リターン・コード
--  , ov_errmsg  OUT VARCHAR2    --ユーザー・エラー・メッセージ
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name  CONSTANT VARCHAR2(50) := 'del_acct_year_dupl_data';   --プログラム名
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
--    lv_retcode              VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
--    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
--    lv_msg                  VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
--    ln_two_years_past_year  NUMBER         DEFAULT 0;      --処理対象予算年度の前々予算年度
--    lb_retcode              BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
--    -- =============================================================================
--    -- 1.販手販協予算テーブルのロックを取得
--    -- =============================================================================
--    CURSOR lock_dupl_cur
--    IS
--      SELECT 'X'
--      FROM   xxcok_bm_support_budget xbsb
--      WHERE  xbsb.budget_year  = TO_CHAR( gn_target_account_year )
--      FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT;
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- セーブポイントの設定
--    -- =============================================================================
--    SAVEPOINT del_acct_year_dupl_save;
--    -- =============================================================================
--    -- 販手販協予算テーブルのロックを取得
--    -- =============================================================================
--    OPEN  lock_dupl_cur;
--    CLOSE lock_dupl_cur;
--    -- =============================================================================
--    -- 販手販協予算テーブルよりレコードを削除
--    -- =============================================================================
--    BEGIN
--      DELETE FROM xxcok_bm_support_budget xbsb
--      WHERE  xbsb.budget_year = TO_CHAR( gn_target_account_year );
--    EXCEPTION
--      -- *** 削除に失敗した場合 ***
--      WHEN OTHERS THEN
--        lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10108
--                , iv_token_name1  => cv_token_object_year
--                , iv_token_value1 => TO_CHAR( gn_target_account_year )
--                );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT     --出力区分
--                    , iv_message  => lv_msg              --メッセージ
--                    , in_new_line => 0                   --改行
--                    );
--        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--        ov_retcode := cv_status_error;
--    END;
--  EXCEPTION
--    -- ***ロックに失敗した場合 ***
--    WHEN global_lock_fail THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10107
--                , iv_token_name1  => cv_token_object_year
--                , iv_token_value1 => TO_CHAR( gn_target_account_year )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT     --出力区分
--                    , iv_message  => lv_msg              --メッセージ
--                    , in_new_line => 0                   --改行
--                    );
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END del_acct_year_dupl_data;
----
--  /**********************************************************************************
--   * Procedure Name   : get_target_acct_year
--   * Description      : 処理対象会計年度取得(A-2)
--   ***********************************************************************************/
--  PROCEDURE get_target_acct_year(
--    ov_errbuf  OUT VARCHAR2                                            -- エラー・メッセージ
--  , ov_retcode OUT VARCHAR2                                            -- リターン・コード
--  , ov_errmsg  OUT VARCHAR2                                            -- ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'get_target_acct_year'; -- プログラム名
--    -- ===============================
--    -- ローカル変数
--    -- ===============================
--    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                            -- エラー・メッセージ
--    lv_retcode VARCHAR2(1)    DEFAULT NULL;                            -- リターン・コード
--    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                            -- ユーザー・エラー・メッセージ
--    lv_msg     VARCHAR2(100)  DEFAULT NULL;                            -- メッセージ出力変数
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
--      AND      gps.set_of_books_id        = gv_set_of_books_id
--      AND      fa.application_short_name  = cv_sqlgl_appl_name
--      AND      gps.adjustment_period_flag = cv_adjustment_flag
--      AND      gps.closing_status         = cv_status_open
--      GROUP BY gps.period_year
--    );
--    --==============================================================
--    --会計年数が1の場合、オープンしている会計年度の翌年を処理対象とする
--    --==============================================================
--    IF( gn_account_year = cn_1 ) THEN
--      SELECT   gps.period_year + 1                               -- 処理対象会計年度
--      INTO     gn_target_account_year
--      FROM     gl_period_statuses           gps
--             , fnd_application              fa
--      WHERE    gps.application_id         = fa.application_id
--      AND      gps.set_of_books_id        = gv_set_of_books_id
--      AND      fa.application_short_name  = cv_sqlgl_appl_name
--      AND      gps.adjustment_period_flag = cv_adjustment_flag
--      AND      gps.closing_status         = cv_status_open
--      GROUP BY gps.period_year;
--    --==============================================================
--    --会計年数が2の場合、大きい方の年度を処理対象とする
--    --==============================================================
--    ELSIF( gn_account_year = cn_2 ) THEN
--      SELECT MAX( period_year )
--      INTO   gn_target_account_year
--      FROM( 
--        SELECT   gps.period_year                                 -- 処理対象会計年度
--        FROM     gl_period_statuses           gps
--               , fnd_application              fa
--        WHERE    gps.application_id         = fa.application_id
--        AND      gps.set_of_books_id        = gv_set_of_books_id
--        AND      fa.application_short_name  = cv_sqlgl_appl_name
--        AND      gps.adjustment_period_flag = cv_adjustment_flag
--        AND      gps.closing_status         = cv_status_open
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
--      lv_msg     := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_name
--                    , iv_name         => cv_err_msg_00057
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f( 
--                      in_which        => FND_FILE.OUTPUT    -- 出力区分
--                    , iv_message      => lv_msg             -- メッセージ
--                    , in_new_line     => 0                  -- 改行
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 有効会計期間取得エラー ***
--    WHEN effective_expt THEN
--      lv_msg     := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_name
--                    , iv_name         => cv_err_msg_00059
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f( 
--                      in_which        => FND_FILE.OUTPUT    -- 出力区分
--                    , iv_message      => lv_msg             -- メッセージ
--                    , in_new_line     => 0                  -- 改行
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END get_target_acct_year;
----
--  /**********************************************************************************
--   * Procedure Name   : init
--   * Description      : 初期処理(A-1)
--   ***********************************************************************************/
--  PROCEDURE init(
--    ov_errbuf          OUT VARCHAR2     --エラー・メッセージ
--  , ov_retcode         OUT VARCHAR2     --リターン・コード
--  , ov_errmsg          OUT VARCHAR2     --ユーザー・エラー・メッセージ
--  , in_file_id         IN  NUMBER       --ファイルID
--  , iv_format_pattern  IN  VARCHAR2     --フォーマットパターン
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'init';    --プログラム名
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
--    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
--    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
--    lv_msg           VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
--    lv_profile_name  VARCHAR2(50)   DEFAULT NULL;               --プロファイル名称変数
--    lb_retcode       BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
--    -- =======================
--    -- ローカル例外
--    -- =======================
--    get_profile_expt EXCEPTION;   --カスタム･プロファイル取得の例外処理
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- コンカレントプログラム入力項目をメッセージ出力
--    -- =============================================================================
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxcok_appl_name
--              , iv_name         => cv_message_00016
--              , iv_token_name1  => cv_token_file_id
--              , iv_token_value1 => TO_CHAR( in_file_id )
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT   --出力区分
--                  , iv_message  => lv_msg            --メッセージ
--                  , in_new_line => 0                 --改行
--                  );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.LOG      --出力区分
--                  , iv_message  => lv_msg            --メッセージ
--                  , in_new_line => 0                 --改行
--                  );
----
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxcok_appl_name
--              , iv_name         => cv_message_00017
--              , iv_token_name1  => cv_token_format
--              , iv_token_value1 => iv_format_pattern
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT   --出力区分
--                  , iv_message  => lv_msg            --メッセージ
--                  , in_new_line => 1                 --改行
--                  );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.LOG      --出力区分
--                  , iv_message  => lv_msg            --メッセージ
--                  , in_new_line => 2                 --改行
--                  );
--    -- =============================================================================
--    -- プロファイルを取得(会計帳簿ID)
--    -- =============================================================================
--    gv_set_of_books_id := FND_PROFILE.VALUE( cv_set_of_bks_id );
----
--    IF ( gv_set_of_books_id IS NULL ) THEN
--      lv_profile_name := cv_set_of_bks_id;
--      RAISE get_profile_expt;
--    END IF;
--    -- =============================================================================
--    -- プロファイルを取得(会社コード)
--    -- =============================================================================
--    gv_company_code := FND_PROFILE.VALUE( cv_company_code );
----
--    IF ( gv_company_code IS NULL ) THEN
--      lv_profile_name := cv_company_code;
--      RAISE get_profile_expt;
--    END IF;
----
--  EXCEPTION
--    -- *** プロファイル取得エラー ***
--    WHEN get_profile_expt THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_00003
--                , iv_token_name1  => cv_token_profile
--                , iv_token_value1 => lv_profile_name
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END init;
----
--  /**********************************************************************************
--   * Procedure Name   : submain
--   * Description      : メイン処理プロシージャ
--   **********************************************************************************/
--  PROCEDURE submain(
--    ov_errbuf         OUT VARCHAR2     --エラー・メッセージ
--  , ov_retcode        OUT VARCHAR2     --リターン・コード
--  , ov_errmsg         OUT VARCHAR2     --ユーザー・エラー・メッセージ
--  , in_file_id        IN  NUMBER       --ファイルID
--  , iv_format_pattern IN  VARCHAR2     --フォーマットパターン
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name  CONSTANT VARCHAR2(50) := 'submain';   --プログラム名
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
--    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
--    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
--    lb_retcode   BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- 初期処理(A-1)の呼出し
--    -- =============================================================================
--    init(
--      ov_errbuf         => lv_errbuf
--    , ov_retcode        => lv_retcode
--    , ov_errmsg         => lv_errmsg
--    , in_file_id        => in_file_id
--    , iv_format_pattern => iv_format_pattern
--    );
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- =============================================================================
--    -- 処理対象会計年度取得(A-2)の呼出し
--    -- =============================================================================
--    get_target_acct_year(
--      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
--    , ov_retcode => lv_retcode                         -- リターン・コード
--    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- =============================================================================
--    -- 予算年度重複データ削除(A-3)の呼出し
--    -- =============================================================================
--    del_acct_year_dupl_data(
--      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
--    , ov_retcode => lv_retcode                         -- リターン・コード
--    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- =============================================================================
--    -- ファイルデータ取得(A-4)の呼出し
--    -- =============================================================================
--    get_file_data(
--      ov_errbuf  => lv_errbuf
--    , ov_retcode => lv_retcode
--    , ov_errmsg  => lv_errmsg
--    , in_file_id => in_file_id
--    );
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- =============================================================================
--    -- 処理データ削除(A-8)の呼出し
--    -- =============================================================================
--    del_mrp_file_ul_interface(
--      ov_errbuf  => lv_errbuf
--    , ov_retcode => lv_retcode
--    , ov_errmsg  => lv_errmsg
--    , in_file_id => in_file_id
--    );
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- =============================================================================
--    -- 妥当性チェックでエラーが発生した場合、ステータスをエラーに設定
--    -- =============================================================================
--    IF ( gv_chk_code = cv_status_continue ) THEN
--      ov_retcode := cv_status_error;
--    END IF;
--  EXCEPTION
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END submain;
----
--  /**********************************************************************************
--   * Procedure Name   : main
--   * Description      : コンカレント実行ファイル登録プロシージャ
--   **********************************************************************************/
--  PROCEDURE main(
--    errbuf            OUT  VARCHAR2    --エラーメッセージ
--  , retcode           OUT  VARCHAR2    --エラーコード
--  , iv_file_id        IN   VARCHAR2    --ファイルID
--  , iv_format_pattern IN   VARCHAR2    --フォーマットパターン
--  )
--  IS
--    -- =======================
--    -- ローカル定数
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'main';    --プログラム名
--    -- =======================
--    -- ローカル変数
--    -- =======================
--    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
--    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
--    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
--    lv_msg           VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
--    lv_message_code  VARCHAR2(500)  DEFAULT NULL;               --メッセージコード
--    lb_retcode       BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
--    ln_file_id       NUMBER         DEFAULT 0;                  --ファイルID
----
--  BEGIN
--    ln_file_id := TO_NUMBER( iv_file_id );
--    -- =============================================================================
--    -- コンカレントヘッダメッセージ出力関数の呼び出し
--    -- =============================================================================
--    xxccp_common_pkg.put_log_header(
--      ov_retcode => lv_retcode
--    , ov_errbuf  => lv_errbuf
--    , ov_errmsg  => lv_errmsg
--    );
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_api_expt;
--    END IF;
--    -- =============================================================================
--    -- submainの呼出し
--    -- =============================================================================
--    submain(
--      ov_errbuf         => lv_errbuf
--    , ov_retcode        => lv_retcode
--    , ov_errmsg         => lv_errmsg
--    , in_file_id        => ln_file_id
--    , iv_format_pattern => iv_format_pattern
--    );
--    -- =============================================================================
--    -- エラー出力
--    -- =============================================================================
--    IF ( lv_retcode = cv_status_error ) THEN
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_errmsg         --メッセージ
--                    , in_new_line => 1                 --改行
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG      --出力区分
--                    , iv_message  => lv_errbuf         --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--    END IF;
--    -- =============================================================================
--    -- 対象件数出力
--    -- =============================================================================
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxccp_appl_name
--              , iv_name         => cv_message_90000
--              , iv_token_name1  => cv_token_count
--              , iv_token_value1 => gn_target_cnt
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT     --出力区分
--                  , iv_message  => lv_msg              --メッセージ
--                  , in_new_line => 0                   --改行
--                  );
--    -- =============================================================================
--    -- 成功件数出力
--    -- =============================================================================
--    -- *** リターンコードがエラーの場合、成功件数を'0'件にする ***
--    IF ( lv_retcode = cv_status_error ) THEN
--      gn_normal_cnt := cn_0;
--    END IF;
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxccp_appl_name
--              , iv_name         => cv_message_90001
--              , iv_token_name1  => cv_token_count
--              , iv_token_value1 => gn_normal_cnt
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT     --出力区分
--                  , iv_message  => lv_msg              --メッセージ
--                  , in_new_line => 0                   --改行
--                  );
--    -- =============================================================================
--    -- エラー件数出力
--    -- =============================================================================
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxccp_appl_name
--              , iv_name         => cv_message_90002
--              , iv_token_name1  => cv_token_count
--              , iv_token_value1 => gn_error_cnt
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT     --出力区分
--                  , iv_message  => lv_msg              --メッセージ
--                  , in_new_line => 0                   --改行
--                  );
--    -- =============================================================================
--    -- 処理終了メッセージを出力
--    -- =============================================================================
--    IF ( lv_retcode = cv_status_normal ) THEN
--      lv_message_code := cv_message_90004;
--    ELSIF ( lv_retcode = cv_status_error ) THEN
--      lv_message_code := cv_message_90006;
--    END IF;
----
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application => cv_xxccp_appl_name
--              , iv_name        => lv_message_code
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT     --出力区分
--                  , iv_message  => lv_msg              --メッセージ
--                  , in_new_line => 0                   --改行
--                  );
--    --ステータスセット
--    retcode := lv_retcode;
--    --終了ステータスがエラーの場合はROLLBACK
--    IF ( retcode = cv_status_error ) THEN
--      ROLLBACK;
--      --IFテーブルにデータがある場合は削除
--      del_interface_at_error(
--        ov_errbuf   => lv_errbuf
--      , ov_retcode  => lv_retcode
--      , ov_errmsg   => lv_errmsg
--      , in_file_id  => ln_file_id
--      );
--    END IF;
--    --エラー時IFデータ削除処理用エラー出力とROLLBACKを行う
--    IF ( lv_retcode = cv_status_error ) THEN
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_errmsg         --メッセージ
--                    , in_new_line => 1                 --改行
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG      --出力区分
--                    , iv_message  => lv_errbuf         --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ROLLBACK;
--    END IF;
--    --エラー処理でも処理の確定をする。
--    COMMIT;
--  EXCEPTION
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
--      retcode := cv_status_error;
--      ROLLBACK;
--      --IFテーブルにデータがある場合は削除
--      del_interface_at_error(
--        ov_errbuf   => lv_errbuf
--      , ov_retcode  => lv_retcode
--      , ov_errmsg   => lv_errmsg
--      , in_file_id  => ln_file_id
--      );
--      --エラー時IFデータ削除処理用エラー出力とROLLBACKを行う
--      IF ( lv_retcode = cv_status_error ) THEN
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --出力区分
--                      , iv_message  => lv_errmsg         --メッセージ
--                      , in_new_line => 1                 --改行
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.LOG      --出力区分
--                      , iv_message  => lv_errbuf         --メッセージ
--                      , in_new_line => 0                 --改行
--                      );
--        ROLLBACK;
--      END IF;
--      --エラー処理でも処理の確定をする。
--      COMMIT;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      retcode := cv_status_error;
--      ROLLBACK;
--      --IFテーブルにデータがある場合は削除
--      del_interface_at_error(
--        ov_errbuf   => lv_errbuf
--      , ov_retcode  => lv_retcode
--      , ov_errmsg   => lv_errmsg
--      , in_file_id  => ln_file_id
--      );
--      --エラー時IFデータ削除処理用エラー出力とROLLBACKを行う
--      IF ( lv_retcode = cv_status_error ) THEN
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --出力区分
--                      , iv_message  => lv_errmsg         --メッセージ
--                      , in_new_line => 1                 --改行
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.LOG      --出力区分
--                      , iv_message  => lv_errbuf         --メッセージ
--                      , in_new_line => 0                 --改行
--                      );
--        ROLLBACK;
--      END IF;
--      --エラー処理でも処理の確定をする。
--      COMMIT;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      retcode := cv_status_error;
--      ROLLBACK;
--      --IFテーブルにデータがある場合は削除
--      del_interface_at_error(
--        ov_errbuf   => lv_errbuf
--      , ov_retcode  => lv_retcode
--      , ov_errmsg   => lv_errmsg
--      , in_file_id  => ln_file_id
--      );
--      --エラー時IFデータ削除処理用エラー出力とROLLBACKを行う
--      IF ( lv_retcode = cv_status_error ) THEN
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --出力区分
--                      , iv_message  => lv_errmsg         --メッセージ
--                      , in_new_line => 1                 --改行
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.LOG      --出力区分
--                      , iv_message  => lv_errbuf         --メッセージ
--                      , in_new_line => 0                 --改行
--                      );
--        ROLLBACK;
--      END IF;
--      --エラー処理でも処理の確定をする。
--      COMMIT;
--  END main;
--
  -- ===============================
  -- グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(100)  := 'XXCOK022A01C';  -- パッケージ名
--
  -- ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_error;   -- 異常:2
--
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER         := FND_GLOBAL.USER_ID;          -- CREATED_BY
--  cd_creation_date          CONSTANT DATE           := SYSDATE;                     -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER         := FND_GLOBAL.USER_ID;          -- LAST_UPDATED_BY
--  cd_last_update_date       CONSTANT DATE           := SYSDATE;                     -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER         := FND_GLOBAL.LOGIN_ID;         -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER         := FND_GLOBAL.CONC_REQUEST_ID;  -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER         := FND_GLOBAL.PROG_APPL_ID;     -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER         := FND_GLOBAL.CONC_PROGRAM_ID;  -- PROGRAM_ID
--  cd_program_update_date    CONSTANT DATE           := SYSDATE;                     -- PROGRAM_UPDATE_DATE  
--
  -- アプリケーション短縮名
  cv_appl_name_sqlgl        CONSTANT VARCHAR2(10)   := 'SQLGL';
  cv_appl_name_xxccp        CONSTANT VARCHAR2(10)   := 'XXCCP';
  cv_appl_name_xxcok        CONSTANT VARCHAR2(10)   := 'XXCOK';
--
  --プロファイル
  cv_set_of_bks_id           CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';          -- 会計帳簿ID
  cv_company_code            CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF1_COMPANY_CODE';  -- 会社コード
  cv_keep_period             CONSTANT VARCHAR2(50)  := 'XXCOK1_BUDGET_KEEP_PERIOD'; -- 販手販協予算保持期間
--
  -- クイックコード
  cv_lookup_type_upload_file CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';    -- ファイルアップロード情報
  cv_enabled_flag_y          CONSTANT VARCHAR2(50)  := 'Y';                         -- 有効フラグ：有効
--
  -- 会計カレンダー／会計期間ステータス
  cv_adj_flag_no            CONSTANT gl_period_statuses.adjustment_period_flag%TYPE := 'N'; -- 調整期間フラグ：調整期間以外
  cv_period_status_open     CONSTANT gl_period_statuses.closing_status%TYPE         := 'O'; -- ステータス    ：オープン
--
  -- アップロードファイル：項目インデックス
  cn_idx_budget_year        CONSTANT PLS_INTEGER    :=  1;  -- 予算年度
  cn_idx_base_code          CONSTANT PLS_INTEGER    :=  2;  -- 拠点コード
  cn_idx_corp_code          CONSTANT PLS_INTEGER    :=  3;  -- 企業コード
  cn_idx_sales_outlets_code CONSTANT PLS_INTEGER    :=  4;  -- 問屋帳合先コード
  cn_idx_acct_code          CONSTANT PLS_INTEGER    :=  5;  -- 勘定科目コード
  cn_idx_sub_acct_code      CONSTANT PLS_INTEGER    :=  6;  -- 補助科目コード
  cn_idx_month_01           CONSTANT PLS_INTEGER    :=  7;  -- 月度_01
  cn_idx_amount_01          CONSTANT PLS_INTEGER    :=  8;  -- 金額_01
  cn_idx_month_02           CONSTANT PLS_INTEGER    :=  9;  -- 月度_02
  cn_idx_amount_02          CONSTANT PLS_INTEGER    := 10;  -- 金額_02
  cn_idx_month_03           CONSTANT PLS_INTEGER    := 11;  -- 月度_03
  cn_idx_amount_03          CONSTANT PLS_INTEGER    := 12;  -- 金額_03
  cn_idx_month_04           CONSTANT PLS_INTEGER    := 13;  -- 月度_04
  cn_idx_amount_04          CONSTANT PLS_INTEGER    := 14;  -- 金額_04
  cn_idx_month_05           CONSTANT PLS_INTEGER    := 15;  -- 月度_05
  cn_idx_amount_05          CONSTANT PLS_INTEGER    := 16;  -- 金額_05
  cn_idx_month_06           CONSTANT PLS_INTEGER    := 17;  -- 月度_06
  cn_idx_amount_06          CONSTANT PLS_INTEGER    := 18;  -- 金額_06
  cn_idx_month_07           CONSTANT PLS_INTEGER    := 19;  -- 月度_07
  cn_idx_amount_07          CONSTANT PLS_INTEGER    := 20;  -- 金額_07
  cn_idx_month_08           CONSTANT PLS_INTEGER    := 21;  -- 月度_08
  cn_idx_amount_08          CONSTANT PLS_INTEGER    := 22;  -- 金額_08
  cn_idx_month_09           CONSTANT PLS_INTEGER    := 23;  -- 月度_09
  cn_idx_amount_09          CONSTANT PLS_INTEGER    := 24;  -- 金額_09
  cn_idx_month_10           CONSTANT PLS_INTEGER    := 25;  -- 月度_10
  cn_idx_amount_10          CONSTANT PLS_INTEGER    := 26;  -- 金額_10
  cn_idx_month_11           CONSTANT PLS_INTEGER    := 27;  -- 月度_11
  cn_idx_amount_11          CONSTANT PLS_INTEGER    := 28;  -- 金額_11
  cn_idx_month_12           CONSTANT PLS_INTEGER    := 29;  -- 月度_12
  cn_idx_amount_12          CONSTANT PLS_INTEGER    := 30;  -- 金額_12
--
  -- 妥当性チェック：桁数（バイト数）
  cn_len_budget_year        CONSTANT NUMBER         :=  4;  -- 予算年度
  cn_len_base_code          CONSTANT NUMBER         :=  4;  -- 拠点コード
  cn_len_corp_code          CONSTANT NUMBER         :=  6;  -- 企業コード
  cn_len_sales_outlets_code CONSTANT NUMBER         :=  9;  -- 問屋帳合先コード
  cn_len_acct_code          CONSTANT NUMBER         :=  5;  -- 勘定科目コード
  cn_len_sub_acct_code      CONSTANT NUMBER         :=  5;  -- 補助科目コード
  cn_len_month              CONSTANT NUMBER         :=  2;  -- 月度
  cn_len_amount             CONSTANT NUMBER         := 12;  -- 金額
--
  -- 書式
  cv_format_yyyymmdd        CONSTANT VARCHAR2(50)   := 'FXRRRR/MM/DD';
  cv_format_yyyymm          CONSTANT VARCHAR2(50)   := 'RRRRMM';
  cv_format_mm              CONSTANT VARCHAR2(50)   := 'MM';
--
  -- メッセージ定義
  cv_output                 CONSTANT VARCHAR2(6)    := 'OUTPUT';            -- ヘッダログ出力
  cv_msg_part               CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)    := '.';
--
  cv_message_90000          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
  cv_message_90001          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
  cv_message_90003          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90003';  -- スキップ件数出力
  cv_message_90002          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
  cv_message_90004          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
  cv_message_90005          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
  cv_message_90006          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90006';  -- エラー終了全ロールバックメッセージ
--
  cv_message_00016          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00016';  -- ファイルID出力用メッセージ
  cv_message_00017          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00017';  -- フォーマットパターン出力用メッセージ
  cv_message_00022          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00022';  -- 業務日付メッセージ
  cv_message_00106          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00106';  -- ファイルアップロード名称出力用メッセージ
  cv_message_00006          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00006';  -- ファイル名出力用メッセージ
--
  cv_err_msg_00028          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00028';  -- 業務処理日付取得エラー
  cv_err_msg_00003          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00003';  -- プロファイル取得エラー
  cv_err_msg_00061          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00061';  -- IFテーブルロック取得エラー
  cv_err_msg_00041          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00041';  -- BLOBデータ変換エラー
  cv_err_msg_00039          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00039';  -- 空ファイルエラーメッセージ
  cv_err_msg_10417          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10417';  -- 予算年度項目NULLエラー
  cv_err_msg_10479          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10479';  -- 予算年度半角数字チェックエラー
  cv_err_msg_10480          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10480';  -- 予算年度桁数チェックエラー
  cv_err_msg_10481          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10481';  -- 会計期間オープンチェックエラー
  cv_err_msg_10418          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10418';  -- 拠点コード項目NULLエラー
  cv_err_msg_10135          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10135';  -- 拠点コード半角英数字チェックエラー
  cv_err_msg_10126          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10126';  -- 拠点コード桁数チェックエラー
  cv_err_msg_10419          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10419';  -- 企業コード項目NULLエラー
  cv_err_msg_10136          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10136';  -- 企業コード半角英数字チェックエラー
  cv_err_msg_10127          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10127';  -- 企業コード桁数チェックエラー
  cv_err_msg_10420          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10420';  -- 問屋帳合先コード項目NULLエラー
  cv_err_msg_10137          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10137';  -- 問屋帳合先コード半角英数字チェックエラー
  cv_err_msg_10125          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10125';  -- 問屋帳合先コード桁数チェックエラー
  cv_err_msg_10421          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10421';  -- 勘定科目コード項目NULLエラー
  cv_err_msg_10138          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10138';  -- 勘定科目コード半角英数字チェックエラー
  cv_err_msg_10128          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10128';  -- 勘定科目コード桁数チェックエラー
  cv_err_msg_10422          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10422';  -- 補助科目コード項目NULLエラー
  cv_err_msg_10139          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10139';  -- 補助科目コード半角英数字チェックエラー
  cv_err_msg_10129          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10129';  -- 補助科目コード桁数チェックエラー
  cv_err_msg_10423          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10423';  -- 月度(n番目)必須チェックエラー
  cv_err_msg_10482          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10482';  -- 月度(n番目)半角数字チェックエラー
  cv_err_msg_10483          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10483';  -- 月度(n番目)桁数チェックエラー
  cv_err_msg_10425          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10425';  -- 月度(n番目)日付チェックエラー
  cv_err_msg_10424          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10424';  -- 予算金額(n番目)必須チェックエラー
  cv_err_msg_10123          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10123';  -- 予算金額(n番目)半角数字チェックエラー
  cv_err_msg_10130          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10130';  -- 予算金額(n番目)桁数チェックエラー
  cv_err_msg_10484          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10484';  -- アップロード情報登録エラー
  cv_err_msg_10107          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10107';  -- データロックエラー(販手販協予算テーブル)
  cv_err_msg_10108          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10108';  -- 予算年度重複データ削除エラー
  cv_err_msg_10449          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10449';  -- 販手販協予算登録エラー
  cv_err_msg_10111          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10111';  -- 保持期間外予算削除エラー
  cv_err_msg_00062          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00062';  -- ファイルアップロードIFテーブル削除エラー
--
  -- メッセージトークン定義
  cv_token_file_id          CONSTANT VARCHAR2(50)   := 'FILE_ID';           -- ファイルID
  cv_token_format           CONSTANT VARCHAR2(50)   := 'FORMAT';            -- フォーマットパターン
  cv_token_business_date    CONSTANT VARCHAR2(50)   := 'BUSINESS_DATE';     -- 業務日付
  cv_token_profile          CONSTANT VARCHAR2(50)   := 'PROFILE';           -- プロファイル名
  cv_token_upload_object    CONSTANT VARCHAR2(50)   := 'UPLOAD_OBJECT';     -- ファイルアップロード名称
  cv_token_file_name        CONSTANT VARCHAR2(50)   := 'FILE_NAME';         -- ファイル名称
  cv_token_row_num          CONSTANT VARCHAR2(50)   := 'ROW_NUM';           -- 行番号
  cv_token_budget_year      CONSTANT VARCHAR2(50)   := 'BUDGET_YEAR';       -- 予算年度
  cv_token_occurs           CONSTANT VARCHAR2(50)   := 'OCCURS';            -- 繰り返し項目のインデックス
  cv_token_month            CONSTANT VARCHAR2(50)   := 'MONTH';             -- 月度
  cv_token_count            CONSTANT VARCHAR2(50)   := 'COUNT';             -- 処理件数
--
  -- 情報系連携ステータス
  cv_dwh_if_status_yet      CONSTANT VARCHAR2(1)    := '0';                 -- 0:未連携
--
  -- その他
  cn_0                      CONSTANT NUMBER         := 0;
  cn_1                      CONSTANT NUMBER         := 1;
  cn_2                      CONSTANT NUMBER         := 2;
  cv_comma                  CONSTANT VARCHAR2(1)    := ',';
  cv_0                      CONSTANT VARCHAR2(1)    := '0';
-- 2010/08/24 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi ADD START
  cv_hyphen                 CONSTANT VARCHAR2(1)    := '-';
-- 2010/08/24 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi ADD END
--
  -- =============================================================================
  -- グローバルレコード型
  -- =============================================================================
--
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_target_cnt             PLS_INTEGER DEFAULT 0;  -- 対象件数
  gn_normal_cnt             PLS_INTEGER DEFAULT 0;  -- 正常件数
  gn_warn_cnt               PLS_INTEGER DEFAULT 0;  -- スキップ件数
  gn_error_cnt              PLS_INTEGER DEFAULT 0;  -- エラー件数
--
  gd_operation_date         DATE                                        DEFAULT NULL; -- 業務処理日付
  gn_set_of_books_id        NUMBER                                      DEFAULT NULL; -- 会計帳簿ID
  gt_company_code           xxcok_tmp_022a01c_upload.company_code%TYPE  DEFAULT NULL; -- 会社コード
  gn_keep_period            NUMBER                                      DEFAULT NULL; -- 販手販協予算保持期間
  gt_next_period_year       xxcok_bm_support_budget.budget_year%TYPE    DEFAULT NULL; -- 翌会計年度
  gn_keep_period_year       NUMBER                                      DEFAULT NULL; -- 販協予算保持期間（年度）
--
  -- ===============================
  -- グローバル例外
  -- ===============================
  global_process_expt       EXCEPTION;  -- 処理部共通例外
  global_api_expt           EXCEPTION;  -- 共通関数例外
  global_api_others_expt    EXCEPTION;  -- 共通関数OTHERS例外
  global_lock_expt          EXCEPTION;  -- ロック例外
--
  -- プラグマ
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : del_mrp_file_ul_interface
   * Description      : ファイルアップロードIFの削除(A-9)
   ***********************************************************************************/
  PROCEDURE del_mrp_file_ul_interface(
      ov_errbuf   OUT VARCHAR2                          -- エラー・メッセージ
    , ov_retcode  OUT VARCHAR2                          -- リターン・コード
    , ov_errmsg   OUT VARCHAR2                          -- ユーザー・エラー・メッセージ
    , iv_file_id  IN  VARCHAR2                          -- ファイルID
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'del_mrp_file_ul_interface';  -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    --===============================
    -- ロック取得用カーソル
    --===============================
    CURSOR lock_xmfui_cur
    IS
      SELECT  xmfui.file_id AS file_id  -- ファイルID
      FROM    xxccp_mrp_file_ul_interface xmfui -- ファイルアップロードIFテーブル
      WHERE   xmfui.file_id =  TO_NUMBER( iv_file_id )
      FOR UPDATE OF xmfui.file_id NOWAIT
    ;
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- ファイルアップロードIFの削除
    --===============================================
    <<delete_loop>>
    FOR lock_xmfui_rec IN lock_xmfui_cur LOOP
      BEGIN
        DELETE
        FROM    xxccp_mrp_file_ul_interface xmfui -- ファイルアップロードIFテーブル
        WHERE   xmfui.file_id =  lock_xmfui_rec.file_id
        ;
--
      EXCEPTION
        ----------------------------------------------------------
        -- OTHERS例外ハンドラ
        ----------------------------------------------------------
        WHEN OTHERS THEN
            lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
            lb_retcode := xxcok_common_pkg.put_message_f(
                              in_which        => FND_FILE.LOG     -- 出力区分
                            , iv_message      => lv_out_msg       -- メッセージ
                            , in_new_line     => cn_0             -- 改行
                          );
--
          lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcok
                          , iv_name         => cv_err_msg_00062
                          , iv_token_name1  => cv_token_file_id
                          , iv_token_value1 => TO_CHAR( lock_xmfui_rec.file_id )
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.LOG     -- 出力区分
                          , iv_message      => lv_out_msg       -- メッセージ
                          , in_new_line     => cn_0             -- 改行
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.OUTPUT  -- 出力区分
                          , iv_message      => lv_out_msg       -- メッセージ
                          , in_new_line     => cn_0             -- 改行
                        );
          RAISE global_process_expt;
      END;
    END LOOP delete_loop;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ロック取得例外ハンドラ
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00061
                      , iv_token_name1  => cv_token_file_id
                      , iv_token_value1 => iv_file_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END del_mrp_file_ul_interface;
--
  /**********************************************************************************
   * Procedure Name   : purge_bm_support_budget
   * Description      : パージ処理(A-8)
   ***********************************************************************************/
  PROCEDURE purge_bm_support_budget(
      ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ
    , ov_retcode  OUT VARCHAR2  -- リターン・コード
    , ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'purge_bm_support_budget';  -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    --===============================
    -- ロック取得用カーソル
    --===============================
    CURSOR lock_xbsb_cur
    IS
      SELECT  xbsb.bm_support_budget_id AS bm_support_budget_id -- 販手販協予算ID
      FROM    xxcok_bm_support_budget xbsb  -- 販手販協予算
      WHERE   TO_NUMBER( xbsb.budget_year ) <= gn_keep_period_year
      FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT
    ;
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- パージ処理
    --===============================================
    <<purge_loop>>
    FOR lock_xbsb_rec IN lock_xbsb_cur LOOP
      BEGIN
        DELETE
        FROM    xxcok_bm_support_budget xbsb  -- 販手販協予算
        WHERE   xbsb.bm_support_budget_id =  lock_xbsb_rec.bm_support_budget_id
        ;
--
      EXCEPTION
        ----------------------------------------------------------
        -- OTHERS例外ハンドラ
        ----------------------------------------------------------
        WHEN OTHERS THEN
            lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
            lb_retcode := xxcok_common_pkg.put_message_f(
                              in_which        => FND_FILE.LOG     -- 出力区分
                            , iv_message      => lv_out_msg       -- メッセージ
                            , in_new_line     => cn_0             -- 改行
                          );
--
          lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcok
                          , iv_name         => cv_err_msg_10111
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.LOG     -- 出力区分
                          , iv_message      => lv_out_msg       -- メッセージ
                          , in_new_line     => cn_0             -- 改行
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.OUTPUT  -- 出力区分
                          , iv_message      => lv_out_msg       -- メッセージ
                          , in_new_line     => cn_0             -- 改行
                        );
          RAISE global_process_expt;
      END;
    END LOOP purge_loop;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ロック取得例外ハンドラ
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10107
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END purge_bm_support_budget;
--
  /**********************************************************************************
   * Procedure Name   : ins_bm_support_budget
   * Description      : 販手販協予算情報の登録(A-7)
   ***********************************************************************************/
  PROCEDURE ins_bm_support_budget(
      ov_errbuf   OUT VARCHAR2                          -- エラー・メッセージ
    , ov_retcode  OUT VARCHAR2                          -- リターン・コード
    , ov_errmsg   OUT VARCHAR2                          -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'ins_bm_support_budget';  -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    --===============================
    -- 販手販協予算用カーソル
    --===============================
    CURSOR  xt022a01c_cur
    IS
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_01    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_01      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_02    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_02      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_03    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_03      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_04    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_04      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_05    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_05      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_06    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_06      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_07    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_07      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_08    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_08      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_09    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_09      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_10    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_10      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_11    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_11      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- 行番号
              , xt022a01c.company_code       AS company_code        -- 会社コード
              , xt022a01c.budget_year        AS budget_year         -- 予算年度
              , xt022a01c.base_code          AS base_code           -- 拠点コード
              , xt022a01c.corp_code          AS corp_code           -- 企業コード
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- 問屋帳合先コード
              , xt022a01c.acct_code          AS acct_code           -- 勘定科目コード
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- 補助科目コード
              , xt022a01c.target_month_12    AS target_month        -- 対象年月
              , xt022a01c.budget_amt_12      AS budget_amt          -- 予算金額
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
    ;
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- 販手販協予算の登録
    --===============================================
    <<insert_loop>>
    FOR xt022a01c_rec IN xt022a01c_cur LOOP
      BEGIN
        INSERT INTO xxcok_bm_support_budget(
            bm_support_budget_id    -- 販手販協予算ID
          , company_code            -- 会社コード
          , budget_year             -- 予算年度
          , base_code               -- 拠点コード
          , corp_code               -- 企業コード
          , sales_outlets_code      -- 問屋帳合先コード
          , acct_code               -- 勘定科目コード
          , sub_acct_code           -- 補助科目コード
          , target_month            -- 月度(対象年月)
          , budget_amt              -- 予算金額
          , info_interface_status   -- 情報系連携ステータス
          , created_by              -- 作成者
          , creation_date           -- 作成日
          , last_updated_by         -- 最終更新者
          , last_update_date        -- 最終更新日
          , last_update_login       -- 最終更新ログイン
          , request_id              -- 要求ID
          , program_application_id  -- コンカレント・プログラム・アプリケーションID
          , program_id              -- プログラムID
          , program_update_date     -- プログラム更新日
        ) VALUES (
            xxcok_bm_support_budget_s01.NEXTVAL -- bm_support_budget_id
          , xt022a01c_rec.company_code          -- company_code
          , xt022a01c_rec.budget_year           -- budget_year
          , xt022a01c_rec.base_code             -- base_code
          , xt022a01c_rec.corp_code             -- corp_code
          , xt022a01c_rec.sales_outlets_code    -- sales_outlets_code
          , xt022a01c_rec.acct_code             -- acct_code
          , xt022a01c_rec.sub_acct_code         -- sub_acct_code
          , xt022a01c_rec.target_month          -- target_month
          , xt022a01c_rec.budget_amt            -- budget_amt
          , cv_dwh_if_status_yet                -- info_interface_status
          , cn_created_by                       -- created_by
          , SYSDATE                             -- creation_date
          , cn_last_updated_by                  -- last_updated_by
          , SYSDATE                             -- last_update_date
          , cn_last_update_login                -- last_update_login
          , cn_request_id                       -- request_id
          , cn_program_application_id           -- program_application_id
          , cn_program_id                       -- program_id
          , SYSDATE                             -- program_update_date
        );
--
      EXCEPTION
        ----------------------------------------------------------
        -- OTHERS例外ハンドラ
        ----------------------------------------------------------
        WHEN OTHERS THEN
          lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.LOG     -- 出力区分
                          , iv_message      => lv_out_msg       -- メッセージ
                          , in_new_line     => cn_0             -- 改行
                        );
--
          lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcok
                          , iv_name         => cv_err_msg_10449
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.LOG     -- 出力区分
                          , iv_message      => lv_out_msg       -- メッセージ
                          , in_new_line     => cn_0             -- 改行
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.OUTPUT  -- 出力区分
                          , iv_message      => lv_out_msg       -- メッセージ
                          , in_new_line     => cn_0             -- 改行
                        );
          RAISE global_process_expt;
      END;
    END LOOP insert_loop;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END ins_bm_support_budget;
--
  /**********************************************************************************
   * Procedure Name   : del_duplicate_budget_year
   * Description      : 重複予算年度データの削除(A-6)
   ***********************************************************************************/
  PROCEDURE del_duplicate_budget_year(
      ov_errbuf   OUT VARCHAR2                          -- エラー・メッセージ
    , ov_retcode  OUT VARCHAR2                          -- リターン・コード
    , ov_errmsg   OUT VARCHAR2                          -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'del_duplicate_budget_year';  -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    --===============================
    -- ロック取得用カーソル
    --===============================
    CURSOR  lock_duplicate_budget_year_cur
    IS
      SELECT  xbsb.bm_support_budget_id -- 販手販協予算ID
      FROM    xxcok_bm_support_budget xbsb  -- 販手販協予算
      WHERE   EXISTS( SELECT  'X'
                      FROM    xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
                      WHERE   xt022a01c.budget_year   =  xbsb.budget_year
                        AND   ROWNUM = 1
              )
      FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT
    ;
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- 重複予算年度のロック取得
    --===============================================
    OPEN  lock_duplicate_budget_year_cur;
    CLOSE lock_duplicate_budget_year_cur;
--
    --===============================================
    -- 重複予算年度の削除
    --===============================================
    BEGIN
      DELETE
      FROM    xxcok_bm_support_budget xbsb  -- 販手販協予算
      WHERE   EXISTS( SELECT  'X'
                      FROM    xxcok_tmp_022a01c_upload  xt022a01c -- 販手販協予算アップロード情報一時表
                      WHERE   xt022a01c.budget_year   =  xbsb.budget_year
                        AND   ROWNUM = 1
              )
      ;
--
    EXCEPTION
      ----------------------------------------------------------
      -- OTHERS例外ハンドラ
      ----------------------------------------------------------
      WHEN OTHERS THEN
          lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.LOG     -- 出力区分
                          , iv_message      => lv_out_msg       -- メッセージ
                          , in_new_line     => cn_0             -- 改行
                        );
--
        lv_out_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcok
                        , iv_name         => cv_err_msg_10108
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.LOG     -- 出力区分
                        , iv_message      => lv_out_msg       -- メッセージ
                        , in_new_line     => cn_0             -- 改行
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.OUTPUT  -- 出力区分
                        , iv_message      => lv_out_msg       -- メッセージ
                        , in_new_line     => cn_0             -- 改行
                      );
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ロック取得例外ハンドラ
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10107
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END del_duplicate_budget_year;
--
  /**********************************************************************************
   * Procedure Name   : ins_xxcok_tmp_022a01c
   * Description      : アップロード情報一時表の登録(A-5)
   ***********************************************************************************/
  PROCEDURE ins_xxcok_tmp_022a01c(
      ov_errbuf         OUT VARCHAR2                          -- エラー・メッセージ
    , ov_retcode        OUT VARCHAR2                          -- リターン・コード
    , ov_errmsg         OUT VARCHAR2                          -- ユーザー・エラー・メッセージ
    , in_row_num        IN  PLS_INTEGER                       -- 行番号
    , it_xt022a01c_rec  IN  xxcok_tmp_022a01c_upload%ROWTYPE  -- 販手販協予算情報
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'ins_xxcok_tmp_022a01c';  -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    INSERT INTO xxcok_tmp_022a01c_upload(
        row_num                 -- 行番号
      , company_code            -- 会社コード
      , budget_year             -- 予算年度
      , base_code               -- 拠点コード
      , corp_code               -- 企業コード
      , sales_outlets_code      -- 問屋帳合先コード
      , acct_code               -- 勘定科目コード
      , sub_acct_code           -- 補助科目コード
      , target_month_01         -- 対象年月_01
      , budget_amt_01           -- 予算金額_01
      , target_month_02         -- 対象年月_02
      , budget_amt_02           -- 予算金額_02
      , target_month_03         -- 対象年月_03
      , budget_amt_03           -- 予算金額_03
      , target_month_04         -- 対象年月_04
      , budget_amt_04           -- 予算金額_04
      , target_month_05         -- 対象年月_05
      , budget_amt_05           -- 予算金額_05
      , target_month_06         -- 対象年月_06
      , budget_amt_06           -- 予算金額_06
      , target_month_07         -- 対象年月_07
      , budget_amt_07           -- 予算金額_07
      , target_month_08         -- 対象年月_08
      , budget_amt_08           -- 予算金額_08
      , target_month_09         -- 対象年月_09
      , budget_amt_09           -- 予算金額_09
      , target_month_10         -- 対象年月_10
      , budget_amt_10           -- 予算金額_10
      , target_month_11         -- 対象年月_11
      , budget_amt_11           -- 予算金額_11
      , target_month_12         -- 対象年月_12
      , budget_amt_12           -- 予算金額_12
    ) VALUES (
        in_row_num                          -- row_num
      , gt_company_code                     -- company_code
      , it_xt022a01c_rec.budget_year        -- budget_year
      , it_xt022a01c_rec.base_code          -- base_code
      , it_xt022a01c_rec.corp_code          -- corp_code
      , it_xt022a01c_rec.sales_outlets_code -- sales_outlets_code
      , it_xt022a01c_rec.acct_code          -- acct_code
      , it_xt022a01c_rec.sub_acct_code      -- sub_acct_code
      , it_xt022a01c_rec.target_month_01    -- target_month_01
      , it_xt022a01c_rec.budget_amt_01      -- budget_amt_01
      , it_xt022a01c_rec.target_month_02    -- target_month_02
      , it_xt022a01c_rec.budget_amt_02      -- budget_amt_02
      , it_xt022a01c_rec.target_month_03    -- target_month_03
      , it_xt022a01c_rec.budget_amt_03      -- budget_amt_03
      , it_xt022a01c_rec.target_month_04    -- target_month_04
      , it_xt022a01c_rec.budget_amt_04      -- budget_amt_04
      , it_xt022a01c_rec.target_month_05    -- target_month_05
      , it_xt022a01c_rec.budget_amt_05      -- budget_amt_05
      , it_xt022a01c_rec.target_month_06    -- target_month_06
      , it_xt022a01c_rec.budget_amt_06      -- budget_amt_06
      , it_xt022a01c_rec.target_month_07    -- target_month_07
      , it_xt022a01c_rec.budget_amt_07      -- budget_amt_07
      , it_xt022a01c_rec.target_month_08    -- target_month_08
      , it_xt022a01c_rec.budget_amt_08      -- budget_amt_08
      , it_xt022a01c_rec.target_month_09    -- target_month_09
      , it_xt022a01c_rec.budget_amt_09      -- budget_amt_09
      , it_xt022a01c_rec.target_month_10    -- target_month_10
      , it_xt022a01c_rec.budget_amt_10      -- budget_amt_10
      , it_xt022a01c_rec.target_month_11    -- target_month_11
      , it_xt022a01c_rec.budget_amt_11      -- budget_amt_11
      , it_xt022a01c_rec.target_month_12    -- target_month_12
      , it_xt022a01c_rec.budget_amt_12      -- budget_amt_12
    )
    ;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
      ov_errbuf  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10484
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                      , iv_token_name2  => cv_token_budget_year
                      , iv_token_value2 => it_xt022a01c_rec.budget_year
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => ov_errbuf       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END ins_xxcok_tmp_022a01c;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_amount
   * Description      : 妥当性チェック：予算金額(A-4-8)
   ***********************************************************************************/
  PROCEDURE chk_data_amount(
      ov_errbuf   OUT VARCHAR2                                -- エラー・メッセージ
    , ov_retcode  OUT VARCHAR2                                -- リターン・コード
    , ov_errmsg   OUT VARCHAR2                                -- ユーザー・エラー・メッセージ
    , in_row_num  IN  PLS_INTEGER                             -- 行番号
    , in_occurs   IN  PLS_INTEGER                             -- 繰り返し項目のインデックス
    , iv_amount   IN  VARCHAR2                                -- 予算金額
    , ot_amount   OUT xxcok_bm_support_budget.budget_amt%TYPE -- 予算金額
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_amount'; -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lb_chk_number   BOOLEAN;                                  -- 共通関数戻り値
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
    ot_amount   := NULL;
--
    --===============================================
    -- 必須入力チェック
    --===============================================
    IF( iv_amount IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10424
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2010/08/24 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi REPAIR START
--    --===============================================
--    -- 半角数字チェック
--    --===============================================
--    lb_chk_number := xxccp_common_pkg.chk_number(
--                        iv_check_char => iv_amount
--                     );
    --===============================================
    -- 予算金額 数値チェック（マイナス金額可）
    --===============================================
    BEGIN
      --===============================================
      -- 半角数字 ハイフンチェック
      --===============================================
      lb_chk_number := xxccp_common_pkg.chk_number(
                          iv_check_char => REPLACE( iv_amount, cv_hyphen, NULL )
                       );
      lb_chk_number := NVL( lb_chk_number, FALSE ); -- 引数がNULLの場合、戻り値がNULLのため
      IF( lb_chk_number ) THEN
        --===============================================
        -- 数値変換チェック
        --===============================================
          ot_amount  := TO_NUMBER( iv_amount );
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.LOG     -- 出力区分
                        , iv_message      => lv_out_msg       -- メッセージ
                        , in_new_line     => cn_0             -- 改行
                      );
--
        lb_chk_number := FALSE;
    END;
    ot_amount  := NULL;
-- 2010/08/24 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi REPAIR END
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10123
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- 桁数チェック
    --===============================================
    IF( LENGTHB( iv_amount ) > cn_len_amount ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10130
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_amount  := TO_NUMBER( iv_amount );
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END chk_data_amount;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_month
   * Description      : 妥当性チェック：対象年月(A-4-7)
   ***********************************************************************************/
  PROCEDURE chk_data_month(
      ov_errbuf         OUT VARCHAR2                                  -- エラー・メッセージ
    , ov_retcode        OUT VARCHAR2                                  -- リターン・コード
    , ov_errmsg         OUT VARCHAR2                                  -- ユーザー・エラー・メッセージ
    , in_row_num        IN  PLS_INTEGER                               -- 行番号
    , in_occurs         IN  PLS_INTEGER                               -- 繰り返し項目のインデックス
    , it_budget_year    IN  xxcok_bm_support_budget.budget_year%TYPE  -- 予算年度
    , iv_month          IN  VARCHAR2                                  -- 月度
    , ot_target_month   OUT xxcok_bm_support_budget.target_month%TYPE -- 対象年月
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_month'; -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lb_chk_number   BOOLEAN;                                  -- 共通関数戻り値
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf         := NULL;
    ov_retcode        := cv_status_normal;
    ov_errmsg         := NULL;
    ot_target_month   := NULL;
--
    --===============================================
    -- 必須入力チェック
    --===============================================
    IF( iv_month IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10423
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 半角数字チェック
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_number(
                        iv_check_char => iv_month
                     );
--
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10482
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- 桁数チェック
    --===============================================
    IF( LENGTHB( iv_month ) > cn_len_month ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10483
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 会計カレンダーチェック
    --===============================================
    IF( it_budget_year IS NULL ) THEN
      -- 予算年度がNULLの場合には後続のチェックをしない
      RAISE global_process_expt;
    END IF;
--
    BEGIN
      SELECT  TO_CHAR( gp.start_date, cv_format_yyyymm )  AS target_month -- 会計期間開始日の年月
      INTO  ot_target_month -- 対象年月
      FROM    gl_sets_of_books  gsob  -- 会計帳簿マスタ
            , gl_periods        gp    -- 会計カレンダー
      WHERE   gsob.set_of_books_id                    =  gn_set_of_books_id
        AND   gp.period_set_name                      =  gsob.period_set_name
        AND   gp.period_year                          =  TO_NUMBER( it_budget_year )
        AND   TO_CHAR( gp.start_date, cv_format_mm )  =  LPAD( iv_month, cn_len_month, cv_0 )
        AND   gp.adjustment_period_flag               =  cv_adj_flag_no
        AND   ROWNUM = 1
      ;
--
      EXCEPTION
        ----------------------------------------------------------
        -- 会計カレンダー未登録
        ----------------------------------------------------------
        WHEN NO_DATA_FOUND THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcok
                          , iv_name         => cv_err_msg_10425
                          , iv_token_name1  => cv_token_occurs
                          , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                          , iv_token_name2  => cv_token_row_num
                          , iv_token_value2 => TO_CHAR( in_row_num )
                          , iv_token_name3  => cv_token_budget_year
                          , iv_token_value3 => TO_CHAR( it_budget_year )
                          , iv_token_name4  => cv_token_month
                          , iv_token_value4 => LPAD( iv_month, cn_len_month, cv_0 )
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.OUTPUT  -- 出力区分
                          , iv_message      => lv_out_msg       -- メッセージ
                          , in_new_line     => cn_0             -- 改行
                        );
          RAISE global_process_expt;
    END;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END chk_data_month;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_sub_acct_code
   * Description      : 妥当性チェック：補助科目コード(A-4-6)
   ***********************************************************************************/
  PROCEDURE chk_data_sub_acct_code(
      ov_errbuf         OUT VARCHAR2                                    -- エラー・メッセージ
    , ov_retcode        OUT VARCHAR2                                    -- リターン・コード
    , ov_errmsg         OUT VARCHAR2                                    -- ユーザー・エラー・メッセージ
    , in_row_num        IN  PLS_INTEGER                                 -- 行番号
    , it_acct_code      IN  xxcok_bm_support_budget.acct_code%TYPE      -- 勘定科目コード
    , iv_sub_acct_code  IN  VARCHAR2                                    -- 補助科目コード
    , ot_sub_acct_code  OUT xxcok_bm_support_budget.sub_acct_code%TYPE  -- 補助科目コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_sub_acct_code'; -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lb_chk_number   BOOLEAN;                                  -- 共通関数戻り値
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf         := NULL;
    ov_retcode        := cv_status_normal;
    ov_errmsg         := NULL;
    ot_sub_acct_code  := NULL;
--
    --===============================================
    -- 必須入力チェック
    --===============================================
    IF( iv_sub_acct_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10422
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 桁数チェック
    --===============================================
    IF( LENGTHB( iv_sub_acct_code ) <> cn_len_sub_acct_code ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10129
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;

    --===============================================
    -- 半角英数字（記号可）チェック
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_alphabet_number(
                        iv_check_char => iv_sub_acct_code
                     );
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10139
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_sub_acct_code  := iv_sub_acct_code;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END chk_data_sub_acct_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_acct_code
   * Description      : 妥当性チェック：勘定科目コード(A-4-5)
   ***********************************************************************************/
  PROCEDURE chk_data_acct_code(
      ov_errbuf     OUT VARCHAR2                                -- エラー・メッセージ
    , ov_retcode    OUT VARCHAR2                                -- リターン・コード
    , ov_errmsg     OUT VARCHAR2                                -- ユーザー・エラー・メッセージ
    , in_row_num    IN  PLS_INTEGER                             -- 行番号
    , iv_acct_code  IN  VARCHAR2                                -- 勘定科目コード
    , ot_acct_code  OUT xxcok_bm_support_budget.acct_code%TYPE  -- 勘定科目コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_acct_code'; -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lb_chk_number   BOOLEAN;                                  -- 共通関数戻り値
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf     := NULL;
    ov_retcode    := cv_status_normal;
    ov_errmsg     := NULL;
    ot_acct_code  := NULL;
--
    --===============================================
    -- 必須入力チェック
    --===============================================
    IF( iv_acct_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10421
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 半角英数字（記号可）チェック
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_alphabet_number(
                        iv_check_char => iv_acct_code
                     );
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10138
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- 桁数チェック
    --===============================================
    IF( LENGTHB( iv_acct_code ) <> cn_len_acct_code ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10128
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_acct_code  := iv_acct_code;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END chk_data_acct_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_sales_outlets_code
   * Description      : 妥当性チェック：問屋帳合先コード(A-4-4)
   ***********************************************************************************/
  PROCEDURE chk_data_sales_outlets_code(
      ov_errbuf             OUT VARCHAR2                                        -- エラー・メッセージ
    , ov_retcode            OUT VARCHAR2                                        -- リターン・コード
    , ov_errmsg             OUT VARCHAR2                                        -- ユーザー・エラー・メッセージ
    , in_row_num            IN  PLS_INTEGER                                     -- 行番号
    , iv_sales_outlets_code IN  VARCHAR2                                        -- 問屋帳合先コード
    , ot_sales_outlets_code OUT xxcok_bm_support_budget.sales_outlets_code%TYPE -- 問屋帳合先コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_sales_outlets_code';  -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lb_chk_number   BOOLEAN;                                  -- 共通関数戻り値
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf             := NULL;
    ov_retcode            := cv_status_normal;
    ov_errmsg             := NULL;
    ot_sales_outlets_code := NULL;
--
    --===============================================
    -- 必須入力チェック
    --===============================================
    IF( iv_sales_outlets_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10420
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 半角英数字（記号可）チェック
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_alphabet_number(
                        iv_check_char => iv_sales_outlets_code
                     );
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10137
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- 桁数チェック
    --===============================================
    IF( LENGTHB( iv_sales_outlets_code ) <> cn_len_sales_outlets_code ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10125
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_sales_outlets_code := iv_sales_outlets_code;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END chk_data_sales_outlets_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_corp_code
   * Description      : 妥当性チェック：企業コード(A-4-3)
   ***********************************************************************************/
  PROCEDURE chk_data_corp_code(
      ov_errbuf     OUT VARCHAR2                                -- エラー・メッセージ
    , ov_retcode    OUT VARCHAR2                                -- リターン・コード
    , ov_errmsg     OUT VARCHAR2                                -- ユーザー・エラー・メッセージ
    , in_row_num    IN  PLS_INTEGER                             -- 行番号
    , iv_corp_code  IN  VARCHAR2                                -- 企業コード
    , ot_corp_code  OUT xxcok_bm_support_budget.corp_code%TYPE  -- 企業コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_corp_code'; -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lb_chk_number   BOOLEAN;                                  -- 共通関数戻り値
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf     := NULL;
    ov_retcode    := cv_status_normal;
    ov_errmsg     := NULL;
    ot_corp_code  := NULL;
--
    --===============================================
    -- 必須入力チェック
    --===============================================
    IF( iv_corp_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10419
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 半角英数字（記号可）チェック
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_alphabet_number(
                        iv_check_char => iv_corp_code
                     );
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10136
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- 桁数チェック
    --===============================================
    IF( LENGTHB( iv_corp_code ) <> cn_len_corp_code ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10127
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_corp_code  := iv_corp_code;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END chk_data_corp_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_base_code
   * Description      : 妥当性チェック：拠点コード(A-4-2)
   ***********************************************************************************/
  PROCEDURE chk_data_base_code(
      ov_errbuf     OUT VARCHAR2                                -- エラー・メッセージ
    , ov_retcode    OUT VARCHAR2                                -- リターン・コード
    , ov_errmsg     OUT VARCHAR2                                -- ユーザー・エラー・メッセージ
    , in_row_num    IN  PLS_INTEGER                             -- 行番号
    , iv_base_code  IN  VARCHAR2                                -- 拠点コード
    , ot_base_code  OUT xxcok_bm_support_budget.base_code%TYPE  -- 拠点コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_base_code'; -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lb_chk_number   BOOLEAN;                                  -- 共通関数戻り値
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf     := NULL;
    ov_retcode    := cv_status_normal;
    ov_errmsg     := NULL;
    ot_base_code  := NULL;
--
    --===============================================
    -- 必須入力チェック
    --===============================================
    IF( iv_base_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10418
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 半角英数字（記号可）チェック
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_alphabet_number(
                        iv_check_char => iv_base_code
                     );
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10135
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- 桁数チェック
    --===============================================
    IF( LENGTHB( iv_base_code ) <> cn_len_base_code ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10126
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_base_code  := iv_base_code;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END chk_data_base_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_budget_year
   * Description      : 妥当性チェック：予算年度(A-4-1)
   ***********************************************************************************/
  PROCEDURE chk_data_budget_year(
      ov_errbuf       OUT VARCHAR2                                  -- エラー・メッセージ
    , ov_retcode      OUT VARCHAR2                                  -- リターン・コード
    , ov_errmsg       OUT VARCHAR2                                  -- ユーザー・エラー・メッセージ
    , in_row_num      IN  PLS_INTEGER                               -- 行番号
    , iv_budget_year  IN  VARCHAR2                                  -- 予算年度
    , ot_budget_year  OUT xxcok_bm_support_budget.budget_year%TYPE  -- 予算年度
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_budget_year'; -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lb_chk_number   BOOLEAN;                                  -- 共通関数戻り値
    lv_period_year  VARCHAR2(4)     DEFAULT NULL;             -- 会計年度
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf       := NULL;
    ov_retcode      := cv_status_normal;
    ov_errmsg       := NULL;
    ot_budget_year  := NULL;
--
    --===============================================
    -- 妥当性チェック
    --===============================================
    IF( iv_budget_year IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10417
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 半角数字チェック
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_number(
                        iv_check_char => iv_budget_year
                     );
--
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10479
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- 桁数チェック
    --===============================================
    IF( LENGTHB( iv_budget_year ) > cn_len_budget_year ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10480
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 会計期間ステータスチェック
    --===============================================
    IF( iv_budget_year = gt_next_period_year ) THEN
      -- 業務日付の翌年度の場合にはエラーとしない
      ot_budget_year := iv_budget_year;
--
    ELSE
      BEGIN
        SELECT  TO_CHAR( gps.period_year )  AS period_year  -- 会計年度
        INTO  ot_budget_year  -- 会計年度
        FROM    fnd_application     fa  -- 共通アプリケーション
              , gl_period_statuses  gps -- 会計期間ステータス
        WHERE   fa.application_short_name   =  cv_appl_name_sqlgl
          AND   gps.application_id          =  fa.application_id
          AND   gps.set_of_books_id         =  gn_set_of_books_id
          AND   gps.adjustment_period_flag  =  cv_adj_flag_no
          AND   gps.closing_status          =  cv_period_status_open
          AND   gps.period_year             =  TO_NUMBER( iv_budget_year )
          AND   ROWNUM = 1
        ;
--
      EXCEPTION
        ----------------------------------------------------------
        -- 会計期間未オープン
        ----------------------------------------------------------
        WHEN NO_DATA_FOUND THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcok
                          , iv_name         => cv_err_msg_10481
                          , iv_token_name1  => cv_token_budget_year
                          , iv_token_value1 => iv_budget_year
                          , iv_token_name2  => cv_token_row_num
                          , iv_token_value2 => TO_CHAR( in_row_num )
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.OUTPUT  -- 出力区分
                          , iv_message      => lv_out_msg       -- メッセージ
                          , in_new_line     => cn_0             -- 改行
                        );
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END chk_data_budget_year;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : 妥当性チェック(A-4)
   ***********************************************************************************/
  PROCEDURE chk_data(
      ov_errbuf     OUT VARCHAR2                          -- エラー・メッセージ
    , ov_retcode    OUT VARCHAR2                          -- リターン・コード
    , ov_errmsg     OUT VARCHAR2                          -- ユーザー・エラー・メッセージ
    , in_row_num    IN  PLS_INTEGER                       -- 行番号
    , it_csv_data   IN  xxcok_common_pkg.g_split_csv_tbl  -- CSV分割データ
    , ot_budget_rec OUT xxcok_tmp_022a01c_upload%ROWTYPE  -- 販手販協予算データ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data'; -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    ln_occurs       PLS_INTEGER;                              -- 繰り返し項目のインデックス
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    ln_occurs   := 0;
--
    --===============================================
    -- 妥当性チェック：予算年度
    --===============================================
    chk_data_budget_year(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , iv_budget_year        => CASE WHEN it_csv_data.COUNT >= cn_idx_budget_year
                                   THEN TRIM( it_csv_data( cn_idx_budget_year ) )
                                   ELSE NULL
                                 END                                              -- 予算年度
      , ot_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：拠点コード
    --===============================================
    chk_data_base_code(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , iv_base_code          => CASE WHEN it_csv_data.COUNT >= cn_idx_base_code
                                   THEN TRIM( it_csv_data( cn_idx_base_code ) )
                                   ELSE NULL
                                 END                                              -- 拠点コード
      , ot_base_code          => ot_budget_rec.base_code                          -- 拠点コード
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：企業コード
    --===============================================
    chk_data_corp_code(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , iv_corp_code          => CASE WHEN it_csv_data.COUNT >= cn_idx_corp_code
                                   THEN TRIM( it_csv_data( cn_idx_corp_code ) )
                                   ELSE NULL
                                 END                                              -- 企業コード
      , ot_corp_code          => ot_budget_rec.corp_code                          -- 企業コード
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：問屋帳合先コード
    --===============================================
    chk_data_sales_outlets_code(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , iv_sales_outlets_code => CASE WHEN it_csv_data.COUNT >= cn_idx_sales_outlets_code
                                   THEN TRIM( it_csv_data( cn_idx_sales_outlets_code ) )
                                   ELSE NULL
                                 END                                              -- 問屋帳合先コード
      , ot_sales_outlets_code => ot_budget_rec.sales_outlets_code                 -- 問屋帳合先コード
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：勘定科目コード
    --===============================================
    chk_data_acct_code(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , iv_acct_code          => CASE WHEN it_csv_data.COUNT >= cn_idx_acct_code
                                   THEN TRIM( it_csv_data( cn_idx_acct_code ) )
                                   ELSE NULL
                                 END                                              -- 勘定科目コード
      , ot_acct_code          => ot_budget_rec.acct_code                          -- 勘定科目コード
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：補助科目コード
    --===============================================
    chk_data_sub_acct_code(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , it_acct_code          => ot_budget_rec.acct_code                          -- 勘定科目コード
      , iv_sub_acct_code      => CASE WHEN it_csv_data.COUNT >= cn_idx_sub_acct_code
                                   THEN TRIM( it_csv_data( cn_idx_sub_acct_code ) )
                                   ELSE NULL
                                 END                                              -- 補助科目コード
      , ot_sub_acct_code      => ot_budget_rec.sub_acct_code                      -- 補助科目コード
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_01、金額_01
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_01
                                   THEN TRIM( it_csv_data( cn_idx_month_01 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_01                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_01
                                   THEN TRIM( it_csv_data( cn_idx_amount_01 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_01                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_02、金額_02
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_02
                                   THEN TRIM( it_csv_data( cn_idx_month_02 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_02                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_02
                                   THEN TRIM( it_csv_data( cn_idx_amount_02 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_02                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_03、金額_03
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_03
                                   THEN TRIM( it_csv_data( cn_idx_month_03 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_03                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_03
                                   THEN TRIM( it_csv_data( cn_idx_amount_03 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_03                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_04、金額_04
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_04
                                   THEN TRIM( it_csv_data( cn_idx_month_04 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_04                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_04
                                   THEN TRIM( it_csv_data( cn_idx_amount_04 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_04                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_05、金額_05
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_05
                                   THEN TRIM( it_csv_data( cn_idx_month_05 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_05                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_05
                                   THEN TRIM( it_csv_data( cn_idx_amount_05 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_05                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_06、金額_06
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_06
                                   THEN TRIM( it_csv_data( cn_idx_month_06 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_06                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_06
                                   THEN TRIM( it_csv_data( cn_idx_amount_06 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_06                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_07、金額_07
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_07
                                   THEN TRIM( it_csv_data( cn_idx_month_07 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_07                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_07
                                   THEN TRIM( it_csv_data( cn_idx_amount_07 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_07                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_08、金額_08
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_08
                                   THEN TRIM( it_csv_data( cn_idx_month_08 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_08                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_08
                                   THEN TRIM( it_csv_data( cn_idx_amount_08 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_08                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_09、金額_09
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_09
                                   THEN TRIM( it_csv_data( cn_idx_month_09 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_09                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_09
                                   THEN TRIM( it_csv_data( cn_idx_amount_09 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_09                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_10、金額_10
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_10
                                   THEN TRIM( it_csv_data( cn_idx_month_10 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_10                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_10
                                   THEN TRIM( it_csv_data( cn_idx_amount_10 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_10                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_11、金額_11
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_11
                                   THEN TRIM( it_csv_data( cn_idx_month_11 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_11                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_11
                                   THEN TRIM( it_csv_data( cn_idx_amount_11 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_11                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- 妥当性チェック：月度_12、金額_12
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , it_budget_year        => ot_budget_rec.budget_year                        -- 予算年度
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_12
                                   THEN TRIM( it_csv_data( cn_idx_month_12 ) )
                                   ELSE NULL
                                 END                                              -- 月度
      , ot_target_month       => ot_budget_rec.target_month_12                    -- 対象年月
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- エラー・メッセージ
      , ov_retcode            => lv_retcode                                       -- リターン・コード
      , ov_errmsg             => lv_errmsg                                        -- ユーザー・エラー・メッセージ
      , in_row_num            => in_row_num                                       -- 行番号
      , in_occurs             => ln_occurs                                        -- 繰り返し項目のインデックス
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_12
                                   THEN TRIM( it_csv_data( cn_idx_amount_12 ) )
                                   ELSE NULL
                                 END                                              -- 予算金額
      , ot_amount             => ot_budget_rec.budget_amt_12                      -- 予算金額
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : import_upload_file_data
   * Description      : アップロードファイルデータの取込(A-3)
   ***********************************************************************************/
  PROCEDURE import_upload_file_data(
      ov_errbuf         OUT VARCHAR2                          -- エラー・メッセージ
    , ov_retcode        OUT VARCHAR2                          -- リターン・コード
    , ov_errmsg         OUT VARCHAR2                          -- ユーザー・エラー・メッセージ
    , iv_file_id        IN  VARCHAR2                          -- ファイルID
    , i_file_data_tab   IN  xxccp_common_pkg2.g_file_data_tbl -- ファイルデータ格納領域
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'import_upload_file_data';  -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lt_csv_data     xxcok_common_pkg.g_split_csv_tbl;         -- CSV分割データ
    ln_csv_col_cnt  PLS_INTEGER;                              -- CSV項目数
    lt_budget_rec   xxcok_tmp_022a01c_upload%ROWTYPE;         -- 販手販協予算データ
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD START
--    lv_out_msg := '    エラー行   エラーデータ(先頭から1,000バイトまで)';
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which        => FND_FILE.LOG     -- 出力区分
--                    , iv_message      => lv_out_msg       -- メッセージ
--                    , in_new_line     => cn_0             -- 改行
--                  );
--    lv_out_msg := '============= ===============================================================';
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which        => FND_FILE.LOG     -- 出力区分
--                    , iv_message      => lv_out_msg       -- メッセージ
--                    , in_new_line     => cn_0             -- 改行
--                  );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD END
--
    -- アップロードファイルデータの取込
    <<import_loop>>
    FOR ln_row_num IN 2 .. i_file_data_tab.COUNT LOOP
      gn_target_cnt   := gn_target_cnt + 1; -- 対象件数をインクリメント
--
      lt_csv_data.delete;
      ln_csv_col_cnt  := 0;
      lt_budget_rec   := NULL;
--
      -- CSVデータの分割
      xxcok_common_pkg.split_csv_data_p(
          ov_errbuf         => lv_errbuf                      -- エラー・メッセージ
        , ov_retcode        => lv_retcode                     -- リターン・コード
        , ov_errmsg         => lv_errmsg                      -- ユーザー・エラー・メッセージ
        , iv_csv_data       => i_file_data_tab( ln_row_num )  -- CSV文字列
        , on_csv_col_cnt    => ln_csv_col_cnt                 -- CSV項目数
        , ov_split_csv_tab  => lt_csv_data                    -- CSV分割データ
      );
      IF( lv_retcode <> cv_status_normal ) THEN
        lv_out_msg := TO_CHAR( ln_row_num, '99,990' ) || ' 行目   ' || lv_errmsg;
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.LOG     -- 出力区分
                        , iv_message      => lv_out_msg       -- メッセージ
                        , in_new_line     => cn_0             -- 改行
                      );
      END IF;
--
      IF( REPLACE( i_file_data_tab( ln_row_num ), cv_comma, NULL ) IS NULL ) THEN
        -- 空行（カンマのみ）の場合には無視
        gn_warn_cnt := gn_warn_cnt + 1; -- スキップ件数をインクリメント
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD START
--        lv_out_msg := TO_CHAR( ln_row_num, '99,990' ) || ' 行目   ' || SUBSTR( i_file_data_tab( ln_row_num ), 1, 1000 );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                          in_which        => FND_FILE.LOG     -- 出力区分
--                        , iv_message      => lv_out_msg       -- メッセージ
--                        , in_new_line     => cn_0             -- 改行
--                      );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD END
--
      ELSE
        --===============================================
        -- A-4．妥当性チェック
        --===============================================
        chk_data(
            ov_errbuf     => lv_errbuf      -- エラー・メッセージ
          , ov_retcode    => lv_retcode     -- リターン・コード
          , ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ
          , in_row_num    => ln_row_num     -- 行番号
          , it_csv_data   => lt_csv_data    -- CSV分割データ
          , ot_budget_rec => lt_budget_rec  -- 販手販協予算データ
        );
        IF( lv_retcode <> cv_status_normal ) THEN
          gn_error_cnt  := gn_error_cnt + 1; -- エラー件数をインクリメント
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD START
--          lv_out_msg := TO_CHAR( ln_row_num, '99,990' ) || ' 行目   ' || SUBSTR( i_file_data_tab( ln_row_num ), 1, 1000 );
--          lb_retcode := xxcok_common_pkg.put_message_f(
--                            in_which        => FND_FILE.LOG     -- 出力区分
--                          , iv_message      => lv_out_msg       -- メッセージ
--                          , in_new_line     => cn_0             -- 改行
--                        );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD END
        END IF;
--
        --===============================================
        -- A-5．販手販協予算アップロード情報一時表への登録
        --===============================================
        IF( gn_error_cnt = 0 ) THEN
          ins_xxcok_tmp_022a01c(
              ov_errbuf         => lv_errbuf      -- エラー・メッセージ
            , ov_retcode        => lv_retcode     -- リターン・コード
            , ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ
            , in_row_num        => ln_row_num     -- 行番号
            , it_xt022a01c_rec  => lt_budget_rec  -- 販手販協予算データ
          );
          IF( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          gn_normal_cnt := gn_normal_cnt + 1; -- 正常件数をインクリメント
        END IF;
      END IF;
    END LOOP import_loop;
--
    IF( gn_target_cnt = gn_warn_cnt ) THEN
      -- 全件スキップの場合には空ファイルエラーのメッセージを出力
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00039
                      , iv_token_name1  => cv_token_file_id
                      , iv_token_value1 => iv_file_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
      RAISE global_process_expt;
--
    ELSIF( gn_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
--
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi REPAIR START
--    ELSIF( gn_error_cnt = 0 ) THEN
--      lv_out_msg := '               エラーはありません。';
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which        => FND_FILE.LOG     -- 出力区分
--                      , iv_message      => lv_out_msg       -- メッセージ
--                      , in_new_line     => cn_0             -- 改行
--                    );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which        => FND_FILE.LOG     -- 出力区分
--                    , iv_message      => NULL             -- メッセージ
--                    , in_new_line     => cn_1             -- 改行
--                  );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi REPAIR END
    END IF;
--
    --===============================================
    -- A-6．重複予算年度の削除
    --===============================================
    del_duplicate_budget_year(
        ov_errbuf     => lv_errbuf      -- エラー・メッセージ
      , ov_retcode    => lv_retcode     -- リターン・コード
      , ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- A-7．販手販協予算の登録
    --===============================================
    ins_bm_support_budget(
        ov_errbuf     => lv_errbuf      -- エラー・メッセージ
      , ov_retcode    => lv_retcode     -- リターン・コード
      , ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- A-8．パージ処理
    --===============================================
    purge_bm_support_budget(
        ov_errbuf     => lv_errbuf      -- エラー・メッセージ
      , ov_retcode    => lv_retcode     -- リターン・コード
      , ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END import_upload_file_data;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_file_data
   * Description      : アップロードファイルデータの取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_file_data(
      ov_errbuf         OUT VARCHAR2                          -- エラー・メッセージ
    , ov_retcode        OUT VARCHAR2                          -- リターン・コード
    , ov_errmsg         OUT VARCHAR2                          -- ユーザー・エラー・メッセージ
    , iv_file_id        IN  VARCHAR2                          -- ファイルID
    , iv_format_pattern IN  VARCHAR2                          -- フォーマットパターン
    , o_file_data_tab   OUT xxccp_common_pkg2.g_file_data_tbl -- ファイルデータ格納領域
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_upload_file_data'; -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lt_file_name    xxccp_mrp_file_ul_interface.file_name%TYPE  DEFAULT NULL; --ファイル名
--
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- アップロードファイルデータ
    CURSOR xmfui_cur
    IS
-- 2010/08/04 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi REPAIR START
--      SELECT  xmfui.file_name   AS file_name      -- ファイル名
--      FROM    xxccp_mrp_file_ul_interface xmfui -- ファイルアップロードIFテーブル
--      WHERE   xmfui.file_id     =  TO_NUMBER( iv_file_id )
--      FOR UPDATE OF xmfui.file_id NOWAIT
--    ;
      SELECT  xmfui.file_name   AS file_name      -- ファイル名
            , flvv.meaning      AS upload_object  -- ファイルアップロード名称
      FROM    xxccp_mrp_file_ul_interface xmfui -- ファイルアップロードIFテーブル
            , fnd_lookup_values_vl        flvv  -- クイックコード
      WHERE   xmfui.file_id     =  TO_NUMBER( iv_file_id )
        AND   flvv.lookup_type  =  cv_lookup_type_upload_file
        AND   flvv.lookup_code  =  xmfui.file_content_type
        AND   flvv.enabled_flag =  cv_enabled_flag_y
        AND   gd_operation_date BETWEEN TRUNC( NVL( start_date_active, gd_operation_date ) )
                                    AND TRUNC( NVL( end_date_active  , gd_operation_date ) )
      FOR UPDATE OF xmfui.file_id NOWAIT
    ;
-- 2010/08/04 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi REPAIR END
    xmfui_rec xmfui_cur%ROWTYPE;
--
    -- ===============================
    -- ローカル例外
    -- ===============================
    blob_expt EXCEPTION;  --BLOBデータ変換エラー例外
    file_expt EXCEPTION;  --空ファイルエラー例外
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- ファイルアップロード情報の取得
    --===============================================
    OPEN  xmfui_cur;
    FETCH xmfui_cur INTO xmfui_rec;
    CLOSE xmfui_cur;
--
-- 2010/08/04 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi ADD START
    --===============================================
    -- ファイルアップロード名称のメッセージ出力
    --===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_message_00106 
                    , iv_token_name1  => cv_token_upload_object
                    , iv_token_value1 => xmfui_rec.upload_object
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG     -- 出力区分
                    , iv_message      => lv_out_msg       -- メッセージ
                    , in_new_line     => cn_0             -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT  -- 出力区分
                    , iv_message      => lv_out_msg       -- メッセージ
                    , in_new_line     => cn_0             -- 改行
                  );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi ADD END
--
    --===============================================
    -- アップロードファイル名のメッセージ出力
    --===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_message_00006
                    , iv_token_name1  => cv_token_file_name
                    , iv_token_value1 => xmfui_rec.file_name
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG     -- 出力区分
                    , iv_message      => lv_out_msg       -- メッセージ
                    , in_new_line     => cn_1             -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT  -- 出力区分
                    , iv_message      => lv_out_msg       -- メッセージ
                    , in_new_line     => cn_1             -- 改行
                  );
--
    --===============================================
    -- BLOBデータ変換
    --===============================================
    xxccp_common_pkg2.blob_to_varchar2(
        ov_errbuf     => lv_errbuf
      , ov_retcode    => lv_retcode
      , ov_errmsg     => lv_errmsg
      , in_file_id    => TO_NUMBER( iv_file_id )
      , ov_file_data  => o_file_data_tab
    );
    -- リターンコードが0(正常)以外の場合
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE blob_expt;
    END IF;
    -- 件数が1件以下の場合
    IF( o_file_data_tab.COUNT <= cn_1 ) THEN
      RAISE file_expt;
    END IF;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ロック例外ハンドラ
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00061
                      , iv_token_name1  => cv_token_file_id
                      , iv_token_value1 => iv_file_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- BLOBデータ変換エラー例外ハンドラ
    ----------------------------------------------------------
    WHEN blob_expt THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => lv_errmsg        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00041
                      , iv_token_name1  => cv_token_file_id
                      , iv_token_value1 => iv_file_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- 空ファイルエラー例外ハンドラ
    ----------------------------------------------------------
    WHEN file_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00039
                      , iv_token_name1  => cv_token_file_id
                      , iv_token_value1 => iv_file_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- 出力区分
                      , iv_message      => lv_out_msg       -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
  END get_upload_file_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf         OUT VARCHAR2  -- エラー・メッセージ
    , ov_retcode        OUT VARCHAR2  -- リターン・コード
    , ov_errmsg         OUT VARCHAR2  -- ユーザー・エラー・メッセージ
    , iv_file_id        IN  VARCHAR2  -- ファイルID
    , iv_format_pattern IN  VARCHAR2  -- フォーマットパターン
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    lv_profile_name fnd_profile_options.profile_option_name%TYPE  DEFAULT NULL; -- プロファイル退避
--
    -- ===============================
    -- ローカル例外
    -- ===============================
    operation_date_expt EXCEPTION;  -- 業務処理日付取得エラー例外
    get_profile_expt    EXCEPTION;  -- プロファイル取得エラー例外
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- コンカレントプログラム入力項目のメッセージ出力
    --===============================================
    -- 入力項目.ファイルID
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_message_00016
                    , iv_token_name1  => cv_token_file_id
                    , iv_token_value1 => iv_file_id
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT  -- 出力区分
                    , iv_message      => lv_out_msg       -- メッセージ
                    , in_new_line     => cn_0             -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG     -- 出力区分
                    , iv_message      => lv_out_msg       -- メッセージ
                    , in_new_line     => cn_0             -- 改行
                  );
--
    -- 入力項目.フォーマットパターン
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_message_00017
                    , iv_token_name1  => cv_token_format
                    , iv_token_value1 => iv_format_pattern
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG     -- 出力区分
                    , iv_message      => lv_out_msg       -- メッセージ
                    , in_new_line     => cn_1             -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT  -- 出力区分
                    , iv_message      => lv_out_msg       -- メッセージ
                    , in_new_line     => cn_1             -- 改行
                  );
--
    --==============================================================
    --業務処理日付を取得
    --==============================================================
    gd_operation_date := xxccp_common_pkg2.get_process_date;
--
    IF( gd_operation_date IS NULL ) THEN
      RAISE operation_date_expt;
    END IF;
--
    -- 業務日付
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_message_00022
                    , iv_token_name1  => cv_token_business_date
                    , iv_token_value1 => TO_CHAR( gd_operation_date, cv_format_yyyymmdd )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG     -- 出力区分
                    , iv_message      => lv_out_msg       -- メッセージ
                    , in_new_line     => cn_0             -- 改行
                  );
--
    --===============================================
    -- プロファイルの取得
    --===============================================
    BEGIN
      -- 会計帳簿ID
      lv_profile_name    := cv_set_of_bks_id;
      gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_bks_id ) );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD START
--      lv_out_msg := 'プロファイル名  ：  '           || cv_set_of_bks_id              || ' 、'
--                 || 'プロファイルオプション値  ：  ' || TO_CHAR( gn_set_of_books_id );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which        => FND_FILE.LOG     -- 出力区分
--                      , iv_message      => lv_out_msg       -- メッセージ
--                      , in_new_line     => cn_0             -- 改行
--                    );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD END
      IF( gn_set_of_books_id IS NULL ) THEN
        RAISE get_profile_expt;
      END IF;
--
      -- 会社コード
      lv_profile_name := cv_company_code;
      gt_company_code := FND_PROFILE.VALUE( cv_company_code );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD START
--      lv_out_msg := 'プロファイル名  ：  '           || cv_company_code || ' 、'
--                 || 'プロファイルオプション値  ：  ' || gt_company_code;
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which        => FND_FILE.LOG     -- 出力区分
--                      , iv_message      => lv_out_msg       -- メッセージ
--                      , in_new_line     => cn_0             -- 改行
--                    );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD END
      IF( gt_company_code IS NULL ) THEN
        RAISE get_profile_expt;
      END IF;
--
      -- 販手販協予算保持期間
      lv_profile_name := cv_keep_period;
      gn_keep_period  := TO_NUMBER( FND_PROFILE.VALUE( cv_keep_period ) );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD START
--      lv_out_msg := 'プロファイル名  ：  '           || cv_keep_period            || ' 、'
--                 || 'プロファイルオプション値  ：  ' || TO_CHAR( gn_keep_period );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which        => FND_FILE.LOG     -- 出力区分
--                      , iv_message      => lv_out_msg       -- メッセージ
--                      , in_new_line     => cn_0             -- 改行
--                    );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD END
      IF( gn_keep_period IS NULL ) THEN
        RAISE get_profile_expt;
      END IF;
--
    EXCEPTION
      ----------------------------------------------------------
      -- OTHERS例外ハンドラ
      -- (get_profile_exptとしてはハンドリングしない)
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.LOG     -- 出力区分
                        , iv_message      => ov_errbuf        -- メッセージ
                        , in_new_line     => cn_0             -- 改行
                      );
--
        lv_out_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcok
                        , iv_name         => cv_err_msg_00003
                        , iv_token_name1  => cv_token_profile
                        , iv_token_value1 => lv_profile_name
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.OUTPUT -- 出力区分
                        , iv_message      => lv_out_msg      -- メッセージ
                        , in_new_line     => cn_0            -- 改行
                      );
--
      RAISE global_process_expt;
    END;
--
    --===============================================
    -- 翌予算年度の取得
    --===============================================
    SELECT  TO_CHAR( gp.period_year + cn_1 )  AS next_period_year -- 翌予算年度
          , gp.period_year - gn_keep_period   AS keep_period_year -- 販協予算保持期間（年度）
    INTO  gt_next_period_year -- 翌予算年度
        , gn_keep_period_year -- 販協予算保持期間（年度）
    FROM    gl_sets_of_books  gsob  -- 会計帳簿マスタ
          , gl_periods        gp    -- 会計カレンダ
    WHERE   gsob.set_of_books_id      =  gn_set_of_books_id
      AND   gp.period_set_name        =  gsob.period_set_name
      AND   gp.adjustment_period_flag =  cv_adj_flag_no
      AND   gd_operation_date         BETWEEN gp.start_date
                                          AND gp.end_date
      AND   ROWNUM = 1
    ;
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD START
--    lv_out_msg := '翌予算年度  ：  ' || gt_next_period_year;
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which        => FND_FILE.LOG     -- 出力区分
--                    , iv_message      => lv_out_msg       -- メッセージ
--                    , in_new_line     => cn_0             -- 改行
--                  );
--    lv_out_msg := '販手販協予算パージ対象  ：  ' || TO_CHAR( gn_keep_period_year ) || ' 年度以前';
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which        => FND_FILE.LOG     -- 出力区分
--                    , iv_message      => lv_out_msg       -- メッセージ
--                    , in_new_line     => cn_1             -- 改行
--                  );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332][DEBUG] SCS S.Arizumi ADD END
--
  EXCEPTION
    ----------------------------------------------------------
    -- 業務処理日付取得エラー例外ハンドラ
    ----------------------------------------------------------
    WHEN operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT -- 出力区分
                      , iv_message      => lv_out_msg      -- メッセージ
                      , in_new_line     => cn_0            -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf         OUT VARCHAR2  -- エラー・メッセージ
    , ov_retcode        OUT VARCHAR2  -- リターン・コード
    , ov_errmsg         OUT VARCHAR2  -- ユーザー・エラー・メッセージ
    , iv_file_id        IN  VARCHAR2  -- ファイルID
    , iv_format_pattern IN  VARCHAR2  -- フォーマットパターン
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'submain';  -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
    l_file_data_tab xxccp_common_pkg2.g_file_data_tbl;        -- ファイルデータ
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- A-1．初期処理
    --===============================================
    init(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ
      , ov_retcode        => lv_retcode         -- リターン・コード
      , ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ
      , iv_file_id        => iv_file_id         -- ファイルID
      , iv_format_pattern => iv_format_pattern  -- フォーマットパターン
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- A-2．アップロードファイルデータの取得
    --===============================================
    get_upload_file_data(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ
      , ov_retcode        => lv_retcode         -- リターン・コード
      , ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ
      , iv_file_id        => iv_file_id         -- ファイルID
      , iv_format_pattern => iv_format_pattern  -- フォーマットパターン
      , o_file_data_tab   => l_file_data_tab    -- ファイルデータ格納領域
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- A-3．販手販協予算の取込
    --===============================================
    import_upload_file_data(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ
      , ov_retcode        => lv_retcode         -- リターン・コード
      , ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ
      , iv_file_id        => iv_file_id         -- ファイルID
      , i_file_data_tab   => l_file_data_tab    -- ファイルデータ格納領域
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  --
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => ov_errbuf        -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
      errbuf            OUT VARCHAR2  -- エラー・メッセージ
    , retcode           OUT VARCHAR2  -- リターン・コード
    , iv_file_id        IN  VARCHAR2  -- ファイルID
    , iv_format_pattern IN  VARCHAR2  -- フォーマットパターン
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- メッセージ戻り値
--
  BEGIN
    --===============================================
    -- 初期化
    --===============================================
    errbuf  := NULL;              -- エラー・メッセージ
    retcode := cv_status_normal;  -- リターン・コード
--
    --===============================================
    -- コンカレントヘッダ出力
    --===============================================
    xxccp_common_pkg.put_log_header(
        iv_which    => cv_output
      , ov_retcode  => lv_retcode
      , ov_errbuf   => lv_errbuf
      , ov_errmsg   => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
-- 2010/08/04 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE START
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which      => FND_FILE.OUTPUT -- 出力区分
--                    , iv_message    => NULL            -- メッセージ
--                    , in_new_line   => cn_1            -- 改行
--                  );
-- 2010/08/04 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi DELETE END
--
    --===============================================
    -- サブメイン処理
    --===============================================
    submain(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ
      , ov_retcode        => lv_retcode         -- リターン・コード
      , ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ
      , iv_file_id        => iv_file_id         -- ファイルID
      , iv_format_pattern => iv_format_pattern  -- フォーマット
    );
    -- ステータスがエラーの場合はROLLBACKする
    IF( lv_retcode = cv_status_error ) THEN
      -- ステータスセット
      retcode := cv_status_error;
      ROLLBACK;
    END IF;
--
    --===============================================
    -- A-9．ファイルアップロードIFの削除
    --===============================================
    del_mrp_file_ul_interface(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ
      , ov_retcode        => lv_retcode         -- リターン・コード
      , ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ
      , iv_file_id        => iv_file_id         -- ファイルID
    );
    IF( lv_retcode = cv_status_error ) THEN
      -- ステータスセット
      retcode := cv_status_error;
    END IF;
--
-- 2010/08/04 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi REPAIR START
--    IF( retcode = cv_status_error ) THEN
--      -- エラー時処理件数設定
--      gn_normal_cnt := cn_0;  -- 正常件数
----
--      -- ステータスセット
--      retcode := cv_status_error;
--    END IF;
----
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which      => FND_FILE.OUTPUT -- 出力区分
--                    , iv_message    => NULL            -- メッセージ
--                    , in_new_line   => cn_1            -- 改行
--                  );
    IF( retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which      => FND_FILE.OUTPUT -- 出力区分
                      , iv_message    => NULL            -- メッセージ
                      , in_new_line   => cn_1            -- 改行
                    );
--
      -- エラー時処理件数設定
      gn_normal_cnt := cn_0;  -- 正常件数
      IF( gn_error_cnt = cn_0 ) THEN
        gn_error_cnt := cn_1; -- エラー件数
      END IF;
--
      -- ステータスセット
      retcode := cv_status_error;
    END IF;
-- 2010/08/04 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi REPAIR END
--
    --===============================================
    -- A-10.終了処理
    --===============================================
    -- 対象件数メッセージ出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_message_90000
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_0            -- 改行
                  );
--
    -- 成功件数メッセージ出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_message_90001
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_0            -- 改行
                  );
--
    -- エラー件数メッセージ出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_message_90002
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_0            -- 改行
                  );
--
    -- スキップ件数メッセージ出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_message_90003
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_0            -- 改行
                  );
--
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which      => FND_FILE.OUTPUT -- 出力区分
                    , iv_message    => NULL            -- メッセージ
                    , in_new_line   => cn_1            -- 改行
                  );
--
    -- 終了メッセージ出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => CASE retcode
                                           WHEN cv_status_normal THEN cv_message_90004
                                           WHEN cv_status_warn   THEN cv_message_90005
                                           ELSE                       cv_message_90006
                                         END
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_0            -- 改行
                  );
--
    -- 必ずファイルアップロードIFを削除するため、明示的にコミット
    COMMIT;
--
  EXCEPTION
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
--
      --===============================================
      -- A-9．ファイルアップロードIFの削除
      --===============================================
      del_mrp_file_ul_interface(
          ov_errbuf         => lv_errbuf          -- エラー・メッセージ
        , ov_retcode        => lv_retcode         -- リターン・コード
        , ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ
        , iv_file_id        => iv_file_id         -- ファイルID
      );
      COMMIT;
--
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
--
      --===============================================
      -- A-9．ファイルアップロードIFの削除
      --===============================================
      del_mrp_file_ul_interface(
          ov_errbuf         => lv_errbuf          -- エラー・メッセージ
        , ov_retcode        => lv_retcode         -- リターン・コード
        , ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ
        , iv_file_id        => iv_file_id         -- ファイルID
      );
      COMMIT;
--
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => errbuf           -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ROLLBACK;
--
      --===============================================
      -- A-9．ファイルアップロードIFの削除
      --===============================================
      del_mrp_file_ul_interface(
          ov_errbuf         => lv_errbuf          -- エラー・メッセージ
        , ov_retcode        => lv_retcode         -- リターン・コード
        , ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ
        , iv_file_id        => iv_file_id         -- ファイルID
      );
      COMMIT;
--
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- 出力区分
                      , iv_message      => errbuf           -- メッセージ
                      , in_new_line     => cn_0             -- 改行
                    );
      ROLLBACK;
--
      --===============================================
      -- A-9．ファイルアップロードIFの削除
      --===============================================
      del_mrp_file_ul_interface(
          ov_errbuf         => lv_errbuf          -- エラー・メッセージ
        , ov_retcode        => lv_retcode         -- リターン・コード
        , ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ
        , iv_file_id        => iv_file_id         -- ファイルID
      );
      COMMIT;
  END  main;
-- 2010/08/02 Ver.2.0 [E_本稼動_03332] SCS S.Arizumi REPAIR END
END XXCOK022A01C;
/
