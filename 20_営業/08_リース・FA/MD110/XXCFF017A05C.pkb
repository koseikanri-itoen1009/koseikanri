create or replace
PACKAGE BODY XXCFF017A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF017A05C(body)
 * Description      : 自販機減価償却振替
 * MD.050           : MD050_CFF_017_A05_自販機減価償却振替
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                       初期処理                                  (A-1)
 *  get_profile_values         プロファイル値取得                        (A-2)
 *  get_period                 会計期間チェック                          (A-3)
 *  chk_je_vending_data_exist  前回作成済み自販機物件仕訳存在チェック    (A-4)
 *  ins_gl_oif_dr              GLOIF登録処理(借方データ)                 (A-5)
 *  ins_gl_oif_cr              GLOIF登録処理(貸方データ)                 (A-6)
 *  submain                    メイン処理プロシージャ
 *  main                       コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/08/01    1.0   SCSK川元善博     新規作成
 *  2014/11/07    1.1   SCSK小路恭弘     E_本稼動_12563
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by    CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  --*** 会計期間チェックエラー
  chk_period_expt           EXCEPTION;
  --*** GL会計期間チェックエラー
  chk_gl_period_expt        EXCEPTION;
  --*** 自販機物件仕訳存在チェック(一般会計OIF)エラー
  chk_cnt_gloif_expt        EXCEPTION;
  --*** 自販機物件仕訳存在チェック(仕訳ヘッダ)エラー
  chk_cnt_glhead_expt       EXCEPTION;
  --*** ユーザ情報(ログインユーザ、所属部門)取得エラー
  get_login_info_expt       EXCEPTION;
  --*** 会計帳簿名取得エラー
  get_sob_name_expt         EXCEPTION;
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
  cv_pkg_name            CONSTANT VARCHAR2(20) := 'XXCFF017A05C';     --パッケージ名
--
  -- ***アプリケーション短縮名
  cv_msg_kbn_cff         CONSTANT VARCHAR2(5)  := 'XXCFF';
--
  -- ***メッセージ名(本文)
  cv_msg_013a20_m_010    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; --プロファイル取得エラー
  cv_msg_013a20_m_011    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00038'; --会計期間チェックエラー
  cv_msg_013a20_m_012    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00130'; --GL会計期間チェックエラー
  cv_msg_013a20_m_013    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00218'; --自販機物件仕訳存在チェック(一般会計OIF)エラー
  cv_msg_013a20_m_014    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00219'; --自販機物件仕訳存在チェック(仕訳ヘッダ)エラー
  cv_msg_013a20_m_015    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00115'; --一般会計OIF作成メッセージ
  cv_msg_013a20_m_016    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00181'; --取得エラー
  cv_msg_013a20_m_017    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00233'; --リース料率数値チェックエラー
--
  -- ***メッセージ名(トークン)
  cv_msg_013a20_t_010    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50076'; --XXCFF:会社コード_本社
  cv_msg_013a20_t_011    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50255'; --XXCFF:仕訳ソース_自販機物件
  cv_msg_013a20_t_012    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50258'; --XXCFF:仕訳カテゴリ_自販機減価償却振替
  cv_msg_013a20_t_013    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50078'; --XXCFF:部門コード_調整部門
  cv_msg_013a20_t_014    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50273'; --XXCFF:台帳名
  cv_msg_013a20_t_015    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50155'; --XXCFF:伝票番号_リース
  cv_msg_013a20_t_016    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50268'; --XXCFF:勘定科目_自販機リース料
  cv_msg_013a20_t_017    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50269'; --XXCFF:補助科目_自販機
  cv_msg_013a20_t_018    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50275'; --XXCFF:リース料率
  cv_msg_013a20_t_019    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50154'; --ログイン(ユーザ名,所属部門)情報
  cv_msg_013a20_t_020    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50160'; --会計帳簿名
  cv_msg_013a20_t_021    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50167'; --ログインユーザID=
  cv_msg_013a20_t_022    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50168'; --会計帳簿ID=
--
  -- ***トークン名
  cv_tkn_prof            CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type         CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period          CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_name        CONSTANT VARCHAR2(20) := 'KEY_NAME';
  cv_tkn_key_val         CONSTANT VARCHAR2(20) := 'KEY_VAL';
  cv_tkn_func_name       CONSTANT VARCHAR2(20) := 'FUNC_NAME';
