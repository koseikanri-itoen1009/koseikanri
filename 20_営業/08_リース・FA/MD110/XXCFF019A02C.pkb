CREATE OR REPLACE PACKAGE BODY XXCFF019A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A02C(body)
 * Description      : IFRS台帳一括追加
 * MD.050           : MD050_CFF_019_A02_IFRS台帳一括追加
 * Version          : 1.0
 *
 * Program List
 * ----------------------------- ----------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ----------------------------------------------------------
 *  init                          初期処理                                  (A-1)
 *  get_profile_values            プロファイル値取得                        (A-2)
 *  chk_period                    会計期間チェック                          (A-3)
 *  get_exec_date                 実行日時取得                              (A-4)
 *  get_ifrs_fa_add_data          IFRS台帳登録データ抽出                    (A-5)
 *  upd_ifrs_sets                 IFRS台帳連携セット更新                    (A-6)
 *  submain                       メイン処理プロシージャ
 *  main                          コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/11/13    1.0   SCSK前田         新規作成
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  data_lock_expt            EXCEPTION;        -- レコードロックエラー
  PRAGMA EXCEPTION_INIT(data_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100):= 'XXCFF019A02C'; -- パッケージ名
--
  -- ***アプリケーション短縮名
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5)  := 'XXCFF';
--
  -- ***メッセージ名(本文)
  cv_msg_019a02_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- プロファイル取得エラー
  cv_msg_019a02_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; -- 会計期間チェックエラー
  cv_msg_019a02_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00262'; -- IFRS台帳一括登録作成メッセージ
  cv_msg_019a02_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00263'; -- IFRS台帳一括登録エラー
  cv_msg_019a02_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- 取得対象データ無しメッセージ
  cv_msg_019a02_m_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00268'; -- 資産カテゴリ情報取得エラー
  cv_msg_019a02_m_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; -- ロックエラー
  -- ***メッセージ名(トークン)
  cv_msg_019a02_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50228'; -- XXCFF:台帳種類_固定資産台帳
  cv_msg_019a02_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50314'; -- XXCFF:台帳種類_IFRS台帳
  cv_msg_019a02_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50315'; -- 固定資産台帳情報
  cv_msg_019a02_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50316'; -- IFRS台帳連携セット
  cv_msg_019a02_t_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50318'; -- XXCFF:IFRS償却方法
--
  -- ***トークン名
  cv_tkn_prof         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_asset_number CONSTANT VARCHAR2(20) := 'ASSET_NUMBER';
  cv_tkn_bk_type      CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period       CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_get_data     CONSTANT VARCHAR2(20) := 'GET_DATA';
  cv_tkn_category     CONSTANT VARCHAR2(20) := 'CATEGORY';
  cv_tkn_table_name   CONSTANT VARCHAR2(20) := 'TABLE_NAME';
--
  -- ***プロファイル
  cv_fixed_asset_register   CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER';       -- 台帳種類_固定資産台帳
  cv_fixed_ifrs_asset_regi  CONSTANT VARCHAR2(35) := 'XXCFF1_FIXED_IFRS_ASSET_REGISTER';  -- 台帳種類_IFRS台帳
  cv_cat_deprn_ifrs         CONSTANT VARCHAR2(30) := 'XXCFF1_CAT_DEPRN_IFRS';             -- IFRS償却方法
--
  -- ***ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT'; -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';    -- ログ出力
