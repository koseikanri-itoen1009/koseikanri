CREATE OR REPLACE PACKAGE BODY XXCFF019A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A03C(body)
 * Description      : IFRS台帳振替
 * MD.050           : MD050_CFF_019_A03_IFRS台帳振替
 * Version          : 1.0
 *
 * Program List
 * ----------------------------- ----------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ----------------------------------------------------------
 *  init                          初期処理                                  (A-1)
 *  get_profile_values            プロファイル値取得                        (A-2)
 *  chk_period                    会計期間チェック                          (A-3)
 *  get_ifrs_fa_trans_data        IFRS台帳振替データ抽出                    (A-5)
 *  submain                       メイン処理プロシージャ
 *  main                          コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/09/15    1.0   SCSK前田         新規作成
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
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
  cv_pkg_name         CONSTANT VARCHAR2(100):= 'XXCFF019A03C'; -- パッケージ名
  --
  -- ***アプリケーション短縮名
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5)  := 'XXCFF';
  --
  -- ***メッセージ名(本文)
  cv_msg_019a03_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- プロファイル取得エラー
  cv_msg_019a03_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; -- 会計期間チェックエラー
  cv_msg_019a03_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00272'; -- 振替作成メッセージ
  cv_msg_019a03_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00273'; -- IFRS台帳振替登録エラー
  cv_msg_019a03_m_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- 取得対象データ無しメッセージ
  cv_msg_019a03_m_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; -- ロックエラー
  cv_msg_019a03_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00277'; -- IFRS台帳振替スキップメッセージ
  --
  -- ***メッセージ名(トークン)
  cv_msg_019a03_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50228'; -- XXCFF:台帳種類_固定資産台帳
  cv_msg_019a03_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50314'; -- XXCFF:台帳種類_IFRS台帳
  cv_msg_019a03_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50316'; -- IFRS台帳連携セット
  cv_msg_019a03_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50322'; -- 資産台帳情報
  --
  -- ***トークン名
  cv_tkn_prof           CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type        CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period         CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_get_data       CONSTANT VARCHAR2(20) := 'GET_DATA';
  cv_tkn_table_name     CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_asset_number1  CONSTANT VARCHAR2(20) := 'ASSET_NUMBER1';
  cv_tkn_asset_number2  CONSTANT VARCHAR2(20) := 'ASSET_NUMBER2';
  --
  -- ***プロファイル
  cv_fixed_asset_register   CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER';       -- 台帳種類_固定資産台帳
  cv_fixed_ifrs_asset_regi  CONSTANT VARCHAR2(35) := 'XXCFF1_FIXED_IFRS_ASSET_REGISTER';  -- 台帳種類_IFRS台帳
  --
  -- ***ファイル出力
  cv_file_type_out    CONSTANT VARCHAR2(10) := 'OUTPUT'; -- メッセージ出力
  cv_file_type_log    CONSTANT VARCHAR2(10) := 'LOG';    -- ログ出力
  --
  cv_haifun           CONSTANT VARCHAR2(1)  := '-';      -- -(ハイフン)
  cn_zero             CONSTANT NUMBER       := 0;        -- 数値ゼロ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ***バルクフェッチ用定義
  -- IFRS台帳振替対象データレコード型
  TYPE g_ifrs_fa_trans_rtype IS RECORD(
    asset_number                fa_additions_b.asset_number%TYPE,                     -- 資産番号
    transaction_date_entered    fa_transaction_headers.transaction_date_entered%TYPE, -- 振替日
    current_units               fa_additions_b.current_units%TYPE,                    -- 単位数量
    gcc_segment1                gl_code_combinations.segment1%TYPE,                   -- 減価償却費_会社
    gcc_segment2                gl_code_combinations.segment2%TYPE,                   -- 減価償却費_部門
    gcc_segment5                gl_code_combinations.segment5%TYPE,                   -- 減価償却費_顧客
    location_id                 fa_distribution_history.location_id%TYPE,             -- ロケーションID
    fl_segment1                 fa_locations.segment1%TYPE,                           -- 事業所_申告地
    fl_segment2                 fa_locations.segment2%TYPE,                           -- 事業所_管理部門
    fl_segment3                 fa_locations.segment3%TYPE,                           -- 事業所_事業所
    fl_segment4                 fa_locations.segment4%TYPE,                           -- 事業所_場所
    fl_segment5                 fa_locations.segment5%TYPE,                           -- 事業所_本社/工場区分
    ifrs_asset_number           fa_additions_b.asset_number%TYPE,                     -- IFRS_資産番号
    ifrs_gcc_segment1           gl_code_combinations.segment1%TYPE,                   -- IFRS_減価償却費_会社
    ifrs_gcc_segment2           gl_code_combinations.segment2%TYPE,                   -- IFRS_減価償却費_部門
    ifrs_gcc_segment3           gl_code_combinations.segment3%TYPE,                   -- IFRS_減価償却費_管理科目
    ifrs_gcc_segment4           gl_code_combinations.segment4%TYPE,                   -- IFRS_減価償却費_補助科目
    ifrs_gcc_segment5           gl_code_combinations.segment5%TYPE,                   -- IFRS_減価償却費_顧客
    ifrs_gcc_segment6           gl_code_combinations.segment6%TYPE,                   -- IFRS_減価償却費_企業
    ifrs_gcc_segment7           gl_code_combinations.segment7%TYPE,                   -- IFRS_減価償却費_予備1
    ifrs_gcc_segment8           gl_code_combinations.segment8%TYPE,                   -- IFRS_減価償却費_予備2
    ifrs_location_id            fa_distribution_history.location_id%TYPE              -- IFRS_ロケーションID
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ***バルクフェッチ用定義
  -- IFRS台帳振替対象データレコード配列
  TYPE g_ifrs_fa_trans_ttype IS TABLE OF g_ifrs_fa_trans_rtype
  INDEX BY BINARY_INTEGER;
--
  g_ifrs_fa_trans_tab         g_ifrs_fa_trans_ttype;  -- IFRS台帳振替対象データ
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
--
  -- セグメント値配列(EBS標準関数fnd_flex_ext用)
  g_segments_tab  fnd_flex_ext.segmentarray;
--
  -- ***処理件数
  -- IFRS台帳振替処理における件数
  gn_ifrs_fa_trans_target_cnt NUMBER;     -- 対象件数
  gn_loop_cnt                 NUMBER;     -- LOOP数
  gn_ifrs_fa_trans_normal_cnt NUMBER;     -- 正常件数
  gn_ifrs_fa_trans_err_cnt    NUMBER;     -- エラー件数
  gn_skip_cnt                 NUMBER;     -- SKIP数
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
   * Procedure Name   : get_ifrs_fa_trans_data
   * Description      : IFRS台帳振替データ抽出(A-5)
   ***********************************************************************************/
  PROCEDURE get_ifrs_fa_trans_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_ifrs_fa_trans_data'; -- プログラム名
    cv_flg_yes              CONSTANT VARCHAR2(1)   := 'Y';                      -- フラグYes
    cv_flg_no               CONSTANT VARCHAR2(1)   := 'N';                      -- フラグNo
    cv_pending              CONSTANT VARCHAR2(7)   := 'PENDING';                -- ステータス(PENDING)
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
    cn_segment_count CONSTANT NUMBER := 8; -- セグメント数
--
    -- *** ローカル変数 ***
    lv_warnmsg            VARCHAR2(5000);                           -- 警告メッセージ
    lb_ret                BOOLEAN;                                  -- 関数リターンコード
    --
    lv_ins_flg            VARCHAR2(1);                              -- 登録フラグ
    lt_ifrs_gcc_segment1  gl_code_combinations.segment1%TYPE;       -- IFRS_減価償却費_会社
    lt_ifrs_gcc_segment2  gl_code_combinations.segment2%TYPE;       -- IFRS_減価償却費_部門
    lt_ifrs_gcc_segment3  gl_code_combinations.segment3%TYPE;       -- IFRS_減価償却費_管理科目
    lt_ifrs_gcc_segment4  gl_code_combinations.segment4%TYPE;       -- IFRS_減価償却費_補助科目
    lt_ifrs_gcc_segment5  gl_code_combinations.segment5%TYPE;       -- IFRS_減価償却費_顧客
    lt_ifrs_gcc_segment6  gl_code_combinations.segment6%TYPE;       -- IFRS_減価償却費_企業
    lt_ifrs_gcc_segment7  gl_code_combinations.segment7%TYPE;       -- IFRS_減価償却費_予備１
    lt_ifrs_gcc_segment8  gl_code_combinations.segment8%TYPE;       -- IFRS_減価償却費_予備２
    lt_ifrs_fl_segment1   fa_locations.segment1%TYPE;               -- IFRS_事業所_申告地
    lt_ifrs_fl_segment2   fa_locations.segment2%TYPE;               -- IFRS_事業所_管理部門
    lt_ifrs_fl_segment3   fa_locations.segment3%TYPE;               -- IFRS_事業所_事業所
    lt_ifrs_fl_segment4   fa_locations.segment4%TYPE;               -- IFRS_事業所_場所
    lt_ifrs_fl_segment5   fa_locations.segment5%TYPE;               -- IFRS_事業所_本社/工場区分
    --
    lt_deprn_ccid         fa_mass_additions.expense_code_combination_id%TYPE;     -- 減価償却費勘定CCID
    lt_deprn_expense_acct fa_category_books.deprn_expense_acct%TYPE;              -- 減価償却費勘定
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 固定資産台帳カーソル
    CURSOR ifrs_fa_trans_cur
    IS
      SELECT  fab.asset_number              AS asset_number               -- 資産番号
             ,fth.transaction_date_entered  AS transaction_date_entered   -- 振替日
             ,fab.current_units             AS current_units              -- 単位数量
             ,gcc.segment1                  AS gcc_segment1               -- 減価償却費_会社
             ,gcc.segment2                  AS gcc_segment2               -- 減価償却費_部門
             ,gcc.segment5                  AS gcc_segment5               -- 減価償却費_顧客
             ,fdh.location_id               AS location_id                -- ロケーションID
             ,fl.segment1                   AS fl_segment1                -- 事業所_申告地
             ,fl.segment2                   AS fl_segment2                -- 事業所_管理部門
             ,fl.segment3                   AS fl_segment3                -- 事業所_事業所
             ,fl.segment4                   AS fl_segment4                -- 事業所_場所
             ,fl.segment5                   AS fl_segment5                -- 事業所_本社/工場区分
             ,ifrs_d.ifrs_asset_number      AS ifrs_asset_number          -- IFRS_資産番号
             ,ifrs_d.ifrs_gcc_segment1      AS ifrs_gcc_segment1          -- IFRS_減価償却費_会社
             ,ifrs_d.ifrs_gcc_segment2      AS ifrs_gcc_segment2          -- IFRS_減価償却費_部門
             ,ifrs_d.ifrs_gcc_segment3      AS ifrs_gcc_segment3          -- IFRS_減価償却費_管理科目
             ,ifrs_d.ifrs_gcc_segment4      AS ifrs_gcc_segment4          -- IFRS_減価償却費_補助科目
             ,ifrs_d.ifrs_gcc_segment5      AS ifrs_gcc_segment5          -- IFRS_減価償却費_顧客
             ,ifrs_d.ifrs_gcc_segment6      AS ifrs_gcc_segment6          -- IFRS_減価償却費_企業
             ,ifrs_d.ifrs_gcc_segment7      AS ifrs_gcc_segment7          -- IFRS_減価償却費_予備1
             ,ifrs_d.ifrs_gcc_segment8      AS ifrs_gcc_segment8          -- IFRS_減価償却費_予備2
             ,ifrs_d.ifrs_location_id       AS ifrs_location_id           -- IFRS_ロケーションID
      FROM    fa_distribution_history   fdh   -- 資産割当履歴情報
             ,fa_additions_b            fab   -- 資産詳細情報
             ,fa_transaction_headers    fth   -- 資産取引ヘッダ
             ,gl_code_combinations      gcc   -- GL勘定科目
             ,fa_locations              fl    -- 事業所マスタ
             ,(SELECT  fab2.attribute22     AS attribute22            -- IFRS_DFF22(固定資産資産番号)
                      ,fab2.asset_number    AS ifrs_asset_number      -- IFRS_資産番号
                      ,gcc2.segment1        AS ifrs_gcc_segment1      -- IFRS_減価償却費_会社
                      ,gcc2.segment2        AS ifrs_gcc_segment2      -- IFRS_減価償却費_部門
                      ,gcc2.segment3        AS ifrs_gcc_segment3      -- IFRS_減価償却費_管理科目
                      ,gcc2.segment4        AS ifrs_gcc_segment4      -- IFRS_減価償却費_補助科目
                      ,gcc2.segment5        AS ifrs_gcc_segment5      -- IFRS_減価償却費_顧客
                      ,gcc2.segment6        AS ifrs_gcc_segment6      -- IFRS_減価償却費_企業
                      ,gcc2.segment7        AS ifrs_gcc_segment7      -- IFRS_減価償却費_予備1
                      ,gcc2.segment8        AS ifrs_gcc_segment8      -- IFRS_減価償却費_予備2
                      ,fdh2.location_id     AS ifrs_location_id       -- IFRS_ロケーションID
               FROM    fa_distribution_history   fdh2   -- 資産割当履歴情報
                      ,fa_additions_b            fab2   -- 資産詳細情報
                      ,gl_code_combinations      gcc2   -- GL勘定科目
               WHERE   1 = 1  
               AND     fdh2.book_type_code            = gv_fixed_ifrs_asset_regi
               AND     fdh2.transaction_header_id_out IS NULL
               AND     fdh2.asset_id                  = fab2.asset_id
               AND     fdh2.code_combination_id       = gcc2.code_combination_id
              ) ifrs_d
      WHERE   1 = 1
      AND     fdh.book_type_code            = gv_fixed_asset_register   -- 資産台帳名
      AND     fdh.transaction_header_id_out IS NULL
      AND     fdh.date_effective            > gt_exec_date
      AND     fdh.asset_id                  = fab.asset_id              -- 資産ID
      AND     fdh.code_combination_id       = gcc.code_combination_id   -- 勘定科目CCID
      AND     fdh.location_id               = fl.location_id            -- ロケーションID
      AND     fdh.transaction_header_id_in  = fth.transaction_header_id 
      AND    (SELECT COUNT(fdh3.distribution_id)
              FROM   fa_distribution_history fdh3
              WHERE  fdh3.book_type_code = fdh.book_type_code
              AND    fdh3.asset_id       = fdh.asset_id ) >= 2
      AND     ifrs_d.attribute22 = fab.asset_number
      ;
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
    OPEN ifrs_fa_trans_cur;
    -- データの一括取得
    FETCH ifrs_fa_trans_cur BULK COLLECT INTO  g_ifrs_fa_trans_tab;
    -- カーソルクローズ
    CLOSE ifrs_fa_trans_cur;
    -- 対象件数の取得
    gn_ifrs_fa_trans_target_cnt := g_ifrs_fa_trans_tab.COUNT;
--
    -- 振替対象件数が0件の場合
    IF ( gn_ifrs_fa_trans_target_cnt = cn_zero ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_019a03_m_015  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_019a03_t_013) -- 資産台帳情報
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
    -- LOOP数、正常件数、スキップ件数初期化
    gn_loop_cnt := 0;
    gn_ifrs_fa_trans_normal_cnt := 0;
    gn_skip_cnt := 0;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    --==============================================================
    --メインループ処理
    --==============================================================
    <<ifrs_fa_add_loop>>
    FOR ln_loop_cnt IN 1 .. gn_ifrs_fa_trans_target_cnt LOOP
--
      -- LOOP数取得
      gn_loop_cnt := ln_loop_cnt;
--
      -- 以下の変数を初期化する
      lv_ins_flg            := cv_flg_no;   -- 登録フラグ
      lt_ifrs_gcc_segment1  := NULL;        -- 減価償却費_会社
      lt_ifrs_gcc_segment2  := NULL;        -- 減価償却費_部門
      lt_ifrs_gcc_segment3  := NULL;        -- 減価償却費_管理科目
      lt_ifrs_gcc_segment4  := NULL;        -- 減価償却費_補助科目
      lt_ifrs_gcc_segment5  := NULL;        -- 減価償却費_顧客
      lt_ifrs_gcc_segment6  := NULL;        -- 減価償却費_企業
      lt_ifrs_gcc_segment7  := NULL;        -- 減価償却費_予備１
      lt_ifrs_gcc_segment8  := NULL;        -- 減価償却費_予備２
      --
      lt_ifrs_fl_segment1   := NULL;        -- 事業所_申告地
      lt_ifrs_fl_segment2   := NULL;        -- 事業所_管理部門
      lt_ifrs_fl_segment3   := NULL;        -- 事業所_事業所
      lt_ifrs_fl_segment4   := NULL;        -- 事業所_場所
      lt_ifrs_fl_segment5   := NULL;        -- 事業所_本社/工場区分
--
      --==============================================================
      -- 減価償却勘定情報 (会社、部門、顧客)、事業所情報チェック(A-5-1)
      --==============================================================
      -- 事業所情報
      IF (g_ifrs_fa_trans_tab(ln_loop_cnt).location_id <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_location_id) THEN
        lv_ins_flg := cv_flg_yes;   -- 登録フラグ = Y
      END IF;
      lt_ifrs_fl_segment1 := g_ifrs_fa_trans_tab(ln_loop_cnt).fl_segment1;          -- IFRS_事業所_申告地
      lt_ifrs_fl_segment2 := g_ifrs_fa_trans_tab(ln_loop_cnt).fl_segment2;          -- IFRS_事業所_管理部門
      lt_ifrs_fl_segment3 := g_ifrs_fa_trans_tab(ln_loop_cnt).fl_segment3;          -- IFRS_事業所_事業所
      lt_ifrs_fl_segment4 := g_ifrs_fa_trans_tab(ln_loop_cnt).fl_segment4;          -- IFRS_事業所_場所
      lt_ifrs_fl_segment5 := g_ifrs_fa_trans_tab(ln_loop_cnt).fl_segment5;          -- IFRS_事業所_本社/工場区分
      --
      -- 減価償却費_会社、部門
      IF ( (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment1 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment1) OR
           (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment2 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment2) OR
           (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment5 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment5) ) THEN
        lv_ins_flg := cv_flg_yes;   -- 登録フラグ = Y
        --
        IF (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment1 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment1) THEN
          g_segments_tab(1) := g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment1;        -- SEG1:会社
        ELSE
          g_segments_tab(1) := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment1;   -- SEG1:会社
        END IF;
        --
        IF (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment2 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment2) THEN
          g_segments_tab(2) := g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment2;        -- SEG2:部門
        ELSE
          g_segments_tab(2) := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment2;   -- SEG2:部門
        END IF;
        --
        g_segments_tab(3)   := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment3;   -- SEG3:管理科目
        g_segments_tab(4)   := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment4;   -- SEG4:補助科目
        --
        IF (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment5 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment5) THEN
          g_segments_tab(5) := g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment5;        -- SEG5:顧客
        ELSE
          g_segments_tab(5) := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment5;   -- SEG5:顧客
        END IF;
        --
        g_segments_tab(6)   := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment6;   -- SEG6:企業
        g_segments_tab(7)   := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment7;   -- SEG7:予備１
        g_segments_tab(8)   := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment8;   -- SEG8:予備２
        --
        --==============================================================
        -- 減価償却費勘定CCID取得(A-5-2)
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
        lt_ifrs_gcc_segment1 := g_segments_tab(1);      -- 減価償却費_会社
        lt_ifrs_gcc_segment2 := g_segments_tab(2);      -- 減価償却費_部門
        lt_ifrs_gcc_segment3 := g_segments_tab(3);      -- 減価償却費_管理科目
        lt_ifrs_gcc_segment4 := g_segments_tab(4);      -- 減価償却費_補助科目
        lt_ifrs_gcc_segment5 := g_segments_tab(5);      -- 減価償却費_顧客
        lt_ifrs_gcc_segment6 := g_segments_tab(6);      -- 減価償却費_企業
        lt_ifrs_gcc_segment7 := g_segments_tab(7);      -- 減価償却費_予備１
        lt_ifrs_gcc_segment8 := g_segments_tab(8);      -- 減価償却費_予備２
      ELSE
        lt_ifrs_gcc_segment1 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment1;      -- 減価償却費_会社
        lt_ifrs_gcc_segment2 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment2;      -- 減価償却費_部門
        lt_ifrs_gcc_segment3 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment3;      -- 減価償却費_管理科目
        lt_ifrs_gcc_segment4 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment4;      -- 減価償却費_補助科目
        lt_ifrs_gcc_segment5 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment5;      -- 減価償却費_顧客
        lt_ifrs_gcc_segment6 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment6;      -- 減価償却費_企業
        lt_ifrs_gcc_segment7 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment7;      -- 減価償却費_予備１
        lt_ifrs_gcc_segment8 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment8;      -- 減価償却費_予備２
      END IF;
      --
      IF (lv_ins_flg = cv_flg_yes) THEN   -- 登録フラグ = Y
        --==============================================================
        -- 振替OIF登録 (A-5-3)
        --==============================================================
        INSERT INTO xx01_transfer_oif(
           transfer_oif_id                -- 振替OIF内部ID
          ,book_type_code                 -- 台帳
          ,asset_number                   -- 資産番号
          ,created_by                     -- 作成者ID
          ,creation_date                  -- 作成日
          ,last_updated_by                -- 最終更新者
          ,last_update_date               -- 最終更新日
          ,last_update_login              -- 最終更新ログインID
          ,request_id                     -- リクエストID
          ,program_application_id         -- アプリケーションID
          ,program_id                     -- プログラムID
          ,program_update_date            -- プログラム最終更新日
          ,transaction_date_entered       -- 振替日
          ,transaction_units              -- 単位変更
          ,posting_flag                   -- 転記チェックフラグ
          ,status                         -- ステータス
          ,segment1                       -- 減価償却費勘定セグメント1
          ,segment2                       -- 減価償却費勘定セグメント2
          ,segment3                       -- 減価償却費勘定セグメント3
          ,segment4                       -- 減価償却費勘定セグメント4
          ,segment5                       -- 減価償却費勘定セグメント5
          ,segment6                       -- 減価償却費勘定セグメント6
          ,segment7                       -- 減価償却費勘定セグメント7
          ,segment8                       -- 減価償却費勘定セグメント8
          ,loc_segment1                   -- 事業所フレックスフィールド1
          ,loc_segment2                   -- 事業所フレックスフィールド2
          ,loc_segment3                   -- 事業所フレックスフィールド3
          ,loc_segment4                   -- 事業所フレックスフィールド4
          ,loc_segment5                   -- 事業所フレックスフィールド5
        ) VALUES (
           xx01_transfer_oif_s.NEXTVAL                                -- 振替OIF内部ID
          ,gv_fixed_ifrs_asset_regi                                   -- IFRS台帳
          ,g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_asset_number         -- 資産番号
          ,cn_created_by                                              -- 作成者ID
          ,cd_creation_date                                           -- 作成日
          ,cn_last_updated_by                                         -- 最終更新者
          ,cd_last_update_date                                        -- 最終更新日
          ,cn_last_update_login                                       -- 最終更新ログインID
          ,cn_request_id                                              -- 要求ID
          ,cn_program_application_id                                  -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                                              -- コンカレント・プログラムID
          ,cd_program_update_date                                     -- プログラム更新日
          ,g_ifrs_fa_trans_tab(ln_loop_cnt).transaction_date_entered  -- 振替日
          ,g_ifrs_fa_trans_tab(ln_loop_cnt).current_units             -- 単位変更
          ,cv_flg_yes                                                 -- 転記チェックフラグ(固定値Y)
          ,cv_pending                                                 -- ステータス(PENDING)
          ,lt_ifrs_gcc_segment1                                       -- 減価償却費勘定セグメント1
          ,lt_ifrs_gcc_segment2                                       -- 減価償却費勘定セグメント2
          ,lt_ifrs_gcc_segment3                                       -- 減価償却費勘定セグメント3
          ,lt_ifrs_gcc_segment4                                       -- 減価償却費勘定セグメント4
          ,lt_ifrs_gcc_segment5                                       -- 減価償却費勘定セグメント5
          ,lt_ifrs_gcc_segment6                                       -- 減価償却費勘定セグメント6
          ,lt_ifrs_gcc_segment7                                       -- 減価償却費勘定セグメント7
          ,lt_ifrs_gcc_segment8                                       -- 減価償却費勘定セグメント8
          ,lt_ifrs_fl_segment1                                        -- 事業所フレックスフィールド1
          ,lt_ifrs_fl_segment2                                        -- 事業所フレックスフィールド2
          ,lt_ifrs_fl_segment3                                        -- 事業所フレックスフィールド3
          ,lt_ifrs_fl_segment4                                        -- 事業所フレックスフィールド4
          ,lt_ifrs_fl_segment5                                        -- 事業所フレックスフィールド5
        );
        --
        -- IFRS台帳振替正常件数カウント
        gn_ifrs_fa_trans_normal_cnt := gn_ifrs_fa_trans_normal_cnt + 1;
      ELSE
        gn_skip_cnt := gn_skip_cnt + 1;
        --
        lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- XXCFF
                                                       ,cv_msg_019a03_m_017    -- IFRS台帳振替スキップメッセージ
                                                       ,cv_tkn_asset_number1   -- トークン'ASSET_NUMBER1'
                                                       ,g_ifrs_fa_trans_tab(gn_loop_cnt).asset_number
                                                                               -- 固定資産台帳の資産番号
                                                       ,cv_tkn_asset_number2   -- トークン'ASSET_NUMBER2'
                                                       ,g_ifrs_fa_trans_tab(gn_loop_cnt).ifrs_asset_number)
                                                                               -- IFRS台帳の資産番号
                                                       ,1
                                                       ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_warnmsg
        );
      END IF;