--
  -- ***プロファイル
  cv_comp_cd_itoen       CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_ITOEN';    --会社コード_本社
  cv_je_src_vending      CONSTANT VARCHAR2(30) := 'XXCFF1_JE_SOURCE_VENDING';   --仕訳ソース_自販機物件
  cv_je_cat_vending      CONSTANT VARCHAR2(30) := 'XXCFF1_JE_CATEGORY_VENDING'; --仕訳カテゴリ_自販機減価償却振替
  cv_dep_cd_chosei       CONSTANT VARCHAR2(30) := 'XXCFF1_DEP_CD_CHOSEI';       --部門コード_調整部門
  cv_fixed_assets_books  CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSETS_BOOKS';  --台帳名
  cv_slip_num_lease      CONSTANT VARCHAR2(30) := 'XXCFF1_SLIP_NUM_LEASE';      --伝票番号_リース
  cv_account_vending     CONSTANT VARCHAR2(30) := 'XXCFF1_ACCOUNT_VENDING';     --勘定科目_自販機リース料
  cv_sub_account_vending CONSTANT VARCHAR2(30) := 'XXCFF1_SUB_ACCOUNT_VENDING'; --補助科目_自販機
  cv_lease_rate          CONSTANT VARCHAR2(30) := 'XXCFF1_LEASE_RATE';          --リース料率
--
  -- ***ファイル出力
--
  cv_file_type_out       CONSTANT VARCHAR2(10) := 'OUTPUT';                     --メッセージ出力
  cv_file_type_log       CONSTANT VARCHAR2(10) := 'LOG';                        --ログ出力
--
  -- ***ダミー値
  cv_ptnr_cd_dammy       CONSTANT VARCHAR2(9)  := '000000000';                  --顧客コード_定義なし
  cv_busi_cd_dammy       CONSTANT VARCHAR2(6)  := '000000';                     --企業コード_定義なし
  cv_project_dammy       CONSTANT VARCHAR2(1)  := '0';                          --予備１_定義なし
  cv_future_dammy        CONSTANT VARCHAR2(1)  := '0';                          --予備２_定義なし
--
  -- ***税コード
  cv_tax_code            CONSTANT VARCHAR2(4)  := '0000';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***バルクフェッチ用定義
  TYPE g_deprn_run_ttype      IS TABLE OF fa_deprn_periods.deprn_run%TYPE INDEX BY PLS_INTEGER;
  TYPE g_book_type_code_ttype IS TABLE OF fa_deprn_periods.book_type_code%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ***バルクフェッチ用定義
  g_deprn_run_tab             g_deprn_run_ttype;
  g_book_type_code_tab        g_book_type_code_ttype;
--
  -- ***処理件数
  -- 一般会計OIF登録処理における件数出力
  gn_gloif_dr_target_cnt   NUMBER;     -- 対象件数(借方データ)
  gn_gloif_cr_target_cnt   NUMBER;     -- 対象件数(貸方データ)
  gn_gloif_normal_cnt      NUMBER;     -- 正常件数
  gn_gloif_error_cnt       NUMBER;     -- エラー件数
--
  -- 初期値情報
  g_init_rec      xxcff_common1_pkg.init_rtype;
--
  -- パラメータ会計期間名
  gv_period_name  VARCHAR2(100);
--
  -- ***ユーザ情報
  -- ログインユーザ
  gt_login_user_name  xx03_users_v.user_name%TYPE;
  -- 起票部門(所属部門)
  gt_login_dept_code  per_people_f.attribute28%TYPE;
  -- ***会計帳簿情報
  -- 会計帳簿名
  gt_sob_name         gl_sets_of_books.name%TYPE;
--
  -- ***プロファイル値
  gv_comp_cd_itoen         VARCHAR2(100);    -- 会社コード_本社
  gv_je_src_vending        VARCHAR2(100);    -- 仕訳ソース_自販機物件
  gv_je_cat_vending        VARCHAR2(100);    -- 仕訳カテゴリ_自販機減価償却振替
  gv_dep_cd_chosei         VARCHAR2(100);    -- 部門コード_調整部門
  gv_fixed_assets_books    VARCHAR2(100);    -- 台帳名
  gv_slip_num_lease        VARCHAR2(100);    -- 伝票番号_リース
  gv_account_vending       VARCHAR2(100);    -- 勘定科目_自販機リース料
  gv_sub_account_vending   VARCHAR2(100);    -- 補助科目_自販機
  gv_lease_rate            VARCHAR2(100);    -- リース料率
  gn_lease_rate            NUMBER;           -- リース料率
--
  -- ***カーソル定義