--
  cv_haifun          CONSTANT VARCHAR2(1)  := '-';      -- -(ハイフン)
  cn_zero_0          CONSTANT NUMBER       := 0;        -- 数値ゼロ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ***バルクフェッチ用定義
  -- IFRS台帳一括登録対象データレコード型
  TYPE g_ifrs_fa_add_rtype IS RECORD(
    description                 fa_additions_tl.description%TYPE,                   -- 摘要
    date_placed_in_service      fa_books.date_placed_in_service%TYPE,               -- 事業供用日
    original_cost               fa_books.original_cost%TYPE,                        -- 当初取得価額
    fixed_assets_units          fa_additions_b.current_units%TYPE,                  -- 単位数量
    location_id                 fa_distribution_history.location_id%TYPE,           -- 事業所フレックスフィールドCCID
    depreciate_flag             fa_books.depreciate_flag%TYPE,                      -- 償却費計上フラグ
    parent_asset_id             fa_additions_b.parent_asset_id%TYPE,                -- 親資産ID
    asset_key_ccid              fa_additions_b.asset_key_ccid%TYPE,                 -- 資産キーCCID
    asset_type                  fa_additions_b.asset_type%TYPE,                     -- 資産タイプ
    attribute1                  fa_additions_b.attribute1%TYPE,                     -- DFF1（更新用事業供用日）
    attribute2                  fa_additions_b.attribute2%TYPE,                     -- DFF2（取得日）
    attribute3                  fa_additions_b.attribute3%TYPE,                     -- DFF3（構造）
    attribute4                  fa_additions_b.attribute4%TYPE,                     -- DFF4（細目）
    attribute5                  fa_additions_b.attribute5%TYPE,                     -- DFF5（圧縮記録・控除方式）
    attribute6                  fa_additions_b.attribute6%TYPE,                     -- DFF6（圧縮控除額）
    attribute7                  fa_additions_b.attribute7%TYPE,                     -- DFF7（圧縮後取得価格）
    attribute8                  fa_additions_b.attribute8%TYPE,                     -- DFF8（資産グループ番号）
    attribute9                  fa_additions_b.attribute9%TYPE,                     -- DFF9（減損計算期間履歴）
    attribute10                 fa_additions_b.attribute10%TYPE,                    -- DFF10（契約明細内部ID）
    attribute11                 fa_additions_b.attribute11%TYPE,                    -- DFF11（リース資産種別）
    attribute12                 fa_additions_b.attribute12%TYPE,                    -- DFF12（開示セグメント）
    attribute13                 fa_additions_b.attribute13%TYPE,                    -- DFF13（面積）
    attribute14                 fa_additions_b.attribute14%TYPE,                    -- DFF14（自販機物件内部ID）
    attribute15                 fa_additions_b.attribute15%TYPE,                    -- DFF15（IFRS耐用年数）
    attribute16                 fa_additions_b.attribute16%TYPE,                    -- DFF16（IFRS償却）
    attribute17                 fa_additions_b.attribute17%TYPE,                    -- DFF17（不動産取得税）
    attribute18                 fa_additions_b.attribute18%TYPE,                    -- DFF18（借入コスト）
    attribute19                 fa_additions_b.attribute19%TYPE,                    -- DFF19（その他）
    attribute20                 fa_additions_b.attribute20%TYPE,                    -- DFF20（IFRS資産科目）
    attribute21                 fa_additions_b.attribute21%TYPE,                    -- DFF21（修正年月日）
    asset_number                fa_additions_b.asset_number%TYPE,                   -- 資産番号
    fc_segment1                 fa_categories.segment1%TYPE,                        -- 資産カテゴリ-種類
    fc_segment2                 fa_categories.segment2%TYPE,                        -- 資産カテゴリ-申告償却
    fc_segment3                 fa_categories.segment3%TYPE,                        -- 資産カテゴリ-資産勘定
    fc_segment4                 fa_categories.segment4%TYPE,                        -- 資産カテゴリ-償却科目
    fc_segment5                 fa_categories.segment5%TYPE,                        -- 資産カテゴリ-耐用年数
    fc_segment7                 fa_categories.segment7%TYPE,                        -- 資産カテゴリ-リース種別
    gcc_segment1                gl_code_combinations.segment1%TYPE,                 -- 会社
    gcc_segment2                gl_code_combinations.segment2%TYPE,                 -- 部門
    gcc_segment4                gl_code_combinations.segment4%TYPE,                 -- 補助科目
    gcc_segment5                gl_code_combinations.segment5%TYPE,                 -- 顧客
    gcc_segment6                gl_code_combinations.segment6%TYPE,                 -- 企業
    gcc_segment7                gl_code_combinations.segment7%TYPE,                 -- 予備１
    gcc_segment8                gl_code_combinations.segment8%TYPE                  -- 予備２
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ***バルクフェッチ用定義
  -- IFRS台帳一括登録対象データレコード配列
  TYPE g_ifrs_fa_add_ttype IS TABLE OF g_ifrs_fa_add_rtype
  INDEX BY BINARY_INTEGER;
--
  g_ifrs_fa_add_tab         g_ifrs_fa_add_ttype;  -- IFRS台帳一括追加対象データ
--
  -- 初期値情報
  g_init_rec  xxcff_common1_pkg.init_rtype;
--
  -- パラメータ会計期間名
  gv_period_name            VARCHAR2(100);
--
  -- 実行日時
  gt_exec_date  xxcff_ifrs_sets.exec_date%TYPE;
--
  -- ***プロファイル値
  gv_fixed_asset_register   VARCHAR2(100);  -- 台帳種類_固定資産台帳
  gv_fixed_ifrs_asset_regi  VARCHAR2(100);  -- 台帳種類_IFRS台帳
  gv_cat_deprn_ifrs         VARCHAR2(100);  -- IFRS償却方法
--
  -- セグメント値配列(EBS標準関数fnd_flex_ext用)
  g_segments_tab  fnd_flex_ext.segmentarray;
--
  -- ***処理件数
  -- IFRS台帳一括追加処理における件数
  gn_ifrs_fa_add_target_cnt NUMBER;     -- 対象件数
  gn_loop_cnt               NUMBER;     -- LOOP数
  gn_ifrs_fa_add_normal_cnt NUMBER;     -- 正常件数
  gn_ifrs_fa_add_err_cnt    NUMBER;     -- エラー件数
--
  /**********************************************************************************
   * Procedure Name   : upd_ifrs_sets
   * Description      : IFRS台帳連携セット更新 (A-6)
   ***********************************************************************************/
  PROCEDURE upd_ifrs_sets(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_ifrs_sets'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
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
    UPDATE xxcff_ifrs_sets  xis       -- IFRS台帳連携セット
    SET    xis.exec_date              = cd_last_update_date         -- 実行日時
          ,xis.last_updated_by        = cn_last_updated_by          -- 最終更新者
          ,xis.last_update_date       = cd_last_update_date         -- 最終更新日
          ,xis.last_update_login      = cn_last_update_login        -- 最終更新ログインID
          ,xis.request_id             = cn_request_id               -- 要求ID
          ,xis.program_application_id = cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
          ,xis.program_id             = cn_program_id               -- コンカレント・プログラムID
          ,xis.program_update_date    = cd_program_update_date      -- プログラム更新日
    WHERE  xis.exec_id                = cv_pkg_name                 -- 処理ID
    ;
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
  END upd_ifrs_sets;
--
  /**********************************************************************************
   * Procedure Name   : get_ifrs_fa_add_data
   * Description      : IFRS台帳登録データ抽出(A-5)
   ***********************************************************************************/
  PROCEDURE get_ifrs_fa_add_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'get_ifrs_fa_add_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    cn_segment_count      CONSTANT NUMBER := 8;                             -- セグメント数
    cv_tran_type_add      CONSTANT VARCHAR2(8)   := 'ADDITION';             -- 取引タイプコード(追加)
    cv_lang               CONSTANT fa_additions_tl.language%TYPE := USERENV( 'LANG' );      -- 言語
    cv_value_zero         CONSTANT VARCHAR2(1)   := '0';                    -- 文字ゼロ
    cv_posting_status     CONSTANT VARCHAR2(4)   := 'POST';                 -- 転記ステータス(POST)
    cv_queue_name         CONSTANT VARCHAR2(4)   := 'POST';                 -- キュー名(POST)
--
    -- *** ローカル変数 ***
    lv_warnmsg            VARCHAR2(5000);                                         -- 警告メッセージ
    lb_ret                BOOLEAN;                                                -- 関数リターンコード
    --
    lt_segment1           fa_categories.segment1%TYPE;                            -- 種類
    lt_segment2           fa_categories.segment2%TYPE;                            -- 申告償却
    lt_segment3           fa_categories.segment3%TYPE;                            -- 資産勘定
    lt_segment4           fa_categories.segment4%TYPE;                            -- 償却科目
    lt_segment5           fa_categories.segment5%TYPE;                            -- 耐用年数
    lt_segment6           fa_categories.segment6%TYPE;                            -- 償却方法
    lt_segment7           fa_categories.segment7%TYPE;                            -- リース種別
    lt_asset_category_id  fa_mass_additions.asset_category_id%TYPE;               -- 資産カテゴリCCID
    lt_deprn_ccid         fa_mass_additions.expense_code_combination_id%TYPE;     -- 減価償却費勘定CCID
    lt_fixed_assets_cost  fa_mass_additions.fixed_assets_cost%TYPE;               -- 取得価額
    lt_payables_cost      fa_mass_additions.payables_cost%TYPE;                   -- 資産当初取得価額
    lv_category           VARCHAR2(216);                                          -- カテゴリ値
    lt_deprn_expense_acct fa_category_books.deprn_expense_acct%TYPE;              -- 減価償却費勘定
--
    -- *** ローカル・カーソル ***
    -- 固定資産台帳カーソル
    CURSOR ifrs_fa_add_cur
    IS
      SELECT  fat.description             AS description              -- 摘要
             ,fb.date_placed_in_service   AS date_placed_in_service   -- 事業供用日
             ,fb.original_cost            AS original_cost            -- 当初取得価額
             ,fab.current_units           AS fixed_assets_units       -- 単位数量
             ,fdh.location_id             AS location_id              -- 事業所フレックスフィールドCCID
             ,fb.depreciate_flag          AS depreciate_flag          -- 償却費計上フラグ
             ,fab.parent_asset_id         AS parent_asset_id          -- 親資産ID
             ,fab.asset_key_ccid          AS asset_key_ccid           -- 資産キーCCID
             ,fab.asset_type              AS asset_type               -- 資産タイプ
             ,fab.attribute1              AS attribute1               -- DFF1（更新用事業供用日）
             ,fab.attribute2              AS attribute2               -- DFF2（取得日）
             ,fab.attribute3              AS attribute3               -- DFF3（構造）
             ,fab.attribute4              AS attribute4               -- DFF4（細目）
             ,fab.attribute5              AS attribute5               -- DFF5（圧縮記録・控除方式）
             ,fab.attribute6              AS attribute6               -- DFF6（圧縮控除額）
             ,fab.attribute7              AS attribute7               -- DFF7（圧縮後取得価格）
             ,fab.attribute8              AS attribute8               -- DFF8（資産グループ番号）
             ,fab.attribute9              AS attribute9               -- DFF9（減損計算期間履歴）
             ,fab.attribute10             AS attribute10              -- DFF10（契約明細内部ID）
             ,fab.attribute11             AS attribute11              -- DFF11（リース資産種別）
             ,fab.attribute12             AS attribute12              -- DFF12（開示セグメント）
             ,fab.attribute13             AS attribute13              -- DFF13（面積）
             ,fab.attribute14             AS attribute14              -- DFF14（自販機物件内部ID）
             ,fab.attribute15             AS attribute15              -- DFF15（IFRS耐用年数）
             ,fab.attribute16             AS attribute16              -- DFF16（IFRS償却）
             ,fab.attribute17             AS attribute17              -- DFF17（不動産取得税）
             ,fab.attribute18             AS attribute18              -- DFF18（借入コスト）
             ,fab.attribute19             AS attribute19              -- DFF19（その他）
             ,fab.attribute20             AS attribute20              -- DFF20（IFRS資産科目）
             ,fab.attribute21             AS attribute21              -- DFF21（修正年月日）
             ,fab.asset_number            AS asset_number             -- 資産番号
             ,fc.segment1                 AS fc_segment1              -- 資産カテゴリ-種類
             ,fc.segment2                 AS fc_segment2              -- 資産カテゴリ-申告償却
             ,fc.segment3                 AS fc_segment3              -- 資産カテゴリ-資産勘定
             ,fc.segment4                 AS fc_segment4              -- 資産カテゴリ-償却科目
             ,fc.segment5                 AS fc_segment5              -- 資産カテゴリ-耐用年数
             ,fc.segment7                 AS fc_segment7              -- 資産カテゴリ-リース種別
             ,gcc.segment1                AS gcc_segment1             -- 会社
             ,gcc.segment2                AS gcc_segment2             -- 部門
             ,gcc.segment4                AS gcc_segment4             -- 補助科目
             ,gcc.segment5                AS gcc_segment5             -- 顧客
             ,gcc.segment6                AS gcc_segment6             -- 企業
             ,gcc.segment7                AS gcc_segment7             -- 予備１
             ,gcc.segment8                AS gcc_segment8             -- 予備２
      FROM    fa_books                  fb        -- 資産台帳情報
             ,fa_additions_b            fab       -- 資産詳細情報
             ,fa_additions_tl           fat       -- 資産摘要情報
             ,fa_distribution_history   fdh       -- 資産割当履歴情報
             ,fa_categories             fc        -- 資産カテゴリ
             ,gl_code_combinations      gcc       -- GL勘定科目
      WHERE   fb.book_type_code             = gv_fixed_asset_register   -- 資産台帳名
      AND     fb.transaction_header_id_in   IN (
                                                SELECT  fth.transaction_header_id   AS trans_header_id  -- 有効取引ヘッダID
                                                FROM    fa_transaction_headers fth
                                                WHERE   fth.transaction_type_code = cv_tran_type_add    -- 取引タイプコード
                                                AND     fth.book_type_code        = fb.book_type_code   -- 資産台帳名
                                                AND     fth.asset_id              = fab.asset_id        -- 資産ID
                                                AND     fth.date_effective        > gt_exec_date
                                               )
      AND     fab.asset_id                  = fat.asset_id
      AND     fat.language                  = cv_lang
      AND     fab.asset_id                  = fdh.asset_id
      AND     fb.book_type_code             = fdh.book_type_code
      AND     fdh.transaction_header_id_out IS NULL
      AND     fab.asset_category_id         = fc.category_id
      AND     fdh.code_combination_id       = gcc.code_combination_id
      AND     NOT EXISTS (
                SELECT 1
                FROM   fa_additions_b  ifrs_fab
                WHERE  ifrs_fab.attribute22 = fab.asset_number
                         )
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
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN ifrs_fa_add_cur;
    -- データの一括取得
    FETCH ifrs_fa_add_cur BULK COLLECT INTO  g_ifrs_fa_add_tab;
    -- カーソルクローズ
    CLOSE ifrs_fa_add_cur;
    -- 対象件数の取得
    gn_ifrs_fa_add_target_cnt := g_ifrs_fa_add_tab.COUNT;
--
    -- 新規登録対象件数が0件の場合
    IF ( gn_ifrs_fa_add_target_cnt = cn_zero_0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_019a02_m_017  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_019a02_t_012) -- 固定資産台帳情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
--
    -- LOOP数初期化
    gn_loop_cnt := 0;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    --==============================================================
    --メインループ処理
    --==============================================================
    <<ifrs_fa_add_loop>>
    FOR ln_loop_cnt IN 1 .. gn_ifrs_fa_add_target_cnt LOOP
--
      -- LOOP数取得
      gn_loop_cnt := ln_loop_cnt;
--
      -- 以下の変数を初期化する
      lt_asset_category_id  := NULL;    -- 資産カテゴリCCID
      lt_deprn_ccid         := NULL;    -- 減価償却費勘定CCID
      lt_fixed_assets_cost  := NULL;    -- 取得価額
      lt_payables_cost      := NULL;    -- 資産当初取得価額
      lv_category           := NULL;    -- カテゴリ値
      lt_deprn_expense_acct := NULL;    -- 減価償却費勘定
--
      -- 共通関数 資産カテゴリチェックのINパラメータ(segment1～7)の値を設定
      lt_segment1 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment1;  -- 種類
      lt_segment2 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment2;  -- 申告償却
      --
      -- 資産勘定
      -- DFF20（IFRS資産科目）に値が設定されている場合
      IF (g_ifrs_fa_add_tab(ln_loop_cnt).attribute20 IS NOT NULL) THEN
        lt_segment3 := g_ifrs_fa_add_tab(ln_loop_cnt).attribute20;  -- DFF20（IFRS資産科目）
      ELSE
        lt_segment3 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment3;  -- 資産カテゴリ-資産勘定
      END IF;
      --
      lt_segment4 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment4;    -- 償却科目
      --
      -- 耐用年数
      -- DFF15（IFRS耐用年数）に値が設定されている場合
      IF (g_ifrs_fa_add_tab(ln_loop_cnt).attribute15 IS NOT NULL) THEN
        lt_segment5 := g_ifrs_fa_add_tab(ln_loop_cnt).attribute15;  -- DFF15（IFRS耐用年数）
      ELSE
        lt_segment5 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment5;  -- 資産カテゴリ-耐用年数
      END IF;
      --
      -- 償却方法
      -- DFF16（IFRS償却）に値が設定されている場合
      IF (g_ifrs_fa_add_tab(ln_loop_cnt).attribute16 IS NOT NULL) THEN
        lt_segment6 := g_ifrs_fa_add_tab(ln_loop_cnt).attribute16;  -- DFF16（IFRS償却）
      ELSE
        lt_segment6 := gv_cat_deprn_ifrs;                           -- IFRS償却方法
      END IF;
      --
      lt_segment7 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment7;    -- リース種別
--
      --==============================================================
      -- 資産カテゴリCCID取得 (A-5-1)
      --==============================================================
      xxcff_common1_pkg.chk_fa_category(
         iv_segment1      => lt_segment1            -- 種類
        ,iv_segment2      => lt_segment2            -- 申告償却
        ,iv_segment3      => lt_segment3            -- 資産勘定
        ,iv_segment4      => lt_segment4            -- 償却科目
        ,iv_segment5      => lt_segment5            -- 耐用年数
        ,iv_segment6      => lt_segment6            -- 償却方法
        ,iv_segment7      => lt_segment7            -- リース種別
        ,on_category_id   => lt_asset_category_id   -- 資産カテゴリCCID
        ,ov_errbuf        => lv_errbuf              -- エラー・メッセージ           --# 固定 #
        ,ov_retcode       => lv_retcode             -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      -- セグメント値配列設定
      g_segments_tab(1) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment1;       -- SEG1:会社
      g_segments_tab(2) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment2;       -- SEG2:部門
      g_segments_tab(4) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment4;       -- SEG4:補助科目
      g_segments_tab(5) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment5;       -- SEG5:顧客
      g_segments_tab(6) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment6;       -- SEG6:企業
      g_segments_tab(7) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment7;       -- SEG7:予備１
      g_segments_tab(8) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment8;       -- SEG8:予備２
      --
      --==============================================================
      -- 資産カテゴリ情報取得 (A-5-2)
      --==============================================================
      BEGIN
        SELECT  fcb.deprn_expense_acct  AS deprn_expense_acct
        INTO    lt_deprn_expense_acct
        FROM    fa_category_books  fcb
        WHERE   fcb.category_id    = lt_asset_category_id         -- カテゴリID
        AND     fcb.book_type_code = gv_fixed_ifrs_asset_regi     -- 資産台帳名
        ;
      EXCEPTION
        -- 資産カテゴリ台帳マスタの取得件数がゼロ件の場合
        WHEN NO_DATA_FOUND THEN
          -- 資産カテゴリ値設定
          lv_category := lt_segment1 || cv_haifun || lt_segment2 || cv_haifun ||
                         lt_segment3 || cv_haifun || lt_segment4 || cv_haifun ||
                         lt_segment5 || cv_haifun || lt_segment6 || cv_haifun || lt_segment7;
          --
          -- エラーメッセージをセット
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff             -- XXCFF
                                                        ,cv_msg_019a02_m_018        -- 資産カテゴリ情報取得エラー
                                                        ,cv_tkn_category            -- トークン'CATEGORY'
                                                        ,lv_category                -- カテゴリ組み合わせ
                                                        ,cv_tkn_bk_type             -- トークン'BOOK_TYPE_CODE'
                                                        ,gv_fixed_ifrs_asset_regi)  -- 資産台帳名
                                                        ,1
                                                        ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
      g_segments_tab(3) := lt_deprn_expense_acct;       -- SEG3:勘定科目
--
      --==============================================================
      -- 減価償却費勘定CCID取得(A-5-3)
      --==============================================================
      -- CCID取得関数呼び出し
      lb_ret := fnd_flex_ext.get_combination_id(
                   application_short_name  => g_init_rec.gl_application_short_name -- アプリケーション短縮名(GL)
                  ,key_flex_code           => g_init_rec.id_flex_code              -- キーフレックスコード
                  ,structure_number        => g_init_rec.chart_of_accounts_id      -- 勘定科目体系番号
                  ,validation_date         => g_init_rec.process_date              -- 日付チェック
                  ,n_segments              => cn_segment_count                     -- セグメント数
                  ,segments                => g_segments_tab                       -- セグメント値配列
                  ,combination_id          => lt_deprn_ccid                        -- CCID(減価償却費勘定CCID)
                  );
      IF NOT lb_ret THEN
        lv_errmsg := fnd_flex_ext.get_message;
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- 登録用項目値設定
      lt_fixed_assets_cost := NVL(g_ifrs_fa_add_tab(ln_loop_cnt).original_cost, cn_zero_0) + 
                              TO_NUMBER(NVL(g_ifrs_fa_add_tab(ln_loop_cnt).attribute17, cv_value_zero)) + 
                              TO_NUMBER(NVL(g_ifrs_fa_add_tab(ln_loop_cnt).attribute18, cv_value_zero)) + 
                              TO_NUMBER(NVL(g_ifrs_fa_add_tab(ln_loop_cnt).attribute19, cv_value_zero));  -- 取得価額
      lt_payables_cost := lt_fixed_assets_cost;                                                   -- 資産当初取得価額
--
      --==============================================================
      -- 追加OIF登録 (A-5-4)
      --==============================================================
      INSERT INTO fa_mass_additions(
         mass_addition_id               -- 追加OIF内部ID
        ,asset_number                   -- 資産番号
        ,description                    -- 摘要
        ,asset_category_id              -- 資産カテゴリCCID
        ,book_type_code                 -- 台帳
        ,date_placed_in_service         -- 事業供用日
        ,fixed_assets_cost              -- 取得価額
        ,payables_units                 -- AP数量
        ,fixed_assets_units             -- 単位数量
        ,expense_code_combination_id    -- 減価償却費勘定CCID
        ,location_id                    -- 事業所フレックスフィールドCCID
        ,last_update_date               -- 最終更新日
        ,last_updated_by                -- 最終更新者
        ,posting_status                 -- 転記ステータス
        ,queue_name                     -- キュー名
        ,payables_cost                  -- 資産当初取得価額
        ,depreciate_flag                -- 償却費計上フラグ
        ,parent_asset_id                -- 親資産ID
        ,asset_key_ccid                 -- 資産キーCCID
        ,asset_type                     -- 資産タイプ
        ,created_by                     -- 作成者ID
        ,creation_date                  -- 作成日
        ,last_update_login              -- 最終更新ログインID
        ,attribute1                     -- DFF1（更新用事業供用日）
        ,attribute2                     -- DFF2（取得日）
        ,attribute3                     -- DFF3（構造）
        ,attribute4                     -- DFF4（細目）
        ,attribute5                     -- DFF5（圧縮記録・控除方式）
        ,attribute6                     -- DFF6（圧縮控除額）
        ,attribute7                     -- DFF7（圧縮後取得価格）
        ,attribute8                     -- DFF8（資産グループ番号）
        ,attribute9                     -- DFF9（減損計算期間履歴）
        ,attribute10                    -- DFF10（契約明細内部ID）
        ,attribute11                    -- DFF11（リース資産種別）
        ,attribute12                    -- DFF12（開示セグメント）
        ,attribute13                    -- DFF13（面積）
        ,attribute14                    -- DFF14（自販機物件内部ID）
        ,attribute15                    -- DFF15（IFRS耐用年数）
        ,attribute16                    -- DFF16（IFRS償却）
        ,attribute17                    -- DFF17（不動産取得税）
        ,attribute18                    -- DFF18（借入コスト）
        ,attribute19                    -- DFF19（その他）
        ,attribute20                    -- DFF20（IFRS資産科目）
        ,attribute21                    -- DFF21（修正年月日）
        ,attribute22                    -- DFF22（固定資産資産番号）
      ) VALUES (
         fa_mass_additions_s.NEXTVAL                                -- 追加OIF内部ID
        ,NULL                                                       -- 資産番号
        ,g_ifrs_fa_add_tab(ln_loop_cnt).description                 -- 摘要
        ,lt_asset_category_id                                       -- 資産カテゴリCCID
        ,gv_fixed_ifrs_asset_regi                                   -- 台帳
        ,g_ifrs_fa_add_tab(ln_loop_cnt).date_placed_in_service      -- 事業供用日
        ,lt_fixed_assets_cost                                       -- 取得価額
        ,g_ifrs_fa_add_tab(ln_loop_cnt).fixed_assets_units          -- AP数量
        ,g_ifrs_fa_add_tab(ln_loop_cnt).fixed_assets_units          -- 単位数量
        ,lt_deprn_ccid                                              -- 減価償却費勘定CCID
        ,g_ifrs_fa_add_tab(ln_loop_cnt).location_id                 -- 事業所フレックスフィールドCCID
        ,cd_last_update_date                                        -- 最終更新日
        ,cn_last_updated_by                                         -- 最終更新者
        ,cv_posting_status                                          -- 転記ステータス
        ,cv_queue_name                                              -- キュー名
        ,lt_payables_cost                                           -- 資産当初取得価額
        ,g_ifrs_fa_add_tab(ln_loop_cnt).depreciate_flag             -- 償却費計上フラグ
        ,g_ifrs_fa_add_tab(ln_loop_cnt).parent_asset_id             -- 親資産ID
        ,g_ifrs_fa_add_tab(ln_loop_cnt).asset_key_ccid              -- 資産キーCCID
        ,g_ifrs_fa_add_tab(ln_loop_cnt).asset_type                  -- 資産タイプ
        ,cn_created_by                                              -- 作成者ID
        ,cd_creation_date                                           -- 作成日
        ,cn_last_update_login                                       -- 最終更新ログインID
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute1                  -- DFF1（更新用事業供用日）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute2                  -- DFF2（取得日）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute3                  -- DFF3（構造）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute4                  -- DFF4（細目）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute5                  -- DFF5（圧縮記録・控除方式
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute6                  -- DFF6（圧縮控除額）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute7                  -- DFF7（圧縮後取得価格）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute8                  -- DFF8（資産グループ番号）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute9                  -- DFF9（減損計算期間履歴）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute10                 -- DFF10（契約明細内部ID）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute11                 -- DFF11（リース資産種別）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute12                 -- DFF12（開示セグメント） 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute13                 -- DFF13（面積） 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute14                 -- DFF14（自販機物件内部ID）
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute15                 -- DFF15（IFRS耐用年数） 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute16                 -- DFF16（IFRS償却） 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute17                 -- DFF17（不動産取得税） 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute18                 -- DFF18（借入コスト） 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute19                 -- DFF19（その他） 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute20                 -- DFF20（IFRS資産科目） 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute21                 -- DFF21（修正年月日） 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).asset_number                -- DFF22（固定資産資産番号）
      );
--
      -- IFRS台帳一括追加正常件数カウント
      gn_ifrs_fa_add_normal_cnt := gn_ifrs_fa_add_normal_cnt + 1;
--
    END LOOP ifrs_fa_add_loop;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (ifrs_fa_add_cur%ISOPEN) THEN
        CLOSE ifrs_fa_add_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (ifrs_fa_add_cur%ISOPEN) THEN
        CLOSE ifrs_fa_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (ifrs_fa_add_cur%ISOPEN) THEN
        CLOSE ifrs_fa_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ifrs_fa_add_data;
--
  /**********************************************************************************
   * Procedure Name   : get_exec_date
   * Description      : 実行日時取得 (A-4)
   ***********************************************************************************/
  PROCEDURE get_exec_date(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exec_date'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
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
    BEGIN
      SELECT  xis.exec_date AS exec_date  -- 実行日時
      INTO    gt_exec_date
      FROM    xxcff_ifrs_sets  xis        -- IFRS台帳連携セット
      WHERE   xis.exec_id = cv_pkg_name
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_019a02_m_017  -- 取得対象データ無し
                                                      ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                      ,cv_msg_019a02_t_013) -- IFRS台帳連携セット
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        --
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_error;
      --
      WHEN data_lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_019a02_m_019  -- ロックエラー
                                                      ,cv_tkn_table_name    -- トークン'TABLE_NAME'
                                                      ,cv_msg_019a02_t_013) -- IFRS台帳連携セット
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        --
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_error;
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
  END get_exec_date;
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
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_yes                CONSTANT VARCHAR2(1) := 'Y';
--
    -- *** ローカル変数 ***
    lt_deprn_run          fa_deprn_periods.deprn_run%TYPE := NULL;  -- 減価償却実行フラグ
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
    BEGIN
      -- 会計期間チェック
      SELECT  fdp.deprn_run        AS deprn_run   -- 減価償却実行フラグ
      INTO    lt_deprn_run
      FROM    fa_deprn_periods  fdp               -- 減価償却期間
      WHERE   fdp.book_type_code    = gv_fixed_ifrs_asset_regi
      AND     fdp.period_name       = gv_period_name
      AND     fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- 会計期間の取得件数がゼロ件の場合
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- 減価償却が実行されている場合
    IF lt_deprn_run = cv_yes THEN
      RAISE chk_period_expt;
    END IF;
