CREATE OR REPLACE PACKAGE BODY xxcok_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcok_common_pkg(body)
 * Description      : 個別開発領域・共通関数
 * MD.070           : MD070_IPO_COK_共通関数
 * Version          : 1.13
 *
 * Program List
 * --------------------------   ------------------------------------------------------------
 *  Name                         Description
 * --------------------------   ------------------------------------------------------------
 *  get_acctg_calendar_p         会計カレンダ取得
 *  get_next_year_p              翌会計年度取得
 *  get_set_of_books_info_p      会計帳簿情報取得
 *  get_close_date_p             締め・支払日取得
 *  get_emp_code_f               従業員コード取得
 *  check_acctg_period_f         会計期間チェック
 *  get_operating_day_f          稼働日取得
 *  get_sales_staff_code_f       担当営業員コード取得
 *  get_wholesale_req_est_p      問屋請求見積照合
 *  get_companies_code_f         企業コード取得
 *  get_department_code_f        所属部門コード取得
 *  get_batch_name_f             バッチ名取得
 *  get_slip_number_f            伝票番号取得
 *  check_year_migration_f       年次移行情報確定チェック
 *  get_code_combination_id_f    CCID取得
 *  check_code_combination_id_f  CCIDチェック
 *  put_message_f                メッセージ出力
 *  get_base_code_f              所属拠点コード取得
 *  split_csv_data_p             CSV文字列分割
 *  get_wholesale_req_est_type_f 問屋請求書見積書突合ステータス取得
 *  get_bill_to_cust_code_f      請求先顧客コード取得
 *  get_uom_conversion_qty_f     基準単位換算数取得
 *  get_directory_path_f         ディレクトリパス取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/31    1.0   T.OSADA          新規作成
 *  2009/02/06    1.1   K.YAMAGUCHI      [障害COK_022] ディレクトリパス取得追加
 *  2009/02/12    1.2   K.IWABUCHI       [障害COK_029] 問屋請求書見積照合 販売手数料算出方法修正
 *  2009/02/16    1.3   K.IWABUCHI       [障害COK_034] 問屋請求書見積照合 販売協賛金算出条件追加
 *  2009/02/18    1.4   K.IWABUCHI       [障害COK_043] 問屋請求書見積照合 見積情報取得SQLソート修正
 *  2009/02/24    1.5   K.IWABUCHI       [障害COK_053] 締め・支払日取得 日付チェック追加
 *  2009/02/26    1.6   K.IWABUCHI       [障害COK_057] SYSDATEを業務日付に修正
 *  2009/03/13    1.7   M.HIRUTA         [障害T1_0020] 基準単位換算数取得 区分内換算対応
 *  2009/03/23    1.8   K.YAMAGUCHI      [障害T1_0074] 見積書の顧客コードから問屋管理コードを導出し、
 *                                                     問屋販売条件請求書の問屋管理コードで検索を行う
 *  2009/04/09    1.9   K.YAMAGUCHI      [障害T1_0341] 請求先顧客取得 抽出条件変更
 *  2009/04/13    1.10  K.YAMAGUCHI      [障害T1_0411] 問屋請求書見積照合 抽出条件変更
 *  2009/04/15    1.11  K.YAMAGUCHI      [障害T1_0570] 担当営業員コード取得 組織プロファイル有効判定条件変更
 *  2009/10/02    1.12  SCS S.Moriyama   [障害E_T3_00630] VDBM残高一覧表が出力されない
 *  2010/04/21    1.13  SCS K.Yamguchi   [E_本稼動_02088] 問屋請求見積照合 再作成
 *                                                        ・突合せ方法の仕様変更
 *                                                        ・請求単位（ボール）対応
 *                                                        ・見積に税込額が設定されている場合の対応
 *
 *****************************************************************************************/
  -- ==============================
  -- グローバル定数
  -- ==============================
  --ステータス・コード
  gv_status_normal CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  gv_status_warn   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  gv_status_error  CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --パッケージ名
  cv_pkg_name      CONSTANT VARCHAR2(30) := 'xxcok_common_pkg';
  --セパレータ
  cv_sepa_period   CONSTANT VARCHAR2(1)  := '.';  -- ピリオド
  cv_sepa_colon    CONSTANT VARCHAR2(1)  := ':';  -- コロン
--
  /**********************************************************************************
   * Procedure Name   : get_acctg_calendar_p
   * Description      : 会計カレンダ取得
   ***********************************************************************************/
  PROCEDURE get_acctg_calendar_p(
    ov_errbuf                 OUT VARCHAR2             -- エラーバッファ
  , ov_retcode                OUT VARCHAR2             -- リターンコード
  , ov_errmsg                 OUT VARCHAR2             -- エラーメッセージ
  , in_set_of_books_id        IN  NUMBER               -- 会計帳簿ID
  , iv_application_short_name IN  VARCHAR2             -- アプリケーション短縮名
  , id_object_date            IN  DATE                 -- 対象日
  , iv_adjustment_period_flag IN  VARCHAR2 DEFAULT 'N' -- 調整フラグ
  , on_period_year            OUT NUMBER               -- 会計年度
  , ov_period_name            OUT VARCHAR2             -- 会計期間名
  , ov_closing_status         OUT VARCHAR2             -- ステータス
  )
  IS
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_acctg_calendar_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_retcode        VARCHAR(1);                             -- リターンコードの変数
    lt_period_year    gl_period_statuses.period_year%TYPE;    -- 会計年度の変数
    lt_period_name    gl_period_statuses.period_name%TYPE;    -- 会計期間名の変数
    lt_closing_status gl_period_statuses.closing_status%TYPE; -- ステータスの変数
--
  BEGIN
    lv_retcode := gv_status_normal;
    --=======================================================================
    --会計年度、会計期間名、ステータスの取得
    --=======================================================================
    SELECT  gps.period_year            AS period_year
          , gps.period_name            AS period_name
          , gps.closing_status         AS closing_status
    INTO    lt_period_year
          , lt_period_name
          , lt_closing_status
    FROM    gl_period_statuses         gps
          , fnd_application            fa
    WHERE   gps.application_id         = fa.application_id
    AND     gps.adjustment_period_flag = iv_adjustment_period_flag
    AND     gps.set_of_books_id        = in_set_of_books_id
    AND     fa.application_short_name  = iv_application_short_name
    AND     gps.start_date            <= id_object_date
    AND     gps.end_date              >= id_object_date;
    --=======================================
    -- 出力パラメータセット
    --=======================================
    ov_errbuf         := NULL;
    ov_retcode        := gv_status_normal;
    ov_errmsg         := NULL;
    on_period_year    := lt_period_year;    -- 変数をパラメータに代入(会計年度)
    ov_period_name    := lt_period_name;    -- 変数をパラメータに代入(会計期間名)
    ov_closing_status := lt_closing_status; -- 変数をパラメータに代入(ステータス)
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END get_acctg_calendar_p;
--
  /************************************************************************
   * Procedure Name  : get_next_year_p
   * Description     : 翌会計年度取得
   ************************************************************************/
  PROCEDURE get_next_year_p(
    ov_errbuf           OUT VARCHAR2                              -- エラー・バッファ
  , ov_retcode          OUT VARCHAR2                              -- リターン・コード
  , ov_errmsg           OUT VARCHAR2                              -- エラー・メッセージ
  , in_set_of_books_id  IN  gl_sets_of_books.set_of_books_id%TYPE -- 会計帳簿ID
  , in_period_year      IN  gl_periods.period_year%TYPE           -- 会計年度
  , on_next_period_year OUT gl_periods.period_year%TYPE           -- 翌会計年度
  , od_next_start_date  OUT gl_periods.start_date%TYPE            -- 翌会計年度期首日
  )
  IS
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_next_year_p'; -- プログラム名
    cn_year     CONSTANT NUMBER       := 1;                 -- 1年
    cv_no_flag  CONSTANT VARCHAR2(1)  := 'N';               -- 調整フラグ'N'
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_retcode          VARCHAR2(1);                 -- リターン・コード
    lt_next_period_year gl_periods.period_year%TYPE; -- 翌会計年度
    lt_next_start_date  gl_periods.start_date%TYPE;  -- 翌会計年度期首日
--
  BEGIN
    lv_retcode := gv_status_normal;
    --=====================================================================
    -- 翌会計年度、翌会計年度期首日の取得
    --=====================================================================
    SELECT gp.period_year            AS period_year              -- 会計年度
         , MIN( gp.start_date )      AS start_date               -- 会計年度期首日
    INTO   lt_next_period_year                                   -- 翌会計年度
         , lt_next_start_date                                    -- 翌会計年度期首日
    FROM   gl_periods                gp                          -- 会計カレンダテーブル
         , gl_sets_of_books          gsob                        -- 会計帳簿マスタ
    WHERE  gp.period_set_name        = gsob.period_set_name
    AND    gsob.set_of_books_id      = in_set_of_books_id
    AND    gp.period_year            = in_period_year + cn_year
    AND    gp.adjustment_period_flag = cv_no_flag
    GROUP BY gp.period_year;
--
    ov_retcode          := lv_retcode;
    ov_errbuf           := NULL;
    ov_errmsg           := NULL;
    on_next_period_year := lt_next_period_year;
    od_next_start_date  := lt_next_start_date;
--
  EXCEPTION
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END get_next_year_p;
--
  /**********************************************************************************
   * Procedure Name   : get_set_of_books_info_p
   * Description      : 会計帳簿情報取得
   ***********************************************************************************/
  PROCEDURE get_set_of_books_info_p(
    ov_errbuf            OUT VARCHAR2 -- エラー・バッファ（ログ）
  , ov_retcode           OUT VARCHAR2 -- リターンコード
  , ov_errmsg            OUT VARCHAR2 -- エラー・メッセージ（ユーザー）
  , on_set_of_books_id   OUT NUMBER   -- 会計帳簿ID
  , ov_set_of_books_name OUT VARCHAR2 -- 会計帳簿名
  , on_chart_acct_id     OUT NUMBER   -- 勘定体系ID
  , ov_period_set_name   OUT VARCHAR2 -- カレンダ名
  , on_aff_segment_cnt   OUT NUMBER   -- AFFセグメント定義数
  , ov_currency_code     OUT VARCHAR2 -- 機能通貨コード
  )
  IS
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name         CONSTANT VARCHAR2(30)  := 'get_set_of_books_info_p'; -- プログラム名
    cv_profile_name     CONSTANT VARCHAR2(20)  := 'GL_SET_OF_BKS_ID';        -- プロファイル・オプション名
    cv_appli_short_name CONSTANT VARCHAR2(10)  := 'SQLGL';                   -- アプリケーション短縮名
    cv_id_flex_code     CONSTANT VARCHAR2(5)   := 'GL#';                     -- フレックスフィールドコード
    cv_iv_token_name1   CONSTANT VARCHAR2(7)   := 'PROFILE';                 -- トークンコード1
    cv_prof_get_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00003';        -- プロファイル取得エラーMSGID
    cv_xxcok            CONSTANT VARCHAR2(10)  := 'XXCOK';                   -- アプリケーション短縮名
    -- ==============================
    --  ローカル変数
    -- ==============================
    lv_set_of_bks_id VARCHAR2(5);    -- 会計帳簿ID
    lv_out_msg       VARCHAR2(2000); -- メッセージ格納用変数
    -- ==============================
    -- ローカル例外
    -- ==============================
    -- プロファイル・オプション値未取得
    nodata_profile_expt EXCEPTION;
--
  BEGIN
    ov_retcode := gv_status_normal;
    -- ====================================================
    -- プロファイル・オプション値の取得
    -- ====================================================
    lv_set_of_bks_id := FND_PROFILE.VALUE( cv_profile_name );
--
    IF( lv_set_of_bks_id IS NULL ) THEN
      RAISE nodata_profile_expt;
    END IF;
    -- ====================================================
    -- 会計帳簿情報の取得
    -- ====================================================
    SELECT gsob.set_of_books_id      AS set_of_books_id
         , gsob.name                 AS set_of_books_name
         , gsob.chart_of_accounts_id AS chart_of_accounts_id
         , gsob.period_set_name      AS period_set_name
         , gsob.currency_code        AS currency_code
    INTO   on_set_of_books_id
         , ov_set_of_books_name
         , on_chart_acct_id
         , ov_period_set_name
         , ov_currency_code
    FROM   gl_sets_of_books          gsob
    WHERE  gsob.set_of_books_id      = TO_NUMBER( lv_set_of_bks_id );
    -- ====================================================
    -- AFFセグメント定義数の取得
    -- ====================================================
    SELECT COUNT( 'X' )              AS aff_segment_cnt
    INTO   on_aff_segment_cnt
    FROM   fnd_id_flex_segments      fids
         , fnd_application           fa
    WHERE  fids.id_flex_num          = on_chart_acct_id
    AND    fids.id_flex_code         = cv_id_flex_code
    AND    fa.application_short_name = cv_appli_short_name
    AND    fids.application_id       = fa.application_id;
--
  EXCEPTION
    -- プロファイル・オプション値未取得エラー
    WHEN nodata_profile_expt THEN
      -- 出力パラメータ変数初期化
      lv_out_msg := NULL;                                     -- メッセージ
      --メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok             -- アプリケーション短縮名
                    , iv_name         => cv_prof_get_err_msg  -- メッセージコード
                    , iv_token_name1  => cv_iv_token_name1    -- トークンコード1
                    , iv_token_value1 => cv_profile_name      -- トークン値1
                    );
      ov_errbuf  := lv_out_msg;
      ov_retcode := gv_status_error;
      ov_errmsg  := lv_out_msg;
    -- OTHERSエラー
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_set_of_books_info_p;
--
  /**********************************************************************************
   * Procedure Name   : get_close_date_p
   * Description      : 締め・支払日取得
   ***********************************************************************************/
  PROCEDURE get_close_date_p(
    ov_errbuf     OUT VARCHAR2          -- ログに出力するエラー・メッセージ
  , ov_retcode    OUT VARCHAR2          -- リターンコード
  , ov_errmsg     OUT VARCHAR2          -- ユーザーに見せるエラー・メッセージ
  , id_proc_date  IN  DATE DEFAULT NULL -- 処理日(対象日)
  , iv_pay_cond   IN  VARCHAR2          -- 支払条件(IN)
  , od_close_date OUT DATE              -- 締め日(OUT)
  , od_pay_date   OUT DATE              -- 支払日(OUT)
  )
  IS
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_close_date_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    ld_proc_date      DATE;         -- 対象日
    lv_close_day      VARCHAR2(10); -- 締め日
    lv_pay_day        VARCHAR2(10); -- 支払日
    lv_site           VARCHAR2(10); -- サイト
    ld_close_date     DATE;         -- 締め日の月末
    ld_pay_date       DATE;         -- 支払日の月末
    lv_chk_close_date VARCHAR2(2);  -- 締め日の月末日(日付チェック用)
    lv_chk_pay_date   VARCHAR2(2);  -- 支払日の月末日(日付チェック用)
    lv_close_year     VARCHAR2(30); -- 締め日（年月）
    lv_pay_year       VARCHAR2(30); -- 支払日（年月）
--
  BEGIN
    ov_retcode := gv_status_normal; -- リターンコードを初期化する。