--
  -- ***テーブル型配列
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_cr
   * Description      : GLOIF登録処理(貸方データ) (A-6)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_cr(
    ov_errbuf         OUT    VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT    VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_cr'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    INSERT INTO gl_interface(
       status                -- ステータス
      ,set_of_books_id       -- 会計帳簿ID
      ,accounting_date       -- 仕訳有効日付
      ,currency_code         -- 通貨コード
      ,date_created          -- 新規作成日付
      ,created_by            -- 新規作成者ID
      ,actual_flag           -- 残高タイプ
      ,user_je_category_name -- 仕訳カテゴリ名
      ,user_je_source_name   -- 仕訳ソース名
      ,segment1              -- 会社
      ,segment2              -- 部門
      ,segment3              -- 科目
      ,segment4              -- 補助科目
      ,segment5              -- 顧客
      ,segment6              -- 企業
      ,segment7              -- 予備1
      ,segment8              -- 予備2
      ,entered_dr            -- 借方金額
      ,entered_cr            -- 貸方金額
      ,reference10           -- 仕訳明細摘要
      ,period_name           -- 会計期間名
      ,attribute1            -- 税区分
      ,attribute3            -- 伝票番号
      ,attribute4            -- 起票部門
      ,attribute5            -- 伝票入力者
      ,context               -- コンテキスト
    )
    SELECT
       'NEW'                                       AS status                -- ステータス
      ,g_init_rec.set_of_books_id                  AS set_of_books_id       -- 会計帳簿ID
      ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) AS accounting_date       -- 仕訳有効日付
      ,g_init_rec.currency_code                    AS currency_code         -- 通貨コード
      ,cd_creation_date                            AS date_created          -- 新規作成日付
      ,cn_created_by                               AS created_by            -- 新規作成者ID
      ,'A'                                         AS actual_flag           -- 残高タイプ
      ,gv_je_cat_vending                           AS user_je_category_name -- 仕訳カテゴリ名
      ,gv_je_src_vending                           AS user_je_source_name   -- 仕訳ソース名
      ,summary.segment1                            AS segment1              -- 会社コード
      ,gv_dep_cd_chosei                            AS segment2              -- 部門コード
      ,gv_account_vending                          AS segment3              -- 科目コード
      ,gv_sub_account_vending                      AS segment4              -- 補助科目コード
      ,cv_ptnr_cd_dammy                            AS segment5              -- 顧客コード
      ,cv_busi_cd_dammy                            AS segment6              -- 企業コード
      ,cv_project_dammy                            AS segment7              -- 予備1
      ,cv_future_dammy                             AS segment8              -- 予備2
      ,0                                           AS entered_dr            -- 借方金額
      ,SUM(summary.entered_cr)                     AS entered_cr            -- 貸方金額
      ,NULL                                        AS reference10           -- 仕訳明細摘要
      ,gv_period_name                              AS period_name           -- 会計期間名
      ,cv_tax_code                                 AS attribute1            -- 税区分
      ,gv_slip_num_lease                           AS attribute3            -- 伝票番号
      ,gt_login_dept_code                          AS attribute4            -- 起票部門
      ,gt_login_user_name                          AS attribute5            -- 伝票入力者
      ,gt_sob_name                                 AS context               -- 会計帳簿名
    FROM
      (
       SELECT
          gcc.segment1                                  AS segment1         -- 会社コード
         ,TRUNC(xvoh.assets_cost * gn_lease_rate / 100) AS entered_cr       -- 取得価格
       FROM
          fa_additions_b          fab
         ,fa_deprn_detail         fdd
         ,fa_deprn_periods        fdp
         ,fa_distribution_history fdh
         ,gl_code_combinations    gcc
         ,xxcff_vd_object_headers xvoh
       WHERE
           fdd.asset_id            = fab.asset_id
       AND fdd.book_type_code      = gv_fixed_assets_books
       AND fdd.period_counter      = fdp.period_counter
       AND fdd.book_type_code      = fdp.book_type_code
       AND fdh.book_type_code      = gv_fixed_assets_books
       AND fdh.date_ineffective    is null
       AND fdd.distribution_id     = fdh.distribution_id
       AND gcc.code_combination_id = fdh.code_combination_id
       AND fdd.deprn_source_code   = 'D'
       AND fdp.period_name         = gv_period_name
       AND fab.tag_number          = xvoh.object_code
       UNION ALL
       SELECT
          gcc.segment1                             AS segment1              -- 会社コード
         ,CASE
            WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
            ELSE
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
            END = 5 THEN
              TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 12)
            WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
            ELSE
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
            END = 6 THEN
              TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 14)
            WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
            ELSE
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
            END = 7 THEN
              TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 18)
            WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
            ELSE
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
            END >= 8 THEN
              TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 24)
          END                                      AS entered_cr            -- 取得価格
       FROM
          fa_additions_b          fab
         ,fa_books                fb
         ,fa_distribution_history fdh
         ,gl_code_combinations    gcc
         ,xxcff_vd_object_headers xvoh
       WHERE
           fab.asset_id            = fb.asset_id
       AND fb.book_type_code       = gv_fixed_assets_books
       AND fb.date_ineffective     is null
       AND fdh.date_ineffective    is null
       AND fdh.book_type_code      = gv_fixed_assets_books
       AND fab.asset_id            = fdh.asset_id
       AND gcc.code_combination_id = fdh.code_combination_id
       AND to_char(fb.date_placed_in_service, 'MM') = SUBSTRB(gv_period_name, 6, 2)
       AND fb.cost                 > 0
       AND NOT EXISTS
             (SELECT
                'X'
              FROM
                 fa_deprn_summary fds
                ,fa_deprn_periods fdp
              WHERE 1=1
              AND fds.asset_id       = fab.asset_id
              AND fds.period_counter = fdp.period_counter
              AND fds.book_type_code = fdp.book_type_code
              AND fds.book_type_code = gv_fixed_assets_books
              AND fdp.period_name    = gv_period_name)
       AND fab.tag_number          = xvoh.object_code
      ) summary
    GROUP BY
       summary.segment1        -- 会社コード
    ;