--
  EXCEPTION
    -- *** 会計期間チェックエラーハンドラ ***
    WHEN chk_period_expt THEN
      -- エラーメッセージをセット
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff            -- XXCFF
                                                    ,cv_msg_019a02_m_011       -- 会計期間チェックエラー
                                                    ,cv_tkn_bk_type            -- トークン'BOOK_TYPE_CODE'
                                                    ,gv_fixed_ifrs_asset_regi  -- 資産台帳名
                                                    ,cv_tkn_period             -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)           -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      --
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errmsg := lv_errmsg;
      -- 終了ステータスはエラーとする
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
    -- XXCFF:台帳種類_固定資産台帳
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a02_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_019a02_t_010) -- XXCFF:台帳種類_固定資産台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:台帳種類_IFRS台帳
    gv_fixed_ifrs_asset_regi := FND_PROFILE.VALUE(cv_fixed_ifrs_asset_regi);
    IF (gv_fixed_ifrs_asset_regi IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a02_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_019a02_t_011) -- XXCFF:台帳種類_IFRS台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:IFRS償却方法
    gv_cat_deprn_ifrs := FND_PROFILE.VALUE(cv_cat_deprn_ifrs);
    IF (gv_cat_deprn_ifrs IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a02_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_019a02_t_014) -- XXCFF:IFRS償却方法
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';      -- プログラム名
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 実行日時取得 (A-4)
    -- =========================================
    get_exec_date(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- IFRS台帳登録データ抽出 (A-5)
    -- =========================================
    get_ifrs_fa_add_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- IFRS台帳連携セット更新(A-6)
    -- =========================================
    upd_ifrs_sets(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
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
    iv_period_name IN  VARCHAR2       --   1.会計期間名
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
--
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
    -- グローバル変数の初期化
    gn_ifrs_fa_add_target_cnt := 0;
    gn_ifrs_fa_add_normal_cnt := 0;
    gn_ifrs_fa_add_err_cnt    := 0;
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
  /**********************************************************************************
   * Description      : 終了処理(A-7)
   ***********************************************************************************/
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- 正常件数を0に設定
      gn_ifrs_fa_add_normal_cnt := cn_zero_0;
      -- エラー件数を+1更新
      gn_ifrs_fa_add_err_cnt := gn_ifrs_fa_add_err_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 対象件数がカウントされている場合
      IF ( gn_ifrs_fa_add_target_cnt > 0 ) THEN
        -- IFRS台帳一括登録エラーの固定資産台帳情報を出力する
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- XXCFF
                                                       ,cv_msg_019a02_m_014    -- IFRS台帳一括登録エラー
                                                       ,cv_tkn_asset_number    -- トークン'ASSET_NUMBER'
                                                       ,g_ifrs_fa_add_tab(gn_loop_cnt).asset_number)
                                                                               -- 資産番号
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
    -- 対象件数が0件だった場合
    ELSIF ( gn_ifrs_fa_add_target_cnt = cn_zero_0 ) THEN
      -- ステータスを警告にする
      lv_retcode := cv_status_warn;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --IFRS台帳一括登録処理における件数出力
    --===============================================================
    --IFRS台帳作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_019a02_m_013
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
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_add_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_add_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_add_err_cnt)
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
END XXCFF019A02C;
/