--
    END LOOP ifrs_fa_add_loop;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (ifrs_fa_trans_cur%ISOPEN) THEN
        CLOSE ifrs_fa_trans_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (ifrs_fa_trans_cur%ISOPEN) THEN
        CLOSE ifrs_fa_trans_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (ifrs_fa_trans_cur%ISOPEN) THEN
        CLOSE ifrs_fa_trans_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ifrs_fa_trans_data;
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
                                                      ,cv_msg_019a03_m_015  -- 取得対象データ無し
                                                      ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                      ,cv_msg_019a03_t_012) -- IFRS台帳連携セット
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
                                                      ,cv_msg_019a03_m_016  -- ロックエラー
                                                      ,cv_tkn_table_name    -- トークン'TABLE_NAME'
                                                      ,cv_msg_019a03_t_012) -- IFRS台帳連携セット
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
                                                    ,cv_msg_019a03_m_011       -- 会計期間チェックエラー
                                                    ,cv_tkn_bk_type            -- トークン'BOOK_TYPE_CODE'
                                                    ,gv_fixed_ifrs_asset_regi  -- 資産台帳名
                                                    ,cv_tkn_period             -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)           -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      --
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
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
                                                    ,cv_msg_019a03_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_019a03_t_010) -- XXCFF:台帳種類_固定資産台帳
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
                                                    ,cv_msg_019a03_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_019a03_t_011) -- XXCFF:台帳種類_IFRS台帳
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
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
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
    -- IFRS台帳振替データ抽出 (A-5)
    -- =========================================
    get_ifrs_fa_trans_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- A-5がエラーの場合
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
    gn_ifrs_fa_trans_target_cnt := 0;
    gn_ifrs_fa_trans_normal_cnt := 0;
    gn_ifrs_fa_trans_err_cnt    := 0;
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
      gn_ifrs_fa_trans_normal_cnt := cn_zero;
      -- エラー件数を+1更新
      gn_ifrs_fa_trans_err_cnt := gn_ifrs_fa_trans_err_cnt + 1;
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
      IF ( gn_ifrs_fa_trans_target_cnt > 0 ) THEN
        -- IFRS台帳振替エラーの固定資産台帳情報を出力する
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- XXCFF
                                                       ,cv_msg_019a03_m_014    -- IFRS台帳振替登録エラー
                                                       ,cv_tkn_asset_number1   -- トークン'ASSET_NUMBER1'
                                                       ,g_ifrs_fa_trans_tab(gn_loop_cnt).asset_number
                                                                               -- 固定資産台帳の資産番号
                                                       ,cv_tkn_asset_number2   -- トークン'ASSET_NUMBER2'
                                                       ,g_ifrs_fa_trans_tab(gn_loop_cnt).ifrs_asset_number)
                                                                               -- IFRS台帳の資産番号
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
    -- 対象件数が0件またはSKIP数が1件以上の場合
    ELSIF (( gn_ifrs_fa_trans_target_cnt = cn_zero ) OR ( gn_skip_cnt > cn_zero)) THEN
      -- ステータスを警告にする
      lv_retcode := cv_status_warn;
    END IF;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --IFRS台帳振替処理における件数出力
    --===============================================================
    --IFRS台帳振替作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_019a03_m_013
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
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_trans_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_trans_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_trans_err_cnt)
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
END XXCFF019A03C;
/