--
    -- 件数設定
    gn_gloif_cr_target_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END ins_gl_oif_cr;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_dr
   * Description      : GLOIF登録処理(借方データ) (A-5)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_dr(
    ov_errbuf         OUT    VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT    VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_dr'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
-- 2014/11/07 Ver.1.1 Y.Shouji ADD START
    cv_flag_on           CONSTANT VARCHAR2(1)  := 'Y';
-- 2014/11/07 Ver.1.1 Y.Shouji ADD END
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    INSERT INTO gl_interface(
       status                -- ステータス
      ,set_of_books_id       -- 会計帳簿ID
      ,accounting_date       -- 仕訳有効日付
      ,currency_code         -- 通貨コード
      ,date_created          -- 新規作成日付
      ,created_by            -- 新規作成者ID
      ,actual_flag           -- 残高タイプ
      ,user_je_category_name -- 仕訳カテゴリ名
      ,user_je_source_name   -- 仕訳ソース名
      ,segment1              -- 会社
      ,segment2              -- 部門
      ,segment3              -- 科目
      ,segment4              -- 補助科目
      ,segment5              -- 顧客
      ,segment6              -- 企業
      ,segment7              -- 予備1
      ,segment8              -- 予備2
      ,entered_dr            -- 借方金額
      ,entered_cr            -- 貸方金額
      ,reference10           -- 仕訳明細摘要
      ,period_name           -- 会計期間名
      ,attribute1            -- 税区分
      ,attribute3            -- 伝票番号
      ,attribute4            -- 起票部門
      ,attribute5            -- 伝票入力者
      ,context               -- コンテキスト
    )
    SELECT
       'NEW'                                         AS status                -- ステータス
      ,g_init_rec.set_of_books_id                    AS set_of_books_id       -- 会計帳簿ID
      ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))   AS accounting_date       -- 仕訳有効日付
      ,g_init_rec.currency_code                      AS currency_code         -- 通貨コード
      ,cd_creation_date                              AS date_created          -- 新規作成日付
      ,cn_created_by                                 AS created_by            -- 新規作成者ID
      ,'A'                                           AS actual_flag           -- 残高タイプ
      ,gv_je_cat_vending                             AS user_je_category_name -- 仕訳カテゴリ名
      ,gv_je_src_vending                             AS user_je_source_name   -- 仕訳ソース名
      ,gcc.segment1                                  AS segment1              -- 会社コード
      ,xvoh.department_code                          AS segment2              -- 部門コード
      ,gv_account_vending                            AS segment3              -- 科目コード
      ,gv_sub_account_vending                        AS segment4              -- 補助科目コード
-- 2014/11/07 Ver.1.1 Y.Shouji MOD START
--      ,xvoh.customer_code                            AS segment5              -- 顧客コード
      ,(CASE WHEN les_class_v.vd_cust_flag = cv_flag_on THEN
                  xvoh.customer_code ELSE cv_ptnr_cd_dammy END)
                                                     AS segment5              -- 顧客コード