--
    IF( id_proc_date IS NULL ) THEN
      --INパラメータ処理日=NULLの場合
      --対象日に業務日付を設定
      ld_proc_date := xxccp_common_pkg2.get_process_date;
    ELSE
      --INパラメータ処理日<>NULLの場合
      --対象日にINパラメータの処理日を設定
      ld_proc_date := id_proc_date; -- INパラメータの処理日を設定する。
    END IF;
    -- =========================================
    -- 支払条件XX_YY_ZZ を受け取る
    -- XX：締め日(日にち)
    -- YY：支払日(日にち)
    -- ZZ：サイト(支払月が何ヵ月後なのかを指定)
    -- =========================================
    -- ===============================
    -- 締め日(日にち)を抽出する。
    -- ===============================
    lv_close_day := SUBSTR( iv_pay_cond, 1, 2 );
    -- ===============================
    -- 支払日(日にち)を抽出する。
    -- ===============================
    lv_pay_day   := SUBSTR( iv_pay_cond, 4, 2 );
    -- ===============================
    -- サイトを抽出する。
    -- ===============================
    lv_site      := SUBSTR( iv_pay_cond, 7, 2 );
    -- ====================================================================
    -- 支払条件が00_00_00だった場合、即時払いを示す日付を戻り値に設定する。
    -- ====================================================================
    IF(     ( lv_close_day = '00' )
         AND( lv_pay_day   = '00' )
         AND( lv_site      = '00' )
    ) THEN
      od_close_date  := ld_proc_date;
      od_pay_date    := ld_proc_date;
    -- ====================================================
    -- 支払条件が00_00_00でなかった場合、以下の処理を行う。
    -- 締め日と支払日の月末の日付を求める。
    -- ====================================================
    ELSE
      ld_close_date := LAST_DAY( ld_proc_date );
      ld_pay_date   := LAST_DAY( ADD_MONTHS( ld_proc_date, TO_NUMBER( lv_site ) ) );
      -- ====================================================
      -- 支払条件.締め日が30だった場合、月末払いとなる。
      -- ====================================================
      IF( lv_close_day = '30' ) THEN
        lv_close_day := SUBSTR( TO_CHAR( ld_close_date, 'YYYY/MM/DD' ), 9, 2 );
      END IF;
      -- ====================================================
      -- 支払条件.支払日が30だった場合、月末払いとなる。
      -- ====================================================
      IF (lv_pay_day = '30') THEN
        lv_pay_day  := SUBSTR (TO_CHAR( ld_pay_date, 'YYYY/MM/DD' ), 9, 2 );
      END IF;
      -- ==================================================================
      -- 支払条件.締め日が締め日末日より後の場合、締め日末日を締め日とする。
      -- ==================================================================
      -- 締め日末日取得
      lv_chk_close_date := SUBSTR( TO_CHAR( ld_close_date, 'YYYY/MM/DD' ), 9, 2 );
      IF ( TO_NUMBER( lv_close_day ) > TO_NUMBER( lv_chk_close_date ) ) THEN
        lv_close_day := lv_chk_close_date;
      END IF;
      -- ==================================================================
      -- 支払条件.支払日が支払日末日より後の場合、支払日末日を支払日とする。
      -- ==================================================================
      -- 支払日末日取得
      lv_chk_pay_date   := SUBSTR( TO_CHAR( ld_pay_date, 'YYYY/MM/DD' ), 9, 2 );
      IF ( TO_NUMBER( lv_pay_day )   > TO_NUMBER( lv_chk_pay_date ) ) THEN
        lv_pay_day   := lv_chk_pay_date;
      END IF;
      -- ===========================================
      -- 締め日と支払日の年月(YYYY/MM/)を抽出する。
      -- ===========================================
      lv_close_year := SUBSTR( TO_CHAR( ld_close_date, 'YYYY/MM/DD' ), 1, 8 );
      lv_pay_year   := SUBSTR( TO_CHAR( ld_pay_date,   'YYYY/MM/DD' ), 1, 8 );
      -- ===============================
      -- 締め日：年月 + 締め日(日にち)
      -- ===============================
      od_close_date := TO_DATE( ( lv_close_year || lv_close_day ), 'YYYY/MM/DD' );
      -- ========================================================
      -- 支払日：サイト（支払月）を反映した年月 + 支払日(日にち)
      -- ========================================================
      od_pay_date   := TO_DATE( ( lv_pay_year || lv_pay_day ), 'YYYY/MM/DD' );
    END IF;
    --=======================================
    -- 出力パラメータセット
    --=======================================
    ov_errbuf    := NULL;
    ov_errmsg    := NULL;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_retcode := gv_status_error;
      raise_application_error(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_close_date_p;
--
  /******************************************************************************
   *FUNCTION NAME : get_emp_code_f
   *Desctiption   : 従業員コード取得
   ******************************************************************************/
  FUNCTION get_emp_code_f(
    in_user_id IN NUMBER --1.ユーザID
  )
  RETURN VARCHAR2        --従業員コード
  IS
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_emp_code_f'; --プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    ld_process_date DATE;                      --業務日付
    lv_emp_code     VARCHAR2(30) DEFAULT NULL; --従業員コード
--
  BEGIN
    -- ==========================================
    -- 業務日付取得
    -- ==========================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- ===========================
    -- 従業員コードを取得
    -- ===========================
    SELECT papf.employee_number      AS emp_num --従業員コード
    INTO   lv_emp_code
    FROM   fnd_user                  fu
         , per_all_people_f          papf
    WHERE  in_user_id                = fu.user_id
    AND    fu.employee_id            = papf.person_id
    AND    ld_process_date BETWEEN fu.start_date
                               AND NVL( fu.end_date, ld_process_date )
    AND    ld_process_date BETWEEN papf.effective_start_date
                               AND NVL( papf.effective_end_date, ld_process_date );
--
    RETURN lv_emp_code; --ユーザIDに紐づく従業員コード
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_emp_code_f;
--
  /************************************************************************
  * Function Name   : check_acctg_period_f
  * Description     : 会計期間チェック
  ************************************************************************/
  FUNCTION check_acctg_period_f(
    in_set_of_books_id        IN NUMBER   -- 会計帳簿ID
  , id_proc_date              IN DATE     -- 処理日(対象日)
  , iv_application_short_name IN VARCHAR2 -- アプリケーション短縮名
  )
  RETURN BOOLEAN                          -- BOOLEAN型 TRUE/FALSE
  IS
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'check_acctg_period_f'; -- プログラム名
    cv_flag     CONSTANT VARCHAR2(1)  := 'N';                    -- 調整フラグの対象外の変数
    cv_open     CONSTANT VARCHAR2(1)  := 'O';                    -- ステータスがオープンの変数
    -- ==============================
    -- ローカル変数
    -- ==============================
    lt_closing_status gl_period_statuses.closing_status%TYPE; -- ステータスの変数
--
  BEGIN
    --=========================================================================
    --処理日に対応する会計期間がオープンしているかをチェック
    --=========================================================================
    SELECT gps.closing_status                     closing_status
    INTO   lt_closing_status
    FROM   gl_period_statuses                     gps
         , fnd_application                        fa
    WHERE  gps.application_id                   = fa.application_id                     -- アプリケーションIDが一致
    AND    fa.application_short_name            = iv_application_short_name             -- アプリケーション短縮名
    AND    gps.set_of_books_id                  = in_set_of_books_id                    -- 会計帳簿IDが一致
    AND    gps.adjustment_period_flag           = cv_flag                               -- 調整フラグが'N'
    AND    gps.start_date                      <= id_proc_date                          -- 開始日から処理日
    AND    gps.end_date                        >= id_proc_date;                         -- 処理日から終了日
--
    IF( lt_closing_status = cv_open ) THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END check_acctg_period_f;
--
  /************************************************************************
   * Function Name   : get_operating_day_f
   * Description     : 稼働日取得
   ************************************************************************/
  FUNCTION get_operating_day_f(
    id_proc_date     IN DATE             -- 処理日
  , in_days          IN NUMBER           -- 日数
  , in_proc_type     IN NUMBER           -- 処理区分
  , in_calendar_type IN NUMBER DEFAULT 0 -- カレンダー区分
  )
  RETURN DATE
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_xxcok_code    CONSTANT VARCHAR2(30) := 'XXCOK1_ORG_CODE_SALES'; -- COK用コード
    cv_sys_cal_code  CONSTANT VARCHAR2(30) := 'SYSTEM_CAL';            -- システムカレンダーコード
    cn_bef           CONSTANT NUMBER       := 1;                       -- 処理区分：前
    cn_aft           CONSTANT NUMBER       := 2;                       -- 処理区分：後
    cn_zero          CONSTANT NUMBER       := 0;                       -- INパラ日数 チェック値=0
    cv_prg_name      CONSTANT VARCHAR2(30) := 'get_operating_day_f';   -- プログラム名
    cn_cal_type_zero CONSTANT NUMBER       := 0;                       -- カレンダー区分=0(組織パラメータ)
    cn_cal_type_one  CONSTANT NUMBER       := 1;                       -- カレンダー区分=1(システムカレンダ)
    -- =======================================================
    -- ローカル変数
    -- ===============================================
    lt_operating_day  bom_calendar_dates.calendar_date%TYPE; -- 営業日（戻り値）
    lt_calendar_code  mtl_parameters.calendar_code%TYPE;     --カレンダーコード
    lt_calendar_date  bom_calendar_dates.calendar_date%TYPE; --検索条件用の営業日
    lt_seq_num        bom_calendar_dates.seq_num%TYPE;       --シーケンス番号
    lt_next_seq_num   bom_calendar_dates.next_seq_num%TYPE;  --ネクストシーケンス番号
    lt_prior_seq_num  bom_calendar_dates.prior_seq_num%TYPE; --前のシーケンス番号
    lt_cndtn_seq_num  bom_calendar_dates.seq_num%TYPE;       --検索条件設定用シーケンス番号
--
    BEGIN
    -- ==========================================
    -- プロファイル値判定処理
    -- ==========================================
    IF( in_calendar_type = cn_cal_type_zero ) THEN
      --INパラメータ カレンダー区分=0(組織パラメータ)の場合
      -- ==========================================
      -- 稼動日カレンダー検索用カレンダーコード取得
      -- ==========================================
      SELECT mp.calendar_code     AS calendar_code        -- カレンダーコード
      INTO   lt_calendar_code
      FROM   mtl_parameters       mp
      WHERE  mp.organization_code = FND_PROFILE.VALUE( cv_xxcok_code );
    ELSE
      IF( in_calendar_type = cn_cal_type_one ) THEN
        --INパラメータ カレンダー区分<>0(組織パラメータ)以外の場合
        --カレンダーコードにシステムカレンダーコードを設定
        lt_calendar_code := cv_sys_cal_code;
      END IF;
    END IF;
    -- ==========================================
    -- 稼動日チェック用データ取得
    --  *CALENDAR_DATE, SEQ_NUM, NEXT_SEQ_NUM,
    --  *PRIOR_SEQ_NUM 取得
    -- ==========================================
    SELECT bcd.calendar_date  AS calendar_date -- 稼動日
         , bcd.seq_num        AS seq_num       -- シーケンス番号
         , bcd.next_seq_num   AS next_seq_num  -- 次シーケンス番号
         , bcd.prior_seq_num  AS prior_seq_num -- 前シーケンス番号
    INTO   lt_calendar_date
         , lt_seq_num
         , lt_next_seq_num
         , lt_prior_seq_num
    FROM   bom_calendar_dates bcd           -- テーブル「稼働日カレンダ」
    WHERE  bcd.calendar_date  = id_proc_date
    AND    bcd.calendar_code  = lt_calendar_code;
    -- ==========================================
    -- 稼動日チェックと検索条件の設定
    --  * SEQ_NUM≠NULLの場合 稼動日
    --  * SEQ_NUM=NULLの場合  非稼動日
    -- ==========================================
    -- SEQ_NUM=NULLの場合  非稼動日
    IF( lt_seq_num IS NULL ) THEN
      -- INパラメータ 日数=0の場合
      IF( in_days = cn_zero  ) THEN
        --処理区分  = 前の場合
        IF( in_proc_type = cn_bef ) THEN
           --==========================================
           --INパラ 処理日 =非稼動日 かつ
           --INパラ処理区分=前       かつ
           --INパラ日数    =zero の場合
           --=>INパラ 処理日より1日前の営業日を取得する
           --==========================================
           lt_cndtn_seq_num := lt_prior_seq_num;
        END IF;
        --処理区分  = 後の場合
        IF( in_proc_type = cn_aft ) THEN
           --==========================================
           --INパラ 処理日  =非稼動日 かつ
           --INパラ処理区分 =後       かつ
           --INパラ日数     =zero の場合
           --=>INパラ 処理日より1日後の営業日を取得する
           --==========================================
           lt_cndtn_seq_num := lt_next_seq_num;
        END IF;
      ELSE
        -- INパラメータ 日数=0以外の場合
        IF( in_days > cn_zero ) THEN
          --==========================================
          --INパラ 処理日  =非稼動日 かつ
          --INパラ日数=zero以上の場合
          --=>INパラ 処理日よりINパラ 日数分後の営業日を取得する
          --==========================================
          lt_cndtn_seq_num := lt_prior_seq_num + in_days;
        ELSE
          --==========================================
          --INパラ 処理日  =非稼動日 かつ
          --INパラ日数=zero以下の場合
          --=>INパラ 処理日よりINパラ 日数分前の営業日を取得する
          --==========================================
          lt_cndtn_seq_num := lt_next_seq_num + in_days;
        END IF;
      END IF;
    -- SEQ_NUM≠NULLの場合 稼動日
    ELSE
      -- INパラメータ 日数=0 の場合
      IF( in_days = cn_zero ) THEN
        --==========================================
        --INパラ 処理日  =稼動日 かつ
        --INパラ 日数    =zero   の場合
        --=>INパラ処理日(=営業日)当日を取得する
        --==========================================
        lt_cndtn_seq_num := lt_seq_num;
      ELSE
        --==========================================
        --INパラ 処理日  =稼動日 かつ
        --INパラ 日数    =zero以上の場合
        --=>INパラ 処理日からINパラ 日数分加算した営業日を取得する
        --==========================================
        lt_cndtn_seq_num := lt_seq_num + in_days;
      END IF;
    END IF;
    -- ==========================================
    -- 「営業日」を取得する。
    -- ==========================================
    SELECT bcd.calendar_date  AS calendar_date    -- 営業日
    INTO   lt_operating_day
    FROM   bom_calendar_dates bcd                 -- テーブル「稼働日カレンダ」
    WHERE  bcd.calendar_code  = lt_calendar_code  -- カレンダーコード
    AND    bcd.seq_num        = lt_cndtn_seq_num; -- 営業日のシーケンス番号
    -- ===============
    -- 戻り値に設定
    -- ===============
    RETURN( lt_operating_day ); -- 営業日
--
  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_operating_day_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_sales_staff_code_f
   *Desctiption   : 担当営業員コード取得
   ******************************************************************************/
   FUNCTION get_sales_staff_code_f(
    iv_customer_code IN VARCHAR2 -- 顧客コード
  , id_proc_date     IN DATE     -- 処理日
  )
  RETURN VARCHAR2                -- 担当営業員コード
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_sales_staff_code_f'; -- プログラム名
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    lt_sales_staff_code jtf_rs_resource_extns.source_number%TYPE DEFAULT NULL; -- 担当営業員コード
--
  BEGIN
    -- =======================================================
    -- 担当営業員コードの取得
    -- =======================================================
    SELECT jrre.source_number         AS sales_staff_code -- 担当営業員コード
    INTO   lt_sales_staff_code
    FROM   hz_cust_accounts           hca                 -- 顧客マスタ
         , hz_organization_profiles   hop                 -- 組織プロファイル
         , ego_resource_agv           era                 -- リソースビュー
         , jtf_rs_resource_extns      jrre                -- リソース
         , per_all_people_f           papf                -- 従業員
    WHERE  hca.account_number          = iv_customer_code -- 顧客コード
    AND    hca.party_id                = hop.party_id
-- 2009/04/15 Ver.1.11 [障害T1_0570] SCS K.Yamaguchi REPAIR START
--    AND    TRUNC( hop.effective_start_date )                          <= TRUNC( id_proc_date )
--    AND    TRUNC( NVL( hop.effective_end_date, id_proc_date ) )       >= TRUNC( id_proc_date )
    AND    TRUNC( hop.effective_start_date )                          <= TRUNC( SYSDATE )
    AND    TRUNC( NVL( hop.effective_end_date, SYSDATE ) )            >= TRUNC( SYSDATE )
-- 2009/04/15 Ver.1.11 [障害T1_0570] SCS K.Yamaguchi REPAIR END
    AND    hop.organization_profile_id = era.organization_profile_id
    AND    TRUNC( NVL( era.resource_s_date, TRUNC( id_proc_date ) ) ) <= TRUNC( id_proc_date )
    AND    TRUNC( NVL( era.resource_e_date, TRUNC( id_proc_date ) ) ) >= TRUNC( id_proc_date )
    AND    jrre.source_number          = era.resource_no
    AND    papf.person_id              = jrre.source_id
    AND    TRUNC( NVL( papf.effective_start_date, id_proc_date ) )    <= TRUNC( id_proc_date )
    AND    TRUNC( NVL( papf.effective_end_date, id_proc_date ) )      >= TRUNC( id_proc_date );
    -- 取得値を戻す
    RETURN lt_sales_staff_code;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- 該当するレコードが存在しなかった場合はNULLを返す
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END get_sales_staff_code_f;
--
  /**********************************************************************************
   * Procedure Name   : get_wholesale_req_est_p
   * Description      : 問屋請求見積照合
   ***********************************************************************************/
-- 2010/04/21 Ver.1.13 [E_本稼動_02088] SCS K.Yamaguchi REPAIR START
--  PROCEDURE get_wholesale_req_est_p(
--    ov_errbuf                      OUT VARCHAR2 -- エラーバッファ
--  , ov_retcode                     OUT VARCHAR2 -- リターンコード
--  , ov_errmsg                      OUT VARCHAR2 -- エラーメッセージ
--  , iv_wholesale_code              IN  VARCHAR2 -- 問屋管理コード
--  , iv_sales_outlets_code          IN  VARCHAR2 -- 問屋帳合先コード
--  , iv_item_code                   IN  VARCHAR2 -- 品目コード
--  , in_demand_unit_price           IN  NUMBER   -- 支払単価
--  , iv_demand_unit_type            IN  VARCHAR2 -- 請求単位
--  , iv_selling_month               IN  VARCHAR2 -- 売上対象年月
--  , ov_estimated_no                OUT VARCHAR2 -- 見積書No.
--  , on_quote_line_id               OUT NUMBER   -- 明細ID
--  , ov_emp_code                    OUT VARCHAR2 -- 担当者コード
--  , on_market_amt                  OUT NUMBER   -- 建値
--  , on_allowance_amt               OUT NUMBER   -- 値引(割戻し)
--  , on_normal_store_deliver_amt    OUT NUMBER   -- 通常店納
--  , on_once_store_deliver_amt      OUT NUMBER   -- 今回店納
--  , on_net_selling_price           OUT NUMBER   -- NET価格
--  , ov_estimated_type              OUT VARCHAR2 -- 見積区分
--  , on_backmargin_amt              OUT NUMBER   -- 販売手数料
--  , on_sales_support_amt           OUT NUMBER   -- 販売協賛金
--  )
--  IS
--    -- =======================================================
--    -- ローカル定数
--    -- =======================================================
--    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_wholesale_req_est_p'; -- プログラム名
--    cv_quote_type_sale             CONSTANT VARCHAR2(1)  := '1';                       -- 見積種別 1:販売先用
--    cv_quote_type_wholesale        CONSTANT VARCHAR2(1)  := '2';                       -- 見積種別 2:帳合問屋先用
--    cv_status_decision             CONSTANT VARCHAR2(1)  := '2';                       -- ステータス= 2:確定
--    cv_quote_div_usuall            CONSTANT VARCHAR2(1)  := '1';                       -- 見積区分 1:通常
--    cn_one                         CONSTANT NUMBER       := 1;                         -- 数値:1
--    cv_zero                        CONSTANT VARCHAR2(1)  := '0';                       -- 文字列:0
--    cv_organization_cd             CONSTANT VARCHAR2(30) := 'XXCOK1_ORG_CODE_SALES';   -- COK用_組織コード
--    cv_unit_type_count             CONSTANT VARCHAR2(1)  := '1';                       -- 単価区分:1(本数)
--    cv_unit_type_cs                CONSTANT VARCHAR2(1)  := '2';                       -- 単価区分:2(C/S)
--    -- =======================================================
--    -- ローカル変数
--    -- =======================================================
--    ln_count                       NUMBER ;    -- 件数
--    ln_price_check_on_flg          NUMBER DEFAULT 0; -- 照合結果判定フラグ
--    ln_sql_data_not_flg            NUMBER DEFAULT 0; -- 1件目見積区分判定フラグ
--    -- =======================================================
--    -- ローカルRECORD型
--    -- =======================================================
--    --問屋請求見積1 レコード定義
--    TYPE l_wholesale_req1_rtype    IS RECORD(
--      lv_quote_number              xxcso_quote_headers.quote_number             %TYPE -- 帳合問屋用見積ヘッダー.見積書番号
--    , lv_employee_number           xxcso_quote_headers.employee_number          %TYPE -- 帳合問屋用見積ヘッダー.担当者コード
--    , lv_quote_div                 xxcso_quote_lines.quote_div                  %TYPE -- 販売先用見積明細.見積区分
--    , ln_usually_deliv_price       xxcso_quote_lines.usually_deliv_price        %TYPE -- 販売先用見積明細.通常店納価格
--    , ln_this_time_deliv_price     xxcso_quote_lines.this_time_deliv_price      %TYPE -- 販売先用見積明細.今回店納価格
--    , ln_quote_line_id             xxcso_quote_lines.quote_line_id              %TYPE -- 帳合問屋用見積明細.見積明細ID
--    , ln_quotation_price           xxcso_quote_lines.quotation_price            %TYPE -- 帳合問屋用見積明細.建値
--    , ln_sales_discount_price      xxcso_quote_lines.sales_discount_price       %TYPE -- 帳合問屋用見積明細.売上値引
--    , ln_usuall_net_price          xxcso_quote_lines.usuall_net_price           %TYPE -- 帳合問屋用見積明細.通常NET価格
--    , ln_this_time_net_price       xxcso_quote_lines.this_time_net_price        %TYPE -- 帳合問屋用見積明細.今回NET価格
--    );
--    --問屋請求見積2 レコード定義
--    TYPE l_wholesale_req2_rtype    IS RECORD(
--      lv_quote_number              xxcso_quote_headers.quote_number             %TYPE -- 帳合問屋用見積ヘッダー.見積書番号
--    , lv_employee_number           xxcso_quote_headers.employee_number          %TYPE -- 帳合問屋用見積ヘッダー.担当者コード
--    , lv_quote_div                 xxcso_quote_lines.quote_div                  %TYPE -- 販売先用見積明細.見積区分
--    , ln_usually_deliv_price       xxcso_quote_lines.usually_deliv_price        %TYPE -- 販売先用見積明細.通常店納価格
--    , ln_this_time_deliv_price     xxcso_quote_lines.this_time_deliv_price      %TYPE -- 販売先用見積明細.今回店納価格
--    , ln_quote_line_id             xxcso_quote_lines.quote_line_id              %TYPE -- 帳合問屋用見積明細.見積明細ID
--    , ln_quotation_price           xxcso_quote_lines.quotation_price            %TYPE -- 帳合問屋用見積明細.建値
--    , ln_sales_discount_price      xxcso_quote_lines.sales_discount_price       %TYPE -- 帳合問屋用見積明細.売上値引
--    , ln_usuall_net_price          xxcso_quote_lines.usuall_net_price           %TYPE -- 帳合問屋用見積明細.通常NET価格
--    , ln_this_time_net_price       xxcso_quote_lines.this_time_net_price        %TYPE -- 帳合問屋用見積明細.今回NET価格
--    , lv_iim_b_case_in_num         ic_item_mst_b.attribute11                    %TYPE -- OPM品目マスタ.ケース入り数（DFF11)
--    );
--    -- =======================================================
--    -- ローカルTABLE型
--    -- =======================================================
--    --問屋請求見積1 レコードの結合配列 定義
--    TYPE  l_wholesale_req1_ttype   IS TABLE OF l_wholesale_req1_rtype
--      INDEX BY PLS_INTEGER;
--    --問屋請求見積2 レコードの結合配列 定義
--    TYPE  l_wholesale_req2_ttype   IS TABLE OF l_wholesale_req2_rtype
--      INDEX BY PLS_INTEGER;
--    -- =======================================================
--    -- ローカルPL/SQL表
--    -- =======================================================
--    --問屋請求見積1 結合配列
--    l_wholesale_req1_tab           l_wholesale_req1_ttype;
--    --問屋請求見積2 結合配列
--    l_wholesale_req2_tab           l_wholesale_req2_ttype;
----
--  BEGIN
--    -- =======================================================
--    -- INパラメータ品目コードNULLチェック
--    -- =======================================================
--    IF( iv_item_code IS NULL ) THEN
--      ln_price_check_on_flg := 0;  --照合結果判定フラグ  オフ
--    ELSE
--      BEGIN
--        -- =======================================================
--        -- ①SQL
--        -- =======================================================
--        SELECT   -- 帳合問屋用見積ヘッダー.見積書番号
--                 csoqh_wholesale.quote_number                  AS wholesale_quote_number
--                 -- 帳合問屋用見積ヘッダー.担当者コード
--               , csoqh_wholesale.employee_number               AS wholesale_employee_number
--                 -- 販売先用見積明細.見積区分
--               , csoql_sale.quote_div                          AS sale_quote_div
--                 -- 販売先用見積明細.通常店納価格
--               , NVL( csoql_sale.usually_deliv_price, 0 )      AS sale_usually_deliv_price
--                 -- 販売先用見積明細.今回店納価格
--               , NVL( csoql_sale.this_time_deliv_price, 0 )    AS sale_this_time_deliv_price
--                 -- 帳合問屋用見積明細.見積明細ID
--               , csoql_wholesale.quote_line_id                 AS wholesale_quote_line_id
--                 -- 帳合問屋用見積明細.建値
--               , NVL( csoql_wholesale.quotation_price, 0 )     AS wholesale_quotation_price
--                 -- 帳合問屋用見積明細.売上値引
--               , NVL( csoql_wholesale.sales_discount_price, 0 )  AS wholesale_sales_discount_price
--                 -- 帳合問屋用見積明細.通常NET価格
--               , NVL( csoql_wholesale.usuall_net_price, 0 )    AS wholesale_usuall_net_price
--                 -- 帳合問屋用見積明細.今回NET価格
--               , NVL( csoql_wholesale.this_time_net_price, 0 ) AS wholesale_this_time_net_price
--        BULK COLLECT INTO l_wholesale_req1_tab  --問屋請求見積1 結合配列
--        FROM     -- 販売先用見積ヘッダー
--                 xxcso_quote_headers                           csoqh_sale
--                 -- 販売先用見積明細
--               , xxcso_quote_lines                             csoql_sale
--                 -- 帳合問屋用見積ヘッダー
--               , xxcso_quote_headers                           csoqh_wholesale
--                 -- 帳合問屋用見積明細
--               , xxcso_quote_lines                             csoql_wholesale
--                 -- Disc品目マスタ
--               , mtl_system_items_b                            msi_b
--                 -- 組織パラメータ
--               , mtl_parameters                                mp
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi ADD START
--                 -- 顧客追加情報
--               , xxcmm_cust_accounts                           xca
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi ADD END
--        WHERE    -- 条件抽出条件
--                 -- 販売先用見積ヘッダー．見積ヘッダーID     = 販売先用見積明細．見積ヘッダーID
--                 csoqh_sale.quote_header_id                  = csoql_sale.quote_header_id
--                 -- 帳合問屋用見積ヘッダー．見積ヘッダーID   = 帳合問屋用見積明細．見積ヘッダーID
--        AND      csoqh_wholesale.quote_header_id             = csoql_wholesale.quote_header_id
--                 -- 販売先用見積ヘッダー．見積書番号         =  帳合問屋用見積ヘッダー．参照見積番号
--        AND      csoqh_sale.quote_number                     = csoqh_wholesale.reference_quote_number
--                 -- 販売先用見積明細．見積明細ID             = 帳合問屋用見積．参照用見積明細ＩＤ
--        AND      csoql_sale.quote_line_id                    = csoql_wholesale.reference_quote_line_id
--                 -- Disc品目マスタ．品目ID                   = 販売先用見積明細．品目ID
--        AND      msi_b.inventory_item_id                     = csoql_sale.inventory_item_id
--                 -- 販売先用見積ヘッダー．見積種別           = '1'(販売先)
--        AND      csoqh_sale.quote_type                       = cv_quote_type_sale
--                 -- 販売先用見積ヘッダー．ステータス         = '2'(確定)
--        AND      csoqh_sale.status                           = cv_status_decision
--                 -- 帳合問屋用見積ヘッダー．見積種別         = '2'(帳合問屋)
--        AND      csoqh_wholesale.quote_type                  = cv_quote_type_wholesale
--                 -- 帳合問屋用見積ヘッダー．ステータス       = '2'(確定)
--        AND      csoqh_wholesale.status                      = cv_status_decision
--                 -- Disc品目マスタ．組織ID                   = 組織パラメータ．組織ID
--        AND      msi_b.organization_id                       = mp.organization_id
--                 -- 販売先用見積ヘッダー．顧客コード         = 入力パラメータ．問屋帳合先コード
--        AND      csoqh_sale.account_number                   = iv_sales_outlets_code
--                 -- Disc品目マスタ．品目コード               = 入力パラメータ．品目コード
--        AND      msi_b.segment1                              = iv_item_code
---- 2009/04/13 Ver.1.10 [障害T1_0411] SCS K.Yamaguchi REPAIR START
----                 -- 販売先用見積明細．期間（開始）           <= 入力パラメータ．売上対象年月
----        AND      csoql_sale.quote_start_date                 <= TO_DATE( iv_selling_month , 'YYYY/MM' )
----                 -- 販売先用見積明細．期間（終了）           >= 入力パラメータ．売上対象年月
----        AND      csoql_sale.quote_end_date                   >= TO_DATE( iv_selling_month , 'YYYY/MM' )
--                 -- 販売先用見積明細．期間（開始）           <= 入力パラメータ．売上対象年月
--        AND      TO_CHAR( csoql_sale.quote_start_date, 'YYYYMM' ) <= iv_selling_month
--                 -- 販売先用見積明細．期間（終了）           >= 入力パラメータ．売上対象年月
--        AND      TO_CHAR( csoql_sale.quote_end_date  , 'YYYYMM' ) >= iv_selling_month
---- 2009/04/13 Ver.1.10 [障害T1_0411] SCS K.Yamaguchi REPAIR END
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi REPAIR START
----                 -- 帳合問屋用見積ヘッダー．顧客コード       = 入力パラメータ．帳合問屋コード
----        AND      csoqh_wholesale.account_number              = iv_wholesale_code
--                 -- 帳合問屋用見積ヘッダー．顧客コード       = 顧客追加情報．顧客コード
--        AND      csoqh_wholesale.account_number              = xca.customer_code
--                 -- 顧客追加情報．問屋管理コード             = 入力パラメータ．問屋管理コード
--        AND      xca.wholesale_ctrl_code                     = iv_wholesale_code
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi REPAIR END
--                 -- 帳合問屋用見積ヘッダー．単価区分         = 入力パラメータ．請求単位
--        AND      csoqh_wholesale.unit_type                   = iv_demand_unit_type
---- 2009/04/13 Ver.1.10 [障害T1_0411] SCS K.Yamaguchi REPAIR START
----                 -- 帳合問屋用見積明細．期間（開始）         <= 入力パラメータ．売上対象年月
----        AND      csoql_wholesale.quote_start_date            <= TO_DATE( iv_selling_month , 'YYYY/MM' )
----                 -- 帳合問屋用見積明細．期間（終了）         >= 入力パラメータ．売上対象年月
----        AND      csoql_wholesale.quote_end_date              >= TO_DATE( iv_selling_month , 'YYYY/MM' )
--                 -- 帳合問屋用見積明細．期間（開始）         <= 入力パラメータ．売上対象年月
--        AND      TO_CHAR( csoql_wholesale.quote_start_date, 'YYYYMM' ) <= iv_selling_month
--                 -- 帳合問屋用見積明細．期間（終了）         >= 入力パラメータ．売上対象年月
--        AND      TO_CHAR( csoql_wholesale.quote_end_date  , 'YYYYMM' ) >= iv_selling_month
---- 2009/04/13 Ver.1.10 [障害T1_0411] SCS K.Yamaguchi REPAIR END
--                 -- 組織パラメータ．組織コード               = FND_PROFILE．VALUE('XXCOK1_ORG_CODE_SALES')
--        AND      mp.organization_code                        = FND_PROFILE.VALUE( cv_organization_cd )
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi REPAIR START
----        ORDER BY -- 販売先用見積明細.見積区分                昇順
----                 csoql_sale.quote_div                        ASC
----                 -- 販売先用見積明細.今回店納価格            降順
----               , csoql_sale.this_time_deliv_price            DESC NULLS LAST
----                 -- 帳合問屋用見積明細.今回NET価格           降順
----               , csoql_wholesale.this_time_net_price         DESC NULLS LAST;
--        ORDER BY -- 販売先用見積明細.見積区分                昇順
--                 csoql_sale.quote_div                        ASC
--                 -- 販売先用見積明細.今回店納価格            降順
--               , csoql_sale.this_time_deliv_price            DESC NULLS LAST
--                 -- 帳合問屋用見積明細.今回NET価格           降順
--               , csoql_wholesale.this_time_net_price         DESC NULLS LAST
--                 -- 帳合問屋用見積ヘッダ．発行日             降順
--               , csoqh_wholesale.publish_date                DESC NULLS LAST
--        ;
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi REPAIR END
--      END;
--      -- =======================================================
--      -- 問屋請求見積照合1
--      -- =======================================================
--      << loop_1 >>
--      FOR ln_count IN NVL( l_wholesale_req1_tab.FIRST, 0 ) ..NVL( l_wholesale_req1_tab.LAST, 0 ) LOOP
--        BEGIN
--          -- =======================================================
--          -- ②単価照合
--          -- =======================================================
--          -- =====================================
--          --①.FETCHしたレコードの
--          --1件目.見積区分<>「1(通常)」の場合
--          --1件目の見積区分が「1(通常)」以外の場合
--          -- =====================================
--          IF( l_wholesale_req1_tab( cn_one ).lv_quote_div <> cv_quote_div_usuall ) THEN
--            ln_price_check_on_flg := 1;  --照合結果判定フラグ  オン
--            ln_sql_data_not_flg   := 1;  -- 1件目見積区分判定フラグ
--            EXIT loop_1;                        --LOOP 処理から離脱
--          END IF;
--          -- =====================================
--          --①.見積区分=「1(通常)」且つ
--          --①.建値 - ①.売上値引 - ①.通常NET価格
--          --   = 入力パラメータ.支払単価
--          --     (in_demand_unit_price)の場合
--          -- =====================================
--          IF(     ( l_wholesale_req1_tab( ln_count ).lv_quote_div = cv_quote_div_usuall )
--              AND ( in_demand_unit_price
--                      = (   l_wholesale_req1_tab( ln_count ).ln_quotation_price
--                          - l_wholesale_req1_tab( ln_count ).ln_sales_discount_price
--                          - l_wholesale_req1_tab( ln_count ).ln_usuall_net_price   )
--                  )
--          ) THEN
--            --・販売手数料 = ①.建値 - ①.売上値引 - ①.通常NET価格
--            on_backmargin_amt := l_wholesale_req1_tab( ln_count ).ln_quotation_price
--                               - l_wholesale_req1_tab( ln_count ).ln_sales_discount_price
--                               - l_wholesale_req1_tab( ln_count ).ln_usuall_net_price;
--            IF( l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price = 0 ) THEN
--              --・販売協賛金 = 0 ※今回店納が0の場合は0
--              on_sales_support_amt := 0;
--            ELSE
--              --・販売協賛金 = ①.通常店納 - ①.今回店納
--              on_sales_support_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
--                                   -  l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;
--            END IF;
--            ov_estimated_no             := l_wholesale_req1_tab( ln_count ).lv_quote_number;         -- 見積書No.
--            on_quote_line_id            := l_wholesale_req1_tab( ln_count ).ln_quote_line_id;        -- 明細ID
--            ov_emp_code                 := l_wholesale_req1_tab( ln_count ).lv_employee_number;      -- 担当者コード
--            on_market_amt               := l_wholesale_req1_tab( ln_count ).ln_quotation_price;      -- 通常建値
--            on_allowance_amt            := l_wholesale_req1_tab( ln_count ).ln_sales_discount_price; -- 値引(割戻し)
--            on_normal_store_deliver_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price;  -- 通常店納
--            on_once_store_deliver_amt   := l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;-- 今回店納
--            on_net_selling_price        := l_wholesale_req1_tab( ln_count ).ln_usuall_net_price;     -- NET価格
--            ov_estimated_type           := l_wholesale_req1_tab( ln_count ).lv_quote_div;            -- 見積区分
--            ln_price_check_on_flg := 1;  --照合結果判定フラグ  オン
--            EXIT loop_1;                       --LOOP 処理から離脱
--          END IF;
--          -- =====================================
--          --①.見積区分が「1」以外  且つ
--          --①.建値 - ①.売上値引 - ①.今回NET価格
--          --= 入力パラメータ.支払単価
--          --    (in_demand_unit_price)の場合
--          -- =====================================
--          IF(     ( l_wholesale_req1_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
--              AND ( in_demand_unit_price
--                      = (   l_wholesale_req1_tab( ln_count ).ln_quotation_price
--                          - l_wholesale_req1_tab( ln_count ).ln_sales_discount_price
--                          - l_wholesale_req1_tab( ln_count ).ln_this_time_net_price )
--                  )
--          ) THEN
--            --・販売手数料 = ①.建値 - ①.売上値引 - ①.通常店納 + ①.今回店納 - ①.今回NET価格
--            on_backmargin_amt    := l_wholesale_req1_tab( ln_count ).ln_quotation_price
--                                  - l_wholesale_req1_tab( ln_count ).ln_sales_discount_price
--                                  - l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
--                                  + l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price
--                                  - l_wholesale_req1_tab( ln_count ).ln_this_time_net_price;
--            --・販売協賛金 = ①.通常店納 - ①.今回店納
--            on_sales_support_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
--                                  - l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;
----
--            ov_estimated_no             := l_wholesale_req1_tab( ln_count ).lv_quote_number;         -- 見積書No.
--            on_quote_line_id            := l_wholesale_req1_tab( ln_count ).ln_quote_line_id;        -- 明細ID
--            ov_emp_code                 := l_wholesale_req1_tab( ln_count ).lv_employee_number;      -- 担当者コード
--            on_market_amt               := l_wholesale_req1_tab( ln_count ).ln_quotation_price;      -- 通常建値
--            on_allowance_amt            := l_wholesale_req1_tab( ln_count ).ln_sales_discount_price; -- 値引(割戻し)
--            on_normal_store_deliver_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price;  -- 通常店納
--            on_once_store_deliver_amt   := l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;-- 今回店納
--            on_net_selling_price        := l_wholesale_req1_tab( ln_count ).ln_this_time_net_price;  -- NET価格
--            ov_estimated_type           := l_wholesale_req1_tab( ln_count ).lv_quote_div;            -- 見積区分
----
--            ln_price_check_on_flg := 1; --照合結果判定フラグ  オン
--            EXIT loop_1;                       --LOOP 処理から離脱
--          END IF;
--          -- =====================================
--          --①.見積区分が「1」以外  且つ
--          --①.建値 - ①.売上値引 - ①.通常店納 + ①.今回店納 - ①.今回NET価格
--          -- = 入力パラメータ.支払単価
--          --      (in_demand_unit_price)の場合
--          -- =====================================
--          IF(     ( l_wholesale_req1_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
--              AND ( in_demand_unit_price
--                      = (   l_wholesale_req1_tab( ln_count ).ln_quotation_price
--                          - l_wholesale_req1_tab( ln_count ).ln_sales_discount_price
--                          - l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
--                          + l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price
--                          - l_wholesale_req1_tab( ln_count ).ln_this_time_net_price )
--                  )
--          ) THEN
--            --・販売手数料 = 入力パラメータ.支払単価
--            on_backmargin_amt := in_demand_unit_price;
--            --・販売協賛金 = NULL
--            on_sales_support_amt := NULL;
--            ov_estimated_no             := l_wholesale_req1_tab( ln_count ).lv_quote_number;         -- 見積書No.
--            on_quote_line_id            := l_wholesale_req1_tab( ln_count ).ln_quote_line_id;        -- 明細ID
--            ov_emp_code                 := l_wholesale_req1_tab( ln_count ).lv_employee_number;      -- 担当者コード
--            on_market_amt               := l_wholesale_req1_tab( ln_count ).ln_quotation_price;      -- 通常建値
--            on_allowance_amt            := l_wholesale_req1_tab( ln_count ).ln_sales_discount_price; -- 値引(割戻し)
--            on_normal_store_deliver_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price;  -- 通常店納
--            on_once_store_deliver_amt   := l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;-- 今回店納
--            on_net_selling_price        := l_wholesale_req1_tab( ln_count ). ln_this_time_net_price; -- NET価格
--            ov_estimated_type           := l_wholesale_req1_tab( ln_count ).lv_quote_div;            -- 見積区分
--            ln_price_check_on_flg := 1;  --照合結果判定フラグ  オン
--            EXIT loop_1;                       --LOOP 処理から離脱
--          END IF;
--          -- =====================================
--          --①.見積区分が「1」以外  且つ
--          --①.通常店納 - ①.今回店納
--          -- = 入力パラメータ.支払単価
--          --      (in_demand_unit_price)の場合
--          -- =====================================
--          IF(     ( l_wholesale_req1_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
--              AND ( in_demand_unit_price
--                      = (   l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
--                          - l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price  )
--                  )
--          ) THEN
--            --・販売手数料 = NULL
--            on_backmargin_amt := NULL;
--            --・販売協賛金 = 入力パラメータ.支払単価
--            on_sales_support_amt := in_demand_unit_price;
--            ov_estimated_no             := l_wholesale_req1_tab( ln_count ).lv_quote_number;          -- 見積書No.
--            on_quote_line_id            := l_wholesale_req1_tab( ln_count ).ln_quote_line_id;         -- 明細ID
--            ov_emp_code                 := l_wholesale_req1_tab( ln_count ).lv_employee_number;       -- 担当者コード
--            on_market_amt               := l_wholesale_req1_tab( ln_count ).ln_quotation_price;       -- 通常建値
--            on_allowance_amt            := l_wholesale_req1_tab( ln_count ).ln_sales_discount_price;  -- 値引(割戻し)
--            on_normal_store_deliver_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price;   -- 通常店納
--            on_once_store_deliver_amt   := l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price; -- 今回店納
--            on_net_selling_price        := l_wholesale_req1_tab( ln_count ).ln_this_time_net_price;   -- NET価格
--            ov_estimated_type           := l_wholesale_req1_tab( ln_count ).lv_quote_div;             -- 見積区分
--            ln_price_check_on_flg := 1;  --照合結果判定フラグ  オン
--            EXIT loop_1;                       --LOOP 処理から離脱
--          END IF;
--          -- =====================================
--          --①.見積区分が「1」以外 且つ
--          --①.通常NET価格 - ①.今回NET価格
--          --= 入力パラメータ.支払単価
--          --      (in_demand_unit_price)の場合
--          -- =====================================
--          IF(     ( l_wholesale_req1_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
--              AND ( in_demand_unit_price
--                      = (   l_wholesale_req1_tab( ln_count ).ln_usuall_net_price
--                          - l_wholesale_req1_tab( ln_count ).ln_this_time_net_price )
--                  )
--          ) THEN
--            --・販売手数料 = (①.今回店納 - ①.今回NET価格)
--            --             - (①.通常店納 - ①.通常NET価格)
--            on_backmargin_amt    := (   (   l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price
--                                          - l_wholesale_req1_tab( ln_count ).ln_this_time_net_price   )
--                                      - (   l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
--                                          - l_wholesale_req1_tab( ln_count ).ln_usuall_net_price      )
--                                    );
--            --・販売協賛金 =  ①.通常店納 - ①.今回店納
--            on_sales_support_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
--                                  - l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;
--            ov_estimated_no             := l_wholesale_req1_tab( ln_count ).lv_quote_number;         -- 見積書No.
--            on_quote_line_id            := l_wholesale_req1_tab( ln_count ).ln_quote_line_id;        -- 明細ID
--            ov_emp_code                 := l_wholesale_req1_tab( ln_count ).lv_employee_number;      -- 担当者コード
--            on_market_amt               := l_wholesale_req1_tab( ln_count ).ln_quotation_price;      -- 通常建値
--            on_allowance_amt            := l_wholesale_req1_tab( ln_count ).ln_sales_discount_price; -- 値引(割戻し)
--            on_normal_store_deliver_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price;  -- 通常店納
--            on_once_store_deliver_amt   := l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;-- 今回店納
--            on_net_selling_price        := l_wholesale_req1_tab( ln_count ).ln_this_time_net_price;  -- NET価格
--            ov_estimated_type           := l_wholesale_req1_tab( ln_count ).lv_quote_div;            -- 見積区分
--            ln_price_check_on_flg := 1;  --照合結果判定フラグ  オン
--            EXIT loop_1;                       --LOOP 処理から離脱
--          END IF;
--        EXCEPTION
--          WHEN NO_DATA_FOUND THEN
--            ln_price_check_on_flg := 0;
--          WHEN OTHERS THEN
--            raise_application_error(
--              -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
--            );
--        END;
--      END LOOP loop_1; --l_wholesale_req1_tab LOOP END
----
--      IF( ln_price_check_on_flg = 0 ) THEN  --照合結果判定フラグ  オフ
--        -- =======================================================
--        -- ③SQL発行
--        -- =======================================================
--        SELECT   -- 帳合問屋用見積ヘッダー.見積書番号
--                 csoqh_wholesale.quote_number                  AS wholesale_quote_number
--                 -- 帳合問屋用見積ヘッダー.担当者コード
--               , csoqh_wholesale.employee_number               AS wholesale_employee_number
--                 -- 販売先用見積明細.見積区分
--               , csoql_sale.quote_div                          AS sale_quote_div
--                 -- 販売先用見積明細.通常店納価格
--               , NVL( csoql_sale.usually_deliv_price, 0 )      AS sale_usually_deliv_price
--                 -- 販売先用見積明細.今回店納価格
--               , NVL( csoql_sale.this_time_deliv_price, 0 )    AS csoql_sale_this_time_del_price
--                 -- 帳合問屋用見積明細.見積明細ID
--               , csoql_wholesale.quote_line_id                 AS wholesale_quote_line_id
--                 -- 帳合問屋用見積明細.建値
--               , NVL( csoql_wholesale.quotation_price , 0 )    AS wholesale_quotation_price
--                 -- 帳合問屋用見積明細.売上値引
--               , NVL( csoql_wholesale.sales_discount_price, 0 )  AS wholesale_sales_discount_price
--                 -- 帳合問屋用見積明細.通常NET価格
--               , NVL( csoql_wholesale.usuall_net_price, 0 )    AS wholesale_usuall_net_price
--                 -- 帳合問屋用見積明細 .今回NET価格
--               , NVL( csoql_wholesale.this_time_net_price, 0 ) AS wholesale_this_time_net_price
--                 -- OPM品目マスタ.ケース入り数（DFF11)
--               , iim_b.attribute11                             AS iim_b_case_in_num
--        -- 問屋請求見積2 結合配列
--        BULK COLLECT INTO l_wholesale_req2_tab
--        FROM     -- 見積ヘッダーテーブル:販売先用見積ヘッダー
--                 xxcso_quote_headers     csoqh_sale
--                 -- 見積明細テーブル    :販売先用見積明細
--               , xxcso_quote_lines     csoql_sale
--                 -- 見積ヘッダーテーブル:帳合問屋用見積ヘッダー
--               , xxcso_quote_headers   csoqh_wholesale
--                 -- 見積明細テーブル    :帳合問屋用見積明細
--               , xxcso_quote_lines     csoql_wholesale
--                 -- Disc品目マスタ      :Disc品目マスタ
--               , mtl_system_items_b    msi_b
--                 -- OPM品目マスタ       :OPM品目マスタ
--               , ic_item_mst_b         iim_b
--                 -- 組織パラメータ      :組織パラメータ
--               , mtl_parameters        mp
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi ADD START
--                 -- 顧客追加情報
--               , xxcmm_cust_accounts                           xca
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi ADD END
--        WHERE    -- ＜抽出条件＞
--                 -- 販売先用見積ヘッダー．見積ヘッダーID   = 販売先用見積明細．見積ヘッダーID
--                 csoqh_sale.quote_header_id                = csoql_sale.quote_header_id
--                 -- 帳合問屋用見積ヘッダー．見積ヘッダーID = 帳合問屋用見積明細．見積ヘッダーID
--        AND      csoqh_wholesale.quote_header_id           = csoql_wholesale.quote_header_id
--                 -- 販売先用見積ヘッダー．見積書番号       = 帳合問屋用見積ヘッダー．参照見積番号
--        AND      csoqh_sale.quote_number                   = csoqh_wholesale.reference_quote_number
--                 -- 販売先用見積明細．見積明細ID           = 帳合問屋用見積．参照用見積明細ＩＤ
--        AND      csoql_sale.quote_line_id                  = csoql_wholesale.reference_quote_line_id
--                 -- Disc品目マスタ．品目ID                 = 販売先用見積明細．品目ID
--        AND      msi_b.inventory_item_id                   = csoql_sale.inventory_item_id
--                 -- 販売先用見積ヘッダー．見積種別         = '1'(販売先)
--        AND      csoqh_sale.quote_type                     = cv_quote_type_sale
--                 -- 販売先用見積ヘッダー．ステータス       = '2'(確定)
--        AND      csoqh_sale.status                         = cv_status_decision
--                 -- 帳合問屋用見積ヘッダー．見積種別       = '2'(帳合問屋)
--        AND      csoqh_wholesale.quote_type                =  cv_quote_type_wholesale
--                 -- 帳合問屋用見積ヘッダー．ステータス     = '2'(確定)
--        AND      csoqh_wholesale.status                    = cv_status_decision
--                 -- OPM品目マスタ．品目コード              = Disc品目マスタ．品目コード
--        AND      iim_b.item_no                             = msi_b.segment1
--                 -- Disc品目マスタ．組織ID                 = 組織パラメータ．組織ID
--        AND      msi_b.organization_id                     = mp.organization_id
--                 -- 販売先用見積ヘッダー．顧客コード       = 入力パラメータ．問屋帳合先コード
--        AND      csoqh_sale.account_number                 = iv_sales_outlets_code
--                 -- Disc品目マスタ．品目コード             = 入力パラメータ．品目コード
--        AND      msi_b.segment1                            = iv_item_code
---- 2009/04/13 Ver.1.10 [障害T1_0411] SCS K.Yamaguchi REPAIR START
----                 -- 販売先用見積明細．期間（開始）        <= 入力パラメータ．売上対象年月
----        AND      csoql_sale.quote_start_date              <= TO_DATE (iv_selling_month , 'YYYY/MM' )
----                 -- 販売先用見積明細．期間（終了）        >= 入力パラメータ．売上対象年月
----        AND      csoql_sale.quote_end_date                >= TO_DATE (iv_selling_month , 'YYYY/MM' )
--                 -- 販売先用見積明細．期間（開始）           <= 入力パラメータ．売上対象年月
--        AND      TO_CHAR( csoql_sale.quote_start_date, 'YYYYMM' ) <= iv_selling_month
--                 -- 販売先用見積明細．期間（終了）           >= 入力パラメータ．売上対象年月
--        AND      TO_CHAR( csoql_sale.quote_end_date  , 'YYYYMM' ) >= iv_selling_month
---- 2009/04/13 Ver.1.10 [障害T1_0411] SCS K.Yamaguchi REPAIR END
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi REPAIR START
----                 -- 帳合問屋用見積ヘッダー．顧客コード     = 入力パラメータ．帳合問屋コード
----        AND      csoqh_wholesale.account_number            = iv_wholesale_code
--                 -- 帳合問屋用見積ヘッダー．顧客コード       = 顧客追加情報．顧客コード
--        AND      csoqh_wholesale.account_number              = xca.customer_code
--                 -- 顧客追加情報．問屋管理コード             = 入力パラメータ．問屋管理コード
--        AND      xca.wholesale_ctrl_code                     = iv_wholesale_code
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi REPAIR END
--                 -- 帳合問屋用見積ヘッダー．単価区分      <> 入力パラメータ．請求単位
--        AND      csoqh_wholesale.unit_type                <> iv_demand_unit_type
---- 2009/04/13 Ver.1.10 [障害T1_0411] SCS K.Yamaguchi REPAIR START
----                 -- 帳合問屋用見積明細．期間（開始）      <= 入力パラメータ．売上対象年月
----        AND      csoql_wholesale.quote_start_date         <= TO_DATE ( iv_selling_month , 'YYYY/MM' )
----                 -- 帳合問屋用見積明細．期間（終了）      >= 入力パラメータ．売上対象年月
----        AND      csoql_wholesale.quote_end_date           >= TO_DATE (iv_selling_month , 'YYYY/MM' )
--                 -- 帳合問屋用見積明細．期間（開始）         <= 入力パラメータ．売上対象年月
--        AND      TO_CHAR( csoql_wholesale.quote_start_date, 'YYYYMM' ) <= iv_selling_month
--                 -- 帳合問屋用見積明細．期間（終了）         >= 入力パラメータ．売上対象年月
--        AND      TO_CHAR( csoql_wholesale.quote_end_date  , 'YYYYMM' ) >= iv_selling_month
---- 2009/04/13 Ver.1.10 [障害T1_0411] SCS K.Yamaguchi REPAIR END
--                 -- 組織パラメータ．組織コード             = FND_PROFILE．VALUE('XXCOK1_ORG_CODE_SALES')
--        AND      mp.organization_code                      = FND_PROFILE.VALUE( cv_organization_cd )
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi REPAIR START
----        ORDER BY -- ＜ソート条件＞
----                 -- 販売先用見積明細.見積区分              昇順
----                 csoql_sale.quote_div                      ASC
----                 -- 販売先用見積明細.今回店納価格          降順
----               , csoql_sale.this_time_deliv_price          DESC NULLS LAST
----                 --帳合問屋用見積明細.今回NET価格          降順
----               , csoql_wholesale.this_time_net_price       DESC NULLS LAST;
--        ORDER BY -- ＜ソート条件＞
--                 -- 販売先用見積明細.見積区分              昇順
--                 csoql_sale.quote_div                      ASC
--                 -- 販売先用見積明細.今回店納価格          降順
--               , csoql_sale.this_time_deliv_price          DESC NULLS LAST
--                 --帳合問屋用見積明細.今回NET価格          降順
--               , csoql_wholesale.this_time_net_price       DESC NULLS LAST
--                 -- 帳合問屋用見積明細．発行日             降順
--               , csoqh_wholesale.publish_date              DESC NULLS LAST
--        ;
---- 2009/03/23 Ver.1.8 SCS K.Yamaguchi REPAIR END
--        -- =======================================================
--        -- 問屋請求見積照合2
--        -- =======================================================
--        << loop_2 >>
--        FOR ln_count IN NVL( l_wholesale_req2_tab.FIRST, 0 ) .. NVL( l_wholesale_req2_tab.LAST, 0 ) LOOP
--          -- =====================================
--          --③.FETCHしたレコードの
--          --1件目.見積区分<>「1(通常)」の場合
--          --1件目の見積区分が「1(通常)」以外の場合
--          -- =====================================
--          IF( l_wholesale_req2_tab( cn_one ).lv_quote_div <> cv_quote_div_usuall ) THEN
--            ln_price_check_on_flg := 1; --照合結果判定フラグ  オン
--            ln_sql_data_not_flg   := 1; -- 1件目見積区分判定フラグ
--            EXIT;                       --LOOP 処理から離脱
--          END IF;
--          -- =======================================================
--          -- ④価格情報の単位変換
--          -- =======================================================
--          -- =====================================
--          -- 入力パラメータ．請求単位(iv_demand_unit_type)
--          -- = 「本」の場合
--          -- =====================================
--          IF( iv_demand_unit_type = cv_unit_type_count ) THEN
--            --見積価格情報の単位変換
--            --建値         = ③.建値         ÷ ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_quotation_price
--              := l_wholesale_req2_tab( ln_count ).ln_quotation_price /
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--            --売上値引     = ③.売上値引     ÷ ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
--              := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price /
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--            --通常NET価格  = ③.通常NET価格  ÷ ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_usuall_net_price
--              := l_wholesale_req2_tab( ln_count ).ln_usuall_net_price /
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--            --今回NET価格  = ③.今回NET価格  ÷ ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_this_time_net_price
--              := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price /
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--            --通常店納価格 = ③.通常NET価格  ÷ ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
--              := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price /
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--            --今回店納価格 = ③.今回店納価格 ÷ ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price
--              := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price /
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--          END IF;
--          -- =====================================
--          -- 入力パラメータ．請求単位(iv_demand_unit_type)
--          --= 「C/S」の場合
--          -- =====================================
--          IF( iv_demand_unit_type = cv_unit_type_cs ) THEN
--            --見積価格情報の単位変換
--            --建値         = ③.建値         × ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_quotation_price
--              := l_wholesale_req2_tab( ln_count ).ln_quotation_price *
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--            --売上値引     = ③.売上値引     × ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
--              := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price *
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--            --通常NET価格  = ③.通常NET価格  × ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_usuall_net_price
--              := l_wholesale_req2_tab( ln_count ).ln_usuall_net_price *
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--            --今回NET価格  = ③.今回NET価格  × ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_this_time_net_price
--              := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price *
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--            --通常店納価格 = ③.通常NET価格  × ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
--              := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price *
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--            --今回店納価格 = ③.今回店納価格 × ③.ケース入り数
--            l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price
--              := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price *
--                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
--          END IF;
--          -- =======================================================
--          -- ⑤単価照合
--          -- =======================================================
--          -- =====================================
--          -- ③.見積区分=「1」且つ
--          -- ④.建値 - ④.売上値引 - ④.通常NET価格
--          -- = 入力パラメータ.支払単価(in_demand_unit_price)
--          -- =====================================
--          IF(     ( l_wholesale_req2_tab( ln_count ).lv_quote_div = cv_quote_div_usuall )
--              AND ( in_demand_unit_price =
--                      (   l_wholesale_req2_tab( ln_count ).ln_quotation_price
--                        - l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
--                        - l_wholesale_req2_tab( ln_count ).ln_usuall_net_price )
--                  )
--          ) THEN
--            --・販売手数料 = ④.建値     - ④.売上値引 - ④.通常NET価格
--            on_backmargin_amt :=
--              (   l_wholesale_req2_tab( ln_count ).ln_quotation_price
--                - l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
--                - l_wholesale_req2_tab( ln_count ).ln_usuall_net_price );
--            IF( l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price = 0 ) THEN
--              --・販売協賛金 = 0 ※今回店納が0の場合は0
--              on_sales_support_amt := 0;
--            ELSE
--              --・販売協賛金 = ④.通常店納 - ④.今回店納
--              on_sales_support_amt :=
--                (   l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
--                  - l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price);
--            END IF;
----
--            ov_estimated_no             := l_wholesale_req2_tab( ln_count ).lv_quote_number;          -- 見積書No.
--            on_quote_line_id            := l_wholesale_req2_tab( ln_count ).ln_quote_line_id;         -- 明細ID
--            ov_emp_code                 := l_wholesale_req2_tab( ln_count ).lv_employee_number;       -- 担当者コード
--            on_market_amt               := l_wholesale_req2_tab( ln_count ).ln_quotation_price;       -- 通常建値
--            on_allowance_amt            := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price;  -- 値引(割戻し)
--            on_normal_store_deliver_amt := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price;   -- 通常店納
--            on_once_store_deliver_amt   := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price; -- 今回店納
--            on_net_selling_price        := l_wholesale_req2_tab( ln_count ).ln_usuall_net_price;      -- NET価格
--            ov_estimated_type           := l_wholesale_req2_tab( ln_count ).lv_quote_div;             -- 見積区分
----
--            ln_price_check_on_flg := 1;  --照合結果判定フラグ  オン
--            EXIT loop_2;                       --LOOP 処理から離脱
--          END IF;
--          -- =====================================
--          --③.見積区分=「1」以外 且つ
--          --④.建値 - ④.売上値引 - ④.今回NET価格
--          -- = 入力パラメータ.支払単価(in_demand_unit_price)
--          -- =====================================
--          IF(     ( l_wholesale_req2_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
--              AND ( in_demand_unit_price =
--                      (   l_wholesale_req2_tab( ln_count ).ln_quotation_price
--                        - l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
--                        - l_wholesale_req2_tab( ln_count ).ln_this_time_net_price )
--                      )
--          ) THEN
--            --・販売手数料 = ④.建値 - ④.売上値引 - ④.通常店納 + ④.今回店納 - ④.今回NET価格
--            on_backmargin_amt :=
--              (   l_wholesale_req2_tab( ln_count ).ln_quotation_price
--                - l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
--                - l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
--                + l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price
--                - l_wholesale_req2_tab( ln_count ).ln_this_time_net_price );
--            --・販売協賛金 = ④.通常店納 - ④.今回店納
--            on_sales_support_amt :=
--              (   l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
--                - l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price );
----
--            ov_estimated_no             := l_wholesale_req2_tab( ln_count ).lv_quote_number;         -- 見積書No.
--            on_quote_line_id            := l_wholesale_req2_tab( ln_count ).ln_quote_line_id;        -- 明細ID
--            ov_emp_code                 := l_wholesale_req2_tab( ln_count ).lv_employee_number;      -- 担当者コード
--            on_market_amt               := l_wholesale_req2_tab( ln_count ).ln_quotation_price;      -- 通常建値
--            on_allowance_amt            := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price; -- 値引(割戻し)
--            on_normal_store_deliver_amt := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price;  -- 通常店納
--            on_once_store_deliver_amt   := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price;-- 今回店納
--            on_net_selling_price        := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price;  -- NET価格
--            ov_estimated_type           := l_wholesale_req2_tab( ln_count ).lv_quote_div;            -- 見積区分
----
--            ln_price_check_on_flg := 1;  --照合結果判定フラグ  オン
--            EXIT loop_2;                       --LOOP 処理から離脱
--          END IF;
--          -- =====================================
--          -- ③.見積区分=「1」以外  且つ
--          -- ④.建値 - ④.売上値引 - ④.通常店納 + ④.今回店納 - ④.今回NET価格
--          -- = 入力パラメータ.支払単価(in_demand_unit_price)
--          -- =====================================
--          IF(     ( l_wholesale_req2_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
--              AND ( in_demand_unit_price =
--                      (   l_wholesale_req2_tab( ln_count ).ln_quotation_price
--                        - l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
--                        - l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
--                        + l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price
--                        - l_wholesale_req2_tab( ln_count ).ln_this_time_net_price )
--                  )
--          ) THEN
--            --・販売手数料 = 入力パラメータ.支払単価(in_demand_unit_price)
--            on_backmargin_amt := in_demand_unit_price;
--            --・販売協賛金 = NULL
--            on_sales_support_amt := NULL;
----
--            ov_estimated_no             := l_wholesale_req2_tab( ln_count ).lv_quote_number;         -- 見積書No.
--            on_quote_line_id            := l_wholesale_req2_tab( ln_count ).ln_quote_line_id;        -- 明細ID
--            ov_emp_code                 := l_wholesale_req2_tab( ln_count ).lv_employee_number;      -- 担当者コード
--            on_market_amt               := l_wholesale_req2_tab( ln_count ).ln_quotation_price;      -- 通常建値
--            on_allowance_amt            := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price; -- 値引(割戻し)
--            on_normal_store_deliver_amt := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price;  -- 通常店納
--            on_once_store_deliver_amt   := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price;-- 今回店納
--            on_net_selling_price        := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price;  -- NET価格
--            ov_estimated_type           := l_wholesale_req2_tab( ln_count ).lv_quote_div;            -- 見積区分
----
--            ln_price_check_on_flg := 1;  --照合結果判定フラグ  オン
--            EXIT loop_2;                       --LOOP 処理から離脱
--          END IF;
--          -- =====================================
--          -- ③.見積区分=「1」以外 且つ
--          -- ④.通常店納 - ④.今回店納
--          -- = 入力パラメータ.支払単価(in_demand_unit_price)
--          -- =====================================
--          IF(     ( l_wholesale_req2_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
--              AND ( in_demand_unit_price =
--                      (   l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
--                        - l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price )
--                  )
--          ) THEN
--            --・販売手数料 = NULL
--            on_backmargin_amt := NULL;
--            --・販売協賛金 = 入力パラメータ.支払単価(in_demand_unit_price)
--            on_sales_support_amt := in_demand_unit_price;
----
--            ov_estimated_no             := l_wholesale_req2_tab( ln_count ).lv_quote_number;         -- 見積書No.
--            on_quote_line_id            := l_wholesale_req2_tab( ln_count ).ln_quote_line_id;        -- 明細ID
--            ov_emp_code                 := l_wholesale_req2_tab( ln_count ).lv_employee_number;      -- 担当者コード
--            on_market_amt               := l_wholesale_req2_tab( ln_count ).ln_quotation_price;      -- 通常建値
--            on_allowance_amt            := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price; -- 値引(割戻し)
--            on_normal_store_deliver_amt := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price;  -- 通常店納
--            on_once_store_deliver_amt   := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price;-- 今回店納
--            on_net_selling_price        := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price;  -- NET価格
--            ov_estimated_type           := l_wholesale_req2_tab( ln_count ).lv_quote_div;            -- 見積区分
----
--            ln_price_check_on_flg := 1;  --照合結果判定フラグ  オン
--            EXIT loop_2;                       --LOOP 処理から離脱
--          END IF;
--          -- =====================================
--          -- ③.見積区分=「1」以外 且つ
--          -- ④.通常NET価格 - ④.今回NET価格
--          -- = 入力パラメータ.支払単価(in_demand_unit_price)
--          -- =====================================
--          IF(     ( l_wholesale_req2_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
--              AND ( in_demand_unit_price =
--                      (   l_wholesale_req2_tab( ln_count ).ln_usuall_net_price
--                        - l_wholesale_req2_tab( ln_count ).ln_this_time_net_price )
--                  )
--          ) THEN
--            --・販売手数料 = (④.今回店納 - ④.今回NET価格) - (④.通常店納 - ④.通常NET価格)
--            on_backmargin_amt :=
--              (   (   l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price
--                    - l_wholesale_req2_tab( ln_count ).ln_this_time_net_price   )
--                - (   l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
--                    - l_wholesale_req2_tab( ln_count ).ln_usuall_net_price      )
--              );
--            --・販売協賛金 = ④.通常店納 - ④.今回店納
--            on_sales_support_amt :=
--              (   l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
--                - l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price );
----
--            ov_estimated_no             := l_wholesale_req2_tab( ln_count ).lv_quote_number;          -- 見積書No.
--            on_quote_line_id            := l_wholesale_req2_tab( ln_count ).ln_quote_line_id;         -- 明細ID
--            ov_emp_code                 := l_wholesale_req2_tab( ln_count ).lv_employee_number;       -- 担当者コード
--            on_market_amt               := l_wholesale_req2_tab( ln_count ).ln_quotation_price;       -- 通常建値
--            on_allowance_amt            := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price;  -- 値引(割戻し)
--            on_normal_store_deliver_amt := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price;   -- 通常店納
--            on_once_store_deliver_amt   := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price; -- 今回店納
--            on_net_selling_price        := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price;   -- NET価格
--            ov_estimated_type           := l_wholesale_req2_tab( ln_count ).lv_quote_div;             -- 見積区分
----
--            ln_price_check_on_flg := 1;  --照合結果判定フラグ  オン
--            EXIT loop_2;                       --LOOP 処理から離脱
--          END IF;
--        END LOOP; --l_wholesale_req2_tab LOOP END
--      END IF;     -- condition IF ln_price_check_on_flg = 0 END
--    END IF;     -- condition IF( iv_item_code IS NULL ) THEN
--    -- =======================================================
--    -- 終了処理
--    -- =======================================================
--    IF( ln_price_check_on_flg = 1 ) THEN  --照合結果判定フラグ  オン
--      --見積データが取得できた場合--
--      ov_retcode                  :=  gv_status_normal;
--      ov_errbuf                   :=  NULL;
--      ov_errmsg                   :=  NULL;
--      IF(  ln_sql_data_not_flg = 1 ) THEN          -- 1件目見積区分判定
--        ov_estimated_type         := cv_zero;  -- 見積区分
--      END IF;
--    ELSE
--      --見積データが取得できなかった場合--
--      ov_estimated_no             := NULL;     -- 見積書No
--      on_quote_line_id            := NULL;     -- 明細ID
--      ov_emp_code                 := NULL;     -- 担当者コード
--      on_market_amt               := NULL;     -- 建値
--      on_allowance_amt            := NULL;     -- 値引(割戻し)
--      on_normal_store_deliver_amt := NULL;     -- 通常店納
--      on_once_store_deliver_amt   := NULL;     -- 今回店納
--      on_net_selling_price        := NULL;     -- NET価格
--      IF( iv_item_code IS NULL ) THEN
--        --INパラメータ.品目コード=NULLの場合
--        ov_estimated_type         := NULL;     -- 見積区分
--      ELSE
--        ov_estimated_type         := cv_zero;  -- 見積区分
--      END IF;
----
--      on_backmargin_amt           := NULL;     -- 販売手数料
--      on_sales_support_amt        := NULL;     -- 販売協賛金
--      ov_retcode                  := gv_status_normal;
--      ov_errbuf                   := NULL;
--      ov_errmsg                   := NULL;
--    END IF;
----
--  EXCEPTION
--    --見積データが取得できなかった場合--
--    WHEN NO_DATA_FOUND THEN
--      ov_estimated_no             := NULL;     -- 見積書No
--      on_quote_line_id            := NULL;     -- 明細ID
--      ov_emp_code                 := NULL;     -- 担当者コード
--      on_market_amt               := NULL;     -- 建値
--      on_allowance_amt            := NULL;     -- 値引(割戻し)
--      on_normal_store_deliver_amt := NULL;     -- 通常店納
--      on_once_store_deliver_amt   := NULL;     -- 今回店納
--      on_net_selling_price        := NULL;     -- NET価格
--      ov_estimated_type           := cv_zero;  -- 見積区分
--      on_backmargin_amt           := NULL;     -- 販売手数料
--      on_sales_support_amt        := NULL;     -- 販売協賛金
--      ov_retcode                  := gv_status_normal;
--      ov_errbuf                   := NULL;
--      ov_errmsg                   := NULL;
--    WHEN OTHERS THEN
--      ov_retcode := gv_status_error;
--      raise_application_error(
--        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
--      );
----
--  END get_wholesale_req_est_p;
  PROCEDURE get_wholesale_req_est_p(
    ov_errbuf                      OUT VARCHAR2 -- エラーバッファ
  , ov_retcode                     OUT VARCHAR2 -- リターンコード
  , ov_errmsg                      OUT VARCHAR2 -- エラーメッセージ
  , iv_wholesale_code              IN  VARCHAR2 -- 問屋管理コード
  , iv_sales_outlets_code          IN  VARCHAR2 -- 問屋帳合先コード
  , iv_item_code                   IN  VARCHAR2 -- 品目コード
  , in_demand_unit_price           IN  NUMBER   -- 支払単価
  , iv_demand_unit_type            IN  VARCHAR2 -- 請求単位
  , iv_selling_month               IN  VARCHAR2 -- 売上対象年月
  , ov_estimated_no                OUT VARCHAR2 -- 見積書No.
  , on_quote_line_id               OUT NUMBER   -- 明細ID
  , ov_emp_code                    OUT VARCHAR2 -- 担当者コード
  , on_market_amt                  OUT NUMBER   -- 建値
  , on_allowance_amt               OUT NUMBER   -- 値引(割戻し)
  , on_normal_store_deliver_amt    OUT NUMBER   -- 通常店納
  , on_once_store_deliver_amt      OUT NUMBER   -- 今回店納
  , on_net_selling_price           OUT NUMBER   -- NET価格
  , ov_estimated_type              OUT VARCHAR2 -- 見積区分
  , on_backmargin_amt              OUT NUMBER   -- 販売手数料
  , on_sales_support_amt           OUT NUMBER   -- 販売協賛金
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_wholesale_req_est_p';                        -- プログラム名
    cv_quote_type_sales            CONSTANT VARCHAR2(1)  := '1';                                              -- 見積種別 1:販売先用
    cv_quote_type_wholesale        CONSTANT VARCHAR2(1)  := '2';                                              -- 見積種別 2:帳合問屋先用
    cv_quote_status_fix            CONSTANT VARCHAR2(1)  := '2';                                              -- ステータス= 2:確定
    cv_quote_div_usuall            CONSTANT VARCHAR2(1)  := '1';                                              -- 見積区分 1:通常
    cv_organizaiton_code           CONSTANT VARCHAR2(30) := FND_PROFILE.VALUE( 'XXCOK1_ORG_CODE_SALES' );     -- COK用_組織コード
    cv_unit_type_unit              CONSTANT VARCHAR2(1)  := '1';                                              -- 単価区分:1(本)
    cv_unit_type_cs                CONSTANT VARCHAR2(1)  := '2';                                              -- 単価区分:2(C/S)
    cv_unit_type_bl                CONSTANT VARCHAR2(1)  := '3';                                              -- 単価区分:3(ボール)
    cv_inc_tax                     xxcso_quote_headers.deliv_price_tax_type%TYPE := '2'; -- 税込価格
    --==================================================
    -- ローカル変数
    --==================================================
    -- 初期取得
    ln_tax_rate                    NUMBER DEFAULT 0;
    -- 換算結果格納
    ln_usually_deliv_price         NUMBER DEFAULT NULL; -- 通常店納価格
    ln_this_time_deliv_price       NUMBER DEFAULT NULL; -- 今回店納価格
    ln_quotation_price             NUMBER DEFAULT NULL; -- 建値
    ln_sales_discount_price        NUMBER DEFAULT NULL; -- 売上値引
    ln_usuall_net_price            NUMBER DEFAULT NULL; -- 通常NET価格
    ln_this_time_net_price         NUMBER DEFAULT NULL; -- 今回NET価格
    --==================================================
    -- ローカル変数
    --==================================================
    CURSOR get_quote_cur
    IS
      SELECT whole_xqh.quote_number                         AS quote_number               -- 見積書番号
           , whole_xql.quote_line_id                        AS quote_line_id              -- 見積明細ID
           , whole_xqh.employee_number                      AS employee_number            -- 担当者コード
           , sales_xql.quote_div                            AS quote_div                  -- 見積区分
           , sales_xqh.unit_type                            AS sales_unit_type            -- 【販売先】単価区分
           , sales_xqh.deliv_price_tax_type                 AS sales_deliv_price_tax_type -- 【販売先】店納価格税区分
           , whole_xqh.unit_type                            AS whole_unit_type            -- 【問屋】単価区分
           , whole_xqh.deliv_price_tax_type                 AS whole_deliv_price_tax_type -- 【問屋】店納価格税区分
           , NVL( sales_xql.usually_deliv_price   , 0 )     AS usually_deliv_price        -- 通常店納価格
           , NVL( sales_xql.this_time_deliv_price , 0 )     AS this_time_deliv_price      -- 今回店納価格
           , NVL( whole_xql.quotation_price       , 0 )     AS quotation_price            -- 建値
           , NVL( whole_xql.sales_discount_price  , 0 )     AS sales_discount_price       -- 売上値引
           , NVL( whole_xql.usuall_net_price      , 0 )     AS usuall_net_price           -- 通常NET価格
           , NVL( whole_xql.this_time_net_price   , 0 )     AS this_time_net_price        -- 今回NET価格
           , NVL( TO_NUMBER( iimb.attribute11 )   , 0 )     AS cs_count                   -- ケース入り数
           , NVL( xsib.bowl_inc_num               , 0 )     AS bl_count                   -- ボール入り数
      FROM xxcso_quote_headers          sales_xqh    -- 【販売先】見積ヘッダ
         , xxcso_quote_lines            sales_xql    -- 【販売先】見積明細
         , xxcso_quote_headers          whole_xqh    -- 【問屋】見積ヘッダ
         , xxcso_quote_lines            whole_xql    -- 【問屋】見積明細
         , xxcmm_cust_accounts          whole_xca    -- 【問屋】顧客マスタ
         , mtl_system_items_b           msib         -- DISC品目
         , ic_item_mst_b                iimb         -- OPM品目
         , mtl_parameters               mp           -- 組織パラメータ
         , xxcmm_system_items_b         xsib         -- DISC品目アドオン
      WHERE sales_xqh.quote_type                        = cv_quote_type_sales
        AND sales_xqh.status                            = cv_quote_status_fix
        AND whole_xqh.quote_type                        = cv_quote_type_wholesale
        AND whole_xqh.status                            = cv_quote_status_fix
        AND sales_xqh.quote_header_id                   = sales_xql.quote_header_id
        AND sales_xqh.quote_number                      = whole_xqh.reference_quote_number
        AND sales_xql.quote_line_id                     = whole_xql.reference_quote_line_id
        AND whole_xqh.quote_header_id                   = whole_xql.quote_header_id
        AND whole_xqh.account_number                    = whole_xca.customer_code
        AND sales_xql.inventory_item_id                 = msib.inventory_item_id
        AND msib.segment1                               = iimb.item_no
        AND msib.organization_id                        = mp.organization_id
        AND msib.segment1                               = xsib.item_code
        AND mp.organization_code                        = cv_organizaiton_code
        AND sales_xqh.account_number                    = iv_sales_outlets_code
        AND msib.segment1                               = iv_item_code
        AND whole_xca.wholesale_ctrl_code               = iv_wholesale_code
        AND TO_DATE( iv_selling_month, 'RRRRMM' ) BETWEEN TRUNC( sales_xql.quote_start_date, 'MM' )
                                                      AND TRUNC( sales_xql.quote_end_date  , 'MM' )
        AND TO_DATE( iv_selling_month, 'RRRRMM' ) BETWEEN TRUNC( whole_xql.quote_start_date, 'MM' )
                                                      AND TRUNC( whole_xql.quote_end_date  , 'MM' )
      ORDER BY sales_xql.quote_div
             , whole_xqh.last_update_date         DESC
             , sales_xql.this_time_deliv_price    DESC NULLS LAST
             , whole_xql.this_time_net_price      DESC NULLS LAST
             , whole_xql.usuall_net_price         DESC NULLS LAST
    ;
--
  BEGIN
    --==================================================
    -- 品目コードがNULLの場合、突合せを行わない（勘定科目支払）
    --==================================================
    IF( iv_item_code IS NULL ) THEN
      ov_retcode                     := gv_status_normal;
      ov_errbuf                      := NULL;
      ov_errmsg                      := NULL;
      ov_estimated_no                := NULL;
      on_quote_line_id               := NULL;
      ov_emp_code                    := NULL;
      on_market_amt                  := NULL;
      on_allowance_amt               := NULL;
      on_normal_store_deliver_amt    := NULL;
      on_once_store_deliver_amt      := NULL;
      on_net_selling_price           := NULL;
      ov_estimated_type              := NULL;
      on_backmargin_amt              := NULL;
      on_sales_support_amt           := NULL;
      RETURN;
    END IF;
    --==================================================
    -- 支払単価が０の場合、突合せを行わない（論理削除データ）
    --==================================================
    IF( in_demand_unit_price = 0 ) THEN
      ov_retcode                     := gv_status_normal;
      ov_errbuf                      := NULL;
      ov_errmsg                      := NULL;
      ov_estimated_no                := NULL;
      on_quote_line_id               := NULL;
      ov_emp_code                    := NULL;
      on_market_amt                  := NULL;
      on_allowance_amt               := NULL;
      on_normal_store_deliver_amt    := NULL;
      on_once_store_deliver_amt      := NULL;
      on_net_selling_price           := NULL;
      ov_estimated_type              := NULL;
      on_backmargin_amt              := NULL;
      on_sales_support_amt           := NULL;
      RETURN;
    END IF;
    --==================================================
    -- 請求単位が1：本、2：CS、3：ボール以外の場合見積書無しとする
    --==================================================
    IF( iv_demand_unit_type NOT IN ( cv_unit_type_unit
                                   , cv_unit_type_cs
                                   , cv_unit_type_bl
                                   )
        OR iv_demand_unit_type IS NULL
    ) THEN
      ov_retcode                     := gv_status_normal;
      ov_errbuf                      := NULL;
      ov_errmsg                      := NULL;
      ov_estimated_no                := NULL;
      on_quote_line_id               := NULL;
      ov_emp_code                    := NULL;
      on_market_amt                  := NULL;
      on_allowance_amt               := NULL;
      on_normal_store_deliver_amt    := NULL;
      on_once_store_deliver_amt      := NULL;
      on_net_selling_price           := NULL;
      ov_estimated_type              := '0';
      on_backmargin_amt              := NULL;
      on_sales_support_amt           := NULL;
      RETURN;
    END IF;
    --==================================================
    -- 税率取得
    --==================================================
    BEGIN
      SELECT TO_NUMBER( flvv.description )   tax_rate
      INTO ln_tax_rate
      FROM fnd_lookup_values_vl    flvv
      WHERE flvv.lookup_type  = 'XXCOK1_QUOTE_TAX_RATE'
        AND flvv.enabled_flag = 'Y'
        AND TO_DATE( iv_selling_month, 'RRRRMM' ) BETWEEN flvv.start_date_active
                                                      AND NVL( flvv.end_date_active, TO_DATE( iv_selling_month, 'RRRRMM' ) )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         ln_tax_rate := 0;   -- 取得できない場合は税率をゼロとする
    END;
    --==================================================
    -- 突合せ
    --==================================================
    FOR get_quote_rec IN get_quote_cur LOOP
      --==================================================
      -- 変数初期化
      --==================================================
      ln_usually_deliv_price   := NULL;
      ln_this_time_deliv_price := NULL;
      ln_quotation_price       := NULL;
      ln_sales_discount_price  := NULL;
      ln_usuall_net_price      := NULL;
      ln_this_time_net_price   := NULL;
      DECLARE
        skip_expt                  EXCEPTION; -- 見積突合せ対象外（見積書無し）
      BEGIN
        --==================================================
        -- 税抜額計算（問屋）
        --==================================================
        IF( get_quote_rec.whole_deliv_price_tax_type = cv_inc_tax ) THEN
          ln_usuall_net_price      := TRUNC( get_quote_rec.usuall_net_price      / ( 100 + ln_tax_rate ) * 100, 2 );
          ln_this_time_net_price   := TRUNC( get_quote_rec.this_time_net_price   / ( 100 + ln_tax_rate ) * 100, 2 );
          ln_quotation_price       := TRUNC( get_quote_rec.quotation_price       / ( 100 + ln_tax_rate ) * 100, 2 );
          ln_sales_discount_price  := TRUNC( get_quote_rec.sales_discount_price  / ( 100 + ln_tax_rate ) * 100, 2 );
        ELSE
          ln_usuall_net_price      := get_quote_rec.usuall_net_price;
          ln_this_time_net_price   := get_quote_rec.this_time_net_price;
          ln_quotation_price       := get_quote_rec.quotation_price;
          ln_sales_discount_price  := get_quote_rec.sales_discount_price;
        END IF;
        --==================================================
        -- 税抜額計算（販売先）
        --==================================================
        IF( get_quote_rec.sales_deliv_price_tax_type = cv_inc_tax ) THEN
          ln_usually_deliv_price   := TRUNC( get_quote_rec.usually_deliv_price   / ( 100 + ln_tax_rate ) * 100, 2 );
          ln_this_time_deliv_price := TRUNC( get_quote_rec.this_time_deliv_price / ( 100 + ln_tax_rate ) * 100, 2 );
        ELSE
          ln_usually_deliv_price   := get_quote_rec.usually_deliv_price;
          ln_this_time_deliv_price := get_quote_rec.this_time_deliv_price;
        END IF;
        --==================================================
        -- 単位換算（問屋）
        --==================================================
        -- 請求単位 ＝ 本
        IF( iv_demand_unit_type = cv_unit_type_unit ) THEN
          IF( get_quote_rec.whole_unit_type = cv_unit_type_unit ) THEN
            ln_usuall_net_price      := ln_usuall_net_price;
            ln_this_time_net_price   := ln_this_time_net_price;
            ln_quotation_price       := ln_quotation_price;
            ln_sales_discount_price  := ln_sales_discount_price;
          ELSIF( get_quote_rec.whole_unit_type = cv_unit_type_cs ) THEN
            IF( get_quote_rec.cs_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usuall_net_price      := TRUNC( ln_usuall_net_price      / get_quote_rec.cs_count, 2 );
              ln_this_time_net_price   := TRUNC( ln_this_time_net_price   / get_quote_rec.cs_count, 2 );
              ln_quotation_price       := TRUNC( ln_quotation_price       / get_quote_rec.cs_count, 2 );
              ln_sales_discount_price  := TRUNC( ln_sales_discount_price  / get_quote_rec.cs_count, 2 );
            END IF;
          ELSIF( get_quote_rec.whole_unit_type = cv_unit_type_bl ) THEN
            IF( get_quote_rec.bl_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usuall_net_price      := TRUNC( ln_usuall_net_price      / get_quote_rec.bl_count, 2 );
              ln_this_time_net_price   := TRUNC( ln_this_time_net_price   / get_quote_rec.bl_count, 2 );
              ln_quotation_price       := TRUNC( ln_quotation_price       / get_quote_rec.bl_count, 2 );
              ln_sales_discount_price  := TRUNC( ln_sales_discount_price  / get_quote_rec.bl_count, 2 );
            END IF;
          END IF;
        -- 請求単位 ＝ ケース
        ELSIF( iv_demand_unit_type = cv_unit_type_cs ) THEN
          IF( get_quote_rec.whole_unit_type = cv_unit_type_unit ) THEN
            IF( get_quote_rec.cs_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usuall_net_price      := ln_usuall_net_price      * get_quote_rec.cs_count;
              ln_this_time_net_price   := ln_this_time_net_price   * get_quote_rec.cs_count;
              ln_quotation_price       := ln_quotation_price       * get_quote_rec.cs_count;
              ln_sales_discount_price  := ln_sales_discount_price  * get_quote_rec.cs_count;
            END IF;
          ELSIF( get_quote_rec.whole_unit_type = cv_unit_type_cs ) THEN
            ln_usuall_net_price      := ln_usuall_net_price;
            ln_this_time_net_price   := ln_this_time_net_price;
            ln_quotation_price       := ln_quotation_price;
            ln_sales_discount_price  := ln_sales_discount_price;
          ELSIF( get_quote_rec.whole_unit_type = cv_unit_type_bl ) THEN
            IF( get_quote_rec.cs_count = 0 )
            OR( get_quote_rec.bl_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usuall_net_price      := TRUNC( ln_usuall_net_price      / get_quote_rec.bl_count, 2 ) * get_quote_rec.cs_count;
              ln_this_time_net_price   := TRUNC( ln_this_time_net_price   / get_quote_rec.bl_count, 2 ) * get_quote_rec.cs_count;
              ln_quotation_price       := TRUNC( ln_quotation_price       / get_quote_rec.bl_count, 2 ) * get_quote_rec.cs_count;
              ln_sales_discount_price  := TRUNC( ln_sales_discount_price  / get_quote_rec.bl_count, 2 ) * get_quote_rec.cs_count;
            END IF;
          END IF;
        -- 請求単位 ＝ ボール
        ELSIF( iv_demand_unit_type = cv_unit_type_bl ) THEN
          IF( get_quote_rec.whole_unit_type = cv_unit_type_unit ) THEN
            IF( get_quote_rec.bl_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usuall_net_price      := ln_usuall_net_price      * get_quote_rec.bl_count;
              ln_this_time_net_price   := ln_this_time_net_price   * get_quote_rec.bl_count;
              ln_quotation_price       := ln_quotation_price       * get_quote_rec.bl_count;
              ln_sales_discount_price  := ln_sales_discount_price  * get_quote_rec.bl_count;
            END IF;
          ELSIF( get_quote_rec.whole_unit_type = cv_unit_type_cs ) THEN
            IF( get_quote_rec.cs_count = 0 )
            OR( get_quote_rec.bl_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usuall_net_price      := TRUNC( ln_usuall_net_price      / get_quote_rec.cs_count, 2 ) * get_quote_rec.bl_count;
              ln_this_time_net_price   := TRUNC( ln_this_time_net_price   / get_quote_rec.cs_count, 2 ) * get_quote_rec.bl_count;
              ln_quotation_price       := TRUNC( ln_quotation_price       / get_quote_rec.cs_count, 2 ) * get_quote_rec.bl_count;
              ln_sales_discount_price  := TRUNC( ln_sales_discount_price  / get_quote_rec.cs_count, 2 ) * get_quote_rec.bl_count;
            END IF;
          ELSIF( get_quote_rec.whole_unit_type = cv_unit_type_bl ) THEN
            ln_usuall_net_price      := ln_usuall_net_price;
            ln_this_time_net_price   := ln_this_time_net_price;
            ln_quotation_price       := ln_quotation_price;
            ln_sales_discount_price  := ln_sales_discount_price;
          END IF;
        END IF;
        --==================================================
        -- 単位換算（販売先）
        --==================================================
        -- 請求単位 ＝ 本
        IF( iv_demand_unit_type = cv_unit_type_unit ) THEN
          IF( get_quote_rec.sales_unit_type = cv_unit_type_unit ) THEN
            ln_usually_deliv_price   := ln_usually_deliv_price;
            ln_this_time_deliv_price := ln_this_time_deliv_price;
          ELSIF( get_quote_rec.sales_unit_type = cv_unit_type_cs ) THEN
            IF( get_quote_rec.cs_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usually_deliv_price   := TRUNC( ln_usually_deliv_price   / get_quote_rec.cs_count, 2 );
              ln_this_time_deliv_price := TRUNC( ln_this_time_deliv_price / get_quote_rec.cs_count, 2 );
            END IF;
          ELSIF( get_quote_rec.sales_unit_type = cv_unit_type_bl ) THEN
            IF( get_quote_rec.bl_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usually_deliv_price   := TRUNC( ln_usually_deliv_price   / get_quote_rec.bl_count, 2 );
              ln_this_time_deliv_price := TRUNC( ln_this_time_deliv_price / get_quote_rec.bl_count, 2 );
            END IF;
          END IF;
        -- 請求単位 ＝ ケース
        ELSIF( iv_demand_unit_type = cv_unit_type_cs ) THEN
          IF( get_quote_rec.sales_unit_type = cv_unit_type_unit ) THEN
            IF( get_quote_rec.cs_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usually_deliv_price   := ln_usually_deliv_price   * get_quote_rec.cs_count;
              ln_this_time_deliv_price := ln_this_time_deliv_price * get_quote_rec.cs_count;
            END IF;
          ELSIF( get_quote_rec.sales_unit_type = cv_unit_type_cs ) THEN
            ln_usually_deliv_price   := ln_usually_deliv_price;
            ln_this_time_deliv_price := ln_this_time_deliv_price;
          ELSIF( get_quote_rec.sales_unit_type = cv_unit_type_bl ) THEN
            IF( get_quote_rec.cs_count = 0 )
            OR( get_quote_rec.bl_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usually_deliv_price   := TRUNC( ln_usually_deliv_price   / get_quote_rec.bl_count, 2 ) * get_quote_rec.cs_count;
              ln_this_time_deliv_price := TRUNC( ln_this_time_deliv_price / get_quote_rec.bl_count, 2 ) * get_quote_rec.cs_count;
            END IF;
          END IF;
        -- 請求単位 ＝ ボール
        ELSIF( iv_demand_unit_type = cv_unit_type_bl ) THEN
          IF( get_quote_rec.sales_unit_type = cv_unit_type_unit ) THEN
            IF( get_quote_rec.bl_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usually_deliv_price   := ln_usually_deliv_price   * get_quote_rec.bl_count;
              ln_this_time_deliv_price := ln_this_time_deliv_price * get_quote_rec.bl_count;
            END IF;
          ELSIF( get_quote_rec.sales_unit_type = cv_unit_type_cs ) THEN
            IF( get_quote_rec.cs_count = 0 )
            OR( get_quote_rec.bl_count = 0 ) THEN
              RAISE skip_expt; -- 突合せ対象外
            ELSE
              ln_usually_deliv_price   := TRUNC( ln_usually_deliv_price   / get_quote_rec.cs_count, 2 ) * get_quote_rec.bl_count;
              ln_this_time_deliv_price := TRUNC( ln_this_time_deliv_price / get_quote_rec.cs_count, 2 ) * get_quote_rec.bl_count;
            END IF;
          ELSIF( get_quote_rec.sales_unit_type = cv_unit_type_bl ) THEN
            ln_usually_deliv_price   := ln_usually_deliv_price;
            ln_this_time_deliv_price := ln_this_time_deliv_price;
          END IF;
        END IF;
        --==================================================
        -- 見積区分：通常
        --==================================================
        IF( get_quote_rec.quote_div = cv_quote_div_usuall ) THEN
          --==================================================
          -- 支払単価：建値 － 売上値引 － 通常ＮＥＴ価格
          --==================================================
          IF( in_demand_unit_price = ln_quotation_price
                                   - ln_sales_discount_price
                                   - ln_usuall_net_price
          ) THEN
            ov_retcode                     := gv_status_normal;
            ov_errbuf                      := NULL;
            ov_errmsg                      := NULL;
            ov_estimated_no                := get_quote_rec.quote_number;
            on_quote_line_id               := get_quote_rec.quote_line_id;
            ov_emp_code                    := get_quote_rec.employee_number;
            on_market_amt                  := ln_quotation_price;
            on_allowance_amt               := ln_sales_discount_price;
            on_normal_store_deliver_amt    := ln_usually_deliv_price;
            on_once_store_deliver_amt      := ln_this_time_deliv_price;
            on_net_selling_price           := ln_usuall_net_price;
            ov_estimated_type              := get_quote_rec.quote_div;
            on_backmargin_amt              := ln_quotation_price
                                            - ln_sales_discount_price
                                            - ln_usuall_net_price;
            on_sales_support_amt           := 0;
            RETURN;
          END IF;
        --==================================================
        -- 見積区分：通常以外
        --==================================================
        ELSE
          --==================================================
          -- 支払単価：建値 － 売上値引 － 今回ＮＥＴ価格
          --==================================================
          IF( in_demand_unit_price = ln_quotation_price
                                   - ln_sales_discount_price
                                   - ln_this_time_net_price
          ) THEN
            ov_retcode                     := gv_status_normal;
            ov_errbuf                      := NULL;
            ov_errmsg                      := NULL;
            ov_estimated_no                := get_quote_rec.quote_number;
            on_quote_line_id               := get_quote_rec.quote_line_id;
            ov_emp_code                    := get_quote_rec.employee_number;
            on_market_amt                  := ln_quotation_price;
            on_allowance_amt               := ln_sales_discount_price;
            on_normal_store_deliver_amt    := ln_usually_deliv_price;
            on_once_store_deliver_amt      := ln_this_time_deliv_price;
            on_net_selling_price           := ln_this_time_net_price;
            ov_estimated_type              := get_quote_rec.quote_div;
            on_backmargin_amt              := ln_quotation_price
                                            - ln_sales_discount_price
                                            - ln_usually_deliv_price
                                            + ln_this_time_deliv_price
                                            - ln_this_time_net_price;
            on_sales_support_amt           := ln_usually_deliv_price
                                            - ln_this_time_deliv_price;
            RETURN;
          END IF;
          --==================================================
          -- 支払単価：建値 － 売上値引 － 通常店納 ＋ 今回店納 － 今回ＮＥＴ価格
          --==================================================
          IF( in_demand_unit_price = ln_quotation_price
                                   - ln_sales_discount_price
                                   - ln_usually_deliv_price
                                   + ln_this_time_deliv_price
                                   - ln_this_time_net_price
          ) THEN
            ov_retcode                     := gv_status_normal;
            ov_errbuf                      := NULL;
            ov_errmsg                      := NULL;
            ov_estimated_no                := get_quote_rec.quote_number;
            on_quote_line_id               := get_quote_rec.quote_line_id;
            ov_emp_code                    := get_quote_rec.employee_number;
            on_market_amt                  := ln_quotation_price;
            on_allowance_amt               := ln_sales_discount_price;
            on_normal_store_deliver_amt    := ln_usually_deliv_price;
            on_once_store_deliver_amt      := ln_this_time_deliv_price;
            on_net_selling_price           := ln_this_time_net_price;
            ov_estimated_type              := get_quote_rec.quote_div;
            on_backmargin_amt              := ln_quotation_price
                                            - ln_sales_discount_price
                                            - ln_usually_deliv_price
                                            + ln_this_time_deliv_price
                                            - ln_this_time_net_price;
            on_sales_support_amt           := 0;
            RETURN;
          END IF;
          --==================================================
          -- 支払単価：通常店納 － 今回店納
          --==================================================
          IF( in_demand_unit_price = ln_usually_deliv_price
                                   - ln_this_time_deliv_price
          ) THEN
            ov_retcode                     := gv_status_normal;
            ov_errbuf                      := NULL;
            ov_errmsg                      := NULL;
            ov_estimated_no                := get_quote_rec.quote_number;
            on_quote_line_id               := get_quote_rec.quote_line_id;
            ov_emp_code                    := get_quote_rec.employee_number;
            on_market_amt                  := ln_quotation_price;
            on_allowance_amt               := ln_sales_discount_price;
            on_normal_store_deliver_amt    := ln_usually_deliv_price;
            on_once_store_deliver_amt      := ln_this_time_deliv_price;
            on_net_selling_price           := ln_this_time_net_price;
            ov_estimated_type              := get_quote_rec.quote_div;
            on_backmargin_amt              := 0;
            on_sales_support_amt           := ln_usually_deliv_price
                                            - ln_this_time_deliv_price;
            RETURN;
          END IF;
          --==================================================
          -- 支払単価：通常ＮＥＴ価格 － 今回ＮＥＴ価格
          --==================================================
          IF( in_demand_unit_price = ln_usuall_net_price
                                   - ln_this_time_net_price
          ) THEN
            ov_retcode                     := gv_status_normal;
            ov_errbuf                      := NULL;
            ov_errmsg                      := NULL;
            ov_estimated_no                := get_quote_rec.quote_number;
            on_quote_line_id               := get_quote_rec.quote_line_id;
            ov_emp_code                    := get_quote_rec.employee_number;
            on_market_amt                  := ln_quotation_price;
            on_allowance_amt               := ln_sales_discount_price;
            on_normal_store_deliver_amt    := ln_usually_deliv_price;
            on_once_store_deliver_amt      := ln_this_time_deliv_price;
            on_net_selling_price           := ln_this_time_net_price;
            ov_estimated_type              := get_quote_rec.quote_div;
            on_backmargin_amt              := ln_this_time_deliv_price
                                            - ln_this_time_net_price
                                            - ln_usually_deliv_price
                                            + ln_usuall_net_price;
            on_sales_support_amt           := ln_usually_deliv_price
                                            - ln_this_time_deliv_price;
            RETURN;
          END IF;
        END IF;
      EXCEPTION
        WHEN skip_expt THEN
          NULL;
      END;
    END LOOP;
    --==================================================
    -- 見積書無し
    --==================================================
    ov_retcode                     := gv_status_normal;
    ov_errbuf                      := NULL;
    ov_errmsg                      := NULL;
    ov_estimated_no                := NULL;
    on_quote_line_id               := NULL;
    ov_emp_code                    := NULL;
    on_market_amt                  := NULL;
    on_allowance_amt               := NULL;
    on_normal_store_deliver_amt    := NULL;
    on_once_store_deliver_amt      := NULL;
    on_net_selling_price           := NULL;
    ov_estimated_type              := '0';
    on_backmargin_amt              := NULL;
    on_sales_support_amt           := NULL;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_retcode := gv_status_error;
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_wholesale_req_est_p;
-- 2010/04/21 Ver.1.13 [E_本稼動_02088] SCS K.Yamaguchi REPAIR END
--
  /******************************************************************************
   *FUNCTION NAME : get_wholesale_req_est_type_f
   *Desctiption   : 問屋請求書見積書突合ステータス取得
   ******************************************************************************/
  FUNCTION get_wholesale_req_est_type_f(
    iv_wholesale_code     IN VARCHAR2 -- 問屋管理コード
  , iv_sales_outlets_code IN VARCHAR2 -- 問屋帳合先コード
  , iv_item_code          IN VARCHAR2 -- 品目コード
  , in_demand_unit_price  IN NUMBER   -- 支払単価
  , iv_demand_unit_type   IN VARCHAR2 -- 請求単位
  , iv_selling_month      IN VARCHAR2 -- 売上対象年月
  )
  RETURN VARCHAR2                     -- ステータス
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_wholesale_req_est_type_f';    -- プログラム名
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    lv_retcode                  VARCHAR2(1)     DEFAULT gv_status_normal;
    lv_errbuf                   VARCHAR2(32767) DEFAULT NULL;
    lv_errmsg                   VARCHAR2(32767) DEFAULT NULL;
    lt_estimated_no             xxcso_quote_headers.quote_number%TYPE;        -- 見積書No.
    lt_wholesale_bill_detail_id xxcso_quote_lines.quote_line_id%TYPE;         -- 明細ID
    lt_emp_code                 xxcso_quote_headers.employee_number%TYPE;     -- 担当者コード
    lt_market_amt               xxcso_quote_lines.quotation_price%TYPE;       -- 建値
    lt_allowance_amt            xxcso_quote_lines.sales_discount_price%TYPE;  -- 値引(割戻し)
    lt_normal_store_deliver_amt xxcso_quote_lines.usually_deliv_price%TYPE;   -- 通常店納
    lt_once_store_deliver_amt   xxcso_quote_lines.this_time_deliv_price%TYPE; -- 今回店納
    lt_net_selling_price        xxcso_quote_lines.usuall_net_price%TYPE;      -- NET価格
    lt_estimated_type           xxcso_quote_lines.quote_div%TYPE;             -- 見積区分
    ln_backmargin_amt           NUMBER;                                       -- 販売手数料
    ln_sales_support_amt        NUMBER;                                       -- 販売協賛金
--
  BEGIN
    -- =======================================================
    -- 問屋請求見積照合呼出
    -- =======================================================
    get_wholesale_req_est_p(
      lv_errbuf                   -- OUT エラーバッファ
    , lv_retcode                  -- OUT リターンコード
    , lv_errmsg                   -- OUT エラーメッセージ
    , iv_wholesale_code           -- IN 問屋管理コード
    , iv_sales_outlets_code       -- IN 問屋帳合先コード
    , iv_item_code                -- IN 品目コード
    , in_demand_unit_price        -- IN 支払単価
    , iv_demand_unit_type         -- IN 請求単位
    , iv_selling_month            -- IN 売上対象年月
    , lt_estimated_no             -- OUT 見積書No.
    , lt_wholesale_bill_detail_id -- OUT 明細ID
    , lt_emp_code                 -- OUT 担当者コード
    , lt_market_amt               -- OUT 建値
    , lt_allowance_amt            -- OUT 値引(割戻し)
    , lt_normal_store_deliver_amt -- OUT 通常店納
    , lt_once_store_deliver_amt   -- OUT 今回店納
    , lt_net_selling_price        -- OUT NET価格
    , lt_estimated_type           -- OUT 見積区分
    , ln_backmargin_amt           -- OUT 販売手数料
    , ln_sales_support_amt        -- OUT 販売協賛金
    );
    -- =======================================================
    -- 見積区分を返却
    -- =======================================================
    RETURN lt_estimated_type; -- 見積区分を返却
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- 該当するレコードが存在しなかった場合はNULLを返す
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_wholesale_req_est_type_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_companies_code_f
   *Desctiption   : 企業コード取得
   ******************************************************************************/
  FUNCTION get_companies_code_f(
    iv_customer_code IN VARCHAR2 -- 顧客コード
  )
  RETURN VARCHAR2
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name    CONSTANT  VARCHAR2(30) := 'get_companies_code_f';  -- プログラム名
    cv_lookup_type CONSTANT  VARCHAR2(30) := 'XXCMM_CHAIN_CODE';
    cv_y           CONSTANT  VARCHAR2(1)  := 'Y';
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    lt_companies_code fnd_lookup_values.attribute1%TYPE DEFAULT NULL; -- 企業コード
--
  BEGIN
    -- =======================================================
    -- 企業コードの取得
    -- =======================================================
    SELECT flv.attribute1           AS companies_code1
    INTO   lt_companies_code
    FROM   xxcmm_cust_accounts      xca
         , fnd_lookup_values        flv
    WHERE  xca.customer_code        = iv_customer_code
    AND    xca.delivery_chain_code  = flv.lookup_code
    AND    flv.lookup_type          = cv_lookup_type
    AND    flv.language             = USERENV( 'LANG' )
    AND    flv.enabled_flag         = cv_y
    AND    NVL( flv.start_date_active, xxccp_common_pkg2.get_process_date )
             <= xxccp_common_pkg2.get_process_date
    AND    NVL( flv.end_date_active, xxccp_common_pkg2.get_process_date )
             >= xxccp_common_pkg2.get_process_date;
    -- 取得値を戻す
    RETURN lt_companies_code;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- 該当するレコードが存在しなかった場合はNULLを返す
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_companies_code_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_department_code_f
   *Desctiption   : 所属部門コード取得
   ******************************************************************************/
  FUNCTION get_department_code_f(
    in_user_id IN NUMBER -- ユーザーID
  )
  RETURN VARCHAR2        -- 所属部門コード
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_department_code_f'; -- プログラム名
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    lt_department_code per_all_people_f.attribute28%TYPE DEFAULT NULL; -- 所属部門コード
    ld_process_date    DATE;                                           -- 業務日付
    lt_employee_id     fnd_user.employee_id%TYPE;                      -- 所属部門コード
--
  BEGIN
    -- ==========================================
    -- 業務日付取得
    -- ==========================================
    ld_process_date :=xxccp_common_pkg2.get_process_date;
    -- ==========================================
    -- ユーザテーブルから従業員ID取得
    -- ==========================================
    SELECT fu.employee_id AS employee_id   -- 従業員ID
    INTO   lt_employee_id
    FROM   fnd_user       fu
    WHERE  fu.user_id     = in_user_id
    AND    -- 業務日付が開始日以上
           -- もし開始日 = NULL -> 開始日 = 業務日付に変換
           NVL( fu.start_date, ld_process_date ) <= ld_process_date
    AND
           -- 業務日付が終了日以下
           -- もし終了日 = NULL -> 終了日 = 業務日付に変換
           NVL( fu.end_date, ld_process_date ) >= ld_process_date;
    -- ==========================================
    -- 従業員テーブルから部門コード取得
    -- ==========================================
    SELECT pap.attribute28    AS department_code   -- 部門コード
    INTO   lt_department_code
    FROM   per_all_people_f   pap
    WHERE  pap.person_id      = lt_employee_id
    AND    -- 業務日付が有効開始日以上
           -- もし有効開始日 = NULL -> 有効開始日 = 業務日付に変換
           NVL( pap.effective_start_date, ld_process_date ) <= ld_process_date
    AND    -- 業務日付が有効終了日以下
           -- もし有効終了日 = NULL -> 有効終了日 = 業務日付に変換
           NVL( pap.effective_end_date, ld_process_date ) >= ld_process_date;
--
    RETURN lt_department_code;        -- 所属部門コード
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --所属部門コードにNULLを設定
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_department_code_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_batch_name_f
   *Desctiption   : バッチ名取得
   ******************************************************************************/
  FUNCTION get_batch_name_f(
    iv_category_name IN VARCHAR2 -- 仕訳カテゴリ名
  )
  RETURN VARCHAR2                -- バッチ名
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_batch_name_f'; -- プログラム名
    cv_space    CONSTANT VARCHAR2(1)  := ' ';                -- 半角スペース
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    lv_batch_name VARCHAR2(100)  DEFAULT NULL; -- バッチ名
--
  BEGIN
    --=======================================
    -- IN パラメータ仕訳カテゴリ名 NULL チェック
    --=======================================
    IF( iv_category_name IS NULL ) THEN
      --INパラメータが仕訳カテゴリ名がNULLの場合
      --OUTパラメータにシステム日付のみ設定
      lv_batch_name  := TO_CHAR( SYSDATE ); -- バッチ名
    ELSE
      --INパラメータが仕訳カテゴリ名がNULL以外場合
      --OUTパラメータに仕訳カテゴリ名+半角スペース+システム日付を設定
      lv_batch_name  := iv_category_name || cv_space ||TO_CHAR( SYSDATE ); -- バッチ名
    END IF;
--
    RETURN lv_batch_name; -- バッチ名
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_batch_name_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_slip_number_f
   *Desctiption   : 伝票番号取得
   ******************************************************************************/
  FUNCTION get_slip_number_f(
    iv_package_name IN VARCHAR2 -- パッケージ名
  )
  RETURN VARCHAR2               -- バッチ名
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'get_slip_number_f';           -- プログラム名
    cv_lookup_type CONSTANT VARCHAR2(30) := 'XXCOK1_SLIP_NUMBER_SEQ_TYPE'; --LOOKUPタイプ
    cv_pad_string  CONSTANT VARCHAR2(1)  := '0';                           --追加する文字列:0
    cn_pad_length  CONSTANT NUMBER       :=  8;                            --文字列の長さ
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    lv_slip_number   VARCHAR2(30)     DEFAULT NULL;     -- 伝票番号
    lv_sql_stmt      VARCHAR2(32767)  DEFAULT NULL;     -- 動的SQL用文字列
    lt_sequence_id   fnd_lookup_values.attribute1%TYPE; -- シーケンス取得用変数
    lt_slip_num_hdr2 fnd_lookup_values.attribute2%TYPE; -- シーケンス番号頭2桁
    ln_sequence_nm   NUMBER;                            -- シーケンス番号
--
  BEGIN
    -- =======================================================
    -- シーケンス番号作成用変数の取得
    -- =======================================================
    SELECT flv.attribute1    flv_sequence_id     -- シーケンス取得用変数
         , flv.attribute2    flv_slip_num_hdr2   -- シーケンス番号頭2桁
    INTO   lt_sequence_id                        -- シーケンス取得用変数
         , lt_slip_num_hdr2                      -- シーケンス番号頭2桁
    FROM   fnd_lookup_values flv                 -- 見積ヘッダーテーブル:販売先用見積ヘッダー
    WHERE  flv.lookup_type   = cv_lookup_type    -- シーケンス取得用変数
    AND    flv.language      = USERENV( 'LANG' ) -- 言語タイプ
    AND    flv.meaning       = iv_package_name;  -- パッケージ名
    -- =======================================================
    -- 動的SQL文の作成
    -- =======================================================
    lv_sql_stmt := ( 'SELECT ' || lt_sequence_id || '.NEXTVAL sequence_num  ' || ' FROM DUAL' );
    -- =======================================================
    -- 動的SQL文の実行
    -- =======================================================
    EXECUTE IMMEDIATE lv_sql_stmt INTO ln_sequence_nm;
    -- =======================================================
    -- 伝票番号の作成
    -- =======================================================
    lv_slip_number := lt_slip_num_hdr2 || LPAD ( ln_sequence_nm, cn_pad_length, cv_pad_string );
    -- =======================================================
    -- 伝票番号 返却
    -- =======================================================
    RETURN lv_slip_number; -- 伝票番号
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- データが存在しないためNULLを返却する
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_slip_number_f;
--
  /******************************************************************************
   *FUNCTION NAME : check_year_migration_f
   *Desctiption   : 年次移行情報確定チェック
   ******************************************************************************/
  FUNCTION check_year_migration_f(
    in_year IN NUMBER -- 年次
  )
  RETURN BOOLEAN      -- ブール値
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name            CONSTANT VARCHAR2(30) := 'check_year_migration_f';     -- プログラム名
    ct_status_decision_a   CONSTANT xxcok_cust_shift_info.status%TYPE := 'A';     -- ステータス=確定
    ct_shift_type_annual_1 CONSTANT xxcok_cust_shift_info.shift_type%TYPE := '1'; -- 移行区分=年次
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    ln_count NUMBER ; -- 件数
    lb_check BOOLEAN; -- 戻り値
--
  BEGIN
    -- ==========================================
    -- 年次移行情報確定件数取得
    -- 対象会計年度 = INパラメータの年次  かつ
    -- ステータス   = 'A':確定            かつ
    -- 移行区分     = '1':年次
    -- ==========================================
    SELECT COUNT( 'X' )          AS kensu                 -- 件数
    INTO   ln_count                                       -- 件数
    FROM   xxcok_cust_shift_info csi                      -- 顧客移行情報テーブル
    WHERE  csi.target_acctg_year = in_year
    AND    csi.status            = ct_status_decision_a
    AND    csi.shift_type        = ct_shift_type_annual_1
    AND    ROWNUM                = 1;
    -- ==========================================
    -- 年次移行情報確定件数チェック
    -- ==========================================
    IF( ln_count = 0 ) THEN
      -- 存在しない
      -- 対象会計年度 = INパラメータの年次  かつ
      -- ステータス   = 'A':確定            かつ
      -- 移行区分     = '1':年次に合致するレコードなし
      lb_check := TRUE;  -- 判定結果 =TRUE を設定
    ELSE
      -- 存在する
      -- 対象会計年度 = INパラメータの年次  かつ
      -- ステータス   = 'A':確定            かつ
      -- 移行区分     = '1':年次に合致するレコードあり
      lb_check := FALSE; -- 判定結果 =FALSE を設定
    END IF;
    --判定結果
    RETURN lb_check;     -- 判定結果をリターン
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --存在しない
      RETURN TRUE; -- TRUE
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END check_year_migration_f;
--
  /******************************************************************************
   *FUNCTION NAME : check_code_combination_id_f
   *Desctiption   : CCID存在チェック
   ******************************************************************************/
  FUNCTION check_code_combination_id_f(
    iv_segment1 IN VARCHAR2 -- 会社コード
  , iv_segment2 IN VARCHAR2 -- 部門コード
  , iv_segment3 IN VARCHAR2 -- 勘定科目コード
  , iv_segment4 IN VARCHAR2 -- 補助科目コード
  , iv_segment5 IN VARCHAR2 -- 顧客コード
  , iv_segment6 IN VARCHAR2 -- 企業コード
  , iv_segment7 IN VARCHAR2 -- 予備１コード
  , iv_segment8 IN VARCHAR2 -- 予備２コード
  )
  RETURN BOOLEAN            -- ブール値
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'check_code_combination_id_f'; -- プログラム名
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    ln_count             NUMBER ;                                    -- 件数
    lb_check             BOOLEAN;                                    -- 戻り値
    lv_errbuf            VARCHAR2(32767);                            -- エラー・バッファ
    lv_retcode           VARCHAR2(1);                                -- リターンコード
    lv_errmsg            VARCHAR2(32767);                            -- エラー・メッセージ
    lt_set_of_books_id   gl_sets_of_books.set_of_books_id%TYPE;      -- 会計帳簿ID
    lt_set_of_books_name gl_sets_of_books.name%TYPE;                 -- 会計帳簿名
    lt_chart_acct_id     gl_sets_of_books.chart_of_accounts_id%TYPE; -- 勘定体系ID
    lt_period_set_name   gl_sets_of_books.period_set_name%TYPE;      -- カレンダ名
    ln_aff_segment_cnt   NUMBER;                                     -- AFFセグメント定義数
    lt_currency_code     gl_sets_of_books.currency_code%TYPE;        -- 機能通貨コード
--
  BEGIN
    -- ==========================================
    -- get_set_of_books_info_p
    -- 会計帳簿情報取得
    -- ==========================================
    xxcok_common_pkg.get_set_of_books_info_p(
      lv_errbuf            --  エラー・バッファ
    , lv_retcode           --  リターンコード
    , lv_errmsg            --  エラー・メッセージ
    , lt_set_of_books_id   -- 会計帳簿ID
    , lt_set_of_books_name -- 会計帳簿名
    , lt_chart_acct_id     -- 勘定体系ID
    , lt_period_set_name   -- カレンダ名
    , ln_aff_segment_cnt   -- AFFセグメント定義数
    , lt_currency_code     -- 機能通貨コード
    );
    -- ==========================================
    -- GL_CODE_COMBINATIONS検索
    -- CCID存在チェック
    -- 会計帳簿情報取得
    -- INパラメータの条件で検索
    -- ==========================================
    SELECT COUNT( 'X' )             AS kensu           -- 件数
    INTO   ln_count                                    -- 件数
    FROM   gl_code_combinations     gcc                -- gl_code_combinationsテーブル
    WHERE  gcc.chart_of_accounts_id = lt_chart_acct_id -- 勘定体系ID
    AND    gcc.segment1             = iv_segment1      -- 会社コード
    AND    gcc.segment2             = iv_segment2      -- 部門コード
    AND    gcc.segment3             = iv_segment3      -- 勘定科目コード
    AND    gcc.segment4             = iv_segment4      -- 補助科目コード
    AND    gcc.segment5             = iv_segment5      -- 顧客コード
    AND    gcc.segment6             = iv_segment6      -- 企業コード
    AND    gcc.segment7             = iv_segment7      -- 予備１コード
    AND    gcc.segment8             = iv_segment8      -- 予備２コード
    AND    ROWNUM                   = 1;
    -- ==========================================
    -- CCID存在チェック確認
    -- ==========================================
    IF( ln_count = 0 ) THEN
      -- 存在しない
      lb_check := FALSE; -- 判定結果 =FALSE を設定
    ELSE
      -- 存在する
      lb_check := TRUE;  -- 判定結果 =TRUE を設定
    END IF;
    --判定結果
    RETURN lb_check;     -- 判定結果をリターン
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --存在しない
      RETURN FALSE;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END check_code_combination_id_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_code_combination_id_f
   *Desctiption   : CCID取得
   ******************************************************************************/
  FUNCTION get_code_combination_id_f(
    id_proc_date IN DATE     -- 処理日
  , iv_segment1  IN VARCHAR2 -- 会社コード
  , iv_segment2  IN VARCHAR2 -- 部門コード
  , iv_segment3  IN VARCHAR2 -- 勘定科目コード
  , iv_segment4  IN VARCHAR2 -- 補助科目コード
  , iv_segment5  IN VARCHAR2 -- 顧客コード
  , iv_segment6  IN VARCHAR2 -- 企業コード
  , iv_segment7  IN VARCHAR2 -- 予備１コード
  , iv_segment8  IN VARCHAR2 -- 予備２コード
  )
  RETURN NUMBER              -- 勘定科目ID
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name               CONSTANT VARCHAR2(30) := 'get_code_combination_id_f'; -- プログラム名
    cn_err_on                 CONSTANT NUMBER       := 1;                           -- エラー値
    cn_err_off                CONSTANT NUMBER       := 0;                           -- エラー値
    cv_application_short_name CONSTANT VARCHAR2(5)  := 'SQLGL';                     -- アプリケーション短縮名
    cv_key_flex_code          CONSTANT VARCHAR2(3)  := 'GL#';                       -- フレックスフィールドコード
    cn_start                  CONSTANT NUMBER       := 1;                           -- FOR 開始値
    cn_end                    CONSTANT NUMBER       := 8;                           -- FOR 終了値
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    ln_ccid                 NUMBER DEFAULT NULL;                        -- 勘定科目ID
    ln_in_para_check_flg    NUMBER DEFAULT 0;                           -- 入力パラメータチェックフラグ
    lb_exist_check          BOOLEAN;                                    -- 戻り値
    lb_get_cmbntn_id_check  BOOLEAN;                                    -- 戻り値
    lv_errbuf               VARCHAR2(32767);                            --  エラー・バッファ
    lv_retcode              VARCHAR2(1);                                --  リターンコード
    lv_errmsg               VARCHAR2(32767);                            --  エラー・メッセージ
    lt_set_of_books_id      gl_sets_of_books.set_of_books_id%TYPE;      -- 会計帳簿ID
    lt_set_of_books_name    gl_sets_of_books.name%TYPE;                 -- 会計帳簿名
    lt_chart_acct_id        gl_sets_of_books.chart_of_accounts_id%TYPE; -- 勘定体系ID
    lt_period_set_name      gl_sets_of_books.period_set_name%TYPE;      -- カレンダ名
    ln_aff_segment_cnt      NUMBER;                                     -- AFFセグメント定義数
    lt_currency_code        gl_sets_of_books.currency_code%TYPE;        -- 機能通貨コード
    l_segments_rec          fnd_flex_ext.SegmentArray;                  -- セグメント値配列
    ln_count                NUMBER;                                     -- 添え字
--
  BEGIN
    -- ==========================================
    -- INパラメータ入力値チェック
    -- ==========================================
    IF(    ( id_proc_date IS NULL )
        OR ( iv_segment1  IS NULL )
        OR ( iv_segment2  IS NULL )
        OR ( iv_segment3  IS NULL )
        OR ( iv_segment4  IS NULL )
        OR ( iv_segment5  IS NULL )
        OR ( iv_segment6  IS NULL )
        OR ( iv_segment7  IS NULL )
        OR ( iv_segment8  IS NULL )
    ) THEN
      -- 処理日,会社コード,部門コード,勘定科目コード,
      -- 補助科目コード, 顧客コード, 企業コード
      -- 予備１コード, 予備２コードがNULLの場合
      -- 入力パラメータチェックフラグをオン設定
      ln_in_para_check_flg := cn_err_on;
    END IF;
--
    IF( ln_in_para_check_flg = cn_err_off ) THEN
      --=======================================
      -- CCID存在チェック
      --=======================================
      lb_exist_check := xxcok_common_pkg.check_code_combination_id_f(
                          iv_segment1 -- 会社コード
                        , iv_segment2 -- 部門コード
                        , iv_segment3 -- 勘定科目コード
                        , iv_segment4 -- 補助科目コード
                        , iv_segment5 -- 顧客コード
                        , iv_segment6 -- 企業コード
                        , iv_segment7 -- 予備１コード
                        , iv_segment8 -- 予備２コード
                        );
      -- ==========================================
      -- get_set_of_books_info_p
      -- 会計帳簿情報取得
      -- ==========================================
      xxcok_common_pkg.get_set_of_books_info_p(
        lv_errbuf            -- エラー・バッファ
      , lv_retcode           -- リターンコード
      , lv_errmsg            -- エラー・メッセージ
      , lt_set_of_books_id   -- 会計帳簿ID
      , lt_set_of_books_name -- 会計帳簿名
      , lt_chart_acct_id     -- 勘定体系ID
      , lt_period_set_name   -- カレンダ名
      , ln_aff_segment_cnt   -- AFFセグメント定義数
      , lt_currency_code     -- 機能通貨コード
      );
     IF( lb_exist_check = TRUE ) THEN
       -- CCIDが存在している場合
       -- ==========================================
       -- GL_CODE_COMBINATIONS検索
       -- CCID取得
       -- INパラメータの条件で検索
       -- ==========================================
       SELECT code_combination_id      ccid               -- 勘定科目ID
       INTO   ln_ccid                                     -- 勘定科目ID
       FROM   gl_code_combinations     gcc                -- gl_code_combinationsテーブル
       WHERE  gcc.chart_of_accounts_id = lt_chart_acct_id -- 勘定体系ID
       AND    gcc.segment1             = iv_segment1      -- 会社コード
       AND    gcc.segment2             = iv_segment2      -- 部門コード
       AND    gcc.segment3             = iv_segment3      -- 勘定科目コード
       AND    gcc.segment4             = iv_segment4      -- 補助科目コード
       AND    gcc.segment5             = iv_segment5      -- 顧客コード
       AND    gcc.segment6             = iv_segment6      -- 企業コード
       AND    gcc.segment7             = iv_segment7      -- 予備１コード
       AND    gcc.segment8             = iv_segment8;     -- 予備２コード
     ELSE
       -- CCIDが存在してない場合
       -- ==========================================
       -- セグメント値配列にINパラメータiv_segment1～
       -- iv_segment8を設定
       -- ==========================================
       << segment_loop >>
       FOR ln_count IN cn_start..cn_end LOOP
         CASE ln_count
           WHEN 1   THEN
             l_segments_rec( ln_count ) := iv_segment1;
           WHEN 2   THEN
             l_segments_rec( ln_count ) := iv_segment2;
           WHEN 3   THEN
             l_segments_rec( ln_count ) := iv_segment3;
           WHEN 4   THEN
             l_segments_rec( ln_count ) := iv_segment4;
           WHEN 5   THEN
             l_segments_rec( ln_count ) := iv_segment5;
           WHEN 6   THEN
             l_segments_rec( ln_count ) := iv_segment6;
           WHEN 7   THEN
             l_segments_rec( ln_count ) := iv_segment7;
           WHEN 8   THEN
             l_segments_rec( ln_count ) := iv_segment8;
         END CASE;
       END LOOP segment_loop;
       -- ==========================================
       -- CCID登録
       -- ==========================================
       lb_get_cmbntn_id_check := fnd_flex_ext.get_combination_id(
                                   cv_application_short_name -- アプリケーション短縮名
                                 , cv_key_flex_code          -- フレックスフィールドコード
                                 , lt_chart_acct_id          -- AFF体系ID
                                 , id_proc_date              -- 基準日付
                                 , cn_end                    -- セグメント数
                                 , l_segments_rec            -- セグメント値配列
                                 , ln_ccid                   -- 生成したCCID
                                 );
     END IF;
    ELSE
      -- 勘定科目IDにNULLを設定
      ln_ccid := NULL;
    END IF;
--
    RETURN ln_ccid;                                                         -- 勘定科目ID
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- 戻り値にNULLを設定
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_code_combination_id_f;
--
  /**********************************************************************************
   * Function Name : put_message_f
   * Description   : メッセージ出力
   ***********************************************************************************/
  FUNCTION put_message_f(
    in_which    IN NUMBER   -- 出力区分
  , iv_message  IN VARCHAR2 -- メッセージ
  , in_new_line IN NUMBER   -- 改行
  )
  RETURN BOOLEAN            -- ブール値
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'put_message_f';  -- プログラム名
    cn_newline_one CONSTANT NUMBER       := 1;                --改行出力件数=1
    cv_blank       CONSTANT VARCHAR2(1)  := ' ';              --半角スペース
    -- =======================================================
    -- ローカル変数
    -- ===============================================
    ln_count NUMBER; --ループ変数
--
  BEGIN
    -- INパラメータの出力区分,メッセージ判定
    IF( ( in_which = FND_FILE.OUTPUT )
      OR
       ( in_which = FND_FILE.LOG    ) )
    THEN
      -- INパラメータのメッセージ判定
      IF( iv_message IS NOT NULL ) THEN
        -- INパラメータの出力区分=FND_FILE.OUTPUTまたはFND_FILE.LOGまたは
        -- メッセージがNULLでない場合
        fnd_file.put_line(
          which => in_which   -- 出力区分セット
        , buff  => iv_message -- 出力メッセージセット
        );
      END IF;
    ELSE
      -- INパラメータの出力区分<>FND_FILE.OUTPUTまたはFND_FILE.LOGの場合
      RETURN FALSE;
    END IF;
    -- 改行出力判定
    IF( in_new_line >= cn_newline_one ) THEN
      -- INパラメータの改行の値分 改行を出力
      << newline_loop >>
      FOR ln_count IN 1..in_new_line LOOP
        fnd_file.put_line(
          which => in_which
        , buff  => cv_blank
        );
      END LOOP newline_loop;
    END IF;
--
    RETURN TRUE;
--
  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END put_message_f;
--
-- 2009/10/02 Ver.1.12 [障害E_T3_00630] SCS S.Moriyama UPD START
--  /******************************************************************************
--   *FUNCTION NAME : get_base_code_f
--   *Desctiption   : 所属拠点コード取得
--   ******************************************************************************/
--  FUNCTION get_base_code_f(
--    id_proc_date IN DATE   -- 処理日
--  , in_user_id   IN NUMBER -- ユーザーID
--  )
--  RETURN VARCHAR2          -- 所属拠点コード
--  IS
--    -- =======================================================
--    -- ローカル定数
--    -- =======================================================
--    cv_prg_name CONSTANT VARCHAR2(30) := 'get_base_code_f'; -- プログラム名
--    -- =======================================================
--    -- ローカル変数
--    -- =======================================================
--    ld_process_date             DATE;                                                   -- 業務日付
--    lt_employee_id              fnd_user.employee_id%TYPE;                              -- 所属部門コード
--    lt_max_object_version_num   per_all_assignments_f.object_version_number%TYPE;       -- 最新レコード判定変数
--    lt_max_effective_start_date per_all_assignments_f.effective_start_date%TYPE;        -- 有効開始日
--    lt_base_code                per_all_assignments_f.ass_attribute5%TYPE DEFAULT NULL; -- 所属拠点コード
--    lt_announce_date            per_all_assignments_f.ass_attribute2%TYPE DEFAULT NULL; -- 発令日
--    lt_new_base_code            per_all_assignments_f.ass_attribute5%TYPE DEFAULT NULL; -- 拠点コード（新）
--    lt_old_base_code            per_all_assignments_f.ass_attribute6%TYPE DEFAULT NULL; -- 拠点コード（旧）
----
--  BEGIN
--    -- ==========================================
--    -- 業務日付取得
--    -- ==========================================
--    ld_process_date :=xxccp_common_pkg2.get_process_date;
--    -- ==========================================
--    -- ユーザテーブルから従業員ID取得
--    -- ==========================================
--    SELECT fu.employee_id AS employee_id -- 従業員ID
--    INTO   lt_employee_id
--    FROM   fnd_user fu
--    WHERE  fu.user_id     = in_user_id
--    AND    -- 業務日付が開始日以上
--           -- もし開始日 = NULL -> 開始日 = 業務日付に変換
--           NVL( fu.start_date, ld_process_date ) <= ld_process_date
--    AND
--           -- 業務日付が終了日以下
--           -- もし終了日 = NULL -> 終了日 = 業務日付に変換
--           NVL( fu.end_date  , ld_process_date ) >= ld_process_date;
--    -- ==========================================
--    -- PER_ALL_ASSIGNMENTS_Fからperson_idの
--    -- 最新レコードを判定するキー情報取得
--    -- ==========================================
--    SELECT MAX( paa.object_version_number ) AS object_version_number -- バージョン番号
--    INTO   lt_max_object_version_num
--    FROM   per_all_assignments_f            paa
--    WHERE  paa.person_id                    = lt_employee_id;
----
--    SELECT MAX( paa.effective_start_date )  AS effective_start_date -- 有効開始日
--    INTO   lt_max_effective_start_date
--    FROM   per_all_assignments_f            paa
--    WHERE  paa.person_id                    = lt_employee_id;
--    -- ==========================================
--    -- PER_ALL_ASSIGNMENTS_Fから発令日,
--    -- 拠点コード(新), 拠点コード(旧) 取得
--    -- ==========================================
--    SELECT paa.ass_attribute2        AS announce_date              -- 発令日
--         , paa.ass_attribute5        AS new_base_code              -- 拠点コード（新）
--         , paa.ass_attribute6        AS old_base_code              -- 拠点コード（旧）
--    INTO   lt_announce_date                                        -- 発令日
--         , lt_new_base_code                                        -- 拠点コード（新）
--         , lt_old_base_code                                        -- 拠点コード（旧）
--    FROM   per_all_assignments_f     paa                           -- アサイメントテーブル
--    WHERE  paa.person_id             = lt_employee_id
--    AND    paa.object_version_number = lt_max_object_version_num   -- バージョン番号=MAX(バージョン番号)
--    AND    paa.effective_start_date  = lt_max_effective_start_date -- 有効開始日=MAX(有効開始日)
--    AND    -- 業務日付が有効開始日以上
--           -- もし有効開始日 = NULL -> 有効開始日 = 業務日付に変換
--           NVL( paa.effective_start_date, ld_process_date ) <= ld_process_date
--    AND    -- 業務日付が有効終了日以下
--           -- もし有効終了日 = NULL -> 有効終了日 = 業務日付に変換
--           NVL( paa.effective_end_date  , ld_process_date ) >= ld_process_date;
--    -- ==========================================
--    --拠点コード判定処理
--    --INパラメータ:処理日,発令日を比較して
--    -- 拠点コード(新)または拠点コード(旧) を
--    --OUTパラメータに設定
--    -- ==========================================
--    IF( TO_DATE( lt_announce_date  ,'YYYYMMDD' ) <= id_proc_date ) THEN
--      --発令日 >= INパラメータ:処理日
--      --OUTパラメータ:所属拠点コードに拠点コード(新)を設定
--      lt_base_code := lt_new_base_code;
--    ELSE
--      --発令日 >= INパラメータ:処理日
--      --OUTパラメータ:所属拠点コードに拠点コード(旧)を設定
--      lt_base_code := lt_old_base_code;
--    END IF;
----
--    RETURN lt_base_code;                  -- 所属拠点コード
----
--  EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--      --所属拠点コードにNULLを設定
--      RETURN NULL;
--    WHEN OTHERS THEN
--      RAISE_APPLICATION_ERROR(
--        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
--      );
----
--  END get_base_code_f;
  /******************************************************************************
   *FUNCTION NAME : get_base_code_f
   *Desctiption   : 所属拠点コード取得
   ******************************************************************************/
  FUNCTION get_base_code_f(
    id_proc_date IN DATE   -- 処理日
  , in_user_id   IN NUMBER -- ユーザーID
  )
  RETURN VARCHAR2          -- 所属拠点コード
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name           CONSTANT VARCHAR2(30) := 'get_base_code_f';                 -- プログラム名
--
    cv_system_person_type CONSTANT per_person_types.system_person_type%TYPE := 'EMP';
    cv_active_flag        CONSTANT per_person_types.active_flag%TYPE        := 'Y';
    cv_date_fmt           CONSTANT VARCHAR2(8)                              := 'RRRRMMDD';
--
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    lt_base_code    per_all_assignments_f.ass_attribute5%TYPE DEFAULT NULL; -- 所属拠点コード
    ld_process_date DATE                                      DEFAULT NULL; -- 業務日付
    ln_user_id      NUMBER;
    ld_target_date  DATE;
--
  BEGIN
    IF ( id_proc_date IS NULL ) THEN
      ld_process_date := xxccp_common_pkg2.get_process_date;
    ELSE
      ld_process_date := TRUNC( id_proc_date );
    END IF;
--
    IF ( in_user_id IS NULL ) THEN
      ln_user_id := fnd_global.user_id;
    ELSE
      ln_user_id := in_user_id;
    END IF;
--
    SELECT  CASE
              WHEN paaf.ass_attribute2 IS NULL THEN -- 発令日
                paaf.ass_attribute5
              WHEN TO_DATE( paaf.ass_attribute2, cv_date_fmt ) > ld_process_date THEN
                paaf.ass_attribute6                 -- 拠点コード（旧）
              ELSE
                paaf.ass_attribute5                 -- 拠点コード（新）
            END  AS base_code
    INTO    lt_base_code                        -- 所属拠点コード
    FROM    fnd_user              fu    -- ユーザーマスタ
          , per_all_people_f      papf  -- 従業員マスタ
          , per_person_types      ppt   -- 従業員区分マスタ
          , per_all_assignments_f paaf  -- 従業員割当マスタ(アサイメント)
    WHERE   fu.user_id              = ln_user_id
      AND   papf.person_id          = fu.employee_id
      AND   id_proc_date      BETWEEN NVL( TRUNC( papf.effective_start_date ), ld_target_date )
                                  AND NVL( TRUNC( papf.effective_end_date   ), ld_target_date )
      AND   ppt.person_type_id      = papf.person_type_id
      AND   ppt.business_group_id   = papf.business_group_id
      AND   ppt.system_person_type  = cv_system_person_type
      AND   ppt.active_flag         = cv_active_flag
      AND   papf.person_id          = paaf.person_id
      AND   id_proc_date      BETWEEN NVL( TRUNC( paaf.effective_start_date ), ld_target_date )
                                  AND NVL( TRUNC( paaf.effective_end_date   ), ld_target_date )
    ;
--
    RETURN lt_base_code;                  -- 所属拠点コード
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_base_code_f;
-- 2009/10/02 Ver.1.12 [障害E_T3_00630] SCS S.Moriyama UPD END
--
  /**********************************************************************************
   * Procedure Name   : split_csv_data_p
   * Description      : CSV文字列分割
   ***********************************************************************************/
  PROCEDURE split_csv_data_p(
    ov_errbuf        OUT VARCHAR2        -- エラーバッファ
  , ov_retcode       OUT VARCHAR2        -- リターンコード
  , ov_errmsg        OUT VARCHAR2        -- エラーメッセージ
  , iv_csv_data      IN  VARCHAR2        -- CSV文字列
  , on_csv_col_cnt   OUT PLS_INTEGER     -- CSV項目数
  , ov_split_csv_tab OUT g_split_csv_tbl -- CSV分割データ
  )
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name    CONSTANT VARCHAR2(30)  := 'split_csv_data_p'; -- プログラム名
    cv_comma       CONSTANT VARCHAR2(1)   := ',';                --カンマ
    cn_length_zero CONSTANT NUMBER        := 0;                  --文字列のカンマなしの場合
    cn_first_char  CONSTANT NUMBER        := 1;                  --1文字目
    cn_add_value   CONSTANT NUMBER        := 2;                  --文字列への加算値
    -- =======================
    -- ローカル変数
    -- =======================
    lv_retcode VARCHAR(1);                   -- リターンコードの変数
    lv_line    VARCHAR2(32767) DEFAULT NULL; --1行のデータ
    lb_col     BOOLEAN         DEFAULT TRUE; --カラム作成継続
    ln_col     NUMBER          DEFAULT 0;    --カラム番号
    ln_length  NUMBER;                       --カンマの位置
--
  BEGIN
    lv_retcode := gv_status_normal;
    -- INパラメータのCSV文字列をローカル変数に格納
    lv_line    := iv_csv_data;
    -- ===============================================
    -- 1.CSV文字列データを区切り文字単位(カンマ)で分解
    -- ===============================================
    IF( lv_line IS NOT NULL ) THEN
      -- *** 区切り文字単位(カンマ)で分解 ***
      << comma_loop >>
      LOOP
      --lv_lineがNULLまたはカンマが文字列中に存在しなくなった場合  終了
      EXIT WHEN ( lb_col = FALSE ) ;
        --カラム番号をカウント
        ln_col := ln_col + 1;
        --カンマの位置を取得
        ln_length := INSTR(lv_line, cv_comma);
        --カンマがなし
        IF ( ln_length = cn_length_zero ) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        --カンマがあり
        ELSE
          --カンマ分削除
          ln_length := ln_length - 1;
          lb_col    := TRUE;
        END IF;
        -- *** CSV形式を項目ごとに分解し変数に格納 ***
        IF ( lv_line IS NULL ) THEN
          ov_split_csv_tab( ln_col ) := NULL;
          lb_col    := FALSE;
        ELSE
          ov_split_csv_tab( ln_col ) := SUBSTR( lv_line, cn_first_char, ln_length );
        END IF;
        -- *** 取得した項目を除く(カンマはのぞくため、ln_length + 2) ***
        IF ( lb_col = TRUE ) THEN
          --カンマありの場合
          lv_line := SUBSTR( lv_line, ln_length + cn_add_value );
        ELSE
          --カンマなしの場合
          lv_line := SUBSTR( lv_line, ln_length );
        END IF;
      END LOOP comma_loop;
    END IF;
    --=======================================
    -- 出力パラメータセット
    --=======================================
    ov_errbuf      := NULL;
    ov_retcode     := lv_retcode;
    ov_errmsg      := NULL;
    on_csv_col_cnt := ln_col;     -- CSV項目数をセット
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END split_csv_data_p;
--
  /******************************************************************************
   *FUNCTION NAME : get_bill_to_cust_code_f
   *Desctiption   : 請求先顧客コード取得
   ******************************************************************************/
  FUNCTION get_bill_to_cust_code_f(
    iv_ship_to_cust_code IN VARCHAR2 -- 出荷先顧客コード
  )
  RETURN VARCHAR2                    -- 請求先顧客コード
  IS
    -- =======================================================
    -- ローカル定数
    -- =======================================================
    cv_prg_name               CONSTANT  VARCHAR2(30) := 'get_bill_to_cust_code_f'; -- プログラム名
    cv_attribute_1            CONSTANT  VARCHAR2(1)  := '1';
    cv_receipt_of_money_2     CONSTANT  VARCHAR2(1)  := '2';                       -- 入金
    cv_status_a               CONSTANT  VARCHAR2(1)  := 'A';
    cv_customer_class_code_14 CONSTANT  VARCHAR2(2)  := '14';
    cv_site_use_code_bill_to  CONSTANT  VARCHAR2(7)  := 'BILL_TO';
    -- =======================================================
    -- ローカル変数
    -- =======================================================
    lt_request_to_cust_code  hz_cust_accounts.account_number%TYPE DEFAULT NULL; -- 請求先顧客コード
    lt_ship_account_number   hz_cust_accounts.account_number%TYPE DEFAULT NULL; -- 出荷先顧客コード
--
  BEGIN
    -- =======================================================
    -- 請求先顧客コードの取得
    -- =======================================================
    SELECT bill_account_number
         , ship_account_number
    INTO   lt_request_to_cust_code                                              -- 請求先顧客コード
         , lt_ship_account_number                                               -- 出荷先顧客コード
    FROM(
      --① 請求先顧客－出荷先顧客
      SELECT bill_hzca_1.account_number                AS bill_account_number   -- 請求先顧客マスタ.
           , ship_hzca_1.account_number                AS ship_account_number   -- 出荷先顧客マスタ.
      FROM   hz_cust_accounts                          bill_hzca_1              -- 請求先顧客マスタ
           , hz_cust_acct_sites_all                    bill_hasa_1              -- 請求先顧客所在地
           , hz_cust_site_uses_all                     bill_hsua_1              -- 請求先顧客使用目的
           , hz_customer_profiles                      bill_hzcp_1              -- 請求先顧客プロファイル
           , hz_cust_accounts                          ship_hzca_1              -- 出荷先顧客マスタ
           , hz_cust_acct_sites_all                    ship_hasa_1              -- 出荷先顧客所在地
           , hz_cust_site_uses_all                     ship_hsua_1              -- 出荷先顧客使用目的
           , hz_cust_acct_relate_all                   bill_hcar_1              -- 顧客関連マスタ(請求関連)
             --請求先顧客マスタ.顧客ID                 = 顧客関連マスタ(請求関連).XXX
      WHERE  bill_hzca_1.cust_account_id               = bill_hcar_1.cust_account_id
             --顧客関連マスタ(請求関連).XXX            = 出荷先顧客マスタ.XXX
      AND    bill_hcar_1.related_cust_account_id       = ship_hzca_1.cust_account_id
             --請求先顧客マスタ.XXX                    = '14'
      AND    bill_hzca_1.customer_class_code           = cv_customer_class_code_14
             --顧客関連マスタ(請求関連).ステータス     = 'A'
      AND    bill_hcar_1.status                        = cv_status_a
             --顧客関連マスタ(請求関連).アトリビュート = cv_attribute_1
      AND    bill_hcar_1.attribute1                    = cv_attribute_1
             --請求先顧客所在地.組織ID                 = ログインユーザの組織ID
      AND    bill_hasa_1.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --出荷先顧客所在地.組織ID                 = ログインユーザの組織ID
      AND    ship_hasa_1.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --顧客関連マスタ(請求関連).組織ID         = ログインユーザの組織ID
      AND    bill_hcar_1.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --請求先顧客使用目的.組織ID               = ログインユーザの組織ID
      AND    bill_hsua_1.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --出荷先顧客使用目的.組織ID               = ログインユーザの組織ID
      AND    ship_hsua_1.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --請求先顧客マスタ.顧客ID                 = 請求先顧客所在地.顧客ID
      AND    bill_hzca_1.cust_account_id               = bill_hasa_1.cust_account_id
             --請求先顧客所在地.顧客所在地ID           = 請求先顧客使用目的.顧客所在地ID
      AND    bill_hasa_1.cust_acct_site_id             = bill_hsua_1.cust_acct_site_id
             --請求先顧客使用目的.使用目的             = 'BILL_TO'(請求先)
      AND    bill_hsua_1.site_use_code                 = cv_site_use_code_bill_to
             --出荷先顧客マスタ.顧客ID                 = 出荷先顧客所在地.顧客ID
      AND    ship_hzca_1.cust_account_id               = ship_hasa_1.cust_account_id
             --出荷先顧客使用目的.顧客所在地ID         = 出荷先顧客所在地.顧客所在地ID
      AND    ship_hsua_1.cust_acct_site_id             = ship_hasa_1.cust_acct_site_id
             --出荷先顧客使用目的.請求先事業所ID       = 請求先顧客使用目的.使用目的ID
      AND    ship_hsua_1.bill_to_site_use_id           = bill_hsua_1.site_use_id
             --請求先顧客プロファイル.使用目的ID       IS NULL
      AND    bill_hzcp_1.site_use_id                   IS NULL
             --請求先顧客マスタ.顧客ID                 = 請求先顧客プロファイル.顧客ID
      AND    bill_hzca_1.cust_account_id               = bill_hzcp_1.cust_account_id
-- 2009/04/09 Ver.1.9 [障害T1_0341] SCS K.Yamaguchi DEL START
--      AND    NOT EXISTS(
--               SELECT 'X'
--               FROM   hz_cust_acct_relate_all   cash_hcar_1   --顧客関連マスタ(入金関連)
--                      --顧客関連マスタ(入金関連).ステータス   = ‘A’
--               WHERE  cash_hcar_1.status                      = cv_status_a
--                      --顧客関連マスタ(入金関連).関連分類     = ‘2’ (入金)
--               AND    cash_hcar_1.attribute1                  = cv_receipt_of_money_2
--                      --顧客関連マスタ(入金関連).関連先顧客ID = 請求先顧客マスタ.顧客ID
--               AND    cash_hcar_1.related_cust_account_id     = bill_hzca_1.cust_account_id
--               --顧客関連マスタ(入金関連).組織ID              = ログインユーザの組織ID
--               AND    cash_hcar_1.org_id                      = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
--             )
-- 2009/04/09 Ver.1.9 [障害T1_0341] SCS K.Yamaguchi DEL END
      UNION ALL
      SELECT ship_hzca_2.account_number      AS bill_account_number   --請求先顧客コード
           , ship_hzca_2.account_number      AS ship_account_number   --出荷先顧客コード
      FROM   hz_cust_accounts                ship_hzca_2              --出荷先顧客マスタ  ※入金先・請求先含む
           , hz_cust_acct_sites_all          bill_hasa_2              --請求先顧客所在地
           , hz_cust_site_uses_all           bill_hsua_2              --請求先顧客使用目的
           , hz_cust_site_uses_all           ship_hsua_2              --出荷先顧客使用目的
           , hz_customer_profiles            bill_hzcp_2              --請求先顧客プロファイル
             --請求先顧客所在地.組織ID       = ログインユーザの組織ID
      WHERE  bill_hasa_2.org_id              = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --請求先顧客使用目的.組織ID     = ログインユーザの組織ID
      AND    bill_hsua_2.org_id              = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --出荷先顧客使用目的.組織ID     = ログインユーザの組織ID
      AND    ship_hsua_2.org_id              = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
-- 2009/04/09 Ver.1.9 [障害T1_0341] SCS K.Yamaguchi DEL START
--      AND    NOT EXISTS(
--               SELECT ROWNUM
--               FROM   hz_cust_acct_relate_all ex_hcar_2        --顧客関連マスタ
--               WHERE   --顧客関連マスタ(請求関連).顧客ID        = 出荷先顧客マスタ.顧客ID
--                       (ex_hcar_2.cust_account_id               = ship_hzca_2.cust_account_id
--                        --
--                        --顧客関連マスタ(請求関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
--               OR       ex_hcar_2.related_cust_account_id       = ship_hzca_2.cust_account_id)
--                        --顧客関連マスタ(請求関連).ステータス   = ‘A’
--               AND      ex_hcar_2.status                        = cv_status_a
--                        --請求先顧客所在地.組織ID               = ログインユーザの組織ID
--               AND      ex_hcar_2.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
--                       )
-- 2009/04/09 Ver.1.9 [障害T1_0341] SCS K.Yamaguchi DEL END
             --請求先顧客マスタ.顧客ID           = 請求先顧客所在地.顧客ID
      AND    ship_hzca_2.cust_account_id         = bill_hasa_2.cust_account_id
             --請求先顧客所在地.顧客所在地ID     = 請求先顧客使用目的.顧客所在地ID
      AND    bill_hasa_2.cust_acct_site_id       = bill_hsua_2.cust_acct_site_id
             --請求先顧客所在地.顧客所在地ID     = 出荷先顧客使用目的.顧客所在地ID
      AND    bill_hasa_2.cust_acct_site_id       = ship_hsua_2.cust_acct_site_id
             --請求先顧客使用目的.使用目的       = 'BILL_TO'(請求先)
      AND    bill_hsua_2.site_use_code           = cv_site_use_code_bill_to
             --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
      AND    ship_hsua_2.bill_to_site_use_id     = bill_hsua_2.site_use_id
             --請求先顧客プロファイル.使用目的   IS NULL
      AND    bill_hzcp_2.site_use_id             IS NULL
             --請求先顧客マスタ.顧客ID           = 請求先顧客プロファイル.顧客ID
      AND    ship_hzca_2.cust_account_id         = bill_hzcp_2.cust_account_id
    )
    WHERE ship_account_number = iv_ship_to_cust_code;    --入力パラメータ.出荷先顧客コード
    -- =======================================================
    -- 請求先顧客コードをリターン
    -- =======================================================
    RETURN lt_request_to_cust_code; -- 請求先顧客コード
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --NO_DATA_FOUNDの場合戻り値にNULLを設定
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_bill_to_cust_code_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_uom_conversion_qty_f
   *Desctiption   : 基準単位換算数取得
   ******************************************************************************/
  FUNCTION get_uom_conversion_qty_f(
    iv_item_code IN VARCHAR2 -- 品目コード
  , iv_uom_code  IN VARCHAR2 -- 単位コード
  , in_quantity  IN NUMBER   -- 換算前数量
  )
  RETURN NUMBER              -- 基準単位換算後数量
  IS
  -- =======================================================
  -- ローカル定数
  -- =======================================================
    cv_prg_name       CONSTANT VARCHAR2(30) := 'get_uom_conversion_qty_f'; -- プログラム名
    cv_profile_option CONSTANT VARCHAR2(30) := 'XXCOK1_ORG_CODE_SALES';
  -- =======================================================
  -- ローカル変数
  -- =======================================================
    lv_before_uom_code        VARCHAR2(10);       -- 換算前単位コード
    ln_before_quantity        NUMBER;             -- 換算前数量
    lov_item_code             VARCHAR2(20);       -- 品目コード
    lov_organization_code     VARCHAR2(10);       -- 在庫組織コード
    lon_inventory_item_id     NUMBER;             -- 品目ＩＤ
    lon_organization_id       NUMBER;             -- 在庫組織ＩＤ
    lov_after_uom_code        VARCHAR2(10);       -- 換算後単位コード
    ln_after_quantity         NUMBER;             -- 換算後数量
    ln_content                NUMBER;             -- 入数
    lv_errbuf                 VARCHAR2(2000);     -- エラー・メッセージエラー       #固定#
    lv_retcode                VARCHAR2(1);        -- リターン・コード               #固定#
    lv_errmsg                 VARCHAR2(2000);     -- ユーザー・エラー・メッセージ   #固定#
--
    lt_primary_uom_code       mtl_system_items_b.primary_uom_code%TYPE;
--
  BEGIN
--
    lv_before_uom_code    := iv_uom_code;
    ln_before_quantity    := in_quantity;
    lov_item_code         := iv_item_code;
--
    lov_organization_code := FND_PROFILE.VALUE( cv_profile_option );
--
    -- 品目の基準単位を取得
    SELECT msib.primary_uom_code
    INTO   lt_primary_uom_code
    FROM   mtl_system_items_b     msib
         , mtl_parameters         mp
    WHERE  msib.organization_id   = mp.organization_id
      AND  mp.organization_code   = lov_organization_code
      AND  msib.segment1          = lov_item_code
    ;
--
    xxcos_common_pkg.get_uom_cnv(
      iv_before_uom_code        => lv_before_uom_code     -- IN            VARCHAR2 -- 換算前単位コード
    , in_before_quantity        => ln_before_quantity     -- IN            NUMBER   -- 換算前数量
    , iov_item_code             => lov_item_code          -- IN OUT NOCOPY VARCHAR2 -- 品目コード
    , iov_organization_code     => lov_organization_code  -- IN OUT NOCOPY VARCHAR2 -- 在庫組織コード
    , ion_inventory_item_id     => lon_inventory_item_id  -- IN OUT        NUMBER   -- 品目ＩＤ
    , ion_organization_id       => lon_organization_id    -- IN OUT        NUMBER   -- 在庫組織ＩＤ
    , iov_after_uom_code        => lt_primary_uom_code    -- IN OUT NOCOPY VARCHAR2 -- 換算後単位コード
    , on_after_quantity         => ln_after_quantity      -- OUT    NOCOPY NUMBER   -- 換算後数量
    , on_content                => ln_content             -- OUT    NOCOPY NUMBER   -- 入数
    , ov_errbuf                 => lv_errbuf              -- OUT    NOCOPY VARCHAR2 -- エラー・メッセージエラー     #固定#
    , ov_retcode                => lv_retcode             -- OUT    NOCOPY VARCHAR2 -- リターン・コード             #固定#
    , ov_errmsg                 => lv_errmsg              -- OUT    NOCOPY VARCHAR  -- ユーザー・エラー・メッセージ #固定#
    );
--
    RETURN ln_after_quantity;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END get_uom_conversion_qty_f;
--
  /**********************************************************************************
   * Procedure Name   : get_directory_path_f
   * Description      : ディレクトリパス取得
   ***********************************************************************************/
  FUNCTION get_directory_path_f(
    iv_directory_name              IN  VARCHAR2         -- ディレクトリ名
  )
  RETURN VARCHAR2                                       -- ディレクトリパス
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_directory_path_f'; -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lt_directory_path              all_directories.directory_path%TYPE DEFAULT NULL;
--
  BEGIN
    SELECT ad.directory_path  AS directory_path
    INTO lt_directory_path
    FROM all_directories      ad
    WHERE directory_name = iv_directory_name
    ;
    RETURN lt_directory_path;
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END get_directory_path_f;
--
END xxcok_common_pkg;
/