-- 2014/11/07 Ver.1.1 Y.Shouji MOD END
      ,cv_busi_cd_dammy                              AS segment6              -- 企業コード
      ,cv_project_dammy                              AS segment7              -- 予備1
      ,cv_future_dammy                               AS segment8              -- 予備2
      ,TRUNC(xvoh.assets_cost * gn_lease_rate / 100) AS entered_dr            -- 取得価格
      ,0                                             AS entered_cr            -- 貸方金額
      ,fab.tag_number                                AS reference10           -- 仕訳明細摘要
      ,gv_period_name                                AS period_name           -- 会計期間名
      ,cv_tax_code                                   AS attribute1            -- 税区分
      ,gv_slip_num_lease                             AS attribute3            -- 伝票番号
      ,gt_login_dept_code                            AS attribute4            -- 起票部門
      ,gt_login_user_name                            AS attribute5            -- 伝票入力者
      ,gt_sob_name                                   AS context               -- 会計帳簿名
    FROM
       fa_additions_b          fab
      ,fa_deprn_detail         fdd
      ,fa_deprn_periods        fdp
      ,fa_distribution_history fdh
      ,gl_code_combinations    gcc
      ,xxcff_vd_object_headers xvoh
-- 2014/11/07 Ver.1.1 Y.Shouji ADD START
      ,xxcff_lease_class_v     les_class_v   -- リース種別ビュー
-- 2014/11/07 Ver.1.1 Y.Shouji ADD END
    WHERE
        fdd.asset_id            = fab.asset_id
    AND fdd.book_type_code      = gv_fixed_assets_books
    AND fdd.period_counter      = fdp.period_counter
    AND fdd.book_type_code      = fdp.book_type_code
    AND fdh.book_type_code      = gv_fixed_assets_books
    AND fdh.date_ineffective    is null
    AND fdd.distribution_id     = fdh.distribution_id
    AND gcc.code_combination_id = fdh.code_combination_id
    AND fdd.deprn_source_code   = 'D'
    AND fdp.period_name         = gv_period_name
    AND fab.tag_number          = xvoh.object_code
-- 2014/11/07 Ver.1.1 Y.Shouji ADD START
    AND xvoh.lease_class        = les_class_v.lease_class_code
-- 2014/11/07 Ver.1.1 Y.Shouji ADD END
    UNION ALL
    SELECT
       'NEW'                                       AS status                -- ステータス
      ,g_init_rec.set_of_books_id                  AS set_of_books_id       -- 会計帳簿ID
      ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) AS accounting_date       -- 仕訳有効日付
      ,g_init_rec.currency_code                    AS currency_code         -- 通貨コード
      ,cd_creation_date                            AS date_created          -- 新規作成日付
      ,cn_created_by                               AS created_by            -- 新規作成者ID
      ,'A'                                         AS actual_flag           -- 残高タイプ
      ,gv_je_cat_vending                           AS user_je_category_name -- 仕訳カテゴリ名
      ,gv_je_src_vending                           AS user_je_source_name   -- 仕訳ソース名
      ,gcc.segment1                                AS segment1              -- 会社コード
      ,xvoh.department_code                        AS segment2              -- 部門コード
      ,gv_account_vending                          AS segment3              -- 科目コード
      ,gv_sub_account_vending                      AS segment4              -- 補助科目コード
-- 2014/11/07 Ver.1.1 Y.Shouji MOD START
--      ,xvoh.customer_code                          AS segment5              -- 顧客コード
      ,(CASE WHEN les_class_v.vd_cust_flag = cv_flag_on THEN
                  xvoh.customer_code ELSE cv_ptnr_cd_dammy END)
                                                   AS segment5              -- 顧客コード
-- 2014/11/07 Ver.1.1 Y.Shouji MOD END
      ,cv_busi_cd_dammy                            AS segment6              -- 企業コード
      ,cv_project_dammy                            AS segment7              -- 予備1
      ,cv_future_dammy                             AS segment8              -- 予備2
      ,CASE
         WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
         ELSE
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
         END = 5 THEN
           TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 12)
         WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
         ELSE
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
         END = 6 THEN
           TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 14)
         WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
         ELSE
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
         END = 7 THEN
           TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 18)
         WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
         ELSE
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
         END >= 8 THEN
           TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 24)
       END                                         AS entered_dr            -- 取得価格
      ,0                                           AS entered_cr            -- 貸方金額
      ,fab.tag_number                              AS reference10           -- 仕訳明細摘要
      ,gv_period_name                              AS period_name           -- 会計期間名
      ,cv_tax_code                                 AS attribute1            -- 税区分
      ,gv_slip_num_lease                           AS attribute3            -- 伝票番号
      ,gt_login_dept_code                          AS attribute4            -- 起票部門
      ,gt_login_user_name                          AS attribute5            -- 伝票入力者
      ,gt_sob_name                                 AS context               -- 会計帳簿名
    FROM
       fa_additions_b          fab
      ,fa_books                fb
      ,fa_distribution_history fdh
      ,gl_code_combinations    gcc
      ,xxcff_vd_object_headers xvoh
-- 2014/11/07 Ver.1.1 Y.Shouji ADD START
      ,xxcff_lease_class_v     les_class_v   -- リース種別ビュー
-- 2014/11/07 Ver.1.1 Y.Shouji ADD END
    WHERE
        fab.asset_id            = fb.asset_id
    AND fb.book_type_code       = gv_fixed_assets_books
    AND fb.date_ineffective     is null
    AND fdh.date_ineffective    is null
    AND fdh.book_type_code      = gv_fixed_assets_books
    AND fab.asset_id            = fdh.asset_id
    AND gcc.code_combination_id = fdh.code_combination_id
    AND to_char(fb.date_placed_in_service, 'MM') = SUBSTRB(gv_period_name, 6, 2)
    AND fb.cost                 > 0
    AND NOT EXISTS
          (SELECT
              fds.asset_id
             ,fds.deprn_reserve
           FROM
              fa_deprn_summary fds
             ,fa_deprn_periods fdp
           WHERE 1=1
           AND fds.asset_id       = fab.asset_id
           AND fds.period_counter = fdp.period_counter
           AND fds.book_type_code = fdp.book_type_code
           AND fds.book_type_code = gv_fixed_assets_books
           AND fdp.period_name    = gv_period_name)
    AND fab.tag_number          = xvoh.object_code
-- 2014/11/07 Ver.1.1 Y.Shouji ADD START
    AND xvoh.lease_class        = les_class_v.lease_class_code
-- 2014/11/07 Ver.1.1 Y.Shouji ADD END
    ;
--
    -- 件数設定
    gn_gloif_dr_target_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END ins_gl_oif_dr;
--
  /**********************************************************************************
   * Procedure Name   : chk_je_vending_data_exist
   * Description      : 前回作成済み自販機物件仕訳存在チェック(A-4)
   ***********************************************************************************/
  PROCEDURE chk_je_vending_data_exist(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_je_vending_data_exist'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
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
    -- 件数
    ln_cnt_gloif  NUMBER; -- 一般会計OIF
    ln_cnt_glhead NUMBER; -- 仕訳ヘッダ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --======================================
    -- 一般会計OIF 存在チェック
    --======================================
    SELECT
      COUNT(gi.set_of_books_id)
    INTO
      ln_cnt_gloif
    FROM
      gl_interface    gi -- 一般会計OIF
    WHERE
        gi.user_je_source_name = gv_je_src_vending
    AND gi.period_name         = gv_period_name
    ;
--
    IF ( NVL(ln_cnt_gloif,0) >= 1 ) THEN
      RAISE chk_cnt_gloif_expt;
    END IF;
--
    --======================================
    -- 仕訳ヘッダ 存在チェック
    --======================================
    SELECT
      COUNT(gjh.je_header_id)
    INTO
      ln_cnt_glhead
    FROM
      gl_je_headers     gjh  -- 仕訳ヘッダ
     ,gl_je_sources_tl  gjst -- 仕訳ソース
    WHERE
        gjh.je_source            = gjst.je_source_name
    AND gjst.language            = USERENV('LANG')
    AND gjst.user_je_source_name = gv_je_src_vending
    AND gjh.period_name          = gv_period_name
    ;
--
    IF ( NVL(ln_cnt_glhead,0) >= 1 ) THEN
      RAISE chk_cnt_glhead_expt;
    END IF;
--
  EXCEPTION
--
    -- *** 自販機物件仕訳存在チェック(一般会計OIF)エラーハンドラ ***
    WHEN chk_cnt_gloif_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_013  -- 自販機物件仕訳存在チェック(一般会計OIF)エラー
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 自販機物件仕訳存在チェック(仕訳ヘッダ)エラーハンドラ ***
    WHEN chk_cnt_glhead_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_014  -- 自販機物件仕訳存在チェック(仕訳ヘッダ)エラー
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END chk_je_vending_data_exist;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : 会計期間チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
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
    -- 資産台帳名
    lv_book_type_code VARCHAR(100);
    -- 会計期間ステータス
    lv_closing_status VARCHAR(100);
--
    -- *** ローカル・カーソル ***
    CURSOR period_cur
    IS
      SELECT
         fdp.deprn_run        AS deprn_run      -- 減価償却実行フラグ
        ,fdp.book_type_code   AS book_type_code -- 資産台帳名
      FROM
         fa_deprn_periods     fdp   -- 減価償却期間
        ,fa_deprn_detail      fdd   -- 減価償却詳細情報
      WHERE
          fdd.book_type_code  = gv_fixed_assets_books
      AND fdp.book_type_code  = fdd.book_type_code
      AND fdp.period_counter  = fdd.period_counter
      AND fdp.period_name     = gv_period_name
      ;
--
    -- *** ローカル・レコード ***
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --======================================
    -- FA会計期間チェック
    --======================================
    -- カーソルオープン
    OPEN period_cur;
    -- データの一括取得
    FETCH period_cur
    BULK COLLECT INTO  g_deprn_run_tab      -- 減価償却実行フラグ
                      ,g_book_type_code_tab -- 資産台帳名
    ;
    -- カーソルクローズ
    CLOSE period_cur;
--
    -- 会計期間の取得件数がゼロ件⇒エラー
    IF g_deprn_run_tab.COUNT = 0 THEN
      RAISE chk_period_expt;
    END IF;
--
    <<chk_period_loop>>
    FOR ln_loop_cnt IN 1 .. g_deprn_run_tab.COUNT LOOP
--
      -- 減価償却が実行されていない⇒エラー
      IF NVL(g_deprn_run_tab(ln_loop_cnt),'N') <> 'Y' THEN
        lv_book_type_code := g_book_type_code_tab(ln_loop_cnt);
        RAISE chk_period_expt;
      END IF;
--
    END LOOP chk_period_loop;
--
    --======================================
    -- GL会計期間チェック
    --======================================
    BEGIN
      -- 会計期間ステータス取得
      SELECT
        gps.closing_status
      INTO
        lv_closing_status
      FROM
         fa_book_controls    fbc   -- 資産台帳マスタ
        ,gl_sets_of_books    gsob  -- 会計帳簿マスタ
        ,gl_periods          gp    -- 会計カレンダ
        ,gl_period_statuses  gps   -- 会計カレンダステータス
        ,fnd_application     fa    -- アプリケーション
      WHERE
        EXISTS
          (SELECT
             'X'
           FROM
             fa_deprn_detail     fdd   -- 減価償却詳細情報
           WHERE
               fdd.book_type_code = gv_fixed_assets_books
           AND fdd.book_type_code = fbc.book_type_code)
        AND fbc.set_of_books_id        = gsob.set_of_books_id
        AND gsob.period_set_name       = gp.period_set_name
        AND gp.period_name             = gv_period_name
        AND gsob.set_of_books_id       = gps.set_of_books_id
        AND gps.period_name            = gp.period_name
        AND gps.application_id         = fa.application_id
        AND fa.application_short_name  = 'SQLGL'
        AND gps.adjustment_period_flag = 'N'
      ;
--
      -- 会計期間ステータス取得
      IF ( lv_closing_status NOT IN ('O', 'F') ) THEN
        RAISE chk_gl_period_expt;
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE chk_gl_period_expt;
    END;
  EXCEPTION
--
    -- *** 会計期間チェックエラーハンドラ ***
    WHEN chk_period_expt THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_011  -- 会計期間チェックエラー
                                                    ,cv_tkn_bk_type       -- トークン'BOOK_TYPE_CODE'
                                                    ,lv_book_type_code    -- 資産台帳名
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** GL会計期間チェックエラーハンドラ ***
    WHEN chk_gl_period_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_012  -- GL会計期間チェックエラー
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- XXCFF:会社コード_本社
    gv_comp_cd_itoen := FND_PROFILE.VALUE(cv_comp_cd_itoen);
    IF (gv_comp_cd_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_010) -- XXCFF:会社コード_本社
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:仕訳ソース_自販機物件
    gv_je_src_vending := FND_PROFILE.VALUE(cv_je_src_vending);
    IF (gv_je_src_vending IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_011) -- XXCFF:仕訳ソース_自販機物件
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:仕訳カテゴリ_自販機減価償却振替
    gv_je_cat_vending := FND_PROFILE.VALUE(cv_je_cat_vending);
    IF (gv_je_cat_vending IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_012) -- XXCFF:仕訳カテゴリ_自販機減価償却振替
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:部門コード_調整部門
    gv_dep_cd_chosei := FND_PROFILE.VALUE(cv_dep_cd_chosei);
    IF (gv_dep_cd_chosei IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_013) -- XXCFF:部門コード_調整部門
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:台帳名
    gv_fixed_assets_books := FND_PROFILE.VALUE(cv_fixed_assets_books);
    IF (gv_fixed_assets_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_014) -- XXCFF:台帳名
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:伝票番号_リース
    gv_slip_num_lease := FND_PROFILE.VALUE(cv_slip_num_lease);
    IF (gv_slip_num_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_015) -- XXCFF:伝票番号_リース
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:勘定科目_自販機リース料
    gv_account_vending := FND_PROFILE.VALUE(cv_account_vending);
    IF (gv_account_vending IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_016) -- XXCFF:勘定科目_自販機リース料
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:補助科目_自販機
    gv_sub_account_vending := FND_PROFILE.VALUE(cv_sub_account_vending);
    IF (gv_sub_account_vending IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_017) -- XXCFF:補助科目_自販機
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:リース料率
    gv_lease_rate := FND_PROFILE.VALUE(cv_lease_rate);
    IF (gv_lease_rate IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_018) -- XXCFF:リース料率
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:リース料率の数値チェック
    BEGIN
      gn_lease_rate := TO_NUMBER(gv_lease_rate);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_013a20_m_017) -- リース料率数値チェックエラー
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END get_profile_values;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    ld_base_date  date;         --基準日
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 初期値情報の取得
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- 初期値情報
      ,ov_errbuf   => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(出力の表示)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(ログ)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --===========================================
    -- ユーザ情報(ログインユーザ、所属部門)取得
    --===========================================
    BEGIN
      SELECT
         xuv.user_name   --ログインユーザ
        ,ppf.attribute28 --起票部門 (所属部門)
      INTO
         gt_login_user_name
        ,gt_login_dept_code
      FROM
         xx03_users_v xuv
        ,per_people_f ppf
      WHERE
          xuv.user_id     = cn_created_by
      AND xuv.employee_id = ppf.person_id
      AND SYSDATE
          BETWEEN ppf.effective_start_date
              AND ppf.effective_end_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_login_info_expt;
    END;
--
    --===========================================
    -- 会計帳簿名称取得
    --===========================================
    BEGIN
      SELECT
        gsob.name   --会計帳簿名
      INTO
        gt_sob_name
      FROM
        gl_sets_of_books gsob
      WHERE
        gsob.set_of_books_id = g_init_rec.set_of_books_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_sob_name_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** ユーザ情報(ログインユーザ、所属部門)取得エラーハンドラ ***
    WHEN get_login_info_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_016  -- 取得エラー
                                                     ,cv_tkn_table         -- トークン'TABLE_NAME'
                                                     ,cv_msg_013a20_t_019  -- ログイン(ユーザ名,所属部門)情報
                                                     ,cv_tkn_key_name      -- トークン'KEY_NAME'
                                                     ,cv_msg_013a20_t_021  -- ログインユーザID=
                                                     ,cv_tkn_key_val       -- トークン'KEY_VAL'
                                                     ,cn_created_by)       -- ログインユーザID
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 会計帳簿名取得エラーハンドラ ***
    WHEN get_sob_name_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff              -- XXCFF
                                                     ,cv_msg_013a20_m_016         -- 取得エラー
                                                     ,cv_tkn_table                -- トークン'TABLE_NAME'
                                                     ,cv_msg_013a20_t_020         -- 会計帳簿名
                                                     ,cv_tkn_key_name             -- トークン'KEY_NAME'
                                                     ,cv_msg_013a20_t_022         -- 会計帳簿ID=
                                                     ,cv_tkn_key_val              -- トークン'KEY_VAL'
                                                     ,g_init_rec.set_of_books_id) -- 会計帳簿ID
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    iv_period_name  IN  VARCHAR2,     -- 1.会計期間名
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_warn_cnt              := 0;
    gn_gloif_dr_target_cnt   := 0;
    gn_gloif_cr_target_cnt   := 0;
    gn_gloif_normal_cnt      := 0;
    gn_gloif_error_cnt       := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- INパラメータ(会計期間名)をグローバル変数に設定
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- プロファイル値取得 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 会計期間チェック (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 前回作成済み自販機物件仕訳存在チェック (A-4)
    -- ============================================
    chk_je_vending_data_exist(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- GLOIF登録処理(借方データ) (A-5)
    -- ====================================
    ins_gl_oif_dr(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- GLOIF登録処理(貸方データ) (A-6)
    -- ====================================
    ins_gl_oif_cr(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_period_name IN  VARCHAR2       -- 1.会計期間名
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
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
       ov_retcode => lv_retcode
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
       iv_period_name -- 会計期間名
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --正常時の出力件数設定
    --===============================================================
    IF (lv_retcode = cv_status_normal) THEN
      -- 対象件数を成功件数に設定する
      gn_gloif_normal_cnt      := gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt;
    --===============================================================
    --エラー時の出力件数設定
    --===============================================================
    ELSE
      -- 成功件数をゼロにクリアする
      gn_gloif_normal_cnt      := 0;
      -- エラー件数に対象件数を設定する
      gn_gloif_error_cnt       := gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt;
    END IF;
--
    --===============================================================
    --一般会計OIF登録処理における件数出力
    --===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --自販機物件仕訳作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_015
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_gloif_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_gloif_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
END XXCFF017A05C;
/
